#! /bin/csh -f

# Verify our workflow environment variables are set
# Assumes this script is run from the root of the workflow directory
set script_dir = `cd $(dirname $0) && pwd`
source "$script_dir/setup_workflow.csh"

# Ugh
set CTIMES = /home/wso/bin/_linux4/ctimes
set MAKE_TICKET = $WORKFLOW_DIR/maketicket.csh
set TIME_CONVERT = "${DRMS_BINS_INSTALL_DIR}"/time_convert
set WAIT_TICKET = "${DRMS_SRC_INSTALL_DIR}/workflow/wait_ticket.csh"

cd $WORKFLOW_DIR

set dsdshigh = `cat $WORKFLOW_DATA/gates/dsds.vwV/high`
set dsdshigh_t = `$TIME_CONVERT time=$dsdshigh`
@ dsdsblock = 6 * 3600
@ dsdshigh_t = $dsdshigh_t + $dsdsblock
set dsdshigh = `$TIME_CONVERT zone=TAI s=$dsdshigh_t`

set update = `$MAKE_TICKET gate=mdi.vwV wantlow=$dsdshigh wanthigh=$dsdshigh action=2`
$WAIT_TICKET $update

set mdihigh = `cat $WORKFLOW_DATA/gates/mdi.vwV/high`
set mdihigh_t = `$TIME_CONVERT time=$mdihigh`
@ mdihigh_t = $mdihigh_t + 60
set mdihigh = `$TIME_CONVERT zone=TAI s=$mdihigh_t`

$MAKE_TICKET gate=mdi.vwV wantlow=$mdihigh wanthigh=$dsdshigh action=5
$MAKE_TICKET gate=mdi.fdV wantlow=$mdihigh wanthigh=$dsdshigh action=5
$MAKE_TICKET gate=mdi.fdM wantlow=$mdihigh wanthigh=$dsdshigh action=5
$MAKE_TICKET gate=mdi.fdM_96m wantlow=$mdihigh wanthigh=$dsdshigh action=5

set synophigh = `cat $WORKFLOW_DATA/gates/mdi.Synop/high`

set fdMhigh = `$CTIMES -c $dsdshigh`
set crhigh = `echo $fdMhigh | sed -e 's/CT//' -e 's/:.*//'`

if ($crhigh > $synophigh) then
    @ cr = $synophigh + 1
    $MAKE_TICKET gate=mdi.Synop wantlow=$cr wanthigh=$crhigh action=5
endif

