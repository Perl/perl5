package TieOut;

sub TIEHANDLE {
	bless( \(my $scalar), $_[0]);
}

sub PRINT {
	my $self = shift;
	$$self .= join('', @_);
}

sub read {
	my $self = shift;
    my $out = $$self;
    $$self = '';
	return $out;
}

1;
