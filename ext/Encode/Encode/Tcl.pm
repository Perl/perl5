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
 my(%tbl, @seq, $enc, @esc, %grp);
 while (<$fh>)
  {
   my ($key,$val) = /^(\S+)\s+(.*)$/;
   $val =~ s/^\{(.*?)\}/$1/g;
   $val =~ s/\\x([0-9a-f]{2})/chr(hex($1))/ge;

   if($enc = Encode->getEncoding($key)){
     $tbl{$val} = ref($enc) eq 'Encode::Tcl' ? $enc->loadEncoding : $enc;
     push @seq, $val;
     $grp{$val} =
	$val =~ m|[(]|  ? 0 : # G0 : SI  eq "\cO"
	$val =~ m|[)-]| ? 1 : # G1 : SO  eq "\cN"
	$val =~ m|[*.]| ? 2 : # G2 : SS2 eq "\eN"
	$val =~ m|[+/]| ? 3 : # G3 : SS3 eq "\eO"
	                  0;  # G0
   }else{
     $obj->{$key} = $val;
   }
   if($val =~ /^\e(.*)/){ push(@esc, quotemeta $1) }
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
 my $tbl = $obj->{'Tbl'};
 my $seq = $obj->{'Seq'};
 my $grp = $obj->{'Grp'};
 my $esc = $obj->{'Esc'};
 my $ini = $obj->{'init'};
 my $fin = $obj->{'final'};
 my $std = $seq->[0];
 my $cur = $std;
 my @sta = ($std, undef, undef, undef); # G0 .. G3 state
 my($g1,$g2,$g3) = (0,0,0);
 my $uni;
 while (length($str)){
   my $uch = substr($str,0,1,'');
   if($uch eq "\e"){
    if($str =~ s/^($esc)//)
     {
      my $esc = "\e$1";
      $sta[ $grp->{$esc} ] = $esc if $tbl->{$esc};
     }
    # appearance of "\eN\eO" or "\eO\eN" isn't supposed.
    # but coincidental ON of G2 and G3 is explicitly avoided.
    elsif($str =~ s/^N//)
     {
      $g2 = 1; $g3 = 0;
     }
    elsif($str =~ s/^O//)
     {
      $g3 = 1; $g2 = 0;
     }
    else
     {
      $str =~ s/^([\x20-\x2F]*[\x30-\x7E])//;
      carp "unknown escape sequence: ESC $1";
     }
    next;
   }
   if($uch eq "\x0e"){
    $g1 = 1; next;
   }
   if($uch eq "\x0f"){
    $g1 = 0; next;
   }

   $cur = $g3 ? $sta[3] : $g2 ? $sta[2] : $g1 ? $sta[1] : $sta[0];

   if(ref($tbl->{$cur}) eq 'Encode::XS'){
     $uni .= $tbl->{$cur}->decode($uch);
     $g2 = $g3 = 0;
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
   $g2 = $g3 = 0;
  }
 $_[1] = $str if $chk;
 return $uni;
}

sub encode
{
 my ($obj,$uni,$chk) = @_;
 my $tbl = $obj->{'Tbl'};
 my $seq = $obj->{'Seq'};
 my $grp = $obj->{'Grp'};
 my $ini = $obj->{'init'};
 my $fin = $obj->{'final'};
 my $std = $seq->[0];
 my $str = $ini;
 my @sta = ($std,undef,undef,undef);
 my @pre = ($std,undef,undef,undef);
 my $cur = $std;
 my $pG = 0;
 my $cG = 0;

 if($ini)
  {
    $sta[ $grp->{$ini} ] = $pre[ $grp->{$ini} ] = $ini;
  }

 while (length($uni)){
  my $ch = substr($uni,0,1,'');
  my $x;
  foreach my $e_seq (@$seq){
   $x = ref($tbl->{$e_seq}) eq 'Encode::XS'
    ? $tbl->{$e_seq}->encode($ch,1)
    : $tbl->{$e_seq}->{FmUni}->{$ch};
   $cur = $e_seq, last if defined $x;
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
  $cG   = $grp->{$cur};
  $str .= $pre[ $cG ] = $cur if $cur ne $pre[ $cG ];

  $str .= $cG == 0 && $pG == 1 ? "\cO" :
          $cG == 1 && $pG == 0 ? "\cN" :
          $cG == 2 ? "\eN" :
          $cG == 3 ? "\eO" :        "";
  $str .= $x;
  $pG = $cG if $cG < 2;
 }
 $str .= $std  unless $cur eq $std;
 $str .= "\cO" if $pG == 1; # back to G0
 $str .= $fin; # necessary?
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
