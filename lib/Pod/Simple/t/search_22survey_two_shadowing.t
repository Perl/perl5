BEGIN {
    if($ENV{PERL_CORE}) {
        chdir 't';
        @INC = '../lib';
    }
}

use strict;
use Pod::Simple::Search;
use Test;
BEGIN { plan tests => 13 }

print "# ", __FILE__,
 ": Testing the scanning of several docroots...\n";

my $x = Pod::Simple::Search->new;
die "Couldn't make an object!?" unless ok defined $x;

$x->inc(0);
$x->shadows(1);

use File::Spec;
use Cwd;
my $cwd = cwd();
print "# CWD: $cwd\n";

sub source_path {
    my $file = shift;
    if ($ENV{PERL_CORE}) {
        my $updir = File::Spec->updir;
        my $dir = File::Spec->catdir($updir, 'lib', 'Pod', 'Simple', 't');
        return File::Spec->catdir ($dir, $file);
    } else {
        return $file;
    }
}

my($here1, $here2, $here3);

if(        -e ($here1 = source_path('test_lib'      ))) {
  die "But where's $here2?"
    unless -e ($here2 = source_path('other_test_lib'));
  die "But where's $here3?"
    unless -e ($here3 = source_path('yet_another_test_lib'));

} elsif(   -e ($here1 = File::Spec->catdir($cwd, 't', 'test_lib'      ))) {
  die "But where's $here2?"
    unless -e ($here2 = File::Spec->catdir($cwd, 't', 'other_test_lib'));
  die "But where's $here3?"
    unless -e ($here3 = File::Spec->catdir($cwd, 't', 'yet_another_test_lib'));

} else {
  die "Can't find the test corpora";
}
print "# OK, found the test corpora\n#  as $here1\n# and $here2\n# and $here3\n#\n";
ok 1;

print $x->_state_as_string;
#$x->verbose(12);

use Pod::Simple;
*pretty = \&Pod::Simple::BlackBox::pretty;

my($name2where, $where2name) = $x->survey($here1, $here2, $here3);

my $p = pretty( $where2name, $name2where )."\n";
$p =~ s/, +/,\n/g;
$p =~ s/^/#  /mg;
print $p;

{
print "# won't show any shadows, since we're just looking at the name2where keys\n";
my $names = join "|", sort keys %$name2where;
ok $names, "Blorm|Sizzlesuzzle|Zonk::Pronk|hink_honk::Glunk|hink_honk::Vliff|perlfliff|perlthang|perlzuk|squaa|squaa::Glunk|squaa::Vliff|squaa::Wowo|zikzik";
}

{
print "# but here we'll see shadowing:\n";
my $names = join "|", sort values %$where2name;
ok $names, "Blorm|Sizzlesuzzle|Zonk::Pronk|hink_honk::Glunk|hink_honk::Glunk|hink_honk::Vliff|hink_honk::Vliff|perlfliff|perlthang|perlthang|perlzuk|squaa|squaa::Glunk|squaa::Vliff|squaa::Vliff|squaa::Vliff|squaa::Wowo|zikzik";

my %count;
for(values %$where2name) { ++$count{$_} };
#print pretty(\%count), "\n\n";
delete @count{ grep $count{$_} < 2, keys %count };
my $shadowed = join "|", sort keys %count;
ok $shadowed, "hink_honk::Glunk|hink_honk::Vliff|perlthang|squaa::Vliff";

sub thar { print "# Seen $_[0] :\n", map "#  {$_}\n", sort grep $where2name->{$_} eq $_[0],keys %$where2name; return; }

ok $count{'perlthang'}, 2;
thar 'perlthang';
ok $count{'squaa::Vliff'}, 3;
thar 'squaa::Vliff';
}


ok( ($name2where->{'squaa'} || 'huh???'), '/squaa\.pm$/');

ok grep( m/squaa\.pm/, keys %$where2name ), 1;

ok( ($name2where->{'perlthang'}    || 'huh???'), '/[^\^]test_lib/' );
ok( ($name2where->{'squaa::Vliff'} || 'huh???'), '/[^\^]test_lib/' );

# Some sanity:
ok( ($name2where->{'squaa::Wowo'}  || 'huh???'), '/other_test_lib/' );




print "# OK, bye from ", __FILE__, "\n";
ok 1;

__END__

