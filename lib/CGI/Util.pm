package CGI::Util;

use strict;
use vars '$VERSION','@EXPORT_OK','@ISA','$EBCDIC','@A2E';
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(rearrange make_attributes unescape escape expires);

$VERSION = '1.1';

$EBCDIC = "\t" ne "\011";
if ($EBCDIC) {
@A2E = (
  0,  1,  2,  3, 55, 45, 46, 47, 22,  5, 21, 11, 12, 13, 14, 15,
 16, 17, 18, 19, 60, 61, 50, 38, 24, 25, 63, 39, 28, 29, 30, 31,
 64, 90,127,123, 91,108, 80,125, 77, 93, 92, 78,107, 96, 75, 97,
240,241,242,243,244,245,246,247,248,249,122, 94, 76,126,110,111,
124,193,194,195,196,197,198,199,200,201,209,210,211,212,213,214,
215,216,217,226,227,228,229,230,231,232,233,173,224,189, 95,109,
121,129,130,131,132,133,134,135,136,137,145,146,147,148,149,150,
151,152,153,162,163,164,165,166,167,168,169,192, 79,208,161,  7,
 32, 33, 34, 35, 36, 37,  6, 23, 40, 41, 42, 43, 44,  9, 10, 27,
 48, 49, 26, 51, 52, 53, 54,  8, 56, 57, 58, 59,  4, 20, 62,255,
 65,170, 74,177,159,178,106,181,187,180,154,138,176,202,175,188,
144,143,234,250,190,160,182,179,157,218,155,139,183,184,185,171,
100,101, 98,102, 99,103,158,104,116,113,114,115,120,117,118,119,
172,105,237,238,235,239,236,191,128,253,254,251,252,186,174, 89,
 68, 69, 66, 70, 67, 71,156, 72, 84, 81, 82, 83, 88, 85, 86, 87,
140, 73,205,206,203,207,204,225,112,221,222,219,220,141,142,223
      );
}

# Smart rearrangement of parameters to allow named parameter
# calling.  We do the rearangement if:
# the first parameter begins with a -
sub rearrange {
    my($order,@param) = @_;
    return () unless @param;

    if (ref($param[0]) eq 'HASH') {
	@param = %{$param[0]};
    } else {
	return @param 
	    unless (defined($param[0]) && substr($param[0],0,1) eq '-');
    }

    # map parameters into positional indices
    my ($i,%pos);
    $i = 0;
    foreach (@$order) {
	foreach (ref($_) eq 'ARRAY' ? @$_ : $_) { $pos{lc($_)} = $i; }
	$i++;
    }

    my (@result,%leftover);
    $#result = $#$order;  # preextend
    while (@param) {
	my $key = lc(shift(@param));
	$key =~ s/^\-//;
	if (exists $pos{$key}) {
	    $result[$pos{$key}] = shift(@param);
	} else {
	    $leftover{$key} = shift(@param);
	}
    }

    push (@result,make_attributes(\%leftover,1)) if %leftover;
    @result;
}

sub make_attributes {
    my $attr = shift;
    return () unless $attr && ref($attr) && ref($attr) eq 'HASH';
    my $escape = shift || 0;
    my(@att);
    foreach (keys %{$attr}) {
	my($key) = $_;
	$key=~s/^\-//;     # get rid of initial - if present
	$key=~tr/A-Z_/a-z-/; # parameters are lower case, use dashes
	my $value = $escape ? simple_escape($attr->{$_}) : $attr->{$_};
	push(@att,defined($attr->{$_}) ? qq/$key="$value"/ : qq/$key/);
    }
    return @att;
}

sub simple_escape {
  return unless defined(my $toencode = shift);
  $toencode =~ s{&}{&amp;}gso;
  $toencode =~ s{<}{&lt;}gso;
  $toencode =~ s{>}{&gt;}gso;
  $toencode =~ s{\"}{&quot;}gso;
# Doesn't work.  Can't work.  forget it.
#  $toencode =~ s{\x8b}{&#139;}gso;
#  $toencode =~ s{\x9b}{&#155;}gso;
  $toencode;
}

# unescape URL-encoded data
sub unescape {
  shift() if ref($_[0]) || (defined $_[1] && $_[0] eq $CGI::DefaultClass);
  my $todecode = shift;
  return undef unless defined($todecode);
  $todecode =~ tr/+/ /;       # pluses become spaces
    if ($EBCDIC) {
      $todecode =~ s/%([0-9a-fA-F]{2})/chr $A2E[hex($1)]/ge;
    } else {
      $todecode =~ s/%([0-9a-fA-F]{2})/chr hex($1)/ge;
    }
  return $todecode;
}

# URL-encode data
sub escape {
  shift() if ref($_[0]) || (defined $_[1] && $_[0] eq $CGI::DefaultClass);
  my $toencode = shift;
  return undef unless defined($toencode);
  $toencode=~s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
  return $toencode;
}

# This internal routine creates date strings suitable for use in
# cookies and HTTP headers.  (They differ, unfortunately.)
# Thanks to Mark Fisher for this.
sub expires {
    my($time,$format) = @_;
    $format ||= 'http';

    my(@MON)=qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
    my(@WDAY) = qw/Sun Mon Tue Wed Thu Fri Sat/;

    # pass through preformatted dates for the sake of expire_calc()
    $time = expire_calc($time);
    return $time unless $time =~ /^\d+$/;

    # make HTTP/cookie date string from GMT'ed time
    # (cookies use '-' as date separator, HTTP uses ' ')
    my($sc) = ' ';
    $sc = '-' if $format eq "cookie";
    my($sec,$min,$hour,$mday,$mon,$year,$wday) = gmtime($time);
    $year += 1900;
    return sprintf("%s, %02d$sc%s$sc%04d %02d:%02d:%02d GMT",
                   $WDAY[$wday],$mday,$MON[$mon],$year,$hour,$min,$sec);
}

# This internal routine creates an expires time exactly some number of
# hours from the current time.  It incorporates modifications from 
# Mark Fisher.
sub expire_calc {
    my($time) = @_;
    my(%mult) = ('s'=>1,
                 'm'=>60,
                 'h'=>60*60,
                 'd'=>60*60*24,
                 'M'=>60*60*24*30,
                 'y'=>60*60*24*365);
    # format for time can be in any of the forms...
    # "now" -- expire immediately
    # "+180s" -- in 180 seconds
    # "+2m" -- in 2 minutes
    # "+12h" -- in 12 hours
    # "+1d"  -- in 1 day
    # "+3M"  -- in 3 months
    # "+2y"  -- in 2 years
    # "-3m"  -- 3 minutes ago(!)
    # If you don't supply one of these forms, we assume you are
    # specifying the date yourself
    my($offset);
    if (!$time || (lc($time) eq 'now')) {
        $offset = 0;
    } elsif ($time=~/^\d+/) {
        return $time;
    } elsif ($time=~/^([+-]?(?:\d+|\d*\.\d*))([mhdMy]?)/) {
        $offset = ($mult{$2} || 1)*$1;
    } else {
        return $time;
    }
    return (time+$offset);
}

1;
