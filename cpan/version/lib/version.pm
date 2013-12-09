#!perl -w
package version;

use 5.005_05;
use strict;

use vars qw(@ISA $VERSION $CLASS $STRICT $LAX *declare *qv);

$VERSION = 0.9905;
$CLASS = 'version';

{
    local $SIG{'__DIE__'};
    eval "use version::vxs $VERSION";
    if ( $@ ) { # don't have the XS version installed
	eval "use version::vpp $VERSION"; # don't tempt fate
	die "$@" if ( $@ );
	push @ISA, "version::vpp";
	local $^W;
	*version::qv = \&version::vpp::qv;
	*version::declare = \&version::vpp::declare;
	*version::_VERSION = \&version::vpp::_VERSION;
	*version::vcmp = \&version::vpp::vcmp;
	*version::new = \&version::vpp::new;
	if ($] >= 5.009000) {
	    no strict 'refs';
	    *version::stringify = \&version::vpp::stringify;
	    *{'version::(""'} = \&version::vpp::stringify;
	    *{'version::(<=>'} = \&version::vpp::vcmp;
	    *version::parse = \&version::vpp::parse;
	}
	*version::is_strict = \&version::vpp::is_strict;
	*version::is_lax = \&version::vpp::is_lax;
    }
    else { # use XS module
	push @ISA, "version::vxs";
	local $^W;
	*version::declare = \&version::vxs::declare;
	*version::qv = \&version::vxs::qv;
	*version::_VERSION = \&version::vxs::_VERSION;
	*version::vcmp = \&version::vxs::VCMP;
	*version::new = \&version::vxs::new;
	if ($] >= 5.009000) {
	    no strict 'refs';
	    *version::stringify = \&version::vxs::stringify;
	    *{'version::(""'} = \&version::vxs::stringify;
	    *{'version::(<=>'} = \&version::vxs::VCMP;
	    *version::parse = \&version::vxs::parse;
	}
	*version::is_strict = \&version::vxs::is_strict;
	*version::is_lax = \&version::vxs::is_lax;
    }
}

sub import {
    no strict 'refs';
    my ($class) = shift;

    # Set up any derived class
    unless ($class eq $CLASS) {
	local $^W;
	*{$class.'::declare'} =  \&{$CLASS.'::declare'};
	*{$class.'::qv'} = \&{$CLASS.'::qv'};
    }

    my %args;
    if (@_) { # any remaining terms are arguments
	map { $args{$_} = 1 } @_
    }
    else { # no parameters at all on use line
	%args =
	(
	    qv => 1,
	    'UNIVERSAL::VERSION' => 1,
	);
    }

    my $callpkg = caller();

    if (exists($args{declare})) {
	*{$callpkg.'::declare'} =
	    sub {return $class->declare(shift) }
	  unless defined(&{$callpkg.'::declare'});
    }

    if (exists($args{qv})) {
	*{$callpkg.'::qv'} =
	    sub {return $class->qv(shift) }
	  unless defined(&{$callpkg.'::qv'});
    }

    if (exists($args{'UNIVERSAL::VERSION'})) {
	local $^W;
	*UNIVERSAL::VERSION
		= \&{$CLASS.'::_VERSION'};
    }

    if (exists($args{'VERSION'})) {
	*{$callpkg.'::VERSION'} = \&{$CLASS.'::_VERSION'};
    }

    if (exists($args{'is_strict'})) {
	*{$callpkg.'::is_strict'} = \&{$CLASS.'::is_strict'}
	  unless defined(&{$callpkg.'::is_strict'});
    }

    if (exists($args{'is_lax'})) {
	*{$callpkg.'::is_lax'} = \&{$CLASS.'::is_lax'}
	  unless defined(&{$callpkg.'::is_lax'});
    }
}


1;
