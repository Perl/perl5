#! perl -w

use strict;
use Test::More tests => 58;
BEGIN { 
  if ($^O eq 'VMS') {
    # So we can get the return value of system()
    require vmsish;
    import vmsish;
  }
}
use Config;
use Cwd;
use File::Path qw( mkpath );
use File::Temp qw( tempdir );
use ExtUtils::CBuilder::Base;

# XXX protect from user CC as we mock everything here
local $ENV{CC};

my ( $base, $phony, $cwd );
my ( $source_file, $object_file, $lib_file );

$base = ExtUtils::CBuilder::Base->new();
ok( $base, "ExtUtils::CBuilder::Base->new() returned true value" );
isa_ok( $base, 'ExtUtils::CBuilder::Base' );

{
  $phony = 'foobar';
  $base = ExtUtils::CBuilder::Base->new(
      config  => { cc => $phony },
  );
  ok( $base, "ExtUtils::CBuilder::Base->new() returned true value" );
  isa_ok( $base, 'ExtUtils::CBuilder::Base' );
  is( $base->{config}->{cc}, $phony,
      "Got expected value when 'config' argument passed to new()" );
}

{
    $phony = 'barbaz';
    local $ENV{CC} = $phony;
    $base = ExtUtils::CBuilder::Base->new();
    ok( $base, "ExtUtils::CBuilder::Base->new() returned true value" );
    isa_ok( $base, 'ExtUtils::CBuilder::Base' );
    is( $base->{config}->{cc}, $phony,
        "Got expected value \$ENV{CC} set" );
}

{
    my $path_to_perl = File::Spec->catfile( '', qw| usr bin perl | );
    local $^X = $path_to_perl;
    is(
        ExtUtils::CBuilder::Base::find_perl_interpreter(),
        $path_to_perl,
        "find_perl_interpreter() returned expected absolute path"
    );
}

{
    my $path_to_perl = 'foobar';
    local $^X = $path_to_perl;
    # %Config is read-only.  We cannot assign to it and we therefore cannot
    # simulate the condition that would occur were its value something other
    # than an existing file.
    if ( !$ENV{PERL_CORE} and $Config::Config{perlpath}) {
        is(
            ExtUtils::CBuilder::Base::find_perl_interpreter(),
            $Config::Config{perlpath},
            "find_perl_interpreter() returned expected file"
        );
    }
    else {
        local $^X = $path_to_perl = File::Spec->rel2abs($path_to_perl);
        is(
            ExtUtils::CBuilder::Base::find_perl_interpreter(),
            $path_to_perl,
            "find_perl_interpreter() returned expected name"
        );
    }
}

{
    $cwd = cwd();
    my $tdir = tempdir();
    chdir $tdir;
    $base = ExtUtils::CBuilder::Base->new();
    ok( $base, "ExtUtils::CBuilder::Base->new() returned true value" );
    isa_ok( $base, 'ExtUtils::CBuilder::Base' );
    is( scalar keys %{$base->{files_to_clean}}, 0,
        "No files needing cleaning yet" );

    my $file_for_cleaning = File::Spec->catfile( $tdir, 'foobar' );
    open my $IN, '>', $file_for_cleaning
        or die "Unable to open dummy file: $!";
    print $IN "\n";
    close $IN or die "Unable to close dummy file: $!";

    $base->add_to_cleanup( $file_for_cleaning );
    is( scalar keys %{$base->{files_to_clean}}, 1,
        "One file needs cleaning" );

    $base->cleanup();
    ok( ! -f $file_for_cleaning, "File was cleaned up" );

    chdir $cwd;
}

# fake compiler is perl and will always succeed
$base = ExtUtils::CBuilder::Base->new(
    config  => {
        cc => File::Spec->rel2abs($^X) . " -e1 --",
        ld => File::Spec->rel2abs($^X) . " -e1 --",
    }
);
ok( $base, "ExtUtils::CBuilder::Base->new() returned true value" );
isa_ok( $base, 'ExtUtils::CBuilder::Base' );
eval {
    $base->compile(foo => 'bar');
};
like(
    $@,
    qr/Missing 'source' argument to compile/,
    "Got expected error message when lacking 'source' argument to compile()"
);

$base = ExtUtils::CBuilder::Base->new( quiet => 1 );
ok( $base, "ExtUtils::CBuilder::Base->new() returned true value" );
isa_ok( $base, 'ExtUtils::CBuilder::Base' );

$source_file = File::Spec->catfile('t', 'compilet.c');
create_c_source_file($source_file);
ok(-e $source_file, "source file '$source_file' created");

# object filename automatically assigned
my $obj_ext = $base->{config}{obj_ext};
is( $base->object_file($source_file),
    File::Spec->catfile('t', "compilet$obj_ext"),
    "object_file(): got expected automatically assigned name for object file"
);

# object filename explicitly assigned
$object_file = File::Spec->catfile('t', 'my_special_compilet.o' );
is( $object_file,
    $base->compile(
        source      => $source_file,
        object_file => $object_file,
    ),
    "compile(): returned object file with specified name"
);

$lib_file = $base->lib_file($object_file);
ok( $lib_file, "lib_file() returned true value" );

my ($lib, @temps);
($lib, @temps) = $base->link(
    objects     => $object_file,
    module_name => 'compilet',
);
$lib =~ tr/"'//d; #"
is($lib_file, $lib, "lib_file(): got expected value for $lib");

($lib, @temps) = $base->link(
    objects     => [ $object_file ],
    module_name => 'compilet',
);
$lib =~ tr/"'//d; #"
is($lib_file, $lib, "lib_file(): got expected value for $lib");

($lib, @temps) = $base->link(
    lib_file    => $lib_file,
    objects     => [ $object_file ],
    module_name => 'compilet',
);
$lib =~ tr/"'//d; #"
is($lib_file, $lib, "lib_file(): got expected value for $lib");

$lib = $base->link(
    objects     => $object_file,
    module_name => 'compilet',
);
$lib =~ tr/"'//d; #"
is($lib_file, $lib, "lib_file(): got expected value for $lib");

{
    local $ENV{PERL_CORE} = '' unless $ENV{PERL_CORE};
    my $include_dir = $base->perl_inc();
    ok( $include_dir, "perl_inc() returned true value" );
    ok( -d $include_dir, "perl_inc() returned directory" );
}

#
$base = ExtUtils::CBuilder::Base->new( quiet => 1 );
ok( $base, "ExtUtils::CBuilder::Base->new() returned true value" );
isa_ok( $base, 'ExtUtils::CBuilder::Base' );

$source_file = File::Spec->catfile('t', 'compilet.c');
create_c_source_file($source_file);
ok(-e $source_file, "source file '$source_file' created");
$object_file = File::Spec->catfile('t', 'my_special_compilet.o' );
is( $object_file,
    $base->compile(
        source      => $source_file,
        object_file => $object_file,
        defines     => { alpha => 'beta', gamma => 'delta' },
    ),
    "compile() completed when 'defines' provided; returned object file with specified name"
);

my $exe_file = $base->exe_file($object_file);
my $ext = $base->{config}{_exe};
my $expected = File::Spec->catfile('t', qq|my_special_compilet$ext| );
is(
    $exe_file,
    $expected,
    "exe_file(): returned expected name of executable"
);

my %args = ();
my @defines = $base->arg_defines( %args );
ok( ! @defines, "Empty hash passed to arg_defines() returns empty list" );

%args = ( alpha => 'beta', gamma => 'delta' );
my $defines_seen_ref = { map { $_ => 1 } $base->arg_defines( %args ) };
is_deeply(
    $defines_seen_ref,
    { '-Dalpha=beta' => 1, '-Dgamma=delta' => 1 },
    "arg_defines(): got expected defines",
);

my $include_dirs_seen_ref =
    { map {$_ => 1} $base->arg_include_dirs( qw| alpha beta gamma | ) };
is_deeply(
    $include_dirs_seen_ref,
    { '-Ialpha' => 1, '-Ibeta' => 1, '-Igamma' => 1 },
    "arg_include_dirs(): got expected include_dirs",
);

is( '-c', $base->arg_nolink(), "arg_nolink(): got expected value" );

my $seen_ref =
    { map {$_ => 1} $base->arg_object_file('alpha') };
is_deeply(
    $seen_ref,
    { '-o'  => 1, 'alpha' => 1 },
    "arg_object_file(): got expected option flag and value",
);

$seen_ref = { map {$_ => 1} $base->arg_share_object_file('alpha') };
my %exp = map {$_ => 1} $base->split_like_shell($base->{config}{lddlflags});
$exp{'-o'} = 1;
$exp{'alpha'} = 1; 

is_deeply(
    $seen_ref,
    \%exp,
    "arg_share_object_file(): got expected option flag and value",
);

$seen_ref =
    { map {$_ => 1} $base->arg_exec_file('alpha') };
is_deeply(
    $seen_ref,
    { '-o'  => 1, 'alpha' => 1 },
    "arg_exec_file(): got expected option flag and value",
);

ok(! $base->split_like_shell(undef),
    "split_like_shell(): handled undefined argument as expected" );

my $array_ref = [ qw| alpha beta gamma | ];
my %split_seen = map { $_ => 1 } $base->split_like_shell($array_ref);
%exp = ( alpha => 1, beta => 1, gamma => 1 );
is_deeply( \%split_seen, \%exp,
    "split_like_shell(): handled array ref as expected" );

{
    $cwd = cwd();
    my $tdir = tempdir();
    my $subdir = File::Spec->catdir(
        $tdir, qw| alpha beta gamma delta epsilon 
            zeta eta theta iota kappa lambda |
    );
    mkpath($subdir, { mode => 0711 } );
    chdir $subdir
        or die "Unable to change to temporary directory for testing";
    local $ENV{PERL_CORE} = 1;
    my $capture = q{};
    local $SIG{__WARN__} = sub { $capture = $_[0] };
    my $expected_message =
        qr/PERL_CORE is set but I can't find your perl source!/; #'
    my $rv;

    $rv = $base->perl_src();
    is( $rv, q{}, "perl_src(): returned empty string as expected" );
    like( $capture, $expected_message,
        "perl_src(): got expected warning" );
    $capture = q{};

    my $config = File::Spec->catfile( $subdir, 'config_h.SH' );
    touch_file($config);
    $rv = $base->perl_src();
    is( $rv, q{}, "perl_src(): returned empty string as expected" );
    like( $capture, $expected_message,
        "perl_src(): got expected warning" );
    $capture = q{};

    my $perlh = File::Spec->catfile( $subdir, 'perl.h' );
    touch_file($perlh);
    $rv = $base->perl_src();
    is( $rv, q{}, "perl_src(): returned empty string as expected" );
    like( $capture, $expected_message,
        "perl_src(): got expected warning" );
    $capture = q{};

    my $libsubdir = File::Spec->catdir( $subdir, 'lib' );
    mkpath($libsubdir, { mode => 0711 } );
    my $exporter = File::Spec->catfile( $libsubdir, 'Exporter.pm' );
    touch_file($exporter);
    $rv = $base->perl_src();
    ok( -d $rv, "perl_src(): returned a directory" );
    is( $rv, Cwd::realpath($subdir), "perl_src(): identified directory" );
    is( $capture, q{}, "perl_src(): no warning, as expected" );

    chdir $cwd
        or die "Unable to change from temporary directory after testing";
}

my ($dl_file_out, $mksymlists_args);
my $dlf = 'Kappa';
%args = (
    dl_vars         => [ qw| alpha beta gamma | ],
    dl_funcs        => {
        'Homer::Iliad'      => [ qw(trojans greeks) ],
        'Homer::Odyssey'    => [ qw(travellers family suitors) ],
    },
    dl_func_list    => [ qw| delta epsilon | ],
    dl_imports      => { zeta => 'eta', theta => 'iota' },
    dl_name         => 'Tk::Canvas',
    dl_base         => 'Tk::Canvas.ext',
    dl_file         => $dlf,
    dl_version      => '7.7',
);
($dl_file_out, $mksymlists_args) =
    ExtUtils::CBuilder::Base::_prepare_mksymlists_args(\%args);
is( $dl_file_out, $dlf, "_prepare_mksymlists_args(): Got expected name for dl_file" );
is_deeply( $mksymlists_args,
    {
        DL_VARS         => [ qw| alpha beta gamma | ],
        DL_FUNCS        => {
            'Homer::Iliad'      => [ qw(trojans greeks) ],
            'Homer::Odyssey'    => [ qw(travellers family suitors) ],
        },
        FUNCLIST        => [ qw| delta epsilon | ],
        IMPORTS         => { zeta => 'eta', theta => 'iota' },
        NAME            => 'Tk::Canvas',
        DLBASE          => 'Tk::Canvas.ext',
        FILE            => $dlf,
        VERSION         => '7.7',
    },
    "_prepare_mksymlists_args(): got expected arguments for Mksymlists",
);

$dlf = 'Canvas';
%args = (
    dl_name         => 'Tk::Canvas',
    dl_base         => 'Tk::Canvas.ext',
);
($dl_file_out, $mksymlists_args) =
    ExtUtils::CBuilder::Base::_prepare_mksymlists_args(\%args);
is( $dl_file_out, $dlf, "_prepare_mksymlists_args(): got expected name for dl_file" );
is_deeply( $mksymlists_args,
    {
        DL_VARS         => [],
        DL_FUNCS        => {},
        FUNCLIST        => [],
        IMPORTS         => {},
        NAME            => 'Tk::Canvas',
        DLBASE          => 'Tk::Canvas.ext',
        FILE            => $dlf,
        VERSION         => '0.0',
    },
    "_prepare_mksymlists_args(): got expected arguments for Mksymlists",
);

#####

for ($source_file, $object_file, $lib_file) {
  tr/"'//d; #"
  1 while unlink;
}

pass("Completed all tests in $0");

if ($^O eq 'VMS') {
   1 while unlink 'COMPILET.LIS';
   1 while unlink 'COMPILET.OPT';
}

sub create_c_source_file {
    my $source_file = shift;
    open my $FH, '>', $source_file or die "Can't create $source_file: $!";
    print $FH "int boot_compilet(void) { return 1; }\n";
    close $FH;
}

sub touch_file {
    my $f = shift;
    open my $FH, '>', $f or die "Can't create $f: $!";
    print $FH "\n";
    close $FH;
    return $f;
}
