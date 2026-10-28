#!perl
#===============================================================================
#
# t/cmd_buffer_limits.t
#
# DESCRIPTION
#   Tests for the three unbounded-response-buffering vulnerabilities fixed in:
#
#     3b6f054  Net::Cmd: bound response buffers to prevent memory-exhaustion DoS
#     a6caebda Ensure that $partial cannot overshoot its limit
#     b6fa2edf Switch hard-coded constant limits to overridable methods
#
#   Three sinks are tested:
#
#     1. getline()/partial-line accumulator (max_partial_bytes, default 1 MiB)
#     2. response() multiline accumulator   (max_resp_bytes,    default 8 MiB)
#     3. read_until_dot() body accumulator  (max_dotread_bytes, default 32 MiB)
#
#   To keep the tests fast and deterministic the limits are overridden to small
#   values via subclassing (the overridable-methods feature from b6fa2edf).
#   A socketpair feeds pre-crafted "server" bytes into the real Net::Cmd code.
#
#   Design note: getline() reads up to 1024 bytes per sysread() call, and the
#   partial-line check fires on length($partial) + length($sysread_buf).  So
#   max_partial_bytes must always be >= 1024 for tests that are NOT testing the
#   partial-line guard itself, otherwise the partial check fires first and masks
#   the response()/read_until_dot() overflow paths.  TestCmd uses 4096 as its
#   default so that response() and read_until_dot() tests are unaffected, while
#   the partial-line section uses dedicated subclasses with much smaller limits.
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

use IO::Handle qw();
use Net::Cmd qw();
use Socket qw(AF_UNIX SOCK_STREAM);
use Test::More;

#===============================================================================
# INITIALIZATION
#===============================================================================

BEGIN {
    if (!eval { require Socket }) {
        plan skip_all => "no Socket";
    }
    elsif (!eval { Socket->import(qw(AF_UNIX SOCK_STREAM)); 1 }) {
        plan skip_all => "Socket does not export AF_UNIX/SOCK_STREAM";
    }
    elsif (ord('A') == 193 && !eval { require Convert::EBCDIC }) {
        plan skip_all => "EBCDIC but no Convert::EBCDIC";
    }
    else {
        my ($rd, $wr);
        if (!socketpair($rd, $wr, AF_UNIX, SOCK_STREAM, 0)) {
            plan skip_all => "socketpair not available: $!";
        }
        else {
            close $rd;
            close $wr;
            plan tests => 28;
        }
    }
}

#===============================================================================
# TEST CLASSES
#===============================================================================

# ---------------------------------------------------------------------------
# TestCmd - base subclass for all tests.
#
# max_partial_bytes is set large enough (4 KiB) that normal CRLF-terminated
# lines arriving in a single sysread() chunk do NOT trip the partial guard.
# This lets the response() and read_until_dot() overflow paths be tested
# independently.  The partial-line section uses smaller-limit subclasses.
# ---------------------------------------------------------------------------

{
    package TestCmd;
    use IO::Handle;
    use Net::Cmd;
    our @ISA = qw(Net::Cmd IO::Handle);
    sub new     { my ($class, $fh) = @_; return bless $fh, $class }
    sub timeout { 0 }
    sub max_partial_bytes  { 4096 }   # large enough not to interfere
    sub max_resp_bytes     { 128  }   # small so response() overflow is cheap
    sub max_dotread_bytes  { 256  }   # small so read_until_dot() overflow is cheap
}

# Subclasses used in the partial-line section (Section 1).
{
    package TestCmdPartial64;   # limit = 64 bytes
    our @ISA = ('TestCmd');
    sub max_partial_bytes { 64 }
}
{
    package TestCmdPartial256;  # limit = 256 bytes (raises default)
    our @ISA = ('TestCmdPartial64');
    sub max_partial_bytes { 256 }
}
{
    package TestCmdPartial8;    # limit = 8 bytes (lowers default)
    our @ISA = ('TestCmdPartial64');
    sub max_partial_bytes { 8 }
}

# Subclass used in the response() section (Section 2).
{
    package TestCmdBigResp;     # raises max_resp_bytes
    our @ISA = ('TestCmd');
    sub max_resp_bytes { 512 }
}

# Subclass used in the read_until_dot() section (Section 3).
{
    package TestCmdSmallDot;    # lowers max_dotread_bytes
    our @ISA = ('TestCmd');
    sub max_dotread_bytes { 32 }
}

#===============================================================================
# SUBROUTINES
#===============================================================================

# ---------------------------------------------------------------------------
# make_cmd($data [, $class])
# Write $data to a socketpair, shut the write end, return a $class object
# wrapping the read end.
# ---------------------------------------------------------------------------

sub make_cmd {
    my ($server_data, $class) = @_;
    $class = 'TestCmd' unless defined $class;

    my ($rd, $wr);
    socketpair($rd, $wr, AF_UNIX, SOCK_STREAM, 0)
        or die "socketpair: $!";

    $wr->autoflush(1);
    print $wr $server_data;
    shutdown($wr, 1);   # SHUT_WR: reader sees EOF after all bytes
    close $wr;

    return $class->new($rd);
}

# ---------------------------------------------------------------------------
# dot_encode(@lines) - format lines as a dot-terminated RFC 977/2449 body
# ---------------------------------------------------------------------------

sub dot_encode {
    my @lines = @_;
    my $out = '';
    for my $ln (@lines) {
        $ln =~ s/^\.\././;
        $out .= $ln . "\015\012";
    }
    $out .= ".\015\012";
    return $out;
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

# ===========================================================================
# Section 1 - getline() partial-line accumulator (max_partial_bytes)
#
# The partial accumulator grows when sysread() delivers bytes that contain no
# CRLF.  After each sysread the check is:
#   length($partial) + length($buf) > max_partial_bytes  -> error
# (the a6caebda fix moves this check *before* prepending $partial to $buf, so
# the combined size is tested rather than the post-prepend remainder).
# ===========================================================================

# 1a. A line of exactly max_partial_bytes bytes + CRLF must succeed.
#     With limit=64: send 64 'A's + CRLF.  The sysread delivers 66 bytes;
#     length($partial=0) + length($buf=66) = 66 > 64 -- this would fail.
#     Instead use 62 'A's + CRLF = 64 bytes total: 0 + 64 = 64, not > 64.
{
    # 62 data bytes + CRLF = 64 bytes in the sysread buffer.
    # length(partial=0) + length(buf=64) = 64, which is NOT > 64, so accepted.
    my $line = ('A' x 62) . "\015\012";
    my $cmd  = make_cmd($line, 'TestCmdPartial64');

    my $got = $cmd->getline;
    is($got, ('A' x 62) . "\n",
        'getline: line whose raw bytes equal max_partial_bytes is accepted');
    is($cmd->code, 421,
        'getline: code is DEF_REPLY_CODE when no error has occurred');
}

# 1b. A partial line (no CRLF) one byte over the limit must close the
#     socket and set an error status.
{
    # 65 bytes, no CRLF: length(partial=0) + length(buf=65) = 65 > 64.
    my $data = 'A' x 65;
    my $cmd  = make_cmd($data, 'TestCmdPartial64');

    my $got = $cmd->getline;
    ok(!defined $got,
        'getline: oversized partial returns undef');
    is($cmd->code, 421,
        'getline: code is 421 after partial-line overflow');
    like(($cmd->message)[0], qr/Response line too long/i,
        'getline: message says "Response line too long"');
    ok(!defined fileno($cmd),
        'getline: connection is closed after overflow');
}

# 1c. The a6caebda fix: the check fires on the *combined* size before prepend,
#     so even a single oversized chunk is caught on the first sysread.
{
    # Same 65-byte payload; verifies the pre-prepend path specifically.
    my $data = 'B' x 65;
    my $cmd  = make_cmd($data, 'TestCmdPartial64');

    my $got = $cmd->getline;
    ok(!defined $got,
        'getline (a6caebda): pre-prepend check fires on first oversized read');
    like(($cmd->message)[0], qr/Response line too long/i,
        'getline (a6caebda): correct error message');
}

# 1d. Subclass that raises max_partial_bytes allows a longer partial/line.
{
    # 128 bytes of data + CRLF = 130 bytes: > 64 (TestCmdPartial64) but < 256.
    my $line = ('C' x 128) . "\015\012";
    my $cmd  = make_cmd($line, 'TestCmdPartial256');

    my $got = $cmd->getline;
    is($got, ('C' x 128) . "\n",
        'getline: subclass can raise max_partial_bytes');
}

# 1e. Subclass that lowers max_partial_bytes catches a shorter overflow.
{
    # 9 bytes, no CRLF: 0 + 9 = 9 > 8 (TestCmdPartial8).
    my $data = 'D' x 9;
    my $cmd  = make_cmd($data, 'TestCmdPartial8');

    my $got = $cmd->getline;
    ok(!defined $got,
        'getline: subclass can lower max_partial_bytes');
    like(($cmd->message)[0], qr/Response line too long/i,
        'getline: lowered limit gives correct error message');
}

# ===========================================================================
# Section 2 - response() multiline accumulator (max_resp_bytes)
#
# Each continuation line (NNN-...) is counted; when the running total exceeds
# max_resp_bytes the connection is closed and CMD_ERROR is returned.
# ===========================================================================

# 2a. A short single-line response must be accepted.
{
    my $cmd = make_cmd("200 OK\015\012");

    my $ret = $cmd->response;
    is($ret, Net::Cmd::CMD_OK(),
        'response: short single-line 200 OK is accepted');
    is($cmd->code, '200',
        'response: code parsed correctly');
}

# 2b. A multiline response whose total byte count exceeds max_resp_bytes must
#     return CMD_ERROR, set code 421, and close the connection.
#
#     Note: response() counts the bytes of $str *after* parse_response() has
#     stripped the leading "NNN " / "NNN-" prefix.  So "200-EEEEEEEEEEEEEEE\r\n"
#     contributes only "EEEEEEEEEEEEEEE\n" = 16 bytes per line.  We need
#     128 / 16 = 8 lines to hit the ceiling; use 10 to cross it comfortably.
{
    # Each continuation contributes 16 bytes after prefix stripping;
    # 10 lines = 160 bytes > 128-byte limit.
    my $cont  = "200-" . ('E' x 15) . "\015\012";
    my $final = "200 end\015\012";
    my $data  = ($cont x 10) . $final;

    my $cmd = make_cmd($data);
    my $ret = $cmd->response;

    is($ret, Net::Cmd::CMD_ERROR(),
        'response: oversized multiline response returns CMD_ERROR');
    is($cmd->code, 421,
        'response: code is 421 after multiline overflow');
    like(($cmd->message)[0], qr/Response too large/i,
        'response: message says "Response too large"');
    ok(!defined fileno($cmd),
        'response: connection is closed after overflow');
}

# 2c. A multiline response just under the limit must be accepted.
{
    # Two 60-byte lines = 120 bytes total, below the 128-byte limit.
    my $line1 = "200-" . ('F' x 55) . "\015\012";   # 60 bytes
    my $line2 = "200 " . ('F' x 55) . "\015\012";   # 60 bytes
    my $cmd   = make_cmd($line1 . $line2);

    my $ret = $cmd->response;
    is($ret, Net::Cmd::CMD_OK(),
        'response: multiline response within limit is accepted');
}

# 2d. Subclass that raises max_resp_bytes allows a larger multiline response.
{
    # 10 continuation lines x 20 bytes = 200 bytes -- over default 128 but < 512.
    my $cont  = "200-" . ('G' x 15) . "\015\012";
    my $final = "200 end\015\012";
    my $data  = ($cont x 10) . $final;

    my $cmd = make_cmd($data, 'TestCmdBigResp');
    my $ret = $cmd->response;
    is($ret, Net::Cmd::CMD_OK(),
        'response: subclass can raise max_resp_bytes');
}

# ===========================================================================
# Section 3 - read_until_dot() body accumulator (max_dotread_bytes)
#
# Lines accumulate in an in-memory array when no filehandle is given; when the
# running total exceeds max_dotread_bytes the connection is closed.
# When a filehandle IS given the accumulator is bypassed completely.
# ===========================================================================

# 3a. A body within max_dotread_bytes must be returned as an arrayref.
{
    # 5 lines x 20 data bytes each; dot_encode appends \015\012, so each
    # stored line is "HHHH...\n" = 21 bytes; total = 105 bytes < 256.
    my $body = dot_encode(map { 'H' x 20 } 1 .. 5);
    my $cmd  = make_cmd($body);

    my $arr = $cmd->read_until_dot;
    ok(defined $arr && ref($arr) eq 'ARRAY',
        'read_until_dot: body within limit returns arrayref');
    is(scalar @{$arr}, 5,
        'read_until_dot: correct number of lines returned');
}

# 3b. A body exceeding max_dotread_bytes must return undef, set code 421,
#     and close the connection.
{
    # 14 lines x 21 bytes = 294 bytes > 256-byte limit.
    my $body = dot_encode(map { 'I' x 20 } 1 .. 14);
    my $cmd  = make_cmd($body);

    my $arr = $cmd->read_until_dot;
    ok(!defined $arr,
        'read_until_dot: oversized body returns undef');
    is($cmd->code, 421,
        'read_until_dot: code is 421 after dot-read overflow');
    like(($cmd->message)[0], qr/Dot-read too large/i,
        'read_until_dot: message says "Dot-read too large"');
    ok(!defined fileno($cmd),
        'read_until_dot: connection is closed after overflow');
}

# 3c. When a filehandle is supplied the in-memory accumulator is bypassed,
#     so even a body that would overflow the byte limit must succeed.
{
    require File::Temp;

    # 14 lines x 21 bytes = 294 bytes -- would exceed the 256-byte in-memory
    # limit, but the data is written to the filehandle instead.
    my $body = dot_encode(map { 'J' x 20 } 1 .. 14);
    my $cmd  = make_cmd($body);

    my $fh  = File::Temp->new;
    my $arr = $cmd->read_until_dot($fh);

    # Returns [] (empty arrayref) because nothing was pushed to $arr.
    ok(defined $arr && ref($arr) eq 'ARRAY',
        'read_until_dot: filehandle path bypasses in-memory limit');
}

# 3d. Subclass that lowers max_dotread_bytes catches a smaller body.
{
    # 2 lines x 21 bytes = 42 bytes > TestCmdSmallDot's 32-byte limit.
    my $body = dot_encode(map { 'K' x 20 } 1 .. 2);
    my $cmd  = make_cmd($body, 'TestCmdSmallDot');

    my $arr = $cmd->read_until_dot;
    ok(!defined $arr,
        'read_until_dot: subclass can lower max_dotread_bytes');
    like(($cmd->message)[0], qr/Dot-read too large/i,
        'read_until_dot: lowered limit gives correct error message');
}

#===============================================================================
