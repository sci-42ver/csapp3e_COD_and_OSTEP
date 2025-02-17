/*%option header-file="lex.yy.h"*/
/*
compile: flex snazzle.l;bison -d snazzle.y;g++ snazzle.tab.c lex.yy.c
https://stackoverflow.com/a/57061573/21294350
*/
%option noyywrap
%{
  #include <cstdio>

  #include "snazzle.tab.h"  // to get the token types from Bison

%}
%%
[ \t\n]           ;
[0-9]+\.[0-9]+    { yylval.fval = atof(yytext); return FLOAT; }
[0-9]+            { yylval.ival = atoi(yytext); return INT; }
[a-zA-Z0-9]+      {
  // We have to strdup yytext because Flex will change it for the next token.
  // Note that this memory must be freed somewhere, so that's why we call
  // free() above in the Bison section.  (Aside: we use free() instead of
  // delete because strdup is a C function that uses malloc, not a C++
  // function that uses new.)
  yylval.sval = strdup(yytext);
  printf("get str %s copyed to %s\n", yytext,yylval.sval);
  return STRING;
}
%%

