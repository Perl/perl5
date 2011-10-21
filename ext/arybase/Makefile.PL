use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'arybase',
    VERSION_FROM  => 'arybase.pm',
    ABSTRACT_FROM => 'arybase.pm',
    realclean     => { FILES => "" },
);

# To work around nmake stupidity.  See rt.cpan.org #71847.
package MY;
sub ppd {
 my $stuff = SUPER::ppd{} @_;
 $stuff =~ s/ \$\[/ \$\$[/;
 $stuff;
}
