package Encode::Tcl::Table;
use strict;
our $VERSION = do {my @r=(q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r};
use base 'Encode::Encoding';

use Carp;
#use Data::Dumper;

sub read
{
    my ($obj,$fh,$name,$type) = @_;
    my($rep, @leading);
    my ($def,$sym,$pages) = split(/\s+/,scalar(<$fh>));
    my @touni;
    my %fmuni;
    my $count = 0;
    $def = hex($def);
    while ($pages--)
    {
	my $line = <$fh>;
	chomp($line);
	my $page = hex($line);
	my @page;
	$leading[$page] = 1 if $page;
	my $ch = $page * 256;
	for (my $i = 0; $i < 16; $i++)
	{
	    my $line = <$fh>;
	    for (my $j = 0; $j < 16; $j++)
	    {
		my $val = hex(substr($line,0,4,''));
		if ($val || !$ch)
		{
		    my $uch = pack('U', $val); # chr($val);
		    push(@page,$uch);
		    $fmuni{$uch} = $ch;
		    $count++;
		}
		else
		{
		    push(@page,undef);
		}
		$ch++;
	    }
	}
	$touni[$page] = \@page;
    }
    $rep = $type ne 'M'
	? $obj->can("rep_$type")
	    : sub
	    {
		($_[0] > 255) || $leading[$_[0]] ? 'n' : 'C';
	    };
    $obj->{'Rep'}   = $rep;
    $obj->{'ToUni'} = \@touni;
    $obj->{'FmUni'} = \%fmuni;
    $obj->{'Def'}   = $def;
    $obj->{'Num'}   = $count;
    return $obj;
}

sub rep_S { 'C' }

sub rep_D { 'n' }

#sub rep_M { ($_[0] > 255) ? 'n' : 'C' }

sub representation
{
    my ($obj,$ch) = @_;
    $ch = 0 unless @_ > 1;
    $obj->{'Rep'}->($ch);
}

sub decode
{
    my($obj,$str,$chk) = @_;
    my $name  = $obj->{'Name'};
    my $rep   = $obj->{'Rep'};
    my $touni = $obj->{'ToUni'};
    my $uni;
    while (length($str))
    {
	my $cc = substr($str,0,1,'');
	my $ch = ord($cc);
	my $x;
	if (&$rep($ch) eq 'C')
	{
	    $x = $touni->[0][$ch];
	}
	else
	{
	    if(! length $str)
	    {
		$str = pack('C',$ch); # split leading byte
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
    $_[1] = $str if $chk;
    return $uni;
}


sub encode
{
    my ($obj,$uni,$chk) = @_;
    my $fmuni = $obj->{'FmUni'};
    my $def   = $obj->{'Def'};
    my $name  = $obj->{'Name'};
    my $rep   = $obj->{'Rep'};
    my $str;
    while (length($uni))
    {
	my $ch = substr($uni,0,1,'');
	my $x  = $fmuni->{$ch};
	unless(defined $x)
	{
	    unless($chk)
	    {
	      Encode::Tcl::no_map_in_encode(ord($ch), $name)
	      }
	    return undef;
	}
	$str .= pack(&$rep($x),$x);
    }
    $_[1] = $uni if $chk;
    return $str;
}
1;
__END__
