use Config;
use IPC::Open3 1.0103 qw(open3);
use Test::More tests => 4;

sub runperl {
    my(%args) = @_;
    my($w, $r);

    local $ENV{PERL5LIB} = join ($Config::Config{path_sep}, @INC);

    my $pid = open3($w, $r, undef, $^X, "-e", $args{prog});
    close $w;
    my $output = "";
    while(<$r>) { $output .= $_; }
    waitpid($pid, 0);
    return $output;
}


# Make sure we don’t try to load modules on demand in the presence of over-
# loaded args.  If there has been a syntax error, they won’t load.
like(
    runperl(
        prog => q<
          use Carp;
          sub foom {
              Carp::confess("Looks lark we got a error: $_[0]")
          }
          BEGIN {
              *{"o::()"} = sub {};
              *{'o::(""'} = sub {"hay"};
              $o::OVERLOAD{dummy}++; # perls before 5.18 need this
              *{"CODE::()"} = sub {};
              $SIG{__DIE__} = sub { foom (@_, bless([], o), sub {}) }
          }
        $a +
        >,
    ),
    qr 'Looks lark.*o=ARRAY.* CODE's,
   'Carp does not try to load modules on demand for overloaded args',
);

# Run the test also in the presence of
#  a) A UNIVERSAL::can module
#  b) A UNIVERSAL::isa module
#  c) Both
# since they follow slightly different code paths on old pre-5.10.1 perls.
my $prog = q<
          use Carp;
          sub foom {
              Carp::confess("Looks lark we got a error: $_[0]")
          }
          BEGIN {
              *{"o::()"} = sub {};
              *{'o::(""'} = sub {"hay"};
              $o::OVERLOAD{dummy}++; # perls before 5.18 need this
              *{"CODE::()"} = sub {};
              $SIG{__DIE__} = sub { foom (@_, bless([], o), sub{}) }
          }
        $a +
>;
for (
 ["UNIVERSAL::isa", 'BEGIN { $UNIVERSAL::isa::VERSION = 1 }'],
 ["UNIVERSAL::can", 'BEGIN { $UNIVERSAL::can::VERSION = 1 }'],
 ["UNIVERSAL::can/isa", 'BEGIN { $UNIVERSAL::can::VERSION =
                                 $UNIVERSAL::isa::VERSION = 1 }'],
) {
    my ($tn, $preamble) = @$_;
    like(runperl( prog => "$preamble$prog" ),
         qr 'Looks lark.*o=ARRAY.* CODE's,
        "StrVal fallback in the presence of $tn",
    )
}
