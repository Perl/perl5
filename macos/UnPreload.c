#include <stdlib.h>

#include <Types.h>
#include <Resources.h>
#include <QuickDraw.h>

void main(int argc, char ** argv)
{
	short	res = openresfile(argv[1]);
	Handle	rsrc;
	
	InitGraf(&qd.thePort);
	
	if (res == -1)
		exit(1);
	
	SetResLoad(false);
	
	if (rsrc = GetResource('CODE', 1))
		SetResAttrs(rsrc, GetResAttrs(rsrc) & ~resPreload);
	
	SetResLoad(true);
	
	UpdateResFile(res);
	CloseResFile(res);
}
