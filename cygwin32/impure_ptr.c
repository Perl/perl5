/*
 *	impure_ptr initialization routine. This is needed
 *	for any DLL that needs to output to the main (calling)
 *	executable's stdout, stderr, etc.
 */

struct _reent *_impure_ptr;  /* this will be the Dlls local copy of impure ptr */

/*********************************************
 * Function to set our local (in this dll)
 * copy of impure_ptr to the main's
 * (calling executable's) impure_ptr
 */
void impure_setup(struct _reent *_impure_ptrMain){

	_impure_ptr = _impure_ptrMain;

}
