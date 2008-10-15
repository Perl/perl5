package NoExporter;
# $Id: /mirror/googlecode/test-more-trunk/t/lib/NoExporter.pm 67132 2008-10-01T01:11:04.501643Z schwern  $

$VERSION = 1.02;

sub import {
    shift;
    die "NoExporter exports nothing.  You asked for: @_" if @_;
}

1;

