#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use strict;
no  warnings 'syntax';

{
    # Bug #77084 points out a corruption problem when scalar //g is used
    # on overloaded objects.

    my @realloc;
    my $TAG = "foo:bar";
    use overload '""' => sub {$TAG};

    my $o = bless [];
    my ($one) = $o =~ /(.*)/g;
    push @realloc, "xxxxxx"; # encourage realloc of SV and PVX
    is $one, $TAG, "list context //g against overloaded object";


    my $r = $o =~ /(.*)/g;
    push @realloc, "yyyyyy"; # encourage realloc of SV and PVX
    is $1, $TAG, "scalar context //g against overloaded object";
    pos ($o) = 0;  # Reset pos, as //g in scalar context sets it to non-0.

    $o =~ /(.*)/g;
    push @realloc, "zzzzzz"; # encourage realloc of SV and PVX
    is $1, $TAG, "void context //g against overloaded object";
}

{
    # an overloaded stringify returning itself shouldn't loop indefinitely


    {
	package Self;
	use overload q{""} => sub {
		    return shift;
		},
	    fallback => 1;
    }

    my $obj = bless [], 'Self';
    my $r = qr/$obj/;
    pass("self object, 1 arg");
    $r = qr/foo$obj/;
    pass("self object, 2 args");
}

{
    # [perl #116823]
    # when overloading regex string constants, a different code path
    # was taken if the regex was compile-time, leading to overloaded
    # regex constant string segments not being handled correctly.
    # They were just treated as OP_CONST strings to be concatted together.
    # In particular, if the overload returned a regex object, it would
    # just be stringified rather than having any code blocks processed.

    BEGIN {
	overload::constant qr => sub {
	    my ($raw, $cooked, $type) = @_;
	    return $cooked unless defined $::CONST_QR_CLASS;
	    if ($type =~ /qq?/) {
		return bless \$cooked, $::CONST_QR_CLASS;
	    } else {
		return $cooked;
	    }
	};
    }

    {
	# returns a qr// object

	package OL_QR;
	use overload q{""} => sub {
		my $re = shift;
		return qr/(?{ $OL_QR::count++ })$$re/;
	    },
	fallback => 1;

    }

    my $qr;

    $::CONST_QR_CLASS = 'OL_QR';

    $OL_QR::count = 0;
    $qr = eval q{ qr/^foo$/; };
    ok("foo" =~ $qr, "compile-time, OL_QR, single constant segment");
    is($OL_QR::count, 1, "flag");

    $OL_QR::count = 0;
    $qr = eval q{ qr/^foo$(?{ $OL_QR::count++ })/; };
    ok("foo" =~ $qr, "compile-time, OL_QR, multiple constant segments");
    is($OL_QR::count, 2, "qr2 flag");

    undef $::CONST_QR_CLASS;
}


done_testing();
