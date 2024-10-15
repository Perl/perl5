#!/usr/bin/perl

use strict;
use Data::Dumper;
    my $n;
    my $i;
die "usage :" unless @ARGV and $ARGV[0];
my $fn = $ARGV[0];
$fn = 'sv_inline.h';
my $f;
open($f, '<:raw', $fn) || die;
local $/;  # enable slurp mode, locally.
my $file = <$f>;
my $mfile = $file;
close($f);

my $s = index($file, "static const struct body_details bodies_by_type[] = {");
my $e = index($file, "\n};", $s);
$file = substr($file, $s, ($e+4)-$s);

my @a;
my @out;
@a = $file =~ /    {( .+? )},/gs;
#print Dumper(\@a);
foreach my $l (@a) {
  my @c;
  my $field = '';
  my $nest = 0;
  my $i = 0;
  $l =~ s/\/\*[^*]+\*\///gs;
  for($i = 0; $i < length $l; $i++) {
    my $ch = substr($l, $i, 1);
    if($ch eq '(') {
      $nest++;
    }
    elsif($ch eq ')') {
      $nest--;
    }
    elsif($nest == 0 && $ch eq ',') {
      $field =~ s/^\s+|\s+$//g;
      push(@c, $field);
      $field = '';
      next;
    }
    $field .= $ch;
  }
  $field =~ s/^\s+|\s+$//g;
  push(@c, $field);
  push @out, \@c;
}

my $nv = splice(@out, 2, 1);
for($i=0; $i < @$nv; $i++) {
$out[2][$i] = "("."NVSIZE <= IVSIZE"."?(".@$nv[$i]."):(".$out[2][$i]."))";
}


  print Dumper(\@out);
my @names = qw (
    body_size
    copy  
    offset  
    type 
    cant_upgrade
    zero_nv  
    arena
    arena_size
    );

my @types = qw(
        SVt_NULL	
        SVt_IV		
        SVt_NV		
        SVt_PV		
        SVt_INVLIST	
        SVt_PVIV	
        SVt_PVNV	
        SVt_PVMG	
        SVt_REGEXP	
        SVt_PVGV	
        SVt_PVLV	
        SVt_PVAV	
        SVt_PVHV	
        SVt_PVCV	
        SVt_PVFM	
        SVt_PVIO	
        SVt_PVOBJ
)
;

for($i=0; $i < @names; $i++) {
  print "#define SVDB_".$names[$i]."(_a) (";
  for($n=0; $n < @out; $n++) {
    if($n ==(@out-1)) {
      print "(".$out[$n][$i].")";
    }
    else {
    print "(_a)==".$types[$n]."?(".$out[$n][$i]."):";
    }
  }
  print ")\n\n";
}

$s = index($mfile, "PERL_STATIC_INLINE SV *
Perl_newSV_type(pTHX_ const svtype type)");
$e = index($mfile, "
    return sv;
}
", $s);
my $fn = substr($mfile, $s, $e+18-$s);

for($n=0; $n < @out; $n++) {
  my $tfn = $fn;
  my $t  = $types[$n];
  $tfn =~ s/\Qtype(pTHX_ const svtype type)\E/type$t(pTHX)/;
  $t = "(".$types[$n].")";
  $tfn =~ s/type_details->(\w+)/SVDB_\1$t/gs;
  $t = $types[$n];
  $tfn =~ s/\Q    type_details = bodies_by_type + type;\E/#define type $t/;
   $tfn =~ s/    return sv;/\#undef type\n    return sv;/;
   $t = "safecalloc(SVDB_body_size(".$types[$n].") + SVDB_offset(".$types[$n]."), 1)";
   $tfn =~ s/new_NOARENAZ\(type_details\)/$t/gs;
   $tfn =~ s/\n    const struct body_details \*type_details;//;
  print $tfn."\n\n";
  if($types[$n] eq "SVt_PV") {
    $tfn =~ s/SVt_PV/$tfn/gs
  }
}

$s = index($mfile, 'Perl_newSV_type_mortal(pTHX_ const svtype type)');
my $mtxt = '    return sv;
}
';
$e = index($mfile, $mtxt
, $s);
 $fn = substr($mfile, $s, $e+length($mtxt)-$s);

for($n=0; $n < @out; $n++) {
  my $tfn = $fn;
  my $t  = $types[$n];
  $tfn =~ s/\Qmortal(pTHX_ const svtype type)\E/mortal$t(pTHX)/;
  $tfn =~ s/\QPerl_newSV_type(pTHX_ type);\E/Perl_newSV_type$t(aTHX);/;
  print $tfn."\n\n";
  if($types[$n] eq "SVt_PV") {
    $tfn =~ s/SVt_PV/$tfn/gs
  }
}

