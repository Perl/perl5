package ExtUtils::Command;
use strict;
# use AutoLoader;
use File::Copy;
use File::Compare;
use File::Basename;
use File::Path qw(rmtree);
require Exporter;
use vars qw(@ISA @EXPORT $VERSION);
@ISA     = qw(Exporter);
@EXPORT  = qw(cp rm_f rm_rf mv cat eqtime mkpath touch test_f);
$VERSION = '1.00';

=head1 NAME

ExtUtils::Command - utilities to replace common UNIX commands in Makefiles etc.

=head1 SYNOPSYS

  perl -MExtUtils::command -e cat files... > destination
  perl -MExtUtils::command -e mv source... destination
  perl -MExtUtils::command -e cp source... destination
  perl -MExtUtils::command -e touch files...
  perl -MExtUtils::command -e rm_f file...
  perl -MExtUtils::command -e rm_rf directories...
  perl -MExtUtils::command -e mkpath directories...
  perl -MExtUtils::command -e eqtime source destination
  perl -MExtUtils::command -e chmod mode files...
  perl -MExtUtils::command -e test_f file

=head1 DESCRIPTION

The module is used in Win32 port to replace common UNIX commands.
Most commands are wrapers on generic modules File::Path and File::Basename.

=over 4

=item cat 

Concatenates all files menthion on command line to STDOUT.

=cut 

sub cat ()
{
 print while (<>);
}

=item eqtime src dst

Sets modified time of dst to that of src

=cut 

sub eqtime
{
 my ($src,$dst) = @ARGV;
 open(F,">$dst");
 close(F);
 utime((stat($src))[8,9],$dst);
}

=item rm_f files....

Removes directories - recursively (even if readonly)

=cut 

sub rm_rf
{
 rmtree([@ARGV],0,0);
}

=item rm_f files....

Removes files (even if readonly)

=cut 

sub rm_f
{
 foreach (@ARGV)
  {
   next unless -e $_;
   chmod(0777,$_);
   next if (-f $_ and unlink($_));
   die "Cannot delete $_:$!";
  }
}

=item touch files ...

Makes files exist, with current timestamp 

=cut 

sub touch
{
 while (@ARGV)
  {
   my $file = shift(@ARGV);               
   open(FILE,">>$file") || die "Cannot write $file:$!";
   close(FILE);
  }
}

=item mv source... destination

Moves source to destination.
Multiple sources are allowed if destination is an existing directory.

=cut 

sub mv
{
 my $dst = pop(@ARGV);
 if (-d $dst)
  {
   while (@ARGV)
    {
     my $src = shift(@ARGV);               
     my $leaf = basename($src);            
     move($src,"$dst/$leaf");  # fixme
    }
  }
 else
  {
   my $src = shift(@ARGV);
   move($src,$dst) || die "Cannot move $src $dst:$!";
  }
}

=item cp source... destination

Copies source to destination.
Multiple sources are allowed if destination is an existing directory.

=cut 

sub cp
{
 my $dst = pop(@ARGV);
 if (-d $dst)
  {
   while (@ARGV)
    {
     my $src = shift(@ARGV);               
     my $leaf = basename($src);            
     copy($src,"$dst/$leaf");  # fixme
    }
  }
 else
  {
   copy(shift,$dst);
  }
}

=item chmod mode files...

Sets UNIX like permissions 'mode' on all the files.

=cut 

sub chmod
{
 chmod(@ARGV) || die "Cannot chmod ".join(' ',@ARGV).":$!";
}

=item mkpath directory...

Creates directory, including any parent directories.

=cut 

sub mkpath
{
 File::Path::mkpath([@ARGV],1,0777);
}

=item test_f file

Tests if a file exists

=cut 

sub test_f
{
 exit !-f shift(@ARGV);
}

1;
__END__ 

=back

=head1 BUGS

eqtime does not work right on Win32 due to problems with utime() built-in
command.

Should probably be Auto/Self loaded.

=head1 SEE ALSO 

ExtUtils::MakeMaker, ExtUtils::MM_Unix, ExtUtils::MM_Win32

=head1 AUTHOR

Nick Ing-Simmons <F<nick@ni-s.u-net.com>>.

=cut

