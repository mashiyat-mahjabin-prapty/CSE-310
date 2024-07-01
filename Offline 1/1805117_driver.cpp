#include<iostream>
#include<fstream>
#include "1805117_symbolInfo.cpp"
#include "1805117_scopeTable.cpp"
#include "1805117_symbolTable.cpp"
using namespace std;

int main()
{
    ifstream myfile("input.txt");
    if(myfile.is_open() != true)
    {
        exit(EXIT_FAILURE);
    }

    int bucketNumber, currentScope;
    string operation, name, type;
    SymbolTable symboltable;
    myfile >> bucketNumber;
    cout << bucketNumber << endl;
    symboltable.enterScope(bucketNumber);
    currentScope++;

    while(!myfile.eof())
    {
        myfile >> operation;
        if(operation == "I")
        {
            myfile >> name >> type;
            cout << operation << " " << name << " " << type << endl;

            symboltable.insert(name, type);
        }
        else if(operation == "L")
        {
            myfile >> name;
            cout << operation << " " << name <<  endl;
            symboltable.lookup(name);
        }
        else if(operation == "D")
        {
            myfile >> name;
            cout << operation << " " << name <<  endl;
            symboltable.deleteEntry(name);
        }
        else if(operation == "P")
        {
            myfile >> type;
            cout << operation << " " << type << endl;

            if(type == "A")
            {
                symboltable.printAll();
            }
            else if(type == "C")
            {
                symboltable.printCurrent();
            }
            else{
                cout << "Invalid Operation\n";
            }
        }
        else if(operation == "S")
        {
            cout << operation << endl;
            symboltable.enterScope(bucketNumber);
        }
        else if(operation == "E")
        {
            cout << operation << endl;
            symboltable.exitScope();
        }
        else{
            break;
        }
        cout << endl;
    }
    for(int i = 0; i < currentScope; i++)
    {
        symboltable.exitScope();
    }
    myfile.close();

    return 0;
}