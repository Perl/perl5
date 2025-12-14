use Test2::V1 -Ppi, -target => 'Test2::Handle';

isa_ok(T2, [$CLASS], "The T2 function returns a handle");

like(dies { $CLASS->new }, qr/Not Implemented/, "Handle base class does not have a handle base");
like(dies { $CLASS->DEFAULT_HANDLE_BASE }, qr/Not Implemented/, "Handle base class does not have a handle base");

my $h = $CLASS->new(base => 'Test2::V1::Base');
is($h->HANDLE_BASE, "Test2::V1::Base", "Can get base that was used to build object");

is(
    [sort $h->HANDLE_SUBS],
    [
        sort qw{
            intercept context
            gen_event

            def do_def

            ok pass fail diag note todo skip
            plan skip_all done_testing bail_out

            is like isnt unlike
            match mismatch validator
            hash array bag object meta meta_check number float rounded within string subset bool check_isa
            number_lt number_le number_ge number_gt
            in_set not_in_set check_set
            item field call call_list call_hash prop check all_items all_keys all_vals all_values
            etc end filter_items
            T F D DF E DNE FDNE U L
            event fail_events
            exact_ref

            warns warning warnings no_warnings

            cmp_ok

            subtest
            can_ok isa_ok DOES_ok
            set_encoding
            imported_ok not_imported_ok
            ref_ok ref_is ref_is_not
            mock mocked
            try_ok dies lives
            is_refcount is_oneref refcount
        },
    ],
    "Can find all the subs, excluded things like BEGIN, isa, can, etc.."
);

$CLASS->import('my_t2', base => 'Test2::V1::Base');
imported_ok('my_t2');

like($h->HANDLE_NAMESPACE, qr/^$CLASS\::GEN_\d+$/, "Got a generated namespace");
isa_ok($h->HANDLE_NAMESPACE, ['Test2::V1::Base'], "Namespace uses the correct base class");

like(
    dies { $CLASS->new(base => 'Test2::V1::BaseXX') },
    qr{Can't locate Test2/V1/BaseXX\.pm},
    "Need a valid base"
);

like(
    dies { $CLASS->new(namespace => $h->HANDLE_NAMESPACE, base => 'Test2::V1::Base') },
    qr/Namespace '$CLASS\::GEN_\d+' already appears to be populated/,
    "Cannot override a defined namespace"
);

ok(!$h->can('Dumper'), "handle 1 does not have Dumper");
$h->HANDLE_INCLUDE('Data::Dumper', 'Dumper');
can_ok($h, ['Dumper'], "handle 1 has Data::Dumper::Dumper");
like($h->Dumper('xxx'), qr/\$VAR\d\s*=\s*'xxx';/, "Can use h->Dumper");

my $h2 = $CLASS->new(namespace => $h->HANDLE_NAMESPACE, base => 'Data::Dumper', stomp => 1);
isa_ok($h->HANDLE_NAMESPACE, ['Test2::V1::Base', 'Data::Dumper'], "Added Data::Dumper as a base");
ok((grep { $_ eq 'Dumper' } $h->HANDLE_SUBS), "Got 'Dumper' in the subs");

my $line = __LINE__ + 1;
my $err = dies { $h->HANDLE_INCLUDE('FASDFASasfdfasfagasAFDSS', 'fasd') };

like(
    $err,
    qr|Test2/Handle\.pm line 52 \(called from ${ \__FILE__ } line $line\)\.|,
    "Error reported to the ideal place"
);

like(
    dies { $line = __LINE__; $h->do_nothing },
    qr/"do_nothing" is not provided by this T2 handle at ${ \__FILE__ } line $line/,
    "Useful error when we do not have method",
);

my $h3 = $CLASS->new(base => 'Test2::V1::Base', include => ['Data::Dumper']);
can_ok($h3, ['Dumper'], "handle 1 has Data::Dumper::Dumper");
like($h3->Dumper('xxx'), qr/\$VAR\d\s*=\s*'xxx';/, "Can use h3->Dumper");

my $h4 = $CLASS->new(base => 'Test2::V1::Base', include => {'Data::Dumper' => 'Dumper'});
can_ok($h4, ['Dumper'], "handle 1 has Data::Dumper::Dumper");
like($h4->Dumper('xxx'), qr/\$VAR\d\s*=\s*'xxx';/, "Can use h4->Dumper");

my $h5 = $CLASS->new(base => 'Test2::V1::Base', include => {'Data::Dumper' => ['Dumper']});
can_ok($h5, ['Dumper'], "handle 1 has Data::Dumper::Dumper");
like($h5->Dumper('xxx'), qr/\$VAR\d\s*=\s*'xxx';/, "Can use h5->Dumper");

like(
    dies { $CLASS->new(base => 'Test2::V1::Base', include => \"hi") },
    qr/Not sure what to do with '/,
    "Invalid include"
);

my $ns = $h->HANDLE_NAMESPACE;
{
    no strict 'refs';
    *{"$ns\::FOO"} = sub { 'foo' };
}
is($h->FOO, 'foo', "AUTOLOAD works");

done_testing;
