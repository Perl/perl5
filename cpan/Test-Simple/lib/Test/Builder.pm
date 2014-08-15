package Test::Builder;

use 5.008001;
use strict;
use warnings;

use Test::Builder::Util qw/try protect/;
use Scalar::Util();
use Test::Builder::Stream;
use Test::Builder::Result;
use Test::Builder::Result::Ok;
use Test::Builder::Result::Diag;
use Test::Builder::Result::Note;
use Test::Builder::Result::Plan;
use Test::Builder::Result::Bail;
use Test::Builder::Result::Child;
use Test::Builder::Trace;

our $VERSION = '1.301001_034';
$VERSION = eval $VERSION;    ## no critic (BuiltinFunctions::ProhibitStringyEval)

# The mostly-singleton, and other package vars.
our $Test  = Test::Builder->new;
our $Level = 1;
our $BLevel = 1;

####################
# {{{ MAGIC things #
####################

sub DESTROY {
    my $self = shift;
    if ( $self->parent and $$ == $self->{Original_Pid} ) {
        my $name = $self->name;
        $self->parent->{In_Destroy} = 1;
        $self->parent->ok(0, $name, "Child ($name) exited without calling finalize()\n");
    }
}

require Test::Builder::ExitMagic;
my $final = Test::Builder::ExitMagic->new(
    tb => Test::Builder->create(shared_stream => 1),
);
END { $final->do_magic() }

####################
# }}} MAGIC things #
####################

####################
# {{{ Constructors #
####################

sub new {
    my $class = shift;
    my %params = @_;
    $Test ||= $class->create(shared_stream => 1);

    return $Test;
}

sub create {
    my $class = shift;
    my %params = @_;

    my $self = bless {}, $class;
    $self->reset(%params);

    return $self;
}

# Copy an object, currently a shallow.
# This does *not* bless the destination.  This keeps the destructor from
# firing when we're just storing a copy of the object to restore later.
sub _copy {
    my($src, $dest) = @_;

    %$dest = %$src;
    #_share_keys($dest); # Not sure the implications here.

    return;
}

####################
# }}} Constructors #
####################

##############################################
# {{{ Simple accessors/generators/deligators #
##############################################

sub listen     { shift->stream->listen(@_)     }
sub munge      { shift->stream->munge(@_)      }
sub tap        { shift->stream->tap            }
sub lresults   { shift->stream->lresults       }
sub is_passing { shift->stream->is_passing(@_) }
sub use_fork   { shift->stream->use_fork       }
sub no_fork    { shift->stream->no_fork        }

BEGIN {
    Test::Builder::Util::accessors(qw/Parent Name _old_level _bailed_out default_name/);
    Test::Builder::Util::accessor(modern => sub {$ENV{TB_MODERN} || 0});
    Test::Builder::Util::accessor(depth  => sub { 0 });
}

##############################################
# }}} Simple accessors/generators/deligators #
##############################################

#########################
# {{{ Stream Management #
#########################

sub stream {
    my $self = shift;

    ($self->{stream}) = @_ if @_;

    # If no stream is set use shared. We do not want to cache that we use
    # shared cause shared is a stack, not a constant, and we always want the
    # top.
    return $self->{stream} || Test::Builder::Stream->shared;
}

sub intercept {
    my $self = shift;
    my ($code) = @_;

    Carp::croak("argument to intercept must be a coderef, got: $code")
        unless reftype $code eq 'CODE';

    my $stream = Test::Builder::Stream->new(no_follow => 1) || die "Internal Error!";
    $stream->exception_followup;

    local $self->{stream} = $stream;

    my @results;
    $stream->listen(INTERCEPTOR => sub {
        my ($item) = @_;
        push @results => $item;
    });
    $code->($stream);

    return \@results;
}

#########################
# }}} Stream Management #
#########################

#############################
# {{{ Children and subtests #
#############################

sub child {
    my( $self, $name, $is_subtest ) = @_;

    $self->croak("You already have a child named ($self->{Child_Name}) running")
        if $self->{Child_Name};

    my $parent_in_todo = $self->in_todo;

    # Clear $TODO for the child.
    my $orig_TODO = $self->find_TODO(undef, 1, undef);

    my $class = Scalar::Util::blessed($self);
    my $child = $class->create;

    $child->{stream} = $self->stream->spawn;

    # Ensure the child understands if they're inside a TODO
    $child->tap->failure_output($self->tap->todo_output)
        if $parent_in_todo && $self->tap;

    # This will be reset in finalize. We do this here lest one child failure
    # cause all children to fail.
    $child->{Child_Error} = $?;
    $?                    = 0;

    $child->{Parent}      = $self;
    $child->{Parent_TODO} = $orig_TODO;
    $child->{Name}        = $name || "Child of " . $self->name;

    $self->{Child_Name}   = $child->name;

    $child->depth($self->depth + 1);

    my $res = Test::Builder::Result::Child->new(
        $self->context,
        name    => $child->name,
        action  => 'push',
        in_todo => $self->in_todo || 0,
        is_subtest => $is_subtest || 0,
    );
    $self->stream->send($res);

    return $child;
}

sub subtest {
    my $self = shift;
    my($name, $subtests, @args) = @_;

    $self->croak("subtest()'s second argument must be a code ref")
        unless $subtests && 'CODE' eq Scalar::Util::reftype($subtests);

    # Turn the child into the parent so anyone who has stored a copy of
    # the Test::Builder singleton will get the child.
    my ($success, $error, $child);
    my $parent = {};
    {
        local $Level = $Level + 1; local $BLevel = $BLevel + 1;

        # Store the guts of $self as $parent and turn $child into $self.
        $child  = $self->child($name, 1);

        _copy($self,  $parent);
        _copy($child, $self);

        my $run_the_subtests = sub {
            $subtests->(@args);
            $self->done_testing unless defined $self->stream->plan;
            1;
        };

        ($success, $error) = try { Test::Builder::Trace->nest($run_the_subtests) };
    }

    # Restore the parent and the copied child.
    _copy($self,   $child);
    _copy($parent, $self);

    # Restore the parent's $TODO
    $self->find_TODO(undef, 1, $child->{Parent_TODO});

    # Die *after* we restore the parent.
    die $error if $error && !(Scalar::Util::blessed($error) && $error->isa('Test::Builder::Exception'));

    local $Level = $Level + 1; local $BLevel = $BLevel + 1;
    my $finalize = $child->finalize(1);

    $self->BAIL_OUT($child->{Bailed_Out_Reason}) if $child->_bailed_out;

    return $finalize;
}

sub finalize {
    my $self = shift;
    my ($is_subtest) = @_;

    return unless $self->parent;
    if( $self->{Child_Name} ) {
        $self->croak("Can't call finalize() with child ($self->{Child_Name}) active");
    }

    local $? = 0;     # don't fail if $subtests happened to set $? nonzero
    $self->_ending;

    local $Level = $Level + 1; local $BLevel = $BLevel + 1;
    my $ok = 1;
    $self->parent->{Child_Name} = undef;

    unless ($self->_bailed_out) {
        if ( $self->{Skip_All} ) {
            $self->parent->skip($self->{Skip_All});
        }
        elsif ( ! $self->stream->tests_run ) {
            $self->parent->ok( 0, sprintf q[No tests run for subtest "%s"], $self->name );
        }
        else {
            $self->parent->ok( $self->is_passing, $self->name );
        }
    }

    $? = $self->{Child_Error};
    my $parent = delete $self->{Parent};

    my $res = Test::Builder::Result::Child->new(
        $self->context,
        name    => $self->{Name} || undef,
        action  => 'pop',
        in_todo => $self->in_todo || 0,
        is_subtest => $is_subtest || 0,
    );
    $parent->stream->send($res);

    return $self->is_passing;
}

#############################
# }}} Children and subtests #
#############################

#####################################
# {{{ Finding Testers and Providers #
#####################################

sub trace_test {
    my $out;
    protect { $out = Test::Builder::Trace->new };
    return $out;
}

sub find_TODO {
    my( $self, $pack, $set, $new_value ) = @_;

    $pack ||= $self->trace_test->todo_package || $self->exported_to;
    return unless $pack;

    no strict 'refs';    ## no critic
    no warnings 'once';
    my $old_value = ${ $pack . '::TODO' };
    $set and ${ $pack . '::TODO' } = $new_value;
    return $old_value;
}

#####################################
# }}} Finding Testers and Providers #
#####################################

################
# {{{ Planning #
################

my %PLAN_CMDS = (
    no_plan  => 'no_plan',
    skip_all => 'skip_all',
    tests    => '_plan_tests',
);

sub plan {
    my( $self, $cmd, $arg ) = @_;

    return unless $cmd;

    local $Level = $Level + 1; local $BLevel = $BLevel + 1;

    if( my $method = $PLAN_CMDS{$cmd} ) {
        local $Level = $Level + 1; local $BLevel = $BLevel + 1;
        $self->$method($arg);
    }
    else {
        my @args = grep { defined } ( $cmd, $arg );
        $self->croak("plan() doesn't understand @args");
    }

    return 1;
}

sub skip_all {
    my( $self, $reason ) = @_;

    $self->{Skip_All} = $self->parent ? $reason : 1;

    die bless {} => 'Test::Builder::Exception' if $self->parent;
    $self->_issue_plan(0, "SKIP", $reason);
}

sub no_plan {
    my($self, $arg) = @_;

    $self->carp("no_plan takes no arguments") if $arg;

    $self->_issue_plan(undef, "NO_PLAN");

    return 1;
}

sub _plan_tests {
    my($self, $arg) = @_;

    if($arg) {
        $self->croak("Number of tests must be a positive integer.  You gave it '$arg'")
            unless $arg =~ /^\+?\d+$/;

        $self->_issue_plan($arg);
    }
    elsif( !defined $arg ) {
        $self->croak("Got an undefined number of tests");
    }
    else {
        $self->croak("You said to run 0 tests");
    }

    return;
}

sub _issue_plan {
    my($self, $max, $directive, $reason) = @_;

    if ($directive && $directive eq 'OVERRIDE') {
        $directive = undef;
    }
    elsif ($self->stream->plan) {
        $self->croak("You tried to plan twice");
    }

    my $plan = Test::Builder::Result::Plan->new(
        $self->context,
        directive => $directive     || undef,
        reason    => $reason        || undef,
        in_todo   => $self->in_todo || 0,

        max => defined($max) ? $max : undef,
    );

    $self->stream->send($plan);

    return $plan;
}

sub done_testing {
    my($self, $num_tests) = @_;

    my $expected = $self->stream->expected_tests;
    my $total    = $self->stream->tests_run;

    # If done_testing() specified the number of tests, shut off no_plan.
    if(defined $num_tests && !defined $expected) {
        $self->_issue_plan($num_tests, 'OVERRIDE');
        $expected = $num_tests;
    }

    if( $self->{Done_Testing} ) {
        my($file, $line) = @{$self->{Done_Testing}}[1,2];
        my $ok = Test::Builder::Result::Ok->new(
            $self->context,
            real_bool => 0,
            name      => "done_testing() was already called at $file line $line",
            bool      => $self->in_todo ? 1 : 0,
            in_todo   => $self->in_todo || 0,
            todo      => $self->in_todo ? $self->todo() || "" : "",
        );
        $self->stream->send($ok);
        $self->is_passing(0) unless $self->in_todo;

        return;
    }

    $self->{Done_Testing} = [caller];

    if ($expected && defined($num_tests) && $num_tests != $expected) {
        my $ok = Test::Builder::Result::Ok->new(
            $self->context,
            real_bool => 0,
            name      => "planned to run $expected but done_testing() expects $num_tests",
            bool      => $self->in_todo ? 1 : 0,
            in_todo   => $self->in_todo || 0,
            todo      => $self->in_todo ? $self->todo() || "" : "",
        );
        $self->stream->send($ok);
        $self->is_passing(0) unless $self->in_todo;
    }


    $self->_issue_plan($total) unless $expected;

    # The wrong number of tests were run
    $self->is_passing(0) if defined $expected && $expected != $total;

    # No tests were run
    $self->is_passing(0) unless $total;

    return 1;
}

################
# }}} Planning #
################

#############################
# {{{ Base Result Producers #
#############################

sub _ok_obj {
    my $self = shift;
    my( $test, $name, @diag ) = @_;

    if ( $self->{Child_Name} and not $self->{In_Destroy} ) {
        $name = 'unnamed test' unless defined $name;
        $self->is_passing(0);
        $self->croak("Cannot run test ($name) with active children");
    }

    # $test might contain an object which we don't want to accidentally
    # store, so we turn it into a boolean.
    $test = $test ? 1 : 0;

    # In case $name is a string overloaded object, force it to stringify.
    $self->_unoverload_str( \$name );

    # Capture the value of $TODO for the rest of this ok() call
    # so it can more easily be found by other routines.
    my $todo    = $self->todo();
    my $in_todo = $self->in_todo;
    local $self->{Todo} = $todo if $in_todo;

    $self->_unoverload_str( \$todo );

    my $ok = Test::Builder::Result::Ok->new(
        $self->context,
        real_bool => $test,
        bool      => $self->in_todo ? 1 : $test,
        name      => $name          || $self->default_name || undef,
        in_todo   => $self->in_todo || 0,
        diag      => \@diag,
    );

    # # in a name can confuse Test::Harness.
    $name =~ s|#|\\#|g if defined $name;

    if( $self->in_todo ) {
        $ok->todo($todo);
        $ok->in_todo(1);
    }

    if (defined $name and $name =~ /^[\d\s]+$/) {
        $ok->diag(<<"        ERR");
    You named your test '$name'.  You shouldn't use numbers for your test names.
    Very confusing.
        ERR
    }

    return $ok;
}

sub ok {
    my $self = shift;
    my( $test, $name, @diag ) = @_;

    my $ok = $self->_ok_obj($test, $name, @diag);
    $self->_record_ok($ok);

    return $test ? 1 : 0;
}

sub _record_ok {
    my $self = shift;
    my ($ok) = @_;

    $self->stream->send($ok);

    $self->is_passing(0) unless $ok->real_bool || $self->in_todo;

    # Check that we haven't violated the plan
    $self->_check_is_passing_plan();
}

sub BAIL_OUT {
    my( $self, $reason ) = @_;

    $self->_bailed_out(1);

    if ($self->parent) {
        $self->{Bailed_Out_Reason} = $reason;
        $self->no_ending(1);
        die bless {} => 'Test::Builder::Exception';
    }

    my $bail = Test::Builder::Result::Bail->new(
        $self->context,
        reason  => $reason,
        in_todo => $self->in_todo || 0,
    );
    $self->stream->send($bail);
}

sub skip {
    my( $self, $why ) = @_;
    $why ||= '';
    $self->_unoverload_str( \$why );

    my $ok = Test::Builder::Result::Ok->new(
        $self->context,
        real_bool => 1,
        bool      => 1,
        in_todo   => $self->in_todo || 0,
        skip      => $why,
    );

    $self->stream->send($ok);
}

sub todo_skip {
    my( $self, $why ) = @_;
    $why ||= '';

    my $ok = Test::Builder::Result::Ok->new(
        $self->context,
        real_bool => 0,
        bool      => 1,
        in_todo   => $self->in_todo || 0,
        skip      => $why,
        todo      => $why,
    );

    $self->stream->send($ok);
}

sub diag {
    my $self = shift;

    my $msg = join '', map { defined($_) ? $_ : 'undef' } @_;

    my $r = Test::Builder::Result::Diag->new(
        $self->context,
        in_todo => $self->in_todo || 0,
        message => $msg,
    );
    $self->stream->send($r);
}

sub note {
    my $self = shift;

    my $msg = join '', map { defined($_) ? $_ : 'undef' } @_;

    my $r = Test::Builder::Result::Note->new(
        $self->context,
        in_todo => $self->in_todo || 0,
        message => $msg,
    );
    $self->stream->send($r);
}

#############################
# }}} Base Result Producers #
#############################

#################################
# {{{ Advanced Result Producers #
#################################

my %numeric_cmps = map { ( $_, 1 ) } ( "<", "<=", ">", ">=", "==", "!=", "<=>" );

# Bad, these are not comparison operators. Should we include more?
my %cmp_ok_bl = map { ( $_, 1 ) } ( "=", "+=", ".=", "x=", "^=", "|=", "||=", "&&=", "...");

sub cmp_ok {
    my( $self, $got, $type, $expect, $name ) = @_;

    if ($cmp_ok_bl{$type}) {
        $self->croak("$type is not a valid comparison operator in cmp_ok()");
    }

    my $test;
    my $error;
    my @diag;

    my($pack, $file, $line) = $self->trace_test->report->call;

    (undef, $error) = try {
        # This is so that warnings come out at the caller's level
        ## no critic (BuiltinFunctions::ProhibitStringyEval)
        eval qq[
#line $line "(eval in cmp_ok) $file"
\$test = \$got $type \$expect;
1;
        ] || die $@;
    };

    # Treat overloaded objects as numbers if we're asked to do a
    # numeric comparison.
    my $unoverload
      = $numeric_cmps{$type}
      ? '_unoverload_num'
      : '_unoverload_str';

    push @diag => <<"END" if $error;
An error occurred while using $type:
------------------------------------
$error
------------------------------------
END

    unless($test) {
        $self->$unoverload( \$got, \$expect );

        if( $type =~ /^(eq|==)$/ ) {
            push @diag => $self->_is_diag( $got, $type, $expect );
        }
        elsif( $type =~ /^(ne|!=)$/ ) {
            push @diag => $self->_isnt_diag( $got, $type );
        }
        else {
            push @diag => $self->_cmp_diag( $got, $type, $expect );
        }
    }

    local $Level = $Level + 1; local $BLevel = $BLevel + 1;
    $self->ok($test, $name, @diag);

    return $test ? 1 : 0;
}


sub is_eq {
    my( $self, $got, $expect, $name ) = @_;
    local $Level = $Level + 1; local $BLevel = $BLevel + 1;

    if( !defined $got || !defined $expect ) {
        # undef only matches undef and nothing else
        my $test = !defined $got && !defined $expect;

        $self->ok($test, $name, $test ? () : $self->_is_diag( $got, 'eq', $expect ));
        return $test;
    }

    return $self->cmp_ok( $got, 'eq', $expect, $name );
}

sub is_num {
    my( $self, $got, $expect, $name ) = @_;
    local $Level = $Level + 1; local $BLevel = $BLevel + 1;

    if( !defined $got || !defined $expect ) {
        # undef only matches undef and nothing else
        my $test = !defined $got && !defined $expect;

        $self->ok($test, $name, $test ? () : $self->_is_diag( $got, '==', $expect ));
        return $test;
    }

    return $self->cmp_ok( $got, '==', $expect, $name );
}

sub isnt_eq {
    my( $self, $got, $dont_expect, $name ) = @_;
    local $Level = $Level + 1; local $BLevel = $BLevel + 1;

    if( !defined $got || !defined $dont_expect ) {
        # undef only matches undef and nothing else
        my $test = defined $got || defined $dont_expect;

        $self->ok( $test, $name, $test ? () : $self->_isnt_diag( $got, 'ne' ));
        return $test;
    }

    return $self->cmp_ok( $got, 'ne', $dont_expect, $name );
}

sub isnt_num {
    my( $self, $got, $dont_expect, $name ) = @_;
    local $Level = $Level + 1; local $BLevel = $BLevel + 1;

    if( !defined $got || !defined $dont_expect ) {
        # undef only matches undef and nothing else
        my $test = defined $got || defined $dont_expect;

        $self->ok( $test, $name, $test ? () : $self->_isnt_diag( $got, '!=' ));
        return $test;
    }

    return $self->cmp_ok( $got, '!=', $dont_expect, $name );
}

sub like {
    my( $self, $thing, $regex, $name ) = @_;
    local $Level = $Level + 1; local $BLevel = $BLevel + 1;

    return $self->_regex_ok( $thing, $regex, '=~', $name );
}

sub unlike {
    my( $self, $thing, $regex, $name ) = @_;
    local $Level = $Level + 1; local $BLevel = $BLevel + 1;

    return $self->_regex_ok( $thing, $regex, '!~', $name );
}



#################################
# }}} Advanced Result Producers #
#################################

#######################
# {{{ Public helpers #
#######################

sub explain {
    my $self = shift;

    return map {
        ref $_
          ? do {
            $self->_try(sub { require Data::Dumper }, die_on_fail => 1);

            my $dumper = Data::Dumper->new( [$_] );
            $dumper->Indent(1)->Terse(1);
            $dumper->Sortkeys(1) if $dumper->can("Sortkeys");
            $dumper->Dump;
          }
          : $_
    } @_;
}

sub carp {
    my $self = shift;
    return warn $self->_message_at_caller(@_);
}

sub croak {
    my $self = shift;
    return die $self->_message_at_caller(@_);
}

sub context {
    my $self = shift;

    my $trace = $self->trace_test;

    return (
        depth  => $self->depth,
        source => $self->name || "",
        trace  => $trace,
    );
}

sub has_plan {
    my $self = shift;

    return($self->stream->expected_tests) if $self->stream->expected_tests;
    return('no_plan') if $self->stream->plan;
    return(undef);
}

sub reset {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my $self = shift;
    my %params;

    if (@_) {
        %params = @_;
        $self->{reset_params} = \%params;
    }
    else {
        %params = %{$self->{reset_params} || {}};
    }

    my $modern = $params{modern} || $self->modern || 0;
    $self->modern($modern);

    # We leave this a global because it has to be localized and localizing
    # hash keys is just asking for pain.  Also, it was documented.
    $Level = 1;
    $BLevel = 1;

    if ($params{new_stream} || !$params{shared_stream}) {
        my $olds = $self->stream;
        $self->{stream} = Test::Builder::Stream->new;
        $self->{stream}->use_lresults if $olds->lresults;
    }

    $final->pid($$) if $final;

    $self->stream->use_tap unless $params{no_tap} || $ENV{TB_NO_TAP};

    $self->stream->plan(undef) unless $params{no_reset_plan};

    # Don't reset stream stuff when reseting/creating a modern TB object
    unless ($modern) {
        $self->stream->no_ending(0);
        $self->tap->reset      if $self->tap;
        $self->lresults->reset if $self->lresults;
    }

    $self->{Name}  = $0;

    $self->{Have_Issued_Plan} = 0;
    $self->{Done_Testing}     = 0;
    $self->{Skip_All}         = 0;

    $self->{Original_Pid} = $$;
    $self->{Child_Name}   = undef;
    $self->{Indent}     ||= '';
    $self->{Depth}        = 0;

    $self->{Exported_To}    = undef;
    $self->{Expected_Tests} = 0;

    $self->{Todo}       = undef;
    $self->{Todo_Stack} = [];
    $self->{Start_Todo} = 0;
    $self->{Opened_Testhandles} = 0;

    return;
}


#######################
# }}} Public helpers #
#######################

####################
# {{{ TODO related #
####################

sub todo {
    my( $self, $pack ) = @_;

    return $self->{Todo} if defined $self->{Todo};

    local $Level = $Level + 1; local $BLevel = $BLevel + 1;
    my $todo = $self->find_TODO($pack);
    return $todo if defined $todo;

    return '';
}

sub in_todo {
    my $self = shift;

    local $Level = $Level + 1; local $BLevel = $BLevel + 1;
    return( defined $self->{Todo} || $self->find_TODO ) ? 1 : 0;
}

sub todo_start {
    my $self = shift;
    my $message = @_ ? shift : '';

    $self->{Start_Todo}++;
    if( $self->in_todo ) {
        push @{ $self->{Todo_Stack} } => $self->todo;
    }
    $self->{Todo} = $message;

    return;
}

sub todo_end {
    my $self = shift;

    if( !$self->{Start_Todo} ) {
        $self->croak('todo_end() called without todo_start()');
    }

    $self->{Start_Todo}--;

    if( $self->{Start_Todo} && @{ $self->{Todo_Stack} } ) {
        $self->{Todo} = pop @{ $self->{Todo_Stack} };
    }
    else {
        delete $self->{Todo};
    }

    return;
}

####################
# }}} TODO related #
####################

#######################
# {{{ Private helpers #
#######################

# Check that we haven't yet violated the plan and set
# is_passing() accordingly
sub _check_is_passing_plan {
    my $self = shift;

    my $plan = $self->stream->expected_tests;
    return unless defined $plan;        # no plan yet defined
    return unless $plan !~ /\D/;        # no numeric plan
    $self->is_passing(0) if $plan < $self->stream->tests_run;
}

sub _is_object {
    my( $self, $thing ) = @_;

    return $self->_try( sub { ref $thing && $thing->isa('UNIVERSAL') } ) ? 1 : 0;
}

sub _unoverload {
    my $self = shift;
    my $type = shift;

    $self->_try(sub { require overload; }, die_on_fail => 1);

    foreach my $thing (@_) {
        if( $self->_is_object($$thing) ) {
            if( my $string_meth = overload::Method( $$thing, $type ) ) {
                $$thing = $$thing->$string_meth();
            }
        }
    }

    return;
}

sub _unoverload_str {
    my $self = shift;

    return $self->_unoverload( q[""], @_ );
}

sub _unoverload_num {
    my $self = shift;

    $self->_unoverload( '0+', @_ );

    for my $val (@_) {
        next unless $self->_is_dualvar($$val);
        $$val = $$val + 0;
    }

    return;
}

# This is a hack to detect a dualvar such as $!
sub _is_dualvar {
    my( $self, $val ) = @_;

    # Objects are not dualvars.
    return 0 if ref $val;

    no warnings 'numeric';
    my $numval = $val + 0;
    return ($numval != 0 and $numval ne $val ? 1 : 0);
}

sub _diag_fmt {
    my( $self, $type, $val ) = @_;

    if( defined $$val ) {
        if( $type eq 'eq' or $type eq 'ne' ) {
            # quote and force string context
            $$val = "'$$val'";
        }
        else {
            # force numeric context
            $self->_unoverload_num($val);
        }
    }
    else {
        $$val = 'undef';
    }

    return;
}

sub _is_diag {
    my( $self, $got, $type, $expect ) = @_;
    local $Level = $Level + 1; local $BLevel = $BLevel + 1;

    $self->_diag_fmt( $type, $_ ) for \$got, \$expect;

    return <<"DIAGNOSTIC";
         got: $got
    expected: $expect
DIAGNOSTIC
}

sub _isnt_diag {
    my( $self, $got, $type ) = @_;
    local $Level = $Level + 1; local $BLevel = $BLevel + 1;

    $self->_diag_fmt( $type, \$got );

    return <<"DIAGNOSTIC";
         got: $got
    expected: anything else
DIAGNOSTIC
}


sub _cmp_diag {
    my( $self, $got, $type, $expect ) = @_;

    $got    = defined $got    ? "'$got'"    : 'undef';
    $expect = defined $expect ? "'$expect'" : 'undef';

    local $Level = $Level + 1; local $BLevel = $BLevel + 1;
    return <<"DIAGNOSTIC";
    $got
        $type
    $expect
DIAGNOSTIC
}

sub _caller_context {
    my $self = shift;

    my($pack, $file, $line) = $self->trace_test->report->call;

    my $code = '';
    $code .= "#line $line $file\n" if defined $file and defined $line;

    return $code;
}

sub _regex_ok {
    my( $self, $thing, $regex, $cmp, $name ) = @_;

    my $ok           = 0;
    my $usable_regex = _is_qr($regex) ? $regex : $self->maybe_regex($regex);
    unless( defined $usable_regex ) {
        local $Level = $Level + 1; local $BLevel = $BLevel + 1;
        $ok = $self->ok( 0, $name, "    '$regex' doesn't look much like a regex to me.");
        return $ok;
    }

    my $test;
    my $context = $self->_caller_context;

    try {
        # No point in issuing an uninit warning, they'll see it in the diagnostics
        no warnings 'uninitialized';
        ## no critic (BuiltinFunctions::ProhibitStringyEval)
        $test = eval $context . q{$test = $thing =~ /$usable_regex/ ? 1 : 0};
    };

    $test = !$test if $cmp eq '!~';

    my @diag;
    unless($test) {
        $thing = defined $thing ? "'$thing'" : 'undef';
        my $match = $cmp eq '=~' ? "doesn't match" : "matches";

        push @diag => sprintf( <<'DIAGNOSTIC', $thing, $match, $regex );
                  %s
    %13s '%s'
DIAGNOSTIC
    }

    local $Level = $Level + 1; local $BLevel = $BLevel + 1;
    $self->ok( $test, $name, @diag );

    return $test;
}

# I'm not ready to publish this.  It doesn't deal with array return
# values from the code or context.
sub _try {
    my( $self, $code, %opts ) = @_;

    my $result;
    my ($ok, $error) = try { $result = $code->() };

    die $error if $opts{die_on_fail} && !$ok;

    return wantarray ? ( $result, $error ) : $result;
}

sub _message_at_caller {
    my $self = shift;

    local $Level = $Level + 1; local $BLevel = $BLevel + 1;
    my $trace = $self->trace_test;
    my( $pack, $file, $line ) = $trace->report->call;
    return join( "", @_ ) . " at $file line $line.\n";
}

#'#
sub _sanity_check {
    my $self = shift;

    $self->_whoa( $self->stream->tests_run < 0, 'Says here you ran a negative number of tests!' );

    $self->lresults->sanity_check($self) if $self->lresults;

    return;
}

sub _whoa {
    my( $self, $check, $desc ) = @_;
    if($check) {
        local $Level = $Level + 1; local $BLevel = $BLevel + 1;
        $self->croak(<<"WHOA");
WHOA!  $desc
This should never happen!  Please contact the author immediately!
WHOA
    }

    return;
}

sub _ending {
    my $self = shift;
    require Test::Builder::ExitMagic;
    my $ending = Test::Builder::ExitMagic->new(tb => $self, stream => $self->stream);
    $ending->do_magic;
}

sub _is_qr {
    my $regex = shift;

    # is_regexp() checks for regexes in a robust manner, say if they're
    # blessed.
    return re::is_regexp($regex) if defined &re::is_regexp;
    return ref $regex eq 'Regexp';
}

#######################
# }}} Private helpers #
#######################

################################################
# {{{ Everything below this line is deprecated #
# But it must be maintained for legacy...      #
################################################

BEGIN {
    my %generate = (
        lresults => [qw/summary details/],
        stream   => [qw/no_ending/],
        tap => [qw/
            no_header no_diag output failure_output todo_output reset_outputs
            use_numbers _new_fh
        /],
    );

    for my $delegate (keys %generate) {
        for my $method (@{$generate{$delegate}}) {
            #print STDERR "Adding: $method ($delegate)\n";
            my $code = sub {
                my $self = shift;

                $self->carp("Use of \$TB->$method() is deprecated.") if $self->modern;
                my $d = $self->$delegate || $self->croak("$method() method only applies when $delegate is in use");

                $d->$method(@_);
            };

            no strict 'refs';    ## no critic
            *{$method} = $code;
        }
    }
}

sub exported_to {
    my($self, $pack) = @_;
    $self->carp("exported_to() is deprecated") if $self->modern;
    $self->{Exported_To} = $pack if defined $pack;
    return $self->{Exported_To};
}

sub _indent {
    my $self = shift;
    $self->carp("_indent() is deprecated") if $self->modern;
    return '' unless $self->depth;
    return '    ' x $self->depth
}

sub _output_plan {
    my ($self) = @_;
    $self->carp("_output_plan() is deprecated") if $self->modern;
    goto &_issue_plan;
}

sub _diag_fh {
    my $self = shift;

    $self->carp("Use of \$TB->_diag_fh() is deprecated.") if $self->modern;
    my $tap = $self->tap || $self->croak("_diag_fh() method only applies when TAP is in use");

    local $Level = $Level + 1; local $BLevel = $BLevel + 1;
    return $tap->_diag_fh($self->in_todo)
}

sub _print {
    my $self = shift;

    $self->carp("Use of \$TB->_print() is deprecated.") if $self->modern;
    my $tap = $self->tap || $self->croak("_print() method only applies when TAP is in use");

    return $tap->_print($self->_indent, @_);
}

sub _print_to_fh {
    my( $self, $fh, @msgs ) = @_;

    $self->carp("Use of \$TB->_print_to_fh() is deprecated.") if $self->modern;
    my $tap = $self->tap || $self->croak("_print_to_fh() method only applies when TAP is in use");

    return $tap->_print_to_fh($fh, $self->_indent, @msgs);
}

sub is_fh {
    my $self = shift;

    $self->carp("Use of \$TB->is_fh() is deprecated.")
        if Scalar::Util::blessed($self) && $self->modern;

    require Test::Builder::Formatter::TAP;
    return Test::Builder::Formatter::TAP->is_fh(@_);
}

sub current_test {
    my $self = shift;

    my $tap      = $self->tap;
    my $lresults = $self->lresults;

    if (@_) {
        my ($num) = @_;

        $lresults->current_test($num) if $lresults;
        $tap->current_test($num)      if $tap;

        $self->stream->tests_run(0 - $self->stream->tests_run + $num);
    }

    return $self->stream->tests_run;
}

sub BAILOUT {
    my ($self) = @_;
    $self->carp("Use of \$TB->BAILOUT() is deprecated.") if $self->modern;
    goto &BAIL_OUT;
}

sub expected_tests {
    my $self = shift;

    if(@_) {
        my ($max) = @_;
        $self->carp("Use of \$TB->expected_tests(\$max) is deprecated.") if $self->modern;
        $self->_issue_plan($max);
    }

    return $self->stream->expected_tests || 0;
}

sub caller {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my $self = shift;

    Carp::confess("Use of Test::Builder->caller() is deprecated.\n") if $self->modern;

    local $Level = $Level + 1; local $BLevel = $BLevel + 1;
    my $trace = $self->trace_test;
    return unless $trace && $trace->report;
    my @call = $trace->report->call;

    return wantarray ? @call : $call[0];
}

sub level {
    my( $self, $level ) = @_;
    $Level = $level if defined $level;
    return $Level;
}

sub maybe_regex {
    my ($self, $regex) = @_;
    my $usable_regex = undef;

    $self->carp("Use of \$TB->maybe_regex() is deprecated.") if $self->modern;

    return $usable_regex unless defined $regex;

    my( $re, $opts );

    # Check for qr/foo/
    if( _is_qr($regex) ) {
        $usable_regex = $regex;
    }
    # Check for '/foo/' or 'm,foo,'
    elsif(( $re, $opts )        = $regex =~ m{^ /(.*)/ (\w*) $ }sx              or
          ( undef, $re, $opts ) = $regex =~ m,^ m([^\w\s]) (.+) \1 (\w*) $,sx
    )
    {
        $usable_regex = length $opts ? "(?$opts)$re" : $re;
    }

    return $usable_regex;
}


###################################
# }}} End of deprecations section #
###################################

####################
# {{{ TB1.5 stuff  #
####################

# This is just a list of method Test::Builder current does not have that Test::Builder 1.5 does.
my %TB15_METHODS = map {$_ => 1} qw{
    _file_and_line _join_message _make_default _my_exit _reset_todo_state
    _result_to_hash _results _todo_state formatter history in_subtest in_test
    no_change_exit_code post_event post_result set_formatter set_plan test_end
    test_exit_code test_start test_state
};

our $AUTOLOAD;
sub AUTOLOAD {
    $AUTOLOAD =~ m/^(.*)::([^:]+)$/;
    my ($package, $sub) = ($1, $2);

    my @caller = CORE::caller();
    my $msg = qq{Can't locate object method "$sub" via package "$package" at $caller[1] line $caller[2]\n};

    $msg .= <<"    EOT" if $TB15_METHODS{$sub};

    *************************************************************************
    '$sub' is a Test::Builder 1.5 method. Test::Builder 1.5 is a dead branch.
    You need to update your code so that it no longer treats Test::Builders
    over a specific version number as anything special.

    See: http://blogs.perl.org/users/chad_exodist_granum/2014/03/testmore---new-maintainer-also-stop-version-checking.html
    *************************************************************************
    EOT

    die $msg;
}

####################
# }}} TB1.5 stuff  #
####################

1;

__END__

=head1 NAME

Test::Builder - Backend for building test libraries

=head1 NOTE ON DEPRECATIONS

With version 1.301001 many old methods and practices have been deprecated. What
we mean when we say "deprecated" is that the practices or methods are not to be
used in any new code. Old code that uses them will still continue to work,
possibly forever, but new code should use the newer and better alternatives.

In the future, if enough (read: pretty much everything) is updated and few if
any modules still use these old items, they will be removed completely. This is
not super likely to happen just because of the sheer number of modules that use
Test::Builder.

=head1 SYNOPSIS

In general you probably do not want to use this module directly, but instead
want to use L<Test::Builder::Provider> which will help you roll out a testing
library.

    package My::Test::Module;
    use Test::Builder::Provider;

    # Export a test tool from an anonymous sub
    provide ok => sub {
        my ($test, $name) = @_;
        builder()->ok($test, $name);
    };

    # Export tools that are package subs
    provides qw/is is_deeply/;
    sub is { ... }
    sub is_deeply { ... }

See L<Test::Builder::Provider> for more details.

B<Note:> You MUST use 'provide', or 'provides' to export testing tools, this
allows you to use the C<< builder()->trace_test >> tools to determine what
file/line a failed test came from.

=head2 LOW-LEVEL

    use Test::Builder;
    my $tb = Test::Builder->create(modern => 1, shared_stream => 1);
    $tb->ok(1);
    ....

=head2 DEPRECATED

    use Test::Builder;
    my $tb = Test::Builder->new;
    $tb->ok(1);
    ...

=head1 DESCRIPTION

L<Test::Simple> and L<Test::More> have proven to be popular testing modules,
but they're not always flexible enough.  Test::Builder provides a
building block upon which to write your own test libraries I<which can
work together>.

=head1 TEST COMPONENT MAP

  [Test Script] > [Test Tool] > [Test::Builder] > [Test::Bulder::Stream] > [Result Formatter]
                                      ^
                                 You are here

A test script uses a test tool such as L<Test::More>, which uses Test::Builder
to produce results. The results are sent to L<Test::Builder::Stream> which then
forwards them on to one or more formatters. The default formatter is
L<Test::Builder::Fromatter::TAP> which produces TAP output.

=head1 METHODS

=head2 CONSTRUCTION

=over 4

=item $Test = Test::Builder->create(%params)

Create a completely independant Test::Builder object.

    my $Test = Test::Builder->create;

Create a Test::Builder object that sends results to the shared output stream
(usually what you want).

    my $Test = Test::Builder->create(shared_stream => 1);

Create a Test::Builder object that does not include any legacy cruft.

    my $Test = Test::Builder->create(modern => 1);

=item $Test = Test::Builder->new B<***DEPRECATED***>

    my $Test = Test::Builder->new;

B<This usage is DEPRECATED!>

Returns the Test::Builder singleton object representing the current state of
the test.

Since you only run one test per program C<new> always returns the same
Test::Builder object.  No matter how many times you call C<new()>, you're
getting the same object.  This is called a singleton.  This is done so that
multiple modules share such global information as the test counter and
where test output is going. B<No longer necessary>

If you want a completely new Test::Builder object different from the
singleton, use C<create>.

=back

=head2 SIMPLE ACCESSORS AND SHORTCUTS

=head3 READ/WRITE ATTRIBUTES

=over 4

=item $parent = $Test->parent

Returns the parent C<Test::Builder> instance, if any.  Only used with child
builders for nested TAP.

=item $Test->name

Defaults to $0, but subtests and child tests will set this.

=item $Test->modern

Defaults to $ENV{TB_MODERN}, or 0. True when the builder object was constructed
with modern practices instead of deprecated ones.

=item $Test->depth

Get/Set the depth. This is usually set for Child tests.

=item $Test->default_name

Get/Set the default name for tests where no name was provided. Typically this
should be set to undef, there are very few real-world use cases for this.
B<Note:> This functionality was added specifically for L<Test::Exception>,
which has one of the few real-world use cases.

=back

=head3 DELEGATES TO STREAM

Each of these is a shortcut to C<< $Test->stream->NAME >>

See the L<Test::Builder::Stream> documentation for details.

=over 4

=item $Test->is_passing(...)

=item $Test->listen(...)

=item $Test->munge(...)

=item $Test->tap

=item $Test->lresults

=item $Test->use_fork

=item $Test->no_fork

=back

=head2 CHILDREN AND SUBTESTS

=over 4

=item $Test->subtest($name, \&subtests, @args)

See documentation of C<subtest> in Test::More.

C<subtest> also, and optionally, accepts arguments which will be passed to the
subtests reference.

=item $child = $Test->child($name)

  my $child = $builder->child($name_of_child);
  $child->plan( tests => 4 );
  $child->ok(some_code());
  ...
  $child->finalize;

Returns a new instance of C<Test::Builder>.  Any output from this child will
be indented four spaces more than the parent's indentation.  When done, the
C<finalize> method I<must> be called explicitly.

Trying to create a new child with a previous child still active (i.e.,
C<finalize> not called) will C<croak>.

Trying to run a test when you have an open child will also C<croak> and cause
the test suite to fail.

=item $ok = $Child->finalize

When your child is done running tests, you must call C<finalize> to clean up
and tell the parent your pass/fail status.

Calling C<finalize> on a child with open children will C<croak>.

If the child falls out of scope before C<finalize> is called, a failure
diagnostic will be issued and the child is considered to have failed.

No attempt to call methods on a child after C<finalize> is called is
guaranteed to succeed.

Calling this on the root builder is a no-op.

=back

=head2 STREAM MANAGEMENT

=over 4

=item $stream = $Test->stream

=item $Test->stream($stream)

=item $Test->stream(undef)

Get/Set the stream. When no stream is set, or is undef it will return the
shared stream.

B<Note:> Do not set this to the shared stream yourself, set it to undef. This
is because the shared stream is actually a stack, and this always returns the
top of the stack.

=item $results = $Test->intercept(\&code)

Any tests run inside the codeblock will be intercepted and not sent to the
normal stream. Instead they will be added to C<$results> which is an array of
L<Test::Builder::Result> objects.

B<Note:> This will also intercept BAIL_OUT and skipall.

B<Note:> This will only intercept results generated with the Test::Builder
object on which C<intercept()> was called. Other builders will still send to
the normal places.

See L<Test::Tester2> for a method of capturing results sent to the global
stream.

=back

=head2 TRACING THE TEST/PROVIDER BOUNDRY

When a test fails it will report the filename and line where the failure
occured. In order to do this it needs to look at the stack and figure out where
your tests stop, and the tools you are using begin. These methods help you find
the desired caller frame.

See the L<Test::Builder::Trace> module for more details.

=over 4

=item $trace = $Test->trace_test()

Returns an L<Test::Builder::Trace> object.

=item $reason = $Test->find_TODO

=item $reason = $Test->find_TODO($pack)

=item $old_reason = $Test->find_TODO($pack, 1, $new_reason);

Like C<todo()> but only returns the value of C<$TODO> ignoring
C<todo_start()>.

Can also be used to set C<$TODO> to a new value while returning the
old value.

=back

=head2 TEST PLAN

=over 4

=item $Test->plan('no_plan');

=item $Test->plan( skip_all => $reason );

=item $Test->plan( tests => $num_tests );

A convenient way to set up your tests.  Call this and Test::Builder
will print the appropriate headers and take the appropriate actions.

If you call C<plan()>, don't call any of the other methods below.

If a child calls "skip_all" in the plan, a C<Test::Builder::Exception> is
thrown.  Trap this error, call C<finalize()> and don't run any more tests on
the child.

    my $child = $Test->child('some child');
    eval { $child->plan( $condition ? ( skip_all => $reason ) : ( tests => 3 )  ) };
    if ( eval { $@->isa('Test::Builder::Exception') } ) {
       $child->finalize;
       return;
    }
    # run your tests

=item $Test->no_plan;

Declares that this test will run an indeterminate number of tests.

=item $Test->skip_all

=item $Test->skip_all($reason)

Skips all the tests, using the given C<$reason>.  Exits immediately with 0.

=item $Test->done_testing

=item $Test->done_testing($count)

Declares that you are done testing, no more tests will be run after this point.

If a plan has not yet been output, it will do so.

$num_tests is the number of tests you planned to run.  If a numbered
plan was already declared, and if this contradicts, a failing result
will be run to reflect the planning mistake.  If C<no_plan> was declared,
this will override.

If C<done_testing()> is called twice, the second call will issue a
failing result.

If C<$num_tests> is omitted, the number of tests run will be used, like
no_plan.

C<done_testing()> is, in effect, used when you'd want to use C<no_plan>, but
safer. You'd use it like so:

    $Test->ok($a == $b);
    $Test->done_testing();

Or to plan a variable number of tests:

    for my $test (@tests) {
        $Test->ok($test);
    }
    $Test->done_testing(scalar @tests);

=back

=head2 SIMPLE RESULT PRODUCERS

Each of these produces 1 or more L<Test::Builder::Result> objects which are fed
into the result stream.

=over 4

=item $Test->ok($test)

=item $Test->ok($test, $name)

=item $Test->ok($test, $name, @diag)

Your basic test.  Pass if C<$test> is true, fail if $test is false.  Just
like L<Test::Simple>'s C<ok()>.

You may also specify diagnostics messages in the form of simple strings, or
complete <Test::Builder::Result> objects. Typically you would only do this in a
failure, but you are allowed to add diags to passes as well.

=item $Test->BAIL_OUT($reason);

Indicates to the L<Test::Harness> that things are going so badly all
testing should terminate.  This includes running any additional test
scripts.

It will exit with 255.

=item $Test->skip

=item $Test->skip($why)

Skips the current test, reporting C<$why>.

=item $Test->todo_skip

=item $Test->todo_skip($why)

Like C<skip()>, only it will declare the test as failing and TODO.  Similar
to

    print "not ok $tnum # TODO $why\n";

=item $Test->diag(@msgs)

Prints out the given C<@msgs>.  Like C<print>, arguments are simply
appended together.

Normally, it uses the C<failure_output()> handle, but if this is for a
TODO test, the C<todo_output()> handle is used.

Output will be indented and marked with a # so as not to interfere
with test output.  A newline will be put on the end if there isn't one
already.

We encourage using this rather than calling print directly.

Returns false.  Why?  Because C<diag()> is often used in conjunction with
a failing test (C<ok() || diag()>) it "passes through" the failure.

    return ok(...) || diag(...);

=item $Test->note(@msgs)

Like C<diag()>, but it prints to the C<output()> handle so it will not
normally be seen by the user except in verbose mode.

=back

=head2 ADVANCED RESULT PRODUCERS

=over 4

=item $Test->is_eq($got, $expected, $name)

Like Test::More's C<is()>.  Checks if C<$got eq $expected>.  This is the
string version.

C<undef> only ever matches another C<undef>.

=item $Test->is_num($got, $expected, $name)

Like Test::More's C<is()>.  Checks if C<$got == $expected>.  This is the
numeric version.

C<undef> only ever matches another C<undef>.

=item $Test->isnt_eq($got, $dont_expect, $name)

Like L<Test::More>'s C<isnt()>.  Checks if C<$got ne $dont_expect>.  This is
the string version.

=item $Test->isnt_num($got, $dont_expect, $name)

Like L<Test::More>'s C<isnt()>.  Checks if C<$got ne $dont_expect>.  This is
the numeric version.

=item $Test->like($thing, qr/$regex/, $name)

=item $Test->like($thing, '/$regex/', $name)

Like L<Test::More>'s C<like()>.  Checks if $thing matches the given C<$regex>.

=item $Test->unlike($thing, qr/$regex/, $name)

=item $Test->unlike($thing, '/$regex/', $name)

Like L<Test::More>'s C<unlike()>.  Checks if $thing $Test->does not match the
given C<$regex>.

=item $Test->cmp_ok($thing, $type, $that, $name)

Works just like L<Test::More>'s C<cmp_ok()>.

    $Test->cmp_ok($big_num, '!=', $other_big_num);

=back

=head2 PUBLIC HELPERS

=over 4

=item @dump = $Test->explain(@msgs)

Will dump the contents of any references in a human readable format.
Handy for things like...

    is_deeply($have, $want) || diag explain $have;

or

    is_deeply($have, $want) || note explain $have;

=item $tb->carp(@message)

Warns with C<@message> but the message will appear to come from the
point where the original test function was called (C<< $tb->caller >>).

=item $tb->croak(@message)

Dies with C<@message> but the message will appear to come from the
point where the original test function was called (C<< $tb->caller >>).

=item $plan = $Test->has_plan

Find out whether a plan has been defined. C<$plan> is either C<undef> (no plan
has been set), C<no_plan> (indeterminate # of tests) or an integer (the number
of expected tests).

=item $Test->reset

Reinitializes the Test::Builder singleton to its original state.
Mostly useful for tests run in persistent environments where the same
test might be run multiple times in the same process.

=item %context = $Test->context

Returns a hash of contextual info.

    (
        depth  => DEPTH,
        source => NAME,
        trace  => TRACE,
    )

=back

=head2 TODO MANAGEMENT

=over 4

=item $todo_reason = $Test->todo

=item $todo_reason = $Test->todo($pack)

If the current tests are considered "TODO" it will return the reason,
if any.  This reason can come from a C<$TODO> variable or the last call
to C<todo_start()>.

Since a TODO test does not need a reason, this function can return an
empty string even when inside a TODO block.  Use C<< $Test->in_todo >>
to determine if you are currently inside a TODO block.

C<todo()> is about finding the right package to look for C<$TODO> in.  It's
pretty good at guessing the right package to look at. It considers the stack
trace, C<$Level>, and metadata associated with various packages.

Sometimes there is some confusion about where C<todo()> should be looking
for the C<$TODO> variable.  If you want to be sure, tell it explicitly
what $pack to use.

=item $in_todo = $Test->in_todo

Returns true if the test is currently inside a TODO block.

=item $Test->todo_start()

=item $Test->todo_start($message)

This method allows you declare all subsequent tests as TODO tests, up until
the C<todo_end> method has been called.

The C<TODO:> and C<$TODO> syntax is generally pretty good about figuring out
whether or not we're in a TODO test.  However, often we find that this is not
possible to determine (such as when we want to use C<$TODO> but
the tests are being executed in other packages which can't be inferred
beforehand).

Note that you can use this to nest "todo" tests

 $Test->todo_start('working on this');
 # lots of code
 $Test->todo_start('working on that');
 # more code
 $Test->todo_end;
 $Test->todo_end;

This is generally not recommended, but large testing systems often have weird
internal needs.

We've tried to make this also work with the TODO: syntax, but it's not
guaranteed and its use is also discouraged:

 TODO: {
     local $TODO = 'We have work to do!';
     $Test->todo_start('working on this');
     # lots of code
     $Test->todo_start('working on that');
     # more code
     $Test->todo_end;
     $Test->todo_end;
 }

Pick one style or another of "TODO" to be on the safe side.

=item $Test->todo_end

Stops running tests as "TODO" tests.  This method is fatal if called without a
preceding C<todo_start> method call.

=back

=head2 DEPRECATED/LEGACY

All of these will issue warnings if called on a modern Test::Builder object.
That is any Test::Builder instance that was created with the 'modern' flag.

=over

=item $self->no_ending

B<Deprecated:> Moved to the L<Test::Builder::Stream> object.

    $Test->no_ending($no_ending);

Normally, Test::Builder does some extra diagnostics when the test
ends.  It also changes the exit code as described below.

If this is true, none of that will be done.

=item $self->summary

B<Deprecated:> Moved to the L<Test::Builder::Stream> object.

The style of result recording used here is deprecated. The functionality was
moved to its own object to contain the legacy code.

    my @tests = $Test->summary;

A simple summary of the tests so far.  True for pass, false for fail.
This is a logical pass/fail, so todos are passes.

Of course, test #1 is $tests[0], etc...

=item $self->details

B<Deprecated:> Moved to the L<Test::Builder::Formatter::LegacyResults> object.

The style of result recording used here is deprecated. The functionality was
moved to its own object to contain the legacy code.

    my @tests = $Test->details;

Like C<summary()>, but with a lot more detail.

    $tests[$test_num - 1] =
            { 'ok'       => is the test considered a pass?
              actual_ok  => did it literally say 'ok'?
              name       => name of the test (if any)
              type       => type of test (if any, see below).
              reason     => reason for the above (if any)
            };

'ok' is true if Test::Harness will consider the test to be a pass.

'actual_ok' is a reflection of whether or not the test literally
printed 'ok' or 'not ok'.  This is for examining the result of 'todo'
tests.

'name' is the name of the test.

'type' indicates if it was a special test.  Normal tests have a type
of ''.  Type can be one of the following:

    skip        see skip()
    todo        see todo()
    todo_skip   see todo_skip()
    unknown     see below

Sometimes the Test::Builder test counter is incremented without it
printing any test output, for example, when C<current_test()> is changed.
In these cases, Test::Builder doesn't know the result of the test, so
its type is 'unknown'.  These details for these tests are filled in.
They are considered ok, but the name and actual_ok is left C<undef>.

For example "not ok 23 - hole count # TODO insufficient donuts" would
result in this structure:

    $tests[22] =    # 23 - 1, since arrays start from 0.
      { ok        => 1,   # logically, the test passed since its todo
        actual_ok => 0,   # in absolute terms, it failed
        name      => 'hole count',
        type      => 'todo',
        reason    => 'insufficient donuts'
      };

=item $self->no_header

B<Deprecated:> moved to the L<Test::Builder::Formatter::TAP> object.

    $Test->no_header($no_header);

If set to true, no "1..N" header will be printed.

=item $self->no_diag

B<Deprecated:> moved to the L<Test::Builder::Formatter::TAP> object.

If set true no diagnostics will be printed.  This includes calls to
C<diag()>.

=item $self->output

=item $self->failure_output

=item $self->todo_output

B<Deprecated:> moved to the L<Test::Builder::Formatter::TAP> object.

    my $filehandle = $Test->output;
    $Test->output($filehandle);
    $Test->output($filename);
    $Test->output(\$scalar);

These methods control where Test::Builder will print its output.
They take either an open C<$filehandle>, a C<$filename> to open and write to
or a C<$scalar> reference to append to.  It will always return a C<$filehandle>.

B<output> is where normal "ok/not ok" test output goes.

Defaults to STDOUT.

B<failure_output> is where diagnostic output on test failures and
C<diag()> goes.  It is normally not read by Test::Harness and instead is
displayed to the user.

Defaults to STDERR.

C<todo_output> is used instead of C<failure_output()> for the
diagnostics of a failing TODO test.  These will not be seen by the
user.

Defaults to STDOUT.

=item $self->reset_outputs

B<Deprecated:> moved to the L<Test::Builder::Formatter::TAP> object.

    $tb->reset_outputs;

Resets all the output filehandles back to their defaults.

=item $self->use_numbers

B<Deprecated:> moved to the L<Test::Builder::Formatter::TAP> object.

    $Test->use_numbers($on_or_off);

Whether or not the test should output numbers.  That is, this if true:

  ok 1
  ok 2
  ok 3

or this if false

  ok
  ok
  ok

Most useful when you can't depend on the test output order, such as
when threads or forking is involved.

Defaults to on.

=item $pack = $Test->exported_to

=item $Test->exported_to($pack)

B<Deprecated:> Use C<< Test::Builder::Trace->anoint($package) >> and
C<< $Test->trace_anointed >> instead.

Tells Test::Builder what package you exported your functions to.

This method isn't terribly useful since modules which share the same
Test::Builder object might get exported to different packages and only
the last one will be honored.

=item $is_fh = $Test->is_fh($thing);

Determines if the given C<$thing> can be used as a filehandle.

=item $curr_test = $Test->current_test;

=item $Test->current_test($num);

Gets/sets the current test number we're on.  You usually shouldn't
have to set this.

If set forward, the details of the missing tests are filled in as 'unknown'.
if set backward, the details of the intervening tests are deleted.  You
can erase history if you really want to.

=item $Test->BAIL_OUT($reason);

Indicates to the L<Test::Harness> that things are going so badly all
testing should terminate.  This includes running any additional test
scripts.

It will exit with 255.

=item $max = $Test->expected_tests

=item $Test->expected_tests($max)

Gets/sets the number of tests we expect this test to run and prints out
the appropriate headers.

=item $package = $Test->caller

=item ($pack, $file, $line) = $Test->caller

=item ($pack, $file, $line) = $Test->caller($height)

Like the normal C<caller()>, except it reports according to your C<level()>.

C<$height> will be added to the C<level()>.

If C<caller()> winds up off the top of the stack it report the highest context.

=item $Test->level($how_high)

B<DEPRECATED> See deprecation notes at the top. The use of C<level()> is
deprecated.

How far up the call stack should C<$Test> look when reporting where the
test failed.

Defaults to 1.

Setting L<$Test::Builder::Level> overrides.  This is typically useful
localized:

    sub my_ok {
        my $test = shift;

        local $Test::Builder::Level = $Test::Builder::Level + 1;
        $TB->ok($test);
    }

To be polite to other functions wrapping your own you usually want to increment
C<$Level> rather than set it to a constant.

=item $Test->maybe_regex(qr/$regex/)

=item $Test->maybe_regex('/$regex/')

This method used to be useful back when Test::Builder worked on Perls
before 5.6 which didn't have qr//.  Now its pretty useless.

Convenience method for building testing functions that take regular
expressions as arguments.

Takes a quoted regular expression produced by C<qr//>, or a string
representing a regular expression.

Returns a Perl value which may be used instead of the corresponding
regular expression, or C<undef> if its argument is not recognised.

For example, a version of C<like()>, sans the useful diagnostic messages,
could be written as:

  sub laconic_like {
      my ($self, $thing, $regex, $name) = @_;
      my $usable_regex = $self->maybe_regex($regex);
      die "expecting regex, found '$regex'\n"
          unless $usable_regex;
      $self->ok($thing =~ m/$usable_regex/, $name);
  }

=back

=head1 PACKAGE VARIABLES

B<NOTE>: These are tied to the package, not the instance. Basically that means
touching these can affect more things than you expect. Using these can lead to
unexpected interactions at a distance.

=over 4

=item C<$Level>

Originally this was the only way to tell Test::Builder where in the stack
errors should be reported. Now the preferred method of finding where errors
should be reported is using the L<Test::Builder::Trace> and
L<Test::Builder::Provider> modules.

C<$Level> should be considered deprecated when possible, that said it will not
be removed any time soon. There is too much legacy code that depends on
C<$Level>. There are also a couple situations in which C<$Level> is necessary:

=over 4

=item Backwards compatibility

If code simply cannot depend on a recent version of Test::Builder, then $Level
must be used as there is no alternative. See L<Test::Builder::Compat> for tools
to help make test tools that work in old and new versions.

=item Stack Management

Using L<Test::Builder::Provider> is not practical for situations like in
L<Test::Exception> where one needs to munge the call stack to hide frames.

=back

=item C<$BLevel>

Used internally by the L<Test::Builder::Trace>, do not modify or rely on this
in your own code. Documented for completeness.

=item C<$Test>

The singleton returned by C<new()>, which is deprecated in favor of
C<create()>.

=back

=head1 EXIT CODES

If all your tests passed, Test::Builder will exit with zero (which is
normal).  If anything failed it will exit with how many failed.  If
you run less (or more) tests than you planned, the missing (or extras)
will be considered failures.  If no tests were ever run Test::Builder
will throw a warning and exit with 255.  If the test died, even after
having successfully completed all its tests, it will still be
considered a failure and will exit with 255.

So the exit codes are...

    0                   all tests successful
    255                 test died or all passed but wrong # of tests run
    any other number    how many failed (including missing or extras)

If you fail more than 254 tests, it will be reported as 254.

B<Note:> The magic that accomplishes this has been moved to
L<Test::Builder::ExitMagic>

=head1 THREADS

In perl 5.8.1 and later, Test::Builder is thread-safe.  The test
number is shared amongst all threads.

While versions earlier than 5.8.1 had threads they contain too many
bugs to support.

Test::Builder is only thread-aware if threads.pm is loaded I<before>
Test::Builder.

=head1 MEMORY

B<Note:> This only applies if you turn lresults on.

    $Test->stream->no_lresults;

An informative hash, accessible via C<details()>, is stored for each
test you perform.  So memory usage will scale linearly with each test
run. Although this is not a problem for most test suites, it can
become an issue if you do large (hundred thousands to million)
combinatorics tests in the same run.

In such cases, you are advised to either split the test file into smaller
ones, or use a reverse approach, doing "normal" (code) compares and
triggering C<fail()> should anything go unexpected.

=head1 EXAMPLES

CPAN can provide the best examples.  L<Test::Simple>, L<Test::More>,
L<Test::Exception> and L<Test::Differences> all use Test::Builder.

=head1 SEE ALSO

L<Test::Simple>, L<Test::More>, L<Test::Harness>, L<Fennec>

=head1 AUTHORS

Original code by chromatic, maintained by Michael G Schwern
E<lt>schwern@pobox.comE<gt> until 2014. Currently maintained by Chad Granum
E<lt>exodist7@gmail.comE<gt>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2002-2014 by chromatic E<lt>chromatic@wgz.orgE<gt> and
                       Michael G Schwern E<lt>schwern@pobox.comE<gt> and
                       Chad Granum E<lt>exodist7@gmail.comE<gt>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

