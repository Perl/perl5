# See dl_aix.xs for details.
use Config;
if ($Config{libs} =~ /-lC/ && -f '/lib/libC.a') {
    $self->{CCFLAGS} = $Config{ccflags} . ' -DUSE_xlC';
    if (-f '/usr/ibmcxx/include/load.h') {
	$self->{CCFLAGS} .= ' -I/usr/ibmcxx/include';
    } elsif (-f '/usr/lpp/xlC/include/load.h') {
	$self->{CCFLAGS} .= ' -I/usr/lpp/xlC/include';
    } else {
	# Hoping that <load.h> will be found somehow.
    }
}
