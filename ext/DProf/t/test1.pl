END { print "main:: the end\n" }
sub FOO::END { print "foo:: the end\n" }


sub foo {
	my $x;
	my $y;
	print "in sub foo\n";
	for( $x = 1; $x < 100; ++$x ){
		bar();
		for( $y = 1; $y < 100; ++$y ){
		}
	}
}

sub bar {
	my $x;
	print "in sub bar\n";
	for( $x = 1; $x < 100; ++$x ){
	}
}

sub baz {
	print "in sub baz\n";
	bar();
	foo();
}

bar();
baz();
foo();

