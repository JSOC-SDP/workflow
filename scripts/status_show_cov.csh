#! /bin/csh -f

set drms_bins_install_dir = "${DRMS_BINS_INSTALL_DIR}"
set drms_incs_install_dir = "${DRMS_INCS_INSTALL_DIR}"
set drms_libs_install_dir = "${DRMS_LIBS_INSTALL_DIR}"
set drms_params_install_dir = "${DRMS_PARAMS_INSTALL_DIR}"
set drms_root_dir = "${DRMS_ROOT_DIR}"
set drms_scrs_install_dir = "${DRMS_SCRS_INSTALL_DIR}"
set drms_src_install_dir = "${DRMS_SRC_INSTALL_DIR}"
set drms_table_dir = "${DRMS_TABLE_DIR}"

source /home/jsoc/.setJSOCenv
set TIME_CONVERT = "${drms_bins_install_dir}"/time_convert
set SHOW_COVERAGE = "${drms_bins_install_dir}"/show_coverage
set SHOW_INFO = "${drms_bins_install_dir}"/show_info

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

##IRIS
#
#set showCovIRIS = "/web/jsoc/htdocs/data/.showCovIRIS"
#set FSN1 = `$SHOW_INFO iris.lev1'['$TenDaysAgo'/5h]' -q key=fsn | head -1`
#set FSN2 = `$SHOW_INFO iris.lev1'['$ThreeDaysAgo'/5h]' -q key=fsn | tail -1`
#$SHOW_COVERAGE iris.lev1 low=$FSN1 high=$FSN2 key=FSN | grep UNK > $showCovIRIS'.tmp'
#mv $showCovIRIS'.tmp' $showCovIRIS
