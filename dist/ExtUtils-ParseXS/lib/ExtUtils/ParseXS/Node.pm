package ExtUtils::ParseXS::Node;
use strict;
use warnings;
use Symbol;

our $VERSION = '3.62';

=head1 NAME

ExtUtils::ParseXS::Node - Classes for nodes of an Abstract Syntax Tree

=head1 SYNOPSIS

    # Create a node to represent the Foo part of an XS file; then
    # top-down parse it into a subtree; then top-down emit the
    # contents of the subtree as C code.

    my $foo = ExtUtils::ParseXS::Node::Foo->new();
    $foo->parse(...)
        or die;
    $foo->as_code(...);
    print STDERR $foo->as_concise(1); # for debugging

=head1 DESCRIPTION

This API is currently private and subject to change.

The C<ExtUtils::ParseXS::Node> class, and its various subclasses, hold the
state for the nodes of an Abstract Syntax Tree (AST), which represents the
parsed state of an XS file.

Each node is a hash of fields. Which field names are legal varies by the
node type. The hash keys and values can be accessed directly: there are no
getter/setter methods.

Each node may have a C<kids> field which points to an array of all the
children of that node: this is what provides the tree structure. In
addition, some of those kids may also have direct links from fields for
quick access. For example, the C<xsub_decl> child object of an C<xsub>
object can be accessed in either of these ways:

    $xsub_object->{kids}[0]
    $xsub_object->{decl}

Most object-valued node fields within a tree point only to their direct
children; however, both C<INPUT_line> and C<OUTPUT_line> have an
C<ioparam> field which points to the C<IO_Param> object associated with
this line, which is located elsewhere in the tree.

The various C<foo_part> nodes divide the parsing of the main body of an
XSUB into sections where different sets of keywords are allowable, and
where various bits of code can be conveniently emitted.

=head2 Methods

There are two main methods in addition to C<new()>, which are present in
all subclasses. First, C<parse()> consumes lines from the source to
satisfy the construct being parsed. It may itself create objects of
lower-level constructs and call parse on them. For example,
C<Node::xbody::parse()> may create a C<Node::input_part> node and call
C<parse()> on it, which will create C<Node::INPUT> or C<Node::PREINIT>
nodes as appropriate, and so on.

Secondly, C<as_code()> descends its sub-tree, outputting the tree as C
code.

The C<as_concise()> method returns a line-per-node string representation
of the node and any children. Most node classes just inherit this method
from the base C<Node> class. It is intended mainly for debugging.

Some nodes also have an C<as_boot_code()> method for adding any code to
the boot XSUB. This returns two array refs, one containing a list of code
lines to be inserted early into the boot XSUB, and a second for later
lines.

Finally, in the IO_Param subclass, C<as_code()> is replaced with
C<as_input_code> and C<as_output_code()>, since that node may need to
generate I<two> sets of C code; one to assign a Perl argument to a C
variable, and the other to return the value of a variable to Perl.

Note that parsing and code-generation are done as two separate phases;
C<parse()> should only build a tree and never emit code.

In addition to C<$self>, methods may commonly have some of these
parameters:

=over

=item C<$pxs>

An C<ExtUtils::ParseXS> object which contains the overall processing
state. In particular, it has warning and croaking methods, and holds the
lines read in from the source file for the current paragraph.

=item C<$xsub>

For nodes related to parsing an XSUB, the current
C<ExtUtils::ParseXS::xsub> node being processed.

=item C<$xbody>

For nodes related to parsing an XSUB, the current
C<ExtUtils::ParseXS::xbody> node being processed. Note that in the
presence of a C<CASE> keyword, an XSUB can have multiple bodies.

=back

The C<parse()> and C<as_code()> methods for some subclasses may have
parameters in addition to those.

Some subclasses may also have additional helper methods.

=head2 Class Hierachy

C<Node> and its sub-classes form the following inheritance hierarchy.
Various abstract classes are used by concrete subclasses where the
processing and/or fields are similar: for example, C<CODE>, C<PPCODE> etc
all consume a block of uninterpreted lines from the source file until the
next keyword, and emit that code, possibly wrapped in C<#line> directives.
This common behaviour is provided by the C<codeblock> class.

    Node
        XS_file
        preamble
        C_part
        C_part_POD
        C_part_code
        C_part_postamble
        cpp_scope
        global_cpp_line
        BOOT
        TYPEMAP
        pre_boot
        boot_xsub
        xsub
        xsub_decl
        ReturnType
        Param
            IO_Param
        Params
        xbody
        input_part
        init_part
        code_part
        output_part
        cleanup_part
        autocall
        oneline
            MODULE
            REQUIRE
            FALLBACK
            include
                INCLUDE
                INCLUDE_COMMAND
            NOT_IMPLEMENTED_YET
            CASE
            enable
                EXPORT_XSUB_SYMBOLS
                PROTOTYPES
                SCOPE
                VERSIONCHECK
        multiline
            multiline_merged
                C_ARGS
                INTERFACE
                INTERFACE_MACRO
                OVERLOAD
            ATTRS
            PROTOTYPE
            codeblock
                CODE
                CLEANUP
                INIT
                POSTCALL
                PPCODE
                PREINIT
        keylines
            ALIAS
            INPUT
            OUTPUT
        keyline
            ALIAS_line
            INPUT_line
            OUTPUT_line


=head2 Abstract Syntax Tree structure

A typical XS file might compile to a tree with a node structure similar to
the following. Note that this is unrelated to the inheritance hierarchy
shown above. In this example, the XS file includes another file, and has a
couple of XSUBs within a C<#if/#else/#endif>. Note that a C<cpp_scope>
node is the parent of all the nodes within the same branch of an C<#if>,
or in the absence of C<#if>, within the same file.

    XS_file
        preamble
        C_part
            C_part_POD
            C_part_code
        C_part_postamble
        cpp_scope: type="main"
            MODULE
            PROTOTYPES
            BOOT
            TYPEMAP
            INCLUDE
                cpp_scope: type="include"
                    xsub
                        ...
            global_cpp_line: directive="ifdef"
            cpp_scope: type="if"
                xsub
                    ...
            global_cpp_line: directive="else"
            cpp_scope: type="if"
                xsub
                    ...
            global_cpp_line: directive="endif"
            xsub
                ...
        pre_boot
        boot_xsub

A typical XSUB might compile to a tree with a structure similar to the
following.

    xsub
        xsub_decl
            ReturnType
            Params
                Param
                Param
                ...
        CASE   # for when a CASE keyword being present implies multiple
               # bodies; otherwise, just a bare xbody node.
            xbody
                # per-body copy of declaration Params, augmented by
                # data from INPUT and OUTPUT sections
                Params
                    IO_Param
                    IO_Param
                    ...
                input_part
                    INPUT
                        INPUT_line
                        INPUT_line
                        ...
                    PREINIT
                init_part
                    INIT
                code_part
                    CODE
                output_part
                    OUTPUT
                        OUTPUT_line
                        OUTPUT_line
                        ...
                    POSTCALL
                cleanup_part
                    CLEANUP
        CASE
            xbody
                ...

=cut

# store these in variables to hide them from brace-matching text editors
my $open_brace  = '{';
my $close_brace = '}';

# values for parse_keywords() flags
# (Can't assume 'constant.pm' is present yet)

my $keywords_flag_MODULE              = 1;
my $keywords_flag_NOT_IMPLEMENTED_YET = 2;

# Utility sub to handle all the boilerplate of declaring a Node subclass,
# including setting up @INC and @FIELDS. Intended to be called from within
# BEGIN. (Created as a lexical sub ref to make it easily accessible to
# all subclasses in this file.)
#
# The first two args can optionally be ('-parent', 'Foo'), in which case
# the parent of this subclass will be ExtUtils::ParseXS::Node::Foo.
# If not specified, the parent will be ExtUtils::ParseXS::Node.
#
# Any remaining args are the names of fields. It also inherits the fields
# of its parent.

my $USING_FIELDS;

my $build_subclass;
BEGIN {
    $build_subclass = sub {
        my (@fields) = @_;

        my $parent = 'ExtUtils::ParseXS::Node';
        if (@fields and $fields[0] eq '-parent') {
            shift @fields;
            my $p = shift @fields;
            $parent .= "::$p";
        }

        my @bad = grep !/^\w+$/, @fields;
        die "Internal error: bad field name(s) in build_subclass: (@bad)\n"
            if @bad;

        no strict 'refs';

        my $class = caller(0);
        @fields   = (@{"${parent}::FIELDS"}, @fields);
        @{"${class}::ISA"}    = $parent;
        @{"${class}::FIELDS"} = @fields;

        if ($USING_FIELDS) {
            eval qq{package $class; fields->import(\@fields); 1;}
                or die $@;
        }
    };
};


# ======================================================================

package ExtUtils::ParseXS::Node;

# Base class for all the other node types.
#
# The 'use fields' enables compile-time or run-time errors if code
# attempts to use a key which isn't listed here.

BEGIN {
    our @FIELDS = (
        'line_no',       # line number and ...
        'file',          # ... filename where this node appeared in src
        'kids',          # child nodes, if any
    );

    # do 'use fields', except: fields needs Hash::Util which is XS, which
    # needs us. So only 'use fields' on systems where Hash::Util has already
    # been built.
    if (eval 'require Hash::Util; 1;') {
        require fields;
        $USING_FIELDS = 1;
        fields->import(@FIELDS);
    }
}


# new(): takes one optional arg, $args, which is a hash ref of key/value
# pairs to initialise the object with.

sub new {
    my ($class, $args) = @_;
    $args = {} unless defined $args;

    my __PACKAGE__  $self = shift;

    if ($USING_FIELDS) {
        $self = fields::new($class);
        %$self = %$args;
    }
    else {
        $self = bless { %$args } => $class;

    }
    return $self;
}


# A very generic parse method that just notes the current file/line no.
# Typically called first as a SUPER by the parse() method of real nodes.

sub parse {
    my __PACKAGE__       $self = shift;
    my ExtUtils::ParseXS $pxs  = shift;

    $self->{file}    = $pxs->{in_pathname};
                        # account for the line array getting shifted
                        # as input lines are consumed, while line_no
                        # array isn't ever shifted
    $self->{line_no} = $pxs->{line_no}->[
                            @{$pxs->{line_no}} - @{$pxs->{line}}
                        ];
    1;
}


# Repeatedly look for keywords matching the pattern. For each found
# keyword, parse the text following them, and add any resultant nodes
# as kids to the current node. Returns a list of the successfully parsed
# and added kids.
# If $max is defined, it specifies the maximum number of keywords to
# process. This value is typically passed as undef (unlimited) or 1
# (just grab the next keyword).
# $flags can contain  $keywords_flag_MODULE or
# keywords_flag_NOT_IMPLEMENTED_YET to indicate to match one of those
# keywords too (whose syntax is slightly different from 'KEY:' and
# so need special handling

sub parse_keywords {
    my __PACKAGE__       $self  = shift;
    my ExtUtils::ParseXS $pxs   = shift;
    my                   $xsub  = shift;
    my                   $xbody = shift;
    my $max                     = shift; # max number of keywords to process
    my $pat                     = shift;
    my $flags                   = shift;

    $flags = 0 unless defined $flags;

    my $n = 0;
    my @kids;
    while (@{$pxs->{line}}) {
        my $line = shift @{$pxs->{line}};
        next unless $line =~ /\S/;

        # extract/delete recognised keyword and any following text
        my $keyword;

        if (   ($flags & $keywords_flag_MODULE)
            && ExtUtils::ParseXS::Utilities::looks_like_MODULE_line($line)
           )
        {
            $keyword = 'MODULE';
        }
        elsif  (   $line =~ s/^(\s*)($pat)\s*:\s*(?:#.*)?/$1/s
                or (   ($flags & $keywords_flag_NOT_IMPLEMENTED_YET)
                    && $line =~ s/^(\s*)(NOT_IMPLEMENTED_YET)/$1/
                   )
               )
        {
            $keyword = $2
        }
        else {
            # stop at unrecognised line
            unshift @{$pxs->{line}}, $line;
            last;
        }

        unshift @{$pxs->{line}}, $line;
        # create a node for the keyword and parse any lines associated
        # with it.
        my $class = "ExtUtils::ParseXS::Node::$keyword";
        my $node  = $class->new();
        if ($node->parse($pxs, $xsub, $xbody)) {
            push @{$self->{kids}}, $node;
            push @kids, $node;
        }

        $n++;
        last if defined $max and $max >= $n;
    }

    return @kids;
}

sub as_code { }

# Most node types inherit this: just continue walking the tree
# looking for any nodes which provide some boot code.
# It returns two array refs; one for lines of code to be injected early
# into the boot XSUB, the second for later code.

sub as_boot_code {
    my __PACKAGE__       $self  = shift;
    my ExtUtils::ParseXS $pxs   = shift;

    my ($early, $later) = ([], []);
    my $kids = $self->{kids};
    if ($kids) {
        for (@$kids) {
            my ($e, $l) = $_->as_boot_code($pxs);
            push @$early, @$e;
            push @$later, @$l;
        }
    }
    return $early, $later;
}


# as_concise(): for debugging:
#
# Return a string representing a concise line-per-node representation
# of the node and any children, in the spirit of 'perl -MO=Concise'.
# Intended to be human- rather than machine-readable.
#
# The single optional parameter, depth, is for indentation purposes

sub as_concise {
    my __PACKAGE__  $self  = shift;
    my $depth =  shift;
    $depth = 0 unless defined $depth;

    my $f = $self->{file};
    $f = '??' unless defined $f;
    $f =~ s{^.*/}{};
    substr($f,0,10) = '' if length($f) > 10;

    my $l = $self->{line_no};
    $l = defined $l ? sprintf("%-3d", $l) : '?? ';

    my $s = sprintf "%-15s", "$f:$l";
    $s .= ('  ' x $depth);

    my $class = ref $self;
    $class =~ s/^.*:://g;
    $s .= "${class}: ";

    my @kv;

    for my $key (sort grep !/^(file|line_no|kids)$/, keys %$self) {
        my $v = $self->{$key};

        # some basic pretty-printing

        if (!defined $v) {
            $v = '-';
        }
        elsif (ref $v) {
            $v = "[ref]";
        }
        elsif ($v =~ /^-?\d+(\.\d+)?$/) {
            # leave as-is
        }
        else {
            $v = "$v";
            $v =~ s/"/\\"/g;
            my $max = 20;
            substr($v, $max) = '...' if length($v) > $max;
            $v = qq("$v");
        }

        push @kv, "$key=$v";
    }

    $s .= join '; ', @kv;
    $s .= "\n";

    if ($self->{kids}) {
        $s .= $_->as_concise($depth+1) for @{$self->{kids}};
    }

    $s;
}


# Simple method wrapper for ExtUtils::ParseXS::Q

sub Q {
    my __PACKAGE__ $self   = shift;
    my $text = shift;
    return ExtUtils::ParseXS::Q($text);
}


# ======================================================================

package ExtUtils::ParseXS::Node::XS_file;

# Top-level AST node representing an entire XS file

BEGIN { $build_subclass->(
    'preamble',   # Node::preamble object which emits preamble C code
    'C_part',     # the C part of the XS file, before the first MODULE
    'C_part_postamble',# Node::C_part_postamble object which emits
                  # boilerplate code following the C code
    'cpp_scope',  # node holding all the XS part of the main file
    'pre_boot',   # node holding code after user XSUBs but before boot XSUB
    'boot_xsub',  # node holding code which generates the boot XSUB
)};

sub parse {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    $self->{line_no} = 1;
    $self->{file}    = $pxs->{in_pathname};

    # Hash of package name => package C name
    $pxs->{map_overloaded_package_to_C_package} = {};

    # Hashref of package name => fallback setting
    $pxs->{map_package_to_fallback_string} = {};

    $pxs->{error_count}  = 0;

    # Initialise the sequence of guard defines used by cpp_scope
    $pxs->{cpp_next_tmp_define} = 'XSubPPtmpAAAA';

    # "Parse" the start of the file. Doesn't actually consume any lines:
    # just a placeholder for emitting preamble later

    my $preamble = ExtUtils::ParseXS::Node::preamble->new();
    $self->{preamble} = $preamble;
    $preamble->parse($pxs, $self)
        or return;
    push @{$self->{kids}}, $preamble;


    # Process the first (C language) half of the XS file, up until the first
    # MODULE: line

    my $C_part = ExtUtils::ParseXS::Node::C_part->new();
    $self->{C_part} = $C_part;
    my $c_part_result = $C_part->parse($pxs, $self);
    push @{$self->{kids}}, $C_part;

    # A failure when parsing the C part means that there wasn't a MODULE
    # line. Don't try to parse the missing XS part, but still return
    # success, passing through the lines from the C part.
    return 1 unless $c_part_result;

    # "Parse" the bit following any C code. Doesn't actually consume any
    # lines: just a placeholder for emitting postamble code.

    my $C_part_postamble = ExtUtils::ParseXS::Node::C_part_postamble->new();
    $self->{C_part_postamble} = $C_part_postamble;
    $C_part_postamble->parse($pxs, $self)
        or return;
    push @{$self->{kids}}, $C_part_postamble;

    # Parse the XS half of the file

    my $cpp_scope = ExtUtils::ParseXS::Node::cpp_scope->new({type => 'main'});
    $self->{cpp_scope} = $cpp_scope;
    $cpp_scope->parse($pxs)
        or return;
    push @{$self->{kids}}, $cpp_scope;

    # Now at EOF: all paragraphs (and thus XSUBs) have now been read in
    # and processed. Do any final post-processing.

    # "Parse" the bit following any C code. Doesn't actually consume any
    # lines: just a placeholder for emitting any code which should follow
    # user XSUBs but which comes before the boot XSUB

    my $pre_boot = ExtUtils::ParseXS::Node::pre_boot->new();
    $self->{pre_boot} = $pre_boot;
    push @{$self->{kids}}, $pre_boot;
    $pre_boot->parse($pxs)
        or return;

    # Emit the boot XSUB initialization routine

    my $boot_xsub = ExtUtils::ParseXS::Node::boot_xsub->new();
    $self->{boot_xsub} = $boot_xsub;
    push @{$self->{kids}}, $boot_xsub;
    $boot_xsub->parse($pxs)
        or return;

    warn(   "Please specify prototyping behavior for "
          . "$pxs->{in_filename} (see perlxs manual)\n")
        unless $pxs->{proto_behaviour_specified};

    1;
}


sub as_code {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    $_->as_code($pxs, $self) for @{$self->{kids}};

}
# ======================================================================

package ExtUtils::ParseXS::Node::preamble;

# AST node representing the boilerplate C code preamble at the start of
# the file. Parsing doesn't actually consume any lines; it exists just for
# its as_code() method which emits the preamble into the C file.

BEGIN { $build_subclass->(
)};

sub parse {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    $self->{line_no} = 1;
    $self->{file}    = $pxs->{in_pathname};
    1;
}

sub as_code {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    # Emit preamble at start of C file, including the
    # version it was generated by.

    print $self->Q(<<"EOM");
    |/*
    | * This file was generated automatically by ExtUtils::ParseXS version $ExtUtils::ParseXS::VERSION from the
    | * contents of $pxs->{in_filename}. Do not edit this file, edit $pxs->{in_filename} instead.
    | *
    | *    ANY CHANGES MADE HERE WILL BE LOST!
    | *
    | */
    |
EOM

    print("#line 1 \"" .
            ExtUtils::ParseXS::Utilities::escape_file_for_line_directive(
                                            $self->{file}) . "\"\n")
        if $pxs->{config_WantLineNumbers};
}


# ======================================================================

package ExtUtils::ParseXS::Node::C_part;

# A node representing the C part of the XS file - i.e. everything
# before the first MODULE line

BEGIN { $build_subclass->(
)};

sub parse {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    $self->{line_no} = 1;
    $self->{file}    = $pxs->{in_pathname};

    # Read in lines until the first MODULE line, creating a list of
    # Node::C_part_code and Node::C_part_POD nodes as children.
    # Returns with $pxs->{lastline} holding the next line (i.e. the MODULE
    # line) or errors out if not found

    $pxs->{lastline}    =  readline($pxs->{in_fh});
    $pxs->{lastline_no} = $.;

    while (defined $pxs->{lastline}) {
        if (ExtUtils::ParseXS::Utilities::looks_like_MODULE_line(
                                                    $pxs->{lastline}))
        {
            # the fetch_para() regime in place in the XS part of the file
            # expects this to have been chomped
            chomp $pxs->{lastline};
            return 1;
        }

        my $node = 
            $pxs->{lastline} =~ /^=/
                 ? ExtUtils::ParseXS::Node::C_part_POD->new()
                 : ExtUtils::ParseXS::Node::C_part_code->new();

        # Read in next block of code or POD lines
        $node->parse($pxs)
            or return;
        push @{$self->{kids}}, $node;
    }

    warn "Didn't find a 'MODULE ... PACKAGE ... PREFIX' line\n";
    return;
}


sub as_code {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    $_->as_code($pxs, $self) for @{$self->{kids}};

    print 'ExtUtils::ParseXS::CountLines'->end_marker, "\n"
        if $pxs->{config_WantLineNumbers};
}


# ======================================================================

package ExtUtils::ParseXS::Node::C_part_POD;

# A node representing a section of POD within the C part of the XS file

BEGIN { $build_subclass->(
    'pod_lines', # array of lines containing pod, including start and end
                 # '=foo' lines
)};

sub parse {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    $self->{line_no} = $pxs->{lastline_no};
    $self->{file}    = $pxs->{in_pathname};

    # This method is called with $pxs->{lastline} holding the first line
    # of POD and returns with $pxs->{lastline} holding the (unprocessed)
    # next line following the =cut line

    my $cut;
    while (1) {
        push @{$self->{pod_lines}}, $pxs->{lastline};
        $pxs->{lastline}    = readline($pxs->{in_fh});
        $pxs->{lastline_no} = $.;
        return 1 if $cut;
        last unless defined $pxs->{lastline};
        $cut = $pxs->{lastline} =~ /^=cut\s*$/;
    }

    # At this point $. is at end of file so die won't state the start
    # of the problem, and as we haven't yet read any lines &death won't
    # show the correct line in the message either.
    die (  "Error: Unterminated pod in $pxs->{in_filename}, "
         . "line $self->{line_no}\n");
}


sub as_code {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    # Emit something in the C file to indicate that a section of POD has
    # been elided, while maintaining the correct lines numbers using
    # #line.
    #
    # We can't just write out a /* */ comment, as our embedded POD might
    # itself be in a comment. We can't put a /**/ comment inside #if 0, as
    # the C standard says that the source file is decomposed into
    # preprocessing characters in the stage before preprocessing commands
    # are executed.
    #
    # I don't want to leave the text as barewords, because the spec isn't
    # clear whether macros are expanded before or after preprocessing
    # commands are executed, and someone pathological may just have
    # defined one of the 3 words as a macro that does something strange.
    # Multiline strings are illegal in C, so the "" we write must be a
    # string literal. And they aren't concatenated until 2 steps later, so
    # we are safe.
    #     - Nicholas Clark

    print $self->Q(<<"EOF");
        |#if 0
        |  "Skipped embedded POD."
        |#endif
EOF

    printf("#line %d \"%s\"\n",
                $self->{line_no} + @{$self->{pod_lines}},
                ExtUtils::ParseXS::Utilities::escape_file_for_line_directive(
                    $pxs->{in_pathname}))
        if $pxs->{config_WantLineNumbers};
}


# ======================================================================

package ExtUtils::ParseXS::Node::C_part_code;

# A node representing a section of C code within the C part of the XS file

BEGIN { $build_subclass->(
    'code_lines', # array of lines containing C code
)};

sub parse {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    $self->{line_no} = $pxs->{lastline_no};
    $self->{file}    = $pxs->{in_pathname};

    # This method is called with $pxs->{lastline} holding the first line
    # of (possibly) C code and returns with $pxs->{lastline} holding the
    # first (unprocessed) line which isn't C code (i.e. its the start of
    # POD or a MODULE line)

    my $cut;
    while (1) {
        return 1 if ExtUtils::ParseXS::Utilities::looks_like_MODULE_line(
                                                            $pxs->{lastline});
        return 1 if $pxs->{lastline} =~ /^=/;
        push @{$self->{code_lines}}, $pxs->{lastline};
        $pxs->{lastline}    = readline($pxs->{in_fh});
        $pxs->{lastline_no} = $.;
        last unless defined $pxs->{lastline};
    }

    1;
}

sub as_code {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    print @{$self->{code_lines}};
}



# ======================================================================

package ExtUtils::ParseXS::Node::C_part_postamble;

# AST node representing the boilerplate C code postamble following any
# initial C code contained within the C part of the XS file.
# This node's parse() method doesn't actually consume any lines; the node
# exists just for its as_code() method to emit the postamble into the C
# file.

BEGIN { $build_subclass->(
)};

sub parse {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    $self->{line_no} = $pxs->{lastline_no};
    $self->{file}    = $pxs->{in_pathname};
    1;
}

sub as_code {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    # Emit boilerplate postamble following any code passed through from
    # the 'C' part of the XS file

    print $self->Q(<<'EOF');
        |#ifndef PERL_UNUSED_VAR
        |#  define PERL_UNUSED_VAR(var) if (0) var = var
        |#endif
        |
        |#ifndef dVAR
        |#  define dVAR		dNOOP
        |#endif
        |
        |
        |/* This stuff is not part of the API! You have been warned. */
        |#ifndef PERL_VERSION_DECIMAL
        |#  define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
        |#endif
        |#ifndef PERL_DECIMAL_VERSION
        |#  define PERL_DECIMAL_VERSION \
        |	  PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
        |#endif
        |#ifndef PERL_VERSION_GE
        |#  define PERL_VERSION_GE(r,v,s) \
        |	  (PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))
        |#endif
        |#ifndef PERL_VERSION_LE
        |#  define PERL_VERSION_LE(r,v,s) \
        |	  (PERL_DECIMAL_VERSION <= PERL_VERSION_DECIMAL(r,v,s))
        |#endif
        |
        |/* XS_INTERNAL is the explicit static-linkage variant of the default
        | * XS macro.
        | *
        | * XS_EXTERNAL is the same as XS_INTERNAL except it does not include
        | * "STATIC", ie. it exports XSUB symbols. You probably don't want that
        | * for anything but the BOOT XSUB.
        | *
        | * See XSUB.h in core!
        | */
        |
        |
        |/* TODO: This might be compatible further back than 5.10.0. */
        |#if PERL_VERSION_GE(5, 10, 0) && PERL_VERSION_LE(5, 15, 1)
        |#  undef XS_EXTERNAL
        |#  undef XS_INTERNAL
        |#  if defined(__CYGWIN__) && defined(USE_DYNAMIC_LOADING)
        |#    define XS_EXTERNAL(name) __declspec(dllexport) XSPROTO(name)
        |#    define XS_INTERNAL(name) STATIC XSPROTO(name)
        |#  endif
        |#  if defined(__SYMBIAN32__)
        |#    define XS_EXTERNAL(name) EXPORT_C XSPROTO(name)
        |#    define XS_INTERNAL(name) EXPORT_C STATIC XSPROTO(name)
        |#  endif
        |#  ifndef XS_EXTERNAL
        |#    if defined(HASATTRIBUTE_UNUSED) && !defined(__cplusplus)
        |#      define XS_EXTERNAL(name) void name(pTHX_ CV* cv __attribute__unused__)
        |#      define XS_INTERNAL(name) STATIC void name(pTHX_ CV* cv __attribute__unused__)
        |#    else
        |#      ifdef __cplusplus
        |#        define XS_EXTERNAL(name) extern "C" XSPROTO(name)
        |#        define XS_INTERNAL(name) static XSPROTO(name)
        |#      else
        |#        define XS_EXTERNAL(name) XSPROTO(name)
        |#        define XS_INTERNAL(name) STATIC XSPROTO(name)
        |#      endif
        |#    endif
        |#  endif
        |#endif
        |
        |/* perl >= 5.10.0 && perl <= 5.15.1 */
        |
        |
        |/* The XS_EXTERNAL macro is used for functions that must not be static
        | * like the boot XSUB of a module. If perl didn't have an XS_EXTERNAL
        | * macro defined, the best we can do is assume XS is the same.
        | * Dito for XS_INTERNAL.
        | */
        |#ifndef XS_EXTERNAL
        |#  define XS_EXTERNAL(name) XS(name)
        |#endif
        |#ifndef XS_INTERNAL
        |#  define XS_INTERNAL(name) XS(name)
        |#endif
        |
        |/* Now, finally, after all this mess, we want an ExtUtils::ParseXS
        | * internal macro that we're free to redefine for varying linkage due
        | * to the EXPORT_XSUB_SYMBOLS XS keyword. This is internal, use
        | * XS_EXTERNAL(name) or XS_INTERNAL(name) in your code if you need to!
        | */
        |
        |#undef XS_EUPXS
        |#if defined(PERL_EUPXS_ALWAYS_EXPORT)
        |#  define XS_EUPXS(name) XS_EXTERNAL(name)
        |#else
        |   /* default to internal */
        |#  define XS_EUPXS(name) XS_INTERNAL(name)
        |#endif
        |
        |#ifndef PERL_ARGS_ASSERT_CROAK_XS_USAGE
        |#define PERL_ARGS_ASSERT_CROAK_XS_USAGE assert(cv); assert(params)
        |
        |/* prototype to pass -Wmissing-prototypes */
        |STATIC void
        |S_croak_xs_usage(const CV *const cv, const char *const params);
        |
        |STATIC void
        |S_croak_xs_usage(const CV *const cv, const char *const params)
        |{
        |    const GV *const gv = CvGV(cv);
        |
        |    PERL_ARGS_ASSERT_CROAK_XS_USAGE;
        |
        |    if (gv) {
        |        const char *const gvname = GvNAME(gv);
        |        const HV *const stash = GvSTASH(gv);
        |        const char *const hvname = stash ? HvNAME(stash) : NULL;
        |
        |        if (hvname)
        |	    Perl_croak_nocontext("Usage: %s::%s(%s)", hvname, gvname, params);
        |        else
        |	    Perl_croak_nocontext("Usage: %s(%s)", gvname, params);
        |    } else {
        |        /* Pants. I don't think that it should be possible to get here. */
        |	Perl_croak_nocontext("Usage: CODE(0x%" UVxf ")(%s)", PTR2UV(cv), params);
        |    }
        |}
        |#undef  PERL_ARGS_ASSERT_CROAK_XS_USAGE
        |
        |#define croak_xs_usage        S_croak_xs_usage
        |
        |#endif
        |
        |/* NOTE: the prototype of newXSproto() is different in versions of perls,
        | * so we define a portable version of newXSproto()
        | */
        |#ifdef newXS_flags
        |#define newXSproto_portable(name, c_impl, file, proto) newXS_flags(name, c_impl, file, proto, 0)
        |#else
        |#define newXSproto_portable(name, c_impl, file, proto) (PL_Sv=(SV*)newXS(name, c_impl, file), sv_setpv(PL_Sv, proto), (CV*)PL_Sv)
        |#endif /* !defined(newXS_flags) */
        |
        |#if PERL_VERSION_LE(5, 21, 5)
        |#  define newXS_deffile(a,b) Perl_newXS(aTHX_ a,b,file)
        |#else
        |#  define newXS_deffile(a,b) Perl_newXS_deffile(aTHX_ a,b)
        |#endif
        |
        |/* simple backcompat versions of the TARGx() macros with no optimisation */
        |#ifndef TARGi
        |#  define TARGi(iv, do_taint) sv_setiv_mg(TARG, iv)
        |#  define TARGu(uv, do_taint) sv_setuv_mg(TARG, uv)
        |#  define TARGn(nv, do_taint) sv_setnv_mg(TARG, nv)
        |#endif
        |
EOF

    # Fix up line number reckoning

    print 'ExtUtils::ParseXS::CountLines'->end_marker, "\n"
        if $pxs->{config_WantLineNumbers};
}


# ======================================================================

package ExtUtils::ParseXS::Node::cpp_scope;

# Node representing a part of an XS file which is all in the same C
# preprocessor scope as regards C preprocessor (CPP) conditionals, i.e.
# #if/#elsif/#else/#endif etc.
#
# Note that this only considers file-scoped C preprocessor directives;
# ones within a code block such as CODE or BOOT don't contribute to the
# state maintained here.
#
# Initially the whole XS part of the main XS file is considered a single
# scope, so the single main cpp_scope node would have, as children, all
# the file-scoped nodes such as Node::PROTOTYPES and any Node::xsub's.
#
# After an INCLUDE, the new XS file is considered as being in a separate
# scope, and gets its own child cpp_scope node.
#
# Once an XS file starts having file-scope CPP conditionals, then each
# branch of the conditional is considered a separate scope and  gets its
# own cpp_scope node. Nested conditionals cause nested cpp_scope objects
# in the AST.
#
# The main reason for this node type is to separate out the AST into
# separate sections which can each have the same named XSUB without a
# 'duplicate XSUB' warning, and where newXS()-type calls can be added to
# to the boot code for *both* XSUBs, guarded by suitable #ifdef's.
#
# This node is the main high-level node where file-scoped parsing takes
# place: its parse() method contains a fetch_para() loop which does all
# the looking for file-scoped keywords, CPP directives, and XSUB
# declarations. It implements a recursive-decent parser by creating child
# cpp_scope nodes and recursing into that child's parse() method (which
# does its own fetch_para() calls).

BEGIN { $build_subclass->(
    'type',       # Str:  what sort of scope: 'main', 'include' or 'if'
    'is_cmd',     # Bool: for include type, it's INCLUDE_COMMAND
    'guard_name', # Str:  the name of the XSubPPtmpAAAA guard define
    'seen_xsubs', # Hash: the names of any XSUBs seen in this scope
)};

sub parse {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    # Main loop: for each iteration, parse the next 'thing' in the current
    # paragraph, such as a C preprocessor directive, a contiguous block of
    # file-scoped keywords, or an XSUB. When the current paragraph runs
    # out, read in another one. XSUBs, TYPEMAP and BOOT will consume
    # all lines until the end of the current paragraph.
    #
    # C preprocessor conditionals such as #if may trigger recursive
    # calls to process each branch until the matching #endif. These may
    # cross paragraph boundaries.

    while ( ($pxs->{line} && @{$pxs->{line}}) || $pxs->fetch_para())
    {
        next unless @{$pxs->{line}}; # fetch_para() can return zero lines

        if (   !defined($self->{line_no})
            && defined $pxs->{line_no}[0]
        ) {
            # set file/line_no after line number info is available:
            # typically after the first call to fetch_para()
            $self->SUPER::parse($pxs);
        }

        # skip blank line
        shift @{$pxs->{line}}, next  if $pxs->{line}[0] !~ /\S/;

        # Process a C-preprocessor line. Note that any non-CPP lines
        # starting with '#' will already have been filtered out by
        # fetch_para().
        #
        # If its a #if or similar, then recursively process each branch
        # as a separate cpp_scope object until the matching #endif is
        # reached.

        if ($pxs->{line}[0] =~ /^#/) {
            my $node = ExtUtils::ParseXS::Node::global_cpp_line->new();
            $node->parse($pxs)
                or next;
            push @{$self->{kids}}, $node;

            next unless $node->{is_cond};

            # Parse branches of a CPP conditionals within a nested scope

            if (not $node->{is_if}) {
                $pxs->death("Error: '". $node->{directive}
                                . "' with no matching 'if'")
                    if $self->{type} ne 'if';

                # we should already be within a nested scope; this
                # CPP condition keyword just ends that scope. Our
                # (recursive) caller will handle processing any further
                # branches if it's an elif/else rather than endif

                return 1
            }

            # So it's an 'if'/'ifdef' etc node. Start a new
            # Node::cpp_scope sub-parse to handle that branch and then any
            # other branches of the same conditional.

            while (1) {
                # For each iteration, parse the next branch in a new scope
                my $scope = ExtUtils::ParseXS::Node::cpp_scope->new(
                                                {type => 'if'});
                $scope->parse($pxs)
                    or next;

                # Sub-parsing of that branch should have terminated
                # at an elif/endif line rather than falling off the
                # end of the file
                my $last = $scope->{kids}[-1];
                unless (
                       defined $last
                    && $last->isa(
                            'ExtUtils::ParseXS::Node::global_cpp_line')
                    &&  $last->{is_cond}
                    && !$last->{is_if}
                ) {
                    $pxs->death("Error: Unterminated '#if/#ifdef/#ifndef'")
                }

                # Move the CPP line which terminated the branch from
                # the end of the inner scope to the current scope
                pop @{$scope->{kids}};
                push @{$self->{kids}}, $scope, $last;

                if (grep { ref($_) !~ /::global_cpp_line$/ }
                        @{$scope->{kids}} )
                {
                    # the inner scope has some content, so needs
                    # a '#define XSubPPtmpAAAA 1'-style guard
                    $scope->{guard_name} = $pxs->{cpp_next_tmp_define}++;
                }

                # any more branches to process of current if?
                last if $last->{is_endif};
            } # while 1

            next;
        }

        # die if the next line is indented: all file-scoped things (CPP,
        # keywords, XSUB starts) are supposed to start on column 1
        # (although see the comment below about multiple parse_keywords()
        # iterations sneaking in indented keywords).
        #
        # The text of the error message is based around a common reason
        # for an indented line to appear in file scope: this is due to an
        # XSUB being prematurely truncated by fetch_para(). For example in
        # the code below, the coder wants the foo and bar lines to both be
        # part of the same CODE block. But the XS parser sees the blank
        # line followed by the '#ifdef' on column 1 as terminating the
        # current XSUB. So the bar() line is treated as being in file
        # scope and dies because it is indented.
        #
        #   |int f()
        #   |    CODE:
        #   |        foo();
        #   |
        #   |#ifdef USE_BAR
        #   |        bar();
        #   |#endif

        $pxs->death(
            "Code is not inside a function"
                ." (maybe last function was ended by a blank line "
                ." followed by a statement on column one?)")
            if $pxs->{line}->[0] =~ /^\s/;

        # The SCOPE keyword can appear both in file scope (just before an
        # XSUB) and as an XSUB keyword. This field maintains the state of the
        # former: reset it at the start of processing any file-scoped
        # keywords just before the XSUB (i.e. without any blank lines, e.g.
        #     SCOPE: ENABLE
        #     int
        #     foo(...)
        # These semantics may not be particularly sensible, but they maintain
        # backwards compatibility for now.

        $pxs->{file_SCOPE_enabled} = 0;

        # Process file-scoped keywords
        #
        # This loop repeatedly: skips any blank lines and then calls
        # the relevant Node::FOO::parse() method if it finds any of the
        # file-scoped keywords in the passed pattern.
        #
        # Note: due to the looping within parse_keywords() rather than
        # looping here, only the first keyword in a contiguous block
        # gets the 'start at column 1' check above enforced.
        # This is a bug, maintained for backwards compatibility: see the
        # comments below referring to SCOPE for other bits of code needed
        # to enforce this compatibility.

        $self->parse_keywords(
                $pxs,
                undef, undef, # xsub and xbody: not needed for non XSUB keywords
                undef,  # implies process as many keywords as possible
                 "BOOT|REQUIRE|PROTOTYPES|EXPORT_XSUB_SYMBOLS|FALLBACK"
              . "|VERSIONCHECK|INCLUDE|INCLUDE_COMMAND|SCOPE|TYPEMAP",
                $keywords_flag_MODULE,
            );
        # XXX we could have an 'or next' here if not for SCOPE backcompat
        # and also delete the following 'skip blank line' and 'next unless
        # @line' lines

        # skip blank lines
        shift @{$pxs->{line}} while @{$pxs->{line}} && $pxs->{line}[0] !~ /\S/;

        next unless @{$pxs->{line}};

        # Parse an XSUB

        my $xsub = ExtUtils::ParseXS::Node::xsub->new();
        $xsub->parse($pxs)
            or next;
        push @{$self->{kids}}, $xsub;

        # Check for a duplicate function definition in this scope
        {
            my $name = $xsub->{decl}{full_C_name};
            if ($self->{seen_xsubs}{$name}) {
                (my $short = $name) =~ s/^$pxs->{PACKAGE_C_name}_//;
                $pxs->Warn(  "Warning: duplicate function definition "
                       . "'$short' detected");
            }
            $self->{seen_xsubs}{$name} = 1;
        }

        # xsub->parse() should have consumed all the remaining
        # lines in the current paragraph.
        die "Internal error: unexpectedly not at EOF\n"
                  if @{$pxs->{line}};

        $pxs->{seen_an_XSUB} = 1; # encountered at least one XSUB

    } # END main 'while' loop

    1;
}


sub as_code {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    my $g = $self->{guard_name};
    print "#define $g 1\n\n" if defined $g;
    $_->as_code($pxs, $self) for @{$self->{kids}};
}


sub as_boot_code {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    # accumulate all the newXS()'s in $early and the BOOT blocks in $later,
    my ($early, $later) = $self->SUPER::as_boot_code($pxs);

    # then wrap them all within '#if XSubPPtmpAAAA' guards
    my $g = $self->{guard_name};
    if (defined $g) {
        unshift @$early, "#if $g\n";
        unshift @$later, "#if $g\n";
        push    @$early, "#endif\n";
        push    @$later, "#endif\n";
    }

    return $early, $later;
}


# ======================================================================

package ExtUtils::ParseXS::Node::global_cpp_line;

# AST node representing a single C-preprocessor line in file (global)
# scope. (A "single" line can actually include embedded "\\\n"'s from line
# continuations).

BEGIN { $build_subclass->(
    'cpp_line',  # Str:  the full text of the "#  foo" CPP line
    'directive', # Str:  one of 'define', 'endif' etc
    'rest',      # Str:  the rest of the line following the directive
    'is_cond',   # Bool: it's an ifdef/else/endif etc
    'is_if',     # Bool: it's an if/ifdef/ifndef
    'is_endif'   # Bool: it's an endif
)};

sub parse {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    $self->SUPER::parse($pxs); # set file/line_no

    my $line = shift @{$pxs->{line}};

    my ($directive, $rest) = $line =~ /^ \# \s* (\w+) (?:\s+ (.*) \s* $)?/sx
        or $pxs->death("Internal error: can't parse CPP line: $line\n");
    $rest = '' unless defined $rest;
    my $is_cond  = $directive =~ /^(if|ifdef|ifndef|elif|else|endif)$/;
    my $is_if    = $directive =~ /^(if|ifdef|ifndef)$/;
    my $is_endif = $directive =~ /^endif$/;
    @$self{qw(cpp_line directive rest is_cond is_if is_endif)}
        = ($line, $directive, $rest, $is_cond, $is_if, $is_endif);

    1;
}


sub as_code {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    print $self->{cpp_line}, "\n";
}


# ======================================================================

package ExtUtils::ParseXS::Node::BOOT;

# Store the code lines associated with the BOOT keyword
#
# Note that unlike other codeblock-like Node classes, BOOT consumes
# *all* lines remaining in the current paragraph, rather than stopping
# at the next keyword, if any.
# It's also file-scoped rather than XSUB-scoped.

BEGIN { $build_subclass->(
    'lines', # Array ref of all code lines making up the BOOT
)};


# Consume all the remaining lines and store in @$lines.

sub parse {
    my __PACKAGE__       $self = shift;
    my ExtUtils::ParseXS $pxs  = shift;

    $self->SUPER::parse($pxs); # set file/line_no

    # Check all the @{$pxs->{line}} lines for balance: all the
    # #if, #else, #endif etc within the BOOT should balance out.
    ExtUtils::ParseXS::Utilities::check_conditional_preprocessor_statements();

    # Suck in all remaining lines

    $self->{lines} = [ @{$pxs->{line}} ];
    @{$pxs->{line}} = ();

    # Ignore any text following the keyword on the same line.
    # XXX this quietly ignores any such text - really it should
    # warn, but not yet for backwards compatibility.
    shift @{$self->{lines}};

    1;
}


sub as_boot_code {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;

    my @lines;

    # Prepend a '#line' directive if not already present
    if (   $pxs->{config_WantLineNumbers}
        && @{$self->{lines}}
        && $self->{lines}[0] !~ /^\s*#\s*line\b/
    )
    {
        push @lines,
            sprintf "#line %d \"%s\"\n",
                $self->{line_no} + 1,
                ExtUtils::ParseXS::Utilities::escape_file_for_line_directive(
                        $self->{file});
    }

    # Save all the BOOT lines (plus trailing empty line) to be emitted
    # later.
    push @lines, "$_\n" for @{$self->{lines}}, "";

    return [], \@lines;
}

# ======================================================================

package ExtUtils::ParseXS::Node::TYPEMAP;

# Process the lines associated with the TYPEMAP keyword
#
# fetch_para() will have already processed the <<EOF logic
# and read all the lines up to, but not including, the EOF line.

BEGIN { $build_subclass->(
    'lines', # Array ref of all lines making up the TYPEMAP section
)};


# Feed all the lines to ExtUtils::Typemaps.

sub parse {
    my __PACKAGE__       $self = shift;
    my ExtUtils::ParseXS $pxs  = shift;

    $self->SUPER::parse($pxs); # set file/line_no

    shift @{$pxs->{line}}; # skip the 'TYPEMAP:' line

    # Suck in all remaining lines
    $self->{lines} = $pxs->{line};
    $pxs->{line} = [];

    my $tmap = ExtUtils::Typemaps->new(
        string        => join("", map "$_\n", @{$self->{lines}}),
        lineno_offset => 1 + ($pxs->current_line_number() || 0),
        fake_filename => $pxs->{in_filename},
    );

    $pxs->{typemaps_object}->merge(typemap => $tmap, replace => 1);

    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::pre_boot;

# AST node representing C code that is emitted after all user-defined
# XSUBs but before the boot XSUB. (This currently consists of
#  'Foo::Bar::()' XSUBs for any packages which have overloading.)
#
# This node's parse() method doesn't actually consume any lines; the node
# exists just for its as_code() method.

BEGIN { $build_subclass->(
)};

sub parse {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    $self->SUPER::parse($pxs); # set file/line_no
    1;
}

sub as_code {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    # For each package FOO which has had at least one overloaded method
    # specified:
    #   - create a stub XSUB in that package called nil;
    #   - generate code to be added to the boot XSUB which links that XSUB
    #     to the symbol table entry *{"FOO::()"}.  This mimics the action in
    #     overload::import() which creates the stub method as a quick way to
    #     check whether an object is overloaded (including via inheritance),
    #     by doing $self->can('()').
    #   - Further down, we add a ${"FOO:()"} scalar containing the value of
    #     'fallback' (or undef if not specified).
    #
    # XXX In 5.18.0, this arrangement was changed in overload.pm, but hasn't
    # been updated here. The *() glob was being used for two different
    # purposes: a sub to do a quick check of overloadability, and a scalar
    # to indicate what 'fallback' value was specified (even if it wasn't
    # specified). The commits:
    #   v5.16.0-87-g50853fa94f
    #   v5.16.0-190-g3866ea3be5
    #   v5.17.1-219-g79c9643d87
    # changed this so that overloadability is checked by &((, while fallback
    # is checked by $() (and not present unless specified by 'fallback'
    # as opposed to the always being present, but sometimes undef).
    # Except that, in the presence of fallback, &() is added too for
    # backcompat reasons (which I don't fully understand - DAPM).
    # See overload.pm's import() and OVERLOAD() methods for more detail.
    #
    # So this code (and the code in as_boot_code) needs updating to match.

    for my $package (sort keys %{$pxs->{map_overloaded_package_to_C_package}})
    {
        # make them findable with fetchmethod
        my $packid = $pxs->{map_overloaded_package_to_C_package}{$package};
        print $self->Q(<<"EOF");
            |XS_EUPXS(XS_${packid}_nil); /* prototype to pass -Wmissing-prototypes */
            |XS_EUPXS(XS_${packid}_nil)
            |{
            |   dXSARGS;
            |   PERL_UNUSED_VAR(items);
            |   XSRETURN_EMPTY;
            |}
            |
EOF
    }
}

sub as_boot_code {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    my @early;
    for my $package (sort keys %{$pxs->{map_overloaded_package_to_C_package}})
    {
        my $packid = $pxs->{map_overloaded_package_to_C_package}{$package};
        push @early, $self->Q(<<"EOF");
            |   /* Making a sub named "${package}::()" allows the package */
            |   /* to be findable via fetchmethod(), and causes */
            |   /* overload::Overloaded("$package") to return true. */
            |   (void)newXS_deffile("${package}::()", XS_${packid}_nil);
EOF
    }
    return \@early, [];
}


# ======================================================================

package ExtUtils::ParseXS::Node::boot_xsub;

# AST node representing C code that is emitted to create the boo XSUB.
#
# This node's parse() method doesn't actually consume any lines; the node
# exists just for its as_code() method.

BEGIN { $build_subclass->(
)};

sub parse {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    $self->SUPER::parse($pxs); # set file/line_no
    1;
}

sub as_code {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    # Walk the AST accumulating any boot code generated by
    # the various nodes' as_boot_code() methods.
    my ($early, $later) = $pxs->{AST}->as_boot_code($pxs);

    # Emit the boot_Foo__Bar() C function / XSUB

    print $self->Q(<<"EOF");
        |#ifdef __cplusplus
        |extern "C" $open_brace
        |#endif
        |XS_EXTERNAL(boot_$pxs->{MODULE_cname}); /* prototype to pass -Wmissing-prototypes */
        |XS_EXTERNAL(boot_$pxs->{MODULE_cname})
        |$open_brace
        |#if PERL_VERSION_LE(5, 21, 5)
        |    dVAR; dXSARGS;
        |#else
        |    dVAR; ${\($pxs->{VERSIONCHECK_value} ? 'dXSBOOTARGSXSAPIVERCHK;' : 'dXSBOOTARGSAPIVERCHK;')}
        |#endif
EOF

    # Declare a 'file' var for passing to newXS() and variants.
    #
    # If there is no $pxs->{seen_an_XSUB} then there are no xsubs
    # in this .xs so 'file' is unused, so silence warnings.
    #
    # 'file' can also be unused in other circumstances: in particular,
    # newXS_deffile() doesn't take a file parameter. So suppress any
    # 'unused var' warning always.
    #
    # Give it the correct 'const'ness: Under 5.8.x and lower, newXS() is
    # declared in proto.h as expecting a non-const file name argument. If
    # the wrong qualifier is used, it causes breakage with C++ compilers and
    # warnings with recent gcc.

    print $self->Q(<<"EOF") if $pxs->{seen_an_XSUB};
        |#if PERL_VERSION_LE(5, 8, 999) /* PERL_VERSION_LT is 5.33+ */
        |    char* file = __FILE__;
        |#else
        |    const char* file = __FILE__;
        |#endif
        |
        |    PERL_UNUSED_VAR(file);
EOF

    # Emit assorted declarations

    print $self->Q(<<"EOF");
        |
        |    PERL_UNUSED_VAR(cv); /* -W */
        |    PERL_UNUSED_VAR(items); /* -W */
EOF

    if ($pxs->{VERSIONCHECK_value}) {
        print $self->Q(<<"EOF");
        |#if PERL_VERSION_LE(5, 21, 5)
        |    XS_VERSION_BOOTCHECK;
        |#  ifdef XS_APIVERSION_BOOTCHECK
        |    XS_APIVERSION_BOOTCHECK;
        |#  endif
        |#endif
        |
EOF
    }
    else {
        print $self->Q(<<"EOF") ;
            |#if PERL_VERSION_LE(5, 21, 5) && defined(XS_APIVERSION_BOOTCHECK)
            |  XS_APIVERSION_BOOTCHECK;
            |#endif
            |
EOF
    }

    # Declare a 'cv' variable within a scope small enough to be visible
    # just to newXS() calls which need to do further processing of the cv:
    # in particular, when emitting one of:
    #      XSANY.any_i32 = $value;
    #      XSINTERFACE_FUNC_SET(cv, $value);

    if ($pxs->{need_boot_cv}) {
        print $self->Q(<<"EOF");
            |    $open_brace
            |        CV * cv;
            |
EOF
    }

    # More overload stuff

    if (keys %{ $pxs->{map_overloaded_package_to_C_package} }) {
        # Emit just once if any overloads:
        # Before 5.10, PL_amagic_generation used to need setting to at
        # least a non-zero value to tell perl that any overloading was
        # present.
        print $self->Q(<<"EOF");
            |    /* register the overloading (type 'A') magic */
            |#if PERL_VERSION_LE(5, 8, 999) /* PERL_VERSION_LT is 5.33+ */
            |    PL_amagic_generation++;
            |#endif
EOF

        for my $package (
            sort keys %{ $pxs->{map_overloaded_package_to_C_package} })
        {
            # Emit once for each package with overloads:
            # Set ${'Foo::()'} to the fallback value for each overloaded
            # package 'Foo' (or undef if not specified).
            # But see the 'XXX' comments above about fallback and $().

            my $fallback = $pxs->{map_package_to_fallback_string}{$package};
            $fallback = 'UNDEF' unless defined $fallback;
            $fallback = $fallback eq 'TRUE'  ? '&PL_sv_yes'
                                      : $fallback eq 'FALSE' ? '&PL_sv_no'
                                      :                        '&PL_sv_undef';

            print $self->Q(<<"EOF");
                |    /* The magic for overload gets a GV* via gv_fetchmeth as */
                |    /* mentioned above, and looks in the SV* slot of it for */
                |    /* the "fallback" status. */
                |    sv_setsv(
                |        get_sv( "${package}::()", TRUE ),
                |        $fallback
                |    );
EOF
        }
    }

    # Emit any boot code associated with newXS().

    print @$early;

    # Emit closing scope for the 'CV *cv' declaration

    if ($pxs->{need_boot_cv}) {
        print $self->Q(<<"EOF");
            |    $close_brace
EOF
    }

    # Emit any lines derived from BOOT: sections

    if (@$later) {
        print $self->Q(<<"EOF");
            |
            |    /* Initialisation Section */
            |
EOF

        print @$later;

        print 'ExtUtils::ParseXS::CountLines'->end_marker, "\n"
            if $pxs->{config_WantLineNumbers};

        print $self->Q(<<"EOF");
            |
            |    /* End of Initialisation Section */
            |
EOF
    }

    # Emit code to call any UNITCHECK blocks and return true.
    # Since 5.22, this is been put into a separate function.

    print $self->Q(<<"EOF");
        |#if PERL_VERSION_LE(5, 21, 5)
        |#  if PERL_VERSION_GE(5, 9, 0)
        |    if (PL_unitcheckav)
        |        call_list(PL_scopestack_ix, PL_unitcheckav);
        |#  endif
        |    XSRETURN_YES;
        |#else
        |    Perl_xs_boot_epilog(aTHX_ ax);
        |#endif
        |$close_brace
        |
        |#ifdef __cplusplus
        |$close_brace
        |#endif
EOF
}


# ======================================================================

package ExtUtils::ParseXS::Node::xsub;

# Process an entire XSUB definition

BEGIN { $build_subclass->(
    'decl',       # Node::xsub_decl object holding this XSUB's declaration

    # Boolean flags: they indicate that at least one of each specified
    # keyword has been seen in this XSUB
    'seen_ALIAS',
    'seen_INTERFACE',
    'seen_INTERFACE_MACRO',
    'seen_PPCODE',
    'seen_PROTOTYPE',
    'seen_SCOPE',

    # These three fields indicate how many SVs are returned to the caller,
    # and so influence the emitting of 'EXTEND(n)', 'XSRETURN(n)', and
    # potentially, the value of n in 'ST(n) = ...'.
    #
    # XSRETURN_count_basic is 0 or 1 and indicates whether a basic return
    # value is pushed onto the stack. It is usually directly related to
    # whether the XSUB is declared void, but NO_RETURN and CODE_sets_ST0
    # can alter that.
    #
    # XSRETURN_count_extra indicates how many SVs will be returned in
    # addition the basic 0 or 1. These will be params declared as OUTLIST.
    #
    # CODE_sets_ST0 is a flag indicating that something within a CODE
    # block is doing 'ST(0) = ..' or similar. This is a workaround for
    # a bug: see the code comments "Horrible 'void' return arg count hack"
    # in Node::CODE::parse() for more details.
    'CODE_sets_ST0',           # Bool
    'XSRETURN_count_basic',    # Int
    'XSRETURN_count_extra',    # Int

    # These maintain the alias parsing state across potentially multiple
    # ALIAS keywords and or lines:

    'map_alias_name_to_value', # Hash: maps seen alias names to their value

    'map_alias_value_to_name_seen_hash', # Hash of Hash of Bools:
                               # indicates which alias names have been
                               # used for each value.

    'alias_clash_hinted',      # Bool: an ALIAS warn-hint has been emitted.

    # Maintain the INTERFACE parsing state across potentially multiple
    # INTERFACE keywords and/or lines:

    'map_interface_name_short_to_original', # Hash: for each INTERFACE
                               # name, map the short (PREFIX removed) name
                               # to the original name.

    # Maintain the OVERLOAD parsing state across potentially multiple
    # OVERLOAD keywords and/or lines:

    'overload_name_seen',      # Hash of Bools: indicates overload method
                               # names (such as '<=>') which have been
                               # listed by OVERLOAD (for newXS boot code
                               # emitting).

    # Maintain the ATTRS parsing state across potentially multiple
    # ATTRS keywords and or lines:

    'attributes',              # Array of Strs: all ATTRIBUTE keywords
                               # (possibly multiple space-separated
                               # keywords per string).

    # INTERFACE_MACRO state

    'interface_macro',         # Str: value of interface extraction macro.
    'interface_macro_set',     # Str: value of interface setting macro.

    # PROTOTYPE value

    'prototype',               # Str: is set to either the global PROTOTYPES
                               #  values (0 or 1), or to what's been
                               #  overridden for this XSUB with PROTOTYPE
                               #    "0": DISABLE
                               #    "1": ENABLE
                               #    "2": empty prototype
                               #    other: a specific prototype.

    # Misc

    'SCOPE_enabled',           # Bool: "SCOPE: ENABLE" seen, in either the
                               # file or XSUB part of the XS file

    'PACKAGE_name',            # value of $pxs->{PACKAGE_name} at parse time
    'PACKAGE_C_name',          # value of $pxs->{PACKAGE_C_name} at parse time

)};


sub parse {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    $self->SUPER::parse($pxs); # set file/line_no

    # record what package we're in
    $self->{PACKAGE_name}   = $pxs->{PACKAGE_name};
    $self->{PACKAGE_C_name} = $pxs->{PACKAGE_C_name};

    # Initially inherit the prototype behaviour for the XSUB from the
    # global PROTOTYPES default
    $self->{prototype} = $pxs->{PROTOTYPES_value};

    # inherit any SCOPE: value that immediately preceded the XSUB
    # declaration
    $self->{SCOPE_enabled} = $pxs->{file_SCOPE_enabled};

    # Parse the XSUB's declaration (return type, name, parameters)

    my $decl = ExtUtils::ParseXS::Node::xsub_decl->new();
    $self->{decl} = $decl;
    $decl->parse($pxs, $self)
        or return;
    push @{$self->{kids}}, $decl;

    # Check all the @{ $pxs->{line}} lines for balance: all the
    # #if, #else, #endif etc within the XSUB should balance out.
    ExtUtils::ParseXS::Utilities::check_conditional_preprocessor_statements();

    # ----------------------------------------------------------------
    # Each iteration of this loop will process 1 optional CASE: line,
    # followed by all the other blocks. In the absence of a CASE: line,
    # this loop is only iterated once.
    # ----------------------------------------------------------------

    my $num             = 0; # the number of CASE+bodies seen
    my $seen_bare_xbody = 0; # seen a previous body without a CASE
    my $case_had_cond;       # the previous CASE had a condition

    # Repeatedly look for CASE or XSUB body.
    while (1) {
        # Parse a CASE statement if present.
        my ($case) =
            $self->parse_keywords(
                $pxs, $self, undef,  # xbody not yet present so use undef
                1,  # process maximum of one keyword
                "CASE",
            );

        if (defined $case) {
            $case->{num} = ++$num;
            $pxs->blurt("Error: 'CASE:' after unconditional 'CASE:'")
                if $num > 1 && ! $case_had_cond;
            $case_had_cond = length $case->{cond};
            $pxs->blurt("Error: no 'CASE:' at top of function")
                if $seen_bare_xbody;
        }
        else {
            $seen_bare_xbody = 1;
            if ($num++) {
                # After the first CASE+body, we should only encounter
                # further CASE+bodies or end-of-paragraph
                last unless @{$pxs->{line}};
                my $l = $pxs->{line}[0];
                $pxs->death(
                    $l =~ /^$ExtUtils::ParseXS::BLOCK_regexp/o
                            ? "Error: misplaced '$1:'"
                            : qq{Error: junk at end of function: "$l"}
                );
            }
        }

        # Parse the XSUB's body

        my $xbody = ExtUtils::ParseXS::Node::xbody->new();
        $xbody->parse($pxs, $self)
            or return;

        if (defined $case) {
            # make the xbody a child of the CASE
            push @{$case->{kids}}, $xbody;
            $xbody = $case;
        }
        else {
            push @{$self->{kids}}, $xbody;
        }
    } # end while (@{ $pxs->{line} })

    # If any aliases have been declared, make the main sub name ix 0
    # if not specified.

    if (            $self->{map_alias_name_to_value}
        and keys %{ $self->{map_alias_name_to_value} })
    {
        my $pname = $self->{decl}{full_perl_name};
        $self->{map_alias_name_to_value}{$pname} = 0
            unless defined $self->{map_alias_name_to_value}{$pname};
    }

    1;
}


sub as_code {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    # ----------------------------------------------------------------
    # Emit initial C code for the XSUB
    # ----------------------------------------------------------------

    {
        my $extern = $self->{decl}{return_type}{extern_C}
                        ? qq[extern "C"] : "";
        my $cname = $self->{decl}{full_C_name};

        # Emit function header
        print $self->Q(<<"EOF");
            |$extern
            |XS_EUPXS(XS_$cname); /* prototype to pass -Wmissing-prototypes */
            |XS_EUPXS(XS_$cname)
            |$open_brace
            |    dVAR; dXSARGS;
EOF
    }

    print $self->Q(<<"EOF") if $self->{seen_ALIAS};
        |    dXSI32;
EOF

    if ($self->{seen_INTERFACE}) {
        my $type = $self->{decl}{return_type}{type};
        $type =~ tr/:/_/
            unless $pxs->{config_RetainCplusplusHierarchicalTypes};
        print $self->Q(<<"EOF") if $self->{seen_INTERFACE};
            |    dXSFUNCTION($type);
EOF
    }


    {
        my $params = $self->{decl}{params};
        # the code to emit to determine whether the correct number of argument
        # have been passed
        my $condition_code =
            ExtUtils::ParseXS::set_cond($params->{seen_ellipsis},
                                        $params->{min_args},
                                        $params->{nargs});

        # "-except" cmd line switch
        print $self->Q(<<"EOF") if $pxs->{config_allow_exceptions};
            |    char errbuf[1024];
            |    *errbuf = '\\0';
EOF

        if ($condition_code) {
            my $p = $params->usage_string();
            $p =~ s/"/\\"/g;
            print $self->Q(<<"EOF");
                |    if ($condition_code)
                |       croak_xs_usage(cv,  "$p");
EOF
        }
        else {
            # cv and items likely to be unused
            print $self->Q(<<"EOF");
                |    PERL_UNUSED_VAR(cv); /* -W */
                |    PERL_UNUSED_VAR(items); /* -W */
EOF
        }
    }

    # gcc -Wall: if an XSUB has PPCODE, it is possible that none of ST,
    # XSRETURN or XSprePUSH macros are used.  Hence 'ax' (setup by
    # dXSARGS) is unused.
    # XXX: could breakup the dXSARGS; into dSP;dMARK;dITEMS
    # but such a move could break third-party extensions
    print $self->Q(<<"EOF") if $self->{seen_PPCODE};
        |    PERL_UNUSED_VAR(ax); /* -Wall */
EOF

    print $self->Q(<<"EOF") if $self->{seen_PPCODE};
        |    SP -= items;
EOF

    # ----------------------------------------------------------------
    # Emit the main body of the XSUB (all the CASE statements + bodies
    # or a single body)
    # ----------------------------------------------------------------

    $_->as_code($pxs, $self) for @{$self->{kids}};

    # ----------------------------------------------------------------
    # All of the body of the XSUB (including all CASE variants) has now
    # been processed. Now emit any XSRETURN or similar, plus any closing
    # bracket.
    # ----------------------------------------------------------------

    print $self->Q(<<"EOF") if $pxs->{config_allow_exceptions};
            |    if (errbuf[0])
            |    Perl_croak(aTHX_ errbuf);
EOF

    # Emit XSRETURN(N) or XSRETURN_EMPTY. It's possible that the user's
    # CODE section rolled its own return, so this code may be
    # unreachable. So suppress any compiler warnings.
    # XXX Currently this is just for HP. Make more generic??

    # Suppress "statement is unreachable" warning on HPUX
    print "#if defined(__HP_cc) || defined(__HP_aCC)\n",
                "#pragma diag_suppress 2128\n",
                "#endif\n"
        if $^O eq "hpux";

    unless ($self->{seen_PPCODE}) {
        my $nret = $self->{XSRETURN_count_basic}
                 + $self->{XSRETURN_count_extra};

        print $nret ? "    XSRETURN($nret);\n"
                    : "    XSRETURN_EMPTY;\n";
    }

    # Suppress "statement is unreachable" warning on HPUX
    print "#if defined(__HP_cc) || defined(__HP_aCC)\n",
                "#pragma diag_default 2128\n",
                "#endif\n"
        if $^O eq "hpux";

    # Emit final closing bracket for the XSUB.
    print "$close_brace\n\n";
}


# Return a list of boot code strings for the XSUB, including newXS()
# call(s) plus any additional boot stuff like handling attributes or
# storing an alias index in the XSUB's CV.

sub as_boot_code {
    my __PACKAGE__        $self   = shift;
    my ExtUtils::ParseXS  $pxs    = shift;

    # Depending on whether the XSUB has a prototype, work out how to
    # invoke one of the newXS() function variants. Set these:
    #
    my $newXS;     # the newXS() variant to be called in the boot section
    my $file_arg;  # an extra      ', file' arg to be passed to newXS call
    my $proto_arg; # an extra e.g. ', "$@"' arg to be passed to newXS call

    my @code; # boot code for each alias etc

    $proto_arg = "";

    unless($self->{prototype}) {
        # no prototype
        $newXS = "newXS_deffile";
        $file_arg = "";
    }
    else {
        # needs prototype
        $newXS = "newXSproto_portable";
        $file_arg = ", file";

        if ($self->{prototype} eq 2) {
            # User has specified an empty prototype
        }
        elsif ($self->{prototype} eq 1) {
            # Protoype enabled, but to be auto-generated by us
            $proto_arg = $self->{decl}{params}->proto_string();
            $proto_arg =~ s{\\}{\\\\}g; # escape backslashes
        }
        else {
            # User has manually specified a prototype
            $proto_arg = $self->{prototype};
        }

        $proto_arg = qq{, "$proto_arg"};
    }

    # Now use those values to append suitable newXS() and other code
    # into @code, for later insertion into the boot sub.

    my $pname = $self->{decl}{full_perl_name};
    my $cname = $self->{decl}{full_C_name};

    if (                $self->{map_alias_name_to_value}
            and keys %{ $self->{map_alias_name_to_value} })
    {
        # For the main XSUB and for each alias name, generate a newXS() call
        # and 'XSANY.any_i32 = ix' line.

        foreach my $xname (sort keys
                    %{ $self->{map_alias_name_to_value} })
        {
            my $value = $self->{map_alias_name_to_value}{$xname};
            push(@code, $self->Q(<<"EOF"));
                |        cv = $newXS(\"$xname\", XS_$cname$file_arg$proto_arg);
                |        XSANY.any_i32 = $value;
EOF
            $pxs->{need_boot_cv} = 1;
        }
    }
    elsif ($self->{attributes}) {
        # Generate a standard newXS() call, plus a single call to
        # apply_attrs_string() call with the string of attributes.
        my $attrs = "@{$self->{attributes}}";
        push(@code, $self->Q(<<"EOF"));
          |        cv = $newXS(\"$pname\", XS_$cname$file_arg$proto_arg);
          |        apply_attrs_string("$self->{PACKAGE_name}", cv, "$attrs", 0);
EOF
        $pxs->{need_boot_cv} = 1;
    }
    elsif (   $self->{seen_INTERFACE}
           or $self->{seen_INTERFACE_MACRO})
    {
        # For each interface name, generate both a newXS() and
        # XSINTERFACE_FUNC_SET() call.
        foreach my $yname (sort keys
                %{ $self->{map_interface_name_short_to_original} })
        {
            my $value = $self->{map_interface_name_short_to_original}{$yname};
            $yname = "$self->{PACKAGE_name}\::$yname" unless $yname =~ /::/;

            my $macro = $self->{interface_macro_set};
            $macro = 'XSINTERFACE_FUNC_SET' unless defined $macro;
            push(@code, $self->Q(<<"EOF"));
                |        cv = $newXS(\"$yname\", XS_$cname$file_arg$proto_arg);
                |        $macro(cv,$value);
EOF
            $pxs->{need_boot_cv} = 1;
        }
    }
    elsif ($newXS eq 'newXS_deffile'){
        # Modified default: generate a standard newXS() call; but
        # work around the CPAN 'P5NCI' distribution doing:
        #     #undef newXS
        #     #define newXS ;
        # by omitting the initial (void).
        # XXX DAPM 2024:
        # this branch was originally: "elsif ($newXS eq 'newXS')"
        # but when the standard name for the newXS variant changed in
        # xsubpp, it was changed here too. So this branch no longer actually
        # handles a workaround for '#define newXS ;'. I also don't
        # understand how just omitting the '(void)' fixed the problem.
        push(@code,
            "        $newXS(\"$pname\", XS_$cname$file_arg$proto_arg);\n");
    }
    else {
        # Default: generate a standard newXS() call
        push(@code,
          "        (void)$newXS(\"$pname\", XS_$cname$file_arg$proto_arg);\n");
    }

    # For every overload operator, generate an additional newXS()
    # call to add an alias such as "Foo::(<=>" for this XSUB.

    for my $operator (sort keys %{ $self->{overload_name_seen} })
    {
        my $overload = "$self->{PACKAGE_name}\::($operator";
        push(@code,
        "        (void)$newXS(\"$overload\", XS_$cname$file_arg$proto_arg);\n");
    }

    return \@code, [];
}


# ======================================================================

package ExtUtils::ParseXS::Node::xsub_decl;

# Parse and store the complete declaration part of an XSUB, including
# its parameters, name and return type.

BEGIN { $build_subclass->(
    'return_type',    # ReturnType object representing e.g "NO_OUTPUT char *"
    'params',         # Params object representing e.g "a, int b, c=0"
    'class',          # Str: the 'Foo::Bar' part of an XSUB's name;
                      #   - if defined, this is a C++ method
    'name',           # Str: the 'foo' XSUB name
    'full_perl_name', # Str: the 'Foo::Bar::foo' perl XSUB name
    'full_C_name',    # Str: the 'Foo__Bar__foo' C XSUB name
    'is_const',       # Bool: declaration had postfix C++ 'const' modifier
)};


# Parse the XSUB's declaration - i.e. return type, name and parameters.

sub parse {
    my __PACKAGE__                    $self   = shift;
    my ExtUtils::ParseXS              $pxs    = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;


    $self->SUPER::parse($pxs); # set file/line_no

    # Parse return type

    my $return_type = ExtUtils::ParseXS::Node::ReturnType->new();

    $return_type->parse($pxs, $xsub)
        or return;

    $self->{return_type} = $return_type;
    push @{$self->{kids}}, $return_type;

    # Decompose the function declaration: match a line like
    #   Some::Class::foo_bar(  args  ) const ;
    #   -----------  -------   ----    ----- --
    #       $1        $2        $3      $4   $5
    #
    # where everything except $2 and $3 are optional and the 'const'
    # is for C++ functions.

    my $func_header = shift(@{ $pxs->{line} });
    $pxs->blurt("Error: cannot parse function definition from '$func_header'"),
      return
        unless $func_header =~
            /^(?:([\w:]*)::)?(\w+)\s*\(\s*(.*?)\s*\)\s*(const)?\s*(;\s*)?$/s;

    my ($class, $name, $params_text, $const) = ($1, $2, $3, $4);

    if (defined $const and !defined $class) {
        $pxs->blurt("const modifier only allowed on XSUBs which are C++ methods");
        undef $const;
    }

    if ($return_type->{static} and !defined $class)
    {
        $pxs->Warn(  "Warning: ignoring 'static' type modifier:"
                   . " only valid with an XSUB name which includes a class");
        $return_type->{static} = 0;
    }

    (my $full_pname = $name) =~
            s/^($pxs->{PREFIX_pattern})?/$pxs->{PACKAGE_class}/;

    (my $clean_func_name = $name) =~ s/^$pxs->{PREFIX_pattern}//;

    my $full_cname = "$pxs->{PACKAGE_C_name}_$clean_func_name";
    $full_cname = $ExtUtils::ParseXS::VMS_SymSet->addsym($full_cname)
        if $ExtUtils::ParseXS::Is_VMS;

    $self->{class}          = $class;
    $self->{is_const}       = defined $const;
    $self->{name}           = $name;
    $self->{full_perl_name} = $full_pname;
    $self->{full_C_name}    = $full_cname;

    # At this point, supposing that the input so far was:
    #
    #   MODULE = ... PACKAGE = BAR::BAZ PREFIX = foo_
    #   int
    #   Some::Class::foo_bar(param1, param2, param3) const ;
    #
    # we should have:
    #
    # $self->{return_type}    an object holding "int"
    # $self->{class}          "Some::Class"
    # $self->{is_const}       TRUE
    # $self->{name}           "foo_bar"
    # $self->{full_perl_name} "BAR::BAZ::bar"
    # $self->{full_C_name}    "BAR__BAZ_bar"
    # $params_text            "param1, param2, param3"

    # ----------------------------------------------------------------
    # Process the XSUB's signature.
    #
    # Split $params_text into parameters, parse them, and store them as
    # Node::Param objects within the Node::Params object.

    my $params = $self->{params} = ExtUtils::ParseXS::Node::Params->new();

    $params->parse($pxs, $xsub, $params_text)
        or return;
    $self->{params} = $params;
    push @{$self->{kids}}, $params;

    # How many OUTLIST SVs get returned in addition to RETVAL
    $xsub->{XSRETURN_count_extra} =
                        grep {    defined $_->{in_out}
                               && $_->{in_out} =~ /OUTLIST$/
                             }
                        @{$self->{params}{kids}};
    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::ReturnType;

# Handle the 'return type' line at the start of an XSUB.
# It mainly consists of the return type, but there are also
# extra keywords to process, such as NO_RETURN.

BEGIN { $build_subclass->(
    'type',           # Str:  the XSUB's C return type
    'no_output',      # Bool: saw 'NO_OUTPUT'
    'extern_C',       # Bool: saw 'extern C'
    'static',         # Bool: saw 'static'
    'use_early_targ', # Bool: emit an early dTARG for backcompat
)};


# Extract out the return type declaration from the start of an XSUB.
# If the declaration and function name are on the same line, delete the
# type part; else pop the first line.

sub parse {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;

    $self->SUPER::parse($pxs); # set file/line_no

    # Whitespace-tidy the line containing the return type, plus possibly
    # the function name and arguments too.
    # XXX Tidying the latter was probably an unintended side-effect of
    # later allowing the return type and function to be on the same line.

    my $line = shift @{$pxs->{line}};
    $line = ExtUtils::Typemaps::tidy_type($line);
    my $type = $line;

    $self->{no_output} = 1 if $type =~ s/^NO_OUTPUT\s+//;

    # Allow one-line declarations. This splits a single line like:
    #    int foo(....)
    # into the two lines:
    #    int
    #    foo(...)
    #
    # Note that this splits both K&R-style 'foo(a, b)' and ANSI-style
    # 'foo(int a, int b)'. I don't know whether the former was intentional.
    # As of 5.40.0, the docs don't suggest that a 1-line K&R is legal. Was
    # added by 11416672a16, first appeared in 5.6.0.
    #
    # NB: $pxs->{config_allow_argtypes} is false if xsubpp was invoked
    # with -noargtypes

    unshift @{$pxs->{line}}, $2
        if $pxs->{config_allow_argtypes}
            and $type =~ s/^(.*?\w.*?) \s* \b (\w+\s*\(.*)/$1/sx;

    # a function definition needs at least 2 lines
    unless (@{$pxs->{line}}) {
        $pxs->blurt("Error: function definition too short '$line'");
        return;
    }

    $self->{extern_C} = 1 if $type =~ s/^extern "C"\s+//;
    $self->{static}   = 1 if $type =~ s/^static\s+//;
    $self->{type}     = $type;

    if ($type ne "void") {
        # Set a flag indicating that, for backwards-compatibility reasons,
        # early dXSTARG should be emitted.
        # Recent code emits a dXSTARG in a tighter scope and under
        # additional circumstances, but some XS code relies on TARG
        # having been declared. So continue to declare it early under
        # the original circumstances.
        my $outputmap = $pxs->{typemaps_object}->get_outputmap(ctype => $type);

        if (    $pxs->{config_optimize}
            and $outputmap
            and $outputmap->targetable_legacy)
        {
            $self->{use_early_targ} = 1;
        }
    }

    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::Param;

# Node subclass which holds the state of one XSUB parameter, based on the
# just the XSUB's signature. See also the Node::IO_Param subclass, which
# augments the parameter declaration with info from INPUT and OUTPUT
# lines.

BEGIN { $build_subclass->(
    # values derived from the XSUB's signature
    'in_out',        # Str:  The IN/OUT/OUTLIST etc value (if any)
    'var',           # Str:  the name of the parameter
    'arg_num',       # Int   The arg number (starting at 1) mapped to this param
    'default',       # Str:  default value (if any)
    'default_usage', # Str:  how to report default value in "usage:..." error
    'is_ansi',       # Bool: param's type was specified in signature
    'is_length',     # Bool: param is declared as 'length(foo)' in signature
    'has_length',    # Bool: this param has a matching 'length(foo)'
                     #       parameter in the signature
    'len_name' ,     # Str:  the 'foo' in 'length(foo)' in signature
    'is_synthetic',  # Bool: var like 'THIS': we pretend it was in the sig

    # values derived from both the XSUB's signature and/or INPUT line
    'type',          # Str:  The C type of the parameter
    'no_init',       # Bool: don't initialise the parameter

    # derived values calculated later
    'proto',         # Str: overridden prototype char(s) (if any) from typemap
)};


# Parse a parameter. A parameter is of the general form:
#
#    OUT char* foo = expression
#
#  where:
#    IN/OUT/OUTLIST etc are only allowed under
#                      $pxs->{config_allow_inout}
#
#    a C type       is only allowed under
#                      $pxs->{config_allow_argtypes}
#
#    foo            can be a plain C variable name, or can be
#    length(foo)    but only under $pxs->{config_allow_argtypes}
#
#    = default      default value - only allowed under
#                      $pxs->{config_allow_argtypes}

sub parse {
    my __PACKAGE__                     $self   = shift;
    my ExtUtils::ParseXS               $pxs    = shift;
    my                                 $params = shift; # parent Params
    my $param_text                             = shift;

    $self->SUPER::parse($pxs); # set file/line_no
    $_ = $param_text;

    # Decompose parameter into its components.
    # Note that $name can be either 'foo' or 'length(foo)'

    my ($out_type, $type, $name, $sp1, $sp2, $default) =
            /^
                 (?:
                     (IN|IN_OUT|IN_OUTLIST|OUT|OUTLIST)
                     \b\s*
                 )?
                 (.*?)                             # optional type
                 \s*
                 \b
                 (   \w+                           # var
                     | length\( \s*\w+\s* \)       # length(var)
                 )
                 (?:
                        (\s*) = (\s*) ( .*?)       # default expr
                 )?
                 \s*
             $
            /x;

    unless (defined $name) {
        if (/^ SV \s* \* $/x) {
            # special-case SV* as a placeholder for backwards
            # compatibility.
            $self->{var} = 'SV *';
            return 1;
        }
        $pxs->blurt("Error: unparseable XSUB parameter: '$_'");
        return;
    }

    undef $type unless length($type) && $type =~ /\S/;
    $self->{var} = $name;

    # Check for duplicates

    my $old_param = $params->{names}{$name};
    if ($old_param) {
        # Normally a dup parameter is an error, but we allow RETVAL as
        # a real parameter, which overrides the synthetic one which
        # was added earlier if the return value isn't void.
        if (    $name eq 'RETVAL'
                and $old_param->{is_synthetic}
                and !defined $old_param->{arg_num})
        {
            # RETVAL is currently fully synthetic. Now that it has
            # been declared as a parameter too, override any implicit
            # RETVAL declaration. Delete the original param from the
            # param list and later re-add it as a parameter in its
            # correct position.
            @{$params->{kids}} = grep $_ != $old_param, @{$params->{kids}};
            # If the param declaration includes a type, it becomes a
            # real parameter. Otherwise the param is kept as
            # 'semi-real' (synthetic, but with an arg_num) until such
            # time as it gets a type set in INPUT, which would remove
            # the synthetic/no_init.
            %$self = %$old_param unless defined $type;
        }
        else {
            $pxs->blurt(
                    "Error: duplicate definition of parameter '$name' ignored");
            return;
        }
    }

    # Process optional IN/OUT etc modifier

    if (defined $out_type) {
        if ($pxs->{config_allow_inout}) {
            $out_type =  $out_type eq 'IN' ? '' : $out_type;
        }
        else {
            $pxs->blurt("Error: parameter IN/OUT modifier not allowed under -noinout");
        }
    }
    else {
        $out_type = '';
    }

    # Process optional type

    if (defined($type) && !$pxs->{config_allow_argtypes}) {
        $pxs->blurt("Error: parameter type not allowed under -noargtypes");
        undef $type;
    }

    # Process 'length(foo)' pseudo-parameter

    my $is_length;
    my $len_name;

    if ($name =~ /^length\( \s* (\w+) \s* \)\z/x) {
        if ($pxs->{config_allow_argtypes}) {
            $len_name = $1;
            $is_length = 1;
            if (defined $default) {
                $pxs->blurt(  "Error: default value not allowed on "
                            . "length() parameter '$len_name'");
                undef $default;
            }
        }
        else {
            $pxs->blurt(  "Error: length() pseudo-parameter not allowed "
                        . "under -noargtypes");
        }
    }

    # Handle ANSI params: those which have a type or 'length(s)',
    # and which thus don't need a matching INPUT line.

    if (defined $type or $is_length) { # 'int foo' or 'length(foo)'
        @$self{qw(type is_ansi)} = ($type, 1);

        if ($is_length) {
            $self->{no_init}   = 1;
            $self->{is_length} = 1;
            $self->{len_name}  = $len_name;
        }
    }

    $self->{in_out} = $out_type if length $out_type;
    $self->{no_init} = 1        if $out_type =~ /^OUT/;

    # Process the default expression, including making the text
    # to be used in "usage: ..." error messages.

    my $report_def = '';
    if (defined $default) {
        # The default expression for reporting usage. For backcompat,
        # sometimes preserve the spaces either side of the '='
        $report_def =    ((defined $type or $is_length) ? '' : $sp1)
                       . "=$sp2$default";
        $self->{default_usage} = $report_def;
        $self->{default} = $default;
    }

    1;
}


# Set the 'proto' field of the param. This is based on the value, if any,
# of the proto method of the typemap for that param's type. It will
# typically be a single character like '$'.
#
# Note that params can have different types (and thus different proto
# chars) in different CASE branches.

sub set_proto {
    my __PACKAGE__       $self = shift;
    my ExtUtils::ParseXS $pxs  = shift;

    # only needed for real args that the caller may pass.
    return unless $self->{arg_num};
    my $type = $self->{type};
    return unless defined $type;
    my $typemap = $pxs->{typemaps_object}->get_typemap(ctype => $type);
    return unless defined $typemap;
    my $p = $typemap->proto;
    return unless defined $p && length $p;
    $self->{proto} = $p;
}


# ======================================================================

package ExtUtils::ParseXS::Node::IO_Param;

# Subclass of Node::Param which holds the state of one XSUB parameter,
# based on the XSUB's signature, but also augmented by info from INPUT or
# OUTPUT lines

BEGIN { $build_subclass->(-parent => 'Param',
    # values derived from the XSUB's INPUT line

    'init_op',     # Str:  initialisation type: one of =/+/;
    'init',        # Str:  initialisation template code
    'is_addr',     # Bool: INPUT var declared as '&foo'
    'is_alien',    # Bool: var declared in INPUT line, but not in signature
    'in_input',    # Bool: the parameter has appeared in an INPUT statement
    'defer',       # Str:  deferred initialisation template code

    # values derived from the XSUB's OUTPUT line
    #
    'in_output',   # Bool: the parameter has appeared in an OUTPUT statement
    'do_setmagic', # Bool: 'SETMAGIC: ENABLE' was active for this parameter
    'output_code', # Str:  the optional setting-code for this parameter

    # ArrayRefs: results of looking up typemaps (which are done in the
    # parse phase, as the typemap definitions can in theory change
    # further down in the XS file). For now these just store
    # uninterpreted, the list returned by the call to
    # lookup_input_typemap() etc, for later use by the as_input_code()
    # etc methods.
    #
    'input_typemap_vals',          # result of lookup_input_typemap()
    'output_typemap_vals',         # result of lookup_output_typemap(...)
    'output_typemap_vals_outlist', # result of lookup_output_typemap(..., n)
)};


# Given a param with known type etc, extract its typemap INPUT template
# and also create a hash of vars that can be used to eval that template.
# An undef returned hash ref signifies that the returned template string
# doesn't need to be evalled.
#
# Returns ($expr, $eval_vars, $is_template)
# or empty list on failure.
#
# $expr:        text like '$var = SvIV($arg)'
# $eval_vars:   hash ref like { var => 'foo', arg => 'ST(0)', ... }
# $is_template: $expr has '$arg' etc and needs evalling

sub lookup_input_typemap {
    my __PACKAGE__                   $self  = shift;
    my ExtUtils::ParseXS             $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub $xsub  = shift;
    my                               $xbody = shift;

    my ($type, $arg_num, $var, $init, $no_init, $default)
        = @{$self}{qw(type arg_num var init no_init default)};
    $var = "XSauto_length_of_$self->{len_name}" if $self->{is_length};
    my $arg = $pxs->ST($arg_num);

    # whitespace-tidy the type
    $type = ExtUtils::Typemaps::tidy_type($type);

    # Specify the environment for when the initialiser template is evaled.
    # Only the common ones are specified here. Other fields may be added
    # later.
    my $eval_vars = {
        type           => $type,
        var            => $var,
        num            => $arg_num,
        arg            => $arg,
        alias          => $xsub->{seen_ALIAS},
        func_name      => $xsub->{decl}{name},
        full_perl_name => $xsub->{decl}{full_perl_name},
        full_C_name    => $xsub->{decl}{full_C_name},
        Package        => $xsub->{PACKAGE_name},
    };

    # The type looked up in the eval is Foo__Bar rather than Foo::Bar
    $eval_vars->{type} =~ tr/:/_/
        unless $pxs->{config_RetainCplusplusHierarchicalTypes};

    my $init_template;

    if (defined $init) {
        # Use the supplied code template rather than getting it from the
        # typemap

        $pxs->death(
                "Internal error: ExtUtils::ParseXS::Node::Param::as_code(): "
              . "both init and no_init supplied")
            if $no_init;

        $eval_vars->{init} = $init;
        $init_template = "\$var = $init";
    }
    elsif ($no_init) {
        # don't add initialiser
        $init_template = "";
    }
    else {
        # Get the initialiser template from the typemap

        my $typemaps = $pxs->{typemaps_object};

        # Normalised type ('Foo *' becomes 'FooPtr): one of the valid vars
        # which can appear within a typemap template.
        (my $ntype = $type) =~ s/\s*\*/Ptr/g;

        # $subtype is really just for the T_ARRAY / DO_ARRAY_ELEM code below,
        # where it's the type of each array element. But it's also passed to
        # the typemap template (although undocumented and virtually unused).
        (my $subtype = $ntype) =~ s/(?:Array)?(?:Ptr)?$//;

        # look up the TYPEMAP entry for this C type and grab the corresponding
        # XS type name (e.g. $type of 'char *'  gives $xstype of 'T_PV'
        my $typemap = $typemaps->get_typemap(ctype => $type);
        if (not $typemap) {
            $pxs->report_typemap_failure($typemaps, $type);
            return;
        }
        my $xstype = $typemap->xstype;

        # An optimisation: for the typemaps which check that the dereferenced
        # item is blessed into the right class, skip the test for DESTROY()
        # methods, as more or less by definition, DESTROY() will be called
        # on an object of the right class. Basically, for T_foo_OBJ, use
        # T_foo_REF instead. T_REF_IV_PTR was added in v5.22.0.
        $xstype =~ s/OBJ$/REF/ || $xstype =~ s/^T_REF_IV_PTR$/T_PTRREF/
            if $xsub->{decl}{name} =~ /DESTROY$/;

        # For a string-ish parameter foo, if length(foo) was also declared
        # as a pseudo-parameter, then override the normal typedef - which
        # would emit SvPV_nolen(...) - and instead, emit SvPV(...,
        # STRLEN_length_of_foo)
        if ($xstype eq 'T_PV' and $self->{has_length}) {
            die "default value not supported with length(NAME) supplied"
                if defined $default;
            return "($type)SvPV($arg, STRLEN_length_of_$var);",
                   $eval_vars, 0;
        }

        # Get the ExtUtils::Typemaps::InputMap object associated with the
        # xstype. This contains the template of the code to be embedded,
        # e.g. 'SvPV_nolen($arg)'
        my $inputmap = $typemaps->get_inputmap(xstype => $xstype);
        if (not defined $inputmap) {
            $pxs->blurt("Error: no INPUT definition for type '$type', typekind '$xstype' found");
            return;
        }

        # Get the text of the template, with a few transformations to make it
        # work better with fussy C compilers. In particular, strip trailing
        # semicolons and remove any leading white space before a '#'.
        my $expr = $inputmap->cleaned_code;

        my $argoff = $arg_num - 1;

        # Process DO_ARRAY_ELEM. This is an undocumented hack that makes the
        # horrible T_ARRAY typemap work. "DO_ARRAY_ELEM" appears as a token
        # in the INPUT and OUTPUT code for for T_ARRAY, within a "for each
        # element" loop, and the purpose of this branch is to substitute the
        # token for some real code which will process each element, based
        # on the type of the array elements (the $subtype).
        #
        # Note: This gruesome bit either needs heavy rethinking or
        # documentation. I vote for the former. --Steffen, 2011
        # Seconded, DAPM 2024.
        if ($expr =~ /\bDO_ARRAY_ELEM\b/) {
            my $subtypemap  = $typemaps->get_typemap(ctype => $subtype);
            if (not $subtypemap) {
                $pxs->report_typemap_failure($typemaps, $subtype);
                return;
            }

            my $subinputmap =
                $typemaps->get_inputmap(xstype => $subtypemap->xstype);
            if (not $subinputmap) {
                $pxs->blurt("Error: no INPUT definition for subtype "
                            . "'$subtype', typekind '"
                            . $subtypemap->xstype . "' found");
                return;
            }

            my $subexpr = $subinputmap->cleaned_code;
            $subexpr =~ s/\$type/\$subtype/g;
            $subexpr =~ s/ntype/subtype/g;
            $subexpr =~ s/\$arg/ST(ix_$var)/g;
            $subexpr =~ s/\n\t/\n\t\t/g;
            $subexpr =~ s/is not of (.*\")/[arg %d] is not of $1, ix_$var + 1/g;
            $subexpr =~ s/\$var/${var}\[ix_$var - $argoff]/;
            $expr =~ s/\bDO_ARRAY_ELEM\b/$subexpr/;
        }

        if ($expr =~ m#/\*.*scope.*\*/#i) {  # "scope" in C comments
            $xsub->{SCOPE_enabled} = 1;
        }

        # Specify additional environment for when a template derived from a
        # *typemap* is evalled.
        @$eval_vars{qw(ntype subtype argoff)} = ($ntype, $subtype, $argoff);
        $init_template = $expr;
    }

    return ($init_template, $eval_vars, 1);
}



# Given a param with known type etc, extract its typemap OUTPUT template
# and also create a hash of vars that can be used to eval that template.
# An undef returned hash ref signifies that the returned template string
# doesn't need to be evalled.
# $out_num, if defined, signifies that this lookup is for an OUTLIST param
#
# Returns ($expr, $eval_vars, $is_template, $saw_DAE)
# or empty list on failure.
#
# $expr:        text like 'sv_setiv($arg, $var)'
# $eval_vars:   hash ref like { var => 'foo', arg => 'ST(0)', ... }
# $is_template: $expr has '$arg' etc and needs evalling
# $saw_DAE:     DO_ARRAY_ELEM was encountered
#

sub lookup_output_typemap {
    my __PACKAGE__                   $self    = shift;
    my ExtUtils::ParseXS             $pxs     = shift;
    my ExtUtils::ParseXS::Node::xsub $xsub    = shift;
    my                               $xbody   = shift;
    my                               $out_num = shift;

    my ($type, $num, $var, $do_setmagic, $output_code)
        = @{$self}{qw(type arg_num var do_setmagic output_code)};

    # values to return
    my ($expr, $eval_vars, $is_template, $saw_DAE);
    $is_template = 1;

    if ($var eq 'RETVAL') {
        # Do some preliminary RETVAL-specific checks and settings.

        # Only OUT/OUTPUT vars (which update one of the passed args) should be
        # calling set magic; RETVAL and OUTLIST should be setting the value of
        # a fresh mortal or TARG. Note that a param can be both OUTPUT and
        # OUTLIST - the value of $do_setmagic only applies to its use as an
        # OUTPUT (updating) value.

        $pxs->death("Internal error: do set magic requested on RETVAL")
            if $do_setmagic;

        # RETVAL normally has an undefined arg_num, although it can be
        # set to a real index if RETVAL is also declared as a parameter.
        # But when returning its value, it's always stored at ST(0).
        $num = 1;

        # It is possible for RETVAL to have multiple types, e.g.
        #     int
        #     foo(long RETVAL)
        #
        # In the above, 'long' is used for the RETVAL C var's declaration,
        # while 'int' is used to generate the return code (for backwards
        # compatibility).
        $type = $xsub->{decl}{return_type}{type};
    }

    # ------------------------------------------------------------------
    # Do initial processing of $type, including creating various derived
    # values

    unless (defined $type) {
        $pxs->blurt("Error: can't determine output type for '$var'");
        return;
    }

    # $ntype: normalised type ('Foo *' becomes 'FooPtr' etc): one of the
    # valid vars which can appear within a typemap template.
    (my $ntype = $type) =~ s/\s*\*/Ptr/g;
    $ntype =~ s/\(\)//g;

    # $subtype is really just for the T_ARRAY / DO_ARRAY_ELEM code below,
    # where it's the type of each array element. But it's also passed to
    # the typemap template (although undocumented and virtually unused).
    # Basically for a type like FooArray or FooArrayPtr, the subtype is Foo.
    (my $subtype = $ntype) =~ s/(?:Array)?(?:Ptr)?$//;

    # whitespace-tidy the type
    $type = ExtUtils::Typemaps::tidy_type($type);

    # The type as supplied to the eval is Foo__Bar rather than Foo::Bar
    my $eval_type = $type;
    $eval_type =~ tr/:/_/
        unless $pxs->{config_RetainCplusplusHierarchicalTypes};

    # We can be called twice for the same variable: once to update the
    # original arg (via an entry in OUTPUT) and once to push the param's
    # value (via OUTLIST). When doing the latter, any override code on an
    # OUTPUT line should not be used.
    undef $output_code if defined $out_num;

    # ------------------------------------------------------------------
    # Find the template code (pre any eval) and store it in $expr.
    # This is typically obtained via a typemap lookup, but can be
    # overridden. Also set vars ready for evalling the typemap template.

    my $outputmap;
    my $typemaps = $pxs->{typemaps_object};

    if (defined $output_code) {
        # An override on an OUTPUT line: use that instead of the typemap.
        # Note that we don't set $expr here, because $expr holds a template
        # string pre-eval, while OUTPUT override code is *not*
        # template-expanded, so $output_code is effectively post-eval code.
        $is_template = 0;
        $expr = $output_code;
    }
    elsif ($type =~ /^array\(([^,]*),(.*)\)/) {
        # Specially handle the implicit array return type, "array(type, nlelem)"
        # rather than using a typemap entry. It returns a string SV whose
        # buffer is a copy of $var, which it assumes is a C array of
        # type 'type' with 'nelem' elements.

        my ($atype, $nitems) = ($1, $2);

        if ($var ne 'RETVAL') {
            # This special type is intended for use only as the return type of
            # an XSUB
            $pxs->blurt(  "Error: can't use array(type,nitems) type for "
                        . (defined $out_num ? "OUTLIST" : "OUT")
                        . " parameter");
            return;
        }

        $expr =
            "\tsv_setpvn(\$arg, (char *)\$var, $nitems * sizeof($atype));\n";
    }
    else {
        # Handle a normal return type via a typemap.

        # Get the output map entry for this type; complain if not found.
        my $typemap = $typemaps->get_typemap(ctype => $type);
        if (not $typemap) {
            $pxs->report_typemap_failure($typemaps, $type);
            return;
        }

        $outputmap = $typemaps->get_outputmap(xstype => $typemap->xstype);
        if (not $outputmap) {
            $pxs->blurt(  "Error: no OUTPUT definition for type '$type', "
                        . "typekind '" . $typemap->xstype . "' found");
            return;
        }

        # Get the text of the typemap template, with a few transformations to
        # make it work better with fussy C compilers. In particular, strip
        # trailing semicolons and remove any leading white space before a '#'.

        $expr = $outputmap->cleaned_code;
    }

    my $arg = $pxs->ST(defined $out_num ? $out_num + 1 : $num);

    # Specify the environment for if/when the code template is evalled.
    $eval_vars =
        {
            num             => $num,
            var             => $var,
            do_setmagic     => $do_setmagic,
            subtype         => $subtype,
            ntype           => $ntype,
            arg             => $arg,
            type            => $eval_type,
            alias           => $xsub->{seen_ALIAS},
            func_name       => $xsub->{decl}{name},
            full_perl_name  => $xsub->{decl}{full_perl_name},
            full_C_name     => $xsub->{decl}{full_C_name},
            Package         => $xsub->{PACKAGE_name},
        };


    # ------------------------------------------------------------------
    # Handle DO_ARRAY_ELEM token as a very special case

    if (!defined $output_code and $expr =~ /\bDO_ARRAY_ELEM\b/) {
        # See the comments in ExtUtils::ParseXS::Node::Param::as_code() that
        # explain the similar code for the DO_ARRAY_ELEM hack there.

        if ($var ne 'RETVAL') {
            # Typemap templates containing DO_ARRAY_ELEM are assumed to
            # contain a loop which explicitly stores a new mortal SV at
            # each of the locations ST(0) .. ST(n-1), and which then uses
            # the code from the typemap for the underlying array element
            # to set each SV's value.
            #
            # This is a horrible hack for RETVAL, which would probably
            # fail with OUTLIST due to stack offsets being wrong, and
            # definitely would fail with OUT, which is supposed to be
            # updating parameter SVs, not pushing anything on the stack.
            # So forbid all except RETVAL.
            $pxs->blurt("Error: can't use typemap containing DO_ARRAY_ELEM for "
                        . (defined $out_num ? "OUTLIST" : "OUT")
                        . " parameter");
            return;
        }

        my $subtypemap = $typemaps->get_typemap(ctype => $subtype);
        if (not $subtypemap) {
            $pxs->report_typemap_failure($typemaps, $subtype);
            return;
        }

        my $suboutputmap =
            $typemaps->get_outputmap(xstype => $subtypemap->xstype);

        if (not $suboutputmap) {
            $pxs->blurt(  "Error: no OUTPUT definition for subtype '$subtype', "
                        . "typekind '" . $subtypemap->xstype . "' found");
            return;
        }

        my $subexpr = $suboutputmap->cleaned_code;
        $subexpr =~ s/ntype/subtype/g;
        $subexpr =~ s/\$arg/ST(ix_$var)/g;
        $subexpr =~ s/\$var/${var}\[ix_$var]/g;
        $subexpr =~ s/\n\t/\n\t\t/g;
        $expr =~ s/\bDO_ARRAY_ELEM\b/$subexpr/;

        $saw_DAE = 1;
    }

    return $expr, $eval_vars, $is_template, $saw_DAE;
}


# $self->as_input_code():
#
# Emit the param object as C code which declares and initialise the variable.
# See also the as_output_code() method, which emits code to return the value
# of that local var.

sub as_input_code {
    my __PACKAGE__                   $self  = shift;
    my ExtUtils::ParseXS             $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub $xsub  = shift;
    my                               $xbody = shift;

    my ($type, $arg_num, $var, $init, $no_init, $defer, $default)
        = @{$self}{qw(type arg_num var init no_init defer default)};

    my $arg = $pxs->ST($arg_num);

    if ($self->{is_length}) {
        # Process length(foo) parameter.
        # Basically for something like foo(char *s, int length(s)),
        # create *two* local C vars: one with STRLEN type, and one with the
        # type specified in the signature. Eventually, generate code looking
        # something like:
        #   STRLEN  STRLEN_length_of_s;
        #   int     XSauto_length_of_s;
        #   char *s = (char *)SvPV(ST(0), STRLEN_length_of_s);
        #   XSauto_length_of_s = STRLEN_length_of_s;
        #   RETVAL = foo(s, XSauto_length_of_s);
        #
        # Note that the SvPV() code line is generated via a separate call to
        # this sub with s as the var (as opposed to *this* call, which is
        # handling length(s)), by overriding the normal T_PV typemap (which
        # uses PV_nolen()).

        my $name = $self->{len_name};

        print "\tSTRLEN\tSTRLEN_length_of_$name;\n";
        # defer this line until after all the other declarations
        $xbody->{input_part}{deferred_code_lines} .=
                "\n\tXSauto_length_of_$name = STRLEN_length_of_$name;\n";
        $var = "XSauto_length_of_$name";
    }

    # Emit the variable's type and name.
    #
    # Includes special handling for function pointer types. An INPUT line
    # always has the C type followed by the variable name. The C code
    # which is emitted normally follows the same pattern. However for
    # function pointers, the code is different: the variable name has to
    # be embedded *within* the type. For example, these two INPUT lines:
    #
    #    char *        s
    #    int (*)(int)  fn_ptr
    #
    # cause the following lines of C to be emitted;
    #
    #    char *              s = [something from a typemap]
    #    int (* fn_ptr)(int)   = [something from a typemap]
    #
    # So handle specially the specific case of a type containing '(*)' by
    # embedding the variable name *within* rather than *after* the type.


    if ($type =~ / \( \s* \* \s* \) /x) {
        # for a fn ptr type, embed the var name in the type declaration
        print "\t" . $pxs->map_type($type, $var);
    }
    else {
        print   "\t",
                ((defined($xsub->{decl}{class}) && $var eq 'CLASS')
                    ? $type
                    : $pxs->map_type($type, undef)),
                "\t$var";
    }

    # Result of parse-phase lookup of INPUT typemap for this param's type.
    my $lookup = $self->{input_typemap_vals};
    $pxs->death(  "Internal error: parameter '$var' "
                . "doesn't have input_typemap_vals")
        unless $lookup;

    my ($init_template, $eval_vars, $is_template) = @$lookup;

    return unless defined $init_template; # an error occurred

    unless ($is_template) {
        # template already expanded
        print " = $init_template\n";
        return;
    }

    # whitespace-tidy the type
    $type = ExtUtils::Typemaps::tidy_type($type);

    # Now finally, emit the actual variable declaration and initialisation
    # line(s). The variable type and name will already have been emitted.

    my $init_code =
        length $init_template
            ? $pxs->eval_input_typemap_code("qq\a$init_template\a", $eval_vars)
            : "";


    if (defined $default
        # XXX for now, for backcompat, ignore default if the
        # param has a typemap override
        && !(defined $init)
        # XXX for now, for backcompat, ignore default if the
        # param wouldn't otherwise get initialised
        && !$no_init
    ) {
        # Has a default value. Just terminate the variable declaration, and
        # defer the initialisation.

        print ";\n";

        # indent the code 1 step further
        $init_code =~ s/(\t+)/$1    /g;
        $init_code =~ s/        /\t/g;

        if ($default eq 'NO_INIT') {
            # for foo(a, b = NO_INIT), add code to initialise later only if
            # an arg was supplied.
            $xbody->{input_part}{deferred_code_lines}
                .= sprintf "\n\tif (items >= %d) {\n%s;\n\t}\n",
                           $arg_num, $init_code;
        }
        else {
            # for foo(a, b = default), add code to initialise later to either
            # the arg or default value
            my $else = $init_code =~ /\S/
                        ? "\telse {\n$init_code;\n\t}\n"
                        : "";

            $default =~ s/"/\\"/g; # escape double quotes
            $xbody->{input_part}{deferred_code_lines}
                .= sprintf "\n\tif (items < %d)\n\t    %s = %s;\n%s",
                    $arg_num,
                    $var,
                    $pxs->eval_input_typemap_code("qq\a$default\a",
                                                   $eval_vars),
                    $else;
        }
    }
    elsif ($xsub->{SCOPE_enabled} or $init_code !~ /^\s*\Q$var\E =/) {
        # The template is likely a full block rather than a '$var = ...'
        # expression. Just terminate the variable declaration, and defer the
        # initialisation.
        # Note that /\Q$var\E/ matches the string containing whatever $var
        # was expanded to in the eval.

        print ";\n";

        $xbody->{input_part}{deferred_code_lines}
                                        .= sprintf "\n%s;\n", $init_code
            if $init_code =~ /\S/;
    }
    else {
        # The template starts with '$var = ...'. The variable name has already
        # been emitted, so remove it from the typemap before evalling it,

        $init_code =~ s/^\s*\Q$var\E(\s*=\s*)/$1/
            # we just checked above that it starts with var=, so this
            # should never happen
            or $pxs->death(
                "Internal error: typemap doesn't start with '\$var='\n");

        printf "%s;\n", $init_code;
    }

    if (defined $defer) {
        $xbody->{input_part}{deferred_code_lines}
            .=   $pxs->eval_input_typemap_code("qq\a$defer\a", $eval_vars)
               . "\n";
    }
}


# $param->as_output_code($ParseXS_object, $out_num])
#
# Emit code to: possibly create, then set the value of, and possibly
# push, an output SV, based on the values in the $param object.
#
# $out_num is optional and its presence indicates that an OUTLIST var is
# being pushed: it indicates the position on the stack of that SV.
#
# This function emits code such as "sv_setiv(ST(0), (IV)foo)", based on
# the typemap OUTPUT entry associated with $type. It passes the typemap
# code through a double-quotish context eval first to expand variables
# such as $arg and $var. It also tries to optimise the emitted code in
# various ways, such as using TARG where available rather than calling
# sv_newmortal() to obtain an SV to set to the return value.
#
# It expects to handle three categories of variable, with these general
# actions:
#
#   RETVAL, i.e. the return value
#
#     Create a new SV; use the typemap to set its value to RETVAL; then
#     store it at ST(0).
#
#   OUTLIST foo
#
#     Create a new SV; use the typemap to set its value to foo; then store
#     it at ST($out_num-1).
#
#   OUTPUT: foo / OUT foo
#
#     Update the value of the passed arg ST($num-1), using the typemap to
#     set its value
#
# Note that it's possible for this function to be called *twice* for the
# same variable: once for OUTLIST, and once for an 'OUTPUT:' entry.
#
# It treats output typemaps as falling into two basic categories,
# exemplified by:
#
#     sv_setFoo($arg, (Foo)$var));
#
#     $arg = newFoo($var);
#
# The first form is the most general and can be used to set the SV value
# for all of the three variable categories above. For the first two
# categories it typically uses a new mortal, while for the last, it just
# uses the passed arg SV.
#
# The assign form of the typemap can be considered an optimisation of
# sv_setsv($arg, newFoo($var)), and is applicable when newFOO() is known
# to return a new SV. So rather than copying it to yet another new SV,
# just return as-is, possibly after mortalising it,
#
# Some typemaps evaluate to different code depending on whether the var is
# RETVAL, e.g T_BOOL is currently defined as:
#
#    ${"$var" eq "RETVAL" ? \"$arg = boolSV($var);"
#                         : \"sv_setsv($arg, boolSV($var));"}
#
# So we examine the typemap *after* evaluation to determine whether it's
# of the form '$arg = ' or not.
#
# Note that *currently* we generally end up with the pessimised option for
# OUTLIST vars, since the typmaps onlt check for RETVAL.
#
# Currently RETVAL and 'OUTLIST var' mostly share the same code paths
# below, so they both benefit from optimisations such as using TARG
# instead of creating a new mortal, and using the RETVALSV C var to keep
# track of the temp SV, rather than repeatedly retrieving it from ST(0)
# etc. Note that RETVALSV is private and shouldn't be referenced within XS
# code or typemaps.

sub as_output_code {
    my __PACKAGE__                   $self   = shift;
    my ExtUtils::ParseXS             $pxs    = shift;
    my ExtUtils::ParseXS::Node::xsub $xsub   = shift;
    my                               $xbody  = shift;
    my                               $out_num = shift;

    my ($type, $var, $do_setmagic, $output_code)
        = @{$self}{qw(type var do_setmagic output_code)};

    if ($var eq 'RETVAL') {
        # It is possible for RETVAL to have multiple types, e.g.
        #     int
        #     foo(long RETVAL)
        #
        # In the above, 'long' is used for the RETVAL C var's declaration,
        # while 'int' is used to generate the return code (for backwards
        # compatibility).
        $type = $xsub->{decl}{return_type}{type};
    }

    # whitespace-tidy the type
    $type = ExtUtils::Typemaps::tidy_type($type);

    # We can be called twice for the same variable: once to update the
    # original arg (via an entry in OUTPUT) and once to push the param's
    # value (via OUTLIST). When doing the latter, any override code on an
    # OUTPUT line should not be used.
    undef $output_code if defined $out_num;

    # Result of parse-phase lookup of OUTPUT typemap for this param's type.
    my $lookup = defined $out_num
                            ? $self->{output_typemap_vals_outlist}
                            : $self->{output_typemap_vals};
    $pxs->death(  "Internal error: parameter '$var' "
                . "doesn't have output_typemap_vals")
        unless $lookup;

    my ($expr, $eval_vars, $is_template, $saw_DAE) = @$lookup;

    return unless defined $expr; # error

    if ($saw_DAE) {
        # We do our own code emitting and return here (rather than control
        # passing on to normal RETVAL processing) since that processing is
        # expecting to push a single temp onto the stack, while our code
        # pushes several temps.
        print $pxs->eval_output_typemap_code("qq\a$expr\a", $eval_vars);
        return;
    }
    elsif (!$is_template) {
        # $expr doesn't need evalling - use as-is
        $output_code = $expr;
    }

    my $ntype = $eval_vars->{ntype};
    my $num   = $eval_vars->{num};
    my $arg   = $eval_vars->{arg};

    # ------------------------------------------------------------------
    # Now emit code for the three types of return value:
    #
    #   RETVAL           - The usual case: store an SV at ST(0) which is set
    #                      to the value of RETVAL. This is typically a new
    #                      mortal, but may be optimised to use TARG.
    #
    #   OUTLIST param    - if $out_num is defined (and will be >= 0) Push
    #                      after any RETVAL, new mortal(s) containing the
    #                      current values of the local var set from that
    #                      parameter. (May also use TARG if not already used
    #                      by RETVAL).
    #
    #   OUT/OUTPUT param - update passed arg SV at ST($num-1) (which
    #                      corresponds to param) with the current value of
    #                      the local var set from that parameter.

    if ($var ne 'RETVAL' and not defined $out_num) {
        # This is a normal OUTPUT var: i.e. a named parameter whose
        # corresponding arg on the stack should be updated with the
        # parameter's current value by using the code contained in the
        # output typemap.
        #
        # Note that for args being *updated* (as opposed to replaced), this
        # branch relies on the typemap to Do The Right Thing. For example,
        # T_BOOL currently has this typemap entry:
        #
        # ${"$var" eq "RETVAL" ? \"$arg = boolSV($var);"
        #                      : \"sv_setsv($arg, boolSV($var));"}
        #
        # which means that if we hit this branch, $evalexpr will have been
        # expanded to something like "sv_setsv(ST(2), boolSV(foo))".

        unless (defined $num) {
            $pxs->blurt(
                "Internal error: OUT parameter has undefined argument number");
            return;
        }

        # Use the code on the OUTPUT line if specified, otherwise use the
        # typemap
        my $code = defined $output_code
                ? "\t$output_code\n"
                : $pxs->eval_output_typemap_code("qq\a$expr\a", $eval_vars);
        print $code;

        # For parameters in the OUTPUT section, honour the SETMAGIC in force
        # at the time. For parameters instead being output because of an OUT
        # keyword in the signature, assume set magic always.
        print "\tSvSETMAGIC($arg);\n" if !$self->{in_output} || $do_setmagic;
        return;
    }

    # ------------------------------------------------------------------
    # The rest of this main body handles RETVAL or "OUTLIST foo".

    if (defined $output_code and !defined $out_num) {
        # Handle this (just emit overridden code as-is):
        #    OUTPUT:
        #       RETVAL output_code
        print "\t$output_code\n";
        print "\t++SP;\n" if $xbody->{output_part}{stack_was_reset};
        return;
    }

    # Emit a standard RETVAL/OUTLIST return

    # ------------------------------------------------------------------
    # First, evaluate the typemap, expanding any vars like $var and $arg,
    # for example,
    #
    #     $arg = newFoo($var);
    # or
    #     sv_setFoo($arg, $var);
    #
    # However, rather than using the actual destination (such as ST(0))
    # for the value of $arg, we instead set it initially to RETVALSV. This
    # is because often the SV will be used in more than one statement,
    # and so it is more efficient to temporarily store it in a C auto var.
    # So we normally emit code such as:
    #
    #  {
    #     SV *RETVALSV;
    #     RETVALSV = newFoo(RETVAL);
    #     RETVALSV = sv_2mortal(RETVALSV);
    #     ST(0) = RETVALSV;
    #  }
    #
    # Rather than
    #
    #     ST(0) = newFoo(RETVAL);
    #     sv_2mortal(ST(0));
    #
    # Later we sometimes modify the evalled typemap to change 'RETVALSV'
    # to some other value:
    #   - back to e.g. 'ST(0)' if there is no other use of the SV;
    #   - to TARG when we are using the OP_ENTERSUB's targ;
    #   - to $var when then return type is SV* (and thus ntype is SVPtr)
    #     and so the variable will already have been declared as type 'SV*'
    #     and thus there is no need for a RETVALSV too.
    #
    # Note that we evaluate the typemap early here so that the various
    # regexes below such as /^\s*\Q$arg\E\s*=/ can be matched against
    # the *evalled* result of typemap entries such as
    #
    # ${ "$var" eq "RETVAL" ? \"$arg = $var;" : \"sv_setsv_mg($arg, $var);" }
    #
    # which may eval to something like "RETVALSV = RETVAL" and
    # subsequently match /^\s*\Q$arg\E =/ (where $arg is "RETVAL"), but
    # couldn't have matched against the original typemap.
    # This is why we *always* set $arg to 'RETVALSV' first and then modify
    # the typemap later - we don't know what final value we want for $arg
    # until after we've examined the evalled result.

    my $orig_arg = $arg;
    $eval_vars->{arg} = $arg = 'RETVALSV';
    my $evalexpr = $pxs->eval_output_typemap_code("qq\a$expr\a", $eval_vars);

    # ------------------------------------------------------------------
    # Examine the just-evalled typemap code to determine what optimisations
    # etc can be performed and what sort of code needs emitting. The two
    # halves of this following if/else examine the two forms of evalled
    # typemap:
    #
    #     RETVALSV = newFoo((Foo)RETVAL);
    # and
    #     sv_setFoo(RETVALSV, (Foo)RETVAL);
    #
    # In particular, the first form is assumed to be returning an SV which
    # the function has generated itself (e.g. newSVREF()) and which may
    # just need mortalising; while the second form generally needs a call
    # to sv_newmortal() first to create an SV which the function can then
    # set the value of.

    my $do_mortalize   = 0;  # Emit an sv_2mortal()
    my $want_newmortal = 0;  # Emit an sv_newmortal()
    my $retvar = 'RETVALSV'; # The name of the C var which holds the SV
                             # (likely tmp) to set to the value of the var

    if ($evalexpr =~ /^\s*\Q$arg\E\s*=/) {
        # Handle this form: RETVALSV = newFoo((Foo)RETVAL);
        # newFoo creates its own SV: we just need to mortalise and return it

        # Is the SV one of the immortal SVs?
        if ($evalexpr =~
                /^\s*
                    \Q$arg\E
                    \s*=\s*
                    (  boolSV\(.*\)
                    |  &PL_sv_yes
                    |  &PL_sv_no
                    |  &PL_sv_undef
                    |  &PL_sv_zero
                    )
                    \s*;\s*$
                /x)
        {
            # If so, we can skip mortalising it to stop it leaking.
            $retvar = $orig_arg; # just assign to ST(N) directly
        }
        else {
            # general '$arg = newFOO()' typemap
            $do_mortalize = 1;

            # If $var is already of type SV*, then use that instead of
            # declaring 'SV* RETVALSV' as an intermediate var.
            $retvar = $var if $ntype eq "SVPtr";
        }
    }
    else {
        # Handle this (eval-expanded) form of typemap:
        #     sv_setFoo(RETVALSV, (Foo)var);
        # We generally need to supply a mortal SV for the typemap code to
        # set, and then return it on the stack,

        # First, see if we can use the targ (if any) attached to the current
        # OP_ENTERSUB, to avoid having to create a new mortal.
        #
        # The targetable() OutputMap class method looks at whether the code
        # snippet is of a form suitable for using TARG as the destination.
        # It looks for one of a known list of well-behaved setting function
        # calls, like sv_setiv() which will set the TARG to a value that
        # doesn't include magic, tieing, being a reference (which would leak
        # as the TARG is never freed), etc. If so, emit dXSTARG and replace
        # RETVALSV with TARG.
        #
        # For backwards-compatibility, dXSTARG may have already been emitted
        # early in the XSUB body, when a more restrictive set of targ-
        # compatible typemap entries were checked for. Note that dXSTARG is
        # defined as something like:
        #
        #   SV * targ = (PL_op->op_private & OPpENTERSUB_HASTARG)
        #               ? PAD_SV(PL_op->op_targ) : sv_newmortal()

        if (   $pxs->{config_optimize}
                && ExtUtils::Typemaps::OutputMap->targetable($evalexpr)
                && !$xbody->{output_part}{targ_used})
        {
            # So TARG is available for use.
            $retvar = 'TARG';
            # can only use TARG to return one value
            $xbody->{output_part}{targ_used} = 1;

            # Since we're using TARG for the return SV, see if we can use
            # the TARG[iun] macros as appropriate to speed up setting it.
            # If so, convert "sv_setiv(RETVALSV, val)" to "TARGi(val,1)"
            # and similarly for uv and nv. These macros skip a function
            # call for the common case where TARG is already a simple
            # IV/UV/NV. Convert the _mg forms too: since we're setting the
            # TARG, there shouldn't be set magic on it, so the _mg action
            # can be safely ignored.

            $evalexpr =~ s{
                              ^
                              (\s*)
                              sv_set([iun])v(?:_mg)?
                              \(
                                  \s* RETVALSV \s* ,
                                  \s* (.*)
                              \)
                              ( \s* ; \s*)
                              $
                          }
                          {$1TARG$2($3, 1)$4}x;
        }
        else {
            # general typemap: give it a fresh SV to set the value of.
            $want_newmortal = 1;
        }
    }

    # ------------------------------------------------------------------
    # Now emit the return C code, based on the various flags and values
    # determined above.

    my $do_scope; # wrap code in a {} block
    my @lines;    # Lines of code to eventually emit

    # Do any declarations first

    if ($retvar eq 'TARG' && !$xsub->{decl}{return_type}{use_early_targ}) {
        push @lines, "\tdXSTARG;\n";
        $do_scope = 1;
    }
    elsif ($retvar eq 'RETVALSV') {
        push @lines, "\tSV * $retvar;\n";
        $do_scope = 1;
    }

    push @lines, "\tRETVALSV = sv_newmortal();\n" if $want_newmortal;

    # Emit the typemap, while changing the name of the destination SV back
    # from RETVALSV to one of the other forms (varname/TARG/ST(N)) if was
    # determined earlier to be necessary.
    # Skip emitting it if it's of the trivial form "var = var", which is
    # generated when the typemap is of the form '$arg = $var' and the SVPtr
    # optimisation is using $var for the destination.

    $evalexpr =~ s/\bRETVALSV\b/$retvar/g if $retvar ne 'RETVALSV';

    unless ($evalexpr =~ /^\s*\Q$var\E\s*=\s*\Q$var\E\s*;\s*$/) {
        push @lines, split /^/, $evalexpr
    }

    # Emit mortalisation on the result SV if needed
    push @lines, "\t$retvar = sv_2mortal($retvar);\n" if $do_mortalize;

    # Emit the final 'ST(n) = RETVALSV' or similar, unless ST(n)
    # was already assigned to earlier directly by the typemap.
    push @lines, "\t$orig_arg = $retvar;\n" unless $retvar eq $orig_arg;

    if ($do_scope) {
        # Add an extra 4-indent, then wrap the output code in a new block
        for (@lines) {
            s/\t/        /g;   # break down all tabs into spaces
            s/^/    /;         # add 4-space extra indent
            s/        /\t/g;   # convert 8 spaces back to tabs
        }
        unshift @lines,  "\t{\n";
        push    @lines,  "\t}\n";
    }

    print @lines;
    print "\t++SP;\n" if $xbody->{output_part}{stack_was_reset};
}


# ======================================================================

package ExtUtils::ParseXS::Node::Params;

# A Node subclass which holds a list of the parameters for an XSUB.
# It is a mainly a list of Node::Param or Node::IO_Param kids, and is
# used in two contexts.
#
# First, as a field of an xsub_decl node, where it holds a list of Param
# objects which represent the individual parameters found within an XSUB's
# signature, plus possibly extra synthetic ones such as THIS and RETVAL.
#
# Second, as a field of an xbody node, where it contains a copy of the
# signature's Params object (and Param children), but where the children
# are in fact IO_param objects and hold augmented information provided by
# any INPUT and OUTPUT blocks within that XSUB body (of which there can be
# more than one in the presence of CASE).

BEGIN { $build_subclass->(

    'names',         # Hash ref mapping variable names to Node::Param
                     # or Node::IO_Param objects

    'params_text',   # Str:  The original text of the sig, e.g.
                     #         "param1, int param2 = 0"

    'seen_ellipsis', # Bool: XSUB signature has (   ,...)

    'nargs',         # Int:  The number of args expected from caller
    'min_args',      # Int:  The minimum number of args allowed from caller

    'auto_function_sig_override', # Str: the C_ARGS value, if any
)};


# ----------------------------------------------------------------
# Parse the parameter list of an XSUB's signature.
#
# Split the XSUB's parameter list on commas into parameters, while
# allowing for things like '(a = ",", b)'.
#
# Then for each parameter, parse its various fields and store in a
# ExtUtils::ParseXS::Node::Param object. Store those Param objects within
# the Params object, plus any other state deduced from the signature, such
# as min/max permitted number of args.
#
# A typical signature might look like:
#
#    OUT     char *s,             \
#            int   length(s),     \
#    OUTLIST int   size     = 10)
#
# ----------------------------------------------------------------

my ($C_group_rex, $C_arg);

# Group in C (no support for comments or literals)
#
# DAPM 2024: I'm not entirely clear what this is supposed to match.
# It appears to match balanced and possibly nested [], {} etc, with
# similar but possibly unbalanced punctuation within. But the balancing
# brackets don't have to correspond: so [} is just as valid as [] or {},
# as is [{{{{] or even [}}}}}

$C_group_rex = qr/ [({\[]
             (?: (?> [^()\[\]{}]+ ) | (??{ $C_group_rex }) )*
             [)}\]] /x;

# $C_arg: match a chunk in C without comma at toplevel (no comments),
# i.e. a single arg within an XS signature, such as
#   foo = ','
#
# DAPM 2024. This appears to match zero, one or more of:
#   a random collection of non-bracket/quote/comma chars (e.g, a word or
#        number or 'int *foo' etc), or
#   a balanced(ish) nested brackets, or
#   a "string literal", or
#   a 'c' char literal
# So (I guess), it captures the next item in a function signature

$C_arg = qr/ (?: (?> [^()\[\]{},"']+ )
       |   (??{ $C_group_rex })
       |   " (?: (?> [^\\"]+ )
         |   \\.
         )* "        # String literal
              |   ' (?: (?> [^\\']+ ) | \\. )* ' # Char literal
       )* /xs;


sub parse {
    my __PACKAGE__                   $self = shift;
    my ExtUtils::ParseXS             $pxs  = shift;
    my ExtUtils::ParseXS::Node::xsub $xsub = shift;
    my $params_text                        = shift;

    $self->SUPER::parse($pxs); # set file/line_no

    # remove line continuation chars (\)
    $params_text =~ s/\\\s*/ /g;
    $self->{params_text} = $params_text;

    my @param_texts;
    my $opt_args = 0; # how many params with default values seen
    my $nargs    = 0; # how many args are expected

    # First, split signature into separate parameters

    if ($params_text =~ /\S/) {
        my $sig_c = "$params_text ,";
        use re 'eval'; # needed for 5.16.0 and earlier
        my $can_use_regex = ($sig_c =~ /^( (??{ $C_arg }) , )* $ /x);
        no re 'eval';

        if ($can_use_regex) {
            # If the parameters are capable of being split by using the
            # fancy regex, do so. This splits the params on commas, but
            # can handle things like foo(a = ",", b)
            use re 'eval';
            @param_texts = ($sig_c =~ /\G ( (??{ $C_arg }) ) , /xg);
        }
        else {
            # This is the fallback parameter-splitting path for when the
            # $C_arg regex doesn't work. This code path should ideally
            # never be reached, and indicates a design weakness in $C_arg.
            @param_texts = split(/\s*,\s*/, $params_text);
            Warn($pxs,   "Warning: cannot parse parameter list "
                       . "'$params_text', fallback to split");
        }
    }
    else {
        @param_texts = ();
    }

    # C++ methods get a fake object/class param at the start.
    # This affects arg numbering.
    if (defined($xsub->{decl}{class})) {
        my ($var, $type) =
            (   $xsub->{decl}{return_type}{static}
             or $xsub->{decl}{name} eq 'new'
            )
                ? ('CLASS', "char *")
                : ('THIS',    ($xsub->{decl}{is_const} ? "const " : "")
                            . "$xsub->{decl}{class} *");

        my ExtUtils::ParseXS::Node::Param $param
                = ExtUtils::ParseXS::Node::Param->new( {
                        var          => $var,
                        type         => $type,
                        is_synthetic => 1,
                        arg_num      => ++$nargs,
                    });
        push @{$self->{kids}}, $param;
        $self->{names}{$var} = $param;
    }

    # For non-void return types, add a fake RETVAL parameter. This triggers
    # the emitting of an 'int RETVAL;' declaration or similar, and (e.g. if
    # later flagged as in_output), triggers the emitting of code to return
    # RETVAL's value.
    #
    # Note that a RETVAL param can be in three main states:
    #
    # fully-synthetic  What is being created here. RETVAL hasn't appeared
    #                  in a signature or INPUT.
    #
    # semi-real        Same as fully-synthetic, but with a defined arg_num,
    #                  and with an updated position within
    #                  @{$self->{kids}}.  A RETVAL has appeared in the
    #                  signature, but without a type yet specified, so it
    #                  continues to use $xsub->{decl}{return_type}{type}.
    #
    # real             is_synthetic, no_init flags turned off. Its type
    #                  comes from the sig or INPUT line. This is just a
    #                  normal parameter now.

    if ($xsub->{decl}{return_type}{type} ne 'void') {
        my ExtUtils::ParseXS::Node::Param $param =
            ExtUtils::ParseXS::Node::Param->new( {
                var          => 'RETVAL',
                type         => $xsub->{decl}{return_type}{type},
                no_init      => 1, # just declare the var, don't initialise it
                is_synthetic => 1,
            } );

        push @{$self->{kids}}, $param;
        $self->{names}{RETVAL} = $param;
    }

    for my $param_text (@param_texts) {
        # Parse each parameter.

        $param_text =~ s/^\s+//;
        $param_text =~ s/\s+$//;

        # Process ellipsis (...)

        $pxs->blurt("Error: further XSUB parameter seen after ellipsis (...)")
            if $self->{seen_ellipsis};

        if ($param_text eq '...') {
            $self->{seen_ellipsis} = 1;
            next;
        }

        my $param = ExtUtils::ParseXS::Node::Param->new();
        $param->parse($pxs, $self, $param_text)
            or next;

        push @{$self->{kids}}, $param;
        $self->{names}{$param->{var}} = $param unless $param->{var} eq 'SV *';
        $opt_args++ if defined $param->{default};
        # Give the param a number if it will consume one of the passed args
        $param->{arg_num} = ++$nargs
            unless (  defined $param->{in_out} && $param->{in_out} eq "OUTLIST"
                    or $param->{is_length})

    } # for (@param_texts)

    $self->{nargs}    = $nargs;
    $self->{min_args} = $nargs - $opt_args;

    # for each parameter of the form 'length(foo)', mark the corresponding
    # 'foo' parameter as 'has_length', or error out if foo not found.
    for my $param (@{$self->{kids}}) {
        next unless $param->{is_length};
        my $name = $param->{len_name};
        if (exists $self->{names}{$name}) {
            $self->{names}{$name}{has_length} = 1;
        }
        else {
            $pxs->blurt("Error: length() on non-parameter '$name'");
        }
    }

    1;
}


# Return a string to be used in "usage: .." error messages.

sub usage_string {
    my __PACKAGE__ $self = shift;

    my @args = map  {
                          $_->{var}
                        . (defined $_->{default_usage}
                            ?$_->{default_usage}
                            : ''
                          )
                    }
               grep {
                        defined $_->{arg_num},
                    }
               @{$self->{kids}};

    push @args, '...' if $self->{seen_ellipsis};
    return join ', ', @args;
}


# $self->C_func_signature():
#
# return two arrays
# the first contains the arguments to pass to an autocall C
# function, e.g. ['a', '&b', 'c'];
# the second contains the types of those args, for use in declaring
# a function pointer type, e.g. ['int', 'char*', 'long'].

sub C_func_signature {
    my __PACKAGE__       $self = shift;
    my ExtUtils::ParseXS $pxs  = shift;

    my @args;
    my @types;
    for my $param (@{$self->{kids}}) {
        next if    $param->{is_synthetic} # THIS/CLASS/RETVAL
                   # if a synthetic RETVAL has acquired an arg_num, then
                   # it's appeared in the signature (although without a
                   # type) and has become semi-real.
                && !($param->{var} eq 'RETVAL' && defined($param->{arg_num}));

        if ($param->{is_length}) {
            push @args, "XSauto_length_of_$param->{len_name}";
            push @types, $param->{type};
            next;
        }

        if ($param->{var} eq 'SV *') {
            #backcompat placeholder
            $pxs->blurt("Error: parameter 'SV *' not valid as a C argument");
            next;
        }

        my $io = $param->{in_out};
        $io = '' unless defined $io;

        # Ignore fake/alien stuff, except an OUTLIST arg, which
        # isn't passed from perl (so no arg_num), but *is* passed to
        # the C function and then back to perl.
        next unless defined $param->{arg_num} or $io eq 'OUTLIST';

        my $a = $param->{var};
        $a = "&$a" if $param->{is_addr} or $io =~ /OUT/;
        push @args, $a;
        my $t = $param->{type};
        push @types, defined $t ? $t : 'void*';
    }

    return \@args, \@types;
}


# $self->proto_string():
#
# return a string containing the perl prototype string for this XSUB,
# e.g. '$$;$$@'.

sub proto_string {
    my __PACKAGE__ $self = shift;

    # Generate a prototype entry for each param that's bound to a real
    # arg. Use '$' unless the typemap for that param has specified an
    # overridden entry.
    my @p = map  defined $_->{proto} ? $_->{proto} : '$',
            grep defined $_->{arg_num} && $_->{arg_num} > 0,
            @{$self->{kids}};

    my @sep = (';'); # separator between required and optional args
    my $min = $self->{min_args};
    if ($min < $self->{nargs}) {
        # has some default vals
        splice (@p, $min, 0, ';');
        @sep = (); # separator already added
    }
    push @p, @sep, '@' if $self->{seen_ellipsis};  # '...'
    return join '', @p;
}


# ======================================================================

package ExtUtils::ParseXS::Node::xbody;

# This node holds all the foo_part nodes which make up the body of an
# XSUB. Note that in the presence of CASE: keywords, an XSUB may have
# multiple xbodys, one per CASE.
# This node doesn't contain the signature, and nor is it responsible
# for emitting the code for the closing part of an XSUB e.g. the
# XSRETURN(N); there is only one of those per XSUB, so is handled by a
# higher-level node.

BEGIN { $build_subclass->(
    'ioparams', # Params object: per-body copy of params which accumulate
                # extra info from any INPUT and OUTPUT sections (which can
                # vary between different CASEs)

    # Node objects representing the various parts of an xbody. These
    # are aliases of the same objects in @{$self->{kids}} for easier
    # access.
    'input_part',
    'init_part',
    'code_part',
    'output_part',
    'cleanup_part',

    # Misc parse state

    'seen_RETVAL_in_CODE',   # Bool: have seen 'RETVAL' within a CODE block
    'seen_autocall',         # Bool: this xbody has an autocall node
    'OUTPUT_SETMAGIC_state', # Bool: most recent value of SETMAGIC in an
                             #       OUTPUT section.

)};


sub parse {
    my __PACKAGE__                   $self  = shift;
    my ExtUtils::ParseXS             $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub $xsub  = shift;

    $self->SUPER::parse($pxs); # set file/line_no

    {
        # Make a per-xbody copy of the Params object, which will
        # accumulate any extra info from (per-CASE) INPUT and OUTPUT
        # sections.

        my $orig = $xsub->{decl}{params};

        # make a shallow copy
        my $ioparams = ExtUtils::ParseXS::Node::Params->new($orig);

        # now duplicate (deep copy) any Param objects and regenerate a new
        # names-mapping hash

        $ioparams->{kids} = [];
        $ioparams->{names}  = {};

        for my $op (@{$orig->{kids}}) {
            my $p  = ExtUtils::ParseXS::Node::IO_Param->new($op);
            # don't copy the current proto state (from the most recent
            # CASE) into the new CASE.
            undef $p->{proto};
            push @{$ioparams->{kids}}, $p;
            $ioparams->{names}{$p->{var}} = $p;
        }

        $self->{ioparams} = $ioparams;
    }

    # by default, OUTPUT entries have SETMAGIC: ENABLE
    $self->{OUTPUT_SETMAGIC_state} = 1;

    for my $part (qw(input_part init_part code_part output_part cleanup_part)) {
        my $kid = "ExtUtils::ParseXS::Node::$part"->new();
        if ($kid->parse($pxs, $xsub, $self)) {
            push @{$self->{kids}}, $kid;
            $self->{$part} = $kid;
        }
    }

    1;
}


sub as_code {
    my __PACKAGE__                   $self  = shift;
    my ExtUtils::ParseXS             $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub $xsub  = shift;

    # Emit opening brace. With cmd-line switch "-except", prefix it with 'TRY'
    print   +($pxs->{config_allow_exceptions} ? ' TRY' : '')
          . "    $open_brace\n";

    if ($self->{kids}) {
        $_->as_code($pxs, $xsub, $self) for @{$self->{kids}};
    }

    # ----------------------------------------------------------------
    # Emit trailers for the body of the XSUB
    # ----------------------------------------------------------------

    if ($xsub->{SCOPE_enabled}) {
        # the matching opens were emitted in input_part->as_code()
        print "      $close_brace\n";
        # PPCODE->as_code emits its own LEAVE and return, so this
        # line would never be reached.
        print "      LEAVE;\n" unless $xsub->{seen_PPCODE};
    }

    # matches the $open_brace at the start of this function
    print "    $close_brace\n";

    print $self->Q(<<"EOF") if $pxs->{config_allow_exceptions};
      |    BEGHANDLERS
      |    CATCHALL
      |    sprintf(errbuf, "%s: %s\\tpropagated", Xname, Xreason);
      |    ENDHANDLERS
EOF

}


# ======================================================================

package ExtUtils::ParseXS::Node::input_part;

BEGIN { $build_subclass->(

    # Str: used during code generation:
    # a multi-line string containing lines of code to be emitted *after*
    # all INPUT and PREINIT keywords have been processed.
    'deferred_code_lines',
)};


sub parse {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    $self->SUPER::parse($pxs); # set file/line_no

    # Process any implicit INPUT section.
    {
        my $input = ExtUtils::ParseXS::Node::INPUT->new();
        if (   $input->parse($pxs, $xsub, $xbody)
            && $input->{kids}
            && @{$input->{kids}})
        {
            $input->{implicit} = 1;
            push @{$self->{kids}}, $input;
        }
    }

    # Repeatedly look for INPUT or similar or generic keywords,
    # parse the text following them, and add any resultant nodes
    # as kids to the current node.
    $self->parse_keywords(
            $pxs, $xsub, $xbody,
            undef,  # implies process as many keywords as possible

              "C_ARGS|INPUT|INTERFACE_MACRO|PREINIT|SCOPE|"
            . $ExtUtils::ParseXS::Constants::generic_xsub_keywords_alt,
        );

    # For each param, look up its INPUT typemap information now (at parse
    # time) and save the results for use later in as_input_code().

    for my $ioparam (@{$xbody->{ioparams}{kids}}) {
        # might be placeholder param which doesn't get emitted
        next unless defined $ioparam->{type};
        $ioparam->{input_typemap_vals} =
            [ $ioparam->lookup_input_typemap($pxs, $xsub, $xbody) ];
    }

    # Now that the type of each param is finalised, calculate its
    # overridden prototype character, if any.
    #
    # Note that the type of a param can change during parsing, so when to
    # call this method is significant. In particular:
    # - THIS's type may be set provisionally based on the XSUB's package,
    #   then updated if it appears as a parameter or on an INPUT line.
    # - typemaps can be overridden using the TYPEMAP keyword, so
    #   it's possible the typemap->proto() method will return something
    #   different by the time the proto field is used to emit boot code.
    # - params can have different types (and thus typemap entries and
    #   proto chars) per CASE branch.
    # So we calculate the per-case/xbody params' proto values here, and
    # also use that value to update the per-XSUB value, warning if the
    # value changes.

    for my $ioparam (@{$xbody->{ioparams}{kids}}) {
        $ioparam->set_proto($pxs);
        my $ioproto = $ioparam->{proto};
        my $name    = $ioparam->{var};
        next unless defined $name;
        next unless $ioparam->{arg_num};

        my $param = $$xsub{decl}{params}{names}{$name};
        my $proto = $param->{proto};
        $ioproto = '$' unless defined $ioproto;
        if (defined $proto and $proto ne $ioproto) {
            $pxs->Warn("Warning: prototype for '$name' varies: '$proto' versus '$ioproto'");
        }
        $param->{proto} = $ioproto;
    }

    1;
}


sub as_code {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    my $ioparams = $xbody->{ioparams};

    # Lines to be emitted after PREINIT/INPUT. This may get populated
    # by the as_code() methods we call of our kids.
    $self->{deferred_code_lines} = "";

    if ($self->{kids}) {
        $_->as_code($pxs, $xsub, $xbody) for @{$self->{kids}};
    }

    # The matching closes will be emitted in xbody->as_code()
    print $self->Q(<<"EOF") if $xsub->{SCOPE_enabled};
        |      ENTER;
        |      $open_brace
EOF

    # Emit any 'char * CLASS' or 'Foo::Bar *THIS' declaration if needed

    for my $ioparam (grep $_->{is_synthetic}, @{$ioparams->{kids}}) {
        $ioparam->as_input_code($pxs, $xsub, $xbody);
    }

    # Recent code emits a dXSTARG in a tighter scope and under
    # additional circumstances, but some XS code relies on TARG
    # having been declared. So continue to declare it early under
    # the original circumstances.
    if ($xsub->{decl}{return_type}{use_early_targ}) {
        print "\tdXSTARG;\n";
    }

    # Emit declaration/init code for any parameters which were
    # declared with a type or length(foo). Do the length() ones first.

    for my $ioparam (
            grep $_->{is_ansi},
                (
                    grep(  $_->{is_length}, @{$ioparams->{kids}} ),
                    grep(! $_->{is_length}, @{$ioparams->{kids}} ),
                )
    )

    {
        $ioparam->as_input_code($pxs, $xsub, $xbody);
    }

    # ----------------------------------------------------------------
    # All C variable declarations have now been emitted. It's now time
    # to emit any code which goes before the main body (i.e. the CODE:
    # etc or the implicit call to the wrapped function).
    # ----------------------------------------------------------------

    # Emit any code which has been deferred until all declarations
    # have been done. This is typically INPUT typemaps which don't
    # start with a simple '$var =' and so would not have been emitted
    # at the variable declaration stage.
    print $self->{deferred_code_lines};
}


# ======================================================================

package ExtUtils::ParseXS::Node::init_part;

BEGIN { $build_subclass->(
)};


sub parse {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    $self->SUPER::parse($pxs); # set file/line_no

    # Repeatedly look for INIT or generic keywords,
    # parse the text following them, and add any resultant nodes
    # as kids to the current node.
    $self->parse_keywords(
            $pxs, $xsub, $xbody,
            undef,  # implies process as many keywords as possible

              "C_ARGS|INIT|INTERFACE|INTERFACE_MACRO|"
            . $ExtUtils::ParseXS::Constants::generic_xsub_keywords_alt,
        );

    1;
}


sub as_code {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    if ($self->{kids}) {
        $_->as_code($pxs, $xsub, $xbody) for @{$self->{kids}};
    }
}


# ======================================================================

package ExtUtils::ParseXS::Node::code_part;

BEGIN { $build_subclass->(
)};


sub parse {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    $self->SUPER::parse($pxs); # set file/line_no

    # Look for a CODE/PPCODE/NOT_IMPLEMENTED_YET keyword; if found, add
    # the kid to the current node.
    return 1 if $self->parse_keywords(
                        $pxs, $xsub, $xbody,
                        1, # match at most one keyword
                        "CODE|PPCODE",
                        $keywords_flag_NOT_IMPLEMENTED_YET,
                    );

    # Didn't find a CODE keyword or similar, so auto-generate a call
    # to the same-named C library function.

    my $autocall = ExtUtils::ParseXS::Node::autocall->new();
    # mainly a NOOP, but sets line number etc and flags that autocall seen
    $autocall->parse($pxs, $xsub, $xbody)
        or return;
    push @{$self->{kids}}, $autocall;

    1;
}


sub as_code {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    if ($self->{kids}) {
        $_->as_code($pxs, $xsub, $xbody) for @{$self->{kids}};
    }
}


# ======================================================================

package ExtUtils::ParseXS::Node::output_part;

BEGIN { $build_subclass->(

    # State during code emitting

    'targ_used',       # Bool: the TARG has been allocated for this body,
                       # so is no longer available for use.

    'stack_was_reset', # Bool: An XSprePUSH was emitted, so return values
                       # should be PUSHed rather than just set.
)};


sub parse {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    $self->SUPER::parse($pxs); # set file/line_no

    # Repeatedly look for POSTCALL, OUTPUT or generic keywords,
    # parse the text following them, and add any resultant nodes
    # as kids to the current node.
    # XXX POSTCALL is documented to precede OUTPUT, but here we allow
    # them in any order and multiplicity.
    $self->parse_keywords(
            $pxs, $xsub, $xbody,
            undef,  # implies process as many keywords as possible
              "POSTCALL|OUTPUT|"
            . $ExtUtils::ParseXS::Constants::generic_xsub_keywords_alt,
        );

    # Work out whether a RETVAL SV will be returned. Note that this should
    # be consistent across CASEs; we warn elsewhere if CODE_sets_ST0 isn't
    # consistent.

    $xsub->{XSRETURN_count_basic} =
           (     $xsub->{CODE_sets_ST0}
             or  (    $xsub->{decl}{return_type}{type} ne "void"
                  && !$xsub->{decl}{return_type}{no_output})
            )
            ? 1 : 0;

    # For each param, look up its OUTPUT typemap information now (at parse
    # time) and save the results for use later in as_output_code_().

    for my $ioparam (@{$xbody->{ioparams}{kids}}) {
        # might be placeholder param which doesn't get emitted
        # XXXX next unless defined $ioparam->{type};

        next unless
            # XXX simplify all this
                (      defined $ioparam->{in_out}
                    && $ioparam->{in_out} =~ /OUT$/
                    && !$ioparam->{in_output}
                )
            ||

                (
                    $ioparam->{var} eq "RETVAL"
                 && (   $ioparam->{in_output}
                     or (     $xbody->{seen_autocall}
                          &&  $xsub->{decl}{return_type}{type} ne "void"
                          && !$xsub->{decl}{return_type}{no_output}
                        )
                    )
                )
            ||
                (
                        $ioparam->{in_output}
                     && $ioparam->{var} ne 'RETVAL'
                 )
        ;

        $ioparam->{output_typemap_vals} =
            [ $ioparam->lookup_output_typemap($pxs, $xsub, $xbody) ];
    }

    my $out_num = $xsub->{XSRETURN_count_basic};

    for my $ioparam (@{$xbody->{ioparams}{kids}}) {
        next unless   defined $ioparam->{in_out}
                   && $ioparam->{in_out} =~ /OUTLIST$/;
        $ioparam->{output_typemap_vals_outlist} =
            [ $ioparam->lookup_output_typemap($pxs, $xsub, $xbody, $out_num++) ];
    }

    1;
}


sub as_code {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    # TARG is available for use within this body.
    $self->{targ_used} = 0;

    # SP still pointing at top arg
    $self->{stack_was_reset} = 0;

    if ($self->{kids}) {
        $_->as_code($pxs, $xsub, $xbody) for @{$self->{kids}};
    }

    my $ioparams = $xbody->{ioparams};

    my $retval = $ioparams->{names}{RETVAL};

    # A CODE section using RETVAL must also have an OUTPUT entry
    if (        $xbody->{seen_RETVAL_in_CODE}
            and not ($retval && $retval->{in_output})
            and     $xsub->{decl}{return_type}{type} ne 'void')
    {
        $pxs->Warn(  "Warning: found a 'CODE' section which seems to be "
                   . "using 'RETVAL' but no 'OUTPUT' section.");
    }

    # Process any OUT vars: i.e. vars that are declared OUT in
    # the XSUB's signature rather than in an OUTPUT section.

    for my $param (
                    grep {
                               defined $_->{in_out}
                            && $_->{in_out} =~ /OUT$/
                            && !$_->{in_output}
                    }
                    @{$ioparams->{kids}})
    {
        $param->as_output_code($pxs, $xsub, $xbody);
    }

    my $basic = $xsub->{XSRETURN_count_basic};
    my $extra = $xsub->{XSRETURN_count_extra};

    if ($extra) {
        # If there are any OUTLIST vars to be returned, we reset SP to
        # the base of the stack frame and then PUSH any return values.
        print "\tXSprePUSH;\n";
        $self->{stack_was_reset} = 1;
    }

    # Extend the stack if we're going to return more values than were
    # passed to us: which would consist of the GV or CV on the stack
    # plus at least min_args at the time ENTERSUB was called.

    my $n = $basic + $extra;
    print "\tEXTEND(SP,$n);\n"
        if $n > $ioparams->{min_args} + 1;

    # All OUTPUT done; now handle an implicit or deferred RETVAL:
    # - OUTPUT_line::as_code() will have skipped/deferred any RETVAL line,
    # - non-void CODE-less XSUBs have an implicit 'OUTPUT: RETVAL'

    if (   ($retval && $retval->{in_output})
        or (    $xbody->{seen_autocall}
            &&  $xsub->{decl}{return_type}{type} ne "void"
            && !$xsub->{decl}{return_type}{no_output}
           )
        )
    {
        # emit a deferred RETVAL from OUTPUT or implicit RETVAL
        $retval->as_output_code($pxs, $xsub, $xbody);
    }

    # Now that RETVAL is on the stack, also push any OUTLIST vars too
    for my $param (grep {   defined $_->{in_out}
                         && $_->{in_out} =~ /OUTLIST$/
                        }
                        @{$ioparams->{kids}}
    ) {
        $param->as_output_code($pxs, $xsub, $xbody, $basic++);
    }
}


# ======================================================================

package ExtUtils::ParseXS::Node::cleanup_part;

BEGIN { $build_subclass->(
)};


sub parse {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    $self->SUPER::parse($pxs); # set file/line_no

    # Repeatedly look for CLEANUP or generic keywords,
    # parse the text following them, and add any resultant nodes
    # as kids to the current node.
    $self->parse_keywords(
            $pxs, $xsub, $xbody,
            undef,  # implies process as many keywords as possible
              "CLEANUP|"
            . $ExtUtils::ParseXS::Constants::generic_xsub_keywords_alt,
        );

    1;
}


sub as_code {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    if ($self->{kids}) {
        $_->as_code($pxs, $xsub, $xbody) for @{$self->{kids}};
    }
}


# ======================================================================

package ExtUtils::ParseXS::Node::oneline;

# Generic base class for keyword Nodes which consume only a single source
# line, such as 'SCOPE: ENABLE'.
# On entry, $self->lines[0] will be any text (on the same line) which
# follows the keyword.

BEGIN { $build_subclass->(
    'text',    # Str: any text following the keyword
)};


sub parse {
    my __PACKAGE__       $self = shift;
    my ExtUtils::ParseXS $pxs  = shift;

    $self->SUPER::parse($pxs); # set file/line_no
    my $s = shift @{$pxs->{line}};
    ExtUtils::ParseXS::Utilities::trim_whitespace($s);
    $self->{text} = $s;
    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::MODULE;

# Process a MODULE keyword, e.g.
#
# MODULE = Foo PACKAGE = Foo::Bar PREFIX = foo_

BEGIN { $build_subclass->(-parent => 'oneline',
    'module',   # Str
    'package',  # Str: may be ''
    'prefix',   # Str: may be ''
)};


sub parse {
    my __PACKAGE__       $self = shift;
    my ExtUtils::ParseXS $pxs  = shift;

    $self->SUPER::parse($pxs); # set file/line_no

    my $line = $self->{text};
    my ($module, $pkg, $prefix) = $line =~
                            /^
                                        MODULE  \s* = \s* ([\w:]+)
                                (?: \s+ PACKAGE \s* = \s* ([\w:]+))?
                                (?: \s+ PREFIX  \s* = \s* (\S+))?
                                \s*
                            $/x
        or $pxs->death("Error: unparseable MODULE line: '$line'");

    $self->{module} = $module;
    ($pxs->{MODULE_cname} = $module) =~ s/\W/_/g;

    $self->{package} = $pxs->{PACKAGE_name} = defined($pkg) ? $pkg : '';

    $self->{prefix} = $prefix = defined($prefix) ? $prefix : '';
    $pxs->{PREFIX_pattern} = quotemeta($prefix);

    ($pxs->{PACKAGE_C_name} = $pxs->{PACKAGE_name}) =~ tr/:/_/;

    $pxs->{PACKAGE_class} = $pxs->{PACKAGE_name};
    $pxs->{PACKAGE_class} .= "::" if $pxs->{PACKAGE_class} ne "";

    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::NOT_IMPLEMENTED_YET;

# Handle NOT_IMPLEMENTED_YET pseudo-keyword

BEGIN { $build_subclass->(-parent => 'oneline',
)};

sub as_code {
    my __PACKAGE__                   $self  = shift;
    my ExtUtils::ParseXS             $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub $xsub  = shift;

    print   "\n"
          . "\tPerl_croak(aTHX_ \"$xsub->{decl}{full_perl_name}: "
          . "not implemented yet\");\n";
}


# ======================================================================

package ExtUtils::ParseXS::Node::CASE;

# Process the 'CASE:' keyword

BEGIN { $build_subclass->(-parent => 'oneline',
    'cond',  # Str: the C code of the condition for the CASE, or ''
    'num',   # Int: which CASE number this is (starting at 1)
)};


sub parse {
    my __PACKAGE__       $self = shift;
    my ExtUtils::ParseXS $pxs  = shift;

    $self->SUPER::parse($pxs); # set file/line_no/text
    $self->{cond} = $self->{text};
    # Note that setting num, and consistency checking (like "else"
    # without "if") is done by the caller, Node::xsub.
    1;
}


sub as_code {
    my __PACKAGE__                   $self  = shift;
    my ExtUtils::ParseXS             $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub $xsub  = shift;

    my $cond = $self->{cond};
    $cond = " if ($cond)" if length $cond;
    print "   ", ($self->{num} > 1 ? " else" : ""), $cond, "\n";
    $_->as_code($pxs, $xsub) for @{$self->{kids}};
}


# ======================================================================

package ExtUtils::ParseXS::Node::autocall;

# Handle an empty XSUB body (i.e. no CODE or PPCODE)
# by auto-generating a call to a C library function of the same
# name

BEGIN { $build_subclass->(
    'args',  # Str: text to use for auto function call arguments
    'types', # Str: text to use for auto function type declaration
)};


sub parse {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    $self->SUPER::parse($pxs); # set file/line_no

    $xbody->{seen_autocall} = 1;

    my $ioparams  = $xbody->{ioparams};
    my ($args, $types);
    $args = $ioparams->{auto_function_sig_override}; # C_ARGS
    if (defined $args) {
        # Try to determine the C_ARGS types; for example, with
        #
        #    foo(short s, int i, long l)
        #      C_ARGS: s, l
        #
        # set $types to ['short', 'long']. May give the wrong results if
        # C_ARGS isn't just a simple list of parameter names
        for my $var (split /,/, $args) {
            $var =~ s/^\s+//;
            $var =~ s/\s+$//;
            my $param = $ioparams->{names}{$var};
            # 'void*' is a desperate guess if no such parameter
            push @$types, ($param && defined $param->{type})
                            ? $param->{type} : 'void*';
        }
        $self->{args}  = $args;
    }
    else {
        ($args, $types) = $ioparams->C_func_signature($pxs);
        $self->{args}  = join ', ', @$args;
    }

    unless ($pxs->{config_RetainCplusplusHierarchicalTypes}) {
        s/:/_/g for @$types;
    }
    $self->{types} = join ', ', @$types;

    1;
}


sub as_code {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    my $class = $xsub->{decl}{class};
    my $name = $xsub->{decl}{name};

    if (    defined $class
        and $name eq "DESTROY")
    {
        # Emit a default body for a C++ DESTROY method: "delete THIS;"
        print "\n\t";
        print "delete THIS;\n";

    }
    else {
        # Emit a default body: this will be a call to the function being
        # wrapped. Typically:
        #    RETVAL = foo(args);
        # with the function name being appropriately modified when it's
        # a C++ new() method etc.

        print "\n\t";

        my $ret_type = $xsub->{decl}{return_type}{type};
        if ($ret_type ne "void") {
            print "RETVAL = ";
        }

        if (defined $class) {
            if ($xsub->{decl}{return_type}{static}) {
                # it has a return type of 'static foo'
                if ($name eq 'new') {
                    $name = "$class";
                }
                else {
                    print "${class}::";
                }
            }
            else {
                if ($name eq 'new') {
                    $name .= " $class";
                }
                else {
                    print "THIS->";
                }
            }
        }

        # Handle "xsubpp -s=strip_prefix" hack
        my $strip = $pxs->{config_strip_c_func_prefix};
        $name =~ s/^\Q$strip//
            if defined $strip;

        if (   $xsub->{seen_INTERFACE}
            or $xsub->{seen_INTERFACE_MACRO})
        {
            $ret_type =~ s/:/_/g
                unless $pxs->{config_RetainCplusplusHierarchicalTypes};
            $name = "(($ret_type (*)($self->{types}))(XSFUNCTION))";
        }

        print "$name($self->{args});\n";

    }
}


# ======================================================================

package ExtUtils::ParseXS::Node::FALLBACK;

# Process the 'FALLBACK' keyword.
# Its main effect is to update $pxs->{map_package_to_fallback_string} with
# the fallback value for the current package. That is later used to plant
# boot code to set ${package}::() to a true/false/undef value.

BEGIN { $build_subclass->(-parent => 'oneline',
    'value', # Str: TRUE, FALSE or UNDEF
)};


sub parse {
    my __PACKAGE__       $self = shift;
    my ExtUtils::ParseXS $pxs  = shift;

    $self->SUPER::parse($pxs); # set file/line_no/text

    # The rest of the current line should contain either TRUE,
    # FALSE or UNDEF, but we also secretly allow 0 or 1 and lower/mixed
    # case.

    my $s = $self->{text};

    $s = 'TRUE'  if $s eq '1';
    $s = 'FALSE' if $s eq '0';
    $s = uc($s);

    $self->death("Error: FALLBACK: TRUE/FALSE/UNDEF")
        unless $s =~ /^(TRUE|FALSE|UNDEF)$/;

    $self->{value} = $s;
    $pxs->{map_package_to_fallback_string}{$pxs->{PACKAGE_name}} = $s;

    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::REQUIRE;

# Process the 'REQUIRE' keyword.

BEGIN { $build_subclass->(-parent => 'oneline',
    'version', # Str: the minimum version allowed, e.g.'1.23'
)};


sub parse {
    my __PACKAGE__       $self = shift;
    my ExtUtils::ParseXS $pxs  = shift;

    $self->SUPER::parse($pxs); # set file/line_no/text

    my $ver = $self->{text};

    $pxs->death("Error: REQUIRE expects a version number")
        unless length $ver;

    # check that the version number is of the form n.n
    $pxs->death("Error: REQUIRE: expected a number, got '$ver'")
        unless $ver =~ /^\d+(\.\d*)?/;

    my $got = $ExtUtils::ParseXS::VERSION;
    $pxs->death("Error: xsubpp $ver (or better) required--this is only $got.")
        unless $got >= $ver;

    $self->{version} = $ver;

    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::include;

# Common base class for the 'INCLUDE' and 'INCLUDE_COMMAND' keywords

BEGIN { $build_subclass->(-parent => 'oneline',
    'is_cmd',       # Bool: is INCLUDE_COMMAND
    'inc_filename', # Str:  the file/command to be included
    'old_filename', # Str:  the previous file
)};


sub parse {
    my __PACKAGE__       $self = shift;
    my ExtUtils::ParseXS $pxs  = shift;

    $self->SUPER::parse($pxs); # set file/line_no/text

    my $f      = $self->{text};
    my $is_cmd = $self->{is_cmd};

    if ($is_cmd) {
        $f = $self->QuoteArgs($f) if $^O eq 'VMS';

        $pxs->death("INCLUDE_COMMAND: command missing")
            unless length $f;

        $pxs->death("INCLUDE_COMMAND: pipes are illegal")
            if $f =~ /^\s*\|/ or $f =~ /\|\s*$/;
    }
    else {
        $pxs->death("INCLUDE: filename missing")
            unless length $f;

        $pxs->death("INCLUDE: output pipe is illegal")
            if $f =~ /^\s*\|/;

        # simple minded recursion detector
        $pxs->death("INCLUDE loop detected")
            if $pxs->{IncludedFiles}{$f};

        ++$pxs->{IncludedFiles}->{$f} unless $f =~ /\|\s*$/;

        if ($f =~ /\|\s*$/ && $f =~ /^\s*perl\s/) {
            $pxs->Warn(
                  "The INCLUDE directive with a command is discouraged."
                . " Use INCLUDE_COMMAND instead! In particular using 'perl'"
                . " in an 'INCLUDE: ... |' directive is not guaranteed to pick"
                . " up the correct perl. The INCLUDE_COMMAND directive allows"
                . " the use of \$^X as the currently running perl, see"
                . " 'perldoc perlxs' for details."
            );
        }
    }

    # Save the current file context.

    my @save_keys = qw(in_fh in_filename in_pathname
                       lastline lastline_no line line_no);
    my @saved =  @$pxs{@save_keys};

    my $isPipe = $is_cmd || $pxs->{in_filename} =~ /\|\s*$/;

    $pxs->{line}    = [];
    $pxs->{line_no} = [];

    # Open the new file / pipe

    $pxs->{in_fh} = Symbol::gensym();

    if ($is_cmd) {
        # Expand the special token '$^X' into the full path of the
        # currently running perl interpreter
        my $X = $pxs->_safe_quote($^X); # quotes if has spaces
        $f =~ s/^\s*\$\^X/$X/;

        open ($pxs->{in_fh}, "-|", $f)
            or $pxs->death(
                "Cannot run command '$f' to include its output: $!");
    }
    else {
        open($pxs->{in_fh}, $f)
            or $pxs->death("Cannot open '$f': $!");
    }

    $self->{old_filename} = $pxs->{in_filename};
    $self->{inc_filename} = $f;
    $pxs->{in_filename} = $f;

    my $path = $f;
    if ($is_cmd) {
        #$path =~ s/\"/\\"/g; # Fails? See CPAN RT #53938: MinGW Broken after 2.21
        $path =~ s/\\/\\\\/g; # Works according to reporter of #53938
    }
    else {
        $path = ($^O =~ /^mswin/i)
                      # See CPAN RT #61908: gcc doesn't like
                      # backslashes on win32?
                    ? "$pxs->{dir}/$path"
                    : File::Spec->catfile($pxs->{dir}, $path);
    }
    $pxs->{in_pathname} = $self->{file} = $path;

    # Prime the pump by reading the first non-blank line
    while (readline($pxs->{in_fh})) {
        last unless /^\s*$/;
    }

    $pxs->{lastline} = $_;
    chomp $pxs->{lastline};
    $pxs->{lastline_no} = $self->{line_no} = $.;

    # Parse included file

    my $cpp_scope = ExtUtils::ParseXS::Node::cpp_scope->new({
                        type   => 'include',
                        is_cmd =>  $self->{is_cmd},
                    });
    $cpp_scope->parse($pxs)
        or return;
    push @{$self->{kids}}, $cpp_scope;

    --$pxs->{IncludedFiles}->{$pxs->{in_filename}}
        unless $isPipe;

    close $pxs->{in_fh};

    # Restore the current file context.

    @$pxs{@save_keys} = @saved;

    if ($isPipe and $? ) {
        --$pxs->{lastline_no};
        print STDERR "Error reading from pipe '$self->{inc_filename}': $! in $pxs->{in_filename}, line $pxs->{lastline_no}\n" ;
        exit 1;
    }

    1;
}


sub as_code {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;

    my $comment = $self->{is_cmd}
        ?   "INCLUDE_COMMAND:  Including output of"
        :   "INCLUDE:  Including";

    $comment .= " '$self->{inc_filename}' from '$self->{old_filename}'";

    print $self->Q(<<"EOF");
        |
        |/* $comment */
        |
EOF

    $_->as_code($pxs) for @{$self->{kids}};

    print $self->Q(<<"EOF");
    |
    |/* INCLUDE: Returning to '$self->{old_filename}' from '$self->{inc_filename}' */
    |
EOF

}


# ======================================================================

package ExtUtils::ParseXS::Node::INCLUDE;

# Process the 'INCLUDE' keyword. Most processing is actually done by the
# parent 'include' class which handles INCLUDE_COMMAND too.

BEGIN { $build_subclass->(-parent => 'include',
)};


sub parse {
    my __PACKAGE__       $self = shift;
    my ExtUtils::ParseXS $pxs  = shift;

    $self->{is_cmd} = 0;
    $self->SUPER::parse($pxs); # main parsing done by Node::include
    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::INCLUDE_COMMAND;

# Process the 'INCLUDE_COMMAND' keyword. Most processing is actually done
# by the parent 'include' class which handles INCLUDE too.

BEGIN { $build_subclass->(-parent => 'include',
)};


sub parse {
    my __PACKAGE__       $self = shift;
    my ExtUtils::ParseXS $pxs  = shift;

    $self->{is_cmd} = 1;
    $self->SUPER::parse($pxs); # main parsing done by Node::include
    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::enable;

# Base class for keywords which accept ENABLE/DISABLE as an argument

BEGIN { $build_subclass->(-parent => 'oneline',
    'enable',  # Bool
)};


sub parse {
    my __PACKAGE__       $self = shift;
    my ExtUtils::ParseXS $pxs  = shift;

    $self->SUPER::parse($pxs); # set file/line_no, self->{text}
    my $s = $self->{text};

    my ($keyword) = ($self =~ /(\w+)=/); # final component of class name

    if ($keyword eq 'PROTOTYPES') {
        # For backwards compatibility, parsing the PROTOTYPES
        # keyword's value is very lax: in particular, anything that
        # didn't match 'ENABLE' (such as 'Enabled' or 'ENABLED') used to
        # be treated as valid but false. Continue to use this
        # interpretation for backcomp, but warn.

        unless ($s =~ /^ ((ENABLE|DISABLE) D? ;?) \s* $ /xi) {
            $pxs->death("Error: $keyword: ENABLE/DISABLE")
        }
        my ($value, $en_dis) = ($1, $2);
        $self->{enable} = $en_dis eq 'ENABLE' ? 1 : 0;
        unless ($value =~ /^(ENABLE|DISABLE)$/) {
            $pxs->Warn("Warning: invalid PROTOTYPES value '$value' interpreted as "
                . ($self->{enable} ? 'ENABLE' : 'DISABLE'));
        }
    }
    else {
        # SCOPE / VERSIONCHECK / EXPORT_XSUB_SYMBOLS
        $s =~ /^(ENABLE|DISABLE)\s*$/
            or $pxs->death("Error: $keyword: ENABLE/DISABLE");
        $self->{enable} = $1 eq 'ENABLE' ? 1 : 0;
    }

    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::EXPORT_XSUB_SYMBOLS;

# Handle EXPORT_XSUB_SYMBOLS keyword
#
# Note that this keyword can appear both inside of and outside of an
# XSUB; for the latter, it it is currently created as a temporary
# object where as_code() is called immediately after parse() and then
# the object is discarded.

BEGIN { $build_subclass->(-parent => 'enable',
)};


sub parse {
    my __PACKAGE__       $self = shift;
    my ExtUtils::ParseXS $pxs  = shift;

    $self->SUPER::parse($pxs); # set file/line_no, self->{enable}
    1;
}


sub as_code {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    my $xs_impl = $self->{enable} ? 'XS_EXTERNAL' : 'XS_INTERNAL';

    # Change the definition of XS_EUPXS, so that any subsequent
    # XS_EUPXS(fXS_Foo_foo) XSUB declarations will expand to
    # XS_EXTERNAL/XS_INTERNAL as appropriate

    print $self->Q(<<"EOF");
        |#undef XS_EUPXS
        |#if defined(PERL_EUPXS_ALWAYS_EXPORT)
        |#  define XS_EUPXS(name) XS_EXTERNAL(name)
        |#elif defined(PERL_EUPXS_NEVER_EXPORT)
        |#  define XS_EUPXS(name) XS_INTERNAL(name)
        |#else
        |#  define XS_EUPXS(name) $xs_impl(name)
        |#endif
EOF
}


# ======================================================================

package ExtUtils::ParseXS::Node::PROTOTYPES;

# Handle PROTOTYPES keyword
#
# Note that this keyword can appear both inside of and outside of an XSUB.

BEGIN { $build_subclass->(-parent => 'enable',
)};


sub parse {
    my __PACKAGE__       $self = shift;
    my ExtUtils::ParseXS $pxs  = shift;

    $self->SUPER::parse($pxs); # set file/line_no, self->{enable}
    $pxs->{PROTOTYPES_value} = $self->{enable};
    $pxs->{proto_behaviour_specified} = 1;
    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::SCOPE;

# Handle SCOPE keyword
#
# Note that this keyword can appear both inside of and outside of an XSUB.

BEGIN { $build_subclass->(-parent => 'enable',
)};


sub parse {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    $self->SUPER::parse($pxs); # set file/line_no, self->{enable}

    # $xsub not defined for file-scoped SCOPE
    if ($xsub) {
        $pxs->blurt("Error: only one SCOPE declaration allowed per XSUB")
            if $xsub->{seen_SCOPE};
        $xsub->{seen_SCOPE} = 1;
    }

    # Note that currently this parse method can be called either while
    # parsing an XSUB, or while processing file-scoped keywords
    # just before an XSUB declaration. So potentially set both types of
    # state.
    $xsub->{SCOPE_enabled}      = $self->{enable} if $xsub;
    $pxs->{file_SCOPE_enabled}  = $self->{enable};
    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::VERSIONCHECK;

# Handle VERSIONCHECK keyword
#
# Note that this keyword can appear both inside of and outside of an XSUB.

BEGIN { $build_subclass->(-parent => 'enable',
)};


sub parse {
    my __PACKAGE__       $self = shift;
    my ExtUtils::ParseXS $pxs  = shift;

    $self->SUPER::parse($pxs); # set file/line_no, self->{enable}
    $pxs->{VERSIONCHECK_value} = $self->{enable};
    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::multiline;

# Generic base class for keyword Nodes which can contain multiple lines,
# e.g. C code or other data: so anything from ALIAS to PPCODE.
# On entry, $self->lines[0] will be any text (on the same line) which
# follows the keyword.

BEGIN { $build_subclass->(
    'lines', # Array ref of all lines until the next keyword
)};


# Consume all the lines up until the next directive and store in @$lines.

sub parse {
    my __PACKAGE__       $self = shift;
    my ExtUtils::ParseXS $pxs  = shift;

    $self->SUPER::parse($pxs); # set file/line_no

    my @lines;

    # Consume lines until the next directive
    while(   @{$pxs->{line}}
          && $pxs->{line}[0] !~ /^$ExtUtils::ParseXS::BLOCK_regexp/o)
    {
        push @lines, shift @{$pxs->{line}};
    }

    $self->{lines} = \@lines;
    1;
}

# No as_code() method - we rely on the sub-classes for that


# ======================================================================

package ExtUtils::ParseXS::Node::multiline_merged;

# Generic base class for keyword Nodes which can contain multiple lines.
# It's the same is is parent class, :Node::multiline, except that in
# addition, leading blank lines are skipped and the remainder concatenated
# into a single line, 'text'.

BEGIN { $build_subclass->(-parent => 'multiline',
    'text', # Str: singe string containing all concatenated lines
)};


# Consume all the lines up until the next directive and store in
# @$lines, and in addition, concatenate and store in $text

sub parse {
    my __PACKAGE__       $self = shift;
    my ExtUtils::ParseXS $pxs  = shift;

    $self->SUPER::parse($pxs); # set file/line_no, read lines

    my @lines = @{$self->{lines}};
    shift @lines while @lines && $lines[0] !~ /\S/;
    # XXX ParseXS originally didn't include a trailing \n,
    # so we carry on doing the same.
    $self->{text} = join "\n", @lines;
    ExtUtils::ParseXS::Utilities::trim_whitespace($self->{text});
    1;
}

# No as_code() method - we rely on the sub-classes for that


# ======================================================================

package ExtUtils::ParseXS::Node::C_ARGS;

# Handle C_ARGS keyword

BEGIN { $build_subclass->(-parent => 'multiline_merged',
)};


sub parse {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    $self->SUPER::parse($pxs); # set file/line_no, get lines, set text
    $xbody->{ioparams}{auto_function_sig_override} = $self->{text};
    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::INTERFACE;

# Handle INTERFACE keyword

BEGIN { $build_subclass->(-parent => 'multiline_merged',
)};


sub parse {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    $self->SUPER::parse($pxs); # set file/line_no, get lines, set text
    $xsub->{seen_INTERFACE} = 1;

    my %map;

    foreach (split /[\s,]+/, $self->{text}) {
        my $short = $_;
        $short =~ s/^$pxs->{PREFIX_pattern}//;
        $map{$short} = $_;
        $xsub->{map_interface_name_short_to_original}{$short} = $_;
    }

    1;
}


sub as_code {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    my $macro = $xsub->{interface_macro};
    $macro = 'XSINTERFACE_FUNC' unless defined $macro;

    my $type = $xsub->{decl}{return_type}{type};
    $type =~ tr/:/_/
        unless $pxs->{config_RetainCplusplusHierarchicalTypes};
    print <<"EOF";
    XSFUNCTION = $macro($type,cv,XSANY.any_dptr);
EOF
}


# ======================================================================

package ExtUtils::ParseXS::Node::INTERFACE_MACRO;

# Handle INTERFACE_MACRO keyword

BEGIN { $build_subclass->(-parent => 'multiline_merged',
    'get_macro', # Str: name of macro to get interface
    'set_macro', # Str: name of macro to set interface
)};


sub parse {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    $self->SUPER::parse($pxs); # set file/line_no, get lines, set text

    $xsub->{seen_INTERFACE_MACRO} = 1;

    my $s = $self->{text};
    my ($m1, $m2);
    if ($s =~ /\s/) {        # two macros
        ($m1, $m2) = split ' ', $s;
    }
    else {
        # XXX rather than using a fake macro name which will probably
        # give a compile error later, we should really warn/die here?
        ($m1, $m2) = ($s, 'UNKNOWN_CVT');
    }

    $self->{get_macro} = $xsub->{interface_macro}     = $m1;
    $self->{set_macro} = $xsub->{interface_macro_set} = $m2;

    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::OVERLOAD;

# Handle OVERLOAD keyword

BEGIN { $build_subclass->(-parent => 'multiline_merged',
    'ops', # Hash ref of seen overloaded op names
)};

# Add all overload method names, like 'cmp', '<=>', etc, (possibly
# multiple ones per line) until the next keyword line, as 'seen' keys to
# the $xsub->{overload_name_seen} hash.

sub parse {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    $self->SUPER::parse($pxs); # set file/line_no, get lines, set text

    my $s = $self->{text};
    while ($s =~  s/^\s*([\w:"\\)\+\-\*\/\%\<\>\.\&\|\^\!\~\{\}\=]+)\s*//) {
        $self->{ops}{$1} = 1;
        $xsub->{overload_name_seen}{$1} = 1;
    }

    # Mark the current package as being overloaded
    $pxs->{map_overloaded_package_to_C_package}->{$xsub->{PACKAGE_name}}
        = $xsub->{PACKAGE_C_name};

    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::ATTRS;

# Handle ATTRS keyword

BEGIN { $build_subclass->(-parent => 'multiline',
)};


# Read each lines's worth of attributes into a string that is pushed
# to the $xsub->{attributes} array. Note that it doesn't matter that multiple
# space-separated attributes on the same line are stored as a single
# string; later, all the attribute lines are joined together into a single
# string to pass to apply_attrs_string().

sub parse {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    $self->SUPER::parse($pxs); # set file/line_no, get lines
    for (@{$self->{lines}}) {
        ExtUtils::ParseXS::Utilities::trim_whitespace($_);
        push @{$xsub->{attributes}}, $_;
    }
    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::PROTOTYPE;

# Handle PROTOTYPE keyword

BEGIN { $build_subclass->(-parent => 'multiline',
    'prototype', # Str: 0 (disable), 1 (enable), 2 ("") or "$$@" etc
)};


# PROTOTYPE: Process one or more lines of the form
#    DISABLE
#    ENABLE
#    $$@      # a literal prototype
#    <blank>  # an empty prototype - equivalent to foo() { ...}
#
# The last line takes precedence.
# XXX It's a design flaw that more than one line can be processed.

sub parse {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    $self->SUPER::parse($pxs); # set file/line_no, get lines

    my $proto;

    $pxs->death("Error: only one PROTOTYPE definition allowed per xsub")
        if $xsub->{seen_PROTOTYPE};
    $xsub->{seen_PROTOTYPE} = 1;

    for (@{$self->{lines}}) {
        next unless /\S/;
        ExtUtils::ParseXS::Utilities::trim_whitespace($_);

        if ($_ eq 'DISABLE') {
            $proto = 0;
        }
        elsif ($_ eq 'ENABLE') {
            $proto = 1;
        }
        else {
            s/\s+//g; # remove any whitespace
            $pxs->death("Error: invalid prototype '$_'")
                unless ExtUtils::ParseXS::Utilities::valid_proto_string($_);
            $proto = ExtUtils::ParseXS::Utilities::C_string($_);
        }
    }

    # If no prototype specified, then assume empty prototype ""
    $proto = 2 unless defined $proto;

    $self->{prototype} = $proto;
    $xsub->{prototype} = $proto;

    $pxs->{proto_behaviour_specified} = 1;
    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::codeblock;

# Base class for Nodes which contain lines of literal C code
# (such as PREINIT: and CODE:)

BEGIN { $build_subclass->(-parent => 'multiline',
)};


# No parse() method: we just use the inherited Node::multiline's one


# Emit the lines of code, skipping any initial blank lines,
# and possibly wrapping in '#line' directives.

sub as_code {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    my @lines = map "$_\n", @{$self->{lines}};

    my $n;

    # Ignore any text following the keyword on the same line.
    # XXX this quietly ignores any such text - really it should
    # warn, but not yet for backwards compatibility.
    $n++, shift @lines if @lines;

    # strip leading blank lines
    $n++, shift @lines while @lines && $lines[0] !~ /\S/;

    # Add a leading '#line' if needed.
    # The XSubPPtmp test is a bit of a hack - it skips synthetic blocks
    # added to boot etc which may not have line numbers.
    my $line0 = $lines[0];
    if (   $pxs->{config_WantLineNumbers}
        && ! (    defined $line0
               && (   $line0 =~ /^\s*#\s*line\b/
                   || $line0 =~ /^#if XSubPPtmp/
                  )
              )
    ) {
        unshift @lines,
                  "#line "
                . ($self->{line_no}  + $n)
                . " \""
                . ExtUtils::ParseXS::Utilities::escape_file_for_line_directive(
                        $self->{file})
                . "\"\n";
    }

    # Add a final "restoring" '#line'
    push @lines, 'ExtUtils::ParseXS::CountLines'->end_marker . "\n"
      if $pxs->{config_WantLineNumbers};

    print for @lines;
}


# ======================================================================

package ExtUtils::ParseXS::Node::CODE;

# Store the code lines associated with the CODE keyword

BEGIN { $build_subclass->(-parent => 'codeblock',
)};

sub parse {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    $self->SUPER::parse($pxs); # set file/line_no/lines

    # Check if the code block includes "RETVAL". This check is for later
    # use to warn if RETVAL is used but no OUTPUT block is present.
    # Ignore if its only being used in an 'ignore this var' situation.
    my $code = join "\n", @{$self->{lines}};
    $xbody->{seen_RETVAL_in_CODE} =
                    $code =~ /\bRETVAL\b/
                 && $code !~ /\b\QPERL_UNUSED_VAR(RETVAL)/;

    # Horrible 'void' return arg count hack.
    #
    # Until about 1996, xsubpp always emitted 'XSRETURN(1)', even for a
    # void XSUB. This was fixed for CODE-less void XSUBs simply by
    # actually honouring the 'void' type and emitting 'XSRETURN_EMPTY'
    # instead. However, for CODE blocks, the documentation had already
    # endorsed a coding style along the lines of
    #
    #    void
    #    foo(...)
    #       CODE:
    #          ST(0) = sv_newmortal();
    #
    # i.e. the XSUB returns an SV even when the return type is 'void'.
    # In 2024 there is still lots of code of this style out in the wild,
    # even in the distros bundled with perl.
    #
    # So honouring the void type here breaks lots of existing code. Thus
    # this hack specifically looks for: void XSUBs with a CODE block that
    # appears to put stuff on the stack via 'ST(n)=' or 'XST_m()', and if
    # so, emits 'XSRETURN(1)' rather than the 'XSRETURN_EMPTY' implied by
    # the 'void' return type.
    #
    # So set a flag which indicates that a CODE block sets ST(0). This
    # will be used later when deciding how/whether to emit EXTEND(n) and
    # XSRETURN(n).

    my $st0 =
             $code =~ m{  ( \b ST      \s* \( [^;]* = )
                        | ( \b XST_m\w+\s* \(         ) }x;

    $pxs->Warn("Warning: ST(0) isn't consistently set in every CASE's CODE block")
        if     defined $xsub->{CODE_sets_ST0}
            && $xsub->{CODE_sets_ST0} ne $st0;
    $xsub->{CODE_sets_ST0} = $st0;

    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::CLEANUP;

# Store the code lines associated with the CLEANUP: keyword

BEGIN { $build_subclass->(-parent => 'codeblock',
)};

# Currently all methods are just inherited.


# ======================================================================

package ExtUtils::ParseXS::Node::INIT;

# Store the code lines associated with the INIT: keyword

BEGIN { $build_subclass->(-parent => 'codeblock',
)};

# Currently all methods are just inherited.


# ======================================================================

package ExtUtils::ParseXS::Node::POSTCALL;

# Store the code lines associated with the POSTCALL: keyword

BEGIN { $build_subclass->(-parent => 'codeblock',
)};

# Currently all methods are just inherited.


# ======================================================================

package ExtUtils::ParseXS::Node::PPCODE;

# Store the code lines associated with the PPCODE keyword

BEGIN { $build_subclass->(-parent => 'codeblock',
)};

sub parse {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    $self->SUPER::parse($pxs); # set file/line_no/lines
    $xsub->{seen_PPCODE} = 1;
    $pxs->death("Error: PPCODE must be the last thing") if @{$pxs->{line}};
    1;
}


sub as_code {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    # Just emit the code block and then code to do PUTBACK and return.
    # The # user of PPCODE is supposed to have done all the return stack
    # manipulation themselves.
    # Note that PPCODE blocks often include a XSRETURN(1) or
    # similar, so any final code we emit after that is in danger of
    # triggering a "statement is unreachable" warning.

    $self->SUPER::as_code($pxs, $xsub, $xbody); # emit code block

    print "\tLEAVE;\n" if $xsub->{SCOPE_enabled};

    # Suppress "statement is unreachable" warning on HPUX
    print "#if defined(__HP_cc) || defined(__HP_aCC)\n",
          "#pragma diag_suppress 2111\n",
          "#endif\n"
        if $^O eq "hpux";

    print "\tPUTBACK;\n\treturn;\n";

    # Suppress "statement is unreachable" warning on HPUX
    print "#if defined(__HP_cc) || defined(__HP_aCC)\n",
          "#pragma diag_default 2111\n",
          "#endif\n"
        if $^O eq "hpux";
}


# ======================================================================

package ExtUtils::ParseXS::Node::PREINIT;

# Store the code lines associated with the PREINIT: keyword

BEGIN { $build_subclass->(-parent => 'codeblock',
)};

# Currently all methods are just inherited.


# ======================================================================

package ExtUtils::ParseXS::Node::keylines;

# Base class for keyword FOO nodes which have a FOO_line kid node for
# each line making up the keyword - such as OUTPUT etc.

BEGIN { $build_subclass->(
    'lines',   # Array ref of all lines until the next keyword
)};


# Process each line on and following the keyword line.
# For each line, create a FOO_line kid and call its parse() method.

sub parse {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;
    my $do_notimplemented                    = shift;

    $self->SUPER::parse($pxs); # set file/line_no

    # Consume and process lines until the next directive.
    while(   @{$pxs->{line}}
          && $pxs->{line}[0] !~ /^$ExtUtils::ParseXS::BLOCK_regexp/o)
    {
        if ($do_notimplemented) {
            # treat NOT_IMPLEMENTED_YET as another block separator, in
            # addition to $BLOCK_regexp.
            last if $pxs->{line}[0] =~ /^\s*NOT_IMPLEMENTED_YET/;
        }

        unless ($pxs->{line}[0] =~ /\S/) {  # skip blank lines
            shift @{$pxs->{line}};
            next;
        }

        push @{$self->{lines}}, $pxs->{line}[0];

        my $class = ref($self) . '_line';
        my $kid = $class->new();
        # Keep the current line in $self->{lines} for now so that the
        # parse() method below sees the right line number. We rely on that
        # method to actually pop the line.
        if ($kid->parse($pxs, $xsub, $xbody, $self)) {
            push @{$self->{kids}}, $kid;
        }
    }

    1;
}


# call as_code() on any kids which have that method

sub as_code {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    return unless $self->{kids};
    $_->as_code($pxs, $xsub, $xbody) for @{$self->{kids}};
}


# ======================================================================

package ExtUtils::ParseXS::Node::keyline;

# Base class for FOO_line nodes which have a FOO node as
# their parent.

BEGIN { $build_subclass->(
    'line',   # Str: text of current line
)};


# The two jobs of this parse method are to grab the next line, and also to
# set the right line number for any warning or error messages triggered by
# the current line. It is called as a SUPER by the parse() methods of its
# concrete subclasses.

sub parse {
    my __PACKAGE__       $self = shift;
    my ExtUtils::ParseXS $pxs  = shift;

    $self->SUPER::parse($pxs); # set file/line_no
    # By shifting *now*, the line above gets the correct line number of
    # this src line, while subsequent processing gives the right line
    # number for warnings etc, since the warn/err methods assume the line
    # being processed has already been popped.
    my $line = shift @{$pxs->{line}}; # line of text to be processed
    $self->{line} = $line;
    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::ALIAS;

# Handle ALIAS keyword

BEGIN { $build_subclass->(-parent => 'keylines',
    'aliases', # hashref of all alias => value pairs.
               # Populated by ALIAS_line::parse()
)};

sub parse {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    $xsub->{seen_ALIAS} = 1;
    $self->SUPER::parse($pxs, $xsub, $xbody);
}


# ======================================================================

package ExtUtils::ParseXS::Node::ALIAS_line;

# Handle one line from an ALIAS keyword block

BEGIN { $build_subclass->(-parent => 'keyline',
)};


# Parse one line from an ALIAS block
#
# Each line can have zero or more definitions, separated by white space.
# Each definition is of one of the two forms:
#
#      name =  value
#      name => other_name
#
#  where 'value' is a positive integer (or C macro) and the names are
#  simple or qualified perl function names. E.g.
#
#     foo = 1   Bar::foo = 2   Bar::baz => Bar::foo
#
# The RHS of a '=>' is the name of an existing alias
#
# The results are added to a hash in the parent ALIAS node, as well as
# to a couple of per-xsub hashes which accumulate the results across
# possibly multiple ALIAS keywords.
#
# Updates:
#   $parent->{aliases}{$alias} = $value;
#   $xsub->{map_alias_name_to_value}{$alias} = $value;
#   $xsub->{map_alias_value_to_name_seen_hash}{$value}{$alias}++;


sub parse {
    my __PACKAGE__                    $self   = shift;
    my ExtUtils::ParseXS              $pxs    = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub   = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody  = shift;
    my ExtUtils::ParseXS::Node::ALIAS $parent = shift; # parent ALIAS node

    $self->SUPER::parse($pxs); # set file/line_no/line
    my $line = $self->{line};  # line of text to be processed

    ExtUtils::ParseXS::Utilities::trim_whitespace($line);
    # XXX this skip doesn't make sense - we've already confirmed
    # line has non-whitespace  with the /\S/; so we just skip if the
    # line is "0" ?
    return unless $line;

    my $orig = $line; # keep full line for error messages

    # we use this later for symbolic aliases
    my $fname = $pxs->{PACKAGE_class} . $xsub->{decl}{name};

    # chop out and process one alias entry from $line

    while ($line =~ s/^\s*([\w:]+)\s*=(>?)\s*([\w:]+)\s*//) {
        my ($alias, $is_symbolic, $value) = ($1, $2, $3);
        my $orig_alias = $alias;

        $pxs->blurt(  "Error: in alias definition for '$alias' the value "
                    . "may not contain ':' unless it is symbolic.")
                if !$is_symbolic and $value=~/:/;

        # check for optional package definition in the alias
        $alias = $pxs->{PACKAGE_class} . $alias if $alias !~ /::/;

        if ($is_symbolic) {
            my $orig_value = $value;
            $value = $pxs->{PACKAGE_class} . $value if $value !~ /::/;
            if (defined $xsub->{map_alias_name_to_value}{$value}) {
                $value = $xsub->{map_alias_name_to_value}{$value};
            } elsif ($value eq $fname) {
                $value = 0;
            } else {
                $pxs->blurt(  "Error: unknown alias '$value' in "
                            . "symbolic definition for '$orig_alias'");
            }
        }

        # check for duplicate alias name & duplicate value
        my $prev_value = $xsub->{map_alias_name_to_value}{$alias};
        if (defined $prev_value) {
            if ($prev_value eq $value) {
                $pxs->Warn("Warning: ignoring duplicate alias '$orig_alias'")
            } else {
                $pxs->Warn(  "Warning: conflicting duplicate alias "
                           . "'$orig_alias' changes definition "
                           . "from '$prev_value' to '$value'");
                delete $xsub->{map_alias_value_to_name_seen_hash}
                            ->{$prev_value}{$alias};
            }
        }

        # Check and see if this alias results in two aliases having the same
        # value, we only check non-symbolic definitions as the whole point of
        # symbolic definitions is to say we want to duplicate the value and
        # it is NOT a mistake.
        unless ($is_symbolic) {
            my @keys= sort keys %{$xsub->
                          {map_alias_value_to_name_seen_hash}->{$value}||{}};
            # deal with an alias of 0, which might not be in the aliases
            # dataset yet as 0 is the default for the base function ($fname)
            push @keys, $fname
                if $value eq "0" and
                    !defined $xsub->{map_alias_name_to_value}{$fname};
            if (@keys and $pxs->{config_author_warnings}) {
                # We do not warn about value collisions unless author_warnings
                # are enabled. They aren't helpful to a module consumer, only
                # the module author.
                @keys= map { "'$_'" }
                                map { my $copy= $_;
                                            $copy=~s/^$pxs->{PACKAGE_class}//;
                                            $copy
                                        } @keys;
                $pxs->WarnHint(
                                    "Warning: aliases '$orig_alias' and "
                                    . join(", ", @keys)
                                    . " have identical values of $value"
                                    . ( $value eq "0"
                                            ? " - the base function"
                                            : "" ),
                                    !$xsub->{alias_clash_hinted}++
                                    ?   "If this is deliberate use a "
                                      . "symbolic alias instead."
                                    : undef
                );
            }
        }

        $parent->{aliases}{$alias} = $value;
        $xsub->{map_alias_name_to_value}->{$alias} = $value;
        $xsub->{map_alias_value_to_name_seen_hash}{$value}{$alias}++;
    }

    $pxs->blurt("Error: cannot parse ALIAS definitions from '$orig'")
        if $line;

    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::INPUT;

# Handle an explicit INPUT: block, or any implicit INPUT
# block which can follow an xsub signature or CASE keyword.

BEGIN { $build_subclass->(-parent => 'keylines',
    'implicit',   # Bool: this is an INPUT section at the start of the
                  #       XSUB/CASE, without an explicit 'INPUT' keyword
)};

# The inherited parse() method will call INPUT_line->parse() for each line


sub parse {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    # Call the SUPER parse method, which will call INPUT_line->parse()
    # for each INPUT line. The '1' bool arg indicates to treat
    # NOT_IMPLEMENTED_YET as another block separator, in addition to
    # $BLOCK_regexp.
    $self->SUPER::parse($pxs, $xsub, $xbody, 1);

    1;
}


# ======================================================================

package ExtUtils::ParseXS::Node::INPUT_line;

# Handle one line from an INPUT keyword block

BEGIN { $build_subclass->(-parent => 'keyline',
    'ioparam', # The IO_Param object associated with this INPUT line.

               # The parsed components of this INPUT line:
    'type',    # Str:  char *
    'is_addr', # Bool:         &
    'name',    # Str:           foo
    'init_op', # Str:                =
    'init',    # Str:                  SvIv($arg)
)};


# Parse one line in an INPUT block. This method does two main things:
#
# It parses the line and stores its components in the fields of the
# INPUT_line object (which aren't further used for parsing or code
# generation)
#
# It also uses those values to create/update the IO_Param object
# associated with this variable. For example with
#
#    void
#    foo(a = 0)
#       int a
#
# a IO_Param object will already have been created with the name 'a' and
# default value '0' when the signature was parsed. Parsing the 'int a'
# line will set the INPUT_line object's fields to (type => 'int',
# name => 'a'), while the IO_Param object will have its type field set to
# 'int'. The INPUT_line object also stores a ref to the IO_Param object.
#

sub parse {
    my __PACKAGE__                    $self   = shift;
    my ExtUtils::ParseXS              $pxs    = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub   = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody  = shift;
    my ExtUtils::ParseXS::Node::INPUT $parent = shift; # parent INPUT node

    $self->SUPER::parse($pxs); # set file/line_no/line
    my $line = $self->{line};  # line of text to be processed

    ExtUtils::ParseXS::Utilities::trim_whitespace($line);

    # remove any trailing semicolon, except for initialisations
    $line =~ s/\s*;$//g unless $line =~ /[=;+].*\S/;

    # Extract optional initialisation code (which overrides the
    # normal typemap), such as 'int foo = ($type)SvIV($arg)'
    my $var_init = '';
    my $init_op;
    ($init_op, $var_init) = ($1, $2) if $line =~ s/\s* ([=;+]) \s* (.*) $//xs;

    $line =~ s/\s+/ /g;

    # Split 'char * &foo'  into  ('char *', '&', 'foo')
    # skip to next INPUT line if not valid.
    #
    # Note that this pattern has a very liberal sense of what is "valid",
    # since we don't fully parse C types.  For example:
    #
    #    int foo(a)
    #        int a XYZ
    #
    # would be interpreted as an "alien" (i.e. not in the signature)
    # variable called "XYZ", with a type of "int a". And because it's
    # alien the initialiser is skipped, so 'int a' is never looked up in
    # a typemap, so we don't detect anything wrong. Later on, the C
    # compiler is likely to trip over on the emitted declaration
    # however:
    #     int a XYZ;

    my ($var_type, $var_addr, $var_name) =
            $line =~ /^
                ( .*? [^&\s] )        # type
                \s*
                (\&?)                 # addr
                \s* \b
                (\w+ | length\(\w+\)) # name or length(name)
                $
            /xs
        or do {
            $pxs->blurt("Error: invalid parameter declaration '$self->{line}'");
            return;
        };

    # length(s) is only allowed in the XSUB's signature.
    if ($var_name =~ /^length\((\w+)\)$/) {
        $pxs->blurt("Error: length() not permitted in INPUT section");
        return;
    }

    my ($var_num, $is_alien);

    my $ioparams = $xbody->{ioparams};

    my ExtUtils::ParseXS::Node::IO_Param $ioparam =
                $ioparams->{names}{$var_name};

    if (defined $ioparam) {
        # The var appeared in the signature too.

        # Check for duplicate definitions of a particular parameter name.
        # This can be either because it has appeared in multiple INPUT
        # lines, or because the type was already defined in the signature,
        # and thus shouldn't be defined again. The exception to this are
        # synthetic params like THIS, which are assigned a provisional type
        # which can be overridden.
        if (   $ioparam->{in_input}
            or (!$ioparam->{is_synthetic} and defined $ioparam->{type})
        ) {
            $pxs->blurt(
                "Error: duplicate definition of parameter '$var_name' ignored");
            return;
        }

        if ($var_name eq 'RETVAL' and $ioparam->{is_synthetic}) {
            # Convert a synthetic RETVAL into a real parameter
            delete $ioparam->{is_synthetic};
            delete $ioparam->{no_init};
            if (! defined $ioparam->{arg_num}) {
                # if has arg_num, RETVAL has appeared in signature but with no
                # type, and has already been moved to the correct position;
                # otherwise, it's an alien var that didn't appear in the
                # signature; move to the correct position.
                @{$ioparams->{kids}} =
                            grep $_ != $ioparam, @{$ioparams->{kids}};
                push @{$ioparams->{kids}}, $ioparam;
                $is_alien            = 1;
                $ioparam->{is_alien} = 1;
            }
        }

        $ioparam->{in_input} = 1;
        $var_num = $ioparam->{arg_num};
    }
    else {
        # The var is in an INPUT line, but not in signature. Treat it as a
        # general var declaration (which really should have been in a
        # PREINIT section). Legal but nasty: flag is as 'alien'
        $is_alien = 1;
        $ioparam = ExtUtils::ParseXS::Node::IO_Param->new({
                    var      => $var_name,
                    is_alien => 1,
                });

        push @{$ioparams->{kids}}, $ioparam;
        $ioparams->{names}{$var_name} = $ioparam;
    }

    # Parse the initialisation part of the INPUT line (if any)

    my ($init, $defer);
    my $no_init = $ioparam->{no_init}; # may have had OUT in signature

    if (!$no_init && defined $init_op) {
        # Use the init code based on overridden $var_init, which was
        # preceded by /[=;+]/ which has been extracted into $init_op

        if (    $init_op =~ /^[=;]$/
                and $var_init =~ /^NO_INIT\s*;?\s*$/
        ) {
            # NO_INIT: skip initialisation
            $no_init = 1;
        }
        elsif ($init_op  eq '=') {
            # Overridden typemap, such as '= ($type)SvUV($arg)'
            $var_init =~ s/;\s*$//;
            $init = $var_init,
        }
        else {
            # "; extra code" or "+ extra code" :
            # append the extra code (after passing through eval) after all the
            # INPUT and PREINIT blocks have been processed, indirectly using
            # the $input_part->{deferred_code_lines} mechanism.
            # In addition, for '+', also generate the normal initialisation
            # code from the standard typemap - assuming that it's a real
            # parameter that appears in the signature as well as the INPUT
            # line.
            $no_init = !($init_op eq '+' && !$is_alien);
            # But in either case, add the deferred code
            $defer = $var_init;
        }
    }
    else {
        # no initialiser: emit var and init code based on typemap entry,
        # unless: it's alien (so no stack arg to bind to it)
        $no_init = 1 if $is_alien;
    }

    # Save the basic information parsed from this line

    $self->{type}    = $var_type,
    $self->{is_addr} = !!$var_addr,
    $self->{name}    = $var_name,
    $self->{init_op} = $init_op,
    $self->{init}    = $var_init,
    $self->{ioparam} = $ioparam;

    # and also update the ioparam object using that information

    %$ioparam = (
        %$ioparam,
        type    => $var_type,
        arg_num => $var_num,
        var     => $var_name,
        defer   => $defer,
        init    => $init,
        init_op => $init_op,
        no_init => $no_init,
        is_addr => !!$var_addr,
    );

    1;
}


sub as_code {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    # Emit "type var" declaration and possibly various forms of
    # initialiser code.

    my $ioparam = $self->{ioparam};

    # Synthetic params like THIS will be emitted later - they
    # are treated like ANSI params, except the type can overridden
    # within an INPUT statement
    return if $ioparam->{is_synthetic};

    # The ioparam object contains data from both the INPUT line and
    # the XSUB signature.
    $ioparam->as_input_code($pxs, $xsub, $xbody);
}


# ======================================================================

package ExtUtils::ParseXS::Node::OUTPUT;

# Handle an OUTPUT: block

BEGIN { $build_subclass->(-parent => 'keylines',
)};

# The inherited parse() method will call OUTPUT_line->parse() for each line


# ======================================================================

package ExtUtils::ParseXS::Node::OUTPUT_line;

# Handle one line from an OUTPUT keyword block

BEGIN { $build_subclass->(-parent => 'keyline',
    'ioparam',     # the IO_Param object associated with this OUTPUT line.
    'is_setmagic', # Bool: the line is a SETMAGIC: line
    'do_setmagic', # Bool: the current SETMAGIC state
    'name',        # Str:  name of the parameter to output
    'code',        # Str:  optional setting code
)};


# Parse one line from an OUTPUT block

sub parse {
    my __PACKAGE__                     $self   = shift;
    my ExtUtils::ParseXS               $pxs    = shift;
    my ExtUtils::ParseXS::Node::xsub   $xsub   = shift;
    my ExtUtils::ParseXS::Node::xbody  $xbody  = shift;
    my ExtUtils::ParseXS::Node::OUTPUT $parent = shift; # parent OUTPUT node

    $self->SUPER::parse($pxs); # set file/line_no/line
    my $line = $self->{line};  # line of text to be processed

    return unless $line =~ /\S/;  # skip blank lines

    # set some sane default values in case we do one of the early returns
    # below

    $self->{do_setmagic} = $xbody->{OUTPUT_SETMAGIC_state};
    $self->{is_setmagic} = 0;

    if ($line =~ /^\s*SETMAGIC\s*:\s*(ENABLE|DISABLE)\s*/) {
        $xbody->{OUTPUT_SETMAGIC_state} = ($1 eq "ENABLE" ? 1 : 0);
        $self->{do_setmagic} = $xbody->{OUTPUT_SETMAGIC_state};
        $self->{is_setmagic} = 1;
        return;
    }

    # Expect lines of the two forms
    #    SomeVar
    #    SomeVar   sv_setsv(....);
    #
    my ($outarg, $outcode) = $line =~ /^\s*(\S+)\s*(.*?)\s*$/s;

    $self->{name} = $outarg;

    my ExtUtils::ParseXS::Node::IO_Param $ioparam =
                                $xbody->{ioparams}{names}{$outarg};
    $self->{ioparam} = $ioparam;

    if ($ioparam && $ioparam->{in_output}) {
        $pxs->blurt("Error: duplicate OUTPUT parameter '$outarg' ignored");
        return;
    }

    if (    $outarg eq "RETVAL"
        and $xsub->{decl}{return_type}{no_output})
    {
        $pxs->blurt(  "Error: can't use RETVAL in OUTPUT "
                    . "when NO_OUTPUT declared");
        return;
    }

    if (  !$ioparam # no such param or, for RETVAL, RETVAL was void;
           # not bound to an arg which can be updated
        or $outarg ne "RETVAL" && !$ioparam->{arg_num})
    {
        $pxs->blurt("Error: OUTPUT $outarg not a parameter");
        return;
    }

    $ioparam->{in_output} = 1;
    $ioparam->{do_setmagic} = $outarg eq 'RETVAL'
                                ? 0 # RETVAL never needs magic setting
                                : $xbody->{OUTPUT_SETMAGIC_state};
    $self->{code} = $ioparam->{output_code} = $outcode if length $outcode;

    1;
}


sub as_code {
    my __PACKAGE__                    $self  = shift;
    my ExtUtils::ParseXS              $pxs   = shift;
    my ExtUtils::ParseXS::Node::xsub  $xsub  = shift;
    my ExtUtils::ParseXS::Node::xbody $xbody = shift;

    # An OUTPUT: line serves two logically distinct purposes.  First, any
    # parameters listed are updated; i.e. the perl equivalent of
    #
    #    my $foo = $_[0];
    #    # maybe $foo's value gets changed here
    #    $_[0] = $foo;  # update caller's arg with current value
    #
    # The code for updating such OUTPUT vars is emitted here, in the
    # same order they appear in OUTPUT lines, and preserving the order
    # of any intermixed POSTCALL etc blocks.
    #
    # Second, it can be used to indicate that an SV should be created,
    # set to the current value of RETVAL, and pushed on the stack; i.e
    # the perl equivalent of
    #
    #   my $RETVAL;
    #   # maybe $RETVAL's value gets set here
    #   return $RETVAL;
    #
    # The code to return RETVAL is emitted later, after all other
    # processing for XSUB is complete apart from any final CLEANUP block.
    # It is done at the same time as any emitting for params declared as
    # OUT or OUTLIST in the signature.
    #
    # There isn't any particularly strong reason to do things in this
    # exact order; but the ordering was the result of how xsubpp was
    # originally written and subsequently modified, and changing things
    # now might break existing XS code which has come to rely on the
    # ordering.

    return if $self->{name} eq 'RETVAL';

    my $ioparam = $self->{ioparam};
    return unless $ioparam; # might be an ENABLE line with no param to emit

    $ioparam->as_output_code($pxs);
}


# ======================================================================


1;

# vim: ts=4 sts=4 sw=4: et:
