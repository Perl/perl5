package Mail::Mailer::smtp;
use vars qw(@ISA);
use Net::SMTP;
use Mail::Util qw(mailaddress);

require Mail::Mailer::rfc822;
@ISA = qw(Mail::Mailer::rfc822);

sub can_cc { 0 }

sub exec {
    my($self, $exe, $args, $to) = @_;
    my %opt = @$args;
    my $host = $opt{'Server'} || undef;
    # for Net::SMTP we do not really exec
    my $smtp = Net::SMTP->new($host, Debug => 0)
	or return undef;

    ${*$self}{'sock'} = $smtp;

    $smtp->mail(mailaddress());
    my $u;
    foreach $u (@$to) {
	$smtp->to($u);
    }
    $smtp->data;
    untie(*$self) if tied *$self;
    tie *$self, 'Mail::Mailer::smtp::pipe',$self;
    $self;
}

sub set_headers {
    my($self,$hdrs) = @_;
    $self->SUPER::set_headers({
	From => "<" . mailaddress() . ">",
	%$hdrs,
	'X-Mailer' => "Mail::Mailer[v$Mail::Mailer::VERSION] Net::SMTP[v$Net::SMTP::VERSION]"
    })
}

sub epilogue {
    my $self = shift;
    my $sock = ${*$self}{'sock'};
    $sock->dataend;
    $sock->quit;
    delete ${*$self}{'sock'};
    untie(*$self);
}

sub close {
    my($self, @to) = @_;
    my $sock = ${*$self}{'sock'};
    if ($sock && fileno($sock)) {
        $self->epilogue;
	close($sock);
    }
}

package Mail::Mailer::smtp::pipe;

sub TIEHANDLE {
    my $pkg = shift;
    my $self = shift;
    my $sock = ${*$self}{'sock'};
    return bless \$sock;
}

sub PRINT {
    my $self = shift;
    my $sock = $$self;
    $sock->datasend( @_ );
}


1;
