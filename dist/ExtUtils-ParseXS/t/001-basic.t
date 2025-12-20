#!/usr/bin/perl

use strict;
use Test::More;
use Config;
use DynaLoader;
use ExtUtils::CBuilder;
use lib (-d 't' ? File::Spec->catdir(qw(t lib)) : 'lib');
use PrimitiveCapture;

my ($source_file, $obj_file, $lib_file);

require_ok( 'ExtUtils::ParseXS' );

# Borrow the useful heredoc quoting/indenting function.
*Q = \&ExtUtils::ParseXS::Q;


{
    # Minimal tie package to capture output to a filehandle
    package Capture;
    sub TIEHANDLE { bless {} }
    sub PRINT { shift->{buf} .= join '', @_ }
    sub PRINTF    { my $obj = shift; my $fmt = shift;
                    $obj->{buf} .= sprintf $fmt, @_ }
    sub content { shift->{buf} }
}

chdir('t') if -d 't';
push @INC, '.';

package ExtUtils::ParseXS;
our $DIE_ON_ERROR = 1;
our $AUTHOR_WARNINGS = 1;
package main;

use Carp; #$SIG{__WARN__} = \&Carp::cluck;

# The linker on some platforms doesn't like loading libraries using relative
# paths. Android won't find relative paths, and system perl on macOS will
# refuse to load relative paths. The path that DynaLoader uses to load the
# .so or .bundle file is based on the @INC path that the library is loaded
# from. The XSTest module we're using for testing is in the current directory,
# so we need an absolute path in @INC rather than '.'. Just convert all of the
# paths to absolute for simplicity.
@INC = map { File::Spec->rel2abs($_) } @INC;



#########################

# test_many(): test a list of XSUB bodies with a common XS preamble.
# $prefix is the prefix of the XSUB's name, in order to be able to extract
# out the C function definition. Typically the generated C subs look like:
#
#    XS_EXTERNAL(XS_Foo_foo)
#    {
#    ...
#    }
# So setting prefix to 'XS_Foo' will match any fn declared in the Foo
# package, while 'boot_Foo' will extract the boot fn.
#
# For each body, a series of regexes is matched against the STDOUT or
# STDERR produced.
#
# $test_fns is an array ref, where each element is an array ref consisting
# of:
#  
# [
#     "common prefix for test descriptions",
#     [ ... lines to be ...
#       ... used as ...
#       ... XSUB body...
#     ],
#     [ check_stderr, expect_nomatch, qr/expected/, "test description"],
#     [ ... and more tests ..]
#     ....
# ]
#
#  where:
#  check_stderr:   boolean: test STDERR against regex rather than STDOUT
#  expect_nomatch: boolean: pass if the regex *doesn't* match

sub test_many {
    my ($preamble, $prefix, $test_fns) = @_;
    for my $test_fn (@$test_fns) {
        my ($desc_prefix, $xsub_lines, @tests) = @$test_fn;

        my $text = $preamble;
        for (@$xsub_lines) {
            $text .= $_;
            $text .= "\n" unless /\n\z/;
        }

        tie *FH, 'Capture';
        my $pxs = ExtUtils::ParseXS->new;
        my $err;
        my $stderr = PrimitiveCapture::capture_stderr(sub {
            eval {
                $pxs->process_file( filename => \$text, output => \*FH);
            };
            $err = $@;
        });
        if (defined $err and length $err) {
            $stderr = "" unless defined $stderr;
            $stderr = $err . $stderr;
        }

        my $out = tied(*FH)->content;
        untie *FH;

        # trim the output to just the function in question to make
        # test diagnostics smaller.
        if (defined($prefix) and !length($err) and $out =~ /\S/) {
            $out =~ s/\A.*? (^\w+\(${prefix} .*? ^}).*\z/$1/xms
                or do {
                    # print STDERR $out;
                    die "$desc_prefix: couldn't trim output to only function starting '$prefix'\n";
                }
        }

        my $err_tested;
        for my $test (@tests) {
            my ($is_err, $exp_nomatch, $qr, $desc) = @$test;
            $desc = "$desc_prefix: $desc" if length $desc_prefix;
            my $str;
            if ($is_err) {
                $err_tested = 1;
                $str = $stderr;
            }
            else {
                $str = $out;
            }
            if ($exp_nomatch) {
                unlike $str, $qr, $desc;
            }
            else {
                like $str, $qr, $desc;
            }
        }
        # if there were no tests that expect an error, test that there
        # were no errors
        if (!$err_tested) {
            is $stderr, undef, "$desc_prefix: no errors expected";
        }
    }
}

#########################


{ # first block: try without linenumbers
my $pxs = ExtUtils::ParseXS->new;
# Try sending to filehandle
tie *FH, 'Capture';
$pxs->process_file( filename => 'XSTest.xs', output => \*FH, prototypes => 1 );
like tied(*FH)->content, '/is_even/', "Test that output contains some text";

$source_file = 'XSTest.c';

# Try sending to file
$pxs->process_file(filename => 'XSTest.xs', output => $source_file, prototypes => 0);
ok -e $source_file, "Create an output file";

my $quiet = $ENV{PERL_CORE} && !$ENV{HARNESS_ACTIVE};
my $b = ExtUtils::CBuilder->new(quiet => $quiet);

SKIP: {
  skip "no compiler available", 2
    if ! $b->have_compiler;
  $obj_file = $b->compile( source => $source_file );
  ok $obj_file, "ExtUtils::CBuilder::compile() returned true value";
  ok -e $obj_file, "Make sure $obj_file exists";
}

SKIP: {
  skip "no dynamic loading", 5
    if !$b->have_compiler || !$Config{usedl};
  my $module = 'XSTest';
  $lib_file = $b->link( objects => $obj_file, module_name => $module );
  ok $lib_file, "ExtUtils::CBuilder::link() returned true value";
  ok -e $lib_file,  "Make sure $lib_file exists";

  eval {require XSTest};
  is $@, '', "No error message recorded, as expected";
  ok  XSTest::is_even(8),
    "Function created thru XS returned expected true value";
  ok !XSTest::is_even(9),
    "Function created thru XS returned expected false value";

  # Win32 needs to close the DLL before it can unlink it, but unfortunately
  # dl_unload_file was missing on Win32 prior to perl change #24679!
  if ($^O eq 'MSWin32' and defined &DynaLoader::dl_unload_file) {
    for (my $i = 0; $i < @DynaLoader::dl_modules; $i++) {
      if ($DynaLoader::dl_modules[$i] eq $module) {
        DynaLoader::dl_unload_file($DynaLoader::dl_librefs[$i]);
        last;
      }
    }
  }
}

my $seen = 0;
open my $IN, '<', $source_file
  or die "Unable to open $source_file: $!";
while (my $l = <$IN>) {
  $seen++ if $l =~ m/#line\s1\s/;
}
is( $seen, 1, "Line numbers created in output file, as intended" );
{
    #rewind .c file and regexp it to look for code generation problems
    local $/ = undef;
    seek($IN, 0, 0);
    my $filecontents = <$IN>;
    $filecontents =~ s/^#if defined\(__HP_cc\).*\n#.*\n#endif\n//gm;
    my $good_T_BOOL_re =
qr|\QXS_EUPXS(XS_XSTest_T_BOOL)\E
.+?
#line \d+\Q "XSTest.c"
	ST(0) = boolSV(RETVAL);
    }
    XSRETURN(1);
}
\E|s;
    like($filecontents, $good_T_BOOL_re, "T_BOOL doesn\'t have an extra sv_newmortal or sv_2mortal");

    my $good_T_BOOL_2_re =
qr|\QXS_EUPXS(XS_XSTest_T_BOOL_2)\E
.+?
#line \d+\Q "XSTest.c"
	sv_setsv(ST(0), boolSV(in));
	SvSETMAGIC(ST(0));
    }
    XSRETURN(1);
}
\E|s;
    like($filecontents, $good_T_BOOL_2_re, 'T_BOOL_2 doesn\'t have an extra sv_newmortal or sv_2mortal');
    my $good_T_BOOL_OUT_re =
qr|\QXS_EUPXS(XS_XSTest_T_BOOL_OUT)\E
.+?
#line \d+\Q "XSTest.c"
	sv_setsv(ST(0), boolSV(out));
	SvSETMAGIC(ST(0));
    }
    XSRETURN_EMPTY;
}
\E|s;
    like($filecontents, $good_T_BOOL_OUT_re, 'T_BOOL_OUT doesn\'t have an extra sv_newmortal or sv_2mortal');

}
close $IN or die "Unable to close $source_file: $!";

unless ($ENV{PERL_NO_CLEANUP}) {
  for ( $obj_file, $lib_file, $source_file) {
    next unless defined $_;
    1 while unlink $_;
  }
}
}

#####################################################################

{ # second block: try with linenumbers
my $pxs = ExtUtils::ParseXS->new;
# Try sending to filehandle
tie *FH, 'Capture';
$pxs->process_file(
    filename => 'XSTest.xs',
    output => \*FH,
    prototypes => 1,
    linenumbers => 0,
);
like tied(*FH)->content, '/is_even/', "Test that output contains some text";

$source_file = 'XSTest.c';

# Try sending to file
$pxs->process_file(
    filename => 'XSTest.xs',
    output => $source_file,
    prototypes => 0,
    linenumbers => 0,
);
ok -e $source_file, "Create an output file";


my $seen = 0;
open my $IN, '<', $source_file
  or die "Unable to open $source_file: $!";
while (my $l = <$IN>) {
  $seen++ if $l =~ m/#line\s1\s/;
}
close $IN or die "Unable to close $source_file: $!";
is( $seen, 0, "No linenumbers created in output file, as intended" );

unless ($ENV{PERL_NO_CLEANUP}) {
  for ( $obj_file, $lib_file, $source_file) {
    next unless defined $_;
    1 while unlink $_;
  }
}
}
#####################################################################

{ # third block: broken typemap
my $pxs = ExtUtils::ParseXS->new;
tie *FH, 'Capture';
my $stderr = PrimitiveCapture::capture_stderr(sub {
  $pxs->process_file(filename => 'XSBroken.xs', output => \*FH);
});
like $stderr, '/Error: no INPUT definition/', "Exercise typemap error";
}
#####################################################################

{ # fourth block: https://github.com/Perl/perl5/issues/19661
  my $pxs = ExtUtils::ParseXS->new;
  tie *FH, 'Capture';
  my ($stderr, $filename);
  {
    $filename = 'XSFalsePositive.xs';
    $stderr = PrimitiveCapture::capture_stderr(sub {
      $pxs->process_file(filename => $filename, output => \*FH, prototypes => 1);
    });
    {
      unlike $stderr,
        qr/Warning: duplicate function definition 'do' detected in \Q$filename\E/,
        "No 'duplicate function definition' warning observed in $filename";
    }
  }
  {
    $filename = 'XSFalsePositive2.xs';
    $stderr = PrimitiveCapture::capture_stderr(sub {
      $pxs->process_file(filename => $filename, output => \*FH, prototypes => 1);
    });
    {
      unlike $stderr,
        qr/Warning: duplicate function definition 'do' detected in \Q$filename\E/,
        "No 'duplicate function definition' warning observed in $filename";
      }
  }
}

#####################################################################

{ # tight cpp directives
  my $pxs = ExtUtils::ParseXS->new;
  tie *FH, 'Capture';
  my $stderr = PrimitiveCapture::capture_stderr(sub { eval {
    $pxs->process_file(
      filename => 'XSTightDirectives.xs',
      output => \*FH,
      prototypes => 1);
  } or warn $@ });
  my $content = tied(*FH)->{buf};
  my $count = 0;
  $count++ while $content=~/^XS_EUPXS\(XS_My_do\)\n\{/mg;
  is $stderr, undef, "No error expected from TightDirectives.xs";
  is $count, 2, "Saw XS_MY_do definition the expected number of times";
}

{ # Alias check
  my $pxs = ExtUtils::ParseXS->new;
  tie *FH, 'Capture';
  my $erred;
  my $stderr = PrimitiveCapture::capture_stderr(sub {
      eval {
        $pxs->process_file(
          filename => 'XSAlias.xs',
          output => \*FH,
          prototypes => 1);
      };
      $erred = 1 if $@;
      print STDERR "got eval err [$@]\n" if $@;
    });
  die $stderr if $erred; # don't hide stderr if code errors out

  my $content = tied(*FH)->{buf};
  my $count = 0;
  $count++ while $content=~/^XS_EUPXS\(XS_My_do\)\n\{/mg;
  is $stderr,
    "Warning: aliases 'pox' and 'dox', 'lox' have"
    . " identical values of 1 in XSAlias.xs, line 9\n"
    . "    (If this is deliberate use a symbolic alias instead.)\n"
    . "Warning: conflicting duplicate alias 'pox' changes"
    . " definition from '1' to '2' in XSAlias.xs, line 10\n"
    . "Warning: aliases 'docks' and 'dox', 'lox' have"
    . " identical values of 1 in XSAlias.xs, line 11\n"
    . "Warning: aliases 'xunx' and 'do' have identical values"
    . " of 0 - the base function in XSAlias.xs, line 13\n"
    . "Warning: aliases 'do' and 'xunx', 'do' have identical values"
    . " of 0 - the base function in XSAlias.xs, line 14\n"
    . "Warning: aliases 'xunx2' and 'do', 'xunx' have"
    . " identical values of 0 - the base function in XSAlias.xs, line 15\n"
    ,
    "Saw expected warnings from XSAlias.xs in AUTHOR_WARNINGS mode";

  my $expect = quotemeta(<<'EOF_CONTENT');
         cv = newXSproto_portable("My::dachs", XS_My_do, file, "$");
         XSANY.any_i32 = 1;
         cv = newXSproto_portable("My::do", XS_My_do, file, "$");
         XSANY.any_i32 = 0;
         cv = newXSproto_portable("My::docks", XS_My_do, file, "$");
         XSANY.any_i32 = 1;
         cv = newXSproto_portable("My::dox", XS_My_do, file, "$");
         XSANY.any_i32 = 1;
         cv = newXSproto_portable("My::lox", XS_My_do, file, "$");
         XSANY.any_i32 = 1;
         cv = newXSproto_portable("My::pox", XS_My_do, file, "$");
         XSANY.any_i32 = 2;
         cv = newXSproto_portable("My::xukes", XS_My_do, file, "$");
         XSANY.any_i32 = 0;
         cv = newXSproto_portable("My::xunx", XS_My_do, file, "$");
         XSANY.any_i32 = 0;
EOF_CONTENT
  $expect=~s/(?:\\[ ])+/\\s+/g;
  $expect=qr/$expect/;
  like $content, $expect, "Saw expected alias initialization";

  #diag $content;
}
{ # Alias check with no dev warnings.
  my $pxs = ExtUtils::ParseXS->new;
  tie *FH, 'Capture';
  my $stderr = PrimitiveCapture::capture_stderr(sub {
    $pxs->process_file(
      filename => 'XSAlias.xs',
      output => \*FH,
      prototypes => 1,
      author_warnings => 0);
  });
  my $content = tied(*FH)->{buf};
  my $count = 0;
  $count++ while $content=~/^XS_EUPXS\(XS_My_do\)\n\{/mg;
  is $stderr,
    "Warning: conflicting duplicate alias 'pox' changes"
    . " definition from '1' to '2' in XSAlias.xs, line 10\n",
    "Saw expected warnings from XSAlias.xs";

  my $expect = quotemeta(<<'EOF_CONTENT');
         cv = newXSproto_portable("My::dachs", XS_My_do, file, "$");
         XSANY.any_i32 = 1;
         cv = newXSproto_portable("My::do", XS_My_do, file, "$");
         XSANY.any_i32 = 0;
         cv = newXSproto_portable("My::docks", XS_My_do, file, "$");
         XSANY.any_i32 = 1;
         cv = newXSproto_portable("My::dox", XS_My_do, file, "$");
         XSANY.any_i32 = 1;
         cv = newXSproto_portable("My::lox", XS_My_do, file, "$");
         XSANY.any_i32 = 1;
         cv = newXSproto_portable("My::pox", XS_My_do, file, "$");
         XSANY.any_i32 = 2;
         cv = newXSproto_portable("My::xukes", XS_My_do, file, "$");
         XSANY.any_i32 = 0;
         cv = newXSproto_portable("My::xunx", XS_My_do, file, "$");
         XSANY.any_i32 = 0;
EOF_CONTENT
  $expect=~s/(?:\\[ ])+/\\s+/g;
  $expect=qr/$expect/;
  like $content, $expect, "Saw expected alias initialization";

  #diag $content;
}
{
    my $file = $INC{"ExtUtils/ParseXS.pm"};
    $file=~s!ExtUtils/ParseXS\.pm\z!perlxs.pod!;
    open my $fh, "<", $file
        or die "Failed to open '$file' for read:$!";
    my $pod_version = "";
    while (defined(my $line= readline($fh))) {
        if ($line=~/\QThis document covers features supported by F<xsubpp> \E(\d+\.\d+)/) {
            $pod_version = $1;
            last;
        }
    }
    close $fh;
    ok($pod_version, "Found the version from perlxs.pod");
    is($pod_version, $ExtUtils::ParseXS::VERSION,
        "The version in perlxs.pod should match the version of ExtUtils::ParseXS");
}

# Basic test of the death() method.
# Run some code which will trigger a call to death(). Check that we get
# the expected error message (and as an exception rather than being on
# stderr.)
{
    my $pxs = ExtUtils::ParseXS->new;
    tie *FH, 'Capture';
    my $exception;
    my $stderr = PrimitiveCapture::capture_stderr(sub {
        eval {
            $pxs->process_file(
                filename => "XSNoMap.xs",
                output => \*FH,
               );
            1;
        } or $exception = $@;
    });
    is($stderr, undef, "should fail to parse");
    like($exception, qr/Error: Unterminated TYPEMAP section/,
         "check we throw rather than trying to deref '2'");
}


{
    # Basic test of using a string ref as the input file

    my $pxs = ExtUtils::ParseXS->new;
    tie *FH, 'Capture';
    my $text = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |void f(int a)
        |    CODE:
        |        mycode;
EOF

    $pxs->process_file( filename => \$text, output => \*FH);

    my $out = tied(*FH)->content;

    # We should have got some content, and the generated '#line' lines
    # should be sensible rather than '#line 1 SCALAR(0x...)'.
    like($out, qr/XS_Foo_f/,               "string ref: fn name");
    like($out, qr/#line \d+ "\(input\)"/,  "string ref input #line");
    like($out, qr/#line \d+ "\(output\)"/, "string ref output #line");
}


{
    # Test [=+;] on INPUT lines (including embedded double quotes
    # within expression which get evalled)

    my $pxs = ExtUtils::ParseXS->new;
    tie *FH, 'Capture';
    my $text = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |void f(mymarker1, a, b, c, d)
        |        int mymarker1
        |        int a = ($var"$var\"$type);
        |        int b ; blah($var"$var\"$type);
        |        int c + blurg($var"$var\"$type);
        |        int d
        |    CODE:
        |        mymarker2;
EOF

    $pxs->process_file( filename => \$text, output => \*FH);

    # Those INPUT lines should have produced something like:
    #
    #    int    mymarker1 = (int)SvIV(ST(0));
    #    int    a = (a"a\"int);
    #    int    b;
    #    int    c = (int)SvIV(ST(3))
    #    int    d = (int)SvIV(ST(4))
    #    blah(b"b\"int);
    #    blurg(c"c\"int);
    #    mymarker2;

    my $out = tied(*FH)->content;

    # trim the output to just the function in question to make
    # test diagnostics smaller.
    $out =~ s/\A .*? (int \s+ mymarker1 .*? mymarker2 ) .* \z/$1/xms
        or die "couldn't trim output";

    like($out, qr/^ \s+ int \s+ a\ =\ \Q(a"a"int);\E $/xm,
                        "INPUT '=' expands custom typemap");

    like($out, qr/^ \s+ int \s+ b;$/xm,
                        "INPUT ';' suppresses typemap");

    like($out, qr/^ \s+ int \s+ c\ =\ \Q(int)SvIV(ST(3))\E $/xm,
                        "INPUT '+' expands standard typemap");

    like($out,
        qr/^ \s+ int \s+ d\ = .*? blah\Q(b"b"int)\E .*? blurg\Q(c"c"int)\E .*? mymarker2/xms,
                        "INPUT '+' and ';' append expanded code");
}


{
    # Check that function pointer types are supported

    my $pxs = ExtUtils::ParseXS->new;
    tie *FH, 'Capture';
    my $text = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |TYPEMAP: <<EOF
        |int (*)(char *, long)   T_INT_FN_PTR
        |
        |INPUT
        |
        |T_INT_FN_PTR
        |    $var = ($type)INT2PTR(SvIV($arg))
        |EOF
        |
        |void foo(mymarker1, fn_ptr)
        |    int                   mymarker1
        |    int (*)(char *, long) fn_ptr
EOF

    $pxs->process_file( filename => \$text, output => \*FH);

    my $out = tied(*FH)->content;

    # trim the output to just the function in question to make
    # test diagnostics smaller.
    $out =~ s/\A .*? (int \s+ mymarker1 .*? XSRETURN ) .* \z/$1/xms
        or die "couldn't trim output";

    # remove all spaces for easier matching
    my $sout = $out;
    $sout =~ s/[ \t]+//g;

    like($sout,
        qr/\Qint(*fn_ptr)(char*,long)=(int(*)(char*,long))INT2PTR(SvIV(ST(1)))/,
        "function pointer declared okay");
}

{
    # Check that default expressions are template-expanded.
    # Whether this is sensible or not, Dynaloader and other distributions
    # rely on it

    my $pxs = ExtUtils::ParseXS->new;
    tie *FH, 'Capture';
    my $text = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |void foo(int mymarker1, char *pkg = "$Package")
        |    CODE:
        |        mymarker2;
EOF

    $pxs->process_file( filename => \$text, output => \*FH);

    my $out = tied(*FH)->content;

    # trim the output to just the function in question to make
    # test diagnostics smaller.
    $out =~ s/\A .*? (int \s+ mymarker1 .*? mymarker2 ) .* \z/$1/xms
        or die "couldn't trim output";

    # remove all spaces for easier matching
    my $sout = $out;
    $sout =~ s/[ \t]+//g;

    like($sout, qr/pkg.*=.*"Foo"/, "default expression expanded");
}

{
    # Test 'alien' INPUT parameters: ones which are declared in an INPUT
    # section but don't appear in the XSUB's signature. This ought to be
    # a compile error, but people rely on it to declare and initialise
    # variables which ought to be in a PREINIT or CODE section.

    my $pxs = ExtUtils::ParseXS->new;
    tie *FH, 'Capture';
    my $text = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |void foo(mymarker1)
        |        int mymarker1
        |        long alien1
        |        int  alien2 = 123;
        |    CODE:
        |        mymarker2;
EOF

    $pxs->process_file( filename => \$text, output => \*FH);

    my $out = tied(*FH)->content;

    # trim the output to just the function in question to make
    # test diagnostics smaller.
    $out =~ s/\A .*? (int \s+ mymarker1 .*? mymarker2 ) .* \z/$1/xms
        or die "couldn't trim output";

    # remove all spaces for easier matching
    my $sout = $out;
    $sout =~ s/[ \t]+//g;

    like($sout, qr/longalien1;\nintalien2=123;/, "alien INPUT parameters");
}

{
    # Test for 'No INPUT definition' error, particularly that the
    # type is output correctly in the error message.

    my $pxs = ExtUtils::ParseXS->new;
    my $text = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |TYPEMAP: <<EOF
        |Foo::Bar   T_FOOBAR
        |EOF
        |
        |void foo(fb)
        |        Foo::Bar fb
EOF

    tie *FH, 'Capture';
    my $stderr = PrimitiveCapture::capture_stderr(sub {
        $pxs->process_file( filename => \$text, output => \*FH);
    });

    like($stderr, qr/Error: no INPUT definition for type 'Foo::Bar'/,
                    "No INPUT definition");
}

{
    # Test for default arg mixed with initialisers

    my $pxs = ExtUtils::ParseXS->new;
    my $text = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |void foo(mymarker1, aaa = 111, bbb = 222, ccc = 333, ddd = NO_INIT, eee = NO_INIT, fff = NO_INIT)
        |    int mymarker1
        |    int aaa = 777;
        |    int bbb + 888;
        |    int ccc ; 999;
        |    int ddd = AAA;
        |    int eee + BBB;
        |    int fff ; CCC;
        |  CODE:
        |    mymarker2
EOF

    tie *FH, 'Capture';
    $pxs->process_file( filename => \$text, output => \*FH);

    my $out = tied(*FH)->content;

    # trim the output to just the function in question to make
    # test diagnostics smaller.
    $out =~ s/\A .*? (int \s+ mymarker1 .*? mymarker2 ) .* \z/$1/xms
        or die "couldn't trim output";

    # remove all spaces for easier matching
    my $sout = $out;
    $sout =~ s/[ \t]+//g;

    like($sout, qr/if\(items<3\)\nbbb=222;\nelse\{\nbbb=.*ST\(2\)\)\n;\n\}\n/,
                    "default with +init");

    like($sout, qr/\Qif(items>=6){\E\n\Qeee=(int)SvIV(ST(5))\E\n;\n\}/,
                "NO_INIT default with +init");

    {
        local $TODO = "default is lost in presence of initialiser";

        like($sout, qr/if\(items<2\)\naaa=111;\nelse\{\naaa=777;\n\}\n/,
                    "default with =init");

        like($sout, qr/if\(items<4\)\nccc=333;\n999;\n/,
                    "default with ;init");

        like($sout, qr/if\(items>=5\)\{\nddd=AAA;\n\}/,
                    "NO_INIT default with =init");
      unlike($sout, qr/^intddd=AAA;\n/m,
                    "NO_INIT default with =init no stray");

    }


    like($sout, qr/^$/m,
                    "default with +init deferred expression");
    like($sout, qr/^888;$/m,
                    "default with +init deferred expression");
    like($sout, qr/^999;$/m,
                    "default with ;init deferred expression");
    like($sout, qr/^BBB;$/m,
                    "NO_INIT default with +init deferred expression");
    like($sout, qr/^CCC;$/m,
                    "NO_INIT default with ;init deferred expression");

}

{
    # C++ methods: check that a sub name including a class auto-generates
    # a THIS or CLASS parameter

    my $pxs = ExtUtils::ParseXS->new;
    my $text = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |TYPEMAP: <<EOF
        |X::Y *    T_XY
        |INPUT
        |T_XY
        |   $var = my_xy($arg)
        |EOF
        |
        |int
        |X::Y::new(marker1)
        |    int mymarker1
        |  CODE:
        |
        |int
        |X::Y::f()
        |  CODE:
        |    mymarker2
        |
EOF

    tie *FH, 'Capture';
    $pxs->process_file( filename => \$text, output => \*FH);

    my $out = tied(*FH)->content;

    # trim the output to just the function in question to make
    # test diagnostics smaller.
    $out =~ s/\A .*? (int \s+ mymarker1 .*? mymarker2 ) .* \z/$1/xms
        or die "couldn't trim output";

    like($out, qr/^\s*\Qchar *\E\s+CLASS = \Q(char *)SvPV_nolen(ST(0))\E$/m,
                    "CLASS auto-generated");
    like($out, qr/^\s*\QX__Y *\E\s+THIS = \Qmy_xy(ST(0))\E$/m,
                    "THIS auto-generated");

}

{
    # Test for 'length(foo)' not legal in INPUT section

    my $pxs = ExtUtils::ParseXS->new;
    my $text = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |void foo(s)
        |        char *s
        |        int  length(s)
EOF

    tie *FH, 'Capture';
    my $stderr = PrimitiveCapture::capture_stderr(sub {
        $pxs->process_file( filename => \$text, output => \*FH);
    });

    like($stderr, qr/./,
                    "No length() in INPUT section");
}

{
    # Test for initialisers with unknown variable type.
    # This previously died.

    my $pxs = ExtUtils::ParseXS->new;
    my $text = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |void foo(a, b, c)
        |    UnknownType a = NO_INIT
        |    UnknownType b = bar();
        |    UnknownType c = baz($arg);
EOF

    tie *FH, 'Capture';
    my $stderr = PrimitiveCapture::capture_stderr(sub {
        $pxs->process_file( filename => \$text, output => \*FH);
    });

    is($stderr, undef, "Unknown type with initialiser: no errors");
}

{
    # Test for "duplicate definition of argument" errors

    my $pxs = ExtUtils::ParseXS->new;
    my $text = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |void foo(a, b, int c)
        |    int a;
        |    int a;
        |    int b;
        |    int b;
        |    int c;
        |    int alien;
        |    int alien;
EOF

    tie *FH, 'Capture';
    my $stderr = PrimitiveCapture::capture_stderr(sub {
        $pxs->process_file( filename => \$text, output => \*FH);
    });

    for my $var (qw(a b c alien)) {
        my $count = () =
            $stderr =~ /duplicate definition of parameter '$var'/g;
        is($count, 1, "One dup error for \"$var\"");
    }
}

{
    # Basic check of an OUT parameter where the type is specified either
    # in the signature or in an INPUT line

    my $pxs = ExtUtils::ParseXS->new;
    my $text = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |int
        |f(marker1, OUT a, OUT int b)
        |    int mymarker1
        |    int a
        |  CODE:
        |    mymarker2
        |
EOF

    tie *FH, 'Capture';
    $pxs->process_file( filename => \$text, output => \*FH);

    my $out = tied(*FH)->content;

    # trim the output to just the function in question to make
    # test diagnostics smaller.
    $out =~ s/\A .*? (int \s+ mymarker1 .*? mymarker2 ) .* \z/$1/xms
        or die "couldn't trim output";

    like($out, qr/^\s+int\s+a;\s*$/m, "OUT a");
    like($out, qr/^\s+int\s+b;\s*$/m, "OUT b");

}

{
    # Basic check of a "usage: ..." string.
    # In particular, it should strip away type and IN/OUT class etc.
    # Also, some distros include a test of their usage strings which
    # are sensitive to variations in white space, so this test
    # confirms that the exact white space is preserved, especially
    # with regards to space (or not) around the '=' of a default value.

    my $pxs = ExtUtils::ParseXS->new;
    my $text = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |int
        |foo(  a   ,  char   * b  , OUT  int  c  ,  OUTLIST int  d   ,    \
        |      IN_OUT char * * e    =   1  + 2 ,   long length(e)   ,    \
        |      char* f="abc"  ,     g  =   0  ,   ...     )
EOF

    tie *FH, 'Capture';
    $pxs->process_file( filename => \$text, output => \*FH);

    my $out = tied(*FH)->content;

    my $ok = $out =~ /croak_xs_usage\(cv,\s*(".*")\);\s*$/m;
    my $str = $ok ? $1 : '';
    ok $ok, "extract usage string";
    is $str, q("a, b, c, e=   1  + 2, f=\"abc\", g  =   0, ..."),
         "matched usage string";
}

{
    # Test for parameter parsing errors, including the effects of the
    # -noargtype and -noinout switches

    my $pxs = ExtUtils::ParseXS->new;
    my $text = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |void
        |foo(char* a, length(a) = 0, IN c, +++)
EOF

    tie *FH, 'Capture';
    my $stderr = PrimitiveCapture::capture_stderr(sub {
        eval {
            $pxs->process_file( filename => \$text, output => \*FH,
                                argtypes => 0, inout => 0);
        }
    });

    like $stderr, qr{\QError: parameter type not allowed under -noargtypes},
                 "no type under -noargtypes";
    like $stderr, qr{\QError: length() pseudo-parameter not allowed under -noargtypes},
                 "no length under -noargtypes";
    like $stderr, qr{\QError: parameter IN/OUT modifier not allowed under -noinout},
                 "no IN/OUT under -noinout";
    like $stderr, qr{\QError: unparseable XSUB parameter: '+++'},
                 "unparseable parameter";
}

{
    # Test for ellipis in the signature.

    my $pxs = ExtUtils::ParseXS->new;
    my $text = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |void
        |foo(int mymarker1, char *b = "...", int c = 0, ...)
        |    POSTCALL:
        |      mymarker2;
EOF

    tie *FH, 'Capture';
    $pxs->process_file( filename => \$text, output => \*FH);

    my $out = tied(*FH)->content;

    # trim the output to just the function in question to make
    # test diagnostics smaller.
    $out =~ s/\A .*? (int \s+ mymarker1 .*? mymarker2 ) .* \z/$1/xms
        or die "couldn't trim output";

    like $out, qr/\Qb = "..."/, "ellipsis: b has correct default value";
    like $out, qr/b = .*SvPV/,  "ellipsis: b has correct non-default value";
    like $out, qr/\Qc = 0/,     "ellipsis: c has correct default value";
    like $out, qr/c = .*SvIV/,  "ellipsis: c has correct non-default value";
    like $out, qr/\Qfoo(mymarker1, b, c)/, "ellipsis: wrapped function args";
}

{
    # Test for bad ellipsis

    my $pxs = ExtUtils::ParseXS->new;
    my $text = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |void
        |foo(a, ..., b)
EOF

    tie *FH, 'Capture';
    my $stderr = PrimitiveCapture::capture_stderr(sub {
        eval {
            $pxs->process_file( filename => \$text, output => \*FH);
        }
    });

    like $stderr, qr{\QError: further XSUB parameter seen after ellipsis},
                 "further XSUB parameter seen after ellipsis";
}

{
    # Test for C++ XSUB support: in particular,
    # - an XSUB function including a class in its name implies C++
    # - implicit CLASS/THIS first arg
    # - new and DESTROY methods handled specially
    # - 'static' return type implies class method
    # - 'const' can follow signature
    #

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |TYPEMAP: <<EOF
        |X::Y *        T_OBJECT
        |const X::Y *  T_OBJECT
        |
        |INPUT
        |T_OBJECT
        |    $var = my_in($arg);
        |
        |OUTPUT
        |T_OBJECT
        |    my_out($arg, $var)
        |EOF
        |
EOF

    my @test_fns = (
        # [
        #     "common prefix for test descriptions",
        #     [ ... lines to be ...
        #       ... used as ...
        #       ... XSUB body...
        #     ],
        #     [ check_stderr, expect_nomatch, qr/expected/, "test description"],
        #     [ ... and more tests ..]
        #     ....
        # ]

        [
            # test something that isn't actually C++
            "C++: plain new",
            [
                'X::Y*',
                'new(int aaa)',
            ],
            [ 0, 0, qr/usage\(cv,\s+"aaa"\)/,                "usage"    ],
            [ 0, 0, qr/\Qnew(aaa)/,                          "autocall" ],
        ],

        [
            # test something static that isn't actually C++
            "C++: plain static new",
            [
                'static X::Y*',
                'new(int aaa)',
            ],
            [ 0, 0, qr/usage\(cv,\s+"aaa"\)/,                "usage"    ],
            [ 0, 0, qr/\Qnew(aaa)/,                          "autocall" ],
            [ 1, 0, qr/Warning: ignoring 'static' type modifier:/, "warning" ],
        ],

        [
            # test something static that isn't actually C++ nor new
            "C++: plain static foo",
            [
                'static X::Y*',
                'foo(int aaa)',
            ],
            [ 0, 0, qr/usage\(cv,\s+"aaa"\)/,                "usage"    ],
            [ 0, 0, qr/\Qfoo(aaa)/,                          "autocall" ],
            [ 1, 0, qr/Warning: ignoring 'static' type modifier:/, "warning" ],
        ],

        [
            "C++: new",
            [
                'X::Y*',
                'X::Y::new(int aaa)',
            ],
            [ 0, 0, qr/usage\(cv,\s+"CLASS, aaa"\)/,         "usage"    ],
            [ 0, 0, qr/char\s*\*\s*CLASS\b/,                 "var decl" ],
            [ 0, 0, qr/\Qnew X::Y(aaa)/,                     "autocall" ],
        ],

        [
            "C++: static new",
            [
                'static X::Y*',
                'X::Y::new(int aaa)',
            ],
            [ 0, 0, qr/usage\(cv,\s+"CLASS, aaa"\)/,         "usage"    ],
            [ 0, 0, qr/char\s*\*\s*CLASS\b/,                 "var decl" ],
            [ 0, 0, qr/\QX::Y(aaa)/,                         "autocall" ],
        ],

        [
            "C++: fff",
            [
                'void',
                'X::Y::fff(int bbb)',
            ],
            [ 0, 0, qr/usage\(cv,\s+"THIS, bbb"\)/,          "usage"    ],
            [ 0, 0, qr/X__Y\s*\*\s*THIS\s*=\s*my_in/,        "var decl" ],
            [ 0, 0, qr/\QTHIS->fff(bbb)/,                    "autocall" ],
        ],

        [
            "C++: ggg",
            [
                'static int',
                'X::Y::ggg(int ccc)',
            ],
            [ 0, 0, qr/usage\(cv,\s+"CLASS, ccc"\)/,         "usage"    ],
            [ 0, 0, qr/char\s*\*\s*CLASS\b/,                 "var decl" ],
            [ 0, 0, qr/\QX::Y::ggg(ccc)/,                    "autocall" ],
        ],

        [
            "C++: hhh",
            [
                'int',
                'X::Y::hhh(int ddd) const',
            ],
            [ 0, 0, qr/usage\(cv,\s+"THIS, ddd"\)/,          "usage"    ],
            [ 0, 0, qr/const X__Y\s*\*\s*THIS\s*=\s*my_in/,  "var decl" ],
            [ 0, 0, qr/\QTHIS->hhh(ddd)/,                    "autocall" ],
        ],

        [
            "C++: only const",
            [
                'void',
                'foo() const',
            ],
            [ 1, 0, qr/\Qconst modifier only allowed on XSUBs which are C++ methods/,
                "got expected err" ],
        ],

        # autocall variants with const

        [
            "C++: static const",
            [ Q(<<'EOF') ],
                |static int
                |X::Y::foo() const
EOF
            [ 0, 0, qr/\QRETVAL = X::Y::foo()/,
                "autocall doesn't have const" ],
        ],

        [
            "C++: static new const",
            [ Q(<<'EOF') ],
                |static int
                |X::Y::new() const
EOF
            [ 0, 0, qr/\QRETVAL = X::Y()/,
                "autocall doesn't have const" ],
        ],

        [
            "C++: const",
            [ Q(<<'EOF') ],
                |int
                |X::Y::foo() const
EOF
            [ 0, 0, qr/\QRETVAL = THIS->foo()/,
                "autocall doesn't have const" ],
        ],

        [
            "C++: new const",
            [ Q(<<'EOF') ],
                |int
                |X::Y::new() const
EOF
            [ 0, 0, qr/\QRETVAL = new X::Y()/,
                "autocall doesn't have const" ],
        ],

        [
            "",
            [
                'int',
                'X::Y::f1(THIS, int i)',
            ],
            [ 1, 0, qr/\QError: duplicate definition of parameter 'THIS' /,
                 "C++: f1 dup THIS" ],
        ],

        [
            "",
            [
                'int',
                'X::Y::f2(int THIS, int i)',
            ],
            [ 1, 0, qr/\QError: duplicate definition of parameter 'THIS' /,
                 "C++: f2 dup THIS" ],
        ],

        [
            "",
            [
                'int',
                'X::Y::new(int CLASS, int i)',
            ],
            [ 1, 0, qr/\QError: duplicate definition of parameter 'CLASS' /,
                 "C++: new dup CLASS" ],
        ],

        [
            "C++: f3",
            [
                'int',
                'X::Y::f3(int i)',
                '    OUTPUT:',
                '        THIS',
            ],
            [ 0, 0, qr/usage\(cv,\s+"THIS, i"\)/,            "usage"    ],
            [ 0, 0, qr/X__Y\s*\*\s*THIS\s*=\s*my_in/,        "var decl" ],
            [ 0, 0, qr/\QTHIS->f3(i)/,                       "autocall" ],
            [ 0, 0, qr/^\s*\Qmy_out(ST(0), THIS)/m,          "set st0"  ],
        ],

        [
            # allow THIS's type to be overridden ...
            "C++: f4: override THIS type",
            [
                'int',
                'X::Y::f4(int i)',
                '    int THIS',
            ],
            [ 0, 0, qr/usage\(cv,\s+"THIS, i"\)/,       "usage"    ],
            [ 0, 0, qr/int\s*THIS\s*=\s*\(int\)/,       "var decl" ],
            [ 0, 1, qr/X__Y\s*\*\s*THIS/,               "no class var decl" ],
            [ 0, 0, qr/\QTHIS->f4(i)/,                  "autocall" ],
        ],

        [
            #  ... but not multiple times
            "C++: f5: dup override THIS type",
            [
                'int',
                'X::Y::f5(int i)',
                '    int THIS',
                '    long THIS',
            ],
            [ 1, 0, qr/\QError: duplicate definition of parameter 'THIS'/,
                    "dup err" ],
        ],

        [
            #  don't allow THIS in sig, with type
            "C++: f6: sig THIS type",
            [
                'int',
                'X::Y::f6(int THIS)',
            ],
            [ 1, 0, qr/\QError: duplicate definition of parameter 'THIS'/,
                    "dup err" ],
        ],

        [
            #  don't allow THIS in sig, without type
            "C++: f7: sig THIS no type",
            [
                'int',
                'X::Y::f7(THIS)',
            ],
            [ 1, 0, qr/\QError: duplicate definition of parameter 'THIS'/,
                    "dup err" ],
        ],

        [
            # allow CLASS's type to be overridden ...
            "C++: new: override CLASS type",
            [
                'int',
                'X::Y::new(int i)',
                '    int CLASS',
            ],
            [ 0, 0, qr/usage\(cv,\s+"CLASS, i"\)/,      "usage"    ],
            [ 0, 0, qr/int\s*CLASS\s*=\s*\(int\)/,      "var decl" ],
            [ 0, 1, qr/char\s*\*\s*CLASS/,              "no char* var decl" ],
            [ 0, 0, qr/\Qnew X::Y(i)/,                  "autocall" ],
        ],

        [
            #  ... but not multiple times
            "C++: new dup override CLASS type",
            [
                'int',
                'X::Y::new(int i)',
                '    int CLASS',
                '    long CLASS',
            ],
            [ 1, 0, qr/\QError: duplicate definition of parameter 'CLASS'/,
                    "dup err" ],
        ],

        [
            #  don't allow CLASS in sig, with type
            "C++: new sig CLASS type",
            [
                'int',
                'X::Y::new(int CLASS)',
            ],
            [ 1, 0, qr/\QError: duplicate definition of parameter 'CLASS'/,
                    "dup err" ],
        ],

        [
            #  don't allow CLASS in sig, without type
            "C++: new sig CLASS no type",
            [
                'int',
                'X::Y::new(CLASS)',
            ],
            [ 1, 0, qr/\QError: duplicate definition of parameter 'CLASS'/,
                    "dup err" ],
        ],

        [
            "C++: DESTROY",
            [
                'void',
                'X::Y::DESTROY()',
            ],
            [ 0, 0, qr/usage\(cv,\s+"THIS"\)/,               "usage"    ],
            [ 0, 0, qr/X__Y\s*\*\s*THIS\s*=\s*my_in/,        "var decl" ],
            [ 0, 0, qr/delete\s+THIS;/,                      "autocall" ],
        ]
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test return type declarations

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
EOF

    my @test_fns = (
        [
            "NO_OUTPUT",
            [ Q(<<'EOF') ],
                |NO_OUTPUT int
                |foo()
EOF
            [ 0, 0, qr/\QRETVAL = foo();/, "has autocall"     ],
            [ 0, 1, qr/\bTARG/,            "no setting TARG"  ],
            [ 0, 1, qr/\QST(0)/,           "no setting ST(0)" ],
        ],
        [
            "xsub decl on one line",
            [ Q(<<'EOF') ],
                | int foo(A, int  B )
                |    char *A
EOF
            [ 0, 0, qr/^\s+char \*\s+A\s+=/m,  "has A decl"    ],
            [ 0, 0, qr/^\s+int\s+B\s+=/m,      "has B decl"    ],
            [ 0, 0, qr/\QRETVAL = foo(A, B);/, "has autocall"  ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test XSUB declarations declarations
    # Generates errors which don't result in an XSUB being emitted,
    # so use 'undef' in the test_many() call to not strip down output

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
EOF

    my @test_fns = (
        [
            "extern C",
            [ Q(<<'EOF') ],
                |extern "C"   int
                |foo()
EOF
            [ 0, 0, qr/^extern "C"\nXS_EUPXS\(XS_Foo_foo\);/m,
                    "has extern decl" ],
        ],
        [
            "defn too short",
            [ Q(<<'EOF') ],
                |int
EOF
            [ 1, 0, qr/Error: function definition too short 'int'/, "got err" ],
        ],
        [
            "defn not parseable 1",
            [ Q(<<'EOF') ],
                |int
                |foo(aaa
                |    CODE:
                |        AAA
EOF
            [ 1, 0, qr/\QError: cannot parse function definition from 'foo(aaa' in\E.*line 6/,
                    "got err" ],
        ],
        [
            "defn not parseable 2",
            [ Q(<<'EOF') ],
                |int
                |fo o(aaa)
EOF
            [ 1, 0, qr/\QError: cannot parse function definition from 'fo o(aaa)' in\E.*line 6/,
                    "got err" ],
        ],

        # note that  issuing this warning is somewhat controversial:
        # see GH 19661. But while we continue to warn, test that we get a
        # warning.
        [
            "dup fn warning",
            [ Q(<<'EOF') ],
                |int
                |foo(aaa)
                |
                |int
                |foo(aaa)
EOF
            [ 1, 0, qr/\QWarning: duplicate function definition 'foo' detected in\E.*line 9/,
                    "got warn" ],
        ],
        [
            "dup fn warning",
            [ Q(<<'EOF') ],
                |#if X
                |int
                |foo(aaa)
                |
                |#else
                |int
                |foo(aaa)
                |#endif
EOF
            [ 1, 1, qr/\QWarning: duplicate function definition/,
                    "no warning" ],
        ],
    );

    test_many($preamble, undef, \@test_fns);
}


{
    # check that suitable "usage: " error strings are generated

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
EOF

    my @test_fns = (
        [
            "general usage",
            [
                'void',
                'foo(a, char *b,  int length(b), int d =  999, ...)',
                '    long a',
            ],
            [ 0, 0, qr/usage\(cv,\s+"a, b, d=  999, ..."\)/,     ""    ],
        ]
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}

{
    # misc checks for length() pseudo-parameter

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
EOF

    my @test_fns = (
        [
            "length() basic",
            [ Q(<<'EOF') ],
                |void
                |foo(char *s, int length(s))
EOF
            [ 0, 0, qr{^\s+STRLEN\s+STRLEN_length_of_s;}m,  "decl STRLEN" ],
            [ 0, 0, qr{^\s+int\s+XSauto_length_of_s;}m,     "decl int"    ],

            [ 0, 0, qr{^ \s+ \Qchar *\E \s+
                        \Qs = (char *)SvPV(ST(0), STRLEN_length_of_s);}xm,
                                                            "decl s"      ],

            [ 0, 0, qr{^\s+\QXSauto_length_of_s = STRLEN_length_of_s}m,
                                                            "assign"     ],

            [ 0, 0, qr{^\s+\Qfoo(s, XSauto_length_of_s);}m, "autocall"   ],
        ],
        [
            "length() default value",
            [ Q(<<'EOF') ],
                |void
                |foo(char *s, length(s) = 0)
EOF
            [ 1, 0, qr{\QError: default value not allowed on length() parameter 's'\E.*line 6},
                   "got expected error" ],
        ],
        [
            "length() no matching var",
            [ Q(<<'EOF') ],
                |void
                |foo(length(s))
EOF
            [ 1, 0, qr{\QError: length() on non-parameter 's'\E.*line 6},
                   "got expected error" ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}

{
    # check that args to an auto-called C function are correct

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
EOF

    my @test_fns = (
        [
            "autocall args normal",
            [
                'void',
                'foo( OUT int  a,   b   , char   *  c , int length(c), OUTLIST int d, IN_OUTLIST int e)',
                '    long &b',
                '    int alien',
            ],
            [ 0, 0, qr/\Qfoo(&a, &b, c, XSauto_length_of_c, &d, &e)/,  ""  ],
        ],
        [
            "autocall args normal",
            [
                'void',
                'foo( OUT int  a,   b   , char   *  c , size_t length(c) )',
                '    long &b',
                '    int alien',
            ],
            [ 0, 0, qr/\Qfoo(&a, &b, c, XSauto_length_of_c)/,     ""    ],
        ],

        [
            "autocall args C_ARGS",
            [
                'void',
                'foo( int  a,   b   , char   *  c  )',
                '    C_ARGS:     a,   b   , bar,  c? c : "boo!"    ',
                '    INPUT:',
                '        long &b',
            ],
            [ 0, 0, qr/\Qfoo(a,   b   , bar,  c? c : "boo!")/,     ""    ],
        ],

        [
            "autocall args empty C_ARGS",
            [ Q(<<'EOF') ],
                |void
                |foo(int  a)
                |    C_ARGS:
EOF
            [ 0, 0, qr/\Qfoo()/,  "" ],
        ],

        [
            # Whether this is sensible or not is another matter.
            # For now, just check that it works as-is.
            "autocall args C_ARGS multi-line",
            [
                'void',
                'foo( int  a,   b   , char   *  c  )',
                '    C_ARGS: a,',
                '        b   , bar,',
                '        c? c : "boo!"',
                '    INPUT:',
                '        long &b',
            ],
            [ 0, 0, qr/\(a,\n        b   , bar,\n\Q        c? c : "boo!")/,
              ""  ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}

{
    # Test OUTLIST etc

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |TYPEMAP: <<EOF
        |mybool        T_MYBOOL
        |
        |OUTPUT
        |T_MYBOOL
        |    ${"$var" eq "RETVAL" ? \"$arg = boolSV($var);" : \"sv_setsv($arg, boolSV($var));"}
        |EOF
EOF

    my @test_fns = (
        [
            "IN OUT",
            [
                'void',
                'foo(IN int A, IN_OUT int B, OUT int C, OUTLIST int D, IN_OUTLIST int E)',
            ],
            [ 0, 0, qr/\Qusage(cv,  "A, B, C, E")/,    "usage"    ],

            [ 0, 0, qr/int\s+A\s*=\s*\(int\)SvIV\s*/,  "A decl"   ],
            [ 0, 0, qr/int\s+B\s*=\s*\(int\)SvIV\s*/,  "B decl"   ],
            [ 0, 0, qr/int\s+C\s*;/,                   "C decl"   ],
            [ 0, 0, qr/int\s+D\s*;/,                   "D decl"   ],
            [ 0, 0, qr/int\s+E\s*=\s*\(int\)SvIV\s*/,  "E decl"   ],

            [ 0, 0, qr/\Qfoo(A, &B, &C, &D, &E)/,      "autocall" ],

            [ 0, 0, qr/sv_setiv.*ST\(1\).*\bB\b/,      "set B"    ],
            [ 0, 0, qr/\QSvSETMAGIC(ST(1))/,           "set magic B" ],
            [ 0, 0, qr/sv_setiv.*ST\(2\).*\bC\b/,      "set C"    ],
            [ 0, 0, qr/\QSvSETMAGIC(ST(2))/,           "set magic C" ],

            [ 0, 1, qr/\bEXTEND\b/,                    "NO extend"       ],

            [ 0, 0, qr/\b\QTARGi((IV)D, 1);\E\s+\QST(0) = TARG;\E\s+\}\s+\Q++SP;/, "set D"    ],
            [ 0, 0, qr/\b\Qsv_setiv(RETVALSV, (IV)E);\E\s+\QST(1) = RETVALSV;\E\s+\}\s+\Q++SP;/, "set E"    ],
        ],

        # Various types of OUTLIST where the param is the only value to
        # be returned. Includes some types which might be optimised.

        [
            "OUTLIST void/bool",
            [
                'void',
                'foo(OUTLIST bool A)',
            ],
            [ 0, 0, qr/\bXSprePUSH;/,                    "XSprePUSH"       ],
            [ 0, 1, qr/\bEXTEND\b/,                      "NO extend"       ],
            [ 0, 0, qr/\b\QRETVALSV = sv_newmortal();/ , "create new mortal" ],
            [ 0, 0, qr/\b\Qsv_setsv(RETVALSV, boolSV(A));/, "set RETVALSV"   ],
            [ 0, 0, qr/\b\QST(0) = RETVALSV;\E\s+\}\s+\Q++SP;/, "store RETVALSV"],
            [ 0, 0, qr/\b\QXSRETURN(1);/,                "XSRETURN(1)"     ],
        ],
        [
            "OUTLIST void/mybool",
            [
                'void',
                'foo(OUTLIST mybool A)',
            ],
            [ 0, 0, qr/\bXSprePUSH;/,                    "XSprePUSH"       ],
            [ 0, 1, qr/\bEXTEND\b/,                      "NO extend"       ],
            [ 0, 0, qr/\b\QRETVALSV = sv_newmortal();/ , "create new mortal" ],
            [ 0, 0, qr/\b\Qsv_setsv(RETVALSV, boolSV(A));/, "set RETVALSV"   ],
            [ 0, 0, qr/\b\QST(0) = RETVALSV;\E\s+\}\s+\Q++SP;/, "store RETVALSV"],
            [ 0, 0, qr/\b\QXSRETURN(1);/,                "XSRETURN(1)"     ],
        ],
        [
            "OUTLIST void/int",
            [
                'void',
                'foo(OUTLIST int A)',
            ],
            [ 0, 0, qr/\bXSprePUSH;/,                    "XSprePUSH"       ],
            [ 0, 1, qr/\bEXTEND\b/,                      "NO extend"       ],
            [ 0, 1, qr/\bsv_newmortal\b;/,               "NO new mortal"   ],
            [ 0, 0, qr/\bdXSTARG;/,                      "dXSTARG"         ],
            [ 0, 0, qr/\b\QTARGi((IV)A, 1);/,            "set TARG"        ],
            [ 0, 0, qr/\b\QST(0) = TARG;\E\s+\}\s+\Q++SP;/, "store TARG"   ],
            [ 0, 0, qr/\b\QXSRETURN(1);/,                "XSRETURN(1)"     ],
        ],
        [
            "OUTLIST void/char*",
            [
                'void',
                'foo(OUTLIST char* A)',
            ],
            [ 0, 0, qr/\bXSprePUSH;/,                    "XSprePUSH"       ],
            [ 0, 1, qr/\bEXTEND\b/,                      "NO extend"       ],
            [ 0, 1, qr/\bsv_newmortal\b;/,               "NO new mortal"   ],
            [ 0, 0, qr/\bdXSTARG;/,                      "dXSTARG"         ],
            [ 0, 0, qr/\b\Qsv_setpv((SV*)TARG, A);/,     "set TARG"        ],
            [ 0, 0, qr/\b\QST(0) = TARG;\E\s+\}\s+\Q++SP;/, "store TARG"   ],
            [ 0, 0, qr/\b\QXSRETURN(1);/,                "XSRETURN(1)"     ],
        ],

        # Various types of OUTLIST where the param is the second value to
        # be returned. Includes some types which might be optimised.

        [
            "OUTLIST int/bool",
            [
                'int',
                'foo(OUTLIST bool A)',
            ],
            [ 0, 0, qr/\bXSprePUSH;/,                    "XSprePUSH"       ],
            [ 0, 0, qr/\b\QEXTEND(SP,2);/,               "extend 2"        ],
            [ 0, 0, qr/\b\QTARGi((IV)RETVAL, 1);/,       "TARGi RETVAL"    ],
            [ 0, 0, qr/\b\QST(0) = TARG;\E\s+\Q++SP;/,   "store RETVAL,SP++" ],
            [ 0, 0, qr/\b\QRETVALSV = sv_newmortal();/ , "create new mortal" ],
            [ 0, 0, qr/\b\Qsv_setsv(RETVALSV, boolSV(A));/, "set RETVALSV"   ],
            [ 0, 0, qr/\b\QST(1) = RETVALSV;\E\s+\}\s+\Q++SP;/, "store RETVALSV"],
            [ 0, 0, qr/\b\QXSRETURN(2);/,                "XSRETURN(2)"     ],
        ],
        [
            "OUTLIST int/mybool",
            [
                'int',
                'foo(OUTLIST mybool A)',
            ],
            [ 0, 0, qr/\bXSprePUSH;/,                    "XSprePUSH"       ],
            [ 0, 0, qr/\b\QEXTEND(SP,2);/,               "extend 2"        ],
            [ 0, 0, qr/\b\QTARGi((IV)RETVAL, 1);/,       "TARGi RETVAL"    ],
            [ 0, 0, qr/\b\QST(0) = TARG;\E\s+\Q++SP;/,   "store RETVAL,SP++" ],
            [ 0, 0, qr/\b\QRETVALSV = sv_newmortal();/ , "create new mortal" ],
            [ 0, 0, qr/\b\Qsv_setsv(RETVALSV, boolSV(A));/, "set RETVALSV"   ],
            [ 0, 0, qr/\b\QST(1) = RETVALSV;\E\s+\}\s+\Q++SP;/, "store RETVALSV"],
            [ 0, 0, qr/\b\QXSRETURN(2);/,                "XSRETURN(2)"     ],
        ],
        [
            "OUTLIST int/int",
            [
                'int',
                'foo(OUTLIST int A)',
            ],
            [ 0, 0, qr/\bXSprePUSH;/,                    "XSprePUSH"       ],
            [ 0, 0, qr/\b\QEXTEND(SP,2);/,               "extend 2"        ],
            [ 0, 0, qr/\b\QTARGi((IV)RETVAL, 1);/,       "TARGi RETVAL"    ],
            [ 0, 0, qr/\b\QST(0) = TARG;\E\s+\Q++SP;/,   "store RETVAL,SP++" ],
            [ 0, 0, qr/\b\QRETVALSV = sv_newmortal();/ , "create new mortal" ],
            [ 0, 0, qr/\b\Qsv_setiv(RETVALSV, (IV)A);/,  "set RETVALSV"   ],
            [ 0, 0, qr/\b\QST(1) = RETVALSV;\E\s+\}\s+\Q++SP;/, "store RETVALSV"],
            [ 0, 0, qr/\b\QXSRETURN(2);/,                "XSRETURN(2)"     ],
        ],
        [
            "OUTLIST int/char*",
            [
                'int',
                'foo(OUTLIST char* A)',
            ],
            [ 0, 0, qr/\bXSprePUSH;/,                    "XSprePUSH"       ],
            [ 0, 0, qr/\b\QEXTEND(SP,2);/,               "extend 2"        ],
            [ 0, 0, qr/\b\QTARGi((IV)RETVAL, 1);/,       "TARGi RETVAL"    ],
            [ 0, 0, qr/\b\QST(0) = TARG;\E\s+\Q++SP;/,   "store RETVAL,SP++" ],
            [ 0, 0, qr/\b\QRETVALSV = sv_newmortal();/ , "create new mortal" ],
            [ 0, 0, qr/\b\Qsv_setpv((SV*)RETVALSV, A);/, "set RETVALSV"   ],
            [ 0, 0, qr/\b\QST(1) = RETVALSV;\E\s+\}\s+\Q++SP;/, "store RETVALSV"],
            [ 0, 0, qr/\b\QXSRETURN(2);/,                "XSRETURN(2)"     ],
        ],
        [
            "OUTLIST int/opt int",
            [
                'int',
                'foo(IN_OUTLIST int A = 0)',
            ],
            [ 0, 0, qr/\bXSprePUSH;/,                    "XSprePUSH"       ],
            [ 0, 0, qr/\b\QEXTEND(SP,2);/,               "extend 2"        ],
            [ 0, 0, qr/\b\QTARGi((IV)RETVAL, 1);/,       "TARGi RETVAL"    ],
            [ 0, 0, qr/\b\QST(0) = TARG;\E\s+\Q++SP;/,   "store RETVAL,SP++" ],
            [ 0, 0, qr/\b\QRETVALSV = sv_newmortal();/ , "create new mortal" ],
            [ 0, 0, qr/\b\Qsv_setiv(RETVALSV, (IV)A);/,  "set RETVALSV"   ],
            [ 0, 0, qr/\b\QST(1) = RETVALSV;\E\s+\}\s+\Q++SP;/, "store RETVALSV"],
            [ 0, 0, qr/\b\QXSRETURN(2);/,                "XSRETURN(2)"     ],
        ],
        [
            "OUTLIST with OUTPUT override",
            [ Q(<<'EOF') ],
                |void
                |foo(IN_OUTLIST int A)
                |    OUTPUT:
                |        A    setA(ST[99], A);
EOF
            [ 0, 1, qr/\bEXTEND\b/,                      "NO extend"       ],
            [ 0, 0, qr/\b\QsetA(ST[99], A);/,            "set ST[99]"      ],
            [ 0, 0, qr/\b\QTARGi((IV)A, 1);/,            "set ST[0]"       ],
            [ 0, 0, qr/\b\QXSRETURN(1);/,                "XSRETURN(1)"     ],
        ],
        [
            "OUTLIST with multiple CASES",
            [ Q(<<'EOF') ],
                 |void
                 |foo(OUTLIST int a, OUTLIST int b)
                 |    CASE: A
                 |        CODE:
                 |            AAA
                 |    CASE: B
                 |        CODE:
                 |            BBB
EOF
            [ 0, 0, qr{\bdXSTARG; .* \bdXSTARG;}xs,       "two dXSTARG"    ],
            [ 0, 0, qr{   \b\QEXTEND(SP,2);\E
                       .* \b\QEXTEND(SP,2);\E }xs,        "two EXTEND(2)"  ],
            [ 0, 0, qr{\b\QST(0) = \E .* \b\QST(0) = }xs, "two ST(0)"      ],
            [ 0, 0, qr{\b\QST(1) = \E .* \b\QST(1) = }xs, "two ST(1)"      ],
            [ 0, 0, qr/\b\QXSRETURN(2);/,                 "XSRETURN(2)"    ],
            [ 0, 1, qr{XSRETURN.*XSRETURN}xs,             "<2 XSRETURNs"   ],
        ],
        [
            "OUTLIST with multiple CASES and void hack",
            [ Q(<<'EOF') ],
                 |void
                 |foo(OUTLIST int a, OUTLIST int b)
                 |    CASE: A
                 |        CODE:
                 |            ST(0) = 1;
                 |    CASE: B
                 |        CODE:
                 |            ST(0) = 2;
EOF
            [ 0, 0, qr{\bdXSTARG; .* \bdXSTARG;}xs,       "two dXSTARG"    ],
            [ 0, 0, qr{   \b\QEXTEND(SP,3);\E
                       .* \b\QEXTEND(SP,3);\E }xs,        "two EXTEND(3)"  ],
            [ 0, 0, qr{\b\QST(0) = 1\E .* \QST(0) = 2}xs, "two ST(0)"      ],
            [ 0, 0, qr{   \b\QST(1) = TARG\E
                       .* \b\QST(1) = TARG}xs,            "two ST(1)"      ],
            [ 0, 0, qr{   \b\QST(2) = RETVAL\E
                       .* \b\QST(2) = RETVAL}xs,          "two ST(2)"      ],
            [ 0, 0, qr/\b\QXSRETURN(3);/,                 "XSRETURN(3)"    ],
            [ 0, 1, qr{XSRETURN.*XSRETURN}xs,             "<2 XSRETURNs"   ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}

{
    # Test OUTLIST on 'assign' format typemaps.
    #
    # Test code for returning the value of OUTLIST vars for typemaps of
    # the form
    #
    #   $arg = $val;
    # or
    #   $arg = newFoo($arg);
    #
    # Includes whether RETVALSV ha been optimised away.
    #
    # Some of the typemaps don't expand to the 'assign' form yet for
    # OUTLIST vars; we test those too.

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |TYPEMAP: <<EOF
        |
        |svref_fix   T_SVREF_REFCOUNT_FIXED
        |mysvref_fix T_MYSVREF_REFCOUNT_FIXED
        |mybool      T_MYBOOL
        |
        |OUTPUT
        |T_SV
        |    $arg = $var;
        |
        |T_MYSVREF_REFCOUNT_FIXED
        |    $arg = newRV_noinc((SV*)$var);
        |
        |T_MYBOOL
        |    $arg = boolSV($var);
        |
        |EOF
EOF

    my @test_fns = (
        [
            # This uses 'SV*' (handled specially by EU::PXS) but with the
            # output code overridden to use the direct $arg = $var assign,
            # which is normally only used for RETVAL return
            "OUTLIST T_SV",
            [
                'int',
                'foo(OUTLIST SV * A)',
            ],
            [ 0, 1, qr/\bRETVALSV\b/,                        "NO RETVALSV"    ],
            [ 0, 0, qr/\b\QA = sv_2mortal(A);/,              "mortalise A"    ],
            [ 0, 0, qr/\b\QST(1) = A;/,                      "store A"        ],
        ],

        [
            "OUTLIST T_SVREF",
            [
                'int',
                'foo(OUTLIST SVREF A)',
            ],
            [ 0, 0, qr/SV\s*\*\s*RETVALSV;/,                 "RETVALSV"       ],
            [ 0, 0, qr/\b\QRETVALSV = newRV((SV*)A)/,        "newREF(A)"      ],
            [ 0, 0, qr/\b\QRETVALSV = sv_2mortal(RETVALSV);/,"mortalise RSV"  ],
            [ 0, 0, qr/\b\QST(1) = RETVALSV;/,               "store RETVALSV" ],
        ],

        [
            # this one doesn't use assign for OUTLIST
            "OUTLIST T_SVREF_REFCOUNT_FIXED",
            [
                'int',
                'foo(OUTLIST svref_fix A)',
            ],
            [ 0, 0, qr/SV\s*\*\s*RETVALSV;/,                 "RETVALSV"       ],
            [ 0, 0, qr/\b\QRETVALSV = sv_newmortal();/ ,     "new mortal"     ],
            [ 0, 0, qr/\b\Qsv_setrv_noinc(RETVALSV, (SV*)A);/,"setrv()"       ],
            [ 0, 0, qr/\b\QST(1) = RETVALSV;/,               "store RETVALSV" ],
        ],
        [
            # while this one uses assign
            "OUTLIST T_MYSVREF_REFCOUNT_FIXED",
            [
                'int',
                'foo(OUTLIST mysvref_fix A)',
            ],
            [ 0, 0, qr/SV\s*\*\s*RETVALSV;/,                 "RETVALSV"       ],
            [ 0, 0, qr/\b\QRETVALSV = newRV_noinc((SV*)A)/,  "newRV(A)"       ],
            [ 0, 0, qr/\b\QRETVALSV = sv_2mortal(RETVALSV);/,"mortalise RSV"  ],
            [ 0, 0, qr/\b\QST(1) = RETVALSV;/,               "store RETVALSV" ],
        ],

        [
            # this one doesn't use assign for OUTLIST
            "OUTLIST T_BOOL",
            [
                'int',
                'foo(OUTLIST bool A)',
            ],
            [ 0, 0, qr/SV\s*\*\s*RETVALSV;/,                 "RETVALSV"       ],
            [ 0, 0, qr/\b\QRETVALSV = sv_newmortal();/ ,     "new mortal"     ],
            [ 0, 0, qr/\b\Qsv_setsv(RETVALSV, boolSV(A));/,  "setsv(boolSV())"],
            [ 0, 0, qr/\b\QST(1) = RETVALSV;/,               "store RETVALSV" ],
        ],
        [
            # while this one uses assign
            "OUTLIST T_MYBOOL",
            [
                'int',
                'foo(OUTLIST mybool A)',
            ],
            [ 0, 1, qr/\bRETVALSV\b/,                        "NO RETVALSV"    ],
            [ 0, 0, qr/\b\QST(1) = boolSV(A)/,               "store boolSV(A)"],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}

{
    # Test prototypes

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: ENABLE
        |
        |TYPEMAP: <<EOF
        |X::Y *        T_OBJECT
        |const X::Y *  T_OBJECT \&
        |
        |P::Q *        T_OBJECT @
        |const P::Q *  T_OBJECT %
        |
        |foo_t         T_IV @
        |bar_t         T_IV %
        |
        |INPUT
        |T_OBJECT
        |    $var = my_in($arg);
        |
        |OUTPUT
        |T_OBJECT
        |    my_out($arg, $var)
        |EOF
EOF

    my @test_fns = (
        [
            "auto-generated proto basic",
            [
                'void',
                'foo(int a, int b, int c)',
            ],
            [ 0, 0, qr/"\$\$\$"/, "" ],
        ],

        [
            "auto-generated proto basic with default",
            [
                'void',
                'foo(int a, int b, int c = 0)',
            ],
            [ 0, 0, qr/"\$\$;\$"/, "" ],
        ],

        [
            "auto-generated proto complex",
            [
                'void',
                'foo(char *A, int length(A), int B, OUTLIST int C, int D)',
            ],
            [ 0, 0, qr/"\$\$\$"/, "" ],
        ],

        [
            "auto-generated proto  complex with default",
            [
                'void',
                'foo(char *A, int length(A), int B, IN_OUTLIST int C, int D = 0)',
            ],
            [ 0, 0, qr/"\$\$\$;\$"/, "" ],
        ],

        [
            "auto-generated proto with ellipsis",
            [
                'void',
                'foo(char *A, int length(A), int B, OUT int C, int D, ...)',
            ],
            [ 0, 0, qr/"\$\$\$\$;\@"/, "" ],
        ],

        [
            "auto-generated proto with default and ellipsis",
            [
                'void',
                'foo(char *A, int length(A), int B, IN_OUT int C, int D = 0, ...)',
            ],
            [ 0, 0, qr/"\$\$\$;\$\@"/, "" ],
        ],

        [
            "auto-generated proto with default and ellipsis and THIS",
            [
                'void',
                'X::Y::foo(char *A, int length(A), int B, IN_OUT int C, int D = 0, ...)',
            ],
            [ 0, 0, qr/"\$\$\$\$;\$\@"/, "" ],
        ],

        [
            "auto-generated proto with overridden THIS type",
            [
                'void',
                'P::Q::foo()',
                '    const P::Q * THIS'
            ],
            [ 0, 0, qr/"%"/, "" ],
        ],

        [
            "explicit prototype",
            [
                'void',
                'foo(int a, int b, int c = 0)',
                '    PROTOTYPE: $@%;$'
            ],
            [ 0, 0, qr/"\$\@%;\$"/, "" ],
        ],

        [
            "explicit prototype with whitespace",
            [ Q(<<'EOF') ],
                |void
                |foo(int a, int b, int c)
                |    PROTOTYPE:     $   $    @   
EOF
            [ 0, 0, qr/"\$\$\@"/, "" ],
        ],

        [
            "explicit prototype with backslash etc",
            [
                'void',
                'foo(int a, int b, int c = 0)',
                '    PROTOTYPE: \$\[@%]'
            ],
            # Note that the emitted C code will have escaped backslashes,
            # so the actual C code looks something like:
            #    newXS_some_variant(..., "\\$\\[@%]");
            # and so the regex below has to escape each backslash and
            # meta char its trying to match:
            [ 0, 0, qr/" \\  \\  \$  \\  \\ \[  \@  \%  \] "/x, "" ],
        ],

        [
            # XXX The parsing code for the PROTOTYPE keyword treats the
            # keyword as multi-line and uses the last seen value.
            # Almost certainly a coding error, but preserve the behaviour
            # for now.
            "explicit multiline prototype",
            [ Q(<<'EOF') ],
                |void
                |foo(int a, int b, int c)
                |    PROTOTYPE:
                |           
                |       DISABLE
                |
                |       %%%%%%
                |
                |       $$@
                |
                |    C_ARGS: x,y,z
EOF
            [ 0, 0, qr/"\$\$\@"/, "" ],
        ],


        [
            "explicit empty prototype",
            [
                'void',
                'foo(int a, int b, int c = 0)',
                '    PROTOTYPE:'
            ],
            [ 0, 0, qr/newXS.*, ""/, "" ],
        ],

        [
            "explicit ENABLE prototype",
            [ Q(<<'EOF') ],
                |void
                |foo(int a, int b, int c)
                |    PROTOTYPE: ENABLE
EOF
            [ 0, 0, qr/"\$\$\$"/, "" ],
        ],

        [
            "explicit DISABLE prototype",
            [ Q(<<'EOF') ],
                |void
                |foo(int a, int b, int c)
                |    PROTOTYPE: DISABLE
EOF
            [ 0, 1, qr/"\$\$\$"/, "" ],
        ],

        [
            "multiple prototype",
            [ Q(<<'EOF') ],
                |void
                |foo(int a, int b, int c)
                |    PROTOTYPE: $$$
                |    PROTOTYPE: $$$
EOF
            [ 1, 0, qr/Error: only one PROTOTYPE definition allowed per xsub/, "" ],
        ],

        [
            "explicit invalid prototype",
            [ Q(<<'EOF') ],
                |void
                |foo(int a, int b, int c)
                |    PROTOTYPE: ab
EOF
            [ 1, 0, qr/Error: invalid prototype 'ab'/, "" ],
        ],

        [
            "not overridden by typemap",
            [
                'void',
                'foo(X::Y * a, int b, int c = 0)',
            ],
            [ 0, 0, qr/"\$\$;\$"/, "" ],
        ],

        [
            "overridden by typemap",
            [
                'void',
                'foo(const X::Y * a, int b, int c = 0)',
            ],
            [ 0, 0, qr/" \\ \\ \& \$ ; \$ "/x, "" ],
        ],

        [
            # shady but legal - placeholder
            "auto-generated proto with no type",
            [
                'void',
                'foo(a, b, c = 0)',
            ],
            [ 0, 0, qr/"\$\$;\$"/, ""  ],
        ],

        [
            "auto-generated proto with backcompat SV* placeholder",
            [
                'void',
                'foo(int a, SV*, char *c = "")',
                'C_ARGS: a, c',
            ],
            [ 0, 0, qr/"\$\$;\$"/, ""  ],
        ],
        [
            "CASE with variant prototype char",
            [ Q(<<'EOF') ],
                |void
                |foo(abc)
                |    CASE: X
                |       foo_t abc
                |    CASE: Y
                |       int   abc
                |    CASE: Z
                |       bar_t abc
EOF
            [ 0, 0, qr/newXS.*"%"/, "has %" ],
            [ 1, 0, qr/Warning: prototype for 'abc' varies: '\@' versus '\$' .*line 28/,
                    "got 'varies' warning 1" ],
            [ 1, 0, qr/Warning: prototype for 'abc' varies: '\$' versus '%' .*line 30/,
                    "got 'varies' warning 2" ],
        ],
    );

    test_many($preamble, 'boot_Foo', \@test_fns);
}

{
    # Test RETVAL with the dXSTARG optimisation. When the return type
    # corresponds to a simple sv_setXv($arg, $val) in the typemap,
    # use the OP_ENTERSUB's TARG if possible, rather than creating a new
    # mortal each time.

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
        |TYPEMAP: <<EOF
        |const int     T_IV
        |const long    T_MYIV
        |const short   T_MYSHORT
        |undef_t       T_MYUNDEF
        |ivmg_t        T_MYIVMG
        |
        |INPUT
        |T_MYIV
        |    $var = ($type)SvIV($arg)
        |
        |OUTPUT
        |T_OBJECT
        |    sv_setiv($arg, (IV)$var);
        |
        |T_MYSHORT
        |    ${ "$var" eq "RETVAL" ? \"$arg = $var;" : \"sv_setiv($arg, $var);" }
        |
        |T_MYUNDEF
        |    sv_set_undef($arg);
        |
        |T_MYIVMG
        |    sv_setiv_mg($arg, (IV)RETVAL);
        |EOF
EOF

    my @test_fns = (
        [
            "dXSTARG int (IV)",
            [
                'int',
                'foo()',
            ],
            [ 0, 0, qr/\bdXSTARG;/,   "has targ def" ],
            [ 0, 0, qr/\bTARGi\b/,    "has TARGi" ],
            [ 0, 1, qr/sv_newmortal/, "doesn't have newmortal" ],
        ],

        [
            # same as int, but via custom typemap entry
            "dXSTARG const int (IV)",
            [
                'const int',
                'foo()',
            ],
            [ 0, 0, qr/\bdXSTARG;/,   "has targ def" ],
            [ 0, 0, qr/\bTARGi\b/,    "has TARGi" ],
            [ 0, 1, qr/sv_newmortal/, "doesn't have newmortal" ],
        ],

        [
            # same as int, but via custom typemap OUTPUT entry
            "dXSTARG const long (MYIV)",
            [
                'const int',
                'foo()',
            ],
            [ 0, 0, qr/\bdXSTARG;/,   "has targ def" ],
            [ 0, 0, qr/\bTARGi\b/,    "has TARGi" ],
            [ 0, 1, qr/sv_newmortal/, "doesn't have newmortal" ],
        ],

        [
            "dXSTARG unsigned long (UV)",
            [
                'unsigned long',
                'foo()',
            ],
            [ 0, 0, qr/\bdXSTARG;/,   "has targ def" ],
            [ 0, 0, qr/\bTARGu\b/,    "has TARGu" ],
            [ 0, 1, qr/sv_newmortal/, "doesn't have newmortal" ],
        ],

        [
            "dXSTARG time_t (NV)",
            [
                'time_t',
                'foo()',
            ],
            [ 0, 0, qr/\bdXSTARG;/,   "has targ def" ],
            [ 0, 0, qr/\bTARGn\b/,    "has TARGn" ],
            [ 0, 1, qr/sv_newmortal/, "doesn't have newmortal" ],
        ],

        [
            "dXSTARG char (pvn)",
            [
                'char',
                'foo()',
            ],
            [ 0, 0, qr/\bdXSTARG;/,   "has targ def" ],
            [ 0, 0, qr/\bsv_setpvn\b/,"has sv_setpvn()" ],
            [ 0, 1, qr/sv_newmortal/, "doesn't have newmortal" ],
        ],

        [
            "dXSTARG char * (PV)",
            [
                'char *',
                'foo()',
            ],
            [ 0, 0, qr/\bdXSTARG;/,   "has targ def" ],
            [ 0, 0, qr/\bsv_setpv\b/, "has sv_setpv" ],
            [ 0, 0, qr/\QST(0) = TARG;/, "has ST(0) = TARG" ],
            [ 0, 1, qr/sv_newmortal/, "doesn't have newmortal" ],
        ],

        [
            "dXSTARG int (IV) with outlist",
            [
                'int',
                'foo(OUTLIST int a, OUTLIST int b)',
            ],
            [ 0, 0, qr/\bdXSTARG;/,      "has targ def" ],
            [ 0, 0, qr/\bXSprePUSH;/,    "has XSprePUSH" ],
            [ 0, 1, qr/\bXSprePUSH\b.+\bXSprePUSH\b/s,
                                         "has only one XSprePUSH" ],

            [ 0, 0, qr/\bTARGi\b/,       "has TARGi" ],
            [ 0, 0, qr/\bsv_setiv\(RETVALSV.*sv_setiv\(RETVALSV/s,
                                         "has two setiv(RETVALSV,...)" ],

            [ 0, 0, qr/\bXSRETURN\(3\)/, "has XSRETURN(3)" ],
        ],

        # Test RETVAL with an overridden typemap template in OUTPUT
        [
            "RETVAL overridden typemap: non-TARGable",
            [
                'int',
                'foo()',
                '    OUTPUT:',
                '        RETVAL my_sv_setiv(ST(0), RETVAL);',
            ],
            [ 0, 0, qr/\bmy_sv_setiv\b/,   "has my_sv_setiv" ],
        ],

        [
            "RETVAL overridden typemap: TARGable",
            [
                'int',
                'foo()',
                '    OUTPUT:',
                '        RETVAL sv_setiv(ST(0), RETVAL);',
            ],
            # XXX currently the TARG optimisation isn't done
            # XXX when this is fixed, update the test
            [ 0, 0, qr/\bsv_setiv\b/,   "has sv_setiv" ],
        ],

        [
            "dXSTARG with variant typemap",
            [
                'void',
                'foo(OUTLIST const short a)',
            ],
            [ 0, 0, qr/\bdXSTARG;/,      "has targ def" ],
            [ 0, 0, qr/\bTARGi\b/,       "has TARGi" ],
            [ 0, 1, qr/\bsv_setiv\(/,    "has NO sv_setiv" ],
            [ 0, 0, qr/\bXSRETURN\(1\)/, "has XSRETURN(1)" ],
        ],

        [
            "dXSTARG with sv_set_undef",
            [
                'void',
                'foo(OUTLIST undef_t a)',
            ],
            [ 0, 0, qr/\bdXSTARG;/,          "has targ def" ],
            [ 0, 0, qr/\bsv_set_undef\(/,    "has sv_set_undef" ],
        ],

        [
            "dXSTARG with sv_setiv_mg",
            [
                'ivmg_t',
                'foo()',
            ],
            [ 0, 0, qr/\bdXSTARG;/,          "has targ def" ],
            [ 0, 0, qr/\bTARGi\(/,           "has TARGi" ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}

{
    # Test INPUT: keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "INPUT bad line",
            [ Q(<<'EOF') ],
                |int
                |foo(abc)
                |    int +
EOF
            [ 1, 0, qr/^\QError: invalid parameter declaration '    int +'\E.* line 7\n/,   "got expected error" ],
        ],
        [
            "INPUT no length()",
            [ Q(<<'EOF') ],
                |int
                |foo(abc)
                |    int length(abc)
EOF
            [ 1, 0, qr/^\QError: length() not permitted in INPUT section\E.* line 7\n/,   "got expected error" ],
        ],
        [
            "INPUT dup",
            [ Q(<<'EOF') ],
                |int
                |foo(abc, int def)
                |    int abc
                |    int abc
                |    int def
EOF
            [ 1, 0, qr/^\QError: duplicate definition of parameter 'abc' ignored in\E.* line 8\n/m,
                                        "abc: got expected error" ],

            [ 1, 0, qr/^\QError: duplicate definition of parameter 'def' ignored in\E.* line 9\n/m,
                                        "def: got expected error" ],
        ],

    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test OUTPUT: keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
        |TYPEMAP: <<EOF
        |blah T_BLAH
        |EOF
        |
EOF

    my @test_fns = (
        [
            "OUTPUT RETVAL",
            [ Q(<<'EOF') ],
                |int
                |foo(int a)
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      RETVAL
EOF
            [ 0, 1, qr/\bSvSETMAGIC\b/,   "no set magic" ],
            [ 0, 0, qr/\bTARGi\b/,        "has TARGi" ],
            [ 0, 0, qr/\QXSRETURN(1)/,    "has XSRETURN" ],
        ],

        [
            "OUTPUT RETVAL with set magic ignored",
            [ Q(<<'EOF') ],
                |int
                |foo(int a)
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      SETMAGIC: ENABLE
                |      RETVAL
EOF
            [ 0, 1, qr/\bSvSETMAGIC\b/,   "no set magic" ],
            [ 0, 0, qr/\bTARGi\b/,        "has TARGi" ],
            [ 0, 0, qr/\QXSRETURN(1)/,    "has XSRETURN" ],
        ],

        [
            "OUTPUT RETVAL with code",
            [ Q(<<'EOF') ],
                |int
                |foo(int a)
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      RETVAL PUSHs(my_newsviv(RETVAL));
EOF
            [ 0, 0, qr/\QPUSHs(my_newsviv(RETVAL));/,   "uses code" ],
            [ 0, 0, qr/\QXSRETURN(1)/,                  "has XSRETURN" ],
        ],

        [
            "OUTPUT RETVAL with code and template-like syntax",
            [ Q(<<'EOF') ],
                |int
                |foo(int a)
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      RETVAL baz($arg,$val);
EOF
            # Check that the override code is *not* template-expanded.
            # This was probably originally an implementation error, but
            # keep that behaviour for now for backwards compatibility.
            [ 0, 0, qr'baz\(\$arg,\$val\);',            "vars not expanded" ],
        ],

        [
            "OUTPUT RETVAL with code on IN_OUTLIST param",
            [ Q(<<'EOF') ],
                |int
                |foo(IN_OUTLIST int abc)
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      RETVAL
                |      abc  my_set(ST[0], RETVAL);
EOF
            [ 0, 0, qr/\Qmy_set(ST[0], RETVAL)/,      "code used for st(0)" ],
            [ 0, 0, qr/\bXSprePUSH;/,                 "XSprePUSH" ],
            [ 0, 1, qr/\bEXTEND\b/,                   "NO extend"       ],
            [ 0, 0, qr/\QTARGi((IV)RETVAL, 1);/,      "push RETVAL" ],
            [ 0, 0, qr/\QRETVALSV = sv_newmortal();/, "create mortal" ],
            [ 0, 0, qr/\Qsv_setiv(RETVALSV, (IV)abc);/, "code not used for st(1)" ],
            [ 0, 0, qr/\QXSRETURN(2)/,                "has XSRETURN" ],
        ],

        [
            "OUTPUT RETVAL with code and unknown type",
            [ Q(<<'EOF') ],
                |blah
                |foo(int a)
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      RETVAL PUSHs(my_newsviv(RETVAL));
EOF
            [ 0, 0, qr/blah\s+RETVAL;/,                 "decl" ],
            [ 0, 0, qr/\QPUSHs(my_newsviv(RETVAL));/,   "uses code" ],
            [ 0, 0, qr/\QXSRETURN(1)/,                  "has XSRETURN" ],
        ],

        [
            "OUTPUT vars with set magic mixture",
            [ Q(<<'EOF') ],
                |int
                |foo(int aaa, int bbb, int ccc, int ddd)
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      RETVAL
                |      aaa
                |      SETMAGIC: ENABLE
                |      bbb
                |      SETMAGIC: DISABLE
                |      ccc
                |      SETMAGIC: ENABLE
                |      ddd  my_set(xyz)
EOF
            [ 0, 0, qr/\b\QSvSETMAGIC(ST(0))/,       "set magic ST(0)" ],
            [ 0, 0, qr/\b\QSvSETMAGIC(ST(1))/,       "set magic ST(1)" ],
            [ 0, 1, qr/\b\QSvSETMAGIC(ST(2))/,       "no set magic ST(2)" ],
            [ 0, 0, qr/\b\QSvSETMAGIC(ST(3))/,       "set magic ST(3)" ],
            [ 0, 0, qr/\b\Qsv_setiv(ST(0),\E.*aaa/,  "setiv(aaa)" ],
            [ 0, 0, qr/\b\Qsv_setiv(ST(1),\E.*bbb/,  "setiv(bbb)" ],
            [ 0, 0, qr/\b\Qsv_setiv(ST(2),\E.*ccc/,  "setiv(ccc)" ],
            [ 0, 1, qr/\b\Qsv_setiv(ST(3)/,          "no setiv(ddd)" ],
            [ 0, 0, qr/\b\Qmy_set(xyz)/,             "myset" ],
            [ 0, 0, qr/\bTARGi\b.*RETVAL/,           "has TARGi(RETVAL,1)" ],
            [ 0, 0, qr/\QXSRETURN(1)/,               "has XSRETURN" ],
        ],

        [
            "OUTPUT vars with set magic mixture per-CASE",
            [ Q(<<'EOF') ],
                |int
                |foo(int a, int b)
                |   CASE: X
                |    OUTPUT:
                |        a
                |        SETMAGIC: DISABLE
                |        b
                |   CASE: Y
                |    OUTPUT:
                |        a
                |        SETMAGIC: DISABLE
                |        b
EOF
            [ 0, 0, qr{\Qif (X)\E
                       .*
                       \QSvSETMAGIC(ST(0));\E
                       .*
                       \Qelse if (Y)\E
                       }sx,                          "X: set magic ST(0)" ],
            [ 0, 1, qr{\Qif (X)\E
                       .*
                       \QSvSETMAGIC(ST(1));\E
                       .*
                       \Qelse if (Y)\E
                       }sx,                          "X: no magic ST(1)" ],
            [ 0, 0, qr{\Qelse if (Y)\E
                       .*
                       \QSvSETMAGIC(ST(0));\E
                       }sx,                          "Y: set magic ST(0)" ],
            [ 0, 1, qr{\Qelse if (Y)\E
                       .*
                       \QSvSETMAGIC(ST(1));\E
                       }sx,                          "Y: no magic ST(1)" ],
        ],

        [
            "duplicate OUTPUT RETVAL",
            [ Q(<<'EOF') ],
                |int
                |foo(int aaa)
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      RETVAL
                |      RETVAL
EOF
            [ 1, 0, qr/Error: duplicate OUTPUT parameter 'RETVAL'/, "" ],
        ],

        [
            "duplicate OUTPUT parameter",
            [ Q(<<'EOF') ],
                |int
                |foo(int aaa)
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      RETVAL
                |      aaa
                |      aaa
EOF
            [ 1, 0, qr/Error: duplicate OUTPUT parameter 'aaa'/, "" ],
        ],

        [
            "RETVAL in CODE without OUTPUT section",
            [ Q(<<'EOF') ],
                |int
                |foo()
                |    CODE:
                |      RETVAL = 99
EOF
            [ 1, 0, qr/Warning: found a 'CODE' section which seems to be using 'RETVAL' but no 'OUTPUT' section/, "" ],
        ],

        [
            # This one *shouldn't* warn. For a void XSUB, RETVAL
            # is just another local variable.
            "void RETVAL in CODE without OUTPUT section",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |    PREINIT:
                |      int RETVAL;
                |    CODE:
                |      RETVAL = 99
EOF
            [ 1, 1, qr/Warning: found a 'CODE' section which seems to be using 'RETVAL' but no 'OUTPUT' section/, "no warn" ],
        ],

        [
            "RETVAL in CODE without being in OUTPUT",
            [ Q(<<'EOF') ],
                |int
                |foo(int aaa)
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      aaa
EOF
            [ 1, 0, qr/Warning: found a 'CODE' section which seems to be using 'RETVAL' but no 'OUTPUT' section/, "" ],
        ],

        [
            "RETVAL in CODE without OUTPUT section, multiple CASEs",
            [ Q(<<'EOF') ],
                |int
                |foo()
                |  CASE: X
                |    CODE:
                |      RETVAL = 99
                |    OUTPUT:
                |      RETVAL
                |  CASE: Y
                |    CODE:
                |      RETVAL = 99
EOF
            [ 1, 0, qr/Warning: found a 'CODE' section which seems to be using 'RETVAL' but no 'OUTPUT' section/, "" ],
        ],

        [
            "OUTPUT RETVAL not a parameter",
            [ Q(<<'EOF') ],
                |void
                |foo(int aaa)
                |    CODE:
                |      xyz
                |    OUTPUT:
                |      RETVAL
EOF
            [ 1, 0, qr/\QError: OUTPUT RETVAL not a parameter/, "" ],
        ],

        [
            "OUTPUT RETVAL IS a parameter",
            [ Q(<<'EOF') ],
                |int
                |foo(int aaa)
                |    CODE:
                |      xyz
                |    OUTPUT:
                |      RETVAL
EOF
            [ 1, 1, qr/\QError: OUTPUT RETVAL not a parameter/, "" ],
        ],

        [
            "OUTPUT foo not a parameter",
            [ Q(<<'EOF') ],
                |void
                |foo(int aaa)
                |    CODE:
                |      xyz
                |    OUTPUT:
                |      bbb
EOF
            [ 1, 0, qr/\QError: OUTPUT bbb not a parameter/, "" ],
        ],

        [
            "OUTPUT length(foo) not a parameter",
            [ Q(<<'EOF') ],
                |void
                |foo(char* aaa, int length(aaa))
                |    CODE:
                |      xyz
                |    OUTPUT:
                |      length(aaa)
EOF
            [ 1, 0, qr/\QError: OUTPUT length(aaa) not a parameter/, "" ],
        ],

        [
            "OUTPUT with IN_OUTLIST",
            [ Q(<<'EOF') ],
                |char*
                |foo(IN_OUTLIST int abc)
                |    CODE:
                |        RETVAL=999
                |    OUTPUT:
                |        RETVAL
                |        abc
EOF
            # OUT var - update arg 0 on stack
            [ 0, 0, qr/\b\Qsv_setiv(ST(0),\E.*abc/,  "setiv(ST0, abc)" ],
            [ 0, 0, qr/\b\QSvSETMAGIC(ST(0))/,       "set magic ST(0)" ],
            # prepare stack for OUTLIST
            [ 0, 0, qr/\bXSprePUSH\b/,               "XSprePUSH" ],
            [ 0, 1, qr/\bEXTEND\b/,                  "NO extend"       ],
            # OUTPUT: RETVAL: push return value on stack
            [ 0, 0, qr/\bsv_setpv\(\(SV\*\)TARG,\s*RETVAL\)/,"sv_setpv(TARG, RETVAL)" ],
            [ 0, 0, qr/\QST(0) = TARG;/,             "has ST(0) = TARG" ],
            # OUTLIST: push abc on stack
            [ 0, 0, qr/\QRETVALSV = sv_newmortal();/, "create mortal" ],
            [ 0, 0, qr/\b\Qsv_setiv(RETVALSV, (IV)abc);/,"sv_setiv(RETVALSV, abc)" ],
            [ 0, 0, qr/\b\QST(1) = RETVALSV;\E\s+\}\s+\Q++SP;/, "store RETVALSV"],
            # and return RETVAL and abc
            [ 0, 0, qr/\QXSRETURN(2)/,               "has XSRETURN" ],

            # should only be one SvSETMAGIC
            [ 0, 1, qr/\bSvSETMAGIC\b.*\bSvSETMAGIC\b/s,"only one SvSETMAGIC" ],
        ],

        [
            "OUTPUT with no output typemap entry",
            [ Q(<<'EOF') ],
                |void
                |foo(blah a)
                |    OUTPUT:
                |      a
EOF
            [ 1, 1, qr/\QError: no OUTPUT definition for type 'blah', typekind 'T_BLAH'\E.*line 11/,
                    "got expected error" ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}

{
    # Test RETVAL as a parameter. This isn't well documented as to
    # how it should be interpreted, so these tests are more about checking
    # current behaviour so that inadvertent changes are detected, rather
    # than approving the current behaviour.

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (

        # First, with void return type.
        # Generally in this case, RETVAL is currently not special - it's
        # just another name for a parameter. If it doesn't have a type
        # specified, it's treated as a placeholder.

        [
            # XXX this generates an autocall using undeclared RETVAL,
            # which should be an error
            "void RETVAL no-type param autocall",
            [ Q(<<'EOF') ],
                |void
                |foo(RETVAL, short abc)
EOF
            [ 0, 0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            [ 0, 0, qr/short\s+abc\s*=.*\QST(1)/,        "abc is ST1" ],
            [ 0, 0, qr/\Qfoo(RETVAL, abc)/,              "autocall" ],
            [ 0, 0, qr/\bXSRETURN_EMPTY\b/,              "ret empty" ],
        ],

        [
            "void RETVAL no-type param",
            [ Q(<<'EOF') ],
                |void
                |foo(RETVAL, short abc)
                |    CODE:
                |        xyz
EOF
            [ 0, 0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            [ 0, 0, qr/short\s+abc\s*=.*\QST(1)/,        "abc is ST1" ],
            [ 0, 0, qr/\bXSRETURN_EMPTY\b/,              "ret empty" ],
        ],

        [
            "void RETVAL typed param autocall",
            [ Q(<<'EOF') ],
                |void
                |foo(int RETVAL, short abc)
EOF
            [ 0, 0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            [ 0, 0, qr/\bint\s+RETVAL\s*=.*\QST(0)/,     "declare and init" ],
            [ 0, 0, qr/short\s+abc\s*=.*\QST(1)/,        "abc is ST1" ],
            [ 0, 0, qr/\Qfoo(RETVAL, abc)/,              "autocall" ],
            [ 0, 0, qr/\bXSRETURN_EMPTY\b/,              "ret empty" ],
        ],

        [
            "void RETVAL INPUT typed param autocall",
            [ Q(<<'EOF') ],
                |void
                |foo(RETVAL, short abc)
                |   int RETVAL
EOF
            [ 0, 0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            [ 0, 0, qr/\bint\s+RETVAL\s*=.*\QST(0)/,     "declare and init" ],
            [ 0, 0, qr/short\s+abc\s*=.*\QST(1)/,        "abc is ST1" ],
            [ 0, 0, qr/\Qfoo(RETVAL, abc)/,              "autocall" ],
            [ 0, 0, qr/\bXSRETURN_EMPTY\b/,              "ret empty" ],
        ],

        [
            "void RETVAL typed param",
            [ Q(<<'EOF') ],
                |void
                |foo(int RETVAL, short abc)
                |    CODE:
                |        xyz
EOF
            [ 0, 0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            [ 0, 0, qr/\bint\s+RETVAL\s*=.*\QST(0)/,     "declare and init" ],
            [ 0, 0, qr/short\s+abc\s*=.*\QST(1)/,        "abc is ST1" ],
            [ 0, 0, qr/\bXSRETURN_EMPTY\b/,              "ret empty" ],
        ],

        [
            "void RETVAL INPUT typed param",
            [ Q(<<'EOF') ],
                |void
                |foo(RETVAL, short abc)
                |   int RETVAL
                |    CODE:
                |        xyz
EOF
            [ 0, 0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            [ 0, 0, qr/\bint\s+RETVAL\s*=.*\QST(0)/,     "declare and init" ],
            [ 0, 0, qr/short\s+abc\s*=.*\QST(1)/,        "abc is ST1" ],
            [ 0, 0, qr/\bXSRETURN_EMPTY\b/,              "ret empty" ],
        ],

        [
            "void RETVAL alien autocall",
            [ Q(<<'EOF') ],
                |void
                |foo(short abc)
                |   int RETVAL = 99
EOF
            [ 0, 0, qr/_usage\(cv,\s*"abc"\)/,           "usage" ],
            [ 0, 0, qr/\bint\s+RETVAL\s*=\s*99/,         "declare and init" ],
            [ 0, 0, qr/short\s+abc\s*=.*\QST(0)/,        "abc is ST0" ],
            [ 0, 0, qr/\Qfoo(abc)/,                      "autocall" ],
            [ 0, 0, qr/\bXSRETURN_EMPTY\b/,              "ret empty" ],
        ],

        [
            "void RETVAL alien",
            [ Q(<<'EOF') ],
                |void
                |foo(short abc)
                |   int RETVAL = 99
EOF
            [ 0, 0, qr/_usage\(cv,\s*"abc"\)/,           "usage" ],
            [ 0, 0, qr/\bint\s+RETVAL\s*=\s*99/,         "declare and init" ],
            [ 0, 0, qr/short\s+abc\s*=.*\QST(0)/,        "abc is ST0" ],
            [ 0, 0, qr/\bXSRETURN_EMPTY\b/,              "ret empty" ],
        ],


        # Next, with 'long' return type.
        # Generally, RETVAL is treated as a normal parameter, with
        # some bad behaviour (such as multiple definitions) when that
        # clashes with the implicit use of RETVAL

        [
            "long RETVAL no-type param autocall",
            [ Q(<<'EOF') ],
                |long
                |foo(RETVAL, short abc)
EOF
            [ 0, 0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            # XXX RETVAL is passed uninitialised to the autocall fn
            [ 0, 0, qr/long\s+RETVAL;/,                  "declare no init" ],
            [ 0, 0, qr/short\s+abc\s*=.*\QST(1)/,        "abc is ST1" ],
            [ 0, 0, qr/\Qfoo(RETVAL, abc)/,              "autocall" ],
            [ 0, 0, qr/\b\QXSRETURN(1)/,                 "ret 1" ],
        ],

        [
            "long RETVAL no-type param",
            [ Q(<<'EOF') ],
                |long
                |foo(RETVAL, short abc)
                |    CODE:
                |        xyz
EOF
            [ 0, 0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            [ 0, 0, qr/long\s+RETVAL;/,                  "declare no init" ],
            [ 0, 0, qr/short\s+abc\s*=.*\QST(1)/,        "abc is ST1" ],
            [ 0, 0, qr/\b\QXSRETURN(1)/,                 "ret 1" ],
        ],

        [
            "long RETVAL typed param autocall",
            [ Q(<<'EOF') ],
                |long
                |foo(int RETVAL, short abc)
EOF
            [ 0, 0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            # duplicate or malformed declarations used to be emitted
            [ 0, 1, qr/int\s+RETVAL;/,                   "no none init init" ],
            [ 0, 1, qr/long\s+RETVAL;/,                  "no none init long" ],

            [ 0, 0, qr/\bint\s+RETVAL\s*=.*\QST(0)/,     "int  decl and init" ],
            [ 0, 0, qr/short\s+abc\s*=.*\QST(1)/,        "abc is ST1" ],
            [ 0, 0, qr/\bRETVAL\s*=\s*foo\(RETVAL, abc\)/,"autocall" ],
            [ 0, 0, qr/\b\QTARGi((IV)RETVAL, 1)/,        "TARGi" ],
            [ 0, 0, qr/\b\QXSRETURN(1)/,                 "ret 1" ],
        ],

        [
            "long RETVAL INPUT typed param autocall",
            [ Q(<<'EOF') ],
                |long
                |foo(RETVAL, short abc)
                |   int RETVAL
EOF
            [ 0, 0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            [ 0, 1, qr/long\s+RETVAL/,                   "no long decl" ],
            [ 0, 0, qr/\bint\s+RETVAL\s*=.*\QST(0)/,     "int  decl and init" ],
            [ 0, 0, qr/short\s+abc\s*=.*\QST(1)/,        "abc is ST1" ],
            [ 0, 0, qr/\bRETVAL\s*=\s*foo\(RETVAL, abc\)/,"autocall" ],
            [ 0, 0, qr/\b\QTARGi((IV)RETVAL, 1)/,         "TARGi" ],
            [ 0, 0, qr/\b\QXSRETURN(1)/,                  "ret 1" ],
        ],

        [
            "long RETVAL INPUT typed param autocall 2nd pos",
            [ Q(<<'EOF') ],
                |long
                |foo(short abc, RETVAL)
                |   int RETVAL
EOF
            [ 0, 0, qr/_usage\(cv,\s*"abc,\s*RETVAL"\)/, "usage" ],
            [ 0, 1, qr/long\s+RETVAL/,                   "no long decl" ],
            [ 0, 0, qr/\bint\s+RETVAL\s*=.*\QST(1)/,     "int  decl and init" ],
            [ 0, 0, qr/short\s+abc\s*=.*\QST(0)/,        "abc is ST0" ],
            [ 0, 0, qr/\bRETVAL\s*=\s*foo\(abc, RETVAL\)/,"autocall" ],
            [ 0, 0, qr/\b\QTARGi((IV)RETVAL, 1)/,         "TARGi" ],
            [ 0, 0, qr/\b\QXSRETURN(1)/,                  "ret 1" ],
        ],

        [
            "long RETVAL typed param",
            [ Q(<<'EOF') ],
                |long
                |foo(int RETVAL, short abc)
                |    CODE:
                |        xyz
                |    OUTPUT:
                |        RETVAL
EOF
            [ 0, 0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            # duplicate or malformed declarations used to be emitted
            [ 0, 1, qr/int\s+RETVAL;/,                "no none init init" ],
            [ 0, 1, qr/long\s+RETVAL;/,               "no none init long" ],

            [ 0, 0, qr/\bint\s+RETVAL\s*=.*\QST(0)/,  "int  decl and init" ],
            [ 0, 0, qr/short\s+abc\s*=.*\QST(1)/,     "abc is ST1" ],
            [ 0, 0, qr/\b\QTARGi((IV)RETVAL, 1)/,     "TARGi" ],
            [ 0, 0, qr/\b\QXSRETURN(1)/,              "ret 1" ],
        ],

        [
            "long RETVAL INPUT typed param",
            [ Q(<<'EOF') ],
                |long
                |foo(RETVAL, short abc)
                |    int RETVAL
                |    CODE:
                |        xyz
                |    OUTPUT:
                |        RETVAL
EOF
            [ 0, 0, qr/_usage\(cv,\s*"RETVAL,\s*abc"\)/, "usage" ],
            [ 0, 1, qr/long\s+RETVAL/,                "no long declare" ],
            [ 0, 0, qr/\bint\s+RETVAL\s*=.*\QST(0)/,  "int  declare and init" ],
            [ 0, 0, qr/short\s+abc\s*=.*\QST(1)/,     "abc is ST1" ],
            [ 0, 0, qr/\b\QTARGi((IV)RETVAL, 1)/,     "TARGi" ],
            [ 0, 0, qr/\b\QXSRETURN(1)/,              "ret 1" ],
        ],

        [
            "long RETVAL alien autocall",
            [ Q(<<'EOF') ],
                |long
                |foo(short abc)
                |   int RETVAL = 99
EOF
            [ 0, 0, qr/_usage\(cv,\s*"abc"\)/,        "usage" ],
            [ 0, 0, qr/\bint\s+RETVAL\s*=\s*99/,      "declare and init" ],
            [ 0, 0, qr/short\s+abc\s*=.*\QST(0)/,     "abc is ST0" ],
            [ 0, 0, qr/\bRETVAL\s*=\s*foo\(abc\)/,    "autocall" ],
            [ 0, 0, qr/\b\QXSRETURN(1)/,              "ret 1" ],
        ],

        [
            "long RETVAL alien",
            [ Q(<<'EOF') ],
                |long
                |foo(abc, def)
                |   int def
                |   int RETVAL = 99
                |   int abc
                |  CODE:
                |    xyz
EOF
            [ 0, 0, qr/_usage\(cv,\s*"abc,\s*def"\)/, "usage" ],
            [ 0, 0, qr/\bint\s+RETVAL\s*=\s*99/,      "declare and init" ],
            [ 0, 0, qr/int\s+abc\s*=.*\QST(0)/,       "abc is ST0" ],
            [ 0, 0, qr/int\s+def\s*=.*\QST(1)/,       "def is ST1" ],
            [ 0, 0, qr/int\s+def.*int\s+RETVAL.*int\s+abc/s,  "ordering" ],
            [ 0, 0, qr/\b\QXSRETURN(1)/,              "ret 1" ],
        ],


        # Test NO_OUTPUT

        [
            "NO_OUTPUT autocall",
            [ Q(<<'EOF') ],
                |NO_OUTPUT long
                |foo(int abc)
EOF
            [ 0, 0, qr/_usage\(cv,\s*"abc"\)/,        "usage" ],
            [ 0, 0, qr/long\s+RETVAL;/,               "long declare  no init" ],
            [ 0, 0, qr/int\s+abc\s*=.*\QST(0)/,       "abc is ST0" ],
            [ 0, 0, qr/\bRETVAL\s*=\s*foo\(abc\)/,    "autocall" ],
            [ 0, 0, qr/\bXSRETURN_EMPTY\b/,           "ret empty" ],
        ],

        [
            # NO_OUTPUT with void should be a NOOP, but check
            "NO_OUTPUT void autocall",
            [ Q(<<'EOF') ],
                |NO_OUTPUT void
                |foo(int abc)
EOF
            [ 0, 0, qr/_usage\(cv,\s*"abc"\)/,        "usage" ],
            [ 0, 1, qr/\s+RETVAL;/,                   "don't declare RETVAL" ],
            [ 0, 0, qr/int\s+abc\s*=.*\QST(0)/,       "abc is ST0" ],
            [ 0, 0, qr/^\s*foo\(abc\)/m,              "void autocall" ],
            [ 0, 0, qr/\bXSRETURN_EMPTY\b/,           "ret empty" ],
        ],

        [
            "NO_OUTPUT with RETVAL autocall",
            [ Q(<<'EOF') ],
                |NO_OUTPUT long
                |foo(int RETVAL)
EOF
            [ 0, 0, qr/_usage\(cv,\s*"RETVAL"\)/,     "usage" ],
            [ 0, 0, qr/\bint\s+RETVAL\s*=/,           "declare and init" ],
            [ 0, 0, qr/\bRETVAL\s*=\s*foo\(RETVAL\)/, "autocall" ],
            [ 0, 0, qr/\bXSRETURN_EMPTY\b/,           "ret empty" ],
        ],

        [
            "NO_OUTPUT with CODE",
            [ Q(<<'EOF') ],
                |NO_OUTPUT long
                |foo(int abc)
                |   CODE:
                |      xyz
EOF
            [ 0, 0, qr/_usage\(cv,\s*"abc"\)/,        "usage" ],
            [ 0, 0, qr/long\s+RETVAL;/,               "long declare  no init" ],
            [ 0, 0, qr/int\s+abc\s*=.*\QST(0)/,       "abc is ST0" ],
            [ 0, 0, qr/\bXSRETURN_EMPTY\b/,           "ret empty" ],
        ],

        [
            # NO_OUTPUT with void should be a NOOP, but check
            "NO_OUTPUT void with CODE",
            [ Q(<<'EOF') ],
                |NO_OUTPUT void
                |foo(int abc)
                |   CODE:
                |      xyz
EOF
            [ 0, 0, qr/_usage\(cv,\s*"abc"\)/,        "usage" ],
            [ 0, 1, qr/\s+RETVAL;/,                   "don't declare RETVAL" ],
            [ 0, 0, qr/int\s+abc\s*=.*\QST(0)/,       "abc is ST0" ],
            [ 0, 0, qr/\bXSRETURN_EMPTY\b/,           "ret empty" ],
        ],

        [
            "NO_OUTPUT with RETVAL and CODE",
            [ Q(<<'EOF') ],
                |NO_OUTPUT long
                |foo(int RETVAL)
                |   CODE:
                |      xyz
EOF
            [ 0, 0, qr/_usage\(cv,\s*"RETVAL"\)/,     "usage" ],
            [ 0, 0, qr/\bint\s+RETVAL\s*=/,           "declare and init" ],
            [ 0, 0, qr/\bXSRETURN_EMPTY\b/,           "ret empty" ],
        ],


        [
            "NO_OUTPUT with CODE and OUTPUT",
            [ Q(<<'EOF') ],
                |NO_OUTPUT long
                |foo(int abc)
                |   CODE:
                |      xyz
                |   OUTPUT:
                |      RETVAL
EOF
            [ 1, 0, qr/Error: can't use RETVAL in OUTPUT when NO_OUTPUT declared/,  "OUTPUT err" ],
        ],

        [
            "NO_OUTPUT with RETVAL param and OUTPUT",
            [ Q(<<'EOF') ],
                |NO_OUTPUT long
                |foo(int RETVAL)
                |   OUTPUT:
                |      RETVAL
EOF
            [ 1, 0, qr/Error: can't use RETVAL in OUTPUT when NO_OUTPUT declared/,  "OUTPUT err" ],
        ],

        [
            "NO_OUTPUT with RETVAL param, CODE and OUTPUT",
            [ Q(<<'EOF') ],
                |NO_OUTPUT long
                |foo(int RETVAL)
                |   CODE:
                |      xyz
                |   OUTPUT:
                |      RETVAL
EOF
            [ 1, 0, qr/Error: can't use RETVAL in OUTPUT when NO_OUTPUT declared/,  "OUTPUT err" ],
        ],


        # Test duplicate RETVAL parameters

        [
            "void dup",
            [ Q(<<'EOF') ],
                |void
                |foo(RETVAL, RETVAL)
EOF
            [ 1, 0, qr/Error: duplicate definition of parameter 'RETVAL'/,  "" ],
        ],

        [
            "void dup typed",
            [ Q(<<'EOF') ],
                |void
                |foo(int RETVAL, short RETVAL)
EOF
            [ 1, 0, qr/Error: duplicate definition of parameter 'RETVAL'/,  "" ],
        ],

        [
            "void dup INPUT",
            [ Q(<<'EOF') ],
                |void
                |foo(RETVAL, RETVAL)
                |   int RETVAL
EOF
            [ 1, 0, qr/Error: duplicate definition of parameter 'RETVAL'/,  "" ],
        ],

        [
            "long dup",
            [ Q(<<'EOF') ],
                |long
                |foo(RETVAL, RETVAL)
EOF
            [ 1, 0, qr/Error: duplicate definition of parameter 'RETVAL'/,  "" ],
        ],

        [
            "long dup typed",
            [ Q(<<'EOF') ],
                |long
                |foo(int RETVAL, short RETVAL)
EOF
            [ 1, 0, qr/Error: duplicate definition of parameter 'RETVAL'/,  "" ],
        ],

        [
            "long dup INPUT",
            [ Q(<<'EOF') ],
                |long
                |foo(RETVAL, RETVAL)
                |   int RETVAL
EOF
            [ 1, 0, qr/Error: duplicate definition of parameter 'RETVAL'/,  "" ],
        ],


    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}

{
    # Test RETVAL return mixed types.
    # Where the return type of the XSUB differs from the declared type
    # of the RETVAL var. For backwards compatibility, we should use the
    # XSUB type when returning.

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
        |TYPEMAP: <<EOF
        |my_type    T_MY_TYPE
        |
        |OUTPUT
        |T_MY_TYPE
        |    sv_set_my_type($arg, (my_type)$var);
        |EOF
EOF

    my @test_fns = (

        [
            "RETVAL mixed type",
            [ Q(<<'EOF') ],
                |my_type
                |foo(int RETVAL)
EOF
            [ 0, 0, qr/int\s+RETVAL\s*=.*SvIV\b/,  "RETVAL is int" ],
            [ 0, 0, qr/sv_set_my_type\(/,          "return is my_type" ],
        ],

        [
            "RETVAL mixed type INPUT",
            [ Q(<<'EOF') ],
                |my_type
                |foo(RETVAL)
                |    int RETVAL
EOF
            [ 0, 0, qr/int\s+RETVAL\s*=.*SvIV\b/,  "RETVAL is int" ],
            [ 0, 0, qr/sv_set_my_type\(/,          "return is my_type" ],
        ],

        [
            "RETVAL mixed type alien",
            [ Q(<<'EOF') ],
                |my_type
                |foo()
                |  int RETVAL = 99;
EOF
            [ 0, 0, qr/int\s+RETVAL\s*=\s*99/,     "RETVAL is int" ],
            [ 0, 0, qr/sv_set_my_type\(/,          "return is my_type" ],
        ],

    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}

{
    # Test CASE: blocks

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (

        [
            "CASE with dup INPUT and OUTPUT",
            [ Q(<<'EOF') ],
                |int
                |foo(abc, def)
                |    CASE: X
                |            int   abc;
                |            short def;
                |        CODE:
                |            RETVAL = abc + def;
                |        OUTPUT:
                |            RETVAL
                |
                |    CASE: Y
                |            long abc;
                |            long def;
                |        CODE:
                |            RETVAL = abc - def;
                |        OUTPUT:
                |            RETVAL
EOF
            [ 0, 0, qr/_usage\(cv,\s*"abc, def"\)/,     "usage" ],

            [ 0, 0, qr/
                       if \s* \(X\)
                       .*
                       int \s+ abc \s* = [^\n]* ST\(0\)
                       .*
                       else \s+ if \s* \(Y\)
                      /xs,                       "1st abc is int and ST(0)" ],
            [ 0, 0, qr/
                       else \s+ if \s* \(Y\)
                       .*
                       long \s+ abc \s* = [^\n]* ST\(0\)
                      /xs,                       "2nd abc is long and ST(0)" ],
            [ 0, 0, qr/
                       if \s* \(X\)
                       .*
                       short \s+ def \s* = [^\n]* ST\(1\)
                       .*
                       else \s+ if \s* \(Y\)
                      /xs,                       "1st def is short and ST(1)" ],
            [ 0, 0, qr/
                       else \s+ if \s* \(Y\)
                       .*
                       long \s+ def \s* = [^\n]* ST\(1\)
                      /xs,                       "2nd def is long and ST(1)" ],
            [ 0, 0, qr/
                       if \s* \(X\)
                       .*
                       int \s+ RETVAL;
                       .*
                       else \s+ if \s* \(Y\)
                      /xs,                       "1st RETVAL is int" ],
            [ 0, 0, qr/
                       else \s+ if \s* \(Y\)
                       .*
                       int \s+ RETVAL;
                       .*
                      /xs,                       "2nd RETVAL is int" ],

            [ 0, 0, qr/
                       if \s* \(X\)
                       .*
                       \QRETVAL = abc + def;\E
                       .*
                       else \s+ if \s* \(Y\)
                      /xs,                       "1st RETVAL assign" ],
            [ 0, 0, qr/
                       else \s+ if \s* \(Y\)
                       .*
                       \QRETVAL = abc - def;\E
                       .*
                      /xs,                       "2nd RETVAL assign" ],

            [ 0, 0, qr/\b\QXSRETURN(1)/,           "ret 1" ],
            [ 0, 1, qr/\bXSRETURN\b.*\bXSRETURN/s, "only a single XSRETURN" ],
        ],
        [
            "CASE with unconditional else",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |    CASE: CCC1
                |        CODE:
                |            YYY1
                |    CASE: CCC2
                |        CODE:
                |            YYY2
                |    CASE:
                |        CODE:
                |            YYY3
EOF
            [ 0, 0, qr/
                       ^ \s+ if \s+ \(CCC1\) \n
                       ^ \s+ \{   \n
                       .*
                       ^\s+ YYY1  \n
                       .*
                       ^ \s+ \}   \n
                       ^ \s+ else \s+ if \s+ \(CCC2\) \n
                       ^ \s+ \{   \n
                       .*
                       ^\s+ YYY2  \n
                       .*
                       ^ \s+ \}   \n
                       ^ \s+ else \n
                       ^ \s+ \{   \n
                       .*
                       ^\s+ YYY3  \n
                       .*
                       ^ \s+ \}   \n
                       ^ \s+ XSRETURN_EMPTY;\n

                      /xms,                       "all present in order" ],
        ],
        [
            "CASE with dup alien var",
            [ Q(<<'EOF') ],
                |void
                |foo(abc)
                |    CASE: X
                |            int abc
                |            int def
                |    CASE: Y
                |            long abc
                |            long def
EOF
            [ 0, 0, qr/
                       if \s* \(X\)
                       .*
                       int \s+ def \s*;
                       .*
                       else \s+ if \s* \(Y\)
                       .*
                       long \s+ def \s*;
                      /xs,                       "two alien declarations" ],
        ],
        [
            "CASE with variant keywords",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |    CASE: X
                |       C_ARGS: x,y
                |    CASE: Y
                |       C_ARGS: y,x
EOF
            [ 0, 0, qr/\(x,y\).*\(y,x\)/s, "C_ARGS" ],
        ],
        [
            "CASE with variant THIS type",
            [ Q(<<'EOF') ],
                |void
                |A::B::foo()
                |    CASE: X
                |       int THIS
                |    CASE: Y
                |       long THIS
                |    CASE:
                |       short THIS
EOF
            [ 0, 0, qr/int   \s+ THIS .*
                       long  \s+ THIS .*
                       short \s+ THIS/sx, "has three types" ],
        ],
        [
            "CASE with variant RETVAL type",
            [ Q(<<'EOF') ],
                |int
                |foo()
                |    CASE: X
                |       long RETVAL
                |    CASE: Y
                |       double RETVAL
                |    CASE: Z
                |       char * RETVAL
EOF
            [ 0, 0, qr/long        \s+ RETVAL .*
                       double      \s+ RETVAL .*
                       char \s* \* \s+ RETVAL/sx, "has three decl types" ],
            [ 0, 0, qr/X .* TARGi .*
                       Y .* TARGi .*
                       Z .* TARGi .*/sx, "has one setting type" ],
        ],
        [
            "CASE with variant autocall RETVAL",
            [ Q(<<'EOF') ],
                |int
                |foo(int a)
                |    CASE: X
                |
                |    CASE: Y
                |        CODE:
                |            YYY
EOF
            [ 0, 0, qr{\Qif (X)\E
                       .*
                       dXSTARG;
                       .*
                       \QTARGi((IV)RETVAL, 1);\E
                       .*
                       \Qelse if (Y)\E
                       }sx,                 "branch X returns RETVAL" ],

            [ 0, 1, qr{\Qelse if (Y)\E
                       .*
                       \QPUSHi((IV)RETVAL);\E
                       }sx,                 "branch Y doesn't return RETVAL" ],
        ],
        [
            "CASE with variant deferred var inits",
            [ Q(<<'EOF') ],
                |int
                |foo(abc)
                |    CASE: X
                |     AV *abc
                |
                |    CASE: Y
                |     HV *abc
EOF
            [ 0, 0, qr{\Qif (X)\E
                       .*
                       croak.*\Qnot an ARRAY reference\E
                       .*
                       \Qelse if (Y)\E
                       .*
                       croak.*\Qnot a HASH reference\E
                       }sx,                 "differing croaks" ],

        ],

        [
            "CASE: case follows unconditional CASE",
            [ Q(<<'EOF') ],
                |int
                |foo()
                |    CASE: X
                |        CODE:
                |            AAA
                |    CASE:
                |        CODE:
                |            BBB
                |    CASE: Y
                |        CODE:
                |            CCC
EOF
            [ 1, 0, qr/\QError: 'CASE:' after unconditional 'CASE:'/,
                    "expected err" ],
        ],
        [
            "CASE: not at top of function",
            [ Q(<<'EOF') ],
                |int
                |foo()
                |    CODE:
                |        AAA
                |    CASE: X
                |        CODE:
EOF
            [ 1, 0, qr/\QError: no 'CASE:' at top of function/,
                    "expected err" ],
        ],
        [
            "CASE: junk",
            [ Q(<<'EOF') ],
                |int
                |foo(a)
                |CASE: X
                |    SCOPE: ENABLE
                |    INPUTx:
EOF
            [ 1, 0, qr/\QError: junk at end of function: "    INPUTx:" in /,
                    "expected err" ],
        ],
        [
            "keyword after end of xbody",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |  CODE:
                |     abc
                |  C_ARGS:
EOF
            [ 1, 0, qr{\QError: misplaced 'C_ARGS:' in\E.*line 8},
                                                    "got expected error"  ],
        ],

        [
            "CASE: setting ST(0)",
            [ Q(<<'EOF') ],
                |void
                |foo(a)
                |CASE: X
                |    CODE:
                |      ST(0) = 1;
                |CASE: Y
                |    CODE:
                |      blah
EOF
            [ 1, 0, qr/\QWarning: ST(0) isn't consistently set in every CASE's CODE block/,
                    "expected err" ],
        ],


    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}

{
    # Test placeholders - various semi-official ways to to mark an
    # argument as 'unused'.

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (

        [
            "placeholder: typeless param with CODE",
            [ Q(<<'EOF') ],
                |int
                |foo(int AAA, BBB, int CCC)
                |   CODE:
                |      XYZ;
EOF
            [ 0, 0, qr/_usage\(cv,\s*"AAA, BBB, CCC"\)/,      "usage" ],
            [ 0, 0, qr/\bint\s+AAA\s*=\s*.*\Q(ST(0))/,        "AAA is ST(0)" ],
            [ 0, 0, qr/\bint\s+CCC\s*=\s*.*\Q(ST(2))/,        "CCC is ST(2)" ],
            [ 0, 1, qr/\bBBB;/,                               "no BBB decl" ],
        ],

        [
            "placeholder: typeless param bodiless",
            [ Q(<<'EOF') ],
                |int
                |foo(int AAA, BBB, int CCC)
EOF
            [ 0, 0, qr/_usage\(cv,\s*"AAA, BBB, CCC"\)/,      "usage" ],
            # Note that autocall uses the BBB var even though it isn't
            # declared. It would be up to the coder to use C_ARGS, or add
            # such a var via PREINIT.
            [ 0, 0, qr/\bRETVAL\s*=\s*\Qfoo(AAA, BBB, CCC);/, "autocall" ],
            [ 0, 0, qr/\bint\s+AAA\s*=\s*.*\Q(ST(0))/,        "AAA is ST(0)" ],
            [ 0, 0, qr/\bint\s+CCC\s*=\s*.*\Q(ST(2))/,        "CCC is ST(2)" ],
            [ 0, 1, qr/\bBBB;/,                               "no BBB decl" ],
        ],

        [
            # this is the only IN/OUT etc one which works, since IN is the
            # default.
            "placeholder: typeless IN param with CODE",
            [ Q(<<'EOF') ],
                |int
                |foo(int AAA, IN BBB, int CCC)
                |   CODE:
                |      XYZ;
EOF
            [ 0, 0, qr/_usage\(cv,\s*"AAA, BBB, CCC"\)/,      "usage" ],
            [ 0, 0, qr/\bint\s+AAA\s*=\s*.*\Q(ST(0))/,        "AAA is ST(0)" ],
            [ 0, 0, qr/\bint\s+CCC\s*=\s*.*\Q(ST(2))/,        "CCC is ST(2)" ],
            [ 0, 1, qr/\bBBB;/,                               "no BBB decl" ],
        ],


        [
            "placeholder: typeless OUT param with CODE",
            [ Q(<<'EOF') ],
                |int
                |foo(int AAA, OUT BBB, int CCC)
                |   CODE:
                |      XYZ;
EOF
            [ 1, 0, qr/Error: can't determine output type for 'BBB'/, "got type err" ],
        ],

        [
            "placeholder: typeless IN_OUT param with CODE",
            [ Q(<<'EOF') ],
                |int
                |foo(int AAA, IN_OUT BBB, int CCC)
                |   CODE:
                |      XYZ;
EOF
            [ 1, 0, qr/Error: can't determine output type for 'BBB'/, "got type err" ],
        ],

        [
            "placeholder: typeless OUTLIST param with CODE",
            [ Q(<<'EOF') ],
                |int
                |foo(int AAA, OUTLIST BBB, int CCC)
                |   CODE:
                |      XYZ;
EOF
            [ 1, 0, qr/Error: can't determine output type for 'BBB'/, "got type err" ],
        ],

        [
            # a placeholder with a default value may not seem to make much
            # sense, but it allows an argument to still be passed (or
            # not), even if it;s no longer used.
            "placeholder: typeless default param with CODE",
            [ Q(<<'EOF') ],
                |int
                |foo(int AAA, BBB = 888, int CCC = 999)
                |   CODE:
                |      XYZ;
EOF
            [ 0, 0, qr/_usage\(cv,\s*"AAA, BBB = 888, CCC\s*= 999"\)/,"usage" ],
            [ 0, 0, qr/\bint\s+AAA\s*=\s*.*\Q(ST(0))/,        "AAA is ST(0)" ],
            [ 0, 0, qr/\bCCC\s*=\s*.*\Q(ST(2))/,              "CCC is ST(2)" ],
            [ 0, 1, qr/\bBBB;/,                               "no BBB decl" ],
            [ 0, 1, qr/\b888\s*;/,                            "no 888 usage" ],
        ],

        [
            "placeholder: allow SV *",
            [ Q(<<'EOF') ],
                |int
                |foo(int AAA, SV *, int CCC)
                |   CODE:
                |      XYZ;
EOF
            [ 0, 0, qr/_usage\(cv,\s*\Q"AAA, SV *, CCC")/,    "usage" ],
            [ 0, 0, qr/\bint\s+AAA\s*=\s*.*\Q(ST(0))/,        "AAA is ST(0)" ],
            [ 0, 0, qr/\bint\s+CCC\s*=\s*.*\Q(ST(2))/,        "CCC is ST(2)" ],
        ],

        [
            # Bodiless XSUBs can't use SV* as a placeholder ...
            "placeholder: SV *, bodiless",
            [ Q(<<'EOF') ],
                |int
                |foo(int AAA, SV    *, int CCC)
EOF
            [ 1, 0, qr/Error: parameter 'SV \*' not valid as a C argument/,
                                                           "got arg err" ],
        ],

        [
            # ... unless they use C_ARGS to define how the C fn should
            # be called.
            "placeholder: SV *, bodiless C_ARGS",
            [ Q(<<'EOF') ],
                |int
                |foo(int AAA, SV    *, int CCC)
                |    C_ARGS: AAA, CCC
EOF
            [ 0, 0, qr/_usage\(cv,\s*\Q"AAA, SV *, CCC")/,    "usage" ],
            [ 0, 0, qr/\bint\s+AAA\s*=\s*.*\Q(ST(0))/,        "AAA is ST(0)" ],
            [ 0, 0, qr/\bint\s+CCC\s*=\s*.*\Q(ST(2))/,        "CCC is ST(2)" ],
            [ 0, 0, qr/\bRETVAL\s*=\s*\Qfoo(AAA, CCC);/,      "autocall" ],
        ],


    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}

{
    # Test weird packing facility: return type array(type,nitems)

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (

        [
            "array(int,5)",
            [ Q(<<'EOF') ],
                |array(int,5)
                |foo()
EOF
            [ 0, 0, qr/int\s*\*\s+RETVAL;/,      "RETVAL is int*" ],
            [ 0, 0, qr/sv_setpvn\(.*,\s*5\s*\*\s*\Qsizeof(int));/,
                                                 "return packs 5 ints" ],
            [ 0, 0, qr/\bdXSTARG\b/,             "declares TARG" ],
            [ 0, 0, qr/sv_setpvn\(TARG\b/,       "uses TARG" ],

        ],

        [
            "array(int*, expr)",
            [ Q(<<'EOF') ],
                |array(int*, FOO_SIZE)
                |foo()
EOF
            [ 0, 0, qr/int\s*\*\s*\*\s+RETVAL;/, "RETVAL is int**" ],
            [ 0, 0, qr/sv_setpvn\(.*,\s*FOO_SIZE\s*\*\s*sizeof\(int\s*\*\s*\)\);/,
                                                "return packs FOO_SIZE int*s" ],
        ],

        [
            "array() as param type",
            [ Q(<<'EOF') ],
                |int
                |foo(abc)
                |    array(int,5) abc
EOF
            [ 1, 0, qr/Could not find a typemap for C type/, " no find type" ],
        ],

        [
            "array() can be overriden by OUTPUT",
            [ Q(<<'EOF') ],
                |array(int,5)
                |foo()
                |    OUTPUT:
                |        RETVAL my_setintptr(ST(0), RETVAL);
EOF
            [ 0, 0, qr/int\s*\*\s+RETVAL;/,             "RETVAL is int*" ],
            [ 0, 0, qr/\Qmy_setintptr(ST(0), RETVAL);/, "override honoured" ],
        ],

        [
            "array() in output override isn't special",
            [ Q(<<'EOF') ],
                |short
                |foo()
                |    OUTPUT:
                |        RETVAL array(int,5)
EOF
            [ 0, 0, qr/short\s+RETVAL;/,      "RETVAL is short" ],
            [ 0, 0, qr/\Qarray(int,5)/,       "return expression is unchanged" ],
        ],

        [
            "array() OUT",
            [ Q(<<'EOF') ],
                |int
                |foo(OUT array(int,5) AAA)
EOF
            [ 1, 0, qr/\QError: can't use array(type,nitems) type for OUT parameter/,
                        "got err" ],
        ],

        [
            "array() OUTLIST",
            [ Q(<<'EOF') ],
                |int
                |foo(OUTLIST array(int,5) AAA)
EOF
            [ 1, 0, qr/\QError: can't use array(type,nitems) type for OUTLIST parameter/,
                    "got err" ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}

{
    # Test weird packing facility: DO_ARRAY_ELEM

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
        |TYPEMAP: <<EOF
        |intArray *        T_ARRAY
        |longArray *       T_ARRAY
        |
        |myiv              T_IV
        |myivArray *       T_ARRAY
        |
        |blah              T_BLAH
        |blahArray *       T_ARRAY
        |
        |nosuchtypeArray * T_ARRAY
        |
        |shortArray *      T_DAE
        |NoInputArray *    T_DAE
        |NoInput           T_Noinput
        |
        |NooutputArray *   T_ARRAY
        |Nooutput          T_Nooutput
        |
        |INPUT
        |T_BLAH
        |   $var = my_get_blah($arg);
        |
        |T_DAE
        |   IN($var,$type,$ntype,$subtype,$arg,$argoff){DO_ARRAY_ELEM}
        |
        |OUTPUT
        |T_BLAH
        |   my_set_blah($arg, $var);
        |
        |T_DAE
        |   OUT($var,$type,$ntype,$subtype,$arg){DO_ARRAY_ELEM}
        |
        |EOF
EOF

    my @test_fns = (

        [
            "T_ARRAY long input",
            [ Q(<<'EOF') ],
                |char *
                |foo(longArray * abc)
EOF
            [ 0, 0, qr/longArray\s*\*\s*abc;/,      "abc is longArray*" ],
            [ 0, 0, qr/abc\s*=\s*longArrayPtr\(/,   "longArrayPtr called" ],
            [ 0, 0, qr/abc\[ix_abc.*\]\s*=\s*.*\QSvIV(ST(ix_abc))/,
                                                    "abc[i] set" ],
            [ 0, 1, qr/DO_ARRAY_ELEM/,              "no DO_ARRAY_ELEM" ],
        ],
        [
            "T_ARRAY long output",
            [ Q(<<'EOF') ],
                |longArray *
                |foo()
EOF
            [ 0, 0, qr/longArray\s*\*\s*RETVAL;/,   "RETVAL is longArray*" ],
            [ 0, 1, qr/longArrayPtr/,               "longArrayPtr NOT called" ],
            [ 0, 0, qr/\Qsv_setiv(ST(ix_RETVAL), (IV)RETVAL[ix_RETVAL]);/,
                                                    "ST(i) set" ],
            [ 0, 1, qr/DO_ARRAY_ELEM/,              "no DO_ARRAY_ELEM" ],
        ],

        [
            "T_ARRAY myiv input",
            [ Q(<<'EOF') ],
                |char *
                |foo(myivArray * abc)
EOF
            [ 0, 0, qr/myivArray\s*\*\s*abc;/,      "abc is myivArray*" ],
            [ 0, 0, qr/abc\s*=\s*myivArrayPtr\(/,   "myivArrayPtr called" ],
            [ 0, 0, qr/abc\[ix_abc.*\]\s*=\s*.*\QSvIV(ST(ix_abc))/,
                                                    "abc[i] set" ],
            [ 0, 1, qr/DO_ARRAY_ELEM/,              "no DO_ARRAY_ELEM" ],
        ],
        [
            "T_ARRAY myiv output",
            [ Q(<<'EOF') ],
                |myivArray *
                |foo()
EOF
            [ 0, 0, qr/myivArray\s*\*\s*RETVAL;/,   "RETVAL is myivArray*" ],
            [ 0, 1, qr/myivArrayPtr/,               "myivArrayPtr NOT called" ],
            [ 0, 0, qr/\Qsv_setiv(ST(ix_RETVAL), (IV)RETVAL[ix_RETVAL]);/,
                                                    "ST(i) set" ],
            [ 0, 1, qr/DO_ARRAY_ELEM/,              "no DO_ARRAY_ELEM" ],
        ],

        [
            "T_ARRAY blah input",
            [ Q(<<'EOF') ],
                |char *
                |foo(blahArray * abc)
EOF
            [ 0, 0, qr/blahArray\s*\*\s*abc;/,      "abc is blahArray*" ],
            [ 0, 0, qr/abc\s*=\s*blahArrayPtr\(/,   "blahArrayPtr called" ],
            [ 0, 0, qr/abc\[ix_abc.*\]\s*=\s*.*\Qmy_get_blah(ST(ix_abc))/,
                                                    "abc[i] set" ],
            [ 0, 1, qr/DO_ARRAY_ELEM/,              "no DO_ARRAY_ELEM" ],
        ],
        [
            "T_ARRAY blah output",
            [ Q(<<'EOF') ],
                |blahArray *
                |foo()
EOF
            [ 0, 0, qr/blahArray\s*\*\s+RETVAL;/,   "RETVAL is blahArray*" ],
            [ 0, 1, qr/blahArrayPtr/,               "blahArrayPtr NOT called" ],
            [ 0, 0, qr/\Qmy_set_blah(ST(ix_RETVAL), RETVAL[ix_RETVAL]);/,
                                                    "ST(i) set" ],
            [ 0, 1, qr/DO_ARRAY_ELEM/,              "no DO_ARRAY_ELEM" ],
        ],

        [
            "T_ARRAY nosuchtype input",
            [ Q(<<'EOF') ],
                |char *
                |foo(nosuchtypeArray * abc)
EOF
            [ 1, 0, qr/Could not find a typemap for C type 'nosuchtype'/,
                                                    "no such type" ],
        ],
        [
            "T_ARRAY nosuchtype output",
            [ Q(<<'EOF') ],
                |nosuchtypeArray *
                |foo()
EOF
            [ 1, 0, qr/Could not find a typemap for C type 'nosuchtype'/,
                                                    "no such type" ],
        ],

        # test DO_ARRAY_ELEM in a typemap other than T_ARRAY.
        #
        # XXX It's not clear whether DO_ARRAY_ELEM should be processed
        # in typemap definitions generally, rather than just in the
        # T_ARRAY definition. Currently it is, but DO_ARRAY_ELEM isn't
        # documented, and was clearly put into place as a hack to make
        # T_ARRAY work. So these tests represent the *current*
        # behaviour, but don't necessarily endorse that behaviour. These
        # tests ensure that any change in behaviour is deliberate rather
        # than accidental.
        [
            "T_DAE input",
            [ Q(<<'EOF') ],
                |char *
                |foo(shortArray * abc)
EOF
            [ 0, 0, qr/shortArray\s*\*\s*abc;/,      "abc is shortArray*" ],
            # calling fooArrayPtr() is part of the T_ARRAY typemap,
            # not part of the general mechanism
            [ 0, 1, qr/shortArrayPtr\(/,             "no shortArrayPtr call" ],
            [ 0, 0, qr/\{\s*abc\[ix_abc.*\]\s*=\s*.*\QSvIV(ST(ix_abc))\E\s*\n?\s*\}/,
                                                    "abc[i] set" ],
            [ 0, 0, qr/\QIN(abc,shortArray *,shortArrayPtr,short,ST(0),0)/,
                                                    "template vars ok" ],
            [ 0, 1, qr/DO_ARRAY_ELEM/,              "no DO_ARRAY_ELEM" ],
        ],
        [
            "T_DAE output",
            [ Q(<<'EOF') ],
                |shortArray *
                |foo()
EOF
            [ 0, 0, qr/shortArray\s*\*\s*RETVAL;/,  "RETVAL is shortArray*" ],
            [ 0, 1, qr/shortArrayPtr\(/,            "shortArrayPtr NOT called" ],
            [ 0, 0, qr/\Qsv_setiv(ST(ix_RETVAL), (IV)RETVAL[ix_RETVAL]);/,
                                                    "ST(i) set" ],
            [ 0, 0, qr/\QOUT(RETVAL,shortArray *,shortArrayPtr,short,ST(0))/,
                                                    "template vars ok" ],
            [ 0, 1, qr/DO_ARRAY_ELEM/,              "no DO_ARRAY_ELEM" ],
        ],
        [
            "T_DAE bad input",
            [ Q(<<'EOF') ],
                |int
                |foo(NoInputArray * abc)
EOF
            [ 1, 0, qr/\QError: no INPUT definition for subtype 'NoInput', typekind 'T_Noinput' found in\E.*line 40/,
                                                    "got expected error" ],
        ],

        # Use overridden return code with an OUTPUT line.
        [
            "T_ARRAY override output",
            [ Q(<<'EOF') ],
                |intArray *
                |foo()
                |    OUTPUT:
                |      RETVAL my_intptr_set(ST(0), RETVAL[0]);
EOF
            [ 0, 0, qr/intArray\s*\*\s*RETVAL;/,   "RETVAL is intArray*" ],
            [ 0, 1, qr/intArrayPtr/,               "intArrayPtr NOT called" ],
            [ 0, 0, qr/\Qmy_intptr_set(ST(0), RETVAL[0]);/, "ST(0) set" ],
            [ 0, 1, qr/DO_ARRAY_ELEM/,              "no DO_ARRAY_ELEM" ],
        ],

        # for OUT and OUTLIST arguments, don't process DO_ARRAY_ELEM
        [
            "T_ARRAY OUT",
            [ Q(<<'EOF') ],
                |int
                |foo(OUT intArray * abc)
EOF
            [ 1, 0, qr/Error: can't use typemap containing DO_ARRAY_ELEM for OUT parameter/,
                    "gives err" ],
        ],
        [
            "T_ARRAY OUT",
            [ Q(<<'EOF') ],
                |int
                |foo(OUTLIST intArray * abc)
EOF
            [ 1, 0, qr/Error: can't use typemap containing DO_ARRAY_ELEM for OUTLIST parameter/,
                    "gives err" ],
        ],

        [
            "T_ARRAY no output typemap entry",
            [ Q(<<'EOF') ],
                |NooutputArray *
                |foo()
EOF
            [ 1, 0, qr/\QError: no OUTPUT definition for subtype 'Nooutput', typekind 'T_Nooutput'\E.*line 40/,
                    "gives expected error" ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}

{
    # Test valid syntax of global-effect ENABLE/DISABLE keywords
    #
    # Check that disallowed variants give errors and allowed variants
    # get as far as generating a boot XSUB

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "VERSIONCHECK: long word",
            [ Q(<<'EOF') ],
                |VERSIONCHECK: ENABLEblah
EOF
            [ 1, 0, qr{Error: VERSIONCHECK: ENABLE/DISABLE}, "should die" ],
        ],
        [
            "VERSIONCHECK: trailing text",
            [ Q(<<'EOF') ],
                |VERSIONCHECK: DISABLE blah # bloo +$%
EOF
            [ 1, 0, qr{Error: VERSIONCHECK: ENABLE/DISABLE}, "should die" ],
        ],
        [
            "VERSIONCHECK: lower case",
            [ Q(<<'EOF') ],
                |VERSIONCHECK: disable
EOF
            [ 1, 0, qr{Error: VERSIONCHECK: ENABLE/DISABLE}, "should die" ],
        ],
        [
            "VERSIONCHECK: semicolon",
            [ Q(<<'EOF') ],
                |VERSIONCHECK: DISABLE;
EOF
            [ 1, 0, qr{Error: VERSIONCHECK: ENABLE/DISABLE}, "should die" ],
        ],

        [
            "EXPORT_XSUB_SYMBOLS: long word",
            [ Q(<<'EOF') ],
                |EXPORT_XSUB_SYMBOLS: ENABLEblah
EOF
            [ 1, 0, qr{Error: EXPORT_XSUB_SYMBOLS: ENABLE/DISABLE}, "should die" ],
        ],
        [
            "EXPORT_XSUB_SYMBOLS: trailing text",
            [ Q(<<'EOF') ],
                |EXPORT_XSUB_SYMBOLS: diSAble blah # bloo +$%
EOF
            [ 1, 0, qr{Error: EXPORT_XSUB_SYMBOLS: ENABLE/DISABLE}, "should die" ],
        ],
        [
            "EXPORT_XSUB_SYMBOLS: lower case",
            [ Q(<<'EOF') ],
                |EXPORT_XSUB_SYMBOLS: disable
EOF
            [ 1, 0, qr{Error: EXPORT_XSUB_SYMBOLS: ENABLE/DISABLE}, "should die" ],
        ],

        [
            "file SCOPE: long word",
            [ Q(<<'EOF') ],
                |SCOPE: ENABLEblah
                |void
                |foo()
EOF
            [ 1, 0, qr{Error: SCOPE: ENABLE/DISABLE}, "should die" ],
        ],
        [
            "file SCOPE: lower case",
            [ Q(<<'EOF') ],
                |SCOPE: enable
                |void
                |foo()
EOF
            [ 1, 0, qr{Error: SCOPE: ENABLE/DISABLE}, "should die" ],
        ],

    );

    test_many($preamble, 'boot_Foo', \@test_fns);
}


{
    # Test PROTOTYPES keyword. Note that there is a lot of
    # backwards-compatibility oddness in the keyword's value

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
EOF

    my @test_fns = (
        [
            "PROTOTYPES: ENABLE",
            [ Q(<<'EOF') ],
                |PROTOTYPES: ENABLE
                |
                |void
                |foo(int a, int b)
EOF
            [ 0, 0, qr{newXSproto_portable.*"\$\$"}, "has proto" ],
        ],
        [
            "PROTOTYPES: ENABLED",
            [ Q(<<'EOF') ],
                |PROTOTYPES: ENABLED
                |
                |void
                |foo(int a, int b)
EOF
            [ 0, 0, qr{newXSproto_portable.*"\$\$"}, "has proto" ],
            [ 1, 0, qr{Warning: invalid PROTOTYPES value 'ENABLED' interpreted as ENABLE},
                    "got warning" ],
        ],
        [
            "PROTOTYPES: ENABLE;",
            [ Q(<<'EOF') ],
                |PROTOTYPES: ENABLE;
                |
                |void
                |foo(int a, int b)
EOF
            [ 0, 0, qr{newXSproto_portable.*"\$\$"}, "has proto" ],
            [ 1, 0, qr{Warning: invalid PROTOTYPES value 'ENABLE;' interpreted as ENABLE},
                    "got warning" ],
        ],

        [
            "PROTOTYPES: DISABLE",
            [ Q(<<'EOF') ],
                |PROTOTYPES: DISABLE
                |
                |void
                |foo(int a, int b)
EOF
            [ 0, 1, qr{"\$\$"}, "doesn't have proto" ],
        ],
        [
            "PROTOTYPES: DISABLED",
            [ Q(<<'EOF') ],
                |PROTOTYPES: DISABLED
                |
                |void
                |foo(int a, int b)
EOF
            [ 0, 1, qr{"\$\$"}, "doesn't have proto" ],
            [ 1, 0, qr{Warning: invalid PROTOTYPES value 'DISABLED' interpreted as DISABLE},
                    "got warning" ],
        ],
        [
            "PROTOTYPES: DISABLE;",
            [ Q(<<'EOF') ],
                |PROTOTYPES: DISABLE;
                |
                |void
                |foo(int a, int b)
EOF
            [ 0, 1, qr{"\$\$"}, "doesn't have proto" ],
            [ 1, 0, qr{Warning: invalid PROTOTYPES value 'DISABLE;' interpreted as DISABLE},
                    "got warning" ],
        ],

        [
            "PROTOTYPES: long word",
            [ Q(<<'EOF') ],
                |PROTOTYPES: ENABLEblah
                |
                |void
                |foo(int a, int b)
EOF
            [ 1, 0, qr{Error: PROTOTYPES: ENABLE/DISABLE}, "should die" ],
        ],
        [
            "PROTOTYPES: trailing text",
            [ Q(<<'EOF') ],
                |PROTOTYPES: ENABLE blah
                |
                |void
                |foo(int a, int b)
EOF
            [ 1, 0, qr{Error: PROTOTYPES: ENABLE/DISABLE}, "should die" ],
        ],
        [
            "PROTOTYPES: trailing text and comment)",
            [ Q(<<'EOF') ],
                |PROTOTYPES: DISABLE blah # bloo +$%
                |
                |void
                |foo(int a, int b)
EOF
            [ 1, 0, qr{Error: PROTOTYPES: ENABLE/DISABLE}, "should die" ],
        ],


    );

    test_many($preamble, 'boot_Foo', \@test_fns);
}


{
    # Test per-XSUB ENABLE/DISABLE keywords except PROTOTYPES

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
        |TYPEMAP: <<EOF
        |MyScopeInt        T_MYINT
        |
        |INPUT
        |T_MYINT
        |   $var = my_int($arg); /* SCOPE */
        |EOF
EOF

    my @test_fns = (
        [
            "file SCOPE: trailing text",
            [ Q(<<'EOF') ],
                |SCOPE: EnAble blah # bloo +$%
                |void
                |foo()
EOF
            [ 1, 0, qr{Error: SCOPE: ENABLE/DISABLE}, "should die" ],
        ],
        [
            "xsub SCOPE: trailing text",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |SCOPE: EnAble blah # bloo +$%
EOF
            [ 1, 0, qr{Error: SCOPE: ENABLE/DISABLE}, "should die" ],
        ],
        [
            "xsub SCOPE: lower case",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |SCOPE: enable
EOF
            [ 1, 0, qr{Error: SCOPE: ENABLE/DISABLE}, "should die" ],
        ],
        [
            "xsub SCOPE: semicolon",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |SCOPE: ENABLE;
EOF
            [ 1, 0, qr{Error: SCOPE: ENABLE/DISABLE}, "should die" ],
        ],

        [
            "SCOPE: as file-scoped keyword",
            [ Q(<<'EOF') ],
                |SCOPE: ENABLE
                |void
                |foo()
                |C_ARGS: a,b,c
EOF
            [ 0, 0, qr{ENTER;\s+{\s+\Qfoo(a,b,c);\E\s+}\s+LEAVE;},
                    "has ENTER/LEAVE" ],
        ],
        [
            "SCOPE: as xsub-scoped keyword",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |C_ARGS: a,b,c
                |SCOPE: ENABLE
EOF
            [ 0, 0, qr{ENTER;\s+{\s+\Qfoo(a,b,c);\E\s+}\s+LEAVE;},
                    "has ENTER/LEAVE" ],
        ],
        [
            "/* SCOPE */ in typemap",
            [ Q(<<'EOF') ],
                |void
                |foo(i)
                | MyScopeInt i
EOF
            [ 0, 0, qr{ENTER;\s+{.+\s+}\s+LEAVE;}s, "has ENTER/LEAVE" ],
        ],
        [
            "xsub duplicate SCOPE",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |SCOPE: ENABLE
                |SCOPE: ENABLE
EOF
            [ 1, 0, qr{\QError: only one SCOPE declaration allowed per XSUB},
                    "got expected error"],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test ALIAS keyword - boot code

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "ALIAS basic",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |    ALIAS: foo = 1
                |           bar = 2
                |           Baz::baz = 3
                |           boz = BOZ_VAL
                |           buz => foo
                |           biz => Baz::baz
EOF
            [ 0, 0, qr{"Foo::foo",.*\n.*= 1;},
                   "has Foo::foo" ],
            [ 0, 0, qr{"Foo::bar",.*\n.*= 2;},
                   "has Foo::bar" ],
            [ 0, 0, qr{"Baz::baz",.*\n.*= 3;},
                   "has Baz::baz" ],
            [ 0, 0, qr{"Foo::boz",.*\n.*= BOZ_VAL;},
                   "has Foo::boz" ],
            [ 0, 0, qr{"Foo::buz",.*\n.*= 1;},
                   "has Foo::buz" ],
            [ 0, 0, qr{"Foo::biz",.*\n.*= 3;},
                   "has Foo::biz" ],
            [ 0, 0, qr{\QCV * cv;}, "has cv declaration" ],
        ],

        [
            "ALIAS with main as default of 0",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |    ALIAS:
                |           bar = 2
EOF
            [ 0, 0, qr{"Foo::foo",.*\n.*= 0;},
                   "has Foo::foo" ],
            [ 0, 0, qr{"Foo::bar",.*\n.*= 2;},
                   "has Foo::bar" ],
        ],

        [
            "ALIAS multi-perl-line, blank lines",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |    ALIAS:            foo   =    1       bar  =  2   
                |
                | Baz::baz  =  3      boz = BOZ_VAL
                |       buz =>                          foo
                |           biz => Baz::baz
                |   
                |
EOF
            [ 0, 0, qr{"Foo::foo",.*\n.*= 1;},
                   "has Foo::foo" ],
            [ 0, 0, qr{"Foo::bar",.*\n.*= 2;},
                   "has Foo::bar" ],
            [ 0, 0, qr{"Baz::baz",.*\n.*= 3;},
                   "has Baz::baz" ],
            [ 0, 0, qr{"Foo::boz",.*\n.*= BOZ_VAL;},
                   "has Foo::boz" ],
            [ 0, 0, qr{"Foo::buz",.*\n.*= 1;},
                   "has Foo::buz" ],
            [ 0, 0, qr{"Foo::biz",.*\n.*= 3;},
                   "has Foo::biz" ],
        ],

        [
            "ALIAS no colon",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |    ALIAS: bar = X::Y
EOF
            [ 1, 0, qr{\QError: in alias definition for 'bar' the value may not contain ':' unless it is symbolic.\E.*line 7},
                   "got expected error" ],
        ],

        [
            "ALIAS unknown alias",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |    ALIAS: Foo::bar => blurt
EOF
            [ 1, 0, qr{\QError: unknown alias 'Foo::blurt' in symbolic definition for 'Foo::bar'\E.*line 7},
                   "got expected error" ],
        ],

        [
            "ALIAS warn duplicate",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |    ALIAS: bar = 1
                |           bar = 1
EOF
            [ 1, 0, qr{\QWarning: ignoring duplicate alias 'bar'\E.*line 8},
                   "got expected warning" ],
        ],
        [
            "ALIAS warn conflict duplicate",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |    ALIAS: bar = 1
                |           bar = 2
EOF
            [ 1, 0, qr{\QWarning: conflicting duplicate alias 'bar'\E.*line 8},
                   "got expected warning" ],
        ],

        [
            "ALIAS warn identical values",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |    ALIAS: bar = 1
                |           baz = 1
EOF
            [ 1, 0, qr{\QWarning: aliases 'baz' and 'bar' have identical values of 1\E.*line 8},
                   "got expected warning" ],
        ],

        [
            "ALIAS unparseable entry",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |    ALIAS: bar = 
EOF
            [ 1, 0, qr{\QError: cannot parse ALIAS definitions from 'bar ='\E.*line 7},
                   "got expected error" ],
        ],
    );

    test_many($preamble, 'boot_Foo', \@test_fns);
}

{
    # Test ALIAS keyword  - XSUB body

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            'ALIAS with $ALIAS used in typemap entry',
            [ Q(<<'EOF') ],
                |void
                |foo(AV *av)
                |    ALIAS: bar = 1
EOF
            [ 0, 0, qr{croak.*\n.*\QGvNAME(CvGV(cv))},
                   "got alias variant of croak message" ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test INTERFACE keyword - boot code

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "INTERFACE basic boot",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |    INTERFACE: f1 f2
EOF
            [ 0, 0, qr{   \QnewXS_deffile("Foo::f1", XS_Foo_foo);\E\n
                       \s+\QXSINTERFACE_FUNC_SET(cv,f1);\E
                      }x,
                   "got f1 entries" ],
            [ 0, 0, qr{   \QnewXS_deffile("Foo::f2", XS_Foo_foo);\E\n
                       \s+\QXSINTERFACE_FUNC_SET(cv,f2);\E
                      }x,
                   "got f2 entries" ],
            [ 0, 0, qr{\QCV * cv;}, "has cv declaration" ],
        ],
    );

    test_many($preamble, 'boot_Foo', \@test_fns);
}

{
    # Test INTERFACE keyword  - XSUB body

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
        |TYPEMAP: <<EOTM
        |X::Y T_IV
        |EOTM
        |
EOF

    my @test_fns = (
        [
            'INTERFACE basic body',
            [ Q(<<'EOF') ],
                |void
                |foo()
                |    INTERFACE: f1 f2
EOF
            [ 0, 0, qr{\b\QdXSFUNCTION(void)},
                   "got XSFUNCTION declaration" ],
            [ 0, 0, qr{\QXSFUNCTION = XSINTERFACE_FUNC(void,cv,XSANY.any_dptr);},
                   "got XSFUNCTION assign" ],
            [ 0, 0, qr{\Q((void (*)())(XSFUNCTION))();},
                   "got XSFUNCTION call" ],
        ],
        [
            'INTERFACE with perl package name',
            [ Q(<<'EOF') ],
                |X::Y
                |foo(X::Y a, char *b)
                |    INTERFACE: f1
EOF
            [ 0, 0, qr{\b\QdXSFUNCTION(X__Y)},
                   "got XSFUNCTION declaration" ],
            [ 0, 0, qr{\QXSFUNCTION = XSINTERFACE_FUNC(X__Y,cv,XSANY.any_dptr);},
                   "got XSFUNCTION assign" ],
            [ 0, 0, qr{\QRETVAL = ((X__Y (*)(X__Y, char *))(XSFUNCTION))(a, b);},
                   "got XSFUNCTION call" ],
        ],
        [
            'INTERFACE with C_ARGS',
            [ Q(<<'EOF') ],
                |char *
                |foo(X::Y a, int b, char *c)
                |    INTERFACE: f1
                |    C_ARGS:  a,  c
EOF
            [ 0, 0, qr{\b\QdXSFUNCTION(char *)},
                   "got XSFUNCTION declaration" ],
            [ 0, 0, qr{\QXSFUNCTION = XSINTERFACE_FUNC(char *,cv,XSANY.any_dptr);},
                   "got XSFUNCTION assign" ],
            [ 0, 0, qr{\QRETVAL = ((char * (*)(X__Y, char *))(XSFUNCTION))(a,  c);},
                   "got XSFUNCTION call" ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test ATTRS keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "ATTRS basic",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |    ATTRS: a
                |           b     c(x)
                |    C_ARGS: foo
                |    ATTRS: d(y(  z))  
EOF
            [ 0, 0, qr{\QCV * cv;}, "has cv declaration" ],
            [ 0, 0, qr{\Qapply_attrs_string("Foo", cv, "a\E\s+b\s+c\(x\)\s+\Qd(y(  z))", 0);},
                   "has correct attrs arg" ],
        ],

    );

    test_many($preamble, 'boot_Foo', \@test_fns);
}


{
    # Test OVERLOAD keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "OVERLOAD basic",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |    OVERLOAD:   cmp   <=>
                |                  + - *    /
                |    OVERLOAD:   >   <  >=
EOF
            [ 0, 0, qr{\Q"Foo::(*"},   "has Foo::(* method"   ],
            [ 0, 0, qr{\Q"Foo::(+"},   "has Foo::(+ method"   ],
            [ 0, 0, qr{\Q"Foo::(-"},   "has Foo::(- method"   ],
            [ 0, 0, qr{\Q"Foo::(/"},   "has Foo::(/ method"   ],
            [ 0, 0, qr{\Q"Foo::(<"},   "has Foo::(< method"   ],
            [ 0, 0, qr{\Q"Foo::(<=>"}, "has Foo::(<=> method" ],
            [ 0, 0, qr{\Q"Foo::(>"},   "has Foo::(> method"   ],
            [ 0, 0, qr{\Q"Foo::(>="},  "has Foo::(>= method"  ],
            [ 0, 0, qr{\Q"Foo::(cmp"}, "has Foo::(cmp method" ],
        ],

    );

    test_many($preamble, 'boot_Foo', \@test_fns);
}


{
    # Test INIT: keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "INIT basic",
            [ Q(<<'EOF') ],
                |void
                |foo(aaa, short bbb)
                |    int aaa
                |  INIT:
                |     XXX
                |     YYY
                |  CODE:
                |     ZZZ
EOF
            [ 0, 0, qr{\bint\s+aaa},             "has aaa decl"   ],
            [ 0, 0, qr{\bshort\s+bbb},           "has bbb decl"   ],
            [ 0, 0, qr{^\s+XXX\n\s+YYY\n}m,      "has XXX, YYY"   ],
            [ 0, 0, qr{^\s+ZZZ\n}m,              "has ZZZ"        ],
            [ 0, 0, qr{aaa.*bbb.*XXX.*YYY.*ZZZ}s,"in sequence"    ],
        ],

    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test NOT_IMPLEMENTED_YET pseudo-keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
        |TYPEMAP: <<EOF
        |INPUT
        |T_UV
        |    set_uint($var, $arg)
        |EOF
EOF

    my @test_fns = (
        [
            "NOT_IMPLEMENTED_YET basic",
            [ Q(<<'EOF') ],
                |void
                |foo(int aaa, bbb, ccc)
                |    short bbb
                |    unsigned ccc
                |  NOT_IMPLEMENTED_YET
EOF
            [ 0, 0, qr{\QPerl_croak(aTHX_ "Foo::foo: not implemented yet");},
                    "has croak"   ],
            [ 0, 0, qr{\bint\s+aaa},             "has aaa decl"   ],
            [ 0, 0, qr{\bshort\s+bbb},           "has bbb decl"   ],
            [ 0, 0, qr{\bunsigned\s+ccc},        "has ccc decl"   ],
            [ 0, 0, qr{\Qset_uint(ccc, ST(2))},  "has ccc init"   ],
        ],
        [
            "NOT_IMPLEMENTED_YET no input part",
            [ Q(<<'EOF') ],
                |void
                |foo()
                |  NOT_IMPLEMENTED_YET
EOF
            [ 0, 0, qr{\QPerl_croak(aTHX_ "Foo::foo: not implemented yet");},
                    "has croak"   ],
            [ 0, 1, qr{NOT_IMPLEMENTED_YET},     "no NIY"         ],
        ],
        [
            "NOT_IMPLEMENTED_YET not special after C_ARGS",
            [ Q(<<'EOF') ],
                |void
                |foo(aaa)
                |    int aaa
                |  C_ARGS: a,b,
                |  NOT_IMPLEMENTED_YET
EOF
            [ 0, 1, qr{\QPerl_croak(aTHX_ "Foo::foo: not implemented yet");},
                    "doesn't has croak"   ],
            [ 0, 0, qr{\bint\s+aaa},                  "has aaa decl"         ],
            [ 0, 0, qr{a,b,\n\s+NOT_IMPLEMENTED_YET}, "NIY is part of C_ARGS"],
        ],
        [
            "NOT_IMPLEMENTED_YET not special after INIT",
            [ Q(<<'EOF') ],
                |void
                |foo(aaa)
                |    int aaa
                |  INIT:
                |    ZZZ
                |  NOT_IMPLEMENTED_YET
EOF
            [ 0, 1, qr{\QPerl_croak(aTHX_ "Foo::foo: not implemented yet");},
                    "doesn't has croak"   ],
            [ 0, 0, qr{\bint\s+aaa},                 "has aaa decl"     ],
            [ 0, 0, qr{ZZZ\n\s+NOT_IMPLEMENTED_YET}, "NIY is part of init code"          ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}

{
    # Test CLEANUP keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "CLEANUP basic",
            [ Q(<<'EOF') ],
                |int
                |foo(int aaa)
                |  CLEANUP:
                |     YYY
EOF
            [ 0, 0, qr{\bint\s+aaa},                  "has aaa decl"      ],
            [ 0, 0, qr{^\s+\QRETVAL = foo(aaa);}m,    "has code body"     ],
            [ 0, 0, qr{^\s+YYY\n}m,                   "has cleanup body" ],
            [ 0, 0, qr{aaa.*foo\(aaa\).*TARGi.*YYY}s, "in sequence"       ],
            [ 0, 0, qr{\#line 8 .*\n\s+YYY},          "correct #line"     ],
        ],
        [
             "CLEANUP empty",
             [ Q(<<'EOF') ],
                 |void
                 |foo(int aaa)
                 |  CLEANUP:
EOF
            [ 0, 0, qr{\bint\s+aaa},                  "has aaa decl"      ],
            [ 0, 0, qr{^\s+\Qfoo(aaa);}m,             "has code body"     ],
            [ 0, 0, qr{\Qfoo(aaa);\E\n\#line 8 },     "correct #line"     ],
         ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}



{
    # Test CODE keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "CODE basic",
            [ Q(<<'EOF') ],
                |void
                |foo(int aaa)
                |  CODE:
                |     YYY
EOF
            [ 0, 0, qr{\bint\s+aaa},           "has aaa decl"   ],
            [ 0, 0, qr{YYY},                   "has code body"  ],
            [ 0, 0, qr{aaa.*YYY}s,             "in sequence"    ],
            [ 0, 0, qr{\#line 8 .*\n\s+YYY},   "correct #line"  ],
        ],
        [
            "CODE empty",
            [ Q(<<'EOF') ],
                |void
                |foo(int aaa)
                |  CODE:
EOF
            [ 0, 0, qr{\bint\s+aaa},               "has aaa decl"   ],
            [ 0, 0, qr{aaa.*\n\s*;\s*\n\#line 8 }, "correct #line"  ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test PPCODE keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "PPCODE basic",
            [ Q(<<'EOF') ],
                |void
                |foo(int aaa)
                |  PPCODE:
                |     YYY
EOF
            [ 0, 0, qr{\bint\s+aaa},           "has aaa decl"   ],
            [ 0, 0, qr{YYY},                   "has code body"  ],
            [ 0, 0, qr{aaa.*YYY}s,             "in sequence"    ],
            [ 0, 0, qr{\#line 8 .*\n\s+YYY},   "correct #line"  ],
        ],
        [
            "PPCODE empty",
            [ Q(<<'EOF') ],
                |void
                |foo(int aaa)
                |  PPCODE:
EOF
            [ 0, 0, qr{\bint\s+aaa},               "has aaa decl"   ],
            [ 0, 0, qr{aaa.*\n\s*;\s*\n\#line 8 }, "correct #line"  ],
        ],
        [
            "PPCODE trailing keyword",
            [ Q(<<'EOF') ],
                |void
                |foo(int aaa)
                |  PPCODE:
                |     YYY
                |  OUTPUT:
                |     blah
EOF
            [ 1, 0, qr{Error: PPCODE must be the last thing}, "got expected err"  ],
        ],
        [
            "PPCODE code tweaks",
            [ Q(<<'EOF') ],
                |void
                |foo(int aaa)
                |  PPCODE:
                |     YYY
EOF
            [ 0, 0, qr{\QPERL_UNUSED_VAR(ax);},   "got PERL_UNUSED_VAR"    ],
            [ 0, 0, qr{\QSP -= items;},           "got SP -= items"        ],
            [ 0, 1, qr{\QXSRETURN},               "no XSRETURN"            ],
            [ 0, 0, qr{\bPUTBACK\b.*\breturn\b}s, "got PUTBACK and return" ],
        ],

    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}


{
    # Test POSTCALL keyword

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "POSTCALL basic",
            [ Q(<<'EOF') ],
                |int
                |foo(int aaa)
                |  POSTCALL:
                |     YYY
EOF
            [ 0, 0, qr{\bint\s+aaa},                  "has aaa decl"      ],
            [ 0, 0, qr{^\s+\QRETVAL = foo(aaa);}m,    "has code body"     ],
            [ 0, 0, qr{^\s+YYY\n}m,                   "has postcall body" ],
            [ 0, 0, qr{aaa.*foo\(aaa\).*YYY.*TARGi}s, "in sequence"       ],
            [ 0, 0, qr{\#line 8 .*\n\s+YYY},          "correct #line"     ],
        ],
        [
             "POSTCALL empty",
             [ Q(<<'EOF') ],
                 |void
                 |foo(int aaa)
                 |  POSTCALL:
EOF
            [ 0, 0, qr{\bint\s+aaa},                  "has aaa decl"      ],
            [ 0, 0, qr{^\s+\Qfoo(aaa);}m,             "has code body"     ],
            [ 0, 0, qr{\Qfoo(aaa);\E\n\#line 8 },     "correct #line"     ],
         ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}

{
    # Test C-preprocessor parsing

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "CPP basic",
            [ Q(<<'EOF') ],
                |#ifdef USE_SHORT
                |
                |short foo()
                |
                |#elif USE_LONG
                |
                |long foo()
                |
                |#else
                |
                |int foo()
                |
                |#endif
EOF
            [ 0, 0, qr{
                        ^ \#ifdef\ USE_SHORT \n
                        ^ \#define\ XSubPPtmpAAAA\ 1 \n

                         .*

                        ^ \s* short \s+ RETVAL; \s* \n

                         .*

                        ^ \#elif\ USE_LONG \n
                        ^ \#define\ XSubPPtmpAAAB\ 1 \n

                         .*

                        ^ \s* long \s+ RETVAL; \s* \n

                         .*

                        ^ \#else \n
                        ^ \#define\ XSubPPtmpAAAC\ 1 \n

                         .*

                        ^ \s* int \s+ RETVAL; \s* \n

                         .*
                        ^ \#endif \n

                      }smx,
                "has corrrect XSubPPtmpAAAA etc definitions"
            ],

            [ 0, 0, qr{
                        ^ \#if\ XSubPPtmpAAAA \n
                        .* newXS .*
                        ^ \#endif \n
                        ^ \#if\ XSubPPtmpAAAB \n
                        .* newXS .*
                        ^ \#endif \n
                        ^ \#if\ XSubPPtmpAAAC \n
                        .* newXS .*
                        ^ \#endif \n

                      }smx,
                "has corrrect XSubPPtmpAAAA etc boot usage"
            ],
        ],

        [
            "CPP two independent branches",
            [ Q(<<'EOF') ],
                |#ifdef USE_SHORT
                |short foo()
                |#endif
                |#if USE_LONG
                |long foo()
                |#endif
EOF
            [ 0, 0, qr{
                        ^ \#ifdef\ USE_SHORT \n
                        ^ \#define\ XSubPPtmpAAAA\ 1 \n
                         .*
                        ^ \s* short \s+ RETVAL; \s* \n
                         .*
                        ^ \#endif \n
                        ^ \#if\ USE_LONG \n
                        ^ \#define\ XSubPPtmpAAAB\ 1 \n
                         .*
                        ^ \s* long \s+ RETVAL; \s* \n
                         .*
                        ^ \#endif \n
                      }smx,
                    "ifdefs in order"  ],
        ],

        [
            "CPP one branch, one main",
            [ Q(<<'EOF') ],
                |#ifdef USE_SHORT
                |short foo()
                |#endif
                |long foo()
EOF
            [ 0, 0, qr{
                        ^ \#ifdef\ USE_SHORT \n
                        ^ \#define\ XSubPPtmpAAAA\ 1 \n
                         .*
                        ^ \s* short \s+ RETVAL; \s* \n
                         .*
                        ^ \#endif \n
                         .*
                        ^ \s* long \s+ RETVAL; \s* \n
                      }smx,
                    "ifdefs in order"  ],
        ],

        [
            "CPP two in one branch",
            [ Q(<<'EOF') ],
                |#ifdef USE_SHORT
                |short foo()
                |
                |long foo()
                |#endif
EOF
            [ 1, 0, qr{Warning: duplicate function definition},
                    "got expected warning"  ],
        ],

        [
            "CPP two in main",
            [ Q(<<'EOF') ],
                |short foo()
                |
                |long foo()
EOF
            [ 1, 0, qr{Warning: duplicate function definition},
                    "got expected warning"  ],
        ],

        [
            "CPP nested conditions",
            [ Q(<<'EOF') ],
                |#ifdef C1
                |
                |short foo()
                |
                |#ifdef C2
                |
                |long foo()
                |
                |#endif
                |
                |int foo()
                |
                |#endif
EOF
            [ 1, 0, qr{Warning: duplicate function definition},
                    "got expected warning"  ],
        ],

        [
            "CPP nested conditions, different fns",
            [ Q(<<'EOF') ],
                |#ifdef C1
                |
                |short foo()
                |
                |#ifdef C2
                |
                |long bar()
                |
                |#endif
                |
                |int baz()
                |
                |#endif
EOF
            [ 0, 0, qr{
                        ^ \#ifdef\ C1 \n
                        ^ \#define\ XSubPPtmpAAAB\ 1 \n
                         .*
                        ^ \s* short \s+ RETVAL; \s* \n
                         .*
                        ^ \#ifdef\ C2 \n
                        ^ \#define\ XSubPPtmpAAAA\ 1 \n
                         .*
                        ^ \s* long \s+ RETVAL; \s* \n
                         .*
                        ^ \#endif \n
                         .*
                        ^ \s* int \s+ RETVAL; \s* \n
                         .*
                        ^ \#endif \n
                      }smx,
                    "ifdefs in order"  ],
        ],

        [
            "CPP with indentation",
            [ Q(<<'EOF') ],
                |#ifdef C1
                |#  ifdef C2
                |long bar()
                |#  endif
                |#endif
EOF
            [ 0, 0, qr{
                        ^ \#ifdef\ C1 \n
                        ^ \#define\ XSubPPtmpAAAB\ 1 \n
                        ^ \s* \n
                        ^ \#\ \ ifdef\ C2 \n
                        ^ \#define\ XSubPPtmpAAAA\ 1 \n
                         .*
                        ^ \s* long \s+ RETVAL; \s* \n
                         .*
                        ^ \#\ \ endif \n
                        ^ \#endif \n
                      }smx,
                    "ifdefs in order"  ],
        ],

        [
            "CPP: trivial branch",
            [ Q(<<'EOF') ],
                |#ifdef C1
                |#define BLAH1
                |#endif
EOF
            [ 0, 1, qr{XSubPPtmpAAA}, "no guard"  ],
        ],

        [
            "CPP: guard and other CPP ordering",
            [ Q(<<'EOF') ],
                |#ifdef C1
                |#define BLAH1
                |
                |short foo()
                |
                |#endif
EOF

            [ 0, 0, qr{
                        ^ \#ifdef\ C1 \n
                         .*
                        ^ \#define\ XSubPPtmpAAAA\ 1 \n
                         .*
                        ^ \#define\ BLAH1\n
                         .*
                        ^ \s* short \s+ RETVAL; \s* \n
                         .*
                        ^ \#endif \n
                      }smx,
                    "ifdefs in order"  ],
        ],

        [
            "CPP balanced else",
            [ Q(<<'EOF') ],
                |#else
                |
                |short foo()
EOF
            [ 1, 0, qr{Error: 'else' with no matching 'if'},
                    "got expected err"  ],
        ],

        [
            "CPP balanced if",
            [ Q(<<'EOF') ],
                |#ifdef
                |
                |short foo()
EOF
            [ 1, 0, qr{Error: Unterminated '#if/#ifdef/#ifndef'},
                    "got expected err"  ],
        ],

        [
            "stray CPP / indented XSUB",
            [ Q(<<'EOF') ],
                |#define FOO
                |  int
EOF
            [ 1, 0, qr{\QCode is not inside a function\E
                       \Q (maybe last function was ended by a blank line \E
                       \Q followed by a statement on column one?)\E
                      }x,
                    "got expected err"  ],
        ],


    );

    test_many($preamble, undef, \@test_fns);
}


{
    # Check for correct package name; i.e. use the current package name,
    # not the last one seen in the file.

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
        |TYPEMAP: <<EOTM
        |foo_t T_FOO
        |INPUT
        |T_FOO
        |    $var = in_foo($arg, "$Package")
        |OUTPUT
        |T_FOO
        |    out_foo($arg, $var, "$Package")
        |EOTM
        |
EOF

    my @test_fns = (
        [
            'typemap: $Package: one package',
            [ Q(<<'EOF') ],
                |foo_t foo(foo_t a1)
EOF

            [ 0, 0, qr{
                        foo_t \s+ \Qa1 = in_foo(ST(0), "Foo")\E
                        .*
                        \Qout_foo(RETVALSV, RETVAL, "Foo")\E
                      }smx,
                "has corrrect Package"
            ],
        ],
        [
            'typemap: $Package: two packages',
            [ Q(<<'EOF') ],
                |foo_t foo(foo_t a1)
                |
                |MODULE = Foo PACKAGE = Foo::Bar
                |
                |int blah()
EOF

            [ 0, 0, qr{
                        foo_t \s+ \Qa1 = in_foo(ST(0), "Foo")\E
                        .*
                        \Qout_foo(RETVALSV, RETVAL, "Foo")\E
                      }smx,
                "has corrrect Package"
            ],
        ],
    );

    test_many($preamble, 'XS_Foo_', \@test_fns);
}

{
    # Check for correct package name in boot code; i.e. use the current
    # package name, not the last one seen in the file.

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            'attr: one package',
            [ Q(<<'EOF') ],
                |int
                |foo()
                |ATTRS: myattr(x)
EOF

            [ 0, 0, qr{\Qapply_attrs_string("Foo", cv, "myattr(x)", 0)},
                "has corrrect package"
            ],
        ],
        [
            'attr: two packages',
            [ Q(<<'EOF') ],
                |int
                |foo()
                |ATTRS: myattr(x)
                |
                |MODULE = Foo PACKAGE = Foo::Bar
                |
                |int blah()
EOF

            [ 0, 0, qr{\Qapply_attrs_string("Foo", cv, "myattr(x)", 0)},
                "has corrrect package"
            ],
        ],

        [
            'interface: one package',
            [ Q(<<'EOF') ],
                |int
                |foo()
                |INTERFACE: abc
EOF

            [ 0, 0, qr{\QnewXS_deffile("Foo::abc", XS_Foo_foo)},
                "has corrrect package"
            ],
        ],
        [
            'interface: two packages',
            [ Q(<<'EOF') ],
                |int
                |foo()
                |INTERFACE: abc
                |
                |MODULE = Foo PACKAGE = Foo::Bar
                |
                |int blah()
EOF

            [ 0, 0, qr{\QnewXS_deffile("Foo::abc", XS_Foo_foo)},
                "has corrrect package"
            ],
        ],

        [
            'overload: one package',
            [ Q(<<'EOF') ],
                |int
                |foo()
                |OVERLOAD: cmp
EOF

            [ 0, 0, qr{\QnewXS_deffile("Foo::(cmp", XS_Foo_foo)},
                "has corrrect package"
            ],
        ],
        [
            'overload: two packages',
            [ Q(<<'EOF') ],
                |int
                |foo()
                |OVERLOAD: cmp
                |
                |MODULE = Foo PACKAGE = Foo::Bar
                |
                |int blah()
EOF

            [ 0, 0, qr{\QnewXS_deffile("Foo::(cmp", XS_Foo_foo)},
                "has corrrect package"
            ],
        ],

    );

    test_many($preamble, 'boot_Foo', \@test_fns);
}

{
    # Test reporting of bad syntax on MODULE lines.

    my $preamble = Q(<<'EOF');
EOF

    my @test_fns = (
        [
            '1st MODULE PKG',
            [ Q(<<'EOF') ],
                |MODULE = X PKG = Y
                |
                |PROTOTYPES:  DISABLE
                |
EOF

            [ 1, 0, qr{Error: unparseable MODULE line: 'MODULE = X PKG = Y'},
                "got expected err msg"
            ],
        ],
        [
            '1st MODULE colon',
            [ Q(<<'EOF') ],
                |MODULE: X PACKAGE = Y
                |
                |PROTOTYPES:  DISABLE
                |
EOF

            [ 1, 0, qr{Error: unparseable MODULE line: 'MODULE: X PACKAGE = Y'},
                "got expected err msg"
            ],
        ],
        [
            '2nd MODULE PKG',
            [ Q(<<'EOF') ],
                |MODULE = Foo PACKAGE = Foo
                |
                |PROTOTYPES:  DISABLE
                |
                |MODULE = X PKG = Y
EOF

            [ 1, 0, qr{Error: unparseable MODULE line: 'MODULE = X PKG = Y'},
                "got expected err msg"
            ],
        ],
        [
            '2nd MODULE colon',
            [ Q(<<'EOF') ],
                |MODULE = Foo PACKAGE = Foo
                |
                |PROTOTYPES:  DISABLE
                |
                |MODULE: X PACKAGE = Y
EOF

            [ 1, 0, qr{Error: unparseable MODULE line: 'MODULE: X PACKAGE = Y'},
                "got expected err msg"
            ],
        ],
    );

    test_many($preamble, undef, \@test_fns);
}


{
    # Test reporting of bad syntax on TYPEMAP lines.

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            'TYPEMAP syntax err',
            [ Q(<<'EOF') ],
                |TYPEMAP: <EOF
                |
EOF

            [ 1, 0, qr{Error: unparseable TYPEMAP line: 'TYPEMAP: <EOF'},
                "got expected err msg"
            ],
        ],
        [
            "line continuation directly after TYPEMAP",
            [ Q(<<'EOF') ],
                |TYPEMAP: <<EOF
                |
                |foo_t T_FOO
                |
                |EOF
                |void foo(int i, \
                |         int j)
EOF

            [ 0, 0, qr{XS}, "no errs" ],
        ],
    );

    test_many($preamble, undef, \@test_fns);
}


{
    # Test POD

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "POD at EOF doesn't warn",
            [ Q(<<'EOF') ],
                |void foo()
                |
                |=pod
                |=cut
EOF

            [ 0, 0, qr{XS}, "no undef warning" ],
        ],
        [
            "line continuation directly after POD",
            [ Q(<<'EOF') ],
                |=pod
                |=cut
                |void foo(int i, \
                |         int j)
EOF

            [ 0, 0, qr{XS}, "no errs" ],
        ],
    );

    test_many($preamble, undef, \@test_fns);
}

{
    # Test standard C file preamble
    # check that a few standard lines are present

    my $preamble = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES:  DISABLE
        |
EOF

    my @test_fns = (
        [
            "C preamble",
            [ Q(<<'EOF') ],
                |void foo()
EOF

            [ 0, 0, qr{#ifndef PERL_UNUSED_VAR}, "PERL_UNUSED_VAR" ],
            [ 0, 0, qr{#ifndef PERL_ARGS_ASSERT_CROAK_XS_USAGE},
                        "PERL_ARGS_ASSERT_CROAK_XS_USAGE" ],
            [ 0, 0, qr{#ifdef newXS_flags}, "newXS_flags" ],
        ],
    );

    test_many($preamble, undef, \@test_fns);
}

{
    # An XS file without a MODULE line should warn, but
    # still emit the C code in the C part of the file (the whole file
    # contents in this case).

    my $preamble = '';

    my @test_fns = (
        [
            "No MODULE line",
            [ Q(<<'EOF') ],
                |foo
                |bar
EOF

            [ 0, 0, qr{#line 1 ".*"\nfoo\nbar\n#line 13 ".*"}, "all C present" ],
            [ 1, 0, qr{Didn't find a 'MODULE ... PACKAGE ... PREFIX' line},
                    "got expected MODULE warning"  ],
        ],
    );

    test_many($preamble, undef, \@test_fns);
}

done_testing;
