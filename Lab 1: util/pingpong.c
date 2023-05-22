#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
  int c2p[2];
  int p2c[2];
  char buf[8];
  pipe(c2p);
  pipe(p2c);

  if(fork()==0){
          close(p2c[1]);
          close(c2p[0]);
        read(p2c[0],buf,sizeof(buf));
        printf("%d: received %s\n",getpid(),buf);
        write(c2p[1],"pong",strlen("pong"));
        close(p2c[0]);
        close(c2p[1]);
  }
  else{
          close(p2c[0]);
          close(c2p[1]);
          write(p2c[1],"ping",strlen("ping"));
          wait(0);
          read(c2p[0],buf,sizeof(buf));
          printf("%d: received %s\n",getpid(),buf);
          close(p2c[1]);
          close(c2p[0]);
  }
  exit(0);
}
