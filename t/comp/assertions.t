#!./perl

BEGIN { $^W=0 }

use base 'assertions::compat';

sub callme ($ ) : assertion {
    return shift;
}

# select STDERR; $|=1;

my @expr=( '1' => 1,
	   '0' => 0,
	   '1 && 1' => 1,
	   '1 && 0' => 0,
	   '0 && 1' => 0,
	   '0 && 0' => 0,
	   '1 || 1' => 1,
	   '1 || 0' => 1,
	   '0 || 1' => 1,
	   '0 || 0' => 0,
	   '(1)' => 1,
	   '(0)' => 0,
	   '1 && ((1) && 1)' => 1,
	   '1 && (0 || 1)' => 1,
	   '1 && ( 0' => undef,
	   '1 &&' => undef,
	   '&& 1' => undef,
	   '1 && || 1' => undef,
	   '(1 && 1) && 1)' => undef,
	   'one && two' => 1,
	   '_ && one' => 0,
	   'one && three' => 0,
	   '1 ' => 1,
	   ' 1' => 1,
	   ' 1 ' => 1,
	   ' ( 1 && 1 ) ' => 1,
	   ' ( 1 && 0 ) ' => 0,
	   '(( 1 && 1) && ( 1 || 0)) || _ && one && ( one || three)' => 1 );

my $supported = assertions::compat::supported();

my $n=@expr/2 + ($supported ? 12 : 0);
my $i=1;
print "1..$n\n";

use assertions::activate 'one', 'two';
require assertions;

while (@expr) {
    my $expr=shift @expr;
    my $expected=shift @expr;
    my $result=eval {assertions::_calc_expr($expr)};
    if (defined $expected) {
	unless (defined $result and $result == $expected) {
	    print STDERR "assertions::_calc_expr($expr) failed,".
		" expected '$expected' but '$result' obtained (\$@=$@)\n";
	    print "not ";
	}
    }
    else {
	if (defined $result) {
	    print STDERR "assertions::_calc_expr($expr) failed,".
		" expected undef but '$result' obtained\n";
	    print "not ";
	}
    }
    print "ok ", $i++, "\n";
}

if ($supported) {

    # @expr/2+1
    if (callme(1)) {
	print STDERR "assertions called by default\n";
	print "not ";
    }
    print "ok ", $i++, "\n";
    
    # 2
    use assertions::activate 'mine';
    {
	package mine;
	use base 'assertions::compat';
	sub callme ($) : assertion {
	    return shift;
	}
	    use assertions;
	unless (callme(1)) {
	    print STDERR "'use assertions;' doesn't active assertions based on package name\n";
	    print "not ";
	}
    }
    print "ok ", $i++, "\n";
    
    # 3
    use assertions 'foo';
    if (callme(1)) {
	print STDERR "assertion deselection doesn't work\n";
	print "not ";
    }
    print "ok ", $i++, "\n";
    
    # 4
    use assertions::activate 'bar', 'doz';
    use assertions 'bar';
    unless (callme(1)) {
	print STDERR "assertion selection doesn't work\n";
	print "not ";
    }
    print "ok ", $i++, "\n";
    
    # 5
    use assertions q(_ && doz);
    unless (callme(1)) {
	print STDERR "assertion activation filtering doesn't work\n";
	print "not ";
    }
    print "ok ", $i++, "\n";
    
    # 6
    use assertions q(_ && foo);
    if (callme(1)) {
	print STDERR "assertion deactivation filtering doesn't work\n";
	print "not ";
    }
    print "ok ", $i++, "\n";
    
    # 7
    if (1) {
	use assertions 'bar';
    }
    if (callme(1)) {
	print STDERR "assertion scoping doesn't work\n";
	print "not ";
    }
    print "ok ", $i++, "\n";

    # 8
    use assertions::activate 're.*';
    use assertions 'reassert';
    unless (callme(1)) {
	print STDERR "assertion selection with re failed\n";
	print "not ";
    }
    print "ok ", $i++, "\n";

    # 9
    my $b=12;
    {
	use assertions 'bar';
	callme(my $b=45);
	unless ($b == 45) {
	    print STDERR "this shouldn't fail ever (b=$b)\n";
	    print "not ";
	}
    }
    print "ok ", $i++, "\n";

    # 10
    {
	no assertions;
	callme(my $b=46);
	if (defined $b) {
	    print STDERR "lexical declaration in assertion arg ignored (b=$b\n";
	    print "not ";
	}
    }
    print "ok ", $i++, "\n";

    # 11
    {
        use assertions::activate sub { return 1 if $_[0] eq 'via_sub' };
	use assertions 'via_sub';
	callme(my $b=47);
	unless ($b == 47) {
	    print STDERR "this shouldn't fail ever (b=$b)\n";
	    print "not ";
	}
    }
    print "ok ", $i++, "\n";

    # 12
    {
	use assertions 'not_asserted';
	callme(my $b=48);
	if ($b == 48) {
	    print STDERR "this shouldn't fail ever (b=$b)\n";
	    print "not ";
	}
    }
    print "ok ", $i++, "\n";
}
