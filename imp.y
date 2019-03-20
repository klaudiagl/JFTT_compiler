%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdlib.h>
#define YYERROR_VERBOSE

FILE * yyin;
FILE * f;
void yyerror(const char * errMessage);
int yylex ();

FILE *f;

typedef struct command
{
    int commandNo;
    char *command;
    int arg1, arg2;
    struct command *next;
} command;

command *commandList = NULL;
command *lastCommands = NULL;

void setCommands(command *ccommand, char *c, int a1, int a2, int commandNo)
{
    ccommand->next = NULL;
    ccommand->command = (char *)strdup(c);
    ccommand->arg1 = a1;
    ccommand->arg2 = a2;
    ccommand->commandNo = commandNo;
    lastCommands = ccommand;
}

unsigned long long currCommands()
{
    if (commandList == NULL)
    {
        return -1;
    }
    else
    {
        command *head = commandList;
        while (head->next != NULL)
        {
            head = head->next;
        }
        return head->commandNo;
    }
}

void printCommands()
{
    command *curr = commandList;
    while (curr != NULL)
    {
        if (!strcmp(curr->command, "JUMP"))
        {
            fprintf(f, "JUMP %d", curr->arg1);
        }
        else if (!strcmp(curr->command, "JZERO") || !strcmp(curr->command, "JODD"))
        {
            fprintf(f, "%s %c %d", curr->command, 65 + curr->arg1, curr->arg2);
        }
        else
        {
            fprintf(f, "%s", curr->command);
            if (curr->arg1 != -1)
            {
                fprintf(f, " %c", curr->arg1 + 65);
                if (curr->arg2 != -1)
                {
                    fprintf(f, " %c", curr->arg2 + 65);
                }
            }
        }
        fprintf(f, "\n");
        curr = curr->next;
    }
}

void addCommand(char *c, int a1, int a2)
{
    if (commandList == NULL)
    {
        commandList = malloc(sizeof(command));
        setCommands(commandList, c, a1, a2, 0);
    }
    else
    {
        command *head = commandList;
        while (head->next != NULL)
        {
            head = head->next;
        }
        head->next = malloc(sizeof(command));
        setCommands(head->next, c, a1, a2, head->commandNo + 1);
    }
}

typedef struct updateCommands
{
    command *commandAddr;
    struct updateCommands *next;
} updateCommands;

updateCommands *updaterList = NULL;

void addLatestCommandToUpdate()
{
    updateCommands *tmp = malloc(sizeof(updateCommands));
    tmp->commandAddr = lastCommands;
    tmp->next = updaterList;
    updaterList = tmp;
}

void rmTop()
{
    updateCommands *top = updaterList;
    updaterList = updaterList->next;
    free(top);
}

void updateLatestCommands(int argNo, int value)
{
    if (argNo == 1)
    {
        updaterList->commandAddr->arg1 = value;
    }
    else if (argNo == 2)
    {
        updaterList->commandAddr->arg2 = value;
    }
    rmTop();
}

typedef struct registerCell
{
    int inUse;
    int valuated;
    unsigned long long value;
} registerCell;

int REGISTERS_AMOUNT = 8;

registerCell *registers = NULL;

void initRegisters()
{
    registers = malloc(8 * sizeof(registerCell));
    for (int i = 0; i < REGISTERS_AMOUNT; i++)
    {
        registers[i].inUse = 0;
        registers[i].valuated = 0;
        registers[i].value = 0;
    }
}

int getFirstUsableRegisterId()
{
    for (int i = 1; i < REGISTERS_AMOUNT; i++)
    {
        if (!registers[i].inUse)
        {
            return i;
        }
    }
    return -1;
}

void bookRegister(int id)
{
    registers[id].inUse = 1;
}

void setRegisterValue(int regID, unsigned long long val)
{
    registers[regID].valuated = 1;
    registers[regID].value = val;
}

void releaseRegister(int id)
{
    registers[id].inUse = 0;
}

void numInReg(unsigned long long int val, int reg)
{
    if(val!=0)
    {
        if(val==1)
        {
            addCommand("INC", reg, -1);
        }
        else
        {
            numInReg(val/2,reg);
            addCommand("ADD", reg, reg);
            if(val%2)
            {
                addCommand("INC", reg, -1);
            }
        }
    }
}

void createNumInReg(unsigned long long int val, int reg) {
    addCommand("SUB", reg, reg);
    numInReg(val,reg);
}


typedef struct variable
{
	char *name;
	unsigned long long int memStart;
	unsigned long long int memEnd;
	unsigned long long int indexStart;
	unsigned long long int indexEnd;
	struct variable *next;
	int type;
} variable;

variable *variableExists(char *n);
void addVariable(char *n);
void addTable(char *n, unsigned long long int tabStart, unsigned long long int tabStop);
void setNew(char *n, unsigned long long int memStart, unsigned long long int memEnd, unsigned long long int indexStart, unsigned long long int indexEnd, int type);
unsigned long long int getVariableMemAddr(char *n);
unsigned long long int getTableMemAddr(char *tabName, unsigned long long int tabIndex);
unsigned long long int getTabStaringIndex(char *tabName);
unsigned long long int tabZeroMem(char *n);
unsigned long long int loopMemStart = 0;
variable *variablesList = NULL;

void errorPrinter(char *c);
int inited[10000];
variable *variableExists(char *n)
{
	variable *v = variablesList;
	while (v != NULL)
	{
		if (!strcmp(v->name, n))
		{
			return v;
		}
		v = v->next;
	}
	return NULL;
}
void setNew(char *n, unsigned long long int memStart, unsigned long long int memEnd, unsigned long long int indexStart, unsigned long long int indexEnd, int type)
{
	variable *v = malloc(sizeof(variable));
	v->name = n;
	v->memStart = memStart;
	v->memEnd = memEnd;
	v->indexEnd = indexEnd;
	v->indexStart = indexStart;
	v->type = type;
	v->next = variablesList;
	variablesList = v;
}
void addVariable(char *name)
{
	if (variableExists(name) != NULL)
	{
		errorPrinter("Próba ponownej deklaracji zmiennej\n");
		exit(0);
	}
	if (variablesList == NULL)
	{
		setNew(name, 0, 0, 0, 0, 0);
	}
	else
	{
		setNew(name, variablesList->memEnd + 1, variablesList->memEnd + 1, 0, 0, 0);
	}
}

void addLoopVariable(char *n)
{
	if (variableExists(n) != NULL)
	{
		errorPrinter("Próba ponownej deklaracji zmiennej\n");
		exit(0);
	}
	if (variablesList == NULL)
	{
		setNew(n, 0, 1, 0, 0, 1);
	}
	else
	{
		setNew(n, variablesList->memEnd + 1, variablesList->memEnd + 2, 0, 0, 1);
	}
}

void addTable(char *n, unsigned long long int tabStart, unsigned long long int tabStop)
{
	if (variableExists(n) != NULL)
	{
		errorPrinter("Próba ponownej deklaracji zmiennej\n");
		exit(0);
	}
	if (tabStop < tabStart)
	{
		errorPrinter("Zły zakres tablicy\n");
		exit(0);
	}
	unsigned long long int sz = tabStop - tabStart + 1;
	if (variablesList == NULL)
	{
		setNew(n, 0, sz - 1, tabStart, tabStop, 2);
	}
	else
	{
		setNew(n, variablesList->memEnd + 1, variablesList->memEnd + sz, tabStart, tabStop, 2);
	}
}

unsigned long long int getVariableMemAddr(char *n)
{
	variable *v = variableExists(n);
	if (v == NULL)
	{
		errorPrinter("Niezadeklarowana zmienna\n");
		exit(0);
	}
	else if (v->type == 2)
	{
		errorPrinter("Złe użycie zmiennej\n");
		exit(0);
	}
	return v->memStart;
}

unsigned long long int getTableMemAddr(char *n, unsigned long long int id)
{
	variable *v = variableExists(n);
	if (v == NULL)
	{
		errorPrinter("Błędna nazwa zmiennej tablicowej\n");
		exit(0);
	}
	if (v->type != 2)
	{
		errorPrinter("Złe użycie zmiennej\n");
		exit(0);
	}
	if (v->indexStart > id || v->indexEnd < id)
	{
		errorPrinter("Błędny indeks tablicy\n");
		exit(0);
	}
	return v->memStart + id - v->indexStart;
}

unsigned long long int getTabStaringIndex(char *n)
{

	variable *v = variableExists(n);
	if (v == NULL)
	{
		errorPrinter("Zła nazwa zmimennej tablicowej\n");
		exit(0);
	}
	if (v->type != 2)
	{
		errorPrinter("Złe użycie zmiennej\n");
		exit(0);
	}
	return v->indexStart;
}

unsigned long long int tabZeroMem(char *n)
{
	variable * v = variableExists(n);
	if (v == NULL)
	{
		errorPrinter("Błędna nazwa zmiennej tablicowej\n");
		exit(0);
	}
	if (v->type != 2)
	{
		errorPrinter("Złe użycie zmiennej\n");
		exit(0);
	}
	return v->memStart;
}

void popVariable()
{
	variablesList = variablesList->next;
}

void setLoopMemStart()
{
	if (variablesList != NULL)
	{
		loopMemStart = variablesList->memEnd + 1;
	}
	else
	{
		loopMemStart = 0;
	}
}

unsigned long long int loopVarsStartMem()
{
	return loopMemStart;
}

%}

%union {
	char * string;
    	unsigned long long int number;
	int reg;
}

%token <string> DECLARE IN END IF THEN ELSE ENDIF WHILE DO ENDWHILE ENDDO FOR FROM DOWNTO TO ENDFOR WRITE READ ASS ADD SUB MUL DIV MOD EQ NEQ GT LT GEQ LEQ LBRACE RBRACE RANGE SEM ID
%token <number> NUM

%%
program         : DECLARE declarations IN
                    {
                        setLoopMemStart();
                    }
                    commands END
                    {
                        addCommand("HALT", -1,-1);
                        printCommands();
                    }
declarations    : declarations ID SEM { addVariable( $<string>2 ); }
                | declarations ID LBRACE NUM RANGE NUM RBRACE SEM { addTable($<string>2, $<number>4, $<number>6 ); }
                |
                ;

commands        : commands command
                | command
                ;

command         : identifier ASS expression SEM
                    {
                        if (registers[$<reg>1].value >= loopVarsStartMem()) {
                            errorPrinter("Próba przyypisania wartości zmiennej pętlowej\n");
                            exit(0);
                        }
                        inited[registers[$<reg>1].value] = 1;
                        addCommand("COPY",0, $<reg>1);
                        addCommand("STORE", $<reg>3, -1);
                        releaseRegister($<reg>1);
                        releaseRegister($<reg>3);
                    }
                | IF condition THEN
                    {
                        addCommand("JZERO", $<reg>2, -1);
                        addLatestCommandToUpdate();
                        releaseRegister($<reg>2);
                    }
                    ifending
                | WHILE  { $<number>$ = currCommands(); } condition
                    {
                        addCommand("JZERO", $<reg>3, -1);
                        addLatestCommandToUpdate();
                        releaseRegister($<reg>3);
                    }
                    DO commands ENDWHILE
                    {
                            addCommand("JUMP", $<number>2+1, -1);
                            updateLatestCommands(2, currCommands()+1);
                    }
                | DO { $<number>$ = currCommands(); } commands WHILE condition ENDDO
                    {
                        addCommand("JZERO", $<reg>5, currCommands()+ 3);
                        addCommand("JUMP", $<number>2+1, -1);
                    }
                | FOR ID FROM value TO value DO
                    {
                            addLoopVariable($<string>2);

                            int reg = getFirstUsableRegisterId();
                            bookRegister(reg);
                            unsigned long long int varAddr = getVariableMemAddr($<string>2);
                            createNumInReg(varAddr, reg);

                            inited[registers[reg].value] = 1;
                            inited[registers[reg+1].value] = 1;
                            addCommand("COPY",0, reg);
                            addCommand("STORE",$<number>4, -1);
                            addCommand("INC",0, -1);
                            addCommand("STORE",$<number>6, -1);
                            unsigned long long int beforCmp = currCommands()+1;
                            createNumInReg(varAddr, reg);
                            addCommand("COPY",0, reg);
                            addCommand("LOAD",$<number>4, -1);\
                            addCommand("INC",0, -1);
                            addCommand("LOAD",$<number>6, -1);
                            addCommand("INC",$<number>6, -1);
                            addCommand("SUB",$<number>6, $<number>4);
                            addCommand("JZERO", $<number>6, -1);
                            addLatestCommandToUpdate();
                            releaseRegister($<number>4);
                            releaseRegister($<number>6);
                            releaseRegister(reg);
                            $<number>$ = beforCmp;
                    }
                    commands
                    {
                            int reg = getFirstUsableRegisterId();
                            bookRegister(reg);
                            unsigned long long int varAddr = getVariableMemAddr($<string>2);
                            createNumInReg(varAddr, reg);

                            int val = getFirstUsableRegisterId();
                            addCommand("COPY",0, reg);
                            addCommand("LOAD",val, -1);
                            addCommand("INC",val, -1);
                            addCommand("STORE",val, -1);
                            addCommand("JUMP", $<number>8, -1);
                            updateLatestCommands(2, currCommands()+1);
                            popVariable();
                    } ENDFOR
                | FOR ID FROM value DOWNTO value DO
                    {

                        addLoopVariable($<string>2);

                        int reg = getFirstUsableRegisterId();
                        bookRegister(reg);
                        unsigned long long int varAddr = getVariableMemAddr($<string>2);
                        createNumInReg(varAddr, reg);

                        inited[registers[reg].value] = 1;
                        inited[registers[reg+1].value] = 1;
                        addCommand("COPY",0, reg);
                        addCommand("STORE",$<number>4, -1);
                        addCommand("INC",0, -1);
                        addCommand("STORE",$<number>6, -1);
                        unsigned long long int beforCmp = currCommands()+1;
                        createNumInReg(varAddr, reg);
                        addCommand("COPY",0, reg);
                        addCommand("LOAD",$<number>4, -1);
                        addCommand("INC",0, -1);
                        addCommand("LOAD",$<number>6, -1);
                        addCommand("INC",$<number>4, -1);
                        addCommand("SUB",$<number>4, $<number>6);
                        addCommand("JZERO", $<number>4, -1);
                        addLatestCommandToUpdate();
                        releaseRegister($<number>4);
                        releaseRegister($<number>6);
                        releaseRegister(reg);
                        $<number>$ = beforCmp;


                    }
                    commands
                    {
                        int reg = getFirstUsableRegisterId();
                        bookRegister(reg);
                        unsigned long long int varAddr = getVariableMemAddr($<string>2);
                        createNumInReg(varAddr, reg);

                        int val = getFirstUsableRegisterId();
                        addCommand("COPY",0, reg);
                        addCommand("LOAD",val, -1);
                        addCommand("JZERO", val, currCommands()+5);
                        addCommand("DEC",val, -1);
                        addCommand("STORE",val, -1);
                        addCommand("JUMP", $<number>8, -1);
                        updateLatestCommands(2, currCommands()+1);
                        popVariable();
                    } ENDFOR
                | READ identifier SEM
                    {
                        int reg = getFirstUsableRegisterId();
                        bookRegister(reg);
                        addCommand("GET", reg, -1);
                        addCommand("COPY",0, $<reg>2);
                        addCommand("STORE", reg, -1);
                        inited[registers[$<reg>2].value] = 1;
                        releaseRegister(reg);
                        releaseRegister($<reg>2);
                    }
                | WRITE value SEM
                    {
                        addCommand("PUT", $<reg>2, -1);
                        releaseRegister($<reg>2);
                    }
                ;

ifending        : commands ENDIF
                    {
                        updateLatestCommands(2,currCommands()+1);
                    }
                | commands
                    {
                        updateLatestCommands(2, currCommands()+2);
                        addCommand("JUMP", -1,-1);
                        addLatestCommandToUpdate();
                    }
                    ELSE commands ENDIF
                    {
                        updateLatestCommands(1,currCommands()+1);
                    }
                ;

expression      : value { $<reg>$ = $<reg>1; }
                | value ADD value
                    {
                        addCommand("ADD", $<reg>1, $<reg>3);
                        releaseRegister($<reg>3);
                        $<reg>$=$<reg>1;
                    }
                | value SUB value
                    {
                        addCommand("SUB", $<reg>1, $<reg>3);
                        releaseRegister($<reg>3);
                        $<reg>$ = $<reg>1;
                    }
                | value MUL value
                    {
                       int res = getFirstUsableRegisterId();bookRegister(res);
                        addCommand("SUB",res, res);
                        addCommand("JODD", $<reg>3, currCommands()+ 6);
                        addCommand("ADD",$<reg>1,$<reg>1);
                        addCommand("HALF",$<reg>3, -1);
                        addCommand("JZERO", $<reg>3, currCommands()+ 5);
                        addCommand("JUMP", currCommands()-3 ,-1);
                        addCommand("ADD", res, $<reg>1);
                        addCommand("JUMP", currCommands() - 4,-1);

                        releaseRegister($<reg>1);
                        releaseRegister($<reg>3);
                        $<reg>$ = res;
                    }
                | value DIV value
                    {
                            int kVal2Reg = getFirstUsableRegisterId();
                            bookRegister(kVal2Reg);
                            int buffAReg = getFirstUsableRegisterId();
                            bookRegister(buffAReg);
                            int res = 0;
                            bookRegister(res);
                            int resK= getFirstUsableRegisterId();
                            bookRegister(resK);
                            int cmpReg = getFirstUsableRegisterId();
                            bookRegister(cmpReg);

                            addCommand("JZERO", $<reg>3, currCommands()+ 3);
                            addCommand("JUMP", currCommands() + 4,-1);
                            addCommand("COPY",$<reg>1, $<reg>3);
                            addCommand("JUMP", currCommands() + 30,-1);

                            addCommand("COPY",buffAReg, $<reg>1);
                            addCommand("COPY",kVal2Reg, $<reg>3);
                            addCommand("SUB",resK, resK);
                            addCommand("INC",resK, -1);
                            addCommand("SUB",res, res);

                            addCommand("ADD",kVal2Reg,kVal2Reg);
                            addCommand("ADD",resK,resK);
                            addCommand("COPY",cmpReg, $<reg>1);
                            addCommand("INC",cmpReg, -1);
                            addCommand("SUB",cmpReg, kVal2Reg);
                            addCommand("JZERO", cmpReg, currCommands()+3);
                            addCommand("JUMP", currCommands() - 5,-1);

                            addCommand("HALF",kVal2Reg, -1);
                            addCommand("HALF",resK, -1);
                            addCommand("COPY",cmpReg, kVal2Reg);
                            addCommand("INC",cmpReg, -1);
                            addCommand("SUB",cmpReg, $<reg>3);
                            addCommand("JZERO", cmpReg, currCommands()+ 11);
                            addCommand("COPY",buffAReg, $<reg>1);

                            addCommand("INC",$<reg>1, -1);
                            addCommand("SUB",$<reg>1, kVal2Reg);
                            addCommand("JZERO", $<reg>1, currCommands()+ 5);
                            addCommand("DEC",$<reg>1, -1);
                            addCommand("ADD", res, resK);
                            addCommand("JUMP", currCommands()-11,-1);
                            addCommand("COPY",$<reg>1, buffAReg);
                            addCommand("JUMP", currCommands() -13,-1);

                            addCommand("COPY",$<reg>1, res);
                            releaseRegister(res);
                            releaseRegister($<reg>3);
                            releaseRegister(resK);
                            releaseRegister(cmpReg);
                            releaseRegister(kVal2Reg);
                            releaseRegister(buffAReg);
                            $<reg>$ = $<reg>1;
                    }
                | value MOD value
                    {
                        int kVal2Reg = getFirstUsableRegisterId();
                        bookRegister(kVal2Reg);
                        int buffAReg = getFirstUsableRegisterId();
                        bookRegister(buffAReg);
                        int cmpReg = getFirstUsableRegisterId();
                        bookRegister(cmpReg);
                        int cmpReg2 = getFirstUsableRegisterId();
                        bookRegister(cmpReg2);
                        addCommand("JZERO", $<reg>3, currCommands()+ 3);
                        addCommand("JUMP", currCommands() + 4,-1);
                        addCommand("COPY",$<reg>1, $<reg>3);
                        addCommand("JUMP", currCommands() + 22,-1);

                        addCommand("COPY",kVal2Reg, $<reg>3);
                        addCommand("COPY",cmpReg, kVal2Reg);
                        addCommand("COPY",cmpReg2, $<reg>1);
                        addCommand("INC",cmpReg2, -1);
                        addCommand("SUB", cmpReg2, cmpReg);
                        addCommand("JZERO", cmpReg2, currCommands()+ 4);
                        addCommand("ADD",kVal2Reg,kVal2Reg);
                        addCommand("JUMP", currCommands() - 5,-1);

                        addCommand("COPY",cmpReg2, $<reg>3);
                        addCommand("SUB",cmpReg2, $<reg>1);
                        addCommand("JZERO", cmpReg2, currCommands() + 3);
                        addCommand("JUMP", currCommands() + 10,-1);
                        addCommand("HALF",kVal2Reg, -1);
                        addCommand("COPY",buffAReg, $<reg>1);
                        addCommand("INC",buffAReg, -1);
                        addCommand("SUB",buffAReg, kVal2Reg);
                        addCommand("JZERO", buffAReg, currCommands()-3);
                        addCommand("DEC",buffAReg, -1);
                        addCommand("COPY",$<reg>1, buffAReg);
                        addCommand("JUMP", currCommands() - 10,-1);

                        releaseRegister(cmpReg);
                        releaseRegister(cmpReg2);
                        releaseRegister(kVal2Reg);
                        releaseRegister($<reg>3);
                        releaseRegister(buffAReg);
                        $<reg>$ = $<reg>1;
                    }
                ;

condition       : value EQ value
                    {
                        addCommand("INC",$<reg>1, -1);
                        addCommand("SUB", $<reg>1, $<reg>3);
                        addCommand("JZERO", $<reg>1, currCommands()+ 7);
                        addCommand("DEC",$<reg>1, -1);
                        addCommand("JZERO", $<reg>1, currCommands()+ 4);
                        addCommand("SUB",$<reg>1, $<reg>1);
                        addCommand("JUMP",  currCommands() + 3,-1);
                        addCommand("INC",$<reg>1, -1);

                        releaseRegister($<reg>3);
                        $<reg>$ =  $<reg>1;
                    }
                | value NEQ value
                    {
                        addCommand("INC",$<reg>1, -1);
                        addCommand("SUB", $<reg>1, $<reg>3);
                        addCommand("JZERO", $<reg>1, currCommands()+ 4);
                        addCommand("DEC",$<reg>1, -1);
                        addCommand("JZERO", $<reg>1, currCommands()+ 3);
                        addCommand("INC",$<reg>1, -1);

                        releaseRegister($<reg>3);
                        $<reg>$ =  $<reg>1;
                    }
                | value LT value
                    {
                        addCommand("SUB",$<reg>3, $<reg>1);
                        releaseRegister($<reg>1);
                        $<reg>$ =  $<reg>3;
                    }
                | value GT value
                    {
                        addCommand("SUB",$<reg>1, $<reg>3);

                        releaseRegister($<reg>3);
                        $<reg>$ =  $<reg>1;
                    }
                | value LEQ value
                    {
                        addCommand("INC",$<reg>3, -1);
                        addCommand("SUB",$<reg>3, $<reg>1);

                        releaseRegister($<reg>1);
                        $<reg>$ =  $<reg>3;
                    }
                | value GEQ value
                    {
                        addCommand("INC",$<reg>1, -1);
                        addCommand("SUB",$<reg>1, $<reg>3);

                        releaseRegister($<reg>3);
                        $<reg>$ =  $<reg>1;
                    }
                ;


value           : NUM
                    {
                        int reg = getFirstUsableRegisterId();
                        bookRegister(reg);
                        createNumInReg($<number>1, reg);
                        $<reg>$ = reg;
                    }
                | identifier
                    {
                        if (!inited[registers[$<reg>1].value]) {
                            errorPrinter("Zmienna nie zainicjalizowana\n");
                            exit(0);
                        }
                        addCommand("COPY",0, $<reg>1);
                        addCommand("LOAD",$<reg>1, -1);
                        $<reg>$ = $<reg>1;
                    }
                ;


identifier      : ID
                    {
                        int reg = getFirstUsableRegisterId();
                        bookRegister(reg);
                        unsigned long long int varAddr = getVariableMemAddr($<string>1);
                        createNumInReg(varAddr, reg);
                        $<reg>$ = reg;
                    }
                | ID LBRACE ID RBRACE
                    {

                        int reg = getFirstUsableRegisterId();
                        bookRegister(reg);
                        unsigned long long int startId = getTabStaringIndex($<string>1);
                        createNumInReg(startId, reg);

                        int varReg = getFirstUsableRegisterId();
                        bookRegister(varReg);
                        unsigned long long int varAddr = getVariableMemAddr( $<string>3);
                        createNumInReg(varAddr, varReg);


                        addCommand("COPY", 0, varReg);
                        addCommand("LOAD",varReg, -1);

                        int tabReg = getFirstUsableRegisterId();
                        bookRegister(tabReg);
                        unsigned long long int tabMemStart = tabZeroMem($<string>1);
                        createNumInReg(tabMemStart, tabReg);

                        addCommand("ADD",tabReg, varReg);
                        addCommand("SUB",tabReg, reg);

                        releaseRegister(reg);
                        releaseRegister(varReg);
                        $<reg>$= tabReg;
                    }
                | ID LBRACE NUM RBRACE
                    {
                        int reg = getFirstUsableRegisterId();
                        bookRegister(reg);
                        unsigned long long int varAddr = getTableMemAddr($<string>1, $<number>3);
                        createNumInReg(varAddr, reg);
                        $<reg>$= reg;
                    }
                ;

%%

int yywrap() {
    return 1;
}

int main(int argc, char **argv) {
    if (argc != 3) {
        errorPrinter("Proszę podać nazwę pliku wejściowego i wyjścowego\n");
        exit(0);
    }
    yyin = fopen(argv[1], "r");
    initRegisters();
    f = fopen(argv[2], "w");
    yyparse();
    return 0;
}
