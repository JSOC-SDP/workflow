# /bin/csh -f

if ($?WORKFLOW_ROOT) then
  set WFDIR = $WORKFLOW_DATA
  set WFCODE = $WORKFLOW_ROOT
else
  echo Need WORKFLOW_ROOT variable to be set.
  exit 1
endif

cd $WFDIR/gates

foreach gate ( * )
  echo " "
  cd $WFDIR/gates/$gate
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
