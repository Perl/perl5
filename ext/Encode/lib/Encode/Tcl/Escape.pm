package Encode::Tcl::Escape;
use strict;
our $VERSION = do {my @r=(q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r};
use base 'Encode::Encoding';

use Carp;

use constant SI  => "\cO";
use constant SO  => "\cN";
use constant SS2 => "\eN";
use constant SS3 => "\eO";

sub read
{
    my ($obj,$fh,$name) = @_;
    my(%tbl, @seq, $enc, @esc, %grp);
    while (<$fh>)
    {
	next unless /^(\S+)\s+(.*)$/;
	my ($key,$val) = ($1,$2);
	$val =~ s/^\{(.*?)\}/$1/g;
	$val =~ s/\\x([0-9a-f]{2})/chr(hex($1))/ge;

	if($enc = Encode->getEncoding($key))
	{
	    $tbl{$val} = ref($enc) eq 'Encode::Tcl' ? $enc->loadEncoding : $enc;
	    push @seq, $val;
	    $grp{$val} =
		$val =~ m|[(]|  ? 0 : # G0 : SI  eq "\cO"
			   $val =~ m|[)-]| ? 1 : # G1 : SO  eq "\cN"
			       $val =~ m|[*.]| ? 2 : # G2 : SS2 eq "\eN"
				   $val =~ m|[+/]| ? 3 : # G3 : SS3 eq "\eO"
				       0;  # G0
	}
	else
	{
	    $obj->{$key} = $val;
	}
	if($val =~ /^\e(.*)/)
	{
	    push(@esc, quotemeta $1);
	}
    }
    $obj->{'Grp'} = \%grp; # graphic chars
    $obj->{'Seq'} = \@seq; # escape sequences
    $obj->{'Tbl'} = \%tbl; # encoding tables
    $obj->{'Esc'} = join('|', @esc); # regex of sequences following ESC
    return $obj;
}

sub decode
{
    my ($obj,$str,$chk) = @_;
    my $name = $obj->{'Name'};
    my $tbl = $obj->{'Tbl'};
    my $seq = $obj->{'Seq'};
    my $grp = $obj->{'Grp'};
    my $esc = $obj->{'Esc'};
    my $ini = $obj->{'init'};
    my $fin = $obj->{'final'};
    my $std = $seq->[0];
    my $cur = $std;
    my @sta = ($std, undef, undef, undef); # G0 .. G3 state
    my $s   = 0; # state of SO-SI.   0 (G0) or 1 (G1);
    my $ss  = 0; # state of SS2,SS3. 0 (G0), 2 (G2) or 3 (G3);
    my $uni;
    while (length($str))
    {
	my $cc = substr($str,0,1,'');
	if($cc eq "\e")
	{
	    if($str =~ s/^($esc)//)
	    {
		my $e = "\e$1";
		$sta[ $grp->{$e} ] = $e if $tbl->{$e};
	    }
	    # appearance of "\eN\eO" or "\eO\eN" isn't supposed.
	    # but in that case, the former will be ignored.
	    elsif($str =~ s/^N//)
	    {
		$ss = 2;
	    }
	    elsif($str =~ s/^O//)
	    {
		$ss = 3;
	    }
	    else
	    {
		# strictly, ([\x20-\x2F]*[\x30-\x7E]). '?' for chopped.
		$str =~ s/^([\x20-\x2F]*[\x30-\x7E]?)//;
		if($chk && ! length $str)
		{
		    $str = "\e$1"; # split sequence
		    last;
		}
		croak "unknown escape sequence: ESC $1";
	    }
	    next;
	}
	if($cc eq SO)
	{
	    $s = 1; next;
	}
	if($cc eq SI)
	{
	    $s = 0; next;
	}

	$cur = $ss ? $sta[$ss] : $sta[$s];

	if(ref($tbl->{$cur}) ne 'Encode::Tcl::Table')
	{
	    $uni .= $tbl->{$cur}->decode($cc);
	    $ss = 0;
	    next;
	}
	my $ch    = ord($cc);
	my $rep   = $tbl->{$cur}->{'Rep'};
	my $touni = $tbl->{$cur}->{'ToUni'};
	my $x;
	if (&$rep($ch) eq 'C')
	{
	    $x = $touni->[0][$ch];
	}
	else
	{
	    if(! length $str)
	    {
		$str = $cc; # split leading byte
		last;
	    }
	    my $c2 = substr($str,0,1,'');
	    $cc .= $c2;
	    $x = $touni->[$ch][ord($c2)];
	}
	unless (defined $x)
	{
	  Encode::Tcl::no_map_in_decode($name, $cc.$str);
	}
	$uni .= $x;
	$ss = 0;
    }
    if($chk)
    {
	my $back = join('', grep defined($_) && $_ ne $std, @sta);
	$back .= SO if $s;
	$back .= $ss == 2 ? SS2 : SS3 if $ss;
	$_[1] = $back.$str;
    }
    return $uni;
}

sub encode
{
    my ($obj,$uni,$chk) = @_;
    my $name = $obj->{'Name'};
    my $tbl = $obj->{'Tbl'};
    my $seq = $obj->{'Seq'};
    my $grp = $obj->{'Grp'};
    my $ini = $obj->{'init'};
    my $fin = $obj->{'final'};
    my $std = $seq->[0];
    my $str = $ini;
    my @sta = ($std,undef,undef,undef); # G0 .. G3 state
    my $cur = $std;
    my $pG = 0; # previous G: 0 or 1.
    my $cG = 0; # current G: 0,1,2,3. 

    if($ini && defined $grp->{$ini})
    {
	$sta[ $grp->{$ini} ] = $ini;
    }

    while (length($uni))
    {
	my $ch = substr($uni,0,1,'');
	my $x;
	foreach my $e_seq (@$seq)
	{
	    $x = ref($tbl->{$e_seq}) eq 'Encode::Tcl::Table'
		? $tbl->{$e_seq}->{FmUni}->{$ch}
	    : $tbl->{$e_seq}->encode($ch,1);
	    $cur = $e_seq, last if defined $x;
	}
	unless (defined $x)
	{
	    unless($chk)
	    {
	      Encode::Tcl::no_map_in_encode(ord($ch), $name)
	      }
	    return undef;
	}
	if(ref($tbl->{$cur}) eq 'Encode::Tcl::Table')
	{
	    my $def = $tbl->{$cur}->{'Def'};
	    my $rep = $tbl->{$cur}->{'Rep'};
	    $x = pack(&$rep($x),$x);
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
    $str .= $std  unless $std eq $sta[0]; # GO to ASCII
    $str .= $fin; # necessary?
    $_[1] = $uni if $chk;
    return $str;
}

1;
__END__
