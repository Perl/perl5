package FileHandle;

# Note that some additional FileHandle methods are defined in POSIX.pm.

=head1 NAME

FileHandle - supply object methods for filehandles

cacheout - keep more files open than the system permits

=head1 SYNOPSIS

    use FileHandle;
    autoflush STDOUT 1;

    cacheout($path);
    print $path @data;

=head1 DESCRIPTION

See L<perlvar> for complete descriptions of each of the following supported C<FileHandle> 
methods:

    autoflush
    output_field_separator
    output_record_separator
    input_record_separator
    input_line_number
    format_page_number
    format_lines_per_page
    format_lines_left
    format_name
    format_top_name
    format_line_break_characters
    format_formfeed

Furthermore, for doing normal I/O you might need these:

=over 

=item $fh->print

See L<perlfunc/print>.

=item $fh->printf

See L<perlfunc/printf>.

=item $fh->getline

This works like <$fh> described in L<perlop/"I/O Operators"> except that it's more readable 
and can be safely called in an array context but still
returns just one line.

=item $fh->getlines

This works like <$fh> when called in an array context to
read all the remaining lines in a file, except that it's more readable.
It will also croak() if accidentally called in a scalar context.

=back

=head2 The cacheout() Library

The cacheout() function will make sure that there's a filehandle
open for writing available as the pathname you give it.  It automatically
closes and re-opens files if you exceed your system file descriptor maximum.

=head1 SEE ALSO

L<perlfunc>, 
L<perlop/"I/O Operators">,
L<POSIX/"FileHandle">

=head1 BUGS

F<sys/param.h> lies with its C<NOFILE> define on some systems,
so you may have to set $cacheout::maxopen yourself.

Some of the methods that set variables (like format_name()) don't
seem to work.

The POSIX functions that create FileHandle methods should be
in this module instead.

Due to backwards compatibility, all filehandles resemble objects
of class C<FileHandle>, or actually classes derived from that class.
They actually aren't.  Which means you can't derive your own 
class from C<FileHandle> and inherit those methods.

=cut

require 5.000;
use English;
use Carp;
use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(
    autoflush
    output_field_separator
    output_record_separator
    input_record_separator
    input_line_number
    format_page_number
    format_lines_per_page
    format_lines_left
    format_name
    format_top_name
    format_line_break_characters
    format_formfeed

    print
    printf
    getline
    getlines

    cacheout
);

sub print {
    local($this) = shift;
    print $this @_;
}

sub printf {
    local($this) = shift;
    printf $this @_;
}

sub getline {
    local($this) = shift;
    croak "usage: FileHandle::getline()" if @_;
    return scalar <$this>;
} 

sub getlines {
    local($this) = shift;
    croak "usage: FileHandle::getline()" if @_;
    croak "can't call FileHandle::getlines in a scalar context" if wantarray;
    return <$this>;
} 

sub autoflush {
    local($old) = select($_[0]);
    local($prev) = $OUTPUT_AUTOFLUSH;
    $OUTPUT_AUTOFLUSH = @_ > 1 ? $_[1] : 1;
    select($old);
    $prev;
}

sub output_field_separator {
    local($old) = select($_[0]);
    local($prev) = $OUTPUT_FIELD_SEPARATOR;
    $OUTPUT_FIELD_SEPARATOR = $_[1] if @_ > 1;
    select($old);
    $prev;
}

sub output_record_separator {
    local($old) = select($_[0]);
    local($prev) = $OUTPUT_RECORD_SEPARATOR;
    $OUTPUT_RECORD_SEPARATOR = $_[1] if @_ > 1;
    select($old);
    $prev;
}

sub input_record_separator {
    local($old) = select($_[0]);
    local($prev) = $INPUT_RECORD_SEPARATOR;
    $INPUT_RECORD_SEPARATOR = $_[1] if @_ > 1;
    select($old);
    $prev;
}

sub input_line_number {
    local($old) = select($_[0]);
    local($prev) = $INPUT_LINE_NUMBER;
    $INPUT_LINE_NUMBER = $_[1] if @_ > 1;
    select($old);
    $prev;
}

sub format_page_number {
    local($old) = select($_[0]);
    local($prev) = $FORMAT_PAGE_NUMBER;
    $FORMAT_PAGE_NUMBER = $_[1] if @_ > 1;
    select($old);
    $prev;
}

sub format_lines_per_page {
    local($old) = select($_[0]);
    local($prev) = $FORMAT_LINES_PER_PAGE;
    $FORMAT_LINES_PER_PAGE = $_[1] if @_ > 1;
    select($old);
    $prev;
}

sub format_lines_left {
    local($old) = select($_[0]);
    local($prev) = $FORMAT_LINES_LEFT;
    $FORMAT_LINES_LEFT = $_[1] if @_ > 1;
    select($old);
    $prev;
}

sub format_name {
    local($old) = select($_[0]);
    local($prev) = $FORMAT_NAME;
    $FORMAT_NAME = $_[1] if @_ > 1;
    select($old);
    $prev;
}

sub format_top_name {
    local($old) = select($_[0]);
    local($prev) = $FORMAT_TOP_NAME;
    $FORMAT_TOP_NAME = $_[1] if @_ > 1;
    select($old);
    $prev;
}

sub format_line_break_characters {
    local($old) = select($_[0]);
    local($prev) = $FORMAT_LINE_BREAK_CHARACTERS;
    $FORMAT_LINE_BREAK_CHARACTERS = $_[1] if @_ > 1;
    select($old);
    $prev;
}

sub format_formfeed {
    local($old) = select($_[0]);
    local($prev) = $FORMAT_FORMFEED;
    $FORMAT_FORMFEED = $_[1] if @_ > 1;
    select($old);
    $prev;
}


# --- cacheout functions ---

# Open in their package.

sub cacheout_open {
    my $pack = caller(1);
    open(*{$pack . '::' . $_[0]}, $_[1]);
}

sub cacheout_close {
    my $pack = caller(1);
    close(*{$pack . '::' . $_[0]});
}

# But only this sub name is visible to them.

sub cacheout {
    ($file) = @_;
    if (!$cacheout_maxopen){
	if (open(PARAM,'/usr/include/sys/param.h')) {
	    local($.);
	    while (<PARAM>) {
		$cacheout_maxopen = $1 - 4
		    if /^\s*#\s*define\s+NOFILE\s+(\d+)/;
	    }
	    close PARAM;
	}
	$cacheout_maxopen = 16 unless $cacheout_maxopen;
    }
    if (!$isopen{$file}) {
	if (++$cacheout_numopen > $cacheout_maxopen) {
	    local(@lru) = sort {$isopen{$a} <=> $isopen{$b};} keys(%isopen);
	    splice(@lru, $cacheout_maxopen / 3);
	    $cacheout_numopen -= @lru;
	    for (@lru) { &cacheout_close($_); delete $isopen{$_}; }
	}
	&cacheout_open($file, ($saw{$file}++ ? '>>' : '>') . $file)
	    || croak("Can't create $file: $!");
    }
    $isopen{$file} = ++$cacheout_seq;
}

$cacheout_seq = 0;
$cacheout_numopen = 0;

1;
