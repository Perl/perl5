@perl -w -Sx %0 %*
@goto end_of_perl
#!perl -w
BEGIN { push(@INC,'lib') }
use strict;
use File::Find;
use ExtUtils::Manifest qw(maniread);
my $files = maniread();
my @dead;
find(sub { 
return if -d $_;
my $name = $File::Find::name;
$name =~ s#^\./##;
 unless (exists $files->{$name})
  {
   # print "new $name\n";
   push(@dead,$name);
  } 
},'.');

foreach my $file (@dead)
 {
  chmod(0666,$file) unless -w $file;
  unlink($file) || warn "Cannot delete $file:$!";
 }

__END__
:end_of_perl
del perl.exe
del perl*.dll