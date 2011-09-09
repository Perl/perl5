print "1..2\n";

print defined(&Carp::carp) ? "not " : "", "ok 1 # control\n";
require Carp::Heavy;
print defined(&Carp::carp) ? "" : "not ", "ok 2 # carp loaded by Carp::Heavy\n";

1;
