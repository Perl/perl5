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

=item _set_defaults

Change $self->{build_script} to 'Build.com' so @Build works.

=cut

sub _set_defaults {
    my $self = shift;
    $self->SUPER::_set_defaults(@_);

    $self->{properties}{build_script} = 'Build.com';
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
	my $vms_prefix = $self->config('vms_prefix');
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

=item _quote_args

Command-line arguments (but not the command itself) must be quoted
to ensure case preservation.

=cut

sub _quote_args {
  # Returns a string that can become [part of] a command line with
  # proper quoting so that the subprocess sees this same list of args,
  # or if we get a single arg that is an array reference, quote the
  # elements of it and return the reference.
  my ($self, @args) = @_;
  my $got_arrayref = (scalar(@args) == 1 
                      && UNIVERSAL::isa($args[0], 'ARRAY')) 
                   ? 1 
                   : 0;

  map { $_ = q(").$_.q(") if !/^\"/ && length($_) > 0 }
     ($got_arrayref ? @{$args[0]} 
                    : @args
     );

  return $got_arrayref ? $args[0] 
                       : join(' ', @args);
}

=item have_forkpipe

There is no native fork(), so some constructs depending on it are not
available.

=cut

sub have_forkpipe { 0 }

=item _backticks

Override to ensure that we quote the arguments but not the command.

=cut

sub _backticks {
  # The command must not be quoted but the arguments to it must be.
  my ($self, @cmd) = @_;
  my $cmd = shift @cmd;
  my $args = $self->_quote_args(@cmd);
  return `$cmd $args`;
}

=item do_system

Override to ensure that we quote the arguments but not the command.

=cut

sub do_system {
  # The command must not be quoted but the arguments to it must be.
  my ($self, @cmd) = @_;
  $self->log_info("@cmd\n");
  my $cmd = shift @cmd;
  my $args = $self->_quote_args(@cmd);
  return !system("$cmd $args");
}

=item _infer_xs_spec

Inherit the standard version but tweak the library file name to be 
something Dynaloader can find.

=cut

sub _infer_xs_spec {
  my $self = shift;
  my $file = shift;

  my $spec = $self->SUPER::_infer_xs_spec($file);

  # Need to create with the same name as DynaLoader will load with.
  if (defined &DynaLoader::mod2fname) {
    my $file = $$spec{module_name} . '.' . $self->{config}->get('dlext');
    $file =~ tr/:/_/;
    $file = DynaLoader::mod2fname([$file]);
    $$spec{lib_file} = File::Spec->catfile($$spec{archdir}, $file);
  }

  return $spec;
}

=item rscan_dir

Inherit the standard version but remove dots at end of name.  This may not be 
necessary if File::Find has been fixed or DECC$FILENAME_UNIX_REPORT is in effect.

=cut

sub rscan_dir {
  my ($self, $dir, $pattern) = @_;

  my $result = $self->SUPER::rscan_dir( $dir, $pattern );

  for my $file (@$result) { $file =~ s/\.$//; }
  return $result;
}

=item dist_dir

Inherit the standard version but replace embedded dots with underscores because 
a dot is the directory delimiter on VMS.

=cut

sub dist_dir {
  my $self = shift;

  my $dist_dir = $self->SUPER::dist_dir;
  $dist_dir =~ s/\./_/g;
  return $dist_dir;
}

=item man3page_name

Inherit the standard version but chop the extra manpage delimiter off the front if 
there is one.  The VMS version of splitdir('[.foo]') returns '', 'foo'.

=cut

sub man3page_name {
  my $self = shift;

  my $mpname = $self->SUPER::man3page_name( shift );
  $mpname =~ s/^$self->manpage_separator//;
  return $mpname;
}

=item expand_test_dir

Inherit the standard version but relativize the paths as the native glob() doesn't
do that for us.

=cut

sub expand_test_dir {
  my ($self, $dir) = @_;

  my @reldirs = $self->SUPER::expand_test_dir( $dir );

  for my $eachdir (@reldirs) {
    my ($v,$d,$f) = File::Spec->splitpath( $eachdir );
    my $reldir = File::Spec->abs2rel( File::Spec->catpath( $v, $d, '' ) );
    $eachdir = File::Spec->catfile( $reldir, $f );
  }
  return @reldirs;
}

=back

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>
Ken Williams <kwilliams@cpan.org>
Craig A. Berry <craigberry@mac.com>

=head1 SEE ALSO

perl(1), Module::Build(3), ExtUtils::MakeMaker(3)

=cut

1;
__END__
