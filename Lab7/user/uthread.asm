
user/_uthread:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <thread_init>:
struct thread *current_thread;
extern void thread_switch(struct th_context*, struct th_context*);
              
void 
thread_init(void)
{
   0:	1141                	add	sp,sp,-16
   2:	e422                	sd	s0,8(sp)
   4:	0800                	add	s0,sp,16
  // main() is thread 0, which will make the first invocation to
  // thread_schedule().  it needs a stack so that the first thread_switch() can
  // save thread 0's state.  thread_schedule() won't run the main thread ever
  // again, because its state is set to RUNNING, and thread_schedule() selects
  // a RUNNABLE thread.
  current_thread = &all_thread[0];
   6:	00001797          	auipc	a5,0x1
   a:	d7a78793          	add	a5,a5,-646 # d80 <all_thread>
   e:	00001717          	auipc	a4,0x1
  12:	d6f73123          	sd	a5,-670(a4) # d70 <current_thread>
  current_thread->state = RUNNING;
  16:	4785                	li	a5,1
  18:	00003717          	auipc	a4,0x3
  1c:	d6f72423          	sw	a5,-664(a4) # 2d80 <__global_pointer$+0x182f>
}
  20:	6422                	ld	s0,8(sp)
  22:	0141                	add	sp,sp,16
  24:	8082                	ret

0000000000000026 <thread_schedule>:

void 
thread_schedule(void)
{
  26:	1141                	add	sp,sp,-16
  28:	e406                	sd	ra,8(sp)
  2a:	e022                	sd	s0,0(sp)
  2c:	0800                	add	s0,sp,16
  struct thread *t, *next_thread;

  /* Find another runnable thread. */
  next_thread = 0;
  t = current_thread + 1;
  2e:	00001317          	auipc	t1,0x1
  32:	d4233303          	ld	t1,-702(t1) # d70 <current_thread>
  36:	6589                	lui	a1,0x2
  38:	07858593          	add	a1,a1,120 # 2078 <__global_pointer$+0xb27>
  3c:	959a                	add	a1,a1,t1
  3e:	4791                	li	a5,4
  for(int i = 0; i < MAX_THREAD; i++){
    if(t >= all_thread + MAX_THREAD)
  40:	00009817          	auipc	a6,0x9
  44:	f2080813          	add	a6,a6,-224 # 8f60 <base>
      t = all_thread;
    if(t->state == RUNNABLE) {
  48:	6689                	lui	a3,0x2
  4a:	4609                	li	a2,2
      next_thread = t;
      break;
    }
    t = t + 1;
  4c:	07868893          	add	a7,a3,120 # 2078 <__global_pointer$+0xb27>
  50:	a809                	j	62 <thread_schedule+0x3c>
    if(t->state == RUNNABLE) {
  52:	00d58733          	add	a4,a1,a3
  56:	4318                	lw	a4,0(a4)
  58:	02c70963          	beq	a4,a2,8a <thread_schedule+0x64>
    t = t + 1;
  5c:	95c6                	add	a1,a1,a7
  for(int i = 0; i < MAX_THREAD; i++){
  5e:	37fd                	addw	a5,a5,-1
  60:	cb81                	beqz	a5,70 <thread_schedule+0x4a>
    if(t >= all_thread + MAX_THREAD)
  62:	ff05e8e3          	bltu	a1,a6,52 <thread_schedule+0x2c>
      t = all_thread;
  66:	00001597          	auipc	a1,0x1
  6a:	d1a58593          	add	a1,a1,-742 # d80 <all_thread>
  6e:	b7d5                	j	52 <thread_schedule+0x2c>
  }

  if (next_thread == 0) {
    printf("thread_schedule: no runnable threads\n");
  70:	00001517          	auipc	a0,0x1
  74:	b7050513          	add	a0,a0,-1168 # be0 <malloc+0xea>
  78:	00001097          	auipc	ra,0x1
  7c:	9c6080e7          	jalr	-1594(ra) # a3e <printf>
    exit(-1);
  80:	557d                	li	a0,-1
  82:	00000097          	auipc	ra,0x0
  86:	654080e7          	jalr	1620(ra) # 6d6 <exit>
  }

  if (current_thread != next_thread) {         /* switch threads?  */
  8a:	02b30263          	beq	t1,a1,ae <thread_schedule+0x88>
    next_thread->state = RUNNING;
  8e:	6509                	lui	a0,0x2
  90:	00a587b3          	add	a5,a1,a0
  94:	4705                	li	a4,1
  96:	c398                	sw	a4,0(a5)
    t = current_thread;
    current_thread = next_thread;
  98:	00001797          	auipc	a5,0x1
  9c:	ccb7bc23          	sd	a1,-808(a5) # d70 <current_thread>
    /* YOUR CODE HERE
     * Invoke thread_switch to switch from t to next_thread:
     * thread_switch(??, ??);
     */
    thread_switch(&t->thread_context, &current_thread->thread_context);
  a0:	0521                	add	a0,a0,8 # 2008 <__global_pointer$+0xab7>
  a2:	95aa                	add	a1,a1,a0
  a4:	951a                	add	a0,a0,t1
  a6:	00000097          	auipc	ra,0x0
  aa:	35a080e7          	jalr	858(ra) # 400 <thread_switch>
  } else
    next_thread = 0;
}
  ae:	60a2                	ld	ra,8(sp)
  b0:	6402                	ld	s0,0(sp)
  b2:	0141                	add	sp,sp,16
  b4:	8082                	ret

00000000000000b6 <thread_create>:

void 
thread_create(void (*func)())
{
  b6:	1141                	add	sp,sp,-16
  b8:	e422                	sd	s0,8(sp)
  ba:	0800                	add	s0,sp,16
  struct thread *t;

  for (t = all_thread; t < all_thread + MAX_THREAD; t++) {
  bc:	00001797          	auipc	a5,0x1
  c0:	cc478793          	add	a5,a5,-828 # d80 <all_thread>
    if (t->state == FREE) break;
  c4:	6689                	lui	a3,0x2
  for (t = all_thread; t < all_thread + MAX_THREAD; t++) {
  c6:	07868593          	add	a1,a3,120 # 2078 <__global_pointer$+0xb27>
  ca:	00009617          	auipc	a2,0x9
  ce:	e9660613          	add	a2,a2,-362 # 8f60 <base>
    if (t->state == FREE) break;
  d2:	00d78733          	add	a4,a5,a3
  d6:	4318                	lw	a4,0(a4)
  d8:	c701                	beqz	a4,e0 <thread_create+0x2a>
  for (t = all_thread; t < all_thread + MAX_THREAD; t++) {
  da:	97ae                	add	a5,a5,a1
  dc:	fec79be3          	bne	a5,a2,d2 <thread_create+0x1c>
  }
  t->state = RUNNABLE;
  e0:	6709                	lui	a4,0x2
  e2:	97ba                	add	a5,a5,a4
  e4:	4709                	li	a4,2
  e6:	c398                	sw	a4,0(a5)
  // YOUR CODE HERE
  t->thread_context.ra = (uint64) func;
  e8:	e788                	sd	a0,8(a5)
  t->thread_context.sp = (uint64) t->stack + STACK_SIZE;
  ea:	eb9c                	sd	a5,16(a5)
}
  ec:	6422                	ld	s0,8(sp)
  ee:	0141                	add	sp,sp,16
  f0:	8082                	ret

00000000000000f2 <thread_yield>:

void 
thread_yield(void)
{
  f2:	1141                	add	sp,sp,-16
  f4:	e406                	sd	ra,8(sp)
  f6:	e022                	sd	s0,0(sp)
  f8:	0800                	add	s0,sp,16
  current_thread->state = RUNNABLE;
  fa:	00001797          	auipc	a5,0x1
  fe:	c767b783          	ld	a5,-906(a5) # d70 <current_thread>
 102:	6709                	lui	a4,0x2
 104:	97ba                	add	a5,a5,a4
 106:	4709                	li	a4,2
 108:	c398                	sw	a4,0(a5)
  thread_schedule();
 10a:	00000097          	auipc	ra,0x0
 10e:	f1c080e7          	jalr	-228(ra) # 26 <thread_schedule>
}
 112:	60a2                	ld	ra,8(sp)
 114:	6402                	ld	s0,0(sp)
 116:	0141                	add	sp,sp,16
 118:	8082                	ret

000000000000011a <thread_a>:
volatile int a_started, b_started, c_started;
volatile int a_n, b_n, c_n;

void 
thread_a(void)
{
 11a:	7179                	add	sp,sp,-48
 11c:	f406                	sd	ra,40(sp)
 11e:	f022                	sd	s0,32(sp)
 120:	ec26                	sd	s1,24(sp)
 122:	e84a                	sd	s2,16(sp)
 124:	e44e                	sd	s3,8(sp)
 126:	e052                	sd	s4,0(sp)
 128:	1800                	add	s0,sp,48
  int i;
  printf("thread_a started\n");
 12a:	00001517          	auipc	a0,0x1
 12e:	ade50513          	add	a0,a0,-1314 # c08 <malloc+0x112>
 132:	00001097          	auipc	ra,0x1
 136:	90c080e7          	jalr	-1780(ra) # a3e <printf>
  a_started = 1;
 13a:	4785                	li	a5,1
 13c:	00001717          	auipc	a4,0x1
 140:	c2f72823          	sw	a5,-976(a4) # d6c <a_started>
  while(b_started == 0 || c_started == 0)
 144:	00001497          	auipc	s1,0x1
 148:	c2448493          	add	s1,s1,-988 # d68 <b_started>
 14c:	00001917          	auipc	s2,0x1
 150:	c1890913          	add	s2,s2,-1000 # d64 <c_started>
 154:	a029                	j	15e <thread_a+0x44>
    thread_yield();
 156:	00000097          	auipc	ra,0x0
 15a:	f9c080e7          	jalr	-100(ra) # f2 <thread_yield>
  while(b_started == 0 || c_started == 0)
 15e:	409c                	lw	a5,0(s1)
 160:	2781                	sext.w	a5,a5
 162:	dbf5                	beqz	a5,156 <thread_a+0x3c>
 164:	00092783          	lw	a5,0(s2)
 168:	2781                	sext.w	a5,a5
 16a:	d7f5                	beqz	a5,156 <thread_a+0x3c>
  
  for (i = 0; i < 100; i++) {
 16c:	4481                	li	s1,0
    printf("thread_a %d\n", i);
 16e:	00001a17          	auipc	s4,0x1
 172:	ab2a0a13          	add	s4,s4,-1358 # c20 <malloc+0x12a>
    a_n += 1;
 176:	00001917          	auipc	s2,0x1
 17a:	bea90913          	add	s2,s2,-1046 # d60 <a_n>
  for (i = 0; i < 100; i++) {
 17e:	06400993          	li	s3,100
    printf("thread_a %d\n", i);
 182:	85a6                	mv	a1,s1
 184:	8552                	mv	a0,s4
 186:	00001097          	auipc	ra,0x1
 18a:	8b8080e7          	jalr	-1864(ra) # a3e <printf>
    a_n += 1;
 18e:	00092783          	lw	a5,0(s2)
 192:	2785                	addw	a5,a5,1
 194:	00f92023          	sw	a5,0(s2)
    thread_yield();
 198:	00000097          	auipc	ra,0x0
 19c:	f5a080e7          	jalr	-166(ra) # f2 <thread_yield>
  for (i = 0; i < 100; i++) {
 1a0:	2485                	addw	s1,s1,1
 1a2:	ff3490e3          	bne	s1,s3,182 <thread_a+0x68>
  }
  printf("thread_a: exit after %d\n", a_n);
 1a6:	00001597          	auipc	a1,0x1
 1aa:	bba5a583          	lw	a1,-1094(a1) # d60 <a_n>
 1ae:	00001517          	auipc	a0,0x1
 1b2:	a8250513          	add	a0,a0,-1406 # c30 <malloc+0x13a>
 1b6:	00001097          	auipc	ra,0x1
 1ba:	888080e7          	jalr	-1912(ra) # a3e <printf>

  current_thread->state = FREE;
 1be:	00001797          	auipc	a5,0x1
 1c2:	bb27b783          	ld	a5,-1102(a5) # d70 <current_thread>
 1c6:	6709                	lui	a4,0x2
 1c8:	97ba                	add	a5,a5,a4
 1ca:	0007a023          	sw	zero,0(a5)
  thread_schedule();
 1ce:	00000097          	auipc	ra,0x0
 1d2:	e58080e7          	jalr	-424(ra) # 26 <thread_schedule>
}
 1d6:	70a2                	ld	ra,40(sp)
 1d8:	7402                	ld	s0,32(sp)
 1da:	64e2                	ld	s1,24(sp)
 1dc:	6942                	ld	s2,16(sp)
 1de:	69a2                	ld	s3,8(sp)
 1e0:	6a02                	ld	s4,0(sp)
 1e2:	6145                	add	sp,sp,48
 1e4:	8082                	ret

00000000000001e6 <thread_b>:

void 
thread_b(void)
{
 1e6:	7179                	add	sp,sp,-48
 1e8:	f406                	sd	ra,40(sp)
 1ea:	f022                	sd	s0,32(sp)
 1ec:	ec26                	sd	s1,24(sp)
 1ee:	e84a                	sd	s2,16(sp)
 1f0:	e44e                	sd	s3,8(sp)
 1f2:	e052                	sd	s4,0(sp)
 1f4:	1800                	add	s0,sp,48
  int i;
  printf("thread_b started\n");
 1f6:	00001517          	auipc	a0,0x1
 1fa:	a5a50513          	add	a0,a0,-1446 # c50 <malloc+0x15a>
 1fe:	00001097          	auipc	ra,0x1
 202:	840080e7          	jalr	-1984(ra) # a3e <printf>
  b_started = 1;
 206:	4785                	li	a5,1
 208:	00001717          	auipc	a4,0x1
 20c:	b6f72023          	sw	a5,-1184(a4) # d68 <b_started>
  while(a_started == 0 || c_started == 0)
 210:	00001497          	auipc	s1,0x1
 214:	b5c48493          	add	s1,s1,-1188 # d6c <a_started>
 218:	00001917          	auipc	s2,0x1
 21c:	b4c90913          	add	s2,s2,-1204 # d64 <c_started>
 220:	a029                	j	22a <thread_b+0x44>
    thread_yield();
 222:	00000097          	auipc	ra,0x0
 226:	ed0080e7          	jalr	-304(ra) # f2 <thread_yield>
  while(a_started == 0 || c_started == 0)
 22a:	409c                	lw	a5,0(s1)
 22c:	2781                	sext.w	a5,a5
 22e:	dbf5                	beqz	a5,222 <thread_b+0x3c>
 230:	00092783          	lw	a5,0(s2)
 234:	2781                	sext.w	a5,a5
 236:	d7f5                	beqz	a5,222 <thread_b+0x3c>
  
  for (i = 0; i < 100; i++) {
 238:	4481                	li	s1,0
    printf("thread_b %d\n", i);
 23a:	00001a17          	auipc	s4,0x1
 23e:	a2ea0a13          	add	s4,s4,-1490 # c68 <malloc+0x172>
    b_n += 1;
 242:	00001917          	auipc	s2,0x1
 246:	b1a90913          	add	s2,s2,-1254 # d5c <b_n>
  for (i = 0; i < 100; i++) {
 24a:	06400993          	li	s3,100
    printf("thread_b %d\n", i);
 24e:	85a6                	mv	a1,s1
 250:	8552                	mv	a0,s4
 252:	00000097          	auipc	ra,0x0
 256:	7ec080e7          	jalr	2028(ra) # a3e <printf>
    b_n += 1;
 25a:	00092783          	lw	a5,0(s2)
 25e:	2785                	addw	a5,a5,1
 260:	00f92023          	sw	a5,0(s2)
    thread_yield();
 264:	00000097          	auipc	ra,0x0
 268:	e8e080e7          	jalr	-370(ra) # f2 <thread_yield>
  for (i = 0; i < 100; i++) {
 26c:	2485                	addw	s1,s1,1
 26e:	ff3490e3          	bne	s1,s3,24e <thread_b+0x68>
  }
  printf("thread_b: exit after %d\n", b_n);
 272:	00001597          	auipc	a1,0x1
 276:	aea5a583          	lw	a1,-1302(a1) # d5c <b_n>
 27a:	00001517          	auipc	a0,0x1
 27e:	9fe50513          	add	a0,a0,-1538 # c78 <malloc+0x182>
 282:	00000097          	auipc	ra,0x0
 286:	7bc080e7          	jalr	1980(ra) # a3e <printf>

  current_thread->state = FREE;
 28a:	00001797          	auipc	a5,0x1
 28e:	ae67b783          	ld	a5,-1306(a5) # d70 <current_thread>
 292:	6709                	lui	a4,0x2
 294:	97ba                	add	a5,a5,a4
 296:	0007a023          	sw	zero,0(a5)
  thread_schedule();
 29a:	00000097          	auipc	ra,0x0
 29e:	d8c080e7          	jalr	-628(ra) # 26 <thread_schedule>
}
 2a2:	70a2                	ld	ra,40(sp)
 2a4:	7402                	ld	s0,32(sp)
 2a6:	64e2                	ld	s1,24(sp)
 2a8:	6942                	ld	s2,16(sp)
 2aa:	69a2                	ld	s3,8(sp)
 2ac:	6a02                	ld	s4,0(sp)
 2ae:	6145                	add	sp,sp,48
 2b0:	8082                	ret

00000000000002b2 <thread_c>:

void 
thread_c(void)
{
 2b2:	7179                	add	sp,sp,-48
 2b4:	f406                	sd	ra,40(sp)
 2b6:	f022                	sd	s0,32(sp)
 2b8:	ec26                	sd	s1,24(sp)
 2ba:	e84a                	sd	s2,16(sp)
 2bc:	e44e                	sd	s3,8(sp)
 2be:	e052                	sd	s4,0(sp)
 2c0:	1800                	add	s0,sp,48
  int i;
  printf("thread_c started\n");
 2c2:	00001517          	auipc	a0,0x1
 2c6:	9d650513          	add	a0,a0,-1578 # c98 <malloc+0x1a2>
 2ca:	00000097          	auipc	ra,0x0
 2ce:	774080e7          	jalr	1908(ra) # a3e <printf>
  c_started = 1;
 2d2:	4785                	li	a5,1
 2d4:	00001717          	auipc	a4,0x1
 2d8:	a8f72823          	sw	a5,-1392(a4) # d64 <c_started>
  while(a_started == 0 || b_started == 0)
 2dc:	00001497          	auipc	s1,0x1
 2e0:	a9048493          	add	s1,s1,-1392 # d6c <a_started>
 2e4:	00001917          	auipc	s2,0x1
 2e8:	a8490913          	add	s2,s2,-1404 # d68 <b_started>
 2ec:	a029                	j	2f6 <thread_c+0x44>
    thread_yield();
 2ee:	00000097          	auipc	ra,0x0
 2f2:	e04080e7          	jalr	-508(ra) # f2 <thread_yield>
  while(a_started == 0 || b_started == 0)
 2f6:	409c                	lw	a5,0(s1)
 2f8:	2781                	sext.w	a5,a5
 2fa:	dbf5                	beqz	a5,2ee <thread_c+0x3c>
 2fc:	00092783          	lw	a5,0(s2)
 300:	2781                	sext.w	a5,a5
 302:	d7f5                	beqz	a5,2ee <thread_c+0x3c>
  
  for (i = 0; i < 100; i++) {
 304:	4481                	li	s1,0
    printf("thread_c %d\n", i);
 306:	00001a17          	auipc	s4,0x1
 30a:	9aaa0a13          	add	s4,s4,-1622 # cb0 <malloc+0x1ba>
    c_n += 1;
 30e:	00001917          	auipc	s2,0x1
 312:	a4a90913          	add	s2,s2,-1462 # d58 <c_n>
  for (i = 0; i < 100; i++) {
 316:	06400993          	li	s3,100
    printf("thread_c %d\n", i);
 31a:	85a6                	mv	a1,s1
 31c:	8552                	mv	a0,s4
 31e:	00000097          	auipc	ra,0x0
 322:	720080e7          	jalr	1824(ra) # a3e <printf>
    c_n += 1;
 326:	00092783          	lw	a5,0(s2)
 32a:	2785                	addw	a5,a5,1
 32c:	00f92023          	sw	a5,0(s2)
    thread_yield();
 330:	00000097          	auipc	ra,0x0
 334:	dc2080e7          	jalr	-574(ra) # f2 <thread_yield>
  for (i = 0; i < 100; i++) {
 338:	2485                	addw	s1,s1,1
 33a:	ff3490e3          	bne	s1,s3,31a <thread_c+0x68>
  }
  printf("thread_c: exit after %d\n", c_n);
 33e:	00001597          	auipc	a1,0x1
 342:	a1a5a583          	lw	a1,-1510(a1) # d58 <c_n>
 346:	00001517          	auipc	a0,0x1
 34a:	97a50513          	add	a0,a0,-1670 # cc0 <malloc+0x1ca>
 34e:	00000097          	auipc	ra,0x0
 352:	6f0080e7          	jalr	1776(ra) # a3e <printf>

  current_thread->state = FREE;
 356:	00001797          	auipc	a5,0x1
 35a:	a1a7b783          	ld	a5,-1510(a5) # d70 <current_thread>
 35e:	6709                	lui	a4,0x2
 360:	97ba                	add	a5,a5,a4
 362:	0007a023          	sw	zero,0(a5)
  thread_schedule();
 366:	00000097          	auipc	ra,0x0
 36a:	cc0080e7          	jalr	-832(ra) # 26 <thread_schedule>
}
 36e:	70a2                	ld	ra,40(sp)
 370:	7402                	ld	s0,32(sp)
 372:	64e2                	ld	s1,24(sp)
 374:	6942                	ld	s2,16(sp)
 376:	69a2                	ld	s3,8(sp)
 378:	6a02                	ld	s4,0(sp)
 37a:	6145                	add	sp,sp,48
 37c:	8082                	ret

000000000000037e <main>:

int 
main(int argc, char *argv[]) 
{
 37e:	1141                	add	sp,sp,-16
 380:	e406                	sd	ra,8(sp)
 382:	e022                	sd	s0,0(sp)
 384:	0800                	add	s0,sp,16
  a_started = b_started = c_started = 0;
 386:	00001797          	auipc	a5,0x1
 38a:	9c07af23          	sw	zero,-1570(a5) # d64 <c_started>
 38e:	00001797          	auipc	a5,0x1
 392:	9c07ad23          	sw	zero,-1574(a5) # d68 <b_started>
 396:	00001797          	auipc	a5,0x1
 39a:	9c07ab23          	sw	zero,-1578(a5) # d6c <a_started>
  a_n = b_n = c_n = 0;
 39e:	00001797          	auipc	a5,0x1
 3a2:	9a07ad23          	sw	zero,-1606(a5) # d58 <c_n>
 3a6:	00001797          	auipc	a5,0x1
 3aa:	9a07ab23          	sw	zero,-1610(a5) # d5c <b_n>
 3ae:	00001797          	auipc	a5,0x1
 3b2:	9a07a923          	sw	zero,-1614(a5) # d60 <a_n>
  thread_init();
 3b6:	00000097          	auipc	ra,0x0
 3ba:	c4a080e7          	jalr	-950(ra) # 0 <thread_init>
  thread_create(thread_a);
 3be:	00000517          	auipc	a0,0x0
 3c2:	d5c50513          	add	a0,a0,-676 # 11a <thread_a>
 3c6:	00000097          	auipc	ra,0x0
 3ca:	cf0080e7          	jalr	-784(ra) # b6 <thread_create>
  thread_create(thread_b);
 3ce:	00000517          	auipc	a0,0x0
 3d2:	e1850513          	add	a0,a0,-488 # 1e6 <thread_b>
 3d6:	00000097          	auipc	ra,0x0
 3da:	ce0080e7          	jalr	-800(ra) # b6 <thread_create>
  thread_create(thread_c);
 3de:	00000517          	auipc	a0,0x0
 3e2:	ed450513          	add	a0,a0,-300 # 2b2 <thread_c>
 3e6:	00000097          	auipc	ra,0x0
 3ea:	cd0080e7          	jalr	-816(ra) # b6 <thread_create>
  thread_schedule();
 3ee:	00000097          	auipc	ra,0x0
 3f2:	c38080e7          	jalr	-968(ra) # 26 <thread_schedule>
  exit(0);
 3f6:	4501                	li	a0,0
 3f8:	00000097          	auipc	ra,0x0
 3fc:	2de080e7          	jalr	734(ra) # 6d6 <exit>

0000000000000400 <thread_switch>:

	.globl thread_switch
thread_switch:
	/* YOUR CODE HERE */

        sd ra, 0(a0)
 400:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)
 404:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)
 408:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)
 40a:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)
 40c:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)
 410:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)
 414:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)
 418:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)
 41c:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)
 420:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)
 424:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)
 428:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
 42c:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
 430:	07b53423          	sd	s11,104(a0)

        ld ra, 0(a1)
 434:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)
 438:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)
 43c:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)
 43e:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)
 440:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)
 444:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)
 448:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)
 44c:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)
 450:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)
 454:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)
 458:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)
 45c:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
 460:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
 464:	0685bd83          	ld	s11,104(a1)

	ret    /* return to ra */
 468:	8082                	ret

000000000000046a <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 46a:	1141                	add	sp,sp,-16
 46c:	e422                	sd	s0,8(sp)
 46e:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 470:	87aa                	mv	a5,a0
 472:	0585                	add	a1,a1,1
 474:	0785                	add	a5,a5,1
 476:	fff5c703          	lbu	a4,-1(a1)
 47a:	fee78fa3          	sb	a4,-1(a5)
 47e:	fb75                	bnez	a4,472 <strcpy+0x8>
    ;
  return os;
}
 480:	6422                	ld	s0,8(sp)
 482:	0141                	add	sp,sp,16
 484:	8082                	ret

0000000000000486 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 486:	1141                	add	sp,sp,-16
 488:	e422                	sd	s0,8(sp)
 48a:	0800                	add	s0,sp,16
  while(*p && *p == *q)
 48c:	00054783          	lbu	a5,0(a0)
 490:	cb91                	beqz	a5,4a4 <strcmp+0x1e>
 492:	0005c703          	lbu	a4,0(a1)
 496:	00f71763          	bne	a4,a5,4a4 <strcmp+0x1e>
    p++, q++;
 49a:	0505                	add	a0,a0,1
 49c:	0585                	add	a1,a1,1
  while(*p && *p == *q)
 49e:	00054783          	lbu	a5,0(a0)
 4a2:	fbe5                	bnez	a5,492 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 4a4:	0005c503          	lbu	a0,0(a1)
}
 4a8:	40a7853b          	subw	a0,a5,a0
 4ac:	6422                	ld	s0,8(sp)
 4ae:	0141                	add	sp,sp,16
 4b0:	8082                	ret

00000000000004b2 <strlen>:

uint
strlen(const char *s)
{
 4b2:	1141                	add	sp,sp,-16
 4b4:	e422                	sd	s0,8(sp)
 4b6:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 4b8:	00054783          	lbu	a5,0(a0)
 4bc:	cf91                	beqz	a5,4d8 <strlen+0x26>
 4be:	0505                	add	a0,a0,1
 4c0:	87aa                	mv	a5,a0
 4c2:	86be                	mv	a3,a5
 4c4:	0785                	add	a5,a5,1
 4c6:	fff7c703          	lbu	a4,-1(a5)
 4ca:	ff65                	bnez	a4,4c2 <strlen+0x10>
 4cc:	40a6853b          	subw	a0,a3,a0
 4d0:	2505                	addw	a0,a0,1
    ;
  return n;
}
 4d2:	6422                	ld	s0,8(sp)
 4d4:	0141                	add	sp,sp,16
 4d6:	8082                	ret
  for(n = 0; s[n]; n++)
 4d8:	4501                	li	a0,0
 4da:	bfe5                	j	4d2 <strlen+0x20>

00000000000004dc <memset>:

void*
memset(void *dst, int c, uint n)
{
 4dc:	1141                	add	sp,sp,-16
 4de:	e422                	sd	s0,8(sp)
 4e0:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 4e2:	ca19                	beqz	a2,4f8 <memset+0x1c>
 4e4:	87aa                	mv	a5,a0
 4e6:	1602                	sll	a2,a2,0x20
 4e8:	9201                	srl	a2,a2,0x20
 4ea:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 4ee:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 4f2:	0785                	add	a5,a5,1
 4f4:	fee79de3          	bne	a5,a4,4ee <memset+0x12>
  }
  return dst;
}
 4f8:	6422                	ld	s0,8(sp)
 4fa:	0141                	add	sp,sp,16
 4fc:	8082                	ret

00000000000004fe <strchr>:

char*
strchr(const char *s, char c)
{
 4fe:	1141                	add	sp,sp,-16
 500:	e422                	sd	s0,8(sp)
 502:	0800                	add	s0,sp,16
  for(; *s; s++)
 504:	00054783          	lbu	a5,0(a0)
 508:	cb99                	beqz	a5,51e <strchr+0x20>
    if(*s == c)
 50a:	00f58763          	beq	a1,a5,518 <strchr+0x1a>
  for(; *s; s++)
 50e:	0505                	add	a0,a0,1
 510:	00054783          	lbu	a5,0(a0)
 514:	fbfd                	bnez	a5,50a <strchr+0xc>
      return (char*)s;
  return 0;
 516:	4501                	li	a0,0
}
 518:	6422                	ld	s0,8(sp)
 51a:	0141                	add	sp,sp,16
 51c:	8082                	ret
  return 0;
 51e:	4501                	li	a0,0
 520:	bfe5                	j	518 <strchr+0x1a>

0000000000000522 <gets>:

char*
gets(char *buf, int max)
{
 522:	711d                	add	sp,sp,-96
 524:	ec86                	sd	ra,88(sp)
 526:	e8a2                	sd	s0,80(sp)
 528:	e4a6                	sd	s1,72(sp)
 52a:	e0ca                	sd	s2,64(sp)
 52c:	fc4e                	sd	s3,56(sp)
 52e:	f852                	sd	s4,48(sp)
 530:	f456                	sd	s5,40(sp)
 532:	f05a                	sd	s6,32(sp)
 534:	ec5e                	sd	s7,24(sp)
 536:	1080                	add	s0,sp,96
 538:	8baa                	mv	s7,a0
 53a:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 53c:	892a                	mv	s2,a0
 53e:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 540:	4aa9                	li	s5,10
 542:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 544:	89a6                	mv	s3,s1
 546:	2485                	addw	s1,s1,1
 548:	0344d863          	bge	s1,s4,578 <gets+0x56>
    cc = read(0, &c, 1);
 54c:	4605                	li	a2,1
 54e:	faf40593          	add	a1,s0,-81
 552:	4501                	li	a0,0
 554:	00000097          	auipc	ra,0x0
 558:	19a080e7          	jalr	410(ra) # 6ee <read>
    if(cc < 1)
 55c:	00a05e63          	blez	a0,578 <gets+0x56>
    buf[i++] = c;
 560:	faf44783          	lbu	a5,-81(s0)
 564:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 568:	01578763          	beq	a5,s5,576 <gets+0x54>
 56c:	0905                	add	s2,s2,1
 56e:	fd679be3          	bne	a5,s6,544 <gets+0x22>
  for(i=0; i+1 < max; ){
 572:	89a6                	mv	s3,s1
 574:	a011                	j	578 <gets+0x56>
 576:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 578:	99de                	add	s3,s3,s7
 57a:	00098023          	sb	zero,0(s3)
  return buf;
}
 57e:	855e                	mv	a0,s7
 580:	60e6                	ld	ra,88(sp)
 582:	6446                	ld	s0,80(sp)
 584:	64a6                	ld	s1,72(sp)
 586:	6906                	ld	s2,64(sp)
 588:	79e2                	ld	s3,56(sp)
 58a:	7a42                	ld	s4,48(sp)
 58c:	7aa2                	ld	s5,40(sp)
 58e:	7b02                	ld	s6,32(sp)
 590:	6be2                	ld	s7,24(sp)
 592:	6125                	add	sp,sp,96
 594:	8082                	ret

0000000000000596 <stat>:

int
stat(const char *n, struct stat *st)
{
 596:	1101                	add	sp,sp,-32
 598:	ec06                	sd	ra,24(sp)
 59a:	e822                	sd	s0,16(sp)
 59c:	e426                	sd	s1,8(sp)
 59e:	e04a                	sd	s2,0(sp)
 5a0:	1000                	add	s0,sp,32
 5a2:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 5a4:	4581                	li	a1,0
 5a6:	00000097          	auipc	ra,0x0
 5aa:	170080e7          	jalr	368(ra) # 716 <open>
  if(fd < 0)
 5ae:	02054563          	bltz	a0,5d8 <stat+0x42>
 5b2:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 5b4:	85ca                	mv	a1,s2
 5b6:	00000097          	auipc	ra,0x0
 5ba:	178080e7          	jalr	376(ra) # 72e <fstat>
 5be:	892a                	mv	s2,a0
  close(fd);
 5c0:	8526                	mv	a0,s1
 5c2:	00000097          	auipc	ra,0x0
 5c6:	13c080e7          	jalr	316(ra) # 6fe <close>
  return r;
}
 5ca:	854a                	mv	a0,s2
 5cc:	60e2                	ld	ra,24(sp)
 5ce:	6442                	ld	s0,16(sp)
 5d0:	64a2                	ld	s1,8(sp)
 5d2:	6902                	ld	s2,0(sp)
 5d4:	6105                	add	sp,sp,32
 5d6:	8082                	ret
    return -1;
 5d8:	597d                	li	s2,-1
 5da:	bfc5                	j	5ca <stat+0x34>

00000000000005dc <atoi>:

int
atoi(const char *s)
{
 5dc:	1141                	add	sp,sp,-16
 5de:	e422                	sd	s0,8(sp)
 5e0:	0800                	add	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 5e2:	00054683          	lbu	a3,0(a0)
 5e6:	fd06879b          	addw	a5,a3,-48
 5ea:	0ff7f793          	zext.b	a5,a5
 5ee:	4625                	li	a2,9
 5f0:	02f66863          	bltu	a2,a5,620 <atoi+0x44>
 5f4:	872a                	mv	a4,a0
  n = 0;
 5f6:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 5f8:	0705                	add	a4,a4,1 # 2001 <__global_pointer$+0xab0>
 5fa:	0025179b          	sllw	a5,a0,0x2
 5fe:	9fa9                	addw	a5,a5,a0
 600:	0017979b          	sllw	a5,a5,0x1
 604:	9fb5                	addw	a5,a5,a3
 606:	fd07851b          	addw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 60a:	00074683          	lbu	a3,0(a4)
 60e:	fd06879b          	addw	a5,a3,-48
 612:	0ff7f793          	zext.b	a5,a5
 616:	fef671e3          	bgeu	a2,a5,5f8 <atoi+0x1c>
  return n;
}
 61a:	6422                	ld	s0,8(sp)
 61c:	0141                	add	sp,sp,16
 61e:	8082                	ret
  n = 0;
 620:	4501                	li	a0,0
 622:	bfe5                	j	61a <atoi+0x3e>

0000000000000624 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 624:	1141                	add	sp,sp,-16
 626:	e422                	sd	s0,8(sp)
 628:	0800                	add	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 62a:	02b57463          	bgeu	a0,a1,652 <memmove+0x2e>
    while(n-- > 0)
 62e:	00c05f63          	blez	a2,64c <memmove+0x28>
 632:	1602                	sll	a2,a2,0x20
 634:	9201                	srl	a2,a2,0x20
 636:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 63a:	872a                	mv	a4,a0
      *dst++ = *src++;
 63c:	0585                	add	a1,a1,1
 63e:	0705                	add	a4,a4,1
 640:	fff5c683          	lbu	a3,-1(a1)
 644:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 648:	fee79ae3          	bne	a5,a4,63c <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 64c:	6422                	ld	s0,8(sp)
 64e:	0141                	add	sp,sp,16
 650:	8082                	ret
    dst += n;
 652:	00c50733          	add	a4,a0,a2
    src += n;
 656:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 658:	fec05ae3          	blez	a2,64c <memmove+0x28>
 65c:	fff6079b          	addw	a5,a2,-1
 660:	1782                	sll	a5,a5,0x20
 662:	9381                	srl	a5,a5,0x20
 664:	fff7c793          	not	a5,a5
 668:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 66a:	15fd                	add	a1,a1,-1
 66c:	177d                	add	a4,a4,-1
 66e:	0005c683          	lbu	a3,0(a1)
 672:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 676:	fee79ae3          	bne	a5,a4,66a <memmove+0x46>
 67a:	bfc9                	j	64c <memmove+0x28>

000000000000067c <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 67c:	1141                	add	sp,sp,-16
 67e:	e422                	sd	s0,8(sp)
 680:	0800                	add	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 682:	ca05                	beqz	a2,6b2 <memcmp+0x36>
 684:	fff6069b          	addw	a3,a2,-1
 688:	1682                	sll	a3,a3,0x20
 68a:	9281                	srl	a3,a3,0x20
 68c:	0685                	add	a3,a3,1
 68e:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 690:	00054783          	lbu	a5,0(a0)
 694:	0005c703          	lbu	a4,0(a1)
 698:	00e79863          	bne	a5,a4,6a8 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 69c:	0505                	add	a0,a0,1
    p2++;
 69e:	0585                	add	a1,a1,1
  while (n-- > 0) {
 6a0:	fed518e3          	bne	a0,a3,690 <memcmp+0x14>
  }
  return 0;
 6a4:	4501                	li	a0,0
 6a6:	a019                	j	6ac <memcmp+0x30>
      return *p1 - *p2;
 6a8:	40e7853b          	subw	a0,a5,a4
}
 6ac:	6422                	ld	s0,8(sp)
 6ae:	0141                	add	sp,sp,16
 6b0:	8082                	ret
  return 0;
 6b2:	4501                	li	a0,0
 6b4:	bfe5                	j	6ac <memcmp+0x30>

00000000000006b6 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 6b6:	1141                	add	sp,sp,-16
 6b8:	e406                	sd	ra,8(sp)
 6ba:	e022                	sd	s0,0(sp)
 6bc:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
 6be:	00000097          	auipc	ra,0x0
 6c2:	f66080e7          	jalr	-154(ra) # 624 <memmove>
}
 6c6:	60a2                	ld	ra,8(sp)
 6c8:	6402                	ld	s0,0(sp)
 6ca:	0141                	add	sp,sp,16
 6cc:	8082                	ret

00000000000006ce <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 6ce:	4885                	li	a7,1
 ecall
 6d0:	00000073          	ecall
 ret
 6d4:	8082                	ret

00000000000006d6 <exit>:
.global exit
exit:
 li a7, SYS_exit
 6d6:	4889                	li	a7,2
 ecall
 6d8:	00000073          	ecall
 ret
 6dc:	8082                	ret

00000000000006de <wait>:
.global wait
wait:
 li a7, SYS_wait
 6de:	488d                	li	a7,3
 ecall
 6e0:	00000073          	ecall
 ret
 6e4:	8082                	ret

00000000000006e6 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 6e6:	4891                	li	a7,4
 ecall
 6e8:	00000073          	ecall
 ret
 6ec:	8082                	ret

00000000000006ee <read>:
.global read
read:
 li a7, SYS_read
 6ee:	4895                	li	a7,5
 ecall
 6f0:	00000073          	ecall
 ret
 6f4:	8082                	ret

00000000000006f6 <write>:
.global write
write:
 li a7, SYS_write
 6f6:	48c1                	li	a7,16
 ecall
 6f8:	00000073          	ecall
 ret
 6fc:	8082                	ret

00000000000006fe <close>:
.global close
close:
 li a7, SYS_close
 6fe:	48d5                	li	a7,21
 ecall
 700:	00000073          	ecall
 ret
 704:	8082                	ret

0000000000000706 <kill>:
.global kill
kill:
 li a7, SYS_kill
 706:	4899                	li	a7,6
 ecall
 708:	00000073          	ecall
 ret
 70c:	8082                	ret

000000000000070e <exec>:
.global exec
exec:
 li a7, SYS_exec
 70e:	489d                	li	a7,7
 ecall
 710:	00000073          	ecall
 ret
 714:	8082                	ret

0000000000000716 <open>:
.global open
open:
 li a7, SYS_open
 716:	48bd                	li	a7,15
 ecall
 718:	00000073          	ecall
 ret
 71c:	8082                	ret

000000000000071e <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 71e:	48c5                	li	a7,17
 ecall
 720:	00000073          	ecall
 ret
 724:	8082                	ret

0000000000000726 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 726:	48c9                	li	a7,18
 ecall
 728:	00000073          	ecall
 ret
 72c:	8082                	ret

000000000000072e <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 72e:	48a1                	li	a7,8
 ecall
 730:	00000073          	ecall
 ret
 734:	8082                	ret

0000000000000736 <link>:
.global link
link:
 li a7, SYS_link
 736:	48cd                	li	a7,19
 ecall
 738:	00000073          	ecall
 ret
 73c:	8082                	ret

000000000000073e <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 73e:	48d1                	li	a7,20
 ecall
 740:	00000073          	ecall
 ret
 744:	8082                	ret

0000000000000746 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 746:	48a5                	li	a7,9
 ecall
 748:	00000073          	ecall
 ret
 74c:	8082                	ret

000000000000074e <dup>:
.global dup
dup:
 li a7, SYS_dup
 74e:	48a9                	li	a7,10
 ecall
 750:	00000073          	ecall
 ret
 754:	8082                	ret

0000000000000756 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 756:	48ad                	li	a7,11
 ecall
 758:	00000073          	ecall
 ret
 75c:	8082                	ret

000000000000075e <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 75e:	48b1                	li	a7,12
 ecall
 760:	00000073          	ecall
 ret
 764:	8082                	ret

0000000000000766 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 766:	48b5                	li	a7,13
 ecall
 768:	00000073          	ecall
 ret
 76c:	8082                	ret

000000000000076e <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 76e:	48b9                	li	a7,14
 ecall
 770:	00000073          	ecall
 ret
 774:	8082                	ret

0000000000000776 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 776:	1101                	add	sp,sp,-32
 778:	ec06                	sd	ra,24(sp)
 77a:	e822                	sd	s0,16(sp)
 77c:	1000                	add	s0,sp,32
 77e:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 782:	4605                	li	a2,1
 784:	fef40593          	add	a1,s0,-17
 788:	00000097          	auipc	ra,0x0
 78c:	f6e080e7          	jalr	-146(ra) # 6f6 <write>
}
 790:	60e2                	ld	ra,24(sp)
 792:	6442                	ld	s0,16(sp)
 794:	6105                	add	sp,sp,32
 796:	8082                	ret

0000000000000798 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 798:	7139                	add	sp,sp,-64
 79a:	fc06                	sd	ra,56(sp)
 79c:	f822                	sd	s0,48(sp)
 79e:	f426                	sd	s1,40(sp)
 7a0:	f04a                	sd	s2,32(sp)
 7a2:	ec4e                	sd	s3,24(sp)
 7a4:	0080                	add	s0,sp,64
 7a6:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 7a8:	c299                	beqz	a3,7ae <printint+0x16>
 7aa:	0805c963          	bltz	a1,83c <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 7ae:	2581                	sext.w	a1,a1
  neg = 0;
 7b0:	4881                	li	a7,0
 7b2:	fc040693          	add	a3,s0,-64
  }

  i = 0;
 7b6:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 7b8:	2601                	sext.w	a2,a2
 7ba:	00000517          	auipc	a0,0x0
 7be:	58650513          	add	a0,a0,1414 # d40 <digits>
 7c2:	883a                	mv	a6,a4
 7c4:	2705                	addw	a4,a4,1
 7c6:	02c5f7bb          	remuw	a5,a1,a2
 7ca:	1782                	sll	a5,a5,0x20
 7cc:	9381                	srl	a5,a5,0x20
 7ce:	97aa                	add	a5,a5,a0
 7d0:	0007c783          	lbu	a5,0(a5)
 7d4:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 7d8:	0005879b          	sext.w	a5,a1
 7dc:	02c5d5bb          	divuw	a1,a1,a2
 7e0:	0685                	add	a3,a3,1
 7e2:	fec7f0e3          	bgeu	a5,a2,7c2 <printint+0x2a>
  if(neg)
 7e6:	00088c63          	beqz	a7,7fe <printint+0x66>
    buf[i++] = '-';
 7ea:	fd070793          	add	a5,a4,-48
 7ee:	00878733          	add	a4,a5,s0
 7f2:	02d00793          	li	a5,45
 7f6:	fef70823          	sb	a5,-16(a4)
 7fa:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
 7fe:	02e05863          	blez	a4,82e <printint+0x96>
 802:	fc040793          	add	a5,s0,-64
 806:	00e78933          	add	s2,a5,a4
 80a:	fff78993          	add	s3,a5,-1
 80e:	99ba                	add	s3,s3,a4
 810:	377d                	addw	a4,a4,-1
 812:	1702                	sll	a4,a4,0x20
 814:	9301                	srl	a4,a4,0x20
 816:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 81a:	fff94583          	lbu	a1,-1(s2)
 81e:	8526                	mv	a0,s1
 820:	00000097          	auipc	ra,0x0
 824:	f56080e7          	jalr	-170(ra) # 776 <putc>
  while(--i >= 0)
 828:	197d                	add	s2,s2,-1
 82a:	ff3918e3          	bne	s2,s3,81a <printint+0x82>
}
 82e:	70e2                	ld	ra,56(sp)
 830:	7442                	ld	s0,48(sp)
 832:	74a2                	ld	s1,40(sp)
 834:	7902                	ld	s2,32(sp)
 836:	69e2                	ld	s3,24(sp)
 838:	6121                	add	sp,sp,64
 83a:	8082                	ret
    x = -xx;
 83c:	40b005bb          	negw	a1,a1
    neg = 1;
 840:	4885                	li	a7,1
    x = -xx;
 842:	bf85                	j	7b2 <printint+0x1a>

0000000000000844 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 844:	715d                	add	sp,sp,-80
 846:	e486                	sd	ra,72(sp)
 848:	e0a2                	sd	s0,64(sp)
 84a:	fc26                	sd	s1,56(sp)
 84c:	f84a                	sd	s2,48(sp)
 84e:	f44e                	sd	s3,40(sp)
 850:	f052                	sd	s4,32(sp)
 852:	ec56                	sd	s5,24(sp)
 854:	e85a                	sd	s6,16(sp)
 856:	e45e                	sd	s7,8(sp)
 858:	e062                	sd	s8,0(sp)
 85a:	0880                	add	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 85c:	0005c903          	lbu	s2,0(a1)
 860:	18090c63          	beqz	s2,9f8 <vprintf+0x1b4>
 864:	8aaa                	mv	s5,a0
 866:	8bb2                	mv	s7,a2
 868:	00158493          	add	s1,a1,1
  state = 0;
 86c:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 86e:	02500a13          	li	s4,37
 872:	4b55                	li	s6,21
 874:	a839                	j	892 <vprintf+0x4e>
        putc(fd, c);
 876:	85ca                	mv	a1,s2
 878:	8556                	mv	a0,s5
 87a:	00000097          	auipc	ra,0x0
 87e:	efc080e7          	jalr	-260(ra) # 776 <putc>
 882:	a019                	j	888 <vprintf+0x44>
    } else if(state == '%'){
 884:	01498d63          	beq	s3,s4,89e <vprintf+0x5a>
  for(i = 0; fmt[i]; i++){
 888:	0485                	add	s1,s1,1
 88a:	fff4c903          	lbu	s2,-1(s1)
 88e:	16090563          	beqz	s2,9f8 <vprintf+0x1b4>
    if(state == 0){
 892:	fe0999e3          	bnez	s3,884 <vprintf+0x40>
      if(c == '%'){
 896:	ff4910e3          	bne	s2,s4,876 <vprintf+0x32>
        state = '%';
 89a:	89d2                	mv	s3,s4
 89c:	b7f5                	j	888 <vprintf+0x44>
      if(c == 'd'){
 89e:	13490263          	beq	s2,s4,9c2 <vprintf+0x17e>
 8a2:	f9d9079b          	addw	a5,s2,-99
 8a6:	0ff7f793          	zext.b	a5,a5
 8aa:	12fb6563          	bltu	s6,a5,9d4 <vprintf+0x190>
 8ae:	f9d9079b          	addw	a5,s2,-99
 8b2:	0ff7f713          	zext.b	a4,a5
 8b6:	10eb6f63          	bltu	s6,a4,9d4 <vprintf+0x190>
 8ba:	00271793          	sll	a5,a4,0x2
 8be:	00000717          	auipc	a4,0x0
 8c2:	42a70713          	add	a4,a4,1066 # ce8 <malloc+0x1f2>
 8c6:	97ba                	add	a5,a5,a4
 8c8:	439c                	lw	a5,0(a5)
 8ca:	97ba                	add	a5,a5,a4
 8cc:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 8ce:	008b8913          	add	s2,s7,8
 8d2:	4685                	li	a3,1
 8d4:	4629                	li	a2,10
 8d6:	000ba583          	lw	a1,0(s7)
 8da:	8556                	mv	a0,s5
 8dc:	00000097          	auipc	ra,0x0
 8e0:	ebc080e7          	jalr	-324(ra) # 798 <printint>
 8e4:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 8e6:	4981                	li	s3,0
 8e8:	b745                	j	888 <vprintf+0x44>
        printint(fd, va_arg(ap, uint64), 10, 0);
 8ea:	008b8913          	add	s2,s7,8
 8ee:	4681                	li	a3,0
 8f0:	4629                	li	a2,10
 8f2:	000ba583          	lw	a1,0(s7)
 8f6:	8556                	mv	a0,s5
 8f8:	00000097          	auipc	ra,0x0
 8fc:	ea0080e7          	jalr	-352(ra) # 798 <printint>
 900:	8bca                	mv	s7,s2
      state = 0;
 902:	4981                	li	s3,0
 904:	b751                	j	888 <vprintf+0x44>
        printint(fd, va_arg(ap, int), 16, 0);
 906:	008b8913          	add	s2,s7,8
 90a:	4681                	li	a3,0
 90c:	4641                	li	a2,16
 90e:	000ba583          	lw	a1,0(s7)
 912:	8556                	mv	a0,s5
 914:	00000097          	auipc	ra,0x0
 918:	e84080e7          	jalr	-380(ra) # 798 <printint>
 91c:	8bca                	mv	s7,s2
      state = 0;
 91e:	4981                	li	s3,0
 920:	b7a5                	j	888 <vprintf+0x44>
        printptr(fd, va_arg(ap, uint64));
 922:	008b8c13          	add	s8,s7,8
 926:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 92a:	03000593          	li	a1,48
 92e:	8556                	mv	a0,s5
 930:	00000097          	auipc	ra,0x0
 934:	e46080e7          	jalr	-442(ra) # 776 <putc>
  putc(fd, 'x');
 938:	07800593          	li	a1,120
 93c:	8556                	mv	a0,s5
 93e:	00000097          	auipc	ra,0x0
 942:	e38080e7          	jalr	-456(ra) # 776 <putc>
 946:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 948:	00000b97          	auipc	s7,0x0
 94c:	3f8b8b93          	add	s7,s7,1016 # d40 <digits>
 950:	03c9d793          	srl	a5,s3,0x3c
 954:	97de                	add	a5,a5,s7
 956:	0007c583          	lbu	a1,0(a5)
 95a:	8556                	mv	a0,s5
 95c:	00000097          	auipc	ra,0x0
 960:	e1a080e7          	jalr	-486(ra) # 776 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 964:	0992                	sll	s3,s3,0x4
 966:	397d                	addw	s2,s2,-1
 968:	fe0914e3          	bnez	s2,950 <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 96c:	8be2                	mv	s7,s8
      state = 0;
 96e:	4981                	li	s3,0
 970:	bf21                	j	888 <vprintf+0x44>
        s = va_arg(ap, char*);
 972:	008b8993          	add	s3,s7,8
 976:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 97a:	02090163          	beqz	s2,99c <vprintf+0x158>
        while(*s != 0){
 97e:	00094583          	lbu	a1,0(s2)
 982:	c9a5                	beqz	a1,9f2 <vprintf+0x1ae>
          putc(fd, *s);
 984:	8556                	mv	a0,s5
 986:	00000097          	auipc	ra,0x0
 98a:	df0080e7          	jalr	-528(ra) # 776 <putc>
          s++;
 98e:	0905                	add	s2,s2,1
        while(*s != 0){
 990:	00094583          	lbu	a1,0(s2)
 994:	f9e5                	bnez	a1,984 <vprintf+0x140>
        s = va_arg(ap, char*);
 996:	8bce                	mv	s7,s3
      state = 0;
 998:	4981                	li	s3,0
 99a:	b5fd                	j	888 <vprintf+0x44>
          s = "(null)";
 99c:	00000917          	auipc	s2,0x0
 9a0:	34490913          	add	s2,s2,836 # ce0 <malloc+0x1ea>
        while(*s != 0){
 9a4:	02800593          	li	a1,40
 9a8:	bff1                	j	984 <vprintf+0x140>
        putc(fd, va_arg(ap, uint));
 9aa:	008b8913          	add	s2,s7,8
 9ae:	000bc583          	lbu	a1,0(s7)
 9b2:	8556                	mv	a0,s5
 9b4:	00000097          	auipc	ra,0x0
 9b8:	dc2080e7          	jalr	-574(ra) # 776 <putc>
 9bc:	8bca                	mv	s7,s2
      state = 0;
 9be:	4981                	li	s3,0
 9c0:	b5e1                	j	888 <vprintf+0x44>
        putc(fd, c);
 9c2:	02500593          	li	a1,37
 9c6:	8556                	mv	a0,s5
 9c8:	00000097          	auipc	ra,0x0
 9cc:	dae080e7          	jalr	-594(ra) # 776 <putc>
      state = 0;
 9d0:	4981                	li	s3,0
 9d2:	bd5d                	j	888 <vprintf+0x44>
        putc(fd, '%');
 9d4:	02500593          	li	a1,37
 9d8:	8556                	mv	a0,s5
 9da:	00000097          	auipc	ra,0x0
 9de:	d9c080e7          	jalr	-612(ra) # 776 <putc>
        putc(fd, c);
 9e2:	85ca                	mv	a1,s2
 9e4:	8556                	mv	a0,s5
 9e6:	00000097          	auipc	ra,0x0
 9ea:	d90080e7          	jalr	-624(ra) # 776 <putc>
      state = 0;
 9ee:	4981                	li	s3,0
 9f0:	bd61                	j	888 <vprintf+0x44>
        s = va_arg(ap, char*);
 9f2:	8bce                	mv	s7,s3
      state = 0;
 9f4:	4981                	li	s3,0
 9f6:	bd49                	j	888 <vprintf+0x44>
    }
  }
}
 9f8:	60a6                	ld	ra,72(sp)
 9fa:	6406                	ld	s0,64(sp)
 9fc:	74e2                	ld	s1,56(sp)
 9fe:	7942                	ld	s2,48(sp)
 a00:	79a2                	ld	s3,40(sp)
 a02:	7a02                	ld	s4,32(sp)
 a04:	6ae2                	ld	s5,24(sp)
 a06:	6b42                	ld	s6,16(sp)
 a08:	6ba2                	ld	s7,8(sp)
 a0a:	6c02                	ld	s8,0(sp)
 a0c:	6161                	add	sp,sp,80
 a0e:	8082                	ret

0000000000000a10 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 a10:	715d                	add	sp,sp,-80
 a12:	ec06                	sd	ra,24(sp)
 a14:	e822                	sd	s0,16(sp)
 a16:	1000                	add	s0,sp,32
 a18:	e010                	sd	a2,0(s0)
 a1a:	e414                	sd	a3,8(s0)
 a1c:	e818                	sd	a4,16(s0)
 a1e:	ec1c                	sd	a5,24(s0)
 a20:	03043023          	sd	a6,32(s0)
 a24:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 a28:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 a2c:	8622                	mv	a2,s0
 a2e:	00000097          	auipc	ra,0x0
 a32:	e16080e7          	jalr	-490(ra) # 844 <vprintf>
}
 a36:	60e2                	ld	ra,24(sp)
 a38:	6442                	ld	s0,16(sp)
 a3a:	6161                	add	sp,sp,80
 a3c:	8082                	ret

0000000000000a3e <printf>:

void
printf(const char *fmt, ...)
{
 a3e:	711d                	add	sp,sp,-96
 a40:	ec06                	sd	ra,24(sp)
 a42:	e822                	sd	s0,16(sp)
 a44:	1000                	add	s0,sp,32
 a46:	e40c                	sd	a1,8(s0)
 a48:	e810                	sd	a2,16(s0)
 a4a:	ec14                	sd	a3,24(s0)
 a4c:	f018                	sd	a4,32(s0)
 a4e:	f41c                	sd	a5,40(s0)
 a50:	03043823          	sd	a6,48(s0)
 a54:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 a58:	00840613          	add	a2,s0,8
 a5c:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 a60:	85aa                	mv	a1,a0
 a62:	4505                	li	a0,1
 a64:	00000097          	auipc	ra,0x0
 a68:	de0080e7          	jalr	-544(ra) # 844 <vprintf>
}
 a6c:	60e2                	ld	ra,24(sp)
 a6e:	6442                	ld	s0,16(sp)
 a70:	6125                	add	sp,sp,96
 a72:	8082                	ret

0000000000000a74 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 a74:	1141                	add	sp,sp,-16
 a76:	e422                	sd	s0,8(sp)
 a78:	0800                	add	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 a7a:	ff050693          	add	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 a7e:	00000797          	auipc	a5,0x0
 a82:	2fa7b783          	ld	a5,762(a5) # d78 <freep>
 a86:	a02d                	j	ab0 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 a88:	4618                	lw	a4,8(a2)
 a8a:	9f2d                	addw	a4,a4,a1
 a8c:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 a90:	6398                	ld	a4,0(a5)
 a92:	6310                	ld	a2,0(a4)
 a94:	a83d                	j	ad2 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 a96:	ff852703          	lw	a4,-8(a0)
 a9a:	9f31                	addw	a4,a4,a2
 a9c:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 a9e:	ff053683          	ld	a3,-16(a0)
 aa2:	a091                	j	ae6 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 aa4:	6398                	ld	a4,0(a5)
 aa6:	00e7e463          	bltu	a5,a4,aae <free+0x3a>
 aaa:	00e6ea63          	bltu	a3,a4,abe <free+0x4a>
{
 aae:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 ab0:	fed7fae3          	bgeu	a5,a3,aa4 <free+0x30>
 ab4:	6398                	ld	a4,0(a5)
 ab6:	00e6e463          	bltu	a3,a4,abe <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 aba:	fee7eae3          	bltu	a5,a4,aae <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 abe:	ff852583          	lw	a1,-8(a0)
 ac2:	6390                	ld	a2,0(a5)
 ac4:	02059813          	sll	a6,a1,0x20
 ac8:	01c85713          	srl	a4,a6,0x1c
 acc:	9736                	add	a4,a4,a3
 ace:	fae60de3          	beq	a2,a4,a88 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 ad2:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 ad6:	4790                	lw	a2,8(a5)
 ad8:	02061593          	sll	a1,a2,0x20
 adc:	01c5d713          	srl	a4,a1,0x1c
 ae0:	973e                	add	a4,a4,a5
 ae2:	fae68ae3          	beq	a3,a4,a96 <free+0x22>
    p->s.ptr = bp->s.ptr;
 ae6:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 ae8:	00000717          	auipc	a4,0x0
 aec:	28f73823          	sd	a5,656(a4) # d78 <freep>
}
 af0:	6422                	ld	s0,8(sp)
 af2:	0141                	add	sp,sp,16
 af4:	8082                	ret

0000000000000af6 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 af6:	7139                	add	sp,sp,-64
 af8:	fc06                	sd	ra,56(sp)
 afa:	f822                	sd	s0,48(sp)
 afc:	f426                	sd	s1,40(sp)
 afe:	f04a                	sd	s2,32(sp)
 b00:	ec4e                	sd	s3,24(sp)
 b02:	e852                	sd	s4,16(sp)
 b04:	e456                	sd	s5,8(sp)
 b06:	e05a                	sd	s6,0(sp)
 b08:	0080                	add	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 b0a:	02051493          	sll	s1,a0,0x20
 b0e:	9081                	srl	s1,s1,0x20
 b10:	04bd                	add	s1,s1,15
 b12:	8091                	srl	s1,s1,0x4
 b14:	0014899b          	addw	s3,s1,1
 b18:	0485                	add	s1,s1,1
  if((prevp = freep) == 0){
 b1a:	00000517          	auipc	a0,0x0
 b1e:	25e53503          	ld	a0,606(a0) # d78 <freep>
 b22:	c515                	beqz	a0,b4e <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 b24:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 b26:	4798                	lw	a4,8(a5)
 b28:	02977f63          	bgeu	a4,s1,b66 <malloc+0x70>
  if(nu < 4096)
 b2c:	8a4e                	mv	s4,s3
 b2e:	0009871b          	sext.w	a4,s3
 b32:	6685                	lui	a3,0x1
 b34:	00d77363          	bgeu	a4,a3,b3a <malloc+0x44>
 b38:	6a05                	lui	s4,0x1
 b3a:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 b3e:	004a1a1b          	sllw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 b42:	00000917          	auipc	s2,0x0
 b46:	23690913          	add	s2,s2,566 # d78 <freep>
  if(p == (char*)-1)
 b4a:	5afd                	li	s5,-1
 b4c:	a895                	j	bc0 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 b4e:	00008797          	auipc	a5,0x8
 b52:	41278793          	add	a5,a5,1042 # 8f60 <base>
 b56:	00000717          	auipc	a4,0x0
 b5a:	22f73123          	sd	a5,546(a4) # d78 <freep>
 b5e:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 b60:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 b64:	b7e1                	j	b2c <malloc+0x36>
      if(p->s.size == nunits)
 b66:	02e48c63          	beq	s1,a4,b9e <malloc+0xa8>
        p->s.size -= nunits;
 b6a:	4137073b          	subw	a4,a4,s3
 b6e:	c798                	sw	a4,8(a5)
        p += p->s.size;
 b70:	02071693          	sll	a3,a4,0x20
 b74:	01c6d713          	srl	a4,a3,0x1c
 b78:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 b7a:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 b7e:	00000717          	auipc	a4,0x0
 b82:	1ea73d23          	sd	a0,506(a4) # d78 <freep>
      return (void*)(p + 1);
 b86:	01078513          	add	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 b8a:	70e2                	ld	ra,56(sp)
 b8c:	7442                	ld	s0,48(sp)
 b8e:	74a2                	ld	s1,40(sp)
 b90:	7902                	ld	s2,32(sp)
 b92:	69e2                	ld	s3,24(sp)
 b94:	6a42                	ld	s4,16(sp)
 b96:	6aa2                	ld	s5,8(sp)
 b98:	6b02                	ld	s6,0(sp)
 b9a:	6121                	add	sp,sp,64
 b9c:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 b9e:	6398                	ld	a4,0(a5)
 ba0:	e118                	sd	a4,0(a0)
 ba2:	bff1                	j	b7e <malloc+0x88>
  hp->s.size = nu;
 ba4:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 ba8:	0541                	add	a0,a0,16
 baa:	00000097          	auipc	ra,0x0
 bae:	eca080e7          	jalr	-310(ra) # a74 <free>
  return freep;
 bb2:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 bb6:	d971                	beqz	a0,b8a <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 bb8:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 bba:	4798                	lw	a4,8(a5)
 bbc:	fa9775e3          	bgeu	a4,s1,b66 <malloc+0x70>
    if(p == freep)
 bc0:	00093703          	ld	a4,0(s2)
 bc4:	853e                	mv	a0,a5
 bc6:	fef719e3          	bne	a4,a5,bb8 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 bca:	8552                	mv	a0,s4
 bcc:	00000097          	auipc	ra,0x0
 bd0:	b92080e7          	jalr	-1134(ra) # 75e <sbrk>
  if(p == (char*)-1)
 bd4:	fd5518e3          	bne	a0,s5,ba4 <malloc+0xae>
        return 0;
 bd8:	4501                	li	a0,0
 bda:	bf45                	j	b8a <malloc+0x94>
