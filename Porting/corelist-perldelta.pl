#!perl
use 5.010;
use strict;
use warnings;
use lib 'Porting';
use Maintainers qw/%Modules/;
use lib 'dist/Module-CoreList/lib';
use Module::CoreList;
use Getopt::Long;

=head1 USAGE

  # generate the module changes for the Perl you are currently building
  ./perl -Ilib Porting/corelist-perldelta.pl
  
  # generate a diff between the corelist sections of two perldelta* files:
  perl Porting/corelist-perldelta.pl --mode=check 5.017001 5.017002 <perl5172delta.pod

=head1 ABOUT

corelist-perldelta.pl is a bit schizophrenic. The part to generate the
new Perldelta text does not need Algorithm::Diff, but wants to be
run with the freshly built Perl.

The part to check the diff wants to be run with a Perl that has an up-to-date
L<Module::CoreList>, but needs the outside L<Algorithm::Diff>.

Ideally, the program will be split into two separate programs, one
to generate the text and one to show the diff between the
corelist sections of the last perldelta and the next perldelta.

=cut

my %sections = (
  new     => qr/New Modules and Pragma(ta)?/,
  updated => qr/Updated Modules and Pragma(ta)?/,
  removed => qr/Removed Modules and Pragma(ta)?/,
);

my %titles = (
  new     => 'New Modules and Pragmata',
  updated => 'Updated Modules and Pragmata',
  removed => 'Removed Modules and Pragmata',
);

my $deprecated;

#--------------------------------------------------------------------------#

sub added {
  my ($mod, $old_v, $new_v) = @_;
  say "=item *\n";
  say "L<$mod> $new_v has been added to the Perl core.\n";
}

sub updated {
  my ($mod, $old_v, $new_v) = @_;
  say "=item *\n";
  say "L<$mod> has been upgraded from version $old_v to $new_v.\n";
  if ( $deprecated->{$mod} ) {
    say "NOTE: L<$mod> is deprecated and may be removed from a future version of Perl.\n";
  }
}

sub removed {
  my ($mod, $old_v, $new_v) = @_;
  say "=item *\n";
  say "C<$mod> has been removed from the Perl core.  Prior version was $old_v.\n";
}

sub generate_section {
  my ($title, $item_sub, @mods ) = @_;
  return unless @mods;

  say "=head2 $title\n";
  say "=over 4\n";

  for my $tuple ( sort { lc($a->[0]) cmp lc($b->[0]) } @mods ) {
    my ($mod,$old_v,$new_v) = @$tuple;
    $old_v //= q('undef');
    $new_v //= q('undef');
    $item_sub->($mod, $old_v, $new_v);
  }

  say "=back\n";
}

#--------------------------------------------------------------------------#

sub run {
  my %opt = (mode => 'generate');

  GetOptions(\%opt,
    'mode|m:s', # 'generate', 'check'
  );

  # by default, compare latest two version in CoreList;
  my @versions = sort keys %Module::CoreList::version;
  my ($old, $new) = (shift @ARGV, shift @ARGV);
  $old ||= $versions[-2];
  $new ||= $versions[-1];

  if ( $opt{mode} eq 'generate' ) {
    do_generate($old => $new);
  }
  elsif ( $opt{mode} eq 'check' ) {
    do_check(\*ARGV, $old => $new);
  }
  else {
    die "Unrecognized mode '$opt{mode}'\n";
  }

  exit 0;
}

# Given two perl versions, it returns a list describing the core distributions that have changed.
# The first three elements are hashrefs corresponding to new, updated, and removed modules
# and are of the form (mostly, see the special remarks about removed):
#   'Distribution Name' => ['Distribution Name', previous version number, current version number]
# where the version number is undef if the distribution did not exist the fourth element is
# an arrayref of core distribution names of those distribution for which it is unknown whether
# they have changed and therefore need to be manually checked.
#
# In most cases, the distribution name in %Modules corresponds to the module that is representative
# of the distribution as listed in Module::CoreList. However, there are a few distribution names
# that do not correspond to a module. %distToModules, has been created which maps the distribution
# name to a representative module. The representative module was chosen by either looking at the
# Makefile of the distribution or by seeing which module the distribution has been traditionally
# listed under in past perldelta.
#
# There are a few distributions for which there is no single representative module (e.g. libnet).
# These distributions are returned as the last element of the list.
#
# %Modules contains a final key, _PERLLIB, which contains a list of modules that are owned by p5p.
# This list contains modules and pragmata that may also be present in Module::CoreList.
# A list of modules are in the list @unclaimedModules, which were manually listed based on whether
# they were independent modules and whether they have been listed in past perldelta.
# The pragmata were found by doing something like:
#   say for sort grep { $_ eq lc $_ and !exists $Modules{$_}}
#     keys %{$Module::CoreList::version{'5.019003'}}
# and manually filtering out pragamata that were already covered.
#
# It is currently not possible to differentiate between a removed module and a removed
# distribution. Therefore, the removed hashref contains every module that has been removed, even if
# the module's corresponding distribution has not been removed.

sub corelist_delta {
  my ($old, $new) = @_;
  my $corelist = \%Module::CoreList::version;
  my %changes = Module::CoreList::changes_between( $old, $new );
  $deprecated = $Module::CoreList::deprecated{$new};

  my $getModifyType = sub {
    my $data = shift;
    if ( exists $data->{left} and exists $data->{right} ) {
      return 'updated';
    }
    elsif ( !exists $data->{left} and exists $data->{right} ) {
      return 'new';
    }
    elsif ( exists $data->{left} and !exists $data->{right} ) {
      return 'removed';
    }
    return undef;
  };

  my @unclaimedModules = qw/AnyDBM_File B B::Concise B::Deparse Benchmark Class::Struct Config::Extensions DB DBM_Filter Devel::Peek DirHandle DynaLoader English Errno ExtUtils::Embed ExtUtils::Miniperl ExtUtils::Typemaps ExtUtils::XSSymSet Fcntl File::Basename File::Compare File::Copy File::DosGlob File::Find File::Glob File::stat FileCache FileHandle FindBin GDBM_File Getopt::Std Hash::Util Hash::Util::FieldHash I18N::Langinfo IPC::Open3 NDBM_File ODBM_File Opcode PerlIO PerlIO::encoding PerlIO::mmap PerlIO::scalar PerlIO::via Pod::Functions Pod::Html POSIX SDBM_File SelectSaver Symbol Sys::Hostname Thread Tie::Array Tie::Handle Tie::Hash Tie::Hash::NamedCapture Tie::Memoize Tie::Scalar Tie::StdHandle Tie::SubstrHash Time::gmtime Time::localtime Time::tm Unicode::UCD UNIVERSAL User::grent User::pwent VMS::DCLsym VMS::Filespec VMS::Stdio XS::Typemap Win32CORE/;
  my @unclaimedPragmata = qw/_charnames arybase attributes blib bytes charnames deprecate diagnostics encoding feature fields filetest inc::latest integer less locale mro open ops overload overloading re sigtrap sort strict subs utf8 vars vmsish/;
  my @unclaimed = (@unclaimedModules, @unclaimedPragmata);

  my %distToModules = (
    'IO-Compress' => [
      {
        'name' => 'IO-Compress',
        'modification' => $getModifyType->( $changes{'IO::Compress::Base'} ),
        'data' => $changes{'IO::Compress::Base'}
      }
    ],
    'Locale-Codes' => [
      {
        'name'         => 'Locale::Codes',
        'modification' => $getModifyType->( $changes{'Locale::Codes'} ),
        'data'         => $changes{'Locale::Codes'}
      }
    ],
    'PathTools' => [
      {
        'name'         => 'File::Spec',
        'modification' => $getModifyType->( $changes{'Cwd'} ),
        'data'         => $changes{'Cwd'}
      }
    ],
    'Scalar-List-Utils' => [
      {
        'name'         => 'List::Util',
        'modification' => $getModifyType->( $changes{'List::Util'} ),
        'data'         => $changes{'List::Util'}
      },
      {
        'name'         => 'Scalar::Util',
        'modification' => $getModifyType->( $changes{'Scalar::Util'} ),
        'data'         => $changes{'Scalar::Util'}
      }
    ],
    'Text-Tabs+Wrap' => [
      {
        'name'         => 'Text::Tabs',
        'modification' => $getModifyType->( $changes{'Text::Tabs'} ),
        'data'         => $changes{'Text::Tabs'}
      },
      {
        'name'         => 'Text::Wrap',
        'modification' => $getModifyType->( $changes{'Text::Wrap'} ),
        'data'         => $changes{'Text::Wrap'}
      }
    ],
  );

  # structure is (new|removed|updated) => [ [ModuleName, previousVersion, newVersion] ]
  my $deltaGrouping = {};

  # list of distributions listed in %Modules that need to be manually checked because there is no module that represents it
  my @manuallyCheck;

  # %Modules defines what is currently in core
  for my $k ( keys %Modules ) {
    next if $k eq '_PERLLIB'; #these are taken care of by being listed in @unclaimed
    next if Module::CoreList::is_core($k) and !exists $changes{$k}; #modules that have not changed

    my ( $distName, $modifyType, $data );

    if ( exists $changes{$k} ) {
      $distName   = $k;
      $modifyType = $getModifyType->( $changes{$k} );
      $data       = $changes{$k};
    }
    elsif ( exists $distToModules{$k} ) {
      # modification will be undef if the distribution has not changed
      my @modules = grep { $_->{modification} } @{ $distToModules{$k} };
      for (@modules) {
        $deltaGrouping->{ $_->{modification} }->{ $_->{name} } = [ $_->{name}, $_->{data}->{left}, $_->{data}->{right} ];
      }
      next;
    }
    else {
      push @manuallyCheck, $k and next;
    }

    $deltaGrouping->{$modifyType}->{$distName} = [ $distName, $data->{left}, $data->{right} ];
  }

  for my $k (@unclaimed) {
    if ( exists $changes{$k} ) {
      $deltaGrouping->{ $getModifyType->( $changes{$k} ) }->{$k} =
        [ $k, $changes{$k}->{left}, $changes{$k}->{right} ];
    }
  }

  # in old corelist, but not this one => removed
  # N.B. This is exhaustive -- not just what's in %Modules, so modules removed from
  # distributions will show up here, too.  Some person will have to review to see what's
  # important. That's the best we can do without a historical Maintainers.pl
  for my $k ( keys %{ $corelist->{$old} } ) {
    if ( ! exists $corelist->{$new}{$k} ) {
      $deltaGrouping->{'removed'}->{$k} = [ $k, $corelist->{$old}{$k}, undef ];
    }
  }

  return (
    \%{ $deltaGrouping->{'new'} },
    \%{ $deltaGrouping->{'removed'} },
    \%{ $deltaGrouping->{'updated'} },
    \@manuallyCheck
  );
}

sub do_generate {
  my ($old, $new) = @_;
  my ($added, $removed, $updated, $manuallyCheck) = corelist_delta($old => $new);

  if ($manuallyCheck) {
    say "\nXXXPlease check whether the following distributions have been modified and list accordingly";
    say "\t$_" for @{$manuallyCheck};
  }

  generate_section( $titles{new},     \&added,   values %{$added} );
  generate_section( $titles{updated}, \&updated, values %{$updated} );
  generate_section( $titles{removed}, \&removed, values %{$removed} );
}

sub do_check {
  my ($in, $old, $new) = @_;

  my $delta = DeltaParser->new($in);
  my ($added, $removed, $updated) = corelist_delta($old => $new);

  for my $ck ([ 'new', $delta->new_modules, $added ],
              [ 'removed', $delta->removed_modules, $removed ],
              [ 'updated', $delta->updated_modules, $updated ] ) {
    my @delta = @{ $ck->[1] };
    my @corelist = sort { lc $a->[0] cmp lc $b->[0] } values %{ $ck->[2] };

    printf $ck->[0] . ":\n";

    require Algorithm::Diff;
    my $diff = Algorithm::Diff->new(map {
      [map { join q{ } => grep defined, @{ $_ } } @{ $_ }]
    } \@delta, \@corelist);

    while ($diff->Next) {
      next if $diff->Same;
      my $sep = '';
      if (!$diff->Items(2)) {
        printf "%d,%dd%d\n", $diff->Get(qw( Min1 Max1 Max2 ));
      } elsif(!$diff->Items(1)) {
        printf "%da%d,%d\n", $diff->Get(qw( Max1 Min2 Max2 ));
      } else {
        $sep = "---\n";
        printf "%d,%dc%d,%d\n", $diff->Get(qw( Min1 Max1 Min2 Max2 ));
      }
      print "< $_\n" for $diff->Items(1);
      print $sep;
      print "> $_\n" for $diff->Items(2);
    }

    print "\n";
  }
}

{
  package DeltaParser;
  use Pod::Simple::SimpleTree;

  sub new {
    my ($class, $input) = @_;

    my $self = bless {} => $class;

    my $parsed_pod = Pod::Simple::SimpleTree->new->parse_file($input)->root;
    splice @{ $parsed_pod }, 0, 2; # we don't care about the document structure,
                                   # just the nodes within it

    $self->_parse_delta($parsed_pod);

    return $self;
  }

  # creates the accessor methods:
  #   new_modules
  #   updated_modules
  #   removed_modules
  for my $k (keys %sections) {
    no strict 'refs';
    my $m = "${k}_modules";
    *$m = sub { $_[0]->{$m} };
  }

  sub _parse_delta {
    my ($self, $pod) = @_;

    my $new_section     = $self->_look_for_section( $pod, $sections{new} );
    my $updated_section = $self->_look_for_section( $pod, $sections{updated} );
    my $removed_section = $self->_look_for_section( $pod, $sections{removed} );

    $self->_parse_new_section($new_section);
    $self->_parse_updated_section($updated_section);
    $self->_parse_removed_section($removed_section);

    for (qw/new_modules updated_modules removed_modules/) {
      $self->{$_} =
        [ sort { lc $a->[0] cmp lc $b->[0] } @{ $self->{$_} } ];
    }

    return;
  }

  sub _parse_new_section {
    my ($self, $section) = @_;

    $self->{new_modules} = [];
    return unless $section;
    $self->{new_modules} = $self->_parse_section($section => sub {
      my ($el) = @_;

      my ($first, $second) = @{ $el }[2, 3];
      my ($ver) = $second =~ /(\d[^\s]+)\s+has\s+been/;

      return [ $first->[2], undef, $ver ];
    });

    return;
  }

  sub _parse_updated_section {
    my ($self, $section) = @_;

    $self->{updated_modules} = [];
    return unless $section;
    $self->{updated_modules} = $self->_parse_section($section => sub {
      my ($el) = @_;

      my ($first, $second) = @{ $el }[2, 3];
      my $module = $first->[2];

      # the regular expression matches the following:
      #   from VERSION_NUMBER to VERSION_NUMBER
      #   from VERSION_NUMBER to VERSION_NUMBER.
      #   from version VERSION_NUMBER to version VERSION_NUMBER.
      #   from VERSION_NUMBER to VERSION_NUMBER and MODULE from VERSION_NUMBER to VERSION_NUMBER
      #   from VERSION_NUMBER to VERSION_NUMBER, and MODULE from VERSION_NUMBER to VERSION_NUMBER
      #
      # some perldelta contain more than one module listed in an entry, this only attempts to match the
      # first module
      my ($old, $new) = $second =~
          /from\s+(?:version\s+)?(\d[^\s]+)\s+to\s+(?:version\s+)?(\d[^\s,]+?)(?=[\s,]|\.\s|\.$|$).*/s;

      warn "Unable to extract old or new version of $module from perldelta"
        if !defined $old || !defined $new;

      return [ $module, $old, $new ];
    });

    return;
  }

  sub _parse_removed_section {
    my ($self, $section) = @_;

    $self->{removed_modules} = [];
    return unless $section;
    $self->{removed_modules} = $self->_parse_section($section => sub {
      my ($el) = @_;

      my ($first, $second) = @{ $el }[2, 3];
      my ($old) = $second =~ /was\s+(\d[^\s]+?)\.?$/;

      return [ $first->[2], $old, undef ];
    });

    return;
  }

  sub _parse_section {
    my ($self, $section, $parser) = @_;

    my $items = $self->_look_down($section => sub {
      my ($el) = @_;
      return unless ref $el && $el->[0] =~ /^item-/
          && @{ $el } > 2 && ref $el->[2];
      return unless $el->[2]->[0] =~ /C|L/;

      return 1;
    });

    return [map { $parser->($_) } @{ $items }];
  }

  sub _look_down {
    my ($self, $pod, $predicate) = @_;
    my @pod = @{ $pod };

    my @l;
    while (my $el = shift @pod) {
      push @l, $el if $predicate->($el);
      if (ref $el) {
        my @el = @{ $el };
        splice @el, 0, 2;
        unshift @pod, @el if @el;
      }
    }

    return @l ? \@l : undef;
  }

  sub _look_for_section {
    my ($self, $pod, $section) = @_;

    my $level;
    $self->_look_for_range($pod,
      sub {
        my ($el) = @_;
        my ($heading) = $el->[0] =~ /^head(\d)$/;
        my $f = $heading && $el->[2] =~ /^$section/;
        $level = $heading if $f && !$level;
        return $f;
      },
      sub {
        my ($el) = @_;
        $el->[0] =~ /^head(\d)$/ && $1 <= $level;
      },
    );
  }

  sub _look_for_range {
    my ($self, $pod, $start_predicate, $stop_predicate) = @_;

    my @l;
    for my $el (@{ $pod }) {
      if (@l) {
        return \@l if $stop_predicate->($el);
      }
      else {
        next unless $start_predicate->($el);
      }
      push @l, $el;
    }

    return;
  }
}

run;
