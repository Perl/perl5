#!./perl -wT

# Tests for the coderef-in-@INC feature

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use Config;

BEGIN {
    require Test::More;

    # This test relies on perlio, but the feature being tested does not.
    # The dependency should eventually be purged and use something like
    # Tie::Handle instead.
    if( $Config{useperlio} ) {
        Test::More->import(tests => 21);
    }
    else {
        Test::More->import('skip_all');
    }
}

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

ok( !eval { require Bar; 1 },      'Trying non-magic package' );

ok( eval { require Foo; 1 },       'require() magic via code ref'  ); 
ok( exists $INC{'Foo.pm'},         '  %INC sees it' );

ok( eval "use Foo1; 1;",           'use()' );  
ok( exists $INC{'Foo1.pm'},        '  %INC sees it' );

ok( eval { do 'Foo2.pl'; 1 },      'do()' ); 
ok( exists $INC{'Foo2.pl'},        '  %INC sees it' );

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

ok( eval { require Foo; 1; },     'Originally loaded packages preserved' );
ok( !eval { require Foo3; 1; },   'Original magic INC purged' );

ok( eval { require Bar; 1 },      'require() magic via array ref' );
ok( exists $INC{'Bar.pm'},        '  %INC sees it' );

ok( eval "use Bar1; 1;",          'use()' );
ok( exists $INC{'Bar1.pm'},       '  %INC sees it' );

ok( eval { do 'Bar2.pl'; 1 },     'do()' );
ok( exists $INC{'Bar2.pl'},       '  %INC sees it' );

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

ok( eval { require Quux; 1 },      'require() magic via hash object' );
ok( exists $INC{'Quux.pm'},        '  %INC sees it' );

pop @INC;

push @INC, bless( [], 'FooLoader' );

ok( eval { require Quux1; 1 },     'require() magic via array object' );
ok( exists $INC{'Quux1.pm'},       '  %INC sees it' );

pop @INC;

push @INC, bless( \(my $x = 1), 'FooLoader' );

ok( eval { require Quux2; 1 },     'require() magic via scalar object' );
ok( exists $INC{'Quux2.pm'},       '  %INC sees it' );

pop @INC;
