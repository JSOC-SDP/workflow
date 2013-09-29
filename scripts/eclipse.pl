#! /usr/bin/perl -w

# sets lev1 quality bits for eclipse times.  Eclipse times are
# updated MANUALLY in this script as needed, and used by update_hmi.Vector,
# update_hmi.LOS, update_hmi.Vector_nrt and update_hmi.LOSnrt.
# Usage:  eclipse.pl <wantlow> <wanthigh> <nrt>     
#         wantlow/high are processing times for observables 

###########################################################################################################
###                                       
###                             Update eclipe times here 
###                                       

    @begin_eclipse = ("2011.03.04_12:27:00_TAI", "2012.02.21_13:14:00_UTC");
    @end_eclipse =   ("2011.03.04_13:00:00_TAI", "2012.02.21_15:00:00_UTC");

###
###########################################################################################################

$TIME_CONVERT = "/home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/time_convert";
$SHOW_INFO = "/home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/show_info";
$SET_INFO = "/home/jsoc/cvs/Development/JSOC/bin/linux_x86_64/set_info";

### mask to compare against existing quality bits
$M = "00002000";    
$M_binary = sprintf "%032b", hex( $M );

###  time range for observables being processed
$WANTLOW = $ARGV[0];   
$WANTHIGH = $ARGV[1];
$w1 = `$TIME_CONVERT time=$WANTLOW`; chomp($w1);
$w2 = `$TIME_CONVERT time=$WANTHIGH`; chomp($w2);
#buffer to get all possible affected filtergrams for vector processing
$W1_need = $w1 - 720;
$W2_need = $w2 + 720;
$wanthigh_need = `$TIME_CONVERT s=$W2_need zone=UTC`; chomp($wanthigh_need);

if ( ($#ARGV == 2) && ($ARGV[2] eq "nrt") ) {
  $lev1 = "hmi.lev1_nrt";
  $now = `date -u +%Y.%m.%d_%H:%M_UTC`; chomp($now);
  $now_s = `$TIME_CONVERT time=$now`; chomp($now_s);
  $oldestNRT_s = $now_s - 1728000;  #20 days
  if ( ($w1 < $oldestNRT_s) || ($w2 < $oldestNRT_s) ) {
    print "NRT data not available for $WANTLOW-$WANTHIGH\n";
    print "You may be able to process some by hand\n";
    exit;
  }
} else {
  $lev1 = "hmi.lev1";
}


###  check to see if obs. processing range includes any eclipse times
for ( $i = 0; $i <= $#begin_eclipse; $i++) {
  $E1_s = `$TIME_CONVERT time=$begin_eclipse[$i] zone=UTC`; chomp($E1_s);
  $E2_s = `$TIME_CONVERT time=$end_eclipse[$i] zone=UTC`; chomp($E2_s);
   
  if ( (($E1_s >= $w1) && ($E1_s <= $w2)) || (($E2_s >= $w1) && ($E2_s <= $w2)) || (($E1_s < $w1) && ($E2_s > $w2)) ) {
    open (LOG, ">/scr21/jsocprod/eclipse_bits.log") || warn "Can't open eclipse log: $!\n";
    if ( ($E1_s >= $w1) && ($E2_s <= $w2) ) {
      $start = $begin_eclipse[$i];
      $end = $end_eclipse[$i];
    } elsif ( ($E1_s < $w1) && ($E2_s <= $w2) ) {
      while ( $W1_need < $E1_s ) {
        $W1_need++;
      }
      $wantlow_need = `$TIME_CONVERT s=$W1_need zone=UTC`; chomp($wantlow_need);
      $start = $wantlow_need;
      $end = $end_eclipse[$i];
    } elsif ( ($E1_s >= $w1) && ($E2_s > $w2) ) {
      $start = $begin_eclipse[$i];
      while ( $W2_need > $E2_s ) {
        $W2_need--;
      }
      $wanthigh_need = `$TIME_CONVERT s=$W2_need zone=UTC`; chomp($wanthigh_need);
      $end = $wanthigh_need;
    } elsif ( ($E1_s < $w1) && ($E2_s > $w2) ) {
      while ( $W1_need < $E1_s ) {
        $W1_need++;
      }
      $wantlow_need = `$TIME_CONVERT s=$W1_need zone=UTC`; chomp($wantlow_need);
      while ( $W2_need > $E2_s ) {
        $W2_need--;
      }
      $wanthigh_need = `$TIME_CONVERT s=$W2_need zone=UTC`; chomp($wanthigh_need);
      $start = $wantlow_need;
      $end = $wanthigh_need;
    }
  } else {
    next;
  }

###  set quality bits for eclipse times in WANTLOW-WANTHIGH range  
#  $FFSN = `$SHOW_INFO -q key=FSN $lev1'['$start'/1m]' n=1`; chomp($FFSN);
#  $LFSN = `$SHOW_INFO -q key=FSN $lev1'['$end'/1m]' n=1`; chomp($LFSN);
  if ( ($FFSN = `$SHOW_INFO -q key=FSN $lev1'['$start'/1m]' n=1`) && ($LFSN = `show_info -q key=FSN $lev1'['$end'/1m]' n=1`) ) {
    chomp($FFSN);
    chomp($LFSN);
    $FSN = $FFSN;
    while ($FSN <= $LFSN) {
      $thisqual = `$SHOW_INFO -q key=QUALITY $lev1'[]['$FSN']'`; chomp($thisqual);
      $Q = substr($thisqual, 2,9); 
      $Q_binary = sprintf "%032b", hex( $Q );
      $check_qual = $Q_binary & $M_binary;
      $check_qual_hex = sprintf('%08X', oct("0b$check_qual"));
      if ( $check_qual_hex != $M ) {
        $thisdecimal = hex($Q);
        $newqual = $thisdecimal + 8192;
        print LOG "$SET_INFO ds=$lev1'[]['$FSN']' QUALITY=$newqual JSOC_DBUSER=production\n";
       `$SET_INFO ds=$lev1'[]['$FSN']' QUALITY=$newqual JSOC_DBUSER=production`;
      } 
      $FSN++;
    }
  } else {
    print "No valid beginning and end FSNs\n";
    exit;
  }
  
  close LOG;
}
