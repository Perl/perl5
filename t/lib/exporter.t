#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

# Utility testing functions.
my $test_num = 1;
sub ok ($;$) {
    my($test, $name) = @_;
    print "not " unless $test;
    print "ok $test_num";
    print " - $name" if defined $name;
    print "\n";
    $test_num++;
}


my $loaded;
BEGIN { $| = 1; $^W = 1; }
END {print "not ok $test_num\n" unless $loaded;}
print "1..$Total_tests\n";
use Exporter;
$loaded = 1;
ok(1, 'compile');


BEGIN {
    # Methods which Exporter says it implements.
    @Exporter_Methods = qw(import
                           export_to_level
                           require_version
                           export_fail
                          );
}

BEGIN { $Total_tests = 14 + @Exporter_Methods }

package Testing;
require Exporter;
@ISA = qw(Exporter);

# Make sure Testing can do everything its supposed to.
foreach my $meth (@::Exporter_Methods) {
    ::ok( Testing->can($meth), "subclass can $meth()" );
}

%EXPORT_TAGS = (
                This => [qw(stuff %left)],
                That => [qw(Above the @wailing)],
                tray => [qw(Fasten $seatbelt)],
               );
@EXPORT    = qw(lifejacket);
@EXPORT_OK = qw(under &your $seat);
$VERSION = '1.05';

::ok( Testing->require_version(1.05),   'require_version()' );
eval { Testing->require_version(1.11); 1 };
::ok( $@,                               'require_version() fail' );
::ok( Testing->require_version(0),      'require_version(0)' );

sub lifejacket  { 'lifejacket'  }
sub stuff       { 'stuff'       }
sub Above       { 'Above'       }
sub the         { 'the'         }
sub Fasten      { 'Fasten'      }
sub your        { 'your'        }
sub under       { 'under'       }
use vars qw($seatbelt $seat @wailing %left);
$seatbelt = 'seatbelt';
$seat     = 'seat';
@wailing = qw(AHHHHHH);
%left = ( left => "right" );


Exporter::export_ok_tags;

my %tags     = map { $_ => 1 } map { @$_ } values %EXPORT_TAGS;
my %exportok = map { $_ => 1 } @EXPORT_OK;
my $ok = 1;
foreach my $tag (keys %tags) {
    $ok = exists $exportok{$tag};
}
::ok( $ok, 'export_ok_tags()' );


package Foo;
Testing->import;

::ok( defined &lifejacket,      'simple import' );


package Bar;
my @imports = qw($seatbelt &Above stuff @wailing %left);
Testing->import(@imports);

::ok( (!grep { eval "!defined $_" } map({ /^\w/ ? "&$_" : $_ } @imports)),
      'import by symbols' );


package Yar;
my @tags = qw(:This :tray);
Testing->import(@tags);

::ok( (!grep { eval "!defined $_" } map { /^\w/ ? "&$_" : $_ }
             map { @$_ } @{$Testing::EXPORT_TAGS{@tags}}),
      'import by tags' );


package Arrr;
Testing->import(qw(!lifejacket));

::ok( !defined &lifejacket,     'deny import by !' );


package Mars;
Testing->import('/e/');

::ok( (!grep { eval "!defined $_" } map { /^\w/ ? "&$_" : $_ }
            grep { /e/ } @Testing::EXPORT, @Testing::EXPORT_OK),
      'import by regex');


package Venus;
Testing->import('!/e/');

::ok( (!grep { eval "defined $_" } map { /^\w/ ? "&$_" : $_ }
            grep { /e/ } @Testing::EXPORT, @Testing::EXPORT_OK),
      'deny import by regex');
::ok( !defined &lifejacket, 'further denial' );


package More::Testing;
@ISA = qw(Exporter);
$VERSION = 0;
eval { More::Testing->require_version(0); 1 };
::ok(!$@,       'require_version(0) and $VERSION = 0');


package Yet::More::Testing;
@ISA = qw(Exporter);
$VERSION = 0;
eval { Yet::More::Testing->require_version(10); 1 };
::ok($@ !~ /\(undef\)/,       'require_version(10) and $VERSION = 0');
