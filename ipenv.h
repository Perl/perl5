/*

    ipenv.h
    Interface for perl environment functions

*/

#ifndef __Inc__IPerlEnv___
#define __Inc__IPerlEnv___

class IPerlEnv
{
public:
    virtual char* Getenv(const char *varname, int &err) = 0;
    virtual int Putenv(const char *envstring, int &err) = 0;
    virtual char* LibPath(char *sfx, ...) =0;
};

#endif	/* __Inc__IPerlEnv___ */

