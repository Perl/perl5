package Carp;
our $VERSION = '1.04';
# this file is an utra-lightweight stub. The first time a function is
# called, Carp::Heavy is loaded, and the real short/longmessmess_jmp
# subs are installed

# $MaxEvalLen, $Verbose
# are supposed to default to 0, but undef should be close enough

$CarpLevel = 0;
$MaxArgLen = 64;    # How much of each argument to print. 0 = all.
$MaxArgNums = 8;    # How many arguments to print. 0 = all.

require Exporter;
@ISA = ('Exporter');
@EXPORT = qw(confess croak carp);
@EXPORT_OK = qw(cluck verbose longmess shortmess);
@EXPORT_FAIL = qw(verbose);	# hook to enable verbose mode

# if the caller specifies verbose usage ("perl -MCarp=verbose script.pl")
# then the following method will be called by the Exporter which knows
# to do this thanks to @EXPORT_FAIL, above.  $_[1] will contain the word
# 'verbose'.

sub export_fail { shift; $Verbose = shift if $_[0] eq 'verbose'; @_ }

# fixed hooks for stashes to point to
sub longmess  { goto &longmess_jmp }
sub shortmess { goto &shortmess_jmp }
# these two are replaced when Carp::Heavy is loaded
sub longmess_jmp  {{ local($@, $!); require Carp::Heavy} goto &longmess_jmp}
sub shortmess_jmp {{ local($@, $!); require Carp::Heavy} goto &shortmess_jmp}

sub croak   { die  shortmess @_ }
sub confess { die  longmess  @_ }
sub carp    { warn shortmess @_ }
sub cluck   { warn longmess  @_ }

1;
