# -*- mode: cperl -*-

use strict;
print "1..1\n";

if (!eval { require Module::Signature; 1 }) {
  skip("Next time around, consider install Module::Signature, ".
       "so you can verify the integrity of this distribution.", 1);
}
elsif (!eval { require Socket; Socket::inet_aton('pgp.mit.edu') }) {
  print "ok 1 # skip - Cannot connect to the keyserver";
}
else {
  (Module::Signature::verify() == Module::Signature::SIGNATURE_OK())
      or print "not ";
  print "ok 1 # Valid signature\n";
}
