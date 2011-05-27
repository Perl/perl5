package Pod::Html;
use strict;
require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
$VERSION = 1.11;
@ISA = qw(Exporter);
@EXPORT = qw(pod2html htmlify);
@EXPORT_OK = qw(anchorify);

use Carp;
use Config;
use Cwd;
use File::Spec;
use File::Spec::Unix;
use Getopt::Long;
use Pod::Simple::Search;
use Pod::Simple::XHTML::LocalPodLinks;

use locale;	# make \w work right in non-ASCII lands

=head1 NAME

Pod::Html - module to convert pod files to HTML

=head1 SYNOPSIS

    use Pod::Html;
    pod2html([options]);

=head1 DESCRIPTION

Converts files from pod format (see L<perlpod>) to HTML format.  It
can automatically generate indexes and cross-references.

=head1 FUNCTIONS

=head2 pod2html

    pod2html("pod2html",
             "--podpath=lib:ext:pod:vms",
             "--podroot=/usr/src/perl",
             "--htmlroot=/perl/nmanual",
             "--libpods=perlfunc:perlguts:perlvar:perlrun:perlop",
             "--recurse",
             "--infile=foo.pod",
             "--outfile=/perl/nmanual/foo.html");

pod2html takes the following arguments:

=over 4

=item backlink

    --backlink

Turns every C<head1> heading into a link back to the top of the page.
By default, no backlinks are generated.

=item css

    --css=stylesheet

Specify the URL of a cascading style sheet.  Also disables all HTML/CSS
C<style> attributes that are output by default (to avoid conflicts).

=item help

    --help

Displays the usage message.

=item hiddendirs

    --hiddendirs
    --nohiddendirs

Include hidden directories in the search for POD's in podpath if recurse
is set.
The default is not to traverse any directory whose name begins with C<.>.
See L</"podpath"> and L</"recurse">.

[This option is for backward compatibility only.
It's hard to imagine that one would usefully create a module with a
name component beginning with C<.>.]

=item htmldir

    --htmldir=name

Sets the directory in which the resulting HTML file is placed.  This
is used to generate relative links to other files. Not passing this
causes all links to be absolute, since this is the value that tells
Pod::Html the root of the documentation tree.

=item htmlroot

    --htmlroot=name

Sets the base URL for the HTML files.  When cross-references are made,
the HTML root is prepended to the URL.

=item index

    --index
    --noindex

Generate an index at the top of the HTML file.  This is the default
behaviour.

=item infile

    --infile=name

Specify the pod file to convert.  Input is taken from STDIN if no
infile is specified.

=item libpods

    --libpods=name:...:name

List of page names (eg, "perlfunc") which contain linkable C<=item>s.

=item outfile

    --outfile=name

Specify the HTML file to create.  Output goes to STDOUT if no outfile
is specified.

=item podpath

    --podpath=name:...:name

Specify which subdirectories of the podroot contain pod files whose
HTML converted forms can be linked to in cross references.

=item podroot

    --podroot=name

Specify the base directory for finding library pods.

=item quiet

    --quiet
    --noquiet

Don't display I<mostly harmless> warning messages.  These messages
will be displayed by default.  But this is not the same as C<verbose>
mode.

=item recurse

    --recurse
    --norecurse

Recurse into subdirectories specified in podpath (default behaviour).

=item title

    --title=title

Specify the title of the resulting HTML file.

=item verbose

    --verbose
    --noverbose

Display progress messages.  By default, they won't be displayed.

=back

=head2 htmlify

    htmlify($heading);

Converts a pod section specification to a suitable section specification
for HTML. Note that we keep spaces and special characters except
C<", ?> (Netscape problem) and the hyphen (writer's problem...).

=head2 anchorify

    anchorify(@heading);

Similar to C<htmlify()>, but turns non-alphanumerics into underscores.  Note
that C<anchorify()> is not exported by default.

=head1 ENVIRONMENT

Uses C<$Config{pod2html}> to setup default options.

=head1 AUTHOR

Tom Christiansen, E<lt>tchrist@perl.comE<gt>.

=head1 SEE ALSO

L<perlpod>

=head1 COPYRIGHT

This program is distributed under the Artistic License.

=cut

# NOTES
# old pod::html tried to create links in preformatted text of all occurences
# of perl.*
# and tries to handle implicit
# links in C<> text (see process_puretext), and links to RFC

# use ::Search and find all POD docs and perldocs, store in %Pages/%Items,
# modify ::Xhtml's perldoc_url_pre/postfix to link successfully

# write test cases for pod::html to try and understand all the linkings

my @Libpods;
my($Htmlroot, $Htmldir, $Htmlfile);
my($Podfile, @Podpath, $Podroot);
my $Css;

my $Recurse;
my $Quiet;
my $HiddenDirs;
my $Verbose;
my $Doindex;

my $Backlink;

my($Title);

my %Sections; # fill with search's results of target pod

# Used to be caches, now are transient hashes (after removal of cache feature)
my %Pages = ();			# associative array used to find the location
				#   of pages referenced by L<> links.
my %Items = ();			# associative array used to find the location
				#   of =item directives referenced by L<> links

# %Pages: page name => path to page 
# e.g., { Pod::Simple => /path/to/Pod/Simple,
#         AFileThatHasPOD => /path/to/the/file }
# %Items: =item's text => path to file in which =item is located
# e.g., { $" => /path/to/perlvar,
#         Item in target pod => '' }

my $Curdir = File::Spec->curdir;

init_globals();

sub init_globals {
    @Libpods = ();	    	# files to search for links to =item directives
    $Htmlroot = "/";	    	# http-server base directory from which all
				#   relative paths in $podpath stem.
    $Htmldir = "";	    	# The directory to which the html pages
				# will (eventually) be written.
    $Htmlfile = "";		# write to stdout by default

    $Podfile = "";		# read from stdin by default
    @Podpath = ();		# list of directories containing library pods.
    $Podroot = $Curdir;	        # filesystem base directory from which all
				#   relative paths in $podpath stem.
    $Css = '';                  # Cascading style sheet
    $Recurse = 1;		# recurse on subdirectories in $podpath.
    $Quiet = 0;		        # not quiet by default
    $Verbose = 0;		# not verbose by default
    $Doindex = 1;   	    	# non-zero if we should generate an index
    $Backlink = 0;		# no backlinks added by default
    $Title = '';		# title to give the pod(s)
}

sub pod2html {
    local(@ARGV) = @_;
    local($/);
    local $_;

    init_globals();

    # parse the command-line parameters
    parse_command_line();

    # set options for the parser
    my $parser = Pod::Simple::XHTML::LocalPodLinks->new();
    $parser->backlink($Backlink);
    $parser->html_css($Css);
    $parser->index($Doindex);
    $parser->output_string(\my $output); # written to file later
     # TODO: implement default title generator in ::xhtml
    $parser->force_title(html_escape($Title));
    $parser->html_doctype('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">');

    my $input;
    unless (@ARGV && $ARGV[0]) {
	if ($Podfile and $Podfile ne '-') {
	    $input = $Podfile;
	} else {
	    $input = '-';
	}
    } else {
	$Podfile = $ARGV[0];
	$input = *ARGV;
    }

    warn "Converting input file $Podfile\n" if $Verbose;
    $parser->parse_file($input);

    # Write output to file
#    $Htmlfile = "-" unless $Htmlfile;	# stdout
    # open > $Htmlfile...
}

##############################################################################

sub usage {
    my $podfile = shift;
    warn "$0: $podfile: @_\n" if @_;
    die <<END_OF_USAGE;
Usage:  $0 --help --htmlroot=<name> --infile=<name> --outfile=<name>
           --podpath=<name>:...:<name> --podroot=<name>
           --libpods=<name>:...:<name> --recurse --verbose --index
           --norecurse --noindex

  --backlink     - set text for "back to top" links (default: none).
  --css          - stylesheet URL
  --help         - prints this message.
  --hiddendirs   - search hidden directories in podpath
  --htmldir      - directory for resulting HTML files.
  --htmlroot     - http-server base directory from which all relative paths
                   in podpath stem (default is /).
  --[no]index    - generate an index at the top of the resulting html
                   (default behaviour).
  --infile       - filename for the pod to convert (input taken from stdin
                   by default).
  --libpods      - colon-separated list of pages to search for =item pod
                   directives in as targets of C<> and implicit links (empty
                   by default).  note, these are not filenames, but rather
                   page names like those that appear in L<> links.
  --outfile      - filename for the resulting html file (output sent to
                   stdout by default).
  --podpath      - colon-separated list of directories containing library
                   pods (empty by default).
  --podroot      - filesystem base directory from which all relative paths
                   in podpath stem (default is .).
  --[no]quiet    - suppress some benign warning messages (default is off).
  --[no]recurse  - recurse on those subdirectories listed in podpath
                   (default behaviour).
  --title        - title that will appear in resulting html file.
  --[no]verbose  - self-explanatory (off by default).

END_OF_USAGE

}

sub parse_command_line {
    my ($opt_backlink,$opt_css,$opt_help,
	$opt_htmldir,$opt_htmlroot,$opt_index,$opt_infile,$opt_libpods,
	$opt_outfile,$opt_podpath,$opt_podroot,$opt_quiet,
	$opt_recurse,$opt_title,$opt_verbose,$opt_hiddendirs);

    unshift @ARGV, split ' ', $Config{pod2html} if $Config{pod2html};
    my $result = GetOptions(
			    'backlink!' => \$opt_backlink,
			    'css=s'      => \$opt_css,
			    'help'       => \$opt_help,
			    'hiddendirs!'=> \$opt_hiddendirs,
			    'htmldir=s'  => \$opt_htmldir,
			    'htmlroot=s' => \$opt_htmlroot,
			    'index!'     => \$opt_index,
			    'infile=s'   => \$opt_infile,
			    'libpods=s'  => \$opt_libpods,
			    'outfile=s'  => \$opt_outfile,
			    'podpath=s'  => \$opt_podpath,
			    'podroot=s'  => \$opt_podroot,
			    'quiet!'     => \$opt_quiet,
			    'recurse!'   => \$opt_recurse,
			    'title=s'    => \$opt_title,
			    'verbose!'   => \$opt_verbose,
			   );
    usage("-", "invalid parameters") if not $result;

    usage("-") if defined $opt_help;	# see if the user asked for help
    $opt_help = "";			# just to make -w shut-up.

    @Podpath  = split(":", $opt_podpath) if defined $opt_podpath;
    @Libpods  = split(":", $opt_libpods) if defined $opt_libpods;

    $Backlink = $opt_backlink if defined $opt_backlink;
    $Css      = $opt_css      if defined $opt_css;
    $Htmldir  = $opt_htmldir  if defined $opt_htmldir;
    $Htmlroot = $opt_htmlroot if defined $opt_htmlroot;
    $Doindex  = $opt_index    if defined $opt_index;
    $Podfile  = $opt_infile   if defined $opt_infile;
    $HiddenDirs = $opt_hiddendirs if defined $opt_hiddendirs;
    $Htmlfile = $opt_outfile  if defined $opt_outfile;
    $Podroot  = $opt_podroot  if defined $opt_podroot;
    $Quiet    = $opt_quiet    if defined $opt_quiet;
    $Recurse  = $opt_recurse  if defined $opt_recurse;
    $Title    = $opt_title    if defined $opt_title;
    $Verbose  = $opt_verbose  if defined $opt_verbose;
}

#
# html_escape: make text safe for HTML
#
sub html_escape {
    my $rest = $_[0];
    $rest   =~ s/&/&amp;/g;
    $rest   =~ s/</&lt;/g;
    $rest   =~ s/>/&gt;/g;
    $rest   =~ s/"/&quot;/g;
    # &apos; is only in XHTML, not HTML4.  Be conservative
    #$rest   =~ s/'/&apos;/g;
    return $rest;
}

#
# htmlify - converts a pod section specification to a suitable section
# specification for HTML. Note that we keep spaces and special characters
# except ", ? (Netscape problem) and the hyphen (writer's problem...).
#
sub htmlify {
    my( $heading) = @_;
    $heading =~ s/(\s+)/ /g;
    $heading =~ s/\s+\Z//;
    $heading =~ s/\A\s+//;
    # The hyphen is a disgrace to the English language.
    # $heading =~ s/[-"?]//g;
    $heading =~ s/["?]//g;
    $heading = lc( $heading );
    return $heading;
}

#
# similar to htmlify, but turns non-alphanumerics into underscores
#
sub anchorify {
    my ($anchor) = @_;
    $anchor = htmlify($anchor);
    $anchor =~ s/\W/_/g;
    return $anchor;
}

1;
