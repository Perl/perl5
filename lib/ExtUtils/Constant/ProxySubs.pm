package ExtUtils::Constant::ProxySubs;

use strict;
use vars qw($VERSION @ISA %type_to_struct %type_to_sv %type_to_C_value
	    %type_is_a_problem %type_num_args);
use Carp;
require ExtUtils::Constant::XS;
use ExtUtils::Constant::Utils qw(C_stringify);
use ExtUtils::Constant::XS qw(%XS_TypeSet);

$VERSION = '0.01';
@ISA = 'ExtUtils::Constant::XS';

%type_to_struct =
    (
     IV => '{const char *name; I32 namelen; IV value;}',
     '' => '{const char *name; I32 namelen;} ',
     );

%type_to_sv = 
    (
     IV => sub { 'newSViv(' . $_[0] . '->value)' },
     '' => sub { '&PL_sv_yes' },
     );

%type_to_C_value = 
    (
     '' => sub {},
     );

%type_is_a_problem =
    (
     SV => 1,
     );

while (my ($type, $value) = each %XS_TypeSet) {
    $type_num_args{$type} = ref $value ? scalar @$value : 1;
}
$type_num_args{''} = 0;

sub partition_names {
    my ($self, $default_type, @items) = @_;
    my (%found, @notfound, @trouble);

    while (my $item = shift @items) {
	my $default = delete $item->{default};
	if ($default) {
	    # If we find a default value, convert it into a regular item and
	    # append it to the queue of items to process
	    my $default_item = {%$item};
	    $default_item->{invert_macro} = 1;
	    $default_item->{pre} = delete $item->{def_pre};
	    $default_item->{post} = delete $item->{def_post};
	    $default_item->{type} = shift @$default;
	    $default_item->{value} = $default;
	    push @items, $default_item;
	} else {
	    # It can be "not found" unless it's the default (invert the macro)
	    # or the "macro" is an empty string (ie no macro)
	    push @notfound, $item unless $item->{invert_macro}
		or !$self->macro_to_ifdef($self->macro_from_name($item));
	}

	if ($item->{pre} or $item->{post} or $type_is_a_problem{$item->{type}}) {
	    push @trouble, $item;
	} else {
	    push @{$found{$item->{type}}}, $item;
	}
    }
    # use Data::Dumper; print Dumper \%found;
    (\%found, \@notfound, \@trouble);
}

sub boottime_iterator {
    my ($self, $type, $iterator, $hash, $subname) = @_;
    my $generator = $type_to_sv{$type};
    die "Can't find generator code for type $type"
	unless defined $generator;

    my $athx = $self->C_constant_prefix_param();

    return sprintf <<"EOBOOT", &$generator($iterator);
        while ($iterator->name) {
	    $subname($athx $hash, $iterator->name,
				$iterator->namelen, %s);
	    ++$iterator;
	}
EOBOOT
}

sub WriteConstants {
    my $self = shift;
    my $ARGS = shift;

    my ($c_fh, $xs_fh, $c_subname, $xs_subname, $default_type, $package)
	= @{$ARGS}{qw(c_fh xs_fh c_subname xs_subname default_type package)};

    $xs_subname ||= 'constant';

    croak("Package name '$package' contains % characters") if $package =~ /%/;

    # All the types we see
    my $what = {};
    # A hash to lookup items with.
    my $items = {};

    my @items = $self->normalise_items ({disable_utf8_duplication => 1},
					$default_type, $what, $items, @_);

    # Partition the values by type. Also include any defaults in here
    # Everything that doesn't have a default needs alternative code for
    # "I'm missing"
    # And everything that has pre or post code ends up in a private block
    my ($found, $notfound, $trouble)
	= $self->partition_names($default_type, @items);

    die "Can't cope with trouble yet" if @$trouble;

    my $pthx = $self->C_constant_prefix_param_defintion();
    my $athx = $self->C_constant_prefix_param();
    my $symbol_table = C_stringify($package) . '::';

    print $c_fh <<"EOADD";
void ${c_subname}_add_symbol($pthx HV *hash, const char *name, I32 namelen, SV *value) {
    SV *rv = newRV_noinc(value);
    if (!hv_store(hash, name, namelen, rv, TRUE)) {
	SvREFCNT_dec(rv);
	Perl_croak("Couldn't add key '%s' to %%%s", name, "$package");
    }
}

static HV *${c_subname}_missing = NULL;

EOADD

    print $xs_fh <<"EOBOOT";
BOOT:
  {
#ifdef dTHX
    dTHX;
#endif
    HV *symbol_table = get_hv("$symbol_table", TRUE);
EOBOOT

    my %iterator;

    $found->{''}
        = [map {{%$_, type=>'', invert_macro => 1}} @$notfound];

    foreach my $type (sort keys %$found) {
	my $struct = $type_to_struct{$type};
	my $type_to_value = $type_to_C_value{$type}
	    || sub {return map {ref $_ ? @$_ : $_} @_};
	my $number_of_args = $type_num_args{$type};
	die "Can't find structure definition for type $type"
	    unless defined $struct;

	my $struct_type = $type ? lc($type) . '_s' : 'notfound_s';
	print $c_fh "struct $struct_type $struct;\n";

	my $array_name = 'values_for_' . ($type ? lc $type : 'notfound');
	print $xs_fh <<"EOBOOT";

    static const struct $struct_type $array_name\[] =
      {
EOBOOT


	foreach my $item (@{$found->{$type}}) {
	    my $name = $item->{name};
	    my $value = $item->{value};
	    $value = $item->{name} unless defined $value;

	    my $namelen = length $name;
	    if ($name =~ tr/\0-\377// != $namelen) {
		# the hash API signals UTF-8 by passing the length negated.
		utf8::encode($name);
		$namelen = -length $name;
	    }
	    $name = C_stringify($name);

	    my $macro = $self->macro_from_name($item);
	    my $ifdef = $self->macro_to_ifdef($macro);
	    if (!$ifdef && $item->{invert_macro}) {
		carp("Attempting to supply a default for '$name' which has no conditional macro");
		next;
	    }
	    print $xs_fh $ifdef;
	    if ($item->{invert_macro}) {
		print $xs_fh
		    "        /* This is the default value: */\n" if $type;
		print $xs_fh "#else\n";
	    }
	    print $xs_fh "        { ", join (', ', "\"$name\"", $namelen,
					     &$type_to_value($value)), " },\n",
						 $self->macro_to_endif($macro);
	}


    # Terminate the list with a NULL
	print $xs_fh "        { NULL, 0", (", 0" x $number_of_args), " } };\n";

	$iterator{$type} = "value_for_" . ($type ? lc $type : 'notfound');

	print $xs_fh <<"EOBOOT";
	const struct $struct_type *$iterator{$type} = $array_name;

EOBOOT
    }

    delete $found->{''};
    foreach my $type (sort keys %$found) {
	print $xs_fh $self->boottime_iterator($type, $iterator{$type}, 
					      'symbol_table',
					      "${c_subname}_add_symbol");
    }
    print $xs_fh <<"EOBOOT";

	${c_subname}_missing = newHV();
	while (value_for_notfound->name) {
	    if (!hv_store(${c_subname}_missing, value_for_notfound->name,
			  value_for_notfound->namelen, &PL_sv_yes, TRUE))
		Perl_croak("Couldn't add key '%s' to missing_hash",
			   value_for_notfound->name);
	    ++value_for_notfound;
	}
  }
EOBOOT

   print $xs_fh <<EOCONSTANT

void
$xs_subname(sv)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv;
        const char *	s = SvPV(sv, len);
    PPCODE:
	if (hv_exists(${c_subname}_missing, s, SvUTF8(sv) ? -len : len)) {
	    sv = newSVpvf("Your vendor has not defined $package macro %" SVf
			  ", used", sv);
	} else {
	    sv = newSVpvf("%" SVf " is not a valid $package macro", sv);
	}
        PUSHs(sv_2mortal(sv));
EOCONSTANT
}

1;
