#!perl

package Porting::Manifest;

use strict;
use warnings;

use v5.34;

##
## list of all files from MANIFEST and ignored by MANIFEST.SKIP
##

sub get_files_from_all_manifests {

    my ($reload) = @_;

    state @list;

    @list = () if $reload;

    return @list if scalar @list;

    require ExtUtils::Manifest;
    require Cwd;

    local $ExtUtils::Manifest::Quiet = $ExtUtils::Manifest::Quiet = 1;    # no warnings 'once'

    my @from_manifest;
    my @from_manifest_skip;

    my $skip;

    my $cwd = Cwd::getcwd();
    my @ls_files;
    my $ls_status;
    {
        my $root_pwd = Cwd::abs_path( $INC{"strict.pm"} );

        #my $strict_path = $INC{"strict.pm"};
        $root_pwd =~ s{/*\Qlib/strict.pm\E$}{};
        chdir($root_pwd);

        # read the manifest files
        @from_manifest = keys %{ ExtUtils::Manifest::maniread("MANIFEST") };
        $skip          = ExtUtils::Manifest::maniskip("MANIFEST.SKIP");

        @ls_files  = `git ls-files --full-name`;
        $ls_status = $?
    }
    chdir($cwd);
    die q[Fail to run git ls-files] if $ls_status;

    chomp(@ls_files);

    foreach my $f (@ls_files) {
        next unless $skip->($f);
        push @from_manifest_skip, $f;
    }

    my %uniq = map { $_ => 1 } @from_manifest, @from_manifest_skip;

    return ( @list = sort keys %uniq );
}

##
## list of Porting files listed in MANIFEST or ignored by MANIFEST.SKIP
##

sub get_porting_files {

    return grep { $_ =~ qr{^Porting} && $_ !~ qr{\.(?:gitignore$|github|gitattributes|mailmap|travis)} } get_files_from_all_manifests();
}

sub get_porting_perl_files {
    return grep { $_ !~ qr{\.sh} } get_porting_files();
}

1;
