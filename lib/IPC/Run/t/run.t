#!/usr/bin/perl -w

=head1 NAME

run.t - Test suite for IPC::Run::run, etc.

=cut

BEGIN { 
    if( $ENV{PERL_CORE} ) {
        chdir '../lib/IPC/Run' if -d '../lib/IPC/Run';
        unshift @INC, 'lib', '../..';
	use Cwd;
        $^X = Cwd::abs_path($^X);
	$^X = qq("$^X") if $^X =~ /\s/;
    }
}


## Handy to have when our output is intermingled with debugging output sent
## to the debugging fd.
$| = 1 ;
select STDERR ; $| = 1 ; select STDOUT ;

use strict ;

use Test ;

use IPC::Run::Debug qw( _map_fds );
use IPC::Run qw( :filters :filter_imp start filter_tests Win32_MODE ) ;

sub run { IPC::Run::run( ref $_[0] ? ( noinherit => 1 ) : (), @_ ) }

use UNIVERSAL qw( isa ) ;

## Test at least some of the win32 PATHEXT logic
my $perl = $^X;
$perl =~ s/\.\w+\z// if Win32_MODE;

## Win32 does not support a lot of things that Unix does.  These
## skip_unless subs help that.
##
## TODO: There are also a few things that Win32 supports (passing Win32 OS
## handles) that we should test for, conversely.
sub skip_unless_subs(&) {
   if ( Win32_MODE ) {
      return sub {
         skip "Can't spawn subroutines on $^O", 0 ;
      } ;
   }
   shift ;
}

sub skip_unless_shell(&) {
   if ( Win32_MODE ) {
      return sub {
         skip "$^O's shell returns 0 even if last command doesn't", 0 ;
      } ;
   }
   shift ;
}

sub skip_unless_high_fds(&) {
   if ( Win32_MODE ) {
      return sub {
         skip "$^O does not allow redirection of file descriptors > 2", 0 ;
      } ;
   }
   shift ;
}


sub _unlink {
   my ( $f ) = @_;
   my $tries;
   while () {
      return if unlink $f;
      if ( $^O =~ /Win32/ && ++$tries <= 10 ) {
         print STDOUT "# Waiting for Win32 to allow $f to be unlinked ($!)\n";
	 select undef, undef, undef, 0.1;
	 next;
      }
      die "$! unlinking $f at ", join( ", line ", (caller)[1,2] ), "\n";
   }
}


my $text    = "Hello World\n" ;

my @perl    = ( $perl ) ;

my $emitter_script =
   qq{print '$text' ; print STDERR uc( '$text' ) unless \@ARGV } ;
my @emitter = ( @perl, '-e', $emitter_script ) ;

my $in ;
my $out ;
my $err ;

my $in_file  = 'run.t.in' ;
my $out_file = 'run.t.out' ;
my $err_file = 'run.t.err' ;

my $h ;

# initialized during the first test
my $fd_map;

sub slurp($) {
   my ( $f ) = @_ ;
   open( S, "<$f" ) or return "$! $f" ;
   my $r = join( '', <S> ) ;
   close S or warn "$!: $f";
   select 0.1 if $^O =~ /Win32/;
   return $r ;
}


sub spit($$) {
   my ( $f, $s ) = @_ ;
   open( S, ">$f" ) or die "$! $f" ;
   print S $s or die "$! $f" ;
   close S or die "$! $f" ;
}

##
## A grossly inefficient filter to test filter
## chains.  It's inefficient because we want to make sure that the
## filter chain flushing logic works.  The inefficiency is that it
## doesn't process as much input as it could each call, so lots of calls
## are required.
##
sub alt_casing_filter {
   my ( $in_ref, $out_ref ) = @_ ;
   return input_avail && do {
      $$out_ref .= lc( substr( $$in_ref, 0, 1, '' ) ) ;
      1 ;
   } && (
      ! input_avail || do {
	 $$out_ref .= uc( substr( $$in_ref, 0, 1, '' ) ) ;
         1 ;
      }
   ) ;
}


sub case_inverting_filter {
   my ( $in_ref, $out_ref ) = @_ ;
   return input_avail && do {
      $$in_ref =~ tr/a-zA-Z/A-Za-z/ ;
      $$out_ref .= $$in_ref ;
      $$in_ref = '' ;
      1 ;
   } ;
}


sub eok {
   my ( $got, $exp ) = ( shift, shift );
   $got =~ s/([\000-\037])/sprintf "\\0x%02x", ord $1/ge if defined $exp;
   $exp =~ s/([\000-\037])/sprintf "\\0x%02x", ord $1/ge if defined $exp;
   @_ = ( $got, $exp, @_ );
   goto &ok;
}


my $r ;


my @tests = (

sub { ok( _map_fds, $fd_map ) ; $fd_map = _map_fds },

##
## Internal testing
##
filter_tests(
   "alt_casing_filter",
   "Hello World",
   ["hElLo wOrLd" =~ m/(..?)/g],
   \&alt_casing_filter
),

sub { ok( _map_fds, $fd_map ) ; $fd_map = _map_fds },

filter_tests(
   "case_inverting_filter",
   "Hello World",
   "hELLO wORLD",
   \&case_inverting_filter
),

sub { ok( _map_fds, $fd_map ) ; $fd_map = _map_fds },

##
## Calling the local system shell
##
sub { ok run qq{$perl -e exit} },
sub { ok $?, 0 },

sub { ok( _map_fds, $fd_map ) ; $fd_map = _map_fds },

skip_unless_shell { ok ! run qq{$perl -e 'exit(42)'} },
skip_unless_shell { ok $?                          },
skip_unless_shell { ok $? >> 8, 42                 },

sub { ok( _map_fds, $fd_map ) ; $fd_map = _map_fds },

##
## Simple commands, not executed via shell
##
sub { ok( run $perl, qw{-e exit}       ) },
sub { ok( $?, 0 ) },

sub { ok( _map_fds, $fd_map ) ; $fd_map = _map_fds },

sub { ok( ! run $perl, qw{-e exit(42)} ) },
sub { ok( $? ) },
sub { ok $? >> 8, 42 },

sub { ok( _map_fds, $fd_map ) ; $fd_map = _map_fds },

##
## A function
##
skip_unless_subs { ok run sub{}           },
skip_unless_subs { ok $?, 0               },
skip_unless_subs { ok !run sub{ exit 42 } },
skip_unless_subs { ok $?                  },
skip_unless_subs { ok $? >> 8, 42         },

sub { ok( _map_fds, $fd_map ) ; $fd_map = _map_fds },

##
## A function, and an init function
##
skip_unless_subs {
   my $e = 0 ;
   ok(
      ! run(
	 sub{ exit($e) },
	 init => sub { $e = 42 }
      )
   ) ;
},
skip_unless_subs { ok( $? ) },

sub { ok( _map_fds, $fd_map ) ; $fd_map = _map_fds },

##
## scalar ref I & O redirection using op tokens
##
sub {
   $out = 'REPLACE ME' ;
   $fd_map = _map_fds ;
   $r = run [ @emitter, "nostderr" ], '>', \$out ;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },
sub { eok( $out,        $text       ) },

sub {
   $out = 'REPLACE ME' ;
   $fd_map = _map_fds ;
   $r = run [ @emitter, "nostderr" ], '<', \undef, '>', \$out ;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },
sub { eok( $out,        $text       ) },
sub {
   $in = $emitter_script ;
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   $fd_map = _map_fds ;
   $r = run \@perl, '<', \$in, '>', \$out, '2>', \$err, ;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

sub { eok( $in,     $emitter_script ) },
sub { eok( $out,        $text       ) },
sub { eok( $err,    uc( $text )     ) },
##
## scalar ref I & O redirection, succinct mode.
##
sub {
   $in = $emitter_script ;
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   $fd_map = _map_fds ;
   $r = run \@perl, \$in, \$out, \$err ;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

sub { eok( $in,     $emitter_script ) },
sub { eok( $out,        $text       ) },
sub { eok( $err,    uc( $text )     ) },

##
## Long output, to test for blocking read.
##
## Assume pipe buffer length <= 10000, need to double that to assure enough
## chars to fill a buffer so.  This test adapted from a test submitted by
## Borislav Deianov <borislav@ensim.com>.
sub {
   $in = "-" x 20000 . "end\n" ;
   $out = 'REPLACE ME' ;
   $fd_map = _map_fds ;
   $r = run [ $perl, qw{-e print"-"x20000;<STDIN>;} ], \$in, \$out ;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

sub { ok( length $out, 20000 ) },
sub { ok( $out !~ /[^-]/ ) },


##
## Long output run through twice
##
## Adapted from a stress test by Aaron Elkiss <aelkiss@wam.umd.edu>
##
sub {
   $h = start [$perl, qw( -pe BEGIN{$|=1}1 )], \$in, \$out;

   $in = "\n";
   $out = "";
   pump $h until length $out;
   ok $out eq "\n";
},

sub {
   my $long_string = "x" x 20000 . "DOC2\n";
   $in = $long_string;
   $out = "";
   my $ok_1 = eval {
      pump $h until $out =~ /DOC2/;
      1;
   };
   my $x = $@;
   my $ok_2 = eval {
      finish $h;
      1;
   };

   $x = $@ if $ok_1 && ! $ok_2;

   if ( $ok_1 && $ok_2 ) {
      ok $long_string eq $out;
   }
   else {
       $x =~ s/(x+)/sprintf "...%d \"x\" chars...", length $1/e;
       ok $x, "";
   }
},

##
## child function, scalar ref I & O redirection, succinct mode.
##
skip_unless_subs {
   $in = $text ;
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   $fd_map = _map_fds ;
   $r = run(
      sub { while (<>) { print ; print STDERR uc( $_ ) } },
         \$in, \$out, \$err 
      ) ;
   ok( $r ) ;
},
skip_unless_subs { ok ! $? },
skip_unless_subs { ok( _map_fds, $fd_map ) },

skip_unless_subs { eok( $in,         $text       ) },
skip_unless_subs { eok( $out,        $text       ) },
skip_unless_subs { eok( $err,    uc( $text )     ) },

##
## here document as input
##
sub {
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   $fd_map = _map_fds ;
   $r = run \@perl, \<<TOHERE, \$out, \$err ;
$emitter_script
TOHERE
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

sub { eok( $out,    $text       ) },
sub { eok( $err,    uc( $text ) ) },

##
## undef as input
##
sub {
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   $fd_map = _map_fds ;
   $r = run \@perl, \undef, \$out, \$err ;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

sub { eok( $out, '' ) },
sub { eok( $err, '' ) },

##
## filehandle input redirection
##
sub {
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   $fd_map = _map_fds ;
   spit( $in_file, $emitter_script ) ;
   open( F, "<$in_file" ) or die "$! $in_file" ;
   $r = run \@perl, \*F, \$out, \$err ;
   close F ;
   unlink $in_file or warn "$! $in_file" ;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

sub { eok( $out,    $text       ) },
sub { eok( $err,    uc( $text ) ) },

##
## input redirection via caller writing directly to a pipe
##
sub {
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   $fd_map = _map_fds ;
   $h = start \@perl, '<pipe', \*IN, '>', \$out, '2>', \$err ;
   ## Assume this won't block...
   print IN $emitter_script ;
   close IN or warn $! ;
   $r = $h->finish ;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

sub { eok( $out,    $text       ) },
sub { eok( $err,    uc( $text ) ) },

##
## filehandle input redirection, passed via *F{IO}
##
sub {
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   $fd_map = _map_fds ;
   spit( $in_file, $emitter_script ) ;
   open( F, "<$in_file" ) or die "$! $in_file" ;
   $r = run \@perl, *F{IO}, \$out, \$err ;
   close F ;
   _unlink $in_file;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

sub { eok( $out,    $text       ) },
sub { eok( $err,    uc( $text ) ) },

##
## filehandle output redirection
##
sub {
   $fd_map = _map_fds ;
   open( OUT, ">$out_file" ) or die "$! $out_file" ;
   open( ERR, ">$err_file" ) or die "$! $err_file" ;
   print OUT     "out: " ;
   print ERR uc( "err: " ) ;
   $r = run \@emitter, \undef, \*OUT, \*ERR ;
   print OUT " more out data" ;
   print ERR uc( " more err data" ) ;
   close OUT ;
   close ERR ;
   $out = slurp( $out_file ) ;
   $err = slurp( $err_file ) ;
   _unlink $out_file;
   _unlink $err_file;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

sub { eok( $out,     "out: $text more out data"   ) },
sub { eok( $err, uc( "err: $text more err data" ) ) },

##
## filehandle output redirection via a pipe that is returned to the caller
##
sub {
   $fd_map = _map_fds ;
   my $r = run \@emitter, \undef, '>pipe', \*OUT, '2>pipe', \*ERR ;
   $out = '' ;
   $err = '' ;
   read OUT, $out, 10000 or warn $!;
   read ERR, $err, 10000 or warn $!;
   close OUT or warn $! ;
   close ERR or warn $! ;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

sub { eok( $out,     $text   ) },
sub { eok( $err, uc( $text ) ) },

##
## sub I & O redirection
##
sub {
   $in = $emitter_script ;
   $out = undef ;
   $err = undef ;
   $fd_map = _map_fds ;
   $r = run(
      \@perl,
      '<',  sub { my $f = $in ; $in = undef ; return $f },
      '>',  sub { $out .= shift },
      '2>', sub { $err .= shift },
   ) ;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

sub { eok( $out,        $text       ) },
sub { eok( $err,    uc( $text )     ) },

##
## input redirection from a file
##
sub {
   $out = undef ;
   $err = undef ;
   $fd_map = _map_fds ;
   spit( $in_file, $emitter_script ) ;
   $r = run(
      \@perl,
      "<$in_file",
      '>',  sub { $out .= shift },
      '2>', sub { $err .= shift },
   ) ;
   _unlink $in_file;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

sub { eok( $out, $text ) },
sub { eok( $err, uc( $text ) ) },

##
## reading input from a non standard fd
##
skip_unless_high_fds {
   $out = undef ;
   $err = undef ;
   $fd_map = _map_fds ;
   $r = run(
      ## FreeBSD doesn't guarantee that fd 3 or 4 are available, so
      ## don't assume, go for 5.
      [ @perl, '-le', 'open( STDIN, "<&5" ) or die $! ; print <STDIN>' ],
      "5<", \"Hello World",
      '>',  \$out,
      '2>', \$err,
   ) ;
   ok( $r ) ;
},
skip_unless_high_fds { ok( ! $? ) },
skip_unless_high_fds { ok( _map_fds, $fd_map ) },

skip_unless_high_fds { eok( $out, $text ) },
skip_unless_high_fds { eok( $err, '' ) },

##
## duping input descriptors and an input descriptor > 0
##
skip_unless_high_fds {
   $in  = $emitter_script ;
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   $fd_map = _map_fds ;
   $r = run(
      \@perl, 
	 '>',  \$out, 
	 '2>', \$err, 
	 '3<', \$in,
	 '0<&3',
   ) ;
   ok( $r ) ;
},
skip_unless_high_fds { ok( ! $? ) },
skip_unless_high_fds { ok( _map_fds, $fd_map ) },
skip_unless_high_fds { eok( $in,     $emitter_script ) },
skip_unless_high_fds { eok( $out,     $text   ) },
skip_unless_high_fds { eok( $err, uc( $text ) ) },

##
## closing input descriptors
##
sub {
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   $fd_map = _map_fds ;
   spit( $in_file, $emitter_script ) ;
   $r = run(
      [ @perl, '-e', '$l = readline *STDIN or die $! ; print $l' ], 
	 '>',  \$out, 
	 '2>', \$err, 
	 '<',  $in_file,
	 '0<&-',
   ) ;
   _unlink $in_file;
   ok( ! $r ) ;
},
sub { ok( $? ) },
sub { ok( _map_fds, $fd_map ) },
sub { eok( $out, ''  ) },
#sub { ok( $err =~ /file descriptor/i ? "Bad file descriptor error" : $err, "Bad file descriptor error" ) },
# XXX This should be use Errno; if $!{EBADF}. --rs
sub { ok( length $err ? "Bad file descriptor error" : $err, "Bad file descriptor error" ) },

##
## input redirection from a non-existent file
##
sub {
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   $fd_map = _map_fds ;
   my $bad_file = "$in_file.nonexistant" ;
   _unlink $bad_file if -e $bad_file;
   eval {
      $r = run \@perl, ">$out_file", "<$bad_file" ;
   } ;
   if ( $@ =~ /\Q$bad_file\E/ ) {
      ok 1 ;
   }
   else {
      ok $@, "qr/\Q$bad_file\E/" ;
   }
},
sub { ok( _map_fds, $fd_map ) },

##
## output redirection to a file w/ creation or truncation
##
sub {
   $fd_map = _map_fds ;
   _unlink $out_file if -x $out_file;
   _unlink $err_file if -x $err_file;
   $r = run(
      \@emitter,
      ">$out_file",
      "2>$err_file",
   ) ;
   $out = slurp( $out_file ) ;
   $err = slurp( $err_file ) ;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

sub { eok( $out, $text ) },
sub { eok( $err, uc( $text ) ) },

##
## output file redirection, w/ truncation
##
sub {
   $fd_map = _map_fds ;
   spit( $out_file, 'out: ' ) ;
   spit( $err_file, 'ERR: ' ) ;
   $r = run(
      \@emitter,
      ">$out_file",
      "2>$err_file",
   ) ;
   $out = slurp( $out_file ) ; _unlink $out_file;
   $err = slurp( $err_file ) ; _unlink $err_file;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

sub { eok( $out, $text ) },
sub { eok( $err, uc( $text ) ) },

##
## output file redirection w/ append
##
sub {
   spit( $out_file, 'out: ' ) ;
   spit( $err_file, 'ERR: ' ) ;
   $fd_map = _map_fds ;
   $r = run(
      \@emitter,
      ">>$out_file",
      "2>>$err_file",
   ) ;
   $out = slurp( $out_file ) ;
   _unlink $out_file;
   $err = slurp( $err_file ) ;
   _unlink $err_file;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

sub { eok( $out, "out: $text" ) },
sub { eok( $err, uc( "err: $text" ) ) },
##
## dup()ing output descriptors
##
sub {
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   $fd_map = _map_fds ;
   $r = run \@emitter, '>', \$out, '2>', \$err, '2>&1' ;
   ok( $r ) ;
},
sub  { ok( ! $? ) },
sub  { ok( _map_fds, $fd_map ) },
sub  { $out =~ /(?:$text){2}/i ? ok 1 : ok $out, "qr/($text){2}/i" },
sub  { eok( $err, '' ) },

##
## stderr & stdout redirection to the same file via >&word
##
sub {
   $fd_map = _map_fds ;
   _unlink $out_file if -x $out_file;
   $r = run \@emitter, ">&$out_file" ;
   $out = slurp( $out_file ) ;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

sub { ok( $out =~ qr/(?:$text){2}/i ) },

##
## Non-zero exit value, command with args, no redirects.
##
sub {
   $fd_map = _map_fds ;
   $r = run [ @perl, '-e', 'exit(42)' ] ;
   ok( !$r ) ;
},
sub { ok( $?, 42 << 8 ) },
sub { ok( _map_fds, $fd_map ) },

##
## Zero exit value, command with args, no redirects.
##
sub {
   $fd_map = _map_fds ;
   $r = run [ @perl, qw{ -e exit }] ;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

##
## dup()ing output descriptors that collide.
##
## This test assumes that our caller doesn't leave a lot of fds opened,
## and assumes that $out_file will be opened on fd 3, 4 or 5.
##
skip_unless_high_fds {
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   _unlink $out_file if -x $out_file;
   $fd_map = _map_fds ;
   $r = run(
      \@emitter,
      "<", \"",
      "3>&1", "4>&1", "5>&1",
      ">$out_file",
      '2>', \$err,
   ) ;
   $out = slurp( $out_file ) ;
   _unlink $out_file;
   ok( $r ) ;
},
skip_unless_high_fds { ok( ! $? ) },
skip_unless_high_fds { ok( _map_fds, $fd_map ) },
skip_unless_high_fds { eok( $out,     $text   ) },
skip_unless_high_fds { eok( $err, uc( $text ) ) },

##
## Pipelining
##
sub {
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   $fd_map = _map_fds ;
   $r = run(
      [ @perl, '-lane', 'print STDERR "1:$_" ; print uc($F[0])," ",$F[1]'],
         \"Hello World",
  '|',[ @perl, '-lane', 'print STDERR "2:$_" ; print $F[0]," ",lc($F[1])'],
	 \$out,
	 \$err,
   ) ;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },
sub { eok( $out, "HELLO world\n" ) },
sub { eok( $err, "1:Hello World\n2:HELLO World\n" ) },

##
## Parallel (unpiplined) processes
##
sub {
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   $fd_map = _map_fds ;
   $r = run(
      [ @perl, '-lane', 'print STDERR "1:$_" ; print uc($F[0])," ",$F[1]' ],
         \"Hello World",
 '&', [ @perl, '-lane', 'print STDERR "2:$_" ; print $F[0]," ",lc( $F[1] )' ],
	 \"Hello World",
	 \$out,
	 \$err,
   ) ;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },
sub { ok( $out =~ qr/^(?:HELLO World\n|Hello world\n){2}$/s ) },
sub { ok( $err =~ qr/^(?:[12]:Hello World.*){2}$/s ) },

##
## A few error cases...
##
sub {
   eval { $r = run \@perl, '<', [], [] } ;
   ok( $@ =~ qr/not allowed/ ) ;
},

sub {
   eval { $r = run \@perl, '>', [], [] } ;
   ok( $@ =~ qr/not allowed/ ) ;
},

(
   map {
      my $foo = $_ ;
      sub {
	 eval { $r = run $foo, [] } ;
	 ok( $@ =~ qr/command/ ) ;
      }
   } qw( | & < > >& 1>&2 >file <file 2<&1 <&- 3<&- )
),
sub {
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   $fd_map = _map_fds ;
   eval {
      $r = run( \@emitter, '>', \$out, '2>', \$err,
	 _simulate_fork_failure => 1
      ) ;
   } ;
   ok( $@ ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

sub { eok( $out, '' ) },
sub { eok( $err, '' ) },

sub {
   $fd_map = _map_fds ;
   eval {
      $r = run \@perl, '<file', _simulate_open_failure => 1 ;
   } ;
   ok( $@ ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

sub {
   $fd_map = _map_fds ;
   eval {
      $r = run \@perl, '>file', _simulate_open_failure => 1 ;
   } ;
   ok( $@ ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

##
## harness, pump, run
##
sub {
   $in  = 'SHOULD BE UNCHANGED' ;
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   $? = 99 ;
   $fd_map = _map_fds ;
   $h = start(
      [ @perl, '-pe', 'BEGIN { $| = 1 } print STDERR uc($_)' ],
      \$in, \$out, \$err,
   ) ;
   ok( isa( $h, 'IPC::Run' ) ) ;
},
sub { ok( $?, 99 ) },

sub { eok( $in,  'SHOULD BE UNCHANGED' ) },
sub { eok( $out, '' ) },
sub { eok( $err, '' ) },
sub { ok( $h->pumpable ) },

sub {
   $in  = '' ;
   $? = 0 ;
   pump_nb $h for ( 1..100 ) ;
   ok( 1 ) ;
},
sub { eok( $in, '' ) },
sub { eok( $out, '' ) },
sub { eok( $err, '' ) },
sub { ok( $h->pumpable ) },

sub {
   $in  = $text ;
   $? = 0 ;
   pump $h until $out =~ /Hello World/ ;
   ok( 1 ) ;
},
sub { ok( ! $? ) },
sub { eok( $in, '' ) },
sub { eok( $out, $text ) },
sub { ok( $h->pumpable ) },

sub { ok( $h->finish ) },
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },
sub { eok( $out,     $text   ) },
sub { eok( $err, uc( $text ) ) },
sub { ok( ! $h->pumpable ) },

##
## start, run, run, run.  See Tom run.  A do-run-run, a-do-run-run.
##
sub {
   $in  = 'SHOULD BE UNCHANGED' ;
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   $fd_map = _map_fds ;
   $h = start(
      [ @perl, '-pe', 'binmode STDOUT ; binmode STDERR ; BEGIN { $| = 1 } print STDERR uc($_)' ],
	 \$in, \$out, \$err,
   ) ;
   ok( isa( $h, 'IPC::Run' ) ) ;
},

sub { eok( $in, 'SHOULD BE UNCHANGED' ) },
sub { eok( $out, '' ) },
sub { eok( $err, '' ) },
sub { ok( $h->pumpable ) },

sub { 
   $in  = $text ;
   ok( $h->finish )
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },
sub { eok( $in,      ''      ) },
sub { eok( $out,     $text   ) },
sub { eok( $err, uc( $text ) ) },
sub { ok( ! $h->pumpable ) },

sub { 
   $in  = $text ;
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   ok( $h->run )
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },
sub { eok( $in,      $text   ) },
sub { eok( $out,     $text   ) },
sub { eok( $err, uc( $text ) ) },
sub { ok( ! $h->pumpable ) },

sub { 
   $in  = $text ;
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   ok( $h->run )
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },
sub { eok( $in,      $text   ) },
sub { eok( $out,     $text   ) },
sub { eok( $err, uc( $text ) ) },
sub { ok( ! $h->pumpable ) },

##
## Output filters
##
sub {
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   $fd_map = _map_fds ;
   $r = run(
      \@emitter,
      '>',
         \&alt_casing_filter,
	 \&case_inverting_filter,
	 \$out,
      '2>', \$err,
   ) ;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

sub { eok( $out, "HeLlO WoRlD\n" ) },
sub { eok( $err, uc( $text ) ) },

##
## Input filters
##
sub {
   $out = 'REPLACE ME' ;
   $err = 'REPLACE ME' ;
   $fd_map = _map_fds ;
   $in = $text ;
   $r = run(
      [ @perl, '-pe', 'binmode STDOUT ; binmode STDERR ; print STDERR uc $_' ],
      '0<',
         \&case_inverting_filter,
	 \&alt_casing_filter,
	 \$in,
      '1>', \$out,
      '2>', \$err,
   ) ;
   ok( $r ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

sub { eok( $in,      $text   ) },
sub { eok( $out,    "HeLlO WoRlD\n" ) },
sub { eok( $err,    uc( $text ) ) },
) ;

plan tests => scalar @tests, todo => [ 69 ] ;

# Must do this this late as plan uses localtime, and localtime on darwin opens
# a file descriptor. Quite probably other operating systems do file descriptor
# things during the test setup.

$fd_map = _map_fds ;

$_->() for ( @tests ) ;
