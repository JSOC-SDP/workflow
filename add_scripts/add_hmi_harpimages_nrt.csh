#! /bin/csh -f
#

# Verify our workflow environment variables are set
# Assumes this script is run from the root of the workflow directory
set script_dir = `cd $(dirname $0) && pwd`
source "$script_dir/setup_workflow.csh"

set NEWTASK = update_hmi_harpimages_nrt
set NEWGATE = hmi_harpimages_nrt
set PRODUCT = hmi_harpimages_nrt

cd $WORKFLOW_DATA
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

$WORKFLOW_DIR/maketask.csh task=$NEWTASK manager=taskmanager.csh target=$NEWGATE maxrange=86400 command=scripts/update_hmi_harpimages_nrt.csh


# Create the gate. If the gate (implemented as a directory) already exists, then delete it first.
if (-e gates/$NEWGATE) then
    rm -rf gates/$NEWGATE
endif

$WORKFLOW_DIR/makegate.csh gate_name=$NEWGATE product=$PRODUCT type=time key=NA project=HMI actiontask=$NEWTASK statustask=scripts/status-general.csh
