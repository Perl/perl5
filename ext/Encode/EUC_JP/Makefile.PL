use 5.7.2;
use strict;
use ExtUtils::MakeMaker;

my %tables = (EUC_JP  => [
                'euc-jp.ucm',
#               'jis0201.enc',
#               'jis0212.enc',
#               'jis0208.enc',
#               'shiftjis.enc',
              ]);


WriteMakefile(
              INC		=> "-I..",
	      NAME		=> "Encode::EUC_JP",
	      VERSION_FROM	=> 'EUC_JP.pm',
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
    my $x = $self->{'OBJ_EXT'};
    # Add the table O_FILES
    foreach my $e (keys %tables)
    {
	$o{$e.$x} = 1;
    }
    $self->{'O_FILES'} = [sort keys %o];
    my @files;
    my %xs;
    foreach my $table (keys %tables) {
	$xs{"$table.xs"} = "$table.c";
	foreach my $ext (qw($(OBJ_EXT) .xs .c .h _def.h .fnm)) {
	    push (@files,$table.$ext);
	}
    }
    $self->{'XS_FILES'} = {%xs};
    $self->{'clean'}{'FILES'} .= join(' ',@files);
    return '';
}

sub postamble
{
    my $self = shift;
    my $dir  = $self->catdir($self->updir,'Encode');
    my $str  = "# Encode\$(OBJ_EXT) depends on .h and _def.h files not .c files - but all written by compile\n";
    $str  .= 'Encode$(OBJ_EXT) :';
    foreach my $table (keys %tables)
    {
	$str .= " $table.c";
    }
    $str .= "\n\n";
    foreach my $table (keys %tables)
    {
       $str .= "$table.c : $table.xs\n";
    }
    $str .= "\n";
    my $compile = $self->catfile($self->updir,'compile');
    foreach my $table (keys %tables)
    {
	my $numlines = 1;
	my $lengthsofar = length($str);
	my $continuator = '';
	$str .= "$table.xs : $compile Makefile.PL";
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
	$str .= "\n\t\$(PERL) $compile -o \$\@ -f $table.fnm\n\n";
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

