BEGIN {
    @INC = '../lib/ExtUtils/t/Big-Fat-Dummy/lib'
}

print "1..2\n";

print eval "use Big::Fat::Dummy; 1;" ? "ok 1\n" : "not ok 1\n";
print "ok 2 - TEST_VERBOSE\n";
