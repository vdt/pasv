#include "global.h"

procedure WriteErrorId;
begin
  writeln('error.p 1.5') end;

procedure Abort;
begin
  write ('Internal system error ');
  if CurrentClass = EndFile then
    writeln('vcg [eof]')
  else
    writeln('vcg [', StatementLine:1, '.', CurrentChar, '] ');

  halt end;

procedure SyntaxError;
begin
  writeln('syntax');
  Abort end;
