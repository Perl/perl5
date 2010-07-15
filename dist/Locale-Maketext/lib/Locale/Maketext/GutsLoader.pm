package Locale::Maketext::GutsLoader;

use Locale::Maketext;

sub zorp { return scalar @_ }

=head1 NAME

Locale::Maketext::GutsLoader - Deprecated module to load Locale::Maketext utf8 code

=head1 SYNOPSIS

  # Do this instead please
  use Locale::Maketext

=head1 DESCRIPTION

Previously majic was done to load Locale::Maketext when utf8 was unavailable. The subs this module provided were merged back into Locale::Maketext

=cut

1;
