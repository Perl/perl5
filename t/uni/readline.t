#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

plan tests => 9;

use utf8;
use open qw( :utf8 :std );

# [perl #19566]: sv_gets writes directly to its argument via
# TARG. Test that we respect SvREADONLY.
use constant roref=>\2;
{
    no warnings 'once';
    my @these_warnings = ();
    local $SIG{__WARN__} = sub { push @these_warnings, $_[0]; };
    eval { for (roref) { $_ = <Fʜ> } };
    like($@, qr/Modification of a read-only value attempted/, '[perl #19566]');
    my $warnings_count = 0;
    for my $w (@these_warnings) {
        chomp $w;
        if ($w =~ m/^readline\(\) on unopened filehandle/) {
            $warnings_count++;
        }
    }
    is($warnings_count, 1,
        "Got expected number of 'unopened' warnings");
}

# [perl #21628]
{
  my $file = tempfile();
  open Ạ,'+>',$file; $a = 3;
  is($a .= <Ạ>, 3, '#21628 - $a .= <A> , A eof');
  close Ạ; $a = 4;
  #no warnings 'closed';
  my $thiswarn = '';
  local $SIG{__WARN__} = sub { $thiswarn .= $_[0]; };
  is($a .= <Ạ>, 4, '#21628 - $a .= <A> , A closed');
  like($thiswarn, qr/readline\(\) on closed filehandle Ạ/,
      "Got expected warning for readline on closed filehandle");
}

use strict;
my $err;
{
  open ᕝ, '.' and binmode ᕝ and sysread ᕝ, $_, 1;
  $err = $! + 0;
  close ᕝ;
}

SKIP: {
  skip "you can read directories as plain files", 2 unless( $err );

  $!=0;
  open ᕝ, '.' and $_=<ᕝ>;
  ok( $!==$err && !defined($_) => 'readline( DIRECTORY )' );
  close ᕝ;

  $!=0;
  { local $/;
    open ᕝ, '.' and $_=<ᕝ>;
    ok( $!==$err && !defined($_) => 'readline( DIRECTORY ) slurp mode' );
    close ᕝ;
  }
}

my $obj = bless [], "Ȼლᔆ";
$obj .= <DATA>;
like($obj, qr/Ȼლᔆ=ARRAY.*world/u, 'rcatline and refs');

{
    my $file = tempfile();
    open my $out_fh, ">", $file;
    print { $out_fh } "Data\n";
    close $out_fh;

    open hòฟ, "<", $file;
    is( scalar(<hòฟ>), "Data\n", "readline() works correctly on UTF-8 filehandles" );
    close hòฟ;
}

__DATA__
world
