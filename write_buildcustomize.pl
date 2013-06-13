#!./miniperl -w

use strict;
if (@ARGV) {
    my $dir = shift;
    chdir $dir or die "Can't chdir '$dir': $!";
    unshift @INC, 'lib';
}

unshift @INC, ('dist/Cwd', 'dist/Cwd/lib');
require File::Spec::Functions;

my $file = 'lib/buildcustomize.pl';

# To clarify, this isn't the entire suite of modules considered "toolchain"
# It's not even all modules needed to build ext/
# It's just the source paths of the (minimum complete set of) modules in ext/
# needed to build the nonxs modules
# After which, all nonxs modules are in lib, which was always sufficient to
# allow miniperl to build everything else.
# Term::ReadLine is not here for building but for allowing the debugger to
# run under miniperl when nothing but miniperl will build :-(.

my @toolchain = qw(cpan/AutoLoader/lib
		   dist/Carp/lib
		   dist/Cwd dist/Cwd/lib
		   dist/ExtUtils-Command/lib
		   dist/ExtUtils-Install/lib
		   cpan/ExtUtils-MakeMaker/lib
		   dist/ExtUtils-Manifest/lib
		   cpan/File-Path/lib
		   ext/re
		   dist/Term-ReadLine/lib
		   );

# Used only in ExtUtils::Liblist::Kid::_win32_ext()
push @toolchain, 'cpan/Text-ParseWords/lib' if $^O eq 'MSWin32';

# lib must be last, as the toolchain modules write themselves into it
# as they build, and it's important that @INC order ensures that the partially
# written files are always masked by the complete versions.

my $inc = join ",\n        ",
    map { "q\0$_\0" }
    (map {File::Spec::Functions::rel2abs($_)} @toolchain, 'lib'), '.';

open my $fh, '>', $file
    or die "Can't open $file: $!";

my $error;

# If any of the system's build tools are written in Perl, then this module
# may well be loaded by a much older version than we are building. So keep it
# as backwards compatible as is easy.
print $fh <<"EOT" or $error = "Can't print to $file: $!";
#!perl

# We are miniperl, building extensions
# Reset \@INC completely, adding the directories we need, and removing the
# installed directories (which we don't need to read, and may confuse us)
\@INC = ($inc);
EOT

if ($error) {
    close $fh
        or warn "Can't unlink $file after error: $!";
} else {
    if (close $fh) {
        do $file and exit;
        $error = "Can't load generated $file: $@";
    } else {
        $error = "Can't close $file: $!";
    }
}

# It's going very wrong, so try to remove the botched file.

unlink $file
    or warn "Can't unlink $file after error: $!";
die $error;

# Local variables:
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# ex: set ts=8 sts=4 sw=4 et:
