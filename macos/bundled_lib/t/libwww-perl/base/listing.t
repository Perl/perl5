print "1..6\n";


use File::Listing;

$dir = <<'EOL';
total 68
drwxr-xr-x   4 aas      users        1024 Mar 16 15:47 .
drwxr-xr-x  11 aas      users        1024 Mar 15 19:22 ..
drwxr-xr-x   2 aas      users        1024 Mar 16 15:47 CVS
-rw-r--r--   1 aas      users        2384 Feb 26 21:14 Debug.pm
-rw-r--r--   1 aas      users        2145 Feb 26 20:09 IO.pm
-rw-r--r--   1 aas      users        3960 Mar 15 18:05 MediaTypes.pm
-rw-r--r--   1 aas      users         792 Feb 26 20:12 MemberMixin.pm
drwxr-xr-x   3 aas      users        1024 Mar 15 18:05 Protocol
-rw-r--r--   1 aas      users        5613 Feb 26 20:16 Protocol.pm
-rw-r--r--   1 aas      users        5963 Feb 26 21:27 RobotUA.pm
-rw-r--r--   1 aas      users        5071 Mar 16 12:25 Simple.pm
-rw-r--r--   1 aas      users        8817 Mar 15 18:05 Socket.pm
-rw-r--r--   1 aas      users        2121 Feb  5 14:22 TkIO.pm
-rw-r--r--   1 aas      users       19628 Mar 15 18:05 UserAgent.pm
-rw-r--r--   1 aas      users        2841 Feb  5 19:06 media.types

CVS:
total 5
drwxr-xr-x   2 aas      users        1024 Mar 16 15:47 .
drwxr-xr-x   4 aas      users        1024 Mar 16 15:47 ..
-rw-r--r--   1 aas      users         545 Mar 16 15:47 Entries
-rw-r--r--   1 aas      users          39 Mar 10 09:05 Repository
-rw-r--r--   1 aas      users          19 Mar 10 09:05 Root

Protocol:
total 37
drwxr-xr-x   3 aas      users        1024 Mar 15 18:05 .
drwxr-xr-x   4 aas      users        1024 Mar 16 15:47 ..
drwxr-xr-x   2 aas      users        1024 Mar 15 18:05 CVS
-rw-r--r--   1 aas      users        4646 Feb 26 20:13 file.pm
-rw-r--r--   1 aas      users       13006 Mar 15 18:05 ftp.pm
-rw-r--r--   1 aas      users        5935 Mar  6 10:29 gopher.pm
-rw-r--r--   1 aas      users        5453 Mar  6 10:29 http.pm
-rw-r--r--   1 aas      users        2365 Feb 26 20:13 mailto.pm

Protocol/CVS:
total 5
drwxr-xr-x   2 aas      users        1024 Mar 15 18:05 .
drwxr-xr-x   3 aas      users        1024 Mar 15 18:05 ..
-rw-r--r--   1 aas      users         238 Mar 15 18:05 Entries
-rw-r--r--   1 aas      users          48 Mar 10 09:05 Repository
-rw-r--r--   1 aas      users          19 Mar 10 09:05 Root
EOL

@dir = parse_dir($dir, undef, 'unix');

print int(@dir) ." lines found\n";
@dir != 25 && print "not ";
print "ok 1\n";

for (@dir) {
   ($name, $type, $size, $mtime, $mode) = @$_;
   $size ||= 0;  # ensure that it is defined
   printf "%-25s $type %6d  ", $name, $size;
   print scalar(localtime($mtime));
   printf "  %06o", $mode;
   print "\n";
}

# Pick out the Socket.pm line as the sample we check carefully
($name, $type, $size, $mtime, $mode) = @{$dir[9]};

$name eq "Socket.pm" || print "not ";
print "ok 2\n";

$type eq "f" || print "not ";
print "ok 3\n";

$size == 8817 || print "not ";
print "ok 4\n";

# Must be careful when checking the time stamps because we don't know
# which year if this script lives for a long time.
$timestring = scalar(localtime($mtime));
$timestring =~ /Mar\s+15\s+18:05/ or print "not ";
print "ok 5\n";

$mode == 0100644 || print "not ";
print "ok 6\n";
