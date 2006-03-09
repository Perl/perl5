package PLXML;

sub DESTROY { }

sub walk {
    print "walk(" . join(',', @_) . ")\n";
    my $self = shift;
    for my $key (sort keys %$self) {
	print "\t$key = <$$self{$key}>\n";
    }
    foreach $kid (@{$$self{Kids}}) {
	$kid->walk(@_);
    }
}

package PLXML::Characters;

@ISA = ('PLXML');
sub walk {}

package PLXML::madprops;

@ISA = ('PLXML');

package PLXML::mad_op;

@ISA = ('PLXML');

package PLXML::mad_pv;

@ISA = ('PLXML');

package PLXML::baseop;

@ISA = ('PLXML');

package PLXML::baseop_unop;

@ISA = ('PLXML');

package PLXML::binop;

@ISA = ('PLXML');

package PLXML::cop;

@ISA = ('PLXML');

package PLXML::filestatop;

@ISA = ('PLXML::baseop_unop');

package PLXML::listop;

@ISA = ('PLXML');

package PLXML::logop;

@ISA = ('PLXML');

package PLXML::loop;

@ISA = ('PLXML');

package PLXML::loopexop;

@ISA = ('PLXML');

package PLXML::padop;

@ISA = ('PLXML');

package PLXML::padop_svop;

@ISA = ('PLXML');

package PLXML::pmop;

@ISA = ('PLXML');

package PLXML::pvop_svop;

@ISA = ('PLXML');

package PLXML::unop;

@ISA = ('PLXML');


# New ops always go at the end, just before 'custom'

# A recapitulation of the format of this file:
# The file consists of five columns: the name of the op, an English
# description, the name of the "check" routine used to optimize this
# operation, some flags, and a description of the operands.

# The flags consist of options followed by a mandatory op class signifier

# The classes are:
# baseop      - 0            unop     - 1            binop      - 2
# logop       - |            listop   - @            pmop       - /
# padop/svop  - $            padop    - # (unused)   loop       - {
# baseop/unop - %            loopexop - }            filestatop - -
# pvop/svop   - "            cop      - ;

# Other options are:
#   needs stack mark                    - m
#   needs constant folding              - f
#   produces a scalar                   - s
#   produces an integer                 - i
#   needs a target                      - t
#   target can be in a pad              - T
#   has a corresponding integer version - I
#   has side effects                    - d
#   uses $_ if no argument given        - u

# Values for the operands are:
# scalar      - S            list     - L            array     - A
# hash        - H            sub (CV) - C            file      - F
# socket      - Fs           filetest - F-           reference - R
# "?" denotes an optional operand.

# Nothing.

package PLXML::op_null;

@ISA = ('PLXML::baseop');

sub key { 'null' }
sub desc { 'null operation' }
sub check { 'ck_null' }
sub flags { '0' }
sub args { '' }


package PLXML::op_stub;

@ISA = ('PLXML::baseop');

sub key { 'stub' }
sub desc { 'stub' }
sub check { 'ck_null' }
sub flags { '0' }
sub args { '' }


package PLXML::op_scalar;

@ISA = ('PLXML::baseop_unop');

sub key { 'scalar' }
sub desc { 'scalar' }
sub check { 'ck_fun' }
sub flags { 's%' }
sub args { 'S' }



# Pushy stuff.

package PLXML::op_pushmark;

@ISA = ('PLXML::baseop');

sub key { 'pushmark' }
sub desc { 'pushmark' }
sub check { 'ck_null' }
sub flags { 's0' }
sub args { '' }


package PLXML::op_wantarray;

@ISA = ('PLXML::baseop');

sub key { 'wantarray' }
sub desc { 'wantarray' }
sub check { 'ck_null' }
sub flags { 'is0' }
sub args { '' }



package PLXML::op_const;

@ISA = ('PLXML::padop_svop');

sub key { 'const' }
sub desc { 'constant item' }
sub check { 'ck_svconst' }
sub flags { 's$' }
sub args { '' }



package PLXML::op_gvsv;

@ISA = ('PLXML::padop_svop');

sub key { 'gvsv' }
sub desc { 'scalar variable' }
sub check { 'ck_null' }
sub flags { 'ds$' }
sub args { '' }


package PLXML::op_gv;

@ISA = ('PLXML::padop_svop');

sub key { 'gv' }
sub desc { 'glob value' }
sub check { 'ck_null' }
sub flags { 'ds$' }
sub args { '' }


package PLXML::op_gelem;

@ISA = ('PLXML::binop');

sub key { 'gelem' }
sub desc { 'glob elem' }
sub check { 'ck_null' }
sub flags { 'd2' }
sub args { 'S S' }


package PLXML::op_padsv;

@ISA = ('PLXML::baseop');

sub key { 'padsv' }
sub desc { 'private variable' }
sub check { 'ck_null' }
sub flags { 'ds0' }
sub args { '' }


package PLXML::op_padav;

@ISA = ('PLXML::baseop');

sub key { 'padav' }
sub desc { 'private array' }
sub check { 'ck_null' }
sub flags { 'd0' }
sub args { '' }


package PLXML::op_padhv;

@ISA = ('PLXML::baseop');

sub key { 'padhv' }
sub desc { 'private hash' }
sub check { 'ck_null' }
sub flags { 'd0' }
sub args { '' }


package PLXML::op_padany;

@ISA = ('PLXML::baseop');

sub key { 'padany' }
sub desc { 'private value' }
sub check { 'ck_null' }
sub flags { 'd0' }
sub args { '' }



package PLXML::op_pushre;

@ISA = ('PLXML::pmop');

sub key { 'pushre' }
sub desc { 'push regexp' }
sub check { 'ck_null' }
sub flags { 'd/' }
sub args { '' }



# References and stuff.

package PLXML::op_rv2gv;

@ISA = ('PLXML::unop');

sub key { 'rv2gv' }
sub desc { 'ref-to-glob cast' }
sub check { 'ck_rvconst' }
sub flags { 'ds1' }
sub args { '' }


package PLXML::op_rv2sv;

@ISA = ('PLXML::unop');

sub key { 'rv2sv' }
sub desc { 'scalar dereference' }
sub check { 'ck_rvconst' }
sub flags { 'ds1' }
sub args { '' }


package PLXML::op_av2arylen;

@ISA = ('PLXML::unop');

sub key { 'av2arylen' }
sub desc { 'array length' }
sub check { 'ck_null' }
sub flags { 'is1' }
sub args { '' }


package PLXML::op_rv2cv;

@ISA = ('PLXML::unop');

sub key { 'rv2cv' }
sub desc { 'subroutine dereference' }
sub check { 'ck_rvconst' }
sub flags { 'd1' }
sub args { '' }


package PLXML::op_anoncode;

@ISA = ('PLXML::padop_svop');

sub key { 'anoncode' }
sub desc { 'anonymous subroutine' }
sub check { 'ck_anoncode' }
sub flags { '$' }
sub args { '' }


package PLXML::op_prototype;

@ISA = ('PLXML::baseop_unop');

sub key { 'prototype' }
sub desc { 'subroutine prototype' }
sub check { 'ck_null' }
sub flags { 's%' }
sub args { 'S' }


package PLXML::op_refgen;

@ISA = ('PLXML::unop');

sub key { 'refgen' }
sub desc { 'reference constructor' }
sub check { 'ck_spair' }
sub flags { 'm1' }
sub args { 'L' }


package PLXML::op_srefgen;

@ISA = ('PLXML::unop');

sub key { 'srefgen' }
sub desc { 'single ref constructor' }
sub check { 'ck_null' }
sub flags { 'fs1' }
sub args { 'S' }


package PLXML::op_ref;

@ISA = ('PLXML::baseop_unop');

sub key { 'ref' }
sub desc { 'reference-type operator' }
sub check { 'ck_fun' }
sub flags { 'stu%' }
sub args { 'S?' }


package PLXML::op_bless;

@ISA = ('PLXML::listop');

sub key { 'bless' }
sub desc { 'bless' }
sub check { 'ck_fun' }
sub flags { 's@' }
sub args { 'S S?' }



# Pushy I/O.

package PLXML::op_backtick;

@ISA = ('PLXML::baseop_unop');

sub key { 'backtick' }
sub desc { 'quoted execution (``, qx)' }
sub check { 'ck_open' }
sub flags { 't%' }
sub args { '' }


# glob defaults its first arg to $_
package PLXML::op_glob;

@ISA = ('PLXML::listop');

sub key { 'glob' }
sub desc { 'glob' }
sub check { 'ck_glob' }
sub flags { 't@' }
sub args { 'S?' }


package PLXML::op_readline;

@ISA = ('PLXML::baseop_unop');

sub key { 'readline' }
sub desc { '<HANDLE>' }
sub check { 'ck_null' }
sub flags { 't%' }
sub args { 'F?' }


package PLXML::op_rcatline;

@ISA = ('PLXML::padop_svop');

sub key { 'rcatline' }
sub desc { 'append I/O operator' }
sub check { 'ck_null' }
sub flags { 't$' }
sub args { '' }



# Bindable operators.

package PLXML::op_regcmaybe;

@ISA = ('PLXML::unop');

sub key { 'regcmaybe' }
sub desc { 'regexp internal guard' }
sub check { 'ck_fun' }
sub flags { 's1' }
sub args { 'S' }


package PLXML::op_regcreset;

@ISA = ('PLXML::unop');

sub key { 'regcreset' }
sub desc { 'regexp internal reset' }
sub check { 'ck_fun' }
sub flags { 's1' }
sub args { 'S' }


package PLXML::op_regcomp;

@ISA = ('PLXML::logop');

sub key { 'regcomp' }
sub desc { 'regexp compilation' }
sub check { 'ck_null' }
sub flags { 's|' }
sub args { 'S' }


package PLXML::op_match;

@ISA = ('PLXML::pmop');

sub key { 'match' }
sub desc { 'pattern match (m//)' }
sub check { 'ck_match' }
sub flags { 'd/' }
sub args { '' }


package PLXML::op_qr;

@ISA = ('PLXML::pmop');

sub key { 'qr' }
sub desc { 'pattern quote (qr//)' }
sub check { 'ck_match' }
sub flags { 's/' }
sub args { '' }


package PLXML::op_subst;

@ISA = ('PLXML::pmop');

sub key { 'subst' }
sub desc { 'substitution (s///)' }
sub check { 'ck_match' }
sub flags { 'dis/' }
sub args { 'S' }


package PLXML::op_substcont;

@ISA = ('PLXML::logop');

sub key { 'substcont' }
sub desc { 'substitution iterator' }
sub check { 'ck_null' }
sub flags { 'dis|' }
sub args { '' }


package PLXML::op_trans;

@ISA = ('PLXML::pvop_svop');

sub key { 'trans' }
sub desc { 'transliteration (tr///)' }
sub check { 'ck_match' }
sub flags { 'is"' }
sub args { 'S' }



# Lvalue operators.
# sassign is special-cased for op class

package PLXML::op_sassign;

@ISA = ('PLXML::baseop');

sub key { 'sassign' }
sub desc { 'scalar assignment' }
sub check { 'ck_sassign' }
sub flags { 's0' }
sub args { '' }


package PLXML::op_aassign;

@ISA = ('PLXML::binop');

sub key { 'aassign' }
sub desc { 'list assignment' }
sub check { 'ck_null' }
sub flags { 't2' }
sub args { 'L L' }



package PLXML::op_chop;

@ISA = ('PLXML::baseop_unop');

sub key { 'chop' }
sub desc { 'chop' }
sub check { 'ck_spair' }
sub flags { 'mts%' }
sub args { 'L' }


package PLXML::op_schop;

@ISA = ('PLXML::baseop_unop');

sub key { 'schop' }
sub desc { 'scalar chop' }
sub check { 'ck_null' }
sub flags { 'stu%' }
sub args { 'S?' }


package PLXML::op_chomp;

@ISA = ('PLXML::baseop_unop');

sub key { 'chomp' }
sub desc { 'chomp' }
sub check { 'ck_spair' }
sub flags { 'mTs%' }
sub args { 'L' }


package PLXML::op_schomp;

@ISA = ('PLXML::baseop_unop');

sub key { 'schomp' }
sub desc { 'scalar chomp' }
sub check { 'ck_null' }
sub flags { 'sTu%' }
sub args { 'S?' }


package PLXML::op_defined;

@ISA = ('PLXML::baseop_unop');

sub key { 'defined' }
sub desc { 'defined operator' }
sub check { 'ck_defined' }
sub flags { 'isu%' }
sub args { 'S?' }


package PLXML::op_undef;

@ISA = ('PLXML::baseop_unop');

sub key { 'undef' }
sub desc { 'undef operator' }
sub check { 'ck_lfun' }
sub flags { 's%' }
sub args { 'S?' }


package PLXML::op_study;

@ISA = ('PLXML::baseop_unop');

sub key { 'study' }
sub desc { 'study' }
sub check { 'ck_fun' }
sub flags { 'su%' }
sub args { 'S?' }


package PLXML::op_pos;

@ISA = ('PLXML::baseop_unop');

sub key { 'pos' }
sub desc { 'match position' }
sub check { 'ck_lfun' }
sub flags { 'stu%' }
sub args { 'S?' }



package PLXML::op_preinc;

@ISA = ('PLXML::unop');

sub key { 'preinc' }
sub desc { 'preincrement (++)' }
sub check { 'ck_lfun' }
sub flags { 'dIs1' }
sub args { 'S' }


package PLXML::op_i_preinc;

@ISA = ('PLXML::unop');

sub key { 'i_preinc' }
sub desc { 'integer preincrement (++)' }
sub check { 'ck_lfun' }
sub flags { 'dis1' }
sub args { 'S' }


package PLXML::op_predec;

@ISA = ('PLXML::unop');

sub key { 'predec' }
sub desc { 'predecrement (--)' }
sub check { 'ck_lfun' }
sub flags { 'dIs1' }
sub args { 'S' }


package PLXML::op_i_predec;

@ISA = ('PLXML::unop');

sub key { 'i_predec' }
sub desc { 'integer predecrement (--)' }
sub check { 'ck_lfun' }
sub flags { 'dis1' }
sub args { 'S' }


package PLXML::op_postinc;

@ISA = ('PLXML::unop');

sub key { 'postinc' }
sub desc { 'postincrement (++)' }
sub check { 'ck_lfun' }
sub flags { 'dIst1' }
sub args { 'S' }


package PLXML::op_i_postinc;

@ISA = ('PLXML::unop');

sub key { 'i_postinc' }
sub desc { 'integer postincrement (++)' }
sub check { 'ck_lfun' }
sub flags { 'disT1' }
sub args { 'S' }


package PLXML::op_postdec;

@ISA = ('PLXML::unop');

sub key { 'postdec' }
sub desc { 'postdecrement (--)' }
sub check { 'ck_lfun' }
sub flags { 'dIst1' }
sub args { 'S' }


package PLXML::op_i_postdec;

@ISA = ('PLXML::unop');

sub key { 'i_postdec' }
sub desc { 'integer postdecrement (--)' }
sub check { 'ck_lfun' }
sub flags { 'disT1' }
sub args { 'S' }



# Ordinary operators.

package PLXML::op_pow;

@ISA = ('PLXML::binop');

sub key { 'pow' }
sub desc { 'exponentiation (**)' }
sub check { 'ck_null' }
sub flags { 'fsT2' }
sub args { 'S S' }



package PLXML::op_multiply;

@ISA = ('PLXML::binop');

sub key { 'multiply' }
sub desc { 'multiplication (*)' }
sub check { 'ck_null' }
sub flags { 'IfsT2' }
sub args { 'S S' }


package PLXML::op_i_multiply;

@ISA = ('PLXML::binop');

sub key { 'i_multiply' }
sub desc { 'integer multiplication (*)' }
sub check { 'ck_null' }
sub flags { 'ifsT2' }
sub args { 'S S' }


package PLXML::op_divide;

@ISA = ('PLXML::binop');

sub key { 'divide' }
sub desc { 'division (/)' }
sub check { 'ck_null' }
sub flags { 'IfsT2' }
sub args { 'S S' }


package PLXML::op_i_divide;

@ISA = ('PLXML::binop');

sub key { 'i_divide' }
sub desc { 'integer division (/)' }
sub check { 'ck_null' }
sub flags { 'ifsT2' }
sub args { 'S S' }


package PLXML::op_modulo;

@ISA = ('PLXML::binop');

sub key { 'modulo' }
sub desc { 'modulus (%)' }
sub check { 'ck_null' }
sub flags { 'IifsT2' }
sub args { 'S S' }


package PLXML::op_i_modulo;

@ISA = ('PLXML::binop');

sub key { 'i_modulo' }
sub desc { 'integer modulus (%)' }
sub check { 'ck_null' }
sub flags { 'ifsT2' }
sub args { 'S S' }


package PLXML::op_repeat;

@ISA = ('PLXML::binop');

sub key { 'repeat' }
sub desc { 'repeat (x)' }
sub check { 'ck_repeat' }
sub flags { 'mt2' }
sub args { 'L S' }



package PLXML::op_add;

@ISA = ('PLXML::binop');

sub key { 'add' }
sub desc { 'addition (+)' }
sub check { 'ck_null' }
sub flags { 'IfsT2' }
sub args { 'S S' }


package PLXML::op_i_add;

@ISA = ('PLXML::binop');

sub key { 'i_add' }
sub desc { 'integer addition (+)' }
sub check { 'ck_null' }
sub flags { 'ifsT2' }
sub args { 'S S' }


package PLXML::op_subtract;

@ISA = ('PLXML::binop');

sub key { 'subtract' }
sub desc { 'subtraction (-)' }
sub check { 'ck_null' }
sub flags { 'IfsT2' }
sub args { 'S S' }


package PLXML::op_i_subtract;

@ISA = ('PLXML::binop');

sub key { 'i_subtract' }
sub desc { 'integer subtraction (-)' }
sub check { 'ck_null' }
sub flags { 'ifsT2' }
sub args { 'S S' }


package PLXML::op_concat;

@ISA = ('PLXML::binop');

sub key { 'concat' }
sub desc { 'concatenation (.) or string' }
sub check { 'ck_concat' }
sub flags { 'fsT2' }
sub args { 'S S' }


package PLXML::op_stringify;

@ISA = ('PLXML::listop');

sub key { 'stringify' }
sub desc { 'string' }
sub check { 'ck_fun' }
sub flags { 'fsT@' }
sub args { 'S' }



package PLXML::op_left_shift;

@ISA = ('PLXML::binop');

sub key { 'left_shift' }
sub desc { 'left bitshift (<<)' }
sub check { 'ck_bitop' }
sub flags { 'fsT2' }
sub args { 'S S' }


package PLXML::op_right_shift;

@ISA = ('PLXML::binop');

sub key { 'right_shift' }
sub desc { 'right bitshift (>>)' }
sub check { 'ck_bitop' }
sub flags { 'fsT2' }
sub args { 'S S' }



package PLXML::op_lt;

@ISA = ('PLXML::binop');

sub key { 'lt' }
sub desc { 'numeric lt (<)' }
sub check { 'ck_null' }
sub flags { 'Iifs2' }
sub args { 'S S' }


package PLXML::op_i_lt;

@ISA = ('PLXML::binop');

sub key { 'i_lt' }
sub desc { 'integer lt (<)' }
sub check { 'ck_null' }
sub flags { 'ifs2' }
sub args { 'S S' }


package PLXML::op_gt;

@ISA = ('PLXML::binop');

sub key { 'gt' }
sub desc { 'numeric gt (>)' }
sub check { 'ck_null' }
sub flags { 'Iifs2' }
sub args { 'S S' }


package PLXML::op_i_gt;

@ISA = ('PLXML::binop');

sub key { 'i_gt' }
sub desc { 'integer gt (>)' }
sub check { 'ck_null' }
sub flags { 'ifs2' }
sub args { 'S S' }


package PLXML::op_le;

@ISA = ('PLXML::binop');

sub key { 'le' }
sub desc { 'numeric le (<=)' }
sub check { 'ck_null' }
sub flags { 'Iifs2' }
sub args { 'S S' }


package PLXML::op_i_le;

@ISA = ('PLXML::binop');

sub key { 'i_le' }
sub desc { 'integer le (<=)' }
sub check { 'ck_null' }
sub flags { 'ifs2' }
sub args { 'S S' }


package PLXML::op_ge;

@ISA = ('PLXML::binop');

sub key { 'ge' }
sub desc { 'numeric ge (>=)' }
sub check { 'ck_null' }
sub flags { 'Iifs2' }
sub args { 'S S' }


package PLXML::op_i_ge;

@ISA = ('PLXML::binop');

sub key { 'i_ge' }
sub desc { 'integer ge (>=)' }
sub check { 'ck_null' }
sub flags { 'ifs2' }
sub args { 'S S' }


package PLXML::op_eq;

@ISA = ('PLXML::binop');

sub key { 'eq' }
sub desc { 'numeric eq (==)' }
sub check { 'ck_null' }
sub flags { 'Iifs2' }
sub args { 'S S' }


package PLXML::op_i_eq;

@ISA = ('PLXML::binop');

sub key { 'i_eq' }
sub desc { 'integer eq (==)' }
sub check { 'ck_null' }
sub flags { 'ifs2' }
sub args { 'S S' }


package PLXML::op_ne;

@ISA = ('PLXML::binop');

sub key { 'ne' }
sub desc { 'numeric ne (!=)' }
sub check { 'ck_null' }
sub flags { 'Iifs2' }
sub args { 'S S' }


package PLXML::op_i_ne;

@ISA = ('PLXML::binop');

sub key { 'i_ne' }
sub desc { 'integer ne (!=)' }
sub check { 'ck_null' }
sub flags { 'ifs2' }
sub args { 'S S' }


package PLXML::op_ncmp;

@ISA = ('PLXML::binop');

sub key { 'ncmp' }
sub desc { 'numeric comparison (<=>)' }
sub check { 'ck_null' }
sub flags { 'Iifst2' }
sub args { 'S S' }


package PLXML::op_i_ncmp;

@ISA = ('PLXML::binop');

sub key { 'i_ncmp' }
sub desc { 'integer comparison (<=>)' }
sub check { 'ck_null' }
sub flags { 'ifst2' }
sub args { 'S S' }



package PLXML::op_slt;

@ISA = ('PLXML::binop');

sub key { 'slt' }
sub desc { 'string lt' }
sub check { 'ck_null' }
sub flags { 'ifs2' }
sub args { 'S S' }


package PLXML::op_sgt;

@ISA = ('PLXML::binop');

sub key { 'sgt' }
sub desc { 'string gt' }
sub check { 'ck_null' }
sub flags { 'ifs2' }
sub args { 'S S' }


package PLXML::op_sle;

@ISA = ('PLXML::binop');

sub key { 'sle' }
sub desc { 'string le' }
sub check { 'ck_null' }
sub flags { 'ifs2' }
sub args { 'S S' }


package PLXML::op_sge;

@ISA = ('PLXML::binop');

sub key { 'sge' }
sub desc { 'string ge' }
sub check { 'ck_null' }
sub flags { 'ifs2' }
sub args { 'S S' }


package PLXML::op_seq;

@ISA = ('PLXML::binop');

sub key { 'seq' }
sub desc { 'string eq' }
sub check { 'ck_null' }
sub flags { 'ifs2' }
sub args { 'S S' }


package PLXML::op_sne;

@ISA = ('PLXML::binop');

sub key { 'sne' }
sub desc { 'string ne' }
sub check { 'ck_null' }
sub flags { 'ifs2' }
sub args { 'S S' }


package PLXML::op_scmp;

@ISA = ('PLXML::binop');

sub key { 'scmp' }
sub desc { 'string comparison (cmp)' }
sub check { 'ck_null' }
sub flags { 'ifst2' }
sub args { 'S S' }



package PLXML::op_bit_and;

@ISA = ('PLXML::binop');

sub key { 'bit_and' }
sub desc { 'bitwise and (&)' }
sub check { 'ck_bitop' }
sub flags { 'fst2' }
sub args { 'S S' }


package PLXML::op_bit_xor;

@ISA = ('PLXML::binop');

sub key { 'bit_xor' }
sub desc { 'bitwise xor (^)' }
sub check { 'ck_bitop' }
sub flags { 'fst2' }
sub args { 'S S' }


package PLXML::op_bit_or;

@ISA = ('PLXML::binop');

sub key { 'bit_or' }
sub desc { 'bitwise or (|)' }
sub check { 'ck_bitop' }
sub flags { 'fst2' }
sub args { 'S S' }



package PLXML::op_negate;

@ISA = ('PLXML::unop');

sub key { 'negate' }
sub desc { 'negation (-)' }
sub check { 'ck_null' }
sub flags { 'Ifst1' }
sub args { 'S' }


package PLXML::op_i_negate;

@ISA = ('PLXML::unop');

sub key { 'i_negate' }
sub desc { 'integer negation (-)' }
sub check { 'ck_null' }
sub flags { 'ifsT1' }
sub args { 'S' }


package PLXML::op_not;

@ISA = ('PLXML::unop');

sub key { 'not' }
sub desc { 'not' }
sub check { 'ck_null' }
sub flags { 'ifs1' }
sub args { 'S' }


package PLXML::op_complement;

@ISA = ('PLXML::unop');

sub key { 'complement' }
sub desc { '1\'s complement (~)' }
sub check { 'ck_bitop' }
sub flags { 'fst1' }
sub args { 'S' }



# High falutin' math.

package PLXML::op_atan2;

@ISA = ('PLXML::listop');

sub key { 'atan2' }
sub desc { 'atan2' }
sub check { 'ck_fun' }
sub flags { 'fsT@' }
sub args { 'S S' }


package PLXML::op_sin;

@ISA = ('PLXML::baseop_unop');

sub key { 'sin' }
sub desc { 'sin' }
sub check { 'ck_fun' }
sub flags { 'fsTu%' }
sub args { 'S?' }


package PLXML::op_cos;

@ISA = ('PLXML::baseop_unop');

sub key { 'cos' }
sub desc { 'cos' }
sub check { 'ck_fun' }
sub flags { 'fsTu%' }
sub args { 'S?' }


package PLXML::op_rand;

@ISA = ('PLXML::baseop_unop');

sub key { 'rand' }
sub desc { 'rand' }
sub check { 'ck_fun' }
sub flags { 'sT%' }
sub args { 'S?' }


package PLXML::op_srand;

@ISA = ('PLXML::baseop_unop');

sub key { 'srand' }
sub desc { 'srand' }
sub check { 'ck_fun' }
sub flags { 's%' }
sub args { 'S?' }


package PLXML::op_exp;

@ISA = ('PLXML::baseop_unop');

sub key { 'exp' }
sub desc { 'exp' }
sub check { 'ck_fun' }
sub flags { 'fsTu%' }
sub args { 'S?' }


package PLXML::op_log;

@ISA = ('PLXML::baseop_unop');

sub key { 'log' }
sub desc { 'log' }
sub check { 'ck_fun' }
sub flags { 'fsTu%' }
sub args { 'S?' }


package PLXML::op_sqrt;

@ISA = ('PLXML::baseop_unop');

sub key { 'sqrt' }
sub desc { 'sqrt' }
sub check { 'ck_fun' }
sub flags { 'fsTu%' }
sub args { 'S?' }



# Lowbrow math.

package PLXML::op_int;

@ISA = ('PLXML::baseop_unop');

sub key { 'int' }
sub desc { 'int' }
sub check { 'ck_fun' }
sub flags { 'fsTu%' }
sub args { 'S?' }


package PLXML::op_hex;

@ISA = ('PLXML::baseop_unop');

sub key { 'hex' }
sub desc { 'hex' }
sub check { 'ck_fun' }
sub flags { 'fsTu%' }
sub args { 'S?' }


package PLXML::op_oct;

@ISA = ('PLXML::baseop_unop');

sub key { 'oct' }
sub desc { 'oct' }
sub check { 'ck_fun' }
sub flags { 'fsTu%' }
sub args { 'S?' }


package PLXML::op_abs;

@ISA = ('PLXML::baseop_unop');

sub key { 'abs' }
sub desc { 'abs' }
sub check { 'ck_fun' }
sub flags { 'fsTu%' }
sub args { 'S?' }



# String stuff.

package PLXML::op_length;

@ISA = ('PLXML::baseop_unop');

sub key { 'length' }
sub desc { 'length' }
sub check { 'ck_lengthconst' }
sub flags { 'isTu%' }
sub args { 'S?' }


package PLXML::op_substr;

@ISA = ('PLXML::listop');

sub key { 'substr' }
sub desc { 'substr' }
sub check { 'ck_substr' }
sub flags { 'st@' }
sub args { 'S S S? S?' }


package PLXML::op_vec;

@ISA = ('PLXML::listop');

sub key { 'vec' }
sub desc { 'vec' }
sub check { 'ck_fun' }
sub flags { 'ist@' }
sub args { 'S S S' }



package PLXML::op_index;

@ISA = ('PLXML::listop');

sub key { 'index' }
sub desc { 'index' }
sub check { 'ck_index' }
sub flags { 'isT@' }
sub args { 'S S S?' }


package PLXML::op_rindex;

@ISA = ('PLXML::listop');

sub key { 'rindex' }
sub desc { 'rindex' }
sub check { 'ck_index' }
sub flags { 'isT@' }
sub args { 'S S S?' }



package PLXML::op_sprintf;

@ISA = ('PLXML::listop');

sub key { 'sprintf' }
sub desc { 'sprintf' }
sub check { 'ck_fun' }
sub flags { 'mfst@' }
sub args { 'S L' }


package PLXML::op_formline;

@ISA = ('PLXML::listop');

sub key { 'formline' }
sub desc { 'formline' }
sub check { 'ck_fun' }
sub flags { 'ms@' }
sub args { 'S L' }


package PLXML::op_ord;

@ISA = ('PLXML::baseop_unop');

sub key { 'ord' }
sub desc { 'ord' }
sub check { 'ck_fun' }
sub flags { 'ifsTu%' }
sub args { 'S?' }


package PLXML::op_chr;

@ISA = ('PLXML::baseop_unop');

sub key { 'chr' }
sub desc { 'chr' }
sub check { 'ck_fun' }
sub flags { 'fsTu%' }
sub args { 'S?' }


package PLXML::op_crypt;

@ISA = ('PLXML::listop');

sub key { 'crypt' }
sub desc { 'crypt' }
sub check { 'ck_fun' }
sub flags { 'fsT@' }
sub args { 'S S' }


package PLXML::op_ucfirst;

@ISA = ('PLXML::baseop_unop');

sub key { 'ucfirst' }
sub desc { 'ucfirst' }
sub check { 'ck_fun' }
sub flags { 'fstu%' }
sub args { 'S?' }


package PLXML::op_lcfirst;

@ISA = ('PLXML::baseop_unop');

sub key { 'lcfirst' }
sub desc { 'lcfirst' }
sub check { 'ck_fun' }
sub flags { 'fstu%' }
sub args { 'S?' }


package PLXML::op_uc;

@ISA = ('PLXML::baseop_unop');

sub key { 'uc' }
sub desc { 'uc' }
sub check { 'ck_fun' }
sub flags { 'fstu%' }
sub args { 'S?' }


package PLXML::op_lc;

@ISA = ('PLXML::baseop_unop');

sub key { 'lc' }
sub desc { 'lc' }
sub check { 'ck_fun' }
sub flags { 'fstu%' }
sub args { 'S?' }


package PLXML::op_quotemeta;

@ISA = ('PLXML::baseop_unop');

sub key { 'quotemeta' }
sub desc { 'quotemeta' }
sub check { 'ck_fun' }
sub flags { 'fstu%' }
sub args { 'S?' }



# Arrays.

package PLXML::op_rv2av;

@ISA = ('PLXML::unop');

sub key { 'rv2av' }
sub desc { 'array dereference' }
sub check { 'ck_rvconst' }
sub flags { 'dt1' }
sub args { '' }


package PLXML::op_aelemfast;

@ISA = ('PLXML::padop_svop');

sub key { 'aelemfast' }
sub desc { 'constant array element' }
sub check { 'ck_null' }
sub flags { 's$' }
sub args { 'A S' }


package PLXML::op_aelem;

@ISA = ('PLXML::binop');

sub key { 'aelem' }
sub desc { 'array element' }
sub check { 'ck_null' }
sub flags { 's2' }
sub args { 'A S' }


package PLXML::op_aslice;

@ISA = ('PLXML::listop');

sub key { 'aslice' }
sub desc { 'array slice' }
sub check { 'ck_null' }
sub flags { 'm@' }
sub args { 'A L' }



# Hashes.

package PLXML::op_each;

@ISA = ('PLXML::baseop_unop');

sub key { 'each' }
sub desc { 'each' }
sub check { 'ck_fun' }
sub flags { '%' }
sub args { 'H' }


package PLXML::op_values;

@ISA = ('PLXML::baseop_unop');

sub key { 'values' }
sub desc { 'values' }
sub check { 'ck_fun' }
sub flags { 't%' }
sub args { 'H' }


package PLXML::op_keys;

@ISA = ('PLXML::baseop_unop');

sub key { 'keys' }
sub desc { 'keys' }
sub check { 'ck_fun' }
sub flags { 't%' }
sub args { 'H' }


package PLXML::op_delete;

@ISA = ('PLXML::baseop_unop');

sub key { 'delete' }
sub desc { 'delete' }
sub check { 'ck_delete' }
sub flags { '%' }
sub args { 'S' }


package PLXML::op_exists;

@ISA = ('PLXML::baseop_unop');

sub key { 'exists' }
sub desc { 'exists' }
sub check { 'ck_exists' }
sub flags { 'is%' }
sub args { 'S' }


package PLXML::op_rv2hv;

@ISA = ('PLXML::unop');

sub key { 'rv2hv' }
sub desc { 'hash dereference' }
sub check { 'ck_rvconst' }
sub flags { 'dt1' }
sub args { '' }


package PLXML::op_helem;

@ISA = ('PLXML::listop');

sub key { 'helem' }
sub desc { 'hash element' }
sub check { 'ck_null' }
sub flags { 's2@' }
sub args { 'H S' }


package PLXML::op_hslice;

@ISA = ('PLXML::listop');

sub key { 'hslice' }
sub desc { 'hash slice' }
sub check { 'ck_null' }
sub flags { 'm@' }
sub args { 'H L' }



# Explosives and implosives.

package PLXML::op_unpack;

@ISA = ('PLXML::listop');

sub key { 'unpack' }
sub desc { 'unpack' }
sub check { 'ck_unpack' }
sub flags { '@' }
sub args { 'S S?' }


package PLXML::op_pack;

@ISA = ('PLXML::listop');

sub key { 'pack' }
sub desc { 'pack' }
sub check { 'ck_fun' }
sub flags { 'mst@' }
sub args { 'S L' }


package PLXML::op_split;

@ISA = ('PLXML::listop');

sub key { 'split' }
sub desc { 'split' }
sub check { 'ck_split' }
sub flags { 't@' }
sub args { 'S S S' }


package PLXML::op_join;

@ISA = ('PLXML::listop');

sub key { 'join' }
sub desc { 'join or string' }
sub check { 'ck_join' }
sub flags { 'mst@' }
sub args { 'S L' }



# List operators.

package PLXML::op_list;

@ISA = ('PLXML::listop');

sub key { 'list' }
sub desc { 'list' }
sub check { 'ck_null' }
sub flags { 'm@' }
sub args { 'L' }


package PLXML::op_lslice;

@ISA = ('PLXML::binop');

sub key { 'lslice' }
sub desc { 'list slice' }
sub check { 'ck_null' }
sub flags { '2' }
sub args { 'H L L' }


package PLXML::op_anonlist;

@ISA = ('PLXML::listop');

sub key { 'anonlist' }
sub desc { 'anonymous list ([])' }
sub check { 'ck_fun' }
sub flags { 'ms@' }
sub args { 'L' }


package PLXML::op_anonhash;

@ISA = ('PLXML::listop');

sub key { 'anonhash' }
sub desc { 'anonymous hash ({})' }
sub check { 'ck_fun' }
sub flags { 'ms@' }
sub args { 'L' }



package PLXML::op_splice;

@ISA = ('PLXML::listop');

sub key { 'splice' }
sub desc { 'splice' }
sub check { 'ck_fun' }
sub flags { 'm@' }
sub args { 'A S? S? L' }


package PLXML::op_push;

@ISA = ('PLXML::listop');

sub key { 'push' }
sub desc { 'push' }
sub check { 'ck_fun' }
sub flags { 'imsT@' }
sub args { 'A L' }


package PLXML::op_pop;

@ISA = ('PLXML::baseop_unop');

sub key { 'pop' }
sub desc { 'pop' }
sub check { 'ck_shift' }
sub flags { 's%' }
sub args { 'A?' }


package PLXML::op_shift;

@ISA = ('PLXML::baseop_unop');

sub key { 'shift' }
sub desc { 'shift' }
sub check { 'ck_shift' }
sub flags { 's%' }
sub args { 'A?' }


package PLXML::op_unshift;

@ISA = ('PLXML::listop');

sub key { 'unshift' }
sub desc { 'unshift' }
sub check { 'ck_fun' }
sub flags { 'imsT@' }
sub args { 'A L' }


package PLXML::op_sort;

@ISA = ('PLXML::listop');

sub key { 'sort' }
sub desc { 'sort' }
sub check { 'ck_sort' }
sub flags { 'm@' }
sub args { 'C? L' }


package PLXML::op_reverse;

@ISA = ('PLXML::listop');

sub key { 'reverse' }
sub desc { 'reverse' }
sub check { 'ck_fun' }
sub flags { 'mt@' }
sub args { 'L' }



package PLXML::op_grepstart;

@ISA = ('PLXML::listop');

sub key { 'grepstart' }
sub desc { 'grep' }
sub check { 'ck_grep' }
sub flags { 'dm@' }
sub args { 'C L' }


package PLXML::op_grepwhile;

@ISA = ('PLXML::logop');

sub key { 'grepwhile' }
sub desc { 'grep iterator' }
sub check { 'ck_null' }
sub flags { 'dt|' }
sub args { '' }



package PLXML::op_mapstart;

@ISA = ('PLXML::listop');

sub key { 'mapstart' }
sub desc { 'map' }
sub check { 'ck_grep' }
sub flags { 'dm@' }
sub args { 'C L' }


package PLXML::op_mapwhile;

@ISA = ('PLXML::logop');

sub key { 'mapwhile' }
sub desc { 'map iterator' }
sub check { 'ck_null' }
sub flags { 'dt|' }
sub args { '' }



# Range stuff.

package PLXML::op_range;

@ISA = ('PLXML::logop');

sub key { 'range' }
sub desc { 'flipflop' }
sub check { 'ck_null' }
sub flags { '|' }
sub args { 'S S' }


package PLXML::op_flip;

@ISA = ('PLXML::unop');

sub key { 'flip' }
sub desc { 'range (or flip)' }
sub check { 'ck_null' }
sub flags { '1' }
sub args { 'S S' }


package PLXML::op_flop;

@ISA = ('PLXML::unop');

sub key { 'flop' }
sub desc { 'range (or flop)' }
sub check { 'ck_null' }
sub flags { '1' }
sub args { '' }



# Control.

package PLXML::op_and;

@ISA = ('PLXML::logop');

sub key { 'and' }
sub desc { 'logical and (&&)' }
sub check { 'ck_null' }
sub flags { '|' }
sub args { '' }


package PLXML::op_or;

@ISA = ('PLXML::logop');

sub key { 'or' }
sub desc { 'logical or (||)' }
sub check { 'ck_null' }
sub flags { '|' }
sub args { '' }


package PLXML::op_xor;

@ISA = ('PLXML::binop');

sub key { 'xor' }
sub desc { 'logical xor' }
sub check { 'ck_null' }
sub flags { 'fs2' }
sub args { 'S S	' }


package PLXML::op_cond_expr;

@ISA = ('PLXML::logop');

sub key { 'cond_expr' }
sub desc { 'conditional expression' }
sub check { 'ck_null' }
sub flags { 'd|' }
sub args { '' }


package PLXML::op_andassign;

@ISA = ('PLXML::logop');

sub key { 'andassign' }
sub desc { 'logical and assignment (&&=)' }
sub check { 'ck_null' }
sub flags { 's|' }
sub args { '' }


package PLXML::op_orassign;

@ISA = ('PLXML::logop');

sub key { 'orassign' }
sub desc { 'logical or assignment (||=)' }
sub check { 'ck_null' }
sub flags { 's|' }
sub args { '' }



package PLXML::op_method;

@ISA = ('PLXML::unop');

sub key { 'method' }
sub desc { 'method lookup' }
sub check { 'ck_method' }
sub flags { 'd1' }
sub args { '' }


package PLXML::op_entersub;

@ISA = ('PLXML::unop');

sub key { 'entersub' }
sub desc { 'subroutine entry' }
sub check { 'ck_subr' }
sub flags { 'dmt1' }
sub args { 'L' }


package PLXML::op_leavesub;

@ISA = ('PLXML::unop');

sub key { 'leavesub' }
sub desc { 'subroutine exit' }
sub check { 'ck_null' }
sub flags { '1' }
sub args { '' }


package PLXML::op_leavesublv;

@ISA = ('PLXML::unop');

sub key { 'leavesublv' }
sub desc { 'lvalue subroutine return' }
sub check { 'ck_null' }
sub flags { '1' }
sub args { '' }


package PLXML::op_caller;

@ISA = ('PLXML::baseop_unop');

sub key { 'caller' }
sub desc { 'caller' }
sub check { 'ck_fun' }
sub flags { 't%' }
sub args { 'S?' }


package PLXML::op_warn;

@ISA = ('PLXML::listop');

sub key { 'warn' }
sub desc { 'warn' }
sub check { 'ck_fun' }
sub flags { 'imst@' }
sub args { 'L' }


package PLXML::op_die;

@ISA = ('PLXML::listop');

sub key { 'die' }
sub desc { 'die' }
sub check { 'ck_die' }
sub flags { 'dimst@' }
sub args { 'L' }


package PLXML::op_reset;

@ISA = ('PLXML::baseop_unop');

sub key { 'reset' }
sub desc { 'symbol reset' }
sub check { 'ck_fun' }
sub flags { 'is%' }
sub args { 'S?' }



package PLXML::op_lineseq;

@ISA = ('PLXML::listop');

sub key { 'lineseq' }
sub desc { 'line sequence' }
sub check { 'ck_null' }
sub flags { '@' }
sub args { '' }


package PLXML::op_nextstate;

@ISA = ('PLXML::cop');

sub key { 'nextstate' }
sub desc { 'next statement' }
sub check { 'ck_null' }
sub flags { 's;' }
sub args { '' }


package PLXML::op_dbstate;

@ISA = ('PLXML::cop');

sub key { 'dbstate' }
sub desc { 'debug next statement' }
sub check { 'ck_null' }
sub flags { 's;' }
sub args { '' }


package PLXML::op_unstack;

@ISA = ('PLXML::baseop');

sub key { 'unstack' }
sub desc { 'iteration finalizer' }
sub check { 'ck_null' }
sub flags { 's0' }
sub args { '' }


package PLXML::op_enter;

@ISA = ('PLXML::baseop');

sub key { 'enter' }
sub desc { 'block entry' }
sub check { 'ck_null' }
sub flags { '0' }
sub args { '' }


package PLXML::op_leave;

@ISA = ('PLXML::listop');

sub key { 'leave' }
sub desc { 'block exit' }
sub check { 'ck_null' }
sub flags { '@' }
sub args { '' }


package PLXML::op_scope;

@ISA = ('PLXML::listop');

sub key { 'scope' }
sub desc { 'block' }
sub check { 'ck_null' }
sub flags { '@' }
sub args { '' }


package PLXML::op_enteriter;

@ISA = ('PLXML::loop');

sub key { 'enteriter' }
sub desc { 'foreach loop entry' }
sub check { 'ck_null' }
sub flags { 'd{' }
sub args { '' }


package PLXML::op_iter;

@ISA = ('PLXML::baseop');

sub key { 'iter' }
sub desc { 'foreach loop iterator' }
sub check { 'ck_null' }
sub flags { '0' }
sub args { '' }


package PLXML::op_enterloop;

@ISA = ('PLXML::loop');

sub key { 'enterloop' }
sub desc { 'loop entry' }
sub check { 'ck_null' }
sub flags { 'd{' }
sub args { '' }


package PLXML::op_leaveloop;

@ISA = ('PLXML::binop');

sub key { 'leaveloop' }
sub desc { 'loop exit' }
sub check { 'ck_null' }
sub flags { '2' }
sub args { '' }


package PLXML::op_return;

@ISA = ('PLXML::listop');

sub key { 'return' }
sub desc { 'return' }
sub check { 'ck_return' }
sub flags { 'dm@' }
sub args { 'L' }


package PLXML::op_last;

@ISA = ('PLXML::loopexop');

sub key { 'last' }
sub desc { 'last' }
sub check { 'ck_null' }
sub flags { 'ds}' }
sub args { '' }


package PLXML::op_next;

@ISA = ('PLXML::loopexop');

sub key { 'next' }
sub desc { 'next' }
sub check { 'ck_null' }
sub flags { 'ds}' }
sub args { '' }


package PLXML::op_redo;

@ISA = ('PLXML::loopexop');

sub key { 'redo' }
sub desc { 'redo' }
sub check { 'ck_null' }
sub flags { 'ds}' }
sub args { '' }


package PLXML::op_dump;

@ISA = ('PLXML::loopexop');

sub key { 'dump' }
sub desc { 'dump' }
sub check { 'ck_null' }
sub flags { 'ds}' }
sub args { '' }


package PLXML::op_goto;

@ISA = ('PLXML::loopexop');

sub key { 'goto' }
sub desc { 'goto' }
sub check { 'ck_null' }
sub flags { 'ds}' }
sub args { '' }


package PLXML::op_exit;

@ISA = ('PLXML::baseop_unop');

sub key { 'exit' }
sub desc { 'exit' }
sub check { 'ck_exit' }
sub flags { 'ds%' }
sub args { 'S?' }


# continued below

#nswitch	numeric switch		ck_null		d	
#cswitch	character switch	ck_null		d	

# I/O.

package PLXML::op_open;

@ISA = ('PLXML::listop');

sub key { 'open' }
sub desc { 'open' }
sub check { 'ck_open' }
sub flags { 'ismt@' }
sub args { 'F S? L' }


package PLXML::op_close;

@ISA = ('PLXML::baseop_unop');

sub key { 'close' }
sub desc { 'close' }
sub check { 'ck_fun' }
sub flags { 'is%' }
sub args { 'F?' }


package PLXML::op_pipe_op;

@ISA = ('PLXML::listop');

sub key { 'pipe_op' }
sub desc { 'pipe' }
sub check { 'ck_fun' }
sub flags { 'is@' }
sub args { 'F F' }



package PLXML::op_fileno;

@ISA = ('PLXML::baseop_unop');

sub key { 'fileno' }
sub desc { 'fileno' }
sub check { 'ck_fun' }
sub flags { 'ist%' }
sub args { 'F' }


package PLXML::op_umask;

@ISA = ('PLXML::baseop_unop');

sub key { 'umask' }
sub desc { 'umask' }
sub check { 'ck_fun' }
sub flags { 'ist%' }
sub args { 'S?' }


package PLXML::op_binmode;

@ISA = ('PLXML::listop');

sub key { 'binmode' }
sub desc { 'binmode' }
sub check { 'ck_fun' }
sub flags { 's@' }
sub args { 'F S?' }



package PLXML::op_tie;

@ISA = ('PLXML::listop');

sub key { 'tie' }
sub desc { 'tie' }
sub check { 'ck_fun' }
sub flags { 'idms@' }
sub args { 'R S L' }


package PLXML::op_untie;

@ISA = ('PLXML::baseop_unop');

sub key { 'untie' }
sub desc { 'untie' }
sub check { 'ck_fun' }
sub flags { 'is%' }
sub args { 'R' }


package PLXML::op_tied;

@ISA = ('PLXML::baseop_unop');

sub key { 'tied' }
sub desc { 'tied' }
sub check { 'ck_fun' }
sub flags { 's%' }
sub args { 'R' }


package PLXML::op_dbmopen;

@ISA = ('PLXML::listop');

sub key { 'dbmopen' }
sub desc { 'dbmopen' }
sub check { 'ck_fun' }
sub flags { 'is@' }
sub args { 'H S S' }


package PLXML::op_dbmclose;

@ISA = ('PLXML::baseop_unop');

sub key { 'dbmclose' }
sub desc { 'dbmclose' }
sub check { 'ck_fun' }
sub flags { 'is%' }
sub args { 'H' }



package PLXML::op_sselect;

@ISA = ('PLXML::listop');

sub key { 'sselect' }
sub desc { 'select system call' }
sub check { 'ck_select' }
sub flags { 't@' }
sub args { 'S S S S' }


package PLXML::op_select;

@ISA = ('PLXML::listop');

sub key { 'select' }
sub desc { 'select' }
sub check { 'ck_select' }
sub flags { 'st@' }
sub args { 'F?' }



package PLXML::op_getc;

@ISA = ('PLXML::baseop_unop');

sub key { 'getc' }
sub desc { 'getc' }
sub check { 'ck_eof' }
sub flags { 'st%' }
sub args { 'F?' }


package PLXML::op_read;

@ISA = ('PLXML::listop');

sub key { 'read' }
sub desc { 'read' }
sub check { 'ck_fun' }
sub flags { 'imst@' }
sub args { 'F R S S?' }


package PLXML::op_enterwrite;

@ISA = ('PLXML::baseop_unop');

sub key { 'enterwrite' }
sub desc { 'write' }
sub check { 'ck_fun' }
sub flags { 'dis%' }
sub args { 'F?' }


package PLXML::op_leavewrite;

@ISA = ('PLXML::unop');

sub key { 'leavewrite' }
sub desc { 'write exit' }
sub check { 'ck_null' }
sub flags { '1' }
sub args { '' }



package PLXML::op_prtf;

@ISA = ('PLXML::listop');

sub key { 'prtf' }
sub desc { 'printf' }
sub check { 'ck_listiob' }
sub flags { 'ims@' }
sub args { 'F? L' }


package PLXML::op_print;

@ISA = ('PLXML::listop');

sub key { 'print' }
sub desc { 'print' }
sub check { 'ck_listiob' }
sub flags { 'ims@' }
sub args { 'F? L' }



package PLXML::op_sysopen;

@ISA = ('PLXML::listop');

sub key { 'sysopen' }
sub desc { 'sysopen' }
sub check { 'ck_fun' }
sub flags { 's@' }
sub args { 'F S S S?' }


package PLXML::op_sysseek;

@ISA = ('PLXML::listop');

sub key { 'sysseek' }
sub desc { 'sysseek' }
sub check { 'ck_fun' }
sub flags { 's@' }
sub args { 'F S S' }


package PLXML::op_sysread;

@ISA = ('PLXML::listop');

sub key { 'sysread' }
sub desc { 'sysread' }
sub check { 'ck_fun' }
sub flags { 'imst@' }
sub args { 'F R S S?' }


package PLXML::op_syswrite;

@ISA = ('PLXML::listop');

sub key { 'syswrite' }
sub desc { 'syswrite' }
sub check { 'ck_fun' }
sub flags { 'imst@' }
sub args { 'F S S? S?' }



package PLXML::op_send;

@ISA = ('PLXML::listop');

sub key { 'send' }
sub desc { 'send' }
sub check { 'ck_fun' }
sub flags { 'imst@' }
sub args { 'Fs S S S?' }


package PLXML::op_recv;

@ISA = ('PLXML::listop');

sub key { 'recv' }
sub desc { 'recv' }
sub check { 'ck_fun' }
sub flags { 'imst@' }
sub args { 'Fs R S S' }



package PLXML::op_eof;

@ISA = ('PLXML::baseop_unop');

sub key { 'eof' }
sub desc { 'eof' }
sub check { 'ck_eof' }
sub flags { 'is%' }
sub args { 'F?' }


package PLXML::op_tell;

@ISA = ('PLXML::baseop_unop');

sub key { 'tell' }
sub desc { 'tell' }
sub check { 'ck_fun' }
sub flags { 'st%' }
sub args { 'F?' }


package PLXML::op_seek;

@ISA = ('PLXML::listop');

sub key { 'seek' }
sub desc { 'seek' }
sub check { 'ck_fun' }
sub flags { 's@' }
sub args { 'F S S' }


# truncate really behaves as if it had both "S S" and "F S"
package PLXML::op_truncate;

@ISA = ('PLXML::listop');

sub key { 'truncate' }
sub desc { 'truncate' }
sub check { 'ck_trunc' }
sub flags { 'is@' }
sub args { 'S S' }



package PLXML::op_fcntl;

@ISA = ('PLXML::listop');

sub key { 'fcntl' }
sub desc { 'fcntl' }
sub check { 'ck_fun' }
sub flags { 'st@' }
sub args { 'F S S' }


package PLXML::op_ioctl;

@ISA = ('PLXML::listop');

sub key { 'ioctl' }
sub desc { 'ioctl' }
sub check { 'ck_fun' }
sub flags { 'st@' }
sub args { 'F S S' }


package PLXML::op_flock;

@ISA = ('PLXML::listop');

sub key { 'flock' }
sub desc { 'flock' }
sub check { 'ck_fun' }
sub flags { 'isT@' }
sub args { 'F S' }



# Sockets.

package PLXML::op_socket;

@ISA = ('PLXML::listop');

sub key { 'socket' }
sub desc { 'socket' }
sub check { 'ck_fun' }
sub flags { 'is@' }
sub args { 'Fs S S S' }


package PLXML::op_sockpair;

@ISA = ('PLXML::listop');

sub key { 'sockpair' }
sub desc { 'socketpair' }
sub check { 'ck_fun' }
sub flags { 'is@' }
sub args { 'Fs Fs S S S' }



package PLXML::op_bind;

@ISA = ('PLXML::listop');

sub key { 'bind' }
sub desc { 'bind' }
sub check { 'ck_fun' }
sub flags { 'is@' }
sub args { 'Fs S' }


package PLXML::op_connect;

@ISA = ('PLXML::listop');

sub key { 'connect' }
sub desc { 'connect' }
sub check { 'ck_fun' }
sub flags { 'is@' }
sub args { 'Fs S' }


package PLXML::op_listen;

@ISA = ('PLXML::listop');

sub key { 'listen' }
sub desc { 'listen' }
sub check { 'ck_fun' }
sub flags { 'is@' }
sub args { 'Fs S' }


package PLXML::op_accept;

@ISA = ('PLXML::listop');

sub key { 'accept' }
sub desc { 'accept' }
sub check { 'ck_fun' }
sub flags { 'ist@' }
sub args { 'Fs Fs' }


package PLXML::op_shutdown;

@ISA = ('PLXML::listop');

sub key { 'shutdown' }
sub desc { 'shutdown' }
sub check { 'ck_fun' }
sub flags { 'ist@' }
sub args { 'Fs S' }



package PLXML::op_gsockopt;

@ISA = ('PLXML::listop');

sub key { 'gsockopt' }
sub desc { 'getsockopt' }
sub check { 'ck_fun' }
sub flags { 'is@' }
sub args { 'Fs S S' }


package PLXML::op_ssockopt;

@ISA = ('PLXML::listop');

sub key { 'ssockopt' }
sub desc { 'setsockopt' }
sub check { 'ck_fun' }
sub flags { 'is@' }
sub args { 'Fs S S S' }



package PLXML::op_getsockname;

@ISA = ('PLXML::baseop_unop');

sub key { 'getsockname' }
sub desc { 'getsockname' }
sub check { 'ck_fun' }
sub flags { 'is%' }
sub args { 'Fs' }


package PLXML::op_getpeername;

@ISA = ('PLXML::baseop_unop');

sub key { 'getpeername' }
sub desc { 'getpeername' }
sub check { 'ck_fun' }
sub flags { 'is%' }
sub args { 'Fs' }



# Stat calls.

package PLXML::op_lstat;

@ISA = ('PLXML::filestatop');

sub key { 'lstat' }
sub desc { 'lstat' }
sub check { 'ck_ftst' }
sub flags { 'u-' }
sub args { 'F' }


package PLXML::op_stat;

@ISA = ('PLXML::filestatop');

sub key { 'stat' }
sub desc { 'stat' }
sub check { 'ck_ftst' }
sub flags { 'u-' }
sub args { 'F' }


package PLXML::op_ftrread;

@ISA = ('PLXML::filestatop');

sub key { 'ftrread' }
sub desc { '-R' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }


package PLXML::op_ftrwrite;

@ISA = ('PLXML::filestatop');

sub key { 'ftrwrite' }
sub desc { '-W' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }


package PLXML::op_ftrexec;

@ISA = ('PLXML::filestatop');

sub key { 'ftrexec' }
sub desc { '-X' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }


package PLXML::op_fteread;

@ISA = ('PLXML::filestatop');

sub key { 'fteread' }
sub desc { '-r' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }


package PLXML::op_ftewrite;

@ISA = ('PLXML::filestatop');

sub key { 'ftewrite' }
sub desc { '-w' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }


package PLXML::op_fteexec;

@ISA = ('PLXML::filestatop');

sub key { 'fteexec' }
sub desc { '-x' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }


package PLXML::op_ftis;

@ISA = ('PLXML::filestatop');

sub key { 'ftis' }
sub desc { '-e' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }


package PLXML::op_fteowned;

@ISA = ('PLXML::filestatop');

sub key { 'fteowned' }
sub desc { '-O' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }


package PLXML::op_ftrowned;

@ISA = ('PLXML::filestatop');

sub key { 'ftrowned' }
sub desc { '-o' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }


package PLXML::op_ftzero;

@ISA = ('PLXML::filestatop');

sub key { 'ftzero' }
sub desc { '-z' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }


package PLXML::op_ftsize;

@ISA = ('PLXML::filestatop');

sub key { 'ftsize' }
sub desc { '-s' }
sub check { 'ck_ftst' }
sub flags { 'istu-' }
sub args { 'F-' }


package PLXML::op_ftmtime;

@ISA = ('PLXML::filestatop');

sub key { 'ftmtime' }
sub desc { '-M' }
sub check { 'ck_ftst' }
sub flags { 'stu-' }
sub args { 'F-' }


package PLXML::op_ftatime;

@ISA = ('PLXML::filestatop');

sub key { 'ftatime' }
sub desc { '-A' }
sub check { 'ck_ftst' }
sub flags { 'stu-' }
sub args { 'F-' }


package PLXML::op_ftctime;

@ISA = ('PLXML::filestatop');

sub key { 'ftctime' }
sub desc { '-C' }
sub check { 'ck_ftst' }
sub flags { 'stu-' }
sub args { 'F-' }


package PLXML::op_ftsock;

@ISA = ('PLXML::filestatop');

sub key { 'ftsock' }
sub desc { '-S' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }


package PLXML::op_ftchr;

@ISA = ('PLXML::filestatop');

sub key { 'ftchr' }
sub desc { '-c' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }


package PLXML::op_ftblk;

@ISA = ('PLXML::filestatop');

sub key { 'ftblk' }
sub desc { '-b' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }


package PLXML::op_ftfile;

@ISA = ('PLXML::filestatop');

sub key { 'ftfile' }
sub desc { '-f' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }


package PLXML::op_ftdir;

@ISA = ('PLXML::filestatop');

sub key { 'ftdir' }
sub desc { '-d' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }


package PLXML::op_ftpipe;

@ISA = ('PLXML::filestatop');

sub key { 'ftpipe' }
sub desc { '-p' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }


package PLXML::op_ftlink;

@ISA = ('PLXML::filestatop');

sub key { 'ftlink' }
sub desc { '-l' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }


package PLXML::op_ftsuid;

@ISA = ('PLXML::filestatop');

sub key { 'ftsuid' }
sub desc { '-u' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }


package PLXML::op_ftsgid;

@ISA = ('PLXML::filestatop');

sub key { 'ftsgid' }
sub desc { '-g' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }


package PLXML::op_ftsvtx;

@ISA = ('PLXML::filestatop');

sub key { 'ftsvtx' }
sub desc { '-k' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }


package PLXML::op_fttty;

@ISA = ('PLXML::filestatop');

sub key { 'fttty' }
sub desc { '-t' }
sub check { 'ck_ftst' }
sub flags { 'is-' }
sub args { 'F-' }


package PLXML::op_fttext;

@ISA = ('PLXML::filestatop');

sub key { 'fttext' }
sub desc { '-T' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }


package PLXML::op_ftbinary;

@ISA = ('PLXML::filestatop');

sub key { 'ftbinary' }
sub desc { '-B' }
sub check { 'ck_ftst' }
sub flags { 'isu-' }
sub args { 'F-' }



# File calls.

package PLXML::op_chdir;

@ISA = ('PLXML::baseop_unop');

sub key { 'chdir' }
sub desc { 'chdir' }
sub check { 'ck_fun' }
sub flags { 'isT%' }
sub args { 'S?' }


package PLXML::op_chown;

@ISA = ('PLXML::listop');

sub key { 'chown' }
sub desc { 'chown' }
sub check { 'ck_fun' }
sub flags { 'imsT@' }
sub args { 'L' }


package PLXML::op_chroot;

@ISA = ('PLXML::baseop_unop');

sub key { 'chroot' }
sub desc { 'chroot' }
sub check { 'ck_fun' }
sub flags { 'isTu%' }
sub args { 'S?' }


package PLXML::op_unlink;

@ISA = ('PLXML::listop');

sub key { 'unlink' }
sub desc { 'unlink' }
sub check { 'ck_fun' }
sub flags { 'imsTu@' }
sub args { 'L' }


package PLXML::op_chmod;

@ISA = ('PLXML::listop');

sub key { 'chmod' }
sub desc { 'chmod' }
sub check { 'ck_fun' }
sub flags { 'imsT@' }
sub args { 'L' }


package PLXML::op_utime;

@ISA = ('PLXML::listop');

sub key { 'utime' }
sub desc { 'utime' }
sub check { 'ck_fun' }
sub flags { 'imsT@' }
sub args { 'L' }


package PLXML::op_rename;

@ISA = ('PLXML::listop');

sub key { 'rename' }
sub desc { 'rename' }
sub check { 'ck_fun' }
sub flags { 'isT@' }
sub args { 'S S' }


package PLXML::op_link;

@ISA = ('PLXML::listop');

sub key { 'link' }
sub desc { 'link' }
sub check { 'ck_fun' }
sub flags { 'isT@' }
sub args { 'S S' }


package PLXML::op_symlink;

@ISA = ('PLXML::listop');

sub key { 'symlink' }
sub desc { 'symlink' }
sub check { 'ck_fun' }
sub flags { 'isT@' }
sub args { 'S S' }


package PLXML::op_readlink;

@ISA = ('PLXML::baseop_unop');

sub key { 'readlink' }
sub desc { 'readlink' }
sub check { 'ck_fun' }
sub flags { 'stu%' }
sub args { 'S?' }


package PLXML::op_mkdir;

@ISA = ('PLXML::listop');

sub key { 'mkdir' }
sub desc { 'mkdir' }
sub check { 'ck_fun' }
sub flags { 'isT@' }
sub args { 'S S?' }


package PLXML::op_rmdir;

@ISA = ('PLXML::baseop_unop');

sub key { 'rmdir' }
sub desc { 'rmdir' }
sub check { 'ck_fun' }
sub flags { 'isTu%' }
sub args { 'S?' }



# Directory calls.

package PLXML::op_open_dir;

@ISA = ('PLXML::listop');

sub key { 'open_dir' }
sub desc { 'opendir' }
sub check { 'ck_fun' }
sub flags { 'is@' }
sub args { 'F S' }


package PLXML::op_readdir;

@ISA = ('PLXML::baseop_unop');

sub key { 'readdir' }
sub desc { 'readdir' }
sub check { 'ck_fun' }
sub flags { '%' }
sub args { 'F' }


package PLXML::op_telldir;

@ISA = ('PLXML::baseop_unop');

sub key { 'telldir' }
sub desc { 'telldir' }
sub check { 'ck_fun' }
sub flags { 'st%' }
sub args { 'F' }


package PLXML::op_seekdir;

@ISA = ('PLXML::listop');

sub key { 'seekdir' }
sub desc { 'seekdir' }
sub check { 'ck_fun' }
sub flags { 's@' }
sub args { 'F S' }


package PLXML::op_rewinddir;

@ISA = ('PLXML::baseop_unop');

sub key { 'rewinddir' }
sub desc { 'rewinddir' }
sub check { 'ck_fun' }
sub flags { 's%' }
sub args { 'F' }


package PLXML::op_closedir;

@ISA = ('PLXML::baseop_unop');

sub key { 'closedir' }
sub desc { 'closedir' }
sub check { 'ck_fun' }
sub flags { 'is%' }
sub args { 'F' }



# Process control.

package PLXML::op_fork;

@ISA = ('PLXML::baseop');

sub key { 'fork' }
sub desc { 'fork' }
sub check { 'ck_null' }
sub flags { 'ist0' }
sub args { '' }


package PLXML::op_wait;

@ISA = ('PLXML::baseop');

sub key { 'wait' }
sub desc { 'wait' }
sub check { 'ck_null' }
sub flags { 'isT0' }
sub args { '' }


package PLXML::op_waitpid;

@ISA = ('PLXML::listop');

sub key { 'waitpid' }
sub desc { 'waitpid' }
sub check { 'ck_fun' }
sub flags { 'isT@' }
sub args { 'S S' }


package PLXML::op_system;

@ISA = ('PLXML::listop');

sub key { 'system' }
sub desc { 'system' }
sub check { 'ck_exec' }
sub flags { 'imsT@' }
sub args { 'S? L' }


package PLXML::op_exec;

@ISA = ('PLXML::listop');

sub key { 'exec' }
sub desc { 'exec' }
sub check { 'ck_exec' }
sub flags { 'dimsT@' }
sub args { 'S? L' }


package PLXML::op_kill;

@ISA = ('PLXML::listop');

sub key { 'kill' }
sub desc { 'kill' }
sub check { 'ck_fun' }
sub flags { 'dimsT@' }
sub args { 'L' }


package PLXML::op_getppid;

@ISA = ('PLXML::baseop');

sub key { 'getppid' }
sub desc { 'getppid' }
sub check { 'ck_null' }
sub flags { 'isT0' }
sub args { '' }


package PLXML::op_getpgrp;

@ISA = ('PLXML::baseop_unop');

sub key { 'getpgrp' }
sub desc { 'getpgrp' }
sub check { 'ck_fun' }
sub flags { 'isT%' }
sub args { 'S?' }


package PLXML::op_setpgrp;

@ISA = ('PLXML::listop');

sub key { 'setpgrp' }
sub desc { 'setpgrp' }
sub check { 'ck_fun' }
sub flags { 'isT@' }
sub args { 'S? S?' }


package PLXML::op_getpriority;

@ISA = ('PLXML::listop');

sub key { 'getpriority' }
sub desc { 'getpriority' }
sub check { 'ck_fun' }
sub flags { 'isT@' }
sub args { 'S S' }


package PLXML::op_setpriority;

@ISA = ('PLXML::listop');

sub key { 'setpriority' }
sub desc { 'setpriority' }
sub check { 'ck_fun' }
sub flags { 'isT@' }
sub args { 'S S S' }



# Time calls.

# NOTE: MacOS patches the 'i' of time() away later when the interpreter
# is created because in MacOS time() is already returning times > 2**31-1,
# that is, non-integers.

package PLXML::op_time;

@ISA = ('PLXML::baseop');

sub key { 'time' }
sub desc { 'time' }
sub check { 'ck_null' }
sub flags { 'isT0' }
sub args { '' }


package PLXML::op_tms;

@ISA = ('PLXML::baseop');

sub key { 'tms' }
sub desc { 'times' }
sub check { 'ck_null' }
sub flags { '0' }
sub args { '' }


package PLXML::op_localtime;

@ISA = ('PLXML::baseop_unop');

sub key { 'localtime' }
sub desc { 'localtime' }
sub check { 'ck_fun' }
sub flags { 't%' }
sub args { 'S?' }


package PLXML::op_gmtime;

@ISA = ('PLXML::baseop_unop');

sub key { 'gmtime' }
sub desc { 'gmtime' }
sub check { 'ck_fun' }
sub flags { 't%' }
sub args { 'S?' }


package PLXML::op_alarm;

@ISA = ('PLXML::baseop_unop');

sub key { 'alarm' }
sub desc { 'alarm' }
sub check { 'ck_fun' }
sub flags { 'istu%' }
sub args { 'S?' }


package PLXML::op_sleep;

@ISA = ('PLXML::baseop_unop');

sub key { 'sleep' }
sub desc { 'sleep' }
sub check { 'ck_fun' }
sub flags { 'isT%' }
sub args { 'S?' }



# Shared memory.

package PLXML::op_shmget;

@ISA = ('PLXML::listop');

sub key { 'shmget' }
sub desc { 'shmget' }
sub check { 'ck_fun' }
sub flags { 'imst@' }
sub args { 'S S S' }


package PLXML::op_shmctl;

@ISA = ('PLXML::listop');

sub key { 'shmctl' }
sub desc { 'shmctl' }
sub check { 'ck_fun' }
sub flags { 'imst@' }
sub args { 'S S S' }


package PLXML::op_shmread;

@ISA = ('PLXML::listop');

sub key { 'shmread' }
sub desc { 'shmread' }
sub check { 'ck_fun' }
sub flags { 'imst@' }
sub args { 'S S S S' }


package PLXML::op_shmwrite;

@ISA = ('PLXML::listop');

sub key { 'shmwrite' }
sub desc { 'shmwrite' }
sub check { 'ck_fun' }
sub flags { 'imst@' }
sub args { 'S S S S' }



# Message passing.

package PLXML::op_msgget;

@ISA = ('PLXML::listop');

sub key { 'msgget' }
sub desc { 'msgget' }
sub check { 'ck_fun' }
sub flags { 'imst@' }
sub args { 'S S' }


package PLXML::op_msgctl;

@ISA = ('PLXML::listop');

sub key { 'msgctl' }
sub desc { 'msgctl' }
sub check { 'ck_fun' }
sub flags { 'imst@' }
sub args { 'S S S' }


package PLXML::op_msgsnd;

@ISA = ('PLXML::listop');

sub key { 'msgsnd' }
sub desc { 'msgsnd' }
sub check { 'ck_fun' }
sub flags { 'imst@' }
sub args { 'S S S' }


package PLXML::op_msgrcv;

@ISA = ('PLXML::listop');

sub key { 'msgrcv' }
sub desc { 'msgrcv' }
sub check { 'ck_fun' }
sub flags { 'imst@' }
sub args { 'S S S S S' }



# Semaphores.

package PLXML::op_semget;

@ISA = ('PLXML::listop');

sub key { 'semget' }
sub desc { 'semget' }
sub check { 'ck_fun' }
sub flags { 'imst@' }
sub args { 'S S S' }


package PLXML::op_semctl;

@ISA = ('PLXML::listop');

sub key { 'semctl' }
sub desc { 'semctl' }
sub check { 'ck_fun' }
sub flags { 'imst@' }
sub args { 'S S S S' }


package PLXML::op_semop;

@ISA = ('PLXML::listop');

sub key { 'semop' }
sub desc { 'semop' }
sub check { 'ck_fun' }
sub flags { 'imst@' }
sub args { 'S S' }



# Eval.

package PLXML::op_require;

@ISA = ('PLXML::baseop_unop');

sub key { 'require' }
sub desc { 'require' }
sub check { 'ck_require' }
sub flags { 'du%' }
sub args { 'S?' }


package PLXML::op_dofile;

@ISA = ('PLXML::unop');

sub key { 'dofile' }
sub desc { 'do "file"' }
sub check { 'ck_fun' }
sub flags { 'd1' }
sub args { 'S' }


package PLXML::op_entereval;

@ISA = ('PLXML::baseop_unop');

sub key { 'entereval' }
sub desc { 'eval "string"' }
sub check { 'ck_eval' }
sub flags { 'd%' }
sub args { 'S' }


package PLXML::op_leaveeval;

@ISA = ('PLXML::unop');

sub key { 'leaveeval' }
sub desc { 'eval "string" exit' }
sub check { 'ck_null' }
sub flags { '1' }
sub args { 'S' }


#evalonce	eval constant string	ck_null		d1	S
package PLXML::op_entertry;

@ISA = ('PLXML::logop');

sub key { 'entertry' }
sub desc { 'eval {block}' }
sub check { 'ck_null' }
sub flags { '|' }
sub args { '' }


package PLXML::op_leavetry;

@ISA = ('PLXML::listop');

sub key { 'leavetry' }
sub desc { 'eval {block} exit' }
sub check { 'ck_null' }
sub flags { '@' }
sub args { '' }



# Get system info.

package PLXML::op_ghbyname;

@ISA = ('PLXML::baseop_unop');

sub key { 'ghbyname' }
sub desc { 'gethostbyname' }
sub check { 'ck_fun' }
sub flags { '%' }
sub args { 'S' }


package PLXML::op_ghbyaddr;

@ISA = ('PLXML::listop');

sub key { 'ghbyaddr' }
sub desc { 'gethostbyaddr' }
sub check { 'ck_fun' }
sub flags { '@' }
sub args { 'S S' }


package PLXML::op_ghostent;

@ISA = ('PLXML::baseop');

sub key { 'ghostent' }
sub desc { 'gethostent' }
sub check { 'ck_null' }
sub flags { '0' }
sub args { '' }


package PLXML::op_gnbyname;

@ISA = ('PLXML::baseop_unop');

sub key { 'gnbyname' }
sub desc { 'getnetbyname' }
sub check { 'ck_fun' }
sub flags { '%' }
sub args { 'S' }


package PLXML::op_gnbyaddr;

@ISA = ('PLXML::listop');

sub key { 'gnbyaddr' }
sub desc { 'getnetbyaddr' }
sub check { 'ck_fun' }
sub flags { '@' }
sub args { 'S S' }


package PLXML::op_gnetent;

@ISA = ('PLXML::baseop');

sub key { 'gnetent' }
sub desc { 'getnetent' }
sub check { 'ck_null' }
sub flags { '0' }
sub args { '' }


package PLXML::op_gpbyname;

@ISA = ('PLXML::baseop_unop');

sub key { 'gpbyname' }
sub desc { 'getprotobyname' }
sub check { 'ck_fun' }
sub flags { '%' }
sub args { 'S' }


package PLXML::op_gpbynumber;

@ISA = ('PLXML::listop');

sub key { 'gpbynumber' }
sub desc { 'getprotobynumber' }
sub check { 'ck_fun' }
sub flags { '@' }
sub args { 'S' }


package PLXML::op_gprotoent;

@ISA = ('PLXML::baseop');

sub key { 'gprotoent' }
sub desc { 'getprotoent' }
sub check { 'ck_null' }
sub flags { '0' }
sub args { '' }


package PLXML::op_gsbyname;

@ISA = ('PLXML::listop');

sub key { 'gsbyname' }
sub desc { 'getservbyname' }
sub check { 'ck_fun' }
sub flags { '@' }
sub args { 'S S' }


package PLXML::op_gsbyport;

@ISA = ('PLXML::listop');

sub key { 'gsbyport' }
sub desc { 'getservbyport' }
sub check { 'ck_fun' }
sub flags { '@' }
sub args { 'S S' }


package PLXML::op_gservent;

@ISA = ('PLXML::baseop');

sub key { 'gservent' }
sub desc { 'getservent' }
sub check { 'ck_null' }
sub flags { '0' }
sub args { '' }


package PLXML::op_shostent;

@ISA = ('PLXML::baseop_unop');

sub key { 'shostent' }
sub desc { 'sethostent' }
sub check { 'ck_fun' }
sub flags { 'is%' }
sub args { 'S' }


package PLXML::op_snetent;

@ISA = ('PLXML::baseop_unop');

sub key { 'snetent' }
sub desc { 'setnetent' }
sub check { 'ck_fun' }
sub flags { 'is%' }
sub args { 'S' }


package PLXML::op_sprotoent;

@ISA = ('PLXML::baseop_unop');

sub key { 'sprotoent' }
sub desc { 'setprotoent' }
sub check { 'ck_fun' }
sub flags { 'is%' }
sub args { 'S' }


package PLXML::op_sservent;

@ISA = ('PLXML::baseop_unop');

sub key { 'sservent' }
sub desc { 'setservent' }
sub check { 'ck_fun' }
sub flags { 'is%' }
sub args { 'S' }


package PLXML::op_ehostent;

@ISA = ('PLXML::baseop');

sub key { 'ehostent' }
sub desc { 'endhostent' }
sub check { 'ck_null' }
sub flags { 'is0' }
sub args { '' }


package PLXML::op_enetent;

@ISA = ('PLXML::baseop');

sub key { 'enetent' }
sub desc { 'endnetent' }
sub check { 'ck_null' }
sub flags { 'is0' }
sub args { '' }


package PLXML::op_eprotoent;

@ISA = ('PLXML::baseop');

sub key { 'eprotoent' }
sub desc { 'endprotoent' }
sub check { 'ck_null' }
sub flags { 'is0' }
sub args { '' }


package PLXML::op_eservent;

@ISA = ('PLXML::baseop');

sub key { 'eservent' }
sub desc { 'endservent' }
sub check { 'ck_null' }
sub flags { 'is0' }
sub args { '' }


package PLXML::op_gpwnam;

@ISA = ('PLXML::baseop_unop');

sub key { 'gpwnam' }
sub desc { 'getpwnam' }
sub check { 'ck_fun' }
sub flags { '%' }
sub args { 'S' }


package PLXML::op_gpwuid;

@ISA = ('PLXML::baseop_unop');

sub key { 'gpwuid' }
sub desc { 'getpwuid' }
sub check { 'ck_fun' }
sub flags { '%' }
sub args { 'S' }


package PLXML::op_gpwent;

@ISA = ('PLXML::baseop');

sub key { 'gpwent' }
sub desc { 'getpwent' }
sub check { 'ck_null' }
sub flags { '0' }
sub args { '' }


package PLXML::op_spwent;

@ISA = ('PLXML::baseop');

sub key { 'spwent' }
sub desc { 'setpwent' }
sub check { 'ck_null' }
sub flags { 'is0' }
sub args { '' }


package PLXML::op_epwent;

@ISA = ('PLXML::baseop');

sub key { 'epwent' }
sub desc { 'endpwent' }
sub check { 'ck_null' }
sub flags { 'is0' }
sub args { '' }


package PLXML::op_ggrnam;

@ISA = ('PLXML::baseop_unop');

sub key { 'ggrnam' }
sub desc { 'getgrnam' }
sub check { 'ck_fun' }
sub flags { '%' }
sub args { 'S' }


package PLXML::op_ggrgid;

@ISA = ('PLXML::baseop_unop');

sub key { 'ggrgid' }
sub desc { 'getgrgid' }
sub check { 'ck_fun' }
sub flags { '%' }
sub args { 'S' }


package PLXML::op_ggrent;

@ISA = ('PLXML::baseop');

sub key { 'ggrent' }
sub desc { 'getgrent' }
sub check { 'ck_null' }
sub flags { '0' }
sub args { '' }


package PLXML::op_sgrent;

@ISA = ('PLXML::baseop');

sub key { 'sgrent' }
sub desc { 'setgrent' }
sub check { 'ck_null' }
sub flags { 'is0' }
sub args { '' }


package PLXML::op_egrent;

@ISA = ('PLXML::baseop');

sub key { 'egrent' }
sub desc { 'endgrent' }
sub check { 'ck_null' }
sub flags { 'is0' }
sub args { '' }


package PLXML::op_getlogin;

@ISA = ('PLXML::baseop');

sub key { 'getlogin' }
sub desc { 'getlogin' }
sub check { 'ck_null' }
sub flags { 'st0' }
sub args { '' }



# Miscellaneous.

package PLXML::op_syscall;

@ISA = ('PLXML::listop');

sub key { 'syscall' }
sub desc { 'syscall' }
sub check { 'ck_fun' }
sub flags { 'imst@' }
sub args { 'S L' }



# For multi-threading
package PLXML::op_lock;

@ISA = ('PLXML::baseop_unop');

sub key { 'lock' }
sub desc { 'lock' }
sub check { 'ck_rfun' }
sub flags { 's%' }
sub args { 'R' }


package PLXML::op_threadsv;

@ISA = ('PLXML::baseop');

sub key { 'threadsv' }
sub desc { 'per-thread value' }
sub check { 'ck_null' }
sub flags { 'ds0' }
sub args { '' }



# Control (contd.)
package PLXML::op_setstate;

@ISA = ('PLXML::cop');

sub key { 'setstate' }
sub desc { 'set statement info' }
sub check { 'ck_null' }
sub flags { 's;' }
sub args { '' }


package PLXML::op_method_named;

@ISA = ('PLXML::padop_svop');

sub key { 'method_named' }
sub desc { 'method with known name' }
sub check { 'ck_null' }
sub flags { 'd$' }
sub args { '' }



package PLXML::op_dor;

@ISA = ('PLXML::logop');

sub key { 'dor' }
sub desc { 'defined or (//)' }
sub check { 'ck_null' }
sub flags { '|' }
sub args { '' }


package PLXML::op_dorassign;

@ISA = ('PLXML::logop');

sub key { 'dorassign' }
sub desc { 'defined or assignment (//=)' }
sub check { 'ck_null' }
sub flags { 's|' }
sub args { '' }



# Add new ops before this, the custom operator.

package PLXML::op_custom;

@ISA = ('PLXML::baseop');

sub key { 'custom' }
sub desc { 'unknown custom operator' }
sub check { 'ck_null' }
sub flags { '0' }
sub args { '' }


