package Bundle::CPAN;

$VERSION = '0.02';

1;

__END__

=head1 NAME

Bundle::CPAN - A bundle to play with all the other modules on CPAN

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::CPAN'>

=head1 CONTENTS

CPAN

CPAN::WAIT

=head1 DESCRIPTION

This bundle includes CPAN.pm as the base module and CPAN::WAIT, the
first plugin for CPAN that was developed even before there was an API.

After installing this bundle, it is recommended to quit the current
session and start again in a new process.

=head1 AUTHOR

Andreas König
