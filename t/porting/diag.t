#!/usr/bin/perl
use warnings;
use strict;

require './test.pl';

plan('no_plan');

$|=1;

# --make-exceptions-list outputs the list of strings that don't have
# perldiag.pod entries to STDERR without TAP formatting, so they can
# easily be put in the __DATA__ section of this file.  This was done
# initially so as to not create new test failures upon the initial
# creation of this test file.  You probably shouldn't do it again.
# Just add the documentation instead.
my $make_exceptions_list = ($ARGV[0]||'') eq '--make-exceptions-list';

chdir '..' or die "Can't chdir ..: $!";
BEGIN { defined $ENV{PERL_UNICODE} and push @INC, "lib"; }

my @functions;

open my $func_fh, "<", "embed.fnc" or die "Can't open embed.fnc: $!";

# Look for functions in embed.fnc that look like they could be diagnostic ones.
while (<$func_fh>) {
  chomp;
  s/^\s+//;
  while (s/\s*\\$//) {      # Grab up all continuation lines, these end in \
    my $next = <$func_fh>;
    $next =~ s/^\s+//;
    chomp $next;
    $_ .= $next;
  }
  next if /^:/;     # Lines beginning with colon are comments.
  next unless /\|/; # Lines without a vertical bar are something we can't deal
                    # with
  my @fields = split /\s*\|\s*/;
  next unless $fields[2] =~ /warn|err|(\b|_)die|croak/i;
  push @functions, $fields[2];

  # The flag p means that this function may have a 'Perl_' prefix
  # The flag s means that this function may have a 'S_' prefix
  push @functions, "Perl_$fields[2]", if $fields[0] =~ /p/;
  push @functions, "S_$fields[2]", if $fields[0] =~ /s/;
}

close $func_fh;

my $function_re = join '|', @functions;
my $source_msg_re = qr/(?<routine>\bDIE\b|$function_re)/;
my $text_re = qr/"(?<text>(?:\\"|[^"])*?)"/;
my $source_msg_call_re = qr/$source_msg_re(?:_nocontext)? \s*
    \(aTHX_ \s*
    (?:packWARN\d*\((?<category>.*?)\),)? \s*
    $text_re /x;
my $bad_version_re = qr{BADVERSION\([^"]*$text_re};

my %entries;

# Get the ignores that are compiled into this file
while (<DATA>) {
  chomp;
  $entries{$_}{todo}=1;
}

my $pod = "pod/perldiag.pod";
my $cur_entry;
open my $diagfh, "<", $pod
  or die "Can't open $pod: $!";

my $category_re = qr/ [a-z0-9_]+?/;      # Note: requires an initial space
my $severity_re = qr/ . (?: \| . )* /x; # A severity is a single char, but can
                                        # be of the form 'S|P|W'
while (<$diagfh>) {
  if (m/^=item (.*)/) {
    $cur_entry = $1;

    if (exists $entries{$cur_entry}) {
        TODO: {
            local $::TODO = "Remove the TODO entry \"$cur_entry\" from DATA as it is already in $pod near line $.";
            ok($cur_entry);
        }
    }
    # Make sure to init this here, so an actual entry in perldiag
    # overwrites one in DATA.
    $entries{$cur_entry}{todo} = 0;
    $entries{$cur_entry}{line_number} = $.;
    next;
  }

  next if ! defined $cur_entry;

  if (! $entries{$cur_entry}{severity}) {
    if (/^ \( ( $severity_re )

        # Can have multiple categories separated by commas
        (?: ( $category_re ) (?: , $category_re)* )? \) /x)
    {
      $entries{$cur_entry}{severity} = $1;
      $entries{$cur_entry}{category} = $2;
    }
    elsif (! $entries{$cur_entry}{first_line} && $_ =~ /\S/) {

      # Keep track of first line of text if doesn't contain a severity, so
      # that can later examine it to determine if that is ok or not
      $entries{$cur_entry}{first_line} = $_;
    }
  }
}

foreach my $cur_entry ( keys %entries) {
    next if $entries{$cur_entry}{todo}; # If in this file, won't have a severity
    if (! exists $entries{$cur_entry}{severity}

            # If there is no first line, it was two =items in a row, so the
            # second one is the one with with text, not this one.
        && exists $entries{$cur_entry}{first_line}

            # If the first line refers to another message, no need for severity
        && $entries{$cur_entry}{first_line} !~ /^See/)
    {
        fail($cur_entry);
        diag(
            "   $pod entry at line $entries{$cur_entry}{line_number}\n"
          . "       \"$cur_entry\"\n"
          . "   is missing a severity and/or category"
        );
    }
}

# List from perlguts.pod "Formatted Printing of IVs, UVs, and NVs"
# Convert from internal formats to ones that the readers will be familiar
# with, while removing any format modifiers, such as precision, the
# presence of which would just confuse the pod's explanation
my %specialformats = (IVdf => 'd',
		      UVuf => 'd',
		      UVof => 'o',
		      UVxf => 'x',
		      UVXf => 'X',
		      NVef => 'f',
		      NVff => 'f',
		      NVgf => 'f',
		      SVf  => 's');
my $format_modifiers = qr/ [#0\ +-]*              # optional flags
			  (?: [1-9][0-9]* | \* )? # optional field width
			  (?: \. \d* )?           # optional precision
			  (?: h|l )?              # optional length modifier
			/x;

my $specialformats = join '|', sort keys %specialformats;
my $specialformats_re = qr/%$format_modifiers"\s*($specialformats)(\s*")?/;

# Recursively descend looking for source files.
my @todo = sort <*>;
while (@todo) {
  my $todo = shift @todo;
  next if $todo ~~ ['t', 'lib', 'ext', 'dist', 'cpan'];
  # opmini.c is just a copy of op.c, so there's no need to check again.
  next if $todo eq 'opmini.c';
  if (-d $todo) {
    unshift @todo, sort glob "$todo/*";
  } elsif ($todo =~ m/\.[ch]$/) {
    check_file($todo);
  }
}

# Standardize messages with variants into the form that appears
# in perldiag.pod -- useful for things without a diag_listed_as annotation
sub standardize {
  my ($name) = @_;

  if    ( $name =~ m/^(Invalid strict version format) \([^\)]*\)/ ) {
    $name = "$1 (\%s)";
  }
  elsif ( $name =~ m/^(Invalid version format) \([^\)]*\)/ ) {
    $name = "$1 (\%s)";
  }
  elsif ($name =~ m/^panic: /) {
    $name = "panic: \%s";
  }

  return $name;
}

sub check_file {
  my ($codefn) = @_;

  print "# Checking $codefn\n";

  open my $codefh, "<", $codefn
    or die "Can't open $codefn: $!";

  my $listed_as;
  my $listed_as_line;
  my $sub = 'top of file';
  while (<$codefh>) {
    chomp;
    # Getting too much here isn't a problem; we only use this to skip
    # errors inside of XS modules, which should get documented in the
    # docs for the module.
    if (m<^[^#\s]> and $_ !~ m/^[{}]*$/) {
      $sub = $_;
    }
    next if $sub =~ m/^XS/;
    if (m</\* diag_listed_as: (.*) \*/>) {
      $listed_as = $1;
      $listed_as_line = $.+1;
    }
    next if /^#/;
    next if /^ +/;

    my $multiline = 0;
    # Loop to accumulate the message text all on one line.
    if (m/$source_msg_re/) {
      while (not m/\);$/) {
        my $nextline = <$codefh>;
        # Means we fell off the end of the file.  Not terribly surprising;
        # this code tries to merge a lot of things that aren't regular C
        # code (preprocessor stuff, long comments).  That's OK; we don't
        # need those anyway.
        last if not defined $nextline;
        chomp $nextline;
        $nextline =~ s/^\s+//;
        $_ =~ s/\\$//;
        # Note that we only want to do this where *both* are true.
        if ($_ =~ m/"$/ and $nextline =~ m/^"/) {
          $_ =~ s/"$//;
          $nextline =~ s/^"//;
        }
        $_ .= $nextline;
        ++$multiline;
      }
    }
    # This should happen *after* unwrapping, or we don't reformat the things
    # in later lines.

    s/$specialformats_re/"%$specialformats{$1}" .  (defined $2 ? '' : '"')/ge;

    # Remove any remaining format modifiers, but not in %%
    s/ (?<!%) % $format_modifiers ( [dioxXucsfeEgGp] ) /%$1/xg;

    # The %"foo" thing needs to happen *before* this regex.
    # diag($_);
    # DIE is just return Perl_die
    my ($name, $category);
    if (/$source_msg_call_re/) {
      ($name, $category) = ($+{'text'}, $+{'category'});
    }
    elsif (/$bad_version_re/) {
      ($name, $category) = ($+{'text'}, undef);
    }
    else {
      next;
    }

    my $severity = {croak => [qw/P F/],
                      die   => [qw/P F/],
                      warn  => [qw/W D S/],
                     }->{$+{'routine'}||'die'};
    my @categories;
    if (defined $category) {
      @categories = map {s/^WARN_//; lc $_} split /\s*[|,]\s*/, $category;
    }
    if ($listed_as and $listed_as_line == $. - $multiline) {
      $name = $listed_as;
    } else {
      # The form listed in perldiag ignores most sorts of fancy printf
      # formatting, or makes it more perlish.
      $name =~ s/%%/\\%/g;
      $name =~ s/%l[ud]/%d/g;
      $name =~ s/%\.(\d+|\*)s/\%s/g;
      $name =~ s/\\"/"/g;
      $name =~ s/\\t/\t/g;
      $name =~ s/\\n/ /g;
      $name =~ s/\s+$//;
      $name =~ s/(\\)\\/$1/g;
    }

    # Extra explanatory info on an already-listed error, doesn't
    # need it's own listing.
    next if $name =~ m/^\t/;

    # Happens fairly often with PL_no_modify.
    next if $name eq '%s';

    # Special syntax for magic comment, allows ignoring the fact
    # that it isn't listed.  Only use in very special circumstances,
    # like this script failing to notice that the Perl_croak call is
    # inside an #if 0 block.
    next if $name eq 'SKIPME';

    $name = standardize($name);

    if (exists $entries{$name}) {
      if ( $entries{$name}{seen}++ ) {
        # no need to repeat entries we've tested
      } elsif ($entries{$name}{todo}) {
        TODO: {
          no warnings 'once';
          local $::TODO = 'in DATA';
          # There is no listing, but it is in the list of exceptions.  TODO FAIL.
          fail($name);
          diag(
            "    Message '$name'\n    from $codefn line $. is not listed in $pod\n".
            "    (but it wasn't documented in 5.10 either, so marking it TODO)."
          );
        }
      } else {
        # We found an actual valid entry in perldiag.pod for this error.
        pass($name);
      }
      # Later, should start checking that the severity is correct, too.
    } else {
      if ($make_exceptions_list) {
        # We're making an updated version of the exception list, to
        # stick in the __DATA__ section.  I honestly can't think of
        # a situation where this is the right thing to do, but I'm
        # leaving it here, just in case one of my descendents thinks
        # it's a good idea.
        print STDERR "$name\n";
      } else {
        # No listing found, and no excuse either.
        # Find the correct place in perldiag.pod, and add a stanza beginning =item $name.
        fail($name);
        diag("    Message '$name'\n    from $codefn line $. is not listed in $pod");
      }
      # seen it, so only fail once for this message
      $entries{$name}{seen}++;
    }

    die if $name =~ /%$/;
  }
}

# Lists all missing things as of the inauguration of this script, so we
# don't have to go from "meh" to perfect all at once.
# 
# PLEASE DO NOT ADD TO THIS LIST.  Instead, write an entry in
# pod/perldiag.pod for your new (warning|error).

# Also FIXME this test, as the first entry in TODO *is* covered by the
# description: Malformed UTF-8 character (%s)
__DATA__
Malformed UTF-8 character (unexpected non-continuation byte 0x%x, immediately after start byte 0x%x)

%s (%d) does not match %s (%d),
%s (%d) smaller than %s (%d),
Argument "%s" isn't numeric
Argument "%s" isn't numeric in %s
Attempt to clear deleted array
Attempt to free non-existent shared string '%s'%s
Attempt to free temp prematurely: SV 0x%x
Attempt to free unreferenced scalar: SV 0x%x
Attempt to reload %s aborted. Compilation failed in require
av_reify called on tied array
Bad name after %s%s
Bad symbol for %s
bad top format reference
Bizarre copy of %s
Bizarre SvTYPE [%d]
Cannot copy to %s
Can't call method "%s" %s
Can't coerce readonly %s to string
Can't coerce readonly %s to string in %s
Can't fix broken locale name "%s"
Can't get short module name from a handle
Can't goto subroutine from an eval-block
Can't goto subroutine from an eval-string
Can't locate object method "%s" via package "%s" (perhaps you forgot to load "%s"?)
Can't modify non-existent substring
Can't open
Can't open perl script "%s": %s
Can't open %s
Can't reset \%ENV on this system
Can't return array to lvalue scalar context
Can't return a %s from lvalue subroutine
Can't return hash to lvalue scalar context
Can't spawn "%s": %s
Can't %s script `%s' with ARGV[0] being `%s'
Can't %s "%s": %s
Can't %s %s%s%s
Can't %s `%s' with ARGV[0] being `%s' (looking for executables only, not found)
Can't take %s of %f
Can't use '%c' after -mname
Can't use string ("%s"%s) as a subroutine ref while "strict refs" in use
Can't use when() outside a topicalizer
\%c better written as $%c
Character(s) in '%c' format wrapped in %s
$%c is no longer supported
Cloning substitution context is unimplemented
Code missing after '/' in pack
Code missing after '/' in unpack
Corrupted regexp opcode %d > %d
'%c' outside of string in pack
Debug leaking scalars child failed%s%s with errno %d: %s
Deep recursion on anonymous subroutine
defined(\%hash) is deprecated
Don't know how to handle magic of type \%o
-Dp not implemented on this platform
entering effective gid failed
entering effective uid failed
Error reading "%s": %s
Exiting %s via %s
Filehandle opened only for %sput
Filehandle %s opened only for %sput
Filehandle STD%s reopened as %s only for input
YOU HAVEN'T DISABLED SET-ID SCRIPTS IN THE KERNEL YET! FIX YOUR KERNEL, PUT A C WRAPPER AROUND THIS SCRIPT, OR USE -u AND UNDUMP!
Format STDOUT redefined
Free to wrong pool %p not %p
get %s %p %p %p
glob failed (can't start child: %s)
glob failed (child exited with status %d%s)
Goto undefined subroutine
Goto undefined subroutine &%s
Hash \%%s missing the \% in argument %d of %s()
Illegal character %sin prototype for %s : %s
Integer overflow in binary number
Integer overflow in decimal number
Integer overflow in hexadecimal number
Integer overflow in octal number
Integer overflow in version %d
internal \%<num>p might conflict with future printf extensions
invalid control request: '\%o'
Invalid module name %s with -%c option: contains single ':'
invalid option -D%c, use -D'' to see choices
Invalid range "%c-%c" in transliteration operator
Invalid separator character %c%c%c in PerlIO layer specification %s
Invalid TOKEN object ignored
Invalid type '%c' in pack
Invalid type '%c' in %s
Invalid type '%c' in unpack
Invalid type ',' in %s
'j' not supported on this platform
'J' not supported on this platform
leaving effective gid failed
leaving effective uid failed
List form of piped open not implemented
Lost precision when decrementing %f by 1
Lost precision when incrementing %f by 1
%lx
Malformed UTF-8 character (fatal)
'\%' may not be used in pack
Missing (suid) fd script name
More than one argument to open
More than one argument to open(,':%s')
mprotect for %p %u failed with %d
mprotect RW for %p %u failed with %d
No code specified for -%c
No directory specified for -I
No such class field "%s"
Not an XSUB reference
Not %s reference
Operator or semicolon missing before %c%s
Perl %s required (did you mean %s?)--this is only %s, stopped
Perl %s required--this is only %s, stopped
Perls since %s too modern--this is %s, stopped
ptr wrong %p != %p fl=%x nl=%p e=%p for %d
Recompile perl with -DDEBUGGING to use -D switch (did you mean -d ?)
Recursive call to Perl_load_module in PerlIO_find_layer
Reversed %c= operator
Runaway prototype
%s(%.0
%s(%f) failed
%s(%f) too large
%s(%f) too small
Scalar value %s better written as $%s
%sCompilation failed in regexp
%sCompilation failed in require
set %s %p %p %p
%s free() ignored (RMAGIC, PERL_CORE)
%s has too many errors.
SIG%s handler "%s" not defined.
%s: illegal mapping '%s'
%s in %s
Size magic not implemented
%s limit (%d) exceeded
%s method "%s" overloading "%s" in package "%s"
%s number > %s non-portable
%s object version %s does not match %s%s%s%s %s
%srealloc() %signored
%s returned from lvalue subroutine in scalar context
%s%s has too many errors.
%s%s on %s %s
%s%s on %s %s %s
Starting Full Screen process with flag=%d, mytype=%d
Starting PM process with flag=%d, mytype=%d
strxfrm() gets absurd
SWASHNEW didn't return an HV ref
-T and -B not implemented on filehandles
The flock() function is not implemented on NetWare
The rewinddir() function is not implemented on NetWare
The seekdir() function is not implemented on NetWare
The stat preceding lstat() wasn't an lstat
The telldir() function is not implemented on NetWare
Too deeply nested ()-groups in %s
Too late to run CHECK block
Too late to run INIT block
Too many args on %s line of "%s"
U0 mode on a byte string
Unbalanced string table refcount: (%d) for "%s"
Undefined top format called
Unexpected constant lvalue entersub entry via type/targ %d:%d
Unicode non-character 0x%X
Unknown PerlIO layer "scalar"
Unstable directory path, current directory changed unexpectedly
Unsupported script encoding UTF-16BE
Unsupported script encoding UTF-16LE
Unsupported script encoding UTF-32BE
Unsupported script encoding UTF-32LE
Unterminated compressed integer in unpack
Usage: CODE(0x%x)(%s)
Usage: %s(%s)
Usage: %s::%s(%s)
Usage: VMS::Filespec::unixrealpath(spec)
Usage: VMS::Filespec::vmsrealpath(spec)
Use of inherited AUTOLOAD for non-method %s::%s() is deprecated
utf8 "\x%X" does not map to Unicode
Value of logical "%s" too long. Truncating to %i bytes
value of node is %d in Offset macro
Value of %s%s can be "0"; test with defined()
Variable "%c%s" is not imported
vector argument not supported with alpha versions
Wide character
Wide character in $/
Wide character in print
Within []-length '%c' not allowed in %s
Wrong syntax (suid) fd script name "%s"
'X' outside of string in unpack
