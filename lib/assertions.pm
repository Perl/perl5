package assertions;

our $VERSION = '0.01';

# use strict;
# use warnings;

my $hint=0x01000000;
my $seen_hint=0x02000000;

sub syntax_error ($$) {
    my ($expr, $why)=@_;
    require Carp;
    Carp::croak("syntax error on assertion filter '$expr' ($why)");
}

sub my_warn ($) {
    my $error=shift;
    require warnings;
    if (warnings::enabled('assertions')) {
	require Carp;
	Carp::carp($error);
    }
}

sub calc_expr {
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
		    and syntax_error $expr, 'consecutive operators';
		$op[0]='||';
	    }
	    elsif ($t eq '&&') {
		defined $op[0]
		    and syntax_error $expr, 'consecutive operators';
		$op[0]='&&';
	    }
	    else {
		if ($t eq ')') {
		    @now==1 and
			syntax_error $expr, 'unbalanced parens';
		    defined $op[0] and
			syntax_error $expr, "key missing after operator '$op[0]'";

		    $t=shift @now;
		    shift @op;
		}
		elsif ($t eq '_') {
		    unless ($^H & $seen_hint) {
			my_warn "assertion status '_' referenced but not previously defined";
		    }
		    $t=($^H & $hint) ? 1 : 0;
		}
		elsif ($t ne '0' and $t ne '1') {
		    # print STDERR "'$t' resolved as ";
		    $t=grep ({ $t=~$_ } @{^ASSERTING}) ? 1 : 0;
		    # print STDERR "$t\n";
		}

		defined $op[0] or
		    syntax_error $expr, 'operator expected';

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
    @now==1 or syntax_error $expr, 'unbalanced parens';
    defined $op[0] and syntax_error $expr, "expression ends on operator '$op[0]'";

    return $now[0];
}


sub import {
    # print STDERR "\@_=", join("|", @_), "\n";
    shift;
    @_=(scalar(caller)) unless @_;
    foreach my $expr (@_) {
	unless (calc_expr $expr) {
	    # print STDERR "assertions deactived";
	    $^H &= ~$hint;
	    $^H |= $seen_hint;
	    return;
	}
    }
    # print STDERR "assertions actived";
    $^H |= $hint|$seen_hint;
}

sub unimport {
    $^H &= ~$hint;
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
      use assertions ' _ && bar ';
      assert { print "asserting 'foo' && 'bar'\n" };
  }

  assert { print "asserting 'foo' again\n" };

=head1 DESCRIPTION

The C<assertions> pragma specifies the tags used to enable and disable
the execution of assertion subroutines.

An assertion subroutine is declared with the C<:assertion> attribute.
This subroutine is not normally executed : it's optimized away by perl
at compile-time.

The C<assertion> pragma associates to its lexical scope one or several
assertion tags. Then, to activate the execution of the assertions
subroutines in this scope, these tags must be given to perl via the
B<-A> command-line option.

=head1 SEE ALSO

L<perlrun>.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Salvador FandiE<ntilde>o

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

TODO : Some more docs are to be added about assertion expressions.
