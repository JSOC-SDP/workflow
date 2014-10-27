#! /bin/csh -f

set echo
set TIME_CONVERT = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/time_convert
set SHOW_COVERAGE = /home/jsoc/cvs/Development/JSOC/bin/$JSOC_MACHINE/show_coverage
set SHOW_INFO = /home/jsoc/cvs/JSOC/bin/$JSOC_MACHINE/show_info

set now = `date -u +%Y.%m.%d_%H:%M:%S`
set now_t = `$TIME_CONVERT time=$now`

@ TenDaysAgo_t =  $now_t - 864000
set TenDaysAgo = `$TIME_CONVERT s=$TenDaysAgo_t`
@ ThreeDaysAgo_t = $now_t - 259200
set ThreeDaysAgo = `$TIME_CONVERT s=$ThreeDaysAgo_t`


# HMI

set showCov = "/web/jsoc/htdocs/data/.showCov" 
$SHOW_COVERAGE ds=hmi.M_45s low=$TenDaysAgo high=$now | grep UNK > $showCov'.tmp'
mv $showCov'.tmp' $showCov

set showCovNRT = "/web/jsoc/htdocs/data/.showCovNRT"
$SHOW_COVERAGE ds=hmi.V_720s_nrt low=$ThreeDaysAgo high=$now | grep UNK > $showCovNRT'.tmp'
mv $showCovNRT'.tmp' $showCovNRT

# AIA

set showCovAIA = "/web/jsoc/htdocs/data/.showCovAIA"

$SHOW_COVERAGE aia.lev1 low=$TenDaysAgo high=$ThreeDaysAgo key=FSN | grep UNK > $showCovAIA'.tmp'
mv $showCovAIA'.tmp' $showCovAIA

set fFSN = `$SHOW_INFO aia.lev1_nrt2'['$ThreeDaysAgo'/1m]' n=1 key=FSN,t_obs -q`
set lFSN = `$SHOW_INFO aia.lev1_nrt2'[]' n=-1 key=FSN,t_obs -q`
set showCovAIANRT = "/web/jsoc/htdocs/data/.showCovAIANRT"
$SHOW_COVERAGE aia.lev1_nrt2 low=$fFSN[1] high=$lFSN[1] key=FSN | grep UNK > $showCovAIANRT'.tmp'
mv $showCovAIANRT'.tmp' $showCovAIANRT

#IRIS

set showCovIRIS = "/web/jsoc/htdocs/data/.showCovIRIS"
$SHOW_COVERAGE iris.lev1 low=$TenDaysAgo high=$ThreeDaysAgo key=FSN | grep UNK > $showCovIRIS'.tmp'
mv $showCovIRIS'.tmp' $showCovIRIS
