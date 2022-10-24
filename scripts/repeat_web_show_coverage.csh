#! /bin/csh -f
set WFCODE = $WORKFLOW_ROOT

# modified to make one run per UT day, shortly after start of UT day.

set NOW = `date -u +%Y.%m.%d_%H:%M:%S`
set NOW_t = `time_convert time=$NOW`
@ now_ut_day = $NOW_t / 86400
@ now_ut_t = $now_ut_day * 86400
@ NEXTWANTHIGH_t = $now_ut_t + 86400
set NEXTWANTHIGH = `time_convert s=$NEXTWANTHIGH_t zone=UTC`
set NEXTWANTLOW = $NOW
#
# now do the desired command(s)
# but only if it has been at least 18 hours since last update.
@ h18 = 3600 * 18
if (-e /web/jsoc/htdocs/doc/data/LastShowCoverage.txt) then
  set prior = `cat /web/jsoc/htdocs/doc/data/LastShowCoverage.txt`
  set prior_t = `time_convert time=$prior`
else
  set prior_t = 0
endif

@ wanttime = $prior_t + $h18
if ($now_ut_t < $wanttime) exit 0

$WFCODE/maketicket.csh gate=repeat_web_show_coverage wantlow=$NEXTWANTLOW wanthigh=$NEXTWANTHIGH action=5
echo $NOW > /web/jsoc/htdocs/doc/data/LastShowCoverage.txt

/web/jsoc/htdocs/doc/data/hmi/coverage_tables/update_coverage
# /web/jsoc/htdocs/doc/data/hmi_test/update_coverage
/web/jsoc/htdocs/doc/data/aia/update_coverage
# /web/jsoc/htdocs/doc/data/aia_test/update_coverage
/web/jsoc/htdocs/doc/data/mdi/update_coverage

exit 0
