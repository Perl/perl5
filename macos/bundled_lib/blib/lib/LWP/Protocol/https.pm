#
# $Id: https.pm,v 1.10 2001/10/26 18:29:27 gisle Exp $

use strict;

package LWP::Protocol::https;

use vars qw(@ISA);

require LWP::Protocol::http;
require LWP::Protocol::https10;

@ISA = qw(LWP::Protocol::http);
my $SSL_CLASS = $LWP::Protocol::https10::SSL_CLASS;

#we need this to setup a proper @ISA tree
{
    package LWP::Protocol::MyHTTPS;
    use vars qw(@ISA);
    @ISA = ($SSL_CLASS, 'LWP::Protocol::MyHTTP');

    #we need to call both Net::SSL::configure and Net::HTTP::configure
    #however both call SUPER::configure (which is IO::Socket::INET)
    #to avoid calling that twice we override Net::HTTP's
    #_http_socket_configure

    sub configure {
        my $self = shift;
        for my $class (@ISA) {
            my $cfg = $class->can('configure');
            $cfg->($self, @_);
        }
        $self;
    }

    sub _http_socket_configure {
	$_[0];
    }

    # The underlying SSLeay classes fails to work if the socket is
    # placed in non-blocking mode.  This override of the blocking
    # method makes sure it stays the way it was created.
    sub blocking { }  # noop
}

sub _conn_class {
    "LWP::Protocol::MyHTTPS";
}

{
    #if we inherit from LWP::Protocol::https10 we inherit from
    #LWP::Protocol::http10, so just setup aliases for these two
    no strict 'refs';
    for (qw(_check_sock _get_sock_info)) {
        *{"$_"} = \&{"LWP::Protocol::https10::$_"};
    }
}

1;
