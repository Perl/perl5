package CPAN::Debug;
use strict;
use vars qw($VERSION);

$VERSION = sprintf "%.6f", substr(q$Rev: 561 $,4)/1000000 + 5.4;
# module is internal to CPAN.pm

%CPAN::DEBUG = qw[
                  CPAN              1
                  Index             2
                  InfoObj           4
                  Author            8
                  Distribution     16
                  Bundle           32
                  Module           64
                  CacheMgr        128
                  Complete        256
                  FTP             512
                  Shell          1024
                  Eval           2048
                  HandleConfig   4096
                  Tarzip         8192
                  Version       16384
                  Queue         32768
                  FirstTime     65536
];

$CPAN::DEBUG ||= 0;

#-> sub CPAN::Debug::debug ;
sub debug {
    my($self,$arg) = @_;
    my($caller,$func,$line,@rest) = caller(1); # caller(0) eg
                                               # Complete, caller(1)
                                               # eg readline
    ($caller) = caller(0);
    $caller =~ s/.*:://;
    $arg = "" unless defined $arg;
    pop @rest while @rest > 5;
    my $rest = join ",", map { defined $_ ? $_ : "UNDEF" } @rest;
    if ($CPAN::DEBUG{$caller} & $CPAN::DEBUG){
        if ($arg and ref $arg) {
            eval { require Data::Dumper };
            if ($@) {
                $CPAN::Frontend->myprint($arg->as_string);
            } else {
                $CPAN::Frontend->myprint(Data::Dumper::Dumper($arg));
            }
        } else {
            $CPAN::Frontend->myprint("Debug($caller:$func,$line,[$rest]): $arg\n");
        }
    }
}

1;
