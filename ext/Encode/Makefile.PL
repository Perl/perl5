use ExtUtils::MakeMaker;
my @tables = qw(iso8859 EBCDIC Symbols);

WriteMakefile(
	NAME		=> "Encode",
	VERSION_FROM	=> 'Encode.pm',
	OBJECT		=> '$(O_FILES)',
	'dist'		=> {
			     COMPRESS	=> 'gzip -9f',
	      		     SUFFIX	=> 'gz',
	      		     DIST_DEFAULT => 'all tardist',
			   },
	MAN3PODS	=> {},
);

package MY;


sub post_initialize
{
 my ($self) = @_;
 push(@{$self->{'O_FILES'}},map("$_\$(OBJ_EXT)",@tables));
 $self->{'clean'}{'FILES'} .= join(' ',map("$_.*",@tables));
 return '';
}

sub clean
{
 my ($self) = @_;
 return $self->SUPER::clean . qq[
	\$(RM_F) ].join(' ',map("$_.*",@tables))."\n"
}

sub postamble
{
 return '

Encode$(OBJ_EXT) : iso8859$(OBJ_EXT) EBCDIC$(OBJ_EXT) Symbols$(OBJ_EXT)

iso8859.c : compile Makefile
	$(PERL) compile $@ Encode/ascii.enc Encode/iso8859*.enc Encode/cp1250.enc

EBCDIC.c : compile Makefile Encode/cp1047.enc Encode/cp37.enc Encode/posix-bc.enc
	$(PERL) compile $@ Encode/cp1047.enc Encode/cp37.enc Encode/posix-bc.enc

Symbols.c : compile Makefile Encode/symbol.enc Encode/dingbats.enc
	$(PERL) compile $@ Encode/symbol.enc Encode/dingbats.enc

'
}
