package FilterTest;

BEGIN {
    chdir('t') if -d 't';    
    @INC = '../lib';
}

use Filter::Simple sub {
    while (my ($from, $to) = splice @_, 0, 2) {
	s/$from/$to/g;
    }
};

1;
