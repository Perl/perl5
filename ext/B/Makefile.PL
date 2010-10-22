use ExtUtils::MakeMaker;
use File::Spec;
my $core = grep { $_ eq 'PERL_CORE=1' } @ARGV;

WriteMakefile(
    NAME	    => "B",
    VERSION_FROM    => "B.pm",
    PL_FILES	    => { 'defsubs_h.PL' => 'defsubs.h' },
    clean	    => {
	FILES	    => "defsubs.h"
    }
);

package MY;
sub headerpath {
    if ($core) {
	return File::Spec->catdir(File::Spec->updir,
				   File::Spec->updir);
    } else {
	require Config;
	return File::Spec->catdir($Config::Config{archlibexp}, "CORE");
    }
}

sub MY::postamble {
    my $headerpath = headerpath();
    my @headers = map { File::Spec->catfile($headerpath, $_) } qw(op.h cop.h);

"
B\$(OBJ_EXT) : defsubs.h

defsubs.h :: @headers defsubs_h.PL
	\$(PERL) -I\$(INST_ARCHLIB) -I\$(INST_LIB) -I\$(PERL_ARCHLIB) -I\$(PERL_LIB) defsubs_h.PL defsubs.h $headerpath
"
}

sub MY::processPL {
    my $text = shift->SUPER::processPL(@_);
    # Append our extra parameter
    $text =~ s/^\t.*defsubs_h\.PL.*/$& . ' ' . headerpath()/me;
    $text;
}
