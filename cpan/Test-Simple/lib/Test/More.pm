package Test::More;

use 5.008001;
use strict;
use warnings;

our $VERSION = '1.301001_097';
$VERSION = eval $VERSION;    ## no critic (BuiltinFunctions::ProhibitStringyEval)

use Test::Stream 1.301001 '-internal';
use Test::Stream::Util qw/protect try spoof/;
use Test::Stream::Toolset qw/is_tester init_tester context before_import/;
use Test::Stream::Subtest qw/subtest/;

use Test::Stream::Carp qw/croak carp/;
use Scalar::Util qw/blessed/;

use Test::More::Tools;
use Test::More::DeepCheck::Strict;

use Test::Builder;

use Test::Stream::Exporter qw/
    default_export default_exports export_to export_to_level
/;

our $TODO;
default_export '$TODO' => \$TODO;
default_exports qw{
    plan done_testing

    ok
    is isnt
    like unlike
    cmp_ok
    is_deeply
    eq_array eq_hash eq_set
    can_ok isa_ok new_ok
    pass fail
    require_ok use_ok
    subtest

    explain

    diag note

    skip todo_skip
    BAIL_OUT
};
Test::Stream::Exporter->cleanup;

{
    no warnings 'once';
    $Test::Builder::Level ||= 1;
}

sub import {
    my $class = shift;
    my $caller = caller;
    my @args = @_;

    my $stash = $class->before_import($caller, \@args) if $class->can('before_import');
    export_to($class, $caller, @args);
    $class->after_import($caller, $stash, @args) if $class->can('after_import');
    $class->import_extra(@args);
}

sub import_extra { 1 };

sub builder { Test::Builder->new }

sub ok ($;$) {
    my ($test, $name) = @_;
    my $ctx  = context();
    if($test) {
        $ctx->ok(1, $name);
        return 1;
    }
    else {
        $ctx->ok(0, $name);
        return 0;
    }
}

sub plan {
    return unless @_;
    my ($directive, $arg) = @_;
    my $ctx = context();

    if ($directive eq 'tests') {
        $ctx->plan($arg);
    }
    else {
        $ctx->plan(0, $directive, $arg);
    }
}

sub done_testing {
    my ($num) = @_;
    my $ctx = context();
    $ctx->done_testing($num);
}

sub is($$;$) {
    my ($got, $want, $name) = @_;
    my $ctx = context();
    my ($ok, @diag) = tmt->is_eq($got, $want);
    $ctx->ok($ok, $name, \@diag);
    return $ok;
}

sub isnt ($$;$) {
    my ($got, $forbid, $name) = @_;
    my $ctx = context();
    my ($ok, @diag) = tmt->isnt_eq($got, $forbid);
    $ctx->ok($ok, $name, \@diag);
    return $ok;
}

{
    no warnings 'once';
    *isn't = \&isnt;
    # ' to unconfuse syntax higlighters
}

sub like ($$;$) {
    my ($got, $check, $name) = @_;
    my $ctx = context();
    my ($ok, @diag) = tmt->regex_check($got, $check, '=~');
    $ctx->ok($ok, $name, \@diag);
    return $ok;
}

sub unlike ($$;$) {
    my ($got, $forbid, $name) = @_;
    my $ctx = context();
    my ($ok, @diag) = tmt->regex_check($got, $forbid, '!~');
    $ctx->ok($ok, $name, \@diag);
    return $ok;
}

sub cmp_ok($$$;$) {
    my ($got, $type, $expect, $name) = @_;
    my $ctx = context();
    my ($ok, @diag) = tmt->cmp_check($got, $type, $expect);
    $ctx->ok($ok, $name, \@diag);
    return $ok;
}

sub can_ok($@) {
    my ($thing, @methods) = @_;
    my $ctx = context();

    my $class = ref $thing || $thing || '';
    my ($ok, @diag);

    if (!@methods) {
        ($ok, @diag) = (0, "    can_ok() called with no methods");
    }
    elsif (!$class) {
        ($ok, @diag) = (0, "    can_ok() called with empty class or reference");
    }
    else {
        ($ok, @diag) = tmt->can_check($thing, $class, @methods);
    }

    my $name = (@methods == 1 && defined $methods[0])
        ? "$class\->can('$methods[0]')"
        : "$class\->can(...)";

    $ctx->ok($ok, $name, \@diag);
    return $ok;
}

sub isa_ok ($$;$) {
    my ($thing, $class, $thing_name) = @_;
    my $ctx = context();
    $thing_name = "'$thing_name'" if $thing_name;
    my ($ok, @diag) = tmt->isa_check($thing, $class, \$thing_name);
    my $name = "$thing_name isa '$class'";
    $ctx->ok($ok, $name, \@diag);
    return $ok;
}

sub new_ok {
    croak "new_ok() must be given at least a class" unless @_;
    my ($class, $args, $object_name) = @_;
    my $ctx = context();
    my ($obj, $name, $ok, @diag) = tmt->new_check($class, $args, $object_name);
    $ctx->ok($ok, $name, \@diag);
    return $obj;
}

sub pass (;$) {
    my $ctx = context();
    return $ctx->ok(1, @_);
}

sub fail (;$) {
    my $ctx = context();
    return $ctx->ok(0, @_);
}

sub explain {
    my $ctx = context();
    tmt->explain(@_);
}

sub diag {
    my $ctx = context();
    $ctx->diag($_) for @_;
}

sub note {
    my $ctx = context();
    $ctx->note($_) for @_;
}

sub skip {
    my( $why, $how_many ) = @_;
    my $ctx = context();

    _skip($why, $how_many, 'skip', 1);

    no warnings 'exiting';
    last SKIP;
}

sub _skip {
    my( $why, $how_many, $func, $bool ) = @_;
    my $ctx = context();

    my $plan = $ctx->stream->plan;

    # If there is no plan we do not need to worry about counts
    my $need_count = $plan ? !($plan->directive && $plan->directive eq 'NO PLAN') : 0;

    if ($need_count && !defined $how_many) {
        $ctx->alert("$func() needs to know \$how_many tests are in the block");
    }

    $ctx->alert("$func() was passed a non-numeric number of tests.  Did you get the arguments backwards?")
        if defined $how_many and $how_many =~ /\D/;

    $how_many = 1 unless defined $how_many;
    $ctx->set_skip($why);
    for( 1 .. $how_many ) {
        $ctx->ok($bool, '');
    }
}

sub todo_skip {
    my($why, $how_many) = @_;

    my $ctx = context();
    $ctx->set_in_todo(1);
    $ctx->set_todo($why);
    _skip($why, $how_many, 'todo_skip', 0);

    no warnings 'exiting';
    last TODO;
}

sub BAIL_OUT {
    my ($reason) = @_;
    my $ctx = context();
    $ctx->bail($reason);
}

sub is_deeply {
    my ($got, $want, $name) = @_;

    my $ctx = context();

    unless( @_ == 2 or @_ == 3 ) {
        my $msg = <<'WARNING';
is_deeply() takes two or three args, you gave %d.
This usually means you passed an array or hash instead
of a reference to it
WARNING
        chop $msg;    # clip off newline so carp() will put in line/file

        $ctx->alert(sprintf $msg, scalar @_);

        $ctx->ok(0, undef, ['incorrect number of args']);
        return 0;
    }

    my ($ok, @diag) = Test::More::DeepCheck::Strict->check($got, $want);
    $ctx->ok($ok, $name, \@diag);
    return $ok;
}

sub eq_array {
    my ($got, $want, $name) = @_;
    my $ctx = context();
    my ($ok, @diag) = Test::More::DeepCheck::Strict->check_array($got, $want);
    return $ok;
}

sub eq_hash {
    my ($got, $want, $name) = @_;
    my $ctx = context();
    my ($ok, @diag) = Test::More::DeepCheck::Strict->check_hash($got, $want);
    return $ok;
}

sub eq_set {
    my ($got, $want, $name) = @_;
    my $ctx = context();
    my ($ok, @diag) = Test::More::DeepCheck::Strict->check_set($got, $want);
    return $ok;
}

sub require_ok($;$) {
    my($module) = shift;
    my $ctx = context();

    # Try to determine if we've been given a module name or file.
    # Module names must be barewords, files not.
    $module = qq['$module'] unless _is_module_name($module);

    my ($ret, $err);
    {
        local $SIG{__DIE__};
        ($ret, $err) = spoof [caller] => "require $module";
    }

    my @diag;
    unless ($ret) {
        chomp $err;
        push @diag => <<"        DIAG";
    Tried to require '$module'.
    Error:  $err
        DIAG
    }

    $ctx->ok( $ret, "require $module;", \@diag );
    return $ret ? 1 : 0;
}

sub _is_module_name {
    my $module = shift;

    # Module names start with a letter.
    # End with an alphanumeric.
    # The rest is an alphanumeric or ::
    $module =~ s/\b::\b//g;

    return $module =~ /^[a-zA-Z]\w*$/ ? 1 : 0;
}

sub use_ok($;@) {
    my ($module, @imports) = @_;
    @imports = () unless @imports;
    my $ctx = context();

    my($pack, $filename, $line) = caller;
    $filename =~ y/\n\r/_/; # so it doesn't run off the "#line $line $f" line

    my ($ret, $err, $newdie, @diag);
    {
        local $SIG{__DIE__};

        if( @imports == 1 and $imports[0] =~ /^\d+(?:\.\d+)?$/ ) {
            # probably a version check.  Perl needs to see the bare number
            # for it to work with non-Exporter based modules.
            ($ret, $err) = spoof [$pack, $filename, $line] => "use $module $imports[0]";
        }
        else {
            ($ret, $err) = spoof [$pack, $filename, $line] => "use $module \@args", @imports;
        }

        $newdie = $SIG{__DIE__};
    }

    $SIG{__DIE__} = $newdie if defined $newdie;

    unless ($ret) {
        chomp $err;
        push @diag => <<"        DIAG";
    Tried to use '$module'.
    Error:  $err
        DIAG
    }

    $ctx->ok($ret, "use $module;", \@diag);

    return $ret ? 1 : 0;
}

1;

__END__

=head1 NAME

Test::More - The defacto standard in unit testing tools.

=head1 SYNOPSIS

    # Using Test::Stream BEFORE using Test::More removes expensive legacy
    # support. This Also provides context(), cull(), and tap_encoding()
    use Test::Stream;

    # Load after Test::Stream to get the benefits of removed legacy
    use Test::More;

    use ok 'Some::Module';

    can_ok($module, @methods);
    isa_ok($object, $class);

    pass($test_name);
    fail($test_name);

    ok($got eq $expected, $test_name);

    is  ($got, $expected, $test_name);
    isnt($got, $expected, $test_name);

    like  ($got, qr/expected/, $test_name);
    unlike($got, qr/expected/, $test_name);

    cmp_ok($got, '==', $expected, $test_name);

    is_deeply(
        $got_complex_structure,
        $expected_complex_structure,
        $test_name
    );

    # Rather than print STDERR "# here's what went wrong\n"
    diag("here's what went wrong");

    SKIP: {
        skip $why, $how_many unless $have_some_feature;

        ok( foo(),       $test_name );
        is( foo(42), 23, $test_name );
    };

    TODO: {
        local $TODO = $why;

        ok( foo(),       $test_name );
        is( foo(42), 23, $test_name );
    };

    sub my_compare {
        my ($got, $want, $name) = @_;
        my $ctx = context(); # From Test::Stream
        my $ok = $got eq $want;
        $ctx->ok($ok, $name);
        ...
        return $ok;
    };

    # If this fails it will report this line instead of the line in my_compare.
    my_compare('a', 'b');

    done_testing;

=head1 DESCRIPTION

B<STOP!> If you're just getting started writing tests, have a look at
L<Test::Simple> first.  This is a drop in replacement for Test::Simple
which you can switch to once you get the hang of basic testing.

The purpose of this module is to provide a wide range of testing
utilities.  Various ways to say "ok" with better diagnostics,
facilities to skip tests, test future features and compare complicated
data structures.  While you can do almost anything with a simple
C<ok()> function, it doesn't provide good diagnostic output.

=head2 I love it when a plan comes together

Before anything else, you need a testing plan.  This basically declares
how many tests your script is going to run to protect against premature
failure.

The preferred way to do this is to declare a plan when you C<use Test::More>.

  use Test::More tests => 23;

There are cases when you will not know beforehand how many tests your
script is going to run.  In this case, you can declare your tests at
the end.

  use Test::More;

  ... run your tests ...

  done_testing( $number_of_tests_run );

Sometimes you really don't know how many tests were run, or it's too
difficult to calculate.  In which case you can leave off
$number_of_tests_run.

In some cases, you'll want to completely skip an entire testing script.

  use Test::More skip_all => $skip_reason;

Your script will declare a skip with the reason why you skipped and
exit immediately with a zero (success).  See L<Test::Harness> for
details.

If you want to control what functions Test::More will export, you
have to use the 'import' option.  For example, to import everything
but 'fail', you'd do:

  use Test::More tests => 23, import => ['!fail'];

Alternatively, you can use the C<plan()> function.  Useful for when you
have to calculate the number of tests.

  use Test::More;
  plan tests => keys %Stuff * 3;

or for deciding between running the tests at all:

  use Test::More;
  if( $^O eq 'MacOS' ) {
      plan skip_all => 'Test irrelevant on MacOS';
  }
  else {
      plan tests => 42;
  }

=over 4

=item B<done_testing>

    done_testing();
    done_testing($number_of_tests);

If you don't know how many tests you're going to run, you can issue
the plan when you're done running tests.

$number_of_tests is the same as C<plan()>, it's the number of tests you
expected to run.  You can omit this, in which case the number of tests
you ran doesn't matter, just the fact that your tests ran to
conclusion.

This is safer than and replaces the "no_plan" plan.

=back

=head2 Test::Stream

If Test::Stream is loaded before Test::More then it will prevent the insertion
of some legacy support shims, saving you memory and improving performance.

    use Test::Stream;
    use Test::More;

You can also use it to make forking work:

    use Test::Stream 'enable_fork';

=head2 TAP Encoding

You can now control the encoding of your TAP output using Test::Stream.

    use Test::Stream; # imports tap_encoding
    use Test::More;

    tap_encoding 'utf8';

You can also just set 'utf8' it at import time

    use Test::Stream 'utf8';

or something other than utf8

    use Test::Stream encoding => 'latin1';

=over 4

=item tap_encoding 'utf8';

=item tap_encoding 'YOUR_ENCODING';

=item tap_encoding 'xxx' => sub { ... };

The C<tap_encoding($encoding)> function will ensure that any B<FUTURE> TAP
output produced by I<This Package> will be output in the specified encoding.

You may also provide a codeblock in which case the scope of the encoding change
will only apply to that codeblock.

B<Note>: This is effective only for the current package. Other packages can/may
select other encodings for their TAP output. For packages where none is
specified, the original STDOUT and STDERR settings are used, the results are
unpredictable.

B<Note>: The encoding of the TAP, it is necessary to set to match the
locale of the encoding of the terminal.

However, in tests code that are performed in a variety of environments,
it can not be assumed in advance the encoding of the locale of the terminal,
it is recommended how to set the encoding to your environment using the
C<Encode::Locale> module.

The following is an example of code.

  use utf8;
  use Test::Stream;
  use Test::More;
  use Encode::Locale;

  tap_encoding('console_out');

B<Note>: Filenames are a touchy subject:

Different OS's and filesystems handle filenames differently. When you do not
specify an encoding, the filename will be unmodified, you get whatever perl
thinks it is. If you do specify an encoding, the filename will be assumed to be
in that encoding, and an attempt will be made to unscramble it. If the
unscrambling fails the original name will be used.

This filename unscrambling is necessary for example on linux systems when you
use utf8 encoding and a utf8 filename. Perl will read the bytes of the name,
and treat them as bytes. if you then try to print the name to a utf8 handle it
will treat each byte as a different character. Test::More attempts to fix this
scrambling for you.

=back

=head2 Helpers

Sometimes you want to write functions for things you do frequently that include
calling ok() or other test functions. Doing this can make it hard to debug
problems as failures will be reported in your sub, and not at the place where
you called your sub. Now there is a solution to this, the
L<Test::Stream::Context> object!.

L<Test::Stream> exports the C<context()> function which will return a context
object for your use. The idea is that you generate a context object at the
lowest level (the function you call from your test file). Deeper functions that
need context will get the object you already generated, at least until the
object falls out of scope or is undefined.

    sub my_compare {
        my ($got, $want, $name) = @_;
        my $ctx = context();

        # is() will find the context object above, instead of generating a new
        # one. That way a failure will be reported to the correct line
        is($got, $want);

        # This time it will generate a new context object. That means a failure
        # will report to this line.
        $ctx = undef;
        is($got, $want);
    };

=head2 Test names

By convention, each test is assigned a number in order.  This is
largely done automatically for you.  However, it's often very useful to
assign a name to each test.  Which would you rather see:

  ok 4
  not ok 5
  ok 6

or

  ok 4 - basic multi-variable
  not ok 5 - simple exponential
  ok 6 - force == mass * acceleration

The later gives you some idea of what failed.  It also makes it easier
to find the test in your script, simply search for "simple
exponential".

All test functions take a name argument.  It's optional, but highly
suggested that you use it.

=head2 I'm ok, you're not ok.

The basic purpose of this module is to print out either "ok #" or "not
ok #" depending on if a given test succeeded or failed.  Everything
else is just gravy.

All of the following print "ok" or "not ok" depending on if the test
succeeded or failed.  They all also return true or false,
respectively.

=over 4

=item B<ok>

  ok($got eq $expected, $test_name);

This simply evaluates any expression (C<$got eq $expected> is just a
simple example) and uses that to determine if the test succeeded or
failed.  A true expression passes, a false one fails.  Very simple.

For example:

    ok( $exp{9} == 81,                   'simple exponential' );
    ok( Film->can('db_Main'),            'set_db()' );
    ok( $p->tests == 4,                  'saw tests' );
    ok( !grep(!defined $_, @items),      'all items defined' );

(Mnemonic:  "This is ok.")

$test_name is a very short description of the test that will be printed
out.  It makes it very easy to find a test in your script when it fails
and gives others an idea of your intentions.  $test_name is optional,
but we B<very> strongly encourage its use.

Should an C<ok()> fail, it will produce some diagnostics:

    not ok 18 - sufficient mucus
    #   Failed test 'sufficient mucus'
    #   in foo.t at line 42.

This is the same as L<Test::Simple>'s C<ok()> routine.

=item B<is>

=item B<isnt>

  is  ( $got, $expected, $test_name );
  isnt( $got, $expected, $test_name );

Similar to C<ok()>, C<is()> and C<isnt()> compare their two arguments
with C<eq> and C<ne> respectively and use the result of that to
determine if the test succeeded or failed.  So these:

    # Is the ultimate answer 42?
    is( ultimate_answer(), 42,          "Meaning of Life" );

    # $foo isn't empty
    isnt( $foo, '',     "Got some foo" );

are similar to these:

    ok( ultimate_answer() eq 42,        "Meaning of Life" );
    ok( $foo ne '',     "Got some foo" );

C<undef> will only ever match C<undef>.  So you can test a value
against C<undef> like this:

    is($not_defined, undef, "undefined as expected");

(Mnemonic:  "This is that."  "This isn't that.")

So why use these?  They produce better diagnostics on failure.  C<ok()>
cannot know what you are testing for (beyond the name), but C<is()> and
C<isnt()> know what the test was and why it failed.  For example this
test:

    my $foo = 'waffle';  my $bar = 'yarblokos';
    is( $foo, $bar,   'Is foo the same as bar?' );

Will produce something like this:

    not ok 17 - Is foo the same as bar?
    #   Failed test 'Is foo the same as bar?'
    #   in foo.t at line 139.
    #          got: 'waffle'
    #     expected: 'yarblokos'

So you can figure out what went wrong without rerunning the test.

You are encouraged to use C<is()> and C<isnt()> over C<ok()> where possible,
however do not be tempted to use them to find out if something is
true or false!

  # XXX BAD!
  is( exists $brooklyn{tree}, 1, 'A tree grows in Brooklyn' );

This does not check if C<exists $brooklyn{tree}> is true, it checks if
it returns 1.  Very different.  Similar caveats exist for false and 0.
In these cases, use C<ok()>.

  ok( exists $brooklyn{tree},    'A tree grows in Brooklyn' );

A simple call to C<isnt()> usually does not provide a strong test but there
are cases when you cannot say much more about a value than that it is
different from some other value:

  new_ok $obj, "Foo";

  my $clone = $obj->clone;
  isa_ok $obj, "Foo", "Foo->clone";

  isnt $obj, $clone, "clone() produces a different object";

For those grammatical pedants out there, there's an C<isn't()>
function which is an alias of C<isnt()>.

=item B<like>

  like( $got, qr/expected/, $test_name );

Similar to C<ok()>, C<like()> matches $got against the regex C<qr/expected/>.

So this:

    like($got, qr/expected/, 'this is like that');

is similar to:

    ok( $got =~ m/expected/, 'this is like that');

(Mnemonic "This is like that".)

The second argument is a regular expression.  It may be given as a
regex reference (i.e. C<qr//>) or (for better compatibility with older
perls) as a string that looks like a regex (alternative delimiters are
currently not supported):

    like( $got, '/expected/', 'this is like that' );

Regex options may be placed on the end (C<'/expected/i'>).

Its advantages over C<ok()> are similar to that of C<is()> and C<isnt()>.  Better
diagnostics on failure.

=item B<unlike>

  unlike( $got, qr/expected/, $test_name );

Works exactly as C<like()>, only it checks if $got B<does not> match the
given pattern.

=item B<cmp_ok>

  cmp_ok( $got, $op, $expected, $test_name );

Halfway between C<ok()> and C<is()> lies C<cmp_ok()>.  This allows you
to compare two arguments using any binary perl operator.  The test
passes if the comparison is true and fails otherwise.

    # ok( $got eq $expected );
    cmp_ok( $got, 'eq', $expected, 'this eq that' );

    # ok( $got == $expected );
    cmp_ok( $got, '==', $expected, 'this == that' );

    # ok( $got && $expected );
    cmp_ok( $got, '&&', $expected, 'this && that' );
    ...etc...

Its advantage over C<ok()> is when the test fails you'll know what $got
and $expected were:

    not ok 1
    #   Failed test in foo.t at line 12.
    #     '23'
    #         &&
    #     undef

It's also useful in those cases where you are comparing numbers and
C<is()>'s use of C<eq> will interfere:

    cmp_ok( $big_hairy_number, '==', $another_big_hairy_number );

It's especially useful when comparing greater-than or smaller-than
relation between values:

    cmp_ok( $some_value, '<=', $upper_limit );

=item B<can_ok>

  can_ok($module, @methods);
  can_ok($object, @methods);

Checks to make sure the $module or $object can do these @methods
(works with functions, too).

    can_ok('Foo', qw(this that whatever));

is almost exactly like saying:

    ok( Foo->can('this') &&
        Foo->can('that') &&
        Foo->can('whatever')
      );

only without all the typing and with a better interface.  Handy for
quickly testing an interface.

No matter how many @methods you check, a single C<can_ok()> call counts
as one test.  If you desire otherwise, use:

    foreach my $meth (@methods) {
        can_ok('Foo', $meth);
    }

=item B<isa_ok>

  isa_ok($object,   $class, $object_name);
  isa_ok($subclass, $class, $object_name);
  isa_ok($ref,      $type,  $ref_name);

Checks to see if the given C<< $object->isa($class) >>.  Also checks to make
sure the object was defined in the first place.  Handy for this sort
of thing:

    my $obj = Some::Module->new;
    isa_ok( $obj, 'Some::Module' );

where you'd otherwise have to write

    my $obj = Some::Module->new;
    ok( defined $obj && $obj->isa('Some::Module') );

to safeguard against your test script blowing up.

You can also test a class, to make sure that it has the right ancestor:

    isa_ok( 'Vole', 'Rodent' );

It works on references, too:

    isa_ok( $array_ref, 'ARRAY' );

The diagnostics of this test normally just refer to 'the object'.  If
you'd like them to be more specific, you can supply an $object_name
(for example 'Test customer').

=item B<new_ok>

  my $obj = new_ok( $class );
  my $obj = new_ok( $class => \@args );
  my $obj = new_ok( $class => \@args, $object_name );

A convenience function which combines creating an object and calling
C<isa_ok()> on that object.

It is basically equivalent to:

    my $obj = $class->new(@args);
    isa_ok $obj, $class, $object_name;

If @args is not given, an empty list will be used.

This function only works on C<new()> and it assumes C<new()> will return
just a single object which isa C<$class>.

=item B<subtest>

    subtest $name => \&code;

C<subtest()> runs the &code as its own little test with its own plan and
its own result.  The main test counts this as a single test using the
result of the whole subtest to determine if its ok or not ok.

For example...

  use Test::More tests => 3;

  pass("First test");

  subtest 'An example subtest' => sub {
      plan tests => 2;

      pass("This is a subtest");
      pass("So is this");
  };

  pass("Third test");

This would produce.

  1..3
  ok 1 - First test
      # Subtest: An example subtest
      1..2
      ok 1 - This is a subtest
      ok 2 - So is this
  ok 2 - An example subtest
  ok 3 - Third test

A subtest may call C<skip_all>.  No tests will be run, but the subtest is
considered a skip.

  subtest 'skippy' => sub {
      plan skip_all => 'cuz I said so';
      pass('this test will never be run');
  };

Returns true if the subtest passed, false otherwise.

Due to how subtests work, you may omit a plan if you desire.  This adds an
implicit C<done_testing()> to the end of your subtest.  The following two
subtests are equivalent:

  subtest 'subtest with implicit done_testing()', sub {
      ok 1, 'subtests with an implicit done testing should work';
      ok 1, '... and support more than one test';
      ok 1, '... no matter how many tests are run';
  };

  subtest 'subtest with explicit done_testing()', sub {
      ok 1, 'subtests with an explicit done testing should work';
      ok 1, '... and support more than one test';
      ok 1, '... no matter how many tests are run';
      done_testing();
  };

B<NOTE on using skip_all in a BEGIN inside a subtest.>

Sometimes you want to run a file as a subtest:

    subtest foo => sub { do 'foo.pl' };

where foo.pl;

    use Test::More skip_all => "won't work";

This will work fine, but will issue a warning. The issue is that the normal
flow control method will now work inside a BEGIN block. The C<use Test::More>
statement is run in a BEGIN block. As a result an exception is thrown instead
of the normal flow control. In most cases this works fine.

A case like this however will have issues:

    subtest foo => sub {
        do 'foo.pl'; # Will issue a skip_all

        # You would expect the subtest to stop, but the 'do' captures the
        # exception, as a result the following statement does execute.

        ok(0, "blah");
    };

You can work around this by cheking the return from C<do>, along with C<$@>, or you can alter foo.pl so that it does this:

    use Test::More;
    plan skip_all => 'broken';

When the plan is issues outside of the BEGIN block it works just fine.

=item B<pass>

=item B<fail>

  pass($test_name);
  fail($test_name);

Sometimes you just want to say that the tests have passed.  Usually
the case is you've got some complicated condition that is difficult to
wedge into an C<ok()>.  In this case, you can simply use C<pass()> (to
declare the test ok) or fail (for not ok).  They are synonyms for
C<ok(1)> and C<ok(0)>.

Use these very, very, very sparingly.

=back

=head2 Debugging tests

Want a stack trace when a test failure occurs? Have some other hook in mind?
Easy!

    use Test::More;
    use Carp qw/confess/;

    Test::Stream->shared->listen(sub {
        my ($stream, $event) = @_;

        # Only care about 'Ok' events (this includes subtests)
        return unless $event->isa('Test::Stream::Event::Ok');

        # Only care about failures
        return if $event->bool;

        confess "Failed test! here is a stacktrace!";
    });

    ok(0, "This will give you a trace.");

=head2 Module tests

Sometimes you want to test if a module, or a list of modules, can
successfully load.  For example, you'll often want a first test which
simply loads all the modules in the distribution to make sure they
work before going on to do more complicated testing.

For such purposes we have C<use ok 'module'>. C<use_ok> is still around, but is
considered discouraged in favor of C<use ok 'module'>. C<require_ok> is also
discouraged because it tries to guess if you gave it a file name or module
name. C<require_ok>'s guessing mechanism is broken, but fixing it can break
things.

=over 4

=item B<use ok 'module'>

=item B<use ok 'module', @args>

    use ok 'Some::Module';
    use ok 'Another::Module', qw/import_a import_b/;

This will load the specified module and pass through any extra arguments to
that module. This will also produce a test result.

B<Note - Do not do this:>

    my $class = 'My::Module';
    use ok $class;

The value 'My::Module' is not assigned to the C<$class> variable until
run-time, but the C<use ok $class> statement is run at compile time. The result
of this is that we try to load 'undef' as a module. This will generate an
exception: C<'use ok' called with an empty argument, did you try to use a package name from an uninitialized variable?>

If you must do something like this, here is a more-correct way:

    my $class;
    BEGIN { $class = 'My::Module' }
    use ok $class;

=item B<require_ok>

B<***DISCOURAGED***> - Broken guessing

   require_ok($module);
   require_ok($file);

Tries to C<require> the given $module or $file.  If it loads
successfully, the test will pass.  Otherwise it fails and displays the
load error.

C<require_ok> will guess whether the input is a module name or a
filename.

No exception will be thrown if the load fails.

    # require Some::Module
    require_ok "Some::Module";

    # require "Some/File.pl";
    require_ok "Some/File.pl";

    # stop testing if any of your modules will not load
    for my $module (@module) {
        require_ok $module or BAIL_OUT "Can't load $module";
    }

=item B<use_ok>

B<***DISCOURAGED***> See C<use ok 'module'>

   BEGIN { use_ok($module); }
   BEGIN { use_ok($module, @imports); }

Like C<require_ok>, but it will C<use> the $module in question and
only loads modules, not files.

If you just want to test a module can be loaded, use C<require_ok>.

If you just want to load a module in a test, we recommend simply using
C<use> directly.  It will cause the test to stop.

It's recommended that you run C<use_ok()> inside a BEGIN block so its
functions are exported at compile-time and prototypes are properly
honored.

If @imports are given, they are passed through to the use.  So this:

   BEGIN { use_ok('Some::Module', qw(foo bar)) }

is like doing this:

   use Some::Module qw(foo bar);

Version numbers can be checked like so:

   # Just like "use Some::Module 1.02"
   BEGIN { use_ok('Some::Module', 1.02) }

Don't try to do this:

   BEGIN {
       use_ok('Some::Module');

       ...some code that depends on the use...
       ...happening at compile time...
   }

because the notion of "compile-time" is relative.  Instead, you want:

  BEGIN { use_ok('Some::Module') }
  BEGIN { ...some code that depends on the use... }

If you want the equivalent of C<use Foo ()>, use a module but not
import anything, use C<require_ok>.

  BEGIN { require_ok "Foo" }

=back

=head2 Complex data structures

Not everything is a simple eq check or regex.  There are times you
need to see if two data structures are equivalent.  For these
instances Test::More provides a handful of useful functions.

B<NOTE> I'm not quite sure what will happen with filehandles.

=over 4

=item B<is_deeply>

  is_deeply( $got, $expected, $test_name );

Similar to C<is()>, except that if $got and $expected are references, it
does a deep comparison walking each data structure to see if they are
equivalent.  If the two structures are different, it will display the
place where they start differing.

C<is_deeply()> compares the dereferenced values of references, the
references themselves (except for their type) are ignored.  This means
aspects such as blessing and ties are not considered "different".

C<is_deeply()> currently has very limited handling of function reference
and globs.  It merely checks if they have the same referent.  This may
improve in the future.

L<Test::Differences> and L<Test::Deep> provide more in-depth functionality
along these lines.


=back


=head2 Diagnostics

If you pick the right test function, you'll usually get a good idea of
what went wrong when it failed.  But sometimes it doesn't work out
that way.  So here we have ways for you to write your own diagnostic
messages which are safer than just C<print STDERR>.

=over 4

=item B<diag>

  diag(@diagnostic_message);

Prints a diagnostic message which is guaranteed not to interfere with
test output.  Like C<print> @diagnostic_message is simply concatenated
together.

Returns false, so as to preserve failure.

Handy for this sort of thing:

    ok( grep(/foo/, @users), "There's a foo user" ) or
        diag("Since there's no foo, check that /etc/bar is set up right");

which would produce:

    not ok 42 - There's a foo user
    #   Failed test 'There's a foo user'
    #   in foo.t at line 52.
    # Since there's no foo, check that /etc/bar is set up right.

You might remember C<ok() or diag()> with the mnemonic C<open() or
die()>.

B<NOTE> The exact formatting of the diagnostic output is still
changing, but it is guaranteed that whatever you throw at it won't
interfere with the test.

=item B<note>

  note(@diagnostic_message);

Like C<diag()>, except the message will not be seen when the test is run
in a harness.  It will only be visible in the verbose TAP stream.

Handy for putting in notes which might be useful for debugging, but
don't indicate a problem.

    note("Tempfile is $tempfile");

=item B<explain>

  my @dump = explain @diagnostic_message;

Will dump the contents of any references in a human readable format.
Usually you want to pass this into C<note> or C<diag>.

Handy for things like...

    is_deeply($have, $want) || diag explain $have;

or

    note explain \%args;
    Some::Class->method(%args);

=back


=head2 Conditional tests

Sometimes running a test under certain conditions will cause the
test script to die.  A certain function or method isn't implemented
(such as C<fork()> on MacOS), some resource isn't available (like a
net connection) or a module isn't available.  In these cases it's
necessary to skip tests, or declare that they are supposed to fail
but will work in the future (a todo test).

For more details on the mechanics of skip and todo tests see
L<Test::Harness>.

The way Test::More handles this is with a named block.  Basically, a
block of tests which can be skipped over or made todo.  It's best if I
just show you...

=over 4

=item B<SKIP: BLOCK>

  SKIP: {
      skip $why, $how_many if $condition;

      ...normal testing code goes here...
  }

This declares a block of tests that might be skipped, $how_many tests
there are, $why and under what $condition to skip them.  An example is
the easiest way to illustrate:

    SKIP: {
        eval { require HTML::Lint };

        skip "HTML::Lint not installed", 2 if $@;

        my $lint = new HTML::Lint;
        isa_ok( $lint, "HTML::Lint" );

        $lint->parse( $html );
        is( $lint->errors, 0, "No errors found in HTML" );
    }

If the user does not have HTML::Lint installed, the whole block of
code I<won't be run at all>.  Test::More will output special ok's
which Test::Harness interprets as skipped, but passing, tests.

It's important that $how_many accurately reflects the number of tests
in the SKIP block so the # of tests run will match up with your plan.
If your plan is C<no_plan> $how_many is optional and will default to 1.

It's perfectly safe to nest SKIP blocks.  Each SKIP block must have
the label C<SKIP>, or Test::More can't work its magic.

You don't skip tests which are failing because there's a bug in your
program, or for which you don't yet have code written.  For that you
use TODO.  Read on.

=item B<TODO: BLOCK>

    TODO: {
        local $TODO = $why if $condition;

        ...normal testing code goes here...
    }

Declares a block of tests you expect to fail and $why.  Perhaps it's
because you haven't fixed a bug or haven't finished a new feature:

    TODO: {
        local $TODO = "URI::Geller not finished";

        my $card = "Eight of clubs";
        is( URI::Geller->your_card, $card, 'Is THIS your card?' );

        my $spoon;
        URI::Geller->bend_spoon;
        is( $spoon, 'bent',    "Spoon bending, that's original" );
    }

With a todo block, the tests inside are expected to fail.  Test::More
will run the tests normally, but print out special flags indicating
they are "todo".  L<Test::Harness> will interpret failures as being ok.
Should anything succeed, it will report it as an unexpected success.
You then know the thing you had todo is done and can remove the
TODO flag.

The nice part about todo tests, as opposed to simply commenting out a
block of tests, is it's like having a programmatic todo list.  You know
how much work is left to be done, you're aware of what bugs there are,
and you'll know immediately when they're fixed.

Once a todo test starts succeeding, simply move it outside the block.
When the block is empty, delete it.


=item B<todo_skip>

    TODO: {
        todo_skip $why, $how_many if $condition;

        ...normal testing code...
    }

With todo tests, it's best to have the tests actually run.  That way
you'll know when they start passing.  Sometimes this isn't possible.
Often a failing test will cause the whole program to die or hang, even
inside an C<eval BLOCK> with and using C<alarm>.  In these extreme
cases you have no choice but to skip over the broken tests entirely.

The syntax and behavior is similar to a C<SKIP: BLOCK> except the
tests will be marked as failing but todo.  L<Test::Harness> will
interpret them as passing.


=item When do I use SKIP vs. TODO?

B<If it's something the user might not be able to do>, use SKIP.
This includes optional modules that aren't installed, running under
an OS that doesn't have some feature (like C<fork()> or symlinks), or maybe
you need an Internet connection and one isn't available.

B<If it's something the programmer hasn't done yet>, use TODO.  This
is for any code you haven't written yet, or bugs you have yet to fix,
but want to put tests in your testing script (always a good idea).


=back


=head2 Test control

=over 4

=item B<BAIL_OUT>

    BAIL_OUT($reason);

Indicates to the harness that things are going so badly all testing
should terminate.  This includes the running of any additional test scripts.

This is typically used when testing cannot continue such as a critical
module failing to compile or a necessary external utility not being
available such as a database connection failing.

The test will exit with 255.

For even better control look at L<Test::Most>.

=back

=head2 Discouraged comparison functions

The use of the following functions is discouraged as they are not
actually testing functions and produce no diagnostics to help figure
out what went wrong.  They were written before C<is_deeply()> existed
because I couldn't figure out how to display a useful diff of two
arbitrary data structures.

These functions are usually used inside an C<ok()>.

    ok( eq_array(\@got, \@expected) );

C<is_deeply()> can do that better and with diagnostics.

    is_deeply( \@got, \@expected );

They may be deprecated in future versions.

=over 4

=item B<eq_array>

  my $is_eq = eq_array(\@got, \@expected);

Checks if two arrays are equivalent.  This is a deep check, so
multi-level structures are handled correctly.

=item B<eq_hash>

  my $is_eq = eq_hash(\%got, \%expected);

Determines if the two hashes contain the same keys and values.  This
is a deep check.


=item B<eq_set>

  my $is_eq = eq_set(\@got, \@expected);

Similar to C<eq_array()>, except the order of the elements is B<not>
important.  This is a deep check, but the irrelevancy of order only
applies to the top level.

    ok( eq_set(\@got, \@expected) );

Is better written:

    is_deeply( [sort @got], [sort @expected] );

B<NOTE> By historical accident, this is not a true set comparison.
While the order of elements does not matter, duplicate elements do.

B<NOTE> C<eq_set()> does not know how to deal with references at the top
level.  The following is an example of a comparison which might not work:

    eq_set([\1, \2], [\2, \1]);

L<Test::Deep> contains much better set comparison functions.

=back


=head2 Extending and Embedding Test::More

Sometimes the Test::More interface isn't quite enough.  Fortunately,
Test::More is built on top of L<Test::Stream> which provides a single,
unified backend for any test library to use.  This means two test
libraries which both use <Test::Stream> B<can> be used together in the
same program>.

=head1 EXIT CODES

If all your tests passed, L<Test::Builder> will exit with zero (which is
normal).  If anything failed it will exit with how many failed.  If
you run less (or more) tests than you planned, the missing (or extras)
will be considered failures.  If no tests were ever run L<Test::Builder>
will throw a warning and exit with 255.  If the test died, even after
having successfully completed all its tests, it will still be
considered a failure and will exit with 255.

So the exit codes are...

    0                   all tests successful
    255                 test died or all passed but wrong # of tests run
    any other number    how many failed (including missing or extras)

If you fail more than 254 tests, it will be reported as 254.

B<NOTE>  This behavior may go away in future versions.


=head1 COMPATIBILITY

Test::More works with Perls as old as 5.8.1.

Thread support is not very reliable before 5.10.1, but that's
because threads are not very reliable before 5.10.1.

Although Test::More has been a core module in versions of Perl since 5.6.2,
Test::More has evolved since then, and not all of the features you're used to
will be present in the shipped version of Test::More. If you are writing a
module, don't forget to indicate in your package metadata the minimum version
of Test::More that you require. For instance, if you want to use
C<done_testing()> but want your test script to run on Perl 5.10.0, you will
need to explicitly require Test::More > 0.88.

Key feature milestones include:

=over 4

=item event stream

=item forking support

=item tap encoding

Test::Builder and Test::More version 1.301001 introduce these major
modernizations.

=item subtests

Subtests were released in Test::More 0.94, which came with Perl 5.12.0.
Subtests did not implicitly call C<done_testing()> until 0.96; the first Perl
with that fix was Perl 5.14.0 with 0.98.

=item C<done_testing()>

This was released in Test::More 0.88 and first shipped with Perl in 5.10.1 as
part of Test::More 0.92.

=item C<cmp_ok()>

Although C<cmp_ok()> was introduced in 0.40, 0.86 fixed an important bug to
make it safe for overloaded objects; the fixed first shipped with Perl in
5.10.1 as part of Test::More 0.92.

=item C<new_ok()> C<note()> and C<explain()>

These were was released in Test::More 0.82, and first shipped with Perl in
5.10.1 as part of Test::More 0.92.

=back

There is a full version history in the Changes file, and the Test::More
versions included as core can be found using L<Module::CoreList>:

    $ corelist -a Test::More


=head1 CAVEATS and NOTES

=over 4

=item utf8 / "Wide character in print"

If you use utf8 or other non-ASCII characters with Test::More you
might get a "Wide character in print" warning.
Using C<< binmode STDOUT, ":utf8" >> will not fix it.

Use the C<tap_encoding> function to configure the TAP stream encoding.

    use utf8;
    use Test::Stream; # imports tap_encoding
    use Test::More;
    tap_encoding 'utf8';

L<Test::Builder> (which powers Test::More) duplicates STDOUT and STDERR.
So any changes to them, including changing their output disciplines,
will not be seen by Test::More.

B<Note>:deprecated ways to use utf8 or other non-ASCII characters.

In the past it was necessary to alter the filehandle encoding prior to loading
Test::More. This is no longer necessary thanks to C<tap_encoding()>.

    # *** DEPRECATED WAY ***
    use open ':std', ':encoding(utf8)';
    use Test::More;

A more direct work around is to change the filehandles used by
L<Test::Builder>.

    # *** EVEN MORE DEPRECATED WAY ***
    my $builder = Test::More->builder;
    binmode $builder->output,         ":encoding(utf8)";
    binmode $builder->failure_output, ":encoding(utf8)";
    binmode $builder->todo_output,    ":encoding(utf8)";


=item Overloaded objects

String overloaded objects are compared B<as strings> (or in C<cmp_ok()>'s
case, strings or numbers as appropriate to the comparison op).  This
prevents Test::More from piercing an object's interface allowing
better blackbox testing.  So if a function starts returning overloaded
objects instead of bare strings your tests won't notice the
difference.  This is good.

However, it does mean that functions like C<is_deeply()> cannot be used to
test the internals of string overloaded objects.  In this case I would
suggest L<Test::Deep> which contains more flexible testing functions for
complex data structures.


=item Threads

B<NOTE:> The underlying mechanism to support threads has changed as of version
1.301001. Instead of sharing several variables and locking them, threads now
use the same mechanism as forking support. The new system writes events to temp
files which are culled by the main process.

Test::More will only be aware of threads if C<use threads> has been done
I<before> Test::More is loaded.  This is ok:

    use threads;
    use Test::More;

This may cause problems:

    use Test::More
    use threads;

5.8.1 and above are supported.  Anything below that has too many bugs.

=back


=head1 HISTORY

This is a case of convergent evolution with Joshua Pritikin's L<Test>
module.  I was largely unaware of its existence when I'd first
written my own C<ok()> routines.  This module exists because I can't
figure out how to easily wedge test names into Test's interface (along
with a few other problems).

The goal here is to have a testing utility that's simple to learn,
quick to use and difficult to trip yourself up with while still
providing more flexibility than the existing Test.pm.  As such, the
names of the most common routines are kept tiny, special cases and
magic side-effects are kept to a minimum.  WYSIWYG.


=head1 SEE ALSO

=head2 ALTERNATIVES

L<Test::Simple> if all this confuses you and you just want to write
some tests.  You can upgrade to Test::More later (it's forward
compatible).

L<Test::Legacy> tests written with Test.pm, the original testing
module, do not play well with other testing libraries.  Test::Legacy
emulates the Test.pm interface and does play well with others.

=head2 TESTING FRAMEWORKS

L<Fennec> The Fennec framework is a testers toolbox. It uses L<Test::Builder>
under the hood. It brings enhancements for forking, defining state, and
mocking. Fennec enhances several modules to work better together than they
would if you loaded them individually on your own.

L<Fennec::Declare> Provides enhanced (L<Devel::Declare>) syntax for Fennec.

=head2 ADDITIONAL LIBRARIES

L<Test::Differences> for more ways to test complex data structures.
And it plays well with Test::More.

L<Test::Class> is like xUnit but more perlish.

L<Test::Deep> gives you more powerful complex data structure testing.

L<Test::Inline> shows the idea of embedded testing.

L<Mock::Quick> The ultimate mocking library. Easily spawn objects defined on
the fly. Can also override, block, or reimplement packages as needed.

L<Test::FixtureBuilder> Quickly define fixture data for unit tests.

=head2 OTHER COMPONENTS

L<Test::Harness> is the test runner and output interpreter for Perl.
It's the thing that powers C<make test> and where the C<prove> utility
comes from.

=head2 BUNDLES

L<Bundle::Test> installs a whole bunch of useful test modules.

L<Test::Most> Most commonly needed test functions and features.

=encoding utf8

=head1 SOURCE

The source code repository for Test::More can be found at
F<http://github.com/Test-More/test-more/>.

=head1 MAINTAINER

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

The following people have all contributed to the Test-More dist (sorted using
VIM's sort function).

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=item Fergal Daly E<lt>fergal@esatclear.ie>E<gt>

=item Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

=item Michael G Schwern E<lt>schwern@pobox.comE<gt>

=item 唐鳳

=back

=head1 COPYRIGHT

There has been a lot of code migration between modules,
here are all the original copyrights together:

=over 4

=item Test::Stream

=item Test::Stream::Tester

Copyright 2014 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=item Test::Simple

=item Test::More

=item Test::Builder

Originally authored by Michael G Schwern E<lt>schwern@pobox.comE<gt> with much
inspiration from Joshua Pritikin's Test module and lots of help from Barrie
Slaymaker, Tony Bowden, blackstar.co.uk, chromatic, Fergal Daly and the perl-qa
gang.

Idea by Tony Bowden and Paul Johnson, code by Michael G Schwern
E<lt>schwern@pobox.comE<gt>, wardrobe by Calvin Klein.

Copyright 2001-2008 by Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=item Test::use::ok

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to L<Test-use-ok>.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=item Test::Tester

This module is copyright 2005 Fergal Daly <fergal@esatclear.ie>, some parts
are based on other people's work.

Under the same license as Perl itself

See http://www.perl.com/perl/misc/Artistic.html

=item Test::Builder::Tester

Copyright Mark Fowler E<lt>mark@twoshortplanks.comE<gt> 2002, 2004.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=back
