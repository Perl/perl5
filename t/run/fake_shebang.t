#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

BEGIN { require './test.pl'; }
use File::Spec::Functions;

plan(tests => 1);

like runperl(stderr => 1,
	   progfile => catfile(curdir(), 'run', 'fake_shebang.aux')),
   qr/\Aok 1\nok 2\nUse of #! on fake line 1 is deprecated [^\n]+\nok 3\n\z/;
