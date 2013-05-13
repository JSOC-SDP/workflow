#! /bin/csh -f

foreach ticket ( $WORKFLOW_DATA/tasks/*/active/*2013*/ticket )
  @ lines = `wc -l $ticket | awk '{print $1}'`
  if ( $lines < 5 ) then
     ls -l $ticket 
  endif
end

  
