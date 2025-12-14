use Test2::V1 -Ppi, -target => 'Test2::V1::Base';

can_ok(
    $CLASS,
    [
        qw{
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
    "Imported all symbols"
);

done_testing;
