print "1..6\n";


BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

my $foo = "foo";

print "not " unless qu(abc$foo) eq "abcfoo";
print "ok 1\n";

# qu is always Unicode, even in EBCDIC, so \x41 is 'A' and \x{61} is 'a'.

print "not " unless qu(abc\x41) eq "abcA";
print "ok 2\n";

print "not " unless qu(abc\x{61}$foo) eq "abcafoo";
print "ok 3\n";

print "not " unless qu(\x{41}\x{100}\x61\x{200}) eq "A\x{100}a\x{200}";
print "ok 4\n";

{

use bytes;

print "not " unless join(" ", unpack("C*", qu(\x80))) eq "194 128";
print "ok 5\n";

print "not " unless join(" ", unpack("C*", qu(\x{100}))) eq "196 128";
print "ok 6\n";

}

