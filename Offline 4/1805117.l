%option noyywrap

%x CHARACTER
%x STRING
%x SINGLE_COMM
%x MULTI_COMM

%{

#include<bits/stdc++.h>
#include "1805117_symbolTable.cpp"
#include "y.tab.h"
using namespace std;


int no_of_lines = 1;
int err_cnt = 0;
extern SymbolTable *symboltable;
extern YYSTYPE yylval;
void yyerror(char *);

extern ofstream logout;
extern ofstream errout;
extern int error_count;

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
WHITESPACE [ \t\r\v\f]+
NEWLINE [\r]?\n
IDENTIFIER [_a-zA-Z][_a-zA-Z0-9]*
    
%%

{WHITESPACE} {}
{NEWLINE} {no_of_lines++;}
"if" {
    SymbolInfo *s = new SymbolInfo(yytext, "IF");
    yylval.symbolInfo = s;
    return IF;
}
"for" {
    SymbolInfo *s = new SymbolInfo(yytext, "FOR");
    yylval.symbolInfo = s;
    return FOR;
}
"do" {
    SymbolInfo *s = new SymbolInfo(yytext, "DO");
    yylval.symbolInfo = s;
    return DO;
}
"int" {
    SymbolInfo *s = new SymbolInfo(yytext, "INT");
    yylval.symbolInfo = s;
    return INT;
}
"float" {
    SymbolInfo *s = new SymbolInfo(yytext, "FLOAT");
    yylval.symbolInfo = s;
    return FLOAT;
}
"void" {
    SymbolInfo *s = new SymbolInfo(yytext, "VOID");
    yylval.symbolInfo = s;
    return VOID;
}
"switch" {
    SymbolInfo *s = new SymbolInfo(yytext, "SWITCH");
    yylval.symbolInfo = s;
    return SWITCH;
}
"default" {
    SymbolInfo *s = new SymbolInfo(yytext, "DEFAULT");
    yylval.symbolInfo = s;
    return DEFAULT;
}
"else" {
    SymbolInfo *s = new SymbolInfo(yytext, "ELSE");
    yylval.symbolInfo = s;
    return ELSE;
}
"while" {
    SymbolInfo *s = new SymbolInfo(yytext, "WHILE");
    yylval.symbolInfo = s;
    return WHILE;
}
"break" {
    SymbolInfo *s = new SymbolInfo(yytext, "BREAK");
    yylval.symbolInfo = s;
    return BREAK;
}
"char" {
    SymbolInfo *s = new SymbolInfo(yytext, "CHAR");
    yylval.symbolInfo = s;
    return CHAR;
}
"double" {
    SymbolInfo *s = new SymbolInfo(yytext, "DOUBLE");
    yylval.symbolInfo = s;
    return DOUBLE;
}
"return" {
    SymbolInfo *s = new SymbolInfo(yytext, "RETURN");
    yylval.symbolInfo = s;
    return RETURN;
}
"case" {
    SymbolInfo *s = new SymbolInfo(yytext, "CASE");
    yylval.symbolInfo = s;
    return CASE;
}
"continue" {
    SymbolInfo *s = new SymbolInfo(yytext, "CONTINUE");
    yylval.symbolInfo = s;
    return CONTINUE;
}
"println" {
    SymbolInfo *s = new SymbolInfo(yytext, "PRINTLN");
    yylval.symbolInfo = s;
    return PRINTLN;
}

{DIGIT}+ {
    SymbolInfo *s = new SymbolInfo(yytext, "CONST_INT");
    yylval.symbolInfo = s;
    return CONST_INT;
}
{DIGIT}*(\.{DIGIT}+)?([Ee][+-]?{DIGIT}+)? {
    SymbolInfo *s = new SymbolInfo(yytext, "CONST_FLOAT");
    yylval.symbolInfo = s;
    return CONST_FLOAT;
}

{DIGIT}*\.{DIGIT}*\.[0-9\.Ee+-]*(\.)* {
    error_count++;
    logout << "Error at line no " << no_of_lines << ": Too many decimal points " << yytext << endl;
    errout << "Error at line no " << no_of_lines << ": Too many decimal points " << yytext << endl;

    SymbolInfo *s = new SymbolInfo(yytext, "CONST_FLOAT");
    yylval.symbolInfo = s;
    return CONST_FLOAT;
}

([0-9]+(\.[0-9]*)?[Ee][+-]?[0-9]*[0-9\.Ee+-]*(\.)*)|([0-9]+\.) {
    error_count++;
    logout << "Error at line no " << no_of_lines << ": Ill formed number " << yytext << endl;
    errout << "Error at line no " << no_of_lines << ": Ill formed number " << yytext << endl;

    SymbolInfo *s = new SymbolInfo(yytext, "CONST_FLOAT");
    yylval.symbolInfo = s;
    return CONST_FLOAT;
}

{IDENTIFIER} {
    SymbolInfo *s = new SymbolInfo(yytext, "ID");
    yylval.symbolInfo = s;
    return ID;
}
{DIGIT}+(\.{DIGIT}+)?(Ee[+-]?{DIGIT}+)?{IDENTIFIER}* {
    error_count++;
    logout << "Error at line no: " << no_of_lines << ": Invalid Suffix on numeric constant or invalid prefix on identifier for character sequence " << yytext << endl; 
    errout << "Error at line no: " << no_of_lines << ": Invalid Suffix on numeric constant or invalid prefix on identifier for character sequence " << yytext << endl; 

    SymbolInfo *s = new SymbolInfo(yytext, "ID");
    yylval.symbolInfo = s;
    return ID;
}
"+"|"-" {
    SymbolInfo *s = new SymbolInfo(yytext, "ADDOP");
    yylval.symbolInfo = s;
    return ADDOP;
}
"*"|"/"|"%" {
    SymbolInfo *s = new SymbolInfo(yytext, "MULOP");
    yylval.symbolInfo = s;
    return MULOP;
}
"++" {
    SymbolInfo *s = new SymbolInfo(yytext, "INCOP");
    yylval.symbolInfo = s;
    return INCOP;
}
"--" {
    SymbolInfo *s = new SymbolInfo(yytext, "DECOP");
    yylval.symbolInfo = s;
    return DECOP;
}
"<"|"<="|">"|">="|"=="|"!=" {
    SymbolInfo *s = new SymbolInfo(yytext, "RELOP");
    yylval.symbolInfo = s;
    return RELOP;
}
"=" {
    SymbolInfo *s = new SymbolInfo(yytext, "ASSIGNOP");
    yylval.symbolInfo = s;
    return ASSIGNOP;
}
"&&"|"||" {
    SymbolInfo *s = new SymbolInfo(yytext, "LOGICOP");
    yylval.symbolInfo = s;
    return LOGICOP;
}
"!" {
    SymbolInfo *s = new SymbolInfo(yytext, "NOT");
    yylval.symbolInfo = s;
    return NOT;
}
"(" {
    SymbolInfo *s = new SymbolInfo(yytext, "LPAREN");
    yylval.symbolInfo = s;
    return LPAREN;
}
")" {
    SymbolInfo *s = new SymbolInfo(yytext, "RPAREN");
    yylval.symbolInfo = s;
    return RPAREN;
}
"{" {
    SymbolInfo *s = new SymbolInfo(yytext, "LCURL");
    yylval.symbolInfo = s;
    return LCURL;
}
"}" {
    SymbolInfo *s = new SymbolInfo(yytext, "RCURL");
    yylval.symbolInfo = s;
    return RCURL;
}
"[" {
    SymbolInfo *s = new SymbolInfo(yytext, "LTHIRD");
    yylval.symbolInfo = s;
    return LTHIRD;
}
"]" {
    SymbolInfo *s = new SymbolInfo(yytext, "RTHIRD");
    yylval.symbolInfo = s;
    return RTHIRD;
}
"," {
    SymbolInfo *s = new SymbolInfo(yytext, "COMMA");
    yylval.symbolInfo = s;
    return COMMA;
}
";" {
    SymbolInfo *s = new SymbolInfo(yytext, "SEMICOLON");
    yylval.symbolInfo = s;
    return SEMICOLON;
}
' {
    char_actual = "";
    char_answer = "";

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
    //cout<<endl<<endl<<"found end of character "<<char_actual<<char_answer<<char_answer.size()<<endl;
    if(char_answer.size() == 0)
    {
        if(char_actual == "\\0")
        {
            
        }
        else 
        {
            err_cnt++;
        }
    }
    else if(char_answer.size() == 1)
    {
        
    }
    else 
    {
        err_cnt++;
        BEGIN INITIAL;
    }
    BEGIN INITIAL;
}
<CHARACTER><<EOF>> {
    string print = "'";
    print += char_actual;

    err_cnt++;
    
    BEGIN INITIAL;
}
<CHARACTER>[\r]?\n {
    string print = "'";
    print += char_actual;

    err_cnt++;
    
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

    no_of_lines += num_line_state;
    num_line_state = 0;

    BEGIN INITIAL;
}
<STRING><<EOF>> {
    string print = "\"";
    print += string_actual;

    error_count++;
    
    BEGIN INITIAL;
}
<STRING>[\r]?\n {
    num_line_state++;
    string print = "\"";
    print += string_actual;
    err_cnt++;
    
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
    
    no_of_lines += num_line_state;
    num_line_state = 0;

    BEGIN INITIAL;
}
<MULTI_COMM><<EOF>> {
    err_cnt++;
    
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
    error_count++;
    logout << "Error at line no " << no_of_lines << ": Unrecognized Character " << yytext << endl;
    errout << "Error at line no " << no_of_lines << ": Unrecognized Character " << yytext << endl;

}
    
%%
