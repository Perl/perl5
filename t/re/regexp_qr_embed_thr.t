#!./perl

chdir 't' if -d 't';
require './test.pl';
set_up_inc('../lib');

skip_all_without_config('useithreads');
skip_all_if_miniperl("no dynamic loading on miniperl, no threads");
require threads;

$::qr = 1;
$::qr_embed_thr = 1;

require './re/regexp.t';
