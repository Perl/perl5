use ExtUtils::MakeMaker;
use Config;

my $e = $Config{'exe_ext'};
my $o = $Config{'obj_ext'};
my $exeout_flag = '-o ';
if ($^O eq 'MSWin32') {
    if ($Config{'cc'} =~ /^cl/i) {
	$exeout_flag = '-Fe';
    }
    elsif ($Config{'cc'} =~ /^bcc/i) {
	$exeout_flag = '-e';
    }
}

WriteMakefile(
    NAME	=> "B",
    VERSION	=> "a5",
    OBJECT	=> "B$o byterun$o",
    depend	=> {
	"B$o"		=> "B.c bytecode.h byterun.h",
    },
    clean	=> {
	FILES		=> "perl byteperl$e btest$e btest.c *$o B.c *~"
    }
);

sub MY::post_constants {
    "\nLIBS = $Config{libs}\n"
}

sub MY::top_targets {
    my $self = shift;
    my $targets = $self->MM::top_targets();
    $targets =~ s/^(all ::.*)$/$1 byteperl$e/m;
    return <<"EOT" . $targets;
#
# byterun.h, byterun.c and Asmdata.pm are auto-generated. If any of the
# files are missing or if you change bytecode.pl (which is what generates
# them all) then you can "make regen_headers" to regenerate them.
#
regen_headers:
	\$(PERL) bytecode.pl
	\$(MV) Asmdata.pm B
#
# byteperl is *not* a standard perl+XSUB executable. It's a special
# program for running standalone bytecode executables. It isn't an XSUB
# at the moment because a standlone Perl program needs to set up curpad
# which is overwritten on exit from an XSUB.
#
byteperl$e : byteperl$o B$o byterun$o
	\$(CC) ${exeout_flag}byteperl$e byteperl$o B$o byterun$o \$(LDFLAGS) \$(PERL_ARCHLIB)/CORE/$Config{libperl} \$(LIBS)
EOT
}
