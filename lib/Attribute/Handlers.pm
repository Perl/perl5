package Attribute::Handlers;
use 5.006;
use Carp;
use warnings;
$VERSION = '0.61';
$DB::single=1;

sub findsym {
	my ($pkg, $ref, $type) = @_;
	$type ||= ref($ref);
        foreach my $sym ( values %{$pkg."::"} ) {
               return $sym if *{$sym}{$type} && *{$sym}{$type} == $ref;
	}
}

my %validtype = (
	VAR	=> [qw[SCALAR ARRAY HASH]],
        ANY	=> [qw[SCALAR ARRAY HASH CODE]],
        ""	=> [qw[SCALAR ARRAY HASH CODE]],
        SCALAR	=> [qw[SCALAR]],
        ARRAY	=> [qw[ARRAY]],
        HASH	=> [qw[HASH]],
        CODE	=> [qw[CODE]],
);
my %lastattr;
my @declarations;
my %raw;
my %sigil = (SCALAR=>'$', ARRAY=>'@', HASH=>'%');

sub usage {croak "Usage: use $_[0] autotie => {AttrName => TieClassName,...}"}

sub import {
    my $class = shift @_;
    while (@_) {
	my $cmd = shift;
        if ($cmd eq 'autotie') {
            my $mapping = shift;
	    usage $class unless ref($mapping) eq 'HASH';
	    while (my($attr, $tieclass) = each %$mapping) {
		usage $class unless $attr =~ m/^[a-z]\w*(::[a-z]\w*)*$/i
		                 && $tieclass =~ m/^[a-z]\w*(::[a-z]\w*)*$/i
		                 && eval "use base $tieclass; 1";
	        eval qq{
	            sub $attr : ATTR(VAR) {
			my (\$ref, \$data) = \@_[2,4];
			\$data = [ \$data ] unless ref \$data eq 'ARRAY';
			my \$type = ref \$ref;
			 (\$type eq 'SCALAR')? tie \$\$ref,'$tieclass',\@\$data
			:(\$type eq 'ARRAY') ? tie \@\$ref,'$tieclass',\@\$data
			:(\$type eq 'HASH')  ? tie \%\$ref,'$tieclass',\@\$data
			: die "Internal error: can't autotie \$type"
	            } 1
	        } or die "Internal error: $@";
	    }
        }
        else {
            croak "Can't understand $_"; 
        }
    }
}
sub resolve_lastattr {
	return unless $lastattr{ref};
	my $sym = findsym @lastattr{'pkg','ref'}
		or die "Internal error: $lastattr{pkg} symbol went missing";
	my $name = *{$sym}{NAME};
	warn "Declaration of $name attribute in package $lastattr{pkg} may clash with future reserved word\n"
		if $^W and $name !~ /[A-Z]/;
	foreach ( @{$validtype{$lastattr{type}}} ) {
		*{"$lastattr{pkg}::_ATTR_${_}_${name}"} = $lastattr{ref};
	}
	%lastattr = ();
}

sub AUTOLOAD {
	my ($class) = @_;
	$AUTOLOAD =~ /_ATTR_(.*?)_(.*)/ or
	    croak "Can't locate class method '$AUTOLOAD' via package '$class'";
	croak "Attribute handler '$2' doesn't handle $1 attributes";
}

sub DESTROY {}

my $builtin = qr/lvalue|method|locked/;

sub handler() {
	return sub {
	    resolve_lastattr;
	    my ($pkg, $ref, @attrs) = @_;
	    foreach (@attrs) {
		my ($attr, $data) = /^([a-z_]\w*)(?:[(](.*)[)])?$/i or next;
		if ($attr eq 'ATTR') {
			$data ||= "ANY";
			$raw{$ref} = $data =~ s/\s*,?\s*RAWDATA\s*,?\s*//;
			croak "Bad attribute type: ATTR($data)"
				unless $validtype{$data};
			%lastattr=(pkg=>$pkg,ref=>$ref,type=>$data);
		}
		else {
			my $handler = $pkg->can($attr);
			next unless $handler;
			push @declarations,
			     [$pkg, $ref, $attr, $data, $raw{$handler}];
		}
		$_ = undef;
	    }
	    return grep {defined && !/$builtin/} @attrs;
	}
}

*{"MODIFY_${_}_ATTRIBUTES"} = handler foreach @{$validtype{ANY}};
push @UNIVERSAL::ISA, 'Attribute::Handlers'
	unless grep /^Attribute::Handlers$/, @UNIVERSAL::ISA;

CHECK {
	resolve_lastattr;
	foreach (@declarations) {
		my ($pkg, $ref, $attr, $data, $raw) = @$_;
		my $type = ref $ref;
		my $sym = findsym($pkg, $ref);
		$sym ||= $type eq 'CODE' ? 'ANON' : 'LEXICAL';
		my $handler = "_ATTR_${type}_${attr}";
		no warnings;
		my $evaled = !$raw && eval("package $pkg; no warnings;
					    \$SIG{__WARN__}=sub{die}; [$data]");
		$data = ($evaled && $data =~ /^\s*\[/)  ? [$evaled]
		      : ($evaled)			? $evaled
		      :					  [$data];
		$pkg->$handler($sym, $ref, $attr, @$data>1? $data : $data->[0]);
	}
}

1;
__END__

=head1 NAME

Attribute::Handlers - Simpler definition of attribute handlers

=head1 VERSION

This document describes version 0.61 of Attribute::Handlers,
released May 10, 2001.

=head1 SYNOPSIS

	package MyClass;
	require v5.6.0;
	use Attribute::Handlers;
	no warnings 'redefine';


	sub Good : ATTR(SCALAR) {
		my ($package, $symbol, $referent, $attr, $data) = @_;

		# Invoked for any scalar variable with a :Good attribute,
		# provided the variable was declared in MyClass (or
		# a derived class) or typed to MyClass.

		# Do whatever to $referent here (executed in CHECK phase).
		...
	}

	sub Bad : ATTR(SCALAR) {
		# Invoked for any scalar variable with a :Bad attribute,
		# provided the variable was declared in MyClass (or
		# a derived class) or typed to MyClass.
		...
	}

	sub Good : ATTR(ARRAY) {
		# Invoked for any array variable with a :Good attribute,
		# provided the variable was declared in MyClass (or
		# a derived class) or typed to MyClass.
		...
	}

	sub Good : ATTR(HASH) {
		# Invoked for any hash variable with a :Good attribute,
		# provided the variable was declared in MyClass (or
		# a derived class) or typed to MyClass.
		...
	}

	sub Ugly : ATTR(CODE) {
		# Invoked for any subroutine declared in MyClass (or a 
		# derived class) with an :Ugly attribute.
		...
	}

	sub Omni : ATTR {
		# Invoked for any scalar, array, hash, or subroutine
		# with an :Omni attribute, provided the variable or
		# subroutine was declared in MyClass (or a derived class)
		# or the variable was typed to MyClass.
		# Use ref($_[2]) to determine what kind of referent it was.
		...
	}


	use Attribute::Handlers autotie => { Cycle => Tie::Cycle };

	my $next : Cycle(['A'..'Z']);


=head1 DESCRIPTION

This module, when inherited by a package, allows that package's class to
define attribute handler subroutines for specific attributes. Variables
and subroutines subsequently defined in that package, or in packages
derived from that package may be given attributes with the same names as
the attribute handler subroutines, which will then be called at the end
of the compilation phase (i.e. in a C<CHECK> block).

To create a handler, define it as a subroutine with the same name as
the desired attribute, and declare the subroutine itself with the  
attribute C<:ATTR>. For example:

	package LoudDecl;
	use Attribute::Handlers;

	sub Loud :ATTR {
		my ($package, $symbol, $referent, $attr, $data) = @_;
		print STDERR
			ref($referent), " ",
			*{$symbol}{NAME}, " ",
			"($referent) ", "was just declared ",
			"and ascribed the ${attr} attribute ",
			"with data ($data)\n";
	}

This creates an handler for the attribute C<:Loud> in the class LoudDecl.
Thereafter, any subroutine declared with a C<:Loud> attribute in the class
LoudDecl:

	package LoudDecl;

	sub foo: Loud {...}

causes the above handler to be invoked, and passed:

=over

=item [0]

the name of the package into which it was declared;

=item [1]

a reference to the symbol table entry (typeglob) containing the subroutine;

=item [2]

a reference to the subroutine;

=item [3]

the name of the attribute;

=item [4]

any data associated with that attribute.

=back

Likewise, declaring any variables with the C<:Loud> attribute within the
package:

	package LoudDecl;

	my $foo :Loud;
	my @foo :Loud;
	my %foo :Loud;

will cause the handler to be called with a similar argument list (except,
of course, that C<$_[2]> will be a reference to the variable).

The package name argument will typically be the name of the class into
which the subroutine was declared, but it may also be the name of a derived
class (since handlers are inherited).

If a lexical variable is given an attribute, there is no symbol table to 
which it belongs, so the symbol table argument (C<$_[1]>) is set to the
string C<'LEXICAL'> in that case. Likewise, ascribing an attribute to
an anonymous subroutine results in a symbol table argument of C<'ANON'>.

The data argument passes in the value (if any) associated with the 
attribute. For example, if C<&foo> had been declared:

	sub foo :Loud("turn it up to 11, man!") {...}

then the string C<"turn it up to 11, man!"> would be passed as the
last argument.

Attribute::Handlers makes strenuous efforts to convert
the data argument (C<$_[4]>) to a useable form before passing it to
the handler (but see L<"Non-interpretive attribute handlers">).
For example, all of these:

	sub foo :Loud(till=>ears=>are=>bleeding) {...}
	sub foo :Loud(['till','ears','are','bleeding']) {...}
	sub foo :Loud(qw/till ears are bleeding/) {...}
	sub foo :Loud(qw/my, ears, are, bleeding/) {...}
	sub foo :Loud(till,ears,are,bleeding) {...}

causes it to pass C<['till','ears','are','bleeding']> as the handler's
data argument. However, if the data can't be parsed as valid Perl, then
it is passed as an uninterpreted string. For example:

	sub foo :Loud(my,ears,are,bleeding) {...}
	sub foo :Loud(qw/my ears are bleeding) {...}

cause the strings C<'my,ears,are,bleeding'> and C<'qw/my ears are bleeding'>
respectively to be passed as the data argument.

If the attribute has only a single associated scalar data value, that value is
passed as a scalar. If multiple values are associated, they are passed as an
array reference. If no value is associated with the attribute, C<undef> is
passed.


=head2 Typed lexicals

Regardless of the package in which it is declared, if a lexical variable is
ascribed an attribute, the handler that is invoked is the one belonging to
the package to which it is typed. For example, the following declarations:

	package OtherClass;

	my LoudDecl $loudobj : Loud;
	my LoudDecl @loudobjs : Loud;
	my LoudDecl %loudobjex : Loud;

causes the LoudDecl::Loud handler to be invoked (even if OtherClass also
defines a handler for C<:Loud> attributes).


=head2 Type-specific attribute handlers

If an attribute handler is declared and the C<:ATTR> specifier is
given the name of a built-in type (C<SCALAR>, C<ARRAY>, C<HASH>, or C<CODE>),
the handler is only applied to declarations of that type. For example,
the following definition:

	package LoudDecl;

	sub RealLoud :ATTR(SCALAR) { print "Yeeeeow!" }

creates an attribute handler that applies only to scalars:


	package Painful;
	use base LoudDecl;

	my $metal : RealLoud;		# invokes &LoudDecl::RealLoud
	my @metal : RealLoud;		# error: unknown attribute
	my %metal : RealLoud;		# error: unknown attribute
	sub metal : RealLoud {...}	# error: unknown attribute

You can, of course, declare separate handlers for these types as well
(but you'll need to specify C<no warnings 'redefine'> to do it quietly):

	package LoudDecl;
	use Attribute::Handlers;
	no warnings 'redefine';

	sub RealLoud :ATTR(SCALAR) { print "Yeeeeow!" }
	sub RealLoud :ATTR(ARRAY) { print "Urrrrrrrrrr!" }
	sub RealLoud :ATTR(HASH) { print "Arrrrrgggghhhhhh!" }
	sub RealLoud :ATTR(CODE) { croak "Real loud sub torpedoed" }

You can also explicitly indicate that a single handler is meant to be
used for all types of referents like so:

	package LoudDecl;
	use Attribute::Handlers;

	sub SeriousLoud :ATTR(ANY) { warn "Hearing loss imminent" }

(I.e. C<ATTR(ANY)> is a synonym for C<:ATTR>).


=head2 Non-interpretive attribute handlers

Occasionally the strenuous efforts Attribute::Handlers makes to convert
the data argument (C<$_[4]>) to a useable form before passing it to
the handler get in the way.

You can turn off that eagerness-to-help by declaring
an attribute handler with the the keyword C<RAWDATA>. For example:

	sub Raw          : ATTR(RAWDATA) {...}
	sub Nekkid       : ATTR(SCALAR,RAWDATA) {...}
	sub Au::Naturale : ATTR(RAWDATA,ANY) {...}

Then the handler makes absolutely no attempt to interpret the data it
receives and simply passes it as a string:

	my $power : Raw(1..100);	# handlers receives "1..100"


=head2 Attributes as C<tie> interfaces

Attributes make an excellent and intuitive interface through which to tie
variables. For example:

        use Attribute::Handlers;
        use Tie::Cycle;

        sub UNIVERSAL::Cycle : ATTR(SCALAR) {
                my ($package, $symbol, $referent, $attr, $data) = @_;
                $data = [ $data ] unless ref $data eq 'ARRAY';
                tie $$referent, 'Tie::Cycle', $data;
        }

        # and thereafter...

        package main;

        my $next : Cycle('A'..'Z');	# $next is now a tied variable

        while (<>) {
                print $next;
        }

In fact, this pattern is so widely applicable that Attribute::Handlers
provides a way to automate it: specifying C<'autotie'> in the
C<use Attribute::Handlers> statement. So, the previous example,
could also be written:

        use Attribute::Handlers autotie => { Cycle => 'Tie::Cycle' };

        # and thereafter...

        package main;

        my $next : Cycle('A'..'Z');	# $next is now a tied variable

        while (<>) {
                print $next;

The argument after C<'autotie'> is a reference to a hash in which each key is
the name of an attribute to be created, and each value is the class to which
variables ascribed that attribute should be tied.

Note that there is no longer any need to import the Tie::Cycle module --
Attribute::Handlers takes care of that automagically.

If the attribute name is unqualified, the attribute is installed in the
current package. Otherwise it is installed in the qualifier's package:


        package Here;

        use Attribute::Handlers autotie => {
                Other::Good => Tie::SecureHash, # tie attr installed in Other::
                        Bad => Tie::Taxes,      # tie attr installed in Here::
            UNIVERSAL::Ugly => Software::Patent # tie attr installed everywhere
        };


=head1 EXAMPLES

If the class shown in L<SYNOPSIS> were placed in the MyClass.pm
module, then the following code:

        package main;
        use MyClass;

        my MyClass $slr :Good :Bad(1**1-1) :Omni(-vorous);

        package SomeOtherClass;
        use base MyClass;

        sub tent { 'acle' }

        sub fn :Ugly(sister) :Omni('po',tent()) {...}
        my @arr :Good :Omni(s/cie/nt/);
        my %hsh :Good(q/bye) :Omni(q/bus/);


would cause the following handlers to be invoked:

        # my MyClass $slr :Good :Bad(1**1-1) :Omni(-vorous);

        MyClass::Good:ATTR(SCALAR)( 'MyClass',          # class
                                    'LEXICAL',          # no typeglob
                                    \$slr,              # referent
                                    'Good',             # attr name
                                    undef               # no attr data
                                  );

        MyClass::Bad:ATTR(SCALAR)( 'MyClass',           # class
                                   'LEXICAL',           # no typeglob
                                   \$slr,               # referent
                                   'Bad',               # attr name
                                   0                    # eval'd attr data
                                 );

        MyClass::Omni:ATTR(SCALAR)( 'MyClass',          # class
                                    'LEXICAL',          # no typeglob
                                    \$slr,              # referent
                                    'Omni',             # attr name
                                    '-vorous'           # eval'd attr data
                                  );


        # sub fn :Ugly(sister) :Omni('po',tent()) {...}

        MyClass::UGLY:ATTR(CODE)( 'SomeOtherClass',     # class
                                  \*SomeOtherClass::fn, # typeglob
                                  \&SomeOtherClass::fn, # referent
                                  'Ugly',               # attr name
                                  'sister'              # eval'd attr data
                                );

        MyClass::Omni:ATTR(CODE)( 'SomeOtherClass',     # class
                                  \*SomeOtherClass::fn, # typeglob
                                  \&SomeOtherClass::fn, # referent
                                  'Omni',               # attr name
                                  ['po','acle']         # eval'd attr data
                                );


        # my @arr :Good :Omni(s/cie/nt/);

        MyClass::Good:ATTR(ARRAY)( 'SomeOtherClass',    # class
                                   'LEXICAL',           # no typeglob
                                   \@arr,               # referent
                                   'Good',              # attr name
                                   undef                # no attr data
                                 );

        MyClass::Omni:ATTR(ARRAY)( 'SomeOtherClass',    # class
                                   'LEXICAL',           # no typeglob
                                   \@arr,               # referent
                                   'Omni',              # attr name
                                   ""                   # eval'd attr data 
                                 );


        # my %hsh :Good(q/bye) :Omni(q/bus/);
                                  
        MyClass::Good:ATTR(HASH)( 'SomeOtherClass',     # class
                                  'LEXICAL',            # no typeglob
                                  \%hsh,                # referent
                                  'Good',               # attr name
                                  'q/bye'               # raw attr data
                                );
                        
        MyClass::Omni:ATTR(HASH)( 'SomeOtherClass',     # class
                                  'LEXICAL',            # no typeglob
                                  \%hsh,                # referent
                                  'Omni',               # attr name
                                  'bus'                 # eval'd attr data
                                );


Installing handlers into UNIVERSAL, makes them...err..universal.
For example:

	package Descriptions;
	use Attribute::Handlers;

	my %name;
	sub name { return $name{$_[2]}||*{$_[1]}{NAME} }

	sub UNIVERSAL::Name :ATTR {
		$name{$_[2]} = $_[4];
	}

	sub UNIVERSAL::Purpose :ATTR {
		print STDERR "Purpose of ", &name, " is $_[4]\n";
	}

	sub UNIVERSAL::Unit :ATTR {
		print STDERR &name, " measured in $_[4]\n";
	}

Let's you write:

	use Descriptions;

	my $capacity : Name(capacity)
		     : Purpose(to store max storage capacity for files)
		     : Unit(Gb);


	package Other;

	sub foo : Purpose(to foo all data before barring it) { }

	# etc.


=head1 DIAGNOSTICS

=over

=item C<Bad attribute type: ATTR(%s)>

An attribute handler was specified with an C<:ATTR(I<ref_type>)>, but the
type of referent it was defined to handle wasn't one of the five permitted:
C<SCALAR>, C<ARRAY>, C<HASH>, C<CODE>, or C<ANY>.

=item C<Attribute handler %s doesn't handle %s attributes>

A handler for attributes of the specified name I<was> defined, but not
for the specified type of declaration. Typically encountered whe trying
to apply a C<VAR> attribute handler to a subroutine, or a C<SCALAR>
attribute handler to some other type of variable.

=item C<Declaration of %s attribute in package %s may clash with future reserved word>

A handler for an attributes with an all-lowercase name was declared. An
attribute with an all-lowercase name might have a meaning to Perl
itself some day, even though most don't yet. Use a mixed-case attribute
name, instead.

=item C<Internal error: %s symbol went missing>

Something is rotten in the state of the program. An attributed
subroutine ceased to exist between the point it was declared and the end
of the compilation phase (when its attribute handler(s) would have been
called).

=back

=head1 AUTHOR

Damian Conway (damian@conway.org)

=head1 BUGS

There are undoubtedly serious bugs lurking somewhere in code this funky :-)
Bug reports and other feedback are most welcome.

=head1 COPYRIGHT

         Copyright (c) 2001, Damian Conway. All Rights Reserved.
       This module is free software. It may be used, redistributed
      and/or modified under the terms of the Perl Artistic License
            (see http://www.perl.com/perl/misc/Artistic.html)
