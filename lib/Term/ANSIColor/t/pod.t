#!/usr/bin/perl
# $Id: pod.t 55 2006-06-22 17:56:02Z eagle $
#
# t/pod.t -- Test POD formatting for Term::ANSIColor.

eval 'use Test::Pod 1.00';
if ($@) {
    print "1..1\n";
    print "ok 1 # skip - Test::Pod 1.00 required for testing POD\n";
    exit;
}
all_pod_files_ok ();
