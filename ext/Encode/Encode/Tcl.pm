package Encode::Tcl;

our $VERSION = '1.00';

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

sub no_map_in_encode ($$)
 # codepoint, enc-name;
{
 carp sprintf "\"\\N{U+%x}\" does not map to %s", @_;
# /* FIXME: Skip over the character, copy in replacement and continue
#  * but that is messy so for now just fail.
#  */
 return;
}

sub no_map_in_decode ($$)
 # enc-name, string beginning the malform char;
{
# /* UTF-8 is supposed to be "Universal" so should not happen */
  croak sprintf "%s '%s' does not map to UTF-8", @_;
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
   my $subclass =
     ($type eq 'X') ? 'Extended' :
     ($type eq 'H') ? 'HanZi'    :
     ($type eq 'E') ? 'Escape'   : 'Table';
   my $class = ref($obj) . '::' . $subclass;
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

package Encode::Tcl::Escape;
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


package Encode::Tcl::Extended;
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

package Encode::Tcl::HanZi;
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
