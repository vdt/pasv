int errcount;

main()
{  errcount = 0;
   yyparse();
   if (errcount) printf("%d syntax errors in jcode\n", errcount);
   exit(errcount < 256 ? errcount : 255);
}

yyerror(s)
char *s;
{  extern int yyline;
   printf("%d: %s near \"", yyline, s);
   print_window();
   printf("\"\n");
   errcount += 1;
}
