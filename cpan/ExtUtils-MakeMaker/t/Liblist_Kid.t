#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

# Liblist wants to be an object which has File::Spec capabilities, so we
# mock one.

BEGIN {
    package MockEUMM;
    use base 'File::Spec';    # what.
    sub new { return bless {}, 'MockEUMM'; }
}

package liblist_kid_test;

use Test::More 'no_plan';
use ExtUtils::MakeMaker::Config;
use File::Spec;

run();

exit;

sub run {
    use_ok( 'ExtUtils::Liblist::Kid' );

    move_to_os_test_data_dir();
    alias_kid_ext_for_convenience();

    conf_reset();

    return test_kid_win32() if $^O eq 'MSWin32';
    return;
}

# This allows us to get a clean playing field and ensure that the current
# system configuration does not affect the test results.

sub conf_reset {
    delete $Config{$_} for keys %Config;
    delete $ENV{LIB};
    delete $ENV{LIBRARY_PATH};

    return;
}

# This keeps the directory paths in the tests short and allows easy
# separation of OS-specific files.

sub move_to_os_test_data_dir {
    my %os_test_dirs = ( MSWin32 => 't/liblist/win32', );
    return if !$os_test_dirs{$^O};

    chdir $os_test_dirs{$^O} or die "Could not change to liblist test dir '$os_test_dirs{$^O}': $!";
    return;
}

# With this we can use a short function name in the tests and use the same
# one everywhere.

sub alias_kid_ext_for_convenience {
    my %os_ext_funcs = ( MSWin32 => \&ExtUtils::Liblist::Kid::_win32_ext, );
    *_kid_ext = $os_ext_funcs{$^O} if $os_ext_funcs{$^O};

    return;
}
sub _kid_ext;

# Since liblist is object-based, we need to provide a mock object.

sub _ext { _kid_ext( MockEUMM->new, @_ ); }

# tests go here

sub test_kid_win32 {

    $Config{installarchlib} = 'lib';

    is_deeply( [ _ext() ],                           [ '',                    '', '',                    '' ], 'empty input results in empty output' );
    is_deeply( [ _ext( 'unreal_test' ) ],            [ '',                    '', '',                    '' ], 'non-existent file results in empty output' );
    is_deeply( [ _ext( 'test' ) ],                   [ 'test.lib',            '', 'test.lib',            '' ], 'existent file results in a path to the file. .lib is default extension with empty %Config' );
    is_deeply( [ _ext( 'c_test' ) ],                 [ 'lib\CORE\c_test.lib', '', 'lib\CORE\c_test.lib', '' ], '$Config{installarchlib}/CORE is the default search dir aside from cwd' );
    is_deeply( [ _ext( 'double' ) ],                 [ 'double.lib',          '', 'double.lib',          '' ], 'once an instance of a lib is found, the search stops' );
    is_deeply( [ _ext( 'test.lib' ) ],               [ 'test.lib',            '', 'test.lib',            '' ], 'the extension is not tacked on twice' );
    is_deeply( [ _ext( 'test.a' ) ],                 [ 'test.a.lib',          '', 'test.a.lib',          '' ], 'but it will be tacked onto filenamess with other kinds of library extension' );
    is_deeply( [ _ext( 'test test2' ) ],             [ 'test.lib test2.lib',  '', 'test.lib test2.lib',  '' ], 'multiple existing files end up separated by spaces' );
    is_deeply( [ _ext( 'test test2 unreal_test' ) ], [ 'test.lib test2.lib',  '', 'test.lib test2.lib',  '' ], "some existing files don't cause false positives" );
    is_deeply( [ _ext( '-l_test' ) ],                [ 'lib_test.lib',        '', 'lib_test.lib',        '' ], 'prefixing a lib with -l triggers a second search with prefix "lib" when gcc is not in use' );
    is_deeply( [ _ext( '-l__test' ) ],               [ '__test.lib',          '', '__test.lib',          '' ], 'unprefixed lib files are found first when -l is used' );
    is_deeply( [ _ext( '-llibtest' ) ],              [ '',                    '', '',                    '' ], 'if -l is used and the lib name is already prefixed no second search without the prefix is done' );
    is_deeply( [ _ext( '-lunreal_test' ) ],          [ '',                    '', '',                    '' ], 'searching with -l for a non-existent library does not cause an endless loop' );
    is_deeply( [ _ext( '"space lib"' ) ],            [ '"space lib.lib"',     '', '"space lib.lib"',     '' ], 'lib with spaces in the name can be found with the help of quotes' );
    is_deeply( [ _ext( '"""space lib"""' ) ],        [ '"space lib.lib"',     '', '"space lib.lib"',     '' ], 'Text::Parsewords deals with extraneous quotes' );

    is_deeply( [ scalar _ext( 'test' ) ], ['test.lib'], 'asking for a scalar gives a single string' );

    is_deeply( [ _ext( undef,             0, 1 ) ], [ '',                                        '', '',                                        '', [] ],                      'asking for real names with empty input results in an empty extra array' );
    is_deeply( [ _ext( 'unreal_test',     0, 1 ) ], [ '',                                        '', '',                                        '', [] ],                      'asking for real names with non-existent file results in an empty extra array' );
    is_deeply( [ _ext( 'c_test',          0, 1 ) ], [ 'lib\CORE\c_test.lib',                     '', 'lib\CORE\c_test.lib',                     '', ['lib/CORE\c_test.lib'] ], 'asking for real names with an existent file in search dir results in an extra array with a mixed-os file path?!' );
    is_deeply( [ _ext( 'test c_test',     0, 1 ) ], [ 'test.lib lib\CORE\c_test.lib',            '', 'test.lib lib\CORE\c_test.lib',            '', ['lib/CORE\c_test.lib'] ], 'files in cwd do not appear in the real name list?!' );
    is_deeply( [ _ext( '-lc_test c_test', 0, 1 ) ], [ 'lib\CORE\c_test.lib lib\CORE\c_test.lib', '', 'lib\CORE\c_test.lib lib\CORE\c_test.lib', '', ['lib/CORE\c_test.lib'] ], 'finding the same lib in a search dir both with and without -l results in a single listing in the array' );

    is_deeply( [ _ext( 'test :nosearch unreal_test test2' ) ],         [ 'test.lib unreal_test test2',     '', 'test.lib unreal_test test2',     '' ], ':nosearch can force passing through of filenames as they are' );
    is_deeply( [ _ext( 'test :nosearch -lunreal_test test2' ) ],       [ 'test.lib unreal_test.lib test2', '', 'test.lib unreal_test.lib test2', '' ], 'lib names with -l after a :nosearch are suffixed with .lib and the -l is removed' );
    is_deeply( [ _ext( 'test :nosearch unreal_test :search test2' ) ], [ 'test.lib unreal_test test2.lib', '', 'test.lib unreal_test test2.lib', '' ], ':search enables file searching again' );
    is_deeply( [ _ext( 'test :meep test2' ) ],                         [ 'test.lib test2.lib',             '', 'test.lib test2.lib',             '' ], 'unknown :flags are safely ignored' );

    my $curr = File::Spec->rel2abs( '' );
    is_deeply( [ _ext( "-L$curr/dir dir_test" ) ], [ $curr . '\dir\dir_test.lib',         '', $curr . '\dir\dir_test.lib',         '' ], 'directories in -L parameters are searched' );
    is_deeply( [ _ext( "-L/non_dir dir_test" ) ],  [ '',                                  '', '',                                  '' ], 'non-existent -L dirs are ignored safely' );
    is_deeply( [ _ext( "-Ldir dir_test" ) ],       [ $curr . '\dir\dir_test.lib',         '', $curr . '\dir\dir_test.lib',         '' ], 'relative -L directories work' );
    is_deeply( [ _ext( '-L"di r" dir_test' ) ],    [ '"' . $curr . '\di r\dir_test.lib"', '', '"' . $curr . '\di r\dir_test.lib"', '' ], '-L directories with spaces work' );

    $Config{perllibs} = 'pl';
    is_deeply( [ _ext( 'unreal_test' ) ],            [ 'pl.lib', '', 'pl.lib', '' ], '$Config{perllibs} adds extra libs to be searched' );
    is_deeply( [ _ext( 'unreal_test :nodefault' ) ], [ '',       '', '',       '' ], ':nodefault flag prevents $Config{perllibs} from being added' );
    delete $Config{perllibs};

    $Config{libpth} = 'libpath';
    is_deeply( [ _ext( 'lp_test' ) ], [ 'libpath\lp_test.lib', '', 'libpath\lp_test.lib', '' ], '$Config{libpth} adds extra search paths' );
    delete $Config{libpth};

    $Config{lib_ext} = '.meep';
    is_deeply( [ _ext( 'test' ) ], [ 'test.meep', '', 'test.meep', '' ], '$Config{lib_ext} changes the lib extension to be searched for' );
    delete $Config{lib_ext};

    $Config{lib_ext} = '.a';
    is_deeply( [ _ext( 'imp' ) ], [ 'imp.dll.a', '', 'imp.dll.a', '' ], '$Config{lib_ext} == ".a" will find *.dll.a too' );
    delete $Config{lib_ext};

    $Config{cc} = 'C:/MinGW/bin/gcc.exe';

    is_deeply( [ _ext( 'test' ) ],                    [ 'test.lib',      '', 'test.lib',      '' ], '[gcc] searching for straight lib names remains unchanged' );
    is_deeply( [ _ext( '-l__test' ) ],                [ 'lib__test.lib', '', 'lib__test.lib', '' ], '[gcc] lib-prefixed library files are found first when -l is in use' );
    is_deeply( [ _ext( '-ltest' ) ],                  [ 'test.lib',      '', 'test.lib',      '' ], '[gcc] non-lib-prefixed library files are found on the second search when -l is in use' );
    is_deeply( [ _ext( '-llibtest' ) ],               [ 'test.lib',      '', 'test.lib',      '' ], '[gcc] if -l is used and the lib name is already prefixed a second search without the lib is done' );
    is_deeply( [ _ext( ':nosearch -lunreal_test' ) ], [ '-lunreal_test', '', '-lunreal_test', '' ], '[gcc] lib names with -l after a :nosearch remain as they are' );

    $ENV{LIBRARY_PATH} = 'libpath';
    is_deeply( [ _ext( 'lp_test' ) ], [ 'libpath\lp_test.lib', '', 'libpath\lp_test.lib', '' ], '[gcc] $ENV{LIBRARY_PATH} adds extra search paths' );
    delete $ENV{LIBRARY_PATH};

    $Config{cc} = 'c:/Programme/Microsoft Visual Studio 9.0/VC/bin/cl.exe';

    is_deeply( [ _ext( 'test' ) ], [ 'test.lib', '', 'test.lib', '' ], '[vc] searching for straight lib names remains unchanged' );
    is_deeply( [ _ext( ':nosearch -Lunreal_test' ) ], [ '-libpath:unreal_test', '', '-libpath:unreal_test', '' ], '[vc] lib dirs with -L after a :nosearch are prefixed with -libpath:' );
    ok( !exists $ENV{LIB}, '[vc] $ENV{LIB} is not autovivified' );

    $ENV{LIB} = 'vc';
    is_deeply( [ _ext( 'vctest.lib' ) ], [ 'vc\vctest.lib', '', 'vc\vctest.lib', '' ], '[vc] $ENV{LIB} adds search paths' );

    return;
}
