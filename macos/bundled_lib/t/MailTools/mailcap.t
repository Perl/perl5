#!/usr/local/bin/perl -w

require Mail::Cap;

print "1..5\n";

# First we create a mailcap file to test
$mcfile = "mailcap-$$";

open(MAILCAP, ">$mcfile") || die "Can't create $mcfile: $!";

print MAILCAP <<EOT;

# This is a comment and should be ignored

image/*; xv %s \\; echo "Showing image %s"; description=Simple image format

text/plain; cat %s;\\
  test=$^X -e "exit (!(q{%{charset}} =~ /^iso-8859-1\$/i))";\\
  copiousoutput

text/plain; smartcat %s; copiousoutput

local;cat %s;print=lpr %{foo} %{bar} %t %s

EOT
close(MAILCAP);

# OK, lets parse it
$mc = new Mail::Cap $mcfile;
unlink($mcfile);  # no more need for this file

$desc = $mc->description('image/gif');

print "GIF desc: $desc\n";
print "ok 1\n" if $desc eq "Simple image format";

$cmd1 = $mc->viewCmd('text/plain; charset=iso-8859-1', 'file.txt');
$cmd2 = $mc->viewCmd('text/plain; charset=iso-8859-2', 'file.txt');
$cmd3 = $mc->viewCmd('image/gif', 'gisle.gif');
$cmd4 = $mc->printCmd('local; foo=bar', 'myfile');

print "$cmd1\n";

print "ok 2\n" if $cmd1 eq "cat file.txt";

print "$cmd2\n";
print "ok 3\n" if $cmd2 eq "smartcat file.txt";

print "$cmd3\n";
print "ok 4\n" if $cmd3 eq qq(xv gisle.gif ; echo "Showing image gisle.gif");

print "$cmd4\n";
print "ok 5\n" if $cmd4 =~ /^lpr\s+bar\s+local\s+myfile$/;


#$mc->dump;
