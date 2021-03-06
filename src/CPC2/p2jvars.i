procedure WHATjvars; const WHAT = '@(#)p2jvars.i    2.11'; begin SINK := WHAT; end;    { Version 2.11 of 1/2/83 }
{
    Jcode variable declarations
}
{
    assignrecindex  --  assign record number for record type

    Each record type has a unique symbol number, assigned during pass
    one.  For each junit, we assign a corresponding record type number.
    These numbers are used to generate unique identifiers in the Jcode.
    We could use the symbol numbers from pass one, but then the addition
    or deletion of irrelevant symbols in the program would change the
    numbers in Junits not otherwise changed, and the reverification
    optimizer would detect a change and cause reproof of otherwise
    unchanged junits.
}
procedure assignrecindex(v: varnodep);        { node needing number }
begin
    if recindexsearch(v) = 0 then begin        { if search fails }
        with v^ do begin            { using given node }
        if vardata.recordnum = 0 then     { if record lacks record num }
        verybadvarnode(v,210);         { no record number }
        if rectab.rntop >= recindexmax then{ if table overflow }
        verybadvarnode(v,211);        { too many records in unit }
        rectab.rntop := rectab.rntop + 1;    { add to table }
        rectab.rntab[rectab.rntop] := vardata.recordnum; { new entry }
        end;                { With }
        end;                    { search fail }
end {assignrecindex};
{
    genjclass  --  generate variable class in jcode

    Classes are 
        variable
        function
        rulefunction
}
procedure genjclass(v: varnodep);
begin
    with v^ do begin                { using varnode }
    if vardata.form = functiondata then begin { if function }
        assert(blockdata <> nil);        { must have block data }
        if blockdata^.blfnkind = rulefunction then { if rule fn }
        genstring15('rulefunction')    { so note }
        else                { if ordinary function }
        genstring15('function');    { so note }
    end else begin                { if not function }
        genstring15('variable');        { is variable }
        end;
    end;
end {genjclass};
{
    genjtypeonly  --  generate jcode type expression (without class info)
}
procedure genjtypeonly(v: varnodep);        { variable defn entry }
var q: varnodep;                { working pointer }
begin
    assert(v <> nil);                { must exist }
    genchar('(');                { enclose in parentheses }
    with v^ do begin                { using given varnode }
    case vardata.form of            { kinds of data }
    numericdata: begin            { longint and fixed }
        if vardata.scale = 0 then begin    { if longint }
        genstring15('subrange');    { (subrange <min> <max>) }
        genspace;
        geninteger(vardata.minvalue);
        genspace;
        geninteger(vardata.maxvalue);
        end else begin            { if fixed point }
        genstring15('fixed');        { (fixed <min> <max> <scale>) }
        genspace;
        geninteger(vardata.minvalue);
        genspace;
        geninteger(vardata.maxvalue);
        genspace;
        geninteger(vardata.scale);
        end;                { end fixed point }
        end;                { end numeric data }
    setdata: begin                { sets are arrays of boolean }
        genstring15('array');        { (array <index> <elt>) }
        genspace;
        genchar('(');            { begin index type }
        genstring15('subrange');        {***boolean subscripts fail*** }
        genspace;
        geninteger(vardata.minvalue);    { low bound }
        genspace;
        geninteger(vardata.maxvalue);    { high bound }
        genchar(')');            { end index type }
        genspace;                { prepare for elt type }
        genstring15('(boolean)');        { elt is always boolean }
        end;
    recorddata: begin            { record }
        genstring15('record');        { (record <name> <field list>) }
        genspace;
        assignrecindex(v);            {assign record number if needed}
        gentypeid(v);            { name of record type }
        q := down;                { first record component }
        while q <> nil do begin        { for all components }
        genspace;            { space over }
        genchar('(');            { begin field }
                        { construct "type$fieldid" name}
        gentypeid(v);            { name of record type }
        genchar('$');            { construct name }
        genstring15(q^.vardata.itemname); { undecorated name of field }
        genspace;
        genjtypeonly(q);        { type of component }
        genchar(')');            { end field }
        q := q^.right;            { get next component }
        end;                { end component loop }
        end;                { end recorddata }
    arraydata: begin            { array }
        genstring15('array');        { (array <index> <elt>) }
        genspace;
        genchar('(');            { begin index type }
        genstring15('subrange');        {***boolean subscripts fail*** }
        genspace;
        geninteger(vardata.minvalue);    { low bound }
        genspace;
        geninteger(vardata.maxvalue);    { high bound }
        genchar(')');            { end index type }
        genspace;                { prepare for elt type }
        if vardata.minvalue < 0 then begin    { if negative subscript bound }
        usererrorstart(vardata.vrsource); { begin diagnostic }
        write(output,
           'Arrays with negative subscripts are not implemented');
        usererrorend;
        end;
        genjtypeonly(down);            { type of array element }
        end;
    signaldata: begin            { signal }
        assert(false);            { not allowed in jcode }
        end;
    monitordata, moduledata: begin        { static module }
        genstring15('module');        { (module) }
        end;
    proceduredata: begin            { not permitted in jcode }
        assert(false);
        end;
    functiondata: begin            { function (rule fn only ) }
        genstring15('module');        { untyped object }
        end;
    booleandata: begin            { boolean }
         genstring15('boolean');        { (boolean) }
        end;
    fixeddata: begin            { ??? }
        assert(false);            { unimplemented }
        end;
    end { of cases };
    genchar(')');                { finish type expression }
    end;                    { with }
end {genjtypeonly};
{
    genjtype  --  generate (class type) pair
}
procedure genjtype(v: varnodep);
begin
    with v^ do begin                { using given node }
        genchar('(');                { begin (class type) }
        genjclass(v);                { class of variable }
        genspace;
    if vardata.form <> functiondata then begin { if non-function }
        genjtypeonly(v);            { generate data type }
        end else begin                { if function }
        if blockdata^.blfnkind = rulefunction then begin { if rule fn }
        if down^.vardata.form in [numericdata, booleandata] then begin
        case down^.vardata.form of    { fan out on form }
        booleandata: begin         { Boolean }
            genjtypeonly(down);        { generate boolean }
            end;
        numericdata: begin        { numeric data }
            genstring15('(longint)');    { never subrange }
            if down^.vardata.scale <> 0 then begin { if scaled }
            usererrorstart(vardata.vrsource); { diagnose }
            write(output,'RULE function cannot return FIXED');
            usererrorend;
            end;
            end;
            end;            { end cases }
        end else begin            { illegal form of rule fn }
            usererrorstart(vardata.vrsource);    { diagnose }
            write(output,'RULE functions must be Boolean or longint');
            usererrorend;
            end;
          end else begin            { if not rule fn }
            genjtypeonly(down);        { use return value type }
            end;
        end;                { end function }
        genchar(')');                { finish (class type) }
    end;                    { With }
end {genjtype};
{
    genvardecl  --   generate jcode variable declaration
}
procedure genvardecl(v: varnodep);            { variable desired }
begin
    assert(v <> nil);                { must exist }
    assert(isbasevar(v));            { must be base var }
    with v^ do begin                { using given node }
    assert(vardata.form in [numericdata, setdata, recorddata, arraydata,
        moduledata, monitordata,    { modules and monitors }
        functiondata,            { functions }
        booleandata, fixeddata]);    { must be valid type }
    assert(idunique > 0);            { already serialized }
    genname(v);                { name of variable }
    genchar(':');                { : }
    genspace;                { for readablity }
    genjtype(v);                { type of this node }
    genline;                { finish statement }
    end;
end {genvardecl};
{
    genjvars  --  generate declarations for all variables mentioned
              in a given routine

    Variables become visible in a junit for one of three reasons:

    1.  The variable appears in the reference list of the block
    2.  The variable is local to the block
    3.  The variable is a function and is called either directly
        or in the assertions of the block.
}
procedure genjvars(blk: blocknodep);        { which block }
var r: refnodep;                { for scanning ref list }
    vwork: varnodep;                { working variable node }
    uniquer: longint;                { unique generated id }
{
    clearidunique  --  clear idunique field of a variable

    This routine is invoked on all variables by using vardrive.
    Variables are uniquely renumbered for each junit.
}
procedure clearidunique(v: varnodep);        { variable to clear }
begin
    v := basevariable(v);            { get base }
    v^.idunique := 0;                { clear }
end {clearidunique};
{
    declarevar  --  declare one variable in one junit
}
procedure declarevar(v: varnodep);        { variable to declare }
begin
    assert(v = basevariable(v));        { must be base variable }
    with v^ do begin                { using given variable }
    if idunique = 0 then begin        { if not already declared }
        uniquer := uniquer + 1;        { assign new serial number }
        idunique := uniquer;        { give it to variable }
            genvardecl(v);            { generate declaration }
        end;
    end;                    { end With }
end {declarevar};
{
    declarefnsinspecs  --  find function calls in assertions to block
             and declare them as vars
}
procedure declarefnsinspecs(blk: blocknodep);        { block to scan }
begin
    functinexprdrive(blk^.blassertions,@declarevar);    { scan assertions }
end {declarefnsinspecs};
{
    genlocal  -- generate local variable declaration
}
procedure genlocal(v: varnodep);        { candidate var to be generated}
begin
    assert(v <> nil);                { must exist }
    v := basevariable(v);            { get base of variable }
    if localvar(blk, v) then begin        { if local to this block }
    assert(v^.idunique = 0);        { must only be gen once }
    declarevar(v);                { declare it }
    end;                    { end is local }
end {genlocal};
begin {genjvars}
    rectab.rntop := 0;                { clear number conversion tab }
    uniquer := 0;                { clear unique id generator }
    vardrive(@clearidunique);            { clear idunique field of all }
                        { 1. Referenced non-locals }
    r := blk^.blrefs;                { get head of reference list }
    while r <> nil do begin            { for all refs }
    vwork := r^.refvar;            { get variable to test }
    with vwork^ do begin            { using variable }
        case r^.refkind of            { fan out on ref kind }
        setref, useref, initref: begin    { set, use, init }
        if visible(vwork,blk) then     { if visible in this block }
            declarevar(vwork);        { declare it }
        end;
        fcallref: begin            { function call }
        declarefnsinspecs(blockdata);    { 3a. declare vars in specs }
        declarevar(vwork);        { declare it }
        end;
        pcallref: begin            { procedure call }
        declarefnsinspecs(blockdata);    { 3a. declare vars in specs }
        end;
        varref: begin end;            { VAR arg - no action }
        end;                { of cases }
        end;                { end scan }
    r := r^.refnext;            { on to next ref }
    end;
                        { 2. Locals }
    vardrive(@genlocal);                { generate locals }
                        { 3b. Functions from own specs }
    declarefnsinspecs(blk);            { check own block }
end {genjvars};
