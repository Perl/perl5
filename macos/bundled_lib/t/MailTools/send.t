#!/usr/local/bin/perl -w

use Mail::Send;

print "1..11\n";

my $i = 1;

$msg = new Mail::Send or print "not ";

printf "ok %d\n",$i++;

$msg = new Mail::Send
	Subject	=> 'example subject',
	To	=> 'timbo'
    or print "not ";

$msg->to('user@host') == 1 or print "not ";
printf "ok %d\n",$i++;

$msg->subject('user@host') == 1 or print "not ";
printf "ok %d\n",$i++;

$msg->cc('user@host', 'user2@no.where') == 2 or print "not ";
printf "ok %d\n",$i++;

$msg->bcc('someone@else') == 1 or print "not ";
printf "ok %d\n",$i++;

$msg->bcc('nobody@here') == 1 or print "not ";
printf "ok %d\n",$i++;

$msg->set('X-Test', 'a test entry') == 1 or print "not ";
printf "ok %d\n",$i++;

$msg->add('X-Test', 'another test entry') == 2 or print "not ";
printf "ok %d\n",$i++;

$msg->set('X-Test2', 'a test2 entry') == 1 or print "not ";
printf "ok %d\n",$i++;

$msg->set('X-Test2', 'replaced') == 1 or print "not ";
printf "ok %d\n",$i++;

$msg->delete('X-Test') or print "not ";
printf "ok %d\n",$i++;

