
package	Net::Telnet;

=head1 NAME

Net::Telnet - Defines constants for the telnet protocol

=head1 SYNOPSIS

    use Telnet qw(TELNET_IAC TELNET_DO TELNET_DONT);

=head1 DESCRIPTION

This module is B<VERY> preliminary as I am not 100% sure how it should
be implemented.

Currently it just exports constants used in the telnet protocol.

Should it contain sub's for packing and unpacking commands ?

Please feel free to send me any suggestions

=head1 NOTE

This is not an implementation of the 'telnet' command but of the telnet
protocol as defined in RFC854

=head1 AUTHOR

Graham Barr <Graham.Barr@tiuk.ti.com>

=head1 REVISION

$Revision: 2.0 $

=head1 COPYRIGHT

Copyright (c) 1995 Graham Barr. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

use     vars qw(@ISA $VERSION);
require	Exporter;
@ISA = qw(Exporter);

$VERSION = sprintf("%d.%02d", q$Revision: 2.0 $ =~ /(\d+)\.(\d+)/);

my %telnet = (
	TELNET_IAC	=> 255,		# interpret as command:
	TELNET_DONT	=> 254,		# you are not to use option
	TELNET_DO	=> 253,		# please, you use option
	TELNET_WONT	=> 252,		# I won't use option
	TELNET_WILL	=> 251,		# I will use option
	TELNET_SB	=> 250,		# interpret as subnegotiation
	TELNET_GA	=> 249,		# you may reverse the line
	TELNET_EL	=> 248,		# erase	the current line
	TELNET_EC	=> 247,		# erase	the current character
	TELNET_AYT	=> 246,		# are you there
	TELNET_AO	=> 245,		# abort	output--but let	prog finish
	TELNET_IP	=> 244,		# interrupt process--permanently
	TELNET_BREAK	=> 243,		# break
	TELNET_DM	=> 242,		# data mark--for connect. cleaning
	TELNET_NOP	=> 241,		# nop
	TELNET_SE	=> 240,		# end sub negotiation
	TELNET_EOR	=> 239,		# end of record	(transparent mode)
	TELNET_ABORT	=> 238,		# Abort	process
	TELNET_SUSP	=> 237,		# Suspend process
	TELNET_EOF	=> 236,		# End of file: EOF is already used...

	TELNET_SYNCH	=> 242,		# for telfunc calls
);

while(($n,$v) =	each %telnet) {	eval "sub $n {$v}"; }

sub telnet_command {
    my $cmd = shift;
    my($n,$v);

    while(($n,$v) = each %telnet) {
	return $n
	    if($v == $cmd);
    }

    return undef;
}

# telnet options
my %telopt = (
	TELOPT_BINARY		=> 0,	# 8-bit	data path
	TELOPT_ECHO		=> 1,	# echo
	TELOPT_RCP		=> 2,	# prepare to reconnect
	TELOPT_SGA		=> 3,	# suppress go ahead
	TELOPT_NAMS		=> 4,	# approximate message size
	TELOPT_STATUS		=> 5,	# give status
	TELOPT_TM		=> 6,	# timing mark
	TELOPT_RCTE		=> 7,	# remote controlled transmission and echo
	TELOPT_NAOL		=> 8,	# negotiate about output line width
	TELOPT_NAOP		=> 9,	# negotiate about output page size
	TELOPT_NAOCRD		=> 10,	# negotiate about CR disposition
	TELOPT_NAOHTS		=> 11,	# negotiate about horizontal tabstops
	TELOPT_NAOHTD		=> 12,	# negotiate about horizontal tab disposition
	TELOPT_NAOFFD		=> 13,	# negotiate about formfeed disposition
	TELOPT_NAOVTS		=> 14,	# negotiate about vertical tab stops
	TELOPT_NAOVTD		=> 15,	# negotiate about vertical tab disposition
	TELOPT_NAOLFD		=> 16,	# negotiate about output LF disposition
	TELOPT_XASCII		=> 17,	# extended ascic character set
	TELOPT_LOGOUT		=> 18,	# force	logout
	TELOPT_BM		=> 19,	# byte macro
	TELOPT_DET		=> 20,	# data entry terminal
	TELOPT_SUPDUP		=> 21,	# supdup protocol
	TELOPT_SUPDUPOUTPUT	=> 22,	# supdup output
	TELOPT_SNDLOC		=> 23,	# send location
	TELOPT_TTYPE		=> 24,	# terminal type
	TELOPT_EOR		=> 25,	# end or record
	TELOPT_TUID		=> 26,	# TACACS user identification
	TELOPT_OUTMRK		=> 27,	# output marking
	TELOPT_TTYLOC		=> 28,	# terminal location number
	TELOPT_3270REGIME	=> 29,	# 3270 regime
	TELOPT_X3PAD		=> 30,	# X.3 PAD
	TELOPT_NAWS		=> 31,	# window size
	TELOPT_TSPEED		=> 32,	# terminal speed
	TELOPT_LFLOW		=> 33,	# remote flow control
	TELOPT_LINEMODE		=> 34,	# Linemode option
	TELOPT_XDISPLOC		=> 35,	# X Display Location
	TELOPT_OLD_ENVIRON	=> 36,	# Old -	Environment variables
	TELOPT_AUTHENTICATION	=> 37,	# Authenticate
	TELOPT_ENCRYPT		=> 38,	# Encryption option
	TELOPT_NEW_ENVIRON	=> 39,	# New -	Environment variables
	TELOPT_EXOPL		=> 255,	# extended-options-list
);

while(($n,$v) =	each %telopt) {	eval "sub $n {$v}"; }

sub telnet_option {
    my $cmd = shift;
    my($n,$v);

    while(($n,$v) = each %telopt) {
	return $n
	    if($v == $cmd);
    }

    return undef;
}

# sub-option qualifiers

sub TELQUAL_IS		{0}	# option is...
sub TELQUAL_SEND	{1}	# send option
sub TELQUAL_INFO	{2}	# ENVIRON: informational version of IS
sub TELQUAL_REPLY	{2}	# AUTHENTICATION: client version of IS
sub TELQUAL_NAME	{3}	# AUTHENTICATION: client version of IS

sub LFLOW_OFF		{0}	# Disable remote flow control
sub LFLOW_ON		{1}	# Enable remote	flow control
sub LFLOW_RESTART_ANY	{2}	# Restart output on any	char
sub LFLOW_RESTART_XON	{3}	# Restart output only on XON

# LINEMODE suboptions

sub LM_MODE		{1}
sub LM_FORWARDMASK	{2}
sub LM_SLC		{3}

sub MODE_EDIT		{0x01}
sub MODE_TRAPSIG	{0x02}
sub MODE_ACK		{0x04}
sub MODE_SOFT_TAB	{0x08}
sub MODE_LIT_ECHO	{0x10}

sub MODE_MASK		{0x1f}

# Not part of protocol,	but needed to simplify things...
sub MODE_FLOW		{0x0100}
sub MODE_ECHO		{0x0200}
sub MODE_INBIN		{0x0400}
sub MODE_OUTBIN		{0x0800}
sub MODE_FORCE		{0x1000}

my %slc	= (
	SLC_SYNCH	=>  1,
	SLC_BRK		=>  2,
	SLC_IP		=>  3,
	SLC_AO		=>  4,
	SLC_AYT		=>  5,
	SLC_EOR		=>  6,
	SLC_ABORT	=>  7,
	SLC_EOF		=>  8,
	SLC_SUSP	=>  9,
	SLC_EC		=> 10,
	SLC_EL		=> 11,
	SLC_EW		=> 12,
	SLC_RP		=> 13,
	SLC_LNEXT	=> 14,
	SLC_XON		=> 15,
	SLC_XOFF	=> 16,
	SLC_FORW1	=> 17,
	SLC_FORW2	=> 18,
);


while(($n,$v) =	each %slc) { eval "sub $n {$v}"; }

sub telnet_slc {
    my $cmd = shift;
    my($n,$v);

    while(($n,$v) = each %slc) {
	return $n
	    if($v == $cmd);
    }

    return undef;
}

sub NSLC		{18}

sub SLC_NOSUPPORT	{0}
sub SLC_CANTCHANGE	{1}
sub SLC_VARIABLE	{2}
sub SLC_DEFAULT		{3}
sub SLC_LEVELBITS	{0x03}

sub SLC_FUNC		{0}
sub SLC_FLAGS		{1}
sub SLC_VALUE		{2}

sub SLC_ACK		{0x80}
sub SLC_FLUSHIN		{0x40}
sub SLC_FLUSHOUT	{0x20}

sub OLD_ENV_VAR		{1}
sub OLD_ENV_VALUE	{0}
sub NEW_ENV_VAR		{0}
sub NEW_ENV_VALUE	{1}
sub ENV_ESC		{2}
sub ENV_USERVAR		{3}

@EXPORT_OK = (keys %telnet, keys %telopt, keys %slc);

sub telnet_pack {
    my $r = '';


    $r;
}

1;
