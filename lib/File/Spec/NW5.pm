package File::Spec::NW5;

use strict;
use vars qw(@ISA $VERSION);
require File::Spec::Win32;

$VERSION = '1.0';

@ISA = qw(File::Spec::Win32);

sub catdir {
    my $self = shift;
    my @args = @_;
    for (@args) {
	# append a slash to each argument unless it has one there
	$_ .= "\\" if $_ eq '' or substr($_,-1) ne "\\";
    }
    my $result = $self->canonpath(join('', @args));
    $result;
}

sub canonpath {
    my $self = shift;
    my $path = $self->SUPER::canonpath(@_);
    $path .= '.' if $path =~ m#\\$#;
    return $path;
}


1;
__END__

=head1 NAME

File::Spec::NW5 - methods for NetWare file specs

=head1 SYNOPSIS

 require File::Spec::NW5; # Done internally by File::Spec if needed

=head1 DESCRIPTION

See File::Spec::Win32 and File::Spec::Unix for a documentation of the
methods provided there. This package overrides the implementation of
these methods, not the semantics.

This module is still in beta.  NetWare-knowledgeable folks are invited
to offer patches and suggestions.
