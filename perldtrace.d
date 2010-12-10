/*
 * Written by Alan Burlinson -- taken from his blog post
 * at <http://blogs.sun.com/alanbur/date/20050909>.
 */

provider perl {
    probe sub__entry(char *, char *, int, char *);
    probe sub__return(char *, char *, int, char *);
};

/*
 * Local Variables:
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 *
 * ex: set ts=8 sts=4 sw=4 noet:
 */
