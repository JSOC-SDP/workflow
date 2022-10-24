#! /bin/csh -f

foreach task ( $WORKFLOW_DATA/tasks/* )
  foreach ticket ( `ls -1 $task/active/ | grep -v root` )
    ls -d $task/active/$ticket
  end
end


