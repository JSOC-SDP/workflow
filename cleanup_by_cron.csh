#! /bin/csh -f

source $HOME/.cshrc
source $HOME/.login

set drms_bins_install_dir = "${DRMS_BINS_INSTALL_DIR}"
set drms_incs_install_dir = "${DRMS_INCS_INSTALL_DIR}"
set drms_libs_install_dir = "${DRMS_LIBS_INSTALL_DIR}"
set drms_params_install_dir = "${DRMS_PARAMS_INSTALL_DIR}"
set drms_root_dir = "${DRMS_ROOT_DIR}"
set drms_scrs_install_dir = "${DRMS_SCRS_INSTALL_DIR}"
set drms_src_install_dir = "${DRMS_SRC_INSTALL_DIR}"
set drms_table_dir = "${DRMS_TABLE_DIR}"

setenv WORKFLOW_DATA /home/jsoc/pipeline
set WORKFLOW_ROOT = "${drms_src_install_dir}"/workflow

cd $WORKFLOW_DATA

# Cleanup old log files of successful tasks.
# gatekeeper need not be stopped for this process since
# only completed tasks will have old logs removed.

set NOW = `date +%Y%m%d_%H%M`
$WORKFLOW_ROOT/cleanup.csh >& $WORKFLOW_DATA/cleanup_logs/cleanup_log.$NOW
