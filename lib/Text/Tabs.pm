#
# expand and unexpand tabs as per the unix expand and 
# unexpand programs.
#
# expand and unexpand operate on arrays of lines.  
#
# David Muir Sharnoff <muir@idiom.com>
# Version: 4/19/95
# 

package Text::Tabs;

require Exporter;

@ISA = (Exporter);
@EXPORT = qw(expand unexpand $tabstop);

$tabstop = 8;

sub expand
{
	my (@l) = @_;
	my $l, @k;
	my $nl;
	for $l (@l) {
		$nl = $/ if chomp($l);
		@k = split($/,$l);
		for $_ (@k) {
			1 while s/^([^\t]*)(\t+)/
				$1 . (" " x 
					($tabstop * length($2)
					- (length($1) % $tabstop)))
				/e;
		}
		$l = join("\n",@k).$nl;
	}
	return @l if $#l > 0;
	return $l[0];
}

sub unexpand
{
	my (@l) = &expand(@_);
	my @e;
	my $k, @k;
	my $nl;
	for $k (@l) {
		$nl = $/ if chomp($k);
		@k = split($/,$k);
		for $x (@k) {
			@e = split(/(.{$tabstop})/,$x);
			for $_ (@e) {
				s/  +$/\t/;
			}
			$x = join('',@e);
		}
		$k = join("\n",@k).$nl;
	}
	return @l if $#l > 0;
	return $l[0];
}

1;
