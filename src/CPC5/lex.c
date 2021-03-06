#define debug1(x)   /* printf(x) */
#define debug2(x,y) /* printf(x,y) */

#define EOF          -1

/* These codes are reserved for tokens that are neither characters
 * nor keywords.  We start numbering at 257 to avoid collision with
 * the pre-defined codes for single-character tokens.  If you add to
 * the following list, make sure the numbers are sequential and bumb
 * Fkeyword by one.  Make sure the token names in this file are in the
 * same order as they are in the yacc grammar.
 */
#define IDENTIFIER  257
#define STRING      258
#define LINE_END    259
#define ZERO        260
#define NUMBER      261

/* After we have assigned numbers to the special tokens, continue the
 * numbering sequence sequentially.  Fkeyword is the number of the first
 * keyword, and Nkeywords is the number of keywords.
 */
#define Fkeyword    262
#define Nkeywords    31

/* If you add to the following list, bump Nkeywords by one.  Make sure the
 * token names in this file are in the same order as they are in the
 * yacc grammar.
 */
char *keywords[Nkeywords + 1] = {
      "ASSIGN",
      "BEGIN",
      "BRANCH",
      "BREAK",
      "END",
      "FREEZE",
      "HANG",
      "JOIN",
      "NEW",
      "REIN",
      "RENEW",
      "REOUT",
      "REQUIRE",
      "PROCLAIM",
      "SAFE",
      "SIDE",
      "SPLIT",
      "THAW",
      "WHEN",
      "subrange",
      "boolean",
      "integer",
      "fixed",
      "set",
      "array",
      "record",
      "module",
      "universal",
      "variable",
      "function",
      "rulefunction",
       0};

/* If you add to the following list, make sure the token names in this
 * file are in the same order as they are in the yacc grammar.
 */
char *builtins[] = {
      "consti",
      "addi",
      "subi",
      "negi",
      "succ",
      "pred",
      "muli",
      "divi",
      "mod",
      "odd",
      "gei",
      "lei",
      "gti",
      "lti",
      "mini",
      "maxi",
      "constf",
      "scale",
      "addf",
      "subf",
      "negf",
      "mulf",
      "divf",
      "gef",
      "lef",
      "gtf",
      "ltf",
      "minf",
      "maxf",
      "true",
      "false",
      "and",
      "or",
      "not",
      "implies",
      "empty",
      "range",
      "union",
      "diff",
      "intersect",
      "subset",
      "superset",
      "in",
      "equal",
      "notequal",
      "if",
      "defined",
      "select",
      "new",
      "selecta",
      "selectr",
      "storea",
      "storer",
      "notimplies",
      "notimpliedby",
      "impliedby",
      "alltrue",
      "arrayconstruct",
      "arraytrue",
      "emptyobject",
      0};

int yyline = 1;

yylex()
{   static int c = ' ';  /* the "current" character */

    /* get the next lexeme, skipping over spaces and comments.
       return a code indicating the lexeme, and leave c to
       be the character immediately following the lexeme. */

    for (;;)
    {   if (('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z'))
        {   /* identifier or keyword */
#           define max_signif 30  /* > length of longest keyword */
            char identifier[max_signif + 1];
            register char *p = identifier;
            register int id_length = 0;
    
            do 
            {   if (id_length < max_signif)
                {   *p++ = c;
                    id_length += 1;
                }
                c = getsave();
            } while (  ('a' <= c && c <= 'z')
                    || ('A' <= c && c <= 'Z')
                    || ('0' <= c && c <= '9')
                    || (c == '.')
                    || (c == '_')
                    || (c == '~')
		    || (c == '$')
                    );

            *p++ = '\0'; /* mark end of identifier */

            if (c == '!')
            {   int k;
                c = getsave();
                k = lookup(identifier, builtins);
                if (k == -1)
                {   yyerror("unknown builtin");
		    debug1("<unknown builtin>\n");
                    return('@');
                }
                else
                {   debug2("%s!\n" ,identifier);
		    return(Fkeyword + Nkeywords + k);
		}
            }
            else
            {   int k;
                k = lookup(identifier, keywords);
                debug2("%s\n" ,identifier);
                return(k == -1 ? IDENTIFIER : Fkeyword + k);
            }

        }
        else if (c == '(')
        {   c = getsave();
            if (c != '/')
	    {   debug1("(\n");
                return('(');
	    }
            else
            {   /* eat and return a string-- up to next /) */
                c = getsave();    /* eat the slash */
                for(;;)
                {   switch(c)
                    {
                    case '/':
                        c = getsave();
                        if (c == ')')
                        {   c = getsave();
			    debug1("STRING\n");
                            return(STRING);
                        }
                        break;
                                 
                    case EOF:
			yyerror("eof in string");
			break;

                    case '\n':
			for(;;)
			/* eat white space (newlines, comments, spaces,
		         * and tabs).  This code was shoehorned in after
			 * the rest was written, accounting for the duplicated
			 * comment handling code.
			 */
			{   if (c == '\n')
		            {	c = getsave();
				yyline += 1;
		            }
			    else if (c == '-')
		            {   c = getsave();
		                if (c != '-')
			            yyerror("malformed comment"); 
				while(c != '\n' && c != EOF)
				    c = getsave();
			    }
			    else if (c == ' ' || c == '\t')
				c = getsave();
			    else 
			       break;
			}
		
			if (c == '/')
			    c = getsave();
			else 
			{   yyerror("malformed string continuation");
			    debug1("STRING\n");
                            return(STRING);
			}
			break;

                    default:
                        c = getsave();
        }   }   }   }

        else if ('0' <= c && c <= '9')
        {   /* eat and return zero or a counting number */

            if (c == '0')
            {   c = getsave();
                if ('0' <= c && c <= '9')
                    yyerror("leading zero");
                else
                {   debug1("ZERO\n");
		    return(ZERO);
		}
            }
            do c = getsave(); while('0' <= c && c <= '9');
	    debug1("NUMBER\n");
            return(NUMBER);
        }
        else if (c == '-')
        {   c = getsave();
            if (c == '-')
                do c = getsave(); while(c != '\n' && c != EOF);
                /* leaving c as the EOF or newline */
            else 
                return('-');
                /* leaving c the non-minus after the minus */
        }
        else if (c == ' ')
            c = getsave();

        else if (c == '\t')
            c = getsave();

        else if (c == '\n')
        {   c = getsave();
            yyline += 1;
            if (c == ' ' || c == '\n' || c == '\t' || c == '-')
                /* loop around */ {}
            else
	    {   debug1("LINE END\n");
                return(LINE_END);
                /* A newline followed by a - that does not begin
                   a comment is never considered a LINE_END.  This
                   lexical analyzer would not work if statements
                   could begin with a -. */
        }   }
        else
        {   register char save_c = c;
            c = getsave();
	    debug2(c == EOF ? "EOF\n" : "%c\n", save_c);
            return(save_c);
}   }   }

lookup(key, table)
char *key;
char *table[];
{   /* table is an array of strings terminated by a null pointer.
       key is a string.
       search table for key.  If found, return index of key in table.
       If not found, return -1. 
     */

    register char **t, *e, *k;

    /* iterate t through the table */
    t = table;
    while (*t != 0)
    {   /* compare entry pointed to by t with key */
        e = *t;
        k = key;
        while(*k == *e) 
        {   if (*k == 0) return(t - table);
            k += 1;
            e += 1;
        }
        t += 1;
    }
    /* table is exhausted */
    return( -1);
}

/* getsave saves a window on the line it has been reading so that
 * error messages routines can provide some context.  The picture will
 * look like either:
 *
 *  window 
 *    ############0-------------------################0
 *                ^                   ^
 *             finish                start
 *
 *
 *  or:
 *
 *  window 
 *    -------------################0-------------------0
 *                 ^               ^
 *               start           finish
 * Key:
 *    # = good stuff we want to see
 *    - = garbage we don't want to see
 *    0 = a zero
 *
 * start and finish always point into window (and never the final 0)
 * start points to the beginning of the text to print, finish points to
 * a zero that terminates the text.  An empty widow consists of both start
 * and finish pointing to a zero.
 *
 * As getsave reads a character, it puts it at the end of the window.
 * If the window fills up, characters are lost at the beginning.  Newlines
 * are not put in the window, instead the set the flag purge_window, so that
 * the first character after a string of newlines clears the window.
 */

#define window_size 30
static char window[window_size + 1];
            /* we use the fact that window[window_size] is initially zero */
static char *start, *finish;
static int purge_window = 1;  /* causes automatic initialization */

print_window()
{ printf((start <= finish ? "%s" : "%s%s"), start, window);
}

int getsave()
{ int c;
  c = getchar();
  switch(c)
  {
  case EOF:
  case 0:
    break;
  case '\n':
    purge_window = 1;
    break;
  default:
    /* purge the window if so instructed */
    if (purge_window)
    {  start = finish = &(window[0]);
       *finish = '\0';
       purge_window = 0;
    }

    /* Add c to the window queue */
    *finish++ = c;

    if (finish == &(window[window_size]))
      finish = &(window[0]);

    *finish = '\0';

    /* Truncate the beginning if necessary */
    if (finish == start)
    {  start += 1;
	 if (start == &(window[window_size]))
	   start = &(window[0]);
  } } 
  return(c);
}
