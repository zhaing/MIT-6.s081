
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
    80000060:	df478793          	add	a5,a5,-524 # 80005e50 <timervec>
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
    80000094:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77df>
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
    8000012a:	63e080e7          	jalr	1598(ra) # 80002764 <either_copyin>
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
    800001c4:	878080e7          	jalr	-1928(ra) # 80001a38 <myproc>
    800001c8:	591c                	lw	a5,48(a0)
    800001ca:	efad                	bnez	a5,80000244 <consoleread+0xd4>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	2e4080e7          	jalr	740(ra) # 800024b4 <sleep>
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
    8000021a:	4f8080e7          	jalr	1272(ra) # 8000270e <either_copyout>
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
    800002f8:	4c6080e7          	jalr	1222(ra) # 800027ba <procdump>
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
    8000044c:	1ec080e7          	jalr	492(ra) # 80002634 <wakeup>
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
    8000045e:	ba658593          	add	a1,a1,-1114 # 80008000 <etext>
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
    8000047e:	73678793          	add	a5,a5,1846 # 80021bb0 <devsw>
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
    800004c0:	b7460613          	add	a2,a2,-1164 # 80008030 <digits>
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
    8000055a:	ab250513          	add	a0,a0,-1358 # 80008008 <etext+0x8>
    8000055e:	00000097          	auipc	ra,0x0
    80000562:	02e080e7          	jalr	46(ra) # 8000058c <printf>
  printf(s);
    80000566:	8526                	mv	a0,s1
    80000568:	00000097          	auipc	ra,0x0
    8000056c:	024080e7          	jalr	36(ra) # 8000058c <printf>
  printf("\n");
    80000570:	00008517          	auipc	a0,0x8
    80000574:	b4850513          	add	a0,a0,-1208 # 800080b8 <digits+0x88>
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
    800005ee:	a46b0b13          	add	s6,s6,-1466 # 80008030 <digits>
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
    80000612:	a0a50513          	add	a0,a0,-1526 # 80008018 <etext+0x18>
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
    8000070c:	90848493          	add	s1,s1,-1784 # 80008010 <etext+0x10>
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
    80000782:	8aa58593          	add	a1,a1,-1878 # 80008028 <etext+0x28>
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
    800007d2:	87a58593          	add	a1,a1,-1926 # 80008048 <digits+0x18>
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
    800008a6:	d92080e7          	jalr	-622(ra) # 80002634 <wakeup>
    
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
    80000940:	b78080e7          	jalr	-1160(ra) # 800024b4 <sleep>
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
    80000a22:	00026797          	auipc	a5,0x26
    80000a26:	5fe78793          	add	a5,a5,1534 # 80027020 <end>
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
    80000a78:	5dc50513          	add	a0,a0,1500 # 80008050 <digits+0x20>
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
    80000adc:	58058593          	add	a1,a1,1408 # 80008058 <digits+0x28>
    80000ae0:	00011517          	auipc	a0,0x11
    80000ae4:	e5050513          	add	a0,a0,-432 # 80011930 <kmem>
    80000ae8:	00000097          	auipc	ra,0x0
    80000aec:	084080e7          	jalr	132(ra) # 80000b6c <initlock>
  freerange(end, (void*)PHYSTOP);
    80000af0:	45c5                	li	a1,17
    80000af2:	05ee                	sll	a1,a1,0x1b
    80000af4:	00026517          	auipc	a0,0x26
    80000af8:	52c50513          	add	a0,a0,1324 # 80027020 <end>
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
    80000b9a:	e86080e7          	jalr	-378(ra) # 80001a1c <mycpu>
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
    80000bcc:	e54080e7          	jalr	-428(ra) # 80001a1c <mycpu>
    80000bd0:	5d3c                	lw	a5,120(a0)
    80000bd2:	cf89                	beqz	a5,80000bec <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	e48080e7          	jalr	-440(ra) # 80001a1c <mycpu>
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
    80000bf0:	e30080e7          	jalr	-464(ra) # 80001a1c <mycpu>
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
    80000c30:	df0080e7          	jalr	-528(ra) # 80001a1c <mycpu>
    80000c34:	e888                	sd	a0,16(s1)
}
    80000c36:	60e2                	ld	ra,24(sp)
    80000c38:	6442                	ld	s0,16(sp)
    80000c3a:	64a2                	ld	s1,8(sp)
    80000c3c:	6105                	add	sp,sp,32
    80000c3e:	8082                	ret
    panic("acquire");
    80000c40:	00007517          	auipc	a0,0x7
    80000c44:	42050513          	add	a0,a0,1056 # 80008060 <digits+0x30>
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
    80000c5c:	dc4080e7          	jalr	-572(ra) # 80001a1c <mycpu>
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
    80000c94:	3d850513          	add	a0,a0,984 # 80008068 <digits+0x38>
    80000c98:	00000097          	auipc	ra,0x0
    80000c9c:	8aa080e7          	jalr	-1878(ra) # 80000542 <panic>
    panic("pop_off");
    80000ca0:	00007517          	auipc	a0,0x7
    80000ca4:	3e050513          	add	a0,a0,992 # 80008080 <digits+0x50>
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
    80000cec:	3a050513          	add	a0,a0,928 # 80008088 <digits+0x58>
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
    80000da8:	177d                	add	a4,a4,-1 # ffffffffffffefff <end+0xffffffff7ffd7fdf>
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
    80000eb0:	b60080e7          	jalr	-1184(ra) # 80001a0c <cpuid>
#endif    
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
    80000ecc:	b44080e7          	jalr	-1212(ra) # 80001a0c <cpuid>
    80000ed0:	85aa                	mv	a1,a0
    80000ed2:	00007517          	auipc	a0,0x7
    80000ed6:	1d650513          	add	a0,a0,470 # 800080a8 <digits+0x78>
    80000eda:	fffff097          	auipc	ra,0xfffff
    80000ede:	6b2080e7          	jalr	1714(ra) # 8000058c <printf>
    kvminithart();    // turn on paging
    80000ee2:	00000097          	auipc	ra,0x0
    80000ee6:	1d6080e7          	jalr	470(ra) # 800010b8 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eea:	00002097          	auipc	ra,0x2
    80000eee:	a12080e7          	jalr	-1518(ra) # 800028fc <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef2:	00005097          	auipc	ra,0x5
    80000ef6:	f9e080e7          	jalr	-98(ra) # 80005e90 <plicinithart>
  }

  scheduler();        
    80000efa:	00001097          	auipc	ra,0x1
    80000efe:	2c4080e7          	jalr	708(ra) # 800021be <scheduler>
    consoleinit();
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	550080e7          	jalr	1360(ra) # 80000452 <consoleinit>
    statsinit();
    80000f0a:	00005097          	auipc	ra,0x5
    80000f0e:	722080e7          	jalr	1826(ra) # 8000662c <statsinit>
    printfinit();
    80000f12:	00000097          	auipc	ra,0x0
    80000f16:	85a080e7          	jalr	-1958(ra) # 8000076c <printfinit>
    printf("\n");
    80000f1a:	00007517          	auipc	a0,0x7
    80000f1e:	19e50513          	add	a0,a0,414 # 800080b8 <digits+0x88>
    80000f22:	fffff097          	auipc	ra,0xfffff
    80000f26:	66a080e7          	jalr	1642(ra) # 8000058c <printf>
    printf("xv6 kernel is booting\n");
    80000f2a:	00007517          	auipc	a0,0x7
    80000f2e:	16650513          	add	a0,a0,358 # 80008090 <digits+0x60>
    80000f32:	fffff097          	auipc	ra,0xfffff
    80000f36:	65a080e7          	jalr	1626(ra) # 8000058c <printf>
    printf("\n");
    80000f3a:	00007517          	auipc	a0,0x7
    80000f3e:	17e50513          	add	a0,a0,382 # 800080b8 <digits+0x88>
    80000f42:	fffff097          	auipc	ra,0xfffff
    80000f46:	64a080e7          	jalr	1610(ra) # 8000058c <printf>
    kinit();         // physical page allocator
    80000f4a:	00000097          	auipc	ra,0x0
    80000f4e:	b86080e7          	jalr	-1146(ra) # 80000ad0 <kinit>
    kvminit();       // create kernel page table
    80000f52:	00000097          	auipc	ra,0x0
    80000f56:	39e080e7          	jalr	926(ra) # 800012f0 <kvminit>
    kvminithart();   // turn on paging
    80000f5a:	00000097          	auipc	ra,0x0
    80000f5e:	15e080e7          	jalr	350(ra) # 800010b8 <kvminithart>
    procinit();      // process table
    80000f62:	00001097          	auipc	ra,0x1
    80000f66:	a42080e7          	jalr	-1470(ra) # 800019a4 <procinit>
    trapinit();      // trap vectors
    80000f6a:	00002097          	auipc	ra,0x2
    80000f6e:	96a080e7          	jalr	-1686(ra) # 800028d4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	98a080e7          	jalr	-1654(ra) # 800028fc <trapinithart>
    plicinit();      // set up interrupt controller
    80000f7a:	00005097          	auipc	ra,0x5
    80000f7e:	f00080e7          	jalr	-256(ra) # 80005e7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f82:	00005097          	auipc	ra,0x5
    80000f86:	f0e080e7          	jalr	-242(ra) # 80005e90 <plicinithart>
    binit();         // buffer cache
    80000f8a:	00002097          	auipc	ra,0x2
    80000f8e:	0b8080e7          	jalr	184(ra) # 80003042 <binit>
    iinit();         // inode cache
    80000f92:	00002097          	auipc	ra,0x2
    80000f96:	744080e7          	jalr	1860(ra) # 800036d6 <iinit>
    fileinit();      // file table
    80000f9a:	00003097          	auipc	ra,0x3
    80000f9e:	6b6080e7          	jalr	1718(ra) # 80004650 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa2:	00005097          	auipc	ra,0x5
    80000fa6:	ff4080e7          	jalr	-12(ra) # 80005f96 <virtio_disk_init>
    userinit();      // first user process
    80000faa:	00001097          	auipc	ra,0x1
    80000fae:	efa080e7          	jalr	-262(ra) # 80001ea4 <userinit>
    __sync_synchronize();
    80000fb2:	0ff0000f          	fence
    started = 1;
    80000fb6:	4785                	li	a5,1
    80000fb8:	00008717          	auipc	a4,0x8
    80000fbc:	04f72a23          	sw	a5,84(a4) # 8000900c <started>
    80000fc0:	bf2d                	j	80000efa <main+0x56>

0000000080000fc2 <_vmprint>:
extern char etext[];  // kernel.ld sets this to end of kernel code.

extern char trampoline[]; // trampoline.S
void
_vmprint(pagetable_t pagetable,int level)
{
    80000fc2:	711d                	add	sp,sp,-96
    80000fc4:	ec86                	sd	ra,88(sp)
    80000fc6:	e8a2                	sd	s0,80(sp)
    80000fc8:	e4a6                	sd	s1,72(sp)
    80000fca:	e0ca                	sd	s2,64(sp)
    80000fcc:	fc4e                	sd	s3,56(sp)
    80000fce:	f852                	sd	s4,48(sp)
    80000fd0:	f456                	sd	s5,40(sp)
    80000fd2:	f05a                	sd	s6,32(sp)
    80000fd4:	ec5e                	sd	s7,24(sp)
    80000fd6:	e862                	sd	s8,16(sp)
    80000fd8:	e466                	sd	s9,8(sp)
    80000fda:	e06a                	sd	s10,0(sp)
    80000fdc:	1080                	add	s0,sp,96
    80000fde:	8aae                	mv	s5,a1
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80000fe0:	8a2a                	mv	s4,a0
    80000fe2:	4981                	li	s3,0
    pte_t pte = pagetable[i];
    if((pte & PTE_V)){
      for(int j=0;j<level;j++){
    80000fe4:	4d01                	li	s10,0
        if(j) printf(" ");
        printf("..");
    80000fe6:	00007b17          	auipc	s6,0x7
    80000fea:	0e2b0b13          	add	s6,s6,226 # 800080c8 <digits+0x98>
        if(j) printf(" ");
    80000fee:	00007b97          	auipc	s7,0x7
    80000ff2:	0d2b8b93          	add	s7,s7,210 # 800080c0 <digits+0x90>
      }
      uint64 child = PTE2PA(pte);
      printf("%d: pte %p pa %p\n", i,pte,child);
    80000ff6:	00007c97          	auipc	s9,0x7
    80000ffa:	0dac8c93          	add	s9,s9,218 # 800080d0 <digits+0xa0>
  for(int i = 0; i < 512; i++){
    80000ffe:	20000c13          	li	s8,512
    80001002:	a025                	j	8000102a <_vmprint+0x68>
      uint64 child = PTE2PA(pte);
    80001004:	00a95493          	srl	s1,s2,0xa
    80001008:	04b2                	sll	s1,s1,0xc
      printf("%d: pte %p pa %p\n", i,pte,child);
    8000100a:	86a6                	mv	a3,s1
    8000100c:	864a                	mv	a2,s2
    8000100e:	85ce                	mv	a1,s3
    80001010:	8566                	mv	a0,s9
    80001012:	fffff097          	auipc	ra,0xfffff
    80001016:	57a080e7          	jalr	1402(ra) # 8000058c <printf>
      if((pte & (PTE_R|PTE_W|PTE_X)) == 0) _vmprint((pagetable_t)child,level+1);
    8000101a:	00e97913          	and	s2,s2,14
    8000101e:	02090d63          	beqz	s2,80001058 <_vmprint+0x96>
  for(int i = 0; i < 512; i++){
    80001022:	2985                	addw	s3,s3,1 # 1001 <_entry-0x7fffefff>
    80001024:	0a21                	add	s4,s4,8 # fffffffffffff008 <end+0xffffffff7ffd7fe8>
    80001026:	05898163          	beq	s3,s8,80001068 <_vmprint+0xa6>
    pte_t pte = pagetable[i];
    8000102a:	000a3903          	ld	s2,0(s4)
    if((pte & PTE_V)){
    8000102e:	00197793          	and	a5,s2,1
    80001032:	dbe5                	beqz	a5,80001022 <_vmprint+0x60>
      for(int j=0;j<level;j++){
    80001034:	84ea                	mv	s1,s10
    80001036:	fd5057e3          	blez	s5,80001004 <_vmprint+0x42>
        printf("..");
    8000103a:	855a                	mv	a0,s6
    8000103c:	fffff097          	auipc	ra,0xfffff
    80001040:	550080e7          	jalr	1360(ra) # 8000058c <printf>
      for(int j=0;j<level;j++){
    80001044:	2485                	addw	s1,s1,1
    80001046:	fa9a8fe3          	beq	s5,s1,80001004 <_vmprint+0x42>
        if(j) printf(" ");
    8000104a:	d8e5                	beqz	s1,8000103a <_vmprint+0x78>
    8000104c:	855e                	mv	a0,s7
    8000104e:	fffff097          	auipc	ra,0xfffff
    80001052:	53e080e7          	jalr	1342(ra) # 8000058c <printf>
    80001056:	b7d5                	j	8000103a <_vmprint+0x78>
      if((pte & (PTE_R|PTE_W|PTE_X)) == 0) _vmprint((pagetable_t)child,level+1);
    80001058:	001a859b          	addw	a1,s5,1
    8000105c:	8526                	mv	a0,s1
    8000105e:	00000097          	auipc	ra,0x0
    80001062:	f64080e7          	jalr	-156(ra) # 80000fc2 <_vmprint>
    80001066:	bf75                	j	80001022 <_vmprint+0x60>
    }
  }
}
    80001068:	60e6                	ld	ra,88(sp)
    8000106a:	6446                	ld	s0,80(sp)
    8000106c:	64a6                	ld	s1,72(sp)
    8000106e:	6906                	ld	s2,64(sp)
    80001070:	79e2                	ld	s3,56(sp)
    80001072:	7a42                	ld	s4,48(sp)
    80001074:	7aa2                	ld	s5,40(sp)
    80001076:	7b02                	ld	s6,32(sp)
    80001078:	6be2                	ld	s7,24(sp)
    8000107a:	6c42                	ld	s8,16(sp)
    8000107c:	6ca2                	ld	s9,8(sp)
    8000107e:	6d02                	ld	s10,0(sp)
    80001080:	6125                	add	sp,sp,96
    80001082:	8082                	ret

0000000080001084 <vmprint>:
void
vmprint(pagetable_t pagetable)
{
    80001084:	1101                	add	sp,sp,-32
    80001086:	ec06                	sd	ra,24(sp)
    80001088:	e822                	sd	s0,16(sp)
    8000108a:	e426                	sd	s1,8(sp)
    8000108c:	1000                	add	s0,sp,32
    8000108e:	84aa                	mv	s1,a0
  printf("page table %p\n",pagetable);
    80001090:	85aa                	mv	a1,a0
    80001092:	00007517          	auipc	a0,0x7
    80001096:	05650513          	add	a0,a0,86 # 800080e8 <digits+0xb8>
    8000109a:	fffff097          	auipc	ra,0xfffff
    8000109e:	4f2080e7          	jalr	1266(ra) # 8000058c <printf>
  _vmprint(pagetable,1);
    800010a2:	4585                	li	a1,1
    800010a4:	8526                	mv	a0,s1
    800010a6:	00000097          	auipc	ra,0x0
    800010aa:	f1c080e7          	jalr	-228(ra) # 80000fc2 <_vmprint>
}
    800010ae:	60e2                	ld	ra,24(sp)
    800010b0:	6442                	ld	s0,16(sp)
    800010b2:	64a2                	ld	s1,8(sp)
    800010b4:	6105                	add	sp,sp,32
    800010b6:	8082                	ret

00000000800010b8 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800010b8:	1141                	add	sp,sp,-16
    800010ba:	e422                	sd	s0,8(sp)
    800010bc:	0800                	add	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    800010be:	00008797          	auipc	a5,0x8
    800010c2:	f527b783          	ld	a5,-174(a5) # 80009010 <kernel_pagetable>
    800010c6:	83b1                	srl	a5,a5,0xc
    800010c8:	577d                	li	a4,-1
    800010ca:	177e                	sll	a4,a4,0x3f
    800010cc:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010ce:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010d2:	12000073          	sfence.vma
  sfence_vma();
}
    800010d6:	6422                	ld	s0,8(sp)
    800010d8:	0141                	add	sp,sp,16
    800010da:	8082                	ret

00000000800010dc <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010dc:	7139                	add	sp,sp,-64
    800010de:	fc06                	sd	ra,56(sp)
    800010e0:	f822                	sd	s0,48(sp)
    800010e2:	f426                	sd	s1,40(sp)
    800010e4:	f04a                	sd	s2,32(sp)
    800010e6:	ec4e                	sd	s3,24(sp)
    800010e8:	e852                	sd	s4,16(sp)
    800010ea:	e456                	sd	s5,8(sp)
    800010ec:	e05a                	sd	s6,0(sp)
    800010ee:	0080                	add	s0,sp,64
    800010f0:	84aa                	mv	s1,a0
    800010f2:	89ae                	mv	s3,a1
    800010f4:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800010f6:	57fd                	li	a5,-1
    800010f8:	83e9                	srl	a5,a5,0x1a
    800010fa:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800010fc:	4b31                	li	s6,12
  if(va >= MAXVA)
    800010fe:	04b7f263          	bgeu	a5,a1,80001142 <walk+0x66>
    panic("walk");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	ff650513          	add	a0,a0,-10 # 800080f8 <digits+0xc8>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	438080e7          	jalr	1080(ra) # 80000542 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001112:	060a8663          	beqz	s5,8000117e <walk+0xa2>
    80001116:	00000097          	auipc	ra,0x0
    8000111a:	9f6080e7          	jalr	-1546(ra) # 80000b0c <kalloc>
    8000111e:	84aa                	mv	s1,a0
    80001120:	c529                	beqz	a0,8000116a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001122:	6605                	lui	a2,0x1
    80001124:	4581                	li	a1,0
    80001126:	00000097          	auipc	ra,0x0
    8000112a:	bd2080e7          	jalr	-1070(ra) # 80000cf8 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000112e:	00c4d793          	srl	a5,s1,0xc
    80001132:	07aa                	sll	a5,a5,0xa
    80001134:	0017e793          	or	a5,a5,1
    80001138:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000113c:	3a5d                	addw	s4,s4,-9
    8000113e:	036a0063          	beq	s4,s6,8000115e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001142:	0149d933          	srl	s2,s3,s4
    80001146:	1ff97913          	and	s2,s2,511
    8000114a:	090e                	sll	s2,s2,0x3
    8000114c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000114e:	00093483          	ld	s1,0(s2)
    80001152:	0014f793          	and	a5,s1,1
    80001156:	dfd5                	beqz	a5,80001112 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001158:	80a9                	srl	s1,s1,0xa
    8000115a:	04b2                	sll	s1,s1,0xc
    8000115c:	b7c5                	j	8000113c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000115e:	00c9d513          	srl	a0,s3,0xc
    80001162:	1ff57513          	and	a0,a0,511
    80001166:	050e                	sll	a0,a0,0x3
    80001168:	9526                	add	a0,a0,s1
}
    8000116a:	70e2                	ld	ra,56(sp)
    8000116c:	7442                	ld	s0,48(sp)
    8000116e:	74a2                	ld	s1,40(sp)
    80001170:	7902                	ld	s2,32(sp)
    80001172:	69e2                	ld	s3,24(sp)
    80001174:	6a42                	ld	s4,16(sp)
    80001176:	6aa2                	ld	s5,8(sp)
    80001178:	6b02                	ld	s6,0(sp)
    8000117a:	6121                	add	sp,sp,64
    8000117c:	8082                	ret
        return 0;
    8000117e:	4501                	li	a0,0
    80001180:	b7ed                	j	8000116a <walk+0x8e>

0000000080001182 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001182:	57fd                	li	a5,-1
    80001184:	83e9                	srl	a5,a5,0x1a
    80001186:	00b7f463          	bgeu	a5,a1,8000118e <walkaddr+0xc>
    return 0;
    8000118a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000118c:	8082                	ret
{
    8000118e:	1141                	add	sp,sp,-16
    80001190:	e406                	sd	ra,8(sp)
    80001192:	e022                	sd	s0,0(sp)
    80001194:	0800                	add	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001196:	4601                	li	a2,0
    80001198:	00000097          	auipc	ra,0x0
    8000119c:	f44080e7          	jalr	-188(ra) # 800010dc <walk>
  if(pte == 0)
    800011a0:	c105                	beqz	a0,800011c0 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800011a2:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800011a4:	0117f693          	and	a3,a5,17
    800011a8:	4745                	li	a4,17
    return 0;
    800011aa:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011ac:	00e68663          	beq	a3,a4,800011b8 <walkaddr+0x36>
}
    800011b0:	60a2                	ld	ra,8(sp)
    800011b2:	6402                	ld	s0,0(sp)
    800011b4:	0141                	add	sp,sp,16
    800011b6:	8082                	ret
  pa = PTE2PA(*pte);
    800011b8:	83a9                	srl	a5,a5,0xa
    800011ba:	00c79513          	sll	a0,a5,0xc
  return pa;
    800011be:	bfcd                	j	800011b0 <walkaddr+0x2e>
    return 0;
    800011c0:	4501                	li	a0,0
    800011c2:	b7fd                	j	800011b0 <walkaddr+0x2e>

00000000800011c4 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800011c4:	1101                	add	sp,sp,-32
    800011c6:	ec06                	sd	ra,24(sp)
    800011c8:	e822                	sd	s0,16(sp)
    800011ca:	e426                	sd	s1,8(sp)
    800011cc:	e04a                	sd	s2,0(sp)
    800011ce:	1000                	add	s0,sp,32
    800011d0:	84aa                	mv	s1,a0
  uint64 off = va % PGSIZE;
    800011d2:	1552                	sll	a0,a0,0x34
    800011d4:	03455913          	srl	s2,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(myproc()->ukpagetable, va, 0);
    800011d8:	00001097          	auipc	ra,0x1
    800011dc:	860080e7          	jalr	-1952(ra) # 80001a38 <myproc>
    800011e0:	4601                	li	a2,0
    800011e2:	85a6                	mv	a1,s1
    800011e4:	6d28                	ld	a0,88(a0)
    800011e6:	00000097          	auipc	ra,0x0
    800011ea:	ef6080e7          	jalr	-266(ra) # 800010dc <walk>
  if(pte == 0)
    800011ee:	cd11                	beqz	a0,8000120a <kvmpa+0x46>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800011f0:	6108                	ld	a0,0(a0)
    800011f2:	00157793          	and	a5,a0,1
    800011f6:	c395                	beqz	a5,8000121a <kvmpa+0x56>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800011f8:	8129                	srl	a0,a0,0xa
    800011fa:	0532                	sll	a0,a0,0xc
  return pa+off;
}
    800011fc:	954a                	add	a0,a0,s2
    800011fe:	60e2                	ld	ra,24(sp)
    80001200:	6442                	ld	s0,16(sp)
    80001202:	64a2                	ld	s1,8(sp)
    80001204:	6902                	ld	s2,0(sp)
    80001206:	6105                	add	sp,sp,32
    80001208:	8082                	ret
    panic("kvmpa");
    8000120a:	00007517          	auipc	a0,0x7
    8000120e:	ef650513          	add	a0,a0,-266 # 80008100 <digits+0xd0>
    80001212:	fffff097          	auipc	ra,0xfffff
    80001216:	330080e7          	jalr	816(ra) # 80000542 <panic>
    panic("kvmpa");
    8000121a:	00007517          	auipc	a0,0x7
    8000121e:	ee650513          	add	a0,a0,-282 # 80008100 <digits+0xd0>
    80001222:	fffff097          	auipc	ra,0xfffff
    80001226:	320080e7          	jalr	800(ra) # 80000542 <panic>

000000008000122a <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000122a:	715d                	add	sp,sp,-80
    8000122c:	e486                	sd	ra,72(sp)
    8000122e:	e0a2                	sd	s0,64(sp)
    80001230:	fc26                	sd	s1,56(sp)
    80001232:	f84a                	sd	s2,48(sp)
    80001234:	f44e                	sd	s3,40(sp)
    80001236:	f052                	sd	s4,32(sp)
    80001238:	ec56                	sd	s5,24(sp)
    8000123a:	e85a                	sd	s6,16(sp)
    8000123c:	e45e                	sd	s7,8(sp)
    8000123e:	0880                	add	s0,sp,80
    80001240:	8aaa                	mv	s5,a0
    80001242:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001244:	777d                	lui	a4,0xfffff
    80001246:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000124a:	fff60993          	add	s3,a2,-1 # fff <_entry-0x7ffff001>
    8000124e:	99ae                	add	s3,s3,a1
    80001250:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001254:	893e                	mv	s2,a5
    80001256:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000125a:	6b85                	lui	s7,0x1
    8000125c:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001260:	4605                	li	a2,1
    80001262:	85ca                	mv	a1,s2
    80001264:	8556                	mv	a0,s5
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	e76080e7          	jalr	-394(ra) # 800010dc <walk>
    8000126e:	c51d                	beqz	a0,8000129c <mappages+0x72>
    if(*pte & PTE_V)
    80001270:	611c                	ld	a5,0(a0)
    80001272:	8b85                	and	a5,a5,1
    80001274:	ef81                	bnez	a5,8000128c <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001276:	80b1                	srl	s1,s1,0xc
    80001278:	04aa                	sll	s1,s1,0xa
    8000127a:	0164e4b3          	or	s1,s1,s6
    8000127e:	0014e493          	or	s1,s1,1
    80001282:	e104                	sd	s1,0(a0)
    if(a == last)
    80001284:	03390863          	beq	s2,s3,800012b4 <mappages+0x8a>
    a += PGSIZE;
    80001288:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000128a:	bfc9                	j	8000125c <mappages+0x32>
      panic("remap");
    8000128c:	00007517          	auipc	a0,0x7
    80001290:	e7c50513          	add	a0,a0,-388 # 80008108 <digits+0xd8>
    80001294:	fffff097          	auipc	ra,0xfffff
    80001298:	2ae080e7          	jalr	686(ra) # 80000542 <panic>
      return -1;
    8000129c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000129e:	60a6                	ld	ra,72(sp)
    800012a0:	6406                	ld	s0,64(sp)
    800012a2:	74e2                	ld	s1,56(sp)
    800012a4:	7942                	ld	s2,48(sp)
    800012a6:	79a2                	ld	s3,40(sp)
    800012a8:	7a02                	ld	s4,32(sp)
    800012aa:	6ae2                	ld	s5,24(sp)
    800012ac:	6b42                	ld	s6,16(sp)
    800012ae:	6ba2                	ld	s7,8(sp)
    800012b0:	6161                	add	sp,sp,80
    800012b2:	8082                	ret
  return 0;
    800012b4:	4501                	li	a0,0
    800012b6:	b7e5                	j	8000129e <mappages+0x74>

00000000800012b8 <kvmmap>:
{
    800012b8:	1141                	add	sp,sp,-16
    800012ba:	e406                	sd	ra,8(sp)
    800012bc:	e022                	sd	s0,0(sp)
    800012be:	0800                	add	s0,sp,16
    800012c0:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800012c2:	86ae                	mv	a3,a1
    800012c4:	85aa                	mv	a1,a0
    800012c6:	00008517          	auipc	a0,0x8
    800012ca:	d4a53503          	ld	a0,-694(a0) # 80009010 <kernel_pagetable>
    800012ce:	00000097          	auipc	ra,0x0
    800012d2:	f5c080e7          	jalr	-164(ra) # 8000122a <mappages>
    800012d6:	e509                	bnez	a0,800012e0 <kvmmap+0x28>
}
    800012d8:	60a2                	ld	ra,8(sp)
    800012da:	6402                	ld	s0,0(sp)
    800012dc:	0141                	add	sp,sp,16
    800012de:	8082                	ret
    panic("kvmmap");
    800012e0:	00007517          	auipc	a0,0x7
    800012e4:	e3050513          	add	a0,a0,-464 # 80008110 <digits+0xe0>
    800012e8:	fffff097          	auipc	ra,0xfffff
    800012ec:	25a080e7          	jalr	602(ra) # 80000542 <panic>

00000000800012f0 <kvminit>:
{
    800012f0:	1101                	add	sp,sp,-32
    800012f2:	ec06                	sd	ra,24(sp)
    800012f4:	e822                	sd	s0,16(sp)
    800012f6:	e426                	sd	s1,8(sp)
    800012f8:	1000                	add	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	812080e7          	jalr	-2030(ra) # 80000b0c <kalloc>
    80001302:	00008717          	auipc	a4,0x8
    80001306:	d0a73723          	sd	a0,-754(a4) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000130a:	6605                	lui	a2,0x1
    8000130c:	4581                	li	a1,0
    8000130e:	00000097          	auipc	ra,0x0
    80001312:	9ea080e7          	jalr	-1558(ra) # 80000cf8 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001316:	4699                	li	a3,6
    80001318:	6605                	lui	a2,0x1
    8000131a:	100005b7          	lui	a1,0x10000
    8000131e:	10000537          	lui	a0,0x10000
    80001322:	00000097          	auipc	ra,0x0
    80001326:	f96080e7          	jalr	-106(ra) # 800012b8 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000132a:	4699                	li	a3,6
    8000132c:	6605                	lui	a2,0x1
    8000132e:	100015b7          	lui	a1,0x10001
    80001332:	10001537          	lui	a0,0x10001
    80001336:	00000097          	auipc	ra,0x0
    8000133a:	f82080e7          	jalr	-126(ra) # 800012b8 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000133e:	4699                	li	a3,6
    80001340:	6641                	lui	a2,0x10
    80001342:	020005b7          	lui	a1,0x2000
    80001346:	02000537          	lui	a0,0x2000
    8000134a:	00000097          	auipc	ra,0x0
    8000134e:	f6e080e7          	jalr	-146(ra) # 800012b8 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001352:	4699                	li	a3,6
    80001354:	00400637          	lui	a2,0x400
    80001358:	0c0005b7          	lui	a1,0xc000
    8000135c:	0c000537          	lui	a0,0xc000
    80001360:	00000097          	auipc	ra,0x0
    80001364:	f58080e7          	jalr	-168(ra) # 800012b8 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001368:	00007497          	auipc	s1,0x7
    8000136c:	c9848493          	add	s1,s1,-872 # 80008000 <etext>
    80001370:	46a9                	li	a3,10
    80001372:	80007617          	auipc	a2,0x80007
    80001376:	c8e60613          	add	a2,a2,-882 # 8000 <_entry-0x7fff8000>
    8000137a:	4585                	li	a1,1
    8000137c:	05fe                	sll	a1,a1,0x1f
    8000137e:	852e                	mv	a0,a1
    80001380:	00000097          	auipc	ra,0x0
    80001384:	f38080e7          	jalr	-200(ra) # 800012b8 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001388:	4699                	li	a3,6
    8000138a:	4645                	li	a2,17
    8000138c:	066e                	sll	a2,a2,0x1b
    8000138e:	8e05                	sub	a2,a2,s1
    80001390:	85a6                	mv	a1,s1
    80001392:	8526                	mv	a0,s1
    80001394:	00000097          	auipc	ra,0x0
    80001398:	f24080e7          	jalr	-220(ra) # 800012b8 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000139c:	46a9                	li	a3,10
    8000139e:	6605                	lui	a2,0x1
    800013a0:	00006597          	auipc	a1,0x6
    800013a4:	c6058593          	add	a1,a1,-928 # 80007000 <_trampoline>
    800013a8:	04000537          	lui	a0,0x4000
    800013ac:	157d                	add	a0,a0,-1 # 3ffffff <_entry-0x7c000001>
    800013ae:	0532                	sll	a0,a0,0xc
    800013b0:	00000097          	auipc	ra,0x0
    800013b4:	f08080e7          	jalr	-248(ra) # 800012b8 <kvmmap>
}
    800013b8:	60e2                	ld	ra,24(sp)
    800013ba:	6442                	ld	s0,16(sp)
    800013bc:	64a2                	ld	s1,8(sp)
    800013be:	6105                	add	sp,sp,32
    800013c0:	8082                	ret

00000000800013c2 <ukvmmap>:
{
    800013c2:	1141                	add	sp,sp,-16
    800013c4:	e406                	sd	ra,8(sp)
    800013c6:	e022                	sd	s0,0(sp)
    800013c8:	0800                	add	s0,sp,16
    800013ca:	87b6                	mv	a5,a3
  if(mappages(ukpagetable, va, sz, pa, perm) != 0)
    800013cc:	86b2                	mv	a3,a2
    800013ce:	863e                	mv	a2,a5
    800013d0:	00000097          	auipc	ra,0x0
    800013d4:	e5a080e7          	jalr	-422(ra) # 8000122a <mappages>
    800013d8:	e509                	bnez	a0,800013e2 <ukvmmap+0x20>
}
    800013da:	60a2                	ld	ra,8(sp)
    800013dc:	6402                	ld	s0,0(sp)
    800013de:	0141                	add	sp,sp,16
    800013e0:	8082                	ret
    panic("kvmmap");
    800013e2:	00007517          	auipc	a0,0x7
    800013e6:	d2e50513          	add	a0,a0,-722 # 80008110 <digits+0xe0>
    800013ea:	fffff097          	auipc	ra,0xfffff
    800013ee:	158080e7          	jalr	344(ra) # 80000542 <panic>

00000000800013f2 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800013f2:	715d                	add	sp,sp,-80
    800013f4:	e486                	sd	ra,72(sp)
    800013f6:	e0a2                	sd	s0,64(sp)
    800013f8:	fc26                	sd	s1,56(sp)
    800013fa:	f84a                	sd	s2,48(sp)
    800013fc:	f44e                	sd	s3,40(sp)
    800013fe:	f052                	sd	s4,32(sp)
    80001400:	ec56                	sd	s5,24(sp)
    80001402:	e85a                	sd	s6,16(sp)
    80001404:	e45e                	sd	s7,8(sp)
    80001406:	0880                	add	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001408:	03459793          	sll	a5,a1,0x34
    8000140c:	e795                	bnez	a5,80001438 <uvmunmap+0x46>
    8000140e:	8a2a                	mv	s4,a0
    80001410:	892e                	mv	s2,a1
    80001412:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001414:	0632                	sll	a2,a2,0xc
    80001416:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000141a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000141c:	6b05                	lui	s6,0x1
    8000141e:	0735e263          	bltu	a1,s3,80001482 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001422:	60a6                	ld	ra,72(sp)
    80001424:	6406                	ld	s0,64(sp)
    80001426:	74e2                	ld	s1,56(sp)
    80001428:	7942                	ld	s2,48(sp)
    8000142a:	79a2                	ld	s3,40(sp)
    8000142c:	7a02                	ld	s4,32(sp)
    8000142e:	6ae2                	ld	s5,24(sp)
    80001430:	6b42                	ld	s6,16(sp)
    80001432:	6ba2                	ld	s7,8(sp)
    80001434:	6161                	add	sp,sp,80
    80001436:	8082                	ret
    panic("uvmunmap: not aligned");
    80001438:	00007517          	auipc	a0,0x7
    8000143c:	ce050513          	add	a0,a0,-800 # 80008118 <digits+0xe8>
    80001440:	fffff097          	auipc	ra,0xfffff
    80001444:	102080e7          	jalr	258(ra) # 80000542 <panic>
      panic("uvmunmap: walk");
    80001448:	00007517          	auipc	a0,0x7
    8000144c:	ce850513          	add	a0,a0,-792 # 80008130 <digits+0x100>
    80001450:	fffff097          	auipc	ra,0xfffff
    80001454:	0f2080e7          	jalr	242(ra) # 80000542 <panic>
      panic("uvmunmap: not mapped");
    80001458:	00007517          	auipc	a0,0x7
    8000145c:	ce850513          	add	a0,a0,-792 # 80008140 <digits+0x110>
    80001460:	fffff097          	auipc	ra,0xfffff
    80001464:	0e2080e7          	jalr	226(ra) # 80000542 <panic>
      panic("uvmunmap: not a leaf");
    80001468:	00007517          	auipc	a0,0x7
    8000146c:	cf050513          	add	a0,a0,-784 # 80008158 <digits+0x128>
    80001470:	fffff097          	auipc	ra,0xfffff
    80001474:	0d2080e7          	jalr	210(ra) # 80000542 <panic>
    *pte = 0;
    80001478:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000147c:	995a                	add	s2,s2,s6
    8000147e:	fb3972e3          	bgeu	s2,s3,80001422 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001482:	4601                	li	a2,0
    80001484:	85ca                	mv	a1,s2
    80001486:	8552                	mv	a0,s4
    80001488:	00000097          	auipc	ra,0x0
    8000148c:	c54080e7          	jalr	-940(ra) # 800010dc <walk>
    80001490:	84aa                	mv	s1,a0
    80001492:	d95d                	beqz	a0,80001448 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001494:	6108                	ld	a0,0(a0)
    80001496:	00157793          	and	a5,a0,1
    8000149a:	dfdd                	beqz	a5,80001458 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000149c:	3ff57793          	and	a5,a0,1023
    800014a0:	fd7784e3          	beq	a5,s7,80001468 <uvmunmap+0x76>
    if(do_free){
    800014a4:	fc0a8ae3          	beqz	s5,80001478 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800014a8:	8129                	srl	a0,a0,0xa
      kfree((void*)pa);
    800014aa:	0532                	sll	a0,a0,0xc
    800014ac:	fffff097          	auipc	ra,0xfffff
    800014b0:	562080e7          	jalr	1378(ra) # 80000a0e <kfree>
    800014b4:	b7d1                	j	80001478 <uvmunmap+0x86>

00000000800014b6 <u2kvmcopy>:
int u2kvmcopy(pagetable_t upagetable, pagetable_t kpagetable, uint64 begin, uint64 end) {
    800014b6:	7139                	add	sp,sp,-64
    800014b8:	fc06                	sd	ra,56(sp)
    800014ba:	f822                	sd	s0,48(sp)
    800014bc:	f426                	sd	s1,40(sp)
    800014be:	f04a                	sd	s2,32(sp)
    800014c0:	ec4e                	sd	s3,24(sp)
    800014c2:	e852                	sd	s4,16(sp)
    800014c4:	e456                	sd	s5,8(sp)
    800014c6:	0080                	add	s0,sp,64
    uint64 begin_page = PGROUNDUP(begin);    // 向上取整
    800014c8:	6785                	lui	a5,0x1
    800014ca:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014cc:	963e                	add	a2,a2,a5
    800014ce:	77fd                	lui	a5,0xfffff
    800014d0:	00f67a33          	and	s4,a2,a5
    for(i = begin_page; i < end; i += PGSIZE){
    800014d4:	08da7863          	bgeu	s4,a3,80001564 <u2kvmcopy+0xae>
    800014d8:	8aaa                	mv	s5,a0
    800014da:	89ae                	mv	s3,a1
    800014dc:	8936                	mv	s2,a3
    800014de:	84d2                	mv	s1,s4
        if((pte = walk(upagetable, i, 0)) == 0)
    800014e0:	4601                	li	a2,0
    800014e2:	85a6                	mv	a1,s1
    800014e4:	8556                	mv	a0,s5
    800014e6:	00000097          	auipc	ra,0x0
    800014ea:	bf6080e7          	jalr	-1034(ra) # 800010dc <walk>
    800014ee:	c51d                	beqz	a0,8000151c <u2kvmcopy+0x66>
        if((*pte & PTE_V) == 0)
    800014f0:	6118                	ld	a4,0(a0)
    800014f2:	00177793          	and	a5,a4,1
    800014f6:	cb9d                	beqz	a5,8000152c <u2kvmcopy+0x76>
        pa = PTE2PA(*pte);
    800014f8:	00a75693          	srl	a3,a4,0xa
        if(mappages(kpagetable, i, PGSIZE, pa, flags) != 0){
    800014fc:	3ef77713          	and	a4,a4,1007
    80001500:	06b2                	sll	a3,a3,0xc
    80001502:	6605                	lui	a2,0x1
    80001504:	85a6                	mv	a1,s1
    80001506:	854e                	mv	a0,s3
    80001508:	00000097          	auipc	ra,0x0
    8000150c:	d22080e7          	jalr	-734(ra) # 8000122a <mappages>
    80001510:	e515                	bnez	a0,8000153c <u2kvmcopy+0x86>
    for(i = begin_page; i < end; i += PGSIZE){
    80001512:	6785                	lui	a5,0x1
    80001514:	94be                	add	s1,s1,a5
    80001516:	fd24e5e3          	bltu	s1,s2,800014e0 <u2kvmcopy+0x2a>
    8000151a:	a825                	j	80001552 <u2kvmcopy+0x9c>
            panic("uvmcopy2kvm: pte should exist");
    8000151c:	00007517          	auipc	a0,0x7
    80001520:	c5450513          	add	a0,a0,-940 # 80008170 <digits+0x140>
    80001524:	fffff097          	auipc	ra,0xfffff
    80001528:	01e080e7          	jalr	30(ra) # 80000542 <panic>
            panic("uvmcopy2kvm: page not present");
    8000152c:	00007517          	auipc	a0,0x7
    80001530:	c6450513          	add	a0,a0,-924 # 80008190 <digits+0x160>
    80001534:	fffff097          	auipc	ra,0xfffff
    80001538:	00e080e7          	jalr	14(ra) # 80000542 <panic>
    uvmunmap(kpagetable, begin_page, (i- begin_page) / PGSIZE, 0);
    8000153c:	41448633          	sub	a2,s1,s4
    80001540:	4681                	li	a3,0
    80001542:	8231                	srl	a2,a2,0xc
    80001544:	85d2                	mv	a1,s4
    80001546:	854e                	mv	a0,s3
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	eaa080e7          	jalr	-342(ra) # 800013f2 <uvmunmap>
    return -1;
    80001550:	557d                	li	a0,-1
}
    80001552:	70e2                	ld	ra,56(sp)
    80001554:	7442                	ld	s0,48(sp)
    80001556:	74a2                	ld	s1,40(sp)
    80001558:	7902                	ld	s2,32(sp)
    8000155a:	69e2                	ld	s3,24(sp)
    8000155c:	6a42                	ld	s4,16(sp)
    8000155e:	6aa2                	ld	s5,8(sp)
    80001560:	6121                	add	sp,sp,64
    80001562:	8082                	ret
    return 0;
    80001564:	4501                	li	a0,0
    80001566:	b7f5                	j	80001552 <u2kvmcopy+0x9c>

0000000080001568 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001568:	1101                	add	sp,sp,-32
    8000156a:	ec06                	sd	ra,24(sp)
    8000156c:	e822                	sd	s0,16(sp)
    8000156e:	e426                	sd	s1,8(sp)
    80001570:	1000                	add	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001572:	fffff097          	auipc	ra,0xfffff
    80001576:	59a080e7          	jalr	1434(ra) # 80000b0c <kalloc>
    8000157a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000157c:	c519                	beqz	a0,8000158a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000157e:	6605                	lui	a2,0x1
    80001580:	4581                	li	a1,0
    80001582:	fffff097          	auipc	ra,0xfffff
    80001586:	776080e7          	jalr	1910(ra) # 80000cf8 <memset>
  return pagetable;
}
    8000158a:	8526                	mv	a0,s1
    8000158c:	60e2                	ld	ra,24(sp)
    8000158e:	6442                	ld	s0,16(sp)
    80001590:	64a2                	ld	s1,8(sp)
    80001592:	6105                	add	sp,sp,32
    80001594:	8082                	ret

0000000080001596 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001596:	7179                	add	sp,sp,-48
    80001598:	f406                	sd	ra,40(sp)
    8000159a:	f022                	sd	s0,32(sp)
    8000159c:	ec26                	sd	s1,24(sp)
    8000159e:	e84a                	sd	s2,16(sp)
    800015a0:	e44e                	sd	s3,8(sp)
    800015a2:	e052                	sd	s4,0(sp)
    800015a4:	1800                	add	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800015a6:	6785                	lui	a5,0x1
    800015a8:	04f67863          	bgeu	a2,a5,800015f8 <uvminit+0x62>
    800015ac:	8a2a                	mv	s4,a0
    800015ae:	89ae                	mv	s3,a1
    800015b0:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	55a080e7          	jalr	1370(ra) # 80000b0c <kalloc>
    800015ba:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800015bc:	6605                	lui	a2,0x1
    800015be:	4581                	li	a1,0
    800015c0:	fffff097          	auipc	ra,0xfffff
    800015c4:	738080e7          	jalr	1848(ra) # 80000cf8 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800015c8:	4779                	li	a4,30
    800015ca:	86ca                	mv	a3,s2
    800015cc:	6605                	lui	a2,0x1
    800015ce:	4581                	li	a1,0
    800015d0:	8552                	mv	a0,s4
    800015d2:	00000097          	auipc	ra,0x0
    800015d6:	c58080e7          	jalr	-936(ra) # 8000122a <mappages>
  memmove(mem, src, sz);
    800015da:	8626                	mv	a2,s1
    800015dc:	85ce                	mv	a1,s3
    800015de:	854a                	mv	a0,s2
    800015e0:	fffff097          	auipc	ra,0xfffff
    800015e4:	774080e7          	jalr	1908(ra) # 80000d54 <memmove>
}
    800015e8:	70a2                	ld	ra,40(sp)
    800015ea:	7402                	ld	s0,32(sp)
    800015ec:	64e2                	ld	s1,24(sp)
    800015ee:	6942                	ld	s2,16(sp)
    800015f0:	69a2                	ld	s3,8(sp)
    800015f2:	6a02                	ld	s4,0(sp)
    800015f4:	6145                	add	sp,sp,48
    800015f6:	8082                	ret
    panic("inituvm: more than a page");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb850513          	add	a0,a0,-1096 # 800081b0 <digits+0x180>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f42080e7          	jalr	-190(ra) # 80000542 <panic>

0000000080001608 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001608:	1101                	add	sp,sp,-32
    8000160a:	ec06                	sd	ra,24(sp)
    8000160c:	e822                	sd	s0,16(sp)
    8000160e:	e426                	sd	s1,8(sp)
    80001610:	1000                	add	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001612:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001614:	00b67d63          	bgeu	a2,a1,8000162e <uvmdealloc+0x26>
    80001618:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000161a:	6785                	lui	a5,0x1
    8000161c:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000161e:	00f60733          	add	a4,a2,a5
    80001622:	76fd                	lui	a3,0xfffff
    80001624:	8f75                	and	a4,a4,a3
    80001626:	97ae                	add	a5,a5,a1
    80001628:	8ff5                	and	a5,a5,a3
    8000162a:	00f76863          	bltu	a4,a5,8000163a <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000162e:	8526                	mv	a0,s1
    80001630:	60e2                	ld	ra,24(sp)
    80001632:	6442                	ld	s0,16(sp)
    80001634:	64a2                	ld	s1,8(sp)
    80001636:	6105                	add	sp,sp,32
    80001638:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000163a:	8f99                	sub	a5,a5,a4
    8000163c:	83b1                	srl	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000163e:	4685                	li	a3,1
    80001640:	0007861b          	sext.w	a2,a5
    80001644:	85ba                	mv	a1,a4
    80001646:	00000097          	auipc	ra,0x0
    8000164a:	dac080e7          	jalr	-596(ra) # 800013f2 <uvmunmap>
    8000164e:	b7c5                	j	8000162e <uvmdealloc+0x26>

0000000080001650 <uvmalloc>:
  if(newsz < oldsz)
    80001650:	0ab66163          	bltu	a2,a1,800016f2 <uvmalloc+0xa2>
{
    80001654:	7139                	add	sp,sp,-64
    80001656:	fc06                	sd	ra,56(sp)
    80001658:	f822                	sd	s0,48(sp)
    8000165a:	f426                	sd	s1,40(sp)
    8000165c:	f04a                	sd	s2,32(sp)
    8000165e:	ec4e                	sd	s3,24(sp)
    80001660:	e852                	sd	s4,16(sp)
    80001662:	e456                	sd	s5,8(sp)
    80001664:	0080                	add	s0,sp,64
    80001666:	8aaa                	mv	s5,a0
    80001668:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000166a:	6785                	lui	a5,0x1
    8000166c:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000166e:	95be                	add	a1,a1,a5
    80001670:	77fd                	lui	a5,0xfffff
    80001672:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001676:	08c9f063          	bgeu	s3,a2,800016f6 <uvmalloc+0xa6>
    8000167a:	894e                	mv	s2,s3
    mem = kalloc();
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	490080e7          	jalr	1168(ra) # 80000b0c <kalloc>
    80001684:	84aa                	mv	s1,a0
    if(mem == 0){
    80001686:	c51d                	beqz	a0,800016b4 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001688:	6605                	lui	a2,0x1
    8000168a:	4581                	li	a1,0
    8000168c:	fffff097          	auipc	ra,0xfffff
    80001690:	66c080e7          	jalr	1644(ra) # 80000cf8 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001694:	4779                	li	a4,30
    80001696:	86a6                	mv	a3,s1
    80001698:	6605                	lui	a2,0x1
    8000169a:	85ca                	mv	a1,s2
    8000169c:	8556                	mv	a0,s5
    8000169e:	00000097          	auipc	ra,0x0
    800016a2:	b8c080e7          	jalr	-1140(ra) # 8000122a <mappages>
    800016a6:	e905                	bnez	a0,800016d6 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800016a8:	6785                	lui	a5,0x1
    800016aa:	993e                	add	s2,s2,a5
    800016ac:	fd4968e3          	bltu	s2,s4,8000167c <uvmalloc+0x2c>
  return newsz;
    800016b0:	8552                	mv	a0,s4
    800016b2:	a809                	j	800016c4 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800016b4:	864e                	mv	a2,s3
    800016b6:	85ca                	mv	a1,s2
    800016b8:	8556                	mv	a0,s5
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	f4e080e7          	jalr	-178(ra) # 80001608 <uvmdealloc>
      return 0;
    800016c2:	4501                	li	a0,0
}
    800016c4:	70e2                	ld	ra,56(sp)
    800016c6:	7442                	ld	s0,48(sp)
    800016c8:	74a2                	ld	s1,40(sp)
    800016ca:	7902                	ld	s2,32(sp)
    800016cc:	69e2                	ld	s3,24(sp)
    800016ce:	6a42                	ld	s4,16(sp)
    800016d0:	6aa2                	ld	s5,8(sp)
    800016d2:	6121                	add	sp,sp,64
    800016d4:	8082                	ret
      kfree(mem);
    800016d6:	8526                	mv	a0,s1
    800016d8:	fffff097          	auipc	ra,0xfffff
    800016dc:	336080e7          	jalr	822(ra) # 80000a0e <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800016e0:	864e                	mv	a2,s3
    800016e2:	85ca                	mv	a1,s2
    800016e4:	8556                	mv	a0,s5
    800016e6:	00000097          	auipc	ra,0x0
    800016ea:	f22080e7          	jalr	-222(ra) # 80001608 <uvmdealloc>
      return 0;
    800016ee:	4501                	li	a0,0
    800016f0:	bfd1                	j	800016c4 <uvmalloc+0x74>
    return oldsz;
    800016f2:	852e                	mv	a0,a1
}
    800016f4:	8082                	ret
  return newsz;
    800016f6:	8532                	mv	a0,a2
    800016f8:	b7f1                	j	800016c4 <uvmalloc+0x74>

00000000800016fa <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800016fa:	7179                	add	sp,sp,-48
    800016fc:	f406                	sd	ra,40(sp)
    800016fe:	f022                	sd	s0,32(sp)
    80001700:	ec26                	sd	s1,24(sp)
    80001702:	e84a                	sd	s2,16(sp)
    80001704:	e44e                	sd	s3,8(sp)
    80001706:	e052                	sd	s4,0(sp)
    80001708:	1800                	add	s0,sp,48
    8000170a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000170c:	84aa                	mv	s1,a0
    8000170e:	6905                	lui	s2,0x1
    80001710:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001712:	4985                	li	s3,1
    80001714:	a829                	j	8000172e <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001716:	83a9                	srl	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001718:	00c79513          	sll	a0,a5,0xc
    8000171c:	00000097          	auipc	ra,0x0
    80001720:	fde080e7          	jalr	-34(ra) # 800016fa <freewalk>
      pagetable[i] = 0;
    80001724:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001728:	04a1                	add	s1,s1,8
    8000172a:	03248163          	beq	s1,s2,8000174c <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000172e:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001730:	00f7f713          	and	a4,a5,15
    80001734:	ff3701e3          	beq	a4,s3,80001716 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001738:	8b85                	and	a5,a5,1
    8000173a:	d7fd                	beqz	a5,80001728 <freewalk+0x2e>
      panic("freewalk: leaf");
    8000173c:	00007517          	auipc	a0,0x7
    80001740:	a9450513          	add	a0,a0,-1388 # 800081d0 <digits+0x1a0>
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	dfe080e7          	jalr	-514(ra) # 80000542 <panic>
    }
  }
  kfree((void*)pagetable);
    8000174c:	8552                	mv	a0,s4
    8000174e:	fffff097          	auipc	ra,0xfffff
    80001752:	2c0080e7          	jalr	704(ra) # 80000a0e <kfree>
}
    80001756:	70a2                	ld	ra,40(sp)
    80001758:	7402                	ld	s0,32(sp)
    8000175a:	64e2                	ld	s1,24(sp)
    8000175c:	6942                	ld	s2,16(sp)
    8000175e:	69a2                	ld	s3,8(sp)
    80001760:	6a02                	ld	s4,0(sp)
    80001762:	6145                	add	sp,sp,48
    80001764:	8082                	ret

0000000080001766 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001766:	1101                	add	sp,sp,-32
    80001768:	ec06                	sd	ra,24(sp)
    8000176a:	e822                	sd	s0,16(sp)
    8000176c:	e426                	sd	s1,8(sp)
    8000176e:	1000                	add	s0,sp,32
    80001770:	84aa                	mv	s1,a0
  if(sz > 0)
    80001772:	e999                	bnez	a1,80001788 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001774:	8526                	mv	a0,s1
    80001776:	00000097          	auipc	ra,0x0
    8000177a:	f84080e7          	jalr	-124(ra) # 800016fa <freewalk>
}
    8000177e:	60e2                	ld	ra,24(sp)
    80001780:	6442                	ld	s0,16(sp)
    80001782:	64a2                	ld	s1,8(sp)
    80001784:	6105                	add	sp,sp,32
    80001786:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001788:	6785                	lui	a5,0x1
    8000178a:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000178c:	95be                	add	a1,a1,a5
    8000178e:	4685                	li	a3,1
    80001790:	00c5d613          	srl	a2,a1,0xc
    80001794:	4581                	li	a1,0
    80001796:	00000097          	auipc	ra,0x0
    8000179a:	c5c080e7          	jalr	-932(ra) # 800013f2 <uvmunmap>
    8000179e:	bfd9                	j	80001774 <uvmfree+0xe>

00000000800017a0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800017a0:	c679                	beqz	a2,8000186e <uvmcopy+0xce>
{
    800017a2:	715d                	add	sp,sp,-80
    800017a4:	e486                	sd	ra,72(sp)
    800017a6:	e0a2                	sd	s0,64(sp)
    800017a8:	fc26                	sd	s1,56(sp)
    800017aa:	f84a                	sd	s2,48(sp)
    800017ac:	f44e                	sd	s3,40(sp)
    800017ae:	f052                	sd	s4,32(sp)
    800017b0:	ec56                	sd	s5,24(sp)
    800017b2:	e85a                	sd	s6,16(sp)
    800017b4:	e45e                	sd	s7,8(sp)
    800017b6:	0880                	add	s0,sp,80
    800017b8:	8b2a                	mv	s6,a0
    800017ba:	8aae                	mv	s5,a1
    800017bc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800017be:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800017c0:	4601                	li	a2,0
    800017c2:	85ce                	mv	a1,s3
    800017c4:	855a                	mv	a0,s6
    800017c6:	00000097          	auipc	ra,0x0
    800017ca:	916080e7          	jalr	-1770(ra) # 800010dc <walk>
    800017ce:	c531                	beqz	a0,8000181a <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800017d0:	6118                	ld	a4,0(a0)
    800017d2:	00177793          	and	a5,a4,1
    800017d6:	cbb1                	beqz	a5,8000182a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800017d8:	00a75593          	srl	a1,a4,0xa
    800017dc:	00c59b93          	sll	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800017e0:	3ff77493          	and	s1,a4,1023
    if((mem = kalloc()) == 0)
    800017e4:	fffff097          	auipc	ra,0xfffff
    800017e8:	328080e7          	jalr	808(ra) # 80000b0c <kalloc>
    800017ec:	892a                	mv	s2,a0
    800017ee:	c939                	beqz	a0,80001844 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800017f0:	6605                	lui	a2,0x1
    800017f2:	85de                	mv	a1,s7
    800017f4:	fffff097          	auipc	ra,0xfffff
    800017f8:	560080e7          	jalr	1376(ra) # 80000d54 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800017fc:	8726                	mv	a4,s1
    800017fe:	86ca                	mv	a3,s2
    80001800:	6605                	lui	a2,0x1
    80001802:	85ce                	mv	a1,s3
    80001804:	8556                	mv	a0,s5
    80001806:	00000097          	auipc	ra,0x0
    8000180a:	a24080e7          	jalr	-1500(ra) # 8000122a <mappages>
    8000180e:	e515                	bnez	a0,8000183a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001810:	6785                	lui	a5,0x1
    80001812:	99be                	add	s3,s3,a5
    80001814:	fb49e6e3          	bltu	s3,s4,800017c0 <uvmcopy+0x20>
    80001818:	a081                	j	80001858 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000181a:	00007517          	auipc	a0,0x7
    8000181e:	9c650513          	add	a0,a0,-1594 # 800081e0 <digits+0x1b0>
    80001822:	fffff097          	auipc	ra,0xfffff
    80001826:	d20080e7          	jalr	-736(ra) # 80000542 <panic>
      panic("uvmcopy: page not present");
    8000182a:	00007517          	auipc	a0,0x7
    8000182e:	9d650513          	add	a0,a0,-1578 # 80008200 <digits+0x1d0>
    80001832:	fffff097          	auipc	ra,0xfffff
    80001836:	d10080e7          	jalr	-752(ra) # 80000542 <panic>
      kfree(mem);
    8000183a:	854a                	mv	a0,s2
    8000183c:	fffff097          	auipc	ra,0xfffff
    80001840:	1d2080e7          	jalr	466(ra) # 80000a0e <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001844:	4685                	li	a3,1
    80001846:	00c9d613          	srl	a2,s3,0xc
    8000184a:	4581                	li	a1,0
    8000184c:	8556                	mv	a0,s5
    8000184e:	00000097          	auipc	ra,0x0
    80001852:	ba4080e7          	jalr	-1116(ra) # 800013f2 <uvmunmap>
  return -1;
    80001856:	557d                	li	a0,-1
}
    80001858:	60a6                	ld	ra,72(sp)
    8000185a:	6406                	ld	s0,64(sp)
    8000185c:	74e2                	ld	s1,56(sp)
    8000185e:	7942                	ld	s2,48(sp)
    80001860:	79a2                	ld	s3,40(sp)
    80001862:	7a02                	ld	s4,32(sp)
    80001864:	6ae2                	ld	s5,24(sp)
    80001866:	6b42                	ld	s6,16(sp)
    80001868:	6ba2                	ld	s7,8(sp)
    8000186a:	6161                	add	sp,sp,80
    8000186c:	8082                	ret
  return 0;
    8000186e:	4501                	li	a0,0
}
    80001870:	8082                	ret

0000000080001872 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001872:	1141                	add	sp,sp,-16
    80001874:	e406                	sd	ra,8(sp)
    80001876:	e022                	sd	s0,0(sp)
    80001878:	0800                	add	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000187a:	4601                	li	a2,0
    8000187c:	00000097          	auipc	ra,0x0
    80001880:	860080e7          	jalr	-1952(ra) # 800010dc <walk>
  if(pte == 0)
    80001884:	c901                	beqz	a0,80001894 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001886:	611c                	ld	a5,0(a0)
    80001888:	9bbd                	and	a5,a5,-17
    8000188a:	e11c                	sd	a5,0(a0)
}
    8000188c:	60a2                	ld	ra,8(sp)
    8000188e:	6402                	ld	s0,0(sp)
    80001890:	0141                	add	sp,sp,16
    80001892:	8082                	ret
    panic("uvmclear");
    80001894:	00007517          	auipc	a0,0x7
    80001898:	98c50513          	add	a0,a0,-1652 # 80008220 <digits+0x1f0>
    8000189c:	fffff097          	auipc	ra,0xfffff
    800018a0:	ca6080e7          	jalr	-858(ra) # 80000542 <panic>

00000000800018a4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800018a4:	c6bd                	beqz	a3,80001912 <copyout+0x6e>
{
    800018a6:	715d                	add	sp,sp,-80
    800018a8:	e486                	sd	ra,72(sp)
    800018aa:	e0a2                	sd	s0,64(sp)
    800018ac:	fc26                	sd	s1,56(sp)
    800018ae:	f84a                	sd	s2,48(sp)
    800018b0:	f44e                	sd	s3,40(sp)
    800018b2:	f052                	sd	s4,32(sp)
    800018b4:	ec56                	sd	s5,24(sp)
    800018b6:	e85a                	sd	s6,16(sp)
    800018b8:	e45e                	sd	s7,8(sp)
    800018ba:	e062                	sd	s8,0(sp)
    800018bc:	0880                	add	s0,sp,80
    800018be:	8b2a                	mv	s6,a0
    800018c0:	8c2e                	mv	s8,a1
    800018c2:	8a32                	mv	s4,a2
    800018c4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800018c6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800018c8:	6a85                	lui	s5,0x1
    800018ca:	a015                	j	800018ee <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800018cc:	9562                	add	a0,a0,s8
    800018ce:	0004861b          	sext.w	a2,s1
    800018d2:	85d2                	mv	a1,s4
    800018d4:	41250533          	sub	a0,a0,s2
    800018d8:	fffff097          	auipc	ra,0xfffff
    800018dc:	47c080e7          	jalr	1148(ra) # 80000d54 <memmove>

    len -= n;
    800018e0:	409989b3          	sub	s3,s3,s1
    src += n;
    800018e4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800018e6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800018ea:	02098263          	beqz	s3,8000190e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800018ee:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800018f2:	85ca                	mv	a1,s2
    800018f4:	855a                	mv	a0,s6
    800018f6:	00000097          	auipc	ra,0x0
    800018fa:	88c080e7          	jalr	-1908(ra) # 80001182 <walkaddr>
    if(pa0 == 0)
    800018fe:	cd01                	beqz	a0,80001916 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001900:	418904b3          	sub	s1,s2,s8
    80001904:	94d6                	add	s1,s1,s5
    80001906:	fc99f3e3          	bgeu	s3,s1,800018cc <copyout+0x28>
    8000190a:	84ce                	mv	s1,s3
    8000190c:	b7c1                	j	800018cc <copyout+0x28>
  }
  return 0;
    8000190e:	4501                	li	a0,0
    80001910:	a021                	j	80001918 <copyout+0x74>
    80001912:	4501                	li	a0,0
}
    80001914:	8082                	ret
      return -1;
    80001916:	557d                	li	a0,-1
}
    80001918:	60a6                	ld	ra,72(sp)
    8000191a:	6406                	ld	s0,64(sp)
    8000191c:	74e2                	ld	s1,56(sp)
    8000191e:	7942                	ld	s2,48(sp)
    80001920:	79a2                	ld	s3,40(sp)
    80001922:	7a02                	ld	s4,32(sp)
    80001924:	6ae2                	ld	s5,24(sp)
    80001926:	6b42                	ld	s6,16(sp)
    80001928:	6ba2                	ld	s7,8(sp)
    8000192a:	6c02                	ld	s8,0(sp)
    8000192c:	6161                	add	sp,sp,80
    8000192e:	8082                	ret

0000000080001930 <copyin>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    80001930:	1141                	add	sp,sp,-16
    80001932:	e406                	sd	ra,8(sp)
    80001934:	e022                	sd	s0,0(sp)
    80001936:	0800                	add	s0,sp,16
  return copyin_new(pagetable,dst,srcva,len);
    80001938:	00005097          	auipc	ra,0x5
    8000193c:	b40080e7          	jalr	-1216(ra) # 80006478 <copyin_new>
}
    80001940:	60a2                	ld	ra,8(sp)
    80001942:	6402                	ld	s0,0(sp)
    80001944:	0141                	add	sp,sp,16
    80001946:	8082                	ret

0000000080001948 <copyinstr>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80001948:	1141                	add	sp,sp,-16
    8000194a:	e406                	sd	ra,8(sp)
    8000194c:	e022                	sd	s0,0(sp)
    8000194e:	0800                	add	s0,sp,16
  return copyinstr_new(pagetable,dst,srcva,max);
    80001950:	00005097          	auipc	ra,0x5
    80001954:	b90080e7          	jalr	-1136(ra) # 800064e0 <copyinstr_new>
}
    80001958:	60a2                	ld	ra,8(sp)
    8000195a:	6402                	ld	s0,0(sp)
    8000195c:	0141                	add	sp,sp,16
    8000195e:	8082                	ret

0000000080001960 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001960:	1101                	add	sp,sp,-32
    80001962:	ec06                	sd	ra,24(sp)
    80001964:	e822                	sd	s0,16(sp)
    80001966:	e426                	sd	s1,8(sp)
    80001968:	1000                	add	s0,sp,32
    8000196a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000196c:	fffff097          	auipc	ra,0xfffff
    80001970:	216080e7          	jalr	534(ra) # 80000b82 <holding>
    80001974:	c909                	beqz	a0,80001986 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001976:	749c                	ld	a5,40(s1)
    80001978:	00978f63          	beq	a5,s1,80001996 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    8000197c:	60e2                	ld	ra,24(sp)
    8000197e:	6442                	ld	s0,16(sp)
    80001980:	64a2                	ld	s1,8(sp)
    80001982:	6105                	add	sp,sp,32
    80001984:	8082                	ret
    panic("wakeup1");
    80001986:	00007517          	auipc	a0,0x7
    8000198a:	8aa50513          	add	a0,a0,-1878 # 80008230 <digits+0x200>
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	bb4080e7          	jalr	-1100(ra) # 80000542 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001996:	4c98                	lw	a4,24(s1)
    80001998:	4785                	li	a5,1
    8000199a:	fef711e3          	bne	a4,a5,8000197c <wakeup1+0x1c>
    p->state = RUNNABLE;
    8000199e:	4789                	li	a5,2
    800019a0:	cc9c                	sw	a5,24(s1)
}
    800019a2:	bfe9                	j	8000197c <wakeup1+0x1c>

00000000800019a4 <procinit>:
{
    800019a4:	7179                	add	sp,sp,-48
    800019a6:	f406                	sd	ra,40(sp)
    800019a8:	f022                	sd	s0,32(sp)
    800019aa:	ec26                	sd	s1,24(sp)
    800019ac:	e84a                	sd	s2,16(sp)
    800019ae:	e44e                	sd	s3,8(sp)
    800019b0:	1800                	add	s0,sp,48
  initlock(&pid_lock, "nextpid");
    800019b2:	00007597          	auipc	a1,0x7
    800019b6:	88658593          	add	a1,a1,-1914 # 80008238 <digits+0x208>
    800019ba:	00010517          	auipc	a0,0x10
    800019be:	f9650513          	add	a0,a0,-106 # 80011950 <pid_lock>
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	1aa080e7          	jalr	426(ra) # 80000b6c <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ca:	00010497          	auipc	s1,0x10
    800019ce:	39e48493          	add	s1,s1,926 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    800019d2:	00007997          	auipc	s3,0x7
    800019d6:	86e98993          	add	s3,s3,-1938 # 80008240 <digits+0x210>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019da:	00016917          	auipc	s2,0x16
    800019de:	f8e90913          	add	s2,s2,-114 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    800019e2:	85ce                	mv	a1,s3
    800019e4:	8526                	mv	a0,s1
    800019e6:	fffff097          	auipc	ra,0xfffff
    800019ea:	186080e7          	jalr	390(ra) # 80000b6c <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ee:	17048493          	add	s1,s1,368
    800019f2:	ff2498e3          	bne	s1,s2,800019e2 <procinit+0x3e>
  kvminithart();
    800019f6:	fffff097          	auipc	ra,0xfffff
    800019fa:	6c2080e7          	jalr	1730(ra) # 800010b8 <kvminithart>
}
    800019fe:	70a2                	ld	ra,40(sp)
    80001a00:	7402                	ld	s0,32(sp)
    80001a02:	64e2                	ld	s1,24(sp)
    80001a04:	6942                	ld	s2,16(sp)
    80001a06:	69a2                	ld	s3,8(sp)
    80001a08:	6145                	add	sp,sp,48
    80001a0a:	8082                	ret

0000000080001a0c <cpuid>:
{
    80001a0c:	1141                	add	sp,sp,-16
    80001a0e:	e422                	sd	s0,8(sp)
    80001a10:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a12:	8512                	mv	a0,tp
}
    80001a14:	2501                	sext.w	a0,a0
    80001a16:	6422                	ld	s0,8(sp)
    80001a18:	0141                	add	sp,sp,16
    80001a1a:	8082                	ret

0000000080001a1c <mycpu>:
mycpu(void) {
    80001a1c:	1141                	add	sp,sp,-16
    80001a1e:	e422                	sd	s0,8(sp)
    80001a20:	0800                	add	s0,sp,16
    80001a22:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a24:	2781                	sext.w	a5,a5
    80001a26:	079e                	sll	a5,a5,0x7
}
    80001a28:	00010517          	auipc	a0,0x10
    80001a2c:	f4050513          	add	a0,a0,-192 # 80011968 <cpus>
    80001a30:	953e                	add	a0,a0,a5
    80001a32:	6422                	ld	s0,8(sp)
    80001a34:	0141                	add	sp,sp,16
    80001a36:	8082                	ret

0000000080001a38 <myproc>:
myproc(void) {
    80001a38:	1101                	add	sp,sp,-32
    80001a3a:	ec06                	sd	ra,24(sp)
    80001a3c:	e822                	sd	s0,16(sp)
    80001a3e:	e426                	sd	s1,8(sp)
    80001a40:	1000                	add	s0,sp,32
  push_off();
    80001a42:	fffff097          	auipc	ra,0xfffff
    80001a46:	16e080e7          	jalr	366(ra) # 80000bb0 <push_off>
    80001a4a:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a4c:	2781                	sext.w	a5,a5
    80001a4e:	079e                	sll	a5,a5,0x7
    80001a50:	00010717          	auipc	a4,0x10
    80001a54:	f0070713          	add	a4,a4,-256 # 80011950 <pid_lock>
    80001a58:	97ba                	add	a5,a5,a4
    80001a5a:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a5c:	fffff097          	auipc	ra,0xfffff
    80001a60:	1f4080e7          	jalr	500(ra) # 80000c50 <pop_off>
}
    80001a64:	8526                	mv	a0,s1
    80001a66:	60e2                	ld	ra,24(sp)
    80001a68:	6442                	ld	s0,16(sp)
    80001a6a:	64a2                	ld	s1,8(sp)
    80001a6c:	6105                	add	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <forkret>:
{
    80001a70:	1141                	add	sp,sp,-16
    80001a72:	e406                	sd	ra,8(sp)
    80001a74:	e022                	sd	s0,0(sp)
    80001a76:	0800                	add	s0,sp,16
  release(&myproc()->lock);
    80001a78:	00000097          	auipc	ra,0x0
    80001a7c:	fc0080e7          	jalr	-64(ra) # 80001a38 <myproc>
    80001a80:	fffff097          	auipc	ra,0xfffff
    80001a84:	230080e7          	jalr	560(ra) # 80000cb0 <release>
  if (first) {
    80001a88:	00007797          	auipc	a5,0x7
    80001a8c:	e287a783          	lw	a5,-472(a5) # 800088b0 <first.1>
    80001a90:	eb89                	bnez	a5,80001aa2 <forkret+0x32>
  usertrapret();
    80001a92:	00001097          	auipc	ra,0x1
    80001a96:	e82080e7          	jalr	-382(ra) # 80002914 <usertrapret>
}
    80001a9a:	60a2                	ld	ra,8(sp)
    80001a9c:	6402                	ld	s0,0(sp)
    80001a9e:	0141                	add	sp,sp,16
    80001aa0:	8082                	ret
    first = 0;
    80001aa2:	00007797          	auipc	a5,0x7
    80001aa6:	e007a723          	sw	zero,-498(a5) # 800088b0 <first.1>
    fsinit(ROOTDEV);
    80001aaa:	4505                	li	a0,1
    80001aac:	00002097          	auipc	ra,0x2
    80001ab0:	baa080e7          	jalr	-1110(ra) # 80003656 <fsinit>
    80001ab4:	bff9                	j	80001a92 <forkret+0x22>

0000000080001ab6 <allocpid>:
allocpid() {
    80001ab6:	1101                	add	sp,sp,-32
    80001ab8:	ec06                	sd	ra,24(sp)
    80001aba:	e822                	sd	s0,16(sp)
    80001abc:	e426                	sd	s1,8(sp)
    80001abe:	e04a                	sd	s2,0(sp)
    80001ac0:	1000                	add	s0,sp,32
  acquire(&pid_lock);
    80001ac2:	00010917          	auipc	s2,0x10
    80001ac6:	e8e90913          	add	s2,s2,-370 # 80011950 <pid_lock>
    80001aca:	854a                	mv	a0,s2
    80001acc:	fffff097          	auipc	ra,0xfffff
    80001ad0:	130080e7          	jalr	304(ra) # 80000bfc <acquire>
  pid = nextpid;
    80001ad4:	00007797          	auipc	a5,0x7
    80001ad8:	de078793          	add	a5,a5,-544 # 800088b4 <nextpid>
    80001adc:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ade:	0014871b          	addw	a4,s1,1
    80001ae2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ae4:	854a                	mv	a0,s2
    80001ae6:	fffff097          	auipc	ra,0xfffff
    80001aea:	1ca080e7          	jalr	458(ra) # 80000cb0 <release>
}
    80001aee:	8526                	mv	a0,s1
    80001af0:	60e2                	ld	ra,24(sp)
    80001af2:	6442                	ld	s0,16(sp)
    80001af4:	64a2                	ld	s1,8(sp)
    80001af6:	6902                	ld	s2,0(sp)
    80001af8:	6105                	add	sp,sp,32
    80001afa:	8082                	ret

0000000080001afc <proc_pagetable>:
{
    80001afc:	1101                	add	sp,sp,-32
    80001afe:	ec06                	sd	ra,24(sp)
    80001b00:	e822                	sd	s0,16(sp)
    80001b02:	e426                	sd	s1,8(sp)
    80001b04:	e04a                	sd	s2,0(sp)
    80001b06:	1000                	add	s0,sp,32
    80001b08:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b0a:	00000097          	auipc	ra,0x0
    80001b0e:	a5e080e7          	jalr	-1442(ra) # 80001568 <uvmcreate>
    80001b12:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b14:	c121                	beqz	a0,80001b54 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b16:	4729                	li	a4,10
    80001b18:	00005697          	auipc	a3,0x5
    80001b1c:	4e868693          	add	a3,a3,1256 # 80007000 <_trampoline>
    80001b20:	6605                	lui	a2,0x1
    80001b22:	040005b7          	lui	a1,0x4000
    80001b26:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b28:	05b2                	sll	a1,a1,0xc
    80001b2a:	fffff097          	auipc	ra,0xfffff
    80001b2e:	700080e7          	jalr	1792(ra) # 8000122a <mappages>
    80001b32:	02054863          	bltz	a0,80001b62 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b36:	4719                	li	a4,6
    80001b38:	06093683          	ld	a3,96(s2)
    80001b3c:	6605                	lui	a2,0x1
    80001b3e:	020005b7          	lui	a1,0x2000
    80001b42:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b44:	05b6                	sll	a1,a1,0xd
    80001b46:	8526                	mv	a0,s1
    80001b48:	fffff097          	auipc	ra,0xfffff
    80001b4c:	6e2080e7          	jalr	1762(ra) # 8000122a <mappages>
    80001b50:	02054163          	bltz	a0,80001b72 <proc_pagetable+0x76>
}
    80001b54:	8526                	mv	a0,s1
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	add	sp,sp,32
    80001b60:	8082                	ret
    uvmfree(pagetable, 0);
    80001b62:	4581                	li	a1,0
    80001b64:	8526                	mv	a0,s1
    80001b66:	00000097          	auipc	ra,0x0
    80001b6a:	c00080e7          	jalr	-1024(ra) # 80001766 <uvmfree>
    return 0;
    80001b6e:	4481                	li	s1,0
    80001b70:	b7d5                	j	80001b54 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b72:	4681                	li	a3,0
    80001b74:	4605                	li	a2,1
    80001b76:	040005b7          	lui	a1,0x4000
    80001b7a:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b7c:	05b2                	sll	a1,a1,0xc
    80001b7e:	8526                	mv	a0,s1
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	872080e7          	jalr	-1934(ra) # 800013f2 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b88:	4581                	li	a1,0
    80001b8a:	8526                	mv	a0,s1
    80001b8c:	00000097          	auipc	ra,0x0
    80001b90:	bda080e7          	jalr	-1062(ra) # 80001766 <uvmfree>
    return 0;
    80001b94:	4481                	li	s1,0
    80001b96:	bf7d                	j	80001b54 <proc_pagetable+0x58>

0000000080001b98 <proc_freepagetable>:
{
    80001b98:	1101                	add	sp,sp,-32
    80001b9a:	ec06                	sd	ra,24(sp)
    80001b9c:	e822                	sd	s0,16(sp)
    80001b9e:	e426                	sd	s1,8(sp)
    80001ba0:	e04a                	sd	s2,0(sp)
    80001ba2:	1000                	add	s0,sp,32
    80001ba4:	84aa                	mv	s1,a0
    80001ba6:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ba8:	4681                	li	a3,0
    80001baa:	4605                	li	a2,1
    80001bac:	040005b7          	lui	a1,0x4000
    80001bb0:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bb2:	05b2                	sll	a1,a1,0xc
    80001bb4:	00000097          	auipc	ra,0x0
    80001bb8:	83e080e7          	jalr	-1986(ra) # 800013f2 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bbc:	4681                	li	a3,0
    80001bbe:	4605                	li	a2,1
    80001bc0:	020005b7          	lui	a1,0x2000
    80001bc4:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bc6:	05b6                	sll	a1,a1,0xd
    80001bc8:	8526                	mv	a0,s1
    80001bca:	00000097          	auipc	ra,0x0
    80001bce:	828080e7          	jalr	-2008(ra) # 800013f2 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bd2:	85ca                	mv	a1,s2
    80001bd4:	8526                	mv	a0,s1
    80001bd6:	00000097          	auipc	ra,0x0
    80001bda:	b90080e7          	jalr	-1136(ra) # 80001766 <uvmfree>
}
    80001bde:	60e2                	ld	ra,24(sp)
    80001be0:	6442                	ld	s0,16(sp)
    80001be2:	64a2                	ld	s1,8(sp)
    80001be4:	6902                	ld	s2,0(sp)
    80001be6:	6105                	add	sp,sp,32
    80001be8:	8082                	ret

0000000080001bea <proc_ukpagetable>:
proc_ukpagetable(struct proc *p) {
    80001bea:	1101                	add	sp,sp,-32
    80001bec:	ec06                	sd	ra,24(sp)
    80001bee:	e822                	sd	s0,16(sp)
    80001bf0:	e426                	sd	s1,8(sp)
    80001bf2:	e04a                	sd	s2,0(sp)
    80001bf4:	1000                	add	s0,sp,32
    pagetable_t ukpagetable = uvmcreate();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	972080e7          	jalr	-1678(ra) # 80001568 <uvmcreate>
    80001bfe:	84aa                	mv	s1,a0
    if(ukpagetable == 0){
    80001c00:	cd51                	beqz	a0,80001c9c <proc_ukpagetable+0xb2>
    ukvmmap(ukpagetable, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001c02:	4719                	li	a4,6
    80001c04:	6685                	lui	a3,0x1
    80001c06:	10000637          	lui	a2,0x10000
    80001c0a:	100005b7          	lui	a1,0x10000
    80001c0e:	fffff097          	auipc	ra,0xfffff
    80001c12:	7b4080e7          	jalr	1972(ra) # 800013c2 <ukvmmap>
    ukvmmap(ukpagetable, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001c16:	4719                	li	a4,6
    80001c18:	6685                	lui	a3,0x1
    80001c1a:	10001637          	lui	a2,0x10001
    80001c1e:	100015b7          	lui	a1,0x10001
    80001c22:	8526                	mv	a0,s1
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	79e080e7          	jalr	1950(ra) # 800013c2 <ukvmmap>
    ukvmmap(ukpagetable, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001c2c:	4719                	li	a4,6
    80001c2e:	004006b7          	lui	a3,0x400
    80001c32:	0c000637          	lui	a2,0xc000
    80001c36:	0c0005b7          	lui	a1,0xc000
    80001c3a:	8526                	mv	a0,s1
    80001c3c:	fffff097          	auipc	ra,0xfffff
    80001c40:	786080e7          	jalr	1926(ra) # 800013c2 <ukvmmap>
    ukvmmap(ukpagetable, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001c44:	00006917          	auipc	s2,0x6
    80001c48:	3bc90913          	add	s2,s2,956 # 80008000 <etext>
    80001c4c:	4729                	li	a4,10
    80001c4e:	80006697          	auipc	a3,0x80006
    80001c52:	3b268693          	add	a3,a3,946 # 8000 <_entry-0x7fff8000>
    80001c56:	4605                	li	a2,1
    80001c58:	067e                	sll	a2,a2,0x1f
    80001c5a:	85b2                	mv	a1,a2
    80001c5c:	8526                	mv	a0,s1
    80001c5e:	fffff097          	auipc	ra,0xfffff
    80001c62:	764080e7          	jalr	1892(ra) # 800013c2 <ukvmmap>
    ukvmmap(ukpagetable, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001c66:	4719                	li	a4,6
    80001c68:	46c5                	li	a3,17
    80001c6a:	06ee                	sll	a3,a3,0x1b
    80001c6c:	412686b3          	sub	a3,a3,s2
    80001c70:	864a                	mv	a2,s2
    80001c72:	85ca                	mv	a1,s2
    80001c74:	8526                	mv	a0,s1
    80001c76:	fffff097          	auipc	ra,0xfffff
    80001c7a:	74c080e7          	jalr	1868(ra) # 800013c2 <ukvmmap>
    ukvmmap(ukpagetable, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);    // 注意va为TRAMPOLINE
    80001c7e:	4729                	li	a4,10
    80001c80:	6685                	lui	a3,0x1
    80001c82:	00005617          	auipc	a2,0x5
    80001c86:	37e60613          	add	a2,a2,894 # 80007000 <_trampoline>
    80001c8a:	040005b7          	lui	a1,0x4000
    80001c8e:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c90:	05b2                	sll	a1,a1,0xc
    80001c92:	8526                	mv	a0,s1
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	72e080e7          	jalr	1838(ra) # 800013c2 <ukvmmap>
}
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	60e2                	ld	ra,24(sp)
    80001ca0:	6442                	ld	s0,16(sp)
    80001ca2:	64a2                	ld	s1,8(sp)
    80001ca4:	6902                	ld	s2,0(sp)
    80001ca6:	6105                	add	sp,sp,32
    80001ca8:	8082                	ret

0000000080001caa <proc_ukfreepagetable>:
{
    80001caa:	7179                	add	sp,sp,-48
    80001cac:	f406                	sd	ra,40(sp)
    80001cae:	f022                	sd	s0,32(sp)
    80001cb0:	ec26                	sd	s1,24(sp)
    80001cb2:	e84a                	sd	s2,16(sp)
    80001cb4:	e44e                	sd	s3,8(sp)
    80001cb6:	1800                	add	s0,sp,48
    80001cb8:	89aa                	mv	s3,a0
    for(int i = 0; i < 512; i++){
    80001cba:	84aa                	mv	s1,a0
    80001cbc:	6905                	lui	s2,0x1
    80001cbe:	992a                	add	s2,s2,a0
    80001cc0:	a021                	j	80001cc8 <proc_ukfreepagetable+0x1e>
    80001cc2:	04a1                	add	s1,s1,8
    80001cc4:	03248363          	beq	s1,s2,80001cea <proc_ukfreepagetable+0x40>
        pte_t pte = ukpagetable[i];
    80001cc8:	609c                	ld	a5,0(s1)
        if((pte & PTE_V)){
    80001cca:	0017f713          	and	a4,a5,1
    80001cce:	db75                	beqz	a4,80001cc2 <proc_ukfreepagetable+0x18>
            ukpagetable[i] = 0;    // 对于有效的PTE都清零
    80001cd0:	0004b023          	sd	zero,0(s1)
            if ((pte & (PTE_R|PTE_W|PTE_X)) == 0) {
    80001cd4:	00e7f713          	and	a4,a5,14
    80001cd8:	f76d                	bnez	a4,80001cc2 <proc_ukfreepagetable+0x18>
                uint64 child = PTE2PA(pte);
    80001cda:	83a9                	srl	a5,a5,0xa
                proc_ukfreepagetable((pagetable_t)child);
    80001cdc:	00c79513          	sll	a0,a5,0xc
    80001ce0:	00000097          	auipc	ra,0x0
    80001ce4:	fca080e7          	jalr	-54(ra) # 80001caa <proc_ukfreepagetable>
    80001ce8:	bfe9                	j	80001cc2 <proc_ukfreepagetable+0x18>
    kfree((void*)ukpagetable);
    80001cea:	854e                	mv	a0,s3
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	d22080e7          	jalr	-734(ra) # 80000a0e <kfree>
}
    80001cf4:	70a2                	ld	ra,40(sp)
    80001cf6:	7402                	ld	s0,32(sp)
    80001cf8:	64e2                	ld	s1,24(sp)
    80001cfa:	6942                	ld	s2,16(sp)
    80001cfc:	69a2                	ld	s3,8(sp)
    80001cfe:	6145                	add	sp,sp,48
    80001d00:	8082                	ret

0000000080001d02 <freeproc>:
{
    80001d02:	1101                	add	sp,sp,-32
    80001d04:	ec06                	sd	ra,24(sp)
    80001d06:	e822                	sd	s0,16(sp)
    80001d08:	e426                	sd	s1,8(sp)
    80001d0a:	1000                	add	s0,sp,32
    80001d0c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d0e:	7128                	ld	a0,96(a0)
    80001d10:	c509                	beqz	a0,80001d1a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	cfc080e7          	jalr	-772(ra) # 80000a0e <kfree>
  p->trapframe = 0;
    80001d1a:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001d1e:	68a8                	ld	a0,80(s1)
    80001d20:	c511                	beqz	a0,80001d2c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d22:	64ac                	ld	a1,72(s1)
    80001d24:	00000097          	auipc	ra,0x0
    80001d28:	e74080e7          	jalr	-396(ra) # 80001b98 <proc_freepagetable>
  p->pagetable = 0;
    80001d2c:	0404b823          	sd	zero,80(s1)
  if(p->kstack) {
    80001d30:	60ac                	ld	a1,64(s1)
    80001d32:	e1a1                	bnez	a1,80001d72 <freeproc+0x70>
  p->kstack = 0;  
    80001d34:	0404b023          	sd	zero,64(s1)
  if(p->ukpagetable)
    80001d38:	6ca8                	ld	a0,88(s1)
    80001d3a:	c509                	beqz	a0,80001d44 <freeproc+0x42>
    proc_ukfreepagetable(p->ukpagetable);
    80001d3c:	00000097          	auipc	ra,0x0
    80001d40:	f6e080e7          	jalr	-146(ra) # 80001caa <proc_ukfreepagetable>
  p->ukpagetable = 0;
    80001d44:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001d48:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d4c:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001d50:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001d54:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001d58:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001d5c:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001d60:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001d64:	0004ac23          	sw	zero,24(s1)
}
    80001d68:	60e2                	ld	ra,24(sp)
    80001d6a:	6442                	ld	s0,16(sp)
    80001d6c:	64a2                	ld	s1,8(sp)
    80001d6e:	6105                	add	sp,sp,32
    80001d70:	8082                	ret
    uvmunmap(p->ukpagetable, p->kstack, 1, 1);
    80001d72:	4685                	li	a3,1
    80001d74:	4605                	li	a2,1
    80001d76:	6ca8                	ld	a0,88(s1)
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	67a080e7          	jalr	1658(ra) # 800013f2 <uvmunmap>
    80001d80:	bf55                	j	80001d34 <freeproc+0x32>

0000000080001d82 <allocproc>:
{
    80001d82:	1101                	add	sp,sp,-32
    80001d84:	ec06                	sd	ra,24(sp)
    80001d86:	e822                	sd	s0,16(sp)
    80001d88:	e426                	sd	s1,8(sp)
    80001d8a:	e04a                	sd	s2,0(sp)
    80001d8c:	1000                	add	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d8e:	00010497          	auipc	s1,0x10
    80001d92:	fda48493          	add	s1,s1,-38 # 80011d68 <proc>
    80001d96:	00016917          	auipc	s2,0x16
    80001d9a:	bd290913          	add	s2,s2,-1070 # 80017968 <tickslock>
    acquire(&p->lock);
    80001d9e:	8526                	mv	a0,s1
    80001da0:	fffff097          	auipc	ra,0xfffff
    80001da4:	e5c080e7          	jalr	-420(ra) # 80000bfc <acquire>
    if(p->state == UNUSED) {
    80001da8:	4c9c                	lw	a5,24(s1)
    80001daa:	cf81                	beqz	a5,80001dc2 <allocproc+0x40>
      release(&p->lock);
    80001dac:	8526                	mv	a0,s1
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	f02080e7          	jalr	-254(ra) # 80000cb0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001db6:	17048493          	add	s1,s1,368
    80001dba:	ff2492e3          	bne	s1,s2,80001d9e <allocproc+0x1c>
  return 0;
    80001dbe:	4481                	li	s1,0
    80001dc0:	a061                	j	80001e48 <allocproc+0xc6>
  p->pid = allocpid();
    80001dc2:	00000097          	auipc	ra,0x0
    80001dc6:	cf4080e7          	jalr	-780(ra) # 80001ab6 <allocpid>
    80001dca:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001dcc:	fffff097          	auipc	ra,0xfffff
    80001dd0:	d40080e7          	jalr	-704(ra) # 80000b0c <kalloc>
    80001dd4:	892a                	mv	s2,a0
    80001dd6:	f0a8                	sd	a0,96(s1)
    80001dd8:	cd3d                	beqz	a0,80001e56 <allocproc+0xd4>
  p->pagetable = proc_pagetable(p);
    80001dda:	8526                	mv	a0,s1
    80001ddc:	00000097          	auipc	ra,0x0
    80001de0:	d20080e7          	jalr	-736(ra) # 80001afc <proc_pagetable>
    80001de4:	892a                	mv	s2,a0
    80001de6:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001de8:	cd35                	beqz	a0,80001e64 <allocproc+0xe2>
  p->ukpagetable = proc_ukpagetable(p);
    80001dea:	8526                	mv	a0,s1
    80001dec:	00000097          	auipc	ra,0x0
    80001df0:	dfe080e7          	jalr	-514(ra) # 80001bea <proc_ukpagetable>
    80001df4:	892a                	mv	s2,a0
    80001df6:	eca8                	sd	a0,88(s1)
  if(p->ukpagetable == 0){
    80001df8:	c151                	beqz	a0,80001e7c <allocproc+0xfa>
  char *pa = kalloc();
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	d12080e7          	jalr	-750(ra) # 80000b0c <kalloc>
    80001e02:	862a                	mv	a2,a0
  if(pa==0){
    80001e04:	c941                	beqz	a0,80001e94 <allocproc+0x112>
  ukvmmap(p->ukpagetable,va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001e06:	4719                	li	a4,6
    80001e08:	6685                	lui	a3,0x1
    80001e0a:	04000937          	lui	s2,0x4000
    80001e0e:	1975                	add	s2,s2,-3 # 3fffffd <_entry-0x7c000003>
    80001e10:	00c91593          	sll	a1,s2,0xc
    80001e14:	6ca8                	ld	a0,88(s1)
    80001e16:	fffff097          	auipc	ra,0xfffff
    80001e1a:	5ac080e7          	jalr	1452(ra) # 800013c2 <ukvmmap>
  p->kstack = va;
    80001e1e:	0932                	sll	s2,s2,0xc
    80001e20:	0524b023          	sd	s2,64(s1)
  memset(&p->context, 0, sizeof(p->context));
    80001e24:	07000613          	li	a2,112
    80001e28:	4581                	li	a1,0
    80001e2a:	06848513          	add	a0,s1,104
    80001e2e:	fffff097          	auipc	ra,0xfffff
    80001e32:	eca080e7          	jalr	-310(ra) # 80000cf8 <memset>
  p->context.ra = (uint64)forkret;
    80001e36:	00000797          	auipc	a5,0x0
    80001e3a:	c3a78793          	add	a5,a5,-966 # 80001a70 <forkret>
    80001e3e:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e40:	60bc                	ld	a5,64(s1)
    80001e42:	6705                	lui	a4,0x1
    80001e44:	97ba                	add	a5,a5,a4
    80001e46:	f8bc                	sd	a5,112(s1)
}
    80001e48:	8526                	mv	a0,s1
    80001e4a:	60e2                	ld	ra,24(sp)
    80001e4c:	6442                	ld	s0,16(sp)
    80001e4e:	64a2                	ld	s1,8(sp)
    80001e50:	6902                	ld	s2,0(sp)
    80001e52:	6105                	add	sp,sp,32
    80001e54:	8082                	ret
    release(&p->lock);
    80001e56:	8526                	mv	a0,s1
    80001e58:	fffff097          	auipc	ra,0xfffff
    80001e5c:	e58080e7          	jalr	-424(ra) # 80000cb0 <release>
    return 0;
    80001e60:	84ca                	mv	s1,s2
    80001e62:	b7dd                	j	80001e48 <allocproc+0xc6>
    freeproc(p);
    80001e64:	8526                	mv	a0,s1
    80001e66:	00000097          	auipc	ra,0x0
    80001e6a:	e9c080e7          	jalr	-356(ra) # 80001d02 <freeproc>
    release(&p->lock);
    80001e6e:	8526                	mv	a0,s1
    80001e70:	fffff097          	auipc	ra,0xfffff
    80001e74:	e40080e7          	jalr	-448(ra) # 80000cb0 <release>
    return 0;
    80001e78:	84ca                	mv	s1,s2
    80001e7a:	b7f9                	j	80001e48 <allocproc+0xc6>
    freeproc(p);
    80001e7c:	8526                	mv	a0,s1
    80001e7e:	00000097          	auipc	ra,0x0
    80001e82:	e84080e7          	jalr	-380(ra) # 80001d02 <freeproc>
    release(&p->lock);
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	e28080e7          	jalr	-472(ra) # 80000cb0 <release>
    return 0;
    80001e90:	84ca                	mv	s1,s2
    80001e92:	bf5d                	j	80001e48 <allocproc+0xc6>
    panic("kalloc");
    80001e94:	00006517          	auipc	a0,0x6
    80001e98:	3b450513          	add	a0,a0,948 # 80008248 <digits+0x218>
    80001e9c:	ffffe097          	auipc	ra,0xffffe
    80001ea0:	6a6080e7          	jalr	1702(ra) # 80000542 <panic>

0000000080001ea4 <userinit>:
{
    80001ea4:	1101                	add	sp,sp,-32
    80001ea6:	ec06                	sd	ra,24(sp)
    80001ea8:	e822                	sd	s0,16(sp)
    80001eaa:	e426                	sd	s1,8(sp)
    80001eac:	e04a                	sd	s2,0(sp)
    80001eae:	1000                	add	s0,sp,32
  p = allocproc();
    80001eb0:	00000097          	auipc	ra,0x0
    80001eb4:	ed2080e7          	jalr	-302(ra) # 80001d82 <allocproc>
    80001eb8:	84aa                	mv	s1,a0
  initproc = p;
    80001eba:	00007797          	auipc	a5,0x7
    80001ebe:	14a7bf23          	sd	a0,350(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ec2:	03400613          	li	a2,52
    80001ec6:	00007597          	auipc	a1,0x7
    80001eca:	9fa58593          	add	a1,a1,-1542 # 800088c0 <initcode>
    80001ece:	6928                	ld	a0,80(a0)
    80001ed0:	fffff097          	auipc	ra,0xfffff
    80001ed4:	6c6080e7          	jalr	1734(ra) # 80001596 <uvminit>
  p->sz = PGSIZE;
    80001ed8:	6905                	lui	s2,0x1
    80001eda:	0524b423          	sd	s2,72(s1)
  u2kvmcopy(p->pagetable, p->ukpagetable, 0, p->sz);
    80001ede:	6685                	lui	a3,0x1
    80001ee0:	4601                	li	a2,0
    80001ee2:	6cac                	ld	a1,88(s1)
    80001ee4:	68a8                	ld	a0,80(s1)
    80001ee6:	fffff097          	auipc	ra,0xfffff
    80001eea:	5d0080e7          	jalr	1488(ra) # 800014b6 <u2kvmcopy>
  p->trapframe->epc = 0;      // user program counter
    80001eee:	70bc                	ld	a5,96(s1)
    80001ef0:	0007bc23          	sd	zero,24(a5)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ef4:	70bc                	ld	a5,96(s1)
    80001ef6:	0327b823          	sd	s2,48(a5)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001efa:	4641                	li	a2,16
    80001efc:	00006597          	auipc	a1,0x6
    80001f00:	35458593          	add	a1,a1,852 # 80008250 <digits+0x220>
    80001f04:	16048513          	add	a0,s1,352
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	f40080e7          	jalr	-192(ra) # 80000e48 <safestrcpy>
  p->cwd = namei("/");
    80001f10:	00006517          	auipc	a0,0x6
    80001f14:	35050513          	add	a0,a0,848 # 80008260 <digits+0x230>
    80001f18:	00002097          	auipc	ra,0x2
    80001f1c:	162080e7          	jalr	354(ra) # 8000407a <namei>
    80001f20:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001f24:	4789                	li	a5,2
    80001f26:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f28:	8526                	mv	a0,s1
    80001f2a:	fffff097          	auipc	ra,0xfffff
    80001f2e:	d86080e7          	jalr	-634(ra) # 80000cb0 <release>
}
    80001f32:	60e2                	ld	ra,24(sp)
    80001f34:	6442                	ld	s0,16(sp)
    80001f36:	64a2                	ld	s1,8(sp)
    80001f38:	6902                	ld	s2,0(sp)
    80001f3a:	6105                	add	sp,sp,32
    80001f3c:	8082                	ret

0000000080001f3e <growproc>:
{
    80001f3e:	7179                	add	sp,sp,-48
    80001f40:	f406                	sd	ra,40(sp)
    80001f42:	f022                	sd	s0,32(sp)
    80001f44:	ec26                	sd	s1,24(sp)
    80001f46:	e84a                	sd	s2,16(sp)
    80001f48:	e44e                	sd	s3,8(sp)
    80001f4a:	1800                	add	s0,sp,48
    80001f4c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001f4e:	00000097          	auipc	ra,0x0
    80001f52:	aea080e7          	jalr	-1302(ra) # 80001a38 <myproc>
    80001f56:	84aa                	mv	s1,a0
  sz = p->sz;
    80001f58:	652c                	ld	a1,72(a0)
    80001f5a:	0005899b          	sext.w	s3,a1
  if(n > 0){
    80001f5e:	07205163          	blez	s2,80001fc0 <growproc+0x82>
    if(n+sz>PLIC) return -1;
    80001f62:	0139093b          	addw	s2,s2,s3
    80001f66:	0009071b          	sext.w	a4,s2
    80001f6a:	0c0007b7          	lui	a5,0xc000
    80001f6e:	0ae7e063          	bltu	a5,a4,8000200e <growproc+0xd0>
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001f72:	02091613          	sll	a2,s2,0x20
    80001f76:	9201                	srl	a2,a2,0x20
    80001f78:	1582                	sll	a1,a1,0x20
    80001f7a:	9181                	srl	a1,a1,0x20
    80001f7c:	6928                	ld	a0,80(a0)
    80001f7e:	fffff097          	auipc	ra,0xfffff
    80001f82:	6d2080e7          	jalr	1746(ra) # 80001650 <uvmalloc>
    80001f86:	0005099b          	sext.w	s3,a0
    80001f8a:	08098463          	beqz	s3,80002012 <growproc+0xd4>
    if(u2kvmcopy(p->pagetable, p->ukpagetable, p->sz, sz) < 0)
    80001f8e:	02051693          	sll	a3,a0,0x20
    80001f92:	9281                	srl	a3,a3,0x20
    80001f94:	64b0                	ld	a2,72(s1)
    80001f96:	6cac                	ld	a1,88(s1)
    80001f98:	68a8                	ld	a0,80(s1)
    80001f9a:	fffff097          	auipc	ra,0xfffff
    80001f9e:	51c080e7          	jalr	1308(ra) # 800014b6 <u2kvmcopy>
    80001fa2:	06054a63          	bltz	a0,80002016 <growproc+0xd8>
  p->sz = sz;
    80001fa6:	1982                	sll	s3,s3,0x20
    80001fa8:	0209d993          	srl	s3,s3,0x20
    80001fac:	0534b423          	sd	s3,72(s1)
  return 0;
    80001fb0:	4501                	li	a0,0
}
    80001fb2:	70a2                	ld	ra,40(sp)
    80001fb4:	7402                	ld	s0,32(sp)
    80001fb6:	64e2                	ld	s1,24(sp)
    80001fb8:	6942                	ld	s2,16(sp)
    80001fba:	69a2                	ld	s3,8(sp)
    80001fbc:	6145                	add	sp,sp,48
    80001fbe:	8082                	ret
  } else if(n < 0){
    80001fc0:	fe0953e3          	bgez	s2,80001fa6 <growproc+0x68>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001fc4:	0139063b          	addw	a2,s2,s3
    80001fc8:	1602                	sll	a2,a2,0x20
    80001fca:	9201                	srl	a2,a2,0x20
    80001fcc:	1582                	sll	a1,a1,0x20
    80001fce:	9181                	srl	a1,a1,0x20
    80001fd0:	6928                	ld	a0,80(a0)
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	636080e7          	jalr	1590(ra) # 80001608 <uvmdealloc>
    80001fda:	0005099b          	sext.w	s3,a0
    if (PGROUNDUP(sz) < PGROUNDUP(p->sz)) {
    80001fde:	6585                	lui	a1,0x1
    80001fe0:	35fd                	addw	a1,a1,-1 # fff <_entry-0x7ffff001>
    80001fe2:	9da9                	addw	a1,a1,a0
    80001fe4:	77fd                	lui	a5,0xfffff
    80001fe6:	8dfd                	and	a1,a1,a5
    80001fe8:	1582                	sll	a1,a1,0x20
    80001fea:	9181                	srl	a1,a1,0x20
    80001fec:	64b0                	ld	a2,72(s1)
    80001fee:	6785                	lui	a5,0x1
    80001ff0:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001ff2:	963e                	add	a2,a2,a5
    80001ff4:	77fd                	lui	a5,0xfffff
    80001ff6:	8e7d                	and	a2,a2,a5
    80001ff8:	fac5f7e3          	bgeu	a1,a2,80001fa6 <growproc+0x68>
               (PGROUNDUP(p->sz) - PGROUNDUP(sz)) / PGSIZE, 0);
    80001ffc:	8e0d                	sub	a2,a2,a1
      uvmunmap(p->ukpagetable, PGROUNDUP(sz),
    80001ffe:	4681                	li	a3,0
    80002000:	8231                	srl	a2,a2,0xc
    80002002:	6ca8                	ld	a0,88(s1)
    80002004:	fffff097          	auipc	ra,0xfffff
    80002008:	3ee080e7          	jalr	1006(ra) # 800013f2 <uvmunmap>
    8000200c:	bf69                	j	80001fa6 <growproc+0x68>
    if(n+sz>PLIC) return -1;
    8000200e:	557d                	li	a0,-1
    80002010:	b74d                	j	80001fb2 <growproc+0x74>
      return -1;
    80002012:	557d                	li	a0,-1
    80002014:	bf79                	j	80001fb2 <growproc+0x74>
      return -1;
    80002016:	557d                	li	a0,-1
    80002018:	bf69                	j	80001fb2 <growproc+0x74>

000000008000201a <fork>:
{
    8000201a:	7139                	add	sp,sp,-64
    8000201c:	fc06                	sd	ra,56(sp)
    8000201e:	f822                	sd	s0,48(sp)
    80002020:	f426                	sd	s1,40(sp)
    80002022:	f04a                	sd	s2,32(sp)
    80002024:	ec4e                	sd	s3,24(sp)
    80002026:	e852                	sd	s4,16(sp)
    80002028:	e456                	sd	s5,8(sp)
    8000202a:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    8000202c:	00000097          	auipc	ra,0x0
    80002030:	a0c080e7          	jalr	-1524(ra) # 80001a38 <myproc>
    80002034:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80002036:	00000097          	auipc	ra,0x0
    8000203a:	d4c080e7          	jalr	-692(ra) # 80001d82 <allocproc>
    8000203e:	10050b63          	beqz	a0,80002154 <fork+0x13a>
    80002042:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002044:	048ab603          	ld	a2,72(s5) # 1048 <_entry-0x7fffefb8>
    80002048:	692c                	ld	a1,80(a0)
    8000204a:	050ab503          	ld	a0,80(s5)
    8000204e:	fffff097          	auipc	ra,0xfffff
    80002052:	752080e7          	jalr	1874(ra) # 800017a0 <uvmcopy>
    80002056:	06054563          	bltz	a0,800020c0 <fork+0xa6>
  np->sz = p->sz;
    8000205a:	048ab683          	ld	a3,72(s5)
    8000205e:	04d9b423          	sd	a3,72(s3)
  if(u2kvmcopy(np->pagetable, np->ukpagetable, 0, np->sz) < 0) {
    80002062:	4601                	li	a2,0
    80002064:	0589b583          	ld	a1,88(s3)
    80002068:	0509b503          	ld	a0,80(s3)
    8000206c:	fffff097          	auipc	ra,0xfffff
    80002070:	44a080e7          	jalr	1098(ra) # 800014b6 <u2kvmcopy>
    80002074:	06054263          	bltz	a0,800020d8 <fork+0xbe>
  np->parent = p;
    80002078:	0359b023          	sd	s5,32(s3)
  *(np->trapframe) = *(p->trapframe);
    8000207c:	060ab683          	ld	a3,96(s5)
    80002080:	87b6                	mv	a5,a3
    80002082:	0609b703          	ld	a4,96(s3)
    80002086:	12068693          	add	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    8000208a:	0007b803          	ld	a6,0(a5) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    8000208e:	6788                	ld	a0,8(a5)
    80002090:	6b8c                	ld	a1,16(a5)
    80002092:	6f90                	ld	a2,24(a5)
    80002094:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80002098:	e708                	sd	a0,8(a4)
    8000209a:	eb0c                	sd	a1,16(a4)
    8000209c:	ef10                	sd	a2,24(a4)
    8000209e:	02078793          	add	a5,a5,32
    800020a2:	02070713          	add	a4,a4,32
    800020a6:	fed792e3          	bne	a5,a3,8000208a <fork+0x70>
  np->trapframe->a0 = 0;
    800020aa:	0609b783          	ld	a5,96(s3)
    800020ae:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    800020b2:	0d8a8493          	add	s1,s5,216
    800020b6:	0d898913          	add	s2,s3,216
    800020ba:	158a8a13          	add	s4,s5,344
    800020be:	a82d                	j	800020f8 <fork+0xde>
    freeproc(np);
    800020c0:	854e                	mv	a0,s3
    800020c2:	00000097          	auipc	ra,0x0
    800020c6:	c40080e7          	jalr	-960(ra) # 80001d02 <freeproc>
    release(&np->lock);
    800020ca:	854e                	mv	a0,s3
    800020cc:	fffff097          	auipc	ra,0xfffff
    800020d0:	be4080e7          	jalr	-1052(ra) # 80000cb0 <release>
    return -1;
    800020d4:	54fd                	li	s1,-1
    800020d6:	a0ad                	j	80002140 <fork+0x126>
    freeproc(np);
    800020d8:	854e                	mv	a0,s3
    800020da:	00000097          	auipc	ra,0x0
    800020de:	c28080e7          	jalr	-984(ra) # 80001d02 <freeproc>
    release(&np->lock);
    800020e2:	854e                	mv	a0,s3
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	bcc080e7          	jalr	-1076(ra) # 80000cb0 <release>
    return -1;
    800020ec:	54fd                	li	s1,-1
    800020ee:	a889                	j	80002140 <fork+0x126>
  for(i = 0; i < NOFILE; i++)
    800020f0:	04a1                	add	s1,s1,8
    800020f2:	0921                	add	s2,s2,8 # 1008 <_entry-0x7fffeff8>
    800020f4:	01448b63          	beq	s1,s4,8000210a <fork+0xf0>
    if(p->ofile[i])
    800020f8:	6088                	ld	a0,0(s1)
    800020fa:	d97d                	beqz	a0,800020f0 <fork+0xd6>
      np->ofile[i] = filedup(p->ofile[i]);
    800020fc:	00002097          	auipc	ra,0x2
    80002100:	5e6080e7          	jalr	1510(ra) # 800046e2 <filedup>
    80002104:	00a93023          	sd	a0,0(s2)
    80002108:	b7e5                	j	800020f0 <fork+0xd6>
  np->cwd = idup(p->cwd);
    8000210a:	158ab503          	ld	a0,344(s5)
    8000210e:	00001097          	auipc	ra,0x1
    80002112:	77e080e7          	jalr	1918(ra) # 8000388c <idup>
    80002116:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000211a:	4641                	li	a2,16
    8000211c:	160a8593          	add	a1,s5,352
    80002120:	16098513          	add	a0,s3,352
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	d24080e7          	jalr	-732(ra) # 80000e48 <safestrcpy>
  pid = np->pid;
    8000212c:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80002130:	4789                	li	a5,2
    80002132:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002136:	854e                	mv	a0,s3
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	b78080e7          	jalr	-1160(ra) # 80000cb0 <release>
}
    80002140:	8526                	mv	a0,s1
    80002142:	70e2                	ld	ra,56(sp)
    80002144:	7442                	ld	s0,48(sp)
    80002146:	74a2                	ld	s1,40(sp)
    80002148:	7902                	ld	s2,32(sp)
    8000214a:	69e2                	ld	s3,24(sp)
    8000214c:	6a42                	ld	s4,16(sp)
    8000214e:	6aa2                	ld	s5,8(sp)
    80002150:	6121                	add	sp,sp,64
    80002152:	8082                	ret
    return -1;
    80002154:	54fd                	li	s1,-1
    80002156:	b7ed                	j	80002140 <fork+0x126>

0000000080002158 <reparent>:
{
    80002158:	7179                	add	sp,sp,-48
    8000215a:	f406                	sd	ra,40(sp)
    8000215c:	f022                	sd	s0,32(sp)
    8000215e:	ec26                	sd	s1,24(sp)
    80002160:	e84a                	sd	s2,16(sp)
    80002162:	e44e                	sd	s3,8(sp)
    80002164:	e052                	sd	s4,0(sp)
    80002166:	1800                	add	s0,sp,48
    80002168:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000216a:	00010497          	auipc	s1,0x10
    8000216e:	bfe48493          	add	s1,s1,-1026 # 80011d68 <proc>
      pp->parent = initproc;
    80002172:	00007a17          	auipc	s4,0x7
    80002176:	ea6a0a13          	add	s4,s4,-346 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000217a:	00015997          	auipc	s3,0x15
    8000217e:	7ee98993          	add	s3,s3,2030 # 80017968 <tickslock>
    80002182:	a029                	j	8000218c <reparent+0x34>
    80002184:	17048493          	add	s1,s1,368
    80002188:	03348363          	beq	s1,s3,800021ae <reparent+0x56>
    if(pp->parent == p){
    8000218c:	709c                	ld	a5,32(s1)
    8000218e:	ff279be3          	bne	a5,s2,80002184 <reparent+0x2c>
      acquire(&pp->lock);
    80002192:	8526                	mv	a0,s1
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	a68080e7          	jalr	-1432(ra) # 80000bfc <acquire>
      pp->parent = initproc;
    8000219c:	000a3783          	ld	a5,0(s4)
    800021a0:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    800021a2:	8526                	mv	a0,s1
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	b0c080e7          	jalr	-1268(ra) # 80000cb0 <release>
    800021ac:	bfe1                	j	80002184 <reparent+0x2c>
}
    800021ae:	70a2                	ld	ra,40(sp)
    800021b0:	7402                	ld	s0,32(sp)
    800021b2:	64e2                	ld	s1,24(sp)
    800021b4:	6942                	ld	s2,16(sp)
    800021b6:	69a2                	ld	s3,8(sp)
    800021b8:	6a02                	ld	s4,0(sp)
    800021ba:	6145                	add	sp,sp,48
    800021bc:	8082                	ret

00000000800021be <scheduler>:
{
    800021be:	715d                	add	sp,sp,-80
    800021c0:	e486                	sd	ra,72(sp)
    800021c2:	e0a2                	sd	s0,64(sp)
    800021c4:	fc26                	sd	s1,56(sp)
    800021c6:	f84a                	sd	s2,48(sp)
    800021c8:	f44e                	sd	s3,40(sp)
    800021ca:	f052                	sd	s4,32(sp)
    800021cc:	ec56                	sd	s5,24(sp)
    800021ce:	e85a                	sd	s6,16(sp)
    800021d0:	e45e                	sd	s7,8(sp)
    800021d2:	e062                	sd	s8,0(sp)
    800021d4:	0880                	add	s0,sp,80
    800021d6:	8792                	mv	a5,tp
  int id = r_tp();
    800021d8:	2781                	sext.w	a5,a5
  c->proc = 0;
    800021da:	00779b13          	sll	s6,a5,0x7
    800021de:	0000f717          	auipc	a4,0xf
    800021e2:	77270713          	add	a4,a4,1906 # 80011950 <pid_lock>
    800021e6:	975a                	add	a4,a4,s6
    800021e8:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    800021ec:	0000f717          	auipc	a4,0xf
    800021f0:	78470713          	add	a4,a4,1924 # 80011970 <cpus+0x8>
    800021f4:	9b3a                	add	s6,s6,a4
        c->proc = p;
    800021f6:	079e                	sll	a5,a5,0x7
    800021f8:	0000fa17          	auipc	s4,0xf
    800021fc:	758a0a13          	add	s4,s4,1880 # 80011950 <pid_lock>
    80002200:	9a3e                	add	s4,s4,a5
        w_satp(MAKE_SATP(p->ukpagetable));
    80002202:	5bfd                	li	s7,-1
    80002204:	1bfe                	sll	s7,s7,0x3f
    for(p = proc; p < &proc[NPROC]; p++) {
    80002206:	00015997          	auipc	s3,0x15
    8000220a:	76298993          	add	s3,s3,1890 # 80017968 <tickslock>
    8000220e:	a0bd                	j	8000227c <scheduler+0xbe>
      release(&p->lock);
    80002210:	8526                	mv	a0,s1
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	a9e080e7          	jalr	-1378(ra) # 80000cb0 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000221a:	17048493          	add	s1,s1,368
    8000221e:	05348563          	beq	s1,s3,80002268 <scheduler+0xaa>
      acquire(&p->lock);
    80002222:	8526                	mv	a0,s1
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	9d8080e7          	jalr	-1576(ra) # 80000bfc <acquire>
      if(p->state == RUNNABLE) {
    8000222c:	4c9c                	lw	a5,24(s1)
    8000222e:	ff2791e3          	bne	a5,s2,80002210 <scheduler+0x52>
        p->state = RUNNING;
    80002232:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    80002236:	009a3c23          	sd	s1,24(s4)
        w_satp(MAKE_SATP(p->ukpagetable));
    8000223a:	6cbc                	ld	a5,88(s1)
    8000223c:	83b1                	srl	a5,a5,0xc
    8000223e:	0177e7b3          	or	a5,a5,s7
  asm volatile("csrw satp, %0" : : "r" (x));
    80002242:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80002246:	12000073          	sfence.vma
        swtch(&c->context, &p->context);
    8000224a:	06848593          	add	a1,s1,104
    8000224e:	855a                	mv	a0,s6
    80002250:	00000097          	auipc	ra,0x0
    80002254:	61a080e7          	jalr	1562(ra) # 8000286a <swtch>
        c->proc = 0;
    80002258:	000a3c23          	sd	zero,24(s4)
        kvminithart();
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	e5c080e7          	jalr	-420(ra) # 800010b8 <kvminithart>
        found = 1;
    80002264:	4c05                	li	s8,1
    80002266:	b76d                	j	80002210 <scheduler+0x52>
    if(found == 0) {
    80002268:	000c1a63          	bnez	s8,8000227c <scheduler+0xbe>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000226c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002270:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002274:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002278:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000227c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002280:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002284:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002288:	4c01                	li	s8,0
    for(p = proc; p < &proc[NPROC]; p++) {
    8000228a:	00010497          	auipc	s1,0x10
    8000228e:	ade48493          	add	s1,s1,-1314 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80002292:	4909                	li	s2,2
        p->state = RUNNING;
    80002294:	4a8d                	li	s5,3
    80002296:	b771                	j	80002222 <scheduler+0x64>

0000000080002298 <sched>:
{
    80002298:	7179                	add	sp,sp,-48
    8000229a:	f406                	sd	ra,40(sp)
    8000229c:	f022                	sd	s0,32(sp)
    8000229e:	ec26                	sd	s1,24(sp)
    800022a0:	e84a                	sd	s2,16(sp)
    800022a2:	e44e                	sd	s3,8(sp)
    800022a4:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	792080e7          	jalr	1938(ra) # 80001a38 <myproc>
    800022ae:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	8d2080e7          	jalr	-1838(ra) # 80000b82 <holding>
    800022b8:	c93d                	beqz	a0,8000232e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022ba:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800022bc:	2781                	sext.w	a5,a5
    800022be:	079e                	sll	a5,a5,0x7
    800022c0:	0000f717          	auipc	a4,0xf
    800022c4:	69070713          	add	a4,a4,1680 # 80011950 <pid_lock>
    800022c8:	97ba                	add	a5,a5,a4
    800022ca:	0907a703          	lw	a4,144(a5)
    800022ce:	4785                	li	a5,1
    800022d0:	06f71763          	bne	a4,a5,8000233e <sched+0xa6>
  if(p->state == RUNNING)
    800022d4:	4c98                	lw	a4,24(s1)
    800022d6:	478d                	li	a5,3
    800022d8:	06f70b63          	beq	a4,a5,8000234e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022dc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022e0:	8b89                	and	a5,a5,2
  if(intr_get())
    800022e2:	efb5                	bnez	a5,8000235e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022e4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022e6:	0000f917          	auipc	s2,0xf
    800022ea:	66a90913          	add	s2,s2,1642 # 80011950 <pid_lock>
    800022ee:	2781                	sext.w	a5,a5
    800022f0:	079e                	sll	a5,a5,0x7
    800022f2:	97ca                	add	a5,a5,s2
    800022f4:	0947a983          	lw	s3,148(a5)
    800022f8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022fa:	2781                	sext.w	a5,a5
    800022fc:	079e                	sll	a5,a5,0x7
    800022fe:	0000f597          	auipc	a1,0xf
    80002302:	67258593          	add	a1,a1,1650 # 80011970 <cpus+0x8>
    80002306:	95be                	add	a1,a1,a5
    80002308:	06848513          	add	a0,s1,104
    8000230c:	00000097          	auipc	ra,0x0
    80002310:	55e080e7          	jalr	1374(ra) # 8000286a <swtch>
    80002314:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002316:	2781                	sext.w	a5,a5
    80002318:	079e                	sll	a5,a5,0x7
    8000231a:	993e                	add	s2,s2,a5
    8000231c:	09392a23          	sw	s3,148(s2)
}
    80002320:	70a2                	ld	ra,40(sp)
    80002322:	7402                	ld	s0,32(sp)
    80002324:	64e2                	ld	s1,24(sp)
    80002326:	6942                	ld	s2,16(sp)
    80002328:	69a2                	ld	s3,8(sp)
    8000232a:	6145                	add	sp,sp,48
    8000232c:	8082                	ret
    panic("sched p->lock");
    8000232e:	00006517          	auipc	a0,0x6
    80002332:	f3a50513          	add	a0,a0,-198 # 80008268 <digits+0x238>
    80002336:	ffffe097          	auipc	ra,0xffffe
    8000233a:	20c080e7          	jalr	524(ra) # 80000542 <panic>
    panic("sched locks");
    8000233e:	00006517          	auipc	a0,0x6
    80002342:	f3a50513          	add	a0,a0,-198 # 80008278 <digits+0x248>
    80002346:	ffffe097          	auipc	ra,0xffffe
    8000234a:	1fc080e7          	jalr	508(ra) # 80000542 <panic>
    panic("sched running");
    8000234e:	00006517          	auipc	a0,0x6
    80002352:	f3a50513          	add	a0,a0,-198 # 80008288 <digits+0x258>
    80002356:	ffffe097          	auipc	ra,0xffffe
    8000235a:	1ec080e7          	jalr	492(ra) # 80000542 <panic>
    panic("sched interruptible");
    8000235e:	00006517          	auipc	a0,0x6
    80002362:	f3a50513          	add	a0,a0,-198 # 80008298 <digits+0x268>
    80002366:	ffffe097          	auipc	ra,0xffffe
    8000236a:	1dc080e7          	jalr	476(ra) # 80000542 <panic>

000000008000236e <exit>:
{
    8000236e:	7179                	add	sp,sp,-48
    80002370:	f406                	sd	ra,40(sp)
    80002372:	f022                	sd	s0,32(sp)
    80002374:	ec26                	sd	s1,24(sp)
    80002376:	e84a                	sd	s2,16(sp)
    80002378:	e44e                	sd	s3,8(sp)
    8000237a:	e052                	sd	s4,0(sp)
    8000237c:	1800                	add	s0,sp,48
    8000237e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	6b8080e7          	jalr	1720(ra) # 80001a38 <myproc>
    80002388:	89aa                	mv	s3,a0
  if(p == initproc)
    8000238a:	00007797          	auipc	a5,0x7
    8000238e:	c8e7b783          	ld	a5,-882(a5) # 80009018 <initproc>
    80002392:	0d850493          	add	s1,a0,216
    80002396:	15850913          	add	s2,a0,344
    8000239a:	02a79363          	bne	a5,a0,800023c0 <exit+0x52>
    panic("init exiting");
    8000239e:	00006517          	auipc	a0,0x6
    800023a2:	f1250513          	add	a0,a0,-238 # 800082b0 <digits+0x280>
    800023a6:	ffffe097          	auipc	ra,0xffffe
    800023aa:	19c080e7          	jalr	412(ra) # 80000542 <panic>
      fileclose(f);
    800023ae:	00002097          	auipc	ra,0x2
    800023b2:	386080e7          	jalr	902(ra) # 80004734 <fileclose>
      p->ofile[fd] = 0;
    800023b6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800023ba:	04a1                	add	s1,s1,8
    800023bc:	01248563          	beq	s1,s2,800023c6 <exit+0x58>
    if(p->ofile[fd]){
    800023c0:	6088                	ld	a0,0(s1)
    800023c2:	f575                	bnez	a0,800023ae <exit+0x40>
    800023c4:	bfdd                	j	800023ba <exit+0x4c>
  begin_op();
    800023c6:	00002097          	auipc	ra,0x2
    800023ca:	ea4080e7          	jalr	-348(ra) # 8000426a <begin_op>
  iput(p->cwd);
    800023ce:	1589b503          	ld	a0,344(s3)
    800023d2:	00001097          	auipc	ra,0x1
    800023d6:	6b2080e7          	jalr	1714(ra) # 80003a84 <iput>
  end_op();
    800023da:	00002097          	auipc	ra,0x2
    800023de:	f0a080e7          	jalr	-246(ra) # 800042e4 <end_op>
  p->cwd = 0;
    800023e2:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    800023e6:	00007497          	auipc	s1,0x7
    800023ea:	c3248493          	add	s1,s1,-974 # 80009018 <initproc>
    800023ee:	6088                	ld	a0,0(s1)
    800023f0:	fffff097          	auipc	ra,0xfffff
    800023f4:	80c080e7          	jalr	-2036(ra) # 80000bfc <acquire>
  wakeup1(initproc);
    800023f8:	6088                	ld	a0,0(s1)
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	566080e7          	jalr	1382(ra) # 80001960 <wakeup1>
  release(&initproc->lock);
    80002402:	6088                	ld	a0,0(s1)
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	8ac080e7          	jalr	-1876(ra) # 80000cb0 <release>
  acquire(&p->lock);
    8000240c:	854e                	mv	a0,s3
    8000240e:	ffffe097          	auipc	ra,0xffffe
    80002412:	7ee080e7          	jalr	2030(ra) # 80000bfc <acquire>
  struct proc *original_parent = p->parent;
    80002416:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000241a:	854e                	mv	a0,s3
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	894080e7          	jalr	-1900(ra) # 80000cb0 <release>
  acquire(&original_parent->lock);
    80002424:	8526                	mv	a0,s1
    80002426:	ffffe097          	auipc	ra,0xffffe
    8000242a:	7d6080e7          	jalr	2006(ra) # 80000bfc <acquire>
  acquire(&p->lock);
    8000242e:	854e                	mv	a0,s3
    80002430:	ffffe097          	auipc	ra,0xffffe
    80002434:	7cc080e7          	jalr	1996(ra) # 80000bfc <acquire>
  reparent(p);
    80002438:	854e                	mv	a0,s3
    8000243a:	00000097          	auipc	ra,0x0
    8000243e:	d1e080e7          	jalr	-738(ra) # 80002158 <reparent>
  wakeup1(original_parent);
    80002442:	8526                	mv	a0,s1
    80002444:	fffff097          	auipc	ra,0xfffff
    80002448:	51c080e7          	jalr	1308(ra) # 80001960 <wakeup1>
  p->xstate = status;
    8000244c:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002450:	4791                	li	a5,4
    80002452:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002456:	8526                	mv	a0,s1
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	858080e7          	jalr	-1960(ra) # 80000cb0 <release>
  sched();
    80002460:	00000097          	auipc	ra,0x0
    80002464:	e38080e7          	jalr	-456(ra) # 80002298 <sched>
  panic("zombie exit");
    80002468:	00006517          	auipc	a0,0x6
    8000246c:	e5850513          	add	a0,a0,-424 # 800082c0 <digits+0x290>
    80002470:	ffffe097          	auipc	ra,0xffffe
    80002474:	0d2080e7          	jalr	210(ra) # 80000542 <panic>

0000000080002478 <yield>:
{
    80002478:	1101                	add	sp,sp,-32
    8000247a:	ec06                	sd	ra,24(sp)
    8000247c:	e822                	sd	s0,16(sp)
    8000247e:	e426                	sd	s1,8(sp)
    80002480:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	5b6080e7          	jalr	1462(ra) # 80001a38 <myproc>
    8000248a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000248c:	ffffe097          	auipc	ra,0xffffe
    80002490:	770080e7          	jalr	1904(ra) # 80000bfc <acquire>
  p->state = RUNNABLE;
    80002494:	4789                	li	a5,2
    80002496:	cc9c                	sw	a5,24(s1)
  sched();
    80002498:	00000097          	auipc	ra,0x0
    8000249c:	e00080e7          	jalr	-512(ra) # 80002298 <sched>
  release(&p->lock);
    800024a0:	8526                	mv	a0,s1
    800024a2:	fffff097          	auipc	ra,0xfffff
    800024a6:	80e080e7          	jalr	-2034(ra) # 80000cb0 <release>
}
    800024aa:	60e2                	ld	ra,24(sp)
    800024ac:	6442                	ld	s0,16(sp)
    800024ae:	64a2                	ld	s1,8(sp)
    800024b0:	6105                	add	sp,sp,32
    800024b2:	8082                	ret

00000000800024b4 <sleep>:
{
    800024b4:	7179                	add	sp,sp,-48
    800024b6:	f406                	sd	ra,40(sp)
    800024b8:	f022                	sd	s0,32(sp)
    800024ba:	ec26                	sd	s1,24(sp)
    800024bc:	e84a                	sd	s2,16(sp)
    800024be:	e44e                	sd	s3,8(sp)
    800024c0:	1800                	add	s0,sp,48
    800024c2:	89aa                	mv	s3,a0
    800024c4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	572080e7          	jalr	1394(ra) # 80001a38 <myproc>
    800024ce:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800024d0:	05250663          	beq	a0,s2,8000251c <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800024d4:	ffffe097          	auipc	ra,0xffffe
    800024d8:	728080e7          	jalr	1832(ra) # 80000bfc <acquire>
    release(lk);
    800024dc:	854a                	mv	a0,s2
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	7d2080e7          	jalr	2002(ra) # 80000cb0 <release>
  p->chan = chan;
    800024e6:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800024ea:	4785                	li	a5,1
    800024ec:	cc9c                	sw	a5,24(s1)
  sched();
    800024ee:	00000097          	auipc	ra,0x0
    800024f2:	daa080e7          	jalr	-598(ra) # 80002298 <sched>
  p->chan = 0;
    800024f6:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800024fa:	8526                	mv	a0,s1
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	7b4080e7          	jalr	1972(ra) # 80000cb0 <release>
    acquire(lk);
    80002504:	854a                	mv	a0,s2
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	6f6080e7          	jalr	1782(ra) # 80000bfc <acquire>
}
    8000250e:	70a2                	ld	ra,40(sp)
    80002510:	7402                	ld	s0,32(sp)
    80002512:	64e2                	ld	s1,24(sp)
    80002514:	6942                	ld	s2,16(sp)
    80002516:	69a2                	ld	s3,8(sp)
    80002518:	6145                	add	sp,sp,48
    8000251a:	8082                	ret
  p->chan = chan;
    8000251c:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002520:	4785                	li	a5,1
    80002522:	cd1c                	sw	a5,24(a0)
  sched();
    80002524:	00000097          	auipc	ra,0x0
    80002528:	d74080e7          	jalr	-652(ra) # 80002298 <sched>
  p->chan = 0;
    8000252c:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002530:	bff9                	j	8000250e <sleep+0x5a>

0000000080002532 <wait>:
{
    80002532:	715d                	add	sp,sp,-80
    80002534:	e486                	sd	ra,72(sp)
    80002536:	e0a2                	sd	s0,64(sp)
    80002538:	fc26                	sd	s1,56(sp)
    8000253a:	f84a                	sd	s2,48(sp)
    8000253c:	f44e                	sd	s3,40(sp)
    8000253e:	f052                	sd	s4,32(sp)
    80002540:	ec56                	sd	s5,24(sp)
    80002542:	e85a                	sd	s6,16(sp)
    80002544:	e45e                	sd	s7,8(sp)
    80002546:	0880                	add	s0,sp,80
    80002548:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000254a:	fffff097          	auipc	ra,0xfffff
    8000254e:	4ee080e7          	jalr	1262(ra) # 80001a38 <myproc>
    80002552:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002554:	ffffe097          	auipc	ra,0xffffe
    80002558:	6a8080e7          	jalr	1704(ra) # 80000bfc <acquire>
    havekids = 0;
    8000255c:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000255e:	4a11                	li	s4,4
        havekids = 1;
    80002560:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002562:	00015997          	auipc	s3,0x15
    80002566:	40698993          	add	s3,s3,1030 # 80017968 <tickslock>
    8000256a:	a845                	j	8000261a <wait+0xe8>
          pid = np->pid;
    8000256c:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002570:	000b0e63          	beqz	s6,8000258c <wait+0x5a>
    80002574:	4691                	li	a3,4
    80002576:	03448613          	add	a2,s1,52
    8000257a:	85da                	mv	a1,s6
    8000257c:	05093503          	ld	a0,80(s2)
    80002580:	fffff097          	auipc	ra,0xfffff
    80002584:	324080e7          	jalr	804(ra) # 800018a4 <copyout>
    80002588:	02054d63          	bltz	a0,800025c2 <wait+0x90>
          freeproc(np);
    8000258c:	8526                	mv	a0,s1
    8000258e:	fffff097          	auipc	ra,0xfffff
    80002592:	774080e7          	jalr	1908(ra) # 80001d02 <freeproc>
          release(&np->lock);
    80002596:	8526                	mv	a0,s1
    80002598:	ffffe097          	auipc	ra,0xffffe
    8000259c:	718080e7          	jalr	1816(ra) # 80000cb0 <release>
          release(&p->lock);
    800025a0:	854a                	mv	a0,s2
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	70e080e7          	jalr	1806(ra) # 80000cb0 <release>
}
    800025aa:	854e                	mv	a0,s3
    800025ac:	60a6                	ld	ra,72(sp)
    800025ae:	6406                	ld	s0,64(sp)
    800025b0:	74e2                	ld	s1,56(sp)
    800025b2:	7942                	ld	s2,48(sp)
    800025b4:	79a2                	ld	s3,40(sp)
    800025b6:	7a02                	ld	s4,32(sp)
    800025b8:	6ae2                	ld	s5,24(sp)
    800025ba:	6b42                	ld	s6,16(sp)
    800025bc:	6ba2                	ld	s7,8(sp)
    800025be:	6161                	add	sp,sp,80
    800025c0:	8082                	ret
            release(&np->lock);
    800025c2:	8526                	mv	a0,s1
    800025c4:	ffffe097          	auipc	ra,0xffffe
    800025c8:	6ec080e7          	jalr	1772(ra) # 80000cb0 <release>
            release(&p->lock);
    800025cc:	854a                	mv	a0,s2
    800025ce:	ffffe097          	auipc	ra,0xffffe
    800025d2:	6e2080e7          	jalr	1762(ra) # 80000cb0 <release>
            return -1;
    800025d6:	59fd                	li	s3,-1
    800025d8:	bfc9                	j	800025aa <wait+0x78>
    for(np = proc; np < &proc[NPROC]; np++){
    800025da:	17048493          	add	s1,s1,368
    800025de:	03348463          	beq	s1,s3,80002606 <wait+0xd4>
      if(np->parent == p){
    800025e2:	709c                	ld	a5,32(s1)
    800025e4:	ff279be3          	bne	a5,s2,800025da <wait+0xa8>
        acquire(&np->lock);
    800025e8:	8526                	mv	a0,s1
    800025ea:	ffffe097          	auipc	ra,0xffffe
    800025ee:	612080e7          	jalr	1554(ra) # 80000bfc <acquire>
        if(np->state == ZOMBIE){
    800025f2:	4c9c                	lw	a5,24(s1)
    800025f4:	f7478ce3          	beq	a5,s4,8000256c <wait+0x3a>
        release(&np->lock);
    800025f8:	8526                	mv	a0,s1
    800025fa:	ffffe097          	auipc	ra,0xffffe
    800025fe:	6b6080e7          	jalr	1718(ra) # 80000cb0 <release>
        havekids = 1;
    80002602:	8756                	mv	a4,s5
    80002604:	bfd9                	j	800025da <wait+0xa8>
    if(!havekids || p->killed){
    80002606:	c305                	beqz	a4,80002626 <wait+0xf4>
    80002608:	03092783          	lw	a5,48(s2)
    8000260c:	ef89                	bnez	a5,80002626 <wait+0xf4>
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000260e:	85ca                	mv	a1,s2
    80002610:	854a                	mv	a0,s2
    80002612:	00000097          	auipc	ra,0x0
    80002616:	ea2080e7          	jalr	-350(ra) # 800024b4 <sleep>
    havekids = 0;
    8000261a:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000261c:	0000f497          	auipc	s1,0xf
    80002620:	74c48493          	add	s1,s1,1868 # 80011d68 <proc>
    80002624:	bf7d                	j	800025e2 <wait+0xb0>
      release(&p->lock);
    80002626:	854a                	mv	a0,s2
    80002628:	ffffe097          	auipc	ra,0xffffe
    8000262c:	688080e7          	jalr	1672(ra) # 80000cb0 <release>
      return -1;
    80002630:	59fd                	li	s3,-1
    80002632:	bfa5                	j	800025aa <wait+0x78>

0000000080002634 <wakeup>:
{
    80002634:	7139                	add	sp,sp,-64
    80002636:	fc06                	sd	ra,56(sp)
    80002638:	f822                	sd	s0,48(sp)
    8000263a:	f426                	sd	s1,40(sp)
    8000263c:	f04a                	sd	s2,32(sp)
    8000263e:	ec4e                	sd	s3,24(sp)
    80002640:	e852                	sd	s4,16(sp)
    80002642:	e456                	sd	s5,8(sp)
    80002644:	0080                	add	s0,sp,64
    80002646:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002648:	0000f497          	auipc	s1,0xf
    8000264c:	72048493          	add	s1,s1,1824 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002650:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002652:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002654:	00015917          	auipc	s2,0x15
    80002658:	31490913          	add	s2,s2,788 # 80017968 <tickslock>
    8000265c:	a811                	j	80002670 <wakeup+0x3c>
    release(&p->lock);
    8000265e:	8526                	mv	a0,s1
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	650080e7          	jalr	1616(ra) # 80000cb0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002668:	17048493          	add	s1,s1,368
    8000266c:	03248063          	beq	s1,s2,8000268c <wakeup+0x58>
    acquire(&p->lock);
    80002670:	8526                	mv	a0,s1
    80002672:	ffffe097          	auipc	ra,0xffffe
    80002676:	58a080e7          	jalr	1418(ra) # 80000bfc <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000267a:	4c9c                	lw	a5,24(s1)
    8000267c:	ff3791e3          	bne	a5,s3,8000265e <wakeup+0x2a>
    80002680:	749c                	ld	a5,40(s1)
    80002682:	fd479ee3          	bne	a5,s4,8000265e <wakeup+0x2a>
      p->state = RUNNABLE;
    80002686:	0154ac23          	sw	s5,24(s1)
    8000268a:	bfd1                	j	8000265e <wakeup+0x2a>
}
    8000268c:	70e2                	ld	ra,56(sp)
    8000268e:	7442                	ld	s0,48(sp)
    80002690:	74a2                	ld	s1,40(sp)
    80002692:	7902                	ld	s2,32(sp)
    80002694:	69e2                	ld	s3,24(sp)
    80002696:	6a42                	ld	s4,16(sp)
    80002698:	6aa2                	ld	s5,8(sp)
    8000269a:	6121                	add	sp,sp,64
    8000269c:	8082                	ret

000000008000269e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000269e:	7179                	add	sp,sp,-48
    800026a0:	f406                	sd	ra,40(sp)
    800026a2:	f022                	sd	s0,32(sp)
    800026a4:	ec26                	sd	s1,24(sp)
    800026a6:	e84a                	sd	s2,16(sp)
    800026a8:	e44e                	sd	s3,8(sp)
    800026aa:	1800                	add	s0,sp,48
    800026ac:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800026ae:	0000f497          	auipc	s1,0xf
    800026b2:	6ba48493          	add	s1,s1,1722 # 80011d68 <proc>
    800026b6:	00015997          	auipc	s3,0x15
    800026ba:	2b298993          	add	s3,s3,690 # 80017968 <tickslock>
    acquire(&p->lock);
    800026be:	8526                	mv	a0,s1
    800026c0:	ffffe097          	auipc	ra,0xffffe
    800026c4:	53c080e7          	jalr	1340(ra) # 80000bfc <acquire>
    if(p->pid == pid){
    800026c8:	5c9c                	lw	a5,56(s1)
    800026ca:	01278d63          	beq	a5,s2,800026e4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800026ce:	8526                	mv	a0,s1
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	5e0080e7          	jalr	1504(ra) # 80000cb0 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800026d8:	17048493          	add	s1,s1,368
    800026dc:	ff3491e3          	bne	s1,s3,800026be <kill+0x20>
  }
  return -1;
    800026e0:	557d                	li	a0,-1
    800026e2:	a821                	j	800026fa <kill+0x5c>
      p->killed = 1;
    800026e4:	4785                	li	a5,1
    800026e6:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800026e8:	4c98                	lw	a4,24(s1)
    800026ea:	00f70f63          	beq	a4,a5,80002708 <kill+0x6a>
      release(&p->lock);
    800026ee:	8526                	mv	a0,s1
    800026f0:	ffffe097          	auipc	ra,0xffffe
    800026f4:	5c0080e7          	jalr	1472(ra) # 80000cb0 <release>
      return 0;
    800026f8:	4501                	li	a0,0
}
    800026fa:	70a2                	ld	ra,40(sp)
    800026fc:	7402                	ld	s0,32(sp)
    800026fe:	64e2                	ld	s1,24(sp)
    80002700:	6942                	ld	s2,16(sp)
    80002702:	69a2                	ld	s3,8(sp)
    80002704:	6145                	add	sp,sp,48
    80002706:	8082                	ret
        p->state = RUNNABLE;
    80002708:	4789                	li	a5,2
    8000270a:	cc9c                	sw	a5,24(s1)
    8000270c:	b7cd                	j	800026ee <kill+0x50>

000000008000270e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000270e:	7179                	add	sp,sp,-48
    80002710:	f406                	sd	ra,40(sp)
    80002712:	f022                	sd	s0,32(sp)
    80002714:	ec26                	sd	s1,24(sp)
    80002716:	e84a                	sd	s2,16(sp)
    80002718:	e44e                	sd	s3,8(sp)
    8000271a:	e052                	sd	s4,0(sp)
    8000271c:	1800                	add	s0,sp,48
    8000271e:	84aa                	mv	s1,a0
    80002720:	892e                	mv	s2,a1
    80002722:	89b2                	mv	s3,a2
    80002724:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002726:	fffff097          	auipc	ra,0xfffff
    8000272a:	312080e7          	jalr	786(ra) # 80001a38 <myproc>
  if(user_dst){
    8000272e:	c08d                	beqz	s1,80002750 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002730:	86d2                	mv	a3,s4
    80002732:	864e                	mv	a2,s3
    80002734:	85ca                	mv	a1,s2
    80002736:	6928                	ld	a0,80(a0)
    80002738:	fffff097          	auipc	ra,0xfffff
    8000273c:	16c080e7          	jalr	364(ra) # 800018a4 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002740:	70a2                	ld	ra,40(sp)
    80002742:	7402                	ld	s0,32(sp)
    80002744:	64e2                	ld	s1,24(sp)
    80002746:	6942                	ld	s2,16(sp)
    80002748:	69a2                	ld	s3,8(sp)
    8000274a:	6a02                	ld	s4,0(sp)
    8000274c:	6145                	add	sp,sp,48
    8000274e:	8082                	ret
    memmove((char *)dst, src, len);
    80002750:	000a061b          	sext.w	a2,s4
    80002754:	85ce                	mv	a1,s3
    80002756:	854a                	mv	a0,s2
    80002758:	ffffe097          	auipc	ra,0xffffe
    8000275c:	5fc080e7          	jalr	1532(ra) # 80000d54 <memmove>
    return 0;
    80002760:	8526                	mv	a0,s1
    80002762:	bff9                	j	80002740 <either_copyout+0x32>

0000000080002764 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002764:	7179                	add	sp,sp,-48
    80002766:	f406                	sd	ra,40(sp)
    80002768:	f022                	sd	s0,32(sp)
    8000276a:	ec26                	sd	s1,24(sp)
    8000276c:	e84a                	sd	s2,16(sp)
    8000276e:	e44e                	sd	s3,8(sp)
    80002770:	e052                	sd	s4,0(sp)
    80002772:	1800                	add	s0,sp,48
    80002774:	892a                	mv	s2,a0
    80002776:	84ae                	mv	s1,a1
    80002778:	89b2                	mv	s3,a2
    8000277a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000277c:	fffff097          	auipc	ra,0xfffff
    80002780:	2bc080e7          	jalr	700(ra) # 80001a38 <myproc>
  if(user_src){
    80002784:	c08d                	beqz	s1,800027a6 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002786:	86d2                	mv	a3,s4
    80002788:	864e                	mv	a2,s3
    8000278a:	85ca                	mv	a1,s2
    8000278c:	6928                	ld	a0,80(a0)
    8000278e:	fffff097          	auipc	ra,0xfffff
    80002792:	1a2080e7          	jalr	418(ra) # 80001930 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002796:	70a2                	ld	ra,40(sp)
    80002798:	7402                	ld	s0,32(sp)
    8000279a:	64e2                	ld	s1,24(sp)
    8000279c:	6942                	ld	s2,16(sp)
    8000279e:	69a2                	ld	s3,8(sp)
    800027a0:	6a02                	ld	s4,0(sp)
    800027a2:	6145                	add	sp,sp,48
    800027a4:	8082                	ret
    memmove(dst, (char*)src, len);
    800027a6:	000a061b          	sext.w	a2,s4
    800027aa:	85ce                	mv	a1,s3
    800027ac:	854a                	mv	a0,s2
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	5a6080e7          	jalr	1446(ra) # 80000d54 <memmove>
    return 0;
    800027b6:	8526                	mv	a0,s1
    800027b8:	bff9                	j	80002796 <either_copyin+0x32>

00000000800027ba <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800027ba:	715d                	add	sp,sp,-80
    800027bc:	e486                	sd	ra,72(sp)
    800027be:	e0a2                	sd	s0,64(sp)
    800027c0:	fc26                	sd	s1,56(sp)
    800027c2:	f84a                	sd	s2,48(sp)
    800027c4:	f44e                	sd	s3,40(sp)
    800027c6:	f052                	sd	s4,32(sp)
    800027c8:	ec56                	sd	s5,24(sp)
    800027ca:	e85a                	sd	s6,16(sp)
    800027cc:	e45e                	sd	s7,8(sp)
    800027ce:	0880                	add	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800027d0:	00006517          	auipc	a0,0x6
    800027d4:	8e850513          	add	a0,a0,-1816 # 800080b8 <digits+0x88>
    800027d8:	ffffe097          	auipc	ra,0xffffe
    800027dc:	db4080e7          	jalr	-588(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027e0:	0000f497          	auipc	s1,0xf
    800027e4:	6e848493          	add	s1,s1,1768 # 80011ec8 <proc+0x160>
    800027e8:	00015917          	auipc	s2,0x15
    800027ec:	2e090913          	add	s2,s2,736 # 80017ac8 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027f0:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800027f2:	00006997          	auipc	s3,0x6
    800027f6:	ade98993          	add	s3,s3,-1314 # 800082d0 <digits+0x2a0>
    printf("%d %s %s", p->pid, state, p->name);
    800027fa:	00006a97          	auipc	s5,0x6
    800027fe:	adea8a93          	add	s5,s5,-1314 # 800082d8 <digits+0x2a8>
    printf("\n");
    80002802:	00006a17          	auipc	s4,0x6
    80002806:	8b6a0a13          	add	s4,s4,-1866 # 800080b8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000280a:	00006b97          	auipc	s7,0x6
    8000280e:	b06b8b93          	add	s7,s7,-1274 # 80008310 <states.0>
    80002812:	a00d                	j	80002834 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002814:	ed86a583          	lw	a1,-296(a3)
    80002818:	8556                	mv	a0,s5
    8000281a:	ffffe097          	auipc	ra,0xffffe
    8000281e:	d72080e7          	jalr	-654(ra) # 8000058c <printf>
    printf("\n");
    80002822:	8552                	mv	a0,s4
    80002824:	ffffe097          	auipc	ra,0xffffe
    80002828:	d68080e7          	jalr	-664(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000282c:	17048493          	add	s1,s1,368
    80002830:	03248263          	beq	s1,s2,80002854 <procdump+0x9a>
    if(p->state == UNUSED)
    80002834:	86a6                	mv	a3,s1
    80002836:	eb84a783          	lw	a5,-328(s1)
    8000283a:	dbed                	beqz	a5,8000282c <procdump+0x72>
      state = "???";
    8000283c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000283e:	fcfb6be3          	bltu	s6,a5,80002814 <procdump+0x5a>
    80002842:	02079713          	sll	a4,a5,0x20
    80002846:	01d75793          	srl	a5,a4,0x1d
    8000284a:	97de                	add	a5,a5,s7
    8000284c:	6390                	ld	a2,0(a5)
    8000284e:	f279                	bnez	a2,80002814 <procdump+0x5a>
      state = "???";
    80002850:	864e                	mv	a2,s3
    80002852:	b7c9                	j	80002814 <procdump+0x5a>
  }
}
    80002854:	60a6                	ld	ra,72(sp)
    80002856:	6406                	ld	s0,64(sp)
    80002858:	74e2                	ld	s1,56(sp)
    8000285a:	7942                	ld	s2,48(sp)
    8000285c:	79a2                	ld	s3,40(sp)
    8000285e:	7a02                	ld	s4,32(sp)
    80002860:	6ae2                	ld	s5,24(sp)
    80002862:	6b42                	ld	s6,16(sp)
    80002864:	6ba2                	ld	s7,8(sp)
    80002866:	6161                	add	sp,sp,80
    80002868:	8082                	ret

000000008000286a <swtch>:
    8000286a:	00153023          	sd	ra,0(a0)
    8000286e:	00253423          	sd	sp,8(a0)
    80002872:	e900                	sd	s0,16(a0)
    80002874:	ed04                	sd	s1,24(a0)
    80002876:	03253023          	sd	s2,32(a0)
    8000287a:	03353423          	sd	s3,40(a0)
    8000287e:	03453823          	sd	s4,48(a0)
    80002882:	03553c23          	sd	s5,56(a0)
    80002886:	05653023          	sd	s6,64(a0)
    8000288a:	05753423          	sd	s7,72(a0)
    8000288e:	05853823          	sd	s8,80(a0)
    80002892:	05953c23          	sd	s9,88(a0)
    80002896:	07a53023          	sd	s10,96(a0)
    8000289a:	07b53423          	sd	s11,104(a0)
    8000289e:	0005b083          	ld	ra,0(a1)
    800028a2:	0085b103          	ld	sp,8(a1)
    800028a6:	6980                	ld	s0,16(a1)
    800028a8:	6d84                	ld	s1,24(a1)
    800028aa:	0205b903          	ld	s2,32(a1)
    800028ae:	0285b983          	ld	s3,40(a1)
    800028b2:	0305ba03          	ld	s4,48(a1)
    800028b6:	0385ba83          	ld	s5,56(a1)
    800028ba:	0405bb03          	ld	s6,64(a1)
    800028be:	0485bb83          	ld	s7,72(a1)
    800028c2:	0505bc03          	ld	s8,80(a1)
    800028c6:	0585bc83          	ld	s9,88(a1)
    800028ca:	0605bd03          	ld	s10,96(a1)
    800028ce:	0685bd83          	ld	s11,104(a1)
    800028d2:	8082                	ret

00000000800028d4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800028d4:	1141                	add	sp,sp,-16
    800028d6:	e406                	sd	ra,8(sp)
    800028d8:	e022                	sd	s0,0(sp)
    800028da:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    800028dc:	00006597          	auipc	a1,0x6
    800028e0:	a5c58593          	add	a1,a1,-1444 # 80008338 <states.0+0x28>
    800028e4:	00015517          	auipc	a0,0x15
    800028e8:	08450513          	add	a0,a0,132 # 80017968 <tickslock>
    800028ec:	ffffe097          	auipc	ra,0xffffe
    800028f0:	280080e7          	jalr	640(ra) # 80000b6c <initlock>
}
    800028f4:	60a2                	ld	ra,8(sp)
    800028f6:	6402                	ld	s0,0(sp)
    800028f8:	0141                	add	sp,sp,16
    800028fa:	8082                	ret

00000000800028fc <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800028fc:	1141                	add	sp,sp,-16
    800028fe:	e422                	sd	s0,8(sp)
    80002900:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002902:	00003797          	auipc	a5,0x3
    80002906:	4be78793          	add	a5,a5,1214 # 80005dc0 <kernelvec>
    8000290a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000290e:	6422                	ld	s0,8(sp)
    80002910:	0141                	add	sp,sp,16
    80002912:	8082                	ret

0000000080002914 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002914:	1141                	add	sp,sp,-16
    80002916:	e406                	sd	ra,8(sp)
    80002918:	e022                	sd	s0,0(sp)
    8000291a:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    8000291c:	fffff097          	auipc	ra,0xfffff
    80002920:	11c080e7          	jalr	284(ra) # 80001a38 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002924:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002928:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000292a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000292e:	00004697          	auipc	a3,0x4
    80002932:	6d268693          	add	a3,a3,1746 # 80007000 <_trampoline>
    80002936:	00004717          	auipc	a4,0x4
    8000293a:	6ca70713          	add	a4,a4,1738 # 80007000 <_trampoline>
    8000293e:	8f15                	sub	a4,a4,a3
    80002940:	040007b7          	lui	a5,0x4000
    80002944:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002946:	07b2                	sll	a5,a5,0xc
    80002948:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000294a:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000294e:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002950:	18002673          	csrr	a2,satp
    80002954:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002956:	7130                	ld	a2,96(a0)
    80002958:	6138                	ld	a4,64(a0)
    8000295a:	6585                	lui	a1,0x1
    8000295c:	972e                	add	a4,a4,a1
    8000295e:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002960:	7138                	ld	a4,96(a0)
    80002962:	00000617          	auipc	a2,0x0
    80002966:	13c60613          	add	a2,a2,316 # 80002a9e <usertrap>
    8000296a:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000296c:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000296e:	8612                	mv	a2,tp
    80002970:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002972:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002976:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000297a:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000297e:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002982:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002984:	6f18                	ld	a4,24(a4)
    80002986:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000298a:	692c                	ld	a1,80(a0)
    8000298c:	81b1                	srl	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000298e:	00004717          	auipc	a4,0x4
    80002992:	70270713          	add	a4,a4,1794 # 80007090 <userret>
    80002996:	8f15                	sub	a4,a4,a3
    80002998:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000299a:	577d                	li	a4,-1
    8000299c:	177e                	sll	a4,a4,0x3f
    8000299e:	8dd9                	or	a1,a1,a4
    800029a0:	02000537          	lui	a0,0x2000
    800029a4:	157d                	add	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800029a6:	0536                	sll	a0,a0,0xd
    800029a8:	9782                	jalr	a5
}
    800029aa:	60a2                	ld	ra,8(sp)
    800029ac:	6402                	ld	s0,0(sp)
    800029ae:	0141                	add	sp,sp,16
    800029b0:	8082                	ret

00000000800029b2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029b2:	1101                	add	sp,sp,-32
    800029b4:	ec06                	sd	ra,24(sp)
    800029b6:	e822                	sd	s0,16(sp)
    800029b8:	e426                	sd	s1,8(sp)
    800029ba:	1000                	add	s0,sp,32
  acquire(&tickslock);
    800029bc:	00015497          	auipc	s1,0x15
    800029c0:	fac48493          	add	s1,s1,-84 # 80017968 <tickslock>
    800029c4:	8526                	mv	a0,s1
    800029c6:	ffffe097          	auipc	ra,0xffffe
    800029ca:	236080e7          	jalr	566(ra) # 80000bfc <acquire>
  ticks++;
    800029ce:	00006517          	auipc	a0,0x6
    800029d2:	65250513          	add	a0,a0,1618 # 80009020 <ticks>
    800029d6:	411c                	lw	a5,0(a0)
    800029d8:	2785                	addw	a5,a5,1
    800029da:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800029dc:	00000097          	auipc	ra,0x0
    800029e0:	c58080e7          	jalr	-936(ra) # 80002634 <wakeup>
  release(&tickslock);
    800029e4:	8526                	mv	a0,s1
    800029e6:	ffffe097          	auipc	ra,0xffffe
    800029ea:	2ca080e7          	jalr	714(ra) # 80000cb0 <release>
}
    800029ee:	60e2                	ld	ra,24(sp)
    800029f0:	6442                	ld	s0,16(sp)
    800029f2:	64a2                	ld	s1,8(sp)
    800029f4:	6105                	add	sp,sp,32
    800029f6:	8082                	ret

00000000800029f8 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029f8:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800029fc:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    800029fe:	0807df63          	bgez	a5,80002a9c <devintr+0xa4>
{
    80002a02:	1101                	add	sp,sp,-32
    80002a04:	ec06                	sd	ra,24(sp)
    80002a06:	e822                	sd	s0,16(sp)
    80002a08:	e426                	sd	s1,8(sp)
    80002a0a:	1000                	add	s0,sp,32
     (scause & 0xff) == 9){
    80002a0c:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002a10:	46a5                	li	a3,9
    80002a12:	00d70d63          	beq	a4,a3,80002a2c <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002a16:	577d                	li	a4,-1
    80002a18:	177e                	sll	a4,a4,0x3f
    80002a1a:	0705                	add	a4,a4,1
    return 0;
    80002a1c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a1e:	04e78e63          	beq	a5,a4,80002a7a <devintr+0x82>
  }
}
    80002a22:	60e2                	ld	ra,24(sp)
    80002a24:	6442                	ld	s0,16(sp)
    80002a26:	64a2                	ld	s1,8(sp)
    80002a28:	6105                	add	sp,sp,32
    80002a2a:	8082                	ret
    int irq = plic_claim();
    80002a2c:	00003097          	auipc	ra,0x3
    80002a30:	49c080e7          	jalr	1180(ra) # 80005ec8 <plic_claim>
    80002a34:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a36:	47a9                	li	a5,10
    80002a38:	02f50763          	beq	a0,a5,80002a66 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002a3c:	4785                	li	a5,1
    80002a3e:	02f50963          	beq	a0,a5,80002a70 <devintr+0x78>
    return 1;
    80002a42:	4505                	li	a0,1
    } else if(irq){
    80002a44:	dcf9                	beqz	s1,80002a22 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a46:	85a6                	mv	a1,s1
    80002a48:	00006517          	auipc	a0,0x6
    80002a4c:	8f850513          	add	a0,a0,-1800 # 80008340 <states.0+0x30>
    80002a50:	ffffe097          	auipc	ra,0xffffe
    80002a54:	b3c080e7          	jalr	-1220(ra) # 8000058c <printf>
      plic_complete(irq);
    80002a58:	8526                	mv	a0,s1
    80002a5a:	00003097          	auipc	ra,0x3
    80002a5e:	492080e7          	jalr	1170(ra) # 80005eec <plic_complete>
    return 1;
    80002a62:	4505                	li	a0,1
    80002a64:	bf7d                	j	80002a22 <devintr+0x2a>
      uartintr();
    80002a66:	ffffe097          	auipc	ra,0xffffe
    80002a6a:	f58080e7          	jalr	-168(ra) # 800009be <uartintr>
    if(irq)
    80002a6e:	b7ed                	j	80002a58 <devintr+0x60>
      virtio_disk_intr();
    80002a70:	00004097          	auipc	ra,0x4
    80002a74:	8ee080e7          	jalr	-1810(ra) # 8000635e <virtio_disk_intr>
    if(irq)
    80002a78:	b7c5                	j	80002a58 <devintr+0x60>
    if(cpuid() == 0){
    80002a7a:	fffff097          	auipc	ra,0xfffff
    80002a7e:	f92080e7          	jalr	-110(ra) # 80001a0c <cpuid>
    80002a82:	c901                	beqz	a0,80002a92 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a84:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a88:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a8a:	14479073          	csrw	sip,a5
    return 2;
    80002a8e:	4509                	li	a0,2
    80002a90:	bf49                	j	80002a22 <devintr+0x2a>
      clockintr();
    80002a92:	00000097          	auipc	ra,0x0
    80002a96:	f20080e7          	jalr	-224(ra) # 800029b2 <clockintr>
    80002a9a:	b7ed                	j	80002a84 <devintr+0x8c>
}
    80002a9c:	8082                	ret

0000000080002a9e <usertrap>:
{
    80002a9e:	1101                	add	sp,sp,-32
    80002aa0:	ec06                	sd	ra,24(sp)
    80002aa2:	e822                	sd	s0,16(sp)
    80002aa4:	e426                	sd	s1,8(sp)
    80002aa6:	e04a                	sd	s2,0(sp)
    80002aa8:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aaa:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002aae:	1007f793          	and	a5,a5,256
    80002ab2:	e3ad                	bnez	a5,80002b14 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ab4:	00003797          	auipc	a5,0x3
    80002ab8:	30c78793          	add	a5,a5,780 # 80005dc0 <kernelvec>
    80002abc:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ac0:	fffff097          	auipc	ra,0xfffff
    80002ac4:	f78080e7          	jalr	-136(ra) # 80001a38 <myproc>
    80002ac8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002aca:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002acc:	14102773          	csrr	a4,sepc
    80002ad0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ad2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002ad6:	47a1                	li	a5,8
    80002ad8:	04f71c63          	bne	a4,a5,80002b30 <usertrap+0x92>
    if(p->killed)
    80002adc:	591c                	lw	a5,48(a0)
    80002ade:	e3b9                	bnez	a5,80002b24 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002ae0:	70b8                	ld	a4,96(s1)
    80002ae2:	6f1c                	ld	a5,24(a4)
    80002ae4:	0791                	add	a5,a5,4
    80002ae6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ae8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002aec:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002af0:	10079073          	csrw	sstatus,a5
    syscall();
    80002af4:	00000097          	auipc	ra,0x0
    80002af8:	2e0080e7          	jalr	736(ra) # 80002dd4 <syscall>
  if(p->killed)
    80002afc:	589c                	lw	a5,48(s1)
    80002afe:	ebc1                	bnez	a5,80002b8e <usertrap+0xf0>
  usertrapret();
    80002b00:	00000097          	auipc	ra,0x0
    80002b04:	e14080e7          	jalr	-492(ra) # 80002914 <usertrapret>
}
    80002b08:	60e2                	ld	ra,24(sp)
    80002b0a:	6442                	ld	s0,16(sp)
    80002b0c:	64a2                	ld	s1,8(sp)
    80002b0e:	6902                	ld	s2,0(sp)
    80002b10:	6105                	add	sp,sp,32
    80002b12:	8082                	ret
    panic("usertrap: not from user mode");
    80002b14:	00006517          	auipc	a0,0x6
    80002b18:	84c50513          	add	a0,a0,-1972 # 80008360 <states.0+0x50>
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	a26080e7          	jalr	-1498(ra) # 80000542 <panic>
      exit(-1);
    80002b24:	557d                	li	a0,-1
    80002b26:	00000097          	auipc	ra,0x0
    80002b2a:	848080e7          	jalr	-1976(ra) # 8000236e <exit>
    80002b2e:	bf4d                	j	80002ae0 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b30:	00000097          	auipc	ra,0x0
    80002b34:	ec8080e7          	jalr	-312(ra) # 800029f8 <devintr>
    80002b38:	892a                	mv	s2,a0
    80002b3a:	c501                	beqz	a0,80002b42 <usertrap+0xa4>
  if(p->killed)
    80002b3c:	589c                	lw	a5,48(s1)
    80002b3e:	c3a1                	beqz	a5,80002b7e <usertrap+0xe0>
    80002b40:	a815                	j	80002b74 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b42:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b46:	5c90                	lw	a2,56(s1)
    80002b48:	00006517          	auipc	a0,0x6
    80002b4c:	83850513          	add	a0,a0,-1992 # 80008380 <states.0+0x70>
    80002b50:	ffffe097          	auipc	ra,0xffffe
    80002b54:	a3c080e7          	jalr	-1476(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b58:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b5c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b60:	00006517          	auipc	a0,0x6
    80002b64:	85050513          	add	a0,a0,-1968 # 800083b0 <states.0+0xa0>
    80002b68:	ffffe097          	auipc	ra,0xffffe
    80002b6c:	a24080e7          	jalr	-1500(ra) # 8000058c <printf>
    p->killed = 1;
    80002b70:	4785                	li	a5,1
    80002b72:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002b74:	557d                	li	a0,-1
    80002b76:	fffff097          	auipc	ra,0xfffff
    80002b7a:	7f8080e7          	jalr	2040(ra) # 8000236e <exit>
  if(which_dev == 2)
    80002b7e:	4789                	li	a5,2
    80002b80:	f8f910e3          	bne	s2,a5,80002b00 <usertrap+0x62>
    yield();
    80002b84:	00000097          	auipc	ra,0x0
    80002b88:	8f4080e7          	jalr	-1804(ra) # 80002478 <yield>
    80002b8c:	bf95                	j	80002b00 <usertrap+0x62>
  int which_dev = 0;
    80002b8e:	4901                	li	s2,0
    80002b90:	b7d5                	j	80002b74 <usertrap+0xd6>

0000000080002b92 <kerneltrap>:
{
    80002b92:	7179                	add	sp,sp,-48
    80002b94:	f406                	sd	ra,40(sp)
    80002b96:	f022                	sd	s0,32(sp)
    80002b98:	ec26                	sd	s1,24(sp)
    80002b9a:	e84a                	sd	s2,16(sp)
    80002b9c:	e44e                	sd	s3,8(sp)
    80002b9e:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ba0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ba4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ba8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002bac:	1004f793          	and	a5,s1,256
    80002bb0:	cb85                	beqz	a5,80002be0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bb2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002bb6:	8b89                	and	a5,a5,2
  if(intr_get() != 0)
    80002bb8:	ef85                	bnez	a5,80002bf0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002bba:	00000097          	auipc	ra,0x0
    80002bbe:	e3e080e7          	jalr	-450(ra) # 800029f8 <devintr>
    80002bc2:	cd1d                	beqz	a0,80002c00 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bc4:	4789                	li	a5,2
    80002bc6:	06f50a63          	beq	a0,a5,80002c3a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bca:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bce:	10049073          	csrw	sstatus,s1
}
    80002bd2:	70a2                	ld	ra,40(sp)
    80002bd4:	7402                	ld	s0,32(sp)
    80002bd6:	64e2                	ld	s1,24(sp)
    80002bd8:	6942                	ld	s2,16(sp)
    80002bda:	69a2                	ld	s3,8(sp)
    80002bdc:	6145                	add	sp,sp,48
    80002bde:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002be0:	00005517          	auipc	a0,0x5
    80002be4:	7f050513          	add	a0,a0,2032 # 800083d0 <states.0+0xc0>
    80002be8:	ffffe097          	auipc	ra,0xffffe
    80002bec:	95a080e7          	jalr	-1702(ra) # 80000542 <panic>
    panic("kerneltrap: interrupts enabled");
    80002bf0:	00006517          	auipc	a0,0x6
    80002bf4:	80850513          	add	a0,a0,-2040 # 800083f8 <states.0+0xe8>
    80002bf8:	ffffe097          	auipc	ra,0xffffe
    80002bfc:	94a080e7          	jalr	-1718(ra) # 80000542 <panic>
    printf("scause %p\n", scause);
    80002c00:	85ce                	mv	a1,s3
    80002c02:	00006517          	auipc	a0,0x6
    80002c06:	81650513          	add	a0,a0,-2026 # 80008418 <states.0+0x108>
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	982080e7          	jalr	-1662(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c12:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c16:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c1a:	00006517          	auipc	a0,0x6
    80002c1e:	80e50513          	add	a0,a0,-2034 # 80008428 <states.0+0x118>
    80002c22:	ffffe097          	auipc	ra,0xffffe
    80002c26:	96a080e7          	jalr	-1686(ra) # 8000058c <printf>
    panic("kerneltrap");
    80002c2a:	00006517          	auipc	a0,0x6
    80002c2e:	81650513          	add	a0,a0,-2026 # 80008440 <states.0+0x130>
    80002c32:	ffffe097          	auipc	ra,0xffffe
    80002c36:	910080e7          	jalr	-1776(ra) # 80000542 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c3a:	fffff097          	auipc	ra,0xfffff
    80002c3e:	dfe080e7          	jalr	-514(ra) # 80001a38 <myproc>
    80002c42:	d541                	beqz	a0,80002bca <kerneltrap+0x38>
    80002c44:	fffff097          	auipc	ra,0xfffff
    80002c48:	df4080e7          	jalr	-524(ra) # 80001a38 <myproc>
    80002c4c:	4d18                	lw	a4,24(a0)
    80002c4e:	478d                	li	a5,3
    80002c50:	f6f71de3          	bne	a4,a5,80002bca <kerneltrap+0x38>
    yield();
    80002c54:	00000097          	auipc	ra,0x0
    80002c58:	824080e7          	jalr	-2012(ra) # 80002478 <yield>
    80002c5c:	b7bd                	j	80002bca <kerneltrap+0x38>

0000000080002c5e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c5e:	1101                	add	sp,sp,-32
    80002c60:	ec06                	sd	ra,24(sp)
    80002c62:	e822                	sd	s0,16(sp)
    80002c64:	e426                	sd	s1,8(sp)
    80002c66:	1000                	add	s0,sp,32
    80002c68:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c6a:	fffff097          	auipc	ra,0xfffff
    80002c6e:	dce080e7          	jalr	-562(ra) # 80001a38 <myproc>
  switch (n) {
    80002c72:	4795                	li	a5,5
    80002c74:	0497e163          	bltu	a5,s1,80002cb6 <argraw+0x58>
    80002c78:	048a                	sll	s1,s1,0x2
    80002c7a:	00005717          	auipc	a4,0x5
    80002c7e:	7fe70713          	add	a4,a4,2046 # 80008478 <states.0+0x168>
    80002c82:	94ba                	add	s1,s1,a4
    80002c84:	409c                	lw	a5,0(s1)
    80002c86:	97ba                	add	a5,a5,a4
    80002c88:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c8a:	713c                	ld	a5,96(a0)
    80002c8c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c8e:	60e2                	ld	ra,24(sp)
    80002c90:	6442                	ld	s0,16(sp)
    80002c92:	64a2                	ld	s1,8(sp)
    80002c94:	6105                	add	sp,sp,32
    80002c96:	8082                	ret
    return p->trapframe->a1;
    80002c98:	713c                	ld	a5,96(a0)
    80002c9a:	7fa8                	ld	a0,120(a5)
    80002c9c:	bfcd                	j	80002c8e <argraw+0x30>
    return p->trapframe->a2;
    80002c9e:	713c                	ld	a5,96(a0)
    80002ca0:	63c8                	ld	a0,128(a5)
    80002ca2:	b7f5                	j	80002c8e <argraw+0x30>
    return p->trapframe->a3;
    80002ca4:	713c                	ld	a5,96(a0)
    80002ca6:	67c8                	ld	a0,136(a5)
    80002ca8:	b7dd                	j	80002c8e <argraw+0x30>
    return p->trapframe->a4;
    80002caa:	713c                	ld	a5,96(a0)
    80002cac:	6bc8                	ld	a0,144(a5)
    80002cae:	b7c5                	j	80002c8e <argraw+0x30>
    return p->trapframe->a5;
    80002cb0:	713c                	ld	a5,96(a0)
    80002cb2:	6fc8                	ld	a0,152(a5)
    80002cb4:	bfe9                	j	80002c8e <argraw+0x30>
  panic("argraw");
    80002cb6:	00005517          	auipc	a0,0x5
    80002cba:	79a50513          	add	a0,a0,1946 # 80008450 <states.0+0x140>
    80002cbe:	ffffe097          	auipc	ra,0xffffe
    80002cc2:	884080e7          	jalr	-1916(ra) # 80000542 <panic>

0000000080002cc6 <fetchaddr>:
{
    80002cc6:	1101                	add	sp,sp,-32
    80002cc8:	ec06                	sd	ra,24(sp)
    80002cca:	e822                	sd	s0,16(sp)
    80002ccc:	e426                	sd	s1,8(sp)
    80002cce:	e04a                	sd	s2,0(sp)
    80002cd0:	1000                	add	s0,sp,32
    80002cd2:	84aa                	mv	s1,a0
    80002cd4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002cd6:	fffff097          	auipc	ra,0xfffff
    80002cda:	d62080e7          	jalr	-670(ra) # 80001a38 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002cde:	653c                	ld	a5,72(a0)
    80002ce0:	02f4f863          	bgeu	s1,a5,80002d10 <fetchaddr+0x4a>
    80002ce4:	00848713          	add	a4,s1,8
    80002ce8:	02e7e663          	bltu	a5,a4,80002d14 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002cec:	46a1                	li	a3,8
    80002cee:	8626                	mv	a2,s1
    80002cf0:	85ca                	mv	a1,s2
    80002cf2:	6928                	ld	a0,80(a0)
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	c3c080e7          	jalr	-964(ra) # 80001930 <copyin>
    80002cfc:	00a03533          	snez	a0,a0
    80002d00:	40a00533          	neg	a0,a0
}
    80002d04:	60e2                	ld	ra,24(sp)
    80002d06:	6442                	ld	s0,16(sp)
    80002d08:	64a2                	ld	s1,8(sp)
    80002d0a:	6902                	ld	s2,0(sp)
    80002d0c:	6105                	add	sp,sp,32
    80002d0e:	8082                	ret
    return -1;
    80002d10:	557d                	li	a0,-1
    80002d12:	bfcd                	j	80002d04 <fetchaddr+0x3e>
    80002d14:	557d                	li	a0,-1
    80002d16:	b7fd                	j	80002d04 <fetchaddr+0x3e>

0000000080002d18 <fetchstr>:
{
    80002d18:	7179                	add	sp,sp,-48
    80002d1a:	f406                	sd	ra,40(sp)
    80002d1c:	f022                	sd	s0,32(sp)
    80002d1e:	ec26                	sd	s1,24(sp)
    80002d20:	e84a                	sd	s2,16(sp)
    80002d22:	e44e                	sd	s3,8(sp)
    80002d24:	1800                	add	s0,sp,48
    80002d26:	892a                	mv	s2,a0
    80002d28:	84ae                	mv	s1,a1
    80002d2a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d2c:	fffff097          	auipc	ra,0xfffff
    80002d30:	d0c080e7          	jalr	-756(ra) # 80001a38 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d34:	86ce                	mv	a3,s3
    80002d36:	864a                	mv	a2,s2
    80002d38:	85a6                	mv	a1,s1
    80002d3a:	6928                	ld	a0,80(a0)
    80002d3c:	fffff097          	auipc	ra,0xfffff
    80002d40:	c0c080e7          	jalr	-1012(ra) # 80001948 <copyinstr>
  if(err < 0)
    80002d44:	00054763          	bltz	a0,80002d52 <fetchstr+0x3a>
  return strlen(buf);
    80002d48:	8526                	mv	a0,s1
    80002d4a:	ffffe097          	auipc	ra,0xffffe
    80002d4e:	130080e7          	jalr	304(ra) # 80000e7a <strlen>
}
    80002d52:	70a2                	ld	ra,40(sp)
    80002d54:	7402                	ld	s0,32(sp)
    80002d56:	64e2                	ld	s1,24(sp)
    80002d58:	6942                	ld	s2,16(sp)
    80002d5a:	69a2                	ld	s3,8(sp)
    80002d5c:	6145                	add	sp,sp,48
    80002d5e:	8082                	ret

0000000080002d60 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d60:	1101                	add	sp,sp,-32
    80002d62:	ec06                	sd	ra,24(sp)
    80002d64:	e822                	sd	s0,16(sp)
    80002d66:	e426                	sd	s1,8(sp)
    80002d68:	1000                	add	s0,sp,32
    80002d6a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d6c:	00000097          	auipc	ra,0x0
    80002d70:	ef2080e7          	jalr	-270(ra) # 80002c5e <argraw>
    80002d74:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d76:	4501                	li	a0,0
    80002d78:	60e2                	ld	ra,24(sp)
    80002d7a:	6442                	ld	s0,16(sp)
    80002d7c:	64a2                	ld	s1,8(sp)
    80002d7e:	6105                	add	sp,sp,32
    80002d80:	8082                	ret

0000000080002d82 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d82:	1101                	add	sp,sp,-32
    80002d84:	ec06                	sd	ra,24(sp)
    80002d86:	e822                	sd	s0,16(sp)
    80002d88:	e426                	sd	s1,8(sp)
    80002d8a:	1000                	add	s0,sp,32
    80002d8c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d8e:	00000097          	auipc	ra,0x0
    80002d92:	ed0080e7          	jalr	-304(ra) # 80002c5e <argraw>
    80002d96:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d98:	4501                	li	a0,0
    80002d9a:	60e2                	ld	ra,24(sp)
    80002d9c:	6442                	ld	s0,16(sp)
    80002d9e:	64a2                	ld	s1,8(sp)
    80002da0:	6105                	add	sp,sp,32
    80002da2:	8082                	ret

0000000080002da4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002da4:	1101                	add	sp,sp,-32
    80002da6:	ec06                	sd	ra,24(sp)
    80002da8:	e822                	sd	s0,16(sp)
    80002daa:	e426                	sd	s1,8(sp)
    80002dac:	e04a                	sd	s2,0(sp)
    80002dae:	1000                	add	s0,sp,32
    80002db0:	84ae                	mv	s1,a1
    80002db2:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002db4:	00000097          	auipc	ra,0x0
    80002db8:	eaa080e7          	jalr	-342(ra) # 80002c5e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002dbc:	864a                	mv	a2,s2
    80002dbe:	85a6                	mv	a1,s1
    80002dc0:	00000097          	auipc	ra,0x0
    80002dc4:	f58080e7          	jalr	-168(ra) # 80002d18 <fetchstr>
}
    80002dc8:	60e2                	ld	ra,24(sp)
    80002dca:	6442                	ld	s0,16(sp)
    80002dcc:	64a2                	ld	s1,8(sp)
    80002dce:	6902                	ld	s2,0(sp)
    80002dd0:	6105                	add	sp,sp,32
    80002dd2:	8082                	ret

0000000080002dd4 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002dd4:	1101                	add	sp,sp,-32
    80002dd6:	ec06                	sd	ra,24(sp)
    80002dd8:	e822                	sd	s0,16(sp)
    80002dda:	e426                	sd	s1,8(sp)
    80002ddc:	e04a                	sd	s2,0(sp)
    80002dde:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002de0:	fffff097          	auipc	ra,0xfffff
    80002de4:	c58080e7          	jalr	-936(ra) # 80001a38 <myproc>
    80002de8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002dea:	06053903          	ld	s2,96(a0)
    80002dee:	0a893783          	ld	a5,168(s2)
    80002df2:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002df6:	37fd                	addw	a5,a5,-1
    80002df8:	4751                	li	a4,20
    80002dfa:	00f76f63          	bltu	a4,a5,80002e18 <syscall+0x44>
    80002dfe:	00369713          	sll	a4,a3,0x3
    80002e02:	00005797          	auipc	a5,0x5
    80002e06:	68e78793          	add	a5,a5,1678 # 80008490 <syscalls>
    80002e0a:	97ba                	add	a5,a5,a4
    80002e0c:	639c                	ld	a5,0(a5)
    80002e0e:	c789                	beqz	a5,80002e18 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e10:	9782                	jalr	a5
    80002e12:	06a93823          	sd	a0,112(s2)
    80002e16:	a839                	j	80002e34 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e18:	16048613          	add	a2,s1,352
    80002e1c:	5c8c                	lw	a1,56(s1)
    80002e1e:	00005517          	auipc	a0,0x5
    80002e22:	63a50513          	add	a0,a0,1594 # 80008458 <states.0+0x148>
    80002e26:	ffffd097          	auipc	ra,0xffffd
    80002e2a:	766080e7          	jalr	1894(ra) # 8000058c <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e2e:	70bc                	ld	a5,96(s1)
    80002e30:	577d                	li	a4,-1
    80002e32:	fbb8                	sd	a4,112(a5)
  }
}
    80002e34:	60e2                	ld	ra,24(sp)
    80002e36:	6442                	ld	s0,16(sp)
    80002e38:	64a2                	ld	s1,8(sp)
    80002e3a:	6902                	ld	s2,0(sp)
    80002e3c:	6105                	add	sp,sp,32
    80002e3e:	8082                	ret

0000000080002e40 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e40:	1101                	add	sp,sp,-32
    80002e42:	ec06                	sd	ra,24(sp)
    80002e44:	e822                	sd	s0,16(sp)
    80002e46:	1000                	add	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e48:	fec40593          	add	a1,s0,-20
    80002e4c:	4501                	li	a0,0
    80002e4e:	00000097          	auipc	ra,0x0
    80002e52:	f12080e7          	jalr	-238(ra) # 80002d60 <argint>
    return -1;
    80002e56:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e58:	00054963          	bltz	a0,80002e6a <sys_exit+0x2a>
  exit(n);
    80002e5c:	fec42503          	lw	a0,-20(s0)
    80002e60:	fffff097          	auipc	ra,0xfffff
    80002e64:	50e080e7          	jalr	1294(ra) # 8000236e <exit>
  return 0;  // not reached
    80002e68:	4781                	li	a5,0
}
    80002e6a:	853e                	mv	a0,a5
    80002e6c:	60e2                	ld	ra,24(sp)
    80002e6e:	6442                	ld	s0,16(sp)
    80002e70:	6105                	add	sp,sp,32
    80002e72:	8082                	ret

0000000080002e74 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e74:	1141                	add	sp,sp,-16
    80002e76:	e406                	sd	ra,8(sp)
    80002e78:	e022                	sd	s0,0(sp)
    80002e7a:	0800                	add	s0,sp,16
  return myproc()->pid;
    80002e7c:	fffff097          	auipc	ra,0xfffff
    80002e80:	bbc080e7          	jalr	-1092(ra) # 80001a38 <myproc>
}
    80002e84:	5d08                	lw	a0,56(a0)
    80002e86:	60a2                	ld	ra,8(sp)
    80002e88:	6402                	ld	s0,0(sp)
    80002e8a:	0141                	add	sp,sp,16
    80002e8c:	8082                	ret

0000000080002e8e <sys_fork>:

uint64
sys_fork(void)
{
    80002e8e:	1141                	add	sp,sp,-16
    80002e90:	e406                	sd	ra,8(sp)
    80002e92:	e022                	sd	s0,0(sp)
    80002e94:	0800                	add	s0,sp,16
  return fork();
    80002e96:	fffff097          	auipc	ra,0xfffff
    80002e9a:	184080e7          	jalr	388(ra) # 8000201a <fork>
}
    80002e9e:	60a2                	ld	ra,8(sp)
    80002ea0:	6402                	ld	s0,0(sp)
    80002ea2:	0141                	add	sp,sp,16
    80002ea4:	8082                	ret

0000000080002ea6 <sys_wait>:

uint64
sys_wait(void)
{
    80002ea6:	1101                	add	sp,sp,-32
    80002ea8:	ec06                	sd	ra,24(sp)
    80002eaa:	e822                	sd	s0,16(sp)
    80002eac:	1000                	add	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002eae:	fe840593          	add	a1,s0,-24
    80002eb2:	4501                	li	a0,0
    80002eb4:	00000097          	auipc	ra,0x0
    80002eb8:	ece080e7          	jalr	-306(ra) # 80002d82 <argaddr>
    80002ebc:	87aa                	mv	a5,a0
    return -1;
    80002ebe:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ec0:	0007c863          	bltz	a5,80002ed0 <sys_wait+0x2a>
  return wait(p);
    80002ec4:	fe843503          	ld	a0,-24(s0)
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	66a080e7          	jalr	1642(ra) # 80002532 <wait>
}
    80002ed0:	60e2                	ld	ra,24(sp)
    80002ed2:	6442                	ld	s0,16(sp)
    80002ed4:	6105                	add	sp,sp,32
    80002ed6:	8082                	ret

0000000080002ed8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ed8:	7179                	add	sp,sp,-48
    80002eda:	f406                	sd	ra,40(sp)
    80002edc:	f022                	sd	s0,32(sp)
    80002ede:	ec26                	sd	s1,24(sp)
    80002ee0:	1800                	add	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002ee2:	fdc40593          	add	a1,s0,-36
    80002ee6:	4501                	li	a0,0
    80002ee8:	00000097          	auipc	ra,0x0
    80002eec:	e78080e7          	jalr	-392(ra) # 80002d60 <argint>
    80002ef0:	87aa                	mv	a5,a0
    return -1;
    80002ef2:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002ef4:	0207c063          	bltz	a5,80002f14 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002ef8:	fffff097          	auipc	ra,0xfffff
    80002efc:	b40080e7          	jalr	-1216(ra) # 80001a38 <myproc>
    80002f00:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002f02:	fdc42503          	lw	a0,-36(s0)
    80002f06:	fffff097          	auipc	ra,0xfffff
    80002f0a:	038080e7          	jalr	56(ra) # 80001f3e <growproc>
    80002f0e:	00054863          	bltz	a0,80002f1e <sys_sbrk+0x46>
    return -1;
  return addr;
    80002f12:	8526                	mv	a0,s1
}
    80002f14:	70a2                	ld	ra,40(sp)
    80002f16:	7402                	ld	s0,32(sp)
    80002f18:	64e2                	ld	s1,24(sp)
    80002f1a:	6145                	add	sp,sp,48
    80002f1c:	8082                	ret
    return -1;
    80002f1e:	557d                	li	a0,-1
    80002f20:	bfd5                	j	80002f14 <sys_sbrk+0x3c>

0000000080002f22 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f22:	7139                	add	sp,sp,-64
    80002f24:	fc06                	sd	ra,56(sp)
    80002f26:	f822                	sd	s0,48(sp)
    80002f28:	f426                	sd	s1,40(sp)
    80002f2a:	f04a                	sd	s2,32(sp)
    80002f2c:	ec4e                	sd	s3,24(sp)
    80002f2e:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f30:	fcc40593          	add	a1,s0,-52
    80002f34:	4501                	li	a0,0
    80002f36:	00000097          	auipc	ra,0x0
    80002f3a:	e2a080e7          	jalr	-470(ra) # 80002d60 <argint>
    return -1;
    80002f3e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f40:	06054563          	bltz	a0,80002faa <sys_sleep+0x88>
  acquire(&tickslock);
    80002f44:	00015517          	auipc	a0,0x15
    80002f48:	a2450513          	add	a0,a0,-1500 # 80017968 <tickslock>
    80002f4c:	ffffe097          	auipc	ra,0xffffe
    80002f50:	cb0080e7          	jalr	-848(ra) # 80000bfc <acquire>
  ticks0 = ticks;
    80002f54:	00006917          	auipc	s2,0x6
    80002f58:	0cc92903          	lw	s2,204(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002f5c:	fcc42783          	lw	a5,-52(s0)
    80002f60:	cf85                	beqz	a5,80002f98 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f62:	00015997          	auipc	s3,0x15
    80002f66:	a0698993          	add	s3,s3,-1530 # 80017968 <tickslock>
    80002f6a:	00006497          	auipc	s1,0x6
    80002f6e:	0b648493          	add	s1,s1,182 # 80009020 <ticks>
    if(myproc()->killed){
    80002f72:	fffff097          	auipc	ra,0xfffff
    80002f76:	ac6080e7          	jalr	-1338(ra) # 80001a38 <myproc>
    80002f7a:	591c                	lw	a5,48(a0)
    80002f7c:	ef9d                	bnez	a5,80002fba <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f7e:	85ce                	mv	a1,s3
    80002f80:	8526                	mv	a0,s1
    80002f82:	fffff097          	auipc	ra,0xfffff
    80002f86:	532080e7          	jalr	1330(ra) # 800024b4 <sleep>
  while(ticks - ticks0 < n){
    80002f8a:	409c                	lw	a5,0(s1)
    80002f8c:	412787bb          	subw	a5,a5,s2
    80002f90:	fcc42703          	lw	a4,-52(s0)
    80002f94:	fce7efe3          	bltu	a5,a4,80002f72 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f98:	00015517          	auipc	a0,0x15
    80002f9c:	9d050513          	add	a0,a0,-1584 # 80017968 <tickslock>
    80002fa0:	ffffe097          	auipc	ra,0xffffe
    80002fa4:	d10080e7          	jalr	-752(ra) # 80000cb0 <release>
  return 0;
    80002fa8:	4781                	li	a5,0
}
    80002faa:	853e                	mv	a0,a5
    80002fac:	70e2                	ld	ra,56(sp)
    80002fae:	7442                	ld	s0,48(sp)
    80002fb0:	74a2                	ld	s1,40(sp)
    80002fb2:	7902                	ld	s2,32(sp)
    80002fb4:	69e2                	ld	s3,24(sp)
    80002fb6:	6121                	add	sp,sp,64
    80002fb8:	8082                	ret
      release(&tickslock);
    80002fba:	00015517          	auipc	a0,0x15
    80002fbe:	9ae50513          	add	a0,a0,-1618 # 80017968 <tickslock>
    80002fc2:	ffffe097          	auipc	ra,0xffffe
    80002fc6:	cee080e7          	jalr	-786(ra) # 80000cb0 <release>
      return -1;
    80002fca:	57fd                	li	a5,-1
    80002fcc:	bff9                	j	80002faa <sys_sleep+0x88>

0000000080002fce <sys_kill>:

uint64
sys_kill(void)
{
    80002fce:	1101                	add	sp,sp,-32
    80002fd0:	ec06                	sd	ra,24(sp)
    80002fd2:	e822                	sd	s0,16(sp)
    80002fd4:	1000                	add	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002fd6:	fec40593          	add	a1,s0,-20
    80002fda:	4501                	li	a0,0
    80002fdc:	00000097          	auipc	ra,0x0
    80002fe0:	d84080e7          	jalr	-636(ra) # 80002d60 <argint>
    80002fe4:	87aa                	mv	a5,a0
    return -1;
    80002fe6:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002fe8:	0007c863          	bltz	a5,80002ff8 <sys_kill+0x2a>
  return kill(pid);
    80002fec:	fec42503          	lw	a0,-20(s0)
    80002ff0:	fffff097          	auipc	ra,0xfffff
    80002ff4:	6ae080e7          	jalr	1710(ra) # 8000269e <kill>
}
    80002ff8:	60e2                	ld	ra,24(sp)
    80002ffa:	6442                	ld	s0,16(sp)
    80002ffc:	6105                	add	sp,sp,32
    80002ffe:	8082                	ret

0000000080003000 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003000:	1101                	add	sp,sp,-32
    80003002:	ec06                	sd	ra,24(sp)
    80003004:	e822                	sd	s0,16(sp)
    80003006:	e426                	sd	s1,8(sp)
    80003008:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000300a:	00015517          	auipc	a0,0x15
    8000300e:	95e50513          	add	a0,a0,-1698 # 80017968 <tickslock>
    80003012:	ffffe097          	auipc	ra,0xffffe
    80003016:	bea080e7          	jalr	-1046(ra) # 80000bfc <acquire>
  xticks = ticks;
    8000301a:	00006497          	auipc	s1,0x6
    8000301e:	0064a483          	lw	s1,6(s1) # 80009020 <ticks>
  release(&tickslock);
    80003022:	00015517          	auipc	a0,0x15
    80003026:	94650513          	add	a0,a0,-1722 # 80017968 <tickslock>
    8000302a:	ffffe097          	auipc	ra,0xffffe
    8000302e:	c86080e7          	jalr	-890(ra) # 80000cb0 <release>
  return xticks;
}
    80003032:	02049513          	sll	a0,s1,0x20
    80003036:	9101                	srl	a0,a0,0x20
    80003038:	60e2                	ld	ra,24(sp)
    8000303a:	6442                	ld	s0,16(sp)
    8000303c:	64a2                	ld	s1,8(sp)
    8000303e:	6105                	add	sp,sp,32
    80003040:	8082                	ret

0000000080003042 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003042:	7179                	add	sp,sp,-48
    80003044:	f406                	sd	ra,40(sp)
    80003046:	f022                	sd	s0,32(sp)
    80003048:	ec26                	sd	s1,24(sp)
    8000304a:	e84a                	sd	s2,16(sp)
    8000304c:	e44e                	sd	s3,8(sp)
    8000304e:	e052                	sd	s4,0(sp)
    80003050:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003052:	00005597          	auipc	a1,0x5
    80003056:	4ee58593          	add	a1,a1,1262 # 80008540 <syscalls+0xb0>
    8000305a:	00015517          	auipc	a0,0x15
    8000305e:	92650513          	add	a0,a0,-1754 # 80017980 <bcache>
    80003062:	ffffe097          	auipc	ra,0xffffe
    80003066:	b0a080e7          	jalr	-1270(ra) # 80000b6c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000306a:	0001d797          	auipc	a5,0x1d
    8000306e:	91678793          	add	a5,a5,-1770 # 8001f980 <bcache+0x8000>
    80003072:	0001d717          	auipc	a4,0x1d
    80003076:	b7670713          	add	a4,a4,-1162 # 8001fbe8 <bcache+0x8268>
    8000307a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000307e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003082:	00015497          	auipc	s1,0x15
    80003086:	91648493          	add	s1,s1,-1770 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    8000308a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000308c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000308e:	00005a17          	auipc	s4,0x5
    80003092:	4baa0a13          	add	s4,s4,1210 # 80008548 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003096:	2b893783          	ld	a5,696(s2)
    8000309a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000309c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030a0:	85d2                	mv	a1,s4
    800030a2:	01048513          	add	a0,s1,16
    800030a6:	00001097          	auipc	ra,0x1
    800030aa:	480080e7          	jalr	1152(ra) # 80004526 <initsleeplock>
    bcache.head.next->prev = b;
    800030ae:	2b893783          	ld	a5,696(s2)
    800030b2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030b4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030b8:	45848493          	add	s1,s1,1112
    800030bc:	fd349de3          	bne	s1,s3,80003096 <binit+0x54>
  }
}
    800030c0:	70a2                	ld	ra,40(sp)
    800030c2:	7402                	ld	s0,32(sp)
    800030c4:	64e2                	ld	s1,24(sp)
    800030c6:	6942                	ld	s2,16(sp)
    800030c8:	69a2                	ld	s3,8(sp)
    800030ca:	6a02                	ld	s4,0(sp)
    800030cc:	6145                	add	sp,sp,48
    800030ce:	8082                	ret

00000000800030d0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030d0:	7179                	add	sp,sp,-48
    800030d2:	f406                	sd	ra,40(sp)
    800030d4:	f022                	sd	s0,32(sp)
    800030d6:	ec26                	sd	s1,24(sp)
    800030d8:	e84a                	sd	s2,16(sp)
    800030da:	e44e                	sd	s3,8(sp)
    800030dc:	1800                	add	s0,sp,48
    800030de:	892a                	mv	s2,a0
    800030e0:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800030e2:	00015517          	auipc	a0,0x15
    800030e6:	89e50513          	add	a0,a0,-1890 # 80017980 <bcache>
    800030ea:	ffffe097          	auipc	ra,0xffffe
    800030ee:	b12080e7          	jalr	-1262(ra) # 80000bfc <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030f2:	0001d497          	auipc	s1,0x1d
    800030f6:	b464b483          	ld	s1,-1210(s1) # 8001fc38 <bcache+0x82b8>
    800030fa:	0001d797          	auipc	a5,0x1d
    800030fe:	aee78793          	add	a5,a5,-1298 # 8001fbe8 <bcache+0x8268>
    80003102:	02f48f63          	beq	s1,a5,80003140 <bread+0x70>
    80003106:	873e                	mv	a4,a5
    80003108:	a021                	j	80003110 <bread+0x40>
    8000310a:	68a4                	ld	s1,80(s1)
    8000310c:	02e48a63          	beq	s1,a4,80003140 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003110:	449c                	lw	a5,8(s1)
    80003112:	ff279ce3          	bne	a5,s2,8000310a <bread+0x3a>
    80003116:	44dc                	lw	a5,12(s1)
    80003118:	ff3799e3          	bne	a5,s3,8000310a <bread+0x3a>
      b->refcnt++;
    8000311c:	40bc                	lw	a5,64(s1)
    8000311e:	2785                	addw	a5,a5,1
    80003120:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003122:	00015517          	auipc	a0,0x15
    80003126:	85e50513          	add	a0,a0,-1954 # 80017980 <bcache>
    8000312a:	ffffe097          	auipc	ra,0xffffe
    8000312e:	b86080e7          	jalr	-1146(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    80003132:	01048513          	add	a0,s1,16
    80003136:	00001097          	auipc	ra,0x1
    8000313a:	42a080e7          	jalr	1066(ra) # 80004560 <acquiresleep>
      return b;
    8000313e:	a8b9                	j	8000319c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003140:	0001d497          	auipc	s1,0x1d
    80003144:	af04b483          	ld	s1,-1296(s1) # 8001fc30 <bcache+0x82b0>
    80003148:	0001d797          	auipc	a5,0x1d
    8000314c:	aa078793          	add	a5,a5,-1376 # 8001fbe8 <bcache+0x8268>
    80003150:	00f48863          	beq	s1,a5,80003160 <bread+0x90>
    80003154:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003156:	40bc                	lw	a5,64(s1)
    80003158:	cf81                	beqz	a5,80003170 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000315a:	64a4                	ld	s1,72(s1)
    8000315c:	fee49de3          	bne	s1,a4,80003156 <bread+0x86>
  panic("bget: no buffers");
    80003160:	00005517          	auipc	a0,0x5
    80003164:	3f050513          	add	a0,a0,1008 # 80008550 <syscalls+0xc0>
    80003168:	ffffd097          	auipc	ra,0xffffd
    8000316c:	3da080e7          	jalr	986(ra) # 80000542 <panic>
      b->dev = dev;
    80003170:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003174:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003178:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000317c:	4785                	li	a5,1
    8000317e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003180:	00015517          	auipc	a0,0x15
    80003184:	80050513          	add	a0,a0,-2048 # 80017980 <bcache>
    80003188:	ffffe097          	auipc	ra,0xffffe
    8000318c:	b28080e7          	jalr	-1240(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    80003190:	01048513          	add	a0,s1,16
    80003194:	00001097          	auipc	ra,0x1
    80003198:	3cc080e7          	jalr	972(ra) # 80004560 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000319c:	409c                	lw	a5,0(s1)
    8000319e:	cb89                	beqz	a5,800031b0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031a0:	8526                	mv	a0,s1
    800031a2:	70a2                	ld	ra,40(sp)
    800031a4:	7402                	ld	s0,32(sp)
    800031a6:	64e2                	ld	s1,24(sp)
    800031a8:	6942                	ld	s2,16(sp)
    800031aa:	69a2                	ld	s3,8(sp)
    800031ac:	6145                	add	sp,sp,48
    800031ae:	8082                	ret
    virtio_disk_rw(b, 0);
    800031b0:	4581                	li	a1,0
    800031b2:	8526                	mv	a0,s1
    800031b4:	00003097          	auipc	ra,0x3
    800031b8:	f24080e7          	jalr	-220(ra) # 800060d8 <virtio_disk_rw>
    b->valid = 1;
    800031bc:	4785                	li	a5,1
    800031be:	c09c                	sw	a5,0(s1)
  return b;
    800031c0:	b7c5                	j	800031a0 <bread+0xd0>

00000000800031c2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031c2:	1101                	add	sp,sp,-32
    800031c4:	ec06                	sd	ra,24(sp)
    800031c6:	e822                	sd	s0,16(sp)
    800031c8:	e426                	sd	s1,8(sp)
    800031ca:	1000                	add	s0,sp,32
    800031cc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031ce:	0541                	add	a0,a0,16
    800031d0:	00001097          	auipc	ra,0x1
    800031d4:	42a080e7          	jalr	1066(ra) # 800045fa <holdingsleep>
    800031d8:	cd01                	beqz	a0,800031f0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031da:	4585                	li	a1,1
    800031dc:	8526                	mv	a0,s1
    800031de:	00003097          	auipc	ra,0x3
    800031e2:	efa080e7          	jalr	-262(ra) # 800060d8 <virtio_disk_rw>
}
    800031e6:	60e2                	ld	ra,24(sp)
    800031e8:	6442                	ld	s0,16(sp)
    800031ea:	64a2                	ld	s1,8(sp)
    800031ec:	6105                	add	sp,sp,32
    800031ee:	8082                	ret
    panic("bwrite");
    800031f0:	00005517          	auipc	a0,0x5
    800031f4:	37850513          	add	a0,a0,888 # 80008568 <syscalls+0xd8>
    800031f8:	ffffd097          	auipc	ra,0xffffd
    800031fc:	34a080e7          	jalr	842(ra) # 80000542 <panic>

0000000080003200 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003200:	1101                	add	sp,sp,-32
    80003202:	ec06                	sd	ra,24(sp)
    80003204:	e822                	sd	s0,16(sp)
    80003206:	e426                	sd	s1,8(sp)
    80003208:	e04a                	sd	s2,0(sp)
    8000320a:	1000                	add	s0,sp,32
    8000320c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000320e:	01050913          	add	s2,a0,16
    80003212:	854a                	mv	a0,s2
    80003214:	00001097          	auipc	ra,0x1
    80003218:	3e6080e7          	jalr	998(ra) # 800045fa <holdingsleep>
    8000321c:	c925                	beqz	a0,8000328c <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    8000321e:	854a                	mv	a0,s2
    80003220:	00001097          	auipc	ra,0x1
    80003224:	396080e7          	jalr	918(ra) # 800045b6 <releasesleep>

  acquire(&bcache.lock);
    80003228:	00014517          	auipc	a0,0x14
    8000322c:	75850513          	add	a0,a0,1880 # 80017980 <bcache>
    80003230:	ffffe097          	auipc	ra,0xffffe
    80003234:	9cc080e7          	jalr	-1588(ra) # 80000bfc <acquire>
  b->refcnt--;
    80003238:	40bc                	lw	a5,64(s1)
    8000323a:	37fd                	addw	a5,a5,-1
    8000323c:	0007871b          	sext.w	a4,a5
    80003240:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003242:	e71d                	bnez	a4,80003270 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003244:	68b8                	ld	a4,80(s1)
    80003246:	64bc                	ld	a5,72(s1)
    80003248:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    8000324a:	68b8                	ld	a4,80(s1)
    8000324c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000324e:	0001c797          	auipc	a5,0x1c
    80003252:	73278793          	add	a5,a5,1842 # 8001f980 <bcache+0x8000>
    80003256:	2b87b703          	ld	a4,696(a5)
    8000325a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000325c:	0001d717          	auipc	a4,0x1d
    80003260:	98c70713          	add	a4,a4,-1652 # 8001fbe8 <bcache+0x8268>
    80003264:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003266:	2b87b703          	ld	a4,696(a5)
    8000326a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000326c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003270:	00014517          	auipc	a0,0x14
    80003274:	71050513          	add	a0,a0,1808 # 80017980 <bcache>
    80003278:	ffffe097          	auipc	ra,0xffffe
    8000327c:	a38080e7          	jalr	-1480(ra) # 80000cb0 <release>
}
    80003280:	60e2                	ld	ra,24(sp)
    80003282:	6442                	ld	s0,16(sp)
    80003284:	64a2                	ld	s1,8(sp)
    80003286:	6902                	ld	s2,0(sp)
    80003288:	6105                	add	sp,sp,32
    8000328a:	8082                	ret
    panic("brelse");
    8000328c:	00005517          	auipc	a0,0x5
    80003290:	2e450513          	add	a0,a0,740 # 80008570 <syscalls+0xe0>
    80003294:	ffffd097          	auipc	ra,0xffffd
    80003298:	2ae080e7          	jalr	686(ra) # 80000542 <panic>

000000008000329c <bpin>:

void
bpin(struct buf *b) {
    8000329c:	1101                	add	sp,sp,-32
    8000329e:	ec06                	sd	ra,24(sp)
    800032a0:	e822                	sd	s0,16(sp)
    800032a2:	e426                	sd	s1,8(sp)
    800032a4:	1000                	add	s0,sp,32
    800032a6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032a8:	00014517          	auipc	a0,0x14
    800032ac:	6d850513          	add	a0,a0,1752 # 80017980 <bcache>
    800032b0:	ffffe097          	auipc	ra,0xffffe
    800032b4:	94c080e7          	jalr	-1716(ra) # 80000bfc <acquire>
  b->refcnt++;
    800032b8:	40bc                	lw	a5,64(s1)
    800032ba:	2785                	addw	a5,a5,1
    800032bc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032be:	00014517          	auipc	a0,0x14
    800032c2:	6c250513          	add	a0,a0,1730 # 80017980 <bcache>
    800032c6:	ffffe097          	auipc	ra,0xffffe
    800032ca:	9ea080e7          	jalr	-1558(ra) # 80000cb0 <release>
}
    800032ce:	60e2                	ld	ra,24(sp)
    800032d0:	6442                	ld	s0,16(sp)
    800032d2:	64a2                	ld	s1,8(sp)
    800032d4:	6105                	add	sp,sp,32
    800032d6:	8082                	ret

00000000800032d8 <bunpin>:

void
bunpin(struct buf *b) {
    800032d8:	1101                	add	sp,sp,-32
    800032da:	ec06                	sd	ra,24(sp)
    800032dc:	e822                	sd	s0,16(sp)
    800032de:	e426                	sd	s1,8(sp)
    800032e0:	1000                	add	s0,sp,32
    800032e2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032e4:	00014517          	auipc	a0,0x14
    800032e8:	69c50513          	add	a0,a0,1692 # 80017980 <bcache>
    800032ec:	ffffe097          	auipc	ra,0xffffe
    800032f0:	910080e7          	jalr	-1776(ra) # 80000bfc <acquire>
  b->refcnt--;
    800032f4:	40bc                	lw	a5,64(s1)
    800032f6:	37fd                	addw	a5,a5,-1
    800032f8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032fa:	00014517          	auipc	a0,0x14
    800032fe:	68650513          	add	a0,a0,1670 # 80017980 <bcache>
    80003302:	ffffe097          	auipc	ra,0xffffe
    80003306:	9ae080e7          	jalr	-1618(ra) # 80000cb0 <release>
}
    8000330a:	60e2                	ld	ra,24(sp)
    8000330c:	6442                	ld	s0,16(sp)
    8000330e:	64a2                	ld	s1,8(sp)
    80003310:	6105                	add	sp,sp,32
    80003312:	8082                	ret

0000000080003314 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003314:	1101                	add	sp,sp,-32
    80003316:	ec06                	sd	ra,24(sp)
    80003318:	e822                	sd	s0,16(sp)
    8000331a:	e426                	sd	s1,8(sp)
    8000331c:	e04a                	sd	s2,0(sp)
    8000331e:	1000                	add	s0,sp,32
    80003320:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003322:	00d5d59b          	srlw	a1,a1,0xd
    80003326:	0001d797          	auipc	a5,0x1d
    8000332a:	d367a783          	lw	a5,-714(a5) # 8002005c <sb+0x1c>
    8000332e:	9dbd                	addw	a1,a1,a5
    80003330:	00000097          	auipc	ra,0x0
    80003334:	da0080e7          	jalr	-608(ra) # 800030d0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003338:	0074f713          	and	a4,s1,7
    8000333c:	4785                	li	a5,1
    8000333e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003342:	14ce                	sll	s1,s1,0x33
    80003344:	90d9                	srl	s1,s1,0x36
    80003346:	00950733          	add	a4,a0,s1
    8000334a:	05874703          	lbu	a4,88(a4)
    8000334e:	00e7f6b3          	and	a3,a5,a4
    80003352:	c69d                	beqz	a3,80003380 <bfree+0x6c>
    80003354:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003356:	94aa                	add	s1,s1,a0
    80003358:	fff7c793          	not	a5,a5
    8000335c:	8f7d                	and	a4,a4,a5
    8000335e:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003362:	00001097          	auipc	ra,0x1
    80003366:	0d8080e7          	jalr	216(ra) # 8000443a <log_write>
  brelse(bp);
    8000336a:	854a                	mv	a0,s2
    8000336c:	00000097          	auipc	ra,0x0
    80003370:	e94080e7          	jalr	-364(ra) # 80003200 <brelse>
}
    80003374:	60e2                	ld	ra,24(sp)
    80003376:	6442                	ld	s0,16(sp)
    80003378:	64a2                	ld	s1,8(sp)
    8000337a:	6902                	ld	s2,0(sp)
    8000337c:	6105                	add	sp,sp,32
    8000337e:	8082                	ret
    panic("freeing free block");
    80003380:	00005517          	auipc	a0,0x5
    80003384:	1f850513          	add	a0,a0,504 # 80008578 <syscalls+0xe8>
    80003388:	ffffd097          	auipc	ra,0xffffd
    8000338c:	1ba080e7          	jalr	442(ra) # 80000542 <panic>

0000000080003390 <balloc>:
{
    80003390:	711d                	add	sp,sp,-96
    80003392:	ec86                	sd	ra,88(sp)
    80003394:	e8a2                	sd	s0,80(sp)
    80003396:	e4a6                	sd	s1,72(sp)
    80003398:	e0ca                	sd	s2,64(sp)
    8000339a:	fc4e                	sd	s3,56(sp)
    8000339c:	f852                	sd	s4,48(sp)
    8000339e:	f456                	sd	s5,40(sp)
    800033a0:	f05a                	sd	s6,32(sp)
    800033a2:	ec5e                	sd	s7,24(sp)
    800033a4:	e862                	sd	s8,16(sp)
    800033a6:	e466                	sd	s9,8(sp)
    800033a8:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033aa:	0001d797          	auipc	a5,0x1d
    800033ae:	c9a7a783          	lw	a5,-870(a5) # 80020044 <sb+0x4>
    800033b2:	cbc1                	beqz	a5,80003442 <balloc+0xb2>
    800033b4:	8baa                	mv	s7,a0
    800033b6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033b8:	0001db17          	auipc	s6,0x1d
    800033bc:	c88b0b13          	add	s6,s6,-888 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033c0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033c2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033c4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033c6:	6c89                	lui	s9,0x2
    800033c8:	a831                	j	800033e4 <balloc+0x54>
    brelse(bp);
    800033ca:	854a                	mv	a0,s2
    800033cc:	00000097          	auipc	ra,0x0
    800033d0:	e34080e7          	jalr	-460(ra) # 80003200 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033d4:	015c87bb          	addw	a5,s9,s5
    800033d8:	00078a9b          	sext.w	s5,a5
    800033dc:	004b2703          	lw	a4,4(s6)
    800033e0:	06eaf163          	bgeu	s5,a4,80003442 <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    800033e4:	41fad79b          	sraw	a5,s5,0x1f
    800033e8:	0137d79b          	srlw	a5,a5,0x13
    800033ec:	015787bb          	addw	a5,a5,s5
    800033f0:	40d7d79b          	sraw	a5,a5,0xd
    800033f4:	01cb2583          	lw	a1,28(s6)
    800033f8:	9dbd                	addw	a1,a1,a5
    800033fa:	855e                	mv	a0,s7
    800033fc:	00000097          	auipc	ra,0x0
    80003400:	cd4080e7          	jalr	-812(ra) # 800030d0 <bread>
    80003404:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003406:	004b2503          	lw	a0,4(s6)
    8000340a:	000a849b          	sext.w	s1,s5
    8000340e:	8762                	mv	a4,s8
    80003410:	faa4fde3          	bgeu	s1,a0,800033ca <balloc+0x3a>
      m = 1 << (bi % 8);
    80003414:	00777693          	and	a3,a4,7
    80003418:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000341c:	41f7579b          	sraw	a5,a4,0x1f
    80003420:	01d7d79b          	srlw	a5,a5,0x1d
    80003424:	9fb9                	addw	a5,a5,a4
    80003426:	4037d79b          	sraw	a5,a5,0x3
    8000342a:	00f90633          	add	a2,s2,a5
    8000342e:	05864603          	lbu	a2,88(a2)
    80003432:	00c6f5b3          	and	a1,a3,a2
    80003436:	cd91                	beqz	a1,80003452 <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003438:	2705                	addw	a4,a4,1
    8000343a:	2485                	addw	s1,s1,1
    8000343c:	fd471ae3          	bne	a4,s4,80003410 <balloc+0x80>
    80003440:	b769                	j	800033ca <balloc+0x3a>
  panic("balloc: out of blocks");
    80003442:	00005517          	auipc	a0,0x5
    80003446:	14e50513          	add	a0,a0,334 # 80008590 <syscalls+0x100>
    8000344a:	ffffd097          	auipc	ra,0xffffd
    8000344e:	0f8080e7          	jalr	248(ra) # 80000542 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003452:	97ca                	add	a5,a5,s2
    80003454:	8e55                	or	a2,a2,a3
    80003456:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000345a:	854a                	mv	a0,s2
    8000345c:	00001097          	auipc	ra,0x1
    80003460:	fde080e7          	jalr	-34(ra) # 8000443a <log_write>
        brelse(bp);
    80003464:	854a                	mv	a0,s2
    80003466:	00000097          	auipc	ra,0x0
    8000346a:	d9a080e7          	jalr	-614(ra) # 80003200 <brelse>
  bp = bread(dev, bno);
    8000346e:	85a6                	mv	a1,s1
    80003470:	855e                	mv	a0,s7
    80003472:	00000097          	auipc	ra,0x0
    80003476:	c5e080e7          	jalr	-930(ra) # 800030d0 <bread>
    8000347a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000347c:	40000613          	li	a2,1024
    80003480:	4581                	li	a1,0
    80003482:	05850513          	add	a0,a0,88
    80003486:	ffffe097          	auipc	ra,0xffffe
    8000348a:	872080e7          	jalr	-1934(ra) # 80000cf8 <memset>
  log_write(bp);
    8000348e:	854a                	mv	a0,s2
    80003490:	00001097          	auipc	ra,0x1
    80003494:	faa080e7          	jalr	-86(ra) # 8000443a <log_write>
  brelse(bp);
    80003498:	854a                	mv	a0,s2
    8000349a:	00000097          	auipc	ra,0x0
    8000349e:	d66080e7          	jalr	-666(ra) # 80003200 <brelse>
}
    800034a2:	8526                	mv	a0,s1
    800034a4:	60e6                	ld	ra,88(sp)
    800034a6:	6446                	ld	s0,80(sp)
    800034a8:	64a6                	ld	s1,72(sp)
    800034aa:	6906                	ld	s2,64(sp)
    800034ac:	79e2                	ld	s3,56(sp)
    800034ae:	7a42                	ld	s4,48(sp)
    800034b0:	7aa2                	ld	s5,40(sp)
    800034b2:	7b02                	ld	s6,32(sp)
    800034b4:	6be2                	ld	s7,24(sp)
    800034b6:	6c42                	ld	s8,16(sp)
    800034b8:	6ca2                	ld	s9,8(sp)
    800034ba:	6125                	add	sp,sp,96
    800034bc:	8082                	ret

00000000800034be <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034be:	7179                	add	sp,sp,-48
    800034c0:	f406                	sd	ra,40(sp)
    800034c2:	f022                	sd	s0,32(sp)
    800034c4:	ec26                	sd	s1,24(sp)
    800034c6:	e84a                	sd	s2,16(sp)
    800034c8:	e44e                	sd	s3,8(sp)
    800034ca:	e052                	sd	s4,0(sp)
    800034cc:	1800                	add	s0,sp,48
    800034ce:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034d0:	47ad                	li	a5,11
    800034d2:	04b7fe63          	bgeu	a5,a1,8000352e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034d6:	ff45849b          	addw	s1,a1,-12
    800034da:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034de:	0ff00793          	li	a5,255
    800034e2:	0ae7e463          	bltu	a5,a4,8000358a <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034e6:	08052583          	lw	a1,128(a0)
    800034ea:	c5b5                	beqz	a1,80003556 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034ec:	00092503          	lw	a0,0(s2)
    800034f0:	00000097          	auipc	ra,0x0
    800034f4:	be0080e7          	jalr	-1056(ra) # 800030d0 <bread>
    800034f8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034fa:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    800034fe:	02049713          	sll	a4,s1,0x20
    80003502:	01e75593          	srl	a1,a4,0x1e
    80003506:	00b784b3          	add	s1,a5,a1
    8000350a:	0004a983          	lw	s3,0(s1)
    8000350e:	04098e63          	beqz	s3,8000356a <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003512:	8552                	mv	a0,s4
    80003514:	00000097          	auipc	ra,0x0
    80003518:	cec080e7          	jalr	-788(ra) # 80003200 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000351c:	854e                	mv	a0,s3
    8000351e:	70a2                	ld	ra,40(sp)
    80003520:	7402                	ld	s0,32(sp)
    80003522:	64e2                	ld	s1,24(sp)
    80003524:	6942                	ld	s2,16(sp)
    80003526:	69a2                	ld	s3,8(sp)
    80003528:	6a02                	ld	s4,0(sp)
    8000352a:	6145                	add	sp,sp,48
    8000352c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000352e:	02059793          	sll	a5,a1,0x20
    80003532:	01e7d593          	srl	a1,a5,0x1e
    80003536:	00b504b3          	add	s1,a0,a1
    8000353a:	0504a983          	lw	s3,80(s1)
    8000353e:	fc099fe3          	bnez	s3,8000351c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003542:	4108                	lw	a0,0(a0)
    80003544:	00000097          	auipc	ra,0x0
    80003548:	e4c080e7          	jalr	-436(ra) # 80003390 <balloc>
    8000354c:	0005099b          	sext.w	s3,a0
    80003550:	0534a823          	sw	s3,80(s1)
    80003554:	b7e1                	j	8000351c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003556:	4108                	lw	a0,0(a0)
    80003558:	00000097          	auipc	ra,0x0
    8000355c:	e38080e7          	jalr	-456(ra) # 80003390 <balloc>
    80003560:	0005059b          	sext.w	a1,a0
    80003564:	08b92023          	sw	a1,128(s2)
    80003568:	b751                	j	800034ec <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000356a:	00092503          	lw	a0,0(s2)
    8000356e:	00000097          	auipc	ra,0x0
    80003572:	e22080e7          	jalr	-478(ra) # 80003390 <balloc>
    80003576:	0005099b          	sext.w	s3,a0
    8000357a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000357e:	8552                	mv	a0,s4
    80003580:	00001097          	auipc	ra,0x1
    80003584:	eba080e7          	jalr	-326(ra) # 8000443a <log_write>
    80003588:	b769                	j	80003512 <bmap+0x54>
  panic("bmap: out of range");
    8000358a:	00005517          	auipc	a0,0x5
    8000358e:	01e50513          	add	a0,a0,30 # 800085a8 <syscalls+0x118>
    80003592:	ffffd097          	auipc	ra,0xffffd
    80003596:	fb0080e7          	jalr	-80(ra) # 80000542 <panic>

000000008000359a <iget>:
{
    8000359a:	7179                	add	sp,sp,-48
    8000359c:	f406                	sd	ra,40(sp)
    8000359e:	f022                	sd	s0,32(sp)
    800035a0:	ec26                	sd	s1,24(sp)
    800035a2:	e84a                	sd	s2,16(sp)
    800035a4:	e44e                	sd	s3,8(sp)
    800035a6:	e052                	sd	s4,0(sp)
    800035a8:	1800                	add	s0,sp,48
    800035aa:	89aa                	mv	s3,a0
    800035ac:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800035ae:	0001d517          	auipc	a0,0x1d
    800035b2:	ab250513          	add	a0,a0,-1358 # 80020060 <icache>
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	646080e7          	jalr	1606(ra) # 80000bfc <acquire>
  empty = 0;
    800035be:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800035c0:	0001d497          	auipc	s1,0x1d
    800035c4:	ab848493          	add	s1,s1,-1352 # 80020078 <icache+0x18>
    800035c8:	0001e697          	auipc	a3,0x1e
    800035cc:	54068693          	add	a3,a3,1344 # 80021b08 <log>
    800035d0:	a039                	j	800035de <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035d2:	02090b63          	beqz	s2,80003608 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800035d6:	08848493          	add	s1,s1,136
    800035da:	02d48a63          	beq	s1,a3,8000360e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035de:	449c                	lw	a5,8(s1)
    800035e0:	fef059e3          	blez	a5,800035d2 <iget+0x38>
    800035e4:	4098                	lw	a4,0(s1)
    800035e6:	ff3716e3          	bne	a4,s3,800035d2 <iget+0x38>
    800035ea:	40d8                	lw	a4,4(s1)
    800035ec:	ff4713e3          	bne	a4,s4,800035d2 <iget+0x38>
      ip->ref++;
    800035f0:	2785                	addw	a5,a5,1
    800035f2:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800035f4:	0001d517          	auipc	a0,0x1d
    800035f8:	a6c50513          	add	a0,a0,-1428 # 80020060 <icache>
    800035fc:	ffffd097          	auipc	ra,0xffffd
    80003600:	6b4080e7          	jalr	1716(ra) # 80000cb0 <release>
      return ip;
    80003604:	8926                	mv	s2,s1
    80003606:	a03d                	j	80003634 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003608:	f7f9                	bnez	a5,800035d6 <iget+0x3c>
    8000360a:	8926                	mv	s2,s1
    8000360c:	b7e9                	j	800035d6 <iget+0x3c>
  if(empty == 0)
    8000360e:	02090c63          	beqz	s2,80003646 <iget+0xac>
  ip->dev = dev;
    80003612:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003616:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000361a:	4785                	li	a5,1
    8000361c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003620:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003624:	0001d517          	auipc	a0,0x1d
    80003628:	a3c50513          	add	a0,a0,-1476 # 80020060 <icache>
    8000362c:	ffffd097          	auipc	ra,0xffffd
    80003630:	684080e7          	jalr	1668(ra) # 80000cb0 <release>
}
    80003634:	854a                	mv	a0,s2
    80003636:	70a2                	ld	ra,40(sp)
    80003638:	7402                	ld	s0,32(sp)
    8000363a:	64e2                	ld	s1,24(sp)
    8000363c:	6942                	ld	s2,16(sp)
    8000363e:	69a2                	ld	s3,8(sp)
    80003640:	6a02                	ld	s4,0(sp)
    80003642:	6145                	add	sp,sp,48
    80003644:	8082                	ret
    panic("iget: no inodes");
    80003646:	00005517          	auipc	a0,0x5
    8000364a:	f7a50513          	add	a0,a0,-134 # 800085c0 <syscalls+0x130>
    8000364e:	ffffd097          	auipc	ra,0xffffd
    80003652:	ef4080e7          	jalr	-268(ra) # 80000542 <panic>

0000000080003656 <fsinit>:
fsinit(int dev) {
    80003656:	7179                	add	sp,sp,-48
    80003658:	f406                	sd	ra,40(sp)
    8000365a:	f022                	sd	s0,32(sp)
    8000365c:	ec26                	sd	s1,24(sp)
    8000365e:	e84a                	sd	s2,16(sp)
    80003660:	e44e                	sd	s3,8(sp)
    80003662:	1800                	add	s0,sp,48
    80003664:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003666:	4585                	li	a1,1
    80003668:	00000097          	auipc	ra,0x0
    8000366c:	a68080e7          	jalr	-1432(ra) # 800030d0 <bread>
    80003670:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003672:	0001d997          	auipc	s3,0x1d
    80003676:	9ce98993          	add	s3,s3,-1586 # 80020040 <sb>
    8000367a:	02000613          	li	a2,32
    8000367e:	05850593          	add	a1,a0,88
    80003682:	854e                	mv	a0,s3
    80003684:	ffffd097          	auipc	ra,0xffffd
    80003688:	6d0080e7          	jalr	1744(ra) # 80000d54 <memmove>
  brelse(bp);
    8000368c:	8526                	mv	a0,s1
    8000368e:	00000097          	auipc	ra,0x0
    80003692:	b72080e7          	jalr	-1166(ra) # 80003200 <brelse>
  if(sb.magic != FSMAGIC)
    80003696:	0009a703          	lw	a4,0(s3)
    8000369a:	102037b7          	lui	a5,0x10203
    8000369e:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036a2:	02f71263          	bne	a4,a5,800036c6 <fsinit+0x70>
  initlog(dev, &sb);
    800036a6:	0001d597          	auipc	a1,0x1d
    800036aa:	99a58593          	add	a1,a1,-1638 # 80020040 <sb>
    800036ae:	854a                	mv	a0,s2
    800036b0:	00001097          	auipc	ra,0x1
    800036b4:	b24080e7          	jalr	-1244(ra) # 800041d4 <initlog>
}
    800036b8:	70a2                	ld	ra,40(sp)
    800036ba:	7402                	ld	s0,32(sp)
    800036bc:	64e2                	ld	s1,24(sp)
    800036be:	6942                	ld	s2,16(sp)
    800036c0:	69a2                	ld	s3,8(sp)
    800036c2:	6145                	add	sp,sp,48
    800036c4:	8082                	ret
    panic("invalid file system");
    800036c6:	00005517          	auipc	a0,0x5
    800036ca:	f0a50513          	add	a0,a0,-246 # 800085d0 <syscalls+0x140>
    800036ce:	ffffd097          	auipc	ra,0xffffd
    800036d2:	e74080e7          	jalr	-396(ra) # 80000542 <panic>

00000000800036d6 <iinit>:
{
    800036d6:	7179                	add	sp,sp,-48
    800036d8:	f406                	sd	ra,40(sp)
    800036da:	f022                	sd	s0,32(sp)
    800036dc:	ec26                	sd	s1,24(sp)
    800036de:	e84a                	sd	s2,16(sp)
    800036e0:	e44e                	sd	s3,8(sp)
    800036e2:	1800                	add	s0,sp,48
  initlock(&icache.lock, "icache");
    800036e4:	00005597          	auipc	a1,0x5
    800036e8:	f0458593          	add	a1,a1,-252 # 800085e8 <syscalls+0x158>
    800036ec:	0001d517          	auipc	a0,0x1d
    800036f0:	97450513          	add	a0,a0,-1676 # 80020060 <icache>
    800036f4:	ffffd097          	auipc	ra,0xffffd
    800036f8:	478080e7          	jalr	1144(ra) # 80000b6c <initlock>
  for(i = 0; i < NINODE; i++) {
    800036fc:	0001d497          	auipc	s1,0x1d
    80003700:	98c48493          	add	s1,s1,-1652 # 80020088 <icache+0x28>
    80003704:	0001e997          	auipc	s3,0x1e
    80003708:	41498993          	add	s3,s3,1044 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000370c:	00005917          	auipc	s2,0x5
    80003710:	ee490913          	add	s2,s2,-284 # 800085f0 <syscalls+0x160>
    80003714:	85ca                	mv	a1,s2
    80003716:	8526                	mv	a0,s1
    80003718:	00001097          	auipc	ra,0x1
    8000371c:	e0e080e7          	jalr	-498(ra) # 80004526 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003720:	08848493          	add	s1,s1,136
    80003724:	ff3498e3          	bne	s1,s3,80003714 <iinit+0x3e>
}
    80003728:	70a2                	ld	ra,40(sp)
    8000372a:	7402                	ld	s0,32(sp)
    8000372c:	64e2                	ld	s1,24(sp)
    8000372e:	6942                	ld	s2,16(sp)
    80003730:	69a2                	ld	s3,8(sp)
    80003732:	6145                	add	sp,sp,48
    80003734:	8082                	ret

0000000080003736 <ialloc>:
{
    80003736:	7139                	add	sp,sp,-64
    80003738:	fc06                	sd	ra,56(sp)
    8000373a:	f822                	sd	s0,48(sp)
    8000373c:	f426                	sd	s1,40(sp)
    8000373e:	f04a                	sd	s2,32(sp)
    80003740:	ec4e                	sd	s3,24(sp)
    80003742:	e852                	sd	s4,16(sp)
    80003744:	e456                	sd	s5,8(sp)
    80003746:	e05a                	sd	s6,0(sp)
    80003748:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    8000374a:	0001d717          	auipc	a4,0x1d
    8000374e:	90272703          	lw	a4,-1790(a4) # 8002004c <sb+0xc>
    80003752:	4785                	li	a5,1
    80003754:	04e7f863          	bgeu	a5,a4,800037a4 <ialloc+0x6e>
    80003758:	8aaa                	mv	s5,a0
    8000375a:	8b2e                	mv	s6,a1
    8000375c:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000375e:	0001da17          	auipc	s4,0x1d
    80003762:	8e2a0a13          	add	s4,s4,-1822 # 80020040 <sb>
    80003766:	00495593          	srl	a1,s2,0x4
    8000376a:	018a2783          	lw	a5,24(s4)
    8000376e:	9dbd                	addw	a1,a1,a5
    80003770:	8556                	mv	a0,s5
    80003772:	00000097          	auipc	ra,0x0
    80003776:	95e080e7          	jalr	-1698(ra) # 800030d0 <bread>
    8000377a:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000377c:	05850993          	add	s3,a0,88
    80003780:	00f97793          	and	a5,s2,15
    80003784:	079a                	sll	a5,a5,0x6
    80003786:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003788:	00099783          	lh	a5,0(s3)
    8000378c:	c785                	beqz	a5,800037b4 <ialloc+0x7e>
    brelse(bp);
    8000378e:	00000097          	auipc	ra,0x0
    80003792:	a72080e7          	jalr	-1422(ra) # 80003200 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003796:	0905                	add	s2,s2,1
    80003798:	00ca2703          	lw	a4,12(s4)
    8000379c:	0009079b          	sext.w	a5,s2
    800037a0:	fce7e3e3          	bltu	a5,a4,80003766 <ialloc+0x30>
  panic("ialloc: no inodes");
    800037a4:	00005517          	auipc	a0,0x5
    800037a8:	e5450513          	add	a0,a0,-428 # 800085f8 <syscalls+0x168>
    800037ac:	ffffd097          	auipc	ra,0xffffd
    800037b0:	d96080e7          	jalr	-618(ra) # 80000542 <panic>
      memset(dip, 0, sizeof(*dip));
    800037b4:	04000613          	li	a2,64
    800037b8:	4581                	li	a1,0
    800037ba:	854e                	mv	a0,s3
    800037bc:	ffffd097          	auipc	ra,0xffffd
    800037c0:	53c080e7          	jalr	1340(ra) # 80000cf8 <memset>
      dip->type = type;
    800037c4:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037c8:	8526                	mv	a0,s1
    800037ca:	00001097          	auipc	ra,0x1
    800037ce:	c70080e7          	jalr	-912(ra) # 8000443a <log_write>
      brelse(bp);
    800037d2:	8526                	mv	a0,s1
    800037d4:	00000097          	auipc	ra,0x0
    800037d8:	a2c080e7          	jalr	-1492(ra) # 80003200 <brelse>
      return iget(dev, inum);
    800037dc:	0009059b          	sext.w	a1,s2
    800037e0:	8556                	mv	a0,s5
    800037e2:	00000097          	auipc	ra,0x0
    800037e6:	db8080e7          	jalr	-584(ra) # 8000359a <iget>
}
    800037ea:	70e2                	ld	ra,56(sp)
    800037ec:	7442                	ld	s0,48(sp)
    800037ee:	74a2                	ld	s1,40(sp)
    800037f0:	7902                	ld	s2,32(sp)
    800037f2:	69e2                	ld	s3,24(sp)
    800037f4:	6a42                	ld	s4,16(sp)
    800037f6:	6aa2                	ld	s5,8(sp)
    800037f8:	6b02                	ld	s6,0(sp)
    800037fa:	6121                	add	sp,sp,64
    800037fc:	8082                	ret

00000000800037fe <iupdate>:
{
    800037fe:	1101                	add	sp,sp,-32
    80003800:	ec06                	sd	ra,24(sp)
    80003802:	e822                	sd	s0,16(sp)
    80003804:	e426                	sd	s1,8(sp)
    80003806:	e04a                	sd	s2,0(sp)
    80003808:	1000                	add	s0,sp,32
    8000380a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000380c:	415c                	lw	a5,4(a0)
    8000380e:	0047d79b          	srlw	a5,a5,0x4
    80003812:	0001d597          	auipc	a1,0x1d
    80003816:	8465a583          	lw	a1,-1978(a1) # 80020058 <sb+0x18>
    8000381a:	9dbd                	addw	a1,a1,a5
    8000381c:	4108                	lw	a0,0(a0)
    8000381e:	00000097          	auipc	ra,0x0
    80003822:	8b2080e7          	jalr	-1870(ra) # 800030d0 <bread>
    80003826:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003828:	05850793          	add	a5,a0,88
    8000382c:	40d8                	lw	a4,4(s1)
    8000382e:	8b3d                	and	a4,a4,15
    80003830:	071a                	sll	a4,a4,0x6
    80003832:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003834:	04449703          	lh	a4,68(s1)
    80003838:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000383c:	04649703          	lh	a4,70(s1)
    80003840:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003844:	04849703          	lh	a4,72(s1)
    80003848:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000384c:	04a49703          	lh	a4,74(s1)
    80003850:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003854:	44f8                	lw	a4,76(s1)
    80003856:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003858:	03400613          	li	a2,52
    8000385c:	05048593          	add	a1,s1,80
    80003860:	00c78513          	add	a0,a5,12
    80003864:	ffffd097          	auipc	ra,0xffffd
    80003868:	4f0080e7          	jalr	1264(ra) # 80000d54 <memmove>
  log_write(bp);
    8000386c:	854a                	mv	a0,s2
    8000386e:	00001097          	auipc	ra,0x1
    80003872:	bcc080e7          	jalr	-1076(ra) # 8000443a <log_write>
  brelse(bp);
    80003876:	854a                	mv	a0,s2
    80003878:	00000097          	auipc	ra,0x0
    8000387c:	988080e7          	jalr	-1656(ra) # 80003200 <brelse>
}
    80003880:	60e2                	ld	ra,24(sp)
    80003882:	6442                	ld	s0,16(sp)
    80003884:	64a2                	ld	s1,8(sp)
    80003886:	6902                	ld	s2,0(sp)
    80003888:	6105                	add	sp,sp,32
    8000388a:	8082                	ret

000000008000388c <idup>:
{
    8000388c:	1101                	add	sp,sp,-32
    8000388e:	ec06                	sd	ra,24(sp)
    80003890:	e822                	sd	s0,16(sp)
    80003892:	e426                	sd	s1,8(sp)
    80003894:	1000                	add	s0,sp,32
    80003896:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003898:	0001c517          	auipc	a0,0x1c
    8000389c:	7c850513          	add	a0,a0,1992 # 80020060 <icache>
    800038a0:	ffffd097          	auipc	ra,0xffffd
    800038a4:	35c080e7          	jalr	860(ra) # 80000bfc <acquire>
  ip->ref++;
    800038a8:	449c                	lw	a5,8(s1)
    800038aa:	2785                	addw	a5,a5,1
    800038ac:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800038ae:	0001c517          	auipc	a0,0x1c
    800038b2:	7b250513          	add	a0,a0,1970 # 80020060 <icache>
    800038b6:	ffffd097          	auipc	ra,0xffffd
    800038ba:	3fa080e7          	jalr	1018(ra) # 80000cb0 <release>
}
    800038be:	8526                	mv	a0,s1
    800038c0:	60e2                	ld	ra,24(sp)
    800038c2:	6442                	ld	s0,16(sp)
    800038c4:	64a2                	ld	s1,8(sp)
    800038c6:	6105                	add	sp,sp,32
    800038c8:	8082                	ret

00000000800038ca <ilock>:
{
    800038ca:	1101                	add	sp,sp,-32
    800038cc:	ec06                	sd	ra,24(sp)
    800038ce:	e822                	sd	s0,16(sp)
    800038d0:	e426                	sd	s1,8(sp)
    800038d2:	e04a                	sd	s2,0(sp)
    800038d4:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038d6:	c115                	beqz	a0,800038fa <ilock+0x30>
    800038d8:	84aa                	mv	s1,a0
    800038da:	451c                	lw	a5,8(a0)
    800038dc:	00f05f63          	blez	a5,800038fa <ilock+0x30>
  acquiresleep(&ip->lock);
    800038e0:	0541                	add	a0,a0,16
    800038e2:	00001097          	auipc	ra,0x1
    800038e6:	c7e080e7          	jalr	-898(ra) # 80004560 <acquiresleep>
  if(ip->valid == 0){
    800038ea:	40bc                	lw	a5,64(s1)
    800038ec:	cf99                	beqz	a5,8000390a <ilock+0x40>
}
    800038ee:	60e2                	ld	ra,24(sp)
    800038f0:	6442                	ld	s0,16(sp)
    800038f2:	64a2                	ld	s1,8(sp)
    800038f4:	6902                	ld	s2,0(sp)
    800038f6:	6105                	add	sp,sp,32
    800038f8:	8082                	ret
    panic("ilock");
    800038fa:	00005517          	auipc	a0,0x5
    800038fe:	d1650513          	add	a0,a0,-746 # 80008610 <syscalls+0x180>
    80003902:	ffffd097          	auipc	ra,0xffffd
    80003906:	c40080e7          	jalr	-960(ra) # 80000542 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000390a:	40dc                	lw	a5,4(s1)
    8000390c:	0047d79b          	srlw	a5,a5,0x4
    80003910:	0001c597          	auipc	a1,0x1c
    80003914:	7485a583          	lw	a1,1864(a1) # 80020058 <sb+0x18>
    80003918:	9dbd                	addw	a1,a1,a5
    8000391a:	4088                	lw	a0,0(s1)
    8000391c:	fffff097          	auipc	ra,0xfffff
    80003920:	7b4080e7          	jalr	1972(ra) # 800030d0 <bread>
    80003924:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003926:	05850593          	add	a1,a0,88
    8000392a:	40dc                	lw	a5,4(s1)
    8000392c:	8bbd                	and	a5,a5,15
    8000392e:	079a                	sll	a5,a5,0x6
    80003930:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003932:	00059783          	lh	a5,0(a1)
    80003936:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000393a:	00259783          	lh	a5,2(a1)
    8000393e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003942:	00459783          	lh	a5,4(a1)
    80003946:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000394a:	00659783          	lh	a5,6(a1)
    8000394e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003952:	459c                	lw	a5,8(a1)
    80003954:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003956:	03400613          	li	a2,52
    8000395a:	05b1                	add	a1,a1,12
    8000395c:	05048513          	add	a0,s1,80
    80003960:	ffffd097          	auipc	ra,0xffffd
    80003964:	3f4080e7          	jalr	1012(ra) # 80000d54 <memmove>
    brelse(bp);
    80003968:	854a                	mv	a0,s2
    8000396a:	00000097          	auipc	ra,0x0
    8000396e:	896080e7          	jalr	-1898(ra) # 80003200 <brelse>
    ip->valid = 1;
    80003972:	4785                	li	a5,1
    80003974:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003976:	04449783          	lh	a5,68(s1)
    8000397a:	fbb5                	bnez	a5,800038ee <ilock+0x24>
      panic("ilock: no type");
    8000397c:	00005517          	auipc	a0,0x5
    80003980:	c9c50513          	add	a0,a0,-868 # 80008618 <syscalls+0x188>
    80003984:	ffffd097          	auipc	ra,0xffffd
    80003988:	bbe080e7          	jalr	-1090(ra) # 80000542 <panic>

000000008000398c <iunlock>:
{
    8000398c:	1101                	add	sp,sp,-32
    8000398e:	ec06                	sd	ra,24(sp)
    80003990:	e822                	sd	s0,16(sp)
    80003992:	e426                	sd	s1,8(sp)
    80003994:	e04a                	sd	s2,0(sp)
    80003996:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003998:	c905                	beqz	a0,800039c8 <iunlock+0x3c>
    8000399a:	84aa                	mv	s1,a0
    8000399c:	01050913          	add	s2,a0,16
    800039a0:	854a                	mv	a0,s2
    800039a2:	00001097          	auipc	ra,0x1
    800039a6:	c58080e7          	jalr	-936(ra) # 800045fa <holdingsleep>
    800039aa:	cd19                	beqz	a0,800039c8 <iunlock+0x3c>
    800039ac:	449c                	lw	a5,8(s1)
    800039ae:	00f05d63          	blez	a5,800039c8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039b2:	854a                	mv	a0,s2
    800039b4:	00001097          	auipc	ra,0x1
    800039b8:	c02080e7          	jalr	-1022(ra) # 800045b6 <releasesleep>
}
    800039bc:	60e2                	ld	ra,24(sp)
    800039be:	6442                	ld	s0,16(sp)
    800039c0:	64a2                	ld	s1,8(sp)
    800039c2:	6902                	ld	s2,0(sp)
    800039c4:	6105                	add	sp,sp,32
    800039c6:	8082                	ret
    panic("iunlock");
    800039c8:	00005517          	auipc	a0,0x5
    800039cc:	c6050513          	add	a0,a0,-928 # 80008628 <syscalls+0x198>
    800039d0:	ffffd097          	auipc	ra,0xffffd
    800039d4:	b72080e7          	jalr	-1166(ra) # 80000542 <panic>

00000000800039d8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039d8:	7179                	add	sp,sp,-48
    800039da:	f406                	sd	ra,40(sp)
    800039dc:	f022                	sd	s0,32(sp)
    800039de:	ec26                	sd	s1,24(sp)
    800039e0:	e84a                	sd	s2,16(sp)
    800039e2:	e44e                	sd	s3,8(sp)
    800039e4:	e052                	sd	s4,0(sp)
    800039e6:	1800                	add	s0,sp,48
    800039e8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039ea:	05050493          	add	s1,a0,80
    800039ee:	08050913          	add	s2,a0,128
    800039f2:	a021                	j	800039fa <itrunc+0x22>
    800039f4:	0491                	add	s1,s1,4
    800039f6:	01248d63          	beq	s1,s2,80003a10 <itrunc+0x38>
    if(ip->addrs[i]){
    800039fa:	408c                	lw	a1,0(s1)
    800039fc:	dde5                	beqz	a1,800039f4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039fe:	0009a503          	lw	a0,0(s3)
    80003a02:	00000097          	auipc	ra,0x0
    80003a06:	912080e7          	jalr	-1774(ra) # 80003314 <bfree>
      ip->addrs[i] = 0;
    80003a0a:	0004a023          	sw	zero,0(s1)
    80003a0e:	b7dd                	j	800039f4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a10:	0809a583          	lw	a1,128(s3)
    80003a14:	e185                	bnez	a1,80003a34 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a16:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a1a:	854e                	mv	a0,s3
    80003a1c:	00000097          	auipc	ra,0x0
    80003a20:	de2080e7          	jalr	-542(ra) # 800037fe <iupdate>
}
    80003a24:	70a2                	ld	ra,40(sp)
    80003a26:	7402                	ld	s0,32(sp)
    80003a28:	64e2                	ld	s1,24(sp)
    80003a2a:	6942                	ld	s2,16(sp)
    80003a2c:	69a2                	ld	s3,8(sp)
    80003a2e:	6a02                	ld	s4,0(sp)
    80003a30:	6145                	add	sp,sp,48
    80003a32:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a34:	0009a503          	lw	a0,0(s3)
    80003a38:	fffff097          	auipc	ra,0xfffff
    80003a3c:	698080e7          	jalr	1688(ra) # 800030d0 <bread>
    80003a40:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a42:	05850493          	add	s1,a0,88
    80003a46:	45850913          	add	s2,a0,1112
    80003a4a:	a021                	j	80003a52 <itrunc+0x7a>
    80003a4c:	0491                	add	s1,s1,4
    80003a4e:	01248b63          	beq	s1,s2,80003a64 <itrunc+0x8c>
      if(a[j])
    80003a52:	408c                	lw	a1,0(s1)
    80003a54:	dde5                	beqz	a1,80003a4c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a56:	0009a503          	lw	a0,0(s3)
    80003a5a:	00000097          	auipc	ra,0x0
    80003a5e:	8ba080e7          	jalr	-1862(ra) # 80003314 <bfree>
    80003a62:	b7ed                	j	80003a4c <itrunc+0x74>
    brelse(bp);
    80003a64:	8552                	mv	a0,s4
    80003a66:	fffff097          	auipc	ra,0xfffff
    80003a6a:	79a080e7          	jalr	1946(ra) # 80003200 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a6e:	0809a583          	lw	a1,128(s3)
    80003a72:	0009a503          	lw	a0,0(s3)
    80003a76:	00000097          	auipc	ra,0x0
    80003a7a:	89e080e7          	jalr	-1890(ra) # 80003314 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a7e:	0809a023          	sw	zero,128(s3)
    80003a82:	bf51                	j	80003a16 <itrunc+0x3e>

0000000080003a84 <iput>:
{
    80003a84:	1101                	add	sp,sp,-32
    80003a86:	ec06                	sd	ra,24(sp)
    80003a88:	e822                	sd	s0,16(sp)
    80003a8a:	e426                	sd	s1,8(sp)
    80003a8c:	e04a                	sd	s2,0(sp)
    80003a8e:	1000                	add	s0,sp,32
    80003a90:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003a92:	0001c517          	auipc	a0,0x1c
    80003a96:	5ce50513          	add	a0,a0,1486 # 80020060 <icache>
    80003a9a:	ffffd097          	auipc	ra,0xffffd
    80003a9e:	162080e7          	jalr	354(ra) # 80000bfc <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003aa2:	4498                	lw	a4,8(s1)
    80003aa4:	4785                	li	a5,1
    80003aa6:	02f70363          	beq	a4,a5,80003acc <iput+0x48>
  ip->ref--;
    80003aaa:	449c                	lw	a5,8(s1)
    80003aac:	37fd                	addw	a5,a5,-1
    80003aae:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003ab0:	0001c517          	auipc	a0,0x1c
    80003ab4:	5b050513          	add	a0,a0,1456 # 80020060 <icache>
    80003ab8:	ffffd097          	auipc	ra,0xffffd
    80003abc:	1f8080e7          	jalr	504(ra) # 80000cb0 <release>
}
    80003ac0:	60e2                	ld	ra,24(sp)
    80003ac2:	6442                	ld	s0,16(sp)
    80003ac4:	64a2                	ld	s1,8(sp)
    80003ac6:	6902                	ld	s2,0(sp)
    80003ac8:	6105                	add	sp,sp,32
    80003aca:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003acc:	40bc                	lw	a5,64(s1)
    80003ace:	dff1                	beqz	a5,80003aaa <iput+0x26>
    80003ad0:	04a49783          	lh	a5,74(s1)
    80003ad4:	fbf9                	bnez	a5,80003aaa <iput+0x26>
    acquiresleep(&ip->lock);
    80003ad6:	01048913          	add	s2,s1,16
    80003ada:	854a                	mv	a0,s2
    80003adc:	00001097          	auipc	ra,0x1
    80003ae0:	a84080e7          	jalr	-1404(ra) # 80004560 <acquiresleep>
    release(&icache.lock);
    80003ae4:	0001c517          	auipc	a0,0x1c
    80003ae8:	57c50513          	add	a0,a0,1404 # 80020060 <icache>
    80003aec:	ffffd097          	auipc	ra,0xffffd
    80003af0:	1c4080e7          	jalr	452(ra) # 80000cb0 <release>
    itrunc(ip);
    80003af4:	8526                	mv	a0,s1
    80003af6:	00000097          	auipc	ra,0x0
    80003afa:	ee2080e7          	jalr	-286(ra) # 800039d8 <itrunc>
    ip->type = 0;
    80003afe:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b02:	8526                	mv	a0,s1
    80003b04:	00000097          	auipc	ra,0x0
    80003b08:	cfa080e7          	jalr	-774(ra) # 800037fe <iupdate>
    ip->valid = 0;
    80003b0c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b10:	854a                	mv	a0,s2
    80003b12:	00001097          	auipc	ra,0x1
    80003b16:	aa4080e7          	jalr	-1372(ra) # 800045b6 <releasesleep>
    acquire(&icache.lock);
    80003b1a:	0001c517          	auipc	a0,0x1c
    80003b1e:	54650513          	add	a0,a0,1350 # 80020060 <icache>
    80003b22:	ffffd097          	auipc	ra,0xffffd
    80003b26:	0da080e7          	jalr	218(ra) # 80000bfc <acquire>
    80003b2a:	b741                	j	80003aaa <iput+0x26>

0000000080003b2c <iunlockput>:
{
    80003b2c:	1101                	add	sp,sp,-32
    80003b2e:	ec06                	sd	ra,24(sp)
    80003b30:	e822                	sd	s0,16(sp)
    80003b32:	e426                	sd	s1,8(sp)
    80003b34:	1000                	add	s0,sp,32
    80003b36:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b38:	00000097          	auipc	ra,0x0
    80003b3c:	e54080e7          	jalr	-428(ra) # 8000398c <iunlock>
  iput(ip);
    80003b40:	8526                	mv	a0,s1
    80003b42:	00000097          	auipc	ra,0x0
    80003b46:	f42080e7          	jalr	-190(ra) # 80003a84 <iput>
}
    80003b4a:	60e2                	ld	ra,24(sp)
    80003b4c:	6442                	ld	s0,16(sp)
    80003b4e:	64a2                	ld	s1,8(sp)
    80003b50:	6105                	add	sp,sp,32
    80003b52:	8082                	ret

0000000080003b54 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b54:	1141                	add	sp,sp,-16
    80003b56:	e422                	sd	s0,8(sp)
    80003b58:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    80003b5a:	411c                	lw	a5,0(a0)
    80003b5c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b5e:	415c                	lw	a5,4(a0)
    80003b60:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b62:	04451783          	lh	a5,68(a0)
    80003b66:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b6a:	04a51783          	lh	a5,74(a0)
    80003b6e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b72:	04c56783          	lwu	a5,76(a0)
    80003b76:	e99c                	sd	a5,16(a1)
}
    80003b78:	6422                	ld	s0,8(sp)
    80003b7a:	0141                	add	sp,sp,16
    80003b7c:	8082                	ret

0000000080003b7e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b7e:	457c                	lw	a5,76(a0)
    80003b80:	0ed7e863          	bltu	a5,a3,80003c70 <readi+0xf2>
{
    80003b84:	7159                	add	sp,sp,-112
    80003b86:	f486                	sd	ra,104(sp)
    80003b88:	f0a2                	sd	s0,96(sp)
    80003b8a:	eca6                	sd	s1,88(sp)
    80003b8c:	e8ca                	sd	s2,80(sp)
    80003b8e:	e4ce                	sd	s3,72(sp)
    80003b90:	e0d2                	sd	s4,64(sp)
    80003b92:	fc56                	sd	s5,56(sp)
    80003b94:	f85a                	sd	s6,48(sp)
    80003b96:	f45e                	sd	s7,40(sp)
    80003b98:	f062                	sd	s8,32(sp)
    80003b9a:	ec66                	sd	s9,24(sp)
    80003b9c:	e86a                	sd	s10,16(sp)
    80003b9e:	e46e                	sd	s11,8(sp)
    80003ba0:	1880                	add	s0,sp,112
    80003ba2:	8baa                	mv	s7,a0
    80003ba4:	8c2e                	mv	s8,a1
    80003ba6:	8ab2                	mv	s5,a2
    80003ba8:	84b6                	mv	s1,a3
    80003baa:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bac:	9f35                	addw	a4,a4,a3
    return 0;
    80003bae:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bb0:	08d76f63          	bltu	a4,a3,80003c4e <readi+0xd0>
  if(off + n > ip->size)
    80003bb4:	00e7f463          	bgeu	a5,a4,80003bbc <readi+0x3e>
    n = ip->size - off;
    80003bb8:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bbc:	0a0b0863          	beqz	s6,80003c6c <readi+0xee>
    80003bc0:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bc2:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bc6:	5cfd                	li	s9,-1
    80003bc8:	a82d                	j	80003c02 <readi+0x84>
    80003bca:	020a1d93          	sll	s11,s4,0x20
    80003bce:	020ddd93          	srl	s11,s11,0x20
    80003bd2:	05890613          	add	a2,s2,88
    80003bd6:	86ee                	mv	a3,s11
    80003bd8:	963a                	add	a2,a2,a4
    80003bda:	85d6                	mv	a1,s5
    80003bdc:	8562                	mv	a0,s8
    80003bde:	fffff097          	auipc	ra,0xfffff
    80003be2:	b30080e7          	jalr	-1232(ra) # 8000270e <either_copyout>
    80003be6:	05950d63          	beq	a0,s9,80003c40 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003bea:	854a                	mv	a0,s2
    80003bec:	fffff097          	auipc	ra,0xfffff
    80003bf0:	614080e7          	jalr	1556(ra) # 80003200 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bf4:	013a09bb          	addw	s3,s4,s3
    80003bf8:	009a04bb          	addw	s1,s4,s1
    80003bfc:	9aee                	add	s5,s5,s11
    80003bfe:	0569f663          	bgeu	s3,s6,80003c4a <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c02:	000ba903          	lw	s2,0(s7)
    80003c06:	00a4d59b          	srlw	a1,s1,0xa
    80003c0a:	855e                	mv	a0,s7
    80003c0c:	00000097          	auipc	ra,0x0
    80003c10:	8b2080e7          	jalr	-1870(ra) # 800034be <bmap>
    80003c14:	0005059b          	sext.w	a1,a0
    80003c18:	854a                	mv	a0,s2
    80003c1a:	fffff097          	auipc	ra,0xfffff
    80003c1e:	4b6080e7          	jalr	1206(ra) # 800030d0 <bread>
    80003c22:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c24:	3ff4f713          	and	a4,s1,1023
    80003c28:	40ed07bb          	subw	a5,s10,a4
    80003c2c:	413b06bb          	subw	a3,s6,s3
    80003c30:	8a3e                	mv	s4,a5
    80003c32:	2781                	sext.w	a5,a5
    80003c34:	0006861b          	sext.w	a2,a3
    80003c38:	f8f679e3          	bgeu	a2,a5,80003bca <readi+0x4c>
    80003c3c:	8a36                	mv	s4,a3
    80003c3e:	b771                	j	80003bca <readi+0x4c>
      brelse(bp);
    80003c40:	854a                	mv	a0,s2
    80003c42:	fffff097          	auipc	ra,0xfffff
    80003c46:	5be080e7          	jalr	1470(ra) # 80003200 <brelse>
  }
  return tot;
    80003c4a:	0009851b          	sext.w	a0,s3
}
    80003c4e:	70a6                	ld	ra,104(sp)
    80003c50:	7406                	ld	s0,96(sp)
    80003c52:	64e6                	ld	s1,88(sp)
    80003c54:	6946                	ld	s2,80(sp)
    80003c56:	69a6                	ld	s3,72(sp)
    80003c58:	6a06                	ld	s4,64(sp)
    80003c5a:	7ae2                	ld	s5,56(sp)
    80003c5c:	7b42                	ld	s6,48(sp)
    80003c5e:	7ba2                	ld	s7,40(sp)
    80003c60:	7c02                	ld	s8,32(sp)
    80003c62:	6ce2                	ld	s9,24(sp)
    80003c64:	6d42                	ld	s10,16(sp)
    80003c66:	6da2                	ld	s11,8(sp)
    80003c68:	6165                	add	sp,sp,112
    80003c6a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c6c:	89da                	mv	s3,s6
    80003c6e:	bff1                	j	80003c4a <readi+0xcc>
    return 0;
    80003c70:	4501                	li	a0,0
}
    80003c72:	8082                	ret

0000000080003c74 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c74:	457c                	lw	a5,76(a0)
    80003c76:	10d7e663          	bltu	a5,a3,80003d82 <writei+0x10e>
{
    80003c7a:	7159                	add	sp,sp,-112
    80003c7c:	f486                	sd	ra,104(sp)
    80003c7e:	f0a2                	sd	s0,96(sp)
    80003c80:	eca6                	sd	s1,88(sp)
    80003c82:	e8ca                	sd	s2,80(sp)
    80003c84:	e4ce                	sd	s3,72(sp)
    80003c86:	e0d2                	sd	s4,64(sp)
    80003c88:	fc56                	sd	s5,56(sp)
    80003c8a:	f85a                	sd	s6,48(sp)
    80003c8c:	f45e                	sd	s7,40(sp)
    80003c8e:	f062                	sd	s8,32(sp)
    80003c90:	ec66                	sd	s9,24(sp)
    80003c92:	e86a                	sd	s10,16(sp)
    80003c94:	e46e                	sd	s11,8(sp)
    80003c96:	1880                	add	s0,sp,112
    80003c98:	8baa                	mv	s7,a0
    80003c9a:	8c2e                	mv	s8,a1
    80003c9c:	8ab2                	mv	s5,a2
    80003c9e:	8936                	mv	s2,a3
    80003ca0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ca2:	00e687bb          	addw	a5,a3,a4
    80003ca6:	0ed7e063          	bltu	a5,a3,80003d86 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003caa:	00043737          	lui	a4,0x43
    80003cae:	0cf76e63          	bltu	a4,a5,80003d8a <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cb2:	0a0b0763          	beqz	s6,80003d60 <writei+0xec>
    80003cb6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cb8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cbc:	5cfd                	li	s9,-1
    80003cbe:	a091                	j	80003d02 <writei+0x8e>
    80003cc0:	02099d93          	sll	s11,s3,0x20
    80003cc4:	020ddd93          	srl	s11,s11,0x20
    80003cc8:	05848513          	add	a0,s1,88
    80003ccc:	86ee                	mv	a3,s11
    80003cce:	8656                	mv	a2,s5
    80003cd0:	85e2                	mv	a1,s8
    80003cd2:	953a                	add	a0,a0,a4
    80003cd4:	fffff097          	auipc	ra,0xfffff
    80003cd8:	a90080e7          	jalr	-1392(ra) # 80002764 <either_copyin>
    80003cdc:	07950263          	beq	a0,s9,80003d40 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ce0:	8526                	mv	a0,s1
    80003ce2:	00000097          	auipc	ra,0x0
    80003ce6:	758080e7          	jalr	1880(ra) # 8000443a <log_write>
    brelse(bp);
    80003cea:	8526                	mv	a0,s1
    80003cec:	fffff097          	auipc	ra,0xfffff
    80003cf0:	514080e7          	jalr	1300(ra) # 80003200 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cf4:	01498a3b          	addw	s4,s3,s4
    80003cf8:	0129893b          	addw	s2,s3,s2
    80003cfc:	9aee                	add	s5,s5,s11
    80003cfe:	056a7663          	bgeu	s4,s6,80003d4a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d02:	000ba483          	lw	s1,0(s7)
    80003d06:	00a9559b          	srlw	a1,s2,0xa
    80003d0a:	855e                	mv	a0,s7
    80003d0c:	fffff097          	auipc	ra,0xfffff
    80003d10:	7b2080e7          	jalr	1970(ra) # 800034be <bmap>
    80003d14:	0005059b          	sext.w	a1,a0
    80003d18:	8526                	mv	a0,s1
    80003d1a:	fffff097          	auipc	ra,0xfffff
    80003d1e:	3b6080e7          	jalr	950(ra) # 800030d0 <bread>
    80003d22:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d24:	3ff97713          	and	a4,s2,1023
    80003d28:	40ed07bb          	subw	a5,s10,a4
    80003d2c:	414b06bb          	subw	a3,s6,s4
    80003d30:	89be                	mv	s3,a5
    80003d32:	2781                	sext.w	a5,a5
    80003d34:	0006861b          	sext.w	a2,a3
    80003d38:	f8f674e3          	bgeu	a2,a5,80003cc0 <writei+0x4c>
    80003d3c:	89b6                	mv	s3,a3
    80003d3e:	b749                	j	80003cc0 <writei+0x4c>
      brelse(bp);
    80003d40:	8526                	mv	a0,s1
    80003d42:	fffff097          	auipc	ra,0xfffff
    80003d46:	4be080e7          	jalr	1214(ra) # 80003200 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003d4a:	04cba783          	lw	a5,76(s7)
    80003d4e:	0127f463          	bgeu	a5,s2,80003d56 <writei+0xe2>
      ip->size = off;
    80003d52:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003d56:	855e                	mv	a0,s7
    80003d58:	00000097          	auipc	ra,0x0
    80003d5c:	aa6080e7          	jalr	-1370(ra) # 800037fe <iupdate>
  }

  return n;
    80003d60:	000b051b          	sext.w	a0,s6
}
    80003d64:	70a6                	ld	ra,104(sp)
    80003d66:	7406                	ld	s0,96(sp)
    80003d68:	64e6                	ld	s1,88(sp)
    80003d6a:	6946                	ld	s2,80(sp)
    80003d6c:	69a6                	ld	s3,72(sp)
    80003d6e:	6a06                	ld	s4,64(sp)
    80003d70:	7ae2                	ld	s5,56(sp)
    80003d72:	7b42                	ld	s6,48(sp)
    80003d74:	7ba2                	ld	s7,40(sp)
    80003d76:	7c02                	ld	s8,32(sp)
    80003d78:	6ce2                	ld	s9,24(sp)
    80003d7a:	6d42                	ld	s10,16(sp)
    80003d7c:	6da2                	ld	s11,8(sp)
    80003d7e:	6165                	add	sp,sp,112
    80003d80:	8082                	ret
    return -1;
    80003d82:	557d                	li	a0,-1
}
    80003d84:	8082                	ret
    return -1;
    80003d86:	557d                	li	a0,-1
    80003d88:	bff1                	j	80003d64 <writei+0xf0>
    return -1;
    80003d8a:	557d                	li	a0,-1
    80003d8c:	bfe1                	j	80003d64 <writei+0xf0>

0000000080003d8e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d8e:	1141                	add	sp,sp,-16
    80003d90:	e406                	sd	ra,8(sp)
    80003d92:	e022                	sd	s0,0(sp)
    80003d94:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d96:	4639                	li	a2,14
    80003d98:	ffffd097          	auipc	ra,0xffffd
    80003d9c:	038080e7          	jalr	56(ra) # 80000dd0 <strncmp>
}
    80003da0:	60a2                	ld	ra,8(sp)
    80003da2:	6402                	ld	s0,0(sp)
    80003da4:	0141                	add	sp,sp,16
    80003da6:	8082                	ret

0000000080003da8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003da8:	7139                	add	sp,sp,-64
    80003daa:	fc06                	sd	ra,56(sp)
    80003dac:	f822                	sd	s0,48(sp)
    80003dae:	f426                	sd	s1,40(sp)
    80003db0:	f04a                	sd	s2,32(sp)
    80003db2:	ec4e                	sd	s3,24(sp)
    80003db4:	e852                	sd	s4,16(sp)
    80003db6:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003db8:	04451703          	lh	a4,68(a0)
    80003dbc:	4785                	li	a5,1
    80003dbe:	00f71a63          	bne	a4,a5,80003dd2 <dirlookup+0x2a>
    80003dc2:	892a                	mv	s2,a0
    80003dc4:	89ae                	mv	s3,a1
    80003dc6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dc8:	457c                	lw	a5,76(a0)
    80003dca:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dcc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dce:	e79d                	bnez	a5,80003dfc <dirlookup+0x54>
    80003dd0:	a8a5                	j	80003e48 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003dd2:	00005517          	auipc	a0,0x5
    80003dd6:	85e50513          	add	a0,a0,-1954 # 80008630 <syscalls+0x1a0>
    80003dda:	ffffc097          	auipc	ra,0xffffc
    80003dde:	768080e7          	jalr	1896(ra) # 80000542 <panic>
      panic("dirlookup read");
    80003de2:	00005517          	auipc	a0,0x5
    80003de6:	86650513          	add	a0,a0,-1946 # 80008648 <syscalls+0x1b8>
    80003dea:	ffffc097          	auipc	ra,0xffffc
    80003dee:	758080e7          	jalr	1880(ra) # 80000542 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003df2:	24c1                	addw	s1,s1,16
    80003df4:	04c92783          	lw	a5,76(s2)
    80003df8:	04f4f763          	bgeu	s1,a5,80003e46 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dfc:	4741                	li	a4,16
    80003dfe:	86a6                	mv	a3,s1
    80003e00:	fc040613          	add	a2,s0,-64
    80003e04:	4581                	li	a1,0
    80003e06:	854a                	mv	a0,s2
    80003e08:	00000097          	auipc	ra,0x0
    80003e0c:	d76080e7          	jalr	-650(ra) # 80003b7e <readi>
    80003e10:	47c1                	li	a5,16
    80003e12:	fcf518e3          	bne	a0,a5,80003de2 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e16:	fc045783          	lhu	a5,-64(s0)
    80003e1a:	dfe1                	beqz	a5,80003df2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e1c:	fc240593          	add	a1,s0,-62
    80003e20:	854e                	mv	a0,s3
    80003e22:	00000097          	auipc	ra,0x0
    80003e26:	f6c080e7          	jalr	-148(ra) # 80003d8e <namecmp>
    80003e2a:	f561                	bnez	a0,80003df2 <dirlookup+0x4a>
      if(poff)
    80003e2c:	000a0463          	beqz	s4,80003e34 <dirlookup+0x8c>
        *poff = off;
    80003e30:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e34:	fc045583          	lhu	a1,-64(s0)
    80003e38:	00092503          	lw	a0,0(s2)
    80003e3c:	fffff097          	auipc	ra,0xfffff
    80003e40:	75e080e7          	jalr	1886(ra) # 8000359a <iget>
    80003e44:	a011                	j	80003e48 <dirlookup+0xa0>
  return 0;
    80003e46:	4501                	li	a0,0
}
    80003e48:	70e2                	ld	ra,56(sp)
    80003e4a:	7442                	ld	s0,48(sp)
    80003e4c:	74a2                	ld	s1,40(sp)
    80003e4e:	7902                	ld	s2,32(sp)
    80003e50:	69e2                	ld	s3,24(sp)
    80003e52:	6a42                	ld	s4,16(sp)
    80003e54:	6121                	add	sp,sp,64
    80003e56:	8082                	ret

0000000080003e58 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e58:	711d                	add	sp,sp,-96
    80003e5a:	ec86                	sd	ra,88(sp)
    80003e5c:	e8a2                	sd	s0,80(sp)
    80003e5e:	e4a6                	sd	s1,72(sp)
    80003e60:	e0ca                	sd	s2,64(sp)
    80003e62:	fc4e                	sd	s3,56(sp)
    80003e64:	f852                	sd	s4,48(sp)
    80003e66:	f456                	sd	s5,40(sp)
    80003e68:	f05a                	sd	s6,32(sp)
    80003e6a:	ec5e                	sd	s7,24(sp)
    80003e6c:	e862                	sd	s8,16(sp)
    80003e6e:	e466                	sd	s9,8(sp)
    80003e70:	1080                	add	s0,sp,96
    80003e72:	84aa                	mv	s1,a0
    80003e74:	8b2e                	mv	s6,a1
    80003e76:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e78:	00054703          	lbu	a4,0(a0)
    80003e7c:	02f00793          	li	a5,47
    80003e80:	02f70263          	beq	a4,a5,80003ea4 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e84:	ffffe097          	auipc	ra,0xffffe
    80003e88:	bb4080e7          	jalr	-1100(ra) # 80001a38 <myproc>
    80003e8c:	15853503          	ld	a0,344(a0)
    80003e90:	00000097          	auipc	ra,0x0
    80003e94:	9fc080e7          	jalr	-1540(ra) # 8000388c <idup>
    80003e98:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003e9a:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003e9e:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ea0:	4b85                	li	s7,1
    80003ea2:	a875                	j	80003f5e <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003ea4:	4585                	li	a1,1
    80003ea6:	4505                	li	a0,1
    80003ea8:	fffff097          	auipc	ra,0xfffff
    80003eac:	6f2080e7          	jalr	1778(ra) # 8000359a <iget>
    80003eb0:	8a2a                	mv	s4,a0
    80003eb2:	b7e5                	j	80003e9a <namex+0x42>
      iunlockput(ip);
    80003eb4:	8552                	mv	a0,s4
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	c76080e7          	jalr	-906(ra) # 80003b2c <iunlockput>
      return 0;
    80003ebe:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ec0:	8552                	mv	a0,s4
    80003ec2:	60e6                	ld	ra,88(sp)
    80003ec4:	6446                	ld	s0,80(sp)
    80003ec6:	64a6                	ld	s1,72(sp)
    80003ec8:	6906                	ld	s2,64(sp)
    80003eca:	79e2                	ld	s3,56(sp)
    80003ecc:	7a42                	ld	s4,48(sp)
    80003ece:	7aa2                	ld	s5,40(sp)
    80003ed0:	7b02                	ld	s6,32(sp)
    80003ed2:	6be2                	ld	s7,24(sp)
    80003ed4:	6c42                	ld	s8,16(sp)
    80003ed6:	6ca2                	ld	s9,8(sp)
    80003ed8:	6125                	add	sp,sp,96
    80003eda:	8082                	ret
      iunlock(ip);
    80003edc:	8552                	mv	a0,s4
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	aae080e7          	jalr	-1362(ra) # 8000398c <iunlock>
      return ip;
    80003ee6:	bfe9                	j	80003ec0 <namex+0x68>
      iunlockput(ip);
    80003ee8:	8552                	mv	a0,s4
    80003eea:	00000097          	auipc	ra,0x0
    80003eee:	c42080e7          	jalr	-958(ra) # 80003b2c <iunlockput>
      return 0;
    80003ef2:	8a4e                	mv	s4,s3
    80003ef4:	b7f1                	j	80003ec0 <namex+0x68>
  len = path - s;
    80003ef6:	40998633          	sub	a2,s3,s1
    80003efa:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003efe:	099c5863          	bge	s8,s9,80003f8e <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003f02:	4639                	li	a2,14
    80003f04:	85a6                	mv	a1,s1
    80003f06:	8556                	mv	a0,s5
    80003f08:	ffffd097          	auipc	ra,0xffffd
    80003f0c:	e4c080e7          	jalr	-436(ra) # 80000d54 <memmove>
    80003f10:	84ce                	mv	s1,s3
  while(*path == '/')
    80003f12:	0004c783          	lbu	a5,0(s1)
    80003f16:	01279763          	bne	a5,s2,80003f24 <namex+0xcc>
    path++;
    80003f1a:	0485                	add	s1,s1,1
  while(*path == '/')
    80003f1c:	0004c783          	lbu	a5,0(s1)
    80003f20:	ff278de3          	beq	a5,s2,80003f1a <namex+0xc2>
    ilock(ip);
    80003f24:	8552                	mv	a0,s4
    80003f26:	00000097          	auipc	ra,0x0
    80003f2a:	9a4080e7          	jalr	-1628(ra) # 800038ca <ilock>
    if(ip->type != T_DIR){
    80003f2e:	044a1783          	lh	a5,68(s4)
    80003f32:	f97791e3          	bne	a5,s7,80003eb4 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80003f36:	000b0563          	beqz	s6,80003f40 <namex+0xe8>
    80003f3a:	0004c783          	lbu	a5,0(s1)
    80003f3e:	dfd9                	beqz	a5,80003edc <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f40:	4601                	li	a2,0
    80003f42:	85d6                	mv	a1,s5
    80003f44:	8552                	mv	a0,s4
    80003f46:	00000097          	auipc	ra,0x0
    80003f4a:	e62080e7          	jalr	-414(ra) # 80003da8 <dirlookup>
    80003f4e:	89aa                	mv	s3,a0
    80003f50:	dd41                	beqz	a0,80003ee8 <namex+0x90>
    iunlockput(ip);
    80003f52:	8552                	mv	a0,s4
    80003f54:	00000097          	auipc	ra,0x0
    80003f58:	bd8080e7          	jalr	-1064(ra) # 80003b2c <iunlockput>
    ip = next;
    80003f5c:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003f5e:	0004c783          	lbu	a5,0(s1)
    80003f62:	01279763          	bne	a5,s2,80003f70 <namex+0x118>
    path++;
    80003f66:	0485                	add	s1,s1,1
  while(*path == '/')
    80003f68:	0004c783          	lbu	a5,0(s1)
    80003f6c:	ff278de3          	beq	a5,s2,80003f66 <namex+0x10e>
  if(*path == 0)
    80003f70:	cb9d                	beqz	a5,80003fa6 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80003f72:	0004c783          	lbu	a5,0(s1)
    80003f76:	89a6                	mv	s3,s1
  len = path - s;
    80003f78:	4c81                	li	s9,0
    80003f7a:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003f7c:	01278963          	beq	a5,s2,80003f8e <namex+0x136>
    80003f80:	dbbd                	beqz	a5,80003ef6 <namex+0x9e>
    path++;
    80003f82:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    80003f84:	0009c783          	lbu	a5,0(s3)
    80003f88:	ff279ce3          	bne	a5,s2,80003f80 <namex+0x128>
    80003f8c:	b7ad                	j	80003ef6 <namex+0x9e>
    memmove(name, s, len);
    80003f8e:	2601                	sext.w	a2,a2
    80003f90:	85a6                	mv	a1,s1
    80003f92:	8556                	mv	a0,s5
    80003f94:	ffffd097          	auipc	ra,0xffffd
    80003f98:	dc0080e7          	jalr	-576(ra) # 80000d54 <memmove>
    name[len] = 0;
    80003f9c:	9cd6                	add	s9,s9,s5
    80003f9e:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003fa2:	84ce                	mv	s1,s3
    80003fa4:	b7bd                	j	80003f12 <namex+0xba>
  if(nameiparent){
    80003fa6:	f00b0de3          	beqz	s6,80003ec0 <namex+0x68>
    iput(ip);
    80003faa:	8552                	mv	a0,s4
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	ad8080e7          	jalr	-1320(ra) # 80003a84 <iput>
    return 0;
    80003fb4:	4a01                	li	s4,0
    80003fb6:	b729                	j	80003ec0 <namex+0x68>

0000000080003fb8 <dirlink>:
{
    80003fb8:	7139                	add	sp,sp,-64
    80003fba:	fc06                	sd	ra,56(sp)
    80003fbc:	f822                	sd	s0,48(sp)
    80003fbe:	f426                	sd	s1,40(sp)
    80003fc0:	f04a                	sd	s2,32(sp)
    80003fc2:	ec4e                	sd	s3,24(sp)
    80003fc4:	e852                	sd	s4,16(sp)
    80003fc6:	0080                	add	s0,sp,64
    80003fc8:	892a                	mv	s2,a0
    80003fca:	8a2e                	mv	s4,a1
    80003fcc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fce:	4601                	li	a2,0
    80003fd0:	00000097          	auipc	ra,0x0
    80003fd4:	dd8080e7          	jalr	-552(ra) # 80003da8 <dirlookup>
    80003fd8:	e93d                	bnez	a0,8000404e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fda:	04c92483          	lw	s1,76(s2)
    80003fde:	c49d                	beqz	s1,8000400c <dirlink+0x54>
    80003fe0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fe2:	4741                	li	a4,16
    80003fe4:	86a6                	mv	a3,s1
    80003fe6:	fc040613          	add	a2,s0,-64
    80003fea:	4581                	li	a1,0
    80003fec:	854a                	mv	a0,s2
    80003fee:	00000097          	auipc	ra,0x0
    80003ff2:	b90080e7          	jalr	-1136(ra) # 80003b7e <readi>
    80003ff6:	47c1                	li	a5,16
    80003ff8:	06f51163          	bne	a0,a5,8000405a <dirlink+0xa2>
    if(de.inum == 0)
    80003ffc:	fc045783          	lhu	a5,-64(s0)
    80004000:	c791                	beqz	a5,8000400c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004002:	24c1                	addw	s1,s1,16
    80004004:	04c92783          	lw	a5,76(s2)
    80004008:	fcf4ede3          	bltu	s1,a5,80003fe2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000400c:	4639                	li	a2,14
    8000400e:	85d2                	mv	a1,s4
    80004010:	fc240513          	add	a0,s0,-62
    80004014:	ffffd097          	auipc	ra,0xffffd
    80004018:	df8080e7          	jalr	-520(ra) # 80000e0c <strncpy>
  de.inum = inum;
    8000401c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004020:	4741                	li	a4,16
    80004022:	86a6                	mv	a3,s1
    80004024:	fc040613          	add	a2,s0,-64
    80004028:	4581                	li	a1,0
    8000402a:	854a                	mv	a0,s2
    8000402c:	00000097          	auipc	ra,0x0
    80004030:	c48080e7          	jalr	-952(ra) # 80003c74 <writei>
    80004034:	872a                	mv	a4,a0
    80004036:	47c1                	li	a5,16
  return 0;
    80004038:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000403a:	02f71863          	bne	a4,a5,8000406a <dirlink+0xb2>
}
    8000403e:	70e2                	ld	ra,56(sp)
    80004040:	7442                	ld	s0,48(sp)
    80004042:	74a2                	ld	s1,40(sp)
    80004044:	7902                	ld	s2,32(sp)
    80004046:	69e2                	ld	s3,24(sp)
    80004048:	6a42                	ld	s4,16(sp)
    8000404a:	6121                	add	sp,sp,64
    8000404c:	8082                	ret
    iput(ip);
    8000404e:	00000097          	auipc	ra,0x0
    80004052:	a36080e7          	jalr	-1482(ra) # 80003a84 <iput>
    return -1;
    80004056:	557d                	li	a0,-1
    80004058:	b7dd                	j	8000403e <dirlink+0x86>
      panic("dirlink read");
    8000405a:	00004517          	auipc	a0,0x4
    8000405e:	5fe50513          	add	a0,a0,1534 # 80008658 <syscalls+0x1c8>
    80004062:	ffffc097          	auipc	ra,0xffffc
    80004066:	4e0080e7          	jalr	1248(ra) # 80000542 <panic>
    panic("dirlink");
    8000406a:	00004517          	auipc	a0,0x4
    8000406e:	70650513          	add	a0,a0,1798 # 80008770 <syscalls+0x2e0>
    80004072:	ffffc097          	auipc	ra,0xffffc
    80004076:	4d0080e7          	jalr	1232(ra) # 80000542 <panic>

000000008000407a <namei>:

struct inode*
namei(char *path)
{
    8000407a:	1101                	add	sp,sp,-32
    8000407c:	ec06                	sd	ra,24(sp)
    8000407e:	e822                	sd	s0,16(sp)
    80004080:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004082:	fe040613          	add	a2,s0,-32
    80004086:	4581                	li	a1,0
    80004088:	00000097          	auipc	ra,0x0
    8000408c:	dd0080e7          	jalr	-560(ra) # 80003e58 <namex>
}
    80004090:	60e2                	ld	ra,24(sp)
    80004092:	6442                	ld	s0,16(sp)
    80004094:	6105                	add	sp,sp,32
    80004096:	8082                	ret

0000000080004098 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004098:	1141                	add	sp,sp,-16
    8000409a:	e406                	sd	ra,8(sp)
    8000409c:	e022                	sd	s0,0(sp)
    8000409e:	0800                	add	s0,sp,16
    800040a0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040a2:	4585                	li	a1,1
    800040a4:	00000097          	auipc	ra,0x0
    800040a8:	db4080e7          	jalr	-588(ra) # 80003e58 <namex>
}
    800040ac:	60a2                	ld	ra,8(sp)
    800040ae:	6402                	ld	s0,0(sp)
    800040b0:	0141                	add	sp,sp,16
    800040b2:	8082                	ret

00000000800040b4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040b4:	1101                	add	sp,sp,-32
    800040b6:	ec06                	sd	ra,24(sp)
    800040b8:	e822                	sd	s0,16(sp)
    800040ba:	e426                	sd	s1,8(sp)
    800040bc:	e04a                	sd	s2,0(sp)
    800040be:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040c0:	0001e917          	auipc	s2,0x1e
    800040c4:	a4890913          	add	s2,s2,-1464 # 80021b08 <log>
    800040c8:	01892583          	lw	a1,24(s2)
    800040cc:	02892503          	lw	a0,40(s2)
    800040d0:	fffff097          	auipc	ra,0xfffff
    800040d4:	000080e7          	jalr	ra # 800030d0 <bread>
    800040d8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040da:	02c92603          	lw	a2,44(s2)
    800040de:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040e0:	00c05f63          	blez	a2,800040fe <write_head+0x4a>
    800040e4:	0001e717          	auipc	a4,0x1e
    800040e8:	a5470713          	add	a4,a4,-1452 # 80021b38 <log+0x30>
    800040ec:	87aa                	mv	a5,a0
    800040ee:	060a                	sll	a2,a2,0x2
    800040f0:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    800040f2:	4314                	lw	a3,0(a4)
    800040f4:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    800040f6:	0711                	add	a4,a4,4
    800040f8:	0791                	add	a5,a5,4
    800040fa:	fec79ce3          	bne	a5,a2,800040f2 <write_head+0x3e>
  }
  bwrite(buf);
    800040fe:	8526                	mv	a0,s1
    80004100:	fffff097          	auipc	ra,0xfffff
    80004104:	0c2080e7          	jalr	194(ra) # 800031c2 <bwrite>
  brelse(buf);
    80004108:	8526                	mv	a0,s1
    8000410a:	fffff097          	auipc	ra,0xfffff
    8000410e:	0f6080e7          	jalr	246(ra) # 80003200 <brelse>
}
    80004112:	60e2                	ld	ra,24(sp)
    80004114:	6442                	ld	s0,16(sp)
    80004116:	64a2                	ld	s1,8(sp)
    80004118:	6902                	ld	s2,0(sp)
    8000411a:	6105                	add	sp,sp,32
    8000411c:	8082                	ret

000000008000411e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000411e:	0001e797          	auipc	a5,0x1e
    80004122:	a167a783          	lw	a5,-1514(a5) # 80021b34 <log+0x2c>
    80004126:	0af05663          	blez	a5,800041d2 <install_trans+0xb4>
{
    8000412a:	7139                	add	sp,sp,-64
    8000412c:	fc06                	sd	ra,56(sp)
    8000412e:	f822                	sd	s0,48(sp)
    80004130:	f426                	sd	s1,40(sp)
    80004132:	f04a                	sd	s2,32(sp)
    80004134:	ec4e                	sd	s3,24(sp)
    80004136:	e852                	sd	s4,16(sp)
    80004138:	e456                	sd	s5,8(sp)
    8000413a:	0080                	add	s0,sp,64
    8000413c:	0001ea97          	auipc	s5,0x1e
    80004140:	9fca8a93          	add	s5,s5,-1540 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004144:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004146:	0001e997          	auipc	s3,0x1e
    8000414a:	9c298993          	add	s3,s3,-1598 # 80021b08 <log>
    8000414e:	0189a583          	lw	a1,24(s3)
    80004152:	014585bb          	addw	a1,a1,s4
    80004156:	2585                	addw	a1,a1,1
    80004158:	0289a503          	lw	a0,40(s3)
    8000415c:	fffff097          	auipc	ra,0xfffff
    80004160:	f74080e7          	jalr	-140(ra) # 800030d0 <bread>
    80004164:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004166:	000aa583          	lw	a1,0(s5)
    8000416a:	0289a503          	lw	a0,40(s3)
    8000416e:	fffff097          	auipc	ra,0xfffff
    80004172:	f62080e7          	jalr	-158(ra) # 800030d0 <bread>
    80004176:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004178:	40000613          	li	a2,1024
    8000417c:	05890593          	add	a1,s2,88
    80004180:	05850513          	add	a0,a0,88
    80004184:	ffffd097          	auipc	ra,0xffffd
    80004188:	bd0080e7          	jalr	-1072(ra) # 80000d54 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000418c:	8526                	mv	a0,s1
    8000418e:	fffff097          	auipc	ra,0xfffff
    80004192:	034080e7          	jalr	52(ra) # 800031c2 <bwrite>
    bunpin(dbuf);
    80004196:	8526                	mv	a0,s1
    80004198:	fffff097          	auipc	ra,0xfffff
    8000419c:	140080e7          	jalr	320(ra) # 800032d8 <bunpin>
    brelse(lbuf);
    800041a0:	854a                	mv	a0,s2
    800041a2:	fffff097          	auipc	ra,0xfffff
    800041a6:	05e080e7          	jalr	94(ra) # 80003200 <brelse>
    brelse(dbuf);
    800041aa:	8526                	mv	a0,s1
    800041ac:	fffff097          	auipc	ra,0xfffff
    800041b0:	054080e7          	jalr	84(ra) # 80003200 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041b4:	2a05                	addw	s4,s4,1
    800041b6:	0a91                	add	s5,s5,4
    800041b8:	02c9a783          	lw	a5,44(s3)
    800041bc:	f8fa49e3          	blt	s4,a5,8000414e <install_trans+0x30>
}
    800041c0:	70e2                	ld	ra,56(sp)
    800041c2:	7442                	ld	s0,48(sp)
    800041c4:	74a2                	ld	s1,40(sp)
    800041c6:	7902                	ld	s2,32(sp)
    800041c8:	69e2                	ld	s3,24(sp)
    800041ca:	6a42                	ld	s4,16(sp)
    800041cc:	6aa2                	ld	s5,8(sp)
    800041ce:	6121                	add	sp,sp,64
    800041d0:	8082                	ret
    800041d2:	8082                	ret

00000000800041d4 <initlog>:
{
    800041d4:	7179                	add	sp,sp,-48
    800041d6:	f406                	sd	ra,40(sp)
    800041d8:	f022                	sd	s0,32(sp)
    800041da:	ec26                	sd	s1,24(sp)
    800041dc:	e84a                	sd	s2,16(sp)
    800041de:	e44e                	sd	s3,8(sp)
    800041e0:	1800                	add	s0,sp,48
    800041e2:	892a                	mv	s2,a0
    800041e4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041e6:	0001e497          	auipc	s1,0x1e
    800041ea:	92248493          	add	s1,s1,-1758 # 80021b08 <log>
    800041ee:	00004597          	auipc	a1,0x4
    800041f2:	47a58593          	add	a1,a1,1146 # 80008668 <syscalls+0x1d8>
    800041f6:	8526                	mv	a0,s1
    800041f8:	ffffd097          	auipc	ra,0xffffd
    800041fc:	974080e7          	jalr	-1676(ra) # 80000b6c <initlock>
  log.start = sb->logstart;
    80004200:	0149a583          	lw	a1,20(s3)
    80004204:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004206:	0109a783          	lw	a5,16(s3)
    8000420a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000420c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004210:	854a                	mv	a0,s2
    80004212:	fffff097          	auipc	ra,0xfffff
    80004216:	ebe080e7          	jalr	-322(ra) # 800030d0 <bread>
  log.lh.n = lh->n;
    8000421a:	4d30                	lw	a2,88(a0)
    8000421c:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000421e:	00c05f63          	blez	a2,8000423c <initlog+0x68>
    80004222:	87aa                	mv	a5,a0
    80004224:	0001e717          	auipc	a4,0x1e
    80004228:	91470713          	add	a4,a4,-1772 # 80021b38 <log+0x30>
    8000422c:	060a                	sll	a2,a2,0x2
    8000422e:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004230:	4ff4                	lw	a3,92(a5)
    80004232:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004234:	0791                	add	a5,a5,4
    80004236:	0711                	add	a4,a4,4
    80004238:	fec79ce3          	bne	a5,a2,80004230 <initlog+0x5c>
  brelse(buf);
    8000423c:	fffff097          	auipc	ra,0xfffff
    80004240:	fc4080e7          	jalr	-60(ra) # 80003200 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004244:	00000097          	auipc	ra,0x0
    80004248:	eda080e7          	jalr	-294(ra) # 8000411e <install_trans>
  log.lh.n = 0;
    8000424c:	0001e797          	auipc	a5,0x1e
    80004250:	8e07a423          	sw	zero,-1816(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    80004254:	00000097          	auipc	ra,0x0
    80004258:	e60080e7          	jalr	-416(ra) # 800040b4 <write_head>
}
    8000425c:	70a2                	ld	ra,40(sp)
    8000425e:	7402                	ld	s0,32(sp)
    80004260:	64e2                	ld	s1,24(sp)
    80004262:	6942                	ld	s2,16(sp)
    80004264:	69a2                	ld	s3,8(sp)
    80004266:	6145                	add	sp,sp,48
    80004268:	8082                	ret

000000008000426a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000426a:	1101                	add	sp,sp,-32
    8000426c:	ec06                	sd	ra,24(sp)
    8000426e:	e822                	sd	s0,16(sp)
    80004270:	e426                	sd	s1,8(sp)
    80004272:	e04a                	sd	s2,0(sp)
    80004274:	1000                	add	s0,sp,32
  acquire(&log.lock);
    80004276:	0001e517          	auipc	a0,0x1e
    8000427a:	89250513          	add	a0,a0,-1902 # 80021b08 <log>
    8000427e:	ffffd097          	auipc	ra,0xffffd
    80004282:	97e080e7          	jalr	-1666(ra) # 80000bfc <acquire>
  while(1){
    if(log.committing){
    80004286:	0001e497          	auipc	s1,0x1e
    8000428a:	88248493          	add	s1,s1,-1918 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000428e:	4979                	li	s2,30
    80004290:	a039                	j	8000429e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004292:	85a6                	mv	a1,s1
    80004294:	8526                	mv	a0,s1
    80004296:	ffffe097          	auipc	ra,0xffffe
    8000429a:	21e080e7          	jalr	542(ra) # 800024b4 <sleep>
    if(log.committing){
    8000429e:	50dc                	lw	a5,36(s1)
    800042a0:	fbed                	bnez	a5,80004292 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042a2:	5098                	lw	a4,32(s1)
    800042a4:	2705                	addw	a4,a4,1
    800042a6:	0027179b          	sllw	a5,a4,0x2
    800042aa:	9fb9                	addw	a5,a5,a4
    800042ac:	0017979b          	sllw	a5,a5,0x1
    800042b0:	54d4                	lw	a3,44(s1)
    800042b2:	9fb5                	addw	a5,a5,a3
    800042b4:	00f95963          	bge	s2,a5,800042c6 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042b8:	85a6                	mv	a1,s1
    800042ba:	8526                	mv	a0,s1
    800042bc:	ffffe097          	auipc	ra,0xffffe
    800042c0:	1f8080e7          	jalr	504(ra) # 800024b4 <sleep>
    800042c4:	bfe9                	j	8000429e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042c6:	0001e517          	auipc	a0,0x1e
    800042ca:	84250513          	add	a0,a0,-1982 # 80021b08 <log>
    800042ce:	d118                	sw	a4,32(a0)
      release(&log.lock);
    800042d0:	ffffd097          	auipc	ra,0xffffd
    800042d4:	9e0080e7          	jalr	-1568(ra) # 80000cb0 <release>
      break;
    }
  }
}
    800042d8:	60e2                	ld	ra,24(sp)
    800042da:	6442                	ld	s0,16(sp)
    800042dc:	64a2                	ld	s1,8(sp)
    800042de:	6902                	ld	s2,0(sp)
    800042e0:	6105                	add	sp,sp,32
    800042e2:	8082                	ret

00000000800042e4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042e4:	7139                	add	sp,sp,-64
    800042e6:	fc06                	sd	ra,56(sp)
    800042e8:	f822                	sd	s0,48(sp)
    800042ea:	f426                	sd	s1,40(sp)
    800042ec:	f04a                	sd	s2,32(sp)
    800042ee:	ec4e                	sd	s3,24(sp)
    800042f0:	e852                	sd	s4,16(sp)
    800042f2:	e456                	sd	s5,8(sp)
    800042f4:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042f6:	0001e497          	auipc	s1,0x1e
    800042fa:	81248493          	add	s1,s1,-2030 # 80021b08 <log>
    800042fe:	8526                	mv	a0,s1
    80004300:	ffffd097          	auipc	ra,0xffffd
    80004304:	8fc080e7          	jalr	-1796(ra) # 80000bfc <acquire>
  log.outstanding -= 1;
    80004308:	509c                	lw	a5,32(s1)
    8000430a:	37fd                	addw	a5,a5,-1
    8000430c:	0007891b          	sext.w	s2,a5
    80004310:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004312:	50dc                	lw	a5,36(s1)
    80004314:	e7b9                	bnez	a5,80004362 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004316:	04091e63          	bnez	s2,80004372 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000431a:	0001d497          	auipc	s1,0x1d
    8000431e:	7ee48493          	add	s1,s1,2030 # 80021b08 <log>
    80004322:	4785                	li	a5,1
    80004324:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004326:	8526                	mv	a0,s1
    80004328:	ffffd097          	auipc	ra,0xffffd
    8000432c:	988080e7          	jalr	-1656(ra) # 80000cb0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004330:	54dc                	lw	a5,44(s1)
    80004332:	06f04763          	bgtz	a5,800043a0 <end_op+0xbc>
    acquire(&log.lock);
    80004336:	0001d497          	auipc	s1,0x1d
    8000433a:	7d248493          	add	s1,s1,2002 # 80021b08 <log>
    8000433e:	8526                	mv	a0,s1
    80004340:	ffffd097          	auipc	ra,0xffffd
    80004344:	8bc080e7          	jalr	-1860(ra) # 80000bfc <acquire>
    log.committing = 0;
    80004348:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000434c:	8526                	mv	a0,s1
    8000434e:	ffffe097          	auipc	ra,0xffffe
    80004352:	2e6080e7          	jalr	742(ra) # 80002634 <wakeup>
    release(&log.lock);
    80004356:	8526                	mv	a0,s1
    80004358:	ffffd097          	auipc	ra,0xffffd
    8000435c:	958080e7          	jalr	-1704(ra) # 80000cb0 <release>
}
    80004360:	a03d                	j	8000438e <end_op+0xaa>
    panic("log.committing");
    80004362:	00004517          	auipc	a0,0x4
    80004366:	30e50513          	add	a0,a0,782 # 80008670 <syscalls+0x1e0>
    8000436a:	ffffc097          	auipc	ra,0xffffc
    8000436e:	1d8080e7          	jalr	472(ra) # 80000542 <panic>
    wakeup(&log);
    80004372:	0001d497          	auipc	s1,0x1d
    80004376:	79648493          	add	s1,s1,1942 # 80021b08 <log>
    8000437a:	8526                	mv	a0,s1
    8000437c:	ffffe097          	auipc	ra,0xffffe
    80004380:	2b8080e7          	jalr	696(ra) # 80002634 <wakeup>
  release(&log.lock);
    80004384:	8526                	mv	a0,s1
    80004386:	ffffd097          	auipc	ra,0xffffd
    8000438a:	92a080e7          	jalr	-1750(ra) # 80000cb0 <release>
}
    8000438e:	70e2                	ld	ra,56(sp)
    80004390:	7442                	ld	s0,48(sp)
    80004392:	74a2                	ld	s1,40(sp)
    80004394:	7902                	ld	s2,32(sp)
    80004396:	69e2                	ld	s3,24(sp)
    80004398:	6a42                	ld	s4,16(sp)
    8000439a:	6aa2                	ld	s5,8(sp)
    8000439c:	6121                	add	sp,sp,64
    8000439e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800043a0:	0001da97          	auipc	s5,0x1d
    800043a4:	798a8a93          	add	s5,s5,1944 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043a8:	0001da17          	auipc	s4,0x1d
    800043ac:	760a0a13          	add	s4,s4,1888 # 80021b08 <log>
    800043b0:	018a2583          	lw	a1,24(s4)
    800043b4:	012585bb          	addw	a1,a1,s2
    800043b8:	2585                	addw	a1,a1,1
    800043ba:	028a2503          	lw	a0,40(s4)
    800043be:	fffff097          	auipc	ra,0xfffff
    800043c2:	d12080e7          	jalr	-750(ra) # 800030d0 <bread>
    800043c6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043c8:	000aa583          	lw	a1,0(s5)
    800043cc:	028a2503          	lw	a0,40(s4)
    800043d0:	fffff097          	auipc	ra,0xfffff
    800043d4:	d00080e7          	jalr	-768(ra) # 800030d0 <bread>
    800043d8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043da:	40000613          	li	a2,1024
    800043de:	05850593          	add	a1,a0,88
    800043e2:	05848513          	add	a0,s1,88
    800043e6:	ffffd097          	auipc	ra,0xffffd
    800043ea:	96e080e7          	jalr	-1682(ra) # 80000d54 <memmove>
    bwrite(to);  // write the log
    800043ee:	8526                	mv	a0,s1
    800043f0:	fffff097          	auipc	ra,0xfffff
    800043f4:	dd2080e7          	jalr	-558(ra) # 800031c2 <bwrite>
    brelse(from);
    800043f8:	854e                	mv	a0,s3
    800043fa:	fffff097          	auipc	ra,0xfffff
    800043fe:	e06080e7          	jalr	-506(ra) # 80003200 <brelse>
    brelse(to);
    80004402:	8526                	mv	a0,s1
    80004404:	fffff097          	auipc	ra,0xfffff
    80004408:	dfc080e7          	jalr	-516(ra) # 80003200 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000440c:	2905                	addw	s2,s2,1
    8000440e:	0a91                	add	s5,s5,4
    80004410:	02ca2783          	lw	a5,44(s4)
    80004414:	f8f94ee3          	blt	s2,a5,800043b0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004418:	00000097          	auipc	ra,0x0
    8000441c:	c9c080e7          	jalr	-868(ra) # 800040b4 <write_head>
    install_trans(); // Now install writes to home locations
    80004420:	00000097          	auipc	ra,0x0
    80004424:	cfe080e7          	jalr	-770(ra) # 8000411e <install_trans>
    log.lh.n = 0;
    80004428:	0001d797          	auipc	a5,0x1d
    8000442c:	7007a623          	sw	zero,1804(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004430:	00000097          	auipc	ra,0x0
    80004434:	c84080e7          	jalr	-892(ra) # 800040b4 <write_head>
    80004438:	bdfd                	j	80004336 <end_op+0x52>

000000008000443a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000443a:	1101                	add	sp,sp,-32
    8000443c:	ec06                	sd	ra,24(sp)
    8000443e:	e822                	sd	s0,16(sp)
    80004440:	e426                	sd	s1,8(sp)
    80004442:	e04a                	sd	s2,0(sp)
    80004444:	1000                	add	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004446:	0001d717          	auipc	a4,0x1d
    8000444a:	6ee72703          	lw	a4,1774(a4) # 80021b34 <log+0x2c>
    8000444e:	47f5                	li	a5,29
    80004450:	08e7c063          	blt	a5,a4,800044d0 <log_write+0x96>
    80004454:	84aa                	mv	s1,a0
    80004456:	0001d797          	auipc	a5,0x1d
    8000445a:	6ce7a783          	lw	a5,1742(a5) # 80021b24 <log+0x1c>
    8000445e:	37fd                	addw	a5,a5,-1
    80004460:	06f75863          	bge	a4,a5,800044d0 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004464:	0001d797          	auipc	a5,0x1d
    80004468:	6c47a783          	lw	a5,1732(a5) # 80021b28 <log+0x20>
    8000446c:	06f05a63          	blez	a5,800044e0 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004470:	0001d917          	auipc	s2,0x1d
    80004474:	69890913          	add	s2,s2,1688 # 80021b08 <log>
    80004478:	854a                	mv	a0,s2
    8000447a:	ffffc097          	auipc	ra,0xffffc
    8000447e:	782080e7          	jalr	1922(ra) # 80000bfc <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004482:	02c92603          	lw	a2,44(s2)
    80004486:	06c05563          	blez	a2,800044f0 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000448a:	44cc                	lw	a1,12(s1)
    8000448c:	0001d717          	auipc	a4,0x1d
    80004490:	6ac70713          	add	a4,a4,1708 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004494:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004496:	4314                	lw	a3,0(a4)
    80004498:	04b68d63          	beq	a3,a1,800044f2 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000449c:	2785                	addw	a5,a5,1
    8000449e:	0711                	add	a4,a4,4
    800044a0:	fec79be3          	bne	a5,a2,80004496 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044a4:	0621                	add	a2,a2,8
    800044a6:	060a                	sll	a2,a2,0x2
    800044a8:	0001d797          	auipc	a5,0x1d
    800044ac:	66078793          	add	a5,a5,1632 # 80021b08 <log>
    800044b0:	97b2                	add	a5,a5,a2
    800044b2:	44d8                	lw	a4,12(s1)
    800044b4:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044b6:	8526                	mv	a0,s1
    800044b8:	fffff097          	auipc	ra,0xfffff
    800044bc:	de4080e7          	jalr	-540(ra) # 8000329c <bpin>
    log.lh.n++;
    800044c0:	0001d717          	auipc	a4,0x1d
    800044c4:	64870713          	add	a4,a4,1608 # 80021b08 <log>
    800044c8:	575c                	lw	a5,44(a4)
    800044ca:	2785                	addw	a5,a5,1
    800044cc:	d75c                	sw	a5,44(a4)
    800044ce:	a835                	j	8000450a <log_write+0xd0>
    panic("too big a transaction");
    800044d0:	00004517          	auipc	a0,0x4
    800044d4:	1b050513          	add	a0,a0,432 # 80008680 <syscalls+0x1f0>
    800044d8:	ffffc097          	auipc	ra,0xffffc
    800044dc:	06a080e7          	jalr	106(ra) # 80000542 <panic>
    panic("log_write outside of trans");
    800044e0:	00004517          	auipc	a0,0x4
    800044e4:	1b850513          	add	a0,a0,440 # 80008698 <syscalls+0x208>
    800044e8:	ffffc097          	auipc	ra,0xffffc
    800044ec:	05a080e7          	jalr	90(ra) # 80000542 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800044f0:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800044f2:	00878693          	add	a3,a5,8
    800044f6:	068a                	sll	a3,a3,0x2
    800044f8:	0001d717          	auipc	a4,0x1d
    800044fc:	61070713          	add	a4,a4,1552 # 80021b08 <log>
    80004500:	9736                	add	a4,a4,a3
    80004502:	44d4                	lw	a3,12(s1)
    80004504:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004506:	faf608e3          	beq	a2,a5,800044b6 <log_write+0x7c>
  }
  release(&log.lock);
    8000450a:	0001d517          	auipc	a0,0x1d
    8000450e:	5fe50513          	add	a0,a0,1534 # 80021b08 <log>
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	79e080e7          	jalr	1950(ra) # 80000cb0 <release>
}
    8000451a:	60e2                	ld	ra,24(sp)
    8000451c:	6442                	ld	s0,16(sp)
    8000451e:	64a2                	ld	s1,8(sp)
    80004520:	6902                	ld	s2,0(sp)
    80004522:	6105                	add	sp,sp,32
    80004524:	8082                	ret

0000000080004526 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004526:	1101                	add	sp,sp,-32
    80004528:	ec06                	sd	ra,24(sp)
    8000452a:	e822                	sd	s0,16(sp)
    8000452c:	e426                	sd	s1,8(sp)
    8000452e:	e04a                	sd	s2,0(sp)
    80004530:	1000                	add	s0,sp,32
    80004532:	84aa                	mv	s1,a0
    80004534:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004536:	00004597          	auipc	a1,0x4
    8000453a:	18258593          	add	a1,a1,386 # 800086b8 <syscalls+0x228>
    8000453e:	0521                	add	a0,a0,8
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	62c080e7          	jalr	1580(ra) # 80000b6c <initlock>
  lk->name = name;
    80004548:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000454c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004550:	0204a423          	sw	zero,40(s1)
}
    80004554:	60e2                	ld	ra,24(sp)
    80004556:	6442                	ld	s0,16(sp)
    80004558:	64a2                	ld	s1,8(sp)
    8000455a:	6902                	ld	s2,0(sp)
    8000455c:	6105                	add	sp,sp,32
    8000455e:	8082                	ret

0000000080004560 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004560:	1101                	add	sp,sp,-32
    80004562:	ec06                	sd	ra,24(sp)
    80004564:	e822                	sd	s0,16(sp)
    80004566:	e426                	sd	s1,8(sp)
    80004568:	e04a                	sd	s2,0(sp)
    8000456a:	1000                	add	s0,sp,32
    8000456c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000456e:	00850913          	add	s2,a0,8
    80004572:	854a                	mv	a0,s2
    80004574:	ffffc097          	auipc	ra,0xffffc
    80004578:	688080e7          	jalr	1672(ra) # 80000bfc <acquire>
  while (lk->locked) {
    8000457c:	409c                	lw	a5,0(s1)
    8000457e:	cb89                	beqz	a5,80004590 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004580:	85ca                	mv	a1,s2
    80004582:	8526                	mv	a0,s1
    80004584:	ffffe097          	auipc	ra,0xffffe
    80004588:	f30080e7          	jalr	-208(ra) # 800024b4 <sleep>
  while (lk->locked) {
    8000458c:	409c                	lw	a5,0(s1)
    8000458e:	fbed                	bnez	a5,80004580 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004590:	4785                	li	a5,1
    80004592:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004594:	ffffd097          	auipc	ra,0xffffd
    80004598:	4a4080e7          	jalr	1188(ra) # 80001a38 <myproc>
    8000459c:	5d1c                	lw	a5,56(a0)
    8000459e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045a0:	854a                	mv	a0,s2
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	70e080e7          	jalr	1806(ra) # 80000cb0 <release>
}
    800045aa:	60e2                	ld	ra,24(sp)
    800045ac:	6442                	ld	s0,16(sp)
    800045ae:	64a2                	ld	s1,8(sp)
    800045b0:	6902                	ld	s2,0(sp)
    800045b2:	6105                	add	sp,sp,32
    800045b4:	8082                	ret

00000000800045b6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045b6:	1101                	add	sp,sp,-32
    800045b8:	ec06                	sd	ra,24(sp)
    800045ba:	e822                	sd	s0,16(sp)
    800045bc:	e426                	sd	s1,8(sp)
    800045be:	e04a                	sd	s2,0(sp)
    800045c0:	1000                	add	s0,sp,32
    800045c2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045c4:	00850913          	add	s2,a0,8
    800045c8:	854a                	mv	a0,s2
    800045ca:	ffffc097          	auipc	ra,0xffffc
    800045ce:	632080e7          	jalr	1586(ra) # 80000bfc <acquire>
  lk->locked = 0;
    800045d2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045d6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045da:	8526                	mv	a0,s1
    800045dc:	ffffe097          	auipc	ra,0xffffe
    800045e0:	058080e7          	jalr	88(ra) # 80002634 <wakeup>
  release(&lk->lk);
    800045e4:	854a                	mv	a0,s2
    800045e6:	ffffc097          	auipc	ra,0xffffc
    800045ea:	6ca080e7          	jalr	1738(ra) # 80000cb0 <release>
}
    800045ee:	60e2                	ld	ra,24(sp)
    800045f0:	6442                	ld	s0,16(sp)
    800045f2:	64a2                	ld	s1,8(sp)
    800045f4:	6902                	ld	s2,0(sp)
    800045f6:	6105                	add	sp,sp,32
    800045f8:	8082                	ret

00000000800045fa <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045fa:	7179                	add	sp,sp,-48
    800045fc:	f406                	sd	ra,40(sp)
    800045fe:	f022                	sd	s0,32(sp)
    80004600:	ec26                	sd	s1,24(sp)
    80004602:	e84a                	sd	s2,16(sp)
    80004604:	e44e                	sd	s3,8(sp)
    80004606:	1800                	add	s0,sp,48
    80004608:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000460a:	00850913          	add	s2,a0,8
    8000460e:	854a                	mv	a0,s2
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	5ec080e7          	jalr	1516(ra) # 80000bfc <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004618:	409c                	lw	a5,0(s1)
    8000461a:	ef99                	bnez	a5,80004638 <holdingsleep+0x3e>
    8000461c:	4481                	li	s1,0
  release(&lk->lk);
    8000461e:	854a                	mv	a0,s2
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	690080e7          	jalr	1680(ra) # 80000cb0 <release>
  return r;
}
    80004628:	8526                	mv	a0,s1
    8000462a:	70a2                	ld	ra,40(sp)
    8000462c:	7402                	ld	s0,32(sp)
    8000462e:	64e2                	ld	s1,24(sp)
    80004630:	6942                	ld	s2,16(sp)
    80004632:	69a2                	ld	s3,8(sp)
    80004634:	6145                	add	sp,sp,48
    80004636:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004638:	0284a983          	lw	s3,40(s1)
    8000463c:	ffffd097          	auipc	ra,0xffffd
    80004640:	3fc080e7          	jalr	1020(ra) # 80001a38 <myproc>
    80004644:	5d04                	lw	s1,56(a0)
    80004646:	413484b3          	sub	s1,s1,s3
    8000464a:	0014b493          	seqz	s1,s1
    8000464e:	bfc1                	j	8000461e <holdingsleep+0x24>

0000000080004650 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004650:	1141                	add	sp,sp,-16
    80004652:	e406                	sd	ra,8(sp)
    80004654:	e022                	sd	s0,0(sp)
    80004656:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004658:	00004597          	auipc	a1,0x4
    8000465c:	07058593          	add	a1,a1,112 # 800086c8 <syscalls+0x238>
    80004660:	0001d517          	auipc	a0,0x1d
    80004664:	5f050513          	add	a0,a0,1520 # 80021c50 <ftable>
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	504080e7          	jalr	1284(ra) # 80000b6c <initlock>
}
    80004670:	60a2                	ld	ra,8(sp)
    80004672:	6402                	ld	s0,0(sp)
    80004674:	0141                	add	sp,sp,16
    80004676:	8082                	ret

0000000080004678 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004678:	1101                	add	sp,sp,-32
    8000467a:	ec06                	sd	ra,24(sp)
    8000467c:	e822                	sd	s0,16(sp)
    8000467e:	e426                	sd	s1,8(sp)
    80004680:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004682:	0001d517          	auipc	a0,0x1d
    80004686:	5ce50513          	add	a0,a0,1486 # 80021c50 <ftable>
    8000468a:	ffffc097          	auipc	ra,0xffffc
    8000468e:	572080e7          	jalr	1394(ra) # 80000bfc <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004692:	0001d497          	auipc	s1,0x1d
    80004696:	5d648493          	add	s1,s1,1494 # 80021c68 <ftable+0x18>
    8000469a:	0001e717          	auipc	a4,0x1e
    8000469e:	56e70713          	add	a4,a4,1390 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    800046a2:	40dc                	lw	a5,4(s1)
    800046a4:	cf99                	beqz	a5,800046c2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046a6:	02848493          	add	s1,s1,40
    800046aa:	fee49ce3          	bne	s1,a4,800046a2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046ae:	0001d517          	auipc	a0,0x1d
    800046b2:	5a250513          	add	a0,a0,1442 # 80021c50 <ftable>
    800046b6:	ffffc097          	auipc	ra,0xffffc
    800046ba:	5fa080e7          	jalr	1530(ra) # 80000cb0 <release>
  return 0;
    800046be:	4481                	li	s1,0
    800046c0:	a819                	j	800046d6 <filealloc+0x5e>
      f->ref = 1;
    800046c2:	4785                	li	a5,1
    800046c4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046c6:	0001d517          	auipc	a0,0x1d
    800046ca:	58a50513          	add	a0,a0,1418 # 80021c50 <ftable>
    800046ce:	ffffc097          	auipc	ra,0xffffc
    800046d2:	5e2080e7          	jalr	1506(ra) # 80000cb0 <release>
}
    800046d6:	8526                	mv	a0,s1
    800046d8:	60e2                	ld	ra,24(sp)
    800046da:	6442                	ld	s0,16(sp)
    800046dc:	64a2                	ld	s1,8(sp)
    800046de:	6105                	add	sp,sp,32
    800046e0:	8082                	ret

00000000800046e2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046e2:	1101                	add	sp,sp,-32
    800046e4:	ec06                	sd	ra,24(sp)
    800046e6:	e822                	sd	s0,16(sp)
    800046e8:	e426                	sd	s1,8(sp)
    800046ea:	1000                	add	s0,sp,32
    800046ec:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046ee:	0001d517          	auipc	a0,0x1d
    800046f2:	56250513          	add	a0,a0,1378 # 80021c50 <ftable>
    800046f6:	ffffc097          	auipc	ra,0xffffc
    800046fa:	506080e7          	jalr	1286(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    800046fe:	40dc                	lw	a5,4(s1)
    80004700:	02f05263          	blez	a5,80004724 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004704:	2785                	addw	a5,a5,1
    80004706:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004708:	0001d517          	auipc	a0,0x1d
    8000470c:	54850513          	add	a0,a0,1352 # 80021c50 <ftable>
    80004710:	ffffc097          	auipc	ra,0xffffc
    80004714:	5a0080e7          	jalr	1440(ra) # 80000cb0 <release>
  return f;
}
    80004718:	8526                	mv	a0,s1
    8000471a:	60e2                	ld	ra,24(sp)
    8000471c:	6442                	ld	s0,16(sp)
    8000471e:	64a2                	ld	s1,8(sp)
    80004720:	6105                	add	sp,sp,32
    80004722:	8082                	ret
    panic("filedup");
    80004724:	00004517          	auipc	a0,0x4
    80004728:	fac50513          	add	a0,a0,-84 # 800086d0 <syscalls+0x240>
    8000472c:	ffffc097          	auipc	ra,0xffffc
    80004730:	e16080e7          	jalr	-490(ra) # 80000542 <panic>

0000000080004734 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004734:	7139                	add	sp,sp,-64
    80004736:	fc06                	sd	ra,56(sp)
    80004738:	f822                	sd	s0,48(sp)
    8000473a:	f426                	sd	s1,40(sp)
    8000473c:	f04a                	sd	s2,32(sp)
    8000473e:	ec4e                	sd	s3,24(sp)
    80004740:	e852                	sd	s4,16(sp)
    80004742:	e456                	sd	s5,8(sp)
    80004744:	0080                	add	s0,sp,64
    80004746:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004748:	0001d517          	auipc	a0,0x1d
    8000474c:	50850513          	add	a0,a0,1288 # 80021c50 <ftable>
    80004750:	ffffc097          	auipc	ra,0xffffc
    80004754:	4ac080e7          	jalr	1196(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    80004758:	40dc                	lw	a5,4(s1)
    8000475a:	06f05163          	blez	a5,800047bc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000475e:	37fd                	addw	a5,a5,-1
    80004760:	0007871b          	sext.w	a4,a5
    80004764:	c0dc                	sw	a5,4(s1)
    80004766:	06e04363          	bgtz	a4,800047cc <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000476a:	0004a903          	lw	s2,0(s1)
    8000476e:	0094ca83          	lbu	s5,9(s1)
    80004772:	0104ba03          	ld	s4,16(s1)
    80004776:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000477a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000477e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004782:	0001d517          	auipc	a0,0x1d
    80004786:	4ce50513          	add	a0,a0,1230 # 80021c50 <ftable>
    8000478a:	ffffc097          	auipc	ra,0xffffc
    8000478e:	526080e7          	jalr	1318(ra) # 80000cb0 <release>

  if(ff.type == FD_PIPE){
    80004792:	4785                	li	a5,1
    80004794:	04f90d63          	beq	s2,a5,800047ee <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004798:	3979                	addw	s2,s2,-2
    8000479a:	4785                	li	a5,1
    8000479c:	0527e063          	bltu	a5,s2,800047dc <fileclose+0xa8>
    begin_op();
    800047a0:	00000097          	auipc	ra,0x0
    800047a4:	aca080e7          	jalr	-1334(ra) # 8000426a <begin_op>
    iput(ff.ip);
    800047a8:	854e                	mv	a0,s3
    800047aa:	fffff097          	auipc	ra,0xfffff
    800047ae:	2da080e7          	jalr	730(ra) # 80003a84 <iput>
    end_op();
    800047b2:	00000097          	auipc	ra,0x0
    800047b6:	b32080e7          	jalr	-1230(ra) # 800042e4 <end_op>
    800047ba:	a00d                	j	800047dc <fileclose+0xa8>
    panic("fileclose");
    800047bc:	00004517          	auipc	a0,0x4
    800047c0:	f1c50513          	add	a0,a0,-228 # 800086d8 <syscalls+0x248>
    800047c4:	ffffc097          	auipc	ra,0xffffc
    800047c8:	d7e080e7          	jalr	-642(ra) # 80000542 <panic>
    release(&ftable.lock);
    800047cc:	0001d517          	auipc	a0,0x1d
    800047d0:	48450513          	add	a0,a0,1156 # 80021c50 <ftable>
    800047d4:	ffffc097          	auipc	ra,0xffffc
    800047d8:	4dc080e7          	jalr	1244(ra) # 80000cb0 <release>
  }
}
    800047dc:	70e2                	ld	ra,56(sp)
    800047de:	7442                	ld	s0,48(sp)
    800047e0:	74a2                	ld	s1,40(sp)
    800047e2:	7902                	ld	s2,32(sp)
    800047e4:	69e2                	ld	s3,24(sp)
    800047e6:	6a42                	ld	s4,16(sp)
    800047e8:	6aa2                	ld	s5,8(sp)
    800047ea:	6121                	add	sp,sp,64
    800047ec:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047ee:	85d6                	mv	a1,s5
    800047f0:	8552                	mv	a0,s4
    800047f2:	00000097          	auipc	ra,0x0
    800047f6:	372080e7          	jalr	882(ra) # 80004b64 <pipeclose>
    800047fa:	b7cd                	j	800047dc <fileclose+0xa8>

00000000800047fc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047fc:	715d                	add	sp,sp,-80
    800047fe:	e486                	sd	ra,72(sp)
    80004800:	e0a2                	sd	s0,64(sp)
    80004802:	fc26                	sd	s1,56(sp)
    80004804:	f84a                	sd	s2,48(sp)
    80004806:	f44e                	sd	s3,40(sp)
    80004808:	0880                	add	s0,sp,80
    8000480a:	84aa                	mv	s1,a0
    8000480c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000480e:	ffffd097          	auipc	ra,0xffffd
    80004812:	22a080e7          	jalr	554(ra) # 80001a38 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004816:	409c                	lw	a5,0(s1)
    80004818:	37f9                	addw	a5,a5,-2
    8000481a:	4705                	li	a4,1
    8000481c:	04f76763          	bltu	a4,a5,8000486a <filestat+0x6e>
    80004820:	892a                	mv	s2,a0
    ilock(f->ip);
    80004822:	6c88                	ld	a0,24(s1)
    80004824:	fffff097          	auipc	ra,0xfffff
    80004828:	0a6080e7          	jalr	166(ra) # 800038ca <ilock>
    stati(f->ip, &st);
    8000482c:	fb840593          	add	a1,s0,-72
    80004830:	6c88                	ld	a0,24(s1)
    80004832:	fffff097          	auipc	ra,0xfffff
    80004836:	322080e7          	jalr	802(ra) # 80003b54 <stati>
    iunlock(f->ip);
    8000483a:	6c88                	ld	a0,24(s1)
    8000483c:	fffff097          	auipc	ra,0xfffff
    80004840:	150080e7          	jalr	336(ra) # 8000398c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004844:	46e1                	li	a3,24
    80004846:	fb840613          	add	a2,s0,-72
    8000484a:	85ce                	mv	a1,s3
    8000484c:	05093503          	ld	a0,80(s2)
    80004850:	ffffd097          	auipc	ra,0xffffd
    80004854:	054080e7          	jalr	84(ra) # 800018a4 <copyout>
    80004858:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000485c:	60a6                	ld	ra,72(sp)
    8000485e:	6406                	ld	s0,64(sp)
    80004860:	74e2                	ld	s1,56(sp)
    80004862:	7942                	ld	s2,48(sp)
    80004864:	79a2                	ld	s3,40(sp)
    80004866:	6161                	add	sp,sp,80
    80004868:	8082                	ret
  return -1;
    8000486a:	557d                	li	a0,-1
    8000486c:	bfc5                	j	8000485c <filestat+0x60>

000000008000486e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000486e:	7179                	add	sp,sp,-48
    80004870:	f406                	sd	ra,40(sp)
    80004872:	f022                	sd	s0,32(sp)
    80004874:	ec26                	sd	s1,24(sp)
    80004876:	e84a                	sd	s2,16(sp)
    80004878:	e44e                	sd	s3,8(sp)
    8000487a:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000487c:	00854783          	lbu	a5,8(a0)
    80004880:	c3d5                	beqz	a5,80004924 <fileread+0xb6>
    80004882:	84aa                	mv	s1,a0
    80004884:	89ae                	mv	s3,a1
    80004886:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004888:	411c                	lw	a5,0(a0)
    8000488a:	4705                	li	a4,1
    8000488c:	04e78963          	beq	a5,a4,800048de <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004890:	470d                	li	a4,3
    80004892:	04e78d63          	beq	a5,a4,800048ec <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004896:	4709                	li	a4,2
    80004898:	06e79e63          	bne	a5,a4,80004914 <fileread+0xa6>
    ilock(f->ip);
    8000489c:	6d08                	ld	a0,24(a0)
    8000489e:	fffff097          	auipc	ra,0xfffff
    800048a2:	02c080e7          	jalr	44(ra) # 800038ca <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048a6:	874a                	mv	a4,s2
    800048a8:	5094                	lw	a3,32(s1)
    800048aa:	864e                	mv	a2,s3
    800048ac:	4585                	li	a1,1
    800048ae:	6c88                	ld	a0,24(s1)
    800048b0:	fffff097          	auipc	ra,0xfffff
    800048b4:	2ce080e7          	jalr	718(ra) # 80003b7e <readi>
    800048b8:	892a                	mv	s2,a0
    800048ba:	00a05563          	blez	a0,800048c4 <fileread+0x56>
      f->off += r;
    800048be:	509c                	lw	a5,32(s1)
    800048c0:	9fa9                	addw	a5,a5,a0
    800048c2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048c4:	6c88                	ld	a0,24(s1)
    800048c6:	fffff097          	auipc	ra,0xfffff
    800048ca:	0c6080e7          	jalr	198(ra) # 8000398c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048ce:	854a                	mv	a0,s2
    800048d0:	70a2                	ld	ra,40(sp)
    800048d2:	7402                	ld	s0,32(sp)
    800048d4:	64e2                	ld	s1,24(sp)
    800048d6:	6942                	ld	s2,16(sp)
    800048d8:	69a2                	ld	s3,8(sp)
    800048da:	6145                	add	sp,sp,48
    800048dc:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048de:	6908                	ld	a0,16(a0)
    800048e0:	00000097          	auipc	ra,0x0
    800048e4:	3ee080e7          	jalr	1006(ra) # 80004cce <piperead>
    800048e8:	892a                	mv	s2,a0
    800048ea:	b7d5                	j	800048ce <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048ec:	02451783          	lh	a5,36(a0)
    800048f0:	03079693          	sll	a3,a5,0x30
    800048f4:	92c1                	srl	a3,a3,0x30
    800048f6:	4725                	li	a4,9
    800048f8:	02d76863          	bltu	a4,a3,80004928 <fileread+0xba>
    800048fc:	0792                	sll	a5,a5,0x4
    800048fe:	0001d717          	auipc	a4,0x1d
    80004902:	2b270713          	add	a4,a4,690 # 80021bb0 <devsw>
    80004906:	97ba                	add	a5,a5,a4
    80004908:	639c                	ld	a5,0(a5)
    8000490a:	c38d                	beqz	a5,8000492c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000490c:	4505                	li	a0,1
    8000490e:	9782                	jalr	a5
    80004910:	892a                	mv	s2,a0
    80004912:	bf75                	j	800048ce <fileread+0x60>
    panic("fileread");
    80004914:	00004517          	auipc	a0,0x4
    80004918:	dd450513          	add	a0,a0,-556 # 800086e8 <syscalls+0x258>
    8000491c:	ffffc097          	auipc	ra,0xffffc
    80004920:	c26080e7          	jalr	-986(ra) # 80000542 <panic>
    return -1;
    80004924:	597d                	li	s2,-1
    80004926:	b765                	j	800048ce <fileread+0x60>
      return -1;
    80004928:	597d                	li	s2,-1
    8000492a:	b755                	j	800048ce <fileread+0x60>
    8000492c:	597d                	li	s2,-1
    8000492e:	b745                	j	800048ce <fileread+0x60>

0000000080004930 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004930:	00954783          	lbu	a5,9(a0)
    80004934:	14078363          	beqz	a5,80004a7a <filewrite+0x14a>
{
    80004938:	715d                	add	sp,sp,-80
    8000493a:	e486                	sd	ra,72(sp)
    8000493c:	e0a2                	sd	s0,64(sp)
    8000493e:	fc26                	sd	s1,56(sp)
    80004940:	f84a                	sd	s2,48(sp)
    80004942:	f44e                	sd	s3,40(sp)
    80004944:	f052                	sd	s4,32(sp)
    80004946:	ec56                	sd	s5,24(sp)
    80004948:	e85a                	sd	s6,16(sp)
    8000494a:	e45e                	sd	s7,8(sp)
    8000494c:	e062                	sd	s8,0(sp)
    8000494e:	0880                	add	s0,sp,80
    80004950:	892a                	mv	s2,a0
    80004952:	8b2e                	mv	s6,a1
    80004954:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004956:	411c                	lw	a5,0(a0)
    80004958:	4705                	li	a4,1
    8000495a:	02e78263          	beq	a5,a4,8000497e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000495e:	470d                	li	a4,3
    80004960:	02e78563          	beq	a5,a4,8000498a <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004964:	4709                	li	a4,2
    80004966:	10e79263          	bne	a5,a4,80004a6a <filewrite+0x13a>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000496a:	0ec05e63          	blez	a2,80004a66 <filewrite+0x136>
    int i = 0;
    8000496e:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004970:	6b85                	lui	s7,0x1
    80004972:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004976:	6c05                	lui	s8,0x1
    80004978:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    8000497c:	a851                	j	80004a10 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    8000497e:	6908                	ld	a0,16(a0)
    80004980:	00000097          	auipc	ra,0x0
    80004984:	254080e7          	jalr	596(ra) # 80004bd4 <pipewrite>
    80004988:	a85d                	j	80004a3e <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000498a:	02451783          	lh	a5,36(a0)
    8000498e:	03079693          	sll	a3,a5,0x30
    80004992:	92c1                	srl	a3,a3,0x30
    80004994:	4725                	li	a4,9
    80004996:	0ed76463          	bltu	a4,a3,80004a7e <filewrite+0x14e>
    8000499a:	0792                	sll	a5,a5,0x4
    8000499c:	0001d717          	auipc	a4,0x1d
    800049a0:	21470713          	add	a4,a4,532 # 80021bb0 <devsw>
    800049a4:	97ba                	add	a5,a5,a4
    800049a6:	679c                	ld	a5,8(a5)
    800049a8:	cfe9                	beqz	a5,80004a82 <filewrite+0x152>
    ret = devsw[f->major].write(1, addr, n);
    800049aa:	4505                	li	a0,1
    800049ac:	9782                	jalr	a5
    800049ae:	a841                	j	80004a3e <filewrite+0x10e>
      if(n1 > max)
    800049b0:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    800049b4:	00000097          	auipc	ra,0x0
    800049b8:	8b6080e7          	jalr	-1866(ra) # 8000426a <begin_op>
      ilock(f->ip);
    800049bc:	01893503          	ld	a0,24(s2)
    800049c0:	fffff097          	auipc	ra,0xfffff
    800049c4:	f0a080e7          	jalr	-246(ra) # 800038ca <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049c8:	8756                	mv	a4,s5
    800049ca:	02092683          	lw	a3,32(s2)
    800049ce:	01698633          	add	a2,s3,s6
    800049d2:	4585                	li	a1,1
    800049d4:	01893503          	ld	a0,24(s2)
    800049d8:	fffff097          	auipc	ra,0xfffff
    800049dc:	29c080e7          	jalr	668(ra) # 80003c74 <writei>
    800049e0:	84aa                	mv	s1,a0
    800049e2:	02a05f63          	blez	a0,80004a20 <filewrite+0xf0>
        f->off += r;
    800049e6:	02092783          	lw	a5,32(s2)
    800049ea:	9fa9                	addw	a5,a5,a0
    800049ec:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049f0:	01893503          	ld	a0,24(s2)
    800049f4:	fffff097          	auipc	ra,0xfffff
    800049f8:	f98080e7          	jalr	-104(ra) # 8000398c <iunlock>
      end_op();
    800049fc:	00000097          	auipc	ra,0x0
    80004a00:	8e8080e7          	jalr	-1816(ra) # 800042e4 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004a04:	049a9963          	bne	s5,s1,80004a56 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004a08:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a0c:	0349d663          	bge	s3,s4,80004a38 <filewrite+0x108>
      int n1 = n - i;
    80004a10:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004a14:	0004879b          	sext.w	a5,s1
    80004a18:	f8fbdce3          	bge	s7,a5,800049b0 <filewrite+0x80>
    80004a1c:	84e2                	mv	s1,s8
    80004a1e:	bf49                	j	800049b0 <filewrite+0x80>
      iunlock(f->ip);
    80004a20:	01893503          	ld	a0,24(s2)
    80004a24:	fffff097          	auipc	ra,0xfffff
    80004a28:	f68080e7          	jalr	-152(ra) # 8000398c <iunlock>
      end_op();
    80004a2c:	00000097          	auipc	ra,0x0
    80004a30:	8b8080e7          	jalr	-1864(ra) # 800042e4 <end_op>
      if(r < 0)
    80004a34:	fc04d8e3          	bgez	s1,80004a04 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004a38:	053a1763          	bne	s4,s3,80004a86 <filewrite+0x156>
    80004a3c:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a3e:	60a6                	ld	ra,72(sp)
    80004a40:	6406                	ld	s0,64(sp)
    80004a42:	74e2                	ld	s1,56(sp)
    80004a44:	7942                	ld	s2,48(sp)
    80004a46:	79a2                	ld	s3,40(sp)
    80004a48:	7a02                	ld	s4,32(sp)
    80004a4a:	6ae2                	ld	s5,24(sp)
    80004a4c:	6b42                	ld	s6,16(sp)
    80004a4e:	6ba2                	ld	s7,8(sp)
    80004a50:	6c02                	ld	s8,0(sp)
    80004a52:	6161                	add	sp,sp,80
    80004a54:	8082                	ret
        panic("short filewrite");
    80004a56:	00004517          	auipc	a0,0x4
    80004a5a:	ca250513          	add	a0,a0,-862 # 800086f8 <syscalls+0x268>
    80004a5e:	ffffc097          	auipc	ra,0xffffc
    80004a62:	ae4080e7          	jalr	-1308(ra) # 80000542 <panic>
    int i = 0;
    80004a66:	4981                	li	s3,0
    80004a68:	bfc1                	j	80004a38 <filewrite+0x108>
    panic("filewrite");
    80004a6a:	00004517          	auipc	a0,0x4
    80004a6e:	c9e50513          	add	a0,a0,-866 # 80008708 <syscalls+0x278>
    80004a72:	ffffc097          	auipc	ra,0xffffc
    80004a76:	ad0080e7          	jalr	-1328(ra) # 80000542 <panic>
    return -1;
    80004a7a:	557d                	li	a0,-1
}
    80004a7c:	8082                	ret
      return -1;
    80004a7e:	557d                	li	a0,-1
    80004a80:	bf7d                	j	80004a3e <filewrite+0x10e>
    80004a82:	557d                	li	a0,-1
    80004a84:	bf6d                	j	80004a3e <filewrite+0x10e>
    ret = (i == n ? n : -1);
    80004a86:	557d                	li	a0,-1
    80004a88:	bf5d                	j	80004a3e <filewrite+0x10e>

0000000080004a8a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a8a:	7179                	add	sp,sp,-48
    80004a8c:	f406                	sd	ra,40(sp)
    80004a8e:	f022                	sd	s0,32(sp)
    80004a90:	ec26                	sd	s1,24(sp)
    80004a92:	e84a                	sd	s2,16(sp)
    80004a94:	e44e                	sd	s3,8(sp)
    80004a96:	e052                	sd	s4,0(sp)
    80004a98:	1800                	add	s0,sp,48
    80004a9a:	84aa                	mv	s1,a0
    80004a9c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a9e:	0005b023          	sd	zero,0(a1)
    80004aa2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004aa6:	00000097          	auipc	ra,0x0
    80004aaa:	bd2080e7          	jalr	-1070(ra) # 80004678 <filealloc>
    80004aae:	e088                	sd	a0,0(s1)
    80004ab0:	c551                	beqz	a0,80004b3c <pipealloc+0xb2>
    80004ab2:	00000097          	auipc	ra,0x0
    80004ab6:	bc6080e7          	jalr	-1082(ra) # 80004678 <filealloc>
    80004aba:	00aa3023          	sd	a0,0(s4)
    80004abe:	c92d                	beqz	a0,80004b30 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ac0:	ffffc097          	auipc	ra,0xffffc
    80004ac4:	04c080e7          	jalr	76(ra) # 80000b0c <kalloc>
    80004ac8:	892a                	mv	s2,a0
    80004aca:	c125                	beqz	a0,80004b2a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004acc:	4985                	li	s3,1
    80004ace:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ad2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ad6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ada:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ade:	00004597          	auipc	a1,0x4
    80004ae2:	c3a58593          	add	a1,a1,-966 # 80008718 <syscalls+0x288>
    80004ae6:	ffffc097          	auipc	ra,0xffffc
    80004aea:	086080e7          	jalr	134(ra) # 80000b6c <initlock>
  (*f0)->type = FD_PIPE;
    80004aee:	609c                	ld	a5,0(s1)
    80004af0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004af4:	609c                	ld	a5,0(s1)
    80004af6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004afa:	609c                	ld	a5,0(s1)
    80004afc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b00:	609c                	ld	a5,0(s1)
    80004b02:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b06:	000a3783          	ld	a5,0(s4)
    80004b0a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b0e:	000a3783          	ld	a5,0(s4)
    80004b12:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b16:	000a3783          	ld	a5,0(s4)
    80004b1a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b1e:	000a3783          	ld	a5,0(s4)
    80004b22:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b26:	4501                	li	a0,0
    80004b28:	a025                	j	80004b50 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b2a:	6088                	ld	a0,0(s1)
    80004b2c:	e501                	bnez	a0,80004b34 <pipealloc+0xaa>
    80004b2e:	a039                	j	80004b3c <pipealloc+0xb2>
    80004b30:	6088                	ld	a0,0(s1)
    80004b32:	c51d                	beqz	a0,80004b60 <pipealloc+0xd6>
    fileclose(*f0);
    80004b34:	00000097          	auipc	ra,0x0
    80004b38:	c00080e7          	jalr	-1024(ra) # 80004734 <fileclose>
  if(*f1)
    80004b3c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b40:	557d                	li	a0,-1
  if(*f1)
    80004b42:	c799                	beqz	a5,80004b50 <pipealloc+0xc6>
    fileclose(*f1);
    80004b44:	853e                	mv	a0,a5
    80004b46:	00000097          	auipc	ra,0x0
    80004b4a:	bee080e7          	jalr	-1042(ra) # 80004734 <fileclose>
  return -1;
    80004b4e:	557d                	li	a0,-1
}
    80004b50:	70a2                	ld	ra,40(sp)
    80004b52:	7402                	ld	s0,32(sp)
    80004b54:	64e2                	ld	s1,24(sp)
    80004b56:	6942                	ld	s2,16(sp)
    80004b58:	69a2                	ld	s3,8(sp)
    80004b5a:	6a02                	ld	s4,0(sp)
    80004b5c:	6145                	add	sp,sp,48
    80004b5e:	8082                	ret
  return -1;
    80004b60:	557d                	li	a0,-1
    80004b62:	b7fd                	j	80004b50 <pipealloc+0xc6>

0000000080004b64 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b64:	1101                	add	sp,sp,-32
    80004b66:	ec06                	sd	ra,24(sp)
    80004b68:	e822                	sd	s0,16(sp)
    80004b6a:	e426                	sd	s1,8(sp)
    80004b6c:	e04a                	sd	s2,0(sp)
    80004b6e:	1000                	add	s0,sp,32
    80004b70:	84aa                	mv	s1,a0
    80004b72:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b74:	ffffc097          	auipc	ra,0xffffc
    80004b78:	088080e7          	jalr	136(ra) # 80000bfc <acquire>
  if(writable){
    80004b7c:	02090d63          	beqz	s2,80004bb6 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b80:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b84:	21848513          	add	a0,s1,536
    80004b88:	ffffe097          	auipc	ra,0xffffe
    80004b8c:	aac080e7          	jalr	-1364(ra) # 80002634 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b90:	2204b783          	ld	a5,544(s1)
    80004b94:	eb95                	bnez	a5,80004bc8 <pipeclose+0x64>
    release(&pi->lock);
    80004b96:	8526                	mv	a0,s1
    80004b98:	ffffc097          	auipc	ra,0xffffc
    80004b9c:	118080e7          	jalr	280(ra) # 80000cb0 <release>
    kfree((char*)pi);
    80004ba0:	8526                	mv	a0,s1
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	e6c080e7          	jalr	-404(ra) # 80000a0e <kfree>
  } else
    release(&pi->lock);
}
    80004baa:	60e2                	ld	ra,24(sp)
    80004bac:	6442                	ld	s0,16(sp)
    80004bae:	64a2                	ld	s1,8(sp)
    80004bb0:	6902                	ld	s2,0(sp)
    80004bb2:	6105                	add	sp,sp,32
    80004bb4:	8082                	ret
    pi->readopen = 0;
    80004bb6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bba:	21c48513          	add	a0,s1,540
    80004bbe:	ffffe097          	auipc	ra,0xffffe
    80004bc2:	a76080e7          	jalr	-1418(ra) # 80002634 <wakeup>
    80004bc6:	b7e9                	j	80004b90 <pipeclose+0x2c>
    release(&pi->lock);
    80004bc8:	8526                	mv	a0,s1
    80004bca:	ffffc097          	auipc	ra,0xffffc
    80004bce:	0e6080e7          	jalr	230(ra) # 80000cb0 <release>
}
    80004bd2:	bfe1                	j	80004baa <pipeclose+0x46>

0000000080004bd4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bd4:	711d                	add	sp,sp,-96
    80004bd6:	ec86                	sd	ra,88(sp)
    80004bd8:	e8a2                	sd	s0,80(sp)
    80004bda:	e4a6                	sd	s1,72(sp)
    80004bdc:	e0ca                	sd	s2,64(sp)
    80004bde:	fc4e                	sd	s3,56(sp)
    80004be0:	f852                	sd	s4,48(sp)
    80004be2:	f456                	sd	s5,40(sp)
    80004be4:	f05a                	sd	s6,32(sp)
    80004be6:	ec5e                	sd	s7,24(sp)
    80004be8:	1080                	add	s0,sp,96
    80004bea:	84aa                	mv	s1,a0
    80004bec:	8b2e                	mv	s6,a1
    80004bee:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004bf0:	ffffd097          	auipc	ra,0xffffd
    80004bf4:	e48080e7          	jalr	-440(ra) # 80001a38 <myproc>
    80004bf8:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004bfa:	8526                	mv	a0,s1
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	000080e7          	jalr	ra # 80000bfc <acquire>
  for(i = 0; i < n; i++){
    80004c04:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004c06:	21848a13          	add	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c0a:	21c48993          	add	s3,s1,540
  for(i = 0; i < n; i++){
    80004c0e:	09505263          	blez	s5,80004c92 <pipewrite+0xbe>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c12:	2184a783          	lw	a5,536(s1)
    80004c16:	21c4a703          	lw	a4,540(s1)
    80004c1a:	2007879b          	addw	a5,a5,512
    80004c1e:	02f71b63          	bne	a4,a5,80004c54 <pipewrite+0x80>
      if(pi->readopen == 0 || pr->killed){
    80004c22:	2204a783          	lw	a5,544(s1)
    80004c26:	c3d1                	beqz	a5,80004caa <pipewrite+0xd6>
    80004c28:	03092783          	lw	a5,48(s2)
    80004c2c:	efbd                	bnez	a5,80004caa <pipewrite+0xd6>
      wakeup(&pi->nread);
    80004c2e:	8552                	mv	a0,s4
    80004c30:	ffffe097          	auipc	ra,0xffffe
    80004c34:	a04080e7          	jalr	-1532(ra) # 80002634 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c38:	85a6                	mv	a1,s1
    80004c3a:	854e                	mv	a0,s3
    80004c3c:	ffffe097          	auipc	ra,0xffffe
    80004c40:	878080e7          	jalr	-1928(ra) # 800024b4 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c44:	2184a783          	lw	a5,536(s1)
    80004c48:	21c4a703          	lw	a4,540(s1)
    80004c4c:	2007879b          	addw	a5,a5,512
    80004c50:	fcf709e3          	beq	a4,a5,80004c22 <pipewrite+0x4e>
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c54:	4685                	li	a3,1
    80004c56:	865a                	mv	a2,s6
    80004c58:	faf40593          	add	a1,s0,-81
    80004c5c:	05093503          	ld	a0,80(s2)
    80004c60:	ffffd097          	auipc	ra,0xffffd
    80004c64:	cd0080e7          	jalr	-816(ra) # 80001930 <copyin>
    80004c68:	57fd                	li	a5,-1
    80004c6a:	02f50463          	beq	a0,a5,80004c92 <pipewrite+0xbe>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c6e:	21c4a783          	lw	a5,540(s1)
    80004c72:	0017871b          	addw	a4,a5,1
    80004c76:	20e4ae23          	sw	a4,540(s1)
    80004c7a:	1ff7f793          	and	a5,a5,511
    80004c7e:	97a6                	add	a5,a5,s1
    80004c80:	faf44703          	lbu	a4,-81(s0)
    80004c84:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004c88:	2b85                	addw	s7,s7,1
    80004c8a:	0b05                	add	s6,s6,1
    80004c8c:	f97a93e3          	bne	s5,s7,80004c12 <pipewrite+0x3e>
    80004c90:	8bd6                	mv	s7,s5
  }
  wakeup(&pi->nread);
    80004c92:	21848513          	add	a0,s1,536
    80004c96:	ffffe097          	auipc	ra,0xffffe
    80004c9a:	99e080e7          	jalr	-1634(ra) # 80002634 <wakeup>
  release(&pi->lock);
    80004c9e:	8526                	mv	a0,s1
    80004ca0:	ffffc097          	auipc	ra,0xffffc
    80004ca4:	010080e7          	jalr	16(ra) # 80000cb0 <release>
  return i;
    80004ca8:	a039                	j	80004cb6 <pipewrite+0xe2>
        release(&pi->lock);
    80004caa:	8526                	mv	a0,s1
    80004cac:	ffffc097          	auipc	ra,0xffffc
    80004cb0:	004080e7          	jalr	4(ra) # 80000cb0 <release>
        return -1;
    80004cb4:	5bfd                	li	s7,-1
}
    80004cb6:	855e                	mv	a0,s7
    80004cb8:	60e6                	ld	ra,88(sp)
    80004cba:	6446                	ld	s0,80(sp)
    80004cbc:	64a6                	ld	s1,72(sp)
    80004cbe:	6906                	ld	s2,64(sp)
    80004cc0:	79e2                	ld	s3,56(sp)
    80004cc2:	7a42                	ld	s4,48(sp)
    80004cc4:	7aa2                	ld	s5,40(sp)
    80004cc6:	7b02                	ld	s6,32(sp)
    80004cc8:	6be2                	ld	s7,24(sp)
    80004cca:	6125                	add	sp,sp,96
    80004ccc:	8082                	ret

0000000080004cce <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cce:	715d                	add	sp,sp,-80
    80004cd0:	e486                	sd	ra,72(sp)
    80004cd2:	e0a2                	sd	s0,64(sp)
    80004cd4:	fc26                	sd	s1,56(sp)
    80004cd6:	f84a                	sd	s2,48(sp)
    80004cd8:	f44e                	sd	s3,40(sp)
    80004cda:	f052                	sd	s4,32(sp)
    80004cdc:	ec56                	sd	s5,24(sp)
    80004cde:	e85a                	sd	s6,16(sp)
    80004ce0:	0880                	add	s0,sp,80
    80004ce2:	84aa                	mv	s1,a0
    80004ce4:	892e                	mv	s2,a1
    80004ce6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ce8:	ffffd097          	auipc	ra,0xffffd
    80004cec:	d50080e7          	jalr	-688(ra) # 80001a38 <myproc>
    80004cf0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cf2:	8526                	mv	a0,s1
    80004cf4:	ffffc097          	auipc	ra,0xffffc
    80004cf8:	f08080e7          	jalr	-248(ra) # 80000bfc <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cfc:	2184a703          	lw	a4,536(s1)
    80004d00:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d04:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d08:	02f71463          	bne	a4,a5,80004d30 <piperead+0x62>
    80004d0c:	2244a783          	lw	a5,548(s1)
    80004d10:	c385                	beqz	a5,80004d30 <piperead+0x62>
    if(pr->killed){
    80004d12:	030a2783          	lw	a5,48(s4)
    80004d16:	ebc9                	bnez	a5,80004da8 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d18:	85a6                	mv	a1,s1
    80004d1a:	854e                	mv	a0,s3
    80004d1c:	ffffd097          	auipc	ra,0xffffd
    80004d20:	798080e7          	jalr	1944(ra) # 800024b4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d24:	2184a703          	lw	a4,536(s1)
    80004d28:	21c4a783          	lw	a5,540(s1)
    80004d2c:	fef700e3          	beq	a4,a5,80004d0c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d30:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d32:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d34:	05505463          	blez	s5,80004d7c <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004d38:	2184a783          	lw	a5,536(s1)
    80004d3c:	21c4a703          	lw	a4,540(s1)
    80004d40:	02f70e63          	beq	a4,a5,80004d7c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d44:	0017871b          	addw	a4,a5,1
    80004d48:	20e4ac23          	sw	a4,536(s1)
    80004d4c:	1ff7f793          	and	a5,a5,511
    80004d50:	97a6                	add	a5,a5,s1
    80004d52:	0187c783          	lbu	a5,24(a5)
    80004d56:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d5a:	4685                	li	a3,1
    80004d5c:	fbf40613          	add	a2,s0,-65
    80004d60:	85ca                	mv	a1,s2
    80004d62:	050a3503          	ld	a0,80(s4)
    80004d66:	ffffd097          	auipc	ra,0xffffd
    80004d6a:	b3e080e7          	jalr	-1218(ra) # 800018a4 <copyout>
    80004d6e:	01650763          	beq	a0,s6,80004d7c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d72:	2985                	addw	s3,s3,1
    80004d74:	0905                	add	s2,s2,1
    80004d76:	fd3a91e3          	bne	s5,s3,80004d38 <piperead+0x6a>
    80004d7a:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d7c:	21c48513          	add	a0,s1,540
    80004d80:	ffffe097          	auipc	ra,0xffffe
    80004d84:	8b4080e7          	jalr	-1868(ra) # 80002634 <wakeup>
  release(&pi->lock);
    80004d88:	8526                	mv	a0,s1
    80004d8a:	ffffc097          	auipc	ra,0xffffc
    80004d8e:	f26080e7          	jalr	-218(ra) # 80000cb0 <release>
  return i;
}
    80004d92:	854e                	mv	a0,s3
    80004d94:	60a6                	ld	ra,72(sp)
    80004d96:	6406                	ld	s0,64(sp)
    80004d98:	74e2                	ld	s1,56(sp)
    80004d9a:	7942                	ld	s2,48(sp)
    80004d9c:	79a2                	ld	s3,40(sp)
    80004d9e:	7a02                	ld	s4,32(sp)
    80004da0:	6ae2                	ld	s5,24(sp)
    80004da2:	6b42                	ld	s6,16(sp)
    80004da4:	6161                	add	sp,sp,80
    80004da6:	8082                	ret
      release(&pi->lock);
    80004da8:	8526                	mv	a0,s1
    80004daa:	ffffc097          	auipc	ra,0xffffc
    80004dae:	f06080e7          	jalr	-250(ra) # 80000cb0 <release>
      return -1;
    80004db2:	59fd                	li	s3,-1
    80004db4:	bff9                	j	80004d92 <piperead+0xc4>

0000000080004db6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004db6:	df010113          	add	sp,sp,-528
    80004dba:	20113423          	sd	ra,520(sp)
    80004dbe:	20813023          	sd	s0,512(sp)
    80004dc2:	ffa6                	sd	s1,504(sp)
    80004dc4:	fbca                	sd	s2,496(sp)
    80004dc6:	f7ce                	sd	s3,488(sp)
    80004dc8:	f3d2                	sd	s4,480(sp)
    80004dca:	efd6                	sd	s5,472(sp)
    80004dcc:	ebda                	sd	s6,464(sp)
    80004dce:	e7de                	sd	s7,456(sp)
    80004dd0:	e3e2                	sd	s8,448(sp)
    80004dd2:	ff66                	sd	s9,440(sp)
    80004dd4:	fb6a                	sd	s10,432(sp)
    80004dd6:	f76e                	sd	s11,424(sp)
    80004dd8:	0c00                	add	s0,sp,528
    80004dda:	892a                	mv	s2,a0
    80004ddc:	dea43c23          	sd	a0,-520(s0)
    80004de0:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004de4:	ffffd097          	auipc	ra,0xffffd
    80004de8:	c54080e7          	jalr	-940(ra) # 80001a38 <myproc>
    80004dec:	84aa                	mv	s1,a0

  begin_op();
    80004dee:	fffff097          	auipc	ra,0xfffff
    80004df2:	47c080e7          	jalr	1148(ra) # 8000426a <begin_op>

  if((ip = namei(path)) == 0){
    80004df6:	854a                	mv	a0,s2
    80004df8:	fffff097          	auipc	ra,0xfffff
    80004dfc:	282080e7          	jalr	642(ra) # 8000407a <namei>
    80004e00:	c92d                	beqz	a0,80004e72 <exec+0xbc>
    80004e02:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e04:	fffff097          	auipc	ra,0xfffff
    80004e08:	ac6080e7          	jalr	-1338(ra) # 800038ca <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e0c:	04000713          	li	a4,64
    80004e10:	4681                	li	a3,0
    80004e12:	e4840613          	add	a2,s0,-440
    80004e16:	4581                	li	a1,0
    80004e18:	8552                	mv	a0,s4
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	d64080e7          	jalr	-668(ra) # 80003b7e <readi>
    80004e22:	04000793          	li	a5,64
    80004e26:	00f51a63          	bne	a0,a5,80004e3a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e2a:	e4842703          	lw	a4,-440(s0)
    80004e2e:	464c47b7          	lui	a5,0x464c4
    80004e32:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e36:	04f70463          	beq	a4,a5,80004e7e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e3a:	8552                	mv	a0,s4
    80004e3c:	fffff097          	auipc	ra,0xfffff
    80004e40:	cf0080e7          	jalr	-784(ra) # 80003b2c <iunlockput>
    end_op();
    80004e44:	fffff097          	auipc	ra,0xfffff
    80004e48:	4a0080e7          	jalr	1184(ra) # 800042e4 <end_op>
  }
  return -1;
    80004e4c:	557d                	li	a0,-1
}
    80004e4e:	20813083          	ld	ra,520(sp)
    80004e52:	20013403          	ld	s0,512(sp)
    80004e56:	74fe                	ld	s1,504(sp)
    80004e58:	795e                	ld	s2,496(sp)
    80004e5a:	79be                	ld	s3,488(sp)
    80004e5c:	7a1e                	ld	s4,480(sp)
    80004e5e:	6afe                	ld	s5,472(sp)
    80004e60:	6b5e                	ld	s6,464(sp)
    80004e62:	6bbe                	ld	s7,456(sp)
    80004e64:	6c1e                	ld	s8,448(sp)
    80004e66:	7cfa                	ld	s9,440(sp)
    80004e68:	7d5a                	ld	s10,432(sp)
    80004e6a:	7dba                	ld	s11,424(sp)
    80004e6c:	21010113          	add	sp,sp,528
    80004e70:	8082                	ret
    end_op();
    80004e72:	fffff097          	auipc	ra,0xfffff
    80004e76:	472080e7          	jalr	1138(ra) # 800042e4 <end_op>
    return -1;
    80004e7a:	557d                	li	a0,-1
    80004e7c:	bfc9                	j	80004e4e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e7e:	8526                	mv	a0,s1
    80004e80:	ffffd097          	auipc	ra,0xffffd
    80004e84:	c7c080e7          	jalr	-900(ra) # 80001afc <proc_pagetable>
    80004e88:	8b2a                	mv	s6,a0
    80004e8a:	d945                	beqz	a0,80004e3a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e8c:	e6842d03          	lw	s10,-408(s0)
    80004e90:	e8045783          	lhu	a5,-384(s0)
    80004e94:	cfe5                	beqz	a5,80004f8c <exec+0x1d6>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e96:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e98:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004e9a:	6c85                	lui	s9,0x1
    80004e9c:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004ea0:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004ea4:	6a85                	lui	s5,0x1
    80004ea6:	a0b5                	j	80004f12 <exec+0x15c>
      panic("loadseg: address should exist");
    80004ea8:	00004517          	auipc	a0,0x4
    80004eac:	87850513          	add	a0,a0,-1928 # 80008720 <syscalls+0x290>
    80004eb0:	ffffb097          	auipc	ra,0xffffb
    80004eb4:	692080e7          	jalr	1682(ra) # 80000542 <panic>
    if(sz - i < PGSIZE)
    80004eb8:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004eba:	8726                	mv	a4,s1
    80004ebc:	012c06bb          	addw	a3,s8,s2
    80004ec0:	4581                	li	a1,0
    80004ec2:	8552                	mv	a0,s4
    80004ec4:	fffff097          	auipc	ra,0xfffff
    80004ec8:	cba080e7          	jalr	-838(ra) # 80003b7e <readi>
    80004ecc:	2501                	sext.w	a0,a0
    80004ece:	28a49663          	bne	s1,a0,8000515a <exec+0x3a4>
  for(i = 0; i < sz; i += PGSIZE){
    80004ed2:	012a893b          	addw	s2,s5,s2
    80004ed6:	03397563          	bgeu	s2,s3,80004f00 <exec+0x14a>
    pa = walkaddr(pagetable, va + i);
    80004eda:	02091593          	sll	a1,s2,0x20
    80004ede:	9181                	srl	a1,a1,0x20
    80004ee0:	95de                	add	a1,a1,s7
    80004ee2:	855a                	mv	a0,s6
    80004ee4:	ffffc097          	auipc	ra,0xffffc
    80004ee8:	29e080e7          	jalr	670(ra) # 80001182 <walkaddr>
    80004eec:	862a                	mv	a2,a0
    if(pa == 0)
    80004eee:	dd4d                	beqz	a0,80004ea8 <exec+0xf2>
    if(sz - i < PGSIZE)
    80004ef0:	412984bb          	subw	s1,s3,s2
    80004ef4:	0004879b          	sext.w	a5,s1
    80004ef8:	fcfcf0e3          	bgeu	s9,a5,80004eb8 <exec+0x102>
    80004efc:	84d6                	mv	s1,s5
    80004efe:	bf6d                	j	80004eb8 <exec+0x102>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f00:	e0843483          	ld	s1,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f04:	2d85                	addw	s11,s11,1
    80004f06:	038d0d1b          	addw	s10,s10,56
    80004f0a:	e8045783          	lhu	a5,-384(s0)
    80004f0e:	08fdd063          	bge	s11,a5,80004f8e <exec+0x1d8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f12:	2d01                	sext.w	s10,s10
    80004f14:	03800713          	li	a4,56
    80004f18:	86ea                	mv	a3,s10
    80004f1a:	e1040613          	add	a2,s0,-496
    80004f1e:	4581                	li	a1,0
    80004f20:	8552                	mv	a0,s4
    80004f22:	fffff097          	auipc	ra,0xfffff
    80004f26:	c5c080e7          	jalr	-932(ra) # 80003b7e <readi>
    80004f2a:	03800793          	li	a5,56
    80004f2e:	22f51463          	bne	a0,a5,80005156 <exec+0x3a0>
    if(ph.type != ELF_PROG_LOAD)
    80004f32:	e1042783          	lw	a5,-496(s0)
    80004f36:	4705                	li	a4,1
    80004f38:	fce796e3          	bne	a5,a4,80004f04 <exec+0x14e>
    if(ph.memsz < ph.filesz)
    80004f3c:	e3843603          	ld	a2,-456(s0)
    80004f40:	e3043783          	ld	a5,-464(s0)
    80004f44:	22f66663          	bltu	a2,a5,80005170 <exec+0x3ba>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f48:	e2043783          	ld	a5,-480(s0)
    80004f4c:	963e                	add	a2,a2,a5
    80004f4e:	22f66463          	bltu	a2,a5,80005176 <exec+0x3c0>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f52:	85a6                	mv	a1,s1
    80004f54:	855a                	mv	a0,s6
    80004f56:	ffffc097          	auipc	ra,0xffffc
    80004f5a:	6fa080e7          	jalr	1786(ra) # 80001650 <uvmalloc>
    80004f5e:	e0a43423          	sd	a0,-504(s0)
    80004f62:	20050d63          	beqz	a0,8000517c <exec+0x3c6>
    if(ph.vaddr % PGSIZE != 0)
    80004f66:	e2043b83          	ld	s7,-480(s0)
    80004f6a:	df043783          	ld	a5,-528(s0)
    80004f6e:	00fbf7b3          	and	a5,s7,a5
    80004f72:	1e079463          	bnez	a5,8000515a <exec+0x3a4>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f76:	e1842c03          	lw	s8,-488(s0)
    80004f7a:	e3042983          	lw	s3,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f7e:	00098463          	beqz	s3,80004f86 <exec+0x1d0>
    80004f82:	4901                	li	s2,0
    80004f84:	bf99                	j	80004eda <exec+0x124>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f86:	e0843483          	ld	s1,-504(s0)
    80004f8a:	bfad                	j	80004f04 <exec+0x14e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f8c:	4481                	li	s1,0
  iunlockput(ip);
    80004f8e:	8552                	mv	a0,s4
    80004f90:	fffff097          	auipc	ra,0xfffff
    80004f94:	b9c080e7          	jalr	-1124(ra) # 80003b2c <iunlockput>
  end_op();
    80004f98:	fffff097          	auipc	ra,0xfffff
    80004f9c:	34c080e7          	jalr	844(ra) # 800042e4 <end_op>
  p = myproc();
    80004fa0:	ffffd097          	auipc	ra,0xffffd
    80004fa4:	a98080e7          	jalr	-1384(ra) # 80001a38 <myproc>
    80004fa8:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004faa:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004fae:	6985                	lui	s3,0x1
    80004fb0:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004fb2:	99a6                	add	s3,s3,s1
    80004fb4:	77fd                	lui	a5,0xfffff
    80004fb6:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fba:	6609                	lui	a2,0x2
    80004fbc:	964e                	add	a2,a2,s3
    80004fbe:	85ce                	mv	a1,s3
    80004fc0:	855a                	mv	a0,s6
    80004fc2:	ffffc097          	auipc	ra,0xffffc
    80004fc6:	68e080e7          	jalr	1678(ra) # 80001650 <uvmalloc>
    80004fca:	892a                	mv	s2,a0
    80004fcc:	e0a43423          	sd	a0,-504(s0)
    80004fd0:	e509                	bnez	a0,80004fda <exec+0x224>
  if(pagetable)
    80004fd2:	e1343423          	sd	s3,-504(s0)
    80004fd6:	4a01                	li	s4,0
    80004fd8:	a249                	j	8000515a <exec+0x3a4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fda:	75f9                	lui	a1,0xffffe
    80004fdc:	95aa                	add	a1,a1,a0
    80004fde:	855a                	mv	a0,s6
    80004fe0:	ffffd097          	auipc	ra,0xffffd
    80004fe4:	892080e7          	jalr	-1902(ra) # 80001872 <uvmclear>
  stackbase = sp - PGSIZE;
    80004fe8:	7bfd                	lui	s7,0xfffff
    80004fea:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004fec:	e0043783          	ld	a5,-512(s0)
    80004ff0:	6388                	ld	a0,0(a5)
    80004ff2:	c52d                	beqz	a0,8000505c <exec+0x2a6>
    80004ff4:	e8840993          	add	s3,s0,-376
    80004ff8:	f8840c13          	add	s8,s0,-120
    80004ffc:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004ffe:	ffffc097          	auipc	ra,0xffffc
    80005002:	e7c080e7          	jalr	-388(ra) # 80000e7a <strlen>
    80005006:	0015079b          	addw	a5,a0,1
    8000500a:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000500e:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    80005012:	17796863          	bltu	s2,s7,80005182 <exec+0x3cc>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005016:	e0043d03          	ld	s10,-512(s0)
    8000501a:	000d3a03          	ld	s4,0(s10)
    8000501e:	8552                	mv	a0,s4
    80005020:	ffffc097          	auipc	ra,0xffffc
    80005024:	e5a080e7          	jalr	-422(ra) # 80000e7a <strlen>
    80005028:	0015069b          	addw	a3,a0,1
    8000502c:	8652                	mv	a2,s4
    8000502e:	85ca                	mv	a1,s2
    80005030:	855a                	mv	a0,s6
    80005032:	ffffd097          	auipc	ra,0xffffd
    80005036:	872080e7          	jalr	-1934(ra) # 800018a4 <copyout>
    8000503a:	14054663          	bltz	a0,80005186 <exec+0x3d0>
    ustack[argc] = sp;
    8000503e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005042:	0485                	add	s1,s1,1
    80005044:	008d0793          	add	a5,s10,8
    80005048:	e0f43023          	sd	a5,-512(s0)
    8000504c:	008d3503          	ld	a0,8(s10)
    80005050:	c909                	beqz	a0,80005062 <exec+0x2ac>
    if(argc >= MAXARG)
    80005052:	09a1                	add	s3,s3,8
    80005054:	fb8995e3          	bne	s3,s8,80004ffe <exec+0x248>
  ip = 0;
    80005058:	4a01                	li	s4,0
    8000505a:	a201                	j	8000515a <exec+0x3a4>
  sp = sz;
    8000505c:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80005060:	4481                	li	s1,0
  ustack[argc] = 0;
    80005062:	00349793          	sll	a5,s1,0x3
    80005066:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffd7f70>
    8000506a:	97a2                	add	a5,a5,s0
    8000506c:	ee07bc23          	sd	zero,-264(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005070:	00148693          	add	a3,s1,1
    80005074:	068e                	sll	a3,a3,0x3
    80005076:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000507a:	ff097913          	and	s2,s2,-16
  sz = sz1;
    8000507e:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80005082:	f57968e3          	bltu	s2,s7,80004fd2 <exec+0x21c>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005086:	e8840613          	add	a2,s0,-376
    8000508a:	85ca                	mv	a1,s2
    8000508c:	855a                	mv	a0,s6
    8000508e:	ffffd097          	auipc	ra,0xffffd
    80005092:	816080e7          	jalr	-2026(ra) # 800018a4 <copyout>
    80005096:	0e054a63          	bltz	a0,8000518a <exec+0x3d4>
  p->trapframe->a1 = sp;
    8000509a:	060ab783          	ld	a5,96(s5) # 1060 <_entry-0x7fffefa0>
    8000509e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050a2:	df843783          	ld	a5,-520(s0)
    800050a6:	0007c703          	lbu	a4,0(a5)
    800050aa:	cf11                	beqz	a4,800050c6 <exec+0x310>
    800050ac:	0785                	add	a5,a5,1
    if(*s == '/')
    800050ae:	02f00693          	li	a3,47
    800050b2:	a039                	j	800050c0 <exec+0x30a>
      last = s+1;
    800050b4:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800050b8:	0785                	add	a5,a5,1
    800050ba:	fff7c703          	lbu	a4,-1(a5)
    800050be:	c701                	beqz	a4,800050c6 <exec+0x310>
    if(*s == '/')
    800050c0:	fed71ce3          	bne	a4,a3,800050b8 <exec+0x302>
    800050c4:	bfc5                	j	800050b4 <exec+0x2fe>
  safestrcpy(p->name, last, sizeof(p->name));
    800050c6:	4641                	li	a2,16
    800050c8:	df843583          	ld	a1,-520(s0)
    800050cc:	160a8513          	add	a0,s5,352
    800050d0:	ffffc097          	auipc	ra,0xffffc
    800050d4:	d78080e7          	jalr	-648(ra) # 80000e48 <safestrcpy>
  oldpagetable = p->pagetable;
    800050d8:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800050dc:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    800050e0:	e0843783          	ld	a5,-504(s0)
    800050e4:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050e8:	060ab783          	ld	a5,96(s5)
    800050ec:	e6043703          	ld	a4,-416(s0)
    800050f0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050f2:	060ab783          	ld	a5,96(s5)
    800050f6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050fa:	85e6                	mv	a1,s9
    800050fc:	ffffd097          	auipc	ra,0xffffd
    80005100:	a9c080e7          	jalr	-1380(ra) # 80001b98 <proc_freepagetable>
  uvmunmap(p->ukpagetable, 0, PGROUNDUP(oldsz)/PGSIZE, 0);
    80005104:	6785                	lui	a5,0x1
    80005106:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005108:	00fc8633          	add	a2,s9,a5
    8000510c:	4681                	li	a3,0
    8000510e:	8231                	srl	a2,a2,0xc
    80005110:	4581                	li	a1,0
    80005112:	058ab503          	ld	a0,88(s5)
    80005116:	ffffc097          	auipc	ra,0xffffc
    8000511a:	2dc080e7          	jalr	732(ra) # 800013f2 <uvmunmap>
  if(u2kvmcopy(p->pagetable, p->ukpagetable, 0, p->sz) < 0)
    8000511e:	048ab683          	ld	a3,72(s5)
    80005122:	4601                	li	a2,0
    80005124:	058ab583          	ld	a1,88(s5)
    80005128:	050ab503          	ld	a0,80(s5)
    8000512c:	ffffc097          	auipc	ra,0xffffc
    80005130:	38a080e7          	jalr	906(ra) # 800014b6 <u2kvmcopy>
    80005134:	04054e63          	bltz	a0,80005190 <exec+0x3da>
  if(p->pid==1) vmprint(p->pagetable);
    80005138:	038aa703          	lw	a4,56(s5)
    8000513c:	4785                	li	a5,1
    8000513e:	00f70563          	beq	a4,a5,80005148 <exec+0x392>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005142:	0004851b          	sext.w	a0,s1
    80005146:	b321                	j	80004e4e <exec+0x98>
  if(p->pid==1) vmprint(p->pagetable);
    80005148:	050ab503          	ld	a0,80(s5)
    8000514c:	ffffc097          	auipc	ra,0xffffc
    80005150:	f38080e7          	jalr	-200(ra) # 80001084 <vmprint>
    80005154:	b7fd                	j	80005142 <exec+0x38c>
    80005156:	e0943423          	sd	s1,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000515a:	e0843583          	ld	a1,-504(s0)
    8000515e:	855a                	mv	a0,s6
    80005160:	ffffd097          	auipc	ra,0xffffd
    80005164:	a38080e7          	jalr	-1480(ra) # 80001b98 <proc_freepagetable>
  return -1;
    80005168:	557d                	li	a0,-1
  if(ip){
    8000516a:	ce0a02e3          	beqz	s4,80004e4e <exec+0x98>
    8000516e:	b1f1                	j	80004e3a <exec+0x84>
    80005170:	e0943423          	sd	s1,-504(s0)
    80005174:	b7dd                	j	8000515a <exec+0x3a4>
    80005176:	e0943423          	sd	s1,-504(s0)
    8000517a:	b7c5                	j	8000515a <exec+0x3a4>
    8000517c:	e0943423          	sd	s1,-504(s0)
    80005180:	bfe9                	j	8000515a <exec+0x3a4>
  ip = 0;
    80005182:	4a01                	li	s4,0
    80005184:	bfd9                	j	8000515a <exec+0x3a4>
    80005186:	4a01                	li	s4,0
  if(pagetable)
    80005188:	bfc9                	j	8000515a <exec+0x3a4>
  sz = sz1;
    8000518a:	e0843983          	ld	s3,-504(s0)
    8000518e:	b591                	j	80004fd2 <exec+0x21c>
    80005190:	e0843983          	ld	s3,-504(s0)
    80005194:	bd3d                	j	80004fd2 <exec+0x21c>

0000000080005196 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005196:	7179                	add	sp,sp,-48
    80005198:	f406                	sd	ra,40(sp)
    8000519a:	f022                	sd	s0,32(sp)
    8000519c:	ec26                	sd	s1,24(sp)
    8000519e:	e84a                	sd	s2,16(sp)
    800051a0:	1800                	add	s0,sp,48
    800051a2:	892e                	mv	s2,a1
    800051a4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800051a6:	fdc40593          	add	a1,s0,-36
    800051aa:	ffffe097          	auipc	ra,0xffffe
    800051ae:	bb6080e7          	jalr	-1098(ra) # 80002d60 <argint>
    800051b2:	04054063          	bltz	a0,800051f2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051b6:	fdc42703          	lw	a4,-36(s0)
    800051ba:	47bd                	li	a5,15
    800051bc:	02e7ed63          	bltu	a5,a4,800051f6 <argfd+0x60>
    800051c0:	ffffd097          	auipc	ra,0xffffd
    800051c4:	878080e7          	jalr	-1928(ra) # 80001a38 <myproc>
    800051c8:	fdc42703          	lw	a4,-36(s0)
    800051cc:	01a70793          	add	a5,a4,26
    800051d0:	078e                	sll	a5,a5,0x3
    800051d2:	953e                	add	a0,a0,a5
    800051d4:	651c                	ld	a5,8(a0)
    800051d6:	c395                	beqz	a5,800051fa <argfd+0x64>
    return -1;
  if(pfd)
    800051d8:	00090463          	beqz	s2,800051e0 <argfd+0x4a>
    *pfd = fd;
    800051dc:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051e0:	4501                	li	a0,0
  if(pf)
    800051e2:	c091                	beqz	s1,800051e6 <argfd+0x50>
    *pf = f;
    800051e4:	e09c                	sd	a5,0(s1)
}
    800051e6:	70a2                	ld	ra,40(sp)
    800051e8:	7402                	ld	s0,32(sp)
    800051ea:	64e2                	ld	s1,24(sp)
    800051ec:	6942                	ld	s2,16(sp)
    800051ee:	6145                	add	sp,sp,48
    800051f0:	8082                	ret
    return -1;
    800051f2:	557d                	li	a0,-1
    800051f4:	bfcd                	j	800051e6 <argfd+0x50>
    return -1;
    800051f6:	557d                	li	a0,-1
    800051f8:	b7fd                	j	800051e6 <argfd+0x50>
    800051fa:	557d                	li	a0,-1
    800051fc:	b7ed                	j	800051e6 <argfd+0x50>

00000000800051fe <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051fe:	1101                	add	sp,sp,-32
    80005200:	ec06                	sd	ra,24(sp)
    80005202:	e822                	sd	s0,16(sp)
    80005204:	e426                	sd	s1,8(sp)
    80005206:	1000                	add	s0,sp,32
    80005208:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000520a:	ffffd097          	auipc	ra,0xffffd
    8000520e:	82e080e7          	jalr	-2002(ra) # 80001a38 <myproc>
    80005212:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005214:	0d850793          	add	a5,a0,216
    80005218:	4501                	li	a0,0
    8000521a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000521c:	6398                	ld	a4,0(a5)
    8000521e:	cb19                	beqz	a4,80005234 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005220:	2505                	addw	a0,a0,1
    80005222:	07a1                	add	a5,a5,8
    80005224:	fed51ce3          	bne	a0,a3,8000521c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005228:	557d                	li	a0,-1
}
    8000522a:	60e2                	ld	ra,24(sp)
    8000522c:	6442                	ld	s0,16(sp)
    8000522e:	64a2                	ld	s1,8(sp)
    80005230:	6105                	add	sp,sp,32
    80005232:	8082                	ret
      p->ofile[fd] = f;
    80005234:	01a50793          	add	a5,a0,26
    80005238:	078e                	sll	a5,a5,0x3
    8000523a:	963e                	add	a2,a2,a5
    8000523c:	e604                	sd	s1,8(a2)
      return fd;
    8000523e:	b7f5                	j	8000522a <fdalloc+0x2c>

0000000080005240 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005240:	715d                	add	sp,sp,-80
    80005242:	e486                	sd	ra,72(sp)
    80005244:	e0a2                	sd	s0,64(sp)
    80005246:	fc26                	sd	s1,56(sp)
    80005248:	f84a                	sd	s2,48(sp)
    8000524a:	f44e                	sd	s3,40(sp)
    8000524c:	f052                	sd	s4,32(sp)
    8000524e:	ec56                	sd	s5,24(sp)
    80005250:	0880                	add	s0,sp,80
    80005252:	8aae                	mv	s5,a1
    80005254:	8a32                	mv	s4,a2
    80005256:	89b6                	mv	s3,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005258:	fb040593          	add	a1,s0,-80
    8000525c:	fffff097          	auipc	ra,0xfffff
    80005260:	e3c080e7          	jalr	-452(ra) # 80004098 <nameiparent>
    80005264:	892a                	mv	s2,a0
    80005266:	12050c63          	beqz	a0,8000539e <create+0x15e>
    return 0;

  ilock(dp);
    8000526a:	ffffe097          	auipc	ra,0xffffe
    8000526e:	660080e7          	jalr	1632(ra) # 800038ca <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005272:	4601                	li	a2,0
    80005274:	fb040593          	add	a1,s0,-80
    80005278:	854a                	mv	a0,s2
    8000527a:	fffff097          	auipc	ra,0xfffff
    8000527e:	b2e080e7          	jalr	-1234(ra) # 80003da8 <dirlookup>
    80005282:	84aa                	mv	s1,a0
    80005284:	c539                	beqz	a0,800052d2 <create+0x92>
    iunlockput(dp);
    80005286:	854a                	mv	a0,s2
    80005288:	fffff097          	auipc	ra,0xfffff
    8000528c:	8a4080e7          	jalr	-1884(ra) # 80003b2c <iunlockput>
    ilock(ip);
    80005290:	8526                	mv	a0,s1
    80005292:	ffffe097          	auipc	ra,0xffffe
    80005296:	638080e7          	jalr	1592(ra) # 800038ca <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000529a:	4789                	li	a5,2
    8000529c:	02fa9463          	bne	s5,a5,800052c4 <create+0x84>
    800052a0:	0444d783          	lhu	a5,68(s1)
    800052a4:	37f9                	addw	a5,a5,-2
    800052a6:	17c2                	sll	a5,a5,0x30
    800052a8:	93c1                	srl	a5,a5,0x30
    800052aa:	4705                	li	a4,1
    800052ac:	00f76c63          	bltu	a4,a5,800052c4 <create+0x84>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800052b0:	8526                	mv	a0,s1
    800052b2:	60a6                	ld	ra,72(sp)
    800052b4:	6406                	ld	s0,64(sp)
    800052b6:	74e2                	ld	s1,56(sp)
    800052b8:	7942                	ld	s2,48(sp)
    800052ba:	79a2                	ld	s3,40(sp)
    800052bc:	7a02                	ld	s4,32(sp)
    800052be:	6ae2                	ld	s5,24(sp)
    800052c0:	6161                	add	sp,sp,80
    800052c2:	8082                	ret
    iunlockput(ip);
    800052c4:	8526                	mv	a0,s1
    800052c6:	fffff097          	auipc	ra,0xfffff
    800052ca:	866080e7          	jalr	-1946(ra) # 80003b2c <iunlockput>
    return 0;
    800052ce:	4481                	li	s1,0
    800052d0:	b7c5                	j	800052b0 <create+0x70>
  if((ip = ialloc(dp->dev, type)) == 0)
    800052d2:	85d6                	mv	a1,s5
    800052d4:	00092503          	lw	a0,0(s2)
    800052d8:	ffffe097          	auipc	ra,0xffffe
    800052dc:	45e080e7          	jalr	1118(ra) # 80003736 <ialloc>
    800052e0:	84aa                	mv	s1,a0
    800052e2:	c139                	beqz	a0,80005328 <create+0xe8>
  ilock(ip);
    800052e4:	ffffe097          	auipc	ra,0xffffe
    800052e8:	5e6080e7          	jalr	1510(ra) # 800038ca <ilock>
  ip->major = major;
    800052ec:	05449323          	sh	s4,70(s1)
  ip->minor = minor;
    800052f0:	05349423          	sh	s3,72(s1)
  ip->nlink = 1;
    800052f4:	4985                	li	s3,1
    800052f6:	05349523          	sh	s3,74(s1)
  iupdate(ip);
    800052fa:	8526                	mv	a0,s1
    800052fc:	ffffe097          	auipc	ra,0xffffe
    80005300:	502080e7          	jalr	1282(ra) # 800037fe <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005304:	033a8a63          	beq	s5,s3,80005338 <create+0xf8>
  if(dirlink(dp, name, ip->inum) < 0)
    80005308:	40d0                	lw	a2,4(s1)
    8000530a:	fb040593          	add	a1,s0,-80
    8000530e:	854a                	mv	a0,s2
    80005310:	fffff097          	auipc	ra,0xfffff
    80005314:	ca8080e7          	jalr	-856(ra) # 80003fb8 <dirlink>
    80005318:	06054b63          	bltz	a0,8000538e <create+0x14e>
  iunlockput(dp);
    8000531c:	854a                	mv	a0,s2
    8000531e:	fffff097          	auipc	ra,0xfffff
    80005322:	80e080e7          	jalr	-2034(ra) # 80003b2c <iunlockput>
  return ip;
    80005326:	b769                	j	800052b0 <create+0x70>
    panic("create: ialloc");
    80005328:	00003517          	auipc	a0,0x3
    8000532c:	41850513          	add	a0,a0,1048 # 80008740 <syscalls+0x2b0>
    80005330:	ffffb097          	auipc	ra,0xffffb
    80005334:	212080e7          	jalr	530(ra) # 80000542 <panic>
    dp->nlink++;  // for ".."
    80005338:	04a95783          	lhu	a5,74(s2)
    8000533c:	2785                	addw	a5,a5,1
    8000533e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005342:	854a                	mv	a0,s2
    80005344:	ffffe097          	auipc	ra,0xffffe
    80005348:	4ba080e7          	jalr	1210(ra) # 800037fe <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000534c:	40d0                	lw	a2,4(s1)
    8000534e:	00003597          	auipc	a1,0x3
    80005352:	40258593          	add	a1,a1,1026 # 80008750 <syscalls+0x2c0>
    80005356:	8526                	mv	a0,s1
    80005358:	fffff097          	auipc	ra,0xfffff
    8000535c:	c60080e7          	jalr	-928(ra) # 80003fb8 <dirlink>
    80005360:	00054f63          	bltz	a0,8000537e <create+0x13e>
    80005364:	00492603          	lw	a2,4(s2)
    80005368:	00003597          	auipc	a1,0x3
    8000536c:	d6058593          	add	a1,a1,-672 # 800080c8 <digits+0x98>
    80005370:	8526                	mv	a0,s1
    80005372:	fffff097          	auipc	ra,0xfffff
    80005376:	c46080e7          	jalr	-954(ra) # 80003fb8 <dirlink>
    8000537a:	f80557e3          	bgez	a0,80005308 <create+0xc8>
      panic("create dots");
    8000537e:	00003517          	auipc	a0,0x3
    80005382:	3da50513          	add	a0,a0,986 # 80008758 <syscalls+0x2c8>
    80005386:	ffffb097          	auipc	ra,0xffffb
    8000538a:	1bc080e7          	jalr	444(ra) # 80000542 <panic>
    panic("create: dirlink");
    8000538e:	00003517          	auipc	a0,0x3
    80005392:	3da50513          	add	a0,a0,986 # 80008768 <syscalls+0x2d8>
    80005396:	ffffb097          	auipc	ra,0xffffb
    8000539a:	1ac080e7          	jalr	428(ra) # 80000542 <panic>
    return 0;
    8000539e:	84aa                	mv	s1,a0
    800053a0:	bf01                	j	800052b0 <create+0x70>

00000000800053a2 <sys_dup>:
{
    800053a2:	7179                	add	sp,sp,-48
    800053a4:	f406                	sd	ra,40(sp)
    800053a6:	f022                	sd	s0,32(sp)
    800053a8:	ec26                	sd	s1,24(sp)
    800053aa:	e84a                	sd	s2,16(sp)
    800053ac:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053ae:	fd840613          	add	a2,s0,-40
    800053b2:	4581                	li	a1,0
    800053b4:	4501                	li	a0,0
    800053b6:	00000097          	auipc	ra,0x0
    800053ba:	de0080e7          	jalr	-544(ra) # 80005196 <argfd>
    return -1;
    800053be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053c0:	02054363          	bltz	a0,800053e6 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800053c4:	fd843903          	ld	s2,-40(s0)
    800053c8:	854a                	mv	a0,s2
    800053ca:	00000097          	auipc	ra,0x0
    800053ce:	e34080e7          	jalr	-460(ra) # 800051fe <fdalloc>
    800053d2:	84aa                	mv	s1,a0
    return -1;
    800053d4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053d6:	00054863          	bltz	a0,800053e6 <sys_dup+0x44>
  filedup(f);
    800053da:	854a                	mv	a0,s2
    800053dc:	fffff097          	auipc	ra,0xfffff
    800053e0:	306080e7          	jalr	774(ra) # 800046e2 <filedup>
  return fd;
    800053e4:	87a6                	mv	a5,s1
}
    800053e6:	853e                	mv	a0,a5
    800053e8:	70a2                	ld	ra,40(sp)
    800053ea:	7402                	ld	s0,32(sp)
    800053ec:	64e2                	ld	s1,24(sp)
    800053ee:	6942                	ld	s2,16(sp)
    800053f0:	6145                	add	sp,sp,48
    800053f2:	8082                	ret

00000000800053f4 <sys_read>:
{
    800053f4:	7179                	add	sp,sp,-48
    800053f6:	f406                	sd	ra,40(sp)
    800053f8:	f022                	sd	s0,32(sp)
    800053fa:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053fc:	fe840613          	add	a2,s0,-24
    80005400:	4581                	li	a1,0
    80005402:	4501                	li	a0,0
    80005404:	00000097          	auipc	ra,0x0
    80005408:	d92080e7          	jalr	-622(ra) # 80005196 <argfd>
    return -1;
    8000540c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000540e:	04054163          	bltz	a0,80005450 <sys_read+0x5c>
    80005412:	fe440593          	add	a1,s0,-28
    80005416:	4509                	li	a0,2
    80005418:	ffffe097          	auipc	ra,0xffffe
    8000541c:	948080e7          	jalr	-1720(ra) # 80002d60 <argint>
    return -1;
    80005420:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005422:	02054763          	bltz	a0,80005450 <sys_read+0x5c>
    80005426:	fd840593          	add	a1,s0,-40
    8000542a:	4505                	li	a0,1
    8000542c:	ffffe097          	auipc	ra,0xffffe
    80005430:	956080e7          	jalr	-1706(ra) # 80002d82 <argaddr>
    return -1;
    80005434:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005436:	00054d63          	bltz	a0,80005450 <sys_read+0x5c>
  return fileread(f, p, n);
    8000543a:	fe442603          	lw	a2,-28(s0)
    8000543e:	fd843583          	ld	a1,-40(s0)
    80005442:	fe843503          	ld	a0,-24(s0)
    80005446:	fffff097          	auipc	ra,0xfffff
    8000544a:	428080e7          	jalr	1064(ra) # 8000486e <fileread>
    8000544e:	87aa                	mv	a5,a0
}
    80005450:	853e                	mv	a0,a5
    80005452:	70a2                	ld	ra,40(sp)
    80005454:	7402                	ld	s0,32(sp)
    80005456:	6145                	add	sp,sp,48
    80005458:	8082                	ret

000000008000545a <sys_write>:
{
    8000545a:	7179                	add	sp,sp,-48
    8000545c:	f406                	sd	ra,40(sp)
    8000545e:	f022                	sd	s0,32(sp)
    80005460:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005462:	fe840613          	add	a2,s0,-24
    80005466:	4581                	li	a1,0
    80005468:	4501                	li	a0,0
    8000546a:	00000097          	auipc	ra,0x0
    8000546e:	d2c080e7          	jalr	-724(ra) # 80005196 <argfd>
    return -1;
    80005472:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005474:	04054163          	bltz	a0,800054b6 <sys_write+0x5c>
    80005478:	fe440593          	add	a1,s0,-28
    8000547c:	4509                	li	a0,2
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	8e2080e7          	jalr	-1822(ra) # 80002d60 <argint>
    return -1;
    80005486:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005488:	02054763          	bltz	a0,800054b6 <sys_write+0x5c>
    8000548c:	fd840593          	add	a1,s0,-40
    80005490:	4505                	li	a0,1
    80005492:	ffffe097          	auipc	ra,0xffffe
    80005496:	8f0080e7          	jalr	-1808(ra) # 80002d82 <argaddr>
    return -1;
    8000549a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000549c:	00054d63          	bltz	a0,800054b6 <sys_write+0x5c>
  return filewrite(f, p, n);
    800054a0:	fe442603          	lw	a2,-28(s0)
    800054a4:	fd843583          	ld	a1,-40(s0)
    800054a8:	fe843503          	ld	a0,-24(s0)
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	484080e7          	jalr	1156(ra) # 80004930 <filewrite>
    800054b4:	87aa                	mv	a5,a0
}
    800054b6:	853e                	mv	a0,a5
    800054b8:	70a2                	ld	ra,40(sp)
    800054ba:	7402                	ld	s0,32(sp)
    800054bc:	6145                	add	sp,sp,48
    800054be:	8082                	ret

00000000800054c0 <sys_close>:
{
    800054c0:	1101                	add	sp,sp,-32
    800054c2:	ec06                	sd	ra,24(sp)
    800054c4:	e822                	sd	s0,16(sp)
    800054c6:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054c8:	fe040613          	add	a2,s0,-32
    800054cc:	fec40593          	add	a1,s0,-20
    800054d0:	4501                	li	a0,0
    800054d2:	00000097          	auipc	ra,0x0
    800054d6:	cc4080e7          	jalr	-828(ra) # 80005196 <argfd>
    return -1;
    800054da:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054dc:	02054463          	bltz	a0,80005504 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054e0:	ffffc097          	auipc	ra,0xffffc
    800054e4:	558080e7          	jalr	1368(ra) # 80001a38 <myproc>
    800054e8:	fec42783          	lw	a5,-20(s0)
    800054ec:	07e9                	add	a5,a5,26
    800054ee:	078e                	sll	a5,a5,0x3
    800054f0:	953e                	add	a0,a0,a5
    800054f2:	00053423          	sd	zero,8(a0)
  fileclose(f);
    800054f6:	fe043503          	ld	a0,-32(s0)
    800054fa:	fffff097          	auipc	ra,0xfffff
    800054fe:	23a080e7          	jalr	570(ra) # 80004734 <fileclose>
  return 0;
    80005502:	4781                	li	a5,0
}
    80005504:	853e                	mv	a0,a5
    80005506:	60e2                	ld	ra,24(sp)
    80005508:	6442                	ld	s0,16(sp)
    8000550a:	6105                	add	sp,sp,32
    8000550c:	8082                	ret

000000008000550e <sys_fstat>:
{
    8000550e:	1101                	add	sp,sp,-32
    80005510:	ec06                	sd	ra,24(sp)
    80005512:	e822                	sd	s0,16(sp)
    80005514:	1000                	add	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005516:	fe840613          	add	a2,s0,-24
    8000551a:	4581                	li	a1,0
    8000551c:	4501                	li	a0,0
    8000551e:	00000097          	auipc	ra,0x0
    80005522:	c78080e7          	jalr	-904(ra) # 80005196 <argfd>
    return -1;
    80005526:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005528:	02054563          	bltz	a0,80005552 <sys_fstat+0x44>
    8000552c:	fe040593          	add	a1,s0,-32
    80005530:	4505                	li	a0,1
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	850080e7          	jalr	-1968(ra) # 80002d82 <argaddr>
    return -1;
    8000553a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000553c:	00054b63          	bltz	a0,80005552 <sys_fstat+0x44>
  return filestat(f, st);
    80005540:	fe043583          	ld	a1,-32(s0)
    80005544:	fe843503          	ld	a0,-24(s0)
    80005548:	fffff097          	auipc	ra,0xfffff
    8000554c:	2b4080e7          	jalr	692(ra) # 800047fc <filestat>
    80005550:	87aa                	mv	a5,a0
}
    80005552:	853e                	mv	a0,a5
    80005554:	60e2                	ld	ra,24(sp)
    80005556:	6442                	ld	s0,16(sp)
    80005558:	6105                	add	sp,sp,32
    8000555a:	8082                	ret

000000008000555c <sys_link>:
{
    8000555c:	7169                	add	sp,sp,-304
    8000555e:	f606                	sd	ra,296(sp)
    80005560:	f222                	sd	s0,288(sp)
    80005562:	ee26                	sd	s1,280(sp)
    80005564:	ea4a                	sd	s2,272(sp)
    80005566:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005568:	08000613          	li	a2,128
    8000556c:	ed040593          	add	a1,s0,-304
    80005570:	4501                	li	a0,0
    80005572:	ffffe097          	auipc	ra,0xffffe
    80005576:	832080e7          	jalr	-1998(ra) # 80002da4 <argstr>
    return -1;
    8000557a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000557c:	10054e63          	bltz	a0,80005698 <sys_link+0x13c>
    80005580:	08000613          	li	a2,128
    80005584:	f5040593          	add	a1,s0,-176
    80005588:	4505                	li	a0,1
    8000558a:	ffffe097          	auipc	ra,0xffffe
    8000558e:	81a080e7          	jalr	-2022(ra) # 80002da4 <argstr>
    return -1;
    80005592:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005594:	10054263          	bltz	a0,80005698 <sys_link+0x13c>
  begin_op();
    80005598:	fffff097          	auipc	ra,0xfffff
    8000559c:	cd2080e7          	jalr	-814(ra) # 8000426a <begin_op>
  if((ip = namei(old)) == 0){
    800055a0:	ed040513          	add	a0,s0,-304
    800055a4:	fffff097          	auipc	ra,0xfffff
    800055a8:	ad6080e7          	jalr	-1322(ra) # 8000407a <namei>
    800055ac:	84aa                	mv	s1,a0
    800055ae:	c551                	beqz	a0,8000563a <sys_link+0xde>
  ilock(ip);
    800055b0:	ffffe097          	auipc	ra,0xffffe
    800055b4:	31a080e7          	jalr	794(ra) # 800038ca <ilock>
  if(ip->type == T_DIR){
    800055b8:	04449703          	lh	a4,68(s1)
    800055bc:	4785                	li	a5,1
    800055be:	08f70463          	beq	a4,a5,80005646 <sys_link+0xea>
  ip->nlink++;
    800055c2:	04a4d783          	lhu	a5,74(s1)
    800055c6:	2785                	addw	a5,a5,1
    800055c8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055cc:	8526                	mv	a0,s1
    800055ce:	ffffe097          	auipc	ra,0xffffe
    800055d2:	230080e7          	jalr	560(ra) # 800037fe <iupdate>
  iunlock(ip);
    800055d6:	8526                	mv	a0,s1
    800055d8:	ffffe097          	auipc	ra,0xffffe
    800055dc:	3b4080e7          	jalr	948(ra) # 8000398c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055e0:	fd040593          	add	a1,s0,-48
    800055e4:	f5040513          	add	a0,s0,-176
    800055e8:	fffff097          	auipc	ra,0xfffff
    800055ec:	ab0080e7          	jalr	-1360(ra) # 80004098 <nameiparent>
    800055f0:	892a                	mv	s2,a0
    800055f2:	c935                	beqz	a0,80005666 <sys_link+0x10a>
  ilock(dp);
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	2d6080e7          	jalr	726(ra) # 800038ca <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055fc:	00092703          	lw	a4,0(s2)
    80005600:	409c                	lw	a5,0(s1)
    80005602:	04f71d63          	bne	a4,a5,8000565c <sys_link+0x100>
    80005606:	40d0                	lw	a2,4(s1)
    80005608:	fd040593          	add	a1,s0,-48
    8000560c:	854a                	mv	a0,s2
    8000560e:	fffff097          	auipc	ra,0xfffff
    80005612:	9aa080e7          	jalr	-1622(ra) # 80003fb8 <dirlink>
    80005616:	04054363          	bltz	a0,8000565c <sys_link+0x100>
  iunlockput(dp);
    8000561a:	854a                	mv	a0,s2
    8000561c:	ffffe097          	auipc	ra,0xffffe
    80005620:	510080e7          	jalr	1296(ra) # 80003b2c <iunlockput>
  iput(ip);
    80005624:	8526                	mv	a0,s1
    80005626:	ffffe097          	auipc	ra,0xffffe
    8000562a:	45e080e7          	jalr	1118(ra) # 80003a84 <iput>
  end_op();
    8000562e:	fffff097          	auipc	ra,0xfffff
    80005632:	cb6080e7          	jalr	-842(ra) # 800042e4 <end_op>
  return 0;
    80005636:	4781                	li	a5,0
    80005638:	a085                	j	80005698 <sys_link+0x13c>
    end_op();
    8000563a:	fffff097          	auipc	ra,0xfffff
    8000563e:	caa080e7          	jalr	-854(ra) # 800042e4 <end_op>
    return -1;
    80005642:	57fd                	li	a5,-1
    80005644:	a891                	j	80005698 <sys_link+0x13c>
    iunlockput(ip);
    80005646:	8526                	mv	a0,s1
    80005648:	ffffe097          	auipc	ra,0xffffe
    8000564c:	4e4080e7          	jalr	1252(ra) # 80003b2c <iunlockput>
    end_op();
    80005650:	fffff097          	auipc	ra,0xfffff
    80005654:	c94080e7          	jalr	-876(ra) # 800042e4 <end_op>
    return -1;
    80005658:	57fd                	li	a5,-1
    8000565a:	a83d                	j	80005698 <sys_link+0x13c>
    iunlockput(dp);
    8000565c:	854a                	mv	a0,s2
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	4ce080e7          	jalr	1230(ra) # 80003b2c <iunlockput>
  ilock(ip);
    80005666:	8526                	mv	a0,s1
    80005668:	ffffe097          	auipc	ra,0xffffe
    8000566c:	262080e7          	jalr	610(ra) # 800038ca <ilock>
  ip->nlink--;
    80005670:	04a4d783          	lhu	a5,74(s1)
    80005674:	37fd                	addw	a5,a5,-1
    80005676:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000567a:	8526                	mv	a0,s1
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	182080e7          	jalr	386(ra) # 800037fe <iupdate>
  iunlockput(ip);
    80005684:	8526                	mv	a0,s1
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	4a6080e7          	jalr	1190(ra) # 80003b2c <iunlockput>
  end_op();
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	c56080e7          	jalr	-938(ra) # 800042e4 <end_op>
  return -1;
    80005696:	57fd                	li	a5,-1
}
    80005698:	853e                	mv	a0,a5
    8000569a:	70b2                	ld	ra,296(sp)
    8000569c:	7412                	ld	s0,288(sp)
    8000569e:	64f2                	ld	s1,280(sp)
    800056a0:	6952                	ld	s2,272(sp)
    800056a2:	6155                	add	sp,sp,304
    800056a4:	8082                	ret

00000000800056a6 <sys_unlink>:
{
    800056a6:	7151                	add	sp,sp,-240
    800056a8:	f586                	sd	ra,232(sp)
    800056aa:	f1a2                	sd	s0,224(sp)
    800056ac:	eda6                	sd	s1,216(sp)
    800056ae:	e9ca                	sd	s2,208(sp)
    800056b0:	e5ce                	sd	s3,200(sp)
    800056b2:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056b4:	08000613          	li	a2,128
    800056b8:	f3040593          	add	a1,s0,-208
    800056bc:	4501                	li	a0,0
    800056be:	ffffd097          	auipc	ra,0xffffd
    800056c2:	6e6080e7          	jalr	1766(ra) # 80002da4 <argstr>
    800056c6:	18054163          	bltz	a0,80005848 <sys_unlink+0x1a2>
  begin_op();
    800056ca:	fffff097          	auipc	ra,0xfffff
    800056ce:	ba0080e7          	jalr	-1120(ra) # 8000426a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056d2:	fb040593          	add	a1,s0,-80
    800056d6:	f3040513          	add	a0,s0,-208
    800056da:	fffff097          	auipc	ra,0xfffff
    800056de:	9be080e7          	jalr	-1602(ra) # 80004098 <nameiparent>
    800056e2:	84aa                	mv	s1,a0
    800056e4:	c979                	beqz	a0,800057ba <sys_unlink+0x114>
  ilock(dp);
    800056e6:	ffffe097          	auipc	ra,0xffffe
    800056ea:	1e4080e7          	jalr	484(ra) # 800038ca <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056ee:	00003597          	auipc	a1,0x3
    800056f2:	06258593          	add	a1,a1,98 # 80008750 <syscalls+0x2c0>
    800056f6:	fb040513          	add	a0,s0,-80
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	694080e7          	jalr	1684(ra) # 80003d8e <namecmp>
    80005702:	14050a63          	beqz	a0,80005856 <sys_unlink+0x1b0>
    80005706:	00003597          	auipc	a1,0x3
    8000570a:	9c258593          	add	a1,a1,-1598 # 800080c8 <digits+0x98>
    8000570e:	fb040513          	add	a0,s0,-80
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	67c080e7          	jalr	1660(ra) # 80003d8e <namecmp>
    8000571a:	12050e63          	beqz	a0,80005856 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000571e:	f2c40613          	add	a2,s0,-212
    80005722:	fb040593          	add	a1,s0,-80
    80005726:	8526                	mv	a0,s1
    80005728:	ffffe097          	auipc	ra,0xffffe
    8000572c:	680080e7          	jalr	1664(ra) # 80003da8 <dirlookup>
    80005730:	892a                	mv	s2,a0
    80005732:	12050263          	beqz	a0,80005856 <sys_unlink+0x1b0>
  ilock(ip);
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	194080e7          	jalr	404(ra) # 800038ca <ilock>
  if(ip->nlink < 1)
    8000573e:	04a91783          	lh	a5,74(s2)
    80005742:	08f05263          	blez	a5,800057c6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005746:	04491703          	lh	a4,68(s2)
    8000574a:	4785                	li	a5,1
    8000574c:	08f70563          	beq	a4,a5,800057d6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005750:	4641                	li	a2,16
    80005752:	4581                	li	a1,0
    80005754:	fc040513          	add	a0,s0,-64
    80005758:	ffffb097          	auipc	ra,0xffffb
    8000575c:	5a0080e7          	jalr	1440(ra) # 80000cf8 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005760:	4741                	li	a4,16
    80005762:	f2c42683          	lw	a3,-212(s0)
    80005766:	fc040613          	add	a2,s0,-64
    8000576a:	4581                	li	a1,0
    8000576c:	8526                	mv	a0,s1
    8000576e:	ffffe097          	auipc	ra,0xffffe
    80005772:	506080e7          	jalr	1286(ra) # 80003c74 <writei>
    80005776:	47c1                	li	a5,16
    80005778:	0af51563          	bne	a0,a5,80005822 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000577c:	04491703          	lh	a4,68(s2)
    80005780:	4785                	li	a5,1
    80005782:	0af70863          	beq	a4,a5,80005832 <sys_unlink+0x18c>
  iunlockput(dp);
    80005786:	8526                	mv	a0,s1
    80005788:	ffffe097          	auipc	ra,0xffffe
    8000578c:	3a4080e7          	jalr	932(ra) # 80003b2c <iunlockput>
  ip->nlink--;
    80005790:	04a95783          	lhu	a5,74(s2)
    80005794:	37fd                	addw	a5,a5,-1
    80005796:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000579a:	854a                	mv	a0,s2
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	062080e7          	jalr	98(ra) # 800037fe <iupdate>
  iunlockput(ip);
    800057a4:	854a                	mv	a0,s2
    800057a6:	ffffe097          	auipc	ra,0xffffe
    800057aa:	386080e7          	jalr	902(ra) # 80003b2c <iunlockput>
  end_op();
    800057ae:	fffff097          	auipc	ra,0xfffff
    800057b2:	b36080e7          	jalr	-1226(ra) # 800042e4 <end_op>
  return 0;
    800057b6:	4501                	li	a0,0
    800057b8:	a84d                	j	8000586a <sys_unlink+0x1c4>
    end_op();
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	b2a080e7          	jalr	-1238(ra) # 800042e4 <end_op>
    return -1;
    800057c2:	557d                	li	a0,-1
    800057c4:	a05d                	j	8000586a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057c6:	00003517          	auipc	a0,0x3
    800057ca:	fb250513          	add	a0,a0,-78 # 80008778 <syscalls+0x2e8>
    800057ce:	ffffb097          	auipc	ra,0xffffb
    800057d2:	d74080e7          	jalr	-652(ra) # 80000542 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057d6:	04c92703          	lw	a4,76(s2)
    800057da:	02000793          	li	a5,32
    800057de:	f6e7f9e3          	bgeu	a5,a4,80005750 <sys_unlink+0xaa>
    800057e2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057e6:	4741                	li	a4,16
    800057e8:	86ce                	mv	a3,s3
    800057ea:	f1840613          	add	a2,s0,-232
    800057ee:	4581                	li	a1,0
    800057f0:	854a                	mv	a0,s2
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	38c080e7          	jalr	908(ra) # 80003b7e <readi>
    800057fa:	47c1                	li	a5,16
    800057fc:	00f51b63          	bne	a0,a5,80005812 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005800:	f1845783          	lhu	a5,-232(s0)
    80005804:	e7a1                	bnez	a5,8000584c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005806:	29c1                	addw	s3,s3,16
    80005808:	04c92783          	lw	a5,76(s2)
    8000580c:	fcf9ede3          	bltu	s3,a5,800057e6 <sys_unlink+0x140>
    80005810:	b781                	j	80005750 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005812:	00003517          	auipc	a0,0x3
    80005816:	f7e50513          	add	a0,a0,-130 # 80008790 <syscalls+0x300>
    8000581a:	ffffb097          	auipc	ra,0xffffb
    8000581e:	d28080e7          	jalr	-728(ra) # 80000542 <panic>
    panic("unlink: writei");
    80005822:	00003517          	auipc	a0,0x3
    80005826:	f8650513          	add	a0,a0,-122 # 800087a8 <syscalls+0x318>
    8000582a:	ffffb097          	auipc	ra,0xffffb
    8000582e:	d18080e7          	jalr	-744(ra) # 80000542 <panic>
    dp->nlink--;
    80005832:	04a4d783          	lhu	a5,74(s1)
    80005836:	37fd                	addw	a5,a5,-1
    80005838:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000583c:	8526                	mv	a0,s1
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	fc0080e7          	jalr	-64(ra) # 800037fe <iupdate>
    80005846:	b781                	j	80005786 <sys_unlink+0xe0>
    return -1;
    80005848:	557d                	li	a0,-1
    8000584a:	a005                	j	8000586a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000584c:	854a                	mv	a0,s2
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	2de080e7          	jalr	734(ra) # 80003b2c <iunlockput>
  iunlockput(dp);
    80005856:	8526                	mv	a0,s1
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	2d4080e7          	jalr	724(ra) # 80003b2c <iunlockput>
  end_op();
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	a84080e7          	jalr	-1404(ra) # 800042e4 <end_op>
  return -1;
    80005868:	557d                	li	a0,-1
}
    8000586a:	70ae                	ld	ra,232(sp)
    8000586c:	740e                	ld	s0,224(sp)
    8000586e:	64ee                	ld	s1,216(sp)
    80005870:	694e                	ld	s2,208(sp)
    80005872:	69ae                	ld	s3,200(sp)
    80005874:	616d                	add	sp,sp,240
    80005876:	8082                	ret

0000000080005878 <sys_open>:

uint64
sys_open(void)
{
    80005878:	7131                	add	sp,sp,-192
    8000587a:	fd06                	sd	ra,184(sp)
    8000587c:	f922                	sd	s0,176(sp)
    8000587e:	f526                	sd	s1,168(sp)
    80005880:	f14a                	sd	s2,160(sp)
    80005882:	ed4e                	sd	s3,152(sp)
    80005884:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005886:	08000613          	li	a2,128
    8000588a:	f5040593          	add	a1,s0,-176
    8000588e:	4501                	li	a0,0
    80005890:	ffffd097          	auipc	ra,0xffffd
    80005894:	514080e7          	jalr	1300(ra) # 80002da4 <argstr>
    return -1;
    80005898:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000589a:	0c054063          	bltz	a0,8000595a <sys_open+0xe2>
    8000589e:	f4c40593          	add	a1,s0,-180
    800058a2:	4505                	li	a0,1
    800058a4:	ffffd097          	auipc	ra,0xffffd
    800058a8:	4bc080e7          	jalr	1212(ra) # 80002d60 <argint>
    800058ac:	0a054763          	bltz	a0,8000595a <sys_open+0xe2>

  begin_op();
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	9ba080e7          	jalr	-1606(ra) # 8000426a <begin_op>

  if(omode & O_CREATE){
    800058b8:	f4c42783          	lw	a5,-180(s0)
    800058bc:	2007f793          	and	a5,a5,512
    800058c0:	cbd5                	beqz	a5,80005974 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    800058c2:	4681                	li	a3,0
    800058c4:	4601                	li	a2,0
    800058c6:	4589                	li	a1,2
    800058c8:	f5040513          	add	a0,s0,-176
    800058cc:	00000097          	auipc	ra,0x0
    800058d0:	974080e7          	jalr	-1676(ra) # 80005240 <create>
    800058d4:	892a                	mv	s2,a0
    if(ip == 0){
    800058d6:	c951                	beqz	a0,8000596a <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058d8:	04491703          	lh	a4,68(s2)
    800058dc:	478d                	li	a5,3
    800058de:	00f71763          	bne	a4,a5,800058ec <sys_open+0x74>
    800058e2:	04695703          	lhu	a4,70(s2)
    800058e6:	47a5                	li	a5,9
    800058e8:	0ce7eb63          	bltu	a5,a4,800059be <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058ec:	fffff097          	auipc	ra,0xfffff
    800058f0:	d8c080e7          	jalr	-628(ra) # 80004678 <filealloc>
    800058f4:	89aa                	mv	s3,a0
    800058f6:	c565                	beqz	a0,800059de <sys_open+0x166>
    800058f8:	00000097          	auipc	ra,0x0
    800058fc:	906080e7          	jalr	-1786(ra) # 800051fe <fdalloc>
    80005900:	84aa                	mv	s1,a0
    80005902:	0c054963          	bltz	a0,800059d4 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005906:	04491703          	lh	a4,68(s2)
    8000590a:	478d                	li	a5,3
    8000590c:	0ef70463          	beq	a4,a5,800059f4 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005910:	4789                	li	a5,2
    80005912:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005916:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000591a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000591e:	f4c42783          	lw	a5,-180(s0)
    80005922:	0017c713          	xor	a4,a5,1
    80005926:	8b05                	and	a4,a4,1
    80005928:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000592c:	0037f713          	and	a4,a5,3
    80005930:	00e03733          	snez	a4,a4
    80005934:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005938:	4007f793          	and	a5,a5,1024
    8000593c:	c791                	beqz	a5,80005948 <sys_open+0xd0>
    8000593e:	04491703          	lh	a4,68(s2)
    80005942:	4789                	li	a5,2
    80005944:	0af70f63          	beq	a4,a5,80005a02 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005948:	854a                	mv	a0,s2
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	042080e7          	jalr	66(ra) # 8000398c <iunlock>
  end_op();
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	992080e7          	jalr	-1646(ra) # 800042e4 <end_op>

  return fd;
}
    8000595a:	8526                	mv	a0,s1
    8000595c:	70ea                	ld	ra,184(sp)
    8000595e:	744a                	ld	s0,176(sp)
    80005960:	74aa                	ld	s1,168(sp)
    80005962:	790a                	ld	s2,160(sp)
    80005964:	69ea                	ld	s3,152(sp)
    80005966:	6129                	add	sp,sp,192
    80005968:	8082                	ret
      end_op();
    8000596a:	fffff097          	auipc	ra,0xfffff
    8000596e:	97a080e7          	jalr	-1670(ra) # 800042e4 <end_op>
      return -1;
    80005972:	b7e5                	j	8000595a <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005974:	f5040513          	add	a0,s0,-176
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	702080e7          	jalr	1794(ra) # 8000407a <namei>
    80005980:	892a                	mv	s2,a0
    80005982:	c905                	beqz	a0,800059b2 <sys_open+0x13a>
    ilock(ip);
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	f46080e7          	jalr	-186(ra) # 800038ca <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000598c:	04491703          	lh	a4,68(s2)
    80005990:	4785                	li	a5,1
    80005992:	f4f713e3          	bne	a4,a5,800058d8 <sys_open+0x60>
    80005996:	f4c42783          	lw	a5,-180(s0)
    8000599a:	dba9                	beqz	a5,800058ec <sys_open+0x74>
      iunlockput(ip);
    8000599c:	854a                	mv	a0,s2
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	18e080e7          	jalr	398(ra) # 80003b2c <iunlockput>
      end_op();
    800059a6:	fffff097          	auipc	ra,0xfffff
    800059aa:	93e080e7          	jalr	-1730(ra) # 800042e4 <end_op>
      return -1;
    800059ae:	54fd                	li	s1,-1
    800059b0:	b76d                	j	8000595a <sys_open+0xe2>
      end_op();
    800059b2:	fffff097          	auipc	ra,0xfffff
    800059b6:	932080e7          	jalr	-1742(ra) # 800042e4 <end_op>
      return -1;
    800059ba:	54fd                	li	s1,-1
    800059bc:	bf79                	j	8000595a <sys_open+0xe2>
    iunlockput(ip);
    800059be:	854a                	mv	a0,s2
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	16c080e7          	jalr	364(ra) # 80003b2c <iunlockput>
    end_op();
    800059c8:	fffff097          	auipc	ra,0xfffff
    800059cc:	91c080e7          	jalr	-1764(ra) # 800042e4 <end_op>
    return -1;
    800059d0:	54fd                	li	s1,-1
    800059d2:	b761                	j	8000595a <sys_open+0xe2>
      fileclose(f);
    800059d4:	854e                	mv	a0,s3
    800059d6:	fffff097          	auipc	ra,0xfffff
    800059da:	d5e080e7          	jalr	-674(ra) # 80004734 <fileclose>
    iunlockput(ip);
    800059de:	854a                	mv	a0,s2
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	14c080e7          	jalr	332(ra) # 80003b2c <iunlockput>
    end_op();
    800059e8:	fffff097          	auipc	ra,0xfffff
    800059ec:	8fc080e7          	jalr	-1796(ra) # 800042e4 <end_op>
    return -1;
    800059f0:	54fd                	li	s1,-1
    800059f2:	b7a5                	j	8000595a <sys_open+0xe2>
    f->type = FD_DEVICE;
    800059f4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059f8:	04691783          	lh	a5,70(s2)
    800059fc:	02f99223          	sh	a5,36(s3)
    80005a00:	bf29                	j	8000591a <sys_open+0xa2>
    itrunc(ip);
    80005a02:	854a                	mv	a0,s2
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	fd4080e7          	jalr	-44(ra) # 800039d8 <itrunc>
    80005a0c:	bf35                	j	80005948 <sys_open+0xd0>

0000000080005a0e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a0e:	7175                	add	sp,sp,-144
    80005a10:	e506                	sd	ra,136(sp)
    80005a12:	e122                	sd	s0,128(sp)
    80005a14:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	854080e7          	jalr	-1964(ra) # 8000426a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a1e:	08000613          	li	a2,128
    80005a22:	f7040593          	add	a1,s0,-144
    80005a26:	4501                	li	a0,0
    80005a28:	ffffd097          	auipc	ra,0xffffd
    80005a2c:	37c080e7          	jalr	892(ra) # 80002da4 <argstr>
    80005a30:	02054963          	bltz	a0,80005a62 <sys_mkdir+0x54>
    80005a34:	4681                	li	a3,0
    80005a36:	4601                	li	a2,0
    80005a38:	4585                	li	a1,1
    80005a3a:	f7040513          	add	a0,s0,-144
    80005a3e:	00000097          	auipc	ra,0x0
    80005a42:	802080e7          	jalr	-2046(ra) # 80005240 <create>
    80005a46:	cd11                	beqz	a0,80005a62 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a48:	ffffe097          	auipc	ra,0xffffe
    80005a4c:	0e4080e7          	jalr	228(ra) # 80003b2c <iunlockput>
  end_op();
    80005a50:	fffff097          	auipc	ra,0xfffff
    80005a54:	894080e7          	jalr	-1900(ra) # 800042e4 <end_op>
  return 0;
    80005a58:	4501                	li	a0,0
}
    80005a5a:	60aa                	ld	ra,136(sp)
    80005a5c:	640a                	ld	s0,128(sp)
    80005a5e:	6149                	add	sp,sp,144
    80005a60:	8082                	ret
    end_op();
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	882080e7          	jalr	-1918(ra) # 800042e4 <end_op>
    return -1;
    80005a6a:	557d                	li	a0,-1
    80005a6c:	b7fd                	j	80005a5a <sys_mkdir+0x4c>

0000000080005a6e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a6e:	7135                	add	sp,sp,-160
    80005a70:	ed06                	sd	ra,152(sp)
    80005a72:	e922                	sd	s0,144(sp)
    80005a74:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	7f4080e7          	jalr	2036(ra) # 8000426a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a7e:	08000613          	li	a2,128
    80005a82:	f7040593          	add	a1,s0,-144
    80005a86:	4501                	li	a0,0
    80005a88:	ffffd097          	auipc	ra,0xffffd
    80005a8c:	31c080e7          	jalr	796(ra) # 80002da4 <argstr>
    80005a90:	04054a63          	bltz	a0,80005ae4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a94:	f6c40593          	add	a1,s0,-148
    80005a98:	4505                	li	a0,1
    80005a9a:	ffffd097          	auipc	ra,0xffffd
    80005a9e:	2c6080e7          	jalr	710(ra) # 80002d60 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005aa2:	04054163          	bltz	a0,80005ae4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005aa6:	f6840593          	add	a1,s0,-152
    80005aaa:	4509                	li	a0,2
    80005aac:	ffffd097          	auipc	ra,0xffffd
    80005ab0:	2b4080e7          	jalr	692(ra) # 80002d60 <argint>
     argint(1, &major) < 0 ||
    80005ab4:	02054863          	bltz	a0,80005ae4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ab8:	f6841683          	lh	a3,-152(s0)
    80005abc:	f6c41603          	lh	a2,-148(s0)
    80005ac0:	458d                	li	a1,3
    80005ac2:	f7040513          	add	a0,s0,-144
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	77a080e7          	jalr	1914(ra) # 80005240 <create>
     argint(2, &minor) < 0 ||
    80005ace:	c919                	beqz	a0,80005ae4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ad0:	ffffe097          	auipc	ra,0xffffe
    80005ad4:	05c080e7          	jalr	92(ra) # 80003b2c <iunlockput>
  end_op();
    80005ad8:	fffff097          	auipc	ra,0xfffff
    80005adc:	80c080e7          	jalr	-2036(ra) # 800042e4 <end_op>
  return 0;
    80005ae0:	4501                	li	a0,0
    80005ae2:	a031                	j	80005aee <sys_mknod+0x80>
    end_op();
    80005ae4:	fffff097          	auipc	ra,0xfffff
    80005ae8:	800080e7          	jalr	-2048(ra) # 800042e4 <end_op>
    return -1;
    80005aec:	557d                	li	a0,-1
}
    80005aee:	60ea                	ld	ra,152(sp)
    80005af0:	644a                	ld	s0,144(sp)
    80005af2:	610d                	add	sp,sp,160
    80005af4:	8082                	ret

0000000080005af6 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005af6:	7135                	add	sp,sp,-160
    80005af8:	ed06                	sd	ra,152(sp)
    80005afa:	e922                	sd	s0,144(sp)
    80005afc:	e526                	sd	s1,136(sp)
    80005afe:	e14a                	sd	s2,128(sp)
    80005b00:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b02:	ffffc097          	auipc	ra,0xffffc
    80005b06:	f36080e7          	jalr	-202(ra) # 80001a38 <myproc>
    80005b0a:	892a                	mv	s2,a0
  
  begin_op();
    80005b0c:	ffffe097          	auipc	ra,0xffffe
    80005b10:	75e080e7          	jalr	1886(ra) # 8000426a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b14:	08000613          	li	a2,128
    80005b18:	f6040593          	add	a1,s0,-160
    80005b1c:	4501                	li	a0,0
    80005b1e:	ffffd097          	auipc	ra,0xffffd
    80005b22:	286080e7          	jalr	646(ra) # 80002da4 <argstr>
    80005b26:	04054b63          	bltz	a0,80005b7c <sys_chdir+0x86>
    80005b2a:	f6040513          	add	a0,s0,-160
    80005b2e:	ffffe097          	auipc	ra,0xffffe
    80005b32:	54c080e7          	jalr	1356(ra) # 8000407a <namei>
    80005b36:	84aa                	mv	s1,a0
    80005b38:	c131                	beqz	a0,80005b7c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b3a:	ffffe097          	auipc	ra,0xffffe
    80005b3e:	d90080e7          	jalr	-624(ra) # 800038ca <ilock>
  if(ip->type != T_DIR){
    80005b42:	04449703          	lh	a4,68(s1)
    80005b46:	4785                	li	a5,1
    80005b48:	04f71063          	bne	a4,a5,80005b88 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b4c:	8526                	mv	a0,s1
    80005b4e:	ffffe097          	auipc	ra,0xffffe
    80005b52:	e3e080e7          	jalr	-450(ra) # 8000398c <iunlock>
  iput(p->cwd);
    80005b56:	15893503          	ld	a0,344(s2)
    80005b5a:	ffffe097          	auipc	ra,0xffffe
    80005b5e:	f2a080e7          	jalr	-214(ra) # 80003a84 <iput>
  end_op();
    80005b62:	ffffe097          	auipc	ra,0xffffe
    80005b66:	782080e7          	jalr	1922(ra) # 800042e4 <end_op>
  p->cwd = ip;
    80005b6a:	14993c23          	sd	s1,344(s2)
  return 0;
    80005b6e:	4501                	li	a0,0
}
    80005b70:	60ea                	ld	ra,152(sp)
    80005b72:	644a                	ld	s0,144(sp)
    80005b74:	64aa                	ld	s1,136(sp)
    80005b76:	690a                	ld	s2,128(sp)
    80005b78:	610d                	add	sp,sp,160
    80005b7a:	8082                	ret
    end_op();
    80005b7c:	ffffe097          	auipc	ra,0xffffe
    80005b80:	768080e7          	jalr	1896(ra) # 800042e4 <end_op>
    return -1;
    80005b84:	557d                	li	a0,-1
    80005b86:	b7ed                	j	80005b70 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b88:	8526                	mv	a0,s1
    80005b8a:	ffffe097          	auipc	ra,0xffffe
    80005b8e:	fa2080e7          	jalr	-94(ra) # 80003b2c <iunlockput>
    end_op();
    80005b92:	ffffe097          	auipc	ra,0xffffe
    80005b96:	752080e7          	jalr	1874(ra) # 800042e4 <end_op>
    return -1;
    80005b9a:	557d                	li	a0,-1
    80005b9c:	bfd1                	j	80005b70 <sys_chdir+0x7a>

0000000080005b9e <sys_exec>:

uint64
sys_exec(void)
{
    80005b9e:	7121                	add	sp,sp,-448
    80005ba0:	ff06                	sd	ra,440(sp)
    80005ba2:	fb22                	sd	s0,432(sp)
    80005ba4:	f726                	sd	s1,424(sp)
    80005ba6:	f34a                	sd	s2,416(sp)
    80005ba8:	ef4e                	sd	s3,408(sp)
    80005baa:	eb52                	sd	s4,400(sp)
    80005bac:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bae:	08000613          	li	a2,128
    80005bb2:	f5040593          	add	a1,s0,-176
    80005bb6:	4501                	li	a0,0
    80005bb8:	ffffd097          	auipc	ra,0xffffd
    80005bbc:	1ec080e7          	jalr	492(ra) # 80002da4 <argstr>
    return -1;
    80005bc0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bc2:	0c054a63          	bltz	a0,80005c96 <sys_exec+0xf8>
    80005bc6:	e4840593          	add	a1,s0,-440
    80005bca:	4505                	li	a0,1
    80005bcc:	ffffd097          	auipc	ra,0xffffd
    80005bd0:	1b6080e7          	jalr	438(ra) # 80002d82 <argaddr>
    80005bd4:	0c054163          	bltz	a0,80005c96 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005bd8:	10000613          	li	a2,256
    80005bdc:	4581                	li	a1,0
    80005bde:	e5040513          	add	a0,s0,-432
    80005be2:	ffffb097          	auipc	ra,0xffffb
    80005be6:	116080e7          	jalr	278(ra) # 80000cf8 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bea:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005bee:	89a6                	mv	s3,s1
    80005bf0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bf2:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bf6:	00391513          	sll	a0,s2,0x3
    80005bfa:	e4040593          	add	a1,s0,-448
    80005bfe:	e4843783          	ld	a5,-440(s0)
    80005c02:	953e                	add	a0,a0,a5
    80005c04:	ffffd097          	auipc	ra,0xffffd
    80005c08:	0c2080e7          	jalr	194(ra) # 80002cc6 <fetchaddr>
    80005c0c:	02054a63          	bltz	a0,80005c40 <sys_exec+0xa2>
      goto bad;
    }
    if(uarg == 0){
    80005c10:	e4043783          	ld	a5,-448(s0)
    80005c14:	c3b9                	beqz	a5,80005c5a <sys_exec+0xbc>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c16:	ffffb097          	auipc	ra,0xffffb
    80005c1a:	ef6080e7          	jalr	-266(ra) # 80000b0c <kalloc>
    80005c1e:	85aa                	mv	a1,a0
    80005c20:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c24:	cd11                	beqz	a0,80005c40 <sys_exec+0xa2>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c26:	6605                	lui	a2,0x1
    80005c28:	e4043503          	ld	a0,-448(s0)
    80005c2c:	ffffd097          	auipc	ra,0xffffd
    80005c30:	0ec080e7          	jalr	236(ra) # 80002d18 <fetchstr>
    80005c34:	00054663          	bltz	a0,80005c40 <sys_exec+0xa2>
    if(i >= NELEM(argv)){
    80005c38:	0905                	add	s2,s2,1
    80005c3a:	09a1                	add	s3,s3,8
    80005c3c:	fb491de3          	bne	s2,s4,80005bf6 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c40:	f5040913          	add	s2,s0,-176
    80005c44:	6088                	ld	a0,0(s1)
    80005c46:	c539                	beqz	a0,80005c94 <sys_exec+0xf6>
    kfree(argv[i]);
    80005c48:	ffffb097          	auipc	ra,0xffffb
    80005c4c:	dc6080e7          	jalr	-570(ra) # 80000a0e <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c50:	04a1                	add	s1,s1,8
    80005c52:	ff2499e3          	bne	s1,s2,80005c44 <sys_exec+0xa6>
  return -1;
    80005c56:	597d                	li	s2,-1
    80005c58:	a83d                	j	80005c96 <sys_exec+0xf8>
      argv[i] = 0;
    80005c5a:	0009079b          	sext.w	a5,s2
    80005c5e:	078e                	sll	a5,a5,0x3
    80005c60:	fd078793          	add	a5,a5,-48
    80005c64:	97a2                	add	a5,a5,s0
    80005c66:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005c6a:	e5040593          	add	a1,s0,-432
    80005c6e:	f5040513          	add	a0,s0,-176
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	144080e7          	jalr	324(ra) # 80004db6 <exec>
    80005c7a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c7c:	f5040993          	add	s3,s0,-176
    80005c80:	6088                	ld	a0,0(s1)
    80005c82:	c911                	beqz	a0,80005c96 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c84:	ffffb097          	auipc	ra,0xffffb
    80005c88:	d8a080e7          	jalr	-630(ra) # 80000a0e <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c8c:	04a1                	add	s1,s1,8
    80005c8e:	ff3499e3          	bne	s1,s3,80005c80 <sys_exec+0xe2>
    80005c92:	a011                	j	80005c96 <sys_exec+0xf8>
  return -1;
    80005c94:	597d                	li	s2,-1
}
    80005c96:	854a                	mv	a0,s2
    80005c98:	70fa                	ld	ra,440(sp)
    80005c9a:	745a                	ld	s0,432(sp)
    80005c9c:	74ba                	ld	s1,424(sp)
    80005c9e:	791a                	ld	s2,416(sp)
    80005ca0:	69fa                	ld	s3,408(sp)
    80005ca2:	6a5a                	ld	s4,400(sp)
    80005ca4:	6139                	add	sp,sp,448
    80005ca6:	8082                	ret

0000000080005ca8 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ca8:	7139                	add	sp,sp,-64
    80005caa:	fc06                	sd	ra,56(sp)
    80005cac:	f822                	sd	s0,48(sp)
    80005cae:	f426                	sd	s1,40(sp)
    80005cb0:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005cb2:	ffffc097          	auipc	ra,0xffffc
    80005cb6:	d86080e7          	jalr	-634(ra) # 80001a38 <myproc>
    80005cba:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005cbc:	fd840593          	add	a1,s0,-40
    80005cc0:	4501                	li	a0,0
    80005cc2:	ffffd097          	auipc	ra,0xffffd
    80005cc6:	0c0080e7          	jalr	192(ra) # 80002d82 <argaddr>
    return -1;
    80005cca:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ccc:	0e054063          	bltz	a0,80005dac <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005cd0:	fc840593          	add	a1,s0,-56
    80005cd4:	fd040513          	add	a0,s0,-48
    80005cd8:	fffff097          	auipc	ra,0xfffff
    80005cdc:	db2080e7          	jalr	-590(ra) # 80004a8a <pipealloc>
    return -1;
    80005ce0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ce2:	0c054563          	bltz	a0,80005dac <sys_pipe+0x104>
  fd0 = -1;
    80005ce6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cea:	fd043503          	ld	a0,-48(s0)
    80005cee:	fffff097          	auipc	ra,0xfffff
    80005cf2:	510080e7          	jalr	1296(ra) # 800051fe <fdalloc>
    80005cf6:	fca42223          	sw	a0,-60(s0)
    80005cfa:	08054c63          	bltz	a0,80005d92 <sys_pipe+0xea>
    80005cfe:	fc843503          	ld	a0,-56(s0)
    80005d02:	fffff097          	auipc	ra,0xfffff
    80005d06:	4fc080e7          	jalr	1276(ra) # 800051fe <fdalloc>
    80005d0a:	fca42023          	sw	a0,-64(s0)
    80005d0e:	06054963          	bltz	a0,80005d80 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d12:	4691                	li	a3,4
    80005d14:	fc440613          	add	a2,s0,-60
    80005d18:	fd843583          	ld	a1,-40(s0)
    80005d1c:	68a8                	ld	a0,80(s1)
    80005d1e:	ffffc097          	auipc	ra,0xffffc
    80005d22:	b86080e7          	jalr	-1146(ra) # 800018a4 <copyout>
    80005d26:	02054063          	bltz	a0,80005d46 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d2a:	4691                	li	a3,4
    80005d2c:	fc040613          	add	a2,s0,-64
    80005d30:	fd843583          	ld	a1,-40(s0)
    80005d34:	0591                	add	a1,a1,4
    80005d36:	68a8                	ld	a0,80(s1)
    80005d38:	ffffc097          	auipc	ra,0xffffc
    80005d3c:	b6c080e7          	jalr	-1172(ra) # 800018a4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d40:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d42:	06055563          	bgez	a0,80005dac <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d46:	fc442783          	lw	a5,-60(s0)
    80005d4a:	07e9                	add	a5,a5,26
    80005d4c:	078e                	sll	a5,a5,0x3
    80005d4e:	97a6                	add	a5,a5,s1
    80005d50:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005d54:	fc042783          	lw	a5,-64(s0)
    80005d58:	07e9                	add	a5,a5,26
    80005d5a:	078e                	sll	a5,a5,0x3
    80005d5c:	00f48533          	add	a0,s1,a5
    80005d60:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005d64:	fd043503          	ld	a0,-48(s0)
    80005d68:	fffff097          	auipc	ra,0xfffff
    80005d6c:	9cc080e7          	jalr	-1588(ra) # 80004734 <fileclose>
    fileclose(wf);
    80005d70:	fc843503          	ld	a0,-56(s0)
    80005d74:	fffff097          	auipc	ra,0xfffff
    80005d78:	9c0080e7          	jalr	-1600(ra) # 80004734 <fileclose>
    return -1;
    80005d7c:	57fd                	li	a5,-1
    80005d7e:	a03d                	j	80005dac <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d80:	fc442783          	lw	a5,-60(s0)
    80005d84:	0007c763          	bltz	a5,80005d92 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d88:	07e9                	add	a5,a5,26
    80005d8a:	078e                	sll	a5,a5,0x3
    80005d8c:	97a6                	add	a5,a5,s1
    80005d8e:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    80005d92:	fd043503          	ld	a0,-48(s0)
    80005d96:	fffff097          	auipc	ra,0xfffff
    80005d9a:	99e080e7          	jalr	-1634(ra) # 80004734 <fileclose>
    fileclose(wf);
    80005d9e:	fc843503          	ld	a0,-56(s0)
    80005da2:	fffff097          	auipc	ra,0xfffff
    80005da6:	992080e7          	jalr	-1646(ra) # 80004734 <fileclose>
    return -1;
    80005daa:	57fd                	li	a5,-1
}
    80005dac:	853e                	mv	a0,a5
    80005dae:	70e2                	ld	ra,56(sp)
    80005db0:	7442                	ld	s0,48(sp)
    80005db2:	74a2                	ld	s1,40(sp)
    80005db4:	6121                	add	sp,sp,64
    80005db6:	8082                	ret
	...

0000000080005dc0 <kernelvec>:
    80005dc0:	7111                	add	sp,sp,-256
    80005dc2:	e006                	sd	ra,0(sp)
    80005dc4:	e40a                	sd	sp,8(sp)
    80005dc6:	e80e                	sd	gp,16(sp)
    80005dc8:	ec12                	sd	tp,24(sp)
    80005dca:	f016                	sd	t0,32(sp)
    80005dcc:	f41a                	sd	t1,40(sp)
    80005dce:	f81e                	sd	t2,48(sp)
    80005dd0:	fc22                	sd	s0,56(sp)
    80005dd2:	e0a6                	sd	s1,64(sp)
    80005dd4:	e4aa                	sd	a0,72(sp)
    80005dd6:	e8ae                	sd	a1,80(sp)
    80005dd8:	ecb2                	sd	a2,88(sp)
    80005dda:	f0b6                	sd	a3,96(sp)
    80005ddc:	f4ba                	sd	a4,104(sp)
    80005dde:	f8be                	sd	a5,112(sp)
    80005de0:	fcc2                	sd	a6,120(sp)
    80005de2:	e146                	sd	a7,128(sp)
    80005de4:	e54a                	sd	s2,136(sp)
    80005de6:	e94e                	sd	s3,144(sp)
    80005de8:	ed52                	sd	s4,152(sp)
    80005dea:	f156                	sd	s5,160(sp)
    80005dec:	f55a                	sd	s6,168(sp)
    80005dee:	f95e                	sd	s7,176(sp)
    80005df0:	fd62                	sd	s8,184(sp)
    80005df2:	e1e6                	sd	s9,192(sp)
    80005df4:	e5ea                	sd	s10,200(sp)
    80005df6:	e9ee                	sd	s11,208(sp)
    80005df8:	edf2                	sd	t3,216(sp)
    80005dfa:	f1f6                	sd	t4,224(sp)
    80005dfc:	f5fa                	sd	t5,232(sp)
    80005dfe:	f9fe                	sd	t6,240(sp)
    80005e00:	d93fc0ef          	jal	80002b92 <kerneltrap>
    80005e04:	6082                	ld	ra,0(sp)
    80005e06:	6122                	ld	sp,8(sp)
    80005e08:	61c2                	ld	gp,16(sp)
    80005e0a:	7282                	ld	t0,32(sp)
    80005e0c:	7322                	ld	t1,40(sp)
    80005e0e:	73c2                	ld	t2,48(sp)
    80005e10:	7462                	ld	s0,56(sp)
    80005e12:	6486                	ld	s1,64(sp)
    80005e14:	6526                	ld	a0,72(sp)
    80005e16:	65c6                	ld	a1,80(sp)
    80005e18:	6666                	ld	a2,88(sp)
    80005e1a:	7686                	ld	a3,96(sp)
    80005e1c:	7726                	ld	a4,104(sp)
    80005e1e:	77c6                	ld	a5,112(sp)
    80005e20:	7866                	ld	a6,120(sp)
    80005e22:	688a                	ld	a7,128(sp)
    80005e24:	692a                	ld	s2,136(sp)
    80005e26:	69ca                	ld	s3,144(sp)
    80005e28:	6a6a                	ld	s4,152(sp)
    80005e2a:	7a8a                	ld	s5,160(sp)
    80005e2c:	7b2a                	ld	s6,168(sp)
    80005e2e:	7bca                	ld	s7,176(sp)
    80005e30:	7c6a                	ld	s8,184(sp)
    80005e32:	6c8e                	ld	s9,192(sp)
    80005e34:	6d2e                	ld	s10,200(sp)
    80005e36:	6dce                	ld	s11,208(sp)
    80005e38:	6e6e                	ld	t3,216(sp)
    80005e3a:	7e8e                	ld	t4,224(sp)
    80005e3c:	7f2e                	ld	t5,232(sp)
    80005e3e:	7fce                	ld	t6,240(sp)
    80005e40:	6111                	add	sp,sp,256
    80005e42:	10200073          	sret
    80005e46:	00000013          	nop
    80005e4a:	00000013          	nop
    80005e4e:	0001                	nop

0000000080005e50 <timervec>:
    80005e50:	34051573          	csrrw	a0,mscratch,a0
    80005e54:	e10c                	sd	a1,0(a0)
    80005e56:	e510                	sd	a2,8(a0)
    80005e58:	e914                	sd	a3,16(a0)
    80005e5a:	710c                	ld	a1,32(a0)
    80005e5c:	7510                	ld	a2,40(a0)
    80005e5e:	6194                	ld	a3,0(a1)
    80005e60:	96b2                	add	a3,a3,a2
    80005e62:	e194                	sd	a3,0(a1)
    80005e64:	4589                	li	a1,2
    80005e66:	14459073          	csrw	sip,a1
    80005e6a:	6914                	ld	a3,16(a0)
    80005e6c:	6510                	ld	a2,8(a0)
    80005e6e:	610c                	ld	a1,0(a0)
    80005e70:	34051573          	csrrw	a0,mscratch,a0
    80005e74:	30200073          	mret
	...

0000000080005e7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e7a:	1141                	add	sp,sp,-16
    80005e7c:	e422                	sd	s0,8(sp)
    80005e7e:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e80:	0c0007b7          	lui	a5,0xc000
    80005e84:	4705                	li	a4,1
    80005e86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e88:	c3d8                	sw	a4,4(a5)
}
    80005e8a:	6422                	ld	s0,8(sp)
    80005e8c:	0141                	add	sp,sp,16
    80005e8e:	8082                	ret

0000000080005e90 <plicinithart>:

void
plicinithart(void)
{
    80005e90:	1141                	add	sp,sp,-16
    80005e92:	e406                	sd	ra,8(sp)
    80005e94:	e022                	sd	s0,0(sp)
    80005e96:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005e98:	ffffc097          	auipc	ra,0xffffc
    80005e9c:	b74080e7          	jalr	-1164(ra) # 80001a0c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ea0:	0085171b          	sllw	a4,a0,0x8
    80005ea4:	0c0027b7          	lui	a5,0xc002
    80005ea8:	97ba                	add	a5,a5,a4
    80005eaa:	40200713          	li	a4,1026
    80005eae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005eb2:	00d5151b          	sllw	a0,a0,0xd
    80005eb6:	0c2017b7          	lui	a5,0xc201
    80005eba:	97aa                	add	a5,a5,a0
    80005ebc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005ec0:	60a2                	ld	ra,8(sp)
    80005ec2:	6402                	ld	s0,0(sp)
    80005ec4:	0141                	add	sp,sp,16
    80005ec6:	8082                	ret

0000000080005ec8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ec8:	1141                	add	sp,sp,-16
    80005eca:	e406                	sd	ra,8(sp)
    80005ecc:	e022                	sd	s0,0(sp)
    80005ece:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005ed0:	ffffc097          	auipc	ra,0xffffc
    80005ed4:	b3c080e7          	jalr	-1220(ra) # 80001a0c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ed8:	00d5151b          	sllw	a0,a0,0xd
    80005edc:	0c2017b7          	lui	a5,0xc201
    80005ee0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005ee2:	43c8                	lw	a0,4(a5)
    80005ee4:	60a2                	ld	ra,8(sp)
    80005ee6:	6402                	ld	s0,0(sp)
    80005ee8:	0141                	add	sp,sp,16
    80005eea:	8082                	ret

0000000080005eec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005eec:	1101                	add	sp,sp,-32
    80005eee:	ec06                	sd	ra,24(sp)
    80005ef0:	e822                	sd	s0,16(sp)
    80005ef2:	e426                	sd	s1,8(sp)
    80005ef4:	1000                	add	s0,sp,32
    80005ef6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	b14080e7          	jalr	-1260(ra) # 80001a0c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f00:	00d5151b          	sllw	a0,a0,0xd
    80005f04:	0c2017b7          	lui	a5,0xc201
    80005f08:	97aa                	add	a5,a5,a0
    80005f0a:	c3c4                	sw	s1,4(a5)
}
    80005f0c:	60e2                	ld	ra,24(sp)
    80005f0e:	6442                	ld	s0,16(sp)
    80005f10:	64a2                	ld	s1,8(sp)
    80005f12:	6105                	add	sp,sp,32
    80005f14:	8082                	ret

0000000080005f16 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f16:	1141                	add	sp,sp,-16
    80005f18:	e406                	sd	ra,8(sp)
    80005f1a:	e022                	sd	s0,0(sp)
    80005f1c:	0800                	add	s0,sp,16
  if(i >= NUM)
    80005f1e:	479d                	li	a5,7
    80005f20:	04a7cb63          	blt	a5,a0,80005f76 <free_desc+0x60>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005f24:	0001d717          	auipc	a4,0x1d
    80005f28:	0dc70713          	add	a4,a4,220 # 80023000 <disk>
    80005f2c:	972a                	add	a4,a4,a0
    80005f2e:	6789                	lui	a5,0x2
    80005f30:	97ba                	add	a5,a5,a4
    80005f32:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f36:	eba1                	bnez	a5,80005f86 <free_desc+0x70>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005f38:	00451713          	sll	a4,a0,0x4
    80005f3c:	0001f797          	auipc	a5,0x1f
    80005f40:	0c47b783          	ld	a5,196(a5) # 80025000 <disk+0x2000>
    80005f44:	97ba                	add	a5,a5,a4
    80005f46:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005f4a:	0001d717          	auipc	a4,0x1d
    80005f4e:	0b670713          	add	a4,a4,182 # 80023000 <disk>
    80005f52:	972a                	add	a4,a4,a0
    80005f54:	6789                	lui	a5,0x2
    80005f56:	97ba                	add	a5,a5,a4
    80005f58:	4705                	li	a4,1
    80005f5a:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f5e:	0001f517          	auipc	a0,0x1f
    80005f62:	0ba50513          	add	a0,a0,186 # 80025018 <disk+0x2018>
    80005f66:	ffffc097          	auipc	ra,0xffffc
    80005f6a:	6ce080e7          	jalr	1742(ra) # 80002634 <wakeup>
}
    80005f6e:	60a2                	ld	ra,8(sp)
    80005f70:	6402                	ld	s0,0(sp)
    80005f72:	0141                	add	sp,sp,16
    80005f74:	8082                	ret
    panic("virtio_disk_intr 1");
    80005f76:	00003517          	auipc	a0,0x3
    80005f7a:	84250513          	add	a0,a0,-1982 # 800087b8 <syscalls+0x328>
    80005f7e:	ffffa097          	auipc	ra,0xffffa
    80005f82:	5c4080e7          	jalr	1476(ra) # 80000542 <panic>
    panic("virtio_disk_intr 2");
    80005f86:	00003517          	auipc	a0,0x3
    80005f8a:	84a50513          	add	a0,a0,-1974 # 800087d0 <syscalls+0x340>
    80005f8e:	ffffa097          	auipc	ra,0xffffa
    80005f92:	5b4080e7          	jalr	1460(ra) # 80000542 <panic>

0000000080005f96 <virtio_disk_init>:
{
    80005f96:	1101                	add	sp,sp,-32
    80005f98:	ec06                	sd	ra,24(sp)
    80005f9a:	e822                	sd	s0,16(sp)
    80005f9c:	e426                	sd	s1,8(sp)
    80005f9e:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fa0:	00003597          	auipc	a1,0x3
    80005fa4:	84858593          	add	a1,a1,-1976 # 800087e8 <syscalls+0x358>
    80005fa8:	0001f517          	auipc	a0,0x1f
    80005fac:	10050513          	add	a0,a0,256 # 800250a8 <disk+0x20a8>
    80005fb0:	ffffb097          	auipc	ra,0xffffb
    80005fb4:	bbc080e7          	jalr	-1092(ra) # 80000b6c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fb8:	100017b7          	lui	a5,0x10001
    80005fbc:	4398                	lw	a4,0(a5)
    80005fbe:	2701                	sext.w	a4,a4
    80005fc0:	747277b7          	lui	a5,0x74727
    80005fc4:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fc8:	0ef71063          	bne	a4,a5,800060a8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fcc:	100017b7          	lui	a5,0x10001
    80005fd0:	43dc                	lw	a5,4(a5)
    80005fd2:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fd4:	4705                	li	a4,1
    80005fd6:	0ce79963          	bne	a5,a4,800060a8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fda:	100017b7          	lui	a5,0x10001
    80005fde:	479c                	lw	a5,8(a5)
    80005fe0:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fe2:	4709                	li	a4,2
    80005fe4:	0ce79263          	bne	a5,a4,800060a8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fe8:	100017b7          	lui	a5,0x10001
    80005fec:	47d8                	lw	a4,12(a5)
    80005fee:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ff0:	554d47b7          	lui	a5,0x554d4
    80005ff4:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005ff8:	0af71863          	bne	a4,a5,800060a8 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ffc:	100017b7          	lui	a5,0x10001
    80006000:	4705                	li	a4,1
    80006002:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006004:	470d                	li	a4,3
    80006006:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006008:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000600a:	c7ffe6b7          	lui	a3,0xc7ffe
    8000600e:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    80006012:	8f75                	and	a4,a4,a3
    80006014:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006016:	472d                	li	a4,11
    80006018:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000601a:	473d                	li	a4,15
    8000601c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000601e:	6705                	lui	a4,0x1
    80006020:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006022:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006026:	5bdc                	lw	a5,52(a5)
    80006028:	2781                	sext.w	a5,a5
  if(max == 0)
    8000602a:	c7d9                	beqz	a5,800060b8 <virtio_disk_init+0x122>
  if(max < NUM)
    8000602c:	471d                	li	a4,7
    8000602e:	08f77d63          	bgeu	a4,a5,800060c8 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006032:	100014b7          	lui	s1,0x10001
    80006036:	47a1                	li	a5,8
    80006038:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000603a:	6609                	lui	a2,0x2
    8000603c:	4581                	li	a1,0
    8000603e:	0001d517          	auipc	a0,0x1d
    80006042:	fc250513          	add	a0,a0,-62 # 80023000 <disk>
    80006046:	ffffb097          	auipc	ra,0xffffb
    8000604a:	cb2080e7          	jalr	-846(ra) # 80000cf8 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000604e:	0001d717          	auipc	a4,0x1d
    80006052:	fb270713          	add	a4,a4,-78 # 80023000 <disk>
    80006056:	00c75793          	srl	a5,a4,0xc
    8000605a:	2781                	sext.w	a5,a5
    8000605c:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    8000605e:	0001f797          	auipc	a5,0x1f
    80006062:	fa278793          	add	a5,a5,-94 # 80025000 <disk+0x2000>
    80006066:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80006068:	0001d717          	auipc	a4,0x1d
    8000606c:	01870713          	add	a4,a4,24 # 80023080 <disk+0x80>
    80006070:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006072:	0001e717          	auipc	a4,0x1e
    80006076:	f8e70713          	add	a4,a4,-114 # 80024000 <disk+0x1000>
    8000607a:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000607c:	4705                	li	a4,1
    8000607e:	00e78c23          	sb	a4,24(a5)
    80006082:	00e78ca3          	sb	a4,25(a5)
    80006086:	00e78d23          	sb	a4,26(a5)
    8000608a:	00e78da3          	sb	a4,27(a5)
    8000608e:	00e78e23          	sb	a4,28(a5)
    80006092:	00e78ea3          	sb	a4,29(a5)
    80006096:	00e78f23          	sb	a4,30(a5)
    8000609a:	00e78fa3          	sb	a4,31(a5)
}
    8000609e:	60e2                	ld	ra,24(sp)
    800060a0:	6442                	ld	s0,16(sp)
    800060a2:	64a2                	ld	s1,8(sp)
    800060a4:	6105                	add	sp,sp,32
    800060a6:	8082                	ret
    panic("could not find virtio disk");
    800060a8:	00002517          	auipc	a0,0x2
    800060ac:	75050513          	add	a0,a0,1872 # 800087f8 <syscalls+0x368>
    800060b0:	ffffa097          	auipc	ra,0xffffa
    800060b4:	492080e7          	jalr	1170(ra) # 80000542 <panic>
    panic("virtio disk has no queue 0");
    800060b8:	00002517          	auipc	a0,0x2
    800060bc:	76050513          	add	a0,a0,1888 # 80008818 <syscalls+0x388>
    800060c0:	ffffa097          	auipc	ra,0xffffa
    800060c4:	482080e7          	jalr	1154(ra) # 80000542 <panic>
    panic("virtio disk max queue too short");
    800060c8:	00002517          	auipc	a0,0x2
    800060cc:	77050513          	add	a0,a0,1904 # 80008838 <syscalls+0x3a8>
    800060d0:	ffffa097          	auipc	ra,0xffffa
    800060d4:	472080e7          	jalr	1138(ra) # 80000542 <panic>

00000000800060d8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060d8:	7119                	add	sp,sp,-128
    800060da:	fc86                	sd	ra,120(sp)
    800060dc:	f8a2                	sd	s0,112(sp)
    800060de:	f4a6                	sd	s1,104(sp)
    800060e0:	f0ca                	sd	s2,96(sp)
    800060e2:	ecce                	sd	s3,88(sp)
    800060e4:	e8d2                	sd	s4,80(sp)
    800060e6:	e4d6                	sd	s5,72(sp)
    800060e8:	e0da                	sd	s6,64(sp)
    800060ea:	fc5e                	sd	s7,56(sp)
    800060ec:	f862                	sd	s8,48(sp)
    800060ee:	f466                	sd	s9,40(sp)
    800060f0:	f06a                	sd	s10,32(sp)
    800060f2:	0100                	add	s0,sp,128
    800060f4:	8a2a                	mv	s4,a0
    800060f6:	8cae                	mv	s9,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060f8:	00c52c03          	lw	s8,12(a0)
    800060fc:	001c1c1b          	sllw	s8,s8,0x1
    80006100:	1c02                	sll	s8,s8,0x20
    80006102:	020c5c13          	srl	s8,s8,0x20

  acquire(&disk.vdisk_lock);
    80006106:	0001f517          	auipc	a0,0x1f
    8000610a:	fa250513          	add	a0,a0,-94 # 800250a8 <disk+0x20a8>
    8000610e:	ffffb097          	auipc	ra,0xffffb
    80006112:	aee080e7          	jalr	-1298(ra) # 80000bfc <acquire>
  for(int i = 0; i < 3; i++){
    80006116:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006118:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000611a:	0001db97          	auipc	s7,0x1d
    8000611e:	ee6b8b93          	add	s7,s7,-282 # 80023000 <disk>
    80006122:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006124:	4a8d                	li	s5,3
    80006126:	a0b5                	j	80006192 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006128:	00fb8733          	add	a4,s7,a5
    8000612c:	975a                	add	a4,a4,s6
    8000612e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006132:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006134:	0207c563          	bltz	a5,8000615e <virtio_disk_rw+0x86>
  for(int i = 0; i < 3; i++){
    80006138:	2605                	addw	a2,a2,1 # 2001 <_entry-0x7fffdfff>
    8000613a:	0591                	add	a1,a1,4
    8000613c:	19560c63          	beq	a2,s5,800062d4 <virtio_disk_rw+0x1fc>
    idx[i] = alloc_desc();
    80006140:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006142:	0001f717          	auipc	a4,0x1f
    80006146:	ed670713          	add	a4,a4,-298 # 80025018 <disk+0x2018>
    8000614a:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000614c:	00074683          	lbu	a3,0(a4)
    80006150:	fee1                	bnez	a3,80006128 <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    80006152:	2785                	addw	a5,a5,1
    80006154:	0705                	add	a4,a4,1
    80006156:	fe979be3          	bne	a5,s1,8000614c <virtio_disk_rw+0x74>
    idx[i] = alloc_desc();
    8000615a:	57fd                	li	a5,-1
    8000615c:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000615e:	00c05e63          	blez	a2,8000617a <virtio_disk_rw+0xa2>
    80006162:	060a                	sll	a2,a2,0x2
    80006164:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006168:	0009a503          	lw	a0,0(s3)
    8000616c:	00000097          	auipc	ra,0x0
    80006170:	daa080e7          	jalr	-598(ra) # 80005f16 <free_desc>
      for(int j = 0; j < i; j++)
    80006174:	0991                	add	s3,s3,4
    80006176:	ffa999e3          	bne	s3,s10,80006168 <virtio_disk_rw+0x90>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000617a:	0001f597          	auipc	a1,0x1f
    8000617e:	f2e58593          	add	a1,a1,-210 # 800250a8 <disk+0x20a8>
    80006182:	0001f517          	auipc	a0,0x1f
    80006186:	e9650513          	add	a0,a0,-362 # 80025018 <disk+0x2018>
    8000618a:	ffffc097          	auipc	ra,0xffffc
    8000618e:	32a080e7          	jalr	810(ra) # 800024b4 <sleep>
  for(int i = 0; i < 3; i++){
    80006192:	f9040993          	add	s3,s0,-112
{
    80006196:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006198:	864a                	mv	a2,s2
    8000619a:	b75d                	j	80006140 <virtio_disk_rw+0x68>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000619c:	0001f717          	auipc	a4,0x1f
    800061a0:	e6473703          	ld	a4,-412(a4) # 80025000 <disk+0x2000>
    800061a4:	973e                	add	a4,a4,a5
    800061a6:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061aa:	0001d517          	auipc	a0,0x1d
    800061ae:	e5650513          	add	a0,a0,-426 # 80023000 <disk>
    800061b2:	0001f717          	auipc	a4,0x1f
    800061b6:	e4e70713          	add	a4,a4,-434 # 80025000 <disk+0x2000>
    800061ba:	6314                	ld	a3,0(a4)
    800061bc:	96be                	add	a3,a3,a5
    800061be:	00c6d603          	lhu	a2,12(a3)
    800061c2:	00166613          	or	a2,a2,1
    800061c6:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061ca:	f9842683          	lw	a3,-104(s0)
    800061ce:	6310                	ld	a2,0(a4)
    800061d0:	97b2                	add	a5,a5,a2
    800061d2:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    800061d6:	20048613          	add	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    800061da:	0612                	sll	a2,a2,0x4
    800061dc:	962a                	add	a2,a2,a0
    800061de:	02060823          	sb	zero,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061e2:	00469793          	sll	a5,a3,0x4
    800061e6:	630c                	ld	a1,0(a4)
    800061e8:	95be                	add	a1,a1,a5
    800061ea:	6689                	lui	a3,0x2
    800061ec:	03068693          	add	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    800061f0:	96ca                	add	a3,a3,s2
    800061f2:	96aa                	add	a3,a3,a0
    800061f4:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    800061f6:	6314                	ld	a3,0(a4)
    800061f8:	96be                	add	a3,a3,a5
    800061fa:	4585                	li	a1,1
    800061fc:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061fe:	6314                	ld	a3,0(a4)
    80006200:	96be                	add	a3,a3,a5
    80006202:	4509                	li	a0,2
    80006204:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    80006208:	6314                	ld	a3,0(a4)
    8000620a:	97b6                	add	a5,a5,a3
    8000620c:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006210:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006214:	03463423          	sd	s4,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    80006218:	6714                	ld	a3,8(a4)
    8000621a:	0026d783          	lhu	a5,2(a3)
    8000621e:	8b9d                	and	a5,a5,7
    80006220:	0789                	add	a5,a5,2
    80006222:	0786                	sll	a5,a5,0x1
    80006224:	96be                	add	a3,a3,a5
    80006226:	00969023          	sh	s1,0(a3)
  __sync_synchronize();
    8000622a:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    8000622e:	6718                	ld	a4,8(a4)
    80006230:	00275783          	lhu	a5,2(a4)
    80006234:	2785                	addw	a5,a5,1
    80006236:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000623a:	100017b7          	lui	a5,0x10001
    8000623e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006242:	004a2783          	lw	a5,4(s4)
    80006246:	02b79163          	bne	a5,a1,80006268 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000624a:	0001f917          	auipc	s2,0x1f
    8000624e:	e5e90913          	add	s2,s2,-418 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006252:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006254:	85ca                	mv	a1,s2
    80006256:	8552                	mv	a0,s4
    80006258:	ffffc097          	auipc	ra,0xffffc
    8000625c:	25c080e7          	jalr	604(ra) # 800024b4 <sleep>
  while(b->disk == 1) {
    80006260:	004a2783          	lw	a5,4(s4)
    80006264:	fe9788e3          	beq	a5,s1,80006254 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006268:	f9042483          	lw	s1,-112(s0)
    8000626c:	20048713          	add	a4,s1,512
    80006270:	0712                	sll	a4,a4,0x4
    80006272:	0001d797          	auipc	a5,0x1d
    80006276:	d8e78793          	add	a5,a5,-626 # 80023000 <disk>
    8000627a:	97ba                	add	a5,a5,a4
    8000627c:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006280:	0001f917          	auipc	s2,0x1f
    80006284:	d8090913          	add	s2,s2,-640 # 80025000 <disk+0x2000>
    80006288:	a019                	j	8000628e <virtio_disk_rw+0x1b6>
      i = disk.desc[i].next;
    8000628a:	00e7d483          	lhu	s1,14(a5)
    free_desc(i);
    8000628e:	8526                	mv	a0,s1
    80006290:	00000097          	auipc	ra,0x0
    80006294:	c86080e7          	jalr	-890(ra) # 80005f16 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006298:	0492                	sll	s1,s1,0x4
    8000629a:	00093783          	ld	a5,0(s2)
    8000629e:	97a6                	add	a5,a5,s1
    800062a0:	00c7d703          	lhu	a4,12(a5)
    800062a4:	8b05                	and	a4,a4,1
    800062a6:	f375                	bnez	a4,8000628a <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062a8:	0001f517          	auipc	a0,0x1f
    800062ac:	e0050513          	add	a0,a0,-512 # 800250a8 <disk+0x20a8>
    800062b0:	ffffb097          	auipc	ra,0xffffb
    800062b4:	a00080e7          	jalr	-1536(ra) # 80000cb0 <release>
}
    800062b8:	70e6                	ld	ra,120(sp)
    800062ba:	7446                	ld	s0,112(sp)
    800062bc:	74a6                	ld	s1,104(sp)
    800062be:	7906                	ld	s2,96(sp)
    800062c0:	69e6                	ld	s3,88(sp)
    800062c2:	6a46                	ld	s4,80(sp)
    800062c4:	6aa6                	ld	s5,72(sp)
    800062c6:	6b06                	ld	s6,64(sp)
    800062c8:	7be2                	ld	s7,56(sp)
    800062ca:	7c42                	ld	s8,48(sp)
    800062cc:	7ca2                	ld	s9,40(sp)
    800062ce:	7d02                	ld	s10,32(sp)
    800062d0:	6109                	add	sp,sp,128
    800062d2:	8082                	ret
  if(write)
    800062d4:	019037b3          	snez	a5,s9
    800062d8:	f8f42023          	sw	a5,-128(s0)
  buf0.reserved = 0;
    800062dc:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    800062e0:	f9843423          	sd	s8,-120(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800062e4:	f9042483          	lw	s1,-112(s0)
    800062e8:	00449913          	sll	s2,s1,0x4
    800062ec:	0001f997          	auipc	s3,0x1f
    800062f0:	d1498993          	add	s3,s3,-748 # 80025000 <disk+0x2000>
    800062f4:	0009ba83          	ld	s5,0(s3)
    800062f8:	9aca                	add	s5,s5,s2
    800062fa:	f8040513          	add	a0,s0,-128
    800062fe:	ffffb097          	auipc	ra,0xffffb
    80006302:	ec6080e7          	jalr	-314(ra) # 800011c4 <kvmpa>
    80006306:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000630a:	0009b783          	ld	a5,0(s3)
    8000630e:	97ca                	add	a5,a5,s2
    80006310:	4741                	li	a4,16
    80006312:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006314:	0009b783          	ld	a5,0(s3)
    80006318:	97ca                	add	a5,a5,s2
    8000631a:	4705                	li	a4,1
    8000631c:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006320:	f9442783          	lw	a5,-108(s0)
    80006324:	0009b703          	ld	a4,0(s3)
    80006328:	974a                	add	a4,a4,s2
    8000632a:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000632e:	0792                	sll	a5,a5,0x4
    80006330:	0009b703          	ld	a4,0(s3)
    80006334:	973e                	add	a4,a4,a5
    80006336:	058a0693          	add	a3,s4,88
    8000633a:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    8000633c:	0009b703          	ld	a4,0(s3)
    80006340:	973e                	add	a4,a4,a5
    80006342:	40000693          	li	a3,1024
    80006346:	c714                	sw	a3,8(a4)
  if(write)
    80006348:	e40c9ae3          	bnez	s9,8000619c <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000634c:	0001f717          	auipc	a4,0x1f
    80006350:	cb473703          	ld	a4,-844(a4) # 80025000 <disk+0x2000>
    80006354:	973e                	add	a4,a4,a5
    80006356:	4689                	li	a3,2
    80006358:	00d71623          	sh	a3,12(a4)
    8000635c:	b5b9                	j	800061aa <virtio_disk_rw+0xd2>

000000008000635e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000635e:	1101                	add	sp,sp,-32
    80006360:	ec06                	sd	ra,24(sp)
    80006362:	e822                	sd	s0,16(sp)
    80006364:	e426                	sd	s1,8(sp)
    80006366:	e04a                	sd	s2,0(sp)
    80006368:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000636a:	0001f517          	auipc	a0,0x1f
    8000636e:	d3e50513          	add	a0,a0,-706 # 800250a8 <disk+0x20a8>
    80006372:	ffffb097          	auipc	ra,0xffffb
    80006376:	88a080e7          	jalr	-1910(ra) # 80000bfc <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    8000637a:	0001f717          	auipc	a4,0x1f
    8000637e:	c8670713          	add	a4,a4,-890 # 80025000 <disk+0x2000>
    80006382:	02075783          	lhu	a5,32(a4)
    80006386:	6b18                	ld	a4,16(a4)
    80006388:	00275683          	lhu	a3,2(a4)
    8000638c:	8ebd                	xor	a3,a3,a5
    8000638e:	8a9d                	and	a3,a3,7
    80006390:	cab9                	beqz	a3,800063e6 <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    80006392:	0001d917          	auipc	s2,0x1d
    80006396:	c6e90913          	add	s2,s2,-914 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    8000639a:	0001f497          	auipc	s1,0x1f
    8000639e:	c6648493          	add	s1,s1,-922 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800063a2:	078e                	sll	a5,a5,0x3
    800063a4:	973e                	add	a4,a4,a5
    800063a6:	435c                	lw	a5,4(a4)
    if(disk.info[id].status != 0)
    800063a8:	20078713          	add	a4,a5,512
    800063ac:	0712                	sll	a4,a4,0x4
    800063ae:	974a                	add	a4,a4,s2
    800063b0:	03074703          	lbu	a4,48(a4)
    800063b4:	ef21                	bnez	a4,8000640c <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800063b6:	20078793          	add	a5,a5,512
    800063ba:	0792                	sll	a5,a5,0x4
    800063bc:	97ca                	add	a5,a5,s2
    800063be:	7798                	ld	a4,40(a5)
    800063c0:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800063c4:	7788                	ld	a0,40(a5)
    800063c6:	ffffc097          	auipc	ra,0xffffc
    800063ca:	26e080e7          	jalr	622(ra) # 80002634 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800063ce:	0204d783          	lhu	a5,32(s1)
    800063d2:	2785                	addw	a5,a5,1
    800063d4:	8b9d                	and	a5,a5,7
    800063d6:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800063da:	6898                	ld	a4,16(s1)
    800063dc:	00275683          	lhu	a3,2(a4)
    800063e0:	8a9d                	and	a3,a3,7
    800063e2:	fcf690e3          	bne	a3,a5,800063a2 <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063e6:	10001737          	lui	a4,0x10001
    800063ea:	533c                	lw	a5,96(a4)
    800063ec:	8b8d                	and	a5,a5,3
    800063ee:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800063f0:	0001f517          	auipc	a0,0x1f
    800063f4:	cb850513          	add	a0,a0,-840 # 800250a8 <disk+0x20a8>
    800063f8:	ffffb097          	auipc	ra,0xffffb
    800063fc:	8b8080e7          	jalr	-1864(ra) # 80000cb0 <release>
}
    80006400:	60e2                	ld	ra,24(sp)
    80006402:	6442                	ld	s0,16(sp)
    80006404:	64a2                	ld	s1,8(sp)
    80006406:	6902                	ld	s2,0(sp)
    80006408:	6105                	add	sp,sp,32
    8000640a:	8082                	ret
      panic("virtio_disk_intr status");
    8000640c:	00002517          	auipc	a0,0x2
    80006410:	44c50513          	add	a0,a0,1100 # 80008858 <syscalls+0x3c8>
    80006414:	ffffa097          	auipc	ra,0xffffa
    80006418:	12e080e7          	jalr	302(ra) # 80000542 <panic>

000000008000641c <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    8000641c:	7179                	add	sp,sp,-48
    8000641e:	f406                	sd	ra,40(sp)
    80006420:	f022                	sd	s0,32(sp)
    80006422:	ec26                	sd	s1,24(sp)
    80006424:	e84a                	sd	s2,16(sp)
    80006426:	e44e                	sd	s3,8(sp)
    80006428:	e052                	sd	s4,0(sp)
    8000642a:	1800                	add	s0,sp,48
    8000642c:	892a                	mv	s2,a0
    8000642e:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    80006430:	00003a17          	auipc	s4,0x3
    80006434:	bf8a0a13          	add	s4,s4,-1032 # 80009028 <stats>
    80006438:	000a2683          	lw	a3,0(s4)
    8000643c:	00002617          	auipc	a2,0x2
    80006440:	43460613          	add	a2,a2,1076 # 80008870 <syscalls+0x3e0>
    80006444:	00000097          	auipc	ra,0x0
    80006448:	2c6080e7          	jalr	710(ra) # 8000670a <snprintf>
    8000644c:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    8000644e:	004a2683          	lw	a3,4(s4)
    80006452:	00002617          	auipc	a2,0x2
    80006456:	42e60613          	add	a2,a2,1070 # 80008880 <syscalls+0x3f0>
    8000645a:	85ce                	mv	a1,s3
    8000645c:	954a                	add	a0,a0,s2
    8000645e:	00000097          	auipc	ra,0x0
    80006462:	2ac080e7          	jalr	684(ra) # 8000670a <snprintf>
  return n;
}
    80006466:	9d25                	addw	a0,a0,s1
    80006468:	70a2                	ld	ra,40(sp)
    8000646a:	7402                	ld	s0,32(sp)
    8000646c:	64e2                	ld	s1,24(sp)
    8000646e:	6942                	ld	s2,16(sp)
    80006470:	69a2                	ld	s3,8(sp)
    80006472:	6a02                	ld	s4,0(sp)
    80006474:	6145                	add	sp,sp,48
    80006476:	8082                	ret

0000000080006478 <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    80006478:	7179                	add	sp,sp,-48
    8000647a:	f406                	sd	ra,40(sp)
    8000647c:	f022                	sd	s0,32(sp)
    8000647e:	ec26                	sd	s1,24(sp)
    80006480:	e84a                	sd	s2,16(sp)
    80006482:	e44e                	sd	s3,8(sp)
    80006484:	1800                	add	s0,sp,48
    80006486:	89ae                	mv	s3,a1
    80006488:	84b2                	mv	s1,a2
    8000648a:	8936                	mv	s2,a3
  struct proc *p = myproc();
    8000648c:	ffffb097          	auipc	ra,0xffffb
    80006490:	5ac080e7          	jalr	1452(ra) # 80001a38 <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    80006494:	653c                	ld	a5,72(a0)
    80006496:	02f4ff63          	bgeu	s1,a5,800064d4 <copyin_new+0x5c>
    8000649a:	01248733          	add	a4,s1,s2
    8000649e:	02f77d63          	bgeu	a4,a5,800064d8 <copyin_new+0x60>
    800064a2:	02976d63          	bltu	a4,s1,800064dc <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    800064a6:	0009061b          	sext.w	a2,s2
    800064aa:	85a6                	mv	a1,s1
    800064ac:	854e                	mv	a0,s3
    800064ae:	ffffb097          	auipc	ra,0xffffb
    800064b2:	8a6080e7          	jalr	-1882(ra) # 80000d54 <memmove>
  stats.ncopyin++;   // XXX lock
    800064b6:	00003717          	auipc	a4,0x3
    800064ba:	b7270713          	add	a4,a4,-1166 # 80009028 <stats>
    800064be:	431c                	lw	a5,0(a4)
    800064c0:	2785                	addw	a5,a5,1
    800064c2:	c31c                	sw	a5,0(a4)
  return 0;
    800064c4:	4501                	li	a0,0
}
    800064c6:	70a2                	ld	ra,40(sp)
    800064c8:	7402                	ld	s0,32(sp)
    800064ca:	64e2                	ld	s1,24(sp)
    800064cc:	6942                	ld	s2,16(sp)
    800064ce:	69a2                	ld	s3,8(sp)
    800064d0:	6145                	add	sp,sp,48
    800064d2:	8082                	ret
    return -1;
    800064d4:	557d                	li	a0,-1
    800064d6:	bfc5                	j	800064c6 <copyin_new+0x4e>
    800064d8:	557d                	li	a0,-1
    800064da:	b7f5                	j	800064c6 <copyin_new+0x4e>
    800064dc:	557d                	li	a0,-1
    800064de:	b7e5                	j	800064c6 <copyin_new+0x4e>

00000000800064e0 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    800064e0:	7179                	add	sp,sp,-48
    800064e2:	f406                	sd	ra,40(sp)
    800064e4:	f022                	sd	s0,32(sp)
    800064e6:	ec26                	sd	s1,24(sp)
    800064e8:	e84a                	sd	s2,16(sp)
    800064ea:	e44e                	sd	s3,8(sp)
    800064ec:	1800                	add	s0,sp,48
    800064ee:	89ae                	mv	s3,a1
    800064f0:	8932                	mv	s2,a2
    800064f2:	84b6                	mv	s1,a3
  struct proc *p = myproc();
    800064f4:	ffffb097          	auipc	ra,0xffffb
    800064f8:	544080e7          	jalr	1348(ra) # 80001a38 <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    800064fc:	00003717          	auipc	a4,0x3
    80006500:	b2c70713          	add	a4,a4,-1236 # 80009028 <stats>
    80006504:	435c                	lw	a5,4(a4)
    80006506:	2785                	addw	a5,a5,1
    80006508:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    8000650a:	cc8d                	beqz	s1,80006544 <copyinstr_new+0x64>
    8000650c:	009906b3          	add	a3,s2,s1
    80006510:	87ca                	mv	a5,s2
    80006512:	6538                	ld	a4,72(a0)
    80006514:	02e7f063          	bgeu	a5,a4,80006534 <copyinstr_new+0x54>
    dst[i] = s[i];
    80006518:	0007c803          	lbu	a6,0(a5)
    8000651c:	41278733          	sub	a4,a5,s2
    80006520:	974e                	add	a4,a4,s3
    80006522:	01070023          	sb	a6,0(a4)
    if(s[i] == '\0')
    80006526:	02080163          	beqz	a6,80006548 <copyinstr_new+0x68>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    8000652a:	0785                	add	a5,a5,1
    8000652c:	fed793e3          	bne	a5,a3,80006512 <copyinstr_new+0x32>
      return 0;
  }
  return -1;
    80006530:	557d                	li	a0,-1
    80006532:	a011                	j	80006536 <copyinstr_new+0x56>
    80006534:	557d                	li	a0,-1
}
    80006536:	70a2                	ld	ra,40(sp)
    80006538:	7402                	ld	s0,32(sp)
    8000653a:	64e2                	ld	s1,24(sp)
    8000653c:	6942                	ld	s2,16(sp)
    8000653e:	69a2                	ld	s3,8(sp)
    80006540:	6145                	add	sp,sp,48
    80006542:	8082                	ret
  return -1;
    80006544:	557d                	li	a0,-1
    80006546:	bfc5                	j	80006536 <copyinstr_new+0x56>
      return 0;
    80006548:	4501                	li	a0,0
    8000654a:	b7f5                	j	80006536 <copyinstr_new+0x56>

000000008000654c <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    8000654c:	1141                	add	sp,sp,-16
    8000654e:	e422                	sd	s0,8(sp)
    80006550:	0800                	add	s0,sp,16
  return -1;
}
    80006552:	557d                	li	a0,-1
    80006554:	6422                	ld	s0,8(sp)
    80006556:	0141                	add	sp,sp,16
    80006558:	8082                	ret

000000008000655a <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    8000655a:	7179                	add	sp,sp,-48
    8000655c:	f406                	sd	ra,40(sp)
    8000655e:	f022                	sd	s0,32(sp)
    80006560:	ec26                	sd	s1,24(sp)
    80006562:	e84a                	sd	s2,16(sp)
    80006564:	e44e                	sd	s3,8(sp)
    80006566:	e052                	sd	s4,0(sp)
    80006568:	1800                	add	s0,sp,48
    8000656a:	892a                	mv	s2,a0
    8000656c:	89ae                	mv	s3,a1
    8000656e:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    80006570:	00020517          	auipc	a0,0x20
    80006574:	a9050513          	add	a0,a0,-1392 # 80026000 <stats>
    80006578:	ffffa097          	auipc	ra,0xffffa
    8000657c:	684080e7          	jalr	1668(ra) # 80000bfc <acquire>

  if(stats.sz == 0) {
    80006580:	00021797          	auipc	a5,0x21
    80006584:	a987a783          	lw	a5,-1384(a5) # 80027018 <stats+0x1018>
    80006588:	cbb5                	beqz	a5,800065fc <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    8000658a:	00021797          	auipc	a5,0x21
    8000658e:	a7678793          	add	a5,a5,-1418 # 80027000 <stats+0x1000>
    80006592:	4fd8                	lw	a4,28(a5)
    80006594:	4f9c                	lw	a5,24(a5)
    80006596:	9f99                	subw	a5,a5,a4
    80006598:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    8000659c:	06d05e63          	blez	a3,80006618 <statsread+0xbe>
    if(m > n)
    800065a0:	8a3e                	mv	s4,a5
    800065a2:	00d4d363          	bge	s1,a3,800065a8 <statsread+0x4e>
    800065a6:	8a26                	mv	s4,s1
    800065a8:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    800065ac:	86a6                	mv	a3,s1
    800065ae:	00020617          	auipc	a2,0x20
    800065b2:	a6a60613          	add	a2,a2,-1430 # 80026018 <stats+0x18>
    800065b6:	963a                	add	a2,a2,a4
    800065b8:	85ce                	mv	a1,s3
    800065ba:	854a                	mv	a0,s2
    800065bc:	ffffc097          	auipc	ra,0xffffc
    800065c0:	152080e7          	jalr	338(ra) # 8000270e <either_copyout>
    800065c4:	57fd                	li	a5,-1
    800065c6:	00f50a63          	beq	a0,a5,800065da <statsread+0x80>
      stats.off += m;
    800065ca:	00021717          	auipc	a4,0x21
    800065ce:	a3670713          	add	a4,a4,-1482 # 80027000 <stats+0x1000>
    800065d2:	4f5c                	lw	a5,28(a4)
    800065d4:	00fa07bb          	addw	a5,s4,a5
    800065d8:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    800065da:	00020517          	auipc	a0,0x20
    800065de:	a2650513          	add	a0,a0,-1498 # 80026000 <stats>
    800065e2:	ffffa097          	auipc	ra,0xffffa
    800065e6:	6ce080e7          	jalr	1742(ra) # 80000cb0 <release>
  return m;
}
    800065ea:	8526                	mv	a0,s1
    800065ec:	70a2                	ld	ra,40(sp)
    800065ee:	7402                	ld	s0,32(sp)
    800065f0:	64e2                	ld	s1,24(sp)
    800065f2:	6942                	ld	s2,16(sp)
    800065f4:	69a2                	ld	s3,8(sp)
    800065f6:	6a02                	ld	s4,0(sp)
    800065f8:	6145                	add	sp,sp,48
    800065fa:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    800065fc:	6585                	lui	a1,0x1
    800065fe:	00020517          	auipc	a0,0x20
    80006602:	a1a50513          	add	a0,a0,-1510 # 80026018 <stats+0x18>
    80006606:	00000097          	auipc	ra,0x0
    8000660a:	e16080e7          	jalr	-490(ra) # 8000641c <statscopyin>
    8000660e:	00021797          	auipc	a5,0x21
    80006612:	a0a7a523          	sw	a0,-1526(a5) # 80027018 <stats+0x1018>
    80006616:	bf95                	j	8000658a <statsread+0x30>
    stats.sz = 0;
    80006618:	00021797          	auipc	a5,0x21
    8000661c:	9e878793          	add	a5,a5,-1560 # 80027000 <stats+0x1000>
    80006620:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    80006624:	0007ae23          	sw	zero,28(a5)
    m = -1;
    80006628:	54fd                	li	s1,-1
    8000662a:	bf45                	j	800065da <statsread+0x80>

000000008000662c <statsinit>:

void
statsinit(void)
{
    8000662c:	1141                	add	sp,sp,-16
    8000662e:	e406                	sd	ra,8(sp)
    80006630:	e022                	sd	s0,0(sp)
    80006632:	0800                	add	s0,sp,16
  initlock(&stats.lock, "stats");
    80006634:	00002597          	auipc	a1,0x2
    80006638:	25c58593          	add	a1,a1,604 # 80008890 <syscalls+0x400>
    8000663c:	00020517          	auipc	a0,0x20
    80006640:	9c450513          	add	a0,a0,-1596 # 80026000 <stats>
    80006644:	ffffa097          	auipc	ra,0xffffa
    80006648:	528080e7          	jalr	1320(ra) # 80000b6c <initlock>

  devsw[STATS].read = statsread;
    8000664c:	0001b797          	auipc	a5,0x1b
    80006650:	56478793          	add	a5,a5,1380 # 80021bb0 <devsw>
    80006654:	00000717          	auipc	a4,0x0
    80006658:	f0670713          	add	a4,a4,-250 # 8000655a <statsread>
    8000665c:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    8000665e:	00000717          	auipc	a4,0x0
    80006662:	eee70713          	add	a4,a4,-274 # 8000654c <statswrite>
    80006666:	f798                	sd	a4,40(a5)
}
    80006668:	60a2                	ld	ra,8(sp)
    8000666a:	6402                	ld	s0,0(sp)
    8000666c:	0141                	add	sp,sp,16
    8000666e:	8082                	ret

0000000080006670 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    80006670:	1101                	add	sp,sp,-32
    80006672:	ec22                	sd	s0,24(sp)
    80006674:	1000                	add	s0,sp,32
    80006676:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    80006678:	c299                	beqz	a3,8000667e <sprintint+0xe>
    8000667a:	0805c263          	bltz	a1,800066fe <sprintint+0x8e>
    x = -xx;
  else
    x = xx;
    8000667e:	2581                	sext.w	a1,a1
    80006680:	4301                	li	t1,0

  i = 0;
    80006682:	fe040713          	add	a4,s0,-32
    80006686:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    80006688:	2601                	sext.w	a2,a2
    8000668a:	00002697          	auipc	a3,0x2
    8000668e:	20e68693          	add	a3,a3,526 # 80008898 <digits>
    80006692:	88aa                	mv	a7,a0
    80006694:	2505                	addw	a0,a0,1
    80006696:	02c5f7bb          	remuw	a5,a1,a2
    8000669a:	1782                	sll	a5,a5,0x20
    8000669c:	9381                	srl	a5,a5,0x20
    8000669e:	97b6                	add	a5,a5,a3
    800066a0:	0007c783          	lbu	a5,0(a5)
    800066a4:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    800066a8:	0005879b          	sext.w	a5,a1
    800066ac:	02c5d5bb          	divuw	a1,a1,a2
    800066b0:	0705                	add	a4,a4,1
    800066b2:	fec7f0e3          	bgeu	a5,a2,80006692 <sprintint+0x22>

  if(sign)
    800066b6:	00030b63          	beqz	t1,800066cc <sprintint+0x5c>
    buf[i++] = '-';
    800066ba:	ff050793          	add	a5,a0,-16
    800066be:	97a2                	add	a5,a5,s0
    800066c0:	02d00713          	li	a4,45
    800066c4:	fee78823          	sb	a4,-16(a5)
    800066c8:	0028851b          	addw	a0,a7,2

  n = 0;
  while(--i >= 0)
    800066cc:	02a05d63          	blez	a0,80006706 <sprintint+0x96>
    800066d0:	fe040793          	add	a5,s0,-32
    800066d4:	00a78733          	add	a4,a5,a0
    800066d8:	87c2                	mv	a5,a6
    800066da:	00180613          	add	a2,a6,1
    800066de:	fff5069b          	addw	a3,a0,-1
    800066e2:	1682                	sll	a3,a3,0x20
    800066e4:	9281                	srl	a3,a3,0x20
    800066e6:	9636                	add	a2,a2,a3
  *s = c;
    800066e8:	fff74683          	lbu	a3,-1(a4)
    800066ec:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    800066f0:	177d                	add	a4,a4,-1
    800066f2:	0785                	add	a5,a5,1
    800066f4:	fec79ae3          	bne	a5,a2,800066e8 <sprintint+0x78>
    n += sputc(s+n, buf[i]);
  return n;
}
    800066f8:	6462                	ld	s0,24(sp)
    800066fa:	6105                	add	sp,sp,32
    800066fc:	8082                	ret
    x = -xx;
    800066fe:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    80006702:	4305                	li	t1,1
    x = -xx;
    80006704:	bfbd                	j	80006682 <sprintint+0x12>
  while(--i >= 0)
    80006706:	4501                	li	a0,0
    80006708:	bfc5                	j	800066f8 <sprintint+0x88>

000000008000670a <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    8000670a:	7135                	add	sp,sp,-160
    8000670c:	f486                	sd	ra,104(sp)
    8000670e:	f0a2                	sd	s0,96(sp)
    80006710:	eca6                	sd	s1,88(sp)
    80006712:	e8ca                	sd	s2,80(sp)
    80006714:	e4ce                	sd	s3,72(sp)
    80006716:	e0d2                	sd	s4,64(sp)
    80006718:	fc56                	sd	s5,56(sp)
    8000671a:	f85a                	sd	s6,48(sp)
    8000671c:	f45e                	sd	s7,40(sp)
    8000671e:	f062                	sd	s8,32(sp)
    80006720:	ec66                	sd	s9,24(sp)
    80006722:	1880                	add	s0,sp,112
    80006724:	e414                	sd	a3,8(s0)
    80006726:	e818                	sd	a4,16(s0)
    80006728:	ec1c                	sd	a5,24(s0)
    8000672a:	03043023          	sd	a6,32(s0)
    8000672e:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    80006732:	c60d                	beqz	a2,8000675c <snprintf+0x52>
    80006734:	8baa                	mv	s7,a0
    80006736:	8aae                	mv	s5,a1
    80006738:	89b2                	mv	s3,a2
    panic("null fmt");

  va_start(ap, fmt);
    8000673a:	00840793          	add	a5,s0,8
    8000673e:	f8f43c23          	sd	a5,-104(s0)
  int off = 0;
    80006742:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006744:	4901                	li	s2,0
    80006746:	02b05363          	blez	a1,8000676c <snprintf+0x62>
    if(c != '%'){
    8000674a:	02500a13          	li	s4,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    8000674e:	07300b13          	li	s6,115
    80006752:	07800c93          	li	s9,120
    80006756:	06400c13          	li	s8,100
    8000675a:	a01d                	j	80006780 <snprintf+0x76>
    panic("null fmt");
    8000675c:	00002517          	auipc	a0,0x2
    80006760:	8bc50513          	add	a0,a0,-1860 # 80008018 <etext+0x18>
    80006764:	ffffa097          	auipc	ra,0xffffa
    80006768:	dde080e7          	jalr	-546(ra) # 80000542 <panic>
  int off = 0;
    8000676c:	4481                	li	s1,0
    8000676e:	a0f9                	j	8000683c <snprintf+0x132>
  *s = c;
    80006770:	009b8733          	add	a4,s7,s1
    80006774:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006778:	2485                	addw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000677a:	2905                	addw	s2,s2,1
    8000677c:	0d54d063          	bge	s1,s5,8000683c <snprintf+0x132>
    80006780:	012987b3          	add	a5,s3,s2
    80006784:	0007c783          	lbu	a5,0(a5)
    80006788:	0007871b          	sext.w	a4,a5
    8000678c:	cbc5                	beqz	a5,8000683c <snprintf+0x132>
    if(c != '%'){
    8000678e:	ff4711e3          	bne	a4,s4,80006770 <snprintf+0x66>
    c = fmt[++i] & 0xff;
    80006792:	2905                	addw	s2,s2,1
    80006794:	012987b3          	add	a5,s3,s2
    80006798:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    8000679c:	c3c5                	beqz	a5,8000683c <snprintf+0x132>
    switch(c){
    8000679e:	05678c63          	beq	a5,s6,800067f6 <snprintf+0xec>
    800067a2:	02fb6763          	bltu	s6,a5,800067d0 <snprintf+0xc6>
    800067a6:	0d478063          	beq	a5,s4,80006866 <snprintf+0x15c>
    800067aa:	0d879463          	bne	a5,s8,80006872 <snprintf+0x168>
    case 'd':
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    800067ae:	f9843783          	ld	a5,-104(s0)
    800067b2:	00878713          	add	a4,a5,8
    800067b6:	f8e43c23          	sd	a4,-104(s0)
    800067ba:	4685                	li	a3,1
    800067bc:	4629                	li	a2,10
    800067be:	438c                	lw	a1,0(a5)
    800067c0:	009b8533          	add	a0,s7,s1
    800067c4:	00000097          	auipc	ra,0x0
    800067c8:	eac080e7          	jalr	-340(ra) # 80006670 <sprintint>
    800067cc:	9ca9                	addw	s1,s1,a0
      break;
    800067ce:	b775                	j	8000677a <snprintf+0x70>
    switch(c){
    800067d0:	0b979163          	bne	a5,s9,80006872 <snprintf+0x168>
    case 'x':
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    800067d4:	f9843783          	ld	a5,-104(s0)
    800067d8:	00878713          	add	a4,a5,8
    800067dc:	f8e43c23          	sd	a4,-104(s0)
    800067e0:	4685                	li	a3,1
    800067e2:	4641                	li	a2,16
    800067e4:	438c                	lw	a1,0(a5)
    800067e6:	009b8533          	add	a0,s7,s1
    800067ea:	00000097          	auipc	ra,0x0
    800067ee:	e86080e7          	jalr	-378(ra) # 80006670 <sprintint>
    800067f2:	9ca9                	addw	s1,s1,a0
      break;
    800067f4:	b759                	j	8000677a <snprintf+0x70>
    case 's':
      if((s = va_arg(ap, char*)) == 0)
    800067f6:	f9843783          	ld	a5,-104(s0)
    800067fa:	00878713          	add	a4,a5,8
    800067fe:	f8e43c23          	sd	a4,-104(s0)
    80006802:	6388                	ld	a0,0(a5)
    80006804:	c931                	beqz	a0,80006858 <snprintf+0x14e>
        s = "(null)";
      for(; *s && off < sz; s++)
    80006806:	00054703          	lbu	a4,0(a0)
    8000680a:	db25                	beqz	a4,8000677a <snprintf+0x70>
    8000680c:	0354d863          	bge	s1,s5,8000683c <snprintf+0x132>
    80006810:	009b86b3          	add	a3,s7,s1
    80006814:	409a863b          	subw	a2,s5,s1
    80006818:	1602                	sll	a2,a2,0x20
    8000681a:	9201                	srl	a2,a2,0x20
    8000681c:	962a                	add	a2,a2,a0
    8000681e:	87aa                	mv	a5,a0
        off += sputc(buf+off, *s);
    80006820:	0014859b          	addw	a1,s1,1
    80006824:	9d89                	subw	a1,a1,a0
  *s = c;
    80006826:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    8000682a:	00f584bb          	addw	s1,a1,a5
      for(; *s && off < sz; s++)
    8000682e:	0785                	add	a5,a5,1
    80006830:	0007c703          	lbu	a4,0(a5)
    80006834:	d339                	beqz	a4,8000677a <snprintf+0x70>
    80006836:	0685                	add	a3,a3,1
    80006838:	fec797e3          	bne	a5,a2,80006826 <snprintf+0x11c>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    8000683c:	8526                	mv	a0,s1
    8000683e:	70a6                	ld	ra,104(sp)
    80006840:	7406                	ld	s0,96(sp)
    80006842:	64e6                	ld	s1,88(sp)
    80006844:	6946                	ld	s2,80(sp)
    80006846:	69a6                	ld	s3,72(sp)
    80006848:	6a06                	ld	s4,64(sp)
    8000684a:	7ae2                	ld	s5,56(sp)
    8000684c:	7b42                	ld	s6,48(sp)
    8000684e:	7ba2                	ld	s7,40(sp)
    80006850:	7c02                	ld	s8,32(sp)
    80006852:	6ce2                	ld	s9,24(sp)
    80006854:	610d                	add	sp,sp,160
    80006856:	8082                	ret
      for(; *s && off < sz; s++)
    80006858:	02800713          	li	a4,40
        s = "(null)";
    8000685c:	00001517          	auipc	a0,0x1
    80006860:	7b450513          	add	a0,a0,1972 # 80008010 <etext+0x10>
    80006864:	b765                	j	8000680c <snprintf+0x102>
  *s = c;
    80006866:	009b87b3          	add	a5,s7,s1
    8000686a:	01478023          	sb	s4,0(a5)
      off += sputc(buf+off, '%');
    8000686e:	2485                	addw	s1,s1,1
      break;
    80006870:	b729                	j	8000677a <snprintf+0x70>
  *s = c;
    80006872:	009b8733          	add	a4,s7,s1
    80006876:	01470023          	sb	s4,0(a4)
      off += sputc(buf+off, c);
    8000687a:	0014871b          	addw	a4,s1,1
  *s = c;
    8000687e:	975e                	add	a4,a4,s7
    80006880:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006884:	2489                	addw	s1,s1,2
      break;
    80006886:	bdd5                	j	8000677a <snprintf+0x70>
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
