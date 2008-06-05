struct token_pos
{
    char *beg;
    char *end;
};
typedef struct token_pos token_pos_t;

#define dTOKENS(init_lim) \
   token_pos_t token_buf[init_lim]; \
   int token_lim = init_lim; \
   token_pos_t *tokens = token_buf; \
   int num_tokens = 0

#define PUSH_TOKEN(p_beg, p_end) \
   STMT_START { \
       ++num_tokens; \
       if (num_tokens == token_lim) \
           tokens_grow(&tokens, &token_lim, (bool)(tokens != token_buf)); \
       tokens[num_tokens-1].beg = p_beg; \
       tokens[num_tokens-1].end = p_end; \
   } STMT_END

#define FREE_TOKENS \
   STMT_START { \
       if (tokens != token_buf) \
          Safefree(tokens); \
   } STMT_END

static void
tokens_grow(token_pos_t **token_ptr, int *token_lim_ptr, bool tokens_on_heap)
{
    int new_lim = *token_lim_ptr;
    if (new_lim < 4)
	new_lim = 4;
    new_lim *= 2;

    if (tokens_on_heap) {
	Renew(*token_ptr, new_lim, token_pos_t);
    }
    else {
	token_pos_t *new_tokens;
	int i;
	New(57, new_tokens, new_lim, token_pos_t);
	for (i = 0; i < *token_lim_ptr; i++)
	    new_tokens[i] = (*token_ptr)[i];
	*token_ptr = new_tokens;
    }
    *token_lim_ptr = new_lim;
}
