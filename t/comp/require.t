#!./perl

BEGIN {
    chdir 't' if -d 't';
    unshift @INC, ('.', '../lib');
}

# don't make this lexical
$i = 1;
print "1..16\n";

sub do_require {
    %INC = ();
    write_file('bleah.pm',@_);
    eval { require "bleah.pm" };
    my @a; # magic guard for scope violations (must be first lexical in file)
}

sub write_file {
    my $f = shift;
    open(REQ,">$f") or die "Can't write '$f': $!";
    print REQ @_;
    close REQ;
}

# new style version numbers

eval { require v5.5.630; };
print "# $@\nnot " if $@;
print "ok ",$i++,"\n";

eval { require v10.0.2; };
print "# $@\nnot " unless $@ =~ /^Perl v10\.0\.2 required/;
print "ok ",$i++,"\n";

eval q{ use v5.5.630; };
print "# $@\nnot " if $@;
print "ok ",$i++,"\n";

eval q{ use v10.0.2; };
print "# $@\nnot " unless $@ =~ /^Perl v10\.0\.2 required/;
print "ok ",$i++,"\n";

my $ver = v5.5.630;
eval { require $ver; };
print "# $@\nnot " if $@;
print "ok ",$i++,"\n";

$ver = v10.0.2;
eval { require $ver; };
print "# $@\nnot " unless $@ =~ /^Perl v10\.0\.2 required/;
print "ok ",$i++,"\n";

print "not " unless v5.5.1 gt v5.5;
print "ok ",$i++,"\n";

print "not " unless 5.005_01 > v5.5;
print "ok ",$i++,"\n";

print "not " unless 5.005_64 - v5.5.640 < 0.0000001;
print "ok ",$i++,"\n";

{
    use utf8;
    print "not " unless v5.5.640 eq "\x{5}\x{5}\x{280}";
    print "ok ",$i++,"\n";

    print "not " unless v7.15 eq "\x{7}\x{f}";
    print "ok ",$i++,"\n";

    print "not "
      unless v1.20.300.4000.50000.600000 eq "\x{1}\x{14}\x{12c}\x{fa0}\x{c350}\x{927c0}";
    print "ok ",$i++,"\n";
}

# interaction with pod (see the eof)
write_file('bleah.pm', "print 'ok $i\n'; 1;\n");
require "bleah.pm";
$i++;

# run-time failure in require
do_require "0;\n";
print "# $@\nnot " unless $@ =~ /did not return a true/;
print "ok ",$i++,"\n";

# compile-time failure in require
do_require "1)\n";
# bison says 'parse error' instead of 'syntax error',
# various yaccs may or may not capitalize 'syntax'.
print "# $@\nnot " unless $@ =~ /(syntax|parse) error/mi;
print "ok ",$i++,"\n";

# successful require
do_require "1";
print "# $@\nnot " if $@;
print "ok ",$i++,"\n";

END { 1 while unlink 'bleah.pm'; }

# ***interaction with pod (don't put any thing after here)***

=pod
