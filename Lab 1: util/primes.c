#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#define intsize sizeof(int) 

void reio(int n, int p[])
{
	close(n);
	dup(p[n]);
	close(p[0]);
	close(p[1]);
}

void
process(){
	int prev;
	int cur;
	int p[2];
	pipe(p);
	if(read(0,&prev,intsize)){
		printf("prime %d\n",prev);
		pipe(p);
		if(fork()==0){
			close(1);
			dup(p[1]);
			close(p[1]);
			close(p[0]);
			while(read(0,&cur,intsize))
			{
				if(cur%prev!=0) write(1,&cur,intsize);
			}
		}
		else
		{
			wait(0);
			close(0);
			dup(p[0]);
			close(p[0]);
			close(p[1]);
			process();
		}
	}
}
		

int
main(int argc,char *argv[])
{
	int p[2];
	pipe(p);

	if(fork()==0){
		close(p[0]);
		close(1);
		dup(p[1]);
		close(p[1]);
		for(int i=2;i<36;i++){
			write(1,&i,intsize);
		}
	}
	else{
		wait(0);
		close(0);
		dup(p[0]);
		close(p[0]);
		close(p[1]);
		process();
	}
	exit(0);
}
