package Module::Build::Platform::VMS;

use strict;
use Module::Build::Base;

use vars qw(@ISA);
@ISA = qw(Module::Build::Base);



=head1 NAME

Module::Build::Platform::VMS - Builder class for VMS platforms

=head1 DESCRIPTION

This module inherits from C<Module::Build::Base> and alters a few
minor details of its functionality.  Please see L<Module::Build> for
the general docs.

=head2 Overridden Methods

=over 4

=item new

Change $self->{build_script} to 'Build.com' so @Build works.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{properties}{build_script} = 'Build.com';

    return $self;
}


=item cull_args

'@Build foo' on VMS will not preserve the case of 'foo'.  Rather than forcing
people to write '@Build "foo"' we'll dispatch case-insensitively.

=cut

sub cull_args {
    my $self = shift;
    my($action, $args) = $self->SUPER::cull_args(@_);
    my @possible_actions = grep { lc $_ eq lc $action } $self->known_actions;

    die "Ambiguous action '$action'.  Could be one of @possible_actions"
        if @possible_actions > 1;

    return ($possible_actions[0], $args);
}


=item manpage_separator

Use '__' instead of '::'.

=cut

sub manpage_separator {
    return '__';
}


=item prefixify

Prefixify taking into account VMS' filepath syntax.

=cut

# Translated from ExtUtils::MM_VMS::prefixify()
sub _prefixify {
    my($self, $path, $sprefix, $type) = @_;
    my $rprefix = $self->prefix;

    $self->log_verbose("  prefixify $path from $sprefix to $rprefix\n");

    # Translate $(PERLPREFIX) to a real path.
    $rprefix = $self->eliminate_macros($rprefix);
    $rprefix = VMS::Filespec::vmspath($rprefix) if $rprefix;
    $sprefix = VMS::Filespec::vmspath($sprefix) if $sprefix;

    $self->log_verbose("  rprefix translated to $rprefix\n".
                       "  sprefix translated to $sprefix\n");

    if( length $path == 0 ) {
        $self->log_verbose("  no path to prefixify.\n")
    }
    elsif( !File::Spec->file_name_is_absolute($path) ) {
        $self->log_verbose("    path is relative, not prefixifying.\n");
    }
    elsif( $sprefix eq $rprefix ) {
        $self->log_verbose("  no new prefix.\n");
    }
    else {
        my($path_vol, $path_dirs) = File::Spec->splitpath( $path );
	my $vms_prefix = $self->config->{vms_prefix};
        if( $path_vol eq $vms_prefix.':' ) {
            $self->log_verbose("  $vms_prefix: seen\n");

            $path_dirs =~ s{^\[}{\[.} unless $path_dirs =~ m{^\[\.};
            $path = $self->_catprefix($rprefix, $path_dirs);
        }
        else {
            $self->log_verbose("    cannot prefixify.\n");
	    return $self->prefix_relpaths($self->installdirs, $type);
        }
    }

    $self->log_verbose("    now $path\n");

    return $path;
}


sub _quote_args {
  # Returns a string that can become [part of] a command line with
  # proper quoting so that the subprocess sees this same list of args.
  my ($self, @args) = @_;

  my $return_args = '';
  for (@args) {
    $return_args .= q( ").$_.q(") if !/^\"/ && length($_) > 0;
  }
  return $return_args;
}

sub have_forkpipe { 0 }

=back

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>, Ken Williams <ken@cpan.org>

=head1 SEE ALSO

perl(1), Module::Build(3), ExtUtils::MakeMaker(3)

=cut

1;
__END__
