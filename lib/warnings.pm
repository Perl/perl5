
# This file was created by warnings.pl
# Any changes made here will be lost.
#

package warnings;

our $VERSION = '1.00';

=head1 NAME

warnings - Perl pragma to control optional warnings

=head1 SYNOPSIS

    use warnings;
    no warnings;

    use warnings "all";
    no warnings "all";

    use warnings::register;
    if (warnings::enabled()) {
        warnings::warn("some warning");
    }

    if (warnings::enabled("void")) {
        warnings::warn("void", "some warning");
    }

    if (warnings::enabled($object)) {
        warnings::warn($object, "some warning");
    }

    warnif("some warning");
    warnif("void", "some warning");
    warnif($object, "some warning");

=head1 DESCRIPTION

If no import list is supplied, all possible warnings are either enabled
or disabled.

A number of functions are provided to assist module authors.

=over 4

=item use warnings::register

Creates a new warnings category with the same name as the package where
the call to the pragma is used.

=item warnings::enabled()

Use the warnings category with the same name as the current package.

Return TRUE if that warnings category is enabled in the calling module.
Otherwise returns FALSE.

=item warnings::enabled($category)

Return TRUE if the warnings category, C<$category>, is enabled in the
calling module.
Otherwise returns FALSE.

=item warnings::enabled($object)

Use the name of the class for the object reference, C<$object>, as the
warnings category.

Return TRUE if that warnings category is enabled in the first scope
where the object is used.
Otherwise returns FALSE.

=item warnings::warn($message)

Print C<$message> to STDERR.

Use the warnings category with the same name as the current package.

If that warnings category has been set to "FATAL" in the calling module
then die. Otherwise return.

=item warnings::warn($category, $message)

Print C<$message> to STDERR.

If the warnings category, C<$category>, has been set to "FATAL" in the
calling module then die. Otherwise return.

=item warnings::warn($object, $message)

Print C<$message> to STDERR.

Use the name of the class for the object reference, C<$object>, as the
warnings category.

If that warnings category has been set to "FATAL" in the scope where C<$object>
is first used then die. Otherwise return.


=item warnings::warnif($message)

Equivalent to:

    if (warnings::enabled())
      { warnings::warn($message) }

=item warnings::warnif($category, $message)

Equivalent to:

    if (warnings::enabled($category))
      { warnings::warn($category, $message) }

=item warnings::warnif($object, $message)

Equivalent to:

    if (warnings::enabled($object))
      { warnings::warn($object, $message) }

=back

See L<perlmodlib/Pragmatic Modules> and L<perllexwarn>.

=cut

use Carp ;

%Offsets = (
    'all'		=> 0,
    'closure'		=> 2,
    'exiting'		=> 4,
    'glob'		=> 6,
    'io'		=> 8,
    'closed'		=> 10,
    'exec'		=> 12,
    'newline'		=> 14,
    'pipe'		=> 16,
    'unopened'		=> 18,
    'misc'		=> 20,
    'numeric'		=> 22,
    'once'		=> 24,
    'overflow'		=> 26,
    'pack'		=> 28,
    'portable'		=> 30,
    'recursion'		=> 32,
    'redefine'		=> 34,
    'regexp'		=> 36,
    'severe'		=> 38,
    'debugging'		=> 40,
    'inplace'		=> 42,
    'internal'		=> 44,
    'malloc'		=> 46,
    'signal'		=> 48,
    'substr'		=> 50,
    'syntax'		=> 52,
    'ambiguous'		=> 54,
    'bareword'		=> 56,
    'deprecated'	=> 58,
    'digit'		=> 60,
    'parenthesis'	=> 62,
    'precedence'	=> 64,
    'printf'		=> 66,
    'prototype'		=> 68,
    'qw'		=> 70,
    'reserved'		=> 72,
    'semicolon'		=> 74,
    'taint'		=> 76,
    'uninitialized'	=> 78,
    'unpack'		=> 80,
    'untie'		=> 82,
    'utf8'		=> 84,
    'void'		=> 86,
    'y2k'		=> 88,
  );

%Bits = (
    'all'		=> "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x01", # [0..44]
    'ambiguous'		=> "\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00", # [27]
    'bareword'		=> "\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00", # [28]
    'closed'		=> "\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [5]
    'closure'		=> "\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [1]
    'debugging'		=> "\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00", # [20]
    'deprecated'	=> "\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00", # [29]
    'digit'		=> "\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00", # [30]
    'exec'		=> "\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [6]
    'exiting'		=> "\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [2]
    'glob'		=> "\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [3]
    'inplace'		=> "\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00", # [21]
    'internal'		=> "\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00", # [22]
    'io'		=> "\x00\x55\x05\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [4..9]
    'malloc'		=> "\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00", # [23]
    'misc'		=> "\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [10]
    'newline'		=> "\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [7]
    'numeric'		=> "\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [11]
    'once'		=> "\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00", # [12]
    'overflow'		=> "\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00", # [13]
    'pack'		=> "\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00", # [14]
    'parenthesis'	=> "\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00", # [31]
    'pipe'		=> "\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [8]
    'portable'		=> "\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00", # [15]
    'precedence'	=> "\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00", # [32]
    'printf'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00", # [33]
    'prototype'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00", # [34]
    'qw'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00", # [35]
    'recursion'		=> "\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00", # [16]
    'redefine'		=> "\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00", # [17]
    'regexp'		=> "\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00", # [18]
    'reserved'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00", # [36]
    'semicolon'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00", # [37]
    'severe'		=> "\x00\x00\x00\x00\x40\x55\x00\x00\x00\x00\x00\x00", # [19..23]
    'signal'		=> "\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00", # [24]
    'substr'		=> "\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00", # [25]
    'syntax'		=> "\x00\x00\x00\x00\x00\x00\x50\x55\x55\x05\x00\x00", # [26..37]
    'taint'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00", # [38]
    'uninitialized'	=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00", # [39]
    'unopened'		=> "\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [9]
    'unpack'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00", # [40]
    'untie'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00", # [41]
    'utf8'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00", # [42]
    'void'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00", # [43]
    'y2k'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01", # [44]
  );

%DeadBits = (
    'all'		=> "\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\x02", # [0..44]
    'ambiguous'		=> "\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00", # [27]
    'bareword'		=> "\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00", # [28]
    'closed'		=> "\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [5]
    'closure'		=> "\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [1]
    'debugging'		=> "\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00", # [20]
    'deprecated'	=> "\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00", # [29]
    'digit'		=> "\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00", # [30]
    'exec'		=> "\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [6]
    'exiting'		=> "\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [2]
    'glob'		=> "\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [3]
    'inplace'		=> "\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00", # [21]
    'internal'		=> "\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00", # [22]
    'io'		=> "\x00\xaa\x0a\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [4..9]
    'malloc'		=> "\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00", # [23]
    'misc'		=> "\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [10]
    'newline'		=> "\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [7]
    'numeric'		=> "\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [11]
    'once'		=> "\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00", # [12]
    'overflow'		=> "\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00", # [13]
    'pack'		=> "\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00", # [14]
    'parenthesis'	=> "\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00", # [31]
    'pipe'		=> "\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [8]
    'portable'		=> "\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00", # [15]
    'precedence'	=> "\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00", # [32]
    'printf'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00", # [33]
    'prototype'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00", # [34]
    'qw'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00", # [35]
    'recursion'		=> "\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00", # [16]
    'redefine'		=> "\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00", # [17]
    'regexp'		=> "\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00", # [18]
    'reserved'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00", # [36]
    'semicolon'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00", # [37]
    'severe'		=> "\x00\x00\x00\x00\x80\xaa\x00\x00\x00\x00\x00\x00", # [19..23]
    'signal'		=> "\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00", # [24]
    'substr'		=> "\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00", # [25]
    'syntax'		=> "\x00\x00\x00\x00\x00\x00\xa0\xaa\xaa\x0a\x00\x00", # [26..37]
    'taint'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00", # [38]
    'uninitialized'	=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00", # [39]
    'unopened'		=> "\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [9]
    'unpack'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00", # [40]
    'untie'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00", # [41]
    'utf8'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00", # [42]
    'void'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00", # [43]
    'y2k'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02", # [44]
  );

$NONE     = "\0\0\0\0\0\0\0\0\0\0\0\0";
$LAST_BIT = 90 ;
$BYTES    = 12 ;

$All = "" ; vec($All, $Offsets{'all'}, 2) = 3 ;

sub bits {
    my $mask ;
    my $catmask ;
    my $fatal = 0 ;
    foreach my $word (@_) {
	if  ($word eq 'FATAL') {
	    $fatal = 1;
	}
	elsif ($catmask = $Bits{$word}) {
	    $mask |= $catmask ;
	    $mask |= $DeadBits{$word} if $fatal ;
	}
	else
          { croak("unknown warnings category '$word'")}
    }

    return $mask ;
}

sub import {
    shift;
    my $mask = ${^WARNING_BITS} ;
    if (vec($mask, $Offsets{'all'}, 1)) {
        $mask |= $Bits{'all'} ;
        $mask |= $DeadBits{'all'} if vec($mask, $Offsets{'all'}+1, 1);
    }
    ${^WARNING_BITS} = $mask | bits(@_ ? @_ : 'all') ;
}

sub unimport {
    shift;
    my $mask = ${^WARNING_BITS} ;
    if (vec($mask, $Offsets{'all'}, 1)) {
        $mask |= $Bits{'all'} ;
        $mask |= $DeadBits{'all'} if vec($mask, $Offsets{'all'}+1, 1);
    }
    ${^WARNING_BITS} = $mask & ~ (bits(@_ ? @_ : 'all') | $All) ;
}

sub __chk
{
    my $category ;
    my $offset ;
    my $isobj = 0 ;

    if (@_) {
        # check the category supplied.
        $category = shift ;
        if (ref $category) {
            croak ("not an object")
                if $category !~ /^([^=]+)=/ ;+
	    $category = $1 ;
            $isobj = 1 ;
        }
        $offset = $Offsets{$category};
        croak("unknown warnings category '$category'")
	    unless defined $offset;
    }
    else {
        $category = (caller(1))[0] ;
        $offset = $Offsets{$category};
        croak("package '$category' not registered for warnings")
	    unless defined $offset ;
    }

    my $this_pkg = (caller(1))[0] ;
    my $i = 2 ;
    my $pkg ;

    if ($isobj) {
        while (do { { package DB; $pkg = (caller($i++))[0] } } ) {
            last unless @DB::args && $DB::args[0] =~ /^$category=/ ;
        }
	$i -= 2 ;
    }
    else {
        for ($i = 2 ; $pkg = (caller($i))[0] ; ++ $i) {
            last if $pkg ne $this_pkg ;
        }
        $i = 2
            if !$pkg || $pkg eq $this_pkg ;
    }

    my $callers_bitmask = (caller($i))[9] ;
    return ($callers_bitmask, $offset, $i) ;
}

sub enabled
{
    croak("Usage: warnings::enabled([category])")
	unless @_ == 1 || @_ == 0 ;

    my ($callers_bitmask, $offset, $i) = __chk(@_) ;

    return 0 unless defined $callers_bitmask ;
    return vec($callers_bitmask, $offset, 1) ||
           vec($callers_bitmask, $Offsets{'all'}, 1) ;
}


sub warn
{
    croak("Usage: warnings::warn([category,] 'message')")
	unless @_ == 2 || @_ == 1 ;

    my $message = pop ;
    my ($callers_bitmask, $offset, $i) = __chk(@_) ;
    local $Carp::CarpLevel = $i ;
    croak($message)
	if vec($callers_bitmask, $offset+1, 1) ||
	   vec($callers_bitmask, $Offsets{'all'}+1, 1) ;
    carp($message) ;
}

sub warnif
{
    croak("Usage: warnings::warnif([category,] 'message')")
	unless @_ == 2 || @_ == 1 ;

    my $message = pop ;
    my ($callers_bitmask, $offset, $i) = __chk(@_) ;
    local $Carp::CarpLevel = $i ;

    return
        unless defined $callers_bitmask &&
            	(vec($callers_bitmask, $offset, 1) ||
            	vec($callers_bitmask, $Offsets{'all'}, 1)) ;

    croak($message)
	if vec($callers_bitmask, $offset+1, 1) ||
	   vec($callers_bitmask, $Offsets{'all'}+1, 1) ;

    carp($message) ;
}
1;
