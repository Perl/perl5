#!/usr/local/bin/perl

use Config;
use File::Basename qw(&basename &dirname);

# List explicitly here the variables you want Configure to
# generate.  Metaconfig only looks for shell variables, so you
# have to mention them as if they were shell variables, not
# %Config entries.  Thus you write
#  $startperl
# to ensure Configure will look for $Config{startperl}.

# This forces PL files to create target in same directory as PL file.
# This is so that make depend always knows where to find PL derivatives.
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
	if ($Config{'osname'} eq 'VMS' or
	    $Config{'osname'} eq 'OS2');  # "case-forgiving"

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

# In this section, perl variables will be expanded during extraction.
# You can use $Config{...} to use Configure variables.

print OUT <<"!GROK!THIS!";
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';
CONVERTERS = pod2html pod2latex pod2man pod2text

all: $(CONVERTERS) man
!NO!SUBS!

if (-x '../miniperl') {
    print OUT "PERL = ..\/miniperl\n\n";
}
else {
    print OUT "PERL = ../miniperl\n\n";
}

@pods = <*.pod>;

print OUT 'POD = ';
foreach (@pods) {
    # Remove .pod suffix.  Each section should add its own suffix.
    s/\.pod$//;  
    print OUT "\t\\\n\t$_.pod";
}
print OUT "\n\n";

print OUT 'MAN = ';
foreach (@pods) {
    print OUT "\t\\\n\t$_.man";
}
print OUT "\n\n";

print OUT 'HTML = ';
foreach (@pods) {
    print OUT "\t\\\n\t$_.html";
}
print OUT "\n\n";

print OUT 'TEX = ';
foreach (@pods) {
    s/\.pod/.tex/;
    print OUT "\t\\\n\t$_.tex";
}
print OUT "\n\n";

print OUT <<'!NO!SUBS!';
man:  pod2man $(MAN)

# pod2html normally runs on all the pods at once in order to build up
# cross-references.
html: pod2html
	$(PERL) -I../lib pod2html $(POD)

tex:	pod2latex $(TEX)

.SUFFIXES: .pm .pod .man

.pm.man:     pod2man
	$(PERL) -I../lib pod2man $*.pm >$*.man

.pod.man:     pod2man
	$(PERL) -I../lib pod2man $*.pod >$*.man

.SUFFIXES: .mp .pod .html

.pm.html:    pod2html
	$(PERL) -I../lib pod2html $*.pod

.pod.html:    pod2html
	$(PERL) -I../lib pod2html $*.pod

.SUFFIXES: .pm .pod .tex

.pod.tex: pod2latex
	$(PERL) -I../lib pod2latex $*.pod

.pm.tex: pod2latex
	$(PERL) -I../lib pod2latex $*.pod

clean:
	rm -f $(MAN) $(HTML) $(TEX)

realclean:	clean
	rm -f $(CONVERTERS)

distclean:	realclean

# Dependencies.
pod2latex:	pod2latex.PL ../lib/Config.pm
	$(PERL) -I../lib pod2latex.PL

pod2html:	pod2html.PL ../lib/Config.pm
	$(PERL) -I ../lib pod2html.PL

pod2man:	pod2man.PL ../lib/Config.pm
	$(PERL) -I ../lib pod2man.PL

pod2text:	pod2text.PL ../lib/Config.pm
	$(PERL) -I ../lib pod2text.PL
!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0644, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
