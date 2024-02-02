#! /bin/csh -f

# echo starting $0 $*
if ( ! $?WORKFLOW_DATA ) then
    echo WORKFLOW_DATA environment variable is undefined
    exit 1
endif

set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow

foreach ATTR (TYPE WANTLOW WANTHIGH GATE)
    set ATTRTXT = `grep $ATTR ticket`
    set $ATTRTXT
end

set PRODUCT = `cat $WORKFLOW_DATA/gates/$GATE/product`

"${DRMS_BINS_INSTALL_DIR}"/set_gaps_missing ds=$PRODUCT low=$WANTLOW high=$WANTHIGH

exit $status
