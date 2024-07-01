%option noyywrap

%x CHARACTER
%x STRING
%x SINGLE_COMM
%x MULTI_COMM

%{

#include<bits/stdc++.h>
#include "1805117_symbolTable.cpp"
using namespace std;

int no_of_lines = 1;
int error_cnt = 0;
int bucket_size = 7;
SymbolTable symboltable(bucket_size);

ofstream logout;
ofstream token;

string char_answer;
string char_actual;

string string_answer;
string string_actual;

string single_comment;
string multi_comment;

int num_line_state;

string capital(string small)
{
    for(int i = 0; i < small.size(); i++)
    {
        small[i] = toupper(small[i]);
    }
    return small;
}

%}
    
LETTER [A-Za-z]
DIGIT [0-9]
KEYWORD if|for|do|int|float|void|switch|default|else|while|break|char|double|return|case|continue
WHITESPACE [ \t\r\v\f]+
NEWLINE [\r]?\n
ADDOP "+"|"-"
MULOP "*"|"/"|"%"
INCOP "++"|"--"
RELOP <|<=|>|>=|==|!=
ASSIGNOP =
logoutICOP &&|\|\|
NOT !
LPAREN \(
RPAREN \)
LCURL \{
RCURL \}
LTHIRD \[
RTHIRD \]
COMMA ,
SEMICOLON ;
IDENTIFIER [_a-zA-Z][_a-zA-Z0-9]*
    
%%

    
{WHITESPACE} {}
{NEWLINE} {no_of_lines++;}
{KEYWORD} {
    string yyString(yytext);
    string yytokenString = capital(yyString);
    token << "<" << yytokenString << "> ";
    logout << "Line no " << no_of_lines << ": Token <" << yytokenString << "> Lexeme " << yytext << " found\n";
}
{DIGIT}+ {
    token << "<CONST_INT," << yytext << "> ";
    logout << "Line no " << no_of_lines << ": Token <CONST_INT> Lexeme " << yytext << " found\n";

    if(symboltable.insert(yytext, "CONST_INT",logout))
    {
        symboltable.printAll(logout);
    }
}
{DIGIT}*(\.{DIGIT}+)?([Ee][+-]?{DIGIT}+)? {
    token << "<CONST_FLOAT," << yytext << "> ";
    logout << "Line no " << no_of_lines << ": Token <CONST_FLOAT> Lexeme " << yytext << " found\n";

    if(symboltable.insert(yytext, "CONST_FLOAT",logout))
    {
        symboltable.printAll(logout);
    }
}

{DIGIT}*\.{DIGIT}*\.[0-9\.Ee+-]*(\.)* {
    error_cnt++;
    logout << "Error at line no " << no_of_lines << ": Too many decimal points " << yytext << endl;
}

({DIGIT}*(\.{DIGIT}*)?{DIGIT}*[Ee][+-]?[0-9\.Ee+-]*(\.)*)|({DIGIT}+\.) {
    error_cnt++;
    logout << "Error at line no " << no_of_lines << ": Ill formed number " << yytext << endl;
}

{IDENTIFIER} {
    token << "<ID," << yytext << "> ";
    logout << "Line no " << no_of_lines << ": Token <ID> Lexeme " << yytext << " found\n";

    if(symboltable.insert(yytext, "ID",logout))
    {
        symboltable.printAll(logout);
    }
}
{DIGIT}+(\.{DIGIT}+)?(Ee[+-]?{DIGIT}+)?{IDENTIFIER}* {
    error_cnt++;
    logout << "Error at line no: " << no_of_lines << ": Invalid Suffix on numeric constant or invalid prefix on identifier for character sequence " << yytext << endl; 
}
{ADDOP} {
    token << "<ADDOP," << yytext << "> ";
    logout << "Line no " << no_of_lines << ": Token <ADDOP> Lexeme " << yytext << " found\n";
}
{MULOP} {
    token << "<MULOP," << yytext << "> ";
    logout << "Line no " << no_of_lines << ": Token <MULOP> Lexeme " << yytext << " found\n";
}
{INCOP} {
    token << "<INCOP," << yytext << "> ";
    logout << "Line no " << no_of_lines << ": Token <INCOP> Lexeme " << yytext << " found\n";
}
{RELOP} {
    token << "<RELOP," << yytext << "> ";
    logout << "Line no " << no_of_lines << ": Token <RELOP> Lexeme " << yytext << " found\n";
}
{ASSIGNOP} {
    token << "<ASSIGNOP," << yytext << "> ";
    logout << "Line no " << no_of_lines << ": Token <ASSIGNOP> Lexeme " << yytext << " found\n";
}
{logoutICOP} {
    token << "<logoutICOP," << yytext << "> ";
    logout << "Line no " << no_of_lines << ": Token <logoutICOP> Lexeme " << yytext << " found\n";
}
{NOT} {
    token << "<NOT," << yytext << "> ";
    logout << "Line no " << no_of_lines << ": Token <NOT> Lexeme " << yytext << " found\n";
}
{LPAREN} {
    token << "<LPAREN," << yytext << "> ";
    logout << "Line no " << no_of_lines << ": Token <LPAREN> Lexeme " << yytext << " found\n";
}
{RPAREN} {
    token << "<RPAREN," << yytext << "> ";
    logout << "Line no " << no_of_lines << ": Token <RPAREN> Lexeme " << yytext << " found\n";
}
{LCURL} {
    token << "<LCURL," << yytext << "> ";
    logout << "Line no " << no_of_lines << ": Token <LCURL> Lexeme " << yytext << " found\n";
    
    symboltable.enterScope(bucket_size);
}
{RCURL} {
    token << "<RCURL," << yytext << "> ";
    logout << "Line no " << no_of_lines << ": Token <RCURL> Lexeme " << yytext << " found\n";

    symboltable.exitScope();
}
{LTHIRD} {
    token << "<LTHIRD," << yytext << "> ";
    logout << "Line no " << no_of_lines << ": Token <LTHIRD> Lexeme " << yytext << " found\n";
}
{RTHIRD} {
    token << "<RTHIRD," << yytext << "> ";
    logout << "Line no " << no_of_lines << ": Token <RTHIRD> Lexeme " << yytext << " found\n";
}
{COMMA} {
    token << "<COMMA," << yytext << "> ";
    logout << "Line no " << no_of_lines << ": Token <COMMA> Lexeme " << yytext << " found\n";
}
{SEMICOLON} {
    token << "<SEMICOLON," << yytext << "> ";
    logout << "Line no " << no_of_lines << ": Token <SEMICOLON> Lexeme " << yytext << " found\n";
}
' {
    char_actual = "\0";
    char_answer = "\0";

    BEGIN CHARACTER;
}
<CHARACTER>\\n {
    char_actual += "\\n";
    char_answer += "\n";
}
<CHARACTER>\\t {
    char_actual += "\\t";
    char_answer += "\t";
}
<CHARACTER>\\\\ {
   // char_actual += "\\\\";
    char_answer += "\\";
}
<CHARACTER>\\' {
    char_actual += "\\'";
    char_answer += "\'";
}
<CHARACTER>\\a {
    char_actual += "\\a";
    char_answer += "\a";
}
<CHARACTER>\\b {
    char_actual += "\\b";
    char_answer += "\b";
}
<CHARACTER>\\f {
    char_actual += "\\f";
    char_answer += "\f";
}
<CHARACTER>\\r {
    char_actual += "\\r";
    char_answer += "\r";
}
<CHARACTER>\\v {
    char_actual += "\\v";
    char_answer += "\v";
}
<CHARACTER>\\0 {
    char_actual += "\\0";
    char_answer += "\0";
}

<CHARACTER>' {
    string print;
    print = "'";
    print += char_actual;
    print += "'";
    cout<<endl<<endl<<"found end of character "<<char_actual<<char_answer<<char_answer.size()<<endl;
    if(char_answer.size() == 0)
    {
        if(char_actual == "\\0")
        {
            token << "<CONST_CHAR," << char_answer << "> ";
            logout << "Line no " << no_of_lines << ": Token <CONST_CHAR> Lexeme " << yytext << " found --> <CONST_CHAR," << char_answer << "> "<<endl;

            if(symboltable.insert(yytext, "CONST_CHAR",logout))
            {
                symboltable.printAll(logout);
            }
        }
        else 
        {
            error_cnt++;
            logout << "Error at line no " << no_of_lines << ": Empty Character Constant " << print << endl;
            BEGIN INITIAL;
        }
    }
    else if(char_answer.size() == 1)
    {
        token << "<CONST_CHAR," << char_answer << "> ";
        logout << "Line no " << no_of_lines << ": Token <CONST_CHAR> Lexeme " << print << " found --> <CONST_CHAR," << char_answer << "> "<<endl;

        if(symboltable.insert(yytext, "CONST_CHAR",logout))
        {
            symboltable.printAll(logout);
        }
    }
    else 
    {
        error_cnt++;
        logout << "Error at line no " << no_of_lines << ": Multi Character Constant " << print << endl;
        BEGIN INITIAL;
    }
    BEGIN INITIAL;
}
<CHARACTER><<EOF>> {
    string print = "'";
    print += char_actual;

    error_cnt++;
    logout << "Error at line no " << no_of_lines << ": Unterminated Character " << print << endl;

    BEGIN INITIAL;
}
<CHARACTER>[\r]?\n {
    string print = "'";
    print += char_actual;

    error_cnt++;
    logout << "Error at line no " << no_of_lines << ": Unterminated Character " << print << endl;

    no_of_lines++;

    BEGIN INITIAL;
}
<CHARACTER>. {
    char_actual += yytext[0];
    char_answer += yytext[0];
}
\" {
    string_actual = "";
    string_answer = "";

    num_line_state = 0;

    BEGIN STRING;
}
<STRING>\\n {
    string_actual += "\\n";
    string_answer += "\n";
    num_line_state++;
}
<STRING>\\t {
    string_actual += "\\t";
    string_answer += "\t";
}
<STRING>\\\\ {
    string_actual += "\\\\";
    string_answer += "\\";
}
<STRING>\\\' {
    string_actual += "\\\'";
    string_answer += "\'";
}
<STRING>\\a {
    string_actual += "\\a";
    string_answer += "\a";
}
<STRING>\\b {
    string_actual += "\\b";
    string_answer += "\b";
}
<STRING>\\f {
    string_actual += "\\f";
    string_answer += "\f";
}
<STRING>\\r {
    string_actual += "\\r";
    string_answer += "\r";
    num_line_state++;
}
<STRING>\\v {
    string_actual += "\\v";
    string_answer += "\v";
}
<STRING>\\0 {
    string_actual += "\\0";
    string_answer += "\0";
}
<STRING>\\\" {
    string_actual += "\\\"";
    string_answer += "\"";
}
<STRING>\\\r\n {
    num_line_state++;
    string_actual += "\\\r\n";
}
<STRING>\\\n {
    num_line_state++;
    string_actual += "\\\n";
}
<STRING>\" {
    string print = "\"";
    print += string_actual;
    print += "\"";

    token << "<STRING,\"" << string_answer <<"\"> ";
    logout << "Line no " << no_of_lines << ": Token <STRING> Lexeme " << print << " found --> <STRING, \"" << string_answer <<"\"> "<<endl;

    no_of_lines += num_line_state;
    num_line_state = 0;

    BEGIN INITIAL;
}
<STRING><<EOF>> {
    string print = "\"";
    print += string_actual;

    error_cnt++;
    logout << "Error at line no " << no_of_lines << ": Unterminated String " << print << endl;

    BEGIN INITIAL;
}
<STRING>[\r]?\n {
    num_line_state++;
    string print = "\"";
    print += string_actual;
    error_cnt++;
    logout << "Error at line no " << no_of_lines << ": Unterminated String " << print << endl;
    
    no_of_lines += num_line_state;
    num_line_state = 0;

    BEGIN INITIAL;
}
<STRING>. {
    string_actual += yytext[0];
    string_answer += yytext[0];
}
\/\/ {
    single_comment = "\0";
    single_comment = "//";

    num_line_state = 0;

    BEGIN SINGLE_COMM;
}
<SINGLE_COMM>[\r]?\n {
    num_line_state++;
    logout << "Line no " << num_line_state << ": Token <COMMENT> Lexeme " << single_comment << " found "<< endl;

    no_of_lines += num_line_state;
    num_line_state = 0;

    BEGIN INITIAL;
}
<SINGLE_COMM>\\\n {
    num_line_state++;
    single_comment += "\\\n";
}
<SINGLE_COMM>\\\r\n {
    num_line_state++;
    single_comment += "\\\r\n";
}
<SINGLE_COMM><<EOF>> {
    logout << "Line no " << num_line_state << ": Token <COMMENT> Lexeme " << single_comment << " found "<< endl;

    no_of_lines += num_line_state;
    num_line_state = 0;

    BEGIN INITIAL;
}
<SINGLE_COMM>\\ {
    single_comment += "\\";
}
<SINGLE_COMM>. {
    single_comment += yytext[0];
}
\/\* {
    multi_comment = "\0";
    multi_comment = "/*";

    num_line_state = 0;
    
    BEGIN MULTI_COMM;
}
<MULTI_COMM>\*\/ {
    multi_comment += "*/"; 
    logout << "Line no " << num_line_state << ": Token <COMMENT> Lexeme " << multi_comment << " found" <<  endl;

    no_of_lines += num_line_state;
    num_line_state = 0;

    BEGIN INITIAL;
}
<MULTI_COMM><<EOF>> {
    error_cnt++;
    logout << "Error at line no " << no_of_lines << ": Unterminated Comment " << multi_comment << endl;

    no_of_lines += num_line_state;
    num_line_state = 0;

    BEGIN INITIAL;
}
<MULTI_COMM>\r {
    multi_comment += "\r";
}
<MULTI_COMM>\n {
    multi_comment += "\n";
    num_line_state++;
}
<MULTI_COMM>. {
    multi_comment += yytext[0];
}
. {
    error_cnt++;
    logout << "Error at line no " << no_of_lines << ": Unrecognized Character " << yytext << endl;

}
    
%%


int main(int argc,char *argv[]){
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	logout.open("1805117_log.txt");
    token.open("1805117_token.txt");

	yyin= fin;
	yylex();

	symboltable.printAll(logout);
	logout<<"Total lines: "<<no_of_lines<<endl;
	logout<<"Total errors: "<<error_cnt<<endl;

	fclose(yyin);
	token.close();
	logout.close();
	return 0;
}
