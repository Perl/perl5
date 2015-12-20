#!/usr/bin/perl
#
# Check or update the version of Perl modules.
#
# Examines all module files (*.pm) under the lib directory and verifies that
# the package is set to the same value as the current version number as
# determined by the MYMETA.json file at the top of the source distribution.
#
# When given the --update option, instead fixes all of the Perl modules found
# to have the correct version.

use 5.006;
use strict;
use warnings;

use lib 't/lib';

use Carp qw(croak);
use File::Find qw(find);
use Getopt::Long qw(GetOptions);
use Test::More;
use Test::RRA qw(skip_unless_automated use_prereq);

# If we have options, we're being run from the command line and always load
# our prerequisite modules.  Otherwise, check if we have necessary
# prerequisites and should run as a test suite.
if (@ARGV) {
    require JSON::PP;
    require Perl6::Slurp;
    Perl6::Slurp->import;
} else {
    skip_unless_automated('Module version tests');
    use_prereq('JSON::PP');
    use_prereq('Perl6::Slurp');
}

# A regular expression matching the version string for a module using the
# package syntax from Perl 5.12 and later.  $1 will contain all of the line
# contents prior to the actual version string, $2 will contain the version
# itself, and $3 will contain the rest of the line.
our $REGEX_VERSION_PACKAGE = qr{
    (                           # prefix ($1)
        \A \s*                  # whitespace
        package \s+             # package keyword
        [\w\:\']+ \s+           # package name
    )
    ( v? [\d._]+ )              # the version number itself ($2)
    (                           # suffix ($3)
        \s* ;
    )
}xms;

# A regular expression matching a $VERSION string in a module.  $1 will
# contain all of the line contents prior to the actual version string, $2 will
# contain the version itself, and $3 will contain the rest of the line.
our $REGEX_VERSION_OLD = qr{
    (                           # prefix ($1)
        \A .*                   # any prefix, such as "our"
        [\$*]                   # scalar or typeglob
        [\w\:\']*\b             # optional package name
        VERSION\b               # version variable
        \s* = \s*               # assignment
    )
    [\"\']?                     # optional leading quote
    ( v? [\d._]+ )              # the version number itself ($2)
    [\"\']?                     # optional trailing quote
    (                           # suffix ($3)
        \s*
        ;
    )
}xms;

# Find all the Perl modules shipped in this package, if any, and returns the
# list of file names.
#
# $dir - The root directory to search, lib by default
#
# Returns: List of file names
sub module_files {
    my ($dir) = @_;
    $dir ||= 'lib';
    return if !-d $dir;
    my @files;
    my $wanted = sub {
        if ($_ eq 'blib') {
            $File::Find::prune = 1;
            return;
        }
        if (m{ [.] pm \z }xms) {
            push(@files, $File::Find::name);
        }
        return;
    };
    find($wanted, $dir);
    return @files;
}

# Given a module file, read it for the version value and return the value.
#
# $file - File to check, which should be a Perl module
#
# Returns: The version of the module
#  Throws: Text exception on I/O failure or inability to find version
sub module_version {
    my ($file) = @_;
    open(my $data, q{<}, $file) or die "$0: cannot open $file: $!\n";
    while (defined(my $line = <$data>)) {
        if (   $line =~ $REGEX_VERSION_PACKAGE
            || $line =~ $REGEX_VERSION_OLD)
        {
            my ($prefix, $version, $suffix) = ($1, $2, $3);
            close($data) or die "$0: error reading from $file: $!\n";
            return $version;
        }
    }
    close($data) or die "$0: error reading from $file: $!\n";
    die "$0: cannot find version number in $file\n";
}

# Return the current version of the distribution from MYMETA.json in the
# current directory.
#
# Returns: The version number of the distribution
# Throws: Text exception if MYMETA.json is not found or doesn't contain a
#         version
sub dist_version {
    my $json     = JSON::PP->new->utf8(1);
    my $metadata = $json->decode(scalar(slurp('MYMETA.json')));
    my $version  = $metadata->{version};
    if (!defined($version)) {
        die "$0: cannot find version number in MYMETA.json\n";
    }
    return $version;
}

# Given a module file and the new version for that module, update the version
# in that module to the new one.
#
# $file    - Perl module file whose version should be updated
# $version - The new version number
#
# Returns: undef
#  Throws: Text exception on I/O failure or inability to find version
sub update_module_version {
    my ($file, $version) = @_;
    open(my $in, q{<}, $file) or die "$0: cannot open $file: $!\n";
    open(my $out, q{>}, "$file.new")
      or die "$0: cannot create $file.new: $!\n";

    # If the version starts with v, use it without quotes.  Otherwise, quote
    # it to prevent removal of trailing zeroes.
    if ($version !~ m{ \A v }xms) {
        $version = "'$version'";
    }

    # Scan for the version and replace it.
  SCAN:
    while (defined(my $line = <$in>)) {
        if (   $line =~ s{ $REGEX_VERSION_PACKAGE }{$1$version$3}xms
            || $line =~ s{ $REGEX_VERSION_OLD     }{$1$version$3}xms)
        {
            print {$out} $line or die "$0: cannot write to $file.new: $!\n";
            last SCAN;
        }
        print {$out} $line or die "$0: cannot write to $file.new: $!\n";
    }

    # Copy the rest of the input file to the output file.
    print {$out} <$in> or die "$0: cannot write to $file.new: $!\n";
    close($out) or die "$0: cannot flush $file.new: $!\n";
    close($in)  or die "$0: error reading from $file: $!\n";

    # All done.  Rename the new file over top of the old file.
    rename("$file.new", $file)
      or die "$0: cannot rename $file.new to $file: $!\n";
    return;
}

# Act as a test suite.  Find all of the Perl modules in the package, if any,
# and check that the version for each module matches the version of the
# distribution.  Reports results with Test::More and sets up a plan based on
# the number of modules found.
#
# Returns: undef
#  Throws: Text exception on fatal errors
sub test_versions {
    my $dist_version = dist_version();
    my @modules      = module_files();

    # Output the plan.  Skip the test if there were no modules found.
    if (@modules) {
        plan tests => scalar(@modules);
    } else {
        plan skip_all => 'No Perl modules found';
        return;
    }

    # For each module, get the module version and compare.
    for my $module (@modules) {
        my $module_version = module_version($module);
        is($module_version, $dist_version, "Version for $module");
    }
    return;
}

# Update the versions of all modules to the current distribution version.
#
# Returns: undef
#  Throws: Text exception on fatal errors
sub update_versions {
    my $version = dist_version();
    my @modules = module_files();
    for my $module (@modules) {
        update_module_version($module, $version);
    }
    return;
}

# Main routine.  We run as either a test suite or as a script to update all of
# the module versions, selecting based on whether we got the -u / --update
# command-line option.
my $update;
Getopt::Long::config('bundling', 'no_ignore_case');
GetOptions('update|u' => \$update) or exit 1;
if ($update) {
    update_versions();
} else {
    test_versions();
}
exit 0;
__END__

=for stopwords
Allbery sublicense MERCHANTABILITY NONINFRINGEMENT CPAN

=head1 NAME

module-version.t - Check or update versions of Perl modules

=head1 SYNOPSIS

B<module-version.t> [B<--update>]

=head1 REQUIREMENTS

Perl 5.6.0 or later, the Perl6::Slurp module, and the JSON::PP Perl
module, both of which are available from CPAN.  JSON::PP is also included
in Perl core in Perl 5.14 and later.

=head1 DESCRIPTION

This script has a dual purpose as either a test script or a utility
script.  The intent is to assist with maintaining consistent versions in a
Perl distribution, supporting both the package keyword syntax introduced
in Perl 5.12 or the older explicit setting of a $VERSION variable.

As a test, it reads the current version of a package from the
F<MYMETA.json> file in the current directory (which should be the root of
the distribution) and then looks for any Perl modules in F<lib>.  If it
finds any, it checks that the version number of the Perl module matches
the version number of the package from the F<MYMETA.json> file.  These
test results are reported with Test::More, suitable for any TAP harness.

As a utility script, when run with the B<--update> option, it similarly
finds all Perl modules in F<lib> and then rewrites their version setting
to match the version of the package as determined from the F<MYMETA.json>
file.

=head1 OPTIONS

=over 4

=item B<-u>, B<--update>

Rather than test the Perl modules for the correct version, update all
Perl modules found in the tree under F<lib> to the current version
from the C<MYMETA.json> file.

=back

=head1 AUTHOR

Russ Allbery <eagle@eyrie.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2013, 2014 The Board of Trustees of the Leland Stanford Junior
University

Copyright 2014, 2015 Russ Allbery <eagle@eyrie.org>

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=head1 SEE ALSO

This module is maintained in the rra-c-util package.  The current version
is available from L<http://www.eyrie.org/~eagle/software/rra-c-util/>.

=cut
