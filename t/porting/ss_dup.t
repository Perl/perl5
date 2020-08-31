#!perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    require Config; Config->import;
}
our @TODO = qw [ SAVEt_SAVESWITCHSTACK ];
our %TODO;
@TODO{@TODO} = ();

if ( $Config{usecrosscompile} ) {
  skip_all( "Not all files are available during cross-compilation" );
}

sub read_cases {
  my ($file, $func) = @_;

  open my $fh, $file or die "$0 cannot open $file: $!";

  while (readline $fh) {
    last if /^Perl_$func/;
  }
  my %found;
  while (readline $fh) {
    last if /^}/;
    $found{$1}++ if /case (SAVEt_\w*):/;
  }
  close $fh or die "$0 cannot close $file: $!";
  \%found;
}

my $leave_scope = read_cases "../scope.c", "leave_scope";
my $ss_dup      = read_cases "../sv.c",    "ss_dup";

ok scalar %$leave_scope, 'we got some';

for (sort keys %$leave_scope) {
  local $::TODO = ' ' if exists $TODO{$_};
  ok exists $$ss_dup{$_}, "ss_dup handles $_";
}

done_testing;
