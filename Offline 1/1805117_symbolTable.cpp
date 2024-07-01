#include<iostream>
using namespace std;

class SymbolTable{
    private:
        scopeTable* currentScope;
    public:
       SymbolTable()
       {
           //cout << "A symbolTable created" << endl;
           currentScope = NULL;
       } 
       void enterScope(int bucketSize)
       {
           scopeTable* temp = new scopeTable(bucketSize, currentScope);
           currentScope = temp;
           //cout << "New scopeTable with id " << currentScope->getId() << " created" << endl;
           return;
       }
       void exitScope()
       {
            if(currentScope == NULL)
           {
               cout << "No scopeTable in the Symboltable" << endl;
               return;
           }
            cout << "Scopetable with id " << currentScope->getId() << " removed" << endl;
            scopeTable* temp = currentScope->getParent();
            delete currentScope;
            currentScope = temp;
       }
       bool insert(string name, string type)
       {
           if(currentScope == NULL)
           {
               cout << "No scopeTable in the Symboltable" << endl;
               return false;
           }
           return currentScope->insert(name, type);
       }
       bool deleteEntry(string name)
       {
           if(currentScope == NULL)
           {
               cout << "No scopeTable in the Symboltable" << endl;
               return false;
           }
           return currentScope->deleteEntry(name);
       }
       SymbolInfo* lookup(string name)
       {
           if(currentScope == NULL)
           {
               cout << "No scopeTable in the Symboltable" << endl;
               return NULL;
           }
           scopeTable* temp = currentScope;
           SymbolInfo* target = NULL;

            while(temp != NULL)
            {
                target = temp->lookup(name);

                if(target != NULL)
                {
                    break;
                }
                temp = temp->getParent();
            }
            return target;
       }
       void printCurrent()
       {
           if(currentScope == NULL)
           {
               cout << "No scopeTable in the Symboltable" << endl;
               return;
           }
           currentScope->print();
           return;
       }
       void printAll()
       {
           if(currentScope == NULL)
           {
               cout << "No scopeTable in the Symboltable" << endl;
               return;
           }
           scopeTable* temp = currentScope;

           while(temp != NULL)
           {
               temp->print();

               cout << endl;

               temp = temp->getParent();
           }
           return;
       }
       ~SymbolTable()
       {
           //cout << "Destroying the symbolTable\n";
       }
};