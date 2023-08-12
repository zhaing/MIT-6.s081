
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	add	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	add	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	add	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	add	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	sllw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	add	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	sllw	a5,a5,0x5
    80000048:	078e                	sll	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	add	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	c3478793          	add	a5,a5,-972 # 80005c90 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	or	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	or	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	add	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	add	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	add	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e6278793          	add	a5,a5,-414 # 80000f08 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	add	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	add	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	add	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	add	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	add	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b54080e7          	jalr	-1196(ra) # 80000c60 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305c63          	blez	s3,8000016c <consolewrite+0x80>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	add	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	3e4080e7          	jalr	996(ra) # 8000250a <either_copyin>
    8000012e:	01550d63          	beq	a0,s5,80000148 <consolewrite+0x5c>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7fa080e7          	jalr	2042(ra) # 80000930 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addw	s2,s2,1
    80000140:	0485                	add	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
    80000146:	894e                	mv	s2,s3
  }
  release(&cons.lock);
    80000148:	00011517          	auipc	a0,0x11
    8000014c:	6e850513          	add	a0,a0,1768 # 80011830 <cons>
    80000150:	00001097          	auipc	ra,0x1
    80000154:	bc4080e7          	jalr	-1084(ra) # 80000d14 <release>

  return i;
}
    80000158:	854a                	mv	a0,s2
    8000015a:	60a6                	ld	ra,72(sp)
    8000015c:	6406                	ld	s0,64(sp)
    8000015e:	74e2                	ld	s1,56(sp)
    80000160:	7942                	ld	s2,48(sp)
    80000162:	79a2                	ld	s3,40(sp)
    80000164:	7a02                	ld	s4,32(sp)
    80000166:	6ae2                	ld	s5,24(sp)
    80000168:	6161                	add	sp,sp,80
    8000016a:	8082                	ret
  for(i = 0; i < n; i++){
    8000016c:	4901                	li	s2,0
    8000016e:	bfe9                	j	80000148 <consolewrite+0x5c>

0000000080000170 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000170:	711d                	add	sp,sp,-96
    80000172:	ec86                	sd	ra,88(sp)
    80000174:	e8a2                	sd	s0,80(sp)
    80000176:	e4a6                	sd	s1,72(sp)
    80000178:	e0ca                	sd	s2,64(sp)
    8000017a:	fc4e                	sd	s3,56(sp)
    8000017c:	f852                	sd	s4,48(sp)
    8000017e:	f456                	sd	s5,40(sp)
    80000180:	f05a                	sd	s6,32(sp)
    80000182:	ec5e                	sd	s7,24(sp)
    80000184:	1080                	add	s0,sp,96
    80000186:	8aaa                	mv	s5,a0
    80000188:	8a2e                	mv	s4,a1
    8000018a:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000018c:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000190:	00011517          	auipc	a0,0x11
    80000194:	6a050513          	add	a0,a0,1696 # 80011830 <cons>
    80000198:	00001097          	auipc	ra,0x1
    8000019c:	ac8080e7          	jalr	-1336(ra) # 80000c60 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a0:	00011497          	auipc	s1,0x11
    800001a4:	69048493          	add	s1,s1,1680 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a8:	00011917          	auipc	s2,0x11
    800001ac:	72090913          	add	s2,s2,1824 # 800118c8 <cons+0x98>
  while(n > 0){
    800001b0:	07305f63          	blez	s3,8000022e <consoleread+0xbe>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71463          	bne	a4,a5,800001e4 <consoleread+0x74>
      if(myproc()->killed){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	86a080e7          	jalr	-1942(ra) # 80001a2a <myproc>
    800001c8:	591c                	lw	a5,48(a0)
    800001ca:	efad                	bnez	a5,80000244 <consoleread+0xd4>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	08a080e7          	jalr	138(ra) # 8000225a <sleep>
    while(cons.r == cons.w){
    800001d8:	0984a783          	lw	a5,152(s1)
    800001dc:	09c4a703          	lw	a4,156(s1)
    800001e0:	fef700e3          	beq	a4,a5,800001c0 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e4:	00011717          	auipc	a4,0x11
    800001e8:	64c70713          	add	a4,a4,1612 # 80011830 <cons>
    800001ec:	0017869b          	addw	a3,a5,1
    800001f0:	08d72c23          	sw	a3,152(a4)
    800001f4:	07f7f693          	and	a3,a5,127
    800001f8:	9736                	add	a4,a4,a3
    800001fa:	01874703          	lbu	a4,24(a4)
    800001fe:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    80000202:	4691                	li	a3,4
    80000204:	06db8463          	beq	s7,a3,8000026c <consoleread+0xfc>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000208:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	faf40613          	add	a2,s0,-81
    80000212:	85d2                	mv	a1,s4
    80000214:	8556                	mv	a0,s5
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	29e080e7          	jalr	670(ra) # 800024b4 <either_copyout>
    8000021e:	57fd                	li	a5,-1
    80000220:	00f50763          	beq	a0,a5,8000022e <consoleread+0xbe>
      break;

    dst++;
    80000224:	0a05                	add	s4,s4,1
    --n;
    80000226:	39fd                	addw	s3,s3,-1

    if(c == '\n'){
    80000228:	47a9                	li	a5,10
    8000022a:	f8fb93e3          	bne	s7,a5,800001b0 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	add	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	ade080e7          	jalr	-1314(ra) # 80000d14 <release>

  return target - n;
    8000023e:	413b053b          	subw	a0,s6,s3
    80000242:	a811                	j	80000256 <consoleread+0xe6>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	add	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	ac8080e7          	jalr	-1336(ra) # 80000d14 <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	60e6                	ld	ra,88(sp)
    80000258:	6446                	ld	s0,80(sp)
    8000025a:	64a6                	ld	s1,72(sp)
    8000025c:	6906                	ld	s2,64(sp)
    8000025e:	79e2                	ld	s3,56(sp)
    80000260:	7a42                	ld	s4,48(sp)
    80000262:	7aa2                	ld	s5,40(sp)
    80000264:	7b02                	ld	s6,32(sp)
    80000266:	6be2                	ld	s7,24(sp)
    80000268:	6125                	add	sp,sp,96
    8000026a:	8082                	ret
      if(n < target){
    8000026c:	0009871b          	sext.w	a4,s3
    80000270:	fb677fe3          	bgeu	a4,s6,8000022e <consoleread+0xbe>
        cons.r--;
    80000274:	00011717          	auipc	a4,0x11
    80000278:	64f72a23          	sw	a5,1620(a4) # 800118c8 <cons+0x98>
    8000027c:	bf4d                	j	8000022e <consoleread+0xbe>

000000008000027e <consputc>:
{
    8000027e:	1141                	add	sp,sp,-16
    80000280:	e406                	sd	ra,8(sp)
    80000282:	e022                	sd	s0,0(sp)
    80000284:	0800                	add	s0,sp,16
  if(c == BACKSPACE){
    80000286:	10000793          	li	a5,256
    8000028a:	00f50a63          	beq	a0,a5,8000029e <consputc+0x20>
    uartputc_sync(c);
    8000028e:	00000097          	auipc	ra,0x0
    80000292:	5c4080e7          	jalr	1476(ra) # 80000852 <uartputc_sync>
}
    80000296:	60a2                	ld	ra,8(sp)
    80000298:	6402                	ld	s0,0(sp)
    8000029a:	0141                	add	sp,sp,16
    8000029c:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	5b2080e7          	jalr	1458(ra) # 80000852 <uartputc_sync>
    800002a8:	02000513          	li	a0,32
    800002ac:	00000097          	auipc	ra,0x0
    800002b0:	5a6080e7          	jalr	1446(ra) # 80000852 <uartputc_sync>
    800002b4:	4521                	li	a0,8
    800002b6:	00000097          	auipc	ra,0x0
    800002ba:	59c080e7          	jalr	1436(ra) # 80000852 <uartputc_sync>
    800002be:	bfe1                	j	80000296 <consputc+0x18>

00000000800002c0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c0:	1101                	add	sp,sp,-32
    800002c2:	ec06                	sd	ra,24(sp)
    800002c4:	e822                	sd	s0,16(sp)
    800002c6:	e426                	sd	s1,8(sp)
    800002c8:	e04a                	sd	s2,0(sp)
    800002ca:	1000                	add	s0,sp,32
    800002cc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002ce:	00011517          	auipc	a0,0x11
    800002d2:	56250513          	add	a0,a0,1378 # 80011830 <cons>
    800002d6:	00001097          	auipc	ra,0x1
    800002da:	98a080e7          	jalr	-1654(ra) # 80000c60 <acquire>

  switch(c){
    800002de:	47d5                	li	a5,21
    800002e0:	0af48663          	beq	s1,a5,8000038c <consoleintr+0xcc>
    800002e4:	0297ca63          	blt	a5,s1,80000318 <consoleintr+0x58>
    800002e8:	47a1                	li	a5,8
    800002ea:	0ef48763          	beq	s1,a5,800003d8 <consoleintr+0x118>
    800002ee:	47c1                	li	a5,16
    800002f0:	10f49a63          	bne	s1,a5,80000404 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f4:	00002097          	auipc	ra,0x2
    800002f8:	26c080e7          	jalr	620(ra) # 80002560 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fc:	00011517          	auipc	a0,0x11
    80000300:	53450513          	add	a0,a0,1332 # 80011830 <cons>
    80000304:	00001097          	auipc	ra,0x1
    80000308:	a10080e7          	jalr	-1520(ra) # 80000d14 <release>
}
    8000030c:	60e2                	ld	ra,24(sp)
    8000030e:	6442                	ld	s0,16(sp)
    80000310:	64a2                	ld	s1,8(sp)
    80000312:	6902                	ld	s2,0(sp)
    80000314:	6105                	add	sp,sp,32
    80000316:	8082                	ret
  switch(c){
    80000318:	07f00793          	li	a5,127
    8000031c:	0af48e63          	beq	s1,a5,800003d8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000320:	00011717          	auipc	a4,0x11
    80000324:	51070713          	add	a4,a4,1296 # 80011830 <cons>
    80000328:	0a072783          	lw	a5,160(a4)
    8000032c:	09872703          	lw	a4,152(a4)
    80000330:	9f99                	subw	a5,a5,a4
    80000332:	07f00713          	li	a4,127
    80000336:	fcf763e3          	bltu	a4,a5,800002fc <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033a:	47b5                	li	a5,13
    8000033c:	0cf48763          	beq	s1,a5,8000040a <consoleintr+0x14a>
      consputc(c);
    80000340:	8526                	mv	a0,s1
    80000342:	00000097          	auipc	ra,0x0
    80000346:	f3c080e7          	jalr	-196(ra) # 8000027e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000034a:	00011797          	auipc	a5,0x11
    8000034e:	4e678793          	add	a5,a5,1254 # 80011830 <cons>
    80000352:	0a07a703          	lw	a4,160(a5)
    80000356:	0017069b          	addw	a3,a4,1
    8000035a:	0006861b          	sext.w	a2,a3
    8000035e:	0ad7a023          	sw	a3,160(a5)
    80000362:	07f77713          	and	a4,a4,127
    80000366:	97ba                	add	a5,a5,a4
    80000368:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036c:	47a9                	li	a5,10
    8000036e:	0cf48563          	beq	s1,a5,80000438 <consoleintr+0x178>
    80000372:	4791                	li	a5,4
    80000374:	0cf48263          	beq	s1,a5,80000438 <consoleintr+0x178>
    80000378:	00011797          	auipc	a5,0x11
    8000037c:	5507a783          	lw	a5,1360(a5) # 800118c8 <cons+0x98>
    80000380:	0807879b          	addw	a5,a5,128
    80000384:	f6f61ce3          	bne	a2,a5,800002fc <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000388:	863e                	mv	a2,a5
    8000038a:	a07d                	j	80000438 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038c:	00011717          	auipc	a4,0x11
    80000390:	4a470713          	add	a4,a4,1188 # 80011830 <cons>
    80000394:	0a072783          	lw	a5,160(a4)
    80000398:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039c:	00011497          	auipc	s1,0x11
    800003a0:	49448493          	add	s1,s1,1172 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003a4:	4929                	li	s2,10
    800003a6:	f4f70be3          	beq	a4,a5,800002fc <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003aa:	37fd                	addw	a5,a5,-1
    800003ac:	07f7f713          	and	a4,a5,127
    800003b0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b2:	01874703          	lbu	a4,24(a4)
    800003b6:	f52703e3          	beq	a4,s2,800002fc <consoleintr+0x3c>
      cons.e--;
    800003ba:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003be:	10000513          	li	a0,256
    800003c2:	00000097          	auipc	ra,0x0
    800003c6:	ebc080e7          	jalr	-324(ra) # 8000027e <consputc>
    while(cons.e != cons.w &&
    800003ca:	0a04a783          	lw	a5,160(s1)
    800003ce:	09c4a703          	lw	a4,156(s1)
    800003d2:	fcf71ce3          	bne	a4,a5,800003aa <consoleintr+0xea>
    800003d6:	b71d                	j	800002fc <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	45870713          	add	a4,a4,1112 # 80011830 <cons>
    800003e0:	0a072783          	lw	a5,160(a4)
    800003e4:	09c72703          	lw	a4,156(a4)
    800003e8:	f0f70ae3          	beq	a4,a5,800002fc <consoleintr+0x3c>
      cons.e--;
    800003ec:	37fd                	addw	a5,a5,-1
    800003ee:	00011717          	auipc	a4,0x11
    800003f2:	4ef72123          	sw	a5,1250(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f6:	10000513          	li	a0,256
    800003fa:	00000097          	auipc	ra,0x0
    800003fe:	e84080e7          	jalr	-380(ra) # 8000027e <consputc>
    80000402:	bded                	j	800002fc <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000404:	ee048ce3          	beqz	s1,800002fc <consoleintr+0x3c>
    80000408:	bf21                	j	80000320 <consoleintr+0x60>
      consputc(c);
    8000040a:	4529                	li	a0,10
    8000040c:	00000097          	auipc	ra,0x0
    80000410:	e72080e7          	jalr	-398(ra) # 8000027e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000414:	00011797          	auipc	a5,0x11
    80000418:	41c78793          	add	a5,a5,1052 # 80011830 <cons>
    8000041c:	0a07a703          	lw	a4,160(a5)
    80000420:	0017069b          	addw	a3,a4,1
    80000424:	0006861b          	sext.w	a2,a3
    80000428:	0ad7a023          	sw	a3,160(a5)
    8000042c:	07f77713          	and	a4,a4,127
    80000430:	97ba                	add	a5,a5,a4
    80000432:	4729                	li	a4,10
    80000434:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000438:	00011797          	auipc	a5,0x11
    8000043c:	48c7aa23          	sw	a2,1172(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000440:	00011517          	auipc	a0,0x11
    80000444:	48850513          	add	a0,a0,1160 # 800118c8 <cons+0x98>
    80000448:	00002097          	auipc	ra,0x2
    8000044c:	f92080e7          	jalr	-110(ra) # 800023da <wakeup>
    80000450:	b575                	j	800002fc <consoleintr+0x3c>

0000000080000452 <consoleinit>:

void
consoleinit(void)
{
    80000452:	1141                	add	sp,sp,-16
    80000454:	e406                	sd	ra,8(sp)
    80000456:	e022                	sd	s0,0(sp)
    80000458:	0800                	add	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045a:	00008597          	auipc	a1,0x8
    8000045e:	bb658593          	add	a1,a1,-1098 # 80008010 <etext+0x10>
    80000462:	00011517          	auipc	a0,0x11
    80000466:	3ce50513          	add	a0,a0,974 # 80011830 <cons>
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	766080e7          	jalr	1894(ra) # 80000bd0 <initlock>

  uartinit();
    80000472:	00000097          	auipc	ra,0x0
    80000476:	390080e7          	jalr	912(ra) # 80000802 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047a:	00022797          	auipc	a5,0x22
    8000047e:	d3678793          	add	a5,a5,-714 # 800221b0 <devsw>
    80000482:	00000717          	auipc	a4,0x0
    80000486:	cee70713          	add	a4,a4,-786 # 80000170 <consoleread>
    8000048a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048c:	00000717          	auipc	a4,0x0
    80000490:	c6070713          	add	a4,a4,-928 # 800000ec <consolewrite>
    80000494:	ef98                	sd	a4,24(a5)
}
    80000496:	60a2                	ld	ra,8(sp)
    80000498:	6402                	ld	s0,0(sp)
    8000049a:	0141                	add	sp,sp,16
    8000049c:	8082                	ret

000000008000049e <printint>:
  }
}

static void
printint(int xx, int base, int sign)
{
    8000049e:	7179                	add	sp,sp,-48
    800004a0:	f406                	sd	ra,40(sp)
    800004a2:	f022                	sd	s0,32(sp)
    800004a4:	ec26                	sd	s1,24(sp)
    800004a6:	e84a                	sd	s2,16(sp)
    800004a8:	1800                	add	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004aa:	c219                	beqz	a2,800004b0 <printint+0x12>
    800004ac:	08054763          	bltz	a0,8000053a <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004b0:	2501                	sext.w	a0,a0
    800004b2:	4881                	li	a7,0
    800004b4:	fd040693          	add	a3,s0,-48

  i = 0;
    800004b8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004ba:	2581                	sext.w	a1,a1
    800004bc:	00008617          	auipc	a2,0x8
    800004c0:	b9c60613          	add	a2,a2,-1124 # 80008058 <digits>
    800004c4:	883a                	mv	a6,a4
    800004c6:	2705                	addw	a4,a4,1
    800004c8:	02b577bb          	remuw	a5,a0,a1
    800004cc:	1782                	sll	a5,a5,0x20
    800004ce:	9381                	srl	a5,a5,0x20
    800004d0:	97b2                	add	a5,a5,a2
    800004d2:	0007c783          	lbu	a5,0(a5)
    800004d6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004da:	0005079b          	sext.w	a5,a0
    800004de:	02b5553b          	divuw	a0,a0,a1
    800004e2:	0685                	add	a3,a3,1
    800004e4:	feb7f0e3          	bgeu	a5,a1,800004c4 <printint+0x26>

  if(sign)
    800004e8:	00088c63          	beqz	a7,80000500 <printint+0x62>
    buf[i++] = '-';
    800004ec:	fe070793          	add	a5,a4,-32
    800004f0:	00878733          	add	a4,a5,s0
    800004f4:	02d00793          	li	a5,45
    800004f8:	fef70823          	sb	a5,-16(a4)
    800004fc:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
    80000500:	02e05763          	blez	a4,8000052e <printint+0x90>
    80000504:	fd040793          	add	a5,s0,-48
    80000508:	00e784b3          	add	s1,a5,a4
    8000050c:	fff78913          	add	s2,a5,-1
    80000510:	993a                	add	s2,s2,a4
    80000512:	377d                	addw	a4,a4,-1
    80000514:	1702                	sll	a4,a4,0x20
    80000516:	9301                	srl	a4,a4,0x20
    80000518:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051c:	fff4c503          	lbu	a0,-1(s1)
    80000520:	00000097          	auipc	ra,0x0
    80000524:	d5e080e7          	jalr	-674(ra) # 8000027e <consputc>
  while(--i >= 0)
    80000528:	14fd                	add	s1,s1,-1
    8000052a:	ff2499e3          	bne	s1,s2,8000051c <printint+0x7e>
}
    8000052e:	70a2                	ld	ra,40(sp)
    80000530:	7402                	ld	s0,32(sp)
    80000532:	64e2                	ld	s1,24(sp)
    80000534:	6942                	ld	s2,16(sp)
    80000536:	6145                	add	sp,sp,48
    80000538:	8082                	ret
    x = -xx;
    8000053a:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053e:	4885                	li	a7,1
    x = -xx;
    80000540:	bf95                	j	800004b4 <printint+0x16>

0000000080000542 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000542:	1101                	add	sp,sp,-32
    80000544:	ec06                	sd	ra,24(sp)
    80000546:	e822                	sd	s0,16(sp)
    80000548:	e426                	sd	s1,8(sp)
    8000054a:	1000                	add	s0,sp,32
    8000054c:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054e:	00011797          	auipc	a5,0x11
    80000552:	3a07a123          	sw	zero,930(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    80000556:	00008517          	auipc	a0,0x8
    8000055a:	ac250513          	add	a0,a0,-1342 # 80008018 <etext+0x18>
    8000055e:	00000097          	auipc	ra,0x0
    80000562:	036080e7          	jalr	54(ra) # 80000594 <printf>
  printf(s);
    80000566:	8526                	mv	a0,s1
    80000568:	00000097          	auipc	ra,0x0
    8000056c:	02c080e7          	jalr	44(ra) # 80000594 <printf>
  printf("\n");
    80000570:	00008517          	auipc	a0,0x8
    80000574:	b7050513          	add	a0,a0,-1168 # 800080e0 <digits+0x88>
    80000578:	00000097          	auipc	ra,0x0
    8000057c:	01c080e7          	jalr	28(ra) # 80000594 <printf>
  backtrace();
    80000580:	00000097          	auipc	ra,0x0
    80000584:	1f4080e7          	jalr	500(ra) # 80000774 <backtrace>
  panicked = 1; // freeze uart output from other CPUs
    80000588:	4785                	li	a5,1
    8000058a:	00009717          	auipc	a4,0x9
    8000058e:	a6f72b23          	sw	a5,-1418(a4) # 80009000 <panicked>
  for(;;)
    80000592:	a001                	j	80000592 <panic+0x50>

0000000080000594 <printf>:
{
    80000594:	7131                	add	sp,sp,-192
    80000596:	fc86                	sd	ra,120(sp)
    80000598:	f8a2                	sd	s0,112(sp)
    8000059a:	f4a6                	sd	s1,104(sp)
    8000059c:	f0ca                	sd	s2,96(sp)
    8000059e:	ecce                	sd	s3,88(sp)
    800005a0:	e8d2                	sd	s4,80(sp)
    800005a2:	e4d6                	sd	s5,72(sp)
    800005a4:	e0da                	sd	s6,64(sp)
    800005a6:	fc5e                	sd	s7,56(sp)
    800005a8:	f862                	sd	s8,48(sp)
    800005aa:	f466                	sd	s9,40(sp)
    800005ac:	f06a                	sd	s10,32(sp)
    800005ae:	ec6e                	sd	s11,24(sp)
    800005b0:	0100                	add	s0,sp,128
    800005b2:	8a2a                	mv	s4,a0
    800005b4:	e40c                	sd	a1,8(s0)
    800005b6:	e810                	sd	a2,16(s0)
    800005b8:	ec14                	sd	a3,24(s0)
    800005ba:	f018                	sd	a4,32(s0)
    800005bc:	f41c                	sd	a5,40(s0)
    800005be:	03043823          	sd	a6,48(s0)
    800005c2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c6:	00011d97          	auipc	s11,0x11
    800005ca:	32adad83          	lw	s11,810(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005ce:	020d9b63          	bnez	s11,80000604 <printf+0x70>
  if (fmt == 0)
    800005d2:	040a0263          	beqz	s4,80000616 <printf+0x82>
  va_start(ap, fmt);
    800005d6:	00840793          	add	a5,s0,8
    800005da:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005de:	000a4503          	lbu	a0,0(s4)
    800005e2:	14050f63          	beqz	a0,80000740 <printf+0x1ac>
    800005e6:	4981                	li	s3,0
    if(c != '%'){
    800005e8:	02500a93          	li	s5,37
    switch(c){
    800005ec:	07000b93          	li	s7,112
  consputc('x');
    800005f0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f2:	00008b17          	auipc	s6,0x8
    800005f6:	a66b0b13          	add	s6,s6,-1434 # 80008058 <digits>
    switch(c){
    800005fa:	07300c93          	li	s9,115
    800005fe:	06400c13          	li	s8,100
    80000602:	a82d                	j	8000063c <printf+0xa8>
    acquire(&pr.lock);
    80000604:	00011517          	auipc	a0,0x11
    80000608:	2d450513          	add	a0,a0,724 # 800118d8 <pr>
    8000060c:	00000097          	auipc	ra,0x0
    80000610:	654080e7          	jalr	1620(ra) # 80000c60 <acquire>
    80000614:	bf7d                	j	800005d2 <printf+0x3e>
    panic("null fmt");
    80000616:	00008517          	auipc	a0,0x8
    8000061a:	a1250513          	add	a0,a0,-1518 # 80008028 <etext+0x28>
    8000061e:	00000097          	auipc	ra,0x0
    80000622:	f24080e7          	jalr	-220(ra) # 80000542 <panic>
      consputc(c);
    80000626:	00000097          	auipc	ra,0x0
    8000062a:	c58080e7          	jalr	-936(ra) # 8000027e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062e:	2985                	addw	s3,s3,1
    80000630:	013a07b3          	add	a5,s4,s3
    80000634:	0007c503          	lbu	a0,0(a5)
    80000638:	10050463          	beqz	a0,80000740 <printf+0x1ac>
    if(c != '%'){
    8000063c:	ff5515e3          	bne	a0,s5,80000626 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000640:	2985                	addw	s3,s3,1
    80000642:	013a07b3          	add	a5,s4,s3
    80000646:	0007c783          	lbu	a5,0(a5)
    8000064a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000064e:	cbed                	beqz	a5,80000740 <printf+0x1ac>
    switch(c){
    80000650:	05778a63          	beq	a5,s7,800006a4 <printf+0x110>
    80000654:	02fbf663          	bgeu	s7,a5,80000680 <printf+0xec>
    80000658:	09978863          	beq	a5,s9,800006e8 <printf+0x154>
    8000065c:	07800713          	li	a4,120
    80000660:	0ce79563          	bne	a5,a4,8000072a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000664:	f8843783          	ld	a5,-120(s0)
    80000668:	00878713          	add	a4,a5,8
    8000066c:	f8e43423          	sd	a4,-120(s0)
    80000670:	4605                	li	a2,1
    80000672:	85ea                	mv	a1,s10
    80000674:	4388                	lw	a0,0(a5)
    80000676:	00000097          	auipc	ra,0x0
    8000067a:	e28080e7          	jalr	-472(ra) # 8000049e <printint>
      break;
    8000067e:	bf45                	j	8000062e <printf+0x9a>
    switch(c){
    80000680:	09578f63          	beq	a5,s5,8000071e <printf+0x18a>
    80000684:	0b879363          	bne	a5,s8,8000072a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000688:	f8843783          	ld	a5,-120(s0)
    8000068c:	00878713          	add	a4,a5,8
    80000690:	f8e43423          	sd	a4,-120(s0)
    80000694:	4605                	li	a2,1
    80000696:	45a9                	li	a1,10
    80000698:	4388                	lw	a0,0(a5)
    8000069a:	00000097          	auipc	ra,0x0
    8000069e:	e04080e7          	jalr	-508(ra) # 8000049e <printint>
      break;
    800006a2:	b771                	j	8000062e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a4:	f8843783          	ld	a5,-120(s0)
    800006a8:	00878713          	add	a4,a5,8
    800006ac:	f8e43423          	sd	a4,-120(s0)
    800006b0:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006b4:	03000513          	li	a0,48
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc6080e7          	jalr	-1082(ra) # 8000027e <consputc>
  consputc('x');
    800006c0:	07800513          	li	a0,120
    800006c4:	00000097          	auipc	ra,0x0
    800006c8:	bba080e7          	jalr	-1094(ra) # 8000027e <consputc>
    800006cc:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ce:	03c95793          	srl	a5,s2,0x3c
    800006d2:	97da                	add	a5,a5,s6
    800006d4:	0007c503          	lbu	a0,0(a5)
    800006d8:	00000097          	auipc	ra,0x0
    800006dc:	ba6080e7          	jalr	-1114(ra) # 8000027e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e0:	0912                	sll	s2,s2,0x4
    800006e2:	34fd                	addw	s1,s1,-1
    800006e4:	f4ed                	bnez	s1,800006ce <printf+0x13a>
    800006e6:	b7a1                	j	8000062e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	add	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	6384                	ld	s1,0(a5)
    800006f6:	cc89                	beqz	s1,80000710 <printf+0x17c>
      for(; *s; s++)
    800006f8:	0004c503          	lbu	a0,0(s1)
    800006fc:	d90d                	beqz	a0,8000062e <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b80080e7          	jalr	-1152(ra) # 8000027e <consputc>
      for(; *s; s++)
    80000706:	0485                	add	s1,s1,1
    80000708:	0004c503          	lbu	a0,0(s1)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x16a>
    8000070e:	b705                	j	8000062e <printf+0x9a>
        s = "(null)";
    80000710:	00008497          	auipc	s1,0x8
    80000714:	91048493          	add	s1,s1,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x16a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5e080e7          	jalr	-1186(ra) # 8000027e <consputc>
      break;
    80000728:	b719                	j	8000062e <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b52080e7          	jalr	-1198(ra) # 8000027e <consputc>
      consputc(c);
    80000734:	8526                	mv	a0,s1
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b48080e7          	jalr	-1208(ra) # 8000027e <consputc>
      break;
    8000073e:	bdc5                	j	8000062e <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1ce>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	add	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00011517          	auipc	a0,0x11
    80000766:	17650513          	add	a0,a0,374 # 800118d8 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	5aa080e7          	jalr	1450(ra) # 80000d14 <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b0>

0000000080000774 <backtrace>:
{
    80000774:	7179                	add	sp,sp,-48
    80000776:	f406                	sd	ra,40(sp)
    80000778:	f022                	sd	s0,32(sp)
    8000077a:	ec26                	sd	s1,24(sp)
    8000077c:	e84a                	sd	s2,16(sp)
    8000077e:	e44e                	sd	s3,8(sp)
    80000780:	1800                	add	s0,sp,48
  printf("backtrace:\n");
    80000782:	00008517          	auipc	a0,0x8
    80000786:	8b650513          	add	a0,a0,-1866 # 80008038 <etext+0x38>
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	e0a080e7          	jalr	-502(ra) # 80000594 <printf>
  asm volatile("mv %0, s0" : "=r" (x) );
    80000792:	84a2                	mv	s1,s0
  uint64 top = PGROUNDUP(fp); //整个栈的顶部
    80000794:	6905                	lui	s2,0x1
    80000796:	197d                	add	s2,s2,-1 # fff <_entry-0x7ffff001>
    80000798:	9926                	add	s2,s2,s1
    8000079a:	77fd                	lui	a5,0xfffff
    8000079c:	00f97933          	and	s2,s2,a5
  for(;fp<top;fp=*((uint64*)(fp - 16))){
    800007a0:	0324f163          	bgeu	s1,s2,800007c2 <backtrace+0x4e>
    printf("%p\n",*((uint64*)(fp - 8)));
    800007a4:	00008997          	auipc	s3,0x8
    800007a8:	8a498993          	add	s3,s3,-1884 # 80008048 <etext+0x48>
    800007ac:	ff84b583          	ld	a1,-8(s1)
    800007b0:	854e                	mv	a0,s3
    800007b2:	00000097          	auipc	ra,0x0
    800007b6:	de2080e7          	jalr	-542(ra) # 80000594 <printf>
  for(;fp<top;fp=*((uint64*)(fp - 16))){
    800007ba:	ff04b483          	ld	s1,-16(s1)
    800007be:	ff24e7e3          	bltu	s1,s2,800007ac <backtrace+0x38>
}
    800007c2:	70a2                	ld	ra,40(sp)
    800007c4:	7402                	ld	s0,32(sp)
    800007c6:	64e2                	ld	s1,24(sp)
    800007c8:	6942                	ld	s2,16(sp)
    800007ca:	69a2                	ld	s3,8(sp)
    800007cc:	6145                	add	sp,sp,48
    800007ce:	8082                	ret

00000000800007d0 <printfinit>:
    ;
}

void
printfinit(void)
{
    800007d0:	1101                	add	sp,sp,-32
    800007d2:	ec06                	sd	ra,24(sp)
    800007d4:	e822                	sd	s0,16(sp)
    800007d6:	e426                	sd	s1,8(sp)
    800007d8:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    800007da:	00011497          	auipc	s1,0x11
    800007de:	0fe48493          	add	s1,s1,254 # 800118d8 <pr>
    800007e2:	00008597          	auipc	a1,0x8
    800007e6:	86e58593          	add	a1,a1,-1938 # 80008050 <etext+0x50>
    800007ea:	8526                	mv	a0,s1
    800007ec:	00000097          	auipc	ra,0x0
    800007f0:	3e4080e7          	jalr	996(ra) # 80000bd0 <initlock>
  pr.locking = 1;
    800007f4:	4785                	li	a5,1
    800007f6:	cc9c                	sw	a5,24(s1)
}
    800007f8:	60e2                	ld	ra,24(sp)
    800007fa:	6442                	ld	s0,16(sp)
    800007fc:	64a2                	ld	s1,8(sp)
    800007fe:	6105                	add	sp,sp,32
    80000800:	8082                	ret

0000000080000802 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000802:	1141                	add	sp,sp,-16
    80000804:	e406                	sd	ra,8(sp)
    80000806:	e022                	sd	s0,0(sp)
    80000808:	0800                	add	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000080a:	100007b7          	lui	a5,0x10000
    8000080e:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000812:	f8000713          	li	a4,-128
    80000816:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000081a:	470d                	li	a4,3
    8000081c:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000820:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000824:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000828:	469d                	li	a3,7
    8000082a:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    8000082e:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000832:	00008597          	auipc	a1,0x8
    80000836:	83e58593          	add	a1,a1,-1986 # 80008070 <digits+0x18>
    8000083a:	00011517          	auipc	a0,0x11
    8000083e:	0be50513          	add	a0,a0,190 # 800118f8 <uart_tx_lock>
    80000842:	00000097          	auipc	ra,0x0
    80000846:	38e080e7          	jalr	910(ra) # 80000bd0 <initlock>
}
    8000084a:	60a2                	ld	ra,8(sp)
    8000084c:	6402                	ld	s0,0(sp)
    8000084e:	0141                	add	sp,sp,16
    80000850:	8082                	ret

0000000080000852 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000852:	1101                	add	sp,sp,-32
    80000854:	ec06                	sd	ra,24(sp)
    80000856:	e822                	sd	s0,16(sp)
    80000858:	e426                	sd	s1,8(sp)
    8000085a:	1000                	add	s0,sp,32
    8000085c:	84aa                	mv	s1,a0
  push_off();
    8000085e:	00000097          	auipc	ra,0x0
    80000862:	3b6080e7          	jalr	950(ra) # 80000c14 <push_off>

  if(panicked){
    80000866:	00008797          	auipc	a5,0x8
    8000086a:	79a7a783          	lw	a5,1946(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000086e:	10000737          	lui	a4,0x10000
  if(panicked){
    80000872:	c391                	beqz	a5,80000876 <uartputc_sync+0x24>
    for(;;)
    80000874:	a001                	j	80000874 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000876:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000087a:	0207f793          	and	a5,a5,32
    8000087e:	dfe5                	beqz	a5,80000876 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000880:	0ff4f513          	zext.b	a0,s1
    80000884:	100007b7          	lui	a5,0x10000
    80000888:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    8000088c:	00000097          	auipc	ra,0x0
    80000890:	428080e7          	jalr	1064(ra) # 80000cb4 <pop_off>
}
    80000894:	60e2                	ld	ra,24(sp)
    80000896:	6442                	ld	s0,16(sp)
    80000898:	64a2                	ld	s1,8(sp)
    8000089a:	6105                	add	sp,sp,32
    8000089c:	8082                	ret

000000008000089e <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000089e:	00008797          	auipc	a5,0x8
    800008a2:	7667a783          	lw	a5,1894(a5) # 80009004 <uart_tx_r>
    800008a6:	00008717          	auipc	a4,0x8
    800008aa:	76272703          	lw	a4,1890(a4) # 80009008 <uart_tx_w>
    800008ae:	08f70063          	beq	a4,a5,8000092e <uartstart+0x90>
{
    800008b2:	7139                	add	sp,sp,-64
    800008b4:	fc06                	sd	ra,56(sp)
    800008b6:	f822                	sd	s0,48(sp)
    800008b8:	f426                	sd	s1,40(sp)
    800008ba:	f04a                	sd	s2,32(sp)
    800008bc:	ec4e                	sd	s3,24(sp)
    800008be:	e852                	sd	s4,16(sp)
    800008c0:	e456                	sd	s5,8(sp)
    800008c2:	0080                	add	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008c4:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    800008c8:	00011a97          	auipc	s5,0x11
    800008cc:	030a8a93          	add	s5,s5,48 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008d0:	00008497          	auipc	s1,0x8
    800008d4:	73448493          	add	s1,s1,1844 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800008d8:	00008a17          	auipc	s4,0x8
    800008dc:	730a0a13          	add	s4,s4,1840 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008e0:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    800008e4:	02077713          	and	a4,a4,32
    800008e8:	cb15                	beqz	a4,8000091c <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    800008ea:	00fa8733          	add	a4,s5,a5
    800008ee:	01874983          	lbu	s3,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008f2:	2785                	addw	a5,a5,1
    800008f4:	41f7d71b          	sraw	a4,a5,0x1f
    800008f8:	01b7571b          	srlw	a4,a4,0x1b
    800008fc:	9fb9                	addw	a5,a5,a4
    800008fe:	8bfd                	and	a5,a5,31
    80000900:	9f99                	subw	a5,a5,a4
    80000902:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000904:	8526                	mv	a0,s1
    80000906:	00002097          	auipc	ra,0x2
    8000090a:	ad4080e7          	jalr	-1324(ra) # 800023da <wakeup>
    
    WriteReg(THR, c);
    8000090e:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000912:	409c                	lw	a5,0(s1)
    80000914:	000a2703          	lw	a4,0(s4)
    80000918:	fcf714e3          	bne	a4,a5,800008e0 <uartstart+0x42>
  }
}
    8000091c:	70e2                	ld	ra,56(sp)
    8000091e:	7442                	ld	s0,48(sp)
    80000920:	74a2                	ld	s1,40(sp)
    80000922:	7902                	ld	s2,32(sp)
    80000924:	69e2                	ld	s3,24(sp)
    80000926:	6a42                	ld	s4,16(sp)
    80000928:	6aa2                	ld	s5,8(sp)
    8000092a:	6121                	add	sp,sp,64
    8000092c:	8082                	ret
    8000092e:	8082                	ret

0000000080000930 <uartputc>:
{
    80000930:	7179                	add	sp,sp,-48
    80000932:	f406                	sd	ra,40(sp)
    80000934:	f022                	sd	s0,32(sp)
    80000936:	ec26                	sd	s1,24(sp)
    80000938:	e84a                	sd	s2,16(sp)
    8000093a:	e44e                	sd	s3,8(sp)
    8000093c:	e052                	sd	s4,0(sp)
    8000093e:	1800                	add	s0,sp,48
    80000940:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    80000942:	00011517          	auipc	a0,0x11
    80000946:	fb650513          	add	a0,a0,-74 # 800118f8 <uart_tx_lock>
    8000094a:	00000097          	auipc	ra,0x0
    8000094e:	316080e7          	jalr	790(ra) # 80000c60 <acquire>
  if(panicked){
    80000952:	00008797          	auipc	a5,0x8
    80000956:	6ae7a783          	lw	a5,1710(a5) # 80009000 <panicked>
    8000095a:	c391                	beqz	a5,8000095e <uartputc+0x2e>
    for(;;)
    8000095c:	a001                	j	8000095c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000095e:	00008697          	auipc	a3,0x8
    80000962:	6aa6a683          	lw	a3,1706(a3) # 80009008 <uart_tx_w>
    80000966:	0016879b          	addw	a5,a3,1
    8000096a:	41f7d71b          	sraw	a4,a5,0x1f
    8000096e:	01b7571b          	srlw	a4,a4,0x1b
    80000972:	9fb9                	addw	a5,a5,a4
    80000974:	8bfd                	and	a5,a5,31
    80000976:	9f99                	subw	a5,a5,a4
    80000978:	00008717          	auipc	a4,0x8
    8000097c:	68c72703          	lw	a4,1676(a4) # 80009004 <uart_tx_r>
    80000980:	04f71363          	bne	a4,a5,800009c6 <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000984:	00011a17          	auipc	s4,0x11
    80000988:	f74a0a13          	add	s4,s4,-140 # 800118f8 <uart_tx_lock>
    8000098c:	00008917          	auipc	s2,0x8
    80000990:	67890913          	add	s2,s2,1656 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000994:	00008997          	auipc	s3,0x8
    80000998:	67498993          	add	s3,s3,1652 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000099c:	85d2                	mv	a1,s4
    8000099e:	854a                	mv	a0,s2
    800009a0:	00002097          	auipc	ra,0x2
    800009a4:	8ba080e7          	jalr	-1862(ra) # 8000225a <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009a8:	0009a683          	lw	a3,0(s3)
    800009ac:	0016879b          	addw	a5,a3,1
    800009b0:	41f7d71b          	sraw	a4,a5,0x1f
    800009b4:	01b7571b          	srlw	a4,a4,0x1b
    800009b8:	9fb9                	addw	a5,a5,a4
    800009ba:	8bfd                	and	a5,a5,31
    800009bc:	9f99                	subw	a5,a5,a4
    800009be:	00092703          	lw	a4,0(s2)
    800009c2:	fcf70de3          	beq	a4,a5,8000099c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    800009c6:	00011917          	auipc	s2,0x11
    800009ca:	f3290913          	add	s2,s2,-206 # 800118f8 <uart_tx_lock>
    800009ce:	96ca                	add	a3,a3,s2
    800009d0:	00968c23          	sb	s1,24(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    800009d4:	00008717          	auipc	a4,0x8
    800009d8:	62f72a23          	sw	a5,1588(a4) # 80009008 <uart_tx_w>
      uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	ec2080e7          	jalr	-318(ra) # 8000089e <uartstart>
      release(&uart_tx_lock);
    800009e4:	854a                	mv	a0,s2
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	32e080e7          	jalr	814(ra) # 80000d14 <release>
}
    800009ee:	70a2                	ld	ra,40(sp)
    800009f0:	7402                	ld	s0,32(sp)
    800009f2:	64e2                	ld	s1,24(sp)
    800009f4:	6942                	ld	s2,16(sp)
    800009f6:	69a2                	ld	s3,8(sp)
    800009f8:	6a02                	ld	s4,0(sp)
    800009fa:	6145                	add	sp,sp,48
    800009fc:	8082                	ret

00000000800009fe <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009fe:	1141                	add	sp,sp,-16
    80000a00:	e422                	sd	s0,8(sp)
    80000a02:	0800                	add	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000a04:	100007b7          	lui	a5,0x10000
    80000a08:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000a0c:	8b85                	and	a5,a5,1
    80000a0e:	cb81                	beqz	a5,80000a1e <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000a10:	100007b7          	lui	a5,0x10000
    80000a14:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000a18:	6422                	ld	s0,8(sp)
    80000a1a:	0141                	add	sp,sp,16
    80000a1c:	8082                	ret
    return -1;
    80000a1e:	557d                	li	a0,-1
    80000a20:	bfe5                	j	80000a18 <uartgetc+0x1a>

0000000080000a22 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000a22:	1101                	add	sp,sp,-32
    80000a24:	ec06                	sd	ra,24(sp)
    80000a26:	e822                	sd	s0,16(sp)
    80000a28:	e426                	sd	s1,8(sp)
    80000a2a:	1000                	add	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a2c:	54fd                	li	s1,-1
    80000a2e:	a029                	j	80000a38 <uartintr+0x16>
      break;
    consoleintr(c);
    80000a30:	00000097          	auipc	ra,0x0
    80000a34:	890080e7          	jalr	-1904(ra) # 800002c0 <consoleintr>
    int c = uartgetc();
    80000a38:	00000097          	auipc	ra,0x0
    80000a3c:	fc6080e7          	jalr	-58(ra) # 800009fe <uartgetc>
    if(c == -1)
    80000a40:	fe9518e3          	bne	a0,s1,80000a30 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a44:	00011497          	auipc	s1,0x11
    80000a48:	eb448493          	add	s1,s1,-332 # 800118f8 <uart_tx_lock>
    80000a4c:	8526                	mv	a0,s1
    80000a4e:	00000097          	auipc	ra,0x0
    80000a52:	212080e7          	jalr	530(ra) # 80000c60 <acquire>
  uartstart();
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	e48080e7          	jalr	-440(ra) # 8000089e <uartstart>
  release(&uart_tx_lock);
    80000a5e:	8526                	mv	a0,s1
    80000a60:	00000097          	auipc	ra,0x0
    80000a64:	2b4080e7          	jalr	692(ra) # 80000d14 <release>
}
    80000a68:	60e2                	ld	ra,24(sp)
    80000a6a:	6442                	ld	s0,16(sp)
    80000a6c:	64a2                	ld	s1,8(sp)
    80000a6e:	6105                	add	sp,sp,32
    80000a70:	8082                	ret

0000000080000a72 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a72:	1101                	add	sp,sp,-32
    80000a74:	ec06                	sd	ra,24(sp)
    80000a76:	e822                	sd	s0,16(sp)
    80000a78:	e426                	sd	s1,8(sp)
    80000a7a:	e04a                	sd	s2,0(sp)
    80000a7c:	1000                	add	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a7e:	03451793          	sll	a5,a0,0x34
    80000a82:	ebb9                	bnez	a5,80000ad8 <kfree+0x66>
    80000a84:	84aa                	mv	s1,a0
    80000a86:	00026797          	auipc	a5,0x26
    80000a8a:	57a78793          	add	a5,a5,1402 # 80027000 <end>
    80000a8e:	04f56563          	bltu	a0,a5,80000ad8 <kfree+0x66>
    80000a92:	47c5                	li	a5,17
    80000a94:	07ee                	sll	a5,a5,0x1b
    80000a96:	04f57163          	bgeu	a0,a5,80000ad8 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a9a:	6605                	lui	a2,0x1
    80000a9c:	4585                	li	a1,1
    80000a9e:	00000097          	auipc	ra,0x0
    80000aa2:	2be080e7          	jalr	702(ra) # 80000d5c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000aa6:	00011917          	auipc	s2,0x11
    80000aaa:	e8a90913          	add	s2,s2,-374 # 80011930 <kmem>
    80000aae:	854a                	mv	a0,s2
    80000ab0:	00000097          	auipc	ra,0x0
    80000ab4:	1b0080e7          	jalr	432(ra) # 80000c60 <acquire>
  r->next = kmem.freelist;
    80000ab8:	01893783          	ld	a5,24(s2)
    80000abc:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000abe:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000ac2:	854a                	mv	a0,s2
    80000ac4:	00000097          	auipc	ra,0x0
    80000ac8:	250080e7          	jalr	592(ra) # 80000d14 <release>
}
    80000acc:	60e2                	ld	ra,24(sp)
    80000ace:	6442                	ld	s0,16(sp)
    80000ad0:	64a2                	ld	s1,8(sp)
    80000ad2:	6902                	ld	s2,0(sp)
    80000ad4:	6105                	add	sp,sp,32
    80000ad6:	8082                	ret
    panic("kfree");
    80000ad8:	00007517          	auipc	a0,0x7
    80000adc:	5a050513          	add	a0,a0,1440 # 80008078 <digits+0x20>
    80000ae0:	00000097          	auipc	ra,0x0
    80000ae4:	a62080e7          	jalr	-1438(ra) # 80000542 <panic>

0000000080000ae8 <freerange>:
{
    80000ae8:	7179                	add	sp,sp,-48
    80000aea:	f406                	sd	ra,40(sp)
    80000aec:	f022                	sd	s0,32(sp)
    80000aee:	ec26                	sd	s1,24(sp)
    80000af0:	e84a                	sd	s2,16(sp)
    80000af2:	e44e                	sd	s3,8(sp)
    80000af4:	e052                	sd	s4,0(sp)
    80000af6:	1800                	add	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000af8:	6785                	lui	a5,0x1
    80000afa:	fff78713          	add	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000afe:	00e504b3          	add	s1,a0,a4
    80000b02:	777d                	lui	a4,0xfffff
    80000b04:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b06:	94be                	add	s1,s1,a5
    80000b08:	0095ee63          	bltu	a1,s1,80000b24 <freerange+0x3c>
    80000b0c:	892e                	mv	s2,a1
    kfree(p);
    80000b0e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b10:	6985                	lui	s3,0x1
    kfree(p);
    80000b12:	01448533          	add	a0,s1,s4
    80000b16:	00000097          	auipc	ra,0x0
    80000b1a:	f5c080e7          	jalr	-164(ra) # 80000a72 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b1e:	94ce                	add	s1,s1,s3
    80000b20:	fe9979e3          	bgeu	s2,s1,80000b12 <freerange+0x2a>
}
    80000b24:	70a2                	ld	ra,40(sp)
    80000b26:	7402                	ld	s0,32(sp)
    80000b28:	64e2                	ld	s1,24(sp)
    80000b2a:	6942                	ld	s2,16(sp)
    80000b2c:	69a2                	ld	s3,8(sp)
    80000b2e:	6a02                	ld	s4,0(sp)
    80000b30:	6145                	add	sp,sp,48
    80000b32:	8082                	ret

0000000080000b34 <kinit>:
{
    80000b34:	1141                	add	sp,sp,-16
    80000b36:	e406                	sd	ra,8(sp)
    80000b38:	e022                	sd	s0,0(sp)
    80000b3a:	0800                	add	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b3c:	00007597          	auipc	a1,0x7
    80000b40:	54458593          	add	a1,a1,1348 # 80008080 <digits+0x28>
    80000b44:	00011517          	auipc	a0,0x11
    80000b48:	dec50513          	add	a0,a0,-532 # 80011930 <kmem>
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	084080e7          	jalr	132(ra) # 80000bd0 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b54:	45c5                	li	a1,17
    80000b56:	05ee                	sll	a1,a1,0x1b
    80000b58:	00026517          	auipc	a0,0x26
    80000b5c:	4a850513          	add	a0,a0,1192 # 80027000 <end>
    80000b60:	00000097          	auipc	ra,0x0
    80000b64:	f88080e7          	jalr	-120(ra) # 80000ae8 <freerange>
}
    80000b68:	60a2                	ld	ra,8(sp)
    80000b6a:	6402                	ld	s0,0(sp)
    80000b6c:	0141                	add	sp,sp,16
    80000b6e:	8082                	ret

0000000080000b70 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b70:	1101                	add	sp,sp,-32
    80000b72:	ec06                	sd	ra,24(sp)
    80000b74:	e822                	sd	s0,16(sp)
    80000b76:	e426                	sd	s1,8(sp)
    80000b78:	1000                	add	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b7a:	00011497          	auipc	s1,0x11
    80000b7e:	db648493          	add	s1,s1,-586 # 80011930 <kmem>
    80000b82:	8526                	mv	a0,s1
    80000b84:	00000097          	auipc	ra,0x0
    80000b88:	0dc080e7          	jalr	220(ra) # 80000c60 <acquire>
  r = kmem.freelist;
    80000b8c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b8e:	c885                	beqz	s1,80000bbe <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b90:	609c                	ld	a5,0(s1)
    80000b92:	00011517          	auipc	a0,0x11
    80000b96:	d9e50513          	add	a0,a0,-610 # 80011930 <kmem>
    80000b9a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b9c:	00000097          	auipc	ra,0x0
    80000ba0:	178080e7          	jalr	376(ra) # 80000d14 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000ba4:	6605                	lui	a2,0x1
    80000ba6:	4595                	li	a1,5
    80000ba8:	8526                	mv	a0,s1
    80000baa:	00000097          	auipc	ra,0x0
    80000bae:	1b2080e7          	jalr	434(ra) # 80000d5c <memset>
  return (void*)r;
}
    80000bb2:	8526                	mv	a0,s1
    80000bb4:	60e2                	ld	ra,24(sp)
    80000bb6:	6442                	ld	s0,16(sp)
    80000bb8:	64a2                	ld	s1,8(sp)
    80000bba:	6105                	add	sp,sp,32
    80000bbc:	8082                	ret
  release(&kmem.lock);
    80000bbe:	00011517          	auipc	a0,0x11
    80000bc2:	d7250513          	add	a0,a0,-654 # 80011930 <kmem>
    80000bc6:	00000097          	auipc	ra,0x0
    80000bca:	14e080e7          	jalr	334(ra) # 80000d14 <release>
  if(r)
    80000bce:	b7d5                	j	80000bb2 <kalloc+0x42>

0000000080000bd0 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bd0:	1141                	add	sp,sp,-16
    80000bd2:	e422                	sd	s0,8(sp)
    80000bd4:	0800                	add	s0,sp,16
  lk->name = name;
    80000bd6:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bd8:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bdc:	00053823          	sd	zero,16(a0)
}
    80000be0:	6422                	ld	s0,8(sp)
    80000be2:	0141                	add	sp,sp,16
    80000be4:	8082                	ret

0000000080000be6 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000be6:	411c                	lw	a5,0(a0)
    80000be8:	e399                	bnez	a5,80000bee <holding+0x8>
    80000bea:	4501                	li	a0,0
  return r;
}
    80000bec:	8082                	ret
{
    80000bee:	1101                	add	sp,sp,-32
    80000bf0:	ec06                	sd	ra,24(sp)
    80000bf2:	e822                	sd	s0,16(sp)
    80000bf4:	e426                	sd	s1,8(sp)
    80000bf6:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bf8:	6904                	ld	s1,16(a0)
    80000bfa:	00001097          	auipc	ra,0x1
    80000bfe:	e14080e7          	jalr	-492(ra) # 80001a0e <mycpu>
    80000c02:	40a48533          	sub	a0,s1,a0
    80000c06:	00153513          	seqz	a0,a0
}
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	add	sp,sp,32
    80000c12:	8082                	ret

0000000080000c14 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c14:	1101                	add	sp,sp,-32
    80000c16:	ec06                	sd	ra,24(sp)
    80000c18:	e822                	sd	s0,16(sp)
    80000c1a:	e426                	sd	s1,8(sp)
    80000c1c:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c1e:	100024f3          	csrr	s1,sstatus
    80000c22:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c26:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c28:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	de2080e7          	jalr	-542(ra) # 80001a0e <mycpu>
    80000c34:	5d3c                	lw	a5,120(a0)
    80000c36:	cf89                	beqz	a5,80000c50 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c38:	00001097          	auipc	ra,0x1
    80000c3c:	dd6080e7          	jalr	-554(ra) # 80001a0e <mycpu>
    80000c40:	5d3c                	lw	a5,120(a0)
    80000c42:	2785                	addw	a5,a5,1
    80000c44:	dd3c                	sw	a5,120(a0)
}
    80000c46:	60e2                	ld	ra,24(sp)
    80000c48:	6442                	ld	s0,16(sp)
    80000c4a:	64a2                	ld	s1,8(sp)
    80000c4c:	6105                	add	sp,sp,32
    80000c4e:	8082                	ret
    mycpu()->intena = old;
    80000c50:	00001097          	auipc	ra,0x1
    80000c54:	dbe080e7          	jalr	-578(ra) # 80001a0e <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c58:	8085                	srl	s1,s1,0x1
    80000c5a:	8885                	and	s1,s1,1
    80000c5c:	dd64                	sw	s1,124(a0)
    80000c5e:	bfe9                	j	80000c38 <push_off+0x24>

0000000080000c60 <acquire>:
{
    80000c60:	1101                	add	sp,sp,-32
    80000c62:	ec06                	sd	ra,24(sp)
    80000c64:	e822                	sd	s0,16(sp)
    80000c66:	e426                	sd	s1,8(sp)
    80000c68:	1000                	add	s0,sp,32
    80000c6a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	fa8080e7          	jalr	-88(ra) # 80000c14 <push_off>
  if(holding(lk))
    80000c74:	8526                	mv	a0,s1
    80000c76:	00000097          	auipc	ra,0x0
    80000c7a:	f70080e7          	jalr	-144(ra) # 80000be6 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c7e:	4705                	li	a4,1
  if(holding(lk))
    80000c80:	e115                	bnez	a0,80000ca4 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c82:	87ba                	mv	a5,a4
    80000c84:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c88:	2781                	sext.w	a5,a5
    80000c8a:	ffe5                	bnez	a5,80000c82 <acquire+0x22>
  __sync_synchronize();
    80000c8c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c90:	00001097          	auipc	ra,0x1
    80000c94:	d7e080e7          	jalr	-642(ra) # 80001a0e <mycpu>
    80000c98:	e888                	sd	a0,16(s1)
}
    80000c9a:	60e2                	ld	ra,24(sp)
    80000c9c:	6442                	ld	s0,16(sp)
    80000c9e:	64a2                	ld	s1,8(sp)
    80000ca0:	6105                	add	sp,sp,32
    80000ca2:	8082                	ret
    panic("acquire");
    80000ca4:	00007517          	auipc	a0,0x7
    80000ca8:	3e450513          	add	a0,a0,996 # 80008088 <digits+0x30>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	896080e7          	jalr	-1898(ra) # 80000542 <panic>

0000000080000cb4 <pop_off>:

void
pop_off(void)
{
    80000cb4:	1141                	add	sp,sp,-16
    80000cb6:	e406                	sd	ra,8(sp)
    80000cb8:	e022                	sd	s0,0(sp)
    80000cba:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    80000cbc:	00001097          	auipc	ra,0x1
    80000cc0:	d52080e7          	jalr	-686(ra) # 80001a0e <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cc4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cc8:	8b89                	and	a5,a5,2
  if(intr_get())
    80000cca:	e78d                	bnez	a5,80000cf4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000ccc:	5d3c                	lw	a5,120(a0)
    80000cce:	02f05b63          	blez	a5,80000d04 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cd2:	37fd                	addw	a5,a5,-1
    80000cd4:	0007871b          	sext.w	a4,a5
    80000cd8:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cda:	eb09                	bnez	a4,80000cec <pop_off+0x38>
    80000cdc:	5d7c                	lw	a5,124(a0)
    80000cde:	c799                	beqz	a5,80000cec <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ce0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ce4:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ce8:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cec:	60a2                	ld	ra,8(sp)
    80000cee:	6402                	ld	s0,0(sp)
    80000cf0:	0141                	add	sp,sp,16
    80000cf2:	8082                	ret
    panic("pop_off - interruptible");
    80000cf4:	00007517          	auipc	a0,0x7
    80000cf8:	39c50513          	add	a0,a0,924 # 80008090 <digits+0x38>
    80000cfc:	00000097          	auipc	ra,0x0
    80000d00:	846080e7          	jalr	-1978(ra) # 80000542 <panic>
    panic("pop_off");
    80000d04:	00007517          	auipc	a0,0x7
    80000d08:	3a450513          	add	a0,a0,932 # 800080a8 <digits+0x50>
    80000d0c:	00000097          	auipc	ra,0x0
    80000d10:	836080e7          	jalr	-1994(ra) # 80000542 <panic>

0000000080000d14 <release>:
{
    80000d14:	1101                	add	sp,sp,-32
    80000d16:	ec06                	sd	ra,24(sp)
    80000d18:	e822                	sd	s0,16(sp)
    80000d1a:	e426                	sd	s1,8(sp)
    80000d1c:	1000                	add	s0,sp,32
    80000d1e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d20:	00000097          	auipc	ra,0x0
    80000d24:	ec6080e7          	jalr	-314(ra) # 80000be6 <holding>
    80000d28:	c115                	beqz	a0,80000d4c <release+0x38>
  lk->cpu = 0;
    80000d2a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d2e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d32:	0f50000f          	fence	iorw,ow
    80000d36:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d3a:	00000097          	auipc	ra,0x0
    80000d3e:	f7a080e7          	jalr	-134(ra) # 80000cb4 <pop_off>
}
    80000d42:	60e2                	ld	ra,24(sp)
    80000d44:	6442                	ld	s0,16(sp)
    80000d46:	64a2                	ld	s1,8(sp)
    80000d48:	6105                	add	sp,sp,32
    80000d4a:	8082                	ret
    panic("release");
    80000d4c:	00007517          	auipc	a0,0x7
    80000d50:	36450513          	add	a0,a0,868 # 800080b0 <digits+0x58>
    80000d54:	fffff097          	auipc	ra,0xfffff
    80000d58:	7ee080e7          	jalr	2030(ra) # 80000542 <panic>

0000000080000d5c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d5c:	1141                	add	sp,sp,-16
    80000d5e:	e422                	sd	s0,8(sp)
    80000d60:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d62:	ca19                	beqz	a2,80000d78 <memset+0x1c>
    80000d64:	87aa                	mv	a5,a0
    80000d66:	1602                	sll	a2,a2,0x20
    80000d68:	9201                	srl	a2,a2,0x20
    80000d6a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d6e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d72:	0785                	add	a5,a5,1
    80000d74:	fee79de3          	bne	a5,a4,80000d6e <memset+0x12>
  }
  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	add	sp,sp,16
    80000d7c:	8082                	ret

0000000080000d7e <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d7e:	1141                	add	sp,sp,-16
    80000d80:	e422                	sd	s0,8(sp)
    80000d82:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d84:	ca05                	beqz	a2,80000db4 <memcmp+0x36>
    80000d86:	fff6069b          	addw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d8a:	1682                	sll	a3,a3,0x20
    80000d8c:	9281                	srl	a3,a3,0x20
    80000d8e:	0685                	add	a3,a3,1
    80000d90:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d92:	00054783          	lbu	a5,0(a0)
    80000d96:	0005c703          	lbu	a4,0(a1)
    80000d9a:	00e79863          	bne	a5,a4,80000daa <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d9e:	0505                	add	a0,a0,1
    80000da0:	0585                	add	a1,a1,1
  while(n-- > 0){
    80000da2:	fed518e3          	bne	a0,a3,80000d92 <memcmp+0x14>
  }

  return 0;
    80000da6:	4501                	li	a0,0
    80000da8:	a019                	j	80000dae <memcmp+0x30>
      return *s1 - *s2;
    80000daa:	40e7853b          	subw	a0,a5,a4
}
    80000dae:	6422                	ld	s0,8(sp)
    80000db0:	0141                	add	sp,sp,16
    80000db2:	8082                	ret
  return 0;
    80000db4:	4501                	li	a0,0
    80000db6:	bfe5                	j	80000dae <memcmp+0x30>

0000000080000db8 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000db8:	1141                	add	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dbe:	02a5e563          	bltu	a1,a0,80000de8 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dc2:	fff6069b          	addw	a3,a2,-1
    80000dc6:	ce11                	beqz	a2,80000de2 <memmove+0x2a>
    80000dc8:	1682                	sll	a3,a3,0x20
    80000dca:	9281                	srl	a3,a3,0x20
    80000dcc:	0685                	add	a3,a3,1
    80000dce:	96ae                	add	a3,a3,a1
    80000dd0:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000dd2:	0585                	add	a1,a1,1
    80000dd4:	0785                	add	a5,a5,1
    80000dd6:	fff5c703          	lbu	a4,-1(a1)
    80000dda:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000dde:	fed59ae3          	bne	a1,a3,80000dd2 <memmove+0x1a>

  return dst;
}
    80000de2:	6422                	ld	s0,8(sp)
    80000de4:	0141                	add	sp,sp,16
    80000de6:	8082                	ret
  if(s < d && s + n > d){
    80000de8:	02061713          	sll	a4,a2,0x20
    80000dec:	9301                	srl	a4,a4,0x20
    80000dee:	00e587b3          	add	a5,a1,a4
    80000df2:	fcf578e3          	bgeu	a0,a5,80000dc2 <memmove+0xa>
    d += n;
    80000df6:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000df8:	fff6069b          	addw	a3,a2,-1
    80000dfc:	d27d                	beqz	a2,80000de2 <memmove+0x2a>
    80000dfe:	02069613          	sll	a2,a3,0x20
    80000e02:	9201                	srl	a2,a2,0x20
    80000e04:	fff64613          	not	a2,a2
    80000e08:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e0a:	17fd                	add	a5,a5,-1
    80000e0c:	177d                	add	a4,a4,-1 # ffffffffffffefff <end+0xffffffff7ffd7fff>
    80000e0e:	0007c683          	lbu	a3,0(a5)
    80000e12:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e16:	fef61ae3          	bne	a2,a5,80000e0a <memmove+0x52>
    80000e1a:	b7e1                	j	80000de2 <memmove+0x2a>

0000000080000e1c <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e1c:	1141                	add	sp,sp,-16
    80000e1e:	e406                	sd	ra,8(sp)
    80000e20:	e022                	sd	s0,0(sp)
    80000e22:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    80000e24:	00000097          	auipc	ra,0x0
    80000e28:	f94080e7          	jalr	-108(ra) # 80000db8 <memmove>
}
    80000e2c:	60a2                	ld	ra,8(sp)
    80000e2e:	6402                	ld	s0,0(sp)
    80000e30:	0141                	add	sp,sp,16
    80000e32:	8082                	ret

0000000080000e34 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e34:	1141                	add	sp,sp,-16
    80000e36:	e422                	sd	s0,8(sp)
    80000e38:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e3a:	ce11                	beqz	a2,80000e56 <strncmp+0x22>
    80000e3c:	00054783          	lbu	a5,0(a0)
    80000e40:	cf89                	beqz	a5,80000e5a <strncmp+0x26>
    80000e42:	0005c703          	lbu	a4,0(a1)
    80000e46:	00f71a63          	bne	a4,a5,80000e5a <strncmp+0x26>
    n--, p++, q++;
    80000e4a:	367d                	addw	a2,a2,-1
    80000e4c:	0505                	add	a0,a0,1
    80000e4e:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e50:	f675                	bnez	a2,80000e3c <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e52:	4501                	li	a0,0
    80000e54:	a809                	j	80000e66 <strncmp+0x32>
    80000e56:	4501                	li	a0,0
    80000e58:	a039                	j	80000e66 <strncmp+0x32>
  if(n == 0)
    80000e5a:	ca09                	beqz	a2,80000e6c <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e5c:	00054503          	lbu	a0,0(a0)
    80000e60:	0005c783          	lbu	a5,0(a1)
    80000e64:	9d1d                	subw	a0,a0,a5
}
    80000e66:	6422                	ld	s0,8(sp)
    80000e68:	0141                	add	sp,sp,16
    80000e6a:	8082                	ret
    return 0;
    80000e6c:	4501                	li	a0,0
    80000e6e:	bfe5                	j	80000e66 <strncmp+0x32>

0000000080000e70 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e70:	1141                	add	sp,sp,-16
    80000e72:	e422                	sd	s0,8(sp)
    80000e74:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e76:	87aa                	mv	a5,a0
    80000e78:	86b2                	mv	a3,a2
    80000e7a:	367d                	addw	a2,a2,-1
    80000e7c:	00d05963          	blez	a3,80000e8e <strncpy+0x1e>
    80000e80:	0785                	add	a5,a5,1
    80000e82:	0005c703          	lbu	a4,0(a1)
    80000e86:	fee78fa3          	sb	a4,-1(a5)
    80000e8a:	0585                	add	a1,a1,1
    80000e8c:	f775                	bnez	a4,80000e78 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e8e:	873e                	mv	a4,a5
    80000e90:	9fb5                	addw	a5,a5,a3
    80000e92:	37fd                	addw	a5,a5,-1
    80000e94:	00c05963          	blez	a2,80000ea6 <strncpy+0x36>
    *s++ = 0;
    80000e98:	0705                	add	a4,a4,1
    80000e9a:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e9e:	40e786bb          	subw	a3,a5,a4
    80000ea2:	fed04be3          	bgtz	a3,80000e98 <strncpy+0x28>
  return os;
}
    80000ea6:	6422                	ld	s0,8(sp)
    80000ea8:	0141                	add	sp,sp,16
    80000eaa:	8082                	ret

0000000080000eac <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000eac:	1141                	add	sp,sp,-16
    80000eae:	e422                	sd	s0,8(sp)
    80000eb0:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000eb2:	02c05363          	blez	a2,80000ed8 <safestrcpy+0x2c>
    80000eb6:	fff6069b          	addw	a3,a2,-1
    80000eba:	1682                	sll	a3,a3,0x20
    80000ebc:	9281                	srl	a3,a3,0x20
    80000ebe:	96ae                	add	a3,a3,a1
    80000ec0:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ec2:	00d58963          	beq	a1,a3,80000ed4 <safestrcpy+0x28>
    80000ec6:	0585                	add	a1,a1,1
    80000ec8:	0785                	add	a5,a5,1
    80000eca:	fff5c703          	lbu	a4,-1(a1)
    80000ece:	fee78fa3          	sb	a4,-1(a5)
    80000ed2:	fb65                	bnez	a4,80000ec2 <safestrcpy+0x16>
    ;
  *s = 0;
    80000ed4:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ed8:	6422                	ld	s0,8(sp)
    80000eda:	0141                	add	sp,sp,16
    80000edc:	8082                	ret

0000000080000ede <strlen>:

int
strlen(const char *s)
{
    80000ede:	1141                	add	sp,sp,-16
    80000ee0:	e422                	sd	s0,8(sp)
    80000ee2:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ee4:	00054783          	lbu	a5,0(a0)
    80000ee8:	cf91                	beqz	a5,80000f04 <strlen+0x26>
    80000eea:	0505                	add	a0,a0,1
    80000eec:	87aa                	mv	a5,a0
    80000eee:	86be                	mv	a3,a5
    80000ef0:	0785                	add	a5,a5,1
    80000ef2:	fff7c703          	lbu	a4,-1(a5)
    80000ef6:	ff65                	bnez	a4,80000eee <strlen+0x10>
    80000ef8:	40a6853b          	subw	a0,a3,a0
    80000efc:	2505                	addw	a0,a0,1
    ;
  return n;
}
    80000efe:	6422                	ld	s0,8(sp)
    80000f00:	0141                	add	sp,sp,16
    80000f02:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f04:	4501                	li	a0,0
    80000f06:	bfe5                	j	80000efe <strlen+0x20>

0000000080000f08 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f08:	1141                	add	sp,sp,-16
    80000f0a:	e406                	sd	ra,8(sp)
    80000f0c:	e022                	sd	s0,0(sp)
    80000f0e:	0800                	add	s0,sp,16
  if(cpuid() == 0){
    80000f10:	00001097          	auipc	ra,0x1
    80000f14:	aee080e7          	jalr	-1298(ra) # 800019fe <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f18:	00008717          	auipc	a4,0x8
    80000f1c:	0f470713          	add	a4,a4,244 # 8000900c <started>
  if(cpuid() == 0){
    80000f20:	c139                	beqz	a0,80000f66 <main+0x5e>
    while(started == 0)
    80000f22:	431c                	lw	a5,0(a4)
    80000f24:	2781                	sext.w	a5,a5
    80000f26:	dff5                	beqz	a5,80000f22 <main+0x1a>
      ;
    __sync_synchronize();
    80000f28:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f2c:	00001097          	auipc	ra,0x1
    80000f30:	ad2080e7          	jalr	-1326(ra) # 800019fe <cpuid>
    80000f34:	85aa                	mv	a1,a0
    80000f36:	00007517          	auipc	a0,0x7
    80000f3a:	19a50513          	add	a0,a0,410 # 800080d0 <digits+0x78>
    80000f3e:	fffff097          	auipc	ra,0xfffff
    80000f42:	656080e7          	jalr	1622(ra) # 80000594 <printf>
    kvminithart();    // turn on paging
    80000f46:	00000097          	auipc	ra,0x0
    80000f4a:	0d8080e7          	jalr	216(ra) # 8000101e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f4e:	00001097          	auipc	ra,0x1
    80000f52:	754080e7          	jalr	1876(ra) # 800026a2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f56:	00005097          	auipc	ra,0x5
    80000f5a:	d7a080e7          	jalr	-646(ra) # 80005cd0 <plicinithart>
  }

  scheduler();        
    80000f5e:	00001097          	auipc	ra,0x1
    80000f62:	020080e7          	jalr	32(ra) # 80001f7e <scheduler>
    consoleinit();
    80000f66:	fffff097          	auipc	ra,0xfffff
    80000f6a:	4ec080e7          	jalr	1260(ra) # 80000452 <consoleinit>
    printfinit();
    80000f6e:	00000097          	auipc	ra,0x0
    80000f72:	862080e7          	jalr	-1950(ra) # 800007d0 <printfinit>
    printf("\n");
    80000f76:	00007517          	auipc	a0,0x7
    80000f7a:	16a50513          	add	a0,a0,362 # 800080e0 <digits+0x88>
    80000f7e:	fffff097          	auipc	ra,0xfffff
    80000f82:	616080e7          	jalr	1558(ra) # 80000594 <printf>
    printf("xv6 kernel is booting\n");
    80000f86:	00007517          	auipc	a0,0x7
    80000f8a:	13250513          	add	a0,a0,306 # 800080b8 <digits+0x60>
    80000f8e:	fffff097          	auipc	ra,0xfffff
    80000f92:	606080e7          	jalr	1542(ra) # 80000594 <printf>
    printf("\n");
    80000f96:	00007517          	auipc	a0,0x7
    80000f9a:	14a50513          	add	a0,a0,330 # 800080e0 <digits+0x88>
    80000f9e:	fffff097          	auipc	ra,0xfffff
    80000fa2:	5f6080e7          	jalr	1526(ra) # 80000594 <printf>
    kinit();         // physical page allocator
    80000fa6:	00000097          	auipc	ra,0x0
    80000faa:	b8e080e7          	jalr	-1138(ra) # 80000b34 <kinit>
    kvminit();       // create kernel page table
    80000fae:	00000097          	auipc	ra,0x0
    80000fb2:	2a0080e7          	jalr	672(ra) # 8000124e <kvminit>
    kvminithart();   // turn on paging
    80000fb6:	00000097          	auipc	ra,0x0
    80000fba:	068080e7          	jalr	104(ra) # 8000101e <kvminithart>
    procinit();      // process table
    80000fbe:	00001097          	auipc	ra,0x1
    80000fc2:	970080e7          	jalr	-1680(ra) # 8000192e <procinit>
    trapinit();      // trap vectors
    80000fc6:	00001097          	auipc	ra,0x1
    80000fca:	6b4080e7          	jalr	1716(ra) # 8000267a <trapinit>
    trapinithart();  // install kernel trap vector
    80000fce:	00001097          	auipc	ra,0x1
    80000fd2:	6d4080e7          	jalr	1748(ra) # 800026a2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fd6:	00005097          	auipc	ra,0x5
    80000fda:	ce4080e7          	jalr	-796(ra) # 80005cba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fde:	00005097          	auipc	ra,0x5
    80000fe2:	cf2080e7          	jalr	-782(ra) # 80005cd0 <plicinithart>
    binit();         // buffer cache
    80000fe6:	00002097          	auipc	ra,0x2
    80000fea:	eee080e7          	jalr	-274(ra) # 80002ed4 <binit>
    iinit();         // inode cache
    80000fee:	00002097          	auipc	ra,0x2
    80000ff2:	57a080e7          	jalr	1402(ra) # 80003568 <iinit>
    fileinit();      // file table
    80000ff6:	00003097          	auipc	ra,0x3
    80000ffa:	4ec080e7          	jalr	1260(ra) # 800044e2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000ffe:	00005097          	auipc	ra,0x5
    80001002:	dd8080e7          	jalr	-552(ra) # 80005dd6 <virtio_disk_init>
    userinit();      // first user process
    80001006:	00001097          	auipc	ra,0x1
    8000100a:	d0a080e7          	jalr	-758(ra) # 80001d10 <userinit>
    __sync_synchronize();
    8000100e:	0ff0000f          	fence
    started = 1;
    80001012:	4785                	li	a5,1
    80001014:	00008717          	auipc	a4,0x8
    80001018:	fef72c23          	sw	a5,-8(a4) # 8000900c <started>
    8000101c:	b789                	j	80000f5e <main+0x56>

000000008000101e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000101e:	1141                	add	sp,sp,-16
    80001020:	e422                	sd	s0,8(sp)
    80001022:	0800                	add	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001024:	00008797          	auipc	a5,0x8
    80001028:	fec7b783          	ld	a5,-20(a5) # 80009010 <kernel_pagetable>
    8000102c:	83b1                	srl	a5,a5,0xc
    8000102e:	577d                	li	a4,-1
    80001030:	177e                	sll	a4,a4,0x3f
    80001032:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001034:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001038:	12000073          	sfence.vma
  sfence_vma();
}
    8000103c:	6422                	ld	s0,8(sp)
    8000103e:	0141                	add	sp,sp,16
    80001040:	8082                	ret

0000000080001042 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001042:	7139                	add	sp,sp,-64
    80001044:	fc06                	sd	ra,56(sp)
    80001046:	f822                	sd	s0,48(sp)
    80001048:	f426                	sd	s1,40(sp)
    8000104a:	f04a                	sd	s2,32(sp)
    8000104c:	ec4e                	sd	s3,24(sp)
    8000104e:	e852                	sd	s4,16(sp)
    80001050:	e456                	sd	s5,8(sp)
    80001052:	e05a                	sd	s6,0(sp)
    80001054:	0080                	add	s0,sp,64
    80001056:	84aa                	mv	s1,a0
    80001058:	89ae                	mv	s3,a1
    8000105a:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srl	a5,a5,0x1a
    80001060:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001062:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001064:	04b7f263          	bgeu	a5,a1,800010a8 <walk+0x66>
    panic("walk");
    80001068:	00007517          	auipc	a0,0x7
    8000106c:	08050513          	add	a0,a0,128 # 800080e8 <digits+0x90>
    80001070:	fffff097          	auipc	ra,0xfffff
    80001074:	4d2080e7          	jalr	1234(ra) # 80000542 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001078:	060a8663          	beqz	s5,800010e4 <walk+0xa2>
    8000107c:	00000097          	auipc	ra,0x0
    80001080:	af4080e7          	jalr	-1292(ra) # 80000b70 <kalloc>
    80001084:	84aa                	mv	s1,a0
    80001086:	c529                	beqz	a0,800010d0 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001088:	6605                	lui	a2,0x1
    8000108a:	4581                	li	a1,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	cd0080e7          	jalr	-816(ra) # 80000d5c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001094:	00c4d793          	srl	a5,s1,0xc
    80001098:	07aa                	sll	a5,a5,0xa
    8000109a:	0017e793          	or	a5,a5,1
    8000109e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010a2:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd7ff7>
    800010a4:	036a0063          	beq	s4,s6,800010c4 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010a8:	0149d933          	srl	s2,s3,s4
    800010ac:	1ff97913          	and	s2,s2,511
    800010b0:	090e                	sll	s2,s2,0x3
    800010b2:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010b4:	00093483          	ld	s1,0(s2)
    800010b8:	0014f793          	and	a5,s1,1
    800010bc:	dfd5                	beqz	a5,80001078 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010be:	80a9                	srl	s1,s1,0xa
    800010c0:	04b2                	sll	s1,s1,0xc
    800010c2:	b7c5                	j	800010a2 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010c4:	00c9d513          	srl	a0,s3,0xc
    800010c8:	1ff57513          	and	a0,a0,511
    800010cc:	050e                	sll	a0,a0,0x3
    800010ce:	9526                	add	a0,a0,s1
}
    800010d0:	70e2                	ld	ra,56(sp)
    800010d2:	7442                	ld	s0,48(sp)
    800010d4:	74a2                	ld	s1,40(sp)
    800010d6:	7902                	ld	s2,32(sp)
    800010d8:	69e2                	ld	s3,24(sp)
    800010da:	6a42                	ld	s4,16(sp)
    800010dc:	6aa2                	ld	s5,8(sp)
    800010de:	6b02                	ld	s6,0(sp)
    800010e0:	6121                	add	sp,sp,64
    800010e2:	8082                	ret
        return 0;
    800010e4:	4501                	li	a0,0
    800010e6:	b7ed                	j	800010d0 <walk+0x8e>

00000000800010e8 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010e8:	57fd                	li	a5,-1
    800010ea:	83e9                	srl	a5,a5,0x1a
    800010ec:	00b7f463          	bgeu	a5,a1,800010f4 <walkaddr+0xc>
    return 0;
    800010f0:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010f2:	8082                	ret
{
    800010f4:	1141                	add	sp,sp,-16
    800010f6:	e406                	sd	ra,8(sp)
    800010f8:	e022                	sd	s0,0(sp)
    800010fa:	0800                	add	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010fc:	4601                	li	a2,0
    800010fe:	00000097          	auipc	ra,0x0
    80001102:	f44080e7          	jalr	-188(ra) # 80001042 <walk>
  if(pte == 0)
    80001106:	c105                	beqz	a0,80001126 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001108:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000110a:	0117f693          	and	a3,a5,17
    8000110e:	4745                	li	a4,17
    return 0;
    80001110:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001112:	00e68663          	beq	a3,a4,8000111e <walkaddr+0x36>
}
    80001116:	60a2                	ld	ra,8(sp)
    80001118:	6402                	ld	s0,0(sp)
    8000111a:	0141                	add	sp,sp,16
    8000111c:	8082                	ret
  pa = PTE2PA(*pte);
    8000111e:	83a9                	srl	a5,a5,0xa
    80001120:	00c79513          	sll	a0,a5,0xc
  return pa;
    80001124:	bfcd                	j	80001116 <walkaddr+0x2e>
    return 0;
    80001126:	4501                	li	a0,0
    80001128:	b7fd                	j	80001116 <walkaddr+0x2e>

000000008000112a <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000112a:	1101                	add	sp,sp,-32
    8000112c:	ec06                	sd	ra,24(sp)
    8000112e:	e822                	sd	s0,16(sp)
    80001130:	e426                	sd	s1,8(sp)
    80001132:	1000                	add	s0,sp,32
    80001134:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001136:	1552                	sll	a0,a0,0x34
    80001138:	03455493          	srl	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    8000113c:	4601                	li	a2,0
    8000113e:	00008517          	auipc	a0,0x8
    80001142:	ed253503          	ld	a0,-302(a0) # 80009010 <kernel_pagetable>
    80001146:	00000097          	auipc	ra,0x0
    8000114a:	efc080e7          	jalr	-260(ra) # 80001042 <walk>
  if(pte == 0)
    8000114e:	cd09                	beqz	a0,80001168 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001150:	6108                	ld	a0,0(a0)
    80001152:	00157793          	and	a5,a0,1
    80001156:	c38d                	beqz	a5,80001178 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001158:	8129                	srl	a0,a0,0xa
    8000115a:	0532                	sll	a0,a0,0xc
  return pa+off;
}
    8000115c:	9526                	add	a0,a0,s1
    8000115e:	60e2                	ld	ra,24(sp)
    80001160:	6442                	ld	s0,16(sp)
    80001162:	64a2                	ld	s1,8(sp)
    80001164:	6105                	add	sp,sp,32
    80001166:	8082                	ret
    panic("kvmpa");
    80001168:	00007517          	auipc	a0,0x7
    8000116c:	f8850513          	add	a0,a0,-120 # 800080f0 <digits+0x98>
    80001170:	fffff097          	auipc	ra,0xfffff
    80001174:	3d2080e7          	jalr	978(ra) # 80000542 <panic>
    panic("kvmpa");
    80001178:	00007517          	auipc	a0,0x7
    8000117c:	f7850513          	add	a0,a0,-136 # 800080f0 <digits+0x98>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3c2080e7          	jalr	962(ra) # 80000542 <panic>

0000000080001188 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001188:	715d                	add	sp,sp,-80
    8000118a:	e486                	sd	ra,72(sp)
    8000118c:	e0a2                	sd	s0,64(sp)
    8000118e:	fc26                	sd	s1,56(sp)
    80001190:	f84a                	sd	s2,48(sp)
    80001192:	f44e                	sd	s3,40(sp)
    80001194:	f052                	sd	s4,32(sp)
    80001196:	ec56                	sd	s5,24(sp)
    80001198:	e85a                	sd	s6,16(sp)
    8000119a:	e45e                	sd	s7,8(sp)
    8000119c:	0880                	add	s0,sp,80
    8000119e:	8aaa                	mv	s5,a0
    800011a0:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011a2:	777d                	lui	a4,0xfffff
    800011a4:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011a8:	fff60993          	add	s3,a2,-1 # fff <_entry-0x7ffff001>
    800011ac:	99ae                	add	s3,s3,a1
    800011ae:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011b2:	893e                	mv	s2,a5
    800011b4:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011b8:	6b85                	lui	s7,0x1
    800011ba:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011be:	4605                	li	a2,1
    800011c0:	85ca                	mv	a1,s2
    800011c2:	8556                	mv	a0,s5
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	e7e080e7          	jalr	-386(ra) # 80001042 <walk>
    800011cc:	c51d                	beqz	a0,800011fa <mappages+0x72>
    if(*pte & PTE_V)
    800011ce:	611c                	ld	a5,0(a0)
    800011d0:	8b85                	and	a5,a5,1
    800011d2:	ef81                	bnez	a5,800011ea <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011d4:	80b1                	srl	s1,s1,0xc
    800011d6:	04aa                	sll	s1,s1,0xa
    800011d8:	0164e4b3          	or	s1,s1,s6
    800011dc:	0014e493          	or	s1,s1,1
    800011e0:	e104                	sd	s1,0(a0)
    if(a == last)
    800011e2:	03390863          	beq	s2,s3,80001212 <mappages+0x8a>
    a += PGSIZE;
    800011e6:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011e8:	bfc9                	j	800011ba <mappages+0x32>
      panic("remap");
    800011ea:	00007517          	auipc	a0,0x7
    800011ee:	f0e50513          	add	a0,a0,-242 # 800080f8 <digits+0xa0>
    800011f2:	fffff097          	auipc	ra,0xfffff
    800011f6:	350080e7          	jalr	848(ra) # 80000542 <panic>
      return -1;
    800011fa:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011fc:	60a6                	ld	ra,72(sp)
    800011fe:	6406                	ld	s0,64(sp)
    80001200:	74e2                	ld	s1,56(sp)
    80001202:	7942                	ld	s2,48(sp)
    80001204:	79a2                	ld	s3,40(sp)
    80001206:	7a02                	ld	s4,32(sp)
    80001208:	6ae2                	ld	s5,24(sp)
    8000120a:	6b42                	ld	s6,16(sp)
    8000120c:	6ba2                	ld	s7,8(sp)
    8000120e:	6161                	add	sp,sp,80
    80001210:	8082                	ret
  return 0;
    80001212:	4501                	li	a0,0
    80001214:	b7e5                	j	800011fc <mappages+0x74>

0000000080001216 <kvmmap>:
{
    80001216:	1141                	add	sp,sp,-16
    80001218:	e406                	sd	ra,8(sp)
    8000121a:	e022                	sd	s0,0(sp)
    8000121c:	0800                	add	s0,sp,16
    8000121e:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001220:	86ae                	mv	a3,a1
    80001222:	85aa                	mv	a1,a0
    80001224:	00008517          	auipc	a0,0x8
    80001228:	dec53503          	ld	a0,-532(a0) # 80009010 <kernel_pagetable>
    8000122c:	00000097          	auipc	ra,0x0
    80001230:	f5c080e7          	jalr	-164(ra) # 80001188 <mappages>
    80001234:	e509                	bnez	a0,8000123e <kvmmap+0x28>
}
    80001236:	60a2                	ld	ra,8(sp)
    80001238:	6402                	ld	s0,0(sp)
    8000123a:	0141                	add	sp,sp,16
    8000123c:	8082                	ret
    panic("kvmmap");
    8000123e:	00007517          	auipc	a0,0x7
    80001242:	ec250513          	add	a0,a0,-318 # 80008100 <digits+0xa8>
    80001246:	fffff097          	auipc	ra,0xfffff
    8000124a:	2fc080e7          	jalr	764(ra) # 80000542 <panic>

000000008000124e <kvminit>:
{
    8000124e:	1101                	add	sp,sp,-32
    80001250:	ec06                	sd	ra,24(sp)
    80001252:	e822                	sd	s0,16(sp)
    80001254:	e426                	sd	s1,8(sp)
    80001256:	1000                	add	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001258:	00000097          	auipc	ra,0x0
    8000125c:	918080e7          	jalr	-1768(ra) # 80000b70 <kalloc>
    80001260:	00008717          	auipc	a4,0x8
    80001264:	daa73823          	sd	a0,-592(a4) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001268:	6605                	lui	a2,0x1
    8000126a:	4581                	li	a1,0
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	af0080e7          	jalr	-1296(ra) # 80000d5c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001274:	4699                	li	a3,6
    80001276:	6605                	lui	a2,0x1
    80001278:	100005b7          	lui	a1,0x10000
    8000127c:	10000537          	lui	a0,0x10000
    80001280:	00000097          	auipc	ra,0x0
    80001284:	f96080e7          	jalr	-106(ra) # 80001216 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001288:	4699                	li	a3,6
    8000128a:	6605                	lui	a2,0x1
    8000128c:	100015b7          	lui	a1,0x10001
    80001290:	10001537          	lui	a0,0x10001
    80001294:	00000097          	auipc	ra,0x0
    80001298:	f82080e7          	jalr	-126(ra) # 80001216 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000129c:	4699                	li	a3,6
    8000129e:	6641                	lui	a2,0x10
    800012a0:	020005b7          	lui	a1,0x2000
    800012a4:	02000537          	lui	a0,0x2000
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	f6e080e7          	jalr	-146(ra) # 80001216 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012b0:	4699                	li	a3,6
    800012b2:	00400637          	lui	a2,0x400
    800012b6:	0c0005b7          	lui	a1,0xc000
    800012ba:	0c000537          	lui	a0,0xc000
    800012be:	00000097          	auipc	ra,0x0
    800012c2:	f58080e7          	jalr	-168(ra) # 80001216 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012c6:	00007497          	auipc	s1,0x7
    800012ca:	d3a48493          	add	s1,s1,-710 # 80008000 <etext>
    800012ce:	46a9                	li	a3,10
    800012d0:	80007617          	auipc	a2,0x80007
    800012d4:	d3060613          	add	a2,a2,-720 # 8000 <_entry-0x7fff8000>
    800012d8:	4585                	li	a1,1
    800012da:	05fe                	sll	a1,a1,0x1f
    800012dc:	852e                	mv	a0,a1
    800012de:	00000097          	auipc	ra,0x0
    800012e2:	f38080e7          	jalr	-200(ra) # 80001216 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012e6:	4699                	li	a3,6
    800012e8:	4645                	li	a2,17
    800012ea:	066e                	sll	a2,a2,0x1b
    800012ec:	8e05                	sub	a2,a2,s1
    800012ee:	85a6                	mv	a1,s1
    800012f0:	8526                	mv	a0,s1
    800012f2:	00000097          	auipc	ra,0x0
    800012f6:	f24080e7          	jalr	-220(ra) # 80001216 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012fa:	46a9                	li	a3,10
    800012fc:	6605                	lui	a2,0x1
    800012fe:	00006597          	auipc	a1,0x6
    80001302:	d0258593          	add	a1,a1,-766 # 80007000 <_trampoline>
    80001306:	04000537          	lui	a0,0x4000
    8000130a:	157d                	add	a0,a0,-1 # 3ffffff <_entry-0x7c000001>
    8000130c:	0532                	sll	a0,a0,0xc
    8000130e:	00000097          	auipc	ra,0x0
    80001312:	f08080e7          	jalr	-248(ra) # 80001216 <kvmmap>
}
    80001316:	60e2                	ld	ra,24(sp)
    80001318:	6442                	ld	s0,16(sp)
    8000131a:	64a2                	ld	s1,8(sp)
    8000131c:	6105                	add	sp,sp,32
    8000131e:	8082                	ret

0000000080001320 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001320:	715d                	add	sp,sp,-80
    80001322:	e486                	sd	ra,72(sp)
    80001324:	e0a2                	sd	s0,64(sp)
    80001326:	fc26                	sd	s1,56(sp)
    80001328:	f84a                	sd	s2,48(sp)
    8000132a:	f44e                	sd	s3,40(sp)
    8000132c:	f052                	sd	s4,32(sp)
    8000132e:	ec56                	sd	s5,24(sp)
    80001330:	e85a                	sd	s6,16(sp)
    80001332:	e45e                	sd	s7,8(sp)
    80001334:	0880                	add	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001336:	03459793          	sll	a5,a1,0x34
    8000133a:	e795                	bnez	a5,80001366 <uvmunmap+0x46>
    8000133c:	8a2a                	mv	s4,a0
    8000133e:	892e                	mv	s2,a1
    80001340:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001342:	0632                	sll	a2,a2,0xc
    80001344:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001348:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000134a:	6b05                	lui	s6,0x1
    8000134c:	0735e263          	bltu	a1,s3,800013b0 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001350:	60a6                	ld	ra,72(sp)
    80001352:	6406                	ld	s0,64(sp)
    80001354:	74e2                	ld	s1,56(sp)
    80001356:	7942                	ld	s2,48(sp)
    80001358:	79a2                	ld	s3,40(sp)
    8000135a:	7a02                	ld	s4,32(sp)
    8000135c:	6ae2                	ld	s5,24(sp)
    8000135e:	6b42                	ld	s6,16(sp)
    80001360:	6ba2                	ld	s7,8(sp)
    80001362:	6161                	add	sp,sp,80
    80001364:	8082                	ret
    panic("uvmunmap: not aligned");
    80001366:	00007517          	auipc	a0,0x7
    8000136a:	da250513          	add	a0,a0,-606 # 80008108 <digits+0xb0>
    8000136e:	fffff097          	auipc	ra,0xfffff
    80001372:	1d4080e7          	jalr	468(ra) # 80000542 <panic>
      panic("uvmunmap: walk");
    80001376:	00007517          	auipc	a0,0x7
    8000137a:	daa50513          	add	a0,a0,-598 # 80008120 <digits+0xc8>
    8000137e:	fffff097          	auipc	ra,0xfffff
    80001382:	1c4080e7          	jalr	452(ra) # 80000542 <panic>
      panic("uvmunmap: not mapped");
    80001386:	00007517          	auipc	a0,0x7
    8000138a:	daa50513          	add	a0,a0,-598 # 80008130 <digits+0xd8>
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	1b4080e7          	jalr	436(ra) # 80000542 <panic>
      panic("uvmunmap: not a leaf");
    80001396:	00007517          	auipc	a0,0x7
    8000139a:	db250513          	add	a0,a0,-590 # 80008148 <digits+0xf0>
    8000139e:	fffff097          	auipc	ra,0xfffff
    800013a2:	1a4080e7          	jalr	420(ra) # 80000542 <panic>
    *pte = 0;
    800013a6:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013aa:	995a                	add	s2,s2,s6
    800013ac:	fb3972e3          	bgeu	s2,s3,80001350 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013b0:	4601                	li	a2,0
    800013b2:	85ca                	mv	a1,s2
    800013b4:	8552                	mv	a0,s4
    800013b6:	00000097          	auipc	ra,0x0
    800013ba:	c8c080e7          	jalr	-884(ra) # 80001042 <walk>
    800013be:	84aa                	mv	s1,a0
    800013c0:	d95d                	beqz	a0,80001376 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013c2:	6108                	ld	a0,0(a0)
    800013c4:	00157793          	and	a5,a0,1
    800013c8:	dfdd                	beqz	a5,80001386 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013ca:	3ff57793          	and	a5,a0,1023
    800013ce:	fd7784e3          	beq	a5,s7,80001396 <uvmunmap+0x76>
    if(do_free){
    800013d2:	fc0a8ae3          	beqz	s5,800013a6 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800013d6:	8129                	srl	a0,a0,0xa
      kfree((void*)pa);
    800013d8:	0532                	sll	a0,a0,0xc
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	698080e7          	jalr	1688(ra) # 80000a72 <kfree>
    800013e2:	b7d1                	j	800013a6 <uvmunmap+0x86>

00000000800013e4 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013e4:	1101                	add	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	add	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013ee:	fffff097          	auipc	ra,0xfffff
    800013f2:	782080e7          	jalr	1922(ra) # 80000b70 <kalloc>
    800013f6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013f8:	c519                	beqz	a0,80001406 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013fa:	6605                	lui	a2,0x1
    800013fc:	4581                	li	a1,0
    800013fe:	00000097          	auipc	ra,0x0
    80001402:	95e080e7          	jalr	-1698(ra) # 80000d5c <memset>
  return pagetable;
}
    80001406:	8526                	mv	a0,s1
    80001408:	60e2                	ld	ra,24(sp)
    8000140a:	6442                	ld	s0,16(sp)
    8000140c:	64a2                	ld	s1,8(sp)
    8000140e:	6105                	add	sp,sp,32
    80001410:	8082                	ret

0000000080001412 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001412:	7179                	add	sp,sp,-48
    80001414:	f406                	sd	ra,40(sp)
    80001416:	f022                	sd	s0,32(sp)
    80001418:	ec26                	sd	s1,24(sp)
    8000141a:	e84a                	sd	s2,16(sp)
    8000141c:	e44e                	sd	s3,8(sp)
    8000141e:	e052                	sd	s4,0(sp)
    80001420:	1800                	add	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001422:	6785                	lui	a5,0x1
    80001424:	04f67863          	bgeu	a2,a5,80001474 <uvminit+0x62>
    80001428:	8a2a                	mv	s4,a0
    8000142a:	89ae                	mv	s3,a1
    8000142c:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000142e:	fffff097          	auipc	ra,0xfffff
    80001432:	742080e7          	jalr	1858(ra) # 80000b70 <kalloc>
    80001436:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001438:	6605                	lui	a2,0x1
    8000143a:	4581                	li	a1,0
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	920080e7          	jalr	-1760(ra) # 80000d5c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001444:	4779                	li	a4,30
    80001446:	86ca                	mv	a3,s2
    80001448:	6605                	lui	a2,0x1
    8000144a:	4581                	li	a1,0
    8000144c:	8552                	mv	a0,s4
    8000144e:	00000097          	auipc	ra,0x0
    80001452:	d3a080e7          	jalr	-710(ra) # 80001188 <mappages>
  memmove(mem, src, sz);
    80001456:	8626                	mv	a2,s1
    80001458:	85ce                	mv	a1,s3
    8000145a:	854a                	mv	a0,s2
    8000145c:	00000097          	auipc	ra,0x0
    80001460:	95c080e7          	jalr	-1700(ra) # 80000db8 <memmove>
}
    80001464:	70a2                	ld	ra,40(sp)
    80001466:	7402                	ld	s0,32(sp)
    80001468:	64e2                	ld	s1,24(sp)
    8000146a:	6942                	ld	s2,16(sp)
    8000146c:	69a2                	ld	s3,8(sp)
    8000146e:	6a02                	ld	s4,0(sp)
    80001470:	6145                	add	sp,sp,48
    80001472:	8082                	ret
    panic("inituvm: more than a page");
    80001474:	00007517          	auipc	a0,0x7
    80001478:	cec50513          	add	a0,a0,-788 # 80008160 <digits+0x108>
    8000147c:	fffff097          	auipc	ra,0xfffff
    80001480:	0c6080e7          	jalr	198(ra) # 80000542 <panic>

0000000080001484 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001484:	1101                	add	sp,sp,-32
    80001486:	ec06                	sd	ra,24(sp)
    80001488:	e822                	sd	s0,16(sp)
    8000148a:	e426                	sd	s1,8(sp)
    8000148c:	1000                	add	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000148e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001490:	00b67d63          	bgeu	a2,a1,800014aa <uvmdealloc+0x26>
    80001494:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001496:	6785                	lui	a5,0x1
    80001498:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000149a:	00f60733          	add	a4,a2,a5
    8000149e:	76fd                	lui	a3,0xfffff
    800014a0:	8f75                	and	a4,a4,a3
    800014a2:	97ae                	add	a5,a5,a1
    800014a4:	8ff5                	and	a5,a5,a3
    800014a6:	00f76863          	bltu	a4,a5,800014b6 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014aa:	8526                	mv	a0,s1
    800014ac:	60e2                	ld	ra,24(sp)
    800014ae:	6442                	ld	s0,16(sp)
    800014b0:	64a2                	ld	s1,8(sp)
    800014b2:	6105                	add	sp,sp,32
    800014b4:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014b6:	8f99                	sub	a5,a5,a4
    800014b8:	83b1                	srl	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014ba:	4685                	li	a3,1
    800014bc:	0007861b          	sext.w	a2,a5
    800014c0:	85ba                	mv	a1,a4
    800014c2:	00000097          	auipc	ra,0x0
    800014c6:	e5e080e7          	jalr	-418(ra) # 80001320 <uvmunmap>
    800014ca:	b7c5                	j	800014aa <uvmdealloc+0x26>

00000000800014cc <uvmalloc>:
  if(newsz < oldsz)
    800014cc:	0ab66163          	bltu	a2,a1,8000156e <uvmalloc+0xa2>
{
    800014d0:	7139                	add	sp,sp,-64
    800014d2:	fc06                	sd	ra,56(sp)
    800014d4:	f822                	sd	s0,48(sp)
    800014d6:	f426                	sd	s1,40(sp)
    800014d8:	f04a                	sd	s2,32(sp)
    800014da:	ec4e                	sd	s3,24(sp)
    800014dc:	e852                	sd	s4,16(sp)
    800014de:	e456                	sd	s5,8(sp)
    800014e0:	0080                	add	s0,sp,64
    800014e2:	8aaa                	mv	s5,a0
    800014e4:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014e6:	6785                	lui	a5,0x1
    800014e8:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014ea:	95be                	add	a1,a1,a5
    800014ec:	77fd                	lui	a5,0xfffff
    800014ee:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014f2:	08c9f063          	bgeu	s3,a2,80001572 <uvmalloc+0xa6>
    800014f6:	894e                	mv	s2,s3
    mem = kalloc();
    800014f8:	fffff097          	auipc	ra,0xfffff
    800014fc:	678080e7          	jalr	1656(ra) # 80000b70 <kalloc>
    80001500:	84aa                	mv	s1,a0
    if(mem == 0){
    80001502:	c51d                	beqz	a0,80001530 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001504:	6605                	lui	a2,0x1
    80001506:	4581                	li	a1,0
    80001508:	00000097          	auipc	ra,0x0
    8000150c:	854080e7          	jalr	-1964(ra) # 80000d5c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001510:	4779                	li	a4,30
    80001512:	86a6                	mv	a3,s1
    80001514:	6605                	lui	a2,0x1
    80001516:	85ca                	mv	a1,s2
    80001518:	8556                	mv	a0,s5
    8000151a:	00000097          	auipc	ra,0x0
    8000151e:	c6e080e7          	jalr	-914(ra) # 80001188 <mappages>
    80001522:	e905                	bnez	a0,80001552 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001524:	6785                	lui	a5,0x1
    80001526:	993e                	add	s2,s2,a5
    80001528:	fd4968e3          	bltu	s2,s4,800014f8 <uvmalloc+0x2c>
  return newsz;
    8000152c:	8552                	mv	a0,s4
    8000152e:	a809                	j	80001540 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001530:	864e                	mv	a2,s3
    80001532:	85ca                	mv	a1,s2
    80001534:	8556                	mv	a0,s5
    80001536:	00000097          	auipc	ra,0x0
    8000153a:	f4e080e7          	jalr	-178(ra) # 80001484 <uvmdealloc>
      return 0;
    8000153e:	4501                	li	a0,0
}
    80001540:	70e2                	ld	ra,56(sp)
    80001542:	7442                	ld	s0,48(sp)
    80001544:	74a2                	ld	s1,40(sp)
    80001546:	7902                	ld	s2,32(sp)
    80001548:	69e2                	ld	s3,24(sp)
    8000154a:	6a42                	ld	s4,16(sp)
    8000154c:	6aa2                	ld	s5,8(sp)
    8000154e:	6121                	add	sp,sp,64
    80001550:	8082                	ret
      kfree(mem);
    80001552:	8526                	mv	a0,s1
    80001554:	fffff097          	auipc	ra,0xfffff
    80001558:	51e080e7          	jalr	1310(ra) # 80000a72 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000155c:	864e                	mv	a2,s3
    8000155e:	85ca                	mv	a1,s2
    80001560:	8556                	mv	a0,s5
    80001562:	00000097          	auipc	ra,0x0
    80001566:	f22080e7          	jalr	-222(ra) # 80001484 <uvmdealloc>
      return 0;
    8000156a:	4501                	li	a0,0
    8000156c:	bfd1                	j	80001540 <uvmalloc+0x74>
    return oldsz;
    8000156e:	852e                	mv	a0,a1
}
    80001570:	8082                	ret
  return newsz;
    80001572:	8532                	mv	a0,a2
    80001574:	b7f1                	j	80001540 <uvmalloc+0x74>

0000000080001576 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001576:	7179                	add	sp,sp,-48
    80001578:	f406                	sd	ra,40(sp)
    8000157a:	f022                	sd	s0,32(sp)
    8000157c:	ec26                	sd	s1,24(sp)
    8000157e:	e84a                	sd	s2,16(sp)
    80001580:	e44e                	sd	s3,8(sp)
    80001582:	e052                	sd	s4,0(sp)
    80001584:	1800                	add	s0,sp,48
    80001586:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001588:	84aa                	mv	s1,a0
    8000158a:	6905                	lui	s2,0x1
    8000158c:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000158e:	4985                	li	s3,1
    80001590:	a829                	j	800015aa <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001592:	83a9                	srl	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001594:	00c79513          	sll	a0,a5,0xc
    80001598:	00000097          	auipc	ra,0x0
    8000159c:	fde080e7          	jalr	-34(ra) # 80001576 <freewalk>
      pagetable[i] = 0;
    800015a0:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015a4:	04a1                	add	s1,s1,8
    800015a6:	03248163          	beq	s1,s2,800015c8 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800015aa:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015ac:	00f7f713          	and	a4,a5,15
    800015b0:	ff3701e3          	beq	a4,s3,80001592 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015b4:	8b85                	and	a5,a5,1
    800015b6:	d7fd                	beqz	a5,800015a4 <freewalk+0x2e>
      panic("freewalk: leaf");
    800015b8:	00007517          	auipc	a0,0x7
    800015bc:	bc850513          	add	a0,a0,-1080 # 80008180 <digits+0x128>
    800015c0:	fffff097          	auipc	ra,0xfffff
    800015c4:	f82080e7          	jalr	-126(ra) # 80000542 <panic>
    }
  }
  kfree((void*)pagetable);
    800015c8:	8552                	mv	a0,s4
    800015ca:	fffff097          	auipc	ra,0xfffff
    800015ce:	4a8080e7          	jalr	1192(ra) # 80000a72 <kfree>
}
    800015d2:	70a2                	ld	ra,40(sp)
    800015d4:	7402                	ld	s0,32(sp)
    800015d6:	64e2                	ld	s1,24(sp)
    800015d8:	6942                	ld	s2,16(sp)
    800015da:	69a2                	ld	s3,8(sp)
    800015dc:	6a02                	ld	s4,0(sp)
    800015de:	6145                	add	sp,sp,48
    800015e0:	8082                	ret

00000000800015e2 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015e2:	1101                	add	sp,sp,-32
    800015e4:	ec06                	sd	ra,24(sp)
    800015e6:	e822                	sd	s0,16(sp)
    800015e8:	e426                	sd	s1,8(sp)
    800015ea:	1000                	add	s0,sp,32
    800015ec:	84aa                	mv	s1,a0
  if(sz > 0)
    800015ee:	e999                	bnez	a1,80001604 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015f0:	8526                	mv	a0,s1
    800015f2:	00000097          	auipc	ra,0x0
    800015f6:	f84080e7          	jalr	-124(ra) # 80001576 <freewalk>
}
    800015fa:	60e2                	ld	ra,24(sp)
    800015fc:	6442                	ld	s0,16(sp)
    800015fe:	64a2                	ld	s1,8(sp)
    80001600:	6105                	add	sp,sp,32
    80001602:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001604:	6785                	lui	a5,0x1
    80001606:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001608:	95be                	add	a1,a1,a5
    8000160a:	4685                	li	a3,1
    8000160c:	00c5d613          	srl	a2,a1,0xc
    80001610:	4581                	li	a1,0
    80001612:	00000097          	auipc	ra,0x0
    80001616:	d0e080e7          	jalr	-754(ra) # 80001320 <uvmunmap>
    8000161a:	bfd9                	j	800015f0 <uvmfree+0xe>

000000008000161c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000161c:	c679                	beqz	a2,800016ea <uvmcopy+0xce>
{
    8000161e:	715d                	add	sp,sp,-80
    80001620:	e486                	sd	ra,72(sp)
    80001622:	e0a2                	sd	s0,64(sp)
    80001624:	fc26                	sd	s1,56(sp)
    80001626:	f84a                	sd	s2,48(sp)
    80001628:	f44e                	sd	s3,40(sp)
    8000162a:	f052                	sd	s4,32(sp)
    8000162c:	ec56                	sd	s5,24(sp)
    8000162e:	e85a                	sd	s6,16(sp)
    80001630:	e45e                	sd	s7,8(sp)
    80001632:	0880                	add	s0,sp,80
    80001634:	8b2a                	mv	s6,a0
    80001636:	8aae                	mv	s5,a1
    80001638:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000163a:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000163c:	4601                	li	a2,0
    8000163e:	85ce                	mv	a1,s3
    80001640:	855a                	mv	a0,s6
    80001642:	00000097          	auipc	ra,0x0
    80001646:	a00080e7          	jalr	-1536(ra) # 80001042 <walk>
    8000164a:	c531                	beqz	a0,80001696 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000164c:	6118                	ld	a4,0(a0)
    8000164e:	00177793          	and	a5,a4,1
    80001652:	cbb1                	beqz	a5,800016a6 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001654:	00a75593          	srl	a1,a4,0xa
    80001658:	00c59b93          	sll	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000165c:	3ff77493          	and	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	510080e7          	jalr	1296(ra) # 80000b70 <kalloc>
    80001668:	892a                	mv	s2,a0
    8000166a:	c939                	beqz	a0,800016c0 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000166c:	6605                	lui	a2,0x1
    8000166e:	85de                	mv	a1,s7
    80001670:	fffff097          	auipc	ra,0xfffff
    80001674:	748080e7          	jalr	1864(ra) # 80000db8 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001678:	8726                	mv	a4,s1
    8000167a:	86ca                	mv	a3,s2
    8000167c:	6605                	lui	a2,0x1
    8000167e:	85ce                	mv	a1,s3
    80001680:	8556                	mv	a0,s5
    80001682:	00000097          	auipc	ra,0x0
    80001686:	b06080e7          	jalr	-1274(ra) # 80001188 <mappages>
    8000168a:	e515                	bnez	a0,800016b6 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000168c:	6785                	lui	a5,0x1
    8000168e:	99be                	add	s3,s3,a5
    80001690:	fb49e6e3          	bltu	s3,s4,8000163c <uvmcopy+0x20>
    80001694:	a081                	j	800016d4 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001696:	00007517          	auipc	a0,0x7
    8000169a:	afa50513          	add	a0,a0,-1286 # 80008190 <digits+0x138>
    8000169e:	fffff097          	auipc	ra,0xfffff
    800016a2:	ea4080e7          	jalr	-348(ra) # 80000542 <panic>
      panic("uvmcopy: page not present");
    800016a6:	00007517          	auipc	a0,0x7
    800016aa:	b0a50513          	add	a0,a0,-1270 # 800081b0 <digits+0x158>
    800016ae:	fffff097          	auipc	ra,0xfffff
    800016b2:	e94080e7          	jalr	-364(ra) # 80000542 <panic>
      kfree(mem);
    800016b6:	854a                	mv	a0,s2
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	3ba080e7          	jalr	954(ra) # 80000a72 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016c0:	4685                	li	a3,1
    800016c2:	00c9d613          	srl	a2,s3,0xc
    800016c6:	4581                	li	a1,0
    800016c8:	8556                	mv	a0,s5
    800016ca:	00000097          	auipc	ra,0x0
    800016ce:	c56080e7          	jalr	-938(ra) # 80001320 <uvmunmap>
  return -1;
    800016d2:	557d                	li	a0,-1
}
    800016d4:	60a6                	ld	ra,72(sp)
    800016d6:	6406                	ld	s0,64(sp)
    800016d8:	74e2                	ld	s1,56(sp)
    800016da:	7942                	ld	s2,48(sp)
    800016dc:	79a2                	ld	s3,40(sp)
    800016de:	7a02                	ld	s4,32(sp)
    800016e0:	6ae2                	ld	s5,24(sp)
    800016e2:	6b42                	ld	s6,16(sp)
    800016e4:	6ba2                	ld	s7,8(sp)
    800016e6:	6161                	add	sp,sp,80
    800016e8:	8082                	ret
  return 0;
    800016ea:	4501                	li	a0,0
}
    800016ec:	8082                	ret

00000000800016ee <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016ee:	1141                	add	sp,sp,-16
    800016f0:	e406                	sd	ra,8(sp)
    800016f2:	e022                	sd	s0,0(sp)
    800016f4:	0800                	add	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016f6:	4601                	li	a2,0
    800016f8:	00000097          	auipc	ra,0x0
    800016fc:	94a080e7          	jalr	-1718(ra) # 80001042 <walk>
  if(pte == 0)
    80001700:	c901                	beqz	a0,80001710 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001702:	611c                	ld	a5,0(a0)
    80001704:	9bbd                	and	a5,a5,-17
    80001706:	e11c                	sd	a5,0(a0)
}
    80001708:	60a2                	ld	ra,8(sp)
    8000170a:	6402                	ld	s0,0(sp)
    8000170c:	0141                	add	sp,sp,16
    8000170e:	8082                	ret
    panic("uvmclear");
    80001710:	00007517          	auipc	a0,0x7
    80001714:	ac050513          	add	a0,a0,-1344 # 800081d0 <digits+0x178>
    80001718:	fffff097          	auipc	ra,0xfffff
    8000171c:	e2a080e7          	jalr	-470(ra) # 80000542 <panic>

0000000080001720 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001720:	c6bd                	beqz	a3,8000178e <copyout+0x6e>
{
    80001722:	715d                	add	sp,sp,-80
    80001724:	e486                	sd	ra,72(sp)
    80001726:	e0a2                	sd	s0,64(sp)
    80001728:	fc26                	sd	s1,56(sp)
    8000172a:	f84a                	sd	s2,48(sp)
    8000172c:	f44e                	sd	s3,40(sp)
    8000172e:	f052                	sd	s4,32(sp)
    80001730:	ec56                	sd	s5,24(sp)
    80001732:	e85a                	sd	s6,16(sp)
    80001734:	e45e                	sd	s7,8(sp)
    80001736:	e062                	sd	s8,0(sp)
    80001738:	0880                	add	s0,sp,80
    8000173a:	8b2a                	mv	s6,a0
    8000173c:	8c2e                	mv	s8,a1
    8000173e:	8a32                	mv	s4,a2
    80001740:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001742:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001744:	6a85                	lui	s5,0x1
    80001746:	a015                	j	8000176a <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001748:	9562                	add	a0,a0,s8
    8000174a:	0004861b          	sext.w	a2,s1
    8000174e:	85d2                	mv	a1,s4
    80001750:	41250533          	sub	a0,a0,s2
    80001754:	fffff097          	auipc	ra,0xfffff
    80001758:	664080e7          	jalr	1636(ra) # 80000db8 <memmove>

    len -= n;
    8000175c:	409989b3          	sub	s3,s3,s1
    src += n;
    80001760:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001762:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001766:	02098263          	beqz	s3,8000178a <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000176a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000176e:	85ca                	mv	a1,s2
    80001770:	855a                	mv	a0,s6
    80001772:	00000097          	auipc	ra,0x0
    80001776:	976080e7          	jalr	-1674(ra) # 800010e8 <walkaddr>
    if(pa0 == 0)
    8000177a:	cd01                	beqz	a0,80001792 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000177c:	418904b3          	sub	s1,s2,s8
    80001780:	94d6                	add	s1,s1,s5
    80001782:	fc99f3e3          	bgeu	s3,s1,80001748 <copyout+0x28>
    80001786:	84ce                	mv	s1,s3
    80001788:	b7c1                	j	80001748 <copyout+0x28>
  }
  return 0;
    8000178a:	4501                	li	a0,0
    8000178c:	a021                	j	80001794 <copyout+0x74>
    8000178e:	4501                	li	a0,0
}
    80001790:	8082                	ret
      return -1;
    80001792:	557d                	li	a0,-1
}
    80001794:	60a6                	ld	ra,72(sp)
    80001796:	6406                	ld	s0,64(sp)
    80001798:	74e2                	ld	s1,56(sp)
    8000179a:	7942                	ld	s2,48(sp)
    8000179c:	79a2                	ld	s3,40(sp)
    8000179e:	7a02                	ld	s4,32(sp)
    800017a0:	6ae2                	ld	s5,24(sp)
    800017a2:	6b42                	ld	s6,16(sp)
    800017a4:	6ba2                	ld	s7,8(sp)
    800017a6:	6c02                	ld	s8,0(sp)
    800017a8:	6161                	add	sp,sp,80
    800017aa:	8082                	ret

00000000800017ac <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017ac:	caa5                	beqz	a3,8000181c <copyin+0x70>
{
    800017ae:	715d                	add	sp,sp,-80
    800017b0:	e486                	sd	ra,72(sp)
    800017b2:	e0a2                	sd	s0,64(sp)
    800017b4:	fc26                	sd	s1,56(sp)
    800017b6:	f84a                	sd	s2,48(sp)
    800017b8:	f44e                	sd	s3,40(sp)
    800017ba:	f052                	sd	s4,32(sp)
    800017bc:	ec56                	sd	s5,24(sp)
    800017be:	e85a                	sd	s6,16(sp)
    800017c0:	e45e                	sd	s7,8(sp)
    800017c2:	e062                	sd	s8,0(sp)
    800017c4:	0880                	add	s0,sp,80
    800017c6:	8b2a                	mv	s6,a0
    800017c8:	8a2e                	mv	s4,a1
    800017ca:	8c32                	mv	s8,a2
    800017cc:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017ce:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017d0:	6a85                	lui	s5,0x1
    800017d2:	a01d                	j	800017f8 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017d4:	018505b3          	add	a1,a0,s8
    800017d8:	0004861b          	sext.w	a2,s1
    800017dc:	412585b3          	sub	a1,a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	fffff097          	auipc	ra,0xfffff
    800017e6:	5d6080e7          	jalr	1494(ra) # 80000db8 <memmove>

    len -= n;
    800017ea:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017ee:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017f0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017f4:	02098263          	beqz	s3,80001818 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017f8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017fc:	85ca                	mv	a1,s2
    800017fe:	855a                	mv	a0,s6
    80001800:	00000097          	auipc	ra,0x0
    80001804:	8e8080e7          	jalr	-1816(ra) # 800010e8 <walkaddr>
    if(pa0 == 0)
    80001808:	cd01                	beqz	a0,80001820 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000180a:	418904b3          	sub	s1,s2,s8
    8000180e:	94d6                	add	s1,s1,s5
    80001810:	fc99f2e3          	bgeu	s3,s1,800017d4 <copyin+0x28>
    80001814:	84ce                	mv	s1,s3
    80001816:	bf7d                	j	800017d4 <copyin+0x28>
  }
  return 0;
    80001818:	4501                	li	a0,0
    8000181a:	a021                	j	80001822 <copyin+0x76>
    8000181c:	4501                	li	a0,0
}
    8000181e:	8082                	ret
      return -1;
    80001820:	557d                	li	a0,-1
}
    80001822:	60a6                	ld	ra,72(sp)
    80001824:	6406                	ld	s0,64(sp)
    80001826:	74e2                	ld	s1,56(sp)
    80001828:	7942                	ld	s2,48(sp)
    8000182a:	79a2                	ld	s3,40(sp)
    8000182c:	7a02                	ld	s4,32(sp)
    8000182e:	6ae2                	ld	s5,24(sp)
    80001830:	6b42                	ld	s6,16(sp)
    80001832:	6ba2                	ld	s7,8(sp)
    80001834:	6c02                	ld	s8,0(sp)
    80001836:	6161                	add	sp,sp,80
    80001838:	8082                	ret

000000008000183a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000183a:	c2dd                	beqz	a3,800018e0 <copyinstr+0xa6>
{
    8000183c:	715d                	add	sp,sp,-80
    8000183e:	e486                	sd	ra,72(sp)
    80001840:	e0a2                	sd	s0,64(sp)
    80001842:	fc26                	sd	s1,56(sp)
    80001844:	f84a                	sd	s2,48(sp)
    80001846:	f44e                	sd	s3,40(sp)
    80001848:	f052                	sd	s4,32(sp)
    8000184a:	ec56                	sd	s5,24(sp)
    8000184c:	e85a                	sd	s6,16(sp)
    8000184e:	e45e                	sd	s7,8(sp)
    80001850:	0880                	add	s0,sp,80
    80001852:	8a2a                	mv	s4,a0
    80001854:	8b2e                	mv	s6,a1
    80001856:	8bb2                	mv	s7,a2
    80001858:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000185a:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000185c:	6985                	lui	s3,0x1
    8000185e:	a02d                	j	80001888 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001860:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001864:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001866:	37fd                	addw	a5,a5,-1
    80001868:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000186c:	60a6                	ld	ra,72(sp)
    8000186e:	6406                	ld	s0,64(sp)
    80001870:	74e2                	ld	s1,56(sp)
    80001872:	7942                	ld	s2,48(sp)
    80001874:	79a2                	ld	s3,40(sp)
    80001876:	7a02                	ld	s4,32(sp)
    80001878:	6ae2                	ld	s5,24(sp)
    8000187a:	6b42                	ld	s6,16(sp)
    8000187c:	6ba2                	ld	s7,8(sp)
    8000187e:	6161                	add	sp,sp,80
    80001880:	8082                	ret
    srcva = va0 + PGSIZE;
    80001882:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001886:	c8a9                	beqz	s1,800018d8 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001888:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000188c:	85ca                	mv	a1,s2
    8000188e:	8552                	mv	a0,s4
    80001890:	00000097          	auipc	ra,0x0
    80001894:	858080e7          	jalr	-1960(ra) # 800010e8 <walkaddr>
    if(pa0 == 0)
    80001898:	c131                	beqz	a0,800018dc <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    8000189a:	417906b3          	sub	a3,s2,s7
    8000189e:	96ce                	add	a3,a3,s3
    800018a0:	00d4f363          	bgeu	s1,a3,800018a6 <copyinstr+0x6c>
    800018a4:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018a6:	955e                	add	a0,a0,s7
    800018a8:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018ac:	daf9                	beqz	a3,80001882 <copyinstr+0x48>
    800018ae:	87da                	mv	a5,s6
    800018b0:	885a                	mv	a6,s6
      if(*p == '\0'){
    800018b2:	41650633          	sub	a2,a0,s6
    while(n > 0){
    800018b6:	96da                	add	a3,a3,s6
    800018b8:	85be                	mv	a1,a5
      if(*p == '\0'){
    800018ba:	00f60733          	add	a4,a2,a5
    800018be:	00074703          	lbu	a4,0(a4)
    800018c2:	df59                	beqz	a4,80001860 <copyinstr+0x26>
        *dst = *p;
    800018c4:	00e78023          	sb	a4,0(a5)
      dst++;
    800018c8:	0785                	add	a5,a5,1
    while(n > 0){
    800018ca:	fed797e3          	bne	a5,a3,800018b8 <copyinstr+0x7e>
    800018ce:	14fd                	add	s1,s1,-1
    800018d0:	94c2                	add	s1,s1,a6
      --max;
    800018d2:	8c8d                	sub	s1,s1,a1
      dst++;
    800018d4:	8b3e                	mv	s6,a5
    800018d6:	b775                	j	80001882 <copyinstr+0x48>
    800018d8:	4781                	li	a5,0
    800018da:	b771                	j	80001866 <copyinstr+0x2c>
      return -1;
    800018dc:	557d                	li	a0,-1
    800018de:	b779                	j	8000186c <copyinstr+0x32>
  int got_null = 0;
    800018e0:	4781                	li	a5,0
  if(got_null){
    800018e2:	37fd                	addw	a5,a5,-1
    800018e4:	0007851b          	sext.w	a0,a5
}
    800018e8:	8082                	ret

00000000800018ea <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018ea:	1101                	add	sp,sp,-32
    800018ec:	ec06                	sd	ra,24(sp)
    800018ee:	e822                	sd	s0,16(sp)
    800018f0:	e426                	sd	s1,8(sp)
    800018f2:	1000                	add	s0,sp,32
    800018f4:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018f6:	fffff097          	auipc	ra,0xfffff
    800018fa:	2f0080e7          	jalr	752(ra) # 80000be6 <holding>
    800018fe:	c909                	beqz	a0,80001910 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001900:	749c                	ld	a5,40(s1)
    80001902:	00978f63          	beq	a5,s1,80001920 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001906:	60e2                	ld	ra,24(sp)
    80001908:	6442                	ld	s0,16(sp)
    8000190a:	64a2                	ld	s1,8(sp)
    8000190c:	6105                	add	sp,sp,32
    8000190e:	8082                	ret
    panic("wakeup1");
    80001910:	00007517          	auipc	a0,0x7
    80001914:	8d050513          	add	a0,a0,-1840 # 800081e0 <digits+0x188>
    80001918:	fffff097          	auipc	ra,0xfffff
    8000191c:	c2a080e7          	jalr	-982(ra) # 80000542 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001920:	4c98                	lw	a4,24(s1)
    80001922:	4785                	li	a5,1
    80001924:	fef711e3          	bne	a4,a5,80001906 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001928:	4789                	li	a5,2
    8000192a:	cc9c                	sw	a5,24(s1)
}
    8000192c:	bfe9                	j	80001906 <wakeup1+0x1c>

000000008000192e <procinit>:
{
    8000192e:	715d                	add	sp,sp,-80
    80001930:	e486                	sd	ra,72(sp)
    80001932:	e0a2                	sd	s0,64(sp)
    80001934:	fc26                	sd	s1,56(sp)
    80001936:	f84a                	sd	s2,48(sp)
    80001938:	f44e                	sd	s3,40(sp)
    8000193a:	f052                	sd	s4,32(sp)
    8000193c:	ec56                	sd	s5,24(sp)
    8000193e:	e85a                	sd	s6,16(sp)
    80001940:	e45e                	sd	s7,8(sp)
    80001942:	0880                	add	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001944:	00007597          	auipc	a1,0x7
    80001948:	8a458593          	add	a1,a1,-1884 # 800081e8 <digits+0x190>
    8000194c:	00010517          	auipc	a0,0x10
    80001950:	00450513          	add	a0,a0,4 # 80011950 <pid_lock>
    80001954:	fffff097          	auipc	ra,0xfffff
    80001958:	27c080e7          	jalr	636(ra) # 80000bd0 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195c:	00010917          	auipc	s2,0x10
    80001960:	40c90913          	add	s2,s2,1036 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001964:	00007b97          	auipc	s7,0x7
    80001968:	88cb8b93          	add	s7,s7,-1908 # 800081f0 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    8000196c:	8b4a                	mv	s6,s2
    8000196e:	00006a97          	auipc	s5,0x6
    80001972:	692a8a93          	add	s5,s5,1682 # 80008000 <etext>
    80001976:	040009b7          	lui	s3,0x4000
    8000197a:	19fd                	add	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    8000197c:	09b2                	sll	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197e:	00016a17          	auipc	s4,0x16
    80001982:	5eaa0a13          	add	s4,s4,1514 # 80017f68 <tickslock>
      initlock(&p->lock, "proc");
    80001986:	85de                	mv	a1,s7
    80001988:	854a                	mv	a0,s2
    8000198a:	fffff097          	auipc	ra,0xfffff
    8000198e:	246080e7          	jalr	582(ra) # 80000bd0 <initlock>
      char *pa = kalloc();
    80001992:	fffff097          	auipc	ra,0xfffff
    80001996:	1de080e7          	jalr	478(ra) # 80000b70 <kalloc>
    8000199a:	85aa                	mv	a1,a0
      if(pa == 0)
    8000199c:	c929                	beqz	a0,800019ee <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    8000199e:	416904b3          	sub	s1,s2,s6
    800019a2:	848d                	sra	s1,s1,0x3
    800019a4:	000ab783          	ld	a5,0(s5)
    800019a8:	02f484b3          	mul	s1,s1,a5
    800019ac:	2485                	addw	s1,s1,1
    800019ae:	00d4949b          	sllw	s1,s1,0xd
    800019b2:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019b6:	4699                	li	a3,6
    800019b8:	6605                	lui	a2,0x1
    800019ba:	8526                	mv	a0,s1
    800019bc:	00000097          	auipc	ra,0x0
    800019c0:	85a080e7          	jalr	-1958(ra) # 80001216 <kvmmap>
      p->kstack = va;
    800019c4:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c8:	18890913          	add	s2,s2,392
    800019cc:	fb491de3          	bne	s2,s4,80001986 <procinit+0x58>
  kvminithart();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	64e080e7          	jalr	1614(ra) # 8000101e <kvminithart>
}
    800019d8:	60a6                	ld	ra,72(sp)
    800019da:	6406                	ld	s0,64(sp)
    800019dc:	74e2                	ld	s1,56(sp)
    800019de:	7942                	ld	s2,48(sp)
    800019e0:	79a2                	ld	s3,40(sp)
    800019e2:	7a02                	ld	s4,32(sp)
    800019e4:	6ae2                	ld	s5,24(sp)
    800019e6:	6b42                	ld	s6,16(sp)
    800019e8:	6ba2                	ld	s7,8(sp)
    800019ea:	6161                	add	sp,sp,80
    800019ec:	8082                	ret
        panic("kalloc");
    800019ee:	00007517          	auipc	a0,0x7
    800019f2:	80a50513          	add	a0,a0,-2038 # 800081f8 <digits+0x1a0>
    800019f6:	fffff097          	auipc	ra,0xfffff
    800019fa:	b4c080e7          	jalr	-1204(ra) # 80000542 <panic>

00000000800019fe <cpuid>:
{
    800019fe:	1141                	add	sp,sp,-16
    80001a00:	e422                	sd	s0,8(sp)
    80001a02:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a04:	8512                	mv	a0,tp
}
    80001a06:	2501                	sext.w	a0,a0
    80001a08:	6422                	ld	s0,8(sp)
    80001a0a:	0141                	add	sp,sp,16
    80001a0c:	8082                	ret

0000000080001a0e <mycpu>:
mycpu(void) {
    80001a0e:	1141                	add	sp,sp,-16
    80001a10:	e422                	sd	s0,8(sp)
    80001a12:	0800                	add	s0,sp,16
    80001a14:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a16:	2781                	sext.w	a5,a5
    80001a18:	079e                	sll	a5,a5,0x7
}
    80001a1a:	00010517          	auipc	a0,0x10
    80001a1e:	f4e50513          	add	a0,a0,-178 # 80011968 <cpus>
    80001a22:	953e                	add	a0,a0,a5
    80001a24:	6422                	ld	s0,8(sp)
    80001a26:	0141                	add	sp,sp,16
    80001a28:	8082                	ret

0000000080001a2a <myproc>:
myproc(void) {
    80001a2a:	1101                	add	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	1000                	add	s0,sp,32
  push_off();
    80001a34:	fffff097          	auipc	ra,0xfffff
    80001a38:	1e0080e7          	jalr	480(ra) # 80000c14 <push_off>
    80001a3c:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a3e:	2781                	sext.w	a5,a5
    80001a40:	079e                	sll	a5,a5,0x7
    80001a42:	00010717          	auipc	a4,0x10
    80001a46:	f0e70713          	add	a4,a4,-242 # 80011950 <pid_lock>
    80001a4a:	97ba                	add	a5,a5,a4
    80001a4c:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a4e:	fffff097          	auipc	ra,0xfffff
    80001a52:	266080e7          	jalr	614(ra) # 80000cb4 <pop_off>
}
    80001a56:	8526                	mv	a0,s1
    80001a58:	60e2                	ld	ra,24(sp)
    80001a5a:	6442                	ld	s0,16(sp)
    80001a5c:	64a2                	ld	s1,8(sp)
    80001a5e:	6105                	add	sp,sp,32
    80001a60:	8082                	ret

0000000080001a62 <forkret>:
{
    80001a62:	1141                	add	sp,sp,-16
    80001a64:	e406                	sd	ra,8(sp)
    80001a66:	e022                	sd	s0,0(sp)
    80001a68:	0800                	add	s0,sp,16
  release(&myproc()->lock);
    80001a6a:	00000097          	auipc	ra,0x0
    80001a6e:	fc0080e7          	jalr	-64(ra) # 80001a2a <myproc>
    80001a72:	fffff097          	auipc	ra,0xfffff
    80001a76:	2a2080e7          	jalr	674(ra) # 80000d14 <release>
  if (first) {
    80001a7a:	00007797          	auipc	a5,0x7
    80001a7e:	dc67a783          	lw	a5,-570(a5) # 80008840 <first.1>
    80001a82:	eb89                	bnez	a5,80001a94 <forkret+0x32>
  usertrapret();
    80001a84:	00001097          	auipc	ra,0x1
    80001a88:	c36080e7          	jalr	-970(ra) # 800026ba <usertrapret>
}
    80001a8c:	60a2                	ld	ra,8(sp)
    80001a8e:	6402                	ld	s0,0(sp)
    80001a90:	0141                	add	sp,sp,16
    80001a92:	8082                	ret
    first = 0;
    80001a94:	00007797          	auipc	a5,0x7
    80001a98:	da07a623          	sw	zero,-596(a5) # 80008840 <first.1>
    fsinit(ROOTDEV);
    80001a9c:	4505                	li	a0,1
    80001a9e:	00002097          	auipc	ra,0x2
    80001aa2:	a4a080e7          	jalr	-1462(ra) # 800034e8 <fsinit>
    80001aa6:	bff9                	j	80001a84 <forkret+0x22>

0000000080001aa8 <allocpid>:
allocpid() {
    80001aa8:	1101                	add	sp,sp,-32
    80001aaa:	ec06                	sd	ra,24(sp)
    80001aac:	e822                	sd	s0,16(sp)
    80001aae:	e426                	sd	s1,8(sp)
    80001ab0:	e04a                	sd	s2,0(sp)
    80001ab2:	1000                	add	s0,sp,32
  acquire(&pid_lock);
    80001ab4:	00010917          	auipc	s2,0x10
    80001ab8:	e9c90913          	add	s2,s2,-356 # 80011950 <pid_lock>
    80001abc:	854a                	mv	a0,s2
    80001abe:	fffff097          	auipc	ra,0xfffff
    80001ac2:	1a2080e7          	jalr	418(ra) # 80000c60 <acquire>
  pid = nextpid;
    80001ac6:	00007797          	auipc	a5,0x7
    80001aca:	d7e78793          	add	a5,a5,-642 # 80008844 <nextpid>
    80001ace:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ad0:	0014871b          	addw	a4,s1,1
    80001ad4:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ad6:	854a                	mv	a0,s2
    80001ad8:	fffff097          	auipc	ra,0xfffff
    80001adc:	23c080e7          	jalr	572(ra) # 80000d14 <release>
}
    80001ae0:	8526                	mv	a0,s1
    80001ae2:	60e2                	ld	ra,24(sp)
    80001ae4:	6442                	ld	s0,16(sp)
    80001ae6:	64a2                	ld	s1,8(sp)
    80001ae8:	6902                	ld	s2,0(sp)
    80001aea:	6105                	add	sp,sp,32
    80001aec:	8082                	ret

0000000080001aee <proc_pagetable>:
{
    80001aee:	1101                	add	sp,sp,-32
    80001af0:	ec06                	sd	ra,24(sp)
    80001af2:	e822                	sd	s0,16(sp)
    80001af4:	e426                	sd	s1,8(sp)
    80001af6:	e04a                	sd	s2,0(sp)
    80001af8:	1000                	add	s0,sp,32
    80001afa:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001afc:	00000097          	auipc	ra,0x0
    80001b00:	8e8080e7          	jalr	-1816(ra) # 800013e4 <uvmcreate>
    80001b04:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b06:	c121                	beqz	a0,80001b46 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b08:	4729                	li	a4,10
    80001b0a:	00005697          	auipc	a3,0x5
    80001b0e:	4f668693          	add	a3,a3,1270 # 80007000 <_trampoline>
    80001b12:	6605                	lui	a2,0x1
    80001b14:	040005b7          	lui	a1,0x4000
    80001b18:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b1a:	05b2                	sll	a1,a1,0xc
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	66c080e7          	jalr	1644(ra) # 80001188 <mappages>
    80001b24:	02054863          	bltz	a0,80001b54 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b28:	4719                	li	a4,6
    80001b2a:	05893683          	ld	a3,88(s2)
    80001b2e:	6605                	lui	a2,0x1
    80001b30:	020005b7          	lui	a1,0x2000
    80001b34:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b36:	05b6                	sll	a1,a1,0xd
    80001b38:	8526                	mv	a0,s1
    80001b3a:	fffff097          	auipc	ra,0xfffff
    80001b3e:	64e080e7          	jalr	1614(ra) # 80001188 <mappages>
    80001b42:	02054163          	bltz	a0,80001b64 <proc_pagetable+0x76>
}
    80001b46:	8526                	mv	a0,s1
    80001b48:	60e2                	ld	ra,24(sp)
    80001b4a:	6442                	ld	s0,16(sp)
    80001b4c:	64a2                	ld	s1,8(sp)
    80001b4e:	6902                	ld	s2,0(sp)
    80001b50:	6105                	add	sp,sp,32
    80001b52:	8082                	ret
    uvmfree(pagetable, 0);
    80001b54:	4581                	li	a1,0
    80001b56:	8526                	mv	a0,s1
    80001b58:	00000097          	auipc	ra,0x0
    80001b5c:	a8a080e7          	jalr	-1398(ra) # 800015e2 <uvmfree>
    return 0;
    80001b60:	4481                	li	s1,0
    80001b62:	b7d5                	j	80001b46 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b64:	4681                	li	a3,0
    80001b66:	4605                	li	a2,1
    80001b68:	040005b7          	lui	a1,0x4000
    80001b6c:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b6e:	05b2                	sll	a1,a1,0xc
    80001b70:	8526                	mv	a0,s1
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	7ae080e7          	jalr	1966(ra) # 80001320 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b7a:	4581                	li	a1,0
    80001b7c:	8526                	mv	a0,s1
    80001b7e:	00000097          	auipc	ra,0x0
    80001b82:	a64080e7          	jalr	-1436(ra) # 800015e2 <uvmfree>
    return 0;
    80001b86:	4481                	li	s1,0
    80001b88:	bf7d                	j	80001b46 <proc_pagetable+0x58>

0000000080001b8a <proc_freepagetable>:
{
    80001b8a:	1101                	add	sp,sp,-32
    80001b8c:	ec06                	sd	ra,24(sp)
    80001b8e:	e822                	sd	s0,16(sp)
    80001b90:	e426                	sd	s1,8(sp)
    80001b92:	e04a                	sd	s2,0(sp)
    80001b94:	1000                	add	s0,sp,32
    80001b96:	84aa                	mv	s1,a0
    80001b98:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b9a:	4681                	li	a3,0
    80001b9c:	4605                	li	a2,1
    80001b9e:	040005b7          	lui	a1,0x4000
    80001ba2:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ba4:	05b2                	sll	a1,a1,0xc
    80001ba6:	fffff097          	auipc	ra,0xfffff
    80001baa:	77a080e7          	jalr	1914(ra) # 80001320 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bae:	4681                	li	a3,0
    80001bb0:	4605                	li	a2,1
    80001bb2:	020005b7          	lui	a1,0x2000
    80001bb6:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bb8:	05b6                	sll	a1,a1,0xd
    80001bba:	8526                	mv	a0,s1
    80001bbc:	fffff097          	auipc	ra,0xfffff
    80001bc0:	764080e7          	jalr	1892(ra) # 80001320 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bc4:	85ca                	mv	a1,s2
    80001bc6:	8526                	mv	a0,s1
    80001bc8:	00000097          	auipc	ra,0x0
    80001bcc:	a1a080e7          	jalr	-1510(ra) # 800015e2 <uvmfree>
}
    80001bd0:	60e2                	ld	ra,24(sp)
    80001bd2:	6442                	ld	s0,16(sp)
    80001bd4:	64a2                	ld	s1,8(sp)
    80001bd6:	6902                	ld	s2,0(sp)
    80001bd8:	6105                	add	sp,sp,32
    80001bda:	8082                	ret

0000000080001bdc <freeproc>:
{
    80001bdc:	1101                	add	sp,sp,-32
    80001bde:	ec06                	sd	ra,24(sp)
    80001be0:	e822                	sd	s0,16(sp)
    80001be2:	e426                	sd	s1,8(sp)
    80001be4:	1000                	add	s0,sp,32
    80001be6:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001be8:	6d28                	ld	a0,88(a0)
    80001bea:	c509                	beqz	a0,80001bf4 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bec:	fffff097          	auipc	ra,0xfffff
    80001bf0:	e86080e7          	jalr	-378(ra) # 80000a72 <kfree>
  p->trapframe = 0;
    80001bf4:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bf8:	68a8                	ld	a0,80(s1)
    80001bfa:	c511                	beqz	a0,80001c06 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bfc:	64ac                	ld	a1,72(s1)
    80001bfe:	00000097          	auipc	ra,0x0
    80001c02:	f8c080e7          	jalr	-116(ra) # 80001b8a <proc_freepagetable>
  p->pagetable = 0;
    80001c06:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c0a:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c0e:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c12:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c16:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c1a:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c1e:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c22:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c26:	0004ac23          	sw	zero,24(s1)
  p->interval = 0;
    80001c2a:	1604a423          	sw	zero,360(s1)
  p->handler = 0;
    80001c2e:	1604b823          	sd	zero,368(s1)
  p->ticks = 0;
    80001c32:	1604ac23          	sw	zero,376(s1)
}
    80001c36:	60e2                	ld	ra,24(sp)
    80001c38:	6442                	ld	s0,16(sp)
    80001c3a:	64a2                	ld	s1,8(sp)
    80001c3c:	6105                	add	sp,sp,32
    80001c3e:	8082                	ret

0000000080001c40 <allocproc>:
{
    80001c40:	1101                	add	sp,sp,-32
    80001c42:	ec06                	sd	ra,24(sp)
    80001c44:	e822                	sd	s0,16(sp)
    80001c46:	e426                	sd	s1,8(sp)
    80001c48:	e04a                	sd	s2,0(sp)
    80001c4a:	1000                	add	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c4c:	00010497          	auipc	s1,0x10
    80001c50:	11c48493          	add	s1,s1,284 # 80011d68 <proc>
    80001c54:	00016917          	auipc	s2,0x16
    80001c58:	31490913          	add	s2,s2,788 # 80017f68 <tickslock>
    acquire(&p->lock);
    80001c5c:	8526                	mv	a0,s1
    80001c5e:	fffff097          	auipc	ra,0xfffff
    80001c62:	002080e7          	jalr	2(ra) # 80000c60 <acquire>
    if(p->state == UNUSED) {
    80001c66:	4c9c                	lw	a5,24(s1)
    80001c68:	cf81                	beqz	a5,80001c80 <allocproc+0x40>
      release(&p->lock);
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	fffff097          	auipc	ra,0xfffff
    80001c70:	0a8080e7          	jalr	168(ra) # 80000d14 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c74:	18848493          	add	s1,s1,392
    80001c78:	ff2492e3          	bne	s1,s2,80001c5c <allocproc+0x1c>
  return 0;
    80001c7c:	4481                	li	s1,0
    80001c7e:	a8b9                	j	80001cdc <allocproc+0x9c>
  p->pid = allocpid();
    80001c80:	00000097          	auipc	ra,0x0
    80001c84:	e28080e7          	jalr	-472(ra) # 80001aa8 <allocpid>
    80001c88:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c8a:	fffff097          	auipc	ra,0xfffff
    80001c8e:	ee6080e7          	jalr	-282(ra) # 80000b70 <kalloc>
    80001c92:	892a                	mv	s2,a0
    80001c94:	eca8                	sd	a0,88(s1)
    80001c96:	c931                	beqz	a0,80001cea <allocproc+0xaa>
  p->pagetable = proc_pagetable(p);
    80001c98:	8526                	mv	a0,s1
    80001c9a:	00000097          	auipc	ra,0x0
    80001c9e:	e54080e7          	jalr	-428(ra) # 80001aee <proc_pagetable>
    80001ca2:	892a                	mv	s2,a0
    80001ca4:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001ca6:	c929                	beqz	a0,80001cf8 <allocproc+0xb8>
  memset(&p->context, 0, sizeof(p->context));
    80001ca8:	07000613          	li	a2,112
    80001cac:	4581                	li	a1,0
    80001cae:	06048513          	add	a0,s1,96
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	0aa080e7          	jalr	170(ra) # 80000d5c <memset>
  p->context.ra = (uint64)forkret;
    80001cba:	00000797          	auipc	a5,0x0
    80001cbe:	da878793          	add	a5,a5,-600 # 80001a62 <forkret>
    80001cc2:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cc4:	60bc                	ld	a5,64(s1)
    80001cc6:	6705                	lui	a4,0x1
    80001cc8:	97ba                	add	a5,a5,a4
    80001cca:	f4bc                	sd	a5,104(s1)
  p->interval = 0;
    80001ccc:	1604a423          	sw	zero,360(s1)
  p->handler = 0;
    80001cd0:	1604b823          	sd	zero,368(s1)
  p->ticks = 0;
    80001cd4:	1604ac23          	sw	zero,376(s1)
  p->trapframecopy = 0;
    80001cd8:	1804b023          	sd	zero,384(s1)
}
    80001cdc:	8526                	mv	a0,s1
    80001cde:	60e2                	ld	ra,24(sp)
    80001ce0:	6442                	ld	s0,16(sp)
    80001ce2:	64a2                	ld	s1,8(sp)
    80001ce4:	6902                	ld	s2,0(sp)
    80001ce6:	6105                	add	sp,sp,32
    80001ce8:	8082                	ret
    release(&p->lock);
    80001cea:	8526                	mv	a0,s1
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	028080e7          	jalr	40(ra) # 80000d14 <release>
    return 0;
    80001cf4:	84ca                	mv	s1,s2
    80001cf6:	b7dd                	j	80001cdc <allocproc+0x9c>
    freeproc(p);
    80001cf8:	8526                	mv	a0,s1
    80001cfa:	00000097          	auipc	ra,0x0
    80001cfe:	ee2080e7          	jalr	-286(ra) # 80001bdc <freeproc>
    release(&p->lock);
    80001d02:	8526                	mv	a0,s1
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	010080e7          	jalr	16(ra) # 80000d14 <release>
    return 0;
    80001d0c:	84ca                	mv	s1,s2
    80001d0e:	b7f9                	j	80001cdc <allocproc+0x9c>

0000000080001d10 <userinit>:
{
    80001d10:	1101                	add	sp,sp,-32
    80001d12:	ec06                	sd	ra,24(sp)
    80001d14:	e822                	sd	s0,16(sp)
    80001d16:	e426                	sd	s1,8(sp)
    80001d18:	1000                	add	s0,sp,32
  p = allocproc();
    80001d1a:	00000097          	auipc	ra,0x0
    80001d1e:	f26080e7          	jalr	-218(ra) # 80001c40 <allocproc>
    80001d22:	84aa                	mv	s1,a0
  initproc = p;
    80001d24:	00007797          	auipc	a5,0x7
    80001d28:	2ea7ba23          	sd	a0,756(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d2c:	03400613          	li	a2,52
    80001d30:	00007597          	auipc	a1,0x7
    80001d34:	b2058593          	add	a1,a1,-1248 # 80008850 <initcode>
    80001d38:	6928                	ld	a0,80(a0)
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	6d8080e7          	jalr	1752(ra) # 80001412 <uvminit>
  p->sz = PGSIZE;
    80001d42:	6785                	lui	a5,0x1
    80001d44:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d46:	6cb8                	ld	a4,88(s1)
    80001d48:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d4c:	6cb8                	ld	a4,88(s1)
    80001d4e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d50:	4641                	li	a2,16
    80001d52:	00006597          	auipc	a1,0x6
    80001d56:	4ae58593          	add	a1,a1,1198 # 80008200 <digits+0x1a8>
    80001d5a:	15848513          	add	a0,s1,344
    80001d5e:	fffff097          	auipc	ra,0xfffff
    80001d62:	14e080e7          	jalr	334(ra) # 80000eac <safestrcpy>
  p->cwd = namei("/");
    80001d66:	00006517          	auipc	a0,0x6
    80001d6a:	4aa50513          	add	a0,a0,1194 # 80008210 <digits+0x1b8>
    80001d6e:	00002097          	auipc	ra,0x2
    80001d72:	19e080e7          	jalr	414(ra) # 80003f0c <namei>
    80001d76:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d7a:	4789                	li	a5,2
    80001d7c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d7e:	8526                	mv	a0,s1
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	f94080e7          	jalr	-108(ra) # 80000d14 <release>
}
    80001d88:	60e2                	ld	ra,24(sp)
    80001d8a:	6442                	ld	s0,16(sp)
    80001d8c:	64a2                	ld	s1,8(sp)
    80001d8e:	6105                	add	sp,sp,32
    80001d90:	8082                	ret

0000000080001d92 <growproc>:
{
    80001d92:	1101                	add	sp,sp,-32
    80001d94:	ec06                	sd	ra,24(sp)
    80001d96:	e822                	sd	s0,16(sp)
    80001d98:	e426                	sd	s1,8(sp)
    80001d9a:	e04a                	sd	s2,0(sp)
    80001d9c:	1000                	add	s0,sp,32
    80001d9e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001da0:	00000097          	auipc	ra,0x0
    80001da4:	c8a080e7          	jalr	-886(ra) # 80001a2a <myproc>
    80001da8:	892a                	mv	s2,a0
  sz = p->sz;
    80001daa:	652c                	ld	a1,72(a0)
    80001dac:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001db0:	00904f63          	bgtz	s1,80001dce <growproc+0x3c>
  } else if(n < 0){
    80001db4:	0204cd63          	bltz	s1,80001dee <growproc+0x5c>
  p->sz = sz;
    80001db8:	1782                	sll	a5,a5,0x20
    80001dba:	9381                	srl	a5,a5,0x20
    80001dbc:	04f93423          	sd	a5,72(s2)
  return 0;
    80001dc0:	4501                	li	a0,0
}
    80001dc2:	60e2                	ld	ra,24(sp)
    80001dc4:	6442                	ld	s0,16(sp)
    80001dc6:	64a2                	ld	s1,8(sp)
    80001dc8:	6902                	ld	s2,0(sp)
    80001dca:	6105                	add	sp,sp,32
    80001dcc:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dce:	00f4863b          	addw	a2,s1,a5
    80001dd2:	1602                	sll	a2,a2,0x20
    80001dd4:	9201                	srl	a2,a2,0x20
    80001dd6:	1582                	sll	a1,a1,0x20
    80001dd8:	9181                	srl	a1,a1,0x20
    80001dda:	6928                	ld	a0,80(a0)
    80001ddc:	fffff097          	auipc	ra,0xfffff
    80001de0:	6f0080e7          	jalr	1776(ra) # 800014cc <uvmalloc>
    80001de4:	0005079b          	sext.w	a5,a0
    80001de8:	fbe1                	bnez	a5,80001db8 <growproc+0x26>
      return -1;
    80001dea:	557d                	li	a0,-1
    80001dec:	bfd9                	j	80001dc2 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dee:	00f4863b          	addw	a2,s1,a5
    80001df2:	1602                	sll	a2,a2,0x20
    80001df4:	9201                	srl	a2,a2,0x20
    80001df6:	1582                	sll	a1,a1,0x20
    80001df8:	9181                	srl	a1,a1,0x20
    80001dfa:	6928                	ld	a0,80(a0)
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	688080e7          	jalr	1672(ra) # 80001484 <uvmdealloc>
    80001e04:	0005079b          	sext.w	a5,a0
    80001e08:	bf45                	j	80001db8 <growproc+0x26>

0000000080001e0a <fork>:
{
    80001e0a:	7139                	add	sp,sp,-64
    80001e0c:	fc06                	sd	ra,56(sp)
    80001e0e:	f822                	sd	s0,48(sp)
    80001e10:	f426                	sd	s1,40(sp)
    80001e12:	f04a                	sd	s2,32(sp)
    80001e14:	ec4e                	sd	s3,24(sp)
    80001e16:	e852                	sd	s4,16(sp)
    80001e18:	e456                	sd	s5,8(sp)
    80001e1a:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001e1c:	00000097          	auipc	ra,0x0
    80001e20:	c0e080e7          	jalr	-1010(ra) # 80001a2a <myproc>
    80001e24:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e26:	00000097          	auipc	ra,0x0
    80001e2a:	e1a080e7          	jalr	-486(ra) # 80001c40 <allocproc>
    80001e2e:	c17d                	beqz	a0,80001f14 <fork+0x10a>
    80001e30:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e32:	048ab603          	ld	a2,72(s5)
    80001e36:	692c                	ld	a1,80(a0)
    80001e38:	050ab503          	ld	a0,80(s5)
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	7e0080e7          	jalr	2016(ra) # 8000161c <uvmcopy>
    80001e44:	04054a63          	bltz	a0,80001e98 <fork+0x8e>
  np->sz = p->sz;
    80001e48:	048ab783          	ld	a5,72(s5)
    80001e4c:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001e50:	035a3023          	sd	s5,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e54:	058ab683          	ld	a3,88(s5)
    80001e58:	87b6                	mv	a5,a3
    80001e5a:	058a3703          	ld	a4,88(s4)
    80001e5e:	12068693          	add	a3,a3,288
    80001e62:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e66:	6788                	ld	a0,8(a5)
    80001e68:	6b8c                	ld	a1,16(a5)
    80001e6a:	6f90                	ld	a2,24(a5)
    80001e6c:	01073023          	sd	a6,0(a4)
    80001e70:	e708                	sd	a0,8(a4)
    80001e72:	eb0c                	sd	a1,16(a4)
    80001e74:	ef10                	sd	a2,24(a4)
    80001e76:	02078793          	add	a5,a5,32
    80001e7a:	02070713          	add	a4,a4,32
    80001e7e:	fed792e3          	bne	a5,a3,80001e62 <fork+0x58>
  np->trapframe->a0 = 0;
    80001e82:	058a3783          	ld	a5,88(s4)
    80001e86:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e8a:	0d0a8493          	add	s1,s5,208
    80001e8e:	0d0a0913          	add	s2,s4,208
    80001e92:	150a8993          	add	s3,s5,336
    80001e96:	a00d                	j	80001eb8 <fork+0xae>
    freeproc(np);
    80001e98:	8552                	mv	a0,s4
    80001e9a:	00000097          	auipc	ra,0x0
    80001e9e:	d42080e7          	jalr	-702(ra) # 80001bdc <freeproc>
    release(&np->lock);
    80001ea2:	8552                	mv	a0,s4
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	e70080e7          	jalr	-400(ra) # 80000d14 <release>
    return -1;
    80001eac:	54fd                	li	s1,-1
    80001eae:	a889                	j	80001f00 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    80001eb0:	04a1                	add	s1,s1,8
    80001eb2:	0921                	add	s2,s2,8
    80001eb4:	01348b63          	beq	s1,s3,80001eca <fork+0xc0>
    if(p->ofile[i])
    80001eb8:	6088                	ld	a0,0(s1)
    80001eba:	d97d                	beqz	a0,80001eb0 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ebc:	00002097          	auipc	ra,0x2
    80001ec0:	6b8080e7          	jalr	1720(ra) # 80004574 <filedup>
    80001ec4:	00a93023          	sd	a0,0(s2)
    80001ec8:	b7e5                	j	80001eb0 <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001eca:	150ab503          	ld	a0,336(s5)
    80001ece:	00002097          	auipc	ra,0x2
    80001ed2:	850080e7          	jalr	-1968(ra) # 8000371e <idup>
    80001ed6:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001eda:	4641                	li	a2,16
    80001edc:	158a8593          	add	a1,s5,344
    80001ee0:	158a0513          	add	a0,s4,344
    80001ee4:	fffff097          	auipc	ra,0xfffff
    80001ee8:	fc8080e7          	jalr	-56(ra) # 80000eac <safestrcpy>
  pid = np->pid;
    80001eec:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001ef0:	4789                	li	a5,2
    80001ef2:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ef6:	8552                	mv	a0,s4
    80001ef8:	fffff097          	auipc	ra,0xfffff
    80001efc:	e1c080e7          	jalr	-484(ra) # 80000d14 <release>
}
    80001f00:	8526                	mv	a0,s1
    80001f02:	70e2                	ld	ra,56(sp)
    80001f04:	7442                	ld	s0,48(sp)
    80001f06:	74a2                	ld	s1,40(sp)
    80001f08:	7902                	ld	s2,32(sp)
    80001f0a:	69e2                	ld	s3,24(sp)
    80001f0c:	6a42                	ld	s4,16(sp)
    80001f0e:	6aa2                	ld	s5,8(sp)
    80001f10:	6121                	add	sp,sp,64
    80001f12:	8082                	ret
    return -1;
    80001f14:	54fd                	li	s1,-1
    80001f16:	b7ed                	j	80001f00 <fork+0xf6>

0000000080001f18 <reparent>:
{
    80001f18:	7179                	add	sp,sp,-48
    80001f1a:	f406                	sd	ra,40(sp)
    80001f1c:	f022                	sd	s0,32(sp)
    80001f1e:	ec26                	sd	s1,24(sp)
    80001f20:	e84a                	sd	s2,16(sp)
    80001f22:	e44e                	sd	s3,8(sp)
    80001f24:	e052                	sd	s4,0(sp)
    80001f26:	1800                	add	s0,sp,48
    80001f28:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f2a:	00010497          	auipc	s1,0x10
    80001f2e:	e3e48493          	add	s1,s1,-450 # 80011d68 <proc>
      pp->parent = initproc;
    80001f32:	00007a17          	auipc	s4,0x7
    80001f36:	0e6a0a13          	add	s4,s4,230 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f3a:	00016997          	auipc	s3,0x16
    80001f3e:	02e98993          	add	s3,s3,46 # 80017f68 <tickslock>
    80001f42:	a029                	j	80001f4c <reparent+0x34>
    80001f44:	18848493          	add	s1,s1,392
    80001f48:	03348363          	beq	s1,s3,80001f6e <reparent+0x56>
    if(pp->parent == p){
    80001f4c:	709c                	ld	a5,32(s1)
    80001f4e:	ff279be3          	bne	a5,s2,80001f44 <reparent+0x2c>
      acquire(&pp->lock);
    80001f52:	8526                	mv	a0,s1
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	d0c080e7          	jalr	-756(ra) # 80000c60 <acquire>
      pp->parent = initproc;
    80001f5c:	000a3783          	ld	a5,0(s4)
    80001f60:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f62:	8526                	mv	a0,s1
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	db0080e7          	jalr	-592(ra) # 80000d14 <release>
    80001f6c:	bfe1                	j	80001f44 <reparent+0x2c>
}
    80001f6e:	70a2                	ld	ra,40(sp)
    80001f70:	7402                	ld	s0,32(sp)
    80001f72:	64e2                	ld	s1,24(sp)
    80001f74:	6942                	ld	s2,16(sp)
    80001f76:	69a2                	ld	s3,8(sp)
    80001f78:	6a02                	ld	s4,0(sp)
    80001f7a:	6145                	add	sp,sp,48
    80001f7c:	8082                	ret

0000000080001f7e <scheduler>:
{
    80001f7e:	715d                	add	sp,sp,-80
    80001f80:	e486                	sd	ra,72(sp)
    80001f82:	e0a2                	sd	s0,64(sp)
    80001f84:	fc26                	sd	s1,56(sp)
    80001f86:	f84a                	sd	s2,48(sp)
    80001f88:	f44e                	sd	s3,40(sp)
    80001f8a:	f052                	sd	s4,32(sp)
    80001f8c:	ec56                	sd	s5,24(sp)
    80001f8e:	e85a                	sd	s6,16(sp)
    80001f90:	e45e                	sd	s7,8(sp)
    80001f92:	e062                	sd	s8,0(sp)
    80001f94:	0880                	add	s0,sp,80
    80001f96:	8792                	mv	a5,tp
  int id = r_tp();
    80001f98:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f9a:	00779b13          	sll	s6,a5,0x7
    80001f9e:	00010717          	auipc	a4,0x10
    80001fa2:	9b270713          	add	a4,a4,-1614 # 80011950 <pid_lock>
    80001fa6:	975a                	add	a4,a4,s6
    80001fa8:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001fac:	00010717          	auipc	a4,0x10
    80001fb0:	9c470713          	add	a4,a4,-1596 # 80011970 <cpus+0x8>
    80001fb4:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001fb6:	4c0d                	li	s8,3
        c->proc = p;
    80001fb8:	079e                	sll	a5,a5,0x7
    80001fba:	00010a17          	auipc	s4,0x10
    80001fbe:	996a0a13          	add	s4,s4,-1642 # 80011950 <pid_lock>
    80001fc2:	9a3e                	add	s4,s4,a5
        found = 1;
    80001fc4:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fc6:	00016997          	auipc	s3,0x16
    80001fca:	fa298993          	add	s3,s3,-94 # 80017f68 <tickslock>
    80001fce:	a899                	j	80002024 <scheduler+0xa6>
      release(&p->lock);
    80001fd0:	8526                	mv	a0,s1
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	d42080e7          	jalr	-702(ra) # 80000d14 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fda:	18848493          	add	s1,s1,392
    80001fde:	03348963          	beq	s1,s3,80002010 <scheduler+0x92>
      acquire(&p->lock);
    80001fe2:	8526                	mv	a0,s1
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	c7c080e7          	jalr	-900(ra) # 80000c60 <acquire>
      if(p->state == RUNNABLE) {
    80001fec:	4c9c                	lw	a5,24(s1)
    80001fee:	ff2791e3          	bne	a5,s2,80001fd0 <scheduler+0x52>
        p->state = RUNNING;
    80001ff2:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001ff6:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001ffa:	06048593          	add	a1,s1,96
    80001ffe:	855a                	mv	a0,s6
    80002000:	00000097          	auipc	ra,0x0
    80002004:	610080e7          	jalr	1552(ra) # 80002610 <swtch>
        c->proc = 0;
    80002008:	000a3c23          	sd	zero,24(s4)
        found = 1;
    8000200c:	8ade                	mv	s5,s7
    8000200e:	b7c9                	j	80001fd0 <scheduler+0x52>
    if(found == 0) {
    80002010:	000a9a63          	bnez	s5,80002024 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002014:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002018:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000201c:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002020:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002024:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002028:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000202c:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002030:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002032:	00010497          	auipc	s1,0x10
    80002036:	d3648493          	add	s1,s1,-714 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    8000203a:	4909                	li	s2,2
    8000203c:	b75d                	j	80001fe2 <scheduler+0x64>

000000008000203e <sched>:
{
    8000203e:	7179                	add	sp,sp,-48
    80002040:	f406                	sd	ra,40(sp)
    80002042:	f022                	sd	s0,32(sp)
    80002044:	ec26                	sd	s1,24(sp)
    80002046:	e84a                	sd	s2,16(sp)
    80002048:	e44e                	sd	s3,8(sp)
    8000204a:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    8000204c:	00000097          	auipc	ra,0x0
    80002050:	9de080e7          	jalr	-1570(ra) # 80001a2a <myproc>
    80002054:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002056:	fffff097          	auipc	ra,0xfffff
    8000205a:	b90080e7          	jalr	-1136(ra) # 80000be6 <holding>
    8000205e:	c93d                	beqz	a0,800020d4 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002060:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002062:	2781                	sext.w	a5,a5
    80002064:	079e                	sll	a5,a5,0x7
    80002066:	00010717          	auipc	a4,0x10
    8000206a:	8ea70713          	add	a4,a4,-1814 # 80011950 <pid_lock>
    8000206e:	97ba                	add	a5,a5,a4
    80002070:	0907a703          	lw	a4,144(a5)
    80002074:	4785                	li	a5,1
    80002076:	06f71763          	bne	a4,a5,800020e4 <sched+0xa6>
  if(p->state == RUNNING)
    8000207a:	4c98                	lw	a4,24(s1)
    8000207c:	478d                	li	a5,3
    8000207e:	06f70b63          	beq	a4,a5,800020f4 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002082:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002086:	8b89                	and	a5,a5,2
  if(intr_get())
    80002088:	efb5                	bnez	a5,80002104 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000208a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000208c:	00010917          	auipc	s2,0x10
    80002090:	8c490913          	add	s2,s2,-1852 # 80011950 <pid_lock>
    80002094:	2781                	sext.w	a5,a5
    80002096:	079e                	sll	a5,a5,0x7
    80002098:	97ca                	add	a5,a5,s2
    8000209a:	0947a983          	lw	s3,148(a5)
    8000209e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020a0:	2781                	sext.w	a5,a5
    800020a2:	079e                	sll	a5,a5,0x7
    800020a4:	00010597          	auipc	a1,0x10
    800020a8:	8cc58593          	add	a1,a1,-1844 # 80011970 <cpus+0x8>
    800020ac:	95be                	add	a1,a1,a5
    800020ae:	06048513          	add	a0,s1,96
    800020b2:	00000097          	auipc	ra,0x0
    800020b6:	55e080e7          	jalr	1374(ra) # 80002610 <swtch>
    800020ba:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020bc:	2781                	sext.w	a5,a5
    800020be:	079e                	sll	a5,a5,0x7
    800020c0:	993e                	add	s2,s2,a5
    800020c2:	09392a23          	sw	s3,148(s2)
}
    800020c6:	70a2                	ld	ra,40(sp)
    800020c8:	7402                	ld	s0,32(sp)
    800020ca:	64e2                	ld	s1,24(sp)
    800020cc:	6942                	ld	s2,16(sp)
    800020ce:	69a2                	ld	s3,8(sp)
    800020d0:	6145                	add	sp,sp,48
    800020d2:	8082                	ret
    panic("sched p->lock");
    800020d4:	00006517          	auipc	a0,0x6
    800020d8:	14450513          	add	a0,a0,324 # 80008218 <digits+0x1c0>
    800020dc:	ffffe097          	auipc	ra,0xffffe
    800020e0:	466080e7          	jalr	1126(ra) # 80000542 <panic>
    panic("sched locks");
    800020e4:	00006517          	auipc	a0,0x6
    800020e8:	14450513          	add	a0,a0,324 # 80008228 <digits+0x1d0>
    800020ec:	ffffe097          	auipc	ra,0xffffe
    800020f0:	456080e7          	jalr	1110(ra) # 80000542 <panic>
    panic("sched running");
    800020f4:	00006517          	auipc	a0,0x6
    800020f8:	14450513          	add	a0,a0,324 # 80008238 <digits+0x1e0>
    800020fc:	ffffe097          	auipc	ra,0xffffe
    80002100:	446080e7          	jalr	1094(ra) # 80000542 <panic>
    panic("sched interruptible");
    80002104:	00006517          	auipc	a0,0x6
    80002108:	14450513          	add	a0,a0,324 # 80008248 <digits+0x1f0>
    8000210c:	ffffe097          	auipc	ra,0xffffe
    80002110:	436080e7          	jalr	1078(ra) # 80000542 <panic>

0000000080002114 <exit>:
{
    80002114:	7179                	add	sp,sp,-48
    80002116:	f406                	sd	ra,40(sp)
    80002118:	f022                	sd	s0,32(sp)
    8000211a:	ec26                	sd	s1,24(sp)
    8000211c:	e84a                	sd	s2,16(sp)
    8000211e:	e44e                	sd	s3,8(sp)
    80002120:	e052                	sd	s4,0(sp)
    80002122:	1800                	add	s0,sp,48
    80002124:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002126:	00000097          	auipc	ra,0x0
    8000212a:	904080e7          	jalr	-1788(ra) # 80001a2a <myproc>
    8000212e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002130:	00007797          	auipc	a5,0x7
    80002134:	ee87b783          	ld	a5,-280(a5) # 80009018 <initproc>
    80002138:	0d050493          	add	s1,a0,208
    8000213c:	15050913          	add	s2,a0,336
    80002140:	02a79363          	bne	a5,a0,80002166 <exit+0x52>
    panic("init exiting");
    80002144:	00006517          	auipc	a0,0x6
    80002148:	11c50513          	add	a0,a0,284 # 80008260 <digits+0x208>
    8000214c:	ffffe097          	auipc	ra,0xffffe
    80002150:	3f6080e7          	jalr	1014(ra) # 80000542 <panic>
      fileclose(f);
    80002154:	00002097          	auipc	ra,0x2
    80002158:	472080e7          	jalr	1138(ra) # 800045c6 <fileclose>
      p->ofile[fd] = 0;
    8000215c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002160:	04a1                	add	s1,s1,8
    80002162:	01248563          	beq	s1,s2,8000216c <exit+0x58>
    if(p->ofile[fd]){
    80002166:	6088                	ld	a0,0(s1)
    80002168:	f575                	bnez	a0,80002154 <exit+0x40>
    8000216a:	bfdd                	j	80002160 <exit+0x4c>
  begin_op();
    8000216c:	00002097          	auipc	ra,0x2
    80002170:	f90080e7          	jalr	-112(ra) # 800040fc <begin_op>
  iput(p->cwd);
    80002174:	1509b503          	ld	a0,336(s3)
    80002178:	00001097          	auipc	ra,0x1
    8000217c:	79e080e7          	jalr	1950(ra) # 80003916 <iput>
  end_op();
    80002180:	00002097          	auipc	ra,0x2
    80002184:	ff6080e7          	jalr	-10(ra) # 80004176 <end_op>
  p->cwd = 0;
    80002188:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    8000218c:	00007497          	auipc	s1,0x7
    80002190:	e8c48493          	add	s1,s1,-372 # 80009018 <initproc>
    80002194:	6088                	ld	a0,0(s1)
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	aca080e7          	jalr	-1334(ra) # 80000c60 <acquire>
  wakeup1(initproc);
    8000219e:	6088                	ld	a0,0(s1)
    800021a0:	fffff097          	auipc	ra,0xfffff
    800021a4:	74a080e7          	jalr	1866(ra) # 800018ea <wakeup1>
  release(&initproc->lock);
    800021a8:	6088                	ld	a0,0(s1)
    800021aa:	fffff097          	auipc	ra,0xfffff
    800021ae:	b6a080e7          	jalr	-1174(ra) # 80000d14 <release>
  acquire(&p->lock);
    800021b2:	854e                	mv	a0,s3
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	aac080e7          	jalr	-1364(ra) # 80000c60 <acquire>
  struct proc *original_parent = p->parent;
    800021bc:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021c0:	854e                	mv	a0,s3
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	b52080e7          	jalr	-1198(ra) # 80000d14 <release>
  acquire(&original_parent->lock);
    800021ca:	8526                	mv	a0,s1
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	a94080e7          	jalr	-1388(ra) # 80000c60 <acquire>
  acquire(&p->lock);
    800021d4:	854e                	mv	a0,s3
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	a8a080e7          	jalr	-1398(ra) # 80000c60 <acquire>
  reparent(p);
    800021de:	854e                	mv	a0,s3
    800021e0:	00000097          	auipc	ra,0x0
    800021e4:	d38080e7          	jalr	-712(ra) # 80001f18 <reparent>
  wakeup1(original_parent);
    800021e8:	8526                	mv	a0,s1
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	700080e7          	jalr	1792(ra) # 800018ea <wakeup1>
  p->xstate = status;
    800021f2:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021f6:	4791                	li	a5,4
    800021f8:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800021fc:	8526                	mv	a0,s1
    800021fe:	fffff097          	auipc	ra,0xfffff
    80002202:	b16080e7          	jalr	-1258(ra) # 80000d14 <release>
  sched();
    80002206:	00000097          	auipc	ra,0x0
    8000220a:	e38080e7          	jalr	-456(ra) # 8000203e <sched>
  panic("zombie exit");
    8000220e:	00006517          	auipc	a0,0x6
    80002212:	06250513          	add	a0,a0,98 # 80008270 <digits+0x218>
    80002216:	ffffe097          	auipc	ra,0xffffe
    8000221a:	32c080e7          	jalr	812(ra) # 80000542 <panic>

000000008000221e <yield>:
{
    8000221e:	1101                	add	sp,sp,-32
    80002220:	ec06                	sd	ra,24(sp)
    80002222:	e822                	sd	s0,16(sp)
    80002224:	e426                	sd	s1,8(sp)
    80002226:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    80002228:	00000097          	auipc	ra,0x0
    8000222c:	802080e7          	jalr	-2046(ra) # 80001a2a <myproc>
    80002230:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	a2e080e7          	jalr	-1490(ra) # 80000c60 <acquire>
  p->state = RUNNABLE;
    8000223a:	4789                	li	a5,2
    8000223c:	cc9c                	sw	a5,24(s1)
  sched();
    8000223e:	00000097          	auipc	ra,0x0
    80002242:	e00080e7          	jalr	-512(ra) # 8000203e <sched>
  release(&p->lock);
    80002246:	8526                	mv	a0,s1
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	acc080e7          	jalr	-1332(ra) # 80000d14 <release>
}
    80002250:	60e2                	ld	ra,24(sp)
    80002252:	6442                	ld	s0,16(sp)
    80002254:	64a2                	ld	s1,8(sp)
    80002256:	6105                	add	sp,sp,32
    80002258:	8082                	ret

000000008000225a <sleep>:
{
    8000225a:	7179                	add	sp,sp,-48
    8000225c:	f406                	sd	ra,40(sp)
    8000225e:	f022                	sd	s0,32(sp)
    80002260:	ec26                	sd	s1,24(sp)
    80002262:	e84a                	sd	s2,16(sp)
    80002264:	e44e                	sd	s3,8(sp)
    80002266:	1800                	add	s0,sp,48
    80002268:	89aa                	mv	s3,a0
    8000226a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	7be080e7          	jalr	1982(ra) # 80001a2a <myproc>
    80002274:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002276:	05250663          	beq	a0,s2,800022c2 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	9e6080e7          	jalr	-1562(ra) # 80000c60 <acquire>
    release(lk);
    80002282:	854a                	mv	a0,s2
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	a90080e7          	jalr	-1392(ra) # 80000d14 <release>
  p->chan = chan;
    8000228c:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002290:	4785                	li	a5,1
    80002292:	cc9c                	sw	a5,24(s1)
  sched();
    80002294:	00000097          	auipc	ra,0x0
    80002298:	daa080e7          	jalr	-598(ra) # 8000203e <sched>
  p->chan = 0;
    8000229c:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800022a0:	8526                	mv	a0,s1
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	a72080e7          	jalr	-1422(ra) # 80000d14 <release>
    acquire(lk);
    800022aa:	854a                	mv	a0,s2
    800022ac:	fffff097          	auipc	ra,0xfffff
    800022b0:	9b4080e7          	jalr	-1612(ra) # 80000c60 <acquire>
}
    800022b4:	70a2                	ld	ra,40(sp)
    800022b6:	7402                	ld	s0,32(sp)
    800022b8:	64e2                	ld	s1,24(sp)
    800022ba:	6942                	ld	s2,16(sp)
    800022bc:	69a2                	ld	s3,8(sp)
    800022be:	6145                	add	sp,sp,48
    800022c0:	8082                	ret
  p->chan = chan;
    800022c2:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022c6:	4785                	li	a5,1
    800022c8:	cd1c                	sw	a5,24(a0)
  sched();
    800022ca:	00000097          	auipc	ra,0x0
    800022ce:	d74080e7          	jalr	-652(ra) # 8000203e <sched>
  p->chan = 0;
    800022d2:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800022d6:	bff9                	j	800022b4 <sleep+0x5a>

00000000800022d8 <wait>:
{
    800022d8:	715d                	add	sp,sp,-80
    800022da:	e486                	sd	ra,72(sp)
    800022dc:	e0a2                	sd	s0,64(sp)
    800022de:	fc26                	sd	s1,56(sp)
    800022e0:	f84a                	sd	s2,48(sp)
    800022e2:	f44e                	sd	s3,40(sp)
    800022e4:	f052                	sd	s4,32(sp)
    800022e6:	ec56                	sd	s5,24(sp)
    800022e8:	e85a                	sd	s6,16(sp)
    800022ea:	e45e                	sd	s7,8(sp)
    800022ec:	0880                	add	s0,sp,80
    800022ee:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022f0:	fffff097          	auipc	ra,0xfffff
    800022f4:	73a080e7          	jalr	1850(ra) # 80001a2a <myproc>
    800022f8:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022fa:	fffff097          	auipc	ra,0xfffff
    800022fe:	966080e7          	jalr	-1690(ra) # 80000c60 <acquire>
    havekids = 0;
    80002302:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002304:	4a11                	li	s4,4
        havekids = 1;
    80002306:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002308:	00016997          	auipc	s3,0x16
    8000230c:	c6098993          	add	s3,s3,-928 # 80017f68 <tickslock>
    80002310:	a845                	j	800023c0 <wait+0xe8>
          pid = np->pid;
    80002312:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002316:	000b0e63          	beqz	s6,80002332 <wait+0x5a>
    8000231a:	4691                	li	a3,4
    8000231c:	03448613          	add	a2,s1,52
    80002320:	85da                	mv	a1,s6
    80002322:	05093503          	ld	a0,80(s2)
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	3fa080e7          	jalr	1018(ra) # 80001720 <copyout>
    8000232e:	02054d63          	bltz	a0,80002368 <wait+0x90>
          freeproc(np);
    80002332:	8526                	mv	a0,s1
    80002334:	00000097          	auipc	ra,0x0
    80002338:	8a8080e7          	jalr	-1880(ra) # 80001bdc <freeproc>
          release(&np->lock);
    8000233c:	8526                	mv	a0,s1
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	9d6080e7          	jalr	-1578(ra) # 80000d14 <release>
          release(&p->lock);
    80002346:	854a                	mv	a0,s2
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	9cc080e7          	jalr	-1588(ra) # 80000d14 <release>
}
    80002350:	854e                	mv	a0,s3
    80002352:	60a6                	ld	ra,72(sp)
    80002354:	6406                	ld	s0,64(sp)
    80002356:	74e2                	ld	s1,56(sp)
    80002358:	7942                	ld	s2,48(sp)
    8000235a:	79a2                	ld	s3,40(sp)
    8000235c:	7a02                	ld	s4,32(sp)
    8000235e:	6ae2                	ld	s5,24(sp)
    80002360:	6b42                	ld	s6,16(sp)
    80002362:	6ba2                	ld	s7,8(sp)
    80002364:	6161                	add	sp,sp,80
    80002366:	8082                	ret
            release(&np->lock);
    80002368:	8526                	mv	a0,s1
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	9aa080e7          	jalr	-1622(ra) # 80000d14 <release>
            release(&p->lock);
    80002372:	854a                	mv	a0,s2
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	9a0080e7          	jalr	-1632(ra) # 80000d14 <release>
            return -1;
    8000237c:	59fd                	li	s3,-1
    8000237e:	bfc9                	j	80002350 <wait+0x78>
    for(np = proc; np < &proc[NPROC]; np++){
    80002380:	18848493          	add	s1,s1,392
    80002384:	03348463          	beq	s1,s3,800023ac <wait+0xd4>
      if(np->parent == p){
    80002388:	709c                	ld	a5,32(s1)
    8000238a:	ff279be3          	bne	a5,s2,80002380 <wait+0xa8>
        acquire(&np->lock);
    8000238e:	8526                	mv	a0,s1
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	8d0080e7          	jalr	-1840(ra) # 80000c60 <acquire>
        if(np->state == ZOMBIE){
    80002398:	4c9c                	lw	a5,24(s1)
    8000239a:	f7478ce3          	beq	a5,s4,80002312 <wait+0x3a>
        release(&np->lock);
    8000239e:	8526                	mv	a0,s1
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	974080e7          	jalr	-1676(ra) # 80000d14 <release>
        havekids = 1;
    800023a8:	8756                	mv	a4,s5
    800023aa:	bfd9                	j	80002380 <wait+0xa8>
    if(!havekids || p->killed){
    800023ac:	c305                	beqz	a4,800023cc <wait+0xf4>
    800023ae:	03092783          	lw	a5,48(s2)
    800023b2:	ef89                	bnez	a5,800023cc <wait+0xf4>
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023b4:	85ca                	mv	a1,s2
    800023b6:	854a                	mv	a0,s2
    800023b8:	00000097          	auipc	ra,0x0
    800023bc:	ea2080e7          	jalr	-350(ra) # 8000225a <sleep>
    havekids = 0;
    800023c0:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800023c2:	00010497          	auipc	s1,0x10
    800023c6:	9a648493          	add	s1,s1,-1626 # 80011d68 <proc>
    800023ca:	bf7d                	j	80002388 <wait+0xb0>
      release(&p->lock);
    800023cc:	854a                	mv	a0,s2
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	946080e7          	jalr	-1722(ra) # 80000d14 <release>
      return -1;
    800023d6:	59fd                	li	s3,-1
    800023d8:	bfa5                	j	80002350 <wait+0x78>

00000000800023da <wakeup>:
{
    800023da:	7139                	add	sp,sp,-64
    800023dc:	fc06                	sd	ra,56(sp)
    800023de:	f822                	sd	s0,48(sp)
    800023e0:	f426                	sd	s1,40(sp)
    800023e2:	f04a                	sd	s2,32(sp)
    800023e4:	ec4e                	sd	s3,24(sp)
    800023e6:	e852                	sd	s4,16(sp)
    800023e8:	e456                	sd	s5,8(sp)
    800023ea:	0080                	add	s0,sp,64
    800023ec:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023ee:	00010497          	auipc	s1,0x10
    800023f2:	97a48493          	add	s1,s1,-1670 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023f6:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023f8:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800023fa:	00016917          	auipc	s2,0x16
    800023fe:	b6e90913          	add	s2,s2,-1170 # 80017f68 <tickslock>
    80002402:	a811                	j	80002416 <wakeup+0x3c>
    release(&p->lock);
    80002404:	8526                	mv	a0,s1
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	90e080e7          	jalr	-1778(ra) # 80000d14 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000240e:	18848493          	add	s1,s1,392
    80002412:	03248063          	beq	s1,s2,80002432 <wakeup+0x58>
    acquire(&p->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	848080e7          	jalr	-1976(ra) # 80000c60 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002420:	4c9c                	lw	a5,24(s1)
    80002422:	ff3791e3          	bne	a5,s3,80002404 <wakeup+0x2a>
    80002426:	749c                	ld	a5,40(s1)
    80002428:	fd479ee3          	bne	a5,s4,80002404 <wakeup+0x2a>
      p->state = RUNNABLE;
    8000242c:	0154ac23          	sw	s5,24(s1)
    80002430:	bfd1                	j	80002404 <wakeup+0x2a>
}
    80002432:	70e2                	ld	ra,56(sp)
    80002434:	7442                	ld	s0,48(sp)
    80002436:	74a2                	ld	s1,40(sp)
    80002438:	7902                	ld	s2,32(sp)
    8000243a:	69e2                	ld	s3,24(sp)
    8000243c:	6a42                	ld	s4,16(sp)
    8000243e:	6aa2                	ld	s5,8(sp)
    80002440:	6121                	add	sp,sp,64
    80002442:	8082                	ret

0000000080002444 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002444:	7179                	add	sp,sp,-48
    80002446:	f406                	sd	ra,40(sp)
    80002448:	f022                	sd	s0,32(sp)
    8000244a:	ec26                	sd	s1,24(sp)
    8000244c:	e84a                	sd	s2,16(sp)
    8000244e:	e44e                	sd	s3,8(sp)
    80002450:	1800                	add	s0,sp,48
    80002452:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002454:	00010497          	auipc	s1,0x10
    80002458:	91448493          	add	s1,s1,-1772 # 80011d68 <proc>
    8000245c:	00016997          	auipc	s3,0x16
    80002460:	b0c98993          	add	s3,s3,-1268 # 80017f68 <tickslock>
    acquire(&p->lock);
    80002464:	8526                	mv	a0,s1
    80002466:	ffffe097          	auipc	ra,0xffffe
    8000246a:	7fa080e7          	jalr	2042(ra) # 80000c60 <acquire>
    if(p->pid == pid){
    8000246e:	5c9c                	lw	a5,56(s1)
    80002470:	01278d63          	beq	a5,s2,8000248a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002474:	8526                	mv	a0,s1
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	89e080e7          	jalr	-1890(ra) # 80000d14 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000247e:	18848493          	add	s1,s1,392
    80002482:	ff3491e3          	bne	s1,s3,80002464 <kill+0x20>
  }
  return -1;
    80002486:	557d                	li	a0,-1
    80002488:	a821                	j	800024a0 <kill+0x5c>
      p->killed = 1;
    8000248a:	4785                	li	a5,1
    8000248c:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000248e:	4c98                	lw	a4,24(s1)
    80002490:	00f70f63          	beq	a4,a5,800024ae <kill+0x6a>
      release(&p->lock);
    80002494:	8526                	mv	a0,s1
    80002496:	fffff097          	auipc	ra,0xfffff
    8000249a:	87e080e7          	jalr	-1922(ra) # 80000d14 <release>
      return 0;
    8000249e:	4501                	li	a0,0
}
    800024a0:	70a2                	ld	ra,40(sp)
    800024a2:	7402                	ld	s0,32(sp)
    800024a4:	64e2                	ld	s1,24(sp)
    800024a6:	6942                	ld	s2,16(sp)
    800024a8:	69a2                	ld	s3,8(sp)
    800024aa:	6145                	add	sp,sp,48
    800024ac:	8082                	ret
        p->state = RUNNABLE;
    800024ae:	4789                	li	a5,2
    800024b0:	cc9c                	sw	a5,24(s1)
    800024b2:	b7cd                	j	80002494 <kill+0x50>

00000000800024b4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024b4:	7179                	add	sp,sp,-48
    800024b6:	f406                	sd	ra,40(sp)
    800024b8:	f022                	sd	s0,32(sp)
    800024ba:	ec26                	sd	s1,24(sp)
    800024bc:	e84a                	sd	s2,16(sp)
    800024be:	e44e                	sd	s3,8(sp)
    800024c0:	e052                	sd	s4,0(sp)
    800024c2:	1800                	add	s0,sp,48
    800024c4:	84aa                	mv	s1,a0
    800024c6:	892e                	mv	s2,a1
    800024c8:	89b2                	mv	s3,a2
    800024ca:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	55e080e7          	jalr	1374(ra) # 80001a2a <myproc>
  if(user_dst){
    800024d4:	c08d                	beqz	s1,800024f6 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024d6:	86d2                	mv	a3,s4
    800024d8:	864e                	mv	a2,s3
    800024da:	85ca                	mv	a1,s2
    800024dc:	6928                	ld	a0,80(a0)
    800024de:	fffff097          	auipc	ra,0xfffff
    800024e2:	242080e7          	jalr	578(ra) # 80001720 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024e6:	70a2                	ld	ra,40(sp)
    800024e8:	7402                	ld	s0,32(sp)
    800024ea:	64e2                	ld	s1,24(sp)
    800024ec:	6942                	ld	s2,16(sp)
    800024ee:	69a2                	ld	s3,8(sp)
    800024f0:	6a02                	ld	s4,0(sp)
    800024f2:	6145                	add	sp,sp,48
    800024f4:	8082                	ret
    memmove((char *)dst, src, len);
    800024f6:	000a061b          	sext.w	a2,s4
    800024fa:	85ce                	mv	a1,s3
    800024fc:	854a                	mv	a0,s2
    800024fe:	fffff097          	auipc	ra,0xfffff
    80002502:	8ba080e7          	jalr	-1862(ra) # 80000db8 <memmove>
    return 0;
    80002506:	8526                	mv	a0,s1
    80002508:	bff9                	j	800024e6 <either_copyout+0x32>

000000008000250a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000250a:	7179                	add	sp,sp,-48
    8000250c:	f406                	sd	ra,40(sp)
    8000250e:	f022                	sd	s0,32(sp)
    80002510:	ec26                	sd	s1,24(sp)
    80002512:	e84a                	sd	s2,16(sp)
    80002514:	e44e                	sd	s3,8(sp)
    80002516:	e052                	sd	s4,0(sp)
    80002518:	1800                	add	s0,sp,48
    8000251a:	892a                	mv	s2,a0
    8000251c:	84ae                	mv	s1,a1
    8000251e:	89b2                	mv	s3,a2
    80002520:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002522:	fffff097          	auipc	ra,0xfffff
    80002526:	508080e7          	jalr	1288(ra) # 80001a2a <myproc>
  if(user_src){
    8000252a:	c08d                	beqz	s1,8000254c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000252c:	86d2                	mv	a3,s4
    8000252e:	864e                	mv	a2,s3
    80002530:	85ca                	mv	a1,s2
    80002532:	6928                	ld	a0,80(a0)
    80002534:	fffff097          	auipc	ra,0xfffff
    80002538:	278080e7          	jalr	632(ra) # 800017ac <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000253c:	70a2                	ld	ra,40(sp)
    8000253e:	7402                	ld	s0,32(sp)
    80002540:	64e2                	ld	s1,24(sp)
    80002542:	6942                	ld	s2,16(sp)
    80002544:	69a2                	ld	s3,8(sp)
    80002546:	6a02                	ld	s4,0(sp)
    80002548:	6145                	add	sp,sp,48
    8000254a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000254c:	000a061b          	sext.w	a2,s4
    80002550:	85ce                	mv	a1,s3
    80002552:	854a                	mv	a0,s2
    80002554:	fffff097          	auipc	ra,0xfffff
    80002558:	864080e7          	jalr	-1948(ra) # 80000db8 <memmove>
    return 0;
    8000255c:	8526                	mv	a0,s1
    8000255e:	bff9                	j	8000253c <either_copyin+0x32>

0000000080002560 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002560:	715d                	add	sp,sp,-80
    80002562:	e486                	sd	ra,72(sp)
    80002564:	e0a2                	sd	s0,64(sp)
    80002566:	fc26                	sd	s1,56(sp)
    80002568:	f84a                	sd	s2,48(sp)
    8000256a:	f44e                	sd	s3,40(sp)
    8000256c:	f052                	sd	s4,32(sp)
    8000256e:	ec56                	sd	s5,24(sp)
    80002570:	e85a                	sd	s6,16(sp)
    80002572:	e45e                	sd	s7,8(sp)
    80002574:	0880                	add	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002576:	00006517          	auipc	a0,0x6
    8000257a:	b6a50513          	add	a0,a0,-1174 # 800080e0 <digits+0x88>
    8000257e:	ffffe097          	auipc	ra,0xffffe
    80002582:	016080e7          	jalr	22(ra) # 80000594 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002586:	00010497          	auipc	s1,0x10
    8000258a:	93a48493          	add	s1,s1,-1734 # 80011ec0 <proc+0x158>
    8000258e:	00016917          	auipc	s2,0x16
    80002592:	b3290913          	add	s2,s2,-1230 # 800180c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002596:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002598:	00006997          	auipc	s3,0x6
    8000259c:	ce898993          	add	s3,s3,-792 # 80008280 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800025a0:	00006a97          	auipc	s5,0x6
    800025a4:	ce8a8a93          	add	s5,s5,-792 # 80008288 <digits+0x230>
    printf("\n");
    800025a8:	00006a17          	auipc	s4,0x6
    800025ac:	b38a0a13          	add	s4,s4,-1224 # 800080e0 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025b0:	00006b97          	auipc	s7,0x6
    800025b4:	d10b8b93          	add	s7,s7,-752 # 800082c0 <states.0>
    800025b8:	a00d                	j	800025da <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025ba:	ee06a583          	lw	a1,-288(a3)
    800025be:	8556                	mv	a0,s5
    800025c0:	ffffe097          	auipc	ra,0xffffe
    800025c4:	fd4080e7          	jalr	-44(ra) # 80000594 <printf>
    printf("\n");
    800025c8:	8552                	mv	a0,s4
    800025ca:	ffffe097          	auipc	ra,0xffffe
    800025ce:	fca080e7          	jalr	-54(ra) # 80000594 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025d2:	18848493          	add	s1,s1,392
    800025d6:	03248263          	beq	s1,s2,800025fa <procdump+0x9a>
    if(p->state == UNUSED)
    800025da:	86a6                	mv	a3,s1
    800025dc:	ec04a783          	lw	a5,-320(s1)
    800025e0:	dbed                	beqz	a5,800025d2 <procdump+0x72>
      state = "???";
    800025e2:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025e4:	fcfb6be3          	bltu	s6,a5,800025ba <procdump+0x5a>
    800025e8:	02079713          	sll	a4,a5,0x20
    800025ec:	01d75793          	srl	a5,a4,0x1d
    800025f0:	97de                	add	a5,a5,s7
    800025f2:	6390                	ld	a2,0(a5)
    800025f4:	f279                	bnez	a2,800025ba <procdump+0x5a>
      state = "???";
    800025f6:	864e                	mv	a2,s3
    800025f8:	b7c9                	j	800025ba <procdump+0x5a>
  }
}
    800025fa:	60a6                	ld	ra,72(sp)
    800025fc:	6406                	ld	s0,64(sp)
    800025fe:	74e2                	ld	s1,56(sp)
    80002600:	7942                	ld	s2,48(sp)
    80002602:	79a2                	ld	s3,40(sp)
    80002604:	7a02                	ld	s4,32(sp)
    80002606:	6ae2                	ld	s5,24(sp)
    80002608:	6b42                	ld	s6,16(sp)
    8000260a:	6ba2                	ld	s7,8(sp)
    8000260c:	6161                	add	sp,sp,80
    8000260e:	8082                	ret

0000000080002610 <swtch>:
    80002610:	00153023          	sd	ra,0(a0)
    80002614:	00253423          	sd	sp,8(a0)
    80002618:	e900                	sd	s0,16(a0)
    8000261a:	ed04                	sd	s1,24(a0)
    8000261c:	03253023          	sd	s2,32(a0)
    80002620:	03353423          	sd	s3,40(a0)
    80002624:	03453823          	sd	s4,48(a0)
    80002628:	03553c23          	sd	s5,56(a0)
    8000262c:	05653023          	sd	s6,64(a0)
    80002630:	05753423          	sd	s7,72(a0)
    80002634:	05853823          	sd	s8,80(a0)
    80002638:	05953c23          	sd	s9,88(a0)
    8000263c:	07a53023          	sd	s10,96(a0)
    80002640:	07b53423          	sd	s11,104(a0)
    80002644:	0005b083          	ld	ra,0(a1)
    80002648:	0085b103          	ld	sp,8(a1)
    8000264c:	6980                	ld	s0,16(a1)
    8000264e:	6d84                	ld	s1,24(a1)
    80002650:	0205b903          	ld	s2,32(a1)
    80002654:	0285b983          	ld	s3,40(a1)
    80002658:	0305ba03          	ld	s4,48(a1)
    8000265c:	0385ba83          	ld	s5,56(a1)
    80002660:	0405bb03          	ld	s6,64(a1)
    80002664:	0485bb83          	ld	s7,72(a1)
    80002668:	0505bc03          	ld	s8,80(a1)
    8000266c:	0585bc83          	ld	s9,88(a1)
    80002670:	0605bd03          	ld	s10,96(a1)
    80002674:	0685bd83          	ld	s11,104(a1)
    80002678:	8082                	ret

000000008000267a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000267a:	1141                	add	sp,sp,-16
    8000267c:	e406                	sd	ra,8(sp)
    8000267e:	e022                	sd	s0,0(sp)
    80002680:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    80002682:	00006597          	auipc	a1,0x6
    80002686:	c6658593          	add	a1,a1,-922 # 800082e8 <states.0+0x28>
    8000268a:	00016517          	auipc	a0,0x16
    8000268e:	8de50513          	add	a0,a0,-1826 # 80017f68 <tickslock>
    80002692:	ffffe097          	auipc	ra,0xffffe
    80002696:	53e080e7          	jalr	1342(ra) # 80000bd0 <initlock>
}
    8000269a:	60a2                	ld	ra,8(sp)
    8000269c:	6402                	ld	s0,0(sp)
    8000269e:	0141                	add	sp,sp,16
    800026a0:	8082                	ret

00000000800026a2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026a2:	1141                	add	sp,sp,-16
    800026a4:	e422                	sd	s0,8(sp)
    800026a6:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026a8:	00003797          	auipc	a5,0x3
    800026ac:	55878793          	add	a5,a5,1368 # 80005c00 <kernelvec>
    800026b0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026b4:	6422                	ld	s0,8(sp)
    800026b6:	0141                	add	sp,sp,16
    800026b8:	8082                	ret

00000000800026ba <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026ba:	1141                	add	sp,sp,-16
    800026bc:	e406                	sd	ra,8(sp)
    800026be:	e022                	sd	s0,0(sp)
    800026c0:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    800026c2:	fffff097          	auipc	ra,0xfffff
    800026c6:	368080e7          	jalr	872(ra) # 80001a2a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026ce:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026d0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026d4:	00005697          	auipc	a3,0x5
    800026d8:	92c68693          	add	a3,a3,-1748 # 80007000 <_trampoline>
    800026dc:	00005717          	auipc	a4,0x5
    800026e0:	92470713          	add	a4,a4,-1756 # 80007000 <_trampoline>
    800026e4:	8f15                	sub	a4,a4,a3
    800026e6:	040007b7          	lui	a5,0x4000
    800026ea:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800026ec:	07b2                	sll	a5,a5,0xc
    800026ee:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026f0:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026f4:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026f6:	18002673          	csrr	a2,satp
    800026fa:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026fc:	6d30                	ld	a2,88(a0)
    800026fe:	6138                	ld	a4,64(a0)
    80002700:	6585                	lui	a1,0x1
    80002702:	972e                	add	a4,a4,a1
    80002704:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002706:	6d38                	ld	a4,88(a0)
    80002708:	00000617          	auipc	a2,0x0
    8000270c:	13c60613          	add	a2,a2,316 # 80002844 <usertrap>
    80002710:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002712:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002714:	8612                	mv	a2,tp
    80002716:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002718:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000271c:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002720:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002724:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002728:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000272a:	6f18                	ld	a4,24(a4)
    8000272c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002730:	692c                	ld	a1,80(a0)
    80002732:	81b1                	srl	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002734:	00005717          	auipc	a4,0x5
    80002738:	95c70713          	add	a4,a4,-1700 # 80007090 <userret>
    8000273c:	8f15                	sub	a4,a4,a3
    8000273e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002740:	577d                	li	a4,-1
    80002742:	177e                	sll	a4,a4,0x3f
    80002744:	8dd9                	or	a1,a1,a4
    80002746:	02000537          	lui	a0,0x2000
    8000274a:	157d                	add	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000274c:	0536                	sll	a0,a0,0xd
    8000274e:	9782                	jalr	a5
}
    80002750:	60a2                	ld	ra,8(sp)
    80002752:	6402                	ld	s0,0(sp)
    80002754:	0141                	add	sp,sp,16
    80002756:	8082                	ret

0000000080002758 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002758:	1101                	add	sp,sp,-32
    8000275a:	ec06                	sd	ra,24(sp)
    8000275c:	e822                	sd	s0,16(sp)
    8000275e:	e426                	sd	s1,8(sp)
    80002760:	1000                	add	s0,sp,32
  acquire(&tickslock);
    80002762:	00016497          	auipc	s1,0x16
    80002766:	80648493          	add	s1,s1,-2042 # 80017f68 <tickslock>
    8000276a:	8526                	mv	a0,s1
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	4f4080e7          	jalr	1268(ra) # 80000c60 <acquire>
  ticks++;
    80002774:	00007517          	auipc	a0,0x7
    80002778:	8ac50513          	add	a0,a0,-1876 # 80009020 <ticks>
    8000277c:	411c                	lw	a5,0(a0)
    8000277e:	2785                	addw	a5,a5,1
    80002780:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002782:	00000097          	auipc	ra,0x0
    80002786:	c58080e7          	jalr	-936(ra) # 800023da <wakeup>
  release(&tickslock);
    8000278a:	8526                	mv	a0,s1
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	588080e7          	jalr	1416(ra) # 80000d14 <release>
}
    80002794:	60e2                	ld	ra,24(sp)
    80002796:	6442                	ld	s0,16(sp)
    80002798:	64a2                	ld	s1,8(sp)
    8000279a:	6105                	add	sp,sp,32
    8000279c:	8082                	ret

000000008000279e <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000279e:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027a2:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    800027a4:	0807df63          	bgez	a5,80002842 <devintr+0xa4>
{
    800027a8:	1101                	add	sp,sp,-32
    800027aa:	ec06                	sd	ra,24(sp)
    800027ac:	e822                	sd	s0,16(sp)
    800027ae:	e426                	sd	s1,8(sp)
    800027b0:	1000                	add	s0,sp,32
     (scause & 0xff) == 9){
    800027b2:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    800027b6:	46a5                	li	a3,9
    800027b8:	00d70d63          	beq	a4,a3,800027d2 <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    800027bc:	577d                	li	a4,-1
    800027be:	177e                	sll	a4,a4,0x3f
    800027c0:	0705                	add	a4,a4,1
    return 0;
    800027c2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027c4:	04e78e63          	beq	a5,a4,80002820 <devintr+0x82>
  }
}
    800027c8:	60e2                	ld	ra,24(sp)
    800027ca:	6442                	ld	s0,16(sp)
    800027cc:	64a2                	ld	s1,8(sp)
    800027ce:	6105                	add	sp,sp,32
    800027d0:	8082                	ret
    int irq = plic_claim();
    800027d2:	00003097          	auipc	ra,0x3
    800027d6:	536080e7          	jalr	1334(ra) # 80005d08 <plic_claim>
    800027da:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027dc:	47a9                	li	a5,10
    800027de:	02f50763          	beq	a0,a5,8000280c <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    800027e2:	4785                	li	a5,1
    800027e4:	02f50963          	beq	a0,a5,80002816 <devintr+0x78>
    return 1;
    800027e8:	4505                	li	a0,1
    } else if(irq){
    800027ea:	dcf9                	beqz	s1,800027c8 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    800027ec:	85a6                	mv	a1,s1
    800027ee:	00006517          	auipc	a0,0x6
    800027f2:	b0250513          	add	a0,a0,-1278 # 800082f0 <states.0+0x30>
    800027f6:	ffffe097          	auipc	ra,0xffffe
    800027fa:	d9e080e7          	jalr	-610(ra) # 80000594 <printf>
      plic_complete(irq);
    800027fe:	8526                	mv	a0,s1
    80002800:	00003097          	auipc	ra,0x3
    80002804:	52c080e7          	jalr	1324(ra) # 80005d2c <plic_complete>
    return 1;
    80002808:	4505                	li	a0,1
    8000280a:	bf7d                	j	800027c8 <devintr+0x2a>
      uartintr();
    8000280c:	ffffe097          	auipc	ra,0xffffe
    80002810:	216080e7          	jalr	534(ra) # 80000a22 <uartintr>
    if(irq)
    80002814:	b7ed                	j	800027fe <devintr+0x60>
      virtio_disk_intr();
    80002816:	00004097          	auipc	ra,0x4
    8000281a:	988080e7          	jalr	-1656(ra) # 8000619e <virtio_disk_intr>
    if(irq)
    8000281e:	b7c5                	j	800027fe <devintr+0x60>
    if(cpuid() == 0){
    80002820:	fffff097          	auipc	ra,0xfffff
    80002824:	1de080e7          	jalr	478(ra) # 800019fe <cpuid>
    80002828:	c901                	beqz	a0,80002838 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000282a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000282e:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002830:	14479073          	csrw	sip,a5
    return 2;
    80002834:	4509                	li	a0,2
    80002836:	bf49                	j	800027c8 <devintr+0x2a>
      clockintr();
    80002838:	00000097          	auipc	ra,0x0
    8000283c:	f20080e7          	jalr	-224(ra) # 80002758 <clockintr>
    80002840:	b7ed                	j	8000282a <devintr+0x8c>
}
    80002842:	8082                	ret

0000000080002844 <usertrap>:
{
    80002844:	1101                	add	sp,sp,-32
    80002846:	ec06                	sd	ra,24(sp)
    80002848:	e822                	sd	s0,16(sp)
    8000284a:	e426                	sd	s1,8(sp)
    8000284c:	e04a                	sd	s2,0(sp)
    8000284e:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002850:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002854:	1007f793          	and	a5,a5,256
    80002858:	e3ad                	bnez	a5,800028ba <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000285a:	00003797          	auipc	a5,0x3
    8000285e:	3a678793          	add	a5,a5,934 # 80005c00 <kernelvec>
    80002862:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002866:	fffff097          	auipc	ra,0xfffff
    8000286a:	1c4080e7          	jalr	452(ra) # 80001a2a <myproc>
    8000286e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002870:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002872:	14102773          	csrr	a4,sepc
    80002876:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002878:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000287c:	47a1                	li	a5,8
    8000287e:	04f71c63          	bne	a4,a5,800028d6 <usertrap+0x92>
    if(p->killed)
    80002882:	591c                	lw	a5,48(a0)
    80002884:	e3b9                	bnez	a5,800028ca <usertrap+0x86>
    p->trapframe->epc += 4;
    80002886:	6cb8                	ld	a4,88(s1)
    80002888:	6f1c                	ld	a5,24(a4)
    8000288a:	0791                	add	a5,a5,4
    8000288c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000288e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002892:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002896:	10079073          	csrw	sstatus,a5
    syscall();
    8000289a:	00000097          	auipc	ra,0x0
    8000289e:	31a080e7          	jalr	794(ra) # 80002bb4 <syscall>
  if(p->killed)
    800028a2:	589c                	lw	a5,48(s1)
    800028a4:	e7c5                	bnez	a5,8000294c <usertrap+0x108>
  usertrapret();
    800028a6:	00000097          	auipc	ra,0x0
    800028aa:	e14080e7          	jalr	-492(ra) # 800026ba <usertrapret>
}
    800028ae:	60e2                	ld	ra,24(sp)
    800028b0:	6442                	ld	s0,16(sp)
    800028b2:	64a2                	ld	s1,8(sp)
    800028b4:	6902                	ld	s2,0(sp)
    800028b6:	6105                	add	sp,sp,32
    800028b8:	8082                	ret
    panic("usertrap: not from user mode");
    800028ba:	00006517          	auipc	a0,0x6
    800028be:	a5650513          	add	a0,a0,-1450 # 80008310 <states.0+0x50>
    800028c2:	ffffe097          	auipc	ra,0xffffe
    800028c6:	c80080e7          	jalr	-896(ra) # 80000542 <panic>
      exit(-1);
    800028ca:	557d                	li	a0,-1
    800028cc:	00000097          	auipc	ra,0x0
    800028d0:	848080e7          	jalr	-1976(ra) # 80002114 <exit>
    800028d4:	bf4d                	j	80002886 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800028d6:	00000097          	auipc	ra,0x0
    800028da:	ec8080e7          	jalr	-312(ra) # 8000279e <devintr>
    800028de:	892a                	mv	s2,a0
    800028e0:	c501                	beqz	a0,800028e8 <usertrap+0xa4>
  if(p->killed)
    800028e2:	589c                	lw	a5,48(s1)
    800028e4:	c3a1                	beqz	a5,80002924 <usertrap+0xe0>
    800028e6:	a815                	j	8000291a <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028e8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028ec:	5c90                	lw	a2,56(s1)
    800028ee:	00006517          	auipc	a0,0x6
    800028f2:	a4250513          	add	a0,a0,-1470 # 80008330 <states.0+0x70>
    800028f6:	ffffe097          	auipc	ra,0xffffe
    800028fa:	c9e080e7          	jalr	-866(ra) # 80000594 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028fe:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002902:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002906:	00006517          	auipc	a0,0x6
    8000290a:	a5a50513          	add	a0,a0,-1446 # 80008360 <states.0+0xa0>
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	c86080e7          	jalr	-890(ra) # 80000594 <printf>
    p->killed = 1;
    80002916:	4785                	li	a5,1
    80002918:	d89c                	sw	a5,48(s1)
    exit(-1);
    8000291a:	557d                	li	a0,-1
    8000291c:	fffff097          	auipc	ra,0xfffff
    80002920:	7f8080e7          	jalr	2040(ra) # 80002114 <exit>
  if(which_dev == 2)
    80002924:	4789                	li	a5,2
    80002926:	f8f910e3          	bne	s2,a5,800028a6 <usertrap+0x62>
    if(p->interval!=0&&++p->ticks==p->interval){
    8000292a:	1684a783          	lw	a5,360(s1)
    8000292e:	cb91                	beqz	a5,80002942 <usertrap+0xfe>
    80002930:	1784a703          	lw	a4,376(s1)
    80002934:	2705                	addw	a4,a4,1
    80002936:	0007069b          	sext.w	a3,a4
    8000293a:	16e4ac23          	sw	a4,376(s1)
    8000293e:	00d78963          	beq	a5,a3,80002950 <usertrap+0x10c>
    yield();
    80002942:	00000097          	auipc	ra,0x0
    80002946:	8dc080e7          	jalr	-1828(ra) # 8000221e <yield>
    8000294a:	bfb1                	j	800028a6 <usertrap+0x62>
  int which_dev = 0;
    8000294c:	4901                	li	s2,0
    8000294e:	b7f1                	j	8000291a <usertrap+0xd6>
      p->trapframecopy = p->trapframe + 512;  
    80002950:	6cac                	ld	a1,88(s1)
    80002952:	00024537          	lui	a0,0x24
    80002956:	952e                	add	a0,a0,a1
    80002958:	18a4b023          	sd	a0,384(s1)
      memmove(p->trapframecopy,p->trapframe,sizeof(struct trapframe));// copy trapframe
    8000295c:	12000613          	li	a2,288
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	458080e7          	jalr	1112(ra) # 80000db8 <memmove>
      p->trapframe->epc = p->handler;
    80002968:	6cbc                	ld	a5,88(s1)
    8000296a:	1704b703          	ld	a4,368(s1)
    8000296e:	ef98                	sd	a4,24(a5)
    80002970:	bfc9                	j	80002942 <usertrap+0xfe>

0000000080002972 <kerneltrap>:
{
    80002972:	7179                	add	sp,sp,-48
    80002974:	f406                	sd	ra,40(sp)
    80002976:	f022                	sd	s0,32(sp)
    80002978:	ec26                	sd	s1,24(sp)
    8000297a:	e84a                	sd	s2,16(sp)
    8000297c:	e44e                	sd	s3,8(sp)
    8000297e:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002980:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002984:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002988:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000298c:	1004f793          	and	a5,s1,256
    80002990:	cb85                	beqz	a5,800029c0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002992:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002996:	8b89                	and	a5,a5,2
  if(intr_get() != 0)
    80002998:	ef85                	bnez	a5,800029d0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000299a:	00000097          	auipc	ra,0x0
    8000299e:	e04080e7          	jalr	-508(ra) # 8000279e <devintr>
    800029a2:	cd1d                	beqz	a0,800029e0 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029a4:	4789                	li	a5,2
    800029a6:	06f50a63          	beq	a0,a5,80002a1a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029aa:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ae:	10049073          	csrw	sstatus,s1
}
    800029b2:	70a2                	ld	ra,40(sp)
    800029b4:	7402                	ld	s0,32(sp)
    800029b6:	64e2                	ld	s1,24(sp)
    800029b8:	6942                	ld	s2,16(sp)
    800029ba:	69a2                	ld	s3,8(sp)
    800029bc:	6145                	add	sp,sp,48
    800029be:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029c0:	00006517          	auipc	a0,0x6
    800029c4:	9c050513          	add	a0,a0,-1600 # 80008380 <states.0+0xc0>
    800029c8:	ffffe097          	auipc	ra,0xffffe
    800029cc:	b7a080e7          	jalr	-1158(ra) # 80000542 <panic>
    panic("kerneltrap: interrupts enabled");
    800029d0:	00006517          	auipc	a0,0x6
    800029d4:	9d850513          	add	a0,a0,-1576 # 800083a8 <states.0+0xe8>
    800029d8:	ffffe097          	auipc	ra,0xffffe
    800029dc:	b6a080e7          	jalr	-1174(ra) # 80000542 <panic>
    printf("scause %p\n", scause);
    800029e0:	85ce                	mv	a1,s3
    800029e2:	00006517          	auipc	a0,0x6
    800029e6:	9e650513          	add	a0,a0,-1562 # 800083c8 <states.0+0x108>
    800029ea:	ffffe097          	auipc	ra,0xffffe
    800029ee:	baa080e7          	jalr	-1110(ra) # 80000594 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029f6:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029fa:	00006517          	auipc	a0,0x6
    800029fe:	9de50513          	add	a0,a0,-1570 # 800083d8 <states.0+0x118>
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	b92080e7          	jalr	-1134(ra) # 80000594 <printf>
    panic("kerneltrap");
    80002a0a:	00006517          	auipc	a0,0x6
    80002a0e:	9e650513          	add	a0,a0,-1562 # 800083f0 <states.0+0x130>
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	b30080e7          	jalr	-1232(ra) # 80000542 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a1a:	fffff097          	auipc	ra,0xfffff
    80002a1e:	010080e7          	jalr	16(ra) # 80001a2a <myproc>
    80002a22:	d541                	beqz	a0,800029aa <kerneltrap+0x38>
    80002a24:	fffff097          	auipc	ra,0xfffff
    80002a28:	006080e7          	jalr	6(ra) # 80001a2a <myproc>
    80002a2c:	4d18                	lw	a4,24(a0)
    80002a2e:	478d                	li	a5,3
    80002a30:	f6f71de3          	bne	a4,a5,800029aa <kerneltrap+0x38>
    yield();
    80002a34:	fffff097          	auipc	ra,0xfffff
    80002a38:	7ea080e7          	jalr	2026(ra) # 8000221e <yield>
    80002a3c:	b7bd                	j	800029aa <kerneltrap+0x38>

0000000080002a3e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a3e:	1101                	add	sp,sp,-32
    80002a40:	ec06                	sd	ra,24(sp)
    80002a42:	e822                	sd	s0,16(sp)
    80002a44:	e426                	sd	s1,8(sp)
    80002a46:	1000                	add	s0,sp,32
    80002a48:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a4a:	fffff097          	auipc	ra,0xfffff
    80002a4e:	fe0080e7          	jalr	-32(ra) # 80001a2a <myproc>
  switch (n) {
    80002a52:	4795                	li	a5,5
    80002a54:	0497e163          	bltu	a5,s1,80002a96 <argraw+0x58>
    80002a58:	048a                	sll	s1,s1,0x2
    80002a5a:	00006717          	auipc	a4,0x6
    80002a5e:	9ce70713          	add	a4,a4,-1586 # 80008428 <states.0+0x168>
    80002a62:	94ba                	add	s1,s1,a4
    80002a64:	409c                	lw	a5,0(s1)
    80002a66:	97ba                	add	a5,a5,a4
    80002a68:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a6a:	6d3c                	ld	a5,88(a0)
    80002a6c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a6e:	60e2                	ld	ra,24(sp)
    80002a70:	6442                	ld	s0,16(sp)
    80002a72:	64a2                	ld	s1,8(sp)
    80002a74:	6105                	add	sp,sp,32
    80002a76:	8082                	ret
    return p->trapframe->a1;
    80002a78:	6d3c                	ld	a5,88(a0)
    80002a7a:	7fa8                	ld	a0,120(a5)
    80002a7c:	bfcd                	j	80002a6e <argraw+0x30>
    return p->trapframe->a2;
    80002a7e:	6d3c                	ld	a5,88(a0)
    80002a80:	63c8                	ld	a0,128(a5)
    80002a82:	b7f5                	j	80002a6e <argraw+0x30>
    return p->trapframe->a3;
    80002a84:	6d3c                	ld	a5,88(a0)
    80002a86:	67c8                	ld	a0,136(a5)
    80002a88:	b7dd                	j	80002a6e <argraw+0x30>
    return p->trapframe->a4;
    80002a8a:	6d3c                	ld	a5,88(a0)
    80002a8c:	6bc8                	ld	a0,144(a5)
    80002a8e:	b7c5                	j	80002a6e <argraw+0x30>
    return p->trapframe->a5;
    80002a90:	6d3c                	ld	a5,88(a0)
    80002a92:	6fc8                	ld	a0,152(a5)
    80002a94:	bfe9                	j	80002a6e <argraw+0x30>
  panic("argraw");
    80002a96:	00006517          	auipc	a0,0x6
    80002a9a:	96a50513          	add	a0,a0,-1686 # 80008400 <states.0+0x140>
    80002a9e:	ffffe097          	auipc	ra,0xffffe
    80002aa2:	aa4080e7          	jalr	-1372(ra) # 80000542 <panic>

0000000080002aa6 <fetchaddr>:
{
    80002aa6:	1101                	add	sp,sp,-32
    80002aa8:	ec06                	sd	ra,24(sp)
    80002aaa:	e822                	sd	s0,16(sp)
    80002aac:	e426                	sd	s1,8(sp)
    80002aae:	e04a                	sd	s2,0(sp)
    80002ab0:	1000                	add	s0,sp,32
    80002ab2:	84aa                	mv	s1,a0
    80002ab4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ab6:	fffff097          	auipc	ra,0xfffff
    80002aba:	f74080e7          	jalr	-140(ra) # 80001a2a <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002abe:	653c                	ld	a5,72(a0)
    80002ac0:	02f4f863          	bgeu	s1,a5,80002af0 <fetchaddr+0x4a>
    80002ac4:	00848713          	add	a4,s1,8
    80002ac8:	02e7e663          	bltu	a5,a4,80002af4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002acc:	46a1                	li	a3,8
    80002ace:	8626                	mv	a2,s1
    80002ad0:	85ca                	mv	a1,s2
    80002ad2:	6928                	ld	a0,80(a0)
    80002ad4:	fffff097          	auipc	ra,0xfffff
    80002ad8:	cd8080e7          	jalr	-808(ra) # 800017ac <copyin>
    80002adc:	00a03533          	snez	a0,a0
    80002ae0:	40a00533          	neg	a0,a0
}
    80002ae4:	60e2                	ld	ra,24(sp)
    80002ae6:	6442                	ld	s0,16(sp)
    80002ae8:	64a2                	ld	s1,8(sp)
    80002aea:	6902                	ld	s2,0(sp)
    80002aec:	6105                	add	sp,sp,32
    80002aee:	8082                	ret
    return -1;
    80002af0:	557d                	li	a0,-1
    80002af2:	bfcd                	j	80002ae4 <fetchaddr+0x3e>
    80002af4:	557d                	li	a0,-1
    80002af6:	b7fd                	j	80002ae4 <fetchaddr+0x3e>

0000000080002af8 <fetchstr>:
{
    80002af8:	7179                	add	sp,sp,-48
    80002afa:	f406                	sd	ra,40(sp)
    80002afc:	f022                	sd	s0,32(sp)
    80002afe:	ec26                	sd	s1,24(sp)
    80002b00:	e84a                	sd	s2,16(sp)
    80002b02:	e44e                	sd	s3,8(sp)
    80002b04:	1800                	add	s0,sp,48
    80002b06:	892a                	mv	s2,a0
    80002b08:	84ae                	mv	s1,a1
    80002b0a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b0c:	fffff097          	auipc	ra,0xfffff
    80002b10:	f1e080e7          	jalr	-226(ra) # 80001a2a <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b14:	86ce                	mv	a3,s3
    80002b16:	864a                	mv	a2,s2
    80002b18:	85a6                	mv	a1,s1
    80002b1a:	6928                	ld	a0,80(a0)
    80002b1c:	fffff097          	auipc	ra,0xfffff
    80002b20:	d1e080e7          	jalr	-738(ra) # 8000183a <copyinstr>
  if(err < 0)
    80002b24:	00054763          	bltz	a0,80002b32 <fetchstr+0x3a>
  return strlen(buf);
    80002b28:	8526                	mv	a0,s1
    80002b2a:	ffffe097          	auipc	ra,0xffffe
    80002b2e:	3b4080e7          	jalr	948(ra) # 80000ede <strlen>
}
    80002b32:	70a2                	ld	ra,40(sp)
    80002b34:	7402                	ld	s0,32(sp)
    80002b36:	64e2                	ld	s1,24(sp)
    80002b38:	6942                	ld	s2,16(sp)
    80002b3a:	69a2                	ld	s3,8(sp)
    80002b3c:	6145                	add	sp,sp,48
    80002b3e:	8082                	ret

0000000080002b40 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b40:	1101                	add	sp,sp,-32
    80002b42:	ec06                	sd	ra,24(sp)
    80002b44:	e822                	sd	s0,16(sp)
    80002b46:	e426                	sd	s1,8(sp)
    80002b48:	1000                	add	s0,sp,32
    80002b4a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b4c:	00000097          	auipc	ra,0x0
    80002b50:	ef2080e7          	jalr	-270(ra) # 80002a3e <argraw>
    80002b54:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b56:	4501                	li	a0,0
    80002b58:	60e2                	ld	ra,24(sp)
    80002b5a:	6442                	ld	s0,16(sp)
    80002b5c:	64a2                	ld	s1,8(sp)
    80002b5e:	6105                	add	sp,sp,32
    80002b60:	8082                	ret

0000000080002b62 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b62:	1101                	add	sp,sp,-32
    80002b64:	ec06                	sd	ra,24(sp)
    80002b66:	e822                	sd	s0,16(sp)
    80002b68:	e426                	sd	s1,8(sp)
    80002b6a:	1000                	add	s0,sp,32
    80002b6c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b6e:	00000097          	auipc	ra,0x0
    80002b72:	ed0080e7          	jalr	-304(ra) # 80002a3e <argraw>
    80002b76:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b78:	4501                	li	a0,0
    80002b7a:	60e2                	ld	ra,24(sp)
    80002b7c:	6442                	ld	s0,16(sp)
    80002b7e:	64a2                	ld	s1,8(sp)
    80002b80:	6105                	add	sp,sp,32
    80002b82:	8082                	ret

0000000080002b84 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b84:	1101                	add	sp,sp,-32
    80002b86:	ec06                	sd	ra,24(sp)
    80002b88:	e822                	sd	s0,16(sp)
    80002b8a:	e426                	sd	s1,8(sp)
    80002b8c:	e04a                	sd	s2,0(sp)
    80002b8e:	1000                	add	s0,sp,32
    80002b90:	84ae                	mv	s1,a1
    80002b92:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b94:	00000097          	auipc	ra,0x0
    80002b98:	eaa080e7          	jalr	-342(ra) # 80002a3e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b9c:	864a                	mv	a2,s2
    80002b9e:	85a6                	mv	a1,s1
    80002ba0:	00000097          	auipc	ra,0x0
    80002ba4:	f58080e7          	jalr	-168(ra) # 80002af8 <fetchstr>
}
    80002ba8:	60e2                	ld	ra,24(sp)
    80002baa:	6442                	ld	s0,16(sp)
    80002bac:	64a2                	ld	s1,8(sp)
    80002bae:	6902                	ld	s2,0(sp)
    80002bb0:	6105                	add	sp,sp,32
    80002bb2:	8082                	ret

0000000080002bb4 <syscall>:
[SYS_sigreturn]   sys_sigreturn,
};

void
syscall(void)
{
    80002bb4:	1101                	add	sp,sp,-32
    80002bb6:	ec06                	sd	ra,24(sp)
    80002bb8:	e822                	sd	s0,16(sp)
    80002bba:	e426                	sd	s1,8(sp)
    80002bbc:	e04a                	sd	s2,0(sp)
    80002bbe:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bc0:	fffff097          	auipc	ra,0xfffff
    80002bc4:	e6a080e7          	jalr	-406(ra) # 80001a2a <myproc>
    80002bc8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bca:	05853903          	ld	s2,88(a0)
    80002bce:	0a893783          	ld	a5,168(s2)
    80002bd2:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bd6:	37fd                	addw	a5,a5,-1
    80002bd8:	4759                	li	a4,22
    80002bda:	00f76f63          	bltu	a4,a5,80002bf8 <syscall+0x44>
    80002bde:	00369713          	sll	a4,a3,0x3
    80002be2:	00006797          	auipc	a5,0x6
    80002be6:	85e78793          	add	a5,a5,-1954 # 80008440 <syscalls>
    80002bea:	97ba                	add	a5,a5,a4
    80002bec:	639c                	ld	a5,0(a5)
    80002bee:	c789                	beqz	a5,80002bf8 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002bf0:	9782                	jalr	a5
    80002bf2:	06a93823          	sd	a0,112(s2)
    80002bf6:	a839                	j	80002c14 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002bf8:	15848613          	add	a2,s1,344
    80002bfc:	5c8c                	lw	a1,56(s1)
    80002bfe:	00006517          	auipc	a0,0x6
    80002c02:	80a50513          	add	a0,a0,-2038 # 80008408 <states.0+0x148>
    80002c06:	ffffe097          	auipc	ra,0xffffe
    80002c0a:	98e080e7          	jalr	-1650(ra) # 80000594 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c0e:	6cbc                	ld	a5,88(s1)
    80002c10:	577d                	li	a4,-1
    80002c12:	fbb8                	sd	a4,112(a5)
  }
}
    80002c14:	60e2                	ld	ra,24(sp)
    80002c16:	6442                	ld	s0,16(sp)
    80002c18:	64a2                	ld	s1,8(sp)
    80002c1a:	6902                	ld	s2,0(sp)
    80002c1c:	6105                	add	sp,sp,32
    80002c1e:	8082                	ret

0000000080002c20 <sys_sigalarm>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_sigalarm(void)
{
    80002c20:	1101                	add	sp,sp,-32
    80002c22:	ec06                	sd	ra,24(sp)
    80002c24:	e822                	sd	s0,16(sp)
    80002c26:	1000                	add	s0,sp,32
  int interval;
  uint64 handler;
  if(argint(0,&interval)<0||argaddr(1, &handler)<0||interval<0)
    80002c28:	fec40593          	add	a1,s0,-20
    80002c2c:	4501                	li	a0,0
    80002c2e:	00000097          	auipc	ra,0x0
    80002c32:	f12080e7          	jalr	-238(ra) # 80002b40 <argint>
    return -1;
    80002c36:	577d                	li	a4,-1
  if(argint(0,&interval)<0||argaddr(1, &handler)<0||interval<0)
    80002c38:	02054f63          	bltz	a0,80002c76 <sys_sigalarm+0x56>
    80002c3c:	fe040593          	add	a1,s0,-32
    80002c40:	4505                	li	a0,1
    80002c42:	00000097          	auipc	ra,0x0
    80002c46:	f20080e7          	jalr	-224(ra) # 80002b62 <argaddr>
    80002c4a:	fec42783          	lw	a5,-20(s0)
    80002c4e:	8fc9                	or	a5,a5,a0
    80002c50:	2781                	sext.w	a5,a5
    return -1;
    80002c52:	577d                	li	a4,-1
  if(argint(0,&interval)<0||argaddr(1, &handler)<0||interval<0)
    80002c54:	0207c163          	bltz	a5,80002c76 <sys_sigalarm+0x56>
  struct proc *p=myproc();
    80002c58:	fffff097          	auipc	ra,0xfffff
    80002c5c:	dd2080e7          	jalr	-558(ra) # 80001a2a <myproc>
  p->interval=interval;
    80002c60:	fec42783          	lw	a5,-20(s0)
    80002c64:	16f52423          	sw	a5,360(a0)
  p->handler=handler;
    80002c68:	fe043783          	ld	a5,-32(s0)
    80002c6c:	16f53823          	sd	a5,368(a0)
  p->ticks=0;
    80002c70:	16052c23          	sw	zero,376(a0)
  return 0;
    80002c74:	4701                	li	a4,0
}
    80002c76:	853a                	mv	a0,a4
    80002c78:	60e2                	ld	ra,24(sp)
    80002c7a:	6442                	ld	s0,16(sp)
    80002c7c:	6105                	add	sp,sp,32
    80002c7e:	8082                	ret

0000000080002c80 <sys_sigreturn>:

uint64
sys_sigreturn(void)
{
    80002c80:	1101                	add	sp,sp,-32
    80002c82:	ec06                	sd	ra,24(sp)
    80002c84:	e822                	sd	s0,16(sp)
    80002c86:	e426                	sd	s1,8(sp)
    80002c88:	1000                	add	s0,sp,32
  struct proc *p=myproc();
    80002c8a:	fffff097          	auipc	ra,0xfffff
    80002c8e:	da0080e7          	jalr	-608(ra) # 80001a2a <myproc>
    80002c92:	84aa                	mv	s1,a0
  if(p->trapframecopy!=p->trapframe+512) return -1;
    80002c94:	18053583          	ld	a1,384(a0)
    80002c98:	6d38                	ld	a4,88(a0)
    80002c9a:	000247b7          	lui	a5,0x24
    80002c9e:	97ba                	add	a5,a5,a4
    80002ca0:	557d                	li	a0,-1
    80002ca2:	00f58763          	beq	a1,a5,80002cb0 <sys_sigreturn+0x30>
  memmove(p->trapframe, p->trapframecopy,sizeof(struct trapframe));
  p->ticks=0;
  p->trapframecopy=0;
  return 0;
}
    80002ca6:	60e2                	ld	ra,24(sp)
    80002ca8:	6442                	ld	s0,16(sp)
    80002caa:	64a2                	ld	s1,8(sp)
    80002cac:	6105                	add	sp,sp,32
    80002cae:	8082                	ret
  memmove(p->trapframe, p->trapframecopy,sizeof(struct trapframe));
    80002cb0:	12000613          	li	a2,288
    80002cb4:	853a                	mv	a0,a4
    80002cb6:	ffffe097          	auipc	ra,0xffffe
    80002cba:	102080e7          	jalr	258(ra) # 80000db8 <memmove>
  p->ticks=0;
    80002cbe:	1604ac23          	sw	zero,376(s1)
  p->trapframecopy=0;
    80002cc2:	1804b023          	sd	zero,384(s1)
  return 0;
    80002cc6:	4501                	li	a0,0
    80002cc8:	bff9                	j	80002ca6 <sys_sigreturn+0x26>

0000000080002cca <sys_exit>:

uint64
sys_exit(void)
{
    80002cca:	1101                	add	sp,sp,-32
    80002ccc:	ec06                	sd	ra,24(sp)
    80002cce:	e822                	sd	s0,16(sp)
    80002cd0:	1000                	add	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002cd2:	fec40593          	add	a1,s0,-20
    80002cd6:	4501                	li	a0,0
    80002cd8:	00000097          	auipc	ra,0x0
    80002cdc:	e68080e7          	jalr	-408(ra) # 80002b40 <argint>
    return -1;
    80002ce0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ce2:	00054963          	bltz	a0,80002cf4 <sys_exit+0x2a>
  exit(n);
    80002ce6:	fec42503          	lw	a0,-20(s0)
    80002cea:	fffff097          	auipc	ra,0xfffff
    80002cee:	42a080e7          	jalr	1066(ra) # 80002114 <exit>
  return 0;  // not reached
    80002cf2:	4781                	li	a5,0
}
    80002cf4:	853e                	mv	a0,a5
    80002cf6:	60e2                	ld	ra,24(sp)
    80002cf8:	6442                	ld	s0,16(sp)
    80002cfa:	6105                	add	sp,sp,32
    80002cfc:	8082                	ret

0000000080002cfe <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cfe:	1141                	add	sp,sp,-16
    80002d00:	e406                	sd	ra,8(sp)
    80002d02:	e022                	sd	s0,0(sp)
    80002d04:	0800                	add	s0,sp,16
  return myproc()->pid;
    80002d06:	fffff097          	auipc	ra,0xfffff
    80002d0a:	d24080e7          	jalr	-732(ra) # 80001a2a <myproc>
}
    80002d0e:	5d08                	lw	a0,56(a0)
    80002d10:	60a2                	ld	ra,8(sp)
    80002d12:	6402                	ld	s0,0(sp)
    80002d14:	0141                	add	sp,sp,16
    80002d16:	8082                	ret

0000000080002d18 <sys_fork>:

uint64
sys_fork(void)
{
    80002d18:	1141                	add	sp,sp,-16
    80002d1a:	e406                	sd	ra,8(sp)
    80002d1c:	e022                	sd	s0,0(sp)
    80002d1e:	0800                	add	s0,sp,16
  return fork();
    80002d20:	fffff097          	auipc	ra,0xfffff
    80002d24:	0ea080e7          	jalr	234(ra) # 80001e0a <fork>
}
    80002d28:	60a2                	ld	ra,8(sp)
    80002d2a:	6402                	ld	s0,0(sp)
    80002d2c:	0141                	add	sp,sp,16
    80002d2e:	8082                	ret

0000000080002d30 <sys_wait>:

uint64
sys_wait(void)
{
    80002d30:	1101                	add	sp,sp,-32
    80002d32:	ec06                	sd	ra,24(sp)
    80002d34:	e822                	sd	s0,16(sp)
    80002d36:	1000                	add	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d38:	fe840593          	add	a1,s0,-24
    80002d3c:	4501                	li	a0,0
    80002d3e:	00000097          	auipc	ra,0x0
    80002d42:	e24080e7          	jalr	-476(ra) # 80002b62 <argaddr>
    80002d46:	87aa                	mv	a5,a0
    return -1;
    80002d48:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d4a:	0007c863          	bltz	a5,80002d5a <sys_wait+0x2a>
  return wait(p);
    80002d4e:	fe843503          	ld	a0,-24(s0)
    80002d52:	fffff097          	auipc	ra,0xfffff
    80002d56:	586080e7          	jalr	1414(ra) # 800022d8 <wait>
}
    80002d5a:	60e2                	ld	ra,24(sp)
    80002d5c:	6442                	ld	s0,16(sp)
    80002d5e:	6105                	add	sp,sp,32
    80002d60:	8082                	ret

0000000080002d62 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d62:	7179                	add	sp,sp,-48
    80002d64:	f406                	sd	ra,40(sp)
    80002d66:	f022                	sd	s0,32(sp)
    80002d68:	ec26                	sd	s1,24(sp)
    80002d6a:	1800                	add	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d6c:	fdc40593          	add	a1,s0,-36
    80002d70:	4501                	li	a0,0
    80002d72:	00000097          	auipc	ra,0x0
    80002d76:	dce080e7          	jalr	-562(ra) # 80002b40 <argint>
    80002d7a:	87aa                	mv	a5,a0
    return -1;
    80002d7c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d7e:	0207c063          	bltz	a5,80002d9e <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d82:	fffff097          	auipc	ra,0xfffff
    80002d86:	ca8080e7          	jalr	-856(ra) # 80001a2a <myproc>
    80002d8a:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d8c:	fdc42503          	lw	a0,-36(s0)
    80002d90:	fffff097          	auipc	ra,0xfffff
    80002d94:	002080e7          	jalr	2(ra) # 80001d92 <growproc>
    80002d98:	00054863          	bltz	a0,80002da8 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d9c:	8526                	mv	a0,s1
}
    80002d9e:	70a2                	ld	ra,40(sp)
    80002da0:	7402                	ld	s0,32(sp)
    80002da2:	64e2                	ld	s1,24(sp)
    80002da4:	6145                	add	sp,sp,48
    80002da6:	8082                	ret
    return -1;
    80002da8:	557d                	li	a0,-1
    80002daa:	bfd5                	j	80002d9e <sys_sbrk+0x3c>

0000000080002dac <sys_sleep>:

uint64
sys_sleep(void)
{
    80002dac:	7139                	add	sp,sp,-64
    80002dae:	fc06                	sd	ra,56(sp)
    80002db0:	f822                	sd	s0,48(sp)
    80002db2:	f426                	sd	s1,40(sp)
    80002db4:	f04a                	sd	s2,32(sp)
    80002db6:	ec4e                	sd	s3,24(sp)
    80002db8:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002dba:	fcc40593          	add	a1,s0,-52
    80002dbe:	4501                	li	a0,0
    80002dc0:	00000097          	auipc	ra,0x0
    80002dc4:	d80080e7          	jalr	-640(ra) # 80002b40 <argint>
    return -1;
    80002dc8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002dca:	06054963          	bltz	a0,80002e3c <sys_sleep+0x90>
  acquire(&tickslock);
    80002dce:	00015517          	auipc	a0,0x15
    80002dd2:	19a50513          	add	a0,a0,410 # 80017f68 <tickslock>
    80002dd6:	ffffe097          	auipc	ra,0xffffe
    80002dda:	e8a080e7          	jalr	-374(ra) # 80000c60 <acquire>
  ticks0 = ticks;
    80002dde:	00006917          	auipc	s2,0x6
    80002de2:	24292903          	lw	s2,578(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002de6:	fcc42783          	lw	a5,-52(s0)
    80002dea:	cf85                	beqz	a5,80002e22 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002dec:	00015997          	auipc	s3,0x15
    80002df0:	17c98993          	add	s3,s3,380 # 80017f68 <tickslock>
    80002df4:	00006497          	auipc	s1,0x6
    80002df8:	22c48493          	add	s1,s1,556 # 80009020 <ticks>
    if(myproc()->killed){
    80002dfc:	fffff097          	auipc	ra,0xfffff
    80002e00:	c2e080e7          	jalr	-978(ra) # 80001a2a <myproc>
    80002e04:	591c                	lw	a5,48(a0)
    80002e06:	e3b9                	bnez	a5,80002e4c <sys_sleep+0xa0>
    sleep(&ticks, &tickslock);
    80002e08:	85ce                	mv	a1,s3
    80002e0a:	8526                	mv	a0,s1
    80002e0c:	fffff097          	auipc	ra,0xfffff
    80002e10:	44e080e7          	jalr	1102(ra) # 8000225a <sleep>
  while(ticks - ticks0 < n){
    80002e14:	409c                	lw	a5,0(s1)
    80002e16:	412787bb          	subw	a5,a5,s2
    80002e1a:	fcc42703          	lw	a4,-52(s0)
    80002e1e:	fce7efe3          	bltu	a5,a4,80002dfc <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e22:	00015517          	auipc	a0,0x15
    80002e26:	14650513          	add	a0,a0,326 # 80017f68 <tickslock>
    80002e2a:	ffffe097          	auipc	ra,0xffffe
    80002e2e:	eea080e7          	jalr	-278(ra) # 80000d14 <release>
  backtrace();
    80002e32:	ffffe097          	auipc	ra,0xffffe
    80002e36:	942080e7          	jalr	-1726(ra) # 80000774 <backtrace>
  return 0;
    80002e3a:	4781                	li	a5,0
}
    80002e3c:	853e                	mv	a0,a5
    80002e3e:	70e2                	ld	ra,56(sp)
    80002e40:	7442                	ld	s0,48(sp)
    80002e42:	74a2                	ld	s1,40(sp)
    80002e44:	7902                	ld	s2,32(sp)
    80002e46:	69e2                	ld	s3,24(sp)
    80002e48:	6121                	add	sp,sp,64
    80002e4a:	8082                	ret
      release(&tickslock);
    80002e4c:	00015517          	auipc	a0,0x15
    80002e50:	11c50513          	add	a0,a0,284 # 80017f68 <tickslock>
    80002e54:	ffffe097          	auipc	ra,0xffffe
    80002e58:	ec0080e7          	jalr	-320(ra) # 80000d14 <release>
      return -1;
    80002e5c:	57fd                	li	a5,-1
    80002e5e:	bff9                	j	80002e3c <sys_sleep+0x90>

0000000080002e60 <sys_kill>:

uint64
sys_kill(void)
{
    80002e60:	1101                	add	sp,sp,-32
    80002e62:	ec06                	sd	ra,24(sp)
    80002e64:	e822                	sd	s0,16(sp)
    80002e66:	1000                	add	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e68:	fec40593          	add	a1,s0,-20
    80002e6c:	4501                	li	a0,0
    80002e6e:	00000097          	auipc	ra,0x0
    80002e72:	cd2080e7          	jalr	-814(ra) # 80002b40 <argint>
    80002e76:	87aa                	mv	a5,a0
    return -1;
    80002e78:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e7a:	0007c863          	bltz	a5,80002e8a <sys_kill+0x2a>
  return kill(pid);
    80002e7e:	fec42503          	lw	a0,-20(s0)
    80002e82:	fffff097          	auipc	ra,0xfffff
    80002e86:	5c2080e7          	jalr	1474(ra) # 80002444 <kill>
}
    80002e8a:	60e2                	ld	ra,24(sp)
    80002e8c:	6442                	ld	s0,16(sp)
    80002e8e:	6105                	add	sp,sp,32
    80002e90:	8082                	ret

0000000080002e92 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e92:	1101                	add	sp,sp,-32
    80002e94:	ec06                	sd	ra,24(sp)
    80002e96:	e822                	sd	s0,16(sp)
    80002e98:	e426                	sd	s1,8(sp)
    80002e9a:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e9c:	00015517          	auipc	a0,0x15
    80002ea0:	0cc50513          	add	a0,a0,204 # 80017f68 <tickslock>
    80002ea4:	ffffe097          	auipc	ra,0xffffe
    80002ea8:	dbc080e7          	jalr	-580(ra) # 80000c60 <acquire>
  xticks = ticks;
    80002eac:	00006497          	auipc	s1,0x6
    80002eb0:	1744a483          	lw	s1,372(s1) # 80009020 <ticks>
  release(&tickslock);
    80002eb4:	00015517          	auipc	a0,0x15
    80002eb8:	0b450513          	add	a0,a0,180 # 80017f68 <tickslock>
    80002ebc:	ffffe097          	auipc	ra,0xffffe
    80002ec0:	e58080e7          	jalr	-424(ra) # 80000d14 <release>
  return xticks;
}
    80002ec4:	02049513          	sll	a0,s1,0x20
    80002ec8:	9101                	srl	a0,a0,0x20
    80002eca:	60e2                	ld	ra,24(sp)
    80002ecc:	6442                	ld	s0,16(sp)
    80002ece:	64a2                	ld	s1,8(sp)
    80002ed0:	6105                	add	sp,sp,32
    80002ed2:	8082                	ret

0000000080002ed4 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ed4:	7179                	add	sp,sp,-48
    80002ed6:	f406                	sd	ra,40(sp)
    80002ed8:	f022                	sd	s0,32(sp)
    80002eda:	ec26                	sd	s1,24(sp)
    80002edc:	e84a                	sd	s2,16(sp)
    80002ede:	e44e                	sd	s3,8(sp)
    80002ee0:	e052                	sd	s4,0(sp)
    80002ee2:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ee4:	00005597          	auipc	a1,0x5
    80002ee8:	61c58593          	add	a1,a1,1564 # 80008500 <syscalls+0xc0>
    80002eec:	00015517          	auipc	a0,0x15
    80002ef0:	09450513          	add	a0,a0,148 # 80017f80 <bcache>
    80002ef4:	ffffe097          	auipc	ra,0xffffe
    80002ef8:	cdc080e7          	jalr	-804(ra) # 80000bd0 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002efc:	0001d797          	auipc	a5,0x1d
    80002f00:	08478793          	add	a5,a5,132 # 8001ff80 <bcache+0x8000>
    80002f04:	0001d717          	auipc	a4,0x1d
    80002f08:	2e470713          	add	a4,a4,740 # 800201e8 <bcache+0x8268>
    80002f0c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f10:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f14:	00015497          	auipc	s1,0x15
    80002f18:	08448493          	add	s1,s1,132 # 80017f98 <bcache+0x18>
    b->next = bcache.head.next;
    80002f1c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f1e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f20:	00005a17          	auipc	s4,0x5
    80002f24:	5e8a0a13          	add	s4,s4,1512 # 80008508 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f28:	2b893783          	ld	a5,696(s2)
    80002f2c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f2e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f32:	85d2                	mv	a1,s4
    80002f34:	01048513          	add	a0,s1,16
    80002f38:	00001097          	auipc	ra,0x1
    80002f3c:	480080e7          	jalr	1152(ra) # 800043b8 <initsleeplock>
    bcache.head.next->prev = b;
    80002f40:	2b893783          	ld	a5,696(s2)
    80002f44:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f46:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f4a:	45848493          	add	s1,s1,1112
    80002f4e:	fd349de3          	bne	s1,s3,80002f28 <binit+0x54>
  }
}
    80002f52:	70a2                	ld	ra,40(sp)
    80002f54:	7402                	ld	s0,32(sp)
    80002f56:	64e2                	ld	s1,24(sp)
    80002f58:	6942                	ld	s2,16(sp)
    80002f5a:	69a2                	ld	s3,8(sp)
    80002f5c:	6a02                	ld	s4,0(sp)
    80002f5e:	6145                	add	sp,sp,48
    80002f60:	8082                	ret

0000000080002f62 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f62:	7179                	add	sp,sp,-48
    80002f64:	f406                	sd	ra,40(sp)
    80002f66:	f022                	sd	s0,32(sp)
    80002f68:	ec26                	sd	s1,24(sp)
    80002f6a:	e84a                	sd	s2,16(sp)
    80002f6c:	e44e                	sd	s3,8(sp)
    80002f6e:	1800                	add	s0,sp,48
    80002f70:	892a                	mv	s2,a0
    80002f72:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f74:	00015517          	auipc	a0,0x15
    80002f78:	00c50513          	add	a0,a0,12 # 80017f80 <bcache>
    80002f7c:	ffffe097          	auipc	ra,0xffffe
    80002f80:	ce4080e7          	jalr	-796(ra) # 80000c60 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f84:	0001d497          	auipc	s1,0x1d
    80002f88:	2b44b483          	ld	s1,692(s1) # 80020238 <bcache+0x82b8>
    80002f8c:	0001d797          	auipc	a5,0x1d
    80002f90:	25c78793          	add	a5,a5,604 # 800201e8 <bcache+0x8268>
    80002f94:	02f48f63          	beq	s1,a5,80002fd2 <bread+0x70>
    80002f98:	873e                	mv	a4,a5
    80002f9a:	a021                	j	80002fa2 <bread+0x40>
    80002f9c:	68a4                	ld	s1,80(s1)
    80002f9e:	02e48a63          	beq	s1,a4,80002fd2 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fa2:	449c                	lw	a5,8(s1)
    80002fa4:	ff279ce3          	bne	a5,s2,80002f9c <bread+0x3a>
    80002fa8:	44dc                	lw	a5,12(s1)
    80002faa:	ff3799e3          	bne	a5,s3,80002f9c <bread+0x3a>
      b->refcnt++;
    80002fae:	40bc                	lw	a5,64(s1)
    80002fb0:	2785                	addw	a5,a5,1
    80002fb2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fb4:	00015517          	auipc	a0,0x15
    80002fb8:	fcc50513          	add	a0,a0,-52 # 80017f80 <bcache>
    80002fbc:	ffffe097          	auipc	ra,0xffffe
    80002fc0:	d58080e7          	jalr	-680(ra) # 80000d14 <release>
      acquiresleep(&b->lock);
    80002fc4:	01048513          	add	a0,s1,16
    80002fc8:	00001097          	auipc	ra,0x1
    80002fcc:	42a080e7          	jalr	1066(ra) # 800043f2 <acquiresleep>
      return b;
    80002fd0:	a8b9                	j	8000302e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fd2:	0001d497          	auipc	s1,0x1d
    80002fd6:	25e4b483          	ld	s1,606(s1) # 80020230 <bcache+0x82b0>
    80002fda:	0001d797          	auipc	a5,0x1d
    80002fde:	20e78793          	add	a5,a5,526 # 800201e8 <bcache+0x8268>
    80002fe2:	00f48863          	beq	s1,a5,80002ff2 <bread+0x90>
    80002fe6:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fe8:	40bc                	lw	a5,64(s1)
    80002fea:	cf81                	beqz	a5,80003002 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fec:	64a4                	ld	s1,72(s1)
    80002fee:	fee49de3          	bne	s1,a4,80002fe8 <bread+0x86>
  panic("bget: no buffers");
    80002ff2:	00005517          	auipc	a0,0x5
    80002ff6:	51e50513          	add	a0,a0,1310 # 80008510 <syscalls+0xd0>
    80002ffa:	ffffd097          	auipc	ra,0xffffd
    80002ffe:	548080e7          	jalr	1352(ra) # 80000542 <panic>
      b->dev = dev;
    80003002:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003006:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000300a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000300e:	4785                	li	a5,1
    80003010:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003012:	00015517          	auipc	a0,0x15
    80003016:	f6e50513          	add	a0,a0,-146 # 80017f80 <bcache>
    8000301a:	ffffe097          	auipc	ra,0xffffe
    8000301e:	cfa080e7          	jalr	-774(ra) # 80000d14 <release>
      acquiresleep(&b->lock);
    80003022:	01048513          	add	a0,s1,16
    80003026:	00001097          	auipc	ra,0x1
    8000302a:	3cc080e7          	jalr	972(ra) # 800043f2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000302e:	409c                	lw	a5,0(s1)
    80003030:	cb89                	beqz	a5,80003042 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003032:	8526                	mv	a0,s1
    80003034:	70a2                	ld	ra,40(sp)
    80003036:	7402                	ld	s0,32(sp)
    80003038:	64e2                	ld	s1,24(sp)
    8000303a:	6942                	ld	s2,16(sp)
    8000303c:	69a2                	ld	s3,8(sp)
    8000303e:	6145                	add	sp,sp,48
    80003040:	8082                	ret
    virtio_disk_rw(b, 0);
    80003042:	4581                	li	a1,0
    80003044:	8526                	mv	a0,s1
    80003046:	00003097          	auipc	ra,0x3
    8000304a:	ed2080e7          	jalr	-302(ra) # 80005f18 <virtio_disk_rw>
    b->valid = 1;
    8000304e:	4785                	li	a5,1
    80003050:	c09c                	sw	a5,0(s1)
  return b;
    80003052:	b7c5                	j	80003032 <bread+0xd0>

0000000080003054 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003054:	1101                	add	sp,sp,-32
    80003056:	ec06                	sd	ra,24(sp)
    80003058:	e822                	sd	s0,16(sp)
    8000305a:	e426                	sd	s1,8(sp)
    8000305c:	1000                	add	s0,sp,32
    8000305e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003060:	0541                	add	a0,a0,16
    80003062:	00001097          	auipc	ra,0x1
    80003066:	42a080e7          	jalr	1066(ra) # 8000448c <holdingsleep>
    8000306a:	cd01                	beqz	a0,80003082 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000306c:	4585                	li	a1,1
    8000306e:	8526                	mv	a0,s1
    80003070:	00003097          	auipc	ra,0x3
    80003074:	ea8080e7          	jalr	-344(ra) # 80005f18 <virtio_disk_rw>
}
    80003078:	60e2                	ld	ra,24(sp)
    8000307a:	6442                	ld	s0,16(sp)
    8000307c:	64a2                	ld	s1,8(sp)
    8000307e:	6105                	add	sp,sp,32
    80003080:	8082                	ret
    panic("bwrite");
    80003082:	00005517          	auipc	a0,0x5
    80003086:	4a650513          	add	a0,a0,1190 # 80008528 <syscalls+0xe8>
    8000308a:	ffffd097          	auipc	ra,0xffffd
    8000308e:	4b8080e7          	jalr	1208(ra) # 80000542 <panic>

0000000080003092 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003092:	1101                	add	sp,sp,-32
    80003094:	ec06                	sd	ra,24(sp)
    80003096:	e822                	sd	s0,16(sp)
    80003098:	e426                	sd	s1,8(sp)
    8000309a:	e04a                	sd	s2,0(sp)
    8000309c:	1000                	add	s0,sp,32
    8000309e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030a0:	01050913          	add	s2,a0,16
    800030a4:	854a                	mv	a0,s2
    800030a6:	00001097          	auipc	ra,0x1
    800030aa:	3e6080e7          	jalr	998(ra) # 8000448c <holdingsleep>
    800030ae:	c925                	beqz	a0,8000311e <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800030b0:	854a                	mv	a0,s2
    800030b2:	00001097          	auipc	ra,0x1
    800030b6:	396080e7          	jalr	918(ra) # 80004448 <releasesleep>

  acquire(&bcache.lock);
    800030ba:	00015517          	auipc	a0,0x15
    800030be:	ec650513          	add	a0,a0,-314 # 80017f80 <bcache>
    800030c2:	ffffe097          	auipc	ra,0xffffe
    800030c6:	b9e080e7          	jalr	-1122(ra) # 80000c60 <acquire>
  b->refcnt--;
    800030ca:	40bc                	lw	a5,64(s1)
    800030cc:	37fd                	addw	a5,a5,-1
    800030ce:	0007871b          	sext.w	a4,a5
    800030d2:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030d4:	e71d                	bnez	a4,80003102 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030d6:	68b8                	ld	a4,80(s1)
    800030d8:	64bc                	ld	a5,72(s1)
    800030da:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800030dc:	68b8                	ld	a4,80(s1)
    800030de:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030e0:	0001d797          	auipc	a5,0x1d
    800030e4:	ea078793          	add	a5,a5,-352 # 8001ff80 <bcache+0x8000>
    800030e8:	2b87b703          	ld	a4,696(a5)
    800030ec:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030ee:	0001d717          	auipc	a4,0x1d
    800030f2:	0fa70713          	add	a4,a4,250 # 800201e8 <bcache+0x8268>
    800030f6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030f8:	2b87b703          	ld	a4,696(a5)
    800030fc:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030fe:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003102:	00015517          	auipc	a0,0x15
    80003106:	e7e50513          	add	a0,a0,-386 # 80017f80 <bcache>
    8000310a:	ffffe097          	auipc	ra,0xffffe
    8000310e:	c0a080e7          	jalr	-1014(ra) # 80000d14 <release>
}
    80003112:	60e2                	ld	ra,24(sp)
    80003114:	6442                	ld	s0,16(sp)
    80003116:	64a2                	ld	s1,8(sp)
    80003118:	6902                	ld	s2,0(sp)
    8000311a:	6105                	add	sp,sp,32
    8000311c:	8082                	ret
    panic("brelse");
    8000311e:	00005517          	auipc	a0,0x5
    80003122:	41250513          	add	a0,a0,1042 # 80008530 <syscalls+0xf0>
    80003126:	ffffd097          	auipc	ra,0xffffd
    8000312a:	41c080e7          	jalr	1052(ra) # 80000542 <panic>

000000008000312e <bpin>:

void
bpin(struct buf *b) {
    8000312e:	1101                	add	sp,sp,-32
    80003130:	ec06                	sd	ra,24(sp)
    80003132:	e822                	sd	s0,16(sp)
    80003134:	e426                	sd	s1,8(sp)
    80003136:	1000                	add	s0,sp,32
    80003138:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000313a:	00015517          	auipc	a0,0x15
    8000313e:	e4650513          	add	a0,a0,-442 # 80017f80 <bcache>
    80003142:	ffffe097          	auipc	ra,0xffffe
    80003146:	b1e080e7          	jalr	-1250(ra) # 80000c60 <acquire>
  b->refcnt++;
    8000314a:	40bc                	lw	a5,64(s1)
    8000314c:	2785                	addw	a5,a5,1
    8000314e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003150:	00015517          	auipc	a0,0x15
    80003154:	e3050513          	add	a0,a0,-464 # 80017f80 <bcache>
    80003158:	ffffe097          	auipc	ra,0xffffe
    8000315c:	bbc080e7          	jalr	-1092(ra) # 80000d14 <release>
}
    80003160:	60e2                	ld	ra,24(sp)
    80003162:	6442                	ld	s0,16(sp)
    80003164:	64a2                	ld	s1,8(sp)
    80003166:	6105                	add	sp,sp,32
    80003168:	8082                	ret

000000008000316a <bunpin>:

void
bunpin(struct buf *b) {
    8000316a:	1101                	add	sp,sp,-32
    8000316c:	ec06                	sd	ra,24(sp)
    8000316e:	e822                	sd	s0,16(sp)
    80003170:	e426                	sd	s1,8(sp)
    80003172:	1000                	add	s0,sp,32
    80003174:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003176:	00015517          	auipc	a0,0x15
    8000317a:	e0a50513          	add	a0,a0,-502 # 80017f80 <bcache>
    8000317e:	ffffe097          	auipc	ra,0xffffe
    80003182:	ae2080e7          	jalr	-1310(ra) # 80000c60 <acquire>
  b->refcnt--;
    80003186:	40bc                	lw	a5,64(s1)
    80003188:	37fd                	addw	a5,a5,-1
    8000318a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000318c:	00015517          	auipc	a0,0x15
    80003190:	df450513          	add	a0,a0,-524 # 80017f80 <bcache>
    80003194:	ffffe097          	auipc	ra,0xffffe
    80003198:	b80080e7          	jalr	-1152(ra) # 80000d14 <release>
}
    8000319c:	60e2                	ld	ra,24(sp)
    8000319e:	6442                	ld	s0,16(sp)
    800031a0:	64a2                	ld	s1,8(sp)
    800031a2:	6105                	add	sp,sp,32
    800031a4:	8082                	ret

00000000800031a6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031a6:	1101                	add	sp,sp,-32
    800031a8:	ec06                	sd	ra,24(sp)
    800031aa:	e822                	sd	s0,16(sp)
    800031ac:	e426                	sd	s1,8(sp)
    800031ae:	e04a                	sd	s2,0(sp)
    800031b0:	1000                	add	s0,sp,32
    800031b2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031b4:	00d5d59b          	srlw	a1,a1,0xd
    800031b8:	0001d797          	auipc	a5,0x1d
    800031bc:	4a47a783          	lw	a5,1188(a5) # 8002065c <sb+0x1c>
    800031c0:	9dbd                	addw	a1,a1,a5
    800031c2:	00000097          	auipc	ra,0x0
    800031c6:	da0080e7          	jalr	-608(ra) # 80002f62 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031ca:	0074f713          	and	a4,s1,7
    800031ce:	4785                	li	a5,1
    800031d0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031d4:	14ce                	sll	s1,s1,0x33
    800031d6:	90d9                	srl	s1,s1,0x36
    800031d8:	00950733          	add	a4,a0,s1
    800031dc:	05874703          	lbu	a4,88(a4)
    800031e0:	00e7f6b3          	and	a3,a5,a4
    800031e4:	c69d                	beqz	a3,80003212 <bfree+0x6c>
    800031e6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031e8:	94aa                	add	s1,s1,a0
    800031ea:	fff7c793          	not	a5,a5
    800031ee:	8f7d                	and	a4,a4,a5
    800031f0:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800031f4:	00001097          	auipc	ra,0x1
    800031f8:	0d8080e7          	jalr	216(ra) # 800042cc <log_write>
  brelse(bp);
    800031fc:	854a                	mv	a0,s2
    800031fe:	00000097          	auipc	ra,0x0
    80003202:	e94080e7          	jalr	-364(ra) # 80003092 <brelse>
}
    80003206:	60e2                	ld	ra,24(sp)
    80003208:	6442                	ld	s0,16(sp)
    8000320a:	64a2                	ld	s1,8(sp)
    8000320c:	6902                	ld	s2,0(sp)
    8000320e:	6105                	add	sp,sp,32
    80003210:	8082                	ret
    panic("freeing free block");
    80003212:	00005517          	auipc	a0,0x5
    80003216:	32650513          	add	a0,a0,806 # 80008538 <syscalls+0xf8>
    8000321a:	ffffd097          	auipc	ra,0xffffd
    8000321e:	328080e7          	jalr	808(ra) # 80000542 <panic>

0000000080003222 <balloc>:
{
    80003222:	711d                	add	sp,sp,-96
    80003224:	ec86                	sd	ra,88(sp)
    80003226:	e8a2                	sd	s0,80(sp)
    80003228:	e4a6                	sd	s1,72(sp)
    8000322a:	e0ca                	sd	s2,64(sp)
    8000322c:	fc4e                	sd	s3,56(sp)
    8000322e:	f852                	sd	s4,48(sp)
    80003230:	f456                	sd	s5,40(sp)
    80003232:	f05a                	sd	s6,32(sp)
    80003234:	ec5e                	sd	s7,24(sp)
    80003236:	e862                	sd	s8,16(sp)
    80003238:	e466                	sd	s9,8(sp)
    8000323a:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000323c:	0001d797          	auipc	a5,0x1d
    80003240:	4087a783          	lw	a5,1032(a5) # 80020644 <sb+0x4>
    80003244:	cbc1                	beqz	a5,800032d4 <balloc+0xb2>
    80003246:	8baa                	mv	s7,a0
    80003248:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000324a:	0001db17          	auipc	s6,0x1d
    8000324e:	3f6b0b13          	add	s6,s6,1014 # 80020640 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003252:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003254:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003256:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003258:	6c89                	lui	s9,0x2
    8000325a:	a831                	j	80003276 <balloc+0x54>
    brelse(bp);
    8000325c:	854a                	mv	a0,s2
    8000325e:	00000097          	auipc	ra,0x0
    80003262:	e34080e7          	jalr	-460(ra) # 80003092 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003266:	015c87bb          	addw	a5,s9,s5
    8000326a:	00078a9b          	sext.w	s5,a5
    8000326e:	004b2703          	lw	a4,4(s6)
    80003272:	06eaf163          	bgeu	s5,a4,800032d4 <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    80003276:	41fad79b          	sraw	a5,s5,0x1f
    8000327a:	0137d79b          	srlw	a5,a5,0x13
    8000327e:	015787bb          	addw	a5,a5,s5
    80003282:	40d7d79b          	sraw	a5,a5,0xd
    80003286:	01cb2583          	lw	a1,28(s6)
    8000328a:	9dbd                	addw	a1,a1,a5
    8000328c:	855e                	mv	a0,s7
    8000328e:	00000097          	auipc	ra,0x0
    80003292:	cd4080e7          	jalr	-812(ra) # 80002f62 <bread>
    80003296:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003298:	004b2503          	lw	a0,4(s6)
    8000329c:	000a849b          	sext.w	s1,s5
    800032a0:	8762                	mv	a4,s8
    800032a2:	faa4fde3          	bgeu	s1,a0,8000325c <balloc+0x3a>
      m = 1 << (bi % 8);
    800032a6:	00777693          	and	a3,a4,7
    800032aa:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032ae:	41f7579b          	sraw	a5,a4,0x1f
    800032b2:	01d7d79b          	srlw	a5,a5,0x1d
    800032b6:	9fb9                	addw	a5,a5,a4
    800032b8:	4037d79b          	sraw	a5,a5,0x3
    800032bc:	00f90633          	add	a2,s2,a5
    800032c0:	05864603          	lbu	a2,88(a2)
    800032c4:	00c6f5b3          	and	a1,a3,a2
    800032c8:	cd91                	beqz	a1,800032e4 <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ca:	2705                	addw	a4,a4,1
    800032cc:	2485                	addw	s1,s1,1
    800032ce:	fd471ae3          	bne	a4,s4,800032a2 <balloc+0x80>
    800032d2:	b769                	j	8000325c <balloc+0x3a>
  panic("balloc: out of blocks");
    800032d4:	00005517          	auipc	a0,0x5
    800032d8:	27c50513          	add	a0,a0,636 # 80008550 <syscalls+0x110>
    800032dc:	ffffd097          	auipc	ra,0xffffd
    800032e0:	266080e7          	jalr	614(ra) # 80000542 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032e4:	97ca                	add	a5,a5,s2
    800032e6:	8e55                	or	a2,a2,a3
    800032e8:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800032ec:	854a                	mv	a0,s2
    800032ee:	00001097          	auipc	ra,0x1
    800032f2:	fde080e7          	jalr	-34(ra) # 800042cc <log_write>
        brelse(bp);
    800032f6:	854a                	mv	a0,s2
    800032f8:	00000097          	auipc	ra,0x0
    800032fc:	d9a080e7          	jalr	-614(ra) # 80003092 <brelse>
  bp = bread(dev, bno);
    80003300:	85a6                	mv	a1,s1
    80003302:	855e                	mv	a0,s7
    80003304:	00000097          	auipc	ra,0x0
    80003308:	c5e080e7          	jalr	-930(ra) # 80002f62 <bread>
    8000330c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000330e:	40000613          	li	a2,1024
    80003312:	4581                	li	a1,0
    80003314:	05850513          	add	a0,a0,88
    80003318:	ffffe097          	auipc	ra,0xffffe
    8000331c:	a44080e7          	jalr	-1468(ra) # 80000d5c <memset>
  log_write(bp);
    80003320:	854a                	mv	a0,s2
    80003322:	00001097          	auipc	ra,0x1
    80003326:	faa080e7          	jalr	-86(ra) # 800042cc <log_write>
  brelse(bp);
    8000332a:	854a                	mv	a0,s2
    8000332c:	00000097          	auipc	ra,0x0
    80003330:	d66080e7          	jalr	-666(ra) # 80003092 <brelse>
}
    80003334:	8526                	mv	a0,s1
    80003336:	60e6                	ld	ra,88(sp)
    80003338:	6446                	ld	s0,80(sp)
    8000333a:	64a6                	ld	s1,72(sp)
    8000333c:	6906                	ld	s2,64(sp)
    8000333e:	79e2                	ld	s3,56(sp)
    80003340:	7a42                	ld	s4,48(sp)
    80003342:	7aa2                	ld	s5,40(sp)
    80003344:	7b02                	ld	s6,32(sp)
    80003346:	6be2                	ld	s7,24(sp)
    80003348:	6c42                	ld	s8,16(sp)
    8000334a:	6ca2                	ld	s9,8(sp)
    8000334c:	6125                	add	sp,sp,96
    8000334e:	8082                	ret

0000000080003350 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003350:	7179                	add	sp,sp,-48
    80003352:	f406                	sd	ra,40(sp)
    80003354:	f022                	sd	s0,32(sp)
    80003356:	ec26                	sd	s1,24(sp)
    80003358:	e84a                	sd	s2,16(sp)
    8000335a:	e44e                	sd	s3,8(sp)
    8000335c:	e052                	sd	s4,0(sp)
    8000335e:	1800                	add	s0,sp,48
    80003360:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003362:	47ad                	li	a5,11
    80003364:	04b7fe63          	bgeu	a5,a1,800033c0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003368:	ff45849b          	addw	s1,a1,-12
    8000336c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003370:	0ff00793          	li	a5,255
    80003374:	0ae7e463          	bltu	a5,a4,8000341c <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003378:	08052583          	lw	a1,128(a0)
    8000337c:	c5b5                	beqz	a1,800033e8 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000337e:	00092503          	lw	a0,0(s2)
    80003382:	00000097          	auipc	ra,0x0
    80003386:	be0080e7          	jalr	-1056(ra) # 80002f62 <bread>
    8000338a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000338c:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    80003390:	02049713          	sll	a4,s1,0x20
    80003394:	01e75593          	srl	a1,a4,0x1e
    80003398:	00b784b3          	add	s1,a5,a1
    8000339c:	0004a983          	lw	s3,0(s1)
    800033a0:	04098e63          	beqz	s3,800033fc <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033a4:	8552                	mv	a0,s4
    800033a6:	00000097          	auipc	ra,0x0
    800033aa:	cec080e7          	jalr	-788(ra) # 80003092 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033ae:	854e                	mv	a0,s3
    800033b0:	70a2                	ld	ra,40(sp)
    800033b2:	7402                	ld	s0,32(sp)
    800033b4:	64e2                	ld	s1,24(sp)
    800033b6:	6942                	ld	s2,16(sp)
    800033b8:	69a2                	ld	s3,8(sp)
    800033ba:	6a02                	ld	s4,0(sp)
    800033bc:	6145                	add	sp,sp,48
    800033be:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033c0:	02059793          	sll	a5,a1,0x20
    800033c4:	01e7d593          	srl	a1,a5,0x1e
    800033c8:	00b504b3          	add	s1,a0,a1
    800033cc:	0504a983          	lw	s3,80(s1)
    800033d0:	fc099fe3          	bnez	s3,800033ae <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033d4:	4108                	lw	a0,0(a0)
    800033d6:	00000097          	auipc	ra,0x0
    800033da:	e4c080e7          	jalr	-436(ra) # 80003222 <balloc>
    800033de:	0005099b          	sext.w	s3,a0
    800033e2:	0534a823          	sw	s3,80(s1)
    800033e6:	b7e1                	j	800033ae <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033e8:	4108                	lw	a0,0(a0)
    800033ea:	00000097          	auipc	ra,0x0
    800033ee:	e38080e7          	jalr	-456(ra) # 80003222 <balloc>
    800033f2:	0005059b          	sext.w	a1,a0
    800033f6:	08b92023          	sw	a1,128(s2)
    800033fa:	b751                	j	8000337e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033fc:	00092503          	lw	a0,0(s2)
    80003400:	00000097          	auipc	ra,0x0
    80003404:	e22080e7          	jalr	-478(ra) # 80003222 <balloc>
    80003408:	0005099b          	sext.w	s3,a0
    8000340c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003410:	8552                	mv	a0,s4
    80003412:	00001097          	auipc	ra,0x1
    80003416:	eba080e7          	jalr	-326(ra) # 800042cc <log_write>
    8000341a:	b769                	j	800033a4 <bmap+0x54>
  panic("bmap: out of range");
    8000341c:	00005517          	auipc	a0,0x5
    80003420:	14c50513          	add	a0,a0,332 # 80008568 <syscalls+0x128>
    80003424:	ffffd097          	auipc	ra,0xffffd
    80003428:	11e080e7          	jalr	286(ra) # 80000542 <panic>

000000008000342c <iget>:
{
    8000342c:	7179                	add	sp,sp,-48
    8000342e:	f406                	sd	ra,40(sp)
    80003430:	f022                	sd	s0,32(sp)
    80003432:	ec26                	sd	s1,24(sp)
    80003434:	e84a                	sd	s2,16(sp)
    80003436:	e44e                	sd	s3,8(sp)
    80003438:	e052                	sd	s4,0(sp)
    8000343a:	1800                	add	s0,sp,48
    8000343c:	89aa                	mv	s3,a0
    8000343e:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003440:	0001d517          	auipc	a0,0x1d
    80003444:	22050513          	add	a0,a0,544 # 80020660 <icache>
    80003448:	ffffe097          	auipc	ra,0xffffe
    8000344c:	818080e7          	jalr	-2024(ra) # 80000c60 <acquire>
  empty = 0;
    80003450:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003452:	0001d497          	auipc	s1,0x1d
    80003456:	22648493          	add	s1,s1,550 # 80020678 <icache+0x18>
    8000345a:	0001f697          	auipc	a3,0x1f
    8000345e:	cae68693          	add	a3,a3,-850 # 80022108 <log>
    80003462:	a039                	j	80003470 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003464:	02090b63          	beqz	s2,8000349a <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003468:	08848493          	add	s1,s1,136
    8000346c:	02d48a63          	beq	s1,a3,800034a0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003470:	449c                	lw	a5,8(s1)
    80003472:	fef059e3          	blez	a5,80003464 <iget+0x38>
    80003476:	4098                	lw	a4,0(s1)
    80003478:	ff3716e3          	bne	a4,s3,80003464 <iget+0x38>
    8000347c:	40d8                	lw	a4,4(s1)
    8000347e:	ff4713e3          	bne	a4,s4,80003464 <iget+0x38>
      ip->ref++;
    80003482:	2785                	addw	a5,a5,1
    80003484:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003486:	0001d517          	auipc	a0,0x1d
    8000348a:	1da50513          	add	a0,a0,474 # 80020660 <icache>
    8000348e:	ffffe097          	auipc	ra,0xffffe
    80003492:	886080e7          	jalr	-1914(ra) # 80000d14 <release>
      return ip;
    80003496:	8926                	mv	s2,s1
    80003498:	a03d                	j	800034c6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000349a:	f7f9                	bnez	a5,80003468 <iget+0x3c>
    8000349c:	8926                	mv	s2,s1
    8000349e:	b7e9                	j	80003468 <iget+0x3c>
  if(empty == 0)
    800034a0:	02090c63          	beqz	s2,800034d8 <iget+0xac>
  ip->dev = dev;
    800034a4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034a8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034ac:	4785                	li	a5,1
    800034ae:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034b2:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800034b6:	0001d517          	auipc	a0,0x1d
    800034ba:	1aa50513          	add	a0,a0,426 # 80020660 <icache>
    800034be:	ffffe097          	auipc	ra,0xffffe
    800034c2:	856080e7          	jalr	-1962(ra) # 80000d14 <release>
}
    800034c6:	854a                	mv	a0,s2
    800034c8:	70a2                	ld	ra,40(sp)
    800034ca:	7402                	ld	s0,32(sp)
    800034cc:	64e2                	ld	s1,24(sp)
    800034ce:	6942                	ld	s2,16(sp)
    800034d0:	69a2                	ld	s3,8(sp)
    800034d2:	6a02                	ld	s4,0(sp)
    800034d4:	6145                	add	sp,sp,48
    800034d6:	8082                	ret
    panic("iget: no inodes");
    800034d8:	00005517          	auipc	a0,0x5
    800034dc:	0a850513          	add	a0,a0,168 # 80008580 <syscalls+0x140>
    800034e0:	ffffd097          	auipc	ra,0xffffd
    800034e4:	062080e7          	jalr	98(ra) # 80000542 <panic>

00000000800034e8 <fsinit>:
fsinit(int dev) {
    800034e8:	7179                	add	sp,sp,-48
    800034ea:	f406                	sd	ra,40(sp)
    800034ec:	f022                	sd	s0,32(sp)
    800034ee:	ec26                	sd	s1,24(sp)
    800034f0:	e84a                	sd	s2,16(sp)
    800034f2:	e44e                	sd	s3,8(sp)
    800034f4:	1800                	add	s0,sp,48
    800034f6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034f8:	4585                	li	a1,1
    800034fa:	00000097          	auipc	ra,0x0
    800034fe:	a68080e7          	jalr	-1432(ra) # 80002f62 <bread>
    80003502:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003504:	0001d997          	auipc	s3,0x1d
    80003508:	13c98993          	add	s3,s3,316 # 80020640 <sb>
    8000350c:	02000613          	li	a2,32
    80003510:	05850593          	add	a1,a0,88
    80003514:	854e                	mv	a0,s3
    80003516:	ffffe097          	auipc	ra,0xffffe
    8000351a:	8a2080e7          	jalr	-1886(ra) # 80000db8 <memmove>
  brelse(bp);
    8000351e:	8526                	mv	a0,s1
    80003520:	00000097          	auipc	ra,0x0
    80003524:	b72080e7          	jalr	-1166(ra) # 80003092 <brelse>
  if(sb.magic != FSMAGIC)
    80003528:	0009a703          	lw	a4,0(s3)
    8000352c:	102037b7          	lui	a5,0x10203
    80003530:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003534:	02f71263          	bne	a4,a5,80003558 <fsinit+0x70>
  initlog(dev, &sb);
    80003538:	0001d597          	auipc	a1,0x1d
    8000353c:	10858593          	add	a1,a1,264 # 80020640 <sb>
    80003540:	854a                	mv	a0,s2
    80003542:	00001097          	auipc	ra,0x1
    80003546:	b24080e7          	jalr	-1244(ra) # 80004066 <initlog>
}
    8000354a:	70a2                	ld	ra,40(sp)
    8000354c:	7402                	ld	s0,32(sp)
    8000354e:	64e2                	ld	s1,24(sp)
    80003550:	6942                	ld	s2,16(sp)
    80003552:	69a2                	ld	s3,8(sp)
    80003554:	6145                	add	sp,sp,48
    80003556:	8082                	ret
    panic("invalid file system");
    80003558:	00005517          	auipc	a0,0x5
    8000355c:	03850513          	add	a0,a0,56 # 80008590 <syscalls+0x150>
    80003560:	ffffd097          	auipc	ra,0xffffd
    80003564:	fe2080e7          	jalr	-30(ra) # 80000542 <panic>

0000000080003568 <iinit>:
{
    80003568:	7179                	add	sp,sp,-48
    8000356a:	f406                	sd	ra,40(sp)
    8000356c:	f022                	sd	s0,32(sp)
    8000356e:	ec26                	sd	s1,24(sp)
    80003570:	e84a                	sd	s2,16(sp)
    80003572:	e44e                	sd	s3,8(sp)
    80003574:	1800                	add	s0,sp,48
  initlock(&icache.lock, "icache");
    80003576:	00005597          	auipc	a1,0x5
    8000357a:	03258593          	add	a1,a1,50 # 800085a8 <syscalls+0x168>
    8000357e:	0001d517          	auipc	a0,0x1d
    80003582:	0e250513          	add	a0,a0,226 # 80020660 <icache>
    80003586:	ffffd097          	auipc	ra,0xffffd
    8000358a:	64a080e7          	jalr	1610(ra) # 80000bd0 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000358e:	0001d497          	auipc	s1,0x1d
    80003592:	0fa48493          	add	s1,s1,250 # 80020688 <icache+0x28>
    80003596:	0001f997          	auipc	s3,0x1f
    8000359a:	b8298993          	add	s3,s3,-1150 # 80022118 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000359e:	00005917          	auipc	s2,0x5
    800035a2:	01290913          	add	s2,s2,18 # 800085b0 <syscalls+0x170>
    800035a6:	85ca                	mv	a1,s2
    800035a8:	8526                	mv	a0,s1
    800035aa:	00001097          	auipc	ra,0x1
    800035ae:	e0e080e7          	jalr	-498(ra) # 800043b8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035b2:	08848493          	add	s1,s1,136
    800035b6:	ff3498e3          	bne	s1,s3,800035a6 <iinit+0x3e>
}
    800035ba:	70a2                	ld	ra,40(sp)
    800035bc:	7402                	ld	s0,32(sp)
    800035be:	64e2                	ld	s1,24(sp)
    800035c0:	6942                	ld	s2,16(sp)
    800035c2:	69a2                	ld	s3,8(sp)
    800035c4:	6145                	add	sp,sp,48
    800035c6:	8082                	ret

00000000800035c8 <ialloc>:
{
    800035c8:	7139                	add	sp,sp,-64
    800035ca:	fc06                	sd	ra,56(sp)
    800035cc:	f822                	sd	s0,48(sp)
    800035ce:	f426                	sd	s1,40(sp)
    800035d0:	f04a                	sd	s2,32(sp)
    800035d2:	ec4e                	sd	s3,24(sp)
    800035d4:	e852                	sd	s4,16(sp)
    800035d6:	e456                	sd	s5,8(sp)
    800035d8:	e05a                	sd	s6,0(sp)
    800035da:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800035dc:	0001d717          	auipc	a4,0x1d
    800035e0:	07072703          	lw	a4,112(a4) # 8002064c <sb+0xc>
    800035e4:	4785                	li	a5,1
    800035e6:	04e7f863          	bgeu	a5,a4,80003636 <ialloc+0x6e>
    800035ea:	8aaa                	mv	s5,a0
    800035ec:	8b2e                	mv	s6,a1
    800035ee:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035f0:	0001da17          	auipc	s4,0x1d
    800035f4:	050a0a13          	add	s4,s4,80 # 80020640 <sb>
    800035f8:	00495593          	srl	a1,s2,0x4
    800035fc:	018a2783          	lw	a5,24(s4)
    80003600:	9dbd                	addw	a1,a1,a5
    80003602:	8556                	mv	a0,s5
    80003604:	00000097          	auipc	ra,0x0
    80003608:	95e080e7          	jalr	-1698(ra) # 80002f62 <bread>
    8000360c:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000360e:	05850993          	add	s3,a0,88
    80003612:	00f97793          	and	a5,s2,15
    80003616:	079a                	sll	a5,a5,0x6
    80003618:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000361a:	00099783          	lh	a5,0(s3)
    8000361e:	c785                	beqz	a5,80003646 <ialloc+0x7e>
    brelse(bp);
    80003620:	00000097          	auipc	ra,0x0
    80003624:	a72080e7          	jalr	-1422(ra) # 80003092 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003628:	0905                	add	s2,s2,1
    8000362a:	00ca2703          	lw	a4,12(s4)
    8000362e:	0009079b          	sext.w	a5,s2
    80003632:	fce7e3e3          	bltu	a5,a4,800035f8 <ialloc+0x30>
  panic("ialloc: no inodes");
    80003636:	00005517          	auipc	a0,0x5
    8000363a:	f8250513          	add	a0,a0,-126 # 800085b8 <syscalls+0x178>
    8000363e:	ffffd097          	auipc	ra,0xffffd
    80003642:	f04080e7          	jalr	-252(ra) # 80000542 <panic>
      memset(dip, 0, sizeof(*dip));
    80003646:	04000613          	li	a2,64
    8000364a:	4581                	li	a1,0
    8000364c:	854e                	mv	a0,s3
    8000364e:	ffffd097          	auipc	ra,0xffffd
    80003652:	70e080e7          	jalr	1806(ra) # 80000d5c <memset>
      dip->type = type;
    80003656:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000365a:	8526                	mv	a0,s1
    8000365c:	00001097          	auipc	ra,0x1
    80003660:	c70080e7          	jalr	-912(ra) # 800042cc <log_write>
      brelse(bp);
    80003664:	8526                	mv	a0,s1
    80003666:	00000097          	auipc	ra,0x0
    8000366a:	a2c080e7          	jalr	-1492(ra) # 80003092 <brelse>
      return iget(dev, inum);
    8000366e:	0009059b          	sext.w	a1,s2
    80003672:	8556                	mv	a0,s5
    80003674:	00000097          	auipc	ra,0x0
    80003678:	db8080e7          	jalr	-584(ra) # 8000342c <iget>
}
    8000367c:	70e2                	ld	ra,56(sp)
    8000367e:	7442                	ld	s0,48(sp)
    80003680:	74a2                	ld	s1,40(sp)
    80003682:	7902                	ld	s2,32(sp)
    80003684:	69e2                	ld	s3,24(sp)
    80003686:	6a42                	ld	s4,16(sp)
    80003688:	6aa2                	ld	s5,8(sp)
    8000368a:	6b02                	ld	s6,0(sp)
    8000368c:	6121                	add	sp,sp,64
    8000368e:	8082                	ret

0000000080003690 <iupdate>:
{
    80003690:	1101                	add	sp,sp,-32
    80003692:	ec06                	sd	ra,24(sp)
    80003694:	e822                	sd	s0,16(sp)
    80003696:	e426                	sd	s1,8(sp)
    80003698:	e04a                	sd	s2,0(sp)
    8000369a:	1000                	add	s0,sp,32
    8000369c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000369e:	415c                	lw	a5,4(a0)
    800036a0:	0047d79b          	srlw	a5,a5,0x4
    800036a4:	0001d597          	auipc	a1,0x1d
    800036a8:	fb45a583          	lw	a1,-76(a1) # 80020658 <sb+0x18>
    800036ac:	9dbd                	addw	a1,a1,a5
    800036ae:	4108                	lw	a0,0(a0)
    800036b0:	00000097          	auipc	ra,0x0
    800036b4:	8b2080e7          	jalr	-1870(ra) # 80002f62 <bread>
    800036b8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036ba:	05850793          	add	a5,a0,88
    800036be:	40d8                	lw	a4,4(s1)
    800036c0:	8b3d                	and	a4,a4,15
    800036c2:	071a                	sll	a4,a4,0x6
    800036c4:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800036c6:	04449703          	lh	a4,68(s1)
    800036ca:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800036ce:	04649703          	lh	a4,70(s1)
    800036d2:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800036d6:	04849703          	lh	a4,72(s1)
    800036da:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800036de:	04a49703          	lh	a4,74(s1)
    800036e2:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800036e6:	44f8                	lw	a4,76(s1)
    800036e8:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036ea:	03400613          	li	a2,52
    800036ee:	05048593          	add	a1,s1,80
    800036f2:	00c78513          	add	a0,a5,12
    800036f6:	ffffd097          	auipc	ra,0xffffd
    800036fa:	6c2080e7          	jalr	1730(ra) # 80000db8 <memmove>
  log_write(bp);
    800036fe:	854a                	mv	a0,s2
    80003700:	00001097          	auipc	ra,0x1
    80003704:	bcc080e7          	jalr	-1076(ra) # 800042cc <log_write>
  brelse(bp);
    80003708:	854a                	mv	a0,s2
    8000370a:	00000097          	auipc	ra,0x0
    8000370e:	988080e7          	jalr	-1656(ra) # 80003092 <brelse>
}
    80003712:	60e2                	ld	ra,24(sp)
    80003714:	6442                	ld	s0,16(sp)
    80003716:	64a2                	ld	s1,8(sp)
    80003718:	6902                	ld	s2,0(sp)
    8000371a:	6105                	add	sp,sp,32
    8000371c:	8082                	ret

000000008000371e <idup>:
{
    8000371e:	1101                	add	sp,sp,-32
    80003720:	ec06                	sd	ra,24(sp)
    80003722:	e822                	sd	s0,16(sp)
    80003724:	e426                	sd	s1,8(sp)
    80003726:	1000                	add	s0,sp,32
    80003728:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000372a:	0001d517          	auipc	a0,0x1d
    8000372e:	f3650513          	add	a0,a0,-202 # 80020660 <icache>
    80003732:	ffffd097          	auipc	ra,0xffffd
    80003736:	52e080e7          	jalr	1326(ra) # 80000c60 <acquire>
  ip->ref++;
    8000373a:	449c                	lw	a5,8(s1)
    8000373c:	2785                	addw	a5,a5,1
    8000373e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003740:	0001d517          	auipc	a0,0x1d
    80003744:	f2050513          	add	a0,a0,-224 # 80020660 <icache>
    80003748:	ffffd097          	auipc	ra,0xffffd
    8000374c:	5cc080e7          	jalr	1484(ra) # 80000d14 <release>
}
    80003750:	8526                	mv	a0,s1
    80003752:	60e2                	ld	ra,24(sp)
    80003754:	6442                	ld	s0,16(sp)
    80003756:	64a2                	ld	s1,8(sp)
    80003758:	6105                	add	sp,sp,32
    8000375a:	8082                	ret

000000008000375c <ilock>:
{
    8000375c:	1101                	add	sp,sp,-32
    8000375e:	ec06                	sd	ra,24(sp)
    80003760:	e822                	sd	s0,16(sp)
    80003762:	e426                	sd	s1,8(sp)
    80003764:	e04a                	sd	s2,0(sp)
    80003766:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003768:	c115                	beqz	a0,8000378c <ilock+0x30>
    8000376a:	84aa                	mv	s1,a0
    8000376c:	451c                	lw	a5,8(a0)
    8000376e:	00f05f63          	blez	a5,8000378c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003772:	0541                	add	a0,a0,16
    80003774:	00001097          	auipc	ra,0x1
    80003778:	c7e080e7          	jalr	-898(ra) # 800043f2 <acquiresleep>
  if(ip->valid == 0){
    8000377c:	40bc                	lw	a5,64(s1)
    8000377e:	cf99                	beqz	a5,8000379c <ilock+0x40>
}
    80003780:	60e2                	ld	ra,24(sp)
    80003782:	6442                	ld	s0,16(sp)
    80003784:	64a2                	ld	s1,8(sp)
    80003786:	6902                	ld	s2,0(sp)
    80003788:	6105                	add	sp,sp,32
    8000378a:	8082                	ret
    panic("ilock");
    8000378c:	00005517          	auipc	a0,0x5
    80003790:	e4450513          	add	a0,a0,-444 # 800085d0 <syscalls+0x190>
    80003794:	ffffd097          	auipc	ra,0xffffd
    80003798:	dae080e7          	jalr	-594(ra) # 80000542 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000379c:	40dc                	lw	a5,4(s1)
    8000379e:	0047d79b          	srlw	a5,a5,0x4
    800037a2:	0001d597          	auipc	a1,0x1d
    800037a6:	eb65a583          	lw	a1,-330(a1) # 80020658 <sb+0x18>
    800037aa:	9dbd                	addw	a1,a1,a5
    800037ac:	4088                	lw	a0,0(s1)
    800037ae:	fffff097          	auipc	ra,0xfffff
    800037b2:	7b4080e7          	jalr	1972(ra) # 80002f62 <bread>
    800037b6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037b8:	05850593          	add	a1,a0,88
    800037bc:	40dc                	lw	a5,4(s1)
    800037be:	8bbd                	and	a5,a5,15
    800037c0:	079a                	sll	a5,a5,0x6
    800037c2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037c4:	00059783          	lh	a5,0(a1)
    800037c8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037cc:	00259783          	lh	a5,2(a1)
    800037d0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037d4:	00459783          	lh	a5,4(a1)
    800037d8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037dc:	00659783          	lh	a5,6(a1)
    800037e0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037e4:	459c                	lw	a5,8(a1)
    800037e6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037e8:	03400613          	li	a2,52
    800037ec:	05b1                	add	a1,a1,12
    800037ee:	05048513          	add	a0,s1,80
    800037f2:	ffffd097          	auipc	ra,0xffffd
    800037f6:	5c6080e7          	jalr	1478(ra) # 80000db8 <memmove>
    brelse(bp);
    800037fa:	854a                	mv	a0,s2
    800037fc:	00000097          	auipc	ra,0x0
    80003800:	896080e7          	jalr	-1898(ra) # 80003092 <brelse>
    ip->valid = 1;
    80003804:	4785                	li	a5,1
    80003806:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003808:	04449783          	lh	a5,68(s1)
    8000380c:	fbb5                	bnez	a5,80003780 <ilock+0x24>
      panic("ilock: no type");
    8000380e:	00005517          	auipc	a0,0x5
    80003812:	dca50513          	add	a0,a0,-566 # 800085d8 <syscalls+0x198>
    80003816:	ffffd097          	auipc	ra,0xffffd
    8000381a:	d2c080e7          	jalr	-724(ra) # 80000542 <panic>

000000008000381e <iunlock>:
{
    8000381e:	1101                	add	sp,sp,-32
    80003820:	ec06                	sd	ra,24(sp)
    80003822:	e822                	sd	s0,16(sp)
    80003824:	e426                	sd	s1,8(sp)
    80003826:	e04a                	sd	s2,0(sp)
    80003828:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000382a:	c905                	beqz	a0,8000385a <iunlock+0x3c>
    8000382c:	84aa                	mv	s1,a0
    8000382e:	01050913          	add	s2,a0,16
    80003832:	854a                	mv	a0,s2
    80003834:	00001097          	auipc	ra,0x1
    80003838:	c58080e7          	jalr	-936(ra) # 8000448c <holdingsleep>
    8000383c:	cd19                	beqz	a0,8000385a <iunlock+0x3c>
    8000383e:	449c                	lw	a5,8(s1)
    80003840:	00f05d63          	blez	a5,8000385a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003844:	854a                	mv	a0,s2
    80003846:	00001097          	auipc	ra,0x1
    8000384a:	c02080e7          	jalr	-1022(ra) # 80004448 <releasesleep>
}
    8000384e:	60e2                	ld	ra,24(sp)
    80003850:	6442                	ld	s0,16(sp)
    80003852:	64a2                	ld	s1,8(sp)
    80003854:	6902                	ld	s2,0(sp)
    80003856:	6105                	add	sp,sp,32
    80003858:	8082                	ret
    panic("iunlock");
    8000385a:	00005517          	auipc	a0,0x5
    8000385e:	d8e50513          	add	a0,a0,-626 # 800085e8 <syscalls+0x1a8>
    80003862:	ffffd097          	auipc	ra,0xffffd
    80003866:	ce0080e7          	jalr	-800(ra) # 80000542 <panic>

000000008000386a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000386a:	7179                	add	sp,sp,-48
    8000386c:	f406                	sd	ra,40(sp)
    8000386e:	f022                	sd	s0,32(sp)
    80003870:	ec26                	sd	s1,24(sp)
    80003872:	e84a                	sd	s2,16(sp)
    80003874:	e44e                	sd	s3,8(sp)
    80003876:	e052                	sd	s4,0(sp)
    80003878:	1800                	add	s0,sp,48
    8000387a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000387c:	05050493          	add	s1,a0,80
    80003880:	08050913          	add	s2,a0,128
    80003884:	a021                	j	8000388c <itrunc+0x22>
    80003886:	0491                	add	s1,s1,4
    80003888:	01248d63          	beq	s1,s2,800038a2 <itrunc+0x38>
    if(ip->addrs[i]){
    8000388c:	408c                	lw	a1,0(s1)
    8000388e:	dde5                	beqz	a1,80003886 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003890:	0009a503          	lw	a0,0(s3)
    80003894:	00000097          	auipc	ra,0x0
    80003898:	912080e7          	jalr	-1774(ra) # 800031a6 <bfree>
      ip->addrs[i] = 0;
    8000389c:	0004a023          	sw	zero,0(s1)
    800038a0:	b7dd                	j	80003886 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038a2:	0809a583          	lw	a1,128(s3)
    800038a6:	e185                	bnez	a1,800038c6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038a8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038ac:	854e                	mv	a0,s3
    800038ae:	00000097          	auipc	ra,0x0
    800038b2:	de2080e7          	jalr	-542(ra) # 80003690 <iupdate>
}
    800038b6:	70a2                	ld	ra,40(sp)
    800038b8:	7402                	ld	s0,32(sp)
    800038ba:	64e2                	ld	s1,24(sp)
    800038bc:	6942                	ld	s2,16(sp)
    800038be:	69a2                	ld	s3,8(sp)
    800038c0:	6a02                	ld	s4,0(sp)
    800038c2:	6145                	add	sp,sp,48
    800038c4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038c6:	0009a503          	lw	a0,0(s3)
    800038ca:	fffff097          	auipc	ra,0xfffff
    800038ce:	698080e7          	jalr	1688(ra) # 80002f62 <bread>
    800038d2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038d4:	05850493          	add	s1,a0,88
    800038d8:	45850913          	add	s2,a0,1112
    800038dc:	a021                	j	800038e4 <itrunc+0x7a>
    800038de:	0491                	add	s1,s1,4
    800038e0:	01248b63          	beq	s1,s2,800038f6 <itrunc+0x8c>
      if(a[j])
    800038e4:	408c                	lw	a1,0(s1)
    800038e6:	dde5                	beqz	a1,800038de <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800038e8:	0009a503          	lw	a0,0(s3)
    800038ec:	00000097          	auipc	ra,0x0
    800038f0:	8ba080e7          	jalr	-1862(ra) # 800031a6 <bfree>
    800038f4:	b7ed                	j	800038de <itrunc+0x74>
    brelse(bp);
    800038f6:	8552                	mv	a0,s4
    800038f8:	fffff097          	auipc	ra,0xfffff
    800038fc:	79a080e7          	jalr	1946(ra) # 80003092 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003900:	0809a583          	lw	a1,128(s3)
    80003904:	0009a503          	lw	a0,0(s3)
    80003908:	00000097          	auipc	ra,0x0
    8000390c:	89e080e7          	jalr	-1890(ra) # 800031a6 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003910:	0809a023          	sw	zero,128(s3)
    80003914:	bf51                	j	800038a8 <itrunc+0x3e>

0000000080003916 <iput>:
{
    80003916:	1101                	add	sp,sp,-32
    80003918:	ec06                	sd	ra,24(sp)
    8000391a:	e822                	sd	s0,16(sp)
    8000391c:	e426                	sd	s1,8(sp)
    8000391e:	e04a                	sd	s2,0(sp)
    80003920:	1000                	add	s0,sp,32
    80003922:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003924:	0001d517          	auipc	a0,0x1d
    80003928:	d3c50513          	add	a0,a0,-708 # 80020660 <icache>
    8000392c:	ffffd097          	auipc	ra,0xffffd
    80003930:	334080e7          	jalr	820(ra) # 80000c60 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003934:	4498                	lw	a4,8(s1)
    80003936:	4785                	li	a5,1
    80003938:	02f70363          	beq	a4,a5,8000395e <iput+0x48>
  ip->ref--;
    8000393c:	449c                	lw	a5,8(s1)
    8000393e:	37fd                	addw	a5,a5,-1
    80003940:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003942:	0001d517          	auipc	a0,0x1d
    80003946:	d1e50513          	add	a0,a0,-738 # 80020660 <icache>
    8000394a:	ffffd097          	auipc	ra,0xffffd
    8000394e:	3ca080e7          	jalr	970(ra) # 80000d14 <release>
}
    80003952:	60e2                	ld	ra,24(sp)
    80003954:	6442                	ld	s0,16(sp)
    80003956:	64a2                	ld	s1,8(sp)
    80003958:	6902                	ld	s2,0(sp)
    8000395a:	6105                	add	sp,sp,32
    8000395c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000395e:	40bc                	lw	a5,64(s1)
    80003960:	dff1                	beqz	a5,8000393c <iput+0x26>
    80003962:	04a49783          	lh	a5,74(s1)
    80003966:	fbf9                	bnez	a5,8000393c <iput+0x26>
    acquiresleep(&ip->lock);
    80003968:	01048913          	add	s2,s1,16
    8000396c:	854a                	mv	a0,s2
    8000396e:	00001097          	auipc	ra,0x1
    80003972:	a84080e7          	jalr	-1404(ra) # 800043f2 <acquiresleep>
    release(&icache.lock);
    80003976:	0001d517          	auipc	a0,0x1d
    8000397a:	cea50513          	add	a0,a0,-790 # 80020660 <icache>
    8000397e:	ffffd097          	auipc	ra,0xffffd
    80003982:	396080e7          	jalr	918(ra) # 80000d14 <release>
    itrunc(ip);
    80003986:	8526                	mv	a0,s1
    80003988:	00000097          	auipc	ra,0x0
    8000398c:	ee2080e7          	jalr	-286(ra) # 8000386a <itrunc>
    ip->type = 0;
    80003990:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003994:	8526                	mv	a0,s1
    80003996:	00000097          	auipc	ra,0x0
    8000399a:	cfa080e7          	jalr	-774(ra) # 80003690 <iupdate>
    ip->valid = 0;
    8000399e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039a2:	854a                	mv	a0,s2
    800039a4:	00001097          	auipc	ra,0x1
    800039a8:	aa4080e7          	jalr	-1372(ra) # 80004448 <releasesleep>
    acquire(&icache.lock);
    800039ac:	0001d517          	auipc	a0,0x1d
    800039b0:	cb450513          	add	a0,a0,-844 # 80020660 <icache>
    800039b4:	ffffd097          	auipc	ra,0xffffd
    800039b8:	2ac080e7          	jalr	684(ra) # 80000c60 <acquire>
    800039bc:	b741                	j	8000393c <iput+0x26>

00000000800039be <iunlockput>:
{
    800039be:	1101                	add	sp,sp,-32
    800039c0:	ec06                	sd	ra,24(sp)
    800039c2:	e822                	sd	s0,16(sp)
    800039c4:	e426                	sd	s1,8(sp)
    800039c6:	1000                	add	s0,sp,32
    800039c8:	84aa                	mv	s1,a0
  iunlock(ip);
    800039ca:	00000097          	auipc	ra,0x0
    800039ce:	e54080e7          	jalr	-428(ra) # 8000381e <iunlock>
  iput(ip);
    800039d2:	8526                	mv	a0,s1
    800039d4:	00000097          	auipc	ra,0x0
    800039d8:	f42080e7          	jalr	-190(ra) # 80003916 <iput>
}
    800039dc:	60e2                	ld	ra,24(sp)
    800039de:	6442                	ld	s0,16(sp)
    800039e0:	64a2                	ld	s1,8(sp)
    800039e2:	6105                	add	sp,sp,32
    800039e4:	8082                	ret

00000000800039e6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039e6:	1141                	add	sp,sp,-16
    800039e8:	e422                	sd	s0,8(sp)
    800039ea:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    800039ec:	411c                	lw	a5,0(a0)
    800039ee:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039f0:	415c                	lw	a5,4(a0)
    800039f2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039f4:	04451783          	lh	a5,68(a0)
    800039f8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039fc:	04a51783          	lh	a5,74(a0)
    80003a00:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a04:	04c56783          	lwu	a5,76(a0)
    80003a08:	e99c                	sd	a5,16(a1)
}
    80003a0a:	6422                	ld	s0,8(sp)
    80003a0c:	0141                	add	sp,sp,16
    80003a0e:	8082                	ret

0000000080003a10 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a10:	457c                	lw	a5,76(a0)
    80003a12:	0ed7e863          	bltu	a5,a3,80003b02 <readi+0xf2>
{
    80003a16:	7159                	add	sp,sp,-112
    80003a18:	f486                	sd	ra,104(sp)
    80003a1a:	f0a2                	sd	s0,96(sp)
    80003a1c:	eca6                	sd	s1,88(sp)
    80003a1e:	e8ca                	sd	s2,80(sp)
    80003a20:	e4ce                	sd	s3,72(sp)
    80003a22:	e0d2                	sd	s4,64(sp)
    80003a24:	fc56                	sd	s5,56(sp)
    80003a26:	f85a                	sd	s6,48(sp)
    80003a28:	f45e                	sd	s7,40(sp)
    80003a2a:	f062                	sd	s8,32(sp)
    80003a2c:	ec66                	sd	s9,24(sp)
    80003a2e:	e86a                	sd	s10,16(sp)
    80003a30:	e46e                	sd	s11,8(sp)
    80003a32:	1880                	add	s0,sp,112
    80003a34:	8baa                	mv	s7,a0
    80003a36:	8c2e                	mv	s8,a1
    80003a38:	8ab2                	mv	s5,a2
    80003a3a:	84b6                	mv	s1,a3
    80003a3c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a3e:	9f35                	addw	a4,a4,a3
    return 0;
    80003a40:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a42:	08d76f63          	bltu	a4,a3,80003ae0 <readi+0xd0>
  if(off + n > ip->size)
    80003a46:	00e7f463          	bgeu	a5,a4,80003a4e <readi+0x3e>
    n = ip->size - off;
    80003a4a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a4e:	0a0b0863          	beqz	s6,80003afe <readi+0xee>
    80003a52:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a54:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a58:	5cfd                	li	s9,-1
    80003a5a:	a82d                	j	80003a94 <readi+0x84>
    80003a5c:	020a1d93          	sll	s11,s4,0x20
    80003a60:	020ddd93          	srl	s11,s11,0x20
    80003a64:	05890613          	add	a2,s2,88
    80003a68:	86ee                	mv	a3,s11
    80003a6a:	963a                	add	a2,a2,a4
    80003a6c:	85d6                	mv	a1,s5
    80003a6e:	8562                	mv	a0,s8
    80003a70:	fffff097          	auipc	ra,0xfffff
    80003a74:	a44080e7          	jalr	-1468(ra) # 800024b4 <either_copyout>
    80003a78:	05950d63          	beq	a0,s9,80003ad2 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003a7c:	854a                	mv	a0,s2
    80003a7e:	fffff097          	auipc	ra,0xfffff
    80003a82:	614080e7          	jalr	1556(ra) # 80003092 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a86:	013a09bb          	addw	s3,s4,s3
    80003a8a:	009a04bb          	addw	s1,s4,s1
    80003a8e:	9aee                	add	s5,s5,s11
    80003a90:	0569f663          	bgeu	s3,s6,80003adc <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a94:	000ba903          	lw	s2,0(s7)
    80003a98:	00a4d59b          	srlw	a1,s1,0xa
    80003a9c:	855e                	mv	a0,s7
    80003a9e:	00000097          	auipc	ra,0x0
    80003aa2:	8b2080e7          	jalr	-1870(ra) # 80003350 <bmap>
    80003aa6:	0005059b          	sext.w	a1,a0
    80003aaa:	854a                	mv	a0,s2
    80003aac:	fffff097          	auipc	ra,0xfffff
    80003ab0:	4b6080e7          	jalr	1206(ra) # 80002f62 <bread>
    80003ab4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ab6:	3ff4f713          	and	a4,s1,1023
    80003aba:	40ed07bb          	subw	a5,s10,a4
    80003abe:	413b06bb          	subw	a3,s6,s3
    80003ac2:	8a3e                	mv	s4,a5
    80003ac4:	2781                	sext.w	a5,a5
    80003ac6:	0006861b          	sext.w	a2,a3
    80003aca:	f8f679e3          	bgeu	a2,a5,80003a5c <readi+0x4c>
    80003ace:	8a36                	mv	s4,a3
    80003ad0:	b771                	j	80003a5c <readi+0x4c>
      brelse(bp);
    80003ad2:	854a                	mv	a0,s2
    80003ad4:	fffff097          	auipc	ra,0xfffff
    80003ad8:	5be080e7          	jalr	1470(ra) # 80003092 <brelse>
  }
  return tot;
    80003adc:	0009851b          	sext.w	a0,s3
}
    80003ae0:	70a6                	ld	ra,104(sp)
    80003ae2:	7406                	ld	s0,96(sp)
    80003ae4:	64e6                	ld	s1,88(sp)
    80003ae6:	6946                	ld	s2,80(sp)
    80003ae8:	69a6                	ld	s3,72(sp)
    80003aea:	6a06                	ld	s4,64(sp)
    80003aec:	7ae2                	ld	s5,56(sp)
    80003aee:	7b42                	ld	s6,48(sp)
    80003af0:	7ba2                	ld	s7,40(sp)
    80003af2:	7c02                	ld	s8,32(sp)
    80003af4:	6ce2                	ld	s9,24(sp)
    80003af6:	6d42                	ld	s10,16(sp)
    80003af8:	6da2                	ld	s11,8(sp)
    80003afa:	6165                	add	sp,sp,112
    80003afc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003afe:	89da                	mv	s3,s6
    80003b00:	bff1                	j	80003adc <readi+0xcc>
    return 0;
    80003b02:	4501                	li	a0,0
}
    80003b04:	8082                	ret

0000000080003b06 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b06:	457c                	lw	a5,76(a0)
    80003b08:	10d7e663          	bltu	a5,a3,80003c14 <writei+0x10e>
{
    80003b0c:	7159                	add	sp,sp,-112
    80003b0e:	f486                	sd	ra,104(sp)
    80003b10:	f0a2                	sd	s0,96(sp)
    80003b12:	eca6                	sd	s1,88(sp)
    80003b14:	e8ca                	sd	s2,80(sp)
    80003b16:	e4ce                	sd	s3,72(sp)
    80003b18:	e0d2                	sd	s4,64(sp)
    80003b1a:	fc56                	sd	s5,56(sp)
    80003b1c:	f85a                	sd	s6,48(sp)
    80003b1e:	f45e                	sd	s7,40(sp)
    80003b20:	f062                	sd	s8,32(sp)
    80003b22:	ec66                	sd	s9,24(sp)
    80003b24:	e86a                	sd	s10,16(sp)
    80003b26:	e46e                	sd	s11,8(sp)
    80003b28:	1880                	add	s0,sp,112
    80003b2a:	8baa                	mv	s7,a0
    80003b2c:	8c2e                	mv	s8,a1
    80003b2e:	8ab2                	mv	s5,a2
    80003b30:	8936                	mv	s2,a3
    80003b32:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b34:	00e687bb          	addw	a5,a3,a4
    80003b38:	0ed7e063          	bltu	a5,a3,80003c18 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b3c:	00043737          	lui	a4,0x43
    80003b40:	0cf76e63          	bltu	a4,a5,80003c1c <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b44:	0a0b0763          	beqz	s6,80003bf2 <writei+0xec>
    80003b48:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b4a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b4e:	5cfd                	li	s9,-1
    80003b50:	a091                	j	80003b94 <writei+0x8e>
    80003b52:	02099d93          	sll	s11,s3,0x20
    80003b56:	020ddd93          	srl	s11,s11,0x20
    80003b5a:	05848513          	add	a0,s1,88
    80003b5e:	86ee                	mv	a3,s11
    80003b60:	8656                	mv	a2,s5
    80003b62:	85e2                	mv	a1,s8
    80003b64:	953a                	add	a0,a0,a4
    80003b66:	fffff097          	auipc	ra,0xfffff
    80003b6a:	9a4080e7          	jalr	-1628(ra) # 8000250a <either_copyin>
    80003b6e:	07950263          	beq	a0,s9,80003bd2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b72:	8526                	mv	a0,s1
    80003b74:	00000097          	auipc	ra,0x0
    80003b78:	758080e7          	jalr	1880(ra) # 800042cc <log_write>
    brelse(bp);
    80003b7c:	8526                	mv	a0,s1
    80003b7e:	fffff097          	auipc	ra,0xfffff
    80003b82:	514080e7          	jalr	1300(ra) # 80003092 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b86:	01498a3b          	addw	s4,s3,s4
    80003b8a:	0129893b          	addw	s2,s3,s2
    80003b8e:	9aee                	add	s5,s5,s11
    80003b90:	056a7663          	bgeu	s4,s6,80003bdc <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b94:	000ba483          	lw	s1,0(s7)
    80003b98:	00a9559b          	srlw	a1,s2,0xa
    80003b9c:	855e                	mv	a0,s7
    80003b9e:	fffff097          	auipc	ra,0xfffff
    80003ba2:	7b2080e7          	jalr	1970(ra) # 80003350 <bmap>
    80003ba6:	0005059b          	sext.w	a1,a0
    80003baa:	8526                	mv	a0,s1
    80003bac:	fffff097          	auipc	ra,0xfffff
    80003bb0:	3b6080e7          	jalr	950(ra) # 80002f62 <bread>
    80003bb4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bb6:	3ff97713          	and	a4,s2,1023
    80003bba:	40ed07bb          	subw	a5,s10,a4
    80003bbe:	414b06bb          	subw	a3,s6,s4
    80003bc2:	89be                	mv	s3,a5
    80003bc4:	2781                	sext.w	a5,a5
    80003bc6:	0006861b          	sext.w	a2,a3
    80003bca:	f8f674e3          	bgeu	a2,a5,80003b52 <writei+0x4c>
    80003bce:	89b6                	mv	s3,a3
    80003bd0:	b749                	j	80003b52 <writei+0x4c>
      brelse(bp);
    80003bd2:	8526                	mv	a0,s1
    80003bd4:	fffff097          	auipc	ra,0xfffff
    80003bd8:	4be080e7          	jalr	1214(ra) # 80003092 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003bdc:	04cba783          	lw	a5,76(s7)
    80003be0:	0127f463          	bgeu	a5,s2,80003be8 <writei+0xe2>
      ip->size = off;
    80003be4:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003be8:	855e                	mv	a0,s7
    80003bea:	00000097          	auipc	ra,0x0
    80003bee:	aa6080e7          	jalr	-1370(ra) # 80003690 <iupdate>
  }

  return n;
    80003bf2:	000b051b          	sext.w	a0,s6
}
    80003bf6:	70a6                	ld	ra,104(sp)
    80003bf8:	7406                	ld	s0,96(sp)
    80003bfa:	64e6                	ld	s1,88(sp)
    80003bfc:	6946                	ld	s2,80(sp)
    80003bfe:	69a6                	ld	s3,72(sp)
    80003c00:	6a06                	ld	s4,64(sp)
    80003c02:	7ae2                	ld	s5,56(sp)
    80003c04:	7b42                	ld	s6,48(sp)
    80003c06:	7ba2                	ld	s7,40(sp)
    80003c08:	7c02                	ld	s8,32(sp)
    80003c0a:	6ce2                	ld	s9,24(sp)
    80003c0c:	6d42                	ld	s10,16(sp)
    80003c0e:	6da2                	ld	s11,8(sp)
    80003c10:	6165                	add	sp,sp,112
    80003c12:	8082                	ret
    return -1;
    80003c14:	557d                	li	a0,-1
}
    80003c16:	8082                	ret
    return -1;
    80003c18:	557d                	li	a0,-1
    80003c1a:	bff1                	j	80003bf6 <writei+0xf0>
    return -1;
    80003c1c:	557d                	li	a0,-1
    80003c1e:	bfe1                	j	80003bf6 <writei+0xf0>

0000000080003c20 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c20:	1141                	add	sp,sp,-16
    80003c22:	e406                	sd	ra,8(sp)
    80003c24:	e022                	sd	s0,0(sp)
    80003c26:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c28:	4639                	li	a2,14
    80003c2a:	ffffd097          	auipc	ra,0xffffd
    80003c2e:	20a080e7          	jalr	522(ra) # 80000e34 <strncmp>
}
    80003c32:	60a2                	ld	ra,8(sp)
    80003c34:	6402                	ld	s0,0(sp)
    80003c36:	0141                	add	sp,sp,16
    80003c38:	8082                	ret

0000000080003c3a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c3a:	7139                	add	sp,sp,-64
    80003c3c:	fc06                	sd	ra,56(sp)
    80003c3e:	f822                	sd	s0,48(sp)
    80003c40:	f426                	sd	s1,40(sp)
    80003c42:	f04a                	sd	s2,32(sp)
    80003c44:	ec4e                	sd	s3,24(sp)
    80003c46:	e852                	sd	s4,16(sp)
    80003c48:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c4a:	04451703          	lh	a4,68(a0)
    80003c4e:	4785                	li	a5,1
    80003c50:	00f71a63          	bne	a4,a5,80003c64 <dirlookup+0x2a>
    80003c54:	892a                	mv	s2,a0
    80003c56:	89ae                	mv	s3,a1
    80003c58:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c5a:	457c                	lw	a5,76(a0)
    80003c5c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c5e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c60:	e79d                	bnez	a5,80003c8e <dirlookup+0x54>
    80003c62:	a8a5                	j	80003cda <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c64:	00005517          	auipc	a0,0x5
    80003c68:	98c50513          	add	a0,a0,-1652 # 800085f0 <syscalls+0x1b0>
    80003c6c:	ffffd097          	auipc	ra,0xffffd
    80003c70:	8d6080e7          	jalr	-1834(ra) # 80000542 <panic>
      panic("dirlookup read");
    80003c74:	00005517          	auipc	a0,0x5
    80003c78:	99450513          	add	a0,a0,-1644 # 80008608 <syscalls+0x1c8>
    80003c7c:	ffffd097          	auipc	ra,0xffffd
    80003c80:	8c6080e7          	jalr	-1850(ra) # 80000542 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c84:	24c1                	addw	s1,s1,16
    80003c86:	04c92783          	lw	a5,76(s2)
    80003c8a:	04f4f763          	bgeu	s1,a5,80003cd8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c8e:	4741                	li	a4,16
    80003c90:	86a6                	mv	a3,s1
    80003c92:	fc040613          	add	a2,s0,-64
    80003c96:	4581                	li	a1,0
    80003c98:	854a                	mv	a0,s2
    80003c9a:	00000097          	auipc	ra,0x0
    80003c9e:	d76080e7          	jalr	-650(ra) # 80003a10 <readi>
    80003ca2:	47c1                	li	a5,16
    80003ca4:	fcf518e3          	bne	a0,a5,80003c74 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ca8:	fc045783          	lhu	a5,-64(s0)
    80003cac:	dfe1                	beqz	a5,80003c84 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cae:	fc240593          	add	a1,s0,-62
    80003cb2:	854e                	mv	a0,s3
    80003cb4:	00000097          	auipc	ra,0x0
    80003cb8:	f6c080e7          	jalr	-148(ra) # 80003c20 <namecmp>
    80003cbc:	f561                	bnez	a0,80003c84 <dirlookup+0x4a>
      if(poff)
    80003cbe:	000a0463          	beqz	s4,80003cc6 <dirlookup+0x8c>
        *poff = off;
    80003cc2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cc6:	fc045583          	lhu	a1,-64(s0)
    80003cca:	00092503          	lw	a0,0(s2)
    80003cce:	fffff097          	auipc	ra,0xfffff
    80003cd2:	75e080e7          	jalr	1886(ra) # 8000342c <iget>
    80003cd6:	a011                	j	80003cda <dirlookup+0xa0>
  return 0;
    80003cd8:	4501                	li	a0,0
}
    80003cda:	70e2                	ld	ra,56(sp)
    80003cdc:	7442                	ld	s0,48(sp)
    80003cde:	74a2                	ld	s1,40(sp)
    80003ce0:	7902                	ld	s2,32(sp)
    80003ce2:	69e2                	ld	s3,24(sp)
    80003ce4:	6a42                	ld	s4,16(sp)
    80003ce6:	6121                	add	sp,sp,64
    80003ce8:	8082                	ret

0000000080003cea <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cea:	711d                	add	sp,sp,-96
    80003cec:	ec86                	sd	ra,88(sp)
    80003cee:	e8a2                	sd	s0,80(sp)
    80003cf0:	e4a6                	sd	s1,72(sp)
    80003cf2:	e0ca                	sd	s2,64(sp)
    80003cf4:	fc4e                	sd	s3,56(sp)
    80003cf6:	f852                	sd	s4,48(sp)
    80003cf8:	f456                	sd	s5,40(sp)
    80003cfa:	f05a                	sd	s6,32(sp)
    80003cfc:	ec5e                	sd	s7,24(sp)
    80003cfe:	e862                	sd	s8,16(sp)
    80003d00:	e466                	sd	s9,8(sp)
    80003d02:	1080                	add	s0,sp,96
    80003d04:	84aa                	mv	s1,a0
    80003d06:	8b2e                	mv	s6,a1
    80003d08:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d0a:	00054703          	lbu	a4,0(a0)
    80003d0e:	02f00793          	li	a5,47
    80003d12:	02f70263          	beq	a4,a5,80003d36 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d16:	ffffe097          	auipc	ra,0xffffe
    80003d1a:	d14080e7          	jalr	-748(ra) # 80001a2a <myproc>
    80003d1e:	15053503          	ld	a0,336(a0)
    80003d22:	00000097          	auipc	ra,0x0
    80003d26:	9fc080e7          	jalr	-1540(ra) # 8000371e <idup>
    80003d2a:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003d2c:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003d30:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d32:	4b85                	li	s7,1
    80003d34:	a875                	j	80003df0 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003d36:	4585                	li	a1,1
    80003d38:	4505                	li	a0,1
    80003d3a:	fffff097          	auipc	ra,0xfffff
    80003d3e:	6f2080e7          	jalr	1778(ra) # 8000342c <iget>
    80003d42:	8a2a                	mv	s4,a0
    80003d44:	b7e5                	j	80003d2c <namex+0x42>
      iunlockput(ip);
    80003d46:	8552                	mv	a0,s4
    80003d48:	00000097          	auipc	ra,0x0
    80003d4c:	c76080e7          	jalr	-906(ra) # 800039be <iunlockput>
      return 0;
    80003d50:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d52:	8552                	mv	a0,s4
    80003d54:	60e6                	ld	ra,88(sp)
    80003d56:	6446                	ld	s0,80(sp)
    80003d58:	64a6                	ld	s1,72(sp)
    80003d5a:	6906                	ld	s2,64(sp)
    80003d5c:	79e2                	ld	s3,56(sp)
    80003d5e:	7a42                	ld	s4,48(sp)
    80003d60:	7aa2                	ld	s5,40(sp)
    80003d62:	7b02                	ld	s6,32(sp)
    80003d64:	6be2                	ld	s7,24(sp)
    80003d66:	6c42                	ld	s8,16(sp)
    80003d68:	6ca2                	ld	s9,8(sp)
    80003d6a:	6125                	add	sp,sp,96
    80003d6c:	8082                	ret
      iunlock(ip);
    80003d6e:	8552                	mv	a0,s4
    80003d70:	00000097          	auipc	ra,0x0
    80003d74:	aae080e7          	jalr	-1362(ra) # 8000381e <iunlock>
      return ip;
    80003d78:	bfe9                	j	80003d52 <namex+0x68>
      iunlockput(ip);
    80003d7a:	8552                	mv	a0,s4
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	c42080e7          	jalr	-958(ra) # 800039be <iunlockput>
      return 0;
    80003d84:	8a4e                	mv	s4,s3
    80003d86:	b7f1                	j	80003d52 <namex+0x68>
  len = path - s;
    80003d88:	40998633          	sub	a2,s3,s1
    80003d8c:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003d90:	099c5863          	bge	s8,s9,80003e20 <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003d94:	4639                	li	a2,14
    80003d96:	85a6                	mv	a1,s1
    80003d98:	8556                	mv	a0,s5
    80003d9a:	ffffd097          	auipc	ra,0xffffd
    80003d9e:	01e080e7          	jalr	30(ra) # 80000db8 <memmove>
    80003da2:	84ce                	mv	s1,s3
  while(*path == '/')
    80003da4:	0004c783          	lbu	a5,0(s1)
    80003da8:	01279763          	bne	a5,s2,80003db6 <namex+0xcc>
    path++;
    80003dac:	0485                	add	s1,s1,1
  while(*path == '/')
    80003dae:	0004c783          	lbu	a5,0(s1)
    80003db2:	ff278de3          	beq	a5,s2,80003dac <namex+0xc2>
    ilock(ip);
    80003db6:	8552                	mv	a0,s4
    80003db8:	00000097          	auipc	ra,0x0
    80003dbc:	9a4080e7          	jalr	-1628(ra) # 8000375c <ilock>
    if(ip->type != T_DIR){
    80003dc0:	044a1783          	lh	a5,68(s4)
    80003dc4:	f97791e3          	bne	a5,s7,80003d46 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80003dc8:	000b0563          	beqz	s6,80003dd2 <namex+0xe8>
    80003dcc:	0004c783          	lbu	a5,0(s1)
    80003dd0:	dfd9                	beqz	a5,80003d6e <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003dd2:	4601                	li	a2,0
    80003dd4:	85d6                	mv	a1,s5
    80003dd6:	8552                	mv	a0,s4
    80003dd8:	00000097          	auipc	ra,0x0
    80003ddc:	e62080e7          	jalr	-414(ra) # 80003c3a <dirlookup>
    80003de0:	89aa                	mv	s3,a0
    80003de2:	dd41                	beqz	a0,80003d7a <namex+0x90>
    iunlockput(ip);
    80003de4:	8552                	mv	a0,s4
    80003de6:	00000097          	auipc	ra,0x0
    80003dea:	bd8080e7          	jalr	-1064(ra) # 800039be <iunlockput>
    ip = next;
    80003dee:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003df0:	0004c783          	lbu	a5,0(s1)
    80003df4:	01279763          	bne	a5,s2,80003e02 <namex+0x118>
    path++;
    80003df8:	0485                	add	s1,s1,1
  while(*path == '/')
    80003dfa:	0004c783          	lbu	a5,0(s1)
    80003dfe:	ff278de3          	beq	a5,s2,80003df8 <namex+0x10e>
  if(*path == 0)
    80003e02:	cb9d                	beqz	a5,80003e38 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80003e04:	0004c783          	lbu	a5,0(s1)
    80003e08:	89a6                	mv	s3,s1
  len = path - s;
    80003e0a:	4c81                	li	s9,0
    80003e0c:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003e0e:	01278963          	beq	a5,s2,80003e20 <namex+0x136>
    80003e12:	dbbd                	beqz	a5,80003d88 <namex+0x9e>
    path++;
    80003e14:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    80003e16:	0009c783          	lbu	a5,0(s3)
    80003e1a:	ff279ce3          	bne	a5,s2,80003e12 <namex+0x128>
    80003e1e:	b7ad                	j	80003d88 <namex+0x9e>
    memmove(name, s, len);
    80003e20:	2601                	sext.w	a2,a2
    80003e22:	85a6                	mv	a1,s1
    80003e24:	8556                	mv	a0,s5
    80003e26:	ffffd097          	auipc	ra,0xffffd
    80003e2a:	f92080e7          	jalr	-110(ra) # 80000db8 <memmove>
    name[len] = 0;
    80003e2e:	9cd6                	add	s9,s9,s5
    80003e30:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003e34:	84ce                	mv	s1,s3
    80003e36:	b7bd                	j	80003da4 <namex+0xba>
  if(nameiparent){
    80003e38:	f00b0de3          	beqz	s6,80003d52 <namex+0x68>
    iput(ip);
    80003e3c:	8552                	mv	a0,s4
    80003e3e:	00000097          	auipc	ra,0x0
    80003e42:	ad8080e7          	jalr	-1320(ra) # 80003916 <iput>
    return 0;
    80003e46:	4a01                	li	s4,0
    80003e48:	b729                	j	80003d52 <namex+0x68>

0000000080003e4a <dirlink>:
{
    80003e4a:	7139                	add	sp,sp,-64
    80003e4c:	fc06                	sd	ra,56(sp)
    80003e4e:	f822                	sd	s0,48(sp)
    80003e50:	f426                	sd	s1,40(sp)
    80003e52:	f04a                	sd	s2,32(sp)
    80003e54:	ec4e                	sd	s3,24(sp)
    80003e56:	e852                	sd	s4,16(sp)
    80003e58:	0080                	add	s0,sp,64
    80003e5a:	892a                	mv	s2,a0
    80003e5c:	8a2e                	mv	s4,a1
    80003e5e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e60:	4601                	li	a2,0
    80003e62:	00000097          	auipc	ra,0x0
    80003e66:	dd8080e7          	jalr	-552(ra) # 80003c3a <dirlookup>
    80003e6a:	e93d                	bnez	a0,80003ee0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e6c:	04c92483          	lw	s1,76(s2)
    80003e70:	c49d                	beqz	s1,80003e9e <dirlink+0x54>
    80003e72:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e74:	4741                	li	a4,16
    80003e76:	86a6                	mv	a3,s1
    80003e78:	fc040613          	add	a2,s0,-64
    80003e7c:	4581                	li	a1,0
    80003e7e:	854a                	mv	a0,s2
    80003e80:	00000097          	auipc	ra,0x0
    80003e84:	b90080e7          	jalr	-1136(ra) # 80003a10 <readi>
    80003e88:	47c1                	li	a5,16
    80003e8a:	06f51163          	bne	a0,a5,80003eec <dirlink+0xa2>
    if(de.inum == 0)
    80003e8e:	fc045783          	lhu	a5,-64(s0)
    80003e92:	c791                	beqz	a5,80003e9e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e94:	24c1                	addw	s1,s1,16
    80003e96:	04c92783          	lw	a5,76(s2)
    80003e9a:	fcf4ede3          	bltu	s1,a5,80003e74 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e9e:	4639                	li	a2,14
    80003ea0:	85d2                	mv	a1,s4
    80003ea2:	fc240513          	add	a0,s0,-62
    80003ea6:	ffffd097          	auipc	ra,0xffffd
    80003eaa:	fca080e7          	jalr	-54(ra) # 80000e70 <strncpy>
  de.inum = inum;
    80003eae:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eb2:	4741                	li	a4,16
    80003eb4:	86a6                	mv	a3,s1
    80003eb6:	fc040613          	add	a2,s0,-64
    80003eba:	4581                	li	a1,0
    80003ebc:	854a                	mv	a0,s2
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	c48080e7          	jalr	-952(ra) # 80003b06 <writei>
    80003ec6:	872a                	mv	a4,a0
    80003ec8:	47c1                	li	a5,16
  return 0;
    80003eca:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ecc:	02f71863          	bne	a4,a5,80003efc <dirlink+0xb2>
}
    80003ed0:	70e2                	ld	ra,56(sp)
    80003ed2:	7442                	ld	s0,48(sp)
    80003ed4:	74a2                	ld	s1,40(sp)
    80003ed6:	7902                	ld	s2,32(sp)
    80003ed8:	69e2                	ld	s3,24(sp)
    80003eda:	6a42                	ld	s4,16(sp)
    80003edc:	6121                	add	sp,sp,64
    80003ede:	8082                	ret
    iput(ip);
    80003ee0:	00000097          	auipc	ra,0x0
    80003ee4:	a36080e7          	jalr	-1482(ra) # 80003916 <iput>
    return -1;
    80003ee8:	557d                	li	a0,-1
    80003eea:	b7dd                	j	80003ed0 <dirlink+0x86>
      panic("dirlink read");
    80003eec:	00004517          	auipc	a0,0x4
    80003ef0:	72c50513          	add	a0,a0,1836 # 80008618 <syscalls+0x1d8>
    80003ef4:	ffffc097          	auipc	ra,0xffffc
    80003ef8:	64e080e7          	jalr	1614(ra) # 80000542 <panic>
    panic("dirlink");
    80003efc:	00005517          	auipc	a0,0x5
    80003f00:	83c50513          	add	a0,a0,-1988 # 80008738 <syscalls+0x2f8>
    80003f04:	ffffc097          	auipc	ra,0xffffc
    80003f08:	63e080e7          	jalr	1598(ra) # 80000542 <panic>

0000000080003f0c <namei>:

struct inode*
namei(char *path)
{
    80003f0c:	1101                	add	sp,sp,-32
    80003f0e:	ec06                	sd	ra,24(sp)
    80003f10:	e822                	sd	s0,16(sp)
    80003f12:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f14:	fe040613          	add	a2,s0,-32
    80003f18:	4581                	li	a1,0
    80003f1a:	00000097          	auipc	ra,0x0
    80003f1e:	dd0080e7          	jalr	-560(ra) # 80003cea <namex>
}
    80003f22:	60e2                	ld	ra,24(sp)
    80003f24:	6442                	ld	s0,16(sp)
    80003f26:	6105                	add	sp,sp,32
    80003f28:	8082                	ret

0000000080003f2a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f2a:	1141                	add	sp,sp,-16
    80003f2c:	e406                	sd	ra,8(sp)
    80003f2e:	e022                	sd	s0,0(sp)
    80003f30:	0800                	add	s0,sp,16
    80003f32:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f34:	4585                	li	a1,1
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	db4080e7          	jalr	-588(ra) # 80003cea <namex>
}
    80003f3e:	60a2                	ld	ra,8(sp)
    80003f40:	6402                	ld	s0,0(sp)
    80003f42:	0141                	add	sp,sp,16
    80003f44:	8082                	ret

0000000080003f46 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f46:	1101                	add	sp,sp,-32
    80003f48:	ec06                	sd	ra,24(sp)
    80003f4a:	e822                	sd	s0,16(sp)
    80003f4c:	e426                	sd	s1,8(sp)
    80003f4e:	e04a                	sd	s2,0(sp)
    80003f50:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f52:	0001e917          	auipc	s2,0x1e
    80003f56:	1b690913          	add	s2,s2,438 # 80022108 <log>
    80003f5a:	01892583          	lw	a1,24(s2)
    80003f5e:	02892503          	lw	a0,40(s2)
    80003f62:	fffff097          	auipc	ra,0xfffff
    80003f66:	000080e7          	jalr	ra # 80002f62 <bread>
    80003f6a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f6c:	02c92603          	lw	a2,44(s2)
    80003f70:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f72:	00c05f63          	blez	a2,80003f90 <write_head+0x4a>
    80003f76:	0001e717          	auipc	a4,0x1e
    80003f7a:	1c270713          	add	a4,a4,450 # 80022138 <log+0x30>
    80003f7e:	87aa                	mv	a5,a0
    80003f80:	060a                	sll	a2,a2,0x2
    80003f82:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003f84:	4314                	lw	a3,0(a4)
    80003f86:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003f88:	0711                	add	a4,a4,4
    80003f8a:	0791                	add	a5,a5,4
    80003f8c:	fec79ce3          	bne	a5,a2,80003f84 <write_head+0x3e>
  }
  bwrite(buf);
    80003f90:	8526                	mv	a0,s1
    80003f92:	fffff097          	auipc	ra,0xfffff
    80003f96:	0c2080e7          	jalr	194(ra) # 80003054 <bwrite>
  brelse(buf);
    80003f9a:	8526                	mv	a0,s1
    80003f9c:	fffff097          	auipc	ra,0xfffff
    80003fa0:	0f6080e7          	jalr	246(ra) # 80003092 <brelse>
}
    80003fa4:	60e2                	ld	ra,24(sp)
    80003fa6:	6442                	ld	s0,16(sp)
    80003fa8:	64a2                	ld	s1,8(sp)
    80003faa:	6902                	ld	s2,0(sp)
    80003fac:	6105                	add	sp,sp,32
    80003fae:	8082                	ret

0000000080003fb0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fb0:	0001e797          	auipc	a5,0x1e
    80003fb4:	1847a783          	lw	a5,388(a5) # 80022134 <log+0x2c>
    80003fb8:	0af05663          	blez	a5,80004064 <install_trans+0xb4>
{
    80003fbc:	7139                	add	sp,sp,-64
    80003fbe:	fc06                	sd	ra,56(sp)
    80003fc0:	f822                	sd	s0,48(sp)
    80003fc2:	f426                	sd	s1,40(sp)
    80003fc4:	f04a                	sd	s2,32(sp)
    80003fc6:	ec4e                	sd	s3,24(sp)
    80003fc8:	e852                	sd	s4,16(sp)
    80003fca:	e456                	sd	s5,8(sp)
    80003fcc:	0080                	add	s0,sp,64
    80003fce:	0001ea97          	auipc	s5,0x1e
    80003fd2:	16aa8a93          	add	s5,s5,362 # 80022138 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fd6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fd8:	0001e997          	auipc	s3,0x1e
    80003fdc:	13098993          	add	s3,s3,304 # 80022108 <log>
    80003fe0:	0189a583          	lw	a1,24(s3)
    80003fe4:	014585bb          	addw	a1,a1,s4
    80003fe8:	2585                	addw	a1,a1,1
    80003fea:	0289a503          	lw	a0,40(s3)
    80003fee:	fffff097          	auipc	ra,0xfffff
    80003ff2:	f74080e7          	jalr	-140(ra) # 80002f62 <bread>
    80003ff6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ff8:	000aa583          	lw	a1,0(s5)
    80003ffc:	0289a503          	lw	a0,40(s3)
    80004000:	fffff097          	auipc	ra,0xfffff
    80004004:	f62080e7          	jalr	-158(ra) # 80002f62 <bread>
    80004008:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000400a:	40000613          	li	a2,1024
    8000400e:	05890593          	add	a1,s2,88
    80004012:	05850513          	add	a0,a0,88
    80004016:	ffffd097          	auipc	ra,0xffffd
    8000401a:	da2080e7          	jalr	-606(ra) # 80000db8 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000401e:	8526                	mv	a0,s1
    80004020:	fffff097          	auipc	ra,0xfffff
    80004024:	034080e7          	jalr	52(ra) # 80003054 <bwrite>
    bunpin(dbuf);
    80004028:	8526                	mv	a0,s1
    8000402a:	fffff097          	auipc	ra,0xfffff
    8000402e:	140080e7          	jalr	320(ra) # 8000316a <bunpin>
    brelse(lbuf);
    80004032:	854a                	mv	a0,s2
    80004034:	fffff097          	auipc	ra,0xfffff
    80004038:	05e080e7          	jalr	94(ra) # 80003092 <brelse>
    brelse(dbuf);
    8000403c:	8526                	mv	a0,s1
    8000403e:	fffff097          	auipc	ra,0xfffff
    80004042:	054080e7          	jalr	84(ra) # 80003092 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004046:	2a05                	addw	s4,s4,1
    80004048:	0a91                	add	s5,s5,4
    8000404a:	02c9a783          	lw	a5,44(s3)
    8000404e:	f8fa49e3          	blt	s4,a5,80003fe0 <install_trans+0x30>
}
    80004052:	70e2                	ld	ra,56(sp)
    80004054:	7442                	ld	s0,48(sp)
    80004056:	74a2                	ld	s1,40(sp)
    80004058:	7902                	ld	s2,32(sp)
    8000405a:	69e2                	ld	s3,24(sp)
    8000405c:	6a42                	ld	s4,16(sp)
    8000405e:	6aa2                	ld	s5,8(sp)
    80004060:	6121                	add	sp,sp,64
    80004062:	8082                	ret
    80004064:	8082                	ret

0000000080004066 <initlog>:
{
    80004066:	7179                	add	sp,sp,-48
    80004068:	f406                	sd	ra,40(sp)
    8000406a:	f022                	sd	s0,32(sp)
    8000406c:	ec26                	sd	s1,24(sp)
    8000406e:	e84a                	sd	s2,16(sp)
    80004070:	e44e                	sd	s3,8(sp)
    80004072:	1800                	add	s0,sp,48
    80004074:	892a                	mv	s2,a0
    80004076:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004078:	0001e497          	auipc	s1,0x1e
    8000407c:	09048493          	add	s1,s1,144 # 80022108 <log>
    80004080:	00004597          	auipc	a1,0x4
    80004084:	5a858593          	add	a1,a1,1448 # 80008628 <syscalls+0x1e8>
    80004088:	8526                	mv	a0,s1
    8000408a:	ffffd097          	auipc	ra,0xffffd
    8000408e:	b46080e7          	jalr	-1210(ra) # 80000bd0 <initlock>
  log.start = sb->logstart;
    80004092:	0149a583          	lw	a1,20(s3)
    80004096:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004098:	0109a783          	lw	a5,16(s3)
    8000409c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000409e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040a2:	854a                	mv	a0,s2
    800040a4:	fffff097          	auipc	ra,0xfffff
    800040a8:	ebe080e7          	jalr	-322(ra) # 80002f62 <bread>
  log.lh.n = lh->n;
    800040ac:	4d30                	lw	a2,88(a0)
    800040ae:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040b0:	00c05f63          	blez	a2,800040ce <initlog+0x68>
    800040b4:	87aa                	mv	a5,a0
    800040b6:	0001e717          	auipc	a4,0x1e
    800040ba:	08270713          	add	a4,a4,130 # 80022138 <log+0x30>
    800040be:	060a                	sll	a2,a2,0x2
    800040c0:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800040c2:	4ff4                	lw	a3,92(a5)
    800040c4:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040c6:	0791                	add	a5,a5,4
    800040c8:	0711                	add	a4,a4,4
    800040ca:	fec79ce3          	bne	a5,a2,800040c2 <initlog+0x5c>
  brelse(buf);
    800040ce:	fffff097          	auipc	ra,0xfffff
    800040d2:	fc4080e7          	jalr	-60(ra) # 80003092 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800040d6:	00000097          	auipc	ra,0x0
    800040da:	eda080e7          	jalr	-294(ra) # 80003fb0 <install_trans>
  log.lh.n = 0;
    800040de:	0001e797          	auipc	a5,0x1e
    800040e2:	0407ab23          	sw	zero,86(a5) # 80022134 <log+0x2c>
  write_head(); // clear the log
    800040e6:	00000097          	auipc	ra,0x0
    800040ea:	e60080e7          	jalr	-416(ra) # 80003f46 <write_head>
}
    800040ee:	70a2                	ld	ra,40(sp)
    800040f0:	7402                	ld	s0,32(sp)
    800040f2:	64e2                	ld	s1,24(sp)
    800040f4:	6942                	ld	s2,16(sp)
    800040f6:	69a2                	ld	s3,8(sp)
    800040f8:	6145                	add	sp,sp,48
    800040fa:	8082                	ret

00000000800040fc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040fc:	1101                	add	sp,sp,-32
    800040fe:	ec06                	sd	ra,24(sp)
    80004100:	e822                	sd	s0,16(sp)
    80004102:	e426                	sd	s1,8(sp)
    80004104:	e04a                	sd	s2,0(sp)
    80004106:	1000                	add	s0,sp,32
  acquire(&log.lock);
    80004108:	0001e517          	auipc	a0,0x1e
    8000410c:	00050513          	mv	a0,a0
    80004110:	ffffd097          	auipc	ra,0xffffd
    80004114:	b50080e7          	jalr	-1200(ra) # 80000c60 <acquire>
  while(1){
    if(log.committing){
    80004118:	0001e497          	auipc	s1,0x1e
    8000411c:	ff048493          	add	s1,s1,-16 # 80022108 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004120:	4979                	li	s2,30
    80004122:	a039                	j	80004130 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004124:	85a6                	mv	a1,s1
    80004126:	8526                	mv	a0,s1
    80004128:	ffffe097          	auipc	ra,0xffffe
    8000412c:	132080e7          	jalr	306(ra) # 8000225a <sleep>
    if(log.committing){
    80004130:	50dc                	lw	a5,36(s1)
    80004132:	fbed                	bnez	a5,80004124 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004134:	5098                	lw	a4,32(s1)
    80004136:	2705                	addw	a4,a4,1
    80004138:	0027179b          	sllw	a5,a4,0x2
    8000413c:	9fb9                	addw	a5,a5,a4
    8000413e:	0017979b          	sllw	a5,a5,0x1
    80004142:	54d4                	lw	a3,44(s1)
    80004144:	9fb5                	addw	a5,a5,a3
    80004146:	00f95963          	bge	s2,a5,80004158 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000414a:	85a6                	mv	a1,s1
    8000414c:	8526                	mv	a0,s1
    8000414e:	ffffe097          	auipc	ra,0xffffe
    80004152:	10c080e7          	jalr	268(ra) # 8000225a <sleep>
    80004156:	bfe9                	j	80004130 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004158:	0001e517          	auipc	a0,0x1e
    8000415c:	fb050513          	add	a0,a0,-80 # 80022108 <log>
    80004160:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004162:	ffffd097          	auipc	ra,0xffffd
    80004166:	bb2080e7          	jalr	-1102(ra) # 80000d14 <release>
      break;
    }
  }
}
    8000416a:	60e2                	ld	ra,24(sp)
    8000416c:	6442                	ld	s0,16(sp)
    8000416e:	64a2                	ld	s1,8(sp)
    80004170:	6902                	ld	s2,0(sp)
    80004172:	6105                	add	sp,sp,32
    80004174:	8082                	ret

0000000080004176 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004176:	7139                	add	sp,sp,-64
    80004178:	fc06                	sd	ra,56(sp)
    8000417a:	f822                	sd	s0,48(sp)
    8000417c:	f426                	sd	s1,40(sp)
    8000417e:	f04a                	sd	s2,32(sp)
    80004180:	ec4e                	sd	s3,24(sp)
    80004182:	e852                	sd	s4,16(sp)
    80004184:	e456                	sd	s5,8(sp)
    80004186:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004188:	0001e497          	auipc	s1,0x1e
    8000418c:	f8048493          	add	s1,s1,-128 # 80022108 <log>
    80004190:	8526                	mv	a0,s1
    80004192:	ffffd097          	auipc	ra,0xffffd
    80004196:	ace080e7          	jalr	-1330(ra) # 80000c60 <acquire>
  log.outstanding -= 1;
    8000419a:	509c                	lw	a5,32(s1)
    8000419c:	37fd                	addw	a5,a5,-1
    8000419e:	0007891b          	sext.w	s2,a5
    800041a2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041a4:	50dc                	lw	a5,36(s1)
    800041a6:	e7b9                	bnez	a5,800041f4 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041a8:	04091e63          	bnez	s2,80004204 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800041ac:	0001e497          	auipc	s1,0x1e
    800041b0:	f5c48493          	add	s1,s1,-164 # 80022108 <log>
    800041b4:	4785                	li	a5,1
    800041b6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041b8:	8526                	mv	a0,s1
    800041ba:	ffffd097          	auipc	ra,0xffffd
    800041be:	b5a080e7          	jalr	-1190(ra) # 80000d14 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041c2:	54dc                	lw	a5,44(s1)
    800041c4:	06f04763          	bgtz	a5,80004232 <end_op+0xbc>
    acquire(&log.lock);
    800041c8:	0001e497          	auipc	s1,0x1e
    800041cc:	f4048493          	add	s1,s1,-192 # 80022108 <log>
    800041d0:	8526                	mv	a0,s1
    800041d2:	ffffd097          	auipc	ra,0xffffd
    800041d6:	a8e080e7          	jalr	-1394(ra) # 80000c60 <acquire>
    log.committing = 0;
    800041da:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041de:	8526                	mv	a0,s1
    800041e0:	ffffe097          	auipc	ra,0xffffe
    800041e4:	1fa080e7          	jalr	506(ra) # 800023da <wakeup>
    release(&log.lock);
    800041e8:	8526                	mv	a0,s1
    800041ea:	ffffd097          	auipc	ra,0xffffd
    800041ee:	b2a080e7          	jalr	-1238(ra) # 80000d14 <release>
}
    800041f2:	a03d                	j	80004220 <end_op+0xaa>
    panic("log.committing");
    800041f4:	00004517          	auipc	a0,0x4
    800041f8:	43c50513          	add	a0,a0,1084 # 80008630 <syscalls+0x1f0>
    800041fc:	ffffc097          	auipc	ra,0xffffc
    80004200:	346080e7          	jalr	838(ra) # 80000542 <panic>
    wakeup(&log);
    80004204:	0001e497          	auipc	s1,0x1e
    80004208:	f0448493          	add	s1,s1,-252 # 80022108 <log>
    8000420c:	8526                	mv	a0,s1
    8000420e:	ffffe097          	auipc	ra,0xffffe
    80004212:	1cc080e7          	jalr	460(ra) # 800023da <wakeup>
  release(&log.lock);
    80004216:	8526                	mv	a0,s1
    80004218:	ffffd097          	auipc	ra,0xffffd
    8000421c:	afc080e7          	jalr	-1284(ra) # 80000d14 <release>
}
    80004220:	70e2                	ld	ra,56(sp)
    80004222:	7442                	ld	s0,48(sp)
    80004224:	74a2                	ld	s1,40(sp)
    80004226:	7902                	ld	s2,32(sp)
    80004228:	69e2                	ld	s3,24(sp)
    8000422a:	6a42                	ld	s4,16(sp)
    8000422c:	6aa2                	ld	s5,8(sp)
    8000422e:	6121                	add	sp,sp,64
    80004230:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004232:	0001ea97          	auipc	s5,0x1e
    80004236:	f06a8a93          	add	s5,s5,-250 # 80022138 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000423a:	0001ea17          	auipc	s4,0x1e
    8000423e:	ecea0a13          	add	s4,s4,-306 # 80022108 <log>
    80004242:	018a2583          	lw	a1,24(s4)
    80004246:	012585bb          	addw	a1,a1,s2
    8000424a:	2585                	addw	a1,a1,1
    8000424c:	028a2503          	lw	a0,40(s4)
    80004250:	fffff097          	auipc	ra,0xfffff
    80004254:	d12080e7          	jalr	-750(ra) # 80002f62 <bread>
    80004258:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000425a:	000aa583          	lw	a1,0(s5)
    8000425e:	028a2503          	lw	a0,40(s4)
    80004262:	fffff097          	auipc	ra,0xfffff
    80004266:	d00080e7          	jalr	-768(ra) # 80002f62 <bread>
    8000426a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000426c:	40000613          	li	a2,1024
    80004270:	05850593          	add	a1,a0,88
    80004274:	05848513          	add	a0,s1,88
    80004278:	ffffd097          	auipc	ra,0xffffd
    8000427c:	b40080e7          	jalr	-1216(ra) # 80000db8 <memmove>
    bwrite(to);  // write the log
    80004280:	8526                	mv	a0,s1
    80004282:	fffff097          	auipc	ra,0xfffff
    80004286:	dd2080e7          	jalr	-558(ra) # 80003054 <bwrite>
    brelse(from);
    8000428a:	854e                	mv	a0,s3
    8000428c:	fffff097          	auipc	ra,0xfffff
    80004290:	e06080e7          	jalr	-506(ra) # 80003092 <brelse>
    brelse(to);
    80004294:	8526                	mv	a0,s1
    80004296:	fffff097          	auipc	ra,0xfffff
    8000429a:	dfc080e7          	jalr	-516(ra) # 80003092 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000429e:	2905                	addw	s2,s2,1
    800042a0:	0a91                	add	s5,s5,4
    800042a2:	02ca2783          	lw	a5,44(s4)
    800042a6:	f8f94ee3          	blt	s2,a5,80004242 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042aa:	00000097          	auipc	ra,0x0
    800042ae:	c9c080e7          	jalr	-868(ra) # 80003f46 <write_head>
    install_trans(); // Now install writes to home locations
    800042b2:	00000097          	auipc	ra,0x0
    800042b6:	cfe080e7          	jalr	-770(ra) # 80003fb0 <install_trans>
    log.lh.n = 0;
    800042ba:	0001e797          	auipc	a5,0x1e
    800042be:	e607ad23          	sw	zero,-390(a5) # 80022134 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042c2:	00000097          	auipc	ra,0x0
    800042c6:	c84080e7          	jalr	-892(ra) # 80003f46 <write_head>
    800042ca:	bdfd                	j	800041c8 <end_op+0x52>

00000000800042cc <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042cc:	1101                	add	sp,sp,-32
    800042ce:	ec06                	sd	ra,24(sp)
    800042d0:	e822                	sd	s0,16(sp)
    800042d2:	e426                	sd	s1,8(sp)
    800042d4:	e04a                	sd	s2,0(sp)
    800042d6:	1000                	add	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042d8:	0001e717          	auipc	a4,0x1e
    800042dc:	e5c72703          	lw	a4,-420(a4) # 80022134 <log+0x2c>
    800042e0:	47f5                	li	a5,29
    800042e2:	08e7c063          	blt	a5,a4,80004362 <log_write+0x96>
    800042e6:	84aa                	mv	s1,a0
    800042e8:	0001e797          	auipc	a5,0x1e
    800042ec:	e3c7a783          	lw	a5,-452(a5) # 80022124 <log+0x1c>
    800042f0:	37fd                	addw	a5,a5,-1
    800042f2:	06f75863          	bge	a4,a5,80004362 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042f6:	0001e797          	auipc	a5,0x1e
    800042fa:	e327a783          	lw	a5,-462(a5) # 80022128 <log+0x20>
    800042fe:	06f05a63          	blez	a5,80004372 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004302:	0001e917          	auipc	s2,0x1e
    80004306:	e0690913          	add	s2,s2,-506 # 80022108 <log>
    8000430a:	854a                	mv	a0,s2
    8000430c:	ffffd097          	auipc	ra,0xffffd
    80004310:	954080e7          	jalr	-1708(ra) # 80000c60 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004314:	02c92603          	lw	a2,44(s2)
    80004318:	06c05563          	blez	a2,80004382 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000431c:	44cc                	lw	a1,12(s1)
    8000431e:	0001e717          	auipc	a4,0x1e
    80004322:	e1a70713          	add	a4,a4,-486 # 80022138 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004326:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004328:	4314                	lw	a3,0(a4)
    8000432a:	04b68d63          	beq	a3,a1,80004384 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000432e:	2785                	addw	a5,a5,1
    80004330:	0711                	add	a4,a4,4
    80004332:	fec79be3          	bne	a5,a2,80004328 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004336:	0621                	add	a2,a2,8
    80004338:	060a                	sll	a2,a2,0x2
    8000433a:	0001e797          	auipc	a5,0x1e
    8000433e:	dce78793          	add	a5,a5,-562 # 80022108 <log>
    80004342:	97b2                	add	a5,a5,a2
    80004344:	44d8                	lw	a4,12(s1)
    80004346:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004348:	8526                	mv	a0,s1
    8000434a:	fffff097          	auipc	ra,0xfffff
    8000434e:	de4080e7          	jalr	-540(ra) # 8000312e <bpin>
    log.lh.n++;
    80004352:	0001e717          	auipc	a4,0x1e
    80004356:	db670713          	add	a4,a4,-586 # 80022108 <log>
    8000435a:	575c                	lw	a5,44(a4)
    8000435c:	2785                	addw	a5,a5,1
    8000435e:	d75c                	sw	a5,44(a4)
    80004360:	a835                	j	8000439c <log_write+0xd0>
    panic("too big a transaction");
    80004362:	00004517          	auipc	a0,0x4
    80004366:	2de50513          	add	a0,a0,734 # 80008640 <syscalls+0x200>
    8000436a:	ffffc097          	auipc	ra,0xffffc
    8000436e:	1d8080e7          	jalr	472(ra) # 80000542 <panic>
    panic("log_write outside of trans");
    80004372:	00004517          	auipc	a0,0x4
    80004376:	2e650513          	add	a0,a0,742 # 80008658 <syscalls+0x218>
    8000437a:	ffffc097          	auipc	ra,0xffffc
    8000437e:	1c8080e7          	jalr	456(ra) # 80000542 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004382:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004384:	00878693          	add	a3,a5,8
    80004388:	068a                	sll	a3,a3,0x2
    8000438a:	0001e717          	auipc	a4,0x1e
    8000438e:	d7e70713          	add	a4,a4,-642 # 80022108 <log>
    80004392:	9736                	add	a4,a4,a3
    80004394:	44d4                	lw	a3,12(s1)
    80004396:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004398:	faf608e3          	beq	a2,a5,80004348 <log_write+0x7c>
  }
  release(&log.lock);
    8000439c:	0001e517          	auipc	a0,0x1e
    800043a0:	d6c50513          	add	a0,a0,-660 # 80022108 <log>
    800043a4:	ffffd097          	auipc	ra,0xffffd
    800043a8:	970080e7          	jalr	-1680(ra) # 80000d14 <release>
}
    800043ac:	60e2                	ld	ra,24(sp)
    800043ae:	6442                	ld	s0,16(sp)
    800043b0:	64a2                	ld	s1,8(sp)
    800043b2:	6902                	ld	s2,0(sp)
    800043b4:	6105                	add	sp,sp,32
    800043b6:	8082                	ret

00000000800043b8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043b8:	1101                	add	sp,sp,-32
    800043ba:	ec06                	sd	ra,24(sp)
    800043bc:	e822                	sd	s0,16(sp)
    800043be:	e426                	sd	s1,8(sp)
    800043c0:	e04a                	sd	s2,0(sp)
    800043c2:	1000                	add	s0,sp,32
    800043c4:	84aa                	mv	s1,a0
    800043c6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043c8:	00004597          	auipc	a1,0x4
    800043cc:	2b058593          	add	a1,a1,688 # 80008678 <syscalls+0x238>
    800043d0:	0521                	add	a0,a0,8
    800043d2:	ffffc097          	auipc	ra,0xffffc
    800043d6:	7fe080e7          	jalr	2046(ra) # 80000bd0 <initlock>
  lk->name = name;
    800043da:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043de:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043e2:	0204a423          	sw	zero,40(s1)
}
    800043e6:	60e2                	ld	ra,24(sp)
    800043e8:	6442                	ld	s0,16(sp)
    800043ea:	64a2                	ld	s1,8(sp)
    800043ec:	6902                	ld	s2,0(sp)
    800043ee:	6105                	add	sp,sp,32
    800043f0:	8082                	ret

00000000800043f2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043f2:	1101                	add	sp,sp,-32
    800043f4:	ec06                	sd	ra,24(sp)
    800043f6:	e822                	sd	s0,16(sp)
    800043f8:	e426                	sd	s1,8(sp)
    800043fa:	e04a                	sd	s2,0(sp)
    800043fc:	1000                	add	s0,sp,32
    800043fe:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004400:	00850913          	add	s2,a0,8
    80004404:	854a                	mv	a0,s2
    80004406:	ffffd097          	auipc	ra,0xffffd
    8000440a:	85a080e7          	jalr	-1958(ra) # 80000c60 <acquire>
  while (lk->locked) {
    8000440e:	409c                	lw	a5,0(s1)
    80004410:	cb89                	beqz	a5,80004422 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004412:	85ca                	mv	a1,s2
    80004414:	8526                	mv	a0,s1
    80004416:	ffffe097          	auipc	ra,0xffffe
    8000441a:	e44080e7          	jalr	-444(ra) # 8000225a <sleep>
  while (lk->locked) {
    8000441e:	409c                	lw	a5,0(s1)
    80004420:	fbed                	bnez	a5,80004412 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004422:	4785                	li	a5,1
    80004424:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004426:	ffffd097          	auipc	ra,0xffffd
    8000442a:	604080e7          	jalr	1540(ra) # 80001a2a <myproc>
    8000442e:	5d1c                	lw	a5,56(a0)
    80004430:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004432:	854a                	mv	a0,s2
    80004434:	ffffd097          	auipc	ra,0xffffd
    80004438:	8e0080e7          	jalr	-1824(ra) # 80000d14 <release>
}
    8000443c:	60e2                	ld	ra,24(sp)
    8000443e:	6442                	ld	s0,16(sp)
    80004440:	64a2                	ld	s1,8(sp)
    80004442:	6902                	ld	s2,0(sp)
    80004444:	6105                	add	sp,sp,32
    80004446:	8082                	ret

0000000080004448 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004448:	1101                	add	sp,sp,-32
    8000444a:	ec06                	sd	ra,24(sp)
    8000444c:	e822                	sd	s0,16(sp)
    8000444e:	e426                	sd	s1,8(sp)
    80004450:	e04a                	sd	s2,0(sp)
    80004452:	1000                	add	s0,sp,32
    80004454:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004456:	00850913          	add	s2,a0,8
    8000445a:	854a                	mv	a0,s2
    8000445c:	ffffd097          	auipc	ra,0xffffd
    80004460:	804080e7          	jalr	-2044(ra) # 80000c60 <acquire>
  lk->locked = 0;
    80004464:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004468:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000446c:	8526                	mv	a0,s1
    8000446e:	ffffe097          	auipc	ra,0xffffe
    80004472:	f6c080e7          	jalr	-148(ra) # 800023da <wakeup>
  release(&lk->lk);
    80004476:	854a                	mv	a0,s2
    80004478:	ffffd097          	auipc	ra,0xffffd
    8000447c:	89c080e7          	jalr	-1892(ra) # 80000d14 <release>
}
    80004480:	60e2                	ld	ra,24(sp)
    80004482:	6442                	ld	s0,16(sp)
    80004484:	64a2                	ld	s1,8(sp)
    80004486:	6902                	ld	s2,0(sp)
    80004488:	6105                	add	sp,sp,32
    8000448a:	8082                	ret

000000008000448c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000448c:	7179                	add	sp,sp,-48
    8000448e:	f406                	sd	ra,40(sp)
    80004490:	f022                	sd	s0,32(sp)
    80004492:	ec26                	sd	s1,24(sp)
    80004494:	e84a                	sd	s2,16(sp)
    80004496:	e44e                	sd	s3,8(sp)
    80004498:	1800                	add	s0,sp,48
    8000449a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000449c:	00850913          	add	s2,a0,8
    800044a0:	854a                	mv	a0,s2
    800044a2:	ffffc097          	auipc	ra,0xffffc
    800044a6:	7be080e7          	jalr	1982(ra) # 80000c60 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044aa:	409c                	lw	a5,0(s1)
    800044ac:	ef99                	bnez	a5,800044ca <holdingsleep+0x3e>
    800044ae:	4481                	li	s1,0
  release(&lk->lk);
    800044b0:	854a                	mv	a0,s2
    800044b2:	ffffd097          	auipc	ra,0xffffd
    800044b6:	862080e7          	jalr	-1950(ra) # 80000d14 <release>
  return r;
}
    800044ba:	8526                	mv	a0,s1
    800044bc:	70a2                	ld	ra,40(sp)
    800044be:	7402                	ld	s0,32(sp)
    800044c0:	64e2                	ld	s1,24(sp)
    800044c2:	6942                	ld	s2,16(sp)
    800044c4:	69a2                	ld	s3,8(sp)
    800044c6:	6145                	add	sp,sp,48
    800044c8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044ca:	0284a983          	lw	s3,40(s1)
    800044ce:	ffffd097          	auipc	ra,0xffffd
    800044d2:	55c080e7          	jalr	1372(ra) # 80001a2a <myproc>
    800044d6:	5d04                	lw	s1,56(a0)
    800044d8:	413484b3          	sub	s1,s1,s3
    800044dc:	0014b493          	seqz	s1,s1
    800044e0:	bfc1                	j	800044b0 <holdingsleep+0x24>

00000000800044e2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044e2:	1141                	add	sp,sp,-16
    800044e4:	e406                	sd	ra,8(sp)
    800044e6:	e022                	sd	s0,0(sp)
    800044e8:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044ea:	00004597          	auipc	a1,0x4
    800044ee:	19e58593          	add	a1,a1,414 # 80008688 <syscalls+0x248>
    800044f2:	0001e517          	auipc	a0,0x1e
    800044f6:	d5e50513          	add	a0,a0,-674 # 80022250 <ftable>
    800044fa:	ffffc097          	auipc	ra,0xffffc
    800044fe:	6d6080e7          	jalr	1750(ra) # 80000bd0 <initlock>
}
    80004502:	60a2                	ld	ra,8(sp)
    80004504:	6402                	ld	s0,0(sp)
    80004506:	0141                	add	sp,sp,16
    80004508:	8082                	ret

000000008000450a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000450a:	1101                	add	sp,sp,-32
    8000450c:	ec06                	sd	ra,24(sp)
    8000450e:	e822                	sd	s0,16(sp)
    80004510:	e426                	sd	s1,8(sp)
    80004512:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004514:	0001e517          	auipc	a0,0x1e
    80004518:	d3c50513          	add	a0,a0,-708 # 80022250 <ftable>
    8000451c:	ffffc097          	auipc	ra,0xffffc
    80004520:	744080e7          	jalr	1860(ra) # 80000c60 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004524:	0001e497          	auipc	s1,0x1e
    80004528:	d4448493          	add	s1,s1,-700 # 80022268 <ftable+0x18>
    8000452c:	0001f717          	auipc	a4,0x1f
    80004530:	cdc70713          	add	a4,a4,-804 # 80023208 <ftable+0xfb8>
    if(f->ref == 0){
    80004534:	40dc                	lw	a5,4(s1)
    80004536:	cf99                	beqz	a5,80004554 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004538:	02848493          	add	s1,s1,40
    8000453c:	fee49ce3          	bne	s1,a4,80004534 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004540:	0001e517          	auipc	a0,0x1e
    80004544:	d1050513          	add	a0,a0,-752 # 80022250 <ftable>
    80004548:	ffffc097          	auipc	ra,0xffffc
    8000454c:	7cc080e7          	jalr	1996(ra) # 80000d14 <release>
  return 0;
    80004550:	4481                	li	s1,0
    80004552:	a819                	j	80004568 <filealloc+0x5e>
      f->ref = 1;
    80004554:	4785                	li	a5,1
    80004556:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004558:	0001e517          	auipc	a0,0x1e
    8000455c:	cf850513          	add	a0,a0,-776 # 80022250 <ftable>
    80004560:	ffffc097          	auipc	ra,0xffffc
    80004564:	7b4080e7          	jalr	1972(ra) # 80000d14 <release>
}
    80004568:	8526                	mv	a0,s1
    8000456a:	60e2                	ld	ra,24(sp)
    8000456c:	6442                	ld	s0,16(sp)
    8000456e:	64a2                	ld	s1,8(sp)
    80004570:	6105                	add	sp,sp,32
    80004572:	8082                	ret

0000000080004574 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004574:	1101                	add	sp,sp,-32
    80004576:	ec06                	sd	ra,24(sp)
    80004578:	e822                	sd	s0,16(sp)
    8000457a:	e426                	sd	s1,8(sp)
    8000457c:	1000                	add	s0,sp,32
    8000457e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004580:	0001e517          	auipc	a0,0x1e
    80004584:	cd050513          	add	a0,a0,-816 # 80022250 <ftable>
    80004588:	ffffc097          	auipc	ra,0xffffc
    8000458c:	6d8080e7          	jalr	1752(ra) # 80000c60 <acquire>
  if(f->ref < 1)
    80004590:	40dc                	lw	a5,4(s1)
    80004592:	02f05263          	blez	a5,800045b6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004596:	2785                	addw	a5,a5,1
    80004598:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000459a:	0001e517          	auipc	a0,0x1e
    8000459e:	cb650513          	add	a0,a0,-842 # 80022250 <ftable>
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	772080e7          	jalr	1906(ra) # 80000d14 <release>
  return f;
}
    800045aa:	8526                	mv	a0,s1
    800045ac:	60e2                	ld	ra,24(sp)
    800045ae:	6442                	ld	s0,16(sp)
    800045b0:	64a2                	ld	s1,8(sp)
    800045b2:	6105                	add	sp,sp,32
    800045b4:	8082                	ret
    panic("filedup");
    800045b6:	00004517          	auipc	a0,0x4
    800045ba:	0da50513          	add	a0,a0,218 # 80008690 <syscalls+0x250>
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	f84080e7          	jalr	-124(ra) # 80000542 <panic>

00000000800045c6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045c6:	7139                	add	sp,sp,-64
    800045c8:	fc06                	sd	ra,56(sp)
    800045ca:	f822                	sd	s0,48(sp)
    800045cc:	f426                	sd	s1,40(sp)
    800045ce:	f04a                	sd	s2,32(sp)
    800045d0:	ec4e                	sd	s3,24(sp)
    800045d2:	e852                	sd	s4,16(sp)
    800045d4:	e456                	sd	s5,8(sp)
    800045d6:	0080                	add	s0,sp,64
    800045d8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045da:	0001e517          	auipc	a0,0x1e
    800045de:	c7650513          	add	a0,a0,-906 # 80022250 <ftable>
    800045e2:	ffffc097          	auipc	ra,0xffffc
    800045e6:	67e080e7          	jalr	1662(ra) # 80000c60 <acquire>
  if(f->ref < 1)
    800045ea:	40dc                	lw	a5,4(s1)
    800045ec:	06f05163          	blez	a5,8000464e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045f0:	37fd                	addw	a5,a5,-1
    800045f2:	0007871b          	sext.w	a4,a5
    800045f6:	c0dc                	sw	a5,4(s1)
    800045f8:	06e04363          	bgtz	a4,8000465e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045fc:	0004a903          	lw	s2,0(s1)
    80004600:	0094ca83          	lbu	s5,9(s1)
    80004604:	0104ba03          	ld	s4,16(s1)
    80004608:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000460c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004610:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004614:	0001e517          	auipc	a0,0x1e
    80004618:	c3c50513          	add	a0,a0,-964 # 80022250 <ftable>
    8000461c:	ffffc097          	auipc	ra,0xffffc
    80004620:	6f8080e7          	jalr	1784(ra) # 80000d14 <release>

  if(ff.type == FD_PIPE){
    80004624:	4785                	li	a5,1
    80004626:	04f90d63          	beq	s2,a5,80004680 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000462a:	3979                	addw	s2,s2,-2
    8000462c:	4785                	li	a5,1
    8000462e:	0527e063          	bltu	a5,s2,8000466e <fileclose+0xa8>
    begin_op();
    80004632:	00000097          	auipc	ra,0x0
    80004636:	aca080e7          	jalr	-1334(ra) # 800040fc <begin_op>
    iput(ff.ip);
    8000463a:	854e                	mv	a0,s3
    8000463c:	fffff097          	auipc	ra,0xfffff
    80004640:	2da080e7          	jalr	730(ra) # 80003916 <iput>
    end_op();
    80004644:	00000097          	auipc	ra,0x0
    80004648:	b32080e7          	jalr	-1230(ra) # 80004176 <end_op>
    8000464c:	a00d                	j	8000466e <fileclose+0xa8>
    panic("fileclose");
    8000464e:	00004517          	auipc	a0,0x4
    80004652:	04a50513          	add	a0,a0,74 # 80008698 <syscalls+0x258>
    80004656:	ffffc097          	auipc	ra,0xffffc
    8000465a:	eec080e7          	jalr	-276(ra) # 80000542 <panic>
    release(&ftable.lock);
    8000465e:	0001e517          	auipc	a0,0x1e
    80004662:	bf250513          	add	a0,a0,-1038 # 80022250 <ftable>
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	6ae080e7          	jalr	1710(ra) # 80000d14 <release>
  }
}
    8000466e:	70e2                	ld	ra,56(sp)
    80004670:	7442                	ld	s0,48(sp)
    80004672:	74a2                	ld	s1,40(sp)
    80004674:	7902                	ld	s2,32(sp)
    80004676:	69e2                	ld	s3,24(sp)
    80004678:	6a42                	ld	s4,16(sp)
    8000467a:	6aa2                	ld	s5,8(sp)
    8000467c:	6121                	add	sp,sp,64
    8000467e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004680:	85d6                	mv	a1,s5
    80004682:	8552                	mv	a0,s4
    80004684:	00000097          	auipc	ra,0x0
    80004688:	372080e7          	jalr	882(ra) # 800049f6 <pipeclose>
    8000468c:	b7cd                	j	8000466e <fileclose+0xa8>

000000008000468e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000468e:	715d                	add	sp,sp,-80
    80004690:	e486                	sd	ra,72(sp)
    80004692:	e0a2                	sd	s0,64(sp)
    80004694:	fc26                	sd	s1,56(sp)
    80004696:	f84a                	sd	s2,48(sp)
    80004698:	f44e                	sd	s3,40(sp)
    8000469a:	0880                	add	s0,sp,80
    8000469c:	84aa                	mv	s1,a0
    8000469e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046a0:	ffffd097          	auipc	ra,0xffffd
    800046a4:	38a080e7          	jalr	906(ra) # 80001a2a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046a8:	409c                	lw	a5,0(s1)
    800046aa:	37f9                	addw	a5,a5,-2
    800046ac:	4705                	li	a4,1
    800046ae:	04f76763          	bltu	a4,a5,800046fc <filestat+0x6e>
    800046b2:	892a                	mv	s2,a0
    ilock(f->ip);
    800046b4:	6c88                	ld	a0,24(s1)
    800046b6:	fffff097          	auipc	ra,0xfffff
    800046ba:	0a6080e7          	jalr	166(ra) # 8000375c <ilock>
    stati(f->ip, &st);
    800046be:	fb840593          	add	a1,s0,-72
    800046c2:	6c88                	ld	a0,24(s1)
    800046c4:	fffff097          	auipc	ra,0xfffff
    800046c8:	322080e7          	jalr	802(ra) # 800039e6 <stati>
    iunlock(f->ip);
    800046cc:	6c88                	ld	a0,24(s1)
    800046ce:	fffff097          	auipc	ra,0xfffff
    800046d2:	150080e7          	jalr	336(ra) # 8000381e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046d6:	46e1                	li	a3,24
    800046d8:	fb840613          	add	a2,s0,-72
    800046dc:	85ce                	mv	a1,s3
    800046de:	05093503          	ld	a0,80(s2)
    800046e2:	ffffd097          	auipc	ra,0xffffd
    800046e6:	03e080e7          	jalr	62(ra) # 80001720 <copyout>
    800046ea:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046ee:	60a6                	ld	ra,72(sp)
    800046f0:	6406                	ld	s0,64(sp)
    800046f2:	74e2                	ld	s1,56(sp)
    800046f4:	7942                	ld	s2,48(sp)
    800046f6:	79a2                	ld	s3,40(sp)
    800046f8:	6161                	add	sp,sp,80
    800046fa:	8082                	ret
  return -1;
    800046fc:	557d                	li	a0,-1
    800046fe:	bfc5                	j	800046ee <filestat+0x60>

0000000080004700 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004700:	7179                	add	sp,sp,-48
    80004702:	f406                	sd	ra,40(sp)
    80004704:	f022                	sd	s0,32(sp)
    80004706:	ec26                	sd	s1,24(sp)
    80004708:	e84a                	sd	s2,16(sp)
    8000470a:	e44e                	sd	s3,8(sp)
    8000470c:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000470e:	00854783          	lbu	a5,8(a0)
    80004712:	c3d5                	beqz	a5,800047b6 <fileread+0xb6>
    80004714:	84aa                	mv	s1,a0
    80004716:	89ae                	mv	s3,a1
    80004718:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000471a:	411c                	lw	a5,0(a0)
    8000471c:	4705                	li	a4,1
    8000471e:	04e78963          	beq	a5,a4,80004770 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004722:	470d                	li	a4,3
    80004724:	04e78d63          	beq	a5,a4,8000477e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004728:	4709                	li	a4,2
    8000472a:	06e79e63          	bne	a5,a4,800047a6 <fileread+0xa6>
    ilock(f->ip);
    8000472e:	6d08                	ld	a0,24(a0)
    80004730:	fffff097          	auipc	ra,0xfffff
    80004734:	02c080e7          	jalr	44(ra) # 8000375c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004738:	874a                	mv	a4,s2
    8000473a:	5094                	lw	a3,32(s1)
    8000473c:	864e                	mv	a2,s3
    8000473e:	4585                	li	a1,1
    80004740:	6c88                	ld	a0,24(s1)
    80004742:	fffff097          	auipc	ra,0xfffff
    80004746:	2ce080e7          	jalr	718(ra) # 80003a10 <readi>
    8000474a:	892a                	mv	s2,a0
    8000474c:	00a05563          	blez	a0,80004756 <fileread+0x56>
      f->off += r;
    80004750:	509c                	lw	a5,32(s1)
    80004752:	9fa9                	addw	a5,a5,a0
    80004754:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004756:	6c88                	ld	a0,24(s1)
    80004758:	fffff097          	auipc	ra,0xfffff
    8000475c:	0c6080e7          	jalr	198(ra) # 8000381e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004760:	854a                	mv	a0,s2
    80004762:	70a2                	ld	ra,40(sp)
    80004764:	7402                	ld	s0,32(sp)
    80004766:	64e2                	ld	s1,24(sp)
    80004768:	6942                	ld	s2,16(sp)
    8000476a:	69a2                	ld	s3,8(sp)
    8000476c:	6145                	add	sp,sp,48
    8000476e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004770:	6908                	ld	a0,16(a0)
    80004772:	00000097          	auipc	ra,0x0
    80004776:	3ee080e7          	jalr	1006(ra) # 80004b60 <piperead>
    8000477a:	892a                	mv	s2,a0
    8000477c:	b7d5                	j	80004760 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000477e:	02451783          	lh	a5,36(a0)
    80004782:	03079693          	sll	a3,a5,0x30
    80004786:	92c1                	srl	a3,a3,0x30
    80004788:	4725                	li	a4,9
    8000478a:	02d76863          	bltu	a4,a3,800047ba <fileread+0xba>
    8000478e:	0792                	sll	a5,a5,0x4
    80004790:	0001e717          	auipc	a4,0x1e
    80004794:	a2070713          	add	a4,a4,-1504 # 800221b0 <devsw>
    80004798:	97ba                	add	a5,a5,a4
    8000479a:	639c                	ld	a5,0(a5)
    8000479c:	c38d                	beqz	a5,800047be <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000479e:	4505                	li	a0,1
    800047a0:	9782                	jalr	a5
    800047a2:	892a                	mv	s2,a0
    800047a4:	bf75                	j	80004760 <fileread+0x60>
    panic("fileread");
    800047a6:	00004517          	auipc	a0,0x4
    800047aa:	f0250513          	add	a0,a0,-254 # 800086a8 <syscalls+0x268>
    800047ae:	ffffc097          	auipc	ra,0xffffc
    800047b2:	d94080e7          	jalr	-620(ra) # 80000542 <panic>
    return -1;
    800047b6:	597d                	li	s2,-1
    800047b8:	b765                	j	80004760 <fileread+0x60>
      return -1;
    800047ba:	597d                	li	s2,-1
    800047bc:	b755                	j	80004760 <fileread+0x60>
    800047be:	597d                	li	s2,-1
    800047c0:	b745                	j	80004760 <fileread+0x60>

00000000800047c2 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800047c2:	00954783          	lbu	a5,9(a0)
    800047c6:	14078363          	beqz	a5,8000490c <filewrite+0x14a>
{
    800047ca:	715d                	add	sp,sp,-80
    800047cc:	e486                	sd	ra,72(sp)
    800047ce:	e0a2                	sd	s0,64(sp)
    800047d0:	fc26                	sd	s1,56(sp)
    800047d2:	f84a                	sd	s2,48(sp)
    800047d4:	f44e                	sd	s3,40(sp)
    800047d6:	f052                	sd	s4,32(sp)
    800047d8:	ec56                	sd	s5,24(sp)
    800047da:	e85a                	sd	s6,16(sp)
    800047dc:	e45e                	sd	s7,8(sp)
    800047de:	e062                	sd	s8,0(sp)
    800047e0:	0880                	add	s0,sp,80
    800047e2:	892a                	mv	s2,a0
    800047e4:	8b2e                	mv	s6,a1
    800047e6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047e8:	411c                	lw	a5,0(a0)
    800047ea:	4705                	li	a4,1
    800047ec:	02e78263          	beq	a5,a4,80004810 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047f0:	470d                	li	a4,3
    800047f2:	02e78563          	beq	a5,a4,8000481c <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047f6:	4709                	li	a4,2
    800047f8:	10e79263          	bne	a5,a4,800048fc <filewrite+0x13a>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047fc:	0ec05e63          	blez	a2,800048f8 <filewrite+0x136>
    int i = 0;
    80004800:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004802:	6b85                	lui	s7,0x1
    80004804:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004808:	6c05                	lui	s8,0x1
    8000480a:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    8000480e:	a851                	j	800048a2 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004810:	6908                	ld	a0,16(a0)
    80004812:	00000097          	auipc	ra,0x0
    80004816:	254080e7          	jalr	596(ra) # 80004a66 <pipewrite>
    8000481a:	a85d                	j	800048d0 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000481c:	02451783          	lh	a5,36(a0)
    80004820:	03079693          	sll	a3,a5,0x30
    80004824:	92c1                	srl	a3,a3,0x30
    80004826:	4725                	li	a4,9
    80004828:	0ed76463          	bltu	a4,a3,80004910 <filewrite+0x14e>
    8000482c:	0792                	sll	a5,a5,0x4
    8000482e:	0001e717          	auipc	a4,0x1e
    80004832:	98270713          	add	a4,a4,-1662 # 800221b0 <devsw>
    80004836:	97ba                	add	a5,a5,a4
    80004838:	679c                	ld	a5,8(a5)
    8000483a:	cfe9                	beqz	a5,80004914 <filewrite+0x152>
    ret = devsw[f->major].write(1, addr, n);
    8000483c:	4505                	li	a0,1
    8000483e:	9782                	jalr	a5
    80004840:	a841                	j	800048d0 <filewrite+0x10e>
      if(n1 > max)
    80004842:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004846:	00000097          	auipc	ra,0x0
    8000484a:	8b6080e7          	jalr	-1866(ra) # 800040fc <begin_op>
      ilock(f->ip);
    8000484e:	01893503          	ld	a0,24(s2)
    80004852:	fffff097          	auipc	ra,0xfffff
    80004856:	f0a080e7          	jalr	-246(ra) # 8000375c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000485a:	8756                	mv	a4,s5
    8000485c:	02092683          	lw	a3,32(s2)
    80004860:	01698633          	add	a2,s3,s6
    80004864:	4585                	li	a1,1
    80004866:	01893503          	ld	a0,24(s2)
    8000486a:	fffff097          	auipc	ra,0xfffff
    8000486e:	29c080e7          	jalr	668(ra) # 80003b06 <writei>
    80004872:	84aa                	mv	s1,a0
    80004874:	02a05f63          	blez	a0,800048b2 <filewrite+0xf0>
        f->off += r;
    80004878:	02092783          	lw	a5,32(s2)
    8000487c:	9fa9                	addw	a5,a5,a0
    8000487e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004882:	01893503          	ld	a0,24(s2)
    80004886:	fffff097          	auipc	ra,0xfffff
    8000488a:	f98080e7          	jalr	-104(ra) # 8000381e <iunlock>
      end_op();
    8000488e:	00000097          	auipc	ra,0x0
    80004892:	8e8080e7          	jalr	-1816(ra) # 80004176 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004896:	049a9963          	bne	s5,s1,800048e8 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    8000489a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000489e:	0349d663          	bge	s3,s4,800048ca <filewrite+0x108>
      int n1 = n - i;
    800048a2:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    800048a6:	0004879b          	sext.w	a5,s1
    800048aa:	f8fbdce3          	bge	s7,a5,80004842 <filewrite+0x80>
    800048ae:	84e2                	mv	s1,s8
    800048b0:	bf49                	j	80004842 <filewrite+0x80>
      iunlock(f->ip);
    800048b2:	01893503          	ld	a0,24(s2)
    800048b6:	fffff097          	auipc	ra,0xfffff
    800048ba:	f68080e7          	jalr	-152(ra) # 8000381e <iunlock>
      end_op();
    800048be:	00000097          	auipc	ra,0x0
    800048c2:	8b8080e7          	jalr	-1864(ra) # 80004176 <end_op>
      if(r < 0)
    800048c6:	fc04d8e3          	bgez	s1,80004896 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800048ca:	053a1763          	bne	s4,s3,80004918 <filewrite+0x156>
    800048ce:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048d0:	60a6                	ld	ra,72(sp)
    800048d2:	6406                	ld	s0,64(sp)
    800048d4:	74e2                	ld	s1,56(sp)
    800048d6:	7942                	ld	s2,48(sp)
    800048d8:	79a2                	ld	s3,40(sp)
    800048da:	7a02                	ld	s4,32(sp)
    800048dc:	6ae2                	ld	s5,24(sp)
    800048de:	6b42                	ld	s6,16(sp)
    800048e0:	6ba2                	ld	s7,8(sp)
    800048e2:	6c02                	ld	s8,0(sp)
    800048e4:	6161                	add	sp,sp,80
    800048e6:	8082                	ret
        panic("short filewrite");
    800048e8:	00004517          	auipc	a0,0x4
    800048ec:	dd050513          	add	a0,a0,-560 # 800086b8 <syscalls+0x278>
    800048f0:	ffffc097          	auipc	ra,0xffffc
    800048f4:	c52080e7          	jalr	-942(ra) # 80000542 <panic>
    int i = 0;
    800048f8:	4981                	li	s3,0
    800048fa:	bfc1                	j	800048ca <filewrite+0x108>
    panic("filewrite");
    800048fc:	00004517          	auipc	a0,0x4
    80004900:	dcc50513          	add	a0,a0,-564 # 800086c8 <syscalls+0x288>
    80004904:	ffffc097          	auipc	ra,0xffffc
    80004908:	c3e080e7          	jalr	-962(ra) # 80000542 <panic>
    return -1;
    8000490c:	557d                	li	a0,-1
}
    8000490e:	8082                	ret
      return -1;
    80004910:	557d                	li	a0,-1
    80004912:	bf7d                	j	800048d0 <filewrite+0x10e>
    80004914:	557d                	li	a0,-1
    80004916:	bf6d                	j	800048d0 <filewrite+0x10e>
    ret = (i == n ? n : -1);
    80004918:	557d                	li	a0,-1
    8000491a:	bf5d                	j	800048d0 <filewrite+0x10e>

000000008000491c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000491c:	7179                	add	sp,sp,-48
    8000491e:	f406                	sd	ra,40(sp)
    80004920:	f022                	sd	s0,32(sp)
    80004922:	ec26                	sd	s1,24(sp)
    80004924:	e84a                	sd	s2,16(sp)
    80004926:	e44e                	sd	s3,8(sp)
    80004928:	e052                	sd	s4,0(sp)
    8000492a:	1800                	add	s0,sp,48
    8000492c:	84aa                	mv	s1,a0
    8000492e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004930:	0005b023          	sd	zero,0(a1)
    80004934:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004938:	00000097          	auipc	ra,0x0
    8000493c:	bd2080e7          	jalr	-1070(ra) # 8000450a <filealloc>
    80004940:	e088                	sd	a0,0(s1)
    80004942:	c551                	beqz	a0,800049ce <pipealloc+0xb2>
    80004944:	00000097          	auipc	ra,0x0
    80004948:	bc6080e7          	jalr	-1082(ra) # 8000450a <filealloc>
    8000494c:	00aa3023          	sd	a0,0(s4)
    80004950:	c92d                	beqz	a0,800049c2 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004952:	ffffc097          	auipc	ra,0xffffc
    80004956:	21e080e7          	jalr	542(ra) # 80000b70 <kalloc>
    8000495a:	892a                	mv	s2,a0
    8000495c:	c125                	beqz	a0,800049bc <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000495e:	4985                	li	s3,1
    80004960:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004964:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004968:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000496c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004970:	00004597          	auipc	a1,0x4
    80004974:	d6858593          	add	a1,a1,-664 # 800086d8 <syscalls+0x298>
    80004978:	ffffc097          	auipc	ra,0xffffc
    8000497c:	258080e7          	jalr	600(ra) # 80000bd0 <initlock>
  (*f0)->type = FD_PIPE;
    80004980:	609c                	ld	a5,0(s1)
    80004982:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004986:	609c                	ld	a5,0(s1)
    80004988:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000498c:	609c                	ld	a5,0(s1)
    8000498e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004992:	609c                	ld	a5,0(s1)
    80004994:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004998:	000a3783          	ld	a5,0(s4)
    8000499c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049a0:	000a3783          	ld	a5,0(s4)
    800049a4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049a8:	000a3783          	ld	a5,0(s4)
    800049ac:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049b0:	000a3783          	ld	a5,0(s4)
    800049b4:	0127b823          	sd	s2,16(a5)
  return 0;
    800049b8:	4501                	li	a0,0
    800049ba:	a025                	j	800049e2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049bc:	6088                	ld	a0,0(s1)
    800049be:	e501                	bnez	a0,800049c6 <pipealloc+0xaa>
    800049c0:	a039                	j	800049ce <pipealloc+0xb2>
    800049c2:	6088                	ld	a0,0(s1)
    800049c4:	c51d                	beqz	a0,800049f2 <pipealloc+0xd6>
    fileclose(*f0);
    800049c6:	00000097          	auipc	ra,0x0
    800049ca:	c00080e7          	jalr	-1024(ra) # 800045c6 <fileclose>
  if(*f1)
    800049ce:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049d2:	557d                	li	a0,-1
  if(*f1)
    800049d4:	c799                	beqz	a5,800049e2 <pipealloc+0xc6>
    fileclose(*f1);
    800049d6:	853e                	mv	a0,a5
    800049d8:	00000097          	auipc	ra,0x0
    800049dc:	bee080e7          	jalr	-1042(ra) # 800045c6 <fileclose>
  return -1;
    800049e0:	557d                	li	a0,-1
}
    800049e2:	70a2                	ld	ra,40(sp)
    800049e4:	7402                	ld	s0,32(sp)
    800049e6:	64e2                	ld	s1,24(sp)
    800049e8:	6942                	ld	s2,16(sp)
    800049ea:	69a2                	ld	s3,8(sp)
    800049ec:	6a02                	ld	s4,0(sp)
    800049ee:	6145                	add	sp,sp,48
    800049f0:	8082                	ret
  return -1;
    800049f2:	557d                	li	a0,-1
    800049f4:	b7fd                	j	800049e2 <pipealloc+0xc6>

00000000800049f6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049f6:	1101                	add	sp,sp,-32
    800049f8:	ec06                	sd	ra,24(sp)
    800049fa:	e822                	sd	s0,16(sp)
    800049fc:	e426                	sd	s1,8(sp)
    800049fe:	e04a                	sd	s2,0(sp)
    80004a00:	1000                	add	s0,sp,32
    80004a02:	84aa                	mv	s1,a0
    80004a04:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a06:	ffffc097          	auipc	ra,0xffffc
    80004a0a:	25a080e7          	jalr	602(ra) # 80000c60 <acquire>
  if(writable){
    80004a0e:	02090d63          	beqz	s2,80004a48 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a12:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a16:	21848513          	add	a0,s1,536
    80004a1a:	ffffe097          	auipc	ra,0xffffe
    80004a1e:	9c0080e7          	jalr	-1600(ra) # 800023da <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a22:	2204b783          	ld	a5,544(s1)
    80004a26:	eb95                	bnez	a5,80004a5a <pipeclose+0x64>
    release(&pi->lock);
    80004a28:	8526                	mv	a0,s1
    80004a2a:	ffffc097          	auipc	ra,0xffffc
    80004a2e:	2ea080e7          	jalr	746(ra) # 80000d14 <release>
    kfree((char*)pi);
    80004a32:	8526                	mv	a0,s1
    80004a34:	ffffc097          	auipc	ra,0xffffc
    80004a38:	03e080e7          	jalr	62(ra) # 80000a72 <kfree>
  } else
    release(&pi->lock);
}
    80004a3c:	60e2                	ld	ra,24(sp)
    80004a3e:	6442                	ld	s0,16(sp)
    80004a40:	64a2                	ld	s1,8(sp)
    80004a42:	6902                	ld	s2,0(sp)
    80004a44:	6105                	add	sp,sp,32
    80004a46:	8082                	ret
    pi->readopen = 0;
    80004a48:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a4c:	21c48513          	add	a0,s1,540
    80004a50:	ffffe097          	auipc	ra,0xffffe
    80004a54:	98a080e7          	jalr	-1654(ra) # 800023da <wakeup>
    80004a58:	b7e9                	j	80004a22 <pipeclose+0x2c>
    release(&pi->lock);
    80004a5a:	8526                	mv	a0,s1
    80004a5c:	ffffc097          	auipc	ra,0xffffc
    80004a60:	2b8080e7          	jalr	696(ra) # 80000d14 <release>
}
    80004a64:	bfe1                	j	80004a3c <pipeclose+0x46>

0000000080004a66 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a66:	711d                	add	sp,sp,-96
    80004a68:	ec86                	sd	ra,88(sp)
    80004a6a:	e8a2                	sd	s0,80(sp)
    80004a6c:	e4a6                	sd	s1,72(sp)
    80004a6e:	e0ca                	sd	s2,64(sp)
    80004a70:	fc4e                	sd	s3,56(sp)
    80004a72:	f852                	sd	s4,48(sp)
    80004a74:	f456                	sd	s5,40(sp)
    80004a76:	f05a                	sd	s6,32(sp)
    80004a78:	ec5e                	sd	s7,24(sp)
    80004a7a:	1080                	add	s0,sp,96
    80004a7c:	84aa                	mv	s1,a0
    80004a7e:	8b2e                	mv	s6,a1
    80004a80:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004a82:	ffffd097          	auipc	ra,0xffffd
    80004a86:	fa8080e7          	jalr	-88(ra) # 80001a2a <myproc>
    80004a8a:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004a8c:	8526                	mv	a0,s1
    80004a8e:	ffffc097          	auipc	ra,0xffffc
    80004a92:	1d2080e7          	jalr	466(ra) # 80000c60 <acquire>
  for(i = 0; i < n; i++){
    80004a96:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004a98:	21848a13          	add	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a9c:	21c48993          	add	s3,s1,540
  for(i = 0; i < n; i++){
    80004aa0:	09505263          	blez	s5,80004b24 <pipewrite+0xbe>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004aa4:	2184a783          	lw	a5,536(s1)
    80004aa8:	21c4a703          	lw	a4,540(s1)
    80004aac:	2007879b          	addw	a5,a5,512
    80004ab0:	02f71b63          	bne	a4,a5,80004ae6 <pipewrite+0x80>
      if(pi->readopen == 0 || pr->killed){
    80004ab4:	2204a783          	lw	a5,544(s1)
    80004ab8:	c3d1                	beqz	a5,80004b3c <pipewrite+0xd6>
    80004aba:	03092783          	lw	a5,48(s2)
    80004abe:	efbd                	bnez	a5,80004b3c <pipewrite+0xd6>
      wakeup(&pi->nread);
    80004ac0:	8552                	mv	a0,s4
    80004ac2:	ffffe097          	auipc	ra,0xffffe
    80004ac6:	918080e7          	jalr	-1768(ra) # 800023da <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004aca:	85a6                	mv	a1,s1
    80004acc:	854e                	mv	a0,s3
    80004ace:	ffffd097          	auipc	ra,0xffffd
    80004ad2:	78c080e7          	jalr	1932(ra) # 8000225a <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ad6:	2184a783          	lw	a5,536(s1)
    80004ada:	21c4a703          	lw	a4,540(s1)
    80004ade:	2007879b          	addw	a5,a5,512
    80004ae2:	fcf709e3          	beq	a4,a5,80004ab4 <pipewrite+0x4e>
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ae6:	4685                	li	a3,1
    80004ae8:	865a                	mv	a2,s6
    80004aea:	faf40593          	add	a1,s0,-81
    80004aee:	05093503          	ld	a0,80(s2)
    80004af2:	ffffd097          	auipc	ra,0xffffd
    80004af6:	cba080e7          	jalr	-838(ra) # 800017ac <copyin>
    80004afa:	57fd                	li	a5,-1
    80004afc:	02f50463          	beq	a0,a5,80004b24 <pipewrite+0xbe>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b00:	21c4a783          	lw	a5,540(s1)
    80004b04:	0017871b          	addw	a4,a5,1
    80004b08:	20e4ae23          	sw	a4,540(s1)
    80004b0c:	1ff7f793          	and	a5,a5,511
    80004b10:	97a6                	add	a5,a5,s1
    80004b12:	faf44703          	lbu	a4,-81(s0)
    80004b16:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004b1a:	2b85                	addw	s7,s7,1
    80004b1c:	0b05                	add	s6,s6,1
    80004b1e:	f97a93e3          	bne	s5,s7,80004aa4 <pipewrite+0x3e>
    80004b22:	8bd6                	mv	s7,s5
  }
  wakeup(&pi->nread);
    80004b24:	21848513          	add	a0,s1,536
    80004b28:	ffffe097          	auipc	ra,0xffffe
    80004b2c:	8b2080e7          	jalr	-1870(ra) # 800023da <wakeup>
  release(&pi->lock);
    80004b30:	8526                	mv	a0,s1
    80004b32:	ffffc097          	auipc	ra,0xffffc
    80004b36:	1e2080e7          	jalr	482(ra) # 80000d14 <release>
  return i;
    80004b3a:	a039                	j	80004b48 <pipewrite+0xe2>
        release(&pi->lock);
    80004b3c:	8526                	mv	a0,s1
    80004b3e:	ffffc097          	auipc	ra,0xffffc
    80004b42:	1d6080e7          	jalr	470(ra) # 80000d14 <release>
        return -1;
    80004b46:	5bfd                	li	s7,-1
}
    80004b48:	855e                	mv	a0,s7
    80004b4a:	60e6                	ld	ra,88(sp)
    80004b4c:	6446                	ld	s0,80(sp)
    80004b4e:	64a6                	ld	s1,72(sp)
    80004b50:	6906                	ld	s2,64(sp)
    80004b52:	79e2                	ld	s3,56(sp)
    80004b54:	7a42                	ld	s4,48(sp)
    80004b56:	7aa2                	ld	s5,40(sp)
    80004b58:	7b02                	ld	s6,32(sp)
    80004b5a:	6be2                	ld	s7,24(sp)
    80004b5c:	6125                	add	sp,sp,96
    80004b5e:	8082                	ret

0000000080004b60 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b60:	715d                	add	sp,sp,-80
    80004b62:	e486                	sd	ra,72(sp)
    80004b64:	e0a2                	sd	s0,64(sp)
    80004b66:	fc26                	sd	s1,56(sp)
    80004b68:	f84a                	sd	s2,48(sp)
    80004b6a:	f44e                	sd	s3,40(sp)
    80004b6c:	f052                	sd	s4,32(sp)
    80004b6e:	ec56                	sd	s5,24(sp)
    80004b70:	e85a                	sd	s6,16(sp)
    80004b72:	0880                	add	s0,sp,80
    80004b74:	84aa                	mv	s1,a0
    80004b76:	892e                	mv	s2,a1
    80004b78:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b7a:	ffffd097          	auipc	ra,0xffffd
    80004b7e:	eb0080e7          	jalr	-336(ra) # 80001a2a <myproc>
    80004b82:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b84:	8526                	mv	a0,s1
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	0da080e7          	jalr	218(ra) # 80000c60 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b8e:	2184a703          	lw	a4,536(s1)
    80004b92:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b96:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b9a:	02f71463          	bne	a4,a5,80004bc2 <piperead+0x62>
    80004b9e:	2244a783          	lw	a5,548(s1)
    80004ba2:	c385                	beqz	a5,80004bc2 <piperead+0x62>
    if(pr->killed){
    80004ba4:	030a2783          	lw	a5,48(s4)
    80004ba8:	ebc9                	bnez	a5,80004c3a <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004baa:	85a6                	mv	a1,s1
    80004bac:	854e                	mv	a0,s3
    80004bae:	ffffd097          	auipc	ra,0xffffd
    80004bb2:	6ac080e7          	jalr	1708(ra) # 8000225a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bb6:	2184a703          	lw	a4,536(s1)
    80004bba:	21c4a783          	lw	a5,540(s1)
    80004bbe:	fef700e3          	beq	a4,a5,80004b9e <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bc2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bc4:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bc6:	05505463          	blez	s5,80004c0e <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004bca:	2184a783          	lw	a5,536(s1)
    80004bce:	21c4a703          	lw	a4,540(s1)
    80004bd2:	02f70e63          	beq	a4,a5,80004c0e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bd6:	0017871b          	addw	a4,a5,1
    80004bda:	20e4ac23          	sw	a4,536(s1)
    80004bde:	1ff7f793          	and	a5,a5,511
    80004be2:	97a6                	add	a5,a5,s1
    80004be4:	0187c783          	lbu	a5,24(a5)
    80004be8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bec:	4685                	li	a3,1
    80004bee:	fbf40613          	add	a2,s0,-65
    80004bf2:	85ca                	mv	a1,s2
    80004bf4:	050a3503          	ld	a0,80(s4)
    80004bf8:	ffffd097          	auipc	ra,0xffffd
    80004bfc:	b28080e7          	jalr	-1240(ra) # 80001720 <copyout>
    80004c00:	01650763          	beq	a0,s6,80004c0e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c04:	2985                	addw	s3,s3,1
    80004c06:	0905                	add	s2,s2,1
    80004c08:	fd3a91e3          	bne	s5,s3,80004bca <piperead+0x6a>
    80004c0c:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c0e:	21c48513          	add	a0,s1,540
    80004c12:	ffffd097          	auipc	ra,0xffffd
    80004c16:	7c8080e7          	jalr	1992(ra) # 800023da <wakeup>
  release(&pi->lock);
    80004c1a:	8526                	mv	a0,s1
    80004c1c:	ffffc097          	auipc	ra,0xffffc
    80004c20:	0f8080e7          	jalr	248(ra) # 80000d14 <release>
  return i;
}
    80004c24:	854e                	mv	a0,s3
    80004c26:	60a6                	ld	ra,72(sp)
    80004c28:	6406                	ld	s0,64(sp)
    80004c2a:	74e2                	ld	s1,56(sp)
    80004c2c:	7942                	ld	s2,48(sp)
    80004c2e:	79a2                	ld	s3,40(sp)
    80004c30:	7a02                	ld	s4,32(sp)
    80004c32:	6ae2                	ld	s5,24(sp)
    80004c34:	6b42                	ld	s6,16(sp)
    80004c36:	6161                	add	sp,sp,80
    80004c38:	8082                	ret
      release(&pi->lock);
    80004c3a:	8526                	mv	a0,s1
    80004c3c:	ffffc097          	auipc	ra,0xffffc
    80004c40:	0d8080e7          	jalr	216(ra) # 80000d14 <release>
      return -1;
    80004c44:	59fd                	li	s3,-1
    80004c46:	bff9                	j	80004c24 <piperead+0xc4>

0000000080004c48 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c48:	df010113          	add	sp,sp,-528
    80004c4c:	20113423          	sd	ra,520(sp)
    80004c50:	20813023          	sd	s0,512(sp)
    80004c54:	ffa6                	sd	s1,504(sp)
    80004c56:	fbca                	sd	s2,496(sp)
    80004c58:	f7ce                	sd	s3,488(sp)
    80004c5a:	f3d2                	sd	s4,480(sp)
    80004c5c:	efd6                	sd	s5,472(sp)
    80004c5e:	ebda                	sd	s6,464(sp)
    80004c60:	e7de                	sd	s7,456(sp)
    80004c62:	e3e2                	sd	s8,448(sp)
    80004c64:	ff66                	sd	s9,440(sp)
    80004c66:	fb6a                	sd	s10,432(sp)
    80004c68:	f76e                	sd	s11,424(sp)
    80004c6a:	0c00                	add	s0,sp,528
    80004c6c:	892a                	mv	s2,a0
    80004c6e:	dea43c23          	sd	a0,-520(s0)
    80004c72:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c76:	ffffd097          	auipc	ra,0xffffd
    80004c7a:	db4080e7          	jalr	-588(ra) # 80001a2a <myproc>
    80004c7e:	84aa                	mv	s1,a0

  begin_op();
    80004c80:	fffff097          	auipc	ra,0xfffff
    80004c84:	47c080e7          	jalr	1148(ra) # 800040fc <begin_op>

  if((ip = namei(path)) == 0){
    80004c88:	854a                	mv	a0,s2
    80004c8a:	fffff097          	auipc	ra,0xfffff
    80004c8e:	282080e7          	jalr	642(ra) # 80003f0c <namei>
    80004c92:	c92d                	beqz	a0,80004d04 <exec+0xbc>
    80004c94:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c96:	fffff097          	auipc	ra,0xfffff
    80004c9a:	ac6080e7          	jalr	-1338(ra) # 8000375c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c9e:	04000713          	li	a4,64
    80004ca2:	4681                	li	a3,0
    80004ca4:	e4840613          	add	a2,s0,-440
    80004ca8:	4581                	li	a1,0
    80004caa:	8552                	mv	a0,s4
    80004cac:	fffff097          	auipc	ra,0xfffff
    80004cb0:	d64080e7          	jalr	-668(ra) # 80003a10 <readi>
    80004cb4:	04000793          	li	a5,64
    80004cb8:	00f51a63          	bne	a0,a5,80004ccc <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004cbc:	e4842703          	lw	a4,-440(s0)
    80004cc0:	464c47b7          	lui	a5,0x464c4
    80004cc4:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004cc8:	04f70463          	beq	a4,a5,80004d10 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ccc:	8552                	mv	a0,s4
    80004cce:	fffff097          	auipc	ra,0xfffff
    80004cd2:	cf0080e7          	jalr	-784(ra) # 800039be <iunlockput>
    end_op();
    80004cd6:	fffff097          	auipc	ra,0xfffff
    80004cda:	4a0080e7          	jalr	1184(ra) # 80004176 <end_op>
  }
  return -1;
    80004cde:	557d                	li	a0,-1
}
    80004ce0:	20813083          	ld	ra,520(sp)
    80004ce4:	20013403          	ld	s0,512(sp)
    80004ce8:	74fe                	ld	s1,504(sp)
    80004cea:	795e                	ld	s2,496(sp)
    80004cec:	79be                	ld	s3,488(sp)
    80004cee:	7a1e                	ld	s4,480(sp)
    80004cf0:	6afe                	ld	s5,472(sp)
    80004cf2:	6b5e                	ld	s6,464(sp)
    80004cf4:	6bbe                	ld	s7,456(sp)
    80004cf6:	6c1e                	ld	s8,448(sp)
    80004cf8:	7cfa                	ld	s9,440(sp)
    80004cfa:	7d5a                	ld	s10,432(sp)
    80004cfc:	7dba                	ld	s11,424(sp)
    80004cfe:	21010113          	add	sp,sp,528
    80004d02:	8082                	ret
    end_op();
    80004d04:	fffff097          	auipc	ra,0xfffff
    80004d08:	472080e7          	jalr	1138(ra) # 80004176 <end_op>
    return -1;
    80004d0c:	557d                	li	a0,-1
    80004d0e:	bfc9                	j	80004ce0 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d10:	8526                	mv	a0,s1
    80004d12:	ffffd097          	auipc	ra,0xffffd
    80004d16:	ddc080e7          	jalr	-548(ra) # 80001aee <proc_pagetable>
    80004d1a:	8b2a                	mv	s6,a0
    80004d1c:	d945                	beqz	a0,80004ccc <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d1e:	e6842d03          	lw	s10,-408(s0)
    80004d22:	e8045783          	lhu	a5,-384(s0)
    80004d26:	cfe5                	beqz	a5,80004e1e <exec+0x1d6>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d28:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d2a:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004d2c:	6c85                	lui	s9,0x1
    80004d2e:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d32:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004d36:	6a85                	lui	s5,0x1
    80004d38:	a0b5                	j	80004da4 <exec+0x15c>
      panic("loadseg: address should exist");
    80004d3a:	00004517          	auipc	a0,0x4
    80004d3e:	9a650513          	add	a0,a0,-1626 # 800086e0 <syscalls+0x2a0>
    80004d42:	ffffc097          	auipc	ra,0xffffc
    80004d46:	800080e7          	jalr	-2048(ra) # 80000542 <panic>
    if(sz - i < PGSIZE)
    80004d4a:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d4c:	8726                	mv	a4,s1
    80004d4e:	012c06bb          	addw	a3,s8,s2
    80004d52:	4581                	li	a1,0
    80004d54:	8552                	mv	a0,s4
    80004d56:	fffff097          	auipc	ra,0xfffff
    80004d5a:	cba080e7          	jalr	-838(ra) # 80003a10 <readi>
    80004d5e:	2501                	sext.w	a0,a0
    80004d60:	24a49063          	bne	s1,a0,80004fa0 <exec+0x358>
  for(i = 0; i < sz; i += PGSIZE){
    80004d64:	012a893b          	addw	s2,s5,s2
    80004d68:	03397563          	bgeu	s2,s3,80004d92 <exec+0x14a>
    pa = walkaddr(pagetable, va + i);
    80004d6c:	02091593          	sll	a1,s2,0x20
    80004d70:	9181                	srl	a1,a1,0x20
    80004d72:	95de                	add	a1,a1,s7
    80004d74:	855a                	mv	a0,s6
    80004d76:	ffffc097          	auipc	ra,0xffffc
    80004d7a:	372080e7          	jalr	882(ra) # 800010e8 <walkaddr>
    80004d7e:	862a                	mv	a2,a0
    if(pa == 0)
    80004d80:	dd4d                	beqz	a0,80004d3a <exec+0xf2>
    if(sz - i < PGSIZE)
    80004d82:	412984bb          	subw	s1,s3,s2
    80004d86:	0004879b          	sext.w	a5,s1
    80004d8a:	fcfcf0e3          	bgeu	s9,a5,80004d4a <exec+0x102>
    80004d8e:	84d6                	mv	s1,s5
    80004d90:	bf6d                	j	80004d4a <exec+0x102>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004d92:	e0843483          	ld	s1,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d96:	2d85                	addw	s11,s11,1
    80004d98:	038d0d1b          	addw	s10,s10,56
    80004d9c:	e8045783          	lhu	a5,-384(s0)
    80004da0:	08fdd063          	bge	s11,a5,80004e20 <exec+0x1d8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004da4:	2d01                	sext.w	s10,s10
    80004da6:	03800713          	li	a4,56
    80004daa:	86ea                	mv	a3,s10
    80004dac:	e1040613          	add	a2,s0,-496
    80004db0:	4581                	li	a1,0
    80004db2:	8552                	mv	a0,s4
    80004db4:	fffff097          	auipc	ra,0xfffff
    80004db8:	c5c080e7          	jalr	-932(ra) # 80003a10 <readi>
    80004dbc:	03800793          	li	a5,56
    80004dc0:	1cf51e63          	bne	a0,a5,80004f9c <exec+0x354>
    if(ph.type != ELF_PROG_LOAD)
    80004dc4:	e1042783          	lw	a5,-496(s0)
    80004dc8:	4705                	li	a4,1
    80004dca:	fce796e3          	bne	a5,a4,80004d96 <exec+0x14e>
    if(ph.memsz < ph.filesz)
    80004dce:	e3843603          	ld	a2,-456(s0)
    80004dd2:	e3043783          	ld	a5,-464(s0)
    80004dd6:	1ef66063          	bltu	a2,a5,80004fb6 <exec+0x36e>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004dda:	e2043783          	ld	a5,-480(s0)
    80004dde:	963e                	add	a2,a2,a5
    80004de0:	1cf66e63          	bltu	a2,a5,80004fbc <exec+0x374>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004de4:	85a6                	mv	a1,s1
    80004de6:	855a                	mv	a0,s6
    80004de8:	ffffc097          	auipc	ra,0xffffc
    80004dec:	6e4080e7          	jalr	1764(ra) # 800014cc <uvmalloc>
    80004df0:	e0a43423          	sd	a0,-504(s0)
    80004df4:	1c050763          	beqz	a0,80004fc2 <exec+0x37a>
    if(ph.vaddr % PGSIZE != 0)
    80004df8:	e2043b83          	ld	s7,-480(s0)
    80004dfc:	df043783          	ld	a5,-528(s0)
    80004e00:	00fbf7b3          	and	a5,s7,a5
    80004e04:	18079e63          	bnez	a5,80004fa0 <exec+0x358>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004e08:	e1842c03          	lw	s8,-488(s0)
    80004e0c:	e3042983          	lw	s3,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004e10:	00098463          	beqz	s3,80004e18 <exec+0x1d0>
    80004e14:	4901                	li	s2,0
    80004e16:	bf99                	j	80004d6c <exec+0x124>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e18:	e0843483          	ld	s1,-504(s0)
    80004e1c:	bfad                	j	80004d96 <exec+0x14e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e1e:	4481                	li	s1,0
  iunlockput(ip);
    80004e20:	8552                	mv	a0,s4
    80004e22:	fffff097          	auipc	ra,0xfffff
    80004e26:	b9c080e7          	jalr	-1124(ra) # 800039be <iunlockput>
  end_op();
    80004e2a:	fffff097          	auipc	ra,0xfffff
    80004e2e:	34c080e7          	jalr	844(ra) # 80004176 <end_op>
  p = myproc();
    80004e32:	ffffd097          	auipc	ra,0xffffd
    80004e36:	bf8080e7          	jalr	-1032(ra) # 80001a2a <myproc>
    80004e3a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e3c:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004e40:	6985                	lui	s3,0x1
    80004e42:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004e44:	99a6                	add	s3,s3,s1
    80004e46:	77fd                	lui	a5,0xfffff
    80004e48:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e4c:	6609                	lui	a2,0x2
    80004e4e:	964e                	add	a2,a2,s3
    80004e50:	85ce                	mv	a1,s3
    80004e52:	855a                	mv	a0,s6
    80004e54:	ffffc097          	auipc	ra,0xffffc
    80004e58:	678080e7          	jalr	1656(ra) # 800014cc <uvmalloc>
    80004e5c:	892a                	mv	s2,a0
    80004e5e:	e0a43423          	sd	a0,-504(s0)
    80004e62:	e509                	bnez	a0,80004e6c <exec+0x224>
  if(pagetable)
    80004e64:	e1343423          	sd	s3,-504(s0)
    80004e68:	4a01                	li	s4,0
    80004e6a:	aa1d                	j	80004fa0 <exec+0x358>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e6c:	75f9                	lui	a1,0xffffe
    80004e6e:	95aa                	add	a1,a1,a0
    80004e70:	855a                	mv	a0,s6
    80004e72:	ffffd097          	auipc	ra,0xffffd
    80004e76:	87c080e7          	jalr	-1924(ra) # 800016ee <uvmclear>
  stackbase = sp - PGSIZE;
    80004e7a:	7bfd                	lui	s7,0xfffff
    80004e7c:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004e7e:	e0043783          	ld	a5,-512(s0)
    80004e82:	6388                	ld	a0,0(a5)
    80004e84:	c52d                	beqz	a0,80004eee <exec+0x2a6>
    80004e86:	e8840993          	add	s3,s0,-376
    80004e8a:	f8840c13          	add	s8,s0,-120
    80004e8e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e90:	ffffc097          	auipc	ra,0xffffc
    80004e94:	04e080e7          	jalr	78(ra) # 80000ede <strlen>
    80004e98:	0015079b          	addw	a5,a0,1
    80004e9c:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ea0:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    80004ea4:	13796263          	bltu	s2,s7,80004fc8 <exec+0x380>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ea8:	e0043d03          	ld	s10,-512(s0)
    80004eac:	000d3a03          	ld	s4,0(s10)
    80004eb0:	8552                	mv	a0,s4
    80004eb2:	ffffc097          	auipc	ra,0xffffc
    80004eb6:	02c080e7          	jalr	44(ra) # 80000ede <strlen>
    80004eba:	0015069b          	addw	a3,a0,1
    80004ebe:	8652                	mv	a2,s4
    80004ec0:	85ca                	mv	a1,s2
    80004ec2:	855a                	mv	a0,s6
    80004ec4:	ffffd097          	auipc	ra,0xffffd
    80004ec8:	85c080e7          	jalr	-1956(ra) # 80001720 <copyout>
    80004ecc:	10054063          	bltz	a0,80004fcc <exec+0x384>
    ustack[argc] = sp;
    80004ed0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ed4:	0485                	add	s1,s1,1
    80004ed6:	008d0793          	add	a5,s10,8
    80004eda:	e0f43023          	sd	a5,-512(s0)
    80004ede:	008d3503          	ld	a0,8(s10)
    80004ee2:	c909                	beqz	a0,80004ef4 <exec+0x2ac>
    if(argc >= MAXARG)
    80004ee4:	09a1                	add	s3,s3,8
    80004ee6:	fb8995e3          	bne	s3,s8,80004e90 <exec+0x248>
  ip = 0;
    80004eea:	4a01                	li	s4,0
    80004eec:	a855                	j	80004fa0 <exec+0x358>
  sp = sz;
    80004eee:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004ef2:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ef4:	00349793          	sll	a5,s1,0x3
    80004ef8:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffd7f90>
    80004efc:	97a2                	add	a5,a5,s0
    80004efe:	ee07bc23          	sd	zero,-264(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004f02:	00148693          	add	a3,s1,1
    80004f06:	068e                	sll	a3,a3,0x3
    80004f08:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f0c:	ff097913          	and	s2,s2,-16
  sz = sz1;
    80004f10:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004f14:	f57968e3          	bltu	s2,s7,80004e64 <exec+0x21c>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f18:	e8840613          	add	a2,s0,-376
    80004f1c:	85ca                	mv	a1,s2
    80004f1e:	855a                	mv	a0,s6
    80004f20:	ffffd097          	auipc	ra,0xffffd
    80004f24:	800080e7          	jalr	-2048(ra) # 80001720 <copyout>
    80004f28:	0a054463          	bltz	a0,80004fd0 <exec+0x388>
  p->trapframe->a1 = sp;
    80004f2c:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004f30:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f34:	df843783          	ld	a5,-520(s0)
    80004f38:	0007c703          	lbu	a4,0(a5)
    80004f3c:	cf11                	beqz	a4,80004f58 <exec+0x310>
    80004f3e:	0785                	add	a5,a5,1
    if(*s == '/')
    80004f40:	02f00693          	li	a3,47
    80004f44:	a039                	j	80004f52 <exec+0x30a>
      last = s+1;
    80004f46:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f4a:	0785                	add	a5,a5,1
    80004f4c:	fff7c703          	lbu	a4,-1(a5)
    80004f50:	c701                	beqz	a4,80004f58 <exec+0x310>
    if(*s == '/')
    80004f52:	fed71ce3          	bne	a4,a3,80004f4a <exec+0x302>
    80004f56:	bfc5                	j	80004f46 <exec+0x2fe>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f58:	4641                	li	a2,16
    80004f5a:	df843583          	ld	a1,-520(s0)
    80004f5e:	158a8513          	add	a0,s5,344
    80004f62:	ffffc097          	auipc	ra,0xffffc
    80004f66:	f4a080e7          	jalr	-182(ra) # 80000eac <safestrcpy>
  oldpagetable = p->pagetable;
    80004f6a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f6e:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80004f72:	e0843783          	ld	a5,-504(s0)
    80004f76:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f7a:	058ab783          	ld	a5,88(s5)
    80004f7e:	e6043703          	ld	a4,-416(s0)
    80004f82:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f84:	058ab783          	ld	a5,88(s5)
    80004f88:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f8c:	85e6                	mv	a1,s9
    80004f8e:	ffffd097          	auipc	ra,0xffffd
    80004f92:	bfc080e7          	jalr	-1028(ra) # 80001b8a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f96:	0004851b          	sext.w	a0,s1
    80004f9a:	b399                	j	80004ce0 <exec+0x98>
    80004f9c:	e0943423          	sd	s1,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004fa0:	e0843583          	ld	a1,-504(s0)
    80004fa4:	855a                	mv	a0,s6
    80004fa6:	ffffd097          	auipc	ra,0xffffd
    80004faa:	be4080e7          	jalr	-1052(ra) # 80001b8a <proc_freepagetable>
  return -1;
    80004fae:	557d                	li	a0,-1
  if(ip){
    80004fb0:	d20a08e3          	beqz	s4,80004ce0 <exec+0x98>
    80004fb4:	bb21                	j	80004ccc <exec+0x84>
    80004fb6:	e0943423          	sd	s1,-504(s0)
    80004fba:	b7dd                	j	80004fa0 <exec+0x358>
    80004fbc:	e0943423          	sd	s1,-504(s0)
    80004fc0:	b7c5                	j	80004fa0 <exec+0x358>
    80004fc2:	e0943423          	sd	s1,-504(s0)
    80004fc6:	bfe9                	j	80004fa0 <exec+0x358>
  ip = 0;
    80004fc8:	4a01                	li	s4,0
    80004fca:	bfd9                	j	80004fa0 <exec+0x358>
    80004fcc:	4a01                	li	s4,0
  if(pagetable)
    80004fce:	bfc9                	j	80004fa0 <exec+0x358>
  sz = sz1;
    80004fd0:	e0843983          	ld	s3,-504(s0)
    80004fd4:	bd41                	j	80004e64 <exec+0x21c>

0000000080004fd6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004fd6:	7179                	add	sp,sp,-48
    80004fd8:	f406                	sd	ra,40(sp)
    80004fda:	f022                	sd	s0,32(sp)
    80004fdc:	ec26                	sd	s1,24(sp)
    80004fde:	e84a                	sd	s2,16(sp)
    80004fe0:	1800                	add	s0,sp,48
    80004fe2:	892e                	mv	s2,a1
    80004fe4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004fe6:	fdc40593          	add	a1,s0,-36
    80004fea:	ffffe097          	auipc	ra,0xffffe
    80004fee:	b56080e7          	jalr	-1194(ra) # 80002b40 <argint>
    80004ff2:	04054063          	bltz	a0,80005032 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004ff6:	fdc42703          	lw	a4,-36(s0)
    80004ffa:	47bd                	li	a5,15
    80004ffc:	02e7ed63          	bltu	a5,a4,80005036 <argfd+0x60>
    80005000:	ffffd097          	auipc	ra,0xffffd
    80005004:	a2a080e7          	jalr	-1494(ra) # 80001a2a <myproc>
    80005008:	fdc42703          	lw	a4,-36(s0)
    8000500c:	01a70793          	add	a5,a4,26
    80005010:	078e                	sll	a5,a5,0x3
    80005012:	953e                	add	a0,a0,a5
    80005014:	611c                	ld	a5,0(a0)
    80005016:	c395                	beqz	a5,8000503a <argfd+0x64>
    return -1;
  if(pfd)
    80005018:	00090463          	beqz	s2,80005020 <argfd+0x4a>
    *pfd = fd;
    8000501c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005020:	4501                	li	a0,0
  if(pf)
    80005022:	c091                	beqz	s1,80005026 <argfd+0x50>
    *pf = f;
    80005024:	e09c                	sd	a5,0(s1)
}
    80005026:	70a2                	ld	ra,40(sp)
    80005028:	7402                	ld	s0,32(sp)
    8000502a:	64e2                	ld	s1,24(sp)
    8000502c:	6942                	ld	s2,16(sp)
    8000502e:	6145                	add	sp,sp,48
    80005030:	8082                	ret
    return -1;
    80005032:	557d                	li	a0,-1
    80005034:	bfcd                	j	80005026 <argfd+0x50>
    return -1;
    80005036:	557d                	li	a0,-1
    80005038:	b7fd                	j	80005026 <argfd+0x50>
    8000503a:	557d                	li	a0,-1
    8000503c:	b7ed                	j	80005026 <argfd+0x50>

000000008000503e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000503e:	1101                	add	sp,sp,-32
    80005040:	ec06                	sd	ra,24(sp)
    80005042:	e822                	sd	s0,16(sp)
    80005044:	e426                	sd	s1,8(sp)
    80005046:	1000                	add	s0,sp,32
    80005048:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000504a:	ffffd097          	auipc	ra,0xffffd
    8000504e:	9e0080e7          	jalr	-1568(ra) # 80001a2a <myproc>
    80005052:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005054:	0d050793          	add	a5,a0,208
    80005058:	4501                	li	a0,0
    8000505a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000505c:	6398                	ld	a4,0(a5)
    8000505e:	cb19                	beqz	a4,80005074 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005060:	2505                	addw	a0,a0,1
    80005062:	07a1                	add	a5,a5,8
    80005064:	fed51ce3          	bne	a0,a3,8000505c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005068:	557d                	li	a0,-1
}
    8000506a:	60e2                	ld	ra,24(sp)
    8000506c:	6442                	ld	s0,16(sp)
    8000506e:	64a2                	ld	s1,8(sp)
    80005070:	6105                	add	sp,sp,32
    80005072:	8082                	ret
      p->ofile[fd] = f;
    80005074:	01a50793          	add	a5,a0,26
    80005078:	078e                	sll	a5,a5,0x3
    8000507a:	963e                	add	a2,a2,a5
    8000507c:	e204                	sd	s1,0(a2)
      return fd;
    8000507e:	b7f5                	j	8000506a <fdalloc+0x2c>

0000000080005080 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005080:	715d                	add	sp,sp,-80
    80005082:	e486                	sd	ra,72(sp)
    80005084:	e0a2                	sd	s0,64(sp)
    80005086:	fc26                	sd	s1,56(sp)
    80005088:	f84a                	sd	s2,48(sp)
    8000508a:	f44e                	sd	s3,40(sp)
    8000508c:	f052                	sd	s4,32(sp)
    8000508e:	ec56                	sd	s5,24(sp)
    80005090:	0880                	add	s0,sp,80
    80005092:	8aae                	mv	s5,a1
    80005094:	8a32                	mv	s4,a2
    80005096:	89b6                	mv	s3,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005098:	fb040593          	add	a1,s0,-80
    8000509c:	fffff097          	auipc	ra,0xfffff
    800050a0:	e8e080e7          	jalr	-370(ra) # 80003f2a <nameiparent>
    800050a4:	892a                	mv	s2,a0
    800050a6:	12050c63          	beqz	a0,800051de <create+0x15e>
    return 0;

  ilock(dp);
    800050aa:	ffffe097          	auipc	ra,0xffffe
    800050ae:	6b2080e7          	jalr	1714(ra) # 8000375c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050b2:	4601                	li	a2,0
    800050b4:	fb040593          	add	a1,s0,-80
    800050b8:	854a                	mv	a0,s2
    800050ba:	fffff097          	auipc	ra,0xfffff
    800050be:	b80080e7          	jalr	-1152(ra) # 80003c3a <dirlookup>
    800050c2:	84aa                	mv	s1,a0
    800050c4:	c539                	beqz	a0,80005112 <create+0x92>
    iunlockput(dp);
    800050c6:	854a                	mv	a0,s2
    800050c8:	fffff097          	auipc	ra,0xfffff
    800050cc:	8f6080e7          	jalr	-1802(ra) # 800039be <iunlockput>
    ilock(ip);
    800050d0:	8526                	mv	a0,s1
    800050d2:	ffffe097          	auipc	ra,0xffffe
    800050d6:	68a080e7          	jalr	1674(ra) # 8000375c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050da:	4789                	li	a5,2
    800050dc:	02fa9463          	bne	s5,a5,80005104 <create+0x84>
    800050e0:	0444d783          	lhu	a5,68(s1)
    800050e4:	37f9                	addw	a5,a5,-2
    800050e6:	17c2                	sll	a5,a5,0x30
    800050e8:	93c1                	srl	a5,a5,0x30
    800050ea:	4705                	li	a4,1
    800050ec:	00f76c63          	bltu	a4,a5,80005104 <create+0x84>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050f0:	8526                	mv	a0,s1
    800050f2:	60a6                	ld	ra,72(sp)
    800050f4:	6406                	ld	s0,64(sp)
    800050f6:	74e2                	ld	s1,56(sp)
    800050f8:	7942                	ld	s2,48(sp)
    800050fa:	79a2                	ld	s3,40(sp)
    800050fc:	7a02                	ld	s4,32(sp)
    800050fe:	6ae2                	ld	s5,24(sp)
    80005100:	6161                	add	sp,sp,80
    80005102:	8082                	ret
    iunlockput(ip);
    80005104:	8526                	mv	a0,s1
    80005106:	fffff097          	auipc	ra,0xfffff
    8000510a:	8b8080e7          	jalr	-1864(ra) # 800039be <iunlockput>
    return 0;
    8000510e:	4481                	li	s1,0
    80005110:	b7c5                	j	800050f0 <create+0x70>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005112:	85d6                	mv	a1,s5
    80005114:	00092503          	lw	a0,0(s2)
    80005118:	ffffe097          	auipc	ra,0xffffe
    8000511c:	4b0080e7          	jalr	1200(ra) # 800035c8 <ialloc>
    80005120:	84aa                	mv	s1,a0
    80005122:	c139                	beqz	a0,80005168 <create+0xe8>
  ilock(ip);
    80005124:	ffffe097          	auipc	ra,0xffffe
    80005128:	638080e7          	jalr	1592(ra) # 8000375c <ilock>
  ip->major = major;
    8000512c:	05449323          	sh	s4,70(s1)
  ip->minor = minor;
    80005130:	05349423          	sh	s3,72(s1)
  ip->nlink = 1;
    80005134:	4985                	li	s3,1
    80005136:	05349523          	sh	s3,74(s1)
  iupdate(ip);
    8000513a:	8526                	mv	a0,s1
    8000513c:	ffffe097          	auipc	ra,0xffffe
    80005140:	554080e7          	jalr	1364(ra) # 80003690 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005144:	033a8a63          	beq	s5,s3,80005178 <create+0xf8>
  if(dirlink(dp, name, ip->inum) < 0)
    80005148:	40d0                	lw	a2,4(s1)
    8000514a:	fb040593          	add	a1,s0,-80
    8000514e:	854a                	mv	a0,s2
    80005150:	fffff097          	auipc	ra,0xfffff
    80005154:	cfa080e7          	jalr	-774(ra) # 80003e4a <dirlink>
    80005158:	06054b63          	bltz	a0,800051ce <create+0x14e>
  iunlockput(dp);
    8000515c:	854a                	mv	a0,s2
    8000515e:	fffff097          	auipc	ra,0xfffff
    80005162:	860080e7          	jalr	-1952(ra) # 800039be <iunlockput>
  return ip;
    80005166:	b769                	j	800050f0 <create+0x70>
    panic("create: ialloc");
    80005168:	00003517          	auipc	a0,0x3
    8000516c:	59850513          	add	a0,a0,1432 # 80008700 <syscalls+0x2c0>
    80005170:	ffffb097          	auipc	ra,0xffffb
    80005174:	3d2080e7          	jalr	978(ra) # 80000542 <panic>
    dp->nlink++;  // for ".."
    80005178:	04a95783          	lhu	a5,74(s2)
    8000517c:	2785                	addw	a5,a5,1
    8000517e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005182:	854a                	mv	a0,s2
    80005184:	ffffe097          	auipc	ra,0xffffe
    80005188:	50c080e7          	jalr	1292(ra) # 80003690 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000518c:	40d0                	lw	a2,4(s1)
    8000518e:	00003597          	auipc	a1,0x3
    80005192:	58258593          	add	a1,a1,1410 # 80008710 <syscalls+0x2d0>
    80005196:	8526                	mv	a0,s1
    80005198:	fffff097          	auipc	ra,0xfffff
    8000519c:	cb2080e7          	jalr	-846(ra) # 80003e4a <dirlink>
    800051a0:	00054f63          	bltz	a0,800051be <create+0x13e>
    800051a4:	00492603          	lw	a2,4(s2)
    800051a8:	00003597          	auipc	a1,0x3
    800051ac:	57058593          	add	a1,a1,1392 # 80008718 <syscalls+0x2d8>
    800051b0:	8526                	mv	a0,s1
    800051b2:	fffff097          	auipc	ra,0xfffff
    800051b6:	c98080e7          	jalr	-872(ra) # 80003e4a <dirlink>
    800051ba:	f80557e3          	bgez	a0,80005148 <create+0xc8>
      panic("create dots");
    800051be:	00003517          	auipc	a0,0x3
    800051c2:	56250513          	add	a0,a0,1378 # 80008720 <syscalls+0x2e0>
    800051c6:	ffffb097          	auipc	ra,0xffffb
    800051ca:	37c080e7          	jalr	892(ra) # 80000542 <panic>
    panic("create: dirlink");
    800051ce:	00003517          	auipc	a0,0x3
    800051d2:	56250513          	add	a0,a0,1378 # 80008730 <syscalls+0x2f0>
    800051d6:	ffffb097          	auipc	ra,0xffffb
    800051da:	36c080e7          	jalr	876(ra) # 80000542 <panic>
    return 0;
    800051de:	84aa                	mv	s1,a0
    800051e0:	bf01                	j	800050f0 <create+0x70>

00000000800051e2 <sys_dup>:
{
    800051e2:	7179                	add	sp,sp,-48
    800051e4:	f406                	sd	ra,40(sp)
    800051e6:	f022                	sd	s0,32(sp)
    800051e8:	ec26                	sd	s1,24(sp)
    800051ea:	e84a                	sd	s2,16(sp)
    800051ec:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051ee:	fd840613          	add	a2,s0,-40
    800051f2:	4581                	li	a1,0
    800051f4:	4501                	li	a0,0
    800051f6:	00000097          	auipc	ra,0x0
    800051fa:	de0080e7          	jalr	-544(ra) # 80004fd6 <argfd>
    return -1;
    800051fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005200:	02054363          	bltz	a0,80005226 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005204:	fd843903          	ld	s2,-40(s0)
    80005208:	854a                	mv	a0,s2
    8000520a:	00000097          	auipc	ra,0x0
    8000520e:	e34080e7          	jalr	-460(ra) # 8000503e <fdalloc>
    80005212:	84aa                	mv	s1,a0
    return -1;
    80005214:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005216:	00054863          	bltz	a0,80005226 <sys_dup+0x44>
  filedup(f);
    8000521a:	854a                	mv	a0,s2
    8000521c:	fffff097          	auipc	ra,0xfffff
    80005220:	358080e7          	jalr	856(ra) # 80004574 <filedup>
  return fd;
    80005224:	87a6                	mv	a5,s1
}
    80005226:	853e                	mv	a0,a5
    80005228:	70a2                	ld	ra,40(sp)
    8000522a:	7402                	ld	s0,32(sp)
    8000522c:	64e2                	ld	s1,24(sp)
    8000522e:	6942                	ld	s2,16(sp)
    80005230:	6145                	add	sp,sp,48
    80005232:	8082                	ret

0000000080005234 <sys_read>:
{
    80005234:	7179                	add	sp,sp,-48
    80005236:	f406                	sd	ra,40(sp)
    80005238:	f022                	sd	s0,32(sp)
    8000523a:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000523c:	fe840613          	add	a2,s0,-24
    80005240:	4581                	li	a1,0
    80005242:	4501                	li	a0,0
    80005244:	00000097          	auipc	ra,0x0
    80005248:	d92080e7          	jalr	-622(ra) # 80004fd6 <argfd>
    return -1;
    8000524c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000524e:	04054163          	bltz	a0,80005290 <sys_read+0x5c>
    80005252:	fe440593          	add	a1,s0,-28
    80005256:	4509                	li	a0,2
    80005258:	ffffe097          	auipc	ra,0xffffe
    8000525c:	8e8080e7          	jalr	-1816(ra) # 80002b40 <argint>
    return -1;
    80005260:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005262:	02054763          	bltz	a0,80005290 <sys_read+0x5c>
    80005266:	fd840593          	add	a1,s0,-40
    8000526a:	4505                	li	a0,1
    8000526c:	ffffe097          	auipc	ra,0xffffe
    80005270:	8f6080e7          	jalr	-1802(ra) # 80002b62 <argaddr>
    return -1;
    80005274:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005276:	00054d63          	bltz	a0,80005290 <sys_read+0x5c>
  return fileread(f, p, n);
    8000527a:	fe442603          	lw	a2,-28(s0)
    8000527e:	fd843583          	ld	a1,-40(s0)
    80005282:	fe843503          	ld	a0,-24(s0)
    80005286:	fffff097          	auipc	ra,0xfffff
    8000528a:	47a080e7          	jalr	1146(ra) # 80004700 <fileread>
    8000528e:	87aa                	mv	a5,a0
}
    80005290:	853e                	mv	a0,a5
    80005292:	70a2                	ld	ra,40(sp)
    80005294:	7402                	ld	s0,32(sp)
    80005296:	6145                	add	sp,sp,48
    80005298:	8082                	ret

000000008000529a <sys_write>:
{
    8000529a:	7179                	add	sp,sp,-48
    8000529c:	f406                	sd	ra,40(sp)
    8000529e:	f022                	sd	s0,32(sp)
    800052a0:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a2:	fe840613          	add	a2,s0,-24
    800052a6:	4581                	li	a1,0
    800052a8:	4501                	li	a0,0
    800052aa:	00000097          	auipc	ra,0x0
    800052ae:	d2c080e7          	jalr	-724(ra) # 80004fd6 <argfd>
    return -1;
    800052b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052b4:	04054163          	bltz	a0,800052f6 <sys_write+0x5c>
    800052b8:	fe440593          	add	a1,s0,-28
    800052bc:	4509                	li	a0,2
    800052be:	ffffe097          	auipc	ra,0xffffe
    800052c2:	882080e7          	jalr	-1918(ra) # 80002b40 <argint>
    return -1;
    800052c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052c8:	02054763          	bltz	a0,800052f6 <sys_write+0x5c>
    800052cc:	fd840593          	add	a1,s0,-40
    800052d0:	4505                	li	a0,1
    800052d2:	ffffe097          	auipc	ra,0xffffe
    800052d6:	890080e7          	jalr	-1904(ra) # 80002b62 <argaddr>
    return -1;
    800052da:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052dc:	00054d63          	bltz	a0,800052f6 <sys_write+0x5c>
  return filewrite(f, p, n);
    800052e0:	fe442603          	lw	a2,-28(s0)
    800052e4:	fd843583          	ld	a1,-40(s0)
    800052e8:	fe843503          	ld	a0,-24(s0)
    800052ec:	fffff097          	auipc	ra,0xfffff
    800052f0:	4d6080e7          	jalr	1238(ra) # 800047c2 <filewrite>
    800052f4:	87aa                	mv	a5,a0
}
    800052f6:	853e                	mv	a0,a5
    800052f8:	70a2                	ld	ra,40(sp)
    800052fa:	7402                	ld	s0,32(sp)
    800052fc:	6145                	add	sp,sp,48
    800052fe:	8082                	ret

0000000080005300 <sys_close>:
{
    80005300:	1101                	add	sp,sp,-32
    80005302:	ec06                	sd	ra,24(sp)
    80005304:	e822                	sd	s0,16(sp)
    80005306:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005308:	fe040613          	add	a2,s0,-32
    8000530c:	fec40593          	add	a1,s0,-20
    80005310:	4501                	li	a0,0
    80005312:	00000097          	auipc	ra,0x0
    80005316:	cc4080e7          	jalr	-828(ra) # 80004fd6 <argfd>
    return -1;
    8000531a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000531c:	02054463          	bltz	a0,80005344 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005320:	ffffc097          	auipc	ra,0xffffc
    80005324:	70a080e7          	jalr	1802(ra) # 80001a2a <myproc>
    80005328:	fec42783          	lw	a5,-20(s0)
    8000532c:	07e9                	add	a5,a5,26
    8000532e:	078e                	sll	a5,a5,0x3
    80005330:	953e                	add	a0,a0,a5
    80005332:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005336:	fe043503          	ld	a0,-32(s0)
    8000533a:	fffff097          	auipc	ra,0xfffff
    8000533e:	28c080e7          	jalr	652(ra) # 800045c6 <fileclose>
  return 0;
    80005342:	4781                	li	a5,0
}
    80005344:	853e                	mv	a0,a5
    80005346:	60e2                	ld	ra,24(sp)
    80005348:	6442                	ld	s0,16(sp)
    8000534a:	6105                	add	sp,sp,32
    8000534c:	8082                	ret

000000008000534e <sys_fstat>:
{
    8000534e:	1101                	add	sp,sp,-32
    80005350:	ec06                	sd	ra,24(sp)
    80005352:	e822                	sd	s0,16(sp)
    80005354:	1000                	add	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005356:	fe840613          	add	a2,s0,-24
    8000535a:	4581                	li	a1,0
    8000535c:	4501                	li	a0,0
    8000535e:	00000097          	auipc	ra,0x0
    80005362:	c78080e7          	jalr	-904(ra) # 80004fd6 <argfd>
    return -1;
    80005366:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005368:	02054563          	bltz	a0,80005392 <sys_fstat+0x44>
    8000536c:	fe040593          	add	a1,s0,-32
    80005370:	4505                	li	a0,1
    80005372:	ffffd097          	auipc	ra,0xffffd
    80005376:	7f0080e7          	jalr	2032(ra) # 80002b62 <argaddr>
    return -1;
    8000537a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000537c:	00054b63          	bltz	a0,80005392 <sys_fstat+0x44>
  return filestat(f, st);
    80005380:	fe043583          	ld	a1,-32(s0)
    80005384:	fe843503          	ld	a0,-24(s0)
    80005388:	fffff097          	auipc	ra,0xfffff
    8000538c:	306080e7          	jalr	774(ra) # 8000468e <filestat>
    80005390:	87aa                	mv	a5,a0
}
    80005392:	853e                	mv	a0,a5
    80005394:	60e2                	ld	ra,24(sp)
    80005396:	6442                	ld	s0,16(sp)
    80005398:	6105                	add	sp,sp,32
    8000539a:	8082                	ret

000000008000539c <sys_link>:
{
    8000539c:	7169                	add	sp,sp,-304
    8000539e:	f606                	sd	ra,296(sp)
    800053a0:	f222                	sd	s0,288(sp)
    800053a2:	ee26                	sd	s1,280(sp)
    800053a4:	ea4a                	sd	s2,272(sp)
    800053a6:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053a8:	08000613          	li	a2,128
    800053ac:	ed040593          	add	a1,s0,-304
    800053b0:	4501                	li	a0,0
    800053b2:	ffffd097          	auipc	ra,0xffffd
    800053b6:	7d2080e7          	jalr	2002(ra) # 80002b84 <argstr>
    return -1;
    800053ba:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053bc:	10054e63          	bltz	a0,800054d8 <sys_link+0x13c>
    800053c0:	08000613          	li	a2,128
    800053c4:	f5040593          	add	a1,s0,-176
    800053c8:	4505                	li	a0,1
    800053ca:	ffffd097          	auipc	ra,0xffffd
    800053ce:	7ba080e7          	jalr	1978(ra) # 80002b84 <argstr>
    return -1;
    800053d2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053d4:	10054263          	bltz	a0,800054d8 <sys_link+0x13c>
  begin_op();
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	d24080e7          	jalr	-732(ra) # 800040fc <begin_op>
  if((ip = namei(old)) == 0){
    800053e0:	ed040513          	add	a0,s0,-304
    800053e4:	fffff097          	auipc	ra,0xfffff
    800053e8:	b28080e7          	jalr	-1240(ra) # 80003f0c <namei>
    800053ec:	84aa                	mv	s1,a0
    800053ee:	c551                	beqz	a0,8000547a <sys_link+0xde>
  ilock(ip);
    800053f0:	ffffe097          	auipc	ra,0xffffe
    800053f4:	36c080e7          	jalr	876(ra) # 8000375c <ilock>
  if(ip->type == T_DIR){
    800053f8:	04449703          	lh	a4,68(s1)
    800053fc:	4785                	li	a5,1
    800053fe:	08f70463          	beq	a4,a5,80005486 <sys_link+0xea>
  ip->nlink++;
    80005402:	04a4d783          	lhu	a5,74(s1)
    80005406:	2785                	addw	a5,a5,1
    80005408:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000540c:	8526                	mv	a0,s1
    8000540e:	ffffe097          	auipc	ra,0xffffe
    80005412:	282080e7          	jalr	642(ra) # 80003690 <iupdate>
  iunlock(ip);
    80005416:	8526                	mv	a0,s1
    80005418:	ffffe097          	auipc	ra,0xffffe
    8000541c:	406080e7          	jalr	1030(ra) # 8000381e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005420:	fd040593          	add	a1,s0,-48
    80005424:	f5040513          	add	a0,s0,-176
    80005428:	fffff097          	auipc	ra,0xfffff
    8000542c:	b02080e7          	jalr	-1278(ra) # 80003f2a <nameiparent>
    80005430:	892a                	mv	s2,a0
    80005432:	c935                	beqz	a0,800054a6 <sys_link+0x10a>
  ilock(dp);
    80005434:	ffffe097          	auipc	ra,0xffffe
    80005438:	328080e7          	jalr	808(ra) # 8000375c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000543c:	00092703          	lw	a4,0(s2)
    80005440:	409c                	lw	a5,0(s1)
    80005442:	04f71d63          	bne	a4,a5,8000549c <sys_link+0x100>
    80005446:	40d0                	lw	a2,4(s1)
    80005448:	fd040593          	add	a1,s0,-48
    8000544c:	854a                	mv	a0,s2
    8000544e:	fffff097          	auipc	ra,0xfffff
    80005452:	9fc080e7          	jalr	-1540(ra) # 80003e4a <dirlink>
    80005456:	04054363          	bltz	a0,8000549c <sys_link+0x100>
  iunlockput(dp);
    8000545a:	854a                	mv	a0,s2
    8000545c:	ffffe097          	auipc	ra,0xffffe
    80005460:	562080e7          	jalr	1378(ra) # 800039be <iunlockput>
  iput(ip);
    80005464:	8526                	mv	a0,s1
    80005466:	ffffe097          	auipc	ra,0xffffe
    8000546a:	4b0080e7          	jalr	1200(ra) # 80003916 <iput>
  end_op();
    8000546e:	fffff097          	auipc	ra,0xfffff
    80005472:	d08080e7          	jalr	-760(ra) # 80004176 <end_op>
  return 0;
    80005476:	4781                	li	a5,0
    80005478:	a085                	j	800054d8 <sys_link+0x13c>
    end_op();
    8000547a:	fffff097          	auipc	ra,0xfffff
    8000547e:	cfc080e7          	jalr	-772(ra) # 80004176 <end_op>
    return -1;
    80005482:	57fd                	li	a5,-1
    80005484:	a891                	j	800054d8 <sys_link+0x13c>
    iunlockput(ip);
    80005486:	8526                	mv	a0,s1
    80005488:	ffffe097          	auipc	ra,0xffffe
    8000548c:	536080e7          	jalr	1334(ra) # 800039be <iunlockput>
    end_op();
    80005490:	fffff097          	auipc	ra,0xfffff
    80005494:	ce6080e7          	jalr	-794(ra) # 80004176 <end_op>
    return -1;
    80005498:	57fd                	li	a5,-1
    8000549a:	a83d                	j	800054d8 <sys_link+0x13c>
    iunlockput(dp);
    8000549c:	854a                	mv	a0,s2
    8000549e:	ffffe097          	auipc	ra,0xffffe
    800054a2:	520080e7          	jalr	1312(ra) # 800039be <iunlockput>
  ilock(ip);
    800054a6:	8526                	mv	a0,s1
    800054a8:	ffffe097          	auipc	ra,0xffffe
    800054ac:	2b4080e7          	jalr	692(ra) # 8000375c <ilock>
  ip->nlink--;
    800054b0:	04a4d783          	lhu	a5,74(s1)
    800054b4:	37fd                	addw	a5,a5,-1
    800054b6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054ba:	8526                	mv	a0,s1
    800054bc:	ffffe097          	auipc	ra,0xffffe
    800054c0:	1d4080e7          	jalr	468(ra) # 80003690 <iupdate>
  iunlockput(ip);
    800054c4:	8526                	mv	a0,s1
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	4f8080e7          	jalr	1272(ra) # 800039be <iunlockput>
  end_op();
    800054ce:	fffff097          	auipc	ra,0xfffff
    800054d2:	ca8080e7          	jalr	-856(ra) # 80004176 <end_op>
  return -1;
    800054d6:	57fd                	li	a5,-1
}
    800054d8:	853e                	mv	a0,a5
    800054da:	70b2                	ld	ra,296(sp)
    800054dc:	7412                	ld	s0,288(sp)
    800054de:	64f2                	ld	s1,280(sp)
    800054e0:	6952                	ld	s2,272(sp)
    800054e2:	6155                	add	sp,sp,304
    800054e4:	8082                	ret

00000000800054e6 <sys_unlink>:
{
    800054e6:	7151                	add	sp,sp,-240
    800054e8:	f586                	sd	ra,232(sp)
    800054ea:	f1a2                	sd	s0,224(sp)
    800054ec:	eda6                	sd	s1,216(sp)
    800054ee:	e9ca                	sd	s2,208(sp)
    800054f0:	e5ce                	sd	s3,200(sp)
    800054f2:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054f4:	08000613          	li	a2,128
    800054f8:	f3040593          	add	a1,s0,-208
    800054fc:	4501                	li	a0,0
    800054fe:	ffffd097          	auipc	ra,0xffffd
    80005502:	686080e7          	jalr	1670(ra) # 80002b84 <argstr>
    80005506:	18054163          	bltz	a0,80005688 <sys_unlink+0x1a2>
  begin_op();
    8000550a:	fffff097          	auipc	ra,0xfffff
    8000550e:	bf2080e7          	jalr	-1038(ra) # 800040fc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005512:	fb040593          	add	a1,s0,-80
    80005516:	f3040513          	add	a0,s0,-208
    8000551a:	fffff097          	auipc	ra,0xfffff
    8000551e:	a10080e7          	jalr	-1520(ra) # 80003f2a <nameiparent>
    80005522:	84aa                	mv	s1,a0
    80005524:	c979                	beqz	a0,800055fa <sys_unlink+0x114>
  ilock(dp);
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	236080e7          	jalr	566(ra) # 8000375c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000552e:	00003597          	auipc	a1,0x3
    80005532:	1e258593          	add	a1,a1,482 # 80008710 <syscalls+0x2d0>
    80005536:	fb040513          	add	a0,s0,-80
    8000553a:	ffffe097          	auipc	ra,0xffffe
    8000553e:	6e6080e7          	jalr	1766(ra) # 80003c20 <namecmp>
    80005542:	14050a63          	beqz	a0,80005696 <sys_unlink+0x1b0>
    80005546:	00003597          	auipc	a1,0x3
    8000554a:	1d258593          	add	a1,a1,466 # 80008718 <syscalls+0x2d8>
    8000554e:	fb040513          	add	a0,s0,-80
    80005552:	ffffe097          	auipc	ra,0xffffe
    80005556:	6ce080e7          	jalr	1742(ra) # 80003c20 <namecmp>
    8000555a:	12050e63          	beqz	a0,80005696 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000555e:	f2c40613          	add	a2,s0,-212
    80005562:	fb040593          	add	a1,s0,-80
    80005566:	8526                	mv	a0,s1
    80005568:	ffffe097          	auipc	ra,0xffffe
    8000556c:	6d2080e7          	jalr	1746(ra) # 80003c3a <dirlookup>
    80005570:	892a                	mv	s2,a0
    80005572:	12050263          	beqz	a0,80005696 <sys_unlink+0x1b0>
  ilock(ip);
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	1e6080e7          	jalr	486(ra) # 8000375c <ilock>
  if(ip->nlink < 1)
    8000557e:	04a91783          	lh	a5,74(s2)
    80005582:	08f05263          	blez	a5,80005606 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005586:	04491703          	lh	a4,68(s2)
    8000558a:	4785                	li	a5,1
    8000558c:	08f70563          	beq	a4,a5,80005616 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005590:	4641                	li	a2,16
    80005592:	4581                	li	a1,0
    80005594:	fc040513          	add	a0,s0,-64
    80005598:	ffffb097          	auipc	ra,0xffffb
    8000559c:	7c4080e7          	jalr	1988(ra) # 80000d5c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055a0:	4741                	li	a4,16
    800055a2:	f2c42683          	lw	a3,-212(s0)
    800055a6:	fc040613          	add	a2,s0,-64
    800055aa:	4581                	li	a1,0
    800055ac:	8526                	mv	a0,s1
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	558080e7          	jalr	1368(ra) # 80003b06 <writei>
    800055b6:	47c1                	li	a5,16
    800055b8:	0af51563          	bne	a0,a5,80005662 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055bc:	04491703          	lh	a4,68(s2)
    800055c0:	4785                	li	a5,1
    800055c2:	0af70863          	beq	a4,a5,80005672 <sys_unlink+0x18c>
  iunlockput(dp);
    800055c6:	8526                	mv	a0,s1
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	3f6080e7          	jalr	1014(ra) # 800039be <iunlockput>
  ip->nlink--;
    800055d0:	04a95783          	lhu	a5,74(s2)
    800055d4:	37fd                	addw	a5,a5,-1
    800055d6:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055da:	854a                	mv	a0,s2
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	0b4080e7          	jalr	180(ra) # 80003690 <iupdate>
  iunlockput(ip);
    800055e4:	854a                	mv	a0,s2
    800055e6:	ffffe097          	auipc	ra,0xffffe
    800055ea:	3d8080e7          	jalr	984(ra) # 800039be <iunlockput>
  end_op();
    800055ee:	fffff097          	auipc	ra,0xfffff
    800055f2:	b88080e7          	jalr	-1144(ra) # 80004176 <end_op>
  return 0;
    800055f6:	4501                	li	a0,0
    800055f8:	a84d                	j	800056aa <sys_unlink+0x1c4>
    end_op();
    800055fa:	fffff097          	auipc	ra,0xfffff
    800055fe:	b7c080e7          	jalr	-1156(ra) # 80004176 <end_op>
    return -1;
    80005602:	557d                	li	a0,-1
    80005604:	a05d                	j	800056aa <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005606:	00003517          	auipc	a0,0x3
    8000560a:	13a50513          	add	a0,a0,314 # 80008740 <syscalls+0x300>
    8000560e:	ffffb097          	auipc	ra,0xffffb
    80005612:	f34080e7          	jalr	-204(ra) # 80000542 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005616:	04c92703          	lw	a4,76(s2)
    8000561a:	02000793          	li	a5,32
    8000561e:	f6e7f9e3          	bgeu	a5,a4,80005590 <sys_unlink+0xaa>
    80005622:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005626:	4741                	li	a4,16
    80005628:	86ce                	mv	a3,s3
    8000562a:	f1840613          	add	a2,s0,-232
    8000562e:	4581                	li	a1,0
    80005630:	854a                	mv	a0,s2
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	3de080e7          	jalr	990(ra) # 80003a10 <readi>
    8000563a:	47c1                	li	a5,16
    8000563c:	00f51b63          	bne	a0,a5,80005652 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005640:	f1845783          	lhu	a5,-232(s0)
    80005644:	e7a1                	bnez	a5,8000568c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005646:	29c1                	addw	s3,s3,16
    80005648:	04c92783          	lw	a5,76(s2)
    8000564c:	fcf9ede3          	bltu	s3,a5,80005626 <sys_unlink+0x140>
    80005650:	b781                	j	80005590 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005652:	00003517          	auipc	a0,0x3
    80005656:	10650513          	add	a0,a0,262 # 80008758 <syscalls+0x318>
    8000565a:	ffffb097          	auipc	ra,0xffffb
    8000565e:	ee8080e7          	jalr	-280(ra) # 80000542 <panic>
    panic("unlink: writei");
    80005662:	00003517          	auipc	a0,0x3
    80005666:	10e50513          	add	a0,a0,270 # 80008770 <syscalls+0x330>
    8000566a:	ffffb097          	auipc	ra,0xffffb
    8000566e:	ed8080e7          	jalr	-296(ra) # 80000542 <panic>
    dp->nlink--;
    80005672:	04a4d783          	lhu	a5,74(s1)
    80005676:	37fd                	addw	a5,a5,-1
    80005678:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000567c:	8526                	mv	a0,s1
    8000567e:	ffffe097          	auipc	ra,0xffffe
    80005682:	012080e7          	jalr	18(ra) # 80003690 <iupdate>
    80005686:	b781                	j	800055c6 <sys_unlink+0xe0>
    return -1;
    80005688:	557d                	li	a0,-1
    8000568a:	a005                	j	800056aa <sys_unlink+0x1c4>
    iunlockput(ip);
    8000568c:	854a                	mv	a0,s2
    8000568e:	ffffe097          	auipc	ra,0xffffe
    80005692:	330080e7          	jalr	816(ra) # 800039be <iunlockput>
  iunlockput(dp);
    80005696:	8526                	mv	a0,s1
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	326080e7          	jalr	806(ra) # 800039be <iunlockput>
  end_op();
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	ad6080e7          	jalr	-1322(ra) # 80004176 <end_op>
  return -1;
    800056a8:	557d                	li	a0,-1
}
    800056aa:	70ae                	ld	ra,232(sp)
    800056ac:	740e                	ld	s0,224(sp)
    800056ae:	64ee                	ld	s1,216(sp)
    800056b0:	694e                	ld	s2,208(sp)
    800056b2:	69ae                	ld	s3,200(sp)
    800056b4:	616d                	add	sp,sp,240
    800056b6:	8082                	ret

00000000800056b8 <sys_open>:

uint64
sys_open(void)
{
    800056b8:	7131                	add	sp,sp,-192
    800056ba:	fd06                	sd	ra,184(sp)
    800056bc:	f922                	sd	s0,176(sp)
    800056be:	f526                	sd	s1,168(sp)
    800056c0:	f14a                	sd	s2,160(sp)
    800056c2:	ed4e                	sd	s3,152(sp)
    800056c4:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056c6:	08000613          	li	a2,128
    800056ca:	f5040593          	add	a1,s0,-176
    800056ce:	4501                	li	a0,0
    800056d0:	ffffd097          	auipc	ra,0xffffd
    800056d4:	4b4080e7          	jalr	1204(ra) # 80002b84 <argstr>
    return -1;
    800056d8:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056da:	0c054063          	bltz	a0,8000579a <sys_open+0xe2>
    800056de:	f4c40593          	add	a1,s0,-180
    800056e2:	4505                	li	a0,1
    800056e4:	ffffd097          	auipc	ra,0xffffd
    800056e8:	45c080e7          	jalr	1116(ra) # 80002b40 <argint>
    800056ec:	0a054763          	bltz	a0,8000579a <sys_open+0xe2>

  begin_op();
    800056f0:	fffff097          	auipc	ra,0xfffff
    800056f4:	a0c080e7          	jalr	-1524(ra) # 800040fc <begin_op>

  if(omode & O_CREATE){
    800056f8:	f4c42783          	lw	a5,-180(s0)
    800056fc:	2007f793          	and	a5,a5,512
    80005700:	cbd5                	beqz	a5,800057b4 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005702:	4681                	li	a3,0
    80005704:	4601                	li	a2,0
    80005706:	4589                	li	a1,2
    80005708:	f5040513          	add	a0,s0,-176
    8000570c:	00000097          	auipc	ra,0x0
    80005710:	974080e7          	jalr	-1676(ra) # 80005080 <create>
    80005714:	892a                	mv	s2,a0
    if(ip == 0){
    80005716:	c951                	beqz	a0,800057aa <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005718:	04491703          	lh	a4,68(s2)
    8000571c:	478d                	li	a5,3
    8000571e:	00f71763          	bne	a4,a5,8000572c <sys_open+0x74>
    80005722:	04695703          	lhu	a4,70(s2)
    80005726:	47a5                	li	a5,9
    80005728:	0ce7eb63          	bltu	a5,a4,800057fe <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000572c:	fffff097          	auipc	ra,0xfffff
    80005730:	dde080e7          	jalr	-546(ra) # 8000450a <filealloc>
    80005734:	89aa                	mv	s3,a0
    80005736:	c565                	beqz	a0,8000581e <sys_open+0x166>
    80005738:	00000097          	auipc	ra,0x0
    8000573c:	906080e7          	jalr	-1786(ra) # 8000503e <fdalloc>
    80005740:	84aa                	mv	s1,a0
    80005742:	0c054963          	bltz	a0,80005814 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005746:	04491703          	lh	a4,68(s2)
    8000574a:	478d                	li	a5,3
    8000574c:	0ef70463          	beq	a4,a5,80005834 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005750:	4789                	li	a5,2
    80005752:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005756:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000575a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000575e:	f4c42783          	lw	a5,-180(s0)
    80005762:	0017c713          	xor	a4,a5,1
    80005766:	8b05                	and	a4,a4,1
    80005768:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000576c:	0037f713          	and	a4,a5,3
    80005770:	00e03733          	snez	a4,a4
    80005774:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005778:	4007f793          	and	a5,a5,1024
    8000577c:	c791                	beqz	a5,80005788 <sys_open+0xd0>
    8000577e:	04491703          	lh	a4,68(s2)
    80005782:	4789                	li	a5,2
    80005784:	0af70f63          	beq	a4,a5,80005842 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005788:	854a                	mv	a0,s2
    8000578a:	ffffe097          	auipc	ra,0xffffe
    8000578e:	094080e7          	jalr	148(ra) # 8000381e <iunlock>
  end_op();
    80005792:	fffff097          	auipc	ra,0xfffff
    80005796:	9e4080e7          	jalr	-1564(ra) # 80004176 <end_op>

  return fd;
}
    8000579a:	8526                	mv	a0,s1
    8000579c:	70ea                	ld	ra,184(sp)
    8000579e:	744a                	ld	s0,176(sp)
    800057a0:	74aa                	ld	s1,168(sp)
    800057a2:	790a                	ld	s2,160(sp)
    800057a4:	69ea                	ld	s3,152(sp)
    800057a6:	6129                	add	sp,sp,192
    800057a8:	8082                	ret
      end_op();
    800057aa:	fffff097          	auipc	ra,0xfffff
    800057ae:	9cc080e7          	jalr	-1588(ra) # 80004176 <end_op>
      return -1;
    800057b2:	b7e5                	j	8000579a <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    800057b4:	f5040513          	add	a0,s0,-176
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	754080e7          	jalr	1876(ra) # 80003f0c <namei>
    800057c0:	892a                	mv	s2,a0
    800057c2:	c905                	beqz	a0,800057f2 <sys_open+0x13a>
    ilock(ip);
    800057c4:	ffffe097          	auipc	ra,0xffffe
    800057c8:	f98080e7          	jalr	-104(ra) # 8000375c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057cc:	04491703          	lh	a4,68(s2)
    800057d0:	4785                	li	a5,1
    800057d2:	f4f713e3          	bne	a4,a5,80005718 <sys_open+0x60>
    800057d6:	f4c42783          	lw	a5,-180(s0)
    800057da:	dba9                	beqz	a5,8000572c <sys_open+0x74>
      iunlockput(ip);
    800057dc:	854a                	mv	a0,s2
    800057de:	ffffe097          	auipc	ra,0xffffe
    800057e2:	1e0080e7          	jalr	480(ra) # 800039be <iunlockput>
      end_op();
    800057e6:	fffff097          	auipc	ra,0xfffff
    800057ea:	990080e7          	jalr	-1648(ra) # 80004176 <end_op>
      return -1;
    800057ee:	54fd                	li	s1,-1
    800057f0:	b76d                	j	8000579a <sys_open+0xe2>
      end_op();
    800057f2:	fffff097          	auipc	ra,0xfffff
    800057f6:	984080e7          	jalr	-1660(ra) # 80004176 <end_op>
      return -1;
    800057fa:	54fd                	li	s1,-1
    800057fc:	bf79                	j	8000579a <sys_open+0xe2>
    iunlockput(ip);
    800057fe:	854a                	mv	a0,s2
    80005800:	ffffe097          	auipc	ra,0xffffe
    80005804:	1be080e7          	jalr	446(ra) # 800039be <iunlockput>
    end_op();
    80005808:	fffff097          	auipc	ra,0xfffff
    8000580c:	96e080e7          	jalr	-1682(ra) # 80004176 <end_op>
    return -1;
    80005810:	54fd                	li	s1,-1
    80005812:	b761                	j	8000579a <sys_open+0xe2>
      fileclose(f);
    80005814:	854e                	mv	a0,s3
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	db0080e7          	jalr	-592(ra) # 800045c6 <fileclose>
    iunlockput(ip);
    8000581e:	854a                	mv	a0,s2
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	19e080e7          	jalr	414(ra) # 800039be <iunlockput>
    end_op();
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	94e080e7          	jalr	-1714(ra) # 80004176 <end_op>
    return -1;
    80005830:	54fd                	li	s1,-1
    80005832:	b7a5                	j	8000579a <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005834:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005838:	04691783          	lh	a5,70(s2)
    8000583c:	02f99223          	sh	a5,36(s3)
    80005840:	bf29                	j	8000575a <sys_open+0xa2>
    itrunc(ip);
    80005842:	854a                	mv	a0,s2
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	026080e7          	jalr	38(ra) # 8000386a <itrunc>
    8000584c:	bf35                	j	80005788 <sys_open+0xd0>

000000008000584e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000584e:	7175                	add	sp,sp,-144
    80005850:	e506                	sd	ra,136(sp)
    80005852:	e122                	sd	s0,128(sp)
    80005854:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005856:	fffff097          	auipc	ra,0xfffff
    8000585a:	8a6080e7          	jalr	-1882(ra) # 800040fc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000585e:	08000613          	li	a2,128
    80005862:	f7040593          	add	a1,s0,-144
    80005866:	4501                	li	a0,0
    80005868:	ffffd097          	auipc	ra,0xffffd
    8000586c:	31c080e7          	jalr	796(ra) # 80002b84 <argstr>
    80005870:	02054963          	bltz	a0,800058a2 <sys_mkdir+0x54>
    80005874:	4681                	li	a3,0
    80005876:	4601                	li	a2,0
    80005878:	4585                	li	a1,1
    8000587a:	f7040513          	add	a0,s0,-144
    8000587e:	00000097          	auipc	ra,0x0
    80005882:	802080e7          	jalr	-2046(ra) # 80005080 <create>
    80005886:	cd11                	beqz	a0,800058a2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005888:	ffffe097          	auipc	ra,0xffffe
    8000588c:	136080e7          	jalr	310(ra) # 800039be <iunlockput>
  end_op();
    80005890:	fffff097          	auipc	ra,0xfffff
    80005894:	8e6080e7          	jalr	-1818(ra) # 80004176 <end_op>
  return 0;
    80005898:	4501                	li	a0,0
}
    8000589a:	60aa                	ld	ra,136(sp)
    8000589c:	640a                	ld	s0,128(sp)
    8000589e:	6149                	add	sp,sp,144
    800058a0:	8082                	ret
    end_op();
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	8d4080e7          	jalr	-1836(ra) # 80004176 <end_op>
    return -1;
    800058aa:	557d                	li	a0,-1
    800058ac:	b7fd                	j	8000589a <sys_mkdir+0x4c>

00000000800058ae <sys_mknod>:

uint64
sys_mknod(void)
{
    800058ae:	7135                	add	sp,sp,-160
    800058b0:	ed06                	sd	ra,152(sp)
    800058b2:	e922                	sd	s0,144(sp)
    800058b4:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	846080e7          	jalr	-1978(ra) # 800040fc <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058be:	08000613          	li	a2,128
    800058c2:	f7040593          	add	a1,s0,-144
    800058c6:	4501                	li	a0,0
    800058c8:	ffffd097          	auipc	ra,0xffffd
    800058cc:	2bc080e7          	jalr	700(ra) # 80002b84 <argstr>
    800058d0:	04054a63          	bltz	a0,80005924 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800058d4:	f6c40593          	add	a1,s0,-148
    800058d8:	4505                	li	a0,1
    800058da:	ffffd097          	auipc	ra,0xffffd
    800058de:	266080e7          	jalr	614(ra) # 80002b40 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058e2:	04054163          	bltz	a0,80005924 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800058e6:	f6840593          	add	a1,s0,-152
    800058ea:	4509                	li	a0,2
    800058ec:	ffffd097          	auipc	ra,0xffffd
    800058f0:	254080e7          	jalr	596(ra) # 80002b40 <argint>
     argint(1, &major) < 0 ||
    800058f4:	02054863          	bltz	a0,80005924 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058f8:	f6841683          	lh	a3,-152(s0)
    800058fc:	f6c41603          	lh	a2,-148(s0)
    80005900:	458d                	li	a1,3
    80005902:	f7040513          	add	a0,s0,-144
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	77a080e7          	jalr	1914(ra) # 80005080 <create>
     argint(2, &minor) < 0 ||
    8000590e:	c919                	beqz	a0,80005924 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	0ae080e7          	jalr	174(ra) # 800039be <iunlockput>
  end_op();
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	85e080e7          	jalr	-1954(ra) # 80004176 <end_op>
  return 0;
    80005920:	4501                	li	a0,0
    80005922:	a031                	j	8000592e <sys_mknod+0x80>
    end_op();
    80005924:	fffff097          	auipc	ra,0xfffff
    80005928:	852080e7          	jalr	-1966(ra) # 80004176 <end_op>
    return -1;
    8000592c:	557d                	li	a0,-1
}
    8000592e:	60ea                	ld	ra,152(sp)
    80005930:	644a                	ld	s0,144(sp)
    80005932:	610d                	add	sp,sp,160
    80005934:	8082                	ret

0000000080005936 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005936:	7135                	add	sp,sp,-160
    80005938:	ed06                	sd	ra,152(sp)
    8000593a:	e922                	sd	s0,144(sp)
    8000593c:	e526                	sd	s1,136(sp)
    8000593e:	e14a                	sd	s2,128(sp)
    80005940:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005942:	ffffc097          	auipc	ra,0xffffc
    80005946:	0e8080e7          	jalr	232(ra) # 80001a2a <myproc>
    8000594a:	892a                	mv	s2,a0
  
  begin_op();
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	7b0080e7          	jalr	1968(ra) # 800040fc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005954:	08000613          	li	a2,128
    80005958:	f6040593          	add	a1,s0,-160
    8000595c:	4501                	li	a0,0
    8000595e:	ffffd097          	auipc	ra,0xffffd
    80005962:	226080e7          	jalr	550(ra) # 80002b84 <argstr>
    80005966:	04054b63          	bltz	a0,800059bc <sys_chdir+0x86>
    8000596a:	f6040513          	add	a0,s0,-160
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	59e080e7          	jalr	1438(ra) # 80003f0c <namei>
    80005976:	84aa                	mv	s1,a0
    80005978:	c131                	beqz	a0,800059bc <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000597a:	ffffe097          	auipc	ra,0xffffe
    8000597e:	de2080e7          	jalr	-542(ra) # 8000375c <ilock>
  if(ip->type != T_DIR){
    80005982:	04449703          	lh	a4,68(s1)
    80005986:	4785                	li	a5,1
    80005988:	04f71063          	bne	a4,a5,800059c8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000598c:	8526                	mv	a0,s1
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	e90080e7          	jalr	-368(ra) # 8000381e <iunlock>
  iput(p->cwd);
    80005996:	15093503          	ld	a0,336(s2)
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	f7c080e7          	jalr	-132(ra) # 80003916 <iput>
  end_op();
    800059a2:	ffffe097          	auipc	ra,0xffffe
    800059a6:	7d4080e7          	jalr	2004(ra) # 80004176 <end_op>
  p->cwd = ip;
    800059aa:	14993823          	sd	s1,336(s2)
  return 0;
    800059ae:	4501                	li	a0,0
}
    800059b0:	60ea                	ld	ra,152(sp)
    800059b2:	644a                	ld	s0,144(sp)
    800059b4:	64aa                	ld	s1,136(sp)
    800059b6:	690a                	ld	s2,128(sp)
    800059b8:	610d                	add	sp,sp,160
    800059ba:	8082                	ret
    end_op();
    800059bc:	ffffe097          	auipc	ra,0xffffe
    800059c0:	7ba080e7          	jalr	1978(ra) # 80004176 <end_op>
    return -1;
    800059c4:	557d                	li	a0,-1
    800059c6:	b7ed                	j	800059b0 <sys_chdir+0x7a>
    iunlockput(ip);
    800059c8:	8526                	mv	a0,s1
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	ff4080e7          	jalr	-12(ra) # 800039be <iunlockput>
    end_op();
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	7a4080e7          	jalr	1956(ra) # 80004176 <end_op>
    return -1;
    800059da:	557d                	li	a0,-1
    800059dc:	bfd1                	j	800059b0 <sys_chdir+0x7a>

00000000800059de <sys_exec>:

uint64
sys_exec(void)
{
    800059de:	7121                	add	sp,sp,-448
    800059e0:	ff06                	sd	ra,440(sp)
    800059e2:	fb22                	sd	s0,432(sp)
    800059e4:	f726                	sd	s1,424(sp)
    800059e6:	f34a                	sd	s2,416(sp)
    800059e8:	ef4e                	sd	s3,408(sp)
    800059ea:	eb52                	sd	s4,400(sp)
    800059ec:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059ee:	08000613          	li	a2,128
    800059f2:	f5040593          	add	a1,s0,-176
    800059f6:	4501                	li	a0,0
    800059f8:	ffffd097          	auipc	ra,0xffffd
    800059fc:	18c080e7          	jalr	396(ra) # 80002b84 <argstr>
    return -1;
    80005a00:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a02:	0c054a63          	bltz	a0,80005ad6 <sys_exec+0xf8>
    80005a06:	e4840593          	add	a1,s0,-440
    80005a0a:	4505                	li	a0,1
    80005a0c:	ffffd097          	auipc	ra,0xffffd
    80005a10:	156080e7          	jalr	342(ra) # 80002b62 <argaddr>
    80005a14:	0c054163          	bltz	a0,80005ad6 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005a18:	10000613          	li	a2,256
    80005a1c:	4581                	li	a1,0
    80005a1e:	e5040513          	add	a0,s0,-432
    80005a22:	ffffb097          	auipc	ra,0xffffb
    80005a26:	33a080e7          	jalr	826(ra) # 80000d5c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a2a:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005a2e:	89a6                	mv	s3,s1
    80005a30:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a32:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a36:	00391513          	sll	a0,s2,0x3
    80005a3a:	e4040593          	add	a1,s0,-448
    80005a3e:	e4843783          	ld	a5,-440(s0)
    80005a42:	953e                	add	a0,a0,a5
    80005a44:	ffffd097          	auipc	ra,0xffffd
    80005a48:	062080e7          	jalr	98(ra) # 80002aa6 <fetchaddr>
    80005a4c:	02054a63          	bltz	a0,80005a80 <sys_exec+0xa2>
      goto bad;
    }
    if(uarg == 0){
    80005a50:	e4043783          	ld	a5,-448(s0)
    80005a54:	c3b9                	beqz	a5,80005a9a <sys_exec+0xbc>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a56:	ffffb097          	auipc	ra,0xffffb
    80005a5a:	11a080e7          	jalr	282(ra) # 80000b70 <kalloc>
    80005a5e:	85aa                	mv	a1,a0
    80005a60:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a64:	cd11                	beqz	a0,80005a80 <sys_exec+0xa2>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a66:	6605                	lui	a2,0x1
    80005a68:	e4043503          	ld	a0,-448(s0)
    80005a6c:	ffffd097          	auipc	ra,0xffffd
    80005a70:	08c080e7          	jalr	140(ra) # 80002af8 <fetchstr>
    80005a74:	00054663          	bltz	a0,80005a80 <sys_exec+0xa2>
    if(i >= NELEM(argv)){
    80005a78:	0905                	add	s2,s2,1
    80005a7a:	09a1                	add	s3,s3,8
    80005a7c:	fb491de3          	bne	s2,s4,80005a36 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a80:	f5040913          	add	s2,s0,-176
    80005a84:	6088                	ld	a0,0(s1)
    80005a86:	c539                	beqz	a0,80005ad4 <sys_exec+0xf6>
    kfree(argv[i]);
    80005a88:	ffffb097          	auipc	ra,0xffffb
    80005a8c:	fea080e7          	jalr	-22(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a90:	04a1                	add	s1,s1,8
    80005a92:	ff2499e3          	bne	s1,s2,80005a84 <sys_exec+0xa6>
  return -1;
    80005a96:	597d                	li	s2,-1
    80005a98:	a83d                	j	80005ad6 <sys_exec+0xf8>
      argv[i] = 0;
    80005a9a:	0009079b          	sext.w	a5,s2
    80005a9e:	078e                	sll	a5,a5,0x3
    80005aa0:	fd078793          	add	a5,a5,-48
    80005aa4:	97a2                	add	a5,a5,s0
    80005aa6:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005aaa:	e5040593          	add	a1,s0,-432
    80005aae:	f5040513          	add	a0,s0,-176
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	196080e7          	jalr	406(ra) # 80004c48 <exec>
    80005aba:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005abc:	f5040993          	add	s3,s0,-176
    80005ac0:	6088                	ld	a0,0(s1)
    80005ac2:	c911                	beqz	a0,80005ad6 <sys_exec+0xf8>
    kfree(argv[i]);
    80005ac4:	ffffb097          	auipc	ra,0xffffb
    80005ac8:	fae080e7          	jalr	-82(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005acc:	04a1                	add	s1,s1,8
    80005ace:	ff3499e3          	bne	s1,s3,80005ac0 <sys_exec+0xe2>
    80005ad2:	a011                	j	80005ad6 <sys_exec+0xf8>
  return -1;
    80005ad4:	597d                	li	s2,-1
}
    80005ad6:	854a                	mv	a0,s2
    80005ad8:	70fa                	ld	ra,440(sp)
    80005ada:	745a                	ld	s0,432(sp)
    80005adc:	74ba                	ld	s1,424(sp)
    80005ade:	791a                	ld	s2,416(sp)
    80005ae0:	69fa                	ld	s3,408(sp)
    80005ae2:	6a5a                	ld	s4,400(sp)
    80005ae4:	6139                	add	sp,sp,448
    80005ae6:	8082                	ret

0000000080005ae8 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ae8:	7139                	add	sp,sp,-64
    80005aea:	fc06                	sd	ra,56(sp)
    80005aec:	f822                	sd	s0,48(sp)
    80005aee:	f426                	sd	s1,40(sp)
    80005af0:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005af2:	ffffc097          	auipc	ra,0xffffc
    80005af6:	f38080e7          	jalr	-200(ra) # 80001a2a <myproc>
    80005afa:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005afc:	fd840593          	add	a1,s0,-40
    80005b00:	4501                	li	a0,0
    80005b02:	ffffd097          	auipc	ra,0xffffd
    80005b06:	060080e7          	jalr	96(ra) # 80002b62 <argaddr>
    return -1;
    80005b0a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b0c:	0e054063          	bltz	a0,80005bec <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b10:	fc840593          	add	a1,s0,-56
    80005b14:	fd040513          	add	a0,s0,-48
    80005b18:	fffff097          	auipc	ra,0xfffff
    80005b1c:	e04080e7          	jalr	-508(ra) # 8000491c <pipealloc>
    return -1;
    80005b20:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b22:	0c054563          	bltz	a0,80005bec <sys_pipe+0x104>
  fd0 = -1;
    80005b26:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b2a:	fd043503          	ld	a0,-48(s0)
    80005b2e:	fffff097          	auipc	ra,0xfffff
    80005b32:	510080e7          	jalr	1296(ra) # 8000503e <fdalloc>
    80005b36:	fca42223          	sw	a0,-60(s0)
    80005b3a:	08054c63          	bltz	a0,80005bd2 <sys_pipe+0xea>
    80005b3e:	fc843503          	ld	a0,-56(s0)
    80005b42:	fffff097          	auipc	ra,0xfffff
    80005b46:	4fc080e7          	jalr	1276(ra) # 8000503e <fdalloc>
    80005b4a:	fca42023          	sw	a0,-64(s0)
    80005b4e:	06054963          	bltz	a0,80005bc0 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b52:	4691                	li	a3,4
    80005b54:	fc440613          	add	a2,s0,-60
    80005b58:	fd843583          	ld	a1,-40(s0)
    80005b5c:	68a8                	ld	a0,80(s1)
    80005b5e:	ffffc097          	auipc	ra,0xffffc
    80005b62:	bc2080e7          	jalr	-1086(ra) # 80001720 <copyout>
    80005b66:	02054063          	bltz	a0,80005b86 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b6a:	4691                	li	a3,4
    80005b6c:	fc040613          	add	a2,s0,-64
    80005b70:	fd843583          	ld	a1,-40(s0)
    80005b74:	0591                	add	a1,a1,4
    80005b76:	68a8                	ld	a0,80(s1)
    80005b78:	ffffc097          	auipc	ra,0xffffc
    80005b7c:	ba8080e7          	jalr	-1112(ra) # 80001720 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b80:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b82:	06055563          	bgez	a0,80005bec <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b86:	fc442783          	lw	a5,-60(s0)
    80005b8a:	07e9                	add	a5,a5,26
    80005b8c:	078e                	sll	a5,a5,0x3
    80005b8e:	97a6                	add	a5,a5,s1
    80005b90:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b94:	fc042783          	lw	a5,-64(s0)
    80005b98:	07e9                	add	a5,a5,26
    80005b9a:	078e                	sll	a5,a5,0x3
    80005b9c:	00f48533          	add	a0,s1,a5
    80005ba0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ba4:	fd043503          	ld	a0,-48(s0)
    80005ba8:	fffff097          	auipc	ra,0xfffff
    80005bac:	a1e080e7          	jalr	-1506(ra) # 800045c6 <fileclose>
    fileclose(wf);
    80005bb0:	fc843503          	ld	a0,-56(s0)
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	a12080e7          	jalr	-1518(ra) # 800045c6 <fileclose>
    return -1;
    80005bbc:	57fd                	li	a5,-1
    80005bbe:	a03d                	j	80005bec <sys_pipe+0x104>
    if(fd0 >= 0)
    80005bc0:	fc442783          	lw	a5,-60(s0)
    80005bc4:	0007c763          	bltz	a5,80005bd2 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005bc8:	07e9                	add	a5,a5,26
    80005bca:	078e                	sll	a5,a5,0x3
    80005bcc:	97a6                	add	a5,a5,s1
    80005bce:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005bd2:	fd043503          	ld	a0,-48(s0)
    80005bd6:	fffff097          	auipc	ra,0xfffff
    80005bda:	9f0080e7          	jalr	-1552(ra) # 800045c6 <fileclose>
    fileclose(wf);
    80005bde:	fc843503          	ld	a0,-56(s0)
    80005be2:	fffff097          	auipc	ra,0xfffff
    80005be6:	9e4080e7          	jalr	-1564(ra) # 800045c6 <fileclose>
    return -1;
    80005bea:	57fd                	li	a5,-1
}
    80005bec:	853e                	mv	a0,a5
    80005bee:	70e2                	ld	ra,56(sp)
    80005bf0:	7442                	ld	s0,48(sp)
    80005bf2:	74a2                	ld	s1,40(sp)
    80005bf4:	6121                	add	sp,sp,64
    80005bf6:	8082                	ret
	...

0000000080005c00 <kernelvec>:
    80005c00:	7111                	add	sp,sp,-256
    80005c02:	e006                	sd	ra,0(sp)
    80005c04:	e40a                	sd	sp,8(sp)
    80005c06:	e80e                	sd	gp,16(sp)
    80005c08:	ec12                	sd	tp,24(sp)
    80005c0a:	f016                	sd	t0,32(sp)
    80005c0c:	f41a                	sd	t1,40(sp)
    80005c0e:	f81e                	sd	t2,48(sp)
    80005c10:	fc22                	sd	s0,56(sp)
    80005c12:	e0a6                	sd	s1,64(sp)
    80005c14:	e4aa                	sd	a0,72(sp)
    80005c16:	e8ae                	sd	a1,80(sp)
    80005c18:	ecb2                	sd	a2,88(sp)
    80005c1a:	f0b6                	sd	a3,96(sp)
    80005c1c:	f4ba                	sd	a4,104(sp)
    80005c1e:	f8be                	sd	a5,112(sp)
    80005c20:	fcc2                	sd	a6,120(sp)
    80005c22:	e146                	sd	a7,128(sp)
    80005c24:	e54a                	sd	s2,136(sp)
    80005c26:	e94e                	sd	s3,144(sp)
    80005c28:	ed52                	sd	s4,152(sp)
    80005c2a:	f156                	sd	s5,160(sp)
    80005c2c:	f55a                	sd	s6,168(sp)
    80005c2e:	f95e                	sd	s7,176(sp)
    80005c30:	fd62                	sd	s8,184(sp)
    80005c32:	e1e6                	sd	s9,192(sp)
    80005c34:	e5ea                	sd	s10,200(sp)
    80005c36:	e9ee                	sd	s11,208(sp)
    80005c38:	edf2                	sd	t3,216(sp)
    80005c3a:	f1f6                	sd	t4,224(sp)
    80005c3c:	f5fa                	sd	t5,232(sp)
    80005c3e:	f9fe                	sd	t6,240(sp)
    80005c40:	d33fc0ef          	jal	80002972 <kerneltrap>
    80005c44:	6082                	ld	ra,0(sp)
    80005c46:	6122                	ld	sp,8(sp)
    80005c48:	61c2                	ld	gp,16(sp)
    80005c4a:	7282                	ld	t0,32(sp)
    80005c4c:	7322                	ld	t1,40(sp)
    80005c4e:	73c2                	ld	t2,48(sp)
    80005c50:	7462                	ld	s0,56(sp)
    80005c52:	6486                	ld	s1,64(sp)
    80005c54:	6526                	ld	a0,72(sp)
    80005c56:	65c6                	ld	a1,80(sp)
    80005c58:	6666                	ld	a2,88(sp)
    80005c5a:	7686                	ld	a3,96(sp)
    80005c5c:	7726                	ld	a4,104(sp)
    80005c5e:	77c6                	ld	a5,112(sp)
    80005c60:	7866                	ld	a6,120(sp)
    80005c62:	688a                	ld	a7,128(sp)
    80005c64:	692a                	ld	s2,136(sp)
    80005c66:	69ca                	ld	s3,144(sp)
    80005c68:	6a6a                	ld	s4,152(sp)
    80005c6a:	7a8a                	ld	s5,160(sp)
    80005c6c:	7b2a                	ld	s6,168(sp)
    80005c6e:	7bca                	ld	s7,176(sp)
    80005c70:	7c6a                	ld	s8,184(sp)
    80005c72:	6c8e                	ld	s9,192(sp)
    80005c74:	6d2e                	ld	s10,200(sp)
    80005c76:	6dce                	ld	s11,208(sp)
    80005c78:	6e6e                	ld	t3,216(sp)
    80005c7a:	7e8e                	ld	t4,224(sp)
    80005c7c:	7f2e                	ld	t5,232(sp)
    80005c7e:	7fce                	ld	t6,240(sp)
    80005c80:	6111                	add	sp,sp,256
    80005c82:	10200073          	sret
    80005c86:	00000013          	nop
    80005c8a:	00000013          	nop
    80005c8e:	0001                	nop

0000000080005c90 <timervec>:
    80005c90:	34051573          	csrrw	a0,mscratch,a0
    80005c94:	e10c                	sd	a1,0(a0)
    80005c96:	e510                	sd	a2,8(a0)
    80005c98:	e914                	sd	a3,16(a0)
    80005c9a:	710c                	ld	a1,32(a0)
    80005c9c:	7510                	ld	a2,40(a0)
    80005c9e:	6194                	ld	a3,0(a1)
    80005ca0:	96b2                	add	a3,a3,a2
    80005ca2:	e194                	sd	a3,0(a1)
    80005ca4:	4589                	li	a1,2
    80005ca6:	14459073          	csrw	sip,a1
    80005caa:	6914                	ld	a3,16(a0)
    80005cac:	6510                	ld	a2,8(a0)
    80005cae:	610c                	ld	a1,0(a0)
    80005cb0:	34051573          	csrrw	a0,mscratch,a0
    80005cb4:	30200073          	mret
	...

0000000080005cba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cba:	1141                	add	sp,sp,-16
    80005cbc:	e422                	sd	s0,8(sp)
    80005cbe:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cc0:	0c0007b7          	lui	a5,0xc000
    80005cc4:	4705                	li	a4,1
    80005cc6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cc8:	c3d8                	sw	a4,4(a5)
}
    80005cca:	6422                	ld	s0,8(sp)
    80005ccc:	0141                	add	sp,sp,16
    80005cce:	8082                	ret

0000000080005cd0 <plicinithart>:

void
plicinithart(void)
{
    80005cd0:	1141                	add	sp,sp,-16
    80005cd2:	e406                	sd	ra,8(sp)
    80005cd4:	e022                	sd	s0,0(sp)
    80005cd6:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005cd8:	ffffc097          	auipc	ra,0xffffc
    80005cdc:	d26080e7          	jalr	-730(ra) # 800019fe <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ce0:	0085171b          	sllw	a4,a0,0x8
    80005ce4:	0c0027b7          	lui	a5,0xc002
    80005ce8:	97ba                	add	a5,a5,a4
    80005cea:	40200713          	li	a4,1026
    80005cee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005cf2:	00d5151b          	sllw	a0,a0,0xd
    80005cf6:	0c2017b7          	lui	a5,0xc201
    80005cfa:	97aa                	add	a5,a5,a0
    80005cfc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005d00:	60a2                	ld	ra,8(sp)
    80005d02:	6402                	ld	s0,0(sp)
    80005d04:	0141                	add	sp,sp,16
    80005d06:	8082                	ret

0000000080005d08 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d08:	1141                	add	sp,sp,-16
    80005d0a:	e406                	sd	ra,8(sp)
    80005d0c:	e022                	sd	s0,0(sp)
    80005d0e:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005d10:	ffffc097          	auipc	ra,0xffffc
    80005d14:	cee080e7          	jalr	-786(ra) # 800019fe <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d18:	00d5151b          	sllw	a0,a0,0xd
    80005d1c:	0c2017b7          	lui	a5,0xc201
    80005d20:	97aa                	add	a5,a5,a0
  return irq;
}
    80005d22:	43c8                	lw	a0,4(a5)
    80005d24:	60a2                	ld	ra,8(sp)
    80005d26:	6402                	ld	s0,0(sp)
    80005d28:	0141                	add	sp,sp,16
    80005d2a:	8082                	ret

0000000080005d2c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d2c:	1101                	add	sp,sp,-32
    80005d2e:	ec06                	sd	ra,24(sp)
    80005d30:	e822                	sd	s0,16(sp)
    80005d32:	e426                	sd	s1,8(sp)
    80005d34:	1000                	add	s0,sp,32
    80005d36:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d38:	ffffc097          	auipc	ra,0xffffc
    80005d3c:	cc6080e7          	jalr	-826(ra) # 800019fe <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d40:	00d5151b          	sllw	a0,a0,0xd
    80005d44:	0c2017b7          	lui	a5,0xc201
    80005d48:	97aa                	add	a5,a5,a0
    80005d4a:	c3c4                	sw	s1,4(a5)
}
    80005d4c:	60e2                	ld	ra,24(sp)
    80005d4e:	6442                	ld	s0,16(sp)
    80005d50:	64a2                	ld	s1,8(sp)
    80005d52:	6105                	add	sp,sp,32
    80005d54:	8082                	ret

0000000080005d56 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d56:	1141                	add	sp,sp,-16
    80005d58:	e406                	sd	ra,8(sp)
    80005d5a:	e022                	sd	s0,0(sp)
    80005d5c:	0800                	add	s0,sp,16
  if(i >= NUM)
    80005d5e:	479d                	li	a5,7
    80005d60:	04a7cb63          	blt	a5,a0,80005db6 <free_desc+0x60>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005d64:	0001e717          	auipc	a4,0x1e
    80005d68:	29c70713          	add	a4,a4,668 # 80024000 <disk>
    80005d6c:	972a                	add	a4,a4,a0
    80005d6e:	6789                	lui	a5,0x2
    80005d70:	97ba                	add	a5,a5,a4
    80005d72:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d76:	eba1                	bnez	a5,80005dc6 <free_desc+0x70>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005d78:	00451713          	sll	a4,a0,0x4
    80005d7c:	00020797          	auipc	a5,0x20
    80005d80:	2847b783          	ld	a5,644(a5) # 80026000 <disk+0x2000>
    80005d84:	97ba                	add	a5,a5,a4
    80005d86:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005d8a:	0001e717          	auipc	a4,0x1e
    80005d8e:	27670713          	add	a4,a4,630 # 80024000 <disk>
    80005d92:	972a                	add	a4,a4,a0
    80005d94:	6789                	lui	a5,0x2
    80005d96:	97ba                	add	a5,a5,a4
    80005d98:	4705                	li	a4,1
    80005d9a:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d9e:	00020517          	auipc	a0,0x20
    80005da2:	27a50513          	add	a0,a0,634 # 80026018 <disk+0x2018>
    80005da6:	ffffc097          	auipc	ra,0xffffc
    80005daa:	634080e7          	jalr	1588(ra) # 800023da <wakeup>
}
    80005dae:	60a2                	ld	ra,8(sp)
    80005db0:	6402                	ld	s0,0(sp)
    80005db2:	0141                	add	sp,sp,16
    80005db4:	8082                	ret
    panic("virtio_disk_intr 1");
    80005db6:	00003517          	auipc	a0,0x3
    80005dba:	9ca50513          	add	a0,a0,-1590 # 80008780 <syscalls+0x340>
    80005dbe:	ffffa097          	auipc	ra,0xffffa
    80005dc2:	784080e7          	jalr	1924(ra) # 80000542 <panic>
    panic("virtio_disk_intr 2");
    80005dc6:	00003517          	auipc	a0,0x3
    80005dca:	9d250513          	add	a0,a0,-1582 # 80008798 <syscalls+0x358>
    80005dce:	ffffa097          	auipc	ra,0xffffa
    80005dd2:	774080e7          	jalr	1908(ra) # 80000542 <panic>

0000000080005dd6 <virtio_disk_init>:
{
    80005dd6:	1101                	add	sp,sp,-32
    80005dd8:	ec06                	sd	ra,24(sp)
    80005dda:	e822                	sd	s0,16(sp)
    80005ddc:	e426                	sd	s1,8(sp)
    80005dde:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005de0:	00003597          	auipc	a1,0x3
    80005de4:	9d058593          	add	a1,a1,-1584 # 800087b0 <syscalls+0x370>
    80005de8:	00020517          	auipc	a0,0x20
    80005dec:	2c050513          	add	a0,a0,704 # 800260a8 <disk+0x20a8>
    80005df0:	ffffb097          	auipc	ra,0xffffb
    80005df4:	de0080e7          	jalr	-544(ra) # 80000bd0 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005df8:	100017b7          	lui	a5,0x10001
    80005dfc:	4398                	lw	a4,0(a5)
    80005dfe:	2701                	sext.w	a4,a4
    80005e00:	747277b7          	lui	a5,0x74727
    80005e04:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e08:	0ef71063          	bne	a4,a5,80005ee8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e0c:	100017b7          	lui	a5,0x10001
    80005e10:	43dc                	lw	a5,4(a5)
    80005e12:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e14:	4705                	li	a4,1
    80005e16:	0ce79963          	bne	a5,a4,80005ee8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e1a:	100017b7          	lui	a5,0x10001
    80005e1e:	479c                	lw	a5,8(a5)
    80005e20:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e22:	4709                	li	a4,2
    80005e24:	0ce79263          	bne	a5,a4,80005ee8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e28:	100017b7          	lui	a5,0x10001
    80005e2c:	47d8                	lw	a4,12(a5)
    80005e2e:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e30:	554d47b7          	lui	a5,0x554d4
    80005e34:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e38:	0af71863          	bne	a4,a5,80005ee8 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e3c:	100017b7          	lui	a5,0x10001
    80005e40:	4705                	li	a4,1
    80005e42:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e44:	470d                	li	a4,3
    80005e46:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e48:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e4a:	c7ffe6b7          	lui	a3,0xc7ffe
    80005e4e:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    80005e52:	8f75                	and	a4,a4,a3
    80005e54:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e56:	472d                	li	a4,11
    80005e58:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e5a:	473d                	li	a4,15
    80005e5c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e5e:	6705                	lui	a4,0x1
    80005e60:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e62:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e66:	5bdc                	lw	a5,52(a5)
    80005e68:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e6a:	c7d9                	beqz	a5,80005ef8 <virtio_disk_init+0x122>
  if(max < NUM)
    80005e6c:	471d                	li	a4,7
    80005e6e:	08f77d63          	bgeu	a4,a5,80005f08 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e72:	100014b7          	lui	s1,0x10001
    80005e76:	47a1                	li	a5,8
    80005e78:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e7a:	6609                	lui	a2,0x2
    80005e7c:	4581                	li	a1,0
    80005e7e:	0001e517          	auipc	a0,0x1e
    80005e82:	18250513          	add	a0,a0,386 # 80024000 <disk>
    80005e86:	ffffb097          	auipc	ra,0xffffb
    80005e8a:	ed6080e7          	jalr	-298(ra) # 80000d5c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e8e:	0001e717          	auipc	a4,0x1e
    80005e92:	17270713          	add	a4,a4,370 # 80024000 <disk>
    80005e96:	00c75793          	srl	a5,a4,0xc
    80005e9a:	2781                	sext.w	a5,a5
    80005e9c:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005e9e:	00020797          	auipc	a5,0x20
    80005ea2:	16278793          	add	a5,a5,354 # 80026000 <disk+0x2000>
    80005ea6:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005ea8:	0001e717          	auipc	a4,0x1e
    80005eac:	1d870713          	add	a4,a4,472 # 80024080 <disk+0x80>
    80005eb0:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005eb2:	0001f717          	auipc	a4,0x1f
    80005eb6:	14e70713          	add	a4,a4,334 # 80025000 <disk+0x1000>
    80005eba:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005ebc:	4705                	li	a4,1
    80005ebe:	00e78c23          	sb	a4,24(a5)
    80005ec2:	00e78ca3          	sb	a4,25(a5)
    80005ec6:	00e78d23          	sb	a4,26(a5)
    80005eca:	00e78da3          	sb	a4,27(a5)
    80005ece:	00e78e23          	sb	a4,28(a5)
    80005ed2:	00e78ea3          	sb	a4,29(a5)
    80005ed6:	00e78f23          	sb	a4,30(a5)
    80005eda:	00e78fa3          	sb	a4,31(a5)
}
    80005ede:	60e2                	ld	ra,24(sp)
    80005ee0:	6442                	ld	s0,16(sp)
    80005ee2:	64a2                	ld	s1,8(sp)
    80005ee4:	6105                	add	sp,sp,32
    80005ee6:	8082                	ret
    panic("could not find virtio disk");
    80005ee8:	00003517          	auipc	a0,0x3
    80005eec:	8d850513          	add	a0,a0,-1832 # 800087c0 <syscalls+0x380>
    80005ef0:	ffffa097          	auipc	ra,0xffffa
    80005ef4:	652080e7          	jalr	1618(ra) # 80000542 <panic>
    panic("virtio disk has no queue 0");
    80005ef8:	00003517          	auipc	a0,0x3
    80005efc:	8e850513          	add	a0,a0,-1816 # 800087e0 <syscalls+0x3a0>
    80005f00:	ffffa097          	auipc	ra,0xffffa
    80005f04:	642080e7          	jalr	1602(ra) # 80000542 <panic>
    panic("virtio disk max queue too short");
    80005f08:	00003517          	auipc	a0,0x3
    80005f0c:	8f850513          	add	a0,a0,-1800 # 80008800 <syscalls+0x3c0>
    80005f10:	ffffa097          	auipc	ra,0xffffa
    80005f14:	632080e7          	jalr	1586(ra) # 80000542 <panic>

0000000080005f18 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f18:	7119                	add	sp,sp,-128
    80005f1a:	fc86                	sd	ra,120(sp)
    80005f1c:	f8a2                	sd	s0,112(sp)
    80005f1e:	f4a6                	sd	s1,104(sp)
    80005f20:	f0ca                	sd	s2,96(sp)
    80005f22:	ecce                	sd	s3,88(sp)
    80005f24:	e8d2                	sd	s4,80(sp)
    80005f26:	e4d6                	sd	s5,72(sp)
    80005f28:	e0da                	sd	s6,64(sp)
    80005f2a:	fc5e                	sd	s7,56(sp)
    80005f2c:	f862                	sd	s8,48(sp)
    80005f2e:	f466                	sd	s9,40(sp)
    80005f30:	f06a                	sd	s10,32(sp)
    80005f32:	0100                	add	s0,sp,128
    80005f34:	8a2a                	mv	s4,a0
    80005f36:	8cae                	mv	s9,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f38:	00c52c03          	lw	s8,12(a0)
    80005f3c:	001c1c1b          	sllw	s8,s8,0x1
    80005f40:	1c02                	sll	s8,s8,0x20
    80005f42:	020c5c13          	srl	s8,s8,0x20

  acquire(&disk.vdisk_lock);
    80005f46:	00020517          	auipc	a0,0x20
    80005f4a:	16250513          	add	a0,a0,354 # 800260a8 <disk+0x20a8>
    80005f4e:	ffffb097          	auipc	ra,0xffffb
    80005f52:	d12080e7          	jalr	-750(ra) # 80000c60 <acquire>
  for(int i = 0; i < 3; i++){
    80005f56:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80005f58:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f5a:	0001eb97          	auipc	s7,0x1e
    80005f5e:	0a6b8b93          	add	s7,s7,166 # 80024000 <disk>
    80005f62:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005f64:	4a8d                	li	s5,3
    80005f66:	a0b5                	j	80005fd2 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005f68:	00fb8733          	add	a4,s7,a5
    80005f6c:	975a                	add	a4,a4,s6
    80005f6e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005f72:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80005f74:	0207c563          	bltz	a5,80005f9e <virtio_disk_rw+0x86>
  for(int i = 0; i < 3; i++){
    80005f78:	2605                	addw	a2,a2,1 # 2001 <_entry-0x7fffdfff>
    80005f7a:	0591                	add	a1,a1,4
    80005f7c:	19560c63          	beq	a2,s5,80006114 <virtio_disk_rw+0x1fc>
    idx[i] = alloc_desc();
    80005f80:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80005f82:	00020717          	auipc	a4,0x20
    80005f86:	09670713          	add	a4,a4,150 # 80026018 <disk+0x2018>
    80005f8a:	87ca                	mv	a5,s2
    if(disk.free[i]){
    80005f8c:	00074683          	lbu	a3,0(a4)
    80005f90:	fee1                	bnez	a3,80005f68 <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    80005f92:	2785                	addw	a5,a5,1
    80005f94:	0705                	add	a4,a4,1
    80005f96:	fe979be3          	bne	a5,s1,80005f8c <virtio_disk_rw+0x74>
    idx[i] = alloc_desc();
    80005f9a:	57fd                	li	a5,-1
    80005f9c:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    80005f9e:	00c05e63          	blez	a2,80005fba <virtio_disk_rw+0xa2>
    80005fa2:	060a                	sll	a2,a2,0x2
    80005fa4:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80005fa8:	0009a503          	lw	a0,0(s3)
    80005fac:	00000097          	auipc	ra,0x0
    80005fb0:	daa080e7          	jalr	-598(ra) # 80005d56 <free_desc>
      for(int j = 0; j < i; j++)
    80005fb4:	0991                	add	s3,s3,4
    80005fb6:	ffa999e3          	bne	s3,s10,80005fa8 <virtio_disk_rw+0x90>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fba:	00020597          	auipc	a1,0x20
    80005fbe:	0ee58593          	add	a1,a1,238 # 800260a8 <disk+0x20a8>
    80005fc2:	00020517          	auipc	a0,0x20
    80005fc6:	05650513          	add	a0,a0,86 # 80026018 <disk+0x2018>
    80005fca:	ffffc097          	auipc	ra,0xffffc
    80005fce:	290080e7          	jalr	656(ra) # 8000225a <sleep>
  for(int i = 0; i < 3; i++){
    80005fd2:	f9040993          	add	s3,s0,-112
{
    80005fd6:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80005fd8:	864a                	mv	a2,s2
    80005fda:	b75d                	j	80005f80 <virtio_disk_rw+0x68>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005fdc:	00020717          	auipc	a4,0x20
    80005fe0:	02473703          	ld	a4,36(a4) # 80026000 <disk+0x2000>
    80005fe4:	973e                	add	a4,a4,a5
    80005fe6:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005fea:	0001e517          	auipc	a0,0x1e
    80005fee:	01650513          	add	a0,a0,22 # 80024000 <disk>
    80005ff2:	00020717          	auipc	a4,0x20
    80005ff6:	00e70713          	add	a4,a4,14 # 80026000 <disk+0x2000>
    80005ffa:	6314                	ld	a3,0(a4)
    80005ffc:	96be                	add	a3,a3,a5
    80005ffe:	00c6d603          	lhu	a2,12(a3)
    80006002:	00166613          	or	a2,a2,1
    80006006:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000600a:	f9842683          	lw	a3,-104(s0)
    8000600e:	6310                	ld	a2,0(a4)
    80006010:	97b2                	add	a5,a5,a2
    80006012:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    80006016:	20048613          	add	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    8000601a:	0612                	sll	a2,a2,0x4
    8000601c:	962a                	add	a2,a2,a0
    8000601e:	02060823          	sb	zero,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006022:	00469793          	sll	a5,a3,0x4
    80006026:	630c                	ld	a1,0(a4)
    80006028:	95be                	add	a1,a1,a5
    8000602a:	6689                	lui	a3,0x2
    8000602c:	03068693          	add	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80006030:	96ca                	add	a3,a3,s2
    80006032:	96aa                	add	a3,a3,a0
    80006034:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    80006036:	6314                	ld	a3,0(a4)
    80006038:	96be                	add	a3,a3,a5
    8000603a:	4585                	li	a1,1
    8000603c:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000603e:	6314                	ld	a3,0(a4)
    80006040:	96be                	add	a3,a3,a5
    80006042:	4509                	li	a0,2
    80006044:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    80006048:	6314                	ld	a3,0(a4)
    8000604a:	97b6                	add	a5,a5,a3
    8000604c:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006050:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006054:	03463423          	sd	s4,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    80006058:	6714                	ld	a3,8(a4)
    8000605a:	0026d783          	lhu	a5,2(a3)
    8000605e:	8b9d                	and	a5,a5,7
    80006060:	0789                	add	a5,a5,2
    80006062:	0786                	sll	a5,a5,0x1
    80006064:	96be                	add	a3,a3,a5
    80006066:	00969023          	sh	s1,0(a3)
  __sync_synchronize();
    8000606a:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    8000606e:	6718                	ld	a4,8(a4)
    80006070:	00275783          	lhu	a5,2(a4)
    80006074:	2785                	addw	a5,a5,1
    80006076:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000607a:	100017b7          	lui	a5,0x10001
    8000607e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006082:	004a2783          	lw	a5,4(s4)
    80006086:	02b79163          	bne	a5,a1,800060a8 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000608a:	00020917          	auipc	s2,0x20
    8000608e:	01e90913          	add	s2,s2,30 # 800260a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006092:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006094:	85ca                	mv	a1,s2
    80006096:	8552                	mv	a0,s4
    80006098:	ffffc097          	auipc	ra,0xffffc
    8000609c:	1c2080e7          	jalr	450(ra) # 8000225a <sleep>
  while(b->disk == 1) {
    800060a0:	004a2783          	lw	a5,4(s4)
    800060a4:	fe9788e3          	beq	a5,s1,80006094 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800060a8:	f9042483          	lw	s1,-112(s0)
    800060ac:	20048713          	add	a4,s1,512
    800060b0:	0712                	sll	a4,a4,0x4
    800060b2:	0001e797          	auipc	a5,0x1e
    800060b6:	f4e78793          	add	a5,a5,-178 # 80024000 <disk>
    800060ba:	97ba                	add	a5,a5,a4
    800060bc:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800060c0:	00020917          	auipc	s2,0x20
    800060c4:	f4090913          	add	s2,s2,-192 # 80026000 <disk+0x2000>
    800060c8:	a019                	j	800060ce <virtio_disk_rw+0x1b6>
      i = disk.desc[i].next;
    800060ca:	00e7d483          	lhu	s1,14(a5)
    free_desc(i);
    800060ce:	8526                	mv	a0,s1
    800060d0:	00000097          	auipc	ra,0x0
    800060d4:	c86080e7          	jalr	-890(ra) # 80005d56 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800060d8:	0492                	sll	s1,s1,0x4
    800060da:	00093783          	ld	a5,0(s2)
    800060de:	97a6                	add	a5,a5,s1
    800060e0:	00c7d703          	lhu	a4,12(a5)
    800060e4:	8b05                	and	a4,a4,1
    800060e6:	f375                	bnez	a4,800060ca <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800060e8:	00020517          	auipc	a0,0x20
    800060ec:	fc050513          	add	a0,a0,-64 # 800260a8 <disk+0x20a8>
    800060f0:	ffffb097          	auipc	ra,0xffffb
    800060f4:	c24080e7          	jalr	-988(ra) # 80000d14 <release>
}
    800060f8:	70e6                	ld	ra,120(sp)
    800060fa:	7446                	ld	s0,112(sp)
    800060fc:	74a6                	ld	s1,104(sp)
    800060fe:	7906                	ld	s2,96(sp)
    80006100:	69e6                	ld	s3,88(sp)
    80006102:	6a46                	ld	s4,80(sp)
    80006104:	6aa6                	ld	s5,72(sp)
    80006106:	6b06                	ld	s6,64(sp)
    80006108:	7be2                	ld	s7,56(sp)
    8000610a:	7c42                	ld	s8,48(sp)
    8000610c:	7ca2                	ld	s9,40(sp)
    8000610e:	7d02                	ld	s10,32(sp)
    80006110:	6109                	add	sp,sp,128
    80006112:	8082                	ret
  if(write)
    80006114:	019037b3          	snez	a5,s9
    80006118:	f8f42023          	sw	a5,-128(s0)
  buf0.reserved = 0;
    8000611c:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006120:	f9843423          	sd	s8,-120(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006124:	f9042483          	lw	s1,-112(s0)
    80006128:	00449913          	sll	s2,s1,0x4
    8000612c:	00020997          	auipc	s3,0x20
    80006130:	ed498993          	add	s3,s3,-300 # 80026000 <disk+0x2000>
    80006134:	0009ba83          	ld	s5,0(s3)
    80006138:	9aca                	add	s5,s5,s2
    8000613a:	f8040513          	add	a0,s0,-128
    8000613e:	ffffb097          	auipc	ra,0xffffb
    80006142:	fec080e7          	jalr	-20(ra) # 8000112a <kvmpa>
    80006146:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000614a:	0009b783          	ld	a5,0(s3)
    8000614e:	97ca                	add	a5,a5,s2
    80006150:	4741                	li	a4,16
    80006152:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006154:	0009b783          	ld	a5,0(s3)
    80006158:	97ca                	add	a5,a5,s2
    8000615a:	4705                	li	a4,1
    8000615c:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006160:	f9442783          	lw	a5,-108(s0)
    80006164:	0009b703          	ld	a4,0(s3)
    80006168:	974a                	add	a4,a4,s2
    8000616a:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000616e:	0792                	sll	a5,a5,0x4
    80006170:	0009b703          	ld	a4,0(s3)
    80006174:	973e                	add	a4,a4,a5
    80006176:	058a0693          	add	a3,s4,88
    8000617a:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    8000617c:	0009b703          	ld	a4,0(s3)
    80006180:	973e                	add	a4,a4,a5
    80006182:	40000693          	li	a3,1024
    80006186:	c714                	sw	a3,8(a4)
  if(write)
    80006188:	e40c9ae3          	bnez	s9,80005fdc <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000618c:	00020717          	auipc	a4,0x20
    80006190:	e7473703          	ld	a4,-396(a4) # 80026000 <disk+0x2000>
    80006194:	973e                	add	a4,a4,a5
    80006196:	4689                	li	a3,2
    80006198:	00d71623          	sh	a3,12(a4)
    8000619c:	b5b9                	j	80005fea <virtio_disk_rw+0xd2>

000000008000619e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000619e:	1101                	add	sp,sp,-32
    800061a0:	ec06                	sd	ra,24(sp)
    800061a2:	e822                	sd	s0,16(sp)
    800061a4:	e426                	sd	s1,8(sp)
    800061a6:	e04a                	sd	s2,0(sp)
    800061a8:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061aa:	00020517          	auipc	a0,0x20
    800061ae:	efe50513          	add	a0,a0,-258 # 800260a8 <disk+0x20a8>
    800061b2:	ffffb097          	auipc	ra,0xffffb
    800061b6:	aae080e7          	jalr	-1362(ra) # 80000c60 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800061ba:	00020717          	auipc	a4,0x20
    800061be:	e4670713          	add	a4,a4,-442 # 80026000 <disk+0x2000>
    800061c2:	02075783          	lhu	a5,32(a4)
    800061c6:	6b18                	ld	a4,16(a4)
    800061c8:	00275683          	lhu	a3,2(a4)
    800061cc:	8ebd                	xor	a3,a3,a5
    800061ce:	8a9d                	and	a3,a3,7
    800061d0:	cab9                	beqz	a3,80006226 <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800061d2:	0001e917          	auipc	s2,0x1e
    800061d6:	e2e90913          	add	s2,s2,-466 # 80024000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800061da:	00020497          	auipc	s1,0x20
    800061de:	e2648493          	add	s1,s1,-474 # 80026000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800061e2:	078e                	sll	a5,a5,0x3
    800061e4:	973e                	add	a4,a4,a5
    800061e6:	435c                	lw	a5,4(a4)
    if(disk.info[id].status != 0)
    800061e8:	20078713          	add	a4,a5,512
    800061ec:	0712                	sll	a4,a4,0x4
    800061ee:	974a                	add	a4,a4,s2
    800061f0:	03074703          	lbu	a4,48(a4)
    800061f4:	ef21                	bnez	a4,8000624c <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800061f6:	20078793          	add	a5,a5,512
    800061fa:	0792                	sll	a5,a5,0x4
    800061fc:	97ca                	add	a5,a5,s2
    800061fe:	7798                	ld	a4,40(a5)
    80006200:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    80006204:	7788                	ld	a0,40(a5)
    80006206:	ffffc097          	auipc	ra,0xffffc
    8000620a:	1d4080e7          	jalr	468(ra) # 800023da <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    8000620e:	0204d783          	lhu	a5,32(s1)
    80006212:	2785                	addw	a5,a5,1
    80006214:	8b9d                	and	a5,a5,7
    80006216:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    8000621a:	6898                	ld	a4,16(s1)
    8000621c:	00275683          	lhu	a3,2(a4)
    80006220:	8a9d                	and	a3,a3,7
    80006222:	fcf690e3          	bne	a3,a5,800061e2 <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006226:	10001737          	lui	a4,0x10001
    8000622a:	533c                	lw	a5,96(a4)
    8000622c:	8b8d                	and	a5,a5,3
    8000622e:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006230:	00020517          	auipc	a0,0x20
    80006234:	e7850513          	add	a0,a0,-392 # 800260a8 <disk+0x20a8>
    80006238:	ffffb097          	auipc	ra,0xffffb
    8000623c:	adc080e7          	jalr	-1316(ra) # 80000d14 <release>
}
    80006240:	60e2                	ld	ra,24(sp)
    80006242:	6442                	ld	s0,16(sp)
    80006244:	64a2                	ld	s1,8(sp)
    80006246:	6902                	ld	s2,0(sp)
    80006248:	6105                	add	sp,sp,32
    8000624a:	8082                	ret
      panic("virtio_disk_intr status");
    8000624c:	00002517          	auipc	a0,0x2
    80006250:	5d450513          	add	a0,a0,1492 # 80008820 <syscalls+0x3e0>
    80006254:	ffffa097          	auipc	ra,0xffffa
    80006258:	2ee080e7          	jalr	750(ra) # 80000542 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
