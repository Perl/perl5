#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = ('.');
}

# don't make this lexical
$i = 1;
print "1..3\n";

sub do_require {
    %INC = ();
    open(REQ,">bleah.pm") or die "Can't write 'bleah.pm': $!";
    print REQ @_;
    close REQ;
    eval { require "bleah.pm" };
    my @a; # magic guard for scope violations (must be first lexical in file)
}

# run-time failure in require
do_require "0;\n";
print "# $@\nnot " unless $@ =~ /did not return a true/;
print "ok ",$i++,"\n";

# compile-time failure in require
do_require "1)\n";
print "# $@\nnot " unless $@ =~ /syntax error/i;
print "ok ",$i++,"\n";

# successful require
do_require "1";
print "# $@\nnot " if $@;
print "ok ",$i++,"\n";

unlink 'bleah.pm';
