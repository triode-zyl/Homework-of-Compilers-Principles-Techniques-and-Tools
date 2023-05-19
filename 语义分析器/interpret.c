#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include "definition.h"
typedef struct{
    enum f{LIT, LODI, LODF, STOI, STOF, CAL, INT, JMP, JPC, OPR, I2R, R2I} f;
    //int l;
    enum l{Int, Real, Char} l;
    //int a;
    DATA a;
}instruction; 

#define STACKSIZE 5000
instruction code[STACKSIZE];
char *fname[]={"LIT","LODI","LODF","STOI","STOF","CAL","INT","JMP","JPC","OPR","I2R","R2I"};


int base(int level, DATA *s, int b){
    int tempb = b;
    while(level > 0){
        tempb = s[tempb].val;
        level --;
    }
    return tempb;
}
DATA s[STACKSIZE];//stacksize：数据栈大小，需自己定义
void interpret() 
{
    int p, b, t;
    instruction i;  //instruction （指令）的类型定义（包括三个域f,l,a），请自行加入到头文件中，供其他文件共享
//    DATA s[STACKSIZE];//stacksize：数据栈大小，需自己定义

    
    t=0; b=1;  //t：数据栈顶指针；b：基地址；
    p=0;	// 指令指针
    s[1].val=0; s[2].val=0; s[3].val=0;
    do {
	
        i=code[p++];//code为指令存放数组，其定义请自行加入到头文件中，供其他文件共享
        switch (i.f) 
        {
        case LIT: 
            t=t+1;
            s[t]=i.a;
            break;
        case OPR: 
            switch(i.a.val) 
            {
                case 0:
                    t=b-1;
                    p=s[t+3].val;
                    b=s[t+2].val;
                    break;
                case 1: 
                    if(i.l != Real)
                        s[t].val=-s[t].val;
                    else
                        s[t].real=-s[t].real;
                    break;
                case 2: 
                    t=t-1;
                    if(i.l != Real)
                        s[t].val=s[t].val + s[t+1].val;
                    else
                        s[t].real=s[t].real + s[t+1].real;
                    break;
                case 3:
                    t=t-1;
                    if(i.l != Real)
                        s[t].val=s[t].val - s[t+1].val;
                    else
                        s[t].real=s[t].real - s[t+1].real;
                    break;
                case 4: 
                    t=t-1;
                    if(i.l != Real)
                        s[t].val=s[t].val * s[t+1].val;
                    else
                        s[t].real=s[t].real * s[t+1].real;
                    break;
                case 5: 
                    t=t-1;
                    if(i.l != Real)
                        s[t].val=s[t].val / s[t+1].val;
                    else
                        s[t].real=s[t].real / s[t+1].real;
                    break;
                case 6: 
                    s[t].val=(s[t].val % 2 == 1);
                    break;
                case 8: 
                    t=t-1;
					if(i.l != Real)
                        s[t].val=(s[t].val == s[t+1].val);
                    else
                        s[t].val=(fabs(s[t].real - s[t+1].real)<=1e-6);
                    break;
                case 9:
                    t=t-1;
                    if(i.l != Real)
                        s[t].val=(s[t].val != s[t+1].val);
                    else
                        s[t].val=(fabs(s[t].real - s[t+1].real)>1e-6);
                    break;
                case 10:
                    t=t-1;
                    if(i.l != Real)
                        s[t].val=(s[t].val < s[t+1].val);
                    else
                        s[t].val=(s[t].real - s[t+1].real < -1e-6);
                    break;
                case 11: 
                    t=t-1;
                    if(i.l != Real)
                        s[t].val=(s[t].val >= s[t+1].val);
                    else
                        s[t].val=(s[t].real - s[t+1].real >= -1e-6);
                    break;
                case 12: 
                    t=t-1;
                    if(i.l != Real)
                        s[t].val=(s[t].val > s[t+1].val);
                    else
                        s[t].val=(s[t].real - s[t+1].real > 1e-6);
                    break;
                case 13: 
                    t=t-1;
                    if(i.l != Real)
                        s[t].val=(s[t].val <= s[t+1].val);
                    else
                        s[t].val=(s[t].real - s[t+1].real <= 1e-6);
                    break;
                case 14: 
                    if(i.l == Int)
                        printf("%d", s[t].val);
                    if(i.l == Real)
                        printf("%f", s[t].real);
                    if(i.l == Char)
                        printf("%c", s[t].str);
                    t=t-1;
                    break;
                case 15: 
                    printf("\n");
                    break;
                case 16: 
                    t=t+1;
                    if(i.l == Int)
                        scanf("%d", &s[t].val);
                    if(i.l == Real)
                        scanf("%f", &s[t].real);
                    if(i.l == Char)
                        scanf("%c", &s[t].str);
                    break;
            }
		    break;
        case LODI: 
            t=t+1;
            s[t].val=s[base(i.l, s, b)+i.a.val].val;
            break;
        case LODF: 
            t=t+1;
            s[t].real=s[base(i.l, s, b)+i.a.val].real;
            break;
        case STOI: 
            s[base(i.l, s, b)+i.a.val].val=s[t].val;
            t=t-1;
            break;
        case STOF: 
            s[base(i.l, s, b)+i.a.val].real=s[t].real;
            t=t-1;
            break;
        case CAL:
            s[t+1].val=base(i.l, s, b);
            s[t+2].val=b;
            s[t+3].val=p;
            b=t+1;
            p=i.a.val;
            break;
        case INT: 
            t=t+i.a.val;
            break;
        case JMP: 
            p=i.a.val;
            break;
        case JPC: //增加条件假跳转
            switch(i.l) 
            {
                case 0:
                    if (s[t].val==0) {
                        p=i.a.val;
                    }
                    t=t-1;
                    break;
                case 1:
                    if (s[t].val==1) {
                        p=i.a.val;
                    }
                    t=t-1;
                    break;
            }
        case I2R:
            if(i.a.val==0)
                s[t].real=(float)s[t].val;
            if(i.a.val==1)
                s[t-1].real=(float)s[t-1].val;
            break;    
        case R2I:
            if(i.a.val==0)
                s[t].val=(int)s[t].real;
            if(i.a.val==1)
                s[t-1].val=(int)s[t-1].real;
            break;    
        }
    //printf("%d %f %d\n",s[t].val,s[t].real,p);
    }while (p!=0);
    //printf("%d,%d,%f\n",s[3].val,s[4].val,s[5].real);
}


int main(){
    char readtemp[1000][50];
    int i=0, j=0;
    FILE* fp;
    if((fp=fopen("pcode.txt","r"))==0){
        printf("无文件!!\n");
        return -1;
    }
    while(!feof(fp)){
        fscanf(fp, "%s", readtemp[j]); 
//        printf("%d----------%s--------\n", i, a[i]);
		j++;
    }
//    printf("%d", j); 
    int p = 0;
    for(i=0;i<j;i++){
    	p = i / 3;
    	if(i%3 == 0){
    		if(!strcasecmp(readtemp[i], "lit")){
				code[p].f = LIT;
			}
			if(!strcasecmp(readtemp[i], "lodi")){
				code[p].f = LODI;
			}
            if(!strcasecmp(readtemp[i], "lodf")){
				code[p].f = LODF;
			}
			if(!strcasecmp(readtemp[i], "stoi")){
				code[p].f = STOI;
			}
            if(!strcasecmp(readtemp[i], "stof")){
				code[p].f = STOF;
			}
			if(!strcasecmp(readtemp[i], "cal")){
				code[p].f = CAL;
			}
			if(!strcasecmp(readtemp[i], "int")){
				code[p].f = INT;
			}
			if(!strcasecmp(readtemp[i], "jmp")){
				code[p].f = JMP;
			}
			if(!strcasecmp(readtemp[i], "jpc")){
				code[p].f = JPC;
			}
			if(!strcasecmp(readtemp[i], "opr")){
				code[p].f = OPR;
			}
            if(!strcasecmp(readtemp[i], "i2r")){
				code[p].f = I2R;
			}
            if(!strcasecmp(readtemp[i], "r2i")){
				code[p].f = R2I;
			}
		}
    	else if(i%3 == 1){
    		code[p].l = atoi(readtemp[i]);
		}
		else if(i%3 == 2){
    		code[p].a.val = atoi(readtemp[i]);
		}
	}
//    printf("////%s////\n", a[2]);
//	int j = 0;
//	for(j = 0; j < 25;j++){
//		printf("%s %d %d\n", fname[code[j].f], code[j].l, code[j].a);
//	}
    fclose(fp);
//    int k;
//    for(k = 0; k < j/3; k++){
//    	printf("%s %d %d\n", fname[code[k].f], code[k].l, code[k].a);
//	}
    interpret();
    
    return 0;
}