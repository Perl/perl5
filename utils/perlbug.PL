#!/usr/local/bin/perl

use Config;
use File::Basename qw(&basename &dirname);

# List explicitly here the variables you want Configure to
# generate.  Metaconfig only looks for shell variables, so you
# have to mention them as if they were shell variables, not
# %Config entries.  Thus you write
#  $startperl
# to ensure Configure will look for $Config{startperl}.

# This forces PL files to create target in same directory as PL file.
# This is so that make depend always knows where to find PL derivatives.
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
	if ($Config{'osname'} eq 'VMS' or
	    $Config{'osname'} eq 'OS2');  # "case-forgiving"

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

# In this section, perl variables will be expanded during extraction.
# You can use $Config{...} to use Configure variables.

print OUT <<"!GROK!THIS!";
$Config{'startperl'}
    eval 'exec perl -S \$0 "\$@"'
	if 0;
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';

use Config;
use Mail::Send;
use Mail::Util;
use Getopt::Std;

use strict;

sub paraprint;

my($Version) = "1.06";

my( $file, $cc, $address, $perlbug, $testaddress, $filename,
    $subject, $from, $verbose, $ed, 
    $fh, $me, $Is_VMS, $msg, $body, $andcc );

Init();

if($::opt_h) { Help(); exit; }

Query();
Edit();
NowWhat();
Send();

exit;

sub Init {
 
	# -------- Setup --------

	$Is_VMS = $::Config{'osname'} eq 'VMS';

	getopts("hva:s:b:f:r:e:SCc:t");
	

	# This comment is needed to notify metaconfig that we are
	# using the $perladmin, $cf_by, and $cf_time definitions.


	# -------- Configuration ---------
	
	# perlbug address
	$perlbug = 'perlbug@perl.com';
	
	# Test address
	$testaddress = 'perlbug-test@perl.com';
	
	# Target address
	$address = $::opt_a || ($::opt_t ? $testaddress : $perlbug);

	# Possible administrator addresses, in order of confidence
	# (Note that cf_email is not mentioned to metaconfig, since
	# we don't really want it. We'll just take it if we have to.)
	$cc = ($::opt_C ? "" : (
		$::opt_c || $::Config{perladmin} || $::Config{cf_email} || $::Config{cf_by}
		));
	
	# Users address, used in message and in Reply-To header
	$from = $::opt_r || "";

	# Include verbose configuration information
	$verbose = $::opt_v || 0;

	# Subject of bug-report message
	$subject = $::opt_s || "";

	# File to send as report
	$file = $::opt_f || "";

	# Body of report
	$body = $::opt_b || "";

	# Editor
	$ed = ($::opt_f ? "file" : (
			$::opt_e || $ENV{VISUAL} || $ENV{EDITOR} || $ENV{EDIT} || 
		      ($Is_VMS ? "edit/tpu" : "vi")
	      ));
      
	# My username
	$me = getpwuid($<);

}


sub Query {

	# Explain what perlbug is
	
	paraprint <<EOF;
This program allows you to enter a bug report,
which will be sent as an e-mail message to $address
once you have filled in the report.

EOF


	# Prompt for subject of message, if needed
	if(! $subject) {
		paraprint <<EOF;
First of all, please provide a subject for the 
message. It should be concise description of the bug, 
if at all possible.

EOF
		print "Subject: ";
	
		$subject = <>;
		chop $subject;
	
		my($err)=0;
		while( $subject =~ /^\s*$/ ) {
			print "\nPlease enter a subject: ";
			$subject = <>;
			chop $subject;
			if($err++>5) {
				die "Aborting.\n";
			}
		}
	}
	

	# Prompt for return address, if needed
	if( !$from) {

		# Try and guess return address
		my($domain) = Mail::Util::maildomain();
	    
	    my($guess);
	                     
	        if( !$domain) {
	        	$guess = "";
	        } elsif ($Is_VMS && !$::Config{'d_has_sockets'}) { 
	        	$guess = "$domain$me";
	        } else {
		    $guess = "$me\@$domain" if $domain;
		    $guess = "$me\@unknown.addresss" unless $domain;
			}
	
		if( $guess ) {
			paraprint <<EOF;


Your e-mail address will be useful if you need to be contacted.
If the default is not your proper address, please correct it here.

EOF
		} else {
			paraprint <<EOF;

So that you may be contacted if necessary, please enter 
your e-mail address here.

EOF
		}
		print "Your address [$guess]: ";
	
		$from = <>;
		chop $from;
	
		if($from eq "") { $from = $guess }
	
	}
	
	#if( $from =~ /^(.*)\@(.*)$/ ) {
	#	$mailname = $1;
	#	$maildomain = $2;
	#}

	if( $from eq $cc or $me eq $cc ) {
		# Try not to copy ourselves
		$cc = "none";
	}


	# Prompt for administrator address, unless an override was given
	if( !$::opt_C and !$::opt_c ) {
		paraprint <<EOF;


A copy of this report can be sent to your local
perl administrator. If the address is wrong, please 
correct it, or enter 'none' to not send a copy.

EOF

		print "Local perl administrator [$cc]: ";
	
		my($entry) = scalar(<>);
		chop $entry;
	
		if($entry ne "") {
			$cc = $entry;
			if($me eq $cc) { $cc = "" }
		}
	
	}

	if($cc eq "none") { $cc = "" }

	$andcc = " and $cc" if $cc;


	# Prompt for editor, if no override is given
	if(! $::opt_e and ! $::opt_f and ! $::opt_b) {
		paraprint <<EOF;


Now you need to enter the bug report. Try to make
the report concise but descriptive. Include any 
relevant detail. Some information about your local
perl configuration will automatically be included 
at the end of the report. 

You will probably want to use an editor to enter
the report. If "$ed" is the editor you want
to use, then just press Enter, otherwise type in
the name of the editor you would like to use.

If you would like to use a prepared file, just enter
"file", and you will be asked for the filename.

EOF

		print "Editor [$ed]: ";
	
		my($entry) =scalar(<>);
		chop $entry;
	
		if($entry ne "") {
			$ed = $entry;
		} 
	}


	# Generate scratch file to edit report in
	
	$filename = ($Is_VMS ? 'sys$scratch:' : '/tmp/') . "bugrep0$$";
	$filename++ while -e $filename;
	
	
	# Prompt for file to read report from, if needed
	
	if( $ed eq "file" and ! $file) {
		paraprint <<EOF;


What is the name of the file that contains your report?

EOF

		print "Filename: ";
	
		my($entry) = scalar(<>);
		chop($entry);

		if(!-f $entry or !-r $entry) {
			print "\n\nUnable to read `$entry'.\nExiting.\n";
			exit;
		}
		$file = $entry;

	}


	# Generate report

	open(REP,">$filename");

	print REP <<EOF;
This is a bug report for perl from $from,
generated with the help of perlbug $Version running under perl $].

EOF

	if($body) {
		print REP $body;
	} elsif($file) {
		open(F,"<$file") or die "Unable to read report file: $!\n";
		while(<F>) {
		print REP $_
		}
		close(F);
	} else {
		print REP "[Please enter your report here]\n";
	}

	print REP <<EOF;



Site configuration information for perl $]:

EOF

	if( $::Config{cf_by} and $::Config{cf_time}) {
		print REP "Configured by $::Config{cf_by} at $::Config{cf_time}.\n\n";
	}

	print REP Config::myconfig;

	if($verbose) {
		print REP "\nComplete configuration data for perl $]:\n\n";
		my($value);
		foreach (sort keys %::Config) {
			$value = $::Config{$_};
			$value =~ s/'/\\'/g;
			print REP "$_='$value'\n";
		}
	}

	close(REP);
}

sub Edit {
	# Edit the report
	
	if(!$file and !$body) {
		if( system("$ed $filename") ) {
			print "\nUnabled to run editor!\n";
		} 
	}
}

sub NowWhat {

	# Report is done, prompt for further action
	if( !$::opt_S ) {
		while(1) {

			paraprint <<EOF;


Now that you have completed your report, would you like to send 
the message to $address$andcc, display the message on 
the screen, re-edit it, or cancel without sending anything?
You may also save the message as a file to mail at another time.

EOF

			print "Action (Send/Display/Edit/Cancel/File): ";
			my($action) = scalar(<>);
			chop $action;

			if($action =~ /^s/i) { # Send
				# Send the message
				last;
			} elsif($action =~ /^f/i) { # File
				print "\n\nName of file to save message in [perlbug.rep]: ";
				my($file) = scalar(<>);
				chop $file;
				if($file eq "") { $file = "perlbug.rep" }
			
				open(FILE,">$file");
				open(REP,"<$filename");
				print FILE "To: $address\nSubject: $subject\n";
				print FILE "Cc: $cc\n" if $cc;
				print FILE "Reply-To: $from\n" if $from;
				print FILE "\n";
				while(<REP>) { print FILE }
				close(REP);
				close(FILE);
	
				print "\nMessage saved in `$file'.\n";
				exit;

			} elsif($action =~ /^[drl]/i) { # Display, Redisplay, List
				# Display the message
				open(REP,"<$filename");
				while(<REP>) { print $_ }
				close(REP);
			} elsif($action =~ /^e/i) { # Edit
				# edit the message
				system("$ed $filename");
			} elsif($action =~ /^[qc]/i) { # Cancel, Quit
				1 while unlink($filename);  # remove all versions under VMS
				print "\nCancelling.\n";
				exit(0);
			}
		
		}
	}
}


sub Send {

	# Message has been accepted for transmission -- Send the message

	$msg = new Mail::Send Subject => $subject, To => $address;
	
	$msg->cc($cc) if $cc;
	$msg->add("Reply-To",$from) if $from;
	    
	$fh = $msg->open;
	
	open(REP,"<$filename");
	while(<REP>) { print $fh $_ }
	close(REP);
	
	$fh->close;  
	
	print "\nMessage sent.\n";

	1 while unlink($filename);  # remove all versions under VMS

}

sub Help {
	print <<EOF; 

A program to help generate bug reports about perl5, and mail them. 
It is designed to be used interactively. Normally no arguments will
be needed.
	
Usage:
$0  [-v] [-a address] [-s subject] [-b body | -f file ]
    [-r returnaddress] [-e editor] [-c adminaddress | -C] [-S] [-t]
    
Simplest usage:  execute "$0", and follow the prompts.

Options:

  -v    Include Verbose configuration data in the report
  -f    File containing the body of the report. Use this to 
        quickly send a prepared message.
  -S    Send without asking for confirmation.
  -a    Address to send the report to. Defaults to `$address'.
  -c    Address to send copy of report to. Defaults to `$cc'.
  -C    Don't send copy to administrator.
  -s    Subject to include with the message. You will be prompted 
        if you don't supply one on the command line.
  -b    Body of the report. If not included on the command line, or
        in a file with -f, you will get a chance to edit the message.
  -r    Your return address. The program will ask you to confirm
        this if you don't give it here.
  -e    Editor to use. 
  -t    Test mode. The target address defaults to `$testaddress'.
  
EOF
}

sub paraprint {
    my @paragraphs = split /\n{2,}/, "@_";
    print "\n";
    for (@paragraphs) {   # implicit local $_
    	s/(\S)\s*\n/$1 /g;
	    write;
	    print "\n";
    }
                       
}
                            

format STDOUT =
^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ~~
$_
.
!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
