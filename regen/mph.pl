package MinimalPerfectHash;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use Text::Wrap;

# The style of this file is determined by:
#
# perltidy -w -ple -bbb -bbc -bbs -nolq -l=80 -noll -nola -nwls='=' \
#   -isbc -nolc -otr -kis -ci=4 -se -sot -sct -nsbl -pt=2 -fs  \
#   -fsb='##!' -fse='##.'

use constant {
    FNV32_PRIME => 16777619,
    U8_MAX      => 0xFF,
    U16_MAX     => 0xFFFF,
    U32_MAX     => 0xFFFFFFFF,
};

our $DEBUG= 0;
my $RSHIFT= 8;
my $MASK= U32_MAX;
my $MAX_SEED2= U16_MAX;    # currently the same, but it isn't required.
my $IS_32BIT= !eval { pack "Q", 1 };

# The basic idea is that you have a two level structure, and effectively
# hash the key twice.
#
# The first hash finds a bucket in the array which contains a seed which
# is used for the second hash, which then leads to a bucket with key
# data which is compared against to determine if the key is a match.
#
# If the first hash finds no seed, then the key cannot match.
#
# In our case we cheat a bit, and hash the key only once, but use the
# low bits for the first lookup and the high-bits for the second.
#
# So for instance:
#
#           h= (h >> RSHIFT) ^ s;
#
# is how the second hash is computed. We right shift the original hash
# value  and then xor in the seed2, which will be non-zero.
#
# That then gives us the bucket which contains the key data we need to
# match for a valid key.

sub fnv1a_32 {
    my ($key, $seed)= @_;
    use integer;

    my $hash= 0 + $seed;
    foreach my $char (split //, $key) {
        $hash= $hash ^ ord($char);

        # the & U32_MAX is to simulate 32 bit ints on a 64 bit integer Perl.
        $hash= ($hash * FNV32_PRIME) & U32_MAX;
    }

    # The hash can end up negative on 32 bit Perls due to use integer being
    # in scope. This is equivalent to casting it to an U32.
    $hash= unpack "V", pack "l", $hash
        if $IS_32BIT;

    return $hash;
}

sub build_perfect_hash {
    my ($hash)= @_;

    my $n= 0 + keys %$hash;
    my $seed1= unpack("N", "Perl") - 1;
    my $hash_to_key;
    my $key_to_hash;
    my $key_buckets;
    SEED1:
    for ($seed1++ ; 1 ; $seed1++) {
        my %hash_to_key;
        my %key_to_hash;
        my %key_buckets;
        my %high;
        foreach my $key (sort keys %$hash) {
            my $h= fnv1a_32($key, $seed1);
            next SEED1 if exists $hash_to_key{$h};
            next SEED1 if $high{ $h >> $RSHIFT }++;
            $hash_to_key{$h}= $key;
            $key_to_hash{$key}= $h;
            push @{ $key_buckets{ $h % $n } }, $key;
        }
        $hash_to_key= \%hash_to_key;
        $key_to_hash= \%key_to_hash;
        $key_buckets= \%key_buckets;
        last SEED1;
    }

    my %token;
    my @first_level;
    my @second_level;
    foreach my $first_idx (
        sort {
            @{ $key_buckets->{$b} } <=> @{ $key_buckets->{$a} }
                || $a <=> $b
        } keys %$key_buckets
        )
    {
        my $keys= $key_buckets->{$first_idx};

        #printf "got %d keys in bucket %d\n", 0+@$keys, $first_idx;
        my $seed2;
        SEED2:
        for ($seed2= 1 ; 1 ; $seed2++) {
            goto FIND_SEED if $seed2 > $MAX_SEED2;
            my @idx= map {
                ((($key_to_hash->{$_} >> $RSHIFT) ^ $seed2) & $MASK) % $n
            } @$keys;
            my %seen;
            next SEED2 if grep { $second_level[$_] || $seen{$_}++ } @idx;
            $first_level[$first_idx]= $seed2;
            @second_level[@idx]= map {

                +{
                    key   => $_,
                    hash  => $key_to_hash->{$_},
                    value => $hash->{$_},
                    seed2 => 0,
                }
            } @$keys;
            last;
        }

    }
    $second_level[$_]{seed2}= $first_level[$_] || 0, $second_level[$_]{idx}= $_
        for 0 .. $#second_level;

    return $seed1, \@second_level;
}

sub _sort_keys_longest_first {
    my ($hash)= shift;
    my @keys= sort { length($b) <=> length($a) || $a cmp $b } keys %$hash;
    return \@keys;
}

# This sub constructs a blob of characters which can be used to
# reconstruct the keys of the $hash that is passed in to it, possibly
# and likely by splitting the keys into two parts, a prefix and a
# suffix. This allows prefixes and suffixes to be reused for more than
# one original key.
#
# It returns a hash that contains each key in the argument $hash with
# each value being the position where it is split, using the length of
# the key to indicate it need not be split at all.
#
# If $preprocess is false the process starts with an empty buffer and
# populates it as it adds each new key, if $preprocess is true then it
# tries to split each key at the '=' sign which is often present in
# Unicode property names and composes the initial buffer from these
# fragments.
#
# It performs multiple passes trying to find the ideal split point to
# produce a minimal buffer, returning the smallest buffer it can.
sub build_split_words {
    my ($hash, $preprocess, $length_all_keys)= @_;
    my %appended;
    my $blob= "";
    if ($preprocess) {
        my %parts;
        foreach my $key (@{ _sort_keys_longest_first($hash) }) {
            my ($prefix, $suffix);
            if ($key =~ /^([^=]+=)([^=]+)\z/) {
                ($prefix, $suffix)= ($1, $2);
                $parts{$suffix}++;

                #$parts{$prefix}++;
            }
            else {
                $prefix= $key;
                $parts{$prefix}++;
            }

        }
        foreach my $part (@{ _sort_keys_longest_first(\%parts) }) {
            $blob .= $part;
        }
        printf "Using preprocessing, initial blob size is %d chars.\n",
            length($blob);
    }
    else {
        print "No preprocessing, starting with an empty blob.\n";
    }
    my ($res, $old_res, $added, $passes);

    REDO:
    $res= {};
    $added= 0;
    $passes++;

    KEY:
    foreach my $key (@{ _sort_keys_longest_first($hash) }) {
        next if exists $res->{$key};
        if (index($blob, $key) >= 0) {
            my $idx= length($key);
            if ($DEBUG and $old_res and $old_res->{$key} != $idx) {
                print "changing: $key => $old_res->{$key} : $idx\n";
            }
            $res->{$key}= $idx;
            next KEY;
        }
        my $best= length($key);
        my $append= $key;
        my $best_prefix= $key;
        my $best_suffix= "";
        my $min= 1;
        foreach my $idx (reverse $min .. length($key) - 1) {
            my $prefix= substr($key, 0, $idx);
            my $suffix= substr($key, $idx);
            my $i1= index($blob, $prefix) >= 0;
            my $i2= index($blob, $suffix) >= 0;
            if ($i1 and $i2) {
                if ($DEBUG and $old_res and $old_res->{$key} != $idx) {
                    print "changing: $key => $old_res->{$key} : $idx\n";
                }
                $res->{$key}= $idx;
                $appended{$prefix}++;
                $appended{$suffix}++;
                next KEY;
            }
            elsif ($i1) {
                if (length $suffix <= length $append) {
                    $best= $idx;
                    $append= $suffix;
                    $best_prefix= $prefix;
                    $best_suffix= $suffix;
                }
            }
            elsif ($i2) {
                if (length $prefix <= length $append) {
                    $best= $idx;
                    $append= $prefix;
                    $best_prefix= $prefix;
                    $best_suffix= $suffix;
                }
            }
        }
        if ($DEBUG and $old_res and $old_res->{$key} != $best) {
            print "changing: $key => $old_res->{$key} : $best\n";
        }

        #print "$best_prefix|$best_suffix => $best => $append\n";
        $res->{$key}= $best;
        $blob .= $append;
        $added += length($append);
        $appended{$best_prefix}++;
        $appended{$best_suffix}++;
    }
    if ($added) {
        if ($added < length $blob) {
            printf "Appended %d chars. Blob is %d chars long.\n",
                $added, length($blob);
        }
        else {
            printf "Blob is %d chars long.\n", $added;
        }
    }
    elsif ($passes > 1) {
        print "Blob needed no changes.\n";
    }
    my $new_blob= "";
    foreach my $part (@{ _sort_keys_longest_first(\%appended) }) {
        $new_blob .= $part unless index($new_blob, $part) >= 0;
    }
    if (length($new_blob) < length($blob)) {
        printf "Uncorrected new blob length of %d chars is smaller.\n"
            . "  Correcting new blob...%s",
            length($new_blob), $DEBUG ? "\n" : " ";
        $blob= $new_blob;
        $old_res= $res;
        %appended= ();
        goto REDO;
    }
    else {
        printf "After %d passes final blob length is %d chars.\n"
            . "This is %.2f%% of the raw key length of %d chars.\n\n",
            $passes, length($blob), 100 * length($blob) / $length_all_keys,
            $length_all_keys;
    }

    # sanity check
    die sprintf "not same size? %d != %d", 0 + keys %$res, 0 + keys %$hash
        unless keys %$res == keys %$hash;
    return ($blob, $res, $length_all_keys);
}

sub blob_as_code {
    my ($blob, $blob_name)= @_;

    $blob_name ||= "mph_blob";

    # output the blob as C code.
    my @code= (sprintf "STATIC const unsigned char %s[] =\n", $blob_name);
    my $blob_len= length $blob;
    while (length($blob)) {
        push @code, sprintf qq(    "%s"), substr($blob, 0, 65, "");
        push @code, length $blob ? "\n" : ";\n";
    }
    push @code, "/* $blob_name length: $blob_len */\n";
    return join "", @code;
}

sub print_includes {
    my $ofh= shift;
    print $ofh "#include <stdio.h>\n";
    print $ofh "#include <string.h>\n";
    print $ofh "#include <stdint.h>\n";
    print $ofh "\n";
}

sub print_defines {
    my ($ofh, $defines)= @_;

    my $key_len;
    foreach my $def (keys %$defines) {
        $key_len //= length $def;
        $key_len= length $def if $key_len < length $def;
    }
    foreach my $def (sort keys %$defines) {
        printf $ofh "#define %*s %5d\n", -$key_len, $def, $defines->{$def};
    }
    print $ofh "\n";
}

sub build_array_of_struct {
    my ($second_level, $blob)= @_;

    my %defines;
    my %tests;
    my @rows;
    foreach my $row (@$second_level) {
        $defines{ $row->{value} }= $row->{idx} + 1;
        $tests{ $row->{key} }= $defines{ $row->{value} };
        ##!
        my @u16= (
            $row->{seed2},
            index($blob, $row->{prefix} // 0),
            index($blob, $row->{suffix} // 0),
        );
        $_ > U16_MAX and die "panic: value exceeds range of U16" 
            for @u16;
        my @u8= (
            length($row->{prefix}), 
            length($row->{suffix}),
        );
        $_ > U8_MAX and die "panic: value exceeds range of U8" 
            for @u8;
        push @rows, sprintf "  { %5d, %5d, %5d, %3d, %3d, %s }   /* %s%s */",
            @u16, @u8, $row->{value}, $row->{prefix}, $row->{suffix};
        ##.
    }
    return \@rows, \%defines, \%tests;
}

sub make_algo {
    my (
        $second_level, $seed1,     $length_all_keys, $smart_blob,
        $rows,         $blob_name, $struct_name,     $table_name,
        $match_name,   $prefix
    )= @_;

    $blob_name   ||= "mph_blob";
    $struct_name ||= "mph_struct";
    $table_name  ||= "mph_table";
    $prefix      ||= "MPH";

    my $n= 0 + @$second_level;
    my $data_size= 0 + @$second_level * 8 + length $smart_blob;

    my @code= "#define ${prefix}_VALt I16\n\n";
    push @code, "/*\n";
    push @code, sprintf "rows: %s\n",                $n;
    push @code, sprintf "seed: %s\n",                $seed1;
    push @code, sprintf "full length of keys: %d\n", $length_all_keys;
    push @code, sprintf "blob length: %d\n",         length $smart_blob;
    push @code, sprintf "ref length: %d\n",          0 + @$second_level * 8;
    push @code, sprintf "data size: %d (%%%.2f)\n", $data_size,
        ($data_size / $length_all_keys) * 100;
    push @code, "*/\n\n";

    push @code, blob_as_code($smart_blob, $blob_name);
    push @code, <<"EOF_CODE";

struct $struct_name {
    U16 seed2;
    U16 pfx;
    U16 sfx;
    U8  pfx_len;
    U8  sfx_len;
    ${prefix}_VALt value;
};

EOF_CODE

    push @code, "#define ${prefix}_RSHIFT $RSHIFT\n";
    push @code, "#define ${prefix}_BUCKETS $n\n\n";
    push @code, sprintf "STATIC const U32 ${prefix}_SEED1 = 0x%08x;\n", $seed1;
    push @code, sprintf "STATIC const U32 ${prefix}_FNV32_PRIME = 0x%08x;\n\n",
        FNV32_PRIME;

    push @code, "/* The comments give the input key for the row it is in */\n";
    push @code,
        "STATIC const struct $struct_name $table_name\[${prefix}_BUCKETS] = {\n",
        join(",\n", @$rows) . "\n};\n\n";
    push @code, <<"EOF_CODE";
${prefix}_VALt $match_name( const unsigned char * const key, const U16 key_len ) {
    const unsigned char * ptr= key;
    const unsigned char * ptr_end= key + key_len;
    U32 h= ${prefix}_SEED1;
    U32 s;
    U32 n;
    /* this is FNV-1a 32bit unrolled. */
    do {
        h ^= NATIVE_TO_LATIN1(*ptr);    /* table collated in Latin1 */
        h *= ${prefix}_FNV32_PRIME;
    } while ( ++ptr < ptr_end );
    n= h % ${prefix}_BUCKETS;
    s = $table_name\[n].seed2;
    if (s) {
        h= (h >> ${prefix}_RSHIFT) ^ s;
        n = h % ${prefix}_BUCKETS;
        if (
            ( $table_name\[n].pfx_len + $table_name\[n].sfx_len == key_len ) &&
            ( memcmp($blob_name + $table_name\[n].pfx, key, $table_name\[n].pfx_len) == 0 ) &&
            ( !$table_name\[n].sfx_len || memcmp($blob_name + $table_name\[n].sfx,
                key + $table_name\[n].pfx_len, $table_name\[n].sfx_len) == 0 )
        ) {
            return $table_name\[n].value;
        }
    }
    return 0;
}
EOF_CODE

    return join "", @code;
}

sub print_algo {
    my (
        $ofh,  $second_level, $seed1,       $long_blob,  $smart_blob,
        $rows, $blob_name,    $struct_name, $table_name, $match_name
    )= @_;

    if (!ref $ofh) {
        my $file= $ofh;
        undef $ofh;
        open $ofh, ">", $file
            or die "Failed to open '$file': $!";
    }

    my $code= make_algo(
        $second_level, $seed1,       $long_blob,  $smart_blob, $rows,
        $blob_name,    $struct_name, $table_name, $match_name
    );
    print $ofh $code;
}

sub print_main {
    my ($ofh, $h_file, $match_name, $prefix)= @_;
    print $ofh <<"EOF_CODE";
#include "$h_file"

int main(int argc, char *argv[]){
    int i;
    for (i=1; i<argc; i++) {
        unsigned char *key = (unsigned char *)argv[i];
        int key_len = strlen(argv[i]);
        printf("key: %s got: %d\\n", key, $match_name((unsigned char *)key,key_len));
    }
    return 0;
}
EOF_CODE
}

# output the test Perl code.
sub print_tests {
    my ($file, $tests_hash)= @_;
    open my $ofh, ">", $file
        or die "Failed to open '$file' for writing: $!";
    my $num_tests= 2 + keys %$tests_hash;
    print $ofh
        "use strict;\nuse warnings;\nuse Test::More tests => $num_tests;\nmy \@res;";
    my $bytes= 0;
    my @tests= sort keys %$tests_hash;
    print $ofh
        "\@res=`./mph_test '$tests[0]/should-not-match' 'should-not-match/$tests[0]'`;\n";
    print $ofh "ok( \$res[0] =~ /got: 0/,'proper prefix does not match');\n";
    print $ofh "ok( \$res[1] =~ /got: 0/,'proper suffix does not match');\n";

    while (@tests) {
        my @batch= splice @tests, 0, 10;
        my $batch_args= join " ", map { "'$_'" } @batch;
        print $ofh "\@res=`./mph_test $batch_args`;\n";
        foreach my $i (0 .. $#batch) {
            my $key= $batch[$i];
            my $want= $tests_hash->{$key};
            print $ofh
                "ok(\$res[$i]=~/got: (\\d+)/ && \$1 == $want, '$key');\n";
        }
    }
    close $ofh;
}

sub print_test_binary {
    my (
        $file,            $h_file,     $second_level, $seed1,
        $length_all_keys, $smart_blob, $rows,         $defines,
        $match_name,      $prefix
    )= @_;
    open my $ofh, ">", $file
        or die "Failed to open '$file': $!";
    print_includes($ofh);
    print_defines($ofh, $defines);
    print_main($ofh, $h_file, $match_name, $prefix);
    close $ofh;
}

sub make_mph_from_hash {
    my $hash= shift;

    my $length_all_keys= 0;
    $length_all_keys += length($_) for keys %$hash;

    # we do this twice because often we can find longer prefixes on the second pass.
    my ($smart_blob, $res_to_split)=
        build_split_words($hash, 0, $length_all_keys);
    {
        my ($smart_blob2, $res_to_split2)=
            build_split_words($hash, 1, $length_all_keys);
        if (length($smart_blob) > length($smart_blob2)) {
            printf "Using preprocess-smart blob, length: %d (vs %d)\n",
                length $smart_blob2, length $smart_blob;
            $smart_blob= $smart_blob2;
            $res_to_split= $res_to_split2;
        }
        else {
            printf "Using greedy-smart blob, length: %d (vs %d)\n",
                length $smart_blob, length $smart_blob2;
        }
    }
    my ($seed1, $second_level)= build_perfect_hash($hash);

    # add prefix/suffix data into the bucket info in @$second_level
    foreach my $bucket_info (@$second_level) {
        my $key= $bucket_info->{key};
        my $sp= $res_to_split->{$key} // die "no split pos for '$key'\n";

        my ($prefix, $suffix)= unpack "A${sp}A*", $key;
        $bucket_info->{prefix}= $prefix;
        $bucket_info->{suffix}= $suffix;
    }
    my ($rows, $defines, $tests)=
        build_array_of_struct($second_level, $smart_blob);
    return ($second_level, $seed1, $length_all_keys, $smart_blob, $rows,
        $defines, $tests);
}

sub make_files {
    my ($hash, $base_name)= @_;

    my $h_name= $base_name . "_algo.h";
    my $c_name= $base_name . "_test.c";
    my $p_name= $base_name . "_test.pl";
    my $blob_name= $base_name . "_blob";
    my $struct_name= $base_name . "_bucket_info";
    my $table_name= $base_name . "_table";
    my $match_name= $base_name . "_match";
    my $prefix= uc($base_name);

    my ($second_level, $seed1, $length_all_keys,
        $smart_blob, $rows, $defines, $tests)
        = make_mph_from_hash($hash);
    print_algo(
        $h_name,     $second_level, $seed1,     $length_all_keys,
        $smart_blob, $rows,         $blob_name, $struct_name,
        $table_name, $match_name,   $prefix
    );
    print_test_binary(
        $c_name,          $h_name,     $second_level, $seed1,
        $length_all_keys, $smart_blob, $rows,         $defines,
        $match_name,      $prefix
    );
    print_tests($p_name, $tests);
}

unless (caller) {
    my %hash;
    {
        no warnings;
        do "../perl/lib/unicore/UCD.pl";
        %hash= %utf8::loose_to_file_of;
    }
    if ($ENV{MERGE_KEYS}) {
        my @keys= keys %hash;
        foreach my $loose (keys %utf8::loose_property_name_of) {
            my $to= $utf8::loose_property_name_of{$loose};
            next if $to eq $loose;
            foreach my $key (@keys) {
                my $copy= $key;
                if ($copy =~ s/^\Q$to\E(=|\z)/$loose$1/) {

                    #print "$key => $copy\n";
                    $hash{$copy}= $key;
                }
            }
        }
    }
    foreach my $key (keys %hash) {
        my $munged= uc($key);
        $munged =~ s/\W/__/g;
        $hash{$key}= $munged;
    }

    my $name= shift @ARGV;
    $name ||= "mph";
    make_files(\%hash, $name);
}

1;
__END__
