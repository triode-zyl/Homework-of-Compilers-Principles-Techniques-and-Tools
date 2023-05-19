#include"tree.h"
#include<stdio.h>
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
struct Node* newNode (char* node_name)
{
	struct Node *p=(struct Node*)malloc(sizeof(struct Node));
	if (p==NULL)
	{
		printf("Error:out of memory.\n");
		exit(1);
	}
    strncpy(p->label,node_name,20);
    p->brother=NULL;
    p->child=NULL;
    return p;
}

void insert(struct Node *parent,struct Node *child)
{   
	
	if (child==NULL)
		return;
	if(parent->child==NULL)
	{
		parent->child=child;
	}
	else
	{
		struct Node *Child;
		Child=parent->child;
		while(Child->brother!=NULL)
			Child=Child->brother;
		Child->brother=child;
	}
}

int space =0;
void printtree(struct Node *root, FILE *stream) {
  int i;
  if (root == NULL)
    return;
  for (i = 0; i < space; i++)
    fprintf(stream," ");
  fprintf(stream, "%d %s\n", space,root->label);

  if (root->child != NULL) {
    space++;
    printtree(root->child, stream);
    space--;
  }
  if(root->brother != NULL){
    printtree(root->brother, stream);
  }
}


char tmp[100][20];
int num[100];
int size=0;
void treedot(struct Node *root,FILE *output)
{
	struct Node *Child=root->child;
	while(Child!=NULL)
	{
		//printf("%s\n",Child->label);
		char name[20];
		strncpy(name,Child->label,20);
		if(!strcmp(name,"+")||!strcmp(name,"-"))
			strncpy(Child->dotname,"ADDSUB",20);
		else if(!strcmp(name,"*")||!strcmp(name,"/"))
			strncpy(Child->dotname,"MULTIDIV",20);
		else if(!strcmp(name,":="))
			strncpy(Child->dotname,"EQUAL",20);
		else if(!strcmp(name,"."))
			strncpy(Child->dotname,"DOT",20);
		else if(!strcmp(name,","))
			strncpy(Child->dotname,"COMMA",20);
		else if(!strcmp(name,";"))
			strncpy(Child->dotname,"SEM",20);
		else if(!strcmp(name,"("))
			strncpy(Child->dotname,"LP",20);
		else if(!strcmp(name,")"))
			strncpy(Child->dotname,"RP",20);
		else if(!strcmp(name,":"))
			strncpy(Child->dotname,"COLON",20);
		else if(!strcmp(name,"#")||!strcmp(name,"<")||!strcmp(name,">")||!strcmp(name,"<=")||!strcmp(name,">=")||!strcmp(name,"="))
			strncpy(Child->dotname,"OPERATOR",20);
		else 
			strncpy(Child->dotname,Child->label,20);
		
		int i;
		for(i=0;i<size;i++)
		{
			if(!strcmp(tmp[i],Child->dotname))
			{
				num[i]++;
				char s[10];
				sprintf(s,"%d",num[i]);
				//itoa(num[i],s,10);
				strcat(Child->dotname,s);
				break;
			}
		}
		if(i==size)
		{
			strncpy(tmp[i],Child->dotname,20);
			num[i]=0;
			size++;
		}
		//printf("%s\n",Child->dotname);
		if(Child->label[0]=='\"')
		{
			char s[20];
			strncpy(s,Child->label,strlen(Child->label)-1);
			fprintf(output,"%s [label=\"\\%s\\\"\"];\n",Child->dotname,s);
		}
		else
			fprintf(output,"%s [label=\"%s\"];\n",Child->dotname,Child->label);
		fprintf(output,"%s->%s;\n",root->dotname,Child->dotname);
		treedot(Child,output);
		Child=Child->brother;
	}
}

