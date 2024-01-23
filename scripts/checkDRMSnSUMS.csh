#! /bin/csh -f

#set echo
set count =  `"$DRMS_BINS_INSTALL_DIR/show_info" mdi.fd_M_96m_lev18'[$]' -cq`
if ($count[1] == 0 ) then
  set stat = 1
else
  set stat = 0
endif
exit $stat
