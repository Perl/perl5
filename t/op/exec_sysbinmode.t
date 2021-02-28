#!.perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

my $Perl = which_perl();
diag "perl: $Perl";

use File::Spec;
my (undef, $perldir) = File::Spec->splitpath( $Perl );

my $e_acute = "\xe9";   # e w/ acute accent
utf8::encode($e_acute);

#----------------------------------------------------------------------

{
    my $e_acute = $e_acute;
    utf8::upgrade($e_acute);

    my ($rpipe, $wpipe);
    pipe $rpipe, $wpipe;

    my $pid = fork;
    if ($pid) {
    }
    elsif (defined $pid) {
        use sysbinmode ":raw";

        close $rpipe;

        open STDOUT, '>&=', fileno $wpipe;

        exec { $Perl } $Perl, -e => 'print $ARGV[0]', '--', $e_acute;
    }
    else {
        die "fork: $!"
    }

    close $wpipe;

    waitpid $pid, 0;
    die "failed subprocess: $?" if $?;

    my $out = <$rpipe>;

    is($out, $e_acute, 'sysbinmode :raw - printed as expected');
}

#----------------------------------------------------------------------

{
    my $e_acute = "\xe9";
    utf8::downgrade($e_acute);

    my ($rpipe, $wpipe);
    pipe $rpipe, $wpipe;

    my $pid = fork;
    if ($pid) {
    }
    elsif (defined $pid) {
        use sysbinmode ":utf8";

        close $rpipe;

        open STDOUT, '>&=', fileno $wpipe;

        exec { $Perl } $Perl, -e => 'print $ARGV[0]', '--', $e_acute;
    }
    else {
        die "fork: $!"
    }

    close $wpipe;

    waitpid $pid, 0;
    die "failed subprocess: $?" if $?;

    my $out = <$rpipe>;

    my $e_acute2 = $e_acute;
    utf8::encode($e_acute2);

    is($out, $e_acute2, 'sysbinmode :utf8 - printed as expected');
}
