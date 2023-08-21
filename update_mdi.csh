#! /bin/csh -f

set drms_bins_install_dir = "${DRMS_BINS_INSTALL_DIR}"
set drms_incs_install_dir = "${DRMS_INCS_INSTALL_DIR}"
set drms_libs_install_dir = "${DRMS_LIBS_INSTALL_DIR}"
set drms_params_install_dir = "${DRMS_PARAMS_INSTALL_DIR}"
set drms_root_dir = "${DRMS_ROOT_DIR}"
set drms_scrs_install_dir = "${DRMS_SCRS_INSTALL_DIR}"
set drms_src_install_dir = "${DRMS_SRC_INSTALL_DIR}"
set drms_table_dir = "${DRMS_TABLE_DIR}"

set WORKFLOW_DATA = /home/jsoc/pipeline
set WORKFLOW_ROOT = "${drms_src_install_dir}"/workflow

set WFCODE = $WORKFLOW_ROOT

cd $WFCODE
set CTIMES = /home/wso/bin/_linux4/ctimes


set dsdshigh = `cat $WORKFLOW_DATA/gates/dsds.vwV/high`
set dsdshigh_t = `time_convert time=$dsdshigh`
@ dsdsblock = 6 * 3600
@ dsdshigh_t = $dsdshigh_t + $dsdsblock
set dsdshigh = `time_convert zone=TAI s=$dsdshigh_t`

set update = `maketicket.csh gate=mdi.vwV wantlow=$dsdshigh wanthigh=$dsdshigh action=2`
wait_ticket.csh $update

set mdihigh = `cat $WORKFLOW_DATA/gates/mdi.vwV/high`
set mdihigh_t = `time_convert time=$mdihigh`
@ mdihigh_t = $mdihigh_t + 60
set mdihigh = `time_convert zone=TAI s=$mdihigh_t`

maketicket.csh gate=mdi.vwV wantlow=$mdihigh wanthigh=$dsdshigh action=5
maketicket.csh gate=mdi.fdV wantlow=$mdihigh wanthigh=$dsdshigh action=5
maketicket.csh gate=mdi.fdM wantlow=$mdihigh wanthigh=$dsdshigh action=5
maketicket.csh gate=mdi.fdM_96m wantlow=$mdihigh wanthigh=$dsdshigh action=5


set synophigh = `cat $WORKFLOW_DATA/gates/mdi.Synop/high`

set fdMhigh = `$CTIMES -c $dsdshigh`
set crhigh = `echo $fdMhigh | sed -e 's/CT//' -e 's/:.*//'`

if ($crhigh > $synophigh) then
  @ cr = $synophigh + 1
  maketicket.csh gate=mdi.Synop wantlow=$cr wanthigh=$crhigh action=5
endif

