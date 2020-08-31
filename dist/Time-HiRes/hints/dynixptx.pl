# uname -v
# V4.5.2
# needs to explicitly link against libc to pull in usleep
no strict 'vars';
$self->{LIBS} = ['-lc'];

