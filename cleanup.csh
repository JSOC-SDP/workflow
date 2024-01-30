# /bin/csh -f

# set echo

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

cd $WORKFLOW_DATA/tasks

foreach task ( * )
    pushd $WORKFLOW_DATA/tasks/$task
    if (!(-e retain)) continue
    set DAYS = `cat retain`
    if ($DAYS <= 0) continue
    set here = $cwd
    cd archive/ok
    find . -depth -mtime +$DAYS -print -delete 
    cd ../logs
    find . -depth -mtime +$DAYS -print -delete 
    cd ../failed
    find . -depth -mtime +10 -print -delete 
    cd $here
    set rootreturn = active/$task'-root'/ticket_return
    if (-e $rootreturn) then
        cd $rootreturn
        find . -depth -mtime +$DAYS -print -delete 
        cd $here
    endif

    popd
end

exit 0
