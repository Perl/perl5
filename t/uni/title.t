BEGIN {
    chdir 't' if -d 't';
    require "uni/case.pl";
    set_up_inc(qw(../lib .));
}

casetest(0, # No extra tests run here,
	"Titlecase_Mapping", sub { ucfirst $_[0] },
	 sub { my $a = ""; ucfirst ($_[0] . $a) });
