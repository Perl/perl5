#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    use Config;
}

plan( tests => 1);

if (($Config{'extensions'} !~ /\bFcntl\b/) ){
  BAIL_OUT("Perl configured without Fcntl module");
}
##Finds IO submodules when using \b
if (($Config{'extensions'} !~ /\bIO\s/) ){
  BAIL_OUT("Perl configured without IO module");
}
# hey, DOS users do not need this kind of common sense ;-)
if ($^O ne 'dos' && ($Config{'extensions'} !~ /\bFile\/Glob\b/) ){
  BAIL_OUT("Perl configured without File::Glob module");
}

pass('common sense');

