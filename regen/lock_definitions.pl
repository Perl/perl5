#!/usr/bin/perl -w
#23456789112345678921234567893123456789412345678951234567896123456789712345678981
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

# Regenerate (overwriting only if changed):

#    lock_definitions.h

# Also accepts the standard regen_lib -q and -v args.

# This script is normally invoked from regen.pl.

BEGIN {
    require './regen/regen_lib.pl';
}

use strict;
use warnings;

my $me = 'regen/lock_definitions.pl';
my $output_file = 'lock_definitions.h';

my $MAX_LINE_WIDTH = 78;
my $comment_columns = $MAX_LINE_WIDTH - 3;  # For "/* " on first line; " * "
                                            # on subsequent ones
my %conditionals;   # Accumulated list of functions that require restrictions
                    # on their input parameters to be thread-safe.
my %uses;           # Accumulated data for each use in the input.  Almost all
                    # uses are function calls, but this name is used for
                    # generality, and because it is fewer characters than
                    # 'function'.  Some use types are inherently function
                    # calls, and they are referred to as such.
my %has_comments;   # Accumulated list of uses that have comments at their
                    # output #defines
my %need_single_thread_init;    # Accumulated list of functions that need
                                # single-thread initialization
my %non_functions;  # Accumulated list of non-function uses
my %non_posixes;    # Accumulated list of functions not in POSIX
my %obsoletes;      # Accumulated list of obsolete functions
my %preferred;      # Accumulated list of functions which have preferred
                    # alternatives
my %race_tags;      # Accumulated tags for the input 'race:tag' elements
my %signal_issues;  # Accumulated list of functions that are affected by signals
my %unsuitables;    # Accumulated list of entirely thread-unsafe functions
my $preprocessor = "";   # Preprocessor conditional in effect
my %categories = ( LC_ALL => 1 );   # Accumulated list of all the locale
                                    # categories referred to in the input

# We use the data for the reentrant alternative functions that are
# automatically subtsituted when that feature is active.
my $reentr_pl = "./regen/reentr.pl";
open my $auto, "<", $reentr_pl or die "Can't open $reentr_pl: $!";
while (<$auto>) {
    last if /^__DATA__/;
}

# Each function there is mapped to a "_r" version of itself
my %automatics;
while (<$auto>) {

    # We are only interested in the function name, which starts with the first
    # non-blank character in the first column
    my ($function, @rest) = split /\s*\|\s*/, $_;   # '|' is column separator
    $function =~ s/ \s .* //x;

    $automatics{$function} = "${function}_r";
}
close $auto or die "Can't close $reentr_pl: $!";

sub name_order {    # sort helper

       # Squeeze out non-words for first-order sort
    return    lc $a =~ s/[\W_]*//gr cmp lc $b =~ s/[\W_]*//gr
           || lc $a cmp lc $b;
}

sub get_display_name {
    my $input = shift;

    # Returns the display name of the input item, which is assumed to be a
    # function unless there is evidence to the contrary
    #
    # Requires %uses to already be populated with the proper display name
    # for the known items.

    # If a quoted-string, it certainly isn't a function; return the input with
    # just the quotes stripped off
    return $input if $input =~ s/ ^ " (.*) " $/$1/x;

    # Return as-is if has spaces or already has "()"
    return $input if $input =~ / \s | \(\) /x;

    # Return the known value if we have one for this
    return $uses{$input}{display_name} if defined $uses{$input};

    # Otherwise, assume is a function.
    return $input . "()";
}

sub format_list {
    my @list = split ",", shift;

    # Return a prettied up version of 'a,b,c,...', where 'a', etc are likely
    # function names

    return "" unless @list;

    foreach my $use (@list) {
        $use = get_display_name($use);
    }

    # Final element is changed to be prefixed with an 'or'
    $list[-1] = "or $list[-1]" if @list > 1;

    # Comma separated, except if only two elements
    my $string = join ", ", @list;
    $string =~ s/,// if @list == 2;

    return $string;
}

sub perl_macro_family {
    my $name = shift;

    # Return the display text for an isALPHA, etc. input
    return "a Perl $name-family macro";
}

# Our data comes internally
my @DATA = <DATA>;
close DATA;

while (defined (my $line = shift @DATA)) {

    my (@cuses, @cdata);    # 'c' stands for continuation
    {
        # Accumulate any continuation lines into just one.  An explanation of
        # the format of the lines is just before the __DATA__ line of this
        # file.
        do {
            chomp $line;
            $line =~ s/ \s+ $ //x;

            # A line is continued if the final non-space is a '\'
            my $continued = $line =~ s/ \s* \\ $ //x;

            # The first '|' separates the uses the line applies to from
            # their data.  If no '|', the first character being a non-space
            # indicates it is a continuation of the uses list; otherwise
            # a continuation of the data.
            if ($line =~ / ^ ( [^|]* ) \s* \| \s* (.*) /x) {
                push @cuses, $1;
                push @cdata, $2;
            }
            elsif ($line =~ / ^ \S /x) {
                push @cuses, $line;
            }
            else {
                push @cdata, $line =~ s/ ^ \s+ //rx;
            }

            last unless $continued;

            $line = shift @DATA;    # Repeat for the continuation line
        } while (1);
    }

    # Construct the entire line from all the continuations of the uses list as
    # the first column, and all the continuations of the data as the second
    # column.
    $line = join " ", @cuses;
    $line .= "|" . join " ", @cdata if @cdata;

    # Now split into the two columns
    my ($uses, $data, $dummy) = split /\s*\|\s*/, $line;
    croak("Extra '|' in input '$_'") if defined $dummy;

    # This line has additional continuation line(s) if the uses list ends
    # in a comma.  All such continuation lines have just the one field.
    if ($data) {
        while ($uses =~ / , \s* $/x) {
            my $continuation = shift @DATA;
            chomp $continuation;
            $uses .= $continuation;
        }

        $line = "$uses|$data";
    }

    # Finally, have the complete line; skip or stop special ones
    next if $line =~ /^\s*$/;       # Empty
    next if $line =~ m|^\s*//|;     # Begins with a // comment
    last if $line =~ /^__END__/;

    # The reason comments are "//" instead of "#" is because we accept C
    # preprocessor lines, which begin with "#".  When found, it applies to all
    # future input lines until a "#endif" is found.
    if ($line =~ / ^ \# (.*) /x) {
        $preprocessor = "$1";
        $preprocessor = "" if $preprocessor =~ /^endif/;
        next;
    }

    # Have disposed of all legal single-column lines
    croak "line with only one column: '$line'" unless defined $data;

    # Fields in the data column.  The fields are explained before the __DATA__
    # line in this file
    my @categories;
    my @races;
    my @conditions;
    my @signals;
    my $has_comment = 0;
    my @notes;
    my %locks;
    my $unsuitable;
    my $non_function = 0;
    my $non_posix = 0;
    my $obsolete;
    my $preferred;
    my $timer = 0;
    my $need_init = 0;

    # Loop through the data column, processing and removing one
    # field each iteration.
    while ($data =~ /\S/) {
        #print STDERR __FILE__, ": ", __LINE__, ": ", $data, "\n";
        $data =~ s/^\s+//;
        $data =~ s/\s+$//;

        # Must dispose of comments first, as they might mimic another
        # field-type, and they go to the end of the line
        if ($data =~ s| // \s* ( .* ) $ ||x) {
            push @notes, "$1";
            $has_comment = 1;
            next;
        }

        if ($data =~ s/ ^ U \b //x) {
            $unsuitable = "";
            next;
        }

        if ($data =~ s/ ^ X \b //x) {
            $non_posix = 1;
            next;
        }

        if ($data =~ s/ ^ [MV] \b //x) {
            $non_function = 1;
            next;
        }

        if ($data =~ s! ^ race
                                  # An optional tag marked by an initial
                                  # colon; returned in $1
                                  (?: : ( \w+ )

                                    # which may be followed by an optional
                                    # condition marked by an initial slash;
                                    # returned in $2
                                    (?: / ( \S+ ) )?
                                  )?
                                \b
                               !!x)
        {
            my $race = $1 // "";
            my $condition = $2 // "";
            if ($condition) {
                push @conditions, $condition;
            }
            else {
                push @races, $race;
            }
            next;
        }

        if ($data =~ s/ ^ ( LC_\S+ ) //x) {
            push @categories, $1;
            $categories{$1} = 1;
            next;
        }

        if ($data =~ s/ ^ sig: ( \S+ ) //x) {
            push @signals, $1;
            next;
        }

        if ($data =~ s/ ^ ( init ) \b //x) {
            push @notes, "must be called at least once in single-threaded mode"
                       . " to enable thread-safety in subsequent calls when in"
                       . " multi-threaded mode.";

            $need_init = 1;
            next;
        }

        if ($data =~ s/ ^ ( timer ) \b //x) {
            $timer = 1;
            next;
        }

        if ($data =~ s/ ^ const: ( \S+ ) //x) {
            croak("lock type redefined:" . $line)
                                             if $locks{$1} && $locks{$1} ne 'x';
            $locks{$1} = 'x';
            next;
        }

        if ($data =~ s/ ^ ( [[:lower:]]+ ) //x) {
            croak("lock type redefined:" . $line)
                                             if $locks{$1} && $locks{$1} ne 'r';
            $locks{$1} = 'r';
            next;
        }

        # Handle  O"this is text"
        if ($data =~ s/ ^ O ( " [^"]+  " ) //x) {
            $obsolete = $1;
            next;
        }

        # The preferred functions (if any) follow the 'O' or 'P'
        if ($data =~ s/ ^ ( O | P ) ( [,\w]* ) //x) {
            my $type = $1;
            if ($type eq 'O') {
                $obsolete = $2;
            }
            elsif ($type eq 'P') {
                $preferred = $2;
            }

            next;
        }

        croak("Unexpected input '$data'") if $data =~ /\S/;
    }

    # Now have assembled all the data for the uses

    # The Linux man pages include this keyword with no explanation.  khw
    # thinks it is obsolete because it always seems associated with SIGALRM.
    # But add this check to be sure.
    croak ("'timer' keyword not associated with signal ALRM")
                                if $timer && ! grep { $_ eq 'ALRM' } @signals;

    # Apply this data to each use in the list given by the uses field
    foreach my $use (split /\s*,\s*/, $uses) {
        croak("Illegal use syntax: '$use'") if $use =~ /\W/;
        if (grep { $_->{preprocessor} eq  $preprocessor }
                                                    $uses{$use}{entries}->@*)
        {
            croak("$use already has an entry")
        }

        # Preprocessor macros yield multiple possibilities for each use.  We
        # create an entry for each, controlled by its preprocessor line
        my %entry;
        $entry{preprocessor} = $preprocessor;
        push $entry{categories}->@*, @categories if @categories;

        foreach my $race (@races) {

            # Convert empty race name to this use's name
            $race = $use unless $race;

            # Add this use to the list of races with this tag
            $race_tags{$race}{$use} = 1;
        }

        push $entry{races}->@*, @races if @races;

        if (@conditions) {
            push $entry{conditions}->@*, @conditions;

            # Note that this use has a condition so that fact can be output at
            # the top of the header file.  Here and below, if any entry for a
            # use has such a global characteristic, the use will be listed;
            # that there are other versions that might not have it goes
            # unmentioned at the global level.
            $conditionals{$use} = 1;
        }

        if (@signals) {
            push $entry{signals}->@*, @signals;
            $signal_issues{$use} = 1;
        }

        $entry{locks}{$_} = $locks{$_} for keys %locks;
        $need_single_thread_init{$use} = 1 if $need_init;
        push $entry{notes}->@*, @notes if @notes;

        if (defined $unsuitable) {
            $entry{unsuitable} = 1;
            $unsuitables{$use} = 1;
        }

        if (defined $obsolete) {
            $entry{obsolete} = $obsolete;
            $obsoletes{$use} = $obsolete;
        }

        if (defined $preferred) {
            $entry{preferred} = $preferred;
            $preferred{$use} = $preferred;
        }

        $uses{$use}{display_name} = $use;

        if ($non_function) {
            $entry{non_function} = 1;
            $non_functions{$use} = 1;
            push $entry{conditions}->@*, "its value is used read-only";
        }
        else {

            # Note that this goes at the function level; the nature of things
            # is that a given name is inherently going to be a function or
            # non-function.  Preprocessor directives won't change which
            $uses{$use}{display_name} .= "()";
        }

        if ($non_posix) {
            $entry{non_posix} = 1;
            $non_posixes{$use} = 1;
        }

        $has_comments{$use} = 1 if $has_comment || $non_posix;

        push $uses{$use}{entries}->@*, \%entry;
    }
}

# Data has now been accumulated; now analyze the races.

# Each use that has a race has to be protected from every other use that has
# the same race by each locking the same mutex.
#
# 1)  If no uses with a given race need to lock the locale nor env mutexes,
#     use the generic one.
# 2)  There are no cases where a use needs to have exclusive access to both
#     the env and locale mutexes.  If either one does require exclusive
#     access, use that for the mutex.
# 2)  If all uses for a given race use the env mutex read-only, and none use
#     the locale one, might as well use the env mutex exclusively for this
#     race.
# 3)  Similarly, for the locale mutex if all use the locale mutex read-only,
#     and none the env one, use the locale mutex exclusively for this race.
# 4)  If any use also requires read-only access to both env and locale, use
#     the generic one and let the macro expansions defined in perl.h figure
#     out what is best for this configuration.
# 5)  If any use with this race has an additional race, all uses with that
#     race must also be factored into this calculation.  That means the
#     implementation of this needs to be a sub that calls itself recursively.

sub compute_race_mutex {
    my ($tag, $race_tags_ref, $has_env_ref, $has_locale_ref) = @_;
    return unless defined $race_tags_ref->{$tag};

    # The keys of %race_tags are the names of the races (available to this
    # function at this level).  The values are the names of the uses that have
    # this race
    my %tag_uses = $race_tags_ref->{$tag}->%*;
    foreach my $use (keys %tag_uses) {

        # Look at each variation of the use.  We get the worse case scenario
        # by looking at all of them
        my @entries = $uses{$use}{entries}->@*;
        foreach my $entry (@entries) {

            # For each mutex, if it is exclusive use that; if read-only, use
            # that if not already found an exclusive instance.

            # Having a category doesn't imply an exclusive lock.
            $$has_locale_ref = "r"
                           if (! $$has_locale_ref || $$has_locale_ref ne 'x')
                           && defined $entry->{categories};

            if (defined $entry->{locks}) {
                $$has_env_ref = $entry->{locks}{env}
                                if (! $$has_env_ref || $$has_env_ref ne 'x')
                                && defined $entry->{locks}{env};
                $$has_locale_ref = $entry->{locks}{locale}
                            if (! $$has_locale_ref || $$has_locale_ref ne 'x')
                            && defined $entry->{locks}{locale};
            }

            # If there are other races for this use, recurse to factor them
            # all in.
            if ($entry->{races} && $entry->{races}->@* > 1) {

                # Make a copy of the races, with this one deleted.  This keeps
                # us from infinitely recursing
                my %tags_copy = $race_tags_ref->%*;
                delete $tags_copy{$tag};

                foreach my $recurse_tag ($entry->{races}->@*) {
                    next if $recurse_tag eq $tag;

                    compute_race_mutex($recurse_tag, \%tags_copy,
                                       $has_env_ref, $has_locale_ref);
                }
            }
        }
    }
}

# Now do the calculations
my %race_locks;
foreach my $tag (keys %race_tags) {
    my $has_env = "";
    my $has_locale = "";
    compute_race_mutex($tag, \%race_tags, \$has_env, \$has_locale);
    if ($has_env) {
        if ($has_locale) {
            $race_locks{$tag} = "generic";
        }
        else {
            $race_locks{$tag} = "env";
        }
    }
    elsif ($has_locale) {
        $race_locks{$tag} = "locale";
    }
    else {
        $race_locks{$tag} = "generic";
    }
}

# Here, $race_logs{$tag} is the mutex to use for locking the race named by
# $tag, for all races.  Following all races for every use should have come up
# with consistent locks for each race, but we check for this below when we
# actually do the output

# Now ready to output
my $l = open_new($output_file, '>', { by => $me,
                               from => "data in $me",
                               file => $output_file, style => '*',
                               copyright => [2023..2024],
                               quote => "",
                             }
                );

sub output_list_with_heading {

    # If the list is empty, do nothing; otherwise outputs the items in the
    # list as columns in a C comment preceded by $heading, and followed by
    # $trailer.  The items are first sorted
    my ($handle, $list_ref, $heading, $trailer) = @_;

    return unless $list_ref->@*;

    print $handle $heading if $heading;

    my @sorted = sort name_order $list_ref->@*;
    my $list = columnarize_list(\@sorted, $comment_columns);
    $list =~ s/^/ * /gm;    # Each line has a " * " prefix
    print $handle $list;

    print $handle $trailer if $trailer;
}

sub output_columnarized_hash {
    my ($handle, $hash_ref, $heading, $trailer) = @_;

    # Like output_list_with_heading, except the data is a hash (not an array),
    # and is to be output in exactly two columns; the first being the keys of
    # the hash, and the second their respective values.

    return unless $hash_ref->%*;

    print $handle $heading if $heading;

    # Get maximum width of the names in the first column.
    my $max_width = 0;

    foreach my $use (keys $hash_ref->%*) {
        my $width = length $use;
        $max_width = $width if $width > $max_width
    }
    $max_width += 2;    # To allow for trailing "()", which we assume that
                        # each key is

    foreach my $use (sort name_order keys $hash_ref->%*) {
        printf $handle " * %-${max_width}s  %s\n",
                       "$use()", $hash_ref->{$use};
    }

    print $handle $trailer if $trailer;
}

sub display_names_ref {

    # Return a pointer to an array of names modified from the input array to
    # be the display name of each
    #
    my @displayable = map { $uses{$_}{display_name} } @_;
    return \@displayable;
}

print $l <<EOT;
/* This file contains macros to wrap their respective libc uses to ensure that
 * those uses are thread-safe in a multi-threaded environment.
 *
 * Most libc uses are already thread-safe without these wrappers, so do not
 * appear here.  But there are still many uses that do have multi-thread
 * issues.  See "Dealing with embedded perls and threads" in perlclib for
 * details.  Many of those uses can be made thread-safe if every running
 * thread submits to being controlled by an appropriate mutex.  The wrapper
 * macros defined in this file create macros that do this.  Take all libc
 * calls that have corresponding macros in this file, and precede each with
 * the LOCK macro, and make sure that all code paths afterwards include its
 * UNLOCK mate.
 *
 * The macros generated here expand to other macro calls that are expected to
 * be #defined in perl.h, depending on the platform and Configuration.  All
 * expand to no-ops when compiled without threading; in some threaded
 * Configurations many still will expand to no-ops.  Some definitions are
 * no-ops in all current cases, but you should wrap their functions with them
 * anyway, as future work likely will yield Configurations where they aren't
 * just no-ops.
 *
 * perlclib lists some functions that need to be called in single-thread mode
 * at least once, before switching to multi-threaded operation.  The locking
 * macros in this file assume that has been done.
 *
 * perlclib also lists some functions that can't be made thread-safe.  This
 * file defines macros for them that will result in a C compilation error if
 * used.
 *
 * The macros provided here do not protect your code from calls that are
 * susceptible to asynchronous signal issues.
 *
 * Some libc uses are not functions but expand to something that C code can
 * use as lvalues; for example, they can be assigned to.  The macros in this
 * file are not valid for lvalues.
 *
 * Individual uses may have additional caveats.  See their entries below for
 * these, and any additional specific information.
 *
 * You shouldn't use these locking macros for calls that happen so early in
 * the start-up procedure or late in the tear-down one that the appropriate
 * mutex operations aren't fully functional.  These are not likely to be
 * running multi-threaded at that time anyway.
 *
 * Also, the locale-related functions introduced in POSIX 2008 are not
 * portable to platforms that don't support them; for example any Windows one.
 * Perl has extensive code to hide the differences from your code.  You should
 * be using Perl_setlocale() to change and query the locale; and don't use
 * functions like uselocale(), or any function that takes a locale_t parameter
 * (typically such functions have the suffix "_l" in their names).  Keep in
 * mind that the current locale is assumed to be "C" for all Perl programs
 * except within the scope of "use locale", or when calling certain functions
 * in the POSIX module.  The perl core sorts all of this out for you; most
 * functions that deal directly with locale information should not be used.
 *
 * You may override any definitions here simply by #defining your own before
 * #including this file (which likely means before #including perl.h).
 *
 * Best practice is to call the LOCK macro; call the function and copy the
 * result to a per-thread place if that result points to a buffer internal to
 * libc; then UNLOCK it immediately.  After that, you can act on the result.
 *
 * The macros here are generated from an internal DATA section in
 * $me, populated from information derived from the
 * POSIX 2017 Standard and Linux glibc section 3 man pages (supplemented by
 * other vendor man pages).  (Linux tends to have extra restrictions not in
 * the Standard, and its man pages are typically more detailed than the
 * Standard and other vendors, who may also have the same restrictions, but
 * just don't document them.) The data can easily be adjusted as necessary.
 *
 * Many of the thread vulnerabilities involve the program's environment and
 * locale, so perl has separate mutexes for each of those two types of access.
 * There are a few others, all rare or obsolete.   There are also many races,
 * where certain functions concurrently executing in different threads can
 * interfere with each other unpredictably.  This header file currently lumps
 * all races and non-environment/locale vulnerabilities into a third, generic,
 * mutex.  So the macro names are various combinations of the three mutexes,
 * and whether the lock needs to be exclusive (suffix "x" in the lock name) or
 * non-exclusive (suffix "r" for read-only).  GEN means the generic mutex; ENV
 * the environment one; and LC the locale one.
 *
 * The lumping into the single generic mutex is due to the expectation that
 * such calls are infrequent enough that having a single mutex for all won't
 * noticeably affect performance, and that the more mutexes you have, the more
 * likely deadlock can occur.  Individual cases could be separated into
 * separate mutexes if necessary.  perl.h takes further steps in the expansion
 * of these macros to avoid deadlock altogether.
 */
EOT

# Beware that the Standard contains weasel words that could make multi-thread
# safety a fiction, depending on the application.  Our experience though is
# that libc implementations don't take advantage of this loophole, and the
# macros here are written as if it didn't exist.  (See
# https://stackoverflow.com/questions/78056645 )  The actual text is:
#
#    A thread-safe function can be safely invoked concurrently with other
#    calls to the same function, or with calls to any other thread-safe
#    functions, by multiple threads. Each function defined in the System
#    Interfaces volume of POSIX.1-2017 is thread-safe unless explicitly stated
#    otherwise. Examples are any 'pure' function, a function which holds a
#    mutex locked while it is accessing static storage or objects shared
#    among threads.
#
# Note that this doesn't say anything about the behavior of a thread-safe
# function when executing concurrently with a thread-unsafe function.  This
# effectively gives permission for a libc implementation to make every
# allegedly thread-safe function not be thread-safe for circumstances outside
# the control of the thread.  This would wreak havoc on a lot of code if libc
# implementations took much advantage of this loophole.  But it is a reason
# to avoid creating many mutexes.  If all threads lock on the same mutex when
# executing a thread-unsafe function, they defeat the weasel words.
#
# Another reason to minimize the number of mutexes is that each additional one
# increases the possibility of deadlock, unless the code is carefully
# crafted (and remains so during future maintenance).
#

# Output the computed results for each use in the DATA
foreach my $use (sort name_order keys %uses) {
    my $USE = uc $use;
    print $l "\n#ifndef ${USE}_LOCK\n";

    # If this use has at least one version that depends on a preprocessor
    # directive, and there isn't an #else one, automatically add one which
    # will expand to no-ops.
    if (   $uses{$use}{entries}[0]{preprocessor} ne ""
        && $uses{$use}{entries}[-1]{preprocessor} ne 'else')
    {
        push $uses{$use}->{entries}->@*, { preprocessor => 'else' };
    }

    # For each possibility for this use ...
    foreach my $entry ($uses{$use}->{entries}->@*) {
        #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper $use, $entry;

        my @comments;
        my $indent = "  ";      # We are within the scope of the above #ifndef
        my $dindent = $indent;  # Indentation for #define lines
        if ($entry->{preprocessor}) {
            print $l "#$indent$entry->{preprocessor}\n";
            $dindent .= "  ";   # #define indentation increased as a result
        }

        my $columns = $comment_columns - length $dindent;
        my $output_function_name = "$uses{$use}{display_name} ";

        my $hanging = " " x length $output_function_name;   # indentation

        # First accumulate all the comments for this entry
        foreach my $type (qw(obsolete preferred)) {
            my $item = $entry->{$type};
            if (defined $item) {
                my $note = ($type eq 'obsolete') ? "Obsolete" : "";
                if ($item) {

                    # Quote enclosed items are displayed as-is, except for
                    # stripping the quotes
                    if ($item =~ s/ ^ " (.*) " $ /$1/x) {
                        $note .= "; " if $note;
                        $note .= $item;
                    }
                    else {
                        if ($note) {    # Start a sentence only if nothing
                                        # precedes it.
                            $note .= "; use "
                        }
                        else {
                            $note = "Use "
                        }

                        # F means the remainder is a family
                        if ($item =~ s/ ^ F //x) {
                            $note .= perl_macro_family($item);
                        }
                        else {
                            $note .= format_list($item);
                        }
                        $note .= " instead";
                    }
                }

                push @comments, split "\n", wrap($columns, "", $hanging,
                                                $output_function_name . $note);
            }
        }

        if ($entry->{non_posix}) {
            my $text = "${output_function_name}either was never in the POSIX"
                     . " Standard, or was removed as of POSIX 2001.";
            push @comments, split "\n", wrap($columns, "", $hanging, $text);
        }

        if ($entry->{signals}) {
            my $signal_count = $entry->{signals}->@*;
            my $text = "${output_function_name}is vulnerable to signal";
            $text .= "s" if $signal_count > 1;
            $text .= " " . join(", ", $entry->{signals}->@*);
            push @comments, split "\n", wrap($columns, "", $hanging, $text);
        }

        if ($entry->{races}) {
            my %races_with;

            # Each item may have multiple races with a different tag for each.
            # %race_tags holds all the races for a given tag
            foreach my $tag ($entry->{races}->@*) {

                # Construct a hash of all the functions under this tag
                $races_with{$_} = $race_tags{$tag}{$_}
                                                  for keys $race_tags{$tag}->%*;
            }

            # Don't bother to list a use as having a race with just itself;
            # this decision to not list could easily be changed.
            if (keys %races_with > 1) {

                # Find myself.
                my $myself = delete $races_with{$use};
                my $race_text =
                    "${output_function_name}has potential races with other"
                  . " threads concurrently using";

                # Sort the remaining ones.
                my @race_names = sort name_order keys %races_with;

                # Create a list with me as the first item.  Doing this gets
                # the sub to create the proper text based on the real number
                # of items; otherwise the deleted one could mislead it.
                my $list_text = format_list(join ",", $myself, @race_names);

                # Change me to the word itself.
                $list_text =~ s/ $myself \(\)? ,? \s* //x;
                if (@race_names == 1) {
                    $race_text .= " either itself " . $list_text;
                }
                else {
                    $race_text .= " any of: itself, " . $list_text;
                }

                $race_text = wrap($columns, "", $hanging, "$race_text.");
                push @comments, split "\n", $race_text;
            }
        }

        if ($entry->{conditions}) {
            my $quoted = join(", ", $entry->{conditions}->@*);
            $quoted = "'$quoted'" if $quoted !~ /\s/;
            push @comments, $uses{$use}{display_name}
                          . " locking macros are only valid if "
                           . $quoted;
        }

        if ($entry->{notes}) {
            foreach my $note ($entry->{notes}->@*) {
                push @comments, split "\n", wrap($columns, "", $hanging,
                                                $output_function_name . $note);
            }
        }

        # Ready to output any comments
        if (@comments) {
            print $l "\n $dindent/* ", $comments[0];
            for (my $i = 1; $i < @comments; $i++) {
                print $l "\n $dindent * ", $comments[$i];
            }

            if (length($comments[-1]) + length($dindent) + 3
                                                           <= $comment_columns)
            {   # End the comment with a trailing "*/" if it fits on the line
                print $l " */\n";
            }
            else {  # Otherwise, put it on the next line
                print $l "\n $dindent */\n";
            }
        }

        # Now calculate and output the wrapper macros.

        if ($entry->{unsuitable}) {
            croak("Unsuitable function '$use' has a lock")
                                if $entry->{locks} || $entry->{categories};
            print $l <<~EOT;
                #${dindent}define ${USE}_LOCK                              \\
                #${dindent}  error_${use}_not_suitable_for_multi-threaded_operation
                EOT
        }
        elsif (! $entry->{locks} && ! $entry->{races} && ! $entry->{categories})
        {

            # No race, no lock => no op.
            print $l <<~EOT;
                #${dindent}define ${USE}_LOCK    NOOP
                #${dindent}define ${USE}_UNLOCK  NOOP
                EOT
        }
        else {
            my $locale_lock = delete $entry->{locks}{locale} // "";
            my $env_lock = delete $entry->{locks}{env} // "";

            # These are the other locks in the data.  This is only to catch
            # typos when someone makes a change to it.
            #
            # The ones marked 'x' override any input 'r' values.  These are
            # because the man pages are incomplete or inconsistent.  There
            # should be something that is a 'const:term' that locks term for
            # write-only access.  But there isn't, so have to assume that an
            # exclusive lock is needed.
            my %known_locks = (
                                hostid       => 'r',
                                term         => 'x',    # Obsolete
                                cwd          => 'x',    # Vulnerable to a
                                                        # chdir() call,
                                sigintr      => 'r',
                                mallopt      => 'r',
                                malloc_hooks => 'r',
                            );

            # This loop maps the rest of the locks into just the generic one
            my $generic_lock = "";
            my @unknown_locks;
            for my $key (keys $entry->{locks}->%*) {
                if (! defined $known_locks{$key}) {
                    push @unknown_locks, $key;
                    next;
                }

                # Can't get any more restrictive than this, so skip further
                # checking
                next if $generic_lock eq 'x';
                $generic_lock = $entry->{locks}{$key};
            }

            croak("Unknown lock: " . Dumper (\@unknown_locks))
                                                             if @unknown_locks;

            if ($entry->{races}) {

                # We have already computed the lock to use for each race
                my $lock = "";
                foreach my $race ($entry->{races}->@*) {
                    if ($lock eq "") {
                        $lock = $race_locks{$race};
                    }
                    elsif ($lock ne $race_locks{$race}) {

                        # The computation should have come up with consistent
                        # values
                        croak("Somehow the code came up with two different"
                            . " locks for $use: '$lock' and"
                            . " '$race_locks{$race}'");
                    }
                }

                eval "\$${lock}_lock = 'x'";
            }

            # A locale lock without a category defined for it means we don't
            # know which category(ies) to use; LC_ALL handles all
            # possibilities
            push $entry->{categories}->@*, "LC_ALL" if   $locale_lock
                                                    && ! $entry->{categories};

            $env_lock = 'ENV' . $env_lock if $env_lock;
            $generic_lock = 'GEN' . $generic_lock if $generic_lock;

            my $name = "";
            $name .= $generic_lock if $generic_lock;
            $name .= "_" if $env_lock && $generic_lock;
            $name .= $env_lock if $env_lock;

            # Ready to output if no locale issues are involved
            if (! $locale_lock && ! $entry->{categories}) {
                print $l <<~EOT;
                    #${dindent}define ${USE}_LOCK    ${name}_LOCK_
                    #${dindent}define ${USE}_UNLOCK  ${name}_UNLOCK_
                    EOT
            }
            else {
                if ($name || $locale_lock) {
                    $name .= "_" if $name;
                    $locale_lock = "r" unless $locale_lock;
                    $name .= "LC$locale_lock";
                    print $l <<~EOT;
                        #${dindent}define ${USE}_LOCK    ${name}_LOCK_()
                        #${dindent}define ${USE}_UNLOCK  ${name}_UNLOCK_()
                        EOT
                }
                else {
                    print $l <<~EOT;
                        #${dindent}define ${USE}_LOCK
                        #${dindent}define ${USE}_UNLOCK
                        EOT
                }
                $name .= $locale_lock;

            }
        }
    }

    print $l "#  endif\n" if $uses{$use}->{entries}->@* > 1;

    print $l "#endif\n";

    $uses{$use}{processed} = 1;

}

my @unhandled = grep { ! defined $uses{$_}{processed} }
                                                sort name_order keys %uses;
croak("These uses are unhandled: " . join ", ", @unhandled) if @unhandled;

read_only_bottom_close_and_rename($l);

# Below is the DATA section.  There are 5 types of lines:
#
#   1)  data lines, arranged like a table, with two columns, separated by a
#       pipe '|'.  The syntax is designed to be very similar to the ATTRIBUTES
#       section of the Linux man pages the data is derived from.  This allows
#       copy-pasting from those to here, with minimal changes, mostly
#       deletions.  There may be continuation lines for these, as described
#       below.
#   2)  a non-continuation line beginning with the string " __END__" indicates
#       it and anything past it to the end of the file are ignored.
#   2)  non-continuation, entirely blank lines are ignored
#   3)  non-continuation lines whose first non-blanks are the string "//" are
#       also ignored
#   4)  non-continuation lines beginning with the character '#' are treated as
#       C preprocessor lines, and output as-is, as part of the generated macro
#       definitions.
#
# The first column of a data line gives the uses that the second column
# applies to.  The uses are comma-separated.  See below for how this
# column can have continuation lines.
#
# The other column gives the data, again in the form of the Linux man pages.
# It applies to each use in the use list.  There are as many
# blank-separated fields as necessary in the second column.  If the final
# non-blank character on the line is '\', the next input line is a
# continuation line.
#
# If a continuation line contains the '|' character, the first portion of the
# line continues the uses column, and the second portion the data column.
# Otherwise, if the first character in the line is a blank, it continues the
# data column; if non-blank, it continues the uses column.   Continuation
# lines themselves may be continued, as many as necessary.
#
# The uses column may be continued even without a '\' character.  If the
# final non-blank character in the uses list is a comma, the next line is
# considered to be more uses, as many lines as necessary.

# The data column contains the following fields (appearing in any order,
# almost):
#
#   a)  Simply the character 'U'.  This indicates that the functions in the
#       uses column are thread-unsafe, and therefore should not be used in
#       multi-thread mode.  The presence of this field precludes any other
#       field but comment ones.
#
#   b)  The character 'M' means that uses column contains macros, not
#       functions.  The only current practical effect of this field is that
#       each item is listed in the generated comments as not being a function.
#
#   c)  The character 'V' means that uses column contains variables, not
#       functions.  The only current practical effect of this field is that
#       each item is listed in the generated comments as not being a function.
#
#   d)  The character 'X' means that the functions in the uses column are
#       non-Standard; they don't appear in any modern version of the POSIX
#       Standard.
#
#   e)  The character 'O' or that character followed by either a double-quote
#       enclosed "string" or a comma-separated list of function names.  This
#       means that the uses in the uses column are considered obsolete.  If
#       the 'O' stands alone, there is no simple replacement for the obsolete
#       functions.  If the 'O' is followed by a comma-separated list, the list
#       gives preferred alternatives that should be used instead.  The
#       "string" is displayed literally for situations where a comma-separated
#       list is inadequate.  "string" may not contain the '"' character
#       internally.
#
#   f)  The string "PF" followed by a name.  This means that the name is
#       preferred over the functions (symbolized by the 'P'), and that it
#       comes from a family (the 'F' means this) of Perl macros; 'name'
#       indicates which family.
#
#   g)  The character 'P', followed by a comma-separated list of function.
#       names (not beginning with 'F').  The functions in this list are
#       preferred over the ones in the uses column.

#   h)  The string "init".  This means that the functions in the uses column
#       are unsafe the first time they are called, but after that can be made
#       thread-safe by following the dictates of any remaining fields.  Hence
#       these functions must be called at least once during single-thread
#       startup.
#
#   i)  The string "sig:" followed by the name of a signal.  For example
#       "sig:ALRM".  This means the functions are vulnerable to the SIGALRM
#       signal.  A list of all such functions is output in the comments at the
#       top of the generated header file, and individually at the point of the
#       macro definitions for each affected function.  But, it is beyond the
#       scope of this to automatically protect against these.  You'll have to
#       figure it out on your own.
#
#   j)  The string "timer".  This appears to be obsolete, with sig:ALRM taking
#       over its meaning.  The code here simply verifies that this string
#       doesn't appear without also "sig:ALRM"
#
#   k)  Any other string of \w characters, none uppercase.  For example,
#       "env".  Each use whose data line contains this field
#       non-atomically reads shared data of the same ilk.  So, in this case,
#       "env" means that these uses read from data associated with
#       "env".  Thus "env" serves as a tag that groups the uses into a
#       class of readers of whatever "env" means.
#
#       The implications of this is that these uses need to each be
#       protected by a read-lock associated with the tag, so that no use
#       that writes to that data can be concurrently executing.
#
#   l)  The string "const:" followed by a tag word (\w+).  This means that the
#       affected functions write to shared data associated with the tag.
#
#       The implication is that these functions need to each have an
#       exclusive lock associated with the tag, to avoid interference with
#       other such functions, or the functions in k) that have the same tag.
#       Continuing the previous example, the function putenv() has
#       "const:env".  This means it needs an exclusive lock on the mutex
#       associated with "env", and all functions that contain just "env" for
#       their data need read-locks on that mutex.
#
#   m)  The string "race".  This means that these each of these uses has
#       a potential race with something running in another thread.  If "race"
#       appears alone, what the other thing(s) that can interfere with it are
#       unspecified, but the generated header takes it as meaning the use
#       only has a race with another instance of it.  This could be because of
#       a buffer shared between threads, or simply that it returns a pointer
#       to internal global static storage, which must be used while still
#       locked, or copied to a per-thread safe place for later use.
#
#       "race" may be followed by a colon and a tag word, like "race:tmpbuf".
#       The potential race is with any other uses that also specify a
#       race with the same tag word.
#
#       The implication is that each such use must be protected with an
#       exclusive mutex associated with that tag, so none can run
#       concurrently.
#
#       A condition may be attached to a race, as in "race:mbrlen/!ps".  The
#       condition is introduced by a single '/'.  This means that the race
#       doesn't happen unless the condition is met.  If you look at the
#       mbrlen() man page, you will find that it takes an argument named "ps".
#       What the condition tells us is that any call to mbrlen with "!ps",
#       (hence ps is NULL) is thread-unsafe.  You can easily write your code
#       so that "ps" is non-NULL, and remove this cause of unsafety.  The
#       generated macros assume that you do so.
#
#   n)  A string giving a locale category, like "LC_TIME".  This indicates
#       what locale category affects the execution of this use.  Multiple
#       ones may be specified.  These are for future use. XXX
#
#   o)  The string "//".  This must be the final field on the line, and
#       the rest of the line becomes a comment string that is to be output
#       just above the generated macros for each affected use.  Any
#       continuation lines continue this comment.
#
# There is another type of continuation line.  If the last non-blank character
# in the uses column is a comma, there are more uses to come.  These
# come on the lines immediately following any data column continuation lines.
# These lines are simply more comma-separated use names.  The final line
# doesn't end in a comma.
#
# The #endif preprocessor line marks the end of the uses affected by
# previous preprocessor lines.  If there was no "#else" line, macros expanding
# to no-ops are automatically generated for the #else case.

__DATA__
addmntent  	| race:stream locale X
alphasort       | locale LC_COLLATE
asctime  	| race:asctime locale  OPerl_sv_strftime_tm LC_TIME
asctime_r  	| locale OPerl_sv_strftime_tm LC_TIME
asprintf, vasprintf| locale X LC_NUMERIC
atof  	        | locale LC_NUMERIC
atoi, atol, atoll| locale LC_NUMERIC
btowc           | LC_CTYPE
#ifndef __GLIBC__
basename        | race
#endif
#ifndef __GLIBC__
catgets         | race
#endif

catopen  	| env LC_MESSAGES
clearenv  	| const:env
clearerr_unlocked,| race:stream X                                           \
fflush_unlocked,  | // Is thread-safe if flockfile() or ftrylockfile() have \
fgetc_unlocked,   |    locked the stream, but should not be used since not  \
fgets_unlocked,   |    standardized and not widely implemented
fputc_unlocked,
fputs_unlocked,
fread_unlocked,
fwrite_unlocked,
getwc_unlocked,
putwc_unlocked

fgetwc_unlocked,  | race:stream LC_CTYPE X                                  \
fgetws_unlocked,  | // Is thread-safe if flockfile() or ftrylockfile() have \
fputwc_unlocked,  |    locked the stream, but should not be used since not  \
fputws_unlocked   |    standardized and not widely implemented

crypt_gensalt	| race:crypt_gensalt X
crypt       	| race:crypt
crypt_r       	| X

#ifndef __GLIBC__
ctermid         | race:ctermid/!s
#endif

ctermid_r       | X
ctime_r  	| race:tzset env locale LC_TIME OPerl_sv_strftime_ints
ctime       	| race:tmbuf race:asctime race:tzset env locale LC_TIME     \
                  OPerl_sv_strftime_ints
cuserid  	| race:cuserid/!string locale X O"DO NOT USE; see its man page"

dbm_clearerr,   | race
dbm_close,
dbm_delete,
dbm_error,
dbm_fetch,
dbm_firstkey,
dbm_nextkey,
dbm_open,
dbm_store
#ifndef __GLIBC__
dirname         | locale
#endif
#ifndef __GLIBC__
dlerror         | race
#endif

drand48, erand48,| race:drand48
jrand48, lcong48,
lrand48, mrand48,
nrand48, seed48,
srand48

drand48_r,      | race:buffer X
erand48_r,
jrand48_r,
lcong48_r,
lrand48_r,
mrand48_r,
nrand48_r,
seed48_r,
srand48_r

ecvt        	| race:ecvt Osnprintf

encrypt, setkey | race:crypt
endaliasent  	| locale X

endfsent, 	| race:fsent X
setfsent

endgrent, 	| race:grent locale
setgrent

endgrent_r  	| race:grent locale Oendgrent X

endhostent, 	| race:hostent env locale
sethostent

endhostent_r  	| race:hostent env locale Oendhostent X

endnetent  	| race:netent env locale
endnetent_r  	| race:netent env locale Oendnetent X
endnetgrent  	| race:netgrent X

endprotoent, 	| race:protoent locale
setprotoent

endprotoent_r  	| race:protoent locale Oendprotoent X

endpwent,       | race:pwent locale
setpwent

endpwent_r      | race:pwent locale Oendpwent X

endrpcent  	| locale X

endservent, 	| race:servent locale
setservent

endservent_r  	| race:servent locale Oendservent X

endspent, 	| race:getspent locale X
getspent_r,
setspent

endttyent,      | race:ttyent X
getttyent,
getttynam,
setttyent

endusershell  	| U X
endutent        | race:utent Oendutxent X
endutxent       | race:utent
err  	        | locale X
error_at_line  	| race:error_at_line/error_one_per_line locale X
error       	| locale X
errx        	| locale X
ether_aton  	| U X
ether_ntoa  	| U X

execlp, execvp  | env
execvpe         | env X

exit        	| race:exit

__fbufsize, 	| race:stream X
__fpending,
__fsetlocking

__fpurge        | race:stream X

fcloseall  	| race:streams X
fcvt        	| race:fcvt Osnprintf
fgetgrent  	| race:fgetgrent X
fgetpwent  	| race:fgetpwent X
fgetspent  	| race:fgetspent X
fgetwc, getwc   | LC_CTYPE
fgetws          | LC_CTYPE
fnmatch  	| env locale
forkpty, openpty| locale X
putwc, fputwc   | LC_CTYPE
fputws          | LC_CTYPE
fts_children  	| U X
fts_read  	| U X
ftw             | race  Onftw

fwscanf, swscanf,| locale LC_NUMERIC
wscanf

gammaf, gammal  | race:signgam X

gamma, lgammaf, | race:signgam
lgammal, lgamma

getaddrinfo  	| env locale
getaliasbyname_r| locale X
getaliasbyname  | U X Pgetaliasbyname_r
getaliasent_r  	| locale X
getaliasent  	| U X Pgetaliasent_r
getc_unlocked   | race:stream  // Is thread-safe if flockfile() or      \
                                  ftrylockfile() have locked the stream
getchar_unlocked| race:stdin  // Is thread-safe if flockfile() or       \
                                 ftrylockfile() have locked stdin

getcontext, setcontext| race:ucp

get_current_dir_name | env X
getdate_r  	| env locale LC_TIME X
getdate  	| race:getdate env locale LC_TIME

// On platforms where the static buffer contained in getenv() is per-thread
// rather than process-wide, another thread executing a getenv() at the same
// time won't destroy ours before we have copied the result safely away and
// unlocked the mutex.  On such platforms (which is most), we can have many
// readers of the environment at the same time.
#ifdef GETENV_PRESERVES_OTHER_THREAD
getenv 	        | env
secure_getenv   | X env
#else
// If, on the other hand, another thread could zap our getenv() return, we
// need to keep them from executing until we are done
getenv 	| race env
secure_getenv   | X race env
#endif

getfsent, 	| race:fsent locale X
getfsfile,
getfsspec

getgrent  	| race:grent race:grentbuf locale
getgrent_r  	| race:grent locale X
getgrgid  	| race:grgid locale
getgrgid_r  	| locale
getgrnam  	| race:grnam locale
getgrnam_r  	| locale
getgrouplist  	| locale X
gethostbyaddr_r | env locale X
gethostbyaddr  	| race:hostbyaddr env locale Ogetaddrinfo                   \
                  // return needs a deep copy for safety
gethostbyname2_r| env locale X
gethostbyname2  | race:hostbyname2 env locale X
gethostbyname_r | env locale X
gethostbyname  	| race:hostbyname env locale Ogetnameinfo                   \
                  // return needs a deep copy for safety
gethostent      | race:hostent race:hostentbuf env locale
gethostent_r    | race:hostent env locale X
gethostid  	| hostid env locale
getlogin  	| race:getlogin race:utent sig:ALRM timer locale
getlogin_r  	| race:utent sig:ALRM timer locale
getmntent_r  	| locale X
getmntent  	| race:mntentbuf locale X
getnameinfo  	| env locale
getnetbyaddr_r  | locale X
getnetbyaddr  	| race:netbyaddr locale
getnetbyname_r  | locale X
getnetbyname  	| race:netbyname env locale
getnetent_r  	| locale X
getnetent  	| race:netent race:netentbuf env locale
getnetgrent  	| race:netgrent race:netgrentbuf locale X

getnetgrent_r, 	| race:netgrent locale X
innetgr,
setnetgrent

getopt  	| race:getopt env

getopt_long,    | race:getopt env X
getopt_long_only

getpass  	| term  O"DO NOT USE; see its man page" X
getprotobyname_r| locale X
getprotobyname  | race:protobyname locale
getprotobynumber_r| locale X
getprotobynumber| race:protobynumber locale
getprotoent_r  	| locale X
getprotoent  	| race:protoent race:protoentbuf locale
getpwent  	| race:pwent race:pwentbuf locale
getpwent_r  	| race:pwent locale X
getpw       	| locale Ogetpwuid X
getpwnam_r  	| locale
getpwnam  	| race:pwnam locale
getpwuid_r  	| locale
getpwuid  	| race:pwuid locale
getrpcbyname_r  | locale X
getrpcbyname  	| U X Pgetrpcbyname_r
getrpcbynumber_r| locale X
getrpcbynumber  | U X Pgetrpcbynumber_r
getrpcent_r  	| locale X
getrpcent  	| U X Pgetrpcent_r
getrpcport  	| env locale X
getservbyname_r | locale X
getservbyname  	| race:servbyname locale
getservbyport_r | locale X
getservbyport  	| race:servbyport locale
getservent_r  	| locale X
getservent  	| race:servent race:serventbuf locale
getspent  	| race:getspent race:spentbuf locale X
getspnam  	| race:getspnam locale X
getspnam_r  	| locale X
getusershell  	| U X
getutent        | init race:utent race:utentbuf sig:ALRM timer Ogetutxent X
getutxent       | init race:utent race:utentbuf sig:ALRM timer
getutid         | init race:utent sig:ALRM timer Ogetutxid X
getutxid        | init race:utent sig:ALRM timer
getutline  	| init race:utent sig:ALRM timer Ogetutxline X
getutxline  	| init race:utent sig:ALRM timer
getwchar        | LC_CTYPE
getwchar_unlocked| race:stdin X                                             \
                    // Is thread-safe if flockfile() or ftrylockfile()      \
                       have locked stdin, but should not be used since not  \
                       standardized and not widely implemented

glob  	        | race:utent env sig:ALRM timer locale LC_COLLATE
gmtime 	        | race:tmbuf env locale LC_TIME
gmtime_r  	| env locale LC_TIME

grantpt  	| locale

hcreate,  	| race:hsearch
hdestroy,
hsearch

hcreate_r,      | race:htab X
hsearch_r,
hdestroy_r

iconv_open  	| locale
iconv       	| race:cd

inet_addr,      | locale
inet_ntoa

inet_aton, 	| locale X
inet_network

inet_ntop  	| locale
inet_pton  	| locale
initgroups  	| locale X

initstate_r,    | race:buf X
random_r,
setstate_r,
srandom_r

iruserok_af  	| locale X
iruserok  	| locale X
isalpha         | LC_CTYPE PFisALPHA
isalnum         | LC_CTYPE PFisALNUM
isascii         | LC_CTYPE  PFisASCII                                       \
                  // Considered obsolete as being non-portable, but Perl    \
                     makes it portable when using a macro
isblank         | LC_CTYPE PFisBLANK
iscntrl         | LC_CTYPE PFisCNTRL
isdigit         | LC_CTYPE PFisDIGIT
isgraph         | LC_CTYPE PFisGRAPH
islower         | LC_CTYPE PFisLOWER
isprint         | LC_CTYPE PFisPRINT
ispunct         | LC_CTYPE PFisPUNCT
isspace         | LC_CTYPE PFisSPACE
isupper         | LC_CTYPE PFisUPPER
isxdigit        | LC_CTYPE PFisXDIGIT

isalnum_l,      | LC_CTYPE
isalpha_l,
isblank_l, iscntrl_l,
isdigit_l, isgraph_l,
islower_l, isprint_l,
ispunct_l, isspace_l,
isupper_l, isxdigit_l
isascii_l       | LC_CTYPE X

iswalpha        | locale LC_CTYPE PFisALPHA
iswalnum        | locale LC_CTYPE PFisALNUM
iswblank        | locale LC_CTYPE PFisBLANK
iswcntrl        | locale LC_CTYPE PFisCNTRL
iswdigit        | locale LC_CTYPE PFisDIGIT
iswgraph        | locale LC_CTYPE PFisGRAPH
iswlower        | locale LC_CTYPE PFisLOWER
iswprint        | locale LC_CTYPE PFisPRINT
iswpunct        | locale LC_CTYPE PFisPUNCT
iswspace        | locale LC_CTYPE PFisSPACE
iswupper        | locale LC_CTYPE PFisUPPER
iswxdigit       | locale LC_CTYPE PFisXDIGIT

iswalnum_l,     | locale LC_CTYPE
iswalpha_l, iswblank_l,
iswcntrl_l, iswdigit_l,
iswgraph_l, iswlower_l,
iswprint_l, iswpunct_l,
iswspace_l, iswupper_l,
iswxdigit_l

l64a  	        | race:l64a
localeconv  	| race:localeconv locale LC_NUMERIC LC_MONETARY PPerl_localeconv
localtime       | race:tmbuf race:tzset env locale LC_TIME
localtime_r  	| race:tzset env locale LC_TIME
login, logout  	| race:utent sig:ALRM timer X
login_tty  	| race:ttyname X
logwtmp  	| sig:ALRM timer X
makecontext     | race:ucp
mallinfo  	| init const:mallopt X
MB_CUR_MAX      | M LC_CTYPE
mblen  	        | race LC_CTYPE Pmbrlen
mbrlen  	| race:mbrlen/!ps LC_CTYPE
mbrtowc         | LC_CTYPE race:mbrtowc/!ps
mbsinit         | LC_CTYPE
mbsnrtowcs  	| race:mbsnrtowcs/!ps LC_CTYPE
mbsrtowcs  	| race:mbsrtowcs/!ps LC_CTYPE
mbstowcs        | LC_CTYPE
mbtowc          | race LC_CTYPE Pmbrtowc

mcheck_check_all,| race:mcheck const:malloc_hooks X
mcheck_pedantic,
mcheck, mprobe

mktime  	| race:tzset env locale LC_TIME
mtrace, muntrace| U X
nan, nanf, nanl | locale LC_NUMERIC
nftw        	| cwd   // chdir() in another thread will mess this up
newlocale  	| env
nl_langinfo  	| race locale
perror  	| race:stderr
posix_fallocate | // The safety in glibc depends on the file system.    \
                     Generally safe

printf, fprintf,| LC_NUMERIC locale
dprintf, sprintf,
snprintf, vprintf,
vfprintf, vdprintf,
vsprintf, vsnprintf
profil  	| U X
psiginfo  	| locale
psignal  	| locale
ptsname  	| race:ptsname
putc_unlocked   | race:stream  // Is thread-safe if flockfile() or          \
                                  ftrylockfile() have locked the stream
putchar_unlocked| race:stdout  // Is thread-safe if flockfile() or          \
                                  ftrylockfile() have locked stdin
putenv  	| const:env
putpwent  	| locale
putspent  	| locale X
pututline       | race:utent sig:ALRM timer Opututxline X
pututxline      | race:utent sig:ALRM timer
putwchar        | LC_CTYPE
putwchar_unlocked| race:stdout X  // Is thread-safe if flockfile() or       \
                                     ftrylockfile() have locked stdout, but \
                                     should not be used since not           \
                                     standardized and not widely implemented
valloc, pvalloc | init X
qecvt  	        | race:qecvt Osnprintf X
qfcvt       	| race:qfcvt Osnprintf X
querylocale     | PPerl_setlocale                                           \
                  // This function is non-portable, found usually only on   \
                     *BSD-derived platforms, and is buggy in various ways.  \
                     DO NOT USE.  The next version of the POSIX Standard is \
                     scheduled to have a replacement for this, but you      \
                     should be using Perl_setlocale() which copes for the   \
                     deficiencies in this.

#ifndef __GLIBC__
rand            | // Problematic and should be avoided; See POSIX Standard
#endif

rcmd_af  	| U X
rcmd        	| U X
readdir  	| race:dirstream
readdir_r       | Oreaddir  // Deprecated by glibc.  It is recommended to   \
                               use plain readdir() instead due to various   \
                               limitations, and modern implementations of   \
                               readdir tend to be thread-safe if concurrent \
                               calls use different directory streams
readdir64       | race:dirstream X
readdir64_r     | X
re_comp         | U  Oregcomp X
re_exec  	| U  Oregexec X
regcomp  	| locale
regerror  	| env
regexec  	| locale
res_nclose  	| locale X
res_ninit  	| locale X
res_nquerydomain| locale X
res_nquery  	| locale X
res_nsearch  	| locale X
res_nsend  	| locale X
rexec_af  	| U  Orcmd X
rexec  	        | U  Orcmd X
rpmatch         | LC_MESSAGES locale X
ruserok_af  	| locale X
ruserok  	| locale X

scanf, fscanf,  | locale LC_NUMERIC
sscanf, vscanf,
vsscanf, vfscanf

setaliasent  	| locale X
setenv, unsetenv| const:env
setgrent_r  	| race:grent locale Osetgrent X
sethostent_r 	| race:hostent env locale Osethostent X
sethostid  	| const:hostid

#ifndef WIN32
setlocale  	| race const:locale env PPerl_setlocale
setlocale_r  	| const:locale env OPerl_setlocale PPerl_setlocale X
#endif

setlogmask  	| race:LogMask
setnetent  	| race:netent env locale
setnetent_r  	| race:netent env locale Osetnetent X
setprotoent_r 	| race:protoent locale Osetprotoent X
setpwent_r      | race:pwent locale Osetpwent X
setrpcent  	| locale X
setservent_r 	| race:servent locale Osetservent X
setusershell  	| U X
setutent        | race:utent Osetutxent X
setutxent       | race:utent
sgetspent  	| race:sgetspent X
sgetspent_r  	| locale X
shm_open, shm_unlink| locale
siginterrupt  	| const:sigintr                                             \
                  O"Use sigaction(2) with the SA_RESTART flag instead"
sleep       	| sig:SIGCHLD/linux
ssignal  	| sigintr O X

strcasecmp,     | locale LC_CTYPE LC_COLLATE                                \
strncasecmp     | // The POSIX Standard says results are undefined unless   \
                     LC_CTYPE is the POSIX locale

strcasestr  	| locale X LC_CTYPE
strcoll, wcscoll| locale LC_COLLATE

strerror        | race:strerror LC_MESSAGES

strerror_r,     | LC_MESSAGES
strerror_l

strfmon         | LC_MONETARY locale
strfmon_l       | LC_MONETARY

strfromd,       | locale LC_NUMERIC  // Asynchronous unsafe
strfromf, strfroml

strftime  	| race:tzset env locale LC_TIME                             \
                  PPerl_sv_strftime_tm,Perl_sv_strftime_ints

strftime_l  	| LC_TIME
strptime  	| env locale LC_TIME
strsignal  	| race:strsignal locale LC_MESSAGES

strtod,         | locale LC_CTYPE LC_NUMERIC
strtof,
strtold

strtoimax  	| locale LC_CTYPE LC_NUMERIC
strtok  	| race:strtok Pstrtok_r
wcstod, wcstold,| locale LC_NUMERIC
wcstof

strtol, strtoll | locale LC_CTYPE LC_NUMERIC
strtoq, strtouq | locale LC_CTYPE LC_NUMERIC X
strtoul, strtoull| locale LC_CTYPE LC_NUMERIC


strtoumax  	| locale LC_CTYPE LC_NUMERIC
strverscmp      | LC_COLLATE X
strxfrm  	| locale LC_COLLATE LC_CTYPE
wcsxfrm         | locale LC_COLLATE LC_CTYPE
swapcontext  	| race:oucp race:ucp
sysconf  	| env

#ifndef __GLIBC__
system          | // Some implementations are not-thread safe; See POSIX    \
                     Standard
#endif

syslog          | env locale

tdelete, 	| race:rootp
tfind,
tsearch

tempnam  	| env Omkstemp,tmpfile
timegm  	| env locale X LC_TIME
timelocal  	| env locale X LC_TIME
tmpnam  	| race:tmpnam/!s Omkstemp,tmpfile
tmpnam_r  	| X Pmkstemp,tmpfile
tolower, tolower_l| LC_CTYPE PFtoLOWER
toupper, toupper_l| LC_CTYPE PFtoUPPER
towctrans       | LC_CTYPE
towlower, towlower_l| LC_CTYPE PFtoLOWER
towupper, towupper_l| LC_CTYPE PFtoUPPER
ttyname  	| race:ttyname  Pttyname_r
ttyname_r  	|
ttyslot  	| U X
twalk  	        | race:root
twalk_r  	| race:root X

// The POSIX Standard says:
//
//    "If a thread accesses tzname, daylight, or timezone  directly while
//     another thread is in a call to tzset(), or to any function that is
//     required or allowed to set timezone information as if by calling tzset(),
//     the behavior is undefined."
//
// Those three items are names of (typically) global variables.
//
//  Further,
//
//    "The tzset() function shall use the value of the environment variable TZ
//     to set time conversion information used by ctime, localtime, mktime, and
//     strftime. If TZ is absent from the environment, implementation-defined
//     default timezone information shall be used.
//
// This means that tzset() must have an exclusive lock, as well as the others
// listed that call it.
tzset  	        | race:tzset env locale LC_TIME

tzname, daylight,| V race:tzset LC_TIME
timezone

ungetwc         | LC_CTYPE
updwtmp  	| sig:ALRM timer X
utmpname  	| race:utent X

// khw believes that this function is thread-safe if called with a per-thread
// argument
va_arg  	| race:ap/arg-ap-is-local-to-its-thread

verr  	        | locale X
verrx       	| locale X
versionsort     | locale X
vsyslog         | env locale X
vwarn       	| locale X
vwarnx  	| locale X
warn        	| locale X
warnx       	| locale X
wcrtomb  	| race:wcrtomb/!ps LC_CTYPE
wcscasecmp  	| locale LC_CTYPE
wcsncasecmp  	| locale LC_CTYPE
wcsnrtombs  	| race:wcsnrtombs/!ps LC_CTYPE
wcsrtombs  	| race:wcsrtombs/!ps LC_CTYPE
wcstoimax  	| locale LC_CTYPE LC_NUMERIC
wcstombs        | LC_CTYPE
wcstoumax  	| locale LC_CTYPE LC_NUMERIC
wcswidth  	| locale LC_CTYPE
wctob           | LC_CTYPE  Pwctomb,wcrtomb
wctomb  	| race LC_CTYPE Pwcrtomb
wctrans  	| locale LC_CTYPE
wctype  	| locale LC_CTYPE
wcwidth  	| locale LC_CTYPE
wordexp  	| race:utent const:env sig:ALRM timer locale
wprintf, fwprintf,| locale LC_CTYPE LC_NUMERIC
swprintf, vwprintf,
vfwprintf, vswprintf
scandir         | LC_CTYPE LC_COLLATE
wcschr          | LC_CTYPE
wcsftime        | LC_CTYPE LC_TIME
wcsrchr         | LC_CTYPE
#ifdef WIN32
wsetlocale      | PPerl_setlocale                                           \
                  // Actually "_wsetlocale()", and its macro name would be  \
                     _WSETLOCALE_LOCK().  But any name beginning  with an   \
                     underscore is technically reserved for the libc        \
                     implementation itself; hence is illegal for perl to    \
                     use.  The real definition of WSETLOCALE_LOCK() is in   \
                     perl.h, as is too complicated to define here.  But you \
                     should be using Perl_setlocale() anyway.
#endif

__END__

The relevant parts of many of the man page sources for the above data.  Kept
here as a convenience for checking things.  These are extracted from Ubuntu
20.04, as modified by official patches.

       │l64a()    │ Thread safety │ MT-Unsafe race:l64a │
       ├────────────────────────┼───────────────┼────────────────┤
       │asprintf(), vasprintf() │ Thread safety │ MT-Safe locale │
       ├────────────────────────┼───────────────┼────────────────┤
       │atof()    │ Thread safety │ MT-Safe locale               │
       ├────────────────────────┼───────────────┼────────────────┤
       │atoi(), atol(), atoll() │ Thread safety │ MT-Safe locale │
       │bindresvport() │ Thread safety │ glibc >= 2.17: MT-Safe  │
       │               │               │ glibc < 2.17: MT-Unsafe │
       ├──────────┼───────────────┼─────────────────────┤
       │catopen()  │ Thread safety │ MT-Safe env │
       ├──────────┼───────────────┼─────────────────────┤
       │cfree()   │ Thread safety │ MT-Safe // In glibc  │
       ├──────────┼───────────────┼─────────────────────┤
       │clearenv() │ Thread safety │ MT-Unsafe const:env │
       ├──────────────────┼───────────────┼──────────────────────────────┤
       │crypt              │ Thread safety │ MT-Unsafe race:crypt │
       ├──────────────────┼───────────────┼──────────────────────────────┤
       │crypt_gensalt     │ Thread safety │ MT-Unsafe race:crypt_gensalt │
       ├──────────────────┼───────────────┼──────────────────────────────┤
       │asctime()      │ Thread safety │ MT-Unsafe race:asctime locale   │
       ├───────────────┼───────────────┼─────────────────────────────────┤
       │asctime_r()    │ Thread safety │ MT-Safe locale                  │
       ├───────────────┼───────────────┼─────────────────────────────────┤
       │ctime()        │ Thread safety │ MT-Unsafe race:tmbuf            │
       │               │               │ race:asctime env locale         │
       ├───────────────┼───────────────┼─────────────────────────────────┤
       │ctime_r(), gm‐ │ Thread safety │ MT-Safe env locale              │
       │time_r(), lo‐  │               │                                 │
       │caltime_r(),   │               │                                 │
       │mktime()       │               │                                 │
       ├───────────────┼───────────────┼─────────────────────────────────┤
       │gmtime(), lo‐  │ Thread safety │ MT-Unsafe race:tmbuf env locale │
       │caltime()      │               │                                 │
       ├──────────────────────┼───────────────┼────────────────────────┤
       │drand48(), erand48(), │ Thread safety │ MT-Unsafe race:drand48 │
       │lrand48(), nrand48(), │               │                        │
       │mrand48(), jrand48(), │               │                        │
       │srand48(), seed48(),  │               │                        │
       │lcong48()             │               │                        │
       ├──────────────────────────┼───────────────┼─────────────────────┤
       │drand48_r(), erand48_r(), │ Thread safety │ MT-Safe race:buffer │
       │lrand48_r(), nrand48_r(), │               │                     │
       │mrand48_r(), jrand48_r(), │               │                     │
       │srand48_r(), seed48_r(),  │               │                     │
       │lcong48_r()               │               │                     │
       ├──────────────────────────┼───────────────┼─────────────────────┤
       │ecvt()    │ Thread safety │ MT-Unsafe race:ecvt │
       ├──────────┼───────────────┼─────────────────────┤
       │fcvt()    │ Thread safety │ MT-Unsafe race:fcvt │
       ├──────────────────────────┼───────────────┼─────────────────────┤
       │encrypt(), setkey()     │ Thread safety │ MT-Unsafe race:crypt │
       ├──────────────────┼───────────────┼────────────────┤
       │err(), errx(),    │ Thread safety │ MT-Safe locale │
       │warn(), warnx(),  │               │                │
       │verr(), verrx(),  │               │                │
       │vwarn(), vwarnx() │               │                │
       ├────────────────┼───────────────┼───────────────────────────────────┤
       │error()         │ Thread safety │ MT-Safe locale                    │
       ├────────────────┼───────────────┼───────────────────────────────────┤
       │error_at_line() │ Thread safety │ MT-Unsafe race:error_at_line/er‐  │
       │                │               │ ror_one_per_line locale           │
       ├──────────────────────────────────┼───────────────┼───────────┤
       │ether_aton(), ether_ntoa()        │ Thread safety │ MT-Unsafe │
       ├──────────────────────────────┼───────────────┼─────────────┤
       │execlp(), execvp(), execvpe() │ Thread safety │ MT-Safe env │
       ├──────────┼───────────────┼─────────────────────┤
       │exit()    │ Thread safety │ MT-Unsafe race:exit │
       ├──────────────────────────┼───────────────┼─────────────────────┤
       │fcloseall() │ Thread safety │ MT-Unsafe race:streams │
       ├──────────────────────────┼───────────────┼─────────────────────┤
       │fgetgrent() │ Thread safety │ MT-Unsafe race:fgetgrent │
       ├────────────┼───────────────┼──────────────────────────┤
       │fgetpwent() │ Thread safety │ MT-Unsafe race:fgetpwent │
       ├──────────────────────────┼───────────────┼─────────────────────┤
       │fmtmsg()  │ Thread safety │ glibc >= 2.16: MT-Safe  │
       │          │               │ glibc < 2.16: MT-Unsafe │
       ├──────────┼───────────────┼────────────────────┤
       │fnmatch() │ Thread safety │ MT-Safe env locale │
       ├───────────┼───────────────┼─────────────────────┤
       │__fpurge() │ Thread safety │ MT-Safe race:stream │
       ├───────────────────────────────────┼───────────────┼───────────┤
       │fts_read(), fts_children()         │ Thread safety │ MT-Unsafe │
       ├──────────┼───────────────┼─────────────┤
       │nftw()    │ Thread safety │ MT-Safe cwd │
       ├────────────────────────────┼───────────────┼────────────────────────┤
       │gamma(), gammaf(), gammal() │ Thread safety │ MT-Unsafe race:signgam │
       ├────────────────┼───────────────┼────────────────────┤
       │getaddrinfo()   │ Thread safety │ MT-Safe env locale │
       ├───────────────────────────┼───────────────┼──────────────────┤
       │getcontext(), setcontext() │ Thread safety │ MT-Safe race:ucp │
       ├───────────────────────┼───────────────┼─────────────┤
       │get_current_dir_name() │ Thread safety │ MT-Safe env │
       ├────────────┼───────────────┼───────────────────────────────────┤
       │getdate()   │ Thread safety │ MT-Unsafe race:getdate env locale │
       ├────────────┼───────────────┼───────────────────────────────────┤
       │getdate_r() │ Thread safety │ MT-Safe env locale                │
       ├──────────────────────────┼───────────────┼─────────────┤
       │getenv(), secure_getenv() │ Thread safety │ MT-Safe env │
       ├─────────────┼───────────────┼─────────────────────────────┤
       │endfsent(),  │ Thread safety │ MT-Unsafe race:fsent        │
       │setfsent()   │               │                             │
       ├─────────────┼───────────────┼─────────────────────────────┤
       │getfsent(),  │ Thread safety │ MT-Unsafe race:fsent locale │
       │getfsspec(), │               │                             │
       │getfsfile()  │               │                             │
       ├──────────────────────────┼───────────────┼─────────────────────┤
       │getgrent()  │ Thread safety │ MT-Unsafe race:grent        │
       │            │               │ race:grentbuf locale        │
       ├────────────┼───────────────┼─────────────────────────────┤
       │setgrent(), │ Thread safety │ MT-Unsafe race:grent locale │
       │endgrent()  │               │                             │
       ├──────────────────────────┼───────────────┼─────────────────────┤
       │getgrent_r()  │ Thread safety │ MT-Unsafe race:grent locale │
       ├──────────────┼───────────────┼─────────────────────────────┤
       │getgrnam()    │ Thread safety │ MT-Unsafe race:grnam locale │
       ├──────────────┼───────────────┼─────────────────────────────┤
       │getgrgid()    │ Thread safety │ MT-Unsafe race:grgid locale │
       ├──────────────┼───────────────┼─────────────────────────────┤
       │getgrnam_r(), │ Thread safety │ MT-Safe locale              │
       │getgrgid_r()  │               │                             │
       ├───────────────┼───────────────┼────────────────┤
       │getgrouplist() │ Thread safety │ MT-Safe locale │
       ├───────────────────┼───────────────┼───────────────────────────────┤
       │gethostbyname()    │ Thread safety │ MT-Unsafe race:hostbyname env │
       │                   │               │ locale                        │
       ├───────────────────┼───────────────┼───────────────────────────────┤
       │gethostbyaddr()    │ Thread safety │ MT-Unsafe race:hostbyaddr env │
       │                   │               │ locale                        │
       ├───────────────────┼───────────────┼───────────────────────────────┤
       │sethostent(),      │ Thread safety │ MT-Unsafe race:hostent env    │
       │endhostent(),      │               │ locale                        │
       │gethostent_r()     │               │                               │
       ├───────────────────┼───────────────┼───────────────────────────────┤
       │gethostent()       │ Thread safety │ MT-Unsafe race:hostent        │
       │                   │               │ race:hostentbuf env locale    │
       ├───────────────────┼───────────────┼───────────────────────────────┤
       │gethostbyname2()   │ Thread safety │ MT-Unsafe race:hostbyname2    │
       │                   │               │ env locale                    │
       ├───────────────────┼───────────────┼───────────────────────────────┤
       │gethostbyaddr_r(), │ Thread safety │ MT-Safe env locale            │
       │gethostbyname_r(), │               │                               │
       │gethostbyname2_r() │               │                               │
       ├──────────────────────────┼───────────────┼─────────────────────┤
       │gethostid() │ Thread safety │ MT-Safe hostid env locale │
       ├────────────┼───────────────┼───────────────────────────┤
       │sethostid() │ Thread safety │ MT-Unsafe const:hostid    │
       ├──────────────────────────┼───────────────┼─────────────────────┤
       │getlogin()   │ Thread safety │ MT-Unsafe race:getlogin race:utent    │
       │             │               │ sig:ALRM timer locale                 │
       ├─────────────┼───────────────┼───────────────────────────────────────┤
       │getlogin_r() │ Thread safety │ MT-Unsafe race:utent sig:ALRM timer   │
       │             │               │ locale                                │
       ├─────────────┼───────────────┼───────────────────────────────────────┤
       │cuserid()    │ Thread safety │ MT-Unsafe race:cuserid/!string locale │
       ├──────────────────────────┼───────────────┼─────────────────────┤
       │getmntent()   │ Thread safety │ MT-Unsafe race:mntentbuf locale │
       ├──────────────┼───────────────┼─────────────────────────────────┤
       │addmntent()   │ Thread safety │ MT-Safe race:stream locale      │
       ├──────────────┼───────────────┼─────────────────────────────────┤
       │getmntent_r() │ Thread safety │ MT-Safe locale                  │
       ├──────────────────────────┼───────────────┼─────────────────────┤
       │getnameinfo() │ Thread safety │ MT-Safe env locale │
       ├───────────────┼───────────────┼───────────────────────────┤
       │getnetent()    │ Thread safety │ MT-Unsafe race:netent     │
       │               │               │ race:netentbuf env locale │
       ├───────────────┼───────────────┼───────────────────────────┤
       │getnetbyname() │ Thread safety │ MT-Unsafe race:netbyname  │
       │               │               │ env locale                │
       ├───────────────┼───────────────┼───────────────────────────┤
       │getnetbyaddr() │ Thread safety │ MT-Unsafe race:netbyaddr  │
       │               │               │ locale                    │
       ├───────────────┼───────────────┼───────────────────────────┤
       │setnetent(),   │ Thread safety │ MT-Unsafe race:netent env │
       │endnetent()    │               │ locale                    │
       ├──────────────────┼───────────────┼────────────────┤
       │getnetent_r(),    │ Thread safety │ MT-Safe locale │
       │getnetbyname_r(), │               │                │
       │getnetbyaddr_r()  │               │                │
       ├─────────────────────────┼───────────────┼───────────────────────────┤
       │getopt(), getopt_long(), │ Thread safety │ MT-Unsafe race:getopt env │
       │getopt_long_only()       │               │                           │
       ├──────────┼───────────────┼────────────────┤
       │getpass() │ Thread safety │ MT-Unsafe term │
       ├───────────────────┼───────────────┼──────────────────────────────┤
       │getprotoent()      │ Thread safety │ MT-Unsafe race:protoent      │
       │                   │               │ race:protoentbuf locale      │
       ├───────────────────┼───────────────┼──────────────────────────────┤
       │getprotobyname()   │ Thread safety │ MT-Unsafe race:protobyname   │
       │                   │               │ locale                       │
       ├───────────────────┼───────────────┼──────────────────────────────┤
       │getprotobynumber() │ Thread safety │ MT-Unsafe race:protobynumber │
       │                   │               │ locale                       │
       ├───────────────────┼───────────────┼──────────────────────────────┤
       │setprotoent(),     │ Thread safety │ MT-Unsafe race:protoent      │
       │endprotoent()      │               │ locale                       │
       ├─────────────────────┼───────────────┼────────────────┤
       │getprotoent_r(),     │ Thread safety │ MT-Safe locale │
       │getprotobyname_r(),  │               │                │
       │getprotobynumber_r() │               │                │
       ├──────────┼───────────────┼────────────────┤
       │getpw()   │ Thread safety │ MT-Safe locale │
       ├────────────┼───────────────┼─────────────────────────────┤
       │getpwent()  │ Thread safety │ MT-Unsafe race:pwent        │
       │            │               │ race:pwentbuf locale        │
       ├────────────┼───────────────┼─────────────────────────────┤
       │setpwent(), │ Thread safety │ MT-Unsafe race:pwent locale │
       │endpwent()  │               │                             │
       ├──────────────┼───────────────┼─────────────────────────────┤
       │getpwent_r()  │ Thread safety │ MT-Unsafe race:pwent locale │
       ├──────────────┼───────────────┼─────────────────────────────┤
       │getpwnam()    │ Thread safety │ MT-Unsafe race:pwnam locale │
       ├──────────────┼───────────────┼─────────────────────────────┤
       │getpwuid()    │ Thread safety │ MT-Unsafe race:pwuid locale │
       ├──────────────┼───────────────┼─────────────────────────────┤
       │getpwnam_r(), │ Thread safety │ MT-Safe locale              │
       │getpwuid_r()  │               │                             │
       ├─────────────────────────────┼───────────────┼────────────────┤
       │getrpcent(), getrpcbyname(), │ Thread safety │ MT-Unsafe      │
       │getrpcbynumber()             │               │                │
       ├─────────────────────────────┼───────────────┼────────────────┤
       │setrpcent(), endrpcent()     │ Thread safety │ MT-Safe locale │
       ├────────────────────┼───────────────┼────────────────┤
       │getrpcent_r(),      │ Thread safety │ MT-Safe locale │
       │getrpcbyname_r(),   │               │                │
       │getrpcbynumber_r()  │               │                │
       ├─────────────┼───────────────┼────────────────────┤
       │getrpcport() │ Thread safety │ MT-Safe env locale │
       ├────────────────┼───────────────┼───────────────────────────┤
       │getservent()    │ Thread safety │ MT-Unsafe race:servent    │
       │                │               │ race:serventbuf locale    │
       ├────────────────┼───────────────┼───────────────────────────┤
       │getservbyname() │ Thread safety │ MT-Unsafe race:servbyname │
       │                │               │ locale                    │
       ├────────────────┼───────────────┼───────────────────────────┤
       │getservbyport() │ Thread safety │ MT-Unsafe race:servbyport │
       │                │               │ locale                    │
       ├────────────────┼───────────────┼───────────────────────────┤
       │setservent(),   │ Thread safety │ MT-Unsafe race:servent    │
       │endservent()    │               │ locale                    │
       ├───────────────────┼───────────────┼────────────────┤
       │getservent_r(),    │ Thread safety │ MT-Safe locale │
       │getservbyname_r(), │               │                │
       │getservbyport_r()  │               │                │
       ├──────────────┼───────────────┼────────────────────────────────┤
       │getspnam()    │ Thread safety │ MT-Unsafe race:getspnam locale │
       ├──────────────┼───────────────┼────────────────────────────────┤
       │getspent()    │ Thread safety │ MT-Unsafe race:getspent        │
       │              │               │ race:spentbuf locale           │
       ├──────────────┼───────────────┼────────────────────────────────┤
       │setspent(),   │ Thread safety │ MT-Unsafe race:getspent locale │
       │endspent(),   │               │                                │
       │getspent_r()  │               │                                │
       ├──────────────┼───────────────┼────────────────────────────────┤
       │fgetspent()   │ Thread safety │ MT-Unsafe race:fgetspent       │
       ├──────────────┼───────────────┼────────────────────────────────┤
       │sgetspent()   │ Thread safety │ MT-Unsafe race:sgetspent       │
       ├──────────────┼───────────────┼────────────────────────────────┤
       │putspent(),   │ Thread safety │ MT-Safe locale                 │
       │getspnam_r(), │               │                                │
       │sgetspent_r() │               │                                │
       ├──────────────┼───────────────┼────────────────────────────────┤
       │getttyent(), setttyent(), │ Thread safety │ MT-Unsafe race:ttyent │
       │endttyent(), getttynam()  │               │                       │
       ├────────────────────────────────┼───────────────┼───────────┤
       │getusershell(), setusershell(), │ Thread safety │ MT-Unsafe │
       │endusershell()                  │               │           │
       ├────────────┼───────────────┼──────────────────────────────┤
       │getutent()  │ Thread safety │ MT-Unsafe init race:utent    │
       │            │               │ race:utentbuf sig:ALRM timer │
       ├────────────┼───────────────┼──────────────────────────────┤
       │getutid(),  │ Thread safety │ MT-Unsafe init race:utent    │
       │getutline() │               │ sig:ALRM timer               │
       ├────────────┼───────────────┼──────────────────────────────┤
       │pututline() │ Thread safety │ MT-Unsafe race:utent         │
       │            │               │ sig:ALRM timer               │
       ├────────────┼───────────────┼──────────────────────────────┤
       │setutent(), │ Thread safety │ MT-Unsafe race:utent         │
       │endutent(), │               │                              │
       │utmpname()  │               │                              │
       ├───────────┼───────────────┼──────────────────────────┤
       │glob()     │ Thread safety │ MT-Unsafe race:utent env │
       │           │               │ sig:ALRM timer locale    │
       ├───────────┼───────────────┼──────────────────────────┤
       │grantpt() │ Thread safety │ MT-Safe locale │
       ├──────────┼───────────────┼─────────────────┤
       │ssignal() │ Thread safety │ MT-Safe sigintr │
       ├──────────────────────────┼───────────────┼────────────────────────┤
       │hcreate(), hsearch(),     │ Thread safety │ MT-Unsafe race:hsearch │
       │hdestroy()                │               │                        │
       ├──────────────────────────┼───────────────┼────────────────────────┤
       │hcreate_r(), hsearch_r(), │ Thread safety │ MT-Safe race:htab      │
       │hdestroy_r()              │               │                        │
       ├──────────┼───────────────┼─────────────────┤
       │iconv()   │ Thread safety │ MT-Safe race:cd │
       ├─────────────┼───────────────┼────────────────┤
       │iconv_open() │ Thread safety │ MT-Safe locale │
       ├───────────────────────────────┼───────────────┼────────────────┤
       │inet_aton(), inet_addr(),      │ Thread safety │ MT-Safe locale │
       │inet_network(), inet_ntoa()    │               │                │
       ├───────────────────────────────┼───────────────┼────────────────┤
       │inet_ntop() │ Thread safety │ MT-Safe locale │
       │inet_pton() │ Thread safety │ MT-Safe locale │
       ├─────────────┼───────────────┼────────────────┤
       │initgroups() │ Thread safety │ MT-Safe locale │
       ├───────────┼───────────────┼────────────────┤
       │iswalnum() │ Thread safety │ MT-Safe locale │
       ├───────────┼───────────────┼────────────────┤
       │iswalpha() │ Thread safety │ MT-Safe locale │
       ├───────────┼───────────────┼────────────────┤
       │iswblank() │ Thread safety │ MT-Safe locale │
       ├───────────┼───────────────┼────────────────┤
       │iswcntrl() │ Thread safety │ MT-Safe locale │
       ├───────────┼───────────────┼────────────────┤
       │iswdigit() │ Thread safety │ MT-Safe locale │
       ├───────────┼───────────────┼────────────────┤
       │iswgraph() │ Thread safety │ MT-Safe locale │
       ├───────────┼───────────────┼────────────────┤
       │iswlower() │ Thread safety │ MT-Safe locale │
       ├───────────┼───────────────┼────────────────┤
       │iswprint() │ Thread safety │ MT-Safe locale │
       ├───────────┼───────────────┼────────────────┤
       │iswpunct() │ Thread safety │ MT-Safe locale │
       ├──────────────────────────┼───────────────┼─────────────────────┤
       │iswspace() │ Thread safety │ MT-Safe locale │
       ├───────────┼───────────────┼────────────────┤
       │iswupper() │ Thread safety │ MT-Safe locale │
       ├────────────┼───────────────┼────────────────┤
       │iswxdigit() │ Thread safety │ MT-Safe locale │
       ├─────────────┼───────────────┼──────────────────────────────────┤
       │localeconv() │ Thread safety │ MT-Unsafe race:localeconv locale │
       ├──────────┼───────────────┼──────────────────────┤
       │login(),  │ Thread safety │ MT-Unsafe race:utent │
       │logout()  │               │ sig:ALRM timer       │
       ├──────────────┼───────────────┼────────────────────────────┤
       │makecontext() │ Thread safety │ MT-Safe race:ucp           │
       ├──────────────┼───────────────┼────────────────────────────┤
       │swapcontext() │ Thread safety │ MT-Safe race:oucp race:ucp │
       ├───────────┼───────────────┼──────────────────────────────┤
       │mallinfo() │ Thread safety │ MT-Unsafe init const:mallopt │
       ├──────────┼───────────────┼────────────────┤
       │mblen()   │ Thread safety │ MT-Unsafe race │
       ├──────────┼───────────────┼───────────────────────────┤
       │mbrlen()  │ Thread safety │ MT-Unsafe race:mbrlen/!ps │
       ├──────────┼───────────────┼────────────────────────────┤
       │mbrtowc() │ Thread safety │ MT-Unsafe race:mbrtowc/!ps │
       ├─────────────┼───────────────┼───────────────────────────────┤
       │mbsnrtowcs() │ Thread safety │ MT-Unsafe race:mbsnrtowcs/!ps │
       ├────────────┼───────────────┼──────────────────────────────┤
       │mbsrtowcs() │ Thread safety │ MT-Unsafe race:mbsrtowcs/!ps │
       ├──────────┼───────────────┼────────────────┤
       │mbtowc()  │ Thread safety │ MT-Unsafe race │
       ├─────────────────────────────┼───────────────┼───────────────────────┤
       │mcheck(), mcheck_pedantic(), │ Thread safety │ MT-Unsafe race:mcheck │
       │mcheck_check_all(), mprobe() │               │ const:malloc_hooks    │
       ├─────────────────────┼───────────────┼───────────┤
       │mtrace(), muntrace() │ Thread safety │ MT-Unsafe │
       ├──────────────┼───────────────┼────────────────┤
       │nl_langinfo() │ Thread safety │ MT-Safe locale │
       ├─────────────────────┼───────────────┼────────────────────────┤
       │forkpty(), openpty() │ Thread safety │ MT-Safe locale         │
       ├─────────────────────┼───────────────┼────────────────────────┤
       │login_tty()          │ Thread safety │ MT-Unsafe race:ttyname │
       ├──────────┼───────────────┼─────────────────────┤
       │perror()  │ Thread safety │ MT-Safe race:stderr │
       ├──────────────────┼───────────────┼─────────────────────────┤
       │posix_fallocate() │ Thread safety │ MT-Safe (but see NOTES) │
       ├─────────────────┼───────────────┼────────────────┤
       │valloc(),        │ Thread safety │ MT-Unsafe init │
       │pvalloc()        │               │                │
       ├────────────────────────┼───────────────┼────────────────┤
       │printf(), fprintf(),    │ Thread safety │ MT-Safe locale │
       │sprintf(), snprintf(),  │               │                │
       │vprintf(), vfprintf(),  │               │                │
       │vsprintf(), vsnprintf() │               │                │
       ├──────────┼───────────────┼───────────┤
       │profil()  │ Thread safety │ MT-Unsafe │
       ├──────────────────────┼───────────────┼────────────────┤
       │psignal(), psiginfo() │ Thread safety │ MT-Safe locale │
       ├────────────┼───────────────┼────────────────────────┤
       │ptsname()   │ Thread safety │ MT-Unsafe race:ptsname │
       ├──────────┼───────────────┼─────────────────────┤
       │putenv()  │ Thread safety │ MT-Unsafe const:env │
       ├───────────┼───────────────┼────────────────┤
       │putpwent() │ Thread safety │ MT-Safe locale │
       ├──────────┼───────────────┼──────────────────────┤
       │qecvt()   │ Thread safety │ MT-Unsafe race:qecvt │
       ├──────────┼───────────────┼──────────────────────┤
       │qfcvt()   │ Thread safety │ MT-Unsafe race:qfcvt │
       ├──────────┼───────────────┼──────────────────────┤
       │random_r(), srandom_r(),    │ Thread safety │ MT-Safe race:buf │
       │initstate_r(), setstate_r() │               │                  │
       ├────────────────────────────┼───────────────┼────────────────┤
       │rcmd(), rcmd_af()           │ Thread safety │ MT-Unsafe      │
       ├────────────────────────────┼───────────────┼────────────────┤
       │iruserok(), ruserok(),      │ Thread safety │ MT-Safe locale │
       │iruserok_af(), ruserok_af() │               │                │
       ├──────────┼───────────────┼──────────────────────────┤
       │readdir() │ Thread safety │ MT-Unsafe race:dirstream │
       ├─────────────────────┼───────────────┼───────────┤
       │re_comp(), re_exec() │ Thread safety │ MT-Unsafe │
       ├─────────────────────┼───────────────┼────────────────┤
       │regcomp(), regexec() │ Thread safety │ MT-Safe locale │
       ├─────────────────────┼───────────────┼────────────────┤
       │regerror()           │ Thread safety │ MT-Safe env    │
       ├───────────────────────────────────┼───────────────┼────────────────┤
       │res_ninit(),         res_nclose(), │ Thread safety │ MT-Safe locale │
       │res_nquery(),                      │               │                │
       │res_nsearch(), res_nquerydomain(), │               │                │
       │res_nsend()                        │               │                │
       ├────────────────────┼───────────────┼───────────┤
       │rexec(), rexec_af() │ Thread safety │ MT-Unsafe │
       ├──────────┼───────────────┼────────────────┤
       │rpmatch() │ Thread safety │ MT-Safe locale │
       ├──────────────────────────┼───────────────┼─────────────────────┤
       │alphasort(), versionsort() │ Thread safety │ MT-Safe locale │
       ├─────────────────────┼───────────────┼────────────────┤
       │scanf(), fscanf(),   │ Thread safety │ MT-Safe locale │
       │sscanf(), vscanf(),  │               │                │
       │vsscanf(), vfscanf() │               │                │
       ├────────────────────┼───────────────┼────────────────┤
       │setaliasent(), en‐  │ Thread safety │ MT-Safe locale │
       │daliasent(), getal‐ │               │                │
       │iasent_r(), getal‐  │               │                │
       │iasbyname_r()       │               │                │
       ├────────────────────┼───────────────┼────────────────┤
       │getaliasent(),      │ Thread safety │ MT-Unsafe      │
       │getaliasbyname()    │               │                │
       ├──────────────┼───────────────┼─────────────────────┤
       │setenv(), un‐ │ Thread safety │ MT-Unsafe const:env │
       │setenv()      │               │                     │
       ├────────────┼───────────────┼────────────────────────────┤
       │setlocale() │ Thread safety │ MT-Unsafe const:locale env │
       ├─────────────┼───────────────┼────────────────────────┤
       │setlogmask() │ Thread safety │ MT-Unsafe race:LogMask │
       ├─────────────────┼───────────────┼─────────────────────────┤
       │setnetgrent(),   │ Thread safety │ MT-Unsafe race:netgrent │
       │getnetgrent_r(), │               │ locale                  │
       │innetgr()        │               │                         │
       ├─────────────────┼───────────────┼─────────────────────────┤
       │endnetgrent()    │ Thread safety │ MT-Unsafe race:netgrent │
       ├─────────────────┼───────────────┼─────────────────────────┤
       │getnetgrent()    │ Thread safety │ MT-Unsafe race:netgrent │
       │                 │               │ race:netgrentbuf locale │
       ├─────────────────────────┼───────────────┼────────────────┤
       │shm_open(), shm_unlink() │ Thread safety │ MT-Safe locale │
       ├───────────────┼───────────────┼─────────────────────────┤
       │siginterrupt() │ Thread safety │ MT-Unsafe const:sigintr │
       ├──────────┼───────────────┼─────────────────────────────┤
       │sleep()   │ Thread safety │ MT-Unsafe sig:SIGCHLD/linux │
       ├──────────────────────┼───────────────┼─────────────────┤
       │va_arg()              │ Thread safety │ MT-Safe race:ap │
       ├─────────────────────────────┼───────────────┼─────────────────────┤
       │__fbufsize(), __fpending(),  │ Thread safety │ MT-Safe race:stream │
       │__fpurge(), __fsetlocking()  │               │                     │
       ├─────────────────────────────┼───────────────┼─────────────────────┤
       │strcasecmp(), strncasecmp() │ Thread safety │ MT-Safe locale │
       ├──────────┼───────────────┼────────────────┤
       │strcoll() │ Thread safety │ MT-Safe locale │
       ├──────────────────────────┼───────────────┼─────────────────────┤
       │strerror()         │ Thread safety │ MT-Unsafe race:strerror │
       ├────────────┼───────────────┼────────────────┤
       │strfmon()   │ Thread safety │ MT-Safe locale │
       ├────────────┼──────────────────────────────────┼────────────────┤
       │            │ Thread safety                    │ MT-Safe locale │
       │strfromd(), ├──────────────────────────────────┼────────────────┤
       │strfromf(), │ Asynchronous signal safety       │ AS-Unsafe heap │
       │strfroml()  ├──────────────────────────────────┼────────────────┤
       │            │ Asynchronous cancellation safety │ AC-Unsafe mem  │
       ├───────────┼───────────────┼────────────────────┤
       │strftime() │ Thread safety │ MT-Safe env locale │
       ├───────────┼───────────────┼────────────────────┤
       │strptime() │ Thread safety │ MT-Safe env locale │
       ├───────────────┼───────────────┼─────────────────────────────────┤
       │strsignal()    │ Thread safety │ MT-Unsafe race:strsignal locale │
       ├─────────────┼───────────────┼────────────────┤
       │strcasestr() │ Thread safety │ MT-Safe locale │
       ├──────────────────────────────┼───────────────┼────────────────┤
       │strtod(), strtof(), strtold() │ Thread safety │ MT-Safe locale │
       ├─────────────────────────┼───────────────┼────────────────┤
       │strtoimax(), strtoumax() │ Thread safety │ MT-Safe locale │
       ├───────────┼───────────────┼───────────────────────┤
       │strtok()   │ Thread safety │ MT-Unsafe race:strtok │
       ├──────────────────────────────┼───────────────┼────────────────┤
       │strtol(), strtoll(), strtoq() │ Thread safety │ MT-Safe locale │
       ├─────────────────────────────────┼───────────────┼────────────────┤
       │strtoul(), strtoull(), strtouq() │ Thread safety │ MT-Safe locale │
       ├──────────┼───────────────┼────────────────┤
       │strxfrm() │ Thread safety │ MT-Safe locale │
       ├──────────┼───────────────┼─────────────┤
       │sysconf() │ Thread safety │ MT-Safe env │
       ├──────────────────────┼───────────────┼────────────────────┤
       │syslog(), vsyslog()   │ Thread safety │ MT-Safe env locale │
       ├──────────┼───────────────┼─────────────┤
       │tempnam() │ Thread safety │ MT-Safe env │
       ├──────────────────────┼───────────────┼────────────────────┤
       │timelocal(), timegm() │ Thread safety │ MT-Safe env locale │
       ├───────────┼───────────────┼──────────────────────────┤
       │tmpnam()   │ Thread safety │ MT-Unsafe race:tmpnam/!s │
       ├─────────────┼───────────────┼────────────────┤
       │towlower()   │ Thread safety │ MT-Safe locale │
       ├─────────────┼───────────────┼────────────────┤
       │towupper()   │ Thread safety │ MT-Safe locale │
       ├────────────────────┼───────────────┼────────────────────┤
       │tsearch(), tfind(), │ Thread safety │ MT-Safe race:rootp │
       │tdelete()           │               │                    │
       ├────────────────────┼───────────────┼────────────────────┤
       │twalk()             │ Thread safety │ MT-Safe race:root  │
       ├────────────────────┼───────────────┼────────────────────┤
       │twalk_r()           │ Thread safety │ MT-Safe race:root  │
       ├────────────┼───────────────┼────────────────────────┤
       │ttyname()   │ Thread safety │ MT-Unsafe race:ttyname │
       ├──────────┼───────────────┼───────────┤
       │ttyslot() │ Thread safety │ MT-Unsafe │
       ├──────────┼───────────────┼────────────────────┤
       │tzset()   │ Thread safety │ MT-Safe env locale │
       ├─────────────────────┼───────────────┼───────────────────────┤
       │getc_unlocked(),     │ Thread safety │ MT-Safe race:stream   │
       │putc_unlocked(),     │               │                       │
       │clearerr_unlocked(), │               │                       │
       │fflush_unlocked(),   │               │                       │
       │fgetc_unlocked(),    │               │                       │
       │fputc_unlocked(),    │               │                       │
       │fread_unlocked(),    │               │                       │
       │fwrite_unlocked(),   │               │                       │
       │fgets_unlocked(),    │               │                       │
       │fputs_unlocked(),    │               │                       │
       │getwc_unlocked(),    │               │                       │
       │fgetwc_unlocked(),   │               │                       │
       │fputwc_unlocked(),   │               │                       │
       │putwc_unlocked(),    │               │                       │
       │fgetws_unlocked(),   │               │                       │
       │fputws_unlocked()    │               │                       │
       ├─────────────────────┼───────────────┼───────────────────────┤
       │getchar_unlocked(),  │ Thread safety │ MT-Unsafe race:stdin  │
       │getwchar_unlocked()  │               │                       │
       ├─────────────────────┼───────────────┼───────────────────────┤
       │putchar_unlocked(),  │ Thread safety │ MT-Unsafe race:stdout │
       │putwchar_unlocked()  │               │                       │
       ├───────────┼───────────────┼──────────────────────────┤
       │updwtmp(), │ Thread safety │ MT-Unsafe sig:ALRM timer │
       │logwtmp()  │               │                          │
       ├──────────┼───────────────┼────────────────────────────┤
       │wcrtomb() │ Thread safety │ MT-Unsafe race:wcrtomb/!ps │
       ├─────────────┼───────────────┼────────────────┤
       │wcscasecmp() │ Thread safety │ MT-Safe locale │
       ├──────────────┼───────────────┼────────────────┤
       │wcsncasecmp() │ Thread safety │ MT-Safe locale │
       ├─────────────┼───────────────┼───────────────────────────────┤
       │wcsnrtombs() │ Thread safety │ MT-Unsafe race:wcsnrtombs/!ps │
       ├────────────┼───────────────┼──────────────────────────────┤
       │wcsrtombs() │ Thread safety │ MT-Unsafe race:wcsrtombs/!ps │
       ├─────────────────────────┼───────────────┼────────────────┤
       │wcstoimax(), wcstoumax() │ Thread safety │ MT-Safe locale │
       ├───────────┼───────────────┼────────────────┤
       │wcswidth() │ Thread safety │ MT-Safe locale │
       ├──────────┼───────────────┼────────────────┤
       │wctomb()  │ Thread safety │ MT-Unsafe race │
       ├──────────┼───────────────┼────────────────┤
       │wctrans() │ Thread safety │ MT-Safe locale │
       ├──────────┼───────────────┼────────────────┤
       │wctype()  │ Thread safety │ MT-Safe locale │
       ├──────────┼───────────────┼────────────────┤
       │wcwidth() │ Thread safety │ MT-Safe locale │
       ├───────────┼───────────────┼────────────────────────────────┤
       │wordexp()  │ Thread safety │ MT-Unsafe race:utent const:env │
       │           │               │ env sig:ALRM timer locale      │
       ├─────────────────────────┼───────────────┼────────────────┤
       │wprintf(), fwprintf(),   │ Thread safety │ MT-Safe locale │
       │swprintf(), vwprintf(),  │               │                │
       │vfwprintf(), vswprintf() │               │                │
       └─────────────────────────┴───────────────┴────────────────┘
