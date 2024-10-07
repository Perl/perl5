package ExtUtils::ParseXS::Node;
use strict;
use warnings;

our $VERSION = '3.55';

=head1 NAME

ExtUtils::ParseXS::Node - Classes for nodes of an ExtUtils::ParseXS AST

=head1 SYNOPSIS

XXX TBC

=head1 DESCRIPTION

XXX Sept 2024: this is Work In Progress. This API is currently private and
subject to change. Most of ParseXS doesn't use an AST, and instead
maintains just enough state to emit code as it parses. This module
represents the start of an effort to make it use an AST instead.

An C<ExtUtils::ParseXS::Node> class, and its various subclasses, hold the
state for the nodes of an Abstract Syntax Tree (AST), which represents the
parsed state of an XS file.

Each node is basically a hash of fields. Which field names are legal
varies by the node type. The hash keys and values can be accessed
directly: there are no getter/setter methods.

=cut


# ======================================================================

package ExtUtils::ParseXS::Node;

# Base class for all the other node types.
#
# The 'use fields' enables compile-time or run-time errors if code
# attempts to use a key which isn't listed here.

my $USING_FIELDS;

BEGIN {
    our @FIELDS = (
        # Currently there are no node fields common to all node types
    );

    # do 'use fields', except: fields needs Hash::Util which is XS, which
    # needs us. So only 'use fields' on systems where Hash::Util has already
    # been built.
    if (eval 'require Hash::Util; 1;') {
        require 'fields.pm';
        $USING_FIELDS = 1;
        fields->import(@FIELDS);
    }
}


# new(): takes one optional arg, $args, which is a hash ref of key/value
# pairs to initialise the object with.

sub new {
    my ($class, $args) = @_;
    $args = {} unless defined $args;

    my ExtUtils::ParseXS::Node $self;
    if ($USING_FIELDS) {
        $self = fields::new($class);
        %$self = %$args;
    }
    else {
        $self = bless $args => $class;
    }
    return $self;
}


# ======================================================================

package ExtUtils::ParseXS::Node::Param;

# Node subclass which holds the state of one XSUB parameter, based on the
# XSUB's signature and/or an INPUT line.

BEGIN {
    our @ISA = qw(ExtUtils::ParseXS::Node);

    our @FIELDS = (
        @ExtUtils::ParseXS::Node::FIELDS,
        'type',      # The C type of the parameter
        'arg_num',   # The arg number (starting at 1) mapped to this param
        'var',       # the name of the parameter
        'default',   # default value (if any)
        'default_usage', # how to report default value in "usage:..." error
        'proto',     # overridden prototype char(s) (if any) from typemap
        'in_out',    # The IN/OUT/OUTLIST etc value (if any)
        'defer',     # deferred initialisation template code
        'init',      # initialisation template code
        'init_op',   # initialisation type: one of =/+/;
        'no_init',   # don't initialise the parameter
        'is_addr',   # INPUT var declared as '&foo'
        'is_ansi',   # param's type was specified in signature
        'is_length', # param is declared as 'length(foo)' in signature
        'len_name' , # the 'foo' in 'length(foo)' in signature
        'is_alien',  # var declared in INPUT line, but not in signature
        'is_synthetic',# var like 'THIS' - we pretend it was in the sig

    );

    fields->import(@FIELDS) if $USING_FIELDS;
}



# check(): for a parsed INPUT line and/or typed parameter in a signature,
# update some global state and do some checks (e.g. "duplicate argument"
# error).
#
# Return true if checks pass.

sub check {
    my ExtUtils::ParseXS::Node::Param $self = shift;
    my ExtUtils::ParseXS              $pxs  = shift;
  
    my $type = $self->{type};

    # Get the overridden prototype character, if any, associated with the
    # typemap entry for this var's type.
    if ($self->{arg_num}) {
        my $typemap = $pxs->{typemaps_object}->get_typemap(ctype => $type);
        my $p = $typemap && $typemap->proto;
        $self->{proto} = $p if defined $p && length $p;
    }

    # XXX tmp workaround during code refactoring
    # Copy any relevant fields from the param object (if any) for the
    # param of the same name declared in the signature, to the INPUT param
    # object.
    my ExtUtils::ParseXS::Node::Param $sigp =
        $pxs->{xsub_sig}{names}{$self->{var}};

    if ($sigp) {
        for (qw(default)) {
            $self->{$_} = $sigp->{$_} if exists $sigp->{$_};
        }
        if (    defined $sigp->{in_out}
            and  $sigp->{in_out} =~ /^OUT/
            and !defined($self->{init_op})
        ) {
            # OUT* class: skip initialisation
            $self->{no_init} = 1;
        }
        # XXX also tmp copy some stuff back to the sig param
        for(qw(is_addr in_out proto type)) {
            $sigp->{$_} = $self->{$_} if exists $self->{$_};
        }
    }
    #
    # Check for duplicate definitions of a particular parameter name.
    # Either the name has appeared in more than one INPUT line or
    # has appeared also in the signature with a type specified.
  
    if ($pxs->{xsub_map_varname_to_seen_in_INPUT}->{$self->{var}}++) {
        $pxs->blurt(
            "Error: duplicate definition of argument '$self->{var}' ignored");
        return;
    }
  
    return 1;
}


# $self->as_code()
# Emit the param object as C code

sub as_code {
    my ExtUtils::ParseXS::Node::Param $self = shift;
    my ExtUtils::ParseXS              $pxs  = shift;
  
    my ($type, $arg_num, $var, $init, $no_init, $defer, $default)
        = @{$self}{qw(type arg_num var init no_init defer default)};
  
    my $arg = $pxs->ST($arg_num, 0);
  
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
        $pxs->{xsub_deferred_code_lines} .=
                "\n\tXSauto_length_of_$name = STRLEN_length_of_$name;\n";
  
        # this var will be declared using the normal typemap mechanism below
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
        print "\t",
                    ((defined($pxs->{xsub_class}) && $var eq 'CLASS')
                        ? $type
                        : $pxs->map_type($type, undef)),
              "\t$var";
    }
  
    # whitespace-tidy the type
    $type = ExtUtils::Typemaps::tidy_type($type);
  
    # Specify the environment for when the initialiser template is evaled.
    # Only the common ones are specified here. Other fields may be added
    # later.
    my $eval_vars = {
        type          => $type,
        var           => $var,
        num           => $arg_num,
        arg           => $arg,
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
            if $pxs->{xsub_func_name} =~ /DESTROY$/;
  
        # For a string-ish parameter foo, if length(foo) was also declared
        # as a pseudo-parameter, then override the normal typedef - which
        # would emit SvPV_nolen(...) - and instead, emit SvPV(...,
        # STRLEN_length_of_foo)
        if (    $xstype eq 'T_PV'
                and exists $pxs->{xsub_sig}{names}{"length($var)"})
        {
            print " = ($type)SvPV($arg, STRLEN_length_of_$var);\n";
            die "default value not supported with length(NAME) supplied"
                if defined $default;
            return;
        }
  
        # Get the ExtUtils::Typemaps::InputMap object associated with the
        # xstype. This contains the template of the code to be embedded,
        # e.g. 'SvPV_nolen($arg)'
        my $inputmap = $typemaps->get_inputmap(xstype => $xstype);
        if (not defined $inputmap) {
            $pxs->blurt("Error: No INPUT definition for type '$type', typekind '$xstype' found");
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
        if ($expr =~ /DO_ARRAY_ELEM/) {
            my $subtypemap  = $typemaps->get_typemap(ctype => $subtype);
            if (not $subtypemap) {
                $pxs->report_typemap_failure($typemaps, $subtype);
                return;
            }
  
            my $subinputmap =
                $typemaps->get_inputmap(xstype => $subtypemap->xstype);
            if (not $subinputmap) {
                $pxs->blurt("Error: No INPUT definition for type '$subtype',
                            typekind '" . $subtypemap->xstype . "' found");
                return;
            }
  
            my $subexpr = $subinputmap->cleaned_code;
            $subexpr =~ s/\$type/\$subtype/g;
            $subexpr =~ s/ntype/subtype/g;
            $subexpr =~ s/\$arg/ST(ix_$var)/g;
            $subexpr =~ s/\n\t/\n\t\t/g;
            $subexpr =~ s/is not of (.*\")/[arg %d] is not of $1, ix_$var + 1/g;
            $subexpr =~ s/\$var/${var}\[ix_$var - $argoff]/;
            $expr =~ s/DO_ARRAY_ELEM/$subexpr/;
        }
  
        if ($expr =~ m#/\*.*scope.*\*/#i) {  # "scope" in C comments
            $pxs->{xsub_SCOPE_enabled} = 1;
        }
  
        # Specify additional environment for when a template derived from a
        # *typemap* is evalled.
        @$eval_vars{qw(ntype subtype argoff)} = ($ntype, $subtype, $argoff);
        $init_template = $expr;
    }
  
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
            $pxs->{xsub_deferred_code_lines}
                .= sprintf "\n\tif (items >= %d) {\n%s;\n\t}\n",
                           $arg_num, $init_code;
        }
        else {
            # for foo(a, b = default), add code to initialise later to either
            # the arg or default value
            my $else = ($init_code =~ /\S/) ? "\telse {\n$init_code;\n\t}\n" : "";
  
            $default =~ s/"/\\"/g; # escape double quotes
            $pxs->{xsub_deferred_code_lines}
                .= sprintf "\n\tif (items < %d)\n\t    %s = %s;\n%s",
                        $arg_num,
                        $var,
                        $pxs->eval_input_typemap_code("qq\a$default\a",
                                                       $eval_vars),
                        $else;
        }
    }
    elsif ($pxs->{xsub_SCOPE_enabled} or $init_code !~ /^\s*\Q$var\E =/) {
        # The template is likely a full block rather than a '$var = ...'
        # expression. Just terminate the variable declaration, and defer the
        # initialisation.
        # Note that /\Q$var\E/ matches the string containing whatever $var
        # was expanded to in the eval.
  
        print ";\n";
  
        $pxs->{xsub_deferred_code_lines} .= sprintf "\n%s;\n", $init_code
            if $init_code =~ /\S/;
    }
    else {
        # The template starts with '$var = ...'. The variable name has already
        # been emitted, so remove it from the typemap before evalling it,
  
        $init_code =~ s/^\s*\Q$var\E(\s*=\s*)/$1/
            or $pxs->death("panic: typemap doesn't start with '\$var='\n");
  
        printf "%s;\n", $init_code;
    }
  
    if (defined $defer) {
        $pxs->{xsub_deferred_code_lines}
            .= $pxs->eval_input_typemap_code("qq\a$defer\a", $eval_vars) . "\n";
    }
}


# ======================================================================

package ExtUtils::ParseXS::Node::Sig;

# Node subclass which holds the state of an XSUB's signature, based on the
# XSUB's actual signature plus any INPUT lines. It is a mainly a list of
# Node::Param children.

BEGIN {
    our @ISA = qw(ExtUtils::ParseXS::Node);

    our @FIELDS = (
        @ExtUtils::ParseXS::Node::FIELDS,
        'params',        # Array ref of Node::Param objects representing
                         # the parameters of this XSUB

        'names',         # Hash ref mapping variable names to Node::Param
                         # objects

        'sig_text',      # The original text of the sig, e.g.
                         #   'param1, int param2 = 0'

        'seen_ellipsis', # Bool: XSUB signature has (   ,...)

        'nargs',         # The number of args expected from caller
        'min_args',      # The minimum number of args allowed from caller

        'auto_function_sig_override', # the C_ARGS value, if any

    );

    fields->import(@FIELDS) if $USING_FIELDS;
}


# Return a string to be used in "usage: .." error messages.

sub usage_string {
    my ExtUtils::ParseXS::Node::Sig $self = shift;

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
               @{$self->{params}};

    push @args, '...' if $self->{seen_ellipsis};
    return join ', ', @args;
}


# $self->C_func_signature():
#
# return a string containing the arguments to pass to an autocall C
# function, e.g. 'a, &b, c'.

sub C_func_signature {
    my ExtUtils::ParseXS::Node::Sig $self = shift;

    my @args;
    for my $param (@{$self->{params}}) {
        next if $param->{is_synthetic}; # THIS etc

        if ($param->{is_length}) {
            push @args, "XSauto_length_of_$param->{len_name}";
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
    }

    return join(", ", @args);
}


# $self->proto_string():
#
# return a string containing the perl prototype string for this XSUB,
# e.g. '$$;$$@'.

sub proto_string {
    my ExtUtils::ParseXS::Node::Sig $self = shift;

    # Generate a prototype entry for each param that's bound to a real
    # arg. Use '$' unless the typemap for that param has specified an
    # overridden entry.
    my @p = map  defined $_->{proto} ? $_->{proto} : '$',
            grep defined $_->{arg_num} && $_->{arg_num} > 0,
            @{$self->{params}};

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

1;

# vim: ts=4 sts=4 sw=4: et:
