package Thread;
require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(yield cond_signal cond_broadcast cond_wait async);

#
# Methods
#

#
# Exported functions
#
sub async (&) {
    return new Thread $_[0];
}

sub eval {
    return eval { shift->join; };
}

bootstrap Thread;

1;
