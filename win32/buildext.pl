use File::Find;
use File::Basename;
use Cwd;
my $here = getcwd();
my $perl = $^X;
$here =~ s,/,\\,g;
if ($perl =~ m#^\.\.#)
 {
  $perl = "$here\\$perl";
 }
my $make = shift;
my $dep  = shift;
my $dmod = -M $dep;
my $dir  = shift;
chdir($dir) || die "Cannot cd to $dir\n";
(my $ext = getcwd()) =~ s,/,\\,g;
my $no = join('|',qw(DynaLoader GDBM_File ODBM_File NDBM_File DB_File Syslog Sysv));
$no = qr/^(?:$no)$/i;
my %ext;
find(\&find_xs,'.');

foreach my $dir (sort keys %ext)
 {
  if (chdir("$ext\\$dir"))
   {
    my $mmod = -M 'Makefile';
    if (!(-f 'Makefile') || $mmod > $dmod)
     {
      print "\nRunning Makefile.PL in $dir\n";
      my $code = system($perl,"-I$here\\..\lib",'Makefile.PL','INSTALLDIRS=perl');
      warn "$code from $dir's Makefile.PL" if $code;
      $mmod = -M 'Makefile';
      if ($mmod > $dmod)
       {
        warn "Makefile $mmod > $dmod ($dep)\n";
       }
     }  
    print "\nMaking $dir\n";
    system($make);
    chdir($here) || die "Cannot cd to $here:$!";
   }
  else
   {
    warn "Cannot cd to $ext\\$dir:$!";
   }
 }

sub find_xs
{
 if (/^(.*)\.pm$/i || /^(.*)_pm.PL$/i)
  {
   my $name = $1;
   return if $name =~ $no; 
   my $dir = $File::Find::dir; 
   $dir =~ s,./,,;
   return if exists $ext{$dir};
   return unless -f "$ext/$dir/Makefile.PL";
   if ($dir =~ /$name$/i)
    {
     $ext{$dir} = $name; 
    }
  }
}