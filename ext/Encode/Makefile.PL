use ExtUtils::MakeMaker;

my %tables = (iso8859 => ['ascii.ucm', 'cp1250.ucm', 'koi8-r.ucm' ],
              EBCDIC  => ['cp1047.ucm','cp37.ucm','posix-bc.ucm'],
              Symbols => ['symbol.ucm','dingbats.ucm'],
             );

opendir(ENC,'Encode');
while (defined(my $file = readdir(ENC)))
 {
  if ($file =~ /8859.*\.ucm/)
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
 my %o;
 # Find existing O_FILES
 foreach my $f (@{$self->{'O_FILES'}})
  {
   $o{$f} = 1;
  }
 my $x = $self->{'OBJ_EXT'};
 # Add the table O_FILES
 foreach my $e (keys %tables)
  {
   $o{$e.$x} = 1;
  }
 # Reset the variable
 $self->{'O_FILES'} = [sort keys %o];
 my @files;
 foreach my $table (keys %tables)
  {
   foreach my $ext (qw($(OBJ_EXT) .c .h .def .fnm))
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
 my $str  = "# Encode\$(OBJ_EXT) depends on .h and .def files not .c files - but all written by compile\n";
 $str  .= 'Encode$(OBJ_EXT) :';
 foreach my $table (keys %tables)
  {
   $str .= " $table.c";
  }
 $str .= "\n\n";
 foreach my $table (keys %tables)
  {
   my $numlines = 1;
   my $lengthsofar = length($str);
   my $continuator = '';
   $str .= "$table.c : compile Makefile.PL";
   foreach my $file (@{$tables{$table}})
    {
     $str .= $continuator.' '.$self->catfile($dir,$file);
     if ( length($str)-$lengthsofar > 128*$numlines )
      {
       $continuator .= " \\\n\t";
       $numlines++;
      } else {
       $continuator = '';
      }
    }
   $str .= "\n\t\$(PERL) compile -o \$\@ -f $table.fnm\n\n";
   open (FILELIST, ">$table.fnm")
       || die "Could not open $table.fnm: $!";
   foreach my $file (@{$tables{$table}})
    {
     print FILELIST $self->catfile($dir,$file) . "\n";
    }
   close(FILELIST);
  }
 return $str;
}
