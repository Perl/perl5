package FOOBAR;

require Exporter;
@ISA = (Exporter);
@EXPORT = (foo, bar);

sub foo { print "FOO\n" };
sub bar { print "BAR\n" };

1;
