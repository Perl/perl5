#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

# This is purposefully simple - hence the O(n) linear searches.
package TestIterators {
    sub TIEHASH {
        bless [], $_[0];
    }

    sub STORE {
        my ($self, $key, $value) = @_;
        push @{$self->[0]}, $key;
        push @{$self->[1]}, $value;
        return $value;
    }

    sub FETCH {
        my ($self, $key) = @_;
        my $i = 0;
        while ($i < @{$self->[0]}) {
            return $self->[1][$i]
                if $self->[0][$i] eq $key;
            ++$i;
        }
        die "$key not found in FETCH";
    }

    sub FIRSTKEY {
        my $self = shift;
        $self->[0][0];
    }

    # As best I can tell, none of our other tie tests actually use the first
    # parameter to nextkey. It's actually (a copy of) the previously returned
    # key. We're not *so* thorough here as to actually hide some state and
    # cross-check that, but the longhand tests below should effectively validate
    # it.
    sub NEXTKEY {
        my ($self, $key) = @_;
        my $i = 0;
        while ($i < @{$self->[0]}) {
            return $self->[0][$i + 1]
                if $self->[0][$i] eq $key;
            ++$i;
        }
        die "$key not found in NEXTKEY";
    }
};

{
    my %h;
    tie %h, 'TestIterators';

    $h{beer} = "foamy";
    $h{perl} = "rules";

    is($h{beer}, "foamy", "found first key");
    is($h{perl}, "rules", "found second key");
    is(eval {
        my $k = $h{decaf};
        1;
    }, undef, "missing key was not found");
    like($@, qr/\Adecaf not found in FETCH/, "with the correct error");

    is(each %h, 'beer', "first iterator");
    is(each %h, 'perl', "second iterator");
    is(each %h, undef, "third iterator is undef");
}

done_testing();
