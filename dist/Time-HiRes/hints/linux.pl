# needs to explicitly link against librt to pull in clock_nanosleep
no strict 'vars';
$self->{LIBS} = ['-lrt'];
