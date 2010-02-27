#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

plan tests => 6;

my $rx = qr//;

is(ref $rx, "Regexp", "qr// blessed into `Regexp' by default");


# Make sure /$qr/ doesn’t clobber match vars before the match (bug 70764).
{
 my $output = '';
 my $rx = qr/o/;
 my $a = "ooaoaoao";

 my $foo = 0;
 $foo += () = ($a =~ /$rx/g);
 $output .= "$foo\n"; # correct

 $foo = 0;
 for ($foo += ($a =~ /o/); $' && ($' =~ /o/) && ($foo++) ; ) { ; }
 $output .= "1: $foo\n"; # No error

 $foo = 0;
 for ($foo += ($a =~ /$rx/); $' && ($' =~ /$rx/) && ($foo++) ; ) { ; }
 $output .= "2: $foo\n"; # initialization warning, incorrect results

 is $output, "5\n1: 5\n2: 5\n", '$a_match_var =~ /$qr/';
}
for my $_($'){
 my $output = '';
 my $rx = qr/o/;
 my $a = "ooaoaoao";

 my $foo = 0;
 $foo += () = ($a =~ /$rx/g);
 $output .= "$foo\n"; # correct

 $foo = 0;
 for ($foo += ($a =~ /o/); $' && /o/ && ($foo++) ; ) { ; }
 $output .= "1: $foo\n"; # No error

 $foo = 0;
 for ($foo += ($a =~ /$rx/); $' && /$rx/ && ($foo++) ; ) { ; }
 $output .= "2: $foo\n"; # initialization warning, incorrect results

 is $output, "5\n1: 5\n2: 5\n", '/$qr/ with my $_ aliased to a match var';
}
for($'){
 my $output = '';
 my $rx = qr/o/;
 my $a = "ooaoaoao";

 my $foo = 0;
 $foo += () = ($a =~ /$rx/g);
 $output .= "$foo\n"; # correct

 $foo = 0;
 for ($foo += ($a =~ /o/); $' && /o/ && ($foo++) ; ) { ; }
 $output .= "1: $foo\n"; # No error

 $foo = 0;
 for ($foo += ($a =~ /$rx/); $' && /$rx/ && ($foo++) ; ) { ; }
 $output .= "2: $foo\n"; # initialization warning, incorrect results

 is $output, "5\n1: 5\n2: 5\n", q|/$qr/ with $'_ aliased to a match var|;
}

# Make sure /$qr/ calls get-magic on its LHS (bug ~~~~~).
{
 my $scratch;
 sub qrBug::TIESCALAR{bless[], 'qrBug'}
 sub qrBug::FETCH { $scratch .= "[fetching]"; 'glat' }
 tie my $flile, "qrBug";
 $flile =~ qr/(?:)/;
 is $scratch, "[fetching]", '/$qr/ with magical LHS';
}

{
    # [perl 72922]: A 'copy' of a Regex object which has magic should not crash
    # When a Regex object was copied and the copy weaken then the original regex object
    # could no longer be 'copied' with qr//

    my $prog = tempfile();
    open my $fh, ">", $prog or die "Can't write to tempfile";
    print $fh <<'EOTEST';
require "./test.pl";
$verbose = 1;
use Scalar::Util 'weaken';
sub s1 {
    my $re = qr/abcdef/;
    my $re_copy1 = $re;
    my $re_weak_copy = $re;;
    weaken($re_weak_copy);
    my $re_copy2 = qr/$re/;

    my $str_re = "$re";
    is("$$re_weak_copy", $str_re, "weak copy equals original");
    is("$re_copy1", $str_re, "copy1 equals original");
    is("$re_copy2", $str_re, "copy2 equals original");

    my $refcnt_start = Internals::SvREFCNT($$re_weak_copy);

    undef $re;
    is(Internals::SvREFCNT($$re_weak_copy), $refcnt_start - 1, "refcnt decreased");
    is("$re_weak_copy", $str_re, "weak copy still equals original");

    undef $re_copy2;
    is(Internals::SvREFCNT($$re_weak_copy), $refcnt_start - 1, "refcnt not decreased");
    is("$re_weak_copy", $str_re, "weak copy still equals original");
}
s1();
s1();
EOTEST
    close $fh;

    my $out = runperl(stderr => 1, progfile => $prog);
    unlink $prog;

    my $expected = <<'EOOUT';
ok 1 - weak copy equals original
ok 2 - copy1 equals original
ok 3 - copy2 equals original
ok 4 - refcnt decreased
ok 5 - weak copy still equals original
ok 6 - refcnt not decreased
ok 7 - weak copy still equals original
ok 8 - weak copy equals original
ok 9 - copy1 equals original
ok 10 - copy2 equals original
ok 11 - refcnt decreased
ok 12 - weak copy still equals original
ok 13 - refcnt not decreased
ok 14 - weak copy still equals original
EOOUT

    is ($out, $expected, '[perl #72922] copy of a regex of which a weak copy exist');
}
