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

# Node class which holds the state of one XSUB parameter, based on the
# XSUB's signature and/or an INPUT line.

BEGIN {
    our @ISA = qw(ExtUtils::ParseXS::Node);

    our @FIELDS = (
        @ExtUtils::ParseXS::Node::FIELDS,
        'type',      # The C type of the parameter
        'num',       # The arg number (starting at 1) mapped to this param
        'var',       # the name of the parameter
        'defer',     # deferred initialisation template code
        'init',      # initialisation template code
        'init_op',   # initialisation type: one of =/+/;
        'no_init',   # don't initialise the parameter
        'ansi',      # param's type was specified in signature
        'is_length', # param is declared as 'length(foo)' in signature
        'len_name' , # the 'foo' in 'length(foo)' in signature
        'is_alien',  # var declared in INPUT line, but not in signature

    );

    fields->import(@FIELDS) if $USING_FIELDS;
}




1;

# vim: ts=4 sts=4 sw=4: et:
