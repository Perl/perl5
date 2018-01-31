use warnings;
use strict;

use Test::More tests => 1;

use Carp ();

sub do_carp {
    Carp::longmess;
}

sub call_with_args {
    my ($arg_hash, $func) = @_;
    $func->(@{$arg_hash->{'args'}});
}

my $msg;
my $h = {};
my $arg_hash = {'args' => [undef]};
call_with_args($arg_hash, sub {
    $arg_hash->{'args'} = [];
    $msg = do_carp(sub { $h; });
});

like $msg, qr/^ at.+\b(?i:rt52610_crash\.t) line \d+\.\n\tmain::__ANON__\(.*\) called at.+\b(?i:rt52610_crash\.t) line \d+\n\tmain::call_with_args\(HASH\(0x[[:xdigit:]]+\), CODE\(0x[[:xdigit:]]+\)\) called at.+\b(?i:rt52610_crash\.t) line \d+$/;
