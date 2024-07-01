%{
#include<bits/stdc++.h>
#include "1805117_symbolTable.cpp"
using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;

ofstream logout;
ofstream errout;

extern int no_of_lines;
int error_count=0;

extern FILE *yyin;

//symboltable
int bucketsize = 30;

SymbolTable *symbolTable = new SymbolTable(bucketsize);

vector<SymbolInfo*> parameters;
bool func = false;

void yyerror(string errorMsg)
{
	//write your code
	logout << "Error at line " << no_of_lines << ": " << errorMsg << "\n" << endl;
	errout << "Error at line " << no_of_lines << ": " << errorMsg << "\n" << endl;
	error_count++; 
}

string implicit_typecast(string left_operand, string right_operand)
{
	if(left_operand == "NULL" || right_operand == "NULL")
	{
		return "NULL";
	}
	if(left_operand == "void" || right_operand == "void")
	{
		return "error";
	}
	if((left_operand == "int" || left_operand == "int_array") && (right_operand == "float" || right_operand == "float_array"))
	{
		return "float";
	} 
	if((right_operand == "int" || right_operand == "int_array") && (left_operand == "float" || left_operand == "float_array"))
	{
		return "float";
	}
	if((left_operand == "int" || left_operand == "int_array") && (right_operand == "int" || right_operand == "int_array"))
	{
		return "int";
	} 
	if((left_operand == "float" || left_operand == "float_array") && (right_operand == "float" || right_operand == "float_array"))
	{
		return "float";
	}

	return "error";
}

bool assignOp(string left_operand, string right_operand)
{
	if(left_operand == "void" || right_operand == "void")
	{
		return false;
	}
	if((left_operand == "int" || left_operand == "int_array") && (right_operand == "int" || right_operand == "int_array"))
	{
		return true;
	}
	if((left_operand == "float" || left_operand == "float_array") && (right_operand != "void"))
	{
		return true;
	}
	if((left_operand == "") && (right_operand == ""))
	{
		return false;
	}
	if((left_operand == "NULL") && (right_operand == "NULL"))
	{
		return false;
	}
	return false;
}


void insert_function(SymbolInfo* si, string ret_type)
{
	si->setTypeSpecification(ret_type);
	si->setFunction(true);

	for(auto temp_p : parameters)
	{
		si->addParam(temp_p->typeSpecification);
	}

	if(!symbolTable->insert(si))
	{
		SymbolInfo *s = symbolTable->lookup(si->getName());

		if(s->isFunctionDec == false)
		{
			logout << "Error at line no " << no_of_lines << ": Multiple declaration of " << si->name << "\n" << endl;
			errout << "Error at line no " << no_of_lines << ": Multiple declaration of " << si->name << "\n" << endl;
			error_count++;
		}
		else
		{
			if(s->typeSpecification != si->typeSpecification)
			{
				logout << "Error at line " << no_of_lines << ": Return type mismatch with function declaration in function " << si->name << "\n" << endl;
    			errout << "Error at line " << no_of_lines << ": Return type mismatch with function declaration in function " << si->name << "\n" << endl;
    			error_count++;
			}
			if(s->params.size() != si->params.size())
			{
				logout << "Error at line no " << no_of_lines << ": Total number of arguments mismatch with declaration in function " << si->name << "\n" << endl;
				errout << "Error at line no " << no_of_lines << ": Total number of arguments mismatch with declaration in function " << si->name << "\n" << endl;
				error_count++;
			}
			else
			{
				for(int i = 0; i < s->params.size(); i++)
				{
					if(s->params[i] != si->params[i])
					{
						logout<<"Error at line "<<no_of_lines<<": "<<i+1<<"th argument mismatch in function "<<si->name<<"\n"<<endl;
    					errout<<"Error at line "<<no_of_lines<<": "<<i+1<<"th argument mismatch in function "<<si->name<<"\n"<<endl;
    					error_count++;
						break;
					}
				}
			}
			s->setFunctionDec(false);
		}
	}
	else
	{
		SymbolInfo *s = symbolTable->lookup(si->name);
		s->setFunctionDec(false);

		for(int i = 0; i < parameters.size(); i++)
		{
			if(parameters[i]->name == "dummy")
			{
				logout<<"Error at line "<<no_of_lines<<": "<<i+1<<"th parameter's name not given in function definition of "<<s->name<<"\n"<<endl;
    			errout<<"Error at line "<<no_of_lines<<": "<<i+1<<"th parameter's name not given in function definition of "<<s->name<<"\n"<<endl;
    			error_count++;
			}
		}
	}
}

%}

%error-verbose

%union {
	SymbolInfo *symbolInfo;
	NonTerminal *nonTerminal;
}
%token <symbolInfo> IF FOR DO INT FLOAT VOID SWITCH DEFAULT ELSE WHILE BREAK CHAR DOUBLE RETURN CASE CONTINUE DECOP PRINTLN
					CONST_INT CONST_FLOAT ID ADDOP MULOP INCOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON
%type <nonTerminal> start program unit var_declaration func_declaration func_definition type_specifier parameter_list compound_statement statements
					declaration_list statement expression expression_statement logic_expression rel_expression simple_expression term unary_expression 
					factor variable argument_list arguments  

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE


%%

start : program
	{
		logout << "Line " << no_of_lines << ": start : program\n" << endl;
		//write your code in this block in all the similar blocks below
		$$ = new NonTerminal();
		$$->text = $1->text;		
	}
	;

program : program unit 
	{
		logout << "Line " << no_of_lines << ": program : program unit\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += "\n";
		$$->text += $2->text;

		logout << $$->text << "\n" << endl;
	}
	| unit
	{
		logout << "Line " << no_of_lines << ": program : unit\n" << endl;
		
		$$ = new NonTerminal();
		$$->text = $1->text;

		logout << $$->text << "\n" << endl;
	}
	;
	
unit : var_declaration
	{
		logout << "Line " << no_of_lines << ": unit : var_declaration\n" << endl;
		
		$$ = new NonTerminal();
		$$->text = $1->text;

		logout << $$->text << "\n" << endl;
	}
    | func_declaration
	{
		logout << "Line " << no_of_lines << ": unit : func_declaration\n" << endl;
		
		$$ = new NonTerminal();
		$$->text = $1->text;

		logout << $$->text << "\n" << endl;
	}
    | func_definition
	{
		logout << "Line " << no_of_lines << ": unit : func_definition\n" << endl;
		
		$$ = new NonTerminal();
		$$->text = $1->text;

		logout << $$->text << "\n" << endl;
	}
    ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
	{
		logout << "Line " << no_of_lines << ": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n" << endl;
		
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += " ";
		$$->text += $2->name;
		$$->text += "(";
		$$->text += $4->text;
		$$->text += ")";
		$$->text += ";";

		logout << $$->text << "\n" << endl;

		//set return type of func
		$2->setTypeSpecification($1->text);
		$2->setFunction(true);
		$2->setFunctionDec(true);

		for(auto temp_p : parameters)
		{
			$2->addParam(temp_p->typeSpecification);
		}

		if(symbolTable->insert($2))
		{
			SymbolInfo* s = symbolTable->lookup($2->name);
			s->setFunctionDec(true); //marked as function dec
		}
		else 
		{
			logout << "Error at line no " << no_of_lines << ": Multiple declaration of " << $2->name << "\n" << endl;
			errout << "Error at line no " << no_of_lines << ": Multiple declaration of " << $2->name << "\n" << endl;
			error_count++; 
		}

		parameters.clear();
	}
	| type_specifier ID LPAREN RPAREN SEMICOLON
	{
		logout << "Line " << no_of_lines << ": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += " ";
		$$->text += $2->name;
		$$->text += "(";
		$$->text += ")";
		$$->text += ";";

		logout << $$->text << "\n" << endl;

		//set return type of func
		$2->setTypeSpecification($1->text);
		$2->setFunction(true);
		$2->setFunctionDec(true);

		if(symbolTable->insert($2))
		{
			SymbolInfo* s = symbolTable->lookup($2->name);
			s->setFunctionDec(true); //marked as function dec
			//symbolTable->printAll(logout);
		}
		else 
		{
			logout << "Error at line no " << no_of_lines << ": Multiple declaration of " << $2->name << "\n" << endl;
			errout << "Error at line no " << no_of_lines << ": Multiple declaration of " << $2->name << "\n" << endl;
			error_count++; 
		}

		parameters.clear();
	}
	;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN {func = true; insert_function($2, $1->text);} compound_statement
	{
		logout << "Line " << no_of_lines << ": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += " ";
		$$->text += $2->name;
		$$->text += "(";
		$$->text += $4->text;
		$$->text += ")";
		$$->text += $7->text;

		logout << $$->text << "\n" << endl;

		func = false;
		parameters.clear();
	}
	| type_specifier ID LPAREN RPAREN {func = true; insert_function($2, $1->text);} compound_statement
	{
		logout << "Line " << no_of_lines << ": func_definition : type_specifier ID LPAREN RPAREN compound_statement\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += " ";
		$$->text += $2->name;
		$$->text += "(";
		$$->text += ")";
		$$->text += $6->text;

		logout << $$->text << "\n" << endl;

		$2->setTypeSpecification($1->text);
		$2->setFunction(true);
		symbolTable->insert($2);

		parameters.clear();
	}
 	;				


parameter_list  : parameter_list COMMA type_specifier ID
	{
		logout << "Line " << no_of_lines << ": parameter_list : parameter_list COMMA type_specifier ID\n" << endl;

		$$ = new NonTerminal();

		$$->text = $1->text;
		$$->text += ",";
		$$->text += $3->text;
		$$->text += " ";
		$$->text += $4->name;

		logout << $$->text << "\n" << endl;
		
		$4->setTypeSpecification($3->text);
		parameters.push_back($4);
	}
	| parameter_list COMMA type_specifier
	{
		logout << "Line " << no_of_lines << ": parameter_list: parameter_list COMMA type_specifier\n" << endl;
	
		$$ = new NonTerminal();

		$$->text = $1->text;
		$$->text += ",";
		$$->text += $3->text;

		logout << $$->text << "\n" << endl;

		SymbolInfo *s = new SymbolInfo("dummy", "dummy");
		s->setTypeSpecification($3->text);

		parameters.push_back(s);
	}
 	| type_specifier ID
	{
		logout << "Line " << no_of_lines << ": parameter_list : type_specifier ID\n" << endl;
	
		$$ = new NonTerminal();

		$$->text = $1->text;
		$$->text += " ";
		$$->text += $2->name;

		logout << $$->text << "\n" << endl;

		$2->setTypeSpecification($1->text);
		parameters.push_back($2);
	}
	| type_specifier
	{
		logout << "Line " << no_of_lines << ": parameter_list : type_specifier\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;

		logout << $$->text << "\n" << endl;

		SymbolInfo *s = new SymbolInfo("dummy", "dummy");
		s->setTypeSpecification($1->text);

		parameters.push_back(s);
	}
 	;

 		
compound_statement : LCURL scope statements RCURL
	{
		logout << "Line " << no_of_lines << ": compound_statement : LCURL statements RCURL\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = "{\n";
		$$->text += $3->text;
		$$->text += "\n}";

		logout << $$->text << "\n" << endl;

		symbolTable->printAll(logout);
		symbolTable->exitScope();
	}
 	| LCURL scope RCURL
	{
		logout << "Line " << no_of_lines << ": compound_statement : LCUR RCURL\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = "{";
		$$->text += "}";

		logout << $$->text << "\n" << endl;

		symbolTable->printAll(logout);
		symbolTable->exitScope();
	}
 	;

scope: {
		symbolTable->enterScope(bucketsize);

		if(func)
		{
			for(auto temp_p : parameters)
			{
				if(temp_p->name == "dummy")
				{
					continue;
				}
				if(!symbolTable->insert(temp_p))
				{
					logout << "Error at line no " << no_of_lines << ": Multiple declaration of " << temp_p->name << "\n" << endl;
					errout << "Error at line no " << no_of_lines << ": Multiple declaration of " << temp_p->name << "\n" << endl;
					error_count++;
				}
			}
		}
		
}

var_declaration : type_specifier declaration_list SEMICOLON
	{
		logout << "Line " << no_of_lines << ": var_declaration : type_specifier declaration_list SEMICOLON\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += " ";
		$$->text += $2->text;
		$$->text += ";";

		logout << $$->text << "\n" << endl;

		if($1->text == "void")
		{
			logout << "Error at line no " << no_of_lines << ": Variable type cannot be void " << "\n" << endl;
			errout << "Error at line no " << no_of_lines << ": Variable type cannot be void " << "\n" << endl;
			error_count++;
		}
		else 
		{
			for(auto temp_p : $2->si) 
			{
				if(temp_p->typeSpecification == "array")
					temp_p->setTypeSpecification($1->text + "_array");
				else temp_p->setTypeSpecification($1->text);

				if(!symbolTable->insert(temp_p))
				{
					logout << "Error at line no " << no_of_lines << ": Multiple declaration of " << temp_p->name << "\n" << endl;
					errout << "Error at line no " << no_of_lines << ": Multiple declaration of " << temp_p->name << "\n" << endl;
					error_count++;
				}
			}
		}
	}
 	;
 		 
type_specifier	: INT
	{
		logout << "Line " << no_of_lines << ": type_specifier : INT\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->name;

		logout << $$->text << "\n" << endl;
	}
 	| FLOAT
	{
		logout << "Line " << no_of_lines << ": type_specifier : FLOAT\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->name;
		
		logout << $$->text << "\n" << endl;
	}
 	| VOID
	{
		logout << "Line " << no_of_lines << ": type_specifier : VOID\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->name;
		
		logout << $$->text << "\n" << endl;
	}
 	;
 		
declaration_list : declaration_list COMMA ID
	{
		logout << "Line " << no_of_lines << ": declaration_list : declaration_list COMMA ID\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += ",";
		$$->text += $3->name;

		logout << $$->text << "\n" << endl;

		$$->setType($1->type);

		$$->setVector($1->si);
		$$->si.push_back($3);
	}
 	| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
	{
		logout << "Line " << no_of_lines << ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += ",";
		$$->text += $3->name;
		$$->text += "[";
		$$->text += $5->name;
		$$->text += "]";

		logout << $$->text << "\n" << endl;

		$$->setType($1->type);

		$$->setVector($1->si);
		$3->setTypeSpecification("array");
		$$->si.push_back($3);
	}
	| declaration_list COMMA ID LTHIRD CONST_FLOAT RTHIRD
	{
		//floating point array index

		logout << "Line " << no_of_lines << ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += ",";
		$$->text += $3->name;
		$$->text += "[";
		$$->text += $5->name;
		$$->text += "]";

		logout << $$->text << "\n" << endl;

		$$->setType($1->type);

		$$->setVector($1->si);
		$3->setTypeSpecification("array");
		$$->si.push_back($3);
		
		logout<<"Error at line "<<no_of_lines<<": Non-integer Array Size\n"<<endl;
    	errout<<"Error at line "<<no_of_lines<<": Non-integer Array Size\n"<<endl;
    	error_count++;
	}
 	| ID
	{
		logout << "Line " << no_of_lines << ": declaration_list : ID\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->name;
		
		logout << $$->text << "\n" << endl;

		$$->si.push_back($1);

	}
 	| ID LTHIRD CONST_INT RTHIRD
	{
		logout << "Line " << no_of_lines << ": declaration_list : ID LTHIRD CONST_INT RTHIRD\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->name;
		$$->text += "[";
		$$->text += $3->name;
		$$->text += "]";

		logout << $$->text << "\n" << endl;

		$1->setTypeSpecification("array");
		$$->si.push_back($1);
	}
	| ID LTHIRD CONST_FLOAT RTHIRD
	{
		logout << "Line " << no_of_lines << ": declaration_list : ID LTHIRD CONST_INT RTHIRD\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->name;
		$$->text += "[";
		$$->text += $3->name;
		$$->text += "]";

		logout << $$->text << "\n" << endl;

		$1->setTypeSpecification("array");
		$$->si.push_back($1);

		logout<<"Error at line "<<no_of_lines<<": Non-integer Array Size\n"<<endl;
    	errout<<"Error at line "<<no_of_lines<<": Non-integer Array Size\n"<<endl;
    	error_count++;
	}
 	;
 		  
statements : statement
	{
		logout << "Line " << no_of_lines << ": statements : statement\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		
		logout << $$->text << "\n" << endl;
	}
	| statements statement
	{
		logout << "Line " << no_of_lines << ": statements : statements statement\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += "\n";
		$$->text += $2->text;

		logout << $$->text << "\n" << endl;
	}
	;
	   
statement : var_declaration
	{
		logout << "Line " << no_of_lines << ": statement : var_declaration\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		
		logout << $$->text << "\n" << endl;
	}
	| expression_statement
	{
		logout << "Line " << no_of_lines << ": statement : expression_statement\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		
		logout << $$->text << "\n" << endl;
	}
	| compound_statement
	{
		logout << "Line " << no_of_lines << ": statement : compound_statement\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		
		logout << $$->text << "\n" << endl;
	}
	| FOR LPAREN expression_statement expression_statement expression RPAREN statement
	{
		logout << "Line " << no_of_lines << ": statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = "for";
		$$->text += "(";
		$$->text += $3->text;
		$$->text += $4->text;
		$$->text += $5->text;
		$$->text += ")";
		$$->text += $7->text;

		logout << $$->text << "\n" << endl;
	}
	| IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	{
		logout << "Line " << no_of_lines << ": statement : IF LPAREN expression RPAREN statement\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = "if";
		$$->text += "(";
		$$->text += $3->text;
		$$->text += ")";
		$$->text += $5->text;

		logout << $$->text << "\n" << endl;
	}
	| IF LPAREN expression RPAREN statement ELSE statement
	{
		logout << "Line " << no_of_lines << ": statement : IF LPAREN expression RPAREN statement ELSE statement\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = "if";
		$$->text += "(";
		$$->text += $3->text;
		$$->text += ")";
		$$->text += $5->text;
		$$->text += "\nelse";
		$$->text += $7->text;

		logout << $$->text << "\n" << endl;
	}
	| WHILE LPAREN expression RPAREN statement
	{
		logout << "Line " << no_of_lines << ": statement : WHILE LPAREN expression RPAREN statement\n" << endl;

		$$ = new NonTerminal();
		$$->text = "while";
		$$->text += "(";
		$$->text += $3->text;
		$$->text += ")";
		$$->text += $5->text;

		logout << $$->text << "\n" << endl;
	}
	| PRINTLN LPAREN ID RPAREN SEMICOLON
	{
		logout << "Line " << no_of_lines << ": statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = "printf";
		$$->text += "(";
		$$->text += $3->name;
		$$->text += ")";
		$$->text += ";";

		logout << $$->text << "\n" << endl;

		SymbolInfo *s = symbolTable->lookup($3->name);

		if(s == NULL)
		{
			logout<<"Error at line "<<no_of_lines<<": Undeclared variable "<<$3->name<<"\n"<<endl;
    		errout<<"Error at line "<<no_of_lines<<": Undeclared variable "<<$3->name<<"\n"<<endl;
    		error_count++;
			$$->setType("NULL");
		}
	}
	| RETURN expression SEMICOLON
	{
		logout << "Line " << no_of_lines << ": statement : RETURN expression SEMICOLON\n" << endl;

		$$ = new NonTerminal();
		$$->text = "return";
		$$->text += " ";
		$$->text += $2->text;
		$$->text += ";";

		logout << $$->text << "\n" << endl;
	}
	;
	  
expression_statement 	: SEMICOLON
	{
		logout << "Line " << no_of_lines << ": expression_statement : SEMICOLON\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = ";";

		logout << $$->text << "\n" << endl;
	}			
	| expression SEMICOLON
	{
		logout << "Line " << no_of_lines << ": expression_statement : expression SEMICOLON\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += ";";
		
		logout << $$->text << "\n" << endl;
	} 
	;
	  
variable : ID
	{
		logout << "Line " << no_of_lines << ": variable : ID\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->name;

		logout << $$->text << "\n" << endl;

		SymbolInfo *s = symbolTable->lookup($1->name);

		if(s == NULL)
		{
			logout<<"Error at line "<<no_of_lines<<": Undeclared variable "<<$1->name<<"\n"<<endl;
    		errout<<"Error at line "<<no_of_lines<<": Undeclared variable "<<$1->name<<"\n"<<endl;
    		error_count++;
			$$->setType("NULL");
		}
		else
		{
			if(s->typeSpecification == "int_array" || s->typeSpecification == "float_array")
			{
				logout<<"Error at line "<<no_of_lines<<": Type mismatch "<<$1->name<<" is not an array\n"<<endl;
    			errout<<"Error at line "<<no_of_lines<<": Type mismatch "<<$1->name<<" is not an array\n"<<endl;
    			error_count++;
				$$->setType("NULL");
			}
			else
			{
				$$->setType(s->typeSpecification);
			}
		}
	} 		
	| ID LTHIRD expression RTHIRD 
	{
		logout << "Line " << no_of_lines << ": variable : ID LTHIRD expression RTHIRD\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->name;
		$$->text += "[";
		$$->text += $3->text;
		$$->text += "]";
		
		logout << $$->text << "\n" << endl;

		SymbolInfo *s = symbolTable->lookup($1->name);

		if(s == NULL)
		{
			logout<<"Error at line "<<no_of_lines<<": Undeclared variable "<<$1->name<<"\n"<<endl;
    		errout<<"Error at line "<<no_of_lines<<": Undeclared variable "<<$1->name<<"\n"<<endl;
    		error_count++;
			$$->setType("NULL");
		}
		else
		{
			if(s->typeSpecification == "int" || s->typeSpecification == "float")
			{
				logout<<"Error at line "<<no_of_lines<<": " <<$1->name<<" is not an array\n"<<endl;
    			errout<<"Error at line "<<no_of_lines<<": " <<$1->name<<" is not an array\n"<<endl;
    			error_count++;
				$$->setType("NULL");
			}
			else
			{
				$$->setType(s->typeSpecification);
			}
		}

		if($3->type != "int")
		{
			logout<<"Error at line "<<no_of_lines<<": Non-integer array index\n"<<endl;
    		errout<<"Error at line "<<no_of_lines<<": Non-integer array index\n"<<endl;
    		error_count++;
		}
	}
	;
	 
expression : logic_expression
	{
		logout << "Line " << no_of_lines << ": expression : logic_expression\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->text;
		
		$$->setType($1->type);
		logout << $$->text << "\n" << endl;
	}	
	| variable ASSIGNOP logic_expression
	{
		logout << "Line " << no_of_lines << ": expression : variable ASSIGNOP logic_expression\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += "=";
		$$->text += $3->text;
		
		if(!assignOp($1->type, $3->type))
		{
			if($1->type == "void" || $3->type == "void")
			{
				logout<<"Error at line "<<no_of_lines<<": Void type used in expression\n"<<endl;
    			errout<<"Error at line "<<no_of_lines<<": Void type used in expression\n"<<endl;
   	 			error_count++;
			}
			else
			{
				logout<<"Error at line "<<no_of_lines<<": Type mismatch \n"<<endl;
    			errout<<"Error at line "<<no_of_lines<<": Type mismatch \n"<<endl;
    			error_count++;
			}
		}
		logout << $$->text << "\n" << endl;
	} 	
	;
			
logic_expression : rel_expression
	{
		logout << "Line " << no_of_lines << ": logic_expression : rel_expression\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;

		$$->setType($1->type);
		logout << $$->text << "\n" << endl;
	}
	| rel_expression LOGICOP rel_expression
	{
		logout << "Line " << no_of_lines << ": logic_expression : rel_expression LOGICOP rel_expression\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += $2->name;
		$$->text += $3->text;
		
		string typecast = implicit_typecast($1->type, $3->type);

		if(typecast != "NULL")
		{
			if(typecast != "error") $$->setType("int");
			else
			{
				if($1->type == "void" || $3->type == "void")
				{
					logout<<"Error at line "<<no_of_lines<<": Void type used in expression\n"<<endl;
    				errout<<"Error at line "<<no_of_lines<<": Void type used in expression\n"<<endl;
   	 				error_count++;
				}
				else
				{
					logout<<"Error at line "<<no_of_lines<<": Incompatible Operand\n"<<endl;
    				errout<<"Error at line "<<no_of_lines<<": Incompatible Operand\n"<<endl;
   	 				error_count++;
				}
				$$->setType("NULL");
			}
		}
		else
		{
			$$->setType("NULL");
		}
		
		logout << $$->text << "\n" << endl;
	} 	
	;
			
rel_expression	: simple_expression
	{
		logout << "Line " << no_of_lines << ": rel_expression : simple_expression\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		
		$$->setType($1->type);
		logout << $$->text << "\n" << endl;
	}
	| simple_expression RELOP simple_expression
	{
		logout << "Line " << no_of_lines << ": rel_expression : simple_expression RELOP simple_expression\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += $2->name;
		$$->text += $3->text;
		
		string typecast = implicit_typecast($1->type, $3->type);

		if(typecast != "NULL")
		{
			if(typecast != "error") $$->setType("int");
			else
			{
				if($1->type == "void" || $3->type == "void")
				{
					logout<<"Error at line "<<no_of_lines<<": Void type used in expression\n"<<endl;
    				errout<<"Error at line "<<no_of_lines<<": Void type used in expression\n"<<endl;
   	 				error_count++;
				}
				else
				{
					logout<<"Error at line "<<no_of_lines<<": Incompatible Operand\n"<<endl;
    				errout<<"Error at line "<<no_of_lines<<": Incompatible Operand\n"<<endl;
   	 				error_count++;
				}
				$$->setType("NULL");
			}
		}
		else
		{
			$$->setType("NULL");
		}

		logout << $$->text << "\n" << endl;
	}	
	;
				
simple_expression : term
	{
		logout << "Line " << no_of_lines << ": simple_expression : term\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;

		$$->setType($1->type);
		logout << $$->text << "\n" << endl;
	}
	| simple_expression ADDOP term
	{
		logout << "Line " << no_of_lines << ": simple_expression : simple_expression ADDOP term\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += $2->name;
		$$->text += $3->text;
		
		string typecast = implicit_typecast($1->type, $3->type);

		if(typecast != "NULL")
		{
			if(typecast != "error") $$->setType("int");
			else
			{
				if($1->type == "void" || $3->type == "void")
				{
					logout<<"Error at line "<<no_of_lines<<": Void type used in expression\n"<<endl;
    				errout<<"Error at line "<<no_of_lines<<": Void type used in expression\n"<<endl;
   	 				error_count++;
				}
				else
				{
					logout<<"Error at line "<<no_of_lines<<": Incompatible Operand\n"<<endl;
    				errout<<"Error at line "<<no_of_lines<<": Incompatible Operand\n"<<endl;
   	 				error_count++;
				}
				$$->setType("NULL");
			}
		}
		else
		{
			$$->setType("NULL");
		}

		logout << $$->text << "\n" << endl;
	} 
	;
					
term :	unary_expression
	{
		logout << "Line " << no_of_lines << ": term : unary_expression\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->text;
		
		$$->setType($1->type);
		logout << $$->text << "\n" << endl;
	}
    |  term MULOP unary_expression
	{
		logout << "Line " << no_of_lines << ": term : term MULOP unary_expression\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += $2->name;
		$$->text += $3->text;

		string typecast = implicit_typecast($1->type, $3->type);
		if($2->name == "%")
		{
			if($3->text == "0")
			{
				logout<<"Error at line "<<no_of_lines<<": Modulus by zero\n"<<endl;
    			errout<<"Error at line "<<no_of_lines<<": Modulus by zero\n"<<endl;
   	 			error_count++;
				$$->setType("NULL");
			}
			else 
			{
				if(typecast != "int")
				{
					logout<<"Error at line "<<no_of_lines<<": Non-integer operand on modulus operation\n"<<endl;
    				errout<<"Error at line "<<no_of_lines<<": Non-integer operand on modulus operation\n"<<endl;
   	 				error_count++;
					$$->setType("NULL");
				}
				else
				{
					$$->setType("int");
				}
			}
		}
		else
		{
			if(typecast != "NULL")
			{
				if(typecast != "error") $$->setType("int");
				else
				{
					if($1->type == "void" || $3->type == "void")
					{
						logout<<"Error at line "<<no_of_lines<<": Void type used in expression\n"<<endl;
    					errout<<"Error at line "<<no_of_lines<<": Void type used in expression\n"<<endl;
   	 					error_count++;
					}
					else
					{
						logout<<"Error at line "<<no_of_lines<<": Incompatible Operand\n"<<endl;
    					errout<<"Error at line "<<no_of_lines<<": Incompatible Operand\n"<<endl;
   	 					error_count++;
					}
					$$->setType("NULL");
				}
			}
			else
			{
				$$->setType("NULL");
			}
		}

		logout << $$->text << "\n" << endl;
	}
    ;

unary_expression : ADDOP unary_expression
	{
		logout << "Line " << no_of_lines << ": unary_expression : ADDOP unary_expression\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->name;
		$$->text += $2->text;
		
		$$->setType($2->type);
		logout << $$->text << "\n" << endl;
	}
	| NOT unary_expression
	{
		logout << "Line " << no_of_lines << ": unary_expression : NOT unary_expression\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->name;
		$$->text += $2->text;
		
		$$->setType($2->type);
		logout << $$->text << "\n" << endl;
	} 
	| factor
	{
		logout << "Line " << no_of_lines << ": unary_expression : factor\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->text;
		
		$$->setType($1->type);
		logout << $$->text << "\n" << endl;
	} 
	;
	
factor	: variable
	{
		logout << "Line " << no_of_lines << ": factor : variable\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->text;
		
		$$->setType($1->type);
		logout << $$->text << "\n" << endl;
	} 
	| ID LPAREN argument_list RPAREN
	{
		logout << "Line " << no_of_lines << ": factor : ID LPAREN argument_list RPAREN\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->name;
		$$->text += "(";
		$$->text += $3->text;
		$$->text += ")";

		SymbolInfo *s = symbolTable->lookup($1->name);

		if(s == NULL)
		{
			logout<<"Error at line "<<no_of_lines<<": Undeclared function "<<$1->name<<"\n"<<endl;
    		errout<<"Error at line "<<no_of_lines<<": Undeclared function "<<$1->name<<"\n"<<endl;
    		error_count++;
			$$->setType("NULL");
		}
		else
		{
			$1->params = $3->param_v;
			if(!s->isFunction)
			{
				$$->setType("NULL");
				logout << "Error at line " << no_of_lines << ": " << $1->name << " is not a function\n"<<endl;
    			errout << "Error at line " << no_of_lines << ": " << $1->name << " is not a function\n"<<endl;
    			error_count++;
				break;
			}
			$$->setType(s->typeSpecification);

			if(s->isFunctionDec)
			{
				logout << "Error at line " << no_of_lines << ": Function not implemented\n"<<endl;
    			errout << "Error at line " << no_of_lines << ": Function not implemented\n"<<endl;
    			error_count++;
			}
			else
			{
				if(s->params.size() != $1->params.size())
				{
					logout << "Error at line no " << no_of_lines << ": Total number of arguments mismatch with declaration in function " << $1->name << "\n" << endl;
					errout << "Error at line no " << no_of_lines << ": Total number of arguments mismatch with declaration in function " << $1->name << "\n" << endl;
					error_count++;
				}
				else
				{
					for(int i = 0; i < s->params.size(); i++)
					{
						if(s->params[i] != $1->params[i])
						{
							logout<<"Error at line "<<no_of_lines<<": "<<i+1<<"th argument mismatch in function "<<$1->name<<"\n"<<endl;
    						errout<<"Error at line "<<no_of_lines<<": "<<i+1<<"th argument mismatch in function "<<$1->name<<"\n"<<endl;
    						error_count++;
							break;
						}
					}
				}
			}
		}
		logout << $$->text << "\n" << endl;
	}
	| LPAREN expression RPAREN
	{
		logout << "Line " << no_of_lines << ": factor : LPAREN expression RPAREN\n" << endl;

		$$ = new NonTerminal();
		$$->text += "(";
		$$->text += $2->text;
		$$->text += ")";
		
		$$->setType($2->type);
		logout << $$->text << "\n" << endl;
	}
	| CONST_INT
	{
		logout << "Line " << no_of_lines << ": factor : CONST_INT\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->name;

		$$->setType("int");
		logout << $$->text << "\n" << endl;
	} 
	| CONST_FLOAT
	{
		logout << "Line " << no_of_lines << ": factor : CONST_FLOAT\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->name;
		
		$$->setType("float");
		logout << $$->text << "\n" << endl;
	}
	| variable INCOP
	{
		logout << "Line " << no_of_lines << ": factor : variable INCOP\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += "++";
		
		logout << $$->text << "\n" << endl;
	} 
	| variable DECOP
	{
		logout << "Line " << no_of_lines << ": factor : variable DECOP\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += "--";
		
		logout << $$->text << "\n" << endl;
	}
	;
	
argument_list : arguments
	{
		logout << "Line " << no_of_lines << ": argument_list : arguments\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->text;
		
		logout << $$->text << "\n" << endl;

		$$->param_v = $1->param_v;
	}
	|
	{
		logout << "Line " << no_of_lines << ": argument_list : \n" << endl;

		$$ = new NonTerminal();
	}
	;
	
arguments : arguments COMMA logic_expression
	{
		logout << "Line " << no_of_lines << ": arguments : arguments COMMA logic_expression\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += ",";
		$$->text += $3->text;
		
		logout << $$->text << "\n" << endl;

		$$->param_v = $1->param_v;
		$$->param_v.push_back($3->type);
	}
	| logic_expression
	{
		logout << "Line " << no_of_lines << ": arguments : logic_expression\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->text;
		
		logout << $$->text << "\n" << endl;

		$$->param_v.push_back($1->type);
	}
	;
 

%%
int main(int argc,char *argv[])
{

	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}

    logout.open("log.txt");
	errout.open("error.txt");

    yyin=fin;
	yyparse();

	symbolTable->printAll(logout);
    logout<<"Total lines: "<<no_of_lines<<endl;
    logout<<"Total errors: "<<error_count<<endl;

    fclose(yyin);

    logout.close();
	errout.close();

    exit(0);
}

