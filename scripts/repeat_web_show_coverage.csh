#! /bin/csh -f
# modified to make one run per UT day, shortly after start of UT day.
if ( ! $?WORKFLOW_DIR ) then
    echo WORKFLOW_DIR environment variable is undefined, setting local variable to "${DRMS_SRC_INSTALL_DIR}"/workflow
    set WORKFLOW_DIR = "${DRMS_SRC_INSTALL_DIR}"/workflow
endif

set MAKE_TICKET = $WORKFLOW_DIR/maketicket.csh
set TIME_CONVERT = ${DRMS_BINS_INSTALL_DIR}/time_convert

set NOW = `date -u +%Y.%m.%d_%H:%M:%S`
set NOW_t = `$TIME_CONVERT time=$NOW`
@ now_ut_day = $NOW_t / 86400
@ now_ut_t = $now_ut_day * 86400
@ NEXTWANTHIGH_t = $now_ut_t + 86400
set NEXTWANTHIGH = `$TIME_CONVERT s=$NEXTWANTHIGH_t zone=UTC`
set NEXTWANTLOW = $NOW
#
# now do the desired command(s)
# but only if it has been at least 18 hours since last update.
@ h18 = 3600 * 18
if (-e /web/jsoc/htdocs/doc/data/LastShowCoverage.txt) then
  set prior = `cat /web/jsoc/htdocs/doc/data/LastShowCoverage.txt`
  set prior_t = `$TIME_CONVERT time=$prior`
else
  set prior_t = 0
endif

@ wanttime = $prior_t + $h18
if ($now_ut_t < $wanttime) exit 0

$MAKE_TICKET gate=repeat_web_show_coverage wantlow=$NEXTWANTLOW wanthigh=$NEXTWANTHIGH action=5
echo $NOW > /web/jsoc/htdocs/doc/data/LastShowCoverage.txt

/web/jsoc/htdocs/doc/data/hmi/coverage_tables/update_coverage
/web/jsoc/htdocs/doc/data/aia/update_coverage
/web/jsoc/htdocs/doc/data/mdi/update_coverage

exit 0
