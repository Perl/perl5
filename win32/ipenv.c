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
	char		w32_perllib_root[MAX_PATH+1];
	HANDLE		w32_perldll_handle;
	CPerlObj	*pPerl;
};


BOOL GetRegStr(HKEY hkey, const char *lpszValueName, char *lpszDefault, char *lpszData, unsigned long *lpdwDataLen)
{	// Retrieve a REG_SZ or REG_EXPAND_SZ from the registry
	HKEY handle;
	DWORD type, dwDataLen = *lpdwDataLen;
	const char *subkey = "Software\\Perl";
	char szBuffer[MAX_PATH+1];
	long retval;

	retval = RegOpenKeyEx(hkey, subkey, 0, KEY_READ, &handle);
	if(retval == ERROR_SUCCESS) 
	{
		retval = RegQueryValueEx(handle, lpszValueName, 0, &type, (LPBYTE)lpszData, &dwDataLen);
		RegCloseKey(handle);
		if(retval == ERROR_SUCCESS && (type == REG_SZ || type == REG_EXPAND_SZ))
		{
			if(type != REG_EXPAND_SZ)
			{
				*lpdwDataLen = dwDataLen;
				return TRUE;
			}
			strcpy(szBuffer, lpszData);
			dwDataLen = ExpandEnvironmentStrings(szBuffer, lpszData, *lpdwDataLen);
			if(dwDataLen < *lpdwDataLen)
			{
				*lpdwDataLen = dwDataLen;
				return TRUE;
			}
		}
	}

	strcpy(lpszData, lpszDefault);
	return FALSE;
}

char* GetRegStr(const char *lpszValueName, char *lpszDefault, char *lpszData, unsigned long *lpdwDataLen)
{
	if(!GetRegStr(HKEY_CURRENT_USER, lpszValueName, lpszDefault, lpszData, lpdwDataLen))
	{
		GetRegStr(HKEY_LOCAL_MACHINE, lpszValueName, lpszDefault, lpszData, lpdwDataLen);
	}
	if(*lpszData == '\0')
		lpszData = NULL;
	return lpszData;
}


char *CPerlEnv::Getenv(const char *varname, int &err)
{
	char* ptr = getenv(varname);
	if(ptr == NULL)
	{
		unsigned long dwDataLen = sizeof(w32_perllib_root);
		if(strcmp("PERL5DB", varname) == 0)
			ptr = GetRegStr(varname, "", w32_perllib_root, &dwDataLen);
	}
	return ptr;
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
		      : (HINSTANCE)w32_perldll_handle,
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




