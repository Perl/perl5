use HTTP::Status;

print "1..8\n";

200 == RC_OK || print "not ";
print "ok 1\n";

is_success(RC_ACCEPTED) || print "not ";
print "ok 2\n";

is_error(RC_BAD_REQUEST) || print "not ";
print "ok 3\n";

is_redirect(RC_MOVED_PERMANENTLY) || print "not ";
print "ok 4\n";

is_success(RC_NOT_FOUND) && print "not ";
print "ok 5\n";

$mess = status_message(0);

defined $mess && print "not ";
print "ok 6\n";

$mess = status_message(200);

if ($mess =~ /ok/i) {
    print "ok 7\n";
}

is_info(RC_CONTINUE) || print "not ";
print "ok 8\n";