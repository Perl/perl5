package Mail::Mailer::qmail;
use vars qw(@ISA);
require Mail::Mailer::rfc822;
@ISA = qw(Mail::Mailer::rfc822);

sub exec {
    my($self, $exe, $args, $to) = @_;
    exec(( $exe ));
}
