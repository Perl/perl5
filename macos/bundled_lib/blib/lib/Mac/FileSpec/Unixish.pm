
# Time-stamp: "2000-05-14 00:42:13 MDT"
require 5;
package Mac::FileSpec::Unixish;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION
            $Debug $Pretend_Non_Mac $Pretend_Mac);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(nativize unixify);
@EXPORT_OK = qw(nativize unixify under_macos);

$VERSION = "1.11";
$Debug = 0;

$Pretend_Non_Mac ||= 0;  # hardcode to 1 for testing non-Mac things on a Mac
$Pretend_Mac     ||= 0;  # hardcode to 1 for testing Mac things on a non-Mac
  # Don't set both of those to 1 at once
#==========================================================================

=head1 NAME

Mac::FileSpec::Unixish -- Unixish-compatability in file specifications

=head1 SYNOPSIS

  use Mac::FileSpec::Unixish; # exports 'unixify' and 'nativize'
  
  @input = map( unixify($_), @ARGV);
  foreach $item (@input) {
    my $_native_item = nativize($item);
    next unless
             $item =~ m<([^/]+)$>s # assumes / is the path separator
             and -f $_native_item;
    printf("File %s is %d bytes long...\n", $1, -s _ );
    open(IN, "<$_native_item")
      || die "Can't open $_native_item : $!\n";
    print "First line: ", scalar(<IN>);
    close(IN);
  }

=head1 DESCRIPTION

Mac::FileSpec::Unixish provides two functions, C<nativize> and
C<unixify> (both of which are exported by default), that will allow
you to denote and manipulate pathspecs in Unixish style, and let you
convert these pathspecs to and from the native OS's format for
conveying such things.  It currently assumes that if you are not
running under MacOS (as reported in C<$^O>), you must be on a Unix
box.  If you want better, I suggest using File::Spec.  (In essence, I
wrote Mac::FileSpec::Unixish as a cheap hack to get around using
File::Spec.)

Using this library, you can, in your code, refer to files using a
Unixish notation, a la:

  $foo = "../analyses/ziz.txt";
  open(OUT, '>' . nativize($foo) ) || die "Couldn't open $foo \: $!";

Under Unix, C<nativize($foo)> will be simply "../analyses/ziz.txt"
(C<nativize> and C<unixify> are nearly no-ops under Unixes); but under
MacOS it will be "::analyses:ziz.txt".

Incidentally, C<nativize(unixify($item))> is always eq C<$item>, for
all (defined, non-undef) values of C<$item>, regardless of whether or
not this is performed under MacOS.  In other words, this:

  @items = map(unixify($_), @ARGV);
  foreach $one (@items) {
    print "$one => ", -s nativize($one), " bytes\n";
    my $one_copy = $one;
    $one_copy =~ s/[^/]+$//s;
    print " in the directory $one_copy";
  }

will work equally well under MacOS as under Unix, regardless of the
fact that items in @ARGV will be in "foo:bar:baz" format if run under
MacOS, and "/foo/bar/baz" format if run under Unix.

This portability is the entire point of this library.

(This code will work even if run under MacOS and if @ARGV contains a
pathspec like "Sean:reports:by week:5/5/98".  C<unixify> encodes those
slashes (as "\e2f", if you're curious) so that they won't be
misunderstood as path separators in the Unixish representation -- see
"GUTS", below, for the gory details.)

This library also provides (but does not by default export) a function
Mac::FileSpec::Unixish::under_macos(), which returns true if you're
running under MacOS, and false otherwise.  You can use that in cases
like:

  my $home =
    Mac::FileSpec::Unixish::under_macos() ?  '/Sean/' : '~/' ;

=head2 PURPOSE

This library exists so that a careful programmer who knows what
filespecs are legal and meaningful both under Mac and under Unix, can
write code that manipulates files and filenawes, and have this code
work equally well under MacOS and under Unix.

That's all this library is for, and that's all it does.

This library doesn't overload anything, so I<don't> go thinking that
you can go

  open(OUT, '>../foo/bar.txt");

under MacOS.

Proper use of this library means that I<every> time you pass a file
specification to any file operation (from C<chdir> to C<-s> to
C<opendir>), you should pass the Unixish designation thru C<nativize>
-- and I<every> time you get a file spec from the OS (thru C<@ARGV> or
C<StandardFile::GetFolder("Select a folder")> or whatever), that you
pass it thru C<unixify> to get the Unixish representation.

C<nativize> and C<unixify> are the only two functions this module
exports.

This library doesn't try to interpret Unixish pathspecs with B<any>
semantics other than the above-described -- to wit, "~"s in filespecs
(as in C<~/.plan> or C<~luser/.plan>) aren't expanded, since there is
no equivalent meaning under MacOS.

And if you say "/tmp/", you I<will> get "tmp:" under MacOS -- and this
is probably I<not> what you want.

This (coupled with the fact that MacOS has nothing like "/", save as a
notational (or notional) base for the mounted volumes) almost
definitely means that B<you don't want to use any absolute pathspecs
like "/tmp/" or "/usr/home/luser" or "/Sean/System Folder",
or pathspecs based on ~ or ~luser>.  In other words, your pathspecs
should either come from outside the program (as from %ENV, @ARGV, or
things you devise based on them), or should be relative.

You have been warned!

=head2 GUTS

Here are some of the icky details of how this module works.

"Unixish" path specification means pathspecs expressed with the
meanings that Unix assigns to '/', '.', and '..' -- with the
additional bit of semantics that the escape character (ASCII 0x1B,
a.k.a. C<"\e">) and two hex ([a-fA-F0-9]) characters after it denote
the one character with that hex code.

In other words, it's just like URL-encoding, but with C<ESC> instead
of C<%>. I included this quoting mechanism so it would be possible to
denote, in Unixish notation, Mac filenames with "/"s in them.
Example:

  "Foovol:stuff:05/98" -> "/Foovol/stuff/05\e2f98"

But actual hardcoding of "\e2f" is unwise, since if you have:

  open(OUT, '>' . nativize("/Foovol/stuff/05\e2f98"));

This will Do What You Want only if you're under MacOS, but under Unix
it will instead try to write to C</Foovol/stuff/05/98>.

As mentioned above, C<nativize(unixify($item))> is always $item, for
all values of $item, and regardless of whether or not this is
performed under MacOS.

But the inverse (i.e., whether C<unixify(nativize($item))>) is not
necessarily true!  In a rather dramatic case, C<nativize("/")> happens
to yield "" under MacOS, for many, many reasons.  Other, more mundane
cases include the fact that "../foo" and "./../foo" and, for that
matter, ".././foo" are all synonyms for the same thing, and the
(notational if not meaningful) distinction between them I<may> be
smashed -- under MacOS, they'd all end up "::foo".

=head2 A Note on Trailers

Note that when a trailing MacOS ":" means 'directory' (e.g.,
"Sean:reports:", it is represented as a trailing '/' in the Unixish
representation, and vice versa.  When I'm writing code, I<I> always
use a trailer (a trailing ":" or "/") when accessing a directory (as
is C<opendir(FOODIR, ":foo:bar:")> or C<opendir(FOODIR, "./foo/bar/")>
).  Now, this is generally unnecessary; C<opendir(FOODIR,
":foo:bar:")> and C<opendir(FOODIR, ":foo:bar:")> do the same thing,
just as C<opendir(FOODIR, "foo/bar/")> and C<opendir(FOODIR,
"foo/bar")> do the same thing on (absolutely all?) Unix boxes.

However, when accessing the root drive of a MacOS volume, the "root"
directory of a volume, like "foo", you should use the trailer --
C<opendir(FOODIR, "foo:")>, not C<opendir(FOODIR, "foo")>.

It's odd to note that MacOS seems inconsistent about using the
trailer.  If you drop the Finder icon for the volume "foo" onto a
droplet, it'll see "foo:" in @ARGV -- with the trailer.  But if you
drop the Finder icon for the directory "foo:bar" (or any other
non-volume-root directory I've tested this on) onto a droplet, it'll
see "foo:bar" in @ARGV -- no trailer.

=head1 COPYRIGHT

Copyright 1998-2000, Sean M. Burke C<sburke@cpan.org>, all rights
reserved.

You may use and redistribute this library under the same terms as Perl itself.

=head1 AUTHOR

Sean M. Burke C<sburke@cpan.org>

=cut

#--------------------------------------------------------------------------

sub nativize {
  # Convert a unixish filespec to one that has
  #  the equivalent meaning for the native OS.
  my($spec) = $_[0];

  print " spec: $spec\n" if $Debug;

  return undef unless defined($spec);
  return '' if $spec eq '';

  my($is_abs) =  $spec =~ s<^/+><>s;
  my($is_dir) =  $spec =~ s</+$><>s;

  my(@bits) = ($spec =~
               m<
                 ( [^\/]+ )
                >xsg
              );

  print "  bits: ", map("<$_>", @bits), "\n" if $Debug;

  my(@bits_out) = ();

  foreach my $bit (@bits) {
    if($bit eq '..') {
      push @bits_out, "\eUP";
      # \eUP is my internal symbol for up-dir
    } elsif ($bit eq '.') { # a HERE
      # do nothing
    } else {
      push @bits_out, $bit;
    }
  }

  my($out) = join(':', @bits_out);

  print "  bits_out: ", map("<$_>", @bits_out), "\n" if $Debug;
  print "  out1 = <$out>\n" if $Debug;

  $out =~ s<(        # Match...
             :?      # a possible leading ':'
             (?:     # and one or more of a
               \eUP  #  \eUP
               \:?   #  possibly followed by ':'
             )+
            )
           ><&_parse_ups($1)>exsg;

  print "  out2 = <$out>\n" if $Debug;

  $out = 
   ($is_abs
     || substr($out,0,1) eq ':'
       #  So that '::foo' (from '../foo' ) doesn't => ':::foo'
     ? '' : ':') .
   $out .
   ($is_dir ? ':' : '')
  ;

  print "  out3 = <$out>\n" if $Debug;
  $out = &_e_decode($out);
  print "  out4 = <$out>\n" if $Debug;

  return $out;
}

#--------------------------------------------------------------------------

sub unixify {
  # Convert from native format into a unixish (with \e-quoting) spec
  my($spec) = $_[0];

  print " spec: $spec\n" if $Debug;

  return undef unless defined($spec);
  return '' if $spec eq '';

  my($is_abs) =  $spec !~ m<^:>s;

  my(@bits) = split( /(\:+)/ , $spec, -1);
  print "  bits: ", map("<$_>", @bits), "\n" if $Debug;

  my($out) = '';
  foreach my $bit (@bits) {
    # print " Bit: <$bit>\n";
    if( $bit eq '') { # Caused by a leading ':'
      # Do nothing.
    } elsif ( $bit eq ':' ) {
      $out .= '/';
    } elsif( $bit =~ /^\:+$/s ) {
      $out .= join('..', ('/') x length($bit))
    } else {
      # It's an item -- \e-quote as necessary
      $out .= &_e_encode($bit);
    }
  }
  $out =
    ($is_abs ? '/' : '.') . $out;
  print "  out: <$out>\n" if $Debug;
  return $out;
}

sub under_macos { 1 }

#==========================================================================

# And if I'm not on a Mac, override &nativize and &unixify
#  to just \e-decode and \e-encode.

if( ($^O ne 'MacOS' || $Pretend_Non_Mac)
    && !$Pretend_Mac
) {
  eval "
         sub nativize { &_e_decode(\@_) }
         sub unixify  { &_e_encode(\@_) }
         sub under_macos { 0 }
       ";
}

#==========================================================================
# Internal routines

sub _parse_ups {
  # Return a string of 1 + as many ":"s as there were
  # \e's in the input string.
  my($in) = $_[0];
  my($out) = ':' x (1 + $in =~ tr/\e//);
  print "  UP-path string <$in> => <$out>\n" if $Debug > 1;
  return $out;
}

sub _e_encode {
  my($thing) = $_[0];
  $thing =~ s<([/\e])><"\e".(unpack('H2',$1))>eg;
  return $thing;
}

sub _e_decode {
  my($thing) = $_[0];
  $thing =~ s/\e([a-fA-F0-9][a-fA-F0-9])/pack('C', hex($1))/eg;
  return $thing;
}

#==========================================================================
1;

__END__
