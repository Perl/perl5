#!./perl -w

# Tests for the coderef-in-@INC feature

BEGIN {
    chdir 't' if -d 't';
    @INC = qw(. ../lib);
}

use File::Spec;

require "test.pl";
plan(tests => 39);

my @tempfiles = ();

sub get_temp_fh {
    my $f = "DummyModule0000";
    1 while -e ++$f;
    push @tempfiles, $f;
    open my $fh, ">$f" or die "Can't create $f: $!";
    print $fh "package ".substr($_[0],0,-3)."; 1;";
    close $fh;
    open $fh, $f or die "Can't open $f: $!";
    return $fh;
}

END { 1 while unlink @tempfiles }

sub fooinc {
    my ($self, $filename) = @_;
    if (substr($filename,0,3) eq 'Foo') {
	return get_temp_fh($filename);
    }
    else {
        return undef;
    }
}

push @INC, \&fooinc;

ok( !eval { require Bar; 1 },      'Trying non-magic package' );

ok( eval { require Foo; 1 },       'require() magic via code ref'  ); 
ok( exists $INC{'Foo.pm'},         '  %INC sees it' );
is( ref $INC{'Foo.pm'}, 'CODE',    '  key is a coderef in %INC' );
is( $INC{'Foo.pm'}, \&fooinc,	   '  key is correct in %INC' );

ok( eval "use Foo1; 1;",           'use()' );  
ok( exists $INC{'Foo1.pm'},        '  %INC sees it' );
is( ref $INC{'Foo1.pm'}, 'CODE',   '  key is a coderef in %INC' );
is( $INC{'Foo1.pm'}, \&fooinc,     '  key is correct in %INC' );

ok( eval { do 'Foo2.pl'; 1 },      'do()' ); 
ok( exists $INC{'Foo2.pl'},        '  %INC sees it' );
is( ref $INC{'Foo2.pl'}, 'CODE',   '  key is a coderef in %INC' );
is( $INC{'Foo2.pl'}, \&fooinc,     '  key is correct in %INC' );

pop @INC;


sub fooinc2 {
    my ($self, $filename) = @_;
    if (substr($filename, 0, length($self->[1])) eq $self->[1]) {
	return get_temp_fh($filename);
    }
    else {
        return undef;
    }
}

my $arrayref = [ \&fooinc2, 'Bar' ];
push @INC, $arrayref;

ok( eval { require Foo; 1; },     'Originally loaded packages preserved' );
ok( !eval { require Foo3; 1; },   'Original magic INC purged' );

ok( eval { require Bar; 1 },      'require() magic via array ref' );
ok( exists $INC{'Bar.pm'},        '  %INC sees it' );
is( ref $INC{'Bar.pm'}, 'ARRAY',  '  key is an arrayref in %INC' );
is( $INC{'Bar.pm'}, $arrayref,    '  key is correct in %INC' );

ok( eval "use Bar1; 1;",          'use()' );
ok( exists $INC{'Bar1.pm'},       '  %INC sees it' );
is( ref $INC{'Bar1.pm'}, 'ARRAY', '  key is an arrayref in %INC' );
is( $INC{'Bar1.pm'}, $arrayref,   '  key is correct in %INC' );

ok( eval { do 'Bar2.pl'; 1 },     'do()' );
ok( exists $INC{'Bar2.pl'},       '  %INC sees it' );
is( ref $INC{'Bar2.pl'}, 'ARRAY', '  key is an arrayref in %INC' );
is( $INC{'Bar2.pl'}, $arrayref,   '  key is correct in %INC' );

pop @INC;

sub FooLoader::INC {
    my ($self, $filename) = @_;
    if (substr($filename,0,4) eq 'Quux') {
	return get_temp_fh($filename);
    }
    else {
        return undef;
    }
}

my $href = bless( {}, 'FooLoader' );
push @INC, $href;

ok( eval { require Quux; 1 },      'require() magic via hash object' );
ok( exists $INC{'Quux.pm'},        '  %INC sees it' );
is( ref $INC{'Quux.pm'}, 'FooLoader',
				   '  key is an object in %INC' );
is( $INC{'Quux.pm'}, $href,        '  key is correct in %INC' );

pop @INC;

my $aref = bless( [], 'FooLoader' );
push @INC, $aref;

ok( eval { require Quux1; 1 },     'require() magic via array object' );
ok( exists $INC{'Quux1.pm'},       '  %INC sees it' );
is( ref $INC{'Quux1.pm'}, 'FooLoader',
				   '  key is an object in %INC' );
is( $INC{'Quux1.pm'}, $aref,       '  key is correct in %INC' );

pop @INC;

my $sref = bless( \(my $x = 1), 'FooLoader' );
push @INC, $sref;

ok( eval { require Quux2; 1 },     'require() magic via scalar object' );
ok( exists $INC{'Quux2.pm'},       '  %INC sees it' );
is( ref $INC{'Quux2.pm'}, 'FooLoader',
				   '  key is an object in %INC' );
is( $INC{'Quux2.pm'}, $sref,       '  key is correct in %INC' );

pop @INC;
