#!./perl -w
BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
    skip_all_if_miniperl();
}

use Config;

my $perlio_log = "perlio$$.txt";

skip_all "DEBUGGING build required"
  unless $::Config{ccflags} =~ /DEBUGGING/
         or $^O eq 'VMS' && $::Config{usedebugging_perl} eq 'Y';

plan tests => 6;

END {
    unlink $perlio_log;
}
{
    unlink $perlio_log;
    local $ENV{PERLIO_DEBUG} = $perlio_log;
    fresh_perl_is("print qq(hello\n)", "hello\n",
                  { stderr => 1 },
                  "No perlio debug file without -Di...");
    ok(!-e $perlio_log, "...no perlio.txt found");
    fresh_perl_is("print qq(hello\n)", "\nEXECUTING...\n\nhello\n",
                  { stderr => 1, switches => [ "-Di" ] },
                  "Perlio debug file with both -Di and PERLIO_DEBUG...");
    ok(-e $perlio_log, "... perlio debugging file found with -Di and PERLIO_DEBUG");

    unlink $perlio_log;
    fresh_perl_is("print qq(hello\n)", "\nEXECUTING...\n\nhello\n",
                  { stderr => 1, switches => [ "-TDi" ] },
                  "No perlio debug file with -T..");
    ok(!-e $perlio_log, "...no perlio debugging file found");
}
