package threads::shared;

use strict;
use warnings;
use Config;
use Scalar::Util qw(weaken);
use attributes qw(reftype);

BEGIN {
    if($Config{'useithreads'} && $Config::threads) {
	*share = \&share_enabled;
	*cond_wait = \&cond_wait_disabled;
	*cond_signal = \&cond_signal_disabled;
	*cond_broadcast = \&cond_broadcast_disabled;
	*unlock = \&unlock_disabled;
	*lock = \&lock_disabled;
    } else {
	*share = \&share_enabled;
    }
}

require Exporter;
require DynaLoader;
our @ISA = qw(Exporter DynaLoader);

our @EXPORT = qw(share cond_wait cond_broadcast cond_signal unlock lock);
our $VERSION = '0.01';

our %shared;

sub cond_wait_disabled { return @_ };
sub cond_signal_disabled { return @_};
sub cond_broadcast_disabled { return @_};
sub unlock_disabled { 1 };
sub lock_disabled { 1 }
sub share_disabled { return @_}

sub share_enabled (\[$@%]) { # \]     
    my $value = $_[0];
    my $ref = reftype($value);
    if($ref eq 'SCALAR') {
      my $obj = \threads::shared::sv->new($$value);
      bless $obj, 'threads::shared::sv';
      $shared{$$obj} = $value;
      weaken($shared{$$obj});
    } else {
	die "You cannot share ref of type $_[0]\n";
    }
}

sub CLONE {
    return unless($_[0] eq "threads::shared");
	foreach my $ptr (keys %shared) {
	    if($ptr) {
		thrcnt_inc($shared{$ptr});
	    }
	}
}

package threads::shared::sv;
use base 'threads::shared';

package threads::shared::av;
use base 'threads::shared';

package threads::shared::hv;
use base 'threads::shared';

bootstrap threads::shared $VERSION;

__END__

=head1 NAME

threads::shared - Perl extension for sharing data structures between threads

=head1 SYNOPSIS

  use threads::shared;

  my($foo, @foo, %foo);
  share(\$foo);
  share(\@foo);
  share(\%hash);
  my $bar = share([]);
  $hash{bar} = share({});

  lock(\%hash);
  unlock(\%hash);
  cond_wait($scalar);
  cond_broadcast(\@array);
  cond_signal($scalar);

=head1 DESCRIPTION

This modules allows you to share() variables. These variables will
then be shared across different threads (and pseudoforks on
win32). They are used together with the threads module.

=head2 EXPORT

share(), lock(), unlock(), cond_wait, cond_signal, cond_broadcast

=head1 BUGS

Not stress tested!
Does not support references
Does not support splice on arrays!
The exported functions need a reference due to unsufficent prototyping!

=head1 AUTHOR

Artur Bergman E<lt>artur at contiller.seE<gt>

threads is released under the same license as Perl

=head1 SEE ALSO

L<perl> L<threads>

=cut
