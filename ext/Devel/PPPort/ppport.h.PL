my $pmfile = 'PPPort.pm';
package Devel::PPPort; 
sub bootstrap {}; 
require qq[$pmfile]; 
WriteFile(qq[ppport.h]);
