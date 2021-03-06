/*
	pager  --  break printout into pages

	Printouts are broken into pages every 66 lines.
	A form feed is added at the beginning of each page
	after the first.

					Version 1.1 of 1/6/83
*/
#include <stdio.h>
int line = 0;					/* current line number */
int needff = 0;					/* FF needed */
int needlf = 0;					/* LFs needed */
char ch;
#define FF 014					/* form feed */
#define PAGESIZE 66				/* lines per page */
main()
{    for (;;) 
     {  ch = getchar();				/* get next char */
	if (ch == EOF) break;			/* done */
	if (ch == '\n')				/* if newline */
	{   line++;				/* count lines */
	    needlf++;				/* add to LFs needed */
	    if (line >= PAGESIZE)		/* if page end reached */
	    {   needff = 1; 
		line = 0;
		needlf = 0;	
	    }					/* set FF, no LF */
	    continue;				/* on to next char */
        }
	if (needff)				/* if form feed needed */
	{   putchar('\n');
	    putchar(FF); 
	    needff = 0; 
	} 					/* handle it */
	while (needlf) 				/* while LFs needed */
	{   putchar('\n');			/* LF */
	    needlf--;				/* decrement */
	}
	putchar(ch);				/* finally put out char */
    }
}
