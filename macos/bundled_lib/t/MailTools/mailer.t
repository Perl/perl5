#!/usr/local/bin/perl -w

use Mail::Mailer;

print "1..2\n";

print "ok 1\n";

$mail = new Mail::Mailer or print "not ";
print "ok 2\n";

undef $mail;

# well until I have a way of getting an address, that is all I can do.
# better than nothing :-)
