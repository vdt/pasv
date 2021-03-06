.H 2 "Circular buffering routines"
This simple example shows a common program component; a set of circular
buffering routines.  Here the Verifier has been used to show 
absence of run-time errors and the maintenance of a
``sanity invariant'' which if violated would indicate that the various
pointers were out of synchronism.
.P
The main program here is a dummy one; the object here is to verify the
subroutines.
.DP
program circle;
{
        Circular Buffering Module        Version 1.9 of 1/5/83
}
monitor circlebuf priority 5;
exports bufget, bufput;
const bufsize = 20;
type  bufindex = 1..20;                 { position in buffer }
      bufarray = array [bufindex] of char;
      buffer = record                   { buffer structure }
        bufin: bufindex;                { next position to insert }
        bufout: bufindex;               { next position to read }
        bufcount: 0..bufsize;           { chars in buffer }
        buf: bufarray;                  { the buffer itself }
        end;
var b: buffer;                          { the buffer }
invariant defined(b);                   { the buffer is always defined }
                                        { buffer sanity }
        ((b.bufout + b.bufcount) = b.bufin)
        or
        ((b.bufout + b.bufcount - bufsize) = b.bufin);
{
        bufput  --  put in buffer
}
function bufput(ch: char)               { char to insert }
                : boolean;              { returns true if insert OK }
begin
    if b.bufcount < bufsize then begin  { if buffer not full }
        b.bufcount := b.bufcount + 1;   { increment buffer count }
        b.buf[b.bufin] := ch;           { store char in buffer }
        assert(defined(b.buf,1,bufsize));{ array still defined }
        if b.bufin = bufsize then       { if at max }
            b.bufin := 1                { reset to start }
        else b.bufin := b.bufin + 1;    { otherwise increment }
        bufput := true;                 { success }
    end else begin                      { if full }
        bufput := false;                { insert fails }
        end;
end {bufput};

.DE
.DP

{
        bufget  --  get from buffer
}
function bufget(var ch: char)           { char returned }
        : boolean;                      { true if successful }
exit return implies defined(ch);        { char only if not empty }
begin
    if b.bufcount > 0 then begin        { if buffer not empty }
        b.bufcount := b.bufcount - 1;   { decrement buffer count }
        assert(defined(b));             { still all defined }
        ch := b.buf[b.bufout];          { get char from buffer }
        if b.bufout = bufsize then      { if at max }
            b.bufout := 1               { reset to start }
        else b.bufout := b.bufout + 1;  { otherwise increment }
        bufget := true;                 { success }
    end else bufget := false;           { fails if empty }
end {bufget};

.DE
.DP

{
        buffer initialization block
}
var i: bufindex;
begin
    for i := 1 to 20 do begin           { clear to spaces }
        b.buf[i] := ' '; 
        assert(defined(b.buf,1,i-1));   { still defined up to i-1 }
        state(defined(i),
              defined(b.buf,1,i));
        end;
    b.bufout := 1;                      { start at 1 }
    b.bufin := 1;                       { end at 1 }
    b.bufcount := 0;                    { length 0 }
end {circlebuf};
var stat: boolean;                      { status from routines above }
    ch: char;                           { working char }
begin {main}
    init circlebuf;
    stat := bufput('x');
    stat := bufget(ch);                 { get a char }
    if stat then begin                  { if we got a char }
        end;
end.
.DE
.P
The Verifier can verify these routines in about
four minutes.  This verification does require rules, but all the rules
needed are in the Rule Builder's standard database.
.DP
    
    Verifying circle 
    No errors detected
    
    Verifying circlebuf 
    No errors detected
    
    Verifying circlebuf-bufget 
    No errors detected
    
    Verifying circlebuf-bufput 
    No errors detected
    
.DE
