#!perl
BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

plan 5;

sub notdef { undef }

# [perl #97466]
# These should actually call the sub, instead of testing the sub itself
ok !defined do { &notdef }, 'defined do { &sub }';
{
    no warnings 'void';
    ok !defined(scalar(42,&notdef)), 'defined(scalar(42,&sub))';
}
ok !defined do{();&notdef}, '!defined do{();&sub}';

# Likewise, these should evaluate @array in scalar context
no warnings "deprecated";
my ($false, $scalar, @array);
ok defined($false ? $scalar : @array), 'defined( ... ? ... : @array)';
ok defined(scalar @array), 'defined(scalar @array)';
