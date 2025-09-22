package SelectSaver 1.03;

use v5.40;

use Symbol 'qualify';

sub new ($class, $filehandle = undef) {
    my $fh = select;
    select qualify $filehandle, caller if defined $filehandle;
    return bless \$fh, $class;
}

sub DESTROY ($self) { select $$self }

__END__

=head1 NAME

SelectSaver - save and restore selected file handle

=head1 SYNOPSIS

    use SelectSaver;

    {
       my $saver = SelectSaver->new(FILEHANDLE);
       # FILEHANDLE is selected
    }
    # previous handle is selected

    {
       my $saver = SelectSaver->new;
       # new handle may be selected, or not
    }
    # previous handle is selected

=head1 DESCRIPTION

A C<SelectSaver> object contains a reference to the file handle that
was selected when it was created.  If its C<new> method gets an extra
parameter, then that parameter is selected; otherwise, the selected
file handle remains unchanged.

When a C<SelectSaver> is destroyed, it re-selects the file handle
that was selected when it was created.
