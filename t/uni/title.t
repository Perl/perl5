BEGIN {
    chdir 't' if -d 't';
    require "uni/case.pl";
    @INC = () unless is_miniperl();
    unshift @INC, qw(../lib .);
}

casetest(0, # No extra tests run here,
	"Titlecase_Mapping", sub { ucfirst $_[0] },
	 sub { my $a = ""; ucfirst ($_[0] . $a) });
