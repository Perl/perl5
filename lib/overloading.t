#./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

BEGIN {
    require "./test.pl";
    plan(tests => 22);
}

use Scalar::Util qw(refaddr);

{
    package Stringifies;

    use overload (
	fallback => 1,
	'""' => sub { "foo" },
	'0+' => sub { 42 },
    );

    sub new { bless {}, shift };
}

my $x = Stringifies->new;

is( "$x", "foo", "stringifies" );
is( 0 + $x, 42, "numifies" );

{
    no overloading;
    is( "$x", overload::StrVal($x), "no stringification" );
    is( 0 + $x, refaddr($x), "no numification" );

    {
	no overloading '""';
	is( "$x", overload::StrVal($x), "no stringification" );
	is( 0 + $x, refaddr($x), "no numification" );
    }
}

{
    no overloading '""';

    is( "$x", overload::StrVal($x), "no stringification" );
    is( 0 + $x, 42, "numifies" );

    {
	no overloading;
	is( "$x", overload::StrVal($x), "no stringification" );
	is( 0 + $x, refaddr($x), "no numification" );
    }

    use overloading '""';

    is( "$x", "foo", "stringifies" );
    is( 0 + $x, 42, "numifies" );

    no overloading '0+';
    is( "$x", "foo", "stringifies" );
    is( 0 + $x, refaddr($x), "no numification" );

    {
	no overloading '""';
	is( "$x", overload::StrVal($x), "no stringification" );
	is( 0 + $x, refaddr($x), "no numification" );

	{
	    use overloading;
	    is( "$x", "foo", "stringifies" );
	    is( 0 + $x, 42, "numifies" );
	}
    }

    is( "$x", "foo", "stringifies" );
    is( 0 + $x, refaddr($x), "no numification" );


    BEGIN { ok(exists($^H{overloading}), "overloading hint present") }

    use overloading;

    BEGIN { ok(!exists($^H{overloading}), "overloading hint removed") }
}
