
package Memoize::ExpireFile;
use Carp;

sub TIEHASH {
  my ($package, %args) = @_;
  my %cache;
  if ($args{TIE}) {
    my ($module, @opts) = @{$args{TIE}};
    my $modulefile = $module . '.pm';
    $modulefile =~ s{::}{/}g;
    eval { require $modulefile };
    if ($@) {
      croak "Memoize::ExpireFile: Couldn't load hash tie module `$module': $@; aborting";
    }
    my $rc = (tie %cache => $module, @opts);
    unless ($rc) {
      croak "Memoize::ExpireFile: Couldn't tie hash to `$module': $@; aborting";
    }
  }
  bless {ARGS => \%args, C => \%cache} => $package;
}


sub STORE {
  my ($self, $key, $data) = @_;
  my $cache = $self->{C};
  my $cur_date = pack("N", (stat($key))[9]);
  $cache->{"C$key"} = $data;
  $cache->{"T$key"} = $cur_date;
}

sub FETCH {
  my ($self, $key) = @_;
  $self->{C}{"C$key"};
}

sub EXISTS {
  my ($self, $key) = @_;
  my $old_date = $self->{C}{"T$key"} || "0";
  my $cur_date = pack("N", (stat($key))[9]);
  if ($self->{ARGS}{CHECK_DATE} && $old_date gt $cur_date) {
    return $self->{ARGS}{CHECK_DATE}->($key, $old_date, $cur_date);
  } 
  return $old_date ge $cur_date;
}

1;
