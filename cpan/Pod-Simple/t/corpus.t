# Testing a corpus of Pod files
use strict;
use warnings;

use Test::More;
BEGIN {
    use Config;
    if ($Config{extensions} !~ /\bEncode\b/) {
      plan skip_all => "Encode was not built";
    }
    if (ord("A") != 65) {
      plan skip_all => "Encode not fully working on non-ASCII platforms at this time";
    }
}

#use Pod::Simple::Debug (10);

use File::Spec;
use File::Basename ();

my(@testfiles, %xmlfiles, %wouldxml);
#use Pod::Simple::Debug (10);
BEGIN {
  my $corpusdir = File::Spec->catdir(File::Basename::dirname(File::Spec->rel2abs(__FILE__)), 'corpus');
  note "Corpusdir: $corpusdir";

  opendir(my $indir, $corpusdir) or die "Can't opendir $corpusdir : $!";
  my @f = map File::Spec::->catfile($corpusdir, $_), readdir($indir);
  closedir($indir);
  my %f;
  @f{@f} = ();
  foreach my $maybetest (sort @f) {
    my $xml = $maybetest;
    $xml =~ s/\.(txt|pod)$/\.xml/is  or  next;
    $wouldxml{$maybetest} = $xml;
    push @testfiles, $maybetest;
    foreach my $x ($xml, uc($xml), lc($xml)) {
      next unless exists $f{$x};
      $xmlfiles{$maybetest} = $x;
      last;
    }
  }
  die "Too few test files (".@testfiles.")" unless @ARGV or @testfiles > 20;

  @testfiles = @ARGV if @ARGV and !grep !m/\.txt/, @ARGV;

  plan tests => (2*@testfiles - 1);
}

my $HACK = 0;
# 1: write generated XML dump to *.xml_out files for debugging
# 2: write generated XML to *.xml files, updating/overwriting test corpus

#@testfiles = ('nonesuch.txt');

{
  my @x = @testfiles;
  note "Files to test:";
  while(@x) { note " ", join(' ', splice @x,0,3); }
}

require Pod::Simple::DumpAsXML;


foreach my $f (@testfiles) {
  my $xml = $xmlfiles{$f};
  note "";
  if($xml) {
    note "To test $f against $xml";
  } else {
    note "$f has no xml to test it against";
  }

  my $outstring;
  eval {
    my $p = Pod::Simple::DumpAsXML->new;
    $p->output_string( \$outstring );
    $p->parse_file( $f );
    undef $p;
  };

  is $@, '', "parsed $f without error" or do {
    ok 0;
    next;
  };

  note "generated " . length($outstring) . " bytes";

  die "Null outstring?" unless $outstring;

  next if $f =~ /nonesuch/;

  my $outfilename = ($HACK > 1) ? $wouldxml{$f} : "$wouldxml{$f}\_out";
  if($HACK) {
    open my $out, ">", $outfilename or die "Can't write-open $outfilename: $!\n";
    binmode($out);
    print $out $outstring;
    close($out);
  }
  unless($xml) {
    note " (no comparison done)";
    ok 1;
    next;
  }

  open(my $in, "<", $xml) or die "Can't read-open $xml: $!";
  #binmode(IN);
  local $/;
  my $xmlsource = <$in>;
  close($in);

  note "There's errata!" if $outstring =~ m/start_line="-321"/;

  $xmlsource =~ s/[\n\r]+/\n/g;
  $outstring =~ s/[\n\r]+/\n/g;
  ok $xmlsource eq $outstring, "perfect match to $xml" or do {
    diag `diff $xml $outfilename` if $HACK;
  };

  unlink $outfilename if $HACK == 1;
}
