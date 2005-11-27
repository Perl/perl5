require 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	 => 'MIME::Base64',
    VERSION_FROM => 'Base64.pm',
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    ($] >= 5.008) ?
      (INSTALLDIRS => 'perl') : (),
);
