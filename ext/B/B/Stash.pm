# Stash.pm -- show what stashes are loaded
# vishalb@hotmail.com 
package B::Stash;

BEGIN { %Seen = %INC }

END {
	my @arr=scan($main::{"main::"});
	@arr=map{s/\:\:$//;$_;}  @arr;
	print "-umain,-u", join (",-u",@arr) ,"\n";
}
sub scan{
	my $start=shift;
	my @return;
	foreach my $key ( keys %{$start}){
		if ($key =~ /::$/){
			unless ($start  eq ${$start}{$key} or $key eq "B::" ){
		 		push @return, $key ;
				foreach my $subscan ( scan(${$start}{$key})){
		 			push @return, "$key".$subscan; 	
				}
			}
		}
	}
	return @return;
}
1;


