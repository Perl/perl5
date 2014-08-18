package Test::Builder::Fork;
use strict;
use warnings;

use Carp qw/confess/;
use Scalar::Util qw/blessed/;
use File::Temp();
use Test::Builder::Util qw/try/;

sub tmpdir { shift->{tmpdir} }
sub pid    { shift->{pid}    }

sub new {
    my $class = shift;

    my $dir = File::Temp::tempdir(CLEANUP => 0) || die "Could not get a temp dir";

    my $self = bless { tmpdir => $dir, pid => $$ }, $class;

    return $self;
}

my $id = 1;
sub handle {
    my $self = shift;
    my ($item) = @_;

    return if $item && blessed($item) && $item->isa('Test::Builder::Event::Finish');

    confess "Did not get a valid Test::Builder::Event object! ($item)"
        unless $item && blessed($item) && $item->isa('Test::Builder::Event');

    my $stream = Test::Builder::Stream->shared;
    return 0 if $$ == $stream->pid;

    # First write the file, then rename it so that it is not read before it is ready.
    my $name =  $self->tmpdir . "/$$-" . $id++;
    require Storable;
    Storable::store($item, $name);
    rename($name, "$name.ready") || die "Could not rename file";

    return 1;
}

sub cull {
    my $self = shift;
    my $dir = $self->tmpdir;

    opendir(my $dh, $dir) || die "could not open temp dir!";
    while(my $file = readdir($dh)) {
        next if $file =~ m/^\.+$/;
        next unless $file =~ m/\.ready$/;

        require Storable;
        my $obj = Storable::retrieve("$dir/$file");
        die "Empty event object found" unless $obj;

        Test::Builder::Stream->shared->send($obj);

        if ($ENV{TEST_KEEP_TMP_DIR}) {
            rename("$dir/$file", "$dir/$file.complete") || die "Could not rename file";
        }
        else {
            unlink("$dir/$file") || die "Could not unlink file: $file";
        }
    }
    closedir($dh);
}

sub DESTROY {
    my $self = shift;

    return unless $$ == $self->pid;

    my $dir = $self->tmpdir;

    if ($ENV{TEST_KEEP_TMP_DIR}) {
        print STDERR "# Not removing temp dir: $dir\n";
        return;
    }

    opendir(my $dh, $dir) || die "Could not open temp dir!";
    while(my $file = readdir($dh)) {
        next if $file =~ m/^\.+$/;
        die "Unculled event! You ran tests in a child process, but never pulled them in!\n"
            if $file !~ m/\.complete$/;
        unlink("$dir/$file") || die "Could not unlink file: $file";
    }
    closedir($dh);
    rmdir($dir);
}

1;

__END__

=head1 NAME

Test::Builder::Fork - Fork support for Test::Builder

=head1 DESCRIPTION

This module is used by L<Test::Builder::Stream> to support forking.

=head1 SYNOPSYS

    use Test::Builder::Fork;

    my $f = Test::Builder::Fork;

    if ($pid = fork) {
        waitpid($pid, 0);
        $f->cull;
    }
    else {
        $f->handle(Test::Builder::Event::Ok->new(bool => 1);
    }

    ...

=head1 METHODS

=over 4

=item $f = $class->new

Create a new instance

=item $f->pid

Original PID in which the fork object was created.

=item $f->tmpdir

Temp dir used to share events between procs

=item $f->handle($event)

Send a event object to the parent

=item $f->cull

Retrieve event objects and send them to the stream

=back

=head1 SEE ALSO

L<Child> - Makes forking easier.

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 SOURCE

The source code repository for Test::More can be found at
F<http://github.com/Test-More/test-more/>.

=head1 COPYRIGHT

Copyright 2014 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>
