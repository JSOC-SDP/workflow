#!/home/jsoc/bin/linux_x86_64/activeperl

# The Gatekeeper iterates over all gates. If a gate's status needs updating, it spawns a task to update the gate's status.
# If a gate has tickets, it spawns tasks to process the tickets. Each gate is created with an "add script". An add script 
# first makes a gate (a subdirectory in the parent gates directory), then it makes a task (a gate-specific directory
# in the parent tasks directory). The Gatekeeper assumes that every gate has an associated task directory.
#
# To process a ticket, the Gatekeeper spawns a task, which creates a task instance (and subdirectory) in the gate-specific
# task directory.

use strict;
use warnings;
use Data::Dumper;
use IO::Dir;
use threads;
use threads::shared;
use lib "$Bin/../../../base/libs/perl";
use drmsNetLocks;
use drmsArgs;
use drmsSysRun;

# Install signal handler (so we can ctrl-c to end this app).
use sigtrap qw/handler Sighandler INT/;

# Script command-line parameters
use constant kArgDataDir       => "ddir";    # The directory containing pipeline data and log files.
use cosntant kArgCodeDir       => "cdir";    # The directory containing the pipeline scripts and apps.
use constant kArgVerbose       => "verbose"; # The verbosity level.
use constant kArgDebug         => "debug"    # The debug level.

# Hardcoded parameters
use constant kSleepShort       => 10;
use constant kSleepLong        => 60;
use constant kLockFile         => "/home/jsoc/locks/gatekeeperlck.txt";
use constant kDefDataDir       => "/home/jsoc/pipeline";
use constant kDefCodeDir       => "/home/jsoc/cvs/Development/JSOC/proj/workflow";
use constant kGateDir          => "gates";
use constant kLogDir           => "/home/jsoc/jsoclogs/pipeline";
use constant kRestartLog       => "restartlog.txt";
use constant kRunLog           => "runlog.txt";
use constant kGKOwner          => "Gatekeeper_owner";
use constant kKeepRunningFile  => "Keep_running";
use constant kEvWorkflowCode   => "WORKFLOW_ROOT";
use constant kEvWorkflowData   => "WORKFLOW_DATA";
use constant kGateStatusDoneTO => 14400; # 4 hours - Time interval to wait for all gates' status tasks to complete.
use constant kGateStatusTO     => 120;   # 1 minute - Time interval to wait for one gate's status task to complete.

# Flag files
use constant kFlagGKVerbose    => "GATEKEEPER_VERBOSE";
use constant kFlagGKDebug      => "GATEKEEPER_DEBUG";

# Return values
use constant kRetSuccess          => 0;
use constant kRetNoLock           => 1;
use constant kRetInvalidArgs      => 2;
use constant kRetFileIO           => 3;
use constant kRetConfig           => 4;
use constant kRetLog              => 5;
use constant kRetUnexpectedTerm   => 6;
use constant kRetStatusTask       => 7;

# Global variables
my($gTerminate);
my($gGateStatusMutex:shared); # Mutex for condition variable that synchronizes gate status-task completion.
my($gNThreads); # Total number of threads (i.e., number of gates) spawned for gate status tasks. Locked
                # by $gGateStatusMutex.

# Local variables
my($opts);
my($cfgH);
my($lock);
my($busy);
my($restartlog);
my($runlog);
my($odir); # original directory
my($fh);
my($sleepdur);
my($gatesH); # A reference to a hash whose key is the name of a gate, and whose value is a Gate object.
my(@gatedirs);

# Acquire lock - this guarantees that no two gatekeepers can run simultaneously.
# This code will attempt to get the lock 10 times. If it doesn't acquire it during
# one of those attempts, then the constructor returns undef.
$lock = new drmsNetLocks(&kLockFile);

if (defined($lock))
{
    # Read-in command-line arguments.
    $opts = GetOpts();
    
    # Read-in the configuration, which comes from a number of sources. Some are environment variables, 
    # and some are flag files in the pipeline data directory. Returns undef if there was a problem
    # reading required configuration information.
    $cfgH = ReadConfig($args);
    
    if (!defined($cfgH))
    {
        ShutDown(\$busy, \$lock, \$runlog, "", &kRetConfig);
    }
    
    if ($rv == &kRetSuccess)
    {
        # Append the PID to the restart.log file.
        $restartlog = new WriteLog(&kLogDir . "/" . &kRestartLog, 1);
        
        if (!defined($restartlog))
        {
            ShutDown(\$busy, \$lock, \$runlog, "Unable to create log file; bailing out.", &kRetLog);
        }
        else
        {
            $restartlog->Write($$, 1);
            $restartlog->Close();
        }
    }
    
    if ($rv == &kRetSuccess)
    {        
        # Write the name of the user who is running the gatekeeper to &kGKOwner.
        if (WriteToFile($cfgH->{&kCfgDataDir}, &kGKOwner, ">", $ENV{'USER'}))
        {
            ShutDown(\$busy, \$lock, \$runlog, "", &kRetFileIO);
        }
        
        # Write the name of the gatekeeper host machine and the PID of the gatekeeper to &kKeepRunningFile.
        if (WriteToFile($cfgH->{&kCfgDataDir}, &kKeepRunningFile, ">", $ENV{'HOST'} . "\." . $$))
        {
            ShutDown(\$busy, \$lock, \$runlog, "", &kRetFileIO);
        }
        
        # Append to the run log.
        $runlog = new WriteLog(&kLogDir . "/" . &kRunLog, 1);
        if (!defined($runlog))
        {
            ShutDown(\$busy, \$lock, \$runlog, "Unable to create run log " . &kLogDir . "/" . &kRunLog, &kRetLog);
        }
    }
    
    if ($rv == &kRetSuccess)
    {   
        # Main gate-checking loop 
        $gTerminate = 0;
        
        MAINLOOP: while (1)
        {
            # Check to see if it is time to shutdown.
            if ($gTerminate)
            {
                ShutDown(\$busy, \$lock, \$runlog, "Shutting down per user request.", &kRetSuccess);
            }
            
            $runlog->Write(); # Write just the timestamp.
            $runlog->Write("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", 1); # Don't write timestamp.
            
            # Ensure that DRMS/SUMS are functional.
            if (drmsSysRun($cfgH->{&kCfgCodeDir} . "/scripts/checkDRMSnSUMS.csh"))
            {
                # Cannot talk to DRMS or SUMS or both.
                $runlog->Write("GATEKEEPER, DRMS and/or SUMS is down, try again in a minute.");
                $sleepdur = &kSleepLong;
                LoopSleepOrBreak(\$busy, $cfgH->{&kCfgDataDir}, $sleepdur); # $busy is always undef here, so $gatesH will be undef here too and there is no need to untie.
            }
            else
            {
                $sleepdur = &kSleepShort;
            }

            # While the gate lock is being held, then no other program can modify the gate contents.
            $busy = new gateLock();
            
            if (defined($busy))
            {
                my(@allgates); # Array of all gate names
                my($badinit);
                my($nextupdateO); # JSOCTime object
                my($nextupdateS); # Time string
                my($nowS); # Time string
                my($nowO); # JSOCTime object
                my($nowT); # seconds since machine epoch
                my($currentO);
                my($expTimeO);
                

                if (!defined($gatesH))
                {
                    if (CreateGates($cfgH, $runlog, \$gatesH))
                    {
                        ShutDown(\$busy, \$lock, \$runlog, "Unable to read gates directory.", &kRetFileIO);
                    }
                }
                else
                {
                    # Reload the state for each gate. Also, an operator could have added a new gate, so check for that.
                    if (ReloadGates($cfgH, $runlog, \$gatesH))
                    {
                        ShutDown(\$busy, \$lock, \$runlog, "Unable to read gates directory.", &kRetFileIO);
                    }
                }
                    
                # Lock the mutex for the condition variable associated with the gate's status tasks
                {
                    lock($gGateStatusMutex);
                    $gNThreads = 0;
                } # unlock $gGateStatusMutex
                
                # Iterate through the gates, checking for work to be done for each. They are in the gates subdirectory 
                # in the data directory). Each gate is implemented as a subdirectory. We have to initalize the gates 
                # on each iteration of the main loop, since the state of each gate may change while the Gatekeeper is 
                # running.
                foreach my $gatename (@allgates)
                {
                    $gateO = $gatesH->{$gatename};
                    
                    if ($gateO->OnHold())
                    {
                        if ($cfgH->{&kCfgVerbose})
                        {
                            $runlog->Write("GATEKEEPER Gate: " . $gateO->Name() . " on HOLD, skip this gate.");
                        }
                        next;
                    }
                    
                    $runlog->Write("starting " . $gateO->Name());
                    
                    if ($cfgH->{&kCfgVerbose})
                    {
                        $runlog->Write("GATEKEEPER Gate: " . $gateO->Name() . ", starting to check for update times expired.");
                    }
                    
                    $nowT = localtime();
                    $nowS = POSIX::strftime("%Y.%m.%d_%H:%M:%S_%Z", $nowT);
                    $nowO = new JSOCTime($nowS, "%Y.%m.%d_%H:%M:%S_%Z");
                    $nextupdateO = new JSOCTime($gateO->Get(&Gate::kStateFNextUpdate), "%Y.%m.%d_%H:%M:%S_%Z");
                    $nextupdateS = $nextupdateO->TimeString();
                    
                    if (!defined($nextupdateO))
                    {
                        $nextupdateO = new JSOCTime($nowS, "%Y.%m.%d_%H:%M:%S_%Z");
                    }
                    
                    if ($cfgH->{&kCfgVerbose})
                    {
                        $runlog->Write("GATEKEEPER Gate: " . $gateO->Name() . ", now = $nowS");
                    }
                    
                    $badinit = length($cfgH->{&kCfgLow}) == 0 || $cfgH->{&kCfgLow} eq "NaN" ||
                               length($cfgH->{&kCfgHigh}) == 0 || $cfgH->{&kCfgHigh} eq "NaN";
                    
                    if (!defined($nextupdateO) || $nowO->GT($nextupdateO) || $badinit)
                    {
                        if ($cfgH->{&kCfgVerbose})
                        {
                            if ($badinit)
                            {
                                $runlog->Write("GATEKEEPER Gate " . $gateO->Name() . " not properly initialized, try to init");
                            }
                        }
                        
                        $nextupdateO = $nowO->Add($gateO->Get(&Gate::kStateFUpdateDelta));
                        $gateO->Set(&Gate::kStateFNextUpdate, $nextupdateS);
                        $gateO->Set(&Gate::kStateFLastUpdate, $nowS);
                        
                        # Spawn a thread that will process this gate. No gate should currently be
                        # busy. After we have spawned all threads, we wait until they have all 
                        # completed before re-visiting the gates (there is a timeout so that 
                        # we don't wait forever if a thread doesn't complete).
                        # We spawn such a thread by creating a StatusTask object and we will 
                        # poll for completed gate processing. Oriinally, there was a flag file,
                        # statusbusy, that lived in the gate directory. It was created by the Gatekeeper
                        # and deleted by the statustask for that gate. The file was used to 
                        # know when the statustask completed. However, by using threads, the 
                        # Gatekeeper knows when the statustask has completed.
                        
                        # Spawn the gate's status task.
                        $st = $gateO->StatusTask();
                        if (!defined($st))
                        {
                            # Fatal error.
                            ShutDown(\$busy, \$lock, \$runlog, "Unable to run status task for gate " . $gateO->Name() . "\.", &kRetFileIO);
                        }
                    }                    
                } # end loop over gates
                
                $startO = new JSOCTime(POSIX::strftime("%Y.%m.%d_%H:%M:%S_%Z", localtime()), "%Y.%m.%d_%H:%M:%S_%Z");
                $currentO = $startO->copy();
                $expTimeO = $startO->copy();
                $expTimeO->Add(&kGateStatusDoneTO); # Add kGateStatusTO seconds to current time - that defines the time
                # when we give up.
                
                # check for thread termination
                {
                    lock($gGateStatusMutex);
                    while ($currentO->LT($expTimeO))
                    {
                        if ($gNThreads == 0)
                        {
                            last;
                        }
                        
                        if (!cond_timedwait($gGateStatusMutex, &kGateStatusTO)) # timeout after 2 minutes.
                        {
                            # Timeout occurred. Allow the script a chance to see if a global timeout should happen.
                            $log->Write("WARNING: No active status task has completed in the last " . &kGateStatusTO . " seconds.");
                        }
                        
                        $currentO = new JSOCTime(POSIX::strftime("%Y.%m.%d_%H:%M:%S_%Z", localtime()), "%Y.%m.%d_%H:%M:%S_%Z");
                    }
                } # unlock $gGateStatusMutex
                
                {
                    lock($gGateStatusMutex);
                    if ($gNThreads != 0)
                    {
                        # Error - a thread is still running, bail.
                        $log->Write("ERROR: At least one status task has not completed within " . &kGateStatusDoneTO . " seconds. Bailing out");
                        
                        # Iterate through gates again to see which status tasks have not completed.
                        
                        ShutDown(\$busy, \$lock, \$runlog, "Unable to run status task for gate " . $gateO->Name() . "\.", &kRetFileIO);
                    }
                }
                
                # The status tasks may have modified certain flag files (like low, high). Also, the gatestatus flag file may have
                # been modified by an operator. Need to reload these three values for all gates since their values are used 
                # downstream.
                #
                foreach my $gatename (@allgates)
                {
                    $gateO = $gatesH->{$gatename};
                    
                    $gateO->Reload(&Gate::kStateFLow);
                    $gateO->Reload(&Gate::kStateFHigh);
                    $gateO->Reload(&Gate::kStateFGateStatus);
                    
                    if ($gateO->Get(&Gate::kStateFType) ~= /time/i)
                    {
                        # Have to call time_convert
                        $lowtime = ;
                        $hightime = ;
                    }
                    else
                    {
                        $lowtime = $gateO->Get(&Gate::kStateFLow);
                        $highttime = $gateO->Get(&Gate::kStateFHigh);
                    }
                    
                    # Run the tasks requested by the tickets at the gate. This code first asynchronously runs the tasks that the tickets request
                    # be run, then it waits for all the tasks to complete.
                    $gate->ProcessTickets();
                } # end loop over gates

                foreach my $gatename (@allgates)
                {
                    $gateO = $gatesH->{$gatename};
                    
                    # 
                }
                
                
            } # end busy block

            
            
            
            
            # The gatekeeper will have modified some gate attributes that may be used by code outside of the gatekeeper, so
            # we need to flush the attributes back to disk.
            foreach my $gatename (@allgates)
            {
                $gateO = $gatesH->{$gatename};
                
                $gateO->Flush();
            } # end loop over gates
            
            # Release the busy lock and allow other waiting programs to modify the gate information.            
            LoopSleepOrBreak(\$busy, $cfgH->{&kCfgDataDir}, $sleepdur);
        } # end main gate-checking loop
    }
}
else
{
    print STDERR "The gatekeeper is already running; bailing out.\n";
    $rv = &kRetNoLock;
}

ShutDown(\$busy, \$lock, \$runlog, "The Gatekeeper quit unexpectedly!", &kUnexpectedTerm);

sub GetOpts
{
    my($optsinH);
    
    $optsinH =
    {
        &kArgDataDir   => 's',
        &kArgCodeDir   => 's',
        &kArgVerbose   => 'i',
        &kArgDebug     => 'i' 
    };
    
    return new drmsArgs($optsinH, 0);
}

sub Sighandler
{
    # Set global variable to signify that the gatekeeper should terminate.
    $gTerminate = 1;
}

sub ReadArgs
{
    my($args);
    
    return $args;
}

sub ReadConfig
{
    my($opts) = @_;
    my($err) = 0;

    my($datadir);
    my($codedir);
    my($verbose);
    my($debug);
    my($cfgH) = {};
    my($cfg);
    
    $datadir = $opts->Get(&kArgDataDir);
    if (!defined($datadir))
    {
        $datadir = $ENV{&kEvWorkflowData};
    }
    if (!defined($datadir))
    {
        $datadir = &kDefDataDir;
    }

    $codedir = $opts->Get(&kArgCodeDir);
    if (!defined($codedir))
    {
        $codedir = $ENV{&kEvWorkflowCode};
    }
    if (!defined($codedir))
    {
        $codedir = &kDefCodeDir;
    }

    if (!defined($datadir) || !defined($codedir) || !(-d $datadir && -d $codedir))
    {
        print STDERR "Workflow data directory and/or code directory undefined.\n";
        $err = 1;
    }

    if (!$err)
    {
        $verbose = $opts->Get(&kArgVerbose);
        if (!defined($verbose))
        {
            $verbose = 1;
            if (-e "$datadir/" . &kFlagGKVerbose)
            {
                my($fh);
                if (defined(open($fh, "<$datadir/" . &kFlagGKVerbose)))
                {
                    $verbose = <$fh>;
                    chomp($verbose);
                    $fh->close();
                }
            }
        }
        
        $debug = $opts->Get(&kArgDebug);
        if (!defined($debug))
        {
            $debug = 1;
            if (-e "$datadir/" . &kFlagGKDebug)
            {
                my($fh);
                if (defined(open($fh, "<$datadir/" . &kFlagGKDebug)))
                {
                    $debug = <$fh>;
                    chomp($debug);
                    $fh->close();
                }
            }
        }
    }

    if (!$err)
    {
        $cfgH->{&kCfgDataDir} = $datadir;
        $cfgH->{&kCfgCodeDir} = $codedir;
        $cfgH->{&kCfgVerbose} = $verbose;
        $cfgH->{&kCfgDebug} = $debug;

        $cfg = new Cfg($cfgH);
    }
    
    return $cfg;
}

sub WriteToFile
{
    my($datadir, $file, $mode, $content) = @_;
    my($fh);
    my($msg);
    my($rv);
    
    $rv = 0;
    
    if (!defined(open($fh, "$mode$datadir/$file")))
    {
        $msg = "Cannot open $datadir/$file for writing.\n";
        $rv = 1;
    }
    
    print $fh $content;
    $fh->close();
    
    return $rv;
}

sub ShutDown
{
    my($busyR, $lockR, $runlogR, $msg, $retval) = @_;
    
    # Turn-off the busy if it is set.
    if (defined($$busyR))
    {
        $$busyR->ReleaseLock();
        $$busyR = undef;
    }
    
    # Print the message to the log file, then destroy the run log.
    if (defined($runlogR) && defined($rrunlogR))
    {
        $$runlogR->Write("$msg");
        $$runlogR->Close();
        $$runlogR = undef;
    }
    elsif ($retval == &kRetSuccess)
    {
        print "$msg\n";
    }
    else
    {
        print STDERR "$msg\n";
    }
    
    # Release the concurrency lock.
    if (defined($$lockR))
    {
        $$lockR->ReleaseLock();
    }
    
    exit($retval);
}

# Unset busy flag (release the "busy" lock) and check for the presence of the Keep_running file. If it is missing, then 
# set the global variable that indicates it is time to shutdown. On the next loop iteration, the shutdow will happen.
# There is no concurrency code handling Keep_running, and there is none necessary. All concurrency is handled with the 
# net lock and the gate lock.
sub LoopSleepOrBreak
{
    my($busy, $datadir, $sleepdur) = @_;
    
    if (defined($$busy))
    {
        $$busy->ReleaseLock();
        $$busy = undef;
    }
    
    if (!(-e "$datadir/" . &kKeepRunningFile))
    {
        # keeprunning flag file removed, terminate.
        $gTerminate = 1;
    }
    else
    {
        # Don't terminate, but sleep to allow other scripts/programs access to gates.
        sleep($sleepdur);
    }
    
    next MAINLOOP;
}

sub CreateOrUpdateGates
{
    my($cfgH, $runlog, $gatesHref) = @_;
    my($update);
    my(%gates);
    my(@gatedirs);
    my($gatedir);
    my($gateO);
    my($rv);

    $update = 0;
    if (defined($gatesH))
    {
        my(@gkeys) = keys(%$gatesH);
        
        if ($#gkeys >= 0)
        {
            $update = 1;
        }
    }
    
    if (!defined(tie(%gates, "IO::Dir", $cfgH->{&kCfgDataDir} . "/" . &kGateDir)))
    {
        $rv = 1;
    }
    else
    {
        if (!defined($$gatesHref))
        {
            $$gatesHref = {};
        }
        
        @gatedirs = keys(%gates);
        
        while (defined($gatedir = shift(@gatedirs)))
        {
            if ($gatedir =~ /^\.$/ || $gatedir =~ /^\.\.$/)
            {
                # Skip the "." and ".." files
                next;
            }
            
            if (!$update)
            {
                # New gates from scratch.
                my($gate);
                
                $gateO = new Gate($cfgH->{&kCfgDataDir} . "/" . &kGateDir, $gatedir, $runlog);
                $$gatesHref->{$gateO->Name()} = $gateO;
            }
            else
            {
                # Reload. Iterate through all gates, re-initializing the state. Also, check for new
                # gates that were added, and check for gates that were dropped.
                my(@gkeys) = keys(%$gatesHref);
                
                foreach my $gate (@gkeys)
                {
                    $gateO = $gatesHref->{$gate};
                    $gateO->Reload();
                }
            }
        }
        
        # Release the gates-directory object.
        untie(%gates); 
    }

    return $rv;
}

sub CreateGates
{
    my($cfgH, $runlog, $gatesH) = @_;
    
    $gatesH = undef;

    return CreateOrUpdateGates($cfgH, $runlog, $gatesH);
}

sub ReloadGates
{
    my($cfgH, $runlog, $gatesH) = @_;
    
    return CreateOrUpdateGates($cfgH, $runlog, $gatesH);
}
