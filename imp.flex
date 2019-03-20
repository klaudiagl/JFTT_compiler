%option yylineno

%{

#include "imp.tab.h"
#define YYERROR_VERBOSE    

int yylex();

void errorPrinter(char * c) 
{
    printf("Linia %d: %s\nv", yylineno, c);
}

void yyerror(char *errMessage)
{
    errorPrinter(errMessage);
}

%}

NUMBER      [0-9]+
WHITESPACE	[ \t\n\r]+
COMMENT     \[([^\]]|{WHITESPACE})*\]

%%
{WHITESPACE}   {}
{COMMENT}     {}
DECLARE     return DECLARE;
IN          return IN;
END         return END;
IF          return IF;
THEN        return THEN;
ELSE        return ELSE;
ENDIF       return ENDIF;
WHILE       return WHILE;
DO          return DO;
ENDWHILE    return ENDWHILE;
ENDDO       return ENDDO;
FOR         return FOR;
FROM        return FROM;
TO          return TO;
ENDFOR      return ENDFOR;
DOWNTO      return DOWNTO;
READ        return READ;
WRITE       return WRITE;
"+"         return ADD;
"-"         return SUB;
"*"         return MUL;
"/"         return DIV;
"%"         return MOD;
"="         return EQ;
":="        return ASS;
"!="        return NEQ;
"<"         return LT;
">"         return GT;
"<="        return LEQ;
">="        return GEQ;
";"         return SEM;
":"         return RANGE;
"("         return LBRACE;
")"         return RBRACE;
[_a-z]+     {
                yylval.string=(char *)strdup(yytext);  
                return ID;
            }
{NUMBER}    {
                yylval.number = atoi(yytext);         
                return NUM;}
.           {
                errorPrinter("Nierozpoznany format\n");
            }

%%