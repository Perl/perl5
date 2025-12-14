use Test2::V1 '-x', 'subtest';
use Test2::API qw/test2_stack/;
use PerlIO;

my @subs = qw{
    ok pass fail diag note todo skip
    plan skip_all done_testing bail_out

    gen_event

    intercept context

    cmp_ok

    can_ok isa_ok DOES_ok
    set_encoding
    imported_ok not_imported_ok
    ref_ok ref_is ref_is_not
    mock mocked

    dies lives try_ok

    is like isnt unlike
    match mismatch validator
    hash array object meta number string bool check_isa
    in_set not_in_set check_set
    item field call call_list call_hash prop check all_items all_keys all_vals all_values
    etc end filter_items
    T F D DF E DNE FDNE U L
    event fail_events
    exact_ref

    is_refcount is_oneref refcount

    subtest
};

T2->not_imported_ok(qw/ok like done_testing/);
T2->imported_ok('subtest');

T2->ok(!T2->can('Dumper'), "Cannot 'Dumper'");
T2->HANDLE_INCLUDE('Data::Dumper', 'Dumper');
T2->can_ok(T2, ['Dumper'], "Added Dumper to the can list");

T2->can_ok(T2(), [@subs], "Handle can do it all");
T2->isa_ok(T2(), ['Test2::Handle'], "Got a handle instance");

T2->ok(Test2::Plugin::ExitSummary->active, "Exit Summary is loaded");

T2->ok(!defined(Test2::Plugin::SRand->seed), "SRand is not loaded");

subtest srand => sub {
    Test2::V1->import('-srand', '-no-T2');
    T2->ok(defined(Test2::Plugin::SRand->seed), "SRand is loaded");
};

subtest strictures => sub {
    local $^H;
    my $hbefore = $^H;
    Test2::V1->import('-strict', '-no-T2');
    my $hafter = $^H;

    my $strict = do { local $^H; strict->import(); $^H };

    T2->ok($strict,               'sanity, got $^H value for strict');
    T2->ok(!($hbefore & $strict), "strict is not on before loading Test2::V0");
    T2->ok(($hafter & $strict),   "strict is on after loading Test2::V0");
};

subtest warnings => sub {
    local ${^WARNING_BITS};
    my $wbefore = ${^WARNING_BITS} || '';
    Test2::V1->import('-warnings', '-no-T2');
    my $wafter = ${^WARNING_BITS} || '';

    my $warnings = do { local ${^WARNING_BITS}; 'warnings'->import(); ${^WARNING_BITS} || '' };

    T2->ok($warnings, 'sanity, got ${^WARNING_BITS} value for warnings');
    T2->ok($wbefore ne $warnings, "warnings are not on before loading Test2::V0") || diag($wbefore, "\n", $warnings);
    T2->ok(($wafter & $warnings), "warnings are on after loading Test2::V0");
};

subtest utf8 => sub {
    T2->ok(!utf8::is_utf8("癸"), "utf8 pragma is off");

    eval <<'    EOT';
    package A::UTF8::Thingy;
    use Test2::V1 '-utf8';
    T2->ok(utf8::is_utf8("癸"), "utf8 pragma is on");

    # -2 cause the subtest adds to the stack
    my $format = test2_stack()->[-2]->format;
    my $handles = $format->handles or return;
    for my $hn (0 .. @$handles) {
        my $h = $handles->[$hn] || next;
        my $layers = { map {$_ => 1} PerlIO::get_layers($h) };
        T2->ok($layers->{utf8}, "utf8 is on for formatter handle $hn");
    }
    EOT
};

subtest "rename imports" => sub {
    package A::Consumer;
    use Test2::V1 '-import', '!subtest', subtest => {-as => 'a_subtest'};
    imported_ok('a_subtest');
    not_imported_ok('subtest');
};

subtest "no meta" => sub {
    package B::Consumer;
    use Test2::V1 '-import', '!meta';
    imported_ok('meta_check');
    not_imported_ok('meta');
};

subtest "-x" => sub {
    package C::Consumer;
    use Test2::V1 '-x';
    T2->imported_ok('dies');
};

subtest "unquoted -x" => sub {
    package D::Consumer;
    main::T2()->ok(!eval "use Test2::V1 -x;");
    main::T2()->like(
        $@,
        qr/Got One or more undefined arguments, this usually means you passed in a single-character flag like '-p' without quoting it, which conflicts with the -p builtin/,
        "Caught easy mistake"
    );
};

subtest target => sub {
    package E::Consumer;
    use Test2::V1 '-i', -target => 'Data::Dumper';
    is($CLASS, 'Data::Dumper', "Added \$CLASS symbol");
    is(CLASS(), 'Data::Dumper', "Added \&CLASS symbol");
};


T2->done_testing;

1;
