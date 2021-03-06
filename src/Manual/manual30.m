.H 1 "Using the verifier"
The
Verifier runs on Digital Equipment Corporation VAX computers
under Berkeley UNIX or Wollongong Eunice/VMS, or
on SUN workstations.
This chapter contains instructions for using the verifier.
.H 2 "Invoking the Verifier"
The Verifier is called using the UNIX command line:
.DP
.ce 1
pasver  [flags] <file>
.DE
This command initiates verification of the Pascal-F program in the named
file.  The file name must end in 
.B ".pf"
indicating that the file is Pascal-F source.
.P
If the
.B "-dvcg"
flag is given, messages will be printed indicating the progress of the
verification, and failed verification conditions will be stored for
examination by the user.
The
.B "-d"
flag enables all internal debugging output, and should be used when
trouble reports are submitted.
.P
The verifier creates, in the current directory, a new directory
for its scratch and history files.  This new directory has the name
of the program being verified, except that the trailing 
.B ".pf"
is
replaced with 
.B "_d"
indicating a directory.
The files in this directory are used to speed up reverifications when
not all the program units of the program have been changed.
The rules associated with the verification are also stored in this directory.
Reverification is omitted for previously-verified program units when
the unit is unchanged and the program unit was successfully verified
in the past.
Reverifications are much faster than original verifications.
.H 2 "Understanding error messages"
The verifier generates error messages during three phases of processing;
syntax checking, preverification checking, and verification.
Samples appear below.
Detection of an error during any phase prevents further phases from
taking place, so only one of the three kinds shown below will appear
as output from any given verification attempt.
.H 3 "Syntax error messages"
.DP

    prog.pf
         4.             IF x < 0 THEN x := 0)
     ****  14                               ^
      14:  ';' expected
    Compilation complete -          1 errors detected
      *** Pass 2 deleted ***
    Pass 1 error abort.

.DE
.P
Syntax checking in the verifier is essentially the same as the
Pascal-F compiler.  This is to be expected, since the first passes
of both are the same.
The messages here are of the same types one would
expect from a compiler.
All messages here indicate errors; there are no ambiguities.
.H 3 "Preverification error messages"
.DP


    Pass 1:
    Pass 2:
    xxx.pf:
       9.      proc1(global1);
    *** Variable "global1" is already used globally by "proc1". ***
    1 error.
    Pass 2 error abort.

.DE
.P
Preverification checking is performed only after the entire program has
been syntax checked, and information about procedures and global objects
has been collected.  This phase is primarily a check for
inconsistencies between definition and use of objects.
In addition, the restrictions necessary to make verification possible are enforced
by this phase, and some common errors which can be caught efficiently in this
phase are diagnosed.
In the example above, there is an aliasing error; the variable
.I global1
is being passed as a
.B VAR
argument to a procedure which uses
.I global1
as a global variable.  This is of course forbidden, since
.I proc1
will not behave as it normally would when a global and formal variable
actually refer to the same location in memory.
.P
One line of the source program is printed with each message
to reduce the need to refer to a printed listing.
.H 3 "Verification error messages"
In general, a message from this phase indicates that the possibility of a
problem exists.
As discussed earlier, a change in the program or the assertions will be
required to eliminate the message.
.P
Each message represents a proof failure along some path between a
previous control point (procedure entry, loop invariant, wait, or
STATE assertion) and the line displayed.  Where more than one path
exists, because of conditional statements, the path being traced out
is described.  This is done by stating the choice made at each
conditional statement on the path.
.P
.DP
    Pass 1:
    Pass 2:
    Pass 3:

    Verifying example6
    Could not prove {example6.pf:18} table1[(j - 1) + 1] = 0
            (ASSERT assertion)
    for path:
        {example6.pf:11} Start of "example6"
        {example6.pf:11} FOR loop exit

    Could not prove {example6.pf:14} allzero(table1,1,i)
            (STATE assertion)
    for path:
        {example6.pf:11} Start of "example6"
        {example6.pf:15} Back to top of FOR loop

    Could not prove {example6.pf:14} allzero(table1,1,i)
            (STATE assertion)
    for path:
        {example6.pf:11} Start of "example6"
        {example6.pf:11} Enter FOR loop

    Could not prove {example6.pf:13} allzero(table1,1,i - 1)
            (ASSERT assertion)
    for path:
        {example6.pf:11} Start of "example6"
        {example6.pf:15} Back to top of FOR loop

    Could not prove {example6.pf:13} allzero(table1,1,i - 1)
        (ASSERT assertion)
    for path:
        {example6.pf:11} Start of "example6"
        {example6.pf:11} Enter FOR loop

    5 errors detected
.DE
The Verifier shows which specific assertion it could not prove,
and for what path through the program proof was unsuccessful.
A listing of the Pascal-F program to which the
above messages refer appears in a later chapter.
.H 2 "How to proceed when a verification fails"
The first attempt at a verification will produce many error messages.
An orderly approach to dealing with these will be helpful.  The messages
may be divided into several classes, as shown below.  Each class should
be eliminated in order.  When new errors appear in a class previously
eliminated, the new errors should be dealt with before continuing work
on the old.
.H 3 "Eliminate the syntax errors"
First, if any syntax errors or preverification error messages are present,
they must be eliminated before the verifier will attempt the verification
phase.  This is straightforward and the messages are usually unambiguous.
.H 3 "Eliminate any definedness problems"
When verification-phase messages appear, the first thing to do
is to look at all messages associated with definedness.
These look like
.DP

.ce
{prog1.pf: 25} Cannot prove "x" is defined.

.DE
Messages like this indicate
that the Verifier could not prove that a variable was initialized at
some point where the value of the variable was used.  All errors
related to definedness should be eliminated before working on further
problems.  Often this will require adding definedness assertions
such as
.DP

.ce
ENTRY DEFINED(x);

.DE
to procedure and function definitions.
Adding an ENTRY condition such as the one above will usually eliminate the
error message for the routine to which it is added, but since it places
a new requirement on every caller to the routine the next verification
attempt may well have new error messages concerning the callers of the routine.
One works outward until the main program is reached.
.P
The user should be aware that
the Verifier generates ENTRY and EXIT definedness assertions internally
for each procedure for each variable referenced (for ENTRY) and set
(for EXIT) in the procedure but not mentioned by the user in the
ENTRY and EXIT assertions.  This convenience feature handles most common
cases, but can be overridden by the user when required by mentioning
the variable in a
.I DEFINED
clause.
This mechanism usually does the right thing for simple variables.
For more complex variables not fully initialized for all calls to the
routine, the user will have to provide entry conditions of his own.
If, for example, at entry to a routine, the array
.I tab
is only expected to be initialized from 1 to
.I x,
one would write an entry assertion of the form
.DP

.ce        
ENTRY DEFINED(tab,1,x);

.DE
.P
A special case is the assignment before use of a global variable or
.B var
argument to a procedure or function.
For example, in
.DP

        procedure p(var x: integer; y: integer);
        BEGIN
            x := 1;
            IF y > 0 THEN x := x + 1;
        END;

.DE
the formal parameter
.I x
seems to be an input and an output variable, since it is both set
and used within
.I p.
Here, an entry condition of the form
.DP

.ce
ENTRY DEFINED(x) = DEFINED(x);

.DE
is required.  This form is essentially meaningless but turns off the built-in
assumption that
.I x
had to be DEFINED at any call to
.I p.
.P
.H 3 "Eliminate the run-time safety errors"
Messages referring to array bounds and variable ranges should be addressed next.
Again, it may be necessary to add ENTRY and EXIT assertions to do this.
It may also be necessary to add terms to STATE invariants.
.H 3 "Eliminate ENTRY errors"
When an error message associated with an ENTRY condition appears,
the message will specify which call to the routine is causing the problem.
First check the ENTRY statement to make sure that the requirement is
what you had in mind; if so, the caller may need work.
.H 3 "Eliminate INVARIANT and EXIT errors"
These refer to the state at the end of a routine.
.H 3 "Work on loop invariants"
This is the really hard job in verification.  Fortunately, when one is
only trying to prove absence of fatal run-time errors, it is not too tough.
A few simple cases cover most situations, of which the following is typical.
.P
.DP
        WHILE parens > 0 DO BEGIN
            printchar(')');
            parens := parens - 1;
            STATE(DEFINED(parens));
            END;
        
.DE
The invariant can go anywhere in the loop but usually placing it at the
end of the loop is more convenient, as in the example below.
.P
.DP
        FOR i := 1 TO 100 DO BEGIN
            tab[i] := 0;
            STATE(DEFINED(tab,1,i));
            END;

.DE
When initializing an array of records, it is usually desirable to write
a procedure which initializes one record in the array through a
.B var
argument, and use that procedure in the initialization loop.  The
record initializing
procedure should have as its
exit condition that the entire
.B var
argument is DEFINED.
.H 3 "Find all hard-to-prove assertions"
Examine the remaining error messages.  Look at each one and ask yourself
``can you convince yourself informally that the assertion is true for that
path at that point, purely by tracing backward along the indicated path and
looking at the statements there?''.  If not, the program or the assertions
need work.  If so, defer working on that assertion until all the assertions
that need work have been dealt with.  Once all the easy assertions are out
of the way, it is time to deal with the hard ones.
.P
The Verifier can prove, without assistance, assertions that are true
because of properties of addition, subtraction, multiplication by
explicit constants, the relational operators,
the Boolean connectives, and storing into and
referencing arrays and records.  This takes care of about 90-95% of all
verification conditions.  Beyond this point,
the Verifier needs help.
.P
Help is provided by adding ASSERT statements to the program and by adding
.I rules
to the rule database.
Whenever an ASSERT statement is placed in a Pascal-F program, the Verifier
will try to prove that it holds.  For any statement after the ASSERT
statement in the program, the assertion will be assumed true.
Hard assertions should be preceded by an easy assertion
or assertions
(ones that
the Verifier can prove) which imply the hard assertion by some
formal argument the Verifier doesn't yet know about.  This argument should
be something that depends only on the ASSERT statement and the following
hard assertion.  It will then be necessary to prove that argument as a rule.
Proving rules is done with the Rule Builder as a separate job; when
working on the program, all the hard assertions should be found and
preceded with an easy assertion, until the entire verification is
a success except for the errors from hard assertion preceded by easy
ones.  Then it is time to go to the Rule Builder, and probably to
the resident Rule Builder expert.
.P
An example is indicated.
.DP

    FOR i := 1 TO 100 DO BEGIN
        table1[i] := 0;
        assert(table1[i] = 0);
        assert(allzero(table1,1,i-1));
        STATE(allzero(table1,1,i));
        END;
.DE
In this example, the STATE assertion is hard to prove.  But if we
add the two ASSERT statements, both of which the Verifier can prove
without much trouble, we could certainly argue that this makes it obvious
that the STATE assertion is sound.  If we had a rule that said
.DS

            a[i] = 0 and allzero(a,1,i-1)
        implies
            allzero(a,1,i)

.DE
the Verifier would apply the rule and prove the assertion.  So we now
know exactly what rule we need, and can prove it with the Rule Builder.
.H 3 "Completing the debugging"
With this sequential approach to debugging a verification, the rather
forbidding prospect of eliminating all those error messages is somewhat
less intimidating.  Note, though, that no sound statement can be made
about the program until
.I every
error message has been eliminated.  One false assertion can cause
any number of other problems to be hidden.
As an example,
writing
.DP

.ce
ENTRY false;

.DE
will eliminate all error messages for any routine, but will cause any caller
of the routine to fail.  (It is an interesting property of the Verifier
that unreachable code need not work!).
The same problem can be induced by accident;
for example
.DP

.ce
ENTRY (x < 0) and (x > 100);

.DE
is essentially equivalent to the previous statement, since no number
can satisfy both constraints.  Thus, until
.I all
error messages have been eliminated, the verification is unsuccessful.

