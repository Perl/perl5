# machten.sh
# This is for MachTen 4.0.2.  It might work on other versions too.
#
# MachTen users might need a fixed tr from ftp.tenon.com.  This should
# be described in the MachTen release notes.
#
# MachTen 2.x has its own hint file.
#
# This file has been put together by Andy Dougherty
# <doughera@lafcol.lafayette.edu> based on comments from lots of
# folks, especially 
# 	Mark Pease <peasem@primenet.com>
#	Martijn Koster <m.koster@webcrawler.com>
#	Richard Yeh <rcyeh@cco.caltech.edu>

#
# Comments, questions, and improvements welcome!
#
# MachTen 4.X does support dynamic loading, but perl doesn't
# know how to use it yet.
#
#  Last modified by Andy Dougherty   <doughera@lafcol.lafayette.edu>
#  Thu Feb  8 15:07:52 EST 1996

# Configure doesn't know how to parse the nm output.
usenm=undef

# At least on PowerMac, doubles must be aligned on 8 byte boundaries.
# I don't know if this is true for all MachTen systems, or how to
# determine this automatically.
alignbytes=8
