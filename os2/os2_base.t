print "1.." . lasttest() . "\n";

$cwd = Cwd::sys_cwd();
print "ok 1\n";
print "not " unless -d $cwd;
print "ok 2\n";

$lpb = Cwd::extLibpath;
print "ok 3\n";
$lpb .= ';' unless $lpb and $lpb =~ /;$/;

$lpe = Cwd::extLibpath(1);
print "ok 4\n";
$lpe .= ';' unless $lpe and $lpe =~ /;$/;

Cwd::extLibpath_set("$lpb$cwd") or print "not ";
print "ok 5\n";

$lpb = Cwd::extLibpath;
print "ok 6\n";
$lpb =~ s#\\#/#g;
($s_cwd = $cwd) =~ s#\\#/#g;

print "not " unless $lpb =~ /\Q$s_cwd/;
print "ok 7\n";

Cwd::extLibpath_set("$lpe$cwd", 1) or print "not ";
print "ok 8\n";

$lpe = Cwd::extLibpath(1);
print "ok 9\n";
$lpe =~ s#\\#/#g;

print "not " unless $lpe =~ /\Q$s_cwd/;
print "ok 10\n";

unshift @INC, 'lib';
require OS2::Process;
@l = OS2::Process::process_entry();
print "not " unless @l == 11;
print "ok 11\n";

# 1: FS 2: Window-VIO 
print "not " unless $l[9] == 1 or $l[9] == 2;
print "ok 12\n";

print "# $_\n" for @l;

sub lasttest {12}
