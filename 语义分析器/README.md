# 语义分析器

周炎亮,2018202196,信息学院

## 测试环境：

- Ubuntu 18.04
- bison/C

## 文件说明：

README.md：本实验说明文档

definition.h：相关结构定义

main.l：词法分析源程序

main.y：语法及语义分析源程序

interpret.c：pcode代码解释器源程序

makefile：程序编译文件

main：语义分析器可执行文件

interpret：pcode代码解释器可执行文件

## 编译方法：

```shell
$ make
```

执行make指令后会生成main及interpret可执行文件。

## 运行：

./main < inputfile

inputfile为pl0语言的文件，执行后会生成pcode.txt的类pcode代码。

./interpret

interpret会读入生成的类pcode代码并解释执行。

## Clear：

make clean