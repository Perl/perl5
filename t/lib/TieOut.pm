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
	return substr($$self, 0, length($$self), '');
}

1;
