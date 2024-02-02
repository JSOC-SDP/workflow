if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow

set npath = `echo $path | grep workflow | wc -l`
if ($npath < 8) set path = ($WORKFLOW_DIR $path)
