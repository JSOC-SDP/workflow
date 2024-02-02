#! /bin/csh -f
#
# make test gates and tasks for mdi.fd_M one minute data at lev1.8
# If the tasks and gates directories exist only the test gates and tasks will be rebuilt.
# If the gates and tasks diretories are not present, they will be created.

echo This program is only used once.
echo If you are sure you want to use it, remove the next line:
exit 1

if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow

# Stop the gatekeeper in case it is running.

cd $WORKFLOW_DIR
rm -f Keep_running
while (-e GATEKEEPERBUSY)
    echo waiting for gatekeeper to quit.
    sleep 5
end

if (!(-e tasks)) mkdir tasks
if (!(-e gates)) mkdir gates
if (!(-e scripts)) mkdir scripts
