use ExtUtils::MakeMaker;

WriteMakefile(
    VERSION_FROM    => "lib/List/Util.pm",
    NAME            => "List::Util",
);

package MY;

BEGIN {
    use Config;
    unless (defined $Config{usedl}) {
	eval <<'__EOMM__';
sub xs_c {
    my($self) = shift;
    return '' unless $self->needs_linking();
'
.xs.c:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs > List$*.xsc && $(MV) List$*.xsc List$*.c
';
}

sub c_o {
    my($self) = shift;
    return '' unless $self->needs_linking();
'
.c$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) List$*.c
	$(MV) List$*$(OBJ_EXT) $*$(OBJ_EXT)
';
}

sub xs_o {	# many makes are too dumb to use xs_c then c_o
    my($self) = shift;
    return '' unless $self->needs_linking();
'
.xs$(OBJ_EXT):
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs > List$*.xsc && $(MV) List$*.xsc List$*.c
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) List$*.c
	$(MV) List$*$(OBJ_EXT) $*$(OBJ_EXT)
';
}

__EOMM__
    }
}
