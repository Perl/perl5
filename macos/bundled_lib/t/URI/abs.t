print "1..45\n";

# This test the resolution of abs path for all examples given
# in the "Uniform Resource Identifiers (URI): Generic Syntax" document.

use URI;
$base = "http://a/b/c/d;p?q";
$testno = 1;

while (<DATA>) {
   #next if 1 .. /^C\.\s+/;
   #last if /^D\.\s+/;
   next unless /\s+(\S+)\s*=\s*(.*)/;
   my $uref = $1;
   my $expect = $2;
   $expect =~ s/\(current document\)/$base/;
   #print "$uref => $expect\n";

   my $bad;
   my $u = URI->new($uref, $base);
   if ($u->abs($base)->as_string ne $expect) {
       $bad++;
       my $abs = $u->abs($base)->as_string;
       print qq(URI->new("$uref")->abs("$base") ==> "$abs"\n);
   }

   # Let's test another version of the same thing
   $u = URI->new($uref);
   my $b = URI->new($base);
   if ($u->abs($b,1) ne $expect && $uref !~ /^http:/) {
       $bad++;
       print qq(URI->new("$uref")->abs(URI->new("$base"), 1)\n);
   }

   # Let's try the other way
   $u = URI->new($expect)->rel($base)->as_string;
   if ($u ne $uref) {
       push(@rel_fail, qq($testno: URI->new("$expect", "$base")->rel ==> "$u" (not "$uref")\n));
   }

   print "not " if $bad;
   print "ok ", $testno++, "\n";
}

if (@rel_fail) {
    print "\n\nIn the following cases we did not get back to where we started with rel()\n";
    print @rel_fail;
}



__END__

Network Working Group                            T. Berners-Lee, MIT/LCS
INTERNET-DRAFT                                 R. Fielding,  U.C. Irvine
draft-fielding-uri-syntax-02              L. Masinter, Xerox Corporation
Expires six months after publication date                  March 4, 1998


          Uniform Resource Identifiers (URI): Generic Syntax

[...]

C. Examples of Resolving Relative URI References

   Within an object with a well-defined base URI of

      http://a/b/c/d;p?q

   the relative URIs would be resolved as follows:

C.1.  Normal Examples

      g:h           =  g:h
      g             =  http://a/b/c/g
      ./g           =  http://a/b/c/g
      g/            =  http://a/b/c/g/
      /g            =  http://a/g
      //g           =  http://g
      ?y            =  http://a/b/c/?y
      g?y           =  http://a/b/c/g?y
      #s            =  (current document)#s
      g#s           =  http://a/b/c/g#s
      g?y#s         =  http://a/b/c/g?y#s
      ;x            =  http://a/b/c/;x
      g;x           =  http://a/b/c/g;x
      g;x?y#s       =  http://a/b/c/g;x?y#s
      .             =  http://a/b/c/
      ./            =  http://a/b/c/
      ..            =  http://a/b/
      ../           =  http://a/b/
      ../g          =  http://a/b/g
      ../..         =  http://a/
      ../../        =  http://a/
      ../../g       =  http://a/g

C.2.  Abnormal Examples

   Although the following abnormal examples are unlikely to occur in
   normal practice, all URI parsers should be capable of resolving them
   consistently.  Each example uses the same base as above.

   An empty reference refers to the start of the current document.

      <>            =  (current document)

   Parsers must be careful in handling the case where there are more
   relative path ".." segments than there are hierarchical levels in
   the base URI's path.  Note that the ".." syntax cannot be used to
   change the authority component of a URI.

      ../../../g    =  http://a/../g
      ../../../../g =  http://a/../../g

   In practice, some implementations strip leading relative symbolic
   elements (".", "..") after applying a relative URI calculation, based
   on the theory that compensating for obvious author errors is better
   than allowing the request to fail.  Thus, the above two references
   will be interpreted as "http://a/g" by some implementations.

   Similarly, parsers must avoid treating "." and ".." as special when
   they are not complete components of a relative path.

      /./g          =  http://a/./g
      /../g         =  http://a/../g
      g.            =  http://a/b/c/g.
      .g            =  http://a/b/c/.g
      g..           =  http://a/b/c/g..
      ..g           =  http://a/b/c/..g

   Less likely are cases where the relative URI uses unnecessary or
   nonsensical forms of the "." and ".." complete path segments.

      ./../g        =  http://a/b/g
      ./g/.         =  http://a/b/c/g/
      g/./h         =  http://a/b/c/g/h
      g/../h        =  http://a/b/c/h
      g;x=1/./y     =  http://a/b/c/g;x=1/y
      g;x=1/../y    =  http://a/b/c/y

   All client applications remove the query component from the base URI
   before resolving relative URIs.  However, some applications fail to
   separate the reference's query and/or fragment components from a
   relative path before merging it with the base path.  This error is
   rarely noticed, since typical usage of a fragment never includes the
   hierarchy ("/") character, and the query component is not normally
   used within relative references.

      g?y/./x       =  http://a/b/c/g?y/./x
      g?y/../x      =  http://a/b/c/g?y/../x
      g#s/./x       =  http://a/b/c/g#s/./x
      g#s/../x      =  http://a/b/c/g#s/../x

   Some parsers allow the scheme name to be present in a relative URI
   if it is the same as the base URI scheme.  This is considered to be
   a loophole in prior specifications of partial URIs [RFC1630]. Its
   use should be avoided.

      http:g        =  http:g
      http:         =  http:


==========================================================================

Some extra tests for good measure...

      #foo?        = (current document)#foo?
      ?#foo        = http://a/b/c/?#foo

