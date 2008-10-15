# For testing Test::Simple;
# $Id: /mirror/googlecode/test-more-trunk/t/lib/Test/Simple/Catch.pm 67132 2008-10-01T01:11:04.501643Z schwern  $
package Test::Simple::Catch;

use Symbol;
use TieOut;
my( $out_fh, $err_fh ) = ( gensym, gensym );
my $out = tie *$out_fh, 'TieOut';
my $err = tie *$err_fh, 'TieOut';

use Test::Builder;
my $t = Test::Builder->new;
$t->output($out_fh);
$t->failure_output($err_fh);
$t->todo_output($err_fh);

sub caught { return( $out, $err ) }

1;
