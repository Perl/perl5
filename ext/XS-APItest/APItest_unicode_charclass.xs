MODULE = XS::APItest            PACKAGE = XS::APItest

bool
test_isBLANK_uni(UV ord)
    CODE:
        RETVAL = isBLANK_uni(ord);
    OUTPUT:
        RETVAL

bool
test_isBLANK_uvchr(UV ord)
    CODE:
        RETVAL = isBLANK_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isBLANK_LC_uvchr(UV ord)
    CODE:
        RETVAL = isBLANK_LC_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isBLANK(UV ord)
    CODE:
        RETVAL = isBLANK(ord);
    OUTPUT:
        RETVAL

bool
test_isBLANK_A(UV ord)
    CODE:
        RETVAL = isBLANK_A(ord);
    OUTPUT:
        RETVAL

bool
test_isBLANK_L1(UV ord)
    CODE:
        RETVAL = isBLANK_L1(ord);
    OUTPUT:
        RETVAL

bool
test_isBLANK_LC(UV ord)
    CODE:
        RETVAL = isBLANK_LC(ord);
    OUTPUT:
        RETVAL

bool
test_isBLANK_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:

        /* In this function and those that follow, the boolean 'type'
         * indicates if to pass a malformed UTF-8 string to the tested macro
         * (malformed by making it too short) */
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isBLANK_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isBLANK_LC_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isBLANK_LC_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isVERTWS_uni(UV ord)
    CODE:
        RETVAL = isVERTWS_uni(ord);
    OUTPUT:
        RETVAL

bool
test_isVERTWS_uvchr(UV ord)
    CODE:
        RETVAL = isVERTWS_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isVERTWS_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isVERTWS_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isUPPER_uni(UV ord)
    CODE:
        RETVAL = isUPPER_uni(ord);
    OUTPUT:
        RETVAL

bool
test_isUPPER_uvchr(UV ord)
    CODE:
        RETVAL = isUPPER_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isUPPER_LC_uvchr(UV ord)
    CODE:
        RETVAL = isUPPER_LC_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isUPPER(UV ord)
    CODE:
        RETVAL = isUPPER(ord);
    OUTPUT:
        RETVAL

bool
test_isUPPER_A(UV ord)
    CODE:
        RETVAL = isUPPER_A(ord);
    OUTPUT:
        RETVAL

bool
test_isUPPER_L1(UV ord)
    CODE:
        RETVAL = isUPPER_L1(ord);
    OUTPUT:
        RETVAL

bool
test_isUPPER_LC(UV ord)
    CODE:
        RETVAL = isUPPER_LC(ord);
    OUTPUT:
        RETVAL

bool
test_isUPPER_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isUPPER_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isUPPER_LC_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isUPPER_LC_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isLOWER_uni(UV ord)
    CODE:
        RETVAL = isLOWER_uni(ord);
    OUTPUT:
        RETVAL

bool
test_isLOWER_uvchr(UV ord)
    CODE:
        RETVAL = isLOWER_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isLOWER_LC_uvchr(UV ord)
    CODE:
        RETVAL = isLOWER_LC_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isLOWER(UV ord)
    CODE:
        RETVAL = isLOWER(ord);
    OUTPUT:
        RETVAL

bool
test_isLOWER_A(UV ord)
    CODE:
        RETVAL = isLOWER_A(ord);
    OUTPUT:
        RETVAL

bool
test_isLOWER_L1(UV ord)
    CODE:
        RETVAL = isLOWER_L1(ord);
    OUTPUT:
        RETVAL

bool
test_isLOWER_LC(UV ord)
    CODE:
        RETVAL = isLOWER_LC(ord);
    OUTPUT:
        RETVAL

bool
test_isLOWER_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isLOWER_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isLOWER_LC_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isLOWER_LC_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isALPHA_uni(UV ord)
    CODE:
        RETVAL = isALPHA_uni(ord);
    OUTPUT:
        RETVAL

bool
test_isALPHA_uvchr(UV ord)
    CODE:
        RETVAL = isALPHA_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isALPHA_LC_uvchr(UV ord)
    CODE:
        RETVAL = isALPHA_LC_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isALPHA(UV ord)
    CODE:
        RETVAL = isALPHA(ord);
    OUTPUT:
        RETVAL

bool
test_isALPHA_A(UV ord)
    CODE:
        RETVAL = isALPHA_A(ord);
    OUTPUT:
        RETVAL

bool
test_isALPHA_L1(UV ord)
    CODE:
        RETVAL = isALPHA_L1(ord);
    OUTPUT:
        RETVAL

bool
test_isALPHA_LC(UV ord)
    CODE:
        RETVAL = isALPHA_LC(ord);
    OUTPUT:
        RETVAL

bool
test_isALPHA_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isALPHA_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isALPHA_LC_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isALPHA_LC_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isWORDCHAR_uni(UV ord)
    CODE:
        RETVAL = isWORDCHAR_uni(ord);
    OUTPUT:
        RETVAL

bool
test_isWORDCHAR_uvchr(UV ord)
    CODE:
        RETVAL = isWORDCHAR_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isWORDCHAR_LC_uvchr(UV ord)
    CODE:
        RETVAL = isWORDCHAR_LC_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isWORDCHAR(UV ord)
    CODE:
        RETVAL = isWORDCHAR(ord);
    OUTPUT:
        RETVAL

bool
test_isWORDCHAR_A(UV ord)
    CODE:
        RETVAL = isWORDCHAR_A(ord);
    OUTPUT:
        RETVAL

bool
test_isWORDCHAR_L1(UV ord)
    CODE:
        RETVAL = isWORDCHAR_L1(ord);
    OUTPUT:
        RETVAL

bool
test_isWORDCHAR_LC(UV ord)
    CODE:
        RETVAL = isWORDCHAR_LC(ord);
    OUTPUT:
        RETVAL

bool
test_isWORDCHAR_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isWORDCHAR_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isWORDCHAR_LC_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isWORDCHAR_LC_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isALPHANUMERIC_uni(UV ord)
    CODE:
        RETVAL = isALPHANUMERIC_uni(ord);
    OUTPUT:
        RETVAL

bool
test_isALPHANUMERIC_uvchr(UV ord)
    CODE:
        RETVAL = isALPHANUMERIC_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isALPHANUMERIC_LC_uvchr(UV ord)
    CODE:
        RETVAL = isALPHANUMERIC_LC_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isALPHANUMERIC(UV ord)
    CODE:
        RETVAL = isALPHANUMERIC(ord);
    OUTPUT:
        RETVAL

bool
test_isALPHANUMERIC_A(UV ord)
    CODE:
        RETVAL = isALPHANUMERIC_A(ord);
    OUTPUT:
        RETVAL

bool
test_isALPHANUMERIC_L1(UV ord)
    CODE:
        RETVAL = isALPHANUMERIC_L1(ord);
    OUTPUT:
        RETVAL

bool
test_isALPHANUMERIC_LC(UV ord)
    CODE:
        RETVAL = isALPHANUMERIC_LC(ord);
    OUTPUT:
        RETVAL

bool
test_isALPHANUMERIC_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isALPHANUMERIC_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isALPHANUMERIC_LC_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isALPHANUMERIC_LC_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isALNUM(UV ord)
    CODE:
        RETVAL = isALNUM(ord);
    OUTPUT:
        RETVAL

bool
test_isALNUM_uni(UV ord)
    CODE:
        RETVAL = isALNUM_uni(ord);
    OUTPUT:
        RETVAL

bool
test_isALNUM_LC_uvchr(UV ord)
    CODE:
        RETVAL = isALNUM_LC_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isALNUM_LC(UV ord)
    CODE:
        RETVAL = isALNUM_LC(ord);
    OUTPUT:
        RETVAL

bool
test_isALNUM_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isWORDCHAR_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isALNUM_LC_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isWORDCHAR_LC_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isDIGIT_uni(UV ord)
    CODE:
        RETVAL = isDIGIT_uni(ord);
    OUTPUT:
        RETVAL

bool
test_isDIGIT_uvchr(UV ord)
    CODE:
        RETVAL = isDIGIT_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isDIGIT_LC_uvchr(UV ord)
    CODE:
        RETVAL = isDIGIT_LC_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isDIGIT_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isDIGIT_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isDIGIT_LC_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isDIGIT_LC_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isDIGIT(UV ord)
    CODE:
        RETVAL = isDIGIT(ord);
    OUTPUT:
        RETVAL

bool
test_isDIGIT_A(UV ord)
    CODE:
        RETVAL = isDIGIT_A(ord);
    OUTPUT:
        RETVAL

bool
test_isDIGIT_L1(UV ord)
    CODE:
        RETVAL = isDIGIT_L1(ord);
    OUTPUT:
        RETVAL

bool
test_isDIGIT_LC(UV ord)
    CODE:
        RETVAL = isDIGIT_LC(ord);
    OUTPUT:
        RETVAL

bool
test_isOCTAL(UV ord)
    CODE:
        RETVAL = isOCTAL(ord);
    OUTPUT:
        RETVAL

bool
test_isOCTAL_A(UV ord)
    CODE:
        RETVAL = isOCTAL_A(ord);
    OUTPUT:
        RETVAL

bool
test_isOCTAL_L1(UV ord)
    CODE:
        RETVAL = isOCTAL_L1(ord);
    OUTPUT:
        RETVAL

bool
test_isIDFIRST_uni(UV ord)
    CODE:
        RETVAL = isIDFIRST_uni(ord);
    OUTPUT:
        RETVAL

bool
test_isIDFIRST_uvchr(UV ord)
    CODE:
        RETVAL = isIDFIRST_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isIDFIRST_LC_uvchr(UV ord)
    CODE:
        RETVAL = isIDFIRST_LC_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isIDFIRST(UV ord)
    CODE:
        RETVAL = isIDFIRST(ord);
    OUTPUT:
        RETVAL

bool
test_isIDFIRST_A(UV ord)
    CODE:
        RETVAL = isIDFIRST_A(ord);
    OUTPUT:
        RETVAL

bool
test_isIDFIRST_L1(UV ord)
    CODE:
        RETVAL = isIDFIRST_L1(ord);
    OUTPUT:
        RETVAL

bool
test_isIDFIRST_LC(UV ord)
    CODE:
        RETVAL = isIDFIRST_LC(ord);
    OUTPUT:
        RETVAL

bool
test_isIDFIRST_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isIDFIRST_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isIDFIRST_LC_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isIDFIRST_LC_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isIDCONT_uni(UV ord)
    CODE:
        RETVAL = isIDCONT_uni(ord);
    OUTPUT:
        RETVAL

bool
test_isIDCONT_uvchr(UV ord)
    CODE:
        RETVAL = isIDCONT_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isIDCONT_LC_uvchr(UV ord)
    CODE:
        RETVAL = isIDCONT_LC_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isIDCONT(UV ord)
    CODE:
        RETVAL = isIDCONT(ord);
    OUTPUT:
        RETVAL

bool
test_isIDCONT_A(UV ord)
    CODE:
        RETVAL = isIDCONT_A(ord);
    OUTPUT:
        RETVAL

bool
test_isIDCONT_L1(UV ord)
    CODE:
        RETVAL = isIDCONT_L1(ord);
    OUTPUT:
        RETVAL

bool
test_isIDCONT_LC(UV ord)
    CODE:
        RETVAL = isIDCONT_LC(ord);
    OUTPUT:
        RETVAL

bool
test_isIDCONT_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isIDCONT_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isIDCONT_LC_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isIDCONT_LC_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isSPACE_uni(UV ord)
    CODE:
        RETVAL = isSPACE_uni(ord);
    OUTPUT:
        RETVAL

bool
test_isSPACE_uvchr(UV ord)
    CODE:
        RETVAL = isSPACE_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isSPACE_LC_uvchr(UV ord)
    CODE:
        RETVAL = isSPACE_LC_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isSPACE(UV ord)
    CODE:
        RETVAL = isSPACE(ord);
    OUTPUT:
        RETVAL

bool
test_isSPACE_A(UV ord)
    CODE:
        RETVAL = isSPACE_A(ord);
    OUTPUT:
        RETVAL

bool
test_isSPACE_L1(UV ord)
    CODE:
        RETVAL = isSPACE_L1(ord);
    OUTPUT:
        RETVAL

bool
test_isSPACE_LC(UV ord)
    CODE:
        RETVAL = isSPACE_LC(ord);
    OUTPUT:
        RETVAL

bool
test_isSPACE_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isSPACE_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isSPACE_LC_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isSPACE_LC_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isASCII_uni(UV ord)
    CODE:
        RETVAL = isASCII_uni(ord);
    OUTPUT:
        RETVAL

bool
test_isASCII_uvchr(UV ord)
    CODE:
        RETVAL = isASCII_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isASCII_LC_uvchr(UV ord)
    CODE:
        RETVAL = isASCII_LC_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isASCII(UV ord)
    CODE:
        RETVAL = isASCII(ord);
    OUTPUT:
        RETVAL

bool
test_isASCII_A(UV ord)
    CODE:
        RETVAL = isASCII_A(ord);
    OUTPUT:
        RETVAL

bool
test_isASCII_L1(UV ord)
    CODE:
        RETVAL = isASCII_L1(ord);
    OUTPUT:
        RETVAL

bool
test_isASCII_LC(UV ord)
    CODE:
        RETVAL = isASCII_LC(ord);
    OUTPUT:
        RETVAL

bool
test_isASCII_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
#ifndef DEBUGGING
        PERL_UNUSED_VAR(e);
#endif
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isASCII_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isASCII_LC_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
#ifndef DEBUGGING
        PERL_UNUSED_VAR(e);
#endif
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isASCII_LC_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isCNTRL_uni(UV ord)
    CODE:
        RETVAL = isCNTRL_uni(ord);
    OUTPUT:
        RETVAL

bool
test_isCNTRL_uvchr(UV ord)
    CODE:
        RETVAL = isCNTRL_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isCNTRL_LC_uvchr(UV ord)
    CODE:
        RETVAL = isCNTRL_LC_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isCNTRL(UV ord)
    CODE:
        RETVAL = isCNTRL(ord);
    OUTPUT:
        RETVAL

bool
test_isCNTRL_A(UV ord)
    CODE:
        RETVAL = isCNTRL_A(ord);
    OUTPUT:
        RETVAL

bool
test_isCNTRL_L1(UV ord)
    CODE:
        RETVAL = isCNTRL_L1(ord);
    OUTPUT:
        RETVAL

bool
test_isCNTRL_LC(UV ord)
    CODE:
        RETVAL = isCNTRL_LC(ord);
    OUTPUT:
        RETVAL

bool
test_isCNTRL_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isCNTRL_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isCNTRL_LC_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isCNTRL_LC_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isPRINT_uni(UV ord)
    CODE:
        RETVAL = isPRINT_uni(ord);
    OUTPUT:
        RETVAL

bool
test_isPRINT_uvchr(UV ord)
    CODE:
        RETVAL = isPRINT_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isPRINT_LC_uvchr(UV ord)
    CODE:
        RETVAL = isPRINT_LC_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isPRINT(UV ord)
    CODE:
        RETVAL = isPRINT(ord);
    OUTPUT:
        RETVAL

bool
test_isPRINT_A(UV ord)
    CODE:
        RETVAL = isPRINT_A(ord);
    OUTPUT:
        RETVAL

bool
test_isPRINT_L1(UV ord)
    CODE:
        RETVAL = isPRINT_L1(ord);
    OUTPUT:
        RETVAL

bool
test_isPRINT_LC(UV ord)
    CODE:
        RETVAL = isPRINT_LC(ord);
    OUTPUT:
        RETVAL

bool
test_isPRINT_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isPRINT_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isPRINT_LC_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isPRINT_LC_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isGRAPH_uni(UV ord)
    CODE:
        RETVAL = isGRAPH_uni(ord);
    OUTPUT:
        RETVAL

bool
test_isGRAPH_uvchr(UV ord)
    CODE:
        RETVAL = isGRAPH_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isGRAPH_LC_uvchr(UV ord)
    CODE:
        RETVAL = isGRAPH_LC_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isGRAPH(UV ord)
    CODE:
        RETVAL = isGRAPH(ord);
    OUTPUT:
        RETVAL

bool
test_isGRAPH_A(UV ord)
    CODE:
        RETVAL = isGRAPH_A(ord);
    OUTPUT:
        RETVAL

bool
test_isGRAPH_L1(UV ord)
    CODE:
        RETVAL = isGRAPH_L1(ord);
    OUTPUT:
        RETVAL

bool
test_isGRAPH_LC(UV ord)
    CODE:
        RETVAL = isGRAPH_LC(ord);
    OUTPUT:
        RETVAL

bool
test_isGRAPH_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isGRAPH_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isGRAPH_LC_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isGRAPH_LC_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isPUNCT_uni(UV ord)
    CODE:
        RETVAL = isPUNCT_uni(ord);
    OUTPUT:
        RETVAL

bool
test_isPUNCT_uvchr(UV ord)
    CODE:
        RETVAL = isPUNCT_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isPUNCT_LC_uvchr(UV ord)
    CODE:
        RETVAL = isPUNCT_LC_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isPUNCT(UV ord)
    CODE:
        RETVAL = isPUNCT(ord);
    OUTPUT:
        RETVAL

bool
test_isPUNCT_A(UV ord)
    CODE:
        RETVAL = isPUNCT_A(ord);
    OUTPUT:
        RETVAL

bool
test_isPUNCT_L1(UV ord)
    CODE:
        RETVAL = isPUNCT_L1(ord);
    OUTPUT:
        RETVAL

bool
test_isPUNCT_LC(UV ord)
    CODE:
        RETVAL = isPUNCT_LC(ord);
    OUTPUT:
        RETVAL

bool
test_isPUNCT_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isPUNCT_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isPUNCT_LC_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isPUNCT_LC_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isXDIGIT_uni(UV ord)
    CODE:
        RETVAL = isXDIGIT_uni(ord);
    OUTPUT:
        RETVAL

bool
test_isXDIGIT_uvchr(UV ord)
    CODE:
        RETVAL = isXDIGIT_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isXDIGIT_LC_uvchr(UV ord)
    CODE:
        RETVAL = isXDIGIT_LC_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isXDIGIT(UV ord)
    CODE:
        RETVAL = isXDIGIT(ord);
    OUTPUT:
        RETVAL

bool
test_isXDIGIT_A(UV ord)
    CODE:
        RETVAL = isXDIGIT_A(ord);
    OUTPUT:
        RETVAL

bool
test_isXDIGIT_L1(UV ord)
    CODE:
        RETVAL = isXDIGIT_L1(ord);
    OUTPUT:
        RETVAL

bool
test_isXDIGIT_LC(UV ord)
    CODE:
        RETVAL = isXDIGIT_LC(ord);
    OUTPUT:
        RETVAL

bool
test_isXDIGIT_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isXDIGIT_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isXDIGIT_LC_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isXDIGIT_LC_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isPSXSPC_uni(UV ord)
    CODE:
        RETVAL = isPSXSPC_uni(ord);
    OUTPUT:
        RETVAL

bool
test_isPSXSPC_uvchr(UV ord)
    CODE:
        RETVAL = isPSXSPC_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isPSXSPC_LC_uvchr(UV ord)
    CODE:
        RETVAL = isPSXSPC_LC_uvchr(ord);
    OUTPUT:
        RETVAL

bool
test_isPSXSPC(UV ord)
    CODE:
        RETVAL = isPSXSPC(ord);
    OUTPUT:
        RETVAL

bool
test_isPSXSPC_A(UV ord)
    CODE:
        RETVAL = isPSXSPC_A(ord);
    OUTPUT:
        RETVAL

bool
test_isPSXSPC_L1(UV ord)
    CODE:
        RETVAL = isPSXSPC_L1(ord);
    OUTPUT:
        RETVAL

bool
test_isPSXSPC_LC(UV ord)
    CODE:
        RETVAL = isPSXSPC_LC(ord);
    OUTPUT:
        RETVAL

bool
test_isPSXSPC_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isPSXSPC_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

bool
test_isPSXSPC_LC_utf8(U8 * p, int type)
    PREINIT:
        const U8 * e;
    CODE:
        if (type >= 0) {
            e = p + UTF8SKIP(p) - type;
            RETVAL = isPSXSPC_LC_utf8_safe(p, e);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL
