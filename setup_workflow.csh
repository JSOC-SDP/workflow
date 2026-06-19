# setup_workflow.csh
# Verify the workflow data directory environment variable is set and exists.
if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

# Verify the workflow root environment variable is set and exists.
if ( ! $?WORKFLOW_DIR ) then
    echo WORKFLOW_DIR environment variable is undefined
    exit 1
endif

# Verify the workflow image directory environment variable is set and exists.
# Then create the image directory if it does not exist.
if ( ! $?WORKFLOW_IMG_ROOT ) then
    echo WORKFLOW_IMG_ROOT environment variable is undefined
    exit 1
endif

if (!(-e $WORKFLOW_IMG_ROOT)) then
    mkdir $WORKFLOW_IMG_ROOT
    if ($?) then 
        echo ERROR making image root directory $WORKFLOW_IMG_ROOT
        exit 1
    endif
endif
