use 5.7.2;
use strict;
use ExtUtils::MakeMaker;

my %tables = (EUC_KR   => ['euc-kr.enc'],
	      KSC5601  => ['ksc5601.enc'],
             );

my $name = 'KR';

WriteMakefile(
              INC		=> "-I..",
	      NAME		=> 'Encode::'.$name,
	      VERSION_FROM	=> "$name.pm",
	      OBJECT		=> '$(O_FILES)',
	      'dist'		=> {
		  COMPRESS	=> 'gzip -9f',
		  SUFFIX	=> 'gz',
		  DIST_DEFAULT => 'all tardist',
	      },
	      MAN3PODS	=> {},
	      # OS 390 winges about line numbers > 64K ???
	      XSOPT => '-nolinenumbers',
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
    $o{"$name$x"} = 1;
    $self->{'O_FILES'} = [sort keys %o];
    my @files = ("$name.xs");
    $self->{'C'} = ["$name.c"];
    $self->{'H'} = [$self->catfile($self->updir,'encode.h')];
    my %xs;
    foreach my $table (keys %tables) {
	push (@{$self->{'C'}},"$table.c");
	# Do NOT add $table.h etc. to H_FILES unless we own up as to how they
	# get built.
	foreach my $ext (qw($(OBJ_EXT) .c .h _def.h .fnm)) {
	    push (@files,$table.$ext);
	}
    }
    $self->{'XS'} = { "$name.xs" => "$name.c" };
    $self->{'clean'}{'FILES'} .= join(' ',@files);
    open(XS,">$name.xs") || die "Cannot open $name.xs:$!";
    print XS <<'END';
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#define U8 U8
#include "../encode.h"
END
    foreach my $table (keys %tables) {
	print XS qq[#include "${table}.h"\n];
    }
    print XS <<"END";

static void
Encode_XSEncoding(pTHX_ encode_t *enc)
{
 dSP;
 HV *stash = gv_stashpv("Encode::XS", TRUE);
 SV *sv    = sv_bless(newRV_noinc(newSViv(PTR2IV(enc))),stash);
 int i = 0;
 PUSHMARK(sp);
 XPUSHs(sv);
 while (enc->name[i])
  {
   const char *name = enc->name[i++];
   XPUSHs(sv_2mortal(newSVpvn(name,strlen(name))));
  }
 PUTBACK;
 call_pv("Encode::define_encoding",G_DISCARD);
 SvREFCNT_dec(sv);
}

MODULE = Encode::$name	PACKAGE = Encode::$name
BOOT:
{
END
    foreach my $table (keys %tables) {
	print XS qq[#include "${table}_def.h"\n];
    }
    print XS "}\n";
    close(XS);
    return "# Built $name.xs\n\n";
}

sub postamble
{
    my $self = shift;
    my $dir  = $self->catdir($self->updir,'Encode');
    my $str  = "# $name\$(OBJ_EXT) depends on .h and _def.h files not .c files - but all written by compile\n";
    $str    .= "$name.c : $name.xs ";
    foreach my $table (keys %tables)
    {
	$str .= " $table.c";
    }
    $str .= "\n\n";
    $str .= "$name\$(OBJ_EXT) : $name.c\n\n";

    my $compile = $self->catfile($self->updir,'compile');
    foreach my $table (keys %tables)
    {
	my $numlines = 1;
	my $lengthsofar = length($str);
	my $continuator = '';
	$str .= "$table.c : $compile Makefile.PL";
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

