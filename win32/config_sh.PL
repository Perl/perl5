# take a semicolon separated path list and turn it into a quoted
# list of paths that Text::Parsewords will grok
sub mungepath {
    my $p = shift;
    # remove leading/trailing semis/spaces
    $p =~ s/^[ ;]+//;
    $p =~ s/[ ;]+$//;
    $p =~ s/'/"/g;
    my @p = map { $_ = "\"$_\"" if /\s/ and !/^".*"$/; $_ } split /;/, $p;
    return join(' ', @p);
}

my %opt;
while (@ARGV && $ARGV[0] =~ /^([\w_]+)=(.*)$/)
 {
  $opt{$1}=$2;
  shift(@ARGV);
 }

$opt{VERSION} = $];
$opt{INST_VER} =~ s|~VERSION~|$]|g;
if ($] =~ /^(\d+)\.(\d\d\d)?(\d\d)?$/) { # should always be true
  $opt{PERL_REVISION} = $1;
  $opt{PERL_VERSION} = int($2 || 0);
  $opt{PERL_SUBVERSION} = $3 || '00';
}
else {
  die "Can't parse perl version ($])";
}

$opt{'cf_by'} = $ENV{USERNAME} unless $opt{'cf_by'};
$opt{'cf_email'} = $opt{'cf_by'} . '@' . (gethostbyname('localhost'))[0]
	unless $opt{'cf_email'};
$opt{'usemymalloc'} = 'y' if $opt{'d_mymalloc'} eq 'define';

$opt{libpth} = mungepath($opt{libpth}) if exists $opt{libpth};
$opt{incpath} = mungepath($opt{incpath}) if exists $opt{incpath};

while (<>)
 {
  s/~([\w_]+)~/$opt{$1}/g;
  if (/^([\w_]+)=(.*)$/) {
    my($k,$v) = ($1,$2);
    # this depends on cf_time being empty in the template (or we'll get a loop)
    if ($k eq 'cf_time') {
      $_ = "$k='" . localtime(time) . "'\n" if $v =~ /^\s*'\s*'/;
    }
    elsif (exists $opt{$k}) {
      $_ = "$k='$opt{$k}'\n";
    }
  }
  print;
 }

