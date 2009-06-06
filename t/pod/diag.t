#!/usr/bin/perl
use warnings;
use strict;
use Test::More 'no_plan';
$|=1;

open my $diagfh, "<:raw", "pod/perldiag.pod"
  or die "Can't open pod/perldiag.pod: $!";

my %entries;
my $cur_entry;
while (<$diagfh>) {
  if (m/^=item (.*)/) {
    $cur_entry = $1;
  } elsif (m/^\((.)(?: ([a-z]+?))?\)/ and !$entries{$cur_entry}{severity}) {
    $entries{$cur_entry}{severity} = $1;
    $entries{$cur_entry}{category} = $2;
  }
}

my @todo = ('.');
while (@todo) {
  my $todo = shift @todo;
  next if $todo ~~ ['./t', './lib', './ext'];
  # opmini.c is just a copy of op.c, so there's no need to check again.
  next if $todo eq './opmini.c';
  if (-d $todo) {
    push @todo, glob "$todo/*";
  } elsif ($todo =~ m/\.(c|h)$/) {
    check_file($todo);
  }
}

sub check_file {
  my ($codefn) = @_;

  diag($codefn);

  open my $codefh, "<:raw", $codefn
    or die "Can't open $codefn: $!";

  my $listed_as;
  my $listed_as_line;
  my $sub = 'top of file';
  while (<$codefh>) {
    chomp;
    # Getting too much here isn't a problem; we only use this to skip
    # errors inside of XS modules, which should get documented in the
    # docs for the module.
    if (m<^([^#\s].*)> and $1 !~ m/^[{}]*$/) {
      $sub = $1;
    }
    next if $sub =~ m/^XS/;
    if (m</\* diag_listed_as: (.*) \*/>) {
      $listed_as = $1;
      $listed_as_line = $.+1;
    }
    next if /^#/;
    next if /^ * /;
    while (m/\bDIE\b|Perl_(croak|die|warn(er)?)/ and not m/\);$/) {
      my $nextline = <$codefh>;
      # Means we fell off the end of the file.  Not terribly surprising;
      # this code tries to merge a lot of things that aren't regular C
      # code (preprocessor stuff, long comments).  That's OK; we don't
      # need those anyway.
      last if not defined $nextline;
      chomp $nextline;
      $nextline =~ s/^\s+//;
      # Note that we only want to do this where *both* are true.
      $_ =~ s/\\$//;
      if ($_ =~ m/"$/ and $nextline =~ m/^"/) {
        $_ =~ s/"$//;
        $nextline =~ s/^"//;
      }
      $_ = "$_$nextline";
    }
    # This should happen *after* unwrapping, or we don't reformat the things
    # in later lines.
    # List from perlguts.pod "Formatted Printing of IVs, UVs, and NVs"
    my %specialformats = (IVdf => 'd',
                          UVuf => 'd',
                          UVof => 'o',
                          UVxf => 'x',
                          UVXf => 'X',
                          NVef => 'f',
                          NVff => 'f',
                          NVgf => 'f',
                          SVf  => 's');
    for my $from (keys %specialformats) {
      s/%"\s*$from\s*"/\%$specialformats{$from}/g;
      s/%"\s*$from/\%$specialformats{$from}"/g;
    }
    # The %"foo" thing needs to happen *before* this regex.
    if (m/(?:DIE|Perl_(croak|die|warn|warner))(?:_nocontext)? \s*
          \(aTHX_ \s*
          (?:packWARN\d*\((.*?)\),)? \s*
          "((?:\\"|[^"])*?)"/x) {
      # diag($_);
      # DIE is just return Perl_die
      my $severity = {croak => [qw/P F/],
                      die   => [qw/P F/],
                      warn  => [qw/W D S/],
                     }->{$1||'die'};
      my @categories;
      if ($2) {
        @categories = map {s/^WARN_//; lc $_} split /\s*[|,]\s*/, $2;
      }
      my $name;
      if ($listed_as and $listed_as_line == $.) {
        $name = $listed_as;
      } else {
        $name = $3;
        # The form listed in perldiag ignores most sorts of fancy printf formatting,
        # or makes it more perlish.
        $name =~ s/%%/\\%/g;
        $name =~ s/%l[ud]/%d/g;
        $name =~ s/%\.(\d+|\*)s/\%s/g;
        $name =~ s/\\"/"/g;
        $name =~ s/\\t/\t/g;
        $name =~ s/\\n/\n/g;
        $name =~ s/\n$//;
      }

      # Extra explanitory info on an already-listed error, doesn't need it's own listing.
      next if $name =~ m/^\t/;

      # Happens fairly often with PL_no_modify.
      next if $name eq '%s';

      # Special syntax for magic comment, allows ignoring the fact that it isn't listed.
      # Only use in very special circumstances, like this script failing to notice that
      # the Perl_croak call is inside an #if 0 block.
      next if $name eq 'SKIPME';

      if (!exists $entries{$name}) {
        if ($name =~ m/^panic: /) {
          # Just too many panic:s, they are hard to diagnose, and there is a generic "panic: %s" entry.
          # Leave these for another pass.
          ok("Presence of '$name' from $codefn line $., covered by panic: %s entry");
        } else {
          fail("Presence of '$name' from $codefn line $.");
        }
      } else {
        ok("Presence of '$name' from $codefn line $.");
        # Commented: "substr outside of string" has is either a warning
        # or an error, depending how much was outside.
        # Also, plenty of failures without forcing further hardship...
#         if ($entries{$name} and !($entries{$name}{severity} ~~ $severity)) {
#           fail("Severity for '$name' from $codefn line $.: got $entries{$name}{severity}, expected $severity");
#         } else {
#           ok("Severity for '$name' from $codefn line $.: got $entries{$name}{severity}, expected $severity");
#         }
      }

      die if $name =~ /%$/;
    }
  }
}
