BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir('t') if -d 't';
        @INC = qw(../lib);
    }
}

BEGIN { print "1..10\n"; }
use NEXT;

my $count=1;

package A;
@ISA = qw/B C D/;

sub test { print "ok ", $count++, "\n"; $_[0]->NEXT::UNSEEN::test;}

package B;
@ISA = qw/C D/;
sub test { print "ok ", $count++, "\n"; $_[0]->NEXT::UNSEEN::test;}

package C;
@ISA = qw/D/;
sub test { print "ok ", $count++, "\n"; $_[0]->NEXT::UNSEEN::test;}

package D;

sub test { print "ok ", $count++, "\n"; $_[0]->NEXT::UNSEEN::test;}

package main;

my $foo = {};

bless($foo,"A");

$foo->test;

package Diamond::Base;
sub test { print "ok ", $count++, "\n"; shift->NEXT::UNSEEN::test; }

package Diamond::Left;  @ISA = qw[Diamond::Base];
package Diamond::Right; @ISA = qw[Diamond::Base];
package Diamond::Top;   @ISA = qw[Diamond::Left Diamond::Right];

package main;

Diamond::Top->test;
