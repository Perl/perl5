#!./perl -w

# Tests for the coderef-in-@INC feature

BEGIN {
  chdir 't' if -d 't';
  @INC = '../lib';
}
use Config;
unless ($Config{useperlio}) {
  print "1..0 # Skipping (tests are implemented using perlio features, this perl uses stdio)\n";
  exit 0;
}

print "1..12\n";

sub fooinc {
    my ($self, $filename) = @_;
    if (substr($filename,0,3) eq 'Foo') {
	open my $fh, '<', \("package ".substr($filename,0,-3)."; 1;");
	return $fh;
    }
    else {
	return undef;
    }
}

push @INC, \&fooinc;

print "not " if eval { require Bar };
print "ok 1\n";
print "not " if ! eval { require Foo }  or ! exists $INC{'Foo.pm'};
print "ok 2\n";
print "not " if ! eval "use Foo1; 1;"   or ! exists $INC{'Foo1.pm'};
print "ok 3\n";
print "not " if ! eval { do 'Foo2.pl' } or ! exists $INC{'Foo2.pl'};
print "ok 4\n";

pop @INC;

sub fooinc2 {
    my ($self, $filename) = @_;
    if (substr($filename, 0, length($self->[1])) eq $self->[1]) {
	open my $fh, '<', \("package ".substr($filename,0,-3)."; 1;");
	return $fh;
    }
    else {
	return undef;
    }
}

push @INC, [ \&fooinc2, 'Bar' ];

print "not " if ! eval { require Foo }; # Already loaded
print "ok 5\n";
print "not " if eval { require Foo3 };
print "ok 6\n";
print "not " if ! eval { require Bar }  or ! exists $INC{'Bar.pm'};
print "ok 7\n";
print "not " if ! eval "use Bar1; 1;"   or ! exists $INC{'Bar1.pm'};
print "ok 8\n";
print "not " if ! eval { do 'Bar2.pl' } or ! exists $INC{'Bar2.pl'};
print "ok 9\n";

pop @INC;

sub FooLoader::INC {
    my ($self, $filename) = @_;
    if (substr($filename,0,4) eq 'Quux') {
	open my $fh, '<', \("package ".substr($filename,0,-3)."; 1;");
	return $fh;
    }
    else {
	return undef;
    }
}

push @INC, bless( {}, 'FooLoader' );

print "not " if ! eval { require Quux } or ! exists $INC{'Quux.pm'};
print "ok 10\n";

pop @INC;

push @INC, bless( [], 'FooLoader' );

print "not " if ! eval { require Quux1 } or ! exists $INC{'Quux1.pm'};
print "ok 11\n";

pop @INC;

push @INC, bless( \(my $x = 1), 'FooLoader' );

print "not " if ! eval { require Quux2 } or ! exists $INC{'Quux2.pm'};
print "ok 12\n";
