### make sure we can find our conf.pl file
BEGIN { 
    use FindBin; 
    require "$FindBin::Bin/inc/conf.pl";
}

use strict;
use Test::More      'no_plan';

use CPANPLUS::Internals::Constants;


my $Class = 'CPANPLUS::Shell';
my $Conf  = gimme_conf();

$Conf->set_conf( shell => SHELL_DEFAULT );

### basic load tests
use_ok( $Class );
is( $Class->which,  SHELL_DEFAULT,
                                "Default shell loaded" );

