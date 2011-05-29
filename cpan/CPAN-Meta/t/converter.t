use strict;
use warnings;
use Test::More 0.88;

use CPAN::Meta;
use CPAN::Meta::Validator;
use CPAN::Meta::Converter;
use File::Spec;
use IO::Dir;
use Parse::CPAN::Meta 1.4400;

my $data_dir = IO::Dir->new( 't/data' );
my @files = sort grep { /^\w/ } $data_dir->read;

sub _spec_version { return $_[0]->{'meta-spec'}{version} || "1.0" }

#use Data::Dumper;

for my $f ( reverse sort @files ) {
  my $path = File::Spec->catfile('t','data',$f);
  my $original = Parse::CPAN::Meta->load_file( $path  );
  ok( $original, "loaded $f" );
  my $original_v = _spec_version($original);
  # UPCONVERSION
  {
    my $cmc = CPAN::Meta::Converter->new( $original );
    my $converted = $cmc->convert( version => 2 );
    is ( _spec_version($converted), 2, "up converted spec version $original_v to spec version 2");
    my $cmv = CPAN::Meta::Validator->new( $converted );
    ok ( $cmv->is_valid, "up converted META is valid" )
      or diag( "ERRORS:\n" . join( "\n", $cmv->errors )
#      . "\nMETA:\n" . Dumper($converted)
    );
  }
  # UPCONVERSION - partial
  if ( _spec_version( $original ) < 2 ) {
    my $cmc = CPAN::Meta::Converter->new( $original );
    my $converted = $cmc->convert( version => '1.4' );
    is ( _spec_version($converted), 1.4, "up converted spec version $original_v to spec version 1.4");
    my $cmv = CPAN::Meta::Validator->new( $converted );
    ok ( $cmv->is_valid, "up converted META is valid" )
      or diag( "ERRORS:\n" . join( "\n", $cmv->errors )
#      . "\nMETA:\n" . Dumper($converted)
    );
  }
  # DOWNCONVERSION - partial
  if ( _spec_version( $original ) >= 1.2 ) {
    my $cmc = CPAN::Meta::Converter->new( $original );
    my $converted = $cmc->convert( version => '1.2' );
    is ( _spec_version($converted), '1.2', "down converted spec version $original_v to spec version 1.2");
    my $cmv = CPAN::Meta::Validator->new( $converted );
    ok ( $cmv->is_valid, "down converted META is valid" )
      or diag( "ERRORS:\n" . join( "\n", $cmv->errors )
#      . "\nMETA:\n" . Dumper($converted)
    );

    if (_spec_version( $original ) == 2) {
      is_deeply(
        $converted->{build_requires},
        {
          'Test::More'      => '0.88',
          'Build::Requires' => '1.1',
          'Test::Requires'  => '1.2',
        },
        "downconversion from 2 merge test and build requirements",
      );
    }
  }
  # DOWNCONVERSION
  {
    my $cmc = CPAN::Meta::Converter->new( $original );
    my $converted = $cmc->convert( version => '1.0' );
    is ( _spec_version($converted), '1.0', "down converted spec version $original_v to spec version 1.0");
    my $cmv = CPAN::Meta::Validator->new( $converted );
    ok ( $cmv->is_valid, "down converted META is valid" )
      or diag( "ERRORS:\n" . join( "\n", $cmv->errors )
#      . "\nMETA:\n" . Dumper($converted)
    );

    unless ($original_v eq '1.0') {
      like ( $converted->{generated_by},
        qr(\Q$original->{generated_by}\E, CPAN::Meta::Converter version \S+$),
        "added converter mark to generated_by",
      );
    }
  }
}

# specific test for custom key handling
{
  my $path = File::Spec->catfile('t','data','META-1_4.yml');
  my $original = Parse::CPAN::Meta->load_file( $path  );
  ok( $original, "loaded META-1_4.yml" );
  my $cmc = CPAN::Meta::Converter->new( $original );
  my $up_converted = $cmc->convert( version => 2 );
  ok ( $up_converted->{x_whatever} && ! $up_converted->{'x-whatever'},
    "up converted 'x-' to 'x_'"
  );
  ok ( $up_converted->{x_whatelse},
    "up converted 'x_' as 'x_'"
  );
  ok ( $up_converted->{x_WhatNow} && ! $up_converted->{XWhatNow},
    "up converted 'XFoo' to 'x_Foo'"
  ) or diag join("\n", keys %$up_converted);
}

# specific test for custom key handling
{
  my $path = File::Spec->catfile('t','data','META-2.json');
  my $original = Parse::CPAN::Meta->load_file( $path  );
  ok( $original, "loaded META-2.json" );
  my $cmc = CPAN::Meta::Converter->new( $original );
  my $up_converted = $cmc->convert( version => 1.4 );
  ok ( $up_converted->{x_whatever},
    "down converted 'x_' as 'x_'"
  );
}

# specific test for upconverting resources
{
  my $path = File::Spec->catfile('t','data','resources.yml');
  my $original = Parse::CPAN::Meta->load_file( $path  );
  ok( $original, "loaded resources.yml" );
  my $cmc = CPAN::Meta::Converter->new( $original );
  my $converted = $cmc->convert( version => 2 );
  is_deeply(
    $converted->{resources},
    { x_MailingList => 'http://groups.google.com/group/www-mechanize-users',
      x_Repository  => 'http://code.google.com/p/www-mechanize/source',
      homepage      => 'http://code.google.com/p/www-mechanize/',
      bugtracker    => {web => 'http://code.google.com/p/www-mechanize/issues/list',},
      license       => ['http://dev.perl.org/licenses/'],
    },
    "upconversion of resources"
  );
}

done_testing;

