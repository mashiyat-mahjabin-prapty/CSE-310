#include<bits/stdc++.h>
using namespace std;

class Function{
    public:
	vector<string> params;
	bool isFunction;
    bool isFunctionDec;

	Function()
	{
		isFunction = false;
	}
    void setFunction(bool func)
    {
        isFunction = func;
    }
    void setFunctionDec(bool declaration)
    {
        isFunctionDec = declaration;
    }
    void addParam(string param)
    {
        params.push_back(param);
    }
    int numParam()
    {
        return params.size();
    }
    string getMisMatchedParam(Function *f)
    {
        for(int i = 0; i < params.size(); i++)
        {
            if(params[i] != f->params[i])
            {
                return to_string(i+1) + "th argument mismatch in function ";
            }
        }
        return "";
    }
};

class SymbolInfo:public Function{
    public:
        string name;
        string type;
        string typeSpecification;
        int size;
        SymbolInfo *next;

        SymbolInfo() : Function()
        {
            //cout << "A new symbolInfo object created" << endl;
            this->name = "";
            this->type = "";
            this->typeSpecification = "";
            this->next = nullptr;
        }
        SymbolInfo(SymbolInfo &s) : Function()
        {
            this->name = s.name;
            this->type = s.type;
            this->typeSpecification = s.typeSpecification;
            this->size = s.size;
            this->next = s.next;
            this->params = s.params;
            this->isFunction = s.isFunction;
            this->isFunctionDec = s.isFunctionDec;
        }
        SymbolInfo(string name, string type="", string typeSpecification="", int size=0) : Function() 
        {
            //cout << "A new symbolInfo object created" << endl;
            this->name = name;
            this->type = type;
            this->typeSpecification = typeSpecification;
            this->size = size;
            this->next = nullptr;
        }
        string getName()
        {
            return this->name;
        }
        void setName(string name)
        {
            this->name = name;
        }
        string getType()
        {
            return this->type;
        }
        void setType(string type)
        {
            this->type = type;
        }
        void setTypeSpecification(string typeSpecification)
        {
            this->typeSpecification = typeSpecification;
        }
        void setSize(int size)
        {
            this->size = size;
        }
        SymbolInfo* getNext()
        {
            return next;
        }
        void setNext(SymbolInfo* next)
        {
            this->next = next;
        }
        ~SymbolInfo()
        {
            //cout << "Destroyed a symbolInfo object" << endl;
        }        
};

class NonTerminal
{
    public:
        string text;
        vector<SymbolInfo*> si;
        string type;
        vector<string> param_v;

        NonTerminal()
        {

        }
        NonTerminal(string text, vector<SymbolInfo*> si)
        {
            this->text = text;
            this->si = si;
        }
        void setText(string text)
        {
            this->text = text;
        }
        void setType(string type)
        {
            this->type = type;
        }
        void setVector(vector<SymbolInfo*> si)
        {
            this->si = si;
        }       
};