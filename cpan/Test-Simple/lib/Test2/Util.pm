package Test2::Util;
use strict;
use warnings;

our $VERSION = '1.302073';


use Config qw/%Config/;

our @EXPORT_OK = qw{
    try

    pkg_to_file

    get_tid USE_THREADS
    CAN_THREAD
    CAN_REALLY_FORK
    CAN_FORK

    IS_WIN32

    ipc_separator
};
BEGIN { require Exporter; our @ISA = qw(Exporter) }

BEGIN {
    *IS_WIN32 = ($^O eq 'MSWin32') ? sub() { 1 } : sub() { 0 };
}

sub _can_thread {
    return 0 unless $] >= 5.008001;
    return 0 unless $Config{'useithreads'};

    # Threads are broken on perl 5.10.0 built with gcc 4.8+
    if ($] == 5.010000 && $Config{'ccname'} eq 'gcc' && $Config{'gccversion'}) {
        my @parts = split /\./, $Config{'gccversion'};
        return 0 if $parts[0] > 4 || ($parts[0] == 4 && $parts[1] >= 8);
    }

    # Change to a version check if this ever changes
    return 0 if $INC{'Devel/Cover.pm'};
    return 1;
}

sub _can_fork {
    return 1 if $Config{d_fork};
    return 0 unless IS_WIN32 || $^O eq 'NetWare';
    return 0 unless $Config{useithreads};
    return 0 unless $Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/;

    return _can_thread();
}

BEGIN {
    no warnings 'once';
    *CAN_THREAD      = _can_thread()   ? sub() { 1 } : sub() { 0 };
}
my $can_fork;
sub CAN_FORK () {
    return $can_fork
        if defined $can_fork;
    $can_fork = !!_can_fork();
    no warnings 'redefine';
    *CAN_FORK = $can_fork ? sub() { 1 } : sub() { 0 };
    $can_fork;
}
my $can_really_fork;
sub CAN_REALLY_FORK () {
    return $can_really_fork
        if defined $can_really_fork;
    $can_really_fork = !!$Config{d_fork};
    no warnings 'redefine';
    *CAN_REALLY_FORK = $can_really_fork ? sub() { 1 } : sub() { 0 };
    $can_really_fork;
}

sub _manual_try(&;@) {
    my $code = shift;
    my $args = \@_;
    my $err;

    my $die = delete $SIG{__DIE__};

    eval { $code->(@$args); 1 } or $err = $@ || "Error was squashed!\n";

    $die ? $SIG{__DIE__} = $die : delete $SIG{__DIE__};

    return (!defined($err), $err);
}

sub _local_try(&;@) {
    my $code = shift;
    my $args = \@_;
    my $err;

    no warnings;
    local $SIG{__DIE__};
    eval { $code->(@$args); 1 } or $err = $@ || "Error was squashed!\n";

    return (!defined($err), $err);
}

# Older versions of perl have a nasty bug on win32 when localizing a variable
# before forking or starting a new thread. So for those systems we use the
# non-local form. When possible though we use the faster 'local' form.
BEGIN {
    if (IS_WIN32 && $] < 5.020002) {
        *try = \&_manual_try;
    }
    else {
        *try = \&_local_try;
    }
}

BEGIN {
    if (CAN_THREAD) {
        if ($INC{'threads.pm'}) {
            # Threads are already loaded, so we do not need to check if they
            # are loaded each time
            *USE_THREADS = sub() { 1 };
            *get_tid     = sub() { threads->tid() };
        }
        else {
            # :-( Need to check each time to see if they have been loaded.
            *USE_THREADS = sub() { $INC{'threads.pm'} ? 1 : 0 };
            *get_tid     = sub() { $INC{'threads.pm'} ? threads->tid() : 0 };
        }
    }
    else {
        # No threads, not now, not ever!
        *USE_THREADS = sub() { 0 };
        *get_tid     = sub() { 0 };
    }
}

sub pkg_to_file {
    my $pkg = shift;
    my $file = $pkg;
    $file =~ s{(::|')}{/}g;
    $file .= '.pm';
    return $file;
}

sub ipc_separator() { "~" }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Util - Tools used by Test2 and friends.

=head1 DESCRIPTION

Collection of tools used by L<Test2> and friends.

=head1 EXPORTS

All exports are optional. You must specify subs to import.

=over 4

=item ($success, $error) = try { ... }

Eval the codeblock, return success or failure, and the error message. This code
protects $@ and $!, they will be restored by the end of the run. This code also
temporarily blocks $SIG{DIE} handlers.

=item protect { ... }

Similar to try, except that it does not catch exceptions. The idea here is to
protect $@ and $! from changes. $@ and $! will be restored to whatever they
were before the run so long as it is successful. If the run fails $! will still
be restored, but $@ will contain the exception being thrown.

=item CAN_FORK

True if this system is capable of true or pseudo-fork.

=item CAN_REALLY_FORK

True if the system can really fork. This will be false for systems where fork
is emulated.

=item CAN_THREAD

True if this system is capable of using threads.

=item USE_THREADS

Returns true if threads are enabled, false if they are not.

=item get_tid

This will return the id of the current thread when threads are enabled,
otherwise it returns 0.

=item my $file = pkg_to_file($package)

Convert a package name to a filename.

=back

=head1 NOTES && CAVEATS

=over 4

=item 5.10.0

Perl 5.10.0 has a bug when compiled with newer gcc versions. This bug causes a
segfault whenever a new thread is launched. Test2 will attempt to detect
this, and note that the system is not capable of forking when it is detected.

=item Devel::Cover

Devel::Cover does not support threads. CAN_THREAD will return false if
Devel::Cover is loaded before the check is first run.

=back

=head1 SOURCE

The source code repository for Test2 can be found at
F<http://github.com/Test-More/test-more/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=item Kent Fredric E<lt>kentnl@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2016 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
