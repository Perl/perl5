use strict;
use warnings;

use Test::More;
use Pod::Simple::XHTML;

sub convert {
  my ($pod, $select) = @_;

  my $out = '';
  my $parser = Pod::Simple::XHTML->new;
  $parser->html_header('');
  $parser->html_footer('');
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
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is $got, $want, $name;
}

compare <<'END_POD', <<'END_HTML', [ 'DESCRIPTION/guff' ];
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
END_POD
  <h2 id="guff">guff</h2>

  <p>guff content</p>

END_HTML

done_testing;
