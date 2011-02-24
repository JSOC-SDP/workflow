# /bin/csh -f

# set echo

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

cd $WFDIR/tasks

foreach task ( * )
  pushd $WFDIR/tasks/$task
  if (!(-e retain)) continue
  set DAYS = `cat retain`
  if ($DAYS <= 0) continue
  set here = $cwd
  cd archive/ok
  find . -depth -mtime +$DAYS -print -delete 
  cd ../logs
  find . -depth -mtime +$DAYS -print -delete 
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
