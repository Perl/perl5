#!/usr/bin/perl -w

BEGIN {
    if ($ENV{PERL_CORE}) {
	# FIXME
	print "1..0 # Skip until we figure out why it exists with no output just after the plan\n";
	exit 0;
    }
}

use strict;
use lib 't/lib';

use Test::More;

use File::Spec;

use Test::Harness qw(execute_tests);

# unset this global when self-testing ('testcover' and etc issue)
local $ENV{HARNESS_PERL_SWITCHES};

{

    # if the harness wants to save the resulting TAP we shouldn't
    # do it for our internal calls
    local $ENV{PERL_TEST_HARNESS_DUMP_TAP} = 0;

    my $TEST_DIR = 't/sample-tests';
    my $PER_LOOP = 4;

    my $results = {
        'descriptive' => {
            'failed' => {},
            'todo'   => {},
            'totals' => {
                'bad'         => 0,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 1,
                'max'         => 5,
                'ok'          => 5,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        join(
            ',', qw(
              descriptive die die_head_end die_last_minute duplicates
              head_end head_fail inc_taint junk_before_plan lone_not_bug
              no_nums no_output schwern sequence_misparse shbang_misparse
              simple simple_fail skip skip_nomsg skipall skipall_nomsg
              stdout_stderr switches taint todo_inline
              todo_misparse too_many vms_nit
              )
          ) => {
            'failed' => {
                't/sample-tests/die' => {
                    'canon'  => '??',
                    'estat'  => 1,
                    'failed' => '??',
                    'max'    => '??',
                    'name'   => 't/sample-tests/die',
                    'wstat'  => '256'
                },
                't/sample-tests/die_head_end' => {
                    'canon'  => '??',
                    'estat'  => 1,
                    'failed' => '??',
                    'max'    => '??',
                    'name'   => 't/sample-tests/die_head_end',
                    'wstat'  => '256'
                },
                't/sample-tests/die_last_minute' => {
                    'canon'  => '??',
                    'estat'  => 1,
                    'failed' => 0,
                    'max'    => 4,
                    'name'   => 't/sample-tests/die_last_minute',
                    'wstat'  => '256'
                },
                't/sample-tests/duplicates' => {
                    'canon'  => '??',
                    'estat'  => '',
                    'failed' => '??',
                    'max'    => 10,
                    'name'   => 't/sample-tests/duplicates',
                    'wstat'  => ''
                },
                't/sample-tests/head_fail' => {
                    'canon'  => 2,
                    'estat'  => '',
                    'failed' => 1,
                    'max'    => 4,
                    'name'   => 't/sample-tests/head_fail',
                    'wstat'  => ''
                },
                't/sample-tests/inc_taint' => {
                    'canon'  => 1,
                    'estat'  => 1,
                    'failed' => 1,
                    'max'    => 1,
                    'name'   => 't/sample-tests/inc_taint',
                    'wstat'  => '256'
                },
                't/sample-tests/no_nums' => {
                    'canon'  => 3,
                    'estat'  => '',
                    'failed' => 1,
                    'max'    => 5,
                    'name'   => 't/sample-tests/no_nums',
                    'wstat'  => ''
                },
                't/sample-tests/no_output' => {
                    'canon'  => '??',
                    'estat'  => '',
                    'failed' => '??',
                    'max'    => '??',
                    'name'   => 't/sample-tests/no_output',
                    'wstat'  => ''
                },
                't/sample-tests/simple_fail' => {
                    'canon'  => '2 5',
                    'estat'  => '',
                    'failed' => 2,
                    'max'    => 5,
                    'name'   => 't/sample-tests/simple_fail',
                    'wstat'  => ''
                },
                't/sample-tests/switches' => {
                    'canon'  => 1,
                    'estat'  => '',
                    'failed' => 1,
                    'max'    => 1,
                    'name'   => 't/sample-tests/switches',
                    'wstat'  => ''
                },
                't/sample-tests/todo_misparse' => {
                    'canon'  => 1,
                    'estat'  => '',
                    'failed' => 1,
                    'max'    => 1,
                    'name'   => 't/sample-tests/todo_misparse',
                    'wstat'  => ''
                },
                't/sample-tests/too_many' => {
                    'canon'  => '4-7',
                    'estat'  => 4,
                    'failed' => 4,
                    'max'    => 3,
                    'name'   => 't/sample-tests/too_many',
                    'wstat'  => '1024'
                },
                't/sample-tests/vms_nit' => {
                    'canon'  => 1,
                    'estat'  => '',
                    'failed' => 1,
                    'max'    => 2,
                    'name'   => 't/sample-tests/vms_nit',
                    'wstat'  => ''
                }
            },
            'todo' => {
                't/sample-tests/todo_inline' => {
                    'canon'  => 2,
                    'estat'  => '',
                    'failed' => 1,
                    'max'    => 2,
                    'name'   => 't/sample-tests/todo_inline',
                    'wstat'  => ''
                }
            },
            'totals' => {
                'bad'         => 13,
                'bonus'       => 1,
                'files'       => 28,
                'good'        => 15,
                'max'         => 77,
                'ok'          => 78,
                'skipped'     => 2,
                'sub_skipped' => 2,
                'tests'       => 28,
                'todo'        => 2
            }
          },
        'die' => {
            'failed' => {
                't/sample-tests/die' => {
                    'canon'  => '??',
                    'estat'  => 1,
                    'failed' => '??',
                    'max'    => '??',
                    'name'   => 't/sample-tests/die',
                    'wstat'  => '256'
                }
            },
            'todo'   => {},
            'totals' => {
                'bad'         => 1,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 0,
                'max'         => 0,
                'ok'          => 0,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'die_head_end' => {
            'failed' => {
                't/sample-tests/die_head_end' => {
                    'canon'  => '??',
                    'estat'  => 1,
                    'failed' => '??',
                    'max'    => '??',
                    'name'   => 't/sample-tests/die_head_end',
                    'wstat'  => '256'
                }
            },
            'todo'   => {},
            'totals' => {
                'bad'         => 1,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 0,
                'max'         => 0,
                'ok'          => 4,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'die_last_minute' => {
            'failed' => {
                't/sample-tests/die_last_minute' => {
                    'canon'  => '??',
                    'estat'  => 1,
                    'failed' => 0,
                    'max'    => 4,
                    'name'   => 't/sample-tests/die_last_minute',
                    'wstat'  => '256'
                }
            },
            'todo'   => {},
            'totals' => {
                'bad'         => 1,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 0,
                'max'         => 4,
                'ok'          => 4,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'duplicates' => {
            'failed' => {
                't/sample-tests/duplicates' => {
                    'canon'  => '??',
                    'estat'  => '',
                    'failed' => '??',
                    'max'    => 10,
                    'name'   => 't/sample-tests/duplicates',
                    'wstat'  => ''
                }
            },
            'todo'   => {},
            'totals' => {
                'bad'         => 1,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 0,
                'max'         => 10,
                'ok'          => 11,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'head_end' => {
            'failed' => {},
            'todo'   => {},
            'totals' => {
                'bad'         => 0,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 1,
                'max'         => 4,
                'ok'          => 4,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'head_fail' => {
            'failed' => {
                't/sample-tests/head_fail' => {
                    'canon'  => 2,
                    'estat'  => '',
                    'failed' => 1,
                    'max'    => 4,
                    'name'   => 't/sample-tests/head_fail',
                    'wstat'  => ''
                }
            },
            'todo'   => {},
            'totals' => {
                'bad'         => 1,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 0,
                'max'         => 4,
                'ok'          => 3,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'inc_taint' => {
            'failed' => {
                't/sample-tests/inc_taint' => {
                    'canon'  => 1,
                    'estat'  => 1,
                    'failed' => 1,
                    'max'    => 1,
                    'name'   => 't/sample-tests/inc_taint',
                    'wstat'  => '256'
                }
            },
            'todo'   => {},
            'totals' => {
                'bad'         => 1,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 0,
                'max'         => 1,
                'ok'          => 0,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'junk_before_plan' => {
            'failed' => {},
            'todo'   => {},
            'totals' => {
                'bad'         => 0,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 1,
                'max'         => 1,
                'ok'          => 1,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'lone_not_bug' => {
            'failed' => {},
            'todo'   => {},
            'totals' => {
                'bad'         => 0,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 1,
                'max'         => 4,
                'ok'          => 4,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'no_nums' => {
            'failed' => {
                't/sample-tests/no_nums' => {
                    'canon'  => 3,
                    'estat'  => '',
                    'failed' => 1,
                    'max'    => 5,
                    'name'   => 't/sample-tests/no_nums',
                    'wstat'  => ''
                }
            },
            'todo'   => {},
            'totals' => {
                'bad'         => 1,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 0,
                'max'         => 5,
                'ok'          => 4,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'no_output' => {
            'failed' => {
                't/sample-tests/no_output' => {
                    'canon'  => '??',
                    'estat'  => '',
                    'failed' => '??',
                    'max'    => '??',
                    'name'   => 't/sample-tests/no_output',
                    'wstat'  => ''
                }
            },
            'todo'   => {},
            'totals' => {
                'bad'         => 1,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 0,
                'max'         => 0,
                'ok'          => 0,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'schwern' => {
            'failed' => {},
            'todo'   => {},
            'totals' => {
                'bad'         => 0,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 1,
                'max'         => 1,
                'ok'          => 1,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'sequence_misparse' => {
            'failed' => {},
            'todo'   => {},
            'totals' => {
                'bad'         => 0,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 1,
                'max'         => 5,
                'ok'          => 5,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'shbang_misparse' => {
            'failed' => {},
            'todo'   => {},
            'totals' => {
                'bad'         => 0,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 1,
                'max'         => 2,
                'ok'          => 2,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'simple' => {
            'failed' => {},
            'todo'   => {},
            'totals' => {
                'bad'         => 0,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 1,
                'max'         => 5,
                'ok'          => 5,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'simple_fail' => {
            'failed' => {
                't/sample-tests/simple_fail' => {
                    'canon'  => '2 5',
                    'estat'  => '',
                    'failed' => 2,
                    'max'    => 5,
                    'name'   => 't/sample-tests/simple_fail',
                    'wstat'  => ''
                }
            },
            'todo'   => {},
            'totals' => {
                'bad'         => 1,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 0,
                'max'         => 5,
                'ok'          => 3,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'skip' => {
            'failed' => {},
            'todo'   => {},
            'totals' => {
                'bad'         => 0,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 1,
                'max'         => 5,
                'ok'          => 5,
                'skipped'     => 0,
                'sub_skipped' => 1,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'skip_nomsg' => {
            'failed' => {},
            'todo'   => {},
            'totals' => {
                'bad'         => 0,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 1,
                'max'         => 1,
                'ok'          => 1,
                'skipped'     => 0,
                'sub_skipped' => 1,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'skipall' => {
            'failed' => {},
            'todo'   => {},
            'totals' => {
                'bad'         => 0,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 1,
                'max'         => 0,
                'ok'          => 0,
                'skipped'     => 1,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'skipall_nomsg' => {
            'failed' => {},
            'todo'   => {},
            'totals' => {
                'bad'         => 0,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 1,
                'max'         => 0,
                'ok'          => 0,
                'skipped'     => 1,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'stdout_stderr' => {
            'failed' => {},
            'todo'   => {},
            'totals' => {
                'bad'         => 0,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 1,
                'max'         => 4,
                'ok'          => 4,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'switches' => {
            'failed' => {
                't/sample-tests/switches' => {
                    'canon'  => 1,
                    'estat'  => '',
                    'failed' => 1,
                    'max'    => 1,
                    'name'   => 't/sample-tests/switches',
                    'wstat'  => ''
                }
            },
            'todo'   => {},
            'totals' => {
                'bad'         => 1,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 0,
                'max'         => 1,
                'ok'          => 0,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'taint' => {
            'failed' => {},
            'todo'   => {},
            'totals' => {
                'bad'         => 0,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 1,
                'max'         => 1,
                'ok'          => 1,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'taint_warn' => {
            'failed' => {},
            'todo'   => {},
            'totals' => {
                'bad'         => 0,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 1,
                'max'         => 1,
                'ok'          => 1,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            },
            'require' => 5.008001,
        },
        'todo_inline' => {
            'failed' => {},
            'todo'   => {
                't/sample-tests/todo_inline' => {
                    'canon'  => 2,
                    'estat'  => '',
                    'failed' => 1,
                    'max'    => 2,
                    'name'   => 't/sample-tests/todo_inline',
                    'wstat'  => ''
                }
            },
            'totals' => {
                'bad'         => 0,
                'bonus'       => 1,
                'files'       => 1,
                'good'        => 1,
                'max'         => 3,
                'ok'          => 3,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 2
            }
        },
        'todo_misparse' => {
            'failed' => {
                't/sample-tests/todo_misparse' => {
                    'canon'  => 1,
                    'estat'  => '',
                    'failed' => 1,
                    'max'    => 1,
                    'name'   => 't/sample-tests/todo_misparse',
                    'wstat'  => ''
                }
            },
            'todo'   => {},
            'totals' => {
                'bad'         => 1,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 0,
                'max'         => 1,
                'ok'          => 0,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'too_many' => {
            'failed' => {
                't/sample-tests/too_many' => {
                    'canon'  => '4-7',
                    'estat'  => 4,
                    'failed' => 4,
                    'max'    => 3,
                    'name'   => 't/sample-tests/too_many',
                    'wstat'  => '1024'
                }
            },
            'todo'   => {},
            'totals' => {
                'bad'         => 1,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 0,
                'max'         => 3,
                'ok'          => 7,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        },
        'vms_nit' => {
            'failed' => {
                't/sample-tests/vms_nit' => {
                    'canon'  => 1,
                    'estat'  => '',
                    'failed' => 1,
                    'max'    => 2,
                    'name'   => 't/sample-tests/vms_nit',
                    'wstat'  => ''
                }
            },
            'todo'   => {},
            'totals' => {
                'bad'         => 1,
                'bonus'       => 0,
                'files'       => 1,
                'good'        => 0,
                'max'         => 2,
                'ok'          => 1,
                'skipped'     => 0,
                'sub_skipped' => 0,
                'tests'       => 1,
                'todo'        => 0
            }
        }
    };

    my $num_tests = ( keys %$results ) * $PER_LOOP;

    plan tests => $num_tests;

    sub local_name {
        my $name = shift;
        return File::Spec->catfile( split /\//, $name );
    }

    sub local_result {
        my $hash = shift;
        my $new  = {};

        while ( my ( $file, $want ) = each %$hash ) {
            if ( exists $want->{name} ) {
                $want->{name} = local_name( $want->{name} );
            }
            $new->{ local_name($file) } = $want;
        }
        return $new;
    }

    sub vague_status {
        my $hash = shift;
        return $hash unless $^O eq 'VMS';

        while ( my ( $file, $want ) = each %$hash ) {
            for ( qw( estat wstat ) ) {
                if ( exists $want->{$_} ) {
                    $want->{$_} = $want->{$_} ? 1 : 0;
                }
            }
        }
        return $hash
    }

    {
        local $^W = 0;

        # Silence harness output
        *TAP::Formatter::Console::_output = sub {

            # do nothing
        };
    }

    for my $test_key ( sort keys %$results ) {
        my $result = $results->{$test_key};
        SKIP: {
            if ( $result->{require} && $] < $result->{require} ) {
                skip "Test requires Perl $result->{require}, we have $]", 4;
            }
            my @test_names = split( /,/, $test_key );
            my @test_files
              = map { File::Spec->catfile( $TEST_DIR, $_ ) } @test_names;

            # For now we supress STDERR because it crufts up /our/ test
            # results. Should probably capture and analyse it.
            local ( *OLDERR, *OLDOUT );
            open OLDERR, '>&STDERR' or die $!;
            open OLDOUT, '>&STDOUT' or die $!;
            my $devnull = File::Spec->devnull;
            open STDERR, ">$devnull" or die $!;
            open STDOUT, ">$devnull" or die $!;

            my ( $tot, $fail, $todo, $harness, $aggregate )
              = execute_tests( tests => \@test_files );

            open STDERR, '>&OLDERR' or die $!;
            open STDOUT, '>&OLDOUT' or die $!;

            my $bench = delete $tot->{bench};
            isa_ok $bench, 'Benchmark';

            # Localise filenames in failed, todo
            my $lfailed = vague_status( local_result( $result->{failed} ) );
            my $ltodo   = vague_status( local_result( $result->{todo} ) );

            # use Data::Dumper;
            # diag Dumper( [ $lfailed, $ltodo ] );

            is_deeply $tot, $result->{totals}, "totals match for $test_key";
            is_deeply vague_status($fail), $lfailed,
              "failure summary matches for $test_key";
            is_deeply vague_status($todo), $ltodo,
              "todo summary matches for $test_key";
        }
    }
}
