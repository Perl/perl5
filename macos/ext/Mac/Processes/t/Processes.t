Perl -Sx "{0}" {"Parameters"}; Exit {Status}

#!perl
#
# Processes.t - List all processes, then try to launch MacPerl
#

use Mac::Processes;
use Mac::MoreFiles(%Application);

printf "%-20s %-8s  %-8s\n", "Process Name", "PSN", "Location";

while (($psn, $pi) = each %Process) {
	printf "%-20s %08X @%08X\n", 
		$pi->processName, $pi->processNumber, $pi->processLocation;
}

$Launch = new LaunchParam(
	launchControlFlags => launchContinue+launchNoFileFlags+launchDontSwitch,
	launchAppSpec      => $Application{McPL}
);

LaunchApplication($Launch) ||Êdie "$^E";

printf "Launched %X flags %X\n", $Launch->launchProcessSN, $Launch->launchControlFlags;
