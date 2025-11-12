use Test::More;
use Time::Piece;

# Skip if doing a regular install
# These are mostly for reverse parsing tests, not required for installation
plan skip_all => "Reverse parsing not required for installation"
  unless ( $ENV{AUTOMATED_TESTING} || $ENV{NONINTERACTIVE_TESTING} || $ENV{PERL_BATCH} );

my $t = gmtime(1373371631);    # 2013-07-09T12:07:11

#locale should be undef
is( $t->_locale, undef );
&Time::Piece::_default_locale();

ok( $t->_locale );

#use localized names
cmp_ok( $t->monname,   'eq', &Time::Piece::_locale()->{mon}[ $t->_mon ] );
cmp_ok( $t->month,     'eq', &Time::Piece::_locale()->{mon}[ $t->_mon ] );
cmp_ok( $t->fullmonth, 'eq', &Time::Piece::_locale()->{month}[ $t->_mon ] );

#use localized names
cmp_ok( $t->wdayname, 'eq', &Time::Piece::_locale()->{wday}[ $t->_wday ] );
cmp_ok( $t->day,      'eq', &Time::Piece::_locale()->{wday}[ $t->_wday ] );
cmp_ok( $t->fullday,  'eq', &Time::Piece::_locale()->{weekday}[ $t->_wday ] );

my @frdays = qw( Dimanche Lundi Merdi Mercredi Jeudi Vendredi Samedi );
$t->day_list(@frdays);
cmp_ok( $t->day,     'eq', &Time::Piece::_locale()->{wday}[ $t->_wday ] );
cmp_ok( $t->fullday, 'eq', &Time::Piece::_locale()->{weekday}[ $t->_wday ] );

# Test fullday_list() method
my @original_fulldays = $t->fullday_list();
is( scalar(@original_fulldays), 7, 'fullday_list() returns 7 days' );

my @custom_fulldays =
  qw( Domingo Lunes Martes Miercoles Jueves Viernes Sabado );
$t->fullday_list(@custom_fulldays);
cmp_ok(
    $t->fullday, 'eq',
    &Time::Piece::_locale()->{weekday}[ $t->_wday ],
    'fullday() returns custom full day name from locale'
);
cmp_ok(
    $t->fullday, 'eq',
    $custom_fulldays[ $t->_wday ],
    'fullday() returns correct custom full day name'
);

# Test fullmon_list() method
my @original_fullmons = $t->fullmon_list();
is( scalar(@original_fullmons), 12, 'fullmon_list() returns 12 months' );

my @custom_fullmons =
  qw( Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre );
$t->fullmon_list(@custom_fullmons);
cmp_ok(
    $t->fullmonth, 'eq',
    &Time::Piece::_locale()->{month}[ $t->_mon ],
    'fullmonth() returns custom full month name from locale'
);
cmp_ok(
    $t->fullmonth, 'eq',
    $custom_fullmons[ $t->_mon ],
    'fullmonth() returns correct custom full month name'
);

# Test strptime with custom full day and month names
# Using 2013-07-09 which is a Tuesday (Martes) in July (Julio)
my $parsed_both = $t->strptime( 'Martes, 9 Julio 2013', '%A, %d %B %Y' );
cmp_ok( $parsed_both->_wday, '==', 2, 'strptime parses custom full day name' );
cmp_ok( $parsed_both->_mon, '==', 6, 'strptime parses custom full month name' );
cmp_ok( $parsed_both->mday, '==', 9, 'strptime parses day of month' );
cmp_ok( $parsed_both->year, '==', 2013, 'strptime parses year' );

#load local locale from system
Time::Piece->use_locale();

#test reverse parsing
sub check_parsed
{
    my ( $t, $parsed, $t_str, $strp_format ) = @_;

    cmp_ok( $parsed->epoch, '==', $t->epoch,
        "Epochs match for $t_str with $strp_format" );
    cmp_ok(
        $parsed->strftime($strp_format),
        'eq',
        $t->strftime($strp_format),
        "Outputs formatted with $strp_format match"
    );
    cmp_ok( $parsed->strftime(), 'eq', $t->strftime(),
        'Outputs formatted as default match' );
    cmp_ok(
        $parsed->datetime(), 'eq',
        $t->strftime("%Y-%m-%dT%H:%M:%S"),
        'datetime() matches strftime()'
    );
}

my @dates = (
    '%Y-%m-%d %H:%M:%S',
    '%Y-%m-%d %T',
    '%A, %e %B %Y at %H:%M:%S',
    '%a, %e %b %Y at %r',
    '%s',
    '%F %T',
    '%D %r',

#TODO
#    '%u %U %Y %T',                    #%U,W,V currently skipped inside strptime
#    '%w %W %y %T',
);

for my $time (
    time(),        # Now, whenever that might be
    1451606400,    # 2016-01-01 00:00
    1451653500,    # 2016-01-01 13:05
    1449014400,    # 2015-12-02 00:00
  )
{
    my $t = gmtime($time);

    for my $strp_format (@dates) {

        my $t_str = $t->strftime($strp_format);
        my $parsed;

        eval { $parsed = $t->strptime( $t_str, $strp_format ); };

        if ($@) {
            warn("gmtime strptime failed with time $t_str and format $strp_format");
            warn($@);
            next;
        }

        check_parsed( $t, $parsed, $t_str, $strp_format );
    }

}

for my $time (
    time(),        # Now, whenever that might be
    1451606430,    # 2016-01-01 00:00:30
    1451653530,    # 2016-01-01 13:05:30
    1449014430,    # 2015-12-02 00:00:30
  )
{
    my $t = localtime($time);
    for my $strp_format (@dates) {

        my $t_str = $t->strftime($strp_format);
        my $parsed;

        eval { $parsed = $t->strptime( $t_str, $strp_format ); };

        if ($@) {
            warn("local strptime failed with time $t_str and format $strp_format");
            warn($@);
            next;
        }
        check_parsed( $t, $parsed, $t_str, $strp_format );

    }

}

done_testing(244);
