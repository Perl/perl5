package assertions;

our $VERSION = '0.01';

# use strict;
# use warnings;

my $hint=0x01000000;

sub syntax_error ($$) {
    my ($expr, $why)=@_;
    require Carp;
    Carp::croak("syntax error on assertion filter '$expr' ($why)");
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
	    elsif (!defined $t or $t eq '') {
		# warn "empty token";
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
	    return;
	}
    }
    # print STDERR "assertions actived";
    $^H |= $hint;
}




sub unimport {
    $^H &= ~$hint;
}

1;
__END__


=head1 NAME

assertions - selects assertions

=head1 SYNOPSIS

  sub assert (&) : assertion { &{$_[0]}() }

  use assertions 'foo';
  assert { print "asserting 'foo'\n" };

  {
      use assertions qw( foo bar );
      assert { print "asserting 'foo' & 'bar'\n" };
  }

  {
      use assertions qw( bar );
      assert { print "asserting 'bar'\n" };
  }

  {
      use assertions ' _ && bar ';
      assert { print "asserting 'foo' && 'bar'\n" };
  }

  assert { print "asserting 'foo' again\n" };


=head1 ABSTRACT

C<assertions> pragma selects the tags used to control assertion
execution.

=head1 DESCRIPTION




=head2 EXPORT

None by default.

=head1 SEE ALSO



=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Salvador FandiE<ntilde>o

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
