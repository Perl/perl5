#!./perl

print "";
@c = caller;
print "@c";
__END__

require POSIX; import POSIX getpid;

print &getpid, "\n";
