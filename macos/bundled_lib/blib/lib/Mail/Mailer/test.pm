package Mail::Mailer::test;
use vars qw(@ISA);
require Mail::Mailer::rfc822;
@ISA = qw(Mail::Mailer::rfc822);

sub can_cc { 0 }

sub exec {
    my($self, $exe, $args, $to) = @_;
    exec('sh', '-c', "echo to: " . join(" ",@{$to}) . "; cat");
}

1;
