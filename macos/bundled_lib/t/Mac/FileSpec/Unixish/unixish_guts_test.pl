#!/usr/local/bin/perl
BEGIN { 
  $Mac::FileSpec::Unixish::Pretend_Mac = 1;
  # $Mac::FileSpec::Unixish::Debug = 1;
}

use Mac::FileSpec::Unixish;

foreach $item (
 "bar/../foo/",
 "/bar/../foo",
 "bar/.////./../foo/",
 "../foo",
 '/'
# "/../foo", # meaningless
) {
  printf "u<%s> => m<%s> => u<%s> => m<%s>\n\n",
   $item,
   $m = nativize($item),
   $u = unixify($m),
   nativize($u)
  ;
}

print"\n\n";

foreach $item (
 ':bar::foo/bar',
 'bar:foo:',
 'bar:::foo',
 '::foo',
) {
  printf "m<%s> => u<%s> => m<%s>\n\n",
   $item,
   $u = unixify($item),
   nativize($u)
  ;
}
print"\n\n";
exit;

__END__

