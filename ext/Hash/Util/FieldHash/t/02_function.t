#!perl

BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = '../lib';
    }
}

use strict; use warnings;
use Test::More;
my $n_tests = 0;

use Hash::Util::FieldHash qw( :all);
my $ob_reg = Hash::Util::FieldHash::_ob_reg;

#########################

# define ref types to use with some tests
my @test_types;
BEGIN {
    # skipping CODE refs, they are differently scoped
    @test_types = qw( SCALAR ARRAY HASH GLOB);
}

### Object registry

BEGIN { $n_tests += 3 }
{
    {
        my $obj = {};
        {
            my $h;
            fieldhash %$h;
            $h->{ $obj} = 123;
            is( keys %$ob_reg, 1, "one object registered");
        }
        # field hash stays alive until $obj dies
        is( keys %$ob_reg, 1, "object still registered");
    }
    is( keys %$ob_reg, 0, "object unregistered");
}

### existence/retrieval/deletion
BEGIN { $n_tests += 6 }
{
    no warnings 'misc';
    my $val = 123;
    fieldhash my %h;
    for ( [ str => 'abc'], [ ref => {}] ) {
        my ( $keytype, $key) = @$_;
        $h{ $key} = $val;
        ok( exists $h{ $key},  "existence ($keytype)");
        is( $h{ $key}, $val,   "retrieval ($keytype)");
        delete $h{ $key};
        is( keys %h, 0, "deletion ($keytype)");
    }
}

### id-action (stringification independent of bless)
BEGIN { $n_tests += 4 }
{
    my( %f, %g, %h, %i);
    fieldhash %f;
    fieldhash %g;
    my $val = 123;
    my $key = [];
    $f{ $key} = $val;
    is( $f{ $key}, $val, "plain key set in field");
    bless $key;
    is( $f{ $key}, $val, "access through blessed");
    $key = [];
    $h{ $key} = $val;
    is( $h{ $key}, $val, "plain key set in hash");
    bless $key;
    isnt( $h{ $key}, $val, "no access through blessed");
}
    
# Garbage collection
BEGIN { $n_tests += 1 + 2*( 3*@test_types + 5) + 1 }

{
    fieldhash my %h;
    $h{ []} = 123;
    is( keys %h, 0, "blip");
}

for my $preload ( [], [ map {}, 1 .. 3] ) {
    my $pre = @$preload ? ' (preloaded)' : '';
    fieldhash my %f;
    my @preval = map "$_", @$preload;
    @f{ @$preload} = @preval;
    # Garbage collection separately
    for my $type ( @test_types) {
        {
            my $ref = gen_ref( $type);
            $f{ $ref} = $type;
            my ( $val) = grep $_ eq $type, values %f;
            is( $val, $type, "$type visible$pre");
            is( 
                keys %$ob_reg,
                1 + @$preload,
                "$type obj registered$pre"
            );
        }
        is( keys %f, @$preload, "$type gone$pre");
    }
    
    # Garbage collection collectively
    is( keys %$ob_reg, @$preload, "no objs remaining$pre");
    {
        my @refs = map gen_ref( $_), @test_types;
        @f{ @refs} = @test_types;
        ok(
            eq_set( [ values %f], [ @test_types, @preval]),
            "all types present$pre",
        );
        is(
            keys %$ob_reg,
            @test_types + @$preload,
            "all types registered$pre",
        );
    }
    die "preload gone" unless defined $preload;
    ok( eq_set( [ values %f], \ @preval), "all types gone$pre");
    is( keys %$ob_reg, @$preload, "all types unregistered$pre");
}
is( keys %$ob_reg, 0, "preload gone after loop");

# big key sets
BEGIN { $n_tests += 8 }
{
    my $size = 10_000;
    fieldhash( my %f);
    {
        my @refs = map [], 1 .. $size;
        $f{ $_} = 1 for @refs;
        is( keys %f, $size, "many keys singly");
        is(
            keys %$ob_reg,
            $size,
            "many objects singly",
        );
    }
    is( keys %f, 0, "many keys singly gone");
    is(
        keys %$ob_reg,
        0,
        "many objects singly unregistered",
    );
    
    {
        my @refs = map [], 1 .. $size;
        @f{ @refs } = ( 1) x @refs;
        is( keys %f, $size, "many keys at once");
        is(
            keys %$ob_reg,
            $size,
            "many objects at once",
        );
    }
    is( keys %f, 0, "many keys at once gone");
    is(
        keys %$ob_reg,
        0,
        "many objects at once unregistered",
    );
}

# many field hashes
BEGIN { $n_tests += 6 }
{
    my $n_fields = 1000;
    my @fields = map &fieldhash( {}), 1 .. $n_fields;
    my @obs = map gen_ref( $_), @test_types;
    my $n_obs = @obs;
    for my $field ( @fields ) {
        @{ $field }{ @obs} = map ref, @obs;
    }
    my $err = grep keys %$_ != @obs, @fields;
    is( $err, 0, "$n_obs entries in $n_fields fields");
    is( keys %$ob_reg, @obs, "$n_obs obs registered");
    pop @obs;
    $err = grep keys %$_ != @obs, @fields;
    is( $err, 0, "one entry gone from $n_fields fields");
    is( keys %$ob_reg, @obs, "one ob unregistered");
    @obs = ();
    $err = grep keys %$_ != @obs, @fields;
    is( $err, 0, "all entries gone from $n_fields fields");
    is( keys %$ob_reg, @obs, "all obs unregistered");
}


# direct hash assignment
BEGIN { $n_tests += 4 }
{
    fieldhashes \ my( %f, %g, %h);
    my $size = 6;
    my @obs = map [], 1 .. $size;
    @f{ @obs} = ( 1) x $size;
    $g{ $_} = $f{ $_} for keys %f; # single assignment
    %h = %f;                       # wholesale assignment
    @obs = ();
    is keys %$ob_reg, 0, "all keys collected";
    is keys %f, 0, "orig garbage-collected";
    is keys %g, 0, "single-copy garbage-collected";
    is keys %h, 0, "wholesale-copy garbage-collected";
}

{

    BEGIN { $n_tests += 1 }
    fieldhash my %h;
    bless \ %h, 'abc'; # this bus-errors with a certain bug
    ok( 1, "no bus error on bless")
}

BEGIN { plan tests => $n_tests }

#######################################################################

use Symbol qw( gensym);

BEGIN {
    my %gen = (
        SCALAR => sub { \ my $x },
        ARRAY  => sub { [] },
        HASH   => sub { {} },
        GLOB   => sub { gensym },
        CODE   => sub { sub {} },
    );

    sub gen_ref { $gen{ shift()}->() }
}
