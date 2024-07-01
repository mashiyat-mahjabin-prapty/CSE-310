#include<iostream>
using namespace std;

class scopeTable{
    private:
        int totalBuckets;
        int current_id;
        string id;
        scopeTable *parentScope;
        SymbolInfo **hashTable;

        int sdbmHash(string name)
        {
            unsigned long long hash = 0;

            for(unsigned long c : name)
            {
                hash = c + (hash << 6) + (hash << 16) - hash;
            }

            return hash % totalBuckets;
        }

    public:
        scopeTable()
        {
            //cout << "New scopeTable created" << endl;
        }
        scopeTable(int totalBuckets, scopeTable *parentScope)
        { 
            this->totalBuckets = totalBuckets;
            this->current_id = 0;
            hashTable = new SymbolInfo*[totalBuckets];
            for(int i = 0; i < totalBuckets; i++)
            {
                hashTable[i] = NULL;
            }
            this->parentScope = parentScope;
            if(parentScope == NULL)
            {
                this->setId(1);
            }
            else{
                this->getParent()->setCurrent();
                this->setId();
            }
            //cout << "New scopeTable created with id# " << id << endl;
        }
        void setId()
        {
            this->id = parentScope->getId() + "." + to_string(parentScope->current_id);
        }
        void setId(int i)
        {
            this->id = to_string(i);
        }
        string getId()
        {
            if(parentScope == NULL)
            {
                return to_string(1);
            }
            return this->id;
        }
        int bucketNumber()
        {
            return totalBuckets;
        }
        scopeTable* getParent()
        {
            return parentScope;
        }
        int getCurrent()
        {
            return this->current_id;
        }
        void setCurrent()
        {
            this->current_id++;
        }
        SymbolInfo* lookup(string name)
        {
            int hash = sdbmHash(name);
            int i = 0;

            SymbolInfo* temp = hashTable[hash];
            while(temp != NULL)
            {
                if(temp->getName() == name)
                {
                    cout << "Found in scopetable# " << id << " at position " << hash << "," << i << endl;
                    return temp;
                }
                i++;
                temp = temp->getNext();
            }
            cout << "Not found in scopeTable# " << id << endl;
            return NULL;
        }
        bool insert(string name, string type)
        {
            if(lookup(name) != NULL)
            {
                //cout << "<" << name << "," << type << ">" << " already exists in current scopeTable" << endl;
                return false;
            }
            int hash = sdbmHash(name);
            int i = 0;

            SymbolInfo* temp = hashTable[hash];

            SymbolInfo* s = new SymbolInfo(name, type);
            
            if(temp == NULL)
            {
                hashTable[hash] = s;
                s->setNext(NULL);
                cout << "Inserted in ScopeTable# " << id << " at position " << hash << "," << i << endl;
                return true;
            }
            while(temp->getNext() != NULL)
            {
                temp = temp->getNext();
                i++;
            }

            temp->setNext(s);
            temp = temp->getNext();
            temp->setNext(NULL);

            cout << "Inserted in ScopeTable# " << id << " at position" << hash << "," << i << endl;
            return true;
        }
        bool deleteEntry(string name)
        {
            if(lookup(name) == NULL)
            {
                //cout << name  << " not found in current scopeTable" << endl;
                return false;
            }
            int hash = sdbmHash(name);
            int i = 0;

            SymbolInfo* temp = hashTable[hash];
            SymbolInfo* prev = NULL;

            while(temp != NULL)
            {
                if(temp->getName() == name)
                {
                    break;
                }
                i++;
                prev = temp;
                temp = temp->getNext();
            }
            if(prev == NULL)
            {
                hashTable[hash] = temp->getNext();
            }
            else
            {
                prev->setNext(temp->getNext());
            }

            delete temp;

            cout << "Deleted Entry " << hash << "," << i << " from current scopetable" << endl;
            return true;
        }
        void print()
        {
            cout << "ScopeTable # " << id << endl;
            for (int i = 0; i < totalBuckets; i++)
            {
                cout << i << "--> ";
                SymbolInfo* current = hashTable[i];
                while(current != NULL)
                {
                    cout << " < " << current->getName() << " : " << current->getType() << " > ";
                    current = current->getNext();
                }
                cout <<  endl;
            }
            return;
        }
        ~scopeTable()
        {
            for(int i = 0; i < totalBuckets; i++)
            {
                delete hashTable[i];
            }
            delete[] hashTable;
            //cout << "Destroying a scopeTable" << endl;
        }
};