#!./perl

print "1..8\n";

sub try ($$) {
   print +($_[1] ? "ok" : "not ok"), " $_[0]\n";
}

try 1,  13 %  4 ==  1;
try 2, -13 %  4 ==  3;
try 3,  13 % -4 == -3;
try 4, -13 % -4 == -1;
try 5, abs( 13e21 %  4e21 -  1e21) < 1e6;
try 6, abs(-13e21 %  4e21 -  3e21) < 1e6;
try 7, abs( 13e21 % -4e21 - -3e21) < 1e6;
try 8, abs(-13e21 % -4e21 - -1e21) < 1e6;
