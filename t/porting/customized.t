#!./perl -w

# Test that CUSTOMIZED files in Maintainers.pl have not been overwritten.
# Test that each entry in customized.dat corresponds to CUSTOMIZED entry in
# Maintainers.pl.

BEGIN {
        # This test script uses a slightly atypical invocation of the 'standard'
        # core testing setup stanza.
        # The existing porting tools which manage the Maintainers file all
        # expect to be run from the root
        # XXX that should be fixed

    chdir '..' unless -d 't';
    @INC = qw(lib Porting t);
    require 'test.pl';
    skip_all("pre-computed SHA1 won't match under EBCDIC") if $::IS_EBCDIC;
    skip_all("This distro may have modified some files in cpan/. Skipping validation.") if $ENV{'PERL_BUILD_PACKAGING'};
}

use strict;
use warnings;
use Digest;
use File::Spec;
use Maintainers qw[%Modules get_module_files get_module_pat];

sub filter_customized {
    my ($m, @files) = @_;

    return @files
        unless my $customized = $Modules{$m}{CUSTOMIZED};

    my ($pat) = map { qr/$_/ }
        join ( '|' =>
          map { ref $_ ? $_ : qr/\b\Q$_\E$/ } @{ $customized },
          # https://github.com/Perl/perl5/issues/20228
          qr/pod\/perlfilter\.pod/
        );

    return grep { $_ =~ $pat } @files;
}

sub my_get_module_files {
    my $m = shift;
    return filter_customized $m => map { Maintainers::expand_glob($_) } get_module_pat($m);
}

my $TestCounter = 0;

my $digest_type = 'SHA-1';

my $original_dir = File::Spec->rel2abs(File::Spec->curdir);
my $data_dir = File::Spec->catdir('t', 'porting');
my $customized = File::Spec->catfile($data_dir, 'customized.dat');

my %customized;

my $regen = 0;

while (@ARGV && substr($ARGV[0], 0, 1) eq '-') {
    my $arg = shift @ARGV;

    $arg =~ s/^--/-/; # Treat '--' the same as a single '-'
    if ($arg eq '-regen') {
        $regen = 1;
    }
    else {
        die <<EOF;
Unknown option '$arg'

Usage: $0 [ --regen ]\n"
    --regen    -> Regenerate the data file for $0

EOF
    }
}

my $data_fh;

if ( $regen ) {
    open $data_fh, '>:raw', $customized or die "Can't open $customized";
    print $data_fh <<~'END_OF_REGEN_MESSAGE';
        # Regenerate this file using:
        #    cd t; ./perl -I../lib porting/customized.t --regen; cd -
        END_OF_REGEN_MESSAGE
}
else {
    open $data_fh, '<:raw', $customized or die "Can't open $customized";
    while (<$data_fh>) {
        next if /^#/;
        chomp;
        my ($module,$file,$sha) = split ' ';
        $customized{ $module }->{ $file } = $sha;
    }
    close $data_fh;
}
my %customized_seen = ();
foreach my $module (keys %customized) {
    foreach my $file (keys %{$customized{$module}}) {
        $customized_seen{$file}++;
    }
}

my %maintainers_seen = ();
foreach my $module ( sort keys %Modules ) {
    next unless my $files = $Modules{ $module }{CUSTOMIZED};
    next unless @{ $files };
    my @perl_files = my_get_module_files( $module );
    foreach my $file ( @perl_files ) {
        my $digest = Digest->new( $digest_type );
        open my $fh, '<', $file or die "Can't open $file";
        binmode $fh;
        $digest->addfile( $fh );
        close $fh;
        $maintainers_seen{$file}++;
        my $id = $digest->hexdigest;
        if ( $regen ) {
            print $data_fh join(' ', $module, $file, $id), "\n";
            next;
        }
        my $should_be = $customized{ $module }->{ $file };
        is( $id, $should_be, "SHA for $file matches stashed SHA" );
    }
}

foreach my $f (sort keys %customized_seen) {
    ok($maintainers_seen{$f},
        "$f in $customized refers to CUSTOMIZED entry in \%Maintainers::Modules");
}

if ( $regen ) {
    pass( "regenerated data file" );
    close $data_fh;
}

done_testing();

=pod

=head1 NAME

customized.t - Test that CUSTOMIZED files in F<Porting/Maintainers.pl> have not been overwritten

=head1 SYNOPSIS

    cd t; ./perl -I../lib porting/customized.t --regen; cd -

=head1 DESCRIPTION

F<t/porting/customized.t> checks that files listed in
F<Porting/Maintainers.pl> that have been C<CUSTOMIZED> are not accidentally
overwritten by CPAN module updates.

=head1 OPTIONS

=over

=item C<--regen>

Use this command line option to regenerate the C<customized.dat> file.

=back

=cut
