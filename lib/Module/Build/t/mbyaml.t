#!/usr/local/bin/perl -w

use strict;
use lib $ENV{PERL_CORE} ? '../lib/Module/Build/t/lib' : 't/lib';
use MBTest 'no_plan';

my ($dir);
$dir = ".";
$dir = "t" if (-d "t");

{
  use_ok("Module::Build::YAML");
  my ($expected, $got, $var);
  $var = {
          'resources' => {
                           'license' => 'http://opensource.org/licenses/artistic-license.php'
                         },
          'meta-spec' => {
                           'version' => '1.2',
                           'url' => 'http://module-build.sourceforge.net/META-spec-v1.2.html'
                         },
          'generated_by' => 'Module::Build version 0.2709',
          'version' => '0.13',
          'name' => 'js-app',
          'dynamic_config' => '1',
          'author' => [
                        '"Stephen Adkins" <spadkins@gmail.com>'
                      ],
          'license' => 'lgpl',
          'build_requires' => {
                                'App::Build' => '0',
                                'File::Spec' => '0',
                                'Module::Build' => '0'
                              },
          'provides' => {
                          'JavaScript::App' => {
                                                 'version' => '0',
                                                 'file' => 'lib/JavaScript/App.pm'
                                               }
                        },
          'requires' => {
                          'App::Options' => '0'
                        },
          'abstract' => 'A framework for building dynamic widgets or full applications in Javascript'
        };
  $expected = <<EOF;
---
abstract: A framework for building dynamic widgets or full applications in Javascript
author:
  - '"Stephen Adkins" <spadkins\@gmail.com>'
build_requires:
  App::Build: 0
  File::Spec: 0
  Module::Build: 0
dynamic_config: 1
generated_by: Module::Build version 0.2709
license: lgpl
meta-spec:
  url: http://module-build.sourceforge.net/META-spec-v1.2.html
  version: 1.2
name: js-app
provides:
  JavaScript::App:
    file: lib/JavaScript/App.pm
    version: 0
requires:
  App::Options: 0
resources:
  license: http://opensource.org/licenses/artistic-license.php
version: 0.13
EOF
    $got = &Module::Build::YAML::Dump($var);
    is($got, $expected, "Dump(): single deep hash");

  $expected = <<EOF;
---
name: js-app
version: 0.13
author:
  - '"Stephen Adkins" <spadkins\@gmail.com>'
abstract: A framework for building dynamic widgets or full applications in Javascript
license: lgpl
resources:
  license: http://opensource.org/licenses/artistic-license.php
requires:
  App::Options: 0
build_requires:
  App::Build: 0
  File::Spec: 0
  Module::Build: 0
dynamic_config: 1
provides:
  JavaScript::App:
    file: lib/JavaScript/App.pm
    version: 0
generated_by: Module::Build version 0.2709
meta-spec:
  url: http://module-build.sourceforge.net/META-spec-v1.2.html
  version: 1.2
EOF
    $var->{_order} = [qw(name version author abstract license resources requires build_requires dynamic_config provides)];
    $got = &Module::Build::YAML::Dump($var);
    is($got, $expected, "Dump(): single deep hash, ordered");

    $var = [
        "e",
        2.71828,
        [ "pi", "is", 3.1416 ],
        { fun => "under_sun", 6 => undef, "more", undef },
    ];
    $expected = <<EOF;
---
e
---
2.71828
---
- pi
- is
- 3.1416
---
6: ""
fun: under_sun
more: ""
EOF
    $got = &Module::Build::YAML::Dump(@$var);
    is($got, $expected, "Dump(): multiple, various");

    $expected = <<EOF;
---
- e
- 2.71828
-
  - pi
  - is
  - 3.1416
-
  6: ""
  fun: under_sun
  more: ""
EOF
    $got = &Module::Build::YAML::Dump($var);
    is($got, $expected, "Dump(): single array of various");

    my $y = Module::Build::YAML->new();
    $got = $y->Dump($var);
    is($got, $expected, "Dump(): single array of various (OO)");
}


