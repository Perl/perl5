use strict;
use warnings;
use Test::More;
use Pod::Simple::JustPod;

sub convert {
  my ($pod, $select) = @_;

  my $out = '';
  my $parser = Pod::Simple::JustPod->new;
  $parser->output_string(\$out);
  $parser->set_heading_select(@$select);

  $parser->parse_string_document($pod);
  return $out;
}

sub compare {
  my ($in, $want, $select, $name) = @_;
  for my $pod ($in, $want) {
    if ($pod =~ /\A([\t ]+)/) {
      my $prefix = $1;
      $pod =~ s{^$prefix}{}gm;
    }
  }
  my $got = convert($in, $select);
  $got =~ s/\A=pod\n\n//;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is $got, $want, $name;
}

compare <<'END_IN_POD', <<'END_OUT_POD', [ 'DESCRIPTION/guff' ];
  =head1 NAME

  NAME content

  =head2 welp

  welp content

  =head3 hork

  hork content

  =head1 DESCRIPTION

  DESCRIPTION content

  =head2 guff

  guff content

  =cut
END_IN_POD
  =head2 guff

  guff content

  =cut
END_OUT_POD

done_testing;
