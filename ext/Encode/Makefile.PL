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
   $numlines = 1;
   $lengthsofar = length($str);
   $continuator = '';
   $str .= "\n\t\$(PERL) compile \$\@";
   foreach my $file (@{$tables{$table}})
    {
     $str .= $continuator.' '.$self->catfile($dir,$file);
     if ( length($str)-$lengthsofar > 128*$numlines )
      {
       $continuator .= "\n\t\$(PERL) compile \$\@";
       $numlines++;
      } else {
       $continuator = '';
      }
    }
   $str .= "\n\n";
  }
 return $str;
}
