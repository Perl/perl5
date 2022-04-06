package IO::Compress::Zip::WeakDecrypt ;

# This code is derived from ...
# Below is the
# ##############################################################################
#
# Decrypt section
#
# H.Merijn Brand (Tux) 2011-06-28
#
# ##############################################################################

# This code is derived from the crypt source of unzip-6.0 dated 05 Jan 2007
# Its license states:
#
# --8<---
# Copyright (c) 1990-2007 Info-ZIP.  All rights reserved.

# See the accompanying file LICENSE, version 2005-Feb-10 or later
# (the contents of which are also included in (un)zip.h) for terms of use.
# If, for some reason, all these files are missing, the Info-ZIP license
# also may be found at:  ftp://ftp.info-zip.org/pub/infozip/license.html
#
# crypt.c (full version) by Info-ZIP.      Last revised:  [see crypt.h]

# The main encryption/decryption source code for Info-Zip software was
# originally written in Europe.  To the best of our knowledge, it can
# be freely distributed in both source and object forms from any country,
# including the USA under License Exception TSU of the U.S. Export
# Administration Regulations (section 740.13(e)) of 6 June 2002.

# NOTE on copyright history:
# Previous versions of this source package (up to version 2.8) were
# not copyrighted and put in the public domain.  If you cannot comply
# with the Info-Zip LICENSE, you may want to look for one of those
# public domain versions.
#
# This encryption code is a direct transcription of the algorithm from
# Roger Schlafly, described by Phil Katz in the file appnote.txt.  This
# file (appnote.txt) is distributed with the PKZIP program (even in the
# version without encryption capabilities).
# -->8---

# As of January 2000, US export regulations were amended to allow export
# of free encryption source code from the US.  As of June 2002, these
# regulations were further relaxed to allow export of encryption binaries
# associated with free encryption source code.  The Zip 2.31, UnZip 5.52
# and Wiz 5.02 archives now include full crypto source code.  As of the
# Zip 2.31 release, all official binaries include encryption support; the
# former "zcr" archives ceased to exist.
# (Note that restrictions may still exist in other countries, of course.)

use Data::Peek;

my @keys;
my @crct = do {
    my $xor = 0xedb88320;
    my @crc = (0) x 1024;

    # generate a crc for every 8-bit value
    foreach my $n (0 .. 255) {
        my $c = $n;
        $c = $c & 1 ? $xor ^ ($c >> 1) : $c >> 1 for 1 .. 8;
        $crc[$n] = _revbe($c);
    }

    # generate crc for each value followed by one, two, and three zeros */
    foreach my $n (0 .. 255) {
        my $c = ($crc[($crc[$n] >> 24) ^ 0] ^ ($crc[$n] << 8)) & 0xffffffff;
        $crc[$_ * 256 + $n] = $c for 1 .. 3;
    }
    map { _revbe($crc[$_]) } 0 .. 1023;
};

sub new
{
    my $self = shift;
    my $password = shift;
    my $crc32 = shift;
    my $lastModFileDateTime = shift;
    my $streaming = shift;

    @keys = (0x12345678, 0x23456789, 0x34567890);
    _update_keys($_)
        for unpack "C*", $password;

    my %object = (
        password            => $password,
        pending             => "",
        headerDecoded       => 0,
        error               => "",
        errorNo             => 0,

        # data needed for the encryption header
        crc32               => $crc32,
        lastModFileDateTime => $lastModFileDateTime,
        streaming           => $streaming,
    );

    return bless \%object, $self;
}

sub decode
{
    my $self = shift;
    my $buff = shift;
    my $offset = shift ;

    # return ""
    #     if $offset >= length($$buff);

    # warn "decode : \n" ; DHexDump $$buff;

    if (! $self->{headerDecoded})
    {
        $self->{pending} .= substr($$buff, $offset);
        # $self->{pending} .= $$buff ;
        # warn "PENDING: " . length($self->{pending}) . "\n" ; DHexDump($self->{pending});

        # if (length($buff) + length($self->{pending}) < 12)
        if (length{pending} < 12)
        {
            return "";
        }

        # DDumper { uk => [ @keys ] };

        my $head = substr $self->{pending}, 0, 12, "";
        # warn "HEAD: " . length($head) . "\n" ; DHexDump($head);

        # DHexDump $head;
        my @head = map { _zdecode($_) } unpack "C*", $head;
        my $x = $self->{streaming}
                    ? ($self->{lastModFileDateTime} >> 8) & 0xff
                    : $self->{crc32} >> 24;
        $x = $self->{crc32} >> 24;
        $x = ($self->{lastModFileDateTime} >> 8) & 0xff ;
        # DHexDump $x;

        $head[-1] == $x
            or return $self->_error("Password Invalid");

# warn "Password OK\n";
        # # Worth checking ...
        # $self->{crc32c} = (unpack LOCAL_FILE_HEADER_FORMAT, pack "C*", @head)[3];

        substr($$buff, $offset) = $self->{pending} ;
        # $$buff = $self->{pending} ;
        $self->{pending} = '';
        $self->{headerDecoded} = 1;
    }

    # print "BEFORE: " . DHexDump ($$buff);
    my $undecoded = pack "C*" => map { _zdecode($_) } unpack "C*" => $$buff;
    # print "AFTER:  " . DHexDump ($undecoded);

    # DHexDump ($buff);
    return $undecoded;
}

sub getError
{
    my $self = shift;
    return $self->{error};
}

sub getErrorNo
{
    my $self = shift;
    return $self->{errorNo};
}

#### Private

sub _error
{
    my $self = shift;

    $self->{error} = shift;
    $self->{errorNo} = -1;
    return undef
}



sub _crc32
{
    my ($c, $b) = @_;

    return ($crct[($c ^ $b) & 0xff] ^ ($c >> 8));
}    # _crc32

sub _revbe
{
    my $w = shift;

    return (($w >> 24) +
          (($w >> 8) & 0xff00) +
          (($w & 0xff00) << 8) +
          (($w & 0xff) << 24));
}    # _revbe

sub _update_keys
{
    use integer;
    my $c = shift;    # signed int

    $keys[0] = _crc32($keys[0], $c);
    $keys[1] = (($keys[1] + ($keys[0] & 0xff)) * 0x08088405 + 1) & 0xffffffff;
    my $keyshift = $keys[1] >> 24;
    $keys[2] = _crc32($keys[2], $keyshift);
}    # _update_keys

sub _zdecode ($)
{
    my $c = shift;

    my $t = ($keys[2] & 0xffff) | 2;
    _update_keys($c ^= ((($t * ($t ^ 1)) >> 8) & 0xff));
    return $c;
}



1;
