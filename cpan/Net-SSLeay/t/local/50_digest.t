use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw( data_file_path initialise_libssl );

plan tests => 203;

initialise_libssl();
Net::SSLeay::OpenSSL_add_all_digests();

sub digest_chunked_f1 {
  my ($file, $digest) = @_;
  
  my $md = Net::SSLeay::EVP_get_digestbyname($digest) or BAIL_OUT "digest '$digest' not available";
  my $ctx = Net::SSLeay::EVP_MD_CTX_create();
  Net::SSLeay::EVP_DigestInit($ctx, $md);

  open my $fh, "<", $file or BAIL_OUT "cannot open file '$file'";
  binmode $fh;
  while(my $len = sysread($fh, my $chunk, 500)) {
    Net::SSLeay::EVP_DigestUpdate($ctx,$chunk);
  }
  close $fh;

  my $result = Net::SSLeay::EVP_DigestFinal($ctx);
  Net::SSLeay::EVP_MD_CTX_destroy($ctx);
  
  return $result;
}

sub digest_chunked_f2 {
  my ($file, $digest) = @_;
  
  my $md = Net::SSLeay::EVP_get_digestbyname($digest) or BAIL_OUT "digest '$digest' not available";
  my $ctx = Net::SSLeay::EVP_MD_CTX_create();
  Net::SSLeay::EVP_DigestInit_ex($ctx, $md, 0); #NULL ENGINE just to test whether the function exists

  open my $fh, "<", $file or BAIL_OUT "cannot open file '$file'";
  binmode $fh;
  while(my $len = sysread($fh, my $chunk, 5)) {
    Net::SSLeay::EVP_DigestUpdate($ctx,$chunk);
  }
  close $fh;

  my $result = Net::SSLeay::EVP_DigestFinal_ex($ctx);
  Net::SSLeay::EVP_MD_CTX_destroy($ctx);
  
  return $result;
}

sub digest_file {
  my ($file, $expected_results, $available_digests) = @_;

  for my $d (sort keys %$expected_results) {
    SKIP: {
      skip "digest '$d' not available (or pre-1.0.0)", 2 unless $available_digests->{$d};
      is( unpack("H*", digest_chunked_f1($file, $d)), $expected_results->{$d}, "$d chunked.1 [$file]");
      is( unpack("H*", digest_chunked_f2($file, $d)), $expected_results->{$d}, "$d chunked.2 [$file]");
    }
  }

  open my $f, "<", $file or BAIL_OUT "cannot open file '$file'";
  binmode $f;
  sysread($f, my $data, -s $file) or BAIL_OUT "sysread failed";  
  close $f;
  
  is(length($data), -s $file, 'got the whole file');

  SKIP: {
    skip "Net::SSLeay::MD2 not available", 1
      unless exists &Net::SSLeay::MD2 and exists $available_digests->{md2};
    is( unpack("H*", Net::SSLeay::MD2($data)), $expected_results->{md2}, "MD2 all-in-one-go [$file]");
  }
  SKIP: {
    skip "Net::SSLeay::MD4 not available", 1
      unless exists &Net::SSLeay::MD4 and exists $available_digests->{md4};
    is( unpack("H*", Net::SSLeay::MD4($data)), $expected_results->{md4}, "MD4 all-in-one-go [$file]");
  }
  SKIP: {
    skip "Net::SSLeay::MD5 not available", 1
      unless exists &Net::SSLeay::MD5 and exists $available_digests->{md5};
    is( unpack("H*", Net::SSLeay::MD5($data)), $expected_results->{md5}, "MD5 all-in-one-go [$file]");
  }
  SKIP: {
    skip "Net::SSLeay::RIPEMD160 not available", 1
      unless exists &Net::SSLeay::RIPEMD160 and
        exists $available_digests->{ripemd160};
    is( unpack("H*", Net::SSLeay::RIPEMD160($data)), $expected_results->{ripemd160}, "RIPEMD160 all-in-one-go [$file]");
  }  
}

sub digest_strings {
  my ($fps, $available_digests) = @_;
  
  for my $data (sort keys %$fps) {
  
    for my $d (sort keys %{$fps->{$data}}) {
      SKIP: {
        skip "digest '$d' not available (or pre-1.0.0)", 2 unless $available_digests->{$d};
        my $md = Net::SSLeay::EVP_get_digestbyname($d) or BAIL_OUT "digest '$d' not available";
        my $ctx = Net::SSLeay::EVP_MD_CTX_create();
        Net::SSLeay::EVP_DigestInit($ctx, $md);
        Net::SSLeay::EVP_DigestUpdate($ctx, $data);
        my $result1 = Net::SSLeay::EVP_DigestFinal($ctx);
        Net::SSLeay::EVP_MD_CTX_destroy($ctx);
        is(unpack('H*', $result1), $fps->{$data}->{$d}, "$d for '$data'");        
        # test EVP_Digest
        my $result2 = Net::SSLeay::EVP_Digest($data, Net::SSLeay::EVP_get_digestbyname($d));
        is(unpack('H*', $result2), $fps->{$data}->{$d}, "EVP_Digest($d)");
      }
    }
  
      
  
    SKIP: {
      skip "Net::SSLeay::MD2 not available", 1
        unless exists &Net::SSLeay::MD2 and exists $available_digests->{md2};
      is(unpack('H*', Net::SSLeay::MD2($data)), $fps->{$data}->{md2}, "MD2 hash for '$data'");
    }
    SKIP: {
      skip "Net::SSLeay::MD4 not available", 1
        unless exists &Net::SSLeay::MD4 and exists $available_digests->{md4};
      is(unpack('H*', Net::SSLeay::MD4($data)), $fps->{$data}->{md4}, "MD4 hash for '$data'");
    }
    SKIP: {
      skip "Net::SSLeay::MD5 not available", 1
        unless exists &Net::SSLeay::MD5 and exists $available_digests->{md5};
      is(unpack('H*', Net::SSLeay::MD5($data)), $fps->{$data}->{md5}, "MD5 hash for '$data'");
    }
    SKIP: {
      skip "Net::SSLeay::RIPEMD160 not available", 1
        unless exists &Net::SSLeay::RIPEMD160 and
          exists $available_digests->{ripemd160};
      is(unpack('H*', Net::SSLeay::RIPEMD160($data)), $fps->{$data}->{ripemd160}, "RIPEMD160 hash for '$data'");
    }

    SKIP: {
      skip "Net::SSLeay::SHA1 not available", 1
        unless exists &Net::SSLeay::SHA1 and exists $available_digests->{sha1};
      is(unpack('H*', Net::SSLeay::SHA1($data)), $fps->{$data}->{sha1}, "SHA1 hash for '$data'");
    }
    SKIP: {
      skip "Net::SSLeay::SHA256 not available", 1
        unless exists &Net::SSLeay::SHA256 and
          exists $available_digests->{sha256};
      is(unpack('H*', Net::SSLeay::SHA256($data)), $fps->{$data}->{sha256}, "SHA256 hash for '$data'");
    }
    SKIP: {
      skip "Net::SSLeay::SHA512 not available", 1
        unless exists &Net::SSLeay::SHA512 and
          exists $available_digests->{sha512};
      is(unpack('H*', Net::SSLeay::SHA512($data)), $fps->{$data}->{sha512}, "SHA512 hash for '$data'");
    }
  }
}

my %all_digests;

eval {
  if (Net::SSLeay::SSLeay >= 0x1000000f) {
	my $ctx = Net::SSLeay::EVP_MD_CTX_create();
    %all_digests = map { $_=>1 } grep {
      # P_EVP_MD_list_all() does not remove digests disabled in FIPS 
      my $md;
      $md = Net::SSLeay::EVP_get_digestbyname($_) and
        Net::SSLeay::EVP_DigestInit($ctx, $md)
    } @{Net::SSLeay::P_EVP_MD_list_all()};
  }
  else {
    %all_digests = ();
  }
};

is($@, '', 'digest init OK');
SKIP: {
  skip "pre-1.0.0", 1 unless Net::SSLeay::SSLeay >= 0x1000000f;
  isnt(scalar(keys %all_digests), 0, 'non-empty digest list');
}

my $file = data_file_path('binary-test.file');

my $file_digests = {
        md2       => '67ae6d821be6898101414c56b1fb4f46',
        md4       => '480438696e7d9a6ab3ecc1e2a3419f78',
        md5       => 'cc89b43c171818c347639fa5170aee16',
        mdc2      => 'ee605fe3fc966a7b17185ebdbcd13ada',
        ripemd160 => 'cb70ba43fc6d263f6d7816170c1a33f28c2000fe',
        sha       => 'c151c6f408cb94bc5c53b17852efbe8bfbeec2b9',
        sha1      => '059404d1d0e952d0457a6c99b6e68b3b44c8ef13',
        sha224    => '161c65efa1b9762f7e0448b5b369a3e2c236876b0b57a35add5106bb',
        sha256    => 'e416730ddaa34729adb32ec6ddad4e50fca1fe97de313e800196b1f8cd5032bd',
        sha512    => '8b5e7181fc76d49e1cb7971a6980b5d8db6b23c3b0553cf42f559156fd08e64567d17c4147c864efd4d3a5e22fb6602d613a055f7f14faad22744dbc3df89d59',
        whirlpool => '31079767aa2dd9b8ab01caadd954a88aaaf6001941c38d17ba43c0ef80a074c3eedf35b73c3941929dea281805c6c5ffc0a619abef4c6a3365d6cb31412d0e0c',
};

my %fps = (
        '' => {
            md2 => '8350e5a3e24c153df2275c9f80692773',
            md4 => '31d6cfe0d16ae931b73c59d7e0c089c0',
            md5 => 'd41d8cd98f00b204e9800998ecf8427e',
	    ripemd160 => '9c1185a5c5e9fc54612808977ee8f548b2258d31',
            sha1      => 'da39a3ee5e6b4b0d3255bfef95601890afd80709',
            sha256    => 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
            sha512    => 'cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e',
        },
        'a' => {
            md2 => '32ec01ec4a6dac72c0ab96fb34c0b5d1',
            md4 => 'bde52cb31de33e46245e05fbdbd6fb24',
            md5 => '0cc175b9c0f1b6a831c399e269772661',
	    ripemd160 => '0bdc9d2d256b3ee9daae347be6f4dc835a467ffe',
            sha1=>'86f7e437faa5a7fce15d1ddcb9eaeaea377667b8',
            sha256=>'ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb',
            sha512=>'1f40fc92da241694750979ee6cf582f2d5d7d28e18335de05abc54d0560e0f5302860c652bf08d560252aa5e74210546f369fbbbce8c12cfc7957b2652fe9a75',
        },
        '38' => {
            md2 => '4b85c826321a5ce87db408c908d0709e',
            md4 => 'ae9c7ebfb68ea795483d270f5934b71d',
            md5 => 'a5771bce93e200c36f7cd9dfd0e5deaa',
	    ripemd160 => '6b2d075b1cd34cd1c3e43a995f110c55649dad0e',
            sha1=>'5b384ce32d8cdef02bc3a139d4cac0a22bb029e8',
            sha256=>'aea92132c4cbeb263e6ac2bf6c183b5d81737f179f21efdc5863739672f0f470',
            sha512=>'caae34a5e81031268bcdaf6f1d8c04d37b7f2c349afb705b575966f63e2ebf0fd910c3b05160ba087ab7af35d40b7c719c53cd8b947c96111f64105fd45cc1b2',
        },
        'abc' => {
            md2 => 'da853b0d3f88d99b30283a69e6ded6bb',
            md4 => 'a448017aaf21d8525fc10ae87aa6729d',
            md5 => '900150983cd24fb0d6963f7d28e17f72',
	    ripemd160 => '8eb208f7e05d987a9b044a8e98c6b087f15a0bfc',
            sha1=>'a9993e364706816aba3e25717850c26c9cd0d89d',
            sha256=>'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
            sha512=>'ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f',
        },
        'message digest' => {
            md2 => 'ab4f496bfb2a530b219ff33031fe06b0',
            md4 => 'd9130a8164549fe818874806e1c7014b',
            md5 => 'f96b697d7cb7938d525a2f31aaf161d0',
	    ripemd160 => '5d0689ef49d2fae572b881b123a85ffa21595f36',
            sha1=>'c12252ceda8be8994d5fa0290a47231c1d16aae3',
            sha256=>'f7846f55cf23e14eebeab5b4e1550cad5b509e3348fbc4efa3a1413d393cb650',
            sha512=>'107dbf389d9e9f71a3a95f6c055b9251bc5268c2be16d6c13492ea45b0199f3309e16455ab1e96118e8a905d5597b72038ddb372a89826046de66687bb420e7c',
        },
        'abcdefghijklmnopqrstuvwxyz' => {
            md2 => '4e8ddff3650292ab5a4108c3aa47940b',
            md4 => 'd79e1c308aa5bbcdeea8ed63df412da9',
            md5 => 'c3fcd3d76192e4007dfb496cca67e13b',
	    ripemd160 => 'f71c27109c692c1b56bbdceb5b9d2865b3708dbc',
            sha1=>'32d10c7b8cf96570ca04ce37f2a19d84240d3a89',
            sha256=>'71c480df93d6ae2f1efad1447c66c9525e316218cf51fc8d9ed832f2daf18b73',
            sha512=>'4dbff86cc2ca1bae1e16468a05cb9881c97f1753bce3619034898faa1aabe429955a1bf8ec483d7421fe3c1646613a59ed5441fb0f321389f77f48a879c7b1f1',
        },
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789' => {
            md2 => 'da33def2a42df13975352846c30338cd',
            md4 => '043f8582f241db351ce627e153e7f0e4',
            md5 => 'd174ab98d277d9f5a5611c2c9f419d9f',
	    ripemd160 => 'b0e20b6e3116640286ed3a87a5713079b21f5189',
            sha1=>'761c457bf73b14d27e9e9265c46f4b4dda11f940',
            sha256=>'db4bfcbd4da0cd85a60c3c37d3fbd8805c77f15fc6b1fdfe614ee0a7c8fdb4c0',
            sha512=>'1e07be23c26a86ea37ea810c8ec7809352515a970e9253c26f536cfc7a9996c45c8370583e0a78fa4a90041d71a4ceab7423f19c71b9d5a3e01249f0bebd5894',
        },
        '12345678901234567890123456789012345678901234567890123456789012345678901234567890' => {
            md2 => 'd5976f79d83d3a0dc9806c3c66f3efd8',
            md4 => 'e33b4ddc9c38f2199c3e7b164fcc0536',
            md5 => '57edf4a22be3c955ac49da2e2107b67a',
	    ripemd160 => '9b752e45573d4b39f4dbd3323cab82bf63326bfb',
            sha1=>'50abf5706a150990a08b2c5ea40fa0e585554732',
            sha256=>'f371bc4a311f2b009eef952dd83ca80e2b60026c8e935592d0f9c308453c813e',
            sha512=>'72ec1ef1124a45b047e8b7c75a932195135bb61de24ec0d1914042246e0aec3a2354e093d76f3048b456764346900cb130d2a4fd5dd16abb5e30bcb850dee843',
        },
);

SKIP: {
  skip "MD5 not available", 3 unless exists &Net::SSLeay::MD5;
  is(Net::SSLeay::EVP_MD_type(Net::SSLeay::EVP_get_digestbyname("MD5")), 4, 'EVP_MD_type md5');
  is(Net::SSLeay::EVP_MD_size(Net::SSLeay::EVP_get_digestbyname("MD5")), 16, 'EVP_MD_size md5');
  
  SKIP: {
    skip "pre-0.9.7", 1 unless Net::SSLeay::SSLeay >= 0x0090700f;
    my $md = Net::SSLeay::EVP_get_digestbyname("md5");
    my $ctx = Net::SSLeay::EVP_MD_CTX_create();
    skip "MD5 not available", 1 unless Net::SSLeay::EVP_DigestInit($ctx, $md);
    my $md2 = Net::SSLeay::EVP_MD_CTX_md($ctx);
    is(Net::SSLeay::EVP_MD_size($md2), 16, 'EVP_MD_size via EVP_MD_CTX_md md5');
  }
}

SKIP: {
  skip "Net::SSLeay::EVP_sha512 not available", 1 unless exists &Net::SSLeay::EVP_sha512;
  is(Net::SSLeay::EVP_MD_size(Net::SSLeay::EVP_sha512()), 64, 'EVP_MD_size sha512');
}
SKIP: {
  skip "Net::SSLeay::EVP_sha256 not available", 1 unless exists &Net::SSLeay::EVP_sha256;
  is(Net::SSLeay::EVP_MD_size(Net::SSLeay::EVP_sha256()), 32, 'EVP_MD_size sha256');
}
SKIP: {
  skip "Net::SSLeay::EVP_sha1 not available", 1 unless exists &Net::SSLeay::EVP_sha1;
  is(Net::SSLeay::EVP_MD_size(Net::SSLeay::EVP_sha1()), 20, 'EVP_MD_size sha1');
}

digest_file($file, $file_digests, \%all_digests);
digest_strings(\%fps, \%all_digests);
