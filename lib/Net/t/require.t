
print "1..9\n";
my $i = 1;
eval { require Net::Config; } || print "not "; print "ok ",$i++,"\n";
eval { require Net::Domain; } || print "not "; print "ok ",$i++,"\n";
eval { require Net::Cmd; }    || print "not "; print "ok ",$i++,"\n";
eval { require Net::Netrc; }  || print "not "; print "ok ",$i++,"\n";
eval { require Net::FTP; }    || print "not "; print "ok ",$i++,"\n";
eval { require Net::SMTP; }   || print "not "; print "ok ",$i++,"\n";
eval { require Net::NNTP; }   || print "not "; print "ok ",$i++,"\n";
eval { require Net::POP3; }   || print "not "; print "ok ",$i++,"\n";
eval { require Net::Time; }   || print "not "; print "ok ",$i++,"\n";


