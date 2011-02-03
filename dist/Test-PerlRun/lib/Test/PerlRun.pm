package Test::PerlRun;

use strict;
use warnings;

use File::Spec;
use IPC::Cmd qw( run );
use Test::Builder;

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
    my $error = ( _run(shift) )[2];

    my $status = _status($error);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $TB->is_eq( $status, @_ );
}

sub _status {
    my $error = shift;

    return 0 unless defined $error;

    # This is a hack, but unfortunately IPC::Cmd local-izes $? so we cannot
    # check that directly.
    my ($status) = $error =~ /exited with value (\d+)/;

    return $status || 0;
}

sub perlrun_stdout_is {
    my ( $stdout, $stderr ) = _run(shift);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $TB->is_eq( $stdout, @_ );
}

sub perlrun_stdout_like {
    my ( $stdout, $stderr ) = _run(shift);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $TB->like( $stdout, @_ );
}

sub perlrun_stderr_is {
    my ( $stdout, $stderr ) = _run(shift);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $TB->is_eq( $stderr, @_ );
}

sub perlrun_stderr_like {
    my ( $stdout, $stderr ) = _run(shift);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $TB->like( $stderr, @_ );
}

sub perlrun {
    my ( $stdout, $stderr, $error ) = _run(shift);

    return ( $stdout, $stderr, _status($error) );
}

sub _run {
    my $p = ref $_[0] ? shift : { code => shift };

    die "You cannot run a command without some Perl code to execute"
        unless grep { defined $p->{$_} && length $p->{$_} } qw( code file );

    my @args
        = defined $p->{switches} && !ref $p->{switches}
        ? $p->{switches}
        : @{ $p->{switches} || [] };

    if ( exists $p->{code} ) {
        push @args, '-e', $p->{code};
    }
    else {
        push @args, $p->{file};
    }
    my $perl = _which_perl();

    my ( $ok, $err, undef, $stdout, $stderr ) = run(
        command => [ _which_perl(), @args, ],
    );

    return (
        ( join q{}, @{$stdout} ),
        ( join q{}, @{$stderr} ),
        $err
    );
}

{
    my $IsVMS = $^O eq 'VMS';

    my $Perl;

    # Code stolen from t/test.pl - simplified because we can safely load other
    # modules.
    #
    # A somewhat safer version of the sometimes wrong $^X.
    sub _which_perl {
        return $Perl if defined $Perl;

        $Perl = $^X;

        # VMS should have 'perl' aliased properly
        return $Perl if $IsVMS;

        require Config;

        my $exe = defined $Config::Config{_exe} ? $Config::Config{_exe} : q{};

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

If you pass a hash reference, you can use the following keys:

=over 4

=item * code

This should be a string of code to run.

=item * file

A file containing Perl code to execute. You cannot pass both C<code> and
C<file> parameters.

=item * switches

This can either be a scalar or an array reference of scalars. Each scalar
should be a switch that will be passed to the F<perl> command, like C<-T> or
C<-C>.

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

This function runs the specified code. It returns a three element list. The
first item is the output sent to C<stdout>, the second is the output to
C<stderr>, and the final element is the exit status for the Perl process that
was run.

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
