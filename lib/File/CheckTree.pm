package File::CheckTree;

our $VERSION = '4.1';

use 5.006;
require Exporter;
use warnings;

=head1 NAME

validate - run many filetest checks on a tree

=head1 SYNOPSIS

    use File::CheckTree;

    $warnings += validate( q{
	/vmunix                 -e || die
	/boot                   -e || die
	/bin                    cd
	    csh                 -ex
	    csh                 !-ug
	    sh                  -ex
	    sh                  !-ug
	/usr                    -d || warn "What happened to $file?\n"
    });

=head1 DESCRIPTION

The validate() routine takes a single multiline string consisting of
lines containing a filename plus a file test to try on it.  (The
file test may also be a "cd", causing subsequent relative filenames
to be interpreted relative to that directory.)  After the file test
you may put C<|| die> to make it a fatal error if the file test fails.
The default is C<|| warn>.  The file test may optionally have a "!' prepended
to test for the opposite condition.  If you do a cd and then list some
relative filenames, you may want to indent them slightly for readability.
If you supply your own die() or warn() message, you can use $file to
interpolate the filename.

Filetests may be bunched:  "-rwx" tests for all of C<-r>, C<-w>, and C<-x>.
Only the first failed test of the bunch will produce a warning.

The routine returns the number of warnings issued.

=cut

our @ISA = qw(Exporter);
our @EXPORT = qw(validate);

sub validate {
    local($file,$test,$warnings,$oldwarnings);
    $warnings = 0;
    foreach $check (split(/\n/,$_[0])) {
	next if $check =~ /^#/;
	next if $check =~ /^$/;
	($file,$test) = split(' ',$check,2);
	if ($test =~ s/^(!?-)(\w{2,}\b)/$1Z/) {
	    $testlist = $2;
	    @testlist = split(//,$testlist);
	}
	else {
	    @testlist = ('Z');
	}
	$oldwarnings = $warnings;
	foreach $one (@testlist) {
	    $this = $test;
	    $this =~ s/(-\w\b)/$1 \$file/g;
	    $this =~ s/-Z/-$one/;
	    $this .= ' || warn' unless $this =~ /\|\|/;
	    $this =~ s/^(.*\S)\s*\|\|\s*(die|warn)$/$1 || 
		valmess('$2','$1')/;
	    $this =~ s/\bcd\b/chdir (\$cwd = \$file)/g;
	    eval $this;
	    last if $warnings > $oldwarnings;
	}
    }
    $warnings;
}

our %Val_Switch = (
	'r' => sub { "$_[0] is not readable by uid $>." },
	'w' => sub { "$_[0] is not writable by uid $>." },
	'x' => sub { "$_[0] is not executable by uid $>." },
	'o' => sub { "$_[0] is not owned by uid $>." },
	'R' => sub { "$_[0] is not readable by you." },
	'W' => sub { "$_[0] is not writable by you." },
	'X' => sub { "$_[0] is not executable by you." },
	'O' => sub { "$_[0] is not owned by you." },
	'e' => sub { "$_[0] does not exist." },
	'z' => sub { "$_[0] does not have zero size." },
	's' => sub { "$_[0] does not have non-zero size." },
	'f' => sub { "$_[0] is not a plain file." },
	'd' => sub { "$_[0] is not a directory." },
	'l' => sub { "$_[0] is not a symbolic link." },
	'p' => sub { "$_[0] is not a named pipe (FIFO)." },
	'S' => sub { "$_[0] is not a socket." },
	'b' => sub { "$_[0] is not a block special file." },
	'c' => sub { "$_[0] is not a character special file." },
	'u' => sub { "$_[0] does not have the setuid bit set." },
	'g' => sub { "$_[0] does not have the setgid bit set." },
	'k' => sub { "$_[0] does not have the sticky bit set." },
	'T' => sub { "$_[0] is not a text file." },
	'B' => sub { "$_[0] is not a binary file." },
);

sub valmess {
    my($disposition,$this) = @_;
    my $file = $cwd . '/' . $file unless $file =~ m|^/|s;
    
    my $ferror;
    if ($this =~ /^(!?)-(\w)\s+\$file\s*$/) {
	my($neg,$ftype) = ($1,$2);

        $ferror = $Val_Switch{$tmp}->($file);

	if ($neg eq '!') {
	    $ferror =~ s/ is not / should not be / ||
	    $ferror =~ s/ does not / should not / ||
	    $ferror =~ s/ not / /;
	}
    }
    else {
	$this =~ s/\$file/'$file'/g;
	$ferror = "Can't do $this.\n";
    }
    die "$ferror\n" if $disposition eq 'die';
    warn "$ferror\n";
    ++$warnings;
}

1;

