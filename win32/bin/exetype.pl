#!perl -w
use strict;
unless (@ARGV == 2) {
    print "Usage: $0 exefile [CONSOLE|WINDOWS]\n";
    exit;
}
unless ($ARGV[1] =~ /^(console|windows)$/i) {
    print "Invalid subsystem $ARGV[1], please use CONSOLE or WINDOWS\n";
    exit;
}
my ($record,$magic,$offset,$size);
open EXE, "+< $ARGV[0]" or die "Cannot open $ARGV[0]: $!";
binmode EXE;
read EXE, $record, 32*4;
($magic,$offset) = unpack "Sx58L", $record;
die "Not an MSDOS executable file" unless $magic == 0x5a4d;
seek EXE, $offset, 0;
read EXE, $record, 24;
($magic,$size) = unpack "Lx16S", $record;
die "PE header not found" unless $magic == 0x4550;
die "Optional header not in NT32 format" unless $size == 224;
seek EXE, $offset+24+68, 0;
print EXE pack "S", uc($ARGV[1]) eq 'CONSOLE' ? 3 : 2;
close EXE;
__END__

=head1 NAME

exetype - Change executable subsystem type between "Console" and "Windows"

=head1 SYNOPSIS

	C:\perl\bin> copy perl.exe guiperl.exe
	C:\perl\bin> exetype guiperl.exe windows

=head1 DESCRIPTION

This program edits an executable file to indicate which subsystem the
operating system must invoke for execution.

You can specify any of the following subsystems:

=over

=item CONSOLE

The CONSOLE subsystem handles a Win32 character-mode application that
use a console supplied by the operating system.

=item WINDOWS

The WINDOWS subsystem handles an application that does not require a
console and creates its own windows, if required.

=back

=head1 AUTHOR

Jan Dubois <jand@activestate.com>

=cut
