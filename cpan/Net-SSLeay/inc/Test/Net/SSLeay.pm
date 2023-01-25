package Test::Net::SSLeay;

use 5.008001;
use strict;
use warnings;
use base qw(Exporter);

use Carp qw(croak);
use Config;
use Cwd qw(abs_path);
use English qw( $EVAL_ERROR $OSNAME $PERL_VERSION -no_match_vars );
use File::Basename qw(dirname);
use File::Spec::Functions qw( abs2rel catfile );
use Test::Builder;
use Test::Net::SSLeay::Socket;

our $VERSION = '1.92';

our @EXPORT_OK = qw(
    can_fork can_really_fork can_thread
    data_file_path
    dies_like
    dies_ok
    doesnt_warn
    initialise_libssl
    is_libressl is_openssl
    is_protocol_usable
    lives_ok
    new_ctx
    protocols
    tcp_socket
    warns_like
);

my $tester = Test::Builder->new();

my $data_path = catfile( dirname(__FILE__), '..', '..', '..', 't', 'data' );

my $initialised = 0;

my %protos = (
    'TLSv1.3' => {
        constant      => \&Net::SSLeay::TLS1_3_VERSION,
        constant_type => 'version',
        priority      => 6,
    },
    'TLSv1.2' => {
        constant      => \&Net::SSLeay::TLSv1_2_method,
        constant_type => 'method',
        priority      => 5,
    },
    'TLSv1.1' => {
        constant      => \&Net::SSLeay::TLSv1_1_method,
        constant_type => 'method',
        priority      => 4,
    },
    'TLSv1' => {
        constant      => \&Net::SSLeay::TLSv1_method,
        constant_type => 'method',
        priority      => 3,
    },
    'SSLv3' => {
        constant      => \&Net::SSLeay::SSLv3_method,
        constant_type => 'method',
        priority      => 2,
    },
    'SSLv2' => {
        constant      => \&Net::SSLeay::SSLv2_method,
        constant_type => 'method',
        priority      => 1,
    },
);

my ( $test_no_warnings, $test_no_warnings_name, @warnings );

END {
    _test_no_warnings() if $test_no_warnings;
}

sub _all {
    my ( $sub, @list ) = @_;

    for (@list) {
        $sub->() or return 0;
    }

    return 1;
}

sub _diag {
    my (%args) = @_;

    $tester->diag( ' ' x 9, 'got: ', $args{got} );
    $tester->diag( ' ' x 4, 'expected: ', $args{expected} );
}

sub _libssl_fatal {
    my ($context) = @_;

    croak "$context: "
        . Net::SSLeay::ERR_error_string( Net::SSLeay::ERR_get_error() );
}

sub _load_net_ssleay {
    eval { require Net::SSLeay; 1; } or croak $EVAL_ERROR;

    return 1;
}

sub _test_no_warnings {
    my $got_str = join q{, }, map { qq{'$_'} } @warnings;
    my $got_type = @warnings == 1 ? 'warning' : 'warnings';

    $tester->ok( @warnings == 0, $test_no_warnings_name )
        or _diag(
            got      => "$got_type $got_str",
            expected => 'no warnings',
        );
}

sub import {
    my ( $class, @imports ) = @_;

    # Enable strict and warnings in the caller
    strict->import;
    warnings->import;

    # Import common modules into the caller's namespace
    my $caller = caller;
    for (qw(Test::More)) {
        eval "package $caller; use $_; 1;" or croak $EVAL_ERROR;
    }

    # Import requested Test::Net::SSLeay symbols into the caller's namespace
    __PACKAGE__->export_to_level( 1, $class, @imports );

    return 1;
}

sub can_fork {
    return 1 if can_really_fork();

    # Some platforms provide fork emulation using ithreads
    return 1 if $Config{d_pseudofork};

    # d_pseudofork was added in Perl 5.10.0 - this is an approximation for
    # older Perls
    if (    ( $OSNAME eq 'Win32' or $OSNAME eq 'NetWare' )
        and $Config{useithreads}
        and $Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/ )
    {
        return 1;
    }

    return can_thread();
}

sub can_really_fork {
    return 1 if $Config{d_fork};

    return 0;
}

sub can_thread {
    return 0 if not $Config{useithreads};

    # Threads are broken in Perl 5.10.0 when compiled with GCC 4.8 or above
    # (see GH #175)
    if (    $PERL_VERSION == 5.010000
        and $Config{ccname} eq 'gcc'
        and defined $Config{gccversion}
        # gccversion is sometimes defined for non-GCC compilers (see GH-350);
        # compilers that are truly GCC are identified with a version number in
        # gccversion
        and $Config{gccversion} =~ /^\d+\.\d+/ )
    {
        my ( $gcc_major, $gcc_minor ) = split /[.\s]+/, $Config{gccversion};

        return 0
            if ( $gcc_major > 4 or ( $gcc_major == 4 and $gcc_minor >= 8 ) );
    }

    # Devel::Cover doesn't (currently) work with threads
    return 0 if $INC{'Devel/Cover.pm'};

    return 1;
}

sub data_file_path {
    my ($data_file) = @_;

    my $abs_path = catfile( abs_path($data_path), $data_file );
    my $rel_path = abs2rel($abs_path);

    croak "$rel_path: data file does not exist"
        if not -e $abs_path;

    return $rel_path;
}

sub dies_like {
    my ( $sub, $expected, $name ) = @_;

    my ( $got, $ok );

    if ( eval { $sub->(); 1 } ) {
        $ok = $tester->ok ( 0, $name );

        _diag(
            got      => 'subroutine lived',
            expected => "subroutine died with exception matching $expected",
        );
    }
    else {
        $got = $EVAL_ERROR;

        my $test = $got =~ $expected;

        $ok = $tester->ok( $test, $name )
            or _diag(
                got      => qq{subroutine died with exception '$got'},
                expected => "subroutine died with exception matching $expected",
            );
    }

    $EVAL_ERROR = $got;

    return $ok;
}

sub dies_ok {
    my ( $sub, $name ) = @_;

    my ( $got, $ok );

    if ( eval { $sub->(); 1 } ) {
        $got = $EVAL_ERROR;

        $ok = $tester->ok ( 0, $name );

        _diag(
            got      => 'subroutine lived',
            expected => 'subroutine died',
        );
    }
    else {
        $got = $EVAL_ERROR;

        $ok = $tester->ok( 1, $name );
    }

    $EVAL_ERROR = $got;

    return $ok;
}

sub doesnt_warn {
    $test_no_warnings      = 1;
    $test_no_warnings_name = shift;

    $SIG{__WARN__} = sub { push @warnings, shift };
}

sub initialise_libssl {
    return 1 if $initialised;

    _load_net_ssleay();

    Net::SSLeay::randomize();

    # Error strings aren't loaded by default until OpenSSL 1.1.0, but it's safe
    # to load them unconditionally because these functions are simply no-ops in
    # later OpenSSL versions
    Net::SSLeay::load_error_strings();
    Net::SSLeay::ERR_load_crypto_strings();

    Net::SSLeay::library_init();

    # The test suite makes heavy use of SHA-256, but SHA-256 isn't registered by
    # default in all OpenSSL versions - register it manually when Net::SSLeay is
    # built against the following OpenSSL versions:

    # OpenSSL 0.9.8 series < 0.9.8o
    Net::SSLeay::OpenSSL_add_all_digests()
        if Net::SSLeay::constant('OPENSSL_VERSION_NUMBER') < 0x009080ff;

    # OpenSSL 1.0.0 series < 1.0.0a
    Net::SSLeay::OpenSSL_add_all_digests()
        if    Net::SSLeay::constant('OPENSSL_VERSION_NUMBER') >= 0x10000000
           && Net::SSLeay::constant('OPENSSL_VERSION_NUMBER') < 0x1000001f;

    $initialised = 1;

    return 1;
}

sub is_libressl {
    _load_net_ssleay();

    # The most foolproof method of checking whether libssl is provided by
    # LibreSSL is by checking OPENSSL_VERSION_NUMBER: every version of
    # LibreSSL identifies itself as OpenSSL 2.0.0, which is a version number
    # that OpenSSL itself will never use (version 3.0.0 follows 1.1.1)
    return 0
        if Net::SSLeay::constant('OPENSSL_VERSION_NUMBER') != 0x20000000;

    return 1;
}

sub is_openssl {
    _load_net_ssleay();

    # "OpenSSL 2.0.0" is actually LibreSSL
    return 0
        if Net::SSLeay::constant('OPENSSL_VERSION_NUMBER') == 0x20000000;

    return 1;
}

sub is_protocol_usable {
    my ($proto) = @_;

    _load_net_ssleay();
    initialise_libssl();

    my $proto_data = $protos{$proto};

    # If libssl does not support this protocol version, or if it was disabled at
    # compile-time, the appropriate method for that version will be missing
    if (
          $proto_data->{constant_type} eq 'version'
        ? !eval { &{ $proto_data->{constant} }; 1 }
        : !defined &{ $proto_data->{constant} }
    ) {
        return 0;
    }

    # If libssl was built with support for this protocol version, the only
    # reliable way to test whether its use is permitted by the security policy
    # is to attempt to create a connection that uses it - if it is permitted,
    # the state machine enters the following states:
    #
    #   SSL_CB_HANDSHAKE_START (ret=1)
    #   SSL_CB_CONNECT_LOOP    (ret=1)
    #   SSL_CB_CONNECT_EXIT    (ret=-1)
    #
    # If it is not permitted, the state machine instead enters the following
    # states:
    #
    #   SSL_CB_HANDSHAKE_START (ret=1)
    #   SSL_CB_CONNECT_EXIT    (ret=-1)
    #
    # Additionally, ERR_get_error() returns the error code 0x14161044, although
    # this might not necessarily be guaranteed for all libssl versions, so
    # testing for it may be unreliable

    my $constant = $proto_data->{constant}->();
    my $ctx;

    if ( $proto_data->{constant_type} eq 'version' ) {
        $ctx = Net::SSLeay::CTX_new_with_method( Net::SSLeay::TLS_method() )
            or _libssl_fatal('Failed to create libssl SSL_CTX object');

        Net::SSLeay::CTX_set_min_proto_version( $ctx, $constant );
        Net::SSLeay::CTX_set_max_proto_version( $ctx, $constant );
    }
    else {
        $ctx = Net::SSLeay::CTX_new_with_method($constant)
            or _libssl_fatal('Failed to create SSL_CTX object');
    }

    my $ssl = Net::SSLeay::new($ctx)
        or _libssl_fatal('Failed to create SSL structure');

    # For the purposes of this test, it isn't necessary to link the SSL
    # structure to a file descriptor, since no data actually needs to be sent or
    # received
    Net::SSLeay::set_fd( $ssl, -1 )
        or _libssl_fatal('Failed to set file descriptor for SSL structure');

    my @states;

    Net::SSLeay::CTX_set_info_callback(
        $ctx,
        sub {
            my ( $ssl, $where, $ret, $data ) = @_;

            push @states, $where;
        }
    );

    Net::SSLeay::connect($ssl)
        or _libssl_fatal('Failed to initiate connection');

    my $disabled =   Net::SSLeay::CB_HANDSHAKE_START()
                   + Net::SSLeay::CB_CONNECT_EXIT();

    my $enabled =   Net::SSLeay::CB_HANDSHAKE_START()
                  + Net::SSLeay::CB_CONNECT_LOOP()
                  + Net::SSLeay::CB_CONNECT_EXIT();

    Net::SSLeay::free($ssl);
    Net::SSLeay::CTX_free($ctx);

    my $observed = 0;
    for my $state (@states) {
        $observed += $state;
    }

    return 0 if $observed == $disabled;
    return 1 if $observed == $enabled;

    croak 'Unexpected TLS state machine sequence: ' . join( ', ', @states );
}

sub lives_ok {
    my ( $sub, $name ) = @_;

    my ( $got, $ok );

    if ( !eval { $sub->(); 1 } ) {
        $got = $EVAL_ERROR;

        $ok = $tester->ok ( 0, $name );

        _diag(
            got      => qq{subroutine died with exception '$got'},
            expected => 'subroutine lived',
        );
    }
    else {
        $got = $EVAL_ERROR;

        $ok = $tester->ok( 1, $name );
    }

    $EVAL_ERROR = $got;

    return $ok;
}

sub new_ctx {
    my ( $min_proto, $max_proto ) = @_;

    my @usable_protos =
        # Exclude protocol versions not supported by this libssl:
        grep {
            is_protocol_usable($_)
        }
        # Exclude protocol versions outside the desired range:
        grep {
               (
                     defined $min_proto
                   ? $protos{$_}->{priority} >= $protos{$min_proto}->{priority}
                   : 1
               )
            && (
                     defined $max_proto
                   ? $protos{$_}->{priority} <= $protos{$max_proto}->{priority}
                   : 1
               )
        }
        protocols();

    croak 'Failed to create libssl SSL_CTX object: no usable protocol versions'
        if !@usable_protos;

    my $proto    = shift @usable_protos;
    my $constant = $protos{$proto}->{constant}->();
    my $ctx;

    if ( $protos{$proto}->{constant_type} eq 'version' ) {
        $ctx = Net::SSLeay::CTX_new_with_method( Net::SSLeay::TLS_method() )
            or _libssl_fatal('Failed to create libssl SSL_CTX object');

        Net::SSLeay::CTX_set_min_proto_version( $ctx, $constant );
        Net::SSLeay::CTX_set_max_proto_version( $ctx, $constant );
    }
    else {
        $ctx = Net::SSLeay::CTX_new_with_method($constant)
            or _libssl_fatal('Failed to create SSL_CTX object');
    }

    return wantarray ? ( $ctx, $proto )
                     : $ctx;
}

sub protocols {
    return
        sort {
            $protos{$b}->{priority} <=> $protos{$a}->{priority}
        }
        keys %protos;
}

sub tcp_socket {
    return Test::Net::SSLeay::Socket->new( proto => 'tcp' );
}

sub warns_like {
    my ( $sub, $expected, $name ) = @_;

    my @expected =   ref $expected eq 'ARRAY'
                   ? @$expected
                   : ($expected);

    my @got;

    local $SIG{__WARN__} = sub { push @got, shift };

    $sub->();

    $SIG{__WARN__} = 'DEFAULT';

    my $test =    scalar @got == scalar @expected
               && _all( sub { $got[$_] =~ $expected[$_] }, 0 .. $#got );

    my $ok = $tester->ok( $test, $name )
        or do {
            my $got_str      = join q{, }, map { qq{'$_'} } @got;
            my $expected_str = join q{, }, map { qq{'$_'} } @expected;

            my $got_plural      = @got == 1 ? '' : 's';
            my $expected_plural = @expected == 1 ? '' : 's';

            _diag(
                got      => "warning$got_plural $got_str",
                expected => "warning$expected_plural matching $expected_str",
            );
        };

    return $ok;
}

1;

__END__

=head1 NAME

Test::Net::SSLeay - Helper module for the Net-SSLeay test suite

=head1 VERSION

This document describes version 1.92 of Test::Net::SSLeay.

=head1 SYNOPSIS

In a Net-SSLeay test script:

    # Optional summary of the purpose of the tests in this script

    use lib 'inc';

    use Net::SSLeay;                              # if required by the tests
    use Test::Net::SSLeay qw(initialise_libssl);  # import other helper
                                                  # functions if required

    # Imports of other modules specific to this test script

    # Plan tests, or skip them altogether if certain preconditions aren't met
    if (disqualifying_condition) {
        plan skip_all => ...;
    } else {
        plan tests => ...;
    }

    # If this script tests Net::SSLeay functionality:
    initialise_libssl();

    # Perform one or more Test::More-based tests

=head1 DESCRIPTION

This is a helper module that makes it easier (or, at least, less repetitive)
to write test scripts for the Net-SSLeay test suite. For consistency, all test
scripts should import this module and follow the preamble structure given in
L</SYNOPSIS>.

Importing this module has the following effects on the caller, regardless of
whether any exports are requested:

=over 4

=item *

C<strict> and C<warnings> are enabled;

=item *

L<Test::More|Test::More>, the test framework used by the Net-SSLeay test
suite, is imported.

=back

No symbols are exported by default. If desired, individual helper functions
may be imported into the caller's namespace by specifying their name in the
import list; see L</"HELPER FUNCTIONS"> for a list of available helper
functions.

=head1 HELPER FUNCTIONS

=head2 can_fork

    if (can_fork()) {
        # Run tests that rely on a working fork() implementation
    }

Returns true if this system natively supports the C<fork()> system call, or if
Perl can emulate C<fork()> on this system using interpreter-level threads.
Otherwise, returns false.

=head2 can_really_fork

    if (can_really_fork()) {
        # Run tests that rely on a native fork() implementation
    }

Returns true if this system natively supports the C<fork()> system call, or
false if not.

=head2 can_thread

    if (can_thread()) {
        # Run tests that rely on working threads support
    }

Returns true if reliable interpreter-level threads support is available in
this Perl, or false if not.

=head2 data_file_path

    my $cert_path = data_file_path('wildcard-cert.cert.pem');
    my $key_path  = data_file_path('wildcard-cert.key.pem');

Returns the relative path to a given file in the test suite data directory
(C<t/local/>). Dies if the file does not exist.

=head2 dies_like

    dies_like(
        sub { die 'This subroutine always dies' },
        qr/always/,
        'A test that always passes'
    );

Similar to L<C<throws_ok> in Test::Exception|Test::Exception/throws_ok>:
performs a L<Test::Builder> test that passes if a given subroutine dies with an
exception string that matches a given pattern, or fails if the subroutine does
not die or dies with an exception string that does not match the given pattern.

This function preserves the value of C<$@> set by the given subroutine, so (for
example) other tests can be performed on the value of C<$@> afterwards.

=head2 dies_ok

    dies_ok(
        sub { my $x = 1 },
        'A test that always fails'
    );

Similar to L<C<dies_ok> in Test::Exception|Test::Exception/dies_ok>: performs a
L<Test::Builder> test that passes if a given subroutine dies, or fails if it
does not.

This function preserves the value of C<$@> set by the given subroutine, so (for
example) other tests can be performed on the value of C<$@> afterwards.

=head2 doesnt_warn

    doesnt_warn('Test script outputs no unexpected warnings');

Offers similar functionality to L<Test::NoWarnings>: performs a L<Test::Builder>
test at the end of the test script that passes if the test script executes from
this point onwards without emitting any unexpected warnings, or fails if
warnings are emitted before the test script ends.

Warnings omitted by subroutines that are executed as part of a L</warns_like>
test are not considered to be unexpected (even if the L</warns_like> test
fails), and will therefore not cause this test to fail.

=head2 initialise_libssl

    initialise_libssl();

    # Run tests that call Net::SSLeay functions

Initialises libssl (and libcrypto) by seeding the pseudorandom number generator,
loading error strings, and registering the default TLS ciphers and digest
functions. All digest functions are explicitly registered when Net::SSLeay is
built against a libssl version that does not register SHA-256 by default, since
SHA-256 is used heavily in the test suite PKI.

libssl will only be initialised the first time this function is called, so it is
safe for it to be called multiple times in the same test script.

=head2 is_libressl

    if (is_libressl()) {
        # Run LibreSSL-specific tests
    }

Returns true if libssl is provided by LibreSSL, or false if not.

=head2 is_openssl

    if (is_openssl()) {
        # Run OpenSSL-specific tests
    }

Returns true if libssl is provided by OpenSSL, or false if not.

=head2 is_protocol_usable

    if ( is_protocol_usable('TLSv1.1') ) {
        # Run TLSv1.1 tests
    }

Returns true if libssl can communicate using the given SSL/TLS protocol version
(represented as a string of the format returned by L</protocols>), or false if
not.

Note that the availability of a particular SSL/TLS protocol version may vary
based on the version of OpenSSL or LibreSSL in use, the options chosen when it
was compiled (e.g., OpenSSL will not support SSLv3 if it was built with
C<no-ssl3>), or run-time configuration (e.g., the use of TLSv1.0 will be
forbidden if the OpenSSL configuration sets the default security level to 3 or
higher; see L<SSL_CTX_set_security_level(3)>).

=head2 lives_ok

    lives_ok(
        sub { die 'Whoops' },
        'A test that always fails'
    );

Similar to L<C<lives_ok> in Test::Exception|Test::Exception/lives_ok>: performs
a L<Test::Builder> test that passes if a given subroutine executes without
dying, or fails if it dies during execution.

This function preserves the value of C<$@> set by the given subroutine, so (for
example) other tests can be performed on the value of C<$@> afterwards.

=head2 new_ctx

    my $ctx = new_ctx();
    # $ctx is an SSL_CTX that uses the highest available protocol version

    my ( $ctx, $version ) = new_ctx( 'TLSv1', 'TLSv1.2' );
    # $ctx is an SSL_CTX that uses the highest available protocol version
    # between TLSv1 and TLSv1.2 inclusive; $version contains the protocol
    # version chosen

Creates a libssl SSL_CTX object that uses the most recent SSL/TLS protocol
version supported by libssl, optionally bounded by the given minimum and maximum
protocol versions (represented as strings of the format returned by
L</protocols>).

If called in scalar context, returns the SSL_CTX object that was created. If
called in array context, returns the SSL_CTX object and a string containing the
protocol version used by the SSL_CTX object. Dies if libssl does not support any
of the protocol versions in the given range, or if an SSL_CTX object that uses
the chosen protocol version could not be created.

=head2 protocols

    my @protos = protocols();

Returns an array containing strings that describe the SSL/TLS protocol versions
supported by L<Net::SSLeay>: C<'TLSv1.3'>, C<'TLSv1.2'>, C<'TLSv1.1'>,
C<'TLSv1'>, C<'SSLv3'>, and C<'SSLv2'>. The protocol versions are sorted in
reverse order of age (i.e. in the order shown here).

Note that it may not be possible to communicate using some of these protocol
versions, depending on how libssl was compiled and is configured. These strings
can be given as parameters to L</is_protocol_usable> to discover whether the
protocol version is actually usable by libssl.

=head2 tcp_socket

    my $server = tcp_socket();

    # Accept connection from client:
    my $sock_in = $server->accept();

    # Create connection to server:
    my $sock_out = $server->connect();

Creates a TCP server socket that listens on localhost on an arbitrarily-chosen
free port. Convenience methods are provided for accepting, establishing and
closing connections.

Returns a L<Test::Net::SSLeay::Socket|Test::Net::SSLeay::Socket> object. Dies
on failure.

=head2 warns_like

    warns_like(
        sub {
            warn 'First warning';
            warn 'Second warning';
        },
        [
            qr/First/,
            qr/Second/,
        ],
        'A test that always passes'
    );

Similar to L<C<warnings_like> in Test::Warn|Test::Warn/warnings_like>: performs
a L<Test::Builder> test that passes if a given subroutine emits a series of
warnings that match the given sequence of patterns, or fails if the subroutine
emits any other sequence of warnings (or no warnings at all). If a pattern is
given instead of an array reference, the subroutine will be expected to emit a
single warning matching the pattern.

=head1 BUGS

If you encounter a problem with this module that you believe is a bug, please
L<create a new issue|https://github.com/radiator-software/p5-net-ssleay/issues/new>
in the Net-SSLeay GitHub repository. Please make sure your bug report includes
the following information:

=over

=item *

the code you are trying to run (ideally a minimum working example that
reproduces the problem), or the full output of the Net-SSLeay test suite if
the problem relates to a test failure;

=item *

your operating system name and version;

=item *

the output of C<perl -V>;

=item *

the version of Net-SSLeay you are using;

=item *

the version of OpenSSL or LibreSSL you are using.

=back

=head1 AUTHORS

Originally written by Chris Novakovic.

Maintained by Chris Novakovic, Tuure Vartiainen and Heikki Vatiainen.

=head1 COPYRIGHT AND LICENSE

Copyright 2020- Chris Novakovic <chris@chrisn.me.uk>.

Copyright 2020- Tuure Vartiainen <vartiait@radiatorsoftware.com>.

Copyright 2020- Heikki Vatiainen <hvn@radiatorsoftware.com>.

This module is released under the terms of the Artistic License 2.0. For
details, see the C<LICENSE> file distributed with Net-SSLeay's source code.

=cut
