;# ctime.pl is a simple Perl emulation for the well known ctime(3C) function.
;#
;# Waldemar Kebsch, Federal Republic of Germany, November 1988
;# kebsch.pad@nixpbe.UUCP
;# Modified March 1990 to better handle timezones
;#  $Id: ctime.pl,v 1.3 90/03/22 10:49:10 hakanson Exp $
;#   Marion Hakanson (hakanson@cse.ogi.edu)
;#   Oregon Graduate Institute of Science and Technology
;#
;# usage:
;#
;#     #include <ctime.pl>          # see the -P and -I option in perl.man
;#     $Date = do ctime(time);

@DoW = ('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
@MoY = ('Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec');

sub ctime {
    local($time) = @_;
    local($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);

    # Use GMT if can't find local TZ
    $TZ = defined($ENV{'TZ'}) ? $ENV{'TZ'} : 'GMT';
    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
        ($TZ eq 'GMT') ? gmtime($time) : localtime($time);
    # Hack to deal with 'PST8PDT' format of TZ
    if ( $TZ =~ /-?\d+/ ) {
        $TZ = $isdst ? $' : $`;
    }
    $TZ .= " " unless $TZ eq "";
    $year += ($year < 70) ? 2000 : 1900;
    sprintf("%s %s %2d %2d:%02d:%02d %s%4d\n",
      $DoW[$wday], $MoY[$mon], $mday, $hour, $min, $sec, $TZ, $year);
}
1;
