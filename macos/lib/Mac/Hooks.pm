=head1 NAME

Hooks.pm - Allow simple overrides of member functions

=head1 SYNOPSIS

	$obj->sethook("xxx", \&proc);
	$proc = $obj->gethook("xxx");
	$obj->callhook("xxx", $y, $z);

=head1 DESCRIPTION

To make it possible to override member functions without having to introduce a
subclass, functions check for the existence of a hook procedure to substitute.
C<callhook> calls the substitute and returns undef if there was none.

=cut
	
package Mac::Hooks;

sub sethook {
	my($my,$hook,$proc) = @_;
	if ($proc) {
		$my->{$hook} = $proc;
	} else {
		delete $my->{$hook};
	}
}
sub gethook {
	my($my,$hook) = @_;
	
	$my->{$hook};
}
sub callhook {
	my($my)   = shift @_;
	my($hook) = shift @_;
	if ($hook = $my->{$hook}) {
		$hook = &$hook(@_);
		$hook = undef unless defined ($hook);
	}
	$hook;
}

1;
