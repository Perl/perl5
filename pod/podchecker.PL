#!/usr/local/bin/perl

use Config;
use File::Basename qw(&basename &dirname);
use Cwd;

# List explicitly here the variables you want Configure to
# generate.  Metaconfig only looks for shell variables, so you
# have to mention them as if they were shell variables, not
# %Config entries.  Thus you write
#  $startperl
# to ensure Configure will look for $Config{startperl}.

# This forces PL files to create target in same directory as PL file.
# This is so that make depend always knows where to find PL derivatives.
$origdir = cwd;
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
        if ($^O eq 'VMS' or $^O eq 'os2' or $^O eq 'dos');  # "case-forgiving"

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

# In this section, perl variables will be expanded during extraction.
# You can use $Config{...} to use Configure variables.

print OUT <<"!GROK!THIS!";
$Config{'startperl'}
    eval 'exec perl -S \$0 "\$@"'
        if 0;
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';
#############################################################################
# podchecker -- command to invoke the podchecker function in Pod::Checker
#
# Copyright (c) 1998-1999 by Bradford Appleton. All rights reserved.
# This file is part of "PodParser". PodParser is free software;
# you can redistribute it and/or modify it under the same terms
# as Perl itself.
#############################################################################

use strict;
use diagnostics;

=head1 NAME

podchecker - check the syntax of POD format documentation files

=head1 SYNOPSIS

B<podchecker> [B<-help>] [B<-man>] [I<file>S< >...]

=head1 OPTIONS AND ARGUMENTS

=over 8

=item B<-help>

Print a brief help message and exit.

=item B<-man>

Print the manual page and exit.

=item I<file>

The pathname of a POD file to syntax-check (defaults to standard input).

=back

=head1 DESCRIPTION

B<podchecker> will read the given input files looking for POD
syntax errors in the POD documentation and will print any errors
it find to STDERR. At the end, it will print a status message
indicating the number of errors found.

B<podchecker> invokes the B<podchecker()> function exported by B<Pod::Checker>
Please see L<Pod::Checker/podchecker()> for more details.

=head1 SEE ALSO

L<Pod::Parser> and L<Pod::Checker>

=head1 AUTHOR

Brad Appleton E<lt>bradapp@enteract.comE<gt>

Based on code for B<Pod::Text::pod2text(1)> written by
Tom Christiansen E<lt>tchrist@mox.perl.comE<gt>

=cut


use Pod::Checker;
use Pod::Usage;
use Getopt::Long;

## Define options
my %options = (
        "help"     => 0,
        "man"      => 0,
);

## Parse options
GetOptions(\%options, "help", "man")  ||  pod2usage(2);
pod2usage(1)  if ($options{help});
pod2usage(-verbose => 2)  if ($options{man});

## Dont default to STDIN if connected to a terminal
pod2usage(2) if ((@ARGV == 0) && (-t STDIN));

## Invoke podchecker()
if(@ARGV) {
   for (@ARGV) { podchecker($_) };
} else {
	podchecker("<&STDIN");
}

!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
