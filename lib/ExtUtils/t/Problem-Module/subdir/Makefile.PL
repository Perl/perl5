printf "\@INC %s .\n", (grep { $_ eq '.' } @INC) ? "has" : "doesn't have";

warn "I think I'm going to be sick\n";
die "YYYAaaaakkk\n";
