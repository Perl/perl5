package Mac::Glue;

BEGIN {
	use vars qw($SERIALIZER);
	$SERIALIZER =
		$MacPerl::Architecture eq 'MacPPC' ?
			'Storable' :
		$MacPerl::Architecture eq 'MacCFM68K' ?
			'FreezeThaw' :
		die("Must be using CFM68K or PPC build of MacPerl: $MacPerl::Architecture");

}

use Carp;
use Data::Dumper;
use Exporter;
use Fcntl;
use Mac::AppleEvents::Simple 1.00 ':all';
use Mac::Apps::Launch 1.70;
use Mac::Files;
use Mac::Memory 1.20 ();
use Mac::Processes 1.01;
use Mac::Types;
use MLDBM ('DB_File', $SERIALIZER);

use strict;
use vars qw(
	$REVISION $VERSION $AUTOLOAD %AE_PUT %AE_GET @SYMS @METHS
	@EXPORT @EXPORT_OK %EXPORT_TAGS @ISA $GLUEDIR
	$GENPKG $GENSEQ %OPENGLUES %MERGEDCLASSES @OTHEREVENT
	@OTHERCLASS %SPECIALEVENT %SPECIALCLASS %DESCS
	%MERGEDENUM @OTHERENUM %INSL %DESC_TYPE %COMP %LOGI
);

#=============================================================================#
# $Id: Glue.pm,v 1.1 2001/10/03 19:31:55 pudge Exp $
($REVISION)	= ' $Revision: 1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;
$VERSION	= '1.00';
@ISA		= 'Exporter';
@EXPORT		= ();
@SYMS		= qw(
			obj_form  param_type enum whose range location
			glueTrue  glueFalse  glueNext gluePrevious
			glueFirst glueMiddle glueLast glueAny glueAll
			gTrue     gFalse     gNext    gPrevious
			gFirst    gMiddle    gLast    gAny    gAll
		);
@METHS		= qw(	AUTOLOAD can launch obj prop	);

@EXPORT_OK	= ( @Mac::AppleEvents::EXPORT, @SYMS );
%EXPORT_TAGS	= (
			all	=> [@EXPORT, @EXPORT_OK],
			glue	=> [@EXPORT, @SYMS],
			long	=> [grep !/^g[A-Z]/, @EXPORT, @SYMS],
			longall	=> [grep !/^g[A-Z]/, @EXPORT, @EXPORT_OK],
		);

$GENPKG		= __PACKAGE__;
$GENSEQ		= 0;

# change this if it ever works on other platforms ... Mac OS X?
$ENV{MACGLUEDIR}	||= "$ENV{MACPERL}site_perl:Mac:Glue:glues:";
$ENV{MACGLUEDIR}	.= ':' unless $ENV{MACGLUEDIR} =~ /:$/;

#=============================================================================#
# exported functions
sub obj_form ($$;$)	{ bless [@_], 'Mac::AEObjDescForm' }
sub param_type ($$)	{ bless [@_], 'Mac::AEParamType' }
sub enum ($)		{ bless [@_], 'Mac::AEEnum' }
sub whose		{ bless [formTest, @_], 'Mac::AEObjDescType' }
sub range ($$)		{ bless [formRange, @_], 'Mac::AEObjDescType' }
sub location ($;$);	*location = *_do_loc{CODE};

#=============================================================================#
# constants
use constant glueTrue		=> enum('true');
use constant glueFalse		=> enum('false');

use constant glueFirst		=> obj_form(formAbsolutePosition, typeAbsoluteOrdinal, kAEFirst);
use constant glueMiddle		=> obj_form(formAbsolutePosition, typeAbsoluteOrdinal, kAEMiddle);
use constant glueLast		=> obj_form(formAbsolutePosition, typeAbsoluteOrdinal, kAELast);
use constant glueAny		=> obj_form(formAbsolutePosition, typeAbsoluteOrdinal, kAEAny);
use constant glueAll		=> obj_form(formAbsolutePosition, typeAbsoluteOrdinal, kAEAll);
use constant glueNext		=> obj_form(formRelativePosition, typeEnumerated, kAENext);
use constant gluePrevious	=> obj_form(formRelativePosition, typeEnumerated, kAEPrevious);

use constant glueNull		=> new AEDesc typeNull;

use constant glueAnd		=> new AEDesc typeEnumerated, kAEAND;
use constant glueOr		=> new AEDesc typeEnumerated, kAEOR;
use constant glueNot		=> new AEDesc typeEnumerated, kAENOT;

use constant glueGT		=> new AEDesc typeEnumerated, kAEGreaterThan;
use constant glueGE		=> new AEDesc typeEnumerated, kAEGreaterThanEquals;
use constant glueEquals		=> new AEDesc typeEnumerated, kAEEquals;
use constant glueLT		=> new AEDesc typeEnumerated, kAELessThan;
use constant glueLE		=> new AEDesc typeEnumerated, kAELessThanEquals;
use constant glueBeginsWith	=> new AEDesc typeEnumerated, kAEBeginsWith;
use constant glueEndsWith	=> new AEDesc typeEnumerated, kAEEndsWith;
use constant glueContains	=> new AEDesc typeEnumerated, kAEContains;


use constant gTrue		=> glueTrue();
use constant gFalse		=> glueFalse();

use constant gFirst		=> glueFirst();
use constant gMiddle		=> glueMiddle();
use constant gLast		=> glueLast();
use constant gAny		=> glueAny();
use constant gAll		=> glueAll();
use constant gNext		=> glueNext();
use constant gPrevious		=> gluePrevious();

use constant gNull		=> glueNull();

use constant gAnd		=> glueAnd();
use constant gOr		=> glueOr();
use constant gNot		=> glueNot();

use constant gGT		=> glueGT();
use constant gGE		=> glueGE();
use constant gEquals		=> glueEquals();
use constant gLT		=> glueLT();
use constant gLE		=> glueLE();
use constant gBeginsWith	=> glueBeginsWith();
use constant gEndsWith		=> glueEndsWith();
use constant gContains		=> glueContains();

#=============================================================================#
_open_others();
#=============================================================================#

sub new {
	my($class, $app, $addtype, @add) = @_;
	my($self, $glue, $db, $app1, $app2);

	# find glue, try a few different names just in case
	($app1 = $app) =~ tr/ /_/;
	($app2 = $app) =~ tr/_/ /;
	for (map { "$ENV{MACGLUEDIR}$_" } $app, $app1, $app2) {
		if (-e) {
			$glue = $_;
			last;
		}
	}
	croak "No application glue for '$app' found in '$ENV{MACGLUEDIR}'" unless $glue;

	# if not already opened, open and store reference to db
	unless (exists $OPENGLUES{$glue}) {
		tie my %db, 'MLDBM', $glue, O_RDONLY or confess "Can't tie '$glue': $!";
		$OPENGLUES{$glue} = \%db;
	}
	$db = $OPENGLUES{$glue};

	# create new class to put this in, add the symbols we want,
	# nyah nyah nyah (gosh, I love Perl)
	$class = $GENPKG . '::GLUE' . $GENSEQ++;
	{
		no strict 'refs';
		for (@METHS) {
			*{$class . '::' . $_} = *{'Mac::Glue::' . $_}{CODE};
		}
	}

	$self = { _DB => $db, ID => $db->{ID}, SWITCH => 0, GLUENAME => $app };

	$self->{ADDRESS} = defined $addtype
			? $addtype eq 'ppc'  || $addtype eq typeTargetID
				? { typeTargetID() => pack_ppc($db->{ID}, @add) }

			: $addtype eq 'eppc' || $addtype eq typeTargetID
				? { typeTargetID() => pack_eppc($db->{ID}, @add) }

			: $addtype eq 'psn'  || $addtype eq typeProcessSerialNumber
				? { typeProcessSerialNumber() => pack_psn($add[0]) } 

			: $addtype eq 'path'
				? { typeProcessSerialNumber() => _path_to_psn($add[0]) }

			: { $addtype => $add[0] }

		: { typeApplSignature() => $self->{ID} };

	@{$self}{qw(CLASS NAMES IDS)} = _merge_classes($db);
	_merge_enums($db, $self);

	bless($self, $class);
}

#=============================================================================#
# help UNIVERSAL::can out

sub can {
	my($self, $meth) = @_;
	return unless @_ == 2;
	my $can = UNIVERSAL::can($self, $meth);
	unless ($can) {
		$AUTOLOAD = ref($self) . '::' . $meth;
		$can = AUTOLOAD('AUTOLOAD::can', $self);
	}
	return $can;
}

#=============================================================================#
# define event calls as subs

sub AUTOLOAD {
	my $can = $_[0] eq 'AUTOLOAD::can' ? shift : 0;
	my $self = $_[0];
	(my $name = $AUTOLOAD) =~ s/^.*://;
	my $sub;

	if ($name eq 'DESTROY') {
		return;
	} elsif ($name =~ /^(?:REPLY|SWITCH|MODE|PRIORITY|TIMEOUT|RETOBJ|ERRORS)$/) {
		$sub = sub { $_[0]->{$name} = $_[1] if $_[1]; $_[0]->{$name} };
	}

	unless ($sub) {
		(my $auto = $AUTOLOAD) =~ s/:([^:]+)$/:\L$1/;
		$sub = $auto if defined &$auto;
	}

	unless ($sub) {
		if (my $event = _find_event($self, lc $name)) {
			$sub = sub { _primary($_[0], $event, lc $name, @_[1 .. $#_]) }
		} elsif (! $can) {
			croak "No event '$name' available from glue for '$self->{GLUENAME}'";
		}
	}

	# install new sub, only do AUTOLOAD for it once!
	if ($sub) {
		no strict 'refs';
		*{$AUTOLOAD} = $sub;
	}

	return $sub if $can;
	goto &$sub;
}

#=============================================================================#
# login using GTQ Login As OSAX
# will NOT return error if exists, because MacPerl does not handle replies well

sub login {
	my($self, $user, $pass) = @_;

	my $evt = build_event(qw(gtqp lgin McPL), q{'----':TEXT(@), pwrd:TEXT(@)},
		$user, $pass);
	$evt->send_event(kAENoReply);

	return 1;
}

#=============================================================================#
# basic subroutine building and sending every event call
# (see sub AUTOLOAD)

sub _primary {
	my($self, $e, $name, @args) = @_;
	my($evt, %xargs, $dobj, @origargs);

	my($class, $event, $reply, $params) = @{$e}{qw(class event reply params)};

	$dobj = shift @args if @args % 2;

	%xargs = @args;
	for (keys %xargs) {
		delete $xargs{$_} unless /^(?:CALLBACK|CLBK_ARG)$/;
	}
	@xargs{keys %{$self->{ADDRESS}}} = values %{$self->{ADDRESS}};

	# create event (Mac::AppleEvents::Simple object)
	$evt = build_event($class, $event, \%xargs);

	# prepare parameters (direct object)
	if (defined $dobj) {
		croak "Direct object parameter not present"
			unless exists $params->{keyDirectObject()};
		_params($self, $evt, $params->{keyDirectObject()}, $dobj);
		push @origargs, 'DOBJ', $dobj;
	}

	# prepare parameters (all the rest)
	my $hash = {@args};
	if ($hash) {
		for my $p (keys %$hash) {
			next if $p =~ /^(?:REPLY|SWITCH|MODE|PRIORITY|TIMEOUT|RETOBJ|ERRORS|CALLBACK|CLBK_ARG)$/;
			my $pp = $p eq 'DOBJ' ? keyDirectObject : lc $p;
			croak "'$p' parameter not available" unless exists $params->{$pp};
			_params($self, $evt, $params->{$pp}, $hash->{$p});
			push @origargs, $pp, $p;
		}
	}

	# prepare send parameters and send event
	local $Mac::AppleEvents::Simple::SWITCH =
		$hash->{SWITCH} ? $hash->{SWITCH} : $self->{SWITCH};

	# we'll wait if REPLY not set and TIMEOUT is set
	if (!exists $hash->{REPLY} && exists $hash->{TIMEOUT}) {
		$self->{REPLY} = 1;
	}

	my $mode =
		(ref $hash->{CALLBACK} eq 'CODE'
			? kAEQueueReply
			: (exists $hash->{REPLY}	# check event setting
				? $hash->{REPLY}
				: exists $self->{REPLY}	# check global setting
					? $self->{REPLY}
					: 1		# default to wait
			)
				? kAEWaitReply
				: kAENoReply)

			| (exists $hash->{MODE}
				? $hash->{MODE}
				: exists $self->{MODE}
					? $self->{MODE}
					: (kAECanInteract | kAECanSwitchLayer));

	my $priority =
		exists $hash->{PRIORITY}
			? $hash->{PRIORITY}
			: exists $self->{PRIORITY}
				? $self->{PRIORITY}
				: kAENormalPriority;

	my $timeout = 
		exists $hash->{TIMEOUT}
			? 60 * $hash->{TIMEOUT}		# convert seconds to ticks
			: exists $self->{TIMEOUT}
				? 60 * $self->{TIMEOUT}
				: kNoTimeOut;

	$evt->send_event($mode, $priority, $timeout);

	my $retobj = exists $hash->{RETOBJ}
		? $hash->{RETOBJ}
		: exists $self->{RETOBJ}
			? $self->{RETOBJ}
			: 0;

	my $error_handler = exists $hash->{ERRORS}
		? $hash->{ERRORS}
		: exists $self->{ERRORS}
			? $self->{ERRORS}
			: 0;

	local $AE_GET{typeObjectSpecifier()} = sub {
		return(_obj_desc($self, $_[0]), 1);
	};

	local $Mac::AppleEvents::Simple::CLASSREC = sub {
		return _is_class($self, $_[0]);
	};

	local $Mac::AppleEvents::Simple::ENUMREC = sub {
		return _is_enum($self, $_[0]);
	};

	my @return;
	if ($retobj) {
		@return = $evt;
	} elsif (my $type = $evt->type) {
		@return = $evt->get;
		@return = _fix_reco($self, {@return}) if $type eq typeAERecord;
		@return = @{_fix_reco($self, \@return)} if $type eq typeAEList;
	}

	$^E = exists $evt->{ERRNO} ? $evt->{ERRNO} : 0; # restore errno

	my $return = 1;
	# if error handler, only return if error handler returns true
	# what should error handler be passed?
	if ($^E && $error_handler) {
		my($package, $filename, $line) = caller(1);
		$return = $error_handler->({
			_glue		=> $self,
			_event		=> $evt,
			glue		=> $self->{GLUENAME},
			event		=> $name,
			errs		=> $^E,
			errn		=> $^E+0,
			line		=> $line,
			'package'	=> $package,
			filename	=> $filename,
		}, @origargs);
	}

	return(wantarray ? @return : $return[0]) if $return;
}

#=============================================================================#
# prepare all event parameters

sub _params {
	my($self, $evt, $p, $data) = @_;
	my($key, $type) = @{$p}[0, 1];

	if (ref $data eq 'Mac::AEParamType') {
		($data, $type) = @{$data}[1, 0];
	} elsif ($type eq typeObjectSpecifier && ref $data ne 'Mac::AEObjDesc') {
		$type = $data =~ /^[+-]?\d+$/ ? typeInteger : typeChar;
	}

	my($desc, $dispose) = _get_desc($self, $data, $type);
	AEPutParamDesc($evt->{EVT}, $key, $desc)
		or confess "Can't put $key/$desc into event: $^E";
	AEDisposeDesc $desc if $dispose;
}

#=============================================================================#
# Put anon array parameter data into AE list

sub _do_list {
	my($self, $data, $type) = @_;
	my $list = AECreateList('', 0) or confess "Can't create list: $^E";
	my $count = 0;

	for my $d (@{$data}) {
		my($desc, $dispose) = _get_desc($self, $d);
		AEPutDesc($list, ++$count, $desc)
			or confess "Can't put $desc into $list: $^E";
		AEDisposeDesc $desc if $dispose;
	}

	return $list;
}

#=============================================================================#
# Put anon hash parameter data into AE record

sub _do_rec {
	my($self, $data, $type) = @_;
	my $reco = AECreateList('', 1) or confess "Can't create record: $^E";
	my $class;

	while (my($k, $d) = each %{$data}) {
		if ($k =~ /^class$/i) {
			$class = _get_id($self, $d);
			next;
		}
		my $key = _get_id($self, $k);
		my($desc, $dispose) = _get_desc($self, $d);
		AEPutKeyDesc($reco, $key, $desc)
			or confess "Can't put $key/$desc into $reco: $^E";
		AEDisposeDesc $desc if $dispose;
	}

	if ($class) {
		my $nreco = AECoerceDesc($reco, $class)
			or confess "Can't coerce to '$class': $^E";
		AEDisposeDesc $reco;
		$reco = $nreco;
	}

	return $reco;
}

#=============================================================================#
# create AE descriptor record

sub _do_obj {
	my($self, $data, $class, $from) = @_;
	my($list, $obj, $form, $dataform, $d, $ref);
	$class = 'property' if $class =~ /^(?:of|in|prop)$/;
	confess "Class '$class' does not exist for '$data'.\n"
		unless exists $self->{NAMES}{$class};

	$data = _get_objdesc($data);
	$ref = ref $data;

	if ($class eq 'property') {
		$data = _get_id($self, $data) or croak "Can't find property '$data'.\n";
		$form = typeProperty;

	} elsif ($ref eq 'AEDesc' || $ref eq 'Mac::AEObjDescType') {
		$data = $DESC_TYPE{$data->[0]}->($self, $class, @{$data}[1 .. $#{$data}])
			if $ref eq 'Mac::AEObjDescType';
		$dataform = $form = $data->type;
		if ($form eq typeCompDescriptor || $form eq typeLogicalDescriptor) {
			$form = formTest;
		}

	} elsif ($ref eq 'Mac::AEObjDescForm') {
		$form = $$data[0];
		$dataform = $$data[1] if @$data == 3;
		$data = $$data[-1];

	} elsif ($data =~ /^[+-]?\d+$/) {
		$form = formAbsolutePosition;

	} else {
		$form = formName;
	}

	$dataform ||=
		$form eq formName		? typeChar	:
		$form eq formAbsolutePosition	? typeInteger	:
		$form eq typeProperty		? typeType	:
		$form;

	$class = $self->{NAMES}{$class};
	$list = AECreateList('', 1) or confess "Can't create list: $^E";

	# form / keyAEForm
	AEPutKey($list, keyAEForm, typeEnumerated, $form)
		or confess "Can't put form:$form into object: $^E";

	# want / keyAEDesiredClass
	AEPutKey($list, keyAEDesiredClass, typeType, $class->{id})
		or confess "Can't put want:$class->{id} into object: $^E";

	# seld / keyAEKeyData
	($d, $dataform) = _get_data($self, $data, $dataform);
	if (ref $d eq 'AEDesc') {
		AEPutKeyDesc($list, keyAEKeyData, $d)
			or confess "Can't put seld:$d into object: $^E";
	} else {
		AEPutKey($list, keyAEKeyData, $dataform, $d)
			or confess "Can't put seld:$dataform($d) into object: $^E";
	}

	# type / keyAEContainer
	if ($from && $from eq typeCurrentContainer) {
		AEPutKey($list, keyAEContainer, $from, '')
			or confess "Can't put from:$from into object: $^E";
	} elsif ($from && $from eq typeObjectBeingExamined) {
		AEPutKey($list, keyAEContainer, $from, '')
			or confess "Can't put from:$from into object: $^E";
	} elsif ($from) {
		$from = _get_objdesc($from);
		AEPutKeyDesc($list, keyAEContainer, $from)
			or confess "Can't put from:$from into object: $^E";
	} else {
		AEPutKey($list, keyAEContainer, typeNull, '')
			or confess "Can't put from:null into object: $^E";
	}

	$obj = AECoerceDesc($list, typeObjectSpecifier)
		or confess "Can't coerce to 'obj ': $^E";
	AEDisposeDesc $list;

	return _obj_desc($self, $obj);
}

#=============================================================================#
# create insertion record

sub _do_loc ($;$) {
	my($pos, $obj) = @_;
	$obj = _get_objdesc($obj);
	my $desc = ref $obj eq 'AEDesc' ? $obj : gNull();
	my $list = AECreateList('', 1) or confess "Can't create list: $^E";

	AEPutKeyDesc($list, keyAEObject, $desc)
		or confess "Can't put object in location: $^E";
	AEPutKey($list, keyAEPosition, typeEnumerated, $INSL{$pos} || $pos)
		or confess "Can't put pos in location: $^E";

	my $insl = AECoerceDesc($list, typeInsertionLoc)
		or confess "Can't coerce $list to 'obj ': $^E";
	AEDisposeDesc $list;
	_save_desc($insl);
	return $insl;
}

#=============================================================================#
# create glue descriptor record

sub _do_range {
	my($self, $class, $r1, $r2) = @_;

	$r1 = _do_obj($self, $r1, $class, typeCurrentContainer);
	$r2 = _do_obj($self, $r2, $class, typeCurrentContainer);

	my $list = AECreateList('', 1) or confess "Can't create list: $^E";

	AEPutKeyDesc($list, keyAERangeStart, $r1->{DESC})
		or confess "Can't add param to list: $^E";
	AEPutKeyDesc($list, keyAERangeStop,  $r2->{DESC})
		or confess "Can't add param to list: $^E";

	my $rang = AECoerceDesc($list, typeRangeDescriptor)
		or confess "Can't coerce to range: $^E";
	AEDisposeDesc $list;
	_save_desc($rang);

	return $rang;
}

#=============================================================================#
# create comparison descriptor record

sub _do_comp {
	my $self = shift;
	my $len = @_;
	my($p1, $d1, $op, $p2, $d2, $c1, $c2, $dispose1, $dispose2);

	$p1 = $len < 4 ? 'property' : shift;
	$d1 = shift;
	$op = shift;
	$p2 = $len < 5 ? undef : shift;
	$d2 = shift;

	unless (ref $op eq 'AEDesc') {
		my $foo = $op;
		$op = $COMP{lc $op} or croak "Comparison operator '$foo' not recognized";
	}

	if ($p1 eq 'property' && $d1 eq 'it') {
		$c1 = new AEDesc typeObjectBeingExamined;
		$dispose1 = 1;
	} else {
		$c1 = _do_obj($self, $d1, $p1, typeObjectBeingExamined)->{DESC};
	}

	if (defined $p2) {
		$c2 = _do_obj($self, $d2, $p2, typeObjectBeingExamined)->{DESC};
	} else {
		($c2, $dispose2) = _get_desc($self, $d2);
	}

	my $list = AECreateList('', 1) or confess "Can't create list: $^E";

	AEPutKeyDesc($list, keyAECompOperator, $op);
	AEPutKeyDesc($list, keyAEObject1, $c1);
	AEPutKeyDesc($list, keyAEObject2, $c2);

	AEDisposeDesc $c1 if $dispose1;
	AEDisposeDesc $c2 if $dispose2;

	my $comp = AECoerceDesc($list, typeCompDescriptor)
		or confess "Can't coerce list to comparison descriptor: $^E";
	AEDisposeDesc $list;
	_save_desc($comp);

	return $comp;
}

#=============================================================================#
# create a logical descriptor record

sub _do_logical {
	my($self, $op, @args) = @_;
	my $terms = AECreateList('', 0) or confess "Can't create list: $^E";

	unless (ref $op eq 'AEDesc') {
		my $foo = $op;
		$op = $LOGI{uc $op} or croak "Logical operator '$foo' not recognized";
	}

	for my $i (0 .. $#args) {
		my $term = $args[$i];
		my $desc;
		croak "Each logical term must be in an anonymous array ($term)\n"
			if ref $term ne 'ARRAY';

		if (grep { ref ne 'ARRAY' } @{$term}[1 .. $#{$term}]) {
			$desc = _do_comp($self, @$term);
		} else {
			$desc = _do_logical($self, @$term);
		}
		AEPutDesc($terms, $i + 1, $desc);
	}

	my $list = AECreateList('', 1) or confess "Can't create list: $^E";
	AEPutKeyDesc($list, keyAELogicalOperator, $op);
	AEPutKeyDesc($list, keyAELogicalTerms, $terms);

	my $logi = AECoerceDesc($list, typeLogicalDescriptor)
		or confess "Can't coerce list into logical descriptor: $^E";
	AEDisposeDesc $terms;
	AEDisposeDesc $list;
	_save_desc($logi);

	return $logi;
}

#=============================================================================#
# help create a test object record

sub _do_whose {
	splice @_, 1, 1;  # remove class
	if (grep { ref ne 'ARRAY' } @_[2 .. $#_]) {
		goto &_do_comp;
	} else {
		goto &_do_logical;
	}
}

#=============================================================================#
# return descriptor as needed

sub _get_desc {
	my($self, $data, $type) = @_;
	my($desc, $dispose, $ref);

	$dispose = 1;
	$data = _get_objdesc($data);
	$ref = ref $data;

	if ($ref eq 'ARRAY') {
		$desc = _do_list($self, $data, $type);
	} elsif ($ref eq 'HASH') {
		$desc = _do_rec($self, $data, $type);
	} elsif ($ref eq 'AEDesc') {
		$desc = $data;
		$dispose = 0;
		_save_desc($desc);
	} else {
		my($d, $t);
		$t = _get_type($self, $data, $type);
		($d, $t) = _get_data($self, $data, $t);

		if (ref $d eq 'AEDesc') {
			$desc = $d;
			$dispose = 0;
			_save_desc($d);
		} else {
			$desc = AEDesc->new($t, $d);
		}
	}

	return($desc, $dispose);
}

#=============================================================================#
# take a good guess at what the data type is

sub _get_type {
	my($self, $data, $type, $key) = @_;
	my $i = 0;

	if (defined $key) {
		my $href = _get_id($self, $key, 1);
		$type = $href->{types}[$i++] if exists $href->{types};
	}

	if (!$type || $type eq typeWildCard) {
		$type = $data =~ /^[+-]?\d+$/ ? typeInteger : typeChar;
	}

	return $type;
}

#=============================================================================#
# fudge the data into something that the event will be expecting
# should only return data as simple non-reference scalar or AEDesc

sub _get_data {
	my($self, $data, $type) = @_;
	my $t;

	my $ref = ref $data;

	if ($ref eq 'Mac::AEEnum') {
		my $id = _get_id($self, $data->[0]);
		$data = $id if defined $id;
		$type = typeEnumerated; # typeEnumerated or typeType ???

	} elsif ($type eq typeType) {
		my $id = _get_id($self, $data);
		$data = $id if defined $id;

	# see the %AE_PUT data structure
	} elsif (exists $AE_PUT{$type}) {
		($data, $t) = $AE_PUT{$type}->($data);
	}

	return($data, $t || $type);
}

#=============================================================================#
# get class / property name

sub _get_name {
	my($self, $id) = @_;
	if (exists $self->{IDS}{$id}) {
		if (exists $self->{IDS}{$id}{name}) {
			return $self->{IDS}{$id}{name};
		}
	}
	return;
}

#=============================================================================#
# find if ID is class

sub _is_class {
	my($self, $id) = @_;
	my $name = _get_name($self, $id) or return;
	my $class = $self->{CLASS}{$name} or return;
	if (scalar keys %{$class->{properties}} > 1 ||
		(scalar keys %{$class->{properties}} == 1 && ! exists $class->{properties}{''})) {
#		print Dumper $class->{properties};
		return 1;
	}
}

#=============================================================================#
# return name if type is enum

sub _is_enum {
	my($self, $id) = @_;
	return unless exists $self->{ENUM}{$id};
	return _get_name($self, $id);
}

#=============================================================================#
# fix record stuff

sub _fix_reco {
	my($self, $data) = @_;

	if (ref $data eq 'ARRAY') {
		my @narr;
		for my $i (@$data) {
			push @narr, (ref $i eq 'HASH' || ref $i eq 'ARRAY')
				? _fix_reco($self, $i) : $i;
		}
		return \@narr;
	} elsif (ref $data eq 'HASH') {
		my %nreco;
		for my $id (keys %$data) {
			my $nid = _get_name($self, $id);
			my $i = $data->{$id};
			$nreco{$nid || $id} = (ref $i eq 'HASH' || ref $i eq 'ARRAY')
				? _fix_reco($self, $i) : $i;
		}
		return \%nreco;
	}
}

#=============================================================================#
# get class / property id

sub _get_id {
	my($self, $name, $obj) = @_;
	(my $new = lc $name) =~ tr/ /_/;
	my $ref = $self->{NAMES}{$new} if exists $self->{NAMES}{$new};
	return $obj ? $ref : $ref->{id};
}

#=============================================================================#
# get Mac::AEObjDesc

sub _get_objdesc {
	my $ref = ref $_[0];
	if ($ref eq 'Mac::AEObjDesc') {
		return $_[0]->{DESC};
	} else {
		return $_[0];
	}
}

#=============================================================================#
# create Mac::AEObjDesc

sub _obj_desc {
	_save_desc($_[1]);
	my $self = bless { GLUE => $_[0], DESC => $_[1] }, 'Mac::AEObjDesc';
}

#=============================================================================#
# save AEDesc for destruction later in Mac::AppleEvents::Simple

sub _save_desc { $DESCS{$_[0]} = $_[0] }

#=============================================================================#
# find all information for an event, based on its "name"

sub _find_event {
	my($self, $name) = @_;
	my $event;

	return $SPECIALEVENT{$name} if exists $SPECIALEVENT{$name};

	for ($self->{_DB}{EVENT}, @OTHEREVENT) {
		if (exists $_->{$name}) {
			$event = $_->{$name};
			last;
		}
	}

	return $event;
}

#=============================================================================#
# is class a plural of another?

sub _is_plural {
	my($self, $class) = @_;
	my $pl = 'c@#!';
	return unless exists $self->{CLASS}{$class}{properties};
	my $pref = $self->{CLASS}{$class}{properties};
	return scalar grep { $pref->{$_}[0] && $pref->{$_}[0] eq $pl } keys %$pref;
}

#=============================================================================#
# create an AE object

sub prop {
	@_ = ($_[0], 'property', @_[1 .. $#_]);
	goto &obj;
}

sub obj {
	my($self, @data, $obj, @obj) = @_;

	if (ref($data[-1]) =~ /^(Mac::)?AE(?:Obj)?Desc$/) { # @data % 2 && 
		$obj = pop @data;
	}

	for (my $i = 0; $i <= $#data; $i++) {
		my($k, $v) = $data[$i];
		if (!(
			$data[$i+1]
				&&
			ref($data[$i+1]) =~ /^(Mac::)?AE/)
				&&
			_is_plural($self, $k)
		) {
			$v = gAll();
		} else {
			$i++;
			$v = $data[$i];
		}
		push @obj, [$v, $k];
	}

	for (reverse @obj) {
		local $^W;
		$obj = _do_obj($self, @{$_}[0, 1], $obj);
	}

	return $obj;
}

#=============================================================================#
# launch the app (done automatically when an event is called if not running)

sub launch {
	my($self, $location) = @_;
	if (defined $location) {
		LaunchSpecs($location);
	} else {
		LaunchApps($self->{ID});
	}
}

#=============================================================================#
# launch spec and then get PSN

sub _path_to_psn {
	my($path) = @_;

	confess "Path '$path' does not exist" unless -e $path;

	my $lp = LaunchParam->new(
		launchControlFlags => (launchContinue | launchNoFileFlags | launchDontSwitch),
		launchAppSpec => $path
	);

	my $psn = LaunchApplication($lp) or confess "Cannot launch '$path': $^E";

	return pack_psn($psn);
}

#=============================================================================#
# open scripting additions and dialect files only once,
# save them for further use by all Mac::Glue instances

sub _open_others {
	chomp(my $curdir = `pwd`);
	my @others;
	for my $dir (map { "$ENV{MACGLUEDIR}$_" } qw[dialects additions]) {
		unless (-e $dir) {
			warn "Please run gluedialect and gluescriptadds programs."
				unless $Mac::Glue::CREATINGGLUES;
			next;
		}

		local *DIR;
		opendir DIR, $dir or confess "Can't open directory '$dir': $!";
		chdir $dir or confess "Can't chdir directory '$dir': $!";

		# ### add file type / creator checking
		for (readdir DIR) {
			next if $_ eq "Icon\015";
			next if /\.pod$/;
			tie my %db, 'MLDBM', $_, O_RDONLY or confess "Can't tie '$_': $!";
			push @OTHEREVENT, $db{EVENT} if $db{EVENT};
			push @OTHERCLASS, $db{CLASS} if $db{CLASS};
			push @OTHERENUM, $db{ENUM} if $db{ENUM};
		}
	}
	chdir $curdir or confess "Can't chdir to '$curdir': $!";
}

#=============================================================================#
# merge additions, dialect, and glue classes together

sub _merge_classes {
	my($db) = @_;
	if (!exists $MERGEDCLASSES{ $db->{ID} }) {
		my($ids, $names) = ({}, {});
		my($class, @classes) = ($db->{CLASS}, @OTHERCLASS);

		for my $c (keys %$class) {
			$names->{$c}{id} = $class->{$c}{id};
			$ids->{$names->{$c}{id}}{name} = $c;

			for my $p (keys %{$class->{$c}{properties}}) {
				$names->{$p}{id} ||= $class->{$c}{properties}{$p}[0];
				$ids->{$names->{$p}{id}}{name} ||= $p;
				unshift @{$names->{$p}{types}}, $class->{$c}{properties}{$p}[1];
			}
		}

		for my $tempc (@classes) {
			for my $c (keys %$tempc) {
				$names->{$c}{id} ||= $tempc->{$c}{id};
				$ids->{$names->{$c}{id}}{name} = $c;

				for my $p (keys %{$tempc->{$c}{properties}}) {
					$names->{$p}{id} ||= $tempc->{$c}{properties}{$p}[0];
					$ids->{$names->{$p}{id}}{name} ||= $p;
					unshift @{$names->{$p}{types}}, $tempc->{$c}{properties}{$p}[1];

					$class->{$c}{properties}{$p} = $tempc->{$c}{properties}{$p}
						if (exists $class->{$c} &&
							$class->{$c}{id} eq $tempc->{$c}{id} &&
							! exists $class->{$c}{properties}{$p});
				}

				unless (exists $class->{$c}) {
					$class->{$c} = $tempc->{$c};
				}
			}
		}

		$MERGEDCLASSES{ $db->{ID} } = [$class, $names, $ids];
	}
	return @{$MERGEDCLASSES{ $db->{ID} }};
}

#=============================================================================#
# "merge" additions, dialect, and glue enumerations together

sub _merge_enums {
	my($db, $self) = @_;
	if (!exists $MERGEDENUM{ $db->{ID} }) {
		my $names = $self->{NAMES};
		my $ids = $self->{IDS};

		for my $tempc (grep defined, $db->{ENUM}, @OTHERENUM) {
			for my $c (keys %$tempc) {
				$self->{ENUMTYPE}{$c} = [];
				for my $n (keys %{$tempc->{$c}}) {
					$names->{$n}{id} ||= $tempc->{$c}{$n}{id};
					$ids->{$names->{$n}{id}} ||= { name => $n };
					$self->{ENUM}{$tempc->{$c}{$n}{id}} = 1;
					push @{$self->{ENUMTYPE}{$c}}, $tempc->{$c}{$n}{id};
				}
			}
		}
		$MERGEDENUM{ $db->{ID} }++;
	}
	$MERGEDENUM{ $db->{ID} };
}

#=============================================================================#

*AE_GET = *Mac::AppleEvents::Simple::AE_GET{HASH};
*DESCS  = *Mac::AppleEvents::Simple::DESCS{HASH};

%INSL = (
	end		=> kAEEnd,
	before		=> kAEBefore,
	beginning  	=> kAEBeginning,
	front		=> kAEBeginning,
	after		=> kAEAfter,
	back		=> kAEAfter,
	behind		=> kAEAfter,
);

%COMP = (
	g_t		=> gGT(),
	g_e		=> gGE(),
	equals		=> gEquals(),
	l_t		=> gLT(),
	l_e		=> gLE(),
	begins_with	=> gBeginsWith(),
	ends_with	=> gEndsWith(),
	contains	=> gContains(),
);

%LOGI = (
	AND		=> gAnd(),
	OR		=> gOr(),
	NOT		=> gNot(),
);

%AE_PUT = (
	typeShortInteger()	=> sub {MacPack(typeShortInteger,	$_[0])},
	typeInteger()		=> sub {MacPack(typeInteger,		$_[0])},
	typeBoolean()		=> sub {MacPack(typeBoolean,		$_[0])},
	typeChar()		=> sub {MacPack(typeChar,		$_[0])},
	typeFSS()		=> sub {MacPack(typeFSS,		$_[0])},
	typeAlias()		=> sub {
		my $alis = NewAliasMinimalFromFullPath($_[0])
			or croak "Can't create alias for '$_[0]': $^E";
		return $alis->get;
	},
	typeWildCard()		=> sub {
		my $type = _get_type('', $_[0], typeWildCard);
		my $data = _get_data('', $_[0], $type);
		return($data, $type);
	},
	typeProcessSerialNumber() => sub { pack_psn($_[0]) },

	# just a guess here ... empty four bytes for lang code, maybe?
	'itxt' => sub {'    ' . MacPack(typeChar, $_[0])},
);

%DESC_TYPE = (
	formRange()	=> \&_do_range,
	formTest()	=> \&_do_whose,
);

%SPECIALEVENT = (
	'set'	=> {
		'class'		=> 'core',
		'event'		=> 'setd',
		'reply'		=> ['****', 0, 0, 0],
		'params'	=> {
			'----'	=> [keyDirectObject, 'obj ', 1, 0, 0, 1],
			'to'	=> ['data', '****', 1, 0, 0],
		}
	},
	'get'	=> {
		'class'		=> 'core',
		'event'		=> 'getd',
		'reply'		=> ['****', 1, 0, 0],
		'params'	=> {
			'----' => [keyDirectObject, 'obj ', 1, 0, 0, 0],
			'as' => ['rtyp', 'type', 0, 1, 0],
		}
	},
);

%SPECIALCLASS = (

);

#=============================================================================#
# other glue* stuff
for (gNull(), gAnd(), gOr(), gNot(), gGT(), gGE(), gEquals(),
	gLT(), gLE(), gBeginsWith(), gEndsWith(), gContains()) {
	_save_desc($_);   
}

#=============================================================================#

1;

__END__

=head1 NAME

Mac::Glue - Control Mac apps with Apple event terminology

=head1 SYNOPSIS

	use Mac::Glue;
	my $glue = Mac::Glue->new('Finder');
	$glue->open( $glue->prop('System Folder') );
	# see rest of docs for lots more info

=head1 DESCRIPTION

"Mac::Glue does AppleScript so you don't have to."

You should have the latest cpan-mac distribution:

	http://sourceforge.net/projects/cpan-mac/

For more information, support, CVS, etc.:

	http://sourceforge.net/projects/mac-glue/

Mac OS apps speak to each other with a I<lingua franca> called B<Apple
events>.  The most common way to do Apple events (aside from doaing them
in a precompiled application with C, Pascal, etc.) is with
AppleScript.  Other languages can do Apple events too, like Frontier and
even Python.  But we like Perl.

MacPerl has for a few years had an interface to Apple events, with the
Mac::AppleEvents module, which is the basis for everything we'll do
here.  Mac::AppleEvents::Simple was made to simplify the process of
doing Apple events in MacPerl, but even that can be too much trouble to
use.  One has to find out the class and event IDs, find out the keywords
and data types for each parameter, etc.

So the vision was born for a framework that wouldn't take much
significant work.  An application's AETE resource would provide the
names to match to the cryptic four-character codes we had been using. 
Compare.

=over 4

=item Raw Mac::AppleEvents method

	use Mac::AppleEvents;
	$evt = AEBuildAppleEvent('aevt', 'odoc', typeApplSignature, 'MACS',
		kAutoGenerateReturnID, kAnyTransactionID,
		"'----': obj{want:type(prop), from:'null'()," . 
		"form:prop, seld:type(macs)}"
	) or die $^E;
	$rep = AESend($evt, kAEWaitReply) or die $^E;
	AEDisposeDesc($evt);
	AEDisposeDesc($rep);

=item Easier Mac::AppleEvents::Simple method

	use Mac::AppleEvents::Simple;
	do_event(qw(aevt odoc MACS),
		"'----': obj{want:type(prop), from:'null'()," . 
		"form:prop, seld:type(macs)}"
	);

=item Cool Mac::Glue method

	use Mac::Glue;
	my $glue = Mac::Glue->new('Finder');
	$glue->open( $glue->prop('System Folder') );

=back

The latter is much simpler to understand, to read, to write.  It
leverages the user's understanding of AppleScript.  And it is just more
natural.

There are downsides.  Mac::Glue is less powerful than the
Mac::AppleEvents raw interfaces, because it offers less flexibility
in how events are called.  It is also slower to start a script,
because the glue structures need to be loaded in.  However, once a
script has started, a difference in speed from the raw interfaces should
be minimal (though not a lot of testing has been done on that).  With the
code above, on a PowerBook G3/292, running Mac OS 8.6:

    Benchmark: timing 100 iterations of glue, glue2, raw, simple...
          glue: 10 secs ( 9.98 usr  0.00 sys =  9.98 cpu)
         glue2:  8 secs ( 8.35 usr  0.00 sys =  8.35 cpu)
           raw:  8 secs ( 7.88 usr  0.00 sys =  7.88 cpu)
        simple:  7 secs ( 7.50 usr  0.00 sys =  7.50 cpu)

The "glue2" entry is the same as "glue" entry, but it creates a glue
object only once instead of each time through, cutting down on the
overhead.  It appears that Mac::Glue is a bit slower than the other
methods, but not substantially, and it is cooler and easier.
The one place where performance is the biggest problem is on
initial execution of the program, but once it starts it is plenty fast.
We'll work to cut down that start time, too.

So, now that you are convinced this is cool, let's continue.

=head2 Creating a Glue

In order to script an application with Mac::Glue, a glue must be created
first.  For that, the application is dropped on the F<gluemac> droplet.
A distribution called Mac::AETE, created by David Schooley, is used to
parse an application's AETE resource, and the glue is written out to a
file using Storable, DB_File, and MLDBM.  Glues are saved in
$ENV{MACGLUEDIR} (which is defined when Mac::Glue is used if it is not
defined already).  By default, glues are stored in
F<:site_perl:Mac:Glue:glues:>.

All glues have access to the global scripting additions and dialect
information.  Glues for these must be created as well, and are created
with the F<gluescriptadds> and F<gluedialect> programs, which are
similar to the F<gluemac> program.  They are saved in
"$ENV{MACGLUEDIR}additions:" and "$ENV{MACGLUEDIR}dialects:".

Along with the glue file is a POD file containing documentation for the
glue, listing all the events (with parameters), classes (with
properties), and enumerators, and descriptions of each.


=head2 Using a Glue

The first thing you do is call the module.

	use Mac::Glue;

Then you create an object for your app by passing the C<new> function
the name of the glue (you may include or omit underscores in the name if
you like).

	my $glue = Mac::Glue->new('My App');  # or My_App

You can also pass in additional parameters for the type of target to use.
For PPC ports, you can do this:

	my $glue = Mac::Glue->new('My App', ppc => 'My App Name',
		'Server Name', 'Zone');

You may also specify a process serial number:

	my $glue = Mac::Glue->new('My App', psn => $psn);

Note that C<$psn> should be a regular long integer, and will be packed into
a double long behind the scenes.  If this confuses you, don't worry about
it; the values returned from the Mac::Processes module are good to pass
back in as C<$psn>.

You can also pass a path to an application:

	my $glue = Mac::Glue->new('My App', path => $path_to_file);

New for Mac OS 9, you can send events over TCP/IP:

	my $glue = Mac::Glue->new('My App', eppc => 'My App Name',
		'some.machine.com');


Once you have your glue set up, you start calling events, as they are
documented in the POD file for the glue.  The events can be called
case-insensitively, with the exception of those that match the names of
the special methods (see L<"Special parameters and methods">).  In that
case, since the special methods are in all caps, the event methods can
be called case-insensitively except for all caps.  e.g., for an event
named C<reply>, it could be called with:

	$glue->Reply;
	$glue->reply;
	$glue->RePLY;

However, it could not be called with C<$glue-E<gt>REPLY>, since that
is reserved.

All applications respond to events differently.  Something that works for
one application might not work for another, so don't use any of these examples
as a way you should script a specific application.  They are just hyopthetical
examples, for the most part.

Events sometimes accept parameters, sometimes they don't.  The primary
parameter of most events is a special parameter called the I<direct
object> parameter.  In your event call, pass the data for that parameter
first:

	$glue->open($file);

Other parameters must be named and must be provided as key-value pairs,
with the key as the name of the parameter, and the value as the
parameter's data:

	$glue->open($file, using => $myapp);

Note that the direct object parameter is the only parameter that doesn't
need a name in front of it, and must come first in the list if it is
supplied at all.

Mac::Glue will attempt to coerce passed data into the expected type. 
For example, if C<open> expects an alias, the file specification in
C<$file> will be turned into an alias before being added to the event.

You can override this behavior with the C<param_type> function.  If
C<open> expects an alias (C<typeAlias>), but you want to pass text,
you can do:

	$glue->open( param_type(typeChar, $path) );

Each datum can be a simple scalar as above, an AEDesc object,
an Mac::AEObjDesc object (returned by C<obj>, C<prop>, and event methods),
an Mac::AEEnum object (returned by the C<enum> function), or an array or hash
reference, corresponding to AE lists and records.  In this example, we
nest them, with an arrayref as one of the values in the hashref, so the
AE list is a datum for one of the keys in the AE record:

	$glue->make(new => 'window', with_properties =>
		{name => "New Window", position => [100, 200]});

The words "name" and "position" will be changed into the proper
corresponding AE IDs.  And on return, record keys will be changed back
from the AE IDs into the English words.

Events return direct object parameters, turned into suitable data for
use in the program.  Aliases are resolved into file specifications, AE
records and lists are turned into Perl hashes and arrays (recursively,
for nested lists), etc.

	my @urls = $sherlock->search_internet('AltaVista',
		'for' => 'Mac::Glue');

AE objects (which will be discussed later) are returned as C<Mac::AEObjDesc>
objects, so they may be used again by being passed back to another
event.

	my $window_object = $glue->get( window => 1 );
	$glue->save($window_object);

This allows AppleScript-like loops:

	my @selection = $glue->get( $glue->prop(selection => of => window) );
	my @owners;
	for my $item (@selection) {
		push @owners, $glue->get( $glue->obj(cell => 'Owners' => $item) );
	}

Some objects may allow an easy way to get a human-readable form, with the
C<as> parameter:

	my $item = $glue->get( file => 1, as => 'string' );

Errors are returned in the special variable C<$^E>, which should be
checked immediately after an event call.

	$glue->close(window => 1);
	if ($^E) {
		warn "Couldn't close window: $^E\n";
	}

Or, if a value is expected and none is returned:

	my $file = $glue->choose_file('Select a file, please.')
		or die "No file chosen: $^E";

Checking C<$^E> only works if the error returned is an error number.
If it isn't, the actual error is available from the reply event,
which can be accessed by using the C<RETOBJ> parameter (described
below in L<"Special parameters and methods">).

You can also handle errors with the C<ERRORS> handlers (also
described below in L<"Special parameters and methods">).


=head2 Creating object specifier records

This is one of the more complex parts of Apple events, and it is only
partially implemented (though full implementation is expected
eventually, and most of it is implemented now).

Object specifier records are created by the C<obj> method, and have
four components to them.

=over 4

=item class

=item container

=item form

=item data

=back

The class and data are passed as key-value pairs, like in AE records or
parameter lists.  The form and the type of the data are determined by
the glue data or a good guess.  The container is determined by the order
of the key-value pairs: each pair is contained by the pair or object that
follows it.

	my $obj = $glue->obj(file => 'foo', folder => 'bar', disk => 'buz');

So you have three pairs.  The key of each pair ("file", "folder", "disk")
is the class.  The value of each pair ("foo", "bar", "baz") is the data.
Because the data are each text, the form defaults to formName,
and the data type defaults to typeChar (TEXT).  If the data is
a number, then the form would be formAbsolutePosition, and the data type
would be typeLongInteger.

So that leaves only the container.  Each pair is contained by the pair
following it.  The disk contains the folder, the folder contains the file.
The disk has no container (its container is null).

Easy, right?  I hope so.  That's the idea.  But let's go back to the
forms, since that is the only tough part left.

The primary forms are types, names, unique IDs, absolute positions,
relative positions, tests, and ranges.  Normally, text data has form
name and type TEXT.  Integer data has absolute position form, and
integer type.  The C<obj_form> function accepts three parameters, which
allows you to set the form and data, or form, type, and data, in case
you want to send data different from how Mac::Glue would guess.

These two are the same, since in the second case, the other is assumed:

	use Mac::Glue ':glue';

	$obj1 = $glue->obj(window =>
		obj_form(formAbsolutePostion, typeLongInteger, 1));

	$obj2 = $glue->obj(window => 1);

Special constants are exported that specify relative positions and
absolute positions.

	$first  = $glue->obj(file => gFirst, property => 'Desktop');
	$second = $glue->obj(file => gNext, $first);

	for ($first, $second) {
		print $glue->get($_, as => 'string');
	}

C<of> and C<in> are synonyms of C<property>:

	$glue->obj(file => gFirst, property => 'Desktop');
	$glue->obj(file => gFirst, of => 'Desktop');
	$glue->obj(file => gFirst, in => 'Desktop');

The "as" parameter above has a form of type, such as:

	obj_form(formPropertyID, typeType, 'string');

Then "string" is turned into a four-character ID behind the scenes (in
this case, it is "TEXT").

A special method called C<prop> is for specifying properties.  These are
equivalent:

	$glue->obj(property => 'Desktop');
	$glue->prop('Desktop');


=head2 Descriptor types for object specifier records

=over 4

=item Property IDs

Normally, the glue will know a property is expected and coerce whatever
string you provide into its four-character ID.  Sometimes
C<obj_form(formPropertyID, typeType, 'property_name')> may be
appropriate.

=item Name

Just pass the data as text.  If there is some ambiguity, you may explicitly
use C<obj_form(formName, typeChar, 'string')>.

=item Unique IDs

Could be anything.

=item Absolute position

As discussed above, if it is an index number, you can just pass the number,
as in C<window =E<gt> 1>, or you can explicitly mark it with
C<window =E<gt> obj_form(formAbsolutePosition, typeLongInteger, 1)>.

For other absolutes, you may use constants, such as
C<window =E<gt> gLast>.  Choices are C<gFirst>, C<gMiddle>,
C<gLast>, C<gAny>, C<gAll>.

These are just shortcuts for explicit forms like
C<obj_form(formAbsolutePosition, typeAbsoluteOrdinal, kAEAll)>.

Note that if there is a plural form of the class name, you may use it
to mean the same thing as "I<class> =E<gt> gAll".  These are all the
same:

	$f->obj(files => of => 'System Folder');
	$f->obj(files => gAll, of => 'System Folder');
	$f->obj(file => gAll, of => 'System Folder');

=item Relative position

Similar to absolute position, but an additional object must be
specified, such as C<file => gNext, file => gMiddle>, which would
return the file after the middle file.  Available constants are C<gNext>
and C<gPrevious>.

The explicit form is C<obj_form(formRelativePosition, typeEnumerated, kAENext)>.

=item Ranges

The C<range> function accepts two arguments, the start and stop ranges.

	range(START, STOP)

Each can be a number index, an absolute position constant, a string, or
another data type passed with C<obj_form>.  Here are a few ways to specify
files in the System Folder:

	$f->obj(files => range(1, 5), of => 'System Folder');
	$f->obj(files => range(1, "System"), of => 'System Folder');
	$f->obj(files => range("Finder", "System"), of => 'System Folder');
	$f->obj(files => range(gFirst, "System"), of => 'System Folder');

=item Whose tests

The C<whose> function accepts either logical records or comparison
records.

	# comparison record
	$f->obj(CLASS => whose(CLASS => VALUE, OPERATOR, VALUE));
	$f->obj(CLASS => whose(PROPERTY, OPERATOR, VALUE));

PROPERTY and CLASS => VALUE work like prop() and obj().  The PROPERTY
form is the same as C<property =E<gt> VALUE>.

OPERATOR is C<contains>, C<equals>, C<begins_with>, C<ends_with>,
C<l_t>, C<l_e>, C<g_t>, or C<g_e>.  VALUE is the value to compare to.

	# files whose name begins with "foo"
	$f->obj(files => whose(name => begins_with => 'foo'));

	# rows whose first cell equals "bar"
	$f->obj(rows => whose(cell => 1 => equals => 'bar'));


Then there is the logical record type, for use when more than one comparison
record is needed.

	# logical record
	$f->obj(CLASS => whose(OPERATOR, LIST));

OPERATOR is C<AND>, C<OR>, or C<NOT>.  LIST is any number of other logical
records or comparison records, contained in anonymous arrays.  So you can
join any number of records together:

	# words where it contains "e" and it begins with "p" and it does not end with "s"
	$aw->obj(
		words => whose(AND =>
			[it => contains => 'e'], [it => begins_with => 'p'],
			[NOT => [it => ends_with => 's']]
		), $text)

Note how each logical record and comparison record following each logical
operator is in an anonymous array.  Also not how the special word "it"
refers to the object being examined.

=back

There's one more record type that works similarly to the above object
specifier records, but is not exactly the same thing.
It's called an I<insertion location record>, and is created like this:

	location(POSITION[, OBJECT])

POSITION is a string, and can be one of C<before>, C<after>, C<beginning>,
or C<end>.  C<front> is a synonym for C<beginning>, and C<back> and C<behind>
are synonyms for C<after>.

OBJECT is the object to be positioned against, and will be the null object
if not supplied.

	my $aw = new Mac::Glue 'AppleWorks';
	my $text = $aw->prop(text_body => document => 1);
	$aw->activate;

	# note null object in location()
	$aw->make(new => 'document', at => location('front'));
	$aw->set($text, to => "foo bar buz baz.");

	$aw->move(
		$aw->obj(word => 4 => $text),
		to => location(after => $aw->obj(word => 2 => $text))
	);


=head2 Special parameters and methods

Special parameters can be passed in the event which control certain
aspects of the event call's behavior.  They can be passed as parameters
(affecting only the one event), or called as methods (which affect every
call made from that object).  They are all upper case.

	$glue->REPLY(1);		# wait for reply on all events
	$glue->close(REPLY => 0);	# don't wait for this one event

=over 4

=item REPLY

Boolean, for whether or not to wait for a reply.  Default is to wait.

=item MODE

Set other modes, such as C<kAENeverInteract>.  This value is OR'd
together with the REPLY value.  Default is C<kAECanInteract |
kAECanSwitchLayer>.

=item SWITCH

Switch to the application being called.  Usually more efficient to use
the C<activate> event:

	$glue->activate;

=item PRIORITY

Set the event priority.  Default is C<kAENormalPriority>.

=item TIMEOUT

Number of seconds to wait before timing out.  Default is a couple
hundred thousand seconds or so.

=item RETOBJ

Boolean, for whether or not the event call will return the direct object
data (the default), or a Mac::AppleEvents::Simple object, containing
references to the actual event and reply, so you can do more advanced
things with the data if you want to.

=item ERRORS

A subroutine reference that will handle any errors (that is, will
be executed only if C<$^E> is true) after the event is executed.
Your handler will be passed 6 or more arguments:

	0	The glue object
	1	The event object (same object returned by RETOBJ)
	2	The Glue's name
	3	The event's name
	4	The error message
	5	The error number
	6..n	Any arguments passed to the event in the first place

Example:

	sub error_handler {
		my($glue, $event, $gluename, $eventname,
			$errs, $errn, @args) = @_;
		my $args = join ', ', @args;
		die "$gluename->$eventname($args) event failed:\n$errs\n";
	}

	$finder->open(
		$finder->obj( item => 'HD' ), # nothing named HD in Finder
		ERRORS => \&error_handler
	);

Result:

	# Finder->open(DOBJ, Mac::AEObjDesc=HASH(0xc4c0814)) event failed:
	No such object (OS error -1728)

=back

=head2 Editing a Glue

There is an included droplet, F<glueedit>, for editing glues.  Drop
a created glue on the droplet, and it will make a text file on the
Desktop.  Edit it, and then drop the text file back on the droplet.
Be careful; this obviously can be dangerous.  If you break something,
you can use F<gluemac> to recreate the original glue, of course.

Why would you edit a glue?  Well, sometimes AETE resources are wrong.  :)


=head1 EXPORT

Mac::Glue has two export sets.  C<glue> exports the constants
and functions beginning with "glue" listed in
L<"Creating Object Specifier Records">, as well as the functions
C<obj_form>, C<enum>, C<location>, C<range>, and C<whose>.
C<all> exports everything from Mac::AppleEvents and
Mac::AppleEvents::Simple, including all functions and constants.
Nothing is exported by default.

	use Mac::Glue ':glue';  # good for most things
	use Mac::Glue ':all';   # for more advanced things


=head1 TIPS

=head2 Hide background apps

  use Mac::Glue;
  use Mac::Apps::Launch;
  $a = new Mac::Glue 'Acrobat Exchange';
  $a->launch;
  Hide($a->{ID});

  # now do your thing ...

=head2 Scripting Addition Maintenance

If you have a lot of scripting additions, it can slow down Mac::Glue
(on startup) and take up more RAM.  Same thing goes for Mac OS in general;
each installed additions takes up more RAM and has to be loaded into
the system, taking up extra time.  So only keep installed the ones
you want installed.

If you have a huge scripting addition and you only want to use a small
part of its functionality, you could also edit the glue and strip
out portions you don't want.  This is not recommended for those who
don't know precisely what they are doing, and the gains may be
unnoticable anyway.


=head1 GOTCHAS

=over 4

=item *

MAKE SURE F<site_perl> COMES FIRST IN YOUR LIBRARY PREFERENCES.
Thank you.  :-)

=item *

Do NOT send an event to the MacPerl application itself and expect a reply.
Instead, try C<$macperlglue-E<gt>REPLY(0)>.  Similarly, do not drop
MacPerl onto F<gluemac>.  Instead, you can make a copy of the MacPerl
application, and drop that on F<gluemac>.

=item *

You should have the latest cpan-mac distribution is installed.

=item *

You should delete old dialect glue files manually if running Mac OS 9.

=back


=head1 TODO / BUGS

=over 4

=item *

Specifying other attributes (transactions, etc.)

=item *

Add more coercions etc. to Mac::AppleEvents::Simple (feedback
wanted on this, let me know what I missed)

=item *

Add comparison operators from glues ?

=item *

"tell" objects to do events

=item *

New AETE flags in Mac OS 8.5, Mac OS 9?  Anything else new?  Anything
missing in backward compatibility to 7.5?

=item *

System of versioning (for glues and target apps) for distribution
of modified glues

=item *

MacPerl (I think) needs a new idle function for waiting for
replies

=item *

MacPerl hangs if it waits for a reply after sending an event to
itself

=item *

Handlers (on foo ...) ?

=item *

Callbacks (some support exists, Cameron Ashby E<lt>cameron@evolution.comE<gt>,
see Mac::AppleEvents::Simple) ?

=item *

Add dynamic fetching of glues?

=back


=head1 HISTORY

=over 4

=item v1.00, Tuesday, September 12, 2000

Added error handling via ERRORS parameter / method.

General cleanup, additional examples.

=item v0.58, Tuesday, November 16, 1999

Change all of the classes to have C<Mac::> at the beginning of them
(except for ones that originate elsewhere, like C<AEDesc>, et al).

Added C<Mac::AEParamType> and C<param_type>.

If a parameter expects an AE object specifier record, and is not passed one,
then it guesses the type and sets it to either C<typeChar> or C<typeInteger>.

Made the conversion of keys into English names recursive with lists,
in addition to records (i.e., lists can contain multiple records).


=item v0.57, Tuesday, November 2, 1999

Added conversion of keys in returned records back into the "English" names.

Records containing C<class> parameter are coerced into descriptors of
that class (i.e., C<{name =E<gt> 'foo', class =E<gt> 'disk'}>).

Added support for events over TCP/IP (Mac OS 9 required).

Note: if Keychain Access is used in Mac OS 9, the C<login> method may no
longer be required for accessing of remote machines.

Fixed bug in C<can> method; also changed how C<can> calls C<AUTOLOAD>.

Added code for experimental callback stuff, undocumented,
subject to change, and probably does not even work.

Changed C<_get_name> to C<_get_id>, created new C<_get_name>.

Updated dialect creation code for Mac OS 9 (aeut is now stored in
the F<AppleScript> extension instead of a dialect file, but for
Mac::Glue is still stored in the F<dialects> folder.  Instead
of being called F<English>, it will likely be called F<AppleScript>.
You should delete (or archive) old dialect glues manually.


=item v0.56, Friday, September 10, 1999

If plural class is used (i.e., I<files> for I<file>), and the following value
is not an C<AE*> object, then it will become "every I<class>".
(Jeff Lowrey)

Added more documentation about using C<AEObjDesc> objects.  (Jeff Lowrey)

=item v0.55, Thursday, September 2, 1999

Added extra arguments to C<new> to accept
alternate targets.  PPC ports, PSNs, and paths are explicitly accepted now.
(Paths are first launched, then the PSN is found ... aliases won't
work properly as paths.)

Added C<login> class method to tell MacPerl to try logging in
with specified username and password.  Requires F<Login As>
OSAX from the F<GTQ Scripting Library>.

=item v0.51, Wednesday, September 1, 1999

Changed ordering of search in C<_find_event>.

Fixed doc problems in Mac::AETE::Format::Glue: inheritance
classes are named, and optional parameters are properly
denoted.

=item v0.50, 12 July 1999

Added g* constants in addition to glue* constants.  Use whichever
you like, but I will use g* for everything.  If you don't want the
g* constants, because they conflict with something, use the
C<:long> and C<:longall> import tags instead of C<:glue> and C<:all>.

Gone to beta!  Woo!

=item v0.31, 22 June 1999

Fixed bug that only found class names instead of class and property
names in creation of object specifier records.

Fixed bug which changed directories on initialization, and didn't change
it back.

Allow case-insensitive parameter names.

=item v0.30, 16 June 1999

Changed function names:
C<glueInsertion> is now C<location>, C<glueRange> is now C<range>.

Added C<whose> function.

Added C<can> method which correctly finds available events.

Made special parameters, formerly with leading underscore and lowercase,
to all uppercase with no underscore (i.e., C<_retobj> is now C<RETOBJ>).

Added C<of> and C<in> as synonyms for C<property> in C<obj> method calls.

Put C<AEObjDesc> back in!  Will use in the future, maybe, to use objects
as targets for events.

Return all descriptors from C<obj> and C<prop>, and all objects
returned from events, as C<AEObjDesc> objects.

Added C<glueTrue> and C<glueFalse> constants.

Tried again to suppress warnings during initial scripting additions and
dialect creation.

Tons of internal cleaning up.

=item v0.26, 07 June 1999

Made choice of serializer for glue more intelligent: FreezeThaw
automatically picked for CFM68K, Storable for PPC.

Updated Mac::AppleEvents and Mac::Memory, fixed more bugs and
added constants.  Fixed bug in AutoSplit.

Added C<glueInsertion>, C<glueRange>, and C<glueNull>.

Completely removed C<AEObjDesc> package, which existed to support
destruction of descriptors.  Use global hash now to keep track
of descriptors to destroy (L<Mac::AppleEvents::Simple>).  So
all descriptors returned from C<obj> and C<prop> and others are
C<AEDesc> objects.

Changed ordering of items in creating object specifiers in
C<_do_obj> to match AppleScript, so comparing to Capture AE
output would be easier.

Put C<%AE_PUT> back in Mac::Glue and left C<%AE_GET> in
Mac::AppleEvents::Simple.

Switched C<DOBJ, {PARAM1 =E<gt> DATA1}> to C<DOBJ, PARAM1 =E<gt> DATA1>
in event calls.

Always default to wait for reply and no timeout if unspecified by user.

Return useful errors in C<$^E>.

Accept and return nested arrays/lists and hashes/records.

Call events and pass classes / properties case-insensitively.


Other miscellaneous changes.  Some cleaning up.

=item v0.25, 30 May 1999

Add serializer option.

Updates to Mac::Memory and Mac::AppleEvents and Mac::AppleEvents::Simple.

Added constants for absolute and relative positions.

Added C<enum>.

Put C<o> and C<p> back as C<obj> and C<prop>.

Other miscellaneous changes.  Lots of cleaning up.

=item v0.20, 22 May 1999

Complete rewrite.  Too many changes to bother mentioning, because I am lazy.

=item v0.09, 13 October 1998

Added ability to use properties.  These are called with the C<p> method:

	$obj->get($obj->p('label_index', item=>'HD'));

which is equivalent to:

	$obj->get($obj->o(property=>'label_index', item=>'HD'));

=item v0.08, 10 October 1998

Unreleased.

Significant cleanup of module, in large part unfinished changes from
last version.

No longer doing error checking for whether lists are allowed or objects
are allowed, because these are sometimes wrong or undetectable.  Also,
will not raise exception on a missing required parameter, but will warn
if C<-w> is on.

C<obj_form> is exported from the glue modules, and all of the functions
and constant from C<Mac::AppleEvents> can be imported from a glue module
with the C<:all> tag:

	use Mac::Glue::SomeApp qw(:all);

=item v0.07, 30 September 1998

More documentation and bugfixes.  Having serious problems with
C<AEObjDesc::DESTROY>.

=item v0.06, 29 September 1998

Whole bunches of changes.  Note that glues made under 0.05 no longer work.

=back


=head1 AUTHOR

Chris Nandor E<lt>pudge@pobox.comE<gt>, http://pudge.net/

Copyright (c) 1998-2000 Chris Nandor.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the terms
of the Artistic License, distributed with Perl.


=head1 THANKS

Matthias Neeracher E<lt>neeri@iis.ee.ethz.chE<gt>,
David Schooley E<lt>dcschooley@mediaone.netE<gt>,
Graham Barr E<lt>gbarr@pobox.comE<gt>,
John W Baxter E<lt>jwblist@olympus.netE<gt>,
Marion Delgado E<lt>dhp@efn.orgE<gt>,
Eric Dobbs E<lt>dobbs@visionlink.orgE<gt>,
Josh Gemmell E<lt>joshg@ola.bc.caE<gt>,
Alex Harper E<lt>harper@misanthrope.netE<gt>,
Nathaniel Irons E<lt>irons@espresso.hampshire.eduE<gt>,
Dave Johnson E<lt>dave_johnson@ieee.orgE<gt>,
Bart Lateur E<lt>bart.mediamind@ping.beE<gt>,
Jefferson R. Lowrey E<lt>lowrey@mailbag.comE<gt>,
Mat Marcus E<lt>mmarcus@adobe.comE<gt>,
Larry Moore E<lt>ljmoore@freespace.netE<gt>,
Ricardo Muggli E<lt>rtmuggli@carlsoncraft.comE<gt>,
Vincent Nonnenmacher E<lt>dpi@pobox.oleane.comE<gt>,
Henry Penninkilampi E<lt>htp@metropolis.net.auE<gt>,
Peter Prymmer E<lt>pvhp@best.comE<gt>,
Ramesh R. E<lt>sram0mp@radon.comm.mot.comE<gt>,
Axel Rose E<lt>rose@sj.comE<gt>,
Stephan Somogyi E<lt>somogyi@gyroscope.netE<gt>,
Kevin Walker E<lt>kwalker@xmission.comE<gt>,
Matthew Wickline E<lt>mattheww@wickline.orgE<gt>.

(If I left your name out, please remind me.)


=head1 SEE ALSO

Mac::AppleEvents, Mac::AppleEvents::Simple, macperlcat, Inside Macintosh: 
Interapplication Communication.

	http://sourceforge.net/projects/mac-glue/

=cut


=head1 VERSION

v1.00, Tuesday, September 12, 2000
