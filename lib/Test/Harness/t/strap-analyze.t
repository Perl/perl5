#!/usr/bin/perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}

my $SAMPLE_TESTS = $ENV{PERL_CORE} ? 'lib/sample-tests' : 't/sample-tests';

use strict;

use Test::More tests => 27;

use_ok('Test::Harness::Straps');

my $IsVMS = $^O eq 'VMS';

my %samples = (
   combined   => {
                  passing     => 0,

                  max         => 10,
                  seen        => 10,

                  'ok'        => 8,
                  'todo'      => 2,
                  'skip'      => 1,
                  bonus       => 1,

                  details     => [ { 'ok' => 1, actual_ok => 1 },
                                   { 'ok' => 1, actual_ok => 1,
                                     name => 'basset hounds got long ears',
                                   },
                                   { 'ok' => 0, actual_ok => 0,
                                     name => 'all hell broke lose',
                                   },
                                   { 'ok' => 1, actual_ok => 1,
                                     type => 'todo'
                                   },
                                   { 'ok' => 1, actual_ok => 1 },
                                   { 'ok' => 1, actual_ok => 1 },
                                   { 'ok' => 1, actual_ok => 1,
                                     type   => 'skip',
                                     reason => 'contract negociations'
                                   },
                                   { 'ok' => 1, actual_ok => 1 },
                                   { 'ok' => 0, actual_ok => 0 },
                                   { 'ok' => 1, actual_ok => 0,
                                     type   => 'todo' 
                                   },
                                 ]
                       },

   descriptive      => {
                        passing     => 1,

                        max         => 5,
                        seen        => 5,

                        'ok'          => 5,
                        'todo'        => 0,
                        'skip'        => 0,
                        bonus       => 0,

                        details     => [ { 'ok' => 1, actual_ok => 1,
                                           name => 'Interlock activated'
                                         },
                                         { 'ok' => 1, actual_ok => 1,
                                           name => 'Megathrusters are go',
                                         },
                                         { 'ok' => 1, actual_ok => 1,
                                           name => 'Head formed',
                                         },
                                         { 'ok' => 1, actual_ok => 1,
                                           name => 'Blazing sword formed'
                                         },
                                         { 'ok' => 1, actual_ok => 1,
                                           name => 'Robeast destroyed'
                                         },
                                       ],
                       },

   duplicates       => {
                        passing     => 0,

                        max         => 10,
                        seen        => 11,

                        'ok'          => 11,
                        'todo'        => 0,
                        'skip'        => 0,
                        bonus       => 0,

                        details     => [ ({ 'ok' => 1, actual_ok => 1 }) x 10
                                       ],
                       },

   head_end         => {
                        passing     => 1,

                        max         => 4,
                        seen        => 4,

                        'ok'        => 4,
                        'todo'      => 0,
                        'skip'      => 0,
                        bonus       => 0,

                        details     => [ ({ 'ok' => 1, actual_ok => 1 }) x 4
                                       ],
                       },

   lone_not_bug     => {
                        passing     => 1,

                        max         => 4,
                        seen        => 4,

                        'ok'        => 4,
                        'todo'      => 0,
                        'skip'      => 0,
                        bonus       => 0,

                        details     => [ ({ 'ok' => 1, actual_ok => 1 }) x 4
                                       ],
                       },

   head_fail           => {
                           passing  => 0,

                           max      => 4,
                           seen     => 4,

                           'ok'     => 3,
                           'todo'   => 0,
                           'skip'   => 0,
                           bonus    => 0,

                           details  => [ { 'ok' => 1, actual_ok => 1 },
                                         { 'ok' => 0, actual_ok => 0 },
                                         ({ 'ok'=> 1, actual_ok => 1 }) x 2
                                       ],
                          },
               
   simple           => {
                        passing     => 1,

                        max         => 5,
                        seen        => 5,
                        
                        'ok'          => 5,
                        'todo'        => 0,
                        'skip'        => 0,
                        bonus       => 0,
                        
                        details     => [ ({ 'ok' => 1, actual_ok => 1 }) x 5
                                       ]
                       },

   simple_fail      => {
                        passing     => 0,

                        max         => 5,
                        seen        => 5,
                        
                        'ok'          => 3,
                        'todo'        => 0,
                        'skip'        => 0,
                        bonus       => 0,
                        
                        details     => [ { 'ok' => 1, actual_ok => 1 },
                                         { 'ok' => 0, actual_ok => 0 },
                                         { 'ok' => 1, actual_ok => 1 },
                                         { 'ok' => 1, actual_ok => 1 },
                                         { 'ok' => 0, actual_ok => 0 },
                                       ]
                       },

   'skip'             => {
                        passing     => 1,

                        max         => 5,
                        seen        => 5,

                        'ok'          => 5,
                        'todo'        => 0,
                        'skip'        => 1,
                        bonus       => 0,
                        
                        details     => [ { 'ok' => 1, actual_ok => 1 },
                                         { 'ok'   => 1, actual_ok => 1,
                                           type   => 'skip',
                                           reason => 'rain delay',
                                         },
                                         ({ 'ok' => 1, actual_ok => 1 }) x 3
                                       ]
                       },

   skip_all           => {
                          passing   => 1,

                          max       => 0,
                          seen      => 0,
                          skip_all  => 'rope',

                          'ok'      => 0,
                          'todo'    => 0,
                          'skip'    => 0,
                          bonus     => 0,
                          
                          details   => [],
                         },

   'todo'             => {
                        passing     => 1,

                        max         => 5,
                        seen        => 5,
                                    
                        'ok'          => 5,
                        'todo'        => 2,
                        'skip'        => 0,
                        bonus       => 1,

                        details     => [ { 'ok' => 1, actual_ok => 1 },
                                         { 'ok' => 1, actual_ok => 1,
                                           type => 'todo' },
                                         { 'ok' => 1, actual_ok => 0,
                                           type => 'todo' },
                                         ({ 'ok' => 1, actual_ok => 1 }) x 2
                                       ],
                       },
   taint            => {
                        passing     => 1,

                        max         => 1,
                        seen        => 1,

                        'ok'          => 1,
                        'todo'        => 0,
                        'skip'        => 0,
                        bonus       => 0,

                        details     => [ { 'ok' => 1, actual_ok => 1,
                                           name => '- -T honored'
                                         },
                                       ],
                       },
   vms_nit          => {
                        passing     => 0,

                        max         => 2,
                        seen        => 2,

                        'ok'          => 1,
                        'todo'        => 0,
                        'skip'        => 0,
                        bonus       => 0,

                        details     => [ { 'ok' => 0, actual_ok => 0 },
                                         { 'ok' => 1, actual_ok => 1 },
                                       ],
                       },              
);


while( my($test, $expect) = each %samples ) {
    my $strap = Test::Harness::Straps->new;
    my %results = $strap->analyze_file("$SAMPLE_TESTS/$test");
    
    is_deeply($expect->{details}, $results{details}, "$test details" );

    delete $expect->{details};
    delete $results{details};
    is_deeply($expect, \%results, "  the rest" );
}
