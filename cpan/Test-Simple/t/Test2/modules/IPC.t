use strict;
use warnings;

use Test2::IPC qw/cull/;
use Test2::API qw/context test2_ipc_drivers test2_ipc/;

BEGIN { require "t/tools.pl" };

test2_ipc();

is_deeply(
    [test2_ipc_drivers()],
    ['Test2::IPC::Driver::Files'],
    "Default driver"
);

ok(__PACKAGE__->can('cull'), "Imported cull");

done_testing;
