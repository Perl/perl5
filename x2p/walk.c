/* $Header: walk.c,v 1.0.1.1 88/01/28 11:07:56 root Exp $
 *
 * $Log:	walk.c,v $
 * Revision 1.0.1.1  88/01/28  11:07:56  root
 * patch8: changed some misleading comments.
 * 
 * Revision 1.0  87/12/18  13:07:40  root
 * Initial revision
 * 
 */

#include "handy.h"
#include "EXTERN.h"
#include "util.h"
#include "a2p.h"

bool exitval = FALSE;
bool realexit = FALSE;
int maxtmp = 0;

STR *
walk(useval,level,node,numericptr)
int useval;
int level;
register int node;
int *numericptr;
{
    register int len;
    register STR *str;
    register int type;
    register int i;
    register STR *tmpstr;
    STR *tmp2str;
    char *t;
    char *d, *s;
    int numarg;
    int numeric = FALSE;
    STR *fstr;
    char *index();

    if (!node) {
	*numericptr = 0;
	return str_make("");
    }
    type = ops[node].ival;
    len = type >> 8;
    type &= 255;
    switch (type) {
    case OPROG:
	str = walk(0,level,ops[node+1].ival,&numarg);
	opens = str_new(0);
	if (do_split && need_entire && !absmaxfld)
	    split_to_array = TRUE;
	if (do_split && split_to_array)
	    set_array_base = TRUE;
	if (set_array_base) {
	    str_cat(str,"$[ = 1;\t\t\t# set array base to 1\n");
	}
	if (fswitch && !const_FS)
	    const_FS = fswitch;
	if (saw_FS > 1 || saw_RS)
	    const_FS = 0;
	if (saw_ORS && need_entire)
	    do_chop = TRUE;
	if (fswitch) {
	    str_cat(str,"$FS = '");
	    if (index("*+?.[]()|^$\\",fswitch))
		str_cat(str,"\\");
	    sprintf(tokenbuf,"%c",fswitch);
	    str_cat(str,tokenbuf);
	    str_cat(str,"';\t\t# field separator from -F switch\n");
	}
	else if (saw_FS && !const_FS) {
	    str_cat(str,"$FS = '[ \\t\\n]+';\t\t# set field separator\n");
	}
	if (saw_OFS) {
	    str_cat(str,"$, = ' ';\t\t# set output field separator\n");
	}
	if (saw_ORS) {
	    str_cat(str,"$\\ = \"\\n\";\t\t# set output record separator\n");
	}
	if (str->str_cur > 20)
	    str_cat(str,"\n");
	if (ops[node+2].ival) {
	    str_scat(str,fstr=walk(0,level,ops[node+2].ival,&numarg));
	    str_free(fstr);
	    str_cat(str,"\n\n");
	}
	if (saw_line_op)
	    str_cat(str,"line: ");
	str_cat(str,"while (<>) {\n");
	tab(str,++level);
	if (saw_FS && !const_FS)
	    do_chop = TRUE;
	if (do_chop) {
	    str_cat(str,"chop;\t# strip record separator\n");
	    tab(str,level);
	}
	arymax = 0;
	if (namelist) {
	    while (isalpha(*namelist)) {
		for (d = tokenbuf,s=namelist;
		  isalpha(*s) || isdigit(*s) || *s == '_';
		  *d++ = *s++) ;
		*d = '\0';
		while (*s && !isalpha(*s)) s++;
		namelist = s;
		nameary[++arymax] = savestr(tokenbuf);
	    }
	}
	if (maxfld < arymax)
	    maxfld = arymax;
	if (do_split)
	    emit_split(str,level);
	str_scat(str,fstr=walk(0,level,ops[node+3].ival,&numarg));
	str_free(fstr);
	fixtab(str,--level);
	str_cat(str,"}\n");
	if (ops[node+4].ival) {
	    realexit = TRUE;
	    str_cat(str,"\n");
	    tab(str,level);
	    str_scat(str,fstr=walk(0,level,ops[node+4].ival,&numarg));
	    str_free(fstr);
	    str_cat(str,"\n");
	}
	if (exitval)
	    str_cat(str,"exit ExitValue;\n");
	if (do_fancy_opens) {
	    str_cat(str,"\n\
sub Pick {\n\
    ($name) = @_;\n\
    $fh = $opened{$name};\n\
    if (!$fh) {\n\
	$nextfh == 0 && open(fh_0,$name);\n\
	$nextfh == 1 && open(fh_1,$name);\n\
	$nextfh == 2 && open(fh_2,$name);\n\
	$nextfh == 3 && open(fh_3,$name);\n\
	$nextfh == 4 && open(fh_4,$name);\n\
	$nextfh == 5 && open(fh_5,$name);\n\
	$nextfh == 6 && open(fh_6,$name);\n\
	$nextfh == 7 && open(fh_7,$name);\n\
	$nextfh == 8 && open(fh_8,$name);\n\
	$nextfh == 9 && open(fh_9,$name);\n\
	$fh = $opened{$name} = 'fh_' . $nextfh++;\n\
    }\n\
    select($fh);\n\
}\n\
");
	}
	break;
    case OHUNKS:
	str = walk(0,level,ops[node+1].ival,&numarg);
	str_scat(str,fstr=walk(0,level,ops[node+2].ival,&numarg));
	str_free(fstr);
	if (len == 3) {
	    str_scat(str,fstr=walk(0,level,ops[node+3].ival,&numarg));
	    str_free(fstr);
	}
	else {
	}
	break;
    case ORANGE:
	str = walk(1,level,ops[node+1].ival,&numarg);
	str_cat(str," .. ");
	str_scat(str,fstr=walk(1,level,ops[node+2].ival,&numarg));
	str_free(fstr);
	break;
    case OPAT:
	goto def;
    case OREGEX:
	str = str_new(0);
	str_set(str,"/");
	tmpstr=walk(0,level,ops[node+1].ival,&numarg);
	/* translate \nnn to [\nnn] */
	for (s = tmpstr->str_ptr, d = tokenbuf; *s; s++, d++) {
	    if (*s == '\\' && isdigit(s[1]) && isdigit(s[2]) && isdigit(s[3])) {
		*d++ = '[';
		*d++ = *s++;
		*d++ = *s++;
		*d++ = *s++;
		*d++ = *s;
		*d = ']';
	    }
	    else
		*d = *s;
	}
	*d = '\0';
	str_cat(str,tokenbuf);
	str_free(tmpstr);
	str_cat(str,"/");
	break;
    case OHUNK:
	if (len == 1) {
	    str = str_new(0);
	    str = walk(0,level,oper1(OPRINT,0),&numarg);
	    str_cat(str," if ");
	    str_scat(str,fstr=walk(0,level,ops[node+1].ival,&numarg));
	    str_free(fstr);
	    str_cat(str,";");
	}
	else {
	    tmpstr = walk(0,level,ops[node+1].ival,&numarg);
	    if (*tmpstr->str_ptr) {
		str = str_new(0);
		str_set(str,"if (");
		str_scat(str,tmpstr);
		str_cat(str,") {\n");
		tab(str,++level);
		str_scat(str,fstr=walk(0,level,ops[node+2].ival,&numarg));
		str_free(fstr);
		fixtab(str,--level);
		str_cat(str,"}\n");
		tab(str,level);
	    }
	    else {
		str = walk(0,level,ops[node+2].ival,&numarg);
	    }
	}
	break;
    case OPPAREN:
	str = str_new(0);
	str_set(str,"(");
	str_scat(str,fstr=walk(useval != 0,level,ops[node+1].ival,&numarg));
	str_free(fstr);
	str_cat(str,")");
	break;
    case OPANDAND:
	str = walk(1,level,ops[node+1].ival,&numarg);
	str_cat(str," && ");
	str_scat(str,fstr=walk(1,level,ops[node+2].ival,&numarg));
	str_free(fstr);
	break;
    case OPOROR:
	str = walk(1,level,ops[node+1].ival,&numarg);
	str_cat(str," || ");
	str_scat(str,fstr=walk(1,level,ops[node+2].ival,&numarg));
	str_free(fstr);
	break;
    case OPNOT:
	str = str_new(0);
	str_set(str,"!");
	str_scat(str,fstr=walk(1,level,ops[node+1].ival,&numarg));
	str_free(fstr);
	break;
    case OCPAREN:
	str = str_new(0);
	str_set(str,"(");
	str_scat(str,fstr=walk(useval != 0,level,ops[node+1].ival,&numarg));
	str_free(fstr);
	numeric |= numarg;
	str_cat(str,")");
	break;
    case OCANDAND:
	str = walk(1,level,ops[node+1].ival,&numarg);
	numeric = 1;
	str_cat(str," && ");
	str_scat(str,fstr=walk(1,level,ops[node+2].ival,&numarg));
	str_free(fstr);
	break;
    case OCOROR:
	str = walk(1,level,ops[node+1].ival,&numarg);
	numeric = 1;
	str_cat(str," || ");
	str_scat(str,fstr=walk(1,level,ops[node+2].ival,&numarg));
	str_free(fstr);
	break;
    case OCNOT:
	str = str_new(0);
	str_set(str,"!");
	str_scat(str,fstr=walk(1,level,ops[node+1].ival,&numarg));
	str_free(fstr);
	numeric = 1;
	break;
    case ORELOP:
	str = walk(1,level,ops[node+2].ival,&numarg);
	numeric |= numarg;
	tmpstr = walk(0,level,ops[node+1].ival,&numarg);
	tmp2str = walk(1,level,ops[node+3].ival,&numarg);
	numeric |= numarg;
	if (!numeric) {
	    t = tmpstr->str_ptr;
	    if (strEQ(t,"=="))
		str_set(tmpstr,"eq");
	    else if (strEQ(t,"!="))
		str_set(tmpstr,"ne");
	    else if (strEQ(t,"<"))
		str_set(tmpstr,"lt");
	    else if (strEQ(t,"<="))
		str_set(tmpstr,"le");
	    else if (strEQ(t,">"))
		str_set(tmpstr,"gt");
	    else if (strEQ(t,">="))
		str_set(tmpstr,"ge");
	    if (!index(tmpstr->str_ptr,'\'') && !index(tmpstr->str_ptr,'"') &&
	      !index(tmp2str->str_ptr,'\'') && !index(tmp2str->str_ptr,'"') )
		numeric |= 2;
	}
	if (numeric & 2) {
	    if (numeric & 1)		/* numeric is very good guess */
		str_cat(str," ");
	    else
		str_cat(str,"\377");
	    numeric = 1;
	}
	else
	    str_cat(str," ");
	str_scat(str,tmpstr);
	str_free(tmpstr);
	str_cat(str," ");
	str_scat(str,tmp2str);
	str_free(tmp2str);
	numeric = 1;
	break;
    case ORPAREN:
	str = str_new(0);
	str_set(str,"(");
	str_scat(str,fstr=walk(useval != 0,level,ops[node+1].ival,&numarg));
	str_free(fstr);
	numeric |= numarg;
	str_cat(str,")");
	break;
    case OMATCHOP:
	str = walk(1,level,ops[node+2].ival,&numarg);
	str_cat(str," ");
	tmpstr = walk(0,level,ops[node+1].ival,&numarg);
	if (strEQ(tmpstr->str_ptr,"~"))
	    str_cat(str,"=~");
	else {
	    str_scat(str,tmpstr);
	    str_free(tmpstr);
	}
	str_cat(str," ");
	str_scat(str,fstr=walk(1,level,ops[node+3].ival,&numarg));
	str_free(fstr);
	numeric = 1;
	break;
    case OMPAREN:
	str = str_new(0);
	str_set(str,"(");
	str_scat(str,fstr=walk(useval != 0,level,ops[node+1].ival,&numarg));
	str_free(fstr);
	numeric |= numarg;
	str_cat(str,")");
	break;
    case OCONCAT:
	str = walk(1,level,ops[node+1].ival,&numarg);
	str_cat(str," . ");
	str_scat(str,fstr=walk(1,level,ops[node+2].ival,&numarg));
	str_free(fstr);
	break;
    case OASSIGN:
	str = walk(0,level,ops[node+2].ival,&numarg);
	str_cat(str," ");
	tmpstr = walk(0,level,ops[node+1].ival,&numarg);
	str_scat(str,tmpstr);
	if (str_len(tmpstr) > 1)
	    numeric = 1;
	str_free(tmpstr);
	str_cat(str," ");
	str_scat(str,fstr=walk(1,level,ops[node+3].ival,&numarg));
	str_free(fstr);
	numeric |= numarg;
	if (strEQ(str->str_ptr,"$FS = '\240'"))
	    str_set(str,"$FS = '[\240\\n\\t]+'");
	break;
    case OADD:
	str = walk(1,level,ops[node+1].ival,&numarg);
	str_cat(str," + ");
	str_scat(str,fstr=walk(1,level,ops[node+2].ival,&numarg));
	str_free(fstr);
	numeric = 1;
	break;
    case OSUB:
	str = walk(1,level,ops[node+1].ival,&numarg);
	str_cat(str," - ");
	str_scat(str,fstr=walk(1,level,ops[node+2].ival,&numarg));
	str_free(fstr);
	numeric = 1;
	break;
    case OMULT:
	str = walk(1,level,ops[node+1].ival,&numarg);
	str_cat(str," * ");
	str_scat(str,fstr=walk(1,level,ops[node+2].ival,&numarg));
	str_free(fstr);
	numeric = 1;
	break;
    case ODIV:
	str = walk(1,level,ops[node+1].ival,&numarg);
	str_cat(str," / ");
	str_scat(str,fstr=walk(1,level,ops[node+2].ival,&numarg));
	str_free(fstr);
	numeric = 1;
	break;
    case OMOD:
	str = walk(1,level,ops[node+1].ival,&numarg);
	str_cat(str," % ");
	str_scat(str,fstr=walk(1,level,ops[node+2].ival,&numarg));
	str_free(fstr);
	numeric = 1;
	break;
    case OPOSTINCR:
	str = walk(1,level,ops[node+1].ival,&numarg);
	str_cat(str,"++");
	numeric = 1;
	break;
    case OPOSTDECR:
	str = walk(1,level,ops[node+1].ival,&numarg);
	str_cat(str,"--");
	numeric = 1;
	break;
    case OPREINCR:
	str = str_new(0);
	str_set(str,"++");
	str_scat(str,fstr=walk(1,level,ops[node+1].ival,&numarg));
	str_free(fstr);
	numeric = 1;
	break;
    case OPREDECR:
	str = str_new(0);
	str_set(str,"--");
	str_scat(str,fstr=walk(1,level,ops[node+1].ival,&numarg));
	str_free(fstr);
	numeric = 1;
	break;
    case OUMINUS:
	str = str_new(0);
	str_set(str,"-");
	str_scat(str,fstr=walk(1,level,ops[node+1].ival,&numarg));
	str_free(fstr);
	numeric = 1;
	break;
    case OUPLUS:
	numeric = 1;
	goto def;
    case OPAREN:
	str = str_new(0);
	str_set(str,"(");
	str_scat(str,fstr=walk(useval != 0,level,ops[node+1].ival,&numarg));
	str_free(fstr);
	str_cat(str,")");
	numeric |= numarg;
	break;
    case OGETLINE:
	str = str_new(0);
	str_set(str,"$_ = <>;\n");
	tab(str,level);
	if (do_chop) {
	    str_cat(str,"chop;\t# strip record separator\n");
	    tab(str,level);
	}
	if (do_split)
	    emit_split(str,level);
	break;
    case OSPRINTF:
	str = str_new(0);
	str_set(str,"sprintf(");
	str_scat(str,fstr=walk(1,level,ops[node+1].ival,&numarg));
	str_free(fstr);
	str_cat(str,")");
	break;
    case OSUBSTR:
	str = str_new(0);
	str_set(str,"substr(");
	str_scat(str,fstr=walk(1,level,ops[node+1].ival,&numarg));
	str_free(fstr);
	str_cat(str,", ");
	str_scat(str,fstr=walk(1,level,ops[node+2].ival,&numarg));
	str_free(fstr);
	str_cat(str,", ");
	if (len == 3) {
	    str_scat(str,fstr=walk(1,level,ops[node+3].ival,&numarg));
	    str_free(fstr);
	}
	else
	    str_cat(str,"999999");
	str_cat(str,")");
	break;
    case OSTRING:
	str = str_new(0);
	str_set(str,ops[node+1].cval);
	break;
    case OSPLIT:
	str = str_new(0);
	numeric = 1;
	tmpstr = walk(1,level,ops[node+2].ival,&numarg);
	if (useval)
	    str_set(str,"(@");
	else
	    str_set(str,"@");
	str_scat(str,tmpstr);
	str_cat(str," = split(");
	if (len == 3) {
	    fstr = walk(1,level,ops[node+3].ival,&numarg);
	    if (str_len(fstr) == 3 && *fstr->str_ptr == '\'') {
		i = fstr->str_ptr[1] & 127;
		if (index("*+?.[]()|^$\\",i))
		    sprintf(tokenbuf,"/\\%c/",i);
		else
		    sprintf(tokenbuf,"/%c/",i);
		str_cat(str,tokenbuf);
	    }
	    else
		str_scat(str,fstr);
	    str_free(fstr);
	}
	else if (const_FS) {
	    sprintf(tokenbuf,"/[%c\\n]/",const_FS);
	    str_cat(str,tokenbuf);
	}
	else if (saw_FS)
	    str_cat(str,"$FS");
	else
	    str_cat(str,"/[ \\t\\n]+/");
	str_cat(str,", ");
	str_scat(str,fstr=walk(1,level,ops[node+1].ival,&numarg));
	str_free(fstr);
	str_cat(str,")");
	if (useval) {
	    str_cat(str,")");
	}
	str_free(tmpstr);
	break;
    case OINDEX:
	str = str_new(0);
	str_set(str,"index(");
	str_scat(str,fstr=walk(1,level,ops[node+1].ival,&numarg));
	str_free(fstr);
	str_cat(str,", ");
	str_scat(str,fstr=walk(1,level,ops[node+2].ival,&numarg));
	str_free(fstr);
	str_cat(str,")");
	numeric = 1;
	break;
    case ONUM:
	str = walk(1,level,ops[node+1].ival,&numarg);
	numeric = 1;
	break;
    case OSTR:
	tmpstr = walk(1,level,ops[node+1].ival,&numarg);
	s = "'";
	for (t = tmpstr->str_ptr; *t; t++) {
	    if (*t == '\\' || *t == '\'')
		s = "\"";
	    *t += 128;
	}
	str = str_new(0);
	str_set(str,s);
	str_scat(str,tmpstr);
	str_free(tmpstr);
	str_cat(str,s);
	break;
    case OVAR:
	str = str_new(0);
	str_set(str,"$");
	str_scat(str,tmpstr=walk(1,level,ops[node+1].ival,&numarg));
	if (len == 1) {
	    tmp2str = hfetch(symtab,tmpstr->str_ptr);
	    if (tmp2str && atoi(tmp2str->str_ptr))
		numeric = 2;
	    if (strEQ(str->str_ptr,"$NR")) {
		numeric = 1;
		str_set(str,"$.");
	    }
	    else if (strEQ(str->str_ptr,"$NF")) {
		numeric = 1;
		str_set(str,"$#Fld");
	    }
	    else if (strEQ(str->str_ptr,"$0"))
		str_set(str,"$_");
	}
	else {
	    str_cat(tmpstr,"[]");
	    tmp2str = hfetch(symtab,tmpstr->str_ptr);
	    if (tmp2str && atoi(tmp2str->str_ptr))
		str_cat(str,"[");
	    else
		str_cat(str,"{");
	    str_scat(str,fstr=walk(1,level,ops[node+2].ival,&numarg));
	    str_free(fstr);
	    if (tmp2str && atoi(tmp2str->str_ptr))
		strcpy(tokenbuf,"]");
	    else
		strcpy(tokenbuf,"}");
	    *tokenbuf += 128;
	    str_cat(str,tokenbuf);
	}
	str_free(tmpstr);
	break;
    case OFLD:
	str = str_new(0);
	if (split_to_array) {
	    str_set(str,"$Fld");
	    str_cat(str,"[");
	    str_scat(str,fstr=walk(1,level,ops[node+1].ival,&numarg));
	    str_free(fstr);
	    str_cat(str,"]");
	}
	else {
	    i = atoi(walk(1,level,ops[node+1].ival,&numarg)->str_ptr);
	    if (i <= arymax)
		sprintf(tokenbuf,"$%s",nameary[i]);
	    else
		sprintf(tokenbuf,"$Fld%d",i);
	    str_set(str,tokenbuf);
	}
	break;
    case OVFLD:
	str = str_new(0);
	str_set(str,"$Fld[");
	i = ops[node+1].ival;
	if ((ops[i].ival & 255) == OPAREN)
	    i = ops[i+1].ival;
	tmpstr=walk(1,level,i,&numarg);
	str_scat(str,tmpstr);
	str_free(tmpstr);
	str_cat(str,"]");
	break;
    case OJUNK:
	goto def;
    case OSNEWLINE:
	str = str_new(2);
	str_set(str,";\n");
	tab(str,level);
	break;
    case ONEWLINE:
	str = str_new(1);
	str_set(str,"\n");
	tab(str,level);
	break;
    case OSCOMMENT:
	str = str_new(0);
	str_set(str,";");
	tmpstr = walk(0,level,ops[node+1].ival,&numarg);
	for (s = tmpstr->str_ptr; *s && *s != '\n'; s++)
	    *s += 128;
	str_scat(str,tmpstr);
	str_free(tmpstr);
	tab(str,level);
	break;
    case OCOMMENT:
	str = str_new(0);
	tmpstr = walk(0,level,ops[node+1].ival,&numarg);
	for (s = tmpstr->str_ptr; *s && *s != '\n'; s++)
	    *s += 128;
	str_scat(str,tmpstr);
	str_free(tmpstr);
	tab(str,level);
	break;
    case OCOMMA:
	str = walk(1,level,ops[node+1].ival,&numarg);
	str_cat(str,", ");
	str_scat(str,fstr=walk(1,level,ops[node+2].ival,&numarg));
	str_free(fstr);
	break;
    case OSEMICOLON:
	str = str_new(1);
	str_set(str,"; ");
	break;
    case OSTATES:
	str = walk(0,level,ops[node+1].ival,&numarg);
	str_scat(str,fstr=walk(0,level,ops[node+2].ival,&numarg));
	str_free(fstr);
	break;
    case OSTATE:
	str = str_new(0);
	if (len >= 1) {
	    str_scat(str,fstr=walk(0,level,ops[node+1].ival,&numarg));
	    str_free(fstr);
	    if (len >= 2) {
		tmpstr = walk(0,level,ops[node+2].ival,&numarg);
		if (*tmpstr->str_ptr == ';') {
		    addsemi(str);
		    str_cat(str,tmpstr->str_ptr+1);
		}
		str_free(tmpstr);
	    }
	}
	break;
    case OPRINTF:
    case OPRINT:
	str = str_new(0);
	if (len == 3) {		/* output redirection */
	    tmpstr = walk(1,level,ops[node+3].ival,&numarg);
	    tmp2str = walk(1,level,ops[node+2].ival,&numarg);
	    if (!do_fancy_opens) {
		t = tmpstr->str_ptr;
		if (*t == '"' || *t == '\'')
		    t = cpytill(tokenbuf,t+1,*t);
		else
		    fatal("Internal error: OPRINT");
		d = savestr(t);
		s = savestr(tokenbuf);
		for (t = tokenbuf; *t; t++) {
		    *t &= 127;
		    if (!isalpha(*t) && !isdigit(*t))
			*t = '_';
		}
		if (!index(tokenbuf,'_'))
		    strcpy(t,"_fh");
		str_cat(opens,"open(");
		str_cat(opens,tokenbuf);
		str_cat(opens,", ");
		d[1] = '\0';
		str_cat(opens,d);
		str_scat(opens,tmp2str);
		str_cat(opens,tmpstr->str_ptr+1);
		if (*tmp2str->str_ptr == '|')
		    str_cat(opens,") || die 'Cannot pipe to \"");
		else
		    str_cat(opens,") || die 'Cannot create file \"");
		if (*d == '"')
		    str_cat(opens,"'.\"");
		str_cat(opens,s);
		if (*d == '"')
		    str_cat(opens,"\".'");
		str_cat(opens,"\".';\n");
		str_free(tmpstr);
		str_free(tmp2str);
		safefree(s);
		safefree(d);
	    }
	    else {
		sprintf(tokenbuf,"do Pick('%s' . (%s)) &&\n",
		   tmp2str->str_ptr, tmpstr->str_ptr);
		str_cat(str,tokenbuf);
		tab(str,level+1);
		*tokenbuf = '\0';
		str_free(tmpstr);
		str_free(tmp2str);
	    }
	}
	else
	    strcpy(tokenbuf,"stdout");
	if (type == OPRINTF)
	    str_cat(str,"printf");
	else
	    str_cat(str,"print");
	if (len == 3 || do_fancy_opens) {
	    if (*tokenbuf)
		str_cat(str," ");
	    str_cat(str,tokenbuf);
	}
	tmpstr = walk(1+(type==OPRINT),level,ops[node+1].ival,&numarg);
	if (!*tmpstr->str_ptr && lval_field) {
	    t = saw_OFS ? "$," : "' '";
	    if (split_to_array) {
		sprintf(tokenbuf,"join(%s,@Fld)",t);
		str_cat(tmpstr,tokenbuf);
	    }
	    else {
		for (i = 1; i < maxfld; i++) {
		    if (i <= arymax)
			sprintf(tokenbuf,"$%s, ",nameary[i]);
		    else
			sprintf(tokenbuf,"$Fld%d, ",i);
		    str_cat(tmpstr,tokenbuf);
		}
		if (maxfld <= arymax)
		    sprintf(tokenbuf,"$%s",nameary[maxfld]);
		else
		    sprintf(tokenbuf,"$Fld%d",maxfld);
		str_cat(tmpstr,tokenbuf);
	    }
	}
	if (*tmpstr->str_ptr) {
	    str_cat(str," ");
	    str_scat(str,tmpstr);
	}
	else {
	    str_cat(str," $_");
	}
	str_free(tmpstr);
	break;
    case OLENGTH:
	str = str_make("length(");
	goto maybe0;
    case OLOG:
	str = str_make("log(");
	goto maybe0;
    case OEXP:
	str = str_make("exp(");
	goto maybe0;
    case OSQRT:
	str = str_make("sqrt(");
	goto maybe0;
    case OINT:
	str = str_make("int(");
      maybe0:
	numeric = 1;
	if (len > 0)
	    tmpstr = walk(1,level,ops[node+1].ival,&numarg);
	else
	    tmpstr = str_new(0);;
	if (!*tmpstr->str_ptr) {
	    if (lval_field) {
		t = saw_OFS ? "$," : "' '";
		if (split_to_array) {
		    sprintf(tokenbuf,"join(%s,@Fld)",t);
		    str_cat(tmpstr,tokenbuf);
		}
		else {
		    sprintf(tokenbuf,"join(%s, ",t);
		    str_cat(tmpstr,tokenbuf);
		    for (i = 1; i < maxfld; i++) {
			if (i <= arymax)
			    sprintf(tokenbuf,"$%s,",nameary[i]);
			else
			    sprintf(tokenbuf,"$Fld%d,",i);
			str_cat(tmpstr,tokenbuf);
		    }
		    if (maxfld <= arymax)
			sprintf(tokenbuf,"$%s)",nameary[maxfld]);
		    else
			sprintf(tokenbuf,"$Fld%d)",maxfld);
		    str_cat(tmpstr,tokenbuf);
		}
	    }
	    else
		str_cat(tmpstr,"$_");
	}
	if (strEQ(tmpstr->str_ptr,"$_")) {
	    if (type == OLENGTH && !do_chop) {
		str = str_make("(length(");
		str_cat(tmpstr,") - 1");
	    }
	}
	str_scat(str,tmpstr);
	str_free(tmpstr);
	str_cat(str,")");
	break;
    case OBREAK:
	str = str_new(0);
	str_set(str,"last");
	break;
    case ONEXT:
	str = str_new(0);
	str_set(str,"next line");
	break;
    case OEXIT:
	str = str_new(0);
	if (realexit) {
	    str_set(str,"exit");
	    if (len == 1) {
		str_cat(str," ");
		exitval = TRUE;
		str_scat(str,fstr=walk(1,level,ops[node+1].ival,&numarg));
		str_free(fstr);
	    }
	}
	else {
	    if (len == 1) {
		str_set(str,"ExitValue = ");
		exitval = TRUE;
		str_scat(str,fstr=walk(1,level,ops[node+1].ival,&numarg));
		str_free(fstr);
		str_cat(str,"; ");
	    }
	    str_cat(str,"last line");
	}
	break;
    case OCONTINUE:
	str = str_new(0);
	str_set(str,"next");
	break;
    case OREDIR:
	goto def;
    case OIF:
	str = str_new(0);
	str_set(str,"if (");
	str_scat(str,fstr=walk(1,level,ops[node+1].ival,&numarg));
	str_free(fstr);
	str_cat(str,") ");
	str_scat(str,fstr=walk(0,level,ops[node+2].ival,&numarg));
	str_free(fstr);
	if (len == 3) {
	    i = ops[node+3].ival;
	    if (i) {
		if ((ops[i].ival & 255) == OBLOCK) {
		    i = ops[i+1].ival;
		    if (i) {
			if ((ops[i].ival & 255) != OIF)
			    i = 0;
		    }
		}
		else
		    i = 0;
	    }
	    if (i) {
		str_cat(str,"els");
		str_scat(str,fstr=walk(0,level,i,&numarg));
		str_free(fstr);
	    }
	    else {
		str_cat(str,"else ");
		str_scat(str,fstr=walk(0,level,ops[node+3].ival,&numarg));
		str_free(fstr);
	    }
	}
	break;
    case OWHILE:
	str = str_new(0);
	str_set(str,"while (");
	str_scat(str,fstr=walk(1,level,ops[node+1].ival,&numarg));
	str_free(fstr);
	str_cat(str,") ");
	str_scat(str,fstr=walk(0,level,ops[node+2].ival,&numarg));
	str_free(fstr);
	break;
    case OFOR:
	str = str_new(0);
	str_set(str,"for (");
	str_scat(str,tmpstr=walk(1,level,ops[node+1].ival,&numarg));
	i = numarg;
	if (i) {
	    t = s = tmpstr->str_ptr;
	    while (isalpha(*t) || isdigit(*t) || *t == '$' || *t == '_')
		t++;
	    i = t - s;
	    if (i < 2)
		i = 0;
	}
	str_cat(str,"; ");
	fstr=walk(1,level,ops[node+2].ival,&numarg);
	if (i && (t = index(fstr->str_ptr,0377))) {
	    if (strnEQ(fstr->str_ptr,s,i))
		*t = ' ';
	}
	str_scat(str,fstr);
	str_free(fstr);
	str_free(tmpstr);
	str_cat(str,"; ");
	str_scat(str,fstr=walk(1,level,ops[node+3].ival,&numarg));
	str_free(fstr);
	str_cat(str,") ");
	str_scat(str,fstr=walk(0,level,ops[node+4].ival,&numarg));
	str_free(fstr);
	break;
    case OFORIN:
	tmpstr=walk(0,level,ops[node+2].ival,&numarg);
	str = str_new(0);
	str_sset(str,tmpstr);
	str_cat(str,"[]");
	tmp2str = hfetch(symtab,str->str_ptr);
	if (tmp2str && atoi(tmp2str->str_ptr)) {
	    maxtmp++;
	    fstr=walk(1,level,ops[node+1].ival,&numarg);
	    sprintf(tokenbuf,
	      "for ($T_%d = 1; ($%s = $%s[$T_%d]) || $T_%d <= $#%s; $T_%d++)%c",
	      maxtmp,
	      fstr->str_ptr,
	      tmpstr->str_ptr,
	      maxtmp,
	      maxtmp,
	      tmpstr->str_ptr,
	      maxtmp,
	      0377);
	    str_set(str,tokenbuf);
	    str_free(fstr);
	    str_scat(str,fstr=walk(0,level,ops[node+3].ival,&numarg));
	    str_free(fstr);
	}
	else {
	    str_set(str,"while (($junkkey,$");
	    str_scat(str,fstr=walk(1,level,ops[node+1].ival,&numarg));
	    str_free(fstr);
	    str_cat(str,") = each(");
	    str_scat(str,tmpstr);
	    str_cat(str,")) ");
	    str_scat(str,fstr=walk(0,level,ops[node+3].ival,&numarg));
	    str_free(fstr);
	}
	str_free(tmpstr);
	break;
    case OBLOCK:
	str = str_new(0);
	str_set(str,"{");
	if (len == 2) {
	    str_scat(str,fstr=walk(0,level,ops[node+2].ival,&numarg));
	    str_free(fstr);
	}
	fixtab(str,++level);
	str_scat(str,fstr=walk(0,level,ops[node+1].ival,&numarg));
	str_free(fstr);
	addsemi(str);
	fixtab(str,--level);
	str_cat(str,"}\n");
	tab(str,level);
	break;
    default:
      def:
	if (len) {
	    if (len > 5)
		fatal("Garbage length in walk");
	    str = walk(0,level,ops[node+1].ival,&numarg);
	    for (i = 2; i<= len; i++) {
		str_scat(str,fstr=walk(0,level,ops[node+i].ival,&numarg));
		str_free(fstr);
	    }
	}
	else {
	    str = Nullstr;
	}
	break;
    }
    if (!str)
	str = str_new(0);
    *numericptr = numeric;
#ifdef DEBUGGING
    if (debug & 4) {
	printf("%3d %5d %15s %d %4d ",level,node,opname[type],len,str->str_cur);
	for (t = str->str_ptr; *t && t - str->str_ptr < 40; t++)
	    if (*t == '\n')
		printf("\\n");
	    else if (*t == '\t')
		printf("\\t");
	    else
		putchar(*t);
	putchar('\n');
    }
#endif
    return str;
}

tab(str,lvl)
register STR *str;
register int lvl;
{
    while (lvl > 1) {
	str_cat(str,"\t");
	lvl -= 2;
    }
    if (lvl)
	str_cat(str,"    ");
}

fixtab(str,lvl)
register STR *str;
register int lvl;
{
    register char *s;

    /* strip trailing white space */

    s = str->str_ptr+str->str_cur - 1;
    while (s >= str->str_ptr && (*s == ' ' || *s == '\t'))
	s--;
    s[1] = '\0';
    str->str_cur = s + 1 - str->str_ptr;
    if (s >= str->str_ptr && *s != '\n')
	str_cat(str,"\n");

    tab(str,lvl);
}

addsemi(str)
register STR *str;
{
    register char *s;

    s = str->str_ptr+str->str_cur - 1;
    while (s >= str->str_ptr && (*s == ' ' || *s == '\t' || *s == '\n'))
	s--;
    if (s >= str->str_ptr && *s != ';' && *s != '}')
	str_cat(str,";");
}

emit_split(str,level)
register STR *str;
int level;
{
    register int i;

    if (split_to_array)
	str_cat(str,"@Fld");
    else {
	str_cat(str,"(");
	for (i = 1; i < maxfld; i++) {
	    if (i <= arymax)
		sprintf(tokenbuf,"$%s,",nameary[i]);
	    else
		sprintf(tokenbuf,"$Fld%d,",i);
	    str_cat(str,tokenbuf);
	}
	if (maxfld <= arymax)
	    sprintf(tokenbuf,"$%s)",nameary[maxfld]);
	else
	    sprintf(tokenbuf,"$Fld%d)",maxfld);
	str_cat(str,tokenbuf);
    }
    if (const_FS) {
	sprintf(tokenbuf," = split(/[%c\\n]/);\n",const_FS);
	str_cat(str,tokenbuf);
    }
    else if (saw_FS)
	str_cat(str," = split($FS);\n");
    else
	str_cat(str," = split;\n");
    tab(str,level);
}

prewalk(numit,level,node,numericptr)
int numit;
int level;
register int node;
int *numericptr;
{
    register int len;
    register int type;
    register int i;
    char *t;
    char *d, *s;
    int numarg;
    int numeric = FALSE;

    if (!node) {
	*numericptr = 0;
	return 0;
    }
    type = ops[node].ival;
    len = type >> 8;
    type &= 255;
    switch (type) {
    case OPROG:
	prewalk(0,level,ops[node+1].ival,&numarg);
	if (ops[node+2].ival) {
	    prewalk(0,level,ops[node+2].ival,&numarg);
	}
	++level;
	prewalk(0,level,ops[node+3].ival,&numarg);
	--level;
	if (ops[node+3].ival) {
	    prewalk(0,level,ops[node+4].ival,&numarg);
	}
	break;
    case OHUNKS:
	prewalk(0,level,ops[node+1].ival,&numarg);
	prewalk(0,level,ops[node+2].ival,&numarg);
	if (len == 3) {
	    prewalk(0,level,ops[node+3].ival,&numarg);
	}
	break;
    case ORANGE:
	prewalk(1,level,ops[node+1].ival,&numarg);
	prewalk(1,level,ops[node+2].ival,&numarg);
	break;
    case OPAT:
	goto def;
    case OREGEX:
	prewalk(0,level,ops[node+1].ival,&numarg);
	break;
    case OHUNK:
	if (len == 1) {
	    prewalk(0,level,ops[node+1].ival,&numarg);
	}
	else {
	    i = prewalk(0,level,ops[node+1].ival,&numarg);
	    if (i) {
		++level;
		prewalk(0,level,ops[node+2].ival,&numarg);
		--level;
	    }
	    else {
		prewalk(0,level,ops[node+2].ival,&numarg);
	    }
	}
	break;
    case OPPAREN:
	prewalk(0,level,ops[node+1].ival,&numarg);
	break;
    case OPANDAND:
	prewalk(0,level,ops[node+1].ival,&numarg);
	prewalk(0,level,ops[node+2].ival,&numarg);
	break;
    case OPOROR:
	prewalk(0,level,ops[node+1].ival,&numarg);
	prewalk(0,level,ops[node+2].ival,&numarg);
	break;
    case OPNOT:
	prewalk(0,level,ops[node+1].ival,&numarg);
	break;
    case OCPAREN:
	prewalk(0,level,ops[node+1].ival,&numarg);
	numeric |= numarg;
	break;
    case OCANDAND:
	prewalk(0,level,ops[node+1].ival,&numarg);
	numeric = 1;
	prewalk(0,level,ops[node+2].ival,&numarg);
	break;
    case OCOROR:
	prewalk(0,level,ops[node+1].ival,&numarg);
	numeric = 1;
	prewalk(0,level,ops[node+2].ival,&numarg);
	break;
    case OCNOT:
	prewalk(0,level,ops[node+1].ival,&numarg);
	numeric = 1;
	break;
    case ORELOP:
	prewalk(0,level,ops[node+2].ival,&numarg);
	numeric |= numarg;
	prewalk(0,level,ops[node+1].ival,&numarg);
	prewalk(0,level,ops[node+3].ival,&numarg);
	numeric |= numarg;
	numeric = 1;
	break;
    case ORPAREN:
	prewalk(0,level,ops[node+1].ival,&numarg);
	numeric |= numarg;
	break;
    case OMATCHOP:
	prewalk(0,level,ops[node+2].ival,&numarg);
	prewalk(0,level,ops[node+1].ival,&numarg);
	prewalk(0,level,ops[node+3].ival,&numarg);
	numeric = 1;
	break;
    case OMPAREN:
	prewalk(0,level,ops[node+1].ival,&numarg);
	numeric |= numarg;
	break;
    case OCONCAT:
	prewalk(0,level,ops[node+1].ival,&numarg);
	prewalk(0,level,ops[node+2].ival,&numarg);
	break;
    case OASSIGN:
	prewalk(0,level,ops[node+2].ival,&numarg);
	prewalk(0,level,ops[node+1].ival,&numarg);
	prewalk(0,level,ops[node+3].ival,&numarg);
	if (numarg || strlen(ops[ops[node+1].ival+1].cval) > 1) {
	    numericize(ops[node+2].ival);
	    if (!numarg)
		numericize(ops[node+3].ival);
	}
	numeric |= numarg;
	break;
    case OADD:
	prewalk(1,level,ops[node+1].ival,&numarg);
	prewalk(1,level,ops[node+2].ival,&numarg);
	numeric = 1;
	break;
    case OSUB:
	prewalk(1,level,ops[node+1].ival,&numarg);
	prewalk(1,level,ops[node+2].ival,&numarg);
	numeric = 1;
	break;
    case OMULT:
	prewalk(1,level,ops[node+1].ival,&numarg);
	prewalk(1,level,ops[node+2].ival,&numarg);
	numeric = 1;
	break;
    case ODIV:
	prewalk(1,level,ops[node+1].ival,&numarg);
	prewalk(1,level,ops[node+2].ival,&numarg);
	numeric = 1;
	break;
    case OMOD:
	prewalk(1,level,ops[node+1].ival,&numarg);
	prewalk(1,level,ops[node+2].ival,&numarg);
	numeric = 1;
	break;
    case OPOSTINCR:
	prewalk(1,level,ops[node+1].ival,&numarg);
	numeric = 1;
	break;
    case OPOSTDECR:
	prewalk(1,level,ops[node+1].ival,&numarg);
	numeric = 1;
	break;
    case OPREINCR:
	prewalk(1,level,ops[node+1].ival,&numarg);
	numeric = 1;
	break;
    case OPREDECR:
	prewalk(1,level,ops[node+1].ival,&numarg);
	numeric = 1;
	break;
    case OUMINUS:
	prewalk(1,level,ops[node+1].ival,&numarg);
	numeric = 1;
	break;
    case OUPLUS:
	prewalk(1,level,ops[node+1].ival,&numarg);
	numeric = 1;
	break;
    case OPAREN:
	prewalk(0,level,ops[node+1].ival,&numarg);
	numeric |= numarg;
	break;
    case OGETLINE:
	break;
    case OSPRINTF:
	prewalk(0,level,ops[node+1].ival,&numarg);
	break;
    case OSUBSTR:
	prewalk(0,level,ops[node+1].ival,&numarg);
	prewalk(1,level,ops[node+2].ival,&numarg);
	if (len == 3) {
	    prewalk(1,level,ops[node+3].ival,&numarg);
	}
	break;
    case OSTRING:
	break;
    case OSPLIT:
	numeric = 1;
	prewalk(0,level,ops[node+2].ival,&numarg);
	if (len == 3)
	    prewalk(0,level,ops[node+3].ival,&numarg);
	prewalk(0,level,ops[node+1].ival,&numarg);
	break;
    case OINDEX:
	prewalk(0,level,ops[node+1].ival,&numarg);
	prewalk(0,level,ops[node+2].ival,&numarg);
	numeric = 1;
	break;
    case ONUM:
	prewalk(0,level,ops[node+1].ival,&numarg);
	numeric = 1;
	break;
    case OSTR:
	prewalk(0,level,ops[node+1].ival,&numarg);
	break;
    case OVAR:
	prewalk(0,level,ops[node+1].ival,&numarg);
	if (len == 1) {
	    if (numit)
		numericize(node);
	}
	else {
	    prewalk(0,level,ops[node+2].ival,&numarg);
	}
	break;
    case OFLD:
	prewalk(0,level,ops[node+1].ival,&numarg);
	break;
    case OVFLD:
	i = ops[node+1].ival;
	prewalk(0,level,i,&numarg);
	break;
    case OJUNK:
	goto def;
    case OSNEWLINE:
	break;
    case ONEWLINE:
	break;
    case OSCOMMENT:
	break;
    case OCOMMENT:
	break;
    case OCOMMA:
	prewalk(0,level,ops[node+1].ival,&numarg);
	prewalk(0,level,ops[node+2].ival,&numarg);
	break;
    case OSEMICOLON:
	break;
    case OSTATES:
	prewalk(0,level,ops[node+1].ival,&numarg);
	prewalk(0,level,ops[node+2].ival,&numarg);
	break;
    case OSTATE:
	if (len >= 1) {
	    prewalk(0,level,ops[node+1].ival,&numarg);
	    if (len >= 2) {
		prewalk(0,level,ops[node+2].ival,&numarg);
	    }
	}
	break;
    case OPRINTF:
    case OPRINT:
	if (len == 3) {		/* output redirection */
	    prewalk(0,level,ops[node+3].ival,&numarg);
	    prewalk(0,level,ops[node+2].ival,&numarg);
	}
	prewalk(0+(type==OPRINT),level,ops[node+1].ival,&numarg);
	break;
    case OLENGTH:
	goto maybe0;
    case OLOG:
	goto maybe0;
    case OEXP:
	goto maybe0;
    case OSQRT:
	goto maybe0;
    case OINT:
      maybe0:
	numeric = 1;
	if (len > 0)
	    prewalk(type != OLENGTH,level,ops[node+1].ival,&numarg);
	break;
    case OBREAK:
	break;
    case ONEXT:
	break;
    case OEXIT:
	if (len == 1) {
	    prewalk(1,level,ops[node+1].ival,&numarg);
	}
	break;
    case OCONTINUE:
	break;
    case OREDIR:
	goto def;
    case OIF:
	prewalk(0,level,ops[node+1].ival,&numarg);
	prewalk(0,level,ops[node+2].ival,&numarg);
	if (len == 3) {
	    prewalk(0,level,ops[node+3].ival,&numarg);
	}
	break;
    case OWHILE:
	prewalk(0,level,ops[node+1].ival,&numarg);
	prewalk(0,level,ops[node+2].ival,&numarg);
	break;
    case OFOR:
	prewalk(0,level,ops[node+1].ival,&numarg);
	prewalk(0,level,ops[node+2].ival,&numarg);
	prewalk(0,level,ops[node+3].ival,&numarg);
	prewalk(0,level,ops[node+4].ival,&numarg);
	break;
    case OFORIN:
	prewalk(0,level,ops[node+2].ival,&numarg);
	prewalk(0,level,ops[node+1].ival,&numarg);
	prewalk(0,level,ops[node+3].ival,&numarg);
	break;
    case OBLOCK:
	if (len == 2) {
	    prewalk(0,level,ops[node+2].ival,&numarg);
	}
	++level;
	prewalk(0,level,ops[node+1].ival,&numarg);
	--level;
	break;
    default:
      def:
	if (len) {
	    if (len > 5)
		fatal("Garbage length in prewalk");
	    prewalk(0,level,ops[node+1].ival,&numarg);
	    for (i = 2; i<= len; i++) {
		prewalk(0,level,ops[node+i].ival,&numarg);
	    }
	}
	break;
    }
    *numericptr = numeric;
    return 1;
}

numericize(node)
register int node;
{
    register int len;
    register int type;
    register int i;
    STR *tmpstr;
    STR *tmp2str;
    int numarg;

    type = ops[node].ival;
    len = type >> 8;
    type &= 255;
    if (type == OVAR && len == 1) {
	tmpstr=walk(0,0,ops[node+1].ival,&numarg);
	tmp2str = str_make("1");
	hstore(symtab,tmpstr->str_ptr,tmp2str);
    }
}
