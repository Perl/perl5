#!./perl -IFoo::Bar -IBla
our @native_INC;
BEGIN { @native_INC = @INC; }
BEGIN {
    chdir 't' if -d 't';
    require './test.pl';	# for which_perl() etc
    unshift @INC, '../lib';     # Do NOT make this @INC = '../lib';
    push @INC, @native_INC;
}
plan(4);

my $Is_VMS   = $^O eq 'VMS';
my $lib;

$lib = 'Bla';
ok do { grep { $_ eq $lib } @INC[0..($#INC-1)] }, 'Identified entry in @INC';

SKIP: {
  skip 'Double colons not allowed in dir spec', 1 if $Is_VMS;
  $lib = 'Foo::Bar';
  ok do { grep { $_ eq $lib } @INC[0..($#INC-1)] },
    'Identified entry in @INC with double colons';
}

$lib = 'Bla2';
fresh_perl_is("print grep { \$_ eq '$lib' } \@INC[0..(\$#INC-1)]", $lib,
	      { switches => ['-IBla2'], nolib => 1 }, '-I');
SKIP: {
  skip 'Double colons not allowed in dir spec', 1 if $Is_VMS;
  $lib = 'Foo::Bar2';
  fresh_perl_is("print grep { \$_ eq '$lib' } \@INC", $lib,
	        { switches => ['-IFoo::Bar2'], nolib => 1 }, '-I with colons');
}
