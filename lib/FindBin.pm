# FindBin.pm
#
# Copyright (c) 1995 Graham Barr & Nick Ing-Simmons. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

=head1 NAME

FindBin - Locate directory of original perl script

=head1 SYNOPSIS

 use FindBin;
 use lib "$FindBin::Bin/../lib";

 or 

 use FindBin qw($Bin);
 use lib "$Bin/../lib";

=head1 DESCRIPTION

Locates the full path to the script bin directory to allow the use
of paths relative to the bin directory.

This allows a user to setup a directory tree for some software with
directories E<lt>rootE<gt>/bin and E<lt>rootE<gt>/lib and then the above example will allow
the use of modules in the lib directory without knowing where the software
tree is installed.

If perl is invoked using the B<-e> option or the perl script is read from
C<STDIN> then FindBin sets both C<$Bin> and C<$RealBin> to the current
directory.

=head1 EXPORTABLE VARIABLES

 $Bin         - path to bin directory from where script was invoked
 $Script      - basename of script from which perl was invoked
 $RealBin     - $Bin with all links resolved
 $RealScript  - $Script with all links resolved

=head1 KNOWN BUGS

if perl is invoked as

   perl filename

and I<filename> does not have executable rights and a program called I<filename>
exists in the users C<$ENV{PATH}> which satisfies both B<-x> and B<-T> then FindBin
assumes that it was invoked via the C<$ENV{PATH}>.

Workaround is to invoke perl as

 perl ./filename

=head1 AUTHORS

Graham Barr E<lt>F<bodg@tiuk.ti.com>E<gt>
Nick Ing-Simmons E<lt>F<nik@tiuk.ti.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 1995 Graham Barr & Nick Ing-Simmons. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 REVISION

$Revision: 1.4 $

=cut

package FindBin;
use Carp;
require 5.000;
require Exporter;
use Cwd qw(getcwd);

@EXPORT_OK = qw($Bin $Script $RealBin $RealScript $Dir $RealDir);
%EXPORT_TAGS = (ALL => [qw($Bin $Script $RealBin $RealScript $Dir $RealDir)]);
@ISA = qw(Exporter);

$VERSION = $VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

# Taken from Cwd.pm It is really getcwd with an optional
# parameter instead of '.'
#
# another way would be:
#
#sub abs_path
#{
# my $cwd = getcwd();
# chdir(shift || '.');
# my $realpath = getcwd();
# chdir($cwd);
# $realpath;
#}

sub my_abs_path
{
    my $start = shift || '.';
    my($dotdots, $cwd, @pst, @cst, $dir, @tst);

    unless (@cst = stat( $start ))
    {
	warn "stat($start): $!";
	return '';
    }
    $cwd = '';
    $dotdots = $start;
    do
    {
	$dotdots .= '/..';
	@pst = @cst;
	unless (opendir(PARENT, $dotdots))
	{
	    warn "opendir($dotdots): $!";
	    return '';
	}
	unless (@cst = stat($dotdots))
	{
	    warn "stat($dotdots): $!";
	    closedir(PARENT);
	    return '';
	}
	if ($pst[0] == $cst[0] && $pst[1] == $cst[1])
	{
	    $dir = '';
	}
	else
	{
	    do
	    {
		unless (defined ($dir = readdir(PARENT)))
	        {
		    warn "readdir($dotdots): $!";
		    closedir(PARENT);
		    return '';
		}
		$tst[0] = $pst[0]+1 unless (@tst = lstat("$dotdots/$dir"))
	    }
	    while ($dir eq '.' || $dir eq '..' || $tst[0] != $pst[0] ||
		   $tst[1] != $pst[1]);
	}
	$cwd = "$dir/$cwd";
	closedir(PARENT);
    } while ($dir);
    chop($cwd); # drop the trailing /
    $cwd;
}


BEGIN
{
 *Dir = \$Bin;
 *RealDir = \$RealBin;
 if (defined &Cwd::sys_abspath) { *abs_path = \&Cwd::sys_abspath}
 else { *abs_path = \&my_abs_path}

 if($0 eq '-e' || $0 eq '-')
  {
   # perl invoked with -e or script is on C<STDIN>

   $Script = $RealScript = $0;
   $Bin    = $RealBin    = getcwd();
  }
 else
  {
   my $script = $0;

   if ($^O eq 'VMS')
    {
     ($Bin,$Script) = VMS::Filespec::rmsexpand($0) =~ /(.*\])(.*)/;
     ($RealBin,$RealScript) = ($Bin,$Script);
    }
   else
    {
     unless($script =~ m#/# && -f $script)
      {
       my $dir;
       
       foreach $dir (split(/:/,$ENV{PATH}))
	{
	if(-x "$dir/$script")
         {
          $script = "$dir/$script";
   
	  if (-f $0) 
           {
	    # $script has been found via PATH but perl could have
	    # been invoked as 'perl file'. Do a dumb check to see
	    # if $script is a perl program, if not then $script = $0
            #
            # well we actually only check that it is an ASCII file
            # we know its executable so it is probably a script
            # of some sort.
   
            $script = $0 unless(-T $script);
           }
          last;
         }
       }
     }
  
     croak("Cannot find current script '$0'") unless(-f $script);
  
     # Ensure $script contains the complete path incase we C<chdir>
  
     $script = getcwd() . "/" . $script unless($script =~ m,^/,);
   
     ($Bin,$Script) = $script =~ m,^(.*?)/+([^/]+)$,;
  
     # Resolve $script if it is a link
     while(1)
      {
       my $linktext = readlink($script);
  
       ($RealBin,$RealScript) = $script =~ m,^(.*?)/+([^/]+)$,;
       last unless defined $linktext;
  
       $script = ($linktext =~ m,^/,)
                  ? $linktext
                  : $RealBin . "/" . $linktext;
      }

     # Get absolute paths to directories
     $Bin     = abs_path($Bin)     if($Bin);
     $RealBin = abs_path($RealBin) if($RealBin);
    }
  }
}

1; # Keep require happy

