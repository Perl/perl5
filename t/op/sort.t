#!./perl

BEGIN {
    chdir 't' if -d 't';
    unshift @INC, '../lib';
}
print "1..37\n";

# XXX known to leak scalars
$ENV{PERL_DESTRUCT_LEVEL} = 0 unless $ENV{PERL_DESTRUCT_LEVEL} > 3;

sub backwards { $a lt $b ? 1 : $a gt $b ? -1 : 0 }

my $upperfirst = 'A' lt 'a';

# Beware: in future this may become hairier because of possible
# collation complications: qw(A a B c) can be sorted at least as
# any of the following
#
#	A a B b
#	A B a b
#	a b A B
#	a A b B
#
# All the above orders make sense.
#
# That said, EBCDIC sorts all small letters first, as opposed
# to ASCII which sorts all big letters first.

@harry = ('dog','cat','x','Cain','Abel');
@george = ('gone','chased','yz','punished','Axed');

$x = join('', sort @harry);
$expected = $upperfirst ? 'AbelCaincatdogx' : 'catdogxAbelCain';
print "# 1: x = '$x', expected = '$expected'\n";
print ($x eq $expected ? "ok 1\n" : "not ok 1\n");

$x = join('', sort( backwards @harry));
$expected = $upperfirst ? 'xdogcatCainAbel' : 'CainAbelxdogcat';
print "# 2: x = '$x', expected = '$expected'\n";
print ($x eq $expected ? "ok 2\n" : "not ok 2\n");

$x = join('', sort @george, 'to', @harry);
$expected = $upperfirst ?
    'AbelAxedCaincatchaseddoggonepunishedtoxyz' :
    'catchaseddoggonepunishedtoxyzAbelAxedCain' ;
print "# 3: x = '$x', expected = '$expected'\n";
print ($x eq $expected ?"ok 3\n":"not ok 3\n");

@a = ();
@b = reverse @a;
print ("@b" eq "" ? "ok 4\n" : "not ok 4 (@b)\n");

@a = (1);
@b = reverse @a;
print ("@b" eq "1" ? "ok 5\n" : "not ok 5 (@b)\n");

@a = (1,2);
@b = reverse @a;
print ("@b" eq "2 1" ? "ok 6\n" : "not ok 6 (@b)\n");

@a = (1,2,3);
@b = reverse @a;
print ("@b" eq "3 2 1" ? "ok 7\n" : "not ok 7 (@b)\n");

@a = (1,2,3,4);
@b = reverse @a;
print ("@b" eq "4 3 2 1" ? "ok 8\n" : "not ok 8 (@b)\n");

@a = (10,2,3,4);
@b = sort {$a <=> $b;} @a;
print ("@b" eq "2 3 4 10" ? "ok 9\n" : "not ok 9 (@b)\n");

$sub = 'backwards';
$x = join('', sort $sub @harry);
$expected = $upperfirst ? 'xdogcatCainAbel' : 'CainAbelxdogcat';
print "# 10: x = $x, expected = '$expected'\n";
print ($x eq $expected ? "ok 10\n" : "not ok 10\n");

# literals, combinations

@b = sort (4,1,3,2);
print ("@b" eq '1 2 3 4' ? "ok 11\n" : "not ok 11\n");
print "# x = '@b'\n";

@b = sort grep { $_ } (4,1,3,2);
print ("@b" eq '1 2 3 4' ? "ok 12\n" : "not ok 12\n");
print "# x = '@b'\n";

@b = sort map { $_ } (4,1,3,2);
print ("@b" eq '1 2 3 4' ? "ok 13\n" : "not ok 13\n");
print "# x = '@b'\n";

@b = sort reverse (4,1,3,2);
print ("@b" eq '1 2 3 4' ? "ok 14\n" : "not ok 14\n");
print "# x = '@b'\n";

$^W = 0;
# redefining sort sub inside the sort sub should fail
sub twoface { *twoface = sub { $a <=> $b }; &twoface }
eval { @b = sort twoface 4,1,3,2 };
print ($@ =~ /redefine active sort/ ? "ok 15\n" : "not ok 15\n");

# redefining sort subs outside the sort should not fail
eval { *twoface = sub { &backwards } };
print $@ ? "not ok 16\n" : "ok 16\n";

eval { @b = sort twoface 4,1,3,2 };
print ("@b" eq '4 3 2 1' ? "ok 17\n" : "not ok 17 |@b|\n");

*twoface = sub { *twoface = *backwards; $a <=> $b };
eval { @b = sort twoface 4,1 };
print ($@ =~ /redefine active sort/ ? "ok 18\n" : "not ok 18\n");

*twoface = sub {
                 eval 'sub twoface { $a <=> $b }';
		 die($@ =~ /redefine active sort/ ? "ok 19\n" : "not ok 19\n");
		 $a <=> $b;
	       };
eval { @b = sort twoface 4,1 };
print $@ ? "$@" : "not ok 19\n";

eval <<'CODE';
    my @result = sort main'backwards 'one', 'two';
CODE
print $@ ? "not ok 20\n# $@" : "ok 20\n";

eval <<'CODE';
    # "sort 'one', 'two'" should not try to parse "'one" as a sort sub
    my @result = sort 'one', 'two';
CODE
print $@ ? "not ok 21\n# $@" : "ok 21\n";

{
  my $sortsub = \&backwards;
  my $sortglob = *backwards;
  my $sortglobr = \*backwards;
  my $sortname = 'backwards';
  @b = sort $sortsub 4,1,3,2;
  print ("@b" eq '4 3 2 1' ? "ok 22\n" : "not ok 22 |@b|\n");
  @b = sort $sortglob 4,1,3,2;
  print ("@b" eq '4 3 2 1' ? "ok 23\n" : "not ok 23 |@b|\n");
  @b = sort $sortname 4,1,3,2;
  print ("@b" eq '4 3 2 1' ? "ok 24\n" : "not ok 24 |@b|\n");
  @b = sort $sortglobr 4,1,3,2;
  print ("@b" eq '4 3 2 1' ? "ok 25\n" : "not ok 25 |@b|\n");
}

{
  local $sortsub = \&backwards;
  local $sortglob = *backwards;
  local $sortglobr = \*backwards;
  local $sortname = 'backwards';
  @b = sort $sortsub 4,1,3,2;
  print ("@b" eq '4 3 2 1' ? "ok 26\n" : "not ok 26 |@b|\n");
  @b = sort $sortglob 4,1,3,2;
  print ("@b" eq '4 3 2 1' ? "ok 27\n" : "not ok 27 |@b|\n");
  @b = sort $sortname 4,1,3,2;
  print ("@b" eq '4 3 2 1' ? "ok 28\n" : "not ok 28 |@b|\n");
  @b = sort $sortglobr 4,1,3,2;
  print ("@b" eq '4 3 2 1' ? "ok 29\n" : "not ok 29 |@b|\n");
}

## exercise sort builtins... ($a <=> $b already tested)
@a = ( 5, 19, 1996, 255, 90 );
@b = sort { $b <=> $a } @a;
print ("@b" eq '1996 255 90 19 5' ? "ok 30\n" : "not ok 30\n");
print "# x = '@b'\n";
$x = join('', sort { $a cmp $b } @harry);
$expected = $upperfirst ? 'AbelCaincatdogx' : 'catdogxAbelCain';
print ($x eq $expected ? "ok 31\n" : "not ok 31\n");
print "# x = '$x'; expected = '$expected'\n";
$x = join('', sort { $b cmp $a } @harry);
$expected = $upperfirst ? 'xdogcatCainAbel' : 'CainAbelxdogcat';
print ($x eq $expected ? "ok 32\n" : "not ok 32\n");
print "# x = '$x'; expected = '$expected'\n";
{
    use integer;
    @b = sort { $a <=> $b } @a;
    print ("@b" eq '5 19 90 255 1996' ? "ok 33\n" : "not ok 33\n");
    print "# x = '@b'\n";
    @b = sort { $b <=> $a } @a;
    print ("@b" eq '1996 255 90 19 5' ? "ok 34\n" : "not ok 34\n");
    print "# x = '@b'\n";
    $x = join('', sort { $a cmp $b } @harry);
    $expected = $upperfirst ? 'AbelCaincatdogx' : 'catdogxAbelCain';
    print ($x eq $expected ? "ok 35\n" : "not ok 35\n");
    print "# x = '$x'; expected = '$expected'\n";
    $x = join('', sort { $b cmp $a } @harry);
    $expected = $upperfirst ? 'xdogcatCainAbel' : 'CainAbelxdogcat';
    print ($x eq $expected ? "ok 36\n" : "not ok 36\n");
    print "# x = '$x'; expected = '$expected'\n";
}
# test sorting in non-main package
package Foo;
@a = ( 5, 19, 1996, 255, 90 );
@b = sort { $b <=> $a } @a;
print ("@b" eq '1996 255 90 19 5' ? "ok 37\n" : "not ok 37\n");
print "# x = '@b'\n";
