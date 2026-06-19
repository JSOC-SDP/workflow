# /bin/csh -f

# Verify our workflow environment variables are set
# Assumes this script is run from the root of the workflow directory
set script_dir = `cd $(dirname $0) && pwd`
source "$script_dir/setup_workflow.csh"

set GATES_DIR = $WORKFLOW_DATA/gates

cd $GATES_DIR

foreach gate ( * )
    echo " "
    cd $GATES_DIR/$gate
    set gs = `cat gatestatus`
    echo $gate ", gatestatus=$gs"
    if ($gs == 'HOLD') continue
    echo -n product= ; cat product
    echo -n low= ; cat low
    echo -n high= ; cat high
    echo -n nextupdate= ; cat nextupdate
    echo -n lastupdate= ; cat lastupdate
    if (-e statusbusy) echo warning -- statusbusy
end
