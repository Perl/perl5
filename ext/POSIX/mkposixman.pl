#!/tmp/perl5 -w
#!/tmp/perl5

# Ramrodded by Dean Roehrich.
#
# Submissions for function descriptions are needed.  Don't write a tutorial,
# and don't repeat things that can be found in the system's manpages,
# just give a quick 2-3 line note and a one-line example.
#
# Check the latest version of the Perl5 Module List for Dean's current
# email address (listed as DMR).
#
my $VERS = 951129;  # yymmdd

local *main::XS;
local *main::PM;

open( XS, "<POSIX.xs" ) || die "Unable to open POSIX.xs";
open( PM, "<POSIX.pm" ) || die "Unable to open POSIX.pm";
close STDOUT;
open( STDOUT, ">POSIX.pod" ) || die "Unable to open POSIX.pod";

print <<'EOQ';
=head1 NAME

POSIX - Perl interface to IEEE Std 1003.1

=head1 SYNOPSIS

    use POSIX;
    use POSIX qw(setsid);
    use POSIX qw(:errno_h :fcntl_h);

    printf "EINTR is %d\n", EINTR;

    $sess_id = POSIX::setsid();

    $fd = POSIX::open($path, O_CREAT|O_EXCL|O_WRONLY, 0644);
	# note: that's a filedescriptor, *NOT* a filehandle

=head1 DESCRIPTION

The POSIX module permits you to access all (or nearly all) the standard
POSIX 1003.1 identifiers.  Many of these identifiers have been given Perl-ish
interfaces.  Things which are C<#defines> in C, like EINTR or O_NDELAY, are
automatically exported into your namespace.  All functions are only exported
if you ask for them explicitly.  Most likely people will prefer to use the
fully-qualified function names.

This document gives a condensed list of the features available in the POSIX
module.  Consult your operating system's manpages for general information on
most features.  Consult L<perlfunc> for functions which are noted as being
identical to Perl's builtin functions.

The first section describes POSIX functions from the 1003.1 specification.
The second section describes some classes for signal objects, TTY objects,
and other miscellaneous objects.  The remaining sections list various
constants and macros in an organization which roughly follows IEEE Std
1003.1b-1993.

=head1 NOTE

The POSIX module is probably the most complex Perl module supplied with
the standard distribution.  It incorporates autoloading, namespace games,
and dynamic loading of code that's in Perl, C, or both.  It's a great
source of wisdom.

=head1 CAVEATS 

A few functions are not implemented because they are C specific.  If you
attempt to call these, they will print a message telling you that they
aren't implemented, and suggest using the Perl equivalent should one
exist.  For example, trying to access the setjmp() call will elicit the
message "setjmp() is C-specific: use eval {} instead".

Furthermore, some evil vendors will claim 1003.1 compliance, but in fact
are not so: they will not pass the PCTS (POSIX Compliance Test Suites).
For example, one vendor may not define EDEADLK, or the semantics of the
errno values set by open(2) might not be quite right.  Perl does not
attempt to verify POSIX compliance.  That means you can currently
successfully say "use POSIX",  and then later in your program you find
that your vendor has been lax and there's no usable ICANON macro after
all.  This could be construed to be a bug.

EOQ

use strict;


my $constants = {};
my $macros = {};
my $packages = [];
my $posixpack = Package->new( 'POSIX' );
my $descriptions = Description->new;

get_constants( 'XS', $constants, $macros );
get_functions( 'XS', $packages, $posixpack );
get_PMfunctions( 'PM', $packages, $posixpack, $descriptions );


# It is possible that the matches of setup_*() may depend on
# the matches of an earlier setup_*().  If you change the order,
# be careful that you're getting only what you want, and no more.
#
my $termios_flags = setup_termios( $constants );
my $wait_stuff = setup_wait( $constants, $macros );
my $stat = setup_file_char( $constants, $macros );
my $port = setup_pat( $constants, '^_POSIX' );
my $sc = setup_pat( $constants, '^_SC_' );
my $pc = setup_pat( $constants, '^_PC_' );
my $fcntl = setup_pat( $constants, '^([FO]_|FD_)' );
my $sigs = setup_pat( $constants, '^(SIG|SA_)' );
my $float = setup_pat( $constants, '^(L?DBL_|FLT_)' );
my $locale = setup_pat( $constants, '^LC_' );
my $stdio = setup_pat( $constants, '(^BUFSIZ$)|(^L_)|(^_IO...$)|(^EOF$)|(^FILENAME_MAX$)|(^TMP_MAX$)' );
my $stdlib = setup_pat( $constants, '(^EXIT_)|(^MB_CUR_MAX$)|(^RAND_MAX$)' );
my $limits = setup_pat( $constants, '(_MAX$)|(_MIN$)|(_BIT$)|(^MAX_)|(_BUF$)' );
my $math = setup_pat( $constants, '^HUGE_VAL$' );
my $time = setup_pat( $constants, '^CL' );
my $unistd = setup_pat( $constants, '(_FILENO$)|(^SEEK_...$)|(^._OK$)' );
my $errno = setup_pat( $constants, '^E' );

print_posix( $posixpack, $descriptions );
print_classes( $packages, $constants, $termios_flags, $descriptions );
print_misc( 'Pathname Constants', $pc );
print_misc( 'POSIX Constants', $port );
print_misc( 'System Configuration', $sc );
print_misc( 'Errno', $errno );
print_misc( 'Fcntl', $fcntl );
print_misc( 'Float', $float );
print_misc( 'Limits', $limits );
print_misc( 'Locale', $locale );
print_misc( 'Math', $math );
print_misc( 'Signal', $sigs );
print_misc( 'Stat', $stat );
print_misc( 'Stdlib', $stdlib );
print_misc( 'Stdio', $stdio );
print_misc( 'Time', $time );
print_misc( 'Unistd', $unistd );
print_misc( 'Wait', $wait_stuff );

print_vers( $VERS );

dregs( $macros, $constants );

exit(0);

Unimplemented.

sub dregs {
	my $macros = shift;
	my $constants = shift;

	foreach (keys %$macros){
		warn "Unknown macro $_ in the POSIX.xs module.\n";
	}
	foreach (keys %$constants){
		warn "Unknown constant $_ in the POSIX.xs module.\n";
	}
}

sub get_constants {
	no strict 'refs';
	my $fh = shift;
	my $constants = shift;
	my $macros = shift;
	my $v;

	while(<$fh>){
		last if /^constant/;
	}
	while(<$fh>){ # }{{
		last if /^}/;
		if( /return\s+([^;]+)/ ){
			$v = $1;
			# skip non-symbols
			if( $v !~ /^\d+$/ ){
				# remove any C casts
				$v =~ s,\(.*?\)\s*(\w),$1,;
				# is it a macro?
				if( $v =~ s/(\(.*?\))// ){
					$macros->{$v} = $1;
				}
				else{
					$constants->{$v} = 1;
				}
			}
		}
	}
}

Close the file.  This uses file descriptors such as those obtained by calling
C<POSIX::open>.

	$fd = POSIX::open( "foo", &POSIX::O_RDONLY );
	POSIX::close( $fd );

sub get_functions {
	no strict 'refs';
	my $fh = shift;
	my $packages = shift;
	my $posixpack = shift;
	my $header = 0;
	my $pack = '';
	my $prefix = '';
	my( $x, $y );
	my( $curfuncs, $curpack );
	my $ret;

	while(<$fh>){
		if( /^MODULE.*?PACKAGE\s*=\s*([^\s]+)/ ){
			$pack = $1;
			$prefix = '';
			if( /PREFIX\s*=\s*([^\n]+)/ ){
				$prefix = $1;
			}
			#print "package($pack) prefix($prefix)\n";
			if( $pack eq 'POSIX' ){
				$curpack = $posixpack;
			}
			else{
				$curpack = Package->new( $pack );
				push @$packages, $curpack;
			}
			$curfuncs = $curpack->curfuncs;
			next;
		}

		chop;
		# find function header
		if( /^[^\s]/ && ! /^#/ ){
			$ret = /^SysRet/ ? 2 : 1;
			chop($x = <$fh>);
			next if( $pack eq 'POSIX' and $x =~ /^constant/ );
			$x =~ /^(.*?)\s*\((.*?)\)/;
			($x,$y) = ($1, $2); # func,sig
			$x =~ s/^$prefix//;
			$curfuncs->{$x} = $ret;
			++$header
		}
		# leave function header
		else{
			$header = 0;
		}
	}
}


sub get_PMfunctions {
	no strict 'refs';
	my $fh = shift;
	my $packages = shift;
	my $posixpack = shift;
	my $desc = shift;
	my $pack = '';
	my( $curfuncs, $curpack );
	my $y;
	my $x;
	my $sub = '';

	# find the second package statement.
	while(<$fh>){
		if( /^package\s+(.*?);/ ){
			$pack = $1;
			last if $pack ne 'POSIX';
		}
	}

	# Check if this package is already
	# being used.
	$curpack = '';
	foreach (@$packages){
		if( $_->name eq $pack ){
			$curpack = $_;
			last;
		}
	}
	# maybe start a new package.
	if( $curpack eq '' ){
		$curpack = Package->new( $pack );
		push @$packages, $curpack;
	}
	$curfuncs = $curpack->curfuncs;

	# now fetch functions
	while(<$fh>){
		if( /^package\s+(.*?);/ ){
			$pack = $1;
			if( $pack eq 'POSIX' ){
				$curpack = $posixpack;
			}
			else{
				# Check if this package is already
				# being used.
				$curpack = '';
				foreach (@$packages){
					if( $_->name() eq $pack ){
						$curpack = $_;
						last;
					}
				}
				# maybe start a new package.
				if( $curpack eq '' ){
					$curpack = Package->new( $pack );
					push @$packages, $curpack;
				}
			}
			$curfuncs = $curpack->curfuncs;
			next;
		}
		if( /^sub\s+(.*?)\s/ ){
			$sub = $1;

			# special cases
			if( $pack eq 'POSIX::SigAction' and
			   $sub eq 'new' ){
				$curfuncs->{$sub} = 1;
			}
			elsif( $pack eq 'POSIX' and $sub eq 'perror' ){
				$curfuncs->{$sub} = 1;
			}

			next;
		}
		if( /usage.*?\((.*?)\)/ ){
			$y = $1;
			$curfuncs->{$sub} = 1;
			next;
		 }
		 if( /^\s+unimpl\s+"(.*?)"/ ){
			$y = $1;
			$y =~ s/, stopped//;
			$desc->append( $pack, $sub, $y );
			$curfuncs->{$sub} = 1;
			next;
		 }
		 if( /^\s+redef\s+"(.*?)"/ ){
			$x = $1;
			$y = "Use method C<$x> instead";
			$desc->append( $pack, $sub, $y );
			$curfuncs->{$sub} = 1;
			next;
		 }
	}
}

Retrieves the value of a configurable limit on a file or directory.  This
uses file descriptors such as those obtained by calling C<POSIX::open>.

The following will determine the maximum length of the longest allowable
pathname on the filesystem which holds C</tmp/foo>.

	$fd = POSIX::open( "/tmp/foo", &POSIX::O_RDONLY );
	$path_max = POSIX::fpathconf( $fd, &POSIX::_PC_PATH_MAX );
Return the mantissa and exponent of a floating-point number.

	($mantissa, $exponent) = POSIX::frexp( 3.14 );
Get file status.  This uses file descriptors such as those obtained by
calling C<POSIX::open>.  The data returned is identical to the data from
Perl's builtin C<stat> function.

	$fd = POSIX::open( "foo", &POSIX::O_RDONLY );
	@stats = POSIX::fstat( $fd );

sub print_posix {
	my $pack = shift;
	my $desc = shift;

	print "=head1 FUNCTIONS\n\n";
	print "=over 8\n\n";
	dumpfuncs( $pack, $desc );
	print "=back\n\n";
}

sub print_classes {
	my $packages = shift;
	my $constants = shift;
	my $termios = shift;
	my $desc = shift;
	my $pack;
	my @pkgs;

	print "=head1 CLASSES\n\n";
	@pkgs = sort { $main::a->name() cmp $main::b->name() } @$packages;
	while( @pkgs ){
		$pack = shift @pkgs;
		print "=head2 ", $pack->name(), "\n\n";
		print "=over 8\n\n";

		dumpfuncs( $pack, $desc );

		if( $pack->name() =~ /termios/i ){
			dumpflags( $termios );
		}
		print "=back\n\n";
	}
}

sub setup_termios {
	my $constants = shift;
	my $obj;

	$obj = {
		'c_iflag field'	=> [qw( BRKINT ICRNL IGNBRK IGNCR IGNPAR
					INLCR INPCK ISTRIP IXOFF IXON
					PARMRK )],
		'c_oflag field' => [qw( OPOST )],
		'c_cflag field' => [qw( CLOCAL CREAD CSIZE CS5 CS6 CS7 CS8
					CSTOPB HUPCL PARENB PARODD )],
		'c_lflag field' => [qw( ECHO ECHOE ECHOK ECHONL ICANON
					IEXTEN ISIG NOFLSH TOSTOP )],
		'c_cc field'	=> [qw( VEOF VEOL VERASE VINTR VKILL VQUIT
					VSUSP VSTART VSTOP VMIN VTIME NCCS )],
		'Baud rate'	=> [],
		'Terminal interface' => [],
	};
	# look for baud rates in constants, add to termios
	foreach (keys %$constants){
		if( /^B\d+$/ ){
			push @{$obj->{'Baud rate'}}, $_;
		}
	}
	# look for TC* in constants, add to termios
	foreach (keys %$constants){
		if( /^TC/ ){
			push @{$obj->{'Terminal interface'}}, $_;
		}
	}
	# trim the constants
	foreach (keys %$obj){
		trim_hash( 'Constant', $obj->{$_}, $constants );
	}
	return $obj;
}


sub dumpfuncs {
	my $pack = shift;
	my $desc = shift;
	my $curfuncs = $pack->curfuncs;
	my $pname = $pack->name;
	my $func;
	my @funcs = sort keys %$curfuncs;

	if( exists $curfuncs->{'new'} ){ # do new first
		@funcs = grep( $_ ne 'new', @funcs );
		unshift @funcs, 'new';
	}
	while( @funcs ){
		$func = shift @funcs;
		if( $func eq 'DESTROY' ){
			next;	 # don't do DESTROY
		}
		print "=item $func\n\n";
		if( $desc->print( $pname, $func, $curfuncs->{$func} ) ){
			# if it was printed, note that
			delete $curfuncs->{$func};
		}
	}
}

sub dumpflags {
	my $flags = shift;
	my $field;

	foreach $field (sort keys %$flags){
		print "=item $field values\n\n";
		print join( ' ', @{$flags->{$field}} ), "\n\n";
	}
}

sub setup_wait {
	my $constants = shift;
	my $macros = shift;
	my $obj;

	$obj = {
		'Macros'    => [qw( WIFEXITED WEXITSTATUS WIFSIGNALED
				    WTERMSIG WIFSTOPPED WSTOPSIG )],
		'Constants' => [qw( WNOHANG WUNTRACED )],
	};
	trim_hash( 'Constant', $obj->{Constants}, $constants );
	trim_hash( 'Macro', $obj->{Macros}, $macros );
	return $obj;
}

sub setup_file_char {
	my $constants = shift;
	my $macros = shift;
	my $obj;

	$obj = {
		'Macros'    => [],
		'Constants' => [],
	};
	# find S_* constants and add to object.
	foreach (sort keys %$constants){
		if( /^S_/ ){
			push @{$obj->{'Constants'}}, $_;
		}
	}
	# find S_* macros and add to object.
	foreach (sort keys %$macros){
		if( /^S_/ ){
			push @{$obj->{'Macros'}}, $_;
		}
	}
	# trim the hashes
	trim_hash( 'Constant', $obj->{Constants}, $constants );
	trim_hash( 'Macro', $obj->{Macros}, $macros );
	return $obj;
}


sub setup_pat {
	my $constants = shift;
	my $pat = shift;
	my $obj;

	$obj = { 'Constants' => [] };
	foreach (sort keys %$constants){
		if( /$pat/ ){
			push @{$obj->{'Constants'}}, $_;
		}
	}
	trim_hash( 'Constant', $obj->{Constants}, $constants );
	return $obj;
}

Get numeric formatting information.  Returns a reference to a hash
containing the current locale formatting values.

The database for the B<de> (Deutsch or German) locale.

	$loc = POSIX::setlocale( &POSIX::LC_ALL, "de" );
	print "Locale = $loc\n";
	$lconv = POSIX::localeconv();
	print "decimal_point	= ", $lconv->{decimal_point},	"\n";
	print "thousands_sep	= ", $lconv->{thousands_sep},	"\n";
	print "grouping	= ", $lconv->{grouping},	"\n";
	print "int_curr_symbol	= ", $lconv->{int_curr_symbol},	"\n";
	print "currency_symbol	= ", $lconv->{currency_symbol},	"\n";
	print "mon_decimal_point = ", $lconv->{mon_decimal_point}, "\n";
	print "mon_thousands_sep = ", $lconv->{mon_thousands_sep}, "\n";
	print "mon_grouping	= ", $lconv->{mon_grouping},	"\n";
	print "positive_sign	= ", $lconv->{positive_sign},	"\n";
	print "negative_sign	= ", $lconv->{negative_sign},	"\n";
	print "int_frac_digits	= ", $lconv->{int_frac_digits},	"\n";
	print "frac_digits	= ", $lconv->{frac_digits},	"\n";
	print "p_cs_precedes	= ", $lconv->{p_cs_precedes},	"\n";
	print "p_sep_by_space	= ", $lconv->{p_sep_by_space},	"\n";
	print "n_cs_precedes	= ", $lconv->{n_cs_precedes},	"\n";
	print "n_sep_by_space	= ", $lconv->{n_sep_by_space},	"\n";
	print "p_sign_posn	= ", $lconv->{p_sign_posn},	"\n";
	print "n_sign_posn	= ", $lconv->{n_sign_posn},	"\n";
Move the read/write file pointer.  This uses file descriptors such as
those obtained by calling C<POSIX::open>.

	$fd = POSIX::open( "foo", &POSIX::O_RDONLY );
	$off_t = POSIX::lseek( $fd, 0, &POSIX::SEEK_SET );

sub print_vers {
	my $vers = shift;

	print "=head1 CREATION\n\n";
	print "This document generated by $0 version $vers.\n\n";
}

sub print_misc {
	my $hdr = shift;
	my $obj = shift;
	my $item;

	print "=head1 ", uc($hdr), "\n\n";
	print "=over 8\n\n";
	foreach $item (sort keys %$obj){
		print "=item $item\n\n";
		print join( ' ', @{$obj->{$item}}), "\n\n";
	}
	print "=back\n\n";
}

sub trim_hash {
	my $name = shift;
	my $av = shift;
	my $hv = shift;

	foreach (@$av){
		if( exists $hv->{$_} ){
			delete $hv->{$_};
		}
		else{
			warn "$name $_ is not in the POSIX.xs module";
		}
	}
}

{ package Package; ## Package package

  sub new {
	my $type = shift;
	my $pack = shift || die;
	my $self = [ $pack, {} ];
	bless $self, $type;
  }
  sub name {
	my $self = shift;
	$self->[0];
  }
  sub curfuncs {
	my $self = shift;
	$self->[1];
  }
  sub DESTROY {
	my $self = shift;
	my $pack = $self->name;
	foreach (keys %{$self->curfuncs}){
		if( $_ eq 'DESTROY' ){
			next; # don't expect much on DESTROY
		}
		warn "Function ". $pack . "::$_ did not have a description.\n";
	}
  }
}
{ package Description;  ## Function description

  sub new {
	my $type = shift;
	my $self = {};
	bless $self, $type;
	$self->fetch;
	return $self;
  }
  sub fetch {
	my $self = shift;
	my $pack = '';
	my $c;
	my( $sub, $as );

	while(<main::DATA>){
		next if /^#/;
		$sub = $as = '';
		if( /^==(.*)/ ){
			$pack = $1;
			next;
		}
		if( /^=([^\+]+)\+\+/ ){
			$sub = $1;
			$as = $sub;
		}
		elsif( /^=([^\+]+)\+C/ ){
			$sub = $1;
			$as = 'C';
		}
		elsif( /^=([^\+]+)\+(\w+)/ ){
			$sub = $1;
			$as = $2;
		}
		elsif( /^=(.*)/ ){
			$sub = $1;
		}

		if( $sub ne '' ){
			$sub = $1;
			$self->{$pack."::$sub"} = '';
			$c = \($self->{$pack."::$sub"});
			if( $as eq 'C' ){
				$$c .= "This is identical to the C function C<$sub()>.\n";
			}
			elsif( $as ne '' ){
				$$c .= "This is identical to Perl's builtin C<$as()> function.\n";
			}
			next;
		}
		$$c .= $_;
	}
  }
  sub DESTROY {
	my $self = shift;
	foreach (keys %$self){
		warn "Function $_ is not in the POSIX.xs module.\n";
	}
  }
  sub append {
	my $self = shift;
	my $pack = shift;
	my $sub = shift;
	my $str = shift || die;

	if( exists $self->{$pack."::$sub"} ){
		$self->{$pack."::$sub"} .= "\n$str.\n";
	}
	else{
		$self->{$pack."::$sub"} = "$str.\n";
	}
  }
  sub print {
	my $self = shift;
	my $pack = shift;
	my $sub = shift;
	my $rtype = shift || die;
	my $ret = 0;

	if( exists $self->{$pack."::$sub"} ){
		if( $rtype > 1 ){
			$self->{$pack."::$sub"} =~ s/identical/similar/;
		}
		print $self->{$pack."::$sub"}, "\n";
		delete $self->{$pack."::$sub"};
		if( $rtype > 1 ){
			print "Returns C<undef> on failure.\n\n";
		}
		$ret = 1;
	}
	$ret;
  }
}

Create an interprocess channel.  This returns file descriptors like those
returned by C<POSIX::open>.

	($fd0, $fd1) = POSIX::pipe();
	POSIX::write( $fd0, "hello", 5 );
	POSIX::read( $fd1, $buf, 5 );
Read from a file.  This uses file descriptors such as those obtained by
calling C<POSIX::open>.  If the buffer C<$buf> is not large enough for the
read then Perl will extend it to make room for the request.

	$fd = POSIX::open( "foo", &POSIX::O_RDONLY );
	$bytes = POSIX::read( $fd, $buf, 3 );
This is similar to the C function C<setpgid()>.
Detailed signal management.  This uses C<POSIX::SigAction> objects for the
C<action> and C<oldaction> arguments.  Consult your system's C<sigaction>
manpage for details.

Synopsis:

	sigaction(sig, action, oldaction = 0)
Install a signal mask and suspend process until signal arrives.  This uses
C<POSIX::SigSet> objects for the C<signal_mask> argument.  Consult your
system's C<sigsuspend> manpage for details.

Synopsis:

	sigsuspend(signal_mask)
This is identical to Perl's builtin C<sprintf()> function.
Convert date and time information to string.  Returns the string.

Synopsis:

	strftime(fmt, sec, min, hour, mday, mon, year, wday = 0, yday = 0, isdst = 0)

The month (C<mon>), weekday (C<wday>), and yearday (C<yday>) begin at zero.
I.e. January is 0, not 1; Sunday is 0, not 1; January 1st is 0, not 1.  The
year (C<year>) is given in years since 1900.  I.e. The year 1995 is 95; the
year 2001 is 101.  Consult your system's C<strftime()> manpage for details
about these and the other arguments.

The string for Tuesday, December 12, 1995.

	$str = POSIX::strftime( "%A, %B %d, %Y", 0, 0, 0, 12, 11, 95, 2 );
	print "$str\n";
String transformation.  Returns the transformed string.

	$dst = POSIX::strxfrm( $src );
Get name of current operating system.

	($sysname, $nodename, $release, $version, $machine ) = POSIX::uname();
Returns the current file position, in bytes.

	$pos = $fh->tell;
Get terminal control attributes.

Obtain the attributes for stdin.

	$termios->getattr()

Obtain the attributes for stdout.

	$termios->getattr( 1 )
Set terminal control attributes.

Set attributes immediately for stdout.

	$termios->setattr( 1, &POSIX::TCSANOW );

__END__
##########
==POSIX::SigSet
=new
Create a new SigSet object.  This object will be destroyed automatically
when it is no longer needed.  Arguments may be supplied to initialize the
set.

Create an empty set.

	$sigset = POSIX::SigSet->new;

Create a set with SIGUSR1.

	$sigset = POSIX::SigSet->new( &POSIX::SIGUSR1 );
=addset
Add a signal to a SigSet object.

	$sigset->addset( &POSIX::SIGUSR2 );
=delset
Remove a signal from the SigSet object.

	$sigset->delset( &POSIX::SIGUSR2 );
=emptyset
Initialize the SigSet object to be empty.

	$sigset->emptyset();
=fillset
Initialize the SigSet object to include all signals.

	$sigset->fillset();
=ismember
Tests the SigSet object to see if it contains a specific signal.

	if( $sigset->ismember( &POSIX::SIGUSR1 ) ){
		print "contains SIGUSR1\n";
	}
##########
==POSIX::Termios
=new
Create a new Termios object.  This object will be destroyed automatically
when it is no longer needed.

	$termios = POSIX::Termios->new;
=getiflag
Retrieve the c_iflag field of a termios object.

	$c_iflag = $termios->getiflag;
=getoflag
Retrieve the c_oflag field of a termios object.

	$c_oflag = $termios->getoflag;
=getcflag
Retrieve the c_cflag field of a termios object.

	$c_cflag = $termios->getcflag;
=getlflag
Retrieve the c_lflag field of a termios object.

	$c_lflag = $termios->getlflag;
=getcc
Retrieve a value from the c_cc field of a termios object.  The c_cc field is
an array so an index must be specified.

	$c_cc[1] = $termios->getcc(1);
=getospeed
Retrieve the output baud rate.

	$ospeed = $termios->getospeed;
=getispeed
Retrieve the input baud rate.

	$ispeed = $termios->getispeed;
=setiflag
Set the c_iflag field of a termios object.

	$termios->setiflag( &POSIX::BRKINT );
=setoflag
Set the c_oflag field of a termios object.

	$termios->setoflag( &POSIX::OPOST );
=setcflag
Set the c_cflag field of a termios object.

	$termios->setcflag( &POSIX::CLOCAL );
=setlflag
Set the c_lflag field of a termios object.

	$termios->setlflag( &POSIX::ECHO );
=setcc
Set a value in the c_cc field of a termios object.  The c_cc field is an
array so an index must be specified.

	$termios->setcc( 1, &POSIX::VEOF );
=setospeed
Set the output baud rate.

	$termios->setospeed( &POSIX::B9600 );
=setispeed
Set the input baud rate.

	$termios->setispeed( &POSIX::B9600 );
##
=setattr
=getattr
##########
==FileHandle
=new
=new_from_fd
=flush
=getc
=ungetc
=seek
=setbuf
=error
=clearerr
=tell
=getpos
=gets
=close
=new_tmpfile
=eof
=fileno
=setpos
=setvbuf
##########
==POSIX
=tolower+lc
=toupper+uc
=remove+unlink
=fabs+abs
=strstr+index
##
=closedir++
=readdir++
=rewinddir++
=fcntl++
=getgrgid++
=getgrnam++
=atan2++
=cos++
=exp++
=abs++
=log++
=sin++
=sqrt++
=getpwnam++
=getpwuid++
=kill++
=getc++
=rename++
=exit++
=system++
=chmod++
=mkdir++
=stat++
=umask++
=gmtime++
=localtime++
=time++
=alarm++
=chdir++
=chown++
=fork++
=getlogin++
=getpgrp++
=getppid++
=link++
=rmdir++
=sleep++
=unlink++
=utime++
##
=perror+C
=pause+C
=tzset+C
=difftime+C
=ctime+C
=clock+C
=asctime+C
=strcoll+C
=abort+C
=tcgetpgrp+C
=setsid+C
=_exit+C
=tanh+C
=tan+C
=sinh+C
=log10+C
=ldexp+C
=fmod+C
=floor+C
=cosh+C
=ceil+C
=atan+C
=asin+C
=acos+C
##
=isatty
Returns a boolean indicating whether the specified filehandle is connected
to a tty.
=setuid
Sets the real user id for this process.
=setgid
Sets the real group id for this process.
=getpid
Returns the process's id.
=getuid
Returns the user's id.
=getegid
Returns the effective group id.
=geteuid
Returns the effective user id.
=getgid
Returns the user's real group id.
=getgroups
Returns the ids of the user's supplementary groups.
=getcwd
Returns the name of the current working directory.
=strerror
Returns the error string for the specified errno.
=getenv
Returns the value of the specified enironment variable.
=getchar
Returns one character from STDIN.
=raise
Sends the specified signal to the current process.
=gets
Returns one line from STDIN.
=printf
Prints the specified arguments to STDOUT.
=rewind
Seeks to the beginning of the file.
##
=tmpnam
Returns a name for a temporary file.

	$tmpfile = POSIX::tmpnam();
=cuserid
Get the character login name of the user.

	$name = POSIX::cuserid();
=ctermid
Generates the path name for controlling terminal.

	$path = POSIX::ctermid();
=times
The times() function returns elapsed realtime since some point in the past
(such as system startup), user and system times for this process, and user
and system times used by child processes.  All times are returned in clock
ticks.

    ($realtime, $user, $system, $cuser, $csystem) = POSIX::times();

Note: Perl's builtin C<times()> function returns four values, measured in
seconds.
=pow
Computes $x raised to the power $exponent.

	$ret = POSIX::pow( $x, $exponent );
=errno
Returns the value of errno.

	$errno = POSIX::errno();
=sysconf
Retrieves values of system configurable variables.

The following will get the machine's clock speed.

	$clock_ticks = POSIX::sysconf( &POSIX::_SC_CLK_TCK );
=pathconf
Retrieves the value of a configurable limit on a file or directory.

The following will determine the maximum length of the longest allowable
pathname on the filesystem which holds C</tmp>.

	$path_max = POSIX::pathconf( "/tmp", &POSIX::_PC_PATH_MAX );
=access
Determines the accessibility of a file.

	if( POSIX::access( "/", &POSIX::R_OK ) ){
		print "have read permission\n";
	}
=setlocale
Modifies and queries program's locale.

The following will set the traditional UNIX system locale behavior.

This document generated by ./mkposixman.PL version 19951212.
##
=waitpid
=wait
=fstat
=sprintf
=opendir
=creat
=ttyname
=tzname
=fpathconf
=mktime
=tcsendbreak
=tcflush
=tcflow
=tcdrain
=tcsetpgrp
=mkfifo
=strxfrm
=wctomb
=wcstombs
=mbtowc
=mbstowcs
=mblen
=write
=uname
=setpgid
=read
=pipe
=nice
=lseek
=dup2
=dup
=close
=sigsuspend
=sigprocmask
=sigpending
=sigaction
=modf
=frexp
=localeconv
=open
=isxdigit
=isupper
=isspace
=ispunct
=isprint
=isgraph
=isdigit
=iscntrl
=isalpha
=isalnum
=islower
=assert
=strftime
##########
==POSIX::SigAction
=new
Creates a new SigAction object.  This object will be destroyed automatically
when it is no longer needed.
