# needs to explicitly link against librt to pull in nanosleep
no strict 'vars';
$self->{LIBS} = ['-lrt'];

