package Encode::Tcl::Extended;
use strict;
our $VERSION = do {my @r=(q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r};
use base 'Encode::Encoding';

use Carp;

sub read
{
    my ($obj,$fh,$name) = @_;
    my(%tbl, $enc, %ssc, @key);
    while (<$fh>)
    {
	next unless /^(\S+)\s+(.*)$/;
	my ($key,$val) = ($1,$2);
	$val =~ s/\{(.*?)\}/$1/;
	$val =~ s/\\x([0-9a-f]{2})/chr(hex($1))/ge;

	if($enc = Encode->getEncoding($key))
	{
	    push @key, $val;
	    $tbl{$val} = ref($enc) eq 'Encode::Tcl' ? $enc->loadEncoding : $enc;
	    $ssc{$val} = substr($val,1) if $val =~ /^>/;
	}
	else
	{
	    $obj->{$key} = $val;
	}
    }
    $obj->{'SSC'} = \%ssc; # single shift char
    $obj->{'Tbl'} = \%tbl; # encoding tables
    $obj->{'Key'} = \@key; # keys of table hash
    return $obj;
}

sub decode
{
    my ($obj,$str,$chk) = @_;
    my $name = $obj->{'Name'};
    my $tbl  = $obj->{'Tbl'};
    my $ssc  = $obj->{'SSC'};
    my $cur = ''; # current state
    my $uni;
    while (length($str))
    {
	my $cc = substr($str,0,1,'');
	my $ch  = ord($cc);
	if(!$cur && $ch > 0x7F)
	{
	    $cur = '>';
	    $cur .= $cc, next if $ssc->{$cur.$cc};
	}
	$ch ^= 0x80 if $cur;

	if(ref($tbl->{$cur}) ne 'Encode::Tcl::Table')
	{
	    $uni .= $tbl->{$cur}->decode($cc);
	    $cur = '';
	    next;
	}
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
	    $x = $touni->[$ch][0x80 ^ ord($c2)];
	}
	unless (defined $x)
	{
	  Encode::Tcl::no_map_in_decode($name, $cc.$str);
	}
	$uni .= $x;
	$cur = '';
    }
    if($chk)
    {
	$cur =~ s/>//;
	$_[1] = $cur ne '' ? $cur.$str : $str;
    }
    return $uni;
}

sub encode
{
    my ($obj,$uni,$chk) = @_;
    my $name = $obj->{'Name'};
    my $tbl = $obj->{'Tbl'};
    my $ssc = $obj->{'SSC'};
    my $key = $obj->{'Key'};
    my $str;
    my $cur;

    while (length($uni))
    {
	my $ch = substr($uni,0,1,'');
	my $x;
	foreach my $k (@$key)
	{
	    $x = ref($tbl->{$k}) ne 'Encode::Tcl::Table'
		? $k =~ /^>/
		    ? $tbl->{$k}->encode(chr(0x80 ^ ord $ch),1)
			: $tbl->{$k}->encode($ch,1)
			    : $tbl->{$k}->{FmUni}->{$ch};
	    $cur = $k, last if defined $x;
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
	    my $r = &$rep($x);
	    $x = pack($r,
		      $cur =~ /^>/
		      ? $r eq 'C' ? 0x80 ^ $x : 0x8080 ^ $x
		      : $x);
	}
	$str .= $ssc->{$cur} if defined $ssc->{$cur};
	$str .= $x;
    }
    $_[1] = $uni if $chk;
    return $str;
}
1;
__END__
