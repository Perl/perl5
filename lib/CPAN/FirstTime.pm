# -*- Mode: cperl; coding: utf-8; cperl-indent-level: 4 -*-
package CPAN::Mirrored::By;
use strict;
use vars qw($VERSION);
$VERSION = sprintf "%.6f", substr(q$Rev: 742 $,4)/1000000 + 5.4;

sub new { 
    my($self,@arg) = @_;
    bless [@arg], $self;
}
sub continent { shift->[0] }
sub country { shift->[1] }
sub url { shift->[2] }

package CPAN::FirstTime;

use strict;
use ExtUtils::MakeMaker ();
use FileHandle ();
use File::Basename ();
use File::Path ();
use File::Spec;
use vars qw($VERSION);
$VERSION = sprintf "%.6f", substr(q$Rev: 742 $,4)/1000000 + 5.4;

=head1 NAME

CPAN::FirstTime - Utility for CPAN::Config file Initialization

=head1 SYNOPSIS

CPAN::FirstTime::init()

=head1 DESCRIPTION

The init routine asks a few questions and writes a CPAN/Config.pm or
CPAN/MyConfig.pm file (depending on what it is currently using).


=cut

use vars qw( %prompts );

sub init {
    my($configpm, %args) = @_;
    use Config;
    # extra arg in 'o conf init make' selects only $item =~ /make/
    my $matcher = $args{args} && @{$args{args}} ? $args{args}[0] : '';
    CPAN->debug("matcher[$matcher]") if $CPAN::DEBUG;

    unless ($CPAN::VERSION) {
	require CPAN::Nox;
    }
    require CPAN::HandleConfig;
    CPAN::HandleConfig::require_myconfig_or_config();
    $CPAN::Config ||= {};
    local($/) = "\n";
    local($\) = "";
    local($|) = 1;

    my($ans,$default);

    #
    # Files, directories
    #

    print $prompts{manual_config};

    my $manual_conf;

    local *_real_prompt = \&ExtUtils::MakeMaker::prompt;
    if ( $args{autoconfig} ) {
        $manual_conf = "no";
    } else {
        $manual_conf = prompt("Are you ready for manual configuration?", "yes");
    }
    my $fastread;
    {
      if ($manual_conf =~ /^y/i) {
	$fastread = 0;
      } else {
	$fastread = 1;
	$CPAN::Config->{urllist} ||= [];

        local $^W = 0;
	# prototype should match that of &MakeMaker::prompt
	*_real_prompt = sub ($;$) {
	  my($q,$a) = @_;
	  my($ret) = defined $a ? $a : "";
	  $CPAN::Frontend->myprint(sprintf qq{%s [%s]\n\n}, $q, $ret);
          eval { require Time::HiRes };
          unless ($@) {
              Time::HiRes::sleep(0.1);
          }
	  $ret;
	};
      }
    }

    $CPAN::Frontend->myprint($prompts{config_intro})
      if !$matcher or 'config_intro' =~ /$matcher/;

    my $cpan_home = $CPAN::Config->{cpan_home}
	|| File::Spec->catdir($ENV{HOME}, ".cpan");

    if (-d $cpan_home) {
	if (!$matcher or 'config_intro' =~ /$matcher/) {
	    $CPAN::Frontend->myprint(qq{

I see you already have a  directory
    $cpan_home
Shall we use it as the general CPAN build and cache directory?

});
	}
    } else {
	# no cpan-home, must prompt and get one
	$CPAN::Frontend->myprint($prompts{cpan_home_where});
    }

    $default = $cpan_home;
    while ($ans = prompt("CPAN build and cache directory?",$default)) {
      unless (File::Spec->file_name_is_absolute($ans)) {
        require Cwd;
        my $cwd = Cwd::cwd();
        my $absans = File::Spec->catdir($cwd,$ans);
        warn "The path '$ans' is not an absolute path. Please specify an absolute path\n";
        $default = $absans;
        next;
      }
      eval { File::Path::mkpath($ans); }; # dies if it can't
      if ($@) {
	warn "Couldn't create directory $ans.\nPlease retry.\n";
	next;
      }
      if (-d $ans && -w _) {
	last;
      } else {
	warn "Couldn't find directory $ans\n"
		. "or directory is not writable. Please retry.\n";
      }
    }
    $CPAN::Config->{cpan_home} = $ans;

    $CPAN::Frontend->myprint($prompts{keep_source_where});

    $CPAN::Config->{keep_source_where}
	= File::Spec->catdir($CPAN::Config->{cpan_home},"sources");

    $CPAN::Config->{build_dir}
	= File::Spec->catdir($CPAN::Config->{cpan_home},"build");

    #
    # Cache size, Index expire
    #

    $CPAN::Frontend->myprint($prompts{build_cache_intro})
      if !$matcher or 'build_cache_intro' =~ /$matcher/;

    # large enough to build large dists like Tk
    my_dflt_prompt(build_cache => 100, $matcher);

    # XXX This the time when we refetch the index files (in days)
    $CPAN::Config->{'index_expire'} = 1;

    $CPAN::Frontend->myprint($prompts{scan_cache_intro})
      if !$matcher or 'build_cache_intro' =~ /$matcher/;

    my_prompt_loop(scan_cache => 'atstart', $matcher, 'atstart|never');

    #
    # cache_metadata
    #

    if (!$matcher or 'build_cache_intro' =~ /$matcher/) {

	$CPAN::Frontend->myprint($prompts{cache_metadata});

	defined($default = $CPAN::Config->{cache_metadata}) or $default = 1;
	do {
	    $ans = prompt("Cache metadata (yes/no)?", ($default ? 'yes' : 'no'));
	} while ($ans !~ /^[yn]/i);
	$CPAN::Config->{cache_metadata} = ($ans =~ /^y/i ? 1 : 0);
    }
    #
    # term_is_latin
    #

    $CPAN::Frontend->myprint($prompts{term_is_latin})
      if !$matcher or 'term_is_latin' =~ /$matcher/;

    defined($default = $CPAN::Config->{term_is_latin}) or $default = 1;
    do {
        $ans = prompt("Your terminal expects ISO-8859-1 (yes/no)?",
                      ($default ? 'yes' : 'no'));
    } while ($ans !~ /^[yn]/i);
    $CPAN::Config->{term_is_latin} = ($ans =~ /^y/i ? 1 : 0);

    #
    # save history in file 'histfile'
    #

    $CPAN::Frontend->myprint($prompts{histfile_intro});

    defined($default = $CPAN::Config->{histfile}) or
        $default = File::Spec->catfile($CPAN::Config->{cpan_home},"histfile");
    $ans = prompt("File to save your history?", $default);
    $CPAN::Config->{histfile} = $ans;

    if ($CPAN::Config->{histfile}) {
      defined($default = $CPAN::Config->{histsize}) or $default = 100;
      $ans = prompt("Number of lines to save?", $default);
      $CPAN::Config->{histsize} = $ans;
    }

    #
    # do an ls on the m or the d command
    #
    $CPAN::Frontend->myprint($prompts{show_upload_date_intro});

    defined($default = $CPAN::Config->{show_upload_date}) or
        $default = 'n';
    $ans = prompt("Always try to show upload date with 'd' and 'm' command (yes/no)?",
                  ($default ? 'yes' : 'no'));
    $CPAN::Config->{show_upload_date} = ($ans =~ /^[y1]/i ? 1 : 0);

    #my_prompt_loop(show_upload_date => 'n', $matcher,
		   #'follow|ask|ignore');

    #
    # prerequisites_policy
    # Do we follow PREREQ_PM?
    #

    $CPAN::Frontend->myprint($prompts{prerequisites_policy_intro})
      if !$matcher or 'prerequisites_policy_intro' =~ /$matcher/;

    my_prompt_loop(prerequisites_policy => 'ask', $matcher,
		   'follow|ask|ignore');


    #
    # Module::Signature
    #
    $CPAN::Frontend->myprint($prompts{check_sigs_intro});

    defined($default = $CPAN::Config->{check_sigs}) or
        $default = 0;
    $ans = prompt($prompts{check_sigs},
                  ($default ? 'yes' : 'no'));
    $CPAN::Config->{check_sigs} = ($ans =~ /^y/i ? 1 : 0);

    #
    # External programs
    #

    $CPAN::Frontend->myprint($prompts{external_progs})
      if !$matcher or 'external_progs' =~ /$matcher/;

    my $old_warn = $^W;
    local $^W if $^O eq 'MacOS';
    my(@path) = split /$Config{'path_sep'}/, $ENV{'PATH'};
    local $^W = $old_warn;
    my $progname;
    for $progname (qw/bzip2 gzip tar unzip make
                      curl lynx wget ncftpget ncftp ftp
                      gpg/)
    {
      if ($^O eq 'MacOS') {
          $CPAN::Config->{$progname} = 'not_here';
          next;
      }
      next if $matcher && $progname !~ /$matcher/;

      my $progcall = $progname;
      # we don't need ncftp if we have ncftpget
      next if $progname eq "ncftp" && $CPAN::Config->{ncftpget} gt " ";
      my $path = $CPAN::Config->{$progname}
	  || $Config::Config{$progname}
	      || "";
      if (File::Spec->file_name_is_absolute($path)) {
	# testing existence is not good enough, some have these exe
	# extensions

	# warn "Warning: configured $path does not exist\n" unless -e $path;
	# $path = "";
      } elsif ($path =~ /^\s+$/) {
          # preserve disabled programs
      } else {
	$path = '';
      }
      unless ($path) {
	# e.g. make -> nmake
	$progcall = $Config::Config{$progname} if $Config::Config{$progname};
      }

      $path ||= find_exe($progcall,[@path]);
      $CPAN::Frontend->mywarn("Warning: $progcall not found in PATH\n") unless
	  $path; # not -e $path, because find_exe already checked that
      $ans = prompt("Where is your $progname program?",$path) || $path;
      $CPAN::Config->{$progname} = $ans;
    }
    my $path = $CPAN::Config->{'pager'} || 
	$ENV{PAGER} || find_exe("less",[@path]) || 
	    find_exe("more",[@path]) || ($^O eq 'MacOS' ? $ENV{EDITOR} : 0 )
	    || "more";
    $ans = prompt("What is your favorite pager program?",$path);
    $CPAN::Config->{'pager'} = $ans;
    $path = $CPAN::Config->{'shell'};
    if (File::Spec->file_name_is_absolute($path)) {
	warn "Warning: configured $path does not exist\n" unless -e $path;
	$path = "";
    }
    $path ||= $ENV{SHELL};
    $path ||= $ENV{COMSPEC} if $^O eq "MSWin32";
    if ($^O eq 'MacOS') {
        $CPAN::Config->{'shell'} = 'not_here';
    } else {
        $path =~ s,\\,/,g if $^O eq 'os2';	# Cosmetic only
        $ans = prompt("What is your favorite shell?",$path);
        $CPAN::Config->{'shell'} = $ans;
    }

    #
    # Arguments to make etc.
    #

    $CPAN::Frontend->myprint($prompts{prefer_installer_intro})
      if !$matcher or 'prerequisites_policy_intro' =~ /$matcher/;

    my_prompt_loop(prefer_installer => 'EUMM', $matcher, 'MB|EUMM');


    $CPAN::Frontend->myprint($prompts{makepl_arg_intro})
      if !$matcher or 'makepl_arg_intro' =~ /$matcher/;

    my_dflt_prompt(makepl_arg => "", $matcher);

    my_dflt_prompt(make_arg => "", $matcher);

    require CPAN::HandleConfig;
    if (exists $CPAN::HandleConfig::keys{make_install_make_command}) {
        # as long as Windows needs $self->_build_command, we cannot
        # support sudo on windows :-)
        my_dflt_prompt(make_install_make_command => $CPAN::Config->{make} || "",
                       $matcher);
    }

    my_dflt_prompt(make_install_arg => $CPAN::Config->{make_arg} || "", 
		   $matcher);

    $CPAN::Frontend->myprint($prompts{mbuildpl_arg_intro})
      if !$matcher or 'mbuildpl_arg_intro' =~ /$matcher/;

    my_dflt_prompt(mbuildpl_arg => "", $matcher);

    my_dflt_prompt(mbuild_arg => "", $matcher);

    if (exists $CPAN::HandleConfig::keys{mbuild_install_build_command}) {
        # as long as Windows needs $self->_build_command, we cannot
        # support sudo on windows :-)
        my_dflt_prompt(mbuild_install_build_command => "./Build", $matcher);
    }

    my_dflt_prompt(mbuild_install_arg => "", $matcher);

    #
    # Alarm period
    #

    $CPAN::Frontend->myprint($prompts{inactivity_timeout_intro})
      if !$matcher or 'inactivity_timeout_intro' =~ /$matcher/;

    # my_dflt_prompt(inactivity_timeout => 0);

    $default = $CPAN::Config->{inactivity_timeout} || 0;
    $CPAN::Config->{inactivity_timeout} =
      prompt("Timeout for inactivity during {Makefile,Build}.PL?",$default);

    # Proxies

    $CPAN::Frontend->myprint($prompts{proxy_intro})
      if !$matcher or 'proxy_intro' =~ /$matcher/;

    for (qw/ftp_proxy http_proxy no_proxy/) {
	next if $matcher and $_ =~ /$matcher/;

	$default = $CPAN::Config->{$_} || $ENV{$_};
	$CPAN::Config->{$_} = prompt("Your $_?",$default);
    }

    if ($CPAN::Config->{ftp_proxy} ||
        $CPAN::Config->{http_proxy}) {

        $default = $CPAN::Config->{proxy_user} || $CPAN::LWP::UserAgent::USER;

		$CPAN::Frontend->myprint($prompts{proxy_user});

        if ($CPAN::Config->{proxy_user} = prompt("Your proxy user id?",$default)) {
	    $CPAN::Frontend->myprint($prompts{proxy_pass});

            if ($CPAN::META->has_inst("Term::ReadKey")) {
                Term::ReadKey::ReadMode("noecho");
            } else {
		$CPAN::Frontend->myprint($prompts{password_warn});
            }
            $CPAN::Config->{proxy_pass} = prompt_no_strip("Your proxy password?");
            if ($CPAN::META->has_inst("Term::ReadKey")) {
                Term::ReadKey::ReadMode("restore");
            }
            $CPAN::Frontend->myprint("\n\n");
        }
    }

    #
    # MIRRORED.BY
    #

    conf_sites() unless $fastread;

    # We don't ask these now, the defaults are very likely OK.
    $CPAN::Config->{inhibit_startup_message} = 0;
    $CPAN::Config->{getcwd}                  = 'cwd';
    $CPAN::Config->{ftp_passive}             = 1;
    $CPAN::Config->{term_ornaments}          = 1;

    $CPAN::Frontend->myprint("\n\n");
    CPAN::HandleConfig->commit($configpm);
}

sub my_dflt_prompt {
    my ($item, $dflt, $m) = @_;
    my $default = $CPAN::Config->{$item} || $dflt;

    $DB::single = 1;
    if (!$m || $item =~ /$m/) {
	$CPAN::Config->{$item} = prompt($prompts{$item}, $default);
    } else {
	$CPAN::Config->{$item} = $default;
    }
}

sub my_prompt_loop {
    my ($item, $dflt, $m, $ok) = @_;
    my $default = $CPAN::Config->{$item} || $dflt;
    my $ans;

    $DB::single = 1;
    if (!$m || $item =~ /$m/) {
	do { $ans = prompt($prompts{$item}, $default);
	} until $ans =~ /$ok/;
	$CPAN::Config->{$item} = $ans;
    } else {
	$CPAN::Config->{$item} = $default;
    }
}


sub conf_sites {
  my $m = 'MIRRORED.BY';
  my $mby = File::Spec->catfile($CPAN::Config->{keep_source_where},$m);
  File::Path::mkpath(File::Basename::dirname($mby));
  if (-f $mby && -f $m && -M $m < -M $mby) {
    require File::Copy;
    File::Copy::copy($m,$mby) or die "Could not update $mby: $!";
  }
  my $loopcount = 0;
  local $^T = time;
  my $overwrite_local = 0;
  if ($mby && -f $mby && -M _ <= 60 && -s _ > 0) {
      my $mtime = localtime((stat _)[9]);
      my $prompt = qq{Found $mby as of $mtime

I\'d use that as a database of CPAN sites. If that is OK for you,
please answer 'y', but if you want me to get a new database now,
please answer 'n' to the following question.

Shall I use the local database in $mby?};
      my $ans = prompt($prompt,"y");
      $overwrite_local = 1 unless $ans =~ /^y/i;
  }
  while ($mby) {
    if ($overwrite_local) {
      print qq{Trying to overwrite $mby\n};
      $mby = CPAN::FTP->localize($m,$mby,3);
      $overwrite_local = 0;
    } elsif ( ! -f $mby ){
      print qq{You have no $mby\n  I\'m trying to fetch one\n};
      $mby = CPAN::FTP->localize($m,$mby,3);
    } elsif (-M $mby > 60 && $loopcount == 0) {
      print qq{Your $mby is older than 60 days,\n  I\'m trying to fetch one\n};
      $mby = CPAN::FTP->localize($m,$mby,3);
      $loopcount++;
    } elsif (-s $mby == 0) {
      print qq{You have an empty $mby,\n  I\'m trying to fetch one\n};
      $mby = CPAN::FTP->localize($m,$mby,3);
    } else {
      last;
    }
  }
  read_mirrored_by($mby);
  bring_your_own();
}

sub find_exe {
    my($exe,$path) = @_;
    my($dir);
    #warn "in find_exe exe[$exe] path[@$path]";
    for $dir (@$path) {
	my $abs = File::Spec->catfile($dir,$exe);
	if (($abs = MM->maybe_command($abs))) {
	    return $abs;
	}
    }
}

sub picklist {
    my($items,$prompt,$default,$require_nonempty,$empty_warning)=@_;
    $default ||= '';

    my $pos = 0;

    my @nums;
    while (1) {

        # display, at most, 15 items at a time
        my $limit = $#{ $items } - $pos;
        $limit = 15 if $limit > 15;

        # show the next $limit items, get the new position
        $pos = display_some($items, $limit, $pos);
        $pos = 0 if $pos >= @$items;

        my $num = prompt($prompt,$default);

        @nums = split (' ', $num);
        my $i = scalar @$items;
        (warn "invalid items entered, try again\n"), next
            if grep (/\D/ || $_ < 1 || $_ > $i, @nums);
        if ($require_nonempty) {
            (warn "$empty_warning\n");
        }
        print "\n";

        # a blank line continues...
        next unless @nums;
        last;
    }
    for (@nums) { $_-- }
    @{$items}[@nums];
}

sub display_some {
	my ($items, $limit, $pos) = @_;
	$pos ||= 0;

	my @displayable = @$items[$pos .. ($pos + $limit)];
    for my $item (@displayable) {
		printf "(%d) %s\n", ++$pos, $item;
    }
	printf("%d more items, hit SPACE RETURN to show them\n",
               (@$items - $pos)
              )
            if $pos < @$items;
	return $pos;
}

sub read_mirrored_by {
    my $local = shift or return;
    my(%all,$url,$expected_size,$default,$ans,$host,
       $dst,$country,$continent,@location);
    my $fh = FileHandle->new;
    $fh->open($local) or die "Couldn't open $local: $!";
    local $/ = "\012";
    while (<$fh>) {
	($host) = /^([\w\.\-]+)/ unless defined $host;
	next unless defined $host;
	next unless /\s+dst_(dst|location)/;
	/location\s+=\s+\"([^\"]+)/ and @location = (split /\s*,\s*/, $1) and
	    ($continent, $country) = @location[-1,-2];
	$continent =~ s/\s\(.*//;
	$continent =~ s/\W+$//; # if Jarkko doesn't know latitude/longitude
	/dst_dst\s+=\s+\"([^\"]+)/  and $dst = $1;
	next unless $host && $dst && $continent && $country;
	$all{$continent}{$country}{$dst} = CPAN::Mirrored::By->new($continent,$country,$dst);
	undef $host;
	$dst=$continent=$country="";
    }
    $fh->close;
    $CPAN::Config->{urllist} ||= [];
    my(@previous_urls);
    if (@previous_urls = @{$CPAN::Config->{urllist}}) {
	$CPAN::Config->{urllist} = [];
    }

    print $prompts{urls_intro};

    my (@cont, $cont, %cont, @countries, @urls, %seen);
    my $no_previous_warn = 
       "Sorry! since you don't have any existing picks, you must make a\n" .
       "geographic selection.";
    @cont = picklist([sort keys %all],
                     "Select your continent (or several nearby continents)",
                     '',
                     ! @previous_urls,
                     $no_previous_warn);


    foreach $cont (@cont) {
        my @c = sort keys %{$all{$cont}};
        @cont{@c} = map ($cont, 0..$#c);
        @c = map ("$_ ($cont)", @c) if @cont > 1;
        push (@countries, @c);
    }

    if (@countries) {
        @countries = picklist (\@countries,
                               "Select your country (or several nearby countries)",
                               '',
                               ! @previous_urls,
                               $no_previous_warn);
        %seen = map (($_ => 1), @previous_urls);
        # hmmm, should take list of defaults from CPAN::Config->{'urllist'}...
        foreach $country (@countries) {
            (my $bare_country = $country) =~ s/ \(.*\)//;
            my @u = sort keys %{$all{$cont{$bare_country}}{$bare_country}};
            @u = grep (! $seen{$_}, @u);
            @u = map ("$_ ($bare_country)", @u)
               if @countries > 1;
            push (@urls, @u);
        }
    }
    push (@urls, map ("$_ (previous pick)", @previous_urls));
    my $prompt = "Select as many URLs as you like (by number),
put them on one line, separated by blanks, e.g. '1 4 5'";
    if (@previous_urls) {
       $default = join (' ', ((scalar @urls) - (scalar @previous_urls) + 1) ..
                             (scalar @urls));
       $prompt .= "\n(or just hit RETURN to keep your previous picks)";
    }

    @urls = picklist (\@urls, $prompt, $default);
    foreach (@urls) { s/ \(.*\)//; }
    push @{$CPAN::Config->{urllist}}, @urls;
}

sub bring_your_own {
    my %seen = map (($_ => 1), @{$CPAN::Config->{urllist}});
    my($ans,@urls);
    do {
	my $prompt = "Enter another URL or RETURN to quit:";
	unless (%seen) {
	    $prompt = qq{CPAN.pm needs at least one URL where it can fetch CPAN files from.

Please enter your CPAN site:};
	}
        $ans = prompt ($prompt, "");

        if ($ans) {
            $ans =~ s|/?\z|/|; # has to end with one slash
            $ans = "file:$ans" unless $ans =~ /:/; # without a scheme is a file:
            if ($ans =~ /^\w+:\/./) {
                push @urls, $ans unless $seen{$ans}++;
            } else {
                printf(qq{"%s" doesn\'t look like an URL at first sight.
I\'ll ignore it for now.
You can add it to your %s
later if you\'re sure it\'s right.\n},
                       $ans,
                       $INC{'CPAN/MyConfig.pm'} || $INC{'CPAN/Config.pm'} || "configuration file",
                      );
            }
        }
    } while $ans || !%seen;

    push @{$CPAN::Config->{urllist}}, @urls;
    # xxx delete or comment these out when you're happy that it works
    print "New set of picks:\n";
    map { print "  $_\n" } @{$CPAN::Config->{urllist}};
}


sub _strip_spaces {
    $_[0] =~ s/^\s+//;  # no leading spaces
    $_[0] =~ s/\s+\z//; # no trailing spaces
}


sub prompt ($;$) {
    my $ans = _real_prompt(@_);

    _strip_spaces($ans);

    return $ans;
}


sub prompt_no_strip ($;$) {
    return _real_prompt(@_);
}


BEGIN {

my @prompts = (

manual_config => qq[

CPAN is the world-wide archive of perl resources. It consists of about
300 sites that all replicate the same contents around the globe.
Many countries have at least one CPAN site already. The resources
found on CPAN are easily accessible with the CPAN.pm module. If you
want to use CPAN.pm, you have to configure it properly.

If you do NOT want to enter a dialog now, you can answer 'no' to this
question and I'll try to autoconfigure. (Note: you can revisit this
dialog anytime later by typing 'o conf init' at the cpan prompt.)

],

config_intro => qq{

The following questions are intended to help you with the
configuration. The CPAN module needs a directory of its own to cache
important index files and maybe keep a temporary mirror of CPAN files.
This may be a site-wide directory or a personal directory.

},

# cpan_home => qq{ },

cpan_home_where => qq{

First of all, I\'d like to create this directory. Where?

},

keep_source_where => qq{

If you like, I can cache the source files after I build them.  Doing
so means that, if you ever rebuild that module in the future, the
files will be taken from the cache. The tradeoff is that it takes up
space.  How much space would you like to allocate to this cache?  (If
you don\'t want me to keep a cache, answer 0.)

},

build_cache_intro => qq{

How big should the disk cache be for keeping the build directories
with all the intermediate files\?

},

build_cache =>
"Cache size for build directory (in MB)?",


scan_cache_intro => qq{

By default, each time the CPAN module is started, cache scanning is
performed to keep the cache size in sync. To prevent this, answer
'never'.

},

scan_cache => "Perform cache scanning (atstart or never)?",

cache_metadata => qq{

To considerably speed up the initial CPAN shell startup, it is
possible to use Storable to create a cache of metadata. If Storable
is not available, the normal index mechanism will be used.

},

term_is_latin => qq{

The next option deals with the charset (aka character set) your
terminal supports. In general, CPAN is English speaking territory, so
the charset does not matter much, but some of the aliens out there who
upload their software to CPAN bear names that are outside the ASCII
range. If your terminal supports UTF-8, you should say no to the next
question.  If it supports ISO-8859-1 (also known as LATIN1) then you
should say yes.  If it supports neither, your answer does not matter
because you will not be able to read the names of some authors
anyway. If you answer no, names will be output in UTF-8.

},

histfile_intro => qq{

If you have one of the readline packages (Term::ReadLine::Perl,
Term::ReadLine::Gnu, possibly others) installed, the interactive CPAN
shell will have history support. The next two questions deal with the
filename of the history file and with its size. If you do not want to
set this variable, please hit SPACE RETURN to the following question.

},

histfile => qq{File to save your history?},

show_upload_date_intro => qq{

The 'd' and the 'm' command normally only show you information they
have in their in-memory database and thus will never connect to the
internet. If you set the 'show_upload_date' variable to true, 'm' and
'd' will additionally show you the upload date of the module or
distribution. Per default this feature is off because it may require a
net connection to get at the upload date.

},

show_upload_date =>
"Always try to show upload date with 'd' and 'm' command (yes/no)?",

prerequisites_policy_intro => qq{

The CPAN module can detect when a module which you are trying to build
depends on prerequisites. If this happens, it can build the
prerequisites for you automatically ('follow'), ask you for
confirmation ('ask'), or just ignore them ('ignore'). Please set your
policy to one of the three values.

},

prerequisites_policy =>
"Policy on building prerequisites (follow, ask or ignore)?",

check_sigs_intro  => qq{

CPAN packages can be digitally signed by authors and thus verified
with the security provided by strong cryptography. The exact mechanism
is defined in the Module::Signature module. While this is generally
considered a good thing, it is not always convenient to the end user
to install modules that are signed incorrectly or where the key of the
author is not available or where some prerequisite for
Module::Signature has a bug and so on.

With the check_sigs parameter you can turn signature checking on and
off. The default is off for now because the whole tool chain for the
functionality is not yet considered mature by some. The author of
CPAN.pm would recommend setting it to true most of the time and
turning it off only if it turns out to be annoying.

Note that if you do not have Module::Signature installed, no signature
checks will be performed at all.

},

check_sigs =>
qq{Always try to check and verify signatures if a SIGNATURE file is in the package
and Module::Signature is installed (yes/no)?},

external_progs => qq{

The CPAN module will need a few external programs to work properly.
Please correct me, if I guess the wrong path for a program. Don\'t
panic if you do not have some of them, just press ENTER for those. To
disable the use of a download program, you can type a space followed
by ENTER.

},

prefer_installer_intro => qq{

When you have Module::Build installed and a module comes with both a
Makefile.PL and a Build.PL, which shall have precedence? The two
installer modules we have are the old and well established
ExtUtils::MakeMaker (for short: EUMM) understands the Makefile.PL and
the next generation installer Module::Build (MB) works with the
Build.PL.

},

prefer_installer =>
qq{In case you could choose, which installer would you prefer (EUMM or MB)?},

makepl_arg_intro => qq{

Every Makefile.PL is run by perl in a separate process. Likewise we
run \'make\' and \'make install\' in separate processes. If you have
any parameters \(e.g. PREFIX, LIB, UNINST or the like\) you want to
pass to the calls, please specify them here.

If you don\'t understand this question, just press ENTER.
},

makepl_arg => qq{
Parameters for the 'perl Makefile.PL' command?
Typical frequently used settings:

    PREFIX=~/perl    # non-root users (please see manual for more hints)

Your choice: },

make_arg => qq{Parameters for the 'make' command?
Typical frequently used setting:

    -j3              # dual processor system

Your choice: },


make_install_make_command => qq{Do you want to use a different make command for 'make install'?
Cautious people will probably prefer:

    su root -c make
or
    sudo make
or
    /path1/to/sudo -u admin_account /path2/to/make

or some such. Your choice: },


make_install_arg => qq{Parameters for the 'make install' command?
Typical frequently used setting:

    UNINST=1         # to always uninstall potentially conflicting files

Your choice: },


mbuildpl_arg_intro => qq{

The next questions deal with Module::Build support.

A Build.PL is run by perl in a separate process. Likewise we run
'./Build' and './Build install' in separate processes. If you have any
parameters you want to pass to the calls, please specify them here.

},

mbuildpl_arg => qq{Parameters for the 'perl Build.PL' command?
Typical frequently used settings:

    --install_base /home/xxx             # different installation directory

Your choice: },

mbuild_arg => qq{Parameters for the './Build' command?
Setting might be:

    --extra_linker_flags -L/usr/foo/lib  # non-standard library location

Your choice: },


mbuild_install_build_command => qq{Do you want to use a different command for './Build install'?
Sudo users will probably prefer:

    su root -c ./Build
or
    sudo ./Build
or
    /path1/to/sudo -u admin_account ./Build

or some such. Your choice: },


mbuild_install_arg => qq{Parameters for the './Build install' command?
Typical frequently used setting:

    --uninst 1                           # uninstall conflicting files

Your choice: },



inactivity_timeout_intro => qq{

Sometimes you may wish to leave the processes run by CPAN alone
without caring about them. Because the Makefile.PL sometimes contains
question you\'re expected to answer, you can set a timer that will
kill a 'perl Makefile.PL' process after the specified time in seconds.

If you set this value to 0, these processes will wait forever. This is
the default and recommended setting.

},

inactivity_timeout => 
qq{Timeout for inactivity during {Makefile,Build}.PL? },


proxy_intro => qq{

If you\'re accessing the net via proxies, you can specify them in the
CPAN configuration or via environment variables. The variable in
the \$CPAN::Config takes precedence.

},

proxy_user => qq{

If your proxy is an authenticating proxy, you can store your username
permanently. If you do not want that, just press RETURN. You will then
be asked for your username in every future session.

},

proxy_pass => qq{

Your password for the authenticating proxy can also be stored
permanently on disk. If this violates your security policy, just press
RETURN. You will then be asked for the password in every future
session.

},

urls_intro => qq{

Now we need to know where your favorite CPAN sites are located. Push
a few sites onto the array (just in case the first on the array won\'t
work). If you are mirroring CPAN to your local workstation, specify a
file: URL.

First, pick a nearby continent and country (you can pick several of
each, separated by spaces, or none if you just want to keep your
existing selections). Then, you will be presented with a list of URLs
of CPAN mirrors in the countries you selected, along with previously
selected URLs. Select some of those URLs, or just keep the old list.
Finally, you will be prompted for any extra URLs -- file:, ftp:, or
http: -- that host a CPAN mirror.

},

password_warn => qq{

Warning: Term::ReadKey seems not to be available, your password will
be echoed to the terminal!

},

);

die "Coding error in \@prompts declaration.  Odd number of elements, above"
  if (@prompts % 2);

%prompts = @prompts;

if (scalar(keys %prompts) != scalar(@prompts)/2) {

    my %already;

    for my $item (0..$#prompts) {
	next if $item % 2;
	die "$prompts[$item] is duplicated\n"
	  if $already{$prompts[$item]}++;
    }

}

}

1;
