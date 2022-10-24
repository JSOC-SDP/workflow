#! /bin/csh -f
#

set NEWTASK = update_hmi_harpimages_nrt
set NEWGATE = hmi_harpimages_nrt
set PRODUCT = hmi_harpimages_nrt

# these lines for all products
if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

cd $WFDIR
rm -f Keep_running
while (-e GATEKEEPERBUSY)
  echo waiting for gatekeeper to quit.
  sleep 5
  end

# begin section for this product

# Create the task. If the task (implemented as a directory) already exists, then delete it first.
if (-e tasks/$NEWTASK) then
    rm -rf tasks/$NEWTASK
endif

$WFCODE/maketask.csh task=$NEWTASK manager=taskmanager.csh target=$NEWGATE maxrange=86400 command=scripts/update_hmi_harpimages_nrt.csh


# Create the gate. If the gate (implemented as a directory) already exists, then delete it first.
if (-e gates/$NEWGATE) then
    rm -rf gates/$NEWGATE
endif

$WFCODE/makegate.csh gate_name=$NEWGATE product=$PRODUCT type=time key=NA project=HMI actiontask=$NEWTASK statustask=scripts/status-general.csh
