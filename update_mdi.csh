#! /bin/csh -f

set WFCODE = $WORKFLOW_ROOT

cd $WFCODE

set dsdshigh = `cat DATA/gates/dsds.vwV/high`
set dsdshigh_t = `time_convert time=$dsdshigh`
@ dsdsblock = 6 * 3600
@ dsdshigh_t = $dsdshigh_t + $dsdsblock
set dsdshigh = `time_convert zone=TAI s=$dsdshigh_t`

set update = `maketicket.csh gate=mdi.vwV wantlow=$dsdshigh wanthigh=$dsdshigh action=2`
wait_ticket.csh $update

set mdihigh = `cat DATA/gates/mdi.vwV/high`
set mdihigh_t = `time_convert time=$mdihigh`
@ mdihigh_t = $mdihigh_t + 60
set mdihigh = `time_convert zone=TAI s=$mdihigh_t`

maketicket.csh gate=mdi.vwV wantlow=$mdihigh wanthigh=$dsdshigh action=5
maketicket.csh gate=mdi.fdV wantlow=$mdihigh wanthigh=$dsdshigh action=5
maketicket.csh gate=mdi.fdM wantlow=$mdihigh wanthigh=$dsdshigh action=5
maketicket.csh gate=mdi.fdM_96m wantlow=$mdihigh wanthigh=$dsdshigh action=5


set synophigh = `cat DATA/gates/mdi.Synop/high`

set fdMhigh = `ctimes -c $dsdshigh`
set crhigh = `echo $fdMhigh | sed -e 's/CT//' -e 's/:.*//'`

if ($crhigh > $synophigh) then
  @ cr = $synophigh + 1
  maketicket.csh gate=mdi.Synop wantlow=$cr wanthigh=$crhigh action=5
endif

