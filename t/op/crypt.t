#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = qw(. ../lib);
}

BEGIN {
    use Config;

    require "test.pl";

    if( !$Config{d_crypt} ) {
        skip_all("crypt unimplemented");
    }
    else {
        plan(tests => 2);
    }
}

# Can't assume too much about the string returned by crypt(),
# and about how many bytes of the encrypted (really, hashed)
# string matter.
#
# HISTORICALLY the results started with the first two bytes of the salt,
# followed by 11 bytes from the set [./0-9A-Za-z], and only the first
# eight characters mattered, but those are probably no more safe
# bets, given alternative encryption/hashing schemes like MD5,
# C2 (or higher) security schemes, and non-UNIX platforms.

ok(substr(crypt("ab", "cd"), 2) ne substr(crypt("ab", "ce"), 2), "salt makes a difference");

ok(crypt("HI", "HO") eq crypt(join("",map{chr($_+256)}unpack"C*","HI"), "HO"), "low eight bits of Unicode");
