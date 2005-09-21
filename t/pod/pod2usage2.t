#!/usr/bin/perl -w

use Test;

BEGIN {
  plan tests => 8;
}

eval "use Pod::Usage";

ok($@ eq '');

sub getoutput
{
  my ($code) = @_;
  my $pid = open(IN, "-|");
  unless(defined $pid) {
    die "Cannot fork: $!";
  }
  if($pid) {
    # parent
    my @out = <IN>;
    close(IN);
    my $exit = $?>>8;
    print "\nEXIT=$exit OUTPUT=+++\n@out+++\n";
    return($exit, join("",@out));
  }
  # child
  open(STDERR, ">&STDOUT");
  &$code;
  print "--NORMAL-RETURN--\n";
  exit 0;
}

sub compare
{
  my ($left,$right) = @_;
  $left =~ s/[\n]+/\n/sg;
  $right =~ s/[\n]+/\n/sg;
  $left =~ s/\s+/ /gm;
  $right =~ s/\s+/ /gm;
  $left eq $right;
}

# test 2
my ($exit, $text) = getoutput( sub { pod2usage() } );
ok($exit == 2 && compare($text, <<'EOT'));
Usage:
    frobnicate [ -r | --recursive ] [ -f | --force ] [ -n number ] file ...

EOT

# test 3
($exit, $text) = getoutput( sub { pod2usage(
  -message => 'You naughty person, what did you say?',
  -verbose => 1 ) } );
ok($exit == 1 && compare($text,<<'EOT'));
You naughty person, what did you say?
 Usage:
     frobnicate [ -r | --recursive ] [ -f | --force ] [ -n number ] file ...
 
 Options:
     -r | --recursive
         Run recursively.
 
     -f | --force
         Just do it!
 
     -n number
         Specify number of frobs, default is 42.
 
EOT

# test 4
($exit, $text) = getoutput( sub { pod2usage(
  -verbose => 2, -exit => 42 ) } );
ok($exit == 42 && compare($text,<<'EOT'));
NAME
     frobnicate - do what I mean

 SYNOPSIS
     frobnicate [ -r | --recursive ] [ -f | --force ] [ -n number ] file ...

 DESCRIPTION
     frobnicate does foo and bar and what not.

 OPTIONS
     -r | --recursive
         Run recursively.

     -f | --force
         Just do it!

     -n number
         Specify number of frobs, default is 42.

EOT

# test 5
($exit, $text) = getoutput( sub { pod2usage(0) } );
ok($exit == 0 && compare($text, <<'EOT'));
Usage:
     frobnicate [ -r | --recursive ] [ -f | --force ] [ -n number ] file ...

 Options:
     -r | --recursive
         Run recursively.

     -f | --force
         Just do it!

     -n number
         Specify number of frobs, default is 42.

EOT

# test 6
($exit, $text) = getoutput( sub { pod2usage(42) } );
ok($exit == 42 && compare($text, <<'EOT'));
Usage:
     frobnicate [ -r | --recursive ] [ -f | --force ] [ -n number ] file ...

EOT

# test 7
($exit, $text) = getoutput( sub { pod2usage(-verbose => 0, -exit => 'NOEXIT') } );
ok($exit == 0 && compare($text, <<'EOT'));
Usage:
     frobnicate [ -r | --recursive ] [ -f | --force ] [ -n number ] file ...

 --NORMAL-RETURN--
EOT

# test 8
($exit, $text) = getoutput( sub { pod2usage(-verbose => 99, -sections => 'DESCRIPTION') } );
ok($exit == 1 && compare($text, <<'EOT'));
Description:
     frobnicate does foo and bar and what not.

EOT



__END__

=head1 NAME

frobnicate - do what I mean

=head1 SYNOPSIS

B<frobnicate> S<[ B<-r> | B<--recursive> ]> S<[ B<-f> | B<--force> ]>
  S<[ B<-n> I<number> ]> I<file> ...

=head1 DESCRIPTION

B<frobnicate> does foo and bar and what not.

=head1 OPTIONS

=over 4

=item B<-r> | B<--recursive>

Run recursively.

=item B<-f> | B<--force>

Just do it!

=item B<-n> I<number>

Specify number of frobs, default is 42.

=back

=cut

