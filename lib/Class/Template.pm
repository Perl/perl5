package Class::Template;
require 5.000;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(members struct);
use strict;

# Template.pm   --- struct/member template builder
#   12mar95
#   Dean Roehrich
#
# changes/bugs fixed since 28nov94 version:
#  - podified
# changes/bugs fixed since 21nov94 version:
#  - Fixed examples.
# changes/bugs fixed since 02sep94 version:
#  - Moved to Class::Template.
# changes/bugs fixed since 20feb94 version:
#  - Updated to be a more proper module.
#  - Added "use strict".
#  - Bug in build_methods, was using @var when @$var needed.
#  - Now using my() rather than local().
#
# Uses perl5 classes to create nested data types.
# This is offered as one implementation of Tom Christiansen's "structs.pl"
# idea.

=head1 NAME

Class::Template - struct/member template builder

=head1 SYNOPSIS

    use Class::Template;
    struct(name => { key1 => type1, key2 => type2 });

    package Myobj;
    use Class::Template;
    members Myobj { key1 => type1, key2 => type2 };

=head1 DESCRIPTION

This module uses perl5 classes to create nested data types.

=head1 EXAMPLES

=over

=item * Example 1

	use Class::Template;
	
	struct( rusage => {
		ru_utime => timeval,
		ru_stime => timeval,
	});
	
	struct( timeval => [
		tv_secs  => '$',
		tv_usecs => '$',
	]);

	my $s = new rusage;

=item * Example 2

	package OBJ;
	use Class::Template;

	members OBJ {
		'a'	=> '$',
		'b'	=> '$',
	};

	members OBJ2 {
		'd'	=> '@',
		'c'	=> '$',
	};

	package OBJ2; @ISA = (OBJ);

	sub new {
		my $r = InitMembers( &OBJ::InitMembers() );
		bless $r;
	}

=back

=head1 NOTES

Use '%' if the member should point to an anonymous hash.  Use '@' if the
member should point to an anonymous array.

When using % and @ the method requires one argument for the key or index
into the hash or array.

Prefix the %, @, or $ with '*' to indicate you want to retrieve pointers to
the values rather than the values themselves.

=cut

Var: {
	$Class::Template::print = 0;
	sub printem { $Class::Template::print++ }
}


sub struct {
	my( $struct, $ref ) = @_;
	my @methods = ();
	my %refs = ();
	my %arrays = ();
	my %hashes = ();
	my $out = '';

	$out = "{\n  package $struct;\n  sub new {\n";
	parse_fields( $ref, \$out, \@methods, \%refs, \%arrays, \%hashes, 0 );
	$out .= "      bless \$r;\n  }\n";
	build_methods( $ref, \$out, \@methods, \%refs, \%arrays, \%hashes );
	$out .= "}\n1;\n";

	( $Class::Template::print ) ? print( $out ) : eval $out;
}

sub members {
	my( $pkg, $ref ) = @_;
	my @methods = ();
	my %refs = ();
	my %arrays = ();
	my %hashes = ();
	my $out = '';

	$out = "{\n  package $pkg;\n  sub InitMembers {\n";
	parse_fields( $ref, \$out, \@methods, \%refs, \%arrays, \%hashes, 1 );
	$out .= "      bless \$r;\n  }\n";
	build_methods( $ref, \$out, \@methods, \%refs, \%arrays, \%hashes );
	$out .= "}\n1;\n";

	( $Class::Template::print ) ? print( $out ) : eval $out;
}


sub parse_fields {
	my( $ref, $out, $methods, $refs, $arrays, $hashes, $member ) = @_;
	my $type = ref $ref;
	my @keys;
	my $val;
	my $cnt = 0;
	my $idx = 0;
	my( $cmt, $n );

	if( $type eq 'HASH' ){
		if( $member ){
			$$out .= "      my(\$r) = \@_ ? shift : {};\n";
		}
		else{
			$$out .= "      my(\$r) = {};\n";
		}
		@keys = keys %$ref;
		foreach (@keys){
			$val = $ref->{$_};
			if( $val =~ /^\*(.)/ ){
				$refs->{$_}++;
				$val = $1;
			}
			if( $val eq '@' ){
				$$out .= "      \$r->{'$_'} = [];\n";
				$arrays->{$_}++;
			}
			elsif( $val eq '%' ){
				$$out .= "      \$r->{'$_'} = {};\n";
				$hashes->{$_}++;
			}
			elsif( $val ne '$' ){
				$$out .= "      \$r->{'$_'} = \&${val}::new();\n";
			}
			else{
				$$out .= "      \$r->{'$_'} = undef;\n";
			}
			push( @$methods, $_ );
		}
	}
	elsif( $type eq 'ARRAY' ){
		if( $member ){
			$$out .= "      my(\$r) = \@_ ? shift : [];\n";
		}
		else{
			$$out .= "      my(\$r) = [];\n";
		}
		while( $idx < @$ref ){
			$n = $ref->[$idx];
			push( @$methods, $n );
			$val = $ref->[$idx+1];
			$cmt = "# $n";
			if( $val =~ /^\*(.)/ ){
				$refs->{$n}++;
				$val = $1;
			}
			if( $val eq '@' ){
				$$out .= "      \$r->[$cnt] = []; $cmt\n";
				$arrays->{$n}++;
			}
			elsif( $val eq '%' ){
				$$out .= "      \$r->[$cnt] = {}; $cmt\n";
				$hashes->{$n}++;
			}
			elsif( $val ne '$' ){
				$$out .= "      \$r->[$cnt] = \&${val}::new();\n";
			}
			else{
				$$out .= "      \$r->[$cnt] = undef; $cmt\n";
			}
			++$cnt;
			$idx += 2;
		}
	}
}


sub build_methods {
	my( $ref, $out, $methods, $refs, $arrays, $hashes ) = @_;
	my $type = ref $ref;
	my $elem = '';
	my $cnt = 0;
	my( $pre, $pst, $cmt, $idx );

	foreach (@$methods){
		$pre = $pst = $cmt = $idx = '';
		if( defined $refs->{$_} ){
			$pre = "\\(";
			$pst = ")";
			$cmt = " # returns ref";
		}
		$$out .= "  sub $_ {$cmt\n      my \$r = shift;\n";
		if( $type eq 'ARRAY' ){
			$elem = "[$cnt]";
			++$cnt;
		}
		elsif( $type eq 'HASH' ){
			$elem = "{'$_'}";
		}
		if( defined $arrays->{$_} ){
			$$out .= "      my \$i;\n";
			$$out .= "      \@_ ? (\$i = shift) : return \$r->$elem;\n";
			$idx = "->[\$i]";
		}
		elsif( defined $hashes->{$_} ){
			$$out .= "      my \$i;\n";
			$$out .= "      \@_ ? (\$i = shift) : return \$r->$elem;\n";
			$idx = "->{\$i}";
		}
		$$out .= "      \@_ ? (\$r->$elem$idx = shift) : $pre\$r->$elem$idx$pst;\n";
		$$out .= "  }\n";
	}
}

1;
