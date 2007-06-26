use 5.006;
use ExtUtils::MakeMaker;

my @libs;
push @libs, '-L/lib/w32api -lole32 -lversion' if $^O eq "cygwin";

WriteMakefile(
    NAME          => 'Win32',
    VERSION_FROM  => 'Win32.pm',
    LIBS          => \@libs,
    INSTALLDIRS   => ($] >= 5.008004 ? 'perl' : 'site'),
    NO_META       => 1,

    AUTHOR        => 'Jan Dubois <jand@activestate.com>',
    ABSTRACT_FROM => 'Win32.pm',
);
