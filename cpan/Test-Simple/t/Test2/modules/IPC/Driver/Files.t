BEGIN { require "t/tools.pl" };
use Test2::Util qw/get_tid USE_THREADS try/;
use File::Temp qw/tempfile/;
use File::Spec qw/catfile/;
use strict;
use warnings;

sub capture(&) {
    my $code = shift;

    my ($err, $out) = ("", "");

    my ($ok, $e);
    {
        local *STDOUT;
        local *STDERR;

        ($ok, $e) = try {
            open(STDOUT, '>', \$out) or die "Failed to open a temporary STDOUT: $!";
            open(STDERR, '>', \$err) or die "Failed to open a temporary STDERR: $!";

            $code->();
        };
    }

    die $e unless $ok;

    return {
        STDOUT => $out,
        STDERR => $err,
    };
}

require Test2::IPC::Driver::Files;
ok(my $ipc = Test2::IPC::Driver::Files->new, "Created an IPC instance");
ok($ipc->isa('Test2::IPC::Driver::Files'), "Correct type");
ok($ipc->isa('Test2::IPC::Driver'), "inheritence");

ok(-d $ipc->tempdir, "created temp dir");
is($ipc->pid, $$, "stored pid");
is($ipc->tid, get_tid(), "stored the tid");

my $hid = '12345';

$ipc->add_hub($hid);
my $hubfile = File::Spec->catfile($ipc->tempdir, "HUB-$hid");
ok(-f $hubfile, "wrote hub file");
if(ok(open(my $fh, '<', $hubfile), "opened hub file")) {
    my @lines = <$fh>;
    close($fh);
    is_deeply(
        \@lines,
        [ "$$\n", get_tid() . "\n" ],
        "Wrote pid and tid to hub file"
    );
}

{
    package Foo;
    use base 'Test2::Event';
}

$ipc->send($hid, bless({ foo => 1 }, 'Foo'));
$ipc->send($hid, bless({ bar => 1 }, 'Foo'));

opendir(my $dh, $ipc->tempdir) || die "Could not open tempdir: !?";
my @files = grep { $_ !~ m/^\.+$/ && $_ !~ m/^HUB-$hid/ } readdir($dh);
closedir($dh);
is(@files, 2, "2 files added to the IPC directory");

my @events = $ipc->cull($hid);
is_deeply(
    \@events,
    [{ foo => 1 }, { bar => 1 }],
    "Culled both events"
);

opendir($dh, $ipc->tempdir) || die "Could not open tempdir: !?";
@files = grep { $_ !~ m/^\.+$/ && $_ !~ m/^HUB-$hid/ } readdir($dh);
closedir($dh);
is(@files, 0, "All files collected");

$ipc->drop_hub($hid);
ok(!-f $ipc->tempdir . '/' . $hid, "removed hub file");

$ipc->send($hid, bless({global => 1}, 'Foo'), 'GLOBAL');
my @got = $ipc->cull($hid);
ok(@got == 0, "did not get our own global event");

my $tmpdir = $ipc->tempdir;
ok(-d $tmpdir, "still have temp dir");
$ipc = undef;
ok(!-d $tmpdir, "cleaned up temp dir");

{
    my $ipc = Test2::IPC::Driver::Files->new();

    my $tmpdir = $ipc->tempdir;

    my $ipc_thread_clone = bless {%$ipc}, 'Test2::IPC::Driver::Files';
    $ipc_thread_clone->set_tid(100);
    $ipc_thread_clone = undef;
    ok(-d $tmpdir, "Directory not removed (different thread)");

    my $ipc_fork_clone = bless {%$ipc}, 'Test2::IPC::Driver::Files';
    $ipc_fork_clone->set_pid($$ + 10);
    $ipc_fork_clone = undef;
    ok(-d $tmpdir, "Directory not removed (different proc)");


    $ipc_thread_clone = bless {%$ipc}, 'Test2::IPC::Driver::Files';
    $ipc_thread_clone->set_tid(undef);
    $ipc_thread_clone = undef;
    ok(-d $tmpdir, "Directory not removed (no thread)");

    $ipc_fork_clone = bless {%$ipc}, 'Test2::IPC::Driver::Files';
    $ipc_fork_clone->set_pid(undef);
    $ipc_fork_clone = undef;
    ok(-d $tmpdir, "Directory not removed (no proc)");

    $ipc = undef;
    ok(!-d $tmpdir, "Directory removed");
}

{
    no warnings 'once';
    local *Test2::IPC::Driver::Files::abort = sub {
        my $self = shift;
        local $self->{no_fatal} = 1;
        $self->Test2::IPC::Driver::abort(@_);
        die 255;
    };

    my $tmpdir;
    my @lines;
    my $file = __FILE__;

    my $out = capture {
        local $ENV{T2_KEEP_TEMPDIR} = 1;

        my $ipc = Test2::IPC::Driver::Files->new();
        $tmpdir = $ipc->tempdir;
        $ipc->add_hub($hid);
        eval { $ipc->add_hub($hid) }; push @lines => __LINE__;
        $ipc->send($hid, bless({ foo => 1 }, 'Foo'));
        $ipc->cull($hid);
        $ipc->drop_hub($hid);
        eval { $ipc->drop_hub($hid) }; push @lines => __LINE__;

        # Make sure having a hub file sitting around does not throw things off
        # in T2_KEEP_TEMPDIR
        $ipc->add_hub($hid);
        $ipc = undef;
        1;
    };

    my $cleanup = sub {
        if (opendir(my $d, $tmpdir)) {
            for my $f (readdir($d)) {
                next if $f =~ m/^\.+$/;
                next unless -f "$tmpdir/$f";
                unlink("$tmpdir/$f");
            }
        }
        rmdir($tmpdir) or warn "Could not remove temp dir '$tmpdir': $!";
    };
    $cleanup->();

    is($out->{STDOUT}, "not ok - IPC Fatal Error\nnot ok - IPC Fatal Error\n", "printed ");

    like($out->{STDERR}, qr/IPC Temp Dir: \Q$tmpdir\E/m, "Got temp dir path");
    like($out->{STDERR}, qr/^# Not removing temp dir: \Q$tmpdir\E$/m, "Notice about not closing tempdir");

    like($out->{STDERR}, qr/^IPC Fatal Error: File for hub '12345' already exists/m, "Got message for duplicate hub");
    like($out->{STDERR}, qr/^IPC Fatal Error: File for hub '12345' does not exist/m, "Cannot remove hub twice");

    $out = capture {
        my $ipc = Test2::IPC::Driver::Files->new();
        $ipc->add_hub($hid);
        my $trace = Test2::Util::Trace->new(frame => [__PACKAGE__, __FILE__, __LINE__, 'foo']);
        my $e = eval { $ipc->send($hid, bless({glob => \*ok, trace => $trace}, 'Foo')); 1 };
        print STDERR $@ unless $e || $@ =~ m/^255/;
        $ipc->drop_hub($hid);
    };

    like($out->{STDERR}, qr/IPC Fatal Error:/, "Got fatal error");
    like($out->{STDERR}, qr/There was an error writing an event/, "Explanation");
    like($out->{STDERR}, qr/Destination: 12345/, "Got dest");
    like($out->{STDERR}, qr/Origin PID:\s+$$/, "Got pid");
    like($out->{STDERR}, qr/Error: Can't store GLOB items/, "Got cause");

    $out = capture {
        my $ipc = Test2::IPC::Driver::Files->new();
        local $@;
        eval { $ipc->send($hid, bless({ foo => 1 }, 'Foo')) };
        print STDERR $@ unless $@ =~ m/^255/;
        $ipc = undef;
    };
    like($out->{STDERR}, qr/IPC Fatal Error: hub '12345' is not available, failed to send event!/, "Cannot send to missing hub");

    $out = capture {
        my $ipc = Test2::IPC::Driver::Files->new();
        $tmpdir = $ipc->tempdir;
        $ipc->add_hub($hid);
        $ipc->send($hid, bless({ foo => 1 }, 'Foo'));
        local $@;
        eval { $ipc->drop_hub($hid) };
        print STDERR $@ unless $@ =~ m/^255/;
    };
    $cleanup->();
    like($out->{STDERR}, qr/IPC Fatal Error: Not all files from hub '12345' have been collected/, "Leftover files");
    like($out->{STDERR}, qr/IPC Fatal Error: Leftover files in the directory \(.*\.ready\)/, "What file");

    $out = capture {
        my $ipc = Test2::IPC::Driver::Files->new();
        $ipc->add_hub($hid);

        eval { $ipc->send($hid, { foo => 1 }) };
        print STDERR $@ unless $@ =~ m/^255/;

        eval { $ipc->send($hid, bless({ foo => 1 }, 'xxx')) };
        print STDERR $@ unless $@ =~ m/^255/;
    };
    like($out->{STDERR}, qr/IPC Fatal Error: 'HASH\(.*\)' is not a blessed object/, "Cannot send unblessed objects");
    like($out->{STDERR}, qr/IPC Fatal Error: 'xxx=HASH\(.*\)' is not an event object!/, "Cannot send non-event objects");


    $ipc = Test2::IPC::Driver::Files->new();

    my ($fh, $fn) = tempfile();
    print $fh "\n";
    close($fh);

    Storable::store({}, $fn);
    $out = capture { eval { $ipc->read_event_file($fn) } };
    like(
        $out->{STDERR},
        qr/IPC Fatal Error: Got an unblessed object: 'HASH\(.*\)'/,
        "Events must actually be events (must be blessed)"
    );

    Storable::store(bless({}, 'Test2::Event::FakeEvent'), $fn);
    $out = capture { eval { $ipc->read_event_file($fn) } };
    like(
        $out->{STDERR},
        qr{IPC Fatal Error: Event has unknown type \(Test2::Event::FakeEvent\), tried to load 'Test2/Event/FakeEvent\.pm' but failed: Can't locate Test2/Event/FakeEvent\.pm},
        "Events must actually be events (not a real module)"
    );

    Storable::store(bless({}, 'Test2::API'), $fn);
    $out = capture { eval { $ipc->read_event_file($fn) } };
    like(
        $out->{STDERR},
        qr{'Test2::API=HASH\(.*\)' is not a 'Test2::Event' object},
        "Events must actually be events (not an event type)"
    );

    Storable::store(bless({}, 'Foo'), $fn);
    $out = capture {
        local @INC;
        push @INC => ('t/lib', 'lib');
        eval { $ipc->read_event_file($fn) };
    };
    ok(!$out->{STDERR}, "no problem", $out->{STDERR});
    ok(!$out->{STDOUT}, "no problem", $out->{STDOUT});

    unlink($fn);
}

{
    my $ipc = Test2::IPC::Driver::Files->new();
    $ipc->add_hub($hid);
    $ipc->send($hid, bless({global => 1}, 'Foo'), 'GLOBAL');
    $ipc->set_globals({});
    my @events = $ipc->cull($hid);
    is_deeply(
        \@events,
        [ {global => 1} ],
        "Got global event"
    );

    @events = $ipc->cull($hid);
    ok(!@events, "Did not grab it again");

    $ipc->set_globals({});
    @events = $ipc->cull($hid);
    is_deeply(
        \@events,
        [ {global => 1} ],
        "Still there"
    );

    $ipc->drop_hub($hid);
    $ipc = undef;
}

done_testing;

