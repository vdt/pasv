procedure WHATdump; const WHAT = '@(#)p2dump.i    2.1'; begin SINK := WHAT; end;    { Version 2.1 of 10/12/82 }
{
    Dumping routines for various structures

    Debug use only.
}
{
    dumpsubvar  --  print description of one variable
}
procedure dumpsubvar(var f: text; p: varnodep; dir: char; depth: longint;
        siblings: boolean);        { print siblings? }
begin
    if p <> nil then                 { if node exists }
    with p^ do begin                { for the given node }
    if depth > 0 then            { if depth info wanted }
        write(f,depth:1,dir,'   ');        { how we got here }
    write(f,
    ' ':vardata.itemdepth,' ':vardata.itemdepth,    { indentation }  
    vardata.itemdepth:2, ' ',vardata.itemname,
    ' {',
    vardata.vrsource.filenumber:1, ':', vardata.vrsource.linenumber:1,
    '}',                    { line number }
    ' (',vardata.loc.relocation:1);
    if vardata.loc.relocation in [stackaddr, paramaddr, routineaddr] then
        write(f,'[',vardata.loc.blockn:1,']');
    write(f,',',vardata.loc.address:1,': ',vardata.size:1,' bits) ');
    if vardata.form in [numericdata, arraydata, setdata] then begin
        write(f,vardata.minvalue:1,'..',vardata.maxvalue:1);
        if vardata.scale <> 0 then write(f,'/',vardata.scale:1);
         write(f,' ');
    end;
        if vardata.form <> numericdata then write(f,vardata.form,' ');
        if vardata.recordname[1] <> ' ' then 
        write(f,vardata.recordname,' ');
        if vardata.by <> bynothing then write(f,vardata.by);
    writeln(f);
    dumpsubvar(f,down,' ',depth,true);    { print children }
    if siblings then dumpsubvar(f,right,' ',depth,true); { print sibling }
    end;                    { of with }
end {dumpsubvar};
{
    printvar  --  print variable
}
procedure printvar(var f: text; p: varnodep);
begin
    if p = nil then                { note nil }
    writeln(f, '  NOT NAMED VARIABLE')    { diagnose }
    else
        dumpsubvar(f, p, ' ', 0, false);    { dump of single var }
end {printvar};
{
    dumpallvars  --  dump all variable nodes
}
procedure dumpallvars(var f: text);        { dump onto indicated file }
{
    dumpvars  --  debugging aid to dump the variable tree 
}
procedure dumpvars(p: varnodep; dir: char; depth: longint);
begin
    if p <> nil then                 { if node exists }
    with p^ do begin                { for the given node }
    dumpvars(lesser,'<',depth+1);        { dump alpha tree }
    dumpsubvar(f,p,dir,depth, true);    { dump this var }
        dumpvars(greater,'>',depth+1);        { dump alpha tree }
    end;                    { of with }
end {dumpvars};
begin {dumpallvars} 
    writeln(f,'Variable Tree Dump');
    dumpvars(vartree^.lesser,'<',0);    { dump left half of tree }
    dumpvars(vartree^.greater,'>',0);    { dump right half of tree }
    writeln(f);
end {dumpallvars};
{
    dumpblocknode  --  dump information in block node

    A debug aid only.
}
procedure dumpblocknode(b: blocknodep);    { block to dump }
var warg: varnodep;            { working varnode }
begin
    with b^ do begin            { using given node }
    write(dbg,'Block summary for "');
    writestring15(dbg,blvarnode^.vardata.itemname); { name of block }
    writeln(dbg,'"');
    write(dbg,'   Block ',blpin:1,':  Scope level ',blscopedepth:1,
             ', block level ', blblockdepth:1);
    if blouterblock <> nil then  begin    { if not outermost block }
        write(dbg,'   (Inside "');
        writestring15(dbg,blouterblock^.blvarnode^.vardata.itemname);
        write(dbg,'")');
        end;
    writeln(dbg);
    write(dbg,'   Priority: ',blpriority:1);    
    write(dbg,'   Flags: ');        { edit various flags }
    if blrecursive then write(dbg,' (recursive)');
    if blhasbody then write(dbg, ' (has body)');
    if blhasoutputvararg then write(dbg, ' (has output VAR)');
    if bldoeswait then write(dbg, ' (does WAIT)');
    if bldoessend then write(dbg, ' (does SEND)');
    if bldoesdevio then write(dbg, ' (does I/O)');
    write(dbg,' (',blfnkind,')');
    write(dbg,' (unit type ',blunittype:1,')');
    writeln(dbg);            { end flags line }
    writeln(dbg, '   Sizes in bits: ',
        bldsize:8,' (data)  ',
        blpsize:8,' (params)',
        bllsize:8,' (locals)');
    warg := blvarnode^.down;        { get arg list }
    writeln(dbg,'   Formal argument list:');
    if warg = nil then writeln(dbg,'        [NONE]');
    while warg <> nil do begin        { dump all vars }
        write(dbg,'        ');        { indent variable }
        printvar(dbg, warg);        { print each formal }
        warg := warg^.right;        { get next formal }
        end;
    if blrsize <> 0 then 
        writeln(dbg,'   Function value size: ',blrsize, ' bits.');
    writeln(dbg);                { blank line }
    end;
end {dumpblocknode};
{
    dumprefs  --  dump reference list for procedure
}
procedure dumprefs(var f: text;            { output file }
           v: blocknodep);        { routine for dump }
var r: refnodep;                { working pointer }
    cl: callnodep;                { working call node pointer }
    vr: varnodep;                { formal arg pointer }
    ar: argnodep;                { arg node pointer }
    vararg: varnodep;                { VAR arg data item }  
begin
    writeln(f);
    write(f,'Reference summary for block ''');
    writeblockname(f, v);            { name of block }
    writeln(f,'''');                { finish line }
    writeln(f,'  Set/Used information: ');
    r := v^.blrefs;                { get first ref }
    if r = nil then writeln(f,'    [NONE]');    { no set/used info message }
    while r <> nil do with r^ do begin        { for all refs }
        write(f,'     ',refvar^.vardata.itemname); { name of variable }
    write(f,'   (');
    if refmention = transitivemention then write(f,'transitive');
    write(f,refkind,')');             { what }
    if refformal <> nil then begin        { if formal }
        write(f,'  Passed by reference to formal arg ',
        refformal^.vardata.itemname);
        end;
    writeln(f);
    r := r^.refnext;            { chain forward }
    end;
    writeln(f, '  Callers: ');            { print list of callers }
    cl := v^.blcallers;                { start call list }
    if cl = nil then writeln(f,'    [NONE]');    { no callers message }
    while cl <> nil do begin            { for all caller nodes }
    write(f,'    ');
    writeblockname(f, cl^.clblock);        { name of calling block }
    writeln(f);                { finish line }
    cl := cl^.clnext;            { on to next ref }
    end;
    writeln(f,'  Formal param correspondences:');
    vr := v^.blvarnode^.down;            { first formal if any }
    if vr = nil then writeln(f,'    [NONE]');    { no params message }
        while vr <> nil do begin        { for all formals }
        if vr^.vardata.by = byreference then begin { if VAR arg }
        vararg := vr^.down;        { skip over pointer }
                write(f,'    ');        { indent }
            writestring15(f, vararg^.vardata.itemname);{ name of formal }
            write(f,':');            { begin actual list }
            ar := vararg^.actuallist;    { get list head }
            if ar = nil then write(f,' [NONE]'); { note useless param }
            while ar <> nil do begin    { for all actuals }
            write(f,' ');        { space before actual }
             writestring15(f, ar^.aractual^.vardata.itemname);{print it }
            ar := ar^.arnext;        { on to next actual }
            end;
            writeln(f);            { finish line for one arg }
        end;                { end is VAR arg }
        vr := vr^.right;            { get next formal arg }
        end;                { end formal loop }
    writeln(f);                { extra blank line at end }
end {dumprefs};
{
    dumpallrefs  --  perform dump for all routines in dictionary
}
procedure dumpallrefs(var f: text);        { output file }
var v: blocknodep;                { working block }
begin
    writeln(f);
    writeln(f,'Full Reference Lists');
    v := blockhead;                { get first block }
    while v <> nil do begin            { for all nodes }
    dumprefs(f,v);                { dump for this routine }
    v := v^.blnext;                { on to next routine }
    end;
end {dumpallrefs};
{
    dumptemptab  -- TEMP information dumper
}
procedure dumptemptab(p: ptn;            { call node }
              var tinfo: temptab);    { TEMP table - read only }
var i: 1..temptabmax;                { for loop }
begin
    if isfunction(p^.vtype) then 
    write(dbg,'Function')
    else write(dbg,'Procedure');
    writeln(dbg,' call summary');
    writeln(dbg,'    Caller: ',lastblockp^.blvarnode^.vardata.itemname);
    writeln(dbg,'    Callee: ',p^.vtype^.vardata.itemname);
    writeln(dbg);
    writeln(dbg,'    TEMP table');
    if tinfo.tttop = 0 then writeln(dbg,'        [EMPTY]');
    for i := 1 to tinfo.tttop do begin        { for all in temp table }
    with tinfo.tttab[i] do begin        { using TEMP item }
        writeln(dbg,i:8,'.   TEMP',tenum:1,'    ',tevarnode^.vardata.
        itemname,'    (',tekind,')');
        end;
    end;
    writeln(dbg);
end {dumptemptab};
{
    dumpvarownership  --  dump variable ownership data
}
procedure dumpvarownership(var f: text);    { output file }
{
    dumpvarowner  --  dump ownership data for one variable
}
procedure dumpvarowner(v: varnodep);
begin
    write(f,' ':8,v^.vardata.itemname,' ':4);
    if v^.varblock = nil then write(f,'[NONE]         ':15)
             else write(f,v^.varblock^.blvarnode^.vardata.itemname);
    write(f,' ':4);
    if v^.varmaster = nil then write(f,'[NONE]         ':15)
            else write(f,v^.varmaster^.blvarnode^.vardata.itemname);
    if v^.blockdata <> nil then begin
    if v^.blockdata^.bldominator = nil then write(f,'[NONE]')
      else write(f,v^.blockdata^.bldominator^.blvarnode^.vardata.itemname);
    end;
    writeln(f);
end {dumpvarowner}; 
begin {dumpvarownership}
    writeln(f,' ':8,'Variable       ':15,' ':4,'Block          ':15,
        ' ':4,'Master         ':15,'Dominator');
    writeln(f);
    vardrive(@dumpvarowner);
    writeln(f);
end {dumpvarownership};
{
    dumpall  --  dump all permanent info 
}
procedure dumpall(var f: text);                { output file for dump }
begin
    dumpvarownership(f);                { variable owners }
    dumpallrefs(f);                    { full ref lists }
end {dumpall};
{
    dumpfatal  --  dump everything
}
procedure dumpfatal;
begin
    if debugg and (not fatalerror) then begin        { if debugging on }
    fatalerror := true;                { avoid dump loop }
    writeln(dbg);
        writeln(dbg,'=======================================================');
    writeln(dbg,'=============   PASS II FATAL ERROR DUMP  =============');
        writeln(dbg,'=======================================================');
    writeln(dbg);
    dumpallvars(dbg);
    dumpvarownership(dbg);
    dumpallrefs(dbg);            { reference info }
    writeln(dbg,'Current Icode Tree');
    treeprint(tree,0);            { icode tree }
    writeln(dbg);
    end;
end {dumpfatal};
