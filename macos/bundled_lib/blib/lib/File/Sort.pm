package File::Sort;
use Carp;
use Fcntl qw(O_RDONLY O_WRONLY O_CREAT O_TRUNC);
use Symbol qw(gensym);
use strict;
use locale;
use vars qw($VERSION *sortsub *sort1 *sort2 *map1 *map2 %fh);

require Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA = 'Exporter';
@EXPORT_OK = 'sort_file';
$VERSION = '1.01';

sub sort_file {
    my @args = @_;
    if (ref $args[0]) {

        # fix pos to look like k
        if (exists $args[0]{'pos'}) {
            my @argv;
            my $pos = $args[0]{'pos'};

            if (!ref $pos) {
                $pos = [$pos];
            }

            if (!exists $args[0]{'k'}) {
                $args[0]{'k'} = [];
            } elsif (!ref $args[0]{'k'}) {
                $args[0]{'k'} = [$args[0]{'k'}];
            }

            for (@$pos) {
                my $n;
                if (   /^\+(\d+)(?:\.(\d+))?([bdfinr]+)?
                   (?:\s+\-(\d+)(?:\.(\d+))?([bdfinr]+)?)?$/x) {
                    $n = $1 + 1;
                    $n .= '.' . ($2 + 1) if defined $2;
                    $n .= $3 if $3;

                    if (defined $4) {
                        $n .= "," . (defined $5 ? ($4 + 1) . ".$5" : $4);
                        $n .= $6 if $6;
                    }
                    push @{$args[0]{'k'}}, $n;
                }
            }

        }
        _sort_file(@args);
    } else {
        _sort_file({I => $args[0], o => $args[1]});
    }
}

sub _sort_file {
    local $\;   # don't mess up our prints
    my($opts, @fh, @recs) = shift;

    # record separator, default to \n
    local $/ = $opts->{R} ? $opts->{R} : "\n";

    # get input files into anon array if not already
    $opts->{I} = [$opts->{I}] unless ref $opts->{I};

    usage() unless @{$opts->{I}};

    # "K" == "no k", for later
    $opts->{K} = $opts->{k} ? 0 : 1;
    $opts->{k} = $opts->{k} ? [$opts->{k}] : [] if !ref $opts->{k};

    # set output and other defaults
    $opts->{o}   = !$opts->{o} ? '' : $opts->{o};
    $opts->{'y'} ||= $ENV{MAX_SORT_RECORDS} || 200000;  # default max records
    $opts->{F}   ||= $ENV{MAX_SORT_FILES}   || 40;      # default max files


    # see big ol' mess below
    _make_sort_sub($opts);

    # only check to see if file is sorted
    if ($opts->{c}) {
        local *F;
        my $last;

        if ($opts->{I}[0] eq '-') {
            open(F, $opts->{I}[0])
                or die "Can't open `$opts->{I}[0]' for reading: $!";
        } else {
            sysopen(F, $opts->{I}[0], O_RDONLY)
                or die "Can't open `$opts->{I}[0]' for reading: $!";
        }

        while (defined(my $rec = <F>)) {
            # fail if -u and keys are not unique (assume sorted)
            if ($opts->{u} && $last) {
                return 0 unless _are_uniq($opts->{K}, $last, $rec);
            }

            # fail if records not in proper sort order
            if ($last) {
                my @foo;
                if ($opts->{K}) {
                    local $^W;
                    @foo = sort sort1 ($rec, $last);
                } else {
                    local $^W;
                    @foo = map {$_->[0]} sort sortsub
                        map &map1, ($rec, $last);
                }
                return 0 if $foo[0] ne $last || $foo[1] ne $rec;
            }

            # save value of last record
            $last = $rec;
        }

        # success, yay
        return 1;

    # if merging sorted files
    } elsif ($opts->{'m'}) {

        foreach my $filein (@{$opts->{I}}) {

            # just open files and get array of handles
            my $sym = gensym();

            sysopen($sym, $filein, O_RDONLY)
                or die "Can't open `$filein' for reading: $!";

            push @fh, $sym;
        }
        
    # ooo, get ready, get ready
    } else {

        # once for each input file
        foreach my $filein (@{$opts->{I}}) {
            local *F;
            my $count = 0;

            _debug("Sorting file $filein ...\n") if $opts->{D};

            if ($filein eq '-') {
                open(F, $filein)
                    or die "Can't open `$filein' for reading: $!";
            } else {
                sysopen(F, $filein, O_RDONLY)
                    or die "Can't open `$filein' for reading: $!";
            }

            while (defined(my $rec = <F>)) {
                push @recs, $rec;
                $count++;  # keep track of number of records

                if ($count >= $opts->{'y'}) {    # don't go over record limit

                    _debug("$count records reached in `$filein'\n")
                        if $opts->{D};

                    # save to temp file, add new fh to array
                    push @fh, _write_temp(\@recs, $opts);

                    # reset record count and record array
                    ($count, @recs) = (0);

                    # do a merge now if at file limit
                    if (@fh >= $opts->{F}) {

                        # get filehandle and restart array with it
                        @fh = (_merge_files($opts, \@fh, [], _get_temp()));

                        _debug("\nCreating temp files ...\n") if $opts->{D};
                    }
                }
            }

            close F;
        }

        # records leftover, didn't reach record limit
        if (@recs) {
            _debug("\nSorting leftover records ...\n") if $opts->{D};
            _check_last(\@recs);
            if ($opts->{K}) {
                local $^W;
                @recs = sort sort1 @recs;
            } else {
                local $^W;
                @recs = map {$_->[0]} sort sortsub map &map1, @recs;
            }
        }
    }

    # do the merge thang, uh huh, do the merge thang
    my $close = _merge_files($opts, \@fh, \@recs, $opts->{o});
    close $close unless fileno($close) == fileno('STDOUT'); # don't close STDOUT

    _debug("\nDone!\n\n") if $opts->{D};
    return 1;   # yay
}

# take optional arrayref of handles of sorted files,
# plus optional arrayref of sorted scalars
sub _merge_files {
    # we need the options, filehandles, and output file
    my($opts, $fh, $recs, $file) = @_;
    my($uniq, $first, $o, %oth);

    # arbitrarily named keys, store handles as values
    %oth = map {($o++ => $_)} @$fh;

    # match handle key in %oth to next record of the handle    
    %fh  = map {
        my $fh = $oth{$_};
        ($_ => scalar <$fh>);
    } keys %oth;

    # extra records, special X "handle"
    $fh{X} = shift @$recs if @$recs;

    _debug("\nCreating sorted $file ...\n") if $opts->{D};

    # output to STDOUT if no output file provided
    if ($file eq '') {
        $file = \*STDOUT;

    # if output file is a path, not a reference to a file, open
    # file and get a reference to it
    } elsif (!ref $file) {
        my $tfh = gensym();
        sysopen($tfh, $file, O_WRONLY|O_CREAT|O_TRUNC)
            or die "Can't open `$file' for writing: $!";
        $file = $tfh;
    }

    my $oldfh = select $file;
    $| = 0; # just in case, use the buffer, you knob

    while (keys %fh) {
        # don't bother sorting keys if only one key remains!
        if (!$opts->{u} && keys %fh == 1) {
            ($first) = keys %fh;
            my $curr = $oth{$first};
            my @left = $first eq 'X' ? @$recs : <$curr>;
            print $fh{$first}, @left;
            delete $fh{$first};
            last;
        }

        {
            # $first is arbitrary number assigned to first fh in sort
            if ($opts->{K}) {
                local $^W;
                ($first) = (sort sort2 keys %fh);
            } else {
                local $^W;
                ($first) = (map {$_->[0]} sort sortsub
                    map &map2, keys %fh);
            }
        }

        # don't print if -u and not unique
        if ($opts->{u}) {
            print $fh{$first} if
                (!$uniq || _are_uniq($opts->{K}, $uniq, $fh{$first}));
            $uniq = $fh{$first};
        } else {
            print $fh{$first};
        }

        # get current filehandle
        my $curr = $oth{$first};

        # use @$recs, not filehandles, if key is X
        my $rec = $first eq 'X' ? shift @$recs : scalar <$curr>;

        if (defined $rec) {     # bring up next record for this filehandle
            $fh{$first} = $rec;

        } else {                # we don't need you anymore
            delete $fh{$first};
        }
    }

    seek $file, 0, 0;  # might need to read back from it
    select $oldfh;
    return $file;
}

sub _check_last {
    # add new record separator if not one there
    ${$_[0]}[-1] .= $/ if (${$_[0]}[-1] !~ m|$/$|);
}

sub _write_temp {
    my($recs, $opts) = @_;
    my $temp = _get_temp() or die "Can't get temp file: $!";

    _check_last($recs);

    _debug("New tempfile: $temp\n") if $opts->{D};

    if ($opts->{K}) {
        local $^W;
        print $temp sort sort1 @{$recs};
    } else {
        local $^W;
        print $temp map {$_->[0]} sort sortsub map &map1, @{$recs};
    }

    seek $temp, 0, 0;  # might need to read back from it
    return $temp;
}

sub _parse_keydef {
    my($k, $topts) = @_;

    # gurgle
    $k =~ /^(\d+)(?:\.(\d+))?([bdfinr]+)?
        (?:,(\d+)(?:\.(\d+))?([bdfinr]+)?)?$/x;

    # set defaults at zero or undef
    my %opts = (
        %$topts,                            # get other options
        ksf => $1 || 0,                     # start field
        ksc => $2 || 0,                     # start field char start
        kst => $3 || '',                    # start field type
        kff => (defined $4 ? $4 : undef),  # end field
        kfc => $5 || 0,                     # end field char end
        kft => $6 || '',                    # end field type
    );

    # their idea of 1 is not ours
    for (qw(ksf ksc kff)) { #  kfc stays same
        $opts{$_}-- if $opts{$_};
    }

    # if nothing in kst or kft, use other flags possibly passed
    if (!$opts{kst} && !$opts{kft}) {
        foreach (qw(b d f i n r)) {
            $opts{kst} .= $_ if $topts->{$_};
            $opts{kft} .= $_ if $topts->{$_};
        }

    # except for b, flags on one apply to the other
    } else {
        foreach (qw(d f i n r)) {
            $opts{kst} .= $_ if ($opts{kst} =~ /$_/ || $opts{kft} =~ /$_/);
            $opts{kft} .= $_ if ($opts{kst} =~ /$_/ || $opts{kft} =~ /$_/);
        }
    }

    return \%opts;
}

sub _make_sort_sub {
    my($topts, @sortsub, @mapsub, @sort1, @sort2) = shift;

    # if no keydefs set
    if ($topts->{K}) {
        $topts->{kst} = '';
        foreach (qw(b d f i n r)) {
            $topts->{kst} .= $_ if $topts->{$_};
        }

        # more complex stuff, act like we had -k defined
        if ($topts->{kst} =~ /[bdfi]/) {
            $topts->{K} = 0;
            $topts->{k} = ['K'];    # special K ;-)
        }
    }

    # if no keydefs set
    if ($topts->{K}) {
        _debug("No keydef set\n") if $topts->{D};

        # defaults for main sort sub components
        my($cmp, $aa, $bb, $fa, $fb) = qw(cmp $a $b $fh{$a} $fh{$b});

        # reverse sense
        ($bb, $aa, $fb, $fa) = ($aa, $bb, $fa, $fb) if $topts->{r};

        # do numeric sort
        $cmp = '<=>' if $topts->{n};

        # add finished expression to array
        my $sort1 = "sub { $aa $cmp $bb }\n";
        my $sort2 = "sub { $fa $cmp $fb }\n";

        _debug("$sort1\n$sort2\n") if $topts->{D};

        {
            local $^W;
            *sort1  = eval $sort1;
            die "Can't create sort sub: $@" if $@;
            *sort2  = eval $sort2;
            die "Can't create sort sub: $@" if $@;
        }

    } else {

        # get text separator or use whitespace
        $topts->{t} =
            defined $topts->{X} ? $topts->{X} :
            defined $topts->{t} ? quotemeta($topts->{t}) :
            '\s+';
        $topts->{t} =~ s|/|\\/|g if defined $topts->{X};

        foreach my $k (@{$topts->{k}}) {
            my($opts, @fil) = ($topts);
            
            # defaults for main sort sub components
            my($cmp, $ab_, $fab_, $aa, $bb) = qw(cmp $_ $fh{$_} $a $b);

            # skip stuff if special K
            $opts = $k eq 'K' ? $topts : _parse_keydef($k, $topts);

            if ($k ne 'K') {
                my($tmp1, $tmp2) = ("\$tmp[$opts->{ksf}]",
                    ($opts->{kff} ? "\$tmp[$opts->{kff}]" : ''));

                # skip leading spaces
                if ($opts->{kst} =~ /b/) {
                    $tmp1 = "($tmp1 =~ /(\\S.*)/)[0]";
                }

                if ($opts->{kft} =~ /b/) {
                    $tmp2 = "($tmp2 =~ /(\\S.*)/)[0]";
                }

                # simpler if one field, goody for us
                if (! defined $opts->{kff} || $opts->{ksf} == $opts->{kff}) {

                    # simpler if chars are both 0, wicked pissah
                    if ($opts->{ksc} == 0 &&
                        (!$opts->{kfc} || $opts->{kfc} == 0)) {
                        @fil = "\$tmp[$opts->{ksf}]";

                    # hmmmmm
                    } elsif (!$opts->{kfc}) {
                        @fil = "substr($tmp1, $opts->{ksc})";

                    # getting out of hand now
                    } else {
                        @fil = "substr($tmp1, $opts->{ksc}, ". 
                            ($opts->{kfc} - $opts->{ksc}) . ')';
                    }

                # try again, shall we?
                } else {

                    # if spans two fields, but chars are both 0
                    # and neither has -b, alrighty
                    if ($opts->{kfc} == 0 && $opts->{ksc} == 0 &&
                        $opts->{kst} !~ /b/ && $opts->{kft} !~ /b/) {
                        @fil = "join(''," .
                            "\@tmp[$opts->{ksf} .. $opts->{kff}])";

                    # if only one field away
                    } elsif (($opts->{kff} - $opts->{ksf}) == 1) {
                        @fil = "join('', substr($tmp1, $opts->{ksc}), " .
                            "substr($tmp2, 0, $opts->{kfc}))";

                    # fine, have it your way!  hurt me!  love me!
                    } else {
                        @fil = "join('', substr($tmp1, $opts->{ksc}), " .
                            "\@tmp[" . ($opts->{ksf} + 1) . " .. " .
                                ($opts->{kff} - 1) . "], " .
                            "substr($tmp2, 0, $opts->{kfc}))";
                    }
                }
            } else {
                @fil = $opts->{kst} =~ /b/ ?
                    "(\$tmp[0] =~ /(\\S.*)/)[0]" : "\$tmp[0]";
            }

            # fold to upper case
            if ($opts->{kst} =~ /f/) {
                $fil[0] = "uc($fil[0])";
            }

            # only alphanumerics and whitespace, override -i
            if ($opts->{kst} =~ /d/) {
                $topts->{DD}++;
                push @fil, "\$tmp =~ s/[^\\w\\s]+//g", '"$tmp"';

            # only printable characters
            } elsif ($opts->{kst} =~ /i/) {
                require POSIX;
                $fil[0] = "join '', grep {POSIX::isprint \$_} " .
                    "split //,\n$fil[0]";
            }

            $fil[0] = "\$tmp = $fil[0]" if $opts->{kst} =~ /d/;


            # reverse sense
            ($bb, $aa) = ($aa, $bb) if ($opts->{kst} =~ /r/);

            # do numeric sort
            $cmp = '<=>' if ($opts->{kst} =~ /n/);

            # add finished expressions to arrays
            my $n = @sortsub + 2;
            push @sortsub, sprintf "%s->[$n] %s %s->[$n]",
                $aa, $cmp, $bb;

            if (@fil > 1) {
                push @mapsub, "  (\n" .
                    join(",\n", map {s/^/      /mg; $_} @fil),
                    "\n    )[-1],\n  ";
            } else {
                push @mapsub, "  " . $fil[0] . ",\n  ";
            }
        }

        # if not -u
        if (! $topts->{u} ) {
            # do straight compare if all else is equal
            push @sortsub, sprintf "%s->[1] %s %s->[1]",
                $topts->{r} ? qw($b cmp $a) : qw($a cmp $b);
        }

        my(%maps, $sortsub, $mapsub) = (map1 => '$_', map2 => '$fh{$_}');

        $sortsub = "sub {\n  " . join(" || \n  ", @sortsub) . "\n}\n";

        for my $m (keys %maps) {
            my $k = $maps{$m};
            $maps{$m} = sprintf "sub {\n  my \@tmp = %s;\n",
                $topts->{k}[0] eq 'K' ? $k : "split(/$topts->{t}/, $k)";

            $maps{$m} .= "  my \$tmp;\n" if $topts->{DD};
            $maps{$m} .= "\n  [\$_, $k";
            $maps{$m} .= ",\n  " . join('', @mapsub) if @mapsub;
            $maps{$m} .= "]\n}\n";
        }

        _debug("$sortsub\n$maps{map1}\n$maps{map2}\n") if $topts->{D};

        {
            local $^W;
            *sortsub = eval $sortsub;
            die "Can't create sort sub: $@" if $@;
            *map1  = eval $maps{map1};
            die "Can't create sort sub: $@" if $@;
            *map2  = eval $maps{map2};
            die "Can't create sort sub: $@" if $@;
        }
    }
}


sub _get_temp { # nice and simple
    require IO::File;
    IO::File->new_tmpfile;
}

sub _are_uniq {
    my $nok = shift;
    local $^W;

    if ($nok) {
        ($a, $b) = @_;
        return &sort1;
    } else {
        ($a, $b) = map &map1, @_;
        return &sortsub;
    }
}

sub _debug {
    print STDERR @_;
}

sub usage {
    local $/ = "\n";    # in case changed
    my $u;

    seek DATA, 0, 0;
    while (<DATA>) {
        last if m/^=head1 SYNOPSIS$/;
    }

    while (<DATA>) {
        last if m/^=/;
        $u .= $_;
    }

    $u =~ s/\n//;
    
    die "Usage:$u";

}

__END__

=head1 NAME

File::Sort - Sort a file or merge sort multiple files


=head1 SYNOPSIS

  use File::Sort qw(sort_file);
  sort_file({
    I => [qw(file_1 file_2)],
    o => 'file_new', k => '5.3,5.5rn', -t => '|'
  });

  sort_file('file1', 'file1.sorted');


=head1 DESCRIPTION

This module sorts text files by lines (or records).  Comparisons
are based on one or more sort keys extracted from each line of input,
and are performed lexicographically. By default, if keys are not given,
sort regards each input line as a single field.  The sort is a merge
sort.  If you don't like that, feel free to change it.


=head2 Options

The following options are available, and are passed in the hash
reference passed to the function in the format:

  OPTION => VALUE

Where an option can take multiple values (like C<I>, C<k>, and C<pos>),
values may be passed via an anonymous array:

  OPTION => [VALUE1, VALUE2]

Where the OPTION is a switch, it should be passed a boolean VALUE
of 1 or 0.

This interface will always be supported, though a more perlish
interface may be offered in the future, as well.  This interface
is basically a mapping of the command-line options to the Unix
sort utility.


=over 4

=item C<I> I<INPUT>

Pass in the input file(s).  This can be either a single string with the
filename, or an array reference containing multiple filename strings.

=item C<c>

Check that single input fle is ordered as specified by the arguments and
the collating sequence of the current locale.  No output is produced;
only the exit code is affected.

=item C<m>

Merge only; the input files are assumed to already be sorted.

=item C<o> I<OUTPUT>

Specify the name of an I<OUTPUT> file to be used instead of the standard
output.

=item C<u>

Unique: Suppresses all but one in each set of lines having equal keys.
If used with the B<c> option check that there are no lines with
consecutive lines with duplicate keys, in addition to checking that the
input file is sorted.

=item C<y> I<MAX_SORT_RECORDS>

Maximum number of lines (records) read before writing to temp file.
Default is 200,000. This may eventually change to be kbytes instead of
lines.  Lines was easier to implement.  Can also specify with
MAX_SORT_RECORDS environment variable.

=item C<F> I<MAX_SORT_FILES>

Maximum number of temp files to be held open at once.  Default to 40,
as older Windows ports had quite a small limit.  Can also specify
with MAX_SORT_FILES environment variable.  No temp files will be used
at all if MAX_SORT_RECORDS is never reached.

=item C<D>

Send debugging information to STDERR.  Behavior subject to change.

=back


The following options override the default ordering rules. When ordering
options appear independent of any key field specifications, the requested
field ordering rules are applied globally to all sort keys. When attached
to a specific key (see B<k>), the specified ordering options override all
global ordering options for that key.


=over 4

=item C<d>

Specify that only blank characters and alphanumeric characters,
according to the current locale setting, are significant in comparisons.
B<d> overrides B<i>.

=item C<f>

Consider all lower-case characters that have upper-case equivalents,
according to the current locale setting, to be the upper-case equivalent
for the purposes of comparison.

=item C<i>

Ignores all characters that are non-printable, according to the current
locale setting.

=item C<n>

Does numeric instead of string compare, using whatever perl considers to
be a number in numeric comparisons.

=item C<r>

Reverse the sense of the comparisons.

=item C<b>

Ignore leading blank characters when determining the starting and ending
positions of a restricted sort key.  If the B<b> option is specified
before the first B<k> option, it is applied to all B<k> options. 
Otherwise, the B<b> option can be attached indepently to each
field_start or field_end option argument (see below).

=item C<t> I<STRING>

Use I<STRING> as the field separator character; char is not considered
to be part of a field (although it can be included in a sort key).  Each
occurrence of char is significant (for example,
E<lt>charE<gt>E<lt>charE<gt> delimits an empty field).  If B<t> is not
specified, blank characters are used as default field separators; each
maximal non-empty sequence of blank characters that follows a non-blank
character is a field separator.

=item C<X> I<STRING>

Same as B<t>, but I<STRING> is interpreted as a Perl regular expression
instead.  Do not escape any characters (C</> characters need to be
escaped internally, and will be escaped for you).

The string matched by I<STRING> is not included in the fields
themselves, unless demanded by perl's regex and split semantics (e.g.,
regexes in parentheses will add that matched expression as an extra
field).  See L<perlre> and L<perlfunc/split>.

=item C<R> I<STRING>

Record separator, defaults to newline.

=item C<k> I<pos1[,pos2]>

The keydef argument is a restricted sort key field definition. The
format of this definition is:

    field_start[.first_char][type][,field_end[.last_char][type]]

where field_start and field_end define a key field restricted to a
portion of the line, and type is a modifier from the list of characters
B<b>, B<d>, B<f>, B<i>, B<n>, B<r>.  The b modifier behaves like the
B<b> option, but applies only to the field_start or field_end to which
it is attached. The other modifiers behave like the corresponding
options, but apply only to the key field to which they are attached;
they have this effect if specified with field_start, field_end, or both.
If any modifier is attached to a field_start or a field_end, no option
applies to either.

Occurrences of the B<k> option are significant in command line order. 
If no B<k> option is specified, a default sort key of the entire line
is used.  When there are multiple keys fields, later keys are compared
only after all earlier keys compare equal.

Except when the B<u> option is specified, lines that otherwise compare
equal are ordered as if none of the options B<d>, B<f>, B<i>, B<n>
or B<k> were present (but with B<r> still in effect, if it was
specified) and with all bytes in the lines significant to the
comparison.  The order in which lines that still compare equal are
written is unspecified.


=item C<pos> I<+pos1 [-pos2]>

Similar to B<k>, these are mostly obsolete switches, but some people
like them and want to use them.  Usage is:

    +field_start[.first_char][type] [-field_end[.last_char][type]]

Where field_end in B<k> specified the last position to be included,
it specifes the last position to NOT be included.  Also, numbers
are counted from 0 instead of 1.  B<pos2> must immediately follow
corresponding B<+pos1>.  The rest should be the same as the B<k> option.

Mixing B<+pos1> B<pos2> with B<k> is allowed, but will result in all of
the B<+pos1> B<pos2> options being ordered AFTER the B<k> options.
It is best if you Don't Do That.  Pick one and stick with it.

Here are some equivalencies:

    pos => '+1 -2'              ->  k => '2,2'
    pos => '+1.1 -1.2'          ->  k => '2.2,2.2'
    pos => ['+1 -2', '+3 -5']   ->  k => ['2,2', '4,5']
    pos => ['+2', '+0b -1']     ->  k => ['3', '1b,1']
    pos => '+2.1 -2.4'          ->  k => '3.2,3.4'
    pos => '+2.0 -3.0'          ->  k => '3.1,4.0'

=back


=head2 Not Implemented

If the options are not listed as implemented above, or are not
listed in TODO below, they are not in the plan for implementation.
This includes B<T> and B<z>.


=head1 EXAMPLES

Sort file by straight string compare of each line, sending
output to STDOUT.

    use File::Sort qw(sort_file);
    sort_file('file');

Sort contents of file by second key in file.

    sort_file({k => 2, I => 'file'});

Sort, in reverse order, contents of file1 and file2, placing
output in outfile and using second character of second field
as the sort key.

    sort_file({
        r => 1, k => '2.2,2.2', o => 'outfile',
        I => ['file1', 'file2']
    });

Same sort but sorting numerically on characters 3 through 5 of
the fifth field first, and only return records with unique keys.

    sort_file({
        u => 1, r => 1, k => ['5.3,5.5rn', '2.2,2.2'],
        o => 'outfile', I => ['file1', 'file2']
    });

Print passwd(4) file sorted by numeric user ID.

    sort_file({t => ':', k => '3n', I => '/etc/passwd'});

For the anal sysadmin, check that passwd(4) file is sorted by numeric
user ID.

    sort_file({c => 1, t => ':', k => '3n', I => '/etc/passwd'});


=head1 ENVIRONMENT

Note that if you change the locale settings after the program has started
up, you must call setlocale() for the new settings to take effect.  For
example:

    # get constants
    use POSIX 'locale_h';

    # e.g., blank out locale
    $ENV{LC_ALL} = $ENV{LANG} = '';

    # use new ENV settings
    setlocale(LC_CTYPE, '');
    setlocale(LC_COLLATE, '');

=over 4

=item LC_COLLATE

Determine the locale for ordering rules.

=item LC_CTYPE

Determine the locale for the interpretation of sequences of bytes of
text data as characters (for example, single- versus multi-byte
characters in arguments and input files) and the behaviour of
character classification for the B<b>, B<d>, B<f>, B<i> and B<n>
options.

=item MAX_SORT_RECORDS

Default is 200,000.  Maximum number of records to use before writing
to a temp file.  Overriden by B<y> option.

=item MAX_SORT_FILES

Maximum number of open temp files to use before merging open temp
files.  Overriden by B<F> option.

=back


=head1 EXPORT

Exports C<sort_file> on request.


=head1 TODO

=over 4

=item Better debugging and error reporting

=item Performance hit with -u

=item Do bytes instead of lines

=item Better test suite

=item Switch for turning off locale ... ?

=back


=head1 HISTORY

=over 4

=item v1.01, Monday, January 14, 2002

Change license to be that of Perl.

=item v1.00, Tuesday, November 13, 2001

Long overdue release.

Add O_TRUNC to output open (D'oh!).

Played with somem of the -k options (Marco A. Romero).

Fix filehandle close test of STDOUT (Gael Marziou).

Some cleanup.

=item v0.91, Saturday, February 12, 2000

Closed all files in test.pl so they could be unlinked on some
platforms.  (Hubert Toullec)

Documented C<I> option.  (Hubert Toullec)

Removed O_EXCL flag from C<sort_file>.

Fixed bug in sorting multiple files.  (Paul Eckert)


=item v0.90, Friday, April 30, 1999

Complete rewrite.  Took the code from this module to write sort
utility for PPT project, then brought changes back over.  As a result
the interface has changed slightly, mostly in regard to what letters
are used for options, but there are also some key behavioral differences.
If you need the old interface, the old module will remain on CPAN, but
will not be supported.  Sorry for any inconvenience this may cause.
The good news is that it should not be too difficult to update your
code to use the new interface.


=item v0.20

Fixed bug with unique option (didn't work :).

Switched to sysopen for better portability.

Print to STDOUT if no output file supplied.

Added c option to check sorting.


=item v0.18 (31 January 1998)

Tests 3 and 4 failed because we hit the open file limit in the
standard Windows port of perl5.004_02 (50).  Adjusted the default
for total number of temp files from 50 to 40 (leave room for other open
files), changed docs.  (Mike Blazer, Gurusamy Sarathy)

=item v0.17 (30 December 1998)

Fixed bug in C<_merge_files> that tried to C<open> a passed
C<IO::File> object.

Fixed up docs and did some more tests and benchmarks.

=item v0.16 (24 December 1998)

One year between releases was too long.  I made changes Miko O'Sullivan
wanted, and I didn't even know I had made them.

Also now use C<IO::File> to create temp files, so the TMPDIR option is
no longer supported.  Hopefully made the whole thing more robust and
faster, while supporting more options for sorting, including delimited
sorts, and arbitrary sorts.

Made CHUNK default a lot larger, which improves performance.  On
low-memory systems, or where (e.g.) the MacPerl binary is not allocated
much RAM, it might need to be lowered.


=item v0.11 (04 January 1998)

More cleanup; fixed special case of no linebreak on last line; wrote test 
suite; fixed warning for redefined subs (sort1 and sort2).

=item v0.10 (03 January 1998)

Some cleanup; made it not subject to system file limitations; separated 
many parts out into separate functions.

=item v0.03 (23 December 1997)

Added reverse and numeric sorting options.

=item v0.02 (19 December 1997)

Added unique and merge-only options.

=item v0.01 (18 December 1997)

First release.

=back


=head1 THANKS

Mike Blazer E<lt>blazer@mail.nevalink.ruE<gt>,
Vicki Brown E<lt>vlb@cfcl.comE<gt>,
Tom Christiansen E<lt>tchrist@perl.comE<gt>,
Albert Dvornik E<lt>bert@mit.eduE<gt>,
Paul Eckert E<lt>peckert@epicrealm.comE<gt>,
Gene Hsu E<lt>gene@moreinfo.comE<gt>,
Andrew M. Langmead E<lt>aml@world.std.comE<gt>,
Gael Marziou E<lt>gael_marziou@hp.comE<gt>,
Brian L. Matthews E<lt>blm@halcyon.comE<gt>,
Rich Morin E<lt>rdm@cfcl.comE<gt>,
Matthias Neeracher E<lt>neeri@iis.ee.ethz.chE<gt>,
Miko O'Sullivan E<lt>miko@idocs.comE<gt>,
Tom Phoneix E<lt>rootbeer@teleport.comE<gt>,
Marco A. Romero E<lt>mromero@iglou.comE<gt>,
Gurusamy Sarathy E<lt>gsar@activestate.comE<gt>,
Hubert Toullec E<lt>Hubert.Toullec@wanadoo.frE<gt>.


=head1 AUTHOR

Chris Nandor E<lt>pudge@pobox.comE<gt>, http://pudge.net/

Copyright (c) 1997-2002 Chris Nandor.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.


=head1 VERSION

v1.01, Monday, January 14, 2002


=head1 SEE ALSO

sort(1), locale, PPT project, <URL:http://sf.net/projects/ppt/>.

=cut
