*** /scalpel/lwall/perl5alpha4/perl.c	Fri Jan 14 05:04:50 1994
--- perl.c	Fri Jan 14 23:22:47 1994
***************
*** 1303,1309 ****
  	SvMULTI_on(envgv);
  	hv = GvHVn(envgv);
  	hv_clear(hv);
- 	hv_magic(hv, envgv, 'E');
  	if (env != environ)
  	    environ[0] = Nullch;
  	for (; *env; env++) {
--- 1303,1308 ----
***************
*** 1314,1319 ****
--- 1313,1319 ----
  	    (void)hv_store(hv, *env, s - *env, sv, 0);
  	    *s = '=';
  	}
+ 	hv_magic(hv, envgv, 'E');
      }
      tainted = 0;
      if (tmpgv = gv_fetchpv("$",TRUE))
