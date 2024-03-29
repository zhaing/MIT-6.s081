
user/_cowtest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <simpletest>:
// allocate more than half of physical memory,
// then fork. this will fail in the default
// kernel, which does not support copy-on-write.
void
simpletest()
{
   0:	7179                	add	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	add	s0,sp,48
  uint64 phys_size = PHYSTOP - KERNBASE;
  int sz = (phys_size / 3) * 2;

  printf("simple: ");
   e:	00001517          	auipc	a0,0x1
  12:	c3a50513          	add	a0,a0,-966 # c48 <malloc+0xe8>
  16:	00001097          	auipc	ra,0x1
  1a:	a92080e7          	jalr	-1390(ra) # aa8 <printf>
  
  char *p = sbrk(sz);
  1e:	05555537          	lui	a0,0x5555
  22:	55450513          	add	a0,a0,1364 # 5555554 <__BSS_END__+0x5550744>
  26:	00000097          	auipc	ra,0x0
  2a:	7a2080e7          	jalr	1954(ra) # 7c8 <sbrk>
  if(p == (char*)0xffffffffffffffffL){
  2e:	57fd                	li	a5,-1
  30:	06f50563          	beq	a0,a5,9a <simpletest+0x9a>
  34:	84aa                	mv	s1,a0
    printf("sbrk(%d) failed\n", sz);
    exit(-1);
  }

  for(char *q = p; q < p + sz; q += 4096){
  36:	05556937          	lui	s2,0x5556
  3a:	992a                	add	s2,s2,a0
  3c:	6985                	lui	s3,0x1
    *(int*)q = getpid();
  3e:	00000097          	auipc	ra,0x0
  42:	782080e7          	jalr	1922(ra) # 7c0 <getpid>
  46:	c088                	sw	a0,0(s1)
  for(char *q = p; q < p + sz; q += 4096){
  48:	94ce                	add	s1,s1,s3
  4a:	fe991ae3          	bne	s2,s1,3e <simpletest+0x3e>
  }

  int pid = fork();
  4e:	00000097          	auipc	ra,0x0
  52:	6ea080e7          	jalr	1770(ra) # 738 <fork>
  if(pid < 0){
  56:	06054363          	bltz	a0,bc <simpletest+0xbc>
    printf("fork() failed\n");
    exit(-1);
  }

  if(pid == 0)
  5a:	cd35                	beqz	a0,d6 <simpletest+0xd6>
    exit(0);

  wait(0);
  5c:	4501                	li	a0,0
  5e:	00000097          	auipc	ra,0x0
  62:	6ea080e7          	jalr	1770(ra) # 748 <wait>

  if(sbrk(-sz) == (char*)0xffffffffffffffffL){
  66:	faaab537          	lui	a0,0xfaaab
  6a:	aac50513          	add	a0,a0,-1364 # fffffffffaaaaaac <__BSS_END__+0xfffffffffaaa5c9c>
  6e:	00000097          	auipc	ra,0x0
  72:	75a080e7          	jalr	1882(ra) # 7c8 <sbrk>
  76:	57fd                	li	a5,-1
  78:	06f50363          	beq	a0,a5,de <simpletest+0xde>
    printf("sbrk(-%d) failed\n", sz);
    exit(-1);
  }

  printf("ok\n");
  7c:	00001517          	auipc	a0,0x1
  80:	c1c50513          	add	a0,a0,-996 # c98 <malloc+0x138>
  84:	00001097          	auipc	ra,0x1
  88:	a24080e7          	jalr	-1500(ra) # aa8 <printf>
}
  8c:	70a2                	ld	ra,40(sp)
  8e:	7402                	ld	s0,32(sp)
  90:	64e2                	ld	s1,24(sp)
  92:	6942                	ld	s2,16(sp)
  94:	69a2                	ld	s3,8(sp)
  96:	6145                	add	sp,sp,48
  98:	8082                	ret
    printf("sbrk(%d) failed\n", sz);
  9a:	055555b7          	lui	a1,0x5555
  9e:	55458593          	add	a1,a1,1364 # 5555554 <__BSS_END__+0x5550744>
  a2:	00001517          	auipc	a0,0x1
  a6:	bb650513          	add	a0,a0,-1098 # c58 <malloc+0xf8>
  aa:	00001097          	auipc	ra,0x1
  ae:	9fe080e7          	jalr	-1538(ra) # aa8 <printf>
    exit(-1);
  b2:	557d                	li	a0,-1
  b4:	00000097          	auipc	ra,0x0
  b8:	68c080e7          	jalr	1676(ra) # 740 <exit>
    printf("fork() failed\n");
  bc:	00001517          	auipc	a0,0x1
  c0:	bb450513          	add	a0,a0,-1100 # c70 <malloc+0x110>
  c4:	00001097          	auipc	ra,0x1
  c8:	9e4080e7          	jalr	-1564(ra) # aa8 <printf>
    exit(-1);
  cc:	557d                	li	a0,-1
  ce:	00000097          	auipc	ra,0x0
  d2:	672080e7          	jalr	1650(ra) # 740 <exit>
    exit(0);
  d6:	00000097          	auipc	ra,0x0
  da:	66a080e7          	jalr	1642(ra) # 740 <exit>
    printf("sbrk(-%d) failed\n", sz);
  de:	055555b7          	lui	a1,0x5555
  e2:	55458593          	add	a1,a1,1364 # 5555554 <__BSS_END__+0x5550744>
  e6:	00001517          	auipc	a0,0x1
  ea:	b9a50513          	add	a0,a0,-1126 # c80 <malloc+0x120>
  ee:	00001097          	auipc	ra,0x1
  f2:	9ba080e7          	jalr	-1606(ra) # aa8 <printf>
    exit(-1);
  f6:	557d                	li	a0,-1
  f8:	00000097          	auipc	ra,0x0
  fc:	648080e7          	jalr	1608(ra) # 740 <exit>

0000000000000100 <threetest>:
// this causes more than half of physical memory
// to be allocated, so it also checks whether
// copied pages are freed.
void
threetest()
{
 100:	7179                	add	sp,sp,-48
 102:	f406                	sd	ra,40(sp)
 104:	f022                	sd	s0,32(sp)
 106:	ec26                	sd	s1,24(sp)
 108:	e84a                	sd	s2,16(sp)
 10a:	e44e                	sd	s3,8(sp)
 10c:	e052                	sd	s4,0(sp)
 10e:	1800                	add	s0,sp,48
  uint64 phys_size = PHYSTOP - KERNBASE;
  int sz = phys_size / 4;
  int pid1, pid2;

  printf("three: ");
 110:	00001517          	auipc	a0,0x1
 114:	b9050513          	add	a0,a0,-1136 # ca0 <malloc+0x140>
 118:	00001097          	auipc	ra,0x1
 11c:	990080e7          	jalr	-1648(ra) # aa8 <printf>
  
  char *p = sbrk(sz);
 120:	02000537          	lui	a0,0x2000
 124:	00000097          	auipc	ra,0x0
 128:	6a4080e7          	jalr	1700(ra) # 7c8 <sbrk>
  if(p == (char*)0xffffffffffffffffL){
 12c:	57fd                	li	a5,-1
 12e:	08f50763          	beq	a0,a5,1bc <threetest+0xbc>
 132:	84aa                	mv	s1,a0
    printf("sbrk(%d) failed\n", sz);
    exit(-1);
  }

  pid1 = fork();
 134:	00000097          	auipc	ra,0x0
 138:	604080e7          	jalr	1540(ra) # 738 <fork>
  if(pid1 < 0){
 13c:	08054f63          	bltz	a0,1da <threetest+0xda>
    printf("fork failed\n");
    exit(-1);
  }
  if(pid1 == 0){
 140:	c955                	beqz	a0,1f4 <threetest+0xf4>
      *(int*)q = 9999;
    }
    exit(0);
  }

  for(char *q = p; q < p + sz; q += 4096){
 142:	020009b7          	lui	s3,0x2000
 146:	99a6                	add	s3,s3,s1
 148:	8926                	mv	s2,s1
 14a:	6a05                	lui	s4,0x1
    *(int*)q = getpid();
 14c:	00000097          	auipc	ra,0x0
 150:	674080e7          	jalr	1652(ra) # 7c0 <getpid>
 154:	00a92023          	sw	a0,0(s2) # 5556000 <__BSS_END__+0x55511f0>
  for(char *q = p; q < p + sz; q += 4096){
 158:	9952                	add	s2,s2,s4
 15a:	ff3919e3          	bne	s2,s3,14c <threetest+0x4c>
  }

  wait(0);
 15e:	4501                	li	a0,0
 160:	00000097          	auipc	ra,0x0
 164:	5e8080e7          	jalr	1512(ra) # 748 <wait>

  sleep(1);
 168:	4505                	li	a0,1
 16a:	00000097          	auipc	ra,0x0
 16e:	666080e7          	jalr	1638(ra) # 7d0 <sleep>

  for(char *q = p; q < p + sz; q += 4096){
 172:	6a05                	lui	s4,0x1
    if(*(int*)q != getpid()){
 174:	0004a903          	lw	s2,0(s1)
 178:	00000097          	auipc	ra,0x0
 17c:	648080e7          	jalr	1608(ra) # 7c0 <getpid>
 180:	10a91a63          	bne	s2,a0,294 <threetest+0x194>
  for(char *q = p; q < p + sz; q += 4096){
 184:	94d2                	add	s1,s1,s4
 186:	ff3497e3          	bne	s1,s3,174 <threetest+0x74>
      printf("wrong content\n");
      exit(-1);
    }
  }

  if(sbrk(-sz) == (char*)0xffffffffffffffffL){
 18a:	fe000537          	lui	a0,0xfe000
 18e:	00000097          	auipc	ra,0x0
 192:	63a080e7          	jalr	1594(ra) # 7c8 <sbrk>
 196:	57fd                	li	a5,-1
 198:	10f50b63          	beq	a0,a5,2ae <threetest+0x1ae>
    printf("sbrk(-%d) failed\n", sz);
    exit(-1);
  }

  printf("ok\n");
 19c:	00001517          	auipc	a0,0x1
 1a0:	afc50513          	add	a0,a0,-1284 # c98 <malloc+0x138>
 1a4:	00001097          	auipc	ra,0x1
 1a8:	904080e7          	jalr	-1788(ra) # aa8 <printf>
}
 1ac:	70a2                	ld	ra,40(sp)
 1ae:	7402                	ld	s0,32(sp)
 1b0:	64e2                	ld	s1,24(sp)
 1b2:	6942                	ld	s2,16(sp)
 1b4:	69a2                	ld	s3,8(sp)
 1b6:	6a02                	ld	s4,0(sp)
 1b8:	6145                	add	sp,sp,48
 1ba:	8082                	ret
    printf("sbrk(%d) failed\n", sz);
 1bc:	020005b7          	lui	a1,0x2000
 1c0:	00001517          	auipc	a0,0x1
 1c4:	a9850513          	add	a0,a0,-1384 # c58 <malloc+0xf8>
 1c8:	00001097          	auipc	ra,0x1
 1cc:	8e0080e7          	jalr	-1824(ra) # aa8 <printf>
    exit(-1);
 1d0:	557d                	li	a0,-1
 1d2:	00000097          	auipc	ra,0x0
 1d6:	56e080e7          	jalr	1390(ra) # 740 <exit>
    printf("fork failed\n");
 1da:	00001517          	auipc	a0,0x1
 1de:	ace50513          	add	a0,a0,-1330 # ca8 <malloc+0x148>
 1e2:	00001097          	auipc	ra,0x1
 1e6:	8c6080e7          	jalr	-1850(ra) # aa8 <printf>
    exit(-1);
 1ea:	557d                	li	a0,-1
 1ec:	00000097          	auipc	ra,0x0
 1f0:	554080e7          	jalr	1364(ra) # 740 <exit>
    pid2 = fork();
 1f4:	00000097          	auipc	ra,0x0
 1f8:	544080e7          	jalr	1348(ra) # 738 <fork>
    if(pid2 < 0){
 1fc:	04054263          	bltz	a0,240 <threetest+0x140>
    if(pid2 == 0){
 200:	ed29                	bnez	a0,25a <threetest+0x15a>
      for(char *q = p; q < p + (sz/5)*4; q += 4096){
 202:	0199a9b7          	lui	s3,0x199a
 206:	99a6                	add	s3,s3,s1
 208:	8926                	mv	s2,s1
 20a:	6a05                	lui	s4,0x1
        *(int*)q = getpid();
 20c:	00000097          	auipc	ra,0x0
 210:	5b4080e7          	jalr	1460(ra) # 7c0 <getpid>
 214:	00a92023          	sw	a0,0(s2)
      for(char *q = p; q < p + (sz/5)*4; q += 4096){
 218:	9952                	add	s2,s2,s4
 21a:	ff2999e3          	bne	s3,s2,20c <threetest+0x10c>
      for(char *q = p; q < p + (sz/5)*4; q += 4096){
 21e:	6a05                	lui	s4,0x1
        if(*(int*)q != getpid()){
 220:	0004a903          	lw	s2,0(s1)
 224:	00000097          	auipc	ra,0x0
 228:	59c080e7          	jalr	1436(ra) # 7c0 <getpid>
 22c:	04a91763          	bne	s2,a0,27a <threetest+0x17a>
      for(char *q = p; q < p + (sz/5)*4; q += 4096){
 230:	94d2                	add	s1,s1,s4
 232:	fe9997e3          	bne	s3,s1,220 <threetest+0x120>
      exit(-1);
 236:	557d                	li	a0,-1
 238:	00000097          	auipc	ra,0x0
 23c:	508080e7          	jalr	1288(ra) # 740 <exit>
      printf("fork failed");
 240:	00001517          	auipc	a0,0x1
 244:	a7850513          	add	a0,a0,-1416 # cb8 <malloc+0x158>
 248:	00001097          	auipc	ra,0x1
 24c:	860080e7          	jalr	-1952(ra) # aa8 <printf>
      exit(-1);
 250:	557d                	li	a0,-1
 252:	00000097          	auipc	ra,0x0
 256:	4ee080e7          	jalr	1262(ra) # 740 <exit>
    for(char *q = p; q < p + (sz/2); q += 4096){
 25a:	01000737          	lui	a4,0x1000
 25e:	9726                	add	a4,a4,s1
      *(int*)q = 9999;
 260:	6789                	lui	a5,0x2
 262:	70f78793          	add	a5,a5,1807 # 270f <buf+0x90f>
    for(char *q = p; q < p + (sz/2); q += 4096){
 266:	6685                	lui	a3,0x1
      *(int*)q = 9999;
 268:	c09c                	sw	a5,0(s1)
    for(char *q = p; q < p + (sz/2); q += 4096){
 26a:	94b6                	add	s1,s1,a3
 26c:	fee49ee3          	bne	s1,a4,268 <threetest+0x168>
    exit(0);
 270:	4501                	li	a0,0
 272:	00000097          	auipc	ra,0x0
 276:	4ce080e7          	jalr	1230(ra) # 740 <exit>
          printf("wrong content\n");
 27a:	00001517          	auipc	a0,0x1
 27e:	a4e50513          	add	a0,a0,-1458 # cc8 <malloc+0x168>
 282:	00001097          	auipc	ra,0x1
 286:	826080e7          	jalr	-2010(ra) # aa8 <printf>
          exit(-1);
 28a:	557d                	li	a0,-1
 28c:	00000097          	auipc	ra,0x0
 290:	4b4080e7          	jalr	1204(ra) # 740 <exit>
      printf("wrong content\n");
 294:	00001517          	auipc	a0,0x1
 298:	a3450513          	add	a0,a0,-1484 # cc8 <malloc+0x168>
 29c:	00001097          	auipc	ra,0x1
 2a0:	80c080e7          	jalr	-2036(ra) # aa8 <printf>
      exit(-1);
 2a4:	557d                	li	a0,-1
 2a6:	00000097          	auipc	ra,0x0
 2aa:	49a080e7          	jalr	1178(ra) # 740 <exit>
    printf("sbrk(-%d) failed\n", sz);
 2ae:	020005b7          	lui	a1,0x2000
 2b2:	00001517          	auipc	a0,0x1
 2b6:	9ce50513          	add	a0,a0,-1586 # c80 <malloc+0x120>
 2ba:	00000097          	auipc	ra,0x0
 2be:	7ee080e7          	jalr	2030(ra) # aa8 <printf>
    exit(-1);
 2c2:	557d                	li	a0,-1
 2c4:	00000097          	auipc	ra,0x0
 2c8:	47c080e7          	jalr	1148(ra) # 740 <exit>

00000000000002cc <filetest>:
char junk3[4096];

// test whether copyout() simulates COW faults.
void
filetest()
{
 2cc:	7179                	add	sp,sp,-48
 2ce:	f406                	sd	ra,40(sp)
 2d0:	f022                	sd	s0,32(sp)
 2d2:	ec26                	sd	s1,24(sp)
 2d4:	e84a                	sd	s2,16(sp)
 2d6:	1800                	add	s0,sp,48
  printf("file: ");
 2d8:	00001517          	auipc	a0,0x1
 2dc:	a0050513          	add	a0,a0,-1536 # cd8 <malloc+0x178>
 2e0:	00000097          	auipc	ra,0x0
 2e4:	7c8080e7          	jalr	1992(ra) # aa8 <printf>
  
  buf[0] = 99;
 2e8:	06300793          	li	a5,99
 2ec:	00002717          	auipc	a4,0x2
 2f0:	b0f70a23          	sb	a5,-1260(a4) # 1e00 <buf>

  for(int i = 0; i < 4; i++){
 2f4:	fc042c23          	sw	zero,-40(s0)
    if(pipe(fds) != 0){
 2f8:	00001497          	auipc	s1,0x1
 2fc:	af848493          	add	s1,s1,-1288 # df0 <fds>
  for(int i = 0; i < 4; i++){
 300:	490d                	li	s2,3
    if(pipe(fds) != 0){
 302:	8526                	mv	a0,s1
 304:	00000097          	auipc	ra,0x0
 308:	44c080e7          	jalr	1100(ra) # 750 <pipe>
 30c:	e149                	bnez	a0,38e <filetest+0xc2>
      printf("pipe() failed\n");
      exit(-1);
    }
    int pid = fork();
 30e:	00000097          	auipc	ra,0x0
 312:	42a080e7          	jalr	1066(ra) # 738 <fork>
    if(pid < 0){
 316:	08054963          	bltz	a0,3a8 <filetest+0xdc>
      printf("fork failed\n");
      exit(-1);
    }
    if(pid == 0){
 31a:	c545                	beqz	a0,3c2 <filetest+0xf6>
        printf("error: read the wrong value\n");
        exit(1);
      }
      exit(0);
    }
    if(write(fds[1], &i, sizeof(i)) != sizeof(i)){
 31c:	4611                	li	a2,4
 31e:	fd840593          	add	a1,s0,-40
 322:	40c8                	lw	a0,4(s1)
 324:	00000097          	auipc	ra,0x0
 328:	43c080e7          	jalr	1084(ra) # 760 <write>
 32c:	4791                	li	a5,4
 32e:	10f51b63          	bne	a0,a5,444 <filetest+0x178>
  for(int i = 0; i < 4; i++){
 332:	fd842783          	lw	a5,-40(s0)
 336:	2785                	addw	a5,a5,1
 338:	0007871b          	sext.w	a4,a5
 33c:	fcf42c23          	sw	a5,-40(s0)
 340:	fce951e3          	bge	s2,a4,302 <filetest+0x36>
      printf("error: write failed\n");
      exit(-1);
    }
  }

  int xstatus = 0;
 344:	fc042e23          	sw	zero,-36(s0)
 348:	4491                	li	s1,4
  for(int i = 0; i < 4; i++) {
    wait(&xstatus);
 34a:	fdc40513          	add	a0,s0,-36
 34e:	00000097          	auipc	ra,0x0
 352:	3fa080e7          	jalr	1018(ra) # 748 <wait>
    if(xstatus != 0) {
 356:	fdc42783          	lw	a5,-36(s0)
 35a:	10079263          	bnez	a5,45e <filetest+0x192>
  for(int i = 0; i < 4; i++) {
 35e:	34fd                	addw	s1,s1,-1
 360:	f4ed                	bnez	s1,34a <filetest+0x7e>
      exit(1);
    }
  }

  if(buf[0] != 99){
 362:	00002717          	auipc	a4,0x2
 366:	a9e74703          	lbu	a4,-1378(a4) # 1e00 <buf>
 36a:	06300793          	li	a5,99
 36e:	0ef71d63          	bne	a4,a5,468 <filetest+0x19c>
    printf("error: child overwrote parent\n");
    exit(1);
  }

  printf("ok\n");
 372:	00001517          	auipc	a0,0x1
 376:	92650513          	add	a0,a0,-1754 # c98 <malloc+0x138>
 37a:	00000097          	auipc	ra,0x0
 37e:	72e080e7          	jalr	1838(ra) # aa8 <printf>
}
 382:	70a2                	ld	ra,40(sp)
 384:	7402                	ld	s0,32(sp)
 386:	64e2                	ld	s1,24(sp)
 388:	6942                	ld	s2,16(sp)
 38a:	6145                	add	sp,sp,48
 38c:	8082                	ret
      printf("pipe() failed\n");
 38e:	00001517          	auipc	a0,0x1
 392:	95250513          	add	a0,a0,-1710 # ce0 <malloc+0x180>
 396:	00000097          	auipc	ra,0x0
 39a:	712080e7          	jalr	1810(ra) # aa8 <printf>
      exit(-1);
 39e:	557d                	li	a0,-1
 3a0:	00000097          	auipc	ra,0x0
 3a4:	3a0080e7          	jalr	928(ra) # 740 <exit>
      printf("fork failed\n");
 3a8:	00001517          	auipc	a0,0x1
 3ac:	90050513          	add	a0,a0,-1792 # ca8 <malloc+0x148>
 3b0:	00000097          	auipc	ra,0x0
 3b4:	6f8080e7          	jalr	1784(ra) # aa8 <printf>
      exit(-1);
 3b8:	557d                	li	a0,-1
 3ba:	00000097          	auipc	ra,0x0
 3be:	386080e7          	jalr	902(ra) # 740 <exit>
      sleep(1);
 3c2:	4505                	li	a0,1
 3c4:	00000097          	auipc	ra,0x0
 3c8:	40c080e7          	jalr	1036(ra) # 7d0 <sleep>
      if(read(fds[0], buf, sizeof(i)) != sizeof(i)){
 3cc:	4611                	li	a2,4
 3ce:	00002597          	auipc	a1,0x2
 3d2:	a3258593          	add	a1,a1,-1486 # 1e00 <buf>
 3d6:	00001517          	auipc	a0,0x1
 3da:	a1a52503          	lw	a0,-1510(a0) # df0 <fds>
 3de:	00000097          	auipc	ra,0x0
 3e2:	37a080e7          	jalr	890(ra) # 758 <read>
 3e6:	4791                	li	a5,4
 3e8:	02f51c63          	bne	a0,a5,420 <filetest+0x154>
      sleep(1);
 3ec:	4505                	li	a0,1
 3ee:	00000097          	auipc	ra,0x0
 3f2:	3e2080e7          	jalr	994(ra) # 7d0 <sleep>
      if(j != i){
 3f6:	fd842703          	lw	a4,-40(s0)
 3fa:	00002797          	auipc	a5,0x2
 3fe:	a067a783          	lw	a5,-1530(a5) # 1e00 <buf>
 402:	02f70c63          	beq	a4,a5,43a <filetest+0x16e>
        printf("error: read the wrong value\n");
 406:	00001517          	auipc	a0,0x1
 40a:	90250513          	add	a0,a0,-1790 # d08 <malloc+0x1a8>
 40e:	00000097          	auipc	ra,0x0
 412:	69a080e7          	jalr	1690(ra) # aa8 <printf>
        exit(1);
 416:	4505                	li	a0,1
 418:	00000097          	auipc	ra,0x0
 41c:	328080e7          	jalr	808(ra) # 740 <exit>
        printf("error: read failed\n");
 420:	00001517          	auipc	a0,0x1
 424:	8d050513          	add	a0,a0,-1840 # cf0 <malloc+0x190>
 428:	00000097          	auipc	ra,0x0
 42c:	680080e7          	jalr	1664(ra) # aa8 <printf>
        exit(1);
 430:	4505                	li	a0,1
 432:	00000097          	auipc	ra,0x0
 436:	30e080e7          	jalr	782(ra) # 740 <exit>
      exit(0);
 43a:	4501                	li	a0,0
 43c:	00000097          	auipc	ra,0x0
 440:	304080e7          	jalr	772(ra) # 740 <exit>
      printf("error: write failed\n");
 444:	00001517          	auipc	a0,0x1
 448:	8e450513          	add	a0,a0,-1820 # d28 <malloc+0x1c8>
 44c:	00000097          	auipc	ra,0x0
 450:	65c080e7          	jalr	1628(ra) # aa8 <printf>
      exit(-1);
 454:	557d                	li	a0,-1
 456:	00000097          	auipc	ra,0x0
 45a:	2ea080e7          	jalr	746(ra) # 740 <exit>
      exit(1);
 45e:	4505                	li	a0,1
 460:	00000097          	auipc	ra,0x0
 464:	2e0080e7          	jalr	736(ra) # 740 <exit>
    printf("error: child overwrote parent\n");
 468:	00001517          	auipc	a0,0x1
 46c:	8d850513          	add	a0,a0,-1832 # d40 <malloc+0x1e0>
 470:	00000097          	auipc	ra,0x0
 474:	638080e7          	jalr	1592(ra) # aa8 <printf>
    exit(1);
 478:	4505                	li	a0,1
 47a:	00000097          	auipc	ra,0x0
 47e:	2c6080e7          	jalr	710(ra) # 740 <exit>

0000000000000482 <main>:

int
main(int argc, char *argv[])
{
 482:	1141                	add	sp,sp,-16
 484:	e406                	sd	ra,8(sp)
 486:	e022                	sd	s0,0(sp)
 488:	0800                	add	s0,sp,16
  simpletest();
 48a:	00000097          	auipc	ra,0x0
 48e:	b76080e7          	jalr	-1162(ra) # 0 <simpletest>

  // check that the first simpletest() freed the physical memory.
  simpletest();
 492:	00000097          	auipc	ra,0x0
 496:	b6e080e7          	jalr	-1170(ra) # 0 <simpletest>

  threetest();
 49a:	00000097          	auipc	ra,0x0
 49e:	c66080e7          	jalr	-922(ra) # 100 <threetest>
  threetest();
 4a2:	00000097          	auipc	ra,0x0
 4a6:	c5e080e7          	jalr	-930(ra) # 100 <threetest>
  threetest();
 4aa:	00000097          	auipc	ra,0x0
 4ae:	c56080e7          	jalr	-938(ra) # 100 <threetest>

  filetest();
 4b2:	00000097          	auipc	ra,0x0
 4b6:	e1a080e7          	jalr	-486(ra) # 2cc <filetest>

  printf("ALL COW TESTS PASSED\n");
 4ba:	00001517          	auipc	a0,0x1
 4be:	8a650513          	add	a0,a0,-1882 # d60 <malloc+0x200>
 4c2:	00000097          	auipc	ra,0x0
 4c6:	5e6080e7          	jalr	1510(ra) # aa8 <printf>

  exit(0);
 4ca:	4501                	li	a0,0
 4cc:	00000097          	auipc	ra,0x0
 4d0:	274080e7          	jalr	628(ra) # 740 <exit>

00000000000004d4 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 4d4:	1141                	add	sp,sp,-16
 4d6:	e422                	sd	s0,8(sp)
 4d8:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 4da:	87aa                	mv	a5,a0
 4dc:	0585                	add	a1,a1,1
 4de:	0785                	add	a5,a5,1
 4e0:	fff5c703          	lbu	a4,-1(a1)
 4e4:	fee78fa3          	sb	a4,-1(a5)
 4e8:	fb75                	bnez	a4,4dc <strcpy+0x8>
    ;
  return os;
}
 4ea:	6422                	ld	s0,8(sp)
 4ec:	0141                	add	sp,sp,16
 4ee:	8082                	ret

00000000000004f0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 4f0:	1141                	add	sp,sp,-16
 4f2:	e422                	sd	s0,8(sp)
 4f4:	0800                	add	s0,sp,16
  while(*p && *p == *q)
 4f6:	00054783          	lbu	a5,0(a0)
 4fa:	cb91                	beqz	a5,50e <strcmp+0x1e>
 4fc:	0005c703          	lbu	a4,0(a1)
 500:	00f71763          	bne	a4,a5,50e <strcmp+0x1e>
    p++, q++;
 504:	0505                	add	a0,a0,1
 506:	0585                	add	a1,a1,1
  while(*p && *p == *q)
 508:	00054783          	lbu	a5,0(a0)
 50c:	fbe5                	bnez	a5,4fc <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 50e:	0005c503          	lbu	a0,0(a1)
}
 512:	40a7853b          	subw	a0,a5,a0
 516:	6422                	ld	s0,8(sp)
 518:	0141                	add	sp,sp,16
 51a:	8082                	ret

000000000000051c <strlen>:

uint
strlen(const char *s)
{
 51c:	1141                	add	sp,sp,-16
 51e:	e422                	sd	s0,8(sp)
 520:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 522:	00054783          	lbu	a5,0(a0)
 526:	cf91                	beqz	a5,542 <strlen+0x26>
 528:	0505                	add	a0,a0,1
 52a:	87aa                	mv	a5,a0
 52c:	86be                	mv	a3,a5
 52e:	0785                	add	a5,a5,1
 530:	fff7c703          	lbu	a4,-1(a5)
 534:	ff65                	bnez	a4,52c <strlen+0x10>
 536:	40a6853b          	subw	a0,a3,a0
 53a:	2505                	addw	a0,a0,1
    ;
  return n;
}
 53c:	6422                	ld	s0,8(sp)
 53e:	0141                	add	sp,sp,16
 540:	8082                	ret
  for(n = 0; s[n]; n++)
 542:	4501                	li	a0,0
 544:	bfe5                	j	53c <strlen+0x20>

0000000000000546 <memset>:

void*
memset(void *dst, int c, uint n)
{
 546:	1141                	add	sp,sp,-16
 548:	e422                	sd	s0,8(sp)
 54a:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 54c:	ca19                	beqz	a2,562 <memset+0x1c>
 54e:	87aa                	mv	a5,a0
 550:	1602                	sll	a2,a2,0x20
 552:	9201                	srl	a2,a2,0x20
 554:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 558:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 55c:	0785                	add	a5,a5,1
 55e:	fee79de3          	bne	a5,a4,558 <memset+0x12>
  }
  return dst;
}
 562:	6422                	ld	s0,8(sp)
 564:	0141                	add	sp,sp,16
 566:	8082                	ret

0000000000000568 <strchr>:

char*
strchr(const char *s, char c)
{
 568:	1141                	add	sp,sp,-16
 56a:	e422                	sd	s0,8(sp)
 56c:	0800                	add	s0,sp,16
  for(; *s; s++)
 56e:	00054783          	lbu	a5,0(a0)
 572:	cb99                	beqz	a5,588 <strchr+0x20>
    if(*s == c)
 574:	00f58763          	beq	a1,a5,582 <strchr+0x1a>
  for(; *s; s++)
 578:	0505                	add	a0,a0,1
 57a:	00054783          	lbu	a5,0(a0)
 57e:	fbfd                	bnez	a5,574 <strchr+0xc>
      return (char*)s;
  return 0;
 580:	4501                	li	a0,0
}
 582:	6422                	ld	s0,8(sp)
 584:	0141                	add	sp,sp,16
 586:	8082                	ret
  return 0;
 588:	4501                	li	a0,0
 58a:	bfe5                	j	582 <strchr+0x1a>

000000000000058c <gets>:

char*
gets(char *buf, int max)
{
 58c:	711d                	add	sp,sp,-96
 58e:	ec86                	sd	ra,88(sp)
 590:	e8a2                	sd	s0,80(sp)
 592:	e4a6                	sd	s1,72(sp)
 594:	e0ca                	sd	s2,64(sp)
 596:	fc4e                	sd	s3,56(sp)
 598:	f852                	sd	s4,48(sp)
 59a:	f456                	sd	s5,40(sp)
 59c:	f05a                	sd	s6,32(sp)
 59e:	ec5e                	sd	s7,24(sp)
 5a0:	1080                	add	s0,sp,96
 5a2:	8baa                	mv	s7,a0
 5a4:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 5a6:	892a                	mv	s2,a0
 5a8:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 5aa:	4aa9                	li	s5,10
 5ac:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 5ae:	89a6                	mv	s3,s1
 5b0:	2485                	addw	s1,s1,1
 5b2:	0344d863          	bge	s1,s4,5e2 <gets+0x56>
    cc = read(0, &c, 1);
 5b6:	4605                	li	a2,1
 5b8:	faf40593          	add	a1,s0,-81
 5bc:	4501                	li	a0,0
 5be:	00000097          	auipc	ra,0x0
 5c2:	19a080e7          	jalr	410(ra) # 758 <read>
    if(cc < 1)
 5c6:	00a05e63          	blez	a0,5e2 <gets+0x56>
    buf[i++] = c;
 5ca:	faf44783          	lbu	a5,-81(s0)
 5ce:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 5d2:	01578763          	beq	a5,s5,5e0 <gets+0x54>
 5d6:	0905                	add	s2,s2,1
 5d8:	fd679be3          	bne	a5,s6,5ae <gets+0x22>
  for(i=0; i+1 < max; ){
 5dc:	89a6                	mv	s3,s1
 5de:	a011                	j	5e2 <gets+0x56>
 5e0:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 5e2:	99de                	add	s3,s3,s7
 5e4:	00098023          	sb	zero,0(s3) # 199a000 <__BSS_END__+0x19951f0>
  return buf;
}
 5e8:	855e                	mv	a0,s7
 5ea:	60e6                	ld	ra,88(sp)
 5ec:	6446                	ld	s0,80(sp)
 5ee:	64a6                	ld	s1,72(sp)
 5f0:	6906                	ld	s2,64(sp)
 5f2:	79e2                	ld	s3,56(sp)
 5f4:	7a42                	ld	s4,48(sp)
 5f6:	7aa2                	ld	s5,40(sp)
 5f8:	7b02                	ld	s6,32(sp)
 5fa:	6be2                	ld	s7,24(sp)
 5fc:	6125                	add	sp,sp,96
 5fe:	8082                	ret

0000000000000600 <stat>:

int
stat(const char *n, struct stat *st)
{
 600:	1101                	add	sp,sp,-32
 602:	ec06                	sd	ra,24(sp)
 604:	e822                	sd	s0,16(sp)
 606:	e426                	sd	s1,8(sp)
 608:	e04a                	sd	s2,0(sp)
 60a:	1000                	add	s0,sp,32
 60c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 60e:	4581                	li	a1,0
 610:	00000097          	auipc	ra,0x0
 614:	170080e7          	jalr	368(ra) # 780 <open>
  if(fd < 0)
 618:	02054563          	bltz	a0,642 <stat+0x42>
 61c:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 61e:	85ca                	mv	a1,s2
 620:	00000097          	auipc	ra,0x0
 624:	178080e7          	jalr	376(ra) # 798 <fstat>
 628:	892a                	mv	s2,a0
  close(fd);
 62a:	8526                	mv	a0,s1
 62c:	00000097          	auipc	ra,0x0
 630:	13c080e7          	jalr	316(ra) # 768 <close>
  return r;
}
 634:	854a                	mv	a0,s2
 636:	60e2                	ld	ra,24(sp)
 638:	6442                	ld	s0,16(sp)
 63a:	64a2                	ld	s1,8(sp)
 63c:	6902                	ld	s2,0(sp)
 63e:	6105                	add	sp,sp,32
 640:	8082                	ret
    return -1;
 642:	597d                	li	s2,-1
 644:	bfc5                	j	634 <stat+0x34>

0000000000000646 <atoi>:

int
atoi(const char *s)
{
 646:	1141                	add	sp,sp,-16
 648:	e422                	sd	s0,8(sp)
 64a:	0800                	add	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 64c:	00054683          	lbu	a3,0(a0)
 650:	fd06879b          	addw	a5,a3,-48 # fd0 <junk3+0x1d0>
 654:	0ff7f793          	zext.b	a5,a5
 658:	4625                	li	a2,9
 65a:	02f66863          	bltu	a2,a5,68a <atoi+0x44>
 65e:	872a                	mv	a4,a0
  n = 0;
 660:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 662:	0705                	add	a4,a4,1
 664:	0025179b          	sllw	a5,a0,0x2
 668:	9fa9                	addw	a5,a5,a0
 66a:	0017979b          	sllw	a5,a5,0x1
 66e:	9fb5                	addw	a5,a5,a3
 670:	fd07851b          	addw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 674:	00074683          	lbu	a3,0(a4)
 678:	fd06879b          	addw	a5,a3,-48
 67c:	0ff7f793          	zext.b	a5,a5
 680:	fef671e3          	bgeu	a2,a5,662 <atoi+0x1c>
  return n;
}
 684:	6422                	ld	s0,8(sp)
 686:	0141                	add	sp,sp,16
 688:	8082                	ret
  n = 0;
 68a:	4501                	li	a0,0
 68c:	bfe5                	j	684 <atoi+0x3e>

000000000000068e <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 68e:	1141                	add	sp,sp,-16
 690:	e422                	sd	s0,8(sp)
 692:	0800                	add	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 694:	02b57463          	bgeu	a0,a1,6bc <memmove+0x2e>
    while(n-- > 0)
 698:	00c05f63          	blez	a2,6b6 <memmove+0x28>
 69c:	1602                	sll	a2,a2,0x20
 69e:	9201                	srl	a2,a2,0x20
 6a0:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 6a4:	872a                	mv	a4,a0
      *dst++ = *src++;
 6a6:	0585                	add	a1,a1,1
 6a8:	0705                	add	a4,a4,1
 6aa:	fff5c683          	lbu	a3,-1(a1)
 6ae:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 6b2:	fee79ae3          	bne	a5,a4,6a6 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 6b6:	6422                	ld	s0,8(sp)
 6b8:	0141                	add	sp,sp,16
 6ba:	8082                	ret
    dst += n;
 6bc:	00c50733          	add	a4,a0,a2
    src += n;
 6c0:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 6c2:	fec05ae3          	blez	a2,6b6 <memmove+0x28>
 6c6:	fff6079b          	addw	a5,a2,-1
 6ca:	1782                	sll	a5,a5,0x20
 6cc:	9381                	srl	a5,a5,0x20
 6ce:	fff7c793          	not	a5,a5
 6d2:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 6d4:	15fd                	add	a1,a1,-1
 6d6:	177d                	add	a4,a4,-1
 6d8:	0005c683          	lbu	a3,0(a1)
 6dc:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 6e0:	fee79ae3          	bne	a5,a4,6d4 <memmove+0x46>
 6e4:	bfc9                	j	6b6 <memmove+0x28>

00000000000006e6 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 6e6:	1141                	add	sp,sp,-16
 6e8:	e422                	sd	s0,8(sp)
 6ea:	0800                	add	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 6ec:	ca05                	beqz	a2,71c <memcmp+0x36>
 6ee:	fff6069b          	addw	a3,a2,-1
 6f2:	1682                	sll	a3,a3,0x20
 6f4:	9281                	srl	a3,a3,0x20
 6f6:	0685                	add	a3,a3,1
 6f8:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 6fa:	00054783          	lbu	a5,0(a0)
 6fe:	0005c703          	lbu	a4,0(a1)
 702:	00e79863          	bne	a5,a4,712 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 706:	0505                	add	a0,a0,1
    p2++;
 708:	0585                	add	a1,a1,1
  while (n-- > 0) {
 70a:	fed518e3          	bne	a0,a3,6fa <memcmp+0x14>
  }
  return 0;
 70e:	4501                	li	a0,0
 710:	a019                	j	716 <memcmp+0x30>
      return *p1 - *p2;
 712:	40e7853b          	subw	a0,a5,a4
}
 716:	6422                	ld	s0,8(sp)
 718:	0141                	add	sp,sp,16
 71a:	8082                	ret
  return 0;
 71c:	4501                	li	a0,0
 71e:	bfe5                	j	716 <memcmp+0x30>

0000000000000720 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 720:	1141                	add	sp,sp,-16
 722:	e406                	sd	ra,8(sp)
 724:	e022                	sd	s0,0(sp)
 726:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
 728:	00000097          	auipc	ra,0x0
 72c:	f66080e7          	jalr	-154(ra) # 68e <memmove>
}
 730:	60a2                	ld	ra,8(sp)
 732:	6402                	ld	s0,0(sp)
 734:	0141                	add	sp,sp,16
 736:	8082                	ret

0000000000000738 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 738:	4885                	li	a7,1
 ecall
 73a:	00000073          	ecall
 ret
 73e:	8082                	ret

0000000000000740 <exit>:
.global exit
exit:
 li a7, SYS_exit
 740:	4889                	li	a7,2
 ecall
 742:	00000073          	ecall
 ret
 746:	8082                	ret

0000000000000748 <wait>:
.global wait
wait:
 li a7, SYS_wait
 748:	488d                	li	a7,3
 ecall
 74a:	00000073          	ecall
 ret
 74e:	8082                	ret

0000000000000750 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 750:	4891                	li	a7,4
 ecall
 752:	00000073          	ecall
 ret
 756:	8082                	ret

0000000000000758 <read>:
.global read
read:
 li a7, SYS_read
 758:	4895                	li	a7,5
 ecall
 75a:	00000073          	ecall
 ret
 75e:	8082                	ret

0000000000000760 <write>:
.global write
write:
 li a7, SYS_write
 760:	48c1                	li	a7,16
 ecall
 762:	00000073          	ecall
 ret
 766:	8082                	ret

0000000000000768 <close>:
.global close
close:
 li a7, SYS_close
 768:	48d5                	li	a7,21
 ecall
 76a:	00000073          	ecall
 ret
 76e:	8082                	ret

0000000000000770 <kill>:
.global kill
kill:
 li a7, SYS_kill
 770:	4899                	li	a7,6
 ecall
 772:	00000073          	ecall
 ret
 776:	8082                	ret

0000000000000778 <exec>:
.global exec
exec:
 li a7, SYS_exec
 778:	489d                	li	a7,7
 ecall
 77a:	00000073          	ecall
 ret
 77e:	8082                	ret

0000000000000780 <open>:
.global open
open:
 li a7, SYS_open
 780:	48bd                	li	a7,15
 ecall
 782:	00000073          	ecall
 ret
 786:	8082                	ret

0000000000000788 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 788:	48c5                	li	a7,17
 ecall
 78a:	00000073          	ecall
 ret
 78e:	8082                	ret

0000000000000790 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 790:	48c9                	li	a7,18
 ecall
 792:	00000073          	ecall
 ret
 796:	8082                	ret

0000000000000798 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 798:	48a1                	li	a7,8
 ecall
 79a:	00000073          	ecall
 ret
 79e:	8082                	ret

00000000000007a0 <link>:
.global link
link:
 li a7, SYS_link
 7a0:	48cd                	li	a7,19
 ecall
 7a2:	00000073          	ecall
 ret
 7a6:	8082                	ret

00000000000007a8 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 7a8:	48d1                	li	a7,20
 ecall
 7aa:	00000073          	ecall
 ret
 7ae:	8082                	ret

00000000000007b0 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 7b0:	48a5                	li	a7,9
 ecall
 7b2:	00000073          	ecall
 ret
 7b6:	8082                	ret

00000000000007b8 <dup>:
.global dup
dup:
 li a7, SYS_dup
 7b8:	48a9                	li	a7,10
 ecall
 7ba:	00000073          	ecall
 ret
 7be:	8082                	ret

00000000000007c0 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 7c0:	48ad                	li	a7,11
 ecall
 7c2:	00000073          	ecall
 ret
 7c6:	8082                	ret

00000000000007c8 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 7c8:	48b1                	li	a7,12
 ecall
 7ca:	00000073          	ecall
 ret
 7ce:	8082                	ret

00000000000007d0 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 7d0:	48b5                	li	a7,13
 ecall
 7d2:	00000073          	ecall
 ret
 7d6:	8082                	ret

00000000000007d8 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 7d8:	48b9                	li	a7,14
 ecall
 7da:	00000073          	ecall
 ret
 7de:	8082                	ret

00000000000007e0 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 7e0:	1101                	add	sp,sp,-32
 7e2:	ec06                	sd	ra,24(sp)
 7e4:	e822                	sd	s0,16(sp)
 7e6:	1000                	add	s0,sp,32
 7e8:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 7ec:	4605                	li	a2,1
 7ee:	fef40593          	add	a1,s0,-17
 7f2:	00000097          	auipc	ra,0x0
 7f6:	f6e080e7          	jalr	-146(ra) # 760 <write>
}
 7fa:	60e2                	ld	ra,24(sp)
 7fc:	6442                	ld	s0,16(sp)
 7fe:	6105                	add	sp,sp,32
 800:	8082                	ret

0000000000000802 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 802:	7139                	add	sp,sp,-64
 804:	fc06                	sd	ra,56(sp)
 806:	f822                	sd	s0,48(sp)
 808:	f426                	sd	s1,40(sp)
 80a:	f04a                	sd	s2,32(sp)
 80c:	ec4e                	sd	s3,24(sp)
 80e:	0080                	add	s0,sp,64
 810:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 812:	c299                	beqz	a3,818 <printint+0x16>
 814:	0805c963          	bltz	a1,8a6 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 818:	2581                	sext.w	a1,a1
  neg = 0;
 81a:	4881                	li	a7,0
 81c:	fc040693          	add	a3,s0,-64
  }

  i = 0;
 820:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 822:	2601                	sext.w	a2,a2
 824:	00000517          	auipc	a0,0x0
 828:	5b450513          	add	a0,a0,1460 # dd8 <digits>
 82c:	883a                	mv	a6,a4
 82e:	2705                	addw	a4,a4,1
 830:	02c5f7bb          	remuw	a5,a1,a2
 834:	1782                	sll	a5,a5,0x20
 836:	9381                	srl	a5,a5,0x20
 838:	97aa                	add	a5,a5,a0
 83a:	0007c783          	lbu	a5,0(a5)
 83e:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 842:	0005879b          	sext.w	a5,a1
 846:	02c5d5bb          	divuw	a1,a1,a2
 84a:	0685                	add	a3,a3,1
 84c:	fec7f0e3          	bgeu	a5,a2,82c <printint+0x2a>
  if(neg)
 850:	00088c63          	beqz	a7,868 <printint+0x66>
    buf[i++] = '-';
 854:	fd070793          	add	a5,a4,-48
 858:	00878733          	add	a4,a5,s0
 85c:	02d00793          	li	a5,45
 860:	fef70823          	sb	a5,-16(a4)
 864:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
 868:	02e05863          	blez	a4,898 <printint+0x96>
 86c:	fc040793          	add	a5,s0,-64
 870:	00e78933          	add	s2,a5,a4
 874:	fff78993          	add	s3,a5,-1
 878:	99ba                	add	s3,s3,a4
 87a:	377d                	addw	a4,a4,-1
 87c:	1702                	sll	a4,a4,0x20
 87e:	9301                	srl	a4,a4,0x20
 880:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 884:	fff94583          	lbu	a1,-1(s2)
 888:	8526                	mv	a0,s1
 88a:	00000097          	auipc	ra,0x0
 88e:	f56080e7          	jalr	-170(ra) # 7e0 <putc>
  while(--i >= 0)
 892:	197d                	add	s2,s2,-1
 894:	ff3918e3          	bne	s2,s3,884 <printint+0x82>
}
 898:	70e2                	ld	ra,56(sp)
 89a:	7442                	ld	s0,48(sp)
 89c:	74a2                	ld	s1,40(sp)
 89e:	7902                	ld	s2,32(sp)
 8a0:	69e2                	ld	s3,24(sp)
 8a2:	6121                	add	sp,sp,64
 8a4:	8082                	ret
    x = -xx;
 8a6:	40b005bb          	negw	a1,a1
    neg = 1;
 8aa:	4885                	li	a7,1
    x = -xx;
 8ac:	bf85                	j	81c <printint+0x1a>

00000000000008ae <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 8ae:	715d                	add	sp,sp,-80
 8b0:	e486                	sd	ra,72(sp)
 8b2:	e0a2                	sd	s0,64(sp)
 8b4:	fc26                	sd	s1,56(sp)
 8b6:	f84a                	sd	s2,48(sp)
 8b8:	f44e                	sd	s3,40(sp)
 8ba:	f052                	sd	s4,32(sp)
 8bc:	ec56                	sd	s5,24(sp)
 8be:	e85a                	sd	s6,16(sp)
 8c0:	e45e                	sd	s7,8(sp)
 8c2:	e062                	sd	s8,0(sp)
 8c4:	0880                	add	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 8c6:	0005c903          	lbu	s2,0(a1)
 8ca:	18090c63          	beqz	s2,a62 <vprintf+0x1b4>
 8ce:	8aaa                	mv	s5,a0
 8d0:	8bb2                	mv	s7,a2
 8d2:	00158493          	add	s1,a1,1
  state = 0;
 8d6:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 8d8:	02500a13          	li	s4,37
 8dc:	4b55                	li	s6,21
 8de:	a839                	j	8fc <vprintf+0x4e>
        putc(fd, c);
 8e0:	85ca                	mv	a1,s2
 8e2:	8556                	mv	a0,s5
 8e4:	00000097          	auipc	ra,0x0
 8e8:	efc080e7          	jalr	-260(ra) # 7e0 <putc>
 8ec:	a019                	j	8f2 <vprintf+0x44>
    } else if(state == '%'){
 8ee:	01498d63          	beq	s3,s4,908 <vprintf+0x5a>
  for(i = 0; fmt[i]; i++){
 8f2:	0485                	add	s1,s1,1
 8f4:	fff4c903          	lbu	s2,-1(s1)
 8f8:	16090563          	beqz	s2,a62 <vprintf+0x1b4>
    if(state == 0){
 8fc:	fe0999e3          	bnez	s3,8ee <vprintf+0x40>
      if(c == '%'){
 900:	ff4910e3          	bne	s2,s4,8e0 <vprintf+0x32>
        state = '%';
 904:	89d2                	mv	s3,s4
 906:	b7f5                	j	8f2 <vprintf+0x44>
      if(c == 'd'){
 908:	13490263          	beq	s2,s4,a2c <vprintf+0x17e>
 90c:	f9d9079b          	addw	a5,s2,-99
 910:	0ff7f793          	zext.b	a5,a5
 914:	12fb6563          	bltu	s6,a5,a3e <vprintf+0x190>
 918:	f9d9079b          	addw	a5,s2,-99
 91c:	0ff7f713          	zext.b	a4,a5
 920:	10eb6f63          	bltu	s6,a4,a3e <vprintf+0x190>
 924:	00271793          	sll	a5,a4,0x2
 928:	00000717          	auipc	a4,0x0
 92c:	45870713          	add	a4,a4,1112 # d80 <malloc+0x220>
 930:	97ba                	add	a5,a5,a4
 932:	439c                	lw	a5,0(a5)
 934:	97ba                	add	a5,a5,a4
 936:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 938:	008b8913          	add	s2,s7,8
 93c:	4685                	li	a3,1
 93e:	4629                	li	a2,10
 940:	000ba583          	lw	a1,0(s7)
 944:	8556                	mv	a0,s5
 946:	00000097          	auipc	ra,0x0
 94a:	ebc080e7          	jalr	-324(ra) # 802 <printint>
 94e:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 950:	4981                	li	s3,0
 952:	b745                	j	8f2 <vprintf+0x44>
        printint(fd, va_arg(ap, uint64), 10, 0);
 954:	008b8913          	add	s2,s7,8
 958:	4681                	li	a3,0
 95a:	4629                	li	a2,10
 95c:	000ba583          	lw	a1,0(s7)
 960:	8556                	mv	a0,s5
 962:	00000097          	auipc	ra,0x0
 966:	ea0080e7          	jalr	-352(ra) # 802 <printint>
 96a:	8bca                	mv	s7,s2
      state = 0;
 96c:	4981                	li	s3,0
 96e:	b751                	j	8f2 <vprintf+0x44>
        printint(fd, va_arg(ap, int), 16, 0);
 970:	008b8913          	add	s2,s7,8
 974:	4681                	li	a3,0
 976:	4641                	li	a2,16
 978:	000ba583          	lw	a1,0(s7)
 97c:	8556                	mv	a0,s5
 97e:	00000097          	auipc	ra,0x0
 982:	e84080e7          	jalr	-380(ra) # 802 <printint>
 986:	8bca                	mv	s7,s2
      state = 0;
 988:	4981                	li	s3,0
 98a:	b7a5                	j	8f2 <vprintf+0x44>
        printptr(fd, va_arg(ap, uint64));
 98c:	008b8c13          	add	s8,s7,8
 990:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 994:	03000593          	li	a1,48
 998:	8556                	mv	a0,s5
 99a:	00000097          	auipc	ra,0x0
 99e:	e46080e7          	jalr	-442(ra) # 7e0 <putc>
  putc(fd, 'x');
 9a2:	07800593          	li	a1,120
 9a6:	8556                	mv	a0,s5
 9a8:	00000097          	auipc	ra,0x0
 9ac:	e38080e7          	jalr	-456(ra) # 7e0 <putc>
 9b0:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 9b2:	00000b97          	auipc	s7,0x0
 9b6:	426b8b93          	add	s7,s7,1062 # dd8 <digits>
 9ba:	03c9d793          	srl	a5,s3,0x3c
 9be:	97de                	add	a5,a5,s7
 9c0:	0007c583          	lbu	a1,0(a5)
 9c4:	8556                	mv	a0,s5
 9c6:	00000097          	auipc	ra,0x0
 9ca:	e1a080e7          	jalr	-486(ra) # 7e0 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 9ce:	0992                	sll	s3,s3,0x4
 9d0:	397d                	addw	s2,s2,-1
 9d2:	fe0914e3          	bnez	s2,9ba <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 9d6:	8be2                	mv	s7,s8
      state = 0;
 9d8:	4981                	li	s3,0
 9da:	bf21                	j	8f2 <vprintf+0x44>
        s = va_arg(ap, char*);
 9dc:	008b8993          	add	s3,s7,8
 9e0:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 9e4:	02090163          	beqz	s2,a06 <vprintf+0x158>
        while(*s != 0){
 9e8:	00094583          	lbu	a1,0(s2)
 9ec:	c9a5                	beqz	a1,a5c <vprintf+0x1ae>
          putc(fd, *s);
 9ee:	8556                	mv	a0,s5
 9f0:	00000097          	auipc	ra,0x0
 9f4:	df0080e7          	jalr	-528(ra) # 7e0 <putc>
          s++;
 9f8:	0905                	add	s2,s2,1
        while(*s != 0){
 9fa:	00094583          	lbu	a1,0(s2)
 9fe:	f9e5                	bnez	a1,9ee <vprintf+0x140>
        s = va_arg(ap, char*);
 a00:	8bce                	mv	s7,s3
      state = 0;
 a02:	4981                	li	s3,0
 a04:	b5fd                	j	8f2 <vprintf+0x44>
          s = "(null)";
 a06:	00000917          	auipc	s2,0x0
 a0a:	37290913          	add	s2,s2,882 # d78 <malloc+0x218>
        while(*s != 0){
 a0e:	02800593          	li	a1,40
 a12:	bff1                	j	9ee <vprintf+0x140>
        putc(fd, va_arg(ap, uint));
 a14:	008b8913          	add	s2,s7,8
 a18:	000bc583          	lbu	a1,0(s7)
 a1c:	8556                	mv	a0,s5
 a1e:	00000097          	auipc	ra,0x0
 a22:	dc2080e7          	jalr	-574(ra) # 7e0 <putc>
 a26:	8bca                	mv	s7,s2
      state = 0;
 a28:	4981                	li	s3,0
 a2a:	b5e1                	j	8f2 <vprintf+0x44>
        putc(fd, c);
 a2c:	02500593          	li	a1,37
 a30:	8556                	mv	a0,s5
 a32:	00000097          	auipc	ra,0x0
 a36:	dae080e7          	jalr	-594(ra) # 7e0 <putc>
      state = 0;
 a3a:	4981                	li	s3,0
 a3c:	bd5d                	j	8f2 <vprintf+0x44>
        putc(fd, '%');
 a3e:	02500593          	li	a1,37
 a42:	8556                	mv	a0,s5
 a44:	00000097          	auipc	ra,0x0
 a48:	d9c080e7          	jalr	-612(ra) # 7e0 <putc>
        putc(fd, c);
 a4c:	85ca                	mv	a1,s2
 a4e:	8556                	mv	a0,s5
 a50:	00000097          	auipc	ra,0x0
 a54:	d90080e7          	jalr	-624(ra) # 7e0 <putc>
      state = 0;
 a58:	4981                	li	s3,0
 a5a:	bd61                	j	8f2 <vprintf+0x44>
        s = va_arg(ap, char*);
 a5c:	8bce                	mv	s7,s3
      state = 0;
 a5e:	4981                	li	s3,0
 a60:	bd49                	j	8f2 <vprintf+0x44>
    }
  }
}
 a62:	60a6                	ld	ra,72(sp)
 a64:	6406                	ld	s0,64(sp)
 a66:	74e2                	ld	s1,56(sp)
 a68:	7942                	ld	s2,48(sp)
 a6a:	79a2                	ld	s3,40(sp)
 a6c:	7a02                	ld	s4,32(sp)
 a6e:	6ae2                	ld	s5,24(sp)
 a70:	6b42                	ld	s6,16(sp)
 a72:	6ba2                	ld	s7,8(sp)
 a74:	6c02                	ld	s8,0(sp)
 a76:	6161                	add	sp,sp,80
 a78:	8082                	ret

0000000000000a7a <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 a7a:	715d                	add	sp,sp,-80
 a7c:	ec06                	sd	ra,24(sp)
 a7e:	e822                	sd	s0,16(sp)
 a80:	1000                	add	s0,sp,32
 a82:	e010                	sd	a2,0(s0)
 a84:	e414                	sd	a3,8(s0)
 a86:	e818                	sd	a4,16(s0)
 a88:	ec1c                	sd	a5,24(s0)
 a8a:	03043023          	sd	a6,32(s0)
 a8e:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 a92:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 a96:	8622                	mv	a2,s0
 a98:	00000097          	auipc	ra,0x0
 a9c:	e16080e7          	jalr	-490(ra) # 8ae <vprintf>
}
 aa0:	60e2                	ld	ra,24(sp)
 aa2:	6442                	ld	s0,16(sp)
 aa4:	6161                	add	sp,sp,80
 aa6:	8082                	ret

0000000000000aa8 <printf>:

void
printf(const char *fmt, ...)
{
 aa8:	711d                	add	sp,sp,-96
 aaa:	ec06                	sd	ra,24(sp)
 aac:	e822                	sd	s0,16(sp)
 aae:	1000                	add	s0,sp,32
 ab0:	e40c                	sd	a1,8(s0)
 ab2:	e810                	sd	a2,16(s0)
 ab4:	ec14                	sd	a3,24(s0)
 ab6:	f018                	sd	a4,32(s0)
 ab8:	f41c                	sd	a5,40(s0)
 aba:	03043823          	sd	a6,48(s0)
 abe:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 ac2:	00840613          	add	a2,s0,8
 ac6:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 aca:	85aa                	mv	a1,a0
 acc:	4505                	li	a0,1
 ace:	00000097          	auipc	ra,0x0
 ad2:	de0080e7          	jalr	-544(ra) # 8ae <vprintf>
}
 ad6:	60e2                	ld	ra,24(sp)
 ad8:	6442                	ld	s0,16(sp)
 ada:	6125                	add	sp,sp,96
 adc:	8082                	ret

0000000000000ade <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 ade:	1141                	add	sp,sp,-16
 ae0:	e422                	sd	s0,8(sp)
 ae2:	0800                	add	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 ae4:	ff050693          	add	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 ae8:	00000797          	auipc	a5,0x0
 aec:	3107b783          	ld	a5,784(a5) # df8 <freep>
 af0:	a02d                	j	b1a <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 af2:	4618                	lw	a4,8(a2)
 af4:	9f2d                	addw	a4,a4,a1
 af6:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 afa:	6398                	ld	a4,0(a5)
 afc:	6310                	ld	a2,0(a4)
 afe:	a83d                	j	b3c <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 b00:	ff852703          	lw	a4,-8(a0)
 b04:	9f31                	addw	a4,a4,a2
 b06:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 b08:	ff053683          	ld	a3,-16(a0)
 b0c:	a091                	j	b50 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 b0e:	6398                	ld	a4,0(a5)
 b10:	00e7e463          	bltu	a5,a4,b18 <free+0x3a>
 b14:	00e6ea63          	bltu	a3,a4,b28 <free+0x4a>
{
 b18:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 b1a:	fed7fae3          	bgeu	a5,a3,b0e <free+0x30>
 b1e:	6398                	ld	a4,0(a5)
 b20:	00e6e463          	bltu	a3,a4,b28 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 b24:	fee7eae3          	bltu	a5,a4,b18 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 b28:	ff852583          	lw	a1,-8(a0)
 b2c:	6390                	ld	a2,0(a5)
 b2e:	02059813          	sll	a6,a1,0x20
 b32:	01c85713          	srl	a4,a6,0x1c
 b36:	9736                	add	a4,a4,a3
 b38:	fae60de3          	beq	a2,a4,af2 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 b3c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 b40:	4790                	lw	a2,8(a5)
 b42:	02061593          	sll	a1,a2,0x20
 b46:	01c5d713          	srl	a4,a1,0x1c
 b4a:	973e                	add	a4,a4,a5
 b4c:	fae68ae3          	beq	a3,a4,b00 <free+0x22>
    p->s.ptr = bp->s.ptr;
 b50:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 b52:	00000717          	auipc	a4,0x0
 b56:	2af73323          	sd	a5,678(a4) # df8 <freep>
}
 b5a:	6422                	ld	s0,8(sp)
 b5c:	0141                	add	sp,sp,16
 b5e:	8082                	ret

0000000000000b60 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 b60:	7139                	add	sp,sp,-64
 b62:	fc06                	sd	ra,56(sp)
 b64:	f822                	sd	s0,48(sp)
 b66:	f426                	sd	s1,40(sp)
 b68:	f04a                	sd	s2,32(sp)
 b6a:	ec4e                	sd	s3,24(sp)
 b6c:	e852                	sd	s4,16(sp)
 b6e:	e456                	sd	s5,8(sp)
 b70:	e05a                	sd	s6,0(sp)
 b72:	0080                	add	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 b74:	02051493          	sll	s1,a0,0x20
 b78:	9081                	srl	s1,s1,0x20
 b7a:	04bd                	add	s1,s1,15
 b7c:	8091                	srl	s1,s1,0x4
 b7e:	0014899b          	addw	s3,s1,1
 b82:	0485                	add	s1,s1,1
  if((prevp = freep) == 0){
 b84:	00000517          	auipc	a0,0x0
 b88:	27453503          	ld	a0,628(a0) # df8 <freep>
 b8c:	c515                	beqz	a0,bb8 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 b8e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 b90:	4798                	lw	a4,8(a5)
 b92:	02977f63          	bgeu	a4,s1,bd0 <malloc+0x70>
  if(nu < 4096)
 b96:	8a4e                	mv	s4,s3
 b98:	0009871b          	sext.w	a4,s3
 b9c:	6685                	lui	a3,0x1
 b9e:	00d77363          	bgeu	a4,a3,ba4 <malloc+0x44>
 ba2:	6a05                	lui	s4,0x1
 ba4:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 ba8:	004a1a1b          	sllw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 bac:	00000917          	auipc	s2,0x0
 bb0:	24c90913          	add	s2,s2,588 # df8 <freep>
  if(p == (char*)-1)
 bb4:	5afd                	li	s5,-1
 bb6:	a895                	j	c2a <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 bb8:	00004797          	auipc	a5,0x4
 bbc:	24878793          	add	a5,a5,584 # 4e00 <base>
 bc0:	00000717          	auipc	a4,0x0
 bc4:	22f73c23          	sd	a5,568(a4) # df8 <freep>
 bc8:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 bca:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 bce:	b7e1                	j	b96 <malloc+0x36>
      if(p->s.size == nunits)
 bd0:	02e48c63          	beq	s1,a4,c08 <malloc+0xa8>
        p->s.size -= nunits;
 bd4:	4137073b          	subw	a4,a4,s3
 bd8:	c798                	sw	a4,8(a5)
        p += p->s.size;
 bda:	02071693          	sll	a3,a4,0x20
 bde:	01c6d713          	srl	a4,a3,0x1c
 be2:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 be4:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 be8:	00000717          	auipc	a4,0x0
 bec:	20a73823          	sd	a0,528(a4) # df8 <freep>
      return (void*)(p + 1);
 bf0:	01078513          	add	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 bf4:	70e2                	ld	ra,56(sp)
 bf6:	7442                	ld	s0,48(sp)
 bf8:	74a2                	ld	s1,40(sp)
 bfa:	7902                	ld	s2,32(sp)
 bfc:	69e2                	ld	s3,24(sp)
 bfe:	6a42                	ld	s4,16(sp)
 c00:	6aa2                	ld	s5,8(sp)
 c02:	6b02                	ld	s6,0(sp)
 c04:	6121                	add	sp,sp,64
 c06:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 c08:	6398                	ld	a4,0(a5)
 c0a:	e118                	sd	a4,0(a0)
 c0c:	bff1                	j	be8 <malloc+0x88>
  hp->s.size = nu;
 c0e:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 c12:	0541                	add	a0,a0,16
 c14:	00000097          	auipc	ra,0x0
 c18:	eca080e7          	jalr	-310(ra) # ade <free>
  return freep;
 c1c:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 c20:	d971                	beqz	a0,bf4 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 c22:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 c24:	4798                	lw	a4,8(a5)
 c26:	fa9775e3          	bgeu	a4,s1,bd0 <malloc+0x70>
    if(p == freep)
 c2a:	00093703          	ld	a4,0(s2)
 c2e:	853e                	mv	a0,a5
 c30:	fef719e3          	bne	a4,a5,c22 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 c34:	8552                	mv	a0,s4
 c36:	00000097          	auipc	ra,0x0
 c3a:	b92080e7          	jalr	-1134(ra) # 7c8 <sbrk>
  if(p == (char*)-1)
 c3e:	fd5518e3          	bne	a0,s5,c0e <malloc+0xae>
        return 0;
 c42:	4501                	li	a0,0
 c44:	bf45                	j	bf4 <malloc+0x94>
