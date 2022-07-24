#! /bin/csh -f

#set echo
set count =  `show_info mdi.fd_M_96m_lev18'[$]' -cq`
# set stat = $? 
#set count = `show_info hmi.m_720s'[2015.01.01_00:00:00_TAI]' -iqp  |& wc -l`
if ($count[1] == 0 ) then
  set stat = 1
else
  set stat = 0
endif
exit $stat
