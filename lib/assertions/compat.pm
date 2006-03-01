package assertions::compat;

our $VERSION = '0.02';

require assertions;
our @ISA = qw(assertions);

sub _on () { 1 }
sub _off () { 0 }

sub import {
    my $class = shift;
    my $name = @_ ? shift : 'asserting';
    my $pkg = caller;
    $name =~ /::/ or $name = "${pkg}::${name}";
    @_ = $pkg unless @_;
    $class->SUPER::import(@_);
    my $enabled = assertions::enabled();
    {
	no strict 'vars';
	no warnings;
	undef &{$name};
	*{$name} = $enabled ? \&_on : \&_off;
    }
}

sub _compat_assertion_handler {
    shift; shift;
    grep $_ ne 'assertion', @_
}

sub _do_nothing_handler {}

# test if 'assertion' attribute is natively supported
my $assertion_ok=eval q{
    sub _my_asserting_test : assertion { 1 }
    _my_asserting_test()
};

*MODIFY_CODE_ATTRIBUTES =
    defined($assertion_ok)
    ? \&_do_nothing_handler
    : \&_compat_assertion_handler;

*supported =
    defined($assertion_ok)
    ? \&_on
    : \&_off;

unless (defined $assertion_ok) {
    package assertions;
    require warnings::register;
    warnings::register->import;
}


1;

__END__

=head1 NAME

assertions::compat - assertions for pre-5.9 versions of perl

=head1 SYNOPSIS

  # add support for 'assertion' attribute:
  use base 'assertions::compat';
  sub assert_foo : assertion { ... };

  # then, maybe in another module:
  package Foo::Bar;

  # define sub 'asserting' with the assertion status:
  use assertions::compat;
  asserting and assert_foo(1,2,3,4);

  # or
  use assertions::compat ASST => 'Foo::Bar::doz';
  ASST and assert_foo('dozpera');

=head1 DESCRIPTION

C<assertions::compat> allows to use assertions on perl versions prior
to 5.9.0 (that is the first one to natively support them). Though,
it's not magic, do not expect it to allow for conditionally executed
subroutines.

This module provides support for two different functionalities:

=head2 The C<assertion> attribute handler

The subroutine attribute C<assertion> is not recognised on perls
without assertion support. This module provides a
C<MODIFY_CODE_ATTRIBUTES> handler for this attribute. It must be used
via inheritance:

  use base 'assertions::compat';

  sub assert_foo : assertion { ... }

Be aware that the handler just discards the attribute, so subroutines
declared as assertions will be B<unconditionally> called on perl without
native support for them.

This module also provides the C<supported> function to check if
assertions are supported or not:

  my $supported = assertions::compat::supported();


=head2 Assertion execution status as a constant

C<assertions::compat> also allows to create constant subs whose value
is the assertion execution status. That allows checking explicitly and
efficiently when assertions have to be executed on perls without native
assertion support.

For instance...

  use assertions::compat ASST => 'Foo::Bar';

exports constant subroutine C<ASST>. Its value is true when assertions
tagged as C<Foo::Bar> has been activated via L<assertions::activate>;
usually done with the -A switch from the command line on perls
supporting it...

  perl -A=Foo::Bar my_script.pl

or alternatively with...

  perl -Massertions::activate=Foo::Bar my_script.pl

on pre-5.9.0 versions of perl.

The constant sub defined can be used following this idiom:

  use assertions::compat ASST => 'Foo::Bar';
  ...
  ASST and assert_foo();

When ASST is false, the perl interpreter optimizes away the rest of
the C<and> statement at compile time.


If no assertion selection tags are passed to C<use
assertions::compat>, the current module name is used as the selection
tag, so...

  use assertions::compat 'ASST';

is equivalent to...

  use assertions::compat ASST => __PACKAGE__;

If the name of the constant subroutine is also omitted, C<asserting>
is used.

This module will not emit a warning when the constant is redefined.
this is done on purpose to allow for code like that:

  use assertions::compat ASST => 'Foo';
  ASST and assert_foo();

  use assertions::compat ASST => 'Bar';
  ASST and assert_bar();

Finally, be aware that while assertion execution status is lexical
scoped, the defined constants are not. You should be careful on that
to not write inconsistent code. For instance...

  package Foo;

  use MyAssertions qw(assert_foo);

  use assertions::compat ASST => 'Foo::Out'
  {
    use assertions::compat ASST => 'Foo::In';
    ASST and assert_foo(); # ok!
  }

  ASST and assert_foo()   # bad usage!
  # ASST refers to tag Foo::In while assert_foo() is
  # called only when Foo::Out has been activated.
  # This is not what you want!!!


=head1 SEE ALSO

L<perlrun>, L<assertions>, L<assertions::activate>, L<attributes>.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Salvador FandiE<ntilde>o

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
