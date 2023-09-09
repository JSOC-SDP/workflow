#! /bin/csh -f
set drms_bins_install_dir = "${DRMS_BINS_INSTALL_DIR}"
set drms_incs_install_dir = "${DRMS_INCS_INSTALL_DIR}"
set drms_libs_install_dir = "${DRMS_LIBS_INSTALL_DIR}"
set drms_params_install_dir = "${DRMS_PARAMS_INSTALL_DIR}"
set drms_root_dir = "${DRMS_ROOT_DIR}"
set drms_scrs_install_dir = "${DRMS_SCRS_INSTALL_DIR}"
set drms_src_install_dir = "${DRMS_SRC_INSTALL_DIR}"
set drms_table_dir = "${DRMS_TABLE_DIR}"

setenv WORKFLOW_ROOT "${drms_src_install_dir}"/workflow

set QUE = k.q
set QSUB = /SGE2/bin/lx-amd64/qsub

set CMD = $cwd/TEST.cmd
set LOG = $cwd/TEST.runlog

echo "echo sleeping" > $CMD
echo "sleep 60" >> $CMD
echo "echo done" >> $CMD

$QSUB -sync yes -e $LOG -o $LOG -q $QUE $CMD


