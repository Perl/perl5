
# Time-stamp: "2001-05-27 19:53:11 MDT"
# Sean M. Burke <sburke@cpan.org>

require 5.000;
package I18N::LangTags;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION); # $Debug
require Exporter;
# $Debug = 0;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(is_language_tag same_language_tag
                extract_language_tags super_languages
                similarity_language_tag is_dialect_of
                locale2language_tag alternate_language_tags
                encode_language_tag
               );

$VERSION = "0.22";

=head1 NAME

I18N::LangTags - functions for dealing with RFC3066-style language tags

=head1 SYNOPSIS

    use I18N::LangTags qw(is_language_tag same_language_tag
                          extract_language_tags super_languages
                          similarity_language_tag is_dialect_of
                          locale2language_tag alternate_language_tags
                          encode_language_tag
                         );

...or whatever of those functions you want to import.  Those are
all the exportable functions -- you're free to import only some,
or none at all.  By default, none are imported.

If you don't import any of these functions, assume a C<&I18N::LangTags::>
in front of all the function names in the following examples.

=head1 DESCRIPTION

Language tags are a formalism, described in RFC 3066 (obsoleting
1766), for declaring what language form (language and possibly
dialect) a given chunk of information is in.

This library provides functions for common tasks involving language
tags as they are needed in a variety of protocols and applications.

Please see the "See Also" references for a thorough explanation
of how to correctly use language tags.

=over

=cut

###########################################################################

=item * the function is_language_tag($lang1)

Returns true iff $lang1 is a formally valid language tag.

   is_language_tag("fr")            is TRUE
   is_language_tag("x-jicarilla")   is FALSE
       (Subtags can be 8 chars long at most -- 'jicarilla' is 9)

   is_language_tag("sgn-US")    is TRUE
       (That's American Sign Language)

   is_language_tag("i-Klikitat")    is TRUE
       (True without regard to the fact noone has actually
        registered Klikitat -- it's a formally valid tag)

   is_language_tag("fr-patois")     is TRUE
       (Formally valid -- altho descriptively weak!)

   is_language_tag("Spanish")       is FALSE
   is_language_tag("french-patois") is FALSE
       (No good -- first subtag has to match
        /^([xXiI]|[a-zA-Z]{2,3})$/ -- see RFC3066)

   is_language_tag("x-borg-prot2532") is TRUE
       (Yes, subtags can contain digits, as of RFC3066)

=cut

sub is_language_tag {

  ## Changes in the language tagging standards may have to be reflected here.

  my($tag) = lc($_[0]);

  return 0 if $tag eq "i" or $tag eq "x";
  # Bad degenerate cases the following
  #  regexp would erroneously let pass

  return $tag =~ 
    /^(?:  # First subtag
         [xi] | [a-z]{2,3}
      )
      (?:  # Subtags thereafter
         -           # separator
         [a-z0-9]{1,8}  # subtag  
      )*
    $/xs ? 1 : 0;
}

###########################################################################

=item * the function extract_language_tags($whatever)

Returns a list of whatever looks like formally valid language tags
in $whatever.  Not very smart, so don't get too creative with
what you want to feed it.

  extract_language_tags("fr, fr-ca, i-mingo")
    returns:   ('fr', 'fr-ca', 'i-mingo')

  extract_language_tags("It's like this: I'm in fr -- French!")
    returns:   ('It', 'in', 'fr')
  (So don't just feed it any old thing.)

The output is untainted.  If you don't know what tainting is,
don't worry about it.

=cut

sub extract_language_tags {

  ## Changes in the language tagging standards may have to be reflected here.

  my($text) =
    $_[0] =~ m/(.+)/  # to make for an untainted result
    ? $1 : ''
  ;
  
  return grep(!m/^[ixIX]$/s, # 'i' and 'x' aren't good tags
    $text =~ 
    m/
      \b
      (?:  # First subtag
         [iIxX] | [a-zA-Z]{2,3}
      )
      (?:  # Subtags thereafter
         -           # separator
         [a-zA-Z0-9]{1,8}  # subtag  
      )*
      \b
    /xsg
  );
}

###########################################################################

=item * the function same_language_tag($lang1, $lang2)

Returns true iff $lang1 and $lang2 are acceptable variant tags
representing the same language-form.

   same_language_tag('x-kadara', 'i-kadara')  is TRUE
      (The x/i- alternation doesn't matter)
   same_language_tag('X-KADARA', 'i-kadara')  is TRUE
      (...and neither does case)
   same_language_tag('en',       'en-US')     is FALSE
      (all-English is not the SAME as US English)
   same_language_tag('x-kadara', 'x-kadar')   is FALSE
      (these are totally unrelated tags)

C<same_language_tag> works by just seeing whether
C<encode_language_tag($lang1)> is the same as
C<encode_language_tag($lang2)>.

(Yes, I know this function is named a bit oddly.  Call it historic
reasons.)

=cut

sub same_language_tag {
  my $el1 = &encode_language_tag($_[0]);
  return 0 unless defined $el1;
   # this avoids the problem of
   # encode_language_tag($lang1) eq and encode_language_tag($lang2)
   # being true if $lang1 and $lang2 are both undef

  return $el1 eq &encode_language_tag($_[1]) ? 1 : 0;
}

###########################################################################

=item * the function similarity_language_tag($lang1, $lang2)

Returns an integer representing the degree of similarity between
tags $lang1 and $lang2 (the order of which does not matter), where
similarity is the number of common elements on the left,
without regard to case and to x/i- alternation.

   similarity_language_tag('fr', 'fr-ca')           is 1
      (one element in common)
   similarity_language_tag('fr-ca', 'fr-FR')        is 1
      (one element in common)

   similarity_language_tag('fr-CA-joual',
                           'fr-CA-PEI')             is 2
   similarity_language_tag('fr-CA-joual', 'fr-CA')  is 2
      (two elements in common)

   similarity_language_tag('x-kadara', 'i-kadara')  is 1
      (x/i- doesn't matter)

   similarity_language_tag('en',       'x-kadar')   is 0
   similarity_language_tag('x-kadara', 'x-kadar')   is 0
      (unrelated tags -- no similarity)

   similarity_language_tag('i-cree-syllabic',
                           'i-cherokee-syllabic')   is 0
      (no B<leftmost> elements in common!)

=cut

sub similarity_language_tag {
  my $lang1 = &encode_language_tag($_[0]);
  my $lang2 = &encode_language_tag($_[1]);

  # NB: (i-sil-...)?  (i-sgn-...)?

  return undef if !defined($lang1) and !defined($lang2);
  return 0 if !defined($lang1) or !defined($lang2);

  my @l1_subtags = split('-', $lang1);
  my @l2_subtags = split('-', $lang2);
  my $similarity = 0;

  while(@l1_subtags and @l2_subtags) {
    if(shift(@l1_subtags) eq shift(@l2_subtags)) {
      ++$similarity;
    } else {
      last;
    } 
  }
  return $similarity;
}

###########################################################################

=item * the function is_dialect_of($lang1, $lang2)

Returns true iff language tag $lang1 represents a subdialect of
language tag $lang2.

B<Get the order right!  It doesn't work the other way around!>

   is_dialect_of('en-US', 'en')            is TRUE
     (American English IS a dialect of all-English)

   is_dialect_of('fr-CA-joual', 'fr-CA')   is TRUE
   is_dialect_of('fr-CA-joual', 'fr')      is TRUE
     (Joual is a dialect of (a dialect of) French)

   is_dialect_of('en', 'en-US')            is FALSE
     (all-English is a NOT dialect of American English)

   is_dialect_of('fr', 'en-CA')            is FALSE

   is_dialect_of('en',    'en'   )            is TRUE
   is_dialect_of('en-US', 'en-US')            is TRUE
     (B<Note:> these are degenerate cases)

   is_dialect_of('i-mingo-tom', 'x-Mingo') is TRUE
     (the x/i thing doesn't matter, nor does case)

=cut

sub is_dialect_of {

  my $lang1 = &encode_language_tag($_[0]);
  my $lang2 = &encode_language_tag($_[1]);

  return undef if !defined($lang1) and !defined($lang2);
  return 0 if !defined($lang1) or !defined($lang2);

  return 1 if $lang1 eq $lang2;
  return 0 if length($lang1) < length($lang2);

  $lang1 .= '-';
  $lang2 .= '-';
  return
    (substr($lang1, 0, length($lang2)) eq $lang2) ? 1 : 0;
}

###########################################################################

=item * the function super_languages($lang1)

Returns a list of language tags that are superordinate tags to $lang1
-- it gets this by removing subtags from the end of $lang1 until
nothing (or just "i" or "x") is left.

   super_languages("fr-CA-joual")  is  ("fr-CA", "fr")

   super_languages("en-AU")  is  ("en")

   super_languages("en")  is  empty-list, ()

   super_languages("i-cherokee")  is  empty-list, ()
    ...not ("i"), which would be illegal as well as pointless.

If $lang1 is not a valid language tag, returns empty-list in
a list context, undef in a scalar context.

A notable and rather unavoidable problem with this method:
"x-mingo-tom" has an "x" because the whole tag isn't an
IANA-registered tag -- but super_languages('x-mingo-tom') is
('x-mingo') -- which isn't really right, since 'i-mingo' is
registered.  But this module has no way of knowing that.  (But note
that same_language_tag('x-mingo', 'i-mingo') is TRUE.)

More importantly, you assume I<at your peril> that superordinates of
$lang1 are mutually intelligible with $lang1.  Consider this
carefully.

=cut 

sub super_languages {
  my $lang1 = $_[0];
  return() unless defined($lang1) && &is_language_tag($lang1);
  my @l1_subtags = split('-', $lang1);

  ## Changes in the language tagging standards may have to be reflected here.

  # NB: (i-sil-...)?

  my @supers = ();
  foreach my $bit (@l1_subtags) {
    push @supers, 
      scalar(@supers) ? ($supers[-1] . '-' . $bit) : $bit;
  }
  pop @supers if @supers;
  shift @supers if @supers && $supers[0] =~ m<^[iIxX]$>s;
  return reverse @supers;
}

###########################################################################

=item * the function locale2language_tag($locale_identifier)

This takes a locale name (like "en", "en_US", or "en_US.ISO8859-1")
and maps it to a language tag.  If it's not mappable (as with,
notably, "C" and "POSIX"), this returns empty-list in a list context,
or undef in a scalar context.

   locale2language_tag("en") is "en"

   locale2language_tag("en_US") is "en-US"

   locale2language_tag("en_US.ISO8859-1") is "en-US"

   locale2language_tag("C") is undef or ()

   locale2language_tag("POSIX") is undef or ()

   locale2language_tag("POSIX") is undef or ()

I'm not totally sure that locale names map satisfactorily to language
tags.  Think REAL hard about how you use this.  YOU HAVE BEEN WARNED.

The output is untainted.  If you don't know what tainting is,
don't worry about it.

=cut 

sub locale2language_tag {
  my $lang =
    $_[0] =~ m/(.+)/  # to make for an untainted result
    ? $1 : ''
  ;

  return $lang if &is_language_tag($lang); # like "en"

  $lang =~ tr<_><->;  # "en_US" -> en-US
  $lang =~ s<\.[-_a-zA-Z0-9\.]*><>s;  # "en_US.ISO8859-1" -> en-US

  return $lang if &is_language_tag($lang);

  return;
}

###########################################################################

=item * the function encode_language_tag($lang1)

This function, if given a language tag, returns an encoding of it such
that:

* tags representing different languages never get the same encoding.

* tags representing the same language always get the same encoding.

* an encoding of a formally valid language tag always is a string
value that is defined, has length, and is true if considered as a
boolean.

Note that the encoding itself is B<not> a formally valid language tag.
Note also that you cannot, currently, go from an encoding back to a
language tag that it's an encoding of.

Note also that you B<must> consider the encoded value as atomic; i.e.,
you should not consider it as anything but an opaque, unanalysable
string value.  (The internals of the encoding method may change in
future versions, as the language tagging standard changes over time.)

C<encode_language_tag> returns undef if given anything other than a
formally valid language tag.

The reason C<encode_language_tag> exists is because different language
tags may represent the same language; this is normally treatable with
C<same_language_tag>, but consider this situation:

You have a data file that expresses greetings in different languages.
Its format is "[language tag]=[how to say 'Hello']", like:

          en-US=Hiho
          fr=Bonjour
          i-mingo=Hau'

And suppose you write a program that reads that file and then runs as
a daemon, answering client requests that specify a language tag and
then expect the string that says how to greet in that language.  So an
interaction looks like:

          greeting-client asks:    fr
          greeting-server answers: Bonjour

So far so good.  But suppose the way you're implementing this is:

          my %greetings;
          die unless open(IN, "<in.dat");
          while(<IN>) {
            chomp;
            next unless /^([^=]+)=(.+)/s;
            my($lang, $expr) = ($1, $2);
            $greetings{$lang} = $expr;
          }
          close(IN);

at which point %greetings has the contents:

          "en-US"   => "Hiho"
          "fr"      => "Bonjour"
          "i-mingo" => "Hau'"

And suppose then that you answer client requests for language $wanted
by just looking up $greetings{$wanted}.

If the client asks for "fr", that will look up successfully in
%greetings, to the value "Bonjour".  And if the client asks for
"i-mingo", that will look up successfully in %greetings, to the value
"Hau'".

But if the client asks for "i-Mingo" or "x-mingo", or "Fr", then the
lookup in %greetings fails.  That's the Wrong Thing.

You could instead do lookups on $wanted with:

          use I18N::LangTags qw(same_language_tag);
          my $repsonse = '';
          foreach my $l2 (keys %greetings) {
            if(same_language_tag($wanted, $l2)) {
              $response = $greetings{$l2};
              last;
            }
          }

But that's rather inefficient.  A better way to do it is to start your
program with:

          use I18N::LangTags qw(encode_language_tag);
          my %greetings;
          die unless open(IN, "<in.dat");
          while(<IN>) {
            chomp;
            next unless /^([^=]+)=(.+)/s;
            my($lang, $expr) = ($1, $2);
            $greetings{
                        encode_language_tag($lang)
                      } = $expr;
          }
          close(IN);

and then just answer client requests for language $wanted by just
looking up

          $greetings{encode_language_tag($wanted)}

And that does the Right Thing.

=cut

sub encode_language_tag {
  # Only similarity_language_tag() is allowed to analyse encodings!

  ## Changes in the language tagging standards may have to be reflected here.

  my($tag) = uc($_[0]); # smash case
  return undef unless &is_language_tag($tag);
   # If it's not a language tag, its encoding is undef

  $tag =~ s/^[xiXI]-//s;
   # Just lop off any leading "x/i-"
   # Or I suppose I could do s/^[xiXI]-/_/s or something.

  return "~$tag";
}

#--------------------------------------------------------------------------

=item * the function alternate_language_tags($lang1)

This function, if given a language tag, returns all language tags that
are alternate forms of this language tag.  (There is little
alternation in the C<current> language tagging formalism, but
extensions to the formalism are under consideration which could add a
great deal of alternation.)

Examples from the current formalism:

          alternate_language_tags('en')           is   ()
          alternate_language_tags('x-mingo-tom')  is   ('i-mingo-tom')
          alternate_language_tags('x-klikitat')   is   ('i-klikitat')
          alternate_language_tags('i-klikitat')   is   ('x-klikitat')

This function returns undef if given anything other than a formally
valid language tag.

=cut

my %alt = qw( i x   x i   I X   X I );
sub alternate_language_tags {
  ## Changes in the language tagging standards may have to be reflected here.
  my $tag = $_[0];
  return() unless &is_language_tag($tag);

 # might as well preserve case

  if($tag =~ /^([XIxi])(-.+)/) {
    # This handles all the alternation that exists CURRENTLY
    return($alt{$1} . $2);
  }
  return();
}

###########################################################################

=back

=head1 ABOUT LOWERCASING

I've considered making all the above functions that output language
tags return all those tags strictly in lowercase.  Having all your
language tags in lowercase does make some things easier.  But you
might as well just lowercase as you like, or call
C<encode_language_tag($lang1)> where appropriate.

=head1 ABOUT UNICODE PLAINTEXT LANGUAGE TAGS

In some future version of I18N::LangTags, I plan to include support
for RFC2482-style language tags -- which are basically just normal
language tags with their ASCII characters shifted into Plane 14.

=head1 SEE ALSO

* L<I18N::LangTags::List|I18N::LangTags::List>

* RFC 3066, C<ftp://ftp.isi.edu/in-notes/rfc3066.txt>, "Tags for the
Identification of Languages".  (Obsoletes RFC 1766)

* RFC 2277, C<ftp://ftp.isi.edu/in-notes/rfc2277.txt>, "IETF Policy on
Character Sets and Languages".

* RFC 2231, C<ftp://ftp.isi.edu/in-notes/rfc2231.txt>, "MIME Parameter
Value and Encoded Word Extensions: Character Sets, Languages, and
Continuations".

* RFC 2482, C<ftp://ftp.isi.edu/in-notes/rfc2482.txt>, 
"Language Tagging in Unicode Plain Text".

* Locale::Codes, in
C<http://www.perl.com/CPAN/modules/by-module/Locale/>

* ISO 639, "Code for the representation of names of languages",
C<http://www.indigo.ie/egt/standards/iso639/iso639-1-en.html>

* ISO 639-2, "Codes for the representation of names of languages",
including three-letter codes,
C<http://lcweb.loc.gov/standards/iso639-2/bibcodes.html>

* The IANA list of registered languages (hopefully up-to-date),
C<ftp://ftp.isi.edu/in-notes/iana/assignments/languages/>

=head1 COPYRIGHT

Copyright (c) 1998-2001 Sean M. Burke. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

The programs and documentation in this dist are distributed in
the hope that they will be useful, but without any warranty; without
even the implied warranty of merchantability or fitness for a
particular purpose.

=head1 AUTHOR

Sean M. Burke C<sburke@cpan.org>

=cut

1;

__END__
