#!perl
#===============================================================================
#
# t/pasv_address_validation.t
#
# DESCRIPTION
#   Regression test for CVE-2026-40558: Net::FTP::pasv() previously used the
#   IP address returned in the server's 227 reply to open the data connection,
#   allowing a malicious server to redirect the data channel to an arbitrary
#   third-party host.
#
#   The fix makes pasv() ignore the IP in the 227 reply and always store the
#   control connection's peer address instead (matching the behaviour that
#   epsv() already had).
#
#   Two scenarios are tested:
#
#     1. CVE regression - server sends a 227 reply containing a decoy IP
#        (127.0.0.2).  pasv() must store the control-connection host
#        (127.0.0.1), not the decoy.
#
#     2. Sanity check - server sends a 227 reply with the correct IP
#        (127.0.0.1).  pasv() must still store peerhost (127.0.0.1) and
#        return a defined value so normal passive transfers continue to work.
#
# COPYRIGHT
#   Copyright (C) 2026 Steve Hay.  All rights reserved.
#
# LICENCE
#   This script is free software; you can redistribute it and/or modify it under
#   the same terms as Perl itself, i.e. under the terms of either the GNU
#   General Public License or the Artistic License, as specified in the LICENCE
#   file.
#
#===============================================================================

use 5.008001;

use strict;
use warnings;

use Config qw();
use IO::Socket::INET qw();
use Test::More;

BEGIN {
    if (!eval { require Socket }) {
        plan skip_all => "no Socket";
    }
    elsif (ord('A') == 193 && !eval { require Convert::EBCDIC }) {
        plan skip_all => "EBCDIC but no Convert::EBCDIC";
    }
}

use Net::FTP;

plan skip_all => "fork not supported on this platform"
    unless $Config::Config{d_fork} || $Config::Config{d_pseudofork} ||
        (($^O eq 'MSWin32' || $^O eq 'NetWare') and
         $Config::Config{useithreads} and
         $Config::Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/);

# Test 1 requires 127.0.0.2 to be routable (most Linux systems have the full
# 127/8 block; some minimal containers do not).
{
    my $probe = IO::Socket::INET->new(
        Listen    => 1,
        LocalAddr => '127.0.0.2',
        LocalPort => 0,
        Proto     => 'tcp',
        Timeout   => 2,
    );
    plan skip_all => "127.0.0.2 not available on this host" unless $probe;
    close $probe;
}

plan tests => 4;

#===============================================================================
# SUBROUTINES
#===============================================================================

#-------------------------------------------------------------------------------
# pasv_reply($ip, $port) - build the parenthesised token of a 227 reply.
#-------------------------------------------------------------------------------

sub pasv_reply {
    my ($ip, $port) = @_;
    my $ip_part = join(',', split(/\./, $ip));
    return sprintf('(%s,%d,%d)', $ip_part, int($port / 256), $port % 256);
}

#-------------------------------------------------------------------------------
# mock_server($ctrl_sock, $pasv_ip, $pasv_port)
#
# Fork a child that accepts one control connection and responds to the minimal
# FTP commands Net::FTP sends before PASV (the 220 greeting, then SYST / TYPE
# as needed), and to PASV itself with a 227 reply containing $pasv_ip and
# $pasv_port.  Sends 221 on QUIT.  Returns the child PID.
#-------------------------------------------------------------------------------

sub mock_server {
    my ($ctrl_sock, $pasv_ip, $pasv_port) = @_;

    defined(my $pid = fork()) or die "fork: $!";
    unless ($pid) {
        # Child: serve exactly one client.
        my $conn = $ctrl_sock->accept or exit 1;
        print $conn "220 mock FTP server ready\r\n";
        while (my $line = <$conn>) {
            $line =~ s/\r?\n$//;
            if ($line =~ /^USER/i) {
                print $conn "230 logged in\r\n"
            }
            elsif ($line =~ /^SYST/i) {
                print $conn "215 UNIX Type: L8\r\n"
            }
            elsif ($line =~ /^TYPE/i) {
                print $conn "200 type set\r\n"
            }
            elsif ($line =~ /^PASV/i) {
                my $token = pasv_reply($pasv_ip, $pasv_port);
                print $conn "227 Entering Passive Mode $token\r\n";
            }
            elsif ($line =~ /^QUIT/i) {
                print $conn "221 goodbye\r\n";
                last;
            }
            else {
                print $conn "200 ok\r\n"
            }
        }
        $conn->close;
        exit 0;
    }

    return $pid;
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

#-------------------------------------------------------------------------------
# Test 1 - CVE-2026-40558 regression
#
# The server advertises 127.0.0.2 in its 227 reply.  After the fix, pasv()
# must store 127.0.0.1 (the control-connection peer) rather than 127.0.0.2.
#-------------------------------------------------------------------------------
{
    my $ctrl = IO::Socket::INET->new(
        Listen    => 5,
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'tcp',
    ) or die "control listener: $!";

    # The decoy port just needs to be a valid port number; nothing listens there
    # for this test because we only inspect what pasv() stores, not the
    # subsequent data connection.
    my $decoy_port = 65432;

    my $pid = mock_server($ctrl, '127.0.0.2', $decoy_port);

    my $ftp = Net::FTP->new('127.0.0.1',
        Port    => $ctrl->sockport,
        Timeout => 5,
    );

    SKIP: {
        skip "could not connect to mock control server", 2 unless $ftp;

        $ftp->login('anonymous');

        my $pasv = $ftp->pasv;

        ok(defined $pasv,
            'CVE test: pasv() returns defined even when 227 contains a decoy IP');

        is($pasv->[0], '127.0.0.1',
            'CVE test: pasv() stores peerhost (127.0.0.1), not the decoy IP from the 227 reply (127.0.0.2)');

        $ftp->quit;
    }

    waitpid($pid, 0);
}

#-------------------------------------------------------------------------------
# Test 2 - sanity check
#
# The server sends a well-formed 227 reply whose IP happens to match the
# control-connection host (127.0.0.1).  pasv() must still return a defined
# value and store 127.0.0.1 so that normal passive-mode transfers continue to
# work after the fix.
#-------------------------------------------------------------------------------
{
    my $ctrl = IO::Socket::INET->new(
        Listen    => 5,
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'tcp',
    ) or die "control listener: $!";

    my $pid = mock_server($ctrl, '127.0.0.1', 65433);

    my $ftp = Net::FTP->new('127.0.0.1',
        Port    => $ctrl->sockport,
        Timeout => 5,
    );

    SKIP: {
        skip "could not connect to mock control server", 2 unless $ftp;

        $ftp->login('anonymous');

        my $pasv = $ftp->pasv;

        ok(defined $pasv,
            'sanity: pasv() returns defined when 227 IP matches control host');

        is($pasv->[0], '127.0.0.1',
            'sanity: pasv() stores peerhost (127.0.0.1) for a well-behaved 227 reply');

        $ftp->quit;
    }

    waitpid($pid, 0);
}

#===============================================================================
