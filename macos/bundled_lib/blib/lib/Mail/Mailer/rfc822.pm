package Mail::Mailer::rfc822;
use vars qw(@ISA);
@ISA = qw(Mail::Mailer);

sub set_headers {
    my $self = shift;
    my $hdrs = shift;
    local($\)="";
    foreach(keys %$hdrs) {
	next unless m/^[A-Z]/;
	print $self "$_: ", join(",", $self->to_array($hdrs->{$_})), "\n";
    }
    print $self "\n";	# terminate headers
}

1;
