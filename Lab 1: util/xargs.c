#include "kernel/types.h"
#include "kernel/param.h"
#include "user/user.h"
#include "kernel/stat.h"

int
main(int argc, char *argv[])
{

  if(argc < 2){
    fprintf(2,"Usage: xargs command\n");
    exit(1);
  }
  char * argvs[MAXARG];//声明一个数组argvs，该数组保存多个指向char类型的指针
  char buf[256]={"\0"};
  int i=0;
  for(;i<argc;i++)
  {
    argvs[i]=argv[i];
  }

  for(;;)
  {
    int j=0;
    while((read(0,buf+j,sizeof(char))!=0)&&buf[j]!='\n')
    {
        j++;
    }
    if(j==0) break;//读完所有行
    buf[j]=0;
    argvs[i]=buf;
    argvs[i+1]=0;
    if(fork()==0)
    {
        exec(argvs[1],argvs+1);
        printf("exec error\n");
        exit(1);
    }
    else{
        wait(0);
    }
  }
  exit(0);
}
