package Encode::Tcl::HanZi;
our $VERSION = do {my @r=(q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r};
use base 'Encode::Encoding';

use Carp;

sub read
{
    my ($obj,$fh,$name) = @_;
    my(%tbl, @seq, $enc);
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
	}
	else 
	{
	    $obj->{$key} = $val;
	}
    }
    $obj->{'Seq'} = \@seq; # escape sequences
    $obj->{'Tbl'} = \%tbl; # encoding tables
    return $obj;
}

sub decode
{
    my ($obj,$str,$chk) = @_;
    my $name = $obj->{'Name'};
    my $tbl = $obj->{'Tbl'};
    my $seq = $obj->{'Seq'};
    my $std = $seq->[0];
    my $cur = $std;
    my $uni;
    while (length($str)){
	my $cc = substr($str,0,1,'');
	if($cc eq "~")
	{
	    if($str =~ s/^\cJ//)
	    {
		next;
	    }
	    elsif($str =~ s/^\~//)
	    {
		1; # no-op
	    }
	    elsif($str =~ s/^([{}])//)
	    {
		$cur = "~$1";
		next;
	    }
	    elsif(! length $str)
	    {
		$str = '~';
		last;
	    }
	    else
	    {
		$str =~ s/^([^~])//;
		croak "unknown HanZi escape sequence: ~$1";
		next;
	    }
	}
	if(ref($tbl->{$cur}) ne 'Encode::Tcl::Table')
	{
	    $uni .= $tbl->{$cur}->decode($cc);
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
    }
    if($chk)
    {
	$_[1] = $cur eq $std ? $str : $cur.$str;
    }
    return $uni;
}

sub encode
{
    my ($obj,$uni,$chk) = @_;
    my $name = $obj->{'Name'};
    my $tbl = $obj->{'Tbl'};
    my $seq = $obj->{'Seq'};
    my $std = $seq->[0];
    my $str;
    my $pre = $std;
    my $cur = $pre;

    while (length($uni))
    {
	my $ch = substr($uni,0,1,'');
	my $x;
	foreach my $e_seq (@$seq)
	{
	    $x = ref($tbl->{$e_seq}) eq 'Encode::Tcl::Table'
		? $tbl->{$e_seq}->{FmUni}->{$ch}
	    : $tbl->{$e_seq}->encode($ch,1);
	    $cur = $e_seq and last if defined $x;
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
	$str .= $cur eq $pre ? $x : ($pre = $cur).$x;
	$str .= '~' if $x eq '~'; # to '~~'
    }
    $str .= $std unless $cur eq $std;
    $_[1] = $uni if $chk;
    return $str;
}
1;
__END__
