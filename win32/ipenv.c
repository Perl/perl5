/*

	ipenv.c
	Interface for perl environment functions

*/

#include <ipenv.h>
#include <stdlib.h>

class CPerlEnv : public IPerlEnv
{
public:
	CPerlEnv() { w32_perldll_handle = INVALID_HANDLE_VALUE; pPerl = NULL; };
	virtual char *Getenv(const char *varname, int &err);
	virtual int Putenv(const char *envstring, int &err);
	virtual char* LibPath(char *sfx, ...);

	inline void SetPerlObj(CPerlObj *p) { pPerl = p; };
protected:
	char	w32_perllib_root[MAX_PATH+1];
	HANDLE	w32_perldll_handle;
	CPerlObj *pPerl;
};

char *CPerlEnv::Getenv(const char *varname, int &err)
{
	return getenv(varname);
}

int CPerlEnv::Putenv(const char *envstring, int &err)
{
	return _putenv(envstring);
}

char* CPerlEnv::LibPath(char *sfx, ...)
{
    va_list ap;
    char *end;
    va_start(ap,sfx);
    GetModuleFileName((w32_perldll_handle == INVALID_HANDLE_VALUE) 
		      ? GetModuleHandle(NULL)
		      : w32_perldll_handle,
		      w32_perllib_root, 
		      sizeof(w32_perllib_root));
    *(end = strrchr(w32_perllib_root, '\\')) = '\0';
    if (stricmp(end-4,"\\bin") == 0)
     end -= 4;
    strcpy(end,"\\lib");
    while (sfx)
     {
      strcat(end,"\\");
      strcat(end,sfx);
      sfx = va_arg(ap,char *);
     }
    va_end(ap); 
    return (w32_perllib_root);
}




