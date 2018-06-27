package ExtUtils::MM_AIX;

use strict;
our $VERSION = '7.24';
$VERSION = eval $VERSION;

require ExtUtils::MM_Unix;
our @ISA = qw(ExtUtils::MM_Unix);

=head1 NAME

ExtUtils::MM_AIX - AIX specific subclass of ExtUtils::MM_Unix

=head1 SYNOPSIS

  Don't use this module directly.
  Use ExtUtils::MM and let it choose.

=head1 DESCRIPTION

This is a subclass of ExtUtils::MM_Unix which contains functionality for
AIX.

Unless otherwise stated it works just like ExtUtils::MM_Unix

=head2 Overridden methods

=head3 dlsyms

Define DL_FUNCS and DL_VARS and write the *.exp files.

=cut

sub dlsyms {
    my($self,%attribs) = @_;
    return '' unless $self->needs_linking;
    my @m;
    # these will need XSMULTI-fying but maybe that already happens
    push @m,"\ndynamic :: $self->{BASEEXT}.exp\n\n"
      unless $self->{SKIPHASH}{'dynamic'}; # dynamic and static are subs, so...
    push @m,"\nstatic :: $self->{BASEEXT}.exp\n\n"
      unless $self->{SKIPHASH}{'static'};  # we avoid a warning if we tick them
    join "\n", @m, $self->xs_dlsyms_iterator(\%attribs);
}

=head3 xs_dlsyms_ext

On AIX, is C<.exp>.

=cut

sub xs_dlsyms_ext {
    '.exp';
}

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com> with code from ExtUtils::MM_Unix

=head1 SEE ALSO

L<ExtUtils::MakeMaker>

=cut


1;
