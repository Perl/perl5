#!./perl

#
# test the bit operators '&', '|' and '^'
#

print "1..9\n";

# numerics
print ((0xdead & 0xbeef) == 0x9ead ? "ok 1\n" : "not ok 1\n");
print ((0xdead | 0xbeef) == 0xfeef ? "ok 2\n" : "not ok 2\n");
print ((0xdead ^ 0xbeef) == 0x6042 ? "ok 3\n" : "not ok 3\n");

# short strings
print (("AAAAA" & "zzzzz") eq '@@@@@' ? "ok 4\n" : "not ok 4\n");
print (("AAAAA" | "zzzzz") eq '{{{{{' ? "ok 5\n" : "not ok 5\n");
print (("AAAAA" ^ "zzzzz") eq ';;;;;' ? "ok 6\n" : "not ok 6\n");

# long strings
$foo = "A" x 150;
$bar = "z" x 75;
print (($foo & $bar) eq ('@'x75 ) ? "ok 7\n" : "not ok 7\n");
print (($foo | $bar) eq ('{'x75 . 'A'x75) ? "ok 8\n" : "not ok 8\n");
print (($foo ^ $bar) eq (';'x75 . 'A'x75) ? "ok 9\n" : "not ok 9\n");
