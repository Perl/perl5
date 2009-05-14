#!/usr/bin/perl -w
use strict;

use Test::More 'no_plan';

use constant NO_SUCH_FILE => "this_file_had_better_not_exist";

use autodie;

eval { open(my $fh, '<', NO_SUCH_FILE); };
ok($@, "3-arg opening non-existent file fails");
like($@, qr/for reading/, "Well-formatted 3-arg open failure");

eval { open(my $fh, "< ".NO_SUCH_FILE) };
ok($@, "2-arg opening non-existent file fails");

like($@, qr/for reading/, "Well-formatted 2-arg open failure");
unlike($@, qr/GLOB\(0x/, "No ugly globs in 2-arg open messsage");
