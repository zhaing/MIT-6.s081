#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"

char*
fmtname(char *path)
{
  static char buf[DIRSIZ+1];
  char *p;

  // Find first character after last slash.
  for(p=path+strlen(path); p >= path && *p != '/'; p--)
    ;
  p++;

  // Return blank-padded name.
  if(strlen(p) >= DIRSIZ)
    return p;
  memmove(buf, p, strlen(p));
  memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  return buf;
}

void
find(char *path, char *file)
{
  char buf[512], *p;
  int fd;
  struct dirent de;
  struct stat st;

  if((fd = open(path, 0)) < 0){
    fprintf(2, "find: cannot open %s\n", path);
    return;
  }

  if(fstat(fd, &st) < 0){
        fprintf(2,"find: cannot stat %s\n",path);
        close(fd);
        return;
  }

  //if(st.type!=T_DIR){
    //    fprintf(2,"find: %s is not a directory\n",path);
      //  close(fd);
        //return;
  //}
  switch(st.type){
  case T_FILE:
          if(strcmp(fmtname(path),file)==0){
                printf("%s\n", file);
                break;
          }

  case T_DIR:
    if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
      printf("find: path too long\n");
      break;
    }
    strcpy(buf, path);
    //p is a pointer of buf
    p = buf+strlen(buf); //now p point to the end of the buf
    *p++ = '/'; // this makes buf become buf/
    //从当前目录下依次读取文件
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
      if(de.inum == 0)
        continue;
      //skip "." and ".."
      if(strcmp(de.name,".")==0||strcmp(de.name,"..")==0) continue;
      //将得到的文件名加到当前路径后面，得到绝对路径
      memmove(p, de.name, DIRSIZ);
      //设置文件名结束符
      p[DIRSIZ] = 0; // buf becomes buf/de.name
      if(stat(buf, &st) < 0){
        printf("ls: cannot stat %s\n", buf);
        continue;
      }
	  if(st.type==T_FILE && strcmp(de.name,file)==0) printf("%s\n",buf);
	  else if(st.type==T_DIR) find(buf,file);
    }
    break;
  }
  close(fd);
}

int
main(int argc, char *argv[])
{

  if(argc != 3){
          fprintf(2,"Usage: find dirName fileName\n");
    exit(1);
  }
  find(argv[1],argv[2]);
  exit(0);
}

