#
# $Id: Tr.pm,v 0.77 2002/01/14 11:06:55 dankogai Exp $
#

package Jcode::Tr;

use strict;
use vars qw($VERSION $RCSID);

$RCSID = q$Id: Tr.pm,v 0.77 2002/01/14 11:06:55 dankogai Exp $;
$VERSION = do { my @r = (q$Revision: 0.77 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use Carp;

use Jcode::Constants qw(:all);
use vars qw(%_TABLE);

sub tr {
    # $prev_from, $prev_to, %table are persistent variables
    my ($r_str, $from, $to, $opt) = @_;
    my (@from, @to);
    my $n = 0;

    undef %_TABLE;
    &_maketable($from, $to, $opt);

    $$r_str =~ s(
		 ([\x80-\xff][\x00-\xff]|[\x00-\xff])
		 )
    {defined($_TABLE{$1}) && ++$n ? 
	 $_TABLE{$1} : $1}ogex;

    return $n;
}

sub _maketable{
    my( $from, $to, $opt ) = @_;
 
    $from =~ s/($RE{EUC_0212}-$RE{EUC_0212})/&_expnd3($1)/geo;
    $from =~ s/($RE{EUC_KANA}-$RE{EUC_KANA})/&_expnd2($1)/geo;
    $from =~ s/($RE{EUC_C   }-$RE{EUC_C   })/&_expnd2($1)/geo;
    $from =~ s/($RE{ASCII   }-$RE{ASCII   })/&_expnd1($1)/geo;
    $to   =~ s/($RE{EUC_0212}-$RE{EUC_0212})/&_expnd3($1)/geo;
    $to   =~ s/($RE{EUC_KANA}-$RE{EUC_KANA})/&_expnd2($1)/geo;
    $to   =~ s/($RE{EUC_C   }-$RE{EUC_C   })/&_expnd2($1)/geo;
    $to   =~ s/($RE{ASCII   }-$RE{ASCII   })/&_expnd1($1)/geo;

    my @from = $from =~ /$RE{EUC_0212}|$RE{EUC_KANA}|$RE{EUC_C}|[\x00-\xff]/go;
    my @to   = $to   =~ /$RE{EUC_0212}|$RE{EUC_KANA}|$RE{EUC_C}|[\x00-\xff]/go;

    push @to, ($opt =~ /d/ ? '' : $to[-1]) x ($#from - $#to) if $#to < $#from;
    @_TABLE{@from} = @to;

}

sub _expnd1 {
    my ($str) = @_;
    # s/\\(.)/$1/og; # I dunno what this was doing!?
    my($c1, $c2) = unpack('CxC', $str);
    if ($c1 <= $c2) {
        for ($str = ''; $c1 <= $c2; $c1++) {
            $str .= pack('C', $c1);
        }
    }
    return $str;
}

sub _expnd2 {
    my ($str) = @_;
    my ($c1, $c2, $c3, $c4) = unpack('CCxCC', $str);
    if ($c1 == $c3 && $c2 <= $c4) {
        for ($str = ''; $c2 <= $c4; $c2++) {
            $str .= pack('CC', $c1, $c2);
        }
    }
    return $str;
}

sub _expnd3 {
    my ($str) = @_;
    my ($c1, $c2, $c3, $c4, $c5, $c6) = unpack('CCCxCCC', $str);
    if ($c1 == $c4 && $c2 == $c5 && $c3 <= $c6) {
        for ($str = ''; $c3 <= $c6; $c3++) {
            $str .= pack('CCC', $c1, $c2, $c3);
        }
    }
    return $str;
}

1;
