package UTF8::Matcher;
use strict;
use warnings;
use Text::Wrap qw(wrap);
use Encode;
use Data::Dumper;

our $hex_fmt="0x%02X";

# Author: Yves Orton (demerphq) 2007.

=pod

Dynamically generates macros for detecting special charclasses
in both latin-1, utf8, and codepoint forms.

To regenerate regcharclass.h, run this script from perl-root. No arguments
are necessary.

Each charclass handler is constructed as follows:
Each string the charclass must match  is rendered as unicode (codepoints>255),
and if possible  as latin1 (codepoints>127), and if possible as "neutral"
(all codepoints<128).

The rendered strings are then inserted into digit-tries by type and length.
With shorter strings being added to tries that are allowed to contain longer
strings, but not vice versa.  Thus the "longest" trie contains all strings
for that charclass.

The following types of trie are generated:

  n - Neutral only. All strings in this type have codepoints<128
  l - Latin1 only. All strings in this type have a codepoint>127 in them
  u - UTF8 only.   All strings in this type have a codepoint>255 in them
  L - Latin1. All strings in 'n' and 'l'
  U - UTF8.   All string in 'n' and 'u'
  c - Codepoint. All strings in U but in codepoint and not utf8 form.

The ternary() routine is responsible for converting the trie data into a
ternary conditional that matches the required set of strings. The generated
macro normally takes at least the argument 's' which is expected to be a
pointer of type C<char *> or C<U8 *>. The condition generated will be
optimised to match the string as efficiently as possible, with range lookups
being used where possible, and in some situations relying on "true" to be 1.

ternary() takes two optional arguments, $type which is one of the above
characters and $ext which is used to add an extra extension to the macro name.

If $type is omitted or false then the generated macro will take an additional
argument, 'is_utf8'.

If $ext has the string 'safe' in it then the generated macro will take an extra
argument 'e' for the end of the string, and all lookups will be length checked
to prevent lookups past e. If 'safe' is not used then the lookup is assumed to
be guaranteed safe, and no 'e' argument is provided  and no length checks are
made during execution.

The 'c' type is different as compared to the rest. Instead of producing
a condition that does octet comparisons of a string array, the 'c' type
produces a macro that takes a single codepoint as an argument (instead of a
char* or U8*) and does the lookup based on only that char, thus it cannot be
used to match multi-codepoint sequences like "\r\n" in the LNBREAK charclass.
This is primarily used for populating charclass bitmaps for codepoints 0..255
but will also match codepoints in the unicode range if necessary.

Using LNBREAK as an example the following macros will be produced:

=over 4

=item is_LNBREAK(s,is_utf8)

=item is_LNBREAK_safe(s,e,is_utf8)

Do a lookup as apporpriate based on the is_utf8 flag. When possible
comparisons involving octect<128 are done before checking the is_utf8
flag, hopefully saving time.

=item is_LNBREAK_utf8(s)

=item is_LNBREAK_utf8_safe(s,e)

Do a lookup assuming the string is encoded in (normalized) UTF8.

=item is_LNBREAK_latin1(s)

=item is_LNBREAK_latin1_safe(s,e)

Do a lookup assuming the string is encoded in latin-1 (aka plan octets).

=item is_LNBREAK_cp(cp)

Check to see if the string matches a given codepoint (hypotethically a
U32). The condition is constructed as as to "break out" as early as
possible if the codepoint is out of range of the condition.

IOW:

  (cp==X || (cp>X && (cp==Y || (cp>Y && ...))))

Thus if the character is X+1 only two comparisons will be done. Making
matching lookups slower, but non-matching faster.

=back

=cut

# store a list of numbers into a hash based trie.
sub _trie_store {
    my $root= shift;
    foreach my $b ( @_ ) {
        $root->{$b} ||= {};
        $root= $root->{$b};
    }
    $root->{''}++;
}

# Convert a string into its neutral, latin1, utf8 forms, where
# the form is undefined unless the string can be completely represented
# in that form. The string is then decomposed into the octects representing
# it. A list is returned for each. Additional a list of codepoints making
# up the string.
# returns (\@n,\@u,\@l,\@cp)
#
sub _uni_latin1 {
    my $str= shift;
    my $u= eval { Encode::encode( "utf8",       "$str", Encode::FB_CROAK ) };
    my $l= eval { Encode::encode( "iso-8859-1", "$str", Encode::FB_CROAK ) };
    my $n= $l;
    undef $n if defined( $n ) && $str =~ /[^\x00-\x7F]/;
    return ((map { $_ ? [ unpack "U0C*", $_ ] : $_ } ( $n, $u, $l )),
            [map { ord $_ } split //,$str]);
}

# store an array ref of char data into the appropriate
# type bins, tracking sizes as we go.
sub _store {
    my ( $self, $r, @k )= @_;
    for my $z ( @k ) {
        $self->{size}{$z}{ 0 + @$r }++;
        push @{ $self->{data}{$z} }, $r;
    }
}

# construct a new charclass constructor object.
# $title ends up in the code a as a comment.
# $opcode is the name of the operation the charclass implements.
# the rest of the arguments are strings that the charclass
# can match.
sub new {
    my $class= shift;
    my $title= shift;
    my $opcode= shift;
    my $self= bless { op => $opcode, title => $title }, $class;
    my %seen;
    # convert the strings to the numeric equivelents and store
    # them for later insertion while tracking their sizes.
    foreach my $seq ( @_ ) {
        next if $seen{$seq}++;
        push @{$self->{seq}},$seq;
        my ( $n, $u, $l,$cp )= _uni_latin1( $seq );
        if ( $n ) {
            _store( $self, $n, qw(n U L) );
        } else {
            if ( $l ) {
                _store( $self, $l, qw(l L) );
            }
            _store( $self, $u, qw(u U) );
        }
        _store($self,$cp,'c');
    }
    #
    # now construct the tries. For each type of data we insert
    # the data into all the tries of length $size and smaller.
    #

    my %allsize;
    foreach my $k ( keys %{ $self->{data} } ) {
        my @size= sort { $b <=> $a } keys %{ $self->{size}{$k} };
        $self->{size}{$k}=\@size;
        undef @allsize{@size};
        foreach my $d ( @{ $self->{data}{$k} } ) {
            foreach my $sz ( @size ) {
                last if $sz < @$d;
                $self->{trie}{$k}{$sz} ||= {};
                _trie_store( $self->{trie}{$k}{$sz}, @$d );
            }
        }
        #delete $self->{data}{$k};
    }
    my @size= sort { $b <=> $a } keys %allsize;
    $self->{size}{''}= \@size;
    return $self;
}

#
# _cond([$v1,$v2,$v2...],$ofs)
#
# converts an array of codepoints into a conditional expression
# consequtive codepoints are merged into a range test
# returns a string containing the conditional expression in the form
# '( li[x]==v || li[x]==y )' When possible we also use range lookups.

sub _cond {
    my ( $c, $ofs,$fmt )= @_;
    $fmt||='((U8*)s)[%d]';
    # cheapo rangification routine.
    # Convert the first element into a singleton represented
    # as [$x,$x] and then merge the rest in as we go.
    my @v= sort { $a <=> $b } @$c;
    my @r= ( [ ( shift @v ) x 2 ] );
    for my $n ( @v ) {
        if ( $n == $r[-1][1] + 1 ) {
            $r[-1][1]++;
        } else {
            push @r, [ $n, $n ];
        }
    }
    @r = map { $_->[0]==$_->[1]-1 ? ([$_->[0],$_->[0]],[$_->[1],$_->[1]]) : $_} @r;
    # sort the ranges by size and order.
    @r= sort { $a->[0] <=> $b->[0] }  @r;
    my $alu= sprintf $fmt,$ofs;    # C array look up

    if ($fmt=~/%d/) {
        # map the ranges into conditions
        @r= map {
            # singleton
            $_->[0] == $_->[1] ? sprintf("$alu == $hex_fmt",$_->[0]) :
            # range
            sprintf("($hex_fmt <= $alu && $alu <= $hex_fmt)",@$_)
        } @r;
        # return the joined results.
        return '( ' . join( " || ", @r ) . ' )';
    } else {
        return combine($alu,@r);
    }
}

#
# Do the condition in such a way that we break out early if the value
# we are looking at is in between two elements in the list.
# Currently used only for codepoint macros (depth 1)
#
sub combine {
    my $alu=shift;
    local $_ = shift;
    my $txt= $_->[0] == $_->[1]
           ? sprintf("$alu == $hex_fmt",$_->[0])
           : sprintf("($hex_fmt <= $alu && $alu <= $hex_fmt)",@$_);
    return $txt unless @_;
    return "( $txt || ( $alu > $_->[1] && \n".combine($alu,@_)." ) )";
}

# recursively convert a trie to an optree represented by
# [condition,yes,no] where  yes and no can be a ref to another optree
# or a scalar representing code.
# called by make_optree

sub _trie_to_optree {
    my ( $node, $ofs, $else, $fmt )= @_;
    return $else unless $node;
    $ofs ||= 0;
    if ( $node->{''} ) {
        $else= $ofs;
    } else {
        $else ||= 0;
    }
    my @k= sort { $b->[1] cmp $a->[1] || $a->[0] <=> $b->[0] }
      map { [ $_, Dumper( $node->{$_} ), $node->{$_} ] }
      grep length, keys %$node;

    return $ofs if !@k;

    my ( $root, $expr );
    while ( @k ) {
        my @cond= ( $k[0][0] );
        my $d= $k[0][1];
        my $r= $k[0][2];
        shift @k;
        while ( @k && $k[0][1] eq $d ) {
            push @cond, $k[0][0];
            shift @k;
        }
        my $op=
          [ _cond( \@cond, $ofs, $fmt ), _trie_to_optree( $r, $ofs + 1, $else, $fmt ) ];
        if ( !$root ) {
            $root= $expr= $op;
        } else {
            push @$expr, $op;
            $expr= $op;
        }
    }
    push @$expr, $else;
    return $root;
}

# construct the optree for a type.
# handles the special logic of type ''.
sub make_optree {
    my ( $self, $type, $size, $fmt )= @_;
    my $else= 0;
    $size||=$self->{size}{$type}[0];
    $size=1 if $type eq 'c';
    if ( !$type ) {
        my ( $u, $l );
        for ( my $sz= $size ; !$u && $sz > 0 ; $sz-- ) {
            $u= _trie_to_optree( $self->{trie}{u}{$sz}, 0, 0, $fmt );
        }
        for ( my $sz= $size ; !$l && $sz > 0 ; $sz-- ) {
            $l= _trie_to_optree( $self->{trie}{l}{$sz}, 0, 0, $fmt );
        }
        if ( $u ) {
            $else= [ '(is_utf8)', $u, $l || 0 ];
        } elsif ( $l ) {
            $else= [ '(!is_utf8)', $l, 0 ];
        }
        $type= 'n';
        $size-- while !$self->{trie}{n}{$size};
    }
    return _trie_to_optree( $self->{trie}{$type}{$size}, 0, $else, $fmt );
}

# construct the optree for a type with length checks to prevent buffer
# overruns. Only one length check is performed per lookup trading code
# size for speed.
sub length_optree {
    my ( $self, $type,$fmt )= @_;
    $type ||= '';
    return $self->{len_op}{$type} if $self->{len_op}{$type};
    my @size = @{$self->{size}{$type}};

    my ( $root, $expr );
    foreach my $size ( @size ) {
        my $op= [
            "( (e) - (s) > " . ( $size - 1 ) . " )",
            $self->make_optree( $type, $size ),
        ];
        if ( !$root ) {
            $root= $expr= $op;
        } else {
            push @$expr, $op;
            $expr= $op;
        }
    }
    push @$expr, 0;
    return $self->{len_op}{$type}= $root ? $root : $expr->[0];
}

#
# recursively walk an optree and covert it to a huge nested ternary expression.
#
sub _optree_to_ternary {
    my ( $node )= @_;
    return $node
      if !ref $node;
    my $depth = 0;
    if ( $node->[0] =~ /\[(\d+)\]/ ) {
        $depth= $1 + 1;
    }
    return sprintf "\n%s( %s ? %s : %s )", "  " x $depth, $node->[0],
      _optree_to_ternary( $node->[1] ), _optree_to_ternary( $node->[2] );
}

# add \\ to the end of strings in a reasonable neat way.
sub _macro($) {
    my $str= shift;
    my @lines= split /[^\S\n]*\n/, $str;
    my $macro = join( "\\\n", map { sprintf "%-76s", $_ } @lines );
    $macro =~ s/  *$//;
    return $macro . "\n\n";
}

# default type extensions. 'uln' dont have one because normally
# they are used only as part of type '' which doesnt get an extension
my %ext= (
    U => '_utf8',
    L => '_latin1',
    c => '_cp',

);

# produce the ternary, handling arguments and putting on the macro headers
# and boiler plate
sub ternary {
    my ( $self, $type, $ext )= @_;
    $type ||= '';
    $ext = ($ext{$type} || '') . ($ext||"");
    my ($root,$fmt,$arg);
    if ($type eq 'c') {
        $arg= $fmt= 'cp';
    } else {
        $arg= 's';
    }
    if ( $type eq 'c' || $ext !~ /safe/) {
        $root= $self->make_optree( $type, 0, $fmt );
    } else {
        $root= $self->length_optree( $type, $fmt );
    }

    our $parens;
    $parens= qr/ \( (?: (?> [^()]+? ) | (??{$parens}) )+? \) /x;
    my $expr= qr/
        \( \s*
        ($parens)
        \s* \? \s*
        \( \s*
        ($parens)
        \s* \? \s*
        (\d+|$parens)
        \s* : \s*
        (\d+|$parens)
        \s* \)
        \s* : \s*
        \4
        \s* \)
    /x;
    my $code= _optree_to_ternary( $root );
    for ( $code ) {
        s/^\s*//;
        1 while s/\(\s*($parens)\s*\?\s*1\s*:\s*0\s*\)/$1/g
          || s<$expr><(($1 && $2) ? $3 : $4)>g
          || s<\(\s*($parens)\s*\)><$1>g;
    }
    my @args=($arg);
    push @args,'e' if $ext=~/safe/;
    push @args,'is_utf8' if !$type;
    my $args=join ",",@args;
    return "/*** GENERATED CODE ***/\n"
          . _macro "#define is_$self->{op}$ext($args)\n$code";
}

my $path=shift @ARGV;
if (!$path) {
    $path= "regcharclass.h";
    if (!-e $path) { $path="../$path" }
    if (!-e $path) { die "Can't find regcharclass.h to update!\n" };
}

rename $path,"$path.bak";
open my $out_fh,">",$path
    or die "Can't write to '$path':$!";
binmode $out_fh; # want unix line endings even when run on win32.
my ($zero) = $0=~/([^\\\/]+)$/;
print $out_fh <<"HEADER";
/*  -*- buffer-read-only: t -*-
 *
 *    regcharclass.h
 *
 *    Copyright (C) 2007, by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!!
 * This file is built by Porting/$zero.
 * (Generated at: @{[ scalar gmtime ]} GMT)
 * Any changes made here will be lost!
 */

HEADER

my ($op,$title,@strs,@txt);
my $doit= sub {
    return unless $op;
    my $o= __PACKAGE__->new($title,$op,@strs);
    print $out_fh "/*\n\t$o->{op}: $o->{title}\n\n";
    print $out_fh join "\n",@txt,"*/","";
    for ('', 'U', 'L') {
        print $out_fh $o->ternary( $_ );
        print $out_fh $o->ternary( $_,'_safe' );
    }
    print $out_fh $o->ternary( 'c' );
};
while (<DATA>) {
    next unless /\S/;
    chomp;
    if (/^([A-Z]+)/) {
        $doit->();
        ($op,$title)=split /\s*:\s*/,$_,2;
        @txt=@strs=();
    } else {
        push @txt, "\t$_";
        s/#.*$//;
        if (/^0x/) {
            push @strs,map { chr $_ } eval $_;
        } elsif (/^[""'']/) {
            push @strs,eval $_;
        }
    }
}
$doit->();
print $out_fh "/* ex: set ro: */\n";
print "$path has been updated\n";

__DATA__
LNBREAK: Line Break: \R
"\x0D\x0A"      # CRLF - Network (Windows) line ending
0x0A            # LF  | LINE FEED
0x0B            # VT  | VERTICAL TAB
0x0C            # FF  | FORM FEED
0x0D            # CR  | CARRIAGE RETURN
0x85            # NEL | NEXT LINE
0x2028          # LINE SEPARATOR
0x2029          # PARAGRAPH SEPARATOR

HORIZWS: Horizontal Whitespace: \h \H
0x09            # HT
0x20            # SPACE
0xa0            # NBSP
0x1680          # OGHAM SPACE MARK
0x180e          # MONGOLIAN VOWEL SEPARATOR
0x2000          # EN QUAD
0x2001          # EM QUAD
0x2002          # EN SPACE
0x2003          # EM SPACE
0x2004          # THREE-PER-EM SPACE
0x2005          # FOUR-PER-EM SPACE
0x2006          # SIX-PER-EM SPACE
0x2007          # FIGURE SPACE
0x2008          # PUNCTUATION SPACE
0x2009          # THIN SPACE
0x200A          # HAIR SPACE
0x202f          # NARROW NO-BREAK SPACE
0x205f          # MEDIUM MATHEMATICAL SPACE
0x3000          # IDEOGRAPHIC SPACE

VERTWS: Vertical Whitespace: \v \V
0x0A            # LF
0x0B            # VT
0x0C            # FF
0x0D            # CR
0x85            # NEL
0x2028          # LINE SEPARATOR
0x2029          # PARAGRAPH SEPARATOR

