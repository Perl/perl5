# 
# Test the address/name extraction
#

require Mail::Address;

$/ = "";
chomp(@line = <DATA>);

print "1..",scalar(@line),"\n";

$i = 1;

foreach $ln (@line) {
 next unless($ln =~ /\S/);

 ($test,$format,$name) = (split(/\n+/,$ln));

 $q = (Mail::Address->parse($test))[0];

 $ename = $q->name || "";
 $eformat = $q->format || "";
 $name = $ename unless defined $name;
 if($ename eq $name && $eformat eq $format) {
  print "ok ",$i,"\n";
 }
 else {
  print "not ok ",$i,"\n";
  print
  print "# name '$name' != '$ename'\n" unless $ename eq $name;
  print "# format '$format' != '$eformat'\n" unless $eformat eq $format;
 }

 $i++;
}

__DATA__
"Joe & J. Harvey" <ddd @Org>, JJV @ BBN
"Joe & J. Harvey" <ddd@Org>
Joe & J. Harvey

"Joe & J. Harvey" <ddd @Org>
"Joe & J. Harvey" <ddd@Org>
Joe & J. Harvey

JJV @ BBN
JJV@BBN


"spickett@tiac.net" <Sean.Pickett@zork.tiac.net>
"spickett@tiac.net" <Sean.Pickett@zork.tiac.net>
Spickett@Tiac.Net

rls@intgp8.ih.att.com (-Schieve,R.L.) 
rls@intgp8.ih.att.com (-Schieve,R.L.)
R.L. -Schieve

bodg fred@tiuk.ti.com
bodg


m-sterni@mars.dsv.su.se 
m-sterni@mars.dsv.su.se


jrh%cup.portal.com@portal.unix.portal.com 
jrh%cup.portal.com@portal.unix.portal.com
Cup Portal Com

astrachan@austlcm.sps.mot.com ('paul astrachan/xvt3') 
astrachan@austlcm.sps.mot.com ('paul astrachan/xvt3')
Paul Astrachan/Xvt3

TWINE57%SDELVB.decnet@SNYBUFVA.CS.SNYBUF.EDU (JAMES R. TWINE - THE NERD) 
TWINE57%SDELVB.decnet@SNYBUFVA.CS.SNYBUF.EDU (JAMES R. TWINE - THE NERD)
James R. Twine - The Nerd

David Apfelbaum <da0g+@andrew.cmu.edu>
David Apfelbaum <da0g+@andrew.cmu.edu>
David Apfelbaum

"JAMES R. TWINE - THE NERD" <TWINE57%SDELVB%SNYDELVA.bitnet@CUNYVM.CUNY.EDU> 
"JAMES R. TWINE - THE NERD" <TWINE57%SDELVB%SNYDELVA.bitnet@CUNYVM.CUNY.EDU>
James R. Twine - The Nerd

bilsby@signal.dra (Fred C. M. Bilsby)
bilsby@signal.dra (Fred C. M. Bilsby)
Fred C. M. Bilsby

/G=Owen/S=Smith/O=SJ-Research/ADMD=INTERSPAN/C=GB/@mhs-relay.ac.uk
/G=Owen/S=Smith/O=SJ-Research/ADMD=INTERSPAN/C=GB/@mhs-relay.ac.uk
Owen Smith

apardon@rc1.vub.ac.be (Antoon Pardon)
apardon@rc1.vub.ac.be (Antoon Pardon)
Antoon Pardon

"Stephen Burke, Liverpool" <BURKE@vxdsya.desy.de>
"Stephen Burke, Liverpool" <BURKE@vxdsya.desy.de>
Stephen Burke

Andy Duplain <duplain@btcs.bt.co.uk>
Andy Duplain <duplain@btcs.bt.co.uk>
Andy Duplain

Gunnar Zoetl <zoetl@isa.informatik.th-darmstadt.de>
Gunnar Zoetl <zoetl@isa.informatik.th-darmstadt.de>
Gunnar Zoetl

The Newcastle Info-Server <info-admin@newcastle.ac.uk>
The Newcastle Info-Server <info-admin@newcastle.ac.uk>
The Newcastle Info-Server

wsinda@nl.tue.win.info (Dick Alstein)
wsinda@nl.tue.win.info (Dick Alstein)
Dick Alstein

mserv@rusmv1.rus.uni-stuttgart.de (RUS Mail Server)
mserv@rusmv1.rus.uni-stuttgart.de (RUS Mail Server)
Rus Mail Server

Suba.Peddada@eng.sun.com (Suba Peddada [CONTRACTOR])
Suba.Peddada@eng.sun.com (Suba Peddada [CONTRACTOR])
Suba Peddada

ftpmail-adm@info2.rus.uni-stuttgart.de
ftpmail-adm@info2.rus.uni-stuttgart.de


Paul Manser (0032 memo) <a906187@tiuk.ti.com>
Paul Manser <a906187@tiuk.ti.com> (0032 memo)
Paul Manser

"gregg (g.) woodcock" <woodcock@bnr.ca>
"gregg (g.) woodcock" <woodcock@bnr.ca>
Gregg Woodcock

Clive Bittlestone <clyvb@asic.sc.ti.com>
Clive Bittlestone <clyvb@asic.sc.ti.com>
Clive Bittlestone

Graham.Barr@tiuk.ti.com
Graham.Barr@tiuk.ti.com
Graham Barr

"Graham Bisset, UK Net Support, +44 224 728109"  <GRAHAM@dyce.wireline.slb.com.ti.com.>
"Graham Bisset, UK Net Support, +44 224 728109" <GRAHAM@dyce.wireline.slb.com.ti.com.>
Graham Bisset

a909937 (Graham Barr          (0004 bodg))
a909937 (Graham Barr          (0004 bodg))
Graham Barr

a909062@node_cb83.node_cb83 (Colin x Maytum         (0013 bro5))
a909062@node_cb83.node_cb83 (Colin x Maytum         (0013 bro5))
Colin X Maytum

a909062@node_cb83.node_cb83 (Colin Maytum         (0013 bro5))
a909062@node_cb83.node_cb83 (Colin Maytum         (0013 bro5))
Colin Maytum

fred@john (Level iii support)
fred@john (Level iii support)
Level III Support

Derek.Roskell%dero@msg.ti.com
Derek.Roskell%dero@msg.ti.com
Derek Roskell

":sysmail"@ Some-Group. Some-Org, Muhammed.(I am the greatest) Ali @(the)Vegas.WBA
":sysmail"@Some-Group.Some-Org


david d `zoo' zuhn <zoo@aggregate.com> 
david d `zoo' zuhn <zoo@aggregate.com>
David D `Zoo' Zuhn

"Christopher S. Arthur" <csa@halcyon.com> 
"Christopher S. Arthur" <csa@halcyon.com>
Christopher S. Arthur

Jeffrey A Law <law@snake.cs.utah.edu> 
Jeffrey A Law <law@snake.cs.utah.edu>
Jeffrey A Law

lidl@uunet.uu.net (Kurt J. Lidl) 
lidl@uunet.uu.net (Kurt J. Lidl)
Kurt J. Lidl

Kresten_Thorup@NeXT.COM (Kresten Krab Thorup) 
Kresten_Thorup@NeXT.COM (Kresten Krab Thorup)
Kresten Krab Thorup

hjl@nynexst.com (H.J. Lu) 
hjl@nynexst.com (H.J. Lu)
H.J. Lu

berg@POOL.Informatik.RWTH-Aachen.DE (Stephen R. van den Berg) 
berg@POOL.Informatik.RWTH-Aachen.DE (Stephen R. van den Berg)
Stephen R. Van Den Berg

@oleane.net:hugues@afp.com a!b@c.d foo!bar!foobar!root
@oleane.net:hugues@afp.com
Oleane Net:Hugues

(foo@bar.com (foobar), ned@foo.com (nedfoo) ) <kevin@goess.org>
kevin@goess.org (foo@bar.com (foobar), ned@foo.com (nedfoo) )
