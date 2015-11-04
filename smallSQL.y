/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                         *
 *  BYACC/J file to add additional functionality to the SmallSQL program   *
 *                                                                         *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

%{
import java.io.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Set;
import java.util.Iterator;
import java.util.Map;
import java.util.Properties;
import java.sql.*;
import javax.swing.JOptionPane; 
import java.util.regex.Matcher; 
import java.util.regex.Pattern; 


%}

%token NL					/* newline  */
%token PRINT				/* print command */
%token SET					/* put a variable/value in the symbol table */
%token EVAL					/* evaluate an expression and return its value */
%token SETINST				/* execute a SmallSQL command and put the results in the symbol table */
%token SYMTAB				/* print the symbol table */
%token DELETE				/* delete a symbol in the symbol table */
%token CLEAR				/* clear out all the symbols in the symbol table */
%token <dval> NUM			/* a number */
%token <sval> SYMBOL		/* a name in the symbol table */
%token <sval> STR			/* a string constant */

%type <sval> expStr
%type <obj> exp
%type <obj> line
%type <obj> lines

%right '?' ':'
%left OR
%left AND
%left '=' NEQ
%left '<' '>' LTE GTE
%left '[' ']'
%left '-' '+'
%left '*' '/' '%' '^'
%left SQRT
%left LG
%left NEG POS '#'			/* unary minus, plus, strlen */

%%

input:			/* empty */												{ result = null; }
				| lines													{ result = $1; }
				;

lines:			line													{ $$ = $1; }
				| lines line											{ $$ = $2; }
				;
		
line:			PRINT expStr ';'										{
																			System.out.println( "= " + $2 );
																			$$ = null;
																		}
																		
				| SET '@' SYMBOL '=' exp ';'							{
																			// System.out.print( "\nSYMBOL='" + $3 + "' exp='" + $5 + "'" );
																			setSymbol( $3, $5 );
																			$$ = $5;
																		}
																		
				| EVAL exp ';'											{ $$ = $2; }
				
				| SETINST STR ';'										{	/* $2 == SmallSQL command */
																			try
																			{
																				setInSymbolTable( SmallSQL( $2 ));
																			}
																			catch( Exception ex )
																			{
																				System.out.print( "Error: executing SETINST '" + $2 + "', message: " + ex.getMessage() );
																			}
																			$$ = null;
																		}
																		
				| SYMTAB ';'											{
																			printSymbolTable();
																			$$ = null;
																		}
				| DELETE '@' SYMBOL ';'									{
																			deleteSymbol( $3 );
																			$$ = null;
																		}
																		
				| CLEAR ';'												{
																			clearSymbolTable();
																			$$ = null;
																		}
				;

expStr:			exp														{
																			if ( $1 instanceof Double )
																				$$ = $1.toString();
																			else
																				$$ = (String)$1;
																		}
																		
				| expStr ',' exp										{ $$ = $1 + " " + $3; }
				;

exp:			NUM														{ $$ = $1; }
				| STR													{ $$ = $1; }
				
				
				| '@' SYMBOL											{
																			Object value = symbolTable.get( $2 );
																			if ( value == null ) // not in symbolTable yet
																			{
																				// put it in as a default Double 0.0
																				Double newDoub = new Double( 0.0 );
																				symbolTable.put( $2, newDoub );
																				$$ = newDoub;
																			}
																			else if ( value instanceof Double || value instanceof String )
																				$$ = value; // Double or String
																			else
																			{
																				System.out.print( "Error: symbol '" + $2 + "' is a list array; please reference as an array" );
																				$$ = new Double( 0.0 );
																			}
																		}
				| '@' SYMBOL '[' exp ']'								{
																			Object value = symbolTable.get( $2 );
																			if ( value == null ) // not in symbolTable yet--arrays must be there
																			{
																				System.out.print( "Error: array symbol '" + $2 + "' is not in the symbol table" );
																				$$ = new Double( 0.0 );
																			}
																			else if ( value instanceof ArrayList )
																			{
																				if ( $4 instanceof Double )
																				{
																					$$ = ((ArrayList)value).get(( (Double)$4).intValue() );
																				}
																				else
																				{
																					System.out.print( "Error: for array symbol '" + $2 + "', array index '" + $4 + "' is not a number" );
																					$$ = new Double( 0.0 );
																				}
																			}
																			else
																			{
																				System.out.print( "Error: symbol '" + $2 + "' is not an array list" );
																				$$ = new Double( 0.0 );
																			}
																		}
																		
				| exp '+' exp											{
																			if ( $1 instanceof Double && $3 instanceof Double )
																			{
																				$$ = (Double)$1 + (Double)$3;
																			}
																			else if ( $1 instanceof String && $3 instanceof String )
																			{
																				$$ = (String)$1 + (String)$3;
																			}
																			else
																			{
																				System.out.print( "Error: trying to do '" + $1 + "' + '" + $3 + "'" );
																				$$ = new Double( 0.0 );
																			}
																		}
																		
				| exp '-' exp											{
																			if ( $1 instanceof Double && $3 instanceof Double )
																			{
																				$$ = (Double)$1 - (Double)$3;
																			}
																			else
																			{
																				System.out.print( "Error: trying to do '" + $1 + "' - '" + $3 + "'" );
																				$$ = new Double( 0.0 );
																			}
																		}
				| exp '*' exp											{
																			if ( $1 instanceof Double && $3 instanceof Double )
																			{
																				$$ = (Double)$1 * (Double)$3;
																			}
																			else
																			{
																				System.out.print( "Error: trying to do '" + $1 + "' * '" + $3 + "'" );
																				$$ = new Double( 0.0 );
																			}
																		}
																		
				| exp '/' exp											{
																			if ( $1 instanceof Double && $3 instanceof Double )
																			{
																				$$ = (Double)$1 / (Double)$3;
																			}
																			else
																			{
																				System.out.print( "Error: trying to do '" + $1 + "' / '" + $3 + "'" );
																				$$ = new Double( 0.0 );
																			}
																		}
																		
				| exp '^' exp											{
																			if ( $1 instanceof Double && $3 instanceof Double )
																			{
																				$$ = Math.pow((Double)$1 , (Double)$3);
																			}
																			else
																			{
																				System.out.print( "Error: THis is the error" );
																				//$$ = new Double( 0.0 );
																			}
																		}																		
																		
				| exp '%' exp											{
																			if ( $1 instanceof Double && $3 instanceof Double )
																			{
																				$$ = (Double)$1 % (Double)$3;
																			}
																			else
																			{
																				System.out.print( "Error: trying to do '" + $1 + "' % '" + $3 + "'" );
																				$$ = new Double( 0.0 );
																			}
																		}
																		
				| '-' exp %prec NEG										{ $$ = - ((Double)$2); }
				| '+' exp %prec POS										{ $$ = + ((Double)$2); }
				| exp '?' exp ':' exp									{ if ( $1 instanceof Double && ((Double)$1).doubleValue() != 0.0 ) $$ = $3; else $$ = $5; }
				| '#' exp												{
																			if ( $2 instanceof String )
																				$$ = new Double( ((String)$2).length() );
																			else
																				$$ = new Double( 0.0 );
																		}
				| '(' exp ')'											{ $$ = $2; }
				| exp '>' exp											{
																			if ( $1 instanceof Double && $3 instanceof Double && ((Double)$1).doubleValue() > ((Double)$3).doubleValue() )
																				$$ = new Double( 1.0 );
																			else
																				$$ = new Double ( 0.0 );
																		}
				| exp '<' exp											{
																			if ( $1 instanceof Double && $3 instanceof Double && ((Double)$1).doubleValue() < ((Double)$3).doubleValue() )
																				$$ = new Double( 1.0 );
																			else
																				$$ = new Double ( 0.0 );
																		}
				| exp GTE exp											{
																			if ( $1 instanceof Double && $3 instanceof Double && ((Double)$1).doubleValue() >= ((Double)$3).doubleValue() )
																				$$ = new Double( 1.0 );
																			else
																				$$ = new Double ( 0.0 );
																		}
				| exp LTE exp											{
																			if ( $1 instanceof Double && $3 instanceof Double && ((Double)$1).doubleValue() <= ((Double)$3).doubleValue() )
																				$$ = new Double( 1.0 );
																			else
																				$$ = new Double ( 0.0 );
																		}
				| exp '=' exp											{
																			if ( $1 instanceof Double && $3 instanceof Double && ((Double)$1).doubleValue() == ((Double)$3).doubleValue() )
																				$$ = new Double( 1.0 );
																			else if ( $1 instanceof String && $3 instanceof String && $1.equals( $3 ))
																				$$ = new Double( 1.0 );
																			else
																				$$ = new Double( 0.0 );
																		}
				| exp NEQ exp											{
																			if ( $1 instanceof Double && $3 instanceof Double && ((Double)$1).doubleValue() != ((Double)$3).doubleValue() )
																				$$ = new Double( 1.0 );
																			else if ( $1 instanceof String && $3 instanceof String && !(((Double)$1).equals( $3 )))
																				$$ = new Double( 1.0 );
																			else
																				$$ = new Double( 0.0 );
																		}
																		
				|  exp	SQRT										    {   // sqrt
																			if ( $1 instanceof Double  )																																					    
																				$$ = Math.sqrt((Double)$1 );
																																						
																			else
																				System.out.print( "Error: trying to do SQRT '" + $1 +" '" );
																				//$$ = new Double( 0.0 );
																		}
																		
				|  exp	LG										       {   // logarithm function 
																			if ( $1 instanceof Double  )																																					    
																				$$ = Math.log((Double)$1 );
																																						
																			else
																				System.out.print( "Error: trying to do logarithm '" + $1 +" '" );
																				//$$ = new Double( 0.0 );
																		}																		

																																					
																		
			| exp AND exp											{
																			if ( $1 instanceof Double && $3 instanceof Double && ((Double)$1).doubleValue()==1.0 && ((Double)$3).doubleValue()==1.0 )
																				$$ = new Double( 1.0 );
																			else if ( $1 instanceof String && $3 instanceof String && ($1.equals("1.0") && $3.equals("1.0")))
																				$$ = new Double( 1.0 );
																			else
																				$$ = new Double( 0.0 );
																		}	
																		
			| exp OR exp											{
																			if ( $1 instanceof Double && $3 instanceof Double && ((Double)$1).doubleValue()==1.0 || ((Double)$3).doubleValue()==1.0 )
																				$$ = new Double( 1.0 );
																			else if ( $1 instanceof String && $3 instanceof String && ($1.equals("1.0") || $3.equals("1.0")))
																				$$ = new Double( 1.0 );
																			else
																				$$ = new Double( 0.0 );
																		}
																		
				;

%%

private Yylex lexer;
private static HashMap<String,Object> symbolTable = new HashMap<String,Object>();
private static Object result = null;
private static Connection con;
private static Statement st;


private int yylex()
{

	int yyl_return = -1;
	try
	{
		yylval = new ParserVal(0);
		yyl_return = lexer.yylex();
	}
	catch ( IOException e )
	{
		System.err.println( "IO error :" + e );
	}
	return yyl_return;
	
}


public void yyerror ( String error )
{

	System.err.println ( "Error: " + error );
	
}


public Parser( Reader r )
{

	lexer = new Yylex( r, this );
	
}


void setSymbol( String symbolName, Object symbolValue )
{

	symbolTable.put( symbolName, symbolValue );
	
}


void setInSymbolTable( ResultSet smallSqlResult ) throws SQLException
{
	
	if ( smallSqlResult != null )
	{
		HashMap<String,ArrayList<Object>> resultSetHM = getRSasHashMap( smallSqlResult );
		
		for ( Map.Entry<String, ArrayList<Object>> entry : resultSetHM.entrySet()) 
		{
			String key = entry.getKey();
			ArrayList<Object> value = entry.getValue();

			symbolTable.put( key, value );
		}
	}
	
}


ResultSet SmallSQL( String smallSqlCmd ) throws SQLException
{

	boolean isRS = st.execute( smallSqlCmd );
	if( isRS )
		return( st.getResultSet() );
	else
		return null;
					
}


void printSymbolTable()
{
		String key ="";  						// Key/symbol from ArrayList
		ArrayList valueArr;						// ArrayList casted from HashMap Value
		String[] tmpValue = new String[100];    // Temporary regular array to acomulate HashMap values per record
		
		int lengthArr=0;                        // Length of the ArrayList per key/symbol

		for (Map.Entry<String,Object> entry : symbolTable.entrySet()) {
			
			
			Object value = entry.getValue();    // getting object value to identify the type of the retrived HashMap value
			
			if ( value instanceof ArrayList ){
				
				key += "  " + entry.getKey();
				
				valueArr = (ArrayList)entry.getValue();
			 
				Object convertedListToArray[] = valueArr.toArray();	// convert  ArrayList to the regular array to concatenate row values		 
				lengthArr	 = convertedListToArray.length ;			 
				
				for(int i = 0; i < convertedListToArray.length; i++) 
			   {						
					tmpValue[i] += "  " + convertedListToArray[i].toString();	//concatenate row values						  	   
			   }
			   
			} else{
				System.out.print(" Not in aray. Key : " + entry.getKey() + " Value : " + value + "\n"); // if HashMap value not ArrayList then just print Key-Value.
			}			
		  		   
		}
		
		if (lengthArr >0) // if ArrayList was not empty then print Key - Values as in SQL table 'emp' 
		{
			System.out.print( key + "\n");
			 
			for(int i = 0; i < lengthArr; i++)
			   {		   
				   System.out.print( tmpValue[i] + "\n");		   		   
			   }
		}

	/* completed */
}


void deleteSymbol( String symbolName )
{
	
		for( Iterator<Map.Entry<String,Object>> it = symbolTable.entrySet().iterator(); it.hasNext(); )
		{
		
			 Map.Entry<String, Object> entry = it.next();			 			 
			 
			 if (entry.getKey().equals( symbolName)  ) {
				 
				  it.remove();
			 }
		}

	
	/* done */
}


void clearSymbolTable()
{
	symbolTable.clear();
	
	/* done */
}




public static void procIf( String cmdStr ) 
{ 
	String IF = "[iI][fF]\\s\\((.*)\\)\\s[tT][hH][eE][nN](.*);$"; 
	String IFELSE = "[iI][fF]\\s\\((.*)\\)\\s[tT][hH][eE][nN](.*);[\n\r]{0,}[eE][lL][sS][eE](.*);"; 
	 
	Boolean ifStatement = false; 
	Boolean ifelseStatement = false; 
	Boolean commandResult = false; 
	 
	Pattern patternIf = Pattern.compile(IF); 
	Matcher matcherIf = patternIf.matcher(cmdStr); 
	 
	Pattern patternIfElse = Pattern.compile(IFELSE); 
	Matcher matcherIfElse = patternIfElse.matcher(cmdStr); 
	 
	String command = ""; 
	String commandIfTrue = ""; 
	String commandElse = ""; 
	 
	if (matcherIf.find())  
	{ 
		ifStatement = true; 
		command = "eval " + matcherIf.group(1) + ";"; 
		commandIfTrue = matcherIf.group(2) + ";"; 
    } 
	   
	if (matcherIfElse.find())  
	{ 
		ifelseStatement = true; 
		command = "eval " + matcherIfElse.group(1) + ";"; 
		commandIfTrue = matcherIfElse.group(2) + ";"; 
		commandElse = matcherIfElse.group(3) + ";"; 
	} 
	 
	if(ifStatement) 
	{ 
		try 
		{ 
			BYaccJ(command); 
			 
			if ( result instanceof Double && ((Double)result).doubleValue() == 1.0 ) 
			{ 
				commandResult = true; 
			} 
			else 
			{ 
				commandResult = false; 
			} 
			 
			if (commandResult) 
			{ 
				try 
				{ 
					BYaccJ(commandIfTrue); 
				} 
				catch (Exception ex) 
				{ 
					System.out.println("Exception was caught: " + ex); 
				} 
			} 
		} 
		catch (Exception ex) 
		{ 
			System.out.println("Exception was caught: " + ex); 
		} 
	} 
	 
	if(ifelseStatement) 
	{ 
		try 
		{ 
			BYaccJ(command); 
			 
			if ( result instanceof Double && ((Double)result).doubleValue() == 1.0 ) 
			{ 
				commandResult = true; 
			} 
			else 
			{ 
				commandResult = false; 
			} 
			 
			System.out.println(commandResult); 
			 
			if (commandResult) 
			{ 
				try 
				{ 
					BYaccJ(commandIfTrue); 
				} 
				catch (Exception ex) 
				{ 
					System.out.println("Exception was caught: " + ex); 
				} 
			} 
			else 
			{ 
				try 
				{ 
					BYaccJ(commandElse); 
				} 
				catch (Exception ex) 
				{ 
					System.out.println("Exception was caught: " + ex); 
				} 
			} 
		} 
		catch (Exception ex) 
		{ 
			System.out.println("Exception was caught: " + ex); 
		} 
	} 
	 
} 



public static void BYaccJ( String command ) throws IOException
{

	result = null;
	Parser yyparser = new Parser( new InputStreamReader( new ByteArrayInputStream( command.getBytes() )));
	yyparser.yyparse();

}


public static void main(String[] args) throws Exception
{

	System.out.println( "Augmented SmallSQL Database command line tool\n" );
	Class.forName("smallsql.database.SSDriver");
	con = DriverManager.getConnection( "jdbc:smallsql", new Properties() );
	st = con.createStatement();
	
	if( args.length > 0 )
	{
		con.setCatalog(	args[0]	);
	}
	System.out.println( "\tVersion: " + con.getMetaData().getDatabaseProductVersion() );
	System.out.println( "\tCurrent database: " + con.getCatalog() );
	System.out.println();
	System.out.println( "\tUse the USE command to change the database context." );
	System.out.println( "\tType ENTER 2 times to execute any Augmented SmallSQL command." );

	StringBuffer command = new StringBuffer();
	BufferedReader input = new BufferedReader( new InputStreamReader( System.in ));
	enterCmdLoop: while(true)
	{
		try
		{
			String line;
			try
			{
				line = input.readLine();
			}
			catch(IOException ex)
			{
				ex.printStackTrace();
				JOptionPane.showMessageDialog( null, "You need to start the command line of the \nSmallSQL Database with a console window:\n\n       java -jar smallsql.jar\n\n" + ex, "Fatal Error", JOptionPane.OK_OPTION);
				return;
			}
			
			if( line == null )
			{
				return; //end of program
			}
			
			if( line.length() == 0 && command.toString().trim().length() > 0 )
			{
				String cmdStr = command.toString();
				String ucTrimCmd = cmdStr.trim().toUpperCase();
				
				if ( ucTrimCmd.startsWith( "PRINT" ) ||
					 ucTrimCmd.startsWith( "SET" ) ||
					 ucTrimCmd.startsWith( "EVAL" ) ||
					 ucTrimCmd.startsWith( "SETINST" ) ||
					 ucTrimCmd.startsWith( "SYMTAB" ) ||
					 ucTrimCmd.startsWith( "DELETE" ) ||
					 ucTrimCmd.startsWith( "CLEAR" ))
				{
					BYaccJ( cmdStr );
					System.out.println( result );
					System.out.println();
				}
				else if ( ucTrimCmd.startsWith( "IF" ))
				{
					procIf( cmdStr );
				}
				else /* actual SmallSQL command */
				{
					int startNonSql = cmdStr.indexOf( "[[" );
					int endNonSql = cmdStr.indexOf( "]]" );
					if ( startNonSql != -1 && endNonSql != -1 )
					{
						String nonSqlCmd = cmdStr.substring( startNonSql+2, endNonSql ).trim();
						BYaccJ( nonSqlCmd );
						if ( result == null )
						{
							System.out.println( "Error: command '" + cmdStr.substring( startNonSql, endNonSql+2 ) + "' produced NULL result" );
							command.setLength( 0 );
							continue enterCmdLoop;
						}
						else if ( result instanceof Double )
						{
							double dblResult = ((Double)result).doubleValue() ;
							if ( dblResult == Math.rint( dblResult )) // number is actually an integer
								cmdStr = cmdStr.substring( 0, startNonSql ) + (long)dblResult + cmdStr.substring( endNonSql + 2 );
							else
								cmdStr = cmdStr.substring( 0, startNonSql ) + dblResult + cmdStr.substring( endNonSql + 2 );
						}
						else if ( result instanceof String )
						{
							cmdStr = cmdStr.substring( 0, startNonSql ) + "'" + (String)result + "'" + cmdStr.substring( endNonSql + 2 );
						}
						else
						{
							System.out.println( "Error: unknown data type returned for [[...]]: '" + result + "'" );
							command.setLength( 0 );
							continue enterCmdLoop;
						}
					}
					
					boolean isRS = st.execute( cmdStr );
					if( isRS )
					{
						printRS( st.getResultSet() );
					}
				}
				
				command.setLength( 0 );
			}
			command.append( line ).append( '\n' );
		}
		catch ( Exception e )
		{
			command.setLength( 0 );
			e.printStackTrace();
		}
	}

}


public static void printRS( ResultSet rs ) throws SQLException
{

	ResultSetMetaData md = rs.getMetaData();
	int count = md.getColumnCount();
	
	for( int i = 1; i <= count; i++ )
	{
		System.out.print( md.getColumnLabel( i ));
		System.out.print( '\t' );
	}
	System.out.println();
	
	while( rs.next() )
	{
		for( int i = 1; i <= count; i++ )
		{
			System.out.print( rs.getObject(i) );
			System.out.print( '\t' );
		}
		System.out.println();
	}
	
}


public static HashMap<String,ArrayList<Object>> getRSasHashMap( ResultSet rs ) throws SQLException
{

	ResultSetMetaData md = rs.getMetaData();
	int count = md.getColumnCount();
	int columnType;
	String[] columnNames = new String[ count+1 ];
	ArrayList<Object> aColumn;
	ArrayList<ArrayList<Object>> columns = new ArrayList<ArrayList<Object>>();
	HashMap<String,ArrayList<Object>> resultSetHM = new HashMap<String,ArrayList<Object>>();
	Double dblType;
	Integer intType;
	
	columns.add( null ); // we don't use columns[0] again
	
	for( int i = 1; i <= count; i++ )
	{
		columnNames[i] = md.getColumnLabel( i );
		columns.add( new ArrayList<Object>() ); // add columns[i]
	}
	
	int c=0;
	
	while( rs.next() )
	{
		c++;
		System.out.println( "while loop: " + c );
		for( int i = 1; i <= count; i++ )
		{
			System.out.println( "for loop: " + i );
			
			aColumn = columns.get( i );
			columnType = md.getColumnType( i );
			if ( columnType == java.sql.Types.VARCHAR ||
				 columnType == java.sql.Types.DOUBLE )
			{
				aColumn.add( rs.getObject(i) );
				System.out.println( "rs.getObject(i) : "+rs.getObject(i));
			}
			else if ( columnType == java.sql.Types.INTEGER )
			{
				intType = (Integer)rs.getObject(i);
				dblType = new Double( intType.doubleValue() );
				aColumn.add( dblType );
				
				System.out.println( "rs.getObject(i) id INT : "+rs.getObject(i));
			}
			else
			{
				System.out.println( "Error: type not currently processed: " + columnType );
				return resultSetHM;
			}
		}
	}
	
	for( int i = 1; i <= count; i++ )
	{
		resultSetHM.put( columnNames[i], columns.get( i ));
	}
	
	return resultSetHM;
	
}

