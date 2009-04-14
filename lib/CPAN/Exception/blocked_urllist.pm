# -*- Mode: cperl; coding: utf-8; cperl-indent-level: 4 -*-
# vim: ts=4 sts=4 sw=4:
package CPAN::Exception::blocked_urllist;
use strict;
use overload '""' => "as_string";

use vars qw(
            $VERSION
);
$VERSION = "1.0";


sub new {
    my($class) = @_;
    bless {}, $class;
}

sub as_string {
    my($self) = shift;
    if ($CPAN::Config->{connect_to_internet_ok}) {
        return qq{

You have not configured a urllist. Please consider to set it with

    o conf init urllist

};
    } else {
        return qq{

You have not configured a urllist and did not allow to connect to the
internet. Please consider to call

    o conf init connect_to_internet_ok urllist

};
    }
}

1;
