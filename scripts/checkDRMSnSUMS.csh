#! /bin/csh -f

# show_info mdi.fd_M_96m_lev18'[$]' -iqp >& /dev/null 
# set stat = $? 
#set count = `show_info hmi.m_720s'[2015.01.01_00:00:00_TAI]' -iqp  |& wc -l`
set count = `show_info hmi.m_720s'[$][3]' -qc`
if ($count[1] != 1) then
  set stat = 1
else
  set stat = 0
endif
exit $stat
