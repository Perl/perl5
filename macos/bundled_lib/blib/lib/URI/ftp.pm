package URI::ftp;

require URI::_server;
require URI::_userpass;
@ISA=qw(URI::_server URI::_userpass);

use strict;
use vars qw($whoami $fqdn);
use URI::Escape qw(uri_unescape);

sub default_port { 21 }

sub path { shift->path_query(@_) }  # XXX

sub _user     { shift->SUPER::user(@_);     }
sub _password { shift->SUPER::password(@_); }

sub user
{
    my $self = shift;
    my $user = $self->_user(@_);
    $user = "anonymous" unless defined $user;
    $user;
}

sub password
{
    my $self = shift;
    my $pass = $self->_password(@_);
    unless (defined $pass) {
	my $user = $self->user;
	if ($user eq 'anonymous' || $user eq 'ftp') {
	    # anonymous ftp login password
	    unless (defined $fqdn) {
		eval {
		    require Net::Domain;
		    $fqdn = Net::Domain::hostfqdn();
		};
		if ($@) {
		    $fqdn = '';
		}
	    }
	    unless (defined $whoami) {
		$whoami = $ENV{USER} || $ENV{LOGNAME} || $ENV{USERNAME};
		unless ($whoami) {
		    if ($^O eq 'MSWin32') { $whoami = Win32::LoginName() }
		    else {
		        $whoami = getlogin || getpwuid($<) || 'unknown';
		    }
		}
	    }
	    $pass = "$whoami\@$fqdn";
	}
    }
    $pass;
}

1;
