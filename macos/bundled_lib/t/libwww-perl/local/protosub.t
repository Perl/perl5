#!perl

print "1..6\n";

# This test tries to make a custom protocol implementation by
# subclassing of LWP::Protocol.


use LWP::UserAgent ();
use LWP::Protocol ();

LWP::Protocol::implementor(http => 'myhttp');

$ua = LWP::UserAgent->new;
$ua->proxy('ftp' => "http://www.sn.no/");

$req = HTTP::Request->new(GET => 'ftp://foo/');
$req->header(Cookie => "perl=cool");

$res = $ua->request($req);

print $res->as_string;

print "not " unless $res->code == 200;
print "ok 5\n";
print "not " unless $res->content eq "Howdy\n";
print "ok 6\n";
exit;


#----------------------------------
package myhttp;

BEGIN {
   @ISA=qw(LWP::Protocol);
}

sub new
{
    my $class = shift;
    print "CTOR: $class->new(@_)\n";
    my($prot) = @_;
    print "not " unless $prot eq "http";
    print "ok 1\n";
    my $self = $class->SUPER::new(@_);
    for (keys %$self) {
	my $v = $self->{$_};
	$v = "<undef>" unless defined($v);
	print "$_: $v\n";
    }
    $self;
}

sub request
{
    my $self = shift;
    print "REQUEST: $self->request(",
       join(",", (map defined($_)? $_ : "UNDEF", @_)), ")\n";

    my($request, $proxy, $arg, $size, $timeout) = @_;
    print $request->as_string;

    print "not " unless $proxy eq "http://www.sn.no/";
    print "ok 2\n";
    print "not " unless $request->url eq "ftp://foo/";
    print "ok 3\n";
    print "not " unless $request->header("cookie") eq "perl=cool";
    print "ok 4\n";

    my $res = HTTP::Response->new(200 => "OK");
    $res->content_type("text/plain");
    $res->date(time);
    $self->collect_once($arg, $res, "Howdy\n");
    $res;
}
