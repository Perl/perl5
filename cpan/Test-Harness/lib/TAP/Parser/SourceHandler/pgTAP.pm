package TAP::Parser::SourceHandler::pgTAP;

use strict;
use vars qw($VERSION @ISA);

use TAP::Parser::IteratorFactory   ();
use TAP::Parser::Iterator::Process ();

@ISA = qw(TAP::Parser::SourceHandler);
TAP::Parser::IteratorFactory->register_handler(__PACKAGE__);

=head1 NAME

TAP::Parser::SourceHandler::pgTAP - Stream TAP from pgTAP test scripts

=head1 VERSION

Version 3.21

=cut

$VERSION = '3.21';

=head1 SYNOPSIS

In F<Build.PL> for your application with pgTAP tests in F<t/*.pg>:

  Module::Build->new(
      module_name        => 'MyApp',
      test_file_exts     => [qw(.t .pg)],
      use_tap_harness    => 1,
      tap_harness_args   => {
          sources => {
              Perl  => undef,
              pgTAP => {
                  dbname => 'try',
                  username => 'postgres',
                  suffix => '.pg',
              },
          }
      },
      build_requires     => {
          'Module::Build'                      => '0.30',
          'TAP::Parser::SourceHandler::pgTAP' => '3.19',
      },
  )->create_build_script;

If you're using L<C<prove>|prove>:

  prove --source Perl \
        --source pgTAP --pgtap-option dbname=try \
                       --pgtap-option username=postgres \
                       --pgtap-option suffix=.pg

Direct use:

  use TAP::Parser::Source;
  use TAP::Parser::SourceHandler::pgTAP;

  my $source = TAP::Parser::Source->new->raw(\'mytest.pg');
  $source->config({ pgTAP => {
      dbname   => 'testing',
      username => 'postgres',
      suffix   => '.pg',
  });
  $source->assemble_meta;

  my $class = 'TAP::Parser::SourceHandler::pgTAP';
  my $vote  = $class->can_handle( $source );
  my $iter  = $class->make_iterator( $source );

=head1 DESCRIPTION

This source handler executes pgTAP tests. It does two things:

=over

=item 1.

Looks at the L<TAP::Parser::Source> passed to it to determine whether or not
the source in question is in fact a pgTAP test (L</can_handle>).

=item 2.

Creates an iterator that will call C<psql> to run the pgTAP tests
(L</make_iterator>).

=back

Unless you're writing a plugin or subclassing L<TAP::Parser>, you probably
won't need to use this module directly.

=head1 METHODS

=head2 Class Methods

=head3 C<can_handle>

  my $vote = $class->can_handle( $source );

Looks at the source to determine whether or not it's a pgTAP test file and
returns a score for how likely it is in fact a pgTAP test file. The scores are
as follows:

  1    if it has a suffix equal to that in the "suffix" config
  1    if its suffix is ".pg"
  0.8  if its suffix is ".sql"
  0.75 if its suffix is ".s"

The latter two scores are subject to change, so try to name your pgTAP tests
ending in ".pg" or specify a suffix in the configuration to be sure.

=cut

sub can_handle {
    my ( $class, $source ) = @_;
    my $meta = $source->meta;

    return 0 unless $meta->{is_file};

    my $suf = $meta->{file}{lc_ext};

    # If the config specifies a suffix, it's required.
    if ( my $config = $source->config_for('pgTAP') ) {
        if ( defined $config->{suffix} ) {
            return $suf eq $config->{suffix} ? 1 : 0;
        }
    }

    # Otherwise, return a score for our supported suffixes.
    my %score_for = (
        '.pg'  => 0.9,
        '.sql' => 0.8,
        '.s'   => 0.75,
    );
    return $score_for{$suf} || 0;
}

=head3 C<make_iterator>

  my $iterator = $class->make_iterator( $source );

Returns a new L<TAP::Parser::Iterator::Process> for the source. C<<
$source->raw >> must be either a file name or a scalar reference to the file
name.

The pgTAP tests are run by executing C<psql>, the PostgreSQL command-line
utility. A number of arguments are passed to it, many of which you can effect
by setting up the source source configuration. The configuration must be a
hash reference, and supports the following keys:

=over

=item C<psql>

The path to the C<psql> command. Defaults to simply "psql", which should work
well enough if it's in your path.

=item C<dbname>

The database to which to connect to run the tests. Defaults to the value of
the C<$PGDATABASE> environment variable or, if not set, to the system
username.

=item C<username>

The PostgreSQL username to use to connect to PostgreSQL. If not specified, no
username will be used, in which case C<psql> will fall back on either the
C<$PGUSER> environment variable or, if not set, the system username.

=item C<host>

Specifies the host name of the machine to which to connect to the PostgreSQL
server. If the value begins with a slash, it is used as the directory for the
Unix-domain socket. Defaults to the value of the C<$PGDATABASE> environment
variable or, if not set, the local host.

=item C<port>

Specifies the TCP port or the local Unix-domain socket file extension on which
the server is listening for connections. Defaults to the value of the
C<$PGPORT> environment variable or, if not set, to the port specified at the
time C<psql> was compiled, usually 5432.

=begin comment

=item C<search_path>

The schema search path to use during the execution of the tests. Useful for
overriding the default search path and you have pgTAP installed in a schema
not included in that search path.

=end comment

=back

=cut

sub make_iterator {
    my ( $class, $source ) = @_;
    my $config = $source->config_for('pgTAP');

    my @command = ( $config->{psql} || 'psql' );
    push @command, qw(
      --no-psqlrc
      --no-align
      --quiet
      --pset pager=
      --pset tuples_only=true
      --set ON_ERROR_ROLLBACK=1
      --set ON_ERROR_STOP=1
    );

    for (qw(username host port dbname)) {
        push @command, "--$_" => $config->{$_} if defined $config->{$_};
    }

    my $fn = ref $source->raw ? ${ $source->raw } : $source->raw;
    $class->_croak(
        'No such file or directory: ' . ( defined $fn ? $fn : '' ) )
      unless $fn && -e $fn;

    push @command, '--file', $fn;

  # XXX I'd like a way to be able to specify environment variables to set when
  # the iterator executes the command...
  # local $ENV{PGOPTIONS} = "--search_path=$config->{search_path}"
  #     if $config->{search_path};

    return TAP::Parser::Iterator::Process->new(
        {   command => \@command,
            merge   => $source->merge
        }
    );
}

=head1 SEE ALSO

L<TAP::Object>,
L<TAP::Parser>,
L<TAP::Parser::IteratorFactory>,
L<TAP::Parser::SourceHandler>,
L<TAP::Parser::SourceHandler::Executable>,
L<TAP::Parser::SourceHandler::Perl>,
L<TAP::Parser::SourceHandler::File>,
L<TAP::Parser::SourceHandler::Handle>,
L<TAP::Parser::SourceHandler::RawTAP>

=head1 AUTHOR

David E. Wheeler <dwheeler@cpan.org>

=cut
