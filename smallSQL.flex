/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                         *
 *  jFlex file to add additional functionality to the SmallSQL program     *
 *                                                                         *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

%%

%byaccj

%{
	private Parser yyparser;

	public Yylex( java.io.Reader r, Parser yyparser )
	{
		this(r);
		this.yyparser = yyparser;
	}
%}

NUM		= ([0-9]+"."([0-9]*)?)|("."[0-9]+)|([0-9]+)
STR		= \"[^\"]*\"
NL		= \n | \r | \r\n
SYMBOL	= [a-zA-Z][a-zA-Z0-9_]*
PRINT	= [pP][rR][iI][nN][tT]
SET		= [sS][eE][Tt]
EVAL	= [eE][vV][aA][lL]
SETINST	= [sS][eE][Tt][iI][nN][sS][tT]
SYMTAB	= [sS][yY][mM][tT][aA][bB]
DELETE	= [dD][eE][lL][eE][tT][eE]
CLEAR	= [cC][lL][eE][aA][rR]
OR		= ([oO][rR]) | "||"
AND		= ([aA][nN][dD]) | "&&"
NEQ		= "!=" | "<>"
LEQ		= "<="
GTE		= ">="

%%

/* operators */
{NEQ}		{ return Parser.NEQ; }
{LEQ}		{ return Parser.LTE; }
{GTE}		{ return Parser.GTE; }
"+" | 
"-" | 
"*" | 
"/" | 
"<" | 
">" | 
"^" | 
"(" | 
")" |
"[" | 
"]" |
"%" |
"=" |
"#" |
"?" |
":" |
"@" |
";"		{ return (int) yycharat(0); }

/* print some output */
{PRINT}		{ return Parser.PRINT; }

/* set a symbol in the symtol table to a value */
{SET}		{ return Parser.SET; }

/* evaluate an expression and return its value: string or number */
{EVAL}		{ return Parser.EVAL; }

/* set symbol (arrays) values in the symbol table to values that come out of SmallSQL */
{SETINST}	{ return Parser.SETINST; }

/* print the contents of the symbol table */
{SYMTAB}	{ return Parser.SYMTAB; }

/* delete a symbol in the symbol table */
{DELETE}	{ return Parser.DELETE; }

/* delete all symbols in the symbol table */
{CLEAR}		{ return Parser.CLEAR; }

/* logical OR */
{OR}		{ return Parser.OR; }

/* logical AND */
{AND}		{ return Parser.AND; }

/* return the name of a bymbol */
{SYMBOL}	{
				yyparser.yylval = new ParserVal( yytext() );
				return Parser.SYMBOL;
			}

/* return a string constant */
{STR}		{
				String strConst = yytext();
				strConst = strConst.substring( 1, strConst.length()-1 );
				yyparser.yylval = new ParserVal( strConst );
				return Parser.STR;
			}

/* return a number; all are sent as Doubles */
{NUM}		{
				yyparser.yylval = new ParserVal( Double.parseDouble( yytext() ));
				return Parser.NUM;
			}

/* newline */
{NL}		{ /*return Parser.NL;*/ }

/* ignore whitespace */
[ \t]+ { }

\b			{ System.err.println( "Sorry, backspace doesn't work" ); }

/* error fallback */
[^]			{
				String errStr = yytext();
				if ( errStr.charAt( 0 ) != 4 )
					System.err.println( "Error: unexpected character '" + errStr + "'" );
				return -1;
			}
