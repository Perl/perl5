package Test2::Util::Facets2Legacy;
use strict;
use warnings;

our $VERSION = '1.302096';

use Carp qw/croak confess/;
use Scalar::Util qw/blessed/;

use base 'Exporter';
our @EXPORT_OK = qw{
    causes_fail
    diagnostics
    global
    increments_count
    no_display
    sets_plan
    subtest_id
    summary
    terminate
};
our %EXPORT_TAGS = ( ALL => \@EXPORT_OK );

our $CYCLE_DETECT = 0;
sub _get_facet_data {
    my $in = shift;

    if (blessed($in) && $in->isa('Test2::Event')) {
        confess "Cycle between Facets2Legacy and $in\->facet_data() (Did you forget to override the facet_data() method?)"
            if $CYCLE_DETECT;

        local $CYCLE_DETECT = 1;
        return $in->facet_data;
    }

    return $in if ref($in) eq 'HASH';

    croak "'$in' Does not appear to be either a Test::Event or an EventFacet hashref";
}

sub causes_fail {
    my $facet_data = _get_facet_data(shift @_);

    return 1 if $facet_data->{errors} && grep { $_->{fail} } @{$facet_data->{errors}};

    if (my $control = $facet_data->{control}) {
        return 1 if $control->{halt};
        return 1 if $control->{terminate};
    }

    return 0 if $facet_data->{amnesty} && @{$facet_data->{amnesty}};
    return 1 if $facet_data->{assert} && !$facet_data->{assert}->{pass};
    return 0;
}

sub diagnostics {
    my $facet_data = _get_facet_data(shift @_);
    return 1 if $facet_data->{errors} && @{$facet_data->{errors}};
    return 0 unless $facet_data->{info} && @{$facet_data->{info}};
    return (grep { $_->{debug} } @{$facet_data->{info}}) ? 1 : 0;
}

sub global {
    my $facet_data = _get_facet_data(shift @_);
    return 0 unless $facet_data->{control};
    return $facet_data->{control}->{global};
}

sub increments_count {
    my $facet_data = _get_facet_data(shift @_);
    return $facet_data->{assert} ? 1 : 0;
}

sub no_display {
    my $facet_data = _get_facet_data(shift @_);
    return 0 unless $facet_data->{about};
    return $facet_data->{about}->{no_display};
}

sub sets_plan {
    my $facet_data = _get_facet_data(shift @_);
    my $plan = $facet_data->{plan} or return;
    my @out = ($plan->{count} || 0);

    if ($plan->{skip}) {
        push @out => 'SKIP';
        push @out => $plan->{details} if defined $plan->{details};
    }
    elsif ($plan->{none}) {
        push @out => 'NO PLAN'
    }

    return @out;
}

sub subtest_id {
    my $facet_data = _get_facet_data(shift @_);
    return undef unless $facet_data->{parent};
    return $facet_data->{parent}->{hid};
}

sub summary {
    my $facet_data = _get_facet_data(shift @_);
    return '' unless $facet_data->{about} && $facet_data->{about}->{details};
    return $facet_data->{about}->{details};
}

sub terminate {
    my $facet_data = _get_facet_data(shift @_);
    return undef unless $facet_data->{control};
    return $facet_data->{control}->{terminate};
}

1;
