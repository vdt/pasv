procedure WHATtrinvar; const WHAT = '@(#)p2trinvar.i    2.1'; begin SINK := WHAT; end;    { Version 2.1 of 10/12/82 }
{
    Module and Monitor Invariant Relevance Processing

    Relevant invariants of modules are made invariants of the
    procedures that need them.
}
{
    relevancetest  --  determine if invariant is relevant to routine
               in indicated sense.
}
function relevancetest(p: ptn;            { invariant expression }
            b: blocknodep;        { routine block }
            s: setofreflistkind)    { kinds of access relevant }
            : boolean;        { true if relevant }
var relevant: boolean;                { relevance working flag }
{
    relevance1  --  is single variable relevant?
            Output through global flag, so search is skipped
            if previous variable is relevant.
}
procedure relevance1(v: varnodep);        { variable to test }
var r: refnodep;                { working ref node }
begin
    r := b^.blrefs;                { get head of ref chain }
    while (not relevant) and (r <> nil) do begin{ search ref chain }
    if r^.refvar = v then             { if correct var }
        if r^.refkind in s then         { if wanted kind of ref }
        relevant := true;    { note if relevant }
    r := r^.refnext;            { continue search }
    end;
end {relevance1};
begin {relevancetest}
    relevant := false;                { assume not relevant }
    varinexprdrive(p, @relevance1);        { examine all variables }
    relevancetest := relevant;            { return result }
end {relevancetest};
{
    addvarrefs  --  add variables referenced in expr to ref list of
            routine, and note if added.
}
procedure addvarrefs(p: ptn;            { expression to add }
             blk: blocknodep;        { block to add to }
             var added: boolean);    { true if added to }
{
    addvarref1  --  add variable referenced to list, if needed
}
procedure addvarref1(v: varnodep);        { relevant variable }
begin
                        { try adding the reference }
    if addref(blk,v,useref,nil, transitivemention) then begin    
    added := true;                { if not duplicate, note }
    end;
end {addvarref1};
begin {addvarrefs}
    varinexprdrive(p,@addvarref1);        { examine all variables }
end {addvarrefs};
{
    addinvarrel  --  add the variables for all relevant invariants to the
             list of referenced variables for the given block
}
procedure addinvarrel(blk: blocknodep;        { block being processed }
              var added: boolean);    { true if added new item }
{
    addinvar  --  add invariant to relevant invariants of routine, adding
              to input variable list if necessary.
              We are always adding an invariant of a module/monitor 
              to the list of a routine.
              It is assumed that the invariant to be added is not
              already an invariant of blk.
}
procedure addinvar(p: ptn);            { invariant to be added }
begin
    addvarrefs(p^.arg[1],blk,added);        { update variable ref list }
    addstmt(blk^.blassertions,p);        { add invariant to assertions }
end {addinvar};
{
    tryinvar  --  test relevance of invariants and add if relevant
}
procedure tryinvar(p: ptn);            { invariant to examine }
var rel: boolean;                { true if relevant }
begin {addinvar}
    with p^ do begin                { using given node }
    assert(code = vdeclop);            { must be vdecl }
    if disp = invariantsubcode then begin    { if invariant }
        rel := relevancetest(p^.arg[1],blk,[setref, useref]);{ if relevant }
        if debugg then begin        { debugging info }
        write(dbg,'      Invariant {',p^.linen.linenumber:1,'}');
        if not rel then write(dbg,' not'); { not if not relevant }
        write(dbg,' relevant');
        end;
        if rel then begin             { if relevant }
                        { check for duplicate }
        if ispresent(blk^.blassertions,p) then begin 
            if debugg then write(dbg,' but already present');
        end else begin            { if not duplicate }
            addinvar(p);        { add to block }
            end;
        end;                { end relevant }
        if debugg then writeln(dbg,'.');    { finish debug }
        end;                { end is invariant }
    end;                    { With }
end {tryinvar};
{
    invarcross  --  called for each block boundary crossed between
            the dominator of the calls and the callee.
            Examines all invariants of the crossed block
            to see if they should be made invariants of the
            called routine.
}
procedure invarcross(b: blocknodep);        { boundary crossed }
begin
    if debugg then            { debug print }
    writeln(dbg,'    Invariants from block ',
    b^.blvarnode^.vardata.itemname);
    seqdrive(b^.blassertions,@tryinvar); { examine all invariants }
end {invarcross};
begin {addinvarrel}
    case blk^.blvarnode^.vardata.form of    { fan out on kind of block }
    proceduredata, functiondata: begin         { procedure or function }
    if debugg then
         writeln(dbg,'  For routine ',blk^.blvarnode^.vardata.itemname);
    blockcrossdrive(blk,blk^.bldominator,@invarcross); { handle crosses }
    end;
    moduledata, monitordata: begin        { monitor or module }
    end;                    { end monitor/module }
    programdata: begin                { main program }
    end;                    { end main program, no action }
    end;                    { of cases }
end {addinvarrel};
{
    relevantinvars  --  perform addinvarrel for all routines.
}
procedure relevantinvars;
var b: blocknodep;                { working block }
    newvar: boolean;                { true if new var added }
begin
    if debugg then writeln(dbg,'Invariant relevance summary');
    b := blockhead;                { get first block }
    while b <> nil do begin            { for all blocks }
    repeat                    { brute-force closure }
        newvar := false;            { no new vars added }
        addinvarrel(b,newvar);        { examine invariants }
        until not newvar;            { repeat until no change }
    b := b^.blnext;                { on to next block }
    end;
    if debugg then writeln(dbg);
end {relevantinvars};
