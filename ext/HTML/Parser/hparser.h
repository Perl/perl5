/* $Id: hparser.h,v 2.34 2006/04/26 07:01:10 gisle Exp $
 *
 * Copyright 1999-2005, Gisle Aas
 * Copyright 1999-2000, Michael A. Chase
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 */

/*
 * Declare various structures and constants.  The main thing
 * is 'struct p_state' that contains various fields to represent
 * the state of the parser.
 */

#ifdef MARKED_SECTION

enum marked_section_t {
    MS_NONE = 0,
    MS_INCLUDE,
    MS_RCDATA,
    MS_CDATA,
    MS_IGNORE
};

#endif /* MARKED_SECTION */


#define P_SIGNATURE 0x16091964  /* tag struct p_state for safer cast */

enum event_id {
    E_DECLARATION = 0,
    E_COMMENT,
    E_START,
    E_END,
    E_TEXT,
    E_PROCESS,
    E_START_DOCUMENT,
    E_END_DOCUMENT,
    E_DEFAULT,
    /**/
    EVENT_COUNT,
    E_NONE   /* used for reporting skipped text (non-events) */
};
typedef enum event_id event_id_t;

/* must match event_id_t above */
static char* event_id_str[] = {
    "declaration",
    "comment",
    "start",
    "end",
    "text",
    "process",
    "start_document",
    "end_document",
    "default",
};

struct p_handler {
    SV* cb;
    SV* argspec;
};

struct p_state {
    U32 signature;

    /* state */
    SV* buf;
    STRLEN offset;
    STRLEN line;
    STRLEN column;
    bool start_document;
    bool parsing;
    bool eof;

    /* special parsing modes */
    char* literal_mode;
    bool  is_cdata;
    bool  no_dash_dash_comment_end;
    char *pending_end_tag;

    /* unbroken_text option needs a buffer of pending text */
    SV*    pend_text;
    bool   pend_text_is_cdata;
    STRLEN pend_text_offset;
    STRLEN pend_text_line;
    STRLEN pend_text_column;

    /* skipped text is accumulated here */
    SV* skipped_text;

#ifdef MARKED_SECTION
    /* marked section support */
    enum marked_section_t ms;
    AV* ms_stack;
    bool marked_sections;
#endif

    /* various boolean configuration attributes */
    bool strict_comment;
    bool strict_names;
    bool strict_end;
    bool xml_mode;
    bool unbroken_text;
    bool attr_encoded;
    bool case_sensitive;
    bool closing_plaintext;
    bool utf8_mode;
    bool empty_element_tags;
    bool xml_pic;

    /* other configuration stuff */
    SV* bool_attr_val;
    struct p_handler handlers[EVENT_COUNT];
    bool argspec_entity_decode;

    /* filters */
    HV* report_tags;
    HV* ignore_tags;
    HV* ignore_elements;

    /* these are set when we are currently inside an element we want to ignore */
    SV* ignoring_element;
    int ignore_depth;

    /* cache */
    HV* entity2char;            /* %HTML::Entities::entity2char */
    SV* tmp;
};
typedef struct p_state PSTATE;

