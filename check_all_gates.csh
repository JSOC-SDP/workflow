# /bin/csh -f

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

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
