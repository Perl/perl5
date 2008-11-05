# *NOTE* This is executed by basic.t and is included in both ExtUtils-MakeMaker 
# as well as Perlcore. Note also that it is expected to be executed in a do "FILE"
# immediately after basic.plt is executed (similarly).

# It is NOT expected to be executed under ExtUtils-Install alone, and in fact is not
# distributed there, however it is expected to be executed under ExtUtils-MakeMaker
# and Perl itself.

my $dist_test_out = run("$make disttest");
is( $?, 0, 'disttest' ) || diag($dist_test_out);

# Test META.yml generation
use ExtUtils::Manifest qw(maniread);

my $distdir  = 'Big-Dummy-0.01';
$distdir =~ s/\./_/g if $Is_VMS;
my $meta_yml = "$distdir/META.yml";

ok( !-f 'META.yml',  'META.yml not written to source dir' );
ok( -f $meta_yml,    'META.yml written to dist dir' );
ok( !-e "META_new.yml", 'temp META.yml file not left around' );

SKIP: {
    # META.yml spec 1.4 was added in 0.11
    skip "Test::YAML::Meta >= 0.11 required", 2
      unless eval { require Test::YAML::Meta }   and
             Test::YAML::Meta->VERSION >= 0.11;

    Test::YAML::Meta::meta_spec_ok($meta_yml);
}

ok open META, $meta_yml or diag $!;
my $meta = join '', <META>;
ok close META;

is $meta, <<"END";
--- #YAML:1.0
name:               Big-Dummy
version:            0.01
abstract:           Try "our" hot dog's
author:
    - Michael G Schwern <schwern\@pobox.com>
license:            unknown
distribution_type:  module
configure_requires:
    ExtUtils::MakeMaker:  0
requires:
    strict:  0
no_index:
    directory:
        - t
        - inc
generated_by:       ExtUtils::MakeMaker version $ExtUtils::MakeMaker::VERSION
meta-spec:
    url:      http://module-build.sourceforge.net/META-spec-v1.4.html
    version:  1.4
END

my $manifest = maniread("$distdir/MANIFEST");
# VMS is non-case preserving, so we can't know what the MANIFEST will
# look like. :(
_normalize($manifest);
is( $manifest->{'meta.yml'}, 'Module meta-data (added by MakeMaker)' );


# Test NO_META META.yml suppression
unlink $meta_yml;
ok( !-f $meta_yml,   'META.yml deleted' );
@mpl_out = run(qq{$perl Makefile.PL "NO_META=1"});
cmp_ok( $?, '==', 0, 'Makefile.PL exited with zero' ) || diag(@mpl_out);
my $distdir_out = run("$make distdir");
is( $?, 0, 'distdir' ) || diag($distdir_out);
ok( !-f $meta_yml,   'META.yml generation suppressed by NO_META' );


# Make sure init_dirscan doesn't go into the distdir
@mpl_out = run(qq{$perl Makefile.PL "PREFIX=../dummy-install"});

cmp_ok( $?, '==', 0, 'Makefile.PL exited with zero' ) || diag(@mpl_out);

ok( grep(/^Writing $makefile for Big::Dummy/, @mpl_out) == 1,
                                'init_dirscan skipped distdir') || 
  diag(@mpl_out);

# I know we'll get ignored errors from make here, that's ok.
# Send STDERR off to oblivion.
open(SAVERR, ">&STDERR") or die $!;
open(STDERR, ">".File::Spec->devnull) or die $!;

my $realclean_out = run("$make realclean");
is( $?, 0, 'realclean' ) || diag($realclean_out);

open(STDERR, ">&SAVERR") or die $!;
close SAVERR;


sub _normalize {
    my $hash = shift;

    while(my($k,$v) = each %$hash) {
        delete $hash->{$k};
        $hash->{lc $k} = $v;
    }
}
