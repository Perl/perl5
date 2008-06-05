/* $Id: hparser.c,v 2.134 2007/01/12 10:54:06 gisle Exp $
 *
 * Copyright 1999-2007, Gisle Aas
 * Copyright 1999-2000, Michael A. Chase
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 */

#ifndef EXTERN
#define EXTERN extern
#endif

#include "hctype.h"    /* isH...() macros */
#include "tokenpos.h"  /* dTOKEN; PUSH_TOKEN() */


static
struct literal_tag {
    int len;
    char* str;
    int is_cdata;
}
literal_mode_elem[] =
{
    {6, "script", 1},
    {5, "style", 1},
    {3, "xmp", 1},
    {9, "plaintext", 1},
    {5, "title", 0},
    {8, "textarea", 0},
    {0, 0, 0}
};

enum argcode {
    ARG_SELF = 1,  /* need to avoid '\0' in argspec string */
    ARG_TOKENS,
    ARG_TOKENPOS,
    ARG_TOKEN0,
    ARG_TAGNAME,
    ARG_TAG,
    ARG_ATTR,
    ARG_ATTRARR,
    ARG_ATTRSEQ,
    ARG_TEXT,
    ARG_DTEXT,
    ARG_IS_CDATA,
    ARG_SKIPPED_TEXT,
    ARG_OFFSET,
    ARG_OFFSET_END,
    ARG_LENGTH,
    ARG_LINE,
    ARG_COLUMN,
    ARG_EVENT,
    ARG_UNDEF,
    ARG_LITERAL, /* Always keep last */

    /* extra flags always encoded first */
    ARG_FLAG_FLAT_ARRAY
};

char *argname[] = {
    /* Must be in the same order as enum argcode */
    "self",     /* ARG_SELF */
    "tokens",   /* ARG_TOKENS */   
    "tokenpos", /* ARG_TOKENPOS */
    "token0",   /* ARG_TOKEN0 */
    "tagname",  /* ARG_TAGNAME */
    "tag",      /* ARG_TAG */
    "attr",     /* ARG_ATTR */
    "@attr",    /* ARG_ATTRARR */
    "attrseq",  /* ARG_ATTRSEQ */
    "text",     /* ARG_TEXT */
    "dtext",    /* ARG_DTEXT */
    "is_cdata", /* ARG_IS_CDATA */
    "skipped_text", /* ARG_SKIPPED_TEXT */
    "offset",   /* ARG_OFFSET */
    "offset_end", /* ARG_OFFSET_END */
    "length",   /* ARG_LENGTH */
    "line",     /* ARG_LINE */
    "column",   /* ARG_COLUMN */
    "event",    /* ARG_EVENT */
    "undef",    /* ARG_UNDEF */
    /* ARG_LITERAL (not compared) */
    /* ARG_FLAG_FLAT_ARRAY */
};

#define CASE_SENSITIVE(p_state) \
         ((p_state)->xml_mode || (p_state)->case_sensitive)
#define STRICT_NAMES(p_state) \
         ((p_state)->xml_mode || (p_state)->strict_names)
#define ALLOW_EMPTY_TAG(p_state) \
         ((p_state)->xml_mode || (p_state)->empty_element_tags)

static void flush_pending_text(PSTATE* p_state, SV* self);

/*
 * Parser functions.
 *
 *   parse()                       - top level entry point.
 *                                   deals with text and calls one of its
 *                                   subordinate parse_*() routines after
 *                                   looking at the first char after "<"
 *     parse_decl()                - deals with declarations         <!...>
 *       parse_comment()           - deals with <!-- ... -->
 *       parse_marked_section      - deals with <![ ... [ ... ]]>
 *     parse_end()                 - deals with end tags             </...>
 *     parse_start()               - deals with start tags           <A...>
 *     parse_process()             - deals with process instructions <?...>
 *     parse_null()                - deals with anything else        <....>
 *
 *     report_event() - called whenever any of the parse*() routines
 *                      has recongnized something.
 */

static void
report_event(PSTATE* p_state,
	     event_id_t event,
	     char *beg, char *end, U32 utf8,
	     token_pos_t *tokens, int num_tokens,
	     SV* self
	    )
{
    struct p_handler *h;
    dTHX;
    dSP;
    AV *array;
    STRLEN my_na;
    char *argspec;
    char *s;
    STRLEN offset;
    STRLEN line;
    STRLEN column;

#ifdef UNICODE_HTML_PARSER
    #define CHR_DIST(a,b) (utf8 ? utf8_distance((U8*)(a),(U8*)(b)) : (a) - (b))
#else
    #define CHR_DIST(a,b) ((a) - (b))
#endif

    /* some events might still fire after a handler has signaled eof
     * so suppress them here.
     */
    if (p_state->eof)
	return;

    /* capture offsets */
    offset = p_state->offset;
    line = p_state->line;
    column = p_state->column;

#if 0
    {  /* used for debugging at some point */
	char *s = beg;
	int i;

	/* print debug output */
	switch(event) {
	case E_DECLARATION: printf("DECLARATION"); break;
	case E_COMMENT:     printf("COMMENT"); break;
	case E_START:       printf("START"); break;
	case E_END:         printf("END"); break;
	case E_TEXT:        printf("TEXT"); break;
	case E_PROCESS:     printf("PROCESS"); break;
	case E_NONE:        printf("NONE"); break;
	default:            printf("EVENT #%d", event); break;
	}

	printf(" [");
	while (s < end) {
	    if (*s == '\n') {
		putchar('\\'); putchar('n');
	    }
	    else
		putchar(*s);
	    s++;
	}
	printf("] %d\n", end - beg);
	for (i = 0; i < num_tokens; i++) {
	    printf("  token %d: %d %d\n",
		   i,
		   tokens[i].beg - beg,
		   tokens[i].end - tokens[i].beg);
	}
    }
#endif

    if (p_state->pending_end_tag && event != E_TEXT && event != E_COMMENT) {
	token_pos_t t;
	char dummy;
	t.beg = p_state->pending_end_tag;
	t.end = p_state->pending_end_tag + strlen(p_state->pending_end_tag);
	p_state->pending_end_tag = 0;
	report_event(p_state, E_END, &dummy, &dummy, 0, &t, 1, self);
	SPAGAIN;
    }

    /* update offsets */
    p_state->offset += CHR_DIST(end, beg);
    if (line) {
	char *s = beg;
	char *nl = NULL;
	while (s < end) {
	    if (*s == '\n') {
		p_state->line++;
		nl = s;
	    }
	    s++;
	}
	if (nl)
	    p_state->column = CHR_DIST(end, nl) - 1;
	else
	    p_state->column += CHR_DIST(end, beg);
    }

    if (event == E_NONE)
	goto IGNORE_EVENT;
    
#ifdef MARKED_SECTION
    if (p_state->ms == MS_IGNORE)
	goto IGNORE_EVENT;
#endif

    /* tag filters */
    if (p_state->ignore_tags || p_state->report_tags || p_state->ignore_elements) {

	if (event == E_START || event == E_END) {
	    SV* tagname = p_state->tmp;

	    assert(num_tokens >= 1);
	    sv_setpvn(tagname, tokens[0].beg, tokens[0].end - tokens[0].beg);
	    if (utf8)
		SvUTF8_on(tagname);
	    else
		SvUTF8_off(tagname);
	    if (!CASE_SENSITIVE(p_state))
		sv_lower(aTHX_ tagname);

	    if (p_state->ignoring_element) {
		if (sv_eq(p_state->ignoring_element, tagname)) {
		    if (event == E_START)
			p_state->ignore_depth++;
		    else if (--p_state->ignore_depth == 0) {
			SvREFCNT_dec(p_state->ignoring_element);
			p_state->ignoring_element = 0;
		    }
		}
		goto IGNORE_EVENT;
	    }

	    if (p_state->ignore_elements &&
		hv_fetch_ent(p_state->ignore_elements, tagname, 0, 0))
	    {
		if (event == E_START) {
		    p_state->ignoring_element = newSVsv(tagname);
		    p_state->ignore_depth = 1;
		}
		goto IGNORE_EVENT;
	    }

	    if (p_state->ignore_tags &&
		hv_fetch_ent(p_state->ignore_tags, tagname, 0, 0))
	    {
		goto IGNORE_EVENT;
	    }
	    if (p_state->report_tags &&
		!hv_fetch_ent(p_state->report_tags, tagname, 0, 0))
	    {
		goto IGNORE_EVENT;
	    }
	}
	else if (p_state->ignoring_element) {
	    goto IGNORE_EVENT;
	}
    }

    h = &p_state->handlers[event];
    if (!h->cb) {
	/* event = E_DEFAULT; */
	h = &p_state->handlers[E_DEFAULT];
	if (!h->cb)
	    goto IGNORE_EVENT;
    }

    if (SvTYPE(h->cb) != SVt_PVAV && !SvTRUE(h->cb)) {
	/* FALSE scalar ('' or 0) means IGNORE this event */
	return;
    }

    if (p_state->unbroken_text && event == E_TEXT) {
	/* should buffer text */
	if (!p_state->pend_text)
	    p_state->pend_text = newSV(256);
	if (SvOK(p_state->pend_text)) {
	    if (p_state->is_cdata != p_state->pend_text_is_cdata) {
		flush_pending_text(p_state, self);
		SPAGAIN;
		goto INIT_PEND_TEXT;
	    }
	}
	else {
	INIT_PEND_TEXT:
	    p_state->pend_text_offset = offset;
	    p_state->pend_text_line = line;
	    p_state->pend_text_column = column;
	    p_state->pend_text_is_cdata = p_state->is_cdata;
	    sv_setpvn(p_state->pend_text, "", 0);
	    if (!utf8)
		SvUTF8_off(p_state->pend_text);
	}
#ifdef UNICODE_HTML_PARSER
	if (utf8 && !SvUTF8(p_state->pend_text))
	    sv_utf8_upgrade(p_state->pend_text);
	if (utf8 || !SvUTF8(p_state->pend_text)) {
	    sv_catpvn(p_state->pend_text, beg, end - beg);
	}
	else {
	    SV *tmp = newSVpvn(beg, end - beg);
	    sv_utf8_upgrade(tmp);
	    sv_catsv(p_state->pend_text, tmp);
	    SvREFCNT_dec(tmp);
	}
#else
	sv_catpvn(p_state->pend_text, beg, end - beg);
#endif
	return;
    }
    else if (p_state->pend_text && SvOK(p_state->pend_text)) {
	flush_pending_text(p_state, self);
	SPAGAIN;
    }

    /* At this point we have decided to generate an event callback */

    argspec = h->argspec ? SvPV(h->argspec, my_na) : "";

    if (SvTYPE(h->cb) == SVt_PVAV) {
	
	if (*argspec == ARG_FLAG_FLAT_ARRAY) {
	    argspec++;
	    array = (AV*)h->cb;
	}
	else {
	    /* start sub-array for accumulator array */
	    array = newAV();
	}
    }
    else {
	array = 0;
	if (*argspec == ARG_FLAG_FLAT_ARRAY)
	    argspec++;

	/* start argument stack for callback */
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
    }

    for (s = argspec; *s; s++) {
	SV* arg = 0;
	int push_arg = 1;
	enum argcode argcode = (enum argcode)*s;

	switch( argcode ) {

	case ARG_SELF:
	    arg = sv_mortalcopy(self);
	    break;

	case ARG_TOKENS:
	    if (num_tokens >= 1) {
		AV* av = newAV();
		SV* prev_token = &PL_sv_undef;
		int i;
		av_extend(av, num_tokens);
		for (i = 0; i < num_tokens; i++) {
		    if (tokens[i].beg) {
			prev_token = newSVpvn(tokens[i].beg, tokens[i].end-tokens[i].beg);
			if (utf8)
			    SvUTF8_on(prev_token);
			av_push(av, prev_token);
		    }
		    else { /* boolean */
			av_push(av, p_state->bool_attr_val
				? newSVsv(p_state->bool_attr_val)
				: newSVsv(prev_token));
		    }
		}
		arg = sv_2mortal(newRV_noinc((SV*)av));
	    }
	    break;

	case ARG_TOKENPOS:
	    if (num_tokens >= 1 && tokens[0].beg >= beg) {
		AV* av = newAV();
		int i;
		av_extend(av, num_tokens*2);
		for (i = 0; i < num_tokens; i++) {
		    if (tokens[i].beg) {
			av_push(av, newSViv(CHR_DIST(tokens[i].beg, beg)));
			av_push(av, newSViv(CHR_DIST(tokens[i].end, tokens[i].beg)));
		    }
		    else { /* boolean tag value */
			av_push(av, newSViv(0));
			av_push(av, newSViv(0));
		    }
		}
		arg = sv_2mortal(newRV_noinc((SV*)av));
	    }
	    break;

	case ARG_TOKEN0:
	case ARG_TAGNAME:
	    /* fall through */

	case ARG_TAG:
	    if (num_tokens >= 1) {
		arg = sv_2mortal(newSVpvn(tokens[0].beg,
					  tokens[0].end - tokens[0].beg));
		if (utf8)
		    SvUTF8_on(arg);
		if (!CASE_SENSITIVE(p_state) && argcode != ARG_TOKEN0)
		    sv_lower(aTHX_ arg);
		if (argcode == ARG_TAG && event != E_START) {
		    char *e_type = "!##/#?#";
		    sv_insert(arg, 0, 0, &e_type[event], 1);
		}
	    }
	    break;

	case ARG_ATTR:
	case ARG_ATTRARR:
	    if (event == E_START) {
		HV* hv;
		int i;
		if (argcode == ARG_ATTR) {
		    hv = newHV();
		    arg = sv_2mortal(newRV_noinc((SV*)hv));
		}
		else {
#ifdef __GNUC__
		    /* gcc -Wall reports this variable as possibly used uninitialized */
		    hv = 0;
#endif
		    push_arg = 0;  /* deal with argument pushing here */
		}

		for (i = 1; i < num_tokens; i += 2) {
		    SV* attrname = newSVpvn(tokens[i].beg,
					    tokens[i].end-tokens[i].beg);
		    SV* attrval;

		    if (utf8)
			SvUTF8_on(attrname);
		    if (tokens[i+1].beg) {
			char *beg = tokens[i+1].beg;
			STRLEN len = tokens[i+1].end - beg;
			if (*beg == '"' || *beg == '\'') {
			    assert(len >= 2 && *beg == beg[len-1]);
			    beg++; len -= 2;
			}
			attrval = newSVpvn(beg, len);
			if (utf8)
			    SvUTF8_on(attrval);
			if (!p_state->attr_encoded) {
#ifdef UNICODE_HTML_PARSER
			    if (p_state->utf8_mode)
				sv_utf8_decode(attrval);
#endif
			    decode_entities(aTHX_ attrval, p_state->entity2char, 0);
			    if (p_state->utf8_mode)
				SvUTF8_off(attrval);
			}
		    }
		    else { /* boolean */
			if (p_state->bool_attr_val)
			    attrval = newSVsv(p_state->bool_attr_val);
			else
			    attrval = newSVsv(attrname);
		    }

		    if (!CASE_SENSITIVE(p_state))
			sv_lower(aTHX_ attrname);

		    if (argcode == ARG_ATTR) {
			if (hv_exists_ent(hv, attrname, 0) ||
			    !hv_store_ent(hv, attrname, attrval, 0)) {
			    SvREFCNT_dec(attrval);
			}
			SvREFCNT_dec(attrname);
		    }
		    else { /* ARG_ATTRARR */
			if (array) {
			    av_push(array, attrname);
			    av_push(array, attrval);
			}
			else {
			    XPUSHs(sv_2mortal(attrname));
			    XPUSHs(sv_2mortal(attrval));
			}
		    }
		}
	    }
	    else if (argcode == ARG_ATTRARR) {
		push_arg = 0;
	    }
	    break;

	case ARG_ATTRSEQ:       /* (v2 compatibility stuff) */
	    if (event == E_START) {
		AV* av = newAV();
		int i;
		for (i = 1; i < num_tokens; i += 2) {
		    SV* attrname = newSVpvn(tokens[i].beg,
					    tokens[i].end-tokens[i].beg);
		    if (utf8)
			SvUTF8_on(attrname);
		    if (!CASE_SENSITIVE(p_state))
			sv_lower(aTHX_ attrname);
		    av_push(av, attrname);
		}
		arg = sv_2mortal(newRV_noinc((SV*)av));
	    }
	    break;
	
	case ARG_TEXT:
	    arg = sv_2mortal(newSVpvn(beg, end - beg));
	    if (utf8)
		SvUTF8_on(arg);
	    break;

	case ARG_DTEXT:
	    if (event == E_TEXT) {
		arg = sv_2mortal(newSVpvn(beg, end - beg));
		if (utf8)
		    SvUTF8_on(arg);
		if (!p_state->is_cdata) {
#ifdef UNICODE_HTML_PARSER
		    if (p_state->utf8_mode)
			sv_utf8_decode(arg);
#endif
		    decode_entities(aTHX_ arg, p_state->entity2char, 1);
		    if (p_state->utf8_mode)
			SvUTF8_off(arg);
		}
	    }
	    break;
      
	case ARG_IS_CDATA:
	    if (event == E_TEXT) {
		arg = boolSV(p_state->is_cdata);
	    }
	    break;

        case ARG_SKIPPED_TEXT:
	    arg = sv_2mortal(p_state->skipped_text);
	    p_state->skipped_text = newSVpvn("", 0);
            break;

	case ARG_OFFSET:
	    arg = sv_2mortal(newSViv(offset));
	    break;

	case ARG_OFFSET_END:
	    arg = sv_2mortal(newSViv(offset + CHR_DIST(end, beg)));
	    break;

	case ARG_LENGTH:
	    arg = sv_2mortal(newSViv(CHR_DIST(end, beg)));
	    break;

	case ARG_LINE:
	    arg = sv_2mortal(newSViv(line));
	    break;

	case ARG_COLUMN:
	    arg = sv_2mortal(newSViv(column));
	    break;

	case ARG_EVENT:
	    assert(event >= 0 && event < EVENT_COUNT);
	    arg = sv_2mortal(newSVpv(event_id_str[event], 0));
	    break;

	case ARG_LITERAL:
	{
	    int len = (unsigned char)s[1];
	    arg = sv_2mortal(newSVpvn(s+2, len));
	    if (SvUTF8(h->argspec))
		SvUTF8_on(arg);
	    s += len + 1;
	}
	break;

	case ARG_UNDEF:
	    arg = sv_mortalcopy(&PL_sv_undef);
	    break;
      
	default:
	    arg = sv_2mortal(newSVpvf("Bad argspec %d", *s));
	    break;
	}

	if (push_arg) {
	    if (!arg)
		arg = sv_mortalcopy(&PL_sv_undef);

	    if (array) {
		/* have to fix mortality here or add mortality to
		 * XPUSHs after removing it from the switch cases.
		 */
		av_push(array, SvREFCNT_inc(arg));
	    }
	    else {
		XPUSHs(arg);
	    }
	}
    }

    if (array) {
	if (array != (AV*)h->cb)
	    av_push((AV*)h->cb, newRV_noinc((SV*)array));
    }
    else {
	PUTBACK;

	if ((enum argcode)*argspec == ARG_SELF && !SvROK(h->cb)) {
	    char *method = SvPV(h->cb, my_na);
	    perl_call_method(method, G_DISCARD | G_EVAL | G_VOID);
	}
	else {
	    perl_call_sv(h->cb, G_DISCARD | G_EVAL | G_VOID);
	}

	if (SvTRUE(ERRSV)) {
	    RETHROW;
	}

	FREETMPS;
	LEAVE;
    }
    if (p_state->skipped_text)
	SvCUR_set(p_state->skipped_text, 0);
    return;

IGNORE_EVENT:
    if (p_state->skipped_text) {
	if (event != E_TEXT && p_state->pend_text && SvOK(p_state->pend_text))
	    flush_pending_text(p_state, self);
#ifdef UNICODE_HTML_PARSER
	if (utf8 && !SvUTF8(p_state->skipped_text))
	    sv_utf8_upgrade(p_state->skipped_text);
	if (utf8 || !SvUTF8(p_state->skipped_text)) {
#endif
	    sv_catpvn(p_state->skipped_text, beg, end - beg);
#ifdef UNICODE_HTML_PARSER
	}
	else {
	    SV *tmp = newSVpvn(beg, end - beg);
	    sv_utf8_upgrade(tmp);
	    sv_catsv(p_state->pend_text, tmp);
	    SvREFCNT_dec(tmp);
	}
#endif
    }
#undef CHR_DIST    
    return;
}


EXTERN SV*
argspec_compile(SV* src, PSTATE* p_state)
{
    dTHX;
    SV* argspec = newSVpvn("", 0);
    STRLEN len;
    char *s = SvPV(src, len);
    char *end = s + len;

    if (SvUTF8(src))
	SvUTF8_on(argspec);

    while (isHSPACE(*s))
	s++;

    if (*s == '@') {
	/* try to deal with '@{ ... }' wrapping */
	char *tmp = s + 1;
	while (isHSPACE(*tmp))
	    tmp++;
	if (*tmp == '{') {
	    char c = ARG_FLAG_FLAT_ARRAY;
	    sv_catpvn(argspec, &c, 1);
	    tmp++;
	    while (isHSPACE(*tmp))
		tmp++;
	    s = tmp;
	}
    }
    while (s < end) {
	if (isHNAME_FIRST(*s) || *s == '@') {
	    char *name = s;
	    int a = ARG_SELF;
	    char **arg_name;

	    s++;
	    while (isHNAME_CHAR(*s))
		s++;

	    /* check identifier */
	    for ( arg_name = argname; a < ARG_LITERAL ; ++a, ++arg_name ) {
		if (strnEQ(*arg_name, name, s - name) &&
		    (*arg_name)[s - name] == '\0')
		    break;
	    }
	    if (a < ARG_LITERAL) {
		char c = (unsigned char) a;
		sv_catpvn(argspec, &c, 1);

		if (a == ARG_LINE || a == ARG_COLUMN) {
		    if (!p_state->line)
			p_state->line = 1; /* enable tracing of line/column */
		}
		if (a == ARG_SKIPPED_TEXT) {
		    if (!p_state->skipped_text) {
			p_state->skipped_text = newSVpvn("", 0);
                    }
                }
		if (a == ARG_ATTR || a == ARG_ATTRARR || a == ARG_DTEXT) {
		    p_state->argspec_entity_decode++;
		}
	    }
	    else {
		croak("Unrecognized identifier %.*s in argspec", s - name, name);
	    }
	}
	else if (*s == '"' || *s == '\'') {
	    char *string_beg = s;
	    s++;
	    while (s < end && *s != *string_beg && *s != '\\')
		s++;
	    if (*s == *string_beg) {
		/* literal */
		int len = s - string_beg - 1;
		unsigned char buf[2];
		if (len > 255)
		    croak("Literal string is longer than 255 chars in argspec");
		buf[0] = ARG_LITERAL;
		buf[1] = len;
		sv_catpvn(argspec, (char*)buf, 2);
		sv_catpvn(argspec, string_beg+1, len);
		s++;
	    }
	    else if (*s == '\\') {
		croak("Backslash reserved for literal string in argspec");
	    }
	    else {
		croak("Unterminated literal string in argspec");
	    }
	}
	else {
	    croak("Bad argspec (%s)", s);
	}

	while (isHSPACE(*s))
	    s++;
	
	if (*s == '}' && SvPVX(argspec)[0] == ARG_FLAG_FLAT_ARRAY) {
	    /* end of '@{ ... }' */
	    s++;
	    while (isHSPACE(*s))
		s++;
	    if (s < end)
		croak("Bad argspec: stuff after @{...} (%s)", s);
	}

	if (s == end)
	    break;
	if (*s != ',') {
	    croak("Missing comma separator in argspec");
	}
	s++;
	while (isHSPACE(*s))
	    s++;
    }
    return argspec;
}


static void
flush_pending_text(PSTATE* p_state, SV* self)
{
    dTHX;
    bool   old_unbroken_text = p_state->unbroken_text;
    SV*    old_pend_text     = p_state->pend_text;
    bool   old_is_cdata      = p_state->is_cdata;
    STRLEN old_offset        = p_state->offset;
    STRLEN old_line          = p_state->line;
    STRLEN old_column        = p_state->column;

    assert(p_state->pend_text && SvOK(p_state->pend_text));

    p_state->unbroken_text = 0;
    p_state->pend_text     = 0;
    p_state->is_cdata      = p_state->pend_text_is_cdata;
    p_state->offset        = p_state->pend_text_offset;
    p_state->line          = p_state->pend_text_line;
    p_state->column        = p_state->pend_text_column;

    report_event(p_state, E_TEXT,
		 SvPVX(old_pend_text), SvEND(old_pend_text), 
		 SvUTF8(old_pend_text), 0, 0, self);
    SvOK_off(old_pend_text);

    p_state->unbroken_text = old_unbroken_text;
    p_state->pend_text     = old_pend_text;
    p_state->is_cdata      = old_is_cdata;
    p_state->offset        = old_offset;
    p_state->line          = old_line;
    p_state->column        = old_column;
}

static char*
skip_until_gt(char *beg, char *end)
{
    /* tries to emulate quote skipping behaviour observed in MSIE */
    char *s = beg;
    char quote = '\0';
    char prev = ' ';
    while (s < end) {
	if (!quote && *s == '>')
	    return s;
	if (*s == '"' || *s == '\'') {
	    if (*s == quote) {
		quote = '\0';  /* end of quoted string */
	    }
	    else if (!quote && (prev == ' ' || prev == '=')) {
		quote = *s;
	    }
	}
	prev = *s++;
    }
    return end;
}

static char*
parse_comment(PSTATE* p_state, char *beg, char *end, U32 utf8, SV* self)
{
    char *s = beg;

    if (p_state->strict_comment) {
	dTOKENS(4);
	char *start_com = s;  /* also used to signal inside/outside */

	while (1) {
	    /* try to locate "--" */
	FIND_DASH_DASH:
	    /* printf("find_dash_dash: [%s]\n", s); */
	    while (s < end && *s != '-' && *s != '>')
		s++;

	    if (s == end) {
		FREE_TOKENS;
		return beg;
	    }

	    if (*s == '>') {
		s++;
		if (start_com)
		    goto FIND_DASH_DASH;

		/* we are done recognizing all comments, make callbacks */
		report_event(p_state, E_COMMENT,
			     beg - 4, s, utf8,
			     tokens, num_tokens,
			     self);
		FREE_TOKENS;

		return s;
	    }

	    s++;
	    if (s == end) {
		FREE_TOKENS;
		return beg;
	    }

	    if (*s == '-') {
		/* two dashes in a row seen */
		s++;
		/* do something */
		if (start_com) {
		    PUSH_TOKEN(start_com, s-2);
		    start_com = 0;
		}
		else {
		    start_com = s;
		}
	    }
	}
    }
    else if (p_state->no_dash_dash_comment_end) {
	token_pos_t token;
        token.beg = beg;
        /* a lone '>' signals end-of-comment */
	while (s < end && *s != '>')
	    s++;
	token.end = s;
	if (s < end) {
	    s++;
	    report_event(p_state, E_COMMENT, beg-4, s, utf8, &token, 1, self);
	    return s;
	}
	else {
	    return beg;
	}
    }
    else { /* non-strict comment */
	token_pos_t token;
	token.beg = beg;
	/* try to locate /--\s*>/ which signals end-of-comment */
    LOCATE_END:
	while (s < end && *s != '-')
	    s++;
	token.end = s;
	if (s < end) {
	    s++;
	    if (*s == '-') {
		s++;
		while (isHSPACE(*s))
		    s++;
		if (*s == '>') {
		    s++;
		    /* yup */
		    report_event(p_state, E_COMMENT, beg-4, s, utf8, &token, 1, self);
		    return s;
		}
	    }
	    if (s < end) {
		s = token.end + 1;
		goto LOCATE_END;
	    }
	}
    
	if (s == end)
	    return beg;
    }

    return 0;
}


#ifdef MARKED_SECTION

static void
marked_section_update(PSTATE* p_state)
{
    dTHX;
    /* we look at p_state->ms_stack to determine p_state->ms */
    AV* ms_stack = p_state->ms_stack;
    p_state->ms = MS_NONE;

    if (ms_stack) {
	int stack_len = av_len(ms_stack);
	int stack_idx;
	for (stack_idx = 0; stack_idx <= stack_len; stack_idx++) {
	    SV** svp = av_fetch(ms_stack, stack_idx, 0);
	    if (svp) {
		AV* tokens = (AV*)SvRV(*svp);
		int tokens_len = av_len(tokens);
		int i;
		assert(SvTYPE(tokens) == SVt_PVAV);
		for (i = 0; i <= tokens_len; i++) {
		    SV** svp = av_fetch(tokens, i, 0);
		    if (svp) {
			STRLEN len;
			char *token_str = SvPV(*svp, len);
			enum marked_section_t token;
			if (strEQ(token_str, "include"))
			    token = MS_INCLUDE;
			else if (strEQ(token_str, "rcdata"))
			    token = MS_RCDATA;
			else if (strEQ(token_str, "cdata"))
			    token = MS_CDATA;
			else if (strEQ(token_str, "ignore"))
			    token = MS_IGNORE;
			else
			    token = MS_NONE;
			if (p_state->ms < token)
			    p_state->ms = token;
		    }
		}
	    }
	}
    }
    /* printf("MS %d\n", p_state->ms); */
    p_state->is_cdata = (p_state->ms == MS_CDATA);
    return;
}


static char*
parse_marked_section(PSTATE* p_state, char *beg, char *end, U32 utf8, SV* self)
{
    dTHX;
    char *s;
    AV* tokens = 0;

    if (!p_state->marked_sections)
	return 0;

    assert(beg[0] == '<');
    assert(beg[1] == '!');
    assert(beg[2] == '[');
    s = beg + 3;

FIND_NAMES:
    while (isHSPACE(*s))
	s++;
    while (isHNAME_FIRST(*s)) {
	char *name_start = s;
	char *name_end;
	SV *name;
	s++;
	while (isHNAME_CHAR(*s))
	    s++;
	name_end = s;
	while (isHSPACE(*s))
	    s++;
	if (s == end)
	    goto PREMATURE;

	if (!tokens)
	    tokens = newAV();
	name = newSVpvn(name_start, name_end - name_start);
	if (utf8)
	    SvUTF8_on(name);
	av_push(tokens, sv_lower(aTHX_ name));
    }
    if (*s == '-') {
	s++;
	if (*s == '-') {
	    /* comment */
	    s++;
	    while (1) {
		while (s < end && *s != '-')
		    s++;
		if (s == end)
		    goto PREMATURE;

		s++;  /* skip first '-' */
		if (*s == '-') {
		    s++;
		    /* comment finished */
		    goto FIND_NAMES;
		}
	    }      
	}
	else
	    goto FAIL;
      
    }
    if (*s == '[') {
	s++;
	/* yup */

	if (!tokens) {
	    tokens = newAV();
	    av_push(tokens, newSVpvn("include", 7));
	}

	if (!p_state->ms_stack)
	    p_state->ms_stack = newAV();
	av_push(p_state->ms_stack, newRV_noinc((SV*)tokens));
	marked_section_update(p_state);
	report_event(p_state, E_NONE, beg, s, utf8, 0, 0, self);
	return s;
    }

FAIL:
    SvREFCNT_dec(tokens);
    return 0; /* not yet implemented */
  
PREMATURE:
    SvREFCNT_dec(tokens);
    return beg;
}
#endif


static char*
parse_decl(PSTATE* p_state, char *beg, char *end, U32 utf8, SV* self)
{
    char *s = beg + 2;

    if (*s == '-') {
	/* comment? */

	char *tmp;
	s++;
	if (s == end)
	    return beg;

	if (*s != '-')
	    goto DECL_FAIL;  /* nope, illegal */

	/* yes, two dashes seen */
	s++;

	tmp = parse_comment(p_state, s, end, utf8, self);
	return (tmp == s) ? beg : tmp;
    }

#ifdef MARKED_SECTION
    if (*s == '[') {
	/* marked section */
	char *tmp;
	tmp = parse_marked_section(p_state, beg, end, utf8, self);
	if (!tmp)
	    goto DECL_FAIL;
	return tmp;
    }
#endif

    if (*s == '>') {
	/* make <!> into empty comment <SGML Handbook 36:32> */
	token_pos_t token;
	token.beg = s;
	token.end = s;
	s++;
	report_event(p_state, E_COMMENT, beg, s, utf8, &token, 1, self);
	return s;
    }

    if (isALPHA(*s)) {
	dTOKENS(8);
	char *decl_id = s;
	STRLEN decl_id_len;

	s++;
	/* declaration */
	while (s < end && isHNAME_CHAR(*s))
	    s++;
	decl_id_len = s - decl_id;
	if (s == end)
	    goto PREMATURE;

	/* just hardcode a few names as the recognized declarations */
	if (!((decl_id_len == 7 &&
	       strnEQx(decl_id, "DOCTYPE", 7, !CASE_SENSITIVE(p_state))) ||
	      (decl_id_len == 6 &&
	       strnEQx(decl_id, "ENTITY",  6, !CASE_SENSITIVE(p_state)))
	    )
	    )
	{
	    goto FAIL;
	}

	/* first word available */
	PUSH_TOKEN(decl_id, s);

	while (1) {
	    while (s < end && isHSPACE(*s))
		s++;

	    if (s == end)
		goto PREMATURE;

	    if (*s == '"' || *s == '\'') {
		char *str_beg = s;
		s++;
		while (s < end && *s != *str_beg)
		    s++;
		if (s == end)
		    goto PREMATURE;
		s++;
		PUSH_TOKEN(str_beg, s);
	    }
	    else if (*s == '-') {
		/* comment */
		char *com_beg = s;
		s++;
		if (s == end)
		    goto PREMATURE;
		if (*s != '-')
		    goto FAIL;
		s++;

		while (1) {
		    while (s < end && *s != '-')
			s++;
		    if (s == end)
			goto PREMATURE;
		    s++;
		    if (s == end)
			goto PREMATURE;
		    if (*s == '-') {
			s++;
			PUSH_TOKEN(com_beg, s);
			break;
		    }
		}
	    }
	    else if (*s != '>') {
		/* plain word */
		char *word_beg = s;
		s++;
		while (s < end && isHNOT_SPACE_GT(*s))
		    s++;
		if (s == end)
		    goto PREMATURE;
		PUSH_TOKEN(word_beg, s);
	    }
	    else {
		break;
	    }
	}

	if (s == end)
	    goto PREMATURE;
	if (*s == '>') {
	    s++;
	    report_event(p_state, E_DECLARATION, beg, s, utf8, tokens, num_tokens, self);
	    FREE_TOKENS;
	    return s;
	}

    FAIL:
	FREE_TOKENS;
	goto DECL_FAIL;

    PREMATURE:
	FREE_TOKENS;
	return beg;

    }

DECL_FAIL:
    if (p_state->strict_comment)
	return 0;

    /* consider everything up to the first '>' a comment */
    while (s < end && *s != '>')
	s++;
    if (s < end) {
	token_pos_t token;
	token.beg = beg + 2;
	token.end = s;
	s++;
	report_event(p_state, E_COMMENT, beg, s, utf8, &token, 1, self);
	return s;
    }
    else {
	return beg;
    }
}


static char*
parse_start(PSTATE* p_state, char *beg, char *end, U32 utf8, SV* self)
{
    char *s = beg;
    int empty_tag = 0;
    dTOKENS(16);

    hctype_t tag_name_first, tag_name_char;
    hctype_t attr_name_first, attr_name_char;

    if (STRICT_NAMES(p_state)) {
	tag_name_first = attr_name_first = HCTYPE_NAME_FIRST;
	tag_name_char  = attr_name_char  = HCTYPE_NAME_CHAR;
    }
    else {
	tag_name_first = tag_name_char = HCTYPE_NOT_SPACE_GT;
	attr_name_first = HCTYPE_NOT_SPACE_GT;
	attr_name_char  = HCTYPE_NOT_SPACE_EQ_GT;
    }

    s += 2;

    while (s < end && isHCTYPE(*s, tag_name_char)) {
	if (*s == '/' && ALLOW_EMPTY_TAG(p_state)) {
	    if ((s + 1) == end)
		goto PREMATURE;
	    if (*(s + 1) == '>')
		break;
	}
	s++;
    }
    PUSH_TOKEN(beg+1, s);  /* tagname */

    while (isHSPACE(*s))
	s++;
    if (s == end)
	goto PREMATURE;

    while (isHCTYPE(*s, attr_name_first)) {
	/* attribute */
	char *attr_name_beg = s;
	char *attr_name_end;
	if (*s == '/' && ALLOW_EMPTY_TAG(p_state)) {
	    if ((s + 1) == end)
		goto PREMATURE;
	    if (*(s + 1) == '>')
		break;
	}
	s++;
	while (s < end && isHCTYPE(*s, attr_name_char)) {
	    if (*s == '/' && ALLOW_EMPTY_TAG(p_state)) {
		if ((s + 1) == end)
		    goto PREMATURE;
		if (*(s + 1) == '>')
		    break;
	    }
	    s++;
	}
	if (s == end)
	    goto PREMATURE;

	attr_name_end = s;
	PUSH_TOKEN(attr_name_beg, attr_name_end); /* attr name */

	while (isHSPACE(*s))
	    s++;
	if (s == end)
	    goto PREMATURE;

	if (*s == '=') {
	    /* with a value */
	    s++;
	    while (isHSPACE(*s))
		s++;
	    if (s == end)
		goto PREMATURE;
	    if (*s == '>') {
		/* parse it similar to ="" */
		PUSH_TOKEN(s, s);
		break;
	    }
	    if (*s == '"' || *s == '\'') {
		char *str_beg = s;
		s++;
		while (s < end && *s != *str_beg)
		    s++;
		if (s == end)
		    goto PREMATURE;
		s++;
		PUSH_TOKEN(str_beg, s);
	    }
	    else {
		char *word_start = s;
		while (s < end && isHNOT_SPACE_GT(*s)) {
		    if (*s == '/' && ALLOW_EMPTY_TAG(p_state)) {
			if ((s + 1) == end)
			    goto PREMATURE;
			if (*(s + 1) == '>')
			    break;
		    }
		    s++;
		}
		if (s == end)
		    goto PREMATURE;
		PUSH_TOKEN(word_start, s);
	    }
	    while (isHSPACE(*s))
		s++;
	    if (s == end)
		goto PREMATURE;
	}
	else {
	    PUSH_TOKEN(0, 0); /* boolean attr value */
	}
    }

    if (ALLOW_EMPTY_TAG(p_state) && *s == '/') {
	s++;
	if (s == end)
	    goto PREMATURE;
	empty_tag = 1;
    }

    if (*s == '>') {
	s++;
	/* done */
	report_event(p_state, E_START, beg, s, utf8, tokens, num_tokens, self);
	if (empty_tag) {
	    report_event(p_state, E_END, s, s, utf8, tokens, 1, self);
	}
	else if (!p_state->xml_mode) {
	    /* find out if this start tag should put us into literal_mode
	     */
	    int i;
	    int tag_len = tokens[0].end - tokens[0].beg;

	    for (i = 0; literal_mode_elem[i].len; i++) {
		if (tag_len == literal_mode_elem[i].len) {
		    /* try to match it */
		    char *s = beg + 1;
		    char *t = literal_mode_elem[i].str;
		    int len = tag_len;
		    while (len) {
			if (toLOWER(*s) != *t)
			    break;
			s++;
			t++;
			if (!--len) {
			    /* found it */
			    p_state->literal_mode = literal_mode_elem[i].str;
			    p_state->is_cdata = literal_mode_elem[i].is_cdata;
			    /* printf("Found %s\n", p_state->literal_mode); */
			    goto END_OF_LITERAL_SEARCH;
			}
		    }
		}
	    }
	END_OF_LITERAL_SEARCH:
	    ;
	}

	FREE_TOKENS;
	return s;
    }
  
    FREE_TOKENS;
    return 0;

PREMATURE:
    FREE_TOKENS;
    return beg;
}


static char*
parse_end(PSTATE* p_state, char *beg, char *end, U32 utf8, SV* self)
{
    char *s = beg+2;
    hctype_t name_first, name_char;

    if (STRICT_NAMES(p_state)) {
	name_first = HCTYPE_NAME_FIRST;
	name_char  = HCTYPE_NAME_CHAR;
    }
    else {
	name_first = name_char = HCTYPE_NOT_SPACE_GT;
    }

    if (isHCTYPE(*s, name_first)) {
	token_pos_t tagname;
	tagname.beg = s;
	s++;
	while (s < end && isHCTYPE(*s, name_char))
	    s++;
	tagname.end = s;

	if (p_state->strict_end) {
	    while (isHSPACE(*s))
		s++;
	}
	else {
	    s = skip_until_gt(s, end);
	}
	if (s < end) {
	    if (*s == '>') {
		s++;
		/* a complete end tag has been recognized */
		report_event(p_state, E_END, beg, s, utf8, &tagname, 1, self);
		return s;
	    }
	}
	else {
	    return beg;
	}
    }
    else if (!p_state->strict_comment) {
	s = skip_until_gt(s, end);
	if (s < end) {
	    token_pos_t token;
	    token.beg = beg + 2;
	    token.end = s;
	    s++;
	    report_event(p_state, E_COMMENT, beg, s, utf8, &token, 1, self);
	    return s;
	}
	else {
	    return beg;
	}
    }
    return 0;
}


static char*
parse_process(PSTATE* p_state, char *beg, char *end, U32 utf8, SV* self)
{
    char *s = beg + 2;  /* skip '<?' */
    /* processing instruction */
    token_pos_t token_pos;
    token_pos.beg = s;

    while (s < end) {
	if (*s == '>') {
	    token_pos.end = s;
	    s++;

	    if (p_state->xml_mode || p_state->xml_pic) {
		/* XML processing instructions are ended by "?>" */
		if (s - beg < 4 || s[-2] != '?')
		    continue;
		token_pos.end = s - 2;
	    }
      
	    /* a complete processing instruction seen */
	    report_event(p_state, E_PROCESS, beg, s, utf8, 
			 &token_pos, 1, self);
	    return s;
	}
	s++;
    }
    return beg;  /* could not fix end */
}


#ifdef USE_PFUNC
static char*
parse_null(PSTATE* p_state, char *beg, char *end, U32 utf8, SV* self)
{
    return 0;
}



#include "pfunc.h"                   /* declares the parsefunc[] */
#endif /* USE_PFUNC */

static char*
parse_buf(pTHX_ PSTATE* p_state, char *beg, char *end, U32 utf8, SV* self)
{
    char *s = beg;
    char *t = beg;
    char *new_pos;

    while (!p_state->eof) {
	/*
	 * At the start of this loop we will always be ready for eating text
	 * or a new tag.  We will never be inside some tag.  The 't' points
	 * to where we started and the 's' is advanced as we go.
	 */

	while (p_state->literal_mode) {
	    char *l = p_state->literal_mode;
	    bool skip_quoted_end = (strEQ(l, "script") || strEQ(l, "style"));
	    char inside_quote = 0;
	    bool escape_next = 0;
	    char *end_text;

	    while (s < end) {
		if (*s == '<' && !inside_quote)
		    break;
		if (skip_quoted_end) {
		    if (escape_next) {
			escape_next = 0;
		    }
		    else {
			if (*s == '\\')
			    escape_next = 1;
			else if (inside_quote && *s == inside_quote)
			    inside_quote = 0;
			else if (*s == '\r' || *s == '\n')
			    inside_quote = 0;
			else if (!inside_quote && (*s == '"' || *s == '\''))
			    inside_quote = *s;
		    }
		}
		s++;
	    }

	    if (s == end) {
		s = t;
		goto DONE;
	    }

	    end_text = s;
	    s++;
      
	    /* here we rely on '\0' termination of perl svpv buffers */
	    if (*s == '/') {
		s++;
		while (*l && toLOWER(*s) == *l) {
		    s++;
		    l++;
		}

		if (!*l && (strNE(p_state->literal_mode, "plaintext") || p_state->closing_plaintext)) {
		    /* matched it all */
		    token_pos_t end_token;
		    end_token.beg = end_text + 2;
		    end_token.end = s;

		    while (isHSPACE(*s))
			s++;
		    if (*s == '>') {
			s++;
			if (t != end_text)
			    report_event(p_state, E_TEXT, t, end_text, utf8,
					 0, 0, self);
			report_event(p_state, E_END,  end_text, s, utf8,
				     &end_token, 1, self);
			p_state->literal_mode = 0;
			p_state->is_cdata = 0;
			t = s;
		    }
		}
	    }
	}

#ifdef MARKED_SECTION
	while (p_state->ms == MS_CDATA || p_state->ms == MS_RCDATA) {
	    while (s < end && *s != ']')
		s++;
	    if (*s == ']') {
		char *end_text = s;
		s++;
		if (*s == ']' && *(s + 1) == '>') {
		    s += 2;
		    /* marked section end */
		    if (t != end_text)
			report_event(p_state, E_TEXT, t, end_text, utf8,
				     0, 0, self);
		    report_event(p_state, E_NONE, end_text, s, utf8, 0, 0, self);
		    t = s;
		    SvREFCNT_dec(av_pop(p_state->ms_stack));
		    marked_section_update(p_state);
		    continue;
		}
	    }
	    if (s == end) {
		s = t;
		goto DONE;
	    }
	}
#endif

	/* first we try to match as much text as possible */
	while (s < end && *s != '<') {
#ifdef MARKED_SECTION
	    if (p_state->ms && *s == ']') {
		char *end_text = s;
		s++;
		if (*s == ']') {
		    s++;
		    if (*s == '>') {
			s++;
			report_event(p_state, E_TEXT, t, end_text, utf8,
				     0, 0, self);
			report_event(p_state, E_NONE, end_text, s, utf8,
				     0, 0, self);
			t = s;
			SvREFCNT_dec(av_pop(p_state->ms_stack));
			marked_section_update(p_state);    
			continue;
		    }
		}
	    }
#endif
	    s++;
	}
	if (s != t) {
	    if (*s == '<') {
		report_event(p_state, E_TEXT, t, s, utf8, 0, 0, self);
		t = s;
	    }
	    else {
		s--;
		if (isHSPACE(*s)) {
		    /* wait with white space at end */
		    while (s >= t && isHSPACE(*s))
			s--;
		}
		else {
		    /* might be a chopped up entities/words */
		    while (s >= t && !isHSPACE(*s))
			s--;
		    while (s >= t && isHSPACE(*s))
			s--;
		}
		s++;
		if (s != t)
		    report_event(p_state, E_TEXT, t, s, utf8, 0, 0, self);
		break;
	    }
	}

	if (end - s < 3)
	    break;

	/* next char is known to be '<' and pointed to by 't' as well as 's' */
	s++;

#ifdef USE_PFUNC
	new_pos = parsefunc[(unsigned char)*s](p_state, t, end, utf8, self);
#else
	if (isHNAME_FIRST(*s))
	    new_pos = parse_start(p_state, t, end, utf8, self);
	else if (*s == '/')
	    new_pos = parse_end(p_state, t, end, utf8, self);
	else if (*s == '!')
	    new_pos = parse_decl(p_state, t, end, utf8, self);
	else if (*s == '?')
	    new_pos = parse_process(p_state, t, end, utf8, self);
	else
	    new_pos = 0;
#endif /* USE_PFUNC */

	if (new_pos) {
	    if (new_pos == t) {
		/* no progress, need more data to know what it is */
		s = t;
		break;
	    }
	    t = s = new_pos;
	}

	/* if we get out here then this was not a conforming tag, so
	 * treat it is plain text at the top of the loop again (we
	 * have already skipped past the "<").
	 */
    }

DONE:
    return s;

}

EXTERN void
parse(pTHX_
      PSTATE* p_state,
      SV* chunk,
      SV* self)
{
    char *s, *beg, *end;
    U32 utf8 = 0;
    STRLEN len;

    if (!p_state->start_document) {
	char dummy[1];
	report_event(p_state, E_START_DOCUMENT, dummy, dummy, 0, 0, 0, self);
	p_state->start_document = 1;
    }

    if (!chunk) {
	/* eof */
	char empty[1];
	if (p_state->buf && SvOK(p_state->buf)) {
	    /* flush it */
	    s = SvPV(p_state->buf, len);
	    end = s + len;
	    utf8 = SvUTF8(p_state->buf);
	    assert(len);

	    while (s < end) {
		if (p_state->literal_mode) {
		    if (strEQ(p_state->literal_mode, "plaintext") ||
			strEQ(p_state->literal_mode, "xmp") ||
			strEQ(p_state->literal_mode, "textarea"))
		    {
			/* rest is considered text */
			break;
                    }
		    if (strEQ(p_state->literal_mode, "script") ||
			strEQ(p_state->literal_mode, "style"))
		    {
			/* effectively make it an empty element */
			token_pos_t t;
			char dummy;
			t.beg = p_state->literal_mode;
			t.end = p_state->literal_mode + strlen(p_state->literal_mode);
			report_event(p_state, E_END, &dummy, &dummy, 0, &t, 1, self);
		    }
		    else {
			p_state->pending_end_tag = p_state->literal_mode;
		    }
		    p_state->literal_mode = 0;
		    s = parse_buf(aTHX_ p_state, s, end, utf8, self);
		    continue;
		}

		if (!p_state->strict_comment && !p_state->no_dash_dash_comment_end && *s == '<') {
		    p_state->no_dash_dash_comment_end = 1;
		    s = parse_buf(aTHX_ p_state, s, end, utf8, self);
		    continue;
		}

		if (!p_state->strict_comment && *s == '<') {
		    char *s1 = s + 1;
		    if (s1 == end || isHNAME_FIRST(*s1) || *s1 == '/' || *s1 == '!' || *s1 == '?') {
			/* some kind of unterminated markup.  Report rest as as comment */
			token_pos_t token;
			token.beg = s + 1;
			token.end = end;
			report_event(p_state, E_COMMENT, s, end, utf8, &token, 1, self);
			s = end;
		    }
		}

		break;
	    }

	    if (s < end) {
		/* report rest as text */
		report_event(p_state, E_TEXT, s, end, utf8, 0, 0, self);
	    }
	    
	    SvREFCNT_dec(p_state->buf);
	    p_state->buf = 0;
	}
	if (p_state->pend_text && SvOK(p_state->pend_text))
	    flush_pending_text(p_state, self);

	if (p_state->ignoring_element) {
	    /* document not balanced */
	    SvREFCNT_dec(p_state->ignoring_element);
	    p_state->ignoring_element = 0;
	}
	report_event(p_state, E_END_DOCUMENT, empty, empty, 0, 0, 0, self);

	/* reset state */
	p_state->offset = 0;
	if (p_state->line)
	    p_state->line = 1;
	p_state->column = 0;
	p_state->start_document = 0;
	p_state->literal_mode = 0;
	p_state->is_cdata = 0;
	return;
    }

#ifdef UNICODE_HTML_PARSER
    if (p_state->utf8_mode)
	sv_utf8_downgrade(chunk, 0);
#endif

    if (p_state->buf && SvOK(p_state->buf)) {
	sv_catsv(p_state->buf, chunk);
	beg = SvPV(p_state->buf, len);
	utf8 = SvUTF8(p_state->buf);
    }
    else {
	beg = SvPV(chunk, len);
	utf8 = SvUTF8(chunk);
	if (p_state->offset == 0 && DOWARN) {
	    /* Print warnings if we find unexpected Unicode BOM forms */
#ifdef UNICODE_HTML_PARSER
	    if (p_state->argspec_entity_decode &&
		!p_state->utf8_mode && (
                 (!utf8 && len >= 3 && strnEQ(beg, "\xEF\xBB\xBF", 3)) ||
		 (utf8 && len >= 6 && strnEQ(beg, "\xC3\xAF\xC2\xBB\xC2\xBF", 6)) ||
		 (!utf8 && probably_utf8_chunk(aTHX_ beg, len))
		)
	       )
	    {
		warn("Parsing of undecoded UTF-8 will give garbage when decoding entities");
	    }
	    if (utf8 && len >= 2 && strnEQ(beg, "\xFF\xFE", 2)) {
		warn("Parsing string decoded with wrong endianess");
	    }
#endif
	    if (!utf8 && len >= 4 &&
		(strnEQ(beg, "\x00\x00\xFE\xFF", 4) ||
		 strnEQ(beg, "\xFE\xFF\x00\x00", 4))
		)
	    {
		warn("Parsing of undecoded UTF-32");
	    }
	    else if (!utf8 && len >= 2 &&
		     (strnEQ(beg, "\xFE\xFF", 2) || strnEQ(beg, "\xFF\xFE", 2))
		)
	    {
		warn("Parsing of undecoded UTF-16");
	    }
	}
    }

    if (!len)
	return; /* nothing to do */

    end = beg + len;
    s = parse_buf(aTHX_ p_state, beg, end, utf8, self);

    if (s == end || p_state->eof) {
	if (p_state->buf) {
	    SvOK_off(p_state->buf);
	}
    }
    else {
	/* need to keep rest in buffer */
	if (p_state->buf) {
	    /* chop off some chars at the beginning */
	    if (SvOK(p_state->buf)) {
		sv_chop(p_state->buf, s);
	    }
	    else {
		sv_setpvn(p_state->buf, s, end - s);
		if (utf8)
		    SvUTF8_on(p_state->buf);
		else
		    SvUTF8_off(p_state->buf);
	    }
	}
	else {
	    p_state->buf = newSVpv(s, end - s);
	    if (utf8)
		SvUTF8_on(p_state->buf);
	}
    }
    return;
}
