#!/home/jsoc/bin/linux_x86_64/activeperl

package WriteLog;

use strict;
use warnings;
use Data::Dumper;
use POSIX qw(strftime);

sub new
{
    my($clname) = shift;
    my($fname) = shift;
    my($append) = shift;
    my($mode);

    my($self) =
    {
        _fname => undef,
        _fh => undef
    };

    bless($self, $clname);

    if (defined($fname) && length($fname) > 0 && -e $fname)
    {
        my($fh);
        
        if (defined($append) && $append != 0)
        {
            $mode = ">>";
        }
        else
        {
            $mode = ">";
        }

        if (defined(open($fh, ">$fname")))
        {
            $self->{_fname} = $fname;
            $self->{_fh} = $fh;
        }
        else
        {
            print STDERR "Invalid file path.\n";
            $self = undef;
        }
    }
    else
    {
        print STDERR "Invalid file path.\n";
        $self = undef;
    }

    return $self;
}

sub DESTROY
{
    my($self) = shift;

    $self->close();
}

sub Write
{
    my($self) = shift;
    my($msg) = shift;
    my($nodate) = shift;
    
    my($now);
    my($timestr);
    
    if (!defined($nodate) || $nodate == 0)
    {
        # Start the line with a timestamp
        $now = localtime();
        $timestr = POSIX::strftime("%B %d, %Y [%H:%M:%S %z]", localtime());
        print $self->{_fh} "$timestr"; # Does not end in newline.
        
        if (defined($msg) && length($msg) > 0)
        {
            print $self->{_fh} " - ";
        }
    }

    if (defined($msg && length($msg) > 0)
    {
        print $self->{_fh} "$msg\n";
    }
    else
    {
        print $self->{_fh} "\n";
    }
}

sub Close
{
    my($self) = shift;
    
    if (defined($self->{_fh}))
    {
        $self->{_fh}->close();
        $self->{_fh} = undef;
    }
}

package Cfg;

use strict;
use warnings;

sub new
{
    my($clname, $src, $log) = @_;
    my($self) = 
    {
        _hash => {},
        _log => undef
    };
    
    bless($self, $clname);
    
    if (-e $src)
    {
        # config source is a file
        my($cfg);
        my($cfgH) = {};
        
        if ($self->ParseCFile($src, $cfgH))
        {
            if (defined($log))
            {
                $log->Write("Unable to open configuration file $src.");
            }
            else
            {
                print STDERR "Unable to open configuration file $src.\n"; 
            }
            
            $self = undef;
        }
        else
        {
            $self->{_hash} = $cfgH;
        }
    }
    else
    {
        # config source is a hash array
        $self->{_hash} = $src;
    }
    
    $self->{_log} = $log;
        
    return $self;
}

sub DESTROY
{

}

sub Get
{
    my($self) = shift;
    my($name) = shift;

    if (exists($self->{_hash}->{$name}))
    {
        return $self->{_hash}->{$name};
    }
    else
    {
        if (defined($self->{_log}))
        {
            $self->{_log}->Write("Unknown configuration argument '$name'.");
        }
        else
        {
            print STDERR "Unknown configuration argument '$name'.\n";
        }
        
        return undef;
    }
}

sub ParseCFile
{
    my($self, $conf, $hashref) = @_;
    my(@cfgdata);
    my(%cfgraw);
    my(%cfg);
    my($rv);
    
    $rv = 0;
    
    if (open(CNFFILE, "<$conf"))
    {
        @cfgdata = <CNFFILE>;
        
        # Make key-value pairs of all non-ccomment lines in configuration file.                                             
        %cfgraw = map {
            chomp;
            my($key, $val) = m/^\s*(\w+)\s*=\s*(.*)/;
            defined($key) && defined($val) ? ($key, $val) : ();
        } grep {/=/ and !/^#/} @cfgdata;                                                                                    
            
            close(CNFFILE);
            
            # Expand in-line variables in arguments                                                                             
            %cfg = map {
                my($val) = $cfgraw{$_};
                my($var);
                my($key);
                my($sub);
                
                while ($val =~ /(\${.+?})/)
                {
                    $var = $1;
                    $key = ($var =~ /\${(.+)}/)[0];
                    $sub = $cfgraw{$key};
                    
                    if (defined($var) && defined($sub))
                    {
                        $var = '\${' . $key . '}';
                        $val =~ s/$var/$sub/g;
                    }
                }
                
                ($_, $val);
            } keys(%cfgraw);
        }
        else
        {
            if (defined($self->{_log}))
            {
                $self->{_log}->Write("Unable to open configuration file '$conf'.");
            }
            else
            {
                print STDERR "Unable to open configuration file '$conf'.\n";
            }
            
            $rv = 1;
        }
        
        if ($rv == 0)
        {
            # everything is AOK - copy %cfg to referenced hash array                                                            
            my($hkey);
            my($hval);
            
            foreach $hkey (keys(%cfg))
            {
                $hval = $cfg{$hkey};
                $hashref->{$hkey} = $hval;
            }
        }
        
        return $rv;
    }

package Gate;

use strict;
use warnings;

use constant kStateFNextUpdate   => "nextupdate";
use constant kStateFUpdateDelta  => "updatedelta";
use constant kStateFType         => "type";
use constant kStateFActionTask   => "actiontask";
use constant kStateFGateStatus   => "gatestatus";
use constant kStateFProduct      => "product";
use constant kStateFStatusTask   => "statustask";
use constant kStateFLow          => "low";
use constant kStateFHigh         => "high";

sub new
{
    my($clname, $gatesdir, $gatesubdir, $log) = @_;
    my($self) =
    {
        _name => undef,
        _gatedir => undef,
        _log => undef,
        _nextupdate => undef,
        _updatedelta => undef,
        _type => undef,
        _actiontask => undef,
        _gatestatus => undef,
        _product => undef,
        _statustask => undef,
        _low => undef,
        _high => undef,
        _orig => undef, # The original state that existed when the object was created.
        _tickets => undef
    };
    my($fh);
    
    bless($self, $clname);
    
    if (defined($log))
    {
        $self->{_log} = $log;
    }
    
    if (defined($gatedir) && -d $gatedir)
    {
        # Gate Identification 
        $self->{_name} = $gatesubdir;
        $self->{_gatedir} = "$gatesdir/$gatesubdir";
        
        # Read the contents of all state files.
        $self->LoadState();
        
        # There are additional state files, but they are not accessed by the Gatekeeper (coverage_args, gate_name, key, project, sequence_number).
    }
    else
    {
        $self->WriteLog("Invalid gate directory $gatedir.");
        $self = undef;
    }
    
    return $self;
}
    
sub DESTROY
{
    my($self) = @_;
    my(@tickets);
    
    # Must flush out to state files, if attributes have changed.
    if ($self->{_nextupdate} ne $self->{_orig}->{_nextupdate})
    {
        # NextUpdate is a time string.
        $self->WriteContent(&kStateFNextUpdate, $self->{_nextupdate});
    }
    if ($self->{_updatedelta} != $self->{_orig}->{_updatedelta})
    {
        # UpdateDelta is a number of seconds.
        $self->WriteContent(&kStateFUpdateDelta, $self->{_updatedelta});
    }
    if ($self->{_type} ne $self->{_orig}->{_type})
    {
        # Type is a string (the value could be numeric, but it could also be a string).
        $self->WriteContent(&kStateFType, $self->{_type});
    }
    if ($self->{_actiontask} ne $self->{_orig}->{_actiontask})
    {
        # ActionTask is the name of a script/program, which is a string.
        $self->WriteContent(&kStateFActionTask, $self->{_actiontask});
    }
    if ($self->{_gatestatus} ne $self->{_orig}->{_gatestatus})
    {
        # GateStatus is a string.
        $self->WriteContent(&kStateFGateStatus, $self->{_gatestatus});
    }
    if ($self->{_product} ne $self->{_orig}->{_product})
    {
        # Product is a DRMS data series, which is a string.
        $self->WriteContent(&kStateFProduct, $self->{_product});
    }
    if ($self->{_statustask} ne $self->{_orig}->{_statustask})
    {
        # StatusTask is the name of a script/program, which is a string.
        $self->WriteContent(&kStateFStatusTask, $self->{_statustask});
    }
    
    # Low/High - In general, these state files are updated by the status scripts. But the Gatekeeper
    # itself will set these values on ocassion. The Gatekeeper and the status scripts will read
    # both of these too. So, we better make sure that there is no possibility that the Gatekeeper 
    # does ANYTHING while the status scripts are running. Otherwise, there could be a race condition.
    if ($self->{_low} ne $self->{_orig}->{_low})
    {
        # StatusTask is the name of a script/program, which is a string.
        $self->WriteContent(&kStateFLow, $self->{_low});
    }
    if ($self->{_high} ne $self->{_orig}->{_high})
    {
        # StatusTask is the name of a script/program, which is a string.
        $self->WriteContent(&kStateFHigh, $self->{_high});
    }
    
    # Flush tickets back to disk.
    @tickets = keys(%{$self->{_tickets}});
    foreach my $ticketname (@tickets)
    {
        $ticketO = $self->{_tickets}->{$ticketname};
        $ticket->Flush();
    }
    $self->{_tickets} = undef;
    
    if (defined($self->{_log}))
    {
        $self->{_log} = undef;
    }
}

# Class methods
    
# Member methods
sub LoadState
{
    my($self, $attrib) = @_;
    
    if (defined($attrib) && length($attrib) > 0)
    {
        $self->{"_" . $attrib} = self->ReadContent($attrib);
        
        # Save the original state so we can check for changes when flushing to disk.
        $self->{_orig}->{"_" . $attrib} = $self->{"_" . $attrib};
    }
    else
    {
        $self->{_nextupdate} = $self->ReadContent(&kStateFNextUpdate);
        $self->{_updatedelta} = $self->ReadContent(&kStateFUpdateDelta);
        $self->{_type} = $self->ReadContent(&kStateFType);
        $self->{_actiontask} = $self->ReadContent(&kStateFActionTask);
        $self->{_gatestatus} = $self->ReadContent(&kStateFGateStatus);
        $self->{_product} = $self->ReadContent(&kStateFProduct);
        $self->{_statustask} = $self->ReadContent(&kStateFStatusTask);
        $self->{_low} = $self->ReadContent(&kStateFLow);
        $self->{_high} = $self->ReadContent(&kStateFHigh);
        
        # Save the original state so we can check for changes when flushing to disk.
        $self->{_orig} = {};
        $self->{_orig}->{_nextupdate} = $self->{_nextupdate};
        $self->{_orig}->{_updatedelta} = $self->{_updatedelta};
        $self->{_orig}->{_type} = $self->{_type};
        $self->{_orig}->{_actiontask} = $self->{_actiontask};
        $self->{_orig}->{_gatestatus} = $self->{_gatestatus};
        $self->{_orig}->{_product} = $self->{_product};
        $self->{_orig}->{_statustask} = $self->{_statustask};
        $self->{_orig}->{_low} = $self->{_low};
        $self->{_orig}->{_high} = $self->{_high};
    }
}
    
sub Reload
{
    my($self, $attrib) = @_;
    
    $self->LoadState($attrib);
}
    
sub WriteLog
{
    my($self, $msg) = @_;
    
    if (defined($self->{_log}))
    {
        $self->{_log}->Write($msg);
    }
    else
    {
        print STDERR "$msg\n";
    }
}
    
sub ReadContent
{
    my($self, $statefID) = @_;
    my($sfile) = $self->{_gatedir} . "/"  . $statefID;
    my($fh);
    my($content);

    if (defined(open($fh, "<$sfile")))
    {
        $content = <$fh>;
        $fh->close();
    }
    else
    {
        $self->WriteLog("Unable to open state file $sfile for reading.");
    }
    
    return $content;
}
    
sub WriteContent
{
    my($self, $statefID, $content) = @_;
    
    my($sfile) = $self->{_gatedir} . "/"  . $statefID;
    my($fh);

    if (defined(open($fh, ">$sfile")))
    {
        print $fh $content;
        $fh->close();
    }
    else
    {
        $self->WriteLog("Unable to open state file $sfile for writing.");
    }
}
    
sub OnHold
{
    my($self) = @_;
    
    return ($self->{_gatestatus} =~ /^\s*hold\s*$/i);
}
    
sub Name
{
    my($self) = @_;
    
    return $self->{_name};    
}
    
sub Get
{
    my($self, $attrib) = @_;
    
    return $self->{"_$attrib"};
        
}

sub Set
{
    my($self, $attrib, $val) = @_;
    
    if (exists($self->{"_$attrib"}))
    {
        $self->{"_$attrib"} = $val;
    }
    else
    {
        $self->WriteLog("Unknown gate attribute $attrib.");
    }
}
    
sub ProcessTickets
{
    my($self) = @_;
    
    my($ticketO);
    
    # Load ticket state. First I have to figure out what state is needed by the Gatekeeper
    
    # Create the ticket objects
    foreach my $ticketname (@tickets)
    {
        $ticketO = new Ticket();
        $task = $ticketO->DoTask();
        
        if (!defined($task))
        {
            # Fatal error.
        }
        
        $self->{_tickets} = $ticketO;        
        
    }
}

    
    
package JSOCTime;

use strict;
use warnings;
use DateTime qw(compare);
use DateTime::Format::Strptime;

# Static funcctions
sub Compare
{
    my($t1) = shift;
    my($t2) = shift;
    
    return DateTime->compare($t1, $t2);
}
    
# Non-static member functions
sub new
{
    my($clname) = shift;
    my($str) = shift;
    my($pattern) = shift;
    
    my($self) =
    {
        _dt => undef # a DateTime object
    };
    
    bless($self, $clname);
    
    my($strp) = new DateTime::Format::Strptime(pattern => '$pattern', locale => 'en_US', time_zone => 'UTC');
    
    if (defined($strp))
    {
        my($dt) = $strp->parse_datetime($str);
        
        if (defined($dt))
        {
            $self->{_dt} = $dt;
        }
        else
        {
            $self = undef;
        }
    }
    else
    {
        $self = undef;
    }
    
    return $self;
}
    
sub Copy
{
    my($self) = @_;
    my($classname);
    my($new) =
    {
        _dt => DateTime->from_object(object => $self->{_dt});
    };
    
    $classname = ref($self);

    bless($new, $classname);
    
    return $new;
}
    
sub Cmp
{
    my($self, $other) = @_;
    
    return DateTime->compare($self->{_dt}, $other->{_dt});
}
    
sub GT
{
    my($self, $other) = @_;
    
    my($cmp) = $self->Cmp($other);
    
    return ($cmp == 1);
}
    
sub Add
{
    my($self, $seconds) = @_;
    
    $self->{_dt}->add(DateTime::Duration->new(seconds => $seconds));
}

# Returns the time-string representation of the member DateTime object.
sub TimeString
{
    my($self) = @_;
    
    return $self->{_dt}->strftime("%Y.%m.%d_%H:%M:%S_%Z");
}
