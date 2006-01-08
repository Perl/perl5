/*
 * hmac.h: header file for HMAC-SHA-1/224/256/384/512 routines
 *
 * Ref: FIPS PUB 198 The Keyed-Hash Message Authentication Code
 *
 * Copyright (C) 2003-2005 Mark Shelor, All Rights Reserved
 *
 * Version: 5.32
 * Fri Dec  2 02:32:20 MST 2005
 *
 */

#ifndef _INCLUDE_HMAC_H_
#define _INCLUDE_HMAC_H_

#include "sha.h"

typedef struct {
	SHA *ksha;
	SHA *isha;
	SHA *osha;
	unsigned char key[SHA_MAX_BLOCK_BITS/8];
} HMAC;

#if defined(__STDC__) && __STDC__ != 0
	#define _HMAC_P(protos)	protos
#else
	#define _HMAC_P(protos)	()
#endif

#define _HMAC_STATE	HMAC *h
#define _HMAC_ALG	int alg
#define _HMAC_DATA	unsigned char *bitstr, unsigned long bitcnt
#define _HMAC_KEY	unsigned char *key, unsigned int keylen

HMAC		*hmacopen 	_HMAC_P((_HMAC_ALG, _HMAC_KEY));
unsigned long	 hmacwrite	_HMAC_P((_HMAC_DATA, _HMAC_STATE));
void		 hmacfinish	_HMAC_P((_HMAC_STATE));
unsigned char	*hmacdigest	_HMAC_P((_HMAC_STATE));
char		*hmachex	_HMAC_P((_HMAC_STATE));
char		*hmacbase64	_HMAC_P((_HMAC_STATE));
int		 hmacclose	_HMAC_P((_HMAC_STATE));

unsigned char	*hmac1digest	_HMAC_P((_HMAC_DATA, _HMAC_KEY));
char		*hmac1hex	_HMAC_P((_HMAC_DATA, _HMAC_KEY));
char		*hmac1base64	_HMAC_P((_HMAC_DATA, _HMAC_KEY));
unsigned char	*hmac224digest	_HMAC_P((_HMAC_DATA, _HMAC_KEY));
char		*hmac224hex	_HMAC_P((_HMAC_DATA, _HMAC_KEY));
char		*hmac224base64	_HMAC_P((_HMAC_DATA, _HMAC_KEY));
unsigned char	*hmac256digest	_HMAC_P((_HMAC_DATA, _HMAC_KEY));
char		*hmac256hex	_HMAC_P((_HMAC_DATA, _HMAC_KEY));
char		*hmac256base64	_HMAC_P((_HMAC_DATA, _HMAC_KEY));
unsigned char	*hmac384digest	_HMAC_P((_HMAC_DATA, _HMAC_KEY));
char		*hmac384hex	_HMAC_P((_HMAC_DATA, _HMAC_KEY));
char		*hmac384base64	_HMAC_P((_HMAC_DATA, _HMAC_KEY));
unsigned char	*hmac512digest	_HMAC_P((_HMAC_DATA, _HMAC_KEY));
char		*hmac512hex	_HMAC_P((_HMAC_DATA, _HMAC_KEY));
char		*hmac512base64	_HMAC_P((_HMAC_DATA, _HMAC_KEY));

#endif	/* _INCLUDE_HMAC_H_ */
