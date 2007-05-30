package assertions;

our $VERSION = '0.04';

# use strict;
# use warnings;

my $hint = 1;
my $seen_hint = 2;

sub _syntax_error ($$) {
    my ($expr, $why)=@_;
    require Carp;
    Carp::croak("syntax error on assertion filter '$expr' ($why)");
}

sub _carp {
    require warnings;
    if (warnings::enabled('assertions')) {
	require Carp;
	Carp::carp(@_);
    }
}

sub _calc_expr {
    my $expr=shift;
    my @tokens=split / \s*
		       ( &&     # and
		       | \|\|   # or
		       | \(     # parents
		       | \) )
		       \s*
		       | \s+    # spaces out
		     /x, $expr;

    # print STDERR "tokens: -", join('-',@tokens), "-\n";

    my @now=1;
    my @op='start';

    for my $t (@tokens) {
	next if (!defined $t or $t eq '');

	if ($t eq '(') {
	    unshift @now, 1;
	    unshift @op, 'start';
	}
	else {
	    if ($t eq '||') {
		defined $op[0]
		    and _syntax_error $expr, 'consecutive operators';
		$op[0]='||';
	    }
	    elsif ($t eq '&&') {
		defined $op[0]
		    and _syntax_error $expr, 'consecutive operators';
		$op[0]='&&';
	    }
	    else {
		if ($t eq ')') {
		    @now==1 and
			_syntax_error $expr, 'unbalanced parens';
		    defined $op[0] and
			_syntax_error $expr, "key missing after operator '$op[0]'";

		    $t=shift @now;
		    shift @op;
		}
		elsif ($t eq '_') {
		    unless ($^H{assertions} & $seen_hint) {
			_carp "assertion status '_' referenced but not previously defined";
		    }
		    $t=($^H{assertions} & $hint) ? 1 : 0;
		}
		elsif ($t ne '0' and $t ne '1') {
		    $t = ( grep { re::is_regexp($_)
				      ? $t=~$_
				      : $_->($t)
				} @{^ASSERTING} ) ? 1 : 0;
		}

		defined $op[0] or
		    _syntax_error $expr, 'operator expected';

		if ($op[0] eq 'start') {
		    $now[0]=$t;
		}
		elsif ($op[0] eq '||') {
		    $now[0]||=$t;
		}
		else {
		    $now[0]&&=$t;
		}
		undef $op[0];
	    }
	}
    }
    @now==1 or _syntax_error $expr, 'unbalanced parens';
    defined $op[0] and _syntax_error $expr, "expression ends on operator '$op[0]'";

    return $now[0];
}


sub import {
    # print STDERR "\@_=", join("|", @_), "\n";
    shift;
    @_=(scalar(caller)) unless @_;
    foreach my $expr (@_) {
	unless (_calc_expr $expr) {
	    # print STDERR "assertions deactived";
	    $^H{assertions} &= ~$hint;
	    $^H{assertions} |= $seen_hint;
	    return;
	}
    }
    # print STDERR "assertions actived";
    $^H{assertions} |= $hint|$seen_hint;
}

sub unimport {
    @_ > 1
	and _carp($_[0]."->unimport arguments are being ignored");
    $^H{assertions} &= ~$hint;
}

sub enabled {
    if (@_) {
	if ($_[0]) {
	    $^H{assertions} |= $hint;
	}
	else {
	    $^H{assertions} &= ~$hint;
	}
	$^H{assertions} |= $seen_hint;
    }
    return $^H{assertions} & $hint ? 1 : 0;
}

sub seen {
    if (@_) {
	if ($_[0]) {
	    $^H{assertions} |= $seen_hint;
	}
	else {
	    $^H{assertions} &= ~$seen_hint;
	}
    }
    return $^H{assertions} & $seen_hint ? 1 : 0;
}

1;

__END__


=head1 NAME

assertions - select assertions in blocks of code

=head1 SYNOPSIS

  sub assert (&) : assertion { &{$_[0]}() }

  use assertions 'foo';
  assert { print "asserting 'foo'\n" };

  {
      use assertions qw( foo bar );
      assert { print "asserting 'foo' and 'bar'\n" };
  }

  {
      use assertions qw( bar );
      assert { print "asserting only 'bar'\n" };
  }

  {
      use assertions '_ && bar';
      assert { print "asserting 'foo' && 'bar'\n" };
  }

  assert { print "asserting 'foo' again\n" };

=head1 DESCRIPTION

  *** WARNING: assertion support is only available from perl version
  *** 5.9.0 and upwards. Check assertions::compat (also available from
  *** this package) for an alternative backwards compatible module.

The C<assertions> pragma specifies the tags used to enable and disable
the execution of assertion subroutines.

An assertion subroutine is declared with the C<:assertion> attribute.
This subroutine is not normally executed: it's optimized away by perl
at compile-time.

The C<assertions> pragma associates to its lexical scope one or
several assertion tags. Then, to activate the execution of the
assertions subroutines in this scope, these tags must be given to perl
via the B<-A> command-line option. For instance, if...

  use assertions 'foobar';

is used, assertions on the same lexical scope will only be executed
when perl is called as...

  perl -A=foobar script.pl

Regular expressions can also be used within the -A
switch. For instance...

  perl -A='foo.*' script.pl

will activate assertions tagged as C<foo>, C<foobar>, C<foofoo>, etc.

=head2 Selecting assertions

Selecting which tags are required to activate assertions inside a
lexical scope, is done with the arguments passed on the C<use
assertions> sentence.

If no arguments are given, the package name is used as the assertion tag:

  use assertions;

is equivalent to

  use assertions __PACKAGE__;

When several tags are given, all of them have to be activated via the
C<-A> switch to activate assertion execution on that lexical scope,
i.e.:

  use assertions qw(Foo Bar);

Constants C<1> and C<0> can be used to force unconditional activation
or deactivation respectively:

  use assertions '0';
  use assertions '1';

Operators C<&&> and C<||> and parenthesis C<(...)> can be used to
construct logical expressions:

  use assertions 'foo && bar';
  use assertions 'foo || bar';
  use assertions 'foo && (bar || doz)';

(note that the logical operators and the parens have to be included
inside the quoted string).

Finally, the special tag C<_> refers to the current assertion
activation state:

  use assertions 'foo';
  use assertions '_ && bar;

is equivalent to

  use assertions 'foo && bar';

=head2 Handling assertions your own way

The C<assertions> module also provides a set of low level functions to
allow for custom assertion handling modules.

Those functions are not exported and have to be fully qualified with
the package name when called, for instance:

  require assertions;
  assertions::enabled(1);

(note that C<assertions> is loaded with the C<require> keyword
to avoid calling C<assertions::import()>).

Those functions have to be called at compile time (they are
useless at runtime).

=over 4

=item enabled($on)

activates or deactivates assertion execution. For instance:

  package assertions::always;

  require assertions;
  sub import { assertions::enabled(1) }

  1;

This function calls C<assertion::seen(1)> also (see below).

=item enabled()

returns a true value when assertion execution is active.

=item seen($on)

A warning is generated when an assertion subroutine is found before
any assertion selection code. This function is used to just tell perl
that assertion selection code has been seen and that the warning is
not required for the currently compiling lexical scope.

=item seen()

returns true if any assertion selection module (or code) has been
called before on the currently compiling lexical scope.

=back

=head1 COMPATIBILITY

Support for assertions is only available in perl from version 5.9. On
previous perl versions this module will do nothing, though it will not
harm either.

L<assertions::compat> provides an alternative way to use assertions
compatible with lower versions of perl.


=head1 SEE ALSO

L<perlrun>, L<assertions::activate>, L<assertions::compat>.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002, 2005 by Salvador FandiE<ntilde>o

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
