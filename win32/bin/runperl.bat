@rem = '--*-Perl-*--
@echo off
perl -x -S %0 %*
goto endofperl
@rem ';
#!perl -w
#line 8
$0 =~ s|\.bat||i;
unless (-f $0) {
    $0 =~ s|.*[/\\]||;
    for (".", split ';', $ENV{PATH}) {
	$_ = "." if $_ eq "";
	$0 = "$_/$0" , goto doit if -f "$_/$0";
    }
    die "`$0' not found.\n";
}
doit: exec "perl", "-x", $0, @ARGV;
die "Failed to exec `$0': $!";
__END__
:endofperl
