####!./perl


my %Expect;
my $symlink_exists = eval { symlink("",""); 1 };

BEGIN {
    chdir 't' if -d 't';
    unshift @INC, '../lib';
}

if ( $symlink_exists ) { print "1..59\n"; }
else                   { print "1..31\n"; }

use File::Find;

find(sub { print "ok 1\n" if $_ eq 'filefind.t'; }, ".");
finddepth(sub { print "ok 2\n" if $_ eq 'filefind.t'; }, ".");


my $case = 2;

END {
    unlink 'FA/FA_ord','FA/FSL','FA/FAA/FAA_ord',
	   'FA/FAB/FAB_ord','FA/FAB/FABA/FABA_ord','FB/FB_ord','FB/FBA/FBA_ord';
    rmdir 'FA/FAA';
    rmdir 'FA/FAB/FABA';
    rmdir 'FA/FAB';
    rmdir 'FA';
    rmdir 'FB/FBA';
    rmdir 'FB';
}

sub Check($) {
  $case++;
  if ($_[0]) { print "ok $case\n"; }
  else       { print "not ok $case\n"; }
}

sub CheckDie($) {
  $case++;
  if ($_[0]) { print "ok $case\n"; }
  else { print "not ok $case\n $!\n"; exit 0; }
}

sub touch {
  CheckDie( open(my $T,'>',$_[0]) );
}

sub MkDir($$) {
  CheckDie( mkdir($_[0],$_[1]) );
}

sub wanted {
  print "# '$_' => 1\n";
  Check( $Expect{$_} );
  delete $Expect{$_};
  $File::Find::prune=1 if  $_ eq 'FABA';
}

MkDir( 'FA',0770 );
MkDir( 'FB',0770  );
touch('FB/FB_ord');
MkDir( 'FB/FBA',0770  );
touch('FB/FBA/FBA_ord');
CheckDie( symlink('../FB','FA/FSL') ) if $symlink_exists;
touch('FA/FA_ord');

MkDir( 'FA/FAA',0770  );
touch('FA/FAA/FAA_ord');
MkDir( 'FA/FAB',0770  );
touch('FA/FAB/FAB_ord');
MkDir( 'FA/FAB/FABA',0770  );
touch('FA/FAB/FABA/FABA_ord');

%Expect = ('.' => 1, 'FSL' => 1, 'FA_ord' => 1, 'FAB' => 1, 'FAB_ord' => 1,
	   'FABA' => 1, 'FAA' => 1, 'FAA_ord' => 1);
delete $Expect{'FSL'} unless $symlink_exists;
File::Find::find( {wanted => \&wanted, },'FA' );
Check( scalar(keys %Expect) == 0 );

%Expect=('FA' => 1, 'FA/FSL' => 1, 'FA/FA_ord' => 1, 'FA/FAB' => 1,
	 'FA/FAB/FAB_ord' => 1, 'FA/FAB/FABA' => 1,
	 'FA/FAB/FABA/FABA_ord' => 1, 'FA/FAA' => 1, 'FA/FAA/FAA_ord' => 1);
delete $Expect{'FA/FSL'} unless $symlink_exists;
File::Find::find( {wanted => \&wanted, no_chdir => 1},'FA' );

Check( scalar(keys %Expect) == 0 );

if ( $symlink_exists ) {
  %Expect=('.' => 1, 'FA_ord' => 1, 'FSL' => 1, 'FB_ord' => 1, 'FBA' => 1, 
           'FBA_ord' => 1, 'FAB' => 1, 'FAB_ord' => 1, 'FABA' => 1, 'FAA' => 1,
           'FAA_ord' => 1);

  File::Find::find( {wanted => \&wanted, follow_fast => 1},'FA' );
  Check( scalar(keys %Expect) == 0 );
  %Expect=('FA' => 1, 'FA/FA_ord' => 1, 'FA/FSL' => 1, 'FA/FSL/FB_ord' => 1,
           'FA/FSL/FBA' => 1, 'FA/FSL/FBA/FBA_ord' => 1, 'FA/FAB' => 1,
           'FA/FAB/FAB_ord' => 1, 'FA/FAB/FABA' => 1, 'FA/FAB/FABA/FABA_ord' => 1,
           'FA/FAA' => 1, 'FA/FAA/FAA_ord' => 1);
  File::Find::find( {wanted => \&wanted, follow_fast => 1, no_chdir => 1},'FA' );
  Check( scalar(keys %Expect) == 0 );
}

print "# of cases: $case\n";
