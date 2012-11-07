
# WARNING! This script can be dangerous.  It executes every line in every
# file in the build directory and its subdirectories, so it could do some
# harm if the line contains `rm *` or something similar.
#
# Run this as ./perl -Ilib Porting/leakfinder.pl after building perl.
#
# This is a quick non-portable hack that evaluates pieces of code in an
# eval twice and sees whether the number of SVs goes up.  Any lines that
# leak are printed to STDOUT.
#
# push and unshift will give false positives.  Some lines (listed at the
# bottom) are explicitly skipped.  Some patterns (at the beginning of the
# inner for loop) are also skipped.

use XS::APItest "sv_count";
use Data::Dumper;
$Data::Dumper::Useqq++;
for(`find .`) {
 warn $_;
 chomp;
 for(`cat \Q$_\E 2>/dev/null`) {
    next if exists $exceptions{s/^\s+//r};
    next if /rm -rf/; # Could be an example from perlsec, e.g.
    next if /END\s*\{/; # Creating an END block creates SVs, obviously
    next if /^\s*(?:push|unshift)/;
    next if /\bselect(?:\s*\()[^()]+,/; # 4-arg select hangs
    my $q = s/[\\']/sprintf "\\%02x", ord $&/gore
         =~ s/\0/'."\\0".'/grid;
    $prog = <<end;   
            open oUt, ">&", STDOUT;
            open STDOUT, ">/dev/null";
            open STDIN, "</dev/null";
            open STDERR, ">/dev/null";
            \$unused_variable = '$q';
            eval \$unused_variable;
            print oUt sv_count, "\n";
            eval \$unused_variable;
            print oUt sv_count, "\n";
end
    open my $fh, "-|", $^X, "-Ilib", "-MXS::APItest=sv_count",
                 '-e', $prog or warn($!), next;
    local $/;
    $out = <$fh>;
    close $fh;
    @_ = split ' ', $out;
    if (@_ == 2 && $_[1] > $_[0]) { print Dumper $_ }
 }
}

BEGIN {
 @exceptions = split /^/, <<'end';
$char++ while substr( $got, $char, 1 ) eq substr( $wanted, $char, 1 );
do {$x[$x] = $x;} while ($x++) < 10;
eval 'v23: $counter++; goto v23 unless $counter == 2';
eval 'v23 : $counter++; goto v23 unless $counter == 2';
sleep;
end
 @exceptions{@exceptions} = ();
}
