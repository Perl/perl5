require 5.004;
use strict;
use ExtUtils::MakeMaker;

my @extra;
my @define;
my $ans = "y"; #prompt("Do you want to compile with support for marked sections?", "yes");
if ($ans =~ /^y(es)?$/i) {
    push(@define, "-DMARKED_SECTION");
}

if ($] >= 5.007) {
    print <<"EOT";

Perl-5.7 provide experimental core support for Unicode strings.  You
can compile HTML::Entities so that Unicode entities like &euro; and
&#x20AC; are decoded into a string containing "\\x{20AC}".  If you
select no to the question below such entities will be left alone and
only entities in the Latin-1 range is decoded.

EOT
    my $ans = prompt("Do you want decoding on unicode entities?", "no");
    if ($ans =~ /^y(es)?$/i) {
	push(@define, "-DUNICODE_ENTITIES");
    }
}
push(@extra, "DEFINE" => "@define") if @define;


WriteMakefile(
    NAME	 => 'HTML::Parser',
    VERSION_FROM => 'Parser.pm',
    H            => [ "hparser.h", "hctype.h", "tokenpos.h", "pfunc.h",
		      "hparser.c", "util.c",
		    ],
    PREREQ_PM    => {
		      'HTML::Tagset' => 3,
                    },
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    @extra,
);


sub MY::postamble
{
    '
pfunc.h : mkpfunc
	$(PERL) mkpfunc >pfunc.h

hctype.h : mkhctype
	$(PERL) mkhctype >hctype.h
'
}
