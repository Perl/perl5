#
# expand and unexpand tabs as per the unix expand and 
# unexpand programs.
#
# expand and unexpand operate on arrays of lines.  Do not
# feed strings that contain newlines to them.
#
# David Muir Sharnoff <muir@idiom.com>
# 

package Text::Tabs;

require Exporter;

@ISA = (Exporter);
@EXPORT = qw(expand unexpand $tabstop);

$tabstop = 8;

sub expand
{
	my @l = @_;
	for $_ (@l) {
		1 while s/^([^\t]*)(\t+)/
			$1 . (" " x 
				($tabstop * length($2)
				- (length($1) % $tabstop)))
			/e;
	}
	return @l;
}

sub unexpand
{
	my @l = &expand(@_);
	my @e;
	for $x (@l) {
		@e = split(/(.{$tabstop})/,$x);
		for $_ (@e) {
			s/  +$/\t/;
		}
		$x = join('',@e);
	}
	return @l;
}

1;
