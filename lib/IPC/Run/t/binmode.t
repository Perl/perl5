#!/usr/bin/perl -w

=head1 NAME

binary.t - Test suite for IPC::Run binary functionality

=cut

BEGIN { 
    if( $ENV{PERL_CORE} ) {
	use Cwd;
        $^X = Cwd::abs_path($^X);
	$^X = qq("$^X") if $^X =~ /\s/;
        chdir '../lib/IPC/Run' if -d '../lib/IPC/Run';
        unshift @INC, 'lib', '../..';
    }
}

## Handy to have when our output is intermingled with debugging output sent
## to the debugging fd.
$| = 1 ;
select STDERR ; $| = 1 ; select STDOUT ;

use strict ;

use Test ;

use IPC::Run qw( harness run binary ) ;

sub Win32_MODE() ;
*Win32_MODE = \&IPC::Run::Win32_MODE ;

my $crlf_text = "Hello World\r\n" ;

my $text     = $crlf_text ;
$text =~ s/\r//g if Win32_MODE ;

my $nl_text  = $crlf_text ;
$nl_text =~ s/\r//g ;

my @perl    = ( $^X ) ;

my $emitter_script = q{ binmode STDOUT ; print "Hello World\r\n" } ;
my @emitter = ( @perl, '-e', $emitter_script ) ;

my $reporter_script =
   q{ binmode STDIN ; $_ = join "", <>; s/([\000-\037])/sprintf "\\\\0x%02x", ord $1/ge; print } ;
my @reporter = ( @perl, '-e', $reporter_script ) ;

my $in ;
my $out ;
my $err ;

sub f($) {
   my $s = shift ;
   $s =~ s/([\000-\027])/sprintf "\\0x%02x", ord $1/ge ;
   $s
}

my @tests = (
## Parsing tests
sub { ok eval { harness [], '>', binary, \$out } ? 1 : $@, 1 } ,
sub { ok eval { harness [], '>', binary, "foo" } ? 1 : $@, 1 },
sub { ok eval { harness [], '<', binary, \$in  } ? 1 : $@, 1 },
sub { ok eval { harness [], '<', binary, "foo" } ? 1 : $@, 1 },

## Testing from-kid now so we can use it to test stdin later
sub { ok run \@emitter, ">", \$out },
sub { ok f $out, f $text, "no binary" },

sub { ok run \@emitter, ">", binary, \$out },
sub { ok f $out, f $crlf_text, "out binary" },

sub { ok run \@emitter, ">", binary( 0 ), \$out },
sub { ok f $out, f $text, "out binary 0" },

sub { ok run \@emitter, ">", binary( 1 ), \$out },
sub { ok f $out, f $crlf_text, "out binary 1" },

## Test to-kid
sub { ok run \@reporter, "<", \$nl_text, ">", \$out },
sub { ok $out, "Hello World" . ( Win32_MODE ? "\\0x0d" : "" ) . "\\0x0a", "reporter < \\n" },

sub { ok run \@reporter, "<", binary, \$nl_text, ">", \$out },
sub { ok $out, "Hello World\\0x0a", "reporter < binary \\n" },

sub { ok run \@reporter, "<", binary, \$crlf_text, ">", \$out },
sub { ok $out, "Hello World\\0x0d\\0x0a", "reporter < binary \\r\\n" },

sub { ok run \@reporter, "<", binary( 0 ), \$nl_text, ">", \$out },
sub { ok $out, "Hello World" . ( Win32_MODE ? "\\0x0d" : "" ) . "\\0x0a", "reporter < binary(0) \\n" },

sub { ok run \@reporter, "<", binary( 1 ), \$nl_text, ">", \$out },
sub { ok $out, "Hello World\\0x0a", "reporter < binary(1) \\n" },

sub { ok run \@reporter, "<", binary( 1 ), \$crlf_text, ">", \$out },
sub { ok $out, "Hello World\\0x0d\\0x0a", "reporter < binary(1) \\r\\n" },
) ;

plan tests => scalar @tests ;

$_->() for ( @tests ) ;
