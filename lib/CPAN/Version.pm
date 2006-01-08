=head1 NAME

CPAN::Version - utility functions to compare CPAN versions

=head1 SYNOPSIS

  use CPAN::Version;

  CPAN::Version->vgt("1.1","1.1.1");    # 1

  CPAN::Version->vcmp("1.1","1.1.1");   # 1

  CPAN::Version->readable(v1.2.3);      # "v1.2.3"

  CPAN::Version->vstring("v1.2.3");     # v1.2.3

  CPAN::Version->float2vv(1.002003);    # "v1.2.3"

=head1 DESCRIPTION

This module mediates between some version that perl sees in a package
and the version that is published by the CPAN indexer.

It's only written as a helper module for both CPAN.pm and CPANPLUS.pm.

As it stands it predates version.pm but has the same goal: make
version strings visible and comparable.

=cut

package CPAN::Version;

use strict;
use vars qw($VERSION);
$VERSION = sprintf "%.2f", substr(q$Rev: 254 $,4)/100;

# CPAN::Version::vcmp courtesy Jost Krieger
sub vcmp {
  my($self,$l,$r) = @_;
  local($^W) = 0;
  CPAN->debug("l[$l] r[$r]") if $CPAN::DEBUG;

  return 0 if $l eq $r; # short circuit for quicker success

  for ($l,$r) {
      next unless tr/.// > 1;
      s/^v?/v/;
      1 while s/\.0+(\d)/.$1/;
  }
  if ($l=~/^v/ <=> $r=~/^v/) {
      for ($l,$r) {
          next if /^v/;
          $_ = $self->float2vv($_);
      }
  }

  return (
          ($l ne "undef") <=> ($r ne "undef") ||
          (
           $] >= 5.006 &&
           $l =~ /^v/ &&
           $r =~ /^v/ &&
           $self->vstring($l) cmp $self->vstring($r)
          ) ||
          $l <=> $r ||
          $l cmp $r
         );
}

sub vgt {
  my($self,$l,$r) = @_;
  $self->vcmp($l,$r) > 0;
}

sub vstring {
  my($self,$n) = @_;
  $n =~ s/^v// or die "CPAN::Version::vstring() called with invalid arg [$n]";
  pack "U*", split /\./, $n;
}

# vv => visible vstring
sub float2vv {
    my($self,$n) = @_;
    my($rev) = int($n);
    $rev ||= 0;
    my($mantissa) = $n =~ /\.(\d{1,12})/; # limit to 12 digits to limit
                                          # architecture influence
    $mantissa ||= 0;
    $mantissa .= "0" while length($mantissa)%3;
    my $ret = "v" . $rev;
    while ($mantissa) {
        $mantissa =~ s/(\d{1,3})// or
            die "Panic: length>0 but not a digit? mantissa[$mantissa]";
        $ret .= ".".int($1);
    }
    # warn "n[$n]ret[$ret]";
    $ret;
}

sub readable {
  my($self,$n) = @_;
  $n =~ /^([\w\-\+\.]+)/;

  return $1 if defined $1 && length($1)>0;
  # if the first user reaches version v43, he will be treated as "+".
  # We'll have to decide about a new rule here then, depending on what
  # will be the prevailing versioning behavior then.

  if ($] < 5.006) { # or whenever v-strings were introduced
    # we get them wrong anyway, whatever we do, because 5.005 will
    # have already interpreted 0.2.4 to be "0.24". So even if he
    # indexer sends us something like "v0.2.4" we compare wrongly.

    # And if they say v1.2, then the old perl takes it as "v12"

    if (defined $CPAN::Frontend) {
      $CPAN::Frontend->mywarn("Suspicious version string seen [$n]\n");
    } else {
      warn("Suspicious version string seen [$n]\n");
    }
    return $n;
  }
  my $better = sprintf "v%vd", $n;
  CPAN->debug("n[$n] better[$better]") if $CPAN::DEBUG;
  return $better;
}

1;

__END__

# Local Variables:
# mode: cperl
# cperl-indent-level: 2
# End:
