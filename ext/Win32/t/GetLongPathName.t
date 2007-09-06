use strict;
use Test;
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

my $drive = $ENV{SystemDrive};
if ($drive) {
    for (@paths) {
	s/^c:/$drive/;
    }
    push @paths, $ENV{SystemRoot} if $ENV{SystemRoot};
}
my %expect;
@expect{@paths} = map { my $x = $_;
                        $x =~ s,(.[/\\])[/\\]+,$1,g;
                        $x =~ s,^c,C,;
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
