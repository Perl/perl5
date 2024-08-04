#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    skip_all_without_perlio();
    skip_all_without_dynamic_extension('Fcntl'); # how did you get this far?
}

use strict;
use warnings;

plan tests => 16;

use Fcntl qw(:seek);

{
    ok((open my $fh, "+>", undef), "open my \$fh, '+>', undef");
    print $fh "the right write stuff";
    ok(seek($fh, 0, SEEK_SET), "seek to zero");
    my $data = <$fh>;
    is($data, "the right write stuff", "found the right stuff");
}

{
    ok((open my $fh, "+<", undef), "open my \$fh, '+<', undef");
    print $fh "the right read stuff";
    ok(seek($fh, 0, SEEK_SET), "seek to zero");
    my $data = <$fh>;
    is($data, "the right read stuff", "found the right stuff");
}

SKIP:
{
    ok((open my $fh, "+>>", undef), "open my \$fh, '+>>', undef")
      or skip "can't open temp for append: $!", 3;
    print $fh "abc";
    ok(seek($fh, 0, SEEK_SET), "seek to zero");
    print $fh "xyz";
    ok(seek($fh, 0, SEEK_SET), "seek to zero again");
    my $data = <$fh>;
    is($data, "abcxyz", "check the second write appended");
}

{
    my $fn = \&CORE::open;
    ok($fn->(my $fh, "+>", undef), "(\\&CORE::open)->(my \$fh, '+>', undef)");
    print $fh "the right write stuff";
    ok(seek($fh, 0, SEEK_SET), "seek to zero");
    my $data = <$fh>;
    is($data, "the right write stuff", "found the right stuff");
}

{
    # GH #22385
    my %hash;
    my $warnings = '';
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    my $r = open my $fh, "+>", delete $hash{nosuchkey};
    my $enoent = $!{ENOENT};
    is $r, undef, "open(my \$fh, '+>', delete \$hash{nosuchkey}) fails";
    SKIP: {
        skip "This system doesn't understand ENOENT", 1
            unless exists $!{ENOENT};
        ok $enoent, "\$! is ENOENT";
    }
    like $warnings, qr/^Use of uninitialized value in open/, "it warns about undef";
}
