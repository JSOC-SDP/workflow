#! /bin/csh -f

echo $0 $*

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

# Call with at least task, target, and task as key=value pairs
# e.g.   maketasks.csh task=<taskname> target=<target> command=<command>
# Any of the following keywords can be set on the calling line.

# set defaults and collect args

set task = "NOT_SPECIFIED"
set parallelOK = 0
set maxrange = NaN    # 
set target = "NOT_SPECIFIED"
set retain = 1
set note = ""
set state = 0
set command = "NOT_SPECIFIED"
set manager = $WFCODE/taskmanager.csh

while ( $#argv > 0)
  foreach keyname (task parallelOK maxrange retain target note command manager )
    if ($1 =~ $keyname=*) then
       set $1
       break
    endif
    end # foreach
  shift
  end #while

  echo $task "$task"
if ("$task" == "NOT_SPECIFIED") then
  echo task must be specified
  exit
endif
if ("$target" == "NOT_SPECIFIED") then
  echo product must be specified
  exit
endif
if ("$command" == "NOT_SPECIFIED") then
  echo command must be specified
  exit
else if (!( -x $command)) then
  echo STOP - in task $task the command $command must be executable.
  exit 1
endif
if ("$maxrange" == "NaN") then
  echo maxrange must be specified
  exit
endif
if (!( -x $manager)) then
  echo STOP - in task $task the taskmanager $manager must be executable.
  exit 1
endif

set isdash = `echo $task | grep '-' | wc -l`
if ($isdash) then
  echo STOP, the task name may not contain a dash, $task
  exit
endif

set isdash = `echo $target | grep '-' | wc -l`
if ($isdash) then
  echo STOP, the target gate name may not contain a dash, $target
  exit
endif

set taskid = $task"-19930101-000"

cd $WFDIR
if (-e tasks/$task) then
  echo task $task already exists, remove then repeat command
  exit
endif
mkdir tasks/$task
cd tasks/$task

echo "$task" > task
echo "$parallelOK" > parallelOK
echo "$maxrange" > maxrange
echo "$retain" > retain
echo "$target" > target
echo "$note" > note
echo "$state" > state
echo "$taskid" > taskid

ln -s $command command
ln -s $manager manager

mkdir preconditions
mkdir active
mkdir done
mkdir archive
mkdir archive/ok
mkdir archive/failed

# If and only if, completed OK task records are to be kept, uncomment the following
# touch DEBUG
