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
   my $class = ref($obj).('::'.(($type eq 'H') ? 'HanZi' : ($type eq 'E') ? 'Escape' : 'Table'));
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
 my $uni;
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
 my $def   = $obj->{'Def'};
 my $rep   = $obj->{'Rep'};
 my $str;
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
 my ($obj,$fh,$name) = @_;
 my(%tbl, @seq, $enc, @esc);
 while (<$fh>)
  {
   my ($key,$val) = /^(\S+)\s+(.*)$/;
   $val =~ s/^\{(.*?)\}/$1/g;
   $val =~ s/\\x([0-9a-f]{2})/chr(hex($1))/ge;
   if($enc = Encode->getEncoding($key)){
     $tbl{$val} = ref($enc) eq 'Encode::Tcl' ? $enc->loadEncoding : $enc;
     push @seq, $val;
   }else{
     $obj->{$key} = $val;
   }
   if($val =~ /^\e(.*)/){ push(@esc, quotemeta $1) }
  }
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
 my $esc = $obj->{'Esc'};
 my $ini = $obj->{'init'};
 my $fin = $obj->{'final'};
 my $std = $seq->[0];
 my $cur = $std;
 my $uni;
 while (length($str)){
   my $uch = substr($str,0,1,'');
   if($uch eq "\e"){
    if($str =~ s/^($esc)//)
     {
      my $esc = "\e$1";
      $cur = $tbl->{$esc} ? $esc :
             ($esc eq $ini || $esc eq $fin) ? $std :
             $cur;
     }
    else
     {
      $str =~ s/^([\x20-\x2F]*[\x30-\x7E])//;
      carp "unknown escape sequence: ESC $1";
     }
    next;
   }
   if($uch eq "\x0e" || $uch eq "\x0f"){
    $cur = $uch and next;
   }
   if(ref($tbl->{$cur}) eq 'Encode::XS'){
     $uni .= $tbl->{$cur}->decode($uch);
     next;
   }
   my $ch    = ord($uch);
   my $rep   = $tbl->{$cur}->{'Rep'};
   my $touni = $tbl->{$cur}->{'ToUni'};
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
 my $tbl = $obj->{'Tbl'};
 my $seq = $obj->{'Seq'};
 my $ini = $obj->{'init'};
 my $fin = $obj->{'final'};
 my $std = $seq->[0];
 my $str = $ini;
 my $pre = $std;
 my $cur = $pre;

 while (length($uni)){
  my $ch = chr(ord(substr($uni,0,1,'')));
  my $x;
  foreach my $e_seq ($std, $pre, @$seq){
   $x = ref($tbl->{$e_seq}) eq 'Encode::XS'
    ? $tbl->{$e_seq}->encode($ch,1)
    : $tbl->{$e_seq}->{FmUni}->{$ch};
   $cur = $e_seq and last if defined $x;
  }
  if(ref($tbl->{$cur}) ne 'Encode::XS')
   {
    my $def = $tbl->{$cur}->{'Def'};
    my $rep = $tbl->{$cur}->{'Rep'};
    unless (defined $x){
     last if ($chk);
     $x = $def;
    }
    $x = pack(&$rep($x),$x);
   }
  $str .= $cur eq $pre ? $x : ($pre = $cur).$x;
 }
 $str .= $std unless $cur eq $std;
 $str .= $fin;
 $_[1] = $uni if $chk;
 return $str;
}

package Encode::Tcl::HanZi;
use base 'Encode::Encoding';

use Carp;

sub read
{
 my ($obj,$fh,$name) = @_;
 my(%tbl, @seq, $enc);
 while (<$fh>)
  {
   my ($key,$val) = /^(\S+)\s+(.*)$/;
   $val =~ s/^\{(.*?)\}/$1/g;
   $val =~ s/\\x([0-9a-f]{2})/chr(hex($1))/ge;
   if($enc = Encode->getEncoding($key)){
     $tbl{$val} = ref($enc) eq 'Encode::Tcl' ? $enc->loadEncoding : $enc;
     push @seq, $val;
   }else{
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
 my $tbl = $obj->{'Tbl'};
 my $seq = $obj->{'Seq'};
 my $std = $seq->[0];
 my $cur = $std;
 my $uni;
 while (length($str)){
   my $uch = substr($str,0,1,'');
   if($uch eq "~"){
    if($str =~ s/^\cJ//)
     {
      next;
     }
    elsif($str =~ s/^\~//)
     {
      1;
     }
    elsif($str =~ s/^([{}])//)
     {
      $cur = "~$1";
      next;
     }
    else
     {
      $str =~ s/^([^~])//;
      carp "unknown HanZi escape sequence: ~$1";
      next;
     }
   }
   if(ref($tbl->{$cur}) eq 'Encode::XS'){
     $uni .= $tbl->{$cur}->decode($uch);
     next;
   }
   my $ch    = ord($uch);
   my $rep   = $tbl->{$cur}->{'Rep'};
   my $touni = $tbl->{$cur}->{'ToUni'};
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
 my $tbl = $obj->{'Tbl'};
 my $seq = $obj->{'Seq'};
 my $std = $seq->[0];
 my $str;
 my $pre = $std;
 my $cur = $pre;

 while (length($uni)){
  my $ch = chr(ord(substr($uni,0,1,'')));
  my $x;
  foreach my $e_seq (@$seq){
   $x = ref($tbl->{$e_seq}) eq 'Encode::XS'
    ? $tbl->{$e_seq}->encode($ch,1)
    : $tbl->{$e_seq}->{FmUni}->{$ch};
   $cur = $e_seq and last if defined $x;
  }
  if(ref($tbl->{$cur}) ne 'Encode::XS')
   {
    my $def = $tbl->{$cur}->{'Def'};
    my $rep = $tbl->{$cur}->{'Rep'};
    unless (defined $x){
     last if ($chk);
     $x = $def;
    }
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
