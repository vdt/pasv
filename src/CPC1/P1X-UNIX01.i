{
	UNIX-only type definitions

	Used for both verifier and compiler
}
{
	filestate  --  state of a source file
}
filestate = (unopened, opened);           
{
	filename   --  name string for a file
}
pathname = array [1..pathnamemax] of char;
{
	fileitem  --  one for each source file being read
}
fileitem = record
	infile: text;			{ the file itself }
	fname: pathname;		{ file name string }
	linenumber: longint;		{ current position in file }
	filenumber: longint;		{ serial of this file }
	state: filestate;		{ state of this file }
	end;
