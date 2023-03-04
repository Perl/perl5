case 1:
    switch ((U8)name[0]) {
    case 1:
        /* $^A */
        /* FALLTHROUGH */;
    case 3:
        /* $^C */
        /* FALLTHROUGH */;
    case 4:
        /* $^D */
        /* FALLTHROUGH */;
    case 5:
        /* $^E */
        /* FALLTHROUGH */;
    case 6:
        /* $^F */
        /* FALLTHROUGH */;
    case 8:
        /* $^H */
        /* FALLTHROUGH */;
    case 9:
        /* $^I */
        /* FALLTHROUGH */;
    case 12:
        /* $^L */
        /* FALLTHROUGH */;
    case 13:
        /* $^M */
        /* FALLTHROUGH */;
    case 14:
        /* $^N */
        /* FALLTHROUGH */;
    case 15:
        /* $^O */
        /* FALLTHROUGH */;
    case 16:
        /* $^P */
        /* FALLTHROUGH */;
    case 18:
        /* $^R */
        /* FALLTHROUGH */;
    case 19:
        /* $^S */
        /* FALLTHROUGH */;
    case 20:
        /* $^T */
        /* FALLTHROUGH */;
    case 22:
        /* $^V */
        /* FALLTHROUGH */;
    case 23:
        /* $^W */
        /* FALLTHROUGH */;
    case 24:
        /* $^X */
        return name;
    }
    break;
case 2:
    switch ((U8)name[0]) {
    case 14:
        /* ${^NR} -> $.  (ALL) */
        if (memEQs(name,*lenp,"\016R")) {
            tmp_buf[0] = '.';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 18:
        /* ${^RS} -> $/  (ALL) */
        if (memEQs(name,*lenp,"\022S")) {
            tmp_buf[0] = '/';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    }
    break;
case 3:
    switch ((U8)name[0]) {
    case 1:
        /* ${^ARG} -> $_  (ALL) */
        if (memEQs(name,*lenp,"\001RG")) {
            tmp_buf[0] = '_';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 7:
        /* ${^GID} -> $(  (ALL) */
        if (memEQs(name,*lenp,"\007ID")) {
            tmp_buf[0] = '(';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 15:
        /* ${^OFS} -> $,  (ALL) */
        if (memEQs(name,*lenp,"\017FS")) {
            tmp_buf[0] = ',';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        /* ${^ORS} -> $\  (ALL) */
        if (memEQs(name,*lenp,"\017RS")) {
            tmp_buf[0] = '\\';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 16:
        /* ${^PID} -> $$  (ALL) */
        if (memEQs(name,*lenp,"\020ID")) {
            tmp_buf[0] = '$';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 21:
        /* ${^UID} -> $<  (ALL) */
        if (memEQs(name,*lenp,"\025ID")) {
            tmp_buf[0] = '<';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    }
    break;
case 4:
    switch ((U8)name[0]) {
    case 5:
        /* ${^EGID} -> $)  (ALL) */
        if (memEQs(name,*lenp,"\005GID")) {
            tmp_buf[0] = ')';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        /* ${^EUID} -> $>  (ALL) */
        if (memEQs(name,*lenp,"\005UID")) {
            tmp_buf[0] = '>';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 15:
        /* ${^OPEN} */
        if (memEQs(name,*lenp,"\017PEN"))
            return name;
        break;
    }
    break;
case 5:
    switch ((U8)name[0]) {
    case 5:
        /* ${^ERRNO} -> $!  (ALL) */
        if (memEQs(name,*lenp,"\005RRNO")) {
            tmp_buf[0] = '!';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 13:
        /* ${^MATCH} -> $&  (ALL) */
        if (memEQs(name,*lenp,"\015ATCH")) {
            tmp_buf[0] = '&';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 20:
        /* ${^TAINT} */
        if (memEQs(name,*lenp,"\024AINT"))
            return name;
        break;
    }
    break;
case 6:
    switch ((U8)name[0]) {
    case 15:
        /* ${^OSNAME} -> $^O  (ALL) */
        if (memEQs(name,*lenp,"\017SNAME")) {
            tmp_buf[0] = '\017';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 16:
        /* ${^PERLDB} -> $^P  (ALL) */
        if (memEQs(name,*lenp,"\020ERLDB")) {
            tmp_buf[0] = '\020';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 19:
        /* ${^SUBSEP} -> $;  (ALL) */
        if (memEQs(name,*lenp,"\023UBSEP")) {
            tmp_buf[0] = ';';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    }
    break;
case 7:
    switch ((U8)name[0]) {
    case 3:
        /* ${^CAPTURE} */
        if (memEQs(name,*lenp,"\003APTURE"))
            return name;
        break;
    case 12:
        /* ${^LAST_FH} */
        if (memEQs(name,*lenp,"\014AST_FH"))
            return name;
        break;
    case 21:
        /* ${^UNICODE} */
        if (memEQs(name,*lenp,"\025NICODE"))
            return name;
        break;
    case 23:
        /* ${^WARNING} -> $^W  (ALL) */
        if (memEQs(name,*lenp,"\027ARNING")) {
            tmp_buf[0] = '\027';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    }
    break;
case 8:
    switch ((U8)name[0]) {
    case 2:
        /* ${^BASETIME} -> $^T  (ALL) */
        if (memEQs(name,*lenp,"\002ASETIME")) {
            tmp_buf[0] = '\024';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 5:
        /* ${^ENCODING} */
        if (memEQs(name,*lenp,"\005NCODING"))
            return name;
        break;
    case 15:
        /* ${^OS_ERROR} -> $!  (ALL) */
        if (memEQs(name,*lenp,"\017S_ERROR")) {
            tmp_buf[0] = '!';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 16:
        /* ${^PREMATCH} -> $`  (ALL) */
        if (memEQs(name,*lenp,"\020REMATCH")) {
            tmp_buf[0] = '`';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    }
    break;
case 9:
    switch ((U8)name[0]) {
    case 3:
        /* ${^COMPILING} -> $^C  (ALL) */
        if (memEQs(name,*lenp,"\003OMPILING")) {
            tmp_buf[0] = '\003';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 4:
        /* ${^DEBUGGING} -> $^D  (ALL) */
        if (memEQs(name,*lenp,"\004EBUGGING")) {
            tmp_buf[0] = '\004';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 16:
        /* ${^POSTMATCH} -> $'  (ALL) */
        if (memEQs(name,*lenp,"\020OSTMATCH")) {
            tmp_buf[0] = '\'';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 21:
        /* ${^UTF8CACHE} */
        if (memEQs(name,*lenp,"\025TF8CACHE"))
            return name;
        break;
    }
    break;
case 10:
    switch ((U8)name[0]) {
    case 5:
        /* ${^EVAL_ERROR} -> $@  (ALL) */
        if (memEQs(name,*lenp,"\005VAL_ERROR")) {
            tmp_buf[0] = '@';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 16:
        /* ${^PROCESS_ID} -> $$  (ALL) */
        if (memEQs(name,*lenp,"\020ROCESS_ID")) {
            tmp_buf[0] = '$';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 21:
        /* ${^UTF8LOCALE} */
        if (memEQs(name,*lenp,"\025TF8LOCALE"))
            return name;
        break;
    }
    break;
case 11:
    switch ((U8)name[0]) {
    case 1:
        /* ${^ACCUMULATOR} -> $^A  (ALL) */
        if (memEQs(name,*lenp,"\001CCUMULATOR")) {
            tmp_buf[0] = '\001';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 3:
        /* ${^CAPTURE_ALL} */
        if (memEQs(name,*lenp,"\003APTURE_ALL"))
            return name;
        /* ${^CHILD_ERROR} -> $?  (ALL) */
        if (memEQs(name,*lenp,"\003HILD_ERROR")) {
            tmp_buf[0] = '?';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 6:
        /* ${^FORMAT_NAME} -> $~  (ALL) */
        if (memEQs(name,*lenp,"\006ORMAT_NAME")) {
            tmp_buf[0] = '~';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    }
    break;
case 12:
    switch ((U8)name[0]) {
    case 7:
        /* ${^GLOBAL_PHASE} */
        if (memEQs(name,*lenp,"\007LOBAL_PHASE"))
            return name;
        break;
    case 9:
        /* ${^INPLACE_EDIT} -> $^I  (ALL) */
        if (memEQs(name,*lenp,"\011NPLACE_EDIT")) {
            tmp_buf[0] = '\011';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 16:
        /* ${^PERL_VERSION} -> $^V  (ALL) */
        if (memEQs(name,*lenp,"\020ERL_VERSION")) {
            tmp_buf[0] = '\026';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        /* ${^PROGRAM_NAME} -> $0  (ALL) */
        if (memEQs(name,*lenp,"\020ROGRAM_NAME")) {
            tmp_buf[0] = '0';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 18:
        /* ${^REAL_USER_ID} -> $<  (ALL) */
        if (memEQs(name,*lenp,"\022EAL_USER_ID")) {
            tmp_buf[0] = '<';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 19:
        /* ${^SAFE_LOCALES} */
        if (memEQs(name,*lenp,"\023AFE_LOCALES"))
            return name;
        break;
    case 23:
        /* ${^WARNING_BITS} */
        if (memEQs(name,*lenp,"\027ARNING_BITS"))
            return name;
        break;
    }
    break;
case 13:
    switch ((U8)name[0]) {
    case 18:
        /* ${^REAL_GROUP_ID} -> $(  (ALL) */
        if (memEQs(name,*lenp,"\022EAL_GROUP_ID")) {
            tmp_buf[0] = '(';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 19:
        /* ${^SYSTEM_FD_MAX} -> $^F  (ALL) */
        if (memEQs(name,*lenp,"\023YSTEM_FD_MAX")) {
            tmp_buf[0] = '\006';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    }
    break;
case 14:
    switch ((U8)name[0]) {
    case 12:
        /* ${^LAST_MATCH_END} -> $+  (ARRAY) */
        if (memEQs(name,*lenp,"\014AST_MATCH_END")) {
            tmp_buf[0] = '+';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        /* ${^LIST_SEPARATOR} -> $"  (ALL) */
        if (memEQs(name,*lenp,"\014IST_SEPARATOR")) {
            tmp_buf[0] = '"';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 18:
        /* ${^RE_DEBUG_FLAGS} */
        if (memEQs(name,*lenp,"\022E_DEBUG_FLAGS"))
            return name;
        /* ${^RE_TRIE_MAXBUF} */
        if (memEQs(name,*lenp,"\022E_TRIE_MAXBUF"))
            return name;
        break;
    }
    break;
case 15:
    switch ((U8)name[0]) {
    case 5:
        /* ${^EXECUTABLE_NAME} -> $^X  (ALL) */
        if (memEQs(name,*lenp,"\005XECUTABLE_NAME")) {
            tmp_buf[0] = '\030';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 6:
        /* ${^FORMAT_FORMFEED} -> $^L  (ALL) */
        if (memEQs(name,*lenp,"\006ORMAT_FORMFEED")) {
            tmp_buf[0] = '\014';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        /* ${^FORMAT_TOP_NAME} -> $^  (ALL) */
        if (memEQs(name,*lenp,"\006ORMAT_TOP_NAME")) {
            tmp_buf[0] = '^';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    }
    break;
case 16:
    switch ((U8)name[0]) {
    case 12:
        /* ${^LAST_MATCH_START} -> $-  (ARRAY) */
        if (memEQs(name,*lenp,"\014AST_MATCH_START")) {
            tmp_buf[0] = '-';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        /* ${^LAST_PAREN_MATCH} -> $+  (ALL) */
        if (memEQs(name,*lenp,"\014AST_PAREN_MATCH")) {
            tmp_buf[0] = '+';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 15:
        /* ${^OLD_PERL_VERSION} -> $]  (ALL) */
        if (memEQs(name,*lenp,"\017LD_PERL_VERSION")) {
            tmp_buf[0] = ']';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        /* ${^OUTPUT_AUTOFLUSH} -> $|  (ALL) */
        if (memEQs(name,*lenp,"\017UTPUT_AUTOFLUSH")) {
            tmp_buf[0] = '|';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    }
    break;
case 17:
    switch ((U8)name[0]) {
    case 5:
        /* ${^EFFECTIVE_USER_ID} -> $>  (ALL) */
        if (memEQs(name,*lenp,"\005FFECTIVE_USER_ID")) {
            tmp_buf[0] = '>';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        /* ${^EXTENDED_OS_ERROR} -> $^E  (ALL) */
        if (memEQs(name,*lenp,"\005XTENDED_OS_ERROR")) {
            tmp_buf[0] = '\005';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 6:
        /* ${^FORMAT_LINES_LEFT} -> $-  (SCALAR) */
        if (memEQs(name,*lenp,"\006ORMAT_LINES_LEFT")) {
            tmp_buf[0] = '-';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 9:
        /* ${^INPUT_LINE_NUMBER} -> $.  (ALL) */
        if (memEQs(name,*lenp,"\011NPUT_LINE_NUMBER")) {
            tmp_buf[0] = '.';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 23:
        /* ${^WIN32_SLOPPY_STAT} */
        if (memEQs(name,*lenp,"\027IN32_SLOPPY_STAT"))
            return name;
        break;
    }
    break;
case 18:
    switch ((U8)name[0]) {
    case 3:
        /* ${^CHILD_ERROR_NATIVE} */
        if (memEQs(name,*lenp,"\003HILD_ERROR_NATIVE"))
            return name;
        break;
    case 5:
        /* ${^EFFECTIVE_GROUP_ID} -> $)  (ALL) */
        if (memEQs(name,*lenp,"\005FFECTIVE_GROUP_ID")) {
            tmp_buf[0] = ')';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 6:
        /* ${^FORMAT_PAGE_NUMBER} -> $%  (ALL) */
        if (memEQs(name,*lenp,"\006ORMAT_PAGE_NUMBER")) {
            tmp_buf[0] = '%';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    }
    break;
case 19:
    switch ((U8)name[0]) {
    case 19:
        /* ${^SUBSCRIPT_SEPARATOR} -> $;  (ALL) */
        if (memEQs(name,*lenp,"\023UBSCRIPT_SEPARATOR")) {
            tmp_buf[0] = ';';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    }
    break;
case 20:
    switch ((U8)name[0]) {
    case 12:
        /* ${^LAST_SUBMATCH_RESULT} -> $^N  (ALL) */
        if (memEQs(name,*lenp,"\014AST_SUBMATCH_RESULT")) {
            tmp_buf[0] = '\016';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 13:
        /* ${^MAX_EVAL_BEGIN_DEPTH} */
        if (memEQs(name,*lenp,"\015AX_EVAL_BEGIN_DEPTH"))
            return name;
        break;
    }
    break;
case 21:
    switch ((U8)name[0]) {
    case 6:
        /* ${^FORMAT_LINES_PER_PAGE} -> $=  (ALL) */
        if (memEQs(name,*lenp,"\006ORMAT_LINES_PER_PAGE")) {
            tmp_buf[0] = '=';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    }
    break;
case 22:
    switch ((U8)name[0]) {
    case 9:
        /* ${^INPUT_RECORD_SEPARATOR} -> $/  (ALL) */
        if (memEQs(name,*lenp,"\011NPUT_RECORD_SEPARATOR")) {
            tmp_buf[0] = '/';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 15:
        /* ${^OUTPUT_FIELD_SEPARATOR} -> $,  (ALL) */
        if (memEQs(name,*lenp,"\017UTPUT_FIELD_SEPARATOR")) {
            tmp_buf[0] = ',';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    }
    break;
case 23:
    switch ((U8)name[0]) {
    case 5:
        /* ${^EXCEPTIONS_BEING_CAUGHT} -> $^S  (ALL) */
        if (memEQs(name,*lenp,"\005XCEPTIONS_BEING_CAUGHT")) {
            tmp_buf[0] = '\023';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 12:
        /* ${^LAST_REGEXP_CODE_RESULT} -> $^R  (ALL) */
        if (memEQs(name,*lenp,"\014AST_REGEXP_CODE_RESULT")) {
            tmp_buf[0] = '\022';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 15:
        /* ${^OUTPUT_RECORD_SEPARATOR} -> $\  (ALL) */
        if (memEQs(name,*lenp,"\017UTPUT_RECORD_SEPARATOR")) {
            tmp_buf[0] = '\\';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    }
    break;
case 26:
    switch ((U8)name[0]) {
    case 18:
        /* ${^RE_COMPILE_RECURSION_LIMIT} */
        if (memEQs(name,*lenp,"\022E_COMPILE_RECURSION_LIMIT"))
            return name;
        break;
    }
    break;
case 28:
    switch ((U8)name[0]) {
    case 6:
        /* ${^FORMAT_LINE_BREAK_CHARACTERS} -> $:  (ALL) */
        if (memEQs(name,*lenp,"\006ORMAT_LINE_BREAK_CHARACTERS")) {
            tmp_buf[0] = ':';
            tmp_buf[1] = 0;
            *lenp = 1;
            return tmp_buf;
        }
        break;
    case 13:
        /* ${^MAX_NESTED_EVAL_BEGIN_BLOCKS} */
        if (memEQs(name,*lenp,"\015AX_NESTED_EVAL_BEGIN_BLOCKS"))
            return name;
        break;
    }
    break;
