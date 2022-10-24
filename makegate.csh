#! /bin/csh -f

echo $0 $*

#set echo

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

# Call with gatename, seriesname, key, and type as key=value pairs
#   gate=<gatename> ds=<seriesname> key=<primekey> type=<typename>
# where typename is one of "time", "sn", ...
# Any of the following keywords can be set on the calling line.

# set defaults and collect args


set gate_name = "NOT_SPECIFIED"
set product = "NOT_SPECIFIED"
set gatestatus = "HOLD"
set low = NaN    # 
set high = NaN    # 
set type = "NOT_SPECIFIED"
set key = "NOT_SPECIFIED"
set lastupdate = 1993    # 
set nextupdate = `date +%Y.%m.%d_%H:%M:%S`    # 
set updatedelta = 86400
set statustask = scripts/statustask.csh
set actiontask = "NOT_SPECIFIED"
set project = "NA"
set coverage_args = "none"

while ( $#argv > 0)
  foreach keyname (gate_name gatestatus product sequence_number low high type key lastupdate nextupdate updatedelta statustask actiontask project)
    if ($1 =~ $keyname=*) then
       set $1
    endif
    end # foreach
  shift
  end #while

if ("$gate_name" == "NOT_SPECIFIED") then
  echo gate_name must be specified
  exit
endif
if ("$product" == "NOT_SPECIFIED") then
  echo product must be specified
  exit
endif
if ("$type" == "NOT_SPECIFIED") then
  echo type must be specified
  exit
endif
if ("$key" == "NOT_SPECIFIED") then
  echo key must be specified
  exit
endif
if ("$actiontask" == "NOT_SPECIFIED") then
  echo warning - actiontask is not specified
endif
if (!(-x $WFCODE/$statustask)) then
  echo STOP, the script/program statustask should be created and executable before a gate that uses it is created.
  exit
endif
if (!(-x $WFDIR/tasks/$actiontask)) then
  echo STOP, the command $actiontask should be created before a gate that uses it is created.
  exit
endif

set isdash = `echo $gate_name | grep '-' | wc -l`
if ($isdash) then
  echo STOP, the gatename may not contain a dash, $gate_name
  exit
endif

set sequence_number = $gate_name"-19930101-000" # gate sequence number

cd $WFDIR
if (-e gates/$gate_name) then
  echo gate $gate_name already exists, remove then repeat command
  exit
endif
mkdir gates/$gate_name
cd gates/$gate_name

echo "$gate_name" > gate_name
echo "$product" > product
echo "$gatestatus" > gatestatus
echo $sequence_number >sequence_number
echo "$low" > low
echo "$high" > high
echo "$type" > type
echo "$key" > key
echo "$lastupdate" > lastupdate
echo "$nextupdate" > nextupdate
echo "$updatedelta" > updatedelta
echo "$statustask" > statustask
echo "$actiontask" > actiontask
echo "$project" > project
echo "$coverage_args" > coverage_args

mkdir new_tickets
mkdir active_tickets

