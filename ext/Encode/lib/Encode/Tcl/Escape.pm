package Encode::Tcl::Escape;
use strict;
our $VERSION = do {my @r=(q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r};
use base 'Encode::Encoding';

use Carp;

use constant SI  => "\cO";
use constant SO  => "\cN";
use constant SS2 => "\e\x4E"; # ESC N
use constant SS3 => "\e\x4F"; # ESC O

sub read
{
    my ($obj,$fh,$name) = @_;
    my(%tbl, @seq, $enc, @esc, %grp, %mbc);
    while (<$fh>)
    {
	next unless /^(\S+)\s+(.*)$/;
	my ($key,$val) = ($1,$2);
	$val =~ s/^\{(.*?)\}/$1/g;
	$val =~ s/\\x([0-9a-f]{2})/chr(hex($1))/ge;

	if ($enc = Encode->getEncoding($key))
	{
	    $tbl{$val} =
		ref($enc) eq 'Encode::Tcl' ? $enc->loadEncoding : $enc;

	    $mbc{$val} =
		$val !~ /\e\x24/ ? 1 : # single-byte
		    $val =~ /[\x30-\x3F]$/ ? 2 : # (only 2 is supported)
			$val =~ /[\x40-\x5F]$/ ? 2 : # double byte
			    $val =~ /[\x60-\x6F]$/ ? 3 : # triple byte
				$val =~ /[\x70-\x7F]$/ ? 4 :
				  # 4 or more (only 4 is supported)
				    croak("odd sequence is defined");

	    push @seq, $val;

	    $grp{$val} =
		$val =~ /\e\x24?[\x28]/  ? 0 : # G0 : SI
		    $val =~ /\e\x24?[\x29\x2D]/ ? 1 : # G1 : SO
			$val =~ /\e\x24?[\x2A\x2E]/ ? 2 : # G2 : SS2
			    $val =~ /\e\x24?[\x2B\x2F]/ ? 3 : # G3 : SS3
				0;  # G0 (ESC 02/04 F, etc.)
	}
	else
	{
	    $obj->{$key} = $val;
	}
	if ($val =~ /^\e(.*)/)
	{
	    push(@esc, quotemeta $1);
	}
    }
    $obj->{'Grp'} = \%grp; # graphic chars
    $obj->{'Mbc'} = \%mbc; # bytes per char
    $obj->{'Seq'} = \@seq; # escape sequences
    $obj->{'Tbl'} = \%tbl; # encoding tables
    $obj->{'Esc'} = join('|', @esc); # regex of sequences following ESC
    return $obj;
}

sub decode
{
    my ($obj,$str,$chk) = @_;
    my $tbl = $obj->{'Tbl'};
    my $seq = $obj->{'Seq'};
    my $mbc = $obj->{'Mbc'};
    my $grp = $obj->{'Grp'};
    my $esc = $obj->{'Esc'};
    my $std = $seq->[0];
    my $cur = $std;
    my @sta = ($std, undef, undef, undef); # G0 .. G3 state
    my $s   = 0; # state of SO-SI.   0 (G0) or 1 (G1);
    my $ss  = 0; # state of SS2,SS3. 0 (G0), 2 (G2) or 3 (G3);
    my $uni;
    while (length($str))
    {
	if ($str =~ s/^\e//)
	{
	    if ($str =~ s/^($esc)//)
	    {
		my $e = "\e$1";
		$sta[ $grp->{$e} ] = $e if $tbl->{$e};
	    }
	    # appearance of "\eN\eO" or "\eO\eN" isn't supposed.
	    # but in that case, the former will be ignored.
	    elsif ($str =~ s/^\x4E//)
	    {
		$ss = 2;
	    }
	    elsif ($str =~ s/^\x4F//)
	    {
		$ss = 3;
	    }
	    else
	    {
		# strictly, ([\x20-\x2F]*[\x30-\x7E]). '?' for chopped.
		$str =~ s/^([\x20-\x2F]*[\x30-\x7E]?)//;
		if ($chk && ! length $str)
		{
		    $str = "\e$1"; # split sequence
		    last;
		}
		croak "unknown escape sequence: ESC $1";
	    }
	    next;
	}
	if ($str =~ s/^\cN//) # SO
	{
	    $s = 1; next;
	}
	if ($str =~ s/^\cO//) # SI
	{
	    $s = 0; next;
	}

	$cur = $ss ? $sta[$ss] : $sta[$s];

	length($str) < $mbc->{$cur} and last; # split leading byte

	my $cc = substr($str, 0, $mbc->{$cur}, '');

	my $x = $tbl->{$cur}->decode($cc);
	defined $x or Encode::Tcl::no_map_in_decode($obj->{'Name'}, $cc);
	$uni .= $x;
	$ss = 0;
    }
    if ($chk)
    {
	my $back = join('', grep defined($_) && $_ ne $std, @sta);
	$back .= SO if $s;
	$back .= $ss == 2 ? SS2 : $ss == 3 ? SS3 : '';
	$_[1] = $back.$str;
    }
    return $uni;
}

sub encode
{
    my ($obj,$uni,$chk) = @_;
    my $tbl = $obj->{'Tbl'};
    my $seq = $obj->{'Seq'};
    my $grp = $obj->{'Grp'};
    my $ini = $obj->{'init'};
    my $std = $seq->[0];
    my $str = $ini;
    my @sta = ($std,undef,undef,undef); # G0 .. G3 state
    my $cur = $std;
    my $pG = 0; # previous G: 0 or 1.
    my $cG = 0; # current G: 0,1,2,3. 

    if ($ini && defined $grp->{$ini})
    {
	$sta[ $grp->{$ini} ] = $ini;
    }

    while (length($uni))
    {
	my $ch = substr($uni,0,1,'');
	my $x;
	foreach my $e_seq (@$seq)
	{
	    $x = $tbl->{$e_seq}->encode($ch, 1);
	    $cur = $e_seq, last if defined $x;
	}
	unless (defined $x)
	{
	    $chk or Encode::Tcl::no_map_in_encode(ord($ch), $obj->{'Name'});
	    return undef;
	}
	$cG   = $grp->{$cur};
	$str .= $sta[$cG] = $cur unless $cG < 2 && $cur eq $sta[$cG];

	$str .= $cG == 0 && $pG == 1 ? SI :
	    $cG == 1 && $pG == 0 ? SO :
		$cG == 2 ? SS2 :
		    $cG == 3 ? SS3 : "";
	$str .= $x;
	$pG = $cG if $cG < 2;
    }
    $str .= SI if $pG == 1; # back to G0
    $str .= $std  unless $std eq $sta[0]; # G0 to ASCII
    $str .= $obj->{'final'}; # necessary? I don't know what is this for.
    $_[1] = $uni if $chk;
    return $str;
}

1;
__END__
