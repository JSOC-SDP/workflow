#! /bin/csh -f

###  BigRedButton.csh should be run as jsocprod on n04 clean up gates and tasks
###  after a major failure in production processing:
###  
###  1. Stop the gatekeeper
###  2. Kill all taskmanagers running on n04
###  3. Delete all tickets and miscellaneous files from all gates and tasks
###  4. Kill anything running in qsub
###  5. Check for valid low and high keys in gates 
###  6. Run the cleanup script and delete failed directories to make it easier to check gates and tasks
###  7  Restart the gatekeeper

set user = $USER
if ( $user != 'jsocprod' ) then
  echo ""
  echo "Must run as user jsocprod on n04."
  echo ""
  exit
endif

set WORKFLOW_DATA = /home/jsoc/pipeline
#set WORKFLOW_ROOT = /home/phil/jsoc/proj/workflow
set WORKFLOW_ROOT = /home/jsoc/cvs/Development/JSOC/proj/workflow
set TASKS = $WORKFLOW_DATA/tasks
set GATES = $WORKFLOW_GATES/gates

set echo 

#  1  #

rm $WORKFLOW_DATA/Keep_running


 #  2  #

@ TM_num = `ps -ef | grep taskmanager.csh | wc -l`
while  ( $TM_num > 0 )
  foreach TM ( `ps -ef | grep taskmanager.csh | awk '{print $2}'` ) 
    kill -9 $TM
  end
 e@ TM_num = `ps -ef | grep taskmanager.csh | wc -l`
while  ( `ps -ef | grep taskmanager.csh | wc -l` > 0 )
end


#  3  #

cd $TASKS
foreach task ( * )
  rm -rf $task/active/*
  echo 0 > $task/state
  rm $task/active/$task'-root'/pending_tickets/*
end

cd $GATES
foreach gate ( * )
  rm $gate/active_tickets/*
  rm $gate/new_tickets/*
end


##  4  ##

foreach QSub ( `qstat | grep jsocprod | egrep '(OBS|VEC|NRT|IMG|MSK|FITS|keiji)' | awk '{print $1}'` )
  qdel $Qsub
end


##  5  ##

cd $WORKFLOW_ROOT
./cleanup.csh
cd $TASKS
foreach task ( * )
  rm -rf $task/archive/failed/*
end


##  6  ##
 
cd $GATES
foreach gate ( * )
  echo $gate
  cat $gate/low
  cat $gate/high
  echo ""
end

##  7  ##

#/home/phil/jsoc/proj/workflow/gatekeeper.restart >> /home/jsoc/pipeline/restart.log &
/home/jsoc/cvs/Development/JSOC/proj/workflow/gatekeeper.restart >> /home/jsoc/pipeline/restart.log &


echo "1. Check for bad low high times in gates (should be the last thing on the screen)."
echo "2. Make sure there are no taskmanagers running."
echo "3. Check gates and tasks (chechgates.csh | more, etc)."
echo "4. Restart failed tickets or run maketickets to get things running again."




