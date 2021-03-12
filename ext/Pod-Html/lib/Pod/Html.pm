package Pod::Html;
use strict;
use Exporter 'import';

our $VERSION = 1.28;
our @EXPORT = qw(pod2html htmlify);
our @EXPORT_OK = qw(anchorify relativize_url);

use Carp;
use Config;
use Cwd;
use File::Basename;
use File::Spec;
use File::Spec::Unix;
use Getopt::Long;
use Pod::Simple::Search;
use Pod::Simple::SimpleTree ();
use Text::Tabs;
use locale; # make \w work right in non-ASCII lands

=head1 NAME

Pod::Html - module to convert pod files to HTML

=head1 SYNOPSIS

    use Pod::Html;
    pod2html([options]);

=head1 DESCRIPTION

Converts files from pod format (see L<perlpod>) to HTML format.  It
can automatically generate indexes and cross-references, and it keeps
a cache of things it knows how to cross-reference.

=head1 FUNCTIONS

=head2 pod2html

    pod2html("pod2html",
             "--podpath=lib:ext:pod:vms",
             "--podroot=/usr/src/perl",
             "--htmlroot=/perl/nmanual",
             "--recurse",
             "--infile=foo.pod",
             "--outfile=/perl/nmanual/foo.html");

pod2html takes the following arguments:

=over 4

=item backlink

    --backlink

Turns every C<head1> heading into a link back to the top of the page.
By default, no backlinks are generated.

=item cachedir

    --cachedir=name

Creates the directory cache in the given directory.

=item css

    --css=stylesheet

Specify the URL of a cascading style sheet.  Also disables all HTML/CSS
C<style> attributes that are output by default (to avoid conflicts).

=item flush

    --flush

Flushes the directory cache.

=item header

    --header
    --noheader

Creates header and footer blocks containing the text of the C<NAME>
section.  By default, no headers are generated.

=item help

    --help

Displays the usage message.

=item htmldir

    --htmldir=name

Sets the directory to which all cross references in the resulting
html file will be relative. Not passing this causes all links to be
absolute since this is the value that tells Pod::Html the root of the 
documentation tree.

Do not use this and --htmlroot in the same call to pod2html; they are
mutually exclusive.

=item htmlroot

    --htmlroot=name

Sets the base URL for the HTML files.  When cross-references are made,
the HTML root is prepended to the URL.

Do not use this if relative links are desired: use --htmldir instead.

Do not pass both this and --htmldir to pod2html; they are mutually
exclusive.

=item index

    --index
    --noindex

Generate an index at the top of the HTML file.  This is the default
behaviour.

=item infile

    --infile=name

Specify the pod file to convert.  Input is taken from STDIN if no
infile is specified.

=item outfile

    --outfile=name

Specify the HTML file to create.  Output goes to STDOUT if no outfile
is specified.

=item poderrors

    --poderrors
    --nopoderrors

Include a "POD ERRORS" section in the outfile if there were any POD 
errors in the infile. This section is included by default.

=item podpath

    --podpath=name:...:name

Specify which subdirectories of the podroot contain pod files whose
HTML converted forms can be linked to in cross references.

=item podroot

    --podroot=name

Specify the base directory for finding library pods. Default is the
current working directory.

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

Marc Green, E<lt>marcgreen@cpan.orgE<gt>. 

Original version by Tom Christiansen, E<lt>tchrist@perl.comE<gt>.

=head1 SEE ALSO

L<perlpod>

=head1 COPYRIGHT

This program is distributed under the Artistic License.

=cut

# This sub duplicates the guts of Pod::Simple::FromTree.  We could have
# used that module, except that it would have been a non-core dependency.
sub feed_tree_to_parser {
    my($parser, $tree) = @_;
    if(ref($tree) eq "") {
	$parser->_handle_text($tree);
    } elsif(!($tree->[0] eq "X" && $parser->nix_X_codes)) {
	$parser->_handle_element_start($tree->[0], $tree->[1]);
	feed_tree_to_parser($parser, $_) foreach @{$tree}[2..$#$tree];
	$parser->_handle_element_end($tree->[0]);
    }
}


my $Podroot;

my %Pages = ();                 # associative array used to find the location
                                #   of pages referenced by L<> links.

sub init_globals {
    my %globals = ();
    $globals{Cachedir} = ".";            # The directory to which directory caches
                                         #   will be written.

    $globals{Dircache} = "pod2htmd.tmp";

    $globals{Htmlroot} = "/";            # http-server base directory from which all
                                         #   relative paths in $podpath stem.
    $globals{Htmldir} = "";              # The directory to which the html pages
                                         #   will (eventually) be written.
    $globals{Htmlfile} = "";             # write to stdout by default
    $globals{Htmlfileurl} = "";          # The url that other files would use to
                                         # refer to this file.  This is only used
                                         # to make relative urls that point to
                                         # other files.

    $globals{Poderrors} = 1;
    $globals{Podfile} = "";              # read from stdin by default
    $globals{Podpath} = [];              # list of directories containing library pods.
    $globals{Podroot} = $globals{Curdir} = File::Spec->curdir;
                                         # filesystem base directory from which all
                                         #   relative paths in $podpath stem.
    $globals{Css} = '';                  # Cascading style sheet
    $globals{Recurse} = 1;               # recurse on subdirectories in $podpath.
    $globals{Quiet} = 0;                 # not quiet by default
    $globals{Verbose} = 0;               # not verbose by default
    $globals{Doindex} = 1;               # non-zero if we should generate an index
    $globals{Backlink} = 0;              # no backlinks added by default
    $globals{Header} = 0;                # produce block header/footer
    $globals{Title} = undef;             # title to give the pod(s)
    $globals{Saved_Cache_Key} = '';
    return \%globals;
}

sub pod2html {
    local(@ARGV) = @_;
    local $_;

    my $globals = init_globals();
    $globals = parse_command_line($globals);

    # prevent '//' in urls
    $globals->{Htmlroot} = "" if $globals->{Htmlroot} eq "/";
    $globals->{Htmldir} =~ s#/\z##;

    if (  $globals->{Htmlroot} eq ''
       && defined( $globals->{Htmldir} )
       && $globals->{Htmldir} ne ''
       && substr( $globals->{Htmlfile}, 0, length( $globals->{Htmldir} ) ) eq $globals->{Htmldir}
       ) {
        # Set the 'base' url for this file, so that we can use it
        # as the location from which to calculate relative links
        # to other files. If this is '', then absolute links will
        # be used throughout.
        #$globals->{Htmlfileurl} = "$globals->{Htmldir}/" . substr( $globals->{Htmlfile}, length( $globals->{Htmldir} ) + 1);
        # Is the above not just "$globals->{Htmlfileurl} = $globals->{Htmlfile}"?
        $globals->{Htmlfileurl} = Pod::Html::_unixify($globals->{Htmlfile});

    }

    # load or generate/cache %Pages
    unless (get_cache($globals)) {
        # generate %Pages
        my $pwd = getcwd();
        chdir($globals->{Podroot}) ||
            die "$0: error changing to directory $globals->{Podroot}: $!\n";

        # find all pod modules/pages in podpath, store in %Pages
        # - callback used to remove Podroot and extension from each file
        # - laborious to allow '.' in dirnames (e.g., /usr/share/perl/5.14.1)
        Pod::Simple::Search->new->inc(0)->verbose($globals->{Verbose})->laborious(1)
            ->callback(\&_save_page)->recurse($globals->{Recurse})->survey(@{$globals->{Podpath}});

        chdir($pwd) || die "$0: error changing to directory $pwd: $!\n";

        # cache the directory list for later use
        warn "caching directories for later use\n" if $globals->{Verbose};
        open my $cache, '>', $globals->{Dircache}
            or die "$0: error open $globals->{Dircache} for writing: $!\n";

        print $cache join(":", @{$globals->{Podpath}}) . "\n$globals->{Podroot}\n";
        my $_updirs_only = ($globals->{Podroot} =~ /\.\./) && !($globals->{Podroot} =~ /[^\.\\\/]/);
        foreach my $key (keys %Pages) {
            if($_updirs_only) {
              my $_dirlevel = $globals->{Podroot};
              while($_dirlevel =~ /\.\./) {
                $_dirlevel =~ s/\.\.//;
                # Assume $Pages{$key} has '/' separators (html dir separators).
                $Pages{$key} =~ s/^[\w\s\-\.]+\///;
              }
            }
            print $cache "$key $Pages{$key}\n";
        }

        close $cache or die "error closing $globals->{Dircache}: $!";
    }

    my $input;
    unless (@ARGV && $ARGV[0]) {
        if ($globals->{Podfile} and $globals->{Podfile} ne '-') {
            $input = $globals->{Podfile};
        } else {
            $input = '-'; # XXX: make a test case for this
        }
    } else {
        $globals->{Podfile} = $ARGV[0];
        $input = *ARGV;
    }

    # set options for input parser
    my $parser = Pod::Simple::SimpleTree->new;
    # Normalize whitespace indenting
    $parser->strip_verbatim_indent(\&trim_leading_whitespace);

    $parser->codes_in_verbatim(0);
    $parser->accept_targets(qw(html HTML));
    $parser->no_errata_section(!$globals->{Poderrors}); # note the inverse

    warn "Converting input file $globals->{Podfile}\n" if $globals->{Verbose};
    my $podtree = $parser->parse_file($input)->root;

    unless(defined $globals->{Title}) {
	if($podtree->[0] eq "Document" && ref($podtree->[2]) eq "ARRAY" &&
		$podtree->[2]->[0] eq "head1" && @{$podtree->[2]} == 3 &&
		ref($podtree->[2]->[2]) eq "" && $podtree->[2]->[2] eq "NAME" &&
		ref($podtree->[3]) eq "ARRAY" && $podtree->[3]->[0] eq "Para" &&
		@{$podtree->[3]} >= 3 &&
		!(grep { ref($_) ne "" }
		    @{$podtree->[3]}[2..$#{$podtree->[3]}]) &&
		(@$podtree == 4 ||
		    (ref($podtree->[4]) eq "ARRAY" &&
			$podtree->[4]->[0] eq "head1"))) {
	    $globals->{Title} = join("", @{$podtree->[3]}[2..$#{$podtree->[3]}]);
	}
    }

    $globals->{Title} //= "";
    $globals->{Title} = html_escape($globals->{Title});

    # set options for the HTML generator
    $parser = Pod::Simple::XHTML::LocalPodLinks->new();
    $parser->codes_in_verbatim(0);
    $parser->anchor_items(1); # the old Pod::Html always did
    $parser->backlink($globals->{Backlink}); # linkify =head1 directives
    $parser->force_title($globals->{Title});
    $parser->htmldir($globals->{Htmldir});
    $parser->htmlfileurl($globals->{Htmlfileurl});
    $parser->htmlroot($globals->{Htmlroot});
    $parser->index($globals->{Doindex});
    $parser->output_string(\my $output); # written to file later
    $parser->pages(\%Pages);
    $parser->quiet($globals->{Quiet});
    $parser->verbose($globals->{Verbose});

    # We need to add this ourselves because we use our own header, not
    # ::XHTML's header. We need to set $parser->backlink to linkify
    # the =head1 directives
    my $bodyid = $globals->{Backlink} ? ' id="_podtop_"' : '';

    my $csslink = '';
    my $tdstyle = ' style="background-color: #cccccc; color: #000"';

    if ($globals->{Css}) {
        $csslink = qq(\n<link rel="stylesheet" href="$globals->{Css}" type="text/css" />);
        $csslink =~ s,\\,/,g;
        $csslink =~ s,(/.):,$1|,;
        $tdstyle= '';
    }

    # header/footer block
    my $block = $globals->{Header} ? <<END_OF_BLOCK : '';
<table border="0" width="100%" cellspacing="0" cellpadding="3">
<tr><td class="_podblock_"$tdstyle valign="middle">
<big><strong><span class="_podblock_">&nbsp;$globals->{Title}</span></strong></big>
</td></tr>
</table>
END_OF_BLOCK

    # create own header/footer because of --header
    $parser->html_header(<<"HTMLHEAD");
<?xml version="1.0" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>$globals->{Title}</title>$csslink
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link rev="made" href="mailto:$Config{perladmin}" />
</head>

<body$bodyid>
$block
HTMLHEAD

    $parser->html_footer(<<"HTMLFOOT");
$block
</body>

</html>
HTMLFOOT

    feed_tree_to_parser($parser, $podtree);

    # Write output to file
    $globals->{Htmlfile} = "-" unless $globals->{Htmlfile}; # stdout
    my $fhout;
    if($globals->{Htmlfile} and $globals->{Htmlfile} ne '-') {
        open $fhout, ">", $globals->{Htmlfile}
            or die "$0: cannot open $globals->{Htmlfile} file for output: $!\n";
    } else {
        open $fhout, ">-";
    }
    binmode $fhout, ":utf8";
    print $fhout $output;
    close $fhout or die "Failed to close $globals->{Htmlfile}: $!";
    chmod 0644, $globals->{Htmlfile} unless $globals->{Htmlfile} eq '-';
}

##############################################################################

sub usage {
    my $podfile = shift;
    warn "$0: $podfile: @_\n" if @_;
    die <<END_OF_USAGE;
Usage:  $0 --help --htmldir=<name> --htmlroot=<URL>
           --infile=<name> --outfile=<name>
           --podpath=<name>:...:<name> --podroot=<name>
           --cachedir=<name> --flush --recurse --norecurse
           --quiet --noquiet --verbose --noverbose
           --index --noindex --backlink --nobacklink
           --header --noheader --poderrors --nopoderrors
           --css=<URL> --title=<name>

  --[no]backlink  - turn =head1 directives into links pointing to the top of
                      the page (off by default).
  --cachedir      - directory for the directory cache files.
  --css           - stylesheet URL
  --flush         - flushes the directory cache.
  --[no]header    - produce block header/footer (default is no headers).
  --help          - prints this message.
  --htmldir       - directory for resulting HTML files.
  --htmlroot      - http-server base directory from which all relative paths
                      in podpath stem (default is /).
  --[no]index     - generate an index at the top of the resulting html
                      (default behaviour).
  --infile        - filename for the pod to convert (input taken from stdin
                      by default).
  --outfile       - filename for the resulting html file (output sent to
                      stdout by default).
  --[no]poderrors - include a POD ERRORS section in the output if there were 
                      any POD errors in the input (default behavior).
  --podpath       - colon-separated list of directories containing library
                      pods (empty by default).
  --podroot       - filesystem base directory from which all relative paths
                      in podpath stem (default is .).
  --[no]quiet     - suppress some benign warning messages (default is off).
  --[no]recurse   - recurse on those subdirectories listed in podpath
                      (default behaviour).
  --title         - title that will appear in resulting html file.
  --[no]verbose   - self-explanatory (off by default).

END_OF_USAGE

}

sub parse_command_line {
    my $globals = shift;
    my ($opt_backlink,$opt_cachedir,$opt_css,$opt_flush,$opt_header,
        $opt_help,$opt_htmldir,$opt_htmlroot,$opt_index,$opt_infile,
        $opt_outfile,$opt_poderrors,$opt_podpath,$opt_podroot,
        $opt_quiet,$opt_recurse,$opt_title,$opt_verbose);

    unshift @ARGV, split ' ', $Config{pod2html} if $Config{pod2html};
    my $result = GetOptions(
                       'backlink!'  => \$opt_backlink,
                       'cachedir=s' => \$opt_cachedir,
                       'css=s'      => \$opt_css,
                       'flush'      => \$opt_flush,
                       'help'       => \$opt_help,
                       'header!'    => \$opt_header,
                       'htmldir=s'  => \$opt_htmldir,
                       'htmlroot=s' => \$opt_htmlroot,
                       'index!'     => \$opt_index,
                       'infile=s'   => \$opt_infile,
                       'outfile=s'  => \$opt_outfile,
                       'poderrors!' => \$opt_poderrors,
                       'podpath=s'  => \$opt_podpath,
                       'podroot=s'  => \$opt_podroot,
                       'quiet!'     => \$opt_quiet,
                       'recurse!'   => \$opt_recurse,
                       'title=s'    => \$opt_title,
                       'verbose!'   => \$opt_verbose,
    );
    usage("-", "invalid parameters") if not $result;

    usage("-") if defined $opt_help;    # see if the user asked for help
    $opt_help = "";                     # just to make -w shut-up.

    @{$globals->{Podpath}}  = split(":", $opt_podpath) if defined $opt_podpath;

    $globals->{Backlink}  =          $opt_backlink   if defined $opt_backlink;
    $globals->{Cachedir}  = _unixify($opt_cachedir)  if defined $opt_cachedir;
    $globals->{Css}       =          $opt_css        if defined $opt_css;
    $globals->{Header}    =          $opt_header     if defined $opt_header;
    $globals->{Htmldir}   = _unixify($opt_htmldir)   if defined $opt_htmldir;
    $globals->{Htmlroot}  = _unixify($opt_htmlroot)  if defined $opt_htmlroot;
    $globals->{Doindex}   =          $opt_index      if defined $opt_index;
    $globals->{Podfile}   = _unixify($opt_infile)    if defined $opt_infile;
    $globals->{Htmlfile}  = _unixify($opt_outfile)   if defined $opt_outfile;
    $globals->{Poderrors} =          $opt_poderrors  if defined $opt_poderrors;
    $globals->{Podroot}   = _unixify($opt_podroot)   if defined $opt_podroot;
    $globals->{Quiet}     =          $opt_quiet      if defined $opt_quiet;
    $globals->{Recurse}   =          $opt_recurse    if defined $opt_recurse;
    $globals->{Title}     =          $opt_title      if defined $opt_title;
    $globals->{Verbose}   =          $opt_verbose    if defined $opt_verbose;

    warn "Flushing directory caches\n"
        if $opt_verbose && defined $opt_flush;
    $globals->{Dircache} = "$globals->{Cachedir}/pod2htmd.tmp";
    if (defined $opt_flush) {
        1 while unlink($globals->{Dircache});
    }
    return $globals;
}

sub get_cache {
    my $globals = shift;

    # A first-level cache:
    # Don't bother reading the cache files if they still apply
    # and haven't changed since we last read them.

    my $this_cache_key = cache_key($globals);
    return 1 if $globals->{Saved_Cache_Key} and $this_cache_key eq $globals->{Saved_Cache_Key};
    $globals->{Saved_Cache_Key} = $this_cache_key;

    # load the cache of %Pages if possible.  $tests will be
    # non-zero if successful.
    my $tests = 0;
    if (-f $globals->{Dircache}) {
        warn "scanning for directory cache\n" if $globals->{Verbose};
        $tests = load_cache($globals);
    }

    return $tests;
}

sub cache_key {
    my $globals = shift;
    return join('!',
        $globals->{Dircache},
        $globals->{Recurse},
        @{$globals->{Podpath}},
        $globals->{Podroot},
        stat($globals->{Dircache}),
    );
}

#
# load_cache - tries to find if the cache stored in $dircache is a valid
#  cache of %Pages.  if so, it loads them and returns a non-zero value.
#
sub load_cache {
    my $globals = shift;
    my $tests = 0;
    local $_;

    warn "scanning for directory cache\n" if $globals->{Verbose};
    open(my $cachefh, '<', $globals->{Dircache}) ||
        die "$0: error opening $globals->{Dircache} for reading: $!\n";
    $/ = "\n";

    # is it the same podpath?
    $_ = <$cachefh>;
    chomp($_);
    $tests++ if (join(":", @{$globals->{Podpath}}) eq $_);

    # is it the same podroot?
    $_ = <$cachefh>;
    chomp($_);
    $tests++ if ($globals->{Podroot} eq $_);

    # load the cache if its good
    if ($tests != 2) {
        close($cachefh);
        return 0;
    }

    warn "loading directory cache\n" if $globals->{Verbose};
    while (<$cachefh>) {
        /(.*?) (.*)$/;
        $Pages{$1} = $2;
    }

    close($cachefh);
    return 1;
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
    $rest =~ s/([[:^print:]])/sprintf("&#x%x;", ord($1))/aeg;
    return $rest;
}

#
# htmlify - converts a pod section specification to a suitable section
# specification for HTML.  We adopt the mechanism used by the formatter
# that we use.
#
sub htmlify {
    my( $heading) = @_;
    return Pod::Simple::XHTML->can("idify")->(undef, $heading, 1);
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

#
# store POD files in %Pages
#
sub _save_page {
    my ($modspec, $modname) = @_;

    # Remove Podroot from path
    $modspec = $Podroot eq File::Spec->curdir
               ? File::Spec->abs2rel($modspec)
               : File::Spec->abs2rel($modspec,
                                     File::Spec->canonpath($Podroot));

    # Convert path to unix style path
    $modspec = Pod::Html::_unixify($modspec);

    my ($file, $dir) = fileparse($modspec, qr/\.[^.]*/); # strip .ext
    $Pages{$modname} = $dir.$file;
}

sub _unixify {
    my $full_path = shift;
    return '' unless $full_path;
    return $full_path if $full_path eq '/';

    my ($vol, $dirs, $file) = File::Spec->splitpath($full_path);
    my @dirs = $dirs eq File::Spec->curdir()
               ? (File::Spec::Unix->curdir())
               : File::Spec->splitdir($dirs);
    if (defined($vol) && $vol) {
        $vol =~ s/:$// if $^O eq 'VMS';
        $vol = uc $vol if $^O eq 'MSWin32';

        if( $dirs[0] ) {
            unshift @dirs, $vol;
        }
        else {
            $dirs[0] = $vol;
        }
    }
    unshift @dirs, '' if File::Spec->file_name_is_absolute($full_path);
    return $file unless scalar(@dirs);
    $full_path = File::Spec::Unix->catfile(File::Spec::Unix->catdir(@dirs),
                                           $file);
    $full_path =~ s|^\/|| if $^O eq 'MSWin32'; # C:/foo works, /C:/foo doesn't
    $full_path =~ s/\^\././g if $^O eq 'VMS'; # unescape dots
    return $full_path;
}

package Pod::Simple::XHTML::LocalPodLinks;
use strict;
use warnings;
use parent 'Pod::Simple::XHTML';

use File::Spec;
use File::Spec::Unix;

__PACKAGE__->_accessorize(
 'htmldir',
 'htmlfileurl',
 'htmlroot',
 'pages', # Page name => relative/path/to/page from root POD dir
 'quiet',
 'verbose',
);

sub resolve_pod_page_link {
    my ($self, $to, $section) = @_;

    return undef unless defined $to || defined $section;
    if (defined $section) {
        $section = '#' . $self->idify($section, 1);
        return $section unless defined $to;
    } else {
        $section = '';
    }

    my $path; # path to $to according to %Pages
    unless (exists $self->pages->{$to}) {
        # Try to find a POD that ends with $to and use that.
        # e.g., given L<XHTML>, if there is no $Podpath/XHTML in %Pages,
        # look for $Podpath/*/XHTML in %Pages, with * being any path,
        # as a substitute (e.g., $Podpath/Pod/Simple/XHTML)
        my @matches;
        foreach my $modname (keys %{$self->pages}) {
            push @matches, $modname if $modname =~ /::\Q$to\E\z/;
        }

        # make it look like a path instead of a namespace
        my $modloc = File::Spec->catfile(split(/::/, $to));

        if ($#matches == -1) {
            warn "Cannot find file \"$modloc.*\" directly under podpath, " . 
                 "cannot find suitable replacement: link remains unresolved.\n"
                 if $self->verbose;
            return '';
        } elsif ($#matches == 0) {
            $path = $self->pages->{$matches[0]};
            my $matchloc = File::Spec->catfile(split(/::/, $path));
            warn "Cannot find file \"$modloc.*\" directly under podpath, but ".
                 "I did find \"$matchloc.*\", so I'll assume that is what you ".
                 "meant to link to.\n"
                 if $self->verbose;
        } else {
            # Use [-1] so newer (higher numbered) perl PODs are used
            # XXX currently, @matches isn't sorted so this is not true
            $path = $self->pages->{$matches[-1]};
            my $matchloc = File::Spec->catfile(split(/::/, $path));
            warn "Cannot find file \"$modloc.*\" directly under podpath, but ".
                 "I did find \"$matchloc.*\" (among others), so I'll use that " .
                 "to resolve the link.\n" if $self->verbose;
        }
    } else {
        $path = $self->pages->{$to};
    }

    my $url = File::Spec::Unix->catfile(Pod::Html::_unixify($self->htmlroot),
                                        $path);

    if ($self->htmlfileurl ne '') {
        # then $self->htmlroot eq '' (by definition of htmlfileurl) so
        # $self->htmldir needs to be prepended to link to get the absolute path
        # that will be relativized
        $url = Pod::Html::relativize_url(
            File::Spec::Unix->catdir(Pod::Html::_unixify($self->htmldir), $url),
            $self->htmlfileurl # already unixified
        );
    }

    return $url . ".html$section";
}

package Pod::Html;

#
# relativize_url - convert an absolute URL to one relative to a base URL.
# Assumes both end in a filename.
#
sub relativize_url {
    my ($dest, $source) = @_;

    # Remove each file from its path
    my ($dest_volume, $dest_directory, $dest_file) =
        File::Spec::Unix->splitpath( $dest );
    $dest = File::Spec::Unix->catpath( $dest_volume, $dest_directory, '' );

    my ($source_volume, $source_directory, $source_file) =
        File::Spec::Unix->splitpath( $source );
    $source = File::Spec::Unix->catpath( $source_volume, $source_directory, '' );

    my $rel_path = '';
    if ($dest ne '') {
       $rel_path = File::Spec::Unix->abs2rel( $dest, $source );
    }

    if ($rel_path ne '' && substr( $rel_path, -1 ) ne '/') {
        $rel_path .= "/$dest_file";
    } else {
        $rel_path .= "$dest_file";
    }

    return $rel_path;
}

# Remove any level of indentation (spaces or tabs) from each code block consistently
# Adapted from: https://metacpan.org/source/HAARG/MetaCPAN-Pod-XHTML-0.002001/lib/Pod/Simple/Role/StripVerbatimIndent.pm
sub trim_leading_whitespace {
    my ($para) = @_;

    # Start by converting tabs to spaces
    @$para = Text::Tabs::expand(@$para);

    # Find the line with the least amount of indent, as that's our "base"
    my @indent_levels = (sort(map { $_ =~ /^( *)./mg } @$para));
    my $indent        = $indent_levels[0] || "";

    # Remove the "base" amount of indent from each line
    foreach (@$para) {
        $_ =~ s/^\Q$indent//mg;
    }

    return;
}

1;
