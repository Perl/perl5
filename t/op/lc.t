#!./perl

print "1..40\n";

$a = "HELLO.* world";
$b = "hello.* WORLD";

print "ok 1\n"  if "\Q$a\E."      eq "HELLO\\.\\*\\ world.";
print "ok 2\n"  if "\u$a"         eq "HELLO\.\* world";
print "ok 3\n"  if "\l$a"         eq "hELLO\.\* world";
print "ok 4\n"  if "\U$a"         eq "HELLO\.\* WORLD";
print "ok 5\n"  if "\L$a"         eq "hello\.\* world";

print "ok 6\n"  if quotemeta($a)  eq "HELLO\\.\\*\\ world";
print "ok 7\n"  if ucfirst($a)    eq "HELLO\.\* world";
print "ok 8\n"  if lcfirst($a)    eq "hELLO\.\* world";
print "ok 9\n"  if uc($a)         eq "HELLO\.\* WORLD";
print "ok 10\n" if lc($a)         eq "hello\.\* world";

print "ok 11\n"  if "\Q$b\E."     eq "hello\\.\\*\\ WORLD.";
print "ok 12\n"  if "\u$b"        eq "Hello\.\* WORLD";
print "ok 13\n"  if "\l$b"        eq "hello\.\* WORLD";
print "ok 14\n"  if "\U$b"        eq "HELLO\.\* WORLD";
print "ok 15\n"  if "\L$b"        eq "hello\.\* world";

print "ok 16\n"  if quotemeta($b) eq "hello\\.\\*\\ WORLD";
print "ok 17\n"  if ucfirst($b)   eq "Hello\.\* WORLD";
print "ok 18\n"  if lcfirst($b)   eq "hello\.\* WORLD";
print "ok 19\n"  if uc($b)        eq "HELLO\.\* WORLD";
print "ok 20\n"  if lc($b)        eq "hello\.\* world";

$a = "\x{100}\x{101}\x{41}\x{61}";
$b = "\x{101}\x{100}\x{61}\x{41}";

print "ok 21\n" if "\Q$a\E."      eq "\x{100}\x{101}\x{41}\x{61}.";
print "ok 22\n" if "\u$a"         eq "\x{100}\x{101}\x{41}\x{61}";
print "ok 23\n" if "\l$a"         eq "\x{101}\x{101}\x{41}\x{61}";
print "ok 24\n" if "\U$a"         eq "\x{100}\x{100}\x{41}\x{41}";
print "ok 25\n" if "\L$a"         eq "\x{101}\x{101}\x{61}\x{61}";

print "ok 26\n" if quotemeta($a)  eq "\x{100}\x{101}\x{41}\x{61}";
print "ok 27\n" if ucfirst($a)    eq "\x{100}\x{101}\x{41}\x{61}";
print "ok 28\n" if lcfirst($a)    eq "\x{101}\x{101}\x{41}\x{61}";
print "ok 29\n" if uc($a)         eq "\x{100}\x{100}\x{41}\x{41}";
print "ok 30\n" if lc($a)         eq "\x{101}\x{101}\x{61}\x{61}";

print "ok 31\n" if "\Q$b\E."      eq "\x{101}\x{100}\x{61}\x{41}.";
print "ok 32\n" if "\u$b"         eq "\x{100}\x{100}\x{61}\x{41}";
print "ok 33\n" if "\l$b"         eq "\x{101}\x{100}\x{61}\x{41}";
print "ok 34\n" if "\U$b"         eq "\x{100}\x{100}\x{41}\x{41}";
print "ok 35\n" if "\L$b"         eq "\x{101}\x{101}\x{61}\x{61}";

print "ok 36\n"  if quotemeta($b) eq "\x{101}\x{100}\x{61}\x{41}";
print "ok 37\n"  if ucfirst($b)   eq "\x{100}\x{100}\x{61}\x{41}";
print "ok 38\n"  if lcfirst($b)   eq "\x{101}\x{100}\x{61}\x{41}";
print "ok 39\n"  if uc($b)        eq "\x{100}\x{100}\x{41}\x{41}";
print "ok 40\n"  if lc($b)        eq "\x{101}\x{101}\x{61}\x{61}";


