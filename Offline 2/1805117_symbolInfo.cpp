#include<iostream>
#include<string>
using namespace std;

class SymbolInfo{
    private:
        string name;
        string type;
        SymbolInfo *next;

    public:
        SymbolInfo()
        {
            //cout << "A new symbolInfo object created" << endl;
        }
        SymbolInfo(string name, string type)
        {
            //cout << "A new symbolInfo object created" << endl;
            this->name = name;
            this->type = type;

            next = NULL;
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