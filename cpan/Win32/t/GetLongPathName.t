use strict;
use Test;
BEGIN {
    if ( $^O ne 'MSWin32' ) {
        print "1..0 # Skip: Not running on Windows\n";
        exit 0;
    }
}
use Win32;

my @paths = qw(
    /
    //
    .
    ..
    c:
    c:/
    c:./
    c:/.
    c:/..
    c:./..
    //./
    //.
    //..
    //./..
);
push @paths, map { my $x = $_; $x =~ s,/,\\,g; $x } @paths;
push @paths, qw(
    ../\
    c:.\\../\
    c:/\..//
    c://.\/./\
    \\.\\../\
    //\..//
    //.\/./\
);

my $drive = $ENV{SYSTEMDRIVE};
if ($drive) {
    for (@paths) {
	s/^c:/$drive/;
    }
}
my %expect;
@expect{@paths} = map { my $x = $_;
                        $x =~ s,(.[/\\])[/\\]+,$1,g;
                        $x =~ s,^(\w):,\U$1:,;
                        $x } @paths;

plan tests => scalar(@paths);

my $i = 1;
for (@paths) {
    my $got = Win32::GetLongPathName($_);
    print "# '$_' => expect '$expect{$_}' => got '$got'\n";
    print "not " unless $expect{$_} eq $got;
    print "ok $i\n";
    ++$i;
}
