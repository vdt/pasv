{
	Type definitions used by verifier.

	These definitions are part of both pass 1 and pass 2.

	Definitions here must not depend upon types or constants
	unique to any pass.
}
{
	targetnumber -- target machine number

	This must be large enough to represent the largest numeric type,
	which in this case is the fixed-point type.
}
targetnumber = targetnumbermin..targetnumbermax; { 4-byte numbers }
{
	targetprecision - range of target machine precisions
}
targetprecision = precisionmin..precisionmax;
{
	identifier  --  compiler identifier
}
identifier = packed array [1..identifiermax] of char;
{
	Kinds of addresses
}
addressclass = (absoluteaddr,stackaddr,deviceaddr,paramaddr,offsetaddr,
	signaladdr,routineaddr,valueaddr,pointeraddr);
{
	blocknumber  --   number of static block for VARBL interpretation
}
blocknumber = 0..blockmax;
{
	sourcelinenumber   --   line number in sourceline file
}
sourcelinenumber = 0..linemax;
{
	symbolnumber  --  serial number of symbol, variable, etc.
}
symbolnumber = 0..symbolmax;
{
	lineinfo  --  where source line came from
}
lineinfo = record
	filenumber: 0..filesmax;	{ which source file }
	linenumber: 0..linemax;		{ which line }
	end;
{
	source line with line number

	When the source input is composed of multiple files, the
	line number stored in the file is used to identify the
	source line in terms meaningful to the user.
}
sourceline = record
	lineid: lineinfo;		{ identity of source line }
	linetext: array [1..linetextmax] of char; { text of source line }
	end;
{
	Kinds of data
}
datakind = (numericdata,setdata,recorddata,arraydata,signaldata,
	    booleandata, fixeddata, pointerdata, 
	    proceduredata, functiondata,
	    monitordata, moduledata, programdata);
{
	Kinds of parameters
}
paramkind = (bynothing, byactualvalue, byreference);
{
	bitaddress   --  address or offset in memory in BITS
}
bitaddress = addressmin..addressmax;		{ offsets may be negative }
{
	addressitem  --  this triple defines an address in memory 

	All address and size information is in BITS.
}
addressitem = record				{ address in memory }
	address: addressmin..addressmax;	{ address or offset }
	blockn: blocknumber;   			{ in which block }     
	relocation: addressclass;		{ relative to what } 
	end;
{
	vitemdepth  --  depth into variable definition item
}
vitemdepth = 0..itemmax;			{ limits struct complexity }
{
	varitem  --  variable definition item

	Type definitions are after the manner of COBOL.  Every variable
	has its own type definition, which follows the variable definition.
	The top level of a definition has an item level of 1.  This 
	identifies a variable.  Variable items may be immediately followed
	by field items, which have itemlevel values greater than 1.  
	
	For the purposes of discussion, items with itemlevel=1 will be
	referred to as variable items.  Items with itemlevel>1 will be
	referred to as field items.  (Itemlevel=0 indicates an open slot.)
	Any item is said to own all following items up to the next item
	of equal or lesser itemvalue.  Thus, an itemvalue=1 item owns all
	following items of level 2..n until the next itemlevel=1, or
	variable, item.  In turn, a level 2 item owns following level 3..n     
	items.  

	An item with no following items of greater itemlevel describes
	a variable or field of simple type.     
	Such items are referred to as primitive items.  An item may be
	both a primitive item and a variable item; such an item describes
	a single variable declared with a simple type.

	For all items, the fields loc, size, itemlevel, and formt are
	meaningful.  All addresses and sizes are in bits.  Fields may
	not overlap.  Variables may not overlap.  Excess space (filler)
	is allowed.  The address and size of any item must contain the
	space of all following items belonging to the instant item.
	For variable items (itemlevel=1) the address in loc is the
	actual address.  For field items (itemlevel>1) the address is
	the offset from the previous item of lesser itemlevel.
	It is often useful to think of variable items as being offset
	from the begininng of memory or from the top of the icode
	execution stack, or from the procedure parameter area, as
	appropriate.

	For primitive items, the fields minvalue and maxvalue are
	meaningful, as is precision.  For integers, precision is
	0.  Characters, booleans, integers, and fixed-point numbers
	are treated uniformly, although the actual type is given in
	form.

	The primary purpose of this notation is to allow rapid lookup
	by address and to allow determination of the type of a 
	field when dereferencing a variable.  The notation is intended
	to be written into a sequential file for use in later passes.
}


varitem = record				{ variable or type part }
	itemdepth: vitemdepth; 			{ depth into var definition }
	form: datakind;				{ kind of variable or field }
	by: paramkind;				{ kind of parameter if param }
	loc: addressitem;			{ which variable }
	size: 0..addressmax;			{ size in bits }
	itemname: identifier;			{ name of variable }
	recordname: identifier;			{ name of record type if record}
	recordnum: symbolnumber;		{ serial number of type decl }
	minvalue: targetnumber;			{ low limit of value }
	maxvalue: targetnumber;			{ high value }
	scale: targetprecision;			{ scale factor (2**n) for value}
	vrsource: lineinfo;			{ source line of declaration }
	end;
