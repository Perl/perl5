=head1 NAME

Mac::Types - Macintosh Toolbox Types and conversions.

=head1 SYNOPSIS

=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut

use strict;

package Mac::Types;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	use Carp;

	use vars qw($VERSION @ISA @EXPORT %MacPack %MacUnpack);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	
	@EXPORT = qw(
		Debugger
		%MacPack
		%MacUnpack
		MacPack
		MacUnpack
	);
}

=head2 Functions

=over 4

=cut
sub _Identity {
	return wantarray ? @_ : shift;
}

sub _Packer {
	my($template) = @_;
	
	return sub { return pack($template, @_); };
}

sub _Unpacker {
	my($template) = @_;
	
	return sub { return unpack($template, $_[0] || ''); };
}

sub _PackPStr {
	my($string) = @_;
	
	return pack("Ca*", length($string), $string);
}

sub _UnpackPStr {
	my($string) = @_;
	
	return "" unless defined($string) && length($string);
	
	my ($length, $cstr) = unpack("Ca*", $string);
	
	return substr($cstr, 0, $length);
}

sub _PackPStrList {
	my($list) = pack("s", scalar(@_));
	for (@_) {
		$list .= _PackPStr($_);
	}
	return $list;
}

sub _UnpackPStrList {
	my($data) = @_;
	my($count, @strings) = unpack("s", $data);
	$data = substr($data,2);
	while ($count--) {
		my($str) = _UnpackPStr($data);
		$data = substr($data, length($str)+1);
		push(@strings, $str);
	}
	return @strings;
}

sub _PackFSSpec {
	my($spec) = MacPerl::MakeFSSpec($_[0]);
	my($packed) = pack("SL", hex(substr($spec, 1, 4)), hex(substr($spec, 5, 8))) 
		. _PackPStr(substr($spec, 14));
	return $packed . ("\0" x (70-length($packed)));
}

sub _UnpackFSSpec {
	my($spec) = @_;
	
	return 
		MacPerl::MakeFSSpec(sprintf(
			"\021%04x%08x:%s", 
			unpack("SL", $spec), 
			_UnpackPStr(substr($spec, 6))));
}

%MacPack = (
	TEXT => \&_Identity,
	enum => _Packer("A4"),
	type => _Packer("A4"),
	keyw => _Packer("A4"),
	sign => _Packer("A4"),
	bool => _Packer("c"),
	shor => _Packer("s"),
	long => _Packer("l"),
	sing => _Packer("f"),
	doub => _Packer("d"),
	magn => _Packer("L"),
	qdrt => _Packer("s4"),
	cRGB => _Packer("s3"),
	
	'STR ' => \&_PackPStr,
	'STR#' => \&_PackPStrList,
	'fss ' => \&_PackFSSpec,
);

%MacUnpack = (
	TEXT => \&_Identity,
	enum => _Unpacker("a4"),
	type => _Unpacker("a4"),
	keyw => _Unpacker("a4"),
	sign => _Unpacker("a4"),
	bool => _Unpacker("c"),
	shor => _Unpacker("s"),
	long => _Unpacker("l"),
	sing => _Unpacker("f"),
	doub => _Unpacker("d"),
	magn => _Unpacker("L"),
	qdrt => _Unpacker("s4"),
	cRGB => _Unpacker("S3"),
	
	'STR ' => \&_UnpackPStr,
	'STR#' => \&_UnpackPStrList,
	'fss ' => \&_UnpackFSSpec,
);

sub _MacConvert {
	my($type) = shift;
	my(@methods) = ();
	
	while (ref($type) eq "HASH") {
		unshift @methods, $type;
		$type = shift;
	}
	my($table,$code);
	for $table (@methods) {
		$code = $table->{$type};
		if (ref($code) eq "CODE") {
			return &{$code}(@_);
		}
	}
	croak "Don't know about type “$type”";
}

=item MacPack [ CONVERTERS ...] CODE, DATA ...

Convert a perl value into a Mac toolbox type. Predefined codes are:

=over 4

=item TEXT 

Text (an identity operation).

=item enum

=item type 

=item keyw

A 4-byte string.

=item bool 

A boolean.

=item shor 

A short integer.

=item long 

A long integer.

=item sing 

A single precision float.

=item doub 

A double precision float.

=item magn 

An unsigned long.

=item qdrt

A QuickDraw C<Rect>.
	
=item 'STR ' 

A pascal style string.

=item 'STR#' 

A string list.

=item 'fss '

A file specification record.

=back

You can pass further code mappings as hash references.

=cut
sub MacPack {
	_MacConvert(\%MacPack, @_);
}

=item MacUnpack [ CONVERTERS ...] CODE, DATA

Convert a Mac toolbox type into a perl value. Predefined codes are as for 
C<MacPack>. You can pass further code mappings as hash references.

=cut
sub MacUnpack {
	_MacConvert(\%MacUnpack, @_);
}

bootstrap Mac::Types;

=back

=include Types.xs

=head1 BUGS/LIMITATIONS

=head1 FILES

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeracher@mac.com> 

=cut

1;

__END__
