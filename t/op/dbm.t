#!./perl

BEGIN {
    chdir 't';
    @INC = '../lib';
    require './test.pl';

    eval { require AnyDBM_File }; # not all places have dbm* functions
      skip_all("No dbm functions: $@") if $@;
}

plan tests => 4;

# This is [20020104.007] "coredump on dbmclose"

my $prog = <<'EOC';
package Foo;
sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = {};
        bless($self,$class);
        my %LT;
        dbmopen(%LT, "dbmtest", 0666) ||
	    die "Can't open dbmtest because of $!\n";
        $self->{'LT'} = \%LT;
        return $self;
}
sub DESTROY {
        my $self = shift;
	dbmclose(%{$self->{'LT'}});
	1 while unlink 'dbmtest';
	1 while unlink <dbmtest.*>;
	print "ok\n";
}
package main;
$test = Foo->new(); # must be package var
EOC

fresh_perl_is("require AnyDBM_File;\n$prog", 'ok', {}, 'explict require');
fresh_perl_is($prog, 'ok', {}, 'implicit require');

$prog = <<'EOC';
@INC = ();
dbmopen(%LT, "dbmtest", 0666);
1 while unlink 'dbmtest';
1 while unlink <dbmtest.*>;
die "Failed to fail!";
EOC

fresh_perl_like($prog, qr/No dbm on this machine/, {},
		'implicit require fails');
fresh_perl_like('delete $::{"AnyDBM_File::"}; ' . $prog,
		qr/No dbm on this machine/, {},
		'implicit require and no stash fails');
