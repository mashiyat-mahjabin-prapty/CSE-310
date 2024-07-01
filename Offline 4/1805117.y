%{
#include<bits/stdc++.h>
#include "1805117_symbolTable.cpp"
using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;

ofstream logout;
ofstream errout;
ofstream codeout;
ofstream opt_codeout;

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

string currentFuncName = "";

void insert_function(SymbolInfo* si, string ret_type)
{
	currentFuncName = si->name;

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


//code gen

int labelCount = 0;

vector<string> allVar;

int stack_pointer = 0;

void increment_stack_pointer(int arr_size = -1)
{
	if(arr_size == -1) stack_pointer += 2;
	else stack_pointer += arr_size*2;
}

int offset = 0;

int nextOffset()
{
	offset += 2;
	return offset;
}

string newLabel()
{
	string label;
	label = "L" + to_string(labelCount);
	labelCount++;
	return label;
}

string stack_addr(int stack_offset)
{
	return "[BP-"+to_string(stack_offset)+"]";
}

string global_variable(string str)
{
	vector<string> str1;

	int start;
	int end = 0;

	while((start = str.find_first_not_of('[', end)) != string::npos)
	{
		end = str.find('[', start);
		str1.push_back(str.substr(start, end-start));
	}

	int s =  str1.size();

	if(s == 1) return str1[0];
	else return str1[0]+"BX";
}

//optimized code
vector<string> tokenize(string str, char delimiter)
{
	vector<string> tokens;

	size_t start;
	size_t end = 0;

	while((start = str.find_first_not_of(delimiter, end)) != string::npos)
	{
		end = str.find(delimiter, start);
		tokens.push_back(str.substr(start, end-start));
	}

	return tokens;
}

void opt_code_gen(string code)
{
	deque<string> opt;
	vector<string> lines = tokenize(code, '\n');

	string previous_first_reg = "";
	string previous_second_reg = "";
	vector<string> previous_tokens;
	vector<string> prev_t;

	for(int i = 0; i < lines.size(); i++)
	{
		string current = lines[i];
		vector<string> current_tokens;

		if(current != "")
		{	
			if(current[1] == ';')
			{
				current = current + "\n";
				opt.push_back(current);
				continue;
			}
			vector<string> cur_t = tokenize(current, ' ');
			vector<string> first_reg = tokenize(cur_t[0], ' ');
			vector<string> second_reg;

			if(cur_t[0] == "MOV")
			{
				current_tokens = tokenize(current, ',');
				second_reg = tokenize(current_tokens[1], ' ');

				if(prev_t[0] == "MOV")
				{
					if(i > 0)
					{
						if(second_reg[0] == previous_first_reg && first_reg[1] == previous_second_reg)
						{
							opt.pop_back();
						}
						else
						{
							current = current + "\n";
							opt.push_back(current);
						}
					}
				}
				previous_first_reg = first_reg[1];
				previous_second_reg = second_reg[0];
			}
			else if(cur_t[0] == "POP")
			{
				if(i > 0)
				{
					if(prev_t[1] == "PUSH")
					{
						if(cur_t[1] == prev_t[1])
						{
							opt.pop_back();
						}
					}
					else
					{
						current = current + "\n";
						opt.push_back(current);
					}
				}
				previous_first_reg = first_reg[1];	
			}
			else 
			{
				cout << "here1 " << current << endl;
				current = current + "\n";
				opt.push_back(current);
			}	
			prev_t = cur_t;
			previous_tokens = current_tokens;		
		}
		else
		{
			continue;
		}
		
		
	}
	cout << "here2" << endl;
	deque<string>::iterator it;
	for (it = opt.begin(); it != opt.end(); ++it)
        opt_codeout << *it; 
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
					factor variable argument_list arguments scope 

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE


%%

start : program
	{
		logout << "Line " << no_of_lines << ": start : program\n" << endl;
		
		//write your code in this block in all the similar blocks below
		$$ = new NonTerminal();

		$$->text = $1->text;
		$$->type = $1->type;

		$$->code = $1->code;

		if(error_count == 0)
		{
			string asm_header = ".MODEL SMALL\n\n.STACK 100H\n\n.DATA\n";
			
			codeout << asm_header;
			for(auto av : allVar)
			{
				codeout << av << endl;
			}
			codeout << endl;
			codeout << ".CODE" << endl;
			string c = string("PRINT PROC\n")+
				"\tPUSH BP\n"+
				"\tMOV BP, SP\n"+
				"\tSUB SP, 2\n"+

				"\tMOV AX, word ptr[BP+4]\n"+
				"\tMOV BX, 10\n\n"+
				"\tXOR CX, CX\n"+
				"\tXOR DX, DX\n"+
				"\t; check if negative number\n"+
				"\tCMP AX, 0\n"+
				"\tJNL OUTPUT_LOOP\n"+
				"\tPUSH AX\n"+
				"\tMOV AH, 2\n"+
				"\tMOV DL, '-'\n"+
				"\tINT 21H\n"+
				"\tPOP AX\n"+
				"\tNEG AX\n\n"+

				"\tOUTPUT_LOOP:\n"+
					"\t\tXOR DX, DX\n"+
					"\t\tDIV BX\n"+
					"\t\tPUSH DX\n"+
					"\t\tINC CX\n"+
					"\t\tCMP AX, 0\n"+
					"\t\tJNE OUTPUT_LOOP\n"+
            	"\tEND_OUTPUT_LOOP:\n\n"+
        
            	"\tPRINT_NUM:\n"+
                	"\t\tPOP DX\n"+
                	"\t\tADD DX, 48\n"+
                	"\t\tMOV AH, 2\n"+
                	"\t\tINT 21H\n"+
            	"\tLOOP PRINT_NUM\n"+
            
				"\t;OUTPUT A NEW LINE\n"+
 				"\tMOV AH, 2\n"+
 				"\tMOV DL, 0AH\n"+
 				"\tINT 21H\n"+
 				"\tMOV DL, 0DH\n"+
 				"\tINT 21H\n"+

				"\tADD SP, 2\n"+
				"\tPOP BP\n"+
				"\tRET\n\n"+

				"PRINT ENDP\n\n";
				codeout << c << endl;
				codeout << $$->code << endl;

				//opt_codeout << $$->code << endl;
				opt_code_gen(c);
				opt_code_gen($$->code);
		}	

		
		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	;

program : program unit 
	{
		logout << "Line " << no_of_lines << ": program : program unit\n" << endl;

		$$ = new NonTerminal();

		$$->text = $1->text;
		$$->text += "\n";
		$$->text += $2->text;

		$$->code = $1->code;
		$$->code += $2->code;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	| unit
	{
		logout << "Line " << no_of_lines << ": program : unit\n" << endl;
		
		$$ = new NonTerminal();

		$$->text = $1->text;
		$$->type = $1->type;

		$$->code = $1->code;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	;
	
unit : var_declaration
	{
		logout << "Line " << no_of_lines << ": unit : var_declaration\n" << endl;
		
		$$ = new NonTerminal();
		
		$$->text = $1->text;
		$$->type = $1->type;

		$$->code = $1->code;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
    | func_declaration
	{
		logout << "Line " << no_of_lines << ": unit : func_declaration\n" << endl;
		
		$$ = new NonTerminal();

		$$->text = $1->text;
		$$->type = $1->type;

		$$->code = $1->code;

		stack_pointer = 0;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
    | func_definition
	{
		logout << "Line " << no_of_lines << ": unit : func_definition\n" << endl;
		
		$$ = new NonTerminal();

		$$->text = $1->text;
		$$->type = $1->type;

		$$->code = $1->code;

		stack_pointer = 0;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
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

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
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

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
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

		$$->code = $2->name + " PROC\n";

		if($2->name == "main")
		{
			$$->code += string("\tMOV AX, @DATA\n") +
						"\tMOV DS, AX\n XOR AX,AX\n";
		}

		$$->code += string("\tPUSH BP\nMOV BP, SP\n") +
					"\tSUB SP, " + to_string(offset + 2) + "\n";
		
		$$->code += $7->code+"\n";

		$$->code += "_" + $2->name + ":\n";
		cout << offset << endl;
		$$->code += "\tADD SP, " + to_string(offset + 2) + "\n";
		$$->code += "\tPOP BP\n";

		if($2->name == "main")
		{
			$$->code += string("\n\t; DOS EXIT\n") +
						"\tMOV AH, 4CH\n" +
						"\tINT 21H\n";
		}
		else
		{
			$$->code += "RET\n";
		}

		$$->code += $2->name + " ENDP\n";

		if($2->name == "main")
		{
			$$->code += "END MAIN\n";
		}

		func = false;
		parameters.clear();

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
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

		$2->setTypeSpecification($1->text);
		$2->setFunction(true);
		symbolTable->insert($2);

		$$->code = $2->name + " PROC\n";

		if($2->name == "main")
		{
			$$->code += string("\tMOV AX, @DATA\n") +
						"\tMOV DS, AX\n\tXOR AX,AX\n";
		}

		$$->code += string("\tPUSH BP\n\tMOV BP, SP\n") +
					"\tSUB SP, " + to_string(offset + 2) + "\n";
		
		$$->code += $6->code+"\n";

		$$->code += "_" + $2->name + ":\n";
		$$->code += string("\tADD SP, ") + to_string(offset + 2) + "\n";
		$$->code += "\tPOP BP\n";

		if($2->name == "main")
		{
			$$->code += string("\n\t; DOS EXIT\n") +
						"\tMOV AH, 4CH\n" +
						"\tINT 21H\n";
		}
		else
		{
			$$->code += "RET\n";
		}

		$$->code += $2->name + " ENDP\n";

		if($2->name == "main")
		{
			$$->code += "END MAIN\n";
		}

		parameters.clear();

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
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

		$4->setTypeSpecification($3->text);
		parameters.push_back($4);

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	| parameter_list COMMA type_specifier
	{
		logout << "Line " << no_of_lines << ": parameter_list: parameter_list COMMA type_specifier\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += ",";
		$$->text += $3->text;

		SymbolInfo *s = new SymbolInfo("dummy", "dummy");
		s->setTypeSpecification($3->text);

		parameters.push_back(s);
		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
 	| type_specifier ID
	{
		logout << "Line " << no_of_lines << ": parameter_list : type_specifier ID\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += " ";
		$$->text += $2->name;

		$2->setTypeSpecification($1->text);
		parameters.push_back($2);

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	| type_specifier
	{
		logout << "Line " << no_of_lines << ": parameter_list : type_specifier\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->type = $1->type;

		SymbolInfo *s = new SymbolInfo("dummy", "dummy");
		s->setTypeSpecification($1->text);

		parameters.push_back(s);

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
 	;

 		
compound_statement : LCURL scope statements RCURL
	{
		logout << "Line " << no_of_lines << ": compound_statement : LCURL statements RCURL\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = "{\n";
		$$->text += $3->text;
		$$->text += "\n}";

		$$->code = $2->code;
		$$->code += $3->code;

		symbolTable->printAll(logout);
		symbolTable->exitScope();

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
 	| LCURL scope RCURL
	{
		logout << "Line " << no_of_lines << ": compound_statement : LCUR RCURL\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = "{";
		$$->text += "}";

		$$->code = $2->code;

		symbolTable->printAll(logout);
		symbolTable->exitScope();

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
 	;

scope: {
		symbolTable->enterScope(bucketsize);

		$$ =  new NonTerminal();

		offset = 0;
		$$->code = "";
		int val = 4;

		if(func)
		{
			for(auto temp_p : parameters)
			{
				if(temp_p->name == "dummy")
				{
					continue;
				}
				if(temp_p->type == "void")
				{
					logout << "Error at line " << no_of_lines << ": Variable type cannot be void\n" << endl;
    				errout << "Error at line " << no_of_lines << ": Variable type cannot be void\n" << endl;
    				error_count++;
					temp_p->type = "NULL";
				}

				
				temp_p->stack_offset = nextOffset();

				if(!symbolTable->insert(temp_p))
				{
					logout << "Error at line no " << no_of_lines << ": Multiple declaration of " << temp_p->name << "\n" << endl;
					errout << "Error at line no " << no_of_lines << ": Multiple declaration of " << temp_p->name << "\n" << endl;
					error_count++;
				}

				$$->code += "\tMOV AX, [BP+" + to_string(val) + "]\n";
				$$->code += "\tMOV " + stack_addr(temp_p->stack_offset) + ", AX\n";
				val += 2; 
				//<< here 

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
				{
					temp_p->setTypeSpecification($1->text + "_array");

					if(symbolTable->isGlobal())
					{
						temp_p->stack_offset = 0;
						allVar.push_back(temp_p->name + " DW " + to_string(temp_p->arr_sz) + " dup(?)");
					}
					else 
					{
						offset += temp_p->arr_sz * 2;
						temp_p->stack_offset = offset;
					}
				}
	
				else
				{
					temp_p->setTypeSpecification($1->text);

					if(symbolTable->isGlobal())
					{
						temp_p->stack_offset = 0;
						allVar.push_back(temp_p->name + " dw ?");
					}
					else 
					{
						temp_p->stack_offset = nextOffset();
					}
					temp_p->arr_sz = 0;
				} 

				if(!symbolTable->insert(temp_p))
				{
					logout << "Error at line no " << no_of_lines << ": Multiple declaration of " << temp_p->name << "\n" << endl;
					errout << "Error at line no " << no_of_lines << ": Multiple declaration of " << temp_p->name << "\n" << endl;
					error_count++;
				}
			}
		}
		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
 	;
 		 
type_specifier	: INT
	{
		logout << "Line " << no_of_lines << ": type_specifier : INT\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->name;
		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
 	| FLOAT
	{
		logout << "Line " << no_of_lines << ": type_specifier : FLOAT\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->name;
		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
 	| VOID
	{
		logout << "Line " << no_of_lines << ": type_specifier : VOID\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->name;
		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
 	;
 		
declaration_list : declaration_list COMMA ID
	{
		logout << "Line " << no_of_lines << ": declaration_list : declaration_list COMMA ID\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += ",";
		$$->text += $3->name;
		
		$$->setType($1->type);
		$3->arr_sz = 0;

		$$->setVector($1->si);
		$$->si.push_back($3);

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
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

		$$->setType($1->type);

		$$->setVector($1->si);
		$3->setTypeSpecification("array");
		$3->arr_sz = stoi($5->name);
		$$->si.push_back($3);

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	| declaration_list COMMA ID LTHIRD CONST_FLOAT RTHIRD
	{
		//floating point array index

		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += ",";
		$$->text += $3->name;
		$$->text += "[";
		$$->text += $5->name;
		$$->text += "]";

		$$->setType($1->type);

		$$->setVector($1->si);
		$3->setTypeSpecification("array");
		$$->si.push_back($3);
		
		logout<<"Error at line "<<no_of_lines<<": Non-integer Array Size\n"<<endl;
    	errout<<"Error at line "<<no_of_lines<<": Non-integer Array Size\n"<<endl;
    	error_count++;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
 	| ID
	{
		logout << "Line " << no_of_lines << ": declaration_list : ID\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->name;

		$$->si.push_back($1);
		$1->arr_sz = 0;
		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;

	}
 	| ID LTHIRD CONST_INT RTHIRD
	{
		logout << "Line " << no_of_lines << ": declaration_list : ID LTHIRD CONST_INT RTHIRD\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->name;
		$$->text += "[";
		$$->text += $3->name;
		$$->text += "]";

		$1->setTypeSpecification("array");
		$1->arr_sz = stoi($3->name);
		$$->si.push_back($1);

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;

	}
	| ID LTHIRD CONST_FLOAT RTHIRD
	{
		$$ = new NonTerminal();
		$$->text = $1->name;
		$$->text += "[";
		$$->text += $3->name;
		$$->text += "]";

		$1->setTypeSpecification("array");
		$$->si.push_back($1);

		logout<<"Error at line "<<no_of_lines<<": Non-integer Array Size\n"<<endl;
    	errout<<"Error at line "<<no_of_lines<<": Non-integer Array Size\n"<<endl;
    	error_count++;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
 	;
 		  
statements : statement
	{
		logout << "Line " << no_of_lines << ": statements : statement\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->type = $1->type;

		$$->code = $1->code;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	| statements statement
	{
		logout << "Line " << no_of_lines << ": statements : statements statement\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += "\n";
		$$->text += $2->text;

		$$->code = $1->code;
		$$->code += "\n";
		$$->code += $2->code;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	;
	   
statement : var_declaration
	{
		logout << "Line " << no_of_lines << ": statement : var_declaration\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->type = $1->type;
		
		$$->code += $1->code;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	| expression_statement
	{
		logout << "Line " << no_of_lines << ": statement : expression_statement\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->type = $1->type;
		
		$$->code += $1->code;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	| compound_statement
	{
		logout << "Line " << no_of_lines << ": statement : compound_statement\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->type = $1->type;
		
		$$->code += $1->code;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
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

		string label1 = newLabel();
		string label2 = newLabel();

		$$->code = "\t; for\n";
		$$->code += $3->code;
		$$->code += "\t" + label1 + ":\n";
		$$->code +=  $4->code + "\n";
		$$->code += "\tCMP " + stack_addr($4->stack_offset) +", 0\n";
		$$->code += "\tJE " + label2 + "\n";
		$$->code += $7->code + "\n";
		$$->code += $5->code + "\n";
		$$->code += "\tJMP " + label1 + "\n";
		$$->code += "\t" + label2 + ":\n";

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
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

		string label = newLabel();

		$$->code = "\t; if\n";
		$$->code += $3->code;
		$$->code += "\tMOV AX, 0\n";
		$$->code += "\tMOV CX, " + stack_addr($3->stack_offset) + "\n";
		$$->code += "\tCMP CX, AX\n";
		$$->code += "\tJE " + label + "\n";
		$$->code += $5->code + "\n";
		$$->code += "\t" + label + ":\n";

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
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
        $$->text += "\nelse ";
        $$->text += $7->text;
		
		string label1 = newLabel();
		string label2 = newLabel();

		$$->code = "\t; if-else\n";
		$$->code += $3->code;
		$$->code += "\tMOV AX, 0\n";
		$$->code += "\tMOV CX, " + stack_addr($3->stack_offset) + "\n";
		$$->code += "\tCMP CX, AX\n";
		$$->code += "\tJE " + label1 + "\n";
		$$->code += $5->code + "\n";
		$$->code += "\tJMP " + label2 + "\n";
				
		$$->code += "\t" + label1 + ":\n";
		$$->code += $7->code + "\n";
		$$->code += "\t" + label2 + ":\n";

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
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

		string label1 = newLabel();
		string label2 = newLabel();
	
		$$->code = "\t; while\n";
		$$->code += "\t" + label1 + ":\n";
		$$->code += $3->code + "\n";
		$$->code += "\tMOV AX, 0\n";
		$$->code += "\tMOV CX, " + stack_addr($3->stack_offset) + "\n";
		$$->code += "\tCMP CX, AX\n";
		$$->code += "\tJE " + label2 + "\n";
		$$->code +=  $5->code + "\n";
		$$->code += "\tJMP " + label1 + "\n";
		$$->code += "\t" + label2 + ":\n";

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	| PRINTLN LPAREN ID RPAREN SEMICOLON
	{
		logout << "Line " << no_of_lines << ": statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n" << endl;
	
		$$ = new NonTerminal();
		
		$$->text = "println";
        $$->text += "(";
        $$->text += $3->name;
        $$->text += ")";
        $$->text += ";";

		SymbolInfo *s = symbolTable->lookup($3->name);

		if(s == NULL)
		{
			logout<<"Error at line "<<no_of_lines<<": Undeclared variable "<<$3->name<<"\n"<<endl;
    		errout<<"Error at line "<<no_of_lines<<": Undeclared variable "<<$3->name<<"\n"<<endl;
    		error_count++;
			$$->setType("NULL");
		}

		$$->code = "\n\t; " + $$->text + "\n";
		
		if(s != NULL && s->stack_offset != 0)
			$$->code += "\tMOV AX, " + stack_addr(s->stack_offset) + "\n";
		else if(s != NULL && s->stack_offset == 0)
			$$->code += "\tMOV AX, " + $3->name + "\n";

		$$->code += "\tPUSH AX\n";
		$$->code += "\tCALL PRINT\n";
		$$->code += "\tADD SP, 2\n";

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	| RETURN expression SEMICOLON
	{
		logout << "Line " << no_of_lines << ": statement : RETURN expression SEMICOLON\n" << endl;

		$$ = new NonTerminal();
		
		$$->text = "return ";
		$$->text += $2->text;
		$$->text += ";";

		$$->code = "\t; " + $$->text + "\n"; 
		$$->code += $2->code + "\n";
		
		if($2->stack_offset != 0) 
		{
			$$->code += "\tMOV AX, " + stack_addr($2->stack_offset) + "\n";
		}
		else 
		{
			$$->code += "\tMOV AX, " + global_variable($2->text) + "\n";
		}
		$$->code += "JMP _" + currentFuncName + "\n";

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	| func_declaration
	{
		$$ = new NonTerminal();
		
		logout << "Error at line " << no_of_lines << ": A function is declared inside a function\n" << endl;
    	errout << "Error at line " << no_of_lines << ": A function is declared inside a function\n" << endl;
    	error_count++;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	| func_definition
	{
		$$ = new NonTerminal();
		
		logout << "Error at line " << no_of_lines << ": A function is defined inside a function\n" << endl;
    	errout << "Error at line " << no_of_lines << ": A function is defined inside a function\n" << endl;
    	error_count++;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	;
	  
expression_statement : SEMICOLON
	{
		logout << "Line " << no_of_lines << ": expression_statement : SEMICOLON\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = ";";

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}			
	| expression SEMICOLON
	{
		logout << "Line " << no_of_lines << ": expression_statement : expression SEMICOLON\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += ";";

		$$->code = $1->code;
		$$->stack_offset = $1->stack_offset;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	} 
	;
	  
variable : ID
	{
		logout << "Line " << no_of_lines << ": variable : ID\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->name;

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

		$$->code = "";

		if(s != NULL)
		{
			$$->stack_offset = s->stack_offset;
		}
		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	} 		
	| ID LTHIRD expression RTHIRD 
	{
		logout << "Line " << no_of_lines << ": variable : ID LTHIRD expression RTHIRD\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->name;
		$$->text += "[";
		$$->text += $3->text;
		$$->text += "]";

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

		
		if(s != NULL)
        {
			$$->arrayIndexAddress = nextOffset();
            $$->code = "\t; " + $$->text + "\n";
			//$$->code += s->code + "\n";

			$$->code += "\tMOV BX, " + stack_addr(s->stack_offset) + "\n";
			$$->code += "\tADD BX, BX\n";
				
			if($1->stack_offset == 0)
			{
				// global array
				$$->code += "\tMOV " + stack_addr($$->arrayIndexAddress) + ", BX\n";
			}
			else
			{
				// local array
				$$->code += "\tMOV AX, " + to_string($1->stack_offset) + "\n";
				$$->code += "\tSUB AX, BX\n";
				$$->code += "\tMOV " + stack_addr($$->arrayIndexAddress) + ", AX\n";
			}
				
			$$->stack_offset = $1->stack_offset;
        }
		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	;
	 
expression : logic_expression
	{
		logout << "Line " << no_of_lines << ": expression : logic_expression\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->setType($1->type);

		$$->code = $1->code;
		$$->stack_offset = $1->stack_offset;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
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

		$$->code = $3->code+"\n";
		if($3->stack_offset != 0)
		{
			$$->code += "\tMOV AX, " + stack_addr($3->stack_offset) + "\n";
		}
		else 
		{
			$$->code += "\tMOV AX, " + global_variable($3->text) + "\n";
		}
		$$->code += $1->code;
		$$->code += "\t; " + $$->text + "\n";

		if($1->arr_sz)
		{
			cout << "arr2 " << $1->arr_sz << endl;
			$$->code += "\tMOV AX, " + stack_addr($3->stack_offset) + "\n";
			
			$$->code += "\tMOV BX, " + stack_addr($1->arrayIndexAddress) + "\n";
					
			if($1->stack_offset == 0)
			{
				// global array
				//process global variable hobe
				$$->code += "\tMOV " + stack_addr($1->stack_offset) + "[BX], AX\n";
			}
			else 
			{
				$$->code += "\tPUSH BP\n";
				$$->code += "\tSUB BP, BX\n";
				$$->code += "\tMOV WORD PTR[BP], AX\n";
				$$->code += "\tPOP BP\n";
			}
		}
		else{
			if($1->stack_offset != 0)
			{
				$$->code += "\tMOV " + stack_addr($1->stack_offset) + ", AX\n";
			}
			else
			{
				$$->code += "\tMOV " + global_variable($1->text) + ", AX\n";
			}
			
			
		
		}
		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;

	} 	
	;
			
logic_expression : rel_expression
	{
		logout << "Line " << no_of_lines << ": logic_expression : rel_expression\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->setType($1->type);

		$$->code = $1->code;
		$$->stack_offset = $1->stack_offset;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
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

		$$->code = $1->code;
		$$->code += $3->code;
		$$->code += "\t; " + $$->text + "\n";

		string label1 = newLabel();
		string label2 = newLabel();
		$$->stack_offset = nextOffset();
				
		if($2->name == "&&") 
		{
			$$->code += "\tMOV AX, 0\n";
			if($1->stack_offset != 0)
			{
				$$->code += "\tMOV CX, " + stack_addr($1->stack_offset) + "\n";
			}
			else
			{
				$$->code += "\tMOV CX, " + global_variable($1->text) + "\n";
			} 
			$$->code += "\tCMP CX, AX\n";
			$$->code += "\tJE " + label1 + "\n";
			$$->code += "\tMOV AX, 0\n";
			if($3->stack_offset != 0)
			{
				$$->code += "\tMOV CX, " + stack_addr($3->stack_offset) + "\n";
			}
			else
			{
				$$->code += "\tMOV CX, " + global_variable($3->text) + "\n";
			}
			$$->code += "\tCMP CX, AX\n";
			$$->code += "\tJE " + label1 + "\n";
			$$->code += "\tMOV AX, 1\n";
			$$->code += "\tMOV " + stack_addr($$->stack_offset) + ", AX\n";
			$$->code += "\tJMP " + label2 + "\n";
			$$->code += "\t" + label1 + ":\n";
			$$->code += "\tMOV AX, 0\n";
			$$->code += "\tMOV " + stack_addr($$->stack_offset) + ", 0\n";
		}
		else 
		{
			$$->code += "\tMOV AX, 0\n";
			if($1->stack_offset != 0)
			{
				$$->code += "\tMOV CX, " + stack_addr($1->stack_offset) + "\n";
			}
			else
			{
				$$->code += "\tMOV CX, " + global_variable($1->text) + "\n";
			} 
			$$->code += "\tCMP CX, AX\n";
			$$->code += "\tJNE " + label1 + "\n";
			$$->code += "\tMOV AX, 0\n";
			if($3->stack_offset != 0)
			{
				$$->code += "\tMOV CX, " + stack_addr($3->stack_offset) + "\n";
			}
			else
			{
				$$->code += "\tMOV CX, " + global_variable($3->text) + "\n";
			}
			$$->code += "\tCMP CX, AX\n";
			$$->code += "\tJNE " + label1 + "\n";
			$$->code += "\tMOV AX, 0\n";
			$$->code += "\tMOV " + stack_addr($$->stack_offset) + ", 0\n";
			$$->code += "\tJMP " + label2 + "\n";
			$$->code += "\t" + label1 + ":\n";
			$$->code += "\tMOV AX, 1\n";
			$$->code += "\tMOV " + stack_addr($$->stack_offset) + ", AX\n";
		}
				
		$$->code += "\t" + label2 + ":\n";

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	} 	
	;
			
rel_expression	: simple_expression
	{
		logout << "Line " << no_of_lines << ": rel_expression : simple_expression\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->setType($1->type);
		
		$$->code = $1->code;
		$$->stack_offset = $1->stack_offset;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
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

		$$->stack_offset = nextOffset();
		string label1 = newLabel();
		string label2 = newLabel();
				
		$$->code = $1->code;
		$$->code += $3->code;
		//$$->code += "\t; " + $$->text + "\n";
				
		if($1->stack_offset != 0)
		{
			$$->code += "\tMOV AX, " + stack_addr($1->stack_offset) + "\n";
		}
		else 
		{
			$$->code += "\tMOV AX, " + global_variable($1->text) + "\n";
		}
		if($3->stack_offset != 0)
		{
			$$->code += "\tCMP AX, " + stack_addr($3->stack_offset) + "\n";
		}
		else
		{
			$$->code += "\tCMP AX, " + global_variable($3->text) + "\n";
		}
		
				
		if($2->name == "<")
		{
			$$->code += "\tJL " + label1 + "\n";		
		}

		else if($2->name == ">")
		{
			$$->code += "\tJG " + label1 + "\n";		
		}

		else if($2->name == "<=")
		{
			$$->code += "\tJLE " + label1 + "\n";		
		}

		else if($2->name == ">=")
		{
			$$->code += "\tJGE " + label1 + "\n";
		}
				
		else if($2->name == "==")
		{
			$$->code += "\tJE " + label1 + "\n";
		}
				
		else if($2->name == "!=")
		{
			$$->code += "\tJNE " + label1 + "\n";
		}
		
		$$->code += "\tMOV AX, 0\n";
		$$->code += "\tMOV " + stack_addr($$->stack_offset) + ", AX\n";
		$$->code += "\tJMP " + label2 + "\n";
		$$->code += "\t" + label1 + ":\n";
		$$->code += "\tMOV AX, 1\n";
		$$->code += "\tMOV " + stack_addr($$->stack_offset) + ", AX\n";
		$$->code += "\t" + label2 + ":\n";

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}	
	;
				
simple_expression : term
	{
		logout << "Line " << no_of_lines << ": simple_expression : term\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->setType($1->type);
		
		$$->code = $1->code;
		$$->stack_offset = $1->stack_offset;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
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

		$$->stack_offset = nextOffset();
		
		$$->code = $1->code;
		$$->code += $3->code;
		$$->code += "\t; " + $$->text + "\n";

		if($1->stack_offset != 0)
		{
			$$->code += "\tMOV AX, " + stack_addr($1->stack_offset) + "\n";
		}
		else
		{
			$$->code += "\tMOV AX, " + global_variable($1->text) + "\n";
		}

		if($2->name == "+")
		{
			if($3->stack_offset != 0)
			{
				$$->code += "\tADD AX, " + stack_addr($3->stack_offset)+ "\n";
			}
			else 
			{
				$$->code += "\tADD AX, " + global_variable($3->text)+ "\n";
			}
		}
		else 
		{
			if($3->stack_offset != 0)
			{
				$$->code += "\tSUB AX, " + stack_addr($3->stack_offset) + "\n";
			}
			else
			{
				$$->code += "\tSUB AX, " + global_variable($3->text) + "\n";
			}
		}
		$$->code += "\tMOV " + stack_addr($$->stack_offset) + ", AX\n";

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	} 
	;
					
term :	unary_expression
	{
		logout << "Line " << no_of_lines << ": term : unary_expression\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->setType($1->type);
		
		$$->code = $1->code;
		$$->stack_offset = $1->stack_offset;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
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
		$$->stack_offset = nextOffset();
				
		$$->code = $1->code;
		$$->code += $3->code;
		$$->code += "\t; " + $$->text  + "\n";

		if($1->stack_offset != 0)
		{
			$$->code += "\tMOV AX, " + stack_addr($1->stack_offset) + "\n";
		}		
		else
		{
			$$->code += "\tMOV AX, " + global_variable($1->text) + "\n";
		}
		
		if($3->stack_offset != 0)
		{
			$$->code += "\tMOV BX, " + stack_addr($3->stack_offset) + "\n";
		}
		else 
		{
			$$->code += "\tMOV BX, " + global_variable($3->text) + "\n";
		}
		if($2->name == "*")
		{
			$$->code += "\tMUL BX\n";
			$$->code += "\tMOV " + stack_addr($$->stack_offset) + ", AX\n"; 
		}
		else if($2->name == "%")
		{
			$$->code += "\tXOR DX, DX\n";
			$$->code += "\tDIV BX\n";
			$$->code += "\tMOV " + stack_addr($$->stack_offset) + ", DX\n";
		}
		else 
		{
			$$->code += "\tXOR DX, DX\n";
			$$->code += "\tDIV BX\n";
			$$->code += "\tMOV " + stack_addr($$->stack_offset) + ", AX\n";
		}

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
    ;

unary_expression : ADDOP unary_expression
	{
		logout << "Line " << no_of_lines << ": unary_expression : ADDOP unary_expression\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->name;
		$$->text += $2->text;
		$$->setType($2->type);
		
		$$->code = $2->code;
		$$->code += "\t; " + $$->text + "\n";

		if($1->name == "+")
		{
			$$->stack_offset = $2->stack_offset;
		}
		else
		{
			$$->stack_offset = nextOffset();
			$$->code += "\tMOV AX, " + stack_addr($2->stack_offset) + "\n"; 
			$$->code += "\tNEG AX\n";
			$$->code += "\tMOV " + stack_addr($$->stack_offset) + ", AX\n";
		}

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	| NOT unary_expression
	{
		logout << "Line " << no_of_lines << ": unary_expression : NOT unary_expression\n" << endl;
	
		$$ = new NonTerminal();
		$$->text = $1->name;
		$$->text += $2->text;
		$$->setType($2->type);
		
		$$->stack_offset = nextOffset();
		
		string label1 = newLabel();
        string label2 = newLabel();

		$$->code = $2->code+"\n";
		$$->code += "\t; " + $$->text + "\n";

        $$->code += "\tCMP "+stack_addr($2->stack_offset)+",0\n";

        $$->code += "\tJE " + label1 + "\n";

        $$->code += "\tMOV " + stack_addr($$->stack_offset) + ", 0\n";
        $$->code += "\tJMP " + label2 + "\n";

        $$->code += label1 + ":\n";
        $$->code += "\tMOV " + stack_addr($$->stack_offset) + ", 1\n";

        $$->code += label2 + ":\n";

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	} 
	| factor
	{
		logout << "Line " << no_of_lines << ": unary_expression : factor\n" << endl;

		$$ = new NonTerminal();
		$$->text == $1->text;
		$$->setType($1->type);
		
		$$->code = $1->code;
		$$->stack_offset = $1->stack_offset;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	} 
	;
	
factor	: variable
	{
		logout << "Line " << no_of_lines << ": factor : variable\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->setType($1->type);
		
		$$->code = $1->code;
		if($1->arr_sz)
		{
			//cout << "arr4 " << $1->arr_sz << endl;
			$$->stack_offset = nextOffset();
				
			$$->code += "\tMOV BX," + stack_addr($1->arrayIndexAddress) + "\n";
					
			if($1->stack_offset == 0)
			{
				// global array
				$$->code += "\tMOV AX, " + stack_addr($1->stack_offset) + "[BX]\n";
				$$->code += "\tMOV " + stack_addr($$->stack_offset) + ", AX\n";

			}
			else 
			{
				// local array
						
				$$->code += "\tPUSH BP\n";
				$$->code += "\tSUB BP, BX\n";
				$$->code += "\tMOV AX, WORD PTR[BP]\n";
				$$->code += "\tPOP BP\n";
				$$->code += "\tMOV " + stack_addr($$->stack_offset) + ", AX\n";
					
			}
		}
		else
		{
			$$->stack_offset = $1->stack_offset;
		}

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
		
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

		if(s != NULL)
        {
            $$->code = $3->code+"\n";
            $$->code += "\tCALL "+$1->name+"\n";
            $$->code += "\tADD SP, " + to_string(2*s->params.size());
			if(s->typeSpecification != "void")
        	{
                $$->stack_offset = nextOffset();
                $$->code += "\nMOV " + stack_addr($$->stack_offset) + ", AX\n";
            }
        }
		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	| LPAREN expression RPAREN
	{
		logout << "Line " << no_of_lines << ": factor : LPAREN expression RPAREN\n" << endl;

		$$ = new NonTerminal();
		$$->text = "(";
		$$->text += $2->text;
		$$->text += ")";

		$$->setType($2->type);
		
		$$->code = $2->code;
		$$->stack_offset = $2->stack_offset;
		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	| CONST_INT
	{
		logout << "Line " << no_of_lines << ": factor : CONST_INT\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->name;
		$$->setType("int");

		$$->stack_offset = nextOffset();
		$$->code = "\tMOV AX, " + $1->name + "\n";
		$$->code += "\tMOV " +stack_addr($$->stack_offset) + ", AX\n";

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	} 
	| CONST_FLOAT
	{
		logout << "Line " << no_of_lines << ": factor : CONST_FLOAT\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->name;
		$$->setType("float");

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	| variable INCOP
	{
		logout << "Line " << no_of_lines << ": factor : variable INCOP\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += "++";
		$$->setType($1->type);

		$$->code = $1->code;
		$$->code += "\t; " + $$->text + "\n";

		$$->stack_offset =  nextOffset();

		if($1->arr_sz)
		{
			
			$$->code += "\tMOV BX, " + stack_addr($1->stack_offset) + "]\n";
			if($1->stack_offset == 0)
			{
				$$->code += "\tMOV AX, " + stack_addr($1->stack_offset) + "[BX]\n";
				$$->code += "\tINC " + stack_addr($1->stack_offset) + "[BX]\n";
				$$->code += "\tMOV " + stack_addr($$->stack_offset) + ", AX\n";
			}
			else 
			{
				$$->code += "\tPUSH BP\n";
				$$->code += "\tSUB BP, BX\n";
				$$->code += "\tMOV AX, WORD PTR[BP]\n";
				$$->code += "\tMOV BX, AX\n";
				$$->code += "\tINC AX\n";
				$$->code += "\tMOV WORD PTR[BP], AX\n";
				$$->code += "\tPOP BP\n";
				$$->code += "\tMOV " + stack_addr($$->stack_offset) + ", BX\n";
			}
		}
		else
		{
			if($1->stack_offset != 0)
			{
				$$->code += "\tMOV AX, " + stack_addr($1->stack_offset) + "\n";
			}
			else
			{
				$$->code += "\tMOV AX, " + global_variable($1->text) + "\n";
			}
			$$->code += "\tMOV " + stack_addr($$->stack_offset) + ", AX\n";
			$$->code += "\tINC AX\n";
			if($1->stack_offset)
			{
				$$->code += "\tMOV " + stack_addr($1->stack_offset) + ", AX\n";
			}
			else
			{
				$$->code += "\tMOV " + global_variable($1->text) + ", AX\n";
			}
		}
		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	} 
	| variable DECOP
	{
		logout << "Line " << no_of_lines << ": factor : variable DECOP\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->text += "--";
		$$->setType($1->type);

		$$->code = $1->code;
		$$->code += "\t; " + $$->text + "\n";

		$$->stack_offset =  nextOffset();

		if($1->arr_sz)
		{
			
			$$->code += "\tMOV BX, " + stack_addr($1->stack_offset) + "]\n";
			if($1->stack_offset == 0)
			{
				$$->code += "\tMOV AX, " + stack_addr($1->stack_offset) + "[BX]\n";
				$$->code += "\tDEC " + stack_addr($1->stack_offset) + "[BX]\n";
				$$->code += "\tMOV " + stack_addr($$->stack_offset) + ", AX\n";
			}
			else 
			{
				$$->code += "\tPUSH BP\n";
				$$->code += "\tSUB BP, BX\n";
				$$->code += "\tMOV AX, WORD PTR[BP]\n";
				$$->code += "\tMOV BX, AX\n";
				$$->code += "\tDEC AX\n";
				$$->code += "\tMOV WORD PTR[BP], AX\n";
				$$->code += "\tPOP BP\n";
				$$->code += "\tMOV " + stack_addr($$->stack_offset) + ", BX\n";
			}
		}
		else
		{
			if($1->stack_offset != 0)
			{
				$$->code += "\tMOV AX, " + stack_addr($1->stack_offset) + "\n";
			}
			else
			{
				$$->code += "\tMOV AX, " + global_variable($1->text) + "\n";
			}
			$$->code += "\tMOV " + stack_addr($$->stack_offset) + ", AX\n";
			$$->code += "\tDEC AX\n";
			if($1->stack_offset)
			{
				$$->code += "\tMOV " + stack_addr($1->stack_offset) + ", AX\n";
			}
			else
			{
				$$->code += "\tMOV " + global_variable($1->text) + ", AX\n";
			}
		}

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	;
	
argument_list : arguments
	{
		logout << "Line " << no_of_lines << ": argument_list : arguments\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->text;

		$$->param_v = $1->param_v;

		$$->code = $1->code;
		$$->stack_offset = $1->stack_offset;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
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

		$$->param_v = $1->param_v;
		$$->param_v.push_back($3->type);

		$$->code = $3->code;
		$$->code += "\n";
        if($3->stack_offset != 0)
		{
			$$->code += "\tPUSH " + stack_addr($3->stack_offset) + "\n";
		} 
        else 
		{
			$$->code += "\tPUSH " + $3->text + "\n";
		}

        $$->code += $1->code;

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
	}
	| logic_expression
	{
		logout << "Line " << no_of_lines << ": arguments : logic_expression\n" << endl;

		$$ = new NonTerminal();
		$$->text = $1->text;
		$$->setType($1->type);

		$$->param_v.push_back($1->type);

		$$->code = $1->code;
		$$->stack_offset = $1->stack_offset;

		$$->code += "\n";
		if($$->stack_offset != 0)
		{
			$$->code += "\tPUSH " + stack_addr($$->stack_offset) + "\n";
		} 
        else 
		{
			$$->code += "\tPUSH " + $1->text + "\n";
		}

		logout << $$->text << endl << endl;	
		logout << $$->code << endl << endl;
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
	codeout.open("code.asm");
	opt_codeout.open("optimized_code.asm");

    yyin=fin;
	yyparse();

	symbolTable->printAll(logout);
    logout<<"Total lines: "<<no_of_lines<<endl;
    logout<<"Total errors: "<<error_count<<endl;

    fclose(yyin);

    logout.close();
	errout.close();
	codeout.close();
	opt_codeout.close();

    exit(0);
}

