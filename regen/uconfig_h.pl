#!/usr/bin/perl -w
#
# Regenerate (overwriting only if changed):
#
#    uconfig.h
#
# from uconfig.h config_h.SH
#
# Accepts the standard regen_lib -q and -v args.

use strict;
use Config;
require 'regen/regen_lib.pl';

my ($uconfig_h, $uconfig_h_new, $config_h_sh)
    = ('uconfig.h', 'uconfig.h-new', 'config_h.SH');

$ENV{CONFIG_SH} = 'uconfig.sh';
$ENV{CONFIG_H} = $uconfig_h_new;
safer_unlink($uconfig_h_new);

my $command = 'sh ./config_h.SH';
system $command and die "`$command` failed, \$?=$?";

open FH, ">>$uconfig_h_new" or die "Can't append to $uconfig_h_new: $!";

print FH "\n", read_only_bottom([$ENV{CONFIG_SH}, 'config_h.SH']);

safer_close(*FH);
rename_if_different($uconfig_h_new, $uconfig_h);
