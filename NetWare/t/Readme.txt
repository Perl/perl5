

		Automated Testing of Perl5.6.1 Interpreter for NetWare.



A set of Standard Unit Test Scripts to test all the functionalities of Perl 5.6.1 Interpreter are available along with the CPAN download. They are all located under 't' folder. These include sub-folders under 't' folder: 'base', 'cmd', 'comp', 'io', lib', 'op', 'pod', 'pragma', 'run'. Each of these sub-folders contain few test scripts ('.t' files) under them.

Executing these test scripts on NetWare can be automated as per the following:

1. Automated scripts, 'base.pl', 'cmd.pl', 'comp.pl', 'io.pl', 'lib.pl', 'op.pl', 'pod.pl', 'pragma.pl', 'run.pl' can be generated that are used to execute all the test scripts ('.t' files) under the corresponding folder.
For example, 'base.pl' tests all the test scripts under 'sys:\perl\scripts\t\base' folder, 'comp.pl' test all scripts under 'sys:\perl\scripts\t\comp' folder and so on.

2. An automated script, 'auto.pl' can also be generated that executes all the above mentioned '.pl' automated scripts, thus executing all the '.t' scripts.

There is a script 'NWScripts.pl' available under the 'NetWare\t' folder of the CPAN download. This is written to generate these automated scripts when executed on a NetWare server. It generates the automated scripts, 'base.pl', 'cmd.pl', 'comp.pl', 'io.pl', 'lib.pl', 'op.pl', 'pod.pl', 'pragma.pl', 'run.pl' and also 'auto.pl' by including all the corresponding '.t' scripts in them. For example, all the scripts that are under 't\base' folder will be entered in 'base.pl' and so on. 'auto.pl will include all these '.pl' scripts like 'base.pl', 'comp.pl' etc.


The following steps elicits the procedure for executing the automated scripts:

1. Copy the 't' folder from the CPAN download to 'sys:\perl\scripts' folder on the NetWare server.

2. Copy all the files from 'NetWare\t' folder of the CPAN download into 'sys:\perl\scripts\t' folder.

3. Execute the command  "perl t\NWModify.pl" on the console command prompt. This script replaces 
     "@INC = " with "unshift @INC, "  and
     "push @INC, " with "unshift @INC, "
   from all the scripts under 'sys:\perl\scripts\t' folder.

This is done to include the correct path for libraries into the scripts when executed on NetWare. If this is not done, some of the scripts will not get executed since they cannot locate the corresponding libraries.

4. Execute the command  "perl t\NWScripts.pl" on the console command prompt to generate the automated scripts mentioned above under the 'sys:\perl\scripts\t' folder.
   (See above for details).

5. Execute 'auto.pl' script using the server console command, "perl t\auto.pl" to run all the standard test scripts. If you want the results to be redirected into a file, say 'auto.txt', then the console command is:  "perl t\auto.pl > auto.txt"

6. If you want to execute certain set of scripts, then run the corresponding '.pl' file. For example, if you want to execute only the 'lib' scripts, then execute 'run.pl' through the server console command, "perl t\run.pl'. To redirect the results into a file, the console command could be, "perl t\run.pl > run.txt".


Known Issues:

The following scripts are commented out in the corresponding autoscript:

1. 'openpid.t' in 'sys:\perl\scripts\t\io.pl' script
   Reason:
     This either hangs or abends the server when executing through auto scripts.
     When run individually, the script execution goes through fine.

2. 'argv.t' in 'sys:\perl\scripts\t\io.pl' script
   Reason:
     This either hangs or abends the server when executing through auto scripts.
     When run individually, the script execution goes through fine.

3. 'filehand.t' in 'sys:\perl\scripts\t\lib.pl' script
   Reason:
     This hangs in the last test case where it uses FileHandle::Pipe whether run individually
     or through an auto script.

