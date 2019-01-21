use strict;
use warnings;
use Carp;
use Test::More tests =>  4;
use Data::Dumper; $Data::Dumper::Indent=1;
our $Level;

sub __capture {
    push @::__capture, join "", @_;
}

sub capture_warnings {
    my $code = shift;

    local @::__capture;
    local $SIG {__WARN__} = \&__capture;
    local $Level = 1;
    &$code;
    return @::__capture;
}

{
    my @warnings = capture_warnings( sub { eval { Carp::carp("foo", undef, "bar"); }; 1; } );
    my $str = join("\n" => @warnings);
    unlike($str, qr/Use of uninitialized value \$error\[1\] in join or string/s,
        "No uninitialized value warning for 'undef' arg to carp");
}

{
    my @warnings = capture_warnings( sub { eval { Carp::croak("foo", undef, "bar"); }; 1; } );
    my $str = join("\n" => @warnings);
    unlike($str, qr/Use of uninitialized value \$error\[1\] in join or string/s,
        "No uninitialized value warning for 'undef' arg to croak");
}

{
    my @warnings = capture_warnings( sub { eval { Carp::cluck("foo", undef, "bar"); }; 1; } );
    my $str = join("\n" => @warnings);
    unlike($str, qr/Use of uninitialized value \$error\[1\] in join or string/s,
        "No uninitialized value warning for 'undef' arg to cluck");
}

{
    my @warnings = capture_warnings( sub { eval { Carp::confess("foo", undef, "bar"); }; 1; } );
    my $str = join("\n" => @warnings);
    unlike($str, qr/Use of uninitialized value \$error\[1\] in join or string/s,
        "No uninitialized value warning for 'undef' arg to confess");
}

