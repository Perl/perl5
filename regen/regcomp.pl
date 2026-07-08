#!/usr/bin/perl -w
#
#
# Regenerate (overwriting only if changed):
#
#    pod/perldebguts.pod
#    regnodes.h
#
# from information stored in
#
#    regcomp.sym
#    op_reg_common.h
#    regexp.h
#
# pod/perldebguts.pod is not completely regenerated.  Only the table of
# regexp nodes is replaced; other parts remain unchanged.
#
# Accepts the standard regen_lib -q and -v args.
#
# This script is normally invoked from regen.pl.
#
# F<regcomp.sym> defines the opcodes and states used in the regex
# engine in a Perl-data format.  This script parses that input into the
# internal model, and turns that into typedefs, defines, and data
# structures, and maybe even code which the regex engine can use to operate.
#
# F<regexp.h> and op_reg_common.h contain defines C<RXf_xxx> and
# C<PREGf_xxx> that are used in flags in our code. These defines are
# parsed out and data structures are created to allow the debug mode of
# the regex engine to show things such as which flags were set during
# compilation. In some cases we transform the C code in the header files
# into perl code which we execute to C<eval()> the contents. For instance
# in a situation like this:
#
#   #define RXf_X 0x1   /* the X mode */
#   #define RXf_Y 0x2   /* the Y mode */
#   #define RXf_Z (X|Y) /* the Z mode */
#
# this script might end up eval()ing something like C<0x1> and then
# C<0x2> and then C<(0x1|0x2)> the results of which it then might use in
# constructing a data structure, or pod in perldebguts, or a comment in
# C<regnodes.h>. It also would separate out the "X", "Y", and "Z" and
# use them, and would also use the data in the line comment if present.
#
# If you compile a regex under perl -Mre=Debug,ALL you can see much
# of the content that this file generates and parses out of its input
# files.

BEGIN {
    # Get function prototypes
    require './regen/regen_lib.pl';
    require './regen/HeaderParser.pm';
}

use strict;
use Getopt::Long ();
use Getopt::Long qw(GetOptions);
use Text::Wrap ();
use Scalar::Util;

# NOTE I don't think anyone actually knows what all of these properties mean,
# and I suspect some of them are outright unused. Now that we are using a pure
# data driven approach with no domain specific config in the middle it should be
# easier to clean it up.
#
# We use the term regnode and node to difference these ops from those used
# by Perl directly to represent a program. They are entirely different ops.
#
# General thoughts:
# 1. We use a single continuum to represent both opcodes and states,
#    and in regexec.c we switch on the combined set.
# 2. Opcodes have more information associated to them, states are simpler,
#    basically just an identifier/number that can be used to switch within
#    the state machine.
# 3. Some opcode are order dependent. In particular the order of opcodes
#    in a group may be sensitive. Randomly inserting a new regnode just
#    anywhere is not a good idea. Add it to the end of a group or create a new
#    group and you should be fine.
# 4. Output files often use "tricks" to reduce diff effects. Some of what
#    we do below is more clumsy looking than it could be because of this.

# Op/state properties:
#
# Note this is not an exact mirror of the original definitions - in the long run
# we can unify them together.
#
# Property      In      Descr
# ----------------------------------------------------------------------------
# name          Both    Name of op/state
# id            Both    integer value for this opcode/state
# optype        Both    Either 'op' or 'state'
# line_num      Both    line number of the input file for this item.
# type          Op      Effective regnode type
# attr          Op      Authored regcomp.sym attributes
# struct        Op      Authored or defaulted regnode struct name
# desc          Op      Authored description text
# pod           Op      Authored pod text
# comment       Both    Maintainer-facing note text

# Global State
my @all;    # all opcodes/state
my %all;    # hash of all opcode/state names

my @ops;    # array of just opcodes
my @states; # array of just states
my @state_defs; # authored state definitions before expansion
my @ops_groups_for_output;
my $definition_model;

our (@Changed, $Verbose);

my $longest_name_length= 0; # track lengths of names for nicer reports
my (%type_alias);           # map the type (??)
my @definition_warnings;

sub emit_definition_warning {
    my ($message) = @_;

    chomp $message;
    push @definition_warnings, $message;
    warn "$message\n";
}

sub die_if_definition_warnings {
    return if !@definition_warnings;

    my $count = scalar @definition_warnings;
    die "Aborting regen/regcomp.pl after $count warning"
        . ($count == 1 ? "" : "s")
        . " while validating regcomp.sym\n";
}

# register a newly constructed node into our state tables.
# ensures that we have no name collisions (on name anyway),
# and issues the "id" for the node.
sub register_node {
    my ($node)= @_;

    if ( $all{ $node->{name} } ) {
        die "Duplicate item '$node->{name}' in regcomp.sym line $node->{line_num} "
            . "previously defined on line $all{ $node->{name} }{line_num}\n";
    } elsif (!$node->{optype}) {
        die "must have an optype in node ", Dumper($node);
    } elsif ($node->{optype} eq "op") {
        push @ops, $node;
    } elsif ($node->{optype} eq "state") {
        push @states, $node;
    } else {
        die "Uknown optype '$node->{optype}' in ", Dumper($node);
    }
    $node->{id}= 0 + @all;
    push @all, $node;
    $all{ $node->{name} }= $node;

    if (($node->{attr} && $node->{attr}{off_by_arg})
        && $node->{attr}{off_by_arg} != 1)
    {
        die "attr.off_by_arg field must be in [01] if present in ", Dumper($node);
    }

}

# parse out a state definition and add the resulting data
# into the global state. may create multiple new states from
# a single definition (this is part of the point).
# Format for states:
# REGOP \t typelist [ \t typelist]
# typelist= namelist
#         = namelist:FAIL
#         = name:count
# Eg:
# WHILEM          A_pre,A_min,A_max,B_min,B_max:FAIL
# BRANCH          next:FAIL
# CURLYM          A,B:FAIL
#
# The CURLYM definition would create the states:
# CURLYM_A, CURLYM_A_fail, CURLYM_B, CURLYM_B_fail
sub parse_state_def {
    my ( $text, $line_num, $pod_comment, $note_comment )= @_;
    my ( $type, @lists )= split /\s+/, $text;
    die "No transitions for state group '$type' at regcomp.sym line $line_num\n" if !@lists;
    push @state_defs, {
        type        => $type,
        transitions => join(" ", @lists),
        pod_comment => $pod_comment,
        note_comment => $note_comment,
        line_num    => $line_num,
    };
    foreach my $list (@lists) {
        my ( $names, $special )= split /:/, $list, 2;
        $special ||= "";
        foreach my $name ( split /,/, $names ) {
            my $real=
                $name eq 'resume'
                ? "resume_$type"
                : "${type}_$name";
            my @suffix;
            if ( !$special ) {
                @suffix= ("");
            }
            elsif ( $special =~ /\d/ ) {
                @suffix= ( 1 .. $special );
            }
            elsif ( $special eq 'FAIL' ) {
                @suffix= ( "", "_fail" );
            }
            else {
                die "unknown state transition suffix ':$special' at regcomp.sym line $line_num\n";
            }
            foreach my $suffix (@suffix) {
                my $node= {
                    name        => "$real$suffix",
                    optype      => "state",
                    type        => $type || "",
                    comment     => "state for $type",
                    note_comment => $note_comment,
                    line_num    => $line_num,
                };
                register_node($node);
            }
        }
    }
}

sub process_flags {
    my ( $attr_name, $varname, $comment )= @_;
    $comment= '' unless defined $comment;

    my @selected;
    my $bitmap= '';
    for my $node (@ops) {
        my $set = $node->{attr} && $node->{attr}{$attr_name} ? 1 : 0;

        # Whilst I could do this with vec, I'd prefer to do longhand the arithmetic
        # ops in the C code.
        my $current= do {
            no warnings;
            ord substr $bitmap, ( $node->{id} >> 3 );
        };
        substr( $bitmap, ( $node->{id} >> 3 ), 1 )=
            chr( $current | ( $set << ( $node->{id} & 7 ) ) );

        push @selected, $node->{name} if $set;
    }
    my $bits = unpack("B*", $bitmap);

    my $out_string= join ', ', @selected, 0;
    $out_string =~ s/(.{1,70},) /$1\n    /g;

    my $out_mask= join ', ', map { sprintf "0x%02X", ord $_ } split '', $bitmap;


    return $comment . <<"EOP";
#define REGNODE_\U$varname\E(node) (PL_${varname}_bitmask[(node) >> 3] & (1 << ((node) & 7)))

EXTCONST U8 PL_${varname}\[] __attribute__deprecated__
INIT({ $out_string });

/* $varname: $bits */
EXTCONST U8 PL_${varname}_bitmask[] INIT({ $out_mask });
EOP
}

sub print_process_EXACTish {
    my ($out)= @_;

    # Creates some bitmaps for EXACTish nodes.

    my @folded;
    my @req8;

    my $base;
    for my $node (@ops) {
        next unless $node->{type} eq 'EXACT';
        my $name = $node->{name};
        $base = $node->{id} if $name eq 'EXACT';

        my $index = $node->{id} - $base;

        # This depends entirely on naming conventions in regcomp.sym
        $folded[$index] = $name =~ /^EXACTF/ || 0;
        $req8[$index] = $name =~ /8/ || 0;
    }

    die "Can't cope with > 32 EXACTish nodes" if @folded > 32;

    my $exactf = sprintf "%X", oct("0b" . join "", reverse @folded);
    my $req8 =   sprintf "%X", oct("0b" . join "", reverse @req8);
    print $out <<EOP,

/* Is 'op', known to be of type EXACT, folding? */
#define isEXACTFish(op) (assert(REGNODE_TYPE(op) == EXACT), (PL_EXACTFish_bitmask & (1U << (op - EXACT))))

/* Do only UTF-8 target strings match 'op', known to be of type EXACT? */
#define isEXACT_REQ8(op) (assert(REGNODE_TYPE(op) == EXACT), (PL_EXACT_REQ8_bitmask & (1U << (op - EXACT))))

EXTCONST U32 PL_EXACTFish_bitmask INIT(0x$exactf);
EXTCONST U32 PL_EXACT_REQ8_bitmask INIT(0x$req8);
EOP
}

sub effective_struct {
    my ($op) = @_;

    return $op->{struct} // 'regnode';
}

sub struct_suffix {
    my ($op) = @_;

    my $struct = effective_struct($op);
    return "" if $struct eq 'regnode';

    $struct =~ /^regnode_(.+)\z/
        or die "Invalid struct '$struct' in Perl data";
    return $1;
}

sub rendered_desc {
    my ($node) = @_;

    return format_desc_input($node->{desc}) if $node->{optype} eq 'op';
    return $node->{comment} // "";
}

sub normalize_perl_op {
    my ($group, $op, $line_num, $group_entry) = @_;

    my $attr = $op->{attr} || {};
    my $struct = effective_struct($op);
    if (defined $struct) {
        die "Invalid struct '$struct' in Perl data at regcomp.sym line "
            . ($op->{line} // $group->{line} // $line_num)
            . "; expected regnode or regnode_*\n"
            if $struct ne 'regnode' && $struct !~ /^regnode_(.+)\z/;
    }
    my $group_types = group_type_list($group, $line_num);
    my $group_default_type = group_default_type($group, $line_num);
    my $node = {
        name        => $op->{NAME},
        optype      => 'op',
        line_num    => $op->{line} // $group->{line} // $line_num || 0,
        GROUP       => $group->{GROUP} // $group->{TYPE},
        pod         => $op->{pod},
        comment     => $op->{comment},
        desc        => $op->{desc},
        type        => $op->{TYPE} // $group_default_type,
        attr        => $attr,
        struct      => $struct,
    };

    die "ops_group requires op TYPE in regcomp.sym at line "
        . ($op->{line} // $group->{line} // $line_num) . "\n"
        if !defined $node->{type};
    die "op (" . describe_op($op, $line_num) . ") is not allowed by group ("
        . describe_group($group, $line_num) . ") in regcomp.sym\n"
        if !group_type_allows($group_types, $node->{type});

    register_node($node);
    push @{ $group_entry->{ops} }, $node;

    if ( !$all{ $node->{type} } and !$type_alias{ $node->{type} } ) {
        $type_alias{ $node->{type} } = $node->{name};
    }

    $longest_name_length = length $node->{name}
        if length $node->{name} > $longest_name_length;
}

sub group_type_list {
    my ($group, $line_num) = @_;

    my $value = $group->{TYPE};
    my $group_line = $group->{line} // $line_num;

    die "ops_group missing TYPE in regcomp.sym at line $group_line\n"
        if !exists $group->{TYPE};

    if (!ref $value) {
        return [$value];
    }

    die "ops_group TYPE must be a string or arrayref in regcomp.sym at line $group_line\n"
        if ref($value) ne 'ARRAY';
    die "ops_group TYPE array may not be empty in regcomp.sym at line $group_line\n"
        if !@$value;

    @$value = sort @$value;

    for my $type (@$value) {
        die "ops_group TYPE array contains undef in regcomp.sym at line $group_line\n"
            if !defined $type;
        die "ops_group TYPE array may only contain strings in regcomp.sym at line $group_line\n"
            if ref($type);
        die "ops_group TYPE array may not contain '__MIXED__' in regcomp.sym at line $group_line\n"
            if $type eq '__MIXED__';
    }

    return $value;
}

sub group_default_type {
    my ($group, $line_num) = @_;

    my $types = group_type_list($group, $line_num);
    return undef if @$types != 1;
    return undef if $types->[0] eq '__MIXED__';
    return $types->[0];
}

sub group_type_allows {
    my ($types, $type) = @_;

    return 1 if @$types == 1 && $types->[0] eq '__MIXED__';
    return scalar grep { $_ eq $type } @$types;
}

sub describe_group {
    my ($group, $line_num) = @_;

    my $group_line = $group->{line} // $line_num;
    my @parts;

    push @parts, "GROUP '$group->{GROUP}'" if exists $group->{GROUP};
    if (exists $group->{TYPE}) {
        my $type_desc = ref($group->{TYPE}) eq 'ARRAY'
            ? "[" . join(", ", @{ $group->{TYPE} }) . "]"
            : "'$group->{TYPE}'";
        push @parts, "TYPE $type_desc";
    }

    push @parts, "line $group_line";
    return join ", ", @parts;
}

sub describe_op {
    my ($op, $line_num) = @_;

    my $op_line = $op->{line} // $line_num;
    my @parts;

    push @parts, "name '$op->{NAME}'" if exists $op->{NAME};
    push @parts, "type '$op->{TYPE}'" if exists $op->{TYPE};
    push @parts, "line $op_line";

    return join ", ", @parts;
}

sub warn_on_duplicate_group_types {
    my ($groups, $kind, $file) = @_;

    my %seen;
    for my $idx (0 .. $#$groups) {
        my $group = $groups->[$idx];
        next if !exists $group->{TYPE};
        for my $type (@{ group_type_list($group, $idx + 1) }) {
            push @{ $seen{$type} }, ($group->{line} // ($idx + 1));
        }
    }

    for my $type (sort keys %seen) {
        next if $type eq '__MIXED__';
        next if @{ $seen{$type} } < 2;
        emit_definition_warning(sprintf
            "Warning: %s contains multiple group definition blocks for TYPE '%s' in %s at lines %s\n",
            $file,
            $type,
            $kind,
            join(", ", @{ $seen{$type} }));
    }
}

sub read_definition {
    my ( $file )= @_;
    my $load_file = $file =~ m{/} ? $file : "./$file";
    my $data = do $load_file;

    die "Failed loading '$file': $@" if $@;
    die "Failed loading '$file': $!" if !defined $data && $!;
    die "Perl data file '$file' did not return a hashref"
        if ref($data) ne 'HASH';

    $definition_model = $data;
    @ops_groups_for_output = ();

    warn_on_duplicate_group_types($data->{ops_groups} || [], "ops_groups", $file);
    warn_on_duplicate_group_types($data->{state_groups} || [], "state_groups", $file);

    my $line_num = 0;
    for my $group (@{ $data->{ops_groups} || [] }) {
        $line_num++;
        my $group_line = $group->{line} // $line_num;
        my $group_entry = {
            group => $group,
            ops   => [],
        };
        push @ops_groups_for_output, $group_entry;
        my $group_types = group_type_list($group, $group_line);
        die "non-scalar ops_group TYPE in '$file' at line $group_line requires GROUP\n"
            if ref($group->{TYPE}) && !exists($group->{GROUP});
        die "mixed ops_group in '$file' at line $group_line requires GROUP\n"
            if $group->{TYPE} eq '__MIXED__' && !exists($group->{GROUP});
        die "ops_group missing ops array in '$file' at line $group_line\n"
            if ref($group->{ops}) ne 'ARRAY';
        emit_definition_warning(
            "Warning: ops_group in '$file' (" . describe_group($group, $group_line) . ") has no ops"
        ) if !@{ $group->{ops} };
        for my $idx (0 .. $#{ $group->{ops} }) {
            my $op = $group->{ops}[$idx];
            $line_num++;
            my $op_line = $op->{line} // $group_line;
            die "ops_group in '$file' at line $group_line requires op TYPE at line $op_line\n"
                if !exists($op->{TYPE}) && !defined group_default_type($group, $group_line);
            die "op (" . describe_op($op, $op_line) . ") is not allowed by group ("
                . describe_group($group, $group_line) . ") in '$file'\n"
                if exists($op->{TYPE})
                    && !group_type_allows($group_types, $op->{TYPE});
            die "op TYPE '__MIXED__' is not allowed in '$file' at line $op_line\n"
                if exists($op->{TYPE}) && $op->{TYPE} eq '__MIXED__';
            normalize_perl_op($group, $op, $line_num, $group_entry);
        }
    }

    for my $group (@{ $data->{state_groups} || [] }) {
        $line_num++;
        my $group_line = $group->{line} // $line_num;
        my $type = $group->{TYPE}
            or die "state_group missing TYPE in '$file' at line $group_line\n";
        die "state_group for '$type' needs transitions in '$file' at line $group_line\n"
            if !defined $group->{transitions};
        my @lists = split /\s+/, $group->{transitions};
        parse_state_def(
            join(" ", $type, @lists),
            $group_line,
            format_pod_input($group->{pod}),
            $group->{comment} // "",
        );
    }

    die "Too many regexp/state opcodes! Maximum is 256, but there are ", 0 + @all,
        " in file!"
        if @all > 256;

    die_if_definition_warnings();
}

sub normalize_pod_fragment {
    my ($text) = @_;

    $text = "" if !defined $text;

    $text = normalize_note_fragment($text);
    $text =~ s/^\#\s*//;

    return $text;
}

sub normalize_desc_fragment {
    my ($text) = @_;

    return normalize_note_fragment($text);
}

sub format_pod_input {
    my ($value) = @_;

    return "" if !defined $value;
    return join "\n\n", @{ normalize_text_paragraphs($value, "pod") };
}

sub format_desc_input {
    my ($value) = @_;

    return "" if !defined $value;
    return join "\n\n", @{ normalize_text_paragraphs($value, "desc") };
}

sub format_pod_output {
    my ($text) = @_;

    $text = "" if !defined $text;
    return "" if $text eq "";
    my @paragraphs = map {
        [ grep { length } map { normalize_pod_fragment($_) } split /\n/, $_ ]
    } split /\n(?:\s*\n)+/, $text;
    @paragraphs = grep { @$_ } @paragraphs;

    return "" if !@paragraphs;
    return $paragraphs[0][0] if @paragraphs == 1 && @{ $paragraphs[0] } == 1;
    return $paragraphs[0] if @paragraphs == 1;

    my @out;
    for my $para (@paragraphs) {
        push @out, [ @$para ];
    }
    return \@out;
}

sub normalize_note_fragment {
    my ($text) = @_;

    $text = "" if !defined $text;
    $text =~ s/[\t\r\n\f]+/ /g;
    $text =~ s/\s+#\s+/ /g;
    $text =~ s/\s+#\s*\z//;
    $text =~ s/(?<!\w)#{2,}(?!\w)/ /g;
    $text =~ s/\. {2,}/.\0/g;
    $text =~ s/ {2,}/ /g;
    $text =~ s/\0/  /g;
    $text =~ s/^ //;
    $text =~ s/ $//;

    return $text;
}

sub format_pod_fragment_for_output {
    my ($text) = @_;

    $text = "" if !defined $text;
    return "" if $text eq "";

    my @out;
    for my $para (split /\n(?:\s*\n)+/, $text) {
        my $line = join " ",
                   grep { length }
                   map { normalize_pod_fragment($_) } split /\n/, $para;
        next if !length $line;
        local $Text::Wrap::columns = 76;
        local $Text::Wrap::unexpand = 0;
        push @out, strip_trailing_horizontal_whitespace(
            Text::Wrap::wrap("# ", "# ", $line)
        );
    }

    return "\n" . join("\n#\n", @out) . "\n";
}

sub normalize_text_paragraphs {
    my ($value, $kind) = @_;

    my $normalize = $kind eq 'pod'
        ? \&normalize_pod_fragment
        : \&normalize_desc_fragment;

    return [ $normalize->($value) ] if !ref($value);

    die ucfirst($kind) . " content must be a scalar or arrayref\n"
        if ref($value) ne 'ARRAY';

    my @paragraphs;
    my @current;
    for my $elem (@$value) {
        if (!ref($elem)) {
            push @current, $normalize->($elem);
            next;
        }

        die ucfirst($kind) . " content only supports one level of nested arrays\n"
            if ref($elem) ne 'ARRAY';

        push @paragraphs, join(" ", grep { length } @current) if @current;
        @current = ();

        my @paragraph = map {
            die ucfirst($kind) . " content only supports one level of nested arrays\n"
                if ref($_);
            $normalize->($_);
        } @$elem;
        push @paragraphs, join(" ", grep { length } @paragraph);
    }
    push @paragraphs, join(" ", grep { length } @current) if @current;

    return \@paragraphs;
}

sub perl_quote {
    my ($text) = @_;

    $text = "" if !defined $text;
    $text =~ s/\\/\\\\/g;
    $text =~ s/"/\\"/g;
    $text =~ s/\$/\\\$/g;
    $text =~ s/@/\\@/g;
    $text =~ s/\n/\\n/g;
    $text =~ s/\r/\\r/g;
    $text =~ s/\t/\\t/g;
    $text =~ s/\f/\\f/g;

    return qq{"$text"};
}

sub reftype { Scalar::Util::reftype($_[0]) // "" }

sub is_numeric_scalar {
    my ($value) = @_;

    return defined($value) && !ref($value) && $value =~ /\A(?:0|[1-9][0-9]*)\z/;
}

sub wrap_quoted_string_parts {
    my ($text, $columns) = @_;

    my $quoted = perl_quote($text);
    return ($quoted) if length($quoted) <= $columns;

    my $inner = substr($quoted, 1, -1);
    local $Text::Wrap::columns = $columns - 2 > 20 ? $columns - 2 : 20;
    local $Text::Wrap::unexpand = 0;
    my $wrapped = Text::Wrap::wrap('', '', $inner);
    my @parts = split /\n/, $wrapped;
    for my $i (0 .. $#parts - 1) {
        $parts[$i] .= " ";
    }
    return map { qq{"$_"} } @parts;
}

sub dump_scalar_parts {
    my ($value, $columns, $key) = @_;

    return ($value) if defined($key) && $key eq 'line' && $value eq '__LINE__';
    return ($value) if is_numeric_scalar($value);
    return wrap_quoted_string_parts($value, $columns);
}

sub dump_inline_scalar_array {
    my ($value) = @_;

    return undef if reftype($value) ne 'ARRAY';
    return undef if !@$value;
    return undef if reftype($value->[0]);

    return "[ " . join(", ", map { perl_quote($_) } @$value) . " ]";
}

sub dump_scalar {
    my ($value, $level, $key) = @_;

    my $indent = "  " x $level;
    my @parts = dump_scalar_parts($value, 80 - length($indent), $key);
    return map { $indent . $_ } @parts;
}

sub dump_nested_field {
    my ($key_text, $value, $level, $path) = @_;

    my $child_indent = "  " x ($level + 1);
    my @parts = dump_any($value, $level + 2, $path);
    my $first = shift @parts;
    my $grandchild_indent = "  " x ($level + 2);
    $first =~ s/^\Q$grandchild_indent\E//;

    my @lines = ($child_indent . $key_text . " " . $first);
    $parts[-1] .= "," if @parts;
    push @lines, @parts;
    return @lines;
}

sub dump_field {
    my ($key, $value, $level, $path) = @_;

    my $child_indent = "  " x ($level + 1);
    my $key_text = perl_quote($key) . " =>";

    if (!ref $value) {
        my @parts = dump_scalar_parts(
            $value,
            80 - length($child_indent) - length($key_text) - 1,
            $key,
        );

        if (@parts == 1) {
            return ($child_indent . $key_text . " " . $parts[0] . ",");
        }

        my @lines = ($child_indent . $key_text);
        for my $i (0 .. $#parts) {
            my $suffix = $i == $#parts ? "," : " .";
            push @lines, ("  " x ($level + 2)) . $parts[$i] . $suffix;
        }
        return @lines;
    }

    if ($key eq 'TYPE') {
        my $inline = dump_inline_scalar_array($value);
        return ($child_indent . $key_text . " " . $inline . ",")
            if defined $inline;
    }

    if ($key eq 'pod' || $key eq 'desc') {
        return dump_nested_field($key_text, $value, $level, $path);
    }

    return dump_nested_field($key_text, $value, $level, $path);
}

sub dump_arrayref {
    my ($value, $level, $path) = @_;

    $path ||= [];

    my $indent = "  " x $level;
    my $child_indent = "  " x ($level + 1);
    return ($indent . "[]") if !@$value;

    my @lines = ($indent . "[");
    for my $idx (0 .. $#$value) {
        my $elem = $value->[$idx];
        if (!ref $elem) {
            my @parts = dump_scalar_parts($elem, 80 - length($child_indent));
            if (@parts == 1) {
                push @lines, $child_indent . $parts[0] . ",";
            }
            else {
                for my $i (0 .. $#parts) {
                    my $suffix = $i == $#parts ? "," : " .";
                    push @lines, $child_indent . $parts[$i] . $suffix;
                }
            }
        }
        else {
            if (
                reftype($elem) eq 'HASH'
                && $idx > 0
                && reftype($value->[$idx - 1]) eq 'HASH'
                && @$path == 1
                && (
                    $path->[0] eq 'ops_groups'
                    || $path->[0] eq 'state_groups'
                )
            ) {
                push @lines, $child_indent . "#################################";
            }
            my @parts = dump_any($elem, $level + 1, [ @$path, $idx ]);
            $parts[-1] .= "," if @parts;
            push @lines, @parts;
        }
    }
    push @lines, $indent . "]";
    return @lines;
}

sub dump_hashref {
    my ($value, $level, $path) = @_;

    $path ||= [];

    my $indent = "  " x $level;
    return ($indent . "{}") if !%$value;

    my @lines = ($indent . "{");
    for my $key (sort keys %$value) {
        push @lines, dump_field($key, $value->{$key}, $level, [ @$path, $key ]);
    }
    push @lines, $indent . "}";
    return @lines;
}

sub dump_any {
    my ($value, $level, $path, $key) = @_;

    $path ||= [];

    my $kind = reftype($value);
    return dump_scalar($value, $level, $key) if !$kind;
    return dump_arrayref($value, $level, $path) if $kind eq 'ARRAY';
    return dump_hashref($value, $level, $path) if $kind eq 'HASH';

    die "Unsupported data type in dump: $kind";
}

sub strip_trailing_horizontal_whitespace {
    my ($text) = @_;

    $text =~ s/[ \t]+$//mg;
    return $text;
}

sub dump_model_as_perl {
    my @lines = dump_any($definition_model, 0, []);
    my $header = <<'EOT';
=pod

=head1 NAME

regen/regcomp.pl - generate regex node metadata from regcomp.sym

=head1 DESCRIPTION

This file is the canonical Perl-data source consumed by
F<regen/regcomp.pl>.  It defines the regex opcodes and regmatch states used
to generate F<regnodes.h> and the regnode table in F<pod/perldebguts.pod>.

Order is significant.  Preserve the existing order of groups and the order of
entries within each group unless you are intentionally changing regex opcode or
state numbering semantics.

=head1 TOP-LEVEL STRUCTURE

The file returns a single hashref with these keys:

=over 4

=item * C<ops_groups>

An ordered arrayref of opcode groups.

=item * C<state_groups>

An ordered arrayref of state groups.

=back

=head1 OPCODE GROUPS

Each entry in C<ops_groups> is a hashref with:

=over 4

=item * C<GROUP>

The logical group/block name.  Groups are emitted as blocks, so relative
ordering within a group is preserved.

=item * C<TYPE>

The regnode type shared by the group.  This may be a string type name, an arrayref
of types, or a special value C<"__MIXED__">, which allows the type to contain ops of
any type without validation.

=item * C<pod>

Optional text emitted into the generated regnode table in
F<pod/perldebguts.pod>.  A scalar is one paragraph.  An arrayref of strings
is one paragraph which will be reflowed.  A nested arrayref starts a new
paragraph; only two levels are supported.

=item * C<comment>

Optional maintainer-facing notes about ordering, invariants, or implementation
constraints.

=item * C<ops>

An ordered arrayref of opcode definitions.

=back

Each regop definition may contain:

=over 4

=item * C<NAME>

The opcode name.

=item * C<TYPE>

Optional unless the containing group's C<TYPE> is C<__MIXED__>.  If the group
is not mixed, the containing group's C<TYPE> is the default and any provided
opcode C<TYPE> must match it.  If the group is mixed, each opcode must provide
its own C<TYPE>.

=item * C<desc>

Description of what the regop does.  It follows the same scalar/arrayref
paragraph rules as C<pod>.

=item * C<struct>

Optional regnode structure name such as C<regnode_1> or
C<regnode_charclass>.  Omit it for plain C<regnode>.

=item * C<pod>

Optional per-op text which is intended to be emitted into the generated regnode table
in perldebguts.pod.  It follows the same scalar/arrayref paragraph rules as
group-level C<pod>.

=item * C<comment>

Optional maintainer-facing notes for this op.

=item * C<attr>

Optional hashref of non-default attributes.  Recognized keys currently include
C<arg_spec>, C<simple>, C<varies>, C<off_by_arg>, and C<str_arg>.

=back

=head1 STATE GROUPS

Each entry in C<state_groups> is a hashref with:

=over 4

=item * C<TYPE>

The base opcode/state name used to form the generated state names.

=item * C<transitions>

The compact transition specification used to expand regmatch states.

=item * C<pod>

Optional text emitted into the generated regnode table.  It follows the same
scalar/arrayref paragraph rules as opcode-group C<pod>.

=item * C<comment>

Optional maintainer-facing notes.

=back

=head1 NOTES

The C<pod> and C<comment> fields serve different purposes.  C<pod> is for
generated documentation output; C<comment> is for source-maintainer guidance,
we put the latter in the data structure so it can be regenerated via code if
necessary.

=cut

EOT

    return $header
         . "return " . shift(@lines) . "\n"
         . join("\n", @lines)
         . ";\n";
}

# use fixed width to keep the diffs between regcomp.pl recompiles
# as small as possible.
my ( $base_name_width, $rwidth, $twidth )= ( 22, 12, 9 );

sub print_state_defs {
    my ($out)= @_;
    printf $out <<EOP,
/* Regops and State definitions */

#define %*s\t%d
#define %*s\t%d

EOP
        -$base_name_width,
        REGNODE_MAX => $#ops,
        -$base_name_width, REGMATCH_STATE_MAX => $#all;

    my %rev_type_alias= reverse %type_alias;
    my $base_format = "#define %*s\t%d\t/* %#04x %s */\n";
    my @withs;
    my $in_states = 0;

    my $max_name_width = 0;
    for my $ref (\@ops, \@states) {
        for my $node ($ref->@*) {
            my $len = length $node->{name};
            $max_name_width = $len if $max_name_width < $len;
        }
    }

    die "Do a white-space only commit to increase \$base_name_width to"
     .  " $max_name_width; then re-run"  if $base_name_width < $max_name_width;

    print $out <<EOT;
/* -- For regexec.c to switch on target being utf8 (t8) or not (tb, b='byte'); */
#define with_t_UTF8ness(op, t_utf8) (((op) << 1) + (cBOOL(t_utf8)))
/* -- same, but also with pattern (p8, pb) -- */
#define with_tp_UTF8ness(op, t_utf8, p_utf8)                        \\
\t\t(((op) << 2) + (cBOOL(t_utf8) << 1) + cBOOL(p_utf8))

/* The #defines below give both the basic regnode and the expanded version for
   switching on utf8ness */
EOT

    for my $node (@ops) {
        print_state_def_line($out, $node->{name}, $node->{id}, rendered_desc($node));
        if ( defined( my $alias= $rev_type_alias{ $node->{name} } ) ) {
            print_state_def_line($out, $alias, $node->{id}, rendered_desc($node));
        }
    }

    print $out "\t/* ------------ States ------------- */\n";
    for my $node (@states) {
        print_state_def_line($out, $node->{name}, $node->{id}, $node->{comment});
    }
}

sub print_state_def_line
{
    my ($fh, $name, $id, $comment) = @_;

    # The sub-names are like '_tb' or '_tb_p8' = max 6 chars wide
    my $name_col_width = $base_name_width + 6;
    my $base_id_width = 3;  # Max is '255' or 3 cols
    my $mid_id_width  = 3;  # Max is '511' or 3 cols
    my $full_id_width = 3;  # Max is '1023' but not close to using the 4th

    my $line = "#define " . $name;
    $line .= " " x ($name_col_width - length($name));

    $line .= sprintf "%*s", $base_id_width, $id;
    $line .= " " x $mid_id_width;
    $line .= " " x ($full_id_width + 2);

    $line .= "/* ";
    my $hanging = length $line;     # Indent any subsequent line to this pos
    $line .= sprintf "0x%02x", $id;

    my $columns = 78;

    # From the documentation: 'In fact, every resulting line will have length
    # of no more than "$columns - 1"'
    $line = wrap($columns + 1, "", " " x $hanging, "$line $comment");
    chomp $line;            # wrap always adds a trailing \n
    $line =~ s/ \s+ $ //x;  # trim, just in case.

    # The comment may have wrapped.  Find the final \n and measure the length
    # to the end.  If it is short enough, just append the ' */' to the line.
    # If it is too close to the end of the space available, add an extra line
    # that consists solely of blanks and the ' */'
    my $len = length($line); my $rindex = rindex($line, "\n");
    if (length($line) - rindex($line, "\n") - 1 <= $columns - 3) {
        $line .= " */\n";
    }
    else {
        $line .= "\n" . " " x ($hanging - 3) . "*/\n";
    }

    print $fh $line;

    # And add the 2 subsidiary #defines used when switching on
    # with_t_UTF8nes()
    my $with_id_t = $id * 2;
    for my $with (qw(tb  t8)) {
        my $with_name = "${name}_$with";
        print  $fh "#define ", $with_name;
        print  $fh " " x ($name_col_width - length($with_name) + $base_id_width);
        printf $fh "%*s", $mid_id_width, $with_id_t;
        print  $fh " " x $full_id_width;
        printf $fh "  /*";
        print  $fh " " x (4 + 2);  # 4 is width of 0xHH that the base entry uses
        printf $fh "0x%03x */\n", $with_id_t;

        $with_id_t++;
    }

    # Finally add the 4 subsidiary #defines used when switching on
    # with_tp_UTF8nes()
    my $with_id_tp = $id * 4;
    for my $with (qw(tb_pb  tb_p8  t8_pb  t8_p8)) {
        my $with_name = "${name}_$with";
        print  $fh "#define ", $with_name;
        print  $fh " " x ($name_col_width - length($with_name) + $base_id_width + $mid_id_width);
        printf $fh "%*s", $full_id_width, $with_id_tp;
        printf $fh "  /*";
        print  $fh " " x (4 + 2);  # 4 is width of 0xHH that the base entry uses
        printf $fh "0x%03x */\n", $with_id_tp;

        $with_id_tp++;
    }

    print $fh "\n"; # Blank line separates groups for clarity
}

sub print_typedefs {
    my ($out)= @_;
    print $out <<EOP;

/* typedefs for regex nodes - one typedef per node type */

EOP
    my $len= 0;
    foreach my $node (@ops) {
        my $struct_name = "struct " . effective_struct($node);
        if ($len < length($struct_name)) {
            $len = length $struct_name;
        }
    }
    $len = (int($len/5)+2)*5;
    my $prefix= "tregnode";

    foreach my $node (sort { $a->{name} cmp $b->{name} } @ops) {
        my $struct_name = "struct " . effective_struct($node);
        $node->{typedef}= $prefix . "_" . $node->{name};
        printf $out "typedef %*s %s;\n", -$len, $struct_name, $node->{typedef};
    }
    print $out <<EOP;

/* end typedefs */

EOP

}




sub print_regnode_info {
    my ($out)= @_;
    print $out <<EOP;

/* PL_regnode_info[] - Opcode/state names in string form, for debugging */

EXTCONST struct regnode_meta PL_regnode_info[]  INIT( {
EOP
    my @fields= qw(type arg_len arg_len_varies off_by_arg);
    foreach my $node_idx (0..$#all) {
        my $node= $all[$node_idx];
        {
            my $size= 0;
            $size = "EXTRA_SIZE($node->{typedef})"
                if $node->{optype} eq 'op' && effective_struct($node) ne 'regnode';
            $node->{arg_len}= $size;

        }
        {
            my $varies= 0;
            $varies = 1 if $node->{attr} && $node->{attr}{str_arg};
            $node->{arg_len_varies}= $varies;
        }
        $node->{off_by_arg}= ($node->{attr} && $node->{attr}{off_by_arg}) || 0;
        print $out "    {\n";
        print $out "        /* #$node_idx $node->{optype} $node->{name} */\n";
        foreach my $f_idx (0..$#fields) {
            my $field= $fields[$f_idx];
            printf $out  "        .%s = %s", $field, $node->{$field} // 0;
            printf $out $f_idx == $#fields ? "\n" : ",\n";
        }
        print $out "    }";
        print $out $node_idx==$#all ? "\n" : ",\n";
    }

    print $out <<EOP;
});

EOP
}


sub print_regnode_name {
    my ($out)= @_;
    print $out <<EOP;

/* PL_regnode_name[] - Opcode/state names in string form, for debugging */

EXTCONST char * const PL_regnode_name[]  INIT( {
EOP

    my $ofs= 0;
    my $sym= "";
    foreach my $node (@all) {
        printf $out "\t%*s\t/* $sym%#04x */\n",
            -3 - $base_name_width, qq("$node->{name}",), $node->{id} - $ofs;
        if ( $node->{id} == $#ops and @ops != @all ) {
            print $out "\t/* ------------ States ------------- */\n";
            $ofs= $#ops;
            $sym= 'REGNODE_MAX +';
        }
    }

    print $out <<EOP;
});

EOP
}

sub print_reg_extflags_name {
    my ($out)= @_;
    print $out <<EOP;
/* PL_reg_extflags_name[] - Opcode/state names in string form, for debugging */

EXTCONST char * const PL_reg_extflags_name[] INIT( {
EOP

    my %rxfv;
    my %definitions;    # Remember what the symbol definitions are
    my $val= 0;
    my %reverse;
    my $REG_EXTFLAGS_NAME_SIZE= 0;
    my $hp= HeaderParser->new();
    foreach my $file ( "op_reg_common.h", "regexp.h" ) {
        $hp->read_file($file);
        foreach my $line_info (@{$hp->lines}) {
            next unless $line_info->{type}     eq "content"
                    and $line_info->{sub_type} eq "#define";
            my $line= $line_info->{line};
            $line=~s/\s*\\\n\s*/ /g;

            # optional leading '_'.  Return symbol in $1, and strip it from
            # comment of line.  Currently doesn't handle comments running onto
            # next line
            if ($line=~s/^ \# \s* define \s+ ( _? RXf_ \w+ ) \s+ //xi) {
                chomp($line);
                my $define= $1;
                my $orig= $_;
                $line=~s{ /\* .*? \*/ }{ }x;    # Replace comments by a blank

                # Replace any prior defined symbols by their values
                foreach my $key ( keys %definitions ) {
                    $line=~s/\b$key\b/$definitions{$key}/g;
                }

                # Remove the U suffix from unsigned int literals
                $line=~s/\b([0-9]+)U\b/$1/g;

                my $newval= eval $line;     # Get numeric definition

                $definitions{$define}= $newval;

                next unless $line =~ /<</;    # Bit defines use left shift
                if ( $val & $newval ) {
                    my @names= ( $define, $reverse{$newval} );
                    s/PMf_// for @names;
                    if ( $names[0] ne $names[1] ) {
                        die sprintf
                            "ERROR: both $define and $reverse{$newval} use 0x%08X (%s:%s)",
                            $newval, $orig, $line;
                    }
                    next;
                }
                $val |= $newval;
                $rxfv{$define}= $newval;
                $reverse{$newval}= $define;
            }
        }
    }
    my %vrxf= reverse %rxfv;
    printf $out "\t/* Bits in extflags defined: %s */\n", unpack 'B*', pack 'N',
        $val;
    my %multibits;
    for ( 0 .. 31 ) {
        my $power_of_2= 2**$_;
        my $n= $vrxf{$power_of_2};
        my $extra= "";
        if ( !$n ) {

            # Here, there was no name that matched exactly the bit.  It could be
            # either that it is unused, or the name matches multiple bits.
            if ( !( $val & $power_of_2 ) ) {
                $n= "UNUSED_BIT_$_";
            }
            else {

                # Here, must be because it matches multiple bits.  Look through
                # all possibilities until find one that matches this one.  Use
                # that name, and all the bits it matches
                foreach my $name ( keys %rxfv ) {
                    if ( $rxfv{$name} & $power_of_2 ) {
                        $n= $name . ( $multibits{$name}++ );
                        $extra= sprintf qq{ : "%s" - 0x%08x}, $name,
                            $rxfv{$name}
                            if $power_of_2 != $rxfv{$name};
                        last;
                    }
                }
            }
        }
        s/\bRXf_(PMf_)?// for $n, $extra;
        printf $out qq(\t%-20s/* 0x%08x%s */\n), qq("$n",), $power_of_2, $extra;
        $REG_EXTFLAGS_NAME_SIZE++;
    }

    print $out <<EOP;
});

#ifdef DEBUGGING
#  define REG_EXTFLAGS_NAME_SIZE $REG_EXTFLAGS_NAME_SIZE
#endif
EOP

}

sub print_reg_intflags_name {
    my ($out)= @_;
    print $out <<EOP;

/* PL_reg_intflags_name[] - Opcode/state names in string form, for debugging */

EXTCONST char * const PL_reg_intflags_name[]  INIT( {
EOP

    my %rxfv;
    my %definitions;    # Remember what the symbol definitions are
    my $val= 0;
    my %reverse;
    my $REG_INTFLAGS_NAME_SIZE= 0;
    my $hp= HeaderParser->new();
    my $last_val = 0;
    foreach my $file ("regcomp.h") {
        $hp->read_file($file);
        my @bit_tuples;
        foreach my $line_info (@{$hp->lines}) {
            next unless $line_info->{type}     eq "content"
                    and $line_info->{sub_type} eq "#define";
            my $line= $line_info->{line};
            $line=~s/\s*\\\n\s*/ /g;

            # optional leading '_'.  Return symbol in $1, and strip it from
            # comment of line
            if (
                $line =~ m/^ \# \s* define \s+ ( PREGf_ ( \w+ ) ) \s+ 0x([0-9a-f]+)(?:\s*\/\*(.*)\*\/)?/xi
            ){
                chomp $line;
                my $define= $1;
                my $abbr= $2;
                my $hex= $3;
                my $comment= $4;
                my $val= hex($hex);
                my $bin= sprintf "%b", $val;
                if ($bin=~/1.*?1/) { die "Not expecting multiple bits in PREGf" }
                my $bit= length($bin) - 1 ;
                $comment= $comment ? " - $comment" : "";
                if ($bit_tuples[$bit]) {
                    die "Duplicate PREGf bit '$bit': $define $val ($hex)";
                }
                $bit_tuples[$bit]= [ $bit, $val, $abbr, $define, $comment ];
            }
        }
        foreach my $i (0..$#bit_tuples) {
            my $bit_tuple= $bit_tuples[$i];
            if (!$bit_tuple) {
                $bit_tuple= [ $i, 1<<$i, "", "", "*UNUSED*" ];
            }
            my ($bit, $val, $abbr, $define, $comment)= @$bit_tuple;
            printf $out qq(\t%-30s/* (1<<%2d) - 0x%08x - %s%s */\n),
                qq("$abbr",), $bit, $val, $define, $comment;
        }
        $REG_INTFLAGS_NAME_SIZE=0+@bit_tuples;
    }

    print $out <<EOP;
});

EOP
    print $out <<EOQ;
#ifdef DEBUGGING
#  define REG_INTFLAGS_NAME_SIZE $REG_INTFLAGS_NAME_SIZE
#endif

EOQ
}

sub print_process_flags {
    my ($out)= @_;

    print $out process_flags( 'varies', 'varies', <<'EOC');
/* The following have no fixed length. U8 so we can do strchr() on it. */
EOC

    print $out process_flags( 'simple', 'simple', <<'EOC');

/* The following always have a length of 1. U8 we can do strchr() on it. */
/* (Note that length 1 means "one character" under UTF8, not "one octet".) */
EOC

}

sub do_perldebguts {
    my $guts= open_new( 'pod/perldebguts.pod', '>' );

    my $node;
    my $code;
    my $descr = "";
    my $name_fmt= '<' x  ( $longest_name_length - 1 );
    my $descr_fmt= '<' x ( 58 - $longest_name_length );
    eval <<EOD or die $@;
format GuTS =
^$name_fmt ^<<<<<<<<< ^$descr_fmt~~
\$node->{name}, \$code, \$descr
.
1;
EOD

    my $old_fh= select($guts);
    $~= "GuTS";

    open my $oldguts, '<', 'pod/perldebguts.pod'
        or die "$0 cannot open pod/perldebguts.pod for reading: $!";
    while (<$oldguts>) {
        print;
        last if /=for regcomp.pl begin/;
    }

    print <<'END_OF_DESCR';

# TYPE arg-description [regnode-struct-suffix] [longjump-len] DESCRIPTION
END_OF_DESCR
    for my $group_entry (@ops_groups_for_output) {
        my $group = $group_entry->{group};
        my $group_pod = format_pod_fragment_for_output(format_pod_input($group->{pod}));
        print $group_pod if length $group_pod;

        for my $n (@{ $group_entry->{ops} }) {
            $node = $n;
            my $arg_spec = $node->{attr}{arg_spec} // "no";
            $code = $arg_spec . " " . struct_suffix($node);
            $code .= " " . $node->{attr}{off_by_arg} if $node->{attr}{off_by_arg};
            my $pod_comment = format_pod_fragment_for_output(format_pod_input($node->{pod}));
            print $pod_comment if length $pod_comment;
            $descr = rendered_desc($node);
            write;
        }
    }
    print "\n";

    while (<$oldguts>) {
        last if /=for regcomp.pl end/;
    }
    do { print } while <$oldguts>; #win32 can't unlink an open FH
    close $oldguts or die "Error closing pod/perldebguts.pod: $!";
    select $old_fh;
    close_and_rename($guts);
}

sub write_regen_conf {
    my ($file, $content) = @_;

    if (open my $in, '<', $file) {
        local $/;
        my $current = <$in>;
        close $in or die "Error closing $file: $!";
        return if defined $current && $current eq $content;
    }

    my $tmp = "$file-new";
    open my $out, '>', $tmp or die "Can't create $tmp: $!";
    binmode $out;
    print {$out} $content;
    close $out or die "Error closing $tmp: $!";

    safer_unlink($file);
    rename $tmp, $file or die "renaming $tmp to $file: $!";
    push @Changed, $file unless $Verbose < 0;
}

my $confine_to_core = 'defined(PERL_CORE) || defined(PERL_EXT_RE_BUILD)';
my $regen_conf = 0;
Getopt::Long::Configure('pass_through');
GetOptions(
    'regen-conf' => \$regen_conf,
) or die "Usage: $0 [--regen-conf] [regcomp.sym]\n";

my @positional = grep { $_ !~ /^-/ } @ARGV;
die "Usage: $0 [--regen-conf] [regcomp.sym]\n" if @positional > 1;

my $input_file = $positional[0] || 'regcomp.sym';
read_definition($input_file);
if ($ENV{DUMP_MODEL_AS_PERL}) {
    print dump_model_as_perl();
    exit 0;
}
if ($ENV{DUMP}) {
    require Data::Dumper;
    print Data::Dumper::Dumper(\@all);
    exit(1);
}
if ($regen_conf) {
    write_regen_conf($input_file, dump_model_as_perl());
}
my $out= open_new( 'regnodes.h', '>',
    {
        by      => 'regen/regcomp.pl',
        from    => [ 'regcomp.sym', 'op_reg_common.h', 'regexp.h' ],
    },
);
print $out "#if $confine_to_core\n\n";
print_typedefs($out);
print_state_defs($out);

print_regnode_name($out);
print_regnode_info($out);


print_reg_extflags_name($out);
print_reg_intflags_name($out);
print_process_flags($out);
print_process_EXACTish($out);
print $out "\n#endif /* $confine_to_core */\n";
read_only_bottom_close_and_rename($out);

do_perldebguts();
