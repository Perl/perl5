package ExtUtils::MM_Win95;

use vars qw($VERSION @ISA);
$VERSION = 0.02;

require ExtUtils::MM_Win32;
@ISA = qw(ExtUtils::MM_Win32);


# a few workarounds for command.com (very basic)

sub dist_test {
    my($self) = shift;
    return q{
disttest : distdir
        cd $(DISTVNAME)
        $(ABSPERLRUN) Makefile.PL
        $(MAKE) $(PASTHRU)
        $(MAKE) test $(PASTHRU)
        cd ..
};
}

sub xs_c {
    my($self) = shift;
    return '' unless $self->needs_linking();
    '
.xs.c:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) \\
	    $(XSPROTOARG) $(XSUBPPARGS) $*.xs > $*.c
	'
}

sub xs_cpp {
    my($self) = shift;
    return '' unless $self->needs_linking();
    '
.xs.cpp:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) \\
	    $(XSPROTOARG) $(XSUBPPARGS) $*.xs > $*.cpp
	';
}

# many makes are too dumb to use xs_c then c_o
sub xs_o {
    my($self) = shift;
    return '' unless $self->needs_linking();
    '
.xs$(OBJ_EXT):
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) \\
	    $(XSPROTOARG) $(XSUBPPARGS) $*.xs > $*.c
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.c
	';
}

1;
