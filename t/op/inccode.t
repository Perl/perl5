#!./perl -wT

# Tests for the coderef-in-@INC feature

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use File::Spec;
use Test::More tests => 30;

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

sub get_addr {
    my $str = shift;
    $str =~ /(0x[0-9a-f]+)/i;
    return $1;
}

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
is( get_addr($INC{'Foo.pm'}), get_addr(\&fooinc),
				   '  key is correct in %INC' );

ok( eval "use Foo1; 1;",           'use()' );  
ok( exists $INC{'Foo1.pm'},        '  %INC sees it' );
is( get_addr($INC{'Foo1.pm'}), get_addr(\&fooinc),
				   '  key is correct in %INC' );

ok( eval { do 'Foo2.pl'; 1 },      'do()' ); 
ok( exists $INC{'Foo2.pl'},        '  %INC sees it' );
is( get_addr($INC{'Foo2.pl'}), get_addr(\&fooinc),
				   '  key is correct in %INC' );

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
is( get_addr($INC{'Bar.pm'}), get_addr($arrayref),
				   '  key is correct in %INC' );

ok( eval "use Bar1; 1;",          'use()' );
ok( exists $INC{'Bar1.pm'},       '  %INC sees it' );
is( get_addr($INC{'Bar1.pm'}), get_addr($arrayref),
				   '  key is correct in %INC' );

ok( eval { do 'Bar2.pl'; 1 },     'do()' );
ok( exists $INC{'Bar2.pl'},       '  %INC sees it' );
is( get_addr($INC{'Bar2.pl'}), get_addr($arrayref),
				   '  key is correct in %INC' );

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
is( get_addr($INC{'Quux.pm'}), get_addr($href),
				   '  key is correct in %INC' );

pop @INC;

my $aref = bless( [], 'FooLoader' );
push @INC, $aref;

ok( eval { require Quux1; 1 },     'require() magic via array object' );
ok( exists $INC{'Quux1.pm'},       '  %INC sees it' );
is( get_addr($INC{'Quux1.pm'}), get_addr($aref),
				   '  key is correct in %INC' );

pop @INC;

my $sref = bless( \(my $x = 1), 'FooLoader' );
push @INC, $sref;

ok( eval { require Quux2; 1 },     'require() magic via scalar object' );
ok( exists $INC{'Quux2.pm'},       '  %INC sees it' );
is( get_addr($INC{'Quux2.pm'}), get_addr($sref),
				   '  key is correct in %INC' );

pop @INC;
