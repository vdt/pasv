/* lisp command interface

   Prepend the line:

   #! <pathname>

   where <pathname> is a complete pathname to this program,
   to a lisp program.  Change the mode of the lisp program to
   so that it is executable, and the file will be executed directly
   by the shell, in much the same way shell scripts are.
*/
    
char what_string[] = "@(#)execlisp.c	1.2";

main(argc, argv)
int argc;
char *argv[];

{  int fd;  /* file descriptor */
   int j;   /* loop counter */
   char c;  /* character buffer */

   /* argv[1] is the file to be executed.  Open the file and
    * discard the first line of the file, which directed exec
    * to this program (since lisp will not know what to do with it).
    */
   fd = open(argv[1], 0);
   check(fd, "open");
   do
      check(read(fd, &c, 1), "read");
   while (c != '\n');

   close(0);
   check(dup(fd), "dup");

   /* delete argv[1] from the argument list */
   for(j=1; j+1<argc; j++) argv[j] = argv[j+1];
   argv[j] = 0;

   /* exec the lisp on the command file */
   check(execv("/usr/ucb/lisp", argv), "exec");
}

check(retcode, msg)
int retcode;
char *msg;
{ if (retcode ==  -1)
  {  perror(msg);
     exit(1);
} }
