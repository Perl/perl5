require 5.002;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	 => 'MIME::Base64',
    VERSION_FROM => 'Base64.pm',
    EXE_FILES    => [qw(encode-base64 decode-base64 encode-qp decode-qp)],
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
