#! /bin/csh -f

# show_info mdi.fd_M_96m_lev18'[$]' -iqp >& /dev/null 
# set stat = $? 
set count = `show_info mdi.fd_M_96m_lev18'[$]' -iqp  |& wc -l`
if ($count[1] != 1) then
  set stat = 1
else
  set stat = 0
endif
exit $stat
