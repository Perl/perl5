use ExtUtils::MakeMaker;

my %tables = (iso8859 => ['ascii.enc', 'cp1250.enc'],
              EBCDIC  => ['cp1047.enc','cp37.enc','posix-bc.enc'],
              Symbols => ['symbol.enc','dingbats.enc'],
             );

opendir(ENC,'Encode');
while (defined(my $file = readdir(ENC)))
 {
  if ($file =~ /iso8859.*\.enc/)
   {
    push(@{$tables{iso8859}},$file);
   }
 }
closedir(ENC);


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
 push(@{$self->{'O_FILES'}},map("$_\$(OBJ_EXT)",keys %tables));
 my @files;
 foreach my $table (keys %tables)
  {
   foreach my $ext (qw($(OBJ_EXT) .c .h .def))
    {
     push (@files,$table.$ext);
    }
  }
 $self->{'clean'}{'FILES'} .= join(' ',@files);
 return '';
}

sub postamble
{
 my $self = shift;
 my $dir  = $self->catdir($self->curdir,'Encode');
 my $str  = "# Encode$(OBJ_EXT) depends on .h and .def files not .c files - but all written by compile\n";
 $str  .= 'Encode$(OBJ_EXT) :';
 my @rules;
 foreach my $table (keys %tables)
  {
   $str .= " $table.c";
  }
 $str .= "\n\n";
 foreach my $table (keys %tables)
  {
   $str .= "$table.c : compile \$(MAKEFILE)";
   foreach my $file (@{$tables{$table}})
    {
     $str .= ' '.$self->catfile($dir,$file);
    }
   $str .= "\n\t\$(PERL) compile \$\@";
   foreach my $file (@{$tables{$table}})
    {
     $str .= ' '.$self->catfile($dir,$file);
    }
   $str .= "\n\n";
  }
 return $str;
}
