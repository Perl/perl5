#!../miniperl -w

BEGIN {
    @INC = qw(../win32 ../lib);
    require './test.pl';
    skip_all('FindExt not portable')
	if $^O eq 'VMS';
}
use strict;
use Config;

# Test that Win32/FindExt.pm is consistent with Configure in determining the
# types of extensions.

if ($^O eq "MSWin32" && !defined $ENV{PERL_STATIC_EXT}) {
    skip_all "PERL_STATIC_EXT must be set to the list of static extensions";
}

unless (defined $Config{usedl}) {
    skip_all "FindExt just plain broken for static perl.";
}

plan tests => 12;
require FindExt;

FindExt::apply_config(\%Config);
FindExt::scan_ext("../$_")
    foreach qw(cpan dist ext);
FindExt::set_static_extensions(split ' ', $^O eq 'MSWin32'
                               ? $ENV{PERL_STATIC_EXT} : $Config{static_ext});

sub compare {
    my ($desc, $want, @have) = @_;
    $want = [sort split ' ', $want]
        unless ref $want eq 'ARRAY';
    local $::Level = $::Level + 1;
    is(scalar @have, scalar @$want, "We find the same number of $desc");
    is("@have", "@$want", "We find the same list of $desc");
}

# Config.pm and FindExt.pm make different choices about what should be built
my @config_built;
my @found_built;
{
    foreach my $type (qw(static dynamic nonxs)) {
	push @found_built, eval "FindExt::${type}_ext()";
	push @config_built, split ' ', $Config{"${type}_ext"};
    }
}
@config_built = sort @config_built;
@found_built = sort @found_built;

foreach (['dynamic_ext',
          [FindExt::dynamic_ext()], $Config{dynamic_ext}],
         ['static_ext',
	  [FindExt::static_ext()], $Config{static_ext}],
	 ['nonxs_ext',
	  [FindExt::nonxs_ext()], $Config{nonxs_ext}],
	 ['known_extensions',
	  [FindExt::known_extensions()], $Config{known_extensions}],
	 ['"config" dynamic + static + nonxs',
	  \@config_built, $Config{extensions}],
	 ['"found" dynamic + static + nonxs', 
	  \@found_built, [FindExt::extensions()]],
	) {
    my ($type, $found, $config) = @$_;
    compare($type, $config, @$found);
}

# Local variables:
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# ex: set ts=8 sts=4 sw=4 et:
