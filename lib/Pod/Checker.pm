#############################################################################
# Pod/Checker.pm -- check pod documents for syntax errors
#
# Based on Tom Christiansen's Pod::Text::pod2text() function
# (with modifications).
#
# Copyright (C) 1994-1999 Tom Christiansen. All rights reserved.
# This file is part of "PodParser". PodParser is free software;
# you can redistribute it and/or modify it under the same terms
# as Perl itself.
#############################################################################

package Pod::Checker;

use vars qw($VERSION);
$VERSION = 1.081;  ## Current version of this package
require  5.004;    ## requires this Perl version or later

=head1 NAME

Pod::Checker, podchecker() - check pod documents for syntax errors

=head1 SYNOPSIS

  use Pod::Checker;

  $syntax_okay = podchecker($filepath, $outputpath);

=head1 OPTIONS/ARGUMENTS

C<$filepath> is the input POD to read and C<$outputpath> is
where to write POD syntax error messages. Either argument may be a scalar
indcating a file-path, or else a reference to an open filehandle.
If unspecified, the input-file it defaults to C<\*STDIN>, and
the output-file defaults to C<\*STDERR>.


=head1 DESCRIPTION

B<podchecker> will perform syntax checking of Perl5 POD format documentation.

I<NOTE THAT THIS MODULE IS CURRENTLY IN THE INITIAL DEVELOPMENT STAGE!>
As of this writing, all it does is check for unknown '=xxxx' commands,
unknown 'X<...>' interior-sequences, and unterminated interior sequences.

It is hoped that curious/ambitious user will help flesh out and add the
additional features they wish to see in B<Pod::Checker> and B<podchecker>.

=head1 EXAMPLES

I<[T.B.D.]>

=head1 AUTHOR

Brad Appleton E<lt>bradapp@enteract.comE<gt> (initial version)

Based on code for B<Pod::Text::pod2text()> written by
Tom Christiansen E<lt>tchrist@mox.perl.comE<gt>

=cut

#############################################################################

use strict;
#use diagnostics;
use Carp;
use Exporter;
use Pod::Parser;

use vars qw(@ISA @EXPORT);
@ISA = qw(Pod::Parser);
@EXPORT = qw(&podchecker);

use vars qw(%VALID_COMMANDS %VALID_SEQUENCES);

my %VALID_COMMANDS = (
    'pod'    =>  1,
    'cut'    =>  1,
    'head1'  =>  1,
    'head2'  =>  1,
    'over'   =>  1,
    'back'   =>  1,
    'item'   =>  1,
    'for'    =>  1,
    'begin'  =>  1,
    'end'    =>  1,
);

my %VALID_SEQUENCES = (
    'I'  =>  1,
    'B'  =>  1,
    'S'  =>  1,
    'C'  =>  1,
    'L'  =>  1,
    'F'  =>  1,
    'X'  =>  1,
    'Z'  =>  1,
    'E'  =>  1,
);

##---------------------------------------------------------------------------

##---------------------------------
## Function definitions begin here
##---------------------------------

sub podchecker( $ ; $ ) {
    my ($infile, $outfile) = @_;
    local $_;

    ## Set defaults
    $infile  ||= \*STDIN;
    $outfile ||= \*STDERR;

    ## Now create a pod checker
    my $checker = new Pod::Checker();

    ## Now check the pod document for errors
    $checker->parse_from_file($infile, $outfile);
    
    ## Return the number of errors found
    return $checker->num_errors();
}

##---------------------------------------------------------------------------

##-------------------------------
## Method definitions begin here
##-------------------------------

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %params = @_;
    my $self = {%params};
    bless $self, $class;
    $self->initialize();
    return $self;
}

sub initialize {
    my $self = shift;
    $self->num_errors(0);
}

sub num_errors {
   return (@_ > 1) ? ($_[0]->{_NUM_ERRORS} = $_[1]) : $_[0]->{_NUM_ERRORS};
}

sub end_pod {
   ## Print the number of errors found
   my $self   = shift;
   my $infile = $self->input_file();
   my $out_fh = $self->output_handle();

   my $num_errors = $self->num_errors();
   if ($num_errors > 0) {
      printf $out_fh ("$infile has $num_errors pod syntax %s.\n",
                      ($num_errors == 1) ? "error" : "errors");
   }
   else {
      print $out_fh "$infile pod syntax OK.\n";
   }
}

sub command { 
    my ($self, $command, $paragraph, $line_num, $pod_para) = @_;
    my ($file, $line) = $pod_para->file_line;
    my $out_fh  = $self->output_handle();
    ## Check the command syntax
    if (! $VALID_COMMANDS{$command}) {
       ++($self->{_NUM_ERRORS});
       _invalid_cmd($out_fh, $command, $paragraph, $file, $line);
    }
    else {
       ## check syntax of particular command
    }
    ## Check the interior sequences in the command-text
    my $expansion = $self->interpolate($paragraph, $line_num);
}

sub verbatim { 
    ## Nothing to check
    ## my ($self, $paragraph, $line_num, $pod_para) = @_;
}

sub textblock { 
    my ($self, $paragraph, $line_num, $pod_para) = @_;
    my $out_fh  = $self->output_handle();
    ## Check the interior sequences in the text (set $SIG{__WARN__} to
    ## send parse_text warnings about untermnated sequences to $out_fh)
    local  $SIG{__WARN__} = sub {
                                ++($self->{_NUM_ERRORS});
                                print $out_fh @_
                            };
    my $expansion = $self->interpolate($paragraph, $line_num);
}

sub interior_sequence { 
    my ($self, $seq_cmd, $seq_arg, $pod_seq) = @_;
    my ($file, $line) = $pod_seq->file_line;
    my $out_fh  = $self->output_handle();
    ## Check the sequence syntax
    if (! $VALID_SEQUENCES{$seq_cmd}) {
       ++($self->{_NUM_ERRORS});
       _invalid_seq($out_fh, $seq_cmd, $seq_arg, $file, $line);
    }
    else {
       ## check syntax of the particular sequence
    }
}

sub _invalid_cmd {
    my ($fh, $cmd, $text, $file, $line) = @_;
    print $fh "*** ERROR: Unknown command \"$cmd\""
            . " at line $line of file $file\n";
}

sub _invalid_seq {
    my ($fh, $cmd, $text, $file, $line) = @_;
    print $fh "*** ERROR: Unknown interior-sequence \"$cmd\""
            . " at line $line of file $file\n";
}

