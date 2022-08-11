package Porting::updateAUTHORS;
use strict;
use warnings;
use Data::Dumper;
use Encode qw(encode_utf8 decode_utf8 decode);

# The style of this file is determined by:
#
# perltidy -w -ple -bbb -bbc -bbs -nolq -l=80 -noll -nola -nwls='=' \
#   -isbc -nolc -otr -kis -ci=4 -se -sot -sct -nsbl -pt=2 -fs  \
#   -fsb='#start-no-tidy' -fse='#end-no-tidy'

# Info and config for passing to git log.
#   %an: author name
#   %aN: author name (respecting .mailmap, see git-shortlog(1) or git-blame(1))
#   %ae: author email
#   %aE: author email (respecting .mailmap, see git-shortlog(1) or git-blame(1))
#   %cn: committer name
#   %cN: committer name (respecting .mailmap, see git-shortlog(1) or git-blame(1))
#   %ce: committer email
#   %cE: committer email (respecting .mailmap, see git-shortlog(1) or git-blame(1))
#   %H: commit hash
#   %h: abbreviated commit hash
#   %s: subject
#   %x00: print a byte from a hex code

my %field_spec= (
    "an" => "author_name",
    "aN" => "author_name_mm",
    "ae" => "author_email",
    "aE" => "author_email_mm",
    "cn" => "committer_name",
    "cN" => "committer_name_mm",
    "ce" => "committer_email",
    "cE" => "committer_email_mm",
    "H"  => "commit_hash",
    "h"  => "abbrev_hash",
    "s"  => "commit_subject",
);

my @field_codes= sort keys %field_spec;
my @field_names= map { $field_spec{$_} } @field_codes;
my $tformat= join "%x00", map { "%" . $_ } @field_codes;

sub _make_name_author_info {
    my ($self, $commit_info, $name_key)= @_;
    my $author_info= $self->{author_info};
    (my $email_key= $name_key) =~ s/name/email/;
    my $email= $commit_info->{$email_key};
    my $name= $commit_info->{$name_key};

    my $line= $author_info->{"email2line"}{$email}
        // $author_info->{"name2line"}{$name};

    $line //= sprintf "%-31s<%s>",
        $commit_info->{$name_key}, $commit_info->{$email_key};
    return $line;
}

sub _make_name_simple {
    my ($self, $commit_info, $key)= @_;
    my $name_key= $key . "_name";
    my $email_key= $key . "_email";
    return sprintf "%s <%s>", $commit_info->{$name_key},
        lc($commit_info->{$email_key});
}

sub read_commit_log {
    my ($self)= @_;
    my $author_info= $self->{author_info}   ||= {};
    my $mailmap_info= $self->{mailmap_info} ||= {};

    open my $fh, qq(git log --pretty='tformat:$tformat' |);
    while (defined(my $line= <$fh>)) {
        chomp $line;
        $line= decode_utf8($line);
        my $commit_info= {};
        @{$commit_info}{@field_names}= split /\0/, $line, 0 + @field_names;

        my $author_name_mm=
            $self->_make_name_author_info($commit_info, "author_name_mm");

        my $committer_name_mm=
            $self->_make_name_author_info($commit_info, "committer_name_mm");

        my $author_name_real= $self->_make_name_simple($commit_info, "author");

        my $committer_name_real=
            $self->_make_name_simple($commit_info, "committer");

        $self->_check_name_mailmap($author_name_mm, $author_name_real,
            $commit_info, "author name");
        $self->_check_name_mailmap(
            $committer_name_mm, $committer_name_real,
            $commit_info,       "committer name"
        );

        $author_info->{"lines"}{$author_name_mm}++;
        $author_info->{"lines"}{$committer_name_mm}++;
    }
    return $author_info;
}

sub read_authors {
    my ($self)= @_;
    my $authors_file= $self->{authors_file};

    my @authors_preamble;
    open my $in_fh, "<", $authors_file
        or die "Failed to open for read '$authors_file': $!";
    my $raw_text= "";
    while (defined(my $line= <$in_fh>)) {
        $raw_text .= $line;
        $line= decode_utf8($line);
        chomp $line;
        push @authors_preamble, $line;
        if ($line =~ /^--/) {
            last;
        }
    }
    my %author_info;
    while (defined(my $line= <$in_fh>)) {
        $raw_text .= $line;
        $line= decode_utf8($line);
        chomp $line;
        my ($name, $email);
        my $copy= $line;
        $copy =~ s/\s+\z//;
        if ($copy =~ s/<([^<>]*)>//) {
            $email= $1;
        }
        elsif ($copy =~ s/\s+(\@\w+)\z//) {
            $email= $1;
        }
        $copy =~ s/\s+\z//;
        $name= $copy;
        $email //= "unknown";
        $email= lc($email);

        $author_info{"lines"}{$line}++;
        $author_info{"email2line"}{$email}= $line
            if $email and $email ne "unknown";
        $author_info{"name2line"}{$name}= $line
            if $name and $name ne "unknown";
        $author_info{"email2name"}{ lc($email) }= $name
            if $email
            and $name
            and $email ne "unknown";
        $author_info{"name2email"}{$name}= $email
            if $name and $name ne "unknown";
    }
    close $in_fh
        or die "Failed to close '$authors_file': $!";

    $self->{author_info}= \%author_info;
    $self->{authors_preamble}= \@authors_preamble;
    $self->{authors_raw_text}= $raw_text;
    return (\%author_info, \@authors_preamble, $raw_text);
}

sub update_authors {
    my ($self)= @_;

    my $author_info= $self->{author_info};
    my $authors_preamble= $self->{authors_preamble};
    my $authors_file= $self->{authors_file};
    my $old_raw_text= $self->{authors_raw_text};

    my $authors_file_new= $authors_file . ".new";
    my $new_raw_text= "";
    {
        open my $out_fh, ">", \$new_raw_text
            or die "Failed to open scalar buffer for write: $!";
        foreach my $line (@$authors_preamble) {
            print $out_fh encode_utf8($line), "\n"
                or die "Failed to print to scalar buffer handle: $!";
        }
        foreach my $author (__sorted_hash_keys($author_info->{"lines"})) {
            next if $author =~ /^unknown/;
            if ($author =~ s/\s*<unknown>\z//) {
                next if $author =~ /^\w+$/;
            }
            print $out_fh encode_utf8($author), "\n"
                or die "Failed to print to scalar buffer handle: $!";
        }
        close $out_fh
            or die "Failed to close scalar buffer handle: $!";
    }
    if ($new_raw_text ne $old_raw_text) {
        $self->{changed_count}++;
        $self->{changed_file}{$authors_file}++;

        warn "Updating '$authors_file'\n" if $self->{verbose};

        open my $out_fh, ">", $authors_file_new
            or die "Failed to open for write '$authors_file_new': $!";
        binmode $out_fh;
        print $out_fh $new_raw_text;
        close $out_fh
            or die "Failed to close '$authors_file_new': $!";
        rename $authors_file_new, $authors_file
            or die
            "Failed to rename '$authors_file_new' to '$authors_file': $!";
        return 1;
    }
    else {
        return 0;
    }
}

sub read_mailmap {
    my ($self)= @_;
    my $mailmap_file= $self->{mailmap_file};

    open my $in, "<", $mailmap_file
        or die "Failed to read '$mailmap_file': $!";
    my %mailmap_hash;
    my @mailmap_preamble;
    my $line_num= 0;
    my $raw_text= "";
    while (defined(my $line= <$in>)) {
        $raw_text .= $line;
        $line= decode_utf8($line);
        ++$line_num;
        next unless $line =~ /\S/;
        chomp($line);
        if ($line =~ /^#/) {
            if (!keys %mailmap_hash) {
                push @mailmap_preamble, $line;
            }
            else {
                die encode_utf8 "Not expecting comments after header ",
                    "finished at line $line_num!\nLine: $line\n";
            }
        }
        else {
            $mailmap_hash{$line}= $line_num;
        }
    }
    close $in
        or die "Failed to close '$mailmap_file' after reading: $!";
    $self->{orig_mailmap_hash}= \%mailmap_hash;
    $self->{mailmap_preamble}= \@mailmap_preamble;
    $self->{mailmap_raw_text}= $raw_text;
    return (\%mailmap_hash, \@mailmap_preamble, $raw_text);
}

# this can be used to extract data from the checkAUTHORS data
sub merge_mailmap_with_AUTHORS_and_checkAUTHORS_data {
    my ($self, $mailmap_hash, $author_info)= @_;
    require 'Porting/checkAUTHORS.pl' or die "No authors?";
    my ($map, $preferred_email_or_github)=
        Porting::checkAUTHORS::generate_known_author_map();

    foreach my $old (sort keys %$preferred_email_or_github) {
        my $new= $preferred_email_or_github->{$old};
        next if $old !~ /\@/ or $new !~ /\@/ or $new eq $old;
        my $name= $author_info->{"email2name"}{$new};
        if ($name) {
            my $line= "$name <$new> <$old>";
            $mailmap_hash->{$line}++;
        }
    }
    return 1;    # ok
}

sub __sorted_hash_keys {
    my ($hash)= @_;
    my @sorted= sort { lc($a) cmp lc($b) || $a cmp $b } keys %$hash;
    return @sorted;
}

# Returns 0 if the file needed to be changed, Return 1 if it does not.
sub update_mailmap {
    my ($self)= @_;
    my $mailmap_hash= $self->{new_mailmap_hash};
    my $mailmap_preamble= $self->{mailmap_preamble};
    my $mailmap_file= $self->{mailmap_file};
    my $old_raw_text= $self->{mailmap_raw_text};

    my $new_raw_text= "";
    {
        open my $out, ">", \$new_raw_text
            or die "Failed to open scalar buffer for write: $!";
        foreach
            my $line (@$mailmap_preamble, __sorted_hash_keys($mailmap_hash),)
        {
            print $out encode_utf8($line), "\n"
                or die "Failed to print to scalar buffer handle: $!";
        }
        close $out
            or die "Failed to close scalar buffer handle: $!";
    }
    if ($new_raw_text ne $old_raw_text) {
        $self->{changed_count}++;
        $self->{changed_file}{$mailmap_file}++;

        warn "Updating '$mailmap_file'\n"
            if $self->{verbose};

        my $mailmap_file_new= $mailmap_file . ".new";
        open my $out, ">", $mailmap_file_new
            or die "Failed to write '$mailmap_file_new': $!";
        binmode $out
            or die "Failed to binmode '$mailmap_file_new': $!";
        print $out $new_raw_text
            or die "Failed to print to '$mailmap_file_new': $!";
        close $out
            or die "Failed to close '$mailmap_file_new' after writing: $!";
        rename $mailmap_file_new, $mailmap_file
            or die
            "Failed to rename '$mailmap_file_new' to '$mailmap_file': $!";
        return 1;
    }
    else {
        return 0;
    }
}

sub parse_orig_mailmap_hash {
    my ($self)= @_;
    my $mailmap_hash= $self->{orig_mailmap_hash};

    my @recs;
    foreach my $line (sort keys %$mailmap_hash) {
        my $line_num= $mailmap_hash->{$line};
        $line =~ /^ \s* (?: ( [^<>]*? ) \s+ )? <([^<>]*)>
                (?: \s+ (?: ( [^<>]*? ) \s+ )? <([^<>]*)> )? \s* \z /x
            or die encode_utf8 "Failed to parse line num $line_num: '$line'";
        if (!$1 or !$2) {
            die encode_utf8 "Both preferred name and email are mandatory ",
                "in line num $line_num: '$line'";
        }

        # [ preferred_name, preferred_email, other_name, other_email ]
        push @recs, [ $1, $2, $3, $4, $line_num ];
    }
    return \@recs;
}

sub _safe_set_key {
    my ($self, $hash, $root_key, $key, $val, $pretty_name)= @_;
    $hash->{$root_key}{$key} //= $val;
    my $prev= $hash->{$root_key}{$key};
    if ($prev ne $val) {
        die encode_utf8 "Collision on mapping $root_key: "
            . " '$key' maps to '$prev' and '$val'\n";
    }
}

my $O2P= "other2preferred";
my $O2PN= "other2preferred_name";
my $O2PE= "other2preferred_email";
my $P2O= "preferred2other";
my $N2P= "name2preferred";
my $E2P= "email2preferred";

my $blurb= "";    # FIXME - replace with a nice message

sub _check_name_mailmap {
    my ($self, $auth_name, $raw_name, $commit_info, $descr)= @_;
    my $mailmap_info= $self->{mailmap_info};

    my $name= $auth_name;
    $name =~ s/<([^<>]+)>/<\L$1\E>/
        or $name =~ s/(\s)(\@\w+)\z/$1<\L$2\E>/
        or $name .= " <unknown>";

    $name =~ s/\s+/ /g;

    if (!$mailmap_info->{$P2O}{$name}) {
        warn encode_utf8 sprintf "Unknown %s '%s' in commit %s '%s'\n%s",
            $descr,
            $name,
            $commit_info->{"abbrev_hash"},
            $commit_info->{"commit_subject"},
            $blurb;
        $mailmap_info->{add}{"$name $raw_name"}++;
        return 0;
    }
    elsif (!$mailmap_info->{$P2O}{$name}{$raw_name}) {
        $mailmap_info->{add}{"$name $raw_name"}++;
    }
    return 1;
}

sub check_fix_mailmap_hash {
    my ($self)= @_;
    my $mailmap_hash= $self->{orig_mailmap_hash};
    my $author_info= $self->{author_info};

    my $parsed= $self->parse_orig_mailmap_hash();
    my @fixed;
    my %seen_map;
    my %pref_groups;

    # first pass through the data, do any conversions, eg, LC
    # the email address, decode any MIME-Header style email addresses.
    # We also correct any preferred name entries so they match what
    # we already have in AUTHORS, and check that there aren't collisions
    # or other issues in the data.
    foreach my $rec (@$parsed) {
        my ($pname, $pemail, $oname, $oemail, $line_num)= @$rec;
        $pemail= lc($pemail);
        $oemail= lc($oemail) if defined $oemail;
        if ($pname =~ /=\?UTF-8\?/) {
            $pname= decode("MIME-Header", $pname);
        }
        my $auth_email= $author_info->{"name2email"}{$pname};
        if ($auth_email) {
            ## this name exists in authors, so use its email data for pemail
            $pemail= $auth_email;
        }
        my $auth_name= $author_info->{"email2name"}{$pemail};
        if ($auth_name) {
            ## this email exists in authors, so use its name data for pname
            $pname= $auth_name;
        }

        # neither name nor email exist in authors.
        if ($pname ne "unknown") {
            if (my $email= $seen_map{"name"}{$pname}) {
                ## we have seen this pname before, check the pemail
                ## is consistent
                if ($email ne $pemail) {
                    warn encode_utf8 "Inconsistent emails for name '$pname'"
                        . " at line num $line_num: keeping '$email',"
                        . " ignoring '$pemail'\n";
                    $pemail= $email;
                }
            }
            else {
                $seen_map{"name"}{$pname}= $pemail;
            }
        }
        if ($pemail ne "unknown") {
            if (my $name= $seen_map{"email"}{$pemail}) {
                ## we have seen this preferred_email before, check the preferred_name
                ## is consistent
                if ($name ne $pname) {
                    warn encode_utf8 "Inconsistent name for email '$pemail'"
                        . " at line num $line_num: keeping '$name', ignoring"
                        . " '$pname'\n";
                    $pname= $name;
                }
            }
            else {
                $seen_map{"email"}{$pemail}= $pname;
            }
        }

        # Build an index of "preferred name/email" to other-email, other name
        # we use this later to remove redundant entries missing a name.
        $pref_groups{"$pname $pemail"}{$oemail}{ $oname || "" }=
            [ $pname, $pemail, $oname, $oemail, $line_num ];
    }

    # this removes entries like
    # Joe <blogs> <whatever>
    # where there is a corresponding
    # Joe <blogs> Joe X <blogs>
    foreach my $pref (__sorted_hash_keys(\%pref_groups)) {
        my $entries= $pref_groups{$pref};
        foreach my $email (__sorted_hash_keys($entries)) {
            my @names= __sorted_hash_keys($entries->{$email});
            if ($names[0] eq "" and @names > 1) {
                shift @names;
            }
            foreach my $name (@names) {
                push @fixed, $entries->{$email}{$name};
            }
        }
    }

    # final pass through the dataset, build up a database
    # we will use later for checks and updates, and reconstruct
    # the canonical entries.
    my $new_mailmap_hash= {};
    my $mailmap_info=     {};
    foreach my $rec (@fixed) {
        my ($pname, $pemail, $oname, $oemail, $line_num)= @$rec;
        my $preferred= "$pname <$pemail>";
        my $other;
        if (defined $oemail) {
            $other= $oname ? "$oname <$oemail>" : "<$oemail>";
        }
        if ($other and $other ne "<unknown>") {
            $self->_safe_set_key($mailmap_info, $O2P,  $other, $preferred);
            $self->_safe_set_key($mailmap_info, $O2PN, $other, $pname);
            $self->_safe_set_key($mailmap_info, $O2PE, $other, $pemail);
        }
        $mailmap_info->{$P2O}{$preferred}{$other}++;
        if ($pname ne "unknown") {
            $self->_safe_set_key($mailmap_info, $N2P, $pname, $preferred);
        }
        if ($pemail ne "unknown") {
            $self->_safe_set_key($mailmap_info, $E2P, $pemail, $preferred);
        }
        my $line= $preferred;
        $line .= " $other" if $other;
        $new_mailmap_hash->{$line}= $line_num;
    }
    $self->{new_mailmap_hash}= $new_mailmap_hash;
    $self->{mailmap_info}= $mailmap_info;
    return ($new_mailmap_hash, $mailmap_info);
}

sub add_new_mailmap_entries {
    my ($self)= @_;
    my $mailmap_hash= $self->{new_mailmap_hash};
    my $mailmap_info= $self->{mailmap_info};
    my $mailmap_file= $self->{mailmap_file};

    my $mailmap_add= $mailmap_info->{add}
        or return 0;

    my $num= 0;
    for my $new (sort keys %$mailmap_add) {
        !$mailmap_hash->{$new}++ or next;
        warn encode_utf8 "Updating '$mailmap_file' with: $new\n";
        $num++;
    }
    return $num;
}

sub read_and_update {
    my ($self)= @_;
    my ($authors_file, $mailmap_file)=
        %{$self}{qw(authors_file mailmap_file)};

    # read the authors file and extract the info it contains
    $self->read_authors();

    # read the mailmap file.
    $self->read_mailmap();

    # check and possibly fix the mailmap data, and build a set of precomputed
    # datasets to work with it.
    $self->check_fix_mailmap_hash();

    # update the mailmap based on any check or fixes we just did.
    $self->update_mailmap();

    # read the commits names using git log, and compares and checks
    # them against the data we have in authors.
    $self->read_commit_log();

    # update the authors file with any changes
    $self->update_authors();

    # check if we discovered new email data from the commits that
    # we need to write back to disk.
    $self->add_new_mailmap_entries()
        and $self->update_mailmap();

    return $self->changed_count();
}

sub changed_count {
    my ($self)= @_;
    return $self->{changed_count};
}

sub changed_file {
    my ($self, $name)= @_;
    return $self->{changed_file}{$name};
}

sub unchanged_file {
    my ($self, $name)= @_;
    return $self->changed_file($name) ? 0 : 1;
}

sub new {
    my ($class, %self)= @_;
    $self{changed_count}= 0;
    for my $name (qw(authors_file mailmap_file)) {
        $self{$name}
            or die "Property '$name' is mandatory in constructor";
    }

    my $self= bless \%self, $class;
    return $self;
}

1;
__END__

=head1 NAME

Porting::updateAUTHORS - Library to automatically update AUTHORS and .mailmap based on commit data.

=head1 SYNOPSIS

    use Porting::updateAUTHORS;

    my $updater= Porting::updateAUTHORS->new(
        authors_file => "AUTHORS",
        mailmap_file => ".mailmap",
    );
    $updater->read_and_update();

=head1 DESCRIPTION

This the brain of the F<Porting/updateAUTHORS.pl> script. It is expected
to be used B<from> that script and B<by> that script. Most features and
options are documented in the F<Porting/updateAUTHORS.pl> and are not
explicitly documented here, read the F<Porting/updateAUTHORS.pl> manpage
for more details.

=head1 METHODS

Porting::updateAUTHORS uses OO as way of managing its internal state.
This documents the public methods it exposes.

=over 4

=item add_new_mailmap_entries()

If any additions were identified while reading the commits this will
inject them into the mailmap_hash so they can be written out. Returns a
count of additions found.

=item check_fix_mailmap_hash()

Analyzes the data contained the in the .mailmap file and applies any
automated fixes which are required and which it can automatically
perform. Returns a hash of adjusted entries and a hash with additional
metadata about the mailmap entries.

=item new(%opts)

Create a new object. Required parameters are

    authors_file
    mailmap_file

Other supported parameters are as follows:

    verbose

this list is not exhaustive. See the code implementing the main()
function in F<Porting/updateAUTHORS.pl> for an exhaustive list.

=item merge_mailmap_with_AUTHORS_and_checkAUTHORS_data

This is a utility function that combines data from this tool with data
contained in F<Porting/checkAUTHORS.pl> it is not used directly, but was
used to cleanup and generate the current version of the .mailmap file.

Will be deleted.

=item parse_orig_mailmap_hash()

Takes a mailmap_hash and parses it and returns it as an array of array
records with the contents:

    [ $preferred_name, $preferred_email,
      $other_name, $other_email,
      $line_num ]

=item read_and_update()

Wraps the other functions in this library and implements the logic and
intent of this tool. Takes two arguments, the authors file name, and the
mailmap file name. Returns nothing but may modify the AUTHORS file
or the .mailmap file. Requires that both files are editable.

=item read_commit_log()

Read the commit log and find any new names it contains.

Normally used via C<read_and_update> and not called directly.

=item read_authors()

Read the AUTHORS file into the object, and return data about it.

Normally used via C<read_and_update> and not called directly.

=item read_mailmap()

Read the .mailmap file into the object and return data about it.

Normally used via C<read_and_update> and not called directly.

=item read_exclusion_file()

Read the exclusion file into the object and return data about it.

Normally used via C<read_and_update> and not called directly.

=item update_authors()

Write out an updated AUTHORS file atomically if it has changed,
returns 0 if the file was actually updated, 1 if it was not.

Normally used via C<read_and_update> and not called directly.

=item update_mailmap()

Write out an updated .mailmap file atomically if it has changed,
returns 0 if the file was actually updated, 1 if it was not.

Normally used via C<read_and_update> and not called directly.

=item update_exclusion_file()

Write out an updated exclusion file atomically if it has changed,
returns 0 if the file was actually update, 1 if it was not.

Normally used via C<read_and_update> and not called directly.

=back

=head1 TODO

More documentation and testing.

=head1 SEE ALSO

F<Porting/checkAUTHORS.pl>

=head1 AUTHOR

Yves Orton <demerphq@gmail.com>

=cut
