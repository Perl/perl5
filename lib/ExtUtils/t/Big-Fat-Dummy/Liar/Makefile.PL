use ExtUtils::MakeMaker;

my $mm = WriteMakefile(
              NAME => 'Big::Fat::Liar',
              VERSION_FROM => 'lib/Big/Fat/Liar.pm',
              _KEEP_AFTER_FLUSH => 1
             );

print "Big::Fat::Liar's vars\n";
foreach my $key (qw(INST_LIB INST_ARCHLIB)) {
    print "$key = $mm->{$key}\n";
}
