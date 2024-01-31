#! /bin/csh -f

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

setenv WORKFLOW_ROOT "${DRMS_SRC_INSTALL_DIR}"/workflow
set path = ($WORKFLOW_ROOT/ $path)
