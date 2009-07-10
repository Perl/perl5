#
# $Id: piconv.t,v 0.1 2009/07/08 12:34:21 dankogai Exp $
#

BEGIN {
    if ( $ENV{'PERL_CORE'} ) {
        print "1..0 # Skip: Don't know how to test this within perl's core\n";
        exit 0;
    }
}

use strict;
use FindBin;
use File::Spec;
use IPC::Open3 qw(open3);
use IO::Select;
use Test::More;

sub run_cmd (;$$);

my $blib =
  File::Spec->rel2abs(
    File::Spec->catfile( $FindBin::RealBin, File::Spec->updir, 'blib' ) );
my $script = "$blib/script/piconv";
my @base_cmd = ( $^X, "-Mblib=$blib", $script );

plan tests => 5;

{
    my ( $st, $out, $err ) = run_cmd;
    is( $st, 0, 'status for usage call' );
    is( $out, undef );
    like( $err, qr{^piconv}, 'usage' );
}

{
    my($st, $out, $err) = run_cmd [qw(-S foobar -f utf-8 -t ascii), $script];
    like($err, qr{unknown scheme.*fallback}i, 'warning for unknown scheme');
}

{
    my ( $st, $out, $err ) = run_cmd [qw(-f utf-8 -t ascii ./non-existing/file)];
    like( $err, qr{can't open}i );
}

sub run_cmd (;$$) {
    my ( $args, $in ) = @_;
    $in ||= '';
    my ( $out, $err );
    my ( $in_fh, $out_fh, $err_fh );
    use Symbol 'gensym';
    $err_fh =
      gensym;    # sigh... otherwise stderr gets just to $out_fh, not to $err_fh
    my $pid = open3( $in_fh, $out_fh, $err_fh, @base_cmd, @$args )
      or die "Can't run @base_cmd @$args: $!";
    print $in_fh $in;
    my $sel = IO::Select->new( $out_fh, $err_fh );

    while ( my @ready = $sel->can_read ) {
        for my $fh (@ready) {
            if ( eof($fh) ) {
                $sel->remove($fh);
                last if !$sel->handles;
            }
            elsif ( $out_fh == $fh ) {
                my $line = <$fh>;
                $out .= $line;
            }
            elsif ( $err_fh == $fh ) {
                my $line = <$fh>;
                $err .= $line;
            }
        }
    }
    my $st = $?;
    ( $st, $out, $err );
}
