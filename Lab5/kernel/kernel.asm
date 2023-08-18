
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
    80000060:	cf478793          	add	a5,a5,-780 # 80005d50 <timervec>
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
    80000094:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	dfe78793          	add	a5,a5,-514 # 80000ea4 <main>
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
    80000110:	af0080e7          	jalr	-1296(ra) # 80000bfc <acquire>
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
    8000012a:	498080e7          	jalr	1176(ra) # 800025be <either_copyin>
    8000012e:	01550d63          	beq	a0,s5,80000148 <consolewrite+0x5c>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	796080e7          	jalr	1942(ra) # 800008cc <uartputc>
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
    80000154:	b60080e7          	jalr	-1184(ra) # 80000cb0 <release>

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
    8000019c:	a64080e7          	jalr	-1436(ra) # 80000bfc <acquire>
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
    800001c4:	938080e7          	jalr	-1736(ra) # 80001af8 <myproc>
    800001c8:	591c                	lw	a5,48(a0)
    800001ca:	efad                	bnez	a5,80000244 <consoleread+0xd4>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	13e080e7          	jalr	318(ra) # 8000230e <sleep>
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
    8000021a:	352080e7          	jalr	850(ra) # 80002568 <either_copyout>
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
    8000023a:	a7a080e7          	jalr	-1414(ra) # 80000cb0 <release>

  return target - n;
    8000023e:	413b053b          	subw	a0,s6,s3
    80000242:	a811                	j	80000256 <consoleread+0xe6>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	add	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	a64080e7          	jalr	-1436(ra) # 80000cb0 <release>
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
    80000292:	560080e7          	jalr	1376(ra) # 800007ee <uartputc_sync>
}
    80000296:	60a2                	ld	ra,8(sp)
    80000298:	6402                	ld	s0,0(sp)
    8000029a:	0141                	add	sp,sp,16
    8000029c:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	54e080e7          	jalr	1358(ra) # 800007ee <uartputc_sync>
    800002a8:	02000513          	li	a0,32
    800002ac:	00000097          	auipc	ra,0x0
    800002b0:	542080e7          	jalr	1346(ra) # 800007ee <uartputc_sync>
    800002b4:	4521                	li	a0,8
    800002b6:	00000097          	auipc	ra,0x0
    800002ba:	538080e7          	jalr	1336(ra) # 800007ee <uartputc_sync>
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
    800002da:	926080e7          	jalr	-1754(ra) # 80000bfc <acquire>

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
    800002f8:	320080e7          	jalr	800(ra) # 80002614 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fc:	00011517          	auipc	a0,0x11
    80000300:	53450513          	add	a0,a0,1332 # 80011830 <cons>
    80000304:	00001097          	auipc	ra,0x1
    80000308:	9ac080e7          	jalr	-1620(ra) # 80000cb0 <release>
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
    8000044c:	046080e7          	jalr	70(ra) # 8000248e <wakeup>
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
    8000046e:	702080e7          	jalr	1794(ra) # 80000b6c <initlock>

  uartinit();
    80000472:	00000097          	auipc	ra,0x0
    80000476:	32c080e7          	jalr	812(ra) # 8000079e <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047a:	00021797          	auipc	a5,0x21
    8000047e:	53678793          	add	a5,a5,1334 # 800219b0 <devsw>
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

static char digits[] = "0123456789abcdef";

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
    800004c0:	b8460613          	add	a2,a2,-1148 # 80008040 <digits>
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
    80000562:	02e080e7          	jalr	46(ra) # 8000058c <printf>
  printf(s);
    80000566:	8526                	mv	a0,s1
    80000568:	00000097          	auipc	ra,0x0
    8000056c:	024080e7          	jalr	36(ra) # 8000058c <printf>
  printf("\n");
    80000570:	00008517          	auipc	a0,0x8
    80000574:	b5850513          	add	a0,a0,-1192 # 800080c8 <digits+0x88>
    80000578:	00000097          	auipc	ra,0x0
    8000057c:	014080e7          	jalr	20(ra) # 8000058c <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000580:	4785                	li	a5,1
    80000582:	00009717          	auipc	a4,0x9
    80000586:	a6f72f23          	sw	a5,-1410(a4) # 80009000 <panicked>
  for(;;)
    8000058a:	a001                	j	8000058a <panic+0x48>

000000008000058c <printf>:
{
    8000058c:	7131                	add	sp,sp,-192
    8000058e:	fc86                	sd	ra,120(sp)
    80000590:	f8a2                	sd	s0,112(sp)
    80000592:	f4a6                	sd	s1,104(sp)
    80000594:	f0ca                	sd	s2,96(sp)
    80000596:	ecce                	sd	s3,88(sp)
    80000598:	e8d2                	sd	s4,80(sp)
    8000059a:	e4d6                	sd	s5,72(sp)
    8000059c:	e0da                	sd	s6,64(sp)
    8000059e:	fc5e                	sd	s7,56(sp)
    800005a0:	f862                	sd	s8,48(sp)
    800005a2:	f466                	sd	s9,40(sp)
    800005a4:	f06a                	sd	s10,32(sp)
    800005a6:	ec6e                	sd	s11,24(sp)
    800005a8:	0100                	add	s0,sp,128
    800005aa:	8a2a                	mv	s4,a0
    800005ac:	e40c                	sd	a1,8(s0)
    800005ae:	e810                	sd	a2,16(s0)
    800005b0:	ec14                	sd	a3,24(s0)
    800005b2:	f018                	sd	a4,32(s0)
    800005b4:	f41c                	sd	a5,40(s0)
    800005b6:	03043823          	sd	a6,48(s0)
    800005ba:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005be:	00011d97          	auipc	s11,0x11
    800005c2:	332dad83          	lw	s11,818(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005c6:	020d9b63          	bnez	s11,800005fc <printf+0x70>
  if (fmt == 0)
    800005ca:	040a0263          	beqz	s4,8000060e <printf+0x82>
  va_start(ap, fmt);
    800005ce:	00840793          	add	a5,s0,8
    800005d2:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d6:	000a4503          	lbu	a0,0(s4)
    800005da:	14050f63          	beqz	a0,80000738 <printf+0x1ac>
    800005de:	4981                	li	s3,0
    if(c != '%'){
    800005e0:	02500a93          	li	s5,37
    switch(c){
    800005e4:	07000b93          	li	s7,112
  consputc('x');
    800005e8:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ea:	00008b17          	auipc	s6,0x8
    800005ee:	a56b0b13          	add	s6,s6,-1450 # 80008040 <digits>
    switch(c){
    800005f2:	07300c93          	li	s9,115
    800005f6:	06400c13          	li	s8,100
    800005fa:	a82d                	j	80000634 <printf+0xa8>
    acquire(&pr.lock);
    800005fc:	00011517          	auipc	a0,0x11
    80000600:	2dc50513          	add	a0,a0,732 # 800118d8 <pr>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	5f8080e7          	jalr	1528(ra) # 80000bfc <acquire>
    8000060c:	bf7d                	j	800005ca <printf+0x3e>
    panic("null fmt");
    8000060e:	00008517          	auipc	a0,0x8
    80000612:	a1a50513          	add	a0,a0,-1510 # 80008028 <etext+0x28>
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	f2c080e7          	jalr	-212(ra) # 80000542 <panic>
      consputc(c);
    8000061e:	00000097          	auipc	ra,0x0
    80000622:	c60080e7          	jalr	-928(ra) # 8000027e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000626:	2985                	addw	s3,s3,1
    80000628:	013a07b3          	add	a5,s4,s3
    8000062c:	0007c503          	lbu	a0,0(a5)
    80000630:	10050463          	beqz	a0,80000738 <printf+0x1ac>
    if(c != '%'){
    80000634:	ff5515e3          	bne	a0,s5,8000061e <printf+0x92>
    c = fmt[++i] & 0xff;
    80000638:	2985                	addw	s3,s3,1
    8000063a:	013a07b3          	add	a5,s4,s3
    8000063e:	0007c783          	lbu	a5,0(a5)
    80000642:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000646:	cbed                	beqz	a5,80000738 <printf+0x1ac>
    switch(c){
    80000648:	05778a63          	beq	a5,s7,8000069c <printf+0x110>
    8000064c:	02fbf663          	bgeu	s7,a5,80000678 <printf+0xec>
    80000650:	09978863          	beq	a5,s9,800006e0 <printf+0x154>
    80000654:	07800713          	li	a4,120
    80000658:	0ce79563          	bne	a5,a4,80000722 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065c:	f8843783          	ld	a5,-120(s0)
    80000660:	00878713          	add	a4,a5,8
    80000664:	f8e43423          	sd	a4,-120(s0)
    80000668:	4605                	li	a2,1
    8000066a:	85ea                	mv	a1,s10
    8000066c:	4388                	lw	a0,0(a5)
    8000066e:	00000097          	auipc	ra,0x0
    80000672:	e30080e7          	jalr	-464(ra) # 8000049e <printint>
      break;
    80000676:	bf45                	j	80000626 <printf+0x9a>
    switch(c){
    80000678:	09578f63          	beq	a5,s5,80000716 <printf+0x18a>
    8000067c:	0b879363          	bne	a5,s8,80000722 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000680:	f8843783          	ld	a5,-120(s0)
    80000684:	00878713          	add	a4,a5,8
    80000688:	f8e43423          	sd	a4,-120(s0)
    8000068c:	4605                	li	a2,1
    8000068e:	45a9                	li	a1,10
    80000690:	4388                	lw	a0,0(a5)
    80000692:	00000097          	auipc	ra,0x0
    80000696:	e0c080e7          	jalr	-500(ra) # 8000049e <printint>
      break;
    8000069a:	b771                	j	80000626 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069c:	f8843783          	ld	a5,-120(s0)
    800006a0:	00878713          	add	a4,a5,8
    800006a4:	f8e43423          	sd	a4,-120(s0)
    800006a8:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006ac:	03000513          	li	a0,48
    800006b0:	00000097          	auipc	ra,0x0
    800006b4:	bce080e7          	jalr	-1074(ra) # 8000027e <consputc>
  consputc('x');
    800006b8:	07800513          	li	a0,120
    800006bc:	00000097          	auipc	ra,0x0
    800006c0:	bc2080e7          	jalr	-1086(ra) # 8000027e <consputc>
    800006c4:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c6:	03c95793          	srl	a5,s2,0x3c
    800006ca:	97da                	add	a5,a5,s6
    800006cc:	0007c503          	lbu	a0,0(a5)
    800006d0:	00000097          	auipc	ra,0x0
    800006d4:	bae080e7          	jalr	-1106(ra) # 8000027e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d8:	0912                	sll	s2,s2,0x4
    800006da:	34fd                	addw	s1,s1,-1
    800006dc:	f4ed                	bnez	s1,800006c6 <printf+0x13a>
    800006de:	b7a1                	j	80000626 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e0:	f8843783          	ld	a5,-120(s0)
    800006e4:	00878713          	add	a4,a5,8
    800006e8:	f8e43423          	sd	a4,-120(s0)
    800006ec:	6384                	ld	s1,0(a5)
    800006ee:	cc89                	beqz	s1,80000708 <printf+0x17c>
      for(; *s; s++)
    800006f0:	0004c503          	lbu	a0,0(s1)
    800006f4:	d90d                	beqz	a0,80000626 <printf+0x9a>
        consputc(*s);
    800006f6:	00000097          	auipc	ra,0x0
    800006fa:	b88080e7          	jalr	-1144(ra) # 8000027e <consputc>
      for(; *s; s++)
    800006fe:	0485                	add	s1,s1,1
    80000700:	0004c503          	lbu	a0,0(s1)
    80000704:	f96d                	bnez	a0,800006f6 <printf+0x16a>
    80000706:	b705                	j	80000626 <printf+0x9a>
        s = "(null)";
    80000708:	00008497          	auipc	s1,0x8
    8000070c:	91848493          	add	s1,s1,-1768 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000710:	02800513          	li	a0,40
    80000714:	b7cd                	j	800006f6 <printf+0x16a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b66080e7          	jalr	-1178(ra) # 8000027e <consputc>
      break;
    80000720:	b719                	j	80000626 <printf+0x9a>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b5a080e7          	jalr	-1190(ra) # 8000027e <consputc>
      consputc(c);
    8000072c:	8526                	mv	a0,s1
    8000072e:	00000097          	auipc	ra,0x0
    80000732:	b50080e7          	jalr	-1200(ra) # 8000027e <consputc>
      break;
    80000736:	bdc5                	j	80000626 <printf+0x9a>
  if(locking)
    80000738:	020d9163          	bnez	s11,8000075a <printf+0x1ce>
}
    8000073c:	70e6                	ld	ra,120(sp)
    8000073e:	7446                	ld	s0,112(sp)
    80000740:	74a6                	ld	s1,104(sp)
    80000742:	7906                	ld	s2,96(sp)
    80000744:	69e6                	ld	s3,88(sp)
    80000746:	6a46                	ld	s4,80(sp)
    80000748:	6aa6                	ld	s5,72(sp)
    8000074a:	6b06                	ld	s6,64(sp)
    8000074c:	7be2                	ld	s7,56(sp)
    8000074e:	7c42                	ld	s8,48(sp)
    80000750:	7ca2                	ld	s9,40(sp)
    80000752:	7d02                	ld	s10,32(sp)
    80000754:	6de2                	ld	s11,24(sp)
    80000756:	6129                	add	sp,sp,192
    80000758:	8082                	ret
    release(&pr.lock);
    8000075a:	00011517          	auipc	a0,0x11
    8000075e:	17e50513          	add	a0,a0,382 # 800118d8 <pr>
    80000762:	00000097          	auipc	ra,0x0
    80000766:	54e080e7          	jalr	1358(ra) # 80000cb0 <release>
}
    8000076a:	bfc9                	j	8000073c <printf+0x1b0>

000000008000076c <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076c:	1101                	add	sp,sp,-32
    8000076e:	ec06                	sd	ra,24(sp)
    80000770:	e822                	sd	s0,16(sp)
    80000772:	e426                	sd	s1,8(sp)
    80000774:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    80000776:	00011497          	auipc	s1,0x11
    8000077a:	16248493          	add	s1,s1,354 # 800118d8 <pr>
    8000077e:	00008597          	auipc	a1,0x8
    80000782:	8ba58593          	add	a1,a1,-1862 # 80008038 <etext+0x38>
    80000786:	8526                	mv	a0,s1
    80000788:	00000097          	auipc	ra,0x0
    8000078c:	3e4080e7          	jalr	996(ra) # 80000b6c <initlock>
  pr.locking = 1;
    80000790:	4785                	li	a5,1
    80000792:	cc9c                	sw	a5,24(s1)
}
    80000794:	60e2                	ld	ra,24(sp)
    80000796:	6442                	ld	s0,16(sp)
    80000798:	64a2                	ld	s1,8(sp)
    8000079a:	6105                	add	sp,sp,32
    8000079c:	8082                	ret

000000008000079e <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079e:	1141                	add	sp,sp,-16
    800007a0:	e406                	sd	ra,8(sp)
    800007a2:	e022                	sd	s0,0(sp)
    800007a4:	0800                	add	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a6:	100007b7          	lui	a5,0x10000
    800007aa:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ae:	f8000713          	li	a4,-128
    800007b2:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b6:	470d                	li	a4,3
    800007b8:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007bc:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c0:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c4:	469d                	li	a3,7
    800007c6:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007ca:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ce:	00008597          	auipc	a1,0x8
    800007d2:	88a58593          	add	a1,a1,-1910 # 80008058 <digits+0x18>
    800007d6:	00011517          	auipc	a0,0x11
    800007da:	12250513          	add	a0,a0,290 # 800118f8 <uart_tx_lock>
    800007de:	00000097          	auipc	ra,0x0
    800007e2:	38e080e7          	jalr	910(ra) # 80000b6c <initlock>
}
    800007e6:	60a2                	ld	ra,8(sp)
    800007e8:	6402                	ld	s0,0(sp)
    800007ea:	0141                	add	sp,sp,16
    800007ec:	8082                	ret

00000000800007ee <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ee:	1101                	add	sp,sp,-32
    800007f0:	ec06                	sd	ra,24(sp)
    800007f2:	e822                	sd	s0,16(sp)
    800007f4:	e426                	sd	s1,8(sp)
    800007f6:	1000                	add	s0,sp,32
    800007f8:	84aa                	mv	s1,a0
  push_off();
    800007fa:	00000097          	auipc	ra,0x0
    800007fe:	3b6080e7          	jalr	950(ra) # 80000bb0 <push_off>

  if(panicked){
    80000802:	00008797          	auipc	a5,0x8
    80000806:	7fe7a783          	lw	a5,2046(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080e:	c391                	beqz	a5,80000812 <uartputc_sync+0x24>
    for(;;)
    80000810:	a001                	j	80000810 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000816:	0207f793          	and	a5,a5,32
    8000081a:	dfe5                	beqz	a5,80000812 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081c:	0ff4f513          	zext.b	a0,s1
    80000820:	100007b7          	lui	a5,0x10000
    80000824:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000828:	00000097          	auipc	ra,0x0
    8000082c:	428080e7          	jalr	1064(ra) # 80000c50 <pop_off>
}
    80000830:	60e2                	ld	ra,24(sp)
    80000832:	6442                	ld	s0,16(sp)
    80000834:	64a2                	ld	s1,8(sp)
    80000836:	6105                	add	sp,sp,32
    80000838:	8082                	ret

000000008000083a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7ca7a783          	lw	a5,1994(a5) # 80009004 <uart_tx_r>
    80000842:	00008717          	auipc	a4,0x8
    80000846:	7c672703          	lw	a4,1990(a4) # 80009008 <uart_tx_w>
    8000084a:	08f70063          	beq	a4,a5,800008ca <uartstart+0x90>
{
    8000084e:	7139                	add	sp,sp,-64
    80000850:	fc06                	sd	ra,56(sp)
    80000852:	f822                	sd	s0,48(sp)
    80000854:	f426                	sd	s1,40(sp)
    80000856:	f04a                	sd	s2,32(sp)
    80000858:	ec4e                	sd	s3,24(sp)
    8000085a:	e852                	sd	s4,16(sp)
    8000085c:	e456                	sd	s5,8(sp)
    8000085e:	0080                	add	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000860:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000864:	00011a97          	auipc	s5,0x11
    80000868:	094a8a93          	add	s5,s5,148 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000086c:	00008497          	auipc	s1,0x8
    80000870:	79848493          	add	s1,s1,1944 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000874:	00008a17          	auipc	s4,0x8
    80000878:	794a0a13          	add	s4,s4,1940 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000880:	02077713          	and	a4,a4,32
    80000884:	cb15                	beqz	a4,800008b8 <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    80000886:	00fa8733          	add	a4,s5,a5
    8000088a:	01874983          	lbu	s3,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000088e:	2785                	addw	a5,a5,1
    80000890:	41f7d71b          	sraw	a4,a5,0x1f
    80000894:	01b7571b          	srlw	a4,a4,0x1b
    80000898:	9fb9                	addw	a5,a5,a4
    8000089a:	8bfd                	and	a5,a5,31
    8000089c:	9f99                	subw	a5,a5,a4
    8000089e:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a0:	8526                	mv	a0,s1
    800008a2:	00002097          	auipc	ra,0x2
    800008a6:	bec080e7          	jalr	-1044(ra) # 8000248e <wakeup>
    
    WriteReg(THR, c);
    800008aa:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ae:	409c                	lw	a5,0(s1)
    800008b0:	000a2703          	lw	a4,0(s4)
    800008b4:	fcf714e3          	bne	a4,a5,8000087c <uartstart+0x42>
  }
}
    800008b8:	70e2                	ld	ra,56(sp)
    800008ba:	7442                	ld	s0,48(sp)
    800008bc:	74a2                	ld	s1,40(sp)
    800008be:	7902                	ld	s2,32(sp)
    800008c0:	69e2                	ld	s3,24(sp)
    800008c2:	6a42                	ld	s4,16(sp)
    800008c4:	6aa2                	ld	s5,8(sp)
    800008c6:	6121                	add	sp,sp,64
    800008c8:	8082                	ret
    800008ca:	8082                	ret

00000000800008cc <uartputc>:
{
    800008cc:	7179                	add	sp,sp,-48
    800008ce:	f406                	sd	ra,40(sp)
    800008d0:	f022                	sd	s0,32(sp)
    800008d2:	ec26                	sd	s1,24(sp)
    800008d4:	e84a                	sd	s2,16(sp)
    800008d6:	e44e                	sd	s3,8(sp)
    800008d8:	e052                	sd	s4,0(sp)
    800008da:	1800                	add	s0,sp,48
    800008dc:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    800008de:	00011517          	auipc	a0,0x11
    800008e2:	01a50513          	add	a0,a0,26 # 800118f8 <uart_tx_lock>
    800008e6:	00000097          	auipc	ra,0x0
    800008ea:	316080e7          	jalr	790(ra) # 80000bfc <acquire>
  if(panicked){
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	7127a783          	lw	a5,1810(a5) # 80009000 <panicked>
    800008f6:	c391                	beqz	a5,800008fa <uartputc+0x2e>
    for(;;)
    800008f8:	a001                	j	800008f8 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800008fa:	00008697          	auipc	a3,0x8
    800008fe:	70e6a683          	lw	a3,1806(a3) # 80009008 <uart_tx_w>
    80000902:	0016879b          	addw	a5,a3,1
    80000906:	41f7d71b          	sraw	a4,a5,0x1f
    8000090a:	01b7571b          	srlw	a4,a4,0x1b
    8000090e:	9fb9                	addw	a5,a5,a4
    80000910:	8bfd                	and	a5,a5,31
    80000912:	9f99                	subw	a5,a5,a4
    80000914:	00008717          	auipc	a4,0x8
    80000918:	6f072703          	lw	a4,1776(a4) # 80009004 <uart_tx_r>
    8000091c:	04f71363          	bne	a4,a5,80000962 <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000920:	00011a17          	auipc	s4,0x11
    80000924:	fd8a0a13          	add	s4,s4,-40 # 800118f8 <uart_tx_lock>
    80000928:	00008917          	auipc	s2,0x8
    8000092c:	6dc90913          	add	s2,s2,1756 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000930:	00008997          	auipc	s3,0x8
    80000934:	6d898993          	add	s3,s3,1752 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000938:	85d2                	mv	a1,s4
    8000093a:	854a                	mv	a0,s2
    8000093c:	00002097          	auipc	ra,0x2
    80000940:	9d2080e7          	jalr	-1582(ra) # 8000230e <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	0009a683          	lw	a3,0(s3)
    80000948:	0016879b          	addw	a5,a3,1
    8000094c:	41f7d71b          	sraw	a4,a5,0x1f
    80000950:	01b7571b          	srlw	a4,a4,0x1b
    80000954:	9fb9                	addw	a5,a5,a4
    80000956:	8bfd                	and	a5,a5,31
    80000958:	9f99                	subw	a5,a5,a4
    8000095a:	00092703          	lw	a4,0(s2)
    8000095e:	fcf70de3          	beq	a4,a5,80000938 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000962:	00011917          	auipc	s2,0x11
    80000966:	f9690913          	add	s2,s2,-106 # 800118f8 <uart_tx_lock>
    8000096a:	96ca                	add	a3,a3,s2
    8000096c:	00968c23          	sb	s1,24(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000970:	00008717          	auipc	a4,0x8
    80000974:	68f72c23          	sw	a5,1688(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000978:	00000097          	auipc	ra,0x0
    8000097c:	ec2080e7          	jalr	-318(ra) # 8000083a <uartstart>
      release(&uart_tx_lock);
    80000980:	854a                	mv	a0,s2
    80000982:	00000097          	auipc	ra,0x0
    80000986:	32e080e7          	jalr	814(ra) # 80000cb0 <release>
}
    8000098a:	70a2                	ld	ra,40(sp)
    8000098c:	7402                	ld	s0,32(sp)
    8000098e:	64e2                	ld	s1,24(sp)
    80000990:	6942                	ld	s2,16(sp)
    80000992:	69a2                	ld	s3,8(sp)
    80000994:	6a02                	ld	s4,0(sp)
    80000996:	6145                	add	sp,sp,48
    80000998:	8082                	ret

000000008000099a <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000099a:	1141                	add	sp,sp,-16
    8000099c:	e422                	sd	s0,8(sp)
    8000099e:	0800                	add	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009a0:	100007b7          	lui	a5,0x10000
    800009a4:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009a8:	8b85                	and	a5,a5,1
    800009aa:	cb81                	beqz	a5,800009ba <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    800009ac:	100007b7          	lui	a5,0x10000
    800009b0:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009b4:	6422                	ld	s0,8(sp)
    800009b6:	0141                	add	sp,sp,16
    800009b8:	8082                	ret
    return -1;
    800009ba:	557d                	li	a0,-1
    800009bc:	bfe5                	j	800009b4 <uartgetc+0x1a>

00000000800009be <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009be:	1101                	add	sp,sp,-32
    800009c0:	ec06                	sd	ra,24(sp)
    800009c2:	e822                	sd	s0,16(sp)
    800009c4:	e426                	sd	s1,8(sp)
    800009c6:	1000                	add	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009c8:	54fd                	li	s1,-1
    800009ca:	a029                	j	800009d4 <uartintr+0x16>
      break;
    consoleintr(c);
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	8f4080e7          	jalr	-1804(ra) # 800002c0 <consoleintr>
    int c = uartgetc();
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	fc6080e7          	jalr	-58(ra) # 8000099a <uartgetc>
    if(c == -1)
    800009dc:	fe9518e3          	bne	a0,s1,800009cc <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009e0:	00011497          	auipc	s1,0x11
    800009e4:	f1848493          	add	s1,s1,-232 # 800118f8 <uart_tx_lock>
    800009e8:	8526                	mv	a0,s1
    800009ea:	00000097          	auipc	ra,0x0
    800009ee:	212080e7          	jalr	530(ra) # 80000bfc <acquire>
  uartstart();
    800009f2:	00000097          	auipc	ra,0x0
    800009f6:	e48080e7          	jalr	-440(ra) # 8000083a <uartstart>
  release(&uart_tx_lock);
    800009fa:	8526                	mv	a0,s1
    800009fc:	00000097          	auipc	ra,0x0
    80000a00:	2b4080e7          	jalr	692(ra) # 80000cb0 <release>
}
    80000a04:	60e2                	ld	ra,24(sp)
    80000a06:	6442                	ld	s0,16(sp)
    80000a08:	64a2                	ld	s1,8(sp)
    80000a0a:	6105                	add	sp,sp,32
    80000a0c:	8082                	ret

0000000080000a0e <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a0e:	1101                	add	sp,sp,-32
    80000a10:	ec06                	sd	ra,24(sp)
    80000a12:	e822                	sd	s0,16(sp)
    80000a14:	e426                	sd	s1,8(sp)
    80000a16:	e04a                	sd	s2,0(sp)
    80000a18:	1000                	add	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a1a:	03451793          	sll	a5,a0,0x34
    80000a1e:	ebb9                	bnez	a5,80000a74 <kfree+0x66>
    80000a20:	84aa                	mv	s1,a0
    80000a22:	00025797          	auipc	a5,0x25
    80000a26:	5de78793          	add	a5,a5,1502 # 80026000 <end>
    80000a2a:	04f56563          	bltu	a0,a5,80000a74 <kfree+0x66>
    80000a2e:	47c5                	li	a5,17
    80000a30:	07ee                	sll	a5,a5,0x1b
    80000a32:	04f57163          	bgeu	a0,a5,80000a74 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a36:	6605                	lui	a2,0x1
    80000a38:	4585                	li	a1,1
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	2be080e7          	jalr	702(ra) # 80000cf8 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a42:	00011917          	auipc	s2,0x11
    80000a46:	eee90913          	add	s2,s2,-274 # 80011930 <kmem>
    80000a4a:	854a                	mv	a0,s2
    80000a4c:	00000097          	auipc	ra,0x0
    80000a50:	1b0080e7          	jalr	432(ra) # 80000bfc <acquire>
  r->next = kmem.freelist;
    80000a54:	01893783          	ld	a5,24(s2)
    80000a58:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a5a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a5e:	854a                	mv	a0,s2
    80000a60:	00000097          	auipc	ra,0x0
    80000a64:	250080e7          	jalr	592(ra) # 80000cb0 <release>
}
    80000a68:	60e2                	ld	ra,24(sp)
    80000a6a:	6442                	ld	s0,16(sp)
    80000a6c:	64a2                	ld	s1,8(sp)
    80000a6e:	6902                	ld	s2,0(sp)
    80000a70:	6105                	add	sp,sp,32
    80000a72:	8082                	ret
    panic("kfree");
    80000a74:	00007517          	auipc	a0,0x7
    80000a78:	5ec50513          	add	a0,a0,1516 # 80008060 <digits+0x20>
    80000a7c:	00000097          	auipc	ra,0x0
    80000a80:	ac6080e7          	jalr	-1338(ra) # 80000542 <panic>

0000000080000a84 <freerange>:
{
    80000a84:	7179                	add	sp,sp,-48
    80000a86:	f406                	sd	ra,40(sp)
    80000a88:	f022                	sd	s0,32(sp)
    80000a8a:	ec26                	sd	s1,24(sp)
    80000a8c:	e84a                	sd	s2,16(sp)
    80000a8e:	e44e                	sd	s3,8(sp)
    80000a90:	e052                	sd	s4,0(sp)
    80000a92:	1800                	add	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a94:	6785                	lui	a5,0x1
    80000a96:	fff78713          	add	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a9a:	00e504b3          	add	s1,a0,a4
    80000a9e:	777d                	lui	a4,0xfffff
    80000aa0:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94be                	add	s1,s1,a5
    80000aa4:	0095ee63          	bltu	a1,s1,80000ac0 <freerange+0x3c>
    80000aa8:	892e                	mv	s2,a1
    kfree(p);
    80000aaa:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aac:	6985                	lui	s3,0x1
    kfree(p);
    80000aae:	01448533          	add	a0,s1,s4
    80000ab2:	00000097          	auipc	ra,0x0
    80000ab6:	f5c080e7          	jalr	-164(ra) # 80000a0e <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aba:	94ce                	add	s1,s1,s3
    80000abc:	fe9979e3          	bgeu	s2,s1,80000aae <freerange+0x2a>
}
    80000ac0:	70a2                	ld	ra,40(sp)
    80000ac2:	7402                	ld	s0,32(sp)
    80000ac4:	64e2                	ld	s1,24(sp)
    80000ac6:	6942                	ld	s2,16(sp)
    80000ac8:	69a2                	ld	s3,8(sp)
    80000aca:	6a02                	ld	s4,0(sp)
    80000acc:	6145                	add	sp,sp,48
    80000ace:	8082                	ret

0000000080000ad0 <kinit>:
{
    80000ad0:	1141                	add	sp,sp,-16
    80000ad2:	e406                	sd	ra,8(sp)
    80000ad4:	e022                	sd	s0,0(sp)
    80000ad6:	0800                	add	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ad8:	00007597          	auipc	a1,0x7
    80000adc:	59058593          	add	a1,a1,1424 # 80008068 <digits+0x28>
    80000ae0:	00011517          	auipc	a0,0x11
    80000ae4:	e5050513          	add	a0,a0,-432 # 80011930 <kmem>
    80000ae8:	00000097          	auipc	ra,0x0
    80000aec:	084080e7          	jalr	132(ra) # 80000b6c <initlock>
  freerange(end, (void*)PHYSTOP);
    80000af0:	45c5                	li	a1,17
    80000af2:	05ee                	sll	a1,a1,0x1b
    80000af4:	00025517          	auipc	a0,0x25
    80000af8:	50c50513          	add	a0,a0,1292 # 80026000 <end>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	f88080e7          	jalr	-120(ra) # 80000a84 <freerange>
}
    80000b04:	60a2                	ld	ra,8(sp)
    80000b06:	6402                	ld	s0,0(sp)
    80000b08:	0141                	add	sp,sp,16
    80000b0a:	8082                	ret

0000000080000b0c <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b0c:	1101                	add	sp,sp,-32
    80000b0e:	ec06                	sd	ra,24(sp)
    80000b10:	e822                	sd	s0,16(sp)
    80000b12:	e426                	sd	s1,8(sp)
    80000b14:	1000                	add	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b16:	00011497          	auipc	s1,0x11
    80000b1a:	e1a48493          	add	s1,s1,-486 # 80011930 <kmem>
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	0dc080e7          	jalr	220(ra) # 80000bfc <acquire>
  r = kmem.freelist;
    80000b28:	6c84                	ld	s1,24(s1)
  if(r)
    80000b2a:	c885                	beqz	s1,80000b5a <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b2c:	609c                	ld	a5,0(s1)
    80000b2e:	00011517          	auipc	a0,0x11
    80000b32:	e0250513          	add	a0,a0,-510 # 80011930 <kmem>
    80000b36:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	178080e7          	jalr	376(ra) # 80000cb0 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b40:	6605                	lui	a2,0x1
    80000b42:	4595                	li	a1,5
    80000b44:	8526                	mv	a0,s1
    80000b46:	00000097          	auipc	ra,0x0
    80000b4a:	1b2080e7          	jalr	434(ra) # 80000cf8 <memset>
  return (void*)r;
}
    80000b4e:	8526                	mv	a0,s1
    80000b50:	60e2                	ld	ra,24(sp)
    80000b52:	6442                	ld	s0,16(sp)
    80000b54:	64a2                	ld	s1,8(sp)
    80000b56:	6105                	add	sp,sp,32
    80000b58:	8082                	ret
  release(&kmem.lock);
    80000b5a:	00011517          	auipc	a0,0x11
    80000b5e:	dd650513          	add	a0,a0,-554 # 80011930 <kmem>
    80000b62:	00000097          	auipc	ra,0x0
    80000b66:	14e080e7          	jalr	334(ra) # 80000cb0 <release>
  if(r)
    80000b6a:	b7d5                	j	80000b4e <kalloc+0x42>

0000000080000b6c <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b6c:	1141                	add	sp,sp,-16
    80000b6e:	e422                	sd	s0,8(sp)
    80000b70:	0800                	add	s0,sp,16
  lk->name = name;
    80000b72:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b74:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b78:	00053823          	sd	zero,16(a0)
}
    80000b7c:	6422                	ld	s0,8(sp)
    80000b7e:	0141                	add	sp,sp,16
    80000b80:	8082                	ret

0000000080000b82 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	411c                	lw	a5,0(a0)
    80000b84:	e399                	bnez	a5,80000b8a <holding+0x8>
    80000b86:	4501                	li	a0,0
  return r;
}
    80000b88:	8082                	ret
{
    80000b8a:	1101                	add	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b94:	6904                	ld	s1,16(a0)
    80000b96:	00001097          	auipc	ra,0x1
    80000b9a:	f46080e7          	jalr	-186(ra) # 80001adc <mycpu>
    80000b9e:	40a48533          	sub	a0,s1,a0
    80000ba2:	00153513          	seqz	a0,a0
}
    80000ba6:	60e2                	ld	ra,24(sp)
    80000ba8:	6442                	ld	s0,16(sp)
    80000baa:	64a2                	ld	s1,8(sp)
    80000bac:	6105                	add	sp,sp,32
    80000bae:	8082                	ret

0000000080000bb0 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bb0:	1101                	add	sp,sp,-32
    80000bb2:	ec06                	sd	ra,24(sp)
    80000bb4:	e822                	sd	s0,16(sp)
    80000bb6:	e426                	sd	s1,8(sp)
    80000bb8:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bba:	100024f3          	csrr	s1,sstatus
    80000bbe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bc2:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bc4:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bc8:	00001097          	auipc	ra,0x1
    80000bcc:	f14080e7          	jalr	-236(ra) # 80001adc <mycpu>
    80000bd0:	5d3c                	lw	a5,120(a0)
    80000bd2:	cf89                	beqz	a5,80000bec <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	f08080e7          	jalr	-248(ra) # 80001adc <mycpu>
    80000bdc:	5d3c                	lw	a5,120(a0)
    80000bde:	2785                	addw	a5,a5,1
    80000be0:	dd3c                	sw	a5,120(a0)
}
    80000be2:	60e2                	ld	ra,24(sp)
    80000be4:	6442                	ld	s0,16(sp)
    80000be6:	64a2                	ld	s1,8(sp)
    80000be8:	6105                	add	sp,sp,32
    80000bea:	8082                	ret
    mycpu()->intena = old;
    80000bec:	00001097          	auipc	ra,0x1
    80000bf0:	ef0080e7          	jalr	-272(ra) # 80001adc <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bf4:	8085                	srl	s1,s1,0x1
    80000bf6:	8885                	and	s1,s1,1
    80000bf8:	dd64                	sw	s1,124(a0)
    80000bfa:	bfe9                	j	80000bd4 <push_off+0x24>

0000000080000bfc <acquire>:
{
    80000bfc:	1101                	add	sp,sp,-32
    80000bfe:	ec06                	sd	ra,24(sp)
    80000c00:	e822                	sd	s0,16(sp)
    80000c02:	e426                	sd	s1,8(sp)
    80000c04:	1000                	add	s0,sp,32
    80000c06:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c08:	00000097          	auipc	ra,0x0
    80000c0c:	fa8080e7          	jalr	-88(ra) # 80000bb0 <push_off>
  if(holding(lk))
    80000c10:	8526                	mv	a0,s1
    80000c12:	00000097          	auipc	ra,0x0
    80000c16:	f70080e7          	jalr	-144(ra) # 80000b82 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c1a:	4705                	li	a4,1
  if(holding(lk))
    80000c1c:	e115                	bnez	a0,80000c40 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c1e:	87ba                	mv	a5,a4
    80000c20:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c24:	2781                	sext.w	a5,a5
    80000c26:	ffe5                	bnez	a5,80000c1e <acquire+0x22>
  __sync_synchronize();
    80000c28:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	eb0080e7          	jalr	-336(ra) # 80001adc <mycpu>
    80000c34:	e888                	sd	a0,16(s1)
}
    80000c36:	60e2                	ld	ra,24(sp)
    80000c38:	6442                	ld	s0,16(sp)
    80000c3a:	64a2                	ld	s1,8(sp)
    80000c3c:	6105                	add	sp,sp,32
    80000c3e:	8082                	ret
    panic("acquire");
    80000c40:	00007517          	auipc	a0,0x7
    80000c44:	43050513          	add	a0,a0,1072 # 80008070 <digits+0x30>
    80000c48:	00000097          	auipc	ra,0x0
    80000c4c:	8fa080e7          	jalr	-1798(ra) # 80000542 <panic>

0000000080000c50 <pop_off>:

void
pop_off(void)
{
    80000c50:	1141                	add	sp,sp,-16
    80000c52:	e406                	sd	ra,8(sp)
    80000c54:	e022                	sd	s0,0(sp)
    80000c56:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    80000c58:	00001097          	auipc	ra,0x1
    80000c5c:	e84080e7          	jalr	-380(ra) # 80001adc <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c60:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c64:	8b89                	and	a5,a5,2
  if(intr_get())
    80000c66:	e78d                	bnez	a5,80000c90 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c68:	5d3c                	lw	a5,120(a0)
    80000c6a:	02f05b63          	blez	a5,80000ca0 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c6e:	37fd                	addw	a5,a5,-1
    80000c70:	0007871b          	sext.w	a4,a5
    80000c74:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c76:	eb09                	bnez	a4,80000c88 <pop_off+0x38>
    80000c78:	5d7c                	lw	a5,124(a0)
    80000c7a:	c799                	beqz	a5,80000c88 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c7c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c80:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c84:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c88:	60a2                	ld	ra,8(sp)
    80000c8a:	6402                	ld	s0,0(sp)
    80000c8c:	0141                	add	sp,sp,16
    80000c8e:	8082                	ret
    panic("pop_off - interruptible");
    80000c90:	00007517          	auipc	a0,0x7
    80000c94:	3e850513          	add	a0,a0,1000 # 80008078 <digits+0x38>
    80000c98:	00000097          	auipc	ra,0x0
    80000c9c:	8aa080e7          	jalr	-1878(ra) # 80000542 <panic>
    panic("pop_off");
    80000ca0:	00007517          	auipc	a0,0x7
    80000ca4:	3f050513          	add	a0,a0,1008 # 80008090 <digits+0x50>
    80000ca8:	00000097          	auipc	ra,0x0
    80000cac:	89a080e7          	jalr	-1894(ra) # 80000542 <panic>

0000000080000cb0 <release>:
{
    80000cb0:	1101                	add	sp,sp,-32
    80000cb2:	ec06                	sd	ra,24(sp)
    80000cb4:	e822                	sd	s0,16(sp)
    80000cb6:	e426                	sd	s1,8(sp)
    80000cb8:	1000                	add	s0,sp,32
    80000cba:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	ec6080e7          	jalr	-314(ra) # 80000b82 <holding>
    80000cc4:	c115                	beqz	a0,80000ce8 <release+0x38>
  lk->cpu = 0;
    80000cc6:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cca:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cce:	0f50000f          	fence	iorw,ow
    80000cd2:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cd6:	00000097          	auipc	ra,0x0
    80000cda:	f7a080e7          	jalr	-134(ra) # 80000c50 <pop_off>
}
    80000cde:	60e2                	ld	ra,24(sp)
    80000ce0:	6442                	ld	s0,16(sp)
    80000ce2:	64a2                	ld	s1,8(sp)
    80000ce4:	6105                	add	sp,sp,32
    80000ce6:	8082                	ret
    panic("release");
    80000ce8:	00007517          	auipc	a0,0x7
    80000cec:	3b050513          	add	a0,a0,944 # 80008098 <digits+0x58>
    80000cf0:	00000097          	auipc	ra,0x0
    80000cf4:	852080e7          	jalr	-1966(ra) # 80000542 <panic>

0000000080000cf8 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cf8:	1141                	add	sp,sp,-16
    80000cfa:	e422                	sd	s0,8(sp)
    80000cfc:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cfe:	ca19                	beqz	a2,80000d14 <memset+0x1c>
    80000d00:	87aa                	mv	a5,a0
    80000d02:	1602                	sll	a2,a2,0x20
    80000d04:	9201                	srl	a2,a2,0x20
    80000d06:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d0a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d0e:	0785                	add	a5,a5,1
    80000d10:	fee79de3          	bne	a5,a4,80000d0a <memset+0x12>
  }
  return dst;
}
    80000d14:	6422                	ld	s0,8(sp)
    80000d16:	0141                	add	sp,sp,16
    80000d18:	8082                	ret

0000000080000d1a <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d1a:	1141                	add	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d20:	ca05                	beqz	a2,80000d50 <memcmp+0x36>
    80000d22:	fff6069b          	addw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d26:	1682                	sll	a3,a3,0x20
    80000d28:	9281                	srl	a3,a3,0x20
    80000d2a:	0685                	add	a3,a3,1
    80000d2c:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d2e:	00054783          	lbu	a5,0(a0)
    80000d32:	0005c703          	lbu	a4,0(a1)
    80000d36:	00e79863          	bne	a5,a4,80000d46 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d3a:	0505                	add	a0,a0,1
    80000d3c:	0585                	add	a1,a1,1
  while(n-- > 0){
    80000d3e:	fed518e3          	bne	a0,a3,80000d2e <memcmp+0x14>
  }

  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	a019                	j	80000d4a <memcmp+0x30>
      return *s1 - *s2;
    80000d46:	40e7853b          	subw	a0,a5,a4
}
    80000d4a:	6422                	ld	s0,8(sp)
    80000d4c:	0141                	add	sp,sp,16
    80000d4e:	8082                	ret
  return 0;
    80000d50:	4501                	li	a0,0
    80000d52:	bfe5                	j	80000d4a <memcmp+0x30>

0000000080000d54 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d54:	1141                	add	sp,sp,-16
    80000d56:	e422                	sd	s0,8(sp)
    80000d58:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d5a:	02a5e563          	bltu	a1,a0,80000d84 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5e:	fff6069b          	addw	a3,a2,-1
    80000d62:	ce11                	beqz	a2,80000d7e <memmove+0x2a>
    80000d64:	1682                	sll	a3,a3,0x20
    80000d66:	9281                	srl	a3,a3,0x20
    80000d68:	0685                	add	a3,a3,1
    80000d6a:	96ae                	add	a3,a3,a1
    80000d6c:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d6e:	0585                	add	a1,a1,1
    80000d70:	0785                	add	a5,a5,1
    80000d72:	fff5c703          	lbu	a4,-1(a1)
    80000d76:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d7a:	fed59ae3          	bne	a1,a3,80000d6e <memmove+0x1a>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	add	sp,sp,16
    80000d82:	8082                	ret
  if(s < d && s + n > d){
    80000d84:	02061713          	sll	a4,a2,0x20
    80000d88:	9301                	srl	a4,a4,0x20
    80000d8a:	00e587b3          	add	a5,a1,a4
    80000d8e:	fcf578e3          	bgeu	a0,a5,80000d5e <memmove+0xa>
    d += n;
    80000d92:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d94:	fff6069b          	addw	a3,a2,-1
    80000d98:	d27d                	beqz	a2,80000d7e <memmove+0x2a>
    80000d9a:	02069613          	sll	a2,a3,0x20
    80000d9e:	9201                	srl	a2,a2,0x20
    80000da0:	fff64613          	not	a2,a2
    80000da4:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000da6:	17fd                	add	a5,a5,-1
    80000da8:	177d                	add	a4,a4,-1 # ffffffffffffefff <end+0xffffffff7ffd8fff>
    80000daa:	0007c683          	lbu	a3,0(a5)
    80000dae:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000db2:	fef61ae3          	bne	a2,a5,80000da6 <memmove+0x52>
    80000db6:	b7e1                	j	80000d7e <memmove+0x2a>

0000000080000db8 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000db8:	1141                	add	sp,sp,-16
    80000dba:	e406                	sd	ra,8(sp)
    80000dbc:	e022                	sd	s0,0(sp)
    80000dbe:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    80000dc0:	00000097          	auipc	ra,0x0
    80000dc4:	f94080e7          	jalr	-108(ra) # 80000d54 <memmove>
}
    80000dc8:	60a2                	ld	ra,8(sp)
    80000dca:	6402                	ld	s0,0(sp)
    80000dcc:	0141                	add	sp,sp,16
    80000dce:	8082                	ret

0000000080000dd0 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dd0:	1141                	add	sp,sp,-16
    80000dd2:	e422                	sd	s0,8(sp)
    80000dd4:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dd6:	ce11                	beqz	a2,80000df2 <strncmp+0x22>
    80000dd8:	00054783          	lbu	a5,0(a0)
    80000ddc:	cf89                	beqz	a5,80000df6 <strncmp+0x26>
    80000dde:	0005c703          	lbu	a4,0(a1)
    80000de2:	00f71a63          	bne	a4,a5,80000df6 <strncmp+0x26>
    n--, p++, q++;
    80000de6:	367d                	addw	a2,a2,-1
    80000de8:	0505                	add	a0,a0,1
    80000dea:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dec:	f675                	bnez	a2,80000dd8 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dee:	4501                	li	a0,0
    80000df0:	a809                	j	80000e02 <strncmp+0x32>
    80000df2:	4501                	li	a0,0
    80000df4:	a039                	j	80000e02 <strncmp+0x32>
  if(n == 0)
    80000df6:	ca09                	beqz	a2,80000e08 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000df8:	00054503          	lbu	a0,0(a0)
    80000dfc:	0005c783          	lbu	a5,0(a1)
    80000e00:	9d1d                	subw	a0,a0,a5
}
    80000e02:	6422                	ld	s0,8(sp)
    80000e04:	0141                	add	sp,sp,16
    80000e06:	8082                	ret
    return 0;
    80000e08:	4501                	li	a0,0
    80000e0a:	bfe5                	j	80000e02 <strncmp+0x32>

0000000080000e0c <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e0c:	1141                	add	sp,sp,-16
    80000e0e:	e422                	sd	s0,8(sp)
    80000e10:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e12:	87aa                	mv	a5,a0
    80000e14:	86b2                	mv	a3,a2
    80000e16:	367d                	addw	a2,a2,-1
    80000e18:	00d05963          	blez	a3,80000e2a <strncpy+0x1e>
    80000e1c:	0785                	add	a5,a5,1
    80000e1e:	0005c703          	lbu	a4,0(a1)
    80000e22:	fee78fa3          	sb	a4,-1(a5)
    80000e26:	0585                	add	a1,a1,1
    80000e28:	f775                	bnez	a4,80000e14 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e2a:	873e                	mv	a4,a5
    80000e2c:	9fb5                	addw	a5,a5,a3
    80000e2e:	37fd                	addw	a5,a5,-1
    80000e30:	00c05963          	blez	a2,80000e42 <strncpy+0x36>
    *s++ = 0;
    80000e34:	0705                	add	a4,a4,1
    80000e36:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e3a:	40e786bb          	subw	a3,a5,a4
    80000e3e:	fed04be3          	bgtz	a3,80000e34 <strncpy+0x28>
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	add	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e48:	1141                	add	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e4e:	02c05363          	blez	a2,80000e74 <safestrcpy+0x2c>
    80000e52:	fff6069b          	addw	a3,a2,-1
    80000e56:	1682                	sll	a3,a3,0x20
    80000e58:	9281                	srl	a3,a3,0x20
    80000e5a:	96ae                	add	a3,a3,a1
    80000e5c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e5e:	00d58963          	beq	a1,a3,80000e70 <safestrcpy+0x28>
    80000e62:	0585                	add	a1,a1,1
    80000e64:	0785                	add	a5,a5,1
    80000e66:	fff5c703          	lbu	a4,-1(a1)
    80000e6a:	fee78fa3          	sb	a4,-1(a5)
    80000e6e:	fb65                	bnez	a4,80000e5e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e70:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e74:	6422                	ld	s0,8(sp)
    80000e76:	0141                	add	sp,sp,16
    80000e78:	8082                	ret

0000000080000e7a <strlen>:

int
strlen(const char *s)
{
    80000e7a:	1141                	add	sp,sp,-16
    80000e7c:	e422                	sd	s0,8(sp)
    80000e7e:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e80:	00054783          	lbu	a5,0(a0)
    80000e84:	cf91                	beqz	a5,80000ea0 <strlen+0x26>
    80000e86:	0505                	add	a0,a0,1
    80000e88:	87aa                	mv	a5,a0
    80000e8a:	86be                	mv	a3,a5
    80000e8c:	0785                	add	a5,a5,1
    80000e8e:	fff7c703          	lbu	a4,-1(a5)
    80000e92:	ff65                	bnez	a4,80000e8a <strlen+0x10>
    80000e94:	40a6853b          	subw	a0,a3,a0
    80000e98:	2505                	addw	a0,a0,1
    ;
  return n;
}
    80000e9a:	6422                	ld	s0,8(sp)
    80000e9c:	0141                	add	sp,sp,16
    80000e9e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ea0:	4501                	li	a0,0
    80000ea2:	bfe5                	j	80000e9a <strlen+0x20>

0000000080000ea4 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ea4:	1141                	add	sp,sp,-16
    80000ea6:	e406                	sd	ra,8(sp)
    80000ea8:	e022                	sd	s0,0(sp)
    80000eaa:	0800                	add	s0,sp,16
  if(cpuid() == 0){
    80000eac:	00001097          	auipc	ra,0x1
    80000eb0:	c20080e7          	jalr	-992(ra) # 80001acc <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000eb4:	00008717          	auipc	a4,0x8
    80000eb8:	15870713          	add	a4,a4,344 # 8000900c <started>
  if(cpuid() == 0){
    80000ebc:	c139                	beqz	a0,80000f02 <main+0x5e>
    while(started == 0)
    80000ebe:	431c                	lw	a5,0(a4)
    80000ec0:	2781                	sext.w	a5,a5
    80000ec2:	dff5                	beqz	a5,80000ebe <main+0x1a>
      ;
    __sync_synchronize();
    80000ec4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	c04080e7          	jalr	-1020(ra) # 80001acc <cpuid>
    80000ed0:	85aa                	mv	a1,a0
    80000ed2:	00007517          	auipc	a0,0x7
    80000ed6:	1e650513          	add	a0,a0,486 # 800080b8 <digits+0x78>
    80000eda:	fffff097          	auipc	ra,0xfffff
    80000ede:	6b2080e7          	jalr	1714(ra) # 8000058c <printf>
    kvminithart();    // turn on paging
    80000ee2:	00000097          	auipc	ra,0x0
    80000ee6:	1d2080e7          	jalr	466(ra) # 800010b4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eea:	00002097          	auipc	ra,0x2
    80000eee:	86c080e7          	jalr	-1940(ra) # 80002756 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef2:	00005097          	auipc	ra,0x5
    80000ef6:	e9e080e7          	jalr	-354(ra) # 80005d90 <plicinithart>
  }

  scheduler();        
    80000efa:	00001097          	auipc	ra,0x1
    80000efe:	136080e7          	jalr	310(ra) # 80002030 <scheduler>
    consoleinit();
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	550080e7          	jalr	1360(ra) # 80000452 <consoleinit>
    printfinit();
    80000f0a:	00000097          	auipc	ra,0x0
    80000f0e:	862080e7          	jalr	-1950(ra) # 8000076c <printfinit>
    printf("\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	1b650513          	add	a0,a0,438 # 800080c8 <digits+0x88>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	672080e7          	jalr	1650(ra) # 8000058c <printf>
    printf("xv6 kernel is booting\n");
    80000f22:	00007517          	auipc	a0,0x7
    80000f26:	17e50513          	add	a0,a0,382 # 800080a0 <digits+0x60>
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	662080e7          	jalr	1634(ra) # 8000058c <printf>
    printf("\n");
    80000f32:	00007517          	auipc	a0,0x7
    80000f36:	19650513          	add	a0,a0,406 # 800080c8 <digits+0x88>
    80000f3a:	fffff097          	auipc	ra,0xfffff
    80000f3e:	652080e7          	jalr	1618(ra) # 8000058c <printf>
    kinit();         // physical page allocator
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	b8e080e7          	jalr	-1138(ra) # 80000ad0 <kinit>
    kvminit();       // create kernel page table
    80000f4a:	00000097          	auipc	ra,0x0
    80000f4e:	40c080e7          	jalr	1036(ra) # 80001356 <kvminit>
    kvminithart();   // turn on paging
    80000f52:	00000097          	auipc	ra,0x0
    80000f56:	162080e7          	jalr	354(ra) # 800010b4 <kvminithart>
    procinit();      // process table
    80000f5a:	00001097          	auipc	ra,0x1
    80000f5e:	aa2080e7          	jalr	-1374(ra) # 800019fc <procinit>
    trapinit();      // trap vectors
    80000f62:	00001097          	auipc	ra,0x1
    80000f66:	7cc080e7          	jalr	1996(ra) # 8000272e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	7ec080e7          	jalr	2028(ra) # 80002756 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f72:	00005097          	auipc	ra,0x5
    80000f76:	e08080e7          	jalr	-504(ra) # 80005d7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f7a:	00005097          	auipc	ra,0x5
    80000f7e:	e16080e7          	jalr	-490(ra) # 80005d90 <plicinithart>
    binit();         // buffer cache
    80000f82:	00002097          	auipc	ra,0x2
    80000f86:	ffc080e7          	jalr	-4(ra) # 80002f7e <binit>
    iinit();         // inode cache
    80000f8a:	00002097          	auipc	ra,0x2
    80000f8e:	688080e7          	jalr	1672(ra) # 80003612 <iinit>
    fileinit();      // file table
    80000f92:	00003097          	auipc	ra,0x3
    80000f96:	5fe080e7          	jalr	1534(ra) # 80004590 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f9a:	00005097          	auipc	ra,0x5
    80000f9e:	efc080e7          	jalr	-260(ra) # 80005e96 <virtio_disk_init>
    userinit();      // first user process
    80000fa2:	00001097          	auipc	ra,0x1
    80000fa6:	e20080e7          	jalr	-480(ra) # 80001dc2 <userinit>
    __sync_synchronize();
    80000faa:	0ff0000f          	fence
    started = 1;
    80000fae:	4785                	li	a5,1
    80000fb0:	00008717          	auipc	a4,0x8
    80000fb4:	04f72e23          	sw	a5,92(a4) # 8000900c <started>
    80000fb8:	b789                	j	80000efa <main+0x56>

0000000080000fba <_vmprint>:

extern char trampoline[]; // trampoline.S

void
_vmprint(pagetable_t pagetable,uint64 level)
{
    80000fba:	7159                	add	sp,sp,-112
    80000fbc:	f486                	sd	ra,104(sp)
    80000fbe:	f0a2                	sd	s0,96(sp)
    80000fc0:	eca6                	sd	s1,88(sp)
    80000fc2:	e8ca                	sd	s2,80(sp)
    80000fc4:	e4ce                	sd	s3,72(sp)
    80000fc6:	e0d2                	sd	s4,64(sp)
    80000fc8:	fc56                	sd	s5,56(sp)
    80000fca:	f85a                	sd	s6,48(sp)
    80000fcc:	f45e                	sd	s7,40(sp)
    80000fce:	f062                	sd	s8,32(sp)
    80000fd0:	ec66                	sd	s9,24(sp)
    80000fd2:	e86a                	sd	s10,16(sp)
    80000fd4:	e46e                	sd	s11,8(sp)
    80000fd6:	1880                	add	s0,sp,112
    80000fd8:	8c2e                	mv	s8,a1
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80000fda:	89aa                	mv	s3,a0
    80000fdc:	4901                	li	s2,0
    pte_t pte = pagetable[i];
    if((pte & PTE_V)){
      printf("..");
    80000fde:	00007d97          	auipc	s11,0x7
    80000fe2:	0f2d8d93          	add	s11,s11,242 # 800080d0 <digits+0x90>
      for(int j=1;j<level;j++){
    80000fe6:	4d05                	li	s10,1
        printf(" ..");
      }
      uint64 child = PTE2PA(pte);
      printf("%d: pte %p pa %p\n", i,pte,child);
    80000fe8:	00007c97          	auipc	s9,0x7
    80000fec:	0f8c8c93          	add	s9,s9,248 # 800080e0 <digits+0xa0>
    80000ff0:	fff58b13          	add	s6,a1,-1
        printf(" ..");
    80000ff4:	00007a97          	auipc	s5,0x7
    80000ff8:	0e4a8a93          	add	s5,s5,228 # 800080d8 <digits+0x98>
  for(int i = 0; i < 512; i++){
    80000ffc:	20000b93          	li	s7,512
    80001000:	a029                	j	8000100a <_vmprint+0x50>
    80001002:	2905                	addw	s2,s2,1
    80001004:	09a1                	add	s3,s3,8 # 1008 <_entry-0x7fffeff8>
    80001006:	05790e63          	beq	s2,s7,80001062 <_vmprint+0xa8>
    pte_t pte = pagetable[i];
    8000100a:	0009ba03          	ld	s4,0(s3)
    if((pte & PTE_V)){
    8000100e:	001a7793          	and	a5,s4,1
    80001012:	dbe5                	beqz	a5,80001002 <_vmprint+0x48>
      printf("..");
    80001014:	856e                	mv	a0,s11
    80001016:	fffff097          	auipc	ra,0xfffff
    8000101a:	576080e7          	jalr	1398(ra) # 8000058c <printf>
      for(int j=1;j<level;j++){
    8000101e:	018d7b63          	bgeu	s10,s8,80001034 <_vmprint+0x7a>
    80001022:	4481                	li	s1,0
        printf(" ..");
    80001024:	8556                	mv	a0,s5
    80001026:	fffff097          	auipc	ra,0xfffff
    8000102a:	566080e7          	jalr	1382(ra) # 8000058c <printf>
      for(int j=1;j<level;j++){
    8000102e:	0485                	add	s1,s1,1
    80001030:	fe9b1ae3          	bne	s6,s1,80001024 <_vmprint+0x6a>
      uint64 child = PTE2PA(pte);
    80001034:	00aa5493          	srl	s1,s4,0xa
    80001038:	04b2                	sll	s1,s1,0xc
      printf("%d: pte %p pa %p\n", i,pte,child);
    8000103a:	86a6                	mv	a3,s1
    8000103c:	8652                	mv	a2,s4
    8000103e:	85ca                	mv	a1,s2
    80001040:	8566                	mv	a0,s9
    80001042:	fffff097          	auipc	ra,0xfffff
    80001046:	54a080e7          	jalr	1354(ra) # 8000058c <printf>
      if((pte & (PTE_R|PTE_W|PTE_X)) == 0) _vmprint((pagetable_t)child,level+1);
    8000104a:	00ea7a13          	and	s4,s4,14
    8000104e:	fa0a1ae3          	bnez	s4,80001002 <_vmprint+0x48>
    80001052:	001c0593          	add	a1,s8,1
    80001056:	8526                	mv	a0,s1
    80001058:	00000097          	auipc	ra,0x0
    8000105c:	f62080e7          	jalr	-158(ra) # 80000fba <_vmprint>
    80001060:	b74d                	j	80001002 <_vmprint+0x48>
    }
  }
}
    80001062:	70a6                	ld	ra,104(sp)
    80001064:	7406                	ld	s0,96(sp)
    80001066:	64e6                	ld	s1,88(sp)
    80001068:	6946                	ld	s2,80(sp)
    8000106a:	69a6                	ld	s3,72(sp)
    8000106c:	6a06                	ld	s4,64(sp)
    8000106e:	7ae2                	ld	s5,56(sp)
    80001070:	7b42                	ld	s6,48(sp)
    80001072:	7ba2                	ld	s7,40(sp)
    80001074:	7c02                	ld	s8,32(sp)
    80001076:	6ce2                	ld	s9,24(sp)
    80001078:	6d42                	ld	s10,16(sp)
    8000107a:	6da2                	ld	s11,8(sp)
    8000107c:	6165                	add	sp,sp,112
    8000107e:	8082                	ret

0000000080001080 <vmprint>:
void
vmprint(pagetable_t pagetable)
{
    80001080:	1101                	add	sp,sp,-32
    80001082:	ec06                	sd	ra,24(sp)
    80001084:	e822                	sd	s0,16(sp)
    80001086:	e426                	sd	s1,8(sp)
    80001088:	1000                	add	s0,sp,32
    8000108a:	84aa                	mv	s1,a0
  printf("page table %p\n",pagetable);
    8000108c:	85aa                	mv	a1,a0
    8000108e:	00007517          	auipc	a0,0x7
    80001092:	06a50513          	add	a0,a0,106 # 800080f8 <digits+0xb8>
    80001096:	fffff097          	auipc	ra,0xfffff
    8000109a:	4f6080e7          	jalr	1270(ra) # 8000058c <printf>
  _vmprint(pagetable,1);
    8000109e:	4585                	li	a1,1
    800010a0:	8526                	mv	a0,s1
    800010a2:	00000097          	auipc	ra,0x0
    800010a6:	f18080e7          	jalr	-232(ra) # 80000fba <_vmprint>
}
    800010aa:	60e2                	ld	ra,24(sp)
    800010ac:	6442                	ld	s0,16(sp)
    800010ae:	64a2                	ld	s1,8(sp)
    800010b0:	6105                	add	sp,sp,32
    800010b2:	8082                	ret

00000000800010b4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800010b4:	1141                	add	sp,sp,-16
    800010b6:	e422                	sd	s0,8(sp)
    800010b8:	0800                	add	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    800010ba:	00008797          	auipc	a5,0x8
    800010be:	f567b783          	ld	a5,-170(a5) # 80009010 <kernel_pagetable>
    800010c2:	83b1                	srl	a5,a5,0xc
    800010c4:	577d                	li	a4,-1
    800010c6:	177e                	sll	a4,a4,0x3f
    800010c8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010ca:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010ce:	12000073          	sfence.vma
  sfence_vma();
}
    800010d2:	6422                	ld	s0,8(sp)
    800010d4:	0141                	add	sp,sp,16
    800010d6:	8082                	ret

00000000800010d8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010d8:	7139                	add	sp,sp,-64
    800010da:	fc06                	sd	ra,56(sp)
    800010dc:	f822                	sd	s0,48(sp)
    800010de:	f426                	sd	s1,40(sp)
    800010e0:	f04a                	sd	s2,32(sp)
    800010e2:	ec4e                	sd	s3,24(sp)
    800010e4:	e852                	sd	s4,16(sp)
    800010e6:	e456                	sd	s5,8(sp)
    800010e8:	e05a                	sd	s6,0(sp)
    800010ea:	0080                	add	s0,sp,64
    800010ec:	84aa                	mv	s1,a0
    800010ee:	89ae                	mv	s3,a1
    800010f0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800010f2:	57fd                	li	a5,-1
    800010f4:	83e9                	srl	a5,a5,0x1a
    800010f6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800010f8:	4b31                	li	s6,12
  if(va >= MAXVA)
    800010fa:	04b7f263          	bgeu	a5,a1,8000113e <walk+0x66>
    panic("walk");
    800010fe:	00007517          	auipc	a0,0x7
    80001102:	00a50513          	add	a0,a0,10 # 80008108 <digits+0xc8>
    80001106:	fffff097          	auipc	ra,0xfffff
    8000110a:	43c080e7          	jalr	1084(ra) # 80000542 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000110e:	060a8663          	beqz	s5,8000117a <walk+0xa2>
    80001112:	00000097          	auipc	ra,0x0
    80001116:	9fa080e7          	jalr	-1542(ra) # 80000b0c <kalloc>
    8000111a:	84aa                	mv	s1,a0
    8000111c:	c529                	beqz	a0,80001166 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000111e:	6605                	lui	a2,0x1
    80001120:	4581                	li	a1,0
    80001122:	00000097          	auipc	ra,0x0
    80001126:	bd6080e7          	jalr	-1066(ra) # 80000cf8 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000112a:	00c4d793          	srl	a5,s1,0xc
    8000112e:	07aa                	sll	a5,a5,0xa
    80001130:	0017e793          	or	a5,a5,1
    80001134:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001138:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd8ff7>
    8000113a:	036a0063          	beq	s4,s6,8000115a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000113e:	0149d933          	srl	s2,s3,s4
    80001142:	1ff97913          	and	s2,s2,511
    80001146:	090e                	sll	s2,s2,0x3
    80001148:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000114a:	00093483          	ld	s1,0(s2)
    8000114e:	0014f793          	and	a5,s1,1
    80001152:	dfd5                	beqz	a5,8000110e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001154:	80a9                	srl	s1,s1,0xa
    80001156:	04b2                	sll	s1,s1,0xc
    80001158:	b7c5                	j	80001138 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000115a:	00c9d513          	srl	a0,s3,0xc
    8000115e:	1ff57513          	and	a0,a0,511
    80001162:	050e                	sll	a0,a0,0x3
    80001164:	9526                	add	a0,a0,s1
}
    80001166:	70e2                	ld	ra,56(sp)
    80001168:	7442                	ld	s0,48(sp)
    8000116a:	74a2                	ld	s1,40(sp)
    8000116c:	7902                	ld	s2,32(sp)
    8000116e:	69e2                	ld	s3,24(sp)
    80001170:	6a42                	ld	s4,16(sp)
    80001172:	6aa2                	ld	s5,8(sp)
    80001174:	6b02                	ld	s6,0(sp)
    80001176:	6121                	add	sp,sp,64
    80001178:	8082                	ret
        return 0;
    8000117a:	4501                	li	a0,0
    8000117c:	b7ed                	j	80001166 <walk+0x8e>

000000008000117e <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000117e:	1101                	add	sp,sp,-32
    80001180:	ec06                	sd	ra,24(sp)
    80001182:	e822                	sd	s0,16(sp)
    80001184:	e426                	sd	s1,8(sp)
    80001186:	1000                	add	s0,sp,32
    80001188:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    8000118a:	1552                	sll	a0,a0,0x34
    8000118c:	03455493          	srl	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001190:	4601                	li	a2,0
    80001192:	00008517          	auipc	a0,0x8
    80001196:	e7e53503          	ld	a0,-386(a0) # 80009010 <kernel_pagetable>
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	f3e080e7          	jalr	-194(ra) # 800010d8 <walk>
  if(pte == 0)
    800011a2:	cd09                	beqz	a0,800011bc <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800011a4:	6108                	ld	a0,0(a0)
    800011a6:	00157793          	and	a5,a0,1
    800011aa:	c38d                	beqz	a5,800011cc <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800011ac:	8129                	srl	a0,a0,0xa
    800011ae:	0532                	sll	a0,a0,0xc
  return pa+off;
}
    800011b0:	9526                	add	a0,a0,s1
    800011b2:	60e2                	ld	ra,24(sp)
    800011b4:	6442                	ld	s0,16(sp)
    800011b6:	64a2                	ld	s1,8(sp)
    800011b8:	6105                	add	sp,sp,32
    800011ba:	8082                	ret
    panic("kvmpa");
    800011bc:	00007517          	auipc	a0,0x7
    800011c0:	f5450513          	add	a0,a0,-172 # 80008110 <digits+0xd0>
    800011c4:	fffff097          	auipc	ra,0xfffff
    800011c8:	37e080e7          	jalr	894(ra) # 80000542 <panic>
    panic("kvmpa");
    800011cc:	00007517          	auipc	a0,0x7
    800011d0:	f4450513          	add	a0,a0,-188 # 80008110 <digits+0xd0>
    800011d4:	fffff097          	auipc	ra,0xfffff
    800011d8:	36e080e7          	jalr	878(ra) # 80000542 <panic>

00000000800011dc <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011dc:	715d                	add	sp,sp,-80
    800011de:	e486                	sd	ra,72(sp)
    800011e0:	e0a2                	sd	s0,64(sp)
    800011e2:	fc26                	sd	s1,56(sp)
    800011e4:	f84a                	sd	s2,48(sp)
    800011e6:	f44e                	sd	s3,40(sp)
    800011e8:	f052                	sd	s4,32(sp)
    800011ea:	ec56                	sd	s5,24(sp)
    800011ec:	e85a                	sd	s6,16(sp)
    800011ee:	e45e                	sd	s7,8(sp)
    800011f0:	0880                	add	s0,sp,80
    800011f2:	8aaa                	mv	s5,a0
    800011f4:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011f6:	777d                	lui	a4,0xfffff
    800011f8:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011fc:	fff60993          	add	s3,a2,-1 # fff <_entry-0x7ffff001>
    80001200:	99ae                	add	s3,s3,a1
    80001202:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001206:	893e                	mv	s2,a5
    80001208:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000120c:	6b85                	lui	s7,0x1
    8000120e:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001212:	4605                	li	a2,1
    80001214:	85ca                	mv	a1,s2
    80001216:	8556                	mv	a0,s5
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	ec0080e7          	jalr	-320(ra) # 800010d8 <walk>
    80001220:	c51d                	beqz	a0,8000124e <mappages+0x72>
    if(*pte & PTE_V)
    80001222:	611c                	ld	a5,0(a0)
    80001224:	8b85                	and	a5,a5,1
    80001226:	ef81                	bnez	a5,8000123e <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001228:	80b1                	srl	s1,s1,0xc
    8000122a:	04aa                	sll	s1,s1,0xa
    8000122c:	0164e4b3          	or	s1,s1,s6
    80001230:	0014e493          	or	s1,s1,1
    80001234:	e104                	sd	s1,0(a0)
    if(a == last)
    80001236:	03390863          	beq	s2,s3,80001266 <mappages+0x8a>
    a += PGSIZE;
    8000123a:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000123c:	bfc9                	j	8000120e <mappages+0x32>
      panic("remap");
    8000123e:	00007517          	auipc	a0,0x7
    80001242:	eda50513          	add	a0,a0,-294 # 80008118 <digits+0xd8>
    80001246:	fffff097          	auipc	ra,0xfffff
    8000124a:	2fc080e7          	jalr	764(ra) # 80000542 <panic>
      return -1;
    8000124e:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001250:	60a6                	ld	ra,72(sp)
    80001252:	6406                	ld	s0,64(sp)
    80001254:	74e2                	ld	s1,56(sp)
    80001256:	7942                	ld	s2,48(sp)
    80001258:	79a2                	ld	s3,40(sp)
    8000125a:	7a02                	ld	s4,32(sp)
    8000125c:	6ae2                	ld	s5,24(sp)
    8000125e:	6b42                	ld	s6,16(sp)
    80001260:	6ba2                	ld	s7,8(sp)
    80001262:	6161                	add	sp,sp,80
    80001264:	8082                	ret
  return 0;
    80001266:	4501                	li	a0,0
    80001268:	b7e5                	j	80001250 <mappages+0x74>

000000008000126a <walkaddr>:
{
    8000126a:	7179                	add	sp,sp,-48
    8000126c:	f406                	sd	ra,40(sp)
    8000126e:	f022                	sd	s0,32(sp)
    80001270:	ec26                	sd	s1,24(sp)
    80001272:	e84a                	sd	s2,16(sp)
    80001274:	e44e                	sd	s3,8(sp)
    80001276:	e052                	sd	s4,0(sp)
    80001278:	1800                	add	s0,sp,48
    8000127a:	892a                	mv	s2,a0
    8000127c:	84ae                	mv	s1,a1
  struct proc *p=myproc();  // lab5-3
    8000127e:	00001097          	auipc	ra,0x1
    80001282:	87a080e7          	jalr	-1926(ra) # 80001af8 <myproc>
  if(va >= MAXVA)
    80001286:	57fd                	li	a5,-1
    80001288:	83e9                	srl	a5,a5,0x1a
    8000128a:	0097fc63          	bgeu	a5,s1,800012a2 <walkaddr+0x38>
    return 0;
    8000128e:	4901                	li	s2,0
}
    80001290:	854a                	mv	a0,s2
    80001292:	70a2                	ld	ra,40(sp)
    80001294:	7402                	ld	s0,32(sp)
    80001296:	64e2                	ld	s1,24(sp)
    80001298:	6942                	ld	s2,16(sp)
    8000129a:	69a2                	ld	s3,8(sp)
    8000129c:	6a02                	ld	s4,0(sp)
    8000129e:	6145                	add	sp,sp,48
    800012a0:	8082                	ret
    800012a2:	89aa                	mv	s3,a0
  pte = walk(pagetable, va, 0);
    800012a4:	4601                	li	a2,0
    800012a6:	85a6                	mv	a1,s1
    800012a8:	854a                	mv	a0,s2
    800012aa:	00000097          	auipc	ra,0x0
    800012ae:	e2e080e7          	jalr	-466(ra) # 800010d8 <walk>
  if(pte == 0 || (*pte & PTE_V) == 0)
    800012b2:	c509                	beqz	a0,800012bc <walkaddr+0x52>
    800012b4:	611c                	ld	a5,0(a0)
    800012b6:	0017f713          	and	a4,a5,1
    800012ba:	eb31                	bnez	a4,8000130e <walkaddr+0xa4>
    if (va >= p->sz || va < PGROUNDUP(p->trapframe->sp))
    800012bc:	0489b783          	ld	a5,72(s3)
      return 0;
    800012c0:	4901                	li	s2,0
    if (va >= p->sz || va < PGROUNDUP(p->trapframe->sp))
    800012c2:	fcf4f7e3          	bgeu	s1,a5,80001290 <walkaddr+0x26>
    800012c6:	0589b783          	ld	a5,88(s3)
    800012ca:	7b9c                	ld	a5,48(a5)
    800012cc:	6705                	lui	a4,0x1
    800012ce:	177d                	add	a4,a4,-1 # fff <_entry-0x7ffff001>
    800012d0:	97ba                	add	a5,a5,a4
    800012d2:	777d                	lui	a4,0xfffff
    800012d4:	8ff9                	and	a5,a5,a4
    800012d6:	faf4ede3          	bltu	s1,a5,80001290 <walkaddr+0x26>
    uint64 ka = (uint64)kalloc();
    800012da:	00000097          	auipc	ra,0x0
    800012de:	832080e7          	jalr	-1998(ra) # 80000b0c <kalloc>
    800012e2:	8a2a                	mv	s4,a0
    if (ka == 0)
    800012e4:	d555                	beqz	a0,80001290 <walkaddr+0x26>
    uint64 ka = (uint64)kalloc();
    800012e6:	892a                	mv	s2,a0
    if (mappages(p->pagetable, PGROUNDDOWN(va), PGSIZE, ka, PTE_W|PTE_X|PTE_R|PTE_U) != 0)
    800012e8:	4779                	li	a4,30
    800012ea:	86aa                	mv	a3,a0
    800012ec:	6605                	lui	a2,0x1
    800012ee:	75fd                	lui	a1,0xfffff
    800012f0:	8de5                	and	a1,a1,s1
    800012f2:	0509b503          	ld	a0,80(s3)
    800012f6:	00000097          	auipc	ra,0x0
    800012fa:	ee6080e7          	jalr	-282(ra) # 800011dc <mappages>
    800012fe:	d949                	beqz	a0,80001290 <walkaddr+0x26>
      kfree((void*)ka);
    80001300:	8552                	mv	a0,s4
    80001302:	fffff097          	auipc	ra,0xfffff
    80001306:	70c080e7          	jalr	1804(ra) # 80000a0e <kfree>
      return 0;
    8000130a:	4901                	li	s2,0
    8000130c:	b751                	j	80001290 <walkaddr+0x26>
  if((*pte & PTE_U) == 0)
    8000130e:	0107f913          	and	s2,a5,16
    80001312:	f6090fe3          	beqz	s2,80001290 <walkaddr+0x26>
  pa = PTE2PA(*pte);
    80001316:	83a9                	srl	a5,a5,0xa
    80001318:	00c79913          	sll	s2,a5,0xc
  return pa;
    8000131c:	bf95                	j	80001290 <walkaddr+0x26>

000000008000131e <kvmmap>:
{
    8000131e:	1141                	add	sp,sp,-16
    80001320:	e406                	sd	ra,8(sp)
    80001322:	e022                	sd	s0,0(sp)
    80001324:	0800                	add	s0,sp,16
    80001326:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001328:	86ae                	mv	a3,a1
    8000132a:	85aa                	mv	a1,a0
    8000132c:	00008517          	auipc	a0,0x8
    80001330:	ce453503          	ld	a0,-796(a0) # 80009010 <kernel_pagetable>
    80001334:	00000097          	auipc	ra,0x0
    80001338:	ea8080e7          	jalr	-344(ra) # 800011dc <mappages>
    8000133c:	e509                	bnez	a0,80001346 <kvmmap+0x28>
}
    8000133e:	60a2                	ld	ra,8(sp)
    80001340:	6402                	ld	s0,0(sp)
    80001342:	0141                	add	sp,sp,16
    80001344:	8082                	ret
    panic("kvmmap");
    80001346:	00007517          	auipc	a0,0x7
    8000134a:	dda50513          	add	a0,a0,-550 # 80008120 <digits+0xe0>
    8000134e:	fffff097          	auipc	ra,0xfffff
    80001352:	1f4080e7          	jalr	500(ra) # 80000542 <panic>

0000000080001356 <kvminit>:
{
    80001356:	1101                	add	sp,sp,-32
    80001358:	ec06                	sd	ra,24(sp)
    8000135a:	e822                	sd	s0,16(sp)
    8000135c:	e426                	sd	s1,8(sp)
    8000135e:	1000                	add	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001360:	fffff097          	auipc	ra,0xfffff
    80001364:	7ac080e7          	jalr	1964(ra) # 80000b0c <kalloc>
    80001368:	00008717          	auipc	a4,0x8
    8000136c:	caa73423          	sd	a0,-856(a4) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001370:	6605                	lui	a2,0x1
    80001372:	4581                	li	a1,0
    80001374:	00000097          	auipc	ra,0x0
    80001378:	984080e7          	jalr	-1660(ra) # 80000cf8 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000137c:	4699                	li	a3,6
    8000137e:	6605                	lui	a2,0x1
    80001380:	100005b7          	lui	a1,0x10000
    80001384:	10000537          	lui	a0,0x10000
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	f96080e7          	jalr	-106(ra) # 8000131e <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001390:	4699                	li	a3,6
    80001392:	6605                	lui	a2,0x1
    80001394:	100015b7          	lui	a1,0x10001
    80001398:	10001537          	lui	a0,0x10001
    8000139c:	00000097          	auipc	ra,0x0
    800013a0:	f82080e7          	jalr	-126(ra) # 8000131e <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800013a4:	4699                	li	a3,6
    800013a6:	6641                	lui	a2,0x10
    800013a8:	020005b7          	lui	a1,0x2000
    800013ac:	02000537          	lui	a0,0x2000
    800013b0:	00000097          	auipc	ra,0x0
    800013b4:	f6e080e7          	jalr	-146(ra) # 8000131e <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800013b8:	4699                	li	a3,6
    800013ba:	00400637          	lui	a2,0x400
    800013be:	0c0005b7          	lui	a1,0xc000
    800013c2:	0c000537          	lui	a0,0xc000
    800013c6:	00000097          	auipc	ra,0x0
    800013ca:	f58080e7          	jalr	-168(ra) # 8000131e <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800013ce:	00007497          	auipc	s1,0x7
    800013d2:	c3248493          	add	s1,s1,-974 # 80008000 <etext>
    800013d6:	46a9                	li	a3,10
    800013d8:	80007617          	auipc	a2,0x80007
    800013dc:	c2860613          	add	a2,a2,-984 # 8000 <_entry-0x7fff8000>
    800013e0:	4585                	li	a1,1
    800013e2:	05fe                	sll	a1,a1,0x1f
    800013e4:	852e                	mv	a0,a1
    800013e6:	00000097          	auipc	ra,0x0
    800013ea:	f38080e7          	jalr	-200(ra) # 8000131e <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800013ee:	4699                	li	a3,6
    800013f0:	4645                	li	a2,17
    800013f2:	066e                	sll	a2,a2,0x1b
    800013f4:	8e05                	sub	a2,a2,s1
    800013f6:	85a6                	mv	a1,s1
    800013f8:	8526                	mv	a0,s1
    800013fa:	00000097          	auipc	ra,0x0
    800013fe:	f24080e7          	jalr	-220(ra) # 8000131e <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001402:	46a9                	li	a3,10
    80001404:	6605                	lui	a2,0x1
    80001406:	00006597          	auipc	a1,0x6
    8000140a:	bfa58593          	add	a1,a1,-1030 # 80007000 <_trampoline>
    8000140e:	04000537          	lui	a0,0x4000
    80001412:	157d                	add	a0,a0,-1 # 3ffffff <_entry-0x7c000001>
    80001414:	0532                	sll	a0,a0,0xc
    80001416:	00000097          	auipc	ra,0x0
    8000141a:	f08080e7          	jalr	-248(ra) # 8000131e <kvmmap>
}
    8000141e:	60e2                	ld	ra,24(sp)
    80001420:	6442                	ld	s0,16(sp)
    80001422:	64a2                	ld	s1,8(sp)
    80001424:	6105                	add	sp,sp,32
    80001426:	8082                	ret

0000000080001428 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001428:	715d                	add	sp,sp,-80
    8000142a:	e486                	sd	ra,72(sp)
    8000142c:	e0a2                	sd	s0,64(sp)
    8000142e:	fc26                	sd	s1,56(sp)
    80001430:	f84a                	sd	s2,48(sp)
    80001432:	f44e                	sd	s3,40(sp)
    80001434:	f052                	sd	s4,32(sp)
    80001436:	ec56                	sd	s5,24(sp)
    80001438:	e85a                	sd	s6,16(sp)
    8000143a:	e45e                	sd	s7,8(sp)
    8000143c:	0880                	add	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000143e:	03459793          	sll	a5,a1,0x34
    80001442:	e795                	bnez	a5,8000146e <uvmunmap+0x46>
    80001444:	8a2a                	mv	s4,a0
    80001446:	892e                	mv	s2,a1
    80001448:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000144a:	0632                	sll	a2,a2,0xc
    8000144c:	00b609b3          	add	s3,a2,a1
      continue;
      //panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      continue;
      //panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001450:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001452:	6a85                	lui	s5,0x1
    80001454:	0535e263          	bltu	a1,s3,80001498 <uvmunmap+0x70>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001458:	60a6                	ld	ra,72(sp)
    8000145a:	6406                	ld	s0,64(sp)
    8000145c:	74e2                	ld	s1,56(sp)
    8000145e:	7942                	ld	s2,48(sp)
    80001460:	79a2                	ld	s3,40(sp)
    80001462:	7a02                	ld	s4,32(sp)
    80001464:	6ae2                	ld	s5,24(sp)
    80001466:	6b42                	ld	s6,16(sp)
    80001468:	6ba2                	ld	s7,8(sp)
    8000146a:	6161                	add	sp,sp,80
    8000146c:	8082                	ret
    panic("uvmunmap: not aligned");
    8000146e:	00007517          	auipc	a0,0x7
    80001472:	cba50513          	add	a0,a0,-838 # 80008128 <digits+0xe8>
    80001476:	fffff097          	auipc	ra,0xfffff
    8000147a:	0cc080e7          	jalr	204(ra) # 80000542 <panic>
      panic("uvmunmap: not a leaf");
    8000147e:	00007517          	auipc	a0,0x7
    80001482:	cc250513          	add	a0,a0,-830 # 80008140 <digits+0x100>
    80001486:	fffff097          	auipc	ra,0xfffff
    8000148a:	0bc080e7          	jalr	188(ra) # 80000542 <panic>
    *pte = 0;
    8000148e:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001492:	9956                	add	s2,s2,s5
    80001494:	fd3972e3          	bgeu	s2,s3,80001458 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001498:	4601                	li	a2,0
    8000149a:	85ca                	mv	a1,s2
    8000149c:	8552                	mv	a0,s4
    8000149e:	00000097          	auipc	ra,0x0
    800014a2:	c3a080e7          	jalr	-966(ra) # 800010d8 <walk>
    800014a6:	84aa                	mv	s1,a0
    800014a8:	d56d                	beqz	a0,80001492 <uvmunmap+0x6a>
    if((*pte & PTE_V) == 0)
    800014aa:	611c                	ld	a5,0(a0)
    800014ac:	0017f713          	and	a4,a5,1
    800014b0:	d36d                	beqz	a4,80001492 <uvmunmap+0x6a>
    if(PTE_FLAGS(*pte) == PTE_V)
    800014b2:	3ff7f713          	and	a4,a5,1023
    800014b6:	fd7704e3          	beq	a4,s7,8000147e <uvmunmap+0x56>
    if(do_free){
    800014ba:	fc0b0ae3          	beqz	s6,8000148e <uvmunmap+0x66>
      uint64 pa = PTE2PA(*pte);
    800014be:	83a9                	srl	a5,a5,0xa
      kfree((void*)pa);
    800014c0:	00c79513          	sll	a0,a5,0xc
    800014c4:	fffff097          	auipc	ra,0xfffff
    800014c8:	54a080e7          	jalr	1354(ra) # 80000a0e <kfree>
    800014cc:	b7c9                	j	8000148e <uvmunmap+0x66>

00000000800014ce <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800014ce:	1101                	add	sp,sp,-32
    800014d0:	ec06                	sd	ra,24(sp)
    800014d2:	e822                	sd	s0,16(sp)
    800014d4:	e426                	sd	s1,8(sp)
    800014d6:	1000                	add	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800014d8:	fffff097          	auipc	ra,0xfffff
    800014dc:	634080e7          	jalr	1588(ra) # 80000b0c <kalloc>
    800014e0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800014e2:	c519                	beqz	a0,800014f0 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800014e4:	6605                	lui	a2,0x1
    800014e6:	4581                	li	a1,0
    800014e8:	00000097          	auipc	ra,0x0
    800014ec:	810080e7          	jalr	-2032(ra) # 80000cf8 <memset>
  return pagetable;
}
    800014f0:	8526                	mv	a0,s1
    800014f2:	60e2                	ld	ra,24(sp)
    800014f4:	6442                	ld	s0,16(sp)
    800014f6:	64a2                	ld	s1,8(sp)
    800014f8:	6105                	add	sp,sp,32
    800014fa:	8082                	ret

00000000800014fc <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800014fc:	7179                	add	sp,sp,-48
    800014fe:	f406                	sd	ra,40(sp)
    80001500:	f022                	sd	s0,32(sp)
    80001502:	ec26                	sd	s1,24(sp)
    80001504:	e84a                	sd	s2,16(sp)
    80001506:	e44e                	sd	s3,8(sp)
    80001508:	e052                	sd	s4,0(sp)
    8000150a:	1800                	add	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000150c:	6785                	lui	a5,0x1
    8000150e:	04f67863          	bgeu	a2,a5,8000155e <uvminit+0x62>
    80001512:	8a2a                	mv	s4,a0
    80001514:	89ae                	mv	s3,a1
    80001516:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001518:	fffff097          	auipc	ra,0xfffff
    8000151c:	5f4080e7          	jalr	1524(ra) # 80000b0c <kalloc>
    80001520:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001522:	6605                	lui	a2,0x1
    80001524:	4581                	li	a1,0
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	7d2080e7          	jalr	2002(ra) # 80000cf8 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000152e:	4779                	li	a4,30
    80001530:	86ca                	mv	a3,s2
    80001532:	6605                	lui	a2,0x1
    80001534:	4581                	li	a1,0
    80001536:	8552                	mv	a0,s4
    80001538:	00000097          	auipc	ra,0x0
    8000153c:	ca4080e7          	jalr	-860(ra) # 800011dc <mappages>
  memmove(mem, src, sz);
    80001540:	8626                	mv	a2,s1
    80001542:	85ce                	mv	a1,s3
    80001544:	854a                	mv	a0,s2
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	80e080e7          	jalr	-2034(ra) # 80000d54 <memmove>
}
    8000154e:	70a2                	ld	ra,40(sp)
    80001550:	7402                	ld	s0,32(sp)
    80001552:	64e2                	ld	s1,24(sp)
    80001554:	6942                	ld	s2,16(sp)
    80001556:	69a2                	ld	s3,8(sp)
    80001558:	6a02                	ld	s4,0(sp)
    8000155a:	6145                	add	sp,sp,48
    8000155c:	8082                	ret
    panic("inituvm: more than a page");
    8000155e:	00007517          	auipc	a0,0x7
    80001562:	bfa50513          	add	a0,a0,-1030 # 80008158 <digits+0x118>
    80001566:	fffff097          	auipc	ra,0xfffff
    8000156a:	fdc080e7          	jalr	-36(ra) # 80000542 <panic>

000000008000156e <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000156e:	1101                	add	sp,sp,-32
    80001570:	ec06                	sd	ra,24(sp)
    80001572:	e822                	sd	s0,16(sp)
    80001574:	e426                	sd	s1,8(sp)
    80001576:	1000                	add	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001578:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000157a:	00b67d63          	bgeu	a2,a1,80001594 <uvmdealloc+0x26>
    8000157e:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001580:	6785                	lui	a5,0x1
    80001582:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001584:	00f60733          	add	a4,a2,a5
    80001588:	76fd                	lui	a3,0xfffff
    8000158a:	8f75                	and	a4,a4,a3
    8000158c:	97ae                	add	a5,a5,a1
    8000158e:	8ff5                	and	a5,a5,a3
    80001590:	00f76863          	bltu	a4,a5,800015a0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001594:	8526                	mv	a0,s1
    80001596:	60e2                	ld	ra,24(sp)
    80001598:	6442                	ld	s0,16(sp)
    8000159a:	64a2                	ld	s1,8(sp)
    8000159c:	6105                	add	sp,sp,32
    8000159e:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800015a0:	8f99                	sub	a5,a5,a4
    800015a2:	83b1                	srl	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800015a4:	4685                	li	a3,1
    800015a6:	0007861b          	sext.w	a2,a5
    800015aa:	85ba                	mv	a1,a4
    800015ac:	00000097          	auipc	ra,0x0
    800015b0:	e7c080e7          	jalr	-388(ra) # 80001428 <uvmunmap>
    800015b4:	b7c5                	j	80001594 <uvmdealloc+0x26>

00000000800015b6 <uvmalloc>:
  if(newsz < oldsz)
    800015b6:	0ab66163          	bltu	a2,a1,80001658 <uvmalloc+0xa2>
{
    800015ba:	7139                	add	sp,sp,-64
    800015bc:	fc06                	sd	ra,56(sp)
    800015be:	f822                	sd	s0,48(sp)
    800015c0:	f426                	sd	s1,40(sp)
    800015c2:	f04a                	sd	s2,32(sp)
    800015c4:	ec4e                	sd	s3,24(sp)
    800015c6:	e852                	sd	s4,16(sp)
    800015c8:	e456                	sd	s5,8(sp)
    800015ca:	0080                	add	s0,sp,64
    800015cc:	8aaa                	mv	s5,a0
    800015ce:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800015d0:	6785                	lui	a5,0x1
    800015d2:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015d4:	95be                	add	a1,a1,a5
    800015d6:	77fd                	lui	a5,0xfffff
    800015d8:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015dc:	08c9f063          	bgeu	s3,a2,8000165c <uvmalloc+0xa6>
    800015e0:	894e                	mv	s2,s3
    mem = kalloc();
    800015e2:	fffff097          	auipc	ra,0xfffff
    800015e6:	52a080e7          	jalr	1322(ra) # 80000b0c <kalloc>
    800015ea:	84aa                	mv	s1,a0
    if(mem == 0){
    800015ec:	c51d                	beqz	a0,8000161a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800015ee:	6605                	lui	a2,0x1
    800015f0:	4581                	li	a1,0
    800015f2:	fffff097          	auipc	ra,0xfffff
    800015f6:	706080e7          	jalr	1798(ra) # 80000cf8 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800015fa:	4779                	li	a4,30
    800015fc:	86a6                	mv	a3,s1
    800015fe:	6605                	lui	a2,0x1
    80001600:	85ca                	mv	a1,s2
    80001602:	8556                	mv	a0,s5
    80001604:	00000097          	auipc	ra,0x0
    80001608:	bd8080e7          	jalr	-1064(ra) # 800011dc <mappages>
    8000160c:	e905                	bnez	a0,8000163c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000160e:	6785                	lui	a5,0x1
    80001610:	993e                	add	s2,s2,a5
    80001612:	fd4968e3          	bltu	s2,s4,800015e2 <uvmalloc+0x2c>
  return newsz;
    80001616:	8552                	mv	a0,s4
    80001618:	a809                	j	8000162a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000161a:	864e                	mv	a2,s3
    8000161c:	85ca                	mv	a1,s2
    8000161e:	8556                	mv	a0,s5
    80001620:	00000097          	auipc	ra,0x0
    80001624:	f4e080e7          	jalr	-178(ra) # 8000156e <uvmdealloc>
      return 0;
    80001628:	4501                	li	a0,0
}
    8000162a:	70e2                	ld	ra,56(sp)
    8000162c:	7442                	ld	s0,48(sp)
    8000162e:	74a2                	ld	s1,40(sp)
    80001630:	7902                	ld	s2,32(sp)
    80001632:	69e2                	ld	s3,24(sp)
    80001634:	6a42                	ld	s4,16(sp)
    80001636:	6aa2                	ld	s5,8(sp)
    80001638:	6121                	add	sp,sp,64
    8000163a:	8082                	ret
      kfree(mem);
    8000163c:	8526                	mv	a0,s1
    8000163e:	fffff097          	auipc	ra,0xfffff
    80001642:	3d0080e7          	jalr	976(ra) # 80000a0e <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001646:	864e                	mv	a2,s3
    80001648:	85ca                	mv	a1,s2
    8000164a:	8556                	mv	a0,s5
    8000164c:	00000097          	auipc	ra,0x0
    80001650:	f22080e7          	jalr	-222(ra) # 8000156e <uvmdealloc>
      return 0;
    80001654:	4501                	li	a0,0
    80001656:	bfd1                	j	8000162a <uvmalloc+0x74>
    return oldsz;
    80001658:	852e                	mv	a0,a1
}
    8000165a:	8082                	ret
  return newsz;
    8000165c:	8532                	mv	a0,a2
    8000165e:	b7f1                	j	8000162a <uvmalloc+0x74>

0000000080001660 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001660:	7179                	add	sp,sp,-48
    80001662:	f406                	sd	ra,40(sp)
    80001664:	f022                	sd	s0,32(sp)
    80001666:	ec26                	sd	s1,24(sp)
    80001668:	e84a                	sd	s2,16(sp)
    8000166a:	e44e                	sd	s3,8(sp)
    8000166c:	e052                	sd	s4,0(sp)
    8000166e:	1800                	add	s0,sp,48
    80001670:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001672:	84aa                	mv	s1,a0
    80001674:	6905                	lui	s2,0x1
    80001676:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001678:	4985                	li	s3,1
    8000167a:	a829                	j	80001694 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000167c:	83a9                	srl	a5,a5,0xa
      freewalk((pagetable_t)child);
    8000167e:	00c79513          	sll	a0,a5,0xc
    80001682:	00000097          	auipc	ra,0x0
    80001686:	fde080e7          	jalr	-34(ra) # 80001660 <freewalk>
      pagetable[i] = 0;
    8000168a:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000168e:	04a1                	add	s1,s1,8
    80001690:	03248163          	beq	s1,s2,800016b2 <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001694:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001696:	00f7f713          	and	a4,a5,15
    8000169a:	ff3701e3          	beq	a4,s3,8000167c <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000169e:	8b85                	and	a5,a5,1
    800016a0:	d7fd                	beqz	a5,8000168e <freewalk+0x2e>
      panic("freewalk: leaf");
    800016a2:	00007517          	auipc	a0,0x7
    800016a6:	ad650513          	add	a0,a0,-1322 # 80008178 <digits+0x138>
    800016aa:	fffff097          	auipc	ra,0xfffff
    800016ae:	e98080e7          	jalr	-360(ra) # 80000542 <panic>
    }
  }
  kfree((void*)pagetable);
    800016b2:	8552                	mv	a0,s4
    800016b4:	fffff097          	auipc	ra,0xfffff
    800016b8:	35a080e7          	jalr	858(ra) # 80000a0e <kfree>
}
    800016bc:	70a2                	ld	ra,40(sp)
    800016be:	7402                	ld	s0,32(sp)
    800016c0:	64e2                	ld	s1,24(sp)
    800016c2:	6942                	ld	s2,16(sp)
    800016c4:	69a2                	ld	s3,8(sp)
    800016c6:	6a02                	ld	s4,0(sp)
    800016c8:	6145                	add	sp,sp,48
    800016ca:	8082                	ret

00000000800016cc <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800016cc:	1101                	add	sp,sp,-32
    800016ce:	ec06                	sd	ra,24(sp)
    800016d0:	e822                	sd	s0,16(sp)
    800016d2:	e426                	sd	s1,8(sp)
    800016d4:	1000                	add	s0,sp,32
    800016d6:	84aa                	mv	s1,a0
  if(sz > 0)
    800016d8:	e999                	bnez	a1,800016ee <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800016da:	8526                	mv	a0,s1
    800016dc:	00000097          	auipc	ra,0x0
    800016e0:	f84080e7          	jalr	-124(ra) # 80001660 <freewalk>
}
    800016e4:	60e2                	ld	ra,24(sp)
    800016e6:	6442                	ld	s0,16(sp)
    800016e8:	64a2                	ld	s1,8(sp)
    800016ea:	6105                	add	sp,sp,32
    800016ec:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800016ee:	6785                	lui	a5,0x1
    800016f0:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800016f2:	95be                	add	a1,a1,a5
    800016f4:	4685                	li	a3,1
    800016f6:	00c5d613          	srl	a2,a1,0xc
    800016fa:	4581                	li	a1,0
    800016fc:	00000097          	auipc	ra,0x0
    80001700:	d2c080e7          	jalr	-724(ra) # 80001428 <uvmunmap>
    80001704:	bfd9                	j	800016da <uvmfree+0xe>

0000000080001706 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001706:	ca4d                	beqz	a2,800017b8 <uvmcopy+0xb2>
{
    80001708:	715d                	add	sp,sp,-80
    8000170a:	e486                	sd	ra,72(sp)
    8000170c:	e0a2                	sd	s0,64(sp)
    8000170e:	fc26                	sd	s1,56(sp)
    80001710:	f84a                	sd	s2,48(sp)
    80001712:	f44e                	sd	s3,40(sp)
    80001714:	f052                	sd	s4,32(sp)
    80001716:	ec56                	sd	s5,24(sp)
    80001718:	e85a                	sd	s6,16(sp)
    8000171a:	e45e                	sd	s7,8(sp)
    8000171c:	0880                	add	s0,sp,80
    8000171e:	8aaa                	mv	s5,a0
    80001720:	8b2e                	mv	s6,a1
    80001722:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001724:	4481                	li	s1,0
    80001726:	a029                	j	80001730 <uvmcopy+0x2a>
    80001728:	6785                	lui	a5,0x1
    8000172a:	94be                	add	s1,s1,a5
    8000172c:	0744fa63          	bgeu	s1,s4,800017a0 <uvmcopy+0x9a>
    if((pte = walk(old, i, 0)) == 0)
    80001730:	4601                	li	a2,0
    80001732:	85a6                	mv	a1,s1
    80001734:	8556                	mv	a0,s5
    80001736:	00000097          	auipc	ra,0x0
    8000173a:	9a2080e7          	jalr	-1630(ra) # 800010d8 <walk>
    8000173e:	d56d                	beqz	a0,80001728 <uvmcopy+0x22>
      continue;   
      //panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001740:	6118                	ld	a4,0(a0)
    80001742:	00177793          	and	a5,a4,1
    80001746:	d3ed                	beqz	a5,80001728 <uvmcopy+0x22>
      continue;
      //panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001748:	00a75593          	srl	a1,a4,0xa
    8000174c:	00c59b93          	sll	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001750:	3ff77913          	and	s2,a4,1023
    if((mem = kalloc()) == 0)
    80001754:	fffff097          	auipc	ra,0xfffff
    80001758:	3b8080e7          	jalr	952(ra) # 80000b0c <kalloc>
    8000175c:	89aa                	mv	s3,a0
    8000175e:	c515                	beqz	a0,8000178a <uvmcopy+0x84>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001760:	6605                	lui	a2,0x1
    80001762:	85de                	mv	a1,s7
    80001764:	fffff097          	auipc	ra,0xfffff
    80001768:	5f0080e7          	jalr	1520(ra) # 80000d54 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000176c:	874a                	mv	a4,s2
    8000176e:	86ce                	mv	a3,s3
    80001770:	6605                	lui	a2,0x1
    80001772:	85a6                	mv	a1,s1
    80001774:	855a                	mv	a0,s6
    80001776:	00000097          	auipc	ra,0x0
    8000177a:	a66080e7          	jalr	-1434(ra) # 800011dc <mappages>
    8000177e:	d54d                	beqz	a0,80001728 <uvmcopy+0x22>
      kfree(mem);
    80001780:	854e                	mv	a0,s3
    80001782:	fffff097          	auipc	ra,0xfffff
    80001786:	28c080e7          	jalr	652(ra) # 80000a0e <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000178a:	4685                	li	a3,1
    8000178c:	00c4d613          	srl	a2,s1,0xc
    80001790:	4581                	li	a1,0
    80001792:	855a                	mv	a0,s6
    80001794:	00000097          	auipc	ra,0x0
    80001798:	c94080e7          	jalr	-876(ra) # 80001428 <uvmunmap>
  return -1;
    8000179c:	557d                	li	a0,-1
    8000179e:	a011                	j	800017a2 <uvmcopy+0x9c>
  return 0;
    800017a0:	4501                	li	a0,0
}
    800017a2:	60a6                	ld	ra,72(sp)
    800017a4:	6406                	ld	s0,64(sp)
    800017a6:	74e2                	ld	s1,56(sp)
    800017a8:	7942                	ld	s2,48(sp)
    800017aa:	79a2                	ld	s3,40(sp)
    800017ac:	7a02                	ld	s4,32(sp)
    800017ae:	6ae2                	ld	s5,24(sp)
    800017b0:	6b42                	ld	s6,16(sp)
    800017b2:	6ba2                	ld	s7,8(sp)
    800017b4:	6161                	add	sp,sp,80
    800017b6:	8082                	ret
  return 0;
    800017b8:	4501                	li	a0,0
}
    800017ba:	8082                	ret

00000000800017bc <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800017bc:	1141                	add	sp,sp,-16
    800017be:	e406                	sd	ra,8(sp)
    800017c0:	e022                	sd	s0,0(sp)
    800017c2:	0800                	add	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800017c4:	4601                	li	a2,0
    800017c6:	00000097          	auipc	ra,0x0
    800017ca:	912080e7          	jalr	-1774(ra) # 800010d8 <walk>
  if(pte == 0)
    800017ce:	c901                	beqz	a0,800017de <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800017d0:	611c                	ld	a5,0(a0)
    800017d2:	9bbd                	and	a5,a5,-17
    800017d4:	e11c                	sd	a5,0(a0)
}
    800017d6:	60a2                	ld	ra,8(sp)
    800017d8:	6402                	ld	s0,0(sp)
    800017da:	0141                	add	sp,sp,16
    800017dc:	8082                	ret
    panic("uvmclear");
    800017de:	00007517          	auipc	a0,0x7
    800017e2:	9aa50513          	add	a0,a0,-1622 # 80008188 <digits+0x148>
    800017e6:	fffff097          	auipc	ra,0xfffff
    800017ea:	d5c080e7          	jalr	-676(ra) # 80000542 <panic>

00000000800017ee <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017ee:	c6bd                	beqz	a3,8000185c <copyout+0x6e>
{
    800017f0:	715d                	add	sp,sp,-80
    800017f2:	e486                	sd	ra,72(sp)
    800017f4:	e0a2                	sd	s0,64(sp)
    800017f6:	fc26                	sd	s1,56(sp)
    800017f8:	f84a                	sd	s2,48(sp)
    800017fa:	f44e                	sd	s3,40(sp)
    800017fc:	f052                	sd	s4,32(sp)
    800017fe:	ec56                	sd	s5,24(sp)
    80001800:	e85a                	sd	s6,16(sp)
    80001802:	e45e                	sd	s7,8(sp)
    80001804:	e062                	sd	s8,0(sp)
    80001806:	0880                	add	s0,sp,80
    80001808:	8b2a                	mv	s6,a0
    8000180a:	8c2e                	mv	s8,a1
    8000180c:	8a32                	mv	s4,a2
    8000180e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001810:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001812:	6a85                	lui	s5,0x1
    80001814:	a015                	j	80001838 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001816:	9562                	add	a0,a0,s8
    80001818:	0004861b          	sext.w	a2,s1
    8000181c:	85d2                	mv	a1,s4
    8000181e:	41250533          	sub	a0,a0,s2
    80001822:	fffff097          	auipc	ra,0xfffff
    80001826:	532080e7          	jalr	1330(ra) # 80000d54 <memmove>

    len -= n;
    8000182a:	409989b3          	sub	s3,s3,s1
    src += n;
    8000182e:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001830:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001834:	02098263          	beqz	s3,80001858 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001838:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000183c:	85ca                	mv	a1,s2
    8000183e:	855a                	mv	a0,s6
    80001840:	00000097          	auipc	ra,0x0
    80001844:	a2a080e7          	jalr	-1494(ra) # 8000126a <walkaddr>
    if(pa0 == 0)
    80001848:	cd01                	beqz	a0,80001860 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000184a:	418904b3          	sub	s1,s2,s8
    8000184e:	94d6                	add	s1,s1,s5
    80001850:	fc99f3e3          	bgeu	s3,s1,80001816 <copyout+0x28>
    80001854:	84ce                	mv	s1,s3
    80001856:	b7c1                	j	80001816 <copyout+0x28>
  }
  return 0;
    80001858:	4501                	li	a0,0
    8000185a:	a021                	j	80001862 <copyout+0x74>
    8000185c:	4501                	li	a0,0
}
    8000185e:	8082                	ret
      return -1;
    80001860:	557d                	li	a0,-1
}
    80001862:	60a6                	ld	ra,72(sp)
    80001864:	6406                	ld	s0,64(sp)
    80001866:	74e2                	ld	s1,56(sp)
    80001868:	7942                	ld	s2,48(sp)
    8000186a:	79a2                	ld	s3,40(sp)
    8000186c:	7a02                	ld	s4,32(sp)
    8000186e:	6ae2                	ld	s5,24(sp)
    80001870:	6b42                	ld	s6,16(sp)
    80001872:	6ba2                	ld	s7,8(sp)
    80001874:	6c02                	ld	s8,0(sp)
    80001876:	6161                	add	sp,sp,80
    80001878:	8082                	ret

000000008000187a <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000187a:	caa5                	beqz	a3,800018ea <copyin+0x70>
{
    8000187c:	715d                	add	sp,sp,-80
    8000187e:	e486                	sd	ra,72(sp)
    80001880:	e0a2                	sd	s0,64(sp)
    80001882:	fc26                	sd	s1,56(sp)
    80001884:	f84a                	sd	s2,48(sp)
    80001886:	f44e                	sd	s3,40(sp)
    80001888:	f052                	sd	s4,32(sp)
    8000188a:	ec56                	sd	s5,24(sp)
    8000188c:	e85a                	sd	s6,16(sp)
    8000188e:	e45e                	sd	s7,8(sp)
    80001890:	e062                	sd	s8,0(sp)
    80001892:	0880                	add	s0,sp,80
    80001894:	8b2a                	mv	s6,a0
    80001896:	8a2e                	mv	s4,a1
    80001898:	8c32                	mv	s8,a2
    8000189a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000189c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000189e:	6a85                	lui	s5,0x1
    800018a0:	a01d                	j	800018c6 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800018a2:	018505b3          	add	a1,a0,s8
    800018a6:	0004861b          	sext.w	a2,s1
    800018aa:	412585b3          	sub	a1,a1,s2
    800018ae:	8552                	mv	a0,s4
    800018b0:	fffff097          	auipc	ra,0xfffff
    800018b4:	4a4080e7          	jalr	1188(ra) # 80000d54 <memmove>

    len -= n;
    800018b8:	409989b3          	sub	s3,s3,s1
    dst += n;
    800018bc:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800018be:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800018c2:	02098263          	beqz	s3,800018e6 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800018c6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800018ca:	85ca                	mv	a1,s2
    800018cc:	855a                	mv	a0,s6
    800018ce:	00000097          	auipc	ra,0x0
    800018d2:	99c080e7          	jalr	-1636(ra) # 8000126a <walkaddr>
    if(pa0 == 0)
    800018d6:	cd01                	beqz	a0,800018ee <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800018d8:	418904b3          	sub	s1,s2,s8
    800018dc:	94d6                	add	s1,s1,s5
    800018de:	fc99f2e3          	bgeu	s3,s1,800018a2 <copyin+0x28>
    800018e2:	84ce                	mv	s1,s3
    800018e4:	bf7d                	j	800018a2 <copyin+0x28>
  }
  return 0;
    800018e6:	4501                	li	a0,0
    800018e8:	a021                	j	800018f0 <copyin+0x76>
    800018ea:	4501                	li	a0,0
}
    800018ec:	8082                	ret
      return -1;
    800018ee:	557d                	li	a0,-1
}
    800018f0:	60a6                	ld	ra,72(sp)
    800018f2:	6406                	ld	s0,64(sp)
    800018f4:	74e2                	ld	s1,56(sp)
    800018f6:	7942                	ld	s2,48(sp)
    800018f8:	79a2                	ld	s3,40(sp)
    800018fa:	7a02                	ld	s4,32(sp)
    800018fc:	6ae2                	ld	s5,24(sp)
    800018fe:	6b42                	ld	s6,16(sp)
    80001900:	6ba2                	ld	s7,8(sp)
    80001902:	6c02                	ld	s8,0(sp)
    80001904:	6161                	add	sp,sp,80
    80001906:	8082                	ret

0000000080001908 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001908:	c2dd                	beqz	a3,800019ae <copyinstr+0xa6>
{
    8000190a:	715d                	add	sp,sp,-80
    8000190c:	e486                	sd	ra,72(sp)
    8000190e:	e0a2                	sd	s0,64(sp)
    80001910:	fc26                	sd	s1,56(sp)
    80001912:	f84a                	sd	s2,48(sp)
    80001914:	f44e                	sd	s3,40(sp)
    80001916:	f052                	sd	s4,32(sp)
    80001918:	ec56                	sd	s5,24(sp)
    8000191a:	e85a                	sd	s6,16(sp)
    8000191c:	e45e                	sd	s7,8(sp)
    8000191e:	0880                	add	s0,sp,80
    80001920:	8a2a                	mv	s4,a0
    80001922:	8b2e                	mv	s6,a1
    80001924:	8bb2                	mv	s7,a2
    80001926:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001928:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000192a:	6985                	lui	s3,0x1
    8000192c:	a02d                	j	80001956 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000192e:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001932:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001934:	37fd                	addw	a5,a5,-1
    80001936:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000193a:	60a6                	ld	ra,72(sp)
    8000193c:	6406                	ld	s0,64(sp)
    8000193e:	74e2                	ld	s1,56(sp)
    80001940:	7942                	ld	s2,48(sp)
    80001942:	79a2                	ld	s3,40(sp)
    80001944:	7a02                	ld	s4,32(sp)
    80001946:	6ae2                	ld	s5,24(sp)
    80001948:	6b42                	ld	s6,16(sp)
    8000194a:	6ba2                	ld	s7,8(sp)
    8000194c:	6161                	add	sp,sp,80
    8000194e:	8082                	ret
    srcva = va0 + PGSIZE;
    80001950:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001954:	c8a9                	beqz	s1,800019a6 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001956:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000195a:	85ca                	mv	a1,s2
    8000195c:	8552                	mv	a0,s4
    8000195e:	00000097          	auipc	ra,0x0
    80001962:	90c080e7          	jalr	-1780(ra) # 8000126a <walkaddr>
    if(pa0 == 0)
    80001966:	c131                	beqz	a0,800019aa <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001968:	417906b3          	sub	a3,s2,s7
    8000196c:	96ce                	add	a3,a3,s3
    8000196e:	00d4f363          	bgeu	s1,a3,80001974 <copyinstr+0x6c>
    80001972:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001974:	955e                	add	a0,a0,s7
    80001976:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000197a:	daf9                	beqz	a3,80001950 <copyinstr+0x48>
    8000197c:	87da                	mv	a5,s6
    8000197e:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001980:	41650633          	sub	a2,a0,s6
    while(n > 0){
    80001984:	96da                	add	a3,a3,s6
    80001986:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001988:	00f60733          	add	a4,a2,a5
    8000198c:	00074703          	lbu	a4,0(a4)
    80001990:	df59                	beqz	a4,8000192e <copyinstr+0x26>
        *dst = *p;
    80001992:	00e78023          	sb	a4,0(a5)
      dst++;
    80001996:	0785                	add	a5,a5,1
    while(n > 0){
    80001998:	fed797e3          	bne	a5,a3,80001986 <copyinstr+0x7e>
    8000199c:	14fd                	add	s1,s1,-1
    8000199e:	94c2                	add	s1,s1,a6
      --max;
    800019a0:	8c8d                	sub	s1,s1,a1
      dst++;
    800019a2:	8b3e                	mv	s6,a5
    800019a4:	b775                	j	80001950 <copyinstr+0x48>
    800019a6:	4781                	li	a5,0
    800019a8:	b771                	j	80001934 <copyinstr+0x2c>
      return -1;
    800019aa:	557d                	li	a0,-1
    800019ac:	b779                	j	8000193a <copyinstr+0x32>
  int got_null = 0;
    800019ae:	4781                	li	a5,0
  if(got_null){
    800019b0:	37fd                	addw	a5,a5,-1
    800019b2:	0007851b          	sext.w	a0,a5
}
    800019b6:	8082                	ret

00000000800019b8 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800019b8:	1101                	add	sp,sp,-32
    800019ba:	ec06                	sd	ra,24(sp)
    800019bc:	e822                	sd	s0,16(sp)
    800019be:	e426                	sd	s1,8(sp)
    800019c0:	1000                	add	s0,sp,32
    800019c2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800019c4:	fffff097          	auipc	ra,0xfffff
    800019c8:	1be080e7          	jalr	446(ra) # 80000b82 <holding>
    800019cc:	c909                	beqz	a0,800019de <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800019ce:	749c                	ld	a5,40(s1)
    800019d0:	00978f63          	beq	a5,s1,800019ee <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800019d4:	60e2                	ld	ra,24(sp)
    800019d6:	6442                	ld	s0,16(sp)
    800019d8:	64a2                	ld	s1,8(sp)
    800019da:	6105                	add	sp,sp,32
    800019dc:	8082                	ret
    panic("wakeup1");
    800019de:	00006517          	auipc	a0,0x6
    800019e2:	7ba50513          	add	a0,a0,1978 # 80008198 <digits+0x158>
    800019e6:	fffff097          	auipc	ra,0xfffff
    800019ea:	b5c080e7          	jalr	-1188(ra) # 80000542 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800019ee:	4c98                	lw	a4,24(s1)
    800019f0:	4785                	li	a5,1
    800019f2:	fef711e3          	bne	a4,a5,800019d4 <wakeup1+0x1c>
    p->state = RUNNABLE;
    800019f6:	4789                	li	a5,2
    800019f8:	cc9c                	sw	a5,24(s1)
}
    800019fa:	bfe9                	j	800019d4 <wakeup1+0x1c>

00000000800019fc <procinit>:
{
    800019fc:	715d                	add	sp,sp,-80
    800019fe:	e486                	sd	ra,72(sp)
    80001a00:	e0a2                	sd	s0,64(sp)
    80001a02:	fc26                	sd	s1,56(sp)
    80001a04:	f84a                	sd	s2,48(sp)
    80001a06:	f44e                	sd	s3,40(sp)
    80001a08:	f052                	sd	s4,32(sp)
    80001a0a:	ec56                	sd	s5,24(sp)
    80001a0c:	e85a                	sd	s6,16(sp)
    80001a0e:	e45e                	sd	s7,8(sp)
    80001a10:	0880                	add	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001a12:	00006597          	auipc	a1,0x6
    80001a16:	78e58593          	add	a1,a1,1934 # 800081a0 <digits+0x160>
    80001a1a:	00010517          	auipc	a0,0x10
    80001a1e:	f3650513          	add	a0,a0,-202 # 80011950 <pid_lock>
    80001a22:	fffff097          	auipc	ra,0xfffff
    80001a26:	14a080e7          	jalr	330(ra) # 80000b6c <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a2a:	00010917          	auipc	s2,0x10
    80001a2e:	33e90913          	add	s2,s2,830 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001a32:	00006b97          	auipc	s7,0x6
    80001a36:	776b8b93          	add	s7,s7,1910 # 800081a8 <digits+0x168>
      uint64 va = KSTACK((int) (p - proc));
    80001a3a:	8b4a                	mv	s6,s2
    80001a3c:	00006a97          	auipc	s5,0x6
    80001a40:	5c4a8a93          	add	s5,s5,1476 # 80008000 <etext>
    80001a44:	040009b7          	lui	s3,0x4000
    80001a48:	19fd                	add	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001a4a:	09b2                	sll	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a4c:	00016a17          	auipc	s4,0x16
    80001a50:	d1ca0a13          	add	s4,s4,-740 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    80001a54:	85de                	mv	a1,s7
    80001a56:	854a                	mv	a0,s2
    80001a58:	fffff097          	auipc	ra,0xfffff
    80001a5c:	114080e7          	jalr	276(ra) # 80000b6c <initlock>
      char *pa = kalloc();
    80001a60:	fffff097          	auipc	ra,0xfffff
    80001a64:	0ac080e7          	jalr	172(ra) # 80000b0c <kalloc>
    80001a68:	85aa                	mv	a1,a0
      if(pa == 0)
    80001a6a:	c929                	beqz	a0,80001abc <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001a6c:	416904b3          	sub	s1,s2,s6
    80001a70:	848d                	sra	s1,s1,0x3
    80001a72:	000ab783          	ld	a5,0(s5)
    80001a76:	02f484b3          	mul	s1,s1,a5
    80001a7a:	2485                	addw	s1,s1,1
    80001a7c:	00d4949b          	sllw	s1,s1,0xd
    80001a80:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a84:	4699                	li	a3,6
    80001a86:	6605                	lui	a2,0x1
    80001a88:	8526                	mv	a0,s1
    80001a8a:	00000097          	auipc	ra,0x0
    80001a8e:	894080e7          	jalr	-1900(ra) # 8000131e <kvmmap>
      p->kstack = va;
    80001a92:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a96:	16890913          	add	s2,s2,360
    80001a9a:	fb491de3          	bne	s2,s4,80001a54 <procinit+0x58>
  kvminithart();
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	616080e7          	jalr	1558(ra) # 800010b4 <kvminithart>
}
    80001aa6:	60a6                	ld	ra,72(sp)
    80001aa8:	6406                	ld	s0,64(sp)
    80001aaa:	74e2                	ld	s1,56(sp)
    80001aac:	7942                	ld	s2,48(sp)
    80001aae:	79a2                	ld	s3,40(sp)
    80001ab0:	7a02                	ld	s4,32(sp)
    80001ab2:	6ae2                	ld	s5,24(sp)
    80001ab4:	6b42                	ld	s6,16(sp)
    80001ab6:	6ba2                	ld	s7,8(sp)
    80001ab8:	6161                	add	sp,sp,80
    80001aba:	8082                	ret
        panic("kalloc");
    80001abc:	00006517          	auipc	a0,0x6
    80001ac0:	6f450513          	add	a0,a0,1780 # 800081b0 <digits+0x170>
    80001ac4:	fffff097          	auipc	ra,0xfffff
    80001ac8:	a7e080e7          	jalr	-1410(ra) # 80000542 <panic>

0000000080001acc <cpuid>:
{
    80001acc:	1141                	add	sp,sp,-16
    80001ace:	e422                	sd	s0,8(sp)
    80001ad0:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ad2:	8512                	mv	a0,tp
}
    80001ad4:	2501                	sext.w	a0,a0
    80001ad6:	6422                	ld	s0,8(sp)
    80001ad8:	0141                	add	sp,sp,16
    80001ada:	8082                	ret

0000000080001adc <mycpu>:
mycpu(void) {
    80001adc:	1141                	add	sp,sp,-16
    80001ade:	e422                	sd	s0,8(sp)
    80001ae0:	0800                	add	s0,sp,16
    80001ae2:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001ae4:	2781                	sext.w	a5,a5
    80001ae6:	079e                	sll	a5,a5,0x7
}
    80001ae8:	00010517          	auipc	a0,0x10
    80001aec:	e8050513          	add	a0,a0,-384 # 80011968 <cpus>
    80001af0:	953e                	add	a0,a0,a5
    80001af2:	6422                	ld	s0,8(sp)
    80001af4:	0141                	add	sp,sp,16
    80001af6:	8082                	ret

0000000080001af8 <myproc>:
myproc(void) {
    80001af8:	1101                	add	sp,sp,-32
    80001afa:	ec06                	sd	ra,24(sp)
    80001afc:	e822                	sd	s0,16(sp)
    80001afe:	e426                	sd	s1,8(sp)
    80001b00:	1000                	add	s0,sp,32
  push_off();
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	0ae080e7          	jalr	174(ra) # 80000bb0 <push_off>
    80001b0a:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001b0c:	2781                	sext.w	a5,a5
    80001b0e:	079e                	sll	a5,a5,0x7
    80001b10:	00010717          	auipc	a4,0x10
    80001b14:	e4070713          	add	a4,a4,-448 # 80011950 <pid_lock>
    80001b18:	97ba                	add	a5,a5,a4
    80001b1a:	6f84                	ld	s1,24(a5)
  pop_off();
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	134080e7          	jalr	308(ra) # 80000c50 <pop_off>
}
    80001b24:	8526                	mv	a0,s1
    80001b26:	60e2                	ld	ra,24(sp)
    80001b28:	6442                	ld	s0,16(sp)
    80001b2a:	64a2                	ld	s1,8(sp)
    80001b2c:	6105                	add	sp,sp,32
    80001b2e:	8082                	ret

0000000080001b30 <forkret>:
{
    80001b30:	1141                	add	sp,sp,-16
    80001b32:	e406                	sd	ra,8(sp)
    80001b34:	e022                	sd	s0,0(sp)
    80001b36:	0800                	add	s0,sp,16
  release(&myproc()->lock);
    80001b38:	00000097          	auipc	ra,0x0
    80001b3c:	fc0080e7          	jalr	-64(ra) # 80001af8 <myproc>
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	170080e7          	jalr	368(ra) # 80000cb0 <release>
  if (first) {
    80001b48:	00007797          	auipc	a5,0x7
    80001b4c:	d387a783          	lw	a5,-712(a5) # 80008880 <first.1>
    80001b50:	eb89                	bnez	a5,80001b62 <forkret+0x32>
  usertrapret();
    80001b52:	00001097          	auipc	ra,0x1
    80001b56:	c1c080e7          	jalr	-996(ra) # 8000276e <usertrapret>
}
    80001b5a:	60a2                	ld	ra,8(sp)
    80001b5c:	6402                	ld	s0,0(sp)
    80001b5e:	0141                	add	sp,sp,16
    80001b60:	8082                	ret
    first = 0;
    80001b62:	00007797          	auipc	a5,0x7
    80001b66:	d007af23          	sw	zero,-738(a5) # 80008880 <first.1>
    fsinit(ROOTDEV);
    80001b6a:	4505                	li	a0,1
    80001b6c:	00002097          	auipc	ra,0x2
    80001b70:	a26080e7          	jalr	-1498(ra) # 80003592 <fsinit>
    80001b74:	bff9                	j	80001b52 <forkret+0x22>

0000000080001b76 <allocpid>:
allocpid() {
    80001b76:	1101                	add	sp,sp,-32
    80001b78:	ec06                	sd	ra,24(sp)
    80001b7a:	e822                	sd	s0,16(sp)
    80001b7c:	e426                	sd	s1,8(sp)
    80001b7e:	e04a                	sd	s2,0(sp)
    80001b80:	1000                	add	s0,sp,32
  acquire(&pid_lock);
    80001b82:	00010917          	auipc	s2,0x10
    80001b86:	dce90913          	add	s2,s2,-562 # 80011950 <pid_lock>
    80001b8a:	854a                	mv	a0,s2
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	070080e7          	jalr	112(ra) # 80000bfc <acquire>
  pid = nextpid;
    80001b94:	00007797          	auipc	a5,0x7
    80001b98:	cf078793          	add	a5,a5,-784 # 80008884 <nextpid>
    80001b9c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b9e:	0014871b          	addw	a4,s1,1
    80001ba2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ba4:	854a                	mv	a0,s2
    80001ba6:	fffff097          	auipc	ra,0xfffff
    80001baa:	10a080e7          	jalr	266(ra) # 80000cb0 <release>
}
    80001bae:	8526                	mv	a0,s1
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6902                	ld	s2,0(sp)
    80001bb8:	6105                	add	sp,sp,32
    80001bba:	8082                	ret

0000000080001bbc <proc_pagetable>:
{
    80001bbc:	1101                	add	sp,sp,-32
    80001bbe:	ec06                	sd	ra,24(sp)
    80001bc0:	e822                	sd	s0,16(sp)
    80001bc2:	e426                	sd	s1,8(sp)
    80001bc4:	e04a                	sd	s2,0(sp)
    80001bc6:	1000                	add	s0,sp,32
    80001bc8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bca:	00000097          	auipc	ra,0x0
    80001bce:	904080e7          	jalr	-1788(ra) # 800014ce <uvmcreate>
    80001bd2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bd4:	c121                	beqz	a0,80001c14 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bd6:	4729                	li	a4,10
    80001bd8:	00005697          	auipc	a3,0x5
    80001bdc:	42868693          	add	a3,a3,1064 # 80007000 <_trampoline>
    80001be0:	6605                	lui	a2,0x1
    80001be2:	040005b7          	lui	a1,0x4000
    80001be6:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001be8:	05b2                	sll	a1,a1,0xc
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	5f2080e7          	jalr	1522(ra) # 800011dc <mappages>
    80001bf2:	02054863          	bltz	a0,80001c22 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bf6:	4719                	li	a4,6
    80001bf8:	05893683          	ld	a3,88(s2)
    80001bfc:	6605                	lui	a2,0x1
    80001bfe:	020005b7          	lui	a1,0x2000
    80001c02:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c04:	05b6                	sll	a1,a1,0xd
    80001c06:	8526                	mv	a0,s1
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	5d4080e7          	jalr	1492(ra) # 800011dc <mappages>
    80001c10:	02054163          	bltz	a0,80001c32 <proc_pagetable+0x76>
}
    80001c14:	8526                	mv	a0,s1
    80001c16:	60e2                	ld	ra,24(sp)
    80001c18:	6442                	ld	s0,16(sp)
    80001c1a:	64a2                	ld	s1,8(sp)
    80001c1c:	6902                	ld	s2,0(sp)
    80001c1e:	6105                	add	sp,sp,32
    80001c20:	8082                	ret
    uvmfree(pagetable, 0);
    80001c22:	4581                	li	a1,0
    80001c24:	8526                	mv	a0,s1
    80001c26:	00000097          	auipc	ra,0x0
    80001c2a:	aa6080e7          	jalr	-1370(ra) # 800016cc <uvmfree>
    return 0;
    80001c2e:	4481                	li	s1,0
    80001c30:	b7d5                	j	80001c14 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c32:	4681                	li	a3,0
    80001c34:	4605                	li	a2,1
    80001c36:	040005b7          	lui	a1,0x4000
    80001c3a:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c3c:	05b2                	sll	a1,a1,0xc
    80001c3e:	8526                	mv	a0,s1
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	7e8080e7          	jalr	2024(ra) # 80001428 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c48:	4581                	li	a1,0
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	00000097          	auipc	ra,0x0
    80001c50:	a80080e7          	jalr	-1408(ra) # 800016cc <uvmfree>
    return 0;
    80001c54:	4481                	li	s1,0
    80001c56:	bf7d                	j	80001c14 <proc_pagetable+0x58>

0000000080001c58 <proc_freepagetable>:
{
    80001c58:	1101                	add	sp,sp,-32
    80001c5a:	ec06                	sd	ra,24(sp)
    80001c5c:	e822                	sd	s0,16(sp)
    80001c5e:	e426                	sd	s1,8(sp)
    80001c60:	e04a                	sd	s2,0(sp)
    80001c62:	1000                	add	s0,sp,32
    80001c64:	84aa                	mv	s1,a0
    80001c66:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c68:	4681                	li	a3,0
    80001c6a:	4605                	li	a2,1
    80001c6c:	040005b7          	lui	a1,0x4000
    80001c70:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c72:	05b2                	sll	a1,a1,0xc
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	7b4080e7          	jalr	1972(ra) # 80001428 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c7c:	4681                	li	a3,0
    80001c7e:	4605                	li	a2,1
    80001c80:	020005b7          	lui	a1,0x2000
    80001c84:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c86:	05b6                	sll	a1,a1,0xd
    80001c88:	8526                	mv	a0,s1
    80001c8a:	fffff097          	auipc	ra,0xfffff
    80001c8e:	79e080e7          	jalr	1950(ra) # 80001428 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c92:	85ca                	mv	a1,s2
    80001c94:	8526                	mv	a0,s1
    80001c96:	00000097          	auipc	ra,0x0
    80001c9a:	a36080e7          	jalr	-1482(ra) # 800016cc <uvmfree>
}
    80001c9e:	60e2                	ld	ra,24(sp)
    80001ca0:	6442                	ld	s0,16(sp)
    80001ca2:	64a2                	ld	s1,8(sp)
    80001ca4:	6902                	ld	s2,0(sp)
    80001ca6:	6105                	add	sp,sp,32
    80001ca8:	8082                	ret

0000000080001caa <freeproc>:
{
    80001caa:	1101                	add	sp,sp,-32
    80001cac:	ec06                	sd	ra,24(sp)
    80001cae:	e822                	sd	s0,16(sp)
    80001cb0:	e426                	sd	s1,8(sp)
    80001cb2:	1000                	add	s0,sp,32
    80001cb4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001cb6:	6d28                	ld	a0,88(a0)
    80001cb8:	c509                	beqz	a0,80001cc2 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	d54080e7          	jalr	-684(ra) # 80000a0e <kfree>
  p->trapframe = 0;
    80001cc2:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001cc6:	68a8                	ld	a0,80(s1)
    80001cc8:	c511                	beqz	a0,80001cd4 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001cca:	64ac                	ld	a1,72(s1)
    80001ccc:	00000097          	auipc	ra,0x0
    80001cd0:	f8c080e7          	jalr	-116(ra) # 80001c58 <proc_freepagetable>
  p->pagetable = 0;
    80001cd4:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cd8:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cdc:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001ce0:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001ce4:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ce8:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001cec:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001cf0:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001cf4:	0004ac23          	sw	zero,24(s1)
}
    80001cf8:	60e2                	ld	ra,24(sp)
    80001cfa:	6442                	ld	s0,16(sp)
    80001cfc:	64a2                	ld	s1,8(sp)
    80001cfe:	6105                	add	sp,sp,32
    80001d00:	8082                	ret

0000000080001d02 <allocproc>:
{
    80001d02:	1101                	add	sp,sp,-32
    80001d04:	ec06                	sd	ra,24(sp)
    80001d06:	e822                	sd	s0,16(sp)
    80001d08:	e426                	sd	s1,8(sp)
    80001d0a:	e04a                	sd	s2,0(sp)
    80001d0c:	1000                	add	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d0e:	00010497          	auipc	s1,0x10
    80001d12:	05a48493          	add	s1,s1,90 # 80011d68 <proc>
    80001d16:	00016917          	auipc	s2,0x16
    80001d1a:	a5290913          	add	s2,s2,-1454 # 80017768 <tickslock>
    acquire(&p->lock);
    80001d1e:	8526                	mv	a0,s1
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	edc080e7          	jalr	-292(ra) # 80000bfc <acquire>
    if(p->state == UNUSED) {
    80001d28:	4c9c                	lw	a5,24(s1)
    80001d2a:	cf81                	beqz	a5,80001d42 <allocproc+0x40>
      release(&p->lock);
    80001d2c:	8526                	mv	a0,s1
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	f82080e7          	jalr	-126(ra) # 80000cb0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d36:	16848493          	add	s1,s1,360
    80001d3a:	ff2492e3          	bne	s1,s2,80001d1e <allocproc+0x1c>
  return 0;
    80001d3e:	4481                	li	s1,0
    80001d40:	a0b9                	j	80001d8e <allocproc+0x8c>
  p->pid = allocpid();
    80001d42:	00000097          	auipc	ra,0x0
    80001d46:	e34080e7          	jalr	-460(ra) # 80001b76 <allocpid>
    80001d4a:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d4c:	fffff097          	auipc	ra,0xfffff
    80001d50:	dc0080e7          	jalr	-576(ra) # 80000b0c <kalloc>
    80001d54:	892a                	mv	s2,a0
    80001d56:	eca8                	sd	a0,88(s1)
    80001d58:	c131                	beqz	a0,80001d9c <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001d5a:	8526                	mv	a0,s1
    80001d5c:	00000097          	auipc	ra,0x0
    80001d60:	e60080e7          	jalr	-416(ra) # 80001bbc <proc_pagetable>
    80001d64:	892a                	mv	s2,a0
    80001d66:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d68:	c129                	beqz	a0,80001daa <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001d6a:	07000613          	li	a2,112
    80001d6e:	4581                	li	a1,0
    80001d70:	06048513          	add	a0,s1,96
    80001d74:	fffff097          	auipc	ra,0xfffff
    80001d78:	f84080e7          	jalr	-124(ra) # 80000cf8 <memset>
  p->context.ra = (uint64)forkret;
    80001d7c:	00000797          	auipc	a5,0x0
    80001d80:	db478793          	add	a5,a5,-588 # 80001b30 <forkret>
    80001d84:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d86:	60bc                	ld	a5,64(s1)
    80001d88:	6705                	lui	a4,0x1
    80001d8a:	97ba                	add	a5,a5,a4
    80001d8c:	f4bc                	sd	a5,104(s1)
}
    80001d8e:	8526                	mv	a0,s1
    80001d90:	60e2                	ld	ra,24(sp)
    80001d92:	6442                	ld	s0,16(sp)
    80001d94:	64a2                	ld	s1,8(sp)
    80001d96:	6902                	ld	s2,0(sp)
    80001d98:	6105                	add	sp,sp,32
    80001d9a:	8082                	ret
    release(&p->lock);
    80001d9c:	8526                	mv	a0,s1
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	f12080e7          	jalr	-238(ra) # 80000cb0 <release>
    return 0;
    80001da6:	84ca                	mv	s1,s2
    80001da8:	b7dd                	j	80001d8e <allocproc+0x8c>
    freeproc(p);
    80001daa:	8526                	mv	a0,s1
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	efe080e7          	jalr	-258(ra) # 80001caa <freeproc>
    release(&p->lock);
    80001db4:	8526                	mv	a0,s1
    80001db6:	fffff097          	auipc	ra,0xfffff
    80001dba:	efa080e7          	jalr	-262(ra) # 80000cb0 <release>
    return 0;
    80001dbe:	84ca                	mv	s1,s2
    80001dc0:	b7f9                	j	80001d8e <allocproc+0x8c>

0000000080001dc2 <userinit>:
{
    80001dc2:	1101                	add	sp,sp,-32
    80001dc4:	ec06                	sd	ra,24(sp)
    80001dc6:	e822                	sd	s0,16(sp)
    80001dc8:	e426                	sd	s1,8(sp)
    80001dca:	1000                	add	s0,sp,32
  p = allocproc();
    80001dcc:	00000097          	auipc	ra,0x0
    80001dd0:	f36080e7          	jalr	-202(ra) # 80001d02 <allocproc>
    80001dd4:	84aa                	mv	s1,a0
  initproc = p;
    80001dd6:	00007797          	auipc	a5,0x7
    80001dda:	24a7b123          	sd	a0,578(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001dde:	03400613          	li	a2,52
    80001de2:	00007597          	auipc	a1,0x7
    80001de6:	aae58593          	add	a1,a1,-1362 # 80008890 <initcode>
    80001dea:	6928                	ld	a0,80(a0)
    80001dec:	fffff097          	auipc	ra,0xfffff
    80001df0:	710080e7          	jalr	1808(ra) # 800014fc <uvminit>
  p->sz = PGSIZE;
    80001df4:	6785                	lui	a5,0x1
    80001df6:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001df8:	6cb8                	ld	a4,88(s1)
    80001dfa:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001dfe:	6cb8                	ld	a4,88(s1)
    80001e00:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e02:	4641                	li	a2,16
    80001e04:	00006597          	auipc	a1,0x6
    80001e08:	3b458593          	add	a1,a1,948 # 800081b8 <digits+0x178>
    80001e0c:	15848513          	add	a0,s1,344
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	038080e7          	jalr	56(ra) # 80000e48 <safestrcpy>
  p->cwd = namei("/");
    80001e18:	00006517          	auipc	a0,0x6
    80001e1c:	3b050513          	add	a0,a0,944 # 800081c8 <digits+0x188>
    80001e20:	00002097          	auipc	ra,0x2
    80001e24:	19a080e7          	jalr	410(ra) # 80003fba <namei>
    80001e28:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e2c:	4789                	li	a5,2
    80001e2e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e30:	8526                	mv	a0,s1
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	e7e080e7          	jalr	-386(ra) # 80000cb0 <release>
}
    80001e3a:	60e2                	ld	ra,24(sp)
    80001e3c:	6442                	ld	s0,16(sp)
    80001e3e:	64a2                	ld	s1,8(sp)
    80001e40:	6105                	add	sp,sp,32
    80001e42:	8082                	ret

0000000080001e44 <growproc>:
{
    80001e44:	1101                	add	sp,sp,-32
    80001e46:	ec06                	sd	ra,24(sp)
    80001e48:	e822                	sd	s0,16(sp)
    80001e4a:	e426                	sd	s1,8(sp)
    80001e4c:	e04a                	sd	s2,0(sp)
    80001e4e:	1000                	add	s0,sp,32
    80001e50:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e52:	00000097          	auipc	ra,0x0
    80001e56:	ca6080e7          	jalr	-858(ra) # 80001af8 <myproc>
    80001e5a:	892a                	mv	s2,a0
  sz = p->sz;
    80001e5c:	652c                	ld	a1,72(a0)
    80001e5e:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001e62:	00904f63          	bgtz	s1,80001e80 <growproc+0x3c>
  } else if(n < 0){
    80001e66:	0204cd63          	bltz	s1,80001ea0 <growproc+0x5c>
  p->sz = sz;
    80001e6a:	1782                	sll	a5,a5,0x20
    80001e6c:	9381                	srl	a5,a5,0x20
    80001e6e:	04f93423          	sd	a5,72(s2)
  return 0;
    80001e72:	4501                	li	a0,0
}
    80001e74:	60e2                	ld	ra,24(sp)
    80001e76:	6442                	ld	s0,16(sp)
    80001e78:	64a2                	ld	s1,8(sp)
    80001e7a:	6902                	ld	s2,0(sp)
    80001e7c:	6105                	add	sp,sp,32
    80001e7e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e80:	00f4863b          	addw	a2,s1,a5
    80001e84:	1602                	sll	a2,a2,0x20
    80001e86:	9201                	srl	a2,a2,0x20
    80001e88:	1582                	sll	a1,a1,0x20
    80001e8a:	9181                	srl	a1,a1,0x20
    80001e8c:	6928                	ld	a0,80(a0)
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	728080e7          	jalr	1832(ra) # 800015b6 <uvmalloc>
    80001e96:	0005079b          	sext.w	a5,a0
    80001e9a:	fbe1                	bnez	a5,80001e6a <growproc+0x26>
      return -1;
    80001e9c:	557d                	li	a0,-1
    80001e9e:	bfd9                	j	80001e74 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ea0:	00f4863b          	addw	a2,s1,a5
    80001ea4:	1602                	sll	a2,a2,0x20
    80001ea6:	9201                	srl	a2,a2,0x20
    80001ea8:	1582                	sll	a1,a1,0x20
    80001eaa:	9181                	srl	a1,a1,0x20
    80001eac:	6928                	ld	a0,80(a0)
    80001eae:	fffff097          	auipc	ra,0xfffff
    80001eb2:	6c0080e7          	jalr	1728(ra) # 8000156e <uvmdealloc>
    80001eb6:	0005079b          	sext.w	a5,a0
    80001eba:	bf45                	j	80001e6a <growproc+0x26>

0000000080001ebc <fork>:
{
    80001ebc:	7139                	add	sp,sp,-64
    80001ebe:	fc06                	sd	ra,56(sp)
    80001ec0:	f822                	sd	s0,48(sp)
    80001ec2:	f426                	sd	s1,40(sp)
    80001ec4:	f04a                	sd	s2,32(sp)
    80001ec6:	ec4e                	sd	s3,24(sp)
    80001ec8:	e852                	sd	s4,16(sp)
    80001eca:	e456                	sd	s5,8(sp)
    80001ecc:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001ece:	00000097          	auipc	ra,0x0
    80001ed2:	c2a080e7          	jalr	-982(ra) # 80001af8 <myproc>
    80001ed6:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001ed8:	00000097          	auipc	ra,0x0
    80001edc:	e2a080e7          	jalr	-470(ra) # 80001d02 <allocproc>
    80001ee0:	c17d                	beqz	a0,80001fc6 <fork+0x10a>
    80001ee2:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001ee4:	048ab603          	ld	a2,72(s5)
    80001ee8:	692c                	ld	a1,80(a0)
    80001eea:	050ab503          	ld	a0,80(s5)
    80001eee:	00000097          	auipc	ra,0x0
    80001ef2:	818080e7          	jalr	-2024(ra) # 80001706 <uvmcopy>
    80001ef6:	04054a63          	bltz	a0,80001f4a <fork+0x8e>
  np->sz = p->sz;
    80001efa:	048ab783          	ld	a5,72(s5)
    80001efe:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001f02:	035a3023          	sd	s5,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001f06:	058ab683          	ld	a3,88(s5)
    80001f0a:	87b6                	mv	a5,a3
    80001f0c:	058a3703          	ld	a4,88(s4)
    80001f10:	12068693          	add	a3,a3,288
    80001f14:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f18:	6788                	ld	a0,8(a5)
    80001f1a:	6b8c                	ld	a1,16(a5)
    80001f1c:	6f90                	ld	a2,24(a5)
    80001f1e:	01073023          	sd	a6,0(a4)
    80001f22:	e708                	sd	a0,8(a4)
    80001f24:	eb0c                	sd	a1,16(a4)
    80001f26:	ef10                	sd	a2,24(a4)
    80001f28:	02078793          	add	a5,a5,32
    80001f2c:	02070713          	add	a4,a4,32
    80001f30:	fed792e3          	bne	a5,a3,80001f14 <fork+0x58>
  np->trapframe->a0 = 0;
    80001f34:	058a3783          	ld	a5,88(s4)
    80001f38:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001f3c:	0d0a8493          	add	s1,s5,208
    80001f40:	0d0a0913          	add	s2,s4,208
    80001f44:	150a8993          	add	s3,s5,336
    80001f48:	a00d                	j	80001f6a <fork+0xae>
    freeproc(np);
    80001f4a:	8552                	mv	a0,s4
    80001f4c:	00000097          	auipc	ra,0x0
    80001f50:	d5e080e7          	jalr	-674(ra) # 80001caa <freeproc>
    release(&np->lock);
    80001f54:	8552                	mv	a0,s4
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	d5a080e7          	jalr	-678(ra) # 80000cb0 <release>
    return -1;
    80001f5e:	54fd                	li	s1,-1
    80001f60:	a889                	j	80001fb2 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    80001f62:	04a1                	add	s1,s1,8
    80001f64:	0921                	add	s2,s2,8
    80001f66:	01348b63          	beq	s1,s3,80001f7c <fork+0xc0>
    if(p->ofile[i])
    80001f6a:	6088                	ld	a0,0(s1)
    80001f6c:	d97d                	beqz	a0,80001f62 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f6e:	00002097          	auipc	ra,0x2
    80001f72:	6b4080e7          	jalr	1716(ra) # 80004622 <filedup>
    80001f76:	00a93023          	sd	a0,0(s2)
    80001f7a:	b7e5                	j	80001f62 <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001f7c:	150ab503          	ld	a0,336(s5)
    80001f80:	00002097          	auipc	ra,0x2
    80001f84:	848080e7          	jalr	-1976(ra) # 800037c8 <idup>
    80001f88:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f8c:	4641                	li	a2,16
    80001f8e:	158a8593          	add	a1,s5,344
    80001f92:	158a0513          	add	a0,s4,344
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	eb2080e7          	jalr	-334(ra) # 80000e48 <safestrcpy>
  pid = np->pid;
    80001f9e:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001fa2:	4789                	li	a5,2
    80001fa4:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001fa8:	8552                	mv	a0,s4
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	d06080e7          	jalr	-762(ra) # 80000cb0 <release>
}
    80001fb2:	8526                	mv	a0,s1
    80001fb4:	70e2                	ld	ra,56(sp)
    80001fb6:	7442                	ld	s0,48(sp)
    80001fb8:	74a2                	ld	s1,40(sp)
    80001fba:	7902                	ld	s2,32(sp)
    80001fbc:	69e2                	ld	s3,24(sp)
    80001fbe:	6a42                	ld	s4,16(sp)
    80001fc0:	6aa2                	ld	s5,8(sp)
    80001fc2:	6121                	add	sp,sp,64
    80001fc4:	8082                	ret
    return -1;
    80001fc6:	54fd                	li	s1,-1
    80001fc8:	b7ed                	j	80001fb2 <fork+0xf6>

0000000080001fca <reparent>:
{
    80001fca:	7179                	add	sp,sp,-48
    80001fcc:	f406                	sd	ra,40(sp)
    80001fce:	f022                	sd	s0,32(sp)
    80001fd0:	ec26                	sd	s1,24(sp)
    80001fd2:	e84a                	sd	s2,16(sp)
    80001fd4:	e44e                	sd	s3,8(sp)
    80001fd6:	e052                	sd	s4,0(sp)
    80001fd8:	1800                	add	s0,sp,48
    80001fda:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001fdc:	00010497          	auipc	s1,0x10
    80001fe0:	d8c48493          	add	s1,s1,-628 # 80011d68 <proc>
      pp->parent = initproc;
    80001fe4:	00007a17          	auipc	s4,0x7
    80001fe8:	034a0a13          	add	s4,s4,52 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001fec:	00015997          	auipc	s3,0x15
    80001ff0:	77c98993          	add	s3,s3,1916 # 80017768 <tickslock>
    80001ff4:	a029                	j	80001ffe <reparent+0x34>
    80001ff6:	16848493          	add	s1,s1,360
    80001ffa:	03348363          	beq	s1,s3,80002020 <reparent+0x56>
    if(pp->parent == p){
    80001ffe:	709c                	ld	a5,32(s1)
    80002000:	ff279be3          	bne	a5,s2,80001ff6 <reparent+0x2c>
      acquire(&pp->lock);
    80002004:	8526                	mv	a0,s1
    80002006:	fffff097          	auipc	ra,0xfffff
    8000200a:	bf6080e7          	jalr	-1034(ra) # 80000bfc <acquire>
      pp->parent = initproc;
    8000200e:	000a3783          	ld	a5,0(s4)
    80002012:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80002014:	8526                	mv	a0,s1
    80002016:	fffff097          	auipc	ra,0xfffff
    8000201a:	c9a080e7          	jalr	-870(ra) # 80000cb0 <release>
    8000201e:	bfe1                	j	80001ff6 <reparent+0x2c>
}
    80002020:	70a2                	ld	ra,40(sp)
    80002022:	7402                	ld	s0,32(sp)
    80002024:	64e2                	ld	s1,24(sp)
    80002026:	6942                	ld	s2,16(sp)
    80002028:	69a2                	ld	s3,8(sp)
    8000202a:	6a02                	ld	s4,0(sp)
    8000202c:	6145                	add	sp,sp,48
    8000202e:	8082                	ret

0000000080002030 <scheduler>:
{
    80002030:	715d                	add	sp,sp,-80
    80002032:	e486                	sd	ra,72(sp)
    80002034:	e0a2                	sd	s0,64(sp)
    80002036:	fc26                	sd	s1,56(sp)
    80002038:	f84a                	sd	s2,48(sp)
    8000203a:	f44e                	sd	s3,40(sp)
    8000203c:	f052                	sd	s4,32(sp)
    8000203e:	ec56                	sd	s5,24(sp)
    80002040:	e85a                	sd	s6,16(sp)
    80002042:	e45e                	sd	s7,8(sp)
    80002044:	e062                	sd	s8,0(sp)
    80002046:	0880                	add	s0,sp,80
    80002048:	8792                	mv	a5,tp
  int id = r_tp();
    8000204a:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000204c:	00779b93          	sll	s7,a5,0x7
    80002050:	00010717          	auipc	a4,0x10
    80002054:	90070713          	add	a4,a4,-1792 # 80011950 <pid_lock>
    80002058:	975e                	add	a4,a4,s7
    8000205a:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    8000205e:	00010717          	auipc	a4,0x10
    80002062:	91270713          	add	a4,a4,-1774 # 80011970 <cpus+0x8>
    80002066:	9bba                	add	s7,s7,a4
    int nproc = 0;
    80002068:	4c01                	li	s8,0
      if(p->state == RUNNABLE) {
    8000206a:	4a09                	li	s4,2
        c->proc = p;
    8000206c:	079e                	sll	a5,a5,0x7
    8000206e:	00010a97          	auipc	s5,0x10
    80002072:	8e2a8a93          	add	s5,s5,-1822 # 80011950 <pid_lock>
    80002076:	9abe                	add	s5,s5,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002078:	00015997          	auipc	s3,0x15
    8000207c:	6f098993          	add	s3,s3,1776 # 80017768 <tickslock>
    80002080:	a8a1                	j	800020d8 <scheduler+0xa8>
      release(&p->lock);
    80002082:	8526                	mv	a0,s1
    80002084:	fffff097          	auipc	ra,0xfffff
    80002088:	c2c080e7          	jalr	-980(ra) # 80000cb0 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000208c:	16848493          	add	s1,s1,360
    80002090:	03348a63          	beq	s1,s3,800020c4 <scheduler+0x94>
      acquire(&p->lock);
    80002094:	8526                	mv	a0,s1
    80002096:	fffff097          	auipc	ra,0xfffff
    8000209a:	b66080e7          	jalr	-1178(ra) # 80000bfc <acquire>
      if(p->state != UNUSED) {
    8000209e:	4c9c                	lw	a5,24(s1)
    800020a0:	d3ed                	beqz	a5,80002082 <scheduler+0x52>
        nproc++;
    800020a2:	2905                	addw	s2,s2,1
      if(p->state == RUNNABLE) {
    800020a4:	fd479fe3          	bne	a5,s4,80002082 <scheduler+0x52>
        p->state = RUNNING;
    800020a8:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    800020ac:	009abc23          	sd	s1,24(s5)
        swtch(&c->context, &p->context);
    800020b0:	06048593          	add	a1,s1,96
    800020b4:	855e                	mv	a0,s7
    800020b6:	00000097          	auipc	ra,0x0
    800020ba:	60e080e7          	jalr	1550(ra) # 800026c4 <swtch>
        c->proc = 0;
    800020be:	000abc23          	sd	zero,24(s5)
    800020c2:	b7c1                	j	80002082 <scheduler+0x52>
    if(nproc <= 2) {   // only init and sh exist
    800020c4:	012a4a63          	blt	s4,s2,800020d8 <scheduler+0xa8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020c8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020cc:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020d0:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800020d4:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020d8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020dc:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020e0:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    800020e4:	8962                	mv	s2,s8
    for(p = proc; p < &proc[NPROC]; p++) {
    800020e6:	00010497          	auipc	s1,0x10
    800020ea:	c8248493          	add	s1,s1,-894 # 80011d68 <proc>
        p->state = RUNNING;
    800020ee:	4b0d                	li	s6,3
    800020f0:	b755                	j	80002094 <scheduler+0x64>

00000000800020f2 <sched>:
{
    800020f2:	7179                	add	sp,sp,-48
    800020f4:	f406                	sd	ra,40(sp)
    800020f6:	f022                	sd	s0,32(sp)
    800020f8:	ec26                	sd	s1,24(sp)
    800020fa:	e84a                	sd	s2,16(sp)
    800020fc:	e44e                	sd	s3,8(sp)
    800020fe:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    80002100:	00000097          	auipc	ra,0x0
    80002104:	9f8080e7          	jalr	-1544(ra) # 80001af8 <myproc>
    80002108:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	a78080e7          	jalr	-1416(ra) # 80000b82 <holding>
    80002112:	c93d                	beqz	a0,80002188 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002114:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002116:	2781                	sext.w	a5,a5
    80002118:	079e                	sll	a5,a5,0x7
    8000211a:	00010717          	auipc	a4,0x10
    8000211e:	83670713          	add	a4,a4,-1994 # 80011950 <pid_lock>
    80002122:	97ba                	add	a5,a5,a4
    80002124:	0907a703          	lw	a4,144(a5)
    80002128:	4785                	li	a5,1
    8000212a:	06f71763          	bne	a4,a5,80002198 <sched+0xa6>
  if(p->state == RUNNING)
    8000212e:	4c98                	lw	a4,24(s1)
    80002130:	478d                	li	a5,3
    80002132:	06f70b63          	beq	a4,a5,800021a8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002136:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000213a:	8b89                	and	a5,a5,2
  if(intr_get())
    8000213c:	efb5                	bnez	a5,800021b8 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000213e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002140:	00010917          	auipc	s2,0x10
    80002144:	81090913          	add	s2,s2,-2032 # 80011950 <pid_lock>
    80002148:	2781                	sext.w	a5,a5
    8000214a:	079e                	sll	a5,a5,0x7
    8000214c:	97ca                	add	a5,a5,s2
    8000214e:	0947a983          	lw	s3,148(a5)
    80002152:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002154:	2781                	sext.w	a5,a5
    80002156:	079e                	sll	a5,a5,0x7
    80002158:	00010597          	auipc	a1,0x10
    8000215c:	81858593          	add	a1,a1,-2024 # 80011970 <cpus+0x8>
    80002160:	95be                	add	a1,a1,a5
    80002162:	06048513          	add	a0,s1,96
    80002166:	00000097          	auipc	ra,0x0
    8000216a:	55e080e7          	jalr	1374(ra) # 800026c4 <swtch>
    8000216e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002170:	2781                	sext.w	a5,a5
    80002172:	079e                	sll	a5,a5,0x7
    80002174:	993e                	add	s2,s2,a5
    80002176:	09392a23          	sw	s3,148(s2)
}
    8000217a:	70a2                	ld	ra,40(sp)
    8000217c:	7402                	ld	s0,32(sp)
    8000217e:	64e2                	ld	s1,24(sp)
    80002180:	6942                	ld	s2,16(sp)
    80002182:	69a2                	ld	s3,8(sp)
    80002184:	6145                	add	sp,sp,48
    80002186:	8082                	ret
    panic("sched p->lock");
    80002188:	00006517          	auipc	a0,0x6
    8000218c:	04850513          	add	a0,a0,72 # 800081d0 <digits+0x190>
    80002190:	ffffe097          	auipc	ra,0xffffe
    80002194:	3b2080e7          	jalr	946(ra) # 80000542 <panic>
    panic("sched locks");
    80002198:	00006517          	auipc	a0,0x6
    8000219c:	04850513          	add	a0,a0,72 # 800081e0 <digits+0x1a0>
    800021a0:	ffffe097          	auipc	ra,0xffffe
    800021a4:	3a2080e7          	jalr	930(ra) # 80000542 <panic>
    panic("sched running");
    800021a8:	00006517          	auipc	a0,0x6
    800021ac:	04850513          	add	a0,a0,72 # 800081f0 <digits+0x1b0>
    800021b0:	ffffe097          	auipc	ra,0xffffe
    800021b4:	392080e7          	jalr	914(ra) # 80000542 <panic>
    panic("sched interruptible");
    800021b8:	00006517          	auipc	a0,0x6
    800021bc:	04850513          	add	a0,a0,72 # 80008200 <digits+0x1c0>
    800021c0:	ffffe097          	auipc	ra,0xffffe
    800021c4:	382080e7          	jalr	898(ra) # 80000542 <panic>

00000000800021c8 <exit>:
{
    800021c8:	7179                	add	sp,sp,-48
    800021ca:	f406                	sd	ra,40(sp)
    800021cc:	f022                	sd	s0,32(sp)
    800021ce:	ec26                	sd	s1,24(sp)
    800021d0:	e84a                	sd	s2,16(sp)
    800021d2:	e44e                	sd	s3,8(sp)
    800021d4:	e052                	sd	s4,0(sp)
    800021d6:	1800                	add	s0,sp,48
    800021d8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021da:	00000097          	auipc	ra,0x0
    800021de:	91e080e7          	jalr	-1762(ra) # 80001af8 <myproc>
    800021e2:	89aa                	mv	s3,a0
  if(p == initproc)
    800021e4:	00007797          	auipc	a5,0x7
    800021e8:	e347b783          	ld	a5,-460(a5) # 80009018 <initproc>
    800021ec:	0d050493          	add	s1,a0,208
    800021f0:	15050913          	add	s2,a0,336
    800021f4:	02a79363          	bne	a5,a0,8000221a <exit+0x52>
    panic("init exiting");
    800021f8:	00006517          	auipc	a0,0x6
    800021fc:	02050513          	add	a0,a0,32 # 80008218 <digits+0x1d8>
    80002200:	ffffe097          	auipc	ra,0xffffe
    80002204:	342080e7          	jalr	834(ra) # 80000542 <panic>
      fileclose(f);
    80002208:	00002097          	auipc	ra,0x2
    8000220c:	46c080e7          	jalr	1132(ra) # 80004674 <fileclose>
      p->ofile[fd] = 0;
    80002210:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002214:	04a1                	add	s1,s1,8
    80002216:	01248563          	beq	s1,s2,80002220 <exit+0x58>
    if(p->ofile[fd]){
    8000221a:	6088                	ld	a0,0(s1)
    8000221c:	f575                	bnez	a0,80002208 <exit+0x40>
    8000221e:	bfdd                	j	80002214 <exit+0x4c>
  begin_op();
    80002220:	00002097          	auipc	ra,0x2
    80002224:	f8a080e7          	jalr	-118(ra) # 800041aa <begin_op>
  iput(p->cwd);
    80002228:	1509b503          	ld	a0,336(s3)
    8000222c:	00001097          	auipc	ra,0x1
    80002230:	794080e7          	jalr	1940(ra) # 800039c0 <iput>
  end_op();
    80002234:	00002097          	auipc	ra,0x2
    80002238:	ff0080e7          	jalr	-16(ra) # 80004224 <end_op>
  p->cwd = 0;
    8000223c:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002240:	00007497          	auipc	s1,0x7
    80002244:	dd848493          	add	s1,s1,-552 # 80009018 <initproc>
    80002248:	6088                	ld	a0,0(s1)
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	9b2080e7          	jalr	-1614(ra) # 80000bfc <acquire>
  wakeup1(initproc);
    80002252:	6088                	ld	a0,0(s1)
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	764080e7          	jalr	1892(ra) # 800019b8 <wakeup1>
  release(&initproc->lock);
    8000225c:	6088                	ld	a0,0(s1)
    8000225e:	fffff097          	auipc	ra,0xfffff
    80002262:	a52080e7          	jalr	-1454(ra) # 80000cb0 <release>
  acquire(&p->lock);
    80002266:	854e                	mv	a0,s3
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	994080e7          	jalr	-1644(ra) # 80000bfc <acquire>
  struct proc *original_parent = p->parent;
    80002270:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002274:	854e                	mv	a0,s3
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	a3a080e7          	jalr	-1478(ra) # 80000cb0 <release>
  acquire(&original_parent->lock);
    8000227e:	8526                	mv	a0,s1
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	97c080e7          	jalr	-1668(ra) # 80000bfc <acquire>
  acquire(&p->lock);
    80002288:	854e                	mv	a0,s3
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	972080e7          	jalr	-1678(ra) # 80000bfc <acquire>
  reparent(p);
    80002292:	854e                	mv	a0,s3
    80002294:	00000097          	auipc	ra,0x0
    80002298:	d36080e7          	jalr	-714(ra) # 80001fca <reparent>
  wakeup1(original_parent);
    8000229c:	8526                	mv	a0,s1
    8000229e:	fffff097          	auipc	ra,0xfffff
    800022a2:	71a080e7          	jalr	1818(ra) # 800019b8 <wakeup1>
  p->xstate = status;
    800022a6:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800022aa:	4791                	li	a5,4
    800022ac:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800022b0:	8526                	mv	a0,s1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9fe080e7          	jalr	-1538(ra) # 80000cb0 <release>
  sched();
    800022ba:	00000097          	auipc	ra,0x0
    800022be:	e38080e7          	jalr	-456(ra) # 800020f2 <sched>
  panic("zombie exit");
    800022c2:	00006517          	auipc	a0,0x6
    800022c6:	f6650513          	add	a0,a0,-154 # 80008228 <digits+0x1e8>
    800022ca:	ffffe097          	auipc	ra,0xffffe
    800022ce:	278080e7          	jalr	632(ra) # 80000542 <panic>

00000000800022d2 <yield>:
{
    800022d2:	1101                	add	sp,sp,-32
    800022d4:	ec06                	sd	ra,24(sp)
    800022d6:	e822                	sd	s0,16(sp)
    800022d8:	e426                	sd	s1,8(sp)
    800022da:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    800022dc:	00000097          	auipc	ra,0x0
    800022e0:	81c080e7          	jalr	-2020(ra) # 80001af8 <myproc>
    800022e4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	916080e7          	jalr	-1770(ra) # 80000bfc <acquire>
  p->state = RUNNABLE;
    800022ee:	4789                	li	a5,2
    800022f0:	cc9c                	sw	a5,24(s1)
  sched();
    800022f2:	00000097          	auipc	ra,0x0
    800022f6:	e00080e7          	jalr	-512(ra) # 800020f2 <sched>
  release(&p->lock);
    800022fa:	8526                	mv	a0,s1
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	9b4080e7          	jalr	-1612(ra) # 80000cb0 <release>
}
    80002304:	60e2                	ld	ra,24(sp)
    80002306:	6442                	ld	s0,16(sp)
    80002308:	64a2                	ld	s1,8(sp)
    8000230a:	6105                	add	sp,sp,32
    8000230c:	8082                	ret

000000008000230e <sleep>:
{
    8000230e:	7179                	add	sp,sp,-48
    80002310:	f406                	sd	ra,40(sp)
    80002312:	f022                	sd	s0,32(sp)
    80002314:	ec26                	sd	s1,24(sp)
    80002316:	e84a                	sd	s2,16(sp)
    80002318:	e44e                	sd	s3,8(sp)
    8000231a:	1800                	add	s0,sp,48
    8000231c:	89aa                	mv	s3,a0
    8000231e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	7d8080e7          	jalr	2008(ra) # 80001af8 <myproc>
    80002328:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000232a:	05250663          	beq	a0,s2,80002376 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	8ce080e7          	jalr	-1842(ra) # 80000bfc <acquire>
    release(lk);
    80002336:	854a                	mv	a0,s2
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	978080e7          	jalr	-1672(ra) # 80000cb0 <release>
  p->chan = chan;
    80002340:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002344:	4785                	li	a5,1
    80002346:	cc9c                	sw	a5,24(s1)
  sched();
    80002348:	00000097          	auipc	ra,0x0
    8000234c:	daa080e7          	jalr	-598(ra) # 800020f2 <sched>
  p->chan = 0;
    80002350:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002354:	8526                	mv	a0,s1
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	95a080e7          	jalr	-1702(ra) # 80000cb0 <release>
    acquire(lk);
    8000235e:	854a                	mv	a0,s2
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	89c080e7          	jalr	-1892(ra) # 80000bfc <acquire>
}
    80002368:	70a2                	ld	ra,40(sp)
    8000236a:	7402                	ld	s0,32(sp)
    8000236c:	64e2                	ld	s1,24(sp)
    8000236e:	6942                	ld	s2,16(sp)
    80002370:	69a2                	ld	s3,8(sp)
    80002372:	6145                	add	sp,sp,48
    80002374:	8082                	ret
  p->chan = chan;
    80002376:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000237a:	4785                	li	a5,1
    8000237c:	cd1c                	sw	a5,24(a0)
  sched();
    8000237e:	00000097          	auipc	ra,0x0
    80002382:	d74080e7          	jalr	-652(ra) # 800020f2 <sched>
  p->chan = 0;
    80002386:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000238a:	bff9                	j	80002368 <sleep+0x5a>

000000008000238c <wait>:
{
    8000238c:	715d                	add	sp,sp,-80
    8000238e:	e486                	sd	ra,72(sp)
    80002390:	e0a2                	sd	s0,64(sp)
    80002392:	fc26                	sd	s1,56(sp)
    80002394:	f84a                	sd	s2,48(sp)
    80002396:	f44e                	sd	s3,40(sp)
    80002398:	f052                	sd	s4,32(sp)
    8000239a:	ec56                	sd	s5,24(sp)
    8000239c:	e85a                	sd	s6,16(sp)
    8000239e:	e45e                	sd	s7,8(sp)
    800023a0:	0880                	add	s0,sp,80
    800023a2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	754080e7          	jalr	1876(ra) # 80001af8 <myproc>
    800023ac:	892a                	mv	s2,a0
  acquire(&p->lock);
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	84e080e7          	jalr	-1970(ra) # 80000bfc <acquire>
    havekids = 0;
    800023b6:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800023b8:	4a11                	li	s4,4
        havekids = 1;
    800023ba:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800023bc:	00015997          	auipc	s3,0x15
    800023c0:	3ac98993          	add	s3,s3,940 # 80017768 <tickslock>
    800023c4:	a845                	j	80002474 <wait+0xe8>
          pid = np->pid;
    800023c6:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023ca:	000b0e63          	beqz	s6,800023e6 <wait+0x5a>
    800023ce:	4691                	li	a3,4
    800023d0:	03448613          	add	a2,s1,52
    800023d4:	85da                	mv	a1,s6
    800023d6:	05093503          	ld	a0,80(s2)
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	414080e7          	jalr	1044(ra) # 800017ee <copyout>
    800023e2:	02054d63          	bltz	a0,8000241c <wait+0x90>
          freeproc(np);
    800023e6:	8526                	mv	a0,s1
    800023e8:	00000097          	auipc	ra,0x0
    800023ec:	8c2080e7          	jalr	-1854(ra) # 80001caa <freeproc>
          release(&np->lock);
    800023f0:	8526                	mv	a0,s1
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	8be080e7          	jalr	-1858(ra) # 80000cb0 <release>
          release(&p->lock);
    800023fa:	854a                	mv	a0,s2
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	8b4080e7          	jalr	-1868(ra) # 80000cb0 <release>
}
    80002404:	854e                	mv	a0,s3
    80002406:	60a6                	ld	ra,72(sp)
    80002408:	6406                	ld	s0,64(sp)
    8000240a:	74e2                	ld	s1,56(sp)
    8000240c:	7942                	ld	s2,48(sp)
    8000240e:	79a2                	ld	s3,40(sp)
    80002410:	7a02                	ld	s4,32(sp)
    80002412:	6ae2                	ld	s5,24(sp)
    80002414:	6b42                	ld	s6,16(sp)
    80002416:	6ba2                	ld	s7,8(sp)
    80002418:	6161                	add	sp,sp,80
    8000241a:	8082                	ret
            release(&np->lock);
    8000241c:	8526                	mv	a0,s1
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	892080e7          	jalr	-1902(ra) # 80000cb0 <release>
            release(&p->lock);
    80002426:	854a                	mv	a0,s2
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	888080e7          	jalr	-1912(ra) # 80000cb0 <release>
            return -1;
    80002430:	59fd                	li	s3,-1
    80002432:	bfc9                	j	80002404 <wait+0x78>
    for(np = proc; np < &proc[NPROC]; np++){
    80002434:	16848493          	add	s1,s1,360
    80002438:	03348463          	beq	s1,s3,80002460 <wait+0xd4>
      if(np->parent == p){
    8000243c:	709c                	ld	a5,32(s1)
    8000243e:	ff279be3          	bne	a5,s2,80002434 <wait+0xa8>
        acquire(&np->lock);
    80002442:	8526                	mv	a0,s1
    80002444:	ffffe097          	auipc	ra,0xffffe
    80002448:	7b8080e7          	jalr	1976(ra) # 80000bfc <acquire>
        if(np->state == ZOMBIE){
    8000244c:	4c9c                	lw	a5,24(s1)
    8000244e:	f7478ce3          	beq	a5,s4,800023c6 <wait+0x3a>
        release(&np->lock);
    80002452:	8526                	mv	a0,s1
    80002454:	fffff097          	auipc	ra,0xfffff
    80002458:	85c080e7          	jalr	-1956(ra) # 80000cb0 <release>
        havekids = 1;
    8000245c:	8756                	mv	a4,s5
    8000245e:	bfd9                	j	80002434 <wait+0xa8>
    if(!havekids || p->killed){
    80002460:	c305                	beqz	a4,80002480 <wait+0xf4>
    80002462:	03092783          	lw	a5,48(s2)
    80002466:	ef89                	bnez	a5,80002480 <wait+0xf4>
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002468:	85ca                	mv	a1,s2
    8000246a:	854a                	mv	a0,s2
    8000246c:	00000097          	auipc	ra,0x0
    80002470:	ea2080e7          	jalr	-350(ra) # 8000230e <sleep>
    havekids = 0;
    80002474:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002476:	00010497          	auipc	s1,0x10
    8000247a:	8f248493          	add	s1,s1,-1806 # 80011d68 <proc>
    8000247e:	bf7d                	j	8000243c <wait+0xb0>
      release(&p->lock);
    80002480:	854a                	mv	a0,s2
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	82e080e7          	jalr	-2002(ra) # 80000cb0 <release>
      return -1;
    8000248a:	59fd                	li	s3,-1
    8000248c:	bfa5                	j	80002404 <wait+0x78>

000000008000248e <wakeup>:
{
    8000248e:	7139                	add	sp,sp,-64
    80002490:	fc06                	sd	ra,56(sp)
    80002492:	f822                	sd	s0,48(sp)
    80002494:	f426                	sd	s1,40(sp)
    80002496:	f04a                	sd	s2,32(sp)
    80002498:	ec4e                	sd	s3,24(sp)
    8000249a:	e852                	sd	s4,16(sp)
    8000249c:	e456                	sd	s5,8(sp)
    8000249e:	0080                	add	s0,sp,64
    800024a0:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800024a2:	00010497          	auipc	s1,0x10
    800024a6:	8c648493          	add	s1,s1,-1850 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800024aa:	4985                	li	s3,1
      p->state = RUNNABLE;
    800024ac:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800024ae:	00015917          	auipc	s2,0x15
    800024b2:	2ba90913          	add	s2,s2,698 # 80017768 <tickslock>
    800024b6:	a811                	j	800024ca <wakeup+0x3c>
    release(&p->lock);
    800024b8:	8526                	mv	a0,s1
    800024ba:	ffffe097          	auipc	ra,0xffffe
    800024be:	7f6080e7          	jalr	2038(ra) # 80000cb0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024c2:	16848493          	add	s1,s1,360
    800024c6:	03248063          	beq	s1,s2,800024e6 <wakeup+0x58>
    acquire(&p->lock);
    800024ca:	8526                	mv	a0,s1
    800024cc:	ffffe097          	auipc	ra,0xffffe
    800024d0:	730080e7          	jalr	1840(ra) # 80000bfc <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800024d4:	4c9c                	lw	a5,24(s1)
    800024d6:	ff3791e3          	bne	a5,s3,800024b8 <wakeup+0x2a>
    800024da:	749c                	ld	a5,40(s1)
    800024dc:	fd479ee3          	bne	a5,s4,800024b8 <wakeup+0x2a>
      p->state = RUNNABLE;
    800024e0:	0154ac23          	sw	s5,24(s1)
    800024e4:	bfd1                	j	800024b8 <wakeup+0x2a>
}
    800024e6:	70e2                	ld	ra,56(sp)
    800024e8:	7442                	ld	s0,48(sp)
    800024ea:	74a2                	ld	s1,40(sp)
    800024ec:	7902                	ld	s2,32(sp)
    800024ee:	69e2                	ld	s3,24(sp)
    800024f0:	6a42                	ld	s4,16(sp)
    800024f2:	6aa2                	ld	s5,8(sp)
    800024f4:	6121                	add	sp,sp,64
    800024f6:	8082                	ret

00000000800024f8 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024f8:	7179                	add	sp,sp,-48
    800024fa:	f406                	sd	ra,40(sp)
    800024fc:	f022                	sd	s0,32(sp)
    800024fe:	ec26                	sd	s1,24(sp)
    80002500:	e84a                	sd	s2,16(sp)
    80002502:	e44e                	sd	s3,8(sp)
    80002504:	1800                	add	s0,sp,48
    80002506:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002508:	00010497          	auipc	s1,0x10
    8000250c:	86048493          	add	s1,s1,-1952 # 80011d68 <proc>
    80002510:	00015997          	auipc	s3,0x15
    80002514:	25898993          	add	s3,s3,600 # 80017768 <tickslock>
    acquire(&p->lock);
    80002518:	8526                	mv	a0,s1
    8000251a:	ffffe097          	auipc	ra,0xffffe
    8000251e:	6e2080e7          	jalr	1762(ra) # 80000bfc <acquire>
    if(p->pid == pid){
    80002522:	5c9c                	lw	a5,56(s1)
    80002524:	01278d63          	beq	a5,s2,8000253e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002528:	8526                	mv	a0,s1
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	786080e7          	jalr	1926(ra) # 80000cb0 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002532:	16848493          	add	s1,s1,360
    80002536:	ff3491e3          	bne	s1,s3,80002518 <kill+0x20>
  }
  return -1;
    8000253a:	557d                	li	a0,-1
    8000253c:	a821                	j	80002554 <kill+0x5c>
      p->killed = 1;
    8000253e:	4785                	li	a5,1
    80002540:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002542:	4c98                	lw	a4,24(s1)
    80002544:	00f70f63          	beq	a4,a5,80002562 <kill+0x6a>
      release(&p->lock);
    80002548:	8526                	mv	a0,s1
    8000254a:	ffffe097          	auipc	ra,0xffffe
    8000254e:	766080e7          	jalr	1894(ra) # 80000cb0 <release>
      return 0;
    80002552:	4501                	li	a0,0
}
    80002554:	70a2                	ld	ra,40(sp)
    80002556:	7402                	ld	s0,32(sp)
    80002558:	64e2                	ld	s1,24(sp)
    8000255a:	6942                	ld	s2,16(sp)
    8000255c:	69a2                	ld	s3,8(sp)
    8000255e:	6145                	add	sp,sp,48
    80002560:	8082                	ret
        p->state = RUNNABLE;
    80002562:	4789                	li	a5,2
    80002564:	cc9c                	sw	a5,24(s1)
    80002566:	b7cd                	j	80002548 <kill+0x50>

0000000080002568 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002568:	7179                	add	sp,sp,-48
    8000256a:	f406                	sd	ra,40(sp)
    8000256c:	f022                	sd	s0,32(sp)
    8000256e:	ec26                	sd	s1,24(sp)
    80002570:	e84a                	sd	s2,16(sp)
    80002572:	e44e                	sd	s3,8(sp)
    80002574:	e052                	sd	s4,0(sp)
    80002576:	1800                	add	s0,sp,48
    80002578:	84aa                	mv	s1,a0
    8000257a:	892e                	mv	s2,a1
    8000257c:	89b2                	mv	s3,a2
    8000257e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002580:	fffff097          	auipc	ra,0xfffff
    80002584:	578080e7          	jalr	1400(ra) # 80001af8 <myproc>
  if(user_dst){
    80002588:	c08d                	beqz	s1,800025aa <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000258a:	86d2                	mv	a3,s4
    8000258c:	864e                	mv	a2,s3
    8000258e:	85ca                	mv	a1,s2
    80002590:	6928                	ld	a0,80(a0)
    80002592:	fffff097          	auipc	ra,0xfffff
    80002596:	25c080e7          	jalr	604(ra) # 800017ee <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000259a:	70a2                	ld	ra,40(sp)
    8000259c:	7402                	ld	s0,32(sp)
    8000259e:	64e2                	ld	s1,24(sp)
    800025a0:	6942                	ld	s2,16(sp)
    800025a2:	69a2                	ld	s3,8(sp)
    800025a4:	6a02                	ld	s4,0(sp)
    800025a6:	6145                	add	sp,sp,48
    800025a8:	8082                	ret
    memmove((char *)dst, src, len);
    800025aa:	000a061b          	sext.w	a2,s4
    800025ae:	85ce                	mv	a1,s3
    800025b0:	854a                	mv	a0,s2
    800025b2:	ffffe097          	auipc	ra,0xffffe
    800025b6:	7a2080e7          	jalr	1954(ra) # 80000d54 <memmove>
    return 0;
    800025ba:	8526                	mv	a0,s1
    800025bc:	bff9                	j	8000259a <either_copyout+0x32>

00000000800025be <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025be:	7179                	add	sp,sp,-48
    800025c0:	f406                	sd	ra,40(sp)
    800025c2:	f022                	sd	s0,32(sp)
    800025c4:	ec26                	sd	s1,24(sp)
    800025c6:	e84a                	sd	s2,16(sp)
    800025c8:	e44e                	sd	s3,8(sp)
    800025ca:	e052                	sd	s4,0(sp)
    800025cc:	1800                	add	s0,sp,48
    800025ce:	892a                	mv	s2,a0
    800025d0:	84ae                	mv	s1,a1
    800025d2:	89b2                	mv	s3,a2
    800025d4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025d6:	fffff097          	auipc	ra,0xfffff
    800025da:	522080e7          	jalr	1314(ra) # 80001af8 <myproc>
  if(user_src){
    800025de:	c08d                	beqz	s1,80002600 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025e0:	86d2                	mv	a3,s4
    800025e2:	864e                	mv	a2,s3
    800025e4:	85ca                	mv	a1,s2
    800025e6:	6928                	ld	a0,80(a0)
    800025e8:	fffff097          	auipc	ra,0xfffff
    800025ec:	292080e7          	jalr	658(ra) # 8000187a <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025f0:	70a2                	ld	ra,40(sp)
    800025f2:	7402                	ld	s0,32(sp)
    800025f4:	64e2                	ld	s1,24(sp)
    800025f6:	6942                	ld	s2,16(sp)
    800025f8:	69a2                	ld	s3,8(sp)
    800025fa:	6a02                	ld	s4,0(sp)
    800025fc:	6145                	add	sp,sp,48
    800025fe:	8082                	ret
    memmove(dst, (char*)src, len);
    80002600:	000a061b          	sext.w	a2,s4
    80002604:	85ce                	mv	a1,s3
    80002606:	854a                	mv	a0,s2
    80002608:	ffffe097          	auipc	ra,0xffffe
    8000260c:	74c080e7          	jalr	1868(ra) # 80000d54 <memmove>
    return 0;
    80002610:	8526                	mv	a0,s1
    80002612:	bff9                	j	800025f0 <either_copyin+0x32>

0000000080002614 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002614:	715d                	add	sp,sp,-80
    80002616:	e486                	sd	ra,72(sp)
    80002618:	e0a2                	sd	s0,64(sp)
    8000261a:	fc26                	sd	s1,56(sp)
    8000261c:	f84a                	sd	s2,48(sp)
    8000261e:	f44e                	sd	s3,40(sp)
    80002620:	f052                	sd	s4,32(sp)
    80002622:	ec56                	sd	s5,24(sp)
    80002624:	e85a                	sd	s6,16(sp)
    80002626:	e45e                	sd	s7,8(sp)
    80002628:	0880                	add	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000262a:	00006517          	auipc	a0,0x6
    8000262e:	a9e50513          	add	a0,a0,-1378 # 800080c8 <digits+0x88>
    80002632:	ffffe097          	auipc	ra,0xffffe
    80002636:	f5a080e7          	jalr	-166(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000263a:	00010497          	auipc	s1,0x10
    8000263e:	88648493          	add	s1,s1,-1914 # 80011ec0 <proc+0x158>
    80002642:	00015917          	auipc	s2,0x15
    80002646:	27e90913          	add	s2,s2,638 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000264a:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000264c:	00006997          	auipc	s3,0x6
    80002650:	bec98993          	add	s3,s3,-1044 # 80008238 <digits+0x1f8>
    printf("%d %s %s", p->pid, state, p->name);
    80002654:	00006a97          	auipc	s5,0x6
    80002658:	beca8a93          	add	s5,s5,-1044 # 80008240 <digits+0x200>
    printf("\n");
    8000265c:	00006a17          	auipc	s4,0x6
    80002660:	a6ca0a13          	add	s4,s4,-1428 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002664:	00006b97          	auipc	s7,0x6
    80002668:	c14b8b93          	add	s7,s7,-1004 # 80008278 <states.0>
    8000266c:	a00d                	j	8000268e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000266e:	ee06a583          	lw	a1,-288(a3)
    80002672:	8556                	mv	a0,s5
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	f18080e7          	jalr	-232(ra) # 8000058c <printf>
    printf("\n");
    8000267c:	8552                	mv	a0,s4
    8000267e:	ffffe097          	auipc	ra,0xffffe
    80002682:	f0e080e7          	jalr	-242(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002686:	16848493          	add	s1,s1,360
    8000268a:	03248263          	beq	s1,s2,800026ae <procdump+0x9a>
    if(p->state == UNUSED)
    8000268e:	86a6                	mv	a3,s1
    80002690:	ec04a783          	lw	a5,-320(s1)
    80002694:	dbed                	beqz	a5,80002686 <procdump+0x72>
      state = "???";
    80002696:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002698:	fcfb6be3          	bltu	s6,a5,8000266e <procdump+0x5a>
    8000269c:	02079713          	sll	a4,a5,0x20
    800026a0:	01d75793          	srl	a5,a4,0x1d
    800026a4:	97de                	add	a5,a5,s7
    800026a6:	6390                	ld	a2,0(a5)
    800026a8:	f279                	bnez	a2,8000266e <procdump+0x5a>
      state = "???";
    800026aa:	864e                	mv	a2,s3
    800026ac:	b7c9                	j	8000266e <procdump+0x5a>
  }
}
    800026ae:	60a6                	ld	ra,72(sp)
    800026b0:	6406                	ld	s0,64(sp)
    800026b2:	74e2                	ld	s1,56(sp)
    800026b4:	7942                	ld	s2,48(sp)
    800026b6:	79a2                	ld	s3,40(sp)
    800026b8:	7a02                	ld	s4,32(sp)
    800026ba:	6ae2                	ld	s5,24(sp)
    800026bc:	6b42                	ld	s6,16(sp)
    800026be:	6ba2                	ld	s7,8(sp)
    800026c0:	6161                	add	sp,sp,80
    800026c2:	8082                	ret

00000000800026c4 <swtch>:
    800026c4:	00153023          	sd	ra,0(a0)
    800026c8:	00253423          	sd	sp,8(a0)
    800026cc:	e900                	sd	s0,16(a0)
    800026ce:	ed04                	sd	s1,24(a0)
    800026d0:	03253023          	sd	s2,32(a0)
    800026d4:	03353423          	sd	s3,40(a0)
    800026d8:	03453823          	sd	s4,48(a0)
    800026dc:	03553c23          	sd	s5,56(a0)
    800026e0:	05653023          	sd	s6,64(a0)
    800026e4:	05753423          	sd	s7,72(a0)
    800026e8:	05853823          	sd	s8,80(a0)
    800026ec:	05953c23          	sd	s9,88(a0)
    800026f0:	07a53023          	sd	s10,96(a0)
    800026f4:	07b53423          	sd	s11,104(a0)
    800026f8:	0005b083          	ld	ra,0(a1)
    800026fc:	0085b103          	ld	sp,8(a1)
    80002700:	6980                	ld	s0,16(a1)
    80002702:	6d84                	ld	s1,24(a1)
    80002704:	0205b903          	ld	s2,32(a1)
    80002708:	0285b983          	ld	s3,40(a1)
    8000270c:	0305ba03          	ld	s4,48(a1)
    80002710:	0385ba83          	ld	s5,56(a1)
    80002714:	0405bb03          	ld	s6,64(a1)
    80002718:	0485bb83          	ld	s7,72(a1)
    8000271c:	0505bc03          	ld	s8,80(a1)
    80002720:	0585bc83          	ld	s9,88(a1)
    80002724:	0605bd03          	ld	s10,96(a1)
    80002728:	0685bd83          	ld	s11,104(a1)
    8000272c:	8082                	ret

000000008000272e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000272e:	1141                	add	sp,sp,-16
    80002730:	e406                	sd	ra,8(sp)
    80002732:	e022                	sd	s0,0(sp)
    80002734:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    80002736:	00006597          	auipc	a1,0x6
    8000273a:	b6a58593          	add	a1,a1,-1174 # 800082a0 <states.0+0x28>
    8000273e:	00015517          	auipc	a0,0x15
    80002742:	02a50513          	add	a0,a0,42 # 80017768 <tickslock>
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	426080e7          	jalr	1062(ra) # 80000b6c <initlock>
}
    8000274e:	60a2                	ld	ra,8(sp)
    80002750:	6402                	ld	s0,0(sp)
    80002752:	0141                	add	sp,sp,16
    80002754:	8082                	ret

0000000080002756 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002756:	1141                	add	sp,sp,-16
    80002758:	e422                	sd	s0,8(sp)
    8000275a:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000275c:	00003797          	auipc	a5,0x3
    80002760:	56478793          	add	a5,a5,1380 # 80005cc0 <kernelvec>
    80002764:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002768:	6422                	ld	s0,8(sp)
    8000276a:	0141                	add	sp,sp,16
    8000276c:	8082                	ret

000000008000276e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000276e:	1141                	add	sp,sp,-16
    80002770:	e406                	sd	ra,8(sp)
    80002772:	e022                	sd	s0,0(sp)
    80002774:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    80002776:	fffff097          	auipc	ra,0xfffff
    8000277a:	382080e7          	jalr	898(ra) # 80001af8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000277e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002782:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002784:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002788:	00005697          	auipc	a3,0x5
    8000278c:	87868693          	add	a3,a3,-1928 # 80007000 <_trampoline>
    80002790:	00005717          	auipc	a4,0x5
    80002794:	87070713          	add	a4,a4,-1936 # 80007000 <_trampoline>
    80002798:	8f15                	sub	a4,a4,a3
    8000279a:	040007b7          	lui	a5,0x4000
    8000279e:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800027a0:	07b2                	sll	a5,a5,0xc
    800027a2:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027a4:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027a8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027aa:	18002673          	csrr	a2,satp
    800027ae:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027b0:	6d30                	ld	a2,88(a0)
    800027b2:	6138                	ld	a4,64(a0)
    800027b4:	6585                	lui	a1,0x1
    800027b6:	972e                	add	a4,a4,a1
    800027b8:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027ba:	6d38                	ld	a4,88(a0)
    800027bc:	00000617          	auipc	a2,0x0
    800027c0:	13c60613          	add	a2,a2,316 # 800028f8 <usertrap>
    800027c4:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027c6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027c8:	8612                	mv	a2,tp
    800027ca:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027cc:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027d0:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027d4:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027d8:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027dc:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027de:	6f18                	ld	a4,24(a4)
    800027e0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027e4:	692c                	ld	a1,80(a0)
    800027e6:	81b1                	srl	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027e8:	00005717          	auipc	a4,0x5
    800027ec:	8a870713          	add	a4,a4,-1880 # 80007090 <userret>
    800027f0:	8f15                	sub	a4,a4,a3
    800027f2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027f4:	577d                	li	a4,-1
    800027f6:	177e                	sll	a4,a4,0x3f
    800027f8:	8dd9                	or	a1,a1,a4
    800027fa:	02000537          	lui	a0,0x2000
    800027fe:	157d                	add	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002800:	0536                	sll	a0,a0,0xd
    80002802:	9782                	jalr	a5
}
    80002804:	60a2                	ld	ra,8(sp)
    80002806:	6402                	ld	s0,0(sp)
    80002808:	0141                	add	sp,sp,16
    8000280a:	8082                	ret

000000008000280c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000280c:	1101                	add	sp,sp,-32
    8000280e:	ec06                	sd	ra,24(sp)
    80002810:	e822                	sd	s0,16(sp)
    80002812:	e426                	sd	s1,8(sp)
    80002814:	1000                	add	s0,sp,32
  acquire(&tickslock);
    80002816:	00015497          	auipc	s1,0x15
    8000281a:	f5248493          	add	s1,s1,-174 # 80017768 <tickslock>
    8000281e:	8526                	mv	a0,s1
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	3dc080e7          	jalr	988(ra) # 80000bfc <acquire>
  ticks++;
    80002828:	00006517          	auipc	a0,0x6
    8000282c:	7f850513          	add	a0,a0,2040 # 80009020 <ticks>
    80002830:	411c                	lw	a5,0(a0)
    80002832:	2785                	addw	a5,a5,1
    80002834:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002836:	00000097          	auipc	ra,0x0
    8000283a:	c58080e7          	jalr	-936(ra) # 8000248e <wakeup>
  release(&tickslock);
    8000283e:	8526                	mv	a0,s1
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	470080e7          	jalr	1136(ra) # 80000cb0 <release>
}
    80002848:	60e2                	ld	ra,24(sp)
    8000284a:	6442                	ld	s0,16(sp)
    8000284c:	64a2                	ld	s1,8(sp)
    8000284e:	6105                	add	sp,sp,32
    80002850:	8082                	ret

0000000080002852 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002852:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002856:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002858:	0807df63          	bgez	a5,800028f6 <devintr+0xa4>
{
    8000285c:	1101                	add	sp,sp,-32
    8000285e:	ec06                	sd	ra,24(sp)
    80002860:	e822                	sd	s0,16(sp)
    80002862:	e426                	sd	s1,8(sp)
    80002864:	1000                	add	s0,sp,32
     (scause & 0xff) == 9){
    80002866:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    8000286a:	46a5                	li	a3,9
    8000286c:	00d70d63          	beq	a4,a3,80002886 <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002870:	577d                	li	a4,-1
    80002872:	177e                	sll	a4,a4,0x3f
    80002874:	0705                	add	a4,a4,1
    return 0;
    80002876:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002878:	04e78e63          	beq	a5,a4,800028d4 <devintr+0x82>
  }
}
    8000287c:	60e2                	ld	ra,24(sp)
    8000287e:	6442                	ld	s0,16(sp)
    80002880:	64a2                	ld	s1,8(sp)
    80002882:	6105                	add	sp,sp,32
    80002884:	8082                	ret
    int irq = plic_claim();
    80002886:	00003097          	auipc	ra,0x3
    8000288a:	542080e7          	jalr	1346(ra) # 80005dc8 <plic_claim>
    8000288e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002890:	47a9                	li	a5,10
    80002892:	02f50763          	beq	a0,a5,800028c0 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002896:	4785                	li	a5,1
    80002898:	02f50963          	beq	a0,a5,800028ca <devintr+0x78>
    return 1;
    8000289c:	4505                	li	a0,1
    } else if(irq){
    8000289e:	dcf9                	beqz	s1,8000287c <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    800028a0:	85a6                	mv	a1,s1
    800028a2:	00006517          	auipc	a0,0x6
    800028a6:	a0650513          	add	a0,a0,-1530 # 800082a8 <states.0+0x30>
    800028aa:	ffffe097          	auipc	ra,0xffffe
    800028ae:	ce2080e7          	jalr	-798(ra) # 8000058c <printf>
      plic_complete(irq);
    800028b2:	8526                	mv	a0,s1
    800028b4:	00003097          	auipc	ra,0x3
    800028b8:	538080e7          	jalr	1336(ra) # 80005dec <plic_complete>
    return 1;
    800028bc:	4505                	li	a0,1
    800028be:	bf7d                	j	8000287c <devintr+0x2a>
      uartintr();
    800028c0:	ffffe097          	auipc	ra,0xffffe
    800028c4:	0fe080e7          	jalr	254(ra) # 800009be <uartintr>
    if(irq)
    800028c8:	b7ed                	j	800028b2 <devintr+0x60>
      virtio_disk_intr();
    800028ca:	00004097          	auipc	ra,0x4
    800028ce:	994080e7          	jalr	-1644(ra) # 8000625e <virtio_disk_intr>
    if(irq)
    800028d2:	b7c5                	j	800028b2 <devintr+0x60>
    if(cpuid() == 0){
    800028d4:	fffff097          	auipc	ra,0xfffff
    800028d8:	1f8080e7          	jalr	504(ra) # 80001acc <cpuid>
    800028dc:	c901                	beqz	a0,800028ec <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028de:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028e2:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028e4:	14479073          	csrw	sip,a5
    return 2;
    800028e8:	4509                	li	a0,2
    800028ea:	bf49                	j	8000287c <devintr+0x2a>
      clockintr();
    800028ec:	00000097          	auipc	ra,0x0
    800028f0:	f20080e7          	jalr	-224(ra) # 8000280c <clockintr>
    800028f4:	b7ed                	j	800028de <devintr+0x8c>
}
    800028f6:	8082                	ret

00000000800028f8 <usertrap>:
{
    800028f8:	7179                	add	sp,sp,-48
    800028fa:	f406                	sd	ra,40(sp)
    800028fc:	f022                	sd	s0,32(sp)
    800028fe:	ec26                	sd	s1,24(sp)
    80002900:	e84a                	sd	s2,16(sp)
    80002902:	e44e                	sd	s3,8(sp)
    80002904:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002906:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000290a:	1007f793          	and	a5,a5,256
    8000290e:	e7c9                	bnez	a5,80002998 <usertrap+0xa0>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002910:	00003797          	auipc	a5,0x3
    80002914:	3b078793          	add	a5,a5,944 # 80005cc0 <kernelvec>
    80002918:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000291c:	fffff097          	auipc	ra,0xfffff
    80002920:	1dc080e7          	jalr	476(ra) # 80001af8 <myproc>
    80002924:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002926:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002928:	14102773          	csrr	a4,sepc
    8000292c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000292e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002932:	47a1                	li	a5,8
    80002934:	06f70a63          	beq	a4,a5,800029a8 <usertrap+0xb0>
    80002938:	14202773          	csrr	a4,scause
  } else if(r_scause() == 13|| r_scause() == 15){
    8000293c:	47b5                	li	a5,13
    8000293e:	00f70763          	beq	a4,a5,8000294c <usertrap+0x54>
    80002942:	14202773          	csrr	a4,scause
    80002946:	47bd                	li	a5,15
    80002948:	10f71b63          	bne	a4,a5,80002a5e <usertrap+0x166>
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000294c:	14302973          	csrr	s2,stval
    if(a >= p->sz){
    80002950:	64bc                	ld	a5,72(s1)
    80002952:	08f97e63          	bgeu	s2,a5,800029ee <usertrap+0xf6>
    else if(a < PGROUNDUP(p->trapframe->sp)){
    80002956:	6cbc                	ld	a5,88(s1)
    80002958:	7b9c                	ld	a5,48(a5)
    8000295a:	6705                	lui	a4,0x1
    8000295c:	177d                	add	a4,a4,-1 # fff <_entry-0x7ffff001>
    8000295e:	97ba                	add	a5,a5,a4
    80002960:	777d                	lui	a4,0xfffff
    80002962:	8ff9                	and	a5,a5,a4
    80002964:	08f97e63          	bgeu	s2,a5,80002a00 <usertrap+0x108>
      printf("usertrap(): invalid va below the user stack\n");
    80002968:	00006517          	auipc	a0,0x6
    8000296c:	9b050513          	add	a0,a0,-1616 # 80008318 <states.0+0xa0>
    80002970:	ffffe097          	auipc	ra,0xffffe
    80002974:	c1c080e7          	jalr	-996(ra) # 8000058c <printf>
      p->killed = 1;
    80002978:	4785                	li	a5,1
    8000297a:	d89c                	sw	a5,48(s1)
    8000297c:	4901                	li	s2,0
    exit(-1);
    8000297e:	557d                	li	a0,-1
    80002980:	00000097          	auipc	ra,0x0
    80002984:	848080e7          	jalr	-1976(ra) # 800021c8 <exit>
  if(which_dev == 2)
    80002988:	4789                	li	a5,2
    8000298a:	04f91163          	bne	s2,a5,800029cc <usertrap+0xd4>
    yield();
    8000298e:	00000097          	auipc	ra,0x0
    80002992:	944080e7          	jalr	-1724(ra) # 800022d2 <yield>
    80002996:	a81d                	j	800029cc <usertrap+0xd4>
    panic("usertrap: not from user mode");
    80002998:	00006517          	auipc	a0,0x6
    8000299c:	93050513          	add	a0,a0,-1744 # 800082c8 <states.0+0x50>
    800029a0:	ffffe097          	auipc	ra,0xffffe
    800029a4:	ba2080e7          	jalr	-1118(ra) # 80000542 <panic>
    if(p->killed)
    800029a8:	591c                	lw	a5,48(a0)
    800029aa:	ef85                	bnez	a5,800029e2 <usertrap+0xea>
    p->trapframe->epc += 4;
    800029ac:	6cb8                	ld	a4,88(s1)
    800029ae:	6f1c                	ld	a5,24(a4)
    800029b0:	0791                	add	a5,a5,4
    800029b2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029b8:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029bc:	10079073          	csrw	sstatus,a5
    syscall();
    800029c0:	00000097          	auipc	ra,0x0
    800029c4:	326080e7          	jalr	806(ra) # 80002ce6 <syscall>
  if(p->killed)
    800029c8:	589c                	lw	a5,48(s1)
    800029ca:	ebf9                	bnez	a5,80002aa0 <usertrap+0x1a8>
  usertrapret();
    800029cc:	00000097          	auipc	ra,0x0
    800029d0:	da2080e7          	jalr	-606(ra) # 8000276e <usertrapret>
}
    800029d4:	70a2                	ld	ra,40(sp)
    800029d6:	7402                	ld	s0,32(sp)
    800029d8:	64e2                	ld	s1,24(sp)
    800029da:	6942                	ld	s2,16(sp)
    800029dc:	69a2                	ld	s3,8(sp)
    800029de:	6145                	add	sp,sp,48
    800029e0:	8082                	ret
      exit(-1);
    800029e2:	557d                	li	a0,-1
    800029e4:	fffff097          	auipc	ra,0xfffff
    800029e8:	7e4080e7          	jalr	2020(ra) # 800021c8 <exit>
    800029ec:	b7c1                	j	800029ac <usertrap+0xb4>
      printf("usertrap(): invalid va higher then p->sz\n");
    800029ee:	00006517          	auipc	a0,0x6
    800029f2:	8fa50513          	add	a0,a0,-1798 # 800082e8 <states.0+0x70>
    800029f6:	ffffe097          	auipc	ra,0xffffe
    800029fa:	b96080e7          	jalr	-1130(ra) # 8000058c <printf>
      p->killed = 1;
    800029fe:	bfad                	j	80002978 <usertrap+0x80>
    else if((mem = kalloc())==0){
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	10c080e7          	jalr	268(ra) # 80000b0c <kalloc>
    80002a08:	89aa                	mv	s3,a0
    80002a0a:	c129                	beqz	a0,80002a4c <usertrap+0x154>
        memset(mem, 0, PGSIZE);
    80002a0c:	6605                	lui	a2,0x1
    80002a0e:	4581                	li	a1,0
    80002a10:	ffffe097          	auipc	ra,0xffffe
    80002a14:	2e8080e7          	jalr	744(ra) # 80000cf8 <memset>
        if(mappages(p->pagetable, PGROUNDDOWN(a), PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80002a18:	4779                	li	a4,30
    80002a1a:	86ce                	mv	a3,s3
    80002a1c:	6605                	lui	a2,0x1
    80002a1e:	75fd                	lui	a1,0xfffff
    80002a20:	00b975b3          	and	a1,s2,a1
    80002a24:	68a8                	ld	a0,80(s1)
    80002a26:	ffffe097          	auipc	ra,0xffffe
    80002a2a:	7b6080e7          	jalr	1974(ra) # 800011dc <mappages>
    80002a2e:	dd49                	beqz	a0,800029c8 <usertrap+0xd0>
          kfree(mem);
    80002a30:	854e                	mv	a0,s3
    80002a32:	ffffe097          	auipc	ra,0xffffe
    80002a36:	fdc080e7          	jalr	-36(ra) # 80000a0e <kfree>
          printf("usertrap(): mappages() failed\n");
    80002a3a:	00006517          	auipc	a0,0x6
    80002a3e:	92e50513          	add	a0,a0,-1746 # 80008368 <states.0+0xf0>
    80002a42:	ffffe097          	auipc	ra,0xffffe
    80002a46:	b4a080e7          	jalr	-1206(ra) # 8000058c <printf>
          p->killed = 1;
    80002a4a:	b73d                	j	80002978 <usertrap+0x80>
      printf("usertrap(): kalloc() failed\n");
    80002a4c:	00006517          	auipc	a0,0x6
    80002a50:	8fc50513          	add	a0,a0,-1796 # 80008348 <states.0+0xd0>
    80002a54:	ffffe097          	auipc	ra,0xffffe
    80002a58:	b38080e7          	jalr	-1224(ra) # 8000058c <printf>
      p->killed = 1;
    80002a5c:	bf31                	j	80002978 <usertrap+0x80>
  } else if((which_dev = devintr()) != 0){
    80002a5e:	00000097          	auipc	ra,0x0
    80002a62:	df4080e7          	jalr	-524(ra) # 80002852 <devintr>
    80002a66:	892a                	mv	s2,a0
    80002a68:	c501                	beqz	a0,80002a70 <usertrap+0x178>
  if(p->killed)
    80002a6a:	589c                	lw	a5,48(s1)
    80002a6c:	df91                	beqz	a5,80002988 <usertrap+0x90>
    80002a6e:	bf01                	j	8000297e <usertrap+0x86>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a70:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a74:	5c90                	lw	a2,56(s1)
    80002a76:	00006517          	auipc	a0,0x6
    80002a7a:	91250513          	add	a0,a0,-1774 # 80008388 <states.0+0x110>
    80002a7e:	ffffe097          	auipc	ra,0xffffe
    80002a82:	b0e080e7          	jalr	-1266(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a86:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a8a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a8e:	00006517          	auipc	a0,0x6
    80002a92:	92a50513          	add	a0,a0,-1750 # 800083b8 <states.0+0x140>
    80002a96:	ffffe097          	auipc	ra,0xffffe
    80002a9a:	af6080e7          	jalr	-1290(ra) # 8000058c <printf>
    p->killed = 1;
    80002a9e:	bde9                	j	80002978 <usertrap+0x80>
  if(p->killed)
    80002aa0:	4901                	li	s2,0
    80002aa2:	bdf1                	j	8000297e <usertrap+0x86>

0000000080002aa4 <kerneltrap>:
{
    80002aa4:	7179                	add	sp,sp,-48
    80002aa6:	f406                	sd	ra,40(sp)
    80002aa8:	f022                	sd	s0,32(sp)
    80002aaa:	ec26                	sd	s1,24(sp)
    80002aac:	e84a                	sd	s2,16(sp)
    80002aae:	e44e                	sd	s3,8(sp)
    80002ab0:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ab2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ab6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aba:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002abe:	1004f793          	and	a5,s1,256
    80002ac2:	cb85                	beqz	a5,80002af2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ac4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ac8:	8b89                	and	a5,a5,2
  if(intr_get() != 0)
    80002aca:	ef85                	bnez	a5,80002b02 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002acc:	00000097          	auipc	ra,0x0
    80002ad0:	d86080e7          	jalr	-634(ra) # 80002852 <devintr>
    80002ad4:	cd1d                	beqz	a0,80002b12 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ad6:	4789                	li	a5,2
    80002ad8:	06f50a63          	beq	a0,a5,80002b4c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002adc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ae0:	10049073          	csrw	sstatus,s1
}
    80002ae4:	70a2                	ld	ra,40(sp)
    80002ae6:	7402                	ld	s0,32(sp)
    80002ae8:	64e2                	ld	s1,24(sp)
    80002aea:	6942                	ld	s2,16(sp)
    80002aec:	69a2                	ld	s3,8(sp)
    80002aee:	6145                	add	sp,sp,48
    80002af0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002af2:	00006517          	auipc	a0,0x6
    80002af6:	8e650513          	add	a0,a0,-1818 # 800083d8 <states.0+0x160>
    80002afa:	ffffe097          	auipc	ra,0xffffe
    80002afe:	a48080e7          	jalr	-1464(ra) # 80000542 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b02:	00006517          	auipc	a0,0x6
    80002b06:	8fe50513          	add	a0,a0,-1794 # 80008400 <states.0+0x188>
    80002b0a:	ffffe097          	auipc	ra,0xffffe
    80002b0e:	a38080e7          	jalr	-1480(ra) # 80000542 <panic>
    printf("scause %p\n", scause);
    80002b12:	85ce                	mv	a1,s3
    80002b14:	00006517          	auipc	a0,0x6
    80002b18:	90c50513          	add	a0,a0,-1780 # 80008420 <states.0+0x1a8>
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	a70080e7          	jalr	-1424(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b24:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b28:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b2c:	00006517          	auipc	a0,0x6
    80002b30:	90450513          	add	a0,a0,-1788 # 80008430 <states.0+0x1b8>
    80002b34:	ffffe097          	auipc	ra,0xffffe
    80002b38:	a58080e7          	jalr	-1448(ra) # 8000058c <printf>
    panic("kerneltrap");
    80002b3c:	00006517          	auipc	a0,0x6
    80002b40:	90c50513          	add	a0,a0,-1780 # 80008448 <states.0+0x1d0>
    80002b44:	ffffe097          	auipc	ra,0xffffe
    80002b48:	9fe080e7          	jalr	-1538(ra) # 80000542 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b4c:	fffff097          	auipc	ra,0xfffff
    80002b50:	fac080e7          	jalr	-84(ra) # 80001af8 <myproc>
    80002b54:	d541                	beqz	a0,80002adc <kerneltrap+0x38>
    80002b56:	fffff097          	auipc	ra,0xfffff
    80002b5a:	fa2080e7          	jalr	-94(ra) # 80001af8 <myproc>
    80002b5e:	4d18                	lw	a4,24(a0)
    80002b60:	478d                	li	a5,3
    80002b62:	f6f71de3          	bne	a4,a5,80002adc <kerneltrap+0x38>
    yield();
    80002b66:	fffff097          	auipc	ra,0xfffff
    80002b6a:	76c080e7          	jalr	1900(ra) # 800022d2 <yield>
    80002b6e:	b7bd                	j	80002adc <kerneltrap+0x38>

0000000080002b70 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b70:	1101                	add	sp,sp,-32
    80002b72:	ec06                	sd	ra,24(sp)
    80002b74:	e822                	sd	s0,16(sp)
    80002b76:	e426                	sd	s1,8(sp)
    80002b78:	1000                	add	s0,sp,32
    80002b7a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b7c:	fffff097          	auipc	ra,0xfffff
    80002b80:	f7c080e7          	jalr	-132(ra) # 80001af8 <myproc>
  switch (n) {
    80002b84:	4795                	li	a5,5
    80002b86:	0497e163          	bltu	a5,s1,80002bc8 <argraw+0x58>
    80002b8a:	048a                	sll	s1,s1,0x2
    80002b8c:	00006717          	auipc	a4,0x6
    80002b90:	8f470713          	add	a4,a4,-1804 # 80008480 <states.0+0x208>
    80002b94:	94ba                	add	s1,s1,a4
    80002b96:	409c                	lw	a5,0(s1)
    80002b98:	97ba                	add	a5,a5,a4
    80002b9a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b9c:	6d3c                	ld	a5,88(a0)
    80002b9e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ba0:	60e2                	ld	ra,24(sp)
    80002ba2:	6442                	ld	s0,16(sp)
    80002ba4:	64a2                	ld	s1,8(sp)
    80002ba6:	6105                	add	sp,sp,32
    80002ba8:	8082                	ret
    return p->trapframe->a1;
    80002baa:	6d3c                	ld	a5,88(a0)
    80002bac:	7fa8                	ld	a0,120(a5)
    80002bae:	bfcd                	j	80002ba0 <argraw+0x30>
    return p->trapframe->a2;
    80002bb0:	6d3c                	ld	a5,88(a0)
    80002bb2:	63c8                	ld	a0,128(a5)
    80002bb4:	b7f5                	j	80002ba0 <argraw+0x30>
    return p->trapframe->a3;
    80002bb6:	6d3c                	ld	a5,88(a0)
    80002bb8:	67c8                	ld	a0,136(a5)
    80002bba:	b7dd                	j	80002ba0 <argraw+0x30>
    return p->trapframe->a4;
    80002bbc:	6d3c                	ld	a5,88(a0)
    80002bbe:	6bc8                	ld	a0,144(a5)
    80002bc0:	b7c5                	j	80002ba0 <argraw+0x30>
    return p->trapframe->a5;
    80002bc2:	6d3c                	ld	a5,88(a0)
    80002bc4:	6fc8                	ld	a0,152(a5)
    80002bc6:	bfe9                	j	80002ba0 <argraw+0x30>
  panic("argraw");
    80002bc8:	00006517          	auipc	a0,0x6
    80002bcc:	89050513          	add	a0,a0,-1904 # 80008458 <states.0+0x1e0>
    80002bd0:	ffffe097          	auipc	ra,0xffffe
    80002bd4:	972080e7          	jalr	-1678(ra) # 80000542 <panic>

0000000080002bd8 <fetchaddr>:
{
    80002bd8:	1101                	add	sp,sp,-32
    80002bda:	ec06                	sd	ra,24(sp)
    80002bdc:	e822                	sd	s0,16(sp)
    80002bde:	e426                	sd	s1,8(sp)
    80002be0:	e04a                	sd	s2,0(sp)
    80002be2:	1000                	add	s0,sp,32
    80002be4:	84aa                	mv	s1,a0
    80002be6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002be8:	fffff097          	auipc	ra,0xfffff
    80002bec:	f10080e7          	jalr	-240(ra) # 80001af8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002bf0:	653c                	ld	a5,72(a0)
    80002bf2:	02f4f863          	bgeu	s1,a5,80002c22 <fetchaddr+0x4a>
    80002bf6:	00848713          	add	a4,s1,8
    80002bfa:	02e7e663          	bltu	a5,a4,80002c26 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bfe:	46a1                	li	a3,8
    80002c00:	8626                	mv	a2,s1
    80002c02:	85ca                	mv	a1,s2
    80002c04:	6928                	ld	a0,80(a0)
    80002c06:	fffff097          	auipc	ra,0xfffff
    80002c0a:	c74080e7          	jalr	-908(ra) # 8000187a <copyin>
    80002c0e:	00a03533          	snez	a0,a0
    80002c12:	40a00533          	neg	a0,a0
}
    80002c16:	60e2                	ld	ra,24(sp)
    80002c18:	6442                	ld	s0,16(sp)
    80002c1a:	64a2                	ld	s1,8(sp)
    80002c1c:	6902                	ld	s2,0(sp)
    80002c1e:	6105                	add	sp,sp,32
    80002c20:	8082                	ret
    return -1;
    80002c22:	557d                	li	a0,-1
    80002c24:	bfcd                	j	80002c16 <fetchaddr+0x3e>
    80002c26:	557d                	li	a0,-1
    80002c28:	b7fd                	j	80002c16 <fetchaddr+0x3e>

0000000080002c2a <fetchstr>:
{
    80002c2a:	7179                	add	sp,sp,-48
    80002c2c:	f406                	sd	ra,40(sp)
    80002c2e:	f022                	sd	s0,32(sp)
    80002c30:	ec26                	sd	s1,24(sp)
    80002c32:	e84a                	sd	s2,16(sp)
    80002c34:	e44e                	sd	s3,8(sp)
    80002c36:	1800                	add	s0,sp,48
    80002c38:	892a                	mv	s2,a0
    80002c3a:	84ae                	mv	s1,a1
    80002c3c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c3e:	fffff097          	auipc	ra,0xfffff
    80002c42:	eba080e7          	jalr	-326(ra) # 80001af8 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c46:	86ce                	mv	a3,s3
    80002c48:	864a                	mv	a2,s2
    80002c4a:	85a6                	mv	a1,s1
    80002c4c:	6928                	ld	a0,80(a0)
    80002c4e:	fffff097          	auipc	ra,0xfffff
    80002c52:	cba080e7          	jalr	-838(ra) # 80001908 <copyinstr>
  if(err < 0)
    80002c56:	00054763          	bltz	a0,80002c64 <fetchstr+0x3a>
  return strlen(buf);
    80002c5a:	8526                	mv	a0,s1
    80002c5c:	ffffe097          	auipc	ra,0xffffe
    80002c60:	21e080e7          	jalr	542(ra) # 80000e7a <strlen>
}
    80002c64:	70a2                	ld	ra,40(sp)
    80002c66:	7402                	ld	s0,32(sp)
    80002c68:	64e2                	ld	s1,24(sp)
    80002c6a:	6942                	ld	s2,16(sp)
    80002c6c:	69a2                	ld	s3,8(sp)
    80002c6e:	6145                	add	sp,sp,48
    80002c70:	8082                	ret

0000000080002c72 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c72:	1101                	add	sp,sp,-32
    80002c74:	ec06                	sd	ra,24(sp)
    80002c76:	e822                	sd	s0,16(sp)
    80002c78:	e426                	sd	s1,8(sp)
    80002c7a:	1000                	add	s0,sp,32
    80002c7c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c7e:	00000097          	auipc	ra,0x0
    80002c82:	ef2080e7          	jalr	-270(ra) # 80002b70 <argraw>
    80002c86:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c88:	4501                	li	a0,0
    80002c8a:	60e2                	ld	ra,24(sp)
    80002c8c:	6442                	ld	s0,16(sp)
    80002c8e:	64a2                	ld	s1,8(sp)
    80002c90:	6105                	add	sp,sp,32
    80002c92:	8082                	ret

0000000080002c94 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c94:	1101                	add	sp,sp,-32
    80002c96:	ec06                	sd	ra,24(sp)
    80002c98:	e822                	sd	s0,16(sp)
    80002c9a:	e426                	sd	s1,8(sp)
    80002c9c:	1000                	add	s0,sp,32
    80002c9e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ca0:	00000097          	auipc	ra,0x0
    80002ca4:	ed0080e7          	jalr	-304(ra) # 80002b70 <argraw>
    80002ca8:	e088                	sd	a0,0(s1)
  return 0;
}
    80002caa:	4501                	li	a0,0
    80002cac:	60e2                	ld	ra,24(sp)
    80002cae:	6442                	ld	s0,16(sp)
    80002cb0:	64a2                	ld	s1,8(sp)
    80002cb2:	6105                	add	sp,sp,32
    80002cb4:	8082                	ret

0000000080002cb6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cb6:	1101                	add	sp,sp,-32
    80002cb8:	ec06                	sd	ra,24(sp)
    80002cba:	e822                	sd	s0,16(sp)
    80002cbc:	e426                	sd	s1,8(sp)
    80002cbe:	e04a                	sd	s2,0(sp)
    80002cc0:	1000                	add	s0,sp,32
    80002cc2:	84ae                	mv	s1,a1
    80002cc4:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002cc6:	00000097          	auipc	ra,0x0
    80002cca:	eaa080e7          	jalr	-342(ra) # 80002b70 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002cce:	864a                	mv	a2,s2
    80002cd0:	85a6                	mv	a1,s1
    80002cd2:	00000097          	auipc	ra,0x0
    80002cd6:	f58080e7          	jalr	-168(ra) # 80002c2a <fetchstr>
}
    80002cda:	60e2                	ld	ra,24(sp)
    80002cdc:	6442                	ld	s0,16(sp)
    80002cde:	64a2                	ld	s1,8(sp)
    80002ce0:	6902                	ld	s2,0(sp)
    80002ce2:	6105                	add	sp,sp,32
    80002ce4:	8082                	ret

0000000080002ce6 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002ce6:	1101                	add	sp,sp,-32
    80002ce8:	ec06                	sd	ra,24(sp)
    80002cea:	e822                	sd	s0,16(sp)
    80002cec:	e426                	sd	s1,8(sp)
    80002cee:	e04a                	sd	s2,0(sp)
    80002cf0:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002cf2:	fffff097          	auipc	ra,0xfffff
    80002cf6:	e06080e7          	jalr	-506(ra) # 80001af8 <myproc>
    80002cfa:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002cfc:	05853903          	ld	s2,88(a0)
    80002d00:	0a893783          	ld	a5,168(s2)
    80002d04:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d08:	37fd                	addw	a5,a5,-1
    80002d0a:	4751                	li	a4,20
    80002d0c:	00f76f63          	bltu	a4,a5,80002d2a <syscall+0x44>
    80002d10:	00369713          	sll	a4,a3,0x3
    80002d14:	00005797          	auipc	a5,0x5
    80002d18:	78478793          	add	a5,a5,1924 # 80008498 <syscalls>
    80002d1c:	97ba                	add	a5,a5,a4
    80002d1e:	639c                	ld	a5,0(a5)
    80002d20:	c789                	beqz	a5,80002d2a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d22:	9782                	jalr	a5
    80002d24:	06a93823          	sd	a0,112(s2)
    80002d28:	a839                	j	80002d46 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d2a:	15848613          	add	a2,s1,344
    80002d2e:	5c8c                	lw	a1,56(s1)
    80002d30:	00005517          	auipc	a0,0x5
    80002d34:	73050513          	add	a0,a0,1840 # 80008460 <states.0+0x1e8>
    80002d38:	ffffe097          	auipc	ra,0xffffe
    80002d3c:	854080e7          	jalr	-1964(ra) # 8000058c <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d40:	6cbc                	ld	a5,88(s1)
    80002d42:	577d                	li	a4,-1
    80002d44:	fbb8                	sd	a4,112(a5)
  }
}
    80002d46:	60e2                	ld	ra,24(sp)
    80002d48:	6442                	ld	s0,16(sp)
    80002d4a:	64a2                	ld	s1,8(sp)
    80002d4c:	6902                	ld	s2,0(sp)
    80002d4e:	6105                	add	sp,sp,32
    80002d50:	8082                	ret

0000000080002d52 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d52:	1101                	add	sp,sp,-32
    80002d54:	ec06                	sd	ra,24(sp)
    80002d56:	e822                	sd	s0,16(sp)
    80002d58:	1000                	add	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d5a:	fec40593          	add	a1,s0,-20
    80002d5e:	4501                	li	a0,0
    80002d60:	00000097          	auipc	ra,0x0
    80002d64:	f12080e7          	jalr	-238(ra) # 80002c72 <argint>
    return -1;
    80002d68:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d6a:	00054963          	bltz	a0,80002d7c <sys_exit+0x2a>
  exit(n);
    80002d6e:	fec42503          	lw	a0,-20(s0)
    80002d72:	fffff097          	auipc	ra,0xfffff
    80002d76:	456080e7          	jalr	1110(ra) # 800021c8 <exit>
  return 0;  // not reached
    80002d7a:	4781                	li	a5,0
}
    80002d7c:	853e                	mv	a0,a5
    80002d7e:	60e2                	ld	ra,24(sp)
    80002d80:	6442                	ld	s0,16(sp)
    80002d82:	6105                	add	sp,sp,32
    80002d84:	8082                	ret

0000000080002d86 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d86:	1141                	add	sp,sp,-16
    80002d88:	e406                	sd	ra,8(sp)
    80002d8a:	e022                	sd	s0,0(sp)
    80002d8c:	0800                	add	s0,sp,16
  return myproc()->pid;
    80002d8e:	fffff097          	auipc	ra,0xfffff
    80002d92:	d6a080e7          	jalr	-662(ra) # 80001af8 <myproc>
}
    80002d96:	5d08                	lw	a0,56(a0)
    80002d98:	60a2                	ld	ra,8(sp)
    80002d9a:	6402                	ld	s0,0(sp)
    80002d9c:	0141                	add	sp,sp,16
    80002d9e:	8082                	ret

0000000080002da0 <sys_fork>:

uint64
sys_fork(void)
{
    80002da0:	1141                	add	sp,sp,-16
    80002da2:	e406                	sd	ra,8(sp)
    80002da4:	e022                	sd	s0,0(sp)
    80002da6:	0800                	add	s0,sp,16
  return fork();
    80002da8:	fffff097          	auipc	ra,0xfffff
    80002dac:	114080e7          	jalr	276(ra) # 80001ebc <fork>
}
    80002db0:	60a2                	ld	ra,8(sp)
    80002db2:	6402                	ld	s0,0(sp)
    80002db4:	0141                	add	sp,sp,16
    80002db6:	8082                	ret

0000000080002db8 <sys_wait>:

uint64
sys_wait(void)
{
    80002db8:	1101                	add	sp,sp,-32
    80002dba:	ec06                	sd	ra,24(sp)
    80002dbc:	e822                	sd	s0,16(sp)
    80002dbe:	1000                	add	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002dc0:	fe840593          	add	a1,s0,-24
    80002dc4:	4501                	li	a0,0
    80002dc6:	00000097          	auipc	ra,0x0
    80002dca:	ece080e7          	jalr	-306(ra) # 80002c94 <argaddr>
    80002dce:	87aa                	mv	a5,a0
    return -1;
    80002dd0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002dd2:	0007c863          	bltz	a5,80002de2 <sys_wait+0x2a>
  return wait(p);
    80002dd6:	fe843503          	ld	a0,-24(s0)
    80002dda:	fffff097          	auipc	ra,0xfffff
    80002dde:	5b2080e7          	jalr	1458(ra) # 8000238c <wait>
}
    80002de2:	60e2                	ld	ra,24(sp)
    80002de4:	6442                	ld	s0,16(sp)
    80002de6:	6105                	add	sp,sp,32
    80002de8:	8082                	ret

0000000080002dea <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dea:	7179                	add	sp,sp,-48
    80002dec:	f406                	sd	ra,40(sp)
    80002dee:	f022                	sd	s0,32(sp)
    80002df0:	ec26                	sd	s1,24(sp)
    80002df2:	e84a                	sd	s2,16(sp)
    80002df4:	1800                	add	s0,sp,48
  int addr;
  int n;
  struct proc *p;
  if(argint(0, &n) < 0)
    80002df6:	fdc40593          	add	a1,s0,-36
    80002dfa:	4501                	li	a0,0
    80002dfc:	00000097          	auipc	ra,0x0
    80002e00:	e76080e7          	jalr	-394(ra) # 80002c72 <argint>
    return -1;
    80002e04:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e06:	02054163          	bltz	a0,80002e28 <sys_sbrk+0x3e>
  p=myproc();
    80002e0a:	fffff097          	auipc	ra,0xfffff
    80002e0e:	cee080e7          	jalr	-786(ra) # 80001af8 <myproc>
    80002e12:	84aa                	mv	s1,a0
  addr = p->sz;
    80002e14:	653c                	ld	a5,72(a0)
    80002e16:	0007891b          	sext.w	s2,a5
  if(n>=0 && addr + n >= addr){
    80002e1a:	fdc42603          	lw	a2,-36(s0)
    80002e1e:	00064c63          	bltz	a2,80002e36 <sys_sbrk+0x4c>
    p->sz += n;
    80002e22:	963e                	add	a2,a2,a5
    80002e24:	e4b0                	sd	a2,72(s1)
  } else if(n < 0 && addr + n >= PGROUNDUP(p->trapframe->sp)){
    p->sz = uvmdealloc(p->pagetable, addr, addr+n);
  } else return -1;
  return addr;
    80002e26:	87ca                	mv	a5,s2
}
    80002e28:	853e                	mv	a0,a5
    80002e2a:	70a2                	ld	ra,40(sp)
    80002e2c:	7402                	ld	s0,32(sp)
    80002e2e:	64e2                	ld	s1,24(sp)
    80002e30:	6942                	ld	s2,16(sp)
    80002e32:	6145                	add	sp,sp,48
    80002e34:	8082                	ret
  } else if(n < 0 && addr + n >= PGROUNDUP(p->trapframe->sp)){
    80002e36:	0126063b          	addw	a2,a2,s2
    80002e3a:	6d3c                	ld	a5,88(a0)
    80002e3c:	7b98                	ld	a4,48(a5)
    80002e3e:	6785                	lui	a5,0x1
    80002e40:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80002e42:	973e                	add	a4,a4,a5
    80002e44:	77fd                	lui	a5,0xfffff
    80002e46:	8f7d                	and	a4,a4,a5
  } else return -1;
    80002e48:	57fd                	li	a5,-1
  } else if(n < 0 && addr + n >= PGROUNDUP(p->trapframe->sp)){
    80002e4a:	fce66fe3          	bltu	a2,a4,80002e28 <sys_sbrk+0x3e>
    p->sz = uvmdealloc(p->pagetable, addr, addr+n);
    80002e4e:	85ca                	mv	a1,s2
    80002e50:	6928                	ld	a0,80(a0)
    80002e52:	ffffe097          	auipc	ra,0xffffe
    80002e56:	71c080e7          	jalr	1820(ra) # 8000156e <uvmdealloc>
    80002e5a:	862a                	mv	a2,a0
    80002e5c:	b7e1                	j	80002e24 <sys_sbrk+0x3a>

0000000080002e5e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e5e:	7139                	add	sp,sp,-64
    80002e60:	fc06                	sd	ra,56(sp)
    80002e62:	f822                	sd	s0,48(sp)
    80002e64:	f426                	sd	s1,40(sp)
    80002e66:	f04a                	sd	s2,32(sp)
    80002e68:	ec4e                	sd	s3,24(sp)
    80002e6a:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e6c:	fcc40593          	add	a1,s0,-52
    80002e70:	4501                	li	a0,0
    80002e72:	00000097          	auipc	ra,0x0
    80002e76:	e00080e7          	jalr	-512(ra) # 80002c72 <argint>
    return -1;
    80002e7a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e7c:	06054563          	bltz	a0,80002ee6 <sys_sleep+0x88>
  acquire(&tickslock);
    80002e80:	00015517          	auipc	a0,0x15
    80002e84:	8e850513          	add	a0,a0,-1816 # 80017768 <tickslock>
    80002e88:	ffffe097          	auipc	ra,0xffffe
    80002e8c:	d74080e7          	jalr	-652(ra) # 80000bfc <acquire>
  ticks0 = ticks;
    80002e90:	00006917          	auipc	s2,0x6
    80002e94:	19092903          	lw	s2,400(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002e98:	fcc42783          	lw	a5,-52(s0)
    80002e9c:	cf85                	beqz	a5,80002ed4 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e9e:	00015997          	auipc	s3,0x15
    80002ea2:	8ca98993          	add	s3,s3,-1846 # 80017768 <tickslock>
    80002ea6:	00006497          	auipc	s1,0x6
    80002eaa:	17a48493          	add	s1,s1,378 # 80009020 <ticks>
    if(myproc()->killed){
    80002eae:	fffff097          	auipc	ra,0xfffff
    80002eb2:	c4a080e7          	jalr	-950(ra) # 80001af8 <myproc>
    80002eb6:	591c                	lw	a5,48(a0)
    80002eb8:	ef9d                	bnez	a5,80002ef6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002eba:	85ce                	mv	a1,s3
    80002ebc:	8526                	mv	a0,s1
    80002ebe:	fffff097          	auipc	ra,0xfffff
    80002ec2:	450080e7          	jalr	1104(ra) # 8000230e <sleep>
  while(ticks - ticks0 < n){
    80002ec6:	409c                	lw	a5,0(s1)
    80002ec8:	412787bb          	subw	a5,a5,s2
    80002ecc:	fcc42703          	lw	a4,-52(s0)
    80002ed0:	fce7efe3          	bltu	a5,a4,80002eae <sys_sleep+0x50>
  }
  release(&tickslock);
    80002ed4:	00015517          	auipc	a0,0x15
    80002ed8:	89450513          	add	a0,a0,-1900 # 80017768 <tickslock>
    80002edc:	ffffe097          	auipc	ra,0xffffe
    80002ee0:	dd4080e7          	jalr	-556(ra) # 80000cb0 <release>
  return 0;
    80002ee4:	4781                	li	a5,0
}
    80002ee6:	853e                	mv	a0,a5
    80002ee8:	70e2                	ld	ra,56(sp)
    80002eea:	7442                	ld	s0,48(sp)
    80002eec:	74a2                	ld	s1,40(sp)
    80002eee:	7902                	ld	s2,32(sp)
    80002ef0:	69e2                	ld	s3,24(sp)
    80002ef2:	6121                	add	sp,sp,64
    80002ef4:	8082                	ret
      release(&tickslock);
    80002ef6:	00015517          	auipc	a0,0x15
    80002efa:	87250513          	add	a0,a0,-1934 # 80017768 <tickslock>
    80002efe:	ffffe097          	auipc	ra,0xffffe
    80002f02:	db2080e7          	jalr	-590(ra) # 80000cb0 <release>
      return -1;
    80002f06:	57fd                	li	a5,-1
    80002f08:	bff9                	j	80002ee6 <sys_sleep+0x88>

0000000080002f0a <sys_kill>:

uint64
sys_kill(void)
{
    80002f0a:	1101                	add	sp,sp,-32
    80002f0c:	ec06                	sd	ra,24(sp)
    80002f0e:	e822                	sd	s0,16(sp)
    80002f10:	1000                	add	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f12:	fec40593          	add	a1,s0,-20
    80002f16:	4501                	li	a0,0
    80002f18:	00000097          	auipc	ra,0x0
    80002f1c:	d5a080e7          	jalr	-678(ra) # 80002c72 <argint>
    80002f20:	87aa                	mv	a5,a0
    return -1;
    80002f22:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f24:	0007c863          	bltz	a5,80002f34 <sys_kill+0x2a>
  return kill(pid);
    80002f28:	fec42503          	lw	a0,-20(s0)
    80002f2c:	fffff097          	auipc	ra,0xfffff
    80002f30:	5cc080e7          	jalr	1484(ra) # 800024f8 <kill>
}
    80002f34:	60e2                	ld	ra,24(sp)
    80002f36:	6442                	ld	s0,16(sp)
    80002f38:	6105                	add	sp,sp,32
    80002f3a:	8082                	ret

0000000080002f3c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f3c:	1101                	add	sp,sp,-32
    80002f3e:	ec06                	sd	ra,24(sp)
    80002f40:	e822                	sd	s0,16(sp)
    80002f42:	e426                	sd	s1,8(sp)
    80002f44:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f46:	00015517          	auipc	a0,0x15
    80002f4a:	82250513          	add	a0,a0,-2014 # 80017768 <tickslock>
    80002f4e:	ffffe097          	auipc	ra,0xffffe
    80002f52:	cae080e7          	jalr	-850(ra) # 80000bfc <acquire>
  xticks = ticks;
    80002f56:	00006497          	auipc	s1,0x6
    80002f5a:	0ca4a483          	lw	s1,202(s1) # 80009020 <ticks>
  release(&tickslock);
    80002f5e:	00015517          	auipc	a0,0x15
    80002f62:	80a50513          	add	a0,a0,-2038 # 80017768 <tickslock>
    80002f66:	ffffe097          	auipc	ra,0xffffe
    80002f6a:	d4a080e7          	jalr	-694(ra) # 80000cb0 <release>
  return xticks;
}
    80002f6e:	02049513          	sll	a0,s1,0x20
    80002f72:	9101                	srl	a0,a0,0x20
    80002f74:	60e2                	ld	ra,24(sp)
    80002f76:	6442                	ld	s0,16(sp)
    80002f78:	64a2                	ld	s1,8(sp)
    80002f7a:	6105                	add	sp,sp,32
    80002f7c:	8082                	ret

0000000080002f7e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f7e:	7179                	add	sp,sp,-48
    80002f80:	f406                	sd	ra,40(sp)
    80002f82:	f022                	sd	s0,32(sp)
    80002f84:	ec26                	sd	s1,24(sp)
    80002f86:	e84a                	sd	s2,16(sp)
    80002f88:	e44e                	sd	s3,8(sp)
    80002f8a:	e052                	sd	s4,0(sp)
    80002f8c:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f8e:	00005597          	auipc	a1,0x5
    80002f92:	5ba58593          	add	a1,a1,1466 # 80008548 <syscalls+0xb0>
    80002f96:	00014517          	auipc	a0,0x14
    80002f9a:	7ea50513          	add	a0,a0,2026 # 80017780 <bcache>
    80002f9e:	ffffe097          	auipc	ra,0xffffe
    80002fa2:	bce080e7          	jalr	-1074(ra) # 80000b6c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fa6:	0001c797          	auipc	a5,0x1c
    80002faa:	7da78793          	add	a5,a5,2010 # 8001f780 <bcache+0x8000>
    80002fae:	0001d717          	auipc	a4,0x1d
    80002fb2:	a3a70713          	add	a4,a4,-1478 # 8001f9e8 <bcache+0x8268>
    80002fb6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fba:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fbe:	00014497          	auipc	s1,0x14
    80002fc2:	7da48493          	add	s1,s1,2010 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002fc6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002fc8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002fca:	00005a17          	auipc	s4,0x5
    80002fce:	586a0a13          	add	s4,s4,1414 # 80008550 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002fd2:	2b893783          	ld	a5,696(s2)
    80002fd6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002fd8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002fdc:	85d2                	mv	a1,s4
    80002fde:	01048513          	add	a0,s1,16
    80002fe2:	00001097          	auipc	ra,0x1
    80002fe6:	484080e7          	jalr	1156(ra) # 80004466 <initsleeplock>
    bcache.head.next->prev = b;
    80002fea:	2b893783          	ld	a5,696(s2)
    80002fee:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ff0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ff4:	45848493          	add	s1,s1,1112
    80002ff8:	fd349de3          	bne	s1,s3,80002fd2 <binit+0x54>
  }
}
    80002ffc:	70a2                	ld	ra,40(sp)
    80002ffe:	7402                	ld	s0,32(sp)
    80003000:	64e2                	ld	s1,24(sp)
    80003002:	6942                	ld	s2,16(sp)
    80003004:	69a2                	ld	s3,8(sp)
    80003006:	6a02                	ld	s4,0(sp)
    80003008:	6145                	add	sp,sp,48
    8000300a:	8082                	ret

000000008000300c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000300c:	7179                	add	sp,sp,-48
    8000300e:	f406                	sd	ra,40(sp)
    80003010:	f022                	sd	s0,32(sp)
    80003012:	ec26                	sd	s1,24(sp)
    80003014:	e84a                	sd	s2,16(sp)
    80003016:	e44e                	sd	s3,8(sp)
    80003018:	1800                	add	s0,sp,48
    8000301a:	892a                	mv	s2,a0
    8000301c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000301e:	00014517          	auipc	a0,0x14
    80003022:	76250513          	add	a0,a0,1890 # 80017780 <bcache>
    80003026:	ffffe097          	auipc	ra,0xffffe
    8000302a:	bd6080e7          	jalr	-1066(ra) # 80000bfc <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000302e:	0001d497          	auipc	s1,0x1d
    80003032:	a0a4b483          	ld	s1,-1526(s1) # 8001fa38 <bcache+0x82b8>
    80003036:	0001d797          	auipc	a5,0x1d
    8000303a:	9b278793          	add	a5,a5,-1614 # 8001f9e8 <bcache+0x8268>
    8000303e:	02f48f63          	beq	s1,a5,8000307c <bread+0x70>
    80003042:	873e                	mv	a4,a5
    80003044:	a021                	j	8000304c <bread+0x40>
    80003046:	68a4                	ld	s1,80(s1)
    80003048:	02e48a63          	beq	s1,a4,8000307c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000304c:	449c                	lw	a5,8(s1)
    8000304e:	ff279ce3          	bne	a5,s2,80003046 <bread+0x3a>
    80003052:	44dc                	lw	a5,12(s1)
    80003054:	ff3799e3          	bne	a5,s3,80003046 <bread+0x3a>
      b->refcnt++;
    80003058:	40bc                	lw	a5,64(s1)
    8000305a:	2785                	addw	a5,a5,1
    8000305c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000305e:	00014517          	auipc	a0,0x14
    80003062:	72250513          	add	a0,a0,1826 # 80017780 <bcache>
    80003066:	ffffe097          	auipc	ra,0xffffe
    8000306a:	c4a080e7          	jalr	-950(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    8000306e:	01048513          	add	a0,s1,16
    80003072:	00001097          	auipc	ra,0x1
    80003076:	42e080e7          	jalr	1070(ra) # 800044a0 <acquiresleep>
      return b;
    8000307a:	a8b9                	j	800030d8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000307c:	0001d497          	auipc	s1,0x1d
    80003080:	9b44b483          	ld	s1,-1612(s1) # 8001fa30 <bcache+0x82b0>
    80003084:	0001d797          	auipc	a5,0x1d
    80003088:	96478793          	add	a5,a5,-1692 # 8001f9e8 <bcache+0x8268>
    8000308c:	00f48863          	beq	s1,a5,8000309c <bread+0x90>
    80003090:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003092:	40bc                	lw	a5,64(s1)
    80003094:	cf81                	beqz	a5,800030ac <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003096:	64a4                	ld	s1,72(s1)
    80003098:	fee49de3          	bne	s1,a4,80003092 <bread+0x86>
  panic("bget: no buffers");
    8000309c:	00005517          	auipc	a0,0x5
    800030a0:	4bc50513          	add	a0,a0,1212 # 80008558 <syscalls+0xc0>
    800030a4:	ffffd097          	auipc	ra,0xffffd
    800030a8:	49e080e7          	jalr	1182(ra) # 80000542 <panic>
      b->dev = dev;
    800030ac:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800030b0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800030b4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030b8:	4785                	li	a5,1
    800030ba:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030bc:	00014517          	auipc	a0,0x14
    800030c0:	6c450513          	add	a0,a0,1732 # 80017780 <bcache>
    800030c4:	ffffe097          	auipc	ra,0xffffe
    800030c8:	bec080e7          	jalr	-1044(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    800030cc:	01048513          	add	a0,s1,16
    800030d0:	00001097          	auipc	ra,0x1
    800030d4:	3d0080e7          	jalr	976(ra) # 800044a0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030d8:	409c                	lw	a5,0(s1)
    800030da:	cb89                	beqz	a5,800030ec <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030dc:	8526                	mv	a0,s1
    800030de:	70a2                	ld	ra,40(sp)
    800030e0:	7402                	ld	s0,32(sp)
    800030e2:	64e2                	ld	s1,24(sp)
    800030e4:	6942                	ld	s2,16(sp)
    800030e6:	69a2                	ld	s3,8(sp)
    800030e8:	6145                	add	sp,sp,48
    800030ea:	8082                	ret
    virtio_disk_rw(b, 0);
    800030ec:	4581                	li	a1,0
    800030ee:	8526                	mv	a0,s1
    800030f0:	00003097          	auipc	ra,0x3
    800030f4:	ee8080e7          	jalr	-280(ra) # 80005fd8 <virtio_disk_rw>
    b->valid = 1;
    800030f8:	4785                	li	a5,1
    800030fa:	c09c                	sw	a5,0(s1)
  return b;
    800030fc:	b7c5                	j	800030dc <bread+0xd0>

00000000800030fe <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030fe:	1101                	add	sp,sp,-32
    80003100:	ec06                	sd	ra,24(sp)
    80003102:	e822                	sd	s0,16(sp)
    80003104:	e426                	sd	s1,8(sp)
    80003106:	1000                	add	s0,sp,32
    80003108:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000310a:	0541                	add	a0,a0,16
    8000310c:	00001097          	auipc	ra,0x1
    80003110:	42e080e7          	jalr	1070(ra) # 8000453a <holdingsleep>
    80003114:	cd01                	beqz	a0,8000312c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003116:	4585                	li	a1,1
    80003118:	8526                	mv	a0,s1
    8000311a:	00003097          	auipc	ra,0x3
    8000311e:	ebe080e7          	jalr	-322(ra) # 80005fd8 <virtio_disk_rw>
}
    80003122:	60e2                	ld	ra,24(sp)
    80003124:	6442                	ld	s0,16(sp)
    80003126:	64a2                	ld	s1,8(sp)
    80003128:	6105                	add	sp,sp,32
    8000312a:	8082                	ret
    panic("bwrite");
    8000312c:	00005517          	auipc	a0,0x5
    80003130:	44450513          	add	a0,a0,1092 # 80008570 <syscalls+0xd8>
    80003134:	ffffd097          	auipc	ra,0xffffd
    80003138:	40e080e7          	jalr	1038(ra) # 80000542 <panic>

000000008000313c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000313c:	1101                	add	sp,sp,-32
    8000313e:	ec06                	sd	ra,24(sp)
    80003140:	e822                	sd	s0,16(sp)
    80003142:	e426                	sd	s1,8(sp)
    80003144:	e04a                	sd	s2,0(sp)
    80003146:	1000                	add	s0,sp,32
    80003148:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000314a:	01050913          	add	s2,a0,16
    8000314e:	854a                	mv	a0,s2
    80003150:	00001097          	auipc	ra,0x1
    80003154:	3ea080e7          	jalr	1002(ra) # 8000453a <holdingsleep>
    80003158:	c925                	beqz	a0,800031c8 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    8000315a:	854a                	mv	a0,s2
    8000315c:	00001097          	auipc	ra,0x1
    80003160:	39a080e7          	jalr	922(ra) # 800044f6 <releasesleep>

  acquire(&bcache.lock);
    80003164:	00014517          	auipc	a0,0x14
    80003168:	61c50513          	add	a0,a0,1564 # 80017780 <bcache>
    8000316c:	ffffe097          	auipc	ra,0xffffe
    80003170:	a90080e7          	jalr	-1392(ra) # 80000bfc <acquire>
  b->refcnt--;
    80003174:	40bc                	lw	a5,64(s1)
    80003176:	37fd                	addw	a5,a5,-1
    80003178:	0007871b          	sext.w	a4,a5
    8000317c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000317e:	e71d                	bnez	a4,800031ac <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003180:	68b8                	ld	a4,80(s1)
    80003182:	64bc                	ld	a5,72(s1)
    80003184:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003186:	68b8                	ld	a4,80(s1)
    80003188:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000318a:	0001c797          	auipc	a5,0x1c
    8000318e:	5f678793          	add	a5,a5,1526 # 8001f780 <bcache+0x8000>
    80003192:	2b87b703          	ld	a4,696(a5)
    80003196:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003198:	0001d717          	auipc	a4,0x1d
    8000319c:	85070713          	add	a4,a4,-1968 # 8001f9e8 <bcache+0x8268>
    800031a0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031a2:	2b87b703          	ld	a4,696(a5)
    800031a6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031a8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031ac:	00014517          	auipc	a0,0x14
    800031b0:	5d450513          	add	a0,a0,1492 # 80017780 <bcache>
    800031b4:	ffffe097          	auipc	ra,0xffffe
    800031b8:	afc080e7          	jalr	-1284(ra) # 80000cb0 <release>
}
    800031bc:	60e2                	ld	ra,24(sp)
    800031be:	6442                	ld	s0,16(sp)
    800031c0:	64a2                	ld	s1,8(sp)
    800031c2:	6902                	ld	s2,0(sp)
    800031c4:	6105                	add	sp,sp,32
    800031c6:	8082                	ret
    panic("brelse");
    800031c8:	00005517          	auipc	a0,0x5
    800031cc:	3b050513          	add	a0,a0,944 # 80008578 <syscalls+0xe0>
    800031d0:	ffffd097          	auipc	ra,0xffffd
    800031d4:	372080e7          	jalr	882(ra) # 80000542 <panic>

00000000800031d8 <bpin>:

void
bpin(struct buf *b) {
    800031d8:	1101                	add	sp,sp,-32
    800031da:	ec06                	sd	ra,24(sp)
    800031dc:	e822                	sd	s0,16(sp)
    800031de:	e426                	sd	s1,8(sp)
    800031e0:	1000                	add	s0,sp,32
    800031e2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031e4:	00014517          	auipc	a0,0x14
    800031e8:	59c50513          	add	a0,a0,1436 # 80017780 <bcache>
    800031ec:	ffffe097          	auipc	ra,0xffffe
    800031f0:	a10080e7          	jalr	-1520(ra) # 80000bfc <acquire>
  b->refcnt++;
    800031f4:	40bc                	lw	a5,64(s1)
    800031f6:	2785                	addw	a5,a5,1
    800031f8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031fa:	00014517          	auipc	a0,0x14
    800031fe:	58650513          	add	a0,a0,1414 # 80017780 <bcache>
    80003202:	ffffe097          	auipc	ra,0xffffe
    80003206:	aae080e7          	jalr	-1362(ra) # 80000cb0 <release>
}
    8000320a:	60e2                	ld	ra,24(sp)
    8000320c:	6442                	ld	s0,16(sp)
    8000320e:	64a2                	ld	s1,8(sp)
    80003210:	6105                	add	sp,sp,32
    80003212:	8082                	ret

0000000080003214 <bunpin>:

void
bunpin(struct buf *b) {
    80003214:	1101                	add	sp,sp,-32
    80003216:	ec06                	sd	ra,24(sp)
    80003218:	e822                	sd	s0,16(sp)
    8000321a:	e426                	sd	s1,8(sp)
    8000321c:	1000                	add	s0,sp,32
    8000321e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003220:	00014517          	auipc	a0,0x14
    80003224:	56050513          	add	a0,a0,1376 # 80017780 <bcache>
    80003228:	ffffe097          	auipc	ra,0xffffe
    8000322c:	9d4080e7          	jalr	-1580(ra) # 80000bfc <acquire>
  b->refcnt--;
    80003230:	40bc                	lw	a5,64(s1)
    80003232:	37fd                	addw	a5,a5,-1
    80003234:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003236:	00014517          	auipc	a0,0x14
    8000323a:	54a50513          	add	a0,a0,1354 # 80017780 <bcache>
    8000323e:	ffffe097          	auipc	ra,0xffffe
    80003242:	a72080e7          	jalr	-1422(ra) # 80000cb0 <release>
}
    80003246:	60e2                	ld	ra,24(sp)
    80003248:	6442                	ld	s0,16(sp)
    8000324a:	64a2                	ld	s1,8(sp)
    8000324c:	6105                	add	sp,sp,32
    8000324e:	8082                	ret

0000000080003250 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003250:	1101                	add	sp,sp,-32
    80003252:	ec06                	sd	ra,24(sp)
    80003254:	e822                	sd	s0,16(sp)
    80003256:	e426                	sd	s1,8(sp)
    80003258:	e04a                	sd	s2,0(sp)
    8000325a:	1000                	add	s0,sp,32
    8000325c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000325e:	00d5d59b          	srlw	a1,a1,0xd
    80003262:	0001d797          	auipc	a5,0x1d
    80003266:	bfa7a783          	lw	a5,-1030(a5) # 8001fe5c <sb+0x1c>
    8000326a:	9dbd                	addw	a1,a1,a5
    8000326c:	00000097          	auipc	ra,0x0
    80003270:	da0080e7          	jalr	-608(ra) # 8000300c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003274:	0074f713          	and	a4,s1,7
    80003278:	4785                	li	a5,1
    8000327a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000327e:	14ce                	sll	s1,s1,0x33
    80003280:	90d9                	srl	s1,s1,0x36
    80003282:	00950733          	add	a4,a0,s1
    80003286:	05874703          	lbu	a4,88(a4)
    8000328a:	00e7f6b3          	and	a3,a5,a4
    8000328e:	c69d                	beqz	a3,800032bc <bfree+0x6c>
    80003290:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003292:	94aa                	add	s1,s1,a0
    80003294:	fff7c793          	not	a5,a5
    80003298:	8f7d                	and	a4,a4,a5
    8000329a:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000329e:	00001097          	auipc	ra,0x1
    800032a2:	0dc080e7          	jalr	220(ra) # 8000437a <log_write>
  brelse(bp);
    800032a6:	854a                	mv	a0,s2
    800032a8:	00000097          	auipc	ra,0x0
    800032ac:	e94080e7          	jalr	-364(ra) # 8000313c <brelse>
}
    800032b0:	60e2                	ld	ra,24(sp)
    800032b2:	6442                	ld	s0,16(sp)
    800032b4:	64a2                	ld	s1,8(sp)
    800032b6:	6902                	ld	s2,0(sp)
    800032b8:	6105                	add	sp,sp,32
    800032ba:	8082                	ret
    panic("freeing free block");
    800032bc:	00005517          	auipc	a0,0x5
    800032c0:	2c450513          	add	a0,a0,708 # 80008580 <syscalls+0xe8>
    800032c4:	ffffd097          	auipc	ra,0xffffd
    800032c8:	27e080e7          	jalr	638(ra) # 80000542 <panic>

00000000800032cc <balloc>:
{
    800032cc:	711d                	add	sp,sp,-96
    800032ce:	ec86                	sd	ra,88(sp)
    800032d0:	e8a2                	sd	s0,80(sp)
    800032d2:	e4a6                	sd	s1,72(sp)
    800032d4:	e0ca                	sd	s2,64(sp)
    800032d6:	fc4e                	sd	s3,56(sp)
    800032d8:	f852                	sd	s4,48(sp)
    800032da:	f456                	sd	s5,40(sp)
    800032dc:	f05a                	sd	s6,32(sp)
    800032de:	ec5e                	sd	s7,24(sp)
    800032e0:	e862                	sd	s8,16(sp)
    800032e2:	e466                	sd	s9,8(sp)
    800032e4:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032e6:	0001d797          	auipc	a5,0x1d
    800032ea:	b5e7a783          	lw	a5,-1186(a5) # 8001fe44 <sb+0x4>
    800032ee:	cbc1                	beqz	a5,8000337e <balloc+0xb2>
    800032f0:	8baa                	mv	s7,a0
    800032f2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032f4:	0001db17          	auipc	s6,0x1d
    800032f8:	b4cb0b13          	add	s6,s6,-1204 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032fc:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032fe:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003300:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003302:	6c89                	lui	s9,0x2
    80003304:	a831                	j	80003320 <balloc+0x54>
    brelse(bp);
    80003306:	854a                	mv	a0,s2
    80003308:	00000097          	auipc	ra,0x0
    8000330c:	e34080e7          	jalr	-460(ra) # 8000313c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003310:	015c87bb          	addw	a5,s9,s5
    80003314:	00078a9b          	sext.w	s5,a5
    80003318:	004b2703          	lw	a4,4(s6)
    8000331c:	06eaf163          	bgeu	s5,a4,8000337e <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    80003320:	41fad79b          	sraw	a5,s5,0x1f
    80003324:	0137d79b          	srlw	a5,a5,0x13
    80003328:	015787bb          	addw	a5,a5,s5
    8000332c:	40d7d79b          	sraw	a5,a5,0xd
    80003330:	01cb2583          	lw	a1,28(s6)
    80003334:	9dbd                	addw	a1,a1,a5
    80003336:	855e                	mv	a0,s7
    80003338:	00000097          	auipc	ra,0x0
    8000333c:	cd4080e7          	jalr	-812(ra) # 8000300c <bread>
    80003340:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003342:	004b2503          	lw	a0,4(s6)
    80003346:	000a849b          	sext.w	s1,s5
    8000334a:	8762                	mv	a4,s8
    8000334c:	faa4fde3          	bgeu	s1,a0,80003306 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003350:	00777693          	and	a3,a4,7
    80003354:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003358:	41f7579b          	sraw	a5,a4,0x1f
    8000335c:	01d7d79b          	srlw	a5,a5,0x1d
    80003360:	9fb9                	addw	a5,a5,a4
    80003362:	4037d79b          	sraw	a5,a5,0x3
    80003366:	00f90633          	add	a2,s2,a5
    8000336a:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    8000336e:	00c6f5b3          	and	a1,a3,a2
    80003372:	cd91                	beqz	a1,8000338e <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003374:	2705                	addw	a4,a4,1
    80003376:	2485                	addw	s1,s1,1
    80003378:	fd471ae3          	bne	a4,s4,8000334c <balloc+0x80>
    8000337c:	b769                	j	80003306 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000337e:	00005517          	auipc	a0,0x5
    80003382:	21a50513          	add	a0,a0,538 # 80008598 <syscalls+0x100>
    80003386:	ffffd097          	auipc	ra,0xffffd
    8000338a:	1bc080e7          	jalr	444(ra) # 80000542 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000338e:	97ca                	add	a5,a5,s2
    80003390:	8e55                	or	a2,a2,a3
    80003392:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003396:	854a                	mv	a0,s2
    80003398:	00001097          	auipc	ra,0x1
    8000339c:	fe2080e7          	jalr	-30(ra) # 8000437a <log_write>
        brelse(bp);
    800033a0:	854a                	mv	a0,s2
    800033a2:	00000097          	auipc	ra,0x0
    800033a6:	d9a080e7          	jalr	-614(ra) # 8000313c <brelse>
  bp = bread(dev, bno);
    800033aa:	85a6                	mv	a1,s1
    800033ac:	855e                	mv	a0,s7
    800033ae:	00000097          	auipc	ra,0x0
    800033b2:	c5e080e7          	jalr	-930(ra) # 8000300c <bread>
    800033b6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033b8:	40000613          	li	a2,1024
    800033bc:	4581                	li	a1,0
    800033be:	05850513          	add	a0,a0,88
    800033c2:	ffffe097          	auipc	ra,0xffffe
    800033c6:	936080e7          	jalr	-1738(ra) # 80000cf8 <memset>
  log_write(bp);
    800033ca:	854a                	mv	a0,s2
    800033cc:	00001097          	auipc	ra,0x1
    800033d0:	fae080e7          	jalr	-82(ra) # 8000437a <log_write>
  brelse(bp);
    800033d4:	854a                	mv	a0,s2
    800033d6:	00000097          	auipc	ra,0x0
    800033da:	d66080e7          	jalr	-666(ra) # 8000313c <brelse>
}
    800033de:	8526                	mv	a0,s1
    800033e0:	60e6                	ld	ra,88(sp)
    800033e2:	6446                	ld	s0,80(sp)
    800033e4:	64a6                	ld	s1,72(sp)
    800033e6:	6906                	ld	s2,64(sp)
    800033e8:	79e2                	ld	s3,56(sp)
    800033ea:	7a42                	ld	s4,48(sp)
    800033ec:	7aa2                	ld	s5,40(sp)
    800033ee:	7b02                	ld	s6,32(sp)
    800033f0:	6be2                	ld	s7,24(sp)
    800033f2:	6c42                	ld	s8,16(sp)
    800033f4:	6ca2                	ld	s9,8(sp)
    800033f6:	6125                	add	sp,sp,96
    800033f8:	8082                	ret

00000000800033fa <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800033fa:	7179                	add	sp,sp,-48
    800033fc:	f406                	sd	ra,40(sp)
    800033fe:	f022                	sd	s0,32(sp)
    80003400:	ec26                	sd	s1,24(sp)
    80003402:	e84a                	sd	s2,16(sp)
    80003404:	e44e                	sd	s3,8(sp)
    80003406:	e052                	sd	s4,0(sp)
    80003408:	1800                	add	s0,sp,48
    8000340a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000340c:	47ad                	li	a5,11
    8000340e:	04b7fe63          	bgeu	a5,a1,8000346a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003412:	ff45849b          	addw	s1,a1,-12
    80003416:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000341a:	0ff00793          	li	a5,255
    8000341e:	0ae7e463          	bltu	a5,a4,800034c6 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003422:	08052583          	lw	a1,128(a0)
    80003426:	c5b5                	beqz	a1,80003492 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003428:	00092503          	lw	a0,0(s2)
    8000342c:	00000097          	auipc	ra,0x0
    80003430:	be0080e7          	jalr	-1056(ra) # 8000300c <bread>
    80003434:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003436:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    8000343a:	02049713          	sll	a4,s1,0x20
    8000343e:	01e75593          	srl	a1,a4,0x1e
    80003442:	00b784b3          	add	s1,a5,a1
    80003446:	0004a983          	lw	s3,0(s1)
    8000344a:	04098e63          	beqz	s3,800034a6 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000344e:	8552                	mv	a0,s4
    80003450:	00000097          	auipc	ra,0x0
    80003454:	cec080e7          	jalr	-788(ra) # 8000313c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003458:	854e                	mv	a0,s3
    8000345a:	70a2                	ld	ra,40(sp)
    8000345c:	7402                	ld	s0,32(sp)
    8000345e:	64e2                	ld	s1,24(sp)
    80003460:	6942                	ld	s2,16(sp)
    80003462:	69a2                	ld	s3,8(sp)
    80003464:	6a02                	ld	s4,0(sp)
    80003466:	6145                	add	sp,sp,48
    80003468:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000346a:	02059793          	sll	a5,a1,0x20
    8000346e:	01e7d593          	srl	a1,a5,0x1e
    80003472:	00b504b3          	add	s1,a0,a1
    80003476:	0504a983          	lw	s3,80(s1)
    8000347a:	fc099fe3          	bnez	s3,80003458 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000347e:	4108                	lw	a0,0(a0)
    80003480:	00000097          	auipc	ra,0x0
    80003484:	e4c080e7          	jalr	-436(ra) # 800032cc <balloc>
    80003488:	0005099b          	sext.w	s3,a0
    8000348c:	0534a823          	sw	s3,80(s1)
    80003490:	b7e1                	j	80003458 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003492:	4108                	lw	a0,0(a0)
    80003494:	00000097          	auipc	ra,0x0
    80003498:	e38080e7          	jalr	-456(ra) # 800032cc <balloc>
    8000349c:	0005059b          	sext.w	a1,a0
    800034a0:	08b92023          	sw	a1,128(s2)
    800034a4:	b751                	j	80003428 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034a6:	00092503          	lw	a0,0(s2)
    800034aa:	00000097          	auipc	ra,0x0
    800034ae:	e22080e7          	jalr	-478(ra) # 800032cc <balloc>
    800034b2:	0005099b          	sext.w	s3,a0
    800034b6:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800034ba:	8552                	mv	a0,s4
    800034bc:	00001097          	auipc	ra,0x1
    800034c0:	ebe080e7          	jalr	-322(ra) # 8000437a <log_write>
    800034c4:	b769                	j	8000344e <bmap+0x54>
  panic("bmap: out of range");
    800034c6:	00005517          	auipc	a0,0x5
    800034ca:	0ea50513          	add	a0,a0,234 # 800085b0 <syscalls+0x118>
    800034ce:	ffffd097          	auipc	ra,0xffffd
    800034d2:	074080e7          	jalr	116(ra) # 80000542 <panic>

00000000800034d6 <iget>:
{
    800034d6:	7179                	add	sp,sp,-48
    800034d8:	f406                	sd	ra,40(sp)
    800034da:	f022                	sd	s0,32(sp)
    800034dc:	ec26                	sd	s1,24(sp)
    800034de:	e84a                	sd	s2,16(sp)
    800034e0:	e44e                	sd	s3,8(sp)
    800034e2:	e052                	sd	s4,0(sp)
    800034e4:	1800                	add	s0,sp,48
    800034e6:	89aa                	mv	s3,a0
    800034e8:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800034ea:	0001d517          	auipc	a0,0x1d
    800034ee:	97650513          	add	a0,a0,-1674 # 8001fe60 <icache>
    800034f2:	ffffd097          	auipc	ra,0xffffd
    800034f6:	70a080e7          	jalr	1802(ra) # 80000bfc <acquire>
  empty = 0;
    800034fa:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034fc:	0001d497          	auipc	s1,0x1d
    80003500:	97c48493          	add	s1,s1,-1668 # 8001fe78 <icache+0x18>
    80003504:	0001e697          	auipc	a3,0x1e
    80003508:	40468693          	add	a3,a3,1028 # 80021908 <log>
    8000350c:	a039                	j	8000351a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000350e:	02090b63          	beqz	s2,80003544 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003512:	08848493          	add	s1,s1,136
    80003516:	02d48a63          	beq	s1,a3,8000354a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000351a:	449c                	lw	a5,8(s1)
    8000351c:	fef059e3          	blez	a5,8000350e <iget+0x38>
    80003520:	4098                	lw	a4,0(s1)
    80003522:	ff3716e3          	bne	a4,s3,8000350e <iget+0x38>
    80003526:	40d8                	lw	a4,4(s1)
    80003528:	ff4713e3          	bne	a4,s4,8000350e <iget+0x38>
      ip->ref++;
    8000352c:	2785                	addw	a5,a5,1
    8000352e:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003530:	0001d517          	auipc	a0,0x1d
    80003534:	93050513          	add	a0,a0,-1744 # 8001fe60 <icache>
    80003538:	ffffd097          	auipc	ra,0xffffd
    8000353c:	778080e7          	jalr	1912(ra) # 80000cb0 <release>
      return ip;
    80003540:	8926                	mv	s2,s1
    80003542:	a03d                	j	80003570 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003544:	f7f9                	bnez	a5,80003512 <iget+0x3c>
    80003546:	8926                	mv	s2,s1
    80003548:	b7e9                	j	80003512 <iget+0x3c>
  if(empty == 0)
    8000354a:	02090c63          	beqz	s2,80003582 <iget+0xac>
  ip->dev = dev;
    8000354e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003552:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003556:	4785                	li	a5,1
    80003558:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000355c:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003560:	0001d517          	auipc	a0,0x1d
    80003564:	90050513          	add	a0,a0,-1792 # 8001fe60 <icache>
    80003568:	ffffd097          	auipc	ra,0xffffd
    8000356c:	748080e7          	jalr	1864(ra) # 80000cb0 <release>
}
    80003570:	854a                	mv	a0,s2
    80003572:	70a2                	ld	ra,40(sp)
    80003574:	7402                	ld	s0,32(sp)
    80003576:	64e2                	ld	s1,24(sp)
    80003578:	6942                	ld	s2,16(sp)
    8000357a:	69a2                	ld	s3,8(sp)
    8000357c:	6a02                	ld	s4,0(sp)
    8000357e:	6145                	add	sp,sp,48
    80003580:	8082                	ret
    panic("iget: no inodes");
    80003582:	00005517          	auipc	a0,0x5
    80003586:	04650513          	add	a0,a0,70 # 800085c8 <syscalls+0x130>
    8000358a:	ffffd097          	auipc	ra,0xffffd
    8000358e:	fb8080e7          	jalr	-72(ra) # 80000542 <panic>

0000000080003592 <fsinit>:
fsinit(int dev) {
    80003592:	7179                	add	sp,sp,-48
    80003594:	f406                	sd	ra,40(sp)
    80003596:	f022                	sd	s0,32(sp)
    80003598:	ec26                	sd	s1,24(sp)
    8000359a:	e84a                	sd	s2,16(sp)
    8000359c:	e44e                	sd	s3,8(sp)
    8000359e:	1800                	add	s0,sp,48
    800035a0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035a2:	4585                	li	a1,1
    800035a4:	00000097          	auipc	ra,0x0
    800035a8:	a68080e7          	jalr	-1432(ra) # 8000300c <bread>
    800035ac:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035ae:	0001d997          	auipc	s3,0x1d
    800035b2:	89298993          	add	s3,s3,-1902 # 8001fe40 <sb>
    800035b6:	02000613          	li	a2,32
    800035ba:	05850593          	add	a1,a0,88
    800035be:	854e                	mv	a0,s3
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	794080e7          	jalr	1940(ra) # 80000d54 <memmove>
  brelse(bp);
    800035c8:	8526                	mv	a0,s1
    800035ca:	00000097          	auipc	ra,0x0
    800035ce:	b72080e7          	jalr	-1166(ra) # 8000313c <brelse>
  if(sb.magic != FSMAGIC)
    800035d2:	0009a703          	lw	a4,0(s3)
    800035d6:	102037b7          	lui	a5,0x10203
    800035da:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035de:	02f71263          	bne	a4,a5,80003602 <fsinit+0x70>
  initlog(dev, &sb);
    800035e2:	0001d597          	auipc	a1,0x1d
    800035e6:	85e58593          	add	a1,a1,-1954 # 8001fe40 <sb>
    800035ea:	854a                	mv	a0,s2
    800035ec:	00001097          	auipc	ra,0x1
    800035f0:	b28080e7          	jalr	-1240(ra) # 80004114 <initlog>
}
    800035f4:	70a2                	ld	ra,40(sp)
    800035f6:	7402                	ld	s0,32(sp)
    800035f8:	64e2                	ld	s1,24(sp)
    800035fa:	6942                	ld	s2,16(sp)
    800035fc:	69a2                	ld	s3,8(sp)
    800035fe:	6145                	add	sp,sp,48
    80003600:	8082                	ret
    panic("invalid file system");
    80003602:	00005517          	auipc	a0,0x5
    80003606:	fd650513          	add	a0,a0,-42 # 800085d8 <syscalls+0x140>
    8000360a:	ffffd097          	auipc	ra,0xffffd
    8000360e:	f38080e7          	jalr	-200(ra) # 80000542 <panic>

0000000080003612 <iinit>:
{
    80003612:	7179                	add	sp,sp,-48
    80003614:	f406                	sd	ra,40(sp)
    80003616:	f022                	sd	s0,32(sp)
    80003618:	ec26                	sd	s1,24(sp)
    8000361a:	e84a                	sd	s2,16(sp)
    8000361c:	e44e                	sd	s3,8(sp)
    8000361e:	1800                	add	s0,sp,48
  initlock(&icache.lock, "icache");
    80003620:	00005597          	auipc	a1,0x5
    80003624:	fd058593          	add	a1,a1,-48 # 800085f0 <syscalls+0x158>
    80003628:	0001d517          	auipc	a0,0x1d
    8000362c:	83850513          	add	a0,a0,-1992 # 8001fe60 <icache>
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	53c080e7          	jalr	1340(ra) # 80000b6c <initlock>
  for(i = 0; i < NINODE; i++) {
    80003638:	0001d497          	auipc	s1,0x1d
    8000363c:	85048493          	add	s1,s1,-1968 # 8001fe88 <icache+0x28>
    80003640:	0001e997          	auipc	s3,0x1e
    80003644:	2d898993          	add	s3,s3,728 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003648:	00005917          	auipc	s2,0x5
    8000364c:	fb090913          	add	s2,s2,-80 # 800085f8 <syscalls+0x160>
    80003650:	85ca                	mv	a1,s2
    80003652:	8526                	mv	a0,s1
    80003654:	00001097          	auipc	ra,0x1
    80003658:	e12080e7          	jalr	-494(ra) # 80004466 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000365c:	08848493          	add	s1,s1,136
    80003660:	ff3498e3          	bne	s1,s3,80003650 <iinit+0x3e>
}
    80003664:	70a2                	ld	ra,40(sp)
    80003666:	7402                	ld	s0,32(sp)
    80003668:	64e2                	ld	s1,24(sp)
    8000366a:	6942                	ld	s2,16(sp)
    8000366c:	69a2                	ld	s3,8(sp)
    8000366e:	6145                	add	sp,sp,48
    80003670:	8082                	ret

0000000080003672 <ialloc>:
{
    80003672:	7139                	add	sp,sp,-64
    80003674:	fc06                	sd	ra,56(sp)
    80003676:	f822                	sd	s0,48(sp)
    80003678:	f426                	sd	s1,40(sp)
    8000367a:	f04a                	sd	s2,32(sp)
    8000367c:	ec4e                	sd	s3,24(sp)
    8000367e:	e852                	sd	s4,16(sp)
    80003680:	e456                	sd	s5,8(sp)
    80003682:	e05a                	sd	s6,0(sp)
    80003684:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003686:	0001c717          	auipc	a4,0x1c
    8000368a:	7c672703          	lw	a4,1990(a4) # 8001fe4c <sb+0xc>
    8000368e:	4785                	li	a5,1
    80003690:	04e7f863          	bgeu	a5,a4,800036e0 <ialloc+0x6e>
    80003694:	8aaa                	mv	s5,a0
    80003696:	8b2e                	mv	s6,a1
    80003698:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000369a:	0001ca17          	auipc	s4,0x1c
    8000369e:	7a6a0a13          	add	s4,s4,1958 # 8001fe40 <sb>
    800036a2:	00495593          	srl	a1,s2,0x4
    800036a6:	018a2783          	lw	a5,24(s4)
    800036aa:	9dbd                	addw	a1,a1,a5
    800036ac:	8556                	mv	a0,s5
    800036ae:	00000097          	auipc	ra,0x0
    800036b2:	95e080e7          	jalr	-1698(ra) # 8000300c <bread>
    800036b6:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036b8:	05850993          	add	s3,a0,88
    800036bc:	00f97793          	and	a5,s2,15
    800036c0:	079a                	sll	a5,a5,0x6
    800036c2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036c4:	00099783          	lh	a5,0(s3)
    800036c8:	c785                	beqz	a5,800036f0 <ialloc+0x7e>
    brelse(bp);
    800036ca:	00000097          	auipc	ra,0x0
    800036ce:	a72080e7          	jalr	-1422(ra) # 8000313c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036d2:	0905                	add	s2,s2,1
    800036d4:	00ca2703          	lw	a4,12(s4)
    800036d8:	0009079b          	sext.w	a5,s2
    800036dc:	fce7e3e3          	bltu	a5,a4,800036a2 <ialloc+0x30>
  panic("ialloc: no inodes");
    800036e0:	00005517          	auipc	a0,0x5
    800036e4:	f2050513          	add	a0,a0,-224 # 80008600 <syscalls+0x168>
    800036e8:	ffffd097          	auipc	ra,0xffffd
    800036ec:	e5a080e7          	jalr	-422(ra) # 80000542 <panic>
      memset(dip, 0, sizeof(*dip));
    800036f0:	04000613          	li	a2,64
    800036f4:	4581                	li	a1,0
    800036f6:	854e                	mv	a0,s3
    800036f8:	ffffd097          	auipc	ra,0xffffd
    800036fc:	600080e7          	jalr	1536(ra) # 80000cf8 <memset>
      dip->type = type;
    80003700:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003704:	8526                	mv	a0,s1
    80003706:	00001097          	auipc	ra,0x1
    8000370a:	c74080e7          	jalr	-908(ra) # 8000437a <log_write>
      brelse(bp);
    8000370e:	8526                	mv	a0,s1
    80003710:	00000097          	auipc	ra,0x0
    80003714:	a2c080e7          	jalr	-1492(ra) # 8000313c <brelse>
      return iget(dev, inum);
    80003718:	0009059b          	sext.w	a1,s2
    8000371c:	8556                	mv	a0,s5
    8000371e:	00000097          	auipc	ra,0x0
    80003722:	db8080e7          	jalr	-584(ra) # 800034d6 <iget>
}
    80003726:	70e2                	ld	ra,56(sp)
    80003728:	7442                	ld	s0,48(sp)
    8000372a:	74a2                	ld	s1,40(sp)
    8000372c:	7902                	ld	s2,32(sp)
    8000372e:	69e2                	ld	s3,24(sp)
    80003730:	6a42                	ld	s4,16(sp)
    80003732:	6aa2                	ld	s5,8(sp)
    80003734:	6b02                	ld	s6,0(sp)
    80003736:	6121                	add	sp,sp,64
    80003738:	8082                	ret

000000008000373a <iupdate>:
{
    8000373a:	1101                	add	sp,sp,-32
    8000373c:	ec06                	sd	ra,24(sp)
    8000373e:	e822                	sd	s0,16(sp)
    80003740:	e426                	sd	s1,8(sp)
    80003742:	e04a                	sd	s2,0(sp)
    80003744:	1000                	add	s0,sp,32
    80003746:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003748:	415c                	lw	a5,4(a0)
    8000374a:	0047d79b          	srlw	a5,a5,0x4
    8000374e:	0001c597          	auipc	a1,0x1c
    80003752:	70a5a583          	lw	a1,1802(a1) # 8001fe58 <sb+0x18>
    80003756:	9dbd                	addw	a1,a1,a5
    80003758:	4108                	lw	a0,0(a0)
    8000375a:	00000097          	auipc	ra,0x0
    8000375e:	8b2080e7          	jalr	-1870(ra) # 8000300c <bread>
    80003762:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003764:	05850793          	add	a5,a0,88
    80003768:	40d8                	lw	a4,4(s1)
    8000376a:	8b3d                	and	a4,a4,15
    8000376c:	071a                	sll	a4,a4,0x6
    8000376e:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003770:	04449703          	lh	a4,68(s1)
    80003774:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003778:	04649703          	lh	a4,70(s1)
    8000377c:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003780:	04849703          	lh	a4,72(s1)
    80003784:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003788:	04a49703          	lh	a4,74(s1)
    8000378c:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003790:	44f8                	lw	a4,76(s1)
    80003792:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003794:	03400613          	li	a2,52
    80003798:	05048593          	add	a1,s1,80
    8000379c:	00c78513          	add	a0,a5,12
    800037a0:	ffffd097          	auipc	ra,0xffffd
    800037a4:	5b4080e7          	jalr	1460(ra) # 80000d54 <memmove>
  log_write(bp);
    800037a8:	854a                	mv	a0,s2
    800037aa:	00001097          	auipc	ra,0x1
    800037ae:	bd0080e7          	jalr	-1072(ra) # 8000437a <log_write>
  brelse(bp);
    800037b2:	854a                	mv	a0,s2
    800037b4:	00000097          	auipc	ra,0x0
    800037b8:	988080e7          	jalr	-1656(ra) # 8000313c <brelse>
}
    800037bc:	60e2                	ld	ra,24(sp)
    800037be:	6442                	ld	s0,16(sp)
    800037c0:	64a2                	ld	s1,8(sp)
    800037c2:	6902                	ld	s2,0(sp)
    800037c4:	6105                	add	sp,sp,32
    800037c6:	8082                	ret

00000000800037c8 <idup>:
{
    800037c8:	1101                	add	sp,sp,-32
    800037ca:	ec06                	sd	ra,24(sp)
    800037cc:	e822                	sd	s0,16(sp)
    800037ce:	e426                	sd	s1,8(sp)
    800037d0:	1000                	add	s0,sp,32
    800037d2:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800037d4:	0001c517          	auipc	a0,0x1c
    800037d8:	68c50513          	add	a0,a0,1676 # 8001fe60 <icache>
    800037dc:	ffffd097          	auipc	ra,0xffffd
    800037e0:	420080e7          	jalr	1056(ra) # 80000bfc <acquire>
  ip->ref++;
    800037e4:	449c                	lw	a5,8(s1)
    800037e6:	2785                	addw	a5,a5,1
    800037e8:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800037ea:	0001c517          	auipc	a0,0x1c
    800037ee:	67650513          	add	a0,a0,1654 # 8001fe60 <icache>
    800037f2:	ffffd097          	auipc	ra,0xffffd
    800037f6:	4be080e7          	jalr	1214(ra) # 80000cb0 <release>
}
    800037fa:	8526                	mv	a0,s1
    800037fc:	60e2                	ld	ra,24(sp)
    800037fe:	6442                	ld	s0,16(sp)
    80003800:	64a2                	ld	s1,8(sp)
    80003802:	6105                	add	sp,sp,32
    80003804:	8082                	ret

0000000080003806 <ilock>:
{
    80003806:	1101                	add	sp,sp,-32
    80003808:	ec06                	sd	ra,24(sp)
    8000380a:	e822                	sd	s0,16(sp)
    8000380c:	e426                	sd	s1,8(sp)
    8000380e:	e04a                	sd	s2,0(sp)
    80003810:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003812:	c115                	beqz	a0,80003836 <ilock+0x30>
    80003814:	84aa                	mv	s1,a0
    80003816:	451c                	lw	a5,8(a0)
    80003818:	00f05f63          	blez	a5,80003836 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000381c:	0541                	add	a0,a0,16
    8000381e:	00001097          	auipc	ra,0x1
    80003822:	c82080e7          	jalr	-894(ra) # 800044a0 <acquiresleep>
  if(ip->valid == 0){
    80003826:	40bc                	lw	a5,64(s1)
    80003828:	cf99                	beqz	a5,80003846 <ilock+0x40>
}
    8000382a:	60e2                	ld	ra,24(sp)
    8000382c:	6442                	ld	s0,16(sp)
    8000382e:	64a2                	ld	s1,8(sp)
    80003830:	6902                	ld	s2,0(sp)
    80003832:	6105                	add	sp,sp,32
    80003834:	8082                	ret
    panic("ilock");
    80003836:	00005517          	auipc	a0,0x5
    8000383a:	de250513          	add	a0,a0,-542 # 80008618 <syscalls+0x180>
    8000383e:	ffffd097          	auipc	ra,0xffffd
    80003842:	d04080e7          	jalr	-764(ra) # 80000542 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003846:	40dc                	lw	a5,4(s1)
    80003848:	0047d79b          	srlw	a5,a5,0x4
    8000384c:	0001c597          	auipc	a1,0x1c
    80003850:	60c5a583          	lw	a1,1548(a1) # 8001fe58 <sb+0x18>
    80003854:	9dbd                	addw	a1,a1,a5
    80003856:	4088                	lw	a0,0(s1)
    80003858:	fffff097          	auipc	ra,0xfffff
    8000385c:	7b4080e7          	jalr	1972(ra) # 8000300c <bread>
    80003860:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003862:	05850593          	add	a1,a0,88
    80003866:	40dc                	lw	a5,4(s1)
    80003868:	8bbd                	and	a5,a5,15
    8000386a:	079a                	sll	a5,a5,0x6
    8000386c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000386e:	00059783          	lh	a5,0(a1)
    80003872:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003876:	00259783          	lh	a5,2(a1)
    8000387a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000387e:	00459783          	lh	a5,4(a1)
    80003882:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003886:	00659783          	lh	a5,6(a1)
    8000388a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000388e:	459c                	lw	a5,8(a1)
    80003890:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003892:	03400613          	li	a2,52
    80003896:	05b1                	add	a1,a1,12
    80003898:	05048513          	add	a0,s1,80
    8000389c:	ffffd097          	auipc	ra,0xffffd
    800038a0:	4b8080e7          	jalr	1208(ra) # 80000d54 <memmove>
    brelse(bp);
    800038a4:	854a                	mv	a0,s2
    800038a6:	00000097          	auipc	ra,0x0
    800038aa:	896080e7          	jalr	-1898(ra) # 8000313c <brelse>
    ip->valid = 1;
    800038ae:	4785                	li	a5,1
    800038b0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038b2:	04449783          	lh	a5,68(s1)
    800038b6:	fbb5                	bnez	a5,8000382a <ilock+0x24>
      panic("ilock: no type");
    800038b8:	00005517          	auipc	a0,0x5
    800038bc:	d6850513          	add	a0,a0,-664 # 80008620 <syscalls+0x188>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	c82080e7          	jalr	-894(ra) # 80000542 <panic>

00000000800038c8 <iunlock>:
{
    800038c8:	1101                	add	sp,sp,-32
    800038ca:	ec06                	sd	ra,24(sp)
    800038cc:	e822                	sd	s0,16(sp)
    800038ce:	e426                	sd	s1,8(sp)
    800038d0:	e04a                	sd	s2,0(sp)
    800038d2:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038d4:	c905                	beqz	a0,80003904 <iunlock+0x3c>
    800038d6:	84aa                	mv	s1,a0
    800038d8:	01050913          	add	s2,a0,16
    800038dc:	854a                	mv	a0,s2
    800038de:	00001097          	auipc	ra,0x1
    800038e2:	c5c080e7          	jalr	-932(ra) # 8000453a <holdingsleep>
    800038e6:	cd19                	beqz	a0,80003904 <iunlock+0x3c>
    800038e8:	449c                	lw	a5,8(s1)
    800038ea:	00f05d63          	blez	a5,80003904 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038ee:	854a                	mv	a0,s2
    800038f0:	00001097          	auipc	ra,0x1
    800038f4:	c06080e7          	jalr	-1018(ra) # 800044f6 <releasesleep>
}
    800038f8:	60e2                	ld	ra,24(sp)
    800038fa:	6442                	ld	s0,16(sp)
    800038fc:	64a2                	ld	s1,8(sp)
    800038fe:	6902                	ld	s2,0(sp)
    80003900:	6105                	add	sp,sp,32
    80003902:	8082                	ret
    panic("iunlock");
    80003904:	00005517          	auipc	a0,0x5
    80003908:	d2c50513          	add	a0,a0,-724 # 80008630 <syscalls+0x198>
    8000390c:	ffffd097          	auipc	ra,0xffffd
    80003910:	c36080e7          	jalr	-970(ra) # 80000542 <panic>

0000000080003914 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003914:	7179                	add	sp,sp,-48
    80003916:	f406                	sd	ra,40(sp)
    80003918:	f022                	sd	s0,32(sp)
    8000391a:	ec26                	sd	s1,24(sp)
    8000391c:	e84a                	sd	s2,16(sp)
    8000391e:	e44e                	sd	s3,8(sp)
    80003920:	e052                	sd	s4,0(sp)
    80003922:	1800                	add	s0,sp,48
    80003924:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003926:	05050493          	add	s1,a0,80
    8000392a:	08050913          	add	s2,a0,128
    8000392e:	a021                	j	80003936 <itrunc+0x22>
    80003930:	0491                	add	s1,s1,4
    80003932:	01248d63          	beq	s1,s2,8000394c <itrunc+0x38>
    if(ip->addrs[i]){
    80003936:	408c                	lw	a1,0(s1)
    80003938:	dde5                	beqz	a1,80003930 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000393a:	0009a503          	lw	a0,0(s3)
    8000393e:	00000097          	auipc	ra,0x0
    80003942:	912080e7          	jalr	-1774(ra) # 80003250 <bfree>
      ip->addrs[i] = 0;
    80003946:	0004a023          	sw	zero,0(s1)
    8000394a:	b7dd                	j	80003930 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000394c:	0809a583          	lw	a1,128(s3)
    80003950:	e185                	bnez	a1,80003970 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003952:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003956:	854e                	mv	a0,s3
    80003958:	00000097          	auipc	ra,0x0
    8000395c:	de2080e7          	jalr	-542(ra) # 8000373a <iupdate>
}
    80003960:	70a2                	ld	ra,40(sp)
    80003962:	7402                	ld	s0,32(sp)
    80003964:	64e2                	ld	s1,24(sp)
    80003966:	6942                	ld	s2,16(sp)
    80003968:	69a2                	ld	s3,8(sp)
    8000396a:	6a02                	ld	s4,0(sp)
    8000396c:	6145                	add	sp,sp,48
    8000396e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003970:	0009a503          	lw	a0,0(s3)
    80003974:	fffff097          	auipc	ra,0xfffff
    80003978:	698080e7          	jalr	1688(ra) # 8000300c <bread>
    8000397c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000397e:	05850493          	add	s1,a0,88
    80003982:	45850913          	add	s2,a0,1112
    80003986:	a021                	j	8000398e <itrunc+0x7a>
    80003988:	0491                	add	s1,s1,4
    8000398a:	01248b63          	beq	s1,s2,800039a0 <itrunc+0x8c>
      if(a[j])
    8000398e:	408c                	lw	a1,0(s1)
    80003990:	dde5                	beqz	a1,80003988 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003992:	0009a503          	lw	a0,0(s3)
    80003996:	00000097          	auipc	ra,0x0
    8000399a:	8ba080e7          	jalr	-1862(ra) # 80003250 <bfree>
    8000399e:	b7ed                	j	80003988 <itrunc+0x74>
    brelse(bp);
    800039a0:	8552                	mv	a0,s4
    800039a2:	fffff097          	auipc	ra,0xfffff
    800039a6:	79a080e7          	jalr	1946(ra) # 8000313c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039aa:	0809a583          	lw	a1,128(s3)
    800039ae:	0009a503          	lw	a0,0(s3)
    800039b2:	00000097          	auipc	ra,0x0
    800039b6:	89e080e7          	jalr	-1890(ra) # 80003250 <bfree>
    ip->addrs[NDIRECT] = 0;
    800039ba:	0809a023          	sw	zero,128(s3)
    800039be:	bf51                	j	80003952 <itrunc+0x3e>

00000000800039c0 <iput>:
{
    800039c0:	1101                	add	sp,sp,-32
    800039c2:	ec06                	sd	ra,24(sp)
    800039c4:	e822                	sd	s0,16(sp)
    800039c6:	e426                	sd	s1,8(sp)
    800039c8:	e04a                	sd	s2,0(sp)
    800039ca:	1000                	add	s0,sp,32
    800039cc:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800039ce:	0001c517          	auipc	a0,0x1c
    800039d2:	49250513          	add	a0,a0,1170 # 8001fe60 <icache>
    800039d6:	ffffd097          	auipc	ra,0xffffd
    800039da:	226080e7          	jalr	550(ra) # 80000bfc <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039de:	4498                	lw	a4,8(s1)
    800039e0:	4785                	li	a5,1
    800039e2:	02f70363          	beq	a4,a5,80003a08 <iput+0x48>
  ip->ref--;
    800039e6:	449c                	lw	a5,8(s1)
    800039e8:	37fd                	addw	a5,a5,-1
    800039ea:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800039ec:	0001c517          	auipc	a0,0x1c
    800039f0:	47450513          	add	a0,a0,1140 # 8001fe60 <icache>
    800039f4:	ffffd097          	auipc	ra,0xffffd
    800039f8:	2bc080e7          	jalr	700(ra) # 80000cb0 <release>
}
    800039fc:	60e2                	ld	ra,24(sp)
    800039fe:	6442                	ld	s0,16(sp)
    80003a00:	64a2                	ld	s1,8(sp)
    80003a02:	6902                	ld	s2,0(sp)
    80003a04:	6105                	add	sp,sp,32
    80003a06:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a08:	40bc                	lw	a5,64(s1)
    80003a0a:	dff1                	beqz	a5,800039e6 <iput+0x26>
    80003a0c:	04a49783          	lh	a5,74(s1)
    80003a10:	fbf9                	bnez	a5,800039e6 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a12:	01048913          	add	s2,s1,16
    80003a16:	854a                	mv	a0,s2
    80003a18:	00001097          	auipc	ra,0x1
    80003a1c:	a88080e7          	jalr	-1400(ra) # 800044a0 <acquiresleep>
    release(&icache.lock);
    80003a20:	0001c517          	auipc	a0,0x1c
    80003a24:	44050513          	add	a0,a0,1088 # 8001fe60 <icache>
    80003a28:	ffffd097          	auipc	ra,0xffffd
    80003a2c:	288080e7          	jalr	648(ra) # 80000cb0 <release>
    itrunc(ip);
    80003a30:	8526                	mv	a0,s1
    80003a32:	00000097          	auipc	ra,0x0
    80003a36:	ee2080e7          	jalr	-286(ra) # 80003914 <itrunc>
    ip->type = 0;
    80003a3a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a3e:	8526                	mv	a0,s1
    80003a40:	00000097          	auipc	ra,0x0
    80003a44:	cfa080e7          	jalr	-774(ra) # 8000373a <iupdate>
    ip->valid = 0;
    80003a48:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a4c:	854a                	mv	a0,s2
    80003a4e:	00001097          	auipc	ra,0x1
    80003a52:	aa8080e7          	jalr	-1368(ra) # 800044f6 <releasesleep>
    acquire(&icache.lock);
    80003a56:	0001c517          	auipc	a0,0x1c
    80003a5a:	40a50513          	add	a0,a0,1034 # 8001fe60 <icache>
    80003a5e:	ffffd097          	auipc	ra,0xffffd
    80003a62:	19e080e7          	jalr	414(ra) # 80000bfc <acquire>
    80003a66:	b741                	j	800039e6 <iput+0x26>

0000000080003a68 <iunlockput>:
{
    80003a68:	1101                	add	sp,sp,-32
    80003a6a:	ec06                	sd	ra,24(sp)
    80003a6c:	e822                	sd	s0,16(sp)
    80003a6e:	e426                	sd	s1,8(sp)
    80003a70:	1000                	add	s0,sp,32
    80003a72:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a74:	00000097          	auipc	ra,0x0
    80003a78:	e54080e7          	jalr	-428(ra) # 800038c8 <iunlock>
  iput(ip);
    80003a7c:	8526                	mv	a0,s1
    80003a7e:	00000097          	auipc	ra,0x0
    80003a82:	f42080e7          	jalr	-190(ra) # 800039c0 <iput>
}
    80003a86:	60e2                	ld	ra,24(sp)
    80003a88:	6442                	ld	s0,16(sp)
    80003a8a:	64a2                	ld	s1,8(sp)
    80003a8c:	6105                	add	sp,sp,32
    80003a8e:	8082                	ret

0000000080003a90 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a90:	1141                	add	sp,sp,-16
    80003a92:	e422                	sd	s0,8(sp)
    80003a94:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    80003a96:	411c                	lw	a5,0(a0)
    80003a98:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a9a:	415c                	lw	a5,4(a0)
    80003a9c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a9e:	04451783          	lh	a5,68(a0)
    80003aa2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003aa6:	04a51783          	lh	a5,74(a0)
    80003aaa:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003aae:	04c56783          	lwu	a5,76(a0)
    80003ab2:	e99c                	sd	a5,16(a1)
}
    80003ab4:	6422                	ld	s0,8(sp)
    80003ab6:	0141                	add	sp,sp,16
    80003ab8:	8082                	ret

0000000080003aba <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003aba:	457c                	lw	a5,76(a0)
    80003abc:	0ed7e963          	bltu	a5,a3,80003bae <readi+0xf4>
{
    80003ac0:	7159                	add	sp,sp,-112
    80003ac2:	f486                	sd	ra,104(sp)
    80003ac4:	f0a2                	sd	s0,96(sp)
    80003ac6:	eca6                	sd	s1,88(sp)
    80003ac8:	e8ca                	sd	s2,80(sp)
    80003aca:	e4ce                	sd	s3,72(sp)
    80003acc:	e0d2                	sd	s4,64(sp)
    80003ace:	fc56                	sd	s5,56(sp)
    80003ad0:	f85a                	sd	s6,48(sp)
    80003ad2:	f45e                	sd	s7,40(sp)
    80003ad4:	f062                	sd	s8,32(sp)
    80003ad6:	ec66                	sd	s9,24(sp)
    80003ad8:	e86a                	sd	s10,16(sp)
    80003ada:	e46e                	sd	s11,8(sp)
    80003adc:	1880                	add	s0,sp,112
    80003ade:	8baa                	mv	s7,a0
    80003ae0:	8c2e                	mv	s8,a1
    80003ae2:	8ab2                	mv	s5,a2
    80003ae4:	84b6                	mv	s1,a3
    80003ae6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ae8:	9f35                	addw	a4,a4,a3
    return 0;
    80003aea:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003aec:	0ad76063          	bltu	a4,a3,80003b8c <readi+0xd2>
  if(off + n > ip->size)
    80003af0:	00e7f463          	bgeu	a5,a4,80003af8 <readi+0x3e>
    n = ip->size - off;
    80003af4:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003af8:	0a0b0963          	beqz	s6,80003baa <readi+0xf0>
    80003afc:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003afe:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b02:	5cfd                	li	s9,-1
    80003b04:	a82d                	j	80003b3e <readi+0x84>
    80003b06:	020a1d93          	sll	s11,s4,0x20
    80003b0a:	020ddd93          	srl	s11,s11,0x20
    80003b0e:	05890613          	add	a2,s2,88
    80003b12:	86ee                	mv	a3,s11
    80003b14:	963a                	add	a2,a2,a4
    80003b16:	85d6                	mv	a1,s5
    80003b18:	8562                	mv	a0,s8
    80003b1a:	fffff097          	auipc	ra,0xfffff
    80003b1e:	a4e080e7          	jalr	-1458(ra) # 80002568 <either_copyout>
    80003b22:	05950d63          	beq	a0,s9,80003b7c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b26:	854a                	mv	a0,s2
    80003b28:	fffff097          	auipc	ra,0xfffff
    80003b2c:	614080e7          	jalr	1556(ra) # 8000313c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b30:	013a09bb          	addw	s3,s4,s3
    80003b34:	009a04bb          	addw	s1,s4,s1
    80003b38:	9aee                	add	s5,s5,s11
    80003b3a:	0569f763          	bgeu	s3,s6,80003b88 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b3e:	000ba903          	lw	s2,0(s7)
    80003b42:	00a4d59b          	srlw	a1,s1,0xa
    80003b46:	855e                	mv	a0,s7
    80003b48:	00000097          	auipc	ra,0x0
    80003b4c:	8b2080e7          	jalr	-1870(ra) # 800033fa <bmap>
    80003b50:	0005059b          	sext.w	a1,a0
    80003b54:	854a                	mv	a0,s2
    80003b56:	fffff097          	auipc	ra,0xfffff
    80003b5a:	4b6080e7          	jalr	1206(ra) # 8000300c <bread>
    80003b5e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b60:	3ff4f713          	and	a4,s1,1023
    80003b64:	40ed07bb          	subw	a5,s10,a4
    80003b68:	413b06bb          	subw	a3,s6,s3
    80003b6c:	8a3e                	mv	s4,a5
    80003b6e:	2781                	sext.w	a5,a5
    80003b70:	0006861b          	sext.w	a2,a3
    80003b74:	f8f679e3          	bgeu	a2,a5,80003b06 <readi+0x4c>
    80003b78:	8a36                	mv	s4,a3
    80003b7a:	b771                	j	80003b06 <readi+0x4c>
      brelse(bp);
    80003b7c:	854a                	mv	a0,s2
    80003b7e:	fffff097          	auipc	ra,0xfffff
    80003b82:	5be080e7          	jalr	1470(ra) # 8000313c <brelse>
      tot = -1;
    80003b86:	59fd                	li	s3,-1
  }
  return tot;
    80003b88:	0009851b          	sext.w	a0,s3
}
    80003b8c:	70a6                	ld	ra,104(sp)
    80003b8e:	7406                	ld	s0,96(sp)
    80003b90:	64e6                	ld	s1,88(sp)
    80003b92:	6946                	ld	s2,80(sp)
    80003b94:	69a6                	ld	s3,72(sp)
    80003b96:	6a06                	ld	s4,64(sp)
    80003b98:	7ae2                	ld	s5,56(sp)
    80003b9a:	7b42                	ld	s6,48(sp)
    80003b9c:	7ba2                	ld	s7,40(sp)
    80003b9e:	7c02                	ld	s8,32(sp)
    80003ba0:	6ce2                	ld	s9,24(sp)
    80003ba2:	6d42                	ld	s10,16(sp)
    80003ba4:	6da2                	ld	s11,8(sp)
    80003ba6:	6165                	add	sp,sp,112
    80003ba8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003baa:	89da                	mv	s3,s6
    80003bac:	bff1                	j	80003b88 <readi+0xce>
    return 0;
    80003bae:	4501                	li	a0,0
}
    80003bb0:	8082                	ret

0000000080003bb2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bb2:	457c                	lw	a5,76(a0)
    80003bb4:	10d7e763          	bltu	a5,a3,80003cc2 <writei+0x110>
{
    80003bb8:	7159                	add	sp,sp,-112
    80003bba:	f486                	sd	ra,104(sp)
    80003bbc:	f0a2                	sd	s0,96(sp)
    80003bbe:	eca6                	sd	s1,88(sp)
    80003bc0:	e8ca                	sd	s2,80(sp)
    80003bc2:	e4ce                	sd	s3,72(sp)
    80003bc4:	e0d2                	sd	s4,64(sp)
    80003bc6:	fc56                	sd	s5,56(sp)
    80003bc8:	f85a                	sd	s6,48(sp)
    80003bca:	f45e                	sd	s7,40(sp)
    80003bcc:	f062                	sd	s8,32(sp)
    80003bce:	ec66                	sd	s9,24(sp)
    80003bd0:	e86a                	sd	s10,16(sp)
    80003bd2:	e46e                	sd	s11,8(sp)
    80003bd4:	1880                	add	s0,sp,112
    80003bd6:	8baa                	mv	s7,a0
    80003bd8:	8c2e                	mv	s8,a1
    80003bda:	8ab2                	mv	s5,a2
    80003bdc:	8936                	mv	s2,a3
    80003bde:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003be0:	00e687bb          	addw	a5,a3,a4
    80003be4:	0ed7e163          	bltu	a5,a3,80003cc6 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003be8:	00043737          	lui	a4,0x43
    80003bec:	0cf76f63          	bltu	a4,a5,80003cca <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bf0:	0a0b0863          	beqz	s6,80003ca0 <writei+0xee>
    80003bf4:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bf6:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bfa:	5cfd                	li	s9,-1
    80003bfc:	a091                	j	80003c40 <writei+0x8e>
    80003bfe:	02099d93          	sll	s11,s3,0x20
    80003c02:	020ddd93          	srl	s11,s11,0x20
    80003c06:	05848513          	add	a0,s1,88
    80003c0a:	86ee                	mv	a3,s11
    80003c0c:	8656                	mv	a2,s5
    80003c0e:	85e2                	mv	a1,s8
    80003c10:	953a                	add	a0,a0,a4
    80003c12:	fffff097          	auipc	ra,0xfffff
    80003c16:	9ac080e7          	jalr	-1620(ra) # 800025be <either_copyin>
    80003c1a:	07950263          	beq	a0,s9,80003c7e <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003c1e:	8526                	mv	a0,s1
    80003c20:	00000097          	auipc	ra,0x0
    80003c24:	75a080e7          	jalr	1882(ra) # 8000437a <log_write>
    brelse(bp);
    80003c28:	8526                	mv	a0,s1
    80003c2a:	fffff097          	auipc	ra,0xfffff
    80003c2e:	512080e7          	jalr	1298(ra) # 8000313c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c32:	01498a3b          	addw	s4,s3,s4
    80003c36:	0129893b          	addw	s2,s3,s2
    80003c3a:	9aee                	add	s5,s5,s11
    80003c3c:	056a7763          	bgeu	s4,s6,80003c8a <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c40:	000ba483          	lw	s1,0(s7)
    80003c44:	00a9559b          	srlw	a1,s2,0xa
    80003c48:	855e                	mv	a0,s7
    80003c4a:	fffff097          	auipc	ra,0xfffff
    80003c4e:	7b0080e7          	jalr	1968(ra) # 800033fa <bmap>
    80003c52:	0005059b          	sext.w	a1,a0
    80003c56:	8526                	mv	a0,s1
    80003c58:	fffff097          	auipc	ra,0xfffff
    80003c5c:	3b4080e7          	jalr	948(ra) # 8000300c <bread>
    80003c60:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c62:	3ff97713          	and	a4,s2,1023
    80003c66:	40ed07bb          	subw	a5,s10,a4
    80003c6a:	414b06bb          	subw	a3,s6,s4
    80003c6e:	89be                	mv	s3,a5
    80003c70:	2781                	sext.w	a5,a5
    80003c72:	0006861b          	sext.w	a2,a3
    80003c76:	f8f674e3          	bgeu	a2,a5,80003bfe <writei+0x4c>
    80003c7a:	89b6                	mv	s3,a3
    80003c7c:	b749                	j	80003bfe <writei+0x4c>
      brelse(bp);
    80003c7e:	8526                	mv	a0,s1
    80003c80:	fffff097          	auipc	ra,0xfffff
    80003c84:	4bc080e7          	jalr	1212(ra) # 8000313c <brelse>
      n = -1;
    80003c88:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003c8a:	04cba783          	lw	a5,76(s7)
    80003c8e:	0127f463          	bgeu	a5,s2,80003c96 <writei+0xe4>
      ip->size = off;
    80003c92:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003c96:	855e                	mv	a0,s7
    80003c98:	00000097          	auipc	ra,0x0
    80003c9c:	aa2080e7          	jalr	-1374(ra) # 8000373a <iupdate>
  }

  return n;
    80003ca0:	000b051b          	sext.w	a0,s6
}
    80003ca4:	70a6                	ld	ra,104(sp)
    80003ca6:	7406                	ld	s0,96(sp)
    80003ca8:	64e6                	ld	s1,88(sp)
    80003caa:	6946                	ld	s2,80(sp)
    80003cac:	69a6                	ld	s3,72(sp)
    80003cae:	6a06                	ld	s4,64(sp)
    80003cb0:	7ae2                	ld	s5,56(sp)
    80003cb2:	7b42                	ld	s6,48(sp)
    80003cb4:	7ba2                	ld	s7,40(sp)
    80003cb6:	7c02                	ld	s8,32(sp)
    80003cb8:	6ce2                	ld	s9,24(sp)
    80003cba:	6d42                	ld	s10,16(sp)
    80003cbc:	6da2                	ld	s11,8(sp)
    80003cbe:	6165                	add	sp,sp,112
    80003cc0:	8082                	ret
    return -1;
    80003cc2:	557d                	li	a0,-1
}
    80003cc4:	8082                	ret
    return -1;
    80003cc6:	557d                	li	a0,-1
    80003cc8:	bff1                	j	80003ca4 <writei+0xf2>
    return -1;
    80003cca:	557d                	li	a0,-1
    80003ccc:	bfe1                	j	80003ca4 <writei+0xf2>

0000000080003cce <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003cce:	1141                	add	sp,sp,-16
    80003cd0:	e406                	sd	ra,8(sp)
    80003cd2:	e022                	sd	s0,0(sp)
    80003cd4:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003cd6:	4639                	li	a2,14
    80003cd8:	ffffd097          	auipc	ra,0xffffd
    80003cdc:	0f8080e7          	jalr	248(ra) # 80000dd0 <strncmp>
}
    80003ce0:	60a2                	ld	ra,8(sp)
    80003ce2:	6402                	ld	s0,0(sp)
    80003ce4:	0141                	add	sp,sp,16
    80003ce6:	8082                	ret

0000000080003ce8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ce8:	7139                	add	sp,sp,-64
    80003cea:	fc06                	sd	ra,56(sp)
    80003cec:	f822                	sd	s0,48(sp)
    80003cee:	f426                	sd	s1,40(sp)
    80003cf0:	f04a                	sd	s2,32(sp)
    80003cf2:	ec4e                	sd	s3,24(sp)
    80003cf4:	e852                	sd	s4,16(sp)
    80003cf6:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cf8:	04451703          	lh	a4,68(a0)
    80003cfc:	4785                	li	a5,1
    80003cfe:	00f71a63          	bne	a4,a5,80003d12 <dirlookup+0x2a>
    80003d02:	892a                	mv	s2,a0
    80003d04:	89ae                	mv	s3,a1
    80003d06:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d08:	457c                	lw	a5,76(a0)
    80003d0a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d0c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d0e:	e79d                	bnez	a5,80003d3c <dirlookup+0x54>
    80003d10:	a8a5                	j	80003d88 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d12:	00005517          	auipc	a0,0x5
    80003d16:	92650513          	add	a0,a0,-1754 # 80008638 <syscalls+0x1a0>
    80003d1a:	ffffd097          	auipc	ra,0xffffd
    80003d1e:	828080e7          	jalr	-2008(ra) # 80000542 <panic>
      panic("dirlookup read");
    80003d22:	00005517          	auipc	a0,0x5
    80003d26:	92e50513          	add	a0,a0,-1746 # 80008650 <syscalls+0x1b8>
    80003d2a:	ffffd097          	auipc	ra,0xffffd
    80003d2e:	818080e7          	jalr	-2024(ra) # 80000542 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d32:	24c1                	addw	s1,s1,16
    80003d34:	04c92783          	lw	a5,76(s2)
    80003d38:	04f4f763          	bgeu	s1,a5,80003d86 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d3c:	4741                	li	a4,16
    80003d3e:	86a6                	mv	a3,s1
    80003d40:	fc040613          	add	a2,s0,-64
    80003d44:	4581                	li	a1,0
    80003d46:	854a                	mv	a0,s2
    80003d48:	00000097          	auipc	ra,0x0
    80003d4c:	d72080e7          	jalr	-654(ra) # 80003aba <readi>
    80003d50:	47c1                	li	a5,16
    80003d52:	fcf518e3          	bne	a0,a5,80003d22 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d56:	fc045783          	lhu	a5,-64(s0)
    80003d5a:	dfe1                	beqz	a5,80003d32 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d5c:	fc240593          	add	a1,s0,-62
    80003d60:	854e                	mv	a0,s3
    80003d62:	00000097          	auipc	ra,0x0
    80003d66:	f6c080e7          	jalr	-148(ra) # 80003cce <namecmp>
    80003d6a:	f561                	bnez	a0,80003d32 <dirlookup+0x4a>
      if(poff)
    80003d6c:	000a0463          	beqz	s4,80003d74 <dirlookup+0x8c>
        *poff = off;
    80003d70:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d74:	fc045583          	lhu	a1,-64(s0)
    80003d78:	00092503          	lw	a0,0(s2)
    80003d7c:	fffff097          	auipc	ra,0xfffff
    80003d80:	75a080e7          	jalr	1882(ra) # 800034d6 <iget>
    80003d84:	a011                	j	80003d88 <dirlookup+0xa0>
  return 0;
    80003d86:	4501                	li	a0,0
}
    80003d88:	70e2                	ld	ra,56(sp)
    80003d8a:	7442                	ld	s0,48(sp)
    80003d8c:	74a2                	ld	s1,40(sp)
    80003d8e:	7902                	ld	s2,32(sp)
    80003d90:	69e2                	ld	s3,24(sp)
    80003d92:	6a42                	ld	s4,16(sp)
    80003d94:	6121                	add	sp,sp,64
    80003d96:	8082                	ret

0000000080003d98 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d98:	711d                	add	sp,sp,-96
    80003d9a:	ec86                	sd	ra,88(sp)
    80003d9c:	e8a2                	sd	s0,80(sp)
    80003d9e:	e4a6                	sd	s1,72(sp)
    80003da0:	e0ca                	sd	s2,64(sp)
    80003da2:	fc4e                	sd	s3,56(sp)
    80003da4:	f852                	sd	s4,48(sp)
    80003da6:	f456                	sd	s5,40(sp)
    80003da8:	f05a                	sd	s6,32(sp)
    80003daa:	ec5e                	sd	s7,24(sp)
    80003dac:	e862                	sd	s8,16(sp)
    80003dae:	e466                	sd	s9,8(sp)
    80003db0:	1080                	add	s0,sp,96
    80003db2:	84aa                	mv	s1,a0
    80003db4:	8b2e                	mv	s6,a1
    80003db6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003db8:	00054703          	lbu	a4,0(a0)
    80003dbc:	02f00793          	li	a5,47
    80003dc0:	02f70263          	beq	a4,a5,80003de4 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003dc4:	ffffe097          	auipc	ra,0xffffe
    80003dc8:	d34080e7          	jalr	-716(ra) # 80001af8 <myproc>
    80003dcc:	15053503          	ld	a0,336(a0)
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	9f8080e7          	jalr	-1544(ra) # 800037c8 <idup>
    80003dd8:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003dda:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003dde:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003de0:	4b85                	li	s7,1
    80003de2:	a875                	j	80003e9e <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003de4:	4585                	li	a1,1
    80003de6:	4505                	li	a0,1
    80003de8:	fffff097          	auipc	ra,0xfffff
    80003dec:	6ee080e7          	jalr	1774(ra) # 800034d6 <iget>
    80003df0:	8a2a                	mv	s4,a0
    80003df2:	b7e5                	j	80003dda <namex+0x42>
      iunlockput(ip);
    80003df4:	8552                	mv	a0,s4
    80003df6:	00000097          	auipc	ra,0x0
    80003dfa:	c72080e7          	jalr	-910(ra) # 80003a68 <iunlockput>
      return 0;
    80003dfe:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e00:	8552                	mv	a0,s4
    80003e02:	60e6                	ld	ra,88(sp)
    80003e04:	6446                	ld	s0,80(sp)
    80003e06:	64a6                	ld	s1,72(sp)
    80003e08:	6906                	ld	s2,64(sp)
    80003e0a:	79e2                	ld	s3,56(sp)
    80003e0c:	7a42                	ld	s4,48(sp)
    80003e0e:	7aa2                	ld	s5,40(sp)
    80003e10:	7b02                	ld	s6,32(sp)
    80003e12:	6be2                	ld	s7,24(sp)
    80003e14:	6c42                	ld	s8,16(sp)
    80003e16:	6ca2                	ld	s9,8(sp)
    80003e18:	6125                	add	sp,sp,96
    80003e1a:	8082                	ret
      iunlock(ip);
    80003e1c:	8552                	mv	a0,s4
    80003e1e:	00000097          	auipc	ra,0x0
    80003e22:	aaa080e7          	jalr	-1366(ra) # 800038c8 <iunlock>
      return ip;
    80003e26:	bfe9                	j	80003e00 <namex+0x68>
      iunlockput(ip);
    80003e28:	8552                	mv	a0,s4
    80003e2a:	00000097          	auipc	ra,0x0
    80003e2e:	c3e080e7          	jalr	-962(ra) # 80003a68 <iunlockput>
      return 0;
    80003e32:	8a4e                	mv	s4,s3
    80003e34:	b7f1                	j	80003e00 <namex+0x68>
  len = path - s;
    80003e36:	40998633          	sub	a2,s3,s1
    80003e3a:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003e3e:	099c5863          	bge	s8,s9,80003ece <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003e42:	4639                	li	a2,14
    80003e44:	85a6                	mv	a1,s1
    80003e46:	8556                	mv	a0,s5
    80003e48:	ffffd097          	auipc	ra,0xffffd
    80003e4c:	f0c080e7          	jalr	-244(ra) # 80000d54 <memmove>
    80003e50:	84ce                	mv	s1,s3
  while(*path == '/')
    80003e52:	0004c783          	lbu	a5,0(s1)
    80003e56:	01279763          	bne	a5,s2,80003e64 <namex+0xcc>
    path++;
    80003e5a:	0485                	add	s1,s1,1
  while(*path == '/')
    80003e5c:	0004c783          	lbu	a5,0(s1)
    80003e60:	ff278de3          	beq	a5,s2,80003e5a <namex+0xc2>
    ilock(ip);
    80003e64:	8552                	mv	a0,s4
    80003e66:	00000097          	auipc	ra,0x0
    80003e6a:	9a0080e7          	jalr	-1632(ra) # 80003806 <ilock>
    if(ip->type != T_DIR){
    80003e6e:	044a1783          	lh	a5,68(s4)
    80003e72:	f97791e3          	bne	a5,s7,80003df4 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80003e76:	000b0563          	beqz	s6,80003e80 <namex+0xe8>
    80003e7a:	0004c783          	lbu	a5,0(s1)
    80003e7e:	dfd9                	beqz	a5,80003e1c <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e80:	4601                	li	a2,0
    80003e82:	85d6                	mv	a1,s5
    80003e84:	8552                	mv	a0,s4
    80003e86:	00000097          	auipc	ra,0x0
    80003e8a:	e62080e7          	jalr	-414(ra) # 80003ce8 <dirlookup>
    80003e8e:	89aa                	mv	s3,a0
    80003e90:	dd41                	beqz	a0,80003e28 <namex+0x90>
    iunlockput(ip);
    80003e92:	8552                	mv	a0,s4
    80003e94:	00000097          	auipc	ra,0x0
    80003e98:	bd4080e7          	jalr	-1068(ra) # 80003a68 <iunlockput>
    ip = next;
    80003e9c:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003e9e:	0004c783          	lbu	a5,0(s1)
    80003ea2:	01279763          	bne	a5,s2,80003eb0 <namex+0x118>
    path++;
    80003ea6:	0485                	add	s1,s1,1
  while(*path == '/')
    80003ea8:	0004c783          	lbu	a5,0(s1)
    80003eac:	ff278de3          	beq	a5,s2,80003ea6 <namex+0x10e>
  if(*path == 0)
    80003eb0:	cb9d                	beqz	a5,80003ee6 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80003eb2:	0004c783          	lbu	a5,0(s1)
    80003eb6:	89a6                	mv	s3,s1
  len = path - s;
    80003eb8:	4c81                	li	s9,0
    80003eba:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003ebc:	01278963          	beq	a5,s2,80003ece <namex+0x136>
    80003ec0:	dbbd                	beqz	a5,80003e36 <namex+0x9e>
    path++;
    80003ec2:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    80003ec4:	0009c783          	lbu	a5,0(s3)
    80003ec8:	ff279ce3          	bne	a5,s2,80003ec0 <namex+0x128>
    80003ecc:	b7ad                	j	80003e36 <namex+0x9e>
    memmove(name, s, len);
    80003ece:	2601                	sext.w	a2,a2
    80003ed0:	85a6                	mv	a1,s1
    80003ed2:	8556                	mv	a0,s5
    80003ed4:	ffffd097          	auipc	ra,0xffffd
    80003ed8:	e80080e7          	jalr	-384(ra) # 80000d54 <memmove>
    name[len] = 0;
    80003edc:	9cd6                	add	s9,s9,s5
    80003ede:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003ee2:	84ce                	mv	s1,s3
    80003ee4:	b7bd                	j	80003e52 <namex+0xba>
  if(nameiparent){
    80003ee6:	f00b0de3          	beqz	s6,80003e00 <namex+0x68>
    iput(ip);
    80003eea:	8552                	mv	a0,s4
    80003eec:	00000097          	auipc	ra,0x0
    80003ef0:	ad4080e7          	jalr	-1324(ra) # 800039c0 <iput>
    return 0;
    80003ef4:	4a01                	li	s4,0
    80003ef6:	b729                	j	80003e00 <namex+0x68>

0000000080003ef8 <dirlink>:
{
    80003ef8:	7139                	add	sp,sp,-64
    80003efa:	fc06                	sd	ra,56(sp)
    80003efc:	f822                	sd	s0,48(sp)
    80003efe:	f426                	sd	s1,40(sp)
    80003f00:	f04a                	sd	s2,32(sp)
    80003f02:	ec4e                	sd	s3,24(sp)
    80003f04:	e852                	sd	s4,16(sp)
    80003f06:	0080                	add	s0,sp,64
    80003f08:	892a                	mv	s2,a0
    80003f0a:	8a2e                	mv	s4,a1
    80003f0c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f0e:	4601                	li	a2,0
    80003f10:	00000097          	auipc	ra,0x0
    80003f14:	dd8080e7          	jalr	-552(ra) # 80003ce8 <dirlookup>
    80003f18:	e93d                	bnez	a0,80003f8e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f1a:	04c92483          	lw	s1,76(s2)
    80003f1e:	c49d                	beqz	s1,80003f4c <dirlink+0x54>
    80003f20:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f22:	4741                	li	a4,16
    80003f24:	86a6                	mv	a3,s1
    80003f26:	fc040613          	add	a2,s0,-64
    80003f2a:	4581                	li	a1,0
    80003f2c:	854a                	mv	a0,s2
    80003f2e:	00000097          	auipc	ra,0x0
    80003f32:	b8c080e7          	jalr	-1140(ra) # 80003aba <readi>
    80003f36:	47c1                	li	a5,16
    80003f38:	06f51163          	bne	a0,a5,80003f9a <dirlink+0xa2>
    if(de.inum == 0)
    80003f3c:	fc045783          	lhu	a5,-64(s0)
    80003f40:	c791                	beqz	a5,80003f4c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f42:	24c1                	addw	s1,s1,16
    80003f44:	04c92783          	lw	a5,76(s2)
    80003f48:	fcf4ede3          	bltu	s1,a5,80003f22 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f4c:	4639                	li	a2,14
    80003f4e:	85d2                	mv	a1,s4
    80003f50:	fc240513          	add	a0,s0,-62
    80003f54:	ffffd097          	auipc	ra,0xffffd
    80003f58:	eb8080e7          	jalr	-328(ra) # 80000e0c <strncpy>
  de.inum = inum;
    80003f5c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f60:	4741                	li	a4,16
    80003f62:	86a6                	mv	a3,s1
    80003f64:	fc040613          	add	a2,s0,-64
    80003f68:	4581                	li	a1,0
    80003f6a:	854a                	mv	a0,s2
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	c46080e7          	jalr	-954(ra) # 80003bb2 <writei>
    80003f74:	872a                	mv	a4,a0
    80003f76:	47c1                	li	a5,16
  return 0;
    80003f78:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f7a:	02f71863          	bne	a4,a5,80003faa <dirlink+0xb2>
}
    80003f7e:	70e2                	ld	ra,56(sp)
    80003f80:	7442                	ld	s0,48(sp)
    80003f82:	74a2                	ld	s1,40(sp)
    80003f84:	7902                	ld	s2,32(sp)
    80003f86:	69e2                	ld	s3,24(sp)
    80003f88:	6a42                	ld	s4,16(sp)
    80003f8a:	6121                	add	sp,sp,64
    80003f8c:	8082                	ret
    iput(ip);
    80003f8e:	00000097          	auipc	ra,0x0
    80003f92:	a32080e7          	jalr	-1486(ra) # 800039c0 <iput>
    return -1;
    80003f96:	557d                	li	a0,-1
    80003f98:	b7dd                	j	80003f7e <dirlink+0x86>
      panic("dirlink read");
    80003f9a:	00004517          	auipc	a0,0x4
    80003f9e:	6c650513          	add	a0,a0,1734 # 80008660 <syscalls+0x1c8>
    80003fa2:	ffffc097          	auipc	ra,0xffffc
    80003fa6:	5a0080e7          	jalr	1440(ra) # 80000542 <panic>
    panic("dirlink");
    80003faa:	00004517          	auipc	a0,0x4
    80003fae:	7ce50513          	add	a0,a0,1998 # 80008778 <syscalls+0x2e0>
    80003fb2:	ffffc097          	auipc	ra,0xffffc
    80003fb6:	590080e7          	jalr	1424(ra) # 80000542 <panic>

0000000080003fba <namei>:

struct inode*
namei(char *path)
{
    80003fba:	1101                	add	sp,sp,-32
    80003fbc:	ec06                	sd	ra,24(sp)
    80003fbe:	e822                	sd	s0,16(sp)
    80003fc0:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fc2:	fe040613          	add	a2,s0,-32
    80003fc6:	4581                	li	a1,0
    80003fc8:	00000097          	auipc	ra,0x0
    80003fcc:	dd0080e7          	jalr	-560(ra) # 80003d98 <namex>
}
    80003fd0:	60e2                	ld	ra,24(sp)
    80003fd2:	6442                	ld	s0,16(sp)
    80003fd4:	6105                	add	sp,sp,32
    80003fd6:	8082                	ret

0000000080003fd8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fd8:	1141                	add	sp,sp,-16
    80003fda:	e406                	sd	ra,8(sp)
    80003fdc:	e022                	sd	s0,0(sp)
    80003fde:	0800                	add	s0,sp,16
    80003fe0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003fe2:	4585                	li	a1,1
    80003fe4:	00000097          	auipc	ra,0x0
    80003fe8:	db4080e7          	jalr	-588(ra) # 80003d98 <namex>
}
    80003fec:	60a2                	ld	ra,8(sp)
    80003fee:	6402                	ld	s0,0(sp)
    80003ff0:	0141                	add	sp,sp,16
    80003ff2:	8082                	ret

0000000080003ff4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003ff4:	1101                	add	sp,sp,-32
    80003ff6:	ec06                	sd	ra,24(sp)
    80003ff8:	e822                	sd	s0,16(sp)
    80003ffa:	e426                	sd	s1,8(sp)
    80003ffc:	e04a                	sd	s2,0(sp)
    80003ffe:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004000:	0001e917          	auipc	s2,0x1e
    80004004:	90890913          	add	s2,s2,-1784 # 80021908 <log>
    80004008:	01892583          	lw	a1,24(s2)
    8000400c:	02892503          	lw	a0,40(s2)
    80004010:	fffff097          	auipc	ra,0xfffff
    80004014:	ffc080e7          	jalr	-4(ra) # 8000300c <bread>
    80004018:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000401a:	02c92603          	lw	a2,44(s2)
    8000401e:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004020:	00c05f63          	blez	a2,8000403e <write_head+0x4a>
    80004024:	0001e717          	auipc	a4,0x1e
    80004028:	91470713          	add	a4,a4,-1772 # 80021938 <log+0x30>
    8000402c:	87aa                	mv	a5,a0
    8000402e:	060a                	sll	a2,a2,0x2
    80004030:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80004032:	4314                	lw	a3,0(a4)
    80004034:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004036:	0711                	add	a4,a4,4
    80004038:	0791                	add	a5,a5,4
    8000403a:	fec79ce3          	bne	a5,a2,80004032 <write_head+0x3e>
  }
  bwrite(buf);
    8000403e:	8526                	mv	a0,s1
    80004040:	fffff097          	auipc	ra,0xfffff
    80004044:	0be080e7          	jalr	190(ra) # 800030fe <bwrite>
  brelse(buf);
    80004048:	8526                	mv	a0,s1
    8000404a:	fffff097          	auipc	ra,0xfffff
    8000404e:	0f2080e7          	jalr	242(ra) # 8000313c <brelse>
}
    80004052:	60e2                	ld	ra,24(sp)
    80004054:	6442                	ld	s0,16(sp)
    80004056:	64a2                	ld	s1,8(sp)
    80004058:	6902                	ld	s2,0(sp)
    8000405a:	6105                	add	sp,sp,32
    8000405c:	8082                	ret

000000008000405e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000405e:	0001e797          	auipc	a5,0x1e
    80004062:	8d67a783          	lw	a5,-1834(a5) # 80021934 <log+0x2c>
    80004066:	0af05663          	blez	a5,80004112 <install_trans+0xb4>
{
    8000406a:	7139                	add	sp,sp,-64
    8000406c:	fc06                	sd	ra,56(sp)
    8000406e:	f822                	sd	s0,48(sp)
    80004070:	f426                	sd	s1,40(sp)
    80004072:	f04a                	sd	s2,32(sp)
    80004074:	ec4e                	sd	s3,24(sp)
    80004076:	e852                	sd	s4,16(sp)
    80004078:	e456                	sd	s5,8(sp)
    8000407a:	0080                	add	s0,sp,64
    8000407c:	0001ea97          	auipc	s5,0x1e
    80004080:	8bca8a93          	add	s5,s5,-1860 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004084:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004086:	0001e997          	auipc	s3,0x1e
    8000408a:	88298993          	add	s3,s3,-1918 # 80021908 <log>
    8000408e:	0189a583          	lw	a1,24(s3)
    80004092:	014585bb          	addw	a1,a1,s4
    80004096:	2585                	addw	a1,a1,1
    80004098:	0289a503          	lw	a0,40(s3)
    8000409c:	fffff097          	auipc	ra,0xfffff
    800040a0:	f70080e7          	jalr	-144(ra) # 8000300c <bread>
    800040a4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040a6:	000aa583          	lw	a1,0(s5)
    800040aa:	0289a503          	lw	a0,40(s3)
    800040ae:	fffff097          	auipc	ra,0xfffff
    800040b2:	f5e080e7          	jalr	-162(ra) # 8000300c <bread>
    800040b6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040b8:	40000613          	li	a2,1024
    800040bc:	05890593          	add	a1,s2,88
    800040c0:	05850513          	add	a0,a0,88
    800040c4:	ffffd097          	auipc	ra,0xffffd
    800040c8:	c90080e7          	jalr	-880(ra) # 80000d54 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040cc:	8526                	mv	a0,s1
    800040ce:	fffff097          	auipc	ra,0xfffff
    800040d2:	030080e7          	jalr	48(ra) # 800030fe <bwrite>
    bunpin(dbuf);
    800040d6:	8526                	mv	a0,s1
    800040d8:	fffff097          	auipc	ra,0xfffff
    800040dc:	13c080e7          	jalr	316(ra) # 80003214 <bunpin>
    brelse(lbuf);
    800040e0:	854a                	mv	a0,s2
    800040e2:	fffff097          	auipc	ra,0xfffff
    800040e6:	05a080e7          	jalr	90(ra) # 8000313c <brelse>
    brelse(dbuf);
    800040ea:	8526                	mv	a0,s1
    800040ec:	fffff097          	auipc	ra,0xfffff
    800040f0:	050080e7          	jalr	80(ra) # 8000313c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040f4:	2a05                	addw	s4,s4,1
    800040f6:	0a91                	add	s5,s5,4
    800040f8:	02c9a783          	lw	a5,44(s3)
    800040fc:	f8fa49e3          	blt	s4,a5,8000408e <install_trans+0x30>
}
    80004100:	70e2                	ld	ra,56(sp)
    80004102:	7442                	ld	s0,48(sp)
    80004104:	74a2                	ld	s1,40(sp)
    80004106:	7902                	ld	s2,32(sp)
    80004108:	69e2                	ld	s3,24(sp)
    8000410a:	6a42                	ld	s4,16(sp)
    8000410c:	6aa2                	ld	s5,8(sp)
    8000410e:	6121                	add	sp,sp,64
    80004110:	8082                	ret
    80004112:	8082                	ret

0000000080004114 <initlog>:
{
    80004114:	7179                	add	sp,sp,-48
    80004116:	f406                	sd	ra,40(sp)
    80004118:	f022                	sd	s0,32(sp)
    8000411a:	ec26                	sd	s1,24(sp)
    8000411c:	e84a                	sd	s2,16(sp)
    8000411e:	e44e                	sd	s3,8(sp)
    80004120:	1800                	add	s0,sp,48
    80004122:	892a                	mv	s2,a0
    80004124:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004126:	0001d497          	auipc	s1,0x1d
    8000412a:	7e248493          	add	s1,s1,2018 # 80021908 <log>
    8000412e:	00004597          	auipc	a1,0x4
    80004132:	54258593          	add	a1,a1,1346 # 80008670 <syscalls+0x1d8>
    80004136:	8526                	mv	a0,s1
    80004138:	ffffd097          	auipc	ra,0xffffd
    8000413c:	a34080e7          	jalr	-1484(ra) # 80000b6c <initlock>
  log.start = sb->logstart;
    80004140:	0149a583          	lw	a1,20(s3)
    80004144:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004146:	0109a783          	lw	a5,16(s3)
    8000414a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000414c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004150:	854a                	mv	a0,s2
    80004152:	fffff097          	auipc	ra,0xfffff
    80004156:	eba080e7          	jalr	-326(ra) # 8000300c <bread>
  log.lh.n = lh->n;
    8000415a:	4d30                	lw	a2,88(a0)
    8000415c:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000415e:	00c05f63          	blez	a2,8000417c <initlog+0x68>
    80004162:	87aa                	mv	a5,a0
    80004164:	0001d717          	auipc	a4,0x1d
    80004168:	7d470713          	add	a4,a4,2004 # 80021938 <log+0x30>
    8000416c:	060a                	sll	a2,a2,0x2
    8000416e:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004170:	4ff4                	lw	a3,92(a5)
    80004172:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004174:	0791                	add	a5,a5,4
    80004176:	0711                	add	a4,a4,4
    80004178:	fec79ce3          	bne	a5,a2,80004170 <initlog+0x5c>
  brelse(buf);
    8000417c:	fffff097          	auipc	ra,0xfffff
    80004180:	fc0080e7          	jalr	-64(ra) # 8000313c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004184:	00000097          	auipc	ra,0x0
    80004188:	eda080e7          	jalr	-294(ra) # 8000405e <install_trans>
  log.lh.n = 0;
    8000418c:	0001d797          	auipc	a5,0x1d
    80004190:	7a07a423          	sw	zero,1960(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    80004194:	00000097          	auipc	ra,0x0
    80004198:	e60080e7          	jalr	-416(ra) # 80003ff4 <write_head>
}
    8000419c:	70a2                	ld	ra,40(sp)
    8000419e:	7402                	ld	s0,32(sp)
    800041a0:	64e2                	ld	s1,24(sp)
    800041a2:	6942                	ld	s2,16(sp)
    800041a4:	69a2                	ld	s3,8(sp)
    800041a6:	6145                	add	sp,sp,48
    800041a8:	8082                	ret

00000000800041aa <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041aa:	1101                	add	sp,sp,-32
    800041ac:	ec06                	sd	ra,24(sp)
    800041ae:	e822                	sd	s0,16(sp)
    800041b0:	e426                	sd	s1,8(sp)
    800041b2:	e04a                	sd	s2,0(sp)
    800041b4:	1000                	add	s0,sp,32
  acquire(&log.lock);
    800041b6:	0001d517          	auipc	a0,0x1d
    800041ba:	75250513          	add	a0,a0,1874 # 80021908 <log>
    800041be:	ffffd097          	auipc	ra,0xffffd
    800041c2:	a3e080e7          	jalr	-1474(ra) # 80000bfc <acquire>
  while(1){
    if(log.committing){
    800041c6:	0001d497          	auipc	s1,0x1d
    800041ca:	74248493          	add	s1,s1,1858 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041ce:	4979                	li	s2,30
    800041d0:	a039                	j	800041de <begin_op+0x34>
      sleep(&log, &log.lock);
    800041d2:	85a6                	mv	a1,s1
    800041d4:	8526                	mv	a0,s1
    800041d6:	ffffe097          	auipc	ra,0xffffe
    800041da:	138080e7          	jalr	312(ra) # 8000230e <sleep>
    if(log.committing){
    800041de:	50dc                	lw	a5,36(s1)
    800041e0:	fbed                	bnez	a5,800041d2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041e2:	5098                	lw	a4,32(s1)
    800041e4:	2705                	addw	a4,a4,1
    800041e6:	0027179b          	sllw	a5,a4,0x2
    800041ea:	9fb9                	addw	a5,a5,a4
    800041ec:	0017979b          	sllw	a5,a5,0x1
    800041f0:	54d4                	lw	a3,44(s1)
    800041f2:	9fb5                	addw	a5,a5,a3
    800041f4:	00f95963          	bge	s2,a5,80004206 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041f8:	85a6                	mv	a1,s1
    800041fa:	8526                	mv	a0,s1
    800041fc:	ffffe097          	auipc	ra,0xffffe
    80004200:	112080e7          	jalr	274(ra) # 8000230e <sleep>
    80004204:	bfe9                	j	800041de <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004206:	0001d517          	auipc	a0,0x1d
    8000420a:	70250513          	add	a0,a0,1794 # 80021908 <log>
    8000420e:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004210:	ffffd097          	auipc	ra,0xffffd
    80004214:	aa0080e7          	jalr	-1376(ra) # 80000cb0 <release>
      break;
    }
  }
}
    80004218:	60e2                	ld	ra,24(sp)
    8000421a:	6442                	ld	s0,16(sp)
    8000421c:	64a2                	ld	s1,8(sp)
    8000421e:	6902                	ld	s2,0(sp)
    80004220:	6105                	add	sp,sp,32
    80004222:	8082                	ret

0000000080004224 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004224:	7139                	add	sp,sp,-64
    80004226:	fc06                	sd	ra,56(sp)
    80004228:	f822                	sd	s0,48(sp)
    8000422a:	f426                	sd	s1,40(sp)
    8000422c:	f04a                	sd	s2,32(sp)
    8000422e:	ec4e                	sd	s3,24(sp)
    80004230:	e852                	sd	s4,16(sp)
    80004232:	e456                	sd	s5,8(sp)
    80004234:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004236:	0001d497          	auipc	s1,0x1d
    8000423a:	6d248493          	add	s1,s1,1746 # 80021908 <log>
    8000423e:	8526                	mv	a0,s1
    80004240:	ffffd097          	auipc	ra,0xffffd
    80004244:	9bc080e7          	jalr	-1604(ra) # 80000bfc <acquire>
  log.outstanding -= 1;
    80004248:	509c                	lw	a5,32(s1)
    8000424a:	37fd                	addw	a5,a5,-1
    8000424c:	0007891b          	sext.w	s2,a5
    80004250:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004252:	50dc                	lw	a5,36(s1)
    80004254:	e7b9                	bnez	a5,800042a2 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004256:	04091e63          	bnez	s2,800042b2 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000425a:	0001d497          	auipc	s1,0x1d
    8000425e:	6ae48493          	add	s1,s1,1710 # 80021908 <log>
    80004262:	4785                	li	a5,1
    80004264:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004266:	8526                	mv	a0,s1
    80004268:	ffffd097          	auipc	ra,0xffffd
    8000426c:	a48080e7          	jalr	-1464(ra) # 80000cb0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004270:	54dc                	lw	a5,44(s1)
    80004272:	06f04763          	bgtz	a5,800042e0 <end_op+0xbc>
    acquire(&log.lock);
    80004276:	0001d497          	auipc	s1,0x1d
    8000427a:	69248493          	add	s1,s1,1682 # 80021908 <log>
    8000427e:	8526                	mv	a0,s1
    80004280:	ffffd097          	auipc	ra,0xffffd
    80004284:	97c080e7          	jalr	-1668(ra) # 80000bfc <acquire>
    log.committing = 0;
    80004288:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000428c:	8526                	mv	a0,s1
    8000428e:	ffffe097          	auipc	ra,0xffffe
    80004292:	200080e7          	jalr	512(ra) # 8000248e <wakeup>
    release(&log.lock);
    80004296:	8526                	mv	a0,s1
    80004298:	ffffd097          	auipc	ra,0xffffd
    8000429c:	a18080e7          	jalr	-1512(ra) # 80000cb0 <release>
}
    800042a0:	a03d                	j	800042ce <end_op+0xaa>
    panic("log.committing");
    800042a2:	00004517          	auipc	a0,0x4
    800042a6:	3d650513          	add	a0,a0,982 # 80008678 <syscalls+0x1e0>
    800042aa:	ffffc097          	auipc	ra,0xffffc
    800042ae:	298080e7          	jalr	664(ra) # 80000542 <panic>
    wakeup(&log);
    800042b2:	0001d497          	auipc	s1,0x1d
    800042b6:	65648493          	add	s1,s1,1622 # 80021908 <log>
    800042ba:	8526                	mv	a0,s1
    800042bc:	ffffe097          	auipc	ra,0xffffe
    800042c0:	1d2080e7          	jalr	466(ra) # 8000248e <wakeup>
  release(&log.lock);
    800042c4:	8526                	mv	a0,s1
    800042c6:	ffffd097          	auipc	ra,0xffffd
    800042ca:	9ea080e7          	jalr	-1558(ra) # 80000cb0 <release>
}
    800042ce:	70e2                	ld	ra,56(sp)
    800042d0:	7442                	ld	s0,48(sp)
    800042d2:	74a2                	ld	s1,40(sp)
    800042d4:	7902                	ld	s2,32(sp)
    800042d6:	69e2                	ld	s3,24(sp)
    800042d8:	6a42                	ld	s4,16(sp)
    800042da:	6aa2                	ld	s5,8(sp)
    800042dc:	6121                	add	sp,sp,64
    800042de:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800042e0:	0001da97          	auipc	s5,0x1d
    800042e4:	658a8a93          	add	s5,s5,1624 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042e8:	0001da17          	auipc	s4,0x1d
    800042ec:	620a0a13          	add	s4,s4,1568 # 80021908 <log>
    800042f0:	018a2583          	lw	a1,24(s4)
    800042f4:	012585bb          	addw	a1,a1,s2
    800042f8:	2585                	addw	a1,a1,1
    800042fa:	028a2503          	lw	a0,40(s4)
    800042fe:	fffff097          	auipc	ra,0xfffff
    80004302:	d0e080e7          	jalr	-754(ra) # 8000300c <bread>
    80004306:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004308:	000aa583          	lw	a1,0(s5)
    8000430c:	028a2503          	lw	a0,40(s4)
    80004310:	fffff097          	auipc	ra,0xfffff
    80004314:	cfc080e7          	jalr	-772(ra) # 8000300c <bread>
    80004318:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000431a:	40000613          	li	a2,1024
    8000431e:	05850593          	add	a1,a0,88
    80004322:	05848513          	add	a0,s1,88
    80004326:	ffffd097          	auipc	ra,0xffffd
    8000432a:	a2e080e7          	jalr	-1490(ra) # 80000d54 <memmove>
    bwrite(to);  // write the log
    8000432e:	8526                	mv	a0,s1
    80004330:	fffff097          	auipc	ra,0xfffff
    80004334:	dce080e7          	jalr	-562(ra) # 800030fe <bwrite>
    brelse(from);
    80004338:	854e                	mv	a0,s3
    8000433a:	fffff097          	auipc	ra,0xfffff
    8000433e:	e02080e7          	jalr	-510(ra) # 8000313c <brelse>
    brelse(to);
    80004342:	8526                	mv	a0,s1
    80004344:	fffff097          	auipc	ra,0xfffff
    80004348:	df8080e7          	jalr	-520(ra) # 8000313c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000434c:	2905                	addw	s2,s2,1
    8000434e:	0a91                	add	s5,s5,4
    80004350:	02ca2783          	lw	a5,44(s4)
    80004354:	f8f94ee3          	blt	s2,a5,800042f0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004358:	00000097          	auipc	ra,0x0
    8000435c:	c9c080e7          	jalr	-868(ra) # 80003ff4 <write_head>
    install_trans(); // Now install writes to home locations
    80004360:	00000097          	auipc	ra,0x0
    80004364:	cfe080e7          	jalr	-770(ra) # 8000405e <install_trans>
    log.lh.n = 0;
    80004368:	0001d797          	auipc	a5,0x1d
    8000436c:	5c07a623          	sw	zero,1484(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004370:	00000097          	auipc	ra,0x0
    80004374:	c84080e7          	jalr	-892(ra) # 80003ff4 <write_head>
    80004378:	bdfd                	j	80004276 <end_op+0x52>

000000008000437a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000437a:	1101                	add	sp,sp,-32
    8000437c:	ec06                	sd	ra,24(sp)
    8000437e:	e822                	sd	s0,16(sp)
    80004380:	e426                	sd	s1,8(sp)
    80004382:	e04a                	sd	s2,0(sp)
    80004384:	1000                	add	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004386:	0001d717          	auipc	a4,0x1d
    8000438a:	5ae72703          	lw	a4,1454(a4) # 80021934 <log+0x2c>
    8000438e:	47f5                	li	a5,29
    80004390:	08e7c063          	blt	a5,a4,80004410 <log_write+0x96>
    80004394:	84aa                	mv	s1,a0
    80004396:	0001d797          	auipc	a5,0x1d
    8000439a:	58e7a783          	lw	a5,1422(a5) # 80021924 <log+0x1c>
    8000439e:	37fd                	addw	a5,a5,-1
    800043a0:	06f75863          	bge	a4,a5,80004410 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043a4:	0001d797          	auipc	a5,0x1d
    800043a8:	5847a783          	lw	a5,1412(a5) # 80021928 <log+0x20>
    800043ac:	06f05a63          	blez	a5,80004420 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800043b0:	0001d917          	auipc	s2,0x1d
    800043b4:	55890913          	add	s2,s2,1368 # 80021908 <log>
    800043b8:	854a                	mv	a0,s2
    800043ba:	ffffd097          	auipc	ra,0xffffd
    800043be:	842080e7          	jalr	-1982(ra) # 80000bfc <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800043c2:	02c92603          	lw	a2,44(s2)
    800043c6:	06c05563          	blez	a2,80004430 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043ca:	44cc                	lw	a1,12(s1)
    800043cc:	0001d717          	auipc	a4,0x1d
    800043d0:	56c70713          	add	a4,a4,1388 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043d4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043d6:	4314                	lw	a3,0(a4)
    800043d8:	04b68d63          	beq	a3,a1,80004432 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800043dc:	2785                	addw	a5,a5,1
    800043de:	0711                	add	a4,a4,4
    800043e0:	fec79be3          	bne	a5,a2,800043d6 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043e4:	0621                	add	a2,a2,8
    800043e6:	060a                	sll	a2,a2,0x2
    800043e8:	0001d797          	auipc	a5,0x1d
    800043ec:	52078793          	add	a5,a5,1312 # 80021908 <log>
    800043f0:	97b2                	add	a5,a5,a2
    800043f2:	44d8                	lw	a4,12(s1)
    800043f4:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043f6:	8526                	mv	a0,s1
    800043f8:	fffff097          	auipc	ra,0xfffff
    800043fc:	de0080e7          	jalr	-544(ra) # 800031d8 <bpin>
    log.lh.n++;
    80004400:	0001d717          	auipc	a4,0x1d
    80004404:	50870713          	add	a4,a4,1288 # 80021908 <log>
    80004408:	575c                	lw	a5,44(a4)
    8000440a:	2785                	addw	a5,a5,1
    8000440c:	d75c                	sw	a5,44(a4)
    8000440e:	a835                	j	8000444a <log_write+0xd0>
    panic("too big a transaction");
    80004410:	00004517          	auipc	a0,0x4
    80004414:	27850513          	add	a0,a0,632 # 80008688 <syscalls+0x1f0>
    80004418:	ffffc097          	auipc	ra,0xffffc
    8000441c:	12a080e7          	jalr	298(ra) # 80000542 <panic>
    panic("log_write outside of trans");
    80004420:	00004517          	auipc	a0,0x4
    80004424:	28050513          	add	a0,a0,640 # 800086a0 <syscalls+0x208>
    80004428:	ffffc097          	auipc	ra,0xffffc
    8000442c:	11a080e7          	jalr	282(ra) # 80000542 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004430:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004432:	00878693          	add	a3,a5,8
    80004436:	068a                	sll	a3,a3,0x2
    80004438:	0001d717          	auipc	a4,0x1d
    8000443c:	4d070713          	add	a4,a4,1232 # 80021908 <log>
    80004440:	9736                	add	a4,a4,a3
    80004442:	44d4                	lw	a3,12(s1)
    80004444:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004446:	faf608e3          	beq	a2,a5,800043f6 <log_write+0x7c>
  }
  release(&log.lock);
    8000444a:	0001d517          	auipc	a0,0x1d
    8000444e:	4be50513          	add	a0,a0,1214 # 80021908 <log>
    80004452:	ffffd097          	auipc	ra,0xffffd
    80004456:	85e080e7          	jalr	-1954(ra) # 80000cb0 <release>
}
    8000445a:	60e2                	ld	ra,24(sp)
    8000445c:	6442                	ld	s0,16(sp)
    8000445e:	64a2                	ld	s1,8(sp)
    80004460:	6902                	ld	s2,0(sp)
    80004462:	6105                	add	sp,sp,32
    80004464:	8082                	ret

0000000080004466 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004466:	1101                	add	sp,sp,-32
    80004468:	ec06                	sd	ra,24(sp)
    8000446a:	e822                	sd	s0,16(sp)
    8000446c:	e426                	sd	s1,8(sp)
    8000446e:	e04a                	sd	s2,0(sp)
    80004470:	1000                	add	s0,sp,32
    80004472:	84aa                	mv	s1,a0
    80004474:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004476:	00004597          	auipc	a1,0x4
    8000447a:	24a58593          	add	a1,a1,586 # 800086c0 <syscalls+0x228>
    8000447e:	0521                	add	a0,a0,8
    80004480:	ffffc097          	auipc	ra,0xffffc
    80004484:	6ec080e7          	jalr	1772(ra) # 80000b6c <initlock>
  lk->name = name;
    80004488:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000448c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004490:	0204a423          	sw	zero,40(s1)
}
    80004494:	60e2                	ld	ra,24(sp)
    80004496:	6442                	ld	s0,16(sp)
    80004498:	64a2                	ld	s1,8(sp)
    8000449a:	6902                	ld	s2,0(sp)
    8000449c:	6105                	add	sp,sp,32
    8000449e:	8082                	ret

00000000800044a0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044a0:	1101                	add	sp,sp,-32
    800044a2:	ec06                	sd	ra,24(sp)
    800044a4:	e822                	sd	s0,16(sp)
    800044a6:	e426                	sd	s1,8(sp)
    800044a8:	e04a                	sd	s2,0(sp)
    800044aa:	1000                	add	s0,sp,32
    800044ac:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044ae:	00850913          	add	s2,a0,8
    800044b2:	854a                	mv	a0,s2
    800044b4:	ffffc097          	auipc	ra,0xffffc
    800044b8:	748080e7          	jalr	1864(ra) # 80000bfc <acquire>
  while (lk->locked) {
    800044bc:	409c                	lw	a5,0(s1)
    800044be:	cb89                	beqz	a5,800044d0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044c0:	85ca                	mv	a1,s2
    800044c2:	8526                	mv	a0,s1
    800044c4:	ffffe097          	auipc	ra,0xffffe
    800044c8:	e4a080e7          	jalr	-438(ra) # 8000230e <sleep>
  while (lk->locked) {
    800044cc:	409c                	lw	a5,0(s1)
    800044ce:	fbed                	bnez	a5,800044c0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044d0:	4785                	li	a5,1
    800044d2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044d4:	ffffd097          	auipc	ra,0xffffd
    800044d8:	624080e7          	jalr	1572(ra) # 80001af8 <myproc>
    800044dc:	5d1c                	lw	a5,56(a0)
    800044de:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044e0:	854a                	mv	a0,s2
    800044e2:	ffffc097          	auipc	ra,0xffffc
    800044e6:	7ce080e7          	jalr	1998(ra) # 80000cb0 <release>
}
    800044ea:	60e2                	ld	ra,24(sp)
    800044ec:	6442                	ld	s0,16(sp)
    800044ee:	64a2                	ld	s1,8(sp)
    800044f0:	6902                	ld	s2,0(sp)
    800044f2:	6105                	add	sp,sp,32
    800044f4:	8082                	ret

00000000800044f6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044f6:	1101                	add	sp,sp,-32
    800044f8:	ec06                	sd	ra,24(sp)
    800044fa:	e822                	sd	s0,16(sp)
    800044fc:	e426                	sd	s1,8(sp)
    800044fe:	e04a                	sd	s2,0(sp)
    80004500:	1000                	add	s0,sp,32
    80004502:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004504:	00850913          	add	s2,a0,8
    80004508:	854a                	mv	a0,s2
    8000450a:	ffffc097          	auipc	ra,0xffffc
    8000450e:	6f2080e7          	jalr	1778(ra) # 80000bfc <acquire>
  lk->locked = 0;
    80004512:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004516:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000451a:	8526                	mv	a0,s1
    8000451c:	ffffe097          	auipc	ra,0xffffe
    80004520:	f72080e7          	jalr	-142(ra) # 8000248e <wakeup>
  release(&lk->lk);
    80004524:	854a                	mv	a0,s2
    80004526:	ffffc097          	auipc	ra,0xffffc
    8000452a:	78a080e7          	jalr	1930(ra) # 80000cb0 <release>
}
    8000452e:	60e2                	ld	ra,24(sp)
    80004530:	6442                	ld	s0,16(sp)
    80004532:	64a2                	ld	s1,8(sp)
    80004534:	6902                	ld	s2,0(sp)
    80004536:	6105                	add	sp,sp,32
    80004538:	8082                	ret

000000008000453a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000453a:	7179                	add	sp,sp,-48
    8000453c:	f406                	sd	ra,40(sp)
    8000453e:	f022                	sd	s0,32(sp)
    80004540:	ec26                	sd	s1,24(sp)
    80004542:	e84a                	sd	s2,16(sp)
    80004544:	e44e                	sd	s3,8(sp)
    80004546:	1800                	add	s0,sp,48
    80004548:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000454a:	00850913          	add	s2,a0,8
    8000454e:	854a                	mv	a0,s2
    80004550:	ffffc097          	auipc	ra,0xffffc
    80004554:	6ac080e7          	jalr	1708(ra) # 80000bfc <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004558:	409c                	lw	a5,0(s1)
    8000455a:	ef99                	bnez	a5,80004578 <holdingsleep+0x3e>
    8000455c:	4481                	li	s1,0
  release(&lk->lk);
    8000455e:	854a                	mv	a0,s2
    80004560:	ffffc097          	auipc	ra,0xffffc
    80004564:	750080e7          	jalr	1872(ra) # 80000cb0 <release>
  return r;
}
    80004568:	8526                	mv	a0,s1
    8000456a:	70a2                	ld	ra,40(sp)
    8000456c:	7402                	ld	s0,32(sp)
    8000456e:	64e2                	ld	s1,24(sp)
    80004570:	6942                	ld	s2,16(sp)
    80004572:	69a2                	ld	s3,8(sp)
    80004574:	6145                	add	sp,sp,48
    80004576:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004578:	0284a983          	lw	s3,40(s1)
    8000457c:	ffffd097          	auipc	ra,0xffffd
    80004580:	57c080e7          	jalr	1404(ra) # 80001af8 <myproc>
    80004584:	5d04                	lw	s1,56(a0)
    80004586:	413484b3          	sub	s1,s1,s3
    8000458a:	0014b493          	seqz	s1,s1
    8000458e:	bfc1                	j	8000455e <holdingsleep+0x24>

0000000080004590 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004590:	1141                	add	sp,sp,-16
    80004592:	e406                	sd	ra,8(sp)
    80004594:	e022                	sd	s0,0(sp)
    80004596:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004598:	00004597          	auipc	a1,0x4
    8000459c:	13858593          	add	a1,a1,312 # 800086d0 <syscalls+0x238>
    800045a0:	0001d517          	auipc	a0,0x1d
    800045a4:	4b050513          	add	a0,a0,1200 # 80021a50 <ftable>
    800045a8:	ffffc097          	auipc	ra,0xffffc
    800045ac:	5c4080e7          	jalr	1476(ra) # 80000b6c <initlock>
}
    800045b0:	60a2                	ld	ra,8(sp)
    800045b2:	6402                	ld	s0,0(sp)
    800045b4:	0141                	add	sp,sp,16
    800045b6:	8082                	ret

00000000800045b8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045b8:	1101                	add	sp,sp,-32
    800045ba:	ec06                	sd	ra,24(sp)
    800045bc:	e822                	sd	s0,16(sp)
    800045be:	e426                	sd	s1,8(sp)
    800045c0:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045c2:	0001d517          	auipc	a0,0x1d
    800045c6:	48e50513          	add	a0,a0,1166 # 80021a50 <ftable>
    800045ca:	ffffc097          	auipc	ra,0xffffc
    800045ce:	632080e7          	jalr	1586(ra) # 80000bfc <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045d2:	0001d497          	auipc	s1,0x1d
    800045d6:	49648493          	add	s1,s1,1174 # 80021a68 <ftable+0x18>
    800045da:	0001e717          	auipc	a4,0x1e
    800045de:	42e70713          	add	a4,a4,1070 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    800045e2:	40dc                	lw	a5,4(s1)
    800045e4:	cf99                	beqz	a5,80004602 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045e6:	02848493          	add	s1,s1,40
    800045ea:	fee49ce3          	bne	s1,a4,800045e2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045ee:	0001d517          	auipc	a0,0x1d
    800045f2:	46250513          	add	a0,a0,1122 # 80021a50 <ftable>
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	6ba080e7          	jalr	1722(ra) # 80000cb0 <release>
  return 0;
    800045fe:	4481                	li	s1,0
    80004600:	a819                	j	80004616 <filealloc+0x5e>
      f->ref = 1;
    80004602:	4785                	li	a5,1
    80004604:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004606:	0001d517          	auipc	a0,0x1d
    8000460a:	44a50513          	add	a0,a0,1098 # 80021a50 <ftable>
    8000460e:	ffffc097          	auipc	ra,0xffffc
    80004612:	6a2080e7          	jalr	1698(ra) # 80000cb0 <release>
}
    80004616:	8526                	mv	a0,s1
    80004618:	60e2                	ld	ra,24(sp)
    8000461a:	6442                	ld	s0,16(sp)
    8000461c:	64a2                	ld	s1,8(sp)
    8000461e:	6105                	add	sp,sp,32
    80004620:	8082                	ret

0000000080004622 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004622:	1101                	add	sp,sp,-32
    80004624:	ec06                	sd	ra,24(sp)
    80004626:	e822                	sd	s0,16(sp)
    80004628:	e426                	sd	s1,8(sp)
    8000462a:	1000                	add	s0,sp,32
    8000462c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000462e:	0001d517          	auipc	a0,0x1d
    80004632:	42250513          	add	a0,a0,1058 # 80021a50 <ftable>
    80004636:	ffffc097          	auipc	ra,0xffffc
    8000463a:	5c6080e7          	jalr	1478(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    8000463e:	40dc                	lw	a5,4(s1)
    80004640:	02f05263          	blez	a5,80004664 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004644:	2785                	addw	a5,a5,1
    80004646:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004648:	0001d517          	auipc	a0,0x1d
    8000464c:	40850513          	add	a0,a0,1032 # 80021a50 <ftable>
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	660080e7          	jalr	1632(ra) # 80000cb0 <release>
  return f;
}
    80004658:	8526                	mv	a0,s1
    8000465a:	60e2                	ld	ra,24(sp)
    8000465c:	6442                	ld	s0,16(sp)
    8000465e:	64a2                	ld	s1,8(sp)
    80004660:	6105                	add	sp,sp,32
    80004662:	8082                	ret
    panic("filedup");
    80004664:	00004517          	auipc	a0,0x4
    80004668:	07450513          	add	a0,a0,116 # 800086d8 <syscalls+0x240>
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	ed6080e7          	jalr	-298(ra) # 80000542 <panic>

0000000080004674 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004674:	7139                	add	sp,sp,-64
    80004676:	fc06                	sd	ra,56(sp)
    80004678:	f822                	sd	s0,48(sp)
    8000467a:	f426                	sd	s1,40(sp)
    8000467c:	f04a                	sd	s2,32(sp)
    8000467e:	ec4e                	sd	s3,24(sp)
    80004680:	e852                	sd	s4,16(sp)
    80004682:	e456                	sd	s5,8(sp)
    80004684:	0080                	add	s0,sp,64
    80004686:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004688:	0001d517          	auipc	a0,0x1d
    8000468c:	3c850513          	add	a0,a0,968 # 80021a50 <ftable>
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	56c080e7          	jalr	1388(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    80004698:	40dc                	lw	a5,4(s1)
    8000469a:	06f05163          	blez	a5,800046fc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000469e:	37fd                	addw	a5,a5,-1
    800046a0:	0007871b          	sext.w	a4,a5
    800046a4:	c0dc                	sw	a5,4(s1)
    800046a6:	06e04363          	bgtz	a4,8000470c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046aa:	0004a903          	lw	s2,0(s1)
    800046ae:	0094ca83          	lbu	s5,9(s1)
    800046b2:	0104ba03          	ld	s4,16(s1)
    800046b6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046ba:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046be:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046c2:	0001d517          	auipc	a0,0x1d
    800046c6:	38e50513          	add	a0,a0,910 # 80021a50 <ftable>
    800046ca:	ffffc097          	auipc	ra,0xffffc
    800046ce:	5e6080e7          	jalr	1510(ra) # 80000cb0 <release>

  if(ff.type == FD_PIPE){
    800046d2:	4785                	li	a5,1
    800046d4:	04f90d63          	beq	s2,a5,8000472e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046d8:	3979                	addw	s2,s2,-2
    800046da:	4785                	li	a5,1
    800046dc:	0527e063          	bltu	a5,s2,8000471c <fileclose+0xa8>
    begin_op();
    800046e0:	00000097          	auipc	ra,0x0
    800046e4:	aca080e7          	jalr	-1334(ra) # 800041aa <begin_op>
    iput(ff.ip);
    800046e8:	854e                	mv	a0,s3
    800046ea:	fffff097          	auipc	ra,0xfffff
    800046ee:	2d6080e7          	jalr	726(ra) # 800039c0 <iput>
    end_op();
    800046f2:	00000097          	auipc	ra,0x0
    800046f6:	b32080e7          	jalr	-1230(ra) # 80004224 <end_op>
    800046fa:	a00d                	j	8000471c <fileclose+0xa8>
    panic("fileclose");
    800046fc:	00004517          	auipc	a0,0x4
    80004700:	fe450513          	add	a0,a0,-28 # 800086e0 <syscalls+0x248>
    80004704:	ffffc097          	auipc	ra,0xffffc
    80004708:	e3e080e7          	jalr	-450(ra) # 80000542 <panic>
    release(&ftable.lock);
    8000470c:	0001d517          	auipc	a0,0x1d
    80004710:	34450513          	add	a0,a0,836 # 80021a50 <ftable>
    80004714:	ffffc097          	auipc	ra,0xffffc
    80004718:	59c080e7          	jalr	1436(ra) # 80000cb0 <release>
  }
}
    8000471c:	70e2                	ld	ra,56(sp)
    8000471e:	7442                	ld	s0,48(sp)
    80004720:	74a2                	ld	s1,40(sp)
    80004722:	7902                	ld	s2,32(sp)
    80004724:	69e2                	ld	s3,24(sp)
    80004726:	6a42                	ld	s4,16(sp)
    80004728:	6aa2                	ld	s5,8(sp)
    8000472a:	6121                	add	sp,sp,64
    8000472c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000472e:	85d6                	mv	a1,s5
    80004730:	8552                	mv	a0,s4
    80004732:	00000097          	auipc	ra,0x0
    80004736:	372080e7          	jalr	882(ra) # 80004aa4 <pipeclose>
    8000473a:	b7cd                	j	8000471c <fileclose+0xa8>

000000008000473c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000473c:	715d                	add	sp,sp,-80
    8000473e:	e486                	sd	ra,72(sp)
    80004740:	e0a2                	sd	s0,64(sp)
    80004742:	fc26                	sd	s1,56(sp)
    80004744:	f84a                	sd	s2,48(sp)
    80004746:	f44e                	sd	s3,40(sp)
    80004748:	0880                	add	s0,sp,80
    8000474a:	84aa                	mv	s1,a0
    8000474c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000474e:	ffffd097          	auipc	ra,0xffffd
    80004752:	3aa080e7          	jalr	938(ra) # 80001af8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004756:	409c                	lw	a5,0(s1)
    80004758:	37f9                	addw	a5,a5,-2
    8000475a:	4705                	li	a4,1
    8000475c:	04f76763          	bltu	a4,a5,800047aa <filestat+0x6e>
    80004760:	892a                	mv	s2,a0
    ilock(f->ip);
    80004762:	6c88                	ld	a0,24(s1)
    80004764:	fffff097          	auipc	ra,0xfffff
    80004768:	0a2080e7          	jalr	162(ra) # 80003806 <ilock>
    stati(f->ip, &st);
    8000476c:	fb840593          	add	a1,s0,-72
    80004770:	6c88                	ld	a0,24(s1)
    80004772:	fffff097          	auipc	ra,0xfffff
    80004776:	31e080e7          	jalr	798(ra) # 80003a90 <stati>
    iunlock(f->ip);
    8000477a:	6c88                	ld	a0,24(s1)
    8000477c:	fffff097          	auipc	ra,0xfffff
    80004780:	14c080e7          	jalr	332(ra) # 800038c8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004784:	46e1                	li	a3,24
    80004786:	fb840613          	add	a2,s0,-72
    8000478a:	85ce                	mv	a1,s3
    8000478c:	05093503          	ld	a0,80(s2)
    80004790:	ffffd097          	auipc	ra,0xffffd
    80004794:	05e080e7          	jalr	94(ra) # 800017ee <copyout>
    80004798:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000479c:	60a6                	ld	ra,72(sp)
    8000479e:	6406                	ld	s0,64(sp)
    800047a0:	74e2                	ld	s1,56(sp)
    800047a2:	7942                	ld	s2,48(sp)
    800047a4:	79a2                	ld	s3,40(sp)
    800047a6:	6161                	add	sp,sp,80
    800047a8:	8082                	ret
  return -1;
    800047aa:	557d                	li	a0,-1
    800047ac:	bfc5                	j	8000479c <filestat+0x60>

00000000800047ae <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047ae:	7179                	add	sp,sp,-48
    800047b0:	f406                	sd	ra,40(sp)
    800047b2:	f022                	sd	s0,32(sp)
    800047b4:	ec26                	sd	s1,24(sp)
    800047b6:	e84a                	sd	s2,16(sp)
    800047b8:	e44e                	sd	s3,8(sp)
    800047ba:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047bc:	00854783          	lbu	a5,8(a0)
    800047c0:	c3d5                	beqz	a5,80004864 <fileread+0xb6>
    800047c2:	84aa                	mv	s1,a0
    800047c4:	89ae                	mv	s3,a1
    800047c6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047c8:	411c                	lw	a5,0(a0)
    800047ca:	4705                	li	a4,1
    800047cc:	04e78963          	beq	a5,a4,8000481e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047d0:	470d                	li	a4,3
    800047d2:	04e78d63          	beq	a5,a4,8000482c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047d6:	4709                	li	a4,2
    800047d8:	06e79e63          	bne	a5,a4,80004854 <fileread+0xa6>
    ilock(f->ip);
    800047dc:	6d08                	ld	a0,24(a0)
    800047de:	fffff097          	auipc	ra,0xfffff
    800047e2:	028080e7          	jalr	40(ra) # 80003806 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047e6:	874a                	mv	a4,s2
    800047e8:	5094                	lw	a3,32(s1)
    800047ea:	864e                	mv	a2,s3
    800047ec:	4585                	li	a1,1
    800047ee:	6c88                	ld	a0,24(s1)
    800047f0:	fffff097          	auipc	ra,0xfffff
    800047f4:	2ca080e7          	jalr	714(ra) # 80003aba <readi>
    800047f8:	892a                	mv	s2,a0
    800047fa:	00a05563          	blez	a0,80004804 <fileread+0x56>
      f->off += r;
    800047fe:	509c                	lw	a5,32(s1)
    80004800:	9fa9                	addw	a5,a5,a0
    80004802:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004804:	6c88                	ld	a0,24(s1)
    80004806:	fffff097          	auipc	ra,0xfffff
    8000480a:	0c2080e7          	jalr	194(ra) # 800038c8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000480e:	854a                	mv	a0,s2
    80004810:	70a2                	ld	ra,40(sp)
    80004812:	7402                	ld	s0,32(sp)
    80004814:	64e2                	ld	s1,24(sp)
    80004816:	6942                	ld	s2,16(sp)
    80004818:	69a2                	ld	s3,8(sp)
    8000481a:	6145                	add	sp,sp,48
    8000481c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000481e:	6908                	ld	a0,16(a0)
    80004820:	00000097          	auipc	ra,0x0
    80004824:	3ee080e7          	jalr	1006(ra) # 80004c0e <piperead>
    80004828:	892a                	mv	s2,a0
    8000482a:	b7d5                	j	8000480e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000482c:	02451783          	lh	a5,36(a0)
    80004830:	03079693          	sll	a3,a5,0x30
    80004834:	92c1                	srl	a3,a3,0x30
    80004836:	4725                	li	a4,9
    80004838:	02d76863          	bltu	a4,a3,80004868 <fileread+0xba>
    8000483c:	0792                	sll	a5,a5,0x4
    8000483e:	0001d717          	auipc	a4,0x1d
    80004842:	17270713          	add	a4,a4,370 # 800219b0 <devsw>
    80004846:	97ba                	add	a5,a5,a4
    80004848:	639c                	ld	a5,0(a5)
    8000484a:	c38d                	beqz	a5,8000486c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000484c:	4505                	li	a0,1
    8000484e:	9782                	jalr	a5
    80004850:	892a                	mv	s2,a0
    80004852:	bf75                	j	8000480e <fileread+0x60>
    panic("fileread");
    80004854:	00004517          	auipc	a0,0x4
    80004858:	e9c50513          	add	a0,a0,-356 # 800086f0 <syscalls+0x258>
    8000485c:	ffffc097          	auipc	ra,0xffffc
    80004860:	ce6080e7          	jalr	-794(ra) # 80000542 <panic>
    return -1;
    80004864:	597d                	li	s2,-1
    80004866:	b765                	j	8000480e <fileread+0x60>
      return -1;
    80004868:	597d                	li	s2,-1
    8000486a:	b755                	j	8000480e <fileread+0x60>
    8000486c:	597d                	li	s2,-1
    8000486e:	b745                	j	8000480e <fileread+0x60>

0000000080004870 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004870:	00954783          	lbu	a5,9(a0)
    80004874:	14078363          	beqz	a5,800049ba <filewrite+0x14a>
{
    80004878:	715d                	add	sp,sp,-80
    8000487a:	e486                	sd	ra,72(sp)
    8000487c:	e0a2                	sd	s0,64(sp)
    8000487e:	fc26                	sd	s1,56(sp)
    80004880:	f84a                	sd	s2,48(sp)
    80004882:	f44e                	sd	s3,40(sp)
    80004884:	f052                	sd	s4,32(sp)
    80004886:	ec56                	sd	s5,24(sp)
    80004888:	e85a                	sd	s6,16(sp)
    8000488a:	e45e                	sd	s7,8(sp)
    8000488c:	e062                	sd	s8,0(sp)
    8000488e:	0880                	add	s0,sp,80
    80004890:	892a                	mv	s2,a0
    80004892:	8b2e                	mv	s6,a1
    80004894:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004896:	411c                	lw	a5,0(a0)
    80004898:	4705                	li	a4,1
    8000489a:	02e78263          	beq	a5,a4,800048be <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000489e:	470d                	li	a4,3
    800048a0:	02e78563          	beq	a5,a4,800048ca <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048a4:	4709                	li	a4,2
    800048a6:	10e79263          	bne	a5,a4,800049aa <filewrite+0x13a>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048aa:	0ec05e63          	blez	a2,800049a6 <filewrite+0x136>
    int i = 0;
    800048ae:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    800048b0:	6b85                	lui	s7,0x1
    800048b2:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800048b6:	6c05                	lui	s8,0x1
    800048b8:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800048bc:	a851                	j	80004950 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800048be:	6908                	ld	a0,16(a0)
    800048c0:	00000097          	auipc	ra,0x0
    800048c4:	254080e7          	jalr	596(ra) # 80004b14 <pipewrite>
    800048c8:	a85d                	j	8000497e <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048ca:	02451783          	lh	a5,36(a0)
    800048ce:	03079693          	sll	a3,a5,0x30
    800048d2:	92c1                	srl	a3,a3,0x30
    800048d4:	4725                	li	a4,9
    800048d6:	0ed76463          	bltu	a4,a3,800049be <filewrite+0x14e>
    800048da:	0792                	sll	a5,a5,0x4
    800048dc:	0001d717          	auipc	a4,0x1d
    800048e0:	0d470713          	add	a4,a4,212 # 800219b0 <devsw>
    800048e4:	97ba                	add	a5,a5,a4
    800048e6:	679c                	ld	a5,8(a5)
    800048e8:	cfe9                	beqz	a5,800049c2 <filewrite+0x152>
    ret = devsw[f->major].write(1, addr, n);
    800048ea:	4505                	li	a0,1
    800048ec:	9782                	jalr	a5
    800048ee:	a841                	j	8000497e <filewrite+0x10e>
      if(n1 > max)
    800048f0:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    800048f4:	00000097          	auipc	ra,0x0
    800048f8:	8b6080e7          	jalr	-1866(ra) # 800041aa <begin_op>
      ilock(f->ip);
    800048fc:	01893503          	ld	a0,24(s2)
    80004900:	fffff097          	auipc	ra,0xfffff
    80004904:	f06080e7          	jalr	-250(ra) # 80003806 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004908:	8756                	mv	a4,s5
    8000490a:	02092683          	lw	a3,32(s2)
    8000490e:	01698633          	add	a2,s3,s6
    80004912:	4585                	li	a1,1
    80004914:	01893503          	ld	a0,24(s2)
    80004918:	fffff097          	auipc	ra,0xfffff
    8000491c:	29a080e7          	jalr	666(ra) # 80003bb2 <writei>
    80004920:	84aa                	mv	s1,a0
    80004922:	02a05f63          	blez	a0,80004960 <filewrite+0xf0>
        f->off += r;
    80004926:	02092783          	lw	a5,32(s2)
    8000492a:	9fa9                	addw	a5,a5,a0
    8000492c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004930:	01893503          	ld	a0,24(s2)
    80004934:	fffff097          	auipc	ra,0xfffff
    80004938:	f94080e7          	jalr	-108(ra) # 800038c8 <iunlock>
      end_op();
    8000493c:	00000097          	auipc	ra,0x0
    80004940:	8e8080e7          	jalr	-1816(ra) # 80004224 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004944:	049a9963          	bne	s5,s1,80004996 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004948:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000494c:	0349d663          	bge	s3,s4,80004978 <filewrite+0x108>
      int n1 = n - i;
    80004950:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004954:	0004879b          	sext.w	a5,s1
    80004958:	f8fbdce3          	bge	s7,a5,800048f0 <filewrite+0x80>
    8000495c:	84e2                	mv	s1,s8
    8000495e:	bf49                	j	800048f0 <filewrite+0x80>
      iunlock(f->ip);
    80004960:	01893503          	ld	a0,24(s2)
    80004964:	fffff097          	auipc	ra,0xfffff
    80004968:	f64080e7          	jalr	-156(ra) # 800038c8 <iunlock>
      end_op();
    8000496c:	00000097          	auipc	ra,0x0
    80004970:	8b8080e7          	jalr	-1864(ra) # 80004224 <end_op>
      if(r < 0)
    80004974:	fc04d8e3          	bgez	s1,80004944 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004978:	053a1763          	bne	s4,s3,800049c6 <filewrite+0x156>
    8000497c:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000497e:	60a6                	ld	ra,72(sp)
    80004980:	6406                	ld	s0,64(sp)
    80004982:	74e2                	ld	s1,56(sp)
    80004984:	7942                	ld	s2,48(sp)
    80004986:	79a2                	ld	s3,40(sp)
    80004988:	7a02                	ld	s4,32(sp)
    8000498a:	6ae2                	ld	s5,24(sp)
    8000498c:	6b42                	ld	s6,16(sp)
    8000498e:	6ba2                	ld	s7,8(sp)
    80004990:	6c02                	ld	s8,0(sp)
    80004992:	6161                	add	sp,sp,80
    80004994:	8082                	ret
        panic("short filewrite");
    80004996:	00004517          	auipc	a0,0x4
    8000499a:	d6a50513          	add	a0,a0,-662 # 80008700 <syscalls+0x268>
    8000499e:	ffffc097          	auipc	ra,0xffffc
    800049a2:	ba4080e7          	jalr	-1116(ra) # 80000542 <panic>
    int i = 0;
    800049a6:	4981                	li	s3,0
    800049a8:	bfc1                	j	80004978 <filewrite+0x108>
    panic("filewrite");
    800049aa:	00004517          	auipc	a0,0x4
    800049ae:	d6650513          	add	a0,a0,-666 # 80008710 <syscalls+0x278>
    800049b2:	ffffc097          	auipc	ra,0xffffc
    800049b6:	b90080e7          	jalr	-1136(ra) # 80000542 <panic>
    return -1;
    800049ba:	557d                	li	a0,-1
}
    800049bc:	8082                	ret
      return -1;
    800049be:	557d                	li	a0,-1
    800049c0:	bf7d                	j	8000497e <filewrite+0x10e>
    800049c2:	557d                	li	a0,-1
    800049c4:	bf6d                	j	8000497e <filewrite+0x10e>
    ret = (i == n ? n : -1);
    800049c6:	557d                	li	a0,-1
    800049c8:	bf5d                	j	8000497e <filewrite+0x10e>

00000000800049ca <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049ca:	7179                	add	sp,sp,-48
    800049cc:	f406                	sd	ra,40(sp)
    800049ce:	f022                	sd	s0,32(sp)
    800049d0:	ec26                	sd	s1,24(sp)
    800049d2:	e84a                	sd	s2,16(sp)
    800049d4:	e44e                	sd	s3,8(sp)
    800049d6:	e052                	sd	s4,0(sp)
    800049d8:	1800                	add	s0,sp,48
    800049da:	84aa                	mv	s1,a0
    800049dc:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049de:	0005b023          	sd	zero,0(a1)
    800049e2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049e6:	00000097          	auipc	ra,0x0
    800049ea:	bd2080e7          	jalr	-1070(ra) # 800045b8 <filealloc>
    800049ee:	e088                	sd	a0,0(s1)
    800049f0:	c551                	beqz	a0,80004a7c <pipealloc+0xb2>
    800049f2:	00000097          	auipc	ra,0x0
    800049f6:	bc6080e7          	jalr	-1082(ra) # 800045b8 <filealloc>
    800049fa:	00aa3023          	sd	a0,0(s4)
    800049fe:	c92d                	beqz	a0,80004a70 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a00:	ffffc097          	auipc	ra,0xffffc
    80004a04:	10c080e7          	jalr	268(ra) # 80000b0c <kalloc>
    80004a08:	892a                	mv	s2,a0
    80004a0a:	c125                	beqz	a0,80004a6a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a0c:	4985                	li	s3,1
    80004a0e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a12:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a16:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a1a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a1e:	00004597          	auipc	a1,0x4
    80004a22:	d0258593          	add	a1,a1,-766 # 80008720 <syscalls+0x288>
    80004a26:	ffffc097          	auipc	ra,0xffffc
    80004a2a:	146080e7          	jalr	326(ra) # 80000b6c <initlock>
  (*f0)->type = FD_PIPE;
    80004a2e:	609c                	ld	a5,0(s1)
    80004a30:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a34:	609c                	ld	a5,0(s1)
    80004a36:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a3a:	609c                	ld	a5,0(s1)
    80004a3c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a40:	609c                	ld	a5,0(s1)
    80004a42:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a46:	000a3783          	ld	a5,0(s4)
    80004a4a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a4e:	000a3783          	ld	a5,0(s4)
    80004a52:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a56:	000a3783          	ld	a5,0(s4)
    80004a5a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a5e:	000a3783          	ld	a5,0(s4)
    80004a62:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a66:	4501                	li	a0,0
    80004a68:	a025                	j	80004a90 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a6a:	6088                	ld	a0,0(s1)
    80004a6c:	e501                	bnez	a0,80004a74 <pipealloc+0xaa>
    80004a6e:	a039                	j	80004a7c <pipealloc+0xb2>
    80004a70:	6088                	ld	a0,0(s1)
    80004a72:	c51d                	beqz	a0,80004aa0 <pipealloc+0xd6>
    fileclose(*f0);
    80004a74:	00000097          	auipc	ra,0x0
    80004a78:	c00080e7          	jalr	-1024(ra) # 80004674 <fileclose>
  if(*f1)
    80004a7c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a80:	557d                	li	a0,-1
  if(*f1)
    80004a82:	c799                	beqz	a5,80004a90 <pipealloc+0xc6>
    fileclose(*f1);
    80004a84:	853e                	mv	a0,a5
    80004a86:	00000097          	auipc	ra,0x0
    80004a8a:	bee080e7          	jalr	-1042(ra) # 80004674 <fileclose>
  return -1;
    80004a8e:	557d                	li	a0,-1
}
    80004a90:	70a2                	ld	ra,40(sp)
    80004a92:	7402                	ld	s0,32(sp)
    80004a94:	64e2                	ld	s1,24(sp)
    80004a96:	6942                	ld	s2,16(sp)
    80004a98:	69a2                	ld	s3,8(sp)
    80004a9a:	6a02                	ld	s4,0(sp)
    80004a9c:	6145                	add	sp,sp,48
    80004a9e:	8082                	ret
  return -1;
    80004aa0:	557d                	li	a0,-1
    80004aa2:	b7fd                	j	80004a90 <pipealloc+0xc6>

0000000080004aa4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004aa4:	1101                	add	sp,sp,-32
    80004aa6:	ec06                	sd	ra,24(sp)
    80004aa8:	e822                	sd	s0,16(sp)
    80004aaa:	e426                	sd	s1,8(sp)
    80004aac:	e04a                	sd	s2,0(sp)
    80004aae:	1000                	add	s0,sp,32
    80004ab0:	84aa                	mv	s1,a0
    80004ab2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ab4:	ffffc097          	auipc	ra,0xffffc
    80004ab8:	148080e7          	jalr	328(ra) # 80000bfc <acquire>
  if(writable){
    80004abc:	02090d63          	beqz	s2,80004af6 <pipeclose+0x52>
    pi->writeopen = 0;
    80004ac0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ac4:	21848513          	add	a0,s1,536
    80004ac8:	ffffe097          	auipc	ra,0xffffe
    80004acc:	9c6080e7          	jalr	-1594(ra) # 8000248e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ad0:	2204b783          	ld	a5,544(s1)
    80004ad4:	eb95                	bnez	a5,80004b08 <pipeclose+0x64>
    release(&pi->lock);
    80004ad6:	8526                	mv	a0,s1
    80004ad8:	ffffc097          	auipc	ra,0xffffc
    80004adc:	1d8080e7          	jalr	472(ra) # 80000cb0 <release>
    kfree((char*)pi);
    80004ae0:	8526                	mv	a0,s1
    80004ae2:	ffffc097          	auipc	ra,0xffffc
    80004ae6:	f2c080e7          	jalr	-212(ra) # 80000a0e <kfree>
  } else
    release(&pi->lock);
}
    80004aea:	60e2                	ld	ra,24(sp)
    80004aec:	6442                	ld	s0,16(sp)
    80004aee:	64a2                	ld	s1,8(sp)
    80004af0:	6902                	ld	s2,0(sp)
    80004af2:	6105                	add	sp,sp,32
    80004af4:	8082                	ret
    pi->readopen = 0;
    80004af6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004afa:	21c48513          	add	a0,s1,540
    80004afe:	ffffe097          	auipc	ra,0xffffe
    80004b02:	990080e7          	jalr	-1648(ra) # 8000248e <wakeup>
    80004b06:	b7e9                	j	80004ad0 <pipeclose+0x2c>
    release(&pi->lock);
    80004b08:	8526                	mv	a0,s1
    80004b0a:	ffffc097          	auipc	ra,0xffffc
    80004b0e:	1a6080e7          	jalr	422(ra) # 80000cb0 <release>
}
    80004b12:	bfe1                	j	80004aea <pipeclose+0x46>

0000000080004b14 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b14:	711d                	add	sp,sp,-96
    80004b16:	ec86                	sd	ra,88(sp)
    80004b18:	e8a2                	sd	s0,80(sp)
    80004b1a:	e4a6                	sd	s1,72(sp)
    80004b1c:	e0ca                	sd	s2,64(sp)
    80004b1e:	fc4e                	sd	s3,56(sp)
    80004b20:	f852                	sd	s4,48(sp)
    80004b22:	f456                	sd	s5,40(sp)
    80004b24:	f05a                	sd	s6,32(sp)
    80004b26:	ec5e                	sd	s7,24(sp)
    80004b28:	1080                	add	s0,sp,96
    80004b2a:	84aa                	mv	s1,a0
    80004b2c:	8b2e                	mv	s6,a1
    80004b2e:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004b30:	ffffd097          	auipc	ra,0xffffd
    80004b34:	fc8080e7          	jalr	-56(ra) # 80001af8 <myproc>
    80004b38:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004b3a:	8526                	mv	a0,s1
    80004b3c:	ffffc097          	auipc	ra,0xffffc
    80004b40:	0c0080e7          	jalr	192(ra) # 80000bfc <acquire>
  for(i = 0; i < n; i++){
    80004b44:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004b46:	21848a13          	add	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b4a:	21c48993          	add	s3,s1,540
  for(i = 0; i < n; i++){
    80004b4e:	09505263          	blez	s5,80004bd2 <pipewrite+0xbe>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b52:	2184a783          	lw	a5,536(s1)
    80004b56:	21c4a703          	lw	a4,540(s1)
    80004b5a:	2007879b          	addw	a5,a5,512
    80004b5e:	02f71b63          	bne	a4,a5,80004b94 <pipewrite+0x80>
      if(pi->readopen == 0 || pr->killed){
    80004b62:	2204a783          	lw	a5,544(s1)
    80004b66:	c3d1                	beqz	a5,80004bea <pipewrite+0xd6>
    80004b68:	03092783          	lw	a5,48(s2)
    80004b6c:	efbd                	bnez	a5,80004bea <pipewrite+0xd6>
      wakeup(&pi->nread);
    80004b6e:	8552                	mv	a0,s4
    80004b70:	ffffe097          	auipc	ra,0xffffe
    80004b74:	91e080e7          	jalr	-1762(ra) # 8000248e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b78:	85a6                	mv	a1,s1
    80004b7a:	854e                	mv	a0,s3
    80004b7c:	ffffd097          	auipc	ra,0xffffd
    80004b80:	792080e7          	jalr	1938(ra) # 8000230e <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b84:	2184a783          	lw	a5,536(s1)
    80004b88:	21c4a703          	lw	a4,540(s1)
    80004b8c:	2007879b          	addw	a5,a5,512
    80004b90:	fcf709e3          	beq	a4,a5,80004b62 <pipewrite+0x4e>
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b94:	4685                	li	a3,1
    80004b96:	865a                	mv	a2,s6
    80004b98:	faf40593          	add	a1,s0,-81
    80004b9c:	05093503          	ld	a0,80(s2)
    80004ba0:	ffffd097          	auipc	ra,0xffffd
    80004ba4:	cda080e7          	jalr	-806(ra) # 8000187a <copyin>
    80004ba8:	57fd                	li	a5,-1
    80004baa:	02f50463          	beq	a0,a5,80004bd2 <pipewrite+0xbe>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bae:	21c4a783          	lw	a5,540(s1)
    80004bb2:	0017871b          	addw	a4,a5,1
    80004bb6:	20e4ae23          	sw	a4,540(s1)
    80004bba:	1ff7f793          	and	a5,a5,511
    80004bbe:	97a6                	add	a5,a5,s1
    80004bc0:	faf44703          	lbu	a4,-81(s0)
    80004bc4:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004bc8:	2b85                	addw	s7,s7,1
    80004bca:	0b05                	add	s6,s6,1
    80004bcc:	f97a93e3          	bne	s5,s7,80004b52 <pipewrite+0x3e>
    80004bd0:	8bd6                	mv	s7,s5
  }
  wakeup(&pi->nread);
    80004bd2:	21848513          	add	a0,s1,536
    80004bd6:	ffffe097          	auipc	ra,0xffffe
    80004bda:	8b8080e7          	jalr	-1864(ra) # 8000248e <wakeup>
  release(&pi->lock);
    80004bde:	8526                	mv	a0,s1
    80004be0:	ffffc097          	auipc	ra,0xffffc
    80004be4:	0d0080e7          	jalr	208(ra) # 80000cb0 <release>
  return i;
    80004be8:	a039                	j	80004bf6 <pipewrite+0xe2>
        release(&pi->lock);
    80004bea:	8526                	mv	a0,s1
    80004bec:	ffffc097          	auipc	ra,0xffffc
    80004bf0:	0c4080e7          	jalr	196(ra) # 80000cb0 <release>
        return -1;
    80004bf4:	5bfd                	li	s7,-1
}
    80004bf6:	855e                	mv	a0,s7
    80004bf8:	60e6                	ld	ra,88(sp)
    80004bfa:	6446                	ld	s0,80(sp)
    80004bfc:	64a6                	ld	s1,72(sp)
    80004bfe:	6906                	ld	s2,64(sp)
    80004c00:	79e2                	ld	s3,56(sp)
    80004c02:	7a42                	ld	s4,48(sp)
    80004c04:	7aa2                	ld	s5,40(sp)
    80004c06:	7b02                	ld	s6,32(sp)
    80004c08:	6be2                	ld	s7,24(sp)
    80004c0a:	6125                	add	sp,sp,96
    80004c0c:	8082                	ret

0000000080004c0e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c0e:	715d                	add	sp,sp,-80
    80004c10:	e486                	sd	ra,72(sp)
    80004c12:	e0a2                	sd	s0,64(sp)
    80004c14:	fc26                	sd	s1,56(sp)
    80004c16:	f84a                	sd	s2,48(sp)
    80004c18:	f44e                	sd	s3,40(sp)
    80004c1a:	f052                	sd	s4,32(sp)
    80004c1c:	ec56                	sd	s5,24(sp)
    80004c1e:	e85a                	sd	s6,16(sp)
    80004c20:	0880                	add	s0,sp,80
    80004c22:	84aa                	mv	s1,a0
    80004c24:	892e                	mv	s2,a1
    80004c26:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c28:	ffffd097          	auipc	ra,0xffffd
    80004c2c:	ed0080e7          	jalr	-304(ra) # 80001af8 <myproc>
    80004c30:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c32:	8526                	mv	a0,s1
    80004c34:	ffffc097          	auipc	ra,0xffffc
    80004c38:	fc8080e7          	jalr	-56(ra) # 80000bfc <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c3c:	2184a703          	lw	a4,536(s1)
    80004c40:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c44:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c48:	02f71463          	bne	a4,a5,80004c70 <piperead+0x62>
    80004c4c:	2244a783          	lw	a5,548(s1)
    80004c50:	c385                	beqz	a5,80004c70 <piperead+0x62>
    if(pr->killed){
    80004c52:	030a2783          	lw	a5,48(s4)
    80004c56:	ebc9                	bnez	a5,80004ce8 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c58:	85a6                	mv	a1,s1
    80004c5a:	854e                	mv	a0,s3
    80004c5c:	ffffd097          	auipc	ra,0xffffd
    80004c60:	6b2080e7          	jalr	1714(ra) # 8000230e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c64:	2184a703          	lw	a4,536(s1)
    80004c68:	21c4a783          	lw	a5,540(s1)
    80004c6c:	fef700e3          	beq	a4,a5,80004c4c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c70:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c72:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c74:	05505463          	blez	s5,80004cbc <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004c78:	2184a783          	lw	a5,536(s1)
    80004c7c:	21c4a703          	lw	a4,540(s1)
    80004c80:	02f70e63          	beq	a4,a5,80004cbc <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c84:	0017871b          	addw	a4,a5,1
    80004c88:	20e4ac23          	sw	a4,536(s1)
    80004c8c:	1ff7f793          	and	a5,a5,511
    80004c90:	97a6                	add	a5,a5,s1
    80004c92:	0187c783          	lbu	a5,24(a5)
    80004c96:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c9a:	4685                	li	a3,1
    80004c9c:	fbf40613          	add	a2,s0,-65
    80004ca0:	85ca                	mv	a1,s2
    80004ca2:	050a3503          	ld	a0,80(s4)
    80004ca6:	ffffd097          	auipc	ra,0xffffd
    80004caa:	b48080e7          	jalr	-1208(ra) # 800017ee <copyout>
    80004cae:	01650763          	beq	a0,s6,80004cbc <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cb2:	2985                	addw	s3,s3,1
    80004cb4:	0905                	add	s2,s2,1
    80004cb6:	fd3a91e3          	bne	s5,s3,80004c78 <piperead+0x6a>
    80004cba:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cbc:	21c48513          	add	a0,s1,540
    80004cc0:	ffffd097          	auipc	ra,0xffffd
    80004cc4:	7ce080e7          	jalr	1998(ra) # 8000248e <wakeup>
  release(&pi->lock);
    80004cc8:	8526                	mv	a0,s1
    80004cca:	ffffc097          	auipc	ra,0xffffc
    80004cce:	fe6080e7          	jalr	-26(ra) # 80000cb0 <release>
  return i;
}
    80004cd2:	854e                	mv	a0,s3
    80004cd4:	60a6                	ld	ra,72(sp)
    80004cd6:	6406                	ld	s0,64(sp)
    80004cd8:	74e2                	ld	s1,56(sp)
    80004cda:	7942                	ld	s2,48(sp)
    80004cdc:	79a2                	ld	s3,40(sp)
    80004cde:	7a02                	ld	s4,32(sp)
    80004ce0:	6ae2                	ld	s5,24(sp)
    80004ce2:	6b42                	ld	s6,16(sp)
    80004ce4:	6161                	add	sp,sp,80
    80004ce6:	8082                	ret
      release(&pi->lock);
    80004ce8:	8526                	mv	a0,s1
    80004cea:	ffffc097          	auipc	ra,0xffffc
    80004cee:	fc6080e7          	jalr	-58(ra) # 80000cb0 <release>
      return -1;
    80004cf2:	59fd                	li	s3,-1
    80004cf4:	bff9                	j	80004cd2 <piperead+0xc4>

0000000080004cf6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004cf6:	df010113          	add	sp,sp,-528
    80004cfa:	20113423          	sd	ra,520(sp)
    80004cfe:	20813023          	sd	s0,512(sp)
    80004d02:	ffa6                	sd	s1,504(sp)
    80004d04:	fbca                	sd	s2,496(sp)
    80004d06:	f7ce                	sd	s3,488(sp)
    80004d08:	f3d2                	sd	s4,480(sp)
    80004d0a:	efd6                	sd	s5,472(sp)
    80004d0c:	ebda                	sd	s6,464(sp)
    80004d0e:	e7de                	sd	s7,456(sp)
    80004d10:	e3e2                	sd	s8,448(sp)
    80004d12:	ff66                	sd	s9,440(sp)
    80004d14:	fb6a                	sd	s10,432(sp)
    80004d16:	f76e                	sd	s11,424(sp)
    80004d18:	0c00                	add	s0,sp,528
    80004d1a:	892a                	mv	s2,a0
    80004d1c:	dea43c23          	sd	a0,-520(s0)
    80004d20:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d24:	ffffd097          	auipc	ra,0xffffd
    80004d28:	dd4080e7          	jalr	-556(ra) # 80001af8 <myproc>
    80004d2c:	84aa                	mv	s1,a0

  begin_op();
    80004d2e:	fffff097          	auipc	ra,0xfffff
    80004d32:	47c080e7          	jalr	1148(ra) # 800041aa <begin_op>

  if((ip = namei(path)) == 0){
    80004d36:	854a                	mv	a0,s2
    80004d38:	fffff097          	auipc	ra,0xfffff
    80004d3c:	282080e7          	jalr	642(ra) # 80003fba <namei>
    80004d40:	c92d                	beqz	a0,80004db2 <exec+0xbc>
    80004d42:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d44:	fffff097          	auipc	ra,0xfffff
    80004d48:	ac2080e7          	jalr	-1342(ra) # 80003806 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d4c:	04000713          	li	a4,64
    80004d50:	4681                	li	a3,0
    80004d52:	e4840613          	add	a2,s0,-440
    80004d56:	4581                	li	a1,0
    80004d58:	8552                	mv	a0,s4
    80004d5a:	fffff097          	auipc	ra,0xfffff
    80004d5e:	d60080e7          	jalr	-672(ra) # 80003aba <readi>
    80004d62:	04000793          	li	a5,64
    80004d66:	00f51a63          	bne	a0,a5,80004d7a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d6a:	e4842703          	lw	a4,-440(s0)
    80004d6e:	464c47b7          	lui	a5,0x464c4
    80004d72:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d76:	04f70463          	beq	a4,a5,80004dbe <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d7a:	8552                	mv	a0,s4
    80004d7c:	fffff097          	auipc	ra,0xfffff
    80004d80:	cec080e7          	jalr	-788(ra) # 80003a68 <iunlockput>
    end_op();
    80004d84:	fffff097          	auipc	ra,0xfffff
    80004d88:	4a0080e7          	jalr	1184(ra) # 80004224 <end_op>
  }
  return -1;
    80004d8c:	557d                	li	a0,-1
}
    80004d8e:	20813083          	ld	ra,520(sp)
    80004d92:	20013403          	ld	s0,512(sp)
    80004d96:	74fe                	ld	s1,504(sp)
    80004d98:	795e                	ld	s2,496(sp)
    80004d9a:	79be                	ld	s3,488(sp)
    80004d9c:	7a1e                	ld	s4,480(sp)
    80004d9e:	6afe                	ld	s5,472(sp)
    80004da0:	6b5e                	ld	s6,464(sp)
    80004da2:	6bbe                	ld	s7,456(sp)
    80004da4:	6c1e                	ld	s8,448(sp)
    80004da6:	7cfa                	ld	s9,440(sp)
    80004da8:	7d5a                	ld	s10,432(sp)
    80004daa:	7dba                	ld	s11,424(sp)
    80004dac:	21010113          	add	sp,sp,528
    80004db0:	8082                	ret
    end_op();
    80004db2:	fffff097          	auipc	ra,0xfffff
    80004db6:	472080e7          	jalr	1138(ra) # 80004224 <end_op>
    return -1;
    80004dba:	557d                	li	a0,-1
    80004dbc:	bfc9                	j	80004d8e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dbe:	8526                	mv	a0,s1
    80004dc0:	ffffd097          	auipc	ra,0xffffd
    80004dc4:	dfc080e7          	jalr	-516(ra) # 80001bbc <proc_pagetable>
    80004dc8:	8b2a                	mv	s6,a0
    80004dca:	d945                	beqz	a0,80004d7a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dcc:	e6842d03          	lw	s10,-408(s0)
    80004dd0:	e8045783          	lhu	a5,-384(s0)
    80004dd4:	cfe5                	beqz	a5,80004ecc <exec+0x1d6>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004dd6:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dd8:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004dda:	6c85                	lui	s9,0x1
    80004ddc:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004de0:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004de4:	6a85                	lui	s5,0x1
    80004de6:	a0b5                	j	80004e52 <exec+0x15c>
      panic("loadseg: address should exist");
    80004de8:	00004517          	auipc	a0,0x4
    80004dec:	94050513          	add	a0,a0,-1728 # 80008728 <syscalls+0x290>
    80004df0:	ffffb097          	auipc	ra,0xffffb
    80004df4:	752080e7          	jalr	1874(ra) # 80000542 <panic>
    if(sz - i < PGSIZE)
    80004df8:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dfa:	8726                	mv	a4,s1
    80004dfc:	012c06bb          	addw	a3,s8,s2
    80004e00:	4581                	li	a1,0
    80004e02:	8552                	mv	a0,s4
    80004e04:	fffff097          	auipc	ra,0xfffff
    80004e08:	cb6080e7          	jalr	-842(ra) # 80003aba <readi>
    80004e0c:	2501                	sext.w	a0,a0
    80004e0e:	24a49c63          	bne	s1,a0,80005066 <exec+0x370>
  for(i = 0; i < sz; i += PGSIZE){
    80004e12:	012a893b          	addw	s2,s5,s2
    80004e16:	03397563          	bgeu	s2,s3,80004e40 <exec+0x14a>
    pa = walkaddr(pagetable, va + i);
    80004e1a:	02091593          	sll	a1,s2,0x20
    80004e1e:	9181                	srl	a1,a1,0x20
    80004e20:	95de                	add	a1,a1,s7
    80004e22:	855a                	mv	a0,s6
    80004e24:	ffffc097          	auipc	ra,0xffffc
    80004e28:	446080e7          	jalr	1094(ra) # 8000126a <walkaddr>
    80004e2c:	862a                	mv	a2,a0
    if(pa == 0)
    80004e2e:	dd4d                	beqz	a0,80004de8 <exec+0xf2>
    if(sz - i < PGSIZE)
    80004e30:	412984bb          	subw	s1,s3,s2
    80004e34:	0004879b          	sext.w	a5,s1
    80004e38:	fcfcf0e3          	bgeu	s9,a5,80004df8 <exec+0x102>
    80004e3c:	84d6                	mv	s1,s5
    80004e3e:	bf6d                	j	80004df8 <exec+0x102>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e40:	e0843483          	ld	s1,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e44:	2d85                	addw	s11,s11,1
    80004e46:	038d0d1b          	addw	s10,s10,56
    80004e4a:	e8045783          	lhu	a5,-384(s0)
    80004e4e:	08fdd063          	bge	s11,a5,80004ece <exec+0x1d8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e52:	2d01                	sext.w	s10,s10
    80004e54:	03800713          	li	a4,56
    80004e58:	86ea                	mv	a3,s10
    80004e5a:	e1040613          	add	a2,s0,-496
    80004e5e:	4581                	li	a1,0
    80004e60:	8552                	mv	a0,s4
    80004e62:	fffff097          	auipc	ra,0xfffff
    80004e66:	c58080e7          	jalr	-936(ra) # 80003aba <readi>
    80004e6a:	03800793          	li	a5,56
    80004e6e:	1ef51a63          	bne	a0,a5,80005062 <exec+0x36c>
    if(ph.type != ELF_PROG_LOAD)
    80004e72:	e1042783          	lw	a5,-496(s0)
    80004e76:	4705                	li	a4,1
    80004e78:	fce796e3          	bne	a5,a4,80004e44 <exec+0x14e>
    if(ph.memsz < ph.filesz)
    80004e7c:	e3843603          	ld	a2,-456(s0)
    80004e80:	e3043783          	ld	a5,-464(s0)
    80004e84:	1ef66c63          	bltu	a2,a5,8000507c <exec+0x386>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004e88:	e2043783          	ld	a5,-480(s0)
    80004e8c:	963e                	add	a2,a2,a5
    80004e8e:	1ef66a63          	bltu	a2,a5,80005082 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e92:	85a6                	mv	a1,s1
    80004e94:	855a                	mv	a0,s6
    80004e96:	ffffc097          	auipc	ra,0xffffc
    80004e9a:	720080e7          	jalr	1824(ra) # 800015b6 <uvmalloc>
    80004e9e:	e0a43423          	sd	a0,-504(s0)
    80004ea2:	1e050363          	beqz	a0,80005088 <exec+0x392>
    if(ph.vaddr % PGSIZE != 0)
    80004ea6:	e2043b83          	ld	s7,-480(s0)
    80004eaa:	df043783          	ld	a5,-528(s0)
    80004eae:	00fbf7b3          	and	a5,s7,a5
    80004eb2:	1a079a63          	bnez	a5,80005066 <exec+0x370>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004eb6:	e1842c03          	lw	s8,-488(s0)
    80004eba:	e3042983          	lw	s3,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004ebe:	00098463          	beqz	s3,80004ec6 <exec+0x1d0>
    80004ec2:	4901                	li	s2,0
    80004ec4:	bf99                	j	80004e1a <exec+0x124>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004ec6:	e0843483          	ld	s1,-504(s0)
    80004eca:	bfad                	j	80004e44 <exec+0x14e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004ecc:	4481                	li	s1,0
  iunlockput(ip);
    80004ece:	8552                	mv	a0,s4
    80004ed0:	fffff097          	auipc	ra,0xfffff
    80004ed4:	b98080e7          	jalr	-1128(ra) # 80003a68 <iunlockput>
  end_op();
    80004ed8:	fffff097          	auipc	ra,0xfffff
    80004edc:	34c080e7          	jalr	844(ra) # 80004224 <end_op>
  p = myproc();
    80004ee0:	ffffd097          	auipc	ra,0xffffd
    80004ee4:	c18080e7          	jalr	-1000(ra) # 80001af8 <myproc>
    80004ee8:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004eea:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004eee:	6985                	lui	s3,0x1
    80004ef0:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004ef2:	99a6                	add	s3,s3,s1
    80004ef4:	77fd                	lui	a5,0xfffff
    80004ef6:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004efa:	6609                	lui	a2,0x2
    80004efc:	964e                	add	a2,a2,s3
    80004efe:	85ce                	mv	a1,s3
    80004f00:	855a                	mv	a0,s6
    80004f02:	ffffc097          	auipc	ra,0xffffc
    80004f06:	6b4080e7          	jalr	1716(ra) # 800015b6 <uvmalloc>
    80004f0a:	892a                	mv	s2,a0
    80004f0c:	e0a43423          	sd	a0,-504(s0)
    80004f10:	e509                	bnez	a0,80004f1a <exec+0x224>
  if(pagetable)
    80004f12:	e1343423          	sd	s3,-504(s0)
    80004f16:	4a01                	li	s4,0
    80004f18:	a2b9                	j	80005066 <exec+0x370>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f1a:	75f9                	lui	a1,0xffffe
    80004f1c:	95aa                	add	a1,a1,a0
    80004f1e:	855a                	mv	a0,s6
    80004f20:	ffffd097          	auipc	ra,0xffffd
    80004f24:	89c080e7          	jalr	-1892(ra) # 800017bc <uvmclear>
  stackbase = sp - PGSIZE;
    80004f28:	7bfd                	lui	s7,0xfffff
    80004f2a:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004f2c:	e0043783          	ld	a5,-512(s0)
    80004f30:	6388                	ld	a0,0(a5)
    80004f32:	c52d                	beqz	a0,80004f9c <exec+0x2a6>
    80004f34:	e8840993          	add	s3,s0,-376
    80004f38:	f8840c13          	add	s8,s0,-120
    80004f3c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004f3e:	ffffc097          	auipc	ra,0xffffc
    80004f42:	f3c080e7          	jalr	-196(ra) # 80000e7a <strlen>
    80004f46:	0015079b          	addw	a5,a0,1
    80004f4a:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f4e:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    80004f52:	13796e63          	bltu	s2,s7,8000508e <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f56:	e0043d03          	ld	s10,-512(s0)
    80004f5a:	000d3a03          	ld	s4,0(s10)
    80004f5e:	8552                	mv	a0,s4
    80004f60:	ffffc097          	auipc	ra,0xffffc
    80004f64:	f1a080e7          	jalr	-230(ra) # 80000e7a <strlen>
    80004f68:	0015069b          	addw	a3,a0,1
    80004f6c:	8652                	mv	a2,s4
    80004f6e:	85ca                	mv	a1,s2
    80004f70:	855a                	mv	a0,s6
    80004f72:	ffffd097          	auipc	ra,0xffffd
    80004f76:	87c080e7          	jalr	-1924(ra) # 800017ee <copyout>
    80004f7a:	10054c63          	bltz	a0,80005092 <exec+0x39c>
    ustack[argc] = sp;
    80004f7e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f82:	0485                	add	s1,s1,1
    80004f84:	008d0793          	add	a5,s10,8
    80004f88:	e0f43023          	sd	a5,-512(s0)
    80004f8c:	008d3503          	ld	a0,8(s10)
    80004f90:	c909                	beqz	a0,80004fa2 <exec+0x2ac>
    if(argc >= MAXARG)
    80004f92:	09a1                	add	s3,s3,8
    80004f94:	fb8995e3          	bne	s3,s8,80004f3e <exec+0x248>
  ip = 0;
    80004f98:	4a01                	li	s4,0
    80004f9a:	a0f1                	j	80005066 <exec+0x370>
  sp = sz;
    80004f9c:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004fa0:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fa2:	00349793          	sll	a5,s1,0x3
    80004fa6:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffd8f90>
    80004faa:	97a2                	add	a5,a5,s0
    80004fac:	ee07bc23          	sd	zero,-264(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004fb0:	00148693          	add	a3,s1,1
    80004fb4:	068e                	sll	a3,a3,0x3
    80004fb6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fba:	ff097913          	and	s2,s2,-16
  sz = sz1;
    80004fbe:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004fc2:	f57968e3          	bltu	s2,s7,80004f12 <exec+0x21c>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fc6:	e8840613          	add	a2,s0,-376
    80004fca:	85ca                	mv	a1,s2
    80004fcc:	855a                	mv	a0,s6
    80004fce:	ffffd097          	auipc	ra,0xffffd
    80004fd2:	820080e7          	jalr	-2016(ra) # 800017ee <copyout>
    80004fd6:	0c054063          	bltz	a0,80005096 <exec+0x3a0>
  p->trapframe->a1 = sp;
    80004fda:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004fde:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fe2:	df843783          	ld	a5,-520(s0)
    80004fe6:	0007c703          	lbu	a4,0(a5)
    80004fea:	cf11                	beqz	a4,80005006 <exec+0x310>
    80004fec:	0785                	add	a5,a5,1
    if(*s == '/')
    80004fee:	02f00693          	li	a3,47
    80004ff2:	a039                	j	80005000 <exec+0x30a>
      last = s+1;
    80004ff4:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004ff8:	0785                	add	a5,a5,1
    80004ffa:	fff7c703          	lbu	a4,-1(a5)
    80004ffe:	c701                	beqz	a4,80005006 <exec+0x310>
    if(*s == '/')
    80005000:	fed71ce3          	bne	a4,a3,80004ff8 <exec+0x302>
    80005004:	bfc5                	j	80004ff4 <exec+0x2fe>
  safestrcpy(p->name, last, sizeof(p->name));
    80005006:	4641                	li	a2,16
    80005008:	df843583          	ld	a1,-520(s0)
    8000500c:	158a8513          	add	a0,s5,344
    80005010:	ffffc097          	auipc	ra,0xffffc
    80005014:	e38080e7          	jalr	-456(ra) # 80000e48 <safestrcpy>
  oldpagetable = p->pagetable;
    80005018:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000501c:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80005020:	e0843783          	ld	a5,-504(s0)
    80005024:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005028:	058ab783          	ld	a5,88(s5)
    8000502c:	e6043703          	ld	a4,-416(s0)
    80005030:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005032:	058ab783          	ld	a5,88(s5)
    80005036:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000503a:	85e6                	mv	a1,s9
    8000503c:	ffffd097          	auipc	ra,0xffffd
    80005040:	c1c080e7          	jalr	-996(ra) # 80001c58 <proc_freepagetable>
  if(p->pid==1) vmprint(p->pagetable);
    80005044:	038aa703          	lw	a4,56(s5)
    80005048:	4785                	li	a5,1
    8000504a:	00f70563          	beq	a4,a5,80005054 <exec+0x35e>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000504e:	0004851b          	sext.w	a0,s1
    80005052:	bb35                	j	80004d8e <exec+0x98>
  if(p->pid==1) vmprint(p->pagetable);
    80005054:	050ab503          	ld	a0,80(s5)
    80005058:	ffffc097          	auipc	ra,0xffffc
    8000505c:	028080e7          	jalr	40(ra) # 80001080 <vmprint>
    80005060:	b7fd                	j	8000504e <exec+0x358>
    80005062:	e0943423          	sd	s1,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005066:	e0843583          	ld	a1,-504(s0)
    8000506a:	855a                	mv	a0,s6
    8000506c:	ffffd097          	auipc	ra,0xffffd
    80005070:	bec080e7          	jalr	-1044(ra) # 80001c58 <proc_freepagetable>
  return -1;
    80005074:	557d                	li	a0,-1
  if(ip){
    80005076:	d00a0ce3          	beqz	s4,80004d8e <exec+0x98>
    8000507a:	b301                	j	80004d7a <exec+0x84>
    8000507c:	e0943423          	sd	s1,-504(s0)
    80005080:	b7dd                	j	80005066 <exec+0x370>
    80005082:	e0943423          	sd	s1,-504(s0)
    80005086:	b7c5                	j	80005066 <exec+0x370>
    80005088:	e0943423          	sd	s1,-504(s0)
    8000508c:	bfe9                	j	80005066 <exec+0x370>
  ip = 0;
    8000508e:	4a01                	li	s4,0
    80005090:	bfd9                	j	80005066 <exec+0x370>
    80005092:	4a01                	li	s4,0
  if(pagetable)
    80005094:	bfc9                	j	80005066 <exec+0x370>
  sz = sz1;
    80005096:	e0843983          	ld	s3,-504(s0)
    8000509a:	bda5                	j	80004f12 <exec+0x21c>

000000008000509c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000509c:	7179                	add	sp,sp,-48
    8000509e:	f406                	sd	ra,40(sp)
    800050a0:	f022                	sd	s0,32(sp)
    800050a2:	ec26                	sd	s1,24(sp)
    800050a4:	e84a                	sd	s2,16(sp)
    800050a6:	1800                	add	s0,sp,48
    800050a8:	892e                	mv	s2,a1
    800050aa:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050ac:	fdc40593          	add	a1,s0,-36
    800050b0:	ffffe097          	auipc	ra,0xffffe
    800050b4:	bc2080e7          	jalr	-1086(ra) # 80002c72 <argint>
    800050b8:	04054063          	bltz	a0,800050f8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050bc:	fdc42703          	lw	a4,-36(s0)
    800050c0:	47bd                	li	a5,15
    800050c2:	02e7ed63          	bltu	a5,a4,800050fc <argfd+0x60>
    800050c6:	ffffd097          	auipc	ra,0xffffd
    800050ca:	a32080e7          	jalr	-1486(ra) # 80001af8 <myproc>
    800050ce:	fdc42703          	lw	a4,-36(s0)
    800050d2:	01a70793          	add	a5,a4,26
    800050d6:	078e                	sll	a5,a5,0x3
    800050d8:	953e                	add	a0,a0,a5
    800050da:	611c                	ld	a5,0(a0)
    800050dc:	c395                	beqz	a5,80005100 <argfd+0x64>
    return -1;
  if(pfd)
    800050de:	00090463          	beqz	s2,800050e6 <argfd+0x4a>
    *pfd = fd;
    800050e2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050e6:	4501                	li	a0,0
  if(pf)
    800050e8:	c091                	beqz	s1,800050ec <argfd+0x50>
    *pf = f;
    800050ea:	e09c                	sd	a5,0(s1)
}
    800050ec:	70a2                	ld	ra,40(sp)
    800050ee:	7402                	ld	s0,32(sp)
    800050f0:	64e2                	ld	s1,24(sp)
    800050f2:	6942                	ld	s2,16(sp)
    800050f4:	6145                	add	sp,sp,48
    800050f6:	8082                	ret
    return -1;
    800050f8:	557d                	li	a0,-1
    800050fa:	bfcd                	j	800050ec <argfd+0x50>
    return -1;
    800050fc:	557d                	li	a0,-1
    800050fe:	b7fd                	j	800050ec <argfd+0x50>
    80005100:	557d                	li	a0,-1
    80005102:	b7ed                	j	800050ec <argfd+0x50>

0000000080005104 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005104:	1101                	add	sp,sp,-32
    80005106:	ec06                	sd	ra,24(sp)
    80005108:	e822                	sd	s0,16(sp)
    8000510a:	e426                	sd	s1,8(sp)
    8000510c:	1000                	add	s0,sp,32
    8000510e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005110:	ffffd097          	auipc	ra,0xffffd
    80005114:	9e8080e7          	jalr	-1560(ra) # 80001af8 <myproc>
    80005118:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000511a:	0d050793          	add	a5,a0,208
    8000511e:	4501                	li	a0,0
    80005120:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005122:	6398                	ld	a4,0(a5)
    80005124:	cb19                	beqz	a4,8000513a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005126:	2505                	addw	a0,a0,1
    80005128:	07a1                	add	a5,a5,8
    8000512a:	fed51ce3          	bne	a0,a3,80005122 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000512e:	557d                	li	a0,-1
}
    80005130:	60e2                	ld	ra,24(sp)
    80005132:	6442                	ld	s0,16(sp)
    80005134:	64a2                	ld	s1,8(sp)
    80005136:	6105                	add	sp,sp,32
    80005138:	8082                	ret
      p->ofile[fd] = f;
    8000513a:	01a50793          	add	a5,a0,26
    8000513e:	078e                	sll	a5,a5,0x3
    80005140:	963e                	add	a2,a2,a5
    80005142:	e204                	sd	s1,0(a2)
      return fd;
    80005144:	b7f5                	j	80005130 <fdalloc+0x2c>

0000000080005146 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005146:	715d                	add	sp,sp,-80
    80005148:	e486                	sd	ra,72(sp)
    8000514a:	e0a2                	sd	s0,64(sp)
    8000514c:	fc26                	sd	s1,56(sp)
    8000514e:	f84a                	sd	s2,48(sp)
    80005150:	f44e                	sd	s3,40(sp)
    80005152:	f052                	sd	s4,32(sp)
    80005154:	ec56                	sd	s5,24(sp)
    80005156:	0880                	add	s0,sp,80
    80005158:	8aae                	mv	s5,a1
    8000515a:	8a32                	mv	s4,a2
    8000515c:	89b6                	mv	s3,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000515e:	fb040593          	add	a1,s0,-80
    80005162:	fffff097          	auipc	ra,0xfffff
    80005166:	e76080e7          	jalr	-394(ra) # 80003fd8 <nameiparent>
    8000516a:	892a                	mv	s2,a0
    8000516c:	12050c63          	beqz	a0,800052a4 <create+0x15e>
    return 0;

  ilock(dp);
    80005170:	ffffe097          	auipc	ra,0xffffe
    80005174:	696080e7          	jalr	1686(ra) # 80003806 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005178:	4601                	li	a2,0
    8000517a:	fb040593          	add	a1,s0,-80
    8000517e:	854a                	mv	a0,s2
    80005180:	fffff097          	auipc	ra,0xfffff
    80005184:	b68080e7          	jalr	-1176(ra) # 80003ce8 <dirlookup>
    80005188:	84aa                	mv	s1,a0
    8000518a:	c539                	beqz	a0,800051d8 <create+0x92>
    iunlockput(dp);
    8000518c:	854a                	mv	a0,s2
    8000518e:	fffff097          	auipc	ra,0xfffff
    80005192:	8da080e7          	jalr	-1830(ra) # 80003a68 <iunlockput>
    ilock(ip);
    80005196:	8526                	mv	a0,s1
    80005198:	ffffe097          	auipc	ra,0xffffe
    8000519c:	66e080e7          	jalr	1646(ra) # 80003806 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051a0:	4789                	li	a5,2
    800051a2:	02fa9463          	bne	s5,a5,800051ca <create+0x84>
    800051a6:	0444d783          	lhu	a5,68(s1)
    800051aa:	37f9                	addw	a5,a5,-2
    800051ac:	17c2                	sll	a5,a5,0x30
    800051ae:	93c1                	srl	a5,a5,0x30
    800051b0:	4705                	li	a4,1
    800051b2:	00f76c63          	bltu	a4,a5,800051ca <create+0x84>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051b6:	8526                	mv	a0,s1
    800051b8:	60a6                	ld	ra,72(sp)
    800051ba:	6406                	ld	s0,64(sp)
    800051bc:	74e2                	ld	s1,56(sp)
    800051be:	7942                	ld	s2,48(sp)
    800051c0:	79a2                	ld	s3,40(sp)
    800051c2:	7a02                	ld	s4,32(sp)
    800051c4:	6ae2                	ld	s5,24(sp)
    800051c6:	6161                	add	sp,sp,80
    800051c8:	8082                	ret
    iunlockput(ip);
    800051ca:	8526                	mv	a0,s1
    800051cc:	fffff097          	auipc	ra,0xfffff
    800051d0:	89c080e7          	jalr	-1892(ra) # 80003a68 <iunlockput>
    return 0;
    800051d4:	4481                	li	s1,0
    800051d6:	b7c5                	j	800051b6 <create+0x70>
  if((ip = ialloc(dp->dev, type)) == 0)
    800051d8:	85d6                	mv	a1,s5
    800051da:	00092503          	lw	a0,0(s2)
    800051de:	ffffe097          	auipc	ra,0xffffe
    800051e2:	494080e7          	jalr	1172(ra) # 80003672 <ialloc>
    800051e6:	84aa                	mv	s1,a0
    800051e8:	c139                	beqz	a0,8000522e <create+0xe8>
  ilock(ip);
    800051ea:	ffffe097          	auipc	ra,0xffffe
    800051ee:	61c080e7          	jalr	1564(ra) # 80003806 <ilock>
  ip->major = major;
    800051f2:	05449323          	sh	s4,70(s1)
  ip->minor = minor;
    800051f6:	05349423          	sh	s3,72(s1)
  ip->nlink = 1;
    800051fa:	4985                	li	s3,1
    800051fc:	05349523          	sh	s3,74(s1)
  iupdate(ip);
    80005200:	8526                	mv	a0,s1
    80005202:	ffffe097          	auipc	ra,0xffffe
    80005206:	538080e7          	jalr	1336(ra) # 8000373a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000520a:	033a8a63          	beq	s5,s3,8000523e <create+0xf8>
  if(dirlink(dp, name, ip->inum) < 0)
    8000520e:	40d0                	lw	a2,4(s1)
    80005210:	fb040593          	add	a1,s0,-80
    80005214:	854a                	mv	a0,s2
    80005216:	fffff097          	auipc	ra,0xfffff
    8000521a:	ce2080e7          	jalr	-798(ra) # 80003ef8 <dirlink>
    8000521e:	06054b63          	bltz	a0,80005294 <create+0x14e>
  iunlockput(dp);
    80005222:	854a                	mv	a0,s2
    80005224:	fffff097          	auipc	ra,0xfffff
    80005228:	844080e7          	jalr	-1980(ra) # 80003a68 <iunlockput>
  return ip;
    8000522c:	b769                	j	800051b6 <create+0x70>
    panic("create: ialloc");
    8000522e:	00003517          	auipc	a0,0x3
    80005232:	51a50513          	add	a0,a0,1306 # 80008748 <syscalls+0x2b0>
    80005236:	ffffb097          	auipc	ra,0xffffb
    8000523a:	30c080e7          	jalr	780(ra) # 80000542 <panic>
    dp->nlink++;  // for ".."
    8000523e:	04a95783          	lhu	a5,74(s2)
    80005242:	2785                	addw	a5,a5,1
    80005244:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005248:	854a                	mv	a0,s2
    8000524a:	ffffe097          	auipc	ra,0xffffe
    8000524e:	4f0080e7          	jalr	1264(ra) # 8000373a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005252:	40d0                	lw	a2,4(s1)
    80005254:	00003597          	auipc	a1,0x3
    80005258:	50458593          	add	a1,a1,1284 # 80008758 <syscalls+0x2c0>
    8000525c:	8526                	mv	a0,s1
    8000525e:	fffff097          	auipc	ra,0xfffff
    80005262:	c9a080e7          	jalr	-870(ra) # 80003ef8 <dirlink>
    80005266:	00054f63          	bltz	a0,80005284 <create+0x13e>
    8000526a:	00492603          	lw	a2,4(s2)
    8000526e:	00003597          	auipc	a1,0x3
    80005272:	e6258593          	add	a1,a1,-414 # 800080d0 <digits+0x90>
    80005276:	8526                	mv	a0,s1
    80005278:	fffff097          	auipc	ra,0xfffff
    8000527c:	c80080e7          	jalr	-896(ra) # 80003ef8 <dirlink>
    80005280:	f80557e3          	bgez	a0,8000520e <create+0xc8>
      panic("create dots");
    80005284:	00003517          	auipc	a0,0x3
    80005288:	4dc50513          	add	a0,a0,1244 # 80008760 <syscalls+0x2c8>
    8000528c:	ffffb097          	auipc	ra,0xffffb
    80005290:	2b6080e7          	jalr	694(ra) # 80000542 <panic>
    panic("create: dirlink");
    80005294:	00003517          	auipc	a0,0x3
    80005298:	4dc50513          	add	a0,a0,1244 # 80008770 <syscalls+0x2d8>
    8000529c:	ffffb097          	auipc	ra,0xffffb
    800052a0:	2a6080e7          	jalr	678(ra) # 80000542 <panic>
    return 0;
    800052a4:	84aa                	mv	s1,a0
    800052a6:	bf01                	j	800051b6 <create+0x70>

00000000800052a8 <sys_dup>:
{
    800052a8:	7179                	add	sp,sp,-48
    800052aa:	f406                	sd	ra,40(sp)
    800052ac:	f022                	sd	s0,32(sp)
    800052ae:	ec26                	sd	s1,24(sp)
    800052b0:	e84a                	sd	s2,16(sp)
    800052b2:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052b4:	fd840613          	add	a2,s0,-40
    800052b8:	4581                	li	a1,0
    800052ba:	4501                	li	a0,0
    800052bc:	00000097          	auipc	ra,0x0
    800052c0:	de0080e7          	jalr	-544(ra) # 8000509c <argfd>
    return -1;
    800052c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052c6:	02054363          	bltz	a0,800052ec <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800052ca:	fd843903          	ld	s2,-40(s0)
    800052ce:	854a                	mv	a0,s2
    800052d0:	00000097          	auipc	ra,0x0
    800052d4:	e34080e7          	jalr	-460(ra) # 80005104 <fdalloc>
    800052d8:	84aa                	mv	s1,a0
    return -1;
    800052da:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052dc:	00054863          	bltz	a0,800052ec <sys_dup+0x44>
  filedup(f);
    800052e0:	854a                	mv	a0,s2
    800052e2:	fffff097          	auipc	ra,0xfffff
    800052e6:	340080e7          	jalr	832(ra) # 80004622 <filedup>
  return fd;
    800052ea:	87a6                	mv	a5,s1
}
    800052ec:	853e                	mv	a0,a5
    800052ee:	70a2                	ld	ra,40(sp)
    800052f0:	7402                	ld	s0,32(sp)
    800052f2:	64e2                	ld	s1,24(sp)
    800052f4:	6942                	ld	s2,16(sp)
    800052f6:	6145                	add	sp,sp,48
    800052f8:	8082                	ret

00000000800052fa <sys_read>:
{
    800052fa:	7179                	add	sp,sp,-48
    800052fc:	f406                	sd	ra,40(sp)
    800052fe:	f022                	sd	s0,32(sp)
    80005300:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005302:	fe840613          	add	a2,s0,-24
    80005306:	4581                	li	a1,0
    80005308:	4501                	li	a0,0
    8000530a:	00000097          	auipc	ra,0x0
    8000530e:	d92080e7          	jalr	-622(ra) # 8000509c <argfd>
    return -1;
    80005312:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005314:	04054163          	bltz	a0,80005356 <sys_read+0x5c>
    80005318:	fe440593          	add	a1,s0,-28
    8000531c:	4509                	li	a0,2
    8000531e:	ffffe097          	auipc	ra,0xffffe
    80005322:	954080e7          	jalr	-1708(ra) # 80002c72 <argint>
    return -1;
    80005326:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005328:	02054763          	bltz	a0,80005356 <sys_read+0x5c>
    8000532c:	fd840593          	add	a1,s0,-40
    80005330:	4505                	li	a0,1
    80005332:	ffffe097          	auipc	ra,0xffffe
    80005336:	962080e7          	jalr	-1694(ra) # 80002c94 <argaddr>
    return -1;
    8000533a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000533c:	00054d63          	bltz	a0,80005356 <sys_read+0x5c>
  return fileread(f, p, n);
    80005340:	fe442603          	lw	a2,-28(s0)
    80005344:	fd843583          	ld	a1,-40(s0)
    80005348:	fe843503          	ld	a0,-24(s0)
    8000534c:	fffff097          	auipc	ra,0xfffff
    80005350:	462080e7          	jalr	1122(ra) # 800047ae <fileread>
    80005354:	87aa                	mv	a5,a0
}
    80005356:	853e                	mv	a0,a5
    80005358:	70a2                	ld	ra,40(sp)
    8000535a:	7402                	ld	s0,32(sp)
    8000535c:	6145                	add	sp,sp,48
    8000535e:	8082                	ret

0000000080005360 <sys_write>:
{
    80005360:	7179                	add	sp,sp,-48
    80005362:	f406                	sd	ra,40(sp)
    80005364:	f022                	sd	s0,32(sp)
    80005366:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005368:	fe840613          	add	a2,s0,-24
    8000536c:	4581                	li	a1,0
    8000536e:	4501                	li	a0,0
    80005370:	00000097          	auipc	ra,0x0
    80005374:	d2c080e7          	jalr	-724(ra) # 8000509c <argfd>
    return -1;
    80005378:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000537a:	04054163          	bltz	a0,800053bc <sys_write+0x5c>
    8000537e:	fe440593          	add	a1,s0,-28
    80005382:	4509                	li	a0,2
    80005384:	ffffe097          	auipc	ra,0xffffe
    80005388:	8ee080e7          	jalr	-1810(ra) # 80002c72 <argint>
    return -1;
    8000538c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000538e:	02054763          	bltz	a0,800053bc <sys_write+0x5c>
    80005392:	fd840593          	add	a1,s0,-40
    80005396:	4505                	li	a0,1
    80005398:	ffffe097          	auipc	ra,0xffffe
    8000539c:	8fc080e7          	jalr	-1796(ra) # 80002c94 <argaddr>
    return -1;
    800053a0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053a2:	00054d63          	bltz	a0,800053bc <sys_write+0x5c>
  return filewrite(f, p, n);
    800053a6:	fe442603          	lw	a2,-28(s0)
    800053aa:	fd843583          	ld	a1,-40(s0)
    800053ae:	fe843503          	ld	a0,-24(s0)
    800053b2:	fffff097          	auipc	ra,0xfffff
    800053b6:	4be080e7          	jalr	1214(ra) # 80004870 <filewrite>
    800053ba:	87aa                	mv	a5,a0
}
    800053bc:	853e                	mv	a0,a5
    800053be:	70a2                	ld	ra,40(sp)
    800053c0:	7402                	ld	s0,32(sp)
    800053c2:	6145                	add	sp,sp,48
    800053c4:	8082                	ret

00000000800053c6 <sys_close>:
{
    800053c6:	1101                	add	sp,sp,-32
    800053c8:	ec06                	sd	ra,24(sp)
    800053ca:	e822                	sd	s0,16(sp)
    800053cc:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053ce:	fe040613          	add	a2,s0,-32
    800053d2:	fec40593          	add	a1,s0,-20
    800053d6:	4501                	li	a0,0
    800053d8:	00000097          	auipc	ra,0x0
    800053dc:	cc4080e7          	jalr	-828(ra) # 8000509c <argfd>
    return -1;
    800053e0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053e2:	02054463          	bltz	a0,8000540a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053e6:	ffffc097          	auipc	ra,0xffffc
    800053ea:	712080e7          	jalr	1810(ra) # 80001af8 <myproc>
    800053ee:	fec42783          	lw	a5,-20(s0)
    800053f2:	07e9                	add	a5,a5,26
    800053f4:	078e                	sll	a5,a5,0x3
    800053f6:	953e                	add	a0,a0,a5
    800053f8:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800053fc:	fe043503          	ld	a0,-32(s0)
    80005400:	fffff097          	auipc	ra,0xfffff
    80005404:	274080e7          	jalr	628(ra) # 80004674 <fileclose>
  return 0;
    80005408:	4781                	li	a5,0
}
    8000540a:	853e                	mv	a0,a5
    8000540c:	60e2                	ld	ra,24(sp)
    8000540e:	6442                	ld	s0,16(sp)
    80005410:	6105                	add	sp,sp,32
    80005412:	8082                	ret

0000000080005414 <sys_fstat>:
{
    80005414:	1101                	add	sp,sp,-32
    80005416:	ec06                	sd	ra,24(sp)
    80005418:	e822                	sd	s0,16(sp)
    8000541a:	1000                	add	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000541c:	fe840613          	add	a2,s0,-24
    80005420:	4581                	li	a1,0
    80005422:	4501                	li	a0,0
    80005424:	00000097          	auipc	ra,0x0
    80005428:	c78080e7          	jalr	-904(ra) # 8000509c <argfd>
    return -1;
    8000542c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000542e:	02054563          	bltz	a0,80005458 <sys_fstat+0x44>
    80005432:	fe040593          	add	a1,s0,-32
    80005436:	4505                	li	a0,1
    80005438:	ffffe097          	auipc	ra,0xffffe
    8000543c:	85c080e7          	jalr	-1956(ra) # 80002c94 <argaddr>
    return -1;
    80005440:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005442:	00054b63          	bltz	a0,80005458 <sys_fstat+0x44>
  return filestat(f, st);
    80005446:	fe043583          	ld	a1,-32(s0)
    8000544a:	fe843503          	ld	a0,-24(s0)
    8000544e:	fffff097          	auipc	ra,0xfffff
    80005452:	2ee080e7          	jalr	750(ra) # 8000473c <filestat>
    80005456:	87aa                	mv	a5,a0
}
    80005458:	853e                	mv	a0,a5
    8000545a:	60e2                	ld	ra,24(sp)
    8000545c:	6442                	ld	s0,16(sp)
    8000545e:	6105                	add	sp,sp,32
    80005460:	8082                	ret

0000000080005462 <sys_link>:
{
    80005462:	7169                	add	sp,sp,-304
    80005464:	f606                	sd	ra,296(sp)
    80005466:	f222                	sd	s0,288(sp)
    80005468:	ee26                	sd	s1,280(sp)
    8000546a:	ea4a                	sd	s2,272(sp)
    8000546c:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000546e:	08000613          	li	a2,128
    80005472:	ed040593          	add	a1,s0,-304
    80005476:	4501                	li	a0,0
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	83e080e7          	jalr	-1986(ra) # 80002cb6 <argstr>
    return -1;
    80005480:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005482:	10054e63          	bltz	a0,8000559e <sys_link+0x13c>
    80005486:	08000613          	li	a2,128
    8000548a:	f5040593          	add	a1,s0,-176
    8000548e:	4505                	li	a0,1
    80005490:	ffffe097          	auipc	ra,0xffffe
    80005494:	826080e7          	jalr	-2010(ra) # 80002cb6 <argstr>
    return -1;
    80005498:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000549a:	10054263          	bltz	a0,8000559e <sys_link+0x13c>
  begin_op();
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	d0c080e7          	jalr	-756(ra) # 800041aa <begin_op>
  if((ip = namei(old)) == 0){
    800054a6:	ed040513          	add	a0,s0,-304
    800054aa:	fffff097          	auipc	ra,0xfffff
    800054ae:	b10080e7          	jalr	-1264(ra) # 80003fba <namei>
    800054b2:	84aa                	mv	s1,a0
    800054b4:	c551                	beqz	a0,80005540 <sys_link+0xde>
  ilock(ip);
    800054b6:	ffffe097          	auipc	ra,0xffffe
    800054ba:	350080e7          	jalr	848(ra) # 80003806 <ilock>
  if(ip->type == T_DIR){
    800054be:	04449703          	lh	a4,68(s1)
    800054c2:	4785                	li	a5,1
    800054c4:	08f70463          	beq	a4,a5,8000554c <sys_link+0xea>
  ip->nlink++;
    800054c8:	04a4d783          	lhu	a5,74(s1)
    800054cc:	2785                	addw	a5,a5,1
    800054ce:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054d2:	8526                	mv	a0,s1
    800054d4:	ffffe097          	auipc	ra,0xffffe
    800054d8:	266080e7          	jalr	614(ra) # 8000373a <iupdate>
  iunlock(ip);
    800054dc:	8526                	mv	a0,s1
    800054de:	ffffe097          	auipc	ra,0xffffe
    800054e2:	3ea080e7          	jalr	1002(ra) # 800038c8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054e6:	fd040593          	add	a1,s0,-48
    800054ea:	f5040513          	add	a0,s0,-176
    800054ee:	fffff097          	auipc	ra,0xfffff
    800054f2:	aea080e7          	jalr	-1302(ra) # 80003fd8 <nameiparent>
    800054f6:	892a                	mv	s2,a0
    800054f8:	c935                	beqz	a0,8000556c <sys_link+0x10a>
  ilock(dp);
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	30c080e7          	jalr	780(ra) # 80003806 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005502:	00092703          	lw	a4,0(s2)
    80005506:	409c                	lw	a5,0(s1)
    80005508:	04f71d63          	bne	a4,a5,80005562 <sys_link+0x100>
    8000550c:	40d0                	lw	a2,4(s1)
    8000550e:	fd040593          	add	a1,s0,-48
    80005512:	854a                	mv	a0,s2
    80005514:	fffff097          	auipc	ra,0xfffff
    80005518:	9e4080e7          	jalr	-1564(ra) # 80003ef8 <dirlink>
    8000551c:	04054363          	bltz	a0,80005562 <sys_link+0x100>
  iunlockput(dp);
    80005520:	854a                	mv	a0,s2
    80005522:	ffffe097          	auipc	ra,0xffffe
    80005526:	546080e7          	jalr	1350(ra) # 80003a68 <iunlockput>
  iput(ip);
    8000552a:	8526                	mv	a0,s1
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	494080e7          	jalr	1172(ra) # 800039c0 <iput>
  end_op();
    80005534:	fffff097          	auipc	ra,0xfffff
    80005538:	cf0080e7          	jalr	-784(ra) # 80004224 <end_op>
  return 0;
    8000553c:	4781                	li	a5,0
    8000553e:	a085                	j	8000559e <sys_link+0x13c>
    end_op();
    80005540:	fffff097          	auipc	ra,0xfffff
    80005544:	ce4080e7          	jalr	-796(ra) # 80004224 <end_op>
    return -1;
    80005548:	57fd                	li	a5,-1
    8000554a:	a891                	j	8000559e <sys_link+0x13c>
    iunlockput(ip);
    8000554c:	8526                	mv	a0,s1
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	51a080e7          	jalr	1306(ra) # 80003a68 <iunlockput>
    end_op();
    80005556:	fffff097          	auipc	ra,0xfffff
    8000555a:	cce080e7          	jalr	-818(ra) # 80004224 <end_op>
    return -1;
    8000555e:	57fd                	li	a5,-1
    80005560:	a83d                	j	8000559e <sys_link+0x13c>
    iunlockput(dp);
    80005562:	854a                	mv	a0,s2
    80005564:	ffffe097          	auipc	ra,0xffffe
    80005568:	504080e7          	jalr	1284(ra) # 80003a68 <iunlockput>
  ilock(ip);
    8000556c:	8526                	mv	a0,s1
    8000556e:	ffffe097          	auipc	ra,0xffffe
    80005572:	298080e7          	jalr	664(ra) # 80003806 <ilock>
  ip->nlink--;
    80005576:	04a4d783          	lhu	a5,74(s1)
    8000557a:	37fd                	addw	a5,a5,-1
    8000557c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005580:	8526                	mv	a0,s1
    80005582:	ffffe097          	auipc	ra,0xffffe
    80005586:	1b8080e7          	jalr	440(ra) # 8000373a <iupdate>
  iunlockput(ip);
    8000558a:	8526                	mv	a0,s1
    8000558c:	ffffe097          	auipc	ra,0xffffe
    80005590:	4dc080e7          	jalr	1244(ra) # 80003a68 <iunlockput>
  end_op();
    80005594:	fffff097          	auipc	ra,0xfffff
    80005598:	c90080e7          	jalr	-880(ra) # 80004224 <end_op>
  return -1;
    8000559c:	57fd                	li	a5,-1
}
    8000559e:	853e                	mv	a0,a5
    800055a0:	70b2                	ld	ra,296(sp)
    800055a2:	7412                	ld	s0,288(sp)
    800055a4:	64f2                	ld	s1,280(sp)
    800055a6:	6952                	ld	s2,272(sp)
    800055a8:	6155                	add	sp,sp,304
    800055aa:	8082                	ret

00000000800055ac <sys_unlink>:
{
    800055ac:	7151                	add	sp,sp,-240
    800055ae:	f586                	sd	ra,232(sp)
    800055b0:	f1a2                	sd	s0,224(sp)
    800055b2:	eda6                	sd	s1,216(sp)
    800055b4:	e9ca                	sd	s2,208(sp)
    800055b6:	e5ce                	sd	s3,200(sp)
    800055b8:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055ba:	08000613          	li	a2,128
    800055be:	f3040593          	add	a1,s0,-208
    800055c2:	4501                	li	a0,0
    800055c4:	ffffd097          	auipc	ra,0xffffd
    800055c8:	6f2080e7          	jalr	1778(ra) # 80002cb6 <argstr>
    800055cc:	18054163          	bltz	a0,8000574e <sys_unlink+0x1a2>
  begin_op();
    800055d0:	fffff097          	auipc	ra,0xfffff
    800055d4:	bda080e7          	jalr	-1062(ra) # 800041aa <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055d8:	fb040593          	add	a1,s0,-80
    800055dc:	f3040513          	add	a0,s0,-208
    800055e0:	fffff097          	auipc	ra,0xfffff
    800055e4:	9f8080e7          	jalr	-1544(ra) # 80003fd8 <nameiparent>
    800055e8:	84aa                	mv	s1,a0
    800055ea:	c979                	beqz	a0,800056c0 <sys_unlink+0x114>
  ilock(dp);
    800055ec:	ffffe097          	auipc	ra,0xffffe
    800055f0:	21a080e7          	jalr	538(ra) # 80003806 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055f4:	00003597          	auipc	a1,0x3
    800055f8:	16458593          	add	a1,a1,356 # 80008758 <syscalls+0x2c0>
    800055fc:	fb040513          	add	a0,s0,-80
    80005600:	ffffe097          	auipc	ra,0xffffe
    80005604:	6ce080e7          	jalr	1742(ra) # 80003cce <namecmp>
    80005608:	14050a63          	beqz	a0,8000575c <sys_unlink+0x1b0>
    8000560c:	00003597          	auipc	a1,0x3
    80005610:	ac458593          	add	a1,a1,-1340 # 800080d0 <digits+0x90>
    80005614:	fb040513          	add	a0,s0,-80
    80005618:	ffffe097          	auipc	ra,0xffffe
    8000561c:	6b6080e7          	jalr	1718(ra) # 80003cce <namecmp>
    80005620:	12050e63          	beqz	a0,8000575c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005624:	f2c40613          	add	a2,s0,-212
    80005628:	fb040593          	add	a1,s0,-80
    8000562c:	8526                	mv	a0,s1
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	6ba080e7          	jalr	1722(ra) # 80003ce8 <dirlookup>
    80005636:	892a                	mv	s2,a0
    80005638:	12050263          	beqz	a0,8000575c <sys_unlink+0x1b0>
  ilock(ip);
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	1ca080e7          	jalr	458(ra) # 80003806 <ilock>
  if(ip->nlink < 1)
    80005644:	04a91783          	lh	a5,74(s2)
    80005648:	08f05263          	blez	a5,800056cc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000564c:	04491703          	lh	a4,68(s2)
    80005650:	4785                	li	a5,1
    80005652:	08f70563          	beq	a4,a5,800056dc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005656:	4641                	li	a2,16
    80005658:	4581                	li	a1,0
    8000565a:	fc040513          	add	a0,s0,-64
    8000565e:	ffffb097          	auipc	ra,0xffffb
    80005662:	69a080e7          	jalr	1690(ra) # 80000cf8 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005666:	4741                	li	a4,16
    80005668:	f2c42683          	lw	a3,-212(s0)
    8000566c:	fc040613          	add	a2,s0,-64
    80005670:	4581                	li	a1,0
    80005672:	8526                	mv	a0,s1
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	53e080e7          	jalr	1342(ra) # 80003bb2 <writei>
    8000567c:	47c1                	li	a5,16
    8000567e:	0af51563          	bne	a0,a5,80005728 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005682:	04491703          	lh	a4,68(s2)
    80005686:	4785                	li	a5,1
    80005688:	0af70863          	beq	a4,a5,80005738 <sys_unlink+0x18c>
  iunlockput(dp);
    8000568c:	8526                	mv	a0,s1
    8000568e:	ffffe097          	auipc	ra,0xffffe
    80005692:	3da080e7          	jalr	986(ra) # 80003a68 <iunlockput>
  ip->nlink--;
    80005696:	04a95783          	lhu	a5,74(s2)
    8000569a:	37fd                	addw	a5,a5,-1
    8000569c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056a0:	854a                	mv	a0,s2
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	098080e7          	jalr	152(ra) # 8000373a <iupdate>
  iunlockput(ip);
    800056aa:	854a                	mv	a0,s2
    800056ac:	ffffe097          	auipc	ra,0xffffe
    800056b0:	3bc080e7          	jalr	956(ra) # 80003a68 <iunlockput>
  end_op();
    800056b4:	fffff097          	auipc	ra,0xfffff
    800056b8:	b70080e7          	jalr	-1168(ra) # 80004224 <end_op>
  return 0;
    800056bc:	4501                	li	a0,0
    800056be:	a84d                	j	80005770 <sys_unlink+0x1c4>
    end_op();
    800056c0:	fffff097          	auipc	ra,0xfffff
    800056c4:	b64080e7          	jalr	-1180(ra) # 80004224 <end_op>
    return -1;
    800056c8:	557d                	li	a0,-1
    800056ca:	a05d                	j	80005770 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056cc:	00003517          	auipc	a0,0x3
    800056d0:	0b450513          	add	a0,a0,180 # 80008780 <syscalls+0x2e8>
    800056d4:	ffffb097          	auipc	ra,0xffffb
    800056d8:	e6e080e7          	jalr	-402(ra) # 80000542 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056dc:	04c92703          	lw	a4,76(s2)
    800056e0:	02000793          	li	a5,32
    800056e4:	f6e7f9e3          	bgeu	a5,a4,80005656 <sys_unlink+0xaa>
    800056e8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056ec:	4741                	li	a4,16
    800056ee:	86ce                	mv	a3,s3
    800056f0:	f1840613          	add	a2,s0,-232
    800056f4:	4581                	li	a1,0
    800056f6:	854a                	mv	a0,s2
    800056f8:	ffffe097          	auipc	ra,0xffffe
    800056fc:	3c2080e7          	jalr	962(ra) # 80003aba <readi>
    80005700:	47c1                	li	a5,16
    80005702:	00f51b63          	bne	a0,a5,80005718 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005706:	f1845783          	lhu	a5,-232(s0)
    8000570a:	e7a1                	bnez	a5,80005752 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000570c:	29c1                	addw	s3,s3,16
    8000570e:	04c92783          	lw	a5,76(s2)
    80005712:	fcf9ede3          	bltu	s3,a5,800056ec <sys_unlink+0x140>
    80005716:	b781                	j	80005656 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005718:	00003517          	auipc	a0,0x3
    8000571c:	08050513          	add	a0,a0,128 # 80008798 <syscalls+0x300>
    80005720:	ffffb097          	auipc	ra,0xffffb
    80005724:	e22080e7          	jalr	-478(ra) # 80000542 <panic>
    panic("unlink: writei");
    80005728:	00003517          	auipc	a0,0x3
    8000572c:	08850513          	add	a0,a0,136 # 800087b0 <syscalls+0x318>
    80005730:	ffffb097          	auipc	ra,0xffffb
    80005734:	e12080e7          	jalr	-494(ra) # 80000542 <panic>
    dp->nlink--;
    80005738:	04a4d783          	lhu	a5,74(s1)
    8000573c:	37fd                	addw	a5,a5,-1
    8000573e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005742:	8526                	mv	a0,s1
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	ff6080e7          	jalr	-10(ra) # 8000373a <iupdate>
    8000574c:	b781                	j	8000568c <sys_unlink+0xe0>
    return -1;
    8000574e:	557d                	li	a0,-1
    80005750:	a005                	j	80005770 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005752:	854a                	mv	a0,s2
    80005754:	ffffe097          	auipc	ra,0xffffe
    80005758:	314080e7          	jalr	788(ra) # 80003a68 <iunlockput>
  iunlockput(dp);
    8000575c:	8526                	mv	a0,s1
    8000575e:	ffffe097          	auipc	ra,0xffffe
    80005762:	30a080e7          	jalr	778(ra) # 80003a68 <iunlockput>
  end_op();
    80005766:	fffff097          	auipc	ra,0xfffff
    8000576a:	abe080e7          	jalr	-1346(ra) # 80004224 <end_op>
  return -1;
    8000576e:	557d                	li	a0,-1
}
    80005770:	70ae                	ld	ra,232(sp)
    80005772:	740e                	ld	s0,224(sp)
    80005774:	64ee                	ld	s1,216(sp)
    80005776:	694e                	ld	s2,208(sp)
    80005778:	69ae                	ld	s3,200(sp)
    8000577a:	616d                	add	sp,sp,240
    8000577c:	8082                	ret

000000008000577e <sys_open>:

uint64
sys_open(void)
{
    8000577e:	7131                	add	sp,sp,-192
    80005780:	fd06                	sd	ra,184(sp)
    80005782:	f922                	sd	s0,176(sp)
    80005784:	f526                	sd	s1,168(sp)
    80005786:	f14a                	sd	s2,160(sp)
    80005788:	ed4e                	sd	s3,152(sp)
    8000578a:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000578c:	08000613          	li	a2,128
    80005790:	f5040593          	add	a1,s0,-176
    80005794:	4501                	li	a0,0
    80005796:	ffffd097          	auipc	ra,0xffffd
    8000579a:	520080e7          	jalr	1312(ra) # 80002cb6 <argstr>
    return -1;
    8000579e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057a0:	0c054063          	bltz	a0,80005860 <sys_open+0xe2>
    800057a4:	f4c40593          	add	a1,s0,-180
    800057a8:	4505                	li	a0,1
    800057aa:	ffffd097          	auipc	ra,0xffffd
    800057ae:	4c8080e7          	jalr	1224(ra) # 80002c72 <argint>
    800057b2:	0a054763          	bltz	a0,80005860 <sys_open+0xe2>

  begin_op();
    800057b6:	fffff097          	auipc	ra,0xfffff
    800057ba:	9f4080e7          	jalr	-1548(ra) # 800041aa <begin_op>

  if(omode & O_CREATE){
    800057be:	f4c42783          	lw	a5,-180(s0)
    800057c2:	2007f793          	and	a5,a5,512
    800057c6:	cbd5                	beqz	a5,8000587a <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    800057c8:	4681                	li	a3,0
    800057ca:	4601                	li	a2,0
    800057cc:	4589                	li	a1,2
    800057ce:	f5040513          	add	a0,s0,-176
    800057d2:	00000097          	auipc	ra,0x0
    800057d6:	974080e7          	jalr	-1676(ra) # 80005146 <create>
    800057da:	892a                	mv	s2,a0
    if(ip == 0){
    800057dc:	c951                	beqz	a0,80005870 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057de:	04491703          	lh	a4,68(s2)
    800057e2:	478d                	li	a5,3
    800057e4:	00f71763          	bne	a4,a5,800057f2 <sys_open+0x74>
    800057e8:	04695703          	lhu	a4,70(s2)
    800057ec:	47a5                	li	a5,9
    800057ee:	0ce7eb63          	bltu	a5,a4,800058c4 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057f2:	fffff097          	auipc	ra,0xfffff
    800057f6:	dc6080e7          	jalr	-570(ra) # 800045b8 <filealloc>
    800057fa:	89aa                	mv	s3,a0
    800057fc:	c565                	beqz	a0,800058e4 <sys_open+0x166>
    800057fe:	00000097          	auipc	ra,0x0
    80005802:	906080e7          	jalr	-1786(ra) # 80005104 <fdalloc>
    80005806:	84aa                	mv	s1,a0
    80005808:	0c054963          	bltz	a0,800058da <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000580c:	04491703          	lh	a4,68(s2)
    80005810:	478d                	li	a5,3
    80005812:	0ef70463          	beq	a4,a5,800058fa <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005816:	4789                	li	a5,2
    80005818:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000581c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005820:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005824:	f4c42783          	lw	a5,-180(s0)
    80005828:	0017c713          	xor	a4,a5,1
    8000582c:	8b05                	and	a4,a4,1
    8000582e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005832:	0037f713          	and	a4,a5,3
    80005836:	00e03733          	snez	a4,a4
    8000583a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000583e:	4007f793          	and	a5,a5,1024
    80005842:	c791                	beqz	a5,8000584e <sys_open+0xd0>
    80005844:	04491703          	lh	a4,68(s2)
    80005848:	4789                	li	a5,2
    8000584a:	0af70f63          	beq	a4,a5,80005908 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    8000584e:	854a                	mv	a0,s2
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	078080e7          	jalr	120(ra) # 800038c8 <iunlock>
  end_op();
    80005858:	fffff097          	auipc	ra,0xfffff
    8000585c:	9cc080e7          	jalr	-1588(ra) # 80004224 <end_op>

  return fd;
}
    80005860:	8526                	mv	a0,s1
    80005862:	70ea                	ld	ra,184(sp)
    80005864:	744a                	ld	s0,176(sp)
    80005866:	74aa                	ld	s1,168(sp)
    80005868:	790a                	ld	s2,160(sp)
    8000586a:	69ea                	ld	s3,152(sp)
    8000586c:	6129                	add	sp,sp,192
    8000586e:	8082                	ret
      end_op();
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	9b4080e7          	jalr	-1612(ra) # 80004224 <end_op>
      return -1;
    80005878:	b7e5                	j	80005860 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    8000587a:	f5040513          	add	a0,s0,-176
    8000587e:	ffffe097          	auipc	ra,0xffffe
    80005882:	73c080e7          	jalr	1852(ra) # 80003fba <namei>
    80005886:	892a                	mv	s2,a0
    80005888:	c905                	beqz	a0,800058b8 <sys_open+0x13a>
    ilock(ip);
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	f7c080e7          	jalr	-132(ra) # 80003806 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005892:	04491703          	lh	a4,68(s2)
    80005896:	4785                	li	a5,1
    80005898:	f4f713e3          	bne	a4,a5,800057de <sys_open+0x60>
    8000589c:	f4c42783          	lw	a5,-180(s0)
    800058a0:	dba9                	beqz	a5,800057f2 <sys_open+0x74>
      iunlockput(ip);
    800058a2:	854a                	mv	a0,s2
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	1c4080e7          	jalr	452(ra) # 80003a68 <iunlockput>
      end_op();
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	978080e7          	jalr	-1672(ra) # 80004224 <end_op>
      return -1;
    800058b4:	54fd                	li	s1,-1
    800058b6:	b76d                	j	80005860 <sys_open+0xe2>
      end_op();
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	96c080e7          	jalr	-1684(ra) # 80004224 <end_op>
      return -1;
    800058c0:	54fd                	li	s1,-1
    800058c2:	bf79                	j	80005860 <sys_open+0xe2>
    iunlockput(ip);
    800058c4:	854a                	mv	a0,s2
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	1a2080e7          	jalr	418(ra) # 80003a68 <iunlockput>
    end_op();
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	956080e7          	jalr	-1706(ra) # 80004224 <end_op>
    return -1;
    800058d6:	54fd                	li	s1,-1
    800058d8:	b761                	j	80005860 <sys_open+0xe2>
      fileclose(f);
    800058da:	854e                	mv	a0,s3
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	d98080e7          	jalr	-616(ra) # 80004674 <fileclose>
    iunlockput(ip);
    800058e4:	854a                	mv	a0,s2
    800058e6:	ffffe097          	auipc	ra,0xffffe
    800058ea:	182080e7          	jalr	386(ra) # 80003a68 <iunlockput>
    end_op();
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	936080e7          	jalr	-1738(ra) # 80004224 <end_op>
    return -1;
    800058f6:	54fd                	li	s1,-1
    800058f8:	b7a5                	j	80005860 <sys_open+0xe2>
    f->type = FD_DEVICE;
    800058fa:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058fe:	04691783          	lh	a5,70(s2)
    80005902:	02f99223          	sh	a5,36(s3)
    80005906:	bf29                	j	80005820 <sys_open+0xa2>
    itrunc(ip);
    80005908:	854a                	mv	a0,s2
    8000590a:	ffffe097          	auipc	ra,0xffffe
    8000590e:	00a080e7          	jalr	10(ra) # 80003914 <itrunc>
    80005912:	bf35                	j	8000584e <sys_open+0xd0>

0000000080005914 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005914:	7175                	add	sp,sp,-144
    80005916:	e506                	sd	ra,136(sp)
    80005918:	e122                	sd	s0,128(sp)
    8000591a:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000591c:	fffff097          	auipc	ra,0xfffff
    80005920:	88e080e7          	jalr	-1906(ra) # 800041aa <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005924:	08000613          	li	a2,128
    80005928:	f7040593          	add	a1,s0,-144
    8000592c:	4501                	li	a0,0
    8000592e:	ffffd097          	auipc	ra,0xffffd
    80005932:	388080e7          	jalr	904(ra) # 80002cb6 <argstr>
    80005936:	02054963          	bltz	a0,80005968 <sys_mkdir+0x54>
    8000593a:	4681                	li	a3,0
    8000593c:	4601                	li	a2,0
    8000593e:	4585                	li	a1,1
    80005940:	f7040513          	add	a0,s0,-144
    80005944:	00000097          	auipc	ra,0x0
    80005948:	802080e7          	jalr	-2046(ra) # 80005146 <create>
    8000594c:	cd11                	beqz	a0,80005968 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	11a080e7          	jalr	282(ra) # 80003a68 <iunlockput>
  end_op();
    80005956:	fffff097          	auipc	ra,0xfffff
    8000595a:	8ce080e7          	jalr	-1842(ra) # 80004224 <end_op>
  return 0;
    8000595e:	4501                	li	a0,0
}
    80005960:	60aa                	ld	ra,136(sp)
    80005962:	640a                	ld	s0,128(sp)
    80005964:	6149                	add	sp,sp,144
    80005966:	8082                	ret
    end_op();
    80005968:	fffff097          	auipc	ra,0xfffff
    8000596c:	8bc080e7          	jalr	-1860(ra) # 80004224 <end_op>
    return -1;
    80005970:	557d                	li	a0,-1
    80005972:	b7fd                	j	80005960 <sys_mkdir+0x4c>

0000000080005974 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005974:	7135                	add	sp,sp,-160
    80005976:	ed06                	sd	ra,152(sp)
    80005978:	e922                	sd	s0,144(sp)
    8000597a:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	82e080e7          	jalr	-2002(ra) # 800041aa <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005984:	08000613          	li	a2,128
    80005988:	f7040593          	add	a1,s0,-144
    8000598c:	4501                	li	a0,0
    8000598e:	ffffd097          	auipc	ra,0xffffd
    80005992:	328080e7          	jalr	808(ra) # 80002cb6 <argstr>
    80005996:	04054a63          	bltz	a0,800059ea <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000599a:	f6c40593          	add	a1,s0,-148
    8000599e:	4505                	li	a0,1
    800059a0:	ffffd097          	auipc	ra,0xffffd
    800059a4:	2d2080e7          	jalr	722(ra) # 80002c72 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059a8:	04054163          	bltz	a0,800059ea <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059ac:	f6840593          	add	a1,s0,-152
    800059b0:	4509                	li	a0,2
    800059b2:	ffffd097          	auipc	ra,0xffffd
    800059b6:	2c0080e7          	jalr	704(ra) # 80002c72 <argint>
     argint(1, &major) < 0 ||
    800059ba:	02054863          	bltz	a0,800059ea <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059be:	f6841683          	lh	a3,-152(s0)
    800059c2:	f6c41603          	lh	a2,-148(s0)
    800059c6:	458d                	li	a1,3
    800059c8:	f7040513          	add	a0,s0,-144
    800059cc:	fffff097          	auipc	ra,0xfffff
    800059d0:	77a080e7          	jalr	1914(ra) # 80005146 <create>
     argint(2, &minor) < 0 ||
    800059d4:	c919                	beqz	a0,800059ea <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	092080e7          	jalr	146(ra) # 80003a68 <iunlockput>
  end_op();
    800059de:	fffff097          	auipc	ra,0xfffff
    800059e2:	846080e7          	jalr	-1978(ra) # 80004224 <end_op>
  return 0;
    800059e6:	4501                	li	a0,0
    800059e8:	a031                	j	800059f4 <sys_mknod+0x80>
    end_op();
    800059ea:	fffff097          	auipc	ra,0xfffff
    800059ee:	83a080e7          	jalr	-1990(ra) # 80004224 <end_op>
    return -1;
    800059f2:	557d                	li	a0,-1
}
    800059f4:	60ea                	ld	ra,152(sp)
    800059f6:	644a                	ld	s0,144(sp)
    800059f8:	610d                	add	sp,sp,160
    800059fa:	8082                	ret

00000000800059fc <sys_chdir>:

uint64
sys_chdir(void)
{
    800059fc:	7135                	add	sp,sp,-160
    800059fe:	ed06                	sd	ra,152(sp)
    80005a00:	e922                	sd	s0,144(sp)
    80005a02:	e526                	sd	s1,136(sp)
    80005a04:	e14a                	sd	s2,128(sp)
    80005a06:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a08:	ffffc097          	auipc	ra,0xffffc
    80005a0c:	0f0080e7          	jalr	240(ra) # 80001af8 <myproc>
    80005a10:	892a                	mv	s2,a0
  
  begin_op();
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	798080e7          	jalr	1944(ra) # 800041aa <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a1a:	08000613          	li	a2,128
    80005a1e:	f6040593          	add	a1,s0,-160
    80005a22:	4501                	li	a0,0
    80005a24:	ffffd097          	auipc	ra,0xffffd
    80005a28:	292080e7          	jalr	658(ra) # 80002cb6 <argstr>
    80005a2c:	04054b63          	bltz	a0,80005a82 <sys_chdir+0x86>
    80005a30:	f6040513          	add	a0,s0,-160
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	586080e7          	jalr	1414(ra) # 80003fba <namei>
    80005a3c:	84aa                	mv	s1,a0
    80005a3e:	c131                	beqz	a0,80005a82 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a40:	ffffe097          	auipc	ra,0xffffe
    80005a44:	dc6080e7          	jalr	-570(ra) # 80003806 <ilock>
  if(ip->type != T_DIR){
    80005a48:	04449703          	lh	a4,68(s1)
    80005a4c:	4785                	li	a5,1
    80005a4e:	04f71063          	bne	a4,a5,80005a8e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a52:	8526                	mv	a0,s1
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	e74080e7          	jalr	-396(ra) # 800038c8 <iunlock>
  iput(p->cwd);
    80005a5c:	15093503          	ld	a0,336(s2)
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	f60080e7          	jalr	-160(ra) # 800039c0 <iput>
  end_op();
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	7bc080e7          	jalr	1980(ra) # 80004224 <end_op>
  p->cwd = ip;
    80005a70:	14993823          	sd	s1,336(s2)
  return 0;
    80005a74:	4501                	li	a0,0
}
    80005a76:	60ea                	ld	ra,152(sp)
    80005a78:	644a                	ld	s0,144(sp)
    80005a7a:	64aa                	ld	s1,136(sp)
    80005a7c:	690a                	ld	s2,128(sp)
    80005a7e:	610d                	add	sp,sp,160
    80005a80:	8082                	ret
    end_op();
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	7a2080e7          	jalr	1954(ra) # 80004224 <end_op>
    return -1;
    80005a8a:	557d                	li	a0,-1
    80005a8c:	b7ed                	j	80005a76 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a8e:	8526                	mv	a0,s1
    80005a90:	ffffe097          	auipc	ra,0xffffe
    80005a94:	fd8080e7          	jalr	-40(ra) # 80003a68 <iunlockput>
    end_op();
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	78c080e7          	jalr	1932(ra) # 80004224 <end_op>
    return -1;
    80005aa0:	557d                	li	a0,-1
    80005aa2:	bfd1                	j	80005a76 <sys_chdir+0x7a>

0000000080005aa4 <sys_exec>:

uint64
sys_exec(void)
{
    80005aa4:	7121                	add	sp,sp,-448
    80005aa6:	ff06                	sd	ra,440(sp)
    80005aa8:	fb22                	sd	s0,432(sp)
    80005aaa:	f726                	sd	s1,424(sp)
    80005aac:	f34a                	sd	s2,416(sp)
    80005aae:	ef4e                	sd	s3,408(sp)
    80005ab0:	eb52                	sd	s4,400(sp)
    80005ab2:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ab4:	08000613          	li	a2,128
    80005ab8:	f5040593          	add	a1,s0,-176
    80005abc:	4501                	li	a0,0
    80005abe:	ffffd097          	auipc	ra,0xffffd
    80005ac2:	1f8080e7          	jalr	504(ra) # 80002cb6 <argstr>
    return -1;
    80005ac6:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ac8:	0c054a63          	bltz	a0,80005b9c <sys_exec+0xf8>
    80005acc:	e4840593          	add	a1,s0,-440
    80005ad0:	4505                	li	a0,1
    80005ad2:	ffffd097          	auipc	ra,0xffffd
    80005ad6:	1c2080e7          	jalr	450(ra) # 80002c94 <argaddr>
    80005ada:	0c054163          	bltz	a0,80005b9c <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005ade:	10000613          	li	a2,256
    80005ae2:	4581                	li	a1,0
    80005ae4:	e5040513          	add	a0,s0,-432
    80005ae8:	ffffb097          	auipc	ra,0xffffb
    80005aec:	210080e7          	jalr	528(ra) # 80000cf8 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005af0:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005af4:	89a6                	mv	s3,s1
    80005af6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005af8:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005afc:	00391513          	sll	a0,s2,0x3
    80005b00:	e4040593          	add	a1,s0,-448
    80005b04:	e4843783          	ld	a5,-440(s0)
    80005b08:	953e                	add	a0,a0,a5
    80005b0a:	ffffd097          	auipc	ra,0xffffd
    80005b0e:	0ce080e7          	jalr	206(ra) # 80002bd8 <fetchaddr>
    80005b12:	02054a63          	bltz	a0,80005b46 <sys_exec+0xa2>
      goto bad;
    }
    if(uarg == 0){
    80005b16:	e4043783          	ld	a5,-448(s0)
    80005b1a:	c3b9                	beqz	a5,80005b60 <sys_exec+0xbc>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b1c:	ffffb097          	auipc	ra,0xffffb
    80005b20:	ff0080e7          	jalr	-16(ra) # 80000b0c <kalloc>
    80005b24:	85aa                	mv	a1,a0
    80005b26:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b2a:	cd11                	beqz	a0,80005b46 <sys_exec+0xa2>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b2c:	6605                	lui	a2,0x1
    80005b2e:	e4043503          	ld	a0,-448(s0)
    80005b32:	ffffd097          	auipc	ra,0xffffd
    80005b36:	0f8080e7          	jalr	248(ra) # 80002c2a <fetchstr>
    80005b3a:	00054663          	bltz	a0,80005b46 <sys_exec+0xa2>
    if(i >= NELEM(argv)){
    80005b3e:	0905                	add	s2,s2,1
    80005b40:	09a1                	add	s3,s3,8
    80005b42:	fb491de3          	bne	s2,s4,80005afc <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b46:	f5040913          	add	s2,s0,-176
    80005b4a:	6088                	ld	a0,0(s1)
    80005b4c:	c539                	beqz	a0,80005b9a <sys_exec+0xf6>
    kfree(argv[i]);
    80005b4e:	ffffb097          	auipc	ra,0xffffb
    80005b52:	ec0080e7          	jalr	-320(ra) # 80000a0e <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b56:	04a1                	add	s1,s1,8
    80005b58:	ff2499e3          	bne	s1,s2,80005b4a <sys_exec+0xa6>
  return -1;
    80005b5c:	597d                	li	s2,-1
    80005b5e:	a83d                	j	80005b9c <sys_exec+0xf8>
      argv[i] = 0;
    80005b60:	0009079b          	sext.w	a5,s2
    80005b64:	078e                	sll	a5,a5,0x3
    80005b66:	fd078793          	add	a5,a5,-48
    80005b6a:	97a2                	add	a5,a5,s0
    80005b6c:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005b70:	e5040593          	add	a1,s0,-432
    80005b74:	f5040513          	add	a0,s0,-176
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	17e080e7          	jalr	382(ra) # 80004cf6 <exec>
    80005b80:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b82:	f5040993          	add	s3,s0,-176
    80005b86:	6088                	ld	a0,0(s1)
    80005b88:	c911                	beqz	a0,80005b9c <sys_exec+0xf8>
    kfree(argv[i]);
    80005b8a:	ffffb097          	auipc	ra,0xffffb
    80005b8e:	e84080e7          	jalr	-380(ra) # 80000a0e <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b92:	04a1                	add	s1,s1,8
    80005b94:	ff3499e3          	bne	s1,s3,80005b86 <sys_exec+0xe2>
    80005b98:	a011                	j	80005b9c <sys_exec+0xf8>
  return -1;
    80005b9a:	597d                	li	s2,-1
}
    80005b9c:	854a                	mv	a0,s2
    80005b9e:	70fa                	ld	ra,440(sp)
    80005ba0:	745a                	ld	s0,432(sp)
    80005ba2:	74ba                	ld	s1,424(sp)
    80005ba4:	791a                	ld	s2,416(sp)
    80005ba6:	69fa                	ld	s3,408(sp)
    80005ba8:	6a5a                	ld	s4,400(sp)
    80005baa:	6139                	add	sp,sp,448
    80005bac:	8082                	ret

0000000080005bae <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bae:	7139                	add	sp,sp,-64
    80005bb0:	fc06                	sd	ra,56(sp)
    80005bb2:	f822                	sd	s0,48(sp)
    80005bb4:	f426                	sd	s1,40(sp)
    80005bb6:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bb8:	ffffc097          	auipc	ra,0xffffc
    80005bbc:	f40080e7          	jalr	-192(ra) # 80001af8 <myproc>
    80005bc0:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005bc2:	fd840593          	add	a1,s0,-40
    80005bc6:	4501                	li	a0,0
    80005bc8:	ffffd097          	auipc	ra,0xffffd
    80005bcc:	0cc080e7          	jalr	204(ra) # 80002c94 <argaddr>
    return -1;
    80005bd0:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005bd2:	0e054063          	bltz	a0,80005cb2 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005bd6:	fc840593          	add	a1,s0,-56
    80005bda:	fd040513          	add	a0,s0,-48
    80005bde:	fffff097          	auipc	ra,0xfffff
    80005be2:	dec080e7          	jalr	-532(ra) # 800049ca <pipealloc>
    return -1;
    80005be6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005be8:	0c054563          	bltz	a0,80005cb2 <sys_pipe+0x104>
  fd0 = -1;
    80005bec:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bf0:	fd043503          	ld	a0,-48(s0)
    80005bf4:	fffff097          	auipc	ra,0xfffff
    80005bf8:	510080e7          	jalr	1296(ra) # 80005104 <fdalloc>
    80005bfc:	fca42223          	sw	a0,-60(s0)
    80005c00:	08054c63          	bltz	a0,80005c98 <sys_pipe+0xea>
    80005c04:	fc843503          	ld	a0,-56(s0)
    80005c08:	fffff097          	auipc	ra,0xfffff
    80005c0c:	4fc080e7          	jalr	1276(ra) # 80005104 <fdalloc>
    80005c10:	fca42023          	sw	a0,-64(s0)
    80005c14:	06054963          	bltz	a0,80005c86 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c18:	4691                	li	a3,4
    80005c1a:	fc440613          	add	a2,s0,-60
    80005c1e:	fd843583          	ld	a1,-40(s0)
    80005c22:	68a8                	ld	a0,80(s1)
    80005c24:	ffffc097          	auipc	ra,0xffffc
    80005c28:	bca080e7          	jalr	-1078(ra) # 800017ee <copyout>
    80005c2c:	02054063          	bltz	a0,80005c4c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c30:	4691                	li	a3,4
    80005c32:	fc040613          	add	a2,s0,-64
    80005c36:	fd843583          	ld	a1,-40(s0)
    80005c3a:	0591                	add	a1,a1,4
    80005c3c:	68a8                	ld	a0,80(s1)
    80005c3e:	ffffc097          	auipc	ra,0xffffc
    80005c42:	bb0080e7          	jalr	-1104(ra) # 800017ee <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c46:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c48:	06055563          	bgez	a0,80005cb2 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c4c:	fc442783          	lw	a5,-60(s0)
    80005c50:	07e9                	add	a5,a5,26
    80005c52:	078e                	sll	a5,a5,0x3
    80005c54:	97a6                	add	a5,a5,s1
    80005c56:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c5a:	fc042783          	lw	a5,-64(s0)
    80005c5e:	07e9                	add	a5,a5,26
    80005c60:	078e                	sll	a5,a5,0x3
    80005c62:	00f48533          	add	a0,s1,a5
    80005c66:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c6a:	fd043503          	ld	a0,-48(s0)
    80005c6e:	fffff097          	auipc	ra,0xfffff
    80005c72:	a06080e7          	jalr	-1530(ra) # 80004674 <fileclose>
    fileclose(wf);
    80005c76:	fc843503          	ld	a0,-56(s0)
    80005c7a:	fffff097          	auipc	ra,0xfffff
    80005c7e:	9fa080e7          	jalr	-1542(ra) # 80004674 <fileclose>
    return -1;
    80005c82:	57fd                	li	a5,-1
    80005c84:	a03d                	j	80005cb2 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c86:	fc442783          	lw	a5,-60(s0)
    80005c8a:	0007c763          	bltz	a5,80005c98 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c8e:	07e9                	add	a5,a5,26
    80005c90:	078e                	sll	a5,a5,0x3
    80005c92:	97a6                	add	a5,a5,s1
    80005c94:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005c98:	fd043503          	ld	a0,-48(s0)
    80005c9c:	fffff097          	auipc	ra,0xfffff
    80005ca0:	9d8080e7          	jalr	-1576(ra) # 80004674 <fileclose>
    fileclose(wf);
    80005ca4:	fc843503          	ld	a0,-56(s0)
    80005ca8:	fffff097          	auipc	ra,0xfffff
    80005cac:	9cc080e7          	jalr	-1588(ra) # 80004674 <fileclose>
    return -1;
    80005cb0:	57fd                	li	a5,-1
}
    80005cb2:	853e                	mv	a0,a5
    80005cb4:	70e2                	ld	ra,56(sp)
    80005cb6:	7442                	ld	s0,48(sp)
    80005cb8:	74a2                	ld	s1,40(sp)
    80005cba:	6121                	add	sp,sp,64
    80005cbc:	8082                	ret
	...

0000000080005cc0 <kernelvec>:
    80005cc0:	7111                	add	sp,sp,-256
    80005cc2:	e006                	sd	ra,0(sp)
    80005cc4:	e40a                	sd	sp,8(sp)
    80005cc6:	e80e                	sd	gp,16(sp)
    80005cc8:	ec12                	sd	tp,24(sp)
    80005cca:	f016                	sd	t0,32(sp)
    80005ccc:	f41a                	sd	t1,40(sp)
    80005cce:	f81e                	sd	t2,48(sp)
    80005cd0:	fc22                	sd	s0,56(sp)
    80005cd2:	e0a6                	sd	s1,64(sp)
    80005cd4:	e4aa                	sd	a0,72(sp)
    80005cd6:	e8ae                	sd	a1,80(sp)
    80005cd8:	ecb2                	sd	a2,88(sp)
    80005cda:	f0b6                	sd	a3,96(sp)
    80005cdc:	f4ba                	sd	a4,104(sp)
    80005cde:	f8be                	sd	a5,112(sp)
    80005ce0:	fcc2                	sd	a6,120(sp)
    80005ce2:	e146                	sd	a7,128(sp)
    80005ce4:	e54a                	sd	s2,136(sp)
    80005ce6:	e94e                	sd	s3,144(sp)
    80005ce8:	ed52                	sd	s4,152(sp)
    80005cea:	f156                	sd	s5,160(sp)
    80005cec:	f55a                	sd	s6,168(sp)
    80005cee:	f95e                	sd	s7,176(sp)
    80005cf0:	fd62                	sd	s8,184(sp)
    80005cf2:	e1e6                	sd	s9,192(sp)
    80005cf4:	e5ea                	sd	s10,200(sp)
    80005cf6:	e9ee                	sd	s11,208(sp)
    80005cf8:	edf2                	sd	t3,216(sp)
    80005cfa:	f1f6                	sd	t4,224(sp)
    80005cfc:	f5fa                	sd	t5,232(sp)
    80005cfe:	f9fe                	sd	t6,240(sp)
    80005d00:	da5fc0ef          	jal	80002aa4 <kerneltrap>
    80005d04:	6082                	ld	ra,0(sp)
    80005d06:	6122                	ld	sp,8(sp)
    80005d08:	61c2                	ld	gp,16(sp)
    80005d0a:	7282                	ld	t0,32(sp)
    80005d0c:	7322                	ld	t1,40(sp)
    80005d0e:	73c2                	ld	t2,48(sp)
    80005d10:	7462                	ld	s0,56(sp)
    80005d12:	6486                	ld	s1,64(sp)
    80005d14:	6526                	ld	a0,72(sp)
    80005d16:	65c6                	ld	a1,80(sp)
    80005d18:	6666                	ld	a2,88(sp)
    80005d1a:	7686                	ld	a3,96(sp)
    80005d1c:	7726                	ld	a4,104(sp)
    80005d1e:	77c6                	ld	a5,112(sp)
    80005d20:	7866                	ld	a6,120(sp)
    80005d22:	688a                	ld	a7,128(sp)
    80005d24:	692a                	ld	s2,136(sp)
    80005d26:	69ca                	ld	s3,144(sp)
    80005d28:	6a6a                	ld	s4,152(sp)
    80005d2a:	7a8a                	ld	s5,160(sp)
    80005d2c:	7b2a                	ld	s6,168(sp)
    80005d2e:	7bca                	ld	s7,176(sp)
    80005d30:	7c6a                	ld	s8,184(sp)
    80005d32:	6c8e                	ld	s9,192(sp)
    80005d34:	6d2e                	ld	s10,200(sp)
    80005d36:	6dce                	ld	s11,208(sp)
    80005d38:	6e6e                	ld	t3,216(sp)
    80005d3a:	7e8e                	ld	t4,224(sp)
    80005d3c:	7f2e                	ld	t5,232(sp)
    80005d3e:	7fce                	ld	t6,240(sp)
    80005d40:	6111                	add	sp,sp,256
    80005d42:	10200073          	sret
    80005d46:	00000013          	nop
    80005d4a:	00000013          	nop
    80005d4e:	0001                	nop

0000000080005d50 <timervec>:
    80005d50:	34051573          	csrrw	a0,mscratch,a0
    80005d54:	e10c                	sd	a1,0(a0)
    80005d56:	e510                	sd	a2,8(a0)
    80005d58:	e914                	sd	a3,16(a0)
    80005d5a:	710c                	ld	a1,32(a0)
    80005d5c:	7510                	ld	a2,40(a0)
    80005d5e:	6194                	ld	a3,0(a1)
    80005d60:	96b2                	add	a3,a3,a2
    80005d62:	e194                	sd	a3,0(a1)
    80005d64:	4589                	li	a1,2
    80005d66:	14459073          	csrw	sip,a1
    80005d6a:	6914                	ld	a3,16(a0)
    80005d6c:	6510                	ld	a2,8(a0)
    80005d6e:	610c                	ld	a1,0(a0)
    80005d70:	34051573          	csrrw	a0,mscratch,a0
    80005d74:	30200073          	mret
	...

0000000080005d7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d7a:	1141                	add	sp,sp,-16
    80005d7c:	e422                	sd	s0,8(sp)
    80005d7e:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d80:	0c0007b7          	lui	a5,0xc000
    80005d84:	4705                	li	a4,1
    80005d86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d88:	c3d8                	sw	a4,4(a5)
}
    80005d8a:	6422                	ld	s0,8(sp)
    80005d8c:	0141                	add	sp,sp,16
    80005d8e:	8082                	ret

0000000080005d90 <plicinithart>:

void
plicinithart(void)
{
    80005d90:	1141                	add	sp,sp,-16
    80005d92:	e406                	sd	ra,8(sp)
    80005d94:	e022                	sd	s0,0(sp)
    80005d96:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005d98:	ffffc097          	auipc	ra,0xffffc
    80005d9c:	d34080e7          	jalr	-716(ra) # 80001acc <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005da0:	0085171b          	sllw	a4,a0,0x8
    80005da4:	0c0027b7          	lui	a5,0xc002
    80005da8:	97ba                	add	a5,a5,a4
    80005daa:	40200713          	li	a4,1026
    80005dae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005db2:	00d5151b          	sllw	a0,a0,0xd
    80005db6:	0c2017b7          	lui	a5,0xc201
    80005dba:	97aa                	add	a5,a5,a0
    80005dbc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005dc0:	60a2                	ld	ra,8(sp)
    80005dc2:	6402                	ld	s0,0(sp)
    80005dc4:	0141                	add	sp,sp,16
    80005dc6:	8082                	ret

0000000080005dc8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005dc8:	1141                	add	sp,sp,-16
    80005dca:	e406                	sd	ra,8(sp)
    80005dcc:	e022                	sd	s0,0(sp)
    80005dce:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005dd0:	ffffc097          	auipc	ra,0xffffc
    80005dd4:	cfc080e7          	jalr	-772(ra) # 80001acc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005dd8:	00d5151b          	sllw	a0,a0,0xd
    80005ddc:	0c2017b7          	lui	a5,0xc201
    80005de0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005de2:	43c8                	lw	a0,4(a5)
    80005de4:	60a2                	ld	ra,8(sp)
    80005de6:	6402                	ld	s0,0(sp)
    80005de8:	0141                	add	sp,sp,16
    80005dea:	8082                	ret

0000000080005dec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dec:	1101                	add	sp,sp,-32
    80005dee:	ec06                	sd	ra,24(sp)
    80005df0:	e822                	sd	s0,16(sp)
    80005df2:	e426                	sd	s1,8(sp)
    80005df4:	1000                	add	s0,sp,32
    80005df6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005df8:	ffffc097          	auipc	ra,0xffffc
    80005dfc:	cd4080e7          	jalr	-812(ra) # 80001acc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e00:	00d5151b          	sllw	a0,a0,0xd
    80005e04:	0c2017b7          	lui	a5,0xc201
    80005e08:	97aa                	add	a5,a5,a0
    80005e0a:	c3c4                	sw	s1,4(a5)
}
    80005e0c:	60e2                	ld	ra,24(sp)
    80005e0e:	6442                	ld	s0,16(sp)
    80005e10:	64a2                	ld	s1,8(sp)
    80005e12:	6105                	add	sp,sp,32
    80005e14:	8082                	ret

0000000080005e16 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e16:	1141                	add	sp,sp,-16
    80005e18:	e406                	sd	ra,8(sp)
    80005e1a:	e022                	sd	s0,0(sp)
    80005e1c:	0800                	add	s0,sp,16
  if(i >= NUM)
    80005e1e:	479d                	li	a5,7
    80005e20:	04a7cb63          	blt	a5,a0,80005e76 <free_desc+0x60>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005e24:	0001d717          	auipc	a4,0x1d
    80005e28:	1dc70713          	add	a4,a4,476 # 80023000 <disk>
    80005e2c:	972a                	add	a4,a4,a0
    80005e2e:	6789                	lui	a5,0x2
    80005e30:	97ba                	add	a5,a5,a4
    80005e32:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e36:	eba1                	bnez	a5,80005e86 <free_desc+0x70>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005e38:	00451713          	sll	a4,a0,0x4
    80005e3c:	0001f797          	auipc	a5,0x1f
    80005e40:	1c47b783          	ld	a5,452(a5) # 80025000 <disk+0x2000>
    80005e44:	97ba                	add	a5,a5,a4
    80005e46:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005e4a:	0001d717          	auipc	a4,0x1d
    80005e4e:	1b670713          	add	a4,a4,438 # 80023000 <disk>
    80005e52:	972a                	add	a4,a4,a0
    80005e54:	6789                	lui	a5,0x2
    80005e56:	97ba                	add	a5,a5,a4
    80005e58:	4705                	li	a4,1
    80005e5a:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e5e:	0001f517          	auipc	a0,0x1f
    80005e62:	1ba50513          	add	a0,a0,442 # 80025018 <disk+0x2018>
    80005e66:	ffffc097          	auipc	ra,0xffffc
    80005e6a:	628080e7          	jalr	1576(ra) # 8000248e <wakeup>
}
    80005e6e:	60a2                	ld	ra,8(sp)
    80005e70:	6402                	ld	s0,0(sp)
    80005e72:	0141                	add	sp,sp,16
    80005e74:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e76:	00003517          	auipc	a0,0x3
    80005e7a:	94a50513          	add	a0,a0,-1718 # 800087c0 <syscalls+0x328>
    80005e7e:	ffffa097          	auipc	ra,0xffffa
    80005e82:	6c4080e7          	jalr	1732(ra) # 80000542 <panic>
    panic("virtio_disk_intr 2");
    80005e86:	00003517          	auipc	a0,0x3
    80005e8a:	95250513          	add	a0,a0,-1710 # 800087d8 <syscalls+0x340>
    80005e8e:	ffffa097          	auipc	ra,0xffffa
    80005e92:	6b4080e7          	jalr	1716(ra) # 80000542 <panic>

0000000080005e96 <virtio_disk_init>:
{
    80005e96:	1101                	add	sp,sp,-32
    80005e98:	ec06                	sd	ra,24(sp)
    80005e9a:	e822                	sd	s0,16(sp)
    80005e9c:	e426                	sd	s1,8(sp)
    80005e9e:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ea0:	00003597          	auipc	a1,0x3
    80005ea4:	95058593          	add	a1,a1,-1712 # 800087f0 <syscalls+0x358>
    80005ea8:	0001f517          	auipc	a0,0x1f
    80005eac:	20050513          	add	a0,a0,512 # 800250a8 <disk+0x20a8>
    80005eb0:	ffffb097          	auipc	ra,0xffffb
    80005eb4:	cbc080e7          	jalr	-836(ra) # 80000b6c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005eb8:	100017b7          	lui	a5,0x10001
    80005ebc:	4398                	lw	a4,0(a5)
    80005ebe:	2701                	sext.w	a4,a4
    80005ec0:	747277b7          	lui	a5,0x74727
    80005ec4:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ec8:	0ef71063          	bne	a4,a5,80005fa8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ecc:	100017b7          	lui	a5,0x10001
    80005ed0:	43dc                	lw	a5,4(a5)
    80005ed2:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ed4:	4705                	li	a4,1
    80005ed6:	0ce79963          	bne	a5,a4,80005fa8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005eda:	100017b7          	lui	a5,0x10001
    80005ede:	479c                	lw	a5,8(a5)
    80005ee0:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ee2:	4709                	li	a4,2
    80005ee4:	0ce79263          	bne	a5,a4,80005fa8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005ee8:	100017b7          	lui	a5,0x10001
    80005eec:	47d8                	lw	a4,12(a5)
    80005eee:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ef0:	554d47b7          	lui	a5,0x554d4
    80005ef4:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005ef8:	0af71863          	bne	a4,a5,80005fa8 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005efc:	100017b7          	lui	a5,0x10001
    80005f00:	4705                	li	a4,1
    80005f02:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f04:	470d                	li	a4,3
    80005f06:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f08:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f0a:	c7ffe6b7          	lui	a3,0xc7ffe
    80005f0e:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005f12:	8f75                	and	a4,a4,a3
    80005f14:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f16:	472d                	li	a4,11
    80005f18:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f1a:	473d                	li	a4,15
    80005f1c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f1e:	6705                	lui	a4,0x1
    80005f20:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f22:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f26:	5bdc                	lw	a5,52(a5)
    80005f28:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f2a:	c7d9                	beqz	a5,80005fb8 <virtio_disk_init+0x122>
  if(max < NUM)
    80005f2c:	471d                	li	a4,7
    80005f2e:	08f77d63          	bgeu	a4,a5,80005fc8 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f32:	100014b7          	lui	s1,0x10001
    80005f36:	47a1                	li	a5,8
    80005f38:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f3a:	6609                	lui	a2,0x2
    80005f3c:	4581                	li	a1,0
    80005f3e:	0001d517          	auipc	a0,0x1d
    80005f42:	0c250513          	add	a0,a0,194 # 80023000 <disk>
    80005f46:	ffffb097          	auipc	ra,0xffffb
    80005f4a:	db2080e7          	jalr	-590(ra) # 80000cf8 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f4e:	0001d717          	auipc	a4,0x1d
    80005f52:	0b270713          	add	a4,a4,178 # 80023000 <disk>
    80005f56:	00c75793          	srl	a5,a4,0xc
    80005f5a:	2781                	sext.w	a5,a5
    80005f5c:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005f5e:	0001f797          	auipc	a5,0x1f
    80005f62:	0a278793          	add	a5,a5,162 # 80025000 <disk+0x2000>
    80005f66:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005f68:	0001d717          	auipc	a4,0x1d
    80005f6c:	11870713          	add	a4,a4,280 # 80023080 <disk+0x80>
    80005f70:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005f72:	0001e717          	auipc	a4,0x1e
    80005f76:	08e70713          	add	a4,a4,142 # 80024000 <disk+0x1000>
    80005f7a:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f7c:	4705                	li	a4,1
    80005f7e:	00e78c23          	sb	a4,24(a5)
    80005f82:	00e78ca3          	sb	a4,25(a5)
    80005f86:	00e78d23          	sb	a4,26(a5)
    80005f8a:	00e78da3          	sb	a4,27(a5)
    80005f8e:	00e78e23          	sb	a4,28(a5)
    80005f92:	00e78ea3          	sb	a4,29(a5)
    80005f96:	00e78f23          	sb	a4,30(a5)
    80005f9a:	00e78fa3          	sb	a4,31(a5)
}
    80005f9e:	60e2                	ld	ra,24(sp)
    80005fa0:	6442                	ld	s0,16(sp)
    80005fa2:	64a2                	ld	s1,8(sp)
    80005fa4:	6105                	add	sp,sp,32
    80005fa6:	8082                	ret
    panic("could not find virtio disk");
    80005fa8:	00003517          	auipc	a0,0x3
    80005fac:	85850513          	add	a0,a0,-1960 # 80008800 <syscalls+0x368>
    80005fb0:	ffffa097          	auipc	ra,0xffffa
    80005fb4:	592080e7          	jalr	1426(ra) # 80000542 <panic>
    panic("virtio disk has no queue 0");
    80005fb8:	00003517          	auipc	a0,0x3
    80005fbc:	86850513          	add	a0,a0,-1944 # 80008820 <syscalls+0x388>
    80005fc0:	ffffa097          	auipc	ra,0xffffa
    80005fc4:	582080e7          	jalr	1410(ra) # 80000542 <panic>
    panic("virtio disk max queue too short");
    80005fc8:	00003517          	auipc	a0,0x3
    80005fcc:	87850513          	add	a0,a0,-1928 # 80008840 <syscalls+0x3a8>
    80005fd0:	ffffa097          	auipc	ra,0xffffa
    80005fd4:	572080e7          	jalr	1394(ra) # 80000542 <panic>

0000000080005fd8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005fd8:	7119                	add	sp,sp,-128
    80005fda:	fc86                	sd	ra,120(sp)
    80005fdc:	f8a2                	sd	s0,112(sp)
    80005fde:	f4a6                	sd	s1,104(sp)
    80005fe0:	f0ca                	sd	s2,96(sp)
    80005fe2:	ecce                	sd	s3,88(sp)
    80005fe4:	e8d2                	sd	s4,80(sp)
    80005fe6:	e4d6                	sd	s5,72(sp)
    80005fe8:	e0da                	sd	s6,64(sp)
    80005fea:	fc5e                	sd	s7,56(sp)
    80005fec:	f862                	sd	s8,48(sp)
    80005fee:	f466                	sd	s9,40(sp)
    80005ff0:	f06a                	sd	s10,32(sp)
    80005ff2:	0100                	add	s0,sp,128
    80005ff4:	8a2a                	mv	s4,a0
    80005ff6:	8cae                	mv	s9,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005ff8:	00c52c03          	lw	s8,12(a0)
    80005ffc:	001c1c1b          	sllw	s8,s8,0x1
    80006000:	1c02                	sll	s8,s8,0x20
    80006002:	020c5c13          	srl	s8,s8,0x20

  acquire(&disk.vdisk_lock);
    80006006:	0001f517          	auipc	a0,0x1f
    8000600a:	0a250513          	add	a0,a0,162 # 800250a8 <disk+0x20a8>
    8000600e:	ffffb097          	auipc	ra,0xffffb
    80006012:	bee080e7          	jalr	-1042(ra) # 80000bfc <acquire>
  for(int i = 0; i < 3; i++){
    80006016:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006018:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000601a:	0001db97          	auipc	s7,0x1d
    8000601e:	fe6b8b93          	add	s7,s7,-26 # 80023000 <disk>
    80006022:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006024:	4a8d                	li	s5,3
    80006026:	a0b5                	j	80006092 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006028:	00fb8733          	add	a4,s7,a5
    8000602c:	975a                	add	a4,a4,s6
    8000602e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006032:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006034:	0207c563          	bltz	a5,8000605e <virtio_disk_rw+0x86>
  for(int i = 0; i < 3; i++){
    80006038:	2605                	addw	a2,a2,1 # 2001 <_entry-0x7fffdfff>
    8000603a:	0591                	add	a1,a1,4
    8000603c:	19560c63          	beq	a2,s5,800061d4 <virtio_disk_rw+0x1fc>
    idx[i] = alloc_desc();
    80006040:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006042:	0001f717          	auipc	a4,0x1f
    80006046:	fd670713          	add	a4,a4,-42 # 80025018 <disk+0x2018>
    8000604a:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000604c:	00074683          	lbu	a3,0(a4)
    80006050:	fee1                	bnez	a3,80006028 <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    80006052:	2785                	addw	a5,a5,1
    80006054:	0705                	add	a4,a4,1
    80006056:	fe979be3          	bne	a5,s1,8000604c <virtio_disk_rw+0x74>
    idx[i] = alloc_desc();
    8000605a:	57fd                	li	a5,-1
    8000605c:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000605e:	00c05e63          	blez	a2,8000607a <virtio_disk_rw+0xa2>
    80006062:	060a                	sll	a2,a2,0x2
    80006064:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006068:	0009a503          	lw	a0,0(s3)
    8000606c:	00000097          	auipc	ra,0x0
    80006070:	daa080e7          	jalr	-598(ra) # 80005e16 <free_desc>
      for(int j = 0; j < i; j++)
    80006074:	0991                	add	s3,s3,4
    80006076:	ffa999e3          	bne	s3,s10,80006068 <virtio_disk_rw+0x90>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000607a:	0001f597          	auipc	a1,0x1f
    8000607e:	02e58593          	add	a1,a1,46 # 800250a8 <disk+0x20a8>
    80006082:	0001f517          	auipc	a0,0x1f
    80006086:	f9650513          	add	a0,a0,-106 # 80025018 <disk+0x2018>
    8000608a:	ffffc097          	auipc	ra,0xffffc
    8000608e:	284080e7          	jalr	644(ra) # 8000230e <sleep>
  for(int i = 0; i < 3; i++){
    80006092:	f9040993          	add	s3,s0,-112
{
    80006096:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006098:	864a                	mv	a2,s2
    8000609a:	b75d                	j	80006040 <virtio_disk_rw+0x68>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000609c:	0001f717          	auipc	a4,0x1f
    800060a0:	f6473703          	ld	a4,-156(a4) # 80025000 <disk+0x2000>
    800060a4:	973e                	add	a4,a4,a5
    800060a6:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060aa:	0001d517          	auipc	a0,0x1d
    800060ae:	f5650513          	add	a0,a0,-170 # 80023000 <disk>
    800060b2:	0001f717          	auipc	a4,0x1f
    800060b6:	f4e70713          	add	a4,a4,-178 # 80025000 <disk+0x2000>
    800060ba:	6314                	ld	a3,0(a4)
    800060bc:	96be                	add	a3,a3,a5
    800060be:	00c6d603          	lhu	a2,12(a3)
    800060c2:	00166613          	or	a2,a2,1
    800060c6:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800060ca:	f9842683          	lw	a3,-104(s0)
    800060ce:	6310                	ld	a2,0(a4)
    800060d0:	97b2                	add	a5,a5,a2
    800060d2:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    800060d6:	20048613          	add	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    800060da:	0612                	sll	a2,a2,0x4
    800060dc:	962a                	add	a2,a2,a0
    800060de:	02060823          	sb	zero,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060e2:	00469793          	sll	a5,a3,0x4
    800060e6:	630c                	ld	a1,0(a4)
    800060e8:	95be                	add	a1,a1,a5
    800060ea:	6689                	lui	a3,0x2
    800060ec:	03068693          	add	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    800060f0:	96ca                	add	a3,a3,s2
    800060f2:	96aa                	add	a3,a3,a0
    800060f4:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    800060f6:	6314                	ld	a3,0(a4)
    800060f8:	96be                	add	a3,a3,a5
    800060fa:	4585                	li	a1,1
    800060fc:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060fe:	6314                	ld	a3,0(a4)
    80006100:	96be                	add	a3,a3,a5
    80006102:	4509                	li	a0,2
    80006104:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    80006108:	6314                	ld	a3,0(a4)
    8000610a:	97b6                	add	a5,a5,a3
    8000610c:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006110:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006114:	03463423          	sd	s4,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    80006118:	6714                	ld	a3,8(a4)
    8000611a:	0026d783          	lhu	a5,2(a3)
    8000611e:	8b9d                	and	a5,a5,7
    80006120:	0789                	add	a5,a5,2
    80006122:	0786                	sll	a5,a5,0x1
    80006124:	96be                	add	a3,a3,a5
    80006126:	00969023          	sh	s1,0(a3)
  __sync_synchronize();
    8000612a:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    8000612e:	6718                	ld	a4,8(a4)
    80006130:	00275783          	lhu	a5,2(a4)
    80006134:	2785                	addw	a5,a5,1
    80006136:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000613a:	100017b7          	lui	a5,0x10001
    8000613e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006142:	004a2783          	lw	a5,4(s4)
    80006146:	02b79163          	bne	a5,a1,80006168 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000614a:	0001f917          	auipc	s2,0x1f
    8000614e:	f5e90913          	add	s2,s2,-162 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006152:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006154:	85ca                	mv	a1,s2
    80006156:	8552                	mv	a0,s4
    80006158:	ffffc097          	auipc	ra,0xffffc
    8000615c:	1b6080e7          	jalr	438(ra) # 8000230e <sleep>
  while(b->disk == 1) {
    80006160:	004a2783          	lw	a5,4(s4)
    80006164:	fe9788e3          	beq	a5,s1,80006154 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006168:	f9042483          	lw	s1,-112(s0)
    8000616c:	20048713          	add	a4,s1,512
    80006170:	0712                	sll	a4,a4,0x4
    80006172:	0001d797          	auipc	a5,0x1d
    80006176:	e8e78793          	add	a5,a5,-370 # 80023000 <disk>
    8000617a:	97ba                	add	a5,a5,a4
    8000617c:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006180:	0001f917          	auipc	s2,0x1f
    80006184:	e8090913          	add	s2,s2,-384 # 80025000 <disk+0x2000>
    80006188:	a019                	j	8000618e <virtio_disk_rw+0x1b6>
      i = disk.desc[i].next;
    8000618a:	00e7d483          	lhu	s1,14(a5)
    free_desc(i);
    8000618e:	8526                	mv	a0,s1
    80006190:	00000097          	auipc	ra,0x0
    80006194:	c86080e7          	jalr	-890(ra) # 80005e16 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006198:	0492                	sll	s1,s1,0x4
    8000619a:	00093783          	ld	a5,0(s2)
    8000619e:	97a6                	add	a5,a5,s1
    800061a0:	00c7d703          	lhu	a4,12(a5)
    800061a4:	8b05                	and	a4,a4,1
    800061a6:	f375                	bnez	a4,8000618a <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061a8:	0001f517          	auipc	a0,0x1f
    800061ac:	f0050513          	add	a0,a0,-256 # 800250a8 <disk+0x20a8>
    800061b0:	ffffb097          	auipc	ra,0xffffb
    800061b4:	b00080e7          	jalr	-1280(ra) # 80000cb0 <release>
}
    800061b8:	70e6                	ld	ra,120(sp)
    800061ba:	7446                	ld	s0,112(sp)
    800061bc:	74a6                	ld	s1,104(sp)
    800061be:	7906                	ld	s2,96(sp)
    800061c0:	69e6                	ld	s3,88(sp)
    800061c2:	6a46                	ld	s4,80(sp)
    800061c4:	6aa6                	ld	s5,72(sp)
    800061c6:	6b06                	ld	s6,64(sp)
    800061c8:	7be2                	ld	s7,56(sp)
    800061ca:	7c42                	ld	s8,48(sp)
    800061cc:	7ca2                	ld	s9,40(sp)
    800061ce:	7d02                	ld	s10,32(sp)
    800061d0:	6109                	add	sp,sp,128
    800061d2:	8082                	ret
  if(write)
    800061d4:	019037b3          	snez	a5,s9
    800061d8:	f8f42023          	sw	a5,-128(s0)
  buf0.reserved = 0;
    800061dc:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    800061e0:	f9843423          	sd	s8,-120(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800061e4:	f9042483          	lw	s1,-112(s0)
    800061e8:	00449913          	sll	s2,s1,0x4
    800061ec:	0001f997          	auipc	s3,0x1f
    800061f0:	e1498993          	add	s3,s3,-492 # 80025000 <disk+0x2000>
    800061f4:	0009ba83          	ld	s5,0(s3)
    800061f8:	9aca                	add	s5,s5,s2
    800061fa:	f8040513          	add	a0,s0,-128
    800061fe:	ffffb097          	auipc	ra,0xffffb
    80006202:	f80080e7          	jalr	-128(ra) # 8000117e <kvmpa>
    80006206:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000620a:	0009b783          	ld	a5,0(s3)
    8000620e:	97ca                	add	a5,a5,s2
    80006210:	4741                	li	a4,16
    80006212:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006214:	0009b783          	ld	a5,0(s3)
    80006218:	97ca                	add	a5,a5,s2
    8000621a:	4705                	li	a4,1
    8000621c:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006220:	f9442783          	lw	a5,-108(s0)
    80006224:	0009b703          	ld	a4,0(s3)
    80006228:	974a                	add	a4,a4,s2
    8000622a:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000622e:	0792                	sll	a5,a5,0x4
    80006230:	0009b703          	ld	a4,0(s3)
    80006234:	973e                	add	a4,a4,a5
    80006236:	058a0693          	add	a3,s4,88
    8000623a:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    8000623c:	0009b703          	ld	a4,0(s3)
    80006240:	973e                	add	a4,a4,a5
    80006242:	40000693          	li	a3,1024
    80006246:	c714                	sw	a3,8(a4)
  if(write)
    80006248:	e40c9ae3          	bnez	s9,8000609c <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000624c:	0001f717          	auipc	a4,0x1f
    80006250:	db473703          	ld	a4,-588(a4) # 80025000 <disk+0x2000>
    80006254:	973e                	add	a4,a4,a5
    80006256:	4689                	li	a3,2
    80006258:	00d71623          	sh	a3,12(a4)
    8000625c:	b5b9                	j	800060aa <virtio_disk_rw+0xd2>

000000008000625e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000625e:	1101                	add	sp,sp,-32
    80006260:	ec06                	sd	ra,24(sp)
    80006262:	e822                	sd	s0,16(sp)
    80006264:	e426                	sd	s1,8(sp)
    80006266:	e04a                	sd	s2,0(sp)
    80006268:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000626a:	0001f517          	auipc	a0,0x1f
    8000626e:	e3e50513          	add	a0,a0,-450 # 800250a8 <disk+0x20a8>
    80006272:	ffffb097          	auipc	ra,0xffffb
    80006276:	98a080e7          	jalr	-1654(ra) # 80000bfc <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    8000627a:	0001f717          	auipc	a4,0x1f
    8000627e:	d8670713          	add	a4,a4,-634 # 80025000 <disk+0x2000>
    80006282:	02075783          	lhu	a5,32(a4)
    80006286:	6b18                	ld	a4,16(a4)
    80006288:	00275683          	lhu	a3,2(a4)
    8000628c:	8ebd                	xor	a3,a3,a5
    8000628e:	8a9d                	and	a3,a3,7
    80006290:	cab9                	beqz	a3,800062e6 <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    80006292:	0001d917          	auipc	s2,0x1d
    80006296:	d6e90913          	add	s2,s2,-658 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    8000629a:	0001f497          	auipc	s1,0x1f
    8000629e:	d6648493          	add	s1,s1,-666 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800062a2:	078e                	sll	a5,a5,0x3
    800062a4:	973e                	add	a4,a4,a5
    800062a6:	435c                	lw	a5,4(a4)
    if(disk.info[id].status != 0)
    800062a8:	20078713          	add	a4,a5,512
    800062ac:	0712                	sll	a4,a4,0x4
    800062ae:	974a                	add	a4,a4,s2
    800062b0:	03074703          	lbu	a4,48(a4)
    800062b4:	ef21                	bnez	a4,8000630c <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800062b6:	20078793          	add	a5,a5,512
    800062ba:	0792                	sll	a5,a5,0x4
    800062bc:	97ca                	add	a5,a5,s2
    800062be:	7798                	ld	a4,40(a5)
    800062c0:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800062c4:	7788                	ld	a0,40(a5)
    800062c6:	ffffc097          	auipc	ra,0xffffc
    800062ca:	1c8080e7          	jalr	456(ra) # 8000248e <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800062ce:	0204d783          	lhu	a5,32(s1)
    800062d2:	2785                	addw	a5,a5,1
    800062d4:	8b9d                	and	a5,a5,7
    800062d6:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800062da:	6898                	ld	a4,16(s1)
    800062dc:	00275683          	lhu	a3,2(a4)
    800062e0:	8a9d                	and	a3,a3,7
    800062e2:	fcf690e3          	bne	a3,a5,800062a2 <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062e6:	10001737          	lui	a4,0x10001
    800062ea:	533c                	lw	a5,96(a4)
    800062ec:	8b8d                	and	a5,a5,3
    800062ee:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800062f0:	0001f517          	auipc	a0,0x1f
    800062f4:	db850513          	add	a0,a0,-584 # 800250a8 <disk+0x20a8>
    800062f8:	ffffb097          	auipc	ra,0xffffb
    800062fc:	9b8080e7          	jalr	-1608(ra) # 80000cb0 <release>
}
    80006300:	60e2                	ld	ra,24(sp)
    80006302:	6442                	ld	s0,16(sp)
    80006304:	64a2                	ld	s1,8(sp)
    80006306:	6902                	ld	s2,0(sp)
    80006308:	6105                	add	sp,sp,32
    8000630a:	8082                	ret
      panic("virtio_disk_intr status");
    8000630c:	00002517          	auipc	a0,0x2
    80006310:	55450513          	add	a0,a0,1364 # 80008860 <syscalls+0x3c8>
    80006314:	ffffa097          	auipc	ra,0xffffa
    80006318:	22e080e7          	jalr	558(ra) # 80000542 <panic>
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
