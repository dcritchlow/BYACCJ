### JFlex BYACCJ project

These commands process the files needed to generate the Java class and run the program

1. Call jflex.bat
	* `Jflex.bat smallSQL.flex`
2. Translate the CFG to java
	* `yacc –J smallSQL.y`
3. Compile the java code
	* `javac Parser.java`
4. Run the program like this from the ...{jflex-home}\{project} folder
	* `java  –cp  .;smallsql.jar  Parser`