####################################################################
package MLDBM::Serializer::Data::Dumper;
BEGIN { @MLDBM::Serializer::Data::Dumper::ISA = qw(MLDBM::Serializer) }

use Data::Dumper '2.08';		# Backward compatibility
use Carp;

#
# Create a Data::Dumper serializer object.
#
sub new {
    my $self = shift->SUPER::new();
    my $meth = shift || "";
    $meth = (defined(&Data::Dumper::Dumpxs) ? 'Dumpxs' : 'Dump')
      unless $meth =~ /^Dump(xs)?$/;
    $self->DumpMeth($meth);
    $self->RemoveTaint(shift);
    $self->Key(shift);
    $self;
}

#
# Serialize $val if it is a reference, or if it does begin with our magic
# key string, since then at retrieval time we expect a Data::Dumper string.
# Otherwise, return the scalar value.
#
sub serialize {
    my $self = shift;
    my ($val) = @_;
    return undef unless defined $val;
    return $val unless ref($val) or $val =~ m|^\Q$self->{'key'}|o;
    my $dumpmeth = $self->{'dumpmeth'};
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Purity = 1;
    local $Data::Dumper::Terse = 1;
    return $self->{'key'} . Data::Dumper->$dumpmeth([$val], ['M']);
}

#
# If the value is undefined or does not begin with our magic key string,
# return it as-is. Otherwise, we need to recover the underlying data structure.
#
sub deserialize {
    my $self = shift;
    my ($val) = @_;
    return undef unless defined $val;
    return $val unless $val =~ s|^\Q$self->{'key'}||o;
    my $M = "";
    ($val) = $val =~ /^(.*)$/s if $self->{'removetaint'};
    # Disambiguate hashref (perl may treat it as a block)
    my $N = eval($val =~ /^\{/ ? '+'.$val : $val);
    return $M ? $M : $N unless $@;
    carp "MLDBM error: $@\twhile evaluating:\n $val";
}

sub DumpMeth	{ my $s = shift; $s->_attrib('dumpmeth', @_); }
sub RemoveTaint	{ my $s = shift; $s->_attrib('removetaint', @_); }
sub Key		{ my $s = shift; $s->_attrib('key', @_); }

# avoid used only once warnings
{
    local $Data::Dumper::Terse;
}

1;
