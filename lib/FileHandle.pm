package FileHandle;

BEGIN {
    require 5.000;
    require English; import English;
    require Exporter;
}

@ISA = (Exporter);
@EXPORT = qw(
    print
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
);

sub print {
    local($this) = shift;
    print $this @_;
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

1;
