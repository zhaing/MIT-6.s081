
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
    80000060:	e4478793          	add	a5,a5,-444 # 80005ea0 <timervec>
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
    80000094:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd07ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	ee878793          	add	a5,a5,-280 # 80000f8e <main>
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
    80000110:	bda080e7          	jalr	-1062(ra) # 80000ce6 <acquire>
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
    8000012a:	6aa080e7          	jalr	1706(ra) # 800027d0 <either_copyin>
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
    80000154:	c4a080e7          	jalr	-950(ra) # 80000d9a <release>

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
    8000019c:	b4e080e7          	jalr	-1202(ra) # 80000ce6 <acquire>
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
    800001c4:	b4a080e7          	jalr	-1206(ra) # 80001d0a <myproc>
    800001c8:	591c                	lw	a5,48(a0)
    800001ca:	efad                	bnez	a5,80000244 <consoleread+0xd4>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	350080e7          	jalr	848(ra) # 80002520 <sleep>
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
    8000021a:	564080e7          	jalr	1380(ra) # 8000277a <either_copyout>
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
    8000023a:	b64080e7          	jalr	-1180(ra) # 80000d9a <release>

  return target - n;
    8000023e:	413b053b          	subw	a0,s6,s3
    80000242:	a811                	j	80000256 <consoleread+0xe6>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	add	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	b4e080e7          	jalr	-1202(ra) # 80000d9a <release>
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
    800002da:	a10080e7          	jalr	-1520(ra) # 80000ce6 <acquire>

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
    800002f8:	532080e7          	jalr	1330(ra) # 80002826 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fc:	00011517          	auipc	a0,0x11
    80000300:	53450513          	add	a0,a0,1332 # 80011830 <cons>
    80000304:	00001097          	auipc	ra,0x1
    80000308:	a96080e7          	jalr	-1386(ra) # 80000d9a <release>
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
    8000044c:	258080e7          	jalr	600(ra) # 800026a0 <wakeup>
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
    8000046e:	7ec080e7          	jalr	2028(ra) # 80000c56 <initlock>

  uartinit();
    80000472:	00000097          	auipc	ra,0x0
    80000476:	32c080e7          	jalr	812(ra) # 8000079e <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047a:	00029797          	auipc	a5,0x29
    8000047e:	53678793          	add	a5,a5,1334 # 800299b0 <devsw>
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
    80000608:	6e2080e7          	jalr	1762(ra) # 80000ce6 <acquire>
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
    80000766:	638080e7          	jalr	1592(ra) # 80000d9a <release>
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
    8000078c:	4ce080e7          	jalr	1230(ra) # 80000c56 <initlock>
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
    800007e2:	478080e7          	jalr	1144(ra) # 80000c56 <initlock>
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
    800007fe:	4a0080e7          	jalr	1184(ra) # 80000c9a <push_off>

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
    8000082c:	512080e7          	jalr	1298(ra) # 80000d3a <pop_off>
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
    800008a6:	dfe080e7          	jalr	-514(ra) # 800026a0 <wakeup>
    
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
    800008ea:	400080e7          	jalr	1024(ra) # 80000ce6 <acquire>
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
    80000940:	be4080e7          	jalr	-1052(ra) # 80002520 <sleep>
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
    80000986:	418080e7          	jalr	1048(ra) # 80000d9a <release>
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
    800009ee:	2fc080e7          	jalr	764(ra) # 80000ce6 <acquire>
  uartstart();
    800009f2:	00000097          	auipc	ra,0x0
    800009f6:	e48080e7          	jalr	-440(ra) # 8000083a <uartstart>
  release(&uart_tx_lock);
    800009fa:	8526                	mv	a0,s1
    800009fc:	00000097          	auipc	ra,0x0
    80000a00:	39e080e7          	jalr	926(ra) # 80000d9a <release>
}
    80000a04:	60e2                	ld	ra,24(sp)
    80000a06:	6442                	ld	s0,16(sp)
    80000a08:	64a2                	ld	s1,8(sp)
    80000a0a:	6105                	add	sp,sp,32
    80000a0c:	8082                	ret

0000000080000a0e <cownum>:
  struct spinlock lock;
  struct run *freelist;
} kmem;

void
cownum(void *pa, uint8 flag){
    80000a0e:	1101                	add	sp,sp,-32
    80000a10:	ec06                	sd	ra,24(sp)
    80000a12:	e822                	sd	s0,16(sp)
    80000a14:	e426                	sd	s1,8(sp)
    80000a16:	e04a                	sd	s2,0(sp)
    80000a18:	1000                	add	s0,sp,32
    80000a1a:	84aa                	mv	s1,a0
    80000a1c:	892e                	mv	s2,a1
  acquire(&kmem.lock);
    80000a1e:	00011517          	auipc	a0,0x11
    80000a22:	f1250513          	add	a0,a0,-238 # 80011930 <kmem>
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	2c0080e7          	jalr	704(ra) # 80000ce6 <acquire>
  if(flag) page_cow[COW_INDEX(pa)]++;
    80000a2e:	02090e63          	beqz	s2,80000a6a <cownum+0x5c>
    80000a32:	800007b7          	lui	a5,0x80000
    80000a36:	94be                	add	s1,s1,a5
    80000a38:	80b1                	srl	s1,s1,0xc
    80000a3a:	00011797          	auipc	a5,0x11
    80000a3e:	f1678793          	add	a5,a5,-234 # 80011950 <page_cow>
    80000a42:	97a6                	add	a5,a5,s1
    80000a44:	0007c703          	lbu	a4,0(a5)
    80000a48:	2705                	addw	a4,a4,1
    80000a4a:	00e78023          	sb	a4,0(a5)
  else page_cow[COW_INDEX(pa)]--;
  release(&kmem.lock);
    80000a4e:	00011517          	auipc	a0,0x11
    80000a52:	ee250513          	add	a0,a0,-286 # 80011930 <kmem>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	344080e7          	jalr	836(ra) # 80000d9a <release>
}
    80000a5e:	60e2                	ld	ra,24(sp)
    80000a60:	6442                	ld	s0,16(sp)
    80000a62:	64a2                	ld	s1,8(sp)
    80000a64:	6902                	ld	s2,0(sp)
    80000a66:	6105                	add	sp,sp,32
    80000a68:	8082                	ret
  else page_cow[COW_INDEX(pa)]--;
    80000a6a:	800007b7          	lui	a5,0x80000
    80000a6e:	94be                	add	s1,s1,a5
    80000a70:	80b1                	srl	s1,s1,0xc
    80000a72:	00011797          	auipc	a5,0x11
    80000a76:	ede78793          	add	a5,a5,-290 # 80011950 <page_cow>
    80000a7a:	97a6                	add	a5,a5,s1
    80000a7c:	0007c703          	lbu	a4,0(a5)
    80000a80:	377d                	addw	a4,a4,-1
    80000a82:	00e78023          	sb	a4,0(a5)
    80000a86:	b7e1                	j	80000a4e <cownum+0x40>

0000000080000a88 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a88:	7179                	add	sp,sp,-48
    80000a8a:	f406                	sd	ra,40(sp)
    80000a8c:	f022                	sd	s0,32(sp)
    80000a8e:	ec26                	sd	s1,24(sp)
    80000a90:	e84a                	sd	s2,16(sp)
    80000a92:	e44e                	sd	s3,8(sp)
    80000a94:	1800                	add	s0,sp,48
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a96:	03451793          	sll	a5,a0,0x34
    80000a9a:	efc9                	bnez	a5,80000b34 <kfree+0xac>
    80000a9c:	84aa                	mv	s1,a0
    80000a9e:	0002d797          	auipc	a5,0x2d
    80000aa2:	56278793          	add	a5,a5,1378 # 8002e000 <end>
    80000aa6:	08f56763          	bltu	a0,a5,80000b34 <kfree+0xac>
    80000aaa:	47c5                	li	a5,17
    80000aac:	07ee                	sll	a5,a5,0x1b
    80000aae:	08f57363          	bgeu	a0,a5,80000b34 <kfree+0xac>
    panic("kfree");
 //lab6
  //cownum(pa,0);
  if(page_cow[COW_INDEX(pa)]>1){
    80000ab2:	80000937          	lui	s2,0x80000
    80000ab6:	992a                	add	s2,s2,a0
    80000ab8:	00c95913          	srl	s2,s2,0xc
    80000abc:	00011797          	auipc	a5,0x11
    80000ac0:	e9478793          	add	a5,a5,-364 # 80011950 <page_cow>
    80000ac4:	97ca                	add	a5,a5,s2
    80000ac6:	0007c703          	lbu	a4,0(a5)
    80000aca:	4785                	li	a5,1
    80000acc:	06e7ec63          	bltu	a5,a4,80000b44 <kfree+0xbc>
    cownum(pa,0);//page_cow[COW_INDEX(pa)]--;
    return;
  }
  acquire(&kmem.lock);
    80000ad0:	00011997          	auipc	s3,0x11
    80000ad4:	e6098993          	add	s3,s3,-416 # 80011930 <kmem>
    80000ad8:	854e                	mv	a0,s3
    80000ada:	00000097          	auipc	ra,0x0
    80000ade:	20c080e7          	jalr	524(ra) # 80000ce6 <acquire>
  page_cow[COW_INDEX(pa)]=0;
    80000ae2:	00011797          	auipc	a5,0x11
    80000ae6:	e6e78793          	add	a5,a5,-402 # 80011950 <page_cow>
    80000aea:	97ca                	add	a5,a5,s2
    80000aec:	00078023          	sb	zero,0(a5)
  release(&kmem.lock); 
    80000af0:	854e                	mv	a0,s3
    80000af2:	00000097          	auipc	ra,0x0
    80000af6:	2a8080e7          	jalr	680(ra) # 80000d9a <release>
  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000afa:	6605                	lui	a2,0x1
    80000afc:	4585                	li	a1,1
    80000afe:	8526                	mv	a0,s1
    80000b00:	00000097          	auipc	ra,0x0
    80000b04:	2e2080e7          	jalr	738(ra) # 80000de2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000b08:	854e                	mv	a0,s3
    80000b0a:	00000097          	auipc	ra,0x0
    80000b0e:	1dc080e7          	jalr	476(ra) # 80000ce6 <acquire>
  r->next = kmem.freelist;
    80000b12:	0189b783          	ld	a5,24(s3)
    80000b16:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000b18:	0099bc23          	sd	s1,24(s3)
  release(&kmem.lock);
    80000b1c:	854e                	mv	a0,s3
    80000b1e:	00000097          	auipc	ra,0x0
    80000b22:	27c080e7          	jalr	636(ra) # 80000d9a <release>
}
    80000b26:	70a2                	ld	ra,40(sp)
    80000b28:	7402                	ld	s0,32(sp)
    80000b2a:	64e2                	ld	s1,24(sp)
    80000b2c:	6942                	ld	s2,16(sp)
    80000b2e:	69a2                	ld	s3,8(sp)
    80000b30:	6145                	add	sp,sp,48
    80000b32:	8082                	ret
    panic("kfree");
    80000b34:	00007517          	auipc	a0,0x7
    80000b38:	52c50513          	add	a0,a0,1324 # 80008060 <digits+0x20>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	a06080e7          	jalr	-1530(ra) # 80000542 <panic>
    cownum(pa,0);//page_cow[COW_INDEX(pa)]--;
    80000b44:	4581                	li	a1,0
    80000b46:	00000097          	auipc	ra,0x0
    80000b4a:	ec8080e7          	jalr	-312(ra) # 80000a0e <cownum>
    return;
    80000b4e:	bfe1                	j	80000b26 <kfree+0x9e>

0000000080000b50 <freerange>:
{
    80000b50:	7139                	add	sp,sp,-64
    80000b52:	fc06                	sd	ra,56(sp)
    80000b54:	f822                	sd	s0,48(sp)
    80000b56:	f426                	sd	s1,40(sp)
    80000b58:	f04a                	sd	s2,32(sp)
    80000b5a:	ec4e                	sd	s3,24(sp)
    80000b5c:	e852                	sd	s4,16(sp)
    80000b5e:	e456                	sd	s5,8(sp)
    80000b60:	0080                	add	s0,sp,64
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b62:	6785                	lui	a5,0x1
    80000b64:	fff78713          	add	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000b68:	00e504b3          	add	s1,a0,a4
    80000b6c:	777d                	lui	a4,0xfffff
    80000b6e:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000b70:	94be                	add	s1,s1,a5
    80000b72:	0295e563          	bltu	a1,s1,80000b9c <freerange+0x4c>
    80000b76:	89ae                	mv	s3,a1
    80000b78:	7afd                	lui	s5,0xfffff
    80000b7a:	6a05                	lui	s4,0x1
    80000b7c:	01548933          	add	s2,s1,s5
    cownum(p,1);
    80000b80:	4585                	li	a1,1
    80000b82:	854a                	mv	a0,s2
    80000b84:	00000097          	auipc	ra,0x0
    80000b88:	e8a080e7          	jalr	-374(ra) # 80000a0e <cownum>
    kfree(p);
    80000b8c:	854a                	mv	a0,s2
    80000b8e:	00000097          	auipc	ra,0x0
    80000b92:	efa080e7          	jalr	-262(ra) # 80000a88 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000b96:	94d2                	add	s1,s1,s4
    80000b98:	fe99f2e3          	bgeu	s3,s1,80000b7c <freerange+0x2c>
}
    80000b9c:	70e2                	ld	ra,56(sp)
    80000b9e:	7442                	ld	s0,48(sp)
    80000ba0:	74a2                	ld	s1,40(sp)
    80000ba2:	7902                	ld	s2,32(sp)
    80000ba4:	69e2                	ld	s3,24(sp)
    80000ba6:	6a42                	ld	s4,16(sp)
    80000ba8:	6aa2                	ld	s5,8(sp)
    80000baa:	6121                	add	sp,sp,64
    80000bac:	8082                	ret

0000000080000bae <kinit>:
{
    80000bae:	1141                	add	sp,sp,-16
    80000bb0:	e406                	sd	ra,8(sp)
    80000bb2:	e022                	sd	s0,0(sp)
    80000bb4:	0800                	add	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000bb6:	00007597          	auipc	a1,0x7
    80000bba:	4b258593          	add	a1,a1,1202 # 80008068 <digits+0x28>
    80000bbe:	00011517          	auipc	a0,0x11
    80000bc2:	d7250513          	add	a0,a0,-654 # 80011930 <kmem>
    80000bc6:	00000097          	auipc	ra,0x0
    80000bca:	090080e7          	jalr	144(ra) # 80000c56 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000bce:	45c5                	li	a1,17
    80000bd0:	05ee                	sll	a1,a1,0x1b
    80000bd2:	0002d517          	auipc	a0,0x2d
    80000bd6:	42e50513          	add	a0,a0,1070 # 8002e000 <end>
    80000bda:	00000097          	auipc	ra,0x0
    80000bde:	f76080e7          	jalr	-138(ra) # 80000b50 <freerange>
}
    80000be2:	60a2                	ld	ra,8(sp)
    80000be4:	6402                	ld	s0,0(sp)
    80000be6:	0141                	add	sp,sp,16
    80000be8:	8082                	ret

0000000080000bea <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000bea:	1101                	add	sp,sp,-32
    80000bec:	ec06                	sd	ra,24(sp)
    80000bee:	e822                	sd	s0,16(sp)
    80000bf0:	e426                	sd	s1,8(sp)
    80000bf2:	1000                	add	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000bf4:	00011497          	auipc	s1,0x11
    80000bf8:	d3c48493          	add	s1,s1,-708 # 80011930 <kmem>
    80000bfc:	8526                	mv	a0,s1
    80000bfe:	00000097          	auipc	ra,0x0
    80000c02:	0e8080e7          	jalr	232(ra) # 80000ce6 <acquire>
  r = kmem.freelist;
    80000c06:	6c84                	ld	s1,24(s1)
  if(r){
    80000c08:	cc95                	beqz	s1,80000c44 <kalloc+0x5a>
    kmem.freelist = r->next;
    80000c0a:	609c                	ld	a5,0(s1)
    80000c0c:	00011517          	auipc	a0,0x11
    80000c10:	d2450513          	add	a0,a0,-732 # 80011930 <kmem>
    80000c14:	ed1c                	sd	a5,24(a0)
    //page_cow[COW_INDEX(r)]=1;
  }
  release(&kmem.lock);
    80000c16:	00000097          	auipc	ra,0x0
    80000c1a:	184080e7          	jalr	388(ra) # 80000d9a <release>

  if(r){
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000c1e:	6605                	lui	a2,0x1
    80000c20:	4595                	li	a1,5
    80000c22:	8526                	mv	a0,s1
    80000c24:	00000097          	auipc	ra,0x0
    80000c28:	1be080e7          	jalr	446(ra) # 80000de2 <memset>
    //acquire(&kmem.lock);
    cownum(r,1);//page_cow[COW_INDEX(r)]=1;
    80000c2c:	4585                	li	a1,1
    80000c2e:	8526                	mv	a0,s1
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	dde080e7          	jalr	-546(ra) # 80000a0e <cownum>
    //release(&kmem.lock);
  }
  return (void*)r;
}
    80000c38:	8526                	mv	a0,s1
    80000c3a:	60e2                	ld	ra,24(sp)
    80000c3c:	6442                	ld	s0,16(sp)
    80000c3e:	64a2                	ld	s1,8(sp)
    80000c40:	6105                	add	sp,sp,32
    80000c42:	8082                	ret
  release(&kmem.lock);
    80000c44:	00011517          	auipc	a0,0x11
    80000c48:	cec50513          	add	a0,a0,-788 # 80011930 <kmem>
    80000c4c:	00000097          	auipc	ra,0x0
    80000c50:	14e080e7          	jalr	334(ra) # 80000d9a <release>
  if(r){
    80000c54:	b7d5                	j	80000c38 <kalloc+0x4e>

0000000080000c56 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c56:	1141                	add	sp,sp,-16
    80000c58:	e422                	sd	s0,8(sp)
    80000c5a:	0800                	add	s0,sp,16
  lk->name = name;
    80000c5c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c5e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c62:	00053823          	sd	zero,16(a0)
}
    80000c66:	6422                	ld	s0,8(sp)
    80000c68:	0141                	add	sp,sp,16
    80000c6a:	8082                	ret

0000000080000c6c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c6c:	411c                	lw	a5,0(a0)
    80000c6e:	e399                	bnez	a5,80000c74 <holding+0x8>
    80000c70:	4501                	li	a0,0
  return r;
}
    80000c72:	8082                	ret
{
    80000c74:	1101                	add	sp,sp,-32
    80000c76:	ec06                	sd	ra,24(sp)
    80000c78:	e822                	sd	s0,16(sp)
    80000c7a:	e426                	sd	s1,8(sp)
    80000c7c:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c7e:	6904                	ld	s1,16(a0)
    80000c80:	00001097          	auipc	ra,0x1
    80000c84:	06e080e7          	jalr	110(ra) # 80001cee <mycpu>
    80000c88:	40a48533          	sub	a0,s1,a0
    80000c8c:	00153513          	seqz	a0,a0
}
    80000c90:	60e2                	ld	ra,24(sp)
    80000c92:	6442                	ld	s0,16(sp)
    80000c94:	64a2                	ld	s1,8(sp)
    80000c96:	6105                	add	sp,sp,32
    80000c98:	8082                	ret

0000000080000c9a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c9a:	1101                	add	sp,sp,-32
    80000c9c:	ec06                	sd	ra,24(sp)
    80000c9e:	e822                	sd	s0,16(sp)
    80000ca0:	e426                	sd	s1,8(sp)
    80000ca2:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ca4:	100024f3          	csrr	s1,sstatus
    80000ca8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000cac:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cae:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cb2:	00001097          	auipc	ra,0x1
    80000cb6:	03c080e7          	jalr	60(ra) # 80001cee <mycpu>
    80000cba:	5d3c                	lw	a5,120(a0)
    80000cbc:	cf89                	beqz	a5,80000cd6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000cbe:	00001097          	auipc	ra,0x1
    80000cc2:	030080e7          	jalr	48(ra) # 80001cee <mycpu>
    80000cc6:	5d3c                	lw	a5,120(a0)
    80000cc8:	2785                	addw	a5,a5,1
    80000cca:	dd3c                	sw	a5,120(a0)
}
    80000ccc:	60e2                	ld	ra,24(sp)
    80000cce:	6442                	ld	s0,16(sp)
    80000cd0:	64a2                	ld	s1,8(sp)
    80000cd2:	6105                	add	sp,sp,32
    80000cd4:	8082                	ret
    mycpu()->intena = old;
    80000cd6:	00001097          	auipc	ra,0x1
    80000cda:	018080e7          	jalr	24(ra) # 80001cee <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cde:	8085                	srl	s1,s1,0x1
    80000ce0:	8885                	and	s1,s1,1
    80000ce2:	dd64                	sw	s1,124(a0)
    80000ce4:	bfe9                	j	80000cbe <push_off+0x24>

0000000080000ce6 <acquire>:
{
    80000ce6:	1101                	add	sp,sp,-32
    80000ce8:	ec06                	sd	ra,24(sp)
    80000cea:	e822                	sd	s0,16(sp)
    80000cec:	e426                	sd	s1,8(sp)
    80000cee:	1000                	add	s0,sp,32
    80000cf0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000cf2:	00000097          	auipc	ra,0x0
    80000cf6:	fa8080e7          	jalr	-88(ra) # 80000c9a <push_off>
  if(holding(lk))
    80000cfa:	8526                	mv	a0,s1
    80000cfc:	00000097          	auipc	ra,0x0
    80000d00:	f70080e7          	jalr	-144(ra) # 80000c6c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d04:	4705                	li	a4,1
  if(holding(lk))
    80000d06:	e115                	bnez	a0,80000d2a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d08:	87ba                	mv	a5,a4
    80000d0a:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d0e:	2781                	sext.w	a5,a5
    80000d10:	ffe5                	bnez	a5,80000d08 <acquire+0x22>
  __sync_synchronize();
    80000d12:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d16:	00001097          	auipc	ra,0x1
    80000d1a:	fd8080e7          	jalr	-40(ra) # 80001cee <mycpu>
    80000d1e:	e888                	sd	a0,16(s1)
}
    80000d20:	60e2                	ld	ra,24(sp)
    80000d22:	6442                	ld	s0,16(sp)
    80000d24:	64a2                	ld	s1,8(sp)
    80000d26:	6105                	add	sp,sp,32
    80000d28:	8082                	ret
    panic("acquire");
    80000d2a:	00007517          	auipc	a0,0x7
    80000d2e:	34650513          	add	a0,a0,838 # 80008070 <digits+0x30>
    80000d32:	00000097          	auipc	ra,0x0
    80000d36:	810080e7          	jalr	-2032(ra) # 80000542 <panic>

0000000080000d3a <pop_off>:

void
pop_off(void)
{
    80000d3a:	1141                	add	sp,sp,-16
    80000d3c:	e406                	sd	ra,8(sp)
    80000d3e:	e022                	sd	s0,0(sp)
    80000d40:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    80000d42:	00001097          	auipc	ra,0x1
    80000d46:	fac080e7          	jalr	-84(ra) # 80001cee <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d4a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d4e:	8b89                	and	a5,a5,2
  if(intr_get())
    80000d50:	e78d                	bnez	a5,80000d7a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d52:	5d3c                	lw	a5,120(a0)
    80000d54:	02f05b63          	blez	a5,80000d8a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d58:	37fd                	addw	a5,a5,-1
    80000d5a:	0007871b          	sext.w	a4,a5
    80000d5e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d60:	eb09                	bnez	a4,80000d72 <pop_off+0x38>
    80000d62:	5d7c                	lw	a5,124(a0)
    80000d64:	c799                	beqz	a5,80000d72 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d66:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d6a:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d6e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d72:	60a2                	ld	ra,8(sp)
    80000d74:	6402                	ld	s0,0(sp)
    80000d76:	0141                	add	sp,sp,16
    80000d78:	8082                	ret
    panic("pop_off - interruptible");
    80000d7a:	00007517          	auipc	a0,0x7
    80000d7e:	2fe50513          	add	a0,a0,766 # 80008078 <digits+0x38>
    80000d82:	fffff097          	auipc	ra,0xfffff
    80000d86:	7c0080e7          	jalr	1984(ra) # 80000542 <panic>
    panic("pop_off");
    80000d8a:	00007517          	auipc	a0,0x7
    80000d8e:	30650513          	add	a0,a0,774 # 80008090 <digits+0x50>
    80000d92:	fffff097          	auipc	ra,0xfffff
    80000d96:	7b0080e7          	jalr	1968(ra) # 80000542 <panic>

0000000080000d9a <release>:
{
    80000d9a:	1101                	add	sp,sp,-32
    80000d9c:	ec06                	sd	ra,24(sp)
    80000d9e:	e822                	sd	s0,16(sp)
    80000da0:	e426                	sd	s1,8(sp)
    80000da2:	1000                	add	s0,sp,32
    80000da4:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000da6:	00000097          	auipc	ra,0x0
    80000daa:	ec6080e7          	jalr	-314(ra) # 80000c6c <holding>
    80000dae:	c115                	beqz	a0,80000dd2 <release+0x38>
  lk->cpu = 0;
    80000db0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000db4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000db8:	0f50000f          	fence	iorw,ow
    80000dbc:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000dc0:	00000097          	auipc	ra,0x0
    80000dc4:	f7a080e7          	jalr	-134(ra) # 80000d3a <pop_off>
}
    80000dc8:	60e2                	ld	ra,24(sp)
    80000dca:	6442                	ld	s0,16(sp)
    80000dcc:	64a2                	ld	s1,8(sp)
    80000dce:	6105                	add	sp,sp,32
    80000dd0:	8082                	ret
    panic("release");
    80000dd2:	00007517          	auipc	a0,0x7
    80000dd6:	2c650513          	add	a0,a0,710 # 80008098 <digits+0x58>
    80000dda:	fffff097          	auipc	ra,0xfffff
    80000dde:	768080e7          	jalr	1896(ra) # 80000542 <panic>

0000000080000de2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000de2:	1141                	add	sp,sp,-16
    80000de4:	e422                	sd	s0,8(sp)
    80000de6:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000de8:	ca19                	beqz	a2,80000dfe <memset+0x1c>
    80000dea:	87aa                	mv	a5,a0
    80000dec:	1602                	sll	a2,a2,0x20
    80000dee:	9201                	srl	a2,a2,0x20
    80000df0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000df4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000df8:	0785                	add	a5,a5,1
    80000dfa:	fee79de3          	bne	a5,a4,80000df4 <memset+0x12>
  }
  return dst;
}
    80000dfe:	6422                	ld	s0,8(sp)
    80000e00:	0141                	add	sp,sp,16
    80000e02:	8082                	ret

0000000080000e04 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e04:	1141                	add	sp,sp,-16
    80000e06:	e422                	sd	s0,8(sp)
    80000e08:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e0a:	ca05                	beqz	a2,80000e3a <memcmp+0x36>
    80000e0c:	fff6069b          	addw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000e10:	1682                	sll	a3,a3,0x20
    80000e12:	9281                	srl	a3,a3,0x20
    80000e14:	0685                	add	a3,a3,1
    80000e16:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e18:	00054783          	lbu	a5,0(a0)
    80000e1c:	0005c703          	lbu	a4,0(a1)
    80000e20:	00e79863          	bne	a5,a4,80000e30 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e24:	0505                	add	a0,a0,1
    80000e26:	0585                	add	a1,a1,1
  while(n-- > 0){
    80000e28:	fed518e3          	bne	a0,a3,80000e18 <memcmp+0x14>
  }

  return 0;
    80000e2c:	4501                	li	a0,0
    80000e2e:	a019                	j	80000e34 <memcmp+0x30>
      return *s1 - *s2;
    80000e30:	40e7853b          	subw	a0,a5,a4
}
    80000e34:	6422                	ld	s0,8(sp)
    80000e36:	0141                	add	sp,sp,16
    80000e38:	8082                	ret
  return 0;
    80000e3a:	4501                	li	a0,0
    80000e3c:	bfe5                	j	80000e34 <memcmp+0x30>

0000000080000e3e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e3e:	1141                	add	sp,sp,-16
    80000e40:	e422                	sd	s0,8(sp)
    80000e42:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e44:	02a5e563          	bltu	a1,a0,80000e6e <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e48:	fff6069b          	addw	a3,a2,-1
    80000e4c:	ce11                	beqz	a2,80000e68 <memmove+0x2a>
    80000e4e:	1682                	sll	a3,a3,0x20
    80000e50:	9281                	srl	a3,a3,0x20
    80000e52:	0685                	add	a3,a3,1
    80000e54:	96ae                	add	a3,a3,a1
    80000e56:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000e58:	0585                	add	a1,a1,1
    80000e5a:	0785                	add	a5,a5,1
    80000e5c:	fff5c703          	lbu	a4,-1(a1)
    80000e60:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000e64:	fed59ae3          	bne	a1,a3,80000e58 <memmove+0x1a>

  return dst;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	add	sp,sp,16
    80000e6c:	8082                	ret
  if(s < d && s + n > d){
    80000e6e:	02061713          	sll	a4,a2,0x20
    80000e72:	9301                	srl	a4,a4,0x20
    80000e74:	00e587b3          	add	a5,a1,a4
    80000e78:	fcf578e3          	bgeu	a0,a5,80000e48 <memmove+0xa>
    d += n;
    80000e7c:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000e7e:	fff6069b          	addw	a3,a2,-1
    80000e82:	d27d                	beqz	a2,80000e68 <memmove+0x2a>
    80000e84:	02069613          	sll	a2,a3,0x20
    80000e88:	9201                	srl	a2,a2,0x20
    80000e8a:	fff64613          	not	a2,a2
    80000e8e:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e90:	17fd                	add	a5,a5,-1
    80000e92:	177d                	add	a4,a4,-1 # ffffffffffffefff <end+0xffffffff7ffd0fff>
    80000e94:	0007c683          	lbu	a3,0(a5)
    80000e98:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e9c:	fef61ae3          	bne	a2,a5,80000e90 <memmove+0x52>
    80000ea0:	b7e1                	j	80000e68 <memmove+0x2a>

0000000080000ea2 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000ea2:	1141                	add	sp,sp,-16
    80000ea4:	e406                	sd	ra,8(sp)
    80000ea6:	e022                	sd	s0,0(sp)
    80000ea8:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    80000eaa:	00000097          	auipc	ra,0x0
    80000eae:	f94080e7          	jalr	-108(ra) # 80000e3e <memmove>
}
    80000eb2:	60a2                	ld	ra,8(sp)
    80000eb4:	6402                	ld	s0,0(sp)
    80000eb6:	0141                	add	sp,sp,16
    80000eb8:	8082                	ret

0000000080000eba <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000eba:	1141                	add	sp,sp,-16
    80000ebc:	e422                	sd	s0,8(sp)
    80000ebe:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000ec0:	ce11                	beqz	a2,80000edc <strncmp+0x22>
    80000ec2:	00054783          	lbu	a5,0(a0)
    80000ec6:	cf89                	beqz	a5,80000ee0 <strncmp+0x26>
    80000ec8:	0005c703          	lbu	a4,0(a1)
    80000ecc:	00f71a63          	bne	a4,a5,80000ee0 <strncmp+0x26>
    n--, p++, q++;
    80000ed0:	367d                	addw	a2,a2,-1
    80000ed2:	0505                	add	a0,a0,1
    80000ed4:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000ed6:	f675                	bnez	a2,80000ec2 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ed8:	4501                	li	a0,0
    80000eda:	a809                	j	80000eec <strncmp+0x32>
    80000edc:	4501                	li	a0,0
    80000ede:	a039                	j	80000eec <strncmp+0x32>
  if(n == 0)
    80000ee0:	ca09                	beqz	a2,80000ef2 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000ee2:	00054503          	lbu	a0,0(a0)
    80000ee6:	0005c783          	lbu	a5,0(a1)
    80000eea:	9d1d                	subw	a0,a0,a5
}
    80000eec:	6422                	ld	s0,8(sp)
    80000eee:	0141                	add	sp,sp,16
    80000ef0:	8082                	ret
    return 0;
    80000ef2:	4501                	li	a0,0
    80000ef4:	bfe5                	j	80000eec <strncmp+0x32>

0000000080000ef6 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000ef6:	1141                	add	sp,sp,-16
    80000ef8:	e422                	sd	s0,8(sp)
    80000efa:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000efc:	87aa                	mv	a5,a0
    80000efe:	86b2                	mv	a3,a2
    80000f00:	367d                	addw	a2,a2,-1
    80000f02:	00d05963          	blez	a3,80000f14 <strncpy+0x1e>
    80000f06:	0785                	add	a5,a5,1
    80000f08:	0005c703          	lbu	a4,0(a1)
    80000f0c:	fee78fa3          	sb	a4,-1(a5)
    80000f10:	0585                	add	a1,a1,1
    80000f12:	f775                	bnez	a4,80000efe <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f14:	873e                	mv	a4,a5
    80000f16:	9fb5                	addw	a5,a5,a3
    80000f18:	37fd                	addw	a5,a5,-1
    80000f1a:	00c05963          	blez	a2,80000f2c <strncpy+0x36>
    *s++ = 0;
    80000f1e:	0705                	add	a4,a4,1
    80000f20:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000f24:	40e786bb          	subw	a3,a5,a4
    80000f28:	fed04be3          	bgtz	a3,80000f1e <strncpy+0x28>
  return os;
}
    80000f2c:	6422                	ld	s0,8(sp)
    80000f2e:	0141                	add	sp,sp,16
    80000f30:	8082                	ret

0000000080000f32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f32:	1141                	add	sp,sp,-16
    80000f34:	e422                	sd	s0,8(sp)
    80000f36:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f38:	02c05363          	blez	a2,80000f5e <safestrcpy+0x2c>
    80000f3c:	fff6069b          	addw	a3,a2,-1
    80000f40:	1682                	sll	a3,a3,0x20
    80000f42:	9281                	srl	a3,a3,0x20
    80000f44:	96ae                	add	a3,a3,a1
    80000f46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f48:	00d58963          	beq	a1,a3,80000f5a <safestrcpy+0x28>
    80000f4c:	0585                	add	a1,a1,1
    80000f4e:	0785                	add	a5,a5,1
    80000f50:	fff5c703          	lbu	a4,-1(a1)
    80000f54:	fee78fa3          	sb	a4,-1(a5)
    80000f58:	fb65                	bnez	a4,80000f48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f5e:	6422                	ld	s0,8(sp)
    80000f60:	0141                	add	sp,sp,16
    80000f62:	8082                	ret

0000000080000f64 <strlen>:

int
strlen(const char *s)
{
    80000f64:	1141                	add	sp,sp,-16
    80000f66:	e422                	sd	s0,8(sp)
    80000f68:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f6a:	00054783          	lbu	a5,0(a0)
    80000f6e:	cf91                	beqz	a5,80000f8a <strlen+0x26>
    80000f70:	0505                	add	a0,a0,1
    80000f72:	87aa                	mv	a5,a0
    80000f74:	86be                	mv	a3,a5
    80000f76:	0785                	add	a5,a5,1
    80000f78:	fff7c703          	lbu	a4,-1(a5)
    80000f7c:	ff65                	bnez	a4,80000f74 <strlen+0x10>
    80000f7e:	40a6853b          	subw	a0,a3,a0
    80000f82:	2505                	addw	a0,a0,1
    ;
  return n;
}
    80000f84:	6422                	ld	s0,8(sp)
    80000f86:	0141                	add	sp,sp,16
    80000f88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f8a:	4501                	li	a0,0
    80000f8c:	bfe5                	j	80000f84 <strlen+0x20>

0000000080000f8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f8e:	1141                	add	sp,sp,-16
    80000f90:	e406                	sd	ra,8(sp)
    80000f92:	e022                	sd	s0,0(sp)
    80000f94:	0800                	add	s0,sp,16
  if(cpuid() == 0){
    80000f96:	00001097          	auipc	ra,0x1
    80000f9a:	d48080e7          	jalr	-696(ra) # 80001cde <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f9e:	00008717          	auipc	a4,0x8
    80000fa2:	06e70713          	add	a4,a4,110 # 8000900c <started>
  if(cpuid() == 0){
    80000fa6:	c139                	beqz	a0,80000fec <main+0x5e>
    while(started == 0)
    80000fa8:	431c                	lw	a5,0(a4)
    80000faa:	2781                	sext.w	a5,a5
    80000fac:	dff5                	beqz	a5,80000fa8 <main+0x1a>
      ;
    __sync_synchronize();
    80000fae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000fb2:	00001097          	auipc	ra,0x1
    80000fb6:	d2c080e7          	jalr	-724(ra) # 80001cde <cpuid>
    80000fba:	85aa                	mv	a1,a0
    80000fbc:	00007517          	auipc	a0,0x7
    80000fc0:	0fc50513          	add	a0,a0,252 # 800080b8 <digits+0x78>
    80000fc4:	fffff097          	auipc	ra,0xfffff
    80000fc8:	5c8080e7          	jalr	1480(ra) # 8000058c <printf>
    kvminithart();    // turn on paging
    80000fcc:	00000097          	auipc	ra,0x0
    80000fd0:	0d8080e7          	jalr	216(ra) # 800010a4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000fd4:	00002097          	auipc	ra,0x2
    80000fd8:	994080e7          	jalr	-1644(ra) # 80002968 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000fdc:	00005097          	auipc	ra,0x5
    80000fe0:	f04080e7          	jalr	-252(ra) # 80005ee0 <plicinithart>
  }

  scheduler();        
    80000fe4:	00001097          	auipc	ra,0x1
    80000fe8:	25e080e7          	jalr	606(ra) # 80002242 <scheduler>
    consoleinit();
    80000fec:	fffff097          	auipc	ra,0xfffff
    80000ff0:	466080e7          	jalr	1126(ra) # 80000452 <consoleinit>
    printfinit();
    80000ff4:	fffff097          	auipc	ra,0xfffff
    80000ff8:	778080e7          	jalr	1912(ra) # 8000076c <printfinit>
    printf("\n");
    80000ffc:	00007517          	auipc	a0,0x7
    80001000:	0cc50513          	add	a0,a0,204 # 800080c8 <digits+0x88>
    80001004:	fffff097          	auipc	ra,0xfffff
    80001008:	588080e7          	jalr	1416(ra) # 8000058c <printf>
    printf("xv6 kernel is booting\n");
    8000100c:	00007517          	auipc	a0,0x7
    80001010:	09450513          	add	a0,a0,148 # 800080a0 <digits+0x60>
    80001014:	fffff097          	auipc	ra,0xfffff
    80001018:	578080e7          	jalr	1400(ra) # 8000058c <printf>
    printf("\n");
    8000101c:	00007517          	auipc	a0,0x7
    80001020:	0ac50513          	add	a0,a0,172 # 800080c8 <digits+0x88>
    80001024:	fffff097          	auipc	ra,0xfffff
    80001028:	568080e7          	jalr	1384(ra) # 8000058c <printf>
    kinit();         // physical page allocator
    8000102c:	00000097          	auipc	ra,0x0
    80001030:	b82080e7          	jalr	-1150(ra) # 80000bae <kinit>
    kvminit();       // create kernel page table
    80001034:	00000097          	auipc	ra,0x0
    80001038:	34e080e7          	jalr	846(ra) # 80001382 <kvminit>
    kvminithart();   // turn on paging
    8000103c:	00000097          	auipc	ra,0x0
    80001040:	068080e7          	jalr	104(ra) # 800010a4 <kvminithart>
    procinit();      // process table
    80001044:	00001097          	auipc	ra,0x1
    80001048:	bca080e7          	jalr	-1078(ra) # 80001c0e <procinit>
    trapinit();      // trap vectors
    8000104c:	00002097          	auipc	ra,0x2
    80001050:	8f4080e7          	jalr	-1804(ra) # 80002940 <trapinit>
    trapinithart();  // install kernel trap vector
    80001054:	00002097          	auipc	ra,0x2
    80001058:	914080e7          	jalr	-1772(ra) # 80002968 <trapinithart>
    plicinit();      // set up interrupt controller
    8000105c:	00005097          	auipc	ra,0x5
    80001060:	e6e080e7          	jalr	-402(ra) # 80005eca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001064:	00005097          	auipc	ra,0x5
    80001068:	e7c080e7          	jalr	-388(ra) # 80005ee0 <plicinithart>
    binit();         // buffer cache
    8000106c:	00002097          	auipc	ra,0x2
    80001070:	070080e7          	jalr	112(ra) # 800030dc <binit>
    iinit();         // inode cache
    80001074:	00002097          	auipc	ra,0x2
    80001078:	6fc080e7          	jalr	1788(ra) # 80003770 <iinit>
    fileinit();      // file table
    8000107c:	00003097          	auipc	ra,0x3
    80001080:	672080e7          	jalr	1650(ra) # 800046ee <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001084:	00005097          	auipc	ra,0x5
    80001088:	f62080e7          	jalr	-158(ra) # 80005fe6 <virtio_disk_init>
    userinit();      // first user process
    8000108c:	00001097          	auipc	ra,0x1
    80001090:	f48080e7          	jalr	-184(ra) # 80001fd4 <userinit>
    __sync_synchronize();
    80001094:	0ff0000f          	fence
    started = 1;
    80001098:	4785                	li	a5,1
    8000109a:	00008717          	auipc	a4,0x8
    8000109e:	f6f72923          	sw	a5,-142(a4) # 8000900c <started>
    800010a2:	b789                	j	80000fe4 <main+0x56>

00000000800010a4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800010a4:	1141                	add	sp,sp,-16
    800010a6:	e422                	sd	s0,8(sp)
    800010a8:	0800                	add	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    800010aa:	00008797          	auipc	a5,0x8
    800010ae:	f667b783          	ld	a5,-154(a5) # 80009010 <kernel_pagetable>
    800010b2:	83b1                	srl	a5,a5,0xc
    800010b4:	577d                	li	a4,-1
    800010b6:	177e                	sll	a4,a4,0x3f
    800010b8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010ba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010be:	12000073          	sfence.vma
  sfence_vma();
}
    800010c2:	6422                	ld	s0,8(sp)
    800010c4:	0141                	add	sp,sp,16
    800010c6:	8082                	ret

00000000800010c8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010c8:	7139                	add	sp,sp,-64
    800010ca:	fc06                	sd	ra,56(sp)
    800010cc:	f822                	sd	s0,48(sp)
    800010ce:	f426                	sd	s1,40(sp)
    800010d0:	f04a                	sd	s2,32(sp)
    800010d2:	ec4e                	sd	s3,24(sp)
    800010d4:	e852                	sd	s4,16(sp)
    800010d6:	e456                	sd	s5,8(sp)
    800010d8:	e05a                	sd	s6,0(sp)
    800010da:	0080                	add	s0,sp,64
    800010dc:	84aa                	mv	s1,a0
    800010de:	89ae                	mv	s3,a1
    800010e0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800010e2:	57fd                	li	a5,-1
    800010e4:	83e9                	srl	a5,a5,0x1a
    800010e6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800010e8:	4b31                	li	s6,12
  if(va >= MAXVA)
    800010ea:	04b7f263          	bgeu	a5,a1,8000112e <walk+0x66>
    panic("walk");
    800010ee:	00007517          	auipc	a0,0x7
    800010f2:	fe250513          	add	a0,a0,-30 # 800080d0 <digits+0x90>
    800010f6:	fffff097          	auipc	ra,0xfffff
    800010fa:	44c080e7          	jalr	1100(ra) # 80000542 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010fe:	060a8663          	beqz	s5,8000116a <walk+0xa2>
    80001102:	00000097          	auipc	ra,0x0
    80001106:	ae8080e7          	jalr	-1304(ra) # 80000bea <kalloc>
    8000110a:	84aa                	mv	s1,a0
    8000110c:	c529                	beqz	a0,80001156 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000110e:	6605                	lui	a2,0x1
    80001110:	4581                	li	a1,0
    80001112:	00000097          	auipc	ra,0x0
    80001116:	cd0080e7          	jalr	-816(ra) # 80000de2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000111a:	00c4d793          	srl	a5,s1,0xc
    8000111e:	07aa                	sll	a5,a5,0xa
    80001120:	0017e793          	or	a5,a5,1
    80001124:	00f93023          	sd	a5,0(s2) # ffffffff80000000 <end+0xfffffffefffd2000>
  for(int level = 2; level > 0; level--) {
    80001128:	3a5d                	addw	s4,s4,-9 # ff7 <_entry-0x7ffff009>
    8000112a:	036a0063          	beq	s4,s6,8000114a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000112e:	0149d933          	srl	s2,s3,s4
    80001132:	1ff97913          	and	s2,s2,511
    80001136:	090e                	sll	s2,s2,0x3
    80001138:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000113a:	00093483          	ld	s1,0(s2)
    8000113e:	0014f793          	and	a5,s1,1
    80001142:	dfd5                	beqz	a5,800010fe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001144:	80a9                	srl	s1,s1,0xa
    80001146:	04b2                	sll	s1,s1,0xc
    80001148:	b7c5                	j	80001128 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000114a:	00c9d513          	srl	a0,s3,0xc
    8000114e:	1ff57513          	and	a0,a0,511
    80001152:	050e                	sll	a0,a0,0x3
    80001154:	9526                	add	a0,a0,s1
}
    80001156:	70e2                	ld	ra,56(sp)
    80001158:	7442                	ld	s0,48(sp)
    8000115a:	74a2                	ld	s1,40(sp)
    8000115c:	7902                	ld	s2,32(sp)
    8000115e:	69e2                	ld	s3,24(sp)
    80001160:	6a42                	ld	s4,16(sp)
    80001162:	6aa2                	ld	s5,8(sp)
    80001164:	6b02                	ld	s6,0(sp)
    80001166:	6121                	add	sp,sp,64
    80001168:	8082                	ret
        return 0;
    8000116a:	4501                	li	a0,0
    8000116c:	b7ed                	j	80001156 <walk+0x8e>

000000008000116e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000116e:	57fd                	li	a5,-1
    80001170:	83e9                	srl	a5,a5,0x1a
    80001172:	00b7f463          	bgeu	a5,a1,8000117a <walkaddr+0xc>
    return 0;
    80001176:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001178:	8082                	ret
{
    8000117a:	1141                	add	sp,sp,-16
    8000117c:	e406                	sd	ra,8(sp)
    8000117e:	e022                	sd	s0,0(sp)
    80001180:	0800                	add	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001182:	4601                	li	a2,0
    80001184:	00000097          	auipc	ra,0x0
    80001188:	f44080e7          	jalr	-188(ra) # 800010c8 <walk>
  if(pte == 0)
    8000118c:	c105                	beqz	a0,800011ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000118e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001190:	0117f693          	and	a3,a5,17
    80001194:	4745                	li	a4,17
    return 0;
    80001196:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001198:	00e68663          	beq	a3,a4,800011a4 <walkaddr+0x36>
}
    8000119c:	60a2                	ld	ra,8(sp)
    8000119e:	6402                	ld	s0,0(sp)
    800011a0:	0141                	add	sp,sp,16
    800011a2:	8082                	ret
  pa = PTE2PA(*pte);
    800011a4:	83a9                	srl	a5,a5,0xa
    800011a6:	00c79513          	sll	a0,a5,0xc
  return pa;
    800011aa:	bfcd                	j	8000119c <walkaddr+0x2e>
    return 0;
    800011ac:	4501                	li	a0,0
    800011ae:	b7fd                	j	8000119c <walkaddr+0x2e>

00000000800011b0 <is_cow>:
  return 0;
}

int is_cow(pagetable_t pagetable, uint64 va) {
        pte_t *pte;
    if (va >= MAXVA) {
    800011b0:	57fd                	li	a5,-1
    800011b2:	83e9                	srl	a5,a5,0x1a
    800011b4:	00b7f463          	bgeu	a5,a1,800011bc <is_cow+0xc>
        return 0;
    800011b8:	4501                	li	a0,0
    }
    if ((*pte & PTE_U) == 0) {
        return 0;
    }
    return 1;
}
    800011ba:	8082                	ret
int is_cow(pagetable_t pagetable, uint64 va) {
    800011bc:	1141                	add	sp,sp,-16
    800011be:	e406                	sd	ra,8(sp)
    800011c0:	e022                	sd	s0,0(sp)
    800011c2:	0800                	add	s0,sp,16
    if ((pte = walk(pagetable, va, 0)) == 0) {
    800011c4:	4601                	li	a2,0
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f02080e7          	jalr	-254(ra) # 800010c8 <walk>
    800011ce:	c911                	beqz	a0,800011e2 <is_cow+0x32>
    if ((*pte & PTE_U) == 0) {
    800011d0:	6108                	ld	a0,0(a0)
    800011d2:	8945                	and	a0,a0,17
    800011d4:	153d                	add	a0,a0,-17
    800011d6:	00153513          	seqz	a0,a0
}
    800011da:	60a2                	ld	ra,8(sp)
    800011dc:	6402                	ld	s0,0(sp)
    800011de:	0141                	add	sp,sp,16
    800011e0:	8082                	ret
        return 0;
    800011e2:	4501                	li	a0,0
    800011e4:	bfdd                	j	800011da <is_cow+0x2a>

00000000800011e6 <cow_alloc2>:

uint64 cow_alloc2(pagetable_t pagetable, uint64 va) {
    800011e6:	7179                	add	sp,sp,-48
    800011e8:	f406                	sd	ra,40(sp)
    800011ea:	f022                	sd	s0,32(sp)
    800011ec:	ec26                	sd	s1,24(sp)
    800011ee:	e84a                	sd	s2,16(sp)
    800011f0:	e44e                	sd	s3,8(sp)
    800011f2:	e052                	sd	s4,0(sp)
    800011f4:	1800                	add	s0,sp,48
    va = PGROUNDDOWN(va);
    pte_t *pte = walk(pagetable, va, 0);
    800011f6:	4601                	li	a2,0
    800011f8:	77fd                	lui	a5,0xfffff
    800011fa:	8dfd                	and	a1,a1,a5
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	ecc080e7          	jalr	-308(ra) # 800010c8 <walk>
    80001204:	892a                	mv	s2,a0
    char* mem = kalloc();
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	9e4080e7          	jalr	-1564(ra) # 80000bea <kalloc>
    if (mem == 0) {
        return 0;
    8000120e:	4a01                	li	s4,0
    if (mem == 0) {
    80001210:	cd15                	beqz	a0,8000124c <cow_alloc2+0x66>
    80001212:	84aa                	mv	s1,a0
    }
    uint64 pa = PTE2PA(*pte);
    80001214:	00093983          	ld	s3,0(s2)
    80001218:	00a9d993          	srl	s3,s3,0xa
    8000121c:	09b2                	sll	s3,s3,0xc
    memmove(mem, (char*)pa, PGSIZE);
    8000121e:	6605                	lui	a2,0x1
    80001220:	85ce                	mv	a1,s3
    80001222:	00000097          	auipc	ra,0x0
    80001226:	c1c080e7          	jalr	-996(ra) # 80000e3e <memmove>


    uint flags = PTE_FLAGS(*pte);
    (*pte) = PA2PTE((uint64)mem) | flags;
    8000122a:	8a26                	mv	s4,s1
    8000122c:	80b1                	srl	s1,s1,0xc
    8000122e:	04aa                	sll	s1,s1,0xa
    uint flags = PTE_FLAGS(*pte);
    80001230:	00093783          	ld	a5,0(s2)
    (*pte) = PA2PTE((uint64)mem) | flags;
    80001234:	2ff7f793          	and	a5,a5,767
    (*pte) |= PTE_W;
    (*pte) &= ~PTE_C;
    80001238:	8fc5                	or	a5,a5,s1
    8000123a:	0047e793          	or	a5,a5,4
    8000123e:	00f93023          	sd	a5,0(s2)
    kfree((void*)pa);
    80001242:	854e                	mv	a0,s3
    80001244:	00000097          	auipc	ra,0x0
    80001248:	844080e7          	jalr	-1980(ra) # 80000a88 <kfree>
    return (uint64)mem;
}
    8000124c:	8552                	mv	a0,s4
    8000124e:	70a2                	ld	ra,40(sp)
    80001250:	7402                	ld	s0,32(sp)
    80001252:	64e2                	ld	s1,24(sp)
    80001254:	6942                	ld	s2,16(sp)
    80001256:	69a2                	ld	s3,8(sp)
    80001258:	6a02                	ld	s4,0(sp)
    8000125a:	6145                	add	sp,sp,48
    8000125c:	8082                	ret

000000008000125e <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000125e:	1101                	add	sp,sp,-32
    80001260:	ec06                	sd	ra,24(sp)
    80001262:	e822                	sd	s0,16(sp)
    80001264:	e426                	sd	s1,8(sp)
    80001266:	1000                	add	s0,sp,32
    80001268:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    8000126a:	1552                	sll	a0,a0,0x34
    8000126c:	03455493          	srl	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001270:	4601                	li	a2,0
    80001272:	00008517          	auipc	a0,0x8
    80001276:	d9e53503          	ld	a0,-610(a0) # 80009010 <kernel_pagetable>
    8000127a:	00000097          	auipc	ra,0x0
    8000127e:	e4e080e7          	jalr	-434(ra) # 800010c8 <walk>
  if(pte == 0)
    80001282:	cd09                	beqz	a0,8000129c <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001284:	6108                	ld	a0,0(a0)
    80001286:	00157793          	and	a5,a0,1
    8000128a:	c38d                	beqz	a5,800012ac <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000128c:	8129                	srl	a0,a0,0xa
    8000128e:	0532                	sll	a0,a0,0xc
  return pa+off;
}
    80001290:	9526                	add	a0,a0,s1
    80001292:	60e2                	ld	ra,24(sp)
    80001294:	6442                	ld	s0,16(sp)
    80001296:	64a2                	ld	s1,8(sp)
    80001298:	6105                	add	sp,sp,32
    8000129a:	8082                	ret
    panic("kvmpa");
    8000129c:	00007517          	auipc	a0,0x7
    800012a0:	e3c50513          	add	a0,a0,-452 # 800080d8 <digits+0x98>
    800012a4:	fffff097          	auipc	ra,0xfffff
    800012a8:	29e080e7          	jalr	670(ra) # 80000542 <panic>
    panic("kvmpa");
    800012ac:	00007517          	auipc	a0,0x7
    800012b0:	e2c50513          	add	a0,a0,-468 # 800080d8 <digits+0x98>
    800012b4:	fffff097          	auipc	ra,0xfffff
    800012b8:	28e080e7          	jalr	654(ra) # 80000542 <panic>

00000000800012bc <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800012bc:	715d                	add	sp,sp,-80
    800012be:	e486                	sd	ra,72(sp)
    800012c0:	e0a2                	sd	s0,64(sp)
    800012c2:	fc26                	sd	s1,56(sp)
    800012c4:	f84a                	sd	s2,48(sp)
    800012c6:	f44e                	sd	s3,40(sp)
    800012c8:	f052                	sd	s4,32(sp)
    800012ca:	ec56                	sd	s5,24(sp)
    800012cc:	e85a                	sd	s6,16(sp)
    800012ce:	e45e                	sd	s7,8(sp)
    800012d0:	0880                	add	s0,sp,80
    800012d2:	8aaa                	mv	s5,a0
    800012d4:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800012d6:	777d                	lui	a4,0xfffff
    800012d8:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800012dc:	fff60993          	add	s3,a2,-1 # fff <_entry-0x7ffff001>
    800012e0:	99ae                	add	s3,s3,a1
    800012e2:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800012e6:	893e                	mv	s2,a5
    800012e8:	40f68a33          	sub	s4,a3,a5
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    //if(pa >= KERNBASE) page_cow[COW_INDEX(pa)]++;
    if(a == last)
      break;
    a += PGSIZE;
    800012ec:	6b85                	lui	s7,0x1
    800012ee:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800012f2:	4605                	li	a2,1
    800012f4:	85ca                	mv	a1,s2
    800012f6:	8556                	mv	a0,s5
    800012f8:	00000097          	auipc	ra,0x0
    800012fc:	dd0080e7          	jalr	-560(ra) # 800010c8 <walk>
    80001300:	c51d                	beqz	a0,8000132e <mappages+0x72>
    if(*pte & PTE_V)
    80001302:	611c                	ld	a5,0(a0)
    80001304:	8b85                	and	a5,a5,1
    80001306:	ef81                	bnez	a5,8000131e <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001308:	80b1                	srl	s1,s1,0xc
    8000130a:	04aa                	sll	s1,s1,0xa
    8000130c:	0164e4b3          	or	s1,s1,s6
    80001310:	0014e493          	or	s1,s1,1
    80001314:	e104                	sd	s1,0(a0)
    if(a == last)
    80001316:	03390863          	beq	s2,s3,80001346 <mappages+0x8a>
    a += PGSIZE;
    8000131a:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000131c:	bfc9                	j	800012ee <mappages+0x32>
      panic("remap");
    8000131e:	00007517          	auipc	a0,0x7
    80001322:	dc250513          	add	a0,a0,-574 # 800080e0 <digits+0xa0>
    80001326:	fffff097          	auipc	ra,0xfffff
    8000132a:	21c080e7          	jalr	540(ra) # 80000542 <panic>
      return -1;
    8000132e:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001330:	60a6                	ld	ra,72(sp)
    80001332:	6406                	ld	s0,64(sp)
    80001334:	74e2                	ld	s1,56(sp)
    80001336:	7942                	ld	s2,48(sp)
    80001338:	79a2                	ld	s3,40(sp)
    8000133a:	7a02                	ld	s4,32(sp)
    8000133c:	6ae2                	ld	s5,24(sp)
    8000133e:	6b42                	ld	s6,16(sp)
    80001340:	6ba2                	ld	s7,8(sp)
    80001342:	6161                	add	sp,sp,80
    80001344:	8082                	ret
  return 0;
    80001346:	4501                	li	a0,0
    80001348:	b7e5                	j	80001330 <mappages+0x74>

000000008000134a <kvmmap>:
{
    8000134a:	1141                	add	sp,sp,-16
    8000134c:	e406                	sd	ra,8(sp)
    8000134e:	e022                	sd	s0,0(sp)
    80001350:	0800                	add	s0,sp,16
    80001352:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001354:	86ae                	mv	a3,a1
    80001356:	85aa                	mv	a1,a0
    80001358:	00008517          	auipc	a0,0x8
    8000135c:	cb853503          	ld	a0,-840(a0) # 80009010 <kernel_pagetable>
    80001360:	00000097          	auipc	ra,0x0
    80001364:	f5c080e7          	jalr	-164(ra) # 800012bc <mappages>
    80001368:	e509                	bnez	a0,80001372 <kvmmap+0x28>
}
    8000136a:	60a2                	ld	ra,8(sp)
    8000136c:	6402                	ld	s0,0(sp)
    8000136e:	0141                	add	sp,sp,16
    80001370:	8082                	ret
    panic("kvmmap");
    80001372:	00007517          	auipc	a0,0x7
    80001376:	d7650513          	add	a0,a0,-650 # 800080e8 <digits+0xa8>
    8000137a:	fffff097          	auipc	ra,0xfffff
    8000137e:	1c8080e7          	jalr	456(ra) # 80000542 <panic>

0000000080001382 <kvminit>:
{
    80001382:	1101                	add	sp,sp,-32
    80001384:	ec06                	sd	ra,24(sp)
    80001386:	e822                	sd	s0,16(sp)
    80001388:	e426                	sd	s1,8(sp)
    8000138a:	1000                	add	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000138c:	00000097          	auipc	ra,0x0
    80001390:	85e080e7          	jalr	-1954(ra) # 80000bea <kalloc>
    80001394:	00008717          	auipc	a4,0x8
    80001398:	c6a73e23          	sd	a0,-900(a4) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000139c:	6605                	lui	a2,0x1
    8000139e:	4581                	li	a1,0
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	a42080e7          	jalr	-1470(ra) # 80000de2 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800013a8:	4699                	li	a3,6
    800013aa:	6605                	lui	a2,0x1
    800013ac:	100005b7          	lui	a1,0x10000
    800013b0:	10000537          	lui	a0,0x10000
    800013b4:	00000097          	auipc	ra,0x0
    800013b8:	f96080e7          	jalr	-106(ra) # 8000134a <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800013bc:	4699                	li	a3,6
    800013be:	6605                	lui	a2,0x1
    800013c0:	100015b7          	lui	a1,0x10001
    800013c4:	10001537          	lui	a0,0x10001
    800013c8:	00000097          	auipc	ra,0x0
    800013cc:	f82080e7          	jalr	-126(ra) # 8000134a <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800013d0:	4699                	li	a3,6
    800013d2:	6641                	lui	a2,0x10
    800013d4:	020005b7          	lui	a1,0x2000
    800013d8:	02000537          	lui	a0,0x2000
    800013dc:	00000097          	auipc	ra,0x0
    800013e0:	f6e080e7          	jalr	-146(ra) # 8000134a <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800013e4:	4699                	li	a3,6
    800013e6:	00400637          	lui	a2,0x400
    800013ea:	0c0005b7          	lui	a1,0xc000
    800013ee:	0c000537          	lui	a0,0xc000
    800013f2:	00000097          	auipc	ra,0x0
    800013f6:	f58080e7          	jalr	-168(ra) # 8000134a <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800013fa:	00007497          	auipc	s1,0x7
    800013fe:	c0648493          	add	s1,s1,-1018 # 80008000 <etext>
    80001402:	46a9                	li	a3,10
    80001404:	80007617          	auipc	a2,0x80007
    80001408:	bfc60613          	add	a2,a2,-1028 # 8000 <_entry-0x7fff8000>
    8000140c:	4585                	li	a1,1
    8000140e:	05fe                	sll	a1,a1,0x1f
    80001410:	852e                	mv	a0,a1
    80001412:	00000097          	auipc	ra,0x0
    80001416:	f38080e7          	jalr	-200(ra) # 8000134a <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000141a:	4699                	li	a3,6
    8000141c:	4645                	li	a2,17
    8000141e:	066e                	sll	a2,a2,0x1b
    80001420:	8e05                	sub	a2,a2,s1
    80001422:	85a6                	mv	a1,s1
    80001424:	8526                	mv	a0,s1
    80001426:	00000097          	auipc	ra,0x0
    8000142a:	f24080e7          	jalr	-220(ra) # 8000134a <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000142e:	46a9                	li	a3,10
    80001430:	6605                	lui	a2,0x1
    80001432:	00006597          	auipc	a1,0x6
    80001436:	bce58593          	add	a1,a1,-1074 # 80007000 <_trampoline>
    8000143a:	04000537          	lui	a0,0x4000
    8000143e:	157d                	add	a0,a0,-1 # 3ffffff <_entry-0x7c000001>
    80001440:	0532                	sll	a0,a0,0xc
    80001442:	00000097          	auipc	ra,0x0
    80001446:	f08080e7          	jalr	-248(ra) # 8000134a <kvmmap>
}
    8000144a:	60e2                	ld	ra,24(sp)
    8000144c:	6442                	ld	s0,16(sp)
    8000144e:	64a2                	ld	s1,8(sp)
    80001450:	6105                	add	sp,sp,32
    80001452:	8082                	ret

0000000080001454 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001454:	715d                	add	sp,sp,-80
    80001456:	e486                	sd	ra,72(sp)
    80001458:	e0a2                	sd	s0,64(sp)
    8000145a:	fc26                	sd	s1,56(sp)
    8000145c:	f84a                	sd	s2,48(sp)
    8000145e:	f44e                	sd	s3,40(sp)
    80001460:	f052                	sd	s4,32(sp)
    80001462:	ec56                	sd	s5,24(sp)
    80001464:	e85a                	sd	s6,16(sp)
    80001466:	e45e                	sd	s7,8(sp)
    80001468:	0880                	add	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000146a:	03459793          	sll	a5,a1,0x34
    8000146e:	e795                	bnez	a5,8000149a <uvmunmap+0x46>
    80001470:	8a2a                	mv	s4,a0
    80001472:	892e                	mv	s2,a1
    80001474:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001476:	0632                	sll	a2,a2,0xc
    80001478:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000147c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000147e:	6b05                	lui	s6,0x1
    80001480:	0735e263          	bltu	a1,s3,800014e4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001484:	60a6                	ld	ra,72(sp)
    80001486:	6406                	ld	s0,64(sp)
    80001488:	74e2                	ld	s1,56(sp)
    8000148a:	7942                	ld	s2,48(sp)
    8000148c:	79a2                	ld	s3,40(sp)
    8000148e:	7a02                	ld	s4,32(sp)
    80001490:	6ae2                	ld	s5,24(sp)
    80001492:	6b42                	ld	s6,16(sp)
    80001494:	6ba2                	ld	s7,8(sp)
    80001496:	6161                	add	sp,sp,80
    80001498:	8082                	ret
    panic("uvmunmap: not aligned");
    8000149a:	00007517          	auipc	a0,0x7
    8000149e:	c5650513          	add	a0,a0,-938 # 800080f0 <digits+0xb0>
    800014a2:	fffff097          	auipc	ra,0xfffff
    800014a6:	0a0080e7          	jalr	160(ra) # 80000542 <panic>
      panic("uvmunmap: walk");
    800014aa:	00007517          	auipc	a0,0x7
    800014ae:	c5e50513          	add	a0,a0,-930 # 80008108 <digits+0xc8>
    800014b2:	fffff097          	auipc	ra,0xfffff
    800014b6:	090080e7          	jalr	144(ra) # 80000542 <panic>
      panic("uvmunmap: not mapped");
    800014ba:	00007517          	auipc	a0,0x7
    800014be:	c5e50513          	add	a0,a0,-930 # 80008118 <digits+0xd8>
    800014c2:	fffff097          	auipc	ra,0xfffff
    800014c6:	080080e7          	jalr	128(ra) # 80000542 <panic>
      panic("uvmunmap: not a leaf");
    800014ca:	00007517          	auipc	a0,0x7
    800014ce:	c6650513          	add	a0,a0,-922 # 80008130 <digits+0xf0>
    800014d2:	fffff097          	auipc	ra,0xfffff
    800014d6:	070080e7          	jalr	112(ra) # 80000542 <panic>
    *pte = 0;
    800014da:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014de:	995a                	add	s2,s2,s6
    800014e0:	fb3972e3          	bgeu	s2,s3,80001484 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800014e4:	4601                	li	a2,0
    800014e6:	85ca                	mv	a1,s2
    800014e8:	8552                	mv	a0,s4
    800014ea:	00000097          	auipc	ra,0x0
    800014ee:	bde080e7          	jalr	-1058(ra) # 800010c8 <walk>
    800014f2:	84aa                	mv	s1,a0
    800014f4:	d95d                	beqz	a0,800014aa <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800014f6:	6108                	ld	a0,0(a0)
    800014f8:	00157793          	and	a5,a0,1
    800014fc:	dfdd                	beqz	a5,800014ba <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800014fe:	3ff57793          	and	a5,a0,1023
    80001502:	fd7784e3          	beq	a5,s7,800014ca <uvmunmap+0x76>
    if(do_free){
    80001506:	fc0a8ae3          	beqz	s5,800014da <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000150a:	8129                	srl	a0,a0,0xa
      kfree((void*)pa);
    8000150c:	0532                	sll	a0,a0,0xc
    8000150e:	fffff097          	auipc	ra,0xfffff
    80001512:	57a080e7          	jalr	1402(ra) # 80000a88 <kfree>
    80001516:	b7d1                	j	800014da <uvmunmap+0x86>

0000000080001518 <cow_alloc>:
cow_alloc(pagetable_t pagetable, uint64 va) {
    80001518:	7139                	add	sp,sp,-64
    8000151a:	fc06                	sd	ra,56(sp)
    8000151c:	f822                	sd	s0,48(sp)
    8000151e:	f426                	sd	s1,40(sp)
    80001520:	f04a                	sd	s2,32(sp)
    80001522:	ec4e                	sd	s3,24(sp)
    80001524:	e852                	sd	s4,16(sp)
    80001526:	e456                	sd	s5,8(sp)
    80001528:	0080                	add	s0,sp,64
  va = PGROUNDDOWN(va);
    8000152a:	77fd                	lui	a5,0xfffff
    8000152c:	00f5f4b3          	and	s1,a1,a5
  if(va >= MAXVA) return -1;
    80001530:	57fd                	li	a5,-1
    80001532:	83e9                	srl	a5,a5,0x1a
    80001534:	0897eb63          	bltu	a5,s1,800015ca <cow_alloc+0xb2>
    80001538:	892a                	mv	s2,a0
  pte_t *pte = walk(pagetable, va, 0);
    8000153a:	4601                	li	a2,0
    8000153c:	85a6                	mv	a1,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	b8a080e7          	jalr	-1142(ra) # 800010c8 <walk>
  if(pte == 0) return -1;
    80001546:	c541                	beqz	a0,800015ce <cow_alloc+0xb6>
  if((*pte & PTE_V) == 0)
    80001548:	6118                	ld	a4,0(a0)
  if((*pte & PTE_U) == 0)
    8000154a:	01177693          	and	a3,a4,17
    8000154e:	47c5                	li	a5,17
    return 0;
    80001550:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001552:	00f68b63          	beq	a3,a5,80001568 <cow_alloc+0x50>
}
    80001556:	70e2                	ld	ra,56(sp)
    80001558:	7442                	ld	s0,48(sp)
    8000155a:	74a2                	ld	s1,40(sp)
    8000155c:	7902                	ld	s2,32(sp)
    8000155e:	69e2                	ld	s3,24(sp)
    80001560:	6a42                	ld	s4,16(sp)
    80001562:	6aa2                	ld	s5,8(sp)
    80001564:	6121                	add	sp,sp,64
    80001566:	8082                	ret
  uint64 pa = PTE2PA(*pte);
    80001568:	00a75a13          	srl	s4,a4,0xa
    8000156c:	0a32                	sll	s4,s4,0xc
  if(pa == 0) return -1;
    8000156e:	060a0263          	beqz	s4,800015d2 <cow_alloc+0xba>
  if(flags & PTE_C) {
    80001572:	10077793          	and	a5,a4,256
    80001576:	d3e5                	beqz	a5,80001556 <cow_alloc+0x3e>
    flags = (flags | PTE_W) & ~PTE_C;
    80001578:	2fb77713          	and	a4,a4,763
    8000157c:	00476993          	or	s3,a4,4
    uint64 mem = (uint64)kalloc();
    80001580:	fffff097          	auipc	ra,0xfffff
    80001584:	66a080e7          	jalr	1642(ra) # 80000bea <kalloc>
    80001588:	8aaa                	mv	s5,a0
    if (mem == 0) return -1;
    8000158a:	c531                	beqz	a0,800015d6 <cow_alloc+0xbe>
    memmove((char*)mem, (char*)pa, PGSIZE);
    8000158c:	6605                	lui	a2,0x1
    8000158e:	85d2                	mv	a1,s4
    80001590:	00000097          	auipc	ra,0x0
    80001594:	8ae080e7          	jalr	-1874(ra) # 80000e3e <memmove>
    uvmunmap(pagetable, va, 1, 1);
    80001598:	4685                	li	a3,1
    8000159a:	4605                	li	a2,1
    8000159c:	85a6                	mv	a1,s1
    8000159e:	854a                	mv	a0,s2
    800015a0:	00000097          	auipc	ra,0x0
    800015a4:	eb4080e7          	jalr	-332(ra) # 80001454 <uvmunmap>
    if (mappages(pagetable, va, PGSIZE, mem, flags) != 0) {
    800015a8:	874e                	mv	a4,s3
    800015aa:	86d6                	mv	a3,s5
    800015ac:	6605                	lui	a2,0x1
    800015ae:	85a6                	mv	a1,s1
    800015b0:	854a                	mv	a0,s2
    800015b2:	00000097          	auipc	ra,0x0
    800015b6:	d0a080e7          	jalr	-758(ra) # 800012bc <mappages>
    800015ba:	dd51                	beqz	a0,80001556 <cow_alloc+0x3e>
      kfree((void*)mem);
    800015bc:	8556                	mv	a0,s5
    800015be:	fffff097          	auipc	ra,0xfffff
    800015c2:	4ca080e7          	jalr	1226(ra) # 80000a88 <kfree>
      return -1;
    800015c6:	557d                	li	a0,-1
    800015c8:	b779                	j	80001556 <cow_alloc+0x3e>
  if(va >= MAXVA) return -1;
    800015ca:	557d                	li	a0,-1
    800015cc:	b769                	j	80001556 <cow_alloc+0x3e>
  if(pte == 0) return -1;
    800015ce:	557d                	li	a0,-1
    800015d0:	b759                	j	80001556 <cow_alloc+0x3e>
  if(pa == 0) return -1;
    800015d2:	557d                	li	a0,-1
    800015d4:	b749                	j	80001556 <cow_alloc+0x3e>
    if (mem == 0) return -1;
    800015d6:	557d                	li	a0,-1
    800015d8:	bfbd                	j	80001556 <cow_alloc+0x3e>

00000000800015da <walkcowaddr>:
  if (va >= MAXVA)
    800015da:	57fd                	li	a5,-1
    800015dc:	83e9                	srl	a5,a5,0x1a
    800015de:	0ab7ea63          	bltu	a5,a1,80001692 <walkcowaddr+0xb8>
int walkcowaddr(pagetable_t pagetable, uint64 va) {
    800015e2:	7139                	add	sp,sp,-64
    800015e4:	fc06                	sd	ra,56(sp)
    800015e6:	f822                	sd	s0,48(sp)
    800015e8:	f426                	sd	s1,40(sp)
    800015ea:	f04a                	sd	s2,32(sp)
    800015ec:	ec4e                	sd	s3,24(sp)
    800015ee:	e852                	sd	s4,16(sp)
    800015f0:	e456                	sd	s5,8(sp)
    800015f2:	0080                	add	s0,sp,64
    800015f4:	89aa                	mv	s3,a0
    800015f6:	84ae                	mv	s1,a1
  pte = walk(pagetable, va, 0);
    800015f8:	4601                	li	a2,0
    800015fa:	00000097          	auipc	ra,0x0
    800015fe:	ace080e7          	jalr	-1330(ra) # 800010c8 <walk>
    80001602:	892a                	mv	s2,a0
  if (pte == 0)
    80001604:	c949                	beqz	a0,80001696 <walkcowaddr+0xbc>
  if ((*pte & PTE_V) == 0)
    80001606:	00053a03          	ld	s4,0(a0)
  if ((*pte & PTE_U) == 0)
    8000160a:	011a7713          	and	a4,s4,17
    8000160e:	47c5                	li	a5,17
    80001610:	08f71563          	bne	a4,a5,8000169a <walkcowaddr+0xc0>
  if ((*pte & PTE_W) == 0) {
    80001614:	004a7793          	and	a5,s4,4
  return 0;
    80001618:	4501                	li	a0,0
  if ((*pte & PTE_W) == 0) {
    8000161a:	efa1                	bnez	a5,80001672 <walkcowaddr+0x98>
    if ((*pte & PTE_C) == 0) {
    8000161c:	100a7793          	and	a5,s4,256
    80001620:	cfbd                	beqz	a5,8000169e <walkcowaddr+0xc4>
    if ((mem = kalloc()) == 0) {
    80001622:	fffff097          	auipc	ra,0xfffff
    80001626:	5c8080e7          	jalr	1480(ra) # 80000bea <kalloc>
    8000162a:	8aaa                	mv	s5,a0
    8000162c:	c93d                	beqz	a0,800016a2 <walkcowaddr+0xc8>
  pa = PTE2PA(*pte);
    8000162e:	00aa5593          	srl	a1,s4,0xa
    memmove(mem, (void*)pa, PGSIZE);
    80001632:	6605                	lui	a2,0x1
    80001634:	05b2                	sll	a1,a1,0xc
    80001636:	00000097          	auipc	ra,0x0
    8000163a:	808080e7          	jalr	-2040(ra) # 80000e3e <memmove>
    flags = (PTE_FLAGS(*pte) & (~PTE_C)) | PTE_W;
    8000163e:	00093903          	ld	s2,0(s2)
    80001642:	2fb97913          	and	s2,s2,763
    80001646:	00496913          	or	s2,s2,4
    uvmunmap(pagetable, PGROUNDDOWN(va), 1, 1);
    8000164a:	77fd                	lui	a5,0xfffff
    8000164c:	8cfd                	and	s1,s1,a5
    8000164e:	4685                	li	a3,1
    80001650:	4605                	li	a2,1
    80001652:	85a6                	mv	a1,s1
    80001654:	854e                	mv	a0,s3
    80001656:	00000097          	auipc	ra,0x0
    8000165a:	dfe080e7          	jalr	-514(ra) # 80001454 <uvmunmap>
    if (mappages(pagetable, PGROUNDDOWN(va), PGSIZE, (uint64)mem, flags) != 0) {
    8000165e:	874a                	mv	a4,s2
    80001660:	86d6                	mv	a3,s5
    80001662:	6605                	lui	a2,0x1
    80001664:	85a6                	mv	a1,s1
    80001666:	854e                	mv	a0,s3
    80001668:	00000097          	auipc	ra,0x0
    8000166c:	c54080e7          	jalr	-940(ra) # 800012bc <mappages>
    80001670:	e911                	bnez	a0,80001684 <walkcowaddr+0xaa>
}
    80001672:	70e2                	ld	ra,56(sp)
    80001674:	7442                	ld	s0,48(sp)
    80001676:	74a2                	ld	s1,40(sp)
    80001678:	7902                	ld	s2,32(sp)
    8000167a:	69e2                	ld	s3,24(sp)
    8000167c:	6a42                	ld	s4,16(sp)
    8000167e:	6aa2                	ld	s5,8(sp)
    80001680:	6121                	add	sp,sp,64
    80001682:	8082                	ret
      kfree(mem);
    80001684:	8556                	mv	a0,s5
    80001686:	fffff097          	auipc	ra,0xfffff
    8000168a:	402080e7          	jalr	1026(ra) # 80000a88 <kfree>
      return -1;
    8000168e:	557d                	li	a0,-1
    80001690:	b7cd                	j	80001672 <walkcowaddr+0x98>
    return -1;
    80001692:	557d                	li	a0,-1
}
    80001694:	8082                	ret
      return -1;
    80001696:	557d                	li	a0,-1
    80001698:	bfe9                	j	80001672 <walkcowaddr+0x98>
    return -1;
    8000169a:	557d                	li	a0,-1
    8000169c:	bfd9                	j	80001672 <walkcowaddr+0x98>
        return -1;
    8000169e:	557d                	li	a0,-1
    800016a0:	bfc9                	j	80001672 <walkcowaddr+0x98>
      return -1;
    800016a2:	557d                	li	a0,-1
    800016a4:	b7f9                	j	80001672 <walkcowaddr+0x98>

00000000800016a6 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800016a6:	1101                	add	sp,sp,-32
    800016a8:	ec06                	sd	ra,24(sp)
    800016aa:	e822                	sd	s0,16(sp)
    800016ac:	e426                	sd	s1,8(sp)
    800016ae:	1000                	add	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800016b0:	fffff097          	auipc	ra,0xfffff
    800016b4:	53a080e7          	jalr	1338(ra) # 80000bea <kalloc>
    800016b8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800016ba:	c519                	beqz	a0,800016c8 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800016bc:	6605                	lui	a2,0x1
    800016be:	4581                	li	a1,0
    800016c0:	fffff097          	auipc	ra,0xfffff
    800016c4:	722080e7          	jalr	1826(ra) # 80000de2 <memset>
  return pagetable;
}
    800016c8:	8526                	mv	a0,s1
    800016ca:	60e2                	ld	ra,24(sp)
    800016cc:	6442                	ld	s0,16(sp)
    800016ce:	64a2                	ld	s1,8(sp)
    800016d0:	6105                	add	sp,sp,32
    800016d2:	8082                	ret

00000000800016d4 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800016d4:	7179                	add	sp,sp,-48
    800016d6:	f406                	sd	ra,40(sp)
    800016d8:	f022                	sd	s0,32(sp)
    800016da:	ec26                	sd	s1,24(sp)
    800016dc:	e84a                	sd	s2,16(sp)
    800016de:	e44e                	sd	s3,8(sp)
    800016e0:	e052                	sd	s4,0(sp)
    800016e2:	1800                	add	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800016e4:	6785                	lui	a5,0x1
    800016e6:	04f67863          	bgeu	a2,a5,80001736 <uvminit+0x62>
    800016ea:	8a2a                	mv	s4,a0
    800016ec:	89ae                	mv	s3,a1
    800016ee:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800016f0:	fffff097          	auipc	ra,0xfffff
    800016f4:	4fa080e7          	jalr	1274(ra) # 80000bea <kalloc>
    800016f8:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800016fa:	6605                	lui	a2,0x1
    800016fc:	4581                	li	a1,0
    800016fe:	fffff097          	auipc	ra,0xfffff
    80001702:	6e4080e7          	jalr	1764(ra) # 80000de2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001706:	4779                	li	a4,30
    80001708:	86ca                	mv	a3,s2
    8000170a:	6605                	lui	a2,0x1
    8000170c:	4581                	li	a1,0
    8000170e:	8552                	mv	a0,s4
    80001710:	00000097          	auipc	ra,0x0
    80001714:	bac080e7          	jalr	-1108(ra) # 800012bc <mappages>
  memmove(mem, src, sz);
    80001718:	8626                	mv	a2,s1
    8000171a:	85ce                	mv	a1,s3
    8000171c:	854a                	mv	a0,s2
    8000171e:	fffff097          	auipc	ra,0xfffff
    80001722:	720080e7          	jalr	1824(ra) # 80000e3e <memmove>
}
    80001726:	70a2                	ld	ra,40(sp)
    80001728:	7402                	ld	s0,32(sp)
    8000172a:	64e2                	ld	s1,24(sp)
    8000172c:	6942                	ld	s2,16(sp)
    8000172e:	69a2                	ld	s3,8(sp)
    80001730:	6a02                	ld	s4,0(sp)
    80001732:	6145                	add	sp,sp,48
    80001734:	8082                	ret
    panic("inituvm: more than a page");
    80001736:	00007517          	auipc	a0,0x7
    8000173a:	a1250513          	add	a0,a0,-1518 # 80008148 <digits+0x108>
    8000173e:	fffff097          	auipc	ra,0xfffff
    80001742:	e04080e7          	jalr	-508(ra) # 80000542 <panic>

0000000080001746 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001746:	1101                	add	sp,sp,-32
    80001748:	ec06                	sd	ra,24(sp)
    8000174a:	e822                	sd	s0,16(sp)
    8000174c:	e426                	sd	s1,8(sp)
    8000174e:	1000                	add	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001750:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001752:	00b67d63          	bgeu	a2,a1,8000176c <uvmdealloc+0x26>
    80001756:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001758:	6785                	lui	a5,0x1
    8000175a:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000175c:	00f60733          	add	a4,a2,a5
    80001760:	76fd                	lui	a3,0xfffff
    80001762:	8f75                	and	a4,a4,a3
    80001764:	97ae                	add	a5,a5,a1
    80001766:	8ff5                	and	a5,a5,a3
    80001768:	00f76863          	bltu	a4,a5,80001778 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000176c:	8526                	mv	a0,s1
    8000176e:	60e2                	ld	ra,24(sp)
    80001770:	6442                	ld	s0,16(sp)
    80001772:	64a2                	ld	s1,8(sp)
    80001774:	6105                	add	sp,sp,32
    80001776:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001778:	8f99                	sub	a5,a5,a4
    8000177a:	83b1                	srl	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000177c:	4685                	li	a3,1
    8000177e:	0007861b          	sext.w	a2,a5
    80001782:	85ba                	mv	a1,a4
    80001784:	00000097          	auipc	ra,0x0
    80001788:	cd0080e7          	jalr	-816(ra) # 80001454 <uvmunmap>
    8000178c:	b7c5                	j	8000176c <uvmdealloc+0x26>

000000008000178e <uvmalloc>:
  if(newsz < oldsz)
    8000178e:	0ab66163          	bltu	a2,a1,80001830 <uvmalloc+0xa2>
{
    80001792:	7139                	add	sp,sp,-64
    80001794:	fc06                	sd	ra,56(sp)
    80001796:	f822                	sd	s0,48(sp)
    80001798:	f426                	sd	s1,40(sp)
    8000179a:	f04a                	sd	s2,32(sp)
    8000179c:	ec4e                	sd	s3,24(sp)
    8000179e:	e852                	sd	s4,16(sp)
    800017a0:	e456                	sd	s5,8(sp)
    800017a2:	0080                	add	s0,sp,64
    800017a4:	8aaa                	mv	s5,a0
    800017a6:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800017a8:	6785                	lui	a5,0x1
    800017aa:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800017ac:	95be                	add	a1,a1,a5
    800017ae:	77fd                	lui	a5,0xfffff
    800017b0:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800017b4:	08c9f063          	bgeu	s3,a2,80001834 <uvmalloc+0xa6>
    800017b8:	894e                	mv	s2,s3
    mem = kalloc();
    800017ba:	fffff097          	auipc	ra,0xfffff
    800017be:	430080e7          	jalr	1072(ra) # 80000bea <kalloc>
    800017c2:	84aa                	mv	s1,a0
    if(mem == 0){
    800017c4:	c51d                	beqz	a0,800017f2 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800017c6:	6605                	lui	a2,0x1
    800017c8:	4581                	li	a1,0
    800017ca:	fffff097          	auipc	ra,0xfffff
    800017ce:	618080e7          	jalr	1560(ra) # 80000de2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800017d2:	4779                	li	a4,30
    800017d4:	86a6                	mv	a3,s1
    800017d6:	6605                	lui	a2,0x1
    800017d8:	85ca                	mv	a1,s2
    800017da:	8556                	mv	a0,s5
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	ae0080e7          	jalr	-1312(ra) # 800012bc <mappages>
    800017e4:	e905                	bnez	a0,80001814 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800017e6:	6785                	lui	a5,0x1
    800017e8:	993e                	add	s2,s2,a5
    800017ea:	fd4968e3          	bltu	s2,s4,800017ba <uvmalloc+0x2c>
  return newsz;
    800017ee:	8552                	mv	a0,s4
    800017f0:	a809                	j	80001802 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800017f2:	864e                	mv	a2,s3
    800017f4:	85ca                	mv	a1,s2
    800017f6:	8556                	mv	a0,s5
    800017f8:	00000097          	auipc	ra,0x0
    800017fc:	f4e080e7          	jalr	-178(ra) # 80001746 <uvmdealloc>
      return 0;
    80001800:	4501                	li	a0,0
}
    80001802:	70e2                	ld	ra,56(sp)
    80001804:	7442                	ld	s0,48(sp)
    80001806:	74a2                	ld	s1,40(sp)
    80001808:	7902                	ld	s2,32(sp)
    8000180a:	69e2                	ld	s3,24(sp)
    8000180c:	6a42                	ld	s4,16(sp)
    8000180e:	6aa2                	ld	s5,8(sp)
    80001810:	6121                	add	sp,sp,64
    80001812:	8082                	ret
      kfree(mem);
    80001814:	8526                	mv	a0,s1
    80001816:	fffff097          	auipc	ra,0xfffff
    8000181a:	272080e7          	jalr	626(ra) # 80000a88 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000181e:	864e                	mv	a2,s3
    80001820:	85ca                	mv	a1,s2
    80001822:	8556                	mv	a0,s5
    80001824:	00000097          	auipc	ra,0x0
    80001828:	f22080e7          	jalr	-222(ra) # 80001746 <uvmdealloc>
      return 0;
    8000182c:	4501                	li	a0,0
    8000182e:	bfd1                	j	80001802 <uvmalloc+0x74>
    return oldsz;
    80001830:	852e                	mv	a0,a1
}
    80001832:	8082                	ret
  return newsz;
    80001834:	8532                	mv	a0,a2
    80001836:	b7f1                	j	80001802 <uvmalloc+0x74>

0000000080001838 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001838:	7179                	add	sp,sp,-48
    8000183a:	f406                	sd	ra,40(sp)
    8000183c:	f022                	sd	s0,32(sp)
    8000183e:	ec26                	sd	s1,24(sp)
    80001840:	e84a                	sd	s2,16(sp)
    80001842:	e44e                	sd	s3,8(sp)
    80001844:	e052                	sd	s4,0(sp)
    80001846:	1800                	add	s0,sp,48
    80001848:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000184a:	84aa                	mv	s1,a0
    8000184c:	6905                	lui	s2,0x1
    8000184e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001850:	4985                	li	s3,1
    80001852:	a829                	j	8000186c <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001854:	83a9                	srl	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001856:	00c79513          	sll	a0,a5,0xc
    8000185a:	00000097          	auipc	ra,0x0
    8000185e:	fde080e7          	jalr	-34(ra) # 80001838 <freewalk>
      pagetable[i] = 0;
    80001862:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001866:	04a1                	add	s1,s1,8
    80001868:	03248163          	beq	s1,s2,8000188a <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000186c:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000186e:	00f7f713          	and	a4,a5,15
    80001872:	ff3701e3          	beq	a4,s3,80001854 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001876:	8b85                	and	a5,a5,1
    80001878:	d7fd                	beqz	a5,80001866 <freewalk+0x2e>
      panic("freewalk: leaf");
    8000187a:	00007517          	auipc	a0,0x7
    8000187e:	8ee50513          	add	a0,a0,-1810 # 80008168 <digits+0x128>
    80001882:	fffff097          	auipc	ra,0xfffff
    80001886:	cc0080e7          	jalr	-832(ra) # 80000542 <panic>
    }
  }
  kfree((void*)pagetable);
    8000188a:	8552                	mv	a0,s4
    8000188c:	fffff097          	auipc	ra,0xfffff
    80001890:	1fc080e7          	jalr	508(ra) # 80000a88 <kfree>
}
    80001894:	70a2                	ld	ra,40(sp)
    80001896:	7402                	ld	s0,32(sp)
    80001898:	64e2                	ld	s1,24(sp)
    8000189a:	6942                	ld	s2,16(sp)
    8000189c:	69a2                	ld	s3,8(sp)
    8000189e:	6a02                	ld	s4,0(sp)
    800018a0:	6145                	add	sp,sp,48
    800018a2:	8082                	ret

00000000800018a4 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800018a4:	1101                	add	sp,sp,-32
    800018a6:	ec06                	sd	ra,24(sp)
    800018a8:	e822                	sd	s0,16(sp)
    800018aa:	e426                	sd	s1,8(sp)
    800018ac:	1000                	add	s0,sp,32
    800018ae:	84aa                	mv	s1,a0
  if(sz > 0)
    800018b0:	e999                	bnez	a1,800018c6 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800018b2:	8526                	mv	a0,s1
    800018b4:	00000097          	auipc	ra,0x0
    800018b8:	f84080e7          	jalr	-124(ra) # 80001838 <freewalk>
}
    800018bc:	60e2                	ld	ra,24(sp)
    800018be:	6442                	ld	s0,16(sp)
    800018c0:	64a2                	ld	s1,8(sp)
    800018c2:	6105                	add	sp,sp,32
    800018c4:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800018c6:	6785                	lui	a5,0x1
    800018c8:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800018ca:	95be                	add	a1,a1,a5
    800018cc:	4685                	li	a3,1
    800018ce:	00c5d613          	srl	a2,a1,0xc
    800018d2:	4581                	li	a1,0
    800018d4:	00000097          	auipc	ra,0x0
    800018d8:	b80080e7          	jalr	-1152(ra) # 80001454 <uvmunmap>
    800018dc:	bfd9                	j	800018b2 <uvmfree+0xe>

00000000800018de <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    800018de:	7139                	add	sp,sp,-64
    800018e0:	fc06                	sd	ra,56(sp)
    800018e2:	f822                	sd	s0,48(sp)
    800018e4:	f426                	sd	s1,40(sp)
    800018e6:	f04a                	sd	s2,32(sp)
    800018e8:	ec4e                	sd	s3,24(sp)
    800018ea:	e852                	sd	s4,16(sp)
    800018ec:	e456                	sd	s5,8(sp)
    800018ee:	e05a                	sd	s6,0(sp)
    800018f0:	0080                	add	s0,sp,64
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  //char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800018f2:	ca55                	beqz	a2,800019a6 <uvmcopy+0xc8>
    800018f4:	8b2a                	mv	s6,a0
    800018f6:	8aae                	mv	s5,a1
    800018f8:	8a32                	mv	s4,a2
    800018fa:	4481                	li	s1,0
    800018fc:	a881                	j	8000194c <uvmcopy+0x6e>
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    800018fe:	00007517          	auipc	a0,0x7
    80001902:	87a50513          	add	a0,a0,-1926 # 80008178 <digits+0x138>
    80001906:	fffff097          	auipc	ra,0xfffff
    8000190a:	c3c080e7          	jalr	-964(ra) # 80000542 <panic>
    if((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");
    8000190e:	00007517          	auipc	a0,0x7
    80001912:	88a50513          	add	a0,a0,-1910 # 80008198 <digits+0x158>
    80001916:	fffff097          	auipc	ra,0xfffff
    8000191a:	c2c080e7          	jalr	-980(ra) # 80000542 <panic>
    pa = PTE2PA(*pte);
    //修改标志位,设置该pte是cow，并不可写
    if(*pte&PTE_W) *pte = (*pte & (~PTE_W)) | PTE_C;
    //取消分配物理内存
    flags = PTE_FLAGS(*pte);
    8000191e:	6118                	ld	a4,0(a0)
    // if((mem = kalloc()) == 0)
    //   goto err;
    // memmove(mem, (char*)pa, PGSIZE);
    if(mappages(new, i, PGSIZE, pa, flags) != 0){
    80001920:	3ff77713          	and	a4,a4,1023
    80001924:	86ca                	mv	a3,s2
    80001926:	6605                	lui	a2,0x1
    80001928:	85a6                	mv	a1,s1
    8000192a:	8556                	mv	a0,s5
    8000192c:	00000097          	auipc	ra,0x0
    80001930:	990080e7          	jalr	-1648(ra) # 800012bc <mappages>
    80001934:	89aa                	mv	s3,a0
    80001936:	e139                	bnez	a0,8000197c <uvmcopy+0x9e>
      //kfree(mem);
      goto err;
    }
    //计数增加
    cownum((void *)pa,1);//page_cow[COW_INDEX(pa)]++;
    80001938:	4585                	li	a1,1
    8000193a:	854a                	mv	a0,s2
    8000193c:	fffff097          	auipc	ra,0xfffff
    80001940:	0d2080e7          	jalr	210(ra) # 80000a0e <cownum>
  for(i = 0; i < sz; i += PGSIZE){
    80001944:	6785                	lui	a5,0x1
    80001946:	94be                	add	s1,s1,a5
    80001948:	0544f463          	bgeu	s1,s4,80001990 <uvmcopy+0xb2>
    if((pte = walk(old, i, 0)) == 0)
    8000194c:	4601                	li	a2,0
    8000194e:	85a6                	mv	a1,s1
    80001950:	855a                	mv	a0,s6
    80001952:	fffff097          	auipc	ra,0xfffff
    80001956:	776080e7          	jalr	1910(ra) # 800010c8 <walk>
    8000195a:	d155                	beqz	a0,800018fe <uvmcopy+0x20>
    if((*pte & PTE_V) == 0)
    8000195c:	611c                	ld	a5,0(a0)
    8000195e:	0017f713          	and	a4,a5,1
    80001962:	d755                	beqz	a4,8000190e <uvmcopy+0x30>
    pa = PTE2PA(*pte);
    80001964:	00a7d913          	srl	s2,a5,0xa
    80001968:	0932                	sll	s2,s2,0xc
    if(*pte&PTE_W) *pte = (*pte & (~PTE_W)) | PTE_C;
    8000196a:	0047f713          	and	a4,a5,4
    8000196e:	db45                	beqz	a4,8000191e <uvmcopy+0x40>
    80001970:	efb7f793          	and	a5,a5,-261
    80001974:	1007e793          	or	a5,a5,256
    80001978:	e11c                	sd	a5,0(a0)
    8000197a:	b755                	j	8000191e <uvmcopy+0x40>
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000197c:	4685                	li	a3,1
    8000197e:	00c4d613          	srl	a2,s1,0xc
    80001982:	4581                	li	a1,0
    80001984:	8556                	mv	a0,s5
    80001986:	00000097          	auipc	ra,0x0
    8000198a:	ace080e7          	jalr	-1330(ra) # 80001454 <uvmunmap>
  return -1;
    8000198e:	59fd                	li	s3,-1
}
    80001990:	854e                	mv	a0,s3
    80001992:	70e2                	ld	ra,56(sp)
    80001994:	7442                	ld	s0,48(sp)
    80001996:	74a2                	ld	s1,40(sp)
    80001998:	7902                	ld	s2,32(sp)
    8000199a:	69e2                	ld	s3,24(sp)
    8000199c:	6a42                	ld	s4,16(sp)
    8000199e:	6aa2                	ld	s5,8(sp)
    800019a0:	6b02                	ld	s6,0(sp)
    800019a2:	6121                	add	sp,sp,64
    800019a4:	8082                	ret
  return 0;
    800019a6:	4981                	li	s3,0
    800019a8:	b7e5                	j	80001990 <uvmcopy+0xb2>

00000000800019aa <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800019aa:	1141                	add	sp,sp,-16
    800019ac:	e406                	sd	ra,8(sp)
    800019ae:	e022                	sd	s0,0(sp)
    800019b0:	0800                	add	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800019b2:	4601                	li	a2,0
    800019b4:	fffff097          	auipc	ra,0xfffff
    800019b8:	714080e7          	jalr	1812(ra) # 800010c8 <walk>
  if(pte == 0)
    800019bc:	c901                	beqz	a0,800019cc <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800019be:	611c                	ld	a5,0(a0)
    800019c0:	9bbd                	and	a5,a5,-17
    800019c2:	e11c                	sd	a5,0(a0)
}
    800019c4:	60a2                	ld	ra,8(sp)
    800019c6:	6402                	ld	s0,0(sp)
    800019c8:	0141                	add	sp,sp,16
    800019ca:	8082                	ret
    panic("uvmclear");
    800019cc:	00006517          	auipc	a0,0x6
    800019d0:	7ec50513          	add	a0,a0,2028 # 800081b8 <digits+0x178>
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	b6e080e7          	jalr	-1170(ra) # 80000542 <panic>

00000000800019dc <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800019dc:	c6c9                	beqz	a3,80001a66 <copyout+0x8a>
{
    800019de:	715d                	add	sp,sp,-80
    800019e0:	e486                	sd	ra,72(sp)
    800019e2:	e0a2                	sd	s0,64(sp)
    800019e4:	fc26                	sd	s1,56(sp)
    800019e6:	f84a                	sd	s2,48(sp)
    800019e8:	f44e                	sd	s3,40(sp)
    800019ea:	f052                	sd	s4,32(sp)
    800019ec:	ec56                	sd	s5,24(sp)
    800019ee:	e85a                	sd	s6,16(sp)
    800019f0:	e45e                	sd	s7,8(sp)
    800019f2:	e062                	sd	s8,0(sp)
    800019f4:	0880                	add	s0,sp,80
    800019f6:	8aaa                	mv	s5,a0
    800019f8:	89ae                	mv	s3,a1
    800019fa:	8b32                	mv	s6,a2
    800019fc:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    800019fe:	7c7d                	lui	s8,0xfffff
    if (cow_alloc2(pagetable, va0) == 0) return -1;
    //if(cow_alloc(pagetable, va0)!=0) return -1;
    pa0 = walkaddr(pagetable, va0); //lab6
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001a00:	6b85                	lui	s7,0x1
    80001a02:	a015                	j	80001a26 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001a04:	412989b3          	sub	s3,s3,s2
    80001a08:	0004861b          	sext.w	a2,s1
    80001a0c:	85da                	mv	a1,s6
    80001a0e:	954e                	add	a0,a0,s3
    80001a10:	fffff097          	auipc	ra,0xfffff
    80001a14:	42e080e7          	jalr	1070(ra) # 80000e3e <memmove>

    len -= n;
    80001a18:	409a0a33          	sub	s4,s4,s1
    src += n;
    80001a1c:	9b26                	add	s6,s6,s1
    dstva = va0 + PGSIZE;
    80001a1e:	017909b3          	add	s3,s2,s7
  while(len > 0){
    80001a22:	040a0063          	beqz	s4,80001a62 <copyout+0x86>
    va0 = PGROUNDDOWN(dstva);
    80001a26:	0189f933          	and	s2,s3,s8
    if (is_cow(pagetable, va0) == 0) return -1;
    80001a2a:	85ca                	mv	a1,s2
    80001a2c:	8556                	mv	a0,s5
    80001a2e:	fffff097          	auipc	ra,0xfffff
    80001a32:	782080e7          	jalr	1922(ra) # 800011b0 <is_cow>
    80001a36:	c915                	beqz	a0,80001a6a <copyout+0x8e>
    if (cow_alloc2(pagetable, va0) == 0) return -1;
    80001a38:	85ca                	mv	a1,s2
    80001a3a:	8556                	mv	a0,s5
    80001a3c:	fffff097          	auipc	ra,0xfffff
    80001a40:	7aa080e7          	jalr	1962(ra) # 800011e6 <cow_alloc2>
    80001a44:	c121                	beqz	a0,80001a84 <copyout+0xa8>
    pa0 = walkaddr(pagetable, va0); //lab6
    80001a46:	85ca                	mv	a1,s2
    80001a48:	8556                	mv	a0,s5
    80001a4a:	fffff097          	auipc	ra,0xfffff
    80001a4e:	724080e7          	jalr	1828(ra) # 8000116e <walkaddr>
    if(pa0 == 0)
    80001a52:	c91d                	beqz	a0,80001a88 <copyout+0xac>
    n = PGSIZE - (dstva - va0);
    80001a54:	413904b3          	sub	s1,s2,s3
    80001a58:	94de                	add	s1,s1,s7
    80001a5a:	fa9a75e3          	bgeu	s4,s1,80001a04 <copyout+0x28>
    80001a5e:	84d2                	mv	s1,s4
    80001a60:	b755                	j	80001a04 <copyout+0x28>
  }
  return 0;
    80001a62:	4501                	li	a0,0
    80001a64:	a021                	j	80001a6c <copyout+0x90>
    80001a66:	4501                	li	a0,0
}
    80001a68:	8082                	ret
    if (is_cow(pagetable, va0) == 0) return -1;
    80001a6a:	557d                	li	a0,-1
}
    80001a6c:	60a6                	ld	ra,72(sp)
    80001a6e:	6406                	ld	s0,64(sp)
    80001a70:	74e2                	ld	s1,56(sp)
    80001a72:	7942                	ld	s2,48(sp)
    80001a74:	79a2                	ld	s3,40(sp)
    80001a76:	7a02                	ld	s4,32(sp)
    80001a78:	6ae2                	ld	s5,24(sp)
    80001a7a:	6b42                	ld	s6,16(sp)
    80001a7c:	6ba2                	ld	s7,8(sp)
    80001a7e:	6c02                	ld	s8,0(sp)
    80001a80:	6161                	add	sp,sp,80
    80001a82:	8082                	ret
    if (cow_alloc2(pagetable, va0) == 0) return -1;
    80001a84:	557d                	li	a0,-1
    80001a86:	b7dd                	j	80001a6c <copyout+0x90>
      return -1;
    80001a88:	557d                	li	a0,-1
    80001a8a:	b7cd                	j	80001a6c <copyout+0x90>

0000000080001a8c <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001a8c:	caa5                	beqz	a3,80001afc <copyin+0x70>
{
    80001a8e:	715d                	add	sp,sp,-80
    80001a90:	e486                	sd	ra,72(sp)
    80001a92:	e0a2                	sd	s0,64(sp)
    80001a94:	fc26                	sd	s1,56(sp)
    80001a96:	f84a                	sd	s2,48(sp)
    80001a98:	f44e                	sd	s3,40(sp)
    80001a9a:	f052                	sd	s4,32(sp)
    80001a9c:	ec56                	sd	s5,24(sp)
    80001a9e:	e85a                	sd	s6,16(sp)
    80001aa0:	e45e                	sd	s7,8(sp)
    80001aa2:	e062                	sd	s8,0(sp)
    80001aa4:	0880                	add	s0,sp,80
    80001aa6:	8b2a                	mv	s6,a0
    80001aa8:	8a2e                	mv	s4,a1
    80001aaa:	8c32                	mv	s8,a2
    80001aac:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001aae:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001ab0:	6a85                	lui	s5,0x1
    80001ab2:	a01d                	j	80001ad8 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001ab4:	018505b3          	add	a1,a0,s8
    80001ab8:	0004861b          	sext.w	a2,s1
    80001abc:	412585b3          	sub	a1,a1,s2
    80001ac0:	8552                	mv	a0,s4
    80001ac2:	fffff097          	auipc	ra,0xfffff
    80001ac6:	37c080e7          	jalr	892(ra) # 80000e3e <memmove>

    len -= n;
    80001aca:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001ace:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001ad0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001ad4:	02098263          	beqz	s3,80001af8 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001ad8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001adc:	85ca                	mv	a1,s2
    80001ade:	855a                	mv	a0,s6
    80001ae0:	fffff097          	auipc	ra,0xfffff
    80001ae4:	68e080e7          	jalr	1678(ra) # 8000116e <walkaddr>
    if(pa0 == 0)
    80001ae8:	cd01                	beqz	a0,80001b00 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001aea:	418904b3          	sub	s1,s2,s8
    80001aee:	94d6                	add	s1,s1,s5
    80001af0:	fc99f2e3          	bgeu	s3,s1,80001ab4 <copyin+0x28>
    80001af4:	84ce                	mv	s1,s3
    80001af6:	bf7d                	j	80001ab4 <copyin+0x28>
  }
  return 0;
    80001af8:	4501                	li	a0,0
    80001afa:	a021                	j	80001b02 <copyin+0x76>
    80001afc:	4501                	li	a0,0
}
    80001afe:	8082                	ret
      return -1;
    80001b00:	557d                	li	a0,-1
}
    80001b02:	60a6                	ld	ra,72(sp)
    80001b04:	6406                	ld	s0,64(sp)
    80001b06:	74e2                	ld	s1,56(sp)
    80001b08:	7942                	ld	s2,48(sp)
    80001b0a:	79a2                	ld	s3,40(sp)
    80001b0c:	7a02                	ld	s4,32(sp)
    80001b0e:	6ae2                	ld	s5,24(sp)
    80001b10:	6b42                	ld	s6,16(sp)
    80001b12:	6ba2                	ld	s7,8(sp)
    80001b14:	6c02                	ld	s8,0(sp)
    80001b16:	6161                	add	sp,sp,80
    80001b18:	8082                	ret

0000000080001b1a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001b1a:	c2dd                	beqz	a3,80001bc0 <copyinstr+0xa6>
{
    80001b1c:	715d                	add	sp,sp,-80
    80001b1e:	e486                	sd	ra,72(sp)
    80001b20:	e0a2                	sd	s0,64(sp)
    80001b22:	fc26                	sd	s1,56(sp)
    80001b24:	f84a                	sd	s2,48(sp)
    80001b26:	f44e                	sd	s3,40(sp)
    80001b28:	f052                	sd	s4,32(sp)
    80001b2a:	ec56                	sd	s5,24(sp)
    80001b2c:	e85a                	sd	s6,16(sp)
    80001b2e:	e45e                	sd	s7,8(sp)
    80001b30:	0880                	add	s0,sp,80
    80001b32:	8a2a                	mv	s4,a0
    80001b34:	8b2e                	mv	s6,a1
    80001b36:	8bb2                	mv	s7,a2
    80001b38:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001b3a:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001b3c:	6985                	lui	s3,0x1
    80001b3e:	a02d                	j	80001b68 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001b40:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001b44:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001b46:	37fd                	addw	a5,a5,-1
    80001b48:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001b4c:	60a6                	ld	ra,72(sp)
    80001b4e:	6406                	ld	s0,64(sp)
    80001b50:	74e2                	ld	s1,56(sp)
    80001b52:	7942                	ld	s2,48(sp)
    80001b54:	79a2                	ld	s3,40(sp)
    80001b56:	7a02                	ld	s4,32(sp)
    80001b58:	6ae2                	ld	s5,24(sp)
    80001b5a:	6b42                	ld	s6,16(sp)
    80001b5c:	6ba2                	ld	s7,8(sp)
    80001b5e:	6161                	add	sp,sp,80
    80001b60:	8082                	ret
    srcva = va0 + PGSIZE;
    80001b62:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001b66:	c8a9                	beqz	s1,80001bb8 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001b68:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001b6c:	85ca                	mv	a1,s2
    80001b6e:	8552                	mv	a0,s4
    80001b70:	fffff097          	auipc	ra,0xfffff
    80001b74:	5fe080e7          	jalr	1534(ra) # 8000116e <walkaddr>
    if(pa0 == 0)
    80001b78:	c131                	beqz	a0,80001bbc <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001b7a:	417906b3          	sub	a3,s2,s7
    80001b7e:	96ce                	add	a3,a3,s3
    80001b80:	00d4f363          	bgeu	s1,a3,80001b86 <copyinstr+0x6c>
    80001b84:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001b86:	955e                	add	a0,a0,s7
    80001b88:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001b8c:	daf9                	beqz	a3,80001b62 <copyinstr+0x48>
    80001b8e:	87da                	mv	a5,s6
    80001b90:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001b92:	41650633          	sub	a2,a0,s6
    while(n > 0){
    80001b96:	96da                	add	a3,a3,s6
    80001b98:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001b9a:	00f60733          	add	a4,a2,a5
    80001b9e:	00074703          	lbu	a4,0(a4)
    80001ba2:	df59                	beqz	a4,80001b40 <copyinstr+0x26>
        *dst = *p;
    80001ba4:	00e78023          	sb	a4,0(a5)
      dst++;
    80001ba8:	0785                	add	a5,a5,1
    while(n > 0){
    80001baa:	fed797e3          	bne	a5,a3,80001b98 <copyinstr+0x7e>
    80001bae:	14fd                	add	s1,s1,-1
    80001bb0:	94c2                	add	s1,s1,a6
      --max;
    80001bb2:	8c8d                	sub	s1,s1,a1
      dst++;
    80001bb4:	8b3e                	mv	s6,a5
    80001bb6:	b775                	j	80001b62 <copyinstr+0x48>
    80001bb8:	4781                	li	a5,0
    80001bba:	b771                	j	80001b46 <copyinstr+0x2c>
      return -1;
    80001bbc:	557d                	li	a0,-1
    80001bbe:	b779                	j	80001b4c <copyinstr+0x32>
  int got_null = 0;
    80001bc0:	4781                	li	a5,0
  if(got_null){
    80001bc2:	37fd                	addw	a5,a5,-1
    80001bc4:	0007851b          	sext.w	a0,a5
}
    80001bc8:	8082                	ret

0000000080001bca <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001bca:	1101                	add	sp,sp,-32
    80001bcc:	ec06                	sd	ra,24(sp)
    80001bce:	e822                	sd	s0,16(sp)
    80001bd0:	e426                	sd	s1,8(sp)
    80001bd2:	1000                	add	s0,sp,32
    80001bd4:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001bd6:	fffff097          	auipc	ra,0xfffff
    80001bda:	096080e7          	jalr	150(ra) # 80000c6c <holding>
    80001bde:	c909                	beqz	a0,80001bf0 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001be0:	749c                	ld	a5,40(s1)
    80001be2:	00978f63          	beq	a5,s1,80001c00 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001be6:	60e2                	ld	ra,24(sp)
    80001be8:	6442                	ld	s0,16(sp)
    80001bea:	64a2                	ld	s1,8(sp)
    80001bec:	6105                	add	sp,sp,32
    80001bee:	8082                	ret
    panic("wakeup1");
    80001bf0:	00006517          	auipc	a0,0x6
    80001bf4:	5d850513          	add	a0,a0,1496 # 800081c8 <digits+0x188>
    80001bf8:	fffff097          	auipc	ra,0xfffff
    80001bfc:	94a080e7          	jalr	-1718(ra) # 80000542 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001c00:	4c98                	lw	a4,24(s1)
    80001c02:	4785                	li	a5,1
    80001c04:	fef711e3          	bne	a4,a5,80001be6 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001c08:	4789                	li	a5,2
    80001c0a:	cc9c                	sw	a5,24(s1)
}
    80001c0c:	bfe9                	j	80001be6 <wakeup1+0x1c>

0000000080001c0e <procinit>:
{
    80001c0e:	715d                	add	sp,sp,-80
    80001c10:	e486                	sd	ra,72(sp)
    80001c12:	e0a2                	sd	s0,64(sp)
    80001c14:	fc26                	sd	s1,56(sp)
    80001c16:	f84a                	sd	s2,48(sp)
    80001c18:	f44e                	sd	s3,40(sp)
    80001c1a:	f052                	sd	s4,32(sp)
    80001c1c:	ec56                	sd	s5,24(sp)
    80001c1e:	e85a                	sd	s6,16(sp)
    80001c20:	e45e                	sd	s7,8(sp)
    80001c22:	0880                	add	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001c24:	00006597          	auipc	a1,0x6
    80001c28:	5ac58593          	add	a1,a1,1452 # 800081d0 <digits+0x190>
    80001c2c:	00018517          	auipc	a0,0x18
    80001c30:	d2450513          	add	a0,a0,-732 # 80019950 <pid_lock>
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	022080e7          	jalr	34(ra) # 80000c56 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c3c:	00018917          	auipc	s2,0x18
    80001c40:	12c90913          	add	s2,s2,300 # 80019d68 <proc>
      initlock(&p->lock, "proc");
    80001c44:	00006b97          	auipc	s7,0x6
    80001c48:	594b8b93          	add	s7,s7,1428 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    80001c4c:	8b4a                	mv	s6,s2
    80001c4e:	00006a97          	auipc	s5,0x6
    80001c52:	3b2a8a93          	add	s5,s5,946 # 80008000 <etext>
    80001c56:	040009b7          	lui	s3,0x4000
    80001c5a:	19fd                	add	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001c5c:	09b2                	sll	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c5e:	0001ea17          	auipc	s4,0x1e
    80001c62:	b0aa0a13          	add	s4,s4,-1270 # 8001f768 <tickslock>
      initlock(&p->lock, "proc");
    80001c66:	85de                	mv	a1,s7
    80001c68:	854a                	mv	a0,s2
    80001c6a:	fffff097          	auipc	ra,0xfffff
    80001c6e:	fec080e7          	jalr	-20(ra) # 80000c56 <initlock>
      char *pa = kalloc();
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	f78080e7          	jalr	-136(ra) # 80000bea <kalloc>
    80001c7a:	85aa                	mv	a1,a0
      if(pa == 0)
    80001c7c:	c929                	beqz	a0,80001cce <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001c7e:	416904b3          	sub	s1,s2,s6
    80001c82:	848d                	sra	s1,s1,0x3
    80001c84:	000ab783          	ld	a5,0(s5)
    80001c88:	02f484b3          	mul	s1,s1,a5
    80001c8c:	2485                	addw	s1,s1,1
    80001c8e:	00d4949b          	sllw	s1,s1,0xd
    80001c92:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001c96:	4699                	li	a3,6
    80001c98:	6605                	lui	a2,0x1
    80001c9a:	8526                	mv	a0,s1
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	6ae080e7          	jalr	1710(ra) # 8000134a <kvmmap>
      p->kstack = va;
    80001ca4:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ca8:	16890913          	add	s2,s2,360
    80001cac:	fb491de3          	bne	s2,s4,80001c66 <procinit+0x58>
  kvminithart();
    80001cb0:	fffff097          	auipc	ra,0xfffff
    80001cb4:	3f4080e7          	jalr	1012(ra) # 800010a4 <kvminithart>
}
    80001cb8:	60a6                	ld	ra,72(sp)
    80001cba:	6406                	ld	s0,64(sp)
    80001cbc:	74e2                	ld	s1,56(sp)
    80001cbe:	7942                	ld	s2,48(sp)
    80001cc0:	79a2                	ld	s3,40(sp)
    80001cc2:	7a02                	ld	s4,32(sp)
    80001cc4:	6ae2                	ld	s5,24(sp)
    80001cc6:	6b42                	ld	s6,16(sp)
    80001cc8:	6ba2                	ld	s7,8(sp)
    80001cca:	6161                	add	sp,sp,80
    80001ccc:	8082                	ret
        panic("kalloc");
    80001cce:	00006517          	auipc	a0,0x6
    80001cd2:	51250513          	add	a0,a0,1298 # 800081e0 <digits+0x1a0>
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	86c080e7          	jalr	-1940(ra) # 80000542 <panic>

0000000080001cde <cpuid>:
{
    80001cde:	1141                	add	sp,sp,-16
    80001ce0:	e422                	sd	s0,8(sp)
    80001ce2:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ce4:	8512                	mv	a0,tp
}
    80001ce6:	2501                	sext.w	a0,a0
    80001ce8:	6422                	ld	s0,8(sp)
    80001cea:	0141                	add	sp,sp,16
    80001cec:	8082                	ret

0000000080001cee <mycpu>:
mycpu(void) {
    80001cee:	1141                	add	sp,sp,-16
    80001cf0:	e422                	sd	s0,8(sp)
    80001cf2:	0800                	add	s0,sp,16
    80001cf4:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001cf6:	2781                	sext.w	a5,a5
    80001cf8:	079e                	sll	a5,a5,0x7
}
    80001cfa:	00018517          	auipc	a0,0x18
    80001cfe:	c6e50513          	add	a0,a0,-914 # 80019968 <cpus>
    80001d02:	953e                	add	a0,a0,a5
    80001d04:	6422                	ld	s0,8(sp)
    80001d06:	0141                	add	sp,sp,16
    80001d08:	8082                	ret

0000000080001d0a <myproc>:
myproc(void) {
    80001d0a:	1101                	add	sp,sp,-32
    80001d0c:	ec06                	sd	ra,24(sp)
    80001d0e:	e822                	sd	s0,16(sp)
    80001d10:	e426                	sd	s1,8(sp)
    80001d12:	1000                	add	s0,sp,32
  push_off();
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	f86080e7          	jalr	-122(ra) # 80000c9a <push_off>
    80001d1c:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001d1e:	2781                	sext.w	a5,a5
    80001d20:	079e                	sll	a5,a5,0x7
    80001d22:	00018717          	auipc	a4,0x18
    80001d26:	c2e70713          	add	a4,a4,-978 # 80019950 <pid_lock>
    80001d2a:	97ba                	add	a5,a5,a4
    80001d2c:	6f84                	ld	s1,24(a5)
  pop_off();
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	00c080e7          	jalr	12(ra) # 80000d3a <pop_off>
}
    80001d36:	8526                	mv	a0,s1
    80001d38:	60e2                	ld	ra,24(sp)
    80001d3a:	6442                	ld	s0,16(sp)
    80001d3c:	64a2                	ld	s1,8(sp)
    80001d3e:	6105                	add	sp,sp,32
    80001d40:	8082                	ret

0000000080001d42 <forkret>:
{
    80001d42:	1141                	add	sp,sp,-16
    80001d44:	e406                	sd	ra,8(sp)
    80001d46:	e022                	sd	s0,0(sp)
    80001d48:	0800                	add	s0,sp,16
  release(&myproc()->lock);
    80001d4a:	00000097          	auipc	ra,0x0
    80001d4e:	fc0080e7          	jalr	-64(ra) # 80001d0a <myproc>
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	048080e7          	jalr	72(ra) # 80000d9a <release>
  if (first) {
    80001d5a:	00007797          	auipc	a5,0x7
    80001d5e:	ab67a783          	lw	a5,-1354(a5) # 80008810 <first.1>
    80001d62:	eb89                	bnez	a5,80001d74 <forkret+0x32>
  usertrapret();
    80001d64:	00001097          	auipc	ra,0x1
    80001d68:	c1c080e7          	jalr	-996(ra) # 80002980 <usertrapret>
}
    80001d6c:	60a2                	ld	ra,8(sp)
    80001d6e:	6402                	ld	s0,0(sp)
    80001d70:	0141                	add	sp,sp,16
    80001d72:	8082                	ret
    first = 0;
    80001d74:	00007797          	auipc	a5,0x7
    80001d78:	a807ae23          	sw	zero,-1380(a5) # 80008810 <first.1>
    fsinit(ROOTDEV);
    80001d7c:	4505                	li	a0,1
    80001d7e:	00002097          	auipc	ra,0x2
    80001d82:	972080e7          	jalr	-1678(ra) # 800036f0 <fsinit>
    80001d86:	bff9                	j	80001d64 <forkret+0x22>

0000000080001d88 <allocpid>:
allocpid() {
    80001d88:	1101                	add	sp,sp,-32
    80001d8a:	ec06                	sd	ra,24(sp)
    80001d8c:	e822                	sd	s0,16(sp)
    80001d8e:	e426                	sd	s1,8(sp)
    80001d90:	e04a                	sd	s2,0(sp)
    80001d92:	1000                	add	s0,sp,32
  acquire(&pid_lock);
    80001d94:	00018917          	auipc	s2,0x18
    80001d98:	bbc90913          	add	s2,s2,-1092 # 80019950 <pid_lock>
    80001d9c:	854a                	mv	a0,s2
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	f48080e7          	jalr	-184(ra) # 80000ce6 <acquire>
  pid = nextpid;
    80001da6:	00007797          	auipc	a5,0x7
    80001daa:	a6e78793          	add	a5,a5,-1426 # 80008814 <nextpid>
    80001dae:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001db0:	0014871b          	addw	a4,s1,1
    80001db4:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001db6:	854a                	mv	a0,s2
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	fe2080e7          	jalr	-30(ra) # 80000d9a <release>
}
    80001dc0:	8526                	mv	a0,s1
    80001dc2:	60e2                	ld	ra,24(sp)
    80001dc4:	6442                	ld	s0,16(sp)
    80001dc6:	64a2                	ld	s1,8(sp)
    80001dc8:	6902                	ld	s2,0(sp)
    80001dca:	6105                	add	sp,sp,32
    80001dcc:	8082                	ret

0000000080001dce <proc_pagetable>:
{
    80001dce:	1101                	add	sp,sp,-32
    80001dd0:	ec06                	sd	ra,24(sp)
    80001dd2:	e822                	sd	s0,16(sp)
    80001dd4:	e426                	sd	s1,8(sp)
    80001dd6:	e04a                	sd	s2,0(sp)
    80001dd8:	1000                	add	s0,sp,32
    80001dda:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ddc:	00000097          	auipc	ra,0x0
    80001de0:	8ca080e7          	jalr	-1846(ra) # 800016a6 <uvmcreate>
    80001de4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001de6:	c121                	beqz	a0,80001e26 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001de8:	4729                	li	a4,10
    80001dea:	00005697          	auipc	a3,0x5
    80001dee:	21668693          	add	a3,a3,534 # 80007000 <_trampoline>
    80001df2:	6605                	lui	a2,0x1
    80001df4:	040005b7          	lui	a1,0x4000
    80001df8:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001dfa:	05b2                	sll	a1,a1,0xc
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	4c0080e7          	jalr	1216(ra) # 800012bc <mappages>
    80001e04:	02054863          	bltz	a0,80001e34 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001e08:	4719                	li	a4,6
    80001e0a:	05893683          	ld	a3,88(s2)
    80001e0e:	6605                	lui	a2,0x1
    80001e10:	020005b7          	lui	a1,0x2000
    80001e14:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001e16:	05b6                	sll	a1,a1,0xd
    80001e18:	8526                	mv	a0,s1
    80001e1a:	fffff097          	auipc	ra,0xfffff
    80001e1e:	4a2080e7          	jalr	1186(ra) # 800012bc <mappages>
    80001e22:	02054163          	bltz	a0,80001e44 <proc_pagetable+0x76>
}
    80001e26:	8526                	mv	a0,s1
    80001e28:	60e2                	ld	ra,24(sp)
    80001e2a:	6442                	ld	s0,16(sp)
    80001e2c:	64a2                	ld	s1,8(sp)
    80001e2e:	6902                	ld	s2,0(sp)
    80001e30:	6105                	add	sp,sp,32
    80001e32:	8082                	ret
    uvmfree(pagetable, 0);
    80001e34:	4581                	li	a1,0
    80001e36:	8526                	mv	a0,s1
    80001e38:	00000097          	auipc	ra,0x0
    80001e3c:	a6c080e7          	jalr	-1428(ra) # 800018a4 <uvmfree>
    return 0;
    80001e40:	4481                	li	s1,0
    80001e42:	b7d5                	j	80001e26 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e44:	4681                	li	a3,0
    80001e46:	4605                	li	a2,1
    80001e48:	040005b7          	lui	a1,0x4000
    80001e4c:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e4e:	05b2                	sll	a1,a1,0xc
    80001e50:	8526                	mv	a0,s1
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	602080e7          	jalr	1538(ra) # 80001454 <uvmunmap>
    uvmfree(pagetable, 0);
    80001e5a:	4581                	li	a1,0
    80001e5c:	8526                	mv	a0,s1
    80001e5e:	00000097          	auipc	ra,0x0
    80001e62:	a46080e7          	jalr	-1466(ra) # 800018a4 <uvmfree>
    return 0;
    80001e66:	4481                	li	s1,0
    80001e68:	bf7d                	j	80001e26 <proc_pagetable+0x58>

0000000080001e6a <proc_freepagetable>:
{
    80001e6a:	1101                	add	sp,sp,-32
    80001e6c:	ec06                	sd	ra,24(sp)
    80001e6e:	e822                	sd	s0,16(sp)
    80001e70:	e426                	sd	s1,8(sp)
    80001e72:	e04a                	sd	s2,0(sp)
    80001e74:	1000                	add	s0,sp,32
    80001e76:	84aa                	mv	s1,a0
    80001e78:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e7a:	4681                	li	a3,0
    80001e7c:	4605                	li	a2,1
    80001e7e:	040005b7          	lui	a1,0x4000
    80001e82:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e84:	05b2                	sll	a1,a1,0xc
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	5ce080e7          	jalr	1486(ra) # 80001454 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e8e:	4681                	li	a3,0
    80001e90:	4605                	li	a2,1
    80001e92:	020005b7          	lui	a1,0x2000
    80001e96:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001e98:	05b6                	sll	a1,a1,0xd
    80001e9a:	8526                	mv	a0,s1
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	5b8080e7          	jalr	1464(ra) # 80001454 <uvmunmap>
  uvmfree(pagetable, sz);
    80001ea4:	85ca                	mv	a1,s2
    80001ea6:	8526                	mv	a0,s1
    80001ea8:	00000097          	auipc	ra,0x0
    80001eac:	9fc080e7          	jalr	-1540(ra) # 800018a4 <uvmfree>
}
    80001eb0:	60e2                	ld	ra,24(sp)
    80001eb2:	6442                	ld	s0,16(sp)
    80001eb4:	64a2                	ld	s1,8(sp)
    80001eb6:	6902                	ld	s2,0(sp)
    80001eb8:	6105                	add	sp,sp,32
    80001eba:	8082                	ret

0000000080001ebc <freeproc>:
{
    80001ebc:	1101                	add	sp,sp,-32
    80001ebe:	ec06                	sd	ra,24(sp)
    80001ec0:	e822                	sd	s0,16(sp)
    80001ec2:	e426                	sd	s1,8(sp)
    80001ec4:	1000                	add	s0,sp,32
    80001ec6:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001ec8:	6d28                	ld	a0,88(a0)
    80001eca:	c509                	beqz	a0,80001ed4 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ecc:	fffff097          	auipc	ra,0xfffff
    80001ed0:	bbc080e7          	jalr	-1092(ra) # 80000a88 <kfree>
  p->trapframe = 0;
    80001ed4:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001ed8:	68a8                	ld	a0,80(s1)
    80001eda:	c511                	beqz	a0,80001ee6 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001edc:	64ac                	ld	a1,72(s1)
    80001ede:	00000097          	auipc	ra,0x0
    80001ee2:	f8c080e7          	jalr	-116(ra) # 80001e6a <proc_freepagetable>
  p->pagetable = 0;
    80001ee6:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001eea:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001eee:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001ef2:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001ef6:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001efa:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001efe:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001f02:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001f06:	0004ac23          	sw	zero,24(s1)
}
    80001f0a:	60e2                	ld	ra,24(sp)
    80001f0c:	6442                	ld	s0,16(sp)
    80001f0e:	64a2                	ld	s1,8(sp)
    80001f10:	6105                	add	sp,sp,32
    80001f12:	8082                	ret

0000000080001f14 <allocproc>:
{
    80001f14:	1101                	add	sp,sp,-32
    80001f16:	ec06                	sd	ra,24(sp)
    80001f18:	e822                	sd	s0,16(sp)
    80001f1a:	e426                	sd	s1,8(sp)
    80001f1c:	e04a                	sd	s2,0(sp)
    80001f1e:	1000                	add	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f20:	00018497          	auipc	s1,0x18
    80001f24:	e4848493          	add	s1,s1,-440 # 80019d68 <proc>
    80001f28:	0001e917          	auipc	s2,0x1e
    80001f2c:	84090913          	add	s2,s2,-1984 # 8001f768 <tickslock>
    acquire(&p->lock);
    80001f30:	8526                	mv	a0,s1
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	db4080e7          	jalr	-588(ra) # 80000ce6 <acquire>
    if(p->state == UNUSED) {
    80001f3a:	4c9c                	lw	a5,24(s1)
    80001f3c:	cf81                	beqz	a5,80001f54 <allocproc+0x40>
      release(&p->lock);
    80001f3e:	8526                	mv	a0,s1
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	e5a080e7          	jalr	-422(ra) # 80000d9a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f48:	16848493          	add	s1,s1,360
    80001f4c:	ff2492e3          	bne	s1,s2,80001f30 <allocproc+0x1c>
  return 0;
    80001f50:	4481                	li	s1,0
    80001f52:	a0b9                	j	80001fa0 <allocproc+0x8c>
  p->pid = allocpid();
    80001f54:	00000097          	auipc	ra,0x0
    80001f58:	e34080e7          	jalr	-460(ra) # 80001d88 <allocpid>
    80001f5c:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001f5e:	fffff097          	auipc	ra,0xfffff
    80001f62:	c8c080e7          	jalr	-884(ra) # 80000bea <kalloc>
    80001f66:	892a                	mv	s2,a0
    80001f68:	eca8                	sd	a0,88(s1)
    80001f6a:	c131                	beqz	a0,80001fae <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001f6c:	8526                	mv	a0,s1
    80001f6e:	00000097          	auipc	ra,0x0
    80001f72:	e60080e7          	jalr	-416(ra) # 80001dce <proc_pagetable>
    80001f76:	892a                	mv	s2,a0
    80001f78:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001f7a:	c129                	beqz	a0,80001fbc <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001f7c:	07000613          	li	a2,112
    80001f80:	4581                	li	a1,0
    80001f82:	06048513          	add	a0,s1,96
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	e5c080e7          	jalr	-420(ra) # 80000de2 <memset>
  p->context.ra = (uint64)forkret;
    80001f8e:	00000797          	auipc	a5,0x0
    80001f92:	db478793          	add	a5,a5,-588 # 80001d42 <forkret>
    80001f96:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001f98:	60bc                	ld	a5,64(s1)
    80001f9a:	6705                	lui	a4,0x1
    80001f9c:	97ba                	add	a5,a5,a4
    80001f9e:	f4bc                	sd	a5,104(s1)
}
    80001fa0:	8526                	mv	a0,s1
    80001fa2:	60e2                	ld	ra,24(sp)
    80001fa4:	6442                	ld	s0,16(sp)
    80001fa6:	64a2                	ld	s1,8(sp)
    80001fa8:	6902                	ld	s2,0(sp)
    80001faa:	6105                	add	sp,sp,32
    80001fac:	8082                	ret
    release(&p->lock);
    80001fae:	8526                	mv	a0,s1
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	dea080e7          	jalr	-534(ra) # 80000d9a <release>
    return 0;
    80001fb8:	84ca                	mv	s1,s2
    80001fba:	b7dd                	j	80001fa0 <allocproc+0x8c>
    freeproc(p);
    80001fbc:	8526                	mv	a0,s1
    80001fbe:	00000097          	auipc	ra,0x0
    80001fc2:	efe080e7          	jalr	-258(ra) # 80001ebc <freeproc>
    release(&p->lock);
    80001fc6:	8526                	mv	a0,s1
    80001fc8:	fffff097          	auipc	ra,0xfffff
    80001fcc:	dd2080e7          	jalr	-558(ra) # 80000d9a <release>
    return 0;
    80001fd0:	84ca                	mv	s1,s2
    80001fd2:	b7f9                	j	80001fa0 <allocproc+0x8c>

0000000080001fd4 <userinit>:
{
    80001fd4:	1101                	add	sp,sp,-32
    80001fd6:	ec06                	sd	ra,24(sp)
    80001fd8:	e822                	sd	s0,16(sp)
    80001fda:	e426                	sd	s1,8(sp)
    80001fdc:	1000                	add	s0,sp,32
  p = allocproc();
    80001fde:	00000097          	auipc	ra,0x0
    80001fe2:	f36080e7          	jalr	-202(ra) # 80001f14 <allocproc>
    80001fe6:	84aa                	mv	s1,a0
  initproc = p;
    80001fe8:	00007797          	auipc	a5,0x7
    80001fec:	02a7b823          	sd	a0,48(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ff0:	03400613          	li	a2,52
    80001ff4:	00007597          	auipc	a1,0x7
    80001ff8:	82c58593          	add	a1,a1,-2004 # 80008820 <initcode>
    80001ffc:	6928                	ld	a0,80(a0)
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	6d6080e7          	jalr	1750(ra) # 800016d4 <uvminit>
  p->sz = PGSIZE;
    80002006:	6785                	lui	a5,0x1
    80002008:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    8000200a:	6cb8                	ld	a4,88(s1)
    8000200c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002010:	6cb8                	ld	a4,88(s1)
    80002012:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002014:	4641                	li	a2,16
    80002016:	00006597          	auipc	a1,0x6
    8000201a:	1d258593          	add	a1,a1,466 # 800081e8 <digits+0x1a8>
    8000201e:	15848513          	add	a0,s1,344
    80002022:	fffff097          	auipc	ra,0xfffff
    80002026:	f10080e7          	jalr	-240(ra) # 80000f32 <safestrcpy>
  p->cwd = namei("/");
    8000202a:	00006517          	auipc	a0,0x6
    8000202e:	1ce50513          	add	a0,a0,462 # 800081f8 <digits+0x1b8>
    80002032:	00002097          	auipc	ra,0x2
    80002036:	0e6080e7          	jalr	230(ra) # 80004118 <namei>
    8000203a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    8000203e:	4789                	li	a5,2
    80002040:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80002042:	8526                	mv	a0,s1
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	d56080e7          	jalr	-682(ra) # 80000d9a <release>
}
    8000204c:	60e2                	ld	ra,24(sp)
    8000204e:	6442                	ld	s0,16(sp)
    80002050:	64a2                	ld	s1,8(sp)
    80002052:	6105                	add	sp,sp,32
    80002054:	8082                	ret

0000000080002056 <growproc>:
{
    80002056:	1101                	add	sp,sp,-32
    80002058:	ec06                	sd	ra,24(sp)
    8000205a:	e822                	sd	s0,16(sp)
    8000205c:	e426                	sd	s1,8(sp)
    8000205e:	e04a                	sd	s2,0(sp)
    80002060:	1000                	add	s0,sp,32
    80002062:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002064:	00000097          	auipc	ra,0x0
    80002068:	ca6080e7          	jalr	-858(ra) # 80001d0a <myproc>
    8000206c:	892a                	mv	s2,a0
  sz = p->sz;
    8000206e:	652c                	ld	a1,72(a0)
    80002070:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80002074:	00904f63          	bgtz	s1,80002092 <growproc+0x3c>
  } else if(n < 0){
    80002078:	0204cd63          	bltz	s1,800020b2 <growproc+0x5c>
  p->sz = sz;
    8000207c:	1782                	sll	a5,a5,0x20
    8000207e:	9381                	srl	a5,a5,0x20
    80002080:	04f93423          	sd	a5,72(s2)
  return 0;
    80002084:	4501                	li	a0,0
}
    80002086:	60e2                	ld	ra,24(sp)
    80002088:	6442                	ld	s0,16(sp)
    8000208a:	64a2                	ld	s1,8(sp)
    8000208c:	6902                	ld	s2,0(sp)
    8000208e:	6105                	add	sp,sp,32
    80002090:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002092:	00f4863b          	addw	a2,s1,a5
    80002096:	1602                	sll	a2,a2,0x20
    80002098:	9201                	srl	a2,a2,0x20
    8000209a:	1582                	sll	a1,a1,0x20
    8000209c:	9181                	srl	a1,a1,0x20
    8000209e:	6928                	ld	a0,80(a0)
    800020a0:	fffff097          	auipc	ra,0xfffff
    800020a4:	6ee080e7          	jalr	1774(ra) # 8000178e <uvmalloc>
    800020a8:	0005079b          	sext.w	a5,a0
    800020ac:	fbe1                	bnez	a5,8000207c <growproc+0x26>
      return -1;
    800020ae:	557d                	li	a0,-1
    800020b0:	bfd9                	j	80002086 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800020b2:	00f4863b          	addw	a2,s1,a5
    800020b6:	1602                	sll	a2,a2,0x20
    800020b8:	9201                	srl	a2,a2,0x20
    800020ba:	1582                	sll	a1,a1,0x20
    800020bc:	9181                	srl	a1,a1,0x20
    800020be:	6928                	ld	a0,80(a0)
    800020c0:	fffff097          	auipc	ra,0xfffff
    800020c4:	686080e7          	jalr	1670(ra) # 80001746 <uvmdealloc>
    800020c8:	0005079b          	sext.w	a5,a0
    800020cc:	bf45                	j	8000207c <growproc+0x26>

00000000800020ce <fork>:
{
    800020ce:	7139                	add	sp,sp,-64
    800020d0:	fc06                	sd	ra,56(sp)
    800020d2:	f822                	sd	s0,48(sp)
    800020d4:	f426                	sd	s1,40(sp)
    800020d6:	f04a                	sd	s2,32(sp)
    800020d8:	ec4e                	sd	s3,24(sp)
    800020da:	e852                	sd	s4,16(sp)
    800020dc:	e456                	sd	s5,8(sp)
    800020de:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    800020e0:	00000097          	auipc	ra,0x0
    800020e4:	c2a080e7          	jalr	-982(ra) # 80001d0a <myproc>
    800020e8:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    800020ea:	00000097          	auipc	ra,0x0
    800020ee:	e2a080e7          	jalr	-470(ra) # 80001f14 <allocproc>
    800020f2:	c17d                	beqz	a0,800021d8 <fork+0x10a>
    800020f4:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800020f6:	048ab603          	ld	a2,72(s5)
    800020fa:	692c                	ld	a1,80(a0)
    800020fc:	050ab503          	ld	a0,80(s5)
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	7de080e7          	jalr	2014(ra) # 800018de <uvmcopy>
    80002108:	04054a63          	bltz	a0,8000215c <fork+0x8e>
  np->sz = p->sz;
    8000210c:	048ab783          	ld	a5,72(s5)
    80002110:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80002114:	035a3023          	sd	s5,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80002118:	058ab683          	ld	a3,88(s5)
    8000211c:	87b6                	mv	a5,a3
    8000211e:	058a3703          	ld	a4,88(s4)
    80002122:	12068693          	add	a3,a3,288
    80002126:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000212a:	6788                	ld	a0,8(a5)
    8000212c:	6b8c                	ld	a1,16(a5)
    8000212e:	6f90                	ld	a2,24(a5)
    80002130:	01073023          	sd	a6,0(a4)
    80002134:	e708                	sd	a0,8(a4)
    80002136:	eb0c                	sd	a1,16(a4)
    80002138:	ef10                	sd	a2,24(a4)
    8000213a:	02078793          	add	a5,a5,32
    8000213e:	02070713          	add	a4,a4,32
    80002142:	fed792e3          	bne	a5,a3,80002126 <fork+0x58>
  np->trapframe->a0 = 0;
    80002146:	058a3783          	ld	a5,88(s4)
    8000214a:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    8000214e:	0d0a8493          	add	s1,s5,208
    80002152:	0d0a0913          	add	s2,s4,208
    80002156:	150a8993          	add	s3,s5,336
    8000215a:	a00d                	j	8000217c <fork+0xae>
    freeproc(np);
    8000215c:	8552                	mv	a0,s4
    8000215e:	00000097          	auipc	ra,0x0
    80002162:	d5e080e7          	jalr	-674(ra) # 80001ebc <freeproc>
    release(&np->lock);
    80002166:	8552                	mv	a0,s4
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	c32080e7          	jalr	-974(ra) # 80000d9a <release>
    return -1;
    80002170:	54fd                	li	s1,-1
    80002172:	a889                	j	800021c4 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    80002174:	04a1                	add	s1,s1,8
    80002176:	0921                	add	s2,s2,8
    80002178:	01348b63          	beq	s1,s3,8000218e <fork+0xc0>
    if(p->ofile[i])
    8000217c:	6088                	ld	a0,0(s1)
    8000217e:	d97d                	beqz	a0,80002174 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80002180:	00002097          	auipc	ra,0x2
    80002184:	600080e7          	jalr	1536(ra) # 80004780 <filedup>
    80002188:	00a93023          	sd	a0,0(s2)
    8000218c:	b7e5                	j	80002174 <fork+0xa6>
  np->cwd = idup(p->cwd);
    8000218e:	150ab503          	ld	a0,336(s5)
    80002192:	00001097          	auipc	ra,0x1
    80002196:	794080e7          	jalr	1940(ra) # 80003926 <idup>
    8000219a:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000219e:	4641                	li	a2,16
    800021a0:	158a8593          	add	a1,s5,344
    800021a4:	158a0513          	add	a0,s4,344
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	d8a080e7          	jalr	-630(ra) # 80000f32 <safestrcpy>
  pid = np->pid;
    800021b0:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    800021b4:	4789                	li	a5,2
    800021b6:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    800021ba:	8552                	mv	a0,s4
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	bde080e7          	jalr	-1058(ra) # 80000d9a <release>
}
    800021c4:	8526                	mv	a0,s1
    800021c6:	70e2                	ld	ra,56(sp)
    800021c8:	7442                	ld	s0,48(sp)
    800021ca:	74a2                	ld	s1,40(sp)
    800021cc:	7902                	ld	s2,32(sp)
    800021ce:	69e2                	ld	s3,24(sp)
    800021d0:	6a42                	ld	s4,16(sp)
    800021d2:	6aa2                	ld	s5,8(sp)
    800021d4:	6121                	add	sp,sp,64
    800021d6:	8082                	ret
    return -1;
    800021d8:	54fd                	li	s1,-1
    800021da:	b7ed                	j	800021c4 <fork+0xf6>

00000000800021dc <reparent>:
{
    800021dc:	7179                	add	sp,sp,-48
    800021de:	f406                	sd	ra,40(sp)
    800021e0:	f022                	sd	s0,32(sp)
    800021e2:	ec26                	sd	s1,24(sp)
    800021e4:	e84a                	sd	s2,16(sp)
    800021e6:	e44e                	sd	s3,8(sp)
    800021e8:	e052                	sd	s4,0(sp)
    800021ea:	1800                	add	s0,sp,48
    800021ec:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021ee:	00018497          	auipc	s1,0x18
    800021f2:	b7a48493          	add	s1,s1,-1158 # 80019d68 <proc>
      pp->parent = initproc;
    800021f6:	00007a17          	auipc	s4,0x7
    800021fa:	e22a0a13          	add	s4,s4,-478 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021fe:	0001d997          	auipc	s3,0x1d
    80002202:	56a98993          	add	s3,s3,1386 # 8001f768 <tickslock>
    80002206:	a029                	j	80002210 <reparent+0x34>
    80002208:	16848493          	add	s1,s1,360
    8000220c:	03348363          	beq	s1,s3,80002232 <reparent+0x56>
    if(pp->parent == p){
    80002210:	709c                	ld	a5,32(s1)
    80002212:	ff279be3          	bne	a5,s2,80002208 <reparent+0x2c>
      acquire(&pp->lock);
    80002216:	8526                	mv	a0,s1
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	ace080e7          	jalr	-1330(ra) # 80000ce6 <acquire>
      pp->parent = initproc;
    80002220:	000a3783          	ld	a5,0(s4)
    80002224:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80002226:	8526                	mv	a0,s1
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	b72080e7          	jalr	-1166(ra) # 80000d9a <release>
    80002230:	bfe1                	j	80002208 <reparent+0x2c>
}
    80002232:	70a2                	ld	ra,40(sp)
    80002234:	7402                	ld	s0,32(sp)
    80002236:	64e2                	ld	s1,24(sp)
    80002238:	6942                	ld	s2,16(sp)
    8000223a:	69a2                	ld	s3,8(sp)
    8000223c:	6a02                	ld	s4,0(sp)
    8000223e:	6145                	add	sp,sp,48
    80002240:	8082                	ret

0000000080002242 <scheduler>:
{
    80002242:	715d                	add	sp,sp,-80
    80002244:	e486                	sd	ra,72(sp)
    80002246:	e0a2                	sd	s0,64(sp)
    80002248:	fc26                	sd	s1,56(sp)
    8000224a:	f84a                	sd	s2,48(sp)
    8000224c:	f44e                	sd	s3,40(sp)
    8000224e:	f052                	sd	s4,32(sp)
    80002250:	ec56                	sd	s5,24(sp)
    80002252:	e85a                	sd	s6,16(sp)
    80002254:	e45e                	sd	s7,8(sp)
    80002256:	e062                	sd	s8,0(sp)
    80002258:	0880                	add	s0,sp,80
    8000225a:	8792                	mv	a5,tp
  int id = r_tp();
    8000225c:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000225e:	00779b93          	sll	s7,a5,0x7
    80002262:	00017717          	auipc	a4,0x17
    80002266:	6ee70713          	add	a4,a4,1774 # 80019950 <pid_lock>
    8000226a:	975e                	add	a4,a4,s7
    8000226c:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002270:	00017717          	auipc	a4,0x17
    80002274:	70070713          	add	a4,a4,1792 # 80019970 <cpus+0x8>
    80002278:	9bba                	add	s7,s7,a4
    int nproc = 0;
    8000227a:	4c01                	li	s8,0
      if(p->state == RUNNABLE) {
    8000227c:	4a09                	li	s4,2
        c->proc = p;
    8000227e:	079e                	sll	a5,a5,0x7
    80002280:	00017a97          	auipc	s5,0x17
    80002284:	6d0a8a93          	add	s5,s5,1744 # 80019950 <pid_lock>
    80002288:	9abe                	add	s5,s5,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000228a:	0001d997          	auipc	s3,0x1d
    8000228e:	4de98993          	add	s3,s3,1246 # 8001f768 <tickslock>
    80002292:	a8a1                	j	800022ea <scheduler+0xa8>
      release(&p->lock);
    80002294:	8526                	mv	a0,s1
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	b04080e7          	jalr	-1276(ra) # 80000d9a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000229e:	16848493          	add	s1,s1,360
    800022a2:	03348a63          	beq	s1,s3,800022d6 <scheduler+0x94>
      acquire(&p->lock);
    800022a6:	8526                	mv	a0,s1
    800022a8:	fffff097          	auipc	ra,0xfffff
    800022ac:	a3e080e7          	jalr	-1474(ra) # 80000ce6 <acquire>
      if(p->state != UNUSED) {
    800022b0:	4c9c                	lw	a5,24(s1)
    800022b2:	d3ed                	beqz	a5,80002294 <scheduler+0x52>
        nproc++;
    800022b4:	2905                	addw	s2,s2,1
      if(p->state == RUNNABLE) {
    800022b6:	fd479fe3          	bne	a5,s4,80002294 <scheduler+0x52>
        p->state = RUNNING;
    800022ba:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    800022be:	009abc23          	sd	s1,24(s5)
        swtch(&c->context, &p->context);
    800022c2:	06048593          	add	a1,s1,96
    800022c6:	855e                	mv	a0,s7
    800022c8:	00000097          	auipc	ra,0x0
    800022cc:	60e080e7          	jalr	1550(ra) # 800028d6 <swtch>
        c->proc = 0;
    800022d0:	000abc23          	sd	zero,24(s5)
    800022d4:	b7c1                	j	80002294 <scheduler+0x52>
    if(nproc <= 2) {   // only init and sh exist
    800022d6:	012a4a63          	blt	s4,s2,800022ea <scheduler+0xa8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022da:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022de:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022e2:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800022e6:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022ea:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022ee:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022f2:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    800022f6:	8962                	mv	s2,s8
    for(p = proc; p < &proc[NPROC]; p++) {
    800022f8:	00018497          	auipc	s1,0x18
    800022fc:	a7048493          	add	s1,s1,-1424 # 80019d68 <proc>
        p->state = RUNNING;
    80002300:	4b0d                	li	s6,3
    80002302:	b755                	j	800022a6 <scheduler+0x64>

0000000080002304 <sched>:
{
    80002304:	7179                	add	sp,sp,-48
    80002306:	f406                	sd	ra,40(sp)
    80002308:	f022                	sd	s0,32(sp)
    8000230a:	ec26                	sd	s1,24(sp)
    8000230c:	e84a                	sd	s2,16(sp)
    8000230e:	e44e                	sd	s3,8(sp)
    80002310:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    80002312:	00000097          	auipc	ra,0x0
    80002316:	9f8080e7          	jalr	-1544(ra) # 80001d0a <myproc>
    8000231a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	950080e7          	jalr	-1712(ra) # 80000c6c <holding>
    80002324:	c93d                	beqz	a0,8000239a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002326:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002328:	2781                	sext.w	a5,a5
    8000232a:	079e                	sll	a5,a5,0x7
    8000232c:	00017717          	auipc	a4,0x17
    80002330:	62470713          	add	a4,a4,1572 # 80019950 <pid_lock>
    80002334:	97ba                	add	a5,a5,a4
    80002336:	0907a703          	lw	a4,144(a5)
    8000233a:	4785                	li	a5,1
    8000233c:	06f71763          	bne	a4,a5,800023aa <sched+0xa6>
  if(p->state == RUNNING)
    80002340:	4c98                	lw	a4,24(s1)
    80002342:	478d                	li	a5,3
    80002344:	06f70b63          	beq	a4,a5,800023ba <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002348:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000234c:	8b89                	and	a5,a5,2
  if(intr_get())
    8000234e:	efb5                	bnez	a5,800023ca <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002350:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002352:	00017917          	auipc	s2,0x17
    80002356:	5fe90913          	add	s2,s2,1534 # 80019950 <pid_lock>
    8000235a:	2781                	sext.w	a5,a5
    8000235c:	079e                	sll	a5,a5,0x7
    8000235e:	97ca                	add	a5,a5,s2
    80002360:	0947a983          	lw	s3,148(a5)
    80002364:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002366:	2781                	sext.w	a5,a5
    80002368:	079e                	sll	a5,a5,0x7
    8000236a:	00017597          	auipc	a1,0x17
    8000236e:	60658593          	add	a1,a1,1542 # 80019970 <cpus+0x8>
    80002372:	95be                	add	a1,a1,a5
    80002374:	06048513          	add	a0,s1,96
    80002378:	00000097          	auipc	ra,0x0
    8000237c:	55e080e7          	jalr	1374(ra) # 800028d6 <swtch>
    80002380:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002382:	2781                	sext.w	a5,a5
    80002384:	079e                	sll	a5,a5,0x7
    80002386:	993e                	add	s2,s2,a5
    80002388:	09392a23          	sw	s3,148(s2)
}
    8000238c:	70a2                	ld	ra,40(sp)
    8000238e:	7402                	ld	s0,32(sp)
    80002390:	64e2                	ld	s1,24(sp)
    80002392:	6942                	ld	s2,16(sp)
    80002394:	69a2                	ld	s3,8(sp)
    80002396:	6145                	add	sp,sp,48
    80002398:	8082                	ret
    panic("sched p->lock");
    8000239a:	00006517          	auipc	a0,0x6
    8000239e:	e6650513          	add	a0,a0,-410 # 80008200 <digits+0x1c0>
    800023a2:	ffffe097          	auipc	ra,0xffffe
    800023a6:	1a0080e7          	jalr	416(ra) # 80000542 <panic>
    panic("sched locks");
    800023aa:	00006517          	auipc	a0,0x6
    800023ae:	e6650513          	add	a0,a0,-410 # 80008210 <digits+0x1d0>
    800023b2:	ffffe097          	auipc	ra,0xffffe
    800023b6:	190080e7          	jalr	400(ra) # 80000542 <panic>
    panic("sched running");
    800023ba:	00006517          	auipc	a0,0x6
    800023be:	e6650513          	add	a0,a0,-410 # 80008220 <digits+0x1e0>
    800023c2:	ffffe097          	auipc	ra,0xffffe
    800023c6:	180080e7          	jalr	384(ra) # 80000542 <panic>
    panic("sched interruptible");
    800023ca:	00006517          	auipc	a0,0x6
    800023ce:	e6650513          	add	a0,a0,-410 # 80008230 <digits+0x1f0>
    800023d2:	ffffe097          	auipc	ra,0xffffe
    800023d6:	170080e7          	jalr	368(ra) # 80000542 <panic>

00000000800023da <exit>:
{
    800023da:	7179                	add	sp,sp,-48
    800023dc:	f406                	sd	ra,40(sp)
    800023de:	f022                	sd	s0,32(sp)
    800023e0:	ec26                	sd	s1,24(sp)
    800023e2:	e84a                	sd	s2,16(sp)
    800023e4:	e44e                	sd	s3,8(sp)
    800023e6:	e052                	sd	s4,0(sp)
    800023e8:	1800                	add	s0,sp,48
    800023ea:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023ec:	00000097          	auipc	ra,0x0
    800023f0:	91e080e7          	jalr	-1762(ra) # 80001d0a <myproc>
    800023f4:	89aa                	mv	s3,a0
  if(p == initproc)
    800023f6:	00007797          	auipc	a5,0x7
    800023fa:	c227b783          	ld	a5,-990(a5) # 80009018 <initproc>
    800023fe:	0d050493          	add	s1,a0,208
    80002402:	15050913          	add	s2,a0,336
    80002406:	02a79363          	bne	a5,a0,8000242c <exit+0x52>
    panic("init exiting");
    8000240a:	00006517          	auipc	a0,0x6
    8000240e:	e3e50513          	add	a0,a0,-450 # 80008248 <digits+0x208>
    80002412:	ffffe097          	auipc	ra,0xffffe
    80002416:	130080e7          	jalr	304(ra) # 80000542 <panic>
      fileclose(f);
    8000241a:	00002097          	auipc	ra,0x2
    8000241e:	3b8080e7          	jalr	952(ra) # 800047d2 <fileclose>
      p->ofile[fd] = 0;
    80002422:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002426:	04a1                	add	s1,s1,8
    80002428:	01248563          	beq	s1,s2,80002432 <exit+0x58>
    if(p->ofile[fd]){
    8000242c:	6088                	ld	a0,0(s1)
    8000242e:	f575                	bnez	a0,8000241a <exit+0x40>
    80002430:	bfdd                	j	80002426 <exit+0x4c>
  begin_op();
    80002432:	00002097          	auipc	ra,0x2
    80002436:	ed6080e7          	jalr	-298(ra) # 80004308 <begin_op>
  iput(p->cwd);
    8000243a:	1509b503          	ld	a0,336(s3)
    8000243e:	00001097          	auipc	ra,0x1
    80002442:	6e0080e7          	jalr	1760(ra) # 80003b1e <iput>
  end_op();
    80002446:	00002097          	auipc	ra,0x2
    8000244a:	f3c080e7          	jalr	-196(ra) # 80004382 <end_op>
  p->cwd = 0;
    8000244e:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002452:	00007497          	auipc	s1,0x7
    80002456:	bc648493          	add	s1,s1,-1082 # 80009018 <initproc>
    8000245a:	6088                	ld	a0,0(s1)
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	88a080e7          	jalr	-1910(ra) # 80000ce6 <acquire>
  wakeup1(initproc);
    80002464:	6088                	ld	a0,0(s1)
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	764080e7          	jalr	1892(ra) # 80001bca <wakeup1>
  release(&initproc->lock);
    8000246e:	6088                	ld	a0,0(s1)
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	92a080e7          	jalr	-1750(ra) # 80000d9a <release>
  acquire(&p->lock);
    80002478:	854e                	mv	a0,s3
    8000247a:	fffff097          	auipc	ra,0xfffff
    8000247e:	86c080e7          	jalr	-1940(ra) # 80000ce6 <acquire>
  struct proc *original_parent = p->parent;
    80002482:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002486:	854e                	mv	a0,s3
    80002488:	fffff097          	auipc	ra,0xfffff
    8000248c:	912080e7          	jalr	-1774(ra) # 80000d9a <release>
  acquire(&original_parent->lock);
    80002490:	8526                	mv	a0,s1
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	854080e7          	jalr	-1964(ra) # 80000ce6 <acquire>
  acquire(&p->lock);
    8000249a:	854e                	mv	a0,s3
    8000249c:	fffff097          	auipc	ra,0xfffff
    800024a0:	84a080e7          	jalr	-1974(ra) # 80000ce6 <acquire>
  reparent(p);
    800024a4:	854e                	mv	a0,s3
    800024a6:	00000097          	auipc	ra,0x0
    800024aa:	d36080e7          	jalr	-714(ra) # 800021dc <reparent>
  wakeup1(original_parent);
    800024ae:	8526                	mv	a0,s1
    800024b0:	fffff097          	auipc	ra,0xfffff
    800024b4:	71a080e7          	jalr	1818(ra) # 80001bca <wakeup1>
  p->xstate = status;
    800024b8:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800024bc:	4791                	li	a5,4
    800024be:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800024c2:	8526                	mv	a0,s1
    800024c4:	fffff097          	auipc	ra,0xfffff
    800024c8:	8d6080e7          	jalr	-1834(ra) # 80000d9a <release>
  sched();
    800024cc:	00000097          	auipc	ra,0x0
    800024d0:	e38080e7          	jalr	-456(ra) # 80002304 <sched>
  panic("zombie exit");
    800024d4:	00006517          	auipc	a0,0x6
    800024d8:	d8450513          	add	a0,a0,-636 # 80008258 <digits+0x218>
    800024dc:	ffffe097          	auipc	ra,0xffffe
    800024e0:	066080e7          	jalr	102(ra) # 80000542 <panic>

00000000800024e4 <yield>:
{
    800024e4:	1101                	add	sp,sp,-32
    800024e6:	ec06                	sd	ra,24(sp)
    800024e8:	e822                	sd	s0,16(sp)
    800024ea:	e426                	sd	s1,8(sp)
    800024ec:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    800024ee:	00000097          	auipc	ra,0x0
    800024f2:	81c080e7          	jalr	-2020(ra) # 80001d0a <myproc>
    800024f6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	7ee080e7          	jalr	2030(ra) # 80000ce6 <acquire>
  p->state = RUNNABLE;
    80002500:	4789                	li	a5,2
    80002502:	cc9c                	sw	a5,24(s1)
  sched();
    80002504:	00000097          	auipc	ra,0x0
    80002508:	e00080e7          	jalr	-512(ra) # 80002304 <sched>
  release(&p->lock);
    8000250c:	8526                	mv	a0,s1
    8000250e:	fffff097          	auipc	ra,0xfffff
    80002512:	88c080e7          	jalr	-1908(ra) # 80000d9a <release>
}
    80002516:	60e2                	ld	ra,24(sp)
    80002518:	6442                	ld	s0,16(sp)
    8000251a:	64a2                	ld	s1,8(sp)
    8000251c:	6105                	add	sp,sp,32
    8000251e:	8082                	ret

0000000080002520 <sleep>:
{
    80002520:	7179                	add	sp,sp,-48
    80002522:	f406                	sd	ra,40(sp)
    80002524:	f022                	sd	s0,32(sp)
    80002526:	ec26                	sd	s1,24(sp)
    80002528:	e84a                	sd	s2,16(sp)
    8000252a:	e44e                	sd	s3,8(sp)
    8000252c:	1800                	add	s0,sp,48
    8000252e:	89aa                	mv	s3,a0
    80002530:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002532:	fffff097          	auipc	ra,0xfffff
    80002536:	7d8080e7          	jalr	2008(ra) # 80001d0a <myproc>
    8000253a:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000253c:	05250663          	beq	a0,s2,80002588 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002540:	ffffe097          	auipc	ra,0xffffe
    80002544:	7a6080e7          	jalr	1958(ra) # 80000ce6 <acquire>
    release(lk);
    80002548:	854a                	mv	a0,s2
    8000254a:	fffff097          	auipc	ra,0xfffff
    8000254e:	850080e7          	jalr	-1968(ra) # 80000d9a <release>
  p->chan = chan;
    80002552:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002556:	4785                	li	a5,1
    80002558:	cc9c                	sw	a5,24(s1)
  sched();
    8000255a:	00000097          	auipc	ra,0x0
    8000255e:	daa080e7          	jalr	-598(ra) # 80002304 <sched>
  p->chan = 0;
    80002562:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002566:	8526                	mv	a0,s1
    80002568:	fffff097          	auipc	ra,0xfffff
    8000256c:	832080e7          	jalr	-1998(ra) # 80000d9a <release>
    acquire(lk);
    80002570:	854a                	mv	a0,s2
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	774080e7          	jalr	1908(ra) # 80000ce6 <acquire>
}
    8000257a:	70a2                	ld	ra,40(sp)
    8000257c:	7402                	ld	s0,32(sp)
    8000257e:	64e2                	ld	s1,24(sp)
    80002580:	6942                	ld	s2,16(sp)
    80002582:	69a2                	ld	s3,8(sp)
    80002584:	6145                	add	sp,sp,48
    80002586:	8082                	ret
  p->chan = chan;
    80002588:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000258c:	4785                	li	a5,1
    8000258e:	cd1c                	sw	a5,24(a0)
  sched();
    80002590:	00000097          	auipc	ra,0x0
    80002594:	d74080e7          	jalr	-652(ra) # 80002304 <sched>
  p->chan = 0;
    80002598:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000259c:	bff9                	j	8000257a <sleep+0x5a>

000000008000259e <wait>:
{
    8000259e:	715d                	add	sp,sp,-80
    800025a0:	e486                	sd	ra,72(sp)
    800025a2:	e0a2                	sd	s0,64(sp)
    800025a4:	fc26                	sd	s1,56(sp)
    800025a6:	f84a                	sd	s2,48(sp)
    800025a8:	f44e                	sd	s3,40(sp)
    800025aa:	f052                	sd	s4,32(sp)
    800025ac:	ec56                	sd	s5,24(sp)
    800025ae:	e85a                	sd	s6,16(sp)
    800025b0:	e45e                	sd	s7,8(sp)
    800025b2:	0880                	add	s0,sp,80
    800025b4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025b6:	fffff097          	auipc	ra,0xfffff
    800025ba:	754080e7          	jalr	1876(ra) # 80001d0a <myproc>
    800025be:	892a                	mv	s2,a0
  acquire(&p->lock);
    800025c0:	ffffe097          	auipc	ra,0xffffe
    800025c4:	726080e7          	jalr	1830(ra) # 80000ce6 <acquire>
    havekids = 0;
    800025c8:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800025ca:	4a11                	li	s4,4
        havekids = 1;
    800025cc:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800025ce:	0001d997          	auipc	s3,0x1d
    800025d2:	19a98993          	add	s3,s3,410 # 8001f768 <tickslock>
    800025d6:	a845                	j	80002686 <wait+0xe8>
          pid = np->pid;
    800025d8:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800025dc:	000b0e63          	beqz	s6,800025f8 <wait+0x5a>
    800025e0:	4691                	li	a3,4
    800025e2:	03448613          	add	a2,s1,52
    800025e6:	85da                	mv	a1,s6
    800025e8:	05093503          	ld	a0,80(s2)
    800025ec:	fffff097          	auipc	ra,0xfffff
    800025f0:	3f0080e7          	jalr	1008(ra) # 800019dc <copyout>
    800025f4:	02054d63          	bltz	a0,8000262e <wait+0x90>
          freeproc(np);
    800025f8:	8526                	mv	a0,s1
    800025fa:	00000097          	auipc	ra,0x0
    800025fe:	8c2080e7          	jalr	-1854(ra) # 80001ebc <freeproc>
          release(&np->lock);
    80002602:	8526                	mv	a0,s1
    80002604:	ffffe097          	auipc	ra,0xffffe
    80002608:	796080e7          	jalr	1942(ra) # 80000d9a <release>
          release(&p->lock);
    8000260c:	854a                	mv	a0,s2
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	78c080e7          	jalr	1932(ra) # 80000d9a <release>
}
    80002616:	854e                	mv	a0,s3
    80002618:	60a6                	ld	ra,72(sp)
    8000261a:	6406                	ld	s0,64(sp)
    8000261c:	74e2                	ld	s1,56(sp)
    8000261e:	7942                	ld	s2,48(sp)
    80002620:	79a2                	ld	s3,40(sp)
    80002622:	7a02                	ld	s4,32(sp)
    80002624:	6ae2                	ld	s5,24(sp)
    80002626:	6b42                	ld	s6,16(sp)
    80002628:	6ba2                	ld	s7,8(sp)
    8000262a:	6161                	add	sp,sp,80
    8000262c:	8082                	ret
            release(&np->lock);
    8000262e:	8526                	mv	a0,s1
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	76a080e7          	jalr	1898(ra) # 80000d9a <release>
            release(&p->lock);
    80002638:	854a                	mv	a0,s2
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	760080e7          	jalr	1888(ra) # 80000d9a <release>
            return -1;
    80002642:	59fd                	li	s3,-1
    80002644:	bfc9                	j	80002616 <wait+0x78>
    for(np = proc; np < &proc[NPROC]; np++){
    80002646:	16848493          	add	s1,s1,360
    8000264a:	03348463          	beq	s1,s3,80002672 <wait+0xd4>
      if(np->parent == p){
    8000264e:	709c                	ld	a5,32(s1)
    80002650:	ff279be3          	bne	a5,s2,80002646 <wait+0xa8>
        acquire(&np->lock);
    80002654:	8526                	mv	a0,s1
    80002656:	ffffe097          	auipc	ra,0xffffe
    8000265a:	690080e7          	jalr	1680(ra) # 80000ce6 <acquire>
        if(np->state == ZOMBIE){
    8000265e:	4c9c                	lw	a5,24(s1)
    80002660:	f7478ce3          	beq	a5,s4,800025d8 <wait+0x3a>
        release(&np->lock);
    80002664:	8526                	mv	a0,s1
    80002666:	ffffe097          	auipc	ra,0xffffe
    8000266a:	734080e7          	jalr	1844(ra) # 80000d9a <release>
        havekids = 1;
    8000266e:	8756                	mv	a4,s5
    80002670:	bfd9                	j	80002646 <wait+0xa8>
    if(!havekids || p->killed){
    80002672:	c305                	beqz	a4,80002692 <wait+0xf4>
    80002674:	03092783          	lw	a5,48(s2)
    80002678:	ef89                	bnez	a5,80002692 <wait+0xf4>
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000267a:	85ca                	mv	a1,s2
    8000267c:	854a                	mv	a0,s2
    8000267e:	00000097          	auipc	ra,0x0
    80002682:	ea2080e7          	jalr	-350(ra) # 80002520 <sleep>
    havekids = 0;
    80002686:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002688:	00017497          	auipc	s1,0x17
    8000268c:	6e048493          	add	s1,s1,1760 # 80019d68 <proc>
    80002690:	bf7d                	j	8000264e <wait+0xb0>
      release(&p->lock);
    80002692:	854a                	mv	a0,s2
    80002694:	ffffe097          	auipc	ra,0xffffe
    80002698:	706080e7          	jalr	1798(ra) # 80000d9a <release>
      return -1;
    8000269c:	59fd                	li	s3,-1
    8000269e:	bfa5                	j	80002616 <wait+0x78>

00000000800026a0 <wakeup>:
{
    800026a0:	7139                	add	sp,sp,-64
    800026a2:	fc06                	sd	ra,56(sp)
    800026a4:	f822                	sd	s0,48(sp)
    800026a6:	f426                	sd	s1,40(sp)
    800026a8:	f04a                	sd	s2,32(sp)
    800026aa:	ec4e                	sd	s3,24(sp)
    800026ac:	e852                	sd	s4,16(sp)
    800026ae:	e456                	sd	s5,8(sp)
    800026b0:	0080                	add	s0,sp,64
    800026b2:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800026b4:	00017497          	auipc	s1,0x17
    800026b8:	6b448493          	add	s1,s1,1716 # 80019d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800026bc:	4985                	li	s3,1
      p->state = RUNNABLE;
    800026be:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800026c0:	0001d917          	auipc	s2,0x1d
    800026c4:	0a890913          	add	s2,s2,168 # 8001f768 <tickslock>
    800026c8:	a811                	j	800026dc <wakeup+0x3c>
    release(&p->lock);
    800026ca:	8526                	mv	a0,s1
    800026cc:	ffffe097          	auipc	ra,0xffffe
    800026d0:	6ce080e7          	jalr	1742(ra) # 80000d9a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800026d4:	16848493          	add	s1,s1,360
    800026d8:	03248063          	beq	s1,s2,800026f8 <wakeup+0x58>
    acquire(&p->lock);
    800026dc:	8526                	mv	a0,s1
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	608080e7          	jalr	1544(ra) # 80000ce6 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800026e6:	4c9c                	lw	a5,24(s1)
    800026e8:	ff3791e3          	bne	a5,s3,800026ca <wakeup+0x2a>
    800026ec:	749c                	ld	a5,40(s1)
    800026ee:	fd479ee3          	bne	a5,s4,800026ca <wakeup+0x2a>
      p->state = RUNNABLE;
    800026f2:	0154ac23          	sw	s5,24(s1)
    800026f6:	bfd1                	j	800026ca <wakeup+0x2a>
}
    800026f8:	70e2                	ld	ra,56(sp)
    800026fa:	7442                	ld	s0,48(sp)
    800026fc:	74a2                	ld	s1,40(sp)
    800026fe:	7902                	ld	s2,32(sp)
    80002700:	69e2                	ld	s3,24(sp)
    80002702:	6a42                	ld	s4,16(sp)
    80002704:	6aa2                	ld	s5,8(sp)
    80002706:	6121                	add	sp,sp,64
    80002708:	8082                	ret

000000008000270a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000270a:	7179                	add	sp,sp,-48
    8000270c:	f406                	sd	ra,40(sp)
    8000270e:	f022                	sd	s0,32(sp)
    80002710:	ec26                	sd	s1,24(sp)
    80002712:	e84a                	sd	s2,16(sp)
    80002714:	e44e                	sd	s3,8(sp)
    80002716:	1800                	add	s0,sp,48
    80002718:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000271a:	00017497          	auipc	s1,0x17
    8000271e:	64e48493          	add	s1,s1,1614 # 80019d68 <proc>
    80002722:	0001d997          	auipc	s3,0x1d
    80002726:	04698993          	add	s3,s3,70 # 8001f768 <tickslock>
    acquire(&p->lock);
    8000272a:	8526                	mv	a0,s1
    8000272c:	ffffe097          	auipc	ra,0xffffe
    80002730:	5ba080e7          	jalr	1466(ra) # 80000ce6 <acquire>
    if(p->pid == pid){
    80002734:	5c9c                	lw	a5,56(s1)
    80002736:	01278d63          	beq	a5,s2,80002750 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000273a:	8526                	mv	a0,s1
    8000273c:	ffffe097          	auipc	ra,0xffffe
    80002740:	65e080e7          	jalr	1630(ra) # 80000d9a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002744:	16848493          	add	s1,s1,360
    80002748:	ff3491e3          	bne	s1,s3,8000272a <kill+0x20>
  }
  return -1;
    8000274c:	557d                	li	a0,-1
    8000274e:	a821                	j	80002766 <kill+0x5c>
      p->killed = 1;
    80002750:	4785                	li	a5,1
    80002752:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002754:	4c98                	lw	a4,24(s1)
    80002756:	00f70f63          	beq	a4,a5,80002774 <kill+0x6a>
      release(&p->lock);
    8000275a:	8526                	mv	a0,s1
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	63e080e7          	jalr	1598(ra) # 80000d9a <release>
      return 0;
    80002764:	4501                	li	a0,0
}
    80002766:	70a2                	ld	ra,40(sp)
    80002768:	7402                	ld	s0,32(sp)
    8000276a:	64e2                	ld	s1,24(sp)
    8000276c:	6942                	ld	s2,16(sp)
    8000276e:	69a2                	ld	s3,8(sp)
    80002770:	6145                	add	sp,sp,48
    80002772:	8082                	ret
        p->state = RUNNABLE;
    80002774:	4789                	li	a5,2
    80002776:	cc9c                	sw	a5,24(s1)
    80002778:	b7cd                	j	8000275a <kill+0x50>

000000008000277a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000277a:	7179                	add	sp,sp,-48
    8000277c:	f406                	sd	ra,40(sp)
    8000277e:	f022                	sd	s0,32(sp)
    80002780:	ec26                	sd	s1,24(sp)
    80002782:	e84a                	sd	s2,16(sp)
    80002784:	e44e                	sd	s3,8(sp)
    80002786:	e052                	sd	s4,0(sp)
    80002788:	1800                	add	s0,sp,48
    8000278a:	84aa                	mv	s1,a0
    8000278c:	892e                	mv	s2,a1
    8000278e:	89b2                	mv	s3,a2
    80002790:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002792:	fffff097          	auipc	ra,0xfffff
    80002796:	578080e7          	jalr	1400(ra) # 80001d0a <myproc>
  if(user_dst){
    8000279a:	c08d                	beqz	s1,800027bc <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000279c:	86d2                	mv	a3,s4
    8000279e:	864e                	mv	a2,s3
    800027a0:	85ca                	mv	a1,s2
    800027a2:	6928                	ld	a0,80(a0)
    800027a4:	fffff097          	auipc	ra,0xfffff
    800027a8:	238080e7          	jalr	568(ra) # 800019dc <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027ac:	70a2                	ld	ra,40(sp)
    800027ae:	7402                	ld	s0,32(sp)
    800027b0:	64e2                	ld	s1,24(sp)
    800027b2:	6942                	ld	s2,16(sp)
    800027b4:	69a2                	ld	s3,8(sp)
    800027b6:	6a02                	ld	s4,0(sp)
    800027b8:	6145                	add	sp,sp,48
    800027ba:	8082                	ret
    memmove((char *)dst, src, len);
    800027bc:	000a061b          	sext.w	a2,s4
    800027c0:	85ce                	mv	a1,s3
    800027c2:	854a                	mv	a0,s2
    800027c4:	ffffe097          	auipc	ra,0xffffe
    800027c8:	67a080e7          	jalr	1658(ra) # 80000e3e <memmove>
    return 0;
    800027cc:	8526                	mv	a0,s1
    800027ce:	bff9                	j	800027ac <either_copyout+0x32>

00000000800027d0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027d0:	7179                	add	sp,sp,-48
    800027d2:	f406                	sd	ra,40(sp)
    800027d4:	f022                	sd	s0,32(sp)
    800027d6:	ec26                	sd	s1,24(sp)
    800027d8:	e84a                	sd	s2,16(sp)
    800027da:	e44e                	sd	s3,8(sp)
    800027dc:	e052                	sd	s4,0(sp)
    800027de:	1800                	add	s0,sp,48
    800027e0:	892a                	mv	s2,a0
    800027e2:	84ae                	mv	s1,a1
    800027e4:	89b2                	mv	s3,a2
    800027e6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027e8:	fffff097          	auipc	ra,0xfffff
    800027ec:	522080e7          	jalr	1314(ra) # 80001d0a <myproc>
  if(user_src){
    800027f0:	c08d                	beqz	s1,80002812 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800027f2:	86d2                	mv	a3,s4
    800027f4:	864e                	mv	a2,s3
    800027f6:	85ca                	mv	a1,s2
    800027f8:	6928                	ld	a0,80(a0)
    800027fa:	fffff097          	auipc	ra,0xfffff
    800027fe:	292080e7          	jalr	658(ra) # 80001a8c <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002802:	70a2                	ld	ra,40(sp)
    80002804:	7402                	ld	s0,32(sp)
    80002806:	64e2                	ld	s1,24(sp)
    80002808:	6942                	ld	s2,16(sp)
    8000280a:	69a2                	ld	s3,8(sp)
    8000280c:	6a02                	ld	s4,0(sp)
    8000280e:	6145                	add	sp,sp,48
    80002810:	8082                	ret
    memmove(dst, (char*)src, len);
    80002812:	000a061b          	sext.w	a2,s4
    80002816:	85ce                	mv	a1,s3
    80002818:	854a                	mv	a0,s2
    8000281a:	ffffe097          	auipc	ra,0xffffe
    8000281e:	624080e7          	jalr	1572(ra) # 80000e3e <memmove>
    return 0;
    80002822:	8526                	mv	a0,s1
    80002824:	bff9                	j	80002802 <either_copyin+0x32>

0000000080002826 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002826:	715d                	add	sp,sp,-80
    80002828:	e486                	sd	ra,72(sp)
    8000282a:	e0a2                	sd	s0,64(sp)
    8000282c:	fc26                	sd	s1,56(sp)
    8000282e:	f84a                	sd	s2,48(sp)
    80002830:	f44e                	sd	s3,40(sp)
    80002832:	f052                	sd	s4,32(sp)
    80002834:	ec56                	sd	s5,24(sp)
    80002836:	e85a                	sd	s6,16(sp)
    80002838:	e45e                	sd	s7,8(sp)
    8000283a:	0880                	add	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000283c:	00006517          	auipc	a0,0x6
    80002840:	88c50513          	add	a0,a0,-1908 # 800080c8 <digits+0x88>
    80002844:	ffffe097          	auipc	ra,0xffffe
    80002848:	d48080e7          	jalr	-696(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000284c:	00017497          	auipc	s1,0x17
    80002850:	67448493          	add	s1,s1,1652 # 80019ec0 <proc+0x158>
    80002854:	0001d917          	auipc	s2,0x1d
    80002858:	06c90913          	add	s2,s2,108 # 8001f8c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000285c:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000285e:	00006997          	auipc	s3,0x6
    80002862:	a0a98993          	add	s3,s3,-1526 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002866:	00006a97          	auipc	s5,0x6
    8000286a:	a0aa8a93          	add	s5,s5,-1526 # 80008270 <digits+0x230>
    printf("\n");
    8000286e:	00006a17          	auipc	s4,0x6
    80002872:	85aa0a13          	add	s4,s4,-1958 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002876:	00006b97          	auipc	s7,0x6
    8000287a:	a32b8b93          	add	s7,s7,-1486 # 800082a8 <states.0>
    8000287e:	a00d                	j	800028a0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002880:	ee06a583          	lw	a1,-288(a3)
    80002884:	8556                	mv	a0,s5
    80002886:	ffffe097          	auipc	ra,0xffffe
    8000288a:	d06080e7          	jalr	-762(ra) # 8000058c <printf>
    printf("\n");
    8000288e:	8552                	mv	a0,s4
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	cfc080e7          	jalr	-772(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002898:	16848493          	add	s1,s1,360
    8000289c:	03248263          	beq	s1,s2,800028c0 <procdump+0x9a>
    if(p->state == UNUSED)
    800028a0:	86a6                	mv	a3,s1
    800028a2:	ec04a783          	lw	a5,-320(s1)
    800028a6:	dbed                	beqz	a5,80002898 <procdump+0x72>
      state = "???";
    800028a8:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028aa:	fcfb6be3          	bltu	s6,a5,80002880 <procdump+0x5a>
    800028ae:	02079713          	sll	a4,a5,0x20
    800028b2:	01d75793          	srl	a5,a4,0x1d
    800028b6:	97de                	add	a5,a5,s7
    800028b8:	6390                	ld	a2,0(a5)
    800028ba:	f279                	bnez	a2,80002880 <procdump+0x5a>
      state = "???";
    800028bc:	864e                	mv	a2,s3
    800028be:	b7c9                	j	80002880 <procdump+0x5a>
  }
}
    800028c0:	60a6                	ld	ra,72(sp)
    800028c2:	6406                	ld	s0,64(sp)
    800028c4:	74e2                	ld	s1,56(sp)
    800028c6:	7942                	ld	s2,48(sp)
    800028c8:	79a2                	ld	s3,40(sp)
    800028ca:	7a02                	ld	s4,32(sp)
    800028cc:	6ae2                	ld	s5,24(sp)
    800028ce:	6b42                	ld	s6,16(sp)
    800028d0:	6ba2                	ld	s7,8(sp)
    800028d2:	6161                	add	sp,sp,80
    800028d4:	8082                	ret

00000000800028d6 <swtch>:
    800028d6:	00153023          	sd	ra,0(a0)
    800028da:	00253423          	sd	sp,8(a0)
    800028de:	e900                	sd	s0,16(a0)
    800028e0:	ed04                	sd	s1,24(a0)
    800028e2:	03253023          	sd	s2,32(a0)
    800028e6:	03353423          	sd	s3,40(a0)
    800028ea:	03453823          	sd	s4,48(a0)
    800028ee:	03553c23          	sd	s5,56(a0)
    800028f2:	05653023          	sd	s6,64(a0)
    800028f6:	05753423          	sd	s7,72(a0)
    800028fa:	05853823          	sd	s8,80(a0)
    800028fe:	05953c23          	sd	s9,88(a0)
    80002902:	07a53023          	sd	s10,96(a0)
    80002906:	07b53423          	sd	s11,104(a0)
    8000290a:	0005b083          	ld	ra,0(a1)
    8000290e:	0085b103          	ld	sp,8(a1)
    80002912:	6980                	ld	s0,16(a1)
    80002914:	6d84                	ld	s1,24(a1)
    80002916:	0205b903          	ld	s2,32(a1)
    8000291a:	0285b983          	ld	s3,40(a1)
    8000291e:	0305ba03          	ld	s4,48(a1)
    80002922:	0385ba83          	ld	s5,56(a1)
    80002926:	0405bb03          	ld	s6,64(a1)
    8000292a:	0485bb83          	ld	s7,72(a1)
    8000292e:	0505bc03          	ld	s8,80(a1)
    80002932:	0585bc83          	ld	s9,88(a1)
    80002936:	0605bd03          	ld	s10,96(a1)
    8000293a:	0685bd83          	ld	s11,104(a1)
    8000293e:	8082                	ret

0000000080002940 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002940:	1141                	add	sp,sp,-16
    80002942:	e406                	sd	ra,8(sp)
    80002944:	e022                	sd	s0,0(sp)
    80002946:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    80002948:	00006597          	auipc	a1,0x6
    8000294c:	98858593          	add	a1,a1,-1656 # 800082d0 <states.0+0x28>
    80002950:	0001d517          	auipc	a0,0x1d
    80002954:	e1850513          	add	a0,a0,-488 # 8001f768 <tickslock>
    80002958:	ffffe097          	auipc	ra,0xffffe
    8000295c:	2fe080e7          	jalr	766(ra) # 80000c56 <initlock>
}
    80002960:	60a2                	ld	ra,8(sp)
    80002962:	6402                	ld	s0,0(sp)
    80002964:	0141                	add	sp,sp,16
    80002966:	8082                	ret

0000000080002968 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002968:	1141                	add	sp,sp,-16
    8000296a:	e422                	sd	s0,8(sp)
    8000296c:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000296e:	00003797          	auipc	a5,0x3
    80002972:	4a278793          	add	a5,a5,1186 # 80005e10 <kernelvec>
    80002976:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000297a:	6422                	ld	s0,8(sp)
    8000297c:	0141                	add	sp,sp,16
    8000297e:	8082                	ret

0000000080002980 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002980:	1141                	add	sp,sp,-16
    80002982:	e406                	sd	ra,8(sp)
    80002984:	e022                	sd	s0,0(sp)
    80002986:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    80002988:	fffff097          	auipc	ra,0xfffff
    8000298c:	382080e7          	jalr	898(ra) # 80001d0a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002990:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002994:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002996:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000299a:	00004697          	auipc	a3,0x4
    8000299e:	66668693          	add	a3,a3,1638 # 80007000 <_trampoline>
    800029a2:	00004717          	auipc	a4,0x4
    800029a6:	65e70713          	add	a4,a4,1630 # 80007000 <_trampoline>
    800029aa:	8f15                	sub	a4,a4,a3
    800029ac:	040007b7          	lui	a5,0x4000
    800029b0:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800029b2:	07b2                	sll	a5,a5,0xc
    800029b4:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029b6:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029ba:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029bc:	18002673          	csrr	a2,satp
    800029c0:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029c2:	6d30                	ld	a2,88(a0)
    800029c4:	6138                	ld	a4,64(a0)
    800029c6:	6585                	lui	a1,0x1
    800029c8:	972e                	add	a4,a4,a1
    800029ca:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029cc:	6d38                	ld	a4,88(a0)
    800029ce:	00000617          	auipc	a2,0x0
    800029d2:	13c60613          	add	a2,a2,316 # 80002b0a <usertrap>
    800029d6:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029d8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029da:	8612                	mv	a2,tp
    800029dc:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029de:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029e2:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029e6:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ea:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029ee:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029f0:	6f18                	ld	a4,24(a4)
    800029f2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029f6:	692c                	ld	a1,80(a0)
    800029f8:	81b1                	srl	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029fa:	00004717          	auipc	a4,0x4
    800029fe:	69670713          	add	a4,a4,1686 # 80007090 <userret>
    80002a02:	8f15                	sub	a4,a4,a3
    80002a04:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a06:	577d                	li	a4,-1
    80002a08:	177e                	sll	a4,a4,0x3f
    80002a0a:	8dd9                	or	a1,a1,a4
    80002a0c:	02000537          	lui	a0,0x2000
    80002a10:	157d                	add	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002a12:	0536                	sll	a0,a0,0xd
    80002a14:	9782                	jalr	a5
}
    80002a16:	60a2                	ld	ra,8(sp)
    80002a18:	6402                	ld	s0,0(sp)
    80002a1a:	0141                	add	sp,sp,16
    80002a1c:	8082                	ret

0000000080002a1e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a1e:	1101                	add	sp,sp,-32
    80002a20:	ec06                	sd	ra,24(sp)
    80002a22:	e822                	sd	s0,16(sp)
    80002a24:	e426                	sd	s1,8(sp)
    80002a26:	1000                	add	s0,sp,32
  acquire(&tickslock);
    80002a28:	0001d497          	auipc	s1,0x1d
    80002a2c:	d4048493          	add	s1,s1,-704 # 8001f768 <tickslock>
    80002a30:	8526                	mv	a0,s1
    80002a32:	ffffe097          	auipc	ra,0xffffe
    80002a36:	2b4080e7          	jalr	692(ra) # 80000ce6 <acquire>
  ticks++;
    80002a3a:	00006517          	auipc	a0,0x6
    80002a3e:	5e650513          	add	a0,a0,1510 # 80009020 <ticks>
    80002a42:	411c                	lw	a5,0(a0)
    80002a44:	2785                	addw	a5,a5,1
    80002a46:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a48:	00000097          	auipc	ra,0x0
    80002a4c:	c58080e7          	jalr	-936(ra) # 800026a0 <wakeup>
  release(&tickslock);
    80002a50:	8526                	mv	a0,s1
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	348080e7          	jalr	840(ra) # 80000d9a <release>
}
    80002a5a:	60e2                	ld	ra,24(sp)
    80002a5c:	6442                	ld	s0,16(sp)
    80002a5e:	64a2                	ld	s1,8(sp)
    80002a60:	6105                	add	sp,sp,32
    80002a62:	8082                	ret

0000000080002a64 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a64:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a68:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002a6a:	0807df63          	bgez	a5,80002b08 <devintr+0xa4>
{
    80002a6e:	1101                	add	sp,sp,-32
    80002a70:	ec06                	sd	ra,24(sp)
    80002a72:	e822                	sd	s0,16(sp)
    80002a74:	e426                	sd	s1,8(sp)
    80002a76:	1000                	add	s0,sp,32
     (scause & 0xff) == 9){
    80002a78:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002a7c:	46a5                	li	a3,9
    80002a7e:	00d70d63          	beq	a4,a3,80002a98 <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002a82:	577d                	li	a4,-1
    80002a84:	177e                	sll	a4,a4,0x3f
    80002a86:	0705                	add	a4,a4,1
    return 0;
    80002a88:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a8a:	04e78e63          	beq	a5,a4,80002ae6 <devintr+0x82>
  }
}
    80002a8e:	60e2                	ld	ra,24(sp)
    80002a90:	6442                	ld	s0,16(sp)
    80002a92:	64a2                	ld	s1,8(sp)
    80002a94:	6105                	add	sp,sp,32
    80002a96:	8082                	ret
    int irq = plic_claim();
    80002a98:	00003097          	auipc	ra,0x3
    80002a9c:	480080e7          	jalr	1152(ra) # 80005f18 <plic_claim>
    80002aa0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002aa2:	47a9                	li	a5,10
    80002aa4:	02f50763          	beq	a0,a5,80002ad2 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002aa8:	4785                	li	a5,1
    80002aaa:	02f50963          	beq	a0,a5,80002adc <devintr+0x78>
    return 1;
    80002aae:	4505                	li	a0,1
    } else if(irq){
    80002ab0:	dcf9                	beqz	s1,80002a8e <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ab2:	85a6                	mv	a1,s1
    80002ab4:	00006517          	auipc	a0,0x6
    80002ab8:	82450513          	add	a0,a0,-2012 # 800082d8 <states.0+0x30>
    80002abc:	ffffe097          	auipc	ra,0xffffe
    80002ac0:	ad0080e7          	jalr	-1328(ra) # 8000058c <printf>
      plic_complete(irq);
    80002ac4:	8526                	mv	a0,s1
    80002ac6:	00003097          	auipc	ra,0x3
    80002aca:	476080e7          	jalr	1142(ra) # 80005f3c <plic_complete>
    return 1;
    80002ace:	4505                	li	a0,1
    80002ad0:	bf7d                	j	80002a8e <devintr+0x2a>
      uartintr();
    80002ad2:	ffffe097          	auipc	ra,0xffffe
    80002ad6:	eec080e7          	jalr	-276(ra) # 800009be <uartintr>
    if(irq)
    80002ada:	b7ed                	j	80002ac4 <devintr+0x60>
      virtio_disk_intr();
    80002adc:	00004097          	auipc	ra,0x4
    80002ae0:	8d2080e7          	jalr	-1838(ra) # 800063ae <virtio_disk_intr>
    if(irq)
    80002ae4:	b7c5                	j	80002ac4 <devintr+0x60>
    if(cpuid() == 0){
    80002ae6:	fffff097          	auipc	ra,0xfffff
    80002aea:	1f8080e7          	jalr	504(ra) # 80001cde <cpuid>
    80002aee:	c901                	beqz	a0,80002afe <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002af0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002af4:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002af6:	14479073          	csrw	sip,a5
    return 2;
    80002afa:	4509                	li	a0,2
    80002afc:	bf49                	j	80002a8e <devintr+0x2a>
      clockintr();
    80002afe:	00000097          	auipc	ra,0x0
    80002b02:	f20080e7          	jalr	-224(ra) # 80002a1e <clockintr>
    80002b06:	b7ed                	j	80002af0 <devintr+0x8c>
}
    80002b08:	8082                	ret

0000000080002b0a <usertrap>:
{
    80002b0a:	1101                	add	sp,sp,-32
    80002b0c:	ec06                	sd	ra,24(sp)
    80002b0e:	e822                	sd	s0,16(sp)
    80002b10:	e426                	sd	s1,8(sp)
    80002b12:	e04a                	sd	s2,0(sp)
    80002b14:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b16:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b1a:	1007f793          	and	a5,a5,256
    80002b1e:	e3b9                	bnez	a5,80002b64 <usertrap+0x5a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b20:	00003797          	auipc	a5,0x3
    80002b24:	2f078793          	add	a5,a5,752 # 80005e10 <kernelvec>
    80002b28:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b2c:	fffff097          	auipc	ra,0xfffff
    80002b30:	1de080e7          	jalr	478(ra) # 80001d0a <myproc>
    80002b34:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b36:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b38:	14102773          	csrr	a4,sepc
    80002b3c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b3e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b42:	47a1                	li	a5,8
    80002b44:	02f70863          	beq	a4,a5,80002b74 <usertrap+0x6a>
    80002b48:	14202773          	csrr	a4,scause
  } else if(r_scause() == 15){
    80002b4c:	47bd                	li	a5,15
    80002b4e:	06f70563          	beq	a4,a5,80002bb8 <usertrap+0xae>
  } else if((which_dev = devintr()) != 0){
    80002b52:	00000097          	auipc	ra,0x0
    80002b56:	f12080e7          	jalr	-238(ra) # 80002a64 <devintr>
    80002b5a:	892a                	mv	s2,a0
    80002b5c:	cd3d                	beqz	a0,80002bda <usertrap+0xd0>
  if(p->killed)
    80002b5e:	589c                	lw	a5,48(s1)
    80002b60:	cfc5                	beqz	a5,80002c18 <usertrap+0x10e>
    80002b62:	a075                	j	80002c0e <usertrap+0x104>
    panic("usertrap: not from user mode");
    80002b64:	00005517          	auipc	a0,0x5
    80002b68:	79450513          	add	a0,a0,1940 # 800082f8 <states.0+0x50>
    80002b6c:	ffffe097          	auipc	ra,0xffffe
    80002b70:	9d6080e7          	jalr	-1578(ra) # 80000542 <panic>
    if(p->killed)
    80002b74:	591c                	lw	a5,48(a0)
    80002b76:	eb9d                	bnez	a5,80002bac <usertrap+0xa2>
    p->trapframe->epc += 4;
    80002b78:	6cb8                	ld	a4,88(s1)
    80002b7a:	6f1c                	ld	a5,24(a4)
    80002b7c:	0791                	add	a5,a5,4
    80002b7e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b80:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b84:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b88:	10079073          	csrw	sstatus,a5
    syscall();
    80002b8c:	00000097          	auipc	ra,0x0
    80002b90:	2e2080e7          	jalr	738(ra) # 80002e6e <syscall>
  if(p->killed)
    80002b94:	589c                	lw	a5,48(s1)
    80002b96:	ebc9                	bnez	a5,80002c28 <usertrap+0x11e>
  usertrapret();
    80002b98:	00000097          	auipc	ra,0x0
    80002b9c:	de8080e7          	jalr	-536(ra) # 80002980 <usertrapret>
}
    80002ba0:	60e2                	ld	ra,24(sp)
    80002ba2:	6442                	ld	s0,16(sp)
    80002ba4:	64a2                	ld	s1,8(sp)
    80002ba6:	6902                	ld	s2,0(sp)
    80002ba8:	6105                	add	sp,sp,32
    80002baa:	8082                	ret
      exit(-1);
    80002bac:	557d                	li	a0,-1
    80002bae:	00000097          	auipc	ra,0x0
    80002bb2:	82c080e7          	jalr	-2004(ra) # 800023da <exit>
    80002bb6:	b7c9                	j	80002b78 <usertrap+0x6e>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bb8:	14302973          	csrr	s2,stval
    if (is_cow(p->pagetable, va)) {
    80002bbc:	85ca                	mv	a1,s2
    80002bbe:	6928                	ld	a0,80(a0)
    80002bc0:	ffffe097          	auipc	ra,0xffffe
    80002bc4:	5f0080e7          	jalr	1520(ra) # 800011b0 <is_cow>
    80002bc8:	d571                	beqz	a0,80002b94 <usertrap+0x8a>
        if (cow_alloc2(p->pagetable, va) == 0) {
    80002bca:	85ca                	mv	a1,s2
    80002bcc:	68a8                	ld	a0,80(s1)
    80002bce:	ffffe097          	auipc	ra,0xffffe
    80002bd2:	618080e7          	jalr	1560(ra) # 800011e6 <cow_alloc2>
    80002bd6:	c90d                	beqz	a0,80002c08 <usertrap+0xfe>
    80002bd8:	bf75                	j	80002b94 <usertrap+0x8a>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bda:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bde:	5c90                	lw	a2,56(s1)
    80002be0:	00005517          	auipc	a0,0x5
    80002be4:	73850513          	add	a0,a0,1848 # 80008318 <states.0+0x70>
    80002be8:	ffffe097          	auipc	ra,0xffffe
    80002bec:	9a4080e7          	jalr	-1628(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bf0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bf4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bf8:	00005517          	auipc	a0,0x5
    80002bfc:	75050513          	add	a0,a0,1872 # 80008348 <states.0+0xa0>
    80002c00:	ffffe097          	auipc	ra,0xffffe
    80002c04:	98c080e7          	jalr	-1652(ra) # 8000058c <printf>
            p->killed = 1;
    80002c08:	4785                	li	a5,1
    80002c0a:	d89c                	sw	a5,48(s1)
    80002c0c:	4901                	li	s2,0
    exit(-1);
    80002c0e:	557d                	li	a0,-1
    80002c10:	fffff097          	auipc	ra,0xfffff
    80002c14:	7ca080e7          	jalr	1994(ra) # 800023da <exit>
  if(which_dev == 2)
    80002c18:	4789                	li	a5,2
    80002c1a:	f6f91fe3          	bne	s2,a5,80002b98 <usertrap+0x8e>
    yield();
    80002c1e:	00000097          	auipc	ra,0x0
    80002c22:	8c6080e7          	jalr	-1850(ra) # 800024e4 <yield>
    80002c26:	bf8d                	j	80002b98 <usertrap+0x8e>
  if(p->killed)
    80002c28:	4901                	li	s2,0
    80002c2a:	b7d5                	j	80002c0e <usertrap+0x104>

0000000080002c2c <kerneltrap>:
{
    80002c2c:	7179                	add	sp,sp,-48
    80002c2e:	f406                	sd	ra,40(sp)
    80002c30:	f022                	sd	s0,32(sp)
    80002c32:	ec26                	sd	s1,24(sp)
    80002c34:	e84a                	sd	s2,16(sp)
    80002c36:	e44e                	sd	s3,8(sp)
    80002c38:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c3a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c3e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c42:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c46:	1004f793          	and	a5,s1,256
    80002c4a:	cb85                	beqz	a5,80002c7a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c4c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c50:	8b89                	and	a5,a5,2
  if(intr_get() != 0)
    80002c52:	ef85                	bnez	a5,80002c8a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c54:	00000097          	auipc	ra,0x0
    80002c58:	e10080e7          	jalr	-496(ra) # 80002a64 <devintr>
    80002c5c:	cd1d                	beqz	a0,80002c9a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c5e:	4789                	li	a5,2
    80002c60:	06f50a63          	beq	a0,a5,80002cd4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c64:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c68:	10049073          	csrw	sstatus,s1
}
    80002c6c:	70a2                	ld	ra,40(sp)
    80002c6e:	7402                	ld	s0,32(sp)
    80002c70:	64e2                	ld	s1,24(sp)
    80002c72:	6942                	ld	s2,16(sp)
    80002c74:	69a2                	ld	s3,8(sp)
    80002c76:	6145                	add	sp,sp,48
    80002c78:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c7a:	00005517          	auipc	a0,0x5
    80002c7e:	6ee50513          	add	a0,a0,1774 # 80008368 <states.0+0xc0>
    80002c82:	ffffe097          	auipc	ra,0xffffe
    80002c86:	8c0080e7          	jalr	-1856(ra) # 80000542 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c8a:	00005517          	auipc	a0,0x5
    80002c8e:	70650513          	add	a0,a0,1798 # 80008390 <states.0+0xe8>
    80002c92:	ffffe097          	auipc	ra,0xffffe
    80002c96:	8b0080e7          	jalr	-1872(ra) # 80000542 <panic>
    printf("scause %p\n", scause);
    80002c9a:	85ce                	mv	a1,s3
    80002c9c:	00005517          	auipc	a0,0x5
    80002ca0:	71450513          	add	a0,a0,1812 # 800083b0 <states.0+0x108>
    80002ca4:	ffffe097          	auipc	ra,0xffffe
    80002ca8:	8e8080e7          	jalr	-1816(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cac:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cb0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cb4:	00005517          	auipc	a0,0x5
    80002cb8:	70c50513          	add	a0,a0,1804 # 800083c0 <states.0+0x118>
    80002cbc:	ffffe097          	auipc	ra,0xffffe
    80002cc0:	8d0080e7          	jalr	-1840(ra) # 8000058c <printf>
    panic("kerneltrap");
    80002cc4:	00005517          	auipc	a0,0x5
    80002cc8:	71450513          	add	a0,a0,1812 # 800083d8 <states.0+0x130>
    80002ccc:	ffffe097          	auipc	ra,0xffffe
    80002cd0:	876080e7          	jalr	-1930(ra) # 80000542 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cd4:	fffff097          	auipc	ra,0xfffff
    80002cd8:	036080e7          	jalr	54(ra) # 80001d0a <myproc>
    80002cdc:	d541                	beqz	a0,80002c64 <kerneltrap+0x38>
    80002cde:	fffff097          	auipc	ra,0xfffff
    80002ce2:	02c080e7          	jalr	44(ra) # 80001d0a <myproc>
    80002ce6:	4d18                	lw	a4,24(a0)
    80002ce8:	478d                	li	a5,3
    80002cea:	f6f71de3          	bne	a4,a5,80002c64 <kerneltrap+0x38>
    yield();
    80002cee:	fffff097          	auipc	ra,0xfffff
    80002cf2:	7f6080e7          	jalr	2038(ra) # 800024e4 <yield>
    80002cf6:	b7bd                	j	80002c64 <kerneltrap+0x38>

0000000080002cf8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cf8:	1101                	add	sp,sp,-32
    80002cfa:	ec06                	sd	ra,24(sp)
    80002cfc:	e822                	sd	s0,16(sp)
    80002cfe:	e426                	sd	s1,8(sp)
    80002d00:	1000                	add	s0,sp,32
    80002d02:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d04:	fffff097          	auipc	ra,0xfffff
    80002d08:	006080e7          	jalr	6(ra) # 80001d0a <myproc>
  switch (n) {
    80002d0c:	4795                	li	a5,5
    80002d0e:	0497e163          	bltu	a5,s1,80002d50 <argraw+0x58>
    80002d12:	048a                	sll	s1,s1,0x2
    80002d14:	00005717          	auipc	a4,0x5
    80002d18:	6fc70713          	add	a4,a4,1788 # 80008410 <states.0+0x168>
    80002d1c:	94ba                	add	s1,s1,a4
    80002d1e:	409c                	lw	a5,0(s1)
    80002d20:	97ba                	add	a5,a5,a4
    80002d22:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d24:	6d3c                	ld	a5,88(a0)
    80002d26:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d28:	60e2                	ld	ra,24(sp)
    80002d2a:	6442                	ld	s0,16(sp)
    80002d2c:	64a2                	ld	s1,8(sp)
    80002d2e:	6105                	add	sp,sp,32
    80002d30:	8082                	ret
    return p->trapframe->a1;
    80002d32:	6d3c                	ld	a5,88(a0)
    80002d34:	7fa8                	ld	a0,120(a5)
    80002d36:	bfcd                	j	80002d28 <argraw+0x30>
    return p->trapframe->a2;
    80002d38:	6d3c                	ld	a5,88(a0)
    80002d3a:	63c8                	ld	a0,128(a5)
    80002d3c:	b7f5                	j	80002d28 <argraw+0x30>
    return p->trapframe->a3;
    80002d3e:	6d3c                	ld	a5,88(a0)
    80002d40:	67c8                	ld	a0,136(a5)
    80002d42:	b7dd                	j	80002d28 <argraw+0x30>
    return p->trapframe->a4;
    80002d44:	6d3c                	ld	a5,88(a0)
    80002d46:	6bc8                	ld	a0,144(a5)
    80002d48:	b7c5                	j	80002d28 <argraw+0x30>
    return p->trapframe->a5;
    80002d4a:	6d3c                	ld	a5,88(a0)
    80002d4c:	6fc8                	ld	a0,152(a5)
    80002d4e:	bfe9                	j	80002d28 <argraw+0x30>
  panic("argraw");
    80002d50:	00005517          	auipc	a0,0x5
    80002d54:	69850513          	add	a0,a0,1688 # 800083e8 <states.0+0x140>
    80002d58:	ffffd097          	auipc	ra,0xffffd
    80002d5c:	7ea080e7          	jalr	2026(ra) # 80000542 <panic>

0000000080002d60 <fetchaddr>:
{
    80002d60:	1101                	add	sp,sp,-32
    80002d62:	ec06                	sd	ra,24(sp)
    80002d64:	e822                	sd	s0,16(sp)
    80002d66:	e426                	sd	s1,8(sp)
    80002d68:	e04a                	sd	s2,0(sp)
    80002d6a:	1000                	add	s0,sp,32
    80002d6c:	84aa                	mv	s1,a0
    80002d6e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	f9a080e7          	jalr	-102(ra) # 80001d0a <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d78:	653c                	ld	a5,72(a0)
    80002d7a:	02f4f863          	bgeu	s1,a5,80002daa <fetchaddr+0x4a>
    80002d7e:	00848713          	add	a4,s1,8
    80002d82:	02e7e663          	bltu	a5,a4,80002dae <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d86:	46a1                	li	a3,8
    80002d88:	8626                	mv	a2,s1
    80002d8a:	85ca                	mv	a1,s2
    80002d8c:	6928                	ld	a0,80(a0)
    80002d8e:	fffff097          	auipc	ra,0xfffff
    80002d92:	cfe080e7          	jalr	-770(ra) # 80001a8c <copyin>
    80002d96:	00a03533          	snez	a0,a0
    80002d9a:	40a00533          	neg	a0,a0
}
    80002d9e:	60e2                	ld	ra,24(sp)
    80002da0:	6442                	ld	s0,16(sp)
    80002da2:	64a2                	ld	s1,8(sp)
    80002da4:	6902                	ld	s2,0(sp)
    80002da6:	6105                	add	sp,sp,32
    80002da8:	8082                	ret
    return -1;
    80002daa:	557d                	li	a0,-1
    80002dac:	bfcd                	j	80002d9e <fetchaddr+0x3e>
    80002dae:	557d                	li	a0,-1
    80002db0:	b7fd                	j	80002d9e <fetchaddr+0x3e>

0000000080002db2 <fetchstr>:
{
    80002db2:	7179                	add	sp,sp,-48
    80002db4:	f406                	sd	ra,40(sp)
    80002db6:	f022                	sd	s0,32(sp)
    80002db8:	ec26                	sd	s1,24(sp)
    80002dba:	e84a                	sd	s2,16(sp)
    80002dbc:	e44e                	sd	s3,8(sp)
    80002dbe:	1800                	add	s0,sp,48
    80002dc0:	892a                	mv	s2,a0
    80002dc2:	84ae                	mv	s1,a1
    80002dc4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002dc6:	fffff097          	auipc	ra,0xfffff
    80002dca:	f44080e7          	jalr	-188(ra) # 80001d0a <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002dce:	86ce                	mv	a3,s3
    80002dd0:	864a                	mv	a2,s2
    80002dd2:	85a6                	mv	a1,s1
    80002dd4:	6928                	ld	a0,80(a0)
    80002dd6:	fffff097          	auipc	ra,0xfffff
    80002dda:	d44080e7          	jalr	-700(ra) # 80001b1a <copyinstr>
  if(err < 0)
    80002dde:	00054763          	bltz	a0,80002dec <fetchstr+0x3a>
  return strlen(buf);
    80002de2:	8526                	mv	a0,s1
    80002de4:	ffffe097          	auipc	ra,0xffffe
    80002de8:	180080e7          	jalr	384(ra) # 80000f64 <strlen>
}
    80002dec:	70a2                	ld	ra,40(sp)
    80002dee:	7402                	ld	s0,32(sp)
    80002df0:	64e2                	ld	s1,24(sp)
    80002df2:	6942                	ld	s2,16(sp)
    80002df4:	69a2                	ld	s3,8(sp)
    80002df6:	6145                	add	sp,sp,48
    80002df8:	8082                	ret

0000000080002dfa <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002dfa:	1101                	add	sp,sp,-32
    80002dfc:	ec06                	sd	ra,24(sp)
    80002dfe:	e822                	sd	s0,16(sp)
    80002e00:	e426                	sd	s1,8(sp)
    80002e02:	1000                	add	s0,sp,32
    80002e04:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e06:	00000097          	auipc	ra,0x0
    80002e0a:	ef2080e7          	jalr	-270(ra) # 80002cf8 <argraw>
    80002e0e:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e10:	4501                	li	a0,0
    80002e12:	60e2                	ld	ra,24(sp)
    80002e14:	6442                	ld	s0,16(sp)
    80002e16:	64a2                	ld	s1,8(sp)
    80002e18:	6105                	add	sp,sp,32
    80002e1a:	8082                	ret

0000000080002e1c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e1c:	1101                	add	sp,sp,-32
    80002e1e:	ec06                	sd	ra,24(sp)
    80002e20:	e822                	sd	s0,16(sp)
    80002e22:	e426                	sd	s1,8(sp)
    80002e24:	1000                	add	s0,sp,32
    80002e26:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e28:	00000097          	auipc	ra,0x0
    80002e2c:	ed0080e7          	jalr	-304(ra) # 80002cf8 <argraw>
    80002e30:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e32:	4501                	li	a0,0
    80002e34:	60e2                	ld	ra,24(sp)
    80002e36:	6442                	ld	s0,16(sp)
    80002e38:	64a2                	ld	s1,8(sp)
    80002e3a:	6105                	add	sp,sp,32
    80002e3c:	8082                	ret

0000000080002e3e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e3e:	1101                	add	sp,sp,-32
    80002e40:	ec06                	sd	ra,24(sp)
    80002e42:	e822                	sd	s0,16(sp)
    80002e44:	e426                	sd	s1,8(sp)
    80002e46:	e04a                	sd	s2,0(sp)
    80002e48:	1000                	add	s0,sp,32
    80002e4a:	84ae                	mv	s1,a1
    80002e4c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e4e:	00000097          	auipc	ra,0x0
    80002e52:	eaa080e7          	jalr	-342(ra) # 80002cf8 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e56:	864a                	mv	a2,s2
    80002e58:	85a6                	mv	a1,s1
    80002e5a:	00000097          	auipc	ra,0x0
    80002e5e:	f58080e7          	jalr	-168(ra) # 80002db2 <fetchstr>
}
    80002e62:	60e2                	ld	ra,24(sp)
    80002e64:	6442                	ld	s0,16(sp)
    80002e66:	64a2                	ld	s1,8(sp)
    80002e68:	6902                	ld	s2,0(sp)
    80002e6a:	6105                	add	sp,sp,32
    80002e6c:	8082                	ret

0000000080002e6e <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002e6e:	1101                	add	sp,sp,-32
    80002e70:	ec06                	sd	ra,24(sp)
    80002e72:	e822                	sd	s0,16(sp)
    80002e74:	e426                	sd	s1,8(sp)
    80002e76:	e04a                	sd	s2,0(sp)
    80002e78:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e7a:	fffff097          	auipc	ra,0xfffff
    80002e7e:	e90080e7          	jalr	-368(ra) # 80001d0a <myproc>
    80002e82:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e84:	05853903          	ld	s2,88(a0)
    80002e88:	0a893783          	ld	a5,168(s2)
    80002e8c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e90:	37fd                	addw	a5,a5,-1
    80002e92:	4751                	li	a4,20
    80002e94:	00f76f63          	bltu	a4,a5,80002eb2 <syscall+0x44>
    80002e98:	00369713          	sll	a4,a3,0x3
    80002e9c:	00005797          	auipc	a5,0x5
    80002ea0:	58c78793          	add	a5,a5,1420 # 80008428 <syscalls>
    80002ea4:	97ba                	add	a5,a5,a4
    80002ea6:	639c                	ld	a5,0(a5)
    80002ea8:	c789                	beqz	a5,80002eb2 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002eaa:	9782                	jalr	a5
    80002eac:	06a93823          	sd	a0,112(s2)
    80002eb0:	a839                	j	80002ece <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002eb2:	15848613          	add	a2,s1,344
    80002eb6:	5c8c                	lw	a1,56(s1)
    80002eb8:	00005517          	auipc	a0,0x5
    80002ebc:	53850513          	add	a0,a0,1336 # 800083f0 <states.0+0x148>
    80002ec0:	ffffd097          	auipc	ra,0xffffd
    80002ec4:	6cc080e7          	jalr	1740(ra) # 8000058c <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ec8:	6cbc                	ld	a5,88(s1)
    80002eca:	577d                	li	a4,-1
    80002ecc:	fbb8                	sd	a4,112(a5)
  }
}
    80002ece:	60e2                	ld	ra,24(sp)
    80002ed0:	6442                	ld	s0,16(sp)
    80002ed2:	64a2                	ld	s1,8(sp)
    80002ed4:	6902                	ld	s2,0(sp)
    80002ed6:	6105                	add	sp,sp,32
    80002ed8:	8082                	ret

0000000080002eda <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002eda:	1101                	add	sp,sp,-32
    80002edc:	ec06                	sd	ra,24(sp)
    80002ede:	e822                	sd	s0,16(sp)
    80002ee0:	1000                	add	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ee2:	fec40593          	add	a1,s0,-20
    80002ee6:	4501                	li	a0,0
    80002ee8:	00000097          	auipc	ra,0x0
    80002eec:	f12080e7          	jalr	-238(ra) # 80002dfa <argint>
    return -1;
    80002ef0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ef2:	00054963          	bltz	a0,80002f04 <sys_exit+0x2a>
  exit(n);
    80002ef6:	fec42503          	lw	a0,-20(s0)
    80002efa:	fffff097          	auipc	ra,0xfffff
    80002efe:	4e0080e7          	jalr	1248(ra) # 800023da <exit>
  return 0;  // not reached
    80002f02:	4781                	li	a5,0
}
    80002f04:	853e                	mv	a0,a5
    80002f06:	60e2                	ld	ra,24(sp)
    80002f08:	6442                	ld	s0,16(sp)
    80002f0a:	6105                	add	sp,sp,32
    80002f0c:	8082                	ret

0000000080002f0e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f0e:	1141                	add	sp,sp,-16
    80002f10:	e406                	sd	ra,8(sp)
    80002f12:	e022                	sd	s0,0(sp)
    80002f14:	0800                	add	s0,sp,16
  return myproc()->pid;
    80002f16:	fffff097          	auipc	ra,0xfffff
    80002f1a:	df4080e7          	jalr	-524(ra) # 80001d0a <myproc>
}
    80002f1e:	5d08                	lw	a0,56(a0)
    80002f20:	60a2                	ld	ra,8(sp)
    80002f22:	6402                	ld	s0,0(sp)
    80002f24:	0141                	add	sp,sp,16
    80002f26:	8082                	ret

0000000080002f28 <sys_fork>:

uint64
sys_fork(void)
{
    80002f28:	1141                	add	sp,sp,-16
    80002f2a:	e406                	sd	ra,8(sp)
    80002f2c:	e022                	sd	s0,0(sp)
    80002f2e:	0800                	add	s0,sp,16
  return fork();
    80002f30:	fffff097          	auipc	ra,0xfffff
    80002f34:	19e080e7          	jalr	414(ra) # 800020ce <fork>
}
    80002f38:	60a2                	ld	ra,8(sp)
    80002f3a:	6402                	ld	s0,0(sp)
    80002f3c:	0141                	add	sp,sp,16
    80002f3e:	8082                	ret

0000000080002f40 <sys_wait>:

uint64
sys_wait(void)
{
    80002f40:	1101                	add	sp,sp,-32
    80002f42:	ec06                	sd	ra,24(sp)
    80002f44:	e822                	sd	s0,16(sp)
    80002f46:	1000                	add	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f48:	fe840593          	add	a1,s0,-24
    80002f4c:	4501                	li	a0,0
    80002f4e:	00000097          	auipc	ra,0x0
    80002f52:	ece080e7          	jalr	-306(ra) # 80002e1c <argaddr>
    80002f56:	87aa                	mv	a5,a0
    return -1;
    80002f58:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f5a:	0007c863          	bltz	a5,80002f6a <sys_wait+0x2a>
  return wait(p);
    80002f5e:	fe843503          	ld	a0,-24(s0)
    80002f62:	fffff097          	auipc	ra,0xfffff
    80002f66:	63c080e7          	jalr	1596(ra) # 8000259e <wait>
}
    80002f6a:	60e2                	ld	ra,24(sp)
    80002f6c:	6442                	ld	s0,16(sp)
    80002f6e:	6105                	add	sp,sp,32
    80002f70:	8082                	ret

0000000080002f72 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f72:	7179                	add	sp,sp,-48
    80002f74:	f406                	sd	ra,40(sp)
    80002f76:	f022                	sd	s0,32(sp)
    80002f78:	ec26                	sd	s1,24(sp)
    80002f7a:	1800                	add	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f7c:	fdc40593          	add	a1,s0,-36
    80002f80:	4501                	li	a0,0
    80002f82:	00000097          	auipc	ra,0x0
    80002f86:	e78080e7          	jalr	-392(ra) # 80002dfa <argint>
    80002f8a:	87aa                	mv	a5,a0
    return -1;
    80002f8c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f8e:	0207c063          	bltz	a5,80002fae <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f92:	fffff097          	auipc	ra,0xfffff
    80002f96:	d78080e7          	jalr	-648(ra) # 80001d0a <myproc>
    80002f9a:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002f9c:	fdc42503          	lw	a0,-36(s0)
    80002fa0:	fffff097          	auipc	ra,0xfffff
    80002fa4:	0b6080e7          	jalr	182(ra) # 80002056 <growproc>
    80002fa8:	00054863          	bltz	a0,80002fb8 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002fac:	8526                	mv	a0,s1
}
    80002fae:	70a2                	ld	ra,40(sp)
    80002fb0:	7402                	ld	s0,32(sp)
    80002fb2:	64e2                	ld	s1,24(sp)
    80002fb4:	6145                	add	sp,sp,48
    80002fb6:	8082                	ret
    return -1;
    80002fb8:	557d                	li	a0,-1
    80002fba:	bfd5                	j	80002fae <sys_sbrk+0x3c>

0000000080002fbc <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fbc:	7139                	add	sp,sp,-64
    80002fbe:	fc06                	sd	ra,56(sp)
    80002fc0:	f822                	sd	s0,48(sp)
    80002fc2:	f426                	sd	s1,40(sp)
    80002fc4:	f04a                	sd	s2,32(sp)
    80002fc6:	ec4e                	sd	s3,24(sp)
    80002fc8:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fca:	fcc40593          	add	a1,s0,-52
    80002fce:	4501                	li	a0,0
    80002fd0:	00000097          	auipc	ra,0x0
    80002fd4:	e2a080e7          	jalr	-470(ra) # 80002dfa <argint>
    return -1;
    80002fd8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fda:	06054563          	bltz	a0,80003044 <sys_sleep+0x88>
  acquire(&tickslock);
    80002fde:	0001c517          	auipc	a0,0x1c
    80002fe2:	78a50513          	add	a0,a0,1930 # 8001f768 <tickslock>
    80002fe6:	ffffe097          	auipc	ra,0xffffe
    80002fea:	d00080e7          	jalr	-768(ra) # 80000ce6 <acquire>
  ticks0 = ticks;
    80002fee:	00006917          	auipc	s2,0x6
    80002ff2:	03292903          	lw	s2,50(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002ff6:	fcc42783          	lw	a5,-52(s0)
    80002ffa:	cf85                	beqz	a5,80003032 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ffc:	0001c997          	auipc	s3,0x1c
    80003000:	76c98993          	add	s3,s3,1900 # 8001f768 <tickslock>
    80003004:	00006497          	auipc	s1,0x6
    80003008:	01c48493          	add	s1,s1,28 # 80009020 <ticks>
    if(myproc()->killed){
    8000300c:	fffff097          	auipc	ra,0xfffff
    80003010:	cfe080e7          	jalr	-770(ra) # 80001d0a <myproc>
    80003014:	591c                	lw	a5,48(a0)
    80003016:	ef9d                	bnez	a5,80003054 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003018:	85ce                	mv	a1,s3
    8000301a:	8526                	mv	a0,s1
    8000301c:	fffff097          	auipc	ra,0xfffff
    80003020:	504080e7          	jalr	1284(ra) # 80002520 <sleep>
  while(ticks - ticks0 < n){
    80003024:	409c                	lw	a5,0(s1)
    80003026:	412787bb          	subw	a5,a5,s2
    8000302a:	fcc42703          	lw	a4,-52(s0)
    8000302e:	fce7efe3          	bltu	a5,a4,8000300c <sys_sleep+0x50>
  }
  release(&tickslock);
    80003032:	0001c517          	auipc	a0,0x1c
    80003036:	73650513          	add	a0,a0,1846 # 8001f768 <tickslock>
    8000303a:	ffffe097          	auipc	ra,0xffffe
    8000303e:	d60080e7          	jalr	-672(ra) # 80000d9a <release>
  return 0;
    80003042:	4781                	li	a5,0
}
    80003044:	853e                	mv	a0,a5
    80003046:	70e2                	ld	ra,56(sp)
    80003048:	7442                	ld	s0,48(sp)
    8000304a:	74a2                	ld	s1,40(sp)
    8000304c:	7902                	ld	s2,32(sp)
    8000304e:	69e2                	ld	s3,24(sp)
    80003050:	6121                	add	sp,sp,64
    80003052:	8082                	ret
      release(&tickslock);
    80003054:	0001c517          	auipc	a0,0x1c
    80003058:	71450513          	add	a0,a0,1812 # 8001f768 <tickslock>
    8000305c:	ffffe097          	auipc	ra,0xffffe
    80003060:	d3e080e7          	jalr	-706(ra) # 80000d9a <release>
      return -1;
    80003064:	57fd                	li	a5,-1
    80003066:	bff9                	j	80003044 <sys_sleep+0x88>

0000000080003068 <sys_kill>:

uint64
sys_kill(void)
{
    80003068:	1101                	add	sp,sp,-32
    8000306a:	ec06                	sd	ra,24(sp)
    8000306c:	e822                	sd	s0,16(sp)
    8000306e:	1000                	add	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003070:	fec40593          	add	a1,s0,-20
    80003074:	4501                	li	a0,0
    80003076:	00000097          	auipc	ra,0x0
    8000307a:	d84080e7          	jalr	-636(ra) # 80002dfa <argint>
    8000307e:	87aa                	mv	a5,a0
    return -1;
    80003080:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003082:	0007c863          	bltz	a5,80003092 <sys_kill+0x2a>
  return kill(pid);
    80003086:	fec42503          	lw	a0,-20(s0)
    8000308a:	fffff097          	auipc	ra,0xfffff
    8000308e:	680080e7          	jalr	1664(ra) # 8000270a <kill>
}
    80003092:	60e2                	ld	ra,24(sp)
    80003094:	6442                	ld	s0,16(sp)
    80003096:	6105                	add	sp,sp,32
    80003098:	8082                	ret

000000008000309a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000309a:	1101                	add	sp,sp,-32
    8000309c:	ec06                	sd	ra,24(sp)
    8000309e:	e822                	sd	s0,16(sp)
    800030a0:	e426                	sd	s1,8(sp)
    800030a2:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030a4:	0001c517          	auipc	a0,0x1c
    800030a8:	6c450513          	add	a0,a0,1732 # 8001f768 <tickslock>
    800030ac:	ffffe097          	auipc	ra,0xffffe
    800030b0:	c3a080e7          	jalr	-966(ra) # 80000ce6 <acquire>
  xticks = ticks;
    800030b4:	00006497          	auipc	s1,0x6
    800030b8:	f6c4a483          	lw	s1,-148(s1) # 80009020 <ticks>
  release(&tickslock);
    800030bc:	0001c517          	auipc	a0,0x1c
    800030c0:	6ac50513          	add	a0,a0,1708 # 8001f768 <tickslock>
    800030c4:	ffffe097          	auipc	ra,0xffffe
    800030c8:	cd6080e7          	jalr	-810(ra) # 80000d9a <release>
  return xticks;
}
    800030cc:	02049513          	sll	a0,s1,0x20
    800030d0:	9101                	srl	a0,a0,0x20
    800030d2:	60e2                	ld	ra,24(sp)
    800030d4:	6442                	ld	s0,16(sp)
    800030d6:	64a2                	ld	s1,8(sp)
    800030d8:	6105                	add	sp,sp,32
    800030da:	8082                	ret

00000000800030dc <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030dc:	7179                	add	sp,sp,-48
    800030de:	f406                	sd	ra,40(sp)
    800030e0:	f022                	sd	s0,32(sp)
    800030e2:	ec26                	sd	s1,24(sp)
    800030e4:	e84a                	sd	s2,16(sp)
    800030e6:	e44e                	sd	s3,8(sp)
    800030e8:	e052                	sd	s4,0(sp)
    800030ea:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030ec:	00005597          	auipc	a1,0x5
    800030f0:	3ec58593          	add	a1,a1,1004 # 800084d8 <syscalls+0xb0>
    800030f4:	0001c517          	auipc	a0,0x1c
    800030f8:	68c50513          	add	a0,a0,1676 # 8001f780 <bcache>
    800030fc:	ffffe097          	auipc	ra,0xffffe
    80003100:	b5a080e7          	jalr	-1190(ra) # 80000c56 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003104:	00024797          	auipc	a5,0x24
    80003108:	67c78793          	add	a5,a5,1660 # 80027780 <bcache+0x8000>
    8000310c:	00025717          	auipc	a4,0x25
    80003110:	8dc70713          	add	a4,a4,-1828 # 800279e8 <bcache+0x8268>
    80003114:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003118:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000311c:	0001c497          	auipc	s1,0x1c
    80003120:	67c48493          	add	s1,s1,1660 # 8001f798 <bcache+0x18>
    b->next = bcache.head.next;
    80003124:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003126:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003128:	00005a17          	auipc	s4,0x5
    8000312c:	3b8a0a13          	add	s4,s4,952 # 800084e0 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003130:	2b893783          	ld	a5,696(s2)
    80003134:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003136:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000313a:	85d2                	mv	a1,s4
    8000313c:	01048513          	add	a0,s1,16
    80003140:	00001097          	auipc	ra,0x1
    80003144:	484080e7          	jalr	1156(ra) # 800045c4 <initsleeplock>
    bcache.head.next->prev = b;
    80003148:	2b893783          	ld	a5,696(s2)
    8000314c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000314e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003152:	45848493          	add	s1,s1,1112
    80003156:	fd349de3          	bne	s1,s3,80003130 <binit+0x54>
  }
}
    8000315a:	70a2                	ld	ra,40(sp)
    8000315c:	7402                	ld	s0,32(sp)
    8000315e:	64e2                	ld	s1,24(sp)
    80003160:	6942                	ld	s2,16(sp)
    80003162:	69a2                	ld	s3,8(sp)
    80003164:	6a02                	ld	s4,0(sp)
    80003166:	6145                	add	sp,sp,48
    80003168:	8082                	ret

000000008000316a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000316a:	7179                	add	sp,sp,-48
    8000316c:	f406                	sd	ra,40(sp)
    8000316e:	f022                	sd	s0,32(sp)
    80003170:	ec26                	sd	s1,24(sp)
    80003172:	e84a                	sd	s2,16(sp)
    80003174:	e44e                	sd	s3,8(sp)
    80003176:	1800                	add	s0,sp,48
    80003178:	892a                	mv	s2,a0
    8000317a:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000317c:	0001c517          	auipc	a0,0x1c
    80003180:	60450513          	add	a0,a0,1540 # 8001f780 <bcache>
    80003184:	ffffe097          	auipc	ra,0xffffe
    80003188:	b62080e7          	jalr	-1182(ra) # 80000ce6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000318c:	00025497          	auipc	s1,0x25
    80003190:	8ac4b483          	ld	s1,-1876(s1) # 80027a38 <bcache+0x82b8>
    80003194:	00025797          	auipc	a5,0x25
    80003198:	85478793          	add	a5,a5,-1964 # 800279e8 <bcache+0x8268>
    8000319c:	02f48f63          	beq	s1,a5,800031da <bread+0x70>
    800031a0:	873e                	mv	a4,a5
    800031a2:	a021                	j	800031aa <bread+0x40>
    800031a4:	68a4                	ld	s1,80(s1)
    800031a6:	02e48a63          	beq	s1,a4,800031da <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031aa:	449c                	lw	a5,8(s1)
    800031ac:	ff279ce3          	bne	a5,s2,800031a4 <bread+0x3a>
    800031b0:	44dc                	lw	a5,12(s1)
    800031b2:	ff3799e3          	bne	a5,s3,800031a4 <bread+0x3a>
      b->refcnt++;
    800031b6:	40bc                	lw	a5,64(s1)
    800031b8:	2785                	addw	a5,a5,1
    800031ba:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031bc:	0001c517          	auipc	a0,0x1c
    800031c0:	5c450513          	add	a0,a0,1476 # 8001f780 <bcache>
    800031c4:	ffffe097          	auipc	ra,0xffffe
    800031c8:	bd6080e7          	jalr	-1066(ra) # 80000d9a <release>
      acquiresleep(&b->lock);
    800031cc:	01048513          	add	a0,s1,16
    800031d0:	00001097          	auipc	ra,0x1
    800031d4:	42e080e7          	jalr	1070(ra) # 800045fe <acquiresleep>
      return b;
    800031d8:	a8b9                	j	80003236 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031da:	00025497          	auipc	s1,0x25
    800031de:	8564b483          	ld	s1,-1962(s1) # 80027a30 <bcache+0x82b0>
    800031e2:	00025797          	auipc	a5,0x25
    800031e6:	80678793          	add	a5,a5,-2042 # 800279e8 <bcache+0x8268>
    800031ea:	00f48863          	beq	s1,a5,800031fa <bread+0x90>
    800031ee:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031f0:	40bc                	lw	a5,64(s1)
    800031f2:	cf81                	beqz	a5,8000320a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031f4:	64a4                	ld	s1,72(s1)
    800031f6:	fee49de3          	bne	s1,a4,800031f0 <bread+0x86>
  panic("bget: no buffers");
    800031fa:	00005517          	auipc	a0,0x5
    800031fe:	2ee50513          	add	a0,a0,750 # 800084e8 <syscalls+0xc0>
    80003202:	ffffd097          	auipc	ra,0xffffd
    80003206:	340080e7          	jalr	832(ra) # 80000542 <panic>
      b->dev = dev;
    8000320a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000320e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003212:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003216:	4785                	li	a5,1
    80003218:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000321a:	0001c517          	auipc	a0,0x1c
    8000321e:	56650513          	add	a0,a0,1382 # 8001f780 <bcache>
    80003222:	ffffe097          	auipc	ra,0xffffe
    80003226:	b78080e7          	jalr	-1160(ra) # 80000d9a <release>
      acquiresleep(&b->lock);
    8000322a:	01048513          	add	a0,s1,16
    8000322e:	00001097          	auipc	ra,0x1
    80003232:	3d0080e7          	jalr	976(ra) # 800045fe <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003236:	409c                	lw	a5,0(s1)
    80003238:	cb89                	beqz	a5,8000324a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000323a:	8526                	mv	a0,s1
    8000323c:	70a2                	ld	ra,40(sp)
    8000323e:	7402                	ld	s0,32(sp)
    80003240:	64e2                	ld	s1,24(sp)
    80003242:	6942                	ld	s2,16(sp)
    80003244:	69a2                	ld	s3,8(sp)
    80003246:	6145                	add	sp,sp,48
    80003248:	8082                	ret
    virtio_disk_rw(b, 0);
    8000324a:	4581                	li	a1,0
    8000324c:	8526                	mv	a0,s1
    8000324e:	00003097          	auipc	ra,0x3
    80003252:	eda080e7          	jalr	-294(ra) # 80006128 <virtio_disk_rw>
    b->valid = 1;
    80003256:	4785                	li	a5,1
    80003258:	c09c                	sw	a5,0(s1)
  return b;
    8000325a:	b7c5                	j	8000323a <bread+0xd0>

000000008000325c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000325c:	1101                	add	sp,sp,-32
    8000325e:	ec06                	sd	ra,24(sp)
    80003260:	e822                	sd	s0,16(sp)
    80003262:	e426                	sd	s1,8(sp)
    80003264:	1000                	add	s0,sp,32
    80003266:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003268:	0541                	add	a0,a0,16
    8000326a:	00001097          	auipc	ra,0x1
    8000326e:	42e080e7          	jalr	1070(ra) # 80004698 <holdingsleep>
    80003272:	cd01                	beqz	a0,8000328a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003274:	4585                	li	a1,1
    80003276:	8526                	mv	a0,s1
    80003278:	00003097          	auipc	ra,0x3
    8000327c:	eb0080e7          	jalr	-336(ra) # 80006128 <virtio_disk_rw>
}
    80003280:	60e2                	ld	ra,24(sp)
    80003282:	6442                	ld	s0,16(sp)
    80003284:	64a2                	ld	s1,8(sp)
    80003286:	6105                	add	sp,sp,32
    80003288:	8082                	ret
    panic("bwrite");
    8000328a:	00005517          	auipc	a0,0x5
    8000328e:	27650513          	add	a0,a0,630 # 80008500 <syscalls+0xd8>
    80003292:	ffffd097          	auipc	ra,0xffffd
    80003296:	2b0080e7          	jalr	688(ra) # 80000542 <panic>

000000008000329a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000329a:	1101                	add	sp,sp,-32
    8000329c:	ec06                	sd	ra,24(sp)
    8000329e:	e822                	sd	s0,16(sp)
    800032a0:	e426                	sd	s1,8(sp)
    800032a2:	e04a                	sd	s2,0(sp)
    800032a4:	1000                	add	s0,sp,32
    800032a6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032a8:	01050913          	add	s2,a0,16
    800032ac:	854a                	mv	a0,s2
    800032ae:	00001097          	auipc	ra,0x1
    800032b2:	3ea080e7          	jalr	1002(ra) # 80004698 <holdingsleep>
    800032b6:	c925                	beqz	a0,80003326 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800032b8:	854a                	mv	a0,s2
    800032ba:	00001097          	auipc	ra,0x1
    800032be:	39a080e7          	jalr	922(ra) # 80004654 <releasesleep>

  acquire(&bcache.lock);
    800032c2:	0001c517          	auipc	a0,0x1c
    800032c6:	4be50513          	add	a0,a0,1214 # 8001f780 <bcache>
    800032ca:	ffffe097          	auipc	ra,0xffffe
    800032ce:	a1c080e7          	jalr	-1508(ra) # 80000ce6 <acquire>
  b->refcnt--;
    800032d2:	40bc                	lw	a5,64(s1)
    800032d4:	37fd                	addw	a5,a5,-1
    800032d6:	0007871b          	sext.w	a4,a5
    800032da:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032dc:	e71d                	bnez	a4,8000330a <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032de:	68b8                	ld	a4,80(s1)
    800032e0:	64bc                	ld	a5,72(s1)
    800032e2:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800032e4:	68b8                	ld	a4,80(s1)
    800032e6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032e8:	00024797          	auipc	a5,0x24
    800032ec:	49878793          	add	a5,a5,1176 # 80027780 <bcache+0x8000>
    800032f0:	2b87b703          	ld	a4,696(a5)
    800032f4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032f6:	00024717          	auipc	a4,0x24
    800032fa:	6f270713          	add	a4,a4,1778 # 800279e8 <bcache+0x8268>
    800032fe:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003300:	2b87b703          	ld	a4,696(a5)
    80003304:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003306:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000330a:	0001c517          	auipc	a0,0x1c
    8000330e:	47650513          	add	a0,a0,1142 # 8001f780 <bcache>
    80003312:	ffffe097          	auipc	ra,0xffffe
    80003316:	a88080e7          	jalr	-1400(ra) # 80000d9a <release>
}
    8000331a:	60e2                	ld	ra,24(sp)
    8000331c:	6442                	ld	s0,16(sp)
    8000331e:	64a2                	ld	s1,8(sp)
    80003320:	6902                	ld	s2,0(sp)
    80003322:	6105                	add	sp,sp,32
    80003324:	8082                	ret
    panic("brelse");
    80003326:	00005517          	auipc	a0,0x5
    8000332a:	1e250513          	add	a0,a0,482 # 80008508 <syscalls+0xe0>
    8000332e:	ffffd097          	auipc	ra,0xffffd
    80003332:	214080e7          	jalr	532(ra) # 80000542 <panic>

0000000080003336 <bpin>:

void
bpin(struct buf *b) {
    80003336:	1101                	add	sp,sp,-32
    80003338:	ec06                	sd	ra,24(sp)
    8000333a:	e822                	sd	s0,16(sp)
    8000333c:	e426                	sd	s1,8(sp)
    8000333e:	1000                	add	s0,sp,32
    80003340:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003342:	0001c517          	auipc	a0,0x1c
    80003346:	43e50513          	add	a0,a0,1086 # 8001f780 <bcache>
    8000334a:	ffffe097          	auipc	ra,0xffffe
    8000334e:	99c080e7          	jalr	-1636(ra) # 80000ce6 <acquire>
  b->refcnt++;
    80003352:	40bc                	lw	a5,64(s1)
    80003354:	2785                	addw	a5,a5,1
    80003356:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003358:	0001c517          	auipc	a0,0x1c
    8000335c:	42850513          	add	a0,a0,1064 # 8001f780 <bcache>
    80003360:	ffffe097          	auipc	ra,0xffffe
    80003364:	a3a080e7          	jalr	-1478(ra) # 80000d9a <release>
}
    80003368:	60e2                	ld	ra,24(sp)
    8000336a:	6442                	ld	s0,16(sp)
    8000336c:	64a2                	ld	s1,8(sp)
    8000336e:	6105                	add	sp,sp,32
    80003370:	8082                	ret

0000000080003372 <bunpin>:

void
bunpin(struct buf *b) {
    80003372:	1101                	add	sp,sp,-32
    80003374:	ec06                	sd	ra,24(sp)
    80003376:	e822                	sd	s0,16(sp)
    80003378:	e426                	sd	s1,8(sp)
    8000337a:	1000                	add	s0,sp,32
    8000337c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000337e:	0001c517          	auipc	a0,0x1c
    80003382:	40250513          	add	a0,a0,1026 # 8001f780 <bcache>
    80003386:	ffffe097          	auipc	ra,0xffffe
    8000338a:	960080e7          	jalr	-1696(ra) # 80000ce6 <acquire>
  b->refcnt--;
    8000338e:	40bc                	lw	a5,64(s1)
    80003390:	37fd                	addw	a5,a5,-1
    80003392:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003394:	0001c517          	auipc	a0,0x1c
    80003398:	3ec50513          	add	a0,a0,1004 # 8001f780 <bcache>
    8000339c:	ffffe097          	auipc	ra,0xffffe
    800033a0:	9fe080e7          	jalr	-1538(ra) # 80000d9a <release>
}
    800033a4:	60e2                	ld	ra,24(sp)
    800033a6:	6442                	ld	s0,16(sp)
    800033a8:	64a2                	ld	s1,8(sp)
    800033aa:	6105                	add	sp,sp,32
    800033ac:	8082                	ret

00000000800033ae <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033ae:	1101                	add	sp,sp,-32
    800033b0:	ec06                	sd	ra,24(sp)
    800033b2:	e822                	sd	s0,16(sp)
    800033b4:	e426                	sd	s1,8(sp)
    800033b6:	e04a                	sd	s2,0(sp)
    800033b8:	1000                	add	s0,sp,32
    800033ba:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033bc:	00d5d59b          	srlw	a1,a1,0xd
    800033c0:	00025797          	auipc	a5,0x25
    800033c4:	a9c7a783          	lw	a5,-1380(a5) # 80027e5c <sb+0x1c>
    800033c8:	9dbd                	addw	a1,a1,a5
    800033ca:	00000097          	auipc	ra,0x0
    800033ce:	da0080e7          	jalr	-608(ra) # 8000316a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033d2:	0074f713          	and	a4,s1,7
    800033d6:	4785                	li	a5,1
    800033d8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033dc:	14ce                	sll	s1,s1,0x33
    800033de:	90d9                	srl	s1,s1,0x36
    800033e0:	00950733          	add	a4,a0,s1
    800033e4:	05874703          	lbu	a4,88(a4)
    800033e8:	00e7f6b3          	and	a3,a5,a4
    800033ec:	c69d                	beqz	a3,8000341a <bfree+0x6c>
    800033ee:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033f0:	94aa                	add	s1,s1,a0
    800033f2:	fff7c793          	not	a5,a5
    800033f6:	8f7d                	and	a4,a4,a5
    800033f8:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800033fc:	00001097          	auipc	ra,0x1
    80003400:	0dc080e7          	jalr	220(ra) # 800044d8 <log_write>
  brelse(bp);
    80003404:	854a                	mv	a0,s2
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	e94080e7          	jalr	-364(ra) # 8000329a <brelse>
}
    8000340e:	60e2                	ld	ra,24(sp)
    80003410:	6442                	ld	s0,16(sp)
    80003412:	64a2                	ld	s1,8(sp)
    80003414:	6902                	ld	s2,0(sp)
    80003416:	6105                	add	sp,sp,32
    80003418:	8082                	ret
    panic("freeing free block");
    8000341a:	00005517          	auipc	a0,0x5
    8000341e:	0f650513          	add	a0,a0,246 # 80008510 <syscalls+0xe8>
    80003422:	ffffd097          	auipc	ra,0xffffd
    80003426:	120080e7          	jalr	288(ra) # 80000542 <panic>

000000008000342a <balloc>:
{
    8000342a:	711d                	add	sp,sp,-96
    8000342c:	ec86                	sd	ra,88(sp)
    8000342e:	e8a2                	sd	s0,80(sp)
    80003430:	e4a6                	sd	s1,72(sp)
    80003432:	e0ca                	sd	s2,64(sp)
    80003434:	fc4e                	sd	s3,56(sp)
    80003436:	f852                	sd	s4,48(sp)
    80003438:	f456                	sd	s5,40(sp)
    8000343a:	f05a                	sd	s6,32(sp)
    8000343c:	ec5e                	sd	s7,24(sp)
    8000343e:	e862                	sd	s8,16(sp)
    80003440:	e466                	sd	s9,8(sp)
    80003442:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003444:	00025797          	auipc	a5,0x25
    80003448:	a007a783          	lw	a5,-1536(a5) # 80027e44 <sb+0x4>
    8000344c:	cbc1                	beqz	a5,800034dc <balloc+0xb2>
    8000344e:	8baa                	mv	s7,a0
    80003450:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003452:	00025b17          	auipc	s6,0x25
    80003456:	9eeb0b13          	add	s6,s6,-1554 # 80027e40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000345a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000345c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000345e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003460:	6c89                	lui	s9,0x2
    80003462:	a831                	j	8000347e <balloc+0x54>
    brelse(bp);
    80003464:	854a                	mv	a0,s2
    80003466:	00000097          	auipc	ra,0x0
    8000346a:	e34080e7          	jalr	-460(ra) # 8000329a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000346e:	015c87bb          	addw	a5,s9,s5
    80003472:	00078a9b          	sext.w	s5,a5
    80003476:	004b2703          	lw	a4,4(s6)
    8000347a:	06eaf163          	bgeu	s5,a4,800034dc <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    8000347e:	41fad79b          	sraw	a5,s5,0x1f
    80003482:	0137d79b          	srlw	a5,a5,0x13
    80003486:	015787bb          	addw	a5,a5,s5
    8000348a:	40d7d79b          	sraw	a5,a5,0xd
    8000348e:	01cb2583          	lw	a1,28(s6)
    80003492:	9dbd                	addw	a1,a1,a5
    80003494:	855e                	mv	a0,s7
    80003496:	00000097          	auipc	ra,0x0
    8000349a:	cd4080e7          	jalr	-812(ra) # 8000316a <bread>
    8000349e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034a0:	004b2503          	lw	a0,4(s6)
    800034a4:	000a849b          	sext.w	s1,s5
    800034a8:	8762                	mv	a4,s8
    800034aa:	faa4fde3          	bgeu	s1,a0,80003464 <balloc+0x3a>
      m = 1 << (bi % 8);
    800034ae:	00777693          	and	a3,a4,7
    800034b2:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034b6:	41f7579b          	sraw	a5,a4,0x1f
    800034ba:	01d7d79b          	srlw	a5,a5,0x1d
    800034be:	9fb9                	addw	a5,a5,a4
    800034c0:	4037d79b          	sraw	a5,a5,0x3
    800034c4:	00f90633          	add	a2,s2,a5
    800034c8:	05864603          	lbu	a2,88(a2)
    800034cc:	00c6f5b3          	and	a1,a3,a2
    800034d0:	cd91                	beqz	a1,800034ec <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034d2:	2705                	addw	a4,a4,1
    800034d4:	2485                	addw	s1,s1,1
    800034d6:	fd471ae3          	bne	a4,s4,800034aa <balloc+0x80>
    800034da:	b769                	j	80003464 <balloc+0x3a>
  panic("balloc: out of blocks");
    800034dc:	00005517          	auipc	a0,0x5
    800034e0:	04c50513          	add	a0,a0,76 # 80008528 <syscalls+0x100>
    800034e4:	ffffd097          	auipc	ra,0xffffd
    800034e8:	05e080e7          	jalr	94(ra) # 80000542 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034ec:	97ca                	add	a5,a5,s2
    800034ee:	8e55                	or	a2,a2,a3
    800034f0:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800034f4:	854a                	mv	a0,s2
    800034f6:	00001097          	auipc	ra,0x1
    800034fa:	fe2080e7          	jalr	-30(ra) # 800044d8 <log_write>
        brelse(bp);
    800034fe:	854a                	mv	a0,s2
    80003500:	00000097          	auipc	ra,0x0
    80003504:	d9a080e7          	jalr	-614(ra) # 8000329a <brelse>
  bp = bread(dev, bno);
    80003508:	85a6                	mv	a1,s1
    8000350a:	855e                	mv	a0,s7
    8000350c:	00000097          	auipc	ra,0x0
    80003510:	c5e080e7          	jalr	-930(ra) # 8000316a <bread>
    80003514:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003516:	40000613          	li	a2,1024
    8000351a:	4581                	li	a1,0
    8000351c:	05850513          	add	a0,a0,88
    80003520:	ffffe097          	auipc	ra,0xffffe
    80003524:	8c2080e7          	jalr	-1854(ra) # 80000de2 <memset>
  log_write(bp);
    80003528:	854a                	mv	a0,s2
    8000352a:	00001097          	auipc	ra,0x1
    8000352e:	fae080e7          	jalr	-82(ra) # 800044d8 <log_write>
  brelse(bp);
    80003532:	854a                	mv	a0,s2
    80003534:	00000097          	auipc	ra,0x0
    80003538:	d66080e7          	jalr	-666(ra) # 8000329a <brelse>
}
    8000353c:	8526                	mv	a0,s1
    8000353e:	60e6                	ld	ra,88(sp)
    80003540:	6446                	ld	s0,80(sp)
    80003542:	64a6                	ld	s1,72(sp)
    80003544:	6906                	ld	s2,64(sp)
    80003546:	79e2                	ld	s3,56(sp)
    80003548:	7a42                	ld	s4,48(sp)
    8000354a:	7aa2                	ld	s5,40(sp)
    8000354c:	7b02                	ld	s6,32(sp)
    8000354e:	6be2                	ld	s7,24(sp)
    80003550:	6c42                	ld	s8,16(sp)
    80003552:	6ca2                	ld	s9,8(sp)
    80003554:	6125                	add	sp,sp,96
    80003556:	8082                	ret

0000000080003558 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003558:	7179                	add	sp,sp,-48
    8000355a:	f406                	sd	ra,40(sp)
    8000355c:	f022                	sd	s0,32(sp)
    8000355e:	ec26                	sd	s1,24(sp)
    80003560:	e84a                	sd	s2,16(sp)
    80003562:	e44e                	sd	s3,8(sp)
    80003564:	e052                	sd	s4,0(sp)
    80003566:	1800                	add	s0,sp,48
    80003568:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000356a:	47ad                	li	a5,11
    8000356c:	04b7fe63          	bgeu	a5,a1,800035c8 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003570:	ff45849b          	addw	s1,a1,-12
    80003574:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003578:	0ff00793          	li	a5,255
    8000357c:	0ae7e463          	bltu	a5,a4,80003624 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003580:	08052583          	lw	a1,128(a0)
    80003584:	c5b5                	beqz	a1,800035f0 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003586:	00092503          	lw	a0,0(s2)
    8000358a:	00000097          	auipc	ra,0x0
    8000358e:	be0080e7          	jalr	-1056(ra) # 8000316a <bread>
    80003592:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003594:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    80003598:	02049713          	sll	a4,s1,0x20
    8000359c:	01e75593          	srl	a1,a4,0x1e
    800035a0:	00b784b3          	add	s1,a5,a1
    800035a4:	0004a983          	lw	s3,0(s1)
    800035a8:	04098e63          	beqz	s3,80003604 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035ac:	8552                	mv	a0,s4
    800035ae:	00000097          	auipc	ra,0x0
    800035b2:	cec080e7          	jalr	-788(ra) # 8000329a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035b6:	854e                	mv	a0,s3
    800035b8:	70a2                	ld	ra,40(sp)
    800035ba:	7402                	ld	s0,32(sp)
    800035bc:	64e2                	ld	s1,24(sp)
    800035be:	6942                	ld	s2,16(sp)
    800035c0:	69a2                	ld	s3,8(sp)
    800035c2:	6a02                	ld	s4,0(sp)
    800035c4:	6145                	add	sp,sp,48
    800035c6:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035c8:	02059793          	sll	a5,a1,0x20
    800035cc:	01e7d593          	srl	a1,a5,0x1e
    800035d0:	00b504b3          	add	s1,a0,a1
    800035d4:	0504a983          	lw	s3,80(s1)
    800035d8:	fc099fe3          	bnez	s3,800035b6 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035dc:	4108                	lw	a0,0(a0)
    800035de:	00000097          	auipc	ra,0x0
    800035e2:	e4c080e7          	jalr	-436(ra) # 8000342a <balloc>
    800035e6:	0005099b          	sext.w	s3,a0
    800035ea:	0534a823          	sw	s3,80(s1)
    800035ee:	b7e1                	j	800035b6 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035f0:	4108                	lw	a0,0(a0)
    800035f2:	00000097          	auipc	ra,0x0
    800035f6:	e38080e7          	jalr	-456(ra) # 8000342a <balloc>
    800035fa:	0005059b          	sext.w	a1,a0
    800035fe:	08b92023          	sw	a1,128(s2)
    80003602:	b751                	j	80003586 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003604:	00092503          	lw	a0,0(s2)
    80003608:	00000097          	auipc	ra,0x0
    8000360c:	e22080e7          	jalr	-478(ra) # 8000342a <balloc>
    80003610:	0005099b          	sext.w	s3,a0
    80003614:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003618:	8552                	mv	a0,s4
    8000361a:	00001097          	auipc	ra,0x1
    8000361e:	ebe080e7          	jalr	-322(ra) # 800044d8 <log_write>
    80003622:	b769                	j	800035ac <bmap+0x54>
  panic("bmap: out of range");
    80003624:	00005517          	auipc	a0,0x5
    80003628:	f1c50513          	add	a0,a0,-228 # 80008540 <syscalls+0x118>
    8000362c:	ffffd097          	auipc	ra,0xffffd
    80003630:	f16080e7          	jalr	-234(ra) # 80000542 <panic>

0000000080003634 <iget>:
{
    80003634:	7179                	add	sp,sp,-48
    80003636:	f406                	sd	ra,40(sp)
    80003638:	f022                	sd	s0,32(sp)
    8000363a:	ec26                	sd	s1,24(sp)
    8000363c:	e84a                	sd	s2,16(sp)
    8000363e:	e44e                	sd	s3,8(sp)
    80003640:	e052                	sd	s4,0(sp)
    80003642:	1800                	add	s0,sp,48
    80003644:	89aa                	mv	s3,a0
    80003646:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003648:	00025517          	auipc	a0,0x25
    8000364c:	81850513          	add	a0,a0,-2024 # 80027e60 <icache>
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	696080e7          	jalr	1686(ra) # 80000ce6 <acquire>
  empty = 0;
    80003658:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000365a:	00025497          	auipc	s1,0x25
    8000365e:	81e48493          	add	s1,s1,-2018 # 80027e78 <icache+0x18>
    80003662:	00026697          	auipc	a3,0x26
    80003666:	2a668693          	add	a3,a3,678 # 80029908 <log>
    8000366a:	a039                	j	80003678 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000366c:	02090b63          	beqz	s2,800036a2 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003670:	08848493          	add	s1,s1,136
    80003674:	02d48a63          	beq	s1,a3,800036a8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003678:	449c                	lw	a5,8(s1)
    8000367a:	fef059e3          	blez	a5,8000366c <iget+0x38>
    8000367e:	4098                	lw	a4,0(s1)
    80003680:	ff3716e3          	bne	a4,s3,8000366c <iget+0x38>
    80003684:	40d8                	lw	a4,4(s1)
    80003686:	ff4713e3          	bne	a4,s4,8000366c <iget+0x38>
      ip->ref++;
    8000368a:	2785                	addw	a5,a5,1
    8000368c:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    8000368e:	00024517          	auipc	a0,0x24
    80003692:	7d250513          	add	a0,a0,2002 # 80027e60 <icache>
    80003696:	ffffd097          	auipc	ra,0xffffd
    8000369a:	704080e7          	jalr	1796(ra) # 80000d9a <release>
      return ip;
    8000369e:	8926                	mv	s2,s1
    800036a0:	a03d                	j	800036ce <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036a2:	f7f9                	bnez	a5,80003670 <iget+0x3c>
    800036a4:	8926                	mv	s2,s1
    800036a6:	b7e9                	j	80003670 <iget+0x3c>
  if(empty == 0)
    800036a8:	02090c63          	beqz	s2,800036e0 <iget+0xac>
  ip->dev = dev;
    800036ac:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036b0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036b4:	4785                	li	a5,1
    800036b6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036ba:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800036be:	00024517          	auipc	a0,0x24
    800036c2:	7a250513          	add	a0,a0,1954 # 80027e60 <icache>
    800036c6:	ffffd097          	auipc	ra,0xffffd
    800036ca:	6d4080e7          	jalr	1748(ra) # 80000d9a <release>
}
    800036ce:	854a                	mv	a0,s2
    800036d0:	70a2                	ld	ra,40(sp)
    800036d2:	7402                	ld	s0,32(sp)
    800036d4:	64e2                	ld	s1,24(sp)
    800036d6:	6942                	ld	s2,16(sp)
    800036d8:	69a2                	ld	s3,8(sp)
    800036da:	6a02                	ld	s4,0(sp)
    800036dc:	6145                	add	sp,sp,48
    800036de:	8082                	ret
    panic("iget: no inodes");
    800036e0:	00005517          	auipc	a0,0x5
    800036e4:	e7850513          	add	a0,a0,-392 # 80008558 <syscalls+0x130>
    800036e8:	ffffd097          	auipc	ra,0xffffd
    800036ec:	e5a080e7          	jalr	-422(ra) # 80000542 <panic>

00000000800036f0 <fsinit>:
fsinit(int dev) {
    800036f0:	7179                	add	sp,sp,-48
    800036f2:	f406                	sd	ra,40(sp)
    800036f4:	f022                	sd	s0,32(sp)
    800036f6:	ec26                	sd	s1,24(sp)
    800036f8:	e84a                	sd	s2,16(sp)
    800036fa:	e44e                	sd	s3,8(sp)
    800036fc:	1800                	add	s0,sp,48
    800036fe:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003700:	4585                	li	a1,1
    80003702:	00000097          	auipc	ra,0x0
    80003706:	a68080e7          	jalr	-1432(ra) # 8000316a <bread>
    8000370a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000370c:	00024997          	auipc	s3,0x24
    80003710:	73498993          	add	s3,s3,1844 # 80027e40 <sb>
    80003714:	02000613          	li	a2,32
    80003718:	05850593          	add	a1,a0,88
    8000371c:	854e                	mv	a0,s3
    8000371e:	ffffd097          	auipc	ra,0xffffd
    80003722:	720080e7          	jalr	1824(ra) # 80000e3e <memmove>
  brelse(bp);
    80003726:	8526                	mv	a0,s1
    80003728:	00000097          	auipc	ra,0x0
    8000372c:	b72080e7          	jalr	-1166(ra) # 8000329a <brelse>
  if(sb.magic != FSMAGIC)
    80003730:	0009a703          	lw	a4,0(s3)
    80003734:	102037b7          	lui	a5,0x10203
    80003738:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000373c:	02f71263          	bne	a4,a5,80003760 <fsinit+0x70>
  initlog(dev, &sb);
    80003740:	00024597          	auipc	a1,0x24
    80003744:	70058593          	add	a1,a1,1792 # 80027e40 <sb>
    80003748:	854a                	mv	a0,s2
    8000374a:	00001097          	auipc	ra,0x1
    8000374e:	b28080e7          	jalr	-1240(ra) # 80004272 <initlog>
}
    80003752:	70a2                	ld	ra,40(sp)
    80003754:	7402                	ld	s0,32(sp)
    80003756:	64e2                	ld	s1,24(sp)
    80003758:	6942                	ld	s2,16(sp)
    8000375a:	69a2                	ld	s3,8(sp)
    8000375c:	6145                	add	sp,sp,48
    8000375e:	8082                	ret
    panic("invalid file system");
    80003760:	00005517          	auipc	a0,0x5
    80003764:	e0850513          	add	a0,a0,-504 # 80008568 <syscalls+0x140>
    80003768:	ffffd097          	auipc	ra,0xffffd
    8000376c:	dda080e7          	jalr	-550(ra) # 80000542 <panic>

0000000080003770 <iinit>:
{
    80003770:	7179                	add	sp,sp,-48
    80003772:	f406                	sd	ra,40(sp)
    80003774:	f022                	sd	s0,32(sp)
    80003776:	ec26                	sd	s1,24(sp)
    80003778:	e84a                	sd	s2,16(sp)
    8000377a:	e44e                	sd	s3,8(sp)
    8000377c:	1800                	add	s0,sp,48
  initlock(&icache.lock, "icache");
    8000377e:	00005597          	auipc	a1,0x5
    80003782:	e0258593          	add	a1,a1,-510 # 80008580 <syscalls+0x158>
    80003786:	00024517          	auipc	a0,0x24
    8000378a:	6da50513          	add	a0,a0,1754 # 80027e60 <icache>
    8000378e:	ffffd097          	auipc	ra,0xffffd
    80003792:	4c8080e7          	jalr	1224(ra) # 80000c56 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003796:	00024497          	auipc	s1,0x24
    8000379a:	6f248493          	add	s1,s1,1778 # 80027e88 <icache+0x28>
    8000379e:	00026997          	auipc	s3,0x26
    800037a2:	17a98993          	add	s3,s3,378 # 80029918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800037a6:	00005917          	auipc	s2,0x5
    800037aa:	de290913          	add	s2,s2,-542 # 80008588 <syscalls+0x160>
    800037ae:	85ca                	mv	a1,s2
    800037b0:	8526                	mv	a0,s1
    800037b2:	00001097          	auipc	ra,0x1
    800037b6:	e12080e7          	jalr	-494(ra) # 800045c4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037ba:	08848493          	add	s1,s1,136
    800037be:	ff3498e3          	bne	s1,s3,800037ae <iinit+0x3e>
}
    800037c2:	70a2                	ld	ra,40(sp)
    800037c4:	7402                	ld	s0,32(sp)
    800037c6:	64e2                	ld	s1,24(sp)
    800037c8:	6942                	ld	s2,16(sp)
    800037ca:	69a2                	ld	s3,8(sp)
    800037cc:	6145                	add	sp,sp,48
    800037ce:	8082                	ret

00000000800037d0 <ialloc>:
{
    800037d0:	7139                	add	sp,sp,-64
    800037d2:	fc06                	sd	ra,56(sp)
    800037d4:	f822                	sd	s0,48(sp)
    800037d6:	f426                	sd	s1,40(sp)
    800037d8:	f04a                	sd	s2,32(sp)
    800037da:	ec4e                	sd	s3,24(sp)
    800037dc:	e852                	sd	s4,16(sp)
    800037de:	e456                	sd	s5,8(sp)
    800037e0:	e05a                	sd	s6,0(sp)
    800037e2:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800037e4:	00024717          	auipc	a4,0x24
    800037e8:	66872703          	lw	a4,1640(a4) # 80027e4c <sb+0xc>
    800037ec:	4785                	li	a5,1
    800037ee:	04e7f863          	bgeu	a5,a4,8000383e <ialloc+0x6e>
    800037f2:	8aaa                	mv	s5,a0
    800037f4:	8b2e                	mv	s6,a1
    800037f6:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037f8:	00024a17          	auipc	s4,0x24
    800037fc:	648a0a13          	add	s4,s4,1608 # 80027e40 <sb>
    80003800:	00495593          	srl	a1,s2,0x4
    80003804:	018a2783          	lw	a5,24(s4)
    80003808:	9dbd                	addw	a1,a1,a5
    8000380a:	8556                	mv	a0,s5
    8000380c:	00000097          	auipc	ra,0x0
    80003810:	95e080e7          	jalr	-1698(ra) # 8000316a <bread>
    80003814:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003816:	05850993          	add	s3,a0,88
    8000381a:	00f97793          	and	a5,s2,15
    8000381e:	079a                	sll	a5,a5,0x6
    80003820:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003822:	00099783          	lh	a5,0(s3)
    80003826:	c785                	beqz	a5,8000384e <ialloc+0x7e>
    brelse(bp);
    80003828:	00000097          	auipc	ra,0x0
    8000382c:	a72080e7          	jalr	-1422(ra) # 8000329a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003830:	0905                	add	s2,s2,1
    80003832:	00ca2703          	lw	a4,12(s4)
    80003836:	0009079b          	sext.w	a5,s2
    8000383a:	fce7e3e3          	bltu	a5,a4,80003800 <ialloc+0x30>
  panic("ialloc: no inodes");
    8000383e:	00005517          	auipc	a0,0x5
    80003842:	d5250513          	add	a0,a0,-686 # 80008590 <syscalls+0x168>
    80003846:	ffffd097          	auipc	ra,0xffffd
    8000384a:	cfc080e7          	jalr	-772(ra) # 80000542 <panic>
      memset(dip, 0, sizeof(*dip));
    8000384e:	04000613          	li	a2,64
    80003852:	4581                	li	a1,0
    80003854:	854e                	mv	a0,s3
    80003856:	ffffd097          	auipc	ra,0xffffd
    8000385a:	58c080e7          	jalr	1420(ra) # 80000de2 <memset>
      dip->type = type;
    8000385e:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003862:	8526                	mv	a0,s1
    80003864:	00001097          	auipc	ra,0x1
    80003868:	c74080e7          	jalr	-908(ra) # 800044d8 <log_write>
      brelse(bp);
    8000386c:	8526                	mv	a0,s1
    8000386e:	00000097          	auipc	ra,0x0
    80003872:	a2c080e7          	jalr	-1492(ra) # 8000329a <brelse>
      return iget(dev, inum);
    80003876:	0009059b          	sext.w	a1,s2
    8000387a:	8556                	mv	a0,s5
    8000387c:	00000097          	auipc	ra,0x0
    80003880:	db8080e7          	jalr	-584(ra) # 80003634 <iget>
}
    80003884:	70e2                	ld	ra,56(sp)
    80003886:	7442                	ld	s0,48(sp)
    80003888:	74a2                	ld	s1,40(sp)
    8000388a:	7902                	ld	s2,32(sp)
    8000388c:	69e2                	ld	s3,24(sp)
    8000388e:	6a42                	ld	s4,16(sp)
    80003890:	6aa2                	ld	s5,8(sp)
    80003892:	6b02                	ld	s6,0(sp)
    80003894:	6121                	add	sp,sp,64
    80003896:	8082                	ret

0000000080003898 <iupdate>:
{
    80003898:	1101                	add	sp,sp,-32
    8000389a:	ec06                	sd	ra,24(sp)
    8000389c:	e822                	sd	s0,16(sp)
    8000389e:	e426                	sd	s1,8(sp)
    800038a0:	e04a                	sd	s2,0(sp)
    800038a2:	1000                	add	s0,sp,32
    800038a4:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038a6:	415c                	lw	a5,4(a0)
    800038a8:	0047d79b          	srlw	a5,a5,0x4
    800038ac:	00024597          	auipc	a1,0x24
    800038b0:	5ac5a583          	lw	a1,1452(a1) # 80027e58 <sb+0x18>
    800038b4:	9dbd                	addw	a1,a1,a5
    800038b6:	4108                	lw	a0,0(a0)
    800038b8:	00000097          	auipc	ra,0x0
    800038bc:	8b2080e7          	jalr	-1870(ra) # 8000316a <bread>
    800038c0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038c2:	05850793          	add	a5,a0,88
    800038c6:	40d8                	lw	a4,4(s1)
    800038c8:	8b3d                	and	a4,a4,15
    800038ca:	071a                	sll	a4,a4,0x6
    800038cc:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800038ce:	04449703          	lh	a4,68(s1)
    800038d2:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800038d6:	04649703          	lh	a4,70(s1)
    800038da:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800038de:	04849703          	lh	a4,72(s1)
    800038e2:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800038e6:	04a49703          	lh	a4,74(s1)
    800038ea:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800038ee:	44f8                	lw	a4,76(s1)
    800038f0:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038f2:	03400613          	li	a2,52
    800038f6:	05048593          	add	a1,s1,80
    800038fa:	00c78513          	add	a0,a5,12
    800038fe:	ffffd097          	auipc	ra,0xffffd
    80003902:	540080e7          	jalr	1344(ra) # 80000e3e <memmove>
  log_write(bp);
    80003906:	854a                	mv	a0,s2
    80003908:	00001097          	auipc	ra,0x1
    8000390c:	bd0080e7          	jalr	-1072(ra) # 800044d8 <log_write>
  brelse(bp);
    80003910:	854a                	mv	a0,s2
    80003912:	00000097          	auipc	ra,0x0
    80003916:	988080e7          	jalr	-1656(ra) # 8000329a <brelse>
}
    8000391a:	60e2                	ld	ra,24(sp)
    8000391c:	6442                	ld	s0,16(sp)
    8000391e:	64a2                	ld	s1,8(sp)
    80003920:	6902                	ld	s2,0(sp)
    80003922:	6105                	add	sp,sp,32
    80003924:	8082                	ret

0000000080003926 <idup>:
{
    80003926:	1101                	add	sp,sp,-32
    80003928:	ec06                	sd	ra,24(sp)
    8000392a:	e822                	sd	s0,16(sp)
    8000392c:	e426                	sd	s1,8(sp)
    8000392e:	1000                	add	s0,sp,32
    80003930:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003932:	00024517          	auipc	a0,0x24
    80003936:	52e50513          	add	a0,a0,1326 # 80027e60 <icache>
    8000393a:	ffffd097          	auipc	ra,0xffffd
    8000393e:	3ac080e7          	jalr	940(ra) # 80000ce6 <acquire>
  ip->ref++;
    80003942:	449c                	lw	a5,8(s1)
    80003944:	2785                	addw	a5,a5,1
    80003946:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003948:	00024517          	auipc	a0,0x24
    8000394c:	51850513          	add	a0,a0,1304 # 80027e60 <icache>
    80003950:	ffffd097          	auipc	ra,0xffffd
    80003954:	44a080e7          	jalr	1098(ra) # 80000d9a <release>
}
    80003958:	8526                	mv	a0,s1
    8000395a:	60e2                	ld	ra,24(sp)
    8000395c:	6442                	ld	s0,16(sp)
    8000395e:	64a2                	ld	s1,8(sp)
    80003960:	6105                	add	sp,sp,32
    80003962:	8082                	ret

0000000080003964 <ilock>:
{
    80003964:	1101                	add	sp,sp,-32
    80003966:	ec06                	sd	ra,24(sp)
    80003968:	e822                	sd	s0,16(sp)
    8000396a:	e426                	sd	s1,8(sp)
    8000396c:	e04a                	sd	s2,0(sp)
    8000396e:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003970:	c115                	beqz	a0,80003994 <ilock+0x30>
    80003972:	84aa                	mv	s1,a0
    80003974:	451c                	lw	a5,8(a0)
    80003976:	00f05f63          	blez	a5,80003994 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000397a:	0541                	add	a0,a0,16
    8000397c:	00001097          	auipc	ra,0x1
    80003980:	c82080e7          	jalr	-894(ra) # 800045fe <acquiresleep>
  if(ip->valid == 0){
    80003984:	40bc                	lw	a5,64(s1)
    80003986:	cf99                	beqz	a5,800039a4 <ilock+0x40>
}
    80003988:	60e2                	ld	ra,24(sp)
    8000398a:	6442                	ld	s0,16(sp)
    8000398c:	64a2                	ld	s1,8(sp)
    8000398e:	6902                	ld	s2,0(sp)
    80003990:	6105                	add	sp,sp,32
    80003992:	8082                	ret
    panic("ilock");
    80003994:	00005517          	auipc	a0,0x5
    80003998:	c1450513          	add	a0,a0,-1004 # 800085a8 <syscalls+0x180>
    8000399c:	ffffd097          	auipc	ra,0xffffd
    800039a0:	ba6080e7          	jalr	-1114(ra) # 80000542 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039a4:	40dc                	lw	a5,4(s1)
    800039a6:	0047d79b          	srlw	a5,a5,0x4
    800039aa:	00024597          	auipc	a1,0x24
    800039ae:	4ae5a583          	lw	a1,1198(a1) # 80027e58 <sb+0x18>
    800039b2:	9dbd                	addw	a1,a1,a5
    800039b4:	4088                	lw	a0,0(s1)
    800039b6:	fffff097          	auipc	ra,0xfffff
    800039ba:	7b4080e7          	jalr	1972(ra) # 8000316a <bread>
    800039be:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039c0:	05850593          	add	a1,a0,88
    800039c4:	40dc                	lw	a5,4(s1)
    800039c6:	8bbd                	and	a5,a5,15
    800039c8:	079a                	sll	a5,a5,0x6
    800039ca:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039cc:	00059783          	lh	a5,0(a1)
    800039d0:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039d4:	00259783          	lh	a5,2(a1)
    800039d8:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039dc:	00459783          	lh	a5,4(a1)
    800039e0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039e4:	00659783          	lh	a5,6(a1)
    800039e8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039ec:	459c                	lw	a5,8(a1)
    800039ee:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039f0:	03400613          	li	a2,52
    800039f4:	05b1                	add	a1,a1,12
    800039f6:	05048513          	add	a0,s1,80
    800039fa:	ffffd097          	auipc	ra,0xffffd
    800039fe:	444080e7          	jalr	1092(ra) # 80000e3e <memmove>
    brelse(bp);
    80003a02:	854a                	mv	a0,s2
    80003a04:	00000097          	auipc	ra,0x0
    80003a08:	896080e7          	jalr	-1898(ra) # 8000329a <brelse>
    ip->valid = 1;
    80003a0c:	4785                	li	a5,1
    80003a0e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a10:	04449783          	lh	a5,68(s1)
    80003a14:	fbb5                	bnez	a5,80003988 <ilock+0x24>
      panic("ilock: no type");
    80003a16:	00005517          	auipc	a0,0x5
    80003a1a:	b9a50513          	add	a0,a0,-1126 # 800085b0 <syscalls+0x188>
    80003a1e:	ffffd097          	auipc	ra,0xffffd
    80003a22:	b24080e7          	jalr	-1244(ra) # 80000542 <panic>

0000000080003a26 <iunlock>:
{
    80003a26:	1101                	add	sp,sp,-32
    80003a28:	ec06                	sd	ra,24(sp)
    80003a2a:	e822                	sd	s0,16(sp)
    80003a2c:	e426                	sd	s1,8(sp)
    80003a2e:	e04a                	sd	s2,0(sp)
    80003a30:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a32:	c905                	beqz	a0,80003a62 <iunlock+0x3c>
    80003a34:	84aa                	mv	s1,a0
    80003a36:	01050913          	add	s2,a0,16
    80003a3a:	854a                	mv	a0,s2
    80003a3c:	00001097          	auipc	ra,0x1
    80003a40:	c5c080e7          	jalr	-932(ra) # 80004698 <holdingsleep>
    80003a44:	cd19                	beqz	a0,80003a62 <iunlock+0x3c>
    80003a46:	449c                	lw	a5,8(s1)
    80003a48:	00f05d63          	blez	a5,80003a62 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a4c:	854a                	mv	a0,s2
    80003a4e:	00001097          	auipc	ra,0x1
    80003a52:	c06080e7          	jalr	-1018(ra) # 80004654 <releasesleep>
}
    80003a56:	60e2                	ld	ra,24(sp)
    80003a58:	6442                	ld	s0,16(sp)
    80003a5a:	64a2                	ld	s1,8(sp)
    80003a5c:	6902                	ld	s2,0(sp)
    80003a5e:	6105                	add	sp,sp,32
    80003a60:	8082                	ret
    panic("iunlock");
    80003a62:	00005517          	auipc	a0,0x5
    80003a66:	b5e50513          	add	a0,a0,-1186 # 800085c0 <syscalls+0x198>
    80003a6a:	ffffd097          	auipc	ra,0xffffd
    80003a6e:	ad8080e7          	jalr	-1320(ra) # 80000542 <panic>

0000000080003a72 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a72:	7179                	add	sp,sp,-48
    80003a74:	f406                	sd	ra,40(sp)
    80003a76:	f022                	sd	s0,32(sp)
    80003a78:	ec26                	sd	s1,24(sp)
    80003a7a:	e84a                	sd	s2,16(sp)
    80003a7c:	e44e                	sd	s3,8(sp)
    80003a7e:	e052                	sd	s4,0(sp)
    80003a80:	1800                	add	s0,sp,48
    80003a82:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a84:	05050493          	add	s1,a0,80
    80003a88:	08050913          	add	s2,a0,128
    80003a8c:	a021                	j	80003a94 <itrunc+0x22>
    80003a8e:	0491                	add	s1,s1,4
    80003a90:	01248d63          	beq	s1,s2,80003aaa <itrunc+0x38>
    if(ip->addrs[i]){
    80003a94:	408c                	lw	a1,0(s1)
    80003a96:	dde5                	beqz	a1,80003a8e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a98:	0009a503          	lw	a0,0(s3)
    80003a9c:	00000097          	auipc	ra,0x0
    80003aa0:	912080e7          	jalr	-1774(ra) # 800033ae <bfree>
      ip->addrs[i] = 0;
    80003aa4:	0004a023          	sw	zero,0(s1)
    80003aa8:	b7dd                	j	80003a8e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003aaa:	0809a583          	lw	a1,128(s3)
    80003aae:	e185                	bnez	a1,80003ace <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ab0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ab4:	854e                	mv	a0,s3
    80003ab6:	00000097          	auipc	ra,0x0
    80003aba:	de2080e7          	jalr	-542(ra) # 80003898 <iupdate>
}
    80003abe:	70a2                	ld	ra,40(sp)
    80003ac0:	7402                	ld	s0,32(sp)
    80003ac2:	64e2                	ld	s1,24(sp)
    80003ac4:	6942                	ld	s2,16(sp)
    80003ac6:	69a2                	ld	s3,8(sp)
    80003ac8:	6a02                	ld	s4,0(sp)
    80003aca:	6145                	add	sp,sp,48
    80003acc:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ace:	0009a503          	lw	a0,0(s3)
    80003ad2:	fffff097          	auipc	ra,0xfffff
    80003ad6:	698080e7          	jalr	1688(ra) # 8000316a <bread>
    80003ada:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003adc:	05850493          	add	s1,a0,88
    80003ae0:	45850913          	add	s2,a0,1112
    80003ae4:	a021                	j	80003aec <itrunc+0x7a>
    80003ae6:	0491                	add	s1,s1,4
    80003ae8:	01248b63          	beq	s1,s2,80003afe <itrunc+0x8c>
      if(a[j])
    80003aec:	408c                	lw	a1,0(s1)
    80003aee:	dde5                	beqz	a1,80003ae6 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003af0:	0009a503          	lw	a0,0(s3)
    80003af4:	00000097          	auipc	ra,0x0
    80003af8:	8ba080e7          	jalr	-1862(ra) # 800033ae <bfree>
    80003afc:	b7ed                	j	80003ae6 <itrunc+0x74>
    brelse(bp);
    80003afe:	8552                	mv	a0,s4
    80003b00:	fffff097          	auipc	ra,0xfffff
    80003b04:	79a080e7          	jalr	1946(ra) # 8000329a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b08:	0809a583          	lw	a1,128(s3)
    80003b0c:	0009a503          	lw	a0,0(s3)
    80003b10:	00000097          	auipc	ra,0x0
    80003b14:	89e080e7          	jalr	-1890(ra) # 800033ae <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b18:	0809a023          	sw	zero,128(s3)
    80003b1c:	bf51                	j	80003ab0 <itrunc+0x3e>

0000000080003b1e <iput>:
{
    80003b1e:	1101                	add	sp,sp,-32
    80003b20:	ec06                	sd	ra,24(sp)
    80003b22:	e822                	sd	s0,16(sp)
    80003b24:	e426                	sd	s1,8(sp)
    80003b26:	e04a                	sd	s2,0(sp)
    80003b28:	1000                	add	s0,sp,32
    80003b2a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b2c:	00024517          	auipc	a0,0x24
    80003b30:	33450513          	add	a0,a0,820 # 80027e60 <icache>
    80003b34:	ffffd097          	auipc	ra,0xffffd
    80003b38:	1b2080e7          	jalr	434(ra) # 80000ce6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b3c:	4498                	lw	a4,8(s1)
    80003b3e:	4785                	li	a5,1
    80003b40:	02f70363          	beq	a4,a5,80003b66 <iput+0x48>
  ip->ref--;
    80003b44:	449c                	lw	a5,8(s1)
    80003b46:	37fd                	addw	a5,a5,-1
    80003b48:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b4a:	00024517          	auipc	a0,0x24
    80003b4e:	31650513          	add	a0,a0,790 # 80027e60 <icache>
    80003b52:	ffffd097          	auipc	ra,0xffffd
    80003b56:	248080e7          	jalr	584(ra) # 80000d9a <release>
}
    80003b5a:	60e2                	ld	ra,24(sp)
    80003b5c:	6442                	ld	s0,16(sp)
    80003b5e:	64a2                	ld	s1,8(sp)
    80003b60:	6902                	ld	s2,0(sp)
    80003b62:	6105                	add	sp,sp,32
    80003b64:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b66:	40bc                	lw	a5,64(s1)
    80003b68:	dff1                	beqz	a5,80003b44 <iput+0x26>
    80003b6a:	04a49783          	lh	a5,74(s1)
    80003b6e:	fbf9                	bnez	a5,80003b44 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b70:	01048913          	add	s2,s1,16
    80003b74:	854a                	mv	a0,s2
    80003b76:	00001097          	auipc	ra,0x1
    80003b7a:	a88080e7          	jalr	-1400(ra) # 800045fe <acquiresleep>
    release(&icache.lock);
    80003b7e:	00024517          	auipc	a0,0x24
    80003b82:	2e250513          	add	a0,a0,738 # 80027e60 <icache>
    80003b86:	ffffd097          	auipc	ra,0xffffd
    80003b8a:	214080e7          	jalr	532(ra) # 80000d9a <release>
    itrunc(ip);
    80003b8e:	8526                	mv	a0,s1
    80003b90:	00000097          	auipc	ra,0x0
    80003b94:	ee2080e7          	jalr	-286(ra) # 80003a72 <itrunc>
    ip->type = 0;
    80003b98:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b9c:	8526                	mv	a0,s1
    80003b9e:	00000097          	auipc	ra,0x0
    80003ba2:	cfa080e7          	jalr	-774(ra) # 80003898 <iupdate>
    ip->valid = 0;
    80003ba6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003baa:	854a                	mv	a0,s2
    80003bac:	00001097          	auipc	ra,0x1
    80003bb0:	aa8080e7          	jalr	-1368(ra) # 80004654 <releasesleep>
    acquire(&icache.lock);
    80003bb4:	00024517          	auipc	a0,0x24
    80003bb8:	2ac50513          	add	a0,a0,684 # 80027e60 <icache>
    80003bbc:	ffffd097          	auipc	ra,0xffffd
    80003bc0:	12a080e7          	jalr	298(ra) # 80000ce6 <acquire>
    80003bc4:	b741                	j	80003b44 <iput+0x26>

0000000080003bc6 <iunlockput>:
{
    80003bc6:	1101                	add	sp,sp,-32
    80003bc8:	ec06                	sd	ra,24(sp)
    80003bca:	e822                	sd	s0,16(sp)
    80003bcc:	e426                	sd	s1,8(sp)
    80003bce:	1000                	add	s0,sp,32
    80003bd0:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bd2:	00000097          	auipc	ra,0x0
    80003bd6:	e54080e7          	jalr	-428(ra) # 80003a26 <iunlock>
  iput(ip);
    80003bda:	8526                	mv	a0,s1
    80003bdc:	00000097          	auipc	ra,0x0
    80003be0:	f42080e7          	jalr	-190(ra) # 80003b1e <iput>
}
    80003be4:	60e2                	ld	ra,24(sp)
    80003be6:	6442                	ld	s0,16(sp)
    80003be8:	64a2                	ld	s1,8(sp)
    80003bea:	6105                	add	sp,sp,32
    80003bec:	8082                	ret

0000000080003bee <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bee:	1141                	add	sp,sp,-16
    80003bf0:	e422                	sd	s0,8(sp)
    80003bf2:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    80003bf4:	411c                	lw	a5,0(a0)
    80003bf6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003bf8:	415c                	lw	a5,4(a0)
    80003bfa:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003bfc:	04451783          	lh	a5,68(a0)
    80003c00:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c04:	04a51783          	lh	a5,74(a0)
    80003c08:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c0c:	04c56783          	lwu	a5,76(a0)
    80003c10:	e99c                	sd	a5,16(a1)
}
    80003c12:	6422                	ld	s0,8(sp)
    80003c14:	0141                	add	sp,sp,16
    80003c16:	8082                	ret

0000000080003c18 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c18:	457c                	lw	a5,76(a0)
    80003c1a:	0ed7e963          	bltu	a5,a3,80003d0c <readi+0xf4>
{
    80003c1e:	7159                	add	sp,sp,-112
    80003c20:	f486                	sd	ra,104(sp)
    80003c22:	f0a2                	sd	s0,96(sp)
    80003c24:	eca6                	sd	s1,88(sp)
    80003c26:	e8ca                	sd	s2,80(sp)
    80003c28:	e4ce                	sd	s3,72(sp)
    80003c2a:	e0d2                	sd	s4,64(sp)
    80003c2c:	fc56                	sd	s5,56(sp)
    80003c2e:	f85a                	sd	s6,48(sp)
    80003c30:	f45e                	sd	s7,40(sp)
    80003c32:	f062                	sd	s8,32(sp)
    80003c34:	ec66                	sd	s9,24(sp)
    80003c36:	e86a                	sd	s10,16(sp)
    80003c38:	e46e                	sd	s11,8(sp)
    80003c3a:	1880                	add	s0,sp,112
    80003c3c:	8baa                	mv	s7,a0
    80003c3e:	8c2e                	mv	s8,a1
    80003c40:	8ab2                	mv	s5,a2
    80003c42:	84b6                	mv	s1,a3
    80003c44:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c46:	9f35                	addw	a4,a4,a3
    return 0;
    80003c48:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c4a:	0ad76063          	bltu	a4,a3,80003cea <readi+0xd2>
  if(off + n > ip->size)
    80003c4e:	00e7f463          	bgeu	a5,a4,80003c56 <readi+0x3e>
    n = ip->size - off;
    80003c52:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c56:	0a0b0963          	beqz	s6,80003d08 <readi+0xf0>
    80003c5a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c5c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c60:	5cfd                	li	s9,-1
    80003c62:	a82d                	j	80003c9c <readi+0x84>
    80003c64:	020a1d93          	sll	s11,s4,0x20
    80003c68:	020ddd93          	srl	s11,s11,0x20
    80003c6c:	05890613          	add	a2,s2,88
    80003c70:	86ee                	mv	a3,s11
    80003c72:	963a                	add	a2,a2,a4
    80003c74:	85d6                	mv	a1,s5
    80003c76:	8562                	mv	a0,s8
    80003c78:	fffff097          	auipc	ra,0xfffff
    80003c7c:	b02080e7          	jalr	-1278(ra) # 8000277a <either_copyout>
    80003c80:	05950d63          	beq	a0,s9,80003cda <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c84:	854a                	mv	a0,s2
    80003c86:	fffff097          	auipc	ra,0xfffff
    80003c8a:	614080e7          	jalr	1556(ra) # 8000329a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c8e:	013a09bb          	addw	s3,s4,s3
    80003c92:	009a04bb          	addw	s1,s4,s1
    80003c96:	9aee                	add	s5,s5,s11
    80003c98:	0569f763          	bgeu	s3,s6,80003ce6 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c9c:	000ba903          	lw	s2,0(s7)
    80003ca0:	00a4d59b          	srlw	a1,s1,0xa
    80003ca4:	855e                	mv	a0,s7
    80003ca6:	00000097          	auipc	ra,0x0
    80003caa:	8b2080e7          	jalr	-1870(ra) # 80003558 <bmap>
    80003cae:	0005059b          	sext.w	a1,a0
    80003cb2:	854a                	mv	a0,s2
    80003cb4:	fffff097          	auipc	ra,0xfffff
    80003cb8:	4b6080e7          	jalr	1206(ra) # 8000316a <bread>
    80003cbc:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cbe:	3ff4f713          	and	a4,s1,1023
    80003cc2:	40ed07bb          	subw	a5,s10,a4
    80003cc6:	413b06bb          	subw	a3,s6,s3
    80003cca:	8a3e                	mv	s4,a5
    80003ccc:	2781                	sext.w	a5,a5
    80003cce:	0006861b          	sext.w	a2,a3
    80003cd2:	f8f679e3          	bgeu	a2,a5,80003c64 <readi+0x4c>
    80003cd6:	8a36                	mv	s4,a3
    80003cd8:	b771                	j	80003c64 <readi+0x4c>
      brelse(bp);
    80003cda:	854a                	mv	a0,s2
    80003cdc:	fffff097          	auipc	ra,0xfffff
    80003ce0:	5be080e7          	jalr	1470(ra) # 8000329a <brelse>
      tot = -1;
    80003ce4:	59fd                	li	s3,-1
  }
  return tot;
    80003ce6:	0009851b          	sext.w	a0,s3
}
    80003cea:	70a6                	ld	ra,104(sp)
    80003cec:	7406                	ld	s0,96(sp)
    80003cee:	64e6                	ld	s1,88(sp)
    80003cf0:	6946                	ld	s2,80(sp)
    80003cf2:	69a6                	ld	s3,72(sp)
    80003cf4:	6a06                	ld	s4,64(sp)
    80003cf6:	7ae2                	ld	s5,56(sp)
    80003cf8:	7b42                	ld	s6,48(sp)
    80003cfa:	7ba2                	ld	s7,40(sp)
    80003cfc:	7c02                	ld	s8,32(sp)
    80003cfe:	6ce2                	ld	s9,24(sp)
    80003d00:	6d42                	ld	s10,16(sp)
    80003d02:	6da2                	ld	s11,8(sp)
    80003d04:	6165                	add	sp,sp,112
    80003d06:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d08:	89da                	mv	s3,s6
    80003d0a:	bff1                	j	80003ce6 <readi+0xce>
    return 0;
    80003d0c:	4501                	li	a0,0
}
    80003d0e:	8082                	ret

0000000080003d10 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d10:	457c                	lw	a5,76(a0)
    80003d12:	10d7e763          	bltu	a5,a3,80003e20 <writei+0x110>
{
    80003d16:	7159                	add	sp,sp,-112
    80003d18:	f486                	sd	ra,104(sp)
    80003d1a:	f0a2                	sd	s0,96(sp)
    80003d1c:	eca6                	sd	s1,88(sp)
    80003d1e:	e8ca                	sd	s2,80(sp)
    80003d20:	e4ce                	sd	s3,72(sp)
    80003d22:	e0d2                	sd	s4,64(sp)
    80003d24:	fc56                	sd	s5,56(sp)
    80003d26:	f85a                	sd	s6,48(sp)
    80003d28:	f45e                	sd	s7,40(sp)
    80003d2a:	f062                	sd	s8,32(sp)
    80003d2c:	ec66                	sd	s9,24(sp)
    80003d2e:	e86a                	sd	s10,16(sp)
    80003d30:	e46e                	sd	s11,8(sp)
    80003d32:	1880                	add	s0,sp,112
    80003d34:	8baa                	mv	s7,a0
    80003d36:	8c2e                	mv	s8,a1
    80003d38:	8ab2                	mv	s5,a2
    80003d3a:	8936                	mv	s2,a3
    80003d3c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d3e:	00e687bb          	addw	a5,a3,a4
    80003d42:	0ed7e163          	bltu	a5,a3,80003e24 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d46:	00043737          	lui	a4,0x43
    80003d4a:	0cf76f63          	bltu	a4,a5,80003e28 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d4e:	0a0b0863          	beqz	s6,80003dfe <writei+0xee>
    80003d52:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d54:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d58:	5cfd                	li	s9,-1
    80003d5a:	a091                	j	80003d9e <writei+0x8e>
    80003d5c:	02099d93          	sll	s11,s3,0x20
    80003d60:	020ddd93          	srl	s11,s11,0x20
    80003d64:	05848513          	add	a0,s1,88
    80003d68:	86ee                	mv	a3,s11
    80003d6a:	8656                	mv	a2,s5
    80003d6c:	85e2                	mv	a1,s8
    80003d6e:	953a                	add	a0,a0,a4
    80003d70:	fffff097          	auipc	ra,0xfffff
    80003d74:	a60080e7          	jalr	-1440(ra) # 800027d0 <either_copyin>
    80003d78:	07950263          	beq	a0,s9,80003ddc <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003d7c:	8526                	mv	a0,s1
    80003d7e:	00000097          	auipc	ra,0x0
    80003d82:	75a080e7          	jalr	1882(ra) # 800044d8 <log_write>
    brelse(bp);
    80003d86:	8526                	mv	a0,s1
    80003d88:	fffff097          	auipc	ra,0xfffff
    80003d8c:	512080e7          	jalr	1298(ra) # 8000329a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d90:	01498a3b          	addw	s4,s3,s4
    80003d94:	0129893b          	addw	s2,s3,s2
    80003d98:	9aee                	add	s5,s5,s11
    80003d9a:	056a7763          	bgeu	s4,s6,80003de8 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d9e:	000ba483          	lw	s1,0(s7)
    80003da2:	00a9559b          	srlw	a1,s2,0xa
    80003da6:	855e                	mv	a0,s7
    80003da8:	fffff097          	auipc	ra,0xfffff
    80003dac:	7b0080e7          	jalr	1968(ra) # 80003558 <bmap>
    80003db0:	0005059b          	sext.w	a1,a0
    80003db4:	8526                	mv	a0,s1
    80003db6:	fffff097          	auipc	ra,0xfffff
    80003dba:	3b4080e7          	jalr	948(ra) # 8000316a <bread>
    80003dbe:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dc0:	3ff97713          	and	a4,s2,1023
    80003dc4:	40ed07bb          	subw	a5,s10,a4
    80003dc8:	414b06bb          	subw	a3,s6,s4
    80003dcc:	89be                	mv	s3,a5
    80003dce:	2781                	sext.w	a5,a5
    80003dd0:	0006861b          	sext.w	a2,a3
    80003dd4:	f8f674e3          	bgeu	a2,a5,80003d5c <writei+0x4c>
    80003dd8:	89b6                	mv	s3,a3
    80003dda:	b749                	j	80003d5c <writei+0x4c>
      brelse(bp);
    80003ddc:	8526                	mv	a0,s1
    80003dde:	fffff097          	auipc	ra,0xfffff
    80003de2:	4bc080e7          	jalr	1212(ra) # 8000329a <brelse>
      n = -1;
    80003de6:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003de8:	04cba783          	lw	a5,76(s7)
    80003dec:	0127f463          	bgeu	a5,s2,80003df4 <writei+0xe4>
      ip->size = off;
    80003df0:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003df4:	855e                	mv	a0,s7
    80003df6:	00000097          	auipc	ra,0x0
    80003dfa:	aa2080e7          	jalr	-1374(ra) # 80003898 <iupdate>
  }

  return n;
    80003dfe:	000b051b          	sext.w	a0,s6
}
    80003e02:	70a6                	ld	ra,104(sp)
    80003e04:	7406                	ld	s0,96(sp)
    80003e06:	64e6                	ld	s1,88(sp)
    80003e08:	6946                	ld	s2,80(sp)
    80003e0a:	69a6                	ld	s3,72(sp)
    80003e0c:	6a06                	ld	s4,64(sp)
    80003e0e:	7ae2                	ld	s5,56(sp)
    80003e10:	7b42                	ld	s6,48(sp)
    80003e12:	7ba2                	ld	s7,40(sp)
    80003e14:	7c02                	ld	s8,32(sp)
    80003e16:	6ce2                	ld	s9,24(sp)
    80003e18:	6d42                	ld	s10,16(sp)
    80003e1a:	6da2                	ld	s11,8(sp)
    80003e1c:	6165                	add	sp,sp,112
    80003e1e:	8082                	ret
    return -1;
    80003e20:	557d                	li	a0,-1
}
    80003e22:	8082                	ret
    return -1;
    80003e24:	557d                	li	a0,-1
    80003e26:	bff1                	j	80003e02 <writei+0xf2>
    return -1;
    80003e28:	557d                	li	a0,-1
    80003e2a:	bfe1                	j	80003e02 <writei+0xf2>

0000000080003e2c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e2c:	1141                	add	sp,sp,-16
    80003e2e:	e406                	sd	ra,8(sp)
    80003e30:	e022                	sd	s0,0(sp)
    80003e32:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e34:	4639                	li	a2,14
    80003e36:	ffffd097          	auipc	ra,0xffffd
    80003e3a:	084080e7          	jalr	132(ra) # 80000eba <strncmp>
}
    80003e3e:	60a2                	ld	ra,8(sp)
    80003e40:	6402                	ld	s0,0(sp)
    80003e42:	0141                	add	sp,sp,16
    80003e44:	8082                	ret

0000000080003e46 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e46:	7139                	add	sp,sp,-64
    80003e48:	fc06                	sd	ra,56(sp)
    80003e4a:	f822                	sd	s0,48(sp)
    80003e4c:	f426                	sd	s1,40(sp)
    80003e4e:	f04a                	sd	s2,32(sp)
    80003e50:	ec4e                	sd	s3,24(sp)
    80003e52:	e852                	sd	s4,16(sp)
    80003e54:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e56:	04451703          	lh	a4,68(a0)
    80003e5a:	4785                	li	a5,1
    80003e5c:	00f71a63          	bne	a4,a5,80003e70 <dirlookup+0x2a>
    80003e60:	892a                	mv	s2,a0
    80003e62:	89ae                	mv	s3,a1
    80003e64:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e66:	457c                	lw	a5,76(a0)
    80003e68:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e6a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e6c:	e79d                	bnez	a5,80003e9a <dirlookup+0x54>
    80003e6e:	a8a5                	j	80003ee6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e70:	00004517          	auipc	a0,0x4
    80003e74:	75850513          	add	a0,a0,1880 # 800085c8 <syscalls+0x1a0>
    80003e78:	ffffc097          	auipc	ra,0xffffc
    80003e7c:	6ca080e7          	jalr	1738(ra) # 80000542 <panic>
      panic("dirlookup read");
    80003e80:	00004517          	auipc	a0,0x4
    80003e84:	76050513          	add	a0,a0,1888 # 800085e0 <syscalls+0x1b8>
    80003e88:	ffffc097          	auipc	ra,0xffffc
    80003e8c:	6ba080e7          	jalr	1722(ra) # 80000542 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e90:	24c1                	addw	s1,s1,16
    80003e92:	04c92783          	lw	a5,76(s2)
    80003e96:	04f4f763          	bgeu	s1,a5,80003ee4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e9a:	4741                	li	a4,16
    80003e9c:	86a6                	mv	a3,s1
    80003e9e:	fc040613          	add	a2,s0,-64
    80003ea2:	4581                	li	a1,0
    80003ea4:	854a                	mv	a0,s2
    80003ea6:	00000097          	auipc	ra,0x0
    80003eaa:	d72080e7          	jalr	-654(ra) # 80003c18 <readi>
    80003eae:	47c1                	li	a5,16
    80003eb0:	fcf518e3          	bne	a0,a5,80003e80 <dirlookup+0x3a>
    if(de.inum == 0)
    80003eb4:	fc045783          	lhu	a5,-64(s0)
    80003eb8:	dfe1                	beqz	a5,80003e90 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003eba:	fc240593          	add	a1,s0,-62
    80003ebe:	854e                	mv	a0,s3
    80003ec0:	00000097          	auipc	ra,0x0
    80003ec4:	f6c080e7          	jalr	-148(ra) # 80003e2c <namecmp>
    80003ec8:	f561                	bnez	a0,80003e90 <dirlookup+0x4a>
      if(poff)
    80003eca:	000a0463          	beqz	s4,80003ed2 <dirlookup+0x8c>
        *poff = off;
    80003ece:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ed2:	fc045583          	lhu	a1,-64(s0)
    80003ed6:	00092503          	lw	a0,0(s2)
    80003eda:	fffff097          	auipc	ra,0xfffff
    80003ede:	75a080e7          	jalr	1882(ra) # 80003634 <iget>
    80003ee2:	a011                	j	80003ee6 <dirlookup+0xa0>
  return 0;
    80003ee4:	4501                	li	a0,0
}
    80003ee6:	70e2                	ld	ra,56(sp)
    80003ee8:	7442                	ld	s0,48(sp)
    80003eea:	74a2                	ld	s1,40(sp)
    80003eec:	7902                	ld	s2,32(sp)
    80003eee:	69e2                	ld	s3,24(sp)
    80003ef0:	6a42                	ld	s4,16(sp)
    80003ef2:	6121                	add	sp,sp,64
    80003ef4:	8082                	ret

0000000080003ef6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ef6:	711d                	add	sp,sp,-96
    80003ef8:	ec86                	sd	ra,88(sp)
    80003efa:	e8a2                	sd	s0,80(sp)
    80003efc:	e4a6                	sd	s1,72(sp)
    80003efe:	e0ca                	sd	s2,64(sp)
    80003f00:	fc4e                	sd	s3,56(sp)
    80003f02:	f852                	sd	s4,48(sp)
    80003f04:	f456                	sd	s5,40(sp)
    80003f06:	f05a                	sd	s6,32(sp)
    80003f08:	ec5e                	sd	s7,24(sp)
    80003f0a:	e862                	sd	s8,16(sp)
    80003f0c:	e466                	sd	s9,8(sp)
    80003f0e:	1080                	add	s0,sp,96
    80003f10:	84aa                	mv	s1,a0
    80003f12:	8b2e                	mv	s6,a1
    80003f14:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f16:	00054703          	lbu	a4,0(a0)
    80003f1a:	02f00793          	li	a5,47
    80003f1e:	02f70263          	beq	a4,a5,80003f42 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f22:	ffffe097          	auipc	ra,0xffffe
    80003f26:	de8080e7          	jalr	-536(ra) # 80001d0a <myproc>
    80003f2a:	15053503          	ld	a0,336(a0)
    80003f2e:	00000097          	auipc	ra,0x0
    80003f32:	9f8080e7          	jalr	-1544(ra) # 80003926 <idup>
    80003f36:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003f38:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003f3c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f3e:	4b85                	li	s7,1
    80003f40:	a875                	j	80003ffc <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003f42:	4585                	li	a1,1
    80003f44:	4505                	li	a0,1
    80003f46:	fffff097          	auipc	ra,0xfffff
    80003f4a:	6ee080e7          	jalr	1774(ra) # 80003634 <iget>
    80003f4e:	8a2a                	mv	s4,a0
    80003f50:	b7e5                	j	80003f38 <namex+0x42>
      iunlockput(ip);
    80003f52:	8552                	mv	a0,s4
    80003f54:	00000097          	auipc	ra,0x0
    80003f58:	c72080e7          	jalr	-910(ra) # 80003bc6 <iunlockput>
      return 0;
    80003f5c:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f5e:	8552                	mv	a0,s4
    80003f60:	60e6                	ld	ra,88(sp)
    80003f62:	6446                	ld	s0,80(sp)
    80003f64:	64a6                	ld	s1,72(sp)
    80003f66:	6906                	ld	s2,64(sp)
    80003f68:	79e2                	ld	s3,56(sp)
    80003f6a:	7a42                	ld	s4,48(sp)
    80003f6c:	7aa2                	ld	s5,40(sp)
    80003f6e:	7b02                	ld	s6,32(sp)
    80003f70:	6be2                	ld	s7,24(sp)
    80003f72:	6c42                	ld	s8,16(sp)
    80003f74:	6ca2                	ld	s9,8(sp)
    80003f76:	6125                	add	sp,sp,96
    80003f78:	8082                	ret
      iunlock(ip);
    80003f7a:	8552                	mv	a0,s4
    80003f7c:	00000097          	auipc	ra,0x0
    80003f80:	aaa080e7          	jalr	-1366(ra) # 80003a26 <iunlock>
      return ip;
    80003f84:	bfe9                	j	80003f5e <namex+0x68>
      iunlockput(ip);
    80003f86:	8552                	mv	a0,s4
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	c3e080e7          	jalr	-962(ra) # 80003bc6 <iunlockput>
      return 0;
    80003f90:	8a4e                	mv	s4,s3
    80003f92:	b7f1                	j	80003f5e <namex+0x68>
  len = path - s;
    80003f94:	40998633          	sub	a2,s3,s1
    80003f98:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003f9c:	099c5863          	bge	s8,s9,8000402c <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003fa0:	4639                	li	a2,14
    80003fa2:	85a6                	mv	a1,s1
    80003fa4:	8556                	mv	a0,s5
    80003fa6:	ffffd097          	auipc	ra,0xffffd
    80003faa:	e98080e7          	jalr	-360(ra) # 80000e3e <memmove>
    80003fae:	84ce                	mv	s1,s3
  while(*path == '/')
    80003fb0:	0004c783          	lbu	a5,0(s1)
    80003fb4:	01279763          	bne	a5,s2,80003fc2 <namex+0xcc>
    path++;
    80003fb8:	0485                	add	s1,s1,1
  while(*path == '/')
    80003fba:	0004c783          	lbu	a5,0(s1)
    80003fbe:	ff278de3          	beq	a5,s2,80003fb8 <namex+0xc2>
    ilock(ip);
    80003fc2:	8552                	mv	a0,s4
    80003fc4:	00000097          	auipc	ra,0x0
    80003fc8:	9a0080e7          	jalr	-1632(ra) # 80003964 <ilock>
    if(ip->type != T_DIR){
    80003fcc:	044a1783          	lh	a5,68(s4)
    80003fd0:	f97791e3          	bne	a5,s7,80003f52 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80003fd4:	000b0563          	beqz	s6,80003fde <namex+0xe8>
    80003fd8:	0004c783          	lbu	a5,0(s1)
    80003fdc:	dfd9                	beqz	a5,80003f7a <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fde:	4601                	li	a2,0
    80003fe0:	85d6                	mv	a1,s5
    80003fe2:	8552                	mv	a0,s4
    80003fe4:	00000097          	auipc	ra,0x0
    80003fe8:	e62080e7          	jalr	-414(ra) # 80003e46 <dirlookup>
    80003fec:	89aa                	mv	s3,a0
    80003fee:	dd41                	beqz	a0,80003f86 <namex+0x90>
    iunlockput(ip);
    80003ff0:	8552                	mv	a0,s4
    80003ff2:	00000097          	auipc	ra,0x0
    80003ff6:	bd4080e7          	jalr	-1068(ra) # 80003bc6 <iunlockput>
    ip = next;
    80003ffa:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003ffc:	0004c783          	lbu	a5,0(s1)
    80004000:	01279763          	bne	a5,s2,8000400e <namex+0x118>
    path++;
    80004004:	0485                	add	s1,s1,1
  while(*path == '/')
    80004006:	0004c783          	lbu	a5,0(s1)
    8000400a:	ff278de3          	beq	a5,s2,80004004 <namex+0x10e>
  if(*path == 0)
    8000400e:	cb9d                	beqz	a5,80004044 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80004010:	0004c783          	lbu	a5,0(s1)
    80004014:	89a6                	mv	s3,s1
  len = path - s;
    80004016:	4c81                	li	s9,0
    80004018:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    8000401a:	01278963          	beq	a5,s2,8000402c <namex+0x136>
    8000401e:	dbbd                	beqz	a5,80003f94 <namex+0x9e>
    path++;
    80004020:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    80004022:	0009c783          	lbu	a5,0(s3)
    80004026:	ff279ce3          	bne	a5,s2,8000401e <namex+0x128>
    8000402a:	b7ad                	j	80003f94 <namex+0x9e>
    memmove(name, s, len);
    8000402c:	2601                	sext.w	a2,a2
    8000402e:	85a6                	mv	a1,s1
    80004030:	8556                	mv	a0,s5
    80004032:	ffffd097          	auipc	ra,0xffffd
    80004036:	e0c080e7          	jalr	-500(ra) # 80000e3e <memmove>
    name[len] = 0;
    8000403a:	9cd6                	add	s9,s9,s5
    8000403c:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004040:	84ce                	mv	s1,s3
    80004042:	b7bd                	j	80003fb0 <namex+0xba>
  if(nameiparent){
    80004044:	f00b0de3          	beqz	s6,80003f5e <namex+0x68>
    iput(ip);
    80004048:	8552                	mv	a0,s4
    8000404a:	00000097          	auipc	ra,0x0
    8000404e:	ad4080e7          	jalr	-1324(ra) # 80003b1e <iput>
    return 0;
    80004052:	4a01                	li	s4,0
    80004054:	b729                	j	80003f5e <namex+0x68>

0000000080004056 <dirlink>:
{
    80004056:	7139                	add	sp,sp,-64
    80004058:	fc06                	sd	ra,56(sp)
    8000405a:	f822                	sd	s0,48(sp)
    8000405c:	f426                	sd	s1,40(sp)
    8000405e:	f04a                	sd	s2,32(sp)
    80004060:	ec4e                	sd	s3,24(sp)
    80004062:	e852                	sd	s4,16(sp)
    80004064:	0080                	add	s0,sp,64
    80004066:	892a                	mv	s2,a0
    80004068:	8a2e                	mv	s4,a1
    8000406a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000406c:	4601                	li	a2,0
    8000406e:	00000097          	auipc	ra,0x0
    80004072:	dd8080e7          	jalr	-552(ra) # 80003e46 <dirlookup>
    80004076:	e93d                	bnez	a0,800040ec <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004078:	04c92483          	lw	s1,76(s2)
    8000407c:	c49d                	beqz	s1,800040aa <dirlink+0x54>
    8000407e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004080:	4741                	li	a4,16
    80004082:	86a6                	mv	a3,s1
    80004084:	fc040613          	add	a2,s0,-64
    80004088:	4581                	li	a1,0
    8000408a:	854a                	mv	a0,s2
    8000408c:	00000097          	auipc	ra,0x0
    80004090:	b8c080e7          	jalr	-1140(ra) # 80003c18 <readi>
    80004094:	47c1                	li	a5,16
    80004096:	06f51163          	bne	a0,a5,800040f8 <dirlink+0xa2>
    if(de.inum == 0)
    8000409a:	fc045783          	lhu	a5,-64(s0)
    8000409e:	c791                	beqz	a5,800040aa <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040a0:	24c1                	addw	s1,s1,16
    800040a2:	04c92783          	lw	a5,76(s2)
    800040a6:	fcf4ede3          	bltu	s1,a5,80004080 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040aa:	4639                	li	a2,14
    800040ac:	85d2                	mv	a1,s4
    800040ae:	fc240513          	add	a0,s0,-62
    800040b2:	ffffd097          	auipc	ra,0xffffd
    800040b6:	e44080e7          	jalr	-444(ra) # 80000ef6 <strncpy>
  de.inum = inum;
    800040ba:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040be:	4741                	li	a4,16
    800040c0:	86a6                	mv	a3,s1
    800040c2:	fc040613          	add	a2,s0,-64
    800040c6:	4581                	li	a1,0
    800040c8:	854a                	mv	a0,s2
    800040ca:	00000097          	auipc	ra,0x0
    800040ce:	c46080e7          	jalr	-954(ra) # 80003d10 <writei>
    800040d2:	872a                	mv	a4,a0
    800040d4:	47c1                	li	a5,16
  return 0;
    800040d6:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040d8:	02f71863          	bne	a4,a5,80004108 <dirlink+0xb2>
}
    800040dc:	70e2                	ld	ra,56(sp)
    800040de:	7442                	ld	s0,48(sp)
    800040e0:	74a2                	ld	s1,40(sp)
    800040e2:	7902                	ld	s2,32(sp)
    800040e4:	69e2                	ld	s3,24(sp)
    800040e6:	6a42                	ld	s4,16(sp)
    800040e8:	6121                	add	sp,sp,64
    800040ea:	8082                	ret
    iput(ip);
    800040ec:	00000097          	auipc	ra,0x0
    800040f0:	a32080e7          	jalr	-1486(ra) # 80003b1e <iput>
    return -1;
    800040f4:	557d                	li	a0,-1
    800040f6:	b7dd                	j	800040dc <dirlink+0x86>
      panic("dirlink read");
    800040f8:	00004517          	auipc	a0,0x4
    800040fc:	4f850513          	add	a0,a0,1272 # 800085f0 <syscalls+0x1c8>
    80004100:	ffffc097          	auipc	ra,0xffffc
    80004104:	442080e7          	jalr	1090(ra) # 80000542 <panic>
    panic("dirlink");
    80004108:	00004517          	auipc	a0,0x4
    8000410c:	60850513          	add	a0,a0,1544 # 80008710 <syscalls+0x2e8>
    80004110:	ffffc097          	auipc	ra,0xffffc
    80004114:	432080e7          	jalr	1074(ra) # 80000542 <panic>

0000000080004118 <namei>:

struct inode*
namei(char *path)
{
    80004118:	1101                	add	sp,sp,-32
    8000411a:	ec06                	sd	ra,24(sp)
    8000411c:	e822                	sd	s0,16(sp)
    8000411e:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004120:	fe040613          	add	a2,s0,-32
    80004124:	4581                	li	a1,0
    80004126:	00000097          	auipc	ra,0x0
    8000412a:	dd0080e7          	jalr	-560(ra) # 80003ef6 <namex>
}
    8000412e:	60e2                	ld	ra,24(sp)
    80004130:	6442                	ld	s0,16(sp)
    80004132:	6105                	add	sp,sp,32
    80004134:	8082                	ret

0000000080004136 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004136:	1141                	add	sp,sp,-16
    80004138:	e406                	sd	ra,8(sp)
    8000413a:	e022                	sd	s0,0(sp)
    8000413c:	0800                	add	s0,sp,16
    8000413e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004140:	4585                	li	a1,1
    80004142:	00000097          	auipc	ra,0x0
    80004146:	db4080e7          	jalr	-588(ra) # 80003ef6 <namex>
}
    8000414a:	60a2                	ld	ra,8(sp)
    8000414c:	6402                	ld	s0,0(sp)
    8000414e:	0141                	add	sp,sp,16
    80004150:	8082                	ret

0000000080004152 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004152:	1101                	add	sp,sp,-32
    80004154:	ec06                	sd	ra,24(sp)
    80004156:	e822                	sd	s0,16(sp)
    80004158:	e426                	sd	s1,8(sp)
    8000415a:	e04a                	sd	s2,0(sp)
    8000415c:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000415e:	00025917          	auipc	s2,0x25
    80004162:	7aa90913          	add	s2,s2,1962 # 80029908 <log>
    80004166:	01892583          	lw	a1,24(s2)
    8000416a:	02892503          	lw	a0,40(s2)
    8000416e:	fffff097          	auipc	ra,0xfffff
    80004172:	ffc080e7          	jalr	-4(ra) # 8000316a <bread>
    80004176:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004178:	02c92603          	lw	a2,44(s2)
    8000417c:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000417e:	00c05f63          	blez	a2,8000419c <write_head+0x4a>
    80004182:	00025717          	auipc	a4,0x25
    80004186:	7b670713          	add	a4,a4,1974 # 80029938 <log+0x30>
    8000418a:	87aa                	mv	a5,a0
    8000418c:	060a                	sll	a2,a2,0x2
    8000418e:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80004190:	4314                	lw	a3,0(a4)
    80004192:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004194:	0711                	add	a4,a4,4
    80004196:	0791                	add	a5,a5,4
    80004198:	fec79ce3          	bne	a5,a2,80004190 <write_head+0x3e>
  }
  bwrite(buf);
    8000419c:	8526                	mv	a0,s1
    8000419e:	fffff097          	auipc	ra,0xfffff
    800041a2:	0be080e7          	jalr	190(ra) # 8000325c <bwrite>
  brelse(buf);
    800041a6:	8526                	mv	a0,s1
    800041a8:	fffff097          	auipc	ra,0xfffff
    800041ac:	0f2080e7          	jalr	242(ra) # 8000329a <brelse>
}
    800041b0:	60e2                	ld	ra,24(sp)
    800041b2:	6442                	ld	s0,16(sp)
    800041b4:	64a2                	ld	s1,8(sp)
    800041b6:	6902                	ld	s2,0(sp)
    800041b8:	6105                	add	sp,sp,32
    800041ba:	8082                	ret

00000000800041bc <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041bc:	00025797          	auipc	a5,0x25
    800041c0:	7787a783          	lw	a5,1912(a5) # 80029934 <log+0x2c>
    800041c4:	0af05663          	blez	a5,80004270 <install_trans+0xb4>
{
    800041c8:	7139                	add	sp,sp,-64
    800041ca:	fc06                	sd	ra,56(sp)
    800041cc:	f822                	sd	s0,48(sp)
    800041ce:	f426                	sd	s1,40(sp)
    800041d0:	f04a                	sd	s2,32(sp)
    800041d2:	ec4e                	sd	s3,24(sp)
    800041d4:	e852                	sd	s4,16(sp)
    800041d6:	e456                	sd	s5,8(sp)
    800041d8:	0080                	add	s0,sp,64
    800041da:	00025a97          	auipc	s5,0x25
    800041de:	75ea8a93          	add	s5,s5,1886 # 80029938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041e2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041e4:	00025997          	auipc	s3,0x25
    800041e8:	72498993          	add	s3,s3,1828 # 80029908 <log>
    800041ec:	0189a583          	lw	a1,24(s3)
    800041f0:	014585bb          	addw	a1,a1,s4
    800041f4:	2585                	addw	a1,a1,1
    800041f6:	0289a503          	lw	a0,40(s3)
    800041fa:	fffff097          	auipc	ra,0xfffff
    800041fe:	f70080e7          	jalr	-144(ra) # 8000316a <bread>
    80004202:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004204:	000aa583          	lw	a1,0(s5)
    80004208:	0289a503          	lw	a0,40(s3)
    8000420c:	fffff097          	auipc	ra,0xfffff
    80004210:	f5e080e7          	jalr	-162(ra) # 8000316a <bread>
    80004214:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004216:	40000613          	li	a2,1024
    8000421a:	05890593          	add	a1,s2,88
    8000421e:	05850513          	add	a0,a0,88
    80004222:	ffffd097          	auipc	ra,0xffffd
    80004226:	c1c080e7          	jalr	-996(ra) # 80000e3e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000422a:	8526                	mv	a0,s1
    8000422c:	fffff097          	auipc	ra,0xfffff
    80004230:	030080e7          	jalr	48(ra) # 8000325c <bwrite>
    bunpin(dbuf);
    80004234:	8526                	mv	a0,s1
    80004236:	fffff097          	auipc	ra,0xfffff
    8000423a:	13c080e7          	jalr	316(ra) # 80003372 <bunpin>
    brelse(lbuf);
    8000423e:	854a                	mv	a0,s2
    80004240:	fffff097          	auipc	ra,0xfffff
    80004244:	05a080e7          	jalr	90(ra) # 8000329a <brelse>
    brelse(dbuf);
    80004248:	8526                	mv	a0,s1
    8000424a:	fffff097          	auipc	ra,0xfffff
    8000424e:	050080e7          	jalr	80(ra) # 8000329a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004252:	2a05                	addw	s4,s4,1
    80004254:	0a91                	add	s5,s5,4
    80004256:	02c9a783          	lw	a5,44(s3)
    8000425a:	f8fa49e3          	blt	s4,a5,800041ec <install_trans+0x30>
}
    8000425e:	70e2                	ld	ra,56(sp)
    80004260:	7442                	ld	s0,48(sp)
    80004262:	74a2                	ld	s1,40(sp)
    80004264:	7902                	ld	s2,32(sp)
    80004266:	69e2                	ld	s3,24(sp)
    80004268:	6a42                	ld	s4,16(sp)
    8000426a:	6aa2                	ld	s5,8(sp)
    8000426c:	6121                	add	sp,sp,64
    8000426e:	8082                	ret
    80004270:	8082                	ret

0000000080004272 <initlog>:
{
    80004272:	7179                	add	sp,sp,-48
    80004274:	f406                	sd	ra,40(sp)
    80004276:	f022                	sd	s0,32(sp)
    80004278:	ec26                	sd	s1,24(sp)
    8000427a:	e84a                	sd	s2,16(sp)
    8000427c:	e44e                	sd	s3,8(sp)
    8000427e:	1800                	add	s0,sp,48
    80004280:	892a                	mv	s2,a0
    80004282:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004284:	00025497          	auipc	s1,0x25
    80004288:	68448493          	add	s1,s1,1668 # 80029908 <log>
    8000428c:	00004597          	auipc	a1,0x4
    80004290:	37458593          	add	a1,a1,884 # 80008600 <syscalls+0x1d8>
    80004294:	8526                	mv	a0,s1
    80004296:	ffffd097          	auipc	ra,0xffffd
    8000429a:	9c0080e7          	jalr	-1600(ra) # 80000c56 <initlock>
  log.start = sb->logstart;
    8000429e:	0149a583          	lw	a1,20(s3)
    800042a2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042a4:	0109a783          	lw	a5,16(s3)
    800042a8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042aa:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042ae:	854a                	mv	a0,s2
    800042b0:	fffff097          	auipc	ra,0xfffff
    800042b4:	eba080e7          	jalr	-326(ra) # 8000316a <bread>
  log.lh.n = lh->n;
    800042b8:	4d30                	lw	a2,88(a0)
    800042ba:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042bc:	00c05f63          	blez	a2,800042da <initlog+0x68>
    800042c0:	87aa                	mv	a5,a0
    800042c2:	00025717          	auipc	a4,0x25
    800042c6:	67670713          	add	a4,a4,1654 # 80029938 <log+0x30>
    800042ca:	060a                	sll	a2,a2,0x2
    800042cc:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800042ce:	4ff4                	lw	a3,92(a5)
    800042d0:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800042d2:	0791                	add	a5,a5,4
    800042d4:	0711                	add	a4,a4,4
    800042d6:	fec79ce3          	bne	a5,a2,800042ce <initlog+0x5c>
  brelse(buf);
    800042da:	fffff097          	auipc	ra,0xfffff
    800042de:	fc0080e7          	jalr	-64(ra) # 8000329a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800042e2:	00000097          	auipc	ra,0x0
    800042e6:	eda080e7          	jalr	-294(ra) # 800041bc <install_trans>
  log.lh.n = 0;
    800042ea:	00025797          	auipc	a5,0x25
    800042ee:	6407a523          	sw	zero,1610(a5) # 80029934 <log+0x2c>
  write_head(); // clear the log
    800042f2:	00000097          	auipc	ra,0x0
    800042f6:	e60080e7          	jalr	-416(ra) # 80004152 <write_head>
}
    800042fa:	70a2                	ld	ra,40(sp)
    800042fc:	7402                	ld	s0,32(sp)
    800042fe:	64e2                	ld	s1,24(sp)
    80004300:	6942                	ld	s2,16(sp)
    80004302:	69a2                	ld	s3,8(sp)
    80004304:	6145                	add	sp,sp,48
    80004306:	8082                	ret

0000000080004308 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004308:	1101                	add	sp,sp,-32
    8000430a:	ec06                	sd	ra,24(sp)
    8000430c:	e822                	sd	s0,16(sp)
    8000430e:	e426                	sd	s1,8(sp)
    80004310:	e04a                	sd	s2,0(sp)
    80004312:	1000                	add	s0,sp,32
  acquire(&log.lock);
    80004314:	00025517          	auipc	a0,0x25
    80004318:	5f450513          	add	a0,a0,1524 # 80029908 <log>
    8000431c:	ffffd097          	auipc	ra,0xffffd
    80004320:	9ca080e7          	jalr	-1590(ra) # 80000ce6 <acquire>
  while(1){
    if(log.committing){
    80004324:	00025497          	auipc	s1,0x25
    80004328:	5e448493          	add	s1,s1,1508 # 80029908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000432c:	4979                	li	s2,30
    8000432e:	a039                	j	8000433c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004330:	85a6                	mv	a1,s1
    80004332:	8526                	mv	a0,s1
    80004334:	ffffe097          	auipc	ra,0xffffe
    80004338:	1ec080e7          	jalr	492(ra) # 80002520 <sleep>
    if(log.committing){
    8000433c:	50dc                	lw	a5,36(s1)
    8000433e:	fbed                	bnez	a5,80004330 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004340:	5098                	lw	a4,32(s1)
    80004342:	2705                	addw	a4,a4,1
    80004344:	0027179b          	sllw	a5,a4,0x2
    80004348:	9fb9                	addw	a5,a5,a4
    8000434a:	0017979b          	sllw	a5,a5,0x1
    8000434e:	54d4                	lw	a3,44(s1)
    80004350:	9fb5                	addw	a5,a5,a3
    80004352:	00f95963          	bge	s2,a5,80004364 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004356:	85a6                	mv	a1,s1
    80004358:	8526                	mv	a0,s1
    8000435a:	ffffe097          	auipc	ra,0xffffe
    8000435e:	1c6080e7          	jalr	454(ra) # 80002520 <sleep>
    80004362:	bfe9                	j	8000433c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004364:	00025517          	auipc	a0,0x25
    80004368:	5a450513          	add	a0,a0,1444 # 80029908 <log>
    8000436c:	d118                	sw	a4,32(a0)
      release(&log.lock);
    8000436e:	ffffd097          	auipc	ra,0xffffd
    80004372:	a2c080e7          	jalr	-1492(ra) # 80000d9a <release>
      break;
    }
  }
}
    80004376:	60e2                	ld	ra,24(sp)
    80004378:	6442                	ld	s0,16(sp)
    8000437a:	64a2                	ld	s1,8(sp)
    8000437c:	6902                	ld	s2,0(sp)
    8000437e:	6105                	add	sp,sp,32
    80004380:	8082                	ret

0000000080004382 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004382:	7139                	add	sp,sp,-64
    80004384:	fc06                	sd	ra,56(sp)
    80004386:	f822                	sd	s0,48(sp)
    80004388:	f426                	sd	s1,40(sp)
    8000438a:	f04a                	sd	s2,32(sp)
    8000438c:	ec4e                	sd	s3,24(sp)
    8000438e:	e852                	sd	s4,16(sp)
    80004390:	e456                	sd	s5,8(sp)
    80004392:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004394:	00025497          	auipc	s1,0x25
    80004398:	57448493          	add	s1,s1,1396 # 80029908 <log>
    8000439c:	8526                	mv	a0,s1
    8000439e:	ffffd097          	auipc	ra,0xffffd
    800043a2:	948080e7          	jalr	-1720(ra) # 80000ce6 <acquire>
  log.outstanding -= 1;
    800043a6:	509c                	lw	a5,32(s1)
    800043a8:	37fd                	addw	a5,a5,-1
    800043aa:	0007891b          	sext.w	s2,a5
    800043ae:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043b0:	50dc                	lw	a5,36(s1)
    800043b2:	e7b9                	bnez	a5,80004400 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043b4:	04091e63          	bnez	s2,80004410 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800043b8:	00025497          	auipc	s1,0x25
    800043bc:	55048493          	add	s1,s1,1360 # 80029908 <log>
    800043c0:	4785                	li	a5,1
    800043c2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043c4:	8526                	mv	a0,s1
    800043c6:	ffffd097          	auipc	ra,0xffffd
    800043ca:	9d4080e7          	jalr	-1580(ra) # 80000d9a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043ce:	54dc                	lw	a5,44(s1)
    800043d0:	06f04763          	bgtz	a5,8000443e <end_op+0xbc>
    acquire(&log.lock);
    800043d4:	00025497          	auipc	s1,0x25
    800043d8:	53448493          	add	s1,s1,1332 # 80029908 <log>
    800043dc:	8526                	mv	a0,s1
    800043de:	ffffd097          	auipc	ra,0xffffd
    800043e2:	908080e7          	jalr	-1784(ra) # 80000ce6 <acquire>
    log.committing = 0;
    800043e6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043ea:	8526                	mv	a0,s1
    800043ec:	ffffe097          	auipc	ra,0xffffe
    800043f0:	2b4080e7          	jalr	692(ra) # 800026a0 <wakeup>
    release(&log.lock);
    800043f4:	8526                	mv	a0,s1
    800043f6:	ffffd097          	auipc	ra,0xffffd
    800043fa:	9a4080e7          	jalr	-1628(ra) # 80000d9a <release>
}
    800043fe:	a03d                	j	8000442c <end_op+0xaa>
    panic("log.committing");
    80004400:	00004517          	auipc	a0,0x4
    80004404:	20850513          	add	a0,a0,520 # 80008608 <syscalls+0x1e0>
    80004408:	ffffc097          	auipc	ra,0xffffc
    8000440c:	13a080e7          	jalr	314(ra) # 80000542 <panic>
    wakeup(&log);
    80004410:	00025497          	auipc	s1,0x25
    80004414:	4f848493          	add	s1,s1,1272 # 80029908 <log>
    80004418:	8526                	mv	a0,s1
    8000441a:	ffffe097          	auipc	ra,0xffffe
    8000441e:	286080e7          	jalr	646(ra) # 800026a0 <wakeup>
  release(&log.lock);
    80004422:	8526                	mv	a0,s1
    80004424:	ffffd097          	auipc	ra,0xffffd
    80004428:	976080e7          	jalr	-1674(ra) # 80000d9a <release>
}
    8000442c:	70e2                	ld	ra,56(sp)
    8000442e:	7442                	ld	s0,48(sp)
    80004430:	74a2                	ld	s1,40(sp)
    80004432:	7902                	ld	s2,32(sp)
    80004434:	69e2                	ld	s3,24(sp)
    80004436:	6a42                	ld	s4,16(sp)
    80004438:	6aa2                	ld	s5,8(sp)
    8000443a:	6121                	add	sp,sp,64
    8000443c:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000443e:	00025a97          	auipc	s5,0x25
    80004442:	4faa8a93          	add	s5,s5,1274 # 80029938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004446:	00025a17          	auipc	s4,0x25
    8000444a:	4c2a0a13          	add	s4,s4,1218 # 80029908 <log>
    8000444e:	018a2583          	lw	a1,24(s4)
    80004452:	012585bb          	addw	a1,a1,s2
    80004456:	2585                	addw	a1,a1,1
    80004458:	028a2503          	lw	a0,40(s4)
    8000445c:	fffff097          	auipc	ra,0xfffff
    80004460:	d0e080e7          	jalr	-754(ra) # 8000316a <bread>
    80004464:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004466:	000aa583          	lw	a1,0(s5)
    8000446a:	028a2503          	lw	a0,40(s4)
    8000446e:	fffff097          	auipc	ra,0xfffff
    80004472:	cfc080e7          	jalr	-772(ra) # 8000316a <bread>
    80004476:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004478:	40000613          	li	a2,1024
    8000447c:	05850593          	add	a1,a0,88
    80004480:	05848513          	add	a0,s1,88
    80004484:	ffffd097          	auipc	ra,0xffffd
    80004488:	9ba080e7          	jalr	-1606(ra) # 80000e3e <memmove>
    bwrite(to);  // write the log
    8000448c:	8526                	mv	a0,s1
    8000448e:	fffff097          	auipc	ra,0xfffff
    80004492:	dce080e7          	jalr	-562(ra) # 8000325c <bwrite>
    brelse(from);
    80004496:	854e                	mv	a0,s3
    80004498:	fffff097          	auipc	ra,0xfffff
    8000449c:	e02080e7          	jalr	-510(ra) # 8000329a <brelse>
    brelse(to);
    800044a0:	8526                	mv	a0,s1
    800044a2:	fffff097          	auipc	ra,0xfffff
    800044a6:	df8080e7          	jalr	-520(ra) # 8000329a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044aa:	2905                	addw	s2,s2,1
    800044ac:	0a91                	add	s5,s5,4
    800044ae:	02ca2783          	lw	a5,44(s4)
    800044b2:	f8f94ee3          	blt	s2,a5,8000444e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044b6:	00000097          	auipc	ra,0x0
    800044ba:	c9c080e7          	jalr	-868(ra) # 80004152 <write_head>
    install_trans(); // Now install writes to home locations
    800044be:	00000097          	auipc	ra,0x0
    800044c2:	cfe080e7          	jalr	-770(ra) # 800041bc <install_trans>
    log.lh.n = 0;
    800044c6:	00025797          	auipc	a5,0x25
    800044ca:	4607a723          	sw	zero,1134(a5) # 80029934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044ce:	00000097          	auipc	ra,0x0
    800044d2:	c84080e7          	jalr	-892(ra) # 80004152 <write_head>
    800044d6:	bdfd                	j	800043d4 <end_op+0x52>

00000000800044d8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044d8:	1101                	add	sp,sp,-32
    800044da:	ec06                	sd	ra,24(sp)
    800044dc:	e822                	sd	s0,16(sp)
    800044de:	e426                	sd	s1,8(sp)
    800044e0:	e04a                	sd	s2,0(sp)
    800044e2:	1000                	add	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044e4:	00025717          	auipc	a4,0x25
    800044e8:	45072703          	lw	a4,1104(a4) # 80029934 <log+0x2c>
    800044ec:	47f5                	li	a5,29
    800044ee:	08e7c063          	blt	a5,a4,8000456e <log_write+0x96>
    800044f2:	84aa                	mv	s1,a0
    800044f4:	00025797          	auipc	a5,0x25
    800044f8:	4307a783          	lw	a5,1072(a5) # 80029924 <log+0x1c>
    800044fc:	37fd                	addw	a5,a5,-1
    800044fe:	06f75863          	bge	a4,a5,8000456e <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004502:	00025797          	auipc	a5,0x25
    80004506:	4267a783          	lw	a5,1062(a5) # 80029928 <log+0x20>
    8000450a:	06f05a63          	blez	a5,8000457e <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000450e:	00025917          	auipc	s2,0x25
    80004512:	3fa90913          	add	s2,s2,1018 # 80029908 <log>
    80004516:	854a                	mv	a0,s2
    80004518:	ffffc097          	auipc	ra,0xffffc
    8000451c:	7ce080e7          	jalr	1998(ra) # 80000ce6 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004520:	02c92603          	lw	a2,44(s2)
    80004524:	06c05563          	blez	a2,8000458e <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004528:	44cc                	lw	a1,12(s1)
    8000452a:	00025717          	auipc	a4,0x25
    8000452e:	40e70713          	add	a4,a4,1038 # 80029938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004532:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004534:	4314                	lw	a3,0(a4)
    80004536:	04b68d63          	beq	a3,a1,80004590 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000453a:	2785                	addw	a5,a5,1
    8000453c:	0711                	add	a4,a4,4
    8000453e:	fec79be3          	bne	a5,a2,80004534 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004542:	0621                	add	a2,a2,8
    80004544:	060a                	sll	a2,a2,0x2
    80004546:	00025797          	auipc	a5,0x25
    8000454a:	3c278793          	add	a5,a5,962 # 80029908 <log>
    8000454e:	97b2                	add	a5,a5,a2
    80004550:	44d8                	lw	a4,12(s1)
    80004552:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004554:	8526                	mv	a0,s1
    80004556:	fffff097          	auipc	ra,0xfffff
    8000455a:	de0080e7          	jalr	-544(ra) # 80003336 <bpin>
    log.lh.n++;
    8000455e:	00025717          	auipc	a4,0x25
    80004562:	3aa70713          	add	a4,a4,938 # 80029908 <log>
    80004566:	575c                	lw	a5,44(a4)
    80004568:	2785                	addw	a5,a5,1
    8000456a:	d75c                	sw	a5,44(a4)
    8000456c:	a835                	j	800045a8 <log_write+0xd0>
    panic("too big a transaction");
    8000456e:	00004517          	auipc	a0,0x4
    80004572:	0aa50513          	add	a0,a0,170 # 80008618 <syscalls+0x1f0>
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	fcc080e7          	jalr	-52(ra) # 80000542 <panic>
    panic("log_write outside of trans");
    8000457e:	00004517          	auipc	a0,0x4
    80004582:	0b250513          	add	a0,a0,178 # 80008630 <syscalls+0x208>
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	fbc080e7          	jalr	-68(ra) # 80000542 <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000458e:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004590:	00878693          	add	a3,a5,8
    80004594:	068a                	sll	a3,a3,0x2
    80004596:	00025717          	auipc	a4,0x25
    8000459a:	37270713          	add	a4,a4,882 # 80029908 <log>
    8000459e:	9736                	add	a4,a4,a3
    800045a0:	44d4                	lw	a3,12(s1)
    800045a2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045a4:	faf608e3          	beq	a2,a5,80004554 <log_write+0x7c>
  }
  release(&log.lock);
    800045a8:	00025517          	auipc	a0,0x25
    800045ac:	36050513          	add	a0,a0,864 # 80029908 <log>
    800045b0:	ffffc097          	auipc	ra,0xffffc
    800045b4:	7ea080e7          	jalr	2026(ra) # 80000d9a <release>
}
    800045b8:	60e2                	ld	ra,24(sp)
    800045ba:	6442                	ld	s0,16(sp)
    800045bc:	64a2                	ld	s1,8(sp)
    800045be:	6902                	ld	s2,0(sp)
    800045c0:	6105                	add	sp,sp,32
    800045c2:	8082                	ret

00000000800045c4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045c4:	1101                	add	sp,sp,-32
    800045c6:	ec06                	sd	ra,24(sp)
    800045c8:	e822                	sd	s0,16(sp)
    800045ca:	e426                	sd	s1,8(sp)
    800045cc:	e04a                	sd	s2,0(sp)
    800045ce:	1000                	add	s0,sp,32
    800045d0:	84aa                	mv	s1,a0
    800045d2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045d4:	00004597          	auipc	a1,0x4
    800045d8:	07c58593          	add	a1,a1,124 # 80008650 <syscalls+0x228>
    800045dc:	0521                	add	a0,a0,8
    800045de:	ffffc097          	auipc	ra,0xffffc
    800045e2:	678080e7          	jalr	1656(ra) # 80000c56 <initlock>
  lk->name = name;
    800045e6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045ea:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045ee:	0204a423          	sw	zero,40(s1)
}
    800045f2:	60e2                	ld	ra,24(sp)
    800045f4:	6442                	ld	s0,16(sp)
    800045f6:	64a2                	ld	s1,8(sp)
    800045f8:	6902                	ld	s2,0(sp)
    800045fa:	6105                	add	sp,sp,32
    800045fc:	8082                	ret

00000000800045fe <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045fe:	1101                	add	sp,sp,-32
    80004600:	ec06                	sd	ra,24(sp)
    80004602:	e822                	sd	s0,16(sp)
    80004604:	e426                	sd	s1,8(sp)
    80004606:	e04a                	sd	s2,0(sp)
    80004608:	1000                	add	s0,sp,32
    8000460a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000460c:	00850913          	add	s2,a0,8
    80004610:	854a                	mv	a0,s2
    80004612:	ffffc097          	auipc	ra,0xffffc
    80004616:	6d4080e7          	jalr	1748(ra) # 80000ce6 <acquire>
  while (lk->locked) {
    8000461a:	409c                	lw	a5,0(s1)
    8000461c:	cb89                	beqz	a5,8000462e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000461e:	85ca                	mv	a1,s2
    80004620:	8526                	mv	a0,s1
    80004622:	ffffe097          	auipc	ra,0xffffe
    80004626:	efe080e7          	jalr	-258(ra) # 80002520 <sleep>
  while (lk->locked) {
    8000462a:	409c                	lw	a5,0(s1)
    8000462c:	fbed                	bnez	a5,8000461e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000462e:	4785                	li	a5,1
    80004630:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004632:	ffffd097          	auipc	ra,0xffffd
    80004636:	6d8080e7          	jalr	1752(ra) # 80001d0a <myproc>
    8000463a:	5d1c                	lw	a5,56(a0)
    8000463c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000463e:	854a                	mv	a0,s2
    80004640:	ffffc097          	auipc	ra,0xffffc
    80004644:	75a080e7          	jalr	1882(ra) # 80000d9a <release>
}
    80004648:	60e2                	ld	ra,24(sp)
    8000464a:	6442                	ld	s0,16(sp)
    8000464c:	64a2                	ld	s1,8(sp)
    8000464e:	6902                	ld	s2,0(sp)
    80004650:	6105                	add	sp,sp,32
    80004652:	8082                	ret

0000000080004654 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004654:	1101                	add	sp,sp,-32
    80004656:	ec06                	sd	ra,24(sp)
    80004658:	e822                	sd	s0,16(sp)
    8000465a:	e426                	sd	s1,8(sp)
    8000465c:	e04a                	sd	s2,0(sp)
    8000465e:	1000                	add	s0,sp,32
    80004660:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004662:	00850913          	add	s2,a0,8
    80004666:	854a                	mv	a0,s2
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	67e080e7          	jalr	1662(ra) # 80000ce6 <acquire>
  lk->locked = 0;
    80004670:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004674:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004678:	8526                	mv	a0,s1
    8000467a:	ffffe097          	auipc	ra,0xffffe
    8000467e:	026080e7          	jalr	38(ra) # 800026a0 <wakeup>
  release(&lk->lk);
    80004682:	854a                	mv	a0,s2
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	716080e7          	jalr	1814(ra) # 80000d9a <release>
}
    8000468c:	60e2                	ld	ra,24(sp)
    8000468e:	6442                	ld	s0,16(sp)
    80004690:	64a2                	ld	s1,8(sp)
    80004692:	6902                	ld	s2,0(sp)
    80004694:	6105                	add	sp,sp,32
    80004696:	8082                	ret

0000000080004698 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004698:	7179                	add	sp,sp,-48
    8000469a:	f406                	sd	ra,40(sp)
    8000469c:	f022                	sd	s0,32(sp)
    8000469e:	ec26                	sd	s1,24(sp)
    800046a0:	e84a                	sd	s2,16(sp)
    800046a2:	e44e                	sd	s3,8(sp)
    800046a4:	1800                	add	s0,sp,48
    800046a6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046a8:	00850913          	add	s2,a0,8
    800046ac:	854a                	mv	a0,s2
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	638080e7          	jalr	1592(ra) # 80000ce6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046b6:	409c                	lw	a5,0(s1)
    800046b8:	ef99                	bnez	a5,800046d6 <holdingsleep+0x3e>
    800046ba:	4481                	li	s1,0
  release(&lk->lk);
    800046bc:	854a                	mv	a0,s2
    800046be:	ffffc097          	auipc	ra,0xffffc
    800046c2:	6dc080e7          	jalr	1756(ra) # 80000d9a <release>
  return r;
}
    800046c6:	8526                	mv	a0,s1
    800046c8:	70a2                	ld	ra,40(sp)
    800046ca:	7402                	ld	s0,32(sp)
    800046cc:	64e2                	ld	s1,24(sp)
    800046ce:	6942                	ld	s2,16(sp)
    800046d0:	69a2                	ld	s3,8(sp)
    800046d2:	6145                	add	sp,sp,48
    800046d4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046d6:	0284a983          	lw	s3,40(s1)
    800046da:	ffffd097          	auipc	ra,0xffffd
    800046de:	630080e7          	jalr	1584(ra) # 80001d0a <myproc>
    800046e2:	5d04                	lw	s1,56(a0)
    800046e4:	413484b3          	sub	s1,s1,s3
    800046e8:	0014b493          	seqz	s1,s1
    800046ec:	bfc1                	j	800046bc <holdingsleep+0x24>

00000000800046ee <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046ee:	1141                	add	sp,sp,-16
    800046f0:	e406                	sd	ra,8(sp)
    800046f2:	e022                	sd	s0,0(sp)
    800046f4:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046f6:	00004597          	auipc	a1,0x4
    800046fa:	f6a58593          	add	a1,a1,-150 # 80008660 <syscalls+0x238>
    800046fe:	00025517          	auipc	a0,0x25
    80004702:	35250513          	add	a0,a0,850 # 80029a50 <ftable>
    80004706:	ffffc097          	auipc	ra,0xffffc
    8000470a:	550080e7          	jalr	1360(ra) # 80000c56 <initlock>
}
    8000470e:	60a2                	ld	ra,8(sp)
    80004710:	6402                	ld	s0,0(sp)
    80004712:	0141                	add	sp,sp,16
    80004714:	8082                	ret

0000000080004716 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004716:	1101                	add	sp,sp,-32
    80004718:	ec06                	sd	ra,24(sp)
    8000471a:	e822                	sd	s0,16(sp)
    8000471c:	e426                	sd	s1,8(sp)
    8000471e:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004720:	00025517          	auipc	a0,0x25
    80004724:	33050513          	add	a0,a0,816 # 80029a50 <ftable>
    80004728:	ffffc097          	auipc	ra,0xffffc
    8000472c:	5be080e7          	jalr	1470(ra) # 80000ce6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004730:	00025497          	auipc	s1,0x25
    80004734:	33848493          	add	s1,s1,824 # 80029a68 <ftable+0x18>
    80004738:	00026717          	auipc	a4,0x26
    8000473c:	2d070713          	add	a4,a4,720 # 8002aa08 <ftable+0xfb8>
    if(f->ref == 0){
    80004740:	40dc                	lw	a5,4(s1)
    80004742:	cf99                	beqz	a5,80004760 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004744:	02848493          	add	s1,s1,40
    80004748:	fee49ce3          	bne	s1,a4,80004740 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000474c:	00025517          	auipc	a0,0x25
    80004750:	30450513          	add	a0,a0,772 # 80029a50 <ftable>
    80004754:	ffffc097          	auipc	ra,0xffffc
    80004758:	646080e7          	jalr	1606(ra) # 80000d9a <release>
  return 0;
    8000475c:	4481                	li	s1,0
    8000475e:	a819                	j	80004774 <filealloc+0x5e>
      f->ref = 1;
    80004760:	4785                	li	a5,1
    80004762:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004764:	00025517          	auipc	a0,0x25
    80004768:	2ec50513          	add	a0,a0,748 # 80029a50 <ftable>
    8000476c:	ffffc097          	auipc	ra,0xffffc
    80004770:	62e080e7          	jalr	1582(ra) # 80000d9a <release>
}
    80004774:	8526                	mv	a0,s1
    80004776:	60e2                	ld	ra,24(sp)
    80004778:	6442                	ld	s0,16(sp)
    8000477a:	64a2                	ld	s1,8(sp)
    8000477c:	6105                	add	sp,sp,32
    8000477e:	8082                	ret

0000000080004780 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004780:	1101                	add	sp,sp,-32
    80004782:	ec06                	sd	ra,24(sp)
    80004784:	e822                	sd	s0,16(sp)
    80004786:	e426                	sd	s1,8(sp)
    80004788:	1000                	add	s0,sp,32
    8000478a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000478c:	00025517          	auipc	a0,0x25
    80004790:	2c450513          	add	a0,a0,708 # 80029a50 <ftable>
    80004794:	ffffc097          	auipc	ra,0xffffc
    80004798:	552080e7          	jalr	1362(ra) # 80000ce6 <acquire>
  if(f->ref < 1)
    8000479c:	40dc                	lw	a5,4(s1)
    8000479e:	02f05263          	blez	a5,800047c2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047a2:	2785                	addw	a5,a5,1
    800047a4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047a6:	00025517          	auipc	a0,0x25
    800047aa:	2aa50513          	add	a0,a0,682 # 80029a50 <ftable>
    800047ae:	ffffc097          	auipc	ra,0xffffc
    800047b2:	5ec080e7          	jalr	1516(ra) # 80000d9a <release>
  return f;
}
    800047b6:	8526                	mv	a0,s1
    800047b8:	60e2                	ld	ra,24(sp)
    800047ba:	6442                	ld	s0,16(sp)
    800047bc:	64a2                	ld	s1,8(sp)
    800047be:	6105                	add	sp,sp,32
    800047c0:	8082                	ret
    panic("filedup");
    800047c2:	00004517          	auipc	a0,0x4
    800047c6:	ea650513          	add	a0,a0,-346 # 80008668 <syscalls+0x240>
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	d78080e7          	jalr	-648(ra) # 80000542 <panic>

00000000800047d2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047d2:	7139                	add	sp,sp,-64
    800047d4:	fc06                	sd	ra,56(sp)
    800047d6:	f822                	sd	s0,48(sp)
    800047d8:	f426                	sd	s1,40(sp)
    800047da:	f04a                	sd	s2,32(sp)
    800047dc:	ec4e                	sd	s3,24(sp)
    800047de:	e852                	sd	s4,16(sp)
    800047e0:	e456                	sd	s5,8(sp)
    800047e2:	0080                	add	s0,sp,64
    800047e4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047e6:	00025517          	auipc	a0,0x25
    800047ea:	26a50513          	add	a0,a0,618 # 80029a50 <ftable>
    800047ee:	ffffc097          	auipc	ra,0xffffc
    800047f2:	4f8080e7          	jalr	1272(ra) # 80000ce6 <acquire>
  if(f->ref < 1)
    800047f6:	40dc                	lw	a5,4(s1)
    800047f8:	06f05163          	blez	a5,8000485a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047fc:	37fd                	addw	a5,a5,-1
    800047fe:	0007871b          	sext.w	a4,a5
    80004802:	c0dc                	sw	a5,4(s1)
    80004804:	06e04363          	bgtz	a4,8000486a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004808:	0004a903          	lw	s2,0(s1)
    8000480c:	0094ca83          	lbu	s5,9(s1)
    80004810:	0104ba03          	ld	s4,16(s1)
    80004814:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004818:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000481c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004820:	00025517          	auipc	a0,0x25
    80004824:	23050513          	add	a0,a0,560 # 80029a50 <ftable>
    80004828:	ffffc097          	auipc	ra,0xffffc
    8000482c:	572080e7          	jalr	1394(ra) # 80000d9a <release>

  if(ff.type == FD_PIPE){
    80004830:	4785                	li	a5,1
    80004832:	04f90d63          	beq	s2,a5,8000488c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004836:	3979                	addw	s2,s2,-2
    80004838:	4785                	li	a5,1
    8000483a:	0527e063          	bltu	a5,s2,8000487a <fileclose+0xa8>
    begin_op();
    8000483e:	00000097          	auipc	ra,0x0
    80004842:	aca080e7          	jalr	-1334(ra) # 80004308 <begin_op>
    iput(ff.ip);
    80004846:	854e                	mv	a0,s3
    80004848:	fffff097          	auipc	ra,0xfffff
    8000484c:	2d6080e7          	jalr	726(ra) # 80003b1e <iput>
    end_op();
    80004850:	00000097          	auipc	ra,0x0
    80004854:	b32080e7          	jalr	-1230(ra) # 80004382 <end_op>
    80004858:	a00d                	j	8000487a <fileclose+0xa8>
    panic("fileclose");
    8000485a:	00004517          	auipc	a0,0x4
    8000485e:	e1650513          	add	a0,a0,-490 # 80008670 <syscalls+0x248>
    80004862:	ffffc097          	auipc	ra,0xffffc
    80004866:	ce0080e7          	jalr	-800(ra) # 80000542 <panic>
    release(&ftable.lock);
    8000486a:	00025517          	auipc	a0,0x25
    8000486e:	1e650513          	add	a0,a0,486 # 80029a50 <ftable>
    80004872:	ffffc097          	auipc	ra,0xffffc
    80004876:	528080e7          	jalr	1320(ra) # 80000d9a <release>
  }
}
    8000487a:	70e2                	ld	ra,56(sp)
    8000487c:	7442                	ld	s0,48(sp)
    8000487e:	74a2                	ld	s1,40(sp)
    80004880:	7902                	ld	s2,32(sp)
    80004882:	69e2                	ld	s3,24(sp)
    80004884:	6a42                	ld	s4,16(sp)
    80004886:	6aa2                	ld	s5,8(sp)
    80004888:	6121                	add	sp,sp,64
    8000488a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000488c:	85d6                	mv	a1,s5
    8000488e:	8552                	mv	a0,s4
    80004890:	00000097          	auipc	ra,0x0
    80004894:	372080e7          	jalr	882(ra) # 80004c02 <pipeclose>
    80004898:	b7cd                	j	8000487a <fileclose+0xa8>

000000008000489a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000489a:	715d                	add	sp,sp,-80
    8000489c:	e486                	sd	ra,72(sp)
    8000489e:	e0a2                	sd	s0,64(sp)
    800048a0:	fc26                	sd	s1,56(sp)
    800048a2:	f84a                	sd	s2,48(sp)
    800048a4:	f44e                	sd	s3,40(sp)
    800048a6:	0880                	add	s0,sp,80
    800048a8:	84aa                	mv	s1,a0
    800048aa:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048ac:	ffffd097          	auipc	ra,0xffffd
    800048b0:	45e080e7          	jalr	1118(ra) # 80001d0a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048b4:	409c                	lw	a5,0(s1)
    800048b6:	37f9                	addw	a5,a5,-2
    800048b8:	4705                	li	a4,1
    800048ba:	04f76763          	bltu	a4,a5,80004908 <filestat+0x6e>
    800048be:	892a                	mv	s2,a0
    ilock(f->ip);
    800048c0:	6c88                	ld	a0,24(s1)
    800048c2:	fffff097          	auipc	ra,0xfffff
    800048c6:	0a2080e7          	jalr	162(ra) # 80003964 <ilock>
    stati(f->ip, &st);
    800048ca:	fb840593          	add	a1,s0,-72
    800048ce:	6c88                	ld	a0,24(s1)
    800048d0:	fffff097          	auipc	ra,0xfffff
    800048d4:	31e080e7          	jalr	798(ra) # 80003bee <stati>
    iunlock(f->ip);
    800048d8:	6c88                	ld	a0,24(s1)
    800048da:	fffff097          	auipc	ra,0xfffff
    800048de:	14c080e7          	jalr	332(ra) # 80003a26 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048e2:	46e1                	li	a3,24
    800048e4:	fb840613          	add	a2,s0,-72
    800048e8:	85ce                	mv	a1,s3
    800048ea:	05093503          	ld	a0,80(s2)
    800048ee:	ffffd097          	auipc	ra,0xffffd
    800048f2:	0ee080e7          	jalr	238(ra) # 800019dc <copyout>
    800048f6:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048fa:	60a6                	ld	ra,72(sp)
    800048fc:	6406                	ld	s0,64(sp)
    800048fe:	74e2                	ld	s1,56(sp)
    80004900:	7942                	ld	s2,48(sp)
    80004902:	79a2                	ld	s3,40(sp)
    80004904:	6161                	add	sp,sp,80
    80004906:	8082                	ret
  return -1;
    80004908:	557d                	li	a0,-1
    8000490a:	bfc5                	j	800048fa <filestat+0x60>

000000008000490c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000490c:	7179                	add	sp,sp,-48
    8000490e:	f406                	sd	ra,40(sp)
    80004910:	f022                	sd	s0,32(sp)
    80004912:	ec26                	sd	s1,24(sp)
    80004914:	e84a                	sd	s2,16(sp)
    80004916:	e44e                	sd	s3,8(sp)
    80004918:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000491a:	00854783          	lbu	a5,8(a0)
    8000491e:	c3d5                	beqz	a5,800049c2 <fileread+0xb6>
    80004920:	84aa                	mv	s1,a0
    80004922:	89ae                	mv	s3,a1
    80004924:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004926:	411c                	lw	a5,0(a0)
    80004928:	4705                	li	a4,1
    8000492a:	04e78963          	beq	a5,a4,8000497c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000492e:	470d                	li	a4,3
    80004930:	04e78d63          	beq	a5,a4,8000498a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004934:	4709                	li	a4,2
    80004936:	06e79e63          	bne	a5,a4,800049b2 <fileread+0xa6>
    ilock(f->ip);
    8000493a:	6d08                	ld	a0,24(a0)
    8000493c:	fffff097          	auipc	ra,0xfffff
    80004940:	028080e7          	jalr	40(ra) # 80003964 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004944:	874a                	mv	a4,s2
    80004946:	5094                	lw	a3,32(s1)
    80004948:	864e                	mv	a2,s3
    8000494a:	4585                	li	a1,1
    8000494c:	6c88                	ld	a0,24(s1)
    8000494e:	fffff097          	auipc	ra,0xfffff
    80004952:	2ca080e7          	jalr	714(ra) # 80003c18 <readi>
    80004956:	892a                	mv	s2,a0
    80004958:	00a05563          	blez	a0,80004962 <fileread+0x56>
      f->off += r;
    8000495c:	509c                	lw	a5,32(s1)
    8000495e:	9fa9                	addw	a5,a5,a0
    80004960:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004962:	6c88                	ld	a0,24(s1)
    80004964:	fffff097          	auipc	ra,0xfffff
    80004968:	0c2080e7          	jalr	194(ra) # 80003a26 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000496c:	854a                	mv	a0,s2
    8000496e:	70a2                	ld	ra,40(sp)
    80004970:	7402                	ld	s0,32(sp)
    80004972:	64e2                	ld	s1,24(sp)
    80004974:	6942                	ld	s2,16(sp)
    80004976:	69a2                	ld	s3,8(sp)
    80004978:	6145                	add	sp,sp,48
    8000497a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000497c:	6908                	ld	a0,16(a0)
    8000497e:	00000097          	auipc	ra,0x0
    80004982:	3ee080e7          	jalr	1006(ra) # 80004d6c <piperead>
    80004986:	892a                	mv	s2,a0
    80004988:	b7d5                	j	8000496c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000498a:	02451783          	lh	a5,36(a0)
    8000498e:	03079693          	sll	a3,a5,0x30
    80004992:	92c1                	srl	a3,a3,0x30
    80004994:	4725                	li	a4,9
    80004996:	02d76863          	bltu	a4,a3,800049c6 <fileread+0xba>
    8000499a:	0792                	sll	a5,a5,0x4
    8000499c:	00025717          	auipc	a4,0x25
    800049a0:	01470713          	add	a4,a4,20 # 800299b0 <devsw>
    800049a4:	97ba                	add	a5,a5,a4
    800049a6:	639c                	ld	a5,0(a5)
    800049a8:	c38d                	beqz	a5,800049ca <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049aa:	4505                	li	a0,1
    800049ac:	9782                	jalr	a5
    800049ae:	892a                	mv	s2,a0
    800049b0:	bf75                	j	8000496c <fileread+0x60>
    panic("fileread");
    800049b2:	00004517          	auipc	a0,0x4
    800049b6:	cce50513          	add	a0,a0,-818 # 80008680 <syscalls+0x258>
    800049ba:	ffffc097          	auipc	ra,0xffffc
    800049be:	b88080e7          	jalr	-1144(ra) # 80000542 <panic>
    return -1;
    800049c2:	597d                	li	s2,-1
    800049c4:	b765                	j	8000496c <fileread+0x60>
      return -1;
    800049c6:	597d                	li	s2,-1
    800049c8:	b755                	j	8000496c <fileread+0x60>
    800049ca:	597d                	li	s2,-1
    800049cc:	b745                	j	8000496c <fileread+0x60>

00000000800049ce <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800049ce:	00954783          	lbu	a5,9(a0)
    800049d2:	14078363          	beqz	a5,80004b18 <filewrite+0x14a>
{
    800049d6:	715d                	add	sp,sp,-80
    800049d8:	e486                	sd	ra,72(sp)
    800049da:	e0a2                	sd	s0,64(sp)
    800049dc:	fc26                	sd	s1,56(sp)
    800049de:	f84a                	sd	s2,48(sp)
    800049e0:	f44e                	sd	s3,40(sp)
    800049e2:	f052                	sd	s4,32(sp)
    800049e4:	ec56                	sd	s5,24(sp)
    800049e6:	e85a                	sd	s6,16(sp)
    800049e8:	e45e                	sd	s7,8(sp)
    800049ea:	e062                	sd	s8,0(sp)
    800049ec:	0880                	add	s0,sp,80
    800049ee:	892a                	mv	s2,a0
    800049f0:	8b2e                	mv	s6,a1
    800049f2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049f4:	411c                	lw	a5,0(a0)
    800049f6:	4705                	li	a4,1
    800049f8:	02e78263          	beq	a5,a4,80004a1c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049fc:	470d                	li	a4,3
    800049fe:	02e78563          	beq	a5,a4,80004a28 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a02:	4709                	li	a4,2
    80004a04:	10e79263          	bne	a5,a4,80004b08 <filewrite+0x13a>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a08:	0ec05e63          	blez	a2,80004b04 <filewrite+0x136>
    int i = 0;
    80004a0c:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004a0e:	6b85                	lui	s7,0x1
    80004a10:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004a14:	6c05                	lui	s8,0x1
    80004a16:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004a1a:	a851                	j	80004aae <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004a1c:	6908                	ld	a0,16(a0)
    80004a1e:	00000097          	auipc	ra,0x0
    80004a22:	254080e7          	jalr	596(ra) # 80004c72 <pipewrite>
    80004a26:	a85d                	j	80004adc <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a28:	02451783          	lh	a5,36(a0)
    80004a2c:	03079693          	sll	a3,a5,0x30
    80004a30:	92c1                	srl	a3,a3,0x30
    80004a32:	4725                	li	a4,9
    80004a34:	0ed76463          	bltu	a4,a3,80004b1c <filewrite+0x14e>
    80004a38:	0792                	sll	a5,a5,0x4
    80004a3a:	00025717          	auipc	a4,0x25
    80004a3e:	f7670713          	add	a4,a4,-138 # 800299b0 <devsw>
    80004a42:	97ba                	add	a5,a5,a4
    80004a44:	679c                	ld	a5,8(a5)
    80004a46:	cfe9                	beqz	a5,80004b20 <filewrite+0x152>
    ret = devsw[f->major].write(1, addr, n);
    80004a48:	4505                	li	a0,1
    80004a4a:	9782                	jalr	a5
    80004a4c:	a841                	j	80004adc <filewrite+0x10e>
      if(n1 > max)
    80004a4e:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004a52:	00000097          	auipc	ra,0x0
    80004a56:	8b6080e7          	jalr	-1866(ra) # 80004308 <begin_op>
      ilock(f->ip);
    80004a5a:	01893503          	ld	a0,24(s2)
    80004a5e:	fffff097          	auipc	ra,0xfffff
    80004a62:	f06080e7          	jalr	-250(ra) # 80003964 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a66:	8756                	mv	a4,s5
    80004a68:	02092683          	lw	a3,32(s2)
    80004a6c:	01698633          	add	a2,s3,s6
    80004a70:	4585                	li	a1,1
    80004a72:	01893503          	ld	a0,24(s2)
    80004a76:	fffff097          	auipc	ra,0xfffff
    80004a7a:	29a080e7          	jalr	666(ra) # 80003d10 <writei>
    80004a7e:	84aa                	mv	s1,a0
    80004a80:	02a05f63          	blez	a0,80004abe <filewrite+0xf0>
        f->off += r;
    80004a84:	02092783          	lw	a5,32(s2)
    80004a88:	9fa9                	addw	a5,a5,a0
    80004a8a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a8e:	01893503          	ld	a0,24(s2)
    80004a92:	fffff097          	auipc	ra,0xfffff
    80004a96:	f94080e7          	jalr	-108(ra) # 80003a26 <iunlock>
      end_op();
    80004a9a:	00000097          	auipc	ra,0x0
    80004a9e:	8e8080e7          	jalr	-1816(ra) # 80004382 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004aa2:	049a9963          	bne	s5,s1,80004af4 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004aa6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004aaa:	0349d663          	bge	s3,s4,80004ad6 <filewrite+0x108>
      int n1 = n - i;
    80004aae:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004ab2:	0004879b          	sext.w	a5,s1
    80004ab6:	f8fbdce3          	bge	s7,a5,80004a4e <filewrite+0x80>
    80004aba:	84e2                	mv	s1,s8
    80004abc:	bf49                	j	80004a4e <filewrite+0x80>
      iunlock(f->ip);
    80004abe:	01893503          	ld	a0,24(s2)
    80004ac2:	fffff097          	auipc	ra,0xfffff
    80004ac6:	f64080e7          	jalr	-156(ra) # 80003a26 <iunlock>
      end_op();
    80004aca:	00000097          	auipc	ra,0x0
    80004ace:	8b8080e7          	jalr	-1864(ra) # 80004382 <end_op>
      if(r < 0)
    80004ad2:	fc04d8e3          	bgez	s1,80004aa2 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004ad6:	053a1763          	bne	s4,s3,80004b24 <filewrite+0x156>
    80004ada:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004adc:	60a6                	ld	ra,72(sp)
    80004ade:	6406                	ld	s0,64(sp)
    80004ae0:	74e2                	ld	s1,56(sp)
    80004ae2:	7942                	ld	s2,48(sp)
    80004ae4:	79a2                	ld	s3,40(sp)
    80004ae6:	7a02                	ld	s4,32(sp)
    80004ae8:	6ae2                	ld	s5,24(sp)
    80004aea:	6b42                	ld	s6,16(sp)
    80004aec:	6ba2                	ld	s7,8(sp)
    80004aee:	6c02                	ld	s8,0(sp)
    80004af0:	6161                	add	sp,sp,80
    80004af2:	8082                	ret
        panic("short filewrite");
    80004af4:	00004517          	auipc	a0,0x4
    80004af8:	b9c50513          	add	a0,a0,-1124 # 80008690 <syscalls+0x268>
    80004afc:	ffffc097          	auipc	ra,0xffffc
    80004b00:	a46080e7          	jalr	-1466(ra) # 80000542 <panic>
    int i = 0;
    80004b04:	4981                	li	s3,0
    80004b06:	bfc1                	j	80004ad6 <filewrite+0x108>
    panic("filewrite");
    80004b08:	00004517          	auipc	a0,0x4
    80004b0c:	b9850513          	add	a0,a0,-1128 # 800086a0 <syscalls+0x278>
    80004b10:	ffffc097          	auipc	ra,0xffffc
    80004b14:	a32080e7          	jalr	-1486(ra) # 80000542 <panic>
    return -1;
    80004b18:	557d                	li	a0,-1
}
    80004b1a:	8082                	ret
      return -1;
    80004b1c:	557d                	li	a0,-1
    80004b1e:	bf7d                	j	80004adc <filewrite+0x10e>
    80004b20:	557d                	li	a0,-1
    80004b22:	bf6d                	j	80004adc <filewrite+0x10e>
    ret = (i == n ? n : -1);
    80004b24:	557d                	li	a0,-1
    80004b26:	bf5d                	j	80004adc <filewrite+0x10e>

0000000080004b28 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b28:	7179                	add	sp,sp,-48
    80004b2a:	f406                	sd	ra,40(sp)
    80004b2c:	f022                	sd	s0,32(sp)
    80004b2e:	ec26                	sd	s1,24(sp)
    80004b30:	e84a                	sd	s2,16(sp)
    80004b32:	e44e                	sd	s3,8(sp)
    80004b34:	e052                	sd	s4,0(sp)
    80004b36:	1800                	add	s0,sp,48
    80004b38:	84aa                	mv	s1,a0
    80004b3a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b3c:	0005b023          	sd	zero,0(a1)
    80004b40:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b44:	00000097          	auipc	ra,0x0
    80004b48:	bd2080e7          	jalr	-1070(ra) # 80004716 <filealloc>
    80004b4c:	e088                	sd	a0,0(s1)
    80004b4e:	c551                	beqz	a0,80004bda <pipealloc+0xb2>
    80004b50:	00000097          	auipc	ra,0x0
    80004b54:	bc6080e7          	jalr	-1082(ra) # 80004716 <filealloc>
    80004b58:	00aa3023          	sd	a0,0(s4)
    80004b5c:	c92d                	beqz	a0,80004bce <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b5e:	ffffc097          	auipc	ra,0xffffc
    80004b62:	08c080e7          	jalr	140(ra) # 80000bea <kalloc>
    80004b66:	892a                	mv	s2,a0
    80004b68:	c125                	beqz	a0,80004bc8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b6a:	4985                	li	s3,1
    80004b6c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b70:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b74:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b78:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b7c:	00004597          	auipc	a1,0x4
    80004b80:	b3458593          	add	a1,a1,-1228 # 800086b0 <syscalls+0x288>
    80004b84:	ffffc097          	auipc	ra,0xffffc
    80004b88:	0d2080e7          	jalr	210(ra) # 80000c56 <initlock>
  (*f0)->type = FD_PIPE;
    80004b8c:	609c                	ld	a5,0(s1)
    80004b8e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b92:	609c                	ld	a5,0(s1)
    80004b94:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b98:	609c                	ld	a5,0(s1)
    80004b9a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b9e:	609c                	ld	a5,0(s1)
    80004ba0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ba4:	000a3783          	ld	a5,0(s4)
    80004ba8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bac:	000a3783          	ld	a5,0(s4)
    80004bb0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bb4:	000a3783          	ld	a5,0(s4)
    80004bb8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bbc:	000a3783          	ld	a5,0(s4)
    80004bc0:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bc4:	4501                	li	a0,0
    80004bc6:	a025                	j	80004bee <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bc8:	6088                	ld	a0,0(s1)
    80004bca:	e501                	bnez	a0,80004bd2 <pipealloc+0xaa>
    80004bcc:	a039                	j	80004bda <pipealloc+0xb2>
    80004bce:	6088                	ld	a0,0(s1)
    80004bd0:	c51d                	beqz	a0,80004bfe <pipealloc+0xd6>
    fileclose(*f0);
    80004bd2:	00000097          	auipc	ra,0x0
    80004bd6:	c00080e7          	jalr	-1024(ra) # 800047d2 <fileclose>
  if(*f1)
    80004bda:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004bde:	557d                	li	a0,-1
  if(*f1)
    80004be0:	c799                	beqz	a5,80004bee <pipealloc+0xc6>
    fileclose(*f1);
    80004be2:	853e                	mv	a0,a5
    80004be4:	00000097          	auipc	ra,0x0
    80004be8:	bee080e7          	jalr	-1042(ra) # 800047d2 <fileclose>
  return -1;
    80004bec:	557d                	li	a0,-1
}
    80004bee:	70a2                	ld	ra,40(sp)
    80004bf0:	7402                	ld	s0,32(sp)
    80004bf2:	64e2                	ld	s1,24(sp)
    80004bf4:	6942                	ld	s2,16(sp)
    80004bf6:	69a2                	ld	s3,8(sp)
    80004bf8:	6a02                	ld	s4,0(sp)
    80004bfa:	6145                	add	sp,sp,48
    80004bfc:	8082                	ret
  return -1;
    80004bfe:	557d                	li	a0,-1
    80004c00:	b7fd                	j	80004bee <pipealloc+0xc6>

0000000080004c02 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c02:	1101                	add	sp,sp,-32
    80004c04:	ec06                	sd	ra,24(sp)
    80004c06:	e822                	sd	s0,16(sp)
    80004c08:	e426                	sd	s1,8(sp)
    80004c0a:	e04a                	sd	s2,0(sp)
    80004c0c:	1000                	add	s0,sp,32
    80004c0e:	84aa                	mv	s1,a0
    80004c10:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c12:	ffffc097          	auipc	ra,0xffffc
    80004c16:	0d4080e7          	jalr	212(ra) # 80000ce6 <acquire>
  if(writable){
    80004c1a:	02090d63          	beqz	s2,80004c54 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c1e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c22:	21848513          	add	a0,s1,536
    80004c26:	ffffe097          	auipc	ra,0xffffe
    80004c2a:	a7a080e7          	jalr	-1414(ra) # 800026a0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c2e:	2204b783          	ld	a5,544(s1)
    80004c32:	eb95                	bnez	a5,80004c66 <pipeclose+0x64>
    release(&pi->lock);
    80004c34:	8526                	mv	a0,s1
    80004c36:	ffffc097          	auipc	ra,0xffffc
    80004c3a:	164080e7          	jalr	356(ra) # 80000d9a <release>
    kfree((char*)pi);
    80004c3e:	8526                	mv	a0,s1
    80004c40:	ffffc097          	auipc	ra,0xffffc
    80004c44:	e48080e7          	jalr	-440(ra) # 80000a88 <kfree>
  } else
    release(&pi->lock);
}
    80004c48:	60e2                	ld	ra,24(sp)
    80004c4a:	6442                	ld	s0,16(sp)
    80004c4c:	64a2                	ld	s1,8(sp)
    80004c4e:	6902                	ld	s2,0(sp)
    80004c50:	6105                	add	sp,sp,32
    80004c52:	8082                	ret
    pi->readopen = 0;
    80004c54:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c58:	21c48513          	add	a0,s1,540
    80004c5c:	ffffe097          	auipc	ra,0xffffe
    80004c60:	a44080e7          	jalr	-1468(ra) # 800026a0 <wakeup>
    80004c64:	b7e9                	j	80004c2e <pipeclose+0x2c>
    release(&pi->lock);
    80004c66:	8526                	mv	a0,s1
    80004c68:	ffffc097          	auipc	ra,0xffffc
    80004c6c:	132080e7          	jalr	306(ra) # 80000d9a <release>
}
    80004c70:	bfe1                	j	80004c48 <pipeclose+0x46>

0000000080004c72 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c72:	711d                	add	sp,sp,-96
    80004c74:	ec86                	sd	ra,88(sp)
    80004c76:	e8a2                	sd	s0,80(sp)
    80004c78:	e4a6                	sd	s1,72(sp)
    80004c7a:	e0ca                	sd	s2,64(sp)
    80004c7c:	fc4e                	sd	s3,56(sp)
    80004c7e:	f852                	sd	s4,48(sp)
    80004c80:	f456                	sd	s5,40(sp)
    80004c82:	f05a                	sd	s6,32(sp)
    80004c84:	ec5e                	sd	s7,24(sp)
    80004c86:	1080                	add	s0,sp,96
    80004c88:	84aa                	mv	s1,a0
    80004c8a:	8b2e                	mv	s6,a1
    80004c8c:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004c8e:	ffffd097          	auipc	ra,0xffffd
    80004c92:	07c080e7          	jalr	124(ra) # 80001d0a <myproc>
    80004c96:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004c98:	8526                	mv	a0,s1
    80004c9a:	ffffc097          	auipc	ra,0xffffc
    80004c9e:	04c080e7          	jalr	76(ra) # 80000ce6 <acquire>
  for(i = 0; i < n; i++){
    80004ca2:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004ca4:	21848a13          	add	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ca8:	21c48993          	add	s3,s1,540
  for(i = 0; i < n; i++){
    80004cac:	09505263          	blez	s5,80004d30 <pipewrite+0xbe>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004cb0:	2184a783          	lw	a5,536(s1)
    80004cb4:	21c4a703          	lw	a4,540(s1)
    80004cb8:	2007879b          	addw	a5,a5,512
    80004cbc:	02f71b63          	bne	a4,a5,80004cf2 <pipewrite+0x80>
      if(pi->readopen == 0 || pr->killed){
    80004cc0:	2204a783          	lw	a5,544(s1)
    80004cc4:	c3d1                	beqz	a5,80004d48 <pipewrite+0xd6>
    80004cc6:	03092783          	lw	a5,48(s2)
    80004cca:	efbd                	bnez	a5,80004d48 <pipewrite+0xd6>
      wakeup(&pi->nread);
    80004ccc:	8552                	mv	a0,s4
    80004cce:	ffffe097          	auipc	ra,0xffffe
    80004cd2:	9d2080e7          	jalr	-1582(ra) # 800026a0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004cd6:	85a6                	mv	a1,s1
    80004cd8:	854e                	mv	a0,s3
    80004cda:	ffffe097          	auipc	ra,0xffffe
    80004cde:	846080e7          	jalr	-1978(ra) # 80002520 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ce2:	2184a783          	lw	a5,536(s1)
    80004ce6:	21c4a703          	lw	a4,540(s1)
    80004cea:	2007879b          	addw	a5,a5,512
    80004cee:	fcf709e3          	beq	a4,a5,80004cc0 <pipewrite+0x4e>
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cf2:	4685                	li	a3,1
    80004cf4:	865a                	mv	a2,s6
    80004cf6:	faf40593          	add	a1,s0,-81
    80004cfa:	05093503          	ld	a0,80(s2)
    80004cfe:	ffffd097          	auipc	ra,0xffffd
    80004d02:	d8e080e7          	jalr	-626(ra) # 80001a8c <copyin>
    80004d06:	57fd                	li	a5,-1
    80004d08:	02f50463          	beq	a0,a5,80004d30 <pipewrite+0xbe>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d0c:	21c4a783          	lw	a5,540(s1)
    80004d10:	0017871b          	addw	a4,a5,1
    80004d14:	20e4ae23          	sw	a4,540(s1)
    80004d18:	1ff7f793          	and	a5,a5,511
    80004d1c:	97a6                	add	a5,a5,s1
    80004d1e:	faf44703          	lbu	a4,-81(s0)
    80004d22:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004d26:	2b85                	addw	s7,s7,1
    80004d28:	0b05                	add	s6,s6,1
    80004d2a:	f97a93e3          	bne	s5,s7,80004cb0 <pipewrite+0x3e>
    80004d2e:	8bd6                	mv	s7,s5
  }
  wakeup(&pi->nread);
    80004d30:	21848513          	add	a0,s1,536
    80004d34:	ffffe097          	auipc	ra,0xffffe
    80004d38:	96c080e7          	jalr	-1684(ra) # 800026a0 <wakeup>
  release(&pi->lock);
    80004d3c:	8526                	mv	a0,s1
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	05c080e7          	jalr	92(ra) # 80000d9a <release>
  return i;
    80004d46:	a039                	j	80004d54 <pipewrite+0xe2>
        release(&pi->lock);
    80004d48:	8526                	mv	a0,s1
    80004d4a:	ffffc097          	auipc	ra,0xffffc
    80004d4e:	050080e7          	jalr	80(ra) # 80000d9a <release>
        return -1;
    80004d52:	5bfd                	li	s7,-1
}
    80004d54:	855e                	mv	a0,s7
    80004d56:	60e6                	ld	ra,88(sp)
    80004d58:	6446                	ld	s0,80(sp)
    80004d5a:	64a6                	ld	s1,72(sp)
    80004d5c:	6906                	ld	s2,64(sp)
    80004d5e:	79e2                	ld	s3,56(sp)
    80004d60:	7a42                	ld	s4,48(sp)
    80004d62:	7aa2                	ld	s5,40(sp)
    80004d64:	7b02                	ld	s6,32(sp)
    80004d66:	6be2                	ld	s7,24(sp)
    80004d68:	6125                	add	sp,sp,96
    80004d6a:	8082                	ret

0000000080004d6c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d6c:	715d                	add	sp,sp,-80
    80004d6e:	e486                	sd	ra,72(sp)
    80004d70:	e0a2                	sd	s0,64(sp)
    80004d72:	fc26                	sd	s1,56(sp)
    80004d74:	f84a                	sd	s2,48(sp)
    80004d76:	f44e                	sd	s3,40(sp)
    80004d78:	f052                	sd	s4,32(sp)
    80004d7a:	ec56                	sd	s5,24(sp)
    80004d7c:	e85a                	sd	s6,16(sp)
    80004d7e:	0880                	add	s0,sp,80
    80004d80:	84aa                	mv	s1,a0
    80004d82:	892e                	mv	s2,a1
    80004d84:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d86:	ffffd097          	auipc	ra,0xffffd
    80004d8a:	f84080e7          	jalr	-124(ra) # 80001d0a <myproc>
    80004d8e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d90:	8526                	mv	a0,s1
    80004d92:	ffffc097          	auipc	ra,0xffffc
    80004d96:	f54080e7          	jalr	-172(ra) # 80000ce6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d9a:	2184a703          	lw	a4,536(s1)
    80004d9e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004da2:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004da6:	02f71463          	bne	a4,a5,80004dce <piperead+0x62>
    80004daa:	2244a783          	lw	a5,548(s1)
    80004dae:	c385                	beqz	a5,80004dce <piperead+0x62>
    if(pr->killed){
    80004db0:	030a2783          	lw	a5,48(s4)
    80004db4:	ebc9                	bnez	a5,80004e46 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004db6:	85a6                	mv	a1,s1
    80004db8:	854e                	mv	a0,s3
    80004dba:	ffffd097          	auipc	ra,0xffffd
    80004dbe:	766080e7          	jalr	1894(ra) # 80002520 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dc2:	2184a703          	lw	a4,536(s1)
    80004dc6:	21c4a783          	lw	a5,540(s1)
    80004dca:	fef700e3          	beq	a4,a5,80004daa <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dce:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dd0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dd2:	05505463          	blez	s5,80004e1a <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004dd6:	2184a783          	lw	a5,536(s1)
    80004dda:	21c4a703          	lw	a4,540(s1)
    80004dde:	02f70e63          	beq	a4,a5,80004e1a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004de2:	0017871b          	addw	a4,a5,1
    80004de6:	20e4ac23          	sw	a4,536(s1)
    80004dea:	1ff7f793          	and	a5,a5,511
    80004dee:	97a6                	add	a5,a5,s1
    80004df0:	0187c783          	lbu	a5,24(a5)
    80004df4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004df8:	4685                	li	a3,1
    80004dfa:	fbf40613          	add	a2,s0,-65
    80004dfe:	85ca                	mv	a1,s2
    80004e00:	050a3503          	ld	a0,80(s4)
    80004e04:	ffffd097          	auipc	ra,0xffffd
    80004e08:	bd8080e7          	jalr	-1064(ra) # 800019dc <copyout>
    80004e0c:	01650763          	beq	a0,s6,80004e1a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e10:	2985                	addw	s3,s3,1
    80004e12:	0905                	add	s2,s2,1
    80004e14:	fd3a91e3          	bne	s5,s3,80004dd6 <piperead+0x6a>
    80004e18:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e1a:	21c48513          	add	a0,s1,540
    80004e1e:	ffffe097          	auipc	ra,0xffffe
    80004e22:	882080e7          	jalr	-1918(ra) # 800026a0 <wakeup>
  release(&pi->lock);
    80004e26:	8526                	mv	a0,s1
    80004e28:	ffffc097          	auipc	ra,0xffffc
    80004e2c:	f72080e7          	jalr	-142(ra) # 80000d9a <release>
  return i;
}
    80004e30:	854e                	mv	a0,s3
    80004e32:	60a6                	ld	ra,72(sp)
    80004e34:	6406                	ld	s0,64(sp)
    80004e36:	74e2                	ld	s1,56(sp)
    80004e38:	7942                	ld	s2,48(sp)
    80004e3a:	79a2                	ld	s3,40(sp)
    80004e3c:	7a02                	ld	s4,32(sp)
    80004e3e:	6ae2                	ld	s5,24(sp)
    80004e40:	6b42                	ld	s6,16(sp)
    80004e42:	6161                	add	sp,sp,80
    80004e44:	8082                	ret
      release(&pi->lock);
    80004e46:	8526                	mv	a0,s1
    80004e48:	ffffc097          	auipc	ra,0xffffc
    80004e4c:	f52080e7          	jalr	-174(ra) # 80000d9a <release>
      return -1;
    80004e50:	59fd                	li	s3,-1
    80004e52:	bff9                	j	80004e30 <piperead+0xc4>

0000000080004e54 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e54:	df010113          	add	sp,sp,-528
    80004e58:	20113423          	sd	ra,520(sp)
    80004e5c:	20813023          	sd	s0,512(sp)
    80004e60:	ffa6                	sd	s1,504(sp)
    80004e62:	fbca                	sd	s2,496(sp)
    80004e64:	f7ce                	sd	s3,488(sp)
    80004e66:	f3d2                	sd	s4,480(sp)
    80004e68:	efd6                	sd	s5,472(sp)
    80004e6a:	ebda                	sd	s6,464(sp)
    80004e6c:	e7de                	sd	s7,456(sp)
    80004e6e:	e3e2                	sd	s8,448(sp)
    80004e70:	ff66                	sd	s9,440(sp)
    80004e72:	fb6a                	sd	s10,432(sp)
    80004e74:	f76e                	sd	s11,424(sp)
    80004e76:	0c00                	add	s0,sp,528
    80004e78:	892a                	mv	s2,a0
    80004e7a:	dea43c23          	sd	a0,-520(s0)
    80004e7e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e82:	ffffd097          	auipc	ra,0xffffd
    80004e86:	e88080e7          	jalr	-376(ra) # 80001d0a <myproc>
    80004e8a:	84aa                	mv	s1,a0

  begin_op();
    80004e8c:	fffff097          	auipc	ra,0xfffff
    80004e90:	47c080e7          	jalr	1148(ra) # 80004308 <begin_op>

  if((ip = namei(path)) == 0){
    80004e94:	854a                	mv	a0,s2
    80004e96:	fffff097          	auipc	ra,0xfffff
    80004e9a:	282080e7          	jalr	642(ra) # 80004118 <namei>
    80004e9e:	c92d                	beqz	a0,80004f10 <exec+0xbc>
    80004ea0:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ea2:	fffff097          	auipc	ra,0xfffff
    80004ea6:	ac2080e7          	jalr	-1342(ra) # 80003964 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004eaa:	04000713          	li	a4,64
    80004eae:	4681                	li	a3,0
    80004eb0:	e4840613          	add	a2,s0,-440
    80004eb4:	4581                	li	a1,0
    80004eb6:	8552                	mv	a0,s4
    80004eb8:	fffff097          	auipc	ra,0xfffff
    80004ebc:	d60080e7          	jalr	-672(ra) # 80003c18 <readi>
    80004ec0:	04000793          	li	a5,64
    80004ec4:	00f51a63          	bne	a0,a5,80004ed8 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004ec8:	e4842703          	lw	a4,-440(s0)
    80004ecc:	464c47b7          	lui	a5,0x464c4
    80004ed0:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ed4:	04f70463          	beq	a4,a5,80004f1c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ed8:	8552                	mv	a0,s4
    80004eda:	fffff097          	auipc	ra,0xfffff
    80004ede:	cec080e7          	jalr	-788(ra) # 80003bc6 <iunlockput>
    end_op();
    80004ee2:	fffff097          	auipc	ra,0xfffff
    80004ee6:	4a0080e7          	jalr	1184(ra) # 80004382 <end_op>
  }
  return -1;
    80004eea:	557d                	li	a0,-1
}
    80004eec:	20813083          	ld	ra,520(sp)
    80004ef0:	20013403          	ld	s0,512(sp)
    80004ef4:	74fe                	ld	s1,504(sp)
    80004ef6:	795e                	ld	s2,496(sp)
    80004ef8:	79be                	ld	s3,488(sp)
    80004efa:	7a1e                	ld	s4,480(sp)
    80004efc:	6afe                	ld	s5,472(sp)
    80004efe:	6b5e                	ld	s6,464(sp)
    80004f00:	6bbe                	ld	s7,456(sp)
    80004f02:	6c1e                	ld	s8,448(sp)
    80004f04:	7cfa                	ld	s9,440(sp)
    80004f06:	7d5a                	ld	s10,432(sp)
    80004f08:	7dba                	ld	s11,424(sp)
    80004f0a:	21010113          	add	sp,sp,528
    80004f0e:	8082                	ret
    end_op();
    80004f10:	fffff097          	auipc	ra,0xfffff
    80004f14:	472080e7          	jalr	1138(ra) # 80004382 <end_op>
    return -1;
    80004f18:	557d                	li	a0,-1
    80004f1a:	bfc9                	j	80004eec <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f1c:	8526                	mv	a0,s1
    80004f1e:	ffffd097          	auipc	ra,0xffffd
    80004f22:	eb0080e7          	jalr	-336(ra) # 80001dce <proc_pagetable>
    80004f26:	8b2a                	mv	s6,a0
    80004f28:	d945                	beqz	a0,80004ed8 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f2a:	e6842d03          	lw	s10,-408(s0)
    80004f2e:	e8045783          	lhu	a5,-384(s0)
    80004f32:	cfe5                	beqz	a5,8000502a <exec+0x1d6>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f34:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f36:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004f38:	6c85                	lui	s9,0x1
    80004f3a:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f3e:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004f42:	6a85                	lui	s5,0x1
    80004f44:	a0b5                	j	80004fb0 <exec+0x15c>
      panic("loadseg: address should exist");
    80004f46:	00003517          	auipc	a0,0x3
    80004f4a:	77250513          	add	a0,a0,1906 # 800086b8 <syscalls+0x290>
    80004f4e:	ffffb097          	auipc	ra,0xffffb
    80004f52:	5f4080e7          	jalr	1524(ra) # 80000542 <panic>
    if(sz - i < PGSIZE)
    80004f56:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f58:	8726                	mv	a4,s1
    80004f5a:	012c06bb          	addw	a3,s8,s2
    80004f5e:	4581                	li	a1,0
    80004f60:	8552                	mv	a0,s4
    80004f62:	fffff097          	auipc	ra,0xfffff
    80004f66:	cb6080e7          	jalr	-842(ra) # 80003c18 <readi>
    80004f6a:	2501                	sext.w	a0,a0
    80004f6c:	24a49063          	bne	s1,a0,800051ac <exec+0x358>
  for(i = 0; i < sz; i += PGSIZE){
    80004f70:	012a893b          	addw	s2,s5,s2
    80004f74:	03397563          	bgeu	s2,s3,80004f9e <exec+0x14a>
    pa = walkaddr(pagetable, va + i);
    80004f78:	02091593          	sll	a1,s2,0x20
    80004f7c:	9181                	srl	a1,a1,0x20
    80004f7e:	95de                	add	a1,a1,s7
    80004f80:	855a                	mv	a0,s6
    80004f82:	ffffc097          	auipc	ra,0xffffc
    80004f86:	1ec080e7          	jalr	492(ra) # 8000116e <walkaddr>
    80004f8a:	862a                	mv	a2,a0
    if(pa == 0)
    80004f8c:	dd4d                	beqz	a0,80004f46 <exec+0xf2>
    if(sz - i < PGSIZE)
    80004f8e:	412984bb          	subw	s1,s3,s2
    80004f92:	0004879b          	sext.w	a5,s1
    80004f96:	fcfcf0e3          	bgeu	s9,a5,80004f56 <exec+0x102>
    80004f9a:	84d6                	mv	s1,s5
    80004f9c:	bf6d                	j	80004f56 <exec+0x102>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f9e:	e0843483          	ld	s1,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fa2:	2d85                	addw	s11,s11,1
    80004fa4:	038d0d1b          	addw	s10,s10,56
    80004fa8:	e8045783          	lhu	a5,-384(s0)
    80004fac:	08fdd063          	bge	s11,a5,8000502c <exec+0x1d8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fb0:	2d01                	sext.w	s10,s10
    80004fb2:	03800713          	li	a4,56
    80004fb6:	86ea                	mv	a3,s10
    80004fb8:	e1040613          	add	a2,s0,-496
    80004fbc:	4581                	li	a1,0
    80004fbe:	8552                	mv	a0,s4
    80004fc0:	fffff097          	auipc	ra,0xfffff
    80004fc4:	c58080e7          	jalr	-936(ra) # 80003c18 <readi>
    80004fc8:	03800793          	li	a5,56
    80004fcc:	1cf51e63          	bne	a0,a5,800051a8 <exec+0x354>
    if(ph.type != ELF_PROG_LOAD)
    80004fd0:	e1042783          	lw	a5,-496(s0)
    80004fd4:	4705                	li	a4,1
    80004fd6:	fce796e3          	bne	a5,a4,80004fa2 <exec+0x14e>
    if(ph.memsz < ph.filesz)
    80004fda:	e3843603          	ld	a2,-456(s0)
    80004fde:	e3043783          	ld	a5,-464(s0)
    80004fe2:	1ef66063          	bltu	a2,a5,800051c2 <exec+0x36e>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fe6:	e2043783          	ld	a5,-480(s0)
    80004fea:	963e                	add	a2,a2,a5
    80004fec:	1cf66e63          	bltu	a2,a5,800051c8 <exec+0x374>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004ff0:	85a6                	mv	a1,s1
    80004ff2:	855a                	mv	a0,s6
    80004ff4:	ffffc097          	auipc	ra,0xffffc
    80004ff8:	79a080e7          	jalr	1946(ra) # 8000178e <uvmalloc>
    80004ffc:	e0a43423          	sd	a0,-504(s0)
    80005000:	1c050763          	beqz	a0,800051ce <exec+0x37a>
    if(ph.vaddr % PGSIZE != 0)
    80005004:	e2043b83          	ld	s7,-480(s0)
    80005008:	df043783          	ld	a5,-528(s0)
    8000500c:	00fbf7b3          	and	a5,s7,a5
    80005010:	18079e63          	bnez	a5,800051ac <exec+0x358>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005014:	e1842c03          	lw	s8,-488(s0)
    80005018:	e3042983          	lw	s3,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000501c:	00098463          	beqz	s3,80005024 <exec+0x1d0>
    80005020:	4901                	li	s2,0
    80005022:	bf99                	j	80004f78 <exec+0x124>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005024:	e0843483          	ld	s1,-504(s0)
    80005028:	bfad                	j	80004fa2 <exec+0x14e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000502a:	4481                	li	s1,0
  iunlockput(ip);
    8000502c:	8552                	mv	a0,s4
    8000502e:	fffff097          	auipc	ra,0xfffff
    80005032:	b98080e7          	jalr	-1128(ra) # 80003bc6 <iunlockput>
  end_op();
    80005036:	fffff097          	auipc	ra,0xfffff
    8000503a:	34c080e7          	jalr	844(ra) # 80004382 <end_op>
  p = myproc();
    8000503e:	ffffd097          	auipc	ra,0xffffd
    80005042:	ccc080e7          	jalr	-820(ra) # 80001d0a <myproc>
    80005046:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005048:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    8000504c:	6985                	lui	s3,0x1
    8000504e:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    80005050:	99a6                	add	s3,s3,s1
    80005052:	77fd                	lui	a5,0xfffff
    80005054:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005058:	6609                	lui	a2,0x2
    8000505a:	964e                	add	a2,a2,s3
    8000505c:	85ce                	mv	a1,s3
    8000505e:	855a                	mv	a0,s6
    80005060:	ffffc097          	auipc	ra,0xffffc
    80005064:	72e080e7          	jalr	1838(ra) # 8000178e <uvmalloc>
    80005068:	892a                	mv	s2,a0
    8000506a:	e0a43423          	sd	a0,-504(s0)
    8000506e:	e509                	bnez	a0,80005078 <exec+0x224>
  if(pagetable)
    80005070:	e1343423          	sd	s3,-504(s0)
    80005074:	4a01                	li	s4,0
    80005076:	aa1d                	j	800051ac <exec+0x358>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005078:	75f9                	lui	a1,0xffffe
    8000507a:	95aa                	add	a1,a1,a0
    8000507c:	855a                	mv	a0,s6
    8000507e:	ffffd097          	auipc	ra,0xffffd
    80005082:	92c080e7          	jalr	-1748(ra) # 800019aa <uvmclear>
  stackbase = sp - PGSIZE;
    80005086:	7bfd                	lui	s7,0xfffff
    80005088:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    8000508a:	e0043783          	ld	a5,-512(s0)
    8000508e:	6388                	ld	a0,0(a5)
    80005090:	c52d                	beqz	a0,800050fa <exec+0x2a6>
    80005092:	e8840993          	add	s3,s0,-376
    80005096:	f8840c13          	add	s8,s0,-120
    8000509a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000509c:	ffffc097          	auipc	ra,0xffffc
    800050a0:	ec8080e7          	jalr	-312(ra) # 80000f64 <strlen>
    800050a4:	0015079b          	addw	a5,a0,1
    800050a8:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050ac:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    800050b0:	13796263          	bltu	s2,s7,800051d4 <exec+0x380>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050b4:	e0043d03          	ld	s10,-512(s0)
    800050b8:	000d3a03          	ld	s4,0(s10)
    800050bc:	8552                	mv	a0,s4
    800050be:	ffffc097          	auipc	ra,0xffffc
    800050c2:	ea6080e7          	jalr	-346(ra) # 80000f64 <strlen>
    800050c6:	0015069b          	addw	a3,a0,1
    800050ca:	8652                	mv	a2,s4
    800050cc:	85ca                	mv	a1,s2
    800050ce:	855a                	mv	a0,s6
    800050d0:	ffffd097          	auipc	ra,0xffffd
    800050d4:	90c080e7          	jalr	-1780(ra) # 800019dc <copyout>
    800050d8:	10054063          	bltz	a0,800051d8 <exec+0x384>
    ustack[argc] = sp;
    800050dc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050e0:	0485                	add	s1,s1,1
    800050e2:	008d0793          	add	a5,s10,8
    800050e6:	e0f43023          	sd	a5,-512(s0)
    800050ea:	008d3503          	ld	a0,8(s10)
    800050ee:	c909                	beqz	a0,80005100 <exec+0x2ac>
    if(argc >= MAXARG)
    800050f0:	09a1                	add	s3,s3,8
    800050f2:	fb8995e3          	bne	s3,s8,8000509c <exec+0x248>
  ip = 0;
    800050f6:	4a01                	li	s4,0
    800050f8:	a855                	j	800051ac <exec+0x358>
  sp = sz;
    800050fa:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    800050fe:	4481                	li	s1,0
  ustack[argc] = 0;
    80005100:	00349793          	sll	a5,s1,0x3
    80005104:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffd0f90>
    80005108:	97a2                	add	a5,a5,s0
    8000510a:	ee07bc23          	sd	zero,-264(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000510e:	00148693          	add	a3,s1,1
    80005112:	068e                	sll	a3,a3,0x3
    80005114:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005118:	ff097913          	and	s2,s2,-16
  sz = sz1;
    8000511c:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80005120:	f57968e3          	bltu	s2,s7,80005070 <exec+0x21c>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005124:	e8840613          	add	a2,s0,-376
    80005128:	85ca                	mv	a1,s2
    8000512a:	855a                	mv	a0,s6
    8000512c:	ffffd097          	auipc	ra,0xffffd
    80005130:	8b0080e7          	jalr	-1872(ra) # 800019dc <copyout>
    80005134:	0a054463          	bltz	a0,800051dc <exec+0x388>
  p->trapframe->a1 = sp;
    80005138:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    8000513c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005140:	df843783          	ld	a5,-520(s0)
    80005144:	0007c703          	lbu	a4,0(a5)
    80005148:	cf11                	beqz	a4,80005164 <exec+0x310>
    8000514a:	0785                	add	a5,a5,1
    if(*s == '/')
    8000514c:	02f00693          	li	a3,47
    80005150:	a039                	j	8000515e <exec+0x30a>
      last = s+1;
    80005152:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005156:	0785                	add	a5,a5,1
    80005158:	fff7c703          	lbu	a4,-1(a5)
    8000515c:	c701                	beqz	a4,80005164 <exec+0x310>
    if(*s == '/')
    8000515e:	fed71ce3          	bne	a4,a3,80005156 <exec+0x302>
    80005162:	bfc5                	j	80005152 <exec+0x2fe>
  safestrcpy(p->name, last, sizeof(p->name));
    80005164:	4641                	li	a2,16
    80005166:	df843583          	ld	a1,-520(s0)
    8000516a:	158a8513          	add	a0,s5,344
    8000516e:	ffffc097          	auipc	ra,0xffffc
    80005172:	dc4080e7          	jalr	-572(ra) # 80000f32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005176:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000517a:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    8000517e:	e0843783          	ld	a5,-504(s0)
    80005182:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005186:	058ab783          	ld	a5,88(s5)
    8000518a:	e6043703          	ld	a4,-416(s0)
    8000518e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005190:	058ab783          	ld	a5,88(s5)
    80005194:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005198:	85e6                	mv	a1,s9
    8000519a:	ffffd097          	auipc	ra,0xffffd
    8000519e:	cd0080e7          	jalr	-816(ra) # 80001e6a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051a2:	0004851b          	sext.w	a0,s1
    800051a6:	b399                	j	80004eec <exec+0x98>
    800051a8:	e0943423          	sd	s1,-504(s0)
    proc_freepagetable(pagetable, sz);
    800051ac:	e0843583          	ld	a1,-504(s0)
    800051b0:	855a                	mv	a0,s6
    800051b2:	ffffd097          	auipc	ra,0xffffd
    800051b6:	cb8080e7          	jalr	-840(ra) # 80001e6a <proc_freepagetable>
  return -1;
    800051ba:	557d                	li	a0,-1
  if(ip){
    800051bc:	d20a08e3          	beqz	s4,80004eec <exec+0x98>
    800051c0:	bb21                	j	80004ed8 <exec+0x84>
    800051c2:	e0943423          	sd	s1,-504(s0)
    800051c6:	b7dd                	j	800051ac <exec+0x358>
    800051c8:	e0943423          	sd	s1,-504(s0)
    800051cc:	b7c5                	j	800051ac <exec+0x358>
    800051ce:	e0943423          	sd	s1,-504(s0)
    800051d2:	bfe9                	j	800051ac <exec+0x358>
  ip = 0;
    800051d4:	4a01                	li	s4,0
    800051d6:	bfd9                	j	800051ac <exec+0x358>
    800051d8:	4a01                	li	s4,0
  if(pagetable)
    800051da:	bfc9                	j	800051ac <exec+0x358>
  sz = sz1;
    800051dc:	e0843983          	ld	s3,-504(s0)
    800051e0:	bd41                	j	80005070 <exec+0x21c>

00000000800051e2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051e2:	7179                	add	sp,sp,-48
    800051e4:	f406                	sd	ra,40(sp)
    800051e6:	f022                	sd	s0,32(sp)
    800051e8:	ec26                	sd	s1,24(sp)
    800051ea:	e84a                	sd	s2,16(sp)
    800051ec:	1800                	add	s0,sp,48
    800051ee:	892e                	mv	s2,a1
    800051f0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800051f2:	fdc40593          	add	a1,s0,-36
    800051f6:	ffffe097          	auipc	ra,0xffffe
    800051fa:	c04080e7          	jalr	-1020(ra) # 80002dfa <argint>
    800051fe:	04054063          	bltz	a0,8000523e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005202:	fdc42703          	lw	a4,-36(s0)
    80005206:	47bd                	li	a5,15
    80005208:	02e7ed63          	bltu	a5,a4,80005242 <argfd+0x60>
    8000520c:	ffffd097          	auipc	ra,0xffffd
    80005210:	afe080e7          	jalr	-1282(ra) # 80001d0a <myproc>
    80005214:	fdc42703          	lw	a4,-36(s0)
    80005218:	01a70793          	add	a5,a4,26
    8000521c:	078e                	sll	a5,a5,0x3
    8000521e:	953e                	add	a0,a0,a5
    80005220:	611c                	ld	a5,0(a0)
    80005222:	c395                	beqz	a5,80005246 <argfd+0x64>
    return -1;
  if(pfd)
    80005224:	00090463          	beqz	s2,8000522c <argfd+0x4a>
    *pfd = fd;
    80005228:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000522c:	4501                	li	a0,0
  if(pf)
    8000522e:	c091                	beqz	s1,80005232 <argfd+0x50>
    *pf = f;
    80005230:	e09c                	sd	a5,0(s1)
}
    80005232:	70a2                	ld	ra,40(sp)
    80005234:	7402                	ld	s0,32(sp)
    80005236:	64e2                	ld	s1,24(sp)
    80005238:	6942                	ld	s2,16(sp)
    8000523a:	6145                	add	sp,sp,48
    8000523c:	8082                	ret
    return -1;
    8000523e:	557d                	li	a0,-1
    80005240:	bfcd                	j	80005232 <argfd+0x50>
    return -1;
    80005242:	557d                	li	a0,-1
    80005244:	b7fd                	j	80005232 <argfd+0x50>
    80005246:	557d                	li	a0,-1
    80005248:	b7ed                	j	80005232 <argfd+0x50>

000000008000524a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000524a:	1101                	add	sp,sp,-32
    8000524c:	ec06                	sd	ra,24(sp)
    8000524e:	e822                	sd	s0,16(sp)
    80005250:	e426                	sd	s1,8(sp)
    80005252:	1000                	add	s0,sp,32
    80005254:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005256:	ffffd097          	auipc	ra,0xffffd
    8000525a:	ab4080e7          	jalr	-1356(ra) # 80001d0a <myproc>
    8000525e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005260:	0d050793          	add	a5,a0,208
    80005264:	4501                	li	a0,0
    80005266:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005268:	6398                	ld	a4,0(a5)
    8000526a:	cb19                	beqz	a4,80005280 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000526c:	2505                	addw	a0,a0,1
    8000526e:	07a1                	add	a5,a5,8
    80005270:	fed51ce3          	bne	a0,a3,80005268 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005274:	557d                	li	a0,-1
}
    80005276:	60e2                	ld	ra,24(sp)
    80005278:	6442                	ld	s0,16(sp)
    8000527a:	64a2                	ld	s1,8(sp)
    8000527c:	6105                	add	sp,sp,32
    8000527e:	8082                	ret
      p->ofile[fd] = f;
    80005280:	01a50793          	add	a5,a0,26
    80005284:	078e                	sll	a5,a5,0x3
    80005286:	963e                	add	a2,a2,a5
    80005288:	e204                	sd	s1,0(a2)
      return fd;
    8000528a:	b7f5                	j	80005276 <fdalloc+0x2c>

000000008000528c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000528c:	715d                	add	sp,sp,-80
    8000528e:	e486                	sd	ra,72(sp)
    80005290:	e0a2                	sd	s0,64(sp)
    80005292:	fc26                	sd	s1,56(sp)
    80005294:	f84a                	sd	s2,48(sp)
    80005296:	f44e                	sd	s3,40(sp)
    80005298:	f052                	sd	s4,32(sp)
    8000529a:	ec56                	sd	s5,24(sp)
    8000529c:	0880                	add	s0,sp,80
    8000529e:	8aae                	mv	s5,a1
    800052a0:	8a32                	mv	s4,a2
    800052a2:	89b6                	mv	s3,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052a4:	fb040593          	add	a1,s0,-80
    800052a8:	fffff097          	auipc	ra,0xfffff
    800052ac:	e8e080e7          	jalr	-370(ra) # 80004136 <nameiparent>
    800052b0:	892a                	mv	s2,a0
    800052b2:	12050c63          	beqz	a0,800053ea <create+0x15e>
    return 0;

  ilock(dp);
    800052b6:	ffffe097          	auipc	ra,0xffffe
    800052ba:	6ae080e7          	jalr	1710(ra) # 80003964 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052be:	4601                	li	a2,0
    800052c0:	fb040593          	add	a1,s0,-80
    800052c4:	854a                	mv	a0,s2
    800052c6:	fffff097          	auipc	ra,0xfffff
    800052ca:	b80080e7          	jalr	-1152(ra) # 80003e46 <dirlookup>
    800052ce:	84aa                	mv	s1,a0
    800052d0:	c539                	beqz	a0,8000531e <create+0x92>
    iunlockput(dp);
    800052d2:	854a                	mv	a0,s2
    800052d4:	fffff097          	auipc	ra,0xfffff
    800052d8:	8f2080e7          	jalr	-1806(ra) # 80003bc6 <iunlockput>
    ilock(ip);
    800052dc:	8526                	mv	a0,s1
    800052de:	ffffe097          	auipc	ra,0xffffe
    800052e2:	686080e7          	jalr	1670(ra) # 80003964 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052e6:	4789                	li	a5,2
    800052e8:	02fa9463          	bne	s5,a5,80005310 <create+0x84>
    800052ec:	0444d783          	lhu	a5,68(s1)
    800052f0:	37f9                	addw	a5,a5,-2
    800052f2:	17c2                	sll	a5,a5,0x30
    800052f4:	93c1                	srl	a5,a5,0x30
    800052f6:	4705                	li	a4,1
    800052f8:	00f76c63          	bltu	a4,a5,80005310 <create+0x84>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800052fc:	8526                	mv	a0,s1
    800052fe:	60a6                	ld	ra,72(sp)
    80005300:	6406                	ld	s0,64(sp)
    80005302:	74e2                	ld	s1,56(sp)
    80005304:	7942                	ld	s2,48(sp)
    80005306:	79a2                	ld	s3,40(sp)
    80005308:	7a02                	ld	s4,32(sp)
    8000530a:	6ae2                	ld	s5,24(sp)
    8000530c:	6161                	add	sp,sp,80
    8000530e:	8082                	ret
    iunlockput(ip);
    80005310:	8526                	mv	a0,s1
    80005312:	fffff097          	auipc	ra,0xfffff
    80005316:	8b4080e7          	jalr	-1868(ra) # 80003bc6 <iunlockput>
    return 0;
    8000531a:	4481                	li	s1,0
    8000531c:	b7c5                	j	800052fc <create+0x70>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000531e:	85d6                	mv	a1,s5
    80005320:	00092503          	lw	a0,0(s2)
    80005324:	ffffe097          	auipc	ra,0xffffe
    80005328:	4ac080e7          	jalr	1196(ra) # 800037d0 <ialloc>
    8000532c:	84aa                	mv	s1,a0
    8000532e:	c139                	beqz	a0,80005374 <create+0xe8>
  ilock(ip);
    80005330:	ffffe097          	auipc	ra,0xffffe
    80005334:	634080e7          	jalr	1588(ra) # 80003964 <ilock>
  ip->major = major;
    80005338:	05449323          	sh	s4,70(s1)
  ip->minor = minor;
    8000533c:	05349423          	sh	s3,72(s1)
  ip->nlink = 1;
    80005340:	4985                	li	s3,1
    80005342:	05349523          	sh	s3,74(s1)
  iupdate(ip);
    80005346:	8526                	mv	a0,s1
    80005348:	ffffe097          	auipc	ra,0xffffe
    8000534c:	550080e7          	jalr	1360(ra) # 80003898 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005350:	033a8a63          	beq	s5,s3,80005384 <create+0xf8>
  if(dirlink(dp, name, ip->inum) < 0)
    80005354:	40d0                	lw	a2,4(s1)
    80005356:	fb040593          	add	a1,s0,-80
    8000535a:	854a                	mv	a0,s2
    8000535c:	fffff097          	auipc	ra,0xfffff
    80005360:	cfa080e7          	jalr	-774(ra) # 80004056 <dirlink>
    80005364:	06054b63          	bltz	a0,800053da <create+0x14e>
  iunlockput(dp);
    80005368:	854a                	mv	a0,s2
    8000536a:	fffff097          	auipc	ra,0xfffff
    8000536e:	85c080e7          	jalr	-1956(ra) # 80003bc6 <iunlockput>
  return ip;
    80005372:	b769                	j	800052fc <create+0x70>
    panic("create: ialloc");
    80005374:	00003517          	auipc	a0,0x3
    80005378:	36450513          	add	a0,a0,868 # 800086d8 <syscalls+0x2b0>
    8000537c:	ffffb097          	auipc	ra,0xffffb
    80005380:	1c6080e7          	jalr	454(ra) # 80000542 <panic>
    dp->nlink++;  // for ".."
    80005384:	04a95783          	lhu	a5,74(s2)
    80005388:	2785                	addw	a5,a5,1
    8000538a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000538e:	854a                	mv	a0,s2
    80005390:	ffffe097          	auipc	ra,0xffffe
    80005394:	508080e7          	jalr	1288(ra) # 80003898 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005398:	40d0                	lw	a2,4(s1)
    8000539a:	00003597          	auipc	a1,0x3
    8000539e:	34e58593          	add	a1,a1,846 # 800086e8 <syscalls+0x2c0>
    800053a2:	8526                	mv	a0,s1
    800053a4:	fffff097          	auipc	ra,0xfffff
    800053a8:	cb2080e7          	jalr	-846(ra) # 80004056 <dirlink>
    800053ac:	00054f63          	bltz	a0,800053ca <create+0x13e>
    800053b0:	00492603          	lw	a2,4(s2)
    800053b4:	00003597          	auipc	a1,0x3
    800053b8:	33c58593          	add	a1,a1,828 # 800086f0 <syscalls+0x2c8>
    800053bc:	8526                	mv	a0,s1
    800053be:	fffff097          	auipc	ra,0xfffff
    800053c2:	c98080e7          	jalr	-872(ra) # 80004056 <dirlink>
    800053c6:	f80557e3          	bgez	a0,80005354 <create+0xc8>
      panic("create dots");
    800053ca:	00003517          	auipc	a0,0x3
    800053ce:	32e50513          	add	a0,a0,814 # 800086f8 <syscalls+0x2d0>
    800053d2:	ffffb097          	auipc	ra,0xffffb
    800053d6:	170080e7          	jalr	368(ra) # 80000542 <panic>
    panic("create: dirlink");
    800053da:	00003517          	auipc	a0,0x3
    800053de:	32e50513          	add	a0,a0,814 # 80008708 <syscalls+0x2e0>
    800053e2:	ffffb097          	auipc	ra,0xffffb
    800053e6:	160080e7          	jalr	352(ra) # 80000542 <panic>
    return 0;
    800053ea:	84aa                	mv	s1,a0
    800053ec:	bf01                	j	800052fc <create+0x70>

00000000800053ee <sys_dup>:
{
    800053ee:	7179                	add	sp,sp,-48
    800053f0:	f406                	sd	ra,40(sp)
    800053f2:	f022                	sd	s0,32(sp)
    800053f4:	ec26                	sd	s1,24(sp)
    800053f6:	e84a                	sd	s2,16(sp)
    800053f8:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053fa:	fd840613          	add	a2,s0,-40
    800053fe:	4581                	li	a1,0
    80005400:	4501                	li	a0,0
    80005402:	00000097          	auipc	ra,0x0
    80005406:	de0080e7          	jalr	-544(ra) # 800051e2 <argfd>
    return -1;
    8000540a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000540c:	02054363          	bltz	a0,80005432 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005410:	fd843903          	ld	s2,-40(s0)
    80005414:	854a                	mv	a0,s2
    80005416:	00000097          	auipc	ra,0x0
    8000541a:	e34080e7          	jalr	-460(ra) # 8000524a <fdalloc>
    8000541e:	84aa                	mv	s1,a0
    return -1;
    80005420:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005422:	00054863          	bltz	a0,80005432 <sys_dup+0x44>
  filedup(f);
    80005426:	854a                	mv	a0,s2
    80005428:	fffff097          	auipc	ra,0xfffff
    8000542c:	358080e7          	jalr	856(ra) # 80004780 <filedup>
  return fd;
    80005430:	87a6                	mv	a5,s1
}
    80005432:	853e                	mv	a0,a5
    80005434:	70a2                	ld	ra,40(sp)
    80005436:	7402                	ld	s0,32(sp)
    80005438:	64e2                	ld	s1,24(sp)
    8000543a:	6942                	ld	s2,16(sp)
    8000543c:	6145                	add	sp,sp,48
    8000543e:	8082                	ret

0000000080005440 <sys_read>:
{
    80005440:	7179                	add	sp,sp,-48
    80005442:	f406                	sd	ra,40(sp)
    80005444:	f022                	sd	s0,32(sp)
    80005446:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005448:	fe840613          	add	a2,s0,-24
    8000544c:	4581                	li	a1,0
    8000544e:	4501                	li	a0,0
    80005450:	00000097          	auipc	ra,0x0
    80005454:	d92080e7          	jalr	-622(ra) # 800051e2 <argfd>
    return -1;
    80005458:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000545a:	04054163          	bltz	a0,8000549c <sys_read+0x5c>
    8000545e:	fe440593          	add	a1,s0,-28
    80005462:	4509                	li	a0,2
    80005464:	ffffe097          	auipc	ra,0xffffe
    80005468:	996080e7          	jalr	-1642(ra) # 80002dfa <argint>
    return -1;
    8000546c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000546e:	02054763          	bltz	a0,8000549c <sys_read+0x5c>
    80005472:	fd840593          	add	a1,s0,-40
    80005476:	4505                	li	a0,1
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	9a4080e7          	jalr	-1628(ra) # 80002e1c <argaddr>
    return -1;
    80005480:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005482:	00054d63          	bltz	a0,8000549c <sys_read+0x5c>
  return fileread(f, p, n);
    80005486:	fe442603          	lw	a2,-28(s0)
    8000548a:	fd843583          	ld	a1,-40(s0)
    8000548e:	fe843503          	ld	a0,-24(s0)
    80005492:	fffff097          	auipc	ra,0xfffff
    80005496:	47a080e7          	jalr	1146(ra) # 8000490c <fileread>
    8000549a:	87aa                	mv	a5,a0
}
    8000549c:	853e                	mv	a0,a5
    8000549e:	70a2                	ld	ra,40(sp)
    800054a0:	7402                	ld	s0,32(sp)
    800054a2:	6145                	add	sp,sp,48
    800054a4:	8082                	ret

00000000800054a6 <sys_write>:
{
    800054a6:	7179                	add	sp,sp,-48
    800054a8:	f406                	sd	ra,40(sp)
    800054aa:	f022                	sd	s0,32(sp)
    800054ac:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054ae:	fe840613          	add	a2,s0,-24
    800054b2:	4581                	li	a1,0
    800054b4:	4501                	li	a0,0
    800054b6:	00000097          	auipc	ra,0x0
    800054ba:	d2c080e7          	jalr	-724(ra) # 800051e2 <argfd>
    return -1;
    800054be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054c0:	04054163          	bltz	a0,80005502 <sys_write+0x5c>
    800054c4:	fe440593          	add	a1,s0,-28
    800054c8:	4509                	li	a0,2
    800054ca:	ffffe097          	auipc	ra,0xffffe
    800054ce:	930080e7          	jalr	-1744(ra) # 80002dfa <argint>
    return -1;
    800054d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054d4:	02054763          	bltz	a0,80005502 <sys_write+0x5c>
    800054d8:	fd840593          	add	a1,s0,-40
    800054dc:	4505                	li	a0,1
    800054de:	ffffe097          	auipc	ra,0xffffe
    800054e2:	93e080e7          	jalr	-1730(ra) # 80002e1c <argaddr>
    return -1;
    800054e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e8:	00054d63          	bltz	a0,80005502 <sys_write+0x5c>
  return filewrite(f, p, n);
    800054ec:	fe442603          	lw	a2,-28(s0)
    800054f0:	fd843583          	ld	a1,-40(s0)
    800054f4:	fe843503          	ld	a0,-24(s0)
    800054f8:	fffff097          	auipc	ra,0xfffff
    800054fc:	4d6080e7          	jalr	1238(ra) # 800049ce <filewrite>
    80005500:	87aa                	mv	a5,a0
}
    80005502:	853e                	mv	a0,a5
    80005504:	70a2                	ld	ra,40(sp)
    80005506:	7402                	ld	s0,32(sp)
    80005508:	6145                	add	sp,sp,48
    8000550a:	8082                	ret

000000008000550c <sys_close>:
{
    8000550c:	1101                	add	sp,sp,-32
    8000550e:	ec06                	sd	ra,24(sp)
    80005510:	e822                	sd	s0,16(sp)
    80005512:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005514:	fe040613          	add	a2,s0,-32
    80005518:	fec40593          	add	a1,s0,-20
    8000551c:	4501                	li	a0,0
    8000551e:	00000097          	auipc	ra,0x0
    80005522:	cc4080e7          	jalr	-828(ra) # 800051e2 <argfd>
    return -1;
    80005526:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005528:	02054463          	bltz	a0,80005550 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000552c:	ffffc097          	auipc	ra,0xffffc
    80005530:	7de080e7          	jalr	2014(ra) # 80001d0a <myproc>
    80005534:	fec42783          	lw	a5,-20(s0)
    80005538:	07e9                	add	a5,a5,26
    8000553a:	078e                	sll	a5,a5,0x3
    8000553c:	953e                	add	a0,a0,a5
    8000553e:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005542:	fe043503          	ld	a0,-32(s0)
    80005546:	fffff097          	auipc	ra,0xfffff
    8000554a:	28c080e7          	jalr	652(ra) # 800047d2 <fileclose>
  return 0;
    8000554e:	4781                	li	a5,0
}
    80005550:	853e                	mv	a0,a5
    80005552:	60e2                	ld	ra,24(sp)
    80005554:	6442                	ld	s0,16(sp)
    80005556:	6105                	add	sp,sp,32
    80005558:	8082                	ret

000000008000555a <sys_fstat>:
{
    8000555a:	1101                	add	sp,sp,-32
    8000555c:	ec06                	sd	ra,24(sp)
    8000555e:	e822                	sd	s0,16(sp)
    80005560:	1000                	add	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005562:	fe840613          	add	a2,s0,-24
    80005566:	4581                	li	a1,0
    80005568:	4501                	li	a0,0
    8000556a:	00000097          	auipc	ra,0x0
    8000556e:	c78080e7          	jalr	-904(ra) # 800051e2 <argfd>
    return -1;
    80005572:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005574:	02054563          	bltz	a0,8000559e <sys_fstat+0x44>
    80005578:	fe040593          	add	a1,s0,-32
    8000557c:	4505                	li	a0,1
    8000557e:	ffffe097          	auipc	ra,0xffffe
    80005582:	89e080e7          	jalr	-1890(ra) # 80002e1c <argaddr>
    return -1;
    80005586:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005588:	00054b63          	bltz	a0,8000559e <sys_fstat+0x44>
  return filestat(f, st);
    8000558c:	fe043583          	ld	a1,-32(s0)
    80005590:	fe843503          	ld	a0,-24(s0)
    80005594:	fffff097          	auipc	ra,0xfffff
    80005598:	306080e7          	jalr	774(ra) # 8000489a <filestat>
    8000559c:	87aa                	mv	a5,a0
}
    8000559e:	853e                	mv	a0,a5
    800055a0:	60e2                	ld	ra,24(sp)
    800055a2:	6442                	ld	s0,16(sp)
    800055a4:	6105                	add	sp,sp,32
    800055a6:	8082                	ret

00000000800055a8 <sys_link>:
{
    800055a8:	7169                	add	sp,sp,-304
    800055aa:	f606                	sd	ra,296(sp)
    800055ac:	f222                	sd	s0,288(sp)
    800055ae:	ee26                	sd	s1,280(sp)
    800055b0:	ea4a                	sd	s2,272(sp)
    800055b2:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055b4:	08000613          	li	a2,128
    800055b8:	ed040593          	add	a1,s0,-304
    800055bc:	4501                	li	a0,0
    800055be:	ffffe097          	auipc	ra,0xffffe
    800055c2:	880080e7          	jalr	-1920(ra) # 80002e3e <argstr>
    return -1;
    800055c6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055c8:	10054e63          	bltz	a0,800056e4 <sys_link+0x13c>
    800055cc:	08000613          	li	a2,128
    800055d0:	f5040593          	add	a1,s0,-176
    800055d4:	4505                	li	a0,1
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	868080e7          	jalr	-1944(ra) # 80002e3e <argstr>
    return -1;
    800055de:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055e0:	10054263          	bltz	a0,800056e4 <sys_link+0x13c>
  begin_op();
    800055e4:	fffff097          	auipc	ra,0xfffff
    800055e8:	d24080e7          	jalr	-732(ra) # 80004308 <begin_op>
  if((ip = namei(old)) == 0){
    800055ec:	ed040513          	add	a0,s0,-304
    800055f0:	fffff097          	auipc	ra,0xfffff
    800055f4:	b28080e7          	jalr	-1240(ra) # 80004118 <namei>
    800055f8:	84aa                	mv	s1,a0
    800055fa:	c551                	beqz	a0,80005686 <sys_link+0xde>
  ilock(ip);
    800055fc:	ffffe097          	auipc	ra,0xffffe
    80005600:	368080e7          	jalr	872(ra) # 80003964 <ilock>
  if(ip->type == T_DIR){
    80005604:	04449703          	lh	a4,68(s1)
    80005608:	4785                	li	a5,1
    8000560a:	08f70463          	beq	a4,a5,80005692 <sys_link+0xea>
  ip->nlink++;
    8000560e:	04a4d783          	lhu	a5,74(s1)
    80005612:	2785                	addw	a5,a5,1
    80005614:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005618:	8526                	mv	a0,s1
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	27e080e7          	jalr	638(ra) # 80003898 <iupdate>
  iunlock(ip);
    80005622:	8526                	mv	a0,s1
    80005624:	ffffe097          	auipc	ra,0xffffe
    80005628:	402080e7          	jalr	1026(ra) # 80003a26 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000562c:	fd040593          	add	a1,s0,-48
    80005630:	f5040513          	add	a0,s0,-176
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	b02080e7          	jalr	-1278(ra) # 80004136 <nameiparent>
    8000563c:	892a                	mv	s2,a0
    8000563e:	c935                	beqz	a0,800056b2 <sys_link+0x10a>
  ilock(dp);
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	324080e7          	jalr	804(ra) # 80003964 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005648:	00092703          	lw	a4,0(s2)
    8000564c:	409c                	lw	a5,0(s1)
    8000564e:	04f71d63          	bne	a4,a5,800056a8 <sys_link+0x100>
    80005652:	40d0                	lw	a2,4(s1)
    80005654:	fd040593          	add	a1,s0,-48
    80005658:	854a                	mv	a0,s2
    8000565a:	fffff097          	auipc	ra,0xfffff
    8000565e:	9fc080e7          	jalr	-1540(ra) # 80004056 <dirlink>
    80005662:	04054363          	bltz	a0,800056a8 <sys_link+0x100>
  iunlockput(dp);
    80005666:	854a                	mv	a0,s2
    80005668:	ffffe097          	auipc	ra,0xffffe
    8000566c:	55e080e7          	jalr	1374(ra) # 80003bc6 <iunlockput>
  iput(ip);
    80005670:	8526                	mv	a0,s1
    80005672:	ffffe097          	auipc	ra,0xffffe
    80005676:	4ac080e7          	jalr	1196(ra) # 80003b1e <iput>
  end_op();
    8000567a:	fffff097          	auipc	ra,0xfffff
    8000567e:	d08080e7          	jalr	-760(ra) # 80004382 <end_op>
  return 0;
    80005682:	4781                	li	a5,0
    80005684:	a085                	j	800056e4 <sys_link+0x13c>
    end_op();
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	cfc080e7          	jalr	-772(ra) # 80004382 <end_op>
    return -1;
    8000568e:	57fd                	li	a5,-1
    80005690:	a891                	j	800056e4 <sys_link+0x13c>
    iunlockput(ip);
    80005692:	8526                	mv	a0,s1
    80005694:	ffffe097          	auipc	ra,0xffffe
    80005698:	532080e7          	jalr	1330(ra) # 80003bc6 <iunlockput>
    end_op();
    8000569c:	fffff097          	auipc	ra,0xfffff
    800056a0:	ce6080e7          	jalr	-794(ra) # 80004382 <end_op>
    return -1;
    800056a4:	57fd                	li	a5,-1
    800056a6:	a83d                	j	800056e4 <sys_link+0x13c>
    iunlockput(dp);
    800056a8:	854a                	mv	a0,s2
    800056aa:	ffffe097          	auipc	ra,0xffffe
    800056ae:	51c080e7          	jalr	1308(ra) # 80003bc6 <iunlockput>
  ilock(ip);
    800056b2:	8526                	mv	a0,s1
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	2b0080e7          	jalr	688(ra) # 80003964 <ilock>
  ip->nlink--;
    800056bc:	04a4d783          	lhu	a5,74(s1)
    800056c0:	37fd                	addw	a5,a5,-1
    800056c2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056c6:	8526                	mv	a0,s1
    800056c8:	ffffe097          	auipc	ra,0xffffe
    800056cc:	1d0080e7          	jalr	464(ra) # 80003898 <iupdate>
  iunlockput(ip);
    800056d0:	8526                	mv	a0,s1
    800056d2:	ffffe097          	auipc	ra,0xffffe
    800056d6:	4f4080e7          	jalr	1268(ra) # 80003bc6 <iunlockput>
  end_op();
    800056da:	fffff097          	auipc	ra,0xfffff
    800056de:	ca8080e7          	jalr	-856(ra) # 80004382 <end_op>
  return -1;
    800056e2:	57fd                	li	a5,-1
}
    800056e4:	853e                	mv	a0,a5
    800056e6:	70b2                	ld	ra,296(sp)
    800056e8:	7412                	ld	s0,288(sp)
    800056ea:	64f2                	ld	s1,280(sp)
    800056ec:	6952                	ld	s2,272(sp)
    800056ee:	6155                	add	sp,sp,304
    800056f0:	8082                	ret

00000000800056f2 <sys_unlink>:
{
    800056f2:	7151                	add	sp,sp,-240
    800056f4:	f586                	sd	ra,232(sp)
    800056f6:	f1a2                	sd	s0,224(sp)
    800056f8:	eda6                	sd	s1,216(sp)
    800056fa:	e9ca                	sd	s2,208(sp)
    800056fc:	e5ce                	sd	s3,200(sp)
    800056fe:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005700:	08000613          	li	a2,128
    80005704:	f3040593          	add	a1,s0,-208
    80005708:	4501                	li	a0,0
    8000570a:	ffffd097          	auipc	ra,0xffffd
    8000570e:	734080e7          	jalr	1844(ra) # 80002e3e <argstr>
    80005712:	18054163          	bltz	a0,80005894 <sys_unlink+0x1a2>
  begin_op();
    80005716:	fffff097          	auipc	ra,0xfffff
    8000571a:	bf2080e7          	jalr	-1038(ra) # 80004308 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000571e:	fb040593          	add	a1,s0,-80
    80005722:	f3040513          	add	a0,s0,-208
    80005726:	fffff097          	auipc	ra,0xfffff
    8000572a:	a10080e7          	jalr	-1520(ra) # 80004136 <nameiparent>
    8000572e:	84aa                	mv	s1,a0
    80005730:	c979                	beqz	a0,80005806 <sys_unlink+0x114>
  ilock(dp);
    80005732:	ffffe097          	auipc	ra,0xffffe
    80005736:	232080e7          	jalr	562(ra) # 80003964 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000573a:	00003597          	auipc	a1,0x3
    8000573e:	fae58593          	add	a1,a1,-82 # 800086e8 <syscalls+0x2c0>
    80005742:	fb040513          	add	a0,s0,-80
    80005746:	ffffe097          	auipc	ra,0xffffe
    8000574a:	6e6080e7          	jalr	1766(ra) # 80003e2c <namecmp>
    8000574e:	14050a63          	beqz	a0,800058a2 <sys_unlink+0x1b0>
    80005752:	00003597          	auipc	a1,0x3
    80005756:	f9e58593          	add	a1,a1,-98 # 800086f0 <syscalls+0x2c8>
    8000575a:	fb040513          	add	a0,s0,-80
    8000575e:	ffffe097          	auipc	ra,0xffffe
    80005762:	6ce080e7          	jalr	1742(ra) # 80003e2c <namecmp>
    80005766:	12050e63          	beqz	a0,800058a2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000576a:	f2c40613          	add	a2,s0,-212
    8000576e:	fb040593          	add	a1,s0,-80
    80005772:	8526                	mv	a0,s1
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	6d2080e7          	jalr	1746(ra) # 80003e46 <dirlookup>
    8000577c:	892a                	mv	s2,a0
    8000577e:	12050263          	beqz	a0,800058a2 <sys_unlink+0x1b0>
  ilock(ip);
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	1e2080e7          	jalr	482(ra) # 80003964 <ilock>
  if(ip->nlink < 1)
    8000578a:	04a91783          	lh	a5,74(s2)
    8000578e:	08f05263          	blez	a5,80005812 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005792:	04491703          	lh	a4,68(s2)
    80005796:	4785                	li	a5,1
    80005798:	08f70563          	beq	a4,a5,80005822 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000579c:	4641                	li	a2,16
    8000579e:	4581                	li	a1,0
    800057a0:	fc040513          	add	a0,s0,-64
    800057a4:	ffffb097          	auipc	ra,0xffffb
    800057a8:	63e080e7          	jalr	1598(ra) # 80000de2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057ac:	4741                	li	a4,16
    800057ae:	f2c42683          	lw	a3,-212(s0)
    800057b2:	fc040613          	add	a2,s0,-64
    800057b6:	4581                	li	a1,0
    800057b8:	8526                	mv	a0,s1
    800057ba:	ffffe097          	auipc	ra,0xffffe
    800057be:	556080e7          	jalr	1366(ra) # 80003d10 <writei>
    800057c2:	47c1                	li	a5,16
    800057c4:	0af51563          	bne	a0,a5,8000586e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057c8:	04491703          	lh	a4,68(s2)
    800057cc:	4785                	li	a5,1
    800057ce:	0af70863          	beq	a4,a5,8000587e <sys_unlink+0x18c>
  iunlockput(dp);
    800057d2:	8526                	mv	a0,s1
    800057d4:	ffffe097          	auipc	ra,0xffffe
    800057d8:	3f2080e7          	jalr	1010(ra) # 80003bc6 <iunlockput>
  ip->nlink--;
    800057dc:	04a95783          	lhu	a5,74(s2)
    800057e0:	37fd                	addw	a5,a5,-1
    800057e2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057e6:	854a                	mv	a0,s2
    800057e8:	ffffe097          	auipc	ra,0xffffe
    800057ec:	0b0080e7          	jalr	176(ra) # 80003898 <iupdate>
  iunlockput(ip);
    800057f0:	854a                	mv	a0,s2
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	3d4080e7          	jalr	980(ra) # 80003bc6 <iunlockput>
  end_op();
    800057fa:	fffff097          	auipc	ra,0xfffff
    800057fe:	b88080e7          	jalr	-1144(ra) # 80004382 <end_op>
  return 0;
    80005802:	4501                	li	a0,0
    80005804:	a84d                	j	800058b6 <sys_unlink+0x1c4>
    end_op();
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	b7c080e7          	jalr	-1156(ra) # 80004382 <end_op>
    return -1;
    8000580e:	557d                	li	a0,-1
    80005810:	a05d                	j	800058b6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005812:	00003517          	auipc	a0,0x3
    80005816:	f0650513          	add	a0,a0,-250 # 80008718 <syscalls+0x2f0>
    8000581a:	ffffb097          	auipc	ra,0xffffb
    8000581e:	d28080e7          	jalr	-728(ra) # 80000542 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005822:	04c92703          	lw	a4,76(s2)
    80005826:	02000793          	li	a5,32
    8000582a:	f6e7f9e3          	bgeu	a5,a4,8000579c <sys_unlink+0xaa>
    8000582e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005832:	4741                	li	a4,16
    80005834:	86ce                	mv	a3,s3
    80005836:	f1840613          	add	a2,s0,-232
    8000583a:	4581                	li	a1,0
    8000583c:	854a                	mv	a0,s2
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	3da080e7          	jalr	986(ra) # 80003c18 <readi>
    80005846:	47c1                	li	a5,16
    80005848:	00f51b63          	bne	a0,a5,8000585e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000584c:	f1845783          	lhu	a5,-232(s0)
    80005850:	e7a1                	bnez	a5,80005898 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005852:	29c1                	addw	s3,s3,16
    80005854:	04c92783          	lw	a5,76(s2)
    80005858:	fcf9ede3          	bltu	s3,a5,80005832 <sys_unlink+0x140>
    8000585c:	b781                	j	8000579c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000585e:	00003517          	auipc	a0,0x3
    80005862:	ed250513          	add	a0,a0,-302 # 80008730 <syscalls+0x308>
    80005866:	ffffb097          	auipc	ra,0xffffb
    8000586a:	cdc080e7          	jalr	-804(ra) # 80000542 <panic>
    panic("unlink: writei");
    8000586e:	00003517          	auipc	a0,0x3
    80005872:	eda50513          	add	a0,a0,-294 # 80008748 <syscalls+0x320>
    80005876:	ffffb097          	auipc	ra,0xffffb
    8000587a:	ccc080e7          	jalr	-820(ra) # 80000542 <panic>
    dp->nlink--;
    8000587e:	04a4d783          	lhu	a5,74(s1)
    80005882:	37fd                	addw	a5,a5,-1
    80005884:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005888:	8526                	mv	a0,s1
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	00e080e7          	jalr	14(ra) # 80003898 <iupdate>
    80005892:	b781                	j	800057d2 <sys_unlink+0xe0>
    return -1;
    80005894:	557d                	li	a0,-1
    80005896:	a005                	j	800058b6 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005898:	854a                	mv	a0,s2
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	32c080e7          	jalr	812(ra) # 80003bc6 <iunlockput>
  iunlockput(dp);
    800058a2:	8526                	mv	a0,s1
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	322080e7          	jalr	802(ra) # 80003bc6 <iunlockput>
  end_op();
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	ad6080e7          	jalr	-1322(ra) # 80004382 <end_op>
  return -1;
    800058b4:	557d                	li	a0,-1
}
    800058b6:	70ae                	ld	ra,232(sp)
    800058b8:	740e                	ld	s0,224(sp)
    800058ba:	64ee                	ld	s1,216(sp)
    800058bc:	694e                	ld	s2,208(sp)
    800058be:	69ae                	ld	s3,200(sp)
    800058c0:	616d                	add	sp,sp,240
    800058c2:	8082                	ret

00000000800058c4 <sys_open>:

uint64
sys_open(void)
{
    800058c4:	7131                	add	sp,sp,-192
    800058c6:	fd06                	sd	ra,184(sp)
    800058c8:	f922                	sd	s0,176(sp)
    800058ca:	f526                	sd	s1,168(sp)
    800058cc:	f14a                	sd	s2,160(sp)
    800058ce:	ed4e                	sd	s3,152(sp)
    800058d0:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058d2:	08000613          	li	a2,128
    800058d6:	f5040593          	add	a1,s0,-176
    800058da:	4501                	li	a0,0
    800058dc:	ffffd097          	auipc	ra,0xffffd
    800058e0:	562080e7          	jalr	1378(ra) # 80002e3e <argstr>
    return -1;
    800058e4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058e6:	0c054063          	bltz	a0,800059a6 <sys_open+0xe2>
    800058ea:	f4c40593          	add	a1,s0,-180
    800058ee:	4505                	li	a0,1
    800058f0:	ffffd097          	auipc	ra,0xffffd
    800058f4:	50a080e7          	jalr	1290(ra) # 80002dfa <argint>
    800058f8:	0a054763          	bltz	a0,800059a6 <sys_open+0xe2>

  begin_op();
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	a0c080e7          	jalr	-1524(ra) # 80004308 <begin_op>

  if(omode & O_CREATE){
    80005904:	f4c42783          	lw	a5,-180(s0)
    80005908:	2007f793          	and	a5,a5,512
    8000590c:	cbd5                	beqz	a5,800059c0 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    8000590e:	4681                	li	a3,0
    80005910:	4601                	li	a2,0
    80005912:	4589                	li	a1,2
    80005914:	f5040513          	add	a0,s0,-176
    80005918:	00000097          	auipc	ra,0x0
    8000591c:	974080e7          	jalr	-1676(ra) # 8000528c <create>
    80005920:	892a                	mv	s2,a0
    if(ip == 0){
    80005922:	c951                	beqz	a0,800059b6 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005924:	04491703          	lh	a4,68(s2)
    80005928:	478d                	li	a5,3
    8000592a:	00f71763          	bne	a4,a5,80005938 <sys_open+0x74>
    8000592e:	04695703          	lhu	a4,70(s2)
    80005932:	47a5                	li	a5,9
    80005934:	0ce7eb63          	bltu	a5,a4,80005a0a <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	dde080e7          	jalr	-546(ra) # 80004716 <filealloc>
    80005940:	89aa                	mv	s3,a0
    80005942:	c565                	beqz	a0,80005a2a <sys_open+0x166>
    80005944:	00000097          	auipc	ra,0x0
    80005948:	906080e7          	jalr	-1786(ra) # 8000524a <fdalloc>
    8000594c:	84aa                	mv	s1,a0
    8000594e:	0c054963          	bltz	a0,80005a20 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005952:	04491703          	lh	a4,68(s2)
    80005956:	478d                	li	a5,3
    80005958:	0ef70463          	beq	a4,a5,80005a40 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000595c:	4789                	li	a5,2
    8000595e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005962:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005966:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000596a:	f4c42783          	lw	a5,-180(s0)
    8000596e:	0017c713          	xor	a4,a5,1
    80005972:	8b05                	and	a4,a4,1
    80005974:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005978:	0037f713          	and	a4,a5,3
    8000597c:	00e03733          	snez	a4,a4
    80005980:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005984:	4007f793          	and	a5,a5,1024
    80005988:	c791                	beqz	a5,80005994 <sys_open+0xd0>
    8000598a:	04491703          	lh	a4,68(s2)
    8000598e:	4789                	li	a5,2
    80005990:	0af70f63          	beq	a4,a5,80005a4e <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005994:	854a                	mv	a0,s2
    80005996:	ffffe097          	auipc	ra,0xffffe
    8000599a:	090080e7          	jalr	144(ra) # 80003a26 <iunlock>
  end_op();
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	9e4080e7          	jalr	-1564(ra) # 80004382 <end_op>

  return fd;
}
    800059a6:	8526                	mv	a0,s1
    800059a8:	70ea                	ld	ra,184(sp)
    800059aa:	744a                	ld	s0,176(sp)
    800059ac:	74aa                	ld	s1,168(sp)
    800059ae:	790a                	ld	s2,160(sp)
    800059b0:	69ea                	ld	s3,152(sp)
    800059b2:	6129                	add	sp,sp,192
    800059b4:	8082                	ret
      end_op();
    800059b6:	fffff097          	auipc	ra,0xfffff
    800059ba:	9cc080e7          	jalr	-1588(ra) # 80004382 <end_op>
      return -1;
    800059be:	b7e5                	j	800059a6 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    800059c0:	f5040513          	add	a0,s0,-176
    800059c4:	ffffe097          	auipc	ra,0xffffe
    800059c8:	754080e7          	jalr	1876(ra) # 80004118 <namei>
    800059cc:	892a                	mv	s2,a0
    800059ce:	c905                	beqz	a0,800059fe <sys_open+0x13a>
    ilock(ip);
    800059d0:	ffffe097          	auipc	ra,0xffffe
    800059d4:	f94080e7          	jalr	-108(ra) # 80003964 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059d8:	04491703          	lh	a4,68(s2)
    800059dc:	4785                	li	a5,1
    800059de:	f4f713e3          	bne	a4,a5,80005924 <sys_open+0x60>
    800059e2:	f4c42783          	lw	a5,-180(s0)
    800059e6:	dba9                	beqz	a5,80005938 <sys_open+0x74>
      iunlockput(ip);
    800059e8:	854a                	mv	a0,s2
    800059ea:	ffffe097          	auipc	ra,0xffffe
    800059ee:	1dc080e7          	jalr	476(ra) # 80003bc6 <iunlockput>
      end_op();
    800059f2:	fffff097          	auipc	ra,0xfffff
    800059f6:	990080e7          	jalr	-1648(ra) # 80004382 <end_op>
      return -1;
    800059fa:	54fd                	li	s1,-1
    800059fc:	b76d                	j	800059a6 <sys_open+0xe2>
      end_op();
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	984080e7          	jalr	-1660(ra) # 80004382 <end_op>
      return -1;
    80005a06:	54fd                	li	s1,-1
    80005a08:	bf79                	j	800059a6 <sys_open+0xe2>
    iunlockput(ip);
    80005a0a:	854a                	mv	a0,s2
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	1ba080e7          	jalr	442(ra) # 80003bc6 <iunlockput>
    end_op();
    80005a14:	fffff097          	auipc	ra,0xfffff
    80005a18:	96e080e7          	jalr	-1682(ra) # 80004382 <end_op>
    return -1;
    80005a1c:	54fd                	li	s1,-1
    80005a1e:	b761                	j	800059a6 <sys_open+0xe2>
      fileclose(f);
    80005a20:	854e                	mv	a0,s3
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	db0080e7          	jalr	-592(ra) # 800047d2 <fileclose>
    iunlockput(ip);
    80005a2a:	854a                	mv	a0,s2
    80005a2c:	ffffe097          	auipc	ra,0xffffe
    80005a30:	19a080e7          	jalr	410(ra) # 80003bc6 <iunlockput>
    end_op();
    80005a34:	fffff097          	auipc	ra,0xfffff
    80005a38:	94e080e7          	jalr	-1714(ra) # 80004382 <end_op>
    return -1;
    80005a3c:	54fd                	li	s1,-1
    80005a3e:	b7a5                	j	800059a6 <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005a40:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a44:	04691783          	lh	a5,70(s2)
    80005a48:	02f99223          	sh	a5,36(s3)
    80005a4c:	bf29                	j	80005966 <sys_open+0xa2>
    itrunc(ip);
    80005a4e:	854a                	mv	a0,s2
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	022080e7          	jalr	34(ra) # 80003a72 <itrunc>
    80005a58:	bf35                	j	80005994 <sys_open+0xd0>

0000000080005a5a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a5a:	7175                	add	sp,sp,-144
    80005a5c:	e506                	sd	ra,136(sp)
    80005a5e:	e122                	sd	s0,128(sp)
    80005a60:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	8a6080e7          	jalr	-1882(ra) # 80004308 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a6a:	08000613          	li	a2,128
    80005a6e:	f7040593          	add	a1,s0,-144
    80005a72:	4501                	li	a0,0
    80005a74:	ffffd097          	auipc	ra,0xffffd
    80005a78:	3ca080e7          	jalr	970(ra) # 80002e3e <argstr>
    80005a7c:	02054963          	bltz	a0,80005aae <sys_mkdir+0x54>
    80005a80:	4681                	li	a3,0
    80005a82:	4601                	li	a2,0
    80005a84:	4585                	li	a1,1
    80005a86:	f7040513          	add	a0,s0,-144
    80005a8a:	00000097          	auipc	ra,0x0
    80005a8e:	802080e7          	jalr	-2046(ra) # 8000528c <create>
    80005a92:	cd11                	beqz	a0,80005aae <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a94:	ffffe097          	auipc	ra,0xffffe
    80005a98:	132080e7          	jalr	306(ra) # 80003bc6 <iunlockput>
  end_op();
    80005a9c:	fffff097          	auipc	ra,0xfffff
    80005aa0:	8e6080e7          	jalr	-1818(ra) # 80004382 <end_op>
  return 0;
    80005aa4:	4501                	li	a0,0
}
    80005aa6:	60aa                	ld	ra,136(sp)
    80005aa8:	640a                	ld	s0,128(sp)
    80005aaa:	6149                	add	sp,sp,144
    80005aac:	8082                	ret
    end_op();
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	8d4080e7          	jalr	-1836(ra) # 80004382 <end_op>
    return -1;
    80005ab6:	557d                	li	a0,-1
    80005ab8:	b7fd                	j	80005aa6 <sys_mkdir+0x4c>

0000000080005aba <sys_mknod>:

uint64
sys_mknod(void)
{
    80005aba:	7135                	add	sp,sp,-160
    80005abc:	ed06                	sd	ra,152(sp)
    80005abe:	e922                	sd	s0,144(sp)
    80005ac0:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ac2:	fffff097          	auipc	ra,0xfffff
    80005ac6:	846080e7          	jalr	-1978(ra) # 80004308 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005aca:	08000613          	li	a2,128
    80005ace:	f7040593          	add	a1,s0,-144
    80005ad2:	4501                	li	a0,0
    80005ad4:	ffffd097          	auipc	ra,0xffffd
    80005ad8:	36a080e7          	jalr	874(ra) # 80002e3e <argstr>
    80005adc:	04054a63          	bltz	a0,80005b30 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005ae0:	f6c40593          	add	a1,s0,-148
    80005ae4:	4505                	li	a0,1
    80005ae6:	ffffd097          	auipc	ra,0xffffd
    80005aea:	314080e7          	jalr	788(ra) # 80002dfa <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005aee:	04054163          	bltz	a0,80005b30 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005af2:	f6840593          	add	a1,s0,-152
    80005af6:	4509                	li	a0,2
    80005af8:	ffffd097          	auipc	ra,0xffffd
    80005afc:	302080e7          	jalr	770(ra) # 80002dfa <argint>
     argint(1, &major) < 0 ||
    80005b00:	02054863          	bltz	a0,80005b30 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b04:	f6841683          	lh	a3,-152(s0)
    80005b08:	f6c41603          	lh	a2,-148(s0)
    80005b0c:	458d                	li	a1,3
    80005b0e:	f7040513          	add	a0,s0,-144
    80005b12:	fffff097          	auipc	ra,0xfffff
    80005b16:	77a080e7          	jalr	1914(ra) # 8000528c <create>
     argint(2, &minor) < 0 ||
    80005b1a:	c919                	beqz	a0,80005b30 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	0aa080e7          	jalr	170(ra) # 80003bc6 <iunlockput>
  end_op();
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	85e080e7          	jalr	-1954(ra) # 80004382 <end_op>
  return 0;
    80005b2c:	4501                	li	a0,0
    80005b2e:	a031                	j	80005b3a <sys_mknod+0x80>
    end_op();
    80005b30:	fffff097          	auipc	ra,0xfffff
    80005b34:	852080e7          	jalr	-1966(ra) # 80004382 <end_op>
    return -1;
    80005b38:	557d                	li	a0,-1
}
    80005b3a:	60ea                	ld	ra,152(sp)
    80005b3c:	644a                	ld	s0,144(sp)
    80005b3e:	610d                	add	sp,sp,160
    80005b40:	8082                	ret

0000000080005b42 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b42:	7135                	add	sp,sp,-160
    80005b44:	ed06                	sd	ra,152(sp)
    80005b46:	e922                	sd	s0,144(sp)
    80005b48:	e526                	sd	s1,136(sp)
    80005b4a:	e14a                	sd	s2,128(sp)
    80005b4c:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b4e:	ffffc097          	auipc	ra,0xffffc
    80005b52:	1bc080e7          	jalr	444(ra) # 80001d0a <myproc>
    80005b56:	892a                	mv	s2,a0
  
  begin_op();
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	7b0080e7          	jalr	1968(ra) # 80004308 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b60:	08000613          	li	a2,128
    80005b64:	f6040593          	add	a1,s0,-160
    80005b68:	4501                	li	a0,0
    80005b6a:	ffffd097          	auipc	ra,0xffffd
    80005b6e:	2d4080e7          	jalr	724(ra) # 80002e3e <argstr>
    80005b72:	04054b63          	bltz	a0,80005bc8 <sys_chdir+0x86>
    80005b76:	f6040513          	add	a0,s0,-160
    80005b7a:	ffffe097          	auipc	ra,0xffffe
    80005b7e:	59e080e7          	jalr	1438(ra) # 80004118 <namei>
    80005b82:	84aa                	mv	s1,a0
    80005b84:	c131                	beqz	a0,80005bc8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b86:	ffffe097          	auipc	ra,0xffffe
    80005b8a:	dde080e7          	jalr	-546(ra) # 80003964 <ilock>
  if(ip->type != T_DIR){
    80005b8e:	04449703          	lh	a4,68(s1)
    80005b92:	4785                	li	a5,1
    80005b94:	04f71063          	bne	a4,a5,80005bd4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b98:	8526                	mv	a0,s1
    80005b9a:	ffffe097          	auipc	ra,0xffffe
    80005b9e:	e8c080e7          	jalr	-372(ra) # 80003a26 <iunlock>
  iput(p->cwd);
    80005ba2:	15093503          	ld	a0,336(s2)
    80005ba6:	ffffe097          	auipc	ra,0xffffe
    80005baa:	f78080e7          	jalr	-136(ra) # 80003b1e <iput>
  end_op();
    80005bae:	ffffe097          	auipc	ra,0xffffe
    80005bb2:	7d4080e7          	jalr	2004(ra) # 80004382 <end_op>
  p->cwd = ip;
    80005bb6:	14993823          	sd	s1,336(s2)
  return 0;
    80005bba:	4501                	li	a0,0
}
    80005bbc:	60ea                	ld	ra,152(sp)
    80005bbe:	644a                	ld	s0,144(sp)
    80005bc0:	64aa                	ld	s1,136(sp)
    80005bc2:	690a                	ld	s2,128(sp)
    80005bc4:	610d                	add	sp,sp,160
    80005bc6:	8082                	ret
    end_op();
    80005bc8:	ffffe097          	auipc	ra,0xffffe
    80005bcc:	7ba080e7          	jalr	1978(ra) # 80004382 <end_op>
    return -1;
    80005bd0:	557d                	li	a0,-1
    80005bd2:	b7ed                	j	80005bbc <sys_chdir+0x7a>
    iunlockput(ip);
    80005bd4:	8526                	mv	a0,s1
    80005bd6:	ffffe097          	auipc	ra,0xffffe
    80005bda:	ff0080e7          	jalr	-16(ra) # 80003bc6 <iunlockput>
    end_op();
    80005bde:	ffffe097          	auipc	ra,0xffffe
    80005be2:	7a4080e7          	jalr	1956(ra) # 80004382 <end_op>
    return -1;
    80005be6:	557d                	li	a0,-1
    80005be8:	bfd1                	j	80005bbc <sys_chdir+0x7a>

0000000080005bea <sys_exec>:

uint64
sys_exec(void)
{
    80005bea:	7121                	add	sp,sp,-448
    80005bec:	ff06                	sd	ra,440(sp)
    80005bee:	fb22                	sd	s0,432(sp)
    80005bf0:	f726                	sd	s1,424(sp)
    80005bf2:	f34a                	sd	s2,416(sp)
    80005bf4:	ef4e                	sd	s3,408(sp)
    80005bf6:	eb52                	sd	s4,400(sp)
    80005bf8:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bfa:	08000613          	li	a2,128
    80005bfe:	f5040593          	add	a1,s0,-176
    80005c02:	4501                	li	a0,0
    80005c04:	ffffd097          	auipc	ra,0xffffd
    80005c08:	23a080e7          	jalr	570(ra) # 80002e3e <argstr>
    return -1;
    80005c0c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c0e:	0c054a63          	bltz	a0,80005ce2 <sys_exec+0xf8>
    80005c12:	e4840593          	add	a1,s0,-440
    80005c16:	4505                	li	a0,1
    80005c18:	ffffd097          	auipc	ra,0xffffd
    80005c1c:	204080e7          	jalr	516(ra) # 80002e1c <argaddr>
    80005c20:	0c054163          	bltz	a0,80005ce2 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005c24:	10000613          	li	a2,256
    80005c28:	4581                	li	a1,0
    80005c2a:	e5040513          	add	a0,s0,-432
    80005c2e:	ffffb097          	auipc	ra,0xffffb
    80005c32:	1b4080e7          	jalr	436(ra) # 80000de2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c36:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005c3a:	89a6                	mv	s3,s1
    80005c3c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c3e:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c42:	00391513          	sll	a0,s2,0x3
    80005c46:	e4040593          	add	a1,s0,-448
    80005c4a:	e4843783          	ld	a5,-440(s0)
    80005c4e:	953e                	add	a0,a0,a5
    80005c50:	ffffd097          	auipc	ra,0xffffd
    80005c54:	110080e7          	jalr	272(ra) # 80002d60 <fetchaddr>
    80005c58:	02054a63          	bltz	a0,80005c8c <sys_exec+0xa2>
      goto bad;
    }
    if(uarg == 0){
    80005c5c:	e4043783          	ld	a5,-448(s0)
    80005c60:	c3b9                	beqz	a5,80005ca6 <sys_exec+0xbc>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c62:	ffffb097          	auipc	ra,0xffffb
    80005c66:	f88080e7          	jalr	-120(ra) # 80000bea <kalloc>
    80005c6a:	85aa                	mv	a1,a0
    80005c6c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c70:	cd11                	beqz	a0,80005c8c <sys_exec+0xa2>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c72:	6605                	lui	a2,0x1
    80005c74:	e4043503          	ld	a0,-448(s0)
    80005c78:	ffffd097          	auipc	ra,0xffffd
    80005c7c:	13a080e7          	jalr	314(ra) # 80002db2 <fetchstr>
    80005c80:	00054663          	bltz	a0,80005c8c <sys_exec+0xa2>
    if(i >= NELEM(argv)){
    80005c84:	0905                	add	s2,s2,1
    80005c86:	09a1                	add	s3,s3,8
    80005c88:	fb491de3          	bne	s2,s4,80005c42 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c8c:	f5040913          	add	s2,s0,-176
    80005c90:	6088                	ld	a0,0(s1)
    80005c92:	c539                	beqz	a0,80005ce0 <sys_exec+0xf6>
    kfree(argv[i]);
    80005c94:	ffffb097          	auipc	ra,0xffffb
    80005c98:	df4080e7          	jalr	-524(ra) # 80000a88 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c9c:	04a1                	add	s1,s1,8
    80005c9e:	ff2499e3          	bne	s1,s2,80005c90 <sys_exec+0xa6>
  return -1;
    80005ca2:	597d                	li	s2,-1
    80005ca4:	a83d                	j	80005ce2 <sys_exec+0xf8>
      argv[i] = 0;
    80005ca6:	0009079b          	sext.w	a5,s2
    80005caa:	078e                	sll	a5,a5,0x3
    80005cac:	fd078793          	add	a5,a5,-48
    80005cb0:	97a2                	add	a5,a5,s0
    80005cb2:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005cb6:	e5040593          	add	a1,s0,-432
    80005cba:	f5040513          	add	a0,s0,-176
    80005cbe:	fffff097          	auipc	ra,0xfffff
    80005cc2:	196080e7          	jalr	406(ra) # 80004e54 <exec>
    80005cc6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cc8:	f5040993          	add	s3,s0,-176
    80005ccc:	6088                	ld	a0,0(s1)
    80005cce:	c911                	beqz	a0,80005ce2 <sys_exec+0xf8>
    kfree(argv[i]);
    80005cd0:	ffffb097          	auipc	ra,0xffffb
    80005cd4:	db8080e7          	jalr	-584(ra) # 80000a88 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cd8:	04a1                	add	s1,s1,8
    80005cda:	ff3499e3          	bne	s1,s3,80005ccc <sys_exec+0xe2>
    80005cde:	a011                	j	80005ce2 <sys_exec+0xf8>
  return -1;
    80005ce0:	597d                	li	s2,-1
}
    80005ce2:	854a                	mv	a0,s2
    80005ce4:	70fa                	ld	ra,440(sp)
    80005ce6:	745a                	ld	s0,432(sp)
    80005ce8:	74ba                	ld	s1,424(sp)
    80005cea:	791a                	ld	s2,416(sp)
    80005cec:	69fa                	ld	s3,408(sp)
    80005cee:	6a5a                	ld	s4,400(sp)
    80005cf0:	6139                	add	sp,sp,448
    80005cf2:	8082                	ret

0000000080005cf4 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005cf4:	7139                	add	sp,sp,-64
    80005cf6:	fc06                	sd	ra,56(sp)
    80005cf8:	f822                	sd	s0,48(sp)
    80005cfa:	f426                	sd	s1,40(sp)
    80005cfc:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005cfe:	ffffc097          	auipc	ra,0xffffc
    80005d02:	00c080e7          	jalr	12(ra) # 80001d0a <myproc>
    80005d06:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d08:	fd840593          	add	a1,s0,-40
    80005d0c:	4501                	li	a0,0
    80005d0e:	ffffd097          	auipc	ra,0xffffd
    80005d12:	10e080e7          	jalr	270(ra) # 80002e1c <argaddr>
    return -1;
    80005d16:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d18:	0e054063          	bltz	a0,80005df8 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d1c:	fc840593          	add	a1,s0,-56
    80005d20:	fd040513          	add	a0,s0,-48
    80005d24:	fffff097          	auipc	ra,0xfffff
    80005d28:	e04080e7          	jalr	-508(ra) # 80004b28 <pipealloc>
    return -1;
    80005d2c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d2e:	0c054563          	bltz	a0,80005df8 <sys_pipe+0x104>
  fd0 = -1;
    80005d32:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d36:	fd043503          	ld	a0,-48(s0)
    80005d3a:	fffff097          	auipc	ra,0xfffff
    80005d3e:	510080e7          	jalr	1296(ra) # 8000524a <fdalloc>
    80005d42:	fca42223          	sw	a0,-60(s0)
    80005d46:	08054c63          	bltz	a0,80005dde <sys_pipe+0xea>
    80005d4a:	fc843503          	ld	a0,-56(s0)
    80005d4e:	fffff097          	auipc	ra,0xfffff
    80005d52:	4fc080e7          	jalr	1276(ra) # 8000524a <fdalloc>
    80005d56:	fca42023          	sw	a0,-64(s0)
    80005d5a:	06054963          	bltz	a0,80005dcc <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d5e:	4691                	li	a3,4
    80005d60:	fc440613          	add	a2,s0,-60
    80005d64:	fd843583          	ld	a1,-40(s0)
    80005d68:	68a8                	ld	a0,80(s1)
    80005d6a:	ffffc097          	auipc	ra,0xffffc
    80005d6e:	c72080e7          	jalr	-910(ra) # 800019dc <copyout>
    80005d72:	02054063          	bltz	a0,80005d92 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d76:	4691                	li	a3,4
    80005d78:	fc040613          	add	a2,s0,-64
    80005d7c:	fd843583          	ld	a1,-40(s0)
    80005d80:	0591                	add	a1,a1,4
    80005d82:	68a8                	ld	a0,80(s1)
    80005d84:	ffffc097          	auipc	ra,0xffffc
    80005d88:	c58080e7          	jalr	-936(ra) # 800019dc <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d8c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d8e:	06055563          	bgez	a0,80005df8 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d92:	fc442783          	lw	a5,-60(s0)
    80005d96:	07e9                	add	a5,a5,26
    80005d98:	078e                	sll	a5,a5,0x3
    80005d9a:	97a6                	add	a5,a5,s1
    80005d9c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005da0:	fc042783          	lw	a5,-64(s0)
    80005da4:	07e9                	add	a5,a5,26
    80005da6:	078e                	sll	a5,a5,0x3
    80005da8:	00f48533          	add	a0,s1,a5
    80005dac:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005db0:	fd043503          	ld	a0,-48(s0)
    80005db4:	fffff097          	auipc	ra,0xfffff
    80005db8:	a1e080e7          	jalr	-1506(ra) # 800047d2 <fileclose>
    fileclose(wf);
    80005dbc:	fc843503          	ld	a0,-56(s0)
    80005dc0:	fffff097          	auipc	ra,0xfffff
    80005dc4:	a12080e7          	jalr	-1518(ra) # 800047d2 <fileclose>
    return -1;
    80005dc8:	57fd                	li	a5,-1
    80005dca:	a03d                	j	80005df8 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005dcc:	fc442783          	lw	a5,-60(s0)
    80005dd0:	0007c763          	bltz	a5,80005dde <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005dd4:	07e9                	add	a5,a5,26
    80005dd6:	078e                	sll	a5,a5,0x3
    80005dd8:	97a6                	add	a5,a5,s1
    80005dda:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005dde:	fd043503          	ld	a0,-48(s0)
    80005de2:	fffff097          	auipc	ra,0xfffff
    80005de6:	9f0080e7          	jalr	-1552(ra) # 800047d2 <fileclose>
    fileclose(wf);
    80005dea:	fc843503          	ld	a0,-56(s0)
    80005dee:	fffff097          	auipc	ra,0xfffff
    80005df2:	9e4080e7          	jalr	-1564(ra) # 800047d2 <fileclose>
    return -1;
    80005df6:	57fd                	li	a5,-1
}
    80005df8:	853e                	mv	a0,a5
    80005dfa:	70e2                	ld	ra,56(sp)
    80005dfc:	7442                	ld	s0,48(sp)
    80005dfe:	74a2                	ld	s1,40(sp)
    80005e00:	6121                	add	sp,sp,64
    80005e02:	8082                	ret
	...

0000000080005e10 <kernelvec>:
    80005e10:	7111                	add	sp,sp,-256
    80005e12:	e006                	sd	ra,0(sp)
    80005e14:	e40a                	sd	sp,8(sp)
    80005e16:	e80e                	sd	gp,16(sp)
    80005e18:	ec12                	sd	tp,24(sp)
    80005e1a:	f016                	sd	t0,32(sp)
    80005e1c:	f41a                	sd	t1,40(sp)
    80005e1e:	f81e                	sd	t2,48(sp)
    80005e20:	fc22                	sd	s0,56(sp)
    80005e22:	e0a6                	sd	s1,64(sp)
    80005e24:	e4aa                	sd	a0,72(sp)
    80005e26:	e8ae                	sd	a1,80(sp)
    80005e28:	ecb2                	sd	a2,88(sp)
    80005e2a:	f0b6                	sd	a3,96(sp)
    80005e2c:	f4ba                	sd	a4,104(sp)
    80005e2e:	f8be                	sd	a5,112(sp)
    80005e30:	fcc2                	sd	a6,120(sp)
    80005e32:	e146                	sd	a7,128(sp)
    80005e34:	e54a                	sd	s2,136(sp)
    80005e36:	e94e                	sd	s3,144(sp)
    80005e38:	ed52                	sd	s4,152(sp)
    80005e3a:	f156                	sd	s5,160(sp)
    80005e3c:	f55a                	sd	s6,168(sp)
    80005e3e:	f95e                	sd	s7,176(sp)
    80005e40:	fd62                	sd	s8,184(sp)
    80005e42:	e1e6                	sd	s9,192(sp)
    80005e44:	e5ea                	sd	s10,200(sp)
    80005e46:	e9ee                	sd	s11,208(sp)
    80005e48:	edf2                	sd	t3,216(sp)
    80005e4a:	f1f6                	sd	t4,224(sp)
    80005e4c:	f5fa                	sd	t5,232(sp)
    80005e4e:	f9fe                	sd	t6,240(sp)
    80005e50:	dddfc0ef          	jal	80002c2c <kerneltrap>
    80005e54:	6082                	ld	ra,0(sp)
    80005e56:	6122                	ld	sp,8(sp)
    80005e58:	61c2                	ld	gp,16(sp)
    80005e5a:	7282                	ld	t0,32(sp)
    80005e5c:	7322                	ld	t1,40(sp)
    80005e5e:	73c2                	ld	t2,48(sp)
    80005e60:	7462                	ld	s0,56(sp)
    80005e62:	6486                	ld	s1,64(sp)
    80005e64:	6526                	ld	a0,72(sp)
    80005e66:	65c6                	ld	a1,80(sp)
    80005e68:	6666                	ld	a2,88(sp)
    80005e6a:	7686                	ld	a3,96(sp)
    80005e6c:	7726                	ld	a4,104(sp)
    80005e6e:	77c6                	ld	a5,112(sp)
    80005e70:	7866                	ld	a6,120(sp)
    80005e72:	688a                	ld	a7,128(sp)
    80005e74:	692a                	ld	s2,136(sp)
    80005e76:	69ca                	ld	s3,144(sp)
    80005e78:	6a6a                	ld	s4,152(sp)
    80005e7a:	7a8a                	ld	s5,160(sp)
    80005e7c:	7b2a                	ld	s6,168(sp)
    80005e7e:	7bca                	ld	s7,176(sp)
    80005e80:	7c6a                	ld	s8,184(sp)
    80005e82:	6c8e                	ld	s9,192(sp)
    80005e84:	6d2e                	ld	s10,200(sp)
    80005e86:	6dce                	ld	s11,208(sp)
    80005e88:	6e6e                	ld	t3,216(sp)
    80005e8a:	7e8e                	ld	t4,224(sp)
    80005e8c:	7f2e                	ld	t5,232(sp)
    80005e8e:	7fce                	ld	t6,240(sp)
    80005e90:	6111                	add	sp,sp,256
    80005e92:	10200073          	sret
    80005e96:	00000013          	nop
    80005e9a:	00000013          	nop
    80005e9e:	0001                	nop

0000000080005ea0 <timervec>:
    80005ea0:	34051573          	csrrw	a0,mscratch,a0
    80005ea4:	e10c                	sd	a1,0(a0)
    80005ea6:	e510                	sd	a2,8(a0)
    80005ea8:	e914                	sd	a3,16(a0)
    80005eaa:	710c                	ld	a1,32(a0)
    80005eac:	7510                	ld	a2,40(a0)
    80005eae:	6194                	ld	a3,0(a1)
    80005eb0:	96b2                	add	a3,a3,a2
    80005eb2:	e194                	sd	a3,0(a1)
    80005eb4:	4589                	li	a1,2
    80005eb6:	14459073          	csrw	sip,a1
    80005eba:	6914                	ld	a3,16(a0)
    80005ebc:	6510                	ld	a2,8(a0)
    80005ebe:	610c                	ld	a1,0(a0)
    80005ec0:	34051573          	csrrw	a0,mscratch,a0
    80005ec4:	30200073          	mret
	...

0000000080005eca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eca:	1141                	add	sp,sp,-16
    80005ecc:	e422                	sd	s0,8(sp)
    80005ece:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ed0:	0c0007b7          	lui	a5,0xc000
    80005ed4:	4705                	li	a4,1
    80005ed6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ed8:	c3d8                	sw	a4,4(a5)
}
    80005eda:	6422                	ld	s0,8(sp)
    80005edc:	0141                	add	sp,sp,16
    80005ede:	8082                	ret

0000000080005ee0 <plicinithart>:

void
plicinithart(void)
{
    80005ee0:	1141                	add	sp,sp,-16
    80005ee2:	e406                	sd	ra,8(sp)
    80005ee4:	e022                	sd	s0,0(sp)
    80005ee6:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005ee8:	ffffc097          	auipc	ra,0xffffc
    80005eec:	df6080e7          	jalr	-522(ra) # 80001cde <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ef0:	0085171b          	sllw	a4,a0,0x8
    80005ef4:	0c0027b7          	lui	a5,0xc002
    80005ef8:	97ba                	add	a5,a5,a4
    80005efa:	40200713          	li	a4,1026
    80005efe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f02:	00d5151b          	sllw	a0,a0,0xd
    80005f06:	0c2017b7          	lui	a5,0xc201
    80005f0a:	97aa                	add	a5,a5,a0
    80005f0c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005f10:	60a2                	ld	ra,8(sp)
    80005f12:	6402                	ld	s0,0(sp)
    80005f14:	0141                	add	sp,sp,16
    80005f16:	8082                	ret

0000000080005f18 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f18:	1141                	add	sp,sp,-16
    80005f1a:	e406                	sd	ra,8(sp)
    80005f1c:	e022                	sd	s0,0(sp)
    80005f1e:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005f20:	ffffc097          	auipc	ra,0xffffc
    80005f24:	dbe080e7          	jalr	-578(ra) # 80001cde <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f28:	00d5151b          	sllw	a0,a0,0xd
    80005f2c:	0c2017b7          	lui	a5,0xc201
    80005f30:	97aa                	add	a5,a5,a0
  return irq;
}
    80005f32:	43c8                	lw	a0,4(a5)
    80005f34:	60a2                	ld	ra,8(sp)
    80005f36:	6402                	ld	s0,0(sp)
    80005f38:	0141                	add	sp,sp,16
    80005f3a:	8082                	ret

0000000080005f3c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f3c:	1101                	add	sp,sp,-32
    80005f3e:	ec06                	sd	ra,24(sp)
    80005f40:	e822                	sd	s0,16(sp)
    80005f42:	e426                	sd	s1,8(sp)
    80005f44:	1000                	add	s0,sp,32
    80005f46:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f48:	ffffc097          	auipc	ra,0xffffc
    80005f4c:	d96080e7          	jalr	-618(ra) # 80001cde <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f50:	00d5151b          	sllw	a0,a0,0xd
    80005f54:	0c2017b7          	lui	a5,0xc201
    80005f58:	97aa                	add	a5,a5,a0
    80005f5a:	c3c4                	sw	s1,4(a5)
}
    80005f5c:	60e2                	ld	ra,24(sp)
    80005f5e:	6442                	ld	s0,16(sp)
    80005f60:	64a2                	ld	s1,8(sp)
    80005f62:	6105                	add	sp,sp,32
    80005f64:	8082                	ret

0000000080005f66 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f66:	1141                	add	sp,sp,-16
    80005f68:	e406                	sd	ra,8(sp)
    80005f6a:	e022                	sd	s0,0(sp)
    80005f6c:	0800                	add	s0,sp,16
  if(i >= NUM)
    80005f6e:	479d                	li	a5,7
    80005f70:	04a7cb63          	blt	a5,a0,80005fc6 <free_desc+0x60>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005f74:	00025717          	auipc	a4,0x25
    80005f78:	08c70713          	add	a4,a4,140 # 8002b000 <disk>
    80005f7c:	972a                	add	a4,a4,a0
    80005f7e:	6789                	lui	a5,0x2
    80005f80:	97ba                	add	a5,a5,a4
    80005f82:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f86:	eba1                	bnez	a5,80005fd6 <free_desc+0x70>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005f88:	00451713          	sll	a4,a0,0x4
    80005f8c:	00027797          	auipc	a5,0x27
    80005f90:	0747b783          	ld	a5,116(a5) # 8002d000 <disk+0x2000>
    80005f94:	97ba                	add	a5,a5,a4
    80005f96:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005f9a:	00025717          	auipc	a4,0x25
    80005f9e:	06670713          	add	a4,a4,102 # 8002b000 <disk>
    80005fa2:	972a                	add	a4,a4,a0
    80005fa4:	6789                	lui	a5,0x2
    80005fa6:	97ba                	add	a5,a5,a4
    80005fa8:	4705                	li	a4,1
    80005faa:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005fae:	00027517          	auipc	a0,0x27
    80005fb2:	06a50513          	add	a0,a0,106 # 8002d018 <disk+0x2018>
    80005fb6:	ffffc097          	auipc	ra,0xffffc
    80005fba:	6ea080e7          	jalr	1770(ra) # 800026a0 <wakeup>
}
    80005fbe:	60a2                	ld	ra,8(sp)
    80005fc0:	6402                	ld	s0,0(sp)
    80005fc2:	0141                	add	sp,sp,16
    80005fc4:	8082                	ret
    panic("virtio_disk_intr 1");
    80005fc6:	00002517          	auipc	a0,0x2
    80005fca:	79250513          	add	a0,a0,1938 # 80008758 <syscalls+0x330>
    80005fce:	ffffa097          	auipc	ra,0xffffa
    80005fd2:	574080e7          	jalr	1396(ra) # 80000542 <panic>
    panic("virtio_disk_intr 2");
    80005fd6:	00002517          	auipc	a0,0x2
    80005fda:	79a50513          	add	a0,a0,1946 # 80008770 <syscalls+0x348>
    80005fde:	ffffa097          	auipc	ra,0xffffa
    80005fe2:	564080e7          	jalr	1380(ra) # 80000542 <panic>

0000000080005fe6 <virtio_disk_init>:
{
    80005fe6:	1101                	add	sp,sp,-32
    80005fe8:	ec06                	sd	ra,24(sp)
    80005fea:	e822                	sd	s0,16(sp)
    80005fec:	e426                	sd	s1,8(sp)
    80005fee:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ff0:	00002597          	auipc	a1,0x2
    80005ff4:	79858593          	add	a1,a1,1944 # 80008788 <syscalls+0x360>
    80005ff8:	00027517          	auipc	a0,0x27
    80005ffc:	0b050513          	add	a0,a0,176 # 8002d0a8 <disk+0x20a8>
    80006000:	ffffb097          	auipc	ra,0xffffb
    80006004:	c56080e7          	jalr	-938(ra) # 80000c56 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006008:	100017b7          	lui	a5,0x10001
    8000600c:	4398                	lw	a4,0(a5)
    8000600e:	2701                	sext.w	a4,a4
    80006010:	747277b7          	lui	a5,0x74727
    80006014:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006018:	0ef71063          	bne	a4,a5,800060f8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000601c:	100017b7          	lui	a5,0x10001
    80006020:	43dc                	lw	a5,4(a5)
    80006022:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006024:	4705                	li	a4,1
    80006026:	0ce79963          	bne	a5,a4,800060f8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000602a:	100017b7          	lui	a5,0x10001
    8000602e:	479c                	lw	a5,8(a5)
    80006030:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006032:	4709                	li	a4,2
    80006034:	0ce79263          	bne	a5,a4,800060f8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006038:	100017b7          	lui	a5,0x10001
    8000603c:	47d8                	lw	a4,12(a5)
    8000603e:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006040:	554d47b7          	lui	a5,0x554d4
    80006044:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006048:	0af71863          	bne	a4,a5,800060f8 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000604c:	100017b7          	lui	a5,0x10001
    80006050:	4705                	li	a4,1
    80006052:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006054:	470d                	li	a4,3
    80006056:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006058:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000605a:	c7ffe6b7          	lui	a3,0xc7ffe
    8000605e:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd075f>
    80006062:	8f75                	and	a4,a4,a3
    80006064:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006066:	472d                	li	a4,11
    80006068:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000606a:	473d                	li	a4,15
    8000606c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000606e:	6705                	lui	a4,0x1
    80006070:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006072:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006076:	5bdc                	lw	a5,52(a5)
    80006078:	2781                	sext.w	a5,a5
  if(max == 0)
    8000607a:	c7d9                	beqz	a5,80006108 <virtio_disk_init+0x122>
  if(max < NUM)
    8000607c:	471d                	li	a4,7
    8000607e:	08f77d63          	bgeu	a4,a5,80006118 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006082:	100014b7          	lui	s1,0x10001
    80006086:	47a1                	li	a5,8
    80006088:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000608a:	6609                	lui	a2,0x2
    8000608c:	4581                	li	a1,0
    8000608e:	00025517          	auipc	a0,0x25
    80006092:	f7250513          	add	a0,a0,-142 # 8002b000 <disk>
    80006096:	ffffb097          	auipc	ra,0xffffb
    8000609a:	d4c080e7          	jalr	-692(ra) # 80000de2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000609e:	00025717          	auipc	a4,0x25
    800060a2:	f6270713          	add	a4,a4,-158 # 8002b000 <disk>
    800060a6:	00c75793          	srl	a5,a4,0xc
    800060aa:	2781                	sext.w	a5,a5
    800060ac:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    800060ae:	00027797          	auipc	a5,0x27
    800060b2:	f5278793          	add	a5,a5,-174 # 8002d000 <disk+0x2000>
    800060b6:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    800060b8:	00025717          	auipc	a4,0x25
    800060bc:	fc870713          	add	a4,a4,-56 # 8002b080 <disk+0x80>
    800060c0:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    800060c2:	00026717          	auipc	a4,0x26
    800060c6:	f3e70713          	add	a4,a4,-194 # 8002c000 <disk+0x1000>
    800060ca:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800060cc:	4705                	li	a4,1
    800060ce:	00e78c23          	sb	a4,24(a5)
    800060d2:	00e78ca3          	sb	a4,25(a5)
    800060d6:	00e78d23          	sb	a4,26(a5)
    800060da:	00e78da3          	sb	a4,27(a5)
    800060de:	00e78e23          	sb	a4,28(a5)
    800060e2:	00e78ea3          	sb	a4,29(a5)
    800060e6:	00e78f23          	sb	a4,30(a5)
    800060ea:	00e78fa3          	sb	a4,31(a5)
}
    800060ee:	60e2                	ld	ra,24(sp)
    800060f0:	6442                	ld	s0,16(sp)
    800060f2:	64a2                	ld	s1,8(sp)
    800060f4:	6105                	add	sp,sp,32
    800060f6:	8082                	ret
    panic("could not find virtio disk");
    800060f8:	00002517          	auipc	a0,0x2
    800060fc:	6a050513          	add	a0,a0,1696 # 80008798 <syscalls+0x370>
    80006100:	ffffa097          	auipc	ra,0xffffa
    80006104:	442080e7          	jalr	1090(ra) # 80000542 <panic>
    panic("virtio disk has no queue 0");
    80006108:	00002517          	auipc	a0,0x2
    8000610c:	6b050513          	add	a0,a0,1712 # 800087b8 <syscalls+0x390>
    80006110:	ffffa097          	auipc	ra,0xffffa
    80006114:	432080e7          	jalr	1074(ra) # 80000542 <panic>
    panic("virtio disk max queue too short");
    80006118:	00002517          	auipc	a0,0x2
    8000611c:	6c050513          	add	a0,a0,1728 # 800087d8 <syscalls+0x3b0>
    80006120:	ffffa097          	auipc	ra,0xffffa
    80006124:	422080e7          	jalr	1058(ra) # 80000542 <panic>

0000000080006128 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006128:	7119                	add	sp,sp,-128
    8000612a:	fc86                	sd	ra,120(sp)
    8000612c:	f8a2                	sd	s0,112(sp)
    8000612e:	f4a6                	sd	s1,104(sp)
    80006130:	f0ca                	sd	s2,96(sp)
    80006132:	ecce                	sd	s3,88(sp)
    80006134:	e8d2                	sd	s4,80(sp)
    80006136:	e4d6                	sd	s5,72(sp)
    80006138:	e0da                	sd	s6,64(sp)
    8000613a:	fc5e                	sd	s7,56(sp)
    8000613c:	f862                	sd	s8,48(sp)
    8000613e:	f466                	sd	s9,40(sp)
    80006140:	f06a                	sd	s10,32(sp)
    80006142:	0100                	add	s0,sp,128
    80006144:	8a2a                	mv	s4,a0
    80006146:	8cae                	mv	s9,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006148:	00c52c03          	lw	s8,12(a0)
    8000614c:	001c1c1b          	sllw	s8,s8,0x1
    80006150:	1c02                	sll	s8,s8,0x20
    80006152:	020c5c13          	srl	s8,s8,0x20

  acquire(&disk.vdisk_lock);
    80006156:	00027517          	auipc	a0,0x27
    8000615a:	f5250513          	add	a0,a0,-174 # 8002d0a8 <disk+0x20a8>
    8000615e:	ffffb097          	auipc	ra,0xffffb
    80006162:	b88080e7          	jalr	-1144(ra) # 80000ce6 <acquire>
  for(int i = 0; i < 3; i++){
    80006166:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006168:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000616a:	00025b97          	auipc	s7,0x25
    8000616e:	e96b8b93          	add	s7,s7,-362 # 8002b000 <disk>
    80006172:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006174:	4a8d                	li	s5,3
    80006176:	a0b5                	j	800061e2 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006178:	00fb8733          	add	a4,s7,a5
    8000617c:	975a                	add	a4,a4,s6
    8000617e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006182:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006184:	0207c563          	bltz	a5,800061ae <virtio_disk_rw+0x86>
  for(int i = 0; i < 3; i++){
    80006188:	2605                	addw	a2,a2,1 # 2001 <_entry-0x7fffdfff>
    8000618a:	0591                	add	a1,a1,4
    8000618c:	19560c63          	beq	a2,s5,80006324 <virtio_disk_rw+0x1fc>
    idx[i] = alloc_desc();
    80006190:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006192:	00027717          	auipc	a4,0x27
    80006196:	e8670713          	add	a4,a4,-378 # 8002d018 <disk+0x2018>
    8000619a:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000619c:	00074683          	lbu	a3,0(a4)
    800061a0:	fee1                	bnez	a3,80006178 <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    800061a2:	2785                	addw	a5,a5,1
    800061a4:	0705                	add	a4,a4,1
    800061a6:	fe979be3          	bne	a5,s1,8000619c <virtio_disk_rw+0x74>
    idx[i] = alloc_desc();
    800061aa:	57fd                	li	a5,-1
    800061ac:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    800061ae:	00c05e63          	blez	a2,800061ca <virtio_disk_rw+0xa2>
    800061b2:	060a                	sll	a2,a2,0x2
    800061b4:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    800061b8:	0009a503          	lw	a0,0(s3)
    800061bc:	00000097          	auipc	ra,0x0
    800061c0:	daa080e7          	jalr	-598(ra) # 80005f66 <free_desc>
      for(int j = 0; j < i; j++)
    800061c4:	0991                	add	s3,s3,4
    800061c6:	ffa999e3          	bne	s3,s10,800061b8 <virtio_disk_rw+0x90>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061ca:	00027597          	auipc	a1,0x27
    800061ce:	ede58593          	add	a1,a1,-290 # 8002d0a8 <disk+0x20a8>
    800061d2:	00027517          	auipc	a0,0x27
    800061d6:	e4650513          	add	a0,a0,-442 # 8002d018 <disk+0x2018>
    800061da:	ffffc097          	auipc	ra,0xffffc
    800061de:	346080e7          	jalr	838(ra) # 80002520 <sleep>
  for(int i = 0; i < 3; i++){
    800061e2:	f9040993          	add	s3,s0,-112
{
    800061e6:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    800061e8:	864a                	mv	a2,s2
    800061ea:	b75d                	j	80006190 <virtio_disk_rw+0x68>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061ec:	00027717          	auipc	a4,0x27
    800061f0:	e1473703          	ld	a4,-492(a4) # 8002d000 <disk+0x2000>
    800061f4:	973e                	add	a4,a4,a5
    800061f6:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061fa:	00025517          	auipc	a0,0x25
    800061fe:	e0650513          	add	a0,a0,-506 # 8002b000 <disk>
    80006202:	00027717          	auipc	a4,0x27
    80006206:	dfe70713          	add	a4,a4,-514 # 8002d000 <disk+0x2000>
    8000620a:	6314                	ld	a3,0(a4)
    8000620c:	96be                	add	a3,a3,a5
    8000620e:	00c6d603          	lhu	a2,12(a3)
    80006212:	00166613          	or	a2,a2,1
    80006216:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000621a:	f9842683          	lw	a3,-104(s0)
    8000621e:	6310                	ld	a2,0(a4)
    80006220:	97b2                	add	a5,a5,a2
    80006222:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    80006226:	20048613          	add	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    8000622a:	0612                	sll	a2,a2,0x4
    8000622c:	962a                	add	a2,a2,a0
    8000622e:	02060823          	sb	zero,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006232:	00469793          	sll	a5,a3,0x4
    80006236:	630c                	ld	a1,0(a4)
    80006238:	95be                	add	a1,a1,a5
    8000623a:	6689                	lui	a3,0x2
    8000623c:	03068693          	add	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80006240:	96ca                	add	a3,a3,s2
    80006242:	96aa                	add	a3,a3,a0
    80006244:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    80006246:	6314                	ld	a3,0(a4)
    80006248:	96be                	add	a3,a3,a5
    8000624a:	4585                	li	a1,1
    8000624c:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000624e:	6314                	ld	a3,0(a4)
    80006250:	96be                	add	a3,a3,a5
    80006252:	4509                	li	a0,2
    80006254:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    80006258:	6314                	ld	a3,0(a4)
    8000625a:	97b6                	add	a5,a5,a3
    8000625c:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006260:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006264:	03463423          	sd	s4,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    80006268:	6714                	ld	a3,8(a4)
    8000626a:	0026d783          	lhu	a5,2(a3)
    8000626e:	8b9d                	and	a5,a5,7
    80006270:	0789                	add	a5,a5,2
    80006272:	0786                	sll	a5,a5,0x1
    80006274:	96be                	add	a3,a3,a5
    80006276:	00969023          	sh	s1,0(a3)
  __sync_synchronize();
    8000627a:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    8000627e:	6718                	ld	a4,8(a4)
    80006280:	00275783          	lhu	a5,2(a4)
    80006284:	2785                	addw	a5,a5,1
    80006286:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000628a:	100017b7          	lui	a5,0x10001
    8000628e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006292:	004a2783          	lw	a5,4(s4)
    80006296:	02b79163          	bne	a5,a1,800062b8 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000629a:	00027917          	auipc	s2,0x27
    8000629e:	e0e90913          	add	s2,s2,-498 # 8002d0a8 <disk+0x20a8>
  while(b->disk == 1) {
    800062a2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062a4:	85ca                	mv	a1,s2
    800062a6:	8552                	mv	a0,s4
    800062a8:	ffffc097          	auipc	ra,0xffffc
    800062ac:	278080e7          	jalr	632(ra) # 80002520 <sleep>
  while(b->disk == 1) {
    800062b0:	004a2783          	lw	a5,4(s4)
    800062b4:	fe9788e3          	beq	a5,s1,800062a4 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800062b8:	f9042483          	lw	s1,-112(s0)
    800062bc:	20048713          	add	a4,s1,512
    800062c0:	0712                	sll	a4,a4,0x4
    800062c2:	00025797          	auipc	a5,0x25
    800062c6:	d3e78793          	add	a5,a5,-706 # 8002b000 <disk>
    800062ca:	97ba                	add	a5,a5,a4
    800062cc:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800062d0:	00027917          	auipc	s2,0x27
    800062d4:	d3090913          	add	s2,s2,-720 # 8002d000 <disk+0x2000>
    800062d8:	a019                	j	800062de <virtio_disk_rw+0x1b6>
      i = disk.desc[i].next;
    800062da:	00e7d483          	lhu	s1,14(a5)
    free_desc(i);
    800062de:	8526                	mv	a0,s1
    800062e0:	00000097          	auipc	ra,0x0
    800062e4:	c86080e7          	jalr	-890(ra) # 80005f66 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800062e8:	0492                	sll	s1,s1,0x4
    800062ea:	00093783          	ld	a5,0(s2)
    800062ee:	97a6                	add	a5,a5,s1
    800062f0:	00c7d703          	lhu	a4,12(a5)
    800062f4:	8b05                	and	a4,a4,1
    800062f6:	f375                	bnez	a4,800062da <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062f8:	00027517          	auipc	a0,0x27
    800062fc:	db050513          	add	a0,a0,-592 # 8002d0a8 <disk+0x20a8>
    80006300:	ffffb097          	auipc	ra,0xffffb
    80006304:	a9a080e7          	jalr	-1382(ra) # 80000d9a <release>
}
    80006308:	70e6                	ld	ra,120(sp)
    8000630a:	7446                	ld	s0,112(sp)
    8000630c:	74a6                	ld	s1,104(sp)
    8000630e:	7906                	ld	s2,96(sp)
    80006310:	69e6                	ld	s3,88(sp)
    80006312:	6a46                	ld	s4,80(sp)
    80006314:	6aa6                	ld	s5,72(sp)
    80006316:	6b06                	ld	s6,64(sp)
    80006318:	7be2                	ld	s7,56(sp)
    8000631a:	7c42                	ld	s8,48(sp)
    8000631c:	7ca2                	ld	s9,40(sp)
    8000631e:	7d02                	ld	s10,32(sp)
    80006320:	6109                	add	sp,sp,128
    80006322:	8082                	ret
  if(write)
    80006324:	019037b3          	snez	a5,s9
    80006328:	f8f42023          	sw	a5,-128(s0)
  buf0.reserved = 0;
    8000632c:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006330:	f9843423          	sd	s8,-120(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006334:	f9042483          	lw	s1,-112(s0)
    80006338:	00449913          	sll	s2,s1,0x4
    8000633c:	00027997          	auipc	s3,0x27
    80006340:	cc498993          	add	s3,s3,-828 # 8002d000 <disk+0x2000>
    80006344:	0009ba83          	ld	s5,0(s3)
    80006348:	9aca                	add	s5,s5,s2
    8000634a:	f8040513          	add	a0,s0,-128
    8000634e:	ffffb097          	auipc	ra,0xffffb
    80006352:	f10080e7          	jalr	-240(ra) # 8000125e <kvmpa>
    80006356:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000635a:	0009b783          	ld	a5,0(s3)
    8000635e:	97ca                	add	a5,a5,s2
    80006360:	4741                	li	a4,16
    80006362:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006364:	0009b783          	ld	a5,0(s3)
    80006368:	97ca                	add	a5,a5,s2
    8000636a:	4705                	li	a4,1
    8000636c:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006370:	f9442783          	lw	a5,-108(s0)
    80006374:	0009b703          	ld	a4,0(s3)
    80006378:	974a                	add	a4,a4,s2
    8000637a:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000637e:	0792                	sll	a5,a5,0x4
    80006380:	0009b703          	ld	a4,0(s3)
    80006384:	973e                	add	a4,a4,a5
    80006386:	058a0693          	add	a3,s4,88
    8000638a:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    8000638c:	0009b703          	ld	a4,0(s3)
    80006390:	973e                	add	a4,a4,a5
    80006392:	40000693          	li	a3,1024
    80006396:	c714                	sw	a3,8(a4)
  if(write)
    80006398:	e40c9ae3          	bnez	s9,800061ec <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000639c:	00027717          	auipc	a4,0x27
    800063a0:	c6473703          	ld	a4,-924(a4) # 8002d000 <disk+0x2000>
    800063a4:	973e                	add	a4,a4,a5
    800063a6:	4689                	li	a3,2
    800063a8:	00d71623          	sh	a3,12(a4)
    800063ac:	b5b9                	j	800061fa <virtio_disk_rw+0xd2>

00000000800063ae <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063ae:	1101                	add	sp,sp,-32
    800063b0:	ec06                	sd	ra,24(sp)
    800063b2:	e822                	sd	s0,16(sp)
    800063b4:	e426                	sd	s1,8(sp)
    800063b6:	e04a                	sd	s2,0(sp)
    800063b8:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063ba:	00027517          	auipc	a0,0x27
    800063be:	cee50513          	add	a0,a0,-786 # 8002d0a8 <disk+0x20a8>
    800063c2:	ffffb097          	auipc	ra,0xffffb
    800063c6:	924080e7          	jalr	-1756(ra) # 80000ce6 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800063ca:	00027717          	auipc	a4,0x27
    800063ce:	c3670713          	add	a4,a4,-970 # 8002d000 <disk+0x2000>
    800063d2:	02075783          	lhu	a5,32(a4)
    800063d6:	6b18                	ld	a4,16(a4)
    800063d8:	00275683          	lhu	a3,2(a4)
    800063dc:	8ebd                	xor	a3,a3,a5
    800063de:	8a9d                	and	a3,a3,7
    800063e0:	cab9                	beqz	a3,80006436 <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800063e2:	00025917          	auipc	s2,0x25
    800063e6:	c1e90913          	add	s2,s2,-994 # 8002b000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800063ea:	00027497          	auipc	s1,0x27
    800063ee:	c1648493          	add	s1,s1,-1002 # 8002d000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800063f2:	078e                	sll	a5,a5,0x3
    800063f4:	973e                	add	a4,a4,a5
    800063f6:	435c                	lw	a5,4(a4)
    if(disk.info[id].status != 0)
    800063f8:	20078713          	add	a4,a5,512
    800063fc:	0712                	sll	a4,a4,0x4
    800063fe:	974a                	add	a4,a4,s2
    80006400:	03074703          	lbu	a4,48(a4)
    80006404:	ef21                	bnez	a4,8000645c <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    80006406:	20078793          	add	a5,a5,512
    8000640a:	0792                	sll	a5,a5,0x4
    8000640c:	97ca                	add	a5,a5,s2
    8000640e:	7798                	ld	a4,40(a5)
    80006410:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    80006414:	7788                	ld	a0,40(a5)
    80006416:	ffffc097          	auipc	ra,0xffffc
    8000641a:	28a080e7          	jalr	650(ra) # 800026a0 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    8000641e:	0204d783          	lhu	a5,32(s1)
    80006422:	2785                	addw	a5,a5,1
    80006424:	8b9d                	and	a5,a5,7
    80006426:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    8000642a:	6898                	ld	a4,16(s1)
    8000642c:	00275683          	lhu	a3,2(a4)
    80006430:	8a9d                	and	a3,a3,7
    80006432:	fcf690e3          	bne	a3,a5,800063f2 <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006436:	10001737          	lui	a4,0x10001
    8000643a:	533c                	lw	a5,96(a4)
    8000643c:	8b8d                	and	a5,a5,3
    8000643e:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006440:	00027517          	auipc	a0,0x27
    80006444:	c6850513          	add	a0,a0,-920 # 8002d0a8 <disk+0x20a8>
    80006448:	ffffb097          	auipc	ra,0xffffb
    8000644c:	952080e7          	jalr	-1710(ra) # 80000d9a <release>
}
    80006450:	60e2                	ld	ra,24(sp)
    80006452:	6442                	ld	s0,16(sp)
    80006454:	64a2                	ld	s1,8(sp)
    80006456:	6902                	ld	s2,0(sp)
    80006458:	6105                	add	sp,sp,32
    8000645a:	8082                	ret
      panic("virtio_disk_intr status");
    8000645c:	00002517          	auipc	a0,0x2
    80006460:	39c50513          	add	a0,a0,924 # 800087f8 <syscalls+0x3d0>
    80006464:	ffffa097          	auipc	ra,0xffffa
    80006468:	0de080e7          	jalr	222(ra) # 80000542 <panic>
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
