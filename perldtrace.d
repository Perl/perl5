/*
 * Written by Alan Burlinson -- taken from his blog post
 * at <http://bleaklow.com/2005/09/09/dtrace_and_perl.html>.
 */

provider perl {
    probe sub__entry(char *, char *, int, char *);
    probe sub__return(char *, char *, int, char *);

    probe phase__change(const char *, const char *);
};

/*
 * Local Variables:
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 *
 * ex: set ts=8 sts=4 sw=4 noet:
 */
