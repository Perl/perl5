#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

sub runthis {
    my($prog, $stdin, @files) = @_;

    my $cmd = '';
    if ($^O eq 'MSWin32' || $^O eq 'NetWare' || $^O eq 'VMS' ) {
        $cmd = qq{$^X -e "$prog"};
        $cmd .= " ". join ' ', map qq{"$_"}, @files if @files;
        $cmd = qq{$^X -le "print '$stdin'" | } . $cmd if defined $stdin;
    }
    else {
        $cmd = qq{$^X -e '$prog' @files};
        $cmd = qq{$^X -le 'print q{$stdin}' | } . $cmd if defined $stdin;
    }

    # The combination of $^X, pipes and STDIN is broken on VMS and
    # will hang.
    if( defined $stdin && $^O eq 'VMS' && $TODO ) {
        return 0;
    }

    my $result = `$cmd`;
    $result =~ s/\n\n/\n/ if $^O eq 'VMS'; # pipes sometimes double these

    return $result;
}

    
require "./test.pl";
plan(tests => 21);

use File::Spec;

my $devnull = File::Spec->devnull;

open(TRY, '>Io_argv1.tmp') || (die "Can't open temp file: $!");
print TRY "a line\n";
close TRY;

$x = runthis( 'while (<>) { print $., $_; }', undef, ('Io_argv1.tmp') x 2);
is($x, "1a line\n2a line\n", '<> from two files');

{
    local $TODO = 'The combo of STDIN, pipes and $^X is broken on VMS'
      if $^O eq 'VMS';
    $x = runthis( 'while (<>) { print $_; }', 'foo', 'Io_argv1.tmp', '-' );
    is($x, "a line\nfoo\n", '   from a file and STDIN');

    $x = runthis( 'while (<>) {print $_;}', 'foo' );
    is($x, "foo\n", '   from just STDIN');
}

@ARGV = ('Io_argv1.tmp', 'Io_argv1.tmp', $devnull, 'Io_argv1.tmp');
while (<>) {
    $y .= $. . $_;
    if (eof()) {
	is($., 3, '$. counts <>');
    }
}

is($y, "1a line\n2a line\n3a line\n", '<> from @ARGV');


open(TRY, '>Io_argv1.tmp') or die "Can't open temp file: $!";
close TRY;
open(TRY, '>Io_argv2.tmp') or die "Can't open temp file: $!";
close TRY;
@ARGV = ('Io_argv1.tmp', 'Io_argv2.tmp');
$^I = '_bak';   # not .bak which confuses VMS
$/ = undef;
my $i = 6;
while (<>) {
    s/^/ok $i\n/;
    ++$i;
    print;
    next_test();
}
open(TRY, '<Io_argv1.tmp') or die "Can't open temp file: $!";
print while <TRY>;
open(TRY, '<Io_argv2.tmp') or die "Can't open temp file: $!";
print while <TRY>;
close TRY;
undef $^I;

ok( eof TRY );

ok( eof NEVEROPENED,    'eof() true on unopened filehandle' );

open STDIN, 'Io_argv1.tmp' or die $!;
@ARGV = ();
ok( !eof(),     'STDIN has something' );

is( <>, "ok 6\n" );

open STDIN, $devnull or die $!;
@ARGV = ();
ok( eof(),      'eof() true with empty @ARGV' );

@ARGV = ('Io_argv1.tmp');
ok( !eof() );

@ARGV = ($devnull, $devnull);
ok( !eof() );

close ARGV or die $!;
ok( eof(),      'eof() true after closing ARGV' );

{
    local $/;
    open F, 'Io_argv1.tmp' or die;
    <F>;	# set $. = 1
    is( <F>, undef );

    open F, $devnull or die;
    ok( defined(<F>) );

    is( <F>, undef );
    is( <F>, undef );

    open F, $devnull or die;	# restart cycle again
    ok( defined(<F>) );
    is( <F>, undef );
    close F;
}

END { unlink 'Io_argv1.tmp', 'Io_argv1.tmp_bak', 'Io_argv2.tmp', 'Io_argv2.tmp_bak' }
