package Encode::Tcl;
use strict;
use Encode qw(find_encoding);
use base 'Encode::Encoding';
use Carp;

=head1 NAME

Encode::Tcl - Tcl encodings

=cut

sub INC_search
{
 foreach my $dir (@INC)
  {
   if (opendir(my $dh,"$dir/Encode"))
    {
     while (defined(my $name = readdir($dh)))
      {
       if ($name =~ /^(.*)\.enc$/)
        {
         my $canon = $1;
         my $obj = find_encoding($canon);
         if (!defined($obj))
          {
           my $obj = bless { Name => $canon, File => "$dir/Encode/$name"},__PACKAGE__;
           $obj->Define( $canon );
           # warn "$canon => $obj\n";
          }
        }
      }
     closedir($dh);
    }
  }
}

sub import
{
 INC_search();
}

sub encode
{
 my $obj = shift;
 my $new = $obj->loadEncoding;
 return undef unless (defined $new);
 return $new->encode(@_);
}

sub new_sequence
{
 my $obj = shift;
 my $new = $obj->loadEncoding;
 return undef unless (defined $new);
 return $new->new_sequence(@_);
}

sub decode
{
 my $obj = shift;
 my $new = $obj->loadEncoding;
 return undef unless (defined $new);
 return $new->decode(@_);
}

sub loadEncoding
{
 my $obj = shift;
 my $file = $obj->{'File'};
 my $name = $obj->name;
 if (open(my $fh,$file))
  {
   my $type;
   while (1)
    {
     my $line = <$fh>;
     $type = substr($line,0,1);
     last unless $type eq '#';
    }
   my $class = ref($obj).('::'.(($type eq 'E') ? 'Escape' : 'Table'));
   # carp "Loading $file";
   bless $obj,$class;
   return $obj if $obj->read($fh,$obj->name,$type);
  }
 else
  {
   croak("Cannot open $file for ".$obj->name);
  }
 $obj->Undefine($name);
 return undef;
}

sub INC_find
{
 my ($class,$name) = @_;
 my $enc;
 foreach my $dir (@INC)
  {
   last if ($enc = $class->loadEncoding($name,"$dir/Encode/$name.enc"));
  }
 return $enc;
}

package Encode::Tcl::Table;
use base 'Encode::Encoding';

use Data::Dumper;

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
 $rep = $type ne 'M' ? $obj->can("rep_$type") :
   sub { ($_[0] > 255) || $leading[$_[0]] ? 'n' : 'C'};
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
 my ($obj,$str,$chk) = @_;
 my $rep   = $obj->{'Rep'};
 my $touni = $obj->{'ToUni'};
 my $uni   = '';
 while (length($str))
  {
   my $ch = ord(substr($str,0,1,''));
   my $x;
   if (&$rep($ch) eq 'C')
    {
     $x = $touni->[0][$ch];
    }
   else
    {
     $x = $touni->[$ch][ord(substr($str,0,1,''))];
    }
   unless (defined $x)
    {
     last if $chk;
     # What do we do here ?
     $x = '';
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
 my $str   = '';
 my $def   = $obj->{'Def'};
 my $rep   = $obj->{'Rep'};
 while (length($uni))
  {
   my $ch = substr($uni,0,1,'');
   my $x  = $fmuni->{chr(ord($ch))};
   unless (defined $x)
    {
     last if ($chk);
     $x = $def;
    }
   $str .= pack(&$rep($x),$x);
  }
 $_[1] = $uni if $chk;
 return $str;
}

package Encode::Tcl::Escape;
use base 'Encode::Encoding';

use Carp;

sub read
{
 my ($class,$fh,$name) = @_;
 my %self = (Name => $name, Num => 0);
 while (<$fh>)
  {
   my ($key,$val) = /^(\S+)\s+(.*)$/;
   $val =~ s/^\{(.*?)\}/$1/g;
   $val =~ s/\\x([0-9a-f]{2})/chr(hex($1))/ge;
   $self{$key} = $val;
  }
 return bless \%self,$class;
}

sub decode
{
 croak("Not implemented yet");
}

sub encode
{
 croak("Not implemented yet");
}

1;
__END__
