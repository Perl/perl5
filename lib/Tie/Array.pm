package Tie::Array; 

# No content yet - just pod skeleton.

1;

__END__

=head1 NAME

Tie::Array - base class for tied arrays

=head1 SYNOPSIS  

    use Tie::Array;
    @ISA = 'Tie::Array';

    sub SIZE  { ... } 
    sub FETCH { ... } 
    sub STORE { ... } 
    sub CLEAR { ... } 
    sub PUSH { ... } 
    sub POP { ... } 
    sub SHIFT { ... } 
    sub UNSHIFT { ... } 
    sub SPLICE { ... } 

=head1 DESCRIPTION       

This module provides some skeletal methods for array-tying classes.


=head1 CAVEATS

There is no support at present for tied @ISA. There is a potential conflict 
between magic entries needed to notice setting of @ISA, and those needed to
implement 'tie'. 

=cut 

