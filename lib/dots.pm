package dots;
use strict;

our $VERSION = '1.00';

our $enable_bit = 0x00000001;
our $mixed_bit  = 0x00000002;

sub import {
    shift;
    $^H{dots} = $enable_bit;
    while (@_) {
        local $_ = shift;
        if ($_ eq 'mixed') {
            $^H{dots} |= $mixed_bit;
        }
        else {
            require Carp;
            Carp::croak("dots: unknown subpragma '$_'");
        }
    }
}

sub unimport {
    shift;
    my $mask;
    while (@_) {
        local $_ = shift;
        if ($_ eq 'mixed') {
            $mask = $mixed_bit;
        }
        else {
            require Carp;
            Carp::croak("dots: unknown subpragma '$_'");
        }
    }
    if (defined $mask) {
        $^H{dots} &= ~$mask;
    }
    else {
        delete $^H{dots};
    }
}

'dot dot dot';
__END__

=head1 NAME

dots - perl pragma to use dots to follow references and call methods

=head1 SYNOPSIS

    use dots;                   # '.' follows refs; '~' is concat

    my $obj = Foo.new(...);     # call class method
    $obj.method;                # call object method
    my $href = { a => 1 };
    $href.{a};                  # follow hash ref
    my $aref = [ sub {...} ];
    $aref.[0].(@args);          # follow array ref; call code

    say "hello" ~ " world";     # '~' concatenates strings

    say $a->[0];                # '->' is not allowed by default
    use dots 'mixed';
    say $a->[0];                # allow '->' explicitly

    no dots 'mixed';            # disallow '->' again

    no dots;                    # back to Perl defaults again

=head1 DESCRIPTION

With the C<dots> pragma you can switch out Perl's '->' operator for the much
easier to type, easier to read, and industry standard '.' operator.  It does
everything '->' usually does in following references and calling methods.

The '~' binary operator, previously unused, becomes string concatenation.

By default, C<use dots> forbids using '->'.  This is important for
readability; seeing an arrow should be a reliable sign that C<use dots> is
off and '.' does string concatenation.  It also leaves open that '->' can be
repurposed someday.  But if you really want to mix arrows and dots, this is
supported; just write C<use dots 'mixed'>.

To undo C<use dots 'mixed'>, write C<no dots 'mixed'>.

To turn off dots, write C<no dots>.

=head1 CAVEATS

This pragma is lexically scoped and only has effect at compile time.
Decompilers like C<-MO=Deparse> will generate the arrow version until
someone teaches them to write dots instead (hint hint).

=cut
