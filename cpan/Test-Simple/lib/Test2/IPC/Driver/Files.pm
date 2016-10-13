package Test2::IPC::Driver::Files;
use strict;
use warnings;

our $VERSION = '1.302059';


BEGIN { require Test2::IPC::Driver; our @ISA = qw(Test2::IPC::Driver) }

use Test2::Util::HashBase qw{tempdir event_id tid pid globals};

use Scalar::Util qw/blessed/;
use File::Temp();
use Storable();
use File::Spec();
use POSIX();

use Test2::Util qw/try get_tid pkg_to_file IS_WIN32/;
use Test2::API qw/test2_ipc_set_pending/;

BEGIN {
    if (IS_WIN32) {
        my $max_tries = 5;

        *do_rename = sub {
            my ($from, $to) = @_;

            my $err;
            for (1 .. $max_tries) {
                return (1) if rename($from, $to);
                $err = "$!";
                last if $_ == $max_tries;
                sleep 1;
            }

            return (0, $err);
        };
        *do_unlink = sub {
            my ($file) = @_;

            my $err;
            for (1 .. $max_tries) {
                return (1) if unlink($file);
                $err = "$!";
                last if $_ == $max_tries;
                sleep 1;
            }

            return (0, "$!");
        };
    }
    else {
        *do_rename = sub {
            my ($from, $to) = @_;
            return (1) if rename($from, $to);
            return (0, "$!");
        };
        *do_unlink = sub {
            my ($file) = @_;
            return (1) if unlink($file);
            return (0, "$!");
        };
    }
}

sub use_shm { 1 }
sub shm_size() { 64 }

sub is_viable { 1 }

sub init {
    my $self = shift;

    my $tmpdir = File::Temp::tempdir(
        $ENV{T2_TEMPDIR_TEMPLATE} || "test2-$$-XXXXXX",
        CLEANUP => 0,
        TMPDIR => 1,
    );

    $self->abort_trace("Could not get a temp dir") unless $tmpdir;

    $self->{+TEMPDIR} = File::Spec->canonpath($tmpdir);

    print STDERR "\nIPC Temp Dir: $tmpdir\n\n"
        if $ENV{T2_KEEP_TEMPDIR};

    $self->{+EVENT_ID} = 1;

    $self->{+TID} = get_tid();
    $self->{+PID} = $$;

    $self->{+GLOBALS} = {};

    return $self;
}

sub hub_file {
    my $self = shift;
    my ($hid) = @_;
    my $tdir = $self->{+TEMPDIR};
    return File::Spec->catfile($tdir, "HUB-$hid");
}

sub event_file {
    my $self = shift;
    my ($hid, $e) = @_;

    my $tempdir = $self->{+TEMPDIR};
    my $type = blessed($e) or $self->abort("'$e' is not a blessed object!");

    $self->abort("'$e' is not an event object!")
        unless $type->isa('Test2::Event');

    my @type = split '::', $type;
    my $name = join('-', $hid, $$, get_tid(), $self->{+EVENT_ID}++, @type);

    return File::Spec->catfile($tempdir, $name);
}

sub add_hub {
    my $self = shift;
    my ($hid) = @_;

    my $hfile = $self->hub_file($hid);

    $self->abort_trace("File for hub '$hid' already exists")
        if -e $hfile;

    open(my $fh, '>', $hfile) or $self->abort_trace("Could not create hub file '$hid': $!");
    print $fh "$$\n" . get_tid() . "\n";
    close($fh);
}

sub drop_hub {
    my $self = shift;
    my ($hid) = @_;

    my $tdir = $self->{+TEMPDIR};
    my $hfile = $self->hub_file($hid);

    $self->abort_trace("File for hub '$hid' does not exist")
        unless -e $hfile;

    open(my $fh, '<', $hfile) or $self->abort_trace("Could not open hub file '$hid': $!");
    my ($pid, $tid) = <$fh>;
    close($fh);

    $self->abort_trace("A hub file can only be closed by the process that started it\nExpected $pid, got $$")
        unless $pid == $$;

    $self->abort_trace("A hub file can only be closed by the thread that started it\nExpected $tid, got " . get_tid())
        unless get_tid() == $tid;

    if ($ENV{T2_KEEP_TEMPDIR}) {
        my ($ok, $err) = do_rename($hfile, File::Spec->canonpath("$hfile.complete"));
        $self->abort_trace("Could not rename file '$hfile' -> '$hfile.complete': $err") unless $ok
    }
    else {
        my ($ok, $err) = do_unlink($hfile);
        $self->abort_trace("Could not remove file for hub '$hid': $err") unless $ok
    }

    opendir(my $dh, $tdir) or $self->abort_trace("Could not open temp dir!");
    for my $file (readdir($dh)) {
        next if $file =~ m{\.complete$};
        next unless $file =~ m{^$hid};
        $self->abort_trace("Not all files from hub '$hid' have been collected!");
    }
    closedir($dh);
}

sub send {
    my $self = shift;
    my ($hid, $e, $global) = @_;

    my $tempdir = $self->{+TEMPDIR};
    my $hfile = $self->hub_file($hid);
    my $dest = $global ? 'GLOBAL' : $hid;

    $self->abort(<<"    EOT") unless $global || -f $hfile;
hub '$hid' is not available, failed to send event!

There was an attempt to send an event to a hub in a parent process or thread,
but that hub appears to be gone. This can happen if you fork, or start a new
thread from inside subtest, and the parent finishes the subtest before the
child returns.

This can also happen if the parent process is done testing before the child
finishes. Test2 normally waits automatically in the root process, but will not
do so if Test::Builder is loaded for legacy reasons.
    EOT

    my $file = $self->event_file($dest, $e);
    my $ready = File::Spec->canonpath("$file.ready");

    if ($global) {
        my $name = $ready;
        $name =~ s{^.*(GLOBAL)}{GLOBAL};
        $self->{+GLOBALS}->{$hid}->{$name}++;
    }

    my ($old, $blocked);
    unless(IS_WIN32) {
        my $to_block = POSIX::SigSet->new(
            POSIX::SIGINT(),
            POSIX::SIGALRM(),
            POSIX::SIGHUP(),
            POSIX::SIGTERM(),
            POSIX::SIGUSR1(),
            POSIX::SIGUSR2(),
        );
        $old = POSIX::SigSet->new;
        $blocked = POSIX::sigprocmask(POSIX::SIG_BLOCK(), $to_block, $old);
        # Silently go on if we failed to log signals, not much we can do.
    }

    # Write and rename the file.
    my ($ok, $err) = try {
        Storable::store($e, $file);
        my ($ok, $err) = do_rename("$file", $ready);
        unless ($ok) {
            POSIX::sigprocmask(POSIX::SIG_SETMASK(), $old, POSIX::SigSet->new()) if defined $blocked;
            $self->abort("Could not rename file '$file' -> '$ready': $err");
        };
        test2_ipc_set_pending(substr($file, -(shm_size)));
    };

    # If our block was successful we want to restore the old mask.
    POSIX::sigprocmask(POSIX::SIG_SETMASK(), $old, POSIX::SigSet->new()) if defined $blocked;

    if (!$ok) {
        my $src_file = __FILE__;
        $err =~ s{ at \Q$src_file\E.*$}{};
        chomp($err);
        my $tid = get_tid();
        my $trace = $e->trace->debug;
        my $type = blessed($e);

        $self->abort(<<"        EOT");

*******************************************************************************
There was an error writing an event:
Destination: $dest
Origin PID:  $$
Origin TID:  $tid
Event Type:  $type
Event Trace: $trace
File Name:   $file
Ready Name:  $ready
Error: $err
*******************************************************************************

        EOT
    }

    return 1;
}

sub cull {
    my $self = shift;
    my ($hid) = @_;

    my $tempdir = $self->{+TEMPDIR};

    opendir(my $dh, $tempdir) or $self->abort("could not open IPC temp dir ($tempdir)!");

    my @out;
    for my $info (sort cmp_events map { $self->should_read_event($hid, $_) } readdir($dh)) {
        my $full = $info->{full_path};
        my $obj = $self->read_event_file($full);
        push @out => $obj;

        # Do not remove global events
        next if $info->{global};

        if ($ENV{T2_KEEP_TEMPDIR}) {
            my $complete = File::Spec->canonpath("$full.complete");
            my ($ok, $err) = do_rename($full, $complete);
            $self->abort("Could not rename IPC file '$full', '$complete': $err") unless $ok;
        }
        else {
            my ($ok, $err) = do_unlink("$full");
            $self->abort("Could not unlink IPC file '$full': $err") unless $ok;
        }
    }

    closedir($dh);
    return @out;
}

sub parse_event_filename {
    my $self = shift;
    my ($file) = @_;

    # The || is to force 0 in false
    my $complete = substr($file, -9, 9) eq '.complete' || 0 and substr($file, -9, 9, "");
    my $ready    = substr($file, -6, 6) eq '.ready'    || 0 and substr($file, -6, 6, "");

    my @parts = split '-', $file;
    my ($global, $hid) = $parts[0] eq 'GLOBAL' ? (1, shift @parts) : (0, join '-' => splice(@parts, 0, 3));
    my ($pid, $tid, $eid) = splice(@parts, 0, 3);
    my $type = join '::' => @parts;

    return {
        ready    => $ready,
        complete => $complete,
        global   => $global,
        type     => $type,
        hid      => $hid,
        pid      => $pid,
        tid      => $tid,
        eid      => $eid,
    };
}

sub should_read_event {
    my $self = shift;
    my ($hid, $file) = @_;

    return if substr($file, 0, 1) eq '.';

    my $parsed = $self->parse_event_filename($file);

    return if $parsed->{complete};
    return unless $parsed->{ready};
    return unless $parsed->{global} || $parsed->{hid} eq $hid;

    return if $parsed->{global} && $self->{+GLOBALS}->{$hid}->{$file}++;

    # Untaint the path.
    my $full = File::Spec->catfile($self->{+TEMPDIR}, $file);
    ($full) = ($full =~ m/^(.*)$/gs) if ${^TAINT};

    $parsed->{full_path} = $full;

    return $parsed;
}

sub cmp_events {
    # Globals first
    return -1 if $a->{global} && !$b->{global};
    return  1 if $b->{global} && !$a->{global};

    return $a->{pid} <=> $b->{pid}
        || $a->{tid} <=> $b->{tid}
        || $a->{eid} <=> $b->{eid};
}

sub read_event_file {
    my $self = shift;
    my ($file) = @_;

    my $obj = Storable::retrieve($file);
    $self->abort("Got an unblessed object: '$obj'")
        unless blessed($obj);

    unless ($obj->isa('Test2::Event')) {
        my $pkg  = blessed($obj);
        my $mod_file = pkg_to_file($pkg);
        my ($ok, $err) = try { require $mod_file };

        $self->abort("Event has unknown type ($pkg), tried to load '$mod_file' but failed: $err")
            unless $ok;

        $self->abort("'$obj' is not a 'Test2::Event' object")
            unless $obj->isa('Test2::Event');
    }

    return $obj;
}

sub waiting {
    my $self = shift;
    require Test2::Event::Waiting;
    $self->send(
        GLOBAL => Test2::Event::Waiting->new(
            trace => Test2::Util::Trace->new(frame => [caller()]),
        ),
        'GLOBAL'
    );
    return;
}

sub DESTROY {
    my $self = shift;

    return unless defined $self->pid;
    return unless defined $self->tid;

    return unless $$        == $self->pid;
    return unless get_tid() == $self->tid;

    my $tempdir = $self->{+TEMPDIR};

    opendir(my $dh, $tempdir) or $self->abort("Could not open temp dir! ($tempdir)");
    while(my $file = readdir($dh)) {
        next if $file =~ m/^\.+$/;
        next if $file =~ m/\.complete$/;
        my $full = File::Spec->catfile($tempdir, $file);

        if ($file =~ m/^(GLOBAL|HUB-)/) {
            $full =~ m/^(.*)$/;
            $full = $1; # Untaint it
            next if $ENV{T2_KEEP_TEMPDIR};
            my ($ok, $err) = do_unlink($full);
            $self->abort("Could not unlink IPC file '$full': $err") unless $ok;
            next;
        }

        $self->abort("Leftover files in the directory ($full)!\n");
    }
    closedir($dh);

    if ($ENV{T2_KEEP_TEMPDIR}) {
        print STDERR "# Not removing temp dir: $tempdir\n";
        return;
    }

    rmdir($tempdir) or warn "Could not remove IPC temp dir ($tempdir)";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::IPC::Driver::Files - Temp dir + Files concurrency model.

=head1 DESCRIPTION

This is the default, and fallback concurrency model for L<Test2>. This
sends events between processes and threads using serialized files in a
temporary directory. This is not particularly fast, but it works everywhere.

=head1 SYNOPSIS

    use Test2::IPC::Driver::Files;

    # IPC is now enabled

=head1 ENVIRONMENT VARIABLES

=over 4

=item T2_KEEP_TEMPDIR=0

When true, the tempdir used by the IPC driver will not be deleted when the test
is done.

=item T2_TEMPDIR_TEMPLATE='test2-XXXXXX'

This can be used to set the template for the IPC temp dir. The template should
follow template specifications from L<File::Temp>.

=back

=head1 SEE ALSO

See L<Test2::IPC::Driver> for methods.

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

=back

=head1 COPYRIGHT

Copyright 2016 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
