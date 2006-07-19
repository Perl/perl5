#!./perl

if ( $does_gmtime = gmtime(time) ) { 
    print "1..8\n" 
}
else { 
    print "1..5\n" 
}


my $test = 1;
sub ok ($$) {
    my($ok, $name) = @_;

    # You have to do it this way or VMS will get confused.
    print $ok ? "ok $test - $name\n" : "not ok $test - $name\n";

    printf "# Failed test at line %d\n", (caller)[2] unless $ok;

    $test++;
    return $ok;
}


($beguser,$begsys) = times;

$beg = time;

while (($now = time) == $beg) { sleep 1 }

ok($now > $beg && $now - $beg < 10,             'very basic time test');

for ($i = 0; $i < 1_000_000; $i++) {
    ($nowuser, $nowsys) = times;
    $i = 2_000_000 if $nowuser > $beguser && ( $nowsys >= $begsys ||
                                            (!$nowsys && !$begsys));
    last if time - $beg > 20;
}

ok($i >= 2_000_000, 'very basic times test');

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($beg);
($xsec,$foo) = localtime($now);
$localyday = $yday;

ok($sec != $xsec && $mday && $year,             'localtime() list context');

ok(localtime() =~ /^(Sun|Mon|Tue|Wed|Thu|Fri|Sat)[ ]
                    (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[ ]
                    ([ \d]\d)\ (\d\d):(\d\d):(\d\d)\ (\d{4})$
                  /x,
   'localtime(), scalar context'
  );

# check that localtime respects changes to $ENV{TZ}
$ENV{TZ} = "GMT-5";
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($beg);
$ENV{TZ} = "GMT+5";
($sec,$min,$hour2,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($beg);
ok($hour != $hour2,                             'changes to $ENV{TZ} respected');

exit 0 unless $does_gmtime;

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($beg);
($xsec,$foo) = localtime($now);

ok($sec != $xsec && $mday && $year,             'gmtime() list context');

my $day_diff = $localyday - $yday;
ok( grep({ $day_diff == $_ } (0, 1, -1, 364, 365, -364, -365)),
                     'gmtime() and localtime() agree what day of year');


# This could be stricter.
ok(gmtime() =~ /^(Sun|Mon|Tue|Wed|Thu|Fri|Sat)[ ]
                 (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[ ]
                 ([ \d]\d)\ (\d\d):(\d\d):(\d\d)\ (\d{4})$
               /x,
   'gmtime(), scalar context'
  );
