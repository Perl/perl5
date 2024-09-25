#!/usr/bin/perl

use strict;
use Test::More tests => 77;
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

$ExtUtils::ParseXS::DIE_ON_ERROR = 1;
$ExtUtils::ParseXS::AUTHOR_WARNINGS = 1;

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
like $stderr, '/No INPUT definition/', "Exercise typemap error";
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
    TODO: {
      local $TODO = 'GH 19661';
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
    TODO: {
      local $TODO = 'GH 19661';
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
  my $stderr = PrimitiveCapture::capture_stderr(sub {
    $pxs->process_file(
      filename => 'XSAlias.xs',
      output => \*FH,
      prototypes => 1);
  });
  my $content = tied(*FH)->{buf};
  my $count = 0;
  $count++ while $content=~/^XS_EUPXS\(XS_My_do\)\n\{/mg;
  is $stderr,
    "Warning: Aliases 'pox' and 'dox', 'lox' have"
    . " identical values of 1 in XSAlias.xs, line 9\n"
    . "    (If this is deliberate use a symbolic alias instead.)\n"
    . "Warning: Conflicting duplicate alias 'pox' changes"
    . " definition from '1' to '2' in XSAlias.xs, line 10\n"
    . "Warning: Aliases 'docks' and 'dox', 'lox' have"
    . " identical values of 1 in XSAlias.xs, line 11\n"
    . "Warning: Aliases 'xunx' and 'do' have identical values"
    . " of 0 - the base function in XSAlias.xs, line 13\n"
    . "Warning: Aliases 'do' and 'xunx', 'do' have identical values"
    . " of 0 - the base function in XSAlias.xs, line 14\n"
    . "Warning: Aliases 'xunx2' and 'do', 'xunx' have"
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
    "Warning: Conflicting duplicate alias 'pox' changes"
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
        if ($line=~/\(also known as C<xsubpp>\)\s+(\d+\.\d+)/) {
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

    like($stderr, qr/No INPUT definition for type 'Foo::Bar'/,
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
EOF

    tie *FH, 'Capture';
    my $stderr = PrimitiveCapture::capture_stderr(sub {
        $pxs->process_file( filename => \$text, output => \*FH);
    });

    for my $var (qw(a b c)) {
        my $count = () =
            $stderr =~ /duplicate definition of argument '$var'/g;
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

    like $stderr, qr{\Qparameter type not allowed under -noargtypes},
                 "no type under -noargtypes";
    like $stderr, qr{\Qlength() pseudo-parameter not allowed under -noargtypes},
                 "no length under -noargtypes";
    like $stderr, qr{\Qparameter IN/OUT modifier not allowed under -noinout},
                 "no IN/OUT under -noinout";
    like $stderr, qr{\QUnparseable XSUB parameter: '+++'},
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

    like $stderr, qr{\Qfurther XSUB parameter seen after ellipsis},
                 "further XSUB parameter seen after ellipsis";
}

{
    # Test for CLASS/THIS in C++ XSUBs

    my $pxs = ExtUtils::ParseXS->new;
    my $text = Q(<<'EOF');
        |MODULE = Foo PACKAGE = Foo
        |
        |PROTOTYPES: DISABLE
        |
        |TYPEMAP: <<EOF
        |color *  O_OBJECT
        |INPUT
        |O_OBJECT
        |    something($arg)
        |EOF
        |
        |
        |void
        |color::new(int aaa)
        |
        |void
        |color::f(int bbb)
        |
        |void
        |mymarker()
EOF

    tie *FH, 'Capture';
    $pxs->process_file( filename => \$text, output => \*FH);

    my $out = tied(*FH)->content;

    # trim the output to just the function in question to make
    # test diagnostics smaller.
    $out =~ s/\A.*? (XS_Foo_new .*? XS_Foo_mymarker).*\z/$1/xms
        or die "couldn't trim output";

    like $out, qr/\Qnew color(aaa)/,                "C++ XSUB: wrapped new";
    like $out, qr/\QTHIS->f(bbb)/,                  "C++ XSUB: wrapped THIS";
    like $out, qr/\Qusage(cv,\E\s+\Q"CLASS, aaa")/, "C++ XSUB: usage new";
    like $out, qr/\Qusage(cv,\E\s+\Q"THIS, bbb")/,  "C++ XSUB: usage THIS";
}
