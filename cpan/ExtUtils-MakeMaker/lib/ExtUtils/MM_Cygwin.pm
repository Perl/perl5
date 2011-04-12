package ExtUtils::MM_Cygwin;

use strict;

use ExtUtils::MakeMaker::Config;
use File::Spec;

require ExtUtils::MM_Unix;
require ExtUtils::MM_Win32;
our @ISA = qw( ExtUtils::MM_Unix );

our $VERSION = '6.57_06';


=head1 NAME

ExtUtils::MM_Cygwin - methods to override UN*X behaviour in ExtUtils::MakeMaker

=head1 SYNOPSIS

 use ExtUtils::MM_Cygwin; # Done internally by ExtUtils::MakeMaker if needed

=head1 DESCRIPTION

See ExtUtils::MM_Unix for a documentation of the methods provided there.

=over 4

=item os_flavor

We're Unix and Cygwin.

=cut

sub os_flavor {
    return('Unix', 'Cygwin');
}

=item cflags

if configured for dynamic loading, triggers #define EXT in EXTERN.h

=cut

sub cflags {
    my($self,$libperl)=@_;
    return $self->{CFLAGS} if $self->{CFLAGS};
    return '' unless $self->needs_linking();

    my $base = $self->SUPER::cflags($libperl);
    foreach (split /\n/, $base) {
        /^(\S*)\s*=\s*(\S*)$/ and $self->{$1} = $2;
    };
    $self->{CCFLAGS} .= " -DUSEIMPORTLIB" if ($Config{useshrplib} eq 'true');

    return $self->{CFLAGS} = qq{
CCFLAGS = $self->{CCFLAGS}
OPTIMIZE = $self->{OPTIMIZE}
PERLTYPE = $self->{PERLTYPE}
};

}


=item replace_manpage_separator

replaces strings '::' with '.' in MAN*POD man page names

=cut

sub replace_manpage_separator {
    my($self, $man) = @_;
    $man =~ s{/+}{.}g;
    return $man;
}

=item init_linker

points to libperl.a

=cut

sub init_linker {
    my $self = shift;

    if ($Config{useshrplib} eq 'true') {
        my $libperl = '$(PERL_INC)' .'/'. "$Config{libperl}";
        if( $] >= 5.006002 ) {
            $libperl =~ s/a$/dll.a/;
        }
        $self->{PERL_ARCHIVE} = $libperl;
    } else {
        $self->{PERL_ARCHIVE} = 
          '$(PERL_INC)' .'/'. ("$Config{libperl}" or "libperl.a");
    }

    $self->{PERL_ARCHIVE_AFTER} ||= '';
    $self->{EXPORT_LIST}  ||= '';
}

=item maybe_command

If our path begins with F</cygdrive/> then we use C<ExtUtils::MM_Win32>
to determine if it may be a command.  Otherwise we use the tests
from C<ExtUtils::MM_Unix>.

=cut

sub maybe_command {
    my ($self, $file) = @_;

    if ($file =~ m{^/cygdrive/}i) {
        return ExtUtils::MM_Win32->maybe_command($file);
    }

    return $self->SUPER::maybe_command($file);
}

=item dynamic_lib

Use the default to produce the *.dll's.
Add the dll size to F<$vendorarch/auto/.rebase>, which stores the
next available imagebase.

If an old dll exists and .rebase is empty, use the same rebase address
for new archdir dll's.

=cut

sub dynamic_lib {
    my($self, %attribs) = @_;
    my $s = ExtUtils::MM_Unix::dynamic_lib($self, %attribs);
    return $s unless $s;
    my $ori = "$self->{INSTALLARCHLIB}/auto/$self->{FULLEXT}/$self->{BASEEXT}.$self->{DLEXT}";
    my $rebase = "$self->{INSTALLVENDORARCH}/auto/.rebase";
    my $imagebase;
    if (-f $rebase) {
      $imagebase = `/bin/cat $rebase`;
      chomp $imagebase;
    }
    if (-e $ori) {
      $imagebase = `/bin/objdump -p $ori | /bin/grep ImageBase | /bin/cut -c12-`;
      chomp $imagebase;
      if ($imagebase gt "40000000" and $imagebase lt "80000000") {
	my $LDDLFLAGS = $self->{LDDLFLAGS};
	$LDDLFLAGS =~ s/-Wl,--enable-auto-image-base/-Wl,--image-base=0x$imagebase/;
	$s =~ s/ \$\(LDDLFLAGS\) / $LDDLFLAGS /m;
      }
    } elsif ($imagebase gt "40000000" and $imagebase lt "80000000") {
      my $LDDLFLAGS = $self->{LDDLFLAGS};
      $LDDLFLAGS =~ s/-Wl,--enable-auto-image-base/-Wl,--image-base=0x$imagebase/ or
      	$LDDLFLAGS .= " -Wl,--image-base=0x$imagebase";
      $s =~ s/ \$\(LDDLFLAGS\) / $LDDLFLAGS /m;
      # Need a tempfile, because gmake expands $_ in the perl cmdline
      open F, ">", "_rebase.pl";
      print F qq(/new base = (.+), new size = (.+)/ && printf("%x\\n",hex(\$1)+hex(\$2)););
      close F;
      # TODO Here we create all DLL's per project with the same imagebase. We'd need
      # a better tool to inc the imagebase.
      $s .= "\t/bin/rebase -v -b 0x$imagebase \$@ | ";
      $s .= "\$(FULLPERL) -n _rebase.pl > \$(INSTALLVENDORARCH)/auto/.rebase\n";
    } else {
      warn "Hint: run perlrebase to initialize $rebase\n";
    }
    $s;
}

=item all_target

Build man pages, too

=cut

sub all_target {
    ExtUtils::MM_Unix::all_target(shift);
}

=back

=cut

1;
