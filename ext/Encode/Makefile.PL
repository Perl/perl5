use 5.7.2;
use strict;
use ExtUtils::MakeMaker;

my %tables = 
    (
     def_t => ['ascii.ucm',
	       '8859-1.ucm',
	       ]
     );

my @exe_files = ();
my @more_exe_files = qw(bin/enc2xs bin/piconv);

for my $arg (@ARGV){
    if ($arg eq "USE_SCRIPTS"){
	push @exe_files, @more_exe_files;
    }
}

WriteMakefile(
	      NAME		=> "Encode",
	      EXE_FILES         => \@exe_files,
	      VERSION_FROM	=> 'Encode.pm',
	      OBJECT		=> '$(O_FILES)',
	      'dist'		=> {
		  COMPRESS	=> 'gzip -9f',
		  SUFFIX	=> 'gz',
		  DIST_DEFAULT => 'all tardist',
	      },
	      MAN3PODS	=> {},
	      INC       => "-I./Encode"
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
    # Trick case-blind filesystems.
    delete $o{'encode'.$x};
    $o{'Encode'.$x} = 1;
    # Reset the variable
    $self->{'O_FILES'} = [sort keys %o];
    my @files;
    foreach my $table (keys %tables)
    {
	foreach my $ext (qw($(OBJ_EXT) .c .h _def.h .fnm))
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
    my $str  = "# Encode\$(OBJ_EXT) depends on .h and _def.h files not .c files - but all written by enc2xs\n";
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
	my $enc2xs = $self->catfile('bin', 'enc2xs');
	$str .= "$table.c : $enc2xs Makefile.PL";
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
        $str .= $^O eq 'VMS' # In VMS quote to preserve case
            ? qq{\n\t\$(PERL) $enc2xs -"Q" -"O" -o \$\@ -f $table.fnm\n\n}
            : qq{\n\t\$(PERL) $enc2xs -Q -O -o \$\@ -f $table.fnm\n\n};
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
