#!./perl -T
#
# Taint tests by Tom Phoenix <rootbeer@teleport.com>.
#
# I don't claim to know all about tainting. If anyone sees
# tests that I've missed here, please add them. But this is
# better than having no tests at all, right?
#

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use strict;
use Config;
use File::Spec::Functions;

BEGIN { require './test.pl'; }
plan tests => 706;

$| = 1;

use vars qw($ipcsysv); # did we manage to load IPC::SysV?

my ($old_env_path, $old_env_dcl_path, $old_env_term);
BEGIN {
   $old_env_path = $ENV{'PATH'};
   $old_env_dcl_path = $ENV{'DCL$PATH'};
   $old_env_term = $ENV{'TERM'};
  if ($^O eq 'VMS' && !defined($Config{d_setenv})) {
      $ENV{PATH} = $ENV{PATH};
      $ENV{TERM} = $ENV{TERM} ne ''? $ENV{TERM} : 'dummy';
  }
  if ($Config{'extensions'} =~ /\bIPC\/SysV\b/
      && ($Config{d_shm} || $Config{d_msg})) {
      eval { require IPC::SysV };
      unless ($@) {
	  $ipcsysv++;
	  IPC::SysV->import(qw(IPC_PRIVATE IPC_RMID IPC_CREAT S_IRWXU IPC_NOWAIT));
      }
  }
}

my $Is_VMS      = $^O eq 'VMS';
my $Is_MSWin32  = $^O eq 'MSWin32';
my $Is_NetWare  = $^O eq 'NetWare';
my $Is_Dos      = $^O eq 'dos';
my $Is_Cygwin   = $^O eq 'cygwin';
my $Is_OpenBSD  = $^O eq 'openbsd';
my $Is_MirBSD   = $^O eq 'mirbsd';
my $Invoke_Perl = $Is_VMS      ? 'MCR Sys$Disk:[]Perl.exe' :
                  $Is_MSWin32  ? '.\perl'               :
                  $Is_NetWare  ? 'perl'                 :
                                 './perl'               ;
my @MoreEnv = qw/IFS CDPATH ENV BASH_ENV/;

if ($Is_VMS) {
    my (%old, $x);
    for $x ('DCL$PATH', @MoreEnv) {
	($old{$x}) = $ENV{$x} =~ /^(.*)$/ if exists $ENV{$x};
    }
    # VMS note:  PATH and TERM are automatically created by the C
    # library in VMS on reference to the their keys in %ENV.
    # There is currently no way to determine if they did not exist
    # before this test was run.
    eval <<EndOfCleanup;
	END {
	    \$ENV{PATH} = \$old_env_path;
	    warn "# Note: logical name 'PATH' may have been created\n";
	    \$ENV{'TERM'} = \$old_env_term;
	    warn "# Note: logical name 'TERM' may have been created\n";
	    \@ENV{keys %old} = values %old;
	    if (defined \$old_env_dcl_path) {
		\$ENV{'DCL\$PATH'} = \$old_env_dcl_path;
	    } else {
		delete \$ENV{'DCL\$PATH'};
	    }
	}
EndOfCleanup
}

# Sources of taint:
#   The empty tainted value, for tainting strings
my $TAINT = substr($^X, 0, 0);
#   A tainted zero, useful for tainting numbers
my $TAINT0;
{
    no warnings;
    $TAINT0 = 0 + $TAINT;
}

# This taints each argument passed. All must be lvalues.
# Side effect: It also stringifies them. :-(
sub taint_these (@) {
    for (@_) { $_ .= $TAINT }
}

# How to identify taint when you see it
sub any_tainted (@) {
    not eval { join("",@_), kill 0; 1 };
}
sub tainted ($) {
    any_tainted @_;
}
sub all_tainted (@) {
    for (@_) { return 0 unless tainted $_ }
    1;
}

sub is_tainted {
    my $thing = shift;
    local $::Level = $::Level + 1;
    ok(any_tainted($thing), @_);
}

sub isnt_tainted {
    my $thing = shift;
    local $::Level = $::Level + 1;
    ok(!any_tainted($thing), @_);
}

# We need an external program to call.
my $ECHO = ($Is_MSWin32 ? ".\\echo$$" : ($Is_NetWare ? "echo$$" : "./echo$$"));
END { unlink $ECHO }
open PROG, "> $ECHO" or die "Can't create $ECHO: $!";
print PROG 'print "@ARGV\n"', "\n";
close PROG;
my $echo = "$Invoke_Perl $ECHO";

my $TEST = catfile(curdir(), 'TEST');

# First, let's make sure that Perl is checking the dangerous
# environment variables. Maybe they aren't set yet, so we'll
# taint them ourselves.
{
    $ENV{'DCL$PATH'} = '' if $Is_VMS;

    if ($Is_MSWin32 && $Config{ccname} =~ /bcc32/ && ! -f 'cc3250mt.dll') {
	my $bcc_dir;
	foreach my $dir (split /$Config{path_sep}/, $ENV{PATH}) {
	    if (-f "$dir/cc3250mt.dll") {
		$bcc_dir = $dir and last;
	    }
	}
	if (defined $bcc_dir) {
	    require File::Copy;
	    File::Copy::copy("$bcc_dir/cc3250mt.dll", '.') or
		die "$0: failed to copy cc3250mt.dll: $!\n";
	    eval q{
		END { unlink "cc3250mt.dll" }
	    };
	}
    }
    $ENV{PATH} = ($Is_Cygwin) ? '/usr/bin' : '';
    delete @ENV{@MoreEnv};
    $ENV{TERM} = 'dumb';

    is(eval { `$echo 1` }, "1\n");

    SKIP: {
        skip "Environment tainting tests skipped", 4
          if $Is_MSWin32 || $Is_NetWare || $Is_VMS || $Is_Dos;

	my @vars = ('PATH', @MoreEnv);
	while (my $v = $vars[0]) {
	    local $ENV{$v} = $TAINT;
	    last if eval { `$echo 1` };
	    last unless $@ =~ /^Insecure \$ENV{$v}/;
	    shift @vars;
	}
	is("@vars", "");

	# tainted $TERM is unsafe only if it contains metachars
	local $ENV{TERM};
	$ENV{TERM} = 'e=mc2';
	is(eval { `$echo 1` }, "1\n");
	$ENV{TERM} = 'e=mc2' . $TAINT;
	is(eval { `$echo 1` }, undef);
	like($@, qr/^Insecure \$ENV{TERM}/);
    }

    my $tmp;
    if ($^O eq 'os2' || $^O eq 'amigaos' || $Is_MSWin32 || $Is_NetWare || $Is_Dos) {
	print "# all directories are writeable\n";
    }
    else {
	$tmp = (grep { defined and -d and (stat _)[2] & 2 }
		     qw(sys$scratch /tmp /var/tmp /usr/tmp),
		     @ENV{qw(TMP TEMP)})[0]
	    or print "# can't find world-writeable directory to test PATH\n";
    }

    SKIP: {
        skip "all directories are writeable", 2 unless $tmp;

	local $ENV{PATH} = $tmp;
	is(eval { `$echo 1` }, undef);
	like($@, qr/^Insecure directory in \$ENV{PATH}/);
    }

    SKIP: {
        skip "This is not VMS", 4 unless $Is_VMS;

	$ENV{'DCL$PATH'} = $TAINT;
	is(eval { `$echo 1` }, '');
	like($@, qr/^Insecure \$ENV{DCL\$PATH}/);
	SKIP: {
            skip q[can't find world-writeable directory to test DCL$PATH], 2
              unless $tmp;

	    $ENV{'DCL$PATH'} = $tmp;
	    is(eval { `$echo 1` }, '');
	    like($@, qr/^Insecure directory in \$ENV{DCL\$PATH}/);
	}
	$ENV{'DCL$PATH'} = '';
    }
}

# Let's see that we can taint and untaint as needed.
{
    my $foo = $TAINT;
    is_tainted($foo);

    # That was a sanity check. If it failed, stop the insanity!
    die "Taint checks don't seem to be enabled" unless tainted $foo;

    $foo = "foo";
    isnt_tainted($foo);

    taint_these($foo);
    is_tainted($foo);

    my @list = 1..10;
    ok(not any_tainted @list);
    taint_these @list[1,3,5,7,9];
    ok(any_tainted @list);
    ok(all_tainted @list[1,3,5,7,9]);
    ok(not any_tainted @list[0,2,4,6,8]);

    ($foo) = $foo =~ /(.+)/;
    isnt_tainted($foo);

    my ($desc, $s, $res, $res2, $one);

    $desc = "match with string tainted";

    $s = 'abcd' . $TAINT;
    $res = $s =~ /(.+)/;
    $one = $1;
    is_tainted($s,     "$desc: s tainted");
    isnt_tainted($res, "$desc: res not tainted");
    isnt_tainted($one, "$desc: \$1 not tainted");
    is($res, 1,        "$desc: res value");
    is($one, 'abcd',   "$desc: \$1 value");

    $desc = "match /g with string tainted";

    $s = 'abcd' . $TAINT;
    $res = $s =~ /(.)/g;
    $one = $1;
    is_tainted($s,     "$desc: s tainted");
    isnt_tainted($res, "$desc: res not tainted");
    isnt_tainted($one, "$desc: \$1 not tainted");
    is($res, 1,        "$desc: res value");
    is($one, 'a',      "$desc: \$1 value");

    $desc = "match with string tainted, list cxt";

    $s = 'abcd' . $TAINT;
    ($res) = $s =~ /(.+)/;
    $one = $1;
    is_tainted($s,     "$desc: s tainted");
    isnt_tainted($res, "$desc: res not tainted");
    isnt_tainted($one, "$desc: \$1 not tainted");
    is($res, 'abcd',   "$desc: res value");
    is($one, 'abcd',   "$desc: \$1 value");

    $desc = "match /g with string tainted, list cxt";

    $s = 'abcd' . $TAINT;
    ($res, $res2) = $s =~ /(.)/g;
    $one = $1;
    is_tainted($s,     "$desc: s tainted");
    isnt_tainted($res, "$desc: res not tainted");
    isnt_tainted($res2,"$desc: res2 not tainted");
    isnt_tainted($one, "$desc: \$1 not tainted");
    is($res, 'a',      "$desc: res value");
    is($res2,'b',      "$desc: res2 value");
    is($one, 'd',      "$desc: \$1 value");

    $desc = "match with pattern tainted";

    $s = 'abcd';
    $res = $s =~ /$TAINT(.+)/;
    $one = $1;
    isnt_tainted($s,   "$desc: s not tainted");
    isnt_tainted($res, "$desc: res not tainted");
    is_tainted($one,   "$desc: \$1 tainted");
    is($res, 1,        "$desc: res value");
    is($one, 'abcd',   "$desc: \$1 value");

    $desc = "match /g with pattern tainted";

    $s = 'abcd';
    $res = $s =~ /$TAINT(.)/g;
    $one = $1;
    isnt_tainted($s,   "$desc: s not tainted");
    isnt_tainted($res, "$desc: res not tainted");
    is_tainted($one,   "$desc: \$1 tainted");
    is($res, 1,        "$desc: res value");
    is($one, 'a',      "$desc: \$1 value");

    $desc = "match with pattern tainted via locale";

    $s = 'abcd';
    { use locale; $res = $s =~ /(\w+)/; $one = $1; }
    isnt_tainted($s,   "$desc: s not tainted");
    isnt_tainted($res, "$desc: res not tainted");
    is_tainted($one,   "$desc: \$1 tainted");
    is($res, 1,        "$desc: res value");
    is($one, 'abcd',   "$desc: \$1 value");

    $desc = "match /g with pattern tainted via locale";

    $s = 'abcd';
    { use locale; $res = $s =~ /(\w)/g; $one = $1; }
    isnt_tainted($s,   "$desc: s not tainted");
    isnt_tainted($res, "$desc: res not tainted");
    is_tainted($one,   "$desc: \$1 tainted");
    is($res, 1,        "$desc: res value");
    is($one, 'a',      "$desc: \$1 value");

    $desc = "match with pattern tainted, list cxt";

    $s = 'abcd';
    ($res) = $s =~ /$TAINT(.+)/;
    $one = $1;
    isnt_tainted($s,   "$desc: s not tainted");
    is_tainted($res,   "$desc: res tainted");
    is_tainted($one,   "$desc: \$1 tainted");
    is($res, 'abcd',   "$desc: res value");
    is($one, 'abcd',   "$desc: \$1 value");

    $desc = "match /g with pattern tainted, list cxt";

    $s = 'abcd';
    ($res, $res2) = $s =~ /$TAINT(.)/g;
    $one = $1;
    isnt_tainted($s,   "$desc: s not tainted");
    is_tainted($res,   "$desc: res tainted");
    is_tainted($one,   "$desc: \$1 tainted");
    is($res, 'a',      "$desc: res value");
    is($res2,'b',      "$desc: res2 value");
    is($one, 'd',      "$desc: \$1 value");

    $desc = "match with pattern tainted via locale, list cxt";

    $s = 'abcd';
    { use locale; ($res) = $s =~ /(\w+)/; $one = $1; }
    isnt_tainted($s,   "$desc: s not tainted");
    is_tainted($res,   "$desc: res tainted");
    is_tainted($one,   "$desc: \$1 tainted");
    is($res, 'abcd',   "$desc: res value");
    is($one, 'abcd',   "$desc: \$1 value");

    $desc = "match /g with pattern tainted via locale, list cxt";

    $s = 'abcd';
    { use locale; ($res, $res2) = $s =~ /(\w)/g; $one = $1; }
    isnt_tainted($s,   "$desc: s not tainted");
    is_tainted($res,   "$desc: res tainted");
    is_tainted($res2,  "$desc: res2 tainted");
    is_tainted($one,   "$desc: \$1 tainted");
    is($res, 'a',      "$desc: res value");
    is($res2,'b',      "$desc: res2 value");
    is($one, 'd',      "$desc: \$1 value");

    $desc = "substitution with string tainted";

    $s = 'abcd' . $TAINT;
    $res = $s =~ s/(.+)/xyz/;
    $one = $1;
    is_tainted($s,     "$desc: s tainted");
    isnt_tainted($res, "$desc: res not tainted");
    isnt_tainted($one, "$desc: \$1 not tainted");
    is($s,   'xyz',    "$desc: s value");
    is($res, 1,        "$desc: res value");
    is($one, 'abcd',   "$desc: \$1 value");

    $desc = "substitution /g with string tainted";

    $s = 'abcd' . $TAINT;
    $res = $s =~ s/(.)/x/g;
    $one = $1;
    is_tainted($s,     "$desc: s tainted");
    is_tainted($res,   "$desc: res tainted");
    isnt_tainted($one, "$desc: \$1 not tainted");
    is($s,   'xxxx',   "$desc: s value");
    is($res, 4,        "$desc: res value");
    is($one, 'd',      "$desc: \$1 value");

    $desc = "substitution /r with string tainted";

    $s = 'abcd' . $TAINT;
    $res = $s =~ s/(.+)/xyz/r;
    $one = $1;
    is_tainted($s,     "$desc: s tainted");
    is_tainted($res,   "$desc: res tainted");
    isnt_tainted($one, "$desc: \$1 not tainted");
    is($s,   'abcd',   "$desc: s value");
    is($res, 'xyz',    "$desc: res value");
    is($one, 'abcd',   "$desc: \$1 value");

    $desc = "substitution /e with string tainted";

    $s = 'abcd' . $TAINT;
    $one = '';
    $res = $s =~ s{(.+)}{
		$one = $one . "x"; # make sure code not tainted
		isnt_tainted($one, "$desc: code not tainted within /e");
		$one = $1;
		isnt_tainted($one, "$desc: \$1 not tainted within /e");
		"xyz";
	    }e;
    $one = $1;
    is_tainted($s,     "$desc: s tainted");
    isnt_tainted($res, "$desc: res not tainted");
    isnt_tainted($one, "$desc: \$1 not tainted");
    is($s,   'xyz',    "$desc: s value");
    is($res, 1,        "$desc: res value");
    is($one, 'abcd',   "$desc: \$1 value");

    $desc = "substitution with pattern tainted";

    $s = 'abcd';
    $res = $s =~ s/$TAINT(.+)/xyz/;
    $one = $1;
    is_tainted($s,     "$desc: s tainted");
    isnt_tainted($res, "$desc: res not tainted");
    is_tainted($one,   "$desc: \$1 tainted");
    is($s,  'xyz',     "$desc: s value");
    is($res, 1,        "$desc: res value");
    is($one, 'abcd',   "$desc: \$1 value");

    $desc = "substitution /g with pattern tainted";

    $s = 'abcd';
    $res = $s =~ s/$TAINT(.)/x/g;
    $one = $1;
    is_tainted($s,     "$desc: s tainted");
    is_tainted($res,   "$desc: res tainted");
    is_tainted($one,   "$desc: \$1 tainted");
    is($s,  'xxxx',    "$desc: s value");
    is($res, 4,        "$desc: res value");
    is($one, 'd',      "$desc: \$1 value");

    $desc = "substitution /ge with pattern tainted";

    $s = 'abc';
    {
	my $i = 0;
	my $j;
	$res = $s =~ s{(.)$TAINT}{
		    $j = $i; # make sure code not tainted
		    $one = $1;
		    isnt_tainted($j, "$desc: code not tainted within /e");
		    $i++;
		    if ($i == 1) {
			isnt_tainted($s,   "$desc: s not tainted loop 1");
		    }
		    else {
			is_tainted($s,     "$desc: s tainted loop $i");
		    }
		    is_tainted($one,   "$desc: \$1 tainted loop $i");
		    $i.$TAINT;
		}ge;
	$one = $1;
    }
    is_tainted($s,     "$desc: s tainted");
    is_tainted($res,   "$desc: res tainted");
    is_tainted($one,   "$desc: \$1 tainted");
    is($s,  '123',     "$desc: s value");
    is($res, 3,        "$desc: res value");
    is($one, 'c',      "$desc: \$1 value");

    $desc = "substitution /r with pattern tainted";

    $s = 'abcd';
    $res = $s =~ s/$TAINT(.+)/xyz/r;
    $one = $1;
    isnt_tainted($s,   "$desc: s not tainted");
    is_tainted($res,   "$desc: res tainted");
    is_tainted($one,   "$desc: \$1 tainted");
    is($s,  'abcd',    "$desc: s value");
    is($res, 'xyz',    "$desc: res value");
    is($one, 'abcd',   "$desc: \$1 value");

    $desc = "substitution with pattern tainted via locale";

    $s = 'abcd';
    { use locale;  $res = $s =~ s/(\w+)/xyz/; $one = $1; }
    is_tainted($s,     "$desc: s tainted");
    isnt_tainted($res, "$desc: res not tainted");
    is_tainted($one,   "$desc: \$1 tainted");
    is($s,  'xyz',     "$desc: s value");
    is($res, 1,        "$desc: res value");
    is($one, 'abcd',   "$desc: \$1 value");

    $desc = "substitution /g with pattern tainted via locale";

    $s = 'abcd';
    { use locale;  $res = $s =~ s/(\w)/x/g; $one = $1; }
    is_tainted($s,     "$desc: s tainted");
    is_tainted($res,   "$desc: res tainted");
    is_tainted($one,   "$desc: \$1 tainted");
    is($s,  'xxxx',    "$desc: s value");
    is($res, 4,        "$desc: res value");
    is($one, 'd',      "$desc: \$1 value");

    $desc = "substitution /r with pattern tainted via locale";

    $s = 'abcd';
    { use locale;  $res = $s =~ s/(\w+)/xyz/r; $one = $1; }
    isnt_tainted($s,   "$desc: s not tainted");
    is_tainted($res,   "$desc: res tainted");
    is_tainted($one,   "$desc: \$1 tainted");
    is($s,  'abcd',    "$desc: s value");
    is($res, 'xyz',    "$desc: res value");
    is($one, 'abcd',   "$desc: \$1 value");

    $desc = "substitution with replacement tainted";

    $s = 'abcd';
    $res = $s =~ s/(.+)/xyz$TAINT/;
    $one = $1;
    is_tainted($s,     "$desc: s tainted");
    isnt_tainted($res, "$desc: res not tainted");
    isnt_tainted($one, "$desc: \$1 not tainted");
    is($s,  'xyz',     "$desc: s value");
    is($res, 1,        "$desc: res value");
    is($one, 'abcd',   "$desc: \$1 value");

    $desc = "substitution /g with replacement tainted";

    $s = 'abcd';
    $res = $s =~ s/(.)/x$TAINT/g;
    $one = $1;
    is_tainted($s,     "$desc: s tainted");
    isnt_tainted($res, "$desc: res not tainted");
    isnt_tainted($one, "$desc: \$1 not tainted");
    is($s,  'xxxx',    "$desc: s value");
    is($res, 4,        "$desc: res value");
    is($one, 'd',      "$desc: \$1 value");

    $desc = "substitution /ge with replacement tainted";

    $s = 'abc';
    {
	my $i = 0;
	my $j;
	$res = $s =~ s{(.)}{
		    $j = $i; # make sure code not tainted
		    $one = $1;
		    isnt_tainted($j, "$desc: code not tainted within /e");
		    $i++;
		    if ($i == 1) {
			isnt_tainted($s,   "$desc: s not tainted loop 1");
		    }
		    else {
			is_tainted($s,     "$desc: s tainted loop $i");
		    }
		    isnt_tainted($one, "$desc: \$1 not tainted within /e");
		    $i.$TAINT;
		}ge;
	$one = $1;
    }
    is_tainted($s,     "$desc: s tainted");
    is_tainted($res,   "$desc: res tainted");
    isnt_tainted($one, "$desc: \$1 not tainted");
    is($s,  '123',     "$desc: s value");
    is($res, 3,        "$desc: res value");
    is($one, 'c',      "$desc: \$1 value");

    $desc = "substitution /r with replacement tainted";

    $s = 'abcd';
    $res = $s =~ s/(.+)/xyz$TAINT/r;
    $one = $1;
    isnt_tainted($s,   "$desc: s not tainted");
    is_tainted($res,   "$desc: res tainted");
    isnt_tainted($one, "$desc: \$1 not tainted");
    is($s,   'abcd',   "$desc: s value");
    is($res, 'xyz',    "$desc: res value");
    is($one, 'abcd',   "$desc: \$1 value");

    {
	# now do them all again with "use re 'taint"

	use re 'taint';

	$desc = "use re 'taint': match with string tainted";

	$s = 'abcd' . $TAINT;
	$res = $s =~ /(.+)/;
	$one = $1;
	is_tainted($s,     "$desc: s tainted");
	isnt_tainted($res, "$desc: res not tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($res, 1,        "$desc: res value");
	is($one, 'abcd',   "$desc: \$1 value");

	$desc = "use re 'taint': match /g with string tainted";

	$s = 'abcd' . $TAINT;
	$res = $s =~ /(.)/g;
	$one = $1;
	is_tainted($s,     "$desc: s tainted");
	isnt_tainted($res, "$desc: res not tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($res, 1,        "$desc: res value");
	is($one, 'a',      "$desc: \$1 value");

	$desc = "use re 'taint': match with string tainted, list cxt";

	$s = 'abcd' . $TAINT;
	($res) = $s =~ /(.+)/;
	$one = $1;
	is_tainted($s,     "$desc: s tainted");
	is_tainted($res,   "$desc: res tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($res, 'abcd',   "$desc: res value");
	is($one, 'abcd',   "$desc: \$1 value");

	$desc = "use re 'taint': match /g with string tainted, list cxt";

	$s = 'abcd' . $TAINT;
	($res, $res2) = $s =~ /(.)/g;
	$one = $1;
	is_tainted($s,     "$desc: s tainted");
	is_tainted($res,   "$desc: res tainted");
	is_tainted($res2,  "$desc: res2 tainted");
	is_tainted($one,   "$desc: \$1 not tainted");
	is($res, 'a',      "$desc: res value");
	is($res2,'b',      "$desc: res2 value");
	is($one, 'd',      "$desc: \$1 value");

	$desc = "use re 'taint': match with pattern tainted";

	$s = 'abcd';
	$res = $s =~ /$TAINT(.+)/;
	$one = $1;
	isnt_tainted($s,   "$desc: s not tainted");
	isnt_tainted($res, "$desc: res not tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($res, 1,        "$desc: res value");
	is($one, 'abcd',   "$desc: \$1 value");

	$desc = "use re 'taint': match /g with pattern tainted";

	$s = 'abcd';
	$res = $s =~ /$TAINT(.)/g;
	$one = $1;
	isnt_tainted($s,   "$desc: s not tainted");
	isnt_tainted($res, "$desc: res not tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($res, 1,        "$desc: res value");
	is($one, 'a',      "$desc: \$1 value");

	$desc = "use re 'taint': match with pattern tainted via locale";

	$s = 'abcd';
	{ use locale; $res = $s =~ /(\w+)/; $one = $1; }
	isnt_tainted($s,   "$desc: s not tainted");
	isnt_tainted($res, "$desc: res not tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($res, 1,        "$desc: res value");
	is($one, 'abcd',   "$desc: \$1 value");

	$desc = "use re 'taint': match /g with pattern tainted via locale";

	$s = 'abcd';
	{ use locale; $res = $s =~ /(\w)/g; $one = $1; }
	isnt_tainted($s,   "$desc: s not tainted");
	isnt_tainted($res, "$desc: res not tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($res, 1,        "$desc: res value");
	is($one, 'a',      "$desc: \$1 value");

	$desc = "use re 'taint': match with pattern tainted, list cxt";

	$s = 'abcd';
	($res) = $s =~ /$TAINT(.+)/;
	$one = $1;
	isnt_tainted($s,   "$desc: s not tainted");
	is_tainted($res,   "$desc: res tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($res, 'abcd',   "$desc: res value");
	is($one, 'abcd',   "$desc: \$1 value");

	$desc = "use re 'taint': match /g with pattern tainted, list cxt";

	$s = 'abcd';
	($res, $res2) = $s =~ /$TAINT(.)/g;
	$one = $1;
	isnt_tainted($s,   "$desc: s not tainted");
	is_tainted($res,   "$desc: res tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($res, 'a',      "$desc: res value");
	is($res2,'b',      "$desc: res2 value");
	is($one, 'd',      "$desc: \$1 value");

	$desc = "use re 'taint': match with pattern tainted via locale, list cxt";

	$s = 'abcd';
	{ use locale; ($res) = $s =~ /(\w+)/; $one = $1; }
	isnt_tainted($s,   "$desc: s not tainted");
	is_tainted($res,   "$desc: res tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($res, 'abcd',   "$desc: res value");
	is($one, 'abcd',   "$desc: \$1 value");

	$desc = "use re 'taint': match /g with pattern tainted via locale, list cxt";

	$s = 'abcd';
	{ use locale; ($res, $res2) = $s =~ /(\w)/g; $one = $1; }
	isnt_tainted($s,   "$desc: s not tainted");
	is_tainted($res,   "$desc: res tainted");
	is_tainted($res2,  "$desc: res2 tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($res, 'a',      "$desc: res value");
	is($res2,'b',      "$desc: res2 value");
	is($one, 'd',      "$desc: \$1 value");

	$desc = "use re 'taint': substitution with string tainted";

	$s = 'abcd' . $TAINT;
	$res = $s =~ s/(.+)/xyz/;
	$one = $1;
	is_tainted($s,     "$desc: s tainted");
	isnt_tainted($res, "$desc: res not tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($s,   'xyz',    "$desc: s value");
	is($res, 1,        "$desc: res value");
	is($one, 'abcd',   "$desc: \$1 value");

	$desc = "use re 'taint': substitution /g with string tainted";

	$s = 'abcd' . $TAINT;
	$res = $s =~ s/(.)/x/g;
	$one = $1;
	is_tainted($s,     "$desc: s tainted");
	is_tainted($res,   "$desc: res tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($s,   'xxxx',   "$desc: s value");
	is($res, 4,        "$desc: res value");
	is($one, 'd',      "$desc: \$1 value");

	$desc = "use re 'taint': substitution /r with string tainted";

	$s = 'abcd' . $TAINT;
	$res = $s =~ s/(.+)/xyz/r;
	$one = $1;
	is_tainted($s,     "$desc: s tainted");
	is_tainted($res,   "$desc: res tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($s,   'abcd',   "$desc: s value");
	is($res, 'xyz',    "$desc: res value");
	is($one, 'abcd',   "$desc: \$1 value");

	$desc = "use re 'taint': substitution /e with string tainted";

	$s = 'abcd' . $TAINT;
	$one = '';
	$res = $s =~ s{(.+)}{
		    $one = $one . "x"; # make sure code not tainted
		    isnt_tainted($one, "$desc: code not tainted within /e");
		    $one = $1;
		    is_tainted($one, "$desc: $1 tainted within /e");
		    "xyz";
		}e;
	$one = $1;
	is_tainted($s,     "$desc: s tainted");
	isnt_tainted($res, "$desc: res not tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($s,   'xyz',    "$desc: s value");
	is($res, 1,        "$desc: res value");
	is($one, 'abcd',   "$desc: \$1 value");

	$desc = "use re 'taint': substitution with pattern tainted";

	$s = 'abcd';
	$res = $s =~ s/$TAINT(.+)/xyz/;
	$one = $1;
	is_tainted($s,     "$desc: s tainted");
	isnt_tainted($res, "$desc: res not tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($s,  'xyz',     "$desc: s value");
	is($res, 1,        "$desc: res value");
	is($one, 'abcd',   "$desc: \$1 value");

	$desc = "use re 'taint': substitution /g with pattern tainted";

	$s = 'abcd';
	$res = $s =~ s/$TAINT(.)/x/g;
	$one = $1;
	is_tainted($s,     "$desc: s tainted");
	is_tainted($res,   "$desc: res tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($s,  'xxxx',    "$desc: s value");
	is($res, 4,        "$desc: res value");
	is($one, 'd',      "$desc: \$1 value");

	$desc = "use re 'taint': substitution /ge with pattern tainted";

	$s = 'abc';
	{
	    my $i = 0;
	    my $j;
	    $res = $s =~ s{(.)$TAINT}{
			$j = $i; # make sure code not tainted
			$one = $1;
			isnt_tainted($j, "$desc: code not tainted within /e");
			$i++;
			if ($i == 1) {
			    isnt_tainted($s,   "$desc: s not tainted loop 1");
			}
			else {
			    is_tainted($s,     "$desc: s tainted loop $i");
			}
			is_tainted($one,   "$desc: \$1 tainted loop $i");
			$i.$TAINT;
		    }ge;
	    $one = $1;
	}
	is_tainted($s,     "$desc: s tainted");
	is_tainted($res,   "$desc: res tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($s,  '123',     "$desc: s value");
	is($res, 3,        "$desc: res value");
	is($one, 'c',      "$desc: \$1 value");


	$desc = "use re 'taint': substitution /r with pattern tainted";

	$s = 'abcd';
	$res = $s =~ s/$TAINT(.+)/xyz/r;
	$one = $1;
	isnt_tainted($s,   "$desc: s not tainted");
	is_tainted($res,   "$desc: res tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($s,  'abcd',    "$desc: s value");
	is($res, 'xyz',    "$desc: res value");
	is($one, 'abcd',   "$desc: \$1 value");

	$desc = "use re 'taint': substitution with pattern tainted via locale";

	$s = 'abcd';
	{ use locale;  $res = $s =~ s/(\w+)/xyz/; $one = $1; }
	is_tainted($s,     "$desc: s tainted");
	isnt_tainted($res, "$desc: res not tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($s,  'xyz',     "$desc: s value");
	is($res, 1,        "$desc: res value");
	is($one, 'abcd',   "$desc: \$1 value");

	$desc = "use re 'taint': substitution /g with pattern tainted via locale";

	$s = 'abcd';
	{ use locale;  $res = $s =~ s/(\w)/x/g; $one = $1; }
	is_tainted($s,     "$desc: s tainted");
	is_tainted($res,   "$desc: res tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($s,  'xxxx',    "$desc: s value");
	is($res, 4,        "$desc: res value");
	is($one, 'd',      "$desc: \$1 value");

	$desc = "use re 'taint': substitution /r with pattern tainted via locale";

	$s = 'abcd';
	{ use locale;  $res = $s =~ s/(\w+)/xyz/r; $one = $1; }
	isnt_tainted($s,   "$desc: s not tainted");
	is_tainted($res,   "$desc: res tainted");
	is_tainted($one,   "$desc: \$1 tainted");
	is($s,  'abcd',    "$desc: s value");
	is($res, 'xyz',    "$desc: res value");
	is($one, 'abcd',   "$desc: \$1 value");

	$desc = "use re 'taint': substitution with replacement tainted";

	$s = 'abcd';
	$res = $s =~ s/(.+)/xyz$TAINT/;
	$one = $1;
	is_tainted($s,     "$desc: s tainted");
	isnt_tainted($res, "$desc: res not tainted");
	isnt_tainted($one, "$desc: \$1 not tainted");
	is($s,  'xyz',     "$desc: s value");
	is($res, 1,        "$desc: res value");
	is($one, 'abcd',   "$desc: \$1 value");

	$desc = "use re 'taint': substitution /g with replacement tainted";

	$s = 'abcd';
	$res = $s =~ s/(.)/x$TAINT/g;
	$one = $1;
	is_tainted($s,     "$desc: s tainted");
	isnt_tainted($res, "$desc: res not tainted");
	isnt_tainted($one, "$desc: \$1 not tainted");
	is($s,  'xxxx',    "$desc: s value");
	is($res, 4,        "$desc: res value");
	is($one, 'd',      "$desc: \$1 value");

	$desc = "use re 'taint': substitution /ge with replacement tainted";

	$s = 'abc';
	{
	    my $i = 0;
	    my $j;
	    $res = $s =~ s{(.)}{
			$j = $i; # make sure code not tainted
			$one = $1;
			isnt_tainted($j, "$desc: code not tainted within /e");
			$i++;
			if ($i == 1) {
			    isnt_tainted($s,   "$desc: s not tainted loop 1");
			}
			else {
			    is_tainted($s,     "$desc: s tainted loop $i");
			}
			    isnt_tainted($one, "$desc: \$1 not tainted");
			$i.$TAINT;
		    }ge;
	    $one = $1;
	}
	is_tainted($s,     "$desc: s tainted");
	is_tainted($res,   "$desc: res tainted");
	isnt_tainted($one, "$desc: \$1 not tainted");
	is($s,  '123',     "$desc: s value");
	is($res, 3,        "$desc: res value");
	is($one, 'c',      "$desc: \$1 value");

	$desc = "use re 'taint': substitution /r with replacement tainted";

	$s = 'abcd';
	$res = $s =~ s/(.+)/xyz$TAINT/r;
	$one = $1;
	isnt_tainted($s,   "$desc: s not tainted");
	is_tainted($res,   "$desc: res tainted");
	isnt_tainted($one, "$desc: \$1 not tainted");
	is($s,   'abcd',   "$desc: s value");
	is($res, 'xyz',    "$desc: res value");
	is($one, 'abcd',   "$desc: \$1 value");
    }

    $foo = $1 if 'bar' =~ /(.+)$TAINT/;
    is_tainted($foo);
    is($foo, 'bar');

    my $pi = 4 * atan2(1,1) + $TAINT0;
    is_tainted($pi);

    ($pi) = $pi =~ /(\d+\.\d+)/;
    isnt_tainted($pi);
    is(sprintf("%.5f", $pi), '3.14159');
}

# How about command-line arguments? The problem is that we don't
# always get some, so we'll run another process with some.
SKIP: {
    my $arg = tempfile();
    open PROG, "> $arg" or die "Can't create $arg: $!";
    print PROG q{
	eval { join('', @ARGV), kill 0 };
	exit 0 if $@ =~ /^Insecure dependency/;
	print "# Oops: \$@ was [$@]\n";
	exit 1;
    };
    close PROG;
    print `$Invoke_Perl "-T" $arg and some suspect arguments`;
    is($?, 0, "Exited with status $?");
    unlink $arg;
}

# Reading from a file should be tainted
{
    ok(open FILE, $TEST) or diag("Couldn't open '$TEST': $!");

    my $block;
    sysread(FILE, $block, 100);
    my $line = <FILE>;
    close FILE;
    is_tainted($block);
    is_tainted($line);
}

# Output of commands should be tainted
{
    my $foo = `$echo abc`;
    is_tainted($foo);
}

# Certain system variables should be tainted
{
    ok(all_tainted $^X, $0);
}

# Results of matching should all be untainted
{
    my $foo = "abcdefghi" . $TAINT;
    is_tainted($foo);

    $foo =~ /def/;
    ok(not any_tainted $`, $&, $');

    $foo =~ /(...)(...)(...)/;
    ok(not any_tainted $1, $2, $3, $+);

    my @bar = $foo =~ /(...)(...)(...)/;
    ok(not any_tainted @bar);

    is_tainted($foo);	# $foo should still be tainted!
    is($foo, "abcdefghi");
}

# Operations which affect files can't use tainted data.
{
    is(eval { chmod 0, $TAINT }, undef, 'chmod');
    like($@, qr/^Insecure dependency/);

    SKIP: {
        skip "truncate() is not available", 2 unless $Config{d_truncate};

	is(eval { truncate 'NoSuChFiLe', $TAINT0 }, undef, 'truncate');
	like($@, qr/^Insecure dependency/);
    }

    is(eval { rename '', $TAINT }, undef, 'rename');
    like($@, qr/^Insecure dependency/);

    is(eval { unlink $TAINT }, undef, 'unlink');
    like($@, qr/^Insecure dependency/);

    is(eval { utime $TAINT }, undef, 'utime');
    like($@, qr/^Insecure dependency/);

    SKIP: {
        skip "chown() is not available", 2 unless $Config{d_chown};

	is(eval { chown -1, -1, $TAINT }, undef, 'chown');
	like($@, qr/^Insecure dependency/);
    }

    SKIP: {
        skip "link() is not available", 2 unless $Config{d_link};

	is(eval { link $TAINT, '' }, undef, 'link');
	like($@, qr/^Insecure dependency/);
    }

    SKIP: {
        skip "symlink() is not available", 2 unless $Config{d_symlink};

	is(eval { symlink $TAINT, '' }, undef, 'symlink');
	like($@, qr/^Insecure dependency/);
    }
}

# Operations which affect directories can't use tainted data.
{
    is(eval { mkdir "foo".$TAINT, 0755 . $TAINT0 }, undef, 'mkdir');
    like($@, qr/^Insecure dependency/);

    is(eval { rmdir $TAINT }, undef, 'rmdir');
    like($@, qr/^Insecure dependency/);

    is(eval { chdir "foo".$TAINT }, undef, 'chdir');
    like($@, qr/^Insecure dependency/);

    SKIP: {
        skip "chroot() is not available", 2 unless $Config{d_chroot};

	is(eval { chroot $TAINT }, undef, 'chroot');
	like($@, qr/^Insecure dependency/);
    }
}

# Some operations using files can't use tainted data.
{
    my $foo = "imaginary library" . $TAINT;
    is(eval { require $foo }, undef, 'require');
    like($@, qr/^Insecure dependency/);

    my $filename = tempfile();	# NB: $filename isn't tainted!
    $foo = $filename . $TAINT;
    unlink $filename;	# in any case

    is(eval { open FOO, $foo }, undef, 'open for read');
    is($@, '');		# NB: This should be allowed

    # Try first new style but allow also old style.
    # We do not want the whole taint.t to fail
    # just because Errno possibly failing.
    ok(eval('$!{ENOENT}') ||
	$! == 2 || # File not found
	($Is_Dos && $! == 22));

    is(eval { open FOO, "> $foo" }, undef, 'open for write');
    like($@, qr/^Insecure dependency/);
}

# Commands to the system can't use tainted data
{
    my $foo = $TAINT;

    SKIP: {
        skip "open('|') is not available", 4 if $^O eq 'amigaos';

	is(eval { open FOO, "| x$foo" }, undef, 'popen to');
	like($@, qr/^Insecure dependency/);

	is(eval { open FOO, "x$foo |" }, undef, 'popen from');
	like($@, qr/^Insecure dependency/);
    }

    is(eval { exec $TAINT }, undef, 'exec');
    like($@, qr/^Insecure dependency/);

    is(eval { system $TAINT }, undef, 'system');
    like($@, qr/^Insecure dependency/);

    $foo = "*";
    taint_these $foo;

    is(eval { `$echo 1$foo` }, undef, 'backticks');
    like($@, qr/^Insecure dependency/);

    SKIP: {
        # wildcard expansion doesn't invoke shell on VMS, so is safe
        skip "This is not VMS", 2 unless $Is_VMS;
    
	isnt(join('', eval { glob $foo } ), '', 'globbing');
	is($@, '');
    }
}

# Operations which affect processes can't use tainted data.
{
    is(eval { kill 0, $TAINT }, undef, 'kill');
    like($@, qr/^Insecure dependency/);

    SKIP: {
        skip "setpgrp() is not available", 2 unless $Config{d_setpgrp};

	is(eval { setpgrp 0, $TAINT0 }, undef, 'setpgrp');
	like($@, qr/^Insecure dependency/);
    }

    SKIP: {
        skip "setpriority() is not available", 2 unless $Config{d_setprior};

	is(eval { setpriority 0, $TAINT0, $TAINT0 }, undef, 'setpriority');
	like($@, qr/^Insecure dependency/);
    }
}

# Some miscellaneous operations can't use tainted data.
{
    SKIP: {
        skip "syscall() is not available", 2 unless $Config{d_syscall};

	is(eval { syscall $TAINT }, undef, 'syscall');
	like($@, qr/^Insecure dependency/);
    }

    {
	my $foo = "x" x 979;
	taint_these $foo;
	local *FOO;
	my $temp = tempfile();
	ok(open FOO, "> $temp") or diag("Couldn't open $temp for write: $!");

	is(eval { ioctl FOO, $TAINT0, $foo }, undef, 'ioctl');
	like($@, qr/^Insecure dependency/);

        SKIP: {
            skip "fcntl() is not available", 2 unless $Config{d_fcntl};

	    is(eval { fcntl FOO, $TAINT0, $foo }, undef, 'fcntl');
	    like($@, qr/^Insecure dependency/);
	}

	close FOO;
    }
}

# Some tests involving references
{
    my $foo = 'abc' . $TAINT;
    my $fooref = \$foo;
    isnt_tainted($fooref);
    is_tainted($$fooref);
    is_tainted($foo);
}

# Some tests involving assignment
{
    my $foo = $TAINT0;
    my $bar = $foo;
    ok(all_tainted $foo, $bar);
    is_tainted($foo = $bar);
    is_tainted($bar = $bar);
    is_tainted($bar += $bar);
    is_tainted($bar -= $bar);
    is_tainted($bar *= $bar);
    is_tainted($bar++);
    is_tainted($bar /= $bar);
    is_tainted($bar += 0);
    is_tainted($bar -= 2);
    is_tainted($bar *= -1);
    is_tainted($bar /= 1);
    is_tainted($bar--);
    is($bar, 0);
}

# Test assignment and return of lists
{
    my @foo = ("A", "tainted" . $TAINT, "B");
    isnt_tainted($foo[0]);
    is_tainted(    $foo[1]);
    isnt_tainted($foo[2]);
    my @bar = @foo;
    isnt_tainted($bar[0]);
    is_tainted(    $bar[1]);
    isnt_tainted($bar[2]);
    my @baz = eval { "A", "tainted" . $TAINT, "B" };
    isnt_tainted($baz[0]);
    is_tainted(    $baz[1]);
    isnt_tainted($baz[2]);
    my @plugh = eval q[ "A", "tainted" . $TAINT, "B" ];
    isnt_tainted($plugh[0]);
    is_tainted(    $plugh[1]);
    isnt_tainted($plugh[2]);
    my $nautilus = sub { "A", "tainted" . $TAINT, "B" };
    isnt_tainted(((&$nautilus)[0]));
    is_tainted(    ((&$nautilus)[1]));
    isnt_tainted(((&$nautilus)[2]));
    my @xyzzy = &$nautilus;
    isnt_tainted($xyzzy[0]);
    is_tainted(    $xyzzy[1]);
    isnt_tainted($xyzzy[2]);
    my $red_october = sub { return "A", "tainted" . $TAINT, "B" };
    isnt_tainted(((&$red_october)[0]));
    is_tainted(    ((&$red_october)[1]));
    isnt_tainted(((&$red_october)[2]));
    my @corge = &$red_october;
    isnt_tainted($corge[0]);
    is_tainted(    $corge[1]);
    isnt_tainted($corge[2]);
}

# Test for system/library calls returning string data of dubious origin.
{
    # No reliable %Config check for getpw*
    SKIP: {
        skip "getpwent() is not available", 9 unless 
          eval { setpwent(); getpwent() };

	setpwent();
	my @getpwent = getpwent();
	die "getpwent: $!\n" unless (@getpwent);
	isnt_tainted($getpwent[0]);
	is_tainted($getpwent[1]);
	isnt_tainted($getpwent[2]);
	isnt_tainted($getpwent[3]);
	isnt_tainted($getpwent[4]);
	isnt_tainted($getpwent[5]);
	is_tainted($getpwent[6], 'ge?cos');
	isnt_tainted($getpwent[7]);
	is_tainted($getpwent[8], 'shell');
	endpwent();
    }

    SKIP: {
        # pretty hard to imagine not
        skip "readdir() is not available", 1 unless $Config{d_readdir};

	local(*D);
	opendir(D, "op") or die "opendir: $!\n";
	my $readdir = readdir(D);
	is_tainted($readdir);
	closedir(D);
    }

    SKIP: {
        skip "readlink() or symlink() is not available" unless 
          $Config{d_readlink} && $Config{d_symlink};

	my $symlink = "sl$$";
	unlink($symlink);
	my $sl = "/something/naughty";
	# it has to be a real path on Mac OS
	symlink($sl, $symlink) or die "symlink: $!\n";
	my $readlink = readlink($symlink);
	is_tainted($readlink);
	unlink($symlink);
    }
}

# test bitwise ops (regression bug)
{
    my $why = "y";
    my $j = "x" | $why;
    isnt_tainted($j);
    $why = $TAINT."y";
    $j = "x" | $why;
    is_tainted(    $j);
}

# test target of substitution (regression bug)
{
    my $why = $TAINT."y";
    $why =~ s/y/z/;
    is_tainted(    $why);

    my $z = "[z]";
    $why =~ s/$z/zee/;
    is_tainted(    $why);

    $why =~ s/e/'-'.$$/ge;
    is_tainted(    $why);
}


SKIP: {
    skip "no IPC::SysV", 2 unless $ipcsysv;

    # test shmread
    SKIP: {
        skip "shm*() not available", 1 unless $Config{d_shm};

        no strict 'subs';
        my $sent = "foobar";
        my $rcvd;
        my $size = 2000;
        my $id = shmget(IPC_PRIVATE, $size, S_IRWXU);

        if (defined $id) {
            if (shmwrite($id, $sent, 0, 60)) {
                if (shmread($id, $rcvd, 0, 60)) {
                    substr($rcvd, index($rcvd, "\0")) = '';
                } else {
                    warn "# shmread failed: $!\n";
                }
            } else {
                warn "# shmwrite failed: $!\n";
            }
            shmctl($id, IPC_RMID, 0) or warn "# shmctl failed: $!\n";
        } else {
            warn "# shmget failed: $!\n";
        }

        skip "SysV shared memory operation failed", 1 unless 
          $rcvd eq $sent;

        is_tainted($rcvd);
    }


    # test msgrcv
    SKIP: {
        skip "msg*() not available", 1 unless $Config{d_msg};

	no strict 'subs';
	my $id = msgget(IPC_PRIVATE, IPC_CREAT | S_IRWXU);

	my $sent      = "message";
	my $type_sent = 1234;
	my $rcvd;
	my $type_rcvd;

	if (defined $id) {
	    if (msgsnd($id, pack("l! a*", $type_sent, $sent), IPC_NOWAIT)) {
		if (msgrcv($id, $rcvd, 60, 0, IPC_NOWAIT)) {
		    ($type_rcvd, $rcvd) = unpack("l! a*", $rcvd);
		} else {
		    warn "# msgrcv failed: $!\n";
		}
	    } else {
		warn "# msgsnd failed: $!\n";
	    }
	    msgctl($id, IPC_RMID, 0) or warn "# msgctl failed: $!\n";
	} else {
	    warn "# msgget failed\n";
	}

        SKIP: {
            skip "SysV message queue operation failed", 1
              unless $rcvd eq $sent && $type_sent == $type_rcvd;

	    is_tainted($rcvd);
	}
    }
}

{
    # bug id 20001004.006

    open IN, $TEST or warn "$0: cannot read $TEST: $!" ;
    local $/;
    my $a = <IN>;
    my $b = <IN>;

    is_tainted($a);
    is_tainted($b);
    is($b, undef);

    close IN;
}

{
    # bug id 20001004.007

    open IN, $TEST or warn "$0: cannot read $TEST: $!" ;
    my $a = <IN>;

    my $c = { a => 42,
	      b => $a };

    isnt_tainted($c->{a});
    is_tainted($c->{b});


    my $d = { a => $a,
	      b => 42 };
    is_tainted($d->{a});
    isnt_tainted($d->{b});


    my $e = { a => 42,
	      b => { c => $a, d => 42 } };
    isnt_tainted($e->{a});
    isnt_tainted($e->{b});
    is_tainted($e->{b}->{c});
    isnt_tainted($e->{b}->{d});

    close IN;
}

{
    # bug id 20010519.003

    BEGIN {
	use vars qw($has_fcntl);
	eval { require Fcntl; import Fcntl; };
	unless ($@) {
	    $has_fcntl = 1;
	}
    }

    SKIP: {
        skip "no Fcntl", 18 unless $has_fcntl;

	my $foo = tempfile();
	my $evil = $foo . $TAINT;

	eval { sysopen(my $ro, $evil, &O_RDONLY) };
	unlike($@, qr/^Insecure dependency/);
	
	eval { sysopen(my $wo, $evil, &O_WRONLY) };
	like($@, qr/^Insecure dependency/);
	
	eval { sysopen(my $rw, $evil, &O_RDWR) };
	like($@, qr/^Insecure dependency/);
	
	eval { sysopen(my $ap, $evil, &O_APPEND) };
	like($@, qr/^Insecure dependency/);
	
	eval { sysopen(my $cr, $evil, &O_CREAT) };
	like($@, qr/^Insecure dependency/);
	
	eval { sysopen(my $tr, $evil, &O_TRUNC) };
	like($@, qr/^Insecure dependency/);
	
	eval { sysopen(my $ro, $foo, &O_RDONLY | $TAINT0) };
	unlike($@, qr/^Insecure dependency/);
	
	eval { sysopen(my $wo, $foo, &O_WRONLY | $TAINT0) };
	like($@, qr/^Insecure dependency/);

	eval { sysopen(my $rw, $foo, &O_RDWR | $TAINT0) };
	like($@, qr/^Insecure dependency/);

	eval { sysopen(my $ap, $foo, &O_APPEND | $TAINT0) };
	like($@, qr/^Insecure dependency/);
	
	eval { sysopen(my $cr, $foo, &O_CREAT | $TAINT0) };
	like($@, qr/^Insecure dependency/);

	eval { sysopen(my $tr, $foo, &O_TRUNC | $TAINT0) };
	like($@, qr/^Insecure dependency/);

	eval { sysopen(my $ro, $foo, &O_RDONLY, $TAINT0) };
	unlike($@, qr/^Insecure dependency/);
	
	eval { sysopen(my $wo, $foo, &O_WRONLY, $TAINT0) };
	like($@, qr/^Insecure dependency/);
	
	eval { sysopen(my $rw, $foo, &O_RDWR, $TAINT0) };
	like($@, qr/^Insecure dependency/);
	
	eval { sysopen(my $ap, $foo, &O_APPEND, $TAINT0) };
	like($@, qr/^Insecure dependency/);
	
	eval { sysopen(my $cr, $foo, &O_CREAT, $TAINT0) };
	like($@, qr/^Insecure dependency/);

	eval { sysopen(my $tr, $foo, &O_TRUNC, $TAINT0) };
	like($@, qr/^Insecure dependency/);
    }
}

{
    # bug 20010526.004

    use warnings;

    my $saw_warning = 0;
    local $SIG{__WARN__} = sub { ++$saw_warning };

    sub fmi {
	my $divnum = shift()/1;
	sprintf("%1.1f\n", $divnum);
    }

    fmi(21 . $TAINT);
    fmi(37);
    fmi(248);

    is($saw_warning, 0);
}


{
    # Bug ID 20010730.010

    my $i = 0;

    sub Tie::TIESCALAR {
        my $class =  shift;
        my $arg   =  shift;

        bless \$arg => $class;
    }

    sub Tie::FETCH {
        $i ++;
        ${$_ [0]}
    }

 
    package main;
 
    my $bar = "The Big Bright Green Pleasure Machine";
    taint_these $bar;
    tie my ($foo), Tie => $bar;

    my $baz = $foo;

    ok $i == 1;
}

{
    # Check that all environment variables are tainted.
    my @untainted;
    while (my ($k, $v) = each %ENV) {
	if (!tainted($v) &&
	    # These we have explicitly untainted or set earlier.
	    $k !~ /^(BASH_ENV|CDPATH|ENV|IFS|PATH|PERL_CORE|TEMP|TERM|TMP)$/) {
	    push @untainted, "# '$k' = '$v'\n";
	}
    }
    is("@untainted", "");
}


ok( ${^TAINT} == 1, '$^TAINT is on' );

eval { ${^TAINT} = 0 };
ok( ${^TAINT},  '$^TAINT is not assignable' );
ok( $@ =~ /^Modification of a read-only value attempted/,
                                'Assigning to ${^TAINT} fails' );

{
    # bug 20011111.105
    
    my $re1 = qr/x$TAINT/;
    is_tainted($re1);
    
    my $re2 = qr/^$re1\z/;
    is_tainted($re2);
    
    my $re3 = "$re2";
    is_tainted($re3);
}

SKIP: {
    skip "system {} has different semantics on Win32", 1 if $Is_MSWin32;

    # bug 20010221.005
    local $ENV{PATH} .= $TAINT;
    eval { system { "echo" } "/arg0", "arg1" };
    like($@, qr/^Insecure \$ENV/);
}

TODO: {
    todo_skip 'tainted %ENV warning occludes tainted arguments warning', 22
      if $Is_VMS;

    # bug 20020208.005 plus some single arg exec/system extras
    my $err = qr/^Insecure dependency/ ;
    is(eval { exec $TAINT, $TAINT }, undef, 'exec');
    like($@, $err);
    is(eval { exec $TAINT $TAINT }, undef, 'exec');
    like($@, $err);
    is(eval { exec $TAINT $TAINT, $TAINT }, undef, 'exec');
    like($@, $err);
    is(eval { exec $TAINT 'notaint' }, undef, 'exec');
    like($@, $err);
    is(eval { exec {'notaint'} $TAINT }, undef, 'exec');
    like($@, $err);

    is(eval { system $TAINT, $TAINT }, undef, 'system');
    like($@, $err);
    is(eval { system $TAINT $TAINT }, undef, 'system');
    like($@, $err);
    is(eval { system $TAINT $TAINT, $TAINT }, undef, 'system');
    like($@, $err);
    is(eval { system $TAINT 'notaint' }, undef, 'system');
    like($@, $err);
    is(eval { system {'notaint'} $TAINT }, undef, 'system');
    like($@, $err);

    eval { 
        no warnings;
        system("lskdfj does not exist","with","args"); 
    };
    is($@, "");

    eval {
	no warnings;
	exec("lskdfj does not exist","with","args"); 
    };
    is($@, "");

    # If you add tests here update also the above skip block for VMS.
}

{
    # [ID 20020704.001] taint propagation failure
    use re 'taint';
    $TAINT =~ /(.*)/;
    is_tainted(my $foo = $1);
}

{
    # [perl #24291] this used to dump core
    our %nonmagicalenv = ( PATH => "util" );
    local *ENV = \%nonmagicalenv;
    eval { system("lskdfj"); };
    like($@, qr/^%ENV is aliased to another variable while running with -T switch/);
    local *ENV = *nonmagicalenv;
    eval { system("lskdfj"); };
    like($@, qr/^%ENV is aliased to %nonmagicalenv while running with -T switch/);
}
{
    # [perl #24248]
    $TAINT =~ /(.*)/;
    isnt_tainted($1);
    my $notaint = $1;
    isnt_tainted($notaint);

    my $l;
    $notaint =~ /($notaint)/;
    $l = $1;
    isnt_tainted($1);
    isnt_tainted($l);
    $notaint =~ /($TAINT)/;
    $l = $1;
    is_tainted($1);
    is_tainted($l);

    $TAINT =~ /($notaint)/;
    $l = $1;
    isnt_tainted($1);
    isnt_tainted($l);
    $TAINT =~ /($TAINT)/;
    $l = $1;
    is_tainted($1);
    is_tainted($l);

    my $r;
    ($r = $TAINT) =~ /($notaint)/;
    isnt_tainted($1);
    ($r = $TAINT) =~ /($TAINT)/;
    is_tainted($1);

    #  [perl #24674]
    # accessing $^O  shoudn't taint it as a side-effect;
    # assigning tainted data to it is now an error

    isnt_tainted($^O);
    if (!$^X) { } elsif ($^O eq 'bar') { }
    isnt_tainted($^O);
    local $^O;  # We're going to clobber something test infrastructure depends on.
    eval '$^O = $^X';
    like($@, qr/Insecure dependency in/);
}

EFFECTIVELY_CONSTANTS: {
    my $tainted_number = 12 + $TAINT0;
    is_tainted( $tainted_number );

    # Even though it's always 0, it's still tainted
    my $tainted_product = $tainted_number * 0;
    is_tainted( $tainted_product );
    is($tainted_product, 0);
}

TERNARY_CONDITIONALS: {
    my $tainted_true  = $TAINT . "blah blah blah";
    my $tainted_false = $TAINT0;
    is_tainted( $tainted_true );
    is_tainted( $tainted_false );

    my $result = $tainted_true ? "True" : "False";
    is($result, "True");
    isnt_tainted( $result );

    $result = $tainted_false ? "True" : "False";
    is($result, "False");
    isnt_tainted( $result );

    my $untainted_whatever = "The Fabulous Johnny Cash";
    my $tainted_whatever = "Soft Cell" . $TAINT;

    $result = $tainted_true ? $tainted_whatever : $untainted_whatever;
    is($result, "Soft Cell");
    is_tainted( $result );

    $result = $tainted_false ? $tainted_whatever : $untainted_whatever;
    is($result, "The Fabulous Johnny Cash");
    isnt_tainted( $result );
}

{
    # rt.perl.org 5900  $1 remains tainted if...
    # 1) The regular expression contains a scalar variable AND
    # 2) The regular expression appears in an elsif clause

    my $foo = "abcdefghi" . $TAINT;

    my $valid_chars = 'a-z';
    if ( $foo eq '' ) {
    }
    elsif ( $foo =~ /([$valid_chars]+)/o ) {
        isnt_tainted($1);
    }

    if ( $foo eq '' ) {
    }
    elsif ( my @bar = $foo =~ /([$valid_chars]+)/o ) {
        ok(not any_tainted @bar);
    }
}

# at scope exit, a restored localised value should have its old
# taint status, not the taint status of the current statement

{
    our $x99 = $^X;
    is_tainted($x99);

    $x99 = '';
    isnt_tainted($x99);

    my $c = do { local $x99; $^X };
    isnt_tainted($x99);
}
{
    our $x99 = $^X;
    is_tainted($x99);

    my $c = do { local $x99; '' };
    is_tainted($x99);
}

# an mg_get of a tainted value during localization shouldn't taint the
# statement

{
    eval { local $0, eval '1' };
    is($@, '');
}

# [perl #8262] //g loops infinitely on tainted data

{
    my @a;
    $a[0] = $^X . '-';
    $a[0]=~ m/(.)/g;
    cmp_ok pos($a[0]), '>', 0, "infinite m//g on arrays (aelemfast)";

    my $i = 1;
    $a[$i] = $^X . '-';
    $a[$i]=~ m/(.)/g;
    cmp_ok pos($a[$i]), '>', 0, "infinite m//g on arrays (aelem)";

    my %h;
    $h{a} = $^X . '-';
    $h{a}=~ m/(.)/g;
    cmp_ok pos($h{a}), '>', 0, "infinite m//g on hashes (helem)";
}

SKIP:
{
    my $got_dualvar;
    eval 'use Scalar::Util "dualvar"; $got_dualvar++';
    skip "No Scalar::Util::dualvar" unless $got_dualvar;
    my $a = Scalar::Util::dualvar(3, $^X);
    my $b = $a + 5;
    is ($b, 8, "Arithmetic on tainted dualvars works");
}

# opening '|-' should not trigger $ENV{PATH} check

{
    SKIP: {
	skip "fork() is not available", 3 unless $Config{'d_fork'};
	skip "opening |- is not stable on threaded Open/MirBSD with taint", 3
            if $Config{useithreads} and $Is_OpenBSD || $Is_MirBSD;

	$ENV{'PATH'} = $TAINT;
	local $SIG{'PIPE'} = 'IGNORE';
	eval {
	    my $pid = open my $pipe, '|-';
	    if (!defined $pid) {
		die "open failed: $!";
	    }
	    if (!$pid) {
		kill 'KILL', $$;	# child suicide
	    }
	    close $pipe;
	};
	unlike($@, qr/Insecure \$ENV/, 'fork triggers %ENV check');
	is($@, '',               'pipe/fork/open/close failed');
	eval {
	    open my $pipe, "|$Invoke_Perl -e 1";
	    close $pipe;
	};
	like($@, qr/Insecure \$ENV/, 'popen neglects %ENV check');
    }
}

{
    package AUTOLOAD_TAINT;
    sub AUTOLOAD {
        our $AUTOLOAD;
        return if $AUTOLOAD =~ /DESTROY/;
        if ($AUTOLOAD =~ /untainted/) {
            main::isnt_tainted($AUTOLOAD, '$AUTOLOAD can be untainted');
            my $copy = $AUTOLOAD;
            main::isnt_tainted($copy, '$AUTOLOAD can be untainted');
        } else {
            main::is_tainted($AUTOLOAD, '$AUTOLOAD can be tainted');
            my $copy = $AUTOLOAD;
            main::is_tainted($copy, '$AUTOLOAD can be tainted');
        }
    }

    package main;
    my $o = bless [], 'AUTOLOAD_TAINT';
    $o->untainted;
    $o->$TAINT;
    $o->untainted;
}

{
    # tests for tainted format in s?printf
    eval { printf($TAINT . "# %s\n", "foo") };
    like($@, qr/^Insecure dependency in printf/, q/printf doesn't like tainted formats/);
    eval { printf("# %s\n", $TAINT . "foo") };
    ok(!$@, q/printf accepts other tainted args/);
    eval { sprintf($TAINT . "# %s\n", "foo") };
    like($@, qr/^Insecure dependency in sprintf/, q/sprintf doesn't like tainted formats/);
    eval { sprintf("# %s\n", $TAINT . "foo") };
    ok(!$@, q/sprintf accepts other tainted args/);
}

{
    # 40708
    my $n  = 7e9;
    8e9 - $n;

    my $val = $n;
    is ($val, '7000000000', 'Assignment to untainted variable');
    $val = $TAINT;
    $val = $n;
    is ($val, '7000000000', 'Assignment to tainted variable');
}

{
    my $val = 0;
    my $tainted = '1' . $TAINT;
    eval '$val = eval $tainted;';
    is ($val, 0, "eval doesn't like tainted strings");
    like ($@, qr/^Insecure dependency in eval/);

    # Rather nice code to get a tainted undef by from Rick Delaney
    open FH, "test.pl" or die $!;
    seek FH, 0, 2 or die $!;
    $tainted = <FH>;

    eval 'eval $tainted';
    like ($@, qr/^Insecure dependency in eval/);
}

foreach my $ord (78, 163, 256) {
    # 47195
    my $line = 'A1' . $TAINT . chr $ord;
    chop $line;
    is($line, 'A1');
    $line =~ /(A\S*)/;
    isnt_tainted($1, "\\S match with chr $ord");
}

{
    # 59998
    sub cr { my $x = crypt($_[0], $_[1]); $x }
    sub co { my $x = ~$_[0]; $x }
    my ($a, $b);
    $a = cr('hello', 'foo' . $TAINT);
    $b = cr('hello', 'foo');
    is_tainted($a,  "tainted crypt");
    isnt_tainted($b, "untainted crypt");
    $a = co('foo' . $TAINT);
    $b = co('foo');
    is_tainted($a,  "tainted complement");
    isnt_tainted($b, "untainted complement");
}

{
    my @data = qw(bonk zam zlonk qunckkk);
    # Clearly some sort of usenet bang-path
    my $string = $TAINT . join "!", @data;

    is_tainted($string, "tainted data");

    my @got = split /!|,/, $string;

    # each @got would be useful here, but I want the test for earlier perls
    for my $i (0 .. $#data) {
	is_tainted($got[$i], "tainted result $i");
	is($got[$i], $data[$i], "correct content $i");
    }

    is_tainted($string, "still tainted data");

    my @got = split /[!,]/, $string;

    # each @got would be useful here, but I want the test for earlier perls
    for my $i (0 .. $#data) {
	is_tainted($got[$i], "tainted result $i");
	is($got[$i], $data[$i], "correct content $i");
    }

    is_tainted($string, "still tainted data");

    my @got = split /!/, $string;

    # each @got would be useful here, but I want the test for earlier perls
    for my $i (0 .. $#data) {
	is_tainted($got[$i], "tainted result $i");
	is($got[$i], $data[$i], "correct content $i");
    }
}

# Bug RT #52552 - broken by change at git commit id f337b08
{
    my $x = $TAINT. q{print "Hello world\n"};
    my $y = pack "a*", $x;
    is_tainted($y, "pack a* preserves tainting");

    my $z = pack "A*", q{print "Hello world\n"}.$TAINT;
    is_tainted($z, "pack A* preserves tainting");

    my $zz = pack "a*a*", q{print "Hello world\n"}, $TAINT;
    is_tainted($zz, "pack a*a* preserves tainting");
}

# Bug RT #61976 tainted $! would show numeric rather than string value

{
    my $tainted_path = substr($^X,0,0) . "/no/such/file";
    my $err;
    # $! is used in a tainted expression, so gets tainted
    open my $fh, $tainted_path or $err= "$!";
    unlike($err, qr/^\d+$/, 'tainted $!');
}

{
    # #6758: tainted values become untainted in tied hashes
    #         (also applies to other value magic such as pos)


    package P6758;

    sub TIEHASH { bless {} }
    sub TIEARRAY { bless {} }

    my $i = 0;

    sub STORE {
	main::is_tainted($_[1], "tied arg1 tainted");
	main::is_tainted($_[2], "tied arg2 tainted");
        $i++;
    }

    package main;

    my ($k,$v) = qw(1111 val);
    taint_these($k,$v);
    tie my @array, 'P6758';
    tie my %hash , 'P6758';
    $array[$k] = $v;
    $hash{$k} = $v;
    ok $i == 2, "tied STORE called correct number of times";
}

# Bug RT #45167 the return value of sprintf sometimes wasn't tainted
# when the args were tainted. This only occured on the first use of
# sprintf; after that, its TARG has taint magic attached, so setmagic
# at the end works.  That's why there are multiple sprintf's below, rather
# than just one wrapped in an inner loop. Also, any plaintext between
# fprmat entires would correctly cause tainting to get set. so test with
# "%s%s" rather than eg "%s %s".

{
    for my $var1 ($TAINT, "123") {
	for my $var2 ($TAINT0, "456") {
	    is( tainted(sprintf '%s', $var1, $var2), tainted($var1),
		"sprintf '%s', '$var1', '$var2'" );
	    is( tainted(sprintf ' %s', $var1, $var2), tainted($var1),
		"sprintf ' %s', '$var1', '$var2'" );
	    is( tainted(sprintf '%s%s', $var1, $var2),
		tainted($var1) || tainted($var2),
		"sprintf '%s%s', '$var1', '$var2'" );
	}
    }
}


# Bug RT #67962: old tainted $1 gets treated as tainted
# in next untainted # match

{
    use re 'taint';
    "abc".$TAINT =~ /(.*)/; # make $1 tainted
    is_tainted($1, '$1 should be tainted');

    my $untainted = "abcdef";
    isnt_tainted($untainted, '$untainted should be untainted');
    $untainted =~ s/(abc)/$1/;
    isnt_tainted($untainted, '$untainted should still be untainted');
    $untainted =~ s/(abc)/x$1/;
    isnt_tainted($untainted, '$untainted should yet still be untainted');
}

{
    # On Windows we can't spawn a fresh Perl interpreter unless at
    # least the Windows system directory (usually C:\Windows\System32)
    # is still on the PATH.  There is however no way to determine the
    # actual path on the current system without loading the Win32
    # module, so we just restore the original $ENV{PATH} here.
    local $ENV{PATH} = $ENV{PATH};
    $ENV{PATH} = $old_env_path if $Is_MSWin32;

    fresh_perl_is(<<'end', "ok", { switches => [ '-T' ] },
    $TAINT = substr($^X, 0, 0);
    formline('@'.('<'x("2000".$TAINT)).' | @*', 'hallo', 'welt');
    print "ok";
end
    "formline survives a tainted dynamic picture");
}

{
    isnt_tainted($^A, "format accumulator not tainted yet");
    formline('@ | @*', 'hallo' . $TAINT, 'welt');
    is_tainted($^A, "tainted formline argument makes a tainted accumulator");
    $^A = "";
    isnt_tainted($^A, "accumulator can be explicitly untainted");
    formline('@' .('<'*5) . ' | @*', 'hallo', 'welt');
    isnt_tainted($^A, "accumulator still untainted");
    $^A = "" . $TAINT;
    is_tainted($^A, "accumulator can be explicitly tainted");
    formline('@' .('<'*5) . ' | @*', 'hallo', 'welt');
    is_tainted($^A, "accumulator still tainted");
    $^A = "";
    isnt_tainted($^A, "accumulator untainted again");
    formline('@' .('<'*5) . ' | @*', 'hallo', 'welt');
    isnt_tainted($^A, "accumulator still untainted");
    formline('@' .('<'*(5+$TAINT0)) . ' | @*', 'hallo', 'welt');
    TODO: {
        local $::TODO = "get magic handled too late?";
        is_tainted($^A, "the accumulator should be tainted already");
    }
    is_tainted($^A, "tainted formline picture makes a tainted accumulator");
}

{   # Bug #80610
    "Constant(1)" =~ / ^ ([a-z_]\w*) (?: [(] (.*) [)] )? $ /xi;
    my $a = $1;
    my $b = $2;
    isnt_tainted($a, "regex optimization of single char /[]/i doesn't taint");
    isnt_tainted($b, "regex optimization of single char /[]/i doesn't taint");
}

{
    # RT 81230: tainted value during FETCH created extra ref to tied obj

    package P81230;
    use warnings;

    my %h;

    sub TIEHASH {
	my $x = $^X; # tainted
	bless  \$x;
    }
    sub FETCH { my $x = $_[0]; $$x . "" }

    tie %h, 'P81230';

    my $w = "";
    local $SIG{__WARN__} = sub { $w .= "@_" };

    untie %h if $h{"k"};

    ::is($w, "", "RT 81230");
}

{
    # Compiling a subroutine inside a tainted expression does not make the
    # constant folded values tainted.
    my $x = sub { "x" . "y" };
    my $y = $ENV{PATH} . $x->(); # Compile $x inside a tainted expression
    my $z = $x->();
    isnt_tainted($z, "Constants folded value not tainted");
}

{
    # now that regexes are first class SVs, make sure that they themselves
    # as well as references to them are tainted

    my $rr = qr/(.)$TAINT/;
    my $r = $$rr; # bare REGEX
    my $s ="abc";
    ok($s =~ s/$r/x/, "match bare regex");
    is_tainted($s, "match bare regex taint");
    is($s, 'xbc', "match bare regex taint value");
}

{
    # [perl #82616] security Issues with user-defined \p{} properties
    # A using a tainted user-defined property should croak

    sub IsA { sprintf "%02x", ord("A") }

    my $prop = "IsA";
    ok("A" =~ /\p{$prop}/, "user-defined property: non-tainted case");
    $prop = "IsA$TAINT";
    eval { "A" =~ /\p{$prop}/};
    like($@, qr/Insecure user-defined property \\p{main::IsA}/,
	    "user-defined property: tainted case");
}

# This may bomb out with the alarm signal so keep it last
SKIP: {
    skip "No alarm()"  unless $Config{d_alarm};
    # Test from RT #41831]
    # [PATCH] Bug & fix: hang when using study + taint mode (perl 5.6.1, 5.8.x)

    my $DATA = <<'END' . $TAINT;
line1 is here
line2 is here
line3 is here
line4 is here

END

    #study $DATA;

    ## don't set $SIG{ALRM}, since we'd never get to a user-level handler as
    ## perl is stuck in a regexp infinite loop!

    alarm(10);

    if ($DATA =~ /^line2.*line4/m) {
	fail("Should not be a match")
    } else {
	pass("Match on tainted multiline data should fail promptly");
    }

    alarm(0);
}
__END__
# Keep the previous test last
