#############################################################################
# Pod/Checker.pm -- check pod documents for syntax errors
#
# Copyright (C) 1994-1999 by Bradford Appleton. All rights reserved.
# This file is part of "PodParser". PodParser is free software;
# you can redistribute it and/or modify it under the same terms
# as Perl itself.
#############################################################################

package Pod::Checker;

use vars qw($VERSION);
$VERSION = 1.085;  ## Current version of this package
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
    ## Initialize number of errors, and setup an error function to
    ## increment this number and then print to the designated output.
    $self->{_NUM_ERRORS} = 0;
    $self->errorsub('poderror');
}

## Invoked as $self->poderror( @args ), or $self->poderror( {%opts}, @args )
sub poderror {
    my $self = shift;
    my %opts = (ref $_[0]) ? %{shift()} : ();

    ## Retrieve options
    chomp( my $msg  = ($opts{-msg} || "")."@_" );
    my $line = (exists $opts{-line}) ? " at line $opts{-line}" : "";
    my $file = (exists $opts{-file}) ? " in file $opts{-file}" : "";
    my $severity = (exists $opts{-severity}) ? "*** $opts{-severity}: " : "";

    ## Increment error count and print message
    ++($self->{_NUM_ERRORS});
    my $out_fh = $self->output_handle();
    print $out_fh ($severity, $msg, $line, $file, "\n");
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
    my ($self, $cmd, $paragraph, $line_num, $pod_para) = @_;
    my ($file, $line) = $pod_para->file_line;
    ## Check the command syntax
    if (! $VALID_COMMANDS{$cmd}) {
       $self->poderror({ -line => $line, -file => $file, -severity => 'ERROR',
                         -msg => "Unknown command \"$cmd\"" });
    }
    else {
       ## check syntax of particular command
    }
    my $expansion = $self->interpolate($paragraph, $line_num);
}

sub verbatim { 
    ## Nothing to check
    ## my ($self, $paragraph, $line_num, $pod_para) = @_;
}

sub textblock { 
    my ($self, $paragraph, $line_num, $pod_para) = @_;
    my $expansion = $self->interpolate($paragraph, $line_num);
}

sub interior_sequence { 
    my ($self, $seq_cmd, $seq_arg, $pod_seq) = @_;
    my ($file, $line) = $pod_seq->file_line;
    ## Check the sequence syntax
    if (! $VALID_SEQUENCES{$seq_cmd}) {
       $self->poderror({ -line => $line, -file => $file, -severity => 'ERROR',
                         -msg => "Unknown interior-sequence \"$seq_cmd\"" });
    }
    else {
       ## check syntax of the particular sequence
    }
}

