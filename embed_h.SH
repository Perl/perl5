#!/bin/sh

cat <<'END' >embed.h
/* This file is derived from global.var and interp.var */

/* (Doing namespace management portably in C is really gross.) */

#ifdef EMBED

/* globals we need to hide from the world */
END

sed <global.var >>embed.h						\
	-e 's/[ 	]*#.*//'					\
	-e '/^[ 	]*$/d'						\
	-e 's/\(.*\)/#define \1		PERL\1/'			\
	-e 's/\(................	\)	/\1/'

cat <<'END' >> embed.h

#endif /* EMBEDDED */

/* Put interpreter specific variables into a struct? */

#ifdef MULTIPLICITY

END


sed <interp.var >>embed.h						\
	-e 's/[ 	]*#.*//'					\
	-e '/^[ 	]*$/d'						\
	-e 's/\(.*\)/#define \1		(curinterp->I\1)/'		\
	-e 's/\(................	\)	/\1/'

cat <<'END' >> embed.h

#else	/* not multiple, so translate interpreter variables the other way... */

END

sed <interp.var >>embed.h						\
	-e 's/[ 	]*#.*//'					\
	-e '/^[ 	]*$/d'						\
	-e 's/\(.*\)/#define I\1		\1/'			\
	-e 's/\(................	\)	/\1/'

cat <<'END' >> embed.h

#endif /* MULTIPLE_INTERPRETERS */
END

