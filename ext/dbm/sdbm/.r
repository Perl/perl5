if test -f 'CHANGES' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'CHANGES'\"
else
echo shar: Extracting \"'CHANGES'\" \(900 characters\)
sed "s/^X//" >'CHANGES' <<'END_OF_FILE'
XChanges from the earlier BETA releases.
X
Xo dbm_prep does everything now, so dbm_open is just a simple
X  wrapper that builds the default filenames. dbm_prep no longer
X  requires a (DBM *) db parameter: it allocates one itself. It
X  returns (DBM *) db or (DBM *) NULL.
X
Xo makroom is now reliable. In the common-case optimization of the page
X  split, the page into which the incoming key/value pair is to be inserted
X  is write-deferred (if the split is successful), thereby saving a cosly
X  write.  BUT, if the split does not make enough room (unsuccessful), the
X  deferred page is written out, as the failure-window is now dependent on
X  the number of split attempts.
X
Xo if -DDUFF is defined, hash function will also use the DUFF construct.
X  This may look like a micro-performance tweak (maybe it is), but in fact,
X  the hash function is the third most-heavily used function, after read
X  and write.
END_OF_FILE
if test 900 -ne `wc -c <'CHANGES'`; then
    echo shar: \"'CHANGES'\" unpacked with wrong size!
fi
# end of 'CHANGES'
fi
if test -f 'COMPARE' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'COMPARE'\"
else
echo shar: Extracting \"'COMPARE'\" \(2832 characters\)
sed "s/^X//" >'COMPARE' <<'END_OF_FILE'
X
XScript started on Thu Sep 28 15:41:06 1989
X% uname -a
Xtitan titan 4_0 UMIPS mips
X% make all x-dbm
X        cc -O -DSDBM -DDUFF -DDUPERROR -DSPLITFAIL -c dbm.c
X        cc -O -DSDBM -DDUFF -DDUPERROR -DSPLITFAIL -c sdbm.c
X        cc -O -DSDBM -DDUFF -DDUPERROR -DSPLITFAIL -c pair.c
X        cc -O -DSDBM -DDUFF -DDUPERROR -DSPLITFAIL -c hash.c
X        ar cr libsdbm.a sdbm.o pair.o hash.o
X        ranlib libsdbm.a
X        cc  -o dbm dbm.o libsdbm.a
X        cc -O -DSDBM -DDUFF -DDUPERROR -DSPLITFAIL -c dba.c
X        cc  -o dba dba.o
X        cc -O -DSDBM -DDUFF -DDUPERROR -DSPLITFAIL -c dbd.c
X        cc  -o dbd dbd.o
X        cc -O -DSDBM -DDUFF -DDUPERROR -DSPLITFAIL -o x-dbm dbm.o
X% 
X% 
X% wc history
X  65110 218344 3204883 history
X% 
X% /bin/time dbm build foo <history
X
Xreal     5:56.9
Xuser       13.3
Xsys        26.3
X% ls -s
Xtotal 14251
X   5 README           2 dbd.c            1 hash.c           1 pair.h
X   0 SCRIPT           5 dbd.o            1 hash.o           5 pair.o
X   1 WISHLIST        62 dbm           3130 history          1 port.h
X  46 dba              5 dbm.c           11 howtodbm.txt    11 sdbm.c
X   3 dba.c            8 dbm.o           14 libsdbm.a        2 sdbm.h
X   6 dba.o            4 foo.dir          1 makefile         8 sdbm.o
X  46 dbd           10810 foo.pag         6 pair.c          60 x-dbm
X% ls -l foo.*
X-rw-r--r--  1 oz           4096 Sep 28 15:48 foo.dir
X-rw-r--r--  1 oz       11069440 Sep 28 15:48 foo.pag
X% 
X% /bin/time x-dbm build bar <history
X
Xreal     5:59.4
Xuser       24.7
Xsys        29.1
X% 
X% ls -s
Xtotal 27612
X   5 README          46 dbd              1 hash.c           5 pair.o
X   1 SCRIPT           2 dbd.c            1 hash.o           1 port.h
X   1 WISHLIST         5 dbd.o         3130 history         11 sdbm.c
X   4 bar.dir         62 dbm             11 howtodbm.txt     2 sdbm.h
X13356 bar.pag         5 dbm.c           14 libsdbm.a        8 sdbm.o
X  46 dba              8 dbm.o            1 makefile        60 x-dbm
X   3 dba.c            4 foo.dir          6 pair.c
X   6 dba.o         10810 foo.pag         1 pair.h
X% 
X% ls -l bar.*
X-rw-r--r--  1 oz           4096 Sep 28 15:54 bar.dir
X-rw-r--r--  1 oz       13676544 Sep 28 15:54 bar.pag
X% 
X% dba foo | tail
X#10801: ok. no entries.
X#10802: ok. no entries.
X#10803: ok. no entries.
X#10804: ok. no entries.
X#10805: ok. no entries.
X#10806: ok. no entries.
X#10807: ok. no entries.
X#10808: ok. no entries.
X#10809: ok.  11 entries 67% used free 337.
X10810 pages (6036 holes):  65073 entries
X% 
X% dba bar | tail
X#13347: ok. no entries.
X#13348: ok. no entries.
X#13349: ok. no entries.
X#13350: ok. no entries.
X#13351: ok. no entries.
X#13352: ok. no entries.
X#13353: ok. no entries.
X#13354: ok. no entries.
X#13355: ok.   7 entries 33% used free 676.
X13356 pages (8643 holes):  65073 entries
X%
X% exit
Xscript done on Thu Sep 28 16:08:45 1989
X
END_OF_FILE
if test 2832 -ne `wc -c <'COMPARE'`; then
    echo shar: \"'COMPARE'\" unpacked with wrong size!
fi
# end of 'COMPARE'
fi
if test -f 'README' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'README'\"
else
echo shar: Extracting \"'README'\" \(11457 characters\)
sed "s/^X//" >'README' <<'END_OF_FILE'
X
X
X
X
X
X
X                   sdbm - Substitute DBM
X                             or
X        Berkeley ndbm for Every UN*X[1] Made Simple
X
X                      Ozan (oz) Yigit
X
X            The Guild of PD Software Toolmakers
X                      Toronto - Canada
X
X                     oz@nexus.yorku.ca
X
X
X
XImplementation is the sincerest form of flattery. - L. Peter
XDeutsch
X
XA The Clone of the ndbm library
X
X     The sources accompanying this notice - sdbm  -  consti-
Xtute  the  first  public  release  (Dec. 1990) of a complete
Xclone of the Berkeley UN*X ndbm library. The sdbm library is
Xmeant  to  clone the proven functionality of ndbm as closely
Xas possible, including a few improvements. It is  practical,
Xeasy to understand, and compatible.  The sdbm library is not
Xderived  from  any  licensed,  proprietary  or   copyrighted
Xsoftware.
X
X     The sdbm implementation is based on  a  1978  algorithm
X[Lar78] by P.-A. (Paul) Larson known as ``Dynamic Hashing''.
XIn the course of searching for a substitute for ndbm, I pro-
Xtotyped  three different external-hashing algorithms [Lar78,
XFag79, Lit80] and ultimately chose Larson's algorithm  as  a
Xbasis  of  the  sdbm  implementation. The Bell Labs dbm (and
Xtherefore ndbm) is based on an  algorithm  invented  by  Ken
XThompson, [Tho90, Tor87] and predates Larson's work.
X
X     The sdbm programming interface  is  totally  compatible
Xwith ndbm and includes a slight improvement in database ini-
Xtialization.  It is also expected  to  be  binary-compatible
Xunder most UN*X versions that support the ndbm library.
X
X     The sdbm implementation shares the shortcomings of  the
Xndbm library, as a side effect of various simplifications to
Xthe original Larson algorithm. It does produce holes in  the
Xpage file as it writes pages past the end of file. (Larson's
Xpaper include a clever solution to this problem  that  is  a
Xresult of using the hash value directly as a block address.)
XOn the other hand, extensive tests  seem  to  indicate  that
Xsdbm creates fewer holes in general, and the resulting page-
Xfiles are smaller. The sdbm implementation  is  also  faster
Xthan  ndbm  in database creation.  Unlike the ndbm, the sdbm
X_________________________
X
X  [1] UN*X is not a trademark of any (dis)organization.
X
X
X
X
X
X
X
X
X
X                           - 2 -
X
X
Xstore operation will not ``wander away'' trying to split its
Xdata  pages  to insert a datum that cannot (due to elaborate
Xworst-case situations) be inserted. (It will  fail  after  a
Xpre-defined number of attempts.)
X
XImportant Compatibility Warning
X
X     The sdbm and ndbm libraries cannot share databases: one
Xcannot  read  the  (dir/pag)  database created by the other.
XThis is due to the differences between  the  ndbm  and  sdbm
Xalgorithms[2], and the hash functions used.  It is  easy  to
Xconvert  between the dbm/ndbm databases and sdbm by ignoring
Xthe index completely: see dbd, dbu etc.
X
X
XNotice of Intellectual Property
X
XThe entire sdbm  library package, as authored by me, Ozan S.
XYigit,  is  hereby placed in the public domain. As such, the
Xauthor is not responsible for the  consequences  of  use  of
Xthis  software, no matter how awful, even if they arise from
Xdefects in it. There is no expressed or implied warranty for
Xthe sdbm library.
X
X     Since the sdbm library package is in the public domain,
Xthis   original  release  or  any  additional  public-domain
Xreleases of the modified original cannot possibly (by defin-
Xition) be withheld from you. Also by definition, You (singu-
Xlar) have all the rights to this code (including  the  right
Xto sell without permission, the right to  hoard[3]  and  the
Xright  to  do  other  icky  things as you see fit) but those
Xrights are also granted to everyone else.
X
X     Please note that all  previous  distributions  of  this
Xsoftware  contained  a  copyright  (which is now dropped) to
Xprotect its origins and its  current  public  domain  status
Xagainst any possible claims and/or challenges.
X
XAcknowledgments
X
X     Many people have been very helpful and  supportive.   A
Xpartial  list  would  necessarily  include Rayan Zacherissen
X(who contributed the  man  page,  and  also  hacked  a  MMAP
X_________________________
X
X  [2] Torek's   discussion   [Tor87]   indicates   that
Xdbm/ndbm implementations use the hash value to traverse
Xthe radix trie differently than sdbm and as  a  result,
Xthe page indexes are generated in different order.  For
Xmore information, send e-mail to the author.
X  [3] You  cannot really hoard something that is avail-
Xable to the public at large, but try if  it  makes  you
Xfeel any better.
X
X
X
X
X
X
X
X
X
X
X                           - 3 -
X
X
Xversion of sdbm), Arnold Robbins, Chris Lewis,  Bill  David-
Xsen,  Henry  Spencer,  Geoff  Collyer, Rich Salz (who got me
Xstarted in the first place), Johannes Ruschein (who did  the
Xminix port) and David Tilbrook. I thank you all.
X
XDistribution Manifest and Notes
X
XThis distribution of sdbm includes (at least) the following:
X
X    CHANGES     change log
X    README      this file.
X    biblio      a small bibliography on external hashing
X    dba.c       a crude (n/s)dbm page file analyzer
X    dbd.c       a crude (n/s)dbm page file dumper (for conversion)
X    dbe.1       man page for dbe.c
X    dbe.c       Janick's database editor
X    dbm.c       a dbm library emulation wrapper for ndbm/sdbm
X    dbm.h       header file for the above
X    dbu.c       a crude db management utility
X    hash.c      hashing function
X    makefile    guess.
X    pair.c      page-level routines (posted earlier)
X    pair.h      header file for the above
X    readme.ms   troff source for the README file
X    sdbm.3      man page
X    sdbm.c      the real thing
X    sdbm.h      header file for the above
X    tune.h      place for tuning & portability thingies
X    util.c      miscellaneous
X
X     dbu is a simple database manipulation  program[4]  that
Xtries to look like Bell Labs' cbt utility. It  is  currently
Xincomplete in functionality.  I use dbu to test out the rou-
Xtines: it takes (from stdin) tab separated  key/value  pairs
Xfor commands like build or insert or takes keys for commands
Xlike delete or look.
X
X    dbu <build|creat|look|insert|cat|delete> dbmfile
X
X     dba is a crude analyzer of dbm/sdbm/ndbm page files. It
Xscans the entire page file, reporting page level statistics,
Xand totals at the end.
X
X     dbd is a crude dump  program  for  dbm/ndbm/sdbm  data-
Xbases.  It  ignores  the bitmap, and dumps the data pages in
Xsequence. It can be used to create input for the  dbu  util-
Xity.   Note that dbd will skip any NULLs in the key and data
Xfields,  thus  is  unsuitable  to  convert   some   peculiar
X_________________________
X
X  [4] The dbd, dba, dbu utilities are quick  hacks  and
Xare  not  fit  for  production use. They were developed
Xlate one night, just to test out sdbm, and convert some
Xdatabases.
X
X
X
X
X
X
X
X
X
X                           - 4 -
X
X
Xdatabases that insist in including the terminating null.
X
X     I have also included a copy of the dbe  (ndbm  DataBase
XEditor)  by  Janick Bergeron [janick@bnr.ca] for your pleas-
Xure. You may find it more useful than the little  dbu  util-
Xity.
X
X     dbm.[ch] is a dbm library emulation on top of ndbm (and
Xhence suitable for sdbm). Written by Robert Elz.
X
X     The sdbm library has been around in beta test for quite
Xa  long  time,  and from whatever little feedback I received
X(maybe no news is good news), I believe it  has  been  func-
Xtioning  without  any  significant  problems.  I  would,  of
Xcourse, appreciate all fixes and/or improvements.  Portabil-
Xity enhancements would especially be useful.
X
XImplementation Issues
X
X     Hash functions: The algorithm behind  sdbm  implementa-
Xtion  needs a good bit-scrambling hash function to be effec-
Xtive. I ran into a set of constants for a simple hash  func-
Xtion  that  seem  to  help sdbm perform better than ndbm for
Xvarious inputs:
X
X    /*
X     * polynomial conversion ignoring overflows
X     * 65599 nice. 65587 even better.
X     */
X    long
X    dbm_hash(char *str, int len) {
X        register unsigned long n = 0;
X
X        while (len--)
X            n = n * 65599 + *str++;
X        return n;
X    }
X
X     There may be better hash functions for the purposes  of
Xdynamic hashing.  Try your favorite, and check the pagefile.
XIf it contains too many pages with too many holes, (in rela-
Xtion  to this one for example) or if sdbm simply stops work-
Xing (fails after SPLTMAX attempts to split)  when  you  feed
Xyour  NEWS  history  file  to it, you probably do not have a
Xgood hashing function.  If  you  do  better  (for  different
Xtypes of input), I would like to know about the function you
Xuse.
X
X     Block sizes: It seems (from  various  tests  on  a  few
Xmachines)  that a page file block size PBLKSIZ of 1024 is by
Xfar the best for performance, but this also happens to limit
Xthe  size  of a key/value pair. Depending on your needs, you
Xmay wish to increase the page size, and also adjust  PAIRMAX
X(the maximum size of a key/value pair allowed: should always
X
X
X
X
X
X
X
X
X
X                           - 5 -
X
X
Xbe at least three words smaller than PBLKSIZ.)  accordingly.
XThe  system-wide  version  of the library should probably be
Xconfigured with 1024 (distribution default), as this appears
Xto be sufficient for most common uses of sdbm.
X
XPortability
X
X     This package has been tested in many  different  UN*Xes
Xeven including minix, and appears to be reasonably portable.
XThis does not mean it will port easily to non-UN*X systems.
X
XNotes and Miscellaneous
X
X     The sdbm is not a very complicated  package,  at  least
Xnot  after  you  familiarize yourself with the literature on
Xexternal hashing. There are other interesting algorithms  in
Xexistence  that ensure (approximately) single-read access to
Xa data value associated with any key. These  are  directory-
Xless schemes such as linear hashing [Lit80] (+ Larson varia-
Xtions), spiral storage [Mar79] or directory schemes such  as
Xextensible  hashing  [Fag79] by Fagin et al. I do hope these
Xsources provide a reasonable playground for  experimentation
Xwith  other algorithms.  See the June 1988 issue of ACM Com-
Xputing Surveys [Enb88] for  an  excellent  overview  of  the
Xfield.
X
XReferences
X
X
X[Lar78]
X    P.-A. Larson, ``Dynamic Hashing'', BIT, vol.   18,   pp.
X    184-201, 1978.
X
X[Tho90]
X    Ken Thompson, private communication, Nov. 1990
X
X[Lit80]
X    W. Litwin, `` Linear Hashing: A new tool  for  file  and
X    table addressing'', Proceedings of the 6th Conference on
X    Very Large  Dabatases  (Montreal), pp.   212-223,   Very
X    Large Database Foundation, Saratoga, Calif., 1980.
X
X[Fag79]
X    R. Fagin, J.  Nievergelt,  N.  Pippinger,  and   H.   R.
X    Strong,  ``Extendible Hashing - A Fast Access Method for
X    Dynamic Files'', ACM  Trans.  Database  Syst.,  vol.  4,
X    no.3, pp. 315-344, Sept. 1979.
X
X[Wal84]
X    Rich Wales, ``Discussion of "dbm"  data  base  system'',
X    USENET newsgroup unix.wizards, Jan. 1984.
X
X[Tor87]
X    Chris Torek,  ``Re:   dbm.a   and   ndbm.a   archives'',
X
X
X
X
X
X
X
X
X
X                           - 6 -
X
X
X    USENET newsgroup comp.unix, 1987.
X
X[Mar79]
X    G. N. Martin, ``Spiral Storage: Incrementally   Augment-
X    able   Hash  Addressed  Storage'', Technical Report #27,
X    University of Varwick, Coventry, U.K., 1979.
X
X[Enb88]
X    R.  J.  Enbody  and  H.   C.   Du,   ``Dynamic   Hashing
X    Schemes'',ACM  Computing  Surveys,  vol.  20, no. 2, pp.
X    85-113, June 1988.
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
X
END_OF_FILE
if test 11457 -ne `wc -c <'README'`; then
    echo shar: \"'README'\" unpacked with wrong size!
fi
# end of 'README'
fi
if test -f 'biblio' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'biblio'\"
else
echo shar: Extracting \"'biblio'\" \(1012 characters\)
sed "s/^X//" >'biblio' <<'END_OF_FILE'
X%A R. J. Enbody
X%A H. C. Du
X%T Dynamic Hashing Schemes
X%J ACM Computing Surveys
X%V 20
X%N 2
X%D June 1988
X%P 85-113
X%K surveys
X
X%A P.-A. Larson
X%T Dynamic Hashing
X%J BIT
X%V 18
X%P 184-201
X%D 1978
X%K dynamic
X
X%A W. Litwin
X%T Linear Hashing: A new tool for file and table addressing
X%J Proceedings of the 6th Conference on Very Large Dabatases (Montreal)
X%I Very Large Database Foundation
X%C Saratoga, Calif.
X%P 212-223
X%D 1980
X%K linear
X
X%A R. Fagin
X%A J. Nievergelt
X%A N. Pippinger
X%A H. R. Strong
X%T Extendible Hashing - A Fast Access Method for Dynamic Files
X%J ACM Trans. Database Syst.
X%V 4
X%N 3
X%D Sept. 1979
X%P 315-344
X%K extend
X
X%A G. N. Martin
X%T Spiral Storage: Incrementally Augmentable Hash Addressed Storage
X%J Technical Report #27
X%I University of Varwick
X%C Coventry, U.K.
X%D 1979
X%K spiral
X
X%A Chris Torek
X%T Re: dbm.a and ndbm.a archives
X%B USENET newsgroup comp.unix
X%D 1987
X%K torek
X
X%A Rich Wales
X%T Discusson of "dbm" data base system
X%B USENET newsgroup unix.wizards
X%D Jan. 1984
X%K rich
X
X
X
X
X
X
END_OF_FILE
if test 1012 -ne `wc -c <'biblio'`; then
    echo shar: \"'biblio'\" unpacked with wrong size!
fi
# end of 'biblio'
fi
if test -f 'dba.c' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'dba.c'\"
else
echo shar: Extracting \"'dba.c'\" \(1273 characters\)
sed "s/^X//" >'dba.c' <<'END_OF_FILE'
X/*
X * dba	dbm analysis/recovery
X */
X
X#include <stdio.h>
X#include <sys/file.h>
X#include "sdbm.h"
X
Xchar *progname;
Xextern void oops();
X
Xint
Xmain(argc, argv)
Xchar **argv;
X{
X	int n;
X	char *p;
X	char *name;
X	int pagf;
X
X	progname = argv[0];
X
X	if (p = argv[1]) {
X		name = (char *) malloc((n = strlen(p)) + 5);
X		strcpy(name, p);
X		strcpy(name + n, ".pag");
X
X		if ((pagf = open(name, O_RDONLY)) < 0)
X			oops("cannot open %s.", name);
X
X		sdump(pagf);
X	}
X	else
X		oops("usage: %s dbname", progname);
X
X	return 0;
X}
X
Xsdump(pagf)
Xint pagf;
X{
X	register b;
X	register n = 0;
X	register t = 0;
X	register o = 0;
X	register e;
X	char pag[PBLKSIZ];
X
X	while ((b = read(pagf, pag, PBLKSIZ)) > 0) {
X		printf("#%d: ", n);
X		if (!okpage(pag))
X			printf("bad\n");
X		else {
X			printf("ok. ");
X			if (!(e = pagestat(pag)))
X			    o++;
X			else
X			    t += e;
X		}
X		n++;
X	}
X
X	if (b == 0)
X		printf("%d pages (%d holes):  %d entries\n", n, o, t);
X	else
X		oops("read failed: block %d", n);
X}
X
Xpagestat(pag)
Xchar *pag;
X{
X	register n;
X	register free;
X	register short *ino = (short *) pag;
X
X	if (!(n = ino[0]))
X		printf("no entries.\n");
X	else {
X		free = ino[n] - (n + 1) * sizeof(short);
X		printf("%3d entries %2d%% used free %d.\n",
X		       n / 2, ((PBLKSIZ - free) * 100) / PBLKSIZ, free);
X	}
X	return n / 2;
X}
END_OF_FILE
if test 1273 -ne `wc -c <'dba.c'`; then
    echo shar: \"'dba.c'\" unpacked with wrong size!
fi
# end of 'dba.c'
fi
if test -f 'dbd.c' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'dbd.c'\"
else
echo shar: Extracting \"'dbd.c'\" \(1719 characters\)
sed "s/^X//" >'dbd.c' <<'END_OF_FILE'
X/*
X * dbd - dump a dbm data file
X */
X
X#include <stdio.h>
X#include <sys/file.h>
X#include "sdbm.h"
X
Xchar *progname;
Xextern void oops();
X
X
X#define empty(page)	(((short *) page)[0] == 0)
X
Xint
Xmain(argc, argv)
Xchar **argv;
X{
X	int n;
X	char *p;
X	char *name;
X	int pagf;
X
X	progname = argv[0];
X
X	if (p = argv[1]) {
X		name = (char *) malloc((n = strlen(p)) + 5);
X		strcpy(name, p);
X		strcpy(name + n, ".pag");
X
X		if ((pagf = open(name, O_RDONLY)) < 0)
X			oops("cannot open %s.", name);
X
X		sdump(pagf);
X	}
X	else
X		oops("usage: %s dbname", progname);
X	return 0;
X}
X
Xsdump(pagf)
Xint pagf;
X{
X	register r;
X	register n = 0;
X	register o = 0;
X	char pag[PBLKSIZ];
X
X	while ((r = read(pagf, pag, PBLKSIZ)) > 0) {
X		if (!okpage(pag))
X			fprintf(stderr, "%d: bad page.\n", n);
X		else if (empty(pag))
X			o++;
X		else
X			dispage(pag);
X		n++;
X	}
X
X	if (r == 0)
X		fprintf(stderr, "%d pages (%d holes).\n", n, o);
X	else
X		oops("read failed: block %d", n);
X}
X
X
X#ifdef OLD
Xdispage(pag)
Xchar *pag;
X{
X	register i, n;
X	register off;
X	register short *ino = (short *) pag;
X
X	off = PBLKSIZ;
X	for (i = 1; i < ino[0]; i += 2) {
X		printf("\t[%d]: ", ino[i]);
X		for (n = ino[i]; n < off; n++)
X			putchar(pag[n]);
X		putchar(' ');
X		off = ino[i];
X		printf("[%d]: ", ino[i + 1]);
X		for (n = ino[i + 1]; n < off; n++)
X			putchar(pag[n]);
X		off = ino[i + 1];
X		putchar('\n');
X	}
X}
X#else
Xdispage(pag)
Xchar *pag;
X{
X	register i, n;
X	register off;
X	register short *ino = (short *) pag;
X
X	off = PBLKSIZ;
X	for (i = 1; i < ino[0]; i += 2) {
X		for (n = ino[i]; n < off; n++)
X			if (pag[n] != 0)
X				putchar(pag[n]);
X		putchar('\t');
X		off = ino[i];
X		for (n = ino[i + 1]; n < off; n++)
X			if (pag[n] != 0)
X				putchar(pag[n]);
X		putchar('\n');
X		off = ino[i + 1];
X	}
X}
X#endif
END_OF_FILE
if test 1719 -ne `wc -c <'dbd.c'`; then
    echo shar: \"'dbd.c'\" unpacked with wrong size!
fi
# end of 'dbd.c'
fi
if test -f 'dbe.1' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'dbe.1'\"
else
echo shar: Extracting \"'dbe.1'\" \(1454 characters\)
sed "s/^X//" >'dbe.1' <<'END_OF_FILE'
X.TH dbe 1 "ndbm(3) EDITOR"
X.SH NAME
Xdbe \- Edit a ndbm(3) database
X.SH USAGE
Xdbe <database> [-m r|w|rw] [-crtvx] -a|-d|-f|-F|-s [<key> [<content>]]
X.SH DESCRIPTION
X\fIdbme\fP operates on ndbm(3) databases.
XIt can be used to create them, look at them or change them.
XWhen specifying the value of a key or the content of its associated entry,
X\\nnn, \\0, \\n, \\t, \\f and \\r are interpreted as usual.
XWhen displaying key/content pairs, non-printable characters are displayed
Xusing the \\nnn notation.
X.SH OPTIONS
X.IP -a
XList all entries in the database.
X.IP -c
XCreate the database if it does not exist.
X.IP -d
XDelete the entry associated with the specified key.
X.IP -f
XFetch and display the entry associated with the specified key.
X.IP -F
XFetch and display all the entries whose key match the specified
Xregular-expression
X.IP "-m r|w|rw"
XOpen the database in read-only, write-only or read-write mode
X.IP -r
XReplace the entry associated with the specified key if it already exists.
XSee option -s.
X.IP -s
XStore an entry under a specific key.
XAn error occurs if the key already exists and the option -r was not specified.
X.IP -t
XRe-initialize the database before executing the command.
X.IP -v
XVerbose mode.
XConfirm stores and deletions.
X.IP -x
XIf option -x is used with option -c, then if the database already exists,
Xan error occurs.
XThis can be used to implement a simple exclusive access locking mechanism.
X.SH SEE ALSO
Xndbm(3)
X.SH AUTHOR
Xjanick@bnr.ca
X
END_OF_FILE
if test 1454 -ne `wc -c <'dbe.1'`; then
    echo shar: \"'dbe.1'\" unpacked with wrong size!
fi
# end of 'dbe.1'
fi
if test -f 'dbe.c' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'dbe.c'\"
else
echo shar: Extracting \"'dbe.c'\" \(9799 characters\)
sed "s/^X//" >'dbe.c' <<'END_OF_FILE'
X#include <stdio.h>
X#ifndef VMS
X#include <sys/file.h>
X#include <ndbm.h>
X#else
X#include "file.h"
X#include "ndbm.h"
X#endif
X#include <ctype.h>
X
X/***************************************************************************\
X**                                                                         **
X**   Function name: getopt()                                               **
X**   Author:        Henry Spencer, UofT                                    **
X**   Coding date:   84/04/28                                               **
X**                                                                         **
X**   Description:                                                          **
X**                                                                         **
X**   Parses argv[] for arguments.                                          **
X**   Works with Whitesmith's C compiler.                                   **
X**                                                                         **
X**   Inputs   - The number of arguments                                    **
X**            - The base address of the array of arguments                 **
X**            - A string listing the valid options (':' indicates an       **
X**              argument to the preceding option is required, a ';'        **
X**              indicates an argument to the preceding option is optional) **
X**                                                                         **
X**   Outputs  - Returns the next option character,                         **
X**              '?' for non '-' arguments                                  **
X**              or ':' when there is no more arguments.                    **
X**                                                                         **
X**   Side Effects + The argument to an option is pointed to by 'optarg'    **
X**                                                                         **
X*****************************************************************************
X**                                                                         **
X**   REVISION HISTORY:                                                     **
X**                                                                         **
X**     DATE           NAME                        DESCRIPTION              **
X**   YY/MM/DD  ------------------   ------------------------------------   **
X**   88/10/20  Janick Bergeron      Returns '?' on unamed arguments        **
X**                                  returns '!' on unknown options         **
X**                                  and 'EOF' only when exhausted.         **
X**   88/11/18  Janick Bergeron      Return ':' when no more arguments      **
X**   89/08/11  Janick Bergeron      Optional optarg when ';' in optstring  **
X**                                                                         **
X\***************************************************************************/
X
Xchar *optarg;			       /* Global argument pointer. */
X
X#ifdef VMS
X#define index  strchr
X#endif
X
Xchar
Xgetopt(argc, argv, optstring)
Xint argc;
Xchar **argv;
Xchar *optstring;
X{
X	register int c;
X	register char *place;
X	extern char *index();
X	static int optind = 0;
X	static char *scan = NULL;
X
X	optarg = NULL;
X
X	if (scan == NULL || *scan == '\0') {
X
X		if (optind == 0)
X			optind++;
X		if (optind >= argc)
X			return ':';
X
X		optarg = place = argv[optind++];
X		if (place[0] != '-' || place[1] == '\0')
X			return '?';
X		if (place[1] == '-' && place[2] == '\0')
X			return '?';
X		scan = place + 1;
X	}
X
X	c = *scan++;
X	place = index(optstring, c);
X	if (place == NULL || c == ':' || c == ';') {
X
X		(void) fprintf(stderr, "%s: unknown option %c\n", argv[0], c);
X		scan = NULL;
X		return '!';
X	}
X	if (*++place == ':') {
X
X		if (*scan != '\0') {
X
X			optarg = scan;
X			scan = NULL;
X
X		}
X		else {
X
X			if (optind >= argc) {
X
X				(void) fprintf(stderr, "%s: %c requires an argument\n",
X					       argv[0], c);
X				return '!';
X			}
X			optarg = argv[optind];
X			optind++;
X		}
X	}
X	else if (*place == ';') {
X
X		if (*scan != '\0') {
X
X			optarg = scan;
X			scan = NULL;
X
X		}
X		else {
X
X			if (optind >= argc || *argv[optind] == '-')
X				optarg = NULL;
X			else {
X				optarg = argv[optind];
X				optind++;
X			}
X		}
X	}
X	return c;
X}
X
X
Xvoid
Xprint_datum(db)
Xdatum db;
X{
X	int i;
X
X	putchar('"');
X	for (i = 0; i < db.dsize; i++) {
X		if (isprint(db.dptr[i]))
X			putchar(db.dptr[i]);
X		else {
X			putchar('\\');
X			putchar('0' + ((db.dptr[i] >> 6) & 0x07));
X			putchar('0' + ((db.dptr[i] >> 3) & 0x07));
X			putchar('0' + (db.dptr[i] & 0x07));
X		}
X	}
X	putchar('"');
X}
X
X
Xdatum
Xread_datum(s)
Xchar *s;
X{
X	datum db;
X	char *p;
X	int i;
X
X	db.dsize = 0;
X	db.dptr = (char *) malloc(strlen(s) * sizeof(char));
X	for (p = db.dptr; *s != '\0'; p++, db.dsize++, s++) {
X		if (*s == '\\') {
X			if (*++s == 'n')
X				*p = '\n';
X			else if (*s == 'r')
X				*p = '\r';
X			else if (*s == 'f')
X				*p = '\f';
X			else if (*s == 't')
X				*p = '\t';
X			else if (isdigit(*s) && isdigit(*(s + 1)) && isdigit(*(s + 2))) {
X				i = (*s++ - '0') << 6;
X				i |= (*s++ - '0') << 3;
X				i |= *s - '0';
X				*p = i;
X			}
X			else if (*s == '0')
X				*p = '\0';
X			else
X				*p = *s;
X		}
X		else
X			*p = *s;
X	}
X
X	return db;
X}
X
X
Xchar *
Xkey2s(db)
Xdatum db;
X{
X	char *buf;
X	char *p1, *p2;
X
X	buf = (char *) malloc((db.dsize + 1) * sizeof(char));
X	for (p1 = buf, p2 = db.dptr; *p2 != '\0'; *p1++ = *p2++);
X	*p1 = '\0';
X	return buf;
X}
X
X
Xmain(argc, argv)
Xint argc;
Xchar **argv;
X{
X	typedef enum {
X		YOW, FETCH, STORE, DELETE, SCAN, REGEXP
X	} commands;
X	char opt;
X	int flags;
X	int giveusage = 0;
X	int verbose = 0;
X	commands what = YOW;
X	char *comarg[3];
X	int st_flag = DBM_INSERT;
X	int argn;
X	DBM *db;
X	datum key;
X	datum content;
X
X	flags = O_RDWR;
X	argn = 0;
X
X	while ((opt = getopt(argc, argv, "acdfFm:rstvx")) != ':') {
X		switch (opt) {
X		case 'a':
X			what = SCAN;
X			break;
X		case 'c':
X			flags |= O_CREAT;
X			break;
X		case 'd':
X			what = DELETE;
X			break;
X		case 'f':
X			what = FETCH;
X			break;
X		case 'F':
X			what = REGEXP;
X			break;
X		case 'm':
X			flags &= ~(000007);
X			if (strcmp(optarg, "r") == 0)
X				flags |= O_RDONLY;
X			else if (strcmp(optarg, "w") == 0)
X				flags |= O_WRONLY;
X			else if (strcmp(optarg, "rw") == 0)
X				flags |= O_RDWR;
X			else {
X				fprintf(stderr, "Invalid mode: \"%s\"\n", optarg);
X				giveusage = 1;
X			}
X			break;
X		case 'r':
X			st_flag = DBM_REPLACE;
X			break;
X		case 's':
X			what = STORE;
X			break;
X		case 't':
X			flags |= O_TRUNC;
X			break;
X		case 'v':
X			verbose = 1;
X			break;
X		case 'x':
X			flags |= O_EXCL;
X			break;
X		case '!':
X			giveusage = 1;
X			break;
X		case '?':
X			if (argn < 3)
X				comarg[argn++] = optarg;
X			else {
X				fprintf(stderr, "Too many arguments.\n");
X				giveusage = 1;
X			}
X			break;
X		}
X	}
X
X	if (giveusage | what == YOW | argn < 1) {
X		fprintf(stderr, "Usage: %s databse [-m r|w|rw] [-crtx] -a|-d|-f|-F|-s [key [content]]\n", argv[0]);
X		exit(-1);
X	}
X
X	if ((db = dbm_open(comarg[0], flags, 0777)) == NULL) {
X		fprintf(stderr, "Error opening database \"%s\"\n", comarg[0]);
X		exit(-1);
X	}
X
X	if (argn > 1)
X		key = read_datum(comarg[1]);
X	if (argn > 2)
X		content = read_datum(comarg[2]);
X
X	switch (what) {
X
X	case SCAN:
X		key = dbm_firstkey(db);
X		if (dbm_error(db)) {
X			fprintf(stderr, "Error when fetching first key\n");
X			goto db_exit;
X		}
X		while (key.dptr != NULL) {
X			content = dbm_fetch(db, key);
X			if (dbm_error(db)) {
X				fprintf(stderr, "Error when fetching ");
X				print_datum(key);
X				printf("\n");
X				goto db_exit;
X			}
X			print_datum(key);
X			printf(": ");
X			print_datum(content);
X			printf("\n");
X			if (dbm_error(db)) {
X				fprintf(stderr, "Error when fetching next key\n");
X				goto db_exit;
X			}
X			key = dbm_nextkey(db);
X		}
X		break;
X
X	case REGEXP:
X		if (argn < 2) {
X			fprintf(stderr, "Missing regular expression.\n");
X			goto db_exit;
X		}
X		if (re_comp(comarg[1])) {
X			fprintf(stderr, "Invalid regular expression\n");
X			goto db_exit;
X		}
X		key = dbm_firstkey(db);
X		if (dbm_error(db)) {
X			fprintf(stderr, "Error when fetching first key\n");
X			goto db_exit;
X		}
X		while (key.dptr != NULL) {
X			if (re_exec(key2s(key))) {
X				content = dbm_fetch(db, key);
X				if (dbm_error(db)) {
X					fprintf(stderr, "Error when fetching ");
X					print_datum(key);
X					printf("\n");
X					goto db_exit;
X				}
X				print_datum(key);
X				printf(": ");
X				print_datum(content);
X				printf("\n");
X				if (dbm_error(db)) {
X					fprintf(stderr, "Error when fetching next key\n");
X					goto db_exit;
X				}
X			}
X			key = dbm_nextkey(db);
X		}
X		break;
X
X	case FETCH:
X		if (argn < 2) {
X			fprintf(stderr, "Missing fetch key.\n");
X			goto db_exit;
X		}
X		content = dbm_fetch(db, key);
X		if (dbm_error(db)) {
X			fprintf(stderr, "Error when fetching ");
X			print_datum(key);
X			printf("\n");
X			goto db_exit;
X		}
X		if (content.dptr == NULL) {
X			fprintf(stderr, "Cannot find ");
X			print_datum(key);
X			printf("\n");
X			goto db_exit;
X		}
X		print_datum(key);
X		printf(": ");
X		print_datum(content);
X		printf("\n");
X		break;
X
X	case DELETE:
X		if (argn < 2) {
X			fprintf(stderr, "Missing delete key.\n");
X			goto db_exit;
X		}
X		if (dbm_delete(db, key) || dbm_error(db)) {
X			fprintf(stderr, "Error when deleting ");
X			print_datum(key);
X			printf("\n");
X			goto db_exit;
X		}
X		if (verbose) {
X			print_datum(key);
X			printf(": DELETED\n");
X		}
X		break;
X
X	case STORE:
X		if (argn < 3) {
X			fprintf(stderr, "Missing key and/or content.\n");
X			goto db_exit;
X		}
X		if (dbm_store(db, key, content, st_flag) || dbm_error(db)) {
X			fprintf(stderr, "Error when storing ");
X			print_datum(key);
X			printf("\n");
X			goto db_exit;
X		}
X		if (verbose) {
X			print_datum(key);
X			printf(": ");
X			print_datum(content);
X			printf(" STORED\n");
X		}
X		break;
X	}
X
Xdb_exit:
X	dbm_clearerr(db);
X	dbm_close(db);
X	if (dbm_error(db)) {
X		fprintf(stderr, "Error closing database \"%s\"\n", comarg[0]);
X		exit(-1);
X	}
X}
END_OF_FILE
if test 9799 -ne `wc -c <'dbe.c'`; then
    echo shar: \"'dbe.c'\" unpacked with wrong size!
fi
# end of 'dbe.c'
fi
if test -f 'dbm.c' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'dbm.c'\"
else
echo shar: Extracting \"'dbm.c'\" \(2426 characters\)
sed "s/^X//" >'dbm.c' <<'END_OF_FILE'
X/*
X * Copyright (c) 1985 The Regents of the University of California.
X * All rights reserved.
X *
X * Redistribution and use in source and binary forms are permitted
X * provided that the above copyright notice and this paragraph are
X * duplicated in all such forms and that any documentation,
X * advertising materials, and other materials related to such
X * distribution and use acknowledge that the software was developed
X * by the University of California, Berkeley.  The name of the
X * University may not be used to endorse or promote products derived
X * from this software without specific prior written permission.
X * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
X * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
X * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
X */
X
X#ifndef lint
Xstatic char sccsid[] = "@(#)dbm.c    5.4 (Berkeley) 5/24/89";
X#endif /* not lint */
X
X#include    "dbm.h"
X
X#define    NODB    ((DBM *)0)
X
Xstatic DBM *cur_db = NODB;
X
Xstatic char no_db[] = "dbm: no open database\n";
X
Xdbminit(file)
X    char *file;
X{
X    if (cur_db != NODB)
X        dbm_close(cur_db);
X
X    cur_db = dbm_open(file, 2, 0);
X    if (cur_db == NODB) {
X        cur_db = dbm_open(file, 0, 0);
X        if (cur_db == NODB)
X            return (-1);
X    }
X    return (0);
X}
X
Xlong
Xforder(key)
Xdatum key;
X{
X    if (cur_db == NODB) {
X        printf(no_db);
X        return (0L);
X    }
X    return (dbm_forder(cur_db, key));
X}
X
Xdatum
Xfetch(key)
Xdatum key;
X{
X    datum item;
X
X    if (cur_db == NODB) {
X        printf(no_db);
X        item.dptr = 0;
X        return (item);
X    }
X    return (dbm_fetch(cur_db, key));
X}
X
Xdelete(key)
Xdatum key;
X{
X    if (cur_db == NODB) {
X        printf(no_db);
X        return (-1);
X    }
X    if (dbm_rdonly(cur_db))
X        return (-1);
X    return (dbm_delete(cur_db, key));
X}
X
Xstore(key, dat)
Xdatum key, dat;
X{
X    if (cur_db == NODB) {
X        printf(no_db);
X        return (-1);
X    }
X    if (dbm_rdonly(cur_db))
X        return (-1);
X
X    return (dbm_store(cur_db, key, dat, DBM_REPLACE));
X}
X
Xdatum
Xfirstkey()
X{
X    datum item;
X
X    if (cur_db == NODB) {
X        printf(no_db);
X        item.dptr = 0;
X        return (item);
X    }
X    return (dbm_firstkey(cur_db));
X}
X
Xdatum
Xnextkey(key)
Xdatum key;
X{
X    datum item;
X
X    if (cur_db == NODB) {
X        printf(no_db);
X        item.dptr = 0;
X        return (item);
X    }
X    return (dbm_nextkey(cur_db, key));
X}
END_OF_FILE
if test 2426 -ne `wc -c <'dbm.c'`; then
    echo shar: \"'dbm.c'\" unpacked with wrong size!
fi
# end of 'dbm.c'
fi
if test -f 'dbm.h' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'dbm.h'\"
else
echo shar: Extracting \"'dbm.h'\" \(1186 characters\)
sed "s/^X//" >'dbm.h' <<'END_OF_FILE'
X/*
X * Copyright (c) 1983 The Regents of the University of California.
X * All rights reserved.
X *
X * Redistribution and use in source and binary forms are permitted
X * provided that the above copyright notice and this paragraph are
X * duplicated in all such forms and that any documentation,
X * advertising materials, and other materials related to such
X * distribution and use acknowledge that the software was developed
X * by the University of California, Berkeley.  The name of the
X * University may not be used to endorse or promote products derived
X * from this software without specific prior written permission.
X * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
X * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
X * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
X *
X *    @(#)dbm.h    5.2 (Berkeley) 5/24/89
X */
X
X#ifndef NULL
X/*
X * this is lunacy, we no longer use it (and never should have
X * unconditionally defined it), but, this whole file is for
X * backwards compatability - someone may rely on this.
X */
X#define    NULL    ((char *) 0)
X#endif
X
X#include <ndbm.h>
X
Xdatum    fetch();
Xdatum    firstkey();
Xdatum    nextkey();
END_OF_FILE
if test 1186 -ne `wc -c <'dbm.h'`; then
    echo shar: \"'dbm.h'\" unpacked with wrong size!
fi
# end of 'dbm.h'
fi
if test -f 'dbu.c' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'dbu.c'\"
else
echo shar: Extracting \"'dbu.c'\" \(4408 characters\)
sed "s/^X//" >'dbu.c' <<'END_OF_FILE'
X#include <stdio.h>
X#include <sys/file.h>
X#ifdef SDBM
X#include "sdbm.h"
X#else
X#include <ndbm.h>
X#endif
X#include <string.h>
X
X#ifdef BSD42
X#define strchr	index
X#endif
X
Xextern int	getopt();
Xextern char	*strchr();
Xextern void	oops();
X
Xchar *progname;
X
Xstatic int rflag;
Xstatic char *usage = "%s [-R] cat | look |... dbmname";
X
X#define DERROR	0
X#define DLOOK	1
X#define DINSERT	2
X#define DDELETE 3
X#define	DCAT	4
X#define DBUILD	5
X#define DPRESS	6
X#define DCREAT	7
X
X#define LINEMAX	8192
X
Xtypedef struct {
X	char *sname;
X	int scode;
X	int flags;
X} cmd;
X
Xstatic cmd cmds[] = {
X
X	"fetch", DLOOK, 	O_RDONLY,
X	"get", DLOOK,		O_RDONLY,
X	"look", DLOOK,		O_RDONLY,
X	"add", DINSERT,		O_RDWR,
X	"insert", DINSERT,	O_RDWR,
X	"store", DINSERT,	O_RDWR,
X	"delete", DDELETE,	O_RDWR,
X	"remove", DDELETE,	O_RDWR,
X	"dump", DCAT,		O_RDONLY,
X	"list", DCAT, 		O_RDONLY,
X	"cat", DCAT,		O_RDONLY,
X	"creat", DCREAT,	O_RDWR | O_CREAT | O_TRUNC,
X	"new", DCREAT,		O_RDWR | O_CREAT | O_TRUNC,
X	"build", DBUILD,	O_RDWR | O_CREAT,
X	"squash", DPRESS,	O_RDWR,
X	"compact", DPRESS,	O_RDWR,
X	"compress", DPRESS,	O_RDWR
X};
X
X#define CTABSIZ (sizeof (cmds)/sizeof (cmd))
X
Xstatic cmd *parse();
Xstatic void badk(), doit(), prdatum();
X
Xint
Xmain(argc, argv)
Xint	argc;
Xchar *argv[];
X{
X	int c;
X	register cmd *act;
X	extern int optind;
X	extern char *optarg;
X
X	progname = argv[0];
X
X	while ((c = getopt(argc, argv, "R")) != EOF)
X		switch (c) {
X		case 'R':	       /* raw processing  */
X			rflag++;
X			break;
X
X		default:
X			oops("usage: %s", usage);
X			break;
X		}
X
X	if ((argc -= optind) < 2)
X		oops("usage: %s", usage);
X
X	if ((act = parse(argv[optind])) == NULL)
X		badk(argv[optind]);
X	optind++;
X	doit(act, argv[optind]);
X	return 0;
X}
X
Xstatic void
Xdoit(act, file)
Xregister cmd *act;
Xchar *file;
X{
X	datum key;
X	datum val;
X	register DBM *db;
X	register char *op;
X	register int n;
X	char *line;
X#ifdef TIME
X	long start;
X	extern long time();
X#endif
X
X	if ((db = dbm_open(file, act->flags, 0644)) == NULL)
X		oops("cannot open: %s", file);
X
X	if ((line = (char *) malloc(LINEMAX)) == NULL)
X		oops("%s: cannot get memory", "line alloc");
X
X	switch (act->scode) {
X
X	case DLOOK:
X		while (fgets(line, LINEMAX, stdin) != NULL) {
X			n = strlen(line) - 1;
X			line[n] = 0;
X			key.dptr = line;
X			key.dsize = n;
X			val = dbm_fetch(db, key);
X			if (val.dptr != NULL) {
X				prdatum(stdout, val);
X				putchar('\n');
X				continue;
X			}
X			prdatum(stderr, key);
X			fprintf(stderr, ": not found.\n");
X		}
X		break;
X	case DINSERT:
X		break;
X	case DDELETE:
X		while (fgets(line, LINEMAX, stdin) != NULL) {
X			n = strlen(line) - 1;
X			line[n] = 0;
X			key.dptr = line;
X			key.dsize = n;
X			if (dbm_delete(db, key) == -1) {
X				prdatum(stderr, key);
X				fprintf(stderr, ": not found.\n");
X			}
X		}
X		break;
X	case DCAT:
X		for (key = dbm_firstkey(db); key.dptr != 0; 
X		     key = dbm_nextkey(db)) {
X			prdatum(stdout, key);
X			putchar('\t');
X			prdatum(stdout, dbm_fetch(db, key));
X			putchar('\n');
X		}
X		break;
X	case DBUILD:
X#ifdef TIME
X		start = time(0);
X#endif
X		while (fgets(line, LINEMAX, stdin) != NULL) {
X			n = strlen(line) - 1;
X			line[n] = 0;
X			key.dptr = line;
X			if ((op = strchr(line, '\t')) != 0) {
X				key.dsize = op - line;
X				*op++ = 0;
X				val.dptr = op;
X				val.dsize = line + n - op;
X			}
X			else
X				oops("bad input; %s", line);
X	
X			if (dbm_store(db, key, val, DBM_REPLACE) < 0) {
X				prdatum(stderr, key);
X				fprintf(stderr, ": ");
X				oops("store: %s", "failed");
X			}
X		}
X#ifdef TIME
X		printf("done: %d seconds.\n", time(0) - start);
X#endif
X		break;
X	case DPRESS:
X		break;
X	case DCREAT:
X		break;
X	}
X
X	dbm_close(db);
X}
X
Xstatic void
Xbadk(word)
Xchar *word;
X{
X	register int i;
X
X	if (progname)
X		fprintf(stderr, "%s: ", progname);
X	fprintf(stderr, "bad keywd %s. use one of\n", word);
X	for (i = 0; i < (int)CTABSIZ; i++)
X		fprintf(stderr, "%-8s%c", cmds[i].sname,
X			((i + 1) % 6 == 0) ? '\n' : ' ');
X	fprintf(stderr, "\n");
X	exit(1);
X	/*NOTREACHED*/
X}
X
Xstatic cmd *
Xparse(str)
Xregister char *str;
X{
X	register int i = CTABSIZ;
X	register cmd *p;
X	
X	for (p = cmds; i--; p++)
X		if (strcmp(p->sname, str) == 0)
X			return p;
X	return NULL;
X}
X
Xstatic void
Xprdatum(stream, d)
XFILE *stream;
Xdatum d;
X{
X	register int c;
X	register char *p = d.dptr;
X	register int n = d.dsize;
X
X	while (n--) {
X		c = *p++ & 0377;
X		if (c & 0200) {
X			fprintf(stream, "M-");
X			c &= 0177;
X		}
X		if (c == 0177 || c < ' ') 
X			fprintf(stream, "^%c", (c == 0177) ? '?' : c + '@');
X		else
X			putc(c, stream);
X	}
X}
X
X
END_OF_FILE
if test 4408 -ne `wc -c <'dbu.c'`; then
    echo shar: \"'dbu.c'\" unpacked with wrong size!
fi
# end of 'dbu.c'
fi
if test -f 'grind' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'grind'\"
else
echo shar: Extracting \"'grind'\" \(201 characters\)
sed "s/^X//" >'grind' <<'END_OF_FILE'
X#!/bin/sh
Xrm -f /tmp/*.dir /tmp/*.pag
Xawk -e '{
X        printf "%s\t", $0
X        for (i = 0; i < 40; i++)
X                printf "%s.", $0
X        printf "\n"
X}' < /usr/dict/words | $1 build /tmp/$2
X
END_OF_FILE
if test 201 -ne `wc -c <'grind'`; then
    echo shar: \"'grind'\" unpacked with wrong size!
fi
chmod +x 'grind'
# end of 'grind'
fi
if test -f 'hash.c' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'hash.c'\"
else
echo shar: Extracting \"'hash.c'\" \(922 characters\)
sed "s/^X//" >'hash.c' <<'END_OF_FILE'
X/*
X * sdbm - ndbm work-alike hashed database library
X * based on Per-Aake Larson's Dynamic Hashing algorithms. BIT 18 (1978).
X * author: oz@nexus.yorku.ca
X * status: public domain. keep it that way.
X *
X * hashing routine
X */
X
X#include "sdbm.h"
X/*
X * polynomial conversion ignoring overflows
X * [this seems to work remarkably well, in fact better
X * then the ndbm hash function. Replace at your own risk]
X * use: 65599	nice.
X *      65587   even better. 
X */
Xlong
Xdbm_hash(str, len)
Xregister char *str;
Xregister int len;
X{
X	register unsigned long n = 0;
X
X#ifdef DUFF
X
X#define HASHC	n = *str++ + 65599 * n
X
X	if (len > 0) {
X		register int loop = (len + 8 - 1) >> 3;
X
X		switch(len & (8 - 1)) {
X		case 0:	do {
X			HASHC;	case 7:	HASHC;
X		case 6:	HASHC;	case 5:	HASHC;
X		case 4:	HASHC;	case 3:	HASHC;
X		case 2:	HASHC;	case 1:	HASHC;
X			} while (--loop);
X		}
X
X	}
X#else
X	while (len--)
X		n = *str++ + 65599 * n;
X#endif
X	return n;
X}
END_OF_FILE
if test 922 -ne `wc -c <'hash.c'`; then
    echo shar: \"'hash.c'\" unpacked with wrong size!
fi
# end of 'hash.c'
fi
if test -f 'makefile' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'makefile'\"
else
echo shar: Extracting \"'makefile'\" \(1147 characters\)
sed "s/^X//" >'makefile' <<'END_OF_FILE'
X#
X# makefile for public domain ndbm-clone: sdbm
X# DUFF: use duff's device (loop unroll) in parts of the code
X#
XCFLAGS = -O -DSDBM -DDUFF -DBSD42
X#LDFLAGS = -p
X
XOBJS = sdbm.o pair.o hash.o
XSRCS = sdbm.c pair.c hash.c dbu.c dba.c dbd.c util.c
XHDRS = tune.h sdbm.h pair.h
XMISC = README CHANGES COMPARE sdbm.3 dbe.c dbe.1 dbm.c dbm.h biblio \
X       readme.ms readme.ps
X
Xall: dbu dba dbd dbe
X
Xdbu: dbu.o sdbm util.o
X	cc $(LDFLAGS) -o dbu dbu.o util.o libsdbm.a
X
Xdba: dba.o util.o
X	cc $(LDFLAGS) -o dba dba.o util.o
Xdbd: dbd.o util.o
X	cc $(LDFLAGS) -o dbd dbd.o util.o
Xdbe: dbe.o sdbm
X	cc $(LDFLAGS) -o dbe dbe.o libsdbm.a
X
Xsdbm: $(OBJS)
X	ar cr libsdbm.a $(OBJS)
X	ranlib libsdbm.a
X###	cp libsdbm.a /usr/lib/libsdbm.a
X
Xdba.o: sdbm.h
Xdbu.o: sdbm.h
Xutil.o:sdbm.h
X
X$(OBJS): sdbm.h tune.h pair.h
X
X#
X# dbu using berkelezoid ndbm routines [if you have them] for testing
X#
X#x-dbu: dbu.o util.o
X#	cc $(CFLAGS) -o x-dbu dbu.o util.o
Xlint:
X	lint -abchx $(SRCS)
X
Xclean:
X	rm -f *.o mon.out core
X
Xpurge: 	clean
X	rm -f dbu libsdbm.a dbd dba dbe x-dbu *.dir *.pag
X
Xshar:
X	shar $(MISC) makefile $(SRCS) $(HDRS) >SDBM.SHAR
X
Xreadme:
X	nroff -ms readme.ms | col -b >README
END_OF_FILE
if test 1147 -ne `wc -c <'makefile'`; then
    echo shar: \"'makefile'\" unpacked with wrong size!
fi
# end of 'makefile'
fi
if test -f 'pair.c' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'pair.c'\"
else
echo shar: Extracting \"'pair.c'\" \(5720 characters\)
sed "s/^X//" >'pair.c' <<'END_OF_FILE'
X/*
X * sdbm - ndbm work-alike hashed database library
X * based on Per-Aake Larson's Dynamic Hashing algorithms. BIT 18 (1978).
X * author: oz@nexus.yorku.ca
X * status: public domain.
X *
X * page-level routines
X */
X
X#ifndef lint
Xstatic char rcsid[] = "$Id: pair.c,v 1.10 90/12/13 13:00:35 oz Exp $";
X#endif
X
X#include "sdbm.h"
X#include "tune.h"
X#include "pair.h"
X
X#ifndef BSD42
X#include <memory.h>
X#endif
X
X#define exhash(item)	dbm_hash((item).dptr, (item).dsize)
X
X/* 
X * forward 
X */
Xstatic int seepair proto((char *, int, char *, int));
X
X/*
X * page format:
X *	+------------------------------+
X * ino	| n | keyoff | datoff | keyoff |
X * 	+------------+--------+--------+
X *	| datoff | - - - ---->	       |
X *	+--------+---------------------+
X *	|	 F R E E A R E A       |
X *	+--------------+---------------+
X *	|  <---- - - - | data          |
X *	+--------+-----+----+----------+
X *	|  key   | data     | key      |
X *	+--------+----------+----------+
X *
X * calculating the offsets for free area:  if the number
X * of entries (ino[0]) is zero, the offset to the END of
X * the free area is the block size. Otherwise, it is the
X * nth (ino[ino[0]]) entry's offset.
X */
X
Xint
Xfitpair(pag, need)
Xchar *pag;
Xint need;
X{
X	register int n;
X	register int off;
X	register int free;
X	register short *ino = (short *) pag;
X
X	off = ((n = ino[0]) > 0) ? ino[n] : PBLKSIZ;
X	free = off - (n + 1) * sizeof(short);
X	need += 2 * sizeof(short);
X
X	debug(("free %d need %d\n", free, need));
X
X	return need <= free;
X}
X
Xvoid
Xputpair(pag, key, val)
Xchar *pag;
Xdatum key;
Xdatum val;
X{
X	register int n;
X	register int off;
X	register short *ino = (short *) pag;
X
X	off = ((n = ino[0]) > 0) ? ino[n] : PBLKSIZ;
X/*
X * enter the key first
X */
X	off -= key.dsize;
X	(void) memcpy(pag + off, key.dptr, key.dsize);
X	ino[n + 1] = off;
X/*
X * now the data
X */
X	off -= val.dsize;
X	(void) memcpy(pag + off, val.dptr, val.dsize);
X	ino[n + 2] = off;
X/*
X * adjust item count
X */
X	ino[0] += 2;
X}
X
Xdatum
Xgetpair(pag, key)
Xchar *pag;
Xdatum key;
X{
X	register int i;
X	register int n;
X	datum val;
X	register short *ino = (short *) pag;
X
X	if ((n = ino[0]) == 0)
X		return nullitem;
X
X	if ((i = seepair(pag, n, key.dptr, key.dsize)) == 0)
X		return nullitem;
X
X	val.dptr = pag + ino[i + 1];
X	val.dsize = ino[i] - ino[i + 1];
X	return val;
X}
X
X#ifdef SEEDUPS
Xint
Xduppair(pag, key)
Xchar *pag;
Xdatum key;
X{
X	register short *ino = (short *) pag;
X	return ino[0] > 0 && seepair(pag, ino[0], key.dptr, key.dsize) > 0;
X}
X#endif
X
Xdatum
Xgetnkey(pag, num)
Xchar *pag;
Xint num;
X{
X	datum key;
X	register int off;
X	register short *ino = (short *) pag;
X
X	num = num * 2 - 1;
X	if (ino[0] == 0 || num > ino[0])
X		return nullitem;
X
X	off = (num > 1) ? ino[num - 1] : PBLKSIZ;
X
X	key.dptr = pag + ino[num];
X	key.dsize = off - ino[num];
X
X	return key;
X}
X
Xint
Xdelpair(pag, key)
Xchar *pag;
Xdatum key;
X{
X	register int n;
X	register int i;
X	register short *ino = (short *) pag;
X
X	if ((n = ino[0]) == 0)
X		return 0;
X
X	if ((i = seepair(pag, n, key.dptr, key.dsize)) == 0)
X		return 0;
X/*
X * found the key. if it is the last entry
X * [i.e. i == n - 1] we just adjust the entry count.
X * hard case: move all data down onto the deleted pair,
X * shift offsets onto deleted offsets, and adjust them.
X * [note: 0 < i < n]
X */
X	if (i < n - 1) {
X		register int m;
X		register char *dst = pag + (i == 1 ? PBLKSIZ : ino[i - 1]);
X		register char *src = pag + ino[i + 1];
X		register int   zoo = dst - src;
X
X		debug(("free-up %d ", zoo));
X/*
X * shift data/keys down
X */
X		m = ino[i + 1] - ino[n];
X#ifdef DUFF
X#define MOVB 	*--dst = *--src
X
X		if (m > 0) {
X			register int loop = (m + 8 - 1) >> 3;
X
X			switch (m & (8 - 1)) {
X			case 0:	do {
X				MOVB;	case 7:	MOVB;
X			case 6:	MOVB;	case 5:	MOVB;
X			case 4:	MOVB;	case 3:	MOVB;
X			case 2:	MOVB;	case 1:	MOVB;
X				} while (--loop);
X			}
X		}
X#else
X#ifdef MEMMOVE
X		memmove(dst, src, m);
X#else
X		while (m--)
X			*--dst = *--src;
X#endif
X#endif
X/*
X * adjust offset index up
X */
X		while (i < n - 1) {
X			ino[i] = ino[i + 2] + zoo;
X			i++;
X		}
X	}
X	ino[0] -= 2;
X	return 1;
X}
X
X/*
X * search for the key in the page.
X * return offset index in the range 0 < i < n.
X * return 0 if not found.
X */
Xstatic int
Xseepair(pag, n, key, siz)
Xchar *pag;
Xregister int n;
Xregister char *key;
Xregister int siz;
X{
X	register int i;
X	register int off = PBLKSIZ;
X	register short *ino = (short *) pag;
X
X	for (i = 1; i < n; i += 2) {
X		if (siz == off - ino[i] &&
X		    memcmp(key, pag + ino[i], siz) == 0)
X			return i;
X		off = ino[i + 1];
X	}
X	return 0;
X}
X
Xvoid
Xsplpage(pag, new, sbit)
Xchar *pag;
Xchar *new;
Xlong sbit;
X{
X	datum key;
X	datum val;
X
X	register int n;
X	register int off = PBLKSIZ;
X	char cur[PBLKSIZ];
X	register short *ino = (short *) cur;
X
X	(void) memcpy(cur, pag, PBLKSIZ);
X	(void) memset(pag, 0, PBLKSIZ);
X	(void) memset(new, 0, PBLKSIZ);
X
X	n = ino[0];
X	for (ino++; n > 0; ino += 2) {
X		key.dptr = cur + ino[0]; 
X		key.dsize = off - ino[0];
X		val.dptr = cur + ino[1];
X		val.dsize = ino[0] - ino[1];
X/*
X * select the page pointer (by looking at sbit) and insert
X */
X		(void) putpair((exhash(key) & sbit) ? new : pag, key, val);
X
X		off = ino[1];
X		n -= 2;
X	}
X
X	debug(("%d split %d/%d\n", ((short *) cur)[0] / 2, 
X	       ((short *) new)[0] / 2,
X	       ((short *) pag)[0] / 2));
X}
X
X/*
X * check page sanity: 
X * number of entries should be something
X * reasonable, and all offsets in the index should be in order.
X * this could be made more rigorous.
X */
Xint
Xchkpage(pag)
Xchar *pag;
X{
X	register int n;
X	register int off;
X	register short *ino = (short *) pag;
X
X	if ((n = ino[0]) < 0 || n > PBLKSIZ / sizeof(short))
X		return 0;
X
X	if (n > 0) {
X		off = PBLKSIZ;
X		for (ino++; n > 0; ino += 2) {
X			if (ino[0] > off || ino[1] > off ||
X			    ino[1] > ino[0])
X				return 0;
X			off = ino[1];
X			n -= 2;
X		}
X	}
X	return 1;
X}
END_OF_FILE
if test 5720 -ne `wc -c <'pair.c'`; then
    echo shar: \"'pair.c'\" unpacked with wrong size!
fi
# end of 'pair.c'
fi
if test -f 'pair.h' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'pair.h'\"
else
echo shar: Extracting \"'pair.h'\" \(378 characters\)
sed "s/^X//" >'pair.h' <<'END_OF_FILE'
Xextern int fitpair proto((char *, int));
Xextern void  putpair proto((char *, datum, datum));
Xextern datum	getpair proto((char *, datum));
Xextern int  delpair proto((char *, datum));
Xextern int  chkpage proto((char *));
Xextern datum getnkey proto((char *, int));
Xextern void splpage proto((char *, char *, long));
X#ifdef SEEDUPS
Xextern int duppair proto((char *, datum));
X#endif
END_OF_FILE
if test 378 -ne `wc -c <'pair.h'`; then
    echo shar: \"'pair.h'\" unpacked with wrong size!
fi
# end of 'pair.h'
fi
if test -f 'readme.ms' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'readme.ms'\"
else
echo shar: Extracting \"'readme.ms'\" \(11691 characters\)
sed "s/^X//" >'readme.ms' <<'END_OF_FILE'
X.\" tbl | readme.ms | [tn]roff -ms | ...
X.\" note the "C" (courier) and "CB" fonts: you will probably have to
X.\" change these.
X.\" $Id: readme.ms,v 1.1 90/12/13 13:09:15 oz Exp Locker: oz $
X
X.de P1
X.br
X.nr dT 4
X.nf
X.ft C
X.sp .5
X.nr t \\n(dT*\\w'x'u
X.ta 1u*\\ntu 2u*\\ntu 3u*\\ntu 4u*\\ntu 5u*\\ntu 6u*\\ntu 7u*\\ntu 8u*\\ntu 9u*\\ntu 10u*\\ntu 11u*\\ntu 12u*\\ntu 13u*\\ntu 14u*\\ntu
X..
X.de P2
X.br
X.ft 1
X.br
X.sp .5
X.br
X.fi
X..
X.\" CW uses the typewriter/courier font.
X.de CW
X\fC\\$1\\fP\\$2
X..
X
X.\" Footnote numbering [by Henry Spencer]
X.\" <text>\*f for a footnote number..
X.\" .FS
X.\" \*F <footnote text>
X.\" .FE
X.\"
X.ds f \\u\\s-2\\n+f\\s+2\\d
X.nr f 0 1
X.ds F \\n+F.
X.nr F 0 1
X
X.ND
X.LP
X.TL
X\fIsdbm\fP \(em Substitute DBM
X.br
Xor
X.br
XBerkeley \fIndbm\fP for Every UN*X\** Made Simple
X.AU
XOzan (oz) Yigit
X.AI
XThe Guild of PD Software Toolmakers
XToronto - Canada
X.sp
Xoz@nexus.yorku.ca
X.LP
X.FS
XUN*X is not a trademark of any (dis)organization.
X.FE
X.sp 2
X\fIImplementation is the sincerest form of flattery. \(em L. Peter Deutsch\fP
X.SH
XA The Clone of the \fIndbm\fP library
X.PP
XThe sources accompanying this notice \(em \fIsdbm\fP \(em constitute
Xthe first public release (Dec. 1990) of a complete clone of
Xthe Berkeley UN*X \fIndbm\fP library. The \fIsdbm\fP library is meant to
Xclone the proven functionality of \fIndbm\fP as closely as possible,
Xincluding a few improvements. It is practical, easy to understand, and
Xcompatible.
XThe \fIsdbm\fP library is not derived from any licensed, proprietary or
Xcopyrighted software.
X.PP
XThe \fIsdbm\fP implementation is based on a 1978 algorithm
X[Lar78] by P.-A. (Paul) Larson known as ``Dynamic Hashing''.
XIn the course of searching for a substitute for \fIndbm\fP, I
Xprototyped three different external-hashing algorithms [Lar78, Fag79, Lit80]
Xand ultimately chose Larson's algorithm as a basis of the \fIsdbm\fP
Ximplementation. The Bell Labs
X\fIdbm\fP (and therefore \fIndbm\fP) is based on an algorithm invented by
XKen Thompson, [Tho90, Tor87] and predates Larson's work.
X.PP
XThe \fIsdbm\fR programming interface is totally compatible
Xwith \fIndbm\fP and includes a slight improvement in database initialization.
XIt is also expected to be binary-compatible under most UN*X versions that
Xsupport the \fIndbm\fP library.
X.PP
XThe \fIsdbm\fP implementation shares the shortcomings of the \fIndbm\fP
Xlibrary, as a side effect of various simplifications to the original Larson
Xalgorithm. It does produce \fIholes\fP in the page file as it writes
Xpages past the end of file. (Larson's paper include a clever solution to
Xthis problem that is a result of using the hash value directly as a block
Xaddress.) On the other hand, extensive tests seem to indicate that \fIsdbm\fP
Xcreates fewer holes in general, and the resulting pagefiles are
Xsmaller. The \fIsdbm\fP implementation is also faster than \fIndbm\fP
Xin database creation.
XUnlike the \fIndbm\fP, the \fIsdbm\fP
X.CW store
Xoperation will not ``wander away'' trying to split its
Xdata pages to insert a datum that \fIcannot\fP (due to elaborate worst-case
Xsituations) be inserted. (It will fail after a pre-defined number of attempts.)
X.SH
XImportant Compatibility Warning
X.PP
XThe \fIsdbm\fP and \fIndbm\fP
Xlibraries \fIcannot\fP share databases: one cannot read the (dir/pag)
Xdatabase created by the other. This is due to the differences
Xbetween the \fIndbm\fP and \fIsdbm\fP algorithms\**, 
X.FS
XTorek's discussion [Tor87]
Xindicates that \fIdbm/ndbm\fP implementations use the hash
Xvalue to traverse the radix trie differently than \fIsdbm\fP
Xand as a result, the page indexes are generated in \fIdifferent\fP order.
XFor more information, send e-mail to the author.
X.FE
Xand the hash functions
Xused.
XIt is easy to convert between the \fIdbm/ndbm\fP databases and \fIsdbm\fP
Xby ignoring the index completely: see
X.CW dbd ,
X.CW dbu
Xetc.
X.R
X.LP
X.SH
XNotice of Intellectual Property
X.LP
X\fIThe entire\fP sdbm  \fIlibrary package, as authored by me,\fP Ozan S. Yigit,
X\fIis hereby placed in the public domain.\fP As such, the author is not
Xresponsible for the consequences of use of this software, no matter how
Xawful, even if they arise from defects in it. There is no expressed or
Ximplied warranty for the \fIsdbm\fP library.
X.PP
XSince the \fIsdbm\fP
Xlibrary package is in the public domain, this \fIoriginal\fP
Xrelease or any additional public-domain releases of the modified original
Xcannot possibly (by definition) be withheld from you. Also by definition,
XYou (singular) have all the rights to this code (including the right to
Xsell without permission, the right to hoard\**
X.FS
XYou cannot really hoard something that is available to the public at
Xlarge, but try if it makes you feel any better.
X.FE
Xand the right to do other icky things as
Xyou see fit) but those rights are also granted to everyone else.
X.PP
XPlease note that all previous distributions of this software contained
Xa copyright (which is now dropped) to protect its
Xorigins and its current public domain status against any possible claims
Xand/or challenges.
X.SH
XAcknowledgments
X.PP
XMany people have been very helpful and supportive.  A partial list would
Xnecessarily include Rayan Zacherissen (who contributed the man page,
Xand also hacked a MMAP version of \fIsdbm\fP),
XArnold Robbins, Chris Lewis,
XBill Davidsen, Henry Spencer, Geoff Collyer, Rich Salz (who got me started
Xin the first place), Johannes Ruschein
X(who did the minix port) and David Tilbrook. I thank you all.
X.SH
XDistribution Manifest and Notes
X.LP
XThis distribution of \fIsdbm\fP includes (at least) the following:
X.P1
X	CHANGES		change log
X	README		this file.
X	biblio		a small bibliography on external hashing
X	dba.c		a crude (n/s)dbm page file analyzer
X	dbd.c		a crude (n/s)dbm page file dumper (for conversion)
X	dbe.1		man page for dbe.c
X	dbe.c		Janick's database editor
X	dbm.c		a dbm library emulation wrapper for ndbm/sdbm
X	dbm.h		header file for the above
X	dbu.c		a crude db management utility
X	hash.c		hashing function
X	makefile	guess.
X	pair.c		page-level routines (posted earlier)
X	pair.h		header file for the above
X	readme.ms	troff source for the README file
X	sdbm.3		man page
X	sdbm.c		the real thing
X	sdbm.h		header file for the above
X	tune.h		place for tuning & portability thingies
X	util.c		miscellaneous
X.P2
X.PP
X.CW dbu
Xis a simple database manipulation program\** that tries to look
X.FS
XThe 
X.CW dbd ,
X.CW dba ,
X.CW dbu
Xutilities are quick hacks and are not fit for production use. They were
Xdeveloped late one night, just to test out \fIsdbm\fP, and convert some
Xdatabases.
X.FE
Xlike Bell Labs'
X.CW cbt
Xutility. It is currently incomplete in functionality.
XI use
X.CW dbu
Xto test out the routines: it takes (from stdin) tab separated
Xkey/value pairs for commands like
X.CW build
Xor
X.CW insert
Xor takes keys for
Xcommands like
X.CW delete
Xor
X.CW look .
X.P1
X	dbu <build|creat|look|insert|cat|delete> dbmfile
X.P2
X.PP
X.CW dba
Xis a crude analyzer of \fIdbm/sdbm/ndbm\fP
Xpage files. It scans the entire
Xpage file, reporting page level statistics, and totals at the end.
X.PP
X.CW dbd
Xis a crude dump program for \fIdbm/ndbm/sdbm\fP
Xdatabases. It ignores the
Xbitmap, and dumps the data pages in sequence. It can be used to create
Xinput for the
X.CW dbu 
Xutility.
XNote that
X.CW dbd
Xwill skip any NULLs in the key and data
Xfields, thus is unsuitable to convert some peculiar databases that
Xinsist in including the terminating null.
X.PP
XI have also included a copy of the
X.CW dbe
X(\fIndbm\fP DataBase Editor) by Janick Bergeron [janick@bnr.ca] for
Xyour pleasure. You may find it more useful than the little
X.CW dbu
Xutility.
X.PP
X.CW dbm.[ch]
Xis a \fIdbm\fP library emulation on top of \fIndbm\fP
X(and hence suitable for \fIsdbm\fP). Written by Robert Elz.
X.PP
XThe \fIsdbm\fP
Xlibrary has been around in beta test for quite a long time, and from whatever
Xlittle feedback I received (maybe no news is good news), I believe it has been
Xfunctioning without any significant problems. I would, of course, appreciate
Xall fixes and/or improvements. Portability enhancements would especially be
Xuseful.
X.SH
XImplementation Issues
X.PP
XHash functions:
XThe algorithm behind \fIsdbm\fP implementation needs a good bit-scrambling
Xhash function to be effective. I ran into a set of constants for a simple
Xhash function that seem to help \fIsdbm\fP perform better than \fIndbm\fP
Xfor various inputs:
X.P1
X	/*
X	 * polynomial conversion ignoring overflows
X	 * 65599 nice. 65587 even better.
X	 */
X	long
X	dbm_hash(char *str, int len) {
X		register unsigned long n = 0;
X	
X		while (len--)
X			n = n * 65599 + *str++;
X		return n;
X	}
X.P2
X.PP
XThere may be better hash functions for the purposes of dynamic hashing.
XTry your favorite, and check the pagefile. If it contains too many pages
Xwith too many holes, (in relation to this one for example) or if
X\fIsdbm\fP
Xsimply stops working (fails after 
X.CW SPLTMAX
Xattempts to split) when you feed your
XNEWS 
X.CW history
Xfile to it, you probably do not have a good hashing function.
XIf you do better (for different types of input), I would like to know
Xabout the function you use.
X.PP
XBlock sizes: It seems (from various tests on a few machines) that a page
Xfile block size
X.CW PBLKSIZ
Xof 1024 is by far the best for performance, but
Xthis also happens to limit the size of a key/value pair. Depending on your
Xneeds, you may wish to increase the page size, and also adjust
X.CW PAIRMAX
X(the maximum size of a key/value pair allowed: should always be at least
Xthree words smaller than
X.CW PBLKSIZ .)
Xaccordingly. The system-wide version of the library
Xshould probably be
Xconfigured with 1024 (distribution default), as this appears to be sufficient
Xfor most common uses of \fIsdbm\fP.
X.SH
XPortability
X.PP
XThis package has been tested in many different UN*Xes even including minix,
Xand appears to be reasonably portable. This does not mean it will port
Xeasily to non-UN*X systems.
X.SH
XNotes and Miscellaneous
X.PP
XThe \fIsdbm\fP is not a very complicated package, at least not after you
Xfamiliarize yourself with the literature on external hashing. There are
Xother interesting algorithms in existence that ensure (approximately)
Xsingle-read access to a data value associated with any key. These are
Xdirectory-less schemes such as \fIlinear hashing\fP [Lit80] (+ Larson
Xvariations), \fIspiral storage\fP [Mar79] or directory schemes such as
X\fIextensible hashing\fP [Fag79] by Fagin et al. I do hope these sources
Xprovide a reasonable playground for experimentation with other algorithms.
XSee the June 1988 issue of ACM Computing Surveys [Enb88] for an
Xexcellent overview of the field. 
X.PG
X.SH
XReferences
X.LP
X.IP [Lar78] 4m
XP.-A. Larson,
X``Dynamic Hashing'', \fIBIT\fP, vol.  18,  pp. 184-201, 1978.
X.IP [Tho90] 4m
XKen Thompson, \fIprivate communication\fP, Nov. 1990
X.IP [Lit80] 4m
XW. Litwin,
X`` Linear Hashing: A new tool  for  file  and table addressing'',
X\fIProceedings of the 6th Conference on Very Large  Dabatases  (Montreal)\fP,
Xpp.  212-223,  Very Large Database Foundation, Saratoga, Calif., 1980.
X.IP [Fag79] 4m
XR. Fagin, J.  Nievergelt,  N.  Pippinger,  and  H.  R. Strong,
X``Extendible Hashing - A Fast Access Method for Dynamic Files'',
X\fIACM Trans. Database Syst.\fP, vol. 4,  no.3, pp. 315-344, Sept. 1979.
X.IP [Wal84] 4m
XRich Wales,
X``Discussion of "dbm" data base system'', \fIUSENET newsgroup unix.wizards\fP,
XJan. 1984.
X.IP [Tor87] 4m
XChris Torek,
X``Re:  dbm.a  and  ndbm.a  archives'', \fIUSENET newsgroup comp.unix\fP,
X1987.
X.IP [Mar79] 4m
XG. N. Martin,
X``Spiral Storage: Incrementally  Augmentable  Hash  Addressed  Storage'',
X\fITechnical Report #27\fP, University of Varwick, Coventry, U.K., 1979.
X.IP [Enb88] 4m
XR. J. Enbody and H. C. Du,
X``Dynamic Hashing  Schemes'',\fIACM Computing Surveys\fP,
Xvol. 20, no. 2, pp. 85-113, June 1988.
END_OF_FILE
if test 11691 -ne `wc -c <'readme.ms'`; then
    echo shar: \"'readme.ms'\" unpacked with wrong size!
fi
# end of 'readme.ms'
fi
if test -f 'readme.ps' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'readme.ps'\"
else
echo shar: Extracting \"'readme.ps'\" \(33302 characters\)
sed "s/^X//" >'readme.ps' <<'END_OF_FILE'
X%!PS-Adobe-1.0
X%%Creator: yetti:oz (Ozan Yigit)
X%%Title: stdin (ditroff)
X%%CreationDate: Thu Dec 13 15:56:08 1990
X%%EndComments
X% lib/psdit.pro -- prolog for psdit (ditroff) files
X% Copyright (c) 1984, 1985 Adobe Systems Incorporated. All Rights Reserved.
X% last edit: shore Sat Nov 23 20:28:03 1985
X% RCSID: $Header: psdit.pro,v 2.1 85/11/24 12:19:43 shore Rel $
X
X/$DITroff 140 dict def $DITroff begin
X/fontnum 1 def /fontsize 10 def /fontheight 10 def /fontslant 0 def
X/xi {0 72 11 mul translate 72 resolution div dup neg scale 0 0 moveto
X  /fontnum 1 def /fontsize 10 def /fontheight 10 def /fontslant 0 def F
X  /pagesave save def}def
X/PB{save /psv exch def currentpoint translate 
X  resolution 72 div dup neg scale 0 0 moveto}def
X/PE{psv restore}def
X/arctoobig 90 def /arctoosmall .05 def
X/m1 matrix def /m2 matrix def /m3 matrix def /oldmat matrix def
X/tan{dup sin exch cos div}def
X/point{resolution 72 div mul}def
X/dround	{transform round exch round exch itransform}def
X/xT{/devname exch def}def
X/xr{/mh exch def /my exch def /resolution exch def}def
X/xp{}def
X/xs{docsave restore end}def
X/xt{}def
X/xf{/fontname exch def /slotno exch def fontnames slotno get fontname eq not
X {fonts slotno fontname findfont put fontnames slotno fontname put}if}def
X/xH{/fontheight exch def F}def
X/xS{/fontslant exch def F}def
X/s{/fontsize exch def /fontheight fontsize def F}def
X/f{/fontnum exch def F}def
X/F{fontheight 0 le {/fontheight fontsize def}if
X   fonts fontnum get fontsize point 0 0 fontheight point neg 0 0 m1 astore
X   fontslant 0 ne{1 0 fontslant tan 1 0 0 m2 astore m3 concatmatrix}if
X   makefont setfont .04 fontsize point mul 0 dround pop setlinewidth}def
X/X{exch currentpoint exch pop moveto show}def
X/N{3 1 roll moveto show}def
X/Y{exch currentpoint pop exch moveto show}def
X/S{show}def
X/ditpush{}def/ditpop{}def
X/AX{3 -1 roll currentpoint exch pop moveto 0 exch ashow}def
X/AN{4 2 roll moveto 0 exch ashow}def
X/AY{3 -1 roll currentpoint pop exch moveto 0 exch ashow}def
X/AS{0 exch ashow}def
X/MX{currentpoint exch pop moveto}def
X/MY{currentpoint pop exch moveto}def
X/MXY{moveto}def
X/cb{pop}def	% action on unknown char -- nothing for now
X/n{}def/w{}def
X/p{pop showpage pagesave restore /pagesave save def}def
X/abspoint{currentpoint exch pop add exch currentpoint pop add exch}def
X/distance{dup mul exch dup mul add sqrt}def
X/dstroke{currentpoint stroke moveto}def
X/Dl{2 copy gsave rlineto stroke grestore rmoveto}def
X/arcellipse{/diamv exch def /diamh exch def oldmat currentmatrix pop
X currentpoint translate 1 diamv diamh div scale /rad diamh 2 div def
X currentpoint exch rad add exch rad -180 180 arc oldmat setmatrix}def
X/Dc{dup arcellipse dstroke}def
X/De{arcellipse dstroke}def
X/Da{/endv exch def /endh exch def /centerv exch def /centerh exch def
X /cradius centerv centerv mul centerh centerh mul add sqrt def
X /eradius endv endv mul endh endh mul add sqrt def
X /endang endv endh atan def
X /startang centerv neg centerh neg atan def
X /sweep startang endang sub dup 0 lt{360 add}if def
X sweep arctoobig gt
X {/midang startang sweep 2 div sub def /midrad cradius eradius add 2 div def
X  /midh midang cos midrad mul def /midv midang sin midrad mul def
X  midh neg midv neg endh endv centerh centerv midh midv Da
X  currentpoint moveto Da}
X {sweep arctoosmall ge
X  {/controldelt 1 sweep 2 div cos sub 3 sweep 2 div sin mul div 4 mul def
X  centerv neg controldelt mul centerh controldelt mul
X  endv neg controldelt mul centerh add endh add
X  endh controldelt mul centerv add endv add
X  centerh endh add centerv endv add rcurveto dstroke}
X {centerh endh add centerv endv add rlineto dstroke}ifelse}ifelse}def
X
X/Barray 200 array def % 200 values in a wiggle
X/D~{mark}def
X/D~~{counttomark Barray exch 0 exch getinterval astore /Bcontrol exch def pop
X /Blen Bcontrol length def Blen 4 ge Blen 2 mod 0 eq and
X {Bcontrol 0 get Bcontrol 1 get abspoint /Ycont exch def /Xcont exch def
X  Bcontrol 0 2 copy get 2 mul put Bcontrol 1 2 copy get 2 mul put
X  Bcontrol Blen 2 sub 2 copy get 2 mul put
X  Bcontrol Blen 1 sub 2 copy get 2 mul put
X  /Ybi /Xbi currentpoint 3 1 roll def def 0 2 Blen 4 sub
X  {/i exch def
X   Bcontrol i get 3 div Bcontrol i 1 add get 3 div
X   Bcontrol i get 3 mul Bcontrol i 2 add get add 6 div
X   Bcontrol i 1 add get 3 mul Bcontrol i 3 add get add 6 div
X   /Xbi Xcont Bcontrol i 2 add get 2 div add def
X   /Ybi Ycont Bcontrol i 3 add get 2 div add def
X   /Xcont Xcont Bcontrol i 2 add get add def
X   /Ycont Ycont Bcontrol i 3 add get add def
X   Xbi currentpoint pop sub Ybi currentpoint exch pop sub rcurveto
X  }for dstroke}if}def
Xend
X/ditstart{$DITroff begin
X /nfonts 60 def			% NFONTS makedev/ditroff dependent!
X /fonts[nfonts{0}repeat]def
X /fontnames[nfonts{()}repeat]def
X/docsave save def
X}def
X
X% character outcalls
X/oc {/pswid exch def /cc exch def /name exch def
X   /ditwid pswid fontsize mul resolution mul 72000 div def
X   /ditsiz fontsize resolution mul 72 div def
X   ocprocs name known{ocprocs name get exec}{name cb}
X   ifelse}def
X/fractm [.65 0 0 .6 0 0] def
X/fraction
X {/fden exch def /fnum exch def gsave /cf currentfont def
X  cf fractm makefont setfont 0 .3 dm 2 copy neg rmoveto
X  fnum show rmoveto currentfont cf setfont(\244)show setfont fden show 
X  grestore ditwid 0 rmoveto} def
X/oce {grestore ditwid 0 rmoveto}def
X/dm {ditsiz mul}def
X/ocprocs 50 dict def ocprocs begin
X(14){(1)(4)fraction}def
X(12){(1)(2)fraction}def
X(34){(3)(4)fraction}def
X(13){(1)(3)fraction}def
X(23){(2)(3)fraction}def
X(18){(1)(8)fraction}def
X(38){(3)(8)fraction}def
X(58){(5)(8)fraction}def
X(78){(7)(8)fraction}def
X(sr){gsave 0 .06 dm rmoveto(\326)show oce}def
X(is){gsave 0 .15 dm rmoveto(\362)show oce}def
X(->){gsave 0 .02 dm rmoveto(\256)show oce}def
X(<-){gsave 0 .02 dm rmoveto(\254)show oce}def
X(==){gsave 0 .05 dm rmoveto(\272)show oce}def
Xend
X
X% an attempt at a PostScript FONT to implement ditroff special chars
X% this will enable us to 
X%	cache the little buggers
X%	generate faster, more compact PS out of psdit
X%	confuse everyone (including myself)!
X50 dict dup begin
X/FontType 3 def
X/FontName /DIThacks def
X/FontMatrix [.001 0 0 .001 0 0] def
X/FontBBox [-260 -260 900 900] def% a lie but ...
X/Encoding 256 array def
X0 1 255{Encoding exch /.notdef put}for
XEncoding
X dup 8#040/space put %space
X dup 8#110/rc put %right ceil
X dup 8#111/lt put %left  top curl
X dup 8#112/bv put %bold vert
X dup 8#113/lk put %left  mid curl
X dup 8#114/lb put %left  bot curl
X dup 8#115/rt put %right top curl
X dup 8#116/rk put %right mid curl
X dup 8#117/rb put %right bot curl
X dup 8#120/rf put %right floor
X dup 8#121/lf put %left  floor
X dup 8#122/lc put %left  ceil
X dup 8#140/sq put %square
X dup 8#141/bx put %box
X dup 8#142/ci put %circle
X dup 8#143/br put %box rule
X dup 8#144/rn put %root extender
X dup 8#145/vr put %vertical rule
X dup 8#146/ob put %outline bullet
X dup 8#147/bu put %bullet
X dup 8#150/ru put %rule
X dup 8#151/ul put %underline
X pop
X/DITfd 100 dict def
X/BuildChar{0 begin
X /cc exch def /fd exch def
X /charname fd /Encoding get cc get def
X /charwid fd /Metrics get charname get def
X /charproc fd /CharProcs get charname get def
X charwid 0 fd /FontBBox get aload pop setcachedevice
X 2 setlinejoin 40 setlinewidth
X newpath 0 0 moveto gsave charproc grestore
X end}def
X/BuildChar load 0 DITfd put
X%/UniqueID 5 def
X/CharProcs 50 dict def
XCharProcs begin
X/space{}def
X/.notdef{}def
X/ru{500 0 rls}def
X/rn{0 840 moveto 500 0 rls}def
X/vr{0 800 moveto 0 -770 rls}def
X/bv{0 800 moveto 0 -1000 rls}def
X/br{0 750 moveto 0 -1000 rls}def
X/ul{0 -140 moveto 500 0 rls}def
X/ob{200 250 rmoveto currentpoint newpath 200 0 360 arc closepath stroke}def
X/bu{200 250 rmoveto currentpoint newpath 200 0 360 arc closepath fill}def
X/sq{80 0 rmoveto currentpoint dround newpath moveto
X    640 0 rlineto 0 640 rlineto -640 0 rlineto closepath stroke}def
X/bx{80 0 rmoveto currentpoint dround newpath moveto
X    640 0 rlineto 0 640 rlineto -640 0 rlineto closepath fill}def
X/ci{500 360 rmoveto currentpoint newpath 333 0 360 arc
X    50 setlinewidth stroke}def
X
X/lt{0 -200 moveto 0 550 rlineto currx 800 2cx s4 add exch s4 a4p stroke}def
X/lb{0 800 moveto 0 -550 rlineto currx -200 2cx s4 add exch s4 a4p stroke}def
X/rt{0 -200 moveto 0 550 rlineto currx 800 2cx s4 sub exch s4 a4p stroke}def
X/rb{0 800 moveto 0 -500 rlineto currx -200 2cx s4 sub exch s4 a4p stroke}def
X/lk{0 800 moveto 0 300 -300 300 s4 arcto pop pop 1000 sub
X    0 300 4 2 roll s4 a4p 0 -200 lineto stroke}def
X/rk{0 800 moveto 0 300 s2 300 s4 arcto pop pop 1000 sub
X    0 300 4 2 roll s4 a4p 0 -200 lineto stroke}def
X/lf{0 800 moveto 0 -1000 rlineto s4 0 rls}def
X/rf{0 800 moveto 0 -1000 rlineto s4 neg 0 rls}def
X/lc{0 -200 moveto 0 1000 rlineto s4 0 rls}def
X/rc{0 -200 moveto 0 1000 rlineto s4 neg 0 rls}def
Xend
X
X/Metrics 50 dict def Metrics begin
X/.notdef 0 def
X/space 500 def
X/ru 500 def
X/br 0 def
X/lt 416 def
X/lb 416 def
X/rt 416 def
X/rb 416 def
X/lk 416 def
X/rk 416 def
X/rc 416 def
X/lc 416 def
X/rf 416 def
X/lf 416 def
X/bv 416 def
X/ob 350 def
X/bu 350 def
X/ci 750 def
X/bx 750 def
X/sq 750 def
X/rn 500 def
X/ul 500 def
X/vr 0 def
Xend
X
XDITfd begin
X/s2 500 def /s4 250 def /s3 333 def
X/a4p{arcto pop pop pop pop}def
X/2cx{2 copy exch}def
X/rls{rlineto stroke}def
X/currx{currentpoint pop}def
X/dround{transform round exch round exch itransform} def
Xend
Xend
X/DIThacks exch definefont pop
Xditstart
X(psc)xT
X576 1 1 xr
X1(Times-Roman)xf 1 f
X2(Times-Italic)xf 2 f
X3(Times-Bold)xf 3 f
X4(Times-BoldItalic)xf 4 f
X5(Helvetica)xf 5 f
X6(Helvetica-Bold)xf 6 f
X7(Courier)xf 7 f
X8(Courier-Bold)xf 8 f
X9(Symbol)xf 9 f
X10(DIThacks)xf 10 f
X10 s
X1 f
Xxi
X%%EndProlog
X
X%%Page: 1 1
X10 s 0 xH 0 xS 1 f
X8 s
X2 f
X12 s
X1778 672(sdbm)N
X3 f
X2004(\320)X
X2124(Substitute)X
X2563(DBM)X
X2237 768(or)N
X1331 864(Berkeley)N
X2 f
X1719(ndbm)X
X3 f
X1956(for)X
X2103(Every)X
X2373(UN*X)X
X1 f
X10 s
X2628 832(1)N
X3 f
X12 s
X2692 864(Made)N
X2951(Simple)X
X2 f
X10 s
X2041 1056(Ozan)N
X2230(\(oz\))X
X2375(Yigit)X
X1 f
X1658 1200(The)N
X1803(Guild)X
X2005(of)X
X2092(PD)X
X2214(Software)X
X2524(Toolmakers)X
X2000 1296(Toronto)N
X2278(-)X
X2325(Canada)X
X1965 1488(oz@nexus.yorku.ca)N
X2 f
X555 1804(Implementation)N
X1078(is)X
X1151(the)X
X1269(sincerest)X
X1574(form)X
X1745(of)X
X1827(\257attery.)X
X2094(\320)X
X2185(L.)X
X2269(Peter)X
X2463(Deutsch)X
X3 f
X555 1996(A)N
X633(The)X
X786(Clone)X
X1006(of)X
X1093(the)X
X2 f
X1220(ndbm)X
X3 f
X1418(library)X
X1 f
X755 2120(The)N
X903(sources)X
X1167(accompanying)X
X1658(this)X
X1796(notice)X
X2015(\320)X
X2 f
X2118(sdbm)X
X1 f
X2309(\320)X
X2411(constitute)X
X2744(the)X
X2864(\256rst)X
X3010(public)X
X3232(release)X
X3478(\(Dec.)X
X3677(1990\))X
X3886(of)X
X3975(a)X
X555 2216(complete)N
X874(clone)X
X1073(of)X
X1165(the)X
X1288(Berkeley)X
X1603(UN*X)X
X2 f
X1842(ndbm)X
X1 f
X2045(library.)X
X2304(The)X
X2 f
X2454(sdbm)X
X1 f
X2648(library)X
X2887(is)X
X2965(meant)X
X3186(to)X
X3273(clone)X
X3472(the)X
X3594(proven)X
X3841(func-)X
X555 2312(tionality)N
X846(of)X
X2 f
X938(ndbm)X
X1 f
X1141(as)X
X1233(closely)X
X1485(as)X
X1576(possible,)X
X1882(including)X
X2208(a)X
X2268(few)X
X2413(improvements.)X
X2915(It)X
X2988(is)X
X3065(practical,)X
X3386(easy)X
X3553(to)X
X3639(understand,)X
X555 2408(and)N
X691(compatible.)X
X1107(The)X
X2 f
X1252(sdbm)X
X1 f
X1441(library)X
X1675(is)X
X1748(not)X
X1870(derived)X
X2131(from)X
X2307(any)X
X2443(licensed,)X
X2746(proprietary)X
X3123(or)X
X3210(copyrighted)X
X3613(software.)X
X755 2532(The)N
X2 f
X910(sdbm)X
X1 f
X1109(implementation)X
X1641(is)X
X1723(based)X
X1935(on)X
X2044(a)X
X2109(1978)X
X2298(algorithm)X
X2638([Lar78])X
X2913(by)X
X3022(P.-A.)X
X3220(\(Paul\))X
X3445(Larson)X
X3697(known)X
X3944(as)X
X555 2628(``Dynamic)N
X934(Hashing''.)X
X1326(In)X
X1424(the)X
X1553(course)X
X1794(of)X
X1892(searching)X
X2231(for)X
X2355(a)X
X2421(substitute)X
X2757(for)X
X2 f
X2881(ndbm)X
X1 f
X3059(,)X
X3109(I)X
X3166(prototyped)X
X3543(three)X
X3734(different)X
X555 2724(external-hashing)N
X1119(algorithms)X
X1490([Lar78,)X
X1758(Fag79,)X
X2007(Lit80])X
X2236(and)X
X2381(ultimately)X
X2734(chose)X
X2946(Larson's)X
X3256(algorithm)X
X3596(as)X
X3692(a)X
X3756(basis)X
X3944(of)X
X555 2820(the)N
X2 f
X680(sdbm)X
X1 f
X875(implementation.)X
X1423(The)X
X1574(Bell)X
X1733(Labs)X
X2 f
X1915(dbm)X
X1 f
X2079(\(and)X
X2248(therefore)X
X2 f
X2565(ndbm)X
X1 f
X2743(\))X
X2796(is)X
X2875(based)X
X3084(on)X
X3190(an)X
X3292(algorithm)X
X3629(invented)X
X3931(by)X
X555 2916(Ken)N
X709(Thompson,)X
X1091([Tho90,)X
X1367(Tor87])X
X1610(and)X
X1746(predates)X
X2034(Larson's)X
X2335(work.)X
X755 3040(The)N
X2 f
X903(sdbm)X
X1 f
X1095(programming)X
X1553(interface)X
X1857(is)X
X1932(totally)X
X2158(compatible)X
X2536(with)X
X2 f
X2700(ndbm)X
X1 f
X2900(and)X
X3038(includes)X
X3327(a)X
X3385(slight)X
X3584(improvement)X
X555 3136(in)N
X641(database)X
X942(initialization.)X
X1410(It)X
X1483(is)X
X1560(also)X
X1713(expected)X
X2023(to)X
X2109(be)X
X2208(binary-compatible)X
X2819(under)X
X3025(most)X
X3203(UN*X)X
X3440(versions)X
X3730(that)X
X3873(sup-)X
X555 3232(port)N
X704(the)X
X2 f
X822(ndbm)X
X1 f
X1020(library.)X
X755 3356(The)N
X2 f
X909(sdbm)X
X1 f
X1107(implementation)X
X1638(shares)X
X1868(the)X
X1995(shortcomings)X
X2455(of)X
X2551(the)X
X2 f
X2678(ndbm)X
X1 f
X2885(library,)X
X3148(as)X
X3244(a)X
X3309(side)X
X3467(effect)X
X3680(of)X
X3775(various)X
X555 3452(simpli\256cations)N
X1046(to)X
X1129(the)X
X1248(original)X
X1518(Larson)X
X1762(algorithm.)X
X2114(It)X
X2183(does)X
X2350(produce)X
X2 f
X2629(holes)X
X1 f
X2818(in)X
X2900(the)X
X3018(page)X
X3190(\256le)X
X3312(as)X
X3399(it)X
X3463(writes)X
X3679(pages)X
X3882(past)X
X555 3548(the)N
X680(end)X
X823(of)X
X917(\256le.)X
X1066(\(Larson's)X
X1400(paper)X
X1605(include)X
X1867(a)X
X1929(clever)X
X2152(solution)X
X2435(to)X
X2523(this)X
X2664(problem)X
X2957(that)X
X3103(is)X
X3182(a)X
X3244(result)X
X3448(of)X
X3541(using)X
X3740(the)X
X3864(hash)X
X555 3644(value)N
X758(directly)X
X1032(as)X
X1128(a)X
X1193(block)X
X1400(address.\))X
X1717(On)X
X1844(the)X
X1971(other)X
X2165(hand,)X
X2370(extensive)X
X2702(tests)X
X2873(seem)X
X3067(to)X
X3158(indicate)X
X3441(that)X
X2 f
X3590(sdbm)X
X1 f
X3787(creates)X
X555 3740(fewer)N
X762(holes)X
X954(in)X
X1039(general,)X
X1318(and)X
X1456(the)X
X1576(resulting)X
X1878(page\256les)X
X2185(are)X
X2306(smaller.)X
X2584(The)X
X2 f
X2731(sdbm)X
X1 f
X2922(implementation)X
X3446(is)X
X3521(also)X
X3672(faster)X
X3873(than)X
X2 f
X555 3836(ndbm)N
X1 f
X757(in)X
X843(database)X
X1144(creation.)X
X1467(Unlike)X
X1709(the)X
X2 f
X1831(ndbm)X
X1 f
X2009(,)X
X2053(the)X
X2 f
X2175(sdbm)X
X7 f
X2396(store)X
X1 f
X2660(operation)X
X2987(will)X
X3134(not)X
X3259(``wander)X
X3573(away'')X
X3820(trying)X
X555 3932(to)N
X642(split)X
X804(its)X
X904(data)X
X1063(pages)X
X1271(to)X
X1358(insert)X
X1561(a)X
X1622(datum)X
X1847(that)X
X2 f
X1992(cannot)X
X1 f
X2235(\(due)X
X2403(to)X
X2490(elaborate)X
X2810(worst-case)X
X3179(situations\))X
X3537(be)X
X3637(inserted.)X
X3935(\(It)X
X555 4028(will)N
X699(fail)X
X826(after)X
X994(a)X
X1050(pre-de\256ned)X
X1436(number)X
X1701(of)X
X1788(attempts.\))X
X3 f
X555 4220(Important)N
X931(Compatibility)X
X1426(Warning)X
X1 f
X755 4344(The)N
X2 f
X904(sdbm)X
X1 f
X1097(and)X
X2 f
X1237(ndbm)X
X1 f
X1439(libraries)X
X2 f
X1726(cannot)X
X1 f
X1968(share)X
X2162(databases:)X
X2515(one)X
X2654(cannot)X
X2891(read)X
X3053(the)X
X3174(\(dir/pag\))X
X3478(database)X
X3778(created)X
X555 4440(by)N
X657(the)X
X777(other.)X
X984(This)X
X1148(is)X
X1222(due)X
X1359(to)X
X1442(the)X
X1561(differences)X
X1940(between)X
X2229(the)X
X2 f
X2348(ndbm)X
X1 f
X2547(and)X
X2 f
X2684(sdbm)X
X1 f
X2874(algorithms)X
X8 s
X3216 4415(2)N
X10 s
X4440(,)Y
X3289(and)X
X3426(the)X
X3545(hash)X
X3713(functions)X
X555 4536(used.)N
X769(It)X
X845(is)X
X925(easy)X
X1094(to)X
X1182(convert)X
X1449(between)X
X1743(the)X
X2 f
X1867(dbm/ndbm)X
X1 f
X2231(databases)X
X2565(and)X
X2 f
X2707(sdbm)X
X1 f
X2902(by)X
X3008(ignoring)X
X3305(the)X
X3429(index)X
X3633(completely:)X
X555 4632(see)N
X7 f
X706(dbd)X
X1 f
X(,)S
X7 f
X918(dbu)X
X1 f
X1082(etc.)X
X3 f
X555 4852(Notice)N
X794(of)X
X881(Intellectual)X
X1288(Property)X
X2 f
X555 4976(The)N
X696(entire)X
X1 f
X904(sdbm)X
X2 f
X1118(library)X
X1361(package,)X
X1670(as)X
X1762(authored)X
X2072(by)X
X2169(me,)X
X1 f
X2304(Ozan)X
X2495(S.)X
X2580(Yigit,)X
X2 f
X2785(is)X
X2858(hereby)X
X3097(placed)X
X3331(in)X
X3413(the)X
X3531(public)X
X3751(domain.)X
X1 f
X555 5072(As)N
X670(such,)X
X863(the)X
X987(author)X
X1218(is)X
X1297(not)X
X1425(responsible)X
X1816(for)X
X1936(the)X
X2060(consequences)X
X2528(of)X
X2621(use)X
X2754(of)X
X2847(this)X
X2988(software,)X
X3310(no)X
X3415(matter)X
X3645(how)X
X3808(awful,)X
X555 5168(even)N
X727(if)X
X796(they)X
X954(arise)X
X1126(from)X
X1302(defects)X
X1550(in)X
X1632(it.)X
X1716(There)X
X1924(is)X
X1997(no)X
X2097(expressed)X
X2434(or)X
X2521(implied)X
X2785(warranty)X
X3091(for)X
X3205(the)X
X2 f
X3323(sdbm)X
X1 f
X3512(library.)X
X8 s
X10 f
X555 5316(hhhhhhhhhhhhhhhhhh)N
X6 s
X1 f
X635 5391(1)N
X8 s
X691 5410(UN*X)N
X877(is)X
X936(not)X
X1034(a)X
X1078(trademark)X
X1352(of)X
X1421(any)X
X1529(\(dis\)organization.)X
X6 s
X635 5485(2)N
X8 s
X691 5504(Torek's)N
X908(discussion)X
X1194([Tor87])X
X1411(indicates)X
X1657(that)X
X2 f
X1772(dbm/ndbm)X
X1 f
X2061(implementations)X
X2506(use)X
X2609(the)X
X2705(hash)X
X2840(value)X
X2996(to)X
X3064(traverse)X
X3283(the)X
X3379(radix)X
X3528(trie)X
X3631(dif-)X
X555 5584(ferently)N
X772(than)X
X2 f
X901(sdbm)X
X1 f
X1055(and)X
X1166(as)X
X1238(a)X
X1285(result,)X
X1462(the)X
X1559(page)X
X1698(indexes)X
X1912(are)X
X2008(generated)X
X2274(in)X
X2 f
X2343(different)X
X1 f
X2579(order.)X
X2764(For)X
X2872(more)X
X3021(information,)X
X3357(send)X
X3492(e-mail)X
X3673(to)X
X555 5664(the)N
X649(author.)X
X
X2 p
X%%Page: 2 2
X8 s 0 xH 0 xS 1 f
X10 s
X2216 384(-)N
X2263(2)X
X2323(-)X
X755 672(Since)N
X971(the)X
X2 f
X1107(sdbm)X
X1 f
X1314(library)X
X1566(package)X
X1868(is)X
X1959(in)X
X2058(the)X
X2193(public)X
X2430(domain,)X
X2727(this)X
X2 f
X2879(original)X
X1 f
X3173(release)X
X3434(or)X
X3538(any)X
X3691(additional)X
X555 768(public-domain)N
X1045(releases)X
X1323(of)X
X1413(the)X
X1534(modi\256ed)X
X1841(original)X
X2112(cannot)X
X2348(possibly)X
X2636(\(by)X
X2765(de\256nition\))X
X3120(be)X
X3218(withheld)X
X3520(from)X
X3698(you.)X
X3860(Also)X
X555 864(by)N
X659(de\256nition,)X
X1009(You)X
X1170(\(singular\))X
X1505(have)X
X1680(all)X
X1783(the)X
X1904(rights)X
X2109(to)X
X2194(this)X
X2332(code)X
X2507(\(including)X
X2859(the)X
X2980(right)X
X3154(to)X
X3239(sell)X
X3373(without)X
X3640(permission,)X
X555 960(the)N
X679(right)X
X856(to)X
X944(hoard)X
X8 s
X1127 935(3)N
X10 s
X1185 960(and)N
X1327(the)X
X1451(right)X
X1628(to)X
X1716(do)X
X1821(other)X
X2011(icky)X
X2174(things)X
X2394(as)X
X2486(you)X
X2631(see)X
X2759(\256t\))X
X2877(but)X
X3004(those)X
X3198(rights)X
X3405(are)X
X3529(also)X
X3683(granted)X
X3949(to)X
X555 1056(everyone)N
X870(else.)X
X755 1180(Please)N
X997(note)X
X1172(that)X
X1329(all)X
X1446(previous)X
X1759(distributions)X
X2195(of)X
X2298(this)X
X2449(software)X
X2762(contained)X
X3110(a)X
X3182(copyright)X
X3525(\(which)X
X3784(is)X
X3873(now)X
X555 1276(dropped\))N
X868(to)X
X953(protect)X
X1199(its)X
X1297(origins)X
X1542(and)X
X1681(its)X
X1779(current)X
X2030(public)X
X2253(domain)X
X2516(status)X
X2721(against)X
X2970(any)X
X3108(possible)X
X3392(claims)X
X3623(and/or)X
X3850(chal-)X
X555 1372(lenges.)N
X3 f
X555 1564(Acknowledgments)N
X1 f
X755 1688(Many)N
X966(people)X
X1204(have)X
X1380(been)X
X1556(very)X
X1723(helpful)X
X1974(and)X
X2114(supportive.)X
X2515(A)X
X2596(partial)X
X2824(list)X
X2944(would)X
X3167(necessarily)X
X3547(include)X
X3806(Rayan)X
X555 1784(Zacherissen)N
X963(\(who)X
X1152(contributed)X
X1541(the)X
X1663(man)X
X1824(page,)X
X2019(and)X
X2158(also)X
X2310(hacked)X
X2561(a)X
X2620(MMAP)X
X2887(version)X
X3146(of)X
X2 f
X3236(sdbm)X
X1 f
X3405(\),)X
X3475(Arnold)X
X3725(Robbins,)X
X555 1880(Chris)N
X763(Lewis,)X
X1013(Bill)X
X1166(Davidsen,)X
X1523(Henry)X
X1758(Spencer,)X
X2071(Geoff)X
X2293(Collyer,)X
X2587(Rich)X
X2772(Salz)X
X2944(\(who)X
X3143(got)X
X3279(me)X
X3411(started)X
X3659(in)X
X3755(the)X
X3887(\256rst)X
X555 1976(place\),)N
X792(Johannes)X
X1106(Ruschein)X
X1424(\(who)X
X1609(did)X
X1731(the)X
X1849(minix)X
X2055(port\))X
X2231(and)X
X2367(David)X
X2583(Tilbrook.)X
X2903(I)X
X2950(thank)X
X3148(you)X
X3288(all.)X
X3 f
X555 2168(Distribution)N
X992(Manifest)X
X1315(and)X
X1463(Notes)X
X1 f
X555 2292(This)N
X717(distribution)X
X1105(of)X
X2 f
X1192(sdbm)X
X1 f
X1381(includes)X
X1668(\(at)X
X1773(least\))X
X1967(the)X
X2085(following:)X
X7 f
X747 2436(CHANGES)N
X1323(change)X
X1659(log)X
X747 2532(README)N
X1323(this)X
X1563(file.)X
X747 2628(biblio)N
X1323(a)X
X1419(small)X
X1707(bibliography)X
X2331(on)X
X2475(external)X
X2907(hashing)X
X747 2724(dba.c)N
X1323(a)X
X1419(crude)X
X1707(\(n/s\)dbm)X
X2139(page)X
X2379(file)X
X2619(analyzer)X
X747 2820(dbd.c)N
X1323(a)X
X1419(crude)X
X1707(\(n/s\)dbm)X
X2139(page)X
X2379(file)X
X2619(dumper)X
X2955(\(for)X
X3195(conversion\))X
X747 2916(dbe.1)N
X1323(man)X
X1515(page)X
X1755(for)X
X1947(dbe.c)X
X747 3012(dbe.c)N
X1323(Janick's)X
X1755(database)X
X2187(editor)X
X747 3108(dbm.c)N
X1323(a)X
X1419(dbm)X
X1611(library)X
X1995(emulation)X
X2475(wrapper)X
X2859(for)X
X3051(ndbm/sdbm)X
X747 3204(dbm.h)N
X1323(header)X
X1659(file)X
X1899(for)X
X2091(the)X
X2283(above)X
X747 3300(dbu.c)N
X1323(a)X
X1419(crude)X
X1707(db)X
X1851(management)X
X2379(utility)X
X747 3396(hash.c)N
X1323(hashing)X
X1707(function)X
X747 3492(makefile)N
X1323(guess.)X
X747 3588(pair.c)N
X1323(page-level)X
X1851(routines)X
X2283(\(posted)X
X2667(earlier\))X
X747 3684(pair.h)N
X1323(header)X
X1659(file)X
X1899(for)X
X2091(the)X
X2283(above)X
X747 3780(readme.ms)N
X1323(troff)X
X1611(source)X
X1947(for)X
X2139(the)X
X2331(README)X
X2667(file)X
X747 3876(sdbm.3)N
X1323(man)X
X1515(page)X
X747 3972(sdbm.c)N
X1323(the)X
X1515(real)X
X1755(thing)X
X747 4068(sdbm.h)N
X1323(header)X
X1659(file)X
X1899(for)X
X2091(the)X
X2283(above)X
X747 4164(tune.h)N
X1323(place)X
X1611(for)X
X1803(tuning)X
X2139(&)X
X2235(portability)X
X2811(thingies)X
X747 4260(util.c)N
X1323(miscellaneous)X
X755 4432(dbu)N
X1 f
X924(is)X
X1002(a)X
X1063(simple)X
X1301(database)X
X1603(manipulation)X
X2050(program)X
X8 s
X2322 4407(4)N
X10 s
X2379 4432(that)N
X2524(tries)X
X2687(to)X
X2774(look)X
X2941(like)X
X3086(Bell)X
X3244(Labs')X
X7 f
X3480(cbt)X
X1 f
X3649(utility.)X
X3884(It)X
X3958(is)X
X555 4528(currently)N
X867(incomplete)X
X1245(in)X
X1329(functionality.)X
X1800(I)X
X1849(use)X
X7 f
X2006(dbu)X
X1 f
X2172(to)X
X2255(test)X
X2387(out)X
X2510(the)X
X2629(routines:)X
X2930(it)X
X2995(takes)X
X3181(\(from)X
X3385(stdin\))X
X3588(tab)X
X3707(separated)X
X555 4624(key/value)N
X898(pairs)X
X1085(for)X
X1210(commands)X
X1587(like)X
X7 f
X1765(build)X
X1 f
X2035(or)X
X7 f
X2160(insert)X
X1 f
X2478(or)X
X2575(takes)X
X2770(keys)X
X2947(for)X
X3071(commands)X
X3448(like)X
X7 f
X3626(delete)X
X1 f
X3944(or)X
X7 f
X555 4720(look)N
X1 f
X(.)S
X7 f
X747 4864(dbu)N
X939(<build|creat|look|insert|cat|delete>)X
X2715(dbmfile)X
X755 5036(dba)N
X1 f
X927(is)X
X1008(a)X
X1072(crude)X
X1279(analyzer)X
X1580(of)X
X2 f
X1675(dbm/sdbm/ndbm)X
X1 f
X2232(page)X
X2412(\256les.)X
X2593(It)X
X2670(scans)X
X2872(the)X
X2998(entire)X
X3209(page)X
X3389(\256le,)X
X3538(reporting)X
X3859(page)X
X555 5132(level)N
X731(statistics,)X
X1046(and)X
X1182(totals)X
X1375(at)X
X1453(the)X
X1571(end.)X
X7 f
X755 5256(dbd)N
X1 f
X925(is)X
X1004(a)X
X1066(crude)X
X1271(dump)X
X1479(program)X
X1777(for)X
X2 f
X1897(dbm/ndbm/sdbm)X
X1 f
X2452(databases.)X
X2806(It)X
X2881(ignores)X
X3143(the)X
X3267(bitmap,)X
X3534(and)X
X3675(dumps)X
X3913(the)X
X555 5352(data)N
X717(pages)X
X928(in)X
X1018(sequence.)X
X1361(It)X
X1437(can)X
X1576(be)X
X1679(used)X
X1853(to)X
X1942(create)X
X2162(input)X
X2353(for)X
X2474(the)X
X7 f
X2627(dbu)X
X1 f
X2798(utility.)X
X3055(Note)X
X3238(that)X
X7 f
X3413(dbd)X
X1 f
X3584(will)X
X3735(skip)X
X3895(any)X
X8 s
X10 f
X555 5432(hhhhhhhhhhhhhhhhhh)N
X6 s
X1 f
X635 5507(3)N
X8 s
X691 5526(You)N
X817(cannot)X
X1003(really)X
X1164(hoard)X
X1325(something)X
X1608(that)X
X1720(is)X
X1779(available)X
X2025(to)X
X2091(the)X
X2185(public)X
X2361(at)X
X2423(large,)X
X2582(but)X
X2680(try)X
X2767(if)X
X2822(it)X
X2874(makes)X
X3053(you)X
X3165(feel)X
X3276(any)X
X3384(better.)X
X6 s
X635 5601(4)N
X8 s
X691 5620(The)N
X7 f
X829(dbd)X
X1 f
X943(,)X
X7 f
X998(dba)X
X1 f
X1112(,)X
X7 f
X1167(dbu)X
X1 f
X1298(utilities)X
X1508(are)X
X1602(quick)X
X1761(hacks)X
X1923(and)X
X2032(are)X
X2126(not)X
X2225(\256t)X
X2295(for)X
X2385(production)X
X2678(use.)X
X2795(They)X
X2942(were)X
X3081(developed)X
X3359(late)X
X3467(one)X
X3575(night,)X
X555 5700(just)N
X664(to)X
X730(test)X
X835(out)X
X2 f
X933(sdbm)X
X1 f
X1068(,)X
X1100(and)X
X1208(convert)X
X1415(some)X
X1566(databases.)X
X
X3 p
X%%Page: 3 3
X8 s 0 xH 0 xS 1 f
X10 s
X2216 384(-)N
X2263(3)X
X2323(-)X
X555 672(NULLs)N
X821(in)X
X903(the)X
X1021(key)X
X1157(and)X
X1293(data)X
X1447(\256elds,)X
X1660(thus)X
X1813(is)X
X1886(unsuitable)X
X2235(to)X
X2317(convert)X
X2578(some)X
X2767(peculiar)X
X3046(databases)X
X3374(that)X
X3514(insist)X
X3702(in)X
X3784(includ-)X
X555 768(ing)N
X677(the)X
X795(terminating)X
X1184(null.)X
X755 892(I)N
X841(have)X
X1052(also)X
X1240(included)X
X1575(a)X
X1670(copy)X
X1885(of)X
X2011(the)X
X7 f
X2195(dbe)X
X1 f
X2397(\()X
X2 f
X2424(ndbm)X
X1 f
X2660(DataBase)X
X3026(Editor\))X
X3311(by)X
X3449(Janick)X
X3712(Bergeron)X
X555 988([janick@bnr.ca])N
X1098(for)X
X1212(your)X
X1379(pleasure.)X
X1687(You)X
X1845(may)X
X2003(\256nd)X
X2147(it)X
X2211(more)X
X2396(useful)X
X2612(than)X
X2770(the)X
X2888(little)X
X7 f
X3082(dbu)X
X1 f
X3246(utility.)X
X7 f
X755 1112(dbm.[ch])N
X1 f
X1169(is)X
X1252(a)X
X2 f
X1318(dbm)X
X1 f
X1486(library)X
X1730(emulation)X
X2079(on)X
X2188(top)X
X2319(of)X
X2 f
X2415(ndbm)X
X1 f
X2622(\(and)X
X2794(hence)X
X3011(suitable)X
X3289(for)X
X2 f
X3412(sdbm)X
X1 f
X3581(\).)X
X3657(Written)X
X3931(by)X
X555 1208(Robert)N
X793(Elz.)X
X755 1332(The)N
X2 f
X901(sdbm)X
X1 f
X1090(library)X
X1324(has)X
X1451(been)X
X1623(around)X
X1866(in)X
X1948(beta)X
X2102(test)X
X2233(for)X
X2347(quite)X
X2527(a)X
X2583(long)X
X2745(time,)X
X2927(and)X
X3063(from)X
X3239(whatever)X
X3554(little)X
X3720(feedback)X
X555 1428(I)N
X609(received)X
X909(\(maybe)X
X1177(no)X
X1284(news)X
X1476(is)X
X1555(good)X
X1741(news\),)X
X1979(I)X
X2032(believe)X
X2290(it)X
X2360(has)X
X2493(been)X
X2671(functioning)X
X3066(without)X
X3336(any)X
X3478(signi\256cant)X
X3837(prob-)X
X555 1524(lems.)N
X752(I)X
X805(would,)X
X1051(of)X
X1144(course,)X
X1400(appreciate)X
X1757(all)X
X1863(\256xes)X
X2040(and/or)X
X2271(improvements.)X
X2774(Portability)X
X3136(enhancements)X
X3616(would)X
X3841(espe-)X
X555 1620(cially)N
X753(be)X
X849(useful.)X
X3 f
X555 1812(Implementation)N
X1122(Issues)X
X1 f
X755 1936(Hash)N
X944(functions:)X
X1288(The)X
X1437(algorithm)X
X1772(behind)X
X2 f
X2014(sdbm)X
X1 f
X2207(implementation)X
X2733(needs)X
X2939(a)X
X2998(good)X
X3181(bit-scrambling)X
X3671(hash)X
X3841(func-)X
X555 2032(tion)N
X702(to)X
X787(be)X
X886(effective.)X
X1211(I)X
X1261(ran)X
X1387(into)X
X1534(a)X
X1593(set)X
X1705(of)X
X1795(constants)X
X2116(for)X
X2233(a)X
X2292(simple)X
X2528(hash)X
X2698(function)X
X2988(that)X
X3130(seem)X
X3317(to)X
X3401(help)X
X2 f
X3561(sdbm)X
X1 f
X3752(perform)X
X555 2128(better)N
X758(than)X
X2 f
X916(ndbm)X
X1 f
X1114(for)X
X1228(various)X
X1484(inputs:)X
X7 f
X747 2272(/*)N
X795 2368(*)N
X891(polynomial)X
X1419(conversion)X
X1947(ignoring)X
X2379(overflows)X
X795 2464(*)N
X891(65599)X
X1179(nice.)X
X1467(65587)X
X1755(even)X
X1995(better.)X
X795 2560(*/)N
X747 2656(long)N
X747 2752(dbm_hash\(char)N
X1419(*str,)X
X1707(int)X
X1899(len\))X
X2139({)X
X939 2848(register)N
X1371(unsigned)X
X1803(long)X
X2043(n)X
X2139(=)X
X2235(0;)X
X939 3040(while)N
X1227(\(len--\))X
X1131 3136(n)N
X1227(=)X
X1323(n)X
X1419(*)X
X1515(65599)X
X1803(+)X
X1899(*str++;)X
X939 3232(return)N
X1275(n;)X
X747 3328(})N
X1 f
X755 3500(There)N
X975(may)X
X1145(be)X
X1253(better)X
X1467(hash)X
X1645(functions)X
X1974(for)X
X2099(the)X
X2228(purposes)X
X2544(of)X
X2642(dynamic)X
X2949(hashing.)X
X3269(Try)X
X3416(your)X
X3594(favorite,)X
X3895(and)X
X555 3596(check)N
X766(the)X
X887(page\256le.)X
X1184(If)X
X1261(it)X
X1328(contains)X
X1618(too)X
X1743(many)X
X1944(pages)X
X2150(with)X
X2315(too)X
X2440(many)X
X2641(holes,)X
X2853(\(in)X
X2965(relation)X
X3233(to)X
X3318(this)X
X3456(one)X
X3595(for)X
X3712(example\))X
X555 3692(or)N
X656(if)X
X2 f
X739(sdbm)X
X1 f
X942(simply)X
X1193(stops)X
X1391(working)X
X1692(\(fails)X
X1891(after)X
X7 f
X2101(SPLTMAX)X
X1 f
X2471(attempts)X
X2776(to)X
X2872(split\))X
X3070(when)X
X3278(you)X
X3432(feed)X
X3604(your)X
X3784(NEWS)X
X7 f
X555 3788(history)N
X1 f
X912(\256le)X
X1035(to)X
X1118(it,)X
X1203(you)X
X1344(probably)X
X1650(do)X
X1751(not)X
X1874(have)X
X2047(a)X
X2104(good)X
X2285(hashing)X
X2555(function.)X
X2883(If)X
X2958(you)X
X3099(do)X
X3200(better)X
X3404(\(for)X
X3545(different)X
X3842(types)X
X555 3884(of)N
X642(input\),)X
X873(I)X
X920(would)X
X1140(like)X
X1280(to)X
X1362(know)X
X1560(about)X
X1758(the)X
X1876(function)X
X2163(you)X
X2303(use.)X
X755 4008(Block)N
X967(sizes:)X
X1166(It)X
X1236(seems)X
X1453(\(from)X
X1657(various)X
X1914(tests)X
X2077(on)X
X2178(a)X
X2235(few)X
X2377(machines\))X
X2727(that)X
X2867(a)X
X2923(page)X
X3095(\256le)X
X3217(block)X
X3415(size)X
X7 f
X3588(PBLKSIZ)X
X1 f
X3944(of)X
X555 4104(1024)N
X738(is)X
X814(by)X
X917(far)X
X1030(the)X
X1150(best)X
X1301(for)X
X1417(performance,)X
X1866(but)X
X1990(this)X
X2127(also)X
X2278(happens)X
X2563(to)X
X2647(limit)X
X2819(the)X
X2939(size)X
X3086(of)X
X3175(a)X
X3233(key/value)X
X3567(pair.)X
X3734(Depend-)X
X555 4200(ing)N
X681(on)X
X785(your)X
X956(needs,)X
X1183(you)X
X1327(may)X
X1489(wish)X
X1663(to)X
X1748(increase)X
X2035(the)X
X2156(page)X
X2331(size,)X
X2499(and)X
X2638(also)X
X2790(adjust)X
X7 f
X3032(PAIRMAX)X
X1 f
X3391(\(the)X
X3539(maximum)X
X3886(size)X
X555 4296(of)N
X648(a)X
X710(key/value)X
X1048(pair)X
X1199(allowed:)X
X1501(should)X
X1740(always)X
X1989(be)X
X2090(at)X
X2173(least)X
X2345(three)X
X2531(words)X
X2752(smaller)X
X3013(than)X
X7 f
X3204(PBLKSIZ)X
X1 f
X(.\))S
X3612(accordingly.)X
X555 4392(The)N
X706(system-wide)X
X1137(version)X
X1399(of)X
X1492(the)X
X1616(library)X
X1856(should)X
X2095(probably)X
X2406(be)X
X2508(con\256gured)X
X2877(with)X
X3044(1024)X
X3229(\(distribution)X
X3649(default\),)X
X3944(as)X
X555 4488(this)N
X690(appears)X
X956(to)X
X1038(be)X
X1134(suf\256cient)X
X1452(for)X
X1566(most)X
X1741(common)X
X2041(uses)X
X2199(of)X
X2 f
X2286(sdbm)X
X1 f
X2455(.)X
X3 f
X555 4680(Portability)N
X1 f
X755 4804(This)N
X917(package)X
X1201(has)X
X1328(been)X
X1500(tested)X
X1707(in)X
X1789(many)X
X1987(different)X
X2284(UN*Xes)X
X2585(even)X
X2757(including)X
X3079(minix,)X
X3305(and)X
X3441(appears)X
X3707(to)X
X3789(be)X
X3885(rea-)X
X555 4900(sonably)N
X824(portable.)X
X1127(This)X
X1289(does)X
X1456(not)X
X1578(mean)X
X1772(it)X
X1836(will)X
X1980(port)X
X2129(easily)X
X2336(to)X
X2418(non-UN*X)X
X2799(systems.)X
X3 f
X555 5092(Notes)N
X767(and)X
X915(Miscellaneous)X
X1 f
X755 5216(The)N
X2 f
X913(sdbm)X
X1 f
X1115(is)X
X1201(not)X
X1336(a)X
X1405(very)X
X1581(complicated)X
X2006(package,)X
X2323(at)X
X2414(least)X
X2594(not)X
X2729(after)X
X2910(you)X
X3063(familiarize)X
X3444(yourself)X
X3739(with)X
X3913(the)X
X555 5312(literature)N
X879(on)X
X993(external)X
X1286(hashing.)X
X1589(There)X
X1811(are)X
X1944(other)X
X2143(interesting)X
X2514(algorithms)X
X2889(in)X
X2984(existence)X
X3316(that)X
X3469(ensure)X
X3712(\(approxi-)X
X555 5408(mately\))N
X825(single-read)X
X1207(access)X
X1438(to)X
X1525(a)X
X1586(data)X
X1745(value)X
X1944(associated)X
X2299(with)X
X2466(any)X
X2607(key.)X
X2768(These)X
X2984(are)X
X3107(directory-less)X
X3568(schemes)X
X3864(such)X
X555 5504(as)N
X2 f
X644(linear)X
X857(hashing)X
X1 f
X1132([Lit80])X
X1381(\(+)X
X1475(Larson)X
X1720(variations\),)X
X2 f
X2105(spiral)X
X2313(storage)X
X1 f
X2575([Mar79])X
X2865(or)X
X2954(directory)X
X3265(schemes)X
X3558(such)X
X3726(as)X
X2 f
X3814(exten-)X
X555 5600(sible)N
X731(hashing)X
X1 f
X1009([Fag79])X
X1288(by)X
X1393(Fagin)X
X1600(et)X
X1683(al.)X
X1786(I)X
X1838(do)X
X1943(hope)X
X2124(these)X
X2314(sources)X
X2579(provide)X
X2848(a)X
X2908(reasonable)X
X3276(playground)X
X3665(for)X
X3783(experi-)X
X555 5696(mentation)N
X907(with)X
X1081(other)X
X1277(algorithms.)X
X1690(See)X
X1837(the)X
X1966(June)X
X2144(1988)X
X2335(issue)X
X2526(of)X
X2624(ACM)X
X2837(Computing)X
X3227(Surveys)X
X3516([Enb88])X
X3810(for)X
X3935(an)X
X555 5792(excellent)N
X865(overview)X
X1184(of)X
X1271(the)X
X1389(\256eld.)X
X
X4 p
X%%Page: 4 4
X10 s 0 xH 0 xS 1 f
X2216 384(-)N
X2263(4)X
X2323(-)X
X3 f
X555 672(References)N
X1 f
X555 824([Lar78])N
X875(P.-A.)X
X1064(Larson,)X
X1327(``Dynamic)X
X1695(Hashing'',)X
X2 f
X2056(BIT)X
X1 f
X(,)S
X2216(vol.)X
X2378(18,)X
X2518(pp.)X
X2638(184-201,)X
X2945(1978.)X
X555 948([Tho90])N
X875(Ken)X
X1029(Thompson,)X
X2 f
X1411(private)X
X1658(communication)X
X1 f
X2152(,)X
X2192(Nov.)X
X2370(1990)X
X555 1072([Lit80])N
X875(W.)X
X992(Litwin,)X
X1246(``)X
X1321(Linear)X
X1552(Hashing:)X
X1862(A)X
X1941(new)X
X2096(tool)X
X2261(for)X
X2396(\256le)X
X2539(and)X
X2675(table)X
X2851(addressing'',)X
X2 f
X3288(Proceedings)X
X3709(of)X
X3791(the)X
X3909(6th)X
X875 1168(Conference)N
X1269(on)X
X1373(Very)X
X1548(Large)X
X1782(Dabatases)X
X2163(\(Montreal\))X
X1 f
X2515(,)X
X2558(pp.)X
X2701(212-223,)X
X3031(Very)X
X3215(Large)X
X3426(Database)X
X3744(Founda-)X
X875 1264(tion,)N
X1039(Saratoga,)X
X1360(Calif.,)X
X1580(1980.)X
X555 1388([Fag79])N
X875(R.)X
X969(Fagin,)X
X1192(J.)X
X1284(Nievergelt,)X
X1684(N.)X
X1803(Pippinger,)X
X2175(and)X
X2332(H.)X
X2451(R.)X
X2544(Strong,)X
X2797(``Extendible)X
X3218(Hashing)X
X3505(-)X
X3552(A)X
X3630(Fast)X
X3783(Access)X
X875 1484(Method)N
X1144(for)X
X1258(Dynamic)X
X1572(Files'',)X
X2 f
X1821(ACM)X
X2010(Trans.)X
X2236(Database)X
X2563(Syst.)X
X1 f
X2712(,)X
X2752(vol.)X
X2894(4,)X
X2994(no.3,)X
X3174(pp.)X
X3294(315-344,)X
X3601(Sept.)X
X3783(1979.)X
X555 1608([Wal84])N
X875(Rich)X
X1055(Wales,)X
X1305(``Discussion)X
X1739(of)X
X1835("dbm")X
X2072(data)X
X2235(base)X
X2406(system'',)X
X2 f
X2730(USENET)X
X3051(newsgroup)X
X3430(unix.wizards)X
X1 f
X3836(,)X
X3884(Jan.)X
X875 1704(1984.)N
X555 1828([Tor87])N
X875(Chris)X
X1068(Torek,)X
X1300(``Re:)X
X1505(dbm.a)X
X1743(and)X
X1899(ndbm.a)X
X2177(archives'',)X
X2 f
X2539(USENET)X
X2852(newsgroup)X
X3223(comp.unix)X
X1 f
X3555(,)X
X3595(1987.)X
X555 1952([Mar79])N
X875(G.)X
X974(N.)X
X1073(Martin,)X
X1332(``Spiral)X
X1598(Storage:)X
X1885(Incrementally)X
X2371(Augmentable)X
X2843(Hash)X
X3048(Addressed)X
X3427(Storage'',)X
X2 f
X3766(Techni-)X
X875 2048(cal)N
X993(Report)X
X1231(#27)X
X1 f
X(,)S
X1391(University)X
X1749(of)X
X1836(Varwick,)X
X2153(Coventry,)X
X2491(U.K.,)X
X2687(1979.)X
X555 2172([Enb88])N
X875(R.)X
X977(J.)X
X1057(Enbody)X
X1335(and)X
X1480(H.)X
X1586(C.)X
X1687(Du,)X
X1833(``Dynamic)X
X2209(Hashing)X
X2524(Schemes'',)X
X2 f
X2883(ACM)X
X3080(Computing)X
X3463(Surveys)X
X1 f
X3713(,)X
X3761(vol.)X
X3911(20,)X
X875 2268(no.)N
X995(2,)X
X1075(pp.)X
X1195(85-113,)X
X1462(June)X
X1629(1988.)X
X
X4 p
X%%Trailer
Xxt
X
Xxs
END_OF_FILE
if test 33302 -ne `wc -c <'readme.ps'`; then
    echo shar: \"'readme.ps'\" unpacked with wrong size!
fi
# end of 'readme.ps'
fi
if test -f 'sdbm.3' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'sdbm.3'\"
else
echo shar: Extracting \"'sdbm.3'\" \(8952 characters\)
sed "s/^X//" >'sdbm.3' <<'END_OF_FILE'
X.\" $Id: sdbm.3,v 1.2 90/12/13 13:00:57 oz Exp $
X.TH SDBM 3 "1 March 1990"
X.SH NAME
Xsdbm, dbm_open, dbm_prep, dbm_close, dbm_fetch, dbm_store, dbm_delete, dbm_firstkey, dbm_nextkey, dbm_hash, dbm_rdonly, dbm_error, dbm_clearerr, dbm_dirfno, dbm_pagfno \- data base subroutines
X.SH SYNOPSIS
X.nf
X.ft B
X#include <sdbm.h>
X.sp
Xtypedef struct {
X	char *dptr;
X	int dsize;
X} datum;
X.sp
Xdatum nullitem = { NULL, 0 };
X.sp
X\s-1DBM\s0 *dbm_open(char *file, int flags, int mode)
X.sp
X\s-1DBM\s0 *dbm_prep(char *dirname, char *pagname, int flags, int mode)
X.sp
Xvoid dbm_close(\s-1DBM\s0 *db)
X.sp
Xdatum dbm_fetch(\s-1DBM\s0 *db, key)
X.sp
Xint dbm_store(\s-1DBM\s0 *db, datum key, datum val, int flags)
X.sp
Xint dbm_delete(\s-1DBM\s0 *db, datum key)
X.sp
Xdatum dbm_firstkey(\s-1DBM\s0 *db)
X.sp
Xdatum dbm_nextkey(\s-1DBM\s0 *db)
X.sp
Xlong dbm_hash(char *string, int len)
X.sp
Xint dbm_rdonly(\s-1DBM\s0 *db)
Xint dbm_error(\s-1DBM\s0 *db)
Xdbm_clearerr(\s-1DBM\s0 *db)
Xint dbm_dirfno(\s-1DBM\s0 *db)
Xint dbm_pagfno(\s-1DBM\s0 *db)
X.ft R
X.fi
X.SH DESCRIPTION
X.IX "database library" sdbm "" "\fLsdbm\fR"
X.IX dbm_open "" "\fLdbm_open\fR \(em open \fLsdbm\fR database"
X.IX dbm_prep "" "\fLdbm_prep\fR \(em prepare \fLsdbm\fR database"
X.IX dbm_close "" "\fLdbm_close\fR \(em close \fLsdbm\fR routine"
X.IX dbm_fetch "" "\fLdbm_fetch\fR \(em fetch \fLsdbm\fR database data"
X.IX dbm_store "" "\fLdbm_store\fR \(em add data to \fLsdbm\fR database"
X.IX dbm_delete "" "\fLdbm_delete\fR \(em remove data from \fLsdbm\fR database"
X.IX dbm_firstkey "" "\fLdbm_firstkey\fR \(em access \fLsdbm\fR database"
X.IX dbm_nextkey "" "\fLdbm_nextkey\fR \(em access \fLsdbm\fR database"
X.IX dbm_hash "" "\fLdbm_hash\fR \(em string hash for \fLsdbm\fR database"
X.IX dbm_rdonly "" "\fLdbm_rdonly\fR \(em return \fLsdbm\fR database read-only mode"
X.IX dbm_error "" "\fLdbm_error\fR \(em return \fLsdbm\fR database error condition"
X.IX dbm_clearerr "" "\fLdbm_clearerr\fR \(em clear \fLsdbm\fR database error condition"
X.IX dbm_dirfno "" "\fLdbm_dirfno\fR \(em return \fLsdbm\fR database bitmap file descriptor"
X.IX dbm_pagfno "" "\fLdbm_pagfno\fR \(em return \fLsdbm\fR database data file descriptor"
X.IX "database functions \(em \fLsdbm\fR"  dbm_open  ""  \fLdbm_open\fP
X.IX "database functions \(em \fLsdbm\fR"  dbm_prep  ""  \fLdbm_prep\fP
X.IX "database functions \(em \fLsdbm\fR"  dbm_close  ""  \fLdbm_close\fP
X.IX "database functions \(em \fLsdbm\fR"  dbm_fetch  ""  \fLdbm_fetch\fP
X.IX "database functions \(em \fLsdbm\fR"  dbm_store  ""  \fLdbm_store\fP
X.IX "database functions \(em \fLsdbm\fR"  dbm_delete  ""  \fLdbm_delete\fP
X.IX "database functions \(em \fLsdbm\fR"  dbm_firstkey  ""  \fLdbm_firstkey\fP
X.IX "database functions \(em \fLsdbm\fR"  dbm_nextkey  ""  \fLdbm_nextkey\fP
X.IX "database functions \(em \fLsdbm\fR"  dbm_rdonly  ""  \fLdbm_rdonly\fP
X.IX "database functions \(em \fLsdbm\fR"  dbm_error  ""  \fLdbm_error\fP
X.IX "database functions \(em \fLsdbm\fR"  dbm_clearerr  ""  \fLdbm_clearerr\fP
X.IX "database functions \(em \fLsdbm\fR"  dbm_dirfno  ""  \fLdbm_dirfno\fP
X.IX "database functions \(em \fLsdbm\fR"  dbm_pagfno  ""  \fLdbm_pagfno\fP
X.LP
XThis package allows an application to maintain a mapping of <key,value> pairs
Xin disk files.  This is not to be considered a real database system, but is
Xstill useful in many simple applications built around fast retrieval of a data
Xvalue from a key.  This implementation uses an external hashing scheme,
Xcalled Dynamic Hashing, as described by Per-Aake Larson in BIT 18 (1978) pp.
X184-201.  Retrieval of any item usually requires a single disk access.
XThe application interface is compatible with the
X.IR ndbm (3)
Xlibrary.
X.LP
XAn
X.B sdbm
Xdatabase is kept in two files usually given the extensions
X.B \.dir
Xand
X.BR \.pag .
XThe
X.B \.dir
Xfile contains a bitmap representing a forest of binary hash trees, the leaves
Xof which indicate data pages in the
X.B \.pag
Xfile.
X.LP
XThe application interface uses the
X.B datum
Xstructure to describe both
X.I keys
Xand
X.IR value s.
XA
X.B datum
Xspecifies a byte sequence of
X.I dsize
Xsize pointed to by
X.IR dptr .
XIf you use
X.SM ASCII
Xstrings as
X.IR key s
Xor
X.IR value s,
Xthen you must decide whether or not to include the terminating
X.SM NUL
Xbyte which sometimes defines strings.  Including it will require larger
Xdatabase files, but it will be possible to get sensible output from a
X.IR strings (1)
Xcommand applied to the data file.
X.LP
XIn order to allow a process using this package to manipulate multiple
Xdatabases, the applications interface always requires a
X.IR handle ,
Xa
X.BR "DBM *" ,
Xto identify the database to be manipulated.  Such a handle can be obtained
Xfrom the only routines that do not require it, namely
X.BR dbm_open (\|)
Xor
X.BR dbm_prep (\|).
XEither of these will open or create the two necessary files.  The
Xdifference is that the latter allows explicitly naming the bitmap and data
Xfiles whereas
X.BR dbm_open (\|)
Xwill take a base file name and call
X.BR dbm_prep (\|)
Xwith the default extensions.
XThe
X.I flags
Xand
X.I mode
Xparameters are the same as for
X.BR open (2).
X.LP
XTo free the resources occupied while a database handle is active, call
X.BR dbm_close (\|).
X.LP
XGiven a handle, one can retrieve data associated with a key by using the
X.BR dbm_fetch (\|)
Xroutine, and associate data with a key by using the
X.BR dbm_store (\|)
Xroutine.
X.LP
XThe values of the
X.I flags
Xparameter for
X.BR dbm_store (\|)
Xcan be either
X.BR \s-1DBM_INSERT\s0 ,
Xwhich will not change an existing entry with the same key, or
X.BR \s-1DBM_REPLACE\s0 ,
Xwhich will replace an existing entry with the same key.
XKeys are unique within the database.
X.LP
XTo delete a key and its associated value use the
X.BR dbm_delete (\|)
Xroutine.
X.LP
XTo retrieve every key in the database, use a loop like:
X.sp
X.nf
X.ft B
Xfor (key = dbm_firstkey(db); key.dptr != NULL; key = dbm_nextkey(db))
X        ;
X.ft R
X.fi
X.LP
XThe order of retrieval is unspecified.
X.LP
XIf you determine that the performance of the database is inadequate or
Xyou notice clustering or other effects that may be due to the hashing
Xalgorithm used by this package, you can override it by supplying your
Xown
X.BR dbm_hash (\|)
Xroutine.  Doing so will make the database unintelligable to any other
Xapplications that do not use your specialized hash function.
X.sp
X.LP
XThe following macros are defined in the header file:
X.IP
X.BR dbm_rdonly (\|)
Xreturns true if the database has been opened read\-only.
X.IP
X.BR dbm_error (\|)
Xreturns true if an I/O error has occurred.
X.IP
X.BR dbm_clearerr (\|)
Xallows you to clear the error flag if you think you know what the error
Xwas and insist on ignoring it.
X.IP
X.BR dbm_dirfno (\|)
Xreturns the file descriptor associated with the bitmap file.
X.IP
X.BR dbm_pagfno (\|)
Xreturns the file descriptor associated with the data file.
X.SH SEE ALSO
X.IR open (2).
X.SH DIAGNOSTICS
XFunctions that return a
X.B "DBM *"
Xhandle will use
X.SM NULL
Xto indicate an error.
XFunctions that return an
X.B int
Xwill use \-1 to indicate an error.  The normal return value in that case is 0.
XFunctions that return a
X.B datum
Xwill return
X.B nullitem
Xto indicate an error.
X.LP
XAs a special case of
X.BR dbm_store (\|),
Xif it is called with the
X.B \s-1DBM_INSERT\s0
Xflag and the key already exists in the database, the return value will be 1.
X.LP
XIn general, if a function parameter is invalid,
X.B errno
Xwill be set to
X.BR \s-1EINVAL\s0 .
XIf a write operation is requested on a read-only database,
X.B errno
Xwill be set to
X.BR \s-1ENOPERM\s0 .
XIf a memory allocation (using
X.IR malloc (3))
Xfailed,
X.B errno
Xwill be set to
X.BR \s-1ENOMEM\s0 .
XFor I/O operation failures
X.B errno
Xwill contain the value set by the relevant failed system call, either
X.IR read (2),
X.IR write (2),
Xor
X.IR lseek (2).
X.SH AUTHOR
X.IP "Ozan S. Yigit" (oz@nexus.yorku.ca)
X.SH BUGS
XThe sum of key and value data sizes must not exceed
X.B \s-1PAIRMAX\s0
X(1008 bytes).
X.LP
XThe sum of the key and value data sizes where several keys hash to the
Xsame value must fit within one bitmap page.
X.LP
XThe
X.B \.pag
Xfile will contain holes, so its apparent size is larger than its contents.
XWhen copied through the filesystem the holes will be filled.
X.LP
XThe contents of
X.B datum
Xvalues returned are in volatile storage.  If you want to retain the values
Xpointed to, you must copy them immediately before another call to this package.
X.LP
XThe only safe way for multiple processes to (read and) update a database at
Xthe same time, is to implement a private locking scheme outside this package
Xand open and close the database between lock acquisitions.  It is safe for
Xmultiple processes to concurrently access a database read-only.
X.SH APPLICATIONS PORTABILITY
XFor complete source code compatibility with the Berkeley Unix
X.IR ndbm (3)
Xlibrary, the 
X.B sdbm.h
Xheader file should be installed in
X.BR /usr/include/ndbm.h .
X.LP
XThe
X.B nullitem
Xdata item, and the
X.BR dbm_prep (\|),
X.BR dbm_hash (\|),
X.BR dbm_rdonly (\|),
X.BR dbm_dirfno (\|),
Xand
X.BR dbm_pagfno (\|)
Xfunctions are unique to this package.
END_OF_FILE
if test 8952 -ne `wc -c <'sdbm.3'`; then
    echo shar: \"'sdbm.3'\" unpacked with wrong size!
fi
# end of 'sdbm.3'
fi
if test -f 'sdbm.c' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'sdbm.c'\"
else
echo shar: Extracting \"'sdbm.c'\" \(11029 characters\)
sed "s/^X//" >'sdbm.c' <<'END_OF_FILE'
X/*
X * sdbm - ndbm work-alike hashed database library
X * based on Per-Aake Larson's Dynamic Hashing algorithms. BIT 18 (1978).
X * author: oz@nexus.yorku.ca
X * status: public domain.
X *
X * core routines
X */
X
X#ifndef lint
Xstatic char rcsid[] = "$Id: sdbm.c,v 1.16 90/12/13 13:01:31 oz Exp $";
X#endif
X
X#include "sdbm.h"
X#include "tune.h"
X#include "pair.h"
X
X#include <sys/types.h>
X#include <sys/stat.h>
X#ifdef BSD42
X#include <sys/file.h>
X#else
X#include <fcntl.h>
X#include <memory.h>
X#endif
X#include <errno.h>
X#include <string.h>
X
X#ifdef __STDC__
X#include <stddef.h>
X#endif
X
X#ifndef NULL
X#define NULL	0
X#endif
X
X/*
X * externals
X */
X#ifndef sun
Xextern int errno;
X#endif
X
Xextern char *malloc proto((unsigned int));
Xextern void free proto((void *));
Xextern long lseek();
X
X/*
X * forward
X */
Xstatic int getdbit proto((DBM *, long));
Xstatic int setdbit proto((DBM *, long));
Xstatic int getpage proto((DBM *, long));
Xstatic datum getnext proto((DBM *));
Xstatic int makroom proto((DBM *, long, int));
X
X/*
X * useful macros
X */
X#define bad(x)		((x).dptr == NULL || (x).dsize <= 0)
X#define exhash(item)	dbm_hash((item).dptr, (item).dsize)
X#define ioerr(db)	((db)->flags |= DBM_IOERR)
X
X#define OFF_PAG(off)	(long) (off) * PBLKSIZ
X#define OFF_DIR(off)	(long) (off) * DBLKSIZ
X
Xstatic long masks[] = {
X	000000000000, 000000000001, 000000000003, 000000000007,
X	000000000017, 000000000037, 000000000077, 000000000177,
X	000000000377, 000000000777, 000000001777, 000000003777,
X	000000007777, 000000017777, 000000037777, 000000077777,
X	000000177777, 000000377777, 000000777777, 000001777777,
X	000003777777, 000007777777, 000017777777, 000037777777,
X	000077777777, 000177777777, 000377777777, 000777777777,
X	001777777777, 003777777777, 007777777777, 017777777777
X};
X
Xdatum nullitem = {NULL, 0};
X
XDBM *
Xdbm_open(file, flags, mode)
Xregister char *file;
Xregister int flags;
Xregister int mode;
X{
X	register DBM *db;
X	register char *dirname;
X	register char *pagname;
X	register int n;
X
X	if (file == NULL || !*file)
X		return errno = EINVAL, (DBM *) NULL;
X/*
X * need space for two seperate filenames
X */
X	n = strlen(file) * 2 + strlen(DIRFEXT) + strlen(PAGFEXT) + 2;
X
X	if ((dirname = malloc((unsigned) n)) == NULL)
X		return errno = ENOMEM, (DBM *) NULL;
X/*
X * build the file names
X */
X	dirname = strcat(strcpy(dirname, file), DIRFEXT);
X	pagname = strcpy(dirname + strlen(dirname) + 1, file);
X	pagname = strcat(pagname, PAGFEXT);
X
X	db = dbm_prep(dirname, pagname, flags, mode);
X	free((char *) dirname);
X	return db;
X}
X
XDBM *
Xdbm_prep(dirname, pagname, flags, mode)
Xchar *dirname;
Xchar *pagname;
Xint flags;
Xint mode;
X{
X	register DBM *db;
X	struct stat dstat;
X
X	if ((db = (DBM *) malloc(sizeof(DBM))) == NULL)
X		return errno = ENOMEM, (DBM *) NULL;
X
X        db->flags = 0;
X        db->hmask = 0;
X        db->blkptr = 0;
X        db->keyptr = 0;
X/*
X * adjust user flags so that WRONLY becomes RDWR, 
X * as required by this package. Also set our internal
X * flag for RDONLY if needed.
X */
X	if (flags & O_WRONLY)
X		flags = (flags & ~O_WRONLY) | O_RDWR;
X
X	else if ((flags & 03) == O_RDONLY)
X		db->flags = DBM_RDONLY;
X/*
X * open the files in sequence, and stat the dirfile.
X * If we fail anywhere, undo everything, return NULL.
X */
X	if ((db->pagf = open(pagname, flags, mode)) > -1) {
X		if ((db->dirf = open(dirname, flags, mode)) > -1) {
X/*
X * need the dirfile size to establish max bit number.
X */
X			if (fstat(db->dirf, &dstat) == 0) {
X/*
X * zero size: either a fresh database, or one with a single,
X * unsplit data page: dirpage is all zeros.
X */
X				db->dirbno = (!dstat.st_size) ? 0 : -1;
X				db->pagbno = -1;
X				db->maxbno = dstat.st_size * BYTESIZ;
X
X				(void) memset(db->pagbuf, 0, PBLKSIZ);
X				(void) memset(db->dirbuf, 0, DBLKSIZ);
X			/*
X			 * success
X			 */
X				return db;
X			}
X			(void) close(db->dirf);
X		}
X		(void) close(db->pagf);
X	}
X	free((char *) db);
X	return (DBM *) NULL;
X}
X
Xvoid
Xdbm_close(db)
Xregister DBM *db;
X{
X	if (db == NULL)
X		errno = EINVAL;
X	else {
X		(void) close(db->dirf);
X		(void) close(db->pagf);
X		free((char *) db);
X	}
X}
X
Xdatum
Xdbm_fetch(db, key)
Xregister DBM *db;
Xdatum key;
X{
X	if (db == NULL || bad(key))
X		return errno = EINVAL, nullitem;
X
X	if (getpage(db, exhash(key)))
X		return getpair(db->pagbuf, key);
X
X	return ioerr(db), nullitem;
X}
X
Xint
Xdbm_delete(db, key)
Xregister DBM *db;
Xdatum key;
X{
X	if (db == NULL || bad(key))
X		return errno = EINVAL, -1;
X	if (dbm_rdonly(db))
X		return errno = EPERM, -1;
X
X	if (getpage(db, exhash(key))) {
X		if (!delpair(db->pagbuf, key))
X			return -1;
X/*
X * update the page file
X */
X		if (lseek(db->pagf, OFF_PAG(db->pagbno), SEEK_SET) < 0
X		    || write(db->pagf, db->pagbuf, PBLKSIZ) < 0)
X			return ioerr(db), -1;
X
X		return 0;
X	}
X
X	return ioerr(db), -1;
X}
X
Xint
Xdbm_store(db, key, val, flags)
Xregister DBM *db;
Xdatum key;
Xdatum val;
Xint flags;
X{
X	int need;
X	register long hash;
X
X	if (db == NULL || bad(key))
X		return errno = EINVAL, -1;
X	if (dbm_rdonly(db))
X		return errno = EPERM, -1;
X
X	need = key.dsize + val.dsize;
X/*
X * is the pair too big (or too small) for this database ??
X */
X	if (need < 0 || need > PAIRMAX)
X		return errno = EINVAL, -1;
X
X	if (getpage(db, (hash = exhash(key)))) {
X/*
X * if we need to replace, delete the key/data pair
X * first. If it is not there, ignore.
X */
X		if (flags == DBM_REPLACE)
X			(void) delpair(db->pagbuf, key);
X#ifdef SEEDUPS
X		else if (duppair(db->pagbuf, key))
X			return 1;
X#endif
X/*
X * if we do not have enough room, we have to split.
X */
X		if (!fitpair(db->pagbuf, need))
X			if (!makroom(db, hash, need))
X				return ioerr(db), -1;
X/*
X * we have enough room or split is successful. insert the key,
X * and update the page file.
X */
X		(void) putpair(db->pagbuf, key, val);
X
X		if (lseek(db->pagf, OFF_PAG(db->pagbno), SEEK_SET) < 0
X		    || write(db->pagf, db->pagbuf, PBLKSIZ) < 0)
X			return ioerr(db), -1;
X	/*
X	 * success
X	 */
X		return 0;
X	}
X
X	return ioerr(db), -1;
X}
X
X/*
X * makroom - make room by splitting the overfull page
X * this routine will attempt to make room for SPLTMAX times before
X * giving up.
X */
Xstatic int
Xmakroom(db, hash, need)
Xregister DBM *db;
Xlong hash;
Xint need;
X{
X	long newp;
X	char twin[PBLKSIZ];
X	char *pag = db->pagbuf;
X	char *new = twin;
X	register int smax = SPLTMAX;
X
X	do {
X/*
X * split the current page
X */
X		(void) splpage(pag, new, db->hmask + 1);
X/*
X * address of the new page
X */
X		newp = (hash & db->hmask) | (db->hmask + 1);
X
X/*
X * write delay, read avoidence/cache shuffle:
X * select the page for incoming pair: if key is to go to the new page,
X * write out the previous one, and copy the new one over, thus making
X * it the current page. If not, simply write the new page, and we are
X * still looking at the page of interest. current page is not updated
X * here, as dbm_store will do so, after it inserts the incoming pair.
X */
X		if (hash & (db->hmask + 1)) {
X			if (lseek(db->pagf, OFF_PAG(db->pagbno), SEEK_SET) < 0
X			    || write(db->pagf, db->pagbuf, PBLKSIZ) < 0)
X				return 0;
X			db->pagbno = newp;
X			(void) memcpy(pag, new, PBLKSIZ);
X		}
X		else if (lseek(db->pagf, OFF_PAG(newp), SEEK_SET) < 0
X			 || write(db->pagf, new, PBLKSIZ) < 0)
X			return 0;
X
X		if (!setdbit(db, db->curbit))
X			return 0;
X/*
X * see if we have enough room now
X */
X		if (fitpair(pag, need))
X			return 1;
X/*
X * try again... update curbit and hmask as getpage would have
X * done. because of our update of the current page, we do not
X * need to read in anything. BUT we have to write the current
X * [deferred] page out, as the window of failure is too great.
X */
X		db->curbit = 2 * db->curbit +
X			((hash & (db->hmask + 1)) ? 2 : 1);
X		db->hmask |= db->hmask + 1;
X
X		if (lseek(db->pagf, OFF_PAG(db->pagbno), SEEK_SET) < 0
X		    || write(db->pagf, db->pagbuf, PBLKSIZ) < 0)
X			return 0;
X
X	} while (--smax);
X/*
X * if we are here, this is real bad news. After SPLTMAX splits,
X * we still cannot fit the key. say goodnight.
X */
X#ifdef BADMESS
X	(void) write(2, "sdbm: cannot insert after SPLTMAX attempts.\n", 44);
X#endif
X	return 0;
X
X}
X
X/*
X * the following two routines will break if
X * deletions aren't taken into account. (ndbm bug)
X */
Xdatum
Xdbm_firstkey(db)
Xregister DBM *db;
X{
X	if (db == NULL)
X		return errno = EINVAL, nullitem;
X/*
X * start at page 0
X */
X	if (lseek(db->pagf, OFF_PAG(0), SEEK_SET) < 0
X	    || read(db->pagf, db->pagbuf, PBLKSIZ) < 0)
X		return ioerr(db), nullitem;
X	db->pagbno = 0;
X	db->blkptr = 0;
X	db->keyptr = 0;
X
X	return getnext(db);
X}
X
Xdatum
Xdbm_nextkey(db)
Xregister DBM *db;
X{
X	if (db == NULL)
X		return errno = EINVAL, nullitem;
X	return getnext(db);
X}
X
X/*
X * all important binary trie traversal
X */
Xstatic int
Xgetpage(db, hash)
Xregister DBM *db;
Xregister long hash;
X{
X	register int hbit;
X	register long dbit;
X	register long pagb;
X
X	dbit = 0;
X	hbit = 0;
X	while (dbit < db->maxbno && getdbit(db, dbit))
X		dbit = 2 * dbit + ((hash & (1 << hbit++)) ? 2 : 1);
X
X	debug(("dbit: %d...", dbit));
X
X	db->curbit = dbit;
X	db->hmask = masks[hbit];
X
X	pagb = hash & db->hmask;
X/*
X * see if the block we need is already in memory.
X * note: this lookaside cache has about 10% hit rate.
X */
X	if (pagb != db->pagbno) { 
X/*
X * note: here, we assume a "hole" is read as 0s.
X * if not, must zero pagbuf first.
X */
X		if (lseek(db->pagf, OFF_PAG(pagb), SEEK_SET) < 0
X		    || read(db->pagf, db->pagbuf, PBLKSIZ) < 0)
X			return 0;
X		if (!chkpage(db->pagbuf))
X			return 0;
X		db->pagbno = pagb;
X
X		debug(("pag read: %d\n", pagb));
X	}
X	return 1;
X}
X
Xstatic int
Xgetdbit(db, dbit)
Xregister DBM *db;
Xregister long dbit;
X{
X	register long c;
X	register long dirb;
X
X	c = dbit / BYTESIZ;
X	dirb = c / DBLKSIZ;
X
X	if (dirb != db->dirbno) {
X		if (lseek(db->dirf, OFF_DIR(dirb), SEEK_SET) < 0
X		    || read(db->dirf, db->dirbuf, DBLKSIZ) < 0)
X			return 0;
X		db->dirbno = dirb;
X
X		debug(("dir read: %d\n", dirb));
X	}
X
X	return db->dirbuf[c % DBLKSIZ] & (1 << dbit % BYTESIZ);
X}
X
Xstatic int
Xsetdbit(db, dbit)
Xregister DBM *db;
Xregister long dbit;
X{
X	register long c;
X	register long dirb;
X
X	c = dbit / BYTESIZ;
X	dirb = c / DBLKSIZ;
X
X	if (dirb != db->dirbno) {
X		if (lseek(db->dirf, OFF_DIR(dirb), SEEK_SET) < 0
X		    || read(db->dirf, db->dirbuf, DBLKSIZ) < 0)
X			return 0;
X		db->dirbno = dirb;
X
X		debug(("dir read: %d\n", dirb));
X	}
X
X	db->dirbuf[c % DBLKSIZ] |= (1 << dbit % BYTESIZ);
X
X	if (dbit >= db->maxbno)
X		db->maxbno += DBLKSIZ * BYTESIZ;
X
X	if (lseek(db->dirf, OFF_DIR(dirb), SEEK_SET) < 0
X	    || write(db->dirf, db->dirbuf, DBLKSIZ) < 0)
X		return 0;
X
X	return 1;
X}
X
X/*
X * getnext - get the next key in the page, and if done with
X * the page, try the next page in sequence
X */
Xstatic datum
Xgetnext(db)
Xregister DBM *db;
X{
X	datum key;
X
X	for (;;) {
X		db->keyptr++;
X		key = getnkey(db->pagbuf, db->keyptr);
X		if (key.dptr != NULL)
X			return key;
X/*
X * we either run out, or there is nothing on this page..
X * try the next one... If we lost our position on the
X * file, we will have to seek.
X */
X		db->keyptr = 0;
X		if (db->pagbno != db->blkptr++)
X			if (lseek(db->pagf, OFF_PAG(db->blkptr), SEEK_SET) < 0)
X				break;
X		db->pagbno = db->blkptr;
X		if (read(db->pagf, db->pagbuf, PBLKSIZ) <= 0)
X			break;
X		if (!chkpage(db->pagbuf))
X			break;
X	}
X
X	return ioerr(db), nullitem;
X}
END_OF_FILE
if test 11029 -ne `wc -c <'sdbm.c'`; then
    echo shar: \"'sdbm.c'\" unpacked with wrong size!
fi
# end of 'sdbm.c'
fi
if test -f 'sdbm.h' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'sdbm.h'\"
else
echo shar: Extracting \"'sdbm.h'\" \(2174 characters\)
sed "s/^X//" >'sdbm.h' <<'END_OF_FILE'
X/*
X * sdbm - ndbm work-alike hashed database library
X * based on Per-Ake Larson's Dynamic Hashing algorithms. BIT 18 (1978).
X * author: oz@nexus.yorku.ca
X * status: public domain. 
X */
X#define DBLKSIZ 4096
X#define PBLKSIZ 1024
X#define PAIRMAX 1008			/* arbitrary on PBLKSIZ-N */
X#define SPLTMAX	10			/* maximum allowed splits */
X					/* for a single insertion */
X#define DIRFEXT	".dir"
X#define PAGFEXT	".pag"
X
Xtypedef struct {
X	int dirf;		       /* directory file descriptor */
X	int pagf;		       /* page file descriptor */
X	int flags;		       /* status/error flags, see below */
X	long maxbno;		       /* size of dirfile in bits */
X	long curbit;		       /* current bit number */
X	long hmask;		       /* current hash mask */
X	long blkptr;		       /* current block for nextkey */
X	int keyptr;		       /* current key for nextkey */
X	long blkno;		       /* current page to read/write */
X	long pagbno;		       /* current page in pagbuf */
X	char pagbuf[PBLKSIZ];	       /* page file block buffer */
X	long dirbno;		       /* current block in dirbuf */
X	char dirbuf[DBLKSIZ];	       /* directory file block buffer */
X} DBM;
X
X#define DBM_RDONLY	0x1	       /* data base open read-only */
X#define DBM_IOERR	0x2	       /* data base I/O error */
X
X/*
X * utility macros
X */
X#define dbm_rdonly(db)		((db)->flags & DBM_RDONLY)
X#define dbm_error(db)		((db)->flags & DBM_IOERR)
X
X#define dbm_clearerr(db)	((db)->flags &= ~DBM_IOERR)  /* ouch */
X
X#define dbm_dirfno(db)	((db)->dirf)
X#define dbm_pagfno(db)	((db)->pagf)
X
Xtypedef struct {
X	char *dptr;
X	int dsize;
X} datum;
X
Xextern datum nullitem;
X
X#ifdef __STDC__
X#define proto(p) p
X#else
X#define proto(p) ()
X#endif
X
X/*
X * flags to dbm_store
X */
X#define DBM_INSERT	0
X#define DBM_REPLACE	1
X
X/*
X * ndbm interface
X */
Xextern DBM *dbm_open proto((char *, int, int));
Xextern void dbm_close proto((DBM *));
Xextern datum dbm_fetch proto((DBM *, datum));
Xextern int dbm_delete proto((DBM *, datum));
Xextern int dbm_store proto((DBM *, datum, datum, int));
Xextern datum dbm_firstkey proto((DBM *));
Xextern datum dbm_nextkey proto((DBM *));
X
X/*
X * other
X */
Xextern DBM *dbm_prep proto((char *, char *, int, int));
Xextern long dbm_hash proto((char *, int));
END_OF_FILE
if test 2174 -ne `wc -c <'sdbm.h'`; then
    echo shar: \"'sdbm.h'\" unpacked with wrong size!
fi
# end of 'sdbm.h'
fi
if test -f 'tune.h' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'tune.h'\"
else
echo shar: Extracting \"'tune.h'\" \(665 characters\)
sed "s/^X//" >'tune.h' <<'END_OF_FILE'
X/*
X * sdbm - ndbm work-alike hashed database library
X * tuning and portability constructs [not nearly enough]
X * author: oz@nexus.yorku.ca
X */
X
X#define BYTESIZ		8
X
X#ifdef SVID
X#include <unistd.h>
X#endif
X
X#ifdef BSD42
X#define SEEK_SET	L_SET
X#define	memset(s,c,n)	bzero(s, n)		/* only when c is zero */
X#define	memcpy(s1,s2,n)	bcopy(s2, s1, n)
X#define	memcmp(s1,s2,n)	bcmp(s1,s2,n)
X#endif
X
X/*
X * important tuning parms (hah)
X */
X
X#define SEEDUPS			/* always detect duplicates */
X#define BADMESS			/* generate a message for worst case:
X				   cannot make room after SPLTMAX splits */
X/*
X * misc
X */
X#ifdef DEBUG
X#define debug(x)	printf x
X#else
X#define debug(x)
X#endif
END_OF_FILE
if test 665 -ne `wc -c <'tune.h'`; then
    echo shar: \"'tune.h'\" unpacked with wrong size!
fi
# end of 'tune.h'
fi
if test -f 'util.c' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'util.c'\"
else
echo shar: Extracting \"'util.c'\" \(767 characters\)
sed "s/^X//" >'util.c' <<'END_OF_FILE'
X#include <stdio.h>
X#ifdef SDBM
X#include "sdbm.h"
X#else
X#include "ndbm.h"
X#endif
X
Xvoid
Xoops(s1, s2)
Xregister char *s1;
Xregister char *s2;
X{
X	extern int errno, sys_nerr;
X	extern char *sys_errlist[];
X	extern char *progname;
X
X	if (progname)
X		fprintf(stderr, "%s: ", progname);
X	fprintf(stderr, s1, s2);
X	if (errno > 0 && errno < sys_nerr)
X		fprintf(stderr, " (%s)", sys_errlist[errno]);
X	fprintf(stderr, "\n");
X	exit(1);
X}
X
Xint
Xokpage(pag)
Xchar *pag;
X{
X	register unsigned n;
X	register off;
X	register short *ino = (short *) pag;
X
X	if ((n = ino[0]) > PBLKSIZ / sizeof(short))
X		return 0;
X
X	if (!n)
X		return 1;
X
X	off = PBLKSIZ;
X	for (ino++; n; ino += 2) {
X		if (ino[0] > off || ino[1] > off ||
X		    ino[1] > ino[0])
X			return 0;
X		off = ino[1];
X		n -= 2;
X	}
X
X	return 1;
X}
END_OF_FILE
if test 767 -ne `wc -c <'util.c'`; then
    echo shar: \"'util.c'\" unpacked with wrong size!
fi
# end of 'util.c'
fi
echo shar: End of shell archive.
exit 0
