### make sure we can find our conf.pl file
BEGIN { 
    use FindBin; 
    require "$FindBin::Bin/inc/conf.pl";
}

use strict;

use CPANPLUS::Backend;

use Test::More 'no_plan';
use Data::Dumper;

my $conf = gimme_conf();

my $cb = CPANPLUS::Backend->new( $conf );
isa_ok($cb, "CPANPLUS::Internals" );

my $mt      = $cb->_module_tree;
my $at      = $cb->_author_tree;
my $modname = TEST_CONF_MODULE;

for my $name (qw[auth mod dslip] ) {
    my $file = File::Spec->catfile( 
                        $conf->get_conf('base'),
                        $conf->_get_source($name)
                );            
    ok( (-e $file && -f _ && -s _), "$file exists" );
}    

ok( scalar keys %$at, "Authortree loaded successfully" );
ok( scalar keys %$mt, "Moduletree loaded successfully" );

my $auth    = $at->{'EUNOXS'};
my $mod     = $mt->{$modname};

isa_ok( $auth, 'CPANPLUS::Module::Author' );
isa_ok( $mod,  'CPANPLUS::Module' );

# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:
