package Test::PerlRun;

use strict;
use warnings;

use File::Spec;
use Test::Builder;
use File::Temp;
use POSIX qw(_exit :sys_wait_h);
use Config;

use base 'Exporter';

our $VERSION = '0.01';

our @EXPORT = qw(
    perlrun_exit_status_is
    perlrun_stdout_is
    perlrun_stdout_like
    perlrun_stderr_is
    perlrun_stderr_like
);

our @EXPORT_OK = 'perlrun';

our %EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ] );

my $TB = Test::Builder->new();

sub perlrun_exit_status_is {
    my $status = ( _run(shift) )[2];

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $TB->is_eq( $status, @_ );
}

sub perlrun_stdout_is {
    my ( $stdout ) = _run(shift);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $TB->is_eq( $stdout, @_ );
}

sub perlrun_stdout_like {
    my ( $stdout ) = _run(shift);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $TB->like( $stdout, @_ );
}

sub perlrun_stderr_is {
    my ( undef, $stderr ) = _run(shift, 1);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $TB->is_eq( $stderr, @_ );
}

sub perlrun_stderr_like {
    my ( undef, $stderr ) = _run(shift, 1);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $TB->like( $stderr, @_ );
}

sub perlrun {
    return _run(shift, 1) if @_ == 1;
    require Carp;
    Carp::croak('Too many arguments for perlrun');
}

{
    my $is_mswin      = $^O eq 'MSWin32';
    my $is_vms        = $^O eq 'VMS';
    my $is_cygwin     = $^O eq 'cygwin';
    my $use_backticks = $is_mswin;

    sub _forcibly_untaint {
        my $sub = shift;
        return &$sub(@_) unless ${^TAINT};

        # We will assume that if you're running under -T, you really mean to
        # run a fresh perl, so we'll brute force launder everything for you
        my $sep = $Config{path_sep};

        my @keys = grep {exists $ENV{$_}} qw(CDPATH IFS ENV BASH_ENV);
        local @ENV{@keys} = ();
        # Untaint, plus take out . and empty string:
        local $ENV{'DCL$PATH'} = $1
            if $is_vms && exists($ENV{'DCL$PATH'}) && ($ENV{'DCL$PATH'} =~ /(.*)/s);
        $ENV{PATH} =~ /(.*)/s;
        local $ENV{PATH} =
            join $sep, grep { $_ ne "" and $_ ne "." and -d $_ and
                                  ($is_mswin or $is_vms or !(stat && (stat _)[2]&0022)) }
                split quotemeta ($sep), $1;
        if ($is_cygwin) {   # Must have /bin under Cygwin
            if (length $ENV{PATH}) {
                $ENV{PATH} = $ENV{PATH} . $sep;
            }
            $ENV{PATH} = $ENV{PATH} . '/bin';
        }
        return &$sub(map {/(.*)/s; $1} @_);
    }

    sub _run {
        my $p = ref $_[0] ? shift : { stdin => shift, file => '-' };
        my $capture_stderr = shift;

        die "You cannot run a command without some Perl code to execute"
            unless grep { defined $p->{$_} && length $p->{$_} } qw( code file );

        my @args
            = defined $p->{switches} && !ref $p->{switches}
                ? $p->{switches}
                    : @{ $p->{switches} || [] };

        if ( exists $p->{code} ) {
            push @args, '-e', ($use_backticks ? qq{"$p->{code}"} : $p->{code});
        }
        else {
            push @args, $p->{file};
        }
        push @args, @{$p->{args}} if $p->{args};
        my $perl = _which_perl();

        my $err_file;
        if ($capture_stderr) {
            $err_file = File::Temp->new();
            $err_file->close();
            # else mandatory locking on some "helpful" OSes bites us
        }
        my ($stdout, $stderr);

        local $/;
        if ($use_backticks) {
            $perl = qq{"$perl"} if $perl =~ /\s/;
            my $stdin;
            if (exists $p->{stdin}) {
                $stdin = File::Temp->new();
                $stdin->print($p->{stdin}) && $stdin->close()
                    or die "Can't write data for stdin to $stdin: $!";
                unshift @args, "<$stdin";
            }
            push @args, "2>$err_file" if $err_file;
            $stdout = _forcibly_untaint(sub {`@_`}, $perl, @args);
        } else {
            my $fh;
            if ($capture_stderr || exists $p->{stdin}) {
                my $pid = open $fh, '-|';
                die "Can't fork by opening -|" unless defined $pid;
                if ($pid == 0) {
                    # We are in the child

                    if (exists $p->{stdin}) {
                        # Spawn a grandchild to provide the contents of stdin.
                        # As easy as a tempfile, and no files to fail to clean
                        $pid = open STDIN, '-|';
                        die "Can't fork by opening -|" unless defined $pid;
                        if ($pid == 0) {
                            # We are in the grandchild
                            print $p->{stdin};
                            close STDOUT;
                            _exit(0);
                        }
                    }

                    if ($capture_stderr) {
                        open STDERR, '>&=', $err_file
                            or die "Can't redirect STDERR: $!";
                    }

                    _forcibly_untaint(sub {
                                          exec @_;
                                          die "exec failed: $!";
                                      }, $perl, @args);

                }
            } else {
                _forcibly_untaint(sub {
                                      open $fh, '-|', @_
                                          or die "Can't open @_: $!";
                                  }, $perl, @args);
            }
            $stdout = <$fh>;
            $! = 0;
            if (!close $fh && $!) {
                die "Can't close $perl @args: $!";
            }
        }

        if ($capture_stderr) {
            open my $fh, '<', $err_file->filename()
                or die "Can't reopen $err_file: $!";
            $stderr = <$fh>;
        }
        my ($status, $signalled);
        if (!defined eval {
            my $raw = defined ${^CHILD_ERROR_NATIVE} ? ${^CHILD_ERROR_NATIVE} : $?;
            if (WIFEXITED($raw)) {
                $status = WEXITSTATUS($raw);
            } elsif (WIFSIGNALED($raw)) {
                $signalled = WTERMSIG($raw);
            }
            1; # We get here if macros are present on this OS
        }) {
            # Assume the conventional values.
            if ($? & 127) {
                $signalled = $? & 127;
            } else {
                $status = $? >> 8;
            }
        }

        return ($stdout, $stderr, $status, $signalled);
    }

    my $Perl;

    # Code stolen from t/test.pl - simplified because we can safely load other
    # modules.
    #
    # A somewhat safer version of the sometimes wrong $^X.
    sub _which_perl {
        return $Perl if defined $Perl;

        $Perl = $^X;

        # VMS should have 'perl' aliased properly
        return $Perl if $is_vms;

        my $exe = defined $Config{_exe} ? $Config{_exe} : q{};

        # This doesn't absolutize the path: beware of future chdirs().
        # We could do File::Spec->abs2rel() but that does getcwd()s,
        # which is a bit heavyweight to do here.

        if ( $Perl =~ /^perl\Q$exe\E$/i ) {
            my $perl = "perl$exe";
            $Perl = File::Spec->catfile( File::Spec->curdir(), $perl );
        }

        # Build up the name of the executable file from the name of
        # the command.
        if ( $Perl !~ /\Q$exe\E$/i ) {
            $Perl = $Perl . $exe;
        }

        warn "which_perl: cannot find $Perl from $^X" unless -f $Perl;

        # For subcommands to use.
        $ENV{PERLEXE} = $Perl;

        return $Perl;
    }
}

1;

__END__

=head1 NAME

Test::PerlRun - run perl and test the exit status or output

=head1 SYNOPSIS

  use Test::More;
  use Test::PerlRun;

  perlrun_exit_status_is( 'exit 42', 42, 'code exited with status == 42' );

  perlrun_stdout_is( q[print 'hello'], 'hello', 'code printed hello' );

  perlrun_stdout_like(
      { file => '/path/to/code' },
      'hello',
      'code printed hello'
  );

  perlrun_stderr_like(
      {
          code     => q[warn 'TAINT' if ${^TAINT}],
          switches => '-T',
      },
      'hello',
      'code printed hello'
  );

=head1 DESCRIPTION

This module provides a thin test wrapper for testing the execution of some
Perl code in a separate process. It was adapted from code in the Perl core's
F<t/test.pl> file, and is primarily intended for testing modules that are
shipped with the Perl core.

If you are writing tests for code outside the Perl core, you should first look
at L<Test::Command>, L<Test::Script>, or L<Test::Script::Run>.

=head1 FUNCTIONS

All the functions that this module provides accept the same first
argument. This can be either a scalar containing Perl code to run, or a hash
reference.

If you pass a scalar, the contents are passed as STDIN of the spawned F<perl>.
If you pass a hash reference, you can use the following keys:

=over 4

=item * code

This should be a string of code to run. It is passed to the spawned F<perl> on
its command line using C<-e>, so avoid newlines and double quotes in the
string if you need to be portable to Win32

=item * file

A file containing Perl code to execute. You cannot pass both C<code> and
C<file> parameters.

=item * switches

This can either be a scalar or an array reference of scalars. Each scalar
should be a switch that will be passed to the F<perl> command, like C<-T> or
C<-C>.

=item * stdin

Data to feed to stdin of the spawned process. By declaring a I<file> of C<->
and using I<stdin> you can execute complex code without needing to create a
temporary file.

=item * args

A reference to an array of arguments to pass to the spawned program.

=back

You can import all the functions this module exports with the C<:all> import
tag.

This module provides the following functions:

=head2 perlrun_exit_status_is( $code, $status, $description )

This function runs the specified code and checks if the exit status matches
the status you provide.

This function is exported by default.

=head2 perlrun_stdout_is( $code, $output, $description )

This function runs the specified code and checks if the output sent to
C<stdout> matches the output you expect.

This function is exported by default.

=head2 perlrun_stdout_like( $code, $output_regex, $description )

This function runs the specified code and checks if the output sent to
C<stdout> matches the output regex you expect.

This function is exported by default.

=head2 perlrun_stderr_is( $code, $output, $description )

This function runs the specified code and checks if the output sent to
C<stderr> matches the output you expect.

This function is exported by default.

=head2 perlrun_stderr_like( $code, $output_regex, $description )

This function runs the specified code and checks if the output sent to
C<stderr> matches the output regex you expect.

This function is exported by default.

=head2 perlrun($code)

This function runs the specified code. It returns a four element list. The
first item is the output sent to C<stdout>, the second is the output to
C<stderr>, the third is the exit status for the Perl process that was run
(or undef if it caught a signal), and the final is undef for a normal exit,
or the numeric value of the signal that terminated the process.

This function does not actually run a test.

This function is exported only by request.

=head1 PERLEXE ENVIRONMENT VARIABLE

When this module runs code, it sets the C<$ENV{PERLEXE}> variable. This
contains the path to the perl executable that is running the code.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

Some of the code in this module was taken from F<t/test.pl> in the core Perl
distribution.

=head1 LICENSE

Copyright (c) 2011 Dave Rolsky, Michael Schwern, Jarkko Hietaaniemi, Craig
Berry, Paul Green, and Nicholas Clark. All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
