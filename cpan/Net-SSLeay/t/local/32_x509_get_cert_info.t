use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw(
    data_file_path initialise_libssl is_libressl is_openssl
);

use lib '.';

my $tests =   ( is_openssl() && Net::SSLeay::SSLeay < 0x10100003 ) || is_libressl()
            ? 723
            : 726;

plan tests => $tests;

initialise_libssl();

# Check some basic X509 features added in 1.54:
my $name = Net::SSLeay::X509_NAME_new();
ok ($name, "X509_NAME_new");
my $hash = Net::SSLeay::X509_NAME_hash($name);
ok ($hash = 4003674586, "X509_NAME_hash");

# Caution from perl 25 onwards, need use lib '.'; above in order to 'do' these files
my $dump = {};
for my $cert ( qw( extended-cert simple-cert strange-cert wildcard-cert ) ) {
    $dump->{"$cert.cert.pem"} = do( data_file_path("$cert.cert.dump") );
}

my %available_digests = map {$_=>1} qw( md5 sha1 );
if (Net::SSLeay::SSLeay >= 0x1000000f) {
  my $ctx = Net::SSLeay::EVP_MD_CTX_create();
  %available_digests = map { $_=>1 } grep {
    # P_EVP_MD_list_all() does not remove digests disabled in FIPS 
    my $md;
    $md = Net::SSLeay::EVP_get_digestbyname($_) and
      Net::SSLeay::EVP_DigestInit($ctx, $md)
  } @{Net::SSLeay::P_EVP_MD_list_all()};
}

for my $f (keys (%$dump)) {
  my $filename = data_file_path($f);
  ok(my $bio = Net::SSLeay::BIO_new_file($filename, 'rb'), "BIO_new_file\t$f");
  ok(my $x509 = Net::SSLeay::PEM_read_bio_X509($bio), "PEM_read_bio_X509\t$f");
  ok(Net::SSLeay::X509_get_pubkey($x509), "X509_get_pubkey\t$f"); #only test whether the function works  

  ok(my $subj_name = Net::SSLeay::X509_get_subject_name($x509), "X509_get_subject_name\t$f");
  is(my $subj_count = Net::SSLeay::X509_NAME_entry_count($subj_name), $dump->{$f}->{subject}->{count}, "X509_NAME_entry_count\t$f");
  
  #BEWARE: values are not the same across different openssl versions therefore cannot test exact match
  #is(Net::SSLeay::X509_NAME_oneline($subj_name), $dump->{$f}->{subject}->{oneline}, "X509_NAME_oneline\t$f");  
  #is(Net::SSLeay::X509_NAME_print_ex($subj_name), $dump->{$f}->{subject}->{print_rfc2253}, "X509_NAME_print_ex\t$f");  
  like(Net::SSLeay::X509_NAME_oneline($subj_name), qr|/OU=.*?/CN=|, "X509_NAME_oneline\t$f");
  like(Net::SSLeay::X509_NAME_print_ex($subj_name), qr|CN=.*?,OU=|, "X509_NAME_print_ex\t$f");

  for my $i (0..$subj_count-1) {    
    ok(my $entry = Net::SSLeay::X509_NAME_get_entry($subj_name, $i), "X509_NAME_get_entry\t$f:$i");
    ok(my $asn1_string = Net::SSLeay::X509_NAME_ENTRY_get_data($entry), "X509_NAME_ENTRY_get_data\t$f:$i");
    ok(my $asn1_object = Net::SSLeay::X509_NAME_ENTRY_get_object($entry), "X509_NAME_ENTRY_get_object\t$f:$i");
    is(Net::SSLeay::OBJ_obj2txt($asn1_object,1), $dump->{$f}->{subject}->{entries}->[$i]->{oid}, "OBJ_obj2txt\t$f:$i");
    is(Net::SSLeay::P_ASN1_STRING_get($asn1_string), $dump->{$f}->{subject}->{entries}->[$i]->{data}, "P_ASN1_STRING_get.1\t$f:$i");
    is(Net::SSLeay::P_ASN1_STRING_get($asn1_string, 1), $dump->{$f}->{subject}->{entries}->[$i]->{data_utf8_decoded}, "P_ASN1_STRING_get.2\t$f:$i");
    if (defined $dump->{$f}->{entries}->[$i]->{nid}) {
      is(my $nid = Net::SSLeay::OBJ_obj2nid($asn1_object), $dump->{$f}->{subject}->{entries}->[$i]->{nid}, "OBJ_obj2nid\t$f:$i");
      is(Net::SSLeay::OBJ_nid2ln($nid), $dump->{$f}->{subject}->{entries}->[$i]->{ln}, "OBJ_nid2ln\t$f:$i");
      is(Net::SSLeay::OBJ_nid2sn($nid), $dump->{$f}->{subject}->{entries}->[$i]->{sn}, "OBJ_nid2sn\t$f:$i");
    }
  }
  
  ok(my $issuer_name = Net::SSLeay::X509_get_issuer_name($x509), "X509_get_subject_name\t$f");
  is(my $issuer_count = Net::SSLeay::X509_NAME_entry_count($issuer_name), $dump->{$f}->{issuer}->{count}, "X509_NAME_entry_count\t$f");
  is(Net::SSLeay::X509_NAME_oneline($issuer_name), $dump->{$f}->{issuer}->{oneline}, "X509_NAME_oneline\t$f");
  is(Net::SSLeay::X509_NAME_print_ex($issuer_name), $dump->{$f}->{issuer}->{print_rfc2253}, "X509_NAME_print_ex\t$f");

  for my $i (0..$issuer_count-1) {    
    ok(my $entry = Net::SSLeay::X509_NAME_get_entry($issuer_name, $i), "X509_NAME_get_entry\t$f:$i");
    ok(my $asn1_string = Net::SSLeay::X509_NAME_ENTRY_get_data($entry), "X509_NAME_ENTRY_get_data\t$f:$i");
    ok(my $asn1_object = Net::SSLeay::X509_NAME_ENTRY_get_object($entry), "X509_NAME_ENTRY_get_object\t$f:$i");
    is(Net::SSLeay::OBJ_obj2txt($asn1_object,1), $dump->{$f}->{issuer}->{entries}->[$i]->{oid}, "OBJ_obj2txt\t$f:$i");
    is(Net::SSLeay::P_ASN1_STRING_get($asn1_string), $dump->{$f}->{issuer}->{entries}->[$i]->{data}, "P_ASN1_STRING_get.1\t$f:$i");
    is(Net::SSLeay::P_ASN1_STRING_get($asn1_string, 1), $dump->{$f}->{issuer}->{entries}->[$i]->{data_utf8_decoded}, "P_ASN1_STRING_get.2\t$f:$i");
    if (defined $dump->{$f}->{entries}->[$i]->{nid}) {
      is(my $nid = Net::SSLeay::OBJ_obj2nid($asn1_object), $dump->{$f}->{issuer}->{entries}->[$i]->{nid}, "OBJ_obj2nid\t$f:$i");
      is(Net::SSLeay::OBJ_nid2ln($nid), $dump->{$f}->{issuer}->{entries}->[$i]->{ln}, "OBJ_nid2ln\t$f:$i");
      is(Net::SSLeay::OBJ_nid2sn($nid), $dump->{$f}->{issuer}->{entries}->[$i]->{sn}, "OBJ_nid2sn\t$f:$i");
    }
  }
  
  my @subjectaltnames = Net::SSLeay::X509_get_subjectAltNames($x509);
  is(scalar(@subjectaltnames), scalar(@{$dump->{$f}->{subject}->{altnames}}), "subjectaltnames size\t$f");
  for my $i (0..$#subjectaltnames) {
    SKIP: {
      skip('altname types are different on pre-0.9.7', 1) unless Net::SSLeay::SSLeay >= 0x0090700f || ($i%2)==1;
      is($subjectaltnames[$i], $dump->{$f}->{subject}->{altnames}->[$i], "subjectaltnames match\t$f:$i");
    }
  }
  
  #BEWARE: values are not the same across different openssl versions or FIPS mode, therefore testing just >0
  #is(Net::SSLeay::X509_subject_name_hash($x509), $dump->{$f}->{hash}->{subject}->{dec}, 'X509_subject_name_hash dec');
  #is(Net::SSLeay::X509_issuer_name_hash($x509), $dump->{$f}->{hash}->{issuer}->{dec}, 'X509_issuer_name_hash dec');
  #is(Net::SSLeay::X509_issuer_and_serial_hash($x509), $dump->{$f}->{hash}->{issuer_and_serial}->{dec}, "X509_issuer_and_serial_hash dec\t$f");
  cmp_ok(Net::SSLeay::X509_subject_name_hash($x509), '>', 0, "X509_subject_name_hash dec\t$f");
  cmp_ok(Net::SSLeay::X509_issuer_name_hash($x509), '>', 0, "X509_issuer_name_hash dec\t$f");
  cmp_ok(Net::SSLeay::X509_issuer_and_serial_hash($x509), '>', 0, "X509_issuer_and_serial_hash dec\t$f");

  for my $digest (qw( md5 sha1 )) { 
    is(Net::SSLeay::X509_get_fingerprint($x509, $digest),
      (exists $available_digests{$digest} ?
        $dump->{$f}->{fingerprint}->{$digest} :
        undef),
      "X509_get_fingerprint $digest\t$f");
  }
  
  my $sha1_digest = Net::SSLeay::EVP_get_digestbyname("sha1");
  SKIP: {
    skip('requires openssl-0.9.7', 1) unless Net::SSLeay::SSLeay >= 0x0090700f;
    is(Net::SSLeay::X509_pubkey_digest($x509, $sha1_digest), $dump->{$f}->{digest_sha1}->{pubkey}, "X509_pubkey_digest\t$f");
  }
  is(Net::SSLeay::X509_digest($x509, $sha1_digest), $dump->{$f}->{digest_sha1}->{x509}, "X509_digest\t$f");

  
  SKIP: {
    skip('P_ASN1_TIME_get_isotime requires 0.9.7e+', 2) unless Net::SSLeay::SSLeay >= 0x0090705f;
    is(Net::SSLeay::P_ASN1_TIME_get_isotime(Net::SSLeay::X509_get_notBefore($x509)), $dump->{$f}->{not_before}, "X509_get_notBefore\t$f");
    is(Net::SSLeay::P_ASN1_TIME_get_isotime(Net::SSLeay::X509_get_notAfter($x509)), $dump->{$f}->{not_after}, "X509_get_notAfter\t$f");
  }
  
  ok(my $ai = Net::SSLeay::X509_get_serialNumber($x509), "X509_get_serialNumber\t$f");

  is(Net::SSLeay::P_ASN1_INTEGER_get_hex($ai), $dump->{$f}->{serial}->{hex}, "serial P_ASN1_INTEGER_get_hex\t$f");
  is(Net::SSLeay::P_ASN1_INTEGER_get_dec($ai), $dump->{$f}->{serial}->{dec}, "serial P_ASN1_INTEGER_get_dec\t$f");

  SKIP: {
    # X509_get0_serialNumber should function the same as X509_get_serialNumber
    skip('X509_get0_serialNumber requires OpenSSL 1.1.0+ or LibreSSL 2.8.1+', 3) unless defined (&Net::SSLeay::X509_get0_serialNumber);
    ok(my $ai = Net::SSLeay::X509_get0_serialNumber($x509), "X509_get0_serialNumber\t$f");

    is(Net::SSLeay::P_ASN1_INTEGER_get_hex($ai), $dump->{$f}->{serial}->{hex}, "serial P_ASN1_INTEGER_get_hex\t$f");
    is(Net::SSLeay::P_ASN1_INTEGER_get_dec($ai), $dump->{$f}->{serial}->{dec}, "serial P_ASN1_INTEGER_get_dec\t$f");
  }

  # On platforms with 64-bit long int returns 4294967295 rather than -1
  # Caution, there is much difference between 32 and 64 bit behaviours with 
  # Net::SSLeay::ASN1_INTEGER_get.
  # This test is deleted
#  my $asn1_integer = Net::SSLeay::ASN1_INTEGER_get($ai);
#  if ($asn1_integer == 4294967295) {
#    $asn1_integer = -1;
#  }
#  is($asn1_integer, $dump->{$f}->{serial}->{long}, "serial ASN1_INTEGER_get\t$f");

  is(Net::SSLeay::X509_get_version($x509), $dump->{$f}->{version}, "X509_get_version\t$f");
  
  is(my $ext_count = Net::SSLeay::X509_get_ext_count($x509), $dump->{$f}->{extensions}->{count}, "X509_get_ext_count\t$f");
  for my $i (0..$ext_count-1) {
    ok(my $ext = Net::SSLeay::X509_get_ext($x509,$i), "X509_get_ext\t$f:$i");
    ok(my $asn1_string = Net::SSLeay::X509_EXTENSION_get_data($ext), "X509_EXTENSION_get_data\t$f:$i");
    ok(my $asn1_object = Net::SSLeay::X509_EXTENSION_get_object($ext), "X509_EXTENSION_get_object\t$f:$i");
    SKIP: {
      skip('X509_EXTENSION_get_critical works differently on pre-0.9.7', 1) unless Net::SSLeay::SSLeay >= 0x0090700f;
      is(Net::SSLeay::X509_EXTENSION_get_critical($ext), $dump->{$f}->{extensions}->{entries}->[$i]->{critical}, "X509_EXTENSION_get_critical\t$f:$i");
    }
    is(Net::SSLeay::OBJ_obj2txt($asn1_object,1), $dump->{$f}->{extensions}->{entries}->[$i]->{oid}, "OBJ_obj2txt\t$f:$i");
    
    if (defined $dump->{$f}->{extensions}->{entries}->[$i]->{nid}) {
      is(my $nid = Net::SSLeay::OBJ_obj2nid($asn1_object), $dump->{$f}->{extensions}->{entries}->[$i]->{nid}, "OBJ_obj2nid\t$f:$i");
      is(Net::SSLeay::OBJ_nid2ln($nid), $dump->{$f}->{extensions}->{entries}->[$i]->{ln}, "OBJ_nid2ln nid=$nid\t$f:$i");
      is(Net::SSLeay::OBJ_nid2sn($nid), $dump->{$f}->{extensions}->{entries}->[$i]->{sn}, "OBJ_nid2sn nid=$nid\t$f:$i");
      #BEARE: handling some special cases - mostly things that varies with different openssl versions
      SKIP: {
          my $ext_data = $dump->{$f}->{extensions}->{entries}->[$i]->{data};

          if ( is_openssl() ) {
              if (    $nid == 85
                   || $nid == 86 ) {
                  # IPv6 address formatting is broken in a way that loses
                  # information between OpenSSL 3.0.0-alpha1 and 3.0.0-alpha7,
                  # so there's no point in running this test
                  if (    $ext_data =~ /IP Address:(?!(?:\d{1,3}\.){3}\d{1,3})/
                       && Net::SSLeay::SSLeay == 0x30000000
                       && Net::SSLeay::SSLeay_version( Net::SSLeay::SSLEAY_VERSION() ) =~ /-alpha[2-6]/ ) {
                      skip( 'This OpenSSL version does not correctly format IPv6 addresses', 1 );
                  }

                  # "othername" fields in subject and issuer alternative name
                  #  output are unsupported before OpenSSL 3.0.0-alpha2
                  if (
                      $ext_data =~ m|othername:|
                      && (
                          Net::SSLeay::SSLeay < 0x30000000
                          || (
                                  Net::SSLeay::SSLeay == 0x30000000
                               && Net::SSLeay::SSLeay_version( Net::SSLeay::SSLEAY_VERSION() ) =~ /-alpha1\ /
                          )
                      )
                  ) {
                      $ext_data =~ s{(othername:) [^, ]+}{$1<unsupported>}g;
                  }
              }
              elsif ( $nid == 89 ) {
                  # The output formatting for certificate policies has a
                  # trailing newline before OpenSSL 3.0.0-alpha1
                  if ( Net::SSLeay::SSLeay < 0x30000000 ) {
                      $ext_data .= "\n";
                  }
              }
              elsif ( $nid == 90 ) {
                  # Authority key identifier formatting has a "keyid:" prefix
                  # and a trailing newline before OpenSSL 3.0.0-alpha1
                  if ( Net::SSLeay::SSLeay < 0x30000000 ) {
                      $ext_data = 'keyid:' . $ext_data . "\n";
                  }
              }
              elsif ( $nid == 103 ) {
                  # The output format for CRL distribution points varies between
                  # different OpenSSL major versions
                  if ( Net::SSLeay::SSLeay < 0x10000001 ) {
                      # OpenSSL 0.9.8:
                      $ext_data =~ s{Full Name:\n  }{}g;
                      $ext_data .= "\n";
                  } elsif ( Net::SSLeay::SSLeay < 0x30000000 ) {
                      # OpenSSL 1.0.0 to 1.1.1:
                      $ext_data =~ s{(Full Name:\n  )}{\n$1}g;
                      $ext_data .= "\n";
                  }
              }
              elsif ( $nid == 126 ) {
                  # OID 1.3.6.1.5.5.7.3.17 ("ipsec Internet Key Exchange") isn't
                  # given its name in extended key usage formatted output before
                  # OpenSSL 1.1.0-pre3
                  if ( Net::SSLeay::SSLeay < 0x10100003 ) {
                      $ext_data =~ s{ipsec Internet Key Exchange(,|$)}{1.3.6.1.5.5.7.3.17$1}g;
                  }
              }
              elsif ( $nid == 177 ) {
                  # Authority information access formatting has a trailing
                  # newline before OpenSSL 3.0.0-alpha1
                  if ( Net::SSLeay::SSLeay < 0x30000000 ) {
                      $ext_data .= "\n";
                  }
              }
          }
          # LibreSSL is a fork of OpenSSL 1.0.1g, so any pre-1.0.2 changes above
          # also apply here:
          elsif ( is_libressl() ) {
              if (    $nid == 85
                   || $nid == 86 ) {
                  # "othername" fields in subject and issuer alternative name
                  #  output are unsupported
                  $ext_data =~ s{(othername:) [^, ]+}{$1<unsupported>}g;
              }
              elsif ( $nid == 89 ) {
                  # The output formatting for certificate policies has a
                  # trailing newline
                  $ext_data .= "\n";
              }
              elsif ( $nid == 90 ) {
                  # Authority key identifier formatting has a "keyid:" prefix
                  # and a trailing newline
                  $ext_data = 'keyid:' . $ext_data . "\n";
              }
              elsif ( $nid == 103 ) {
                  # The output format for CRL distribution points contains
                  # extra newlines between the values, and has leading and
                  # trailing newlines
                  $ext_data =~ s{(Full Name:\n  )}{\n$1}g;
                  $ext_data .= "\n";
              }
              elsif ( $nid == 126 ) {
                  # OID 1.3.6.1.5.5.7.3.17 ("ipsec Internet Key Exchange") isn't
                  # given its name in extended key usage formatted output
                  $ext_data =~ s{ipsec Internet Key Exchange(,|$)}{1.3.6.1.5.5.7.3.17$1}g;
              }
              elsif ( $nid == 177 ) {
                  # Authority information access formatting has a trailing
                  # newline
                  $ext_data .= "\n";
              }
          }

          is( Net::SSLeay::X509V3_EXT_print($ext), $ext_data, "X509V3_EXT_print nid=$nid\t$f:$i" );
      }
    }
  }
    
  SKIP: {
    skip('crl_distribution_points requires 0.9.7+', int(@{$dump->{$f}->{cdp}})+1) unless Net::SSLeay::SSLeay >= 0x0090700f;
    my @cdp = Net::SSLeay::P_X509_get_crl_distribution_points($x509);
    is(scalar(@cdp), scalar(@{$dump->{$f}->{cdp}}), "cdp size\t$f");
    for my $i (0..$#cdp) {
      is($cdp[$i], $dump->{$f}->{cdp}->[$i], "cdp match\t$f:$i");
    }
  }

  my @keyusage = Net::SSLeay::P_X509_get_key_usage($x509);
  my @ns_cert_type = Net::SSLeay::P_X509_get_netscape_cert_type($x509);
  is(scalar(@keyusage), scalar(@{$dump->{$f}->{keyusage}}), "keyusage size\t$f");
  is(scalar(@ns_cert_type), scalar(@{$dump->{$f}->{ns_cert_type}}), "ns_cert_type size\t$f");
  for my $i (0..$#keyusage) {
    is($keyusage[$i], $dump->{$f}->{keyusage}->[$i], "keyusage match\t$f:$i");
  }
  for my $i (0..$#ns_cert_type) {
    is($ns_cert_type[$i], $dump->{$f}->{ns_cert_type}->[$i], "ns_cert_type match\t$f:$i");
  }

  SKIP: {
    # "ipsec Internet Key Exchange" isn't known by its name in OpenSSL
    # 1.1.0-pre2 and below or in LibreSSL
    if (    is_openssl() && Net::SSLeay::SSLeay < 0x10100003
         || is_libressl() ) {
        @{ $dump->{$f}->{extkeyusage}->{ln} } =
            grep { $_ ne 'ipsec Internet Key Exchange' }
            @{ $dump->{$f}->{extkeyusage}->{ln} };

        @{ $dump->{$f}->{extkeyusage}->{nid} } =
            grep { $_ != 1022 }
            @{ $dump->{$f}->{extkeyusage}->{nid} };

        @{ $dump->{$f}->{extkeyusage}->{sn} } =
            grep { $_ ne 'ipsecIKE' }
            @{ $dump->{$f}->{extkeyusage}->{sn} };
    }

    my $test_count = 4 + scalar(@{$dump->{$f}->{extkeyusage}->{oid}}) +
                         scalar(@{$dump->{$f}->{extkeyusage}->{nid}}) +
                         scalar(@{$dump->{$f}->{extkeyusage}->{sn}}) +
                         scalar(@{$dump->{$f}->{extkeyusage}->{ln}});

    skip('extended key usage requires 0.9.7+', $test_count) unless Net::SSLeay::SSLeay >= 0x0090700f;
    my @extkeyusage_oid = Net::SSLeay::P_X509_get_ext_key_usage($x509,0);
    my @extkeyusage_nid = Net::SSLeay::P_X509_get_ext_key_usage($x509,1);
    my @extkeyusage_sn  = Net::SSLeay::P_X509_get_ext_key_usage($x509,2);
    my @extkeyusage_ln  = Net::SSLeay::P_X509_get_ext_key_usage($x509,3);
  
    is(scalar(@extkeyusage_oid), scalar(@{$dump->{$f}->{extkeyusage}->{oid}}), "extku_oid size\t$f");
    is(scalar(@extkeyusage_nid), scalar(@{$dump->{$f}->{extkeyusage}->{nid}}), "extku_nid size\t$f");
    is(scalar(@extkeyusage_sn), scalar(@{$dump->{$f}->{extkeyusage}->{sn}}), "extku_sn size\t$f");
    is(scalar(@extkeyusage_ln), scalar(@{$dump->{$f}->{extkeyusage}->{ln}}), "extku_ln size\t$f");

    for my $i (0..$#extkeyusage_oid) {
      is($extkeyusage_oid[$i], $dump->{$f}->{extkeyusage}->{oid}->[$i], "extkeyusage_oid match\t$f:$i");
    }
    for my $i (0..$#extkeyusage_nid) {
      is($extkeyusage_nid[$i], $dump->{$f}->{extkeyusage}->{nid}->[$i], "extkeyusage_nid match\t$f:$i");
    }
    for my $i (0..$#extkeyusage_sn) {
      is($extkeyusage_sn[$i], $dump->{$f}->{extkeyusage}->{sn}->[$i], "extkeyusage_sn match\t$f:$i");
    }
    for my $i (0..$#extkeyusage_ln) {
      is($extkeyusage_ln[$i], $dump->{$f}->{extkeyusage}->{ln}->[$i], "extkeyusage_ln match\t$f:$i");
    }
  }
  
  ok(my $pubkey = Net::SSLeay::X509_get_pubkey($x509), "X509_get_pubkey");
  is(Net::SSLeay::OBJ_obj2txt(Net::SSLeay::P_X509_get_signature_alg($x509)), $dump->{$f}->{signature_alg}, "P_X509_get_signature_alg");
  is(Net::SSLeay::OBJ_obj2txt(Net::SSLeay::P_X509_get_pubkey_alg($x509)), $dump->{$f}->{pubkey_alg}, "P_X509_get_pubkey_alg");  
  is(Net::SSLeay::EVP_PKEY_size($pubkey), $dump->{$f}->{pubkey_size}, "EVP_PKEY_size");
  is(Net::SSLeay::EVP_PKEY_bits($pubkey), $dump->{$f}->{pubkey_bits}, "EVP_PKEY_bits");
  SKIP: {
    skip('EVP_PKEY_id requires OpenSSL 1.0.0+', 1) unless Net::SSLeay::SSLeay >= 0x1000000f;
    is(Net::SSLeay::EVP_PKEY_id($pubkey), $dump->{$f}->{pubkey_id}, "EVP_PKEY_id");
  }

}

my $ctx = Net::SSLeay::X509_STORE_CTX_new();
my $filename = data_file_path('simple-cert.cert.pem');
my $bio = Net::SSLeay::BIO_new_file($filename, 'rb');
my $x509 = Net::SSLeay::PEM_read_bio_X509($bio);
my $x509_store = Net::SSLeay::X509_STORE_new();
Net::SSLeay::X509_STORE_CTX_set_cert($ctx,$x509);

my $ca_filename = data_file_path('root-ca.cert.pem');
my $ca_bio = Net::SSLeay::BIO_new_file($ca_filename, 'rb');
my $ca_x509 = Net::SSLeay::PEM_read_bio_X509($ca_bio);
is (Net::SSLeay::X509_STORE_add_cert($x509_store,$ca_x509), 1, 'X509_STORE_add_cert');
is (Net::SSLeay::X509_STORE_CTX_init($ctx, $x509_store, $x509), 1, 'X509_STORE_CTX_init');
SKIP: {
    skip('X509_STORE_CTX_get0_cert requires OpenSSL 1.1.0-pre5+ or LibreSSL 2.7.0+', 1) unless defined (&Net::SSLeay::X509_STORE_CTX_get0_cert);
    ok (my $x509_from_cert = Net::SSLeay::X509_STORE_CTX_get0_cert($ctx),'Get x509 from store ctx');
};
Net::SSLeay::X509_verify_cert($ctx);
ok (my $sk_x509 = Net::SSLeay::X509_STORE_CTX_get1_chain($ctx),'Get STACK_OF(x509) from store ctx');
my $size;
ok ($size = Net::SSLeay::sk_X509_num($sk_x509),'STACK_OF(X509) size '.$size);
ok (Net::SSLeay::sk_X509_value($sk_x509,0),'STACK_OF(X509) value at 0');

my $new_filename = data_file_path('wildcard-cert.cert.pem');
my $new_bio = Net::SSLeay::BIO_new_file($new_filename,'rb');
my $new_x509 = Net::SSLeay::PEM_read_bio_X509($new_bio);

ok (Net::SSLeay::sk_X509_insert($sk_x509,$new_x509,1),'STACK_OK(X509) insert');
my $new_size;
$new_size = Net::SSLeay::sk_X509_num($sk_x509);
ok ($new_size == $size + 1, 'size is ' . ($size + 1) . ' after insert');
ok (Net::SSLeay::sk_X509_delete($sk_x509, 1),'STACK_OK(X509) delete');
$new_size = Net::SSLeay::sk_X509_num($sk_x509);
ok ($new_size == $size, "size is $size after delete");
ok (Net::SSLeay::sk_X509_unshift($sk_x509,$new_x509),'STACK_OF(X509) unshift');
$new_size = Net::SSLeay::sk_X509_num($sk_x509);
ok ($new_size == $size + 1, 'size is ' . ($size + 1) . ' after unshift');
ok (Net::SSLeay::sk_X509_shift($sk_x509),'STACK_OF(X509) shift');
$new_size = Net::SSLeay::sk_X509_num($sk_x509);
ok ($new_size == $size, "size is $size after shift");
ok (Net::SSLeay::sk_X509_pop($sk_x509),'STACK_OF(X509) pop');
$new_size = Net::SSLeay::sk_X509_num($sk_x509);
ok ($new_size == $size - 1, 'size is ' . ($size + 1) . ' after pop');
