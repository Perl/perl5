use Test::More tests => 2;
use Config;

# Can't assume too much about the string returned by crypt(),
# and about how many bytes of the encrypted (really, hashed)
# string matter.
#
# HISTORICALLY the results started with the first two bytes of the salt,
# followed by 11 bytes from the set [./0-9A-Za-z], and only the first
# eight characters mattered, but those are probably no more safe
# bets, given alternative encryption/hashing schemes like MD5,
# C2 (or higher) security schemes, and non-UNIX platforms.

SKIP: {
    skip "crypt unimplemented", 2, unless $Config{d_crypt};
    
    ok(substr(crypt("ab", "cd"), 2) ne substr(crypt("ab", "ce"), 2), "salt");

    ok(crypt("HI", "HO") eq crypt(v4040.4041, "HO"), "Unicode");
}
