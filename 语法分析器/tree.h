#ifndef TREE_H_
#define TREE_H_
#include<stdio.h>

struct Node
{
    char label[20];
    char dotname[20];
    struct Node *brother;
    struct Node *child;
};


struct Node* newNode(char* node_name);

void insert(struct Node *parent,struct Node *child);

void printtree(struct Node* root,FILE *stream);

void treedot(struct Node *root,FILE *output);

#endif