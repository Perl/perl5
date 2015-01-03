package Test::Stream::Block;
use strict;
use warnings;

use Scalar::Util qw/blessed reftype/;
use Test::Stream::Carp qw/confess carp/;

use Test::Stream::ArrayBase(
    accessors => [qw/name coderef params caller deduced _start_line _end_line/],
);

our %SUB_MAPS;

sub PACKAGE() { 0 };
sub FILE()    { 1 };
sub LINE()    { 2 };
sub SUBNAME() { 3 };

sub init {
    my $self = shift;

    confess "coderef is a mandatory field for " . blessed($self) . " instances"
        unless $self->[CODEREF];

    confess "caller is a mandatory field for " . blessed($self) . " instances"
        unless $self->[CALLER];

    confess "coderef must be a code reference"
        unless ref($self->[CODEREF]) && reftype($self->[CODEREF]) eq 'CODE';

    $self->deduce;

    $self->[PARAMS] ||= {};
}

sub deduce {
    my $self = shift;

    eval { require B; 1 } || return;

    my $code    = $self->[CODEREF];
    my $cobj    = B::svref_2object($code);
    my $pkg     = $cobj->GV->STASH->NAME;
    my $file    = $cobj->FILE;
    my $line    = $cobj->START->line;
    my $subname = $cobj->GV->NAME;

    $SUB_MAPS{$file}->{$line} = $self->[NAME];

    $self->[DEDUCED] = [$pkg, $file, $line, $subname];
    $self->[NAME] ||= $subname;
}

sub merge_params {
    my $self = shift;
    my ($new) = @_;
    my $old = $self->[PARAMS];

    # Use existing ref, merge in new ones, but old ones are kept since the
    # block can override the workflow.
    %$old = ( %$new, %$old );
}

sub package { $_[0]->[DEDUCED]->[PACKAGE] }
sub file    { $_[0]->[DEDUCED]->[FILE]    }
sub subname { $_[0]->[DEDUCED]->[SUBNAME] }

sub run {
    my $self = shift;
    my @args = @_;

    $self->[CODEREF]->(@args);
}

sub detail {
    my $self = shift;

    my $name = $self->[NAME];
    my $file = $self->file;

    my $start = $self->start_line;
    my $end   = $self->end_line;

    my $lines;
    if ($end && $end != $start) {
        $lines = "lines $start -> $end";
    }
    elsif ($end) {
        $lines = "line $start";
    }
    else {
        my ($dpkg, $dfile, $dline) = @{$self->caller};
        $lines = "line $start (declared in $dfile line $dline)";
    }

    my $known = "";
    if ($self->[DEDUCED]->[SUBNAME] ne '__ANON__') {
        $known = " (" . $self->[DEDUCED]->[SUBNAME] . ")";
    }

    return "${name}${known} in ${file} ${lines}";
}

sub start_line {
    my $self = shift;
    return $self->[_START_LINE] if $self->[_START_LINE];

    my $start = $self->[DEDUCED]->[LINE];
    my $end   = $self->end_line || 0;

    if ($start == $end || $start == 1) {
        $self->[_START_LINE] = $start;
    }
    else {
        $self->[_START_LINE] = $start - 1;
    }

    return $self->[_START_LINE];
}

sub end_line {
    my $self = shift;
    return $self->[_END_LINE] if $self->[_END_LINE];

    my $call = $self->[CALLER];
    my $dedu = $self->[DEDUCED];

    _map_package_file($dedu->[PACKAGE], $dedu->[FILE]);

    # Check if caller and deduced seem to be from the same place.
    my $match = $call->[PACKAGE] eq $dedu->[PACKAGE];
    $match &&= $call->[FILE] eq $dedu->[FILE];
    $match &&= $call->[LINE] >= $dedu->[LINE];
    $match &&= !_check_interrupt($dedu->[FILE], $dedu->[LINE], $call->[LINE]);

    if ($match) {
        $self->[_END_LINE] = $call->[LINE];
        return $call->[LINE];
    }

    # Uhg, see if we can figure it out.
    my @lines = sort { $a <=> $b } keys %{$SUB_MAPS{$dedu->[FILE]}};
    for my $line (@lines) {
        next if $line <= $dedu->[LINE];
        $self->[_END_LINE] = $line;
        $self->[_END_LINE] -= 2 unless $SUB_MAPS{$dedu->[FILE]}->{$line} eq '__EOF__';
        return $self->[_END_LINE];
    }

    return undef;
}

sub _check_interrupt {
    my ($file, $start, $end) = @_;
    return 0 if $start == $end;

    my @lines = sort { $a <=> $b } keys %{$SUB_MAPS{$file}};

    for my $line (@lines) {
        next if $line <= $start;
        return $line <= $end;
    }

    return 0;
}

my %MAPPED;
sub _map_package_file {
    my ($pkg, $file) = @_;

    return if $MAPPED{$pkg}->{$file}++;

    require B;

    my %seen;
    my @symbols = do { no strict 'refs'; %{"$pkg\::"} };
    for my $sym (@symbols) {
        my $code = $pkg->can($sym) || next;
        next if $seen{$code}++;

        my $cobj = B::svref_2object($code);

        # Skip imported subs
        my $pname = $cobj->GV->STASH->NAME;
        next unless $pname eq $pkg;

        my $f = $cobj->FILE;
        next unless $f eq $file;

        # Skip XS/C Files
        next if $file =~ m/\.c$/;
        next if $file =~ m/\.xs$/;

        my $line = $cobj->START->line;
        $SUB_MAPS{$file}->{$line} ||= $sym;
    }

    if (open(my $fh, '<', $file)) {
        my $length = () = <$fh>;
        close($fh);
        $SUB_MAPS{$file}->{$length} = '__EOF__';
    }
}

1;
