
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
    'octmode'		=> 24,
    'chmod'		=> 26,
    'mkdir'		=> 28,
    'umask'		=> 30,
    'once'		=> 32,
    'overflow'		=> 34,
    'pack'		=> 36,
    'portable'		=> 38,
    'recursion'		=> 40,
    'redefine'		=> 42,
    'regexp'		=> 44,
    'severe'		=> 46,
    'debugging'		=> 48,
    'inplace'		=> 50,
    'internal'		=> 52,
    'malloc'		=> 54,
    'signal'		=> 56,
    'substr'		=> 58,
    'syntax'		=> 60,
    'ambiguous'		=> 62,
    'bareword'		=> 64,
    'deprecated'	=> 66,
    'digit'		=> 68,
    'parenthesis'	=> 70,
    'precedence'	=> 72,
    'printf'		=> 74,
    'prototype'		=> 76,
    'qw'		=> 78,
    'reserved'		=> 80,
    'semicolon'		=> 82,
    'taint'		=> 84,
    'uninitialized'	=> 86,
    'unpack'		=> 88,
    'untie'		=> 90,
    'utf8'		=> 92,
    'void'		=> 94,
    'y2k'		=> 96,
  );

%Bits = (
    'all'		=> "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x01", # [0..48]
    'ambiguous'		=> "\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00", # [31]
    'bareword'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00", # [32]
    'chmod'		=> "\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [13]
    'closed'		=> "\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [5]
    'closure'		=> "\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [1]
    'debugging'		=> "\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00", # [24]
    'deprecated'	=> "\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00", # [33]
    'digit'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00", # [34]
    'exec'		=> "\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [6]
    'exiting'		=> "\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [2]
    'glob'		=> "\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [3]
    'inplace'		=> "\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00", # [25]
    'internal'		=> "\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00", # [26]
    'io'		=> "\x00\x55\x05\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [4..9]
    'malloc'		=> "\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00", # [27]
    'misc'		=> "\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [10]
    'mkdir'		=> "\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [14]
    'newline'		=> "\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [7]
    'numeric'		=> "\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [11]
    'octmode'		=> "\x00\x00\x00\x55\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [12..15]
    'once'		=> "\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00", # [16]
    'overflow'		=> "\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00", # [17]
    'pack'		=> "\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00", # [18]
    'parenthesis'	=> "\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00", # [35]
    'pipe'		=> "\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [8]
    'portable'		=> "\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00", # [19]
    'precedence'	=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00", # [36]
    'printf'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00", # [37]
    'prototype'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00", # [38]
    'qw'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00", # [39]
    'recursion'		=> "\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00", # [20]
    'redefine'		=> "\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00", # [21]
    'regexp'		=> "\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00", # [22]
    'reserved'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00", # [40]
    'semicolon'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00", # [41]
    'severe'		=> "\x00\x00\x00\x00\x00\x40\x55\x00\x00\x00\x00\x00\x00", # [23..27]
    'signal'		=> "\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00", # [28]
    'substr'		=> "\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00", # [29]
    'syntax'		=> "\x00\x00\x00\x00\x00\x00\x00\x50\x55\x55\x05\x00\x00", # [30..41]
    'taint'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00", # [42]
    'umask'		=> "\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [15]
    'uninitialized'	=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00", # [43]
    'unopened'		=> "\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [9]
    'unpack'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00", # [44]
    'untie'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00", # [45]
    'utf8'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00", # [46]
    'void'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00", # [47]
    'y2k'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01", # [48]
  );

%DeadBits = (
    'all'		=> "\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\x02", # [0..48]
    'ambiguous'		=> "\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00", # [31]
    'bareword'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00", # [32]
    'chmod'		=> "\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [13]
    'closed'		=> "\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [5]
    'closure'		=> "\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [1]
    'debugging'		=> "\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00", # [24]
    'deprecated'	=> "\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00", # [33]
    'digit'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00", # [34]
    'exec'		=> "\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [6]
    'exiting'		=> "\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [2]
    'glob'		=> "\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [3]
    'inplace'		=> "\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00", # [25]
    'internal'		=> "\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00", # [26]
    'io'		=> "\x00\xaa\x0a\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [4..9]
    'malloc'		=> "\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00", # [27]
    'misc'		=> "\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [10]
    'mkdir'		=> "\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [14]
    'newline'		=> "\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [7]
    'numeric'		=> "\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [11]
    'octmode'		=> "\x00\x00\x00\xaa\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [12..15]
    'once'		=> "\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00", # [16]
    'overflow'		=> "\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00", # [17]
    'pack'		=> "\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00", # [18]
    'parenthesis'	=> "\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00", # [35]
    'pipe'		=> "\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [8]
    'portable'		=> "\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00", # [19]
    'precedence'	=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00", # [36]
    'printf'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00", # [37]
    'prototype'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00", # [38]
    'qw'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00", # [39]
    'recursion'		=> "\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00", # [20]
    'redefine'		=> "\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00", # [21]
    'regexp'		=> "\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00", # [22]
    'reserved'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00", # [40]
    'semicolon'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00", # [41]
    'severe'		=> "\x00\x00\x00\x00\x00\x80\xaa\x00\x00\x00\x00\x00\x00", # [23..27]
    'signal'		=> "\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00", # [28]
    'substr'		=> "\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00", # [29]
    'syntax'		=> "\x00\x00\x00\x00\x00\x00\x00\xa0\xaa\xaa\x0a\x00\x00", # [30..41]
    'taint'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00", # [42]
    'umask'		=> "\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [15]
    'uninitialized'	=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00", # [43]
    'unopened'		=> "\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", # [9]
    'unpack'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00", # [44]
    'untie'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00", # [45]
    'utf8'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00", # [46]
    'void'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00", # [47]
    'y2k'		=> "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02", # [48]
  );

$NONE     = "\0\0\0\0\0\0\0\0\0\0\0\0\0";
$LAST_BIT = 98 ;
$BYTES    = 13 ;

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
