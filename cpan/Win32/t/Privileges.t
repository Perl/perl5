use strict;
use warnings;

use Test::More tests => 7;
use Win32;
use Config;
use File::Temp;

is(ref(Win32::GetProcessPrivileges()), 'HASH');
is(ref(Win32::GetProcessPrivileges(Win32::GetCurrentProcessId())), 'HASH');

# All Windows PIDs are divisible by 4. It's an undocumented implementation
# detail, but it means it's extremely unlikely that the PID below is valid.
ok(!Win32::GetProcessPrivileges(3423237));

SKIP: {
    my $whoami = `whoami /priv 2>&1`;
    skip '"whoami" command is missing', 1
        if $? == -1 || $? >> 8;

    my $privs = Win32::GetProcessPrivileges();

    my $ok = 1;
    while ($whoami =~ /^(Se\w+)/mg) {
        if (!exists $privs->{$1}) {
            $ok = 0;
            last;
        }
    }

    ok $ok;
}

# there isn't really anything to test, we just want to make sure that the
# function doesn't segfault
Win32::IsDeveloperModeEnabled();
ok(1);

Win32::IsSymlinkCreationAllowed();
ok(1);

SKIP: {
    skip 'MSWin32-only test', 1
        if $^O ne 'MSWin32';
    skip "this perl doesn't have symlink()", 1
        if !$Config{d_symlink};

    my $tmpdir = File::Temp->newdir;
    my $dirname = $tmpdir->dirname;

    if (Win32::IsSymlinkCreationAllowed()) {
        # we expect success
        is symlink("foo", $tmpdir->dirname . "/new_symlink"), 1;
    }
    else {
        # we expect failure
        is symlink("foo", $tmpdir->dirname . "/new_symlink"), 0;
    }
}

