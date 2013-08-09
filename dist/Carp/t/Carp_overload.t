use warnings;
no warnings 'once';
use Test::More 0.98 tests => 9;

use Carp;

my $o = Stringable->new(key => 'Baz');

my $msg = call(\&with_longmess, $o, {bar => 'buzz'});
like($msg, qr/'Stringable=Baz'/, "Stringable object stringified");
like($msg, qr/'HASH\(0x[[:xdigit:]]+\)'/, "HASH *not* stringified");

{
    my $called;

    local $Carp::RefArgFormatter = sub {
        $called++;
        join '', explain $_[0];
    };

    $msg = call(\&with_longmess, $o, {bar => 'buzz'});
    ok($called, "Called private formatter");
    like($msg, qr/bar.*buzz/m, 'HASH stringified');
}

$o = CarpTracable->new(key => 'Bax');
$msg = call(\&with_longmess, $o, {bar => 'buzz'});
ok($o->{called}, "CARP_TRACE called");
like($msg, qr/'TRACE:CarpTracable=Bax'/, "CARP_TRACE output used") or diag explain $msg;
like($msg, qr/'HASH\(0x[[:xdigit:]]+\)'/, "HASH not stringified again");

$o = CarpBad->new(key => 'Zoo');
$msg = call(\&with_longmess, $o, {bar => 'kill'});
unlike($msg, qr/THIS SHOULD NEVER HAPPEN|Zoo/, "Didn't get the as-string version");
like($msg, qr/CarpBad=HASH/,"Normal non-overload string conversion");
diag explain $msg;

sub call
{
    my $func = shift;
    $func->(@_);
}

sub with_longmess
{
    my $g = shift;
    Carp::longmess("longmess:\n");
}

package Stringable;

use overload
    q[""] => 'as_string';

sub new { my $class = shift; return bless {@_}, $class }

sub as_string
{
    my $self = shift;
    join '=', ref $self, $self->{key} || '<no key>';
}

package CarpTracable;

use parent -norequire => 'Stringable';

sub CARP_TRACE
{
    my $self = shift;
    $self->{called}++;
    "TRACE:" . $self; # use string overload
}

package CarpBad;

use parent -norequire => 'Stringable';

sub as_string
{
    Carp::cluck("woops, this isn't allowed");
    "THIS SHOULD NEVER HAPPEN";
}


