
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in i386_vm_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 03 01 00 00       	call   f0100141 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
		monitor(NULL);
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
f0100047:	8d 5d 14             	lea    0x14(%ebp),%ebx
{
	va_list ap;

	va_start(ap, fmt);
	cprintf("kernel warning at %s:%d: ", file, line);
f010004a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010004d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100051:	8b 45 08             	mov    0x8(%ebp),%eax
f0100054:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100058:	c7 04 24 e0 19 10 f0 	movl   $0xf01019e0,(%esp)
f010005f:	e8 c7 08 00 00       	call   f010092b <cprintf>
	vcprintf(fmt, ap);
f0100064:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100068:	8b 45 10             	mov    0x10(%ebp),%eax
f010006b:	89 04 24             	mov    %eax,(%esp)
f010006e:	e8 85 08 00 00       	call   f01008f8 <vcprintf>
	cprintf("\n");
f0100073:	c7 04 24 8b 1a 10 f0 	movl   $0xf0101a8b,(%esp)
f010007a:	e8 ac 08 00 00       	call   f010092b <cprintf>
	va_end(ap);
}
f010007f:	83 c4 14             	add    $0x14,%esp
f0100082:	5b                   	pop    %ebx
f0100083:	5d                   	pop    %ebp
f0100084:	c3                   	ret    

f0100085 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100085:	55                   	push   %ebp
f0100086:	89 e5                	mov    %esp,%ebp
f0100088:	56                   	push   %esi
f0100089:	53                   	push   %ebx
f010008a:	83 ec 10             	sub    $0x10,%esp
f010008d:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100090:	83 3d 00 23 11 f0 00 	cmpl   $0x0,0xf0112300
f0100097:	75 3d                	jne    f01000d6 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f0100099:	89 35 00 23 11 f0    	mov    %esi,0xf0112300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f010009f:	fa                   	cli    
f01000a0:	fc                   	cld    
/*
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
f01000a1:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");

	va_start(ap, fmt);
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000a7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01000ae:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000b2:	c7 04 24 fa 19 10 f0 	movl   $0xf01019fa,(%esp)
f01000b9:	e8 6d 08 00 00       	call   f010092b <cprintf>
	vcprintf(fmt, ap);
f01000be:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000c2:	89 34 24             	mov    %esi,(%esp)
f01000c5:	e8 2e 08 00 00       	call   f01008f8 <vcprintf>
	cprintf("\n");
f01000ca:	c7 04 24 8b 1a 10 f0 	movl   $0xf0101a8b,(%esp)
f01000d1:	e8 55 08 00 00       	call   f010092b <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000dd:	e8 ca 06 00 00       	call   f01007ac <monitor>
f01000e2:	eb f2                	jmp    f01000d6 <_panic+0x51>

f01000e4 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f01000e4:	55                   	push   %ebp
f01000e5:	89 e5                	mov    %esp,%ebp
f01000e7:	53                   	push   %ebx
f01000e8:	83 ec 14             	sub    $0x14,%esp
f01000eb:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f01000ee:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000f2:	c7 04 24 12 1a 10 f0 	movl   $0xf0101a12,(%esp)
f01000f9:	e8 2d 08 00 00       	call   f010092b <cprintf>
	if (x > 0)
f01000fe:	85 db                	test   %ebx,%ebx
f0100100:	7e 0d                	jle    f010010f <test_backtrace+0x2b>
		test_backtrace(x-1);
f0100102:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100105:	89 04 24             	mov    %eax,(%esp)
f0100108:	e8 d7 ff ff ff       	call   f01000e4 <test_backtrace>
f010010d:	eb 1c                	jmp    f010012b <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010010f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100116:	00 
f0100117:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010011e:	00 
f010011f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100126:	e8 75 05 00 00       	call   f01006a0 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f010012b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010012f:	c7 04 24 2e 1a 10 f0 	movl   $0xf0101a2e,(%esp)
f0100136:	e8 f0 07 00 00       	call   f010092b <cprintf>
}
f010013b:	83 c4 14             	add    $0x14,%esp
f010013e:	5b                   	pop    %ebx
f010013f:	5d                   	pop    %ebp
f0100140:	c3                   	ret    

f0100141 <i386_init>:

void
i386_init(void)
{
f0100141:	55                   	push   %ebp
f0100142:	89 e5                	mov    %esp,%ebp
f0100144:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100147:	b8 60 29 11 f0       	mov    $0xf0112960,%eax
f010014c:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f0100151:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100155:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010015c:	00 
f010015d:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f0100164:	e8 8d 13 00 00       	call   f01014f6 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100169:	e8 3c 03 00 00       	call   f01004aa <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010016e:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100175:	00 
f0100176:	c7 04 24 49 1a 10 f0 	movl   $0xf0101a49,(%esp)
f010017d:	e8 a9 07 00 00       	call   f010092b <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f0100182:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f0100189:	e8 56 ff ff ff       	call   f01000e4 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010018e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100195:	e8 12 06 00 00       	call   f01007ac <monitor>
f010019a:	eb f2                	jmp    f010018e <i386_init+0x4d>
f010019c:	00 00                	add    %al,(%eax)
	...

f01001a0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a8:	ec                   	in     (%dx),%al
f01001a9:	ec                   	in     (%dx),%al
f01001aa:	ec                   	in     (%dx),%al
f01001ab:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001ac:	5d                   	pop    %ebp
f01001ad:	c3                   	ret    

f01001ae <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001ae:	55                   	push   %ebp
f01001af:	89 e5                	mov    %esp,%ebp
f01001b1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b6:	ec                   	in     (%dx),%al
f01001b7:	89 c2                	mov    %eax,%edx
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01001be:	f6 c2 01             	test   $0x1,%dl
f01001c1:	74 09                	je     f01001cc <serial_proc_data+0x1e>
f01001c3:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001c8:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001c9:	0f b6 c0             	movzbl %al,%eax
}
f01001cc:	5d                   	pop    %ebp
f01001cd:	c3                   	ret    

f01001ce <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ce:	55                   	push   %ebp
f01001cf:	89 e5                	mov    %esp,%ebp
f01001d1:	57                   	push   %edi
f01001d2:	56                   	push   %esi
f01001d3:	53                   	push   %ebx
f01001d4:	83 ec 0c             	sub    $0xc,%esp
f01001d7:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
		cons.buf[cons.wpos++] = c;
f01001d9:	bb 44 25 11 f0       	mov    $0xf0112544,%ebx
f01001de:	bf 40 23 11 f0       	mov    $0xf0112340,%edi
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001e3:	eb 1e                	jmp    f0100203 <cons_intr+0x35>
		if (c == 0)
f01001e5:	85 c0                	test   %eax,%eax
f01001e7:	74 1a                	je     f0100203 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001e9:	8b 13                	mov    (%ebx),%edx
f01001eb:	88 04 17             	mov    %al,(%edi,%edx,1)
f01001ee:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01001f1:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01001f6:	0f 94 c2             	sete   %dl
f01001f9:	0f b6 d2             	movzbl %dl,%edx
f01001fc:	83 ea 01             	sub    $0x1,%edx
f01001ff:	21 d0                	and    %edx,%eax
f0100201:	89 03                	mov    %eax,(%ebx)
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100203:	ff d6                	call   *%esi
f0100205:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100208:	75 db                	jne    f01001e5 <cons_intr+0x17>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010020a:	83 c4 0c             	add    $0xc,%esp
f010020d:	5b                   	pop    %ebx
f010020e:	5e                   	pop    %esi
f010020f:	5f                   	pop    %edi
f0100210:	5d                   	pop    %ebp
f0100211:	c3                   	ret    

f0100212 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100212:	55                   	push   %ebp
f0100213:	89 e5                	mov    %esp,%ebp
f0100215:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100218:	b8 9a 05 10 f0       	mov    $0xf010059a,%eax
f010021d:	e8 ac ff ff ff       	call   f01001ce <cons_intr>
}
f0100222:	c9                   	leave  
f0100223:	c3                   	ret    

f0100224 <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100224:	55                   	push   %ebp
f0100225:	89 e5                	mov    %esp,%ebp
f0100227:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f010022a:	83 3d 24 23 11 f0 00 	cmpl   $0x0,0xf0112324
f0100231:	74 0a                	je     f010023d <serial_intr+0x19>
		cons_intr(serial_proc_data);
f0100233:	b8 ae 01 10 f0       	mov    $0xf01001ae,%eax
f0100238:	e8 91 ff ff ff       	call   f01001ce <cons_intr>
}
f010023d:	c9                   	leave  
f010023e:	c3                   	ret    

f010023f <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f010023f:	55                   	push   %ebp
f0100240:	89 e5                	mov    %esp,%ebp
f0100242:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100245:	e8 da ff ff ff       	call   f0100224 <serial_intr>
	kbd_intr();
f010024a:	e8 c3 ff ff ff       	call   f0100212 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010024f:	8b 15 40 25 11 f0    	mov    0xf0112540,%edx
f0100255:	b8 00 00 00 00       	mov    $0x0,%eax
f010025a:	3b 15 44 25 11 f0    	cmp    0xf0112544,%edx
f0100260:	74 21                	je     f0100283 <cons_getc+0x44>
		c = cons.buf[cons.rpos++];
f0100262:	0f b6 82 40 23 11 f0 	movzbl -0xfeedcc0(%edx),%eax
f0100269:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f010026c:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.rpos = 0;
f0100272:	0f 94 c1             	sete   %cl
f0100275:	0f b6 c9             	movzbl %cl,%ecx
f0100278:	83 e9 01             	sub    $0x1,%ecx
f010027b:	21 ca                	and    %ecx,%edx
f010027d:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
		return c;
	}
	return 0;
}
f0100283:	c9                   	leave  
f0100284:	c3                   	ret    

f0100285 <getchar>:
	cons_putc(c);
}

int
getchar(void)
{
f0100285:	55                   	push   %ebp
f0100286:	89 e5                	mov    %esp,%ebp
f0100288:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010028b:	e8 af ff ff ff       	call   f010023f <cons_getc>
f0100290:	85 c0                	test   %eax,%eax
f0100292:	74 f7                	je     f010028b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100294:	c9                   	leave  
f0100295:	c3                   	ret    

f0100296 <iscons>:

int
iscons(int fdnum)
{
f0100296:	55                   	push   %ebp
f0100297:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100299:	b8 01 00 00 00       	mov    $0x1,%eax
f010029e:	5d                   	pop    %ebp
f010029f:	c3                   	ret    

f01002a0 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002a0:	55                   	push   %ebp
f01002a1:	89 e5                	mov    %esp,%ebp
f01002a3:	57                   	push   %edi
f01002a4:	56                   	push   %esi
f01002a5:	53                   	push   %ebx
f01002a6:	83 ec 2c             	sub    $0x2c,%esp
f01002a9:	89 c7                	mov    %eax,%edi
f01002ab:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01002b0:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01002b1:	a8 20                	test   $0x20,%al
f01002b3:	75 21                	jne    f01002d6 <cons_putc+0x36>
f01002b5:	bb 00 00 00 00       	mov    $0x0,%ebx
f01002ba:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01002bf:	e8 dc fe ff ff       	call   f01001a0 <delay>
f01002c4:	89 f2                	mov    %esi,%edx
f01002c6:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01002c7:	a8 20                	test   $0x20,%al
f01002c9:	75 0b                	jne    f01002d6 <cons_putc+0x36>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002cb:	83 c3 01             	add    $0x1,%ebx
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01002ce:	81 fb 00 32 00 00    	cmp    $0x3200,%ebx
f01002d4:	75 e9                	jne    f01002bf <cons_putc+0x1f>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f01002d6:	89 fa                	mov    %edi,%edx
f01002d8:	89 f8                	mov    %edi,%eax
f01002da:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002dd:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002e2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e3:	b2 79                	mov    $0x79,%dl
f01002e5:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002e6:	84 c0                	test   %al,%al
f01002e8:	78 21                	js     f010030b <cons_putc+0x6b>
f01002ea:	bb 00 00 00 00       	mov    $0x0,%ebx
f01002ef:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f01002f4:	e8 a7 fe ff ff       	call   f01001a0 <delay>
f01002f9:	89 f2                	mov    %esi,%edx
f01002fb:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002fc:	84 c0                	test   %al,%al
f01002fe:	78 0b                	js     f010030b <cons_putc+0x6b>
f0100300:	83 c3 01             	add    $0x1,%ebx
f0100303:	81 fb 00 32 00 00    	cmp    $0x3200,%ebx
f0100309:	75 e9                	jne    f01002f4 <cons_putc+0x54>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010030b:	ba 78 03 00 00       	mov    $0x378,%edx
f0100310:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100314:	ee                   	out    %al,(%dx)
f0100315:	b2 7a                	mov    $0x7a,%dl
f0100317:	b8 0d 00 00 00       	mov    $0xd,%eax
f010031c:	ee                   	out    %al,(%dx)
f010031d:	b8 08 00 00 00       	mov    $0x8,%eax
f0100322:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100323:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f0100329:	75 06                	jne    f0100331 <cons_putc+0x91>
		c |= 0x0700;
f010032b:	81 cf 00 07 00 00    	or     $0x700,%edi

	switch (c & 0xff) {
f0100331:	89 f8                	mov    %edi,%eax
f0100333:	25 ff 00 00 00       	and    $0xff,%eax
f0100338:	83 f8 09             	cmp    $0x9,%eax
f010033b:	0f 84 83 00 00 00    	je     f01003c4 <cons_putc+0x124>
f0100341:	83 f8 09             	cmp    $0x9,%eax
f0100344:	7f 0c                	jg     f0100352 <cons_putc+0xb2>
f0100346:	83 f8 08             	cmp    $0x8,%eax
f0100349:	0f 85 a9 00 00 00    	jne    f01003f8 <cons_putc+0x158>
f010034f:	90                   	nop
f0100350:	eb 18                	jmp    f010036a <cons_putc+0xca>
f0100352:	83 f8 0a             	cmp    $0xa,%eax
f0100355:	8d 76 00             	lea    0x0(%esi),%esi
f0100358:	74 40                	je     f010039a <cons_putc+0xfa>
f010035a:	83 f8 0d             	cmp    $0xd,%eax
f010035d:	8d 76 00             	lea    0x0(%esi),%esi
f0100360:	0f 85 92 00 00 00    	jne    f01003f8 <cons_putc+0x158>
f0100366:	66 90                	xchg   %ax,%ax
f0100368:	eb 38                	jmp    f01003a2 <cons_putc+0x102>
	case '\b':
		if (crt_pos > 0) {
f010036a:	0f b7 05 30 23 11 f0 	movzwl 0xf0112330,%eax
f0100371:	66 85 c0             	test   %ax,%ax
f0100374:	0f 84 e8 00 00 00    	je     f0100462 <cons_putc+0x1c2>
			crt_pos--;
f010037a:	83 e8 01             	sub    $0x1,%eax
f010037d:	66 a3 30 23 11 f0    	mov    %ax,0xf0112330
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100383:	0f b7 c0             	movzwl %ax,%eax
f0100386:	66 81 e7 00 ff       	and    $0xff00,%di
f010038b:	83 cf 20             	or     $0x20,%edi
f010038e:	8b 15 2c 23 11 f0    	mov    0xf011232c,%edx
f0100394:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100398:	eb 7b                	jmp    f0100415 <cons_putc+0x175>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010039a:	66 83 05 30 23 11 f0 	addw   $0x50,0xf0112330
f01003a1:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003a2:	0f b7 05 30 23 11 f0 	movzwl 0xf0112330,%eax
f01003a9:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003af:	c1 e8 10             	shr    $0x10,%eax
f01003b2:	66 c1 e8 06          	shr    $0x6,%ax
f01003b6:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b9:	c1 e0 04             	shl    $0x4,%eax
f01003bc:	66 a3 30 23 11 f0    	mov    %ax,0xf0112330
f01003c2:	eb 51                	jmp    f0100415 <cons_putc+0x175>
		break;
	case '\t':
		cons_putc(' ');
f01003c4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c9:	e8 d2 fe ff ff       	call   f01002a0 <cons_putc>
		cons_putc(' ');
f01003ce:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d3:	e8 c8 fe ff ff       	call   f01002a0 <cons_putc>
		cons_putc(' ');
f01003d8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003dd:	e8 be fe ff ff       	call   f01002a0 <cons_putc>
		cons_putc(' ');
f01003e2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e7:	e8 b4 fe ff ff       	call   f01002a0 <cons_putc>
		cons_putc(' ');
f01003ec:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f1:	e8 aa fe ff ff       	call   f01002a0 <cons_putc>
f01003f6:	eb 1d                	jmp    f0100415 <cons_putc+0x175>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003f8:	0f b7 05 30 23 11 f0 	movzwl 0xf0112330,%eax
f01003ff:	0f b7 c8             	movzwl %ax,%ecx
f0100402:	8b 15 2c 23 11 f0    	mov    0xf011232c,%edx
f0100408:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f010040c:	83 c0 01             	add    $0x1,%eax
f010040f:	66 a3 30 23 11 f0    	mov    %ax,0xf0112330
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100415:	66 81 3d 30 23 11 f0 	cmpw   $0x7cf,0xf0112330
f010041c:	cf 07 
f010041e:	76 42                	jbe    f0100462 <cons_putc+0x1c2>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100420:	a1 2c 23 11 f0       	mov    0xf011232c,%eax
f0100425:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010042c:	00 
f010042d:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100433:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100437:	89 04 24             	mov    %eax,(%esp)
f010043a:	e8 16 11 00 00       	call   f0101555 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010043f:	8b 15 2c 23 11 f0    	mov    0xf011232c,%edx
f0100445:	b8 80 07 00 00       	mov    $0x780,%eax
f010044a:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100450:	83 c0 01             	add    $0x1,%eax
f0100453:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100458:	75 f0                	jne    f010044a <cons_putc+0x1aa>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010045a:	66 83 2d 30 23 11 f0 	subw   $0x50,0xf0112330
f0100461:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100462:	8b 0d 28 23 11 f0    	mov    0xf0112328,%ecx
f0100468:	89 cb                	mov    %ecx,%ebx
f010046a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046f:	89 ca                	mov    %ecx,%edx
f0100471:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100472:	0f b7 35 30 23 11 f0 	movzwl 0xf0112330,%esi
f0100479:	83 c1 01             	add    $0x1,%ecx
f010047c:	89 f0                	mov    %esi,%eax
f010047e:	66 c1 e8 08          	shr    $0x8,%ax
f0100482:	89 ca                	mov    %ecx,%edx
f0100484:	ee                   	out    %al,(%dx)
f0100485:	b8 0f 00 00 00       	mov    $0xf,%eax
f010048a:	89 da                	mov    %ebx,%edx
f010048c:	ee                   	out    %al,(%dx)
f010048d:	89 f0                	mov    %esi,%eax
f010048f:	89 ca                	mov    %ecx,%edx
f0100491:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100492:	83 c4 2c             	add    $0x2c,%esp
f0100495:	5b                   	pop    %ebx
f0100496:	5e                   	pop    %esi
f0100497:	5f                   	pop    %edi
f0100498:	5d                   	pop    %ebp
f0100499:	c3                   	ret    

f010049a <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010049a:	55                   	push   %ebp
f010049b:	89 e5                	mov    %esp,%ebp
f010049d:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01004a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01004a3:	e8 f8 fd ff ff       	call   f01002a0 <cons_putc>
}
f01004a8:	c9                   	leave  
f01004a9:	c3                   	ret    

f01004aa <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004aa:	55                   	push   %ebp
f01004ab:	89 e5                	mov    %esp,%ebp
f01004ad:	57                   	push   %edi
f01004ae:	56                   	push   %esi
f01004af:	53                   	push   %ebx
f01004b0:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004b3:	b8 00 80 0b f0       	mov    $0xf00b8000,%eax
f01004b8:	0f b7 10             	movzwl (%eax),%edx
	*cp = (uint16_t) 0xA55A;
f01004bb:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
f01004c0:	0f b7 00             	movzwl (%eax),%eax
f01004c3:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01004c7:	74 11                	je     f01004da <cons_init+0x30>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01004c9:	c7 05 28 23 11 f0 b4 	movl   $0x3b4,0xf0112328
f01004d0:	03 00 00 
f01004d3:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f01004d8:	eb 16                	jmp    f01004f0 <cons_init+0x46>
	} else {
		*cp = was;
f01004da:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01004e1:	c7 05 28 23 11 f0 d4 	movl   $0x3d4,0xf0112328
f01004e8:	03 00 00 
f01004eb:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01004f0:	8b 0d 28 23 11 f0    	mov    0xf0112328,%ecx
f01004f6:	89 cb                	mov    %ecx,%ebx
f01004f8:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004fd:	89 ca                	mov    %ecx,%edx
f01004ff:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100500:	83 c1 01             	add    $0x1,%ecx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100503:	89 ca                	mov    %ecx,%edx
f0100505:	ec                   	in     (%dx),%al
f0100506:	0f b6 f8             	movzbl %al,%edi
f0100509:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010050c:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100511:	89 da                	mov    %ebx,%edx
f0100513:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100514:	89 ca                	mov    %ecx,%edx
f0100516:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100517:	89 35 2c 23 11 f0    	mov    %esi,0xf011232c
	crt_pos = pos;
f010051d:	0f b6 c8             	movzbl %al,%ecx
f0100520:	09 cf                	or     %ecx,%edi
f0100522:	66 89 3d 30 23 11 f0 	mov    %di,0xf0112330
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100529:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f010052e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100533:	89 da                	mov    %ebx,%edx
f0100535:	ee                   	out    %al,(%dx)
f0100536:	b2 fb                	mov    $0xfb,%dl
f0100538:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010053d:	ee                   	out    %al,(%dx)
f010053e:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f0100543:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100548:	89 ca                	mov    %ecx,%edx
f010054a:	ee                   	out    %al,(%dx)
f010054b:	b2 f9                	mov    $0xf9,%dl
f010054d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100552:	ee                   	out    %al,(%dx)
f0100553:	b2 fb                	mov    $0xfb,%dl
f0100555:	b8 03 00 00 00       	mov    $0x3,%eax
f010055a:	ee                   	out    %al,(%dx)
f010055b:	b2 fc                	mov    $0xfc,%dl
f010055d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100562:	ee                   	out    %al,(%dx)
f0100563:	b2 f9                	mov    $0xf9,%dl
f0100565:	b8 01 00 00 00       	mov    $0x1,%eax
f010056a:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056b:	b2 fd                	mov    $0xfd,%dl
f010056d:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010056e:	3c ff                	cmp    $0xff,%al
f0100570:	0f 95 c0             	setne  %al
f0100573:	0f b6 f0             	movzbl %al,%esi
f0100576:	89 35 24 23 11 f0    	mov    %esi,0xf0112324
f010057c:	89 da                	mov    %ebx,%edx
f010057e:	ec                   	in     (%dx),%al
f010057f:	89 ca                	mov    %ecx,%edx
f0100581:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100582:	85 f6                	test   %esi,%esi
f0100584:	75 0c                	jne    f0100592 <cons_init+0xe8>
		cprintf("Serial port does not exist!\n");
f0100586:	c7 04 24 64 1a 10 f0 	movl   $0xf0101a64,(%esp)
f010058d:	e8 99 03 00 00       	call   f010092b <cprintf>
}
f0100592:	83 c4 1c             	add    $0x1c,%esp
f0100595:	5b                   	pop    %ebx
f0100596:	5e                   	pop    %esi
f0100597:	5f                   	pop    %edi
f0100598:	5d                   	pop    %ebp
f0100599:	c3                   	ret    

f010059a <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010059a:	55                   	push   %ebp
f010059b:	89 e5                	mov    %esp,%ebp
f010059d:	53                   	push   %ebx
f010059e:	83 ec 14             	sub    $0x14,%esp
f01005a1:	ba 64 00 00 00       	mov    $0x64,%edx
f01005a6:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01005a7:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01005ac:	a8 01                	test   $0x1,%al
f01005ae:	0f 84 d9 00 00 00    	je     f010068d <kbd_proc_data+0xf3>
f01005b4:	b2 60                	mov    $0x60,%dl
f01005b6:	ec                   	in     (%dx),%al
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01005b7:	3c e0                	cmp    $0xe0,%al
f01005b9:	75 11                	jne    f01005cc <kbd_proc_data+0x32>
		// E0 escape character
		shift |= E0ESC;
f01005bb:	83 0d 20 23 11 f0 40 	orl    $0x40,0xf0112320
f01005c2:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
f01005c7:	e9 c1 00 00 00       	jmp    f010068d <kbd_proc_data+0xf3>
	} else if (data & 0x80) {
f01005cc:	84 c0                	test   %al,%al
f01005ce:	79 32                	jns    f0100602 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01005d0:	8b 15 20 23 11 f0    	mov    0xf0112320,%edx
f01005d6:	f6 c2 40             	test   $0x40,%dl
f01005d9:	75 03                	jne    f01005de <kbd_proc_data+0x44>
f01005db:	83 e0 7f             	and    $0x7f,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f01005de:	0f b6 c0             	movzbl %al,%eax
f01005e1:	0f b6 80 a0 1a 10 f0 	movzbl -0xfefe560(%eax),%eax
f01005e8:	83 c8 40             	or     $0x40,%eax
f01005eb:	0f b6 c0             	movzbl %al,%eax
f01005ee:	f7 d0                	not    %eax
f01005f0:	21 c2                	and    %eax,%edx
f01005f2:	89 15 20 23 11 f0    	mov    %edx,0xf0112320
f01005f8:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
f01005fd:	e9 8b 00 00 00       	jmp    f010068d <kbd_proc_data+0xf3>
	} else if (shift & E0ESC) {
f0100602:	8b 15 20 23 11 f0    	mov    0xf0112320,%edx
f0100608:	f6 c2 40             	test   $0x40,%dl
f010060b:	74 0c                	je     f0100619 <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010060d:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f0100610:	83 e2 bf             	and    $0xffffffbf,%edx
f0100613:	89 15 20 23 11 f0    	mov    %edx,0xf0112320
	}

	shift |= shiftcode[data];
f0100619:	0f b6 c0             	movzbl %al,%eax
	shift ^= togglecode[data];
f010061c:	0f b6 90 a0 1a 10 f0 	movzbl -0xfefe560(%eax),%edx
f0100623:	0b 15 20 23 11 f0    	or     0xf0112320,%edx
f0100629:	0f b6 88 a0 1b 10 f0 	movzbl -0xfefe460(%eax),%ecx
f0100630:	31 ca                	xor    %ecx,%edx
f0100632:	89 15 20 23 11 f0    	mov    %edx,0xf0112320

	c = charcode[shift & (CTL | SHIFT)][data];
f0100638:	89 d1                	mov    %edx,%ecx
f010063a:	83 e1 03             	and    $0x3,%ecx
f010063d:	8b 0c 8d a0 1c 10 f0 	mov    -0xfefe360(,%ecx,4),%ecx
f0100644:	0f b6 1c 01          	movzbl (%ecx,%eax,1),%ebx
	if (shift & CAPSLOCK) {
f0100648:	f6 c2 08             	test   $0x8,%dl
f010064b:	74 1a                	je     f0100667 <kbd_proc_data+0xcd>
		if ('a' <= c && c <= 'z')
f010064d:	89 d9                	mov    %ebx,%ecx
f010064f:	8d 43 9f             	lea    -0x61(%ebx),%eax
f0100652:	83 f8 19             	cmp    $0x19,%eax
f0100655:	77 05                	ja     f010065c <kbd_proc_data+0xc2>
			c += 'A' - 'a';
f0100657:	83 eb 20             	sub    $0x20,%ebx
f010065a:	eb 0b                	jmp    f0100667 <kbd_proc_data+0xcd>
		else if ('A' <= c && c <= 'Z')
f010065c:	83 e9 41             	sub    $0x41,%ecx
f010065f:	83 f9 19             	cmp    $0x19,%ecx
f0100662:	77 03                	ja     f0100667 <kbd_proc_data+0xcd>
			c += 'a' - 'A';
f0100664:	83 c3 20             	add    $0x20,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100667:	f7 d2                	not    %edx
f0100669:	f6 c2 06             	test   $0x6,%dl
f010066c:	75 1f                	jne    f010068d <kbd_proc_data+0xf3>
f010066e:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100674:	75 17                	jne    f010068d <kbd_proc_data+0xf3>
		cprintf("Rebooting!\n");
f0100676:	c7 04 24 81 1a 10 f0 	movl   $0xf0101a81,(%esp)
f010067d:	e8 a9 02 00 00       	call   f010092b <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100682:	ba 92 00 00 00       	mov    $0x92,%edx
f0100687:	b8 03 00 00 00       	mov    $0x3,%eax
f010068c:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010068d:	89 d8                	mov    %ebx,%eax
f010068f:	83 c4 14             	add    $0x14,%esp
f0100692:	5b                   	pop    %ebx
f0100693:	5d                   	pop    %ebp
f0100694:	c3                   	ret    
	...

f01006a0 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01006a0:	55                   	push   %ebp
f01006a1:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f01006a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01006a8:	5d                   	pop    %ebp
f01006a9:	c3                   	ret    

f01006aa <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f01006aa:	55                   	push   %ebp
f01006ab:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01006ad:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01006b0:	5d                   	pop    %ebp
f01006b1:	c3                   	ret    

f01006b2 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006b2:	55                   	push   %ebp
f01006b3:	89 e5                	mov    %esp,%ebp
f01006b5:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006b8:	c7 04 24 b0 1c 10 f0 	movl   $0xf0101cb0,(%esp)
f01006bf:	e8 67 02 00 00       	call   f010092b <cprintf>
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
f01006c4:	c7 44 24 08 0c 00 10 	movl   $0x1010000c,0x8(%esp)
f01006cb:	10 
f01006cc:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006d3:	00 
f01006d4:	c7 04 24 3c 1d 10 f0 	movl   $0xf0101d3c,(%esp)
f01006db:	e8 4b 02 00 00       	call   f010092b <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006e0:	c7 44 24 08 c5 19 10 	movl   $0x1019c5,0x8(%esp)
f01006e7:	00 
f01006e8:	c7 44 24 04 c5 19 10 	movl   $0xf01019c5,0x4(%esp)
f01006ef:	f0 
f01006f0:	c7 04 24 60 1d 10 f0 	movl   $0xf0101d60,(%esp)
f01006f7:	e8 2f 02 00 00       	call   f010092b <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006fc:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100703:	00 
f0100704:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010070b:	f0 
f010070c:	c7 04 24 84 1d 10 f0 	movl   $0xf0101d84,(%esp)
f0100713:	e8 13 02 00 00       	call   f010092b <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100718:	c7 44 24 08 60 29 11 	movl   $0x112960,0x8(%esp)
f010071f:	00 
f0100720:	c7 44 24 04 60 29 11 	movl   $0xf0112960,0x4(%esp)
f0100727:	f0 
f0100728:	c7 04 24 a8 1d 10 f0 	movl   $0xf0101da8,(%esp)
f010072f:	e8 f7 01 00 00       	call   f010092b <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100734:	b8 5f 2d 11 f0       	mov    $0xf0112d5f,%eax
f0100739:	2d 0c 00 10 00       	sub    $0x10000c,%eax
f010073e:	89 c2                	mov    %eax,%edx
f0100740:	c1 fa 1f             	sar    $0x1f,%edx
f0100743:	c1 ea 16             	shr    $0x16,%edx
f0100746:	8d 04 02             	lea    (%edx,%eax,1),%eax
f0100749:	c1 f8 0a             	sar    $0xa,%eax
f010074c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100750:	c7 04 24 cc 1d 10 f0 	movl   $0xf0101dcc,(%esp)
f0100757:	e8 cf 01 00 00       	call   f010092b <cprintf>
		(end-_start+1023)/1024);
	return 0;
}
f010075c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100761:	c9                   	leave  
f0100762:	c3                   	ret    

f0100763 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100763:	55                   	push   %ebp
f0100764:	89 e5                	mov    %esp,%ebp
f0100766:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100769:	a1 70 1e 10 f0       	mov    0xf0101e70,%eax
f010076e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100772:	a1 6c 1e 10 f0       	mov    0xf0101e6c,%eax
f0100777:	89 44 24 04          	mov    %eax,0x4(%esp)
f010077b:	c7 04 24 c9 1c 10 f0 	movl   $0xf0101cc9,(%esp)
f0100782:	e8 a4 01 00 00       	call   f010092b <cprintf>
f0100787:	a1 7c 1e 10 f0       	mov    0xf0101e7c,%eax
f010078c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100790:	a1 78 1e 10 f0       	mov    0xf0101e78,%eax
f0100795:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100799:	c7 04 24 c9 1c 10 f0 	movl   $0xf0101cc9,(%esp)
f01007a0:	e8 86 01 00 00       	call   f010092b <cprintf>
	return 0;
}
f01007a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01007aa:	c9                   	leave  
f01007ab:	c3                   	ret    

f01007ac <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007ac:	55                   	push   %ebp
f01007ad:	89 e5                	mov    %esp,%ebp
f01007af:	57                   	push   %edi
f01007b0:	56                   	push   %esi
f01007b1:	53                   	push   %ebx
f01007b2:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007b5:	c7 04 24 f8 1d 10 f0 	movl   $0xf0101df8,(%esp)
f01007bc:	e8 6a 01 00 00       	call   f010092b <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007c1:	c7 04 24 1c 1e 10 f0 	movl   $0xf0101e1c,(%esp)
f01007c8:	e8 5e 01 00 00       	call   f010092b <cprintf>

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01007cd:	bf 6c 1e 10 f0       	mov    $0xf0101e6c,%edi
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f01007d2:	c7 04 24 d2 1c 10 f0 	movl   $0xf0101cd2,(%esp)
f01007d9:	e8 92 0a 00 00       	call   f0101270 <readline>
f01007de:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007e0:	85 c0                	test   %eax,%eax
f01007e2:	74 ee                	je     f01007d2 <monitor+0x26>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007e4:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
f01007eb:	be 00 00 00 00       	mov    $0x0,%esi
f01007f0:	eb 06                	jmp    f01007f8 <monitor+0x4c>
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007f2:	c6 03 00             	movb   $0x0,(%ebx)
f01007f5:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007f8:	0f b6 03             	movzbl (%ebx),%eax
f01007fb:	84 c0                	test   %al,%al
f01007fd:	74 6c                	je     f010086b <monitor+0xbf>
f01007ff:	0f be c0             	movsbl %al,%eax
f0100802:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100806:	c7 04 24 d6 1c 10 f0 	movl   $0xf0101cd6,(%esp)
f010080d:	e8 8c 0c 00 00       	call   f010149e <strchr>
f0100812:	85 c0                	test   %eax,%eax
f0100814:	75 dc                	jne    f01007f2 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100816:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100819:	74 50                	je     f010086b <monitor+0xbf>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010081b:	83 fe 0f             	cmp    $0xf,%esi
f010081e:	66 90                	xchg   %ax,%ax
f0100820:	75 16                	jne    f0100838 <monitor+0x8c>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100822:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100829:	00 
f010082a:	c7 04 24 db 1c 10 f0 	movl   $0xf0101cdb,(%esp)
f0100831:	e8 f5 00 00 00       	call   f010092b <cprintf>
f0100836:	eb 9a                	jmp    f01007d2 <monitor+0x26>
			return 0;
		}
		argv[argc++] = buf;
f0100838:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010083c:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f010083f:	0f b6 03             	movzbl (%ebx),%eax
f0100842:	84 c0                	test   %al,%al
f0100844:	75 0c                	jne    f0100852 <monitor+0xa6>
f0100846:	eb b0                	jmp    f01007f8 <monitor+0x4c>
			buf++;
f0100848:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010084b:	0f b6 03             	movzbl (%ebx),%eax
f010084e:	84 c0                	test   %al,%al
f0100850:	74 a6                	je     f01007f8 <monitor+0x4c>
f0100852:	0f be c0             	movsbl %al,%eax
f0100855:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100859:	c7 04 24 d6 1c 10 f0 	movl   $0xf0101cd6,(%esp)
f0100860:	e8 39 0c 00 00       	call   f010149e <strchr>
f0100865:	85 c0                	test   %eax,%eax
f0100867:	74 df                	je     f0100848 <monitor+0x9c>
f0100869:	eb 8d                	jmp    f01007f8 <monitor+0x4c>
			buf++;
	}
	argv[argc] = 0;
f010086b:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100872:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100873:	85 f6                	test   %esi,%esi
f0100875:	0f 84 57 ff ff ff    	je     f01007d2 <monitor+0x26>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010087b:	8b 07                	mov    (%edi),%eax
f010087d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100881:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100884:	89 04 24             	mov    %eax,(%esp)
f0100887:	e8 9d 0b 00 00       	call   f0101429 <strcmp>
f010088c:	ba 00 00 00 00       	mov    $0x0,%edx
f0100891:	85 c0                	test   %eax,%eax
f0100893:	74 1d                	je     f01008b2 <monitor+0x106>
f0100895:	a1 78 1e 10 f0       	mov    0xf0101e78,%eax
f010089a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010089e:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008a1:	89 04 24             	mov    %eax,(%esp)
f01008a4:	e8 80 0b 00 00       	call   f0101429 <strcmp>
f01008a9:	85 c0                	test   %eax,%eax
f01008ab:	75 28                	jne    f01008d5 <monitor+0x129>
f01008ad:	ba 01 00 00 00       	mov    $0x1,%edx
			return commands[i].func(argc, argv, tf);
f01008b2:	6b d2 0c             	imul   $0xc,%edx,%edx
f01008b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01008b8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008bc:	8d 45 a8             	lea    -0x58(%ebp),%eax
f01008bf:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008c3:	89 34 24             	mov    %esi,(%esp)
f01008c6:	ff 92 74 1e 10 f0    	call   *-0xfefe18c(%edx)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008cc:	85 c0                	test   %eax,%eax
f01008ce:	78 1d                	js     f01008ed <monitor+0x141>
f01008d0:	e9 fd fe ff ff       	jmp    f01007d2 <monitor+0x26>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008d5:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008d8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008dc:	c7 04 24 f8 1c 10 f0 	movl   $0xf0101cf8,(%esp)
f01008e3:	e8 43 00 00 00       	call   f010092b <cprintf>
f01008e8:	e9 e5 fe ff ff       	jmp    f01007d2 <monitor+0x26>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008ed:	83 c4 5c             	add    $0x5c,%esp
f01008f0:	5b                   	pop    %ebx
f01008f1:	5e                   	pop    %esi
f01008f2:	5f                   	pop    %edi
f01008f3:	5d                   	pop    %ebp
f01008f4:	c3                   	ret    
f01008f5:	00 00                	add    %al,(%eax)
	...

f01008f8 <vcprintf>:
	*cnt++;
}

int
vcprintf(const char *fmt, va_list ap)
{
f01008f8:	55                   	push   %ebp
f01008f9:	89 e5                	mov    %esp,%ebp
f01008fb:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01008fe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100905:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100908:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010090c:	8b 45 08             	mov    0x8(%ebp),%eax
f010090f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100913:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100916:	89 44 24 04          	mov    %eax,0x4(%esp)
f010091a:	c7 04 24 45 09 10 f0 	movl   $0xf0100945,(%esp)
f0100921:	e8 87 04 00 00       	call   f0100dad <vprintfmt>
	return cnt;
}
f0100926:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100929:	c9                   	leave  
f010092a:	c3                   	ret    

f010092b <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010092b:	55                   	push   %ebp
f010092c:	89 e5                	mov    %esp,%ebp
f010092e:	83 ec 18             	sub    $0x18,%esp
	vprintfmt((void*)putch, &cnt, fmt, ap);
	return cnt;
}

int
cprintf(const char *fmt, ...)
f0100931:	8d 45 0c             	lea    0xc(%ebp),%eax
{
	va_list ap;
	int cnt;

	va_start(ap, fmt);
	cnt = vcprintf(fmt, ap);
f0100934:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100938:	8b 45 08             	mov    0x8(%ebp),%eax
f010093b:	89 04 24             	mov    %eax,(%esp)
f010093e:	e8 b5 ff ff ff       	call   f01008f8 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100943:	c9                   	leave  
f0100944:	c3                   	ret    

f0100945 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100945:	55                   	push   %ebp
f0100946:	89 e5                	mov    %esp,%ebp
f0100948:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010094b:	8b 45 08             	mov    0x8(%ebp),%eax
f010094e:	89 04 24             	mov    %eax,(%esp)
f0100951:	e8 44 fb ff ff       	call   f010049a <cputchar>
	*cnt++;
}
f0100956:	c9                   	leave  
f0100957:	c3                   	ret    
	...

f0100960 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100960:	55                   	push   %ebp
f0100961:	89 e5                	mov    %esp,%ebp
f0100963:	57                   	push   %edi
f0100964:	56                   	push   %esi
f0100965:	53                   	push   %ebx
f0100966:	83 ec 14             	sub    $0x14,%esp
f0100969:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010096c:	89 55 e8             	mov    %edx,-0x18(%ebp)
f010096f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100972:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100975:	8b 1a                	mov    (%edx),%ebx
f0100977:	8b 01                	mov    (%ecx),%eax
f0100979:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	while (l <= r) {
f010097c:	39 c3                	cmp    %eax,%ebx
f010097e:	0f 8f 9c 00 00 00    	jg     f0100a20 <stab_binsearch+0xc0>
f0100984:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		int true_m = (l + r) / 2, m = true_m;
f010098b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010098e:	01 d8                	add    %ebx,%eax
f0100990:	89 c7                	mov    %eax,%edi
f0100992:	c1 ef 1f             	shr    $0x1f,%edi
f0100995:	01 c7                	add    %eax,%edi
f0100997:	d1 ff                	sar    %edi
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100999:	39 df                	cmp    %ebx,%edi
f010099b:	7c 33                	jl     f01009d0 <stab_binsearch+0x70>
f010099d:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01009a0:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01009a3:	0f b6 44 82 04       	movzbl 0x4(%edx,%eax,4),%eax
f01009a8:	39 f0                	cmp    %esi,%eax
f01009aa:	0f 84 bc 00 00 00    	je     f0100a6c <stab_binsearch+0x10c>
f01009b0:	8d 44 7f fd          	lea    -0x3(%edi,%edi,2),%eax
f01009b4:	8d 54 82 04          	lea    0x4(%edx,%eax,4),%edx
f01009b8:	89 f8                	mov    %edi,%eax
			m--;
f01009ba:	83 e8 01             	sub    $0x1,%eax
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009bd:	39 d8                	cmp    %ebx,%eax
f01009bf:	7c 0f                	jl     f01009d0 <stab_binsearch+0x70>
f01009c1:	0f b6 0a             	movzbl (%edx),%ecx
f01009c4:	83 ea 0c             	sub    $0xc,%edx
f01009c7:	39 f1                	cmp    %esi,%ecx
f01009c9:	75 ef                	jne    f01009ba <stab_binsearch+0x5a>
f01009cb:	e9 9e 00 00 00       	jmp    f0100a6e <stab_binsearch+0x10e>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009d0:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f01009d3:	eb 3c                	jmp    f0100a11 <stab_binsearch+0xb1>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01009d5:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f01009d8:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
f01009da:	8d 5f 01             	lea    0x1(%edi),%ebx
f01009dd:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f01009e4:	eb 2b                	jmp    f0100a11 <stab_binsearch+0xb1>
		} else if (stabs[m].n_value > addr) {
f01009e6:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01009e9:	76 14                	jbe    f01009ff <stab_binsearch+0x9f>
			*region_right = m - 1;
f01009eb:	83 e8 01             	sub    $0x1,%eax
f01009ee:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01009f1:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01009f4:	89 02                	mov    %eax,(%edx)
f01009f6:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f01009fd:	eb 12                	jmp    f0100a11 <stab_binsearch+0xb1>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01009ff:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100a02:	89 01                	mov    %eax,(%ecx)
			l = m;
			addr++;
f0100a04:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a08:	89 c3                	mov    %eax,%ebx
f0100a0a:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100a11:	39 5d ec             	cmp    %ebx,-0x14(%ebp)
f0100a14:	0f 8d 71 ff ff ff    	jge    f010098b <stab_binsearch+0x2b>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a1a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100a1e:	75 0f                	jne    f0100a2f <stab_binsearch+0xcf>
		*region_right = *region_left - 1;
f0100a20:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a23:	8b 03                	mov    (%ebx),%eax
f0100a25:	83 e8 01             	sub    $0x1,%eax
f0100a28:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100a2b:	89 02                	mov    %eax,(%edx)
f0100a2d:	eb 57                	jmp    f0100a86 <stab_binsearch+0x126>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a2f:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100a32:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a34:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a37:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a39:	39 c1                	cmp    %eax,%ecx
f0100a3b:	7d 28                	jge    f0100a65 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0100a3d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a40:	8b 5d f0             	mov    -0x10(%ebp),%ebx
f0100a43:	0f b6 54 93 04       	movzbl 0x4(%ebx,%edx,4),%edx
f0100a48:	39 f2                	cmp    %esi,%edx
f0100a4a:	74 19                	je     f0100a65 <stab_binsearch+0x105>
f0100a4c:	8d 54 40 fd          	lea    -0x3(%eax,%eax,2),%edx
f0100a50:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx
		     l--)
f0100a54:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a57:	39 c1                	cmp    %eax,%ecx
f0100a59:	7d 0a                	jge    f0100a65 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0100a5b:	0f b6 1a             	movzbl (%edx),%ebx
f0100a5e:	83 ea 0c             	sub    $0xc,%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a61:	39 f3                	cmp    %esi,%ebx
f0100a63:	75 ef                	jne    f0100a54 <stab_binsearch+0xf4>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a65:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a68:	89 02                	mov    %eax,(%edx)
f0100a6a:	eb 1a                	jmp    f0100a86 <stab_binsearch+0x126>
	}
}
f0100a6c:	89 f8                	mov    %edi,%eax
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a6e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a71:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0100a74:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a78:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a7b:	0f 82 54 ff ff ff    	jb     f01009d5 <stab_binsearch+0x75>
f0100a81:	e9 60 ff ff ff       	jmp    f01009e6 <stab_binsearch+0x86>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0100a86:	83 c4 14             	add    $0x14,%esp
f0100a89:	5b                   	pop    %ebx
f0100a8a:	5e                   	pop    %esi
f0100a8b:	5f                   	pop    %edi
f0100a8c:	5d                   	pop    %ebp
f0100a8d:	c3                   	ret    

f0100a8e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a8e:	55                   	push   %ebp
f0100a8f:	89 e5                	mov    %esp,%ebp
f0100a91:	83 ec 28             	sub    $0x28,%esp
f0100a94:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100a97:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100a9a:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a9d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100aa0:	c7 03 84 1e 10 f0    	movl   $0xf0101e84,(%ebx)
	info->eip_line = 0;
f0100aa6:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100aad:	c7 43 08 84 1e 10 f0 	movl   $0xf0101e84,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100ab4:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100abb:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100abe:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ac5:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100acb:	76 12                	jbe    f0100adf <debuginfo_eip+0x51>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100acd:	b8 80 75 10 f0       	mov    $0xf0107580,%eax
f0100ad2:	3d 79 5b 10 f0       	cmp    $0xf0105b79,%eax
f0100ad7:	0f 86 53 01 00 00    	jbe    f0100c30 <debuginfo_eip+0x1a2>
f0100add:	eb 1c                	jmp    f0100afb <debuginfo_eip+0x6d>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100adf:	c7 44 24 08 8e 1e 10 	movl   $0xf0101e8e,0x8(%esp)
f0100ae6:	f0 
f0100ae7:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100aee:	00 
f0100aef:	c7 04 24 9b 1e 10 f0 	movl   $0xf0101e9b,(%esp)
f0100af6:	e8 8a f5 ff ff       	call   f0100085 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100afb:	80 3d 7f 75 10 f0 00 	cmpb   $0x0,0xf010757f
f0100b02:	0f 85 28 01 00 00    	jne    f0100c30 <debuginfo_eip+0x1a2>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b08:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b0f:	b8 78 5b 10 f0       	mov    $0xf0105b78,%eax
f0100b14:	2d bc 20 10 f0       	sub    $0xf01020bc,%eax
f0100b19:	c1 f8 02             	sar    $0x2,%eax
f0100b1c:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b22:	83 e8 01             	sub    $0x1,%eax
f0100b25:	89 45 f0             	mov    %eax,-0x10(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b28:	8d 4d f0             	lea    -0x10(%ebp),%ecx
f0100b2b:	8d 55 f4             	lea    -0xc(%ebp),%edx
f0100b2e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b32:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b39:	b8 bc 20 10 f0       	mov    $0xf01020bc,%eax
f0100b3e:	e8 1d fe ff ff       	call   f0100960 <stab_binsearch>
	if (lfile == 0)
f0100b43:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b46:	85 c0                	test   %eax,%eax
f0100b48:	0f 84 e2 00 00 00    	je     f0100c30 <debuginfo_eip+0x1a2>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b4e:	89 45 ec             	mov    %eax,-0x14(%ebp)
	rfun = rfile;
f0100b51:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100b54:	89 45 e8             	mov    %eax,-0x18(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b57:	8d 4d e8             	lea    -0x18(%ebp),%ecx
f0100b5a:	8d 55 ec             	lea    -0x14(%ebp),%edx
f0100b5d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b61:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100b68:	b8 bc 20 10 f0       	mov    $0xf01020bc,%eax
f0100b6d:	e8 ee fd ff ff       	call   f0100960 <stab_binsearch>

	if (lfun <= rfun) {
f0100b72:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100b75:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f0100b78:	7f 31                	jg     f0100bab <debuginfo_eip+0x11d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b7a:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100b7d:	8b 80 bc 20 10 f0    	mov    -0xfefdf44(%eax),%eax
f0100b83:	ba 80 75 10 f0       	mov    $0xf0107580,%edx
f0100b88:	81 ea 79 5b 10 f0    	sub    $0xf0105b79,%edx
f0100b8e:	39 d0                	cmp    %edx,%eax
f0100b90:	73 08                	jae    f0100b9a <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b92:	05 79 5b 10 f0       	add    $0xf0105b79,%eax
f0100b97:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b9a:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100b9d:	6b c6 0c             	imul   $0xc,%esi,%eax
f0100ba0:	8b 80 c4 20 10 f0    	mov    -0xfefdf3c(%eax),%eax
f0100ba6:	89 43 10             	mov    %eax,0x10(%ebx)
f0100ba9:	eb 06                	jmp    f0100bb1 <debuginfo_eip+0x123>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bab:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bae:	8b 75 f4             	mov    -0xc(%ebp),%esi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bb1:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100bb8:	00 
f0100bb9:	8b 43 08             	mov    0x8(%ebx),%eax
f0100bbc:	89 04 24             	mov    %eax,(%esp)
f0100bbf:	e8 07 09 00 00       	call   f01014cb <strfind>
f0100bc4:	2b 43 08             	sub    0x8(%ebx),%eax
f0100bc7:	89 43 0c             	mov    %eax,0xc(%ebx)
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
f0100bca:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0100bcd:	6b c6 0c             	imul   $0xc,%esi,%eax
f0100bd0:	05 c4 20 10 f0       	add    $0xf01020c4,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bd5:	eb 06                	jmp    f0100bdd <debuginfo_eip+0x14f>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100bd7:	83 ee 01             	sub    $0x1,%esi
f0100bda:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bdd:	39 ce                	cmp    %ecx,%esi
f0100bdf:	7c 20                	jl     f0100c01 <debuginfo_eip+0x173>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100be1:	0f b6 50 fc          	movzbl -0x4(%eax),%edx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100be5:	80 fa 84             	cmp    $0x84,%dl
f0100be8:	74 5c                	je     f0100c46 <debuginfo_eip+0x1b8>
f0100bea:	80 fa 64             	cmp    $0x64,%dl
f0100bed:	75 e8                	jne    f0100bd7 <debuginfo_eip+0x149>
f0100bef:	83 38 00             	cmpl   $0x0,(%eax)
f0100bf2:	74 e3                	je     f0100bd7 <debuginfo_eip+0x149>
f0100bf4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100bf8:	eb 4c                	jmp    f0100c46 <debuginfo_eip+0x1b8>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100bfa:	05 79 5b 10 f0       	add    $0xf0105b79,%eax
f0100bff:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c01:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100c04:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f0100c07:	7d 2e                	jge    f0100c37 <debuginfo_eip+0x1a9>
		for (lline = lfun + 1;
f0100c09:	83 c0 01             	add    $0x1,%eax
f0100c0c:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100c0f:	81 c2 c0 20 10 f0    	add    $0xf01020c0,%edx
f0100c15:	eb 07                	jmp    f0100c1e <debuginfo_eip+0x190>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c17:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c1b:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c1e:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f0100c21:	7d 14                	jge    f0100c37 <debuginfo_eip+0x1a9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c23:	0f b6 0a             	movzbl (%edx),%ecx
f0100c26:	83 c2 0c             	add    $0xc,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c29:	80 f9 a0             	cmp    $0xa0,%cl
f0100c2c:	74 e9                	je     f0100c17 <debuginfo_eip+0x189>
f0100c2e:	eb 07                	jmp    f0100c37 <debuginfo_eip+0x1a9>
f0100c30:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c35:	eb 05                	jmp    f0100c3c <debuginfo_eip+0x1ae>
f0100c37:	b8 00 00 00 00       	mov    $0x0,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
}
f0100c3c:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100c3f:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100c42:	89 ec                	mov    %ebp,%esp
f0100c44:	5d                   	pop    %ebp
f0100c45:	c3                   	ret    
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c46:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100c49:	8b 86 bc 20 10 f0    	mov    -0xfefdf44(%esi),%eax
f0100c4f:	ba 80 75 10 f0       	mov    $0xf0107580,%edx
f0100c54:	81 ea 79 5b 10 f0    	sub    $0xf0105b79,%edx
f0100c5a:	39 d0                	cmp    %edx,%eax
f0100c5c:	72 9c                	jb     f0100bfa <debuginfo_eip+0x16c>
f0100c5e:	eb a1                	jmp    f0100c01 <debuginfo_eip+0x173>

f0100c60 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c60:	55                   	push   %ebp
f0100c61:	89 e5                	mov    %esp,%ebp
f0100c63:	57                   	push   %edi
f0100c64:	56                   	push   %esi
f0100c65:	53                   	push   %ebx
f0100c66:	83 ec 4c             	sub    $0x4c,%esp
f0100c69:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100c6c:	89 d6                	mov    %edx,%esi
f0100c6e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c71:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c74:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100c77:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100c7a:	8b 45 10             	mov    0x10(%ebp),%eax
f0100c7d:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100c80:	8b 7d 18             	mov    0x18(%ebp),%edi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c83:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100c86:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100c8b:	39 d1                	cmp    %edx,%ecx
f0100c8d:	72 15                	jb     f0100ca4 <printnum+0x44>
f0100c8f:	77 07                	ja     f0100c98 <printnum+0x38>
f0100c91:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100c94:	39 d0                	cmp    %edx,%eax
f0100c96:	76 0c                	jbe    f0100ca4 <printnum+0x44>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100c98:	83 eb 01             	sub    $0x1,%ebx
f0100c9b:	85 db                	test   %ebx,%ebx
f0100c9d:	8d 76 00             	lea    0x0(%esi),%esi
f0100ca0:	7f 61                	jg     f0100d03 <printnum+0xa3>
f0100ca2:	eb 70                	jmp    f0100d14 <printnum+0xb4>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100ca4:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0100ca8:	83 eb 01             	sub    $0x1,%ebx
f0100cab:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100caf:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100cb3:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0100cb7:	8b 5c 24 0c          	mov    0xc(%esp),%ebx
f0100cbb:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0100cbe:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0100cc1:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100cc4:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100cc8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100ccf:	00 
f0100cd0:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100cd3:	89 04 24             	mov    %eax,(%esp)
f0100cd6:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100cd9:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100cdd:	e8 7e 0a 00 00       	call   f0101760 <__udivdi3>
f0100ce2:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100ce5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100ce8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100cec:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100cf0:	89 04 24             	mov    %eax,(%esp)
f0100cf3:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100cf7:	89 f2                	mov    %esi,%edx
f0100cf9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cfc:	e8 5f ff ff ff       	call   f0100c60 <printnum>
f0100d01:	eb 11                	jmp    f0100d14 <printnum+0xb4>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d03:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100d07:	89 3c 24             	mov    %edi,(%esp)
f0100d0a:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d0d:	83 eb 01             	sub    $0x1,%ebx
f0100d10:	85 db                	test   %ebx,%ebx
f0100d12:	7f ef                	jg     f0100d03 <printnum+0xa3>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d14:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100d18:	8b 74 24 04          	mov    0x4(%esp),%esi
f0100d1c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d1f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d23:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100d2a:	00 
f0100d2b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100d2e:	89 14 24             	mov    %edx,(%esp)
f0100d31:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100d34:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100d38:	e8 53 0b 00 00       	call   f0101890 <__umoddi3>
f0100d3d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100d41:	0f be 80 a9 1e 10 f0 	movsbl -0xfefe157(%eax),%eax
f0100d48:	89 04 24             	mov    %eax,(%esp)
f0100d4b:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100d4e:	83 c4 4c             	add    $0x4c,%esp
f0100d51:	5b                   	pop    %ebx
f0100d52:	5e                   	pop    %esi
f0100d53:	5f                   	pop    %edi
f0100d54:	5d                   	pop    %ebp
f0100d55:	c3                   	ret    

f0100d56 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d56:	55                   	push   %ebp
f0100d57:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d59:	83 fa 01             	cmp    $0x1,%edx
f0100d5c:	7e 0e                	jle    f0100d6c <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d5e:	8b 10                	mov    (%eax),%edx
f0100d60:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d63:	89 08                	mov    %ecx,(%eax)
f0100d65:	8b 02                	mov    (%edx),%eax
f0100d67:	8b 52 04             	mov    0x4(%edx),%edx
f0100d6a:	eb 22                	jmp    f0100d8e <getuint+0x38>
	else if (lflag)
f0100d6c:	85 d2                	test   %edx,%edx
f0100d6e:	74 10                	je     f0100d80 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d70:	8b 10                	mov    (%eax),%edx
f0100d72:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d75:	89 08                	mov    %ecx,(%eax)
f0100d77:	8b 02                	mov    (%edx),%eax
f0100d79:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d7e:	eb 0e                	jmp    f0100d8e <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d80:	8b 10                	mov    (%eax),%edx
f0100d82:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d85:	89 08                	mov    %ecx,(%eax)
f0100d87:	8b 02                	mov    (%edx),%eax
f0100d89:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100d8e:	5d                   	pop    %ebp
f0100d8f:	c3                   	ret    

f0100d90 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d90:	55                   	push   %ebp
f0100d91:	89 e5                	mov    %esp,%ebp
f0100d93:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d96:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d9a:	8b 10                	mov    (%eax),%edx
f0100d9c:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d9f:	73 0a                	jae    f0100dab <sprintputch+0x1b>
		*b->buf++ = ch;
f0100da1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100da4:	88 0a                	mov    %cl,(%edx)
f0100da6:	83 c2 01             	add    $0x1,%edx
f0100da9:	89 10                	mov    %edx,(%eax)
}
f0100dab:	5d                   	pop    %ebp
f0100dac:	c3                   	ret    

f0100dad <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100dad:	55                   	push   %ebp
f0100dae:	89 e5                	mov    %esp,%ebp
f0100db0:	57                   	push   %edi
f0100db1:	56                   	push   %esi
f0100db2:	53                   	push   %ebx
f0100db3:	83 ec 5c             	sub    $0x5c,%esp
f0100db6:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100db9:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100dbc:	8b 5d 10             	mov    0x10(%ebp),%ebx
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100dbf:	c7 45 c8 ff ff ff ff 	movl   $0xffffffff,-0x38(%ebp)
f0100dc6:	eb 11                	jmp    f0100dd9 <vprintfmt+0x2c>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100dc8:	85 c0                	test   %eax,%eax
f0100dca:	0f 84 ec 03 00 00    	je     f01011bc <vprintfmt+0x40f>
				return;
			putch(ch, putdat);
f0100dd0:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100dd4:	89 04 24             	mov    %eax,(%esp)
f0100dd7:	ff d7                	call   *%edi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100dd9:	0f b6 03             	movzbl (%ebx),%eax
f0100ddc:	83 c3 01             	add    $0x1,%ebx
f0100ddf:	83 f8 25             	cmp    $0x25,%eax
f0100de2:	75 e4                	jne    f0100dc8 <vprintfmt+0x1b>
f0100de4:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100de8:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100def:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100df6:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100dfd:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e02:	eb 06                	jmp    f0100e0a <vprintfmt+0x5d>
f0100e04:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0100e08:	89 c3                	mov    %eax,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e0a:	0f b6 13             	movzbl (%ebx),%edx
f0100e0d:	0f b6 c2             	movzbl %dl,%eax
f0100e10:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e13:	8d 43 01             	lea    0x1(%ebx),%eax
f0100e16:	83 ea 23             	sub    $0x23,%edx
f0100e19:	80 fa 55             	cmp    $0x55,%dl
f0100e1c:	0f 87 7d 03 00 00    	ja     f010119f <vprintfmt+0x3f2>
f0100e22:	0f b6 d2             	movzbl %dl,%edx
f0100e25:	ff 24 95 38 1f 10 f0 	jmp    *-0xfefe0c8(,%edx,4)
f0100e2c:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100e30:	eb d6                	jmp    f0100e08 <vprintfmt+0x5b>
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e32:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100e35:	83 ea 30             	sub    $0x30,%edx
f0100e38:	89 55 d0             	mov    %edx,-0x30(%ebp)
				ch = *fmt;
f0100e3b:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0100e3e:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0100e41:	83 fb 09             	cmp    $0x9,%ebx
f0100e44:	77 4c                	ja     f0100e92 <vprintfmt+0xe5>
f0100e46:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100e49:	8b 4d d0             	mov    -0x30(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e4c:	83 c0 01             	add    $0x1,%eax
				precision = precision * 10 + ch - '0';
f0100e4f:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100e52:	8d 4c 4a d0          	lea    -0x30(%edx,%ecx,2),%ecx
				ch = *fmt;
f0100e56:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0100e59:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0100e5c:	83 fb 09             	cmp    $0x9,%ebx
f0100e5f:	76 eb                	jbe    f0100e4c <vprintfmt+0x9f>
f0100e61:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0100e64:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100e67:	eb 29                	jmp    f0100e92 <vprintfmt+0xe5>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e69:	8b 55 14             	mov    0x14(%ebp),%edx
f0100e6c:	8d 5a 04             	lea    0x4(%edx),%ebx
f0100e6f:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0100e72:	8b 12                	mov    (%edx),%edx
f0100e74:	89 55 d0             	mov    %edx,-0x30(%ebp)
			goto process_precision;
f0100e77:	eb 19                	jmp    f0100e92 <vprintfmt+0xe5>

		case '.':
			if (width < 0)
f0100e79:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100e7c:	c1 fa 1f             	sar    $0x1f,%edx
f0100e7f:	f7 d2                	not    %edx
f0100e81:	21 55 e4             	and    %edx,-0x1c(%ebp)
f0100e84:	eb 82                	jmp    f0100e08 <vprintfmt+0x5b>
f0100e86:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
			goto reswitch;
f0100e8d:	e9 76 ff ff ff       	jmp    f0100e08 <vprintfmt+0x5b>

		process_precision:
			if (width < 0)
f0100e92:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100e96:	0f 89 6c ff ff ff    	jns    f0100e08 <vprintfmt+0x5b>
f0100e9c:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100e9f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100ea2:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0100ea5:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100ea8:	e9 5b ff ff ff       	jmp    f0100e08 <vprintfmt+0x5b>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100ead:	83 c1 01             	add    $0x1,%ecx
			goto reswitch;
f0100eb0:	e9 53 ff ff ff       	jmp    f0100e08 <vprintfmt+0x5b>
f0100eb5:	89 45 cc             	mov    %eax,-0x34(%ebp)

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100eb8:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ebb:	8d 50 04             	lea    0x4(%eax),%edx
f0100ebe:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ec1:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ec5:	8b 00                	mov    (%eax),%eax
f0100ec7:	89 04 24             	mov    %eax,(%esp)
f0100eca:	ff d7                	call   *%edi
f0100ecc:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			break;
f0100ecf:	e9 05 ff ff ff       	jmp    f0100dd9 <vprintfmt+0x2c>
f0100ed4:	89 45 cc             	mov    %eax,-0x34(%ebp)

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100ed7:	8b 45 14             	mov    0x14(%ebp),%eax
f0100eda:	8d 50 04             	lea    0x4(%eax),%edx
f0100edd:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ee0:	8b 00                	mov    (%eax),%eax
f0100ee2:	89 c2                	mov    %eax,%edx
f0100ee4:	c1 fa 1f             	sar    $0x1f,%edx
f0100ee7:	31 d0                	xor    %edx,%eax
f0100ee9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100eeb:	83 f8 06             	cmp    $0x6,%eax
f0100eee:	7f 0b                	jg     f0100efb <vprintfmt+0x14e>
f0100ef0:	8b 14 85 90 20 10 f0 	mov    -0xfefdf70(,%eax,4),%edx
f0100ef7:	85 d2                	test   %edx,%edx
f0100ef9:	75 20                	jne    f0100f1b <vprintfmt+0x16e>
				printfmt(putch, putdat, "error %d", err);
f0100efb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100eff:	c7 44 24 08 ba 1e 10 	movl   $0xf0101eba,0x8(%esp)
f0100f06:	f0 
f0100f07:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f0b:	89 3c 24             	mov    %edi,(%esp)
f0100f0e:	e8 31 03 00 00       	call   f0101244 <printfmt>
f0100f13:	8b 5d cc             	mov    -0x34(%ebp),%ebx
		// error message
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f16:	e9 be fe ff ff       	jmp    f0100dd9 <vprintfmt+0x2c>
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
f0100f1b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100f1f:	c7 44 24 08 c3 1e 10 	movl   $0xf0101ec3,0x8(%esp)
f0100f26:	f0 
f0100f27:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f2b:	89 3c 24             	mov    %edi,(%esp)
f0100f2e:	e8 11 03 00 00       	call   f0101244 <printfmt>
f0100f33:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0100f36:	e9 9e fe ff ff       	jmp    f0100dd9 <vprintfmt+0x2c>
f0100f3b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100f3e:	89 c3                	mov    %eax,%ebx
f0100f40:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100f43:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f46:	89 45 c4             	mov    %eax,-0x3c(%ebp)
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f49:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f4c:	8d 50 04             	lea    0x4(%eax),%edx
f0100f4f:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f52:	8b 00                	mov    (%eax),%eax
f0100f54:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f57:	85 c0                	test   %eax,%eax
f0100f59:	75 07                	jne    f0100f62 <vprintfmt+0x1b5>
f0100f5b:	c7 45 e0 c6 1e 10 f0 	movl   $0xf0101ec6,-0x20(%ebp)
				p = "(null)";
			if (width > 0 && padc != '-')
f0100f62:	83 7d c4 00          	cmpl   $0x0,-0x3c(%ebp)
f0100f66:	7e 06                	jle    f0100f6e <vprintfmt+0x1c1>
f0100f68:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100f6c:	75 13                	jne    f0100f81 <vprintfmt+0x1d4>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100f6e:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100f71:	0f be 02             	movsbl (%edx),%eax
f0100f74:	85 c0                	test   %eax,%eax
f0100f76:	0f 85 99 00 00 00    	jne    f0101015 <vprintfmt+0x268>
f0100f7c:	e9 86 00 00 00       	jmp    f0101007 <vprintfmt+0x25a>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f81:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100f85:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f88:	89 0c 24             	mov    %ecx,(%esp)
f0100f8b:	e8 db 03 00 00       	call   f010136b <strnlen>
f0100f90:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0100f93:	29 c2                	sub    %eax,%edx
f0100f95:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100f98:	85 d2                	test   %edx,%edx
f0100f9a:	7e d2                	jle    f0100f6e <vprintfmt+0x1c1>
					putch(padc, putdat);
f0100f9c:	0f be 4d d4          	movsbl -0x2c(%ebp),%ecx
f0100fa0:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100fa3:	89 5d c4             	mov    %ebx,-0x3c(%ebp)
f0100fa6:	89 d3                	mov    %edx,%ebx
f0100fa8:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100fac:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100faf:	89 04 24             	mov    %eax,(%esp)
f0100fb2:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fb4:	83 eb 01             	sub    $0x1,%ebx
f0100fb7:	85 db                	test   %ebx,%ebx
f0100fb9:	7f ed                	jg     f0100fa8 <vprintfmt+0x1fb>
f0100fbb:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100fbe:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100fc5:	eb a7                	jmp    f0100f6e <vprintfmt+0x1c1>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fc7:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100fcb:	74 18                	je     f0100fe5 <vprintfmt+0x238>
f0100fcd:	8d 50 e0             	lea    -0x20(%eax),%edx
f0100fd0:	83 fa 5e             	cmp    $0x5e,%edx
f0100fd3:	76 10                	jbe    f0100fe5 <vprintfmt+0x238>
					putch('?', putdat);
f0100fd5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fd9:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0100fe0:	ff 55 e0             	call   *-0x20(%ebp)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fe3:	eb 0a                	jmp    f0100fef <vprintfmt+0x242>
					putch('?', putdat);
				else
					putch(ch, putdat);
f0100fe5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fe9:	89 04 24             	mov    %eax,(%esp)
f0100fec:	ff 55 e0             	call   *-0x20(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fef:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f0100ff3:	0f be 03             	movsbl (%ebx),%eax
f0100ff6:	85 c0                	test   %eax,%eax
f0100ff8:	74 05                	je     f0100fff <vprintfmt+0x252>
f0100ffa:	83 c3 01             	add    $0x1,%ebx
f0100ffd:	eb 29                	jmp    f0101028 <vprintfmt+0x27b>
f0100fff:	89 fe                	mov    %edi,%esi
f0101001:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101004:	8b 5d d0             	mov    -0x30(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101007:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010100b:	7f 2e                	jg     f010103b <vprintfmt+0x28e>
f010100d:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0101010:	e9 c4 fd ff ff       	jmp    f0100dd9 <vprintfmt+0x2c>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101015:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101018:	83 c2 01             	add    $0x1,%edx
f010101b:	89 7d e0             	mov    %edi,-0x20(%ebp)
f010101e:	89 f7                	mov    %esi,%edi
f0101020:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101023:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0101026:	89 d3                	mov    %edx,%ebx
f0101028:	85 f6                	test   %esi,%esi
f010102a:	78 9b                	js     f0100fc7 <vprintfmt+0x21a>
f010102c:	83 ee 01             	sub    $0x1,%esi
f010102f:	79 96                	jns    f0100fc7 <vprintfmt+0x21a>
f0101031:	89 fe                	mov    %edi,%esi
f0101033:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101036:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101039:	eb cc                	jmp    f0101007 <vprintfmt+0x25a>
f010103b:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f010103e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101041:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101045:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010104c:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010104e:	83 eb 01             	sub    $0x1,%ebx
f0101051:	85 db                	test   %ebx,%ebx
f0101053:	7f ec                	jg     f0101041 <vprintfmt+0x294>
f0101055:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0101058:	e9 7c fd ff ff       	jmp    f0100dd9 <vprintfmt+0x2c>
f010105d:	89 45 cc             	mov    %eax,-0x34(%ebp)
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101060:	83 f9 01             	cmp    $0x1,%ecx
f0101063:	7e 16                	jle    f010107b <vprintfmt+0x2ce>
		return va_arg(*ap, long long);
f0101065:	8b 45 14             	mov    0x14(%ebp),%eax
f0101068:	8d 50 08             	lea    0x8(%eax),%edx
f010106b:	89 55 14             	mov    %edx,0x14(%ebp)
f010106e:	8b 10                	mov    (%eax),%edx
f0101070:	8b 48 04             	mov    0x4(%eax),%ecx
f0101073:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0101076:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101079:	eb 32                	jmp    f01010ad <vprintfmt+0x300>
	else if (lflag)
f010107b:	85 c9                	test   %ecx,%ecx
f010107d:	74 18                	je     f0101097 <vprintfmt+0x2ea>
		return va_arg(*ap, long);
f010107f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101082:	8d 50 04             	lea    0x4(%eax),%edx
f0101085:	89 55 14             	mov    %edx,0x14(%ebp)
f0101088:	8b 00                	mov    (%eax),%eax
f010108a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010108d:	89 c1                	mov    %eax,%ecx
f010108f:	c1 f9 1f             	sar    $0x1f,%ecx
f0101092:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101095:	eb 16                	jmp    f01010ad <vprintfmt+0x300>
	else
		return va_arg(*ap, int);
f0101097:	8b 45 14             	mov    0x14(%ebp),%eax
f010109a:	8d 50 04             	lea    0x4(%eax),%edx
f010109d:	89 55 14             	mov    %edx,0x14(%ebp)
f01010a0:	8b 00                	mov    (%eax),%eax
f01010a2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010a5:	89 c2                	mov    %eax,%edx
f01010a7:	c1 fa 1f             	sar    $0x1f,%edx
f01010aa:	89 55 dc             	mov    %edx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01010ad:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01010b0:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01010b3:	b8 0a 00 00 00       	mov    $0xa,%eax
			if ((long long) num < 0) {
f01010b8:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01010bc:	0f 89 9b 00 00 00    	jns    f010115d <vprintfmt+0x3b0>
				putch('-', putdat);
f01010c2:	89 74 24 04          	mov    %esi,0x4(%esp)
f01010c6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01010cd:	ff d7                	call   *%edi
				num = -(long long) num;
f01010cf:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01010d2:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01010d5:	f7 d9                	neg    %ecx
f01010d7:	83 d3 00             	adc    $0x0,%ebx
f01010da:	f7 db                	neg    %ebx
f01010dc:	b8 0a 00 00 00       	mov    $0xa,%eax
f01010e1:	eb 7a                	jmp    f010115d <vprintfmt+0x3b0>
f01010e3:	89 45 cc             	mov    %eax,-0x34(%ebp)
			base = 10;
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01010e6:	89 ca                	mov    %ecx,%edx
f01010e8:	8d 45 14             	lea    0x14(%ebp),%eax
f01010eb:	e8 66 fc ff ff       	call   f0100d56 <getuint>
f01010f0:	89 c1                	mov    %eax,%ecx
f01010f2:	89 d3                	mov    %edx,%ebx
f01010f4:	b8 0a 00 00 00       	mov    $0xa,%eax
			base = 10;
			goto number;
f01010f9:	eb 62                	jmp    f010115d <vprintfmt+0x3b0>
f01010fb:	89 45 cc             	mov    %eax,-0x34(%ebp)

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01010fe:	89 ca                	mov    %ecx,%edx
f0101100:	8d 45 14             	lea    0x14(%ebp),%eax
f0101103:	e8 4e fc ff ff       	call   f0100d56 <getuint>
f0101108:	89 c1                	mov    %eax,%ecx
f010110a:	89 d3                	mov    %edx,%ebx
f010110c:	b8 08 00 00 00       	mov    $0x8,%eax
			base = 8;
			goto number;
f0101111:	eb 4a                	jmp    f010115d <vprintfmt+0x3b0>
f0101113:	89 45 cc             	mov    %eax,-0x34(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
f0101116:	89 74 24 04          	mov    %esi,0x4(%esp)
f010111a:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101121:	ff d7                	call   *%edi
			putch('x', putdat);
f0101123:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101127:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010112e:	ff d7                	call   *%edi
			num = (unsigned long long)
f0101130:	8b 45 14             	mov    0x14(%ebp),%eax
f0101133:	8d 50 04             	lea    0x4(%eax),%edx
f0101136:	89 55 14             	mov    %edx,0x14(%ebp)
f0101139:	8b 08                	mov    (%eax),%ecx
f010113b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101140:	b8 10 00 00 00       	mov    $0x10,%eax
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101145:	eb 16                	jmp    f010115d <vprintfmt+0x3b0>
f0101147:	89 45 cc             	mov    %eax,-0x34(%ebp)

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010114a:	89 ca                	mov    %ecx,%edx
f010114c:	8d 45 14             	lea    0x14(%ebp),%eax
f010114f:	e8 02 fc ff ff       	call   f0100d56 <getuint>
f0101154:	89 c1                	mov    %eax,%ecx
f0101156:	89 d3                	mov    %edx,%ebx
f0101158:	b8 10 00 00 00       	mov    $0x10,%eax
			base = 16;
		number:
			printnum(putch, putdat, num, base, width, padc);
f010115d:	0f be 55 d4          	movsbl -0x2c(%ebp),%edx
f0101161:	89 54 24 10          	mov    %edx,0x10(%esp)
f0101165:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101168:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010116c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101170:	89 0c 24             	mov    %ecx,(%esp)
f0101173:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101177:	89 f2                	mov    %esi,%edx
f0101179:	89 f8                	mov    %edi,%eax
f010117b:	e8 e0 fa ff ff       	call   f0100c60 <printnum>
f0101180:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			break;
f0101183:	e9 51 fc ff ff       	jmp    f0100dd9 <vprintfmt+0x2c>
f0101188:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010118b:	8b 55 e0             	mov    -0x20(%ebp),%edx

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010118e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101192:	89 14 24             	mov    %edx,(%esp)
f0101195:	ff d7                	call   *%edi
f0101197:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			break;
f010119a:	e9 3a fc ff ff       	jmp    f0100dd9 <vprintfmt+0x2c>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010119f:	89 74 24 04          	mov    %esi,0x4(%esp)
f01011a3:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01011aa:	ff d7                	call   *%edi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01011ac:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01011af:	80 38 25             	cmpb   $0x25,(%eax)
f01011b2:	0f 84 21 fc ff ff    	je     f0100dd9 <vprintfmt+0x2c>
f01011b8:	89 c3                	mov    %eax,%ebx
f01011ba:	eb f0                	jmp    f01011ac <vprintfmt+0x3ff>
				/* do nothing */;
			break;
		}
	}
}
f01011bc:	83 c4 5c             	add    $0x5c,%esp
f01011bf:	5b                   	pop    %ebx
f01011c0:	5e                   	pop    %esi
f01011c1:	5f                   	pop    %edi
f01011c2:	5d                   	pop    %ebp
f01011c3:	c3                   	ret    

f01011c4 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011c4:	55                   	push   %ebp
f01011c5:	89 e5                	mov    %esp,%ebp
f01011c7:	83 ec 28             	sub    $0x28,%esp
f01011ca:	8b 45 08             	mov    0x8(%ebp),%eax
f01011cd:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
f01011d0:	85 c0                	test   %eax,%eax
f01011d2:	74 04                	je     f01011d8 <vsnprintf+0x14>
f01011d4:	85 d2                	test   %edx,%edx
f01011d6:	7f 07                	jg     f01011df <vsnprintf+0x1b>
f01011d8:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01011dd:	eb 3b                	jmp    f010121a <vsnprintf+0x56>
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};
f01011df:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01011e2:	8d 44 10 ff          	lea    -0x1(%eax,%edx,1),%eax
f01011e6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01011e9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011f0:	8b 45 14             	mov    0x14(%ebp),%eax
f01011f3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011f7:	8b 45 10             	mov    0x10(%ebp),%eax
f01011fa:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011fe:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101201:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101205:	c7 04 24 90 0d 10 f0 	movl   $0xf0100d90,(%esp)
f010120c:	e8 9c fb ff ff       	call   f0100dad <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101211:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101214:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101217:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f010121a:	c9                   	leave  
f010121b:	c3                   	ret    

f010121c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010121c:	55                   	push   %ebp
f010121d:	89 e5                	mov    %esp,%ebp
f010121f:	83 ec 18             	sub    $0x18,%esp

	return b.cnt;
}

int
snprintf(char *buf, int n, const char *fmt, ...)
f0101222:	8d 45 14             	lea    0x14(%ebp),%eax
{
	va_list ap;
	int rc;

	va_start(ap, fmt);
	rc = vsnprintf(buf, n, fmt, ap);
f0101225:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101229:	8b 45 10             	mov    0x10(%ebp),%eax
f010122c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101230:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101233:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101237:	8b 45 08             	mov    0x8(%ebp),%eax
f010123a:	89 04 24             	mov    %eax,(%esp)
f010123d:	e8 82 ff ff ff       	call   f01011c4 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101242:	c9                   	leave  
f0101243:	c3                   	ret    

f0101244 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101244:	55                   	push   %ebp
f0101245:	89 e5                	mov    %esp,%ebp
f0101247:	83 ec 18             	sub    $0x18,%esp
		}
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
f010124a:	8d 45 14             	lea    0x14(%ebp),%eax
{
	va_list ap;

	va_start(ap, fmt);
	vprintfmt(putch, putdat, fmt, ap);
f010124d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101251:	8b 45 10             	mov    0x10(%ebp),%eax
f0101254:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101258:	8b 45 0c             	mov    0xc(%ebp),%eax
f010125b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010125f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101262:	89 04 24             	mov    %eax,(%esp)
f0101265:	e8 43 fb ff ff       	call   f0100dad <vprintfmt>
	va_end(ap);
}
f010126a:	c9                   	leave  
f010126b:	c3                   	ret    
f010126c:	00 00                	add    %al,(%eax)
	...

f0101270 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101270:	55                   	push   %ebp
f0101271:	89 e5                	mov    %esp,%ebp
f0101273:	57                   	push   %edi
f0101274:	56                   	push   %esi
f0101275:	53                   	push   %ebx
f0101276:	83 ec 1c             	sub    $0x1c,%esp
f0101279:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010127c:	85 c0                	test   %eax,%eax
f010127e:	74 10                	je     f0101290 <readline+0x20>
		cprintf("%s", prompt);
f0101280:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101284:	c7 04 24 c3 1e 10 f0 	movl   $0xf0101ec3,(%esp)
f010128b:	e8 9b f6 ff ff       	call   f010092b <cprintf>

	i = 0;
	echoing = iscons(0);
f0101290:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101297:	e8 fa ef ff ff       	call   f0100296 <iscons>
f010129c:	89 c7                	mov    %eax,%edi
f010129e:	be 00 00 00 00       	mov    $0x0,%esi
	while (1) {
		c = getchar();
f01012a3:	e8 dd ef ff ff       	call   f0100285 <getchar>
f01012a8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01012aa:	85 c0                	test   %eax,%eax
f01012ac:	79 17                	jns    f01012c5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01012ae:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012b2:	c7 04 24 ac 20 10 f0 	movl   $0xf01020ac,(%esp)
f01012b9:	e8 6d f6 ff ff       	call   f010092b <cprintf>
f01012be:	b8 00 00 00 00       	mov    $0x0,%eax
			return NULL;
f01012c3:	eb 76                	jmp    f010133b <readline+0xcb>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01012c5:	83 f8 08             	cmp    $0x8,%eax
f01012c8:	74 08                	je     f01012d2 <readline+0x62>
f01012ca:	83 f8 7f             	cmp    $0x7f,%eax
f01012cd:	8d 76 00             	lea    0x0(%esi),%esi
f01012d0:	75 19                	jne    f01012eb <readline+0x7b>
f01012d2:	85 f6                	test   %esi,%esi
f01012d4:	7e 15                	jle    f01012eb <readline+0x7b>
			if (echoing)
f01012d6:	85 ff                	test   %edi,%edi
f01012d8:	74 0c                	je     f01012e6 <readline+0x76>
				cputchar('\b');
f01012da:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01012e1:	e8 b4 f1 ff ff       	call   f010049a <cputchar>
			i--;
f01012e6:	83 ee 01             	sub    $0x1,%esi
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01012e9:	eb b8                	jmp    f01012a3 <readline+0x33>
			if (echoing)
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
f01012eb:	83 fb 1f             	cmp    $0x1f,%ebx
f01012ee:	66 90                	xchg   %ax,%ax
f01012f0:	7e 23                	jle    f0101315 <readline+0xa5>
f01012f2:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01012f8:	7f 1b                	jg     f0101315 <readline+0xa5>
			if (echoing)
f01012fa:	85 ff                	test   %edi,%edi
f01012fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101300:	74 08                	je     f010130a <readline+0x9a>
				cputchar(c);
f0101302:	89 1c 24             	mov    %ebx,(%esp)
f0101305:	e8 90 f1 ff ff       	call   f010049a <cputchar>
			buf[i++] = c;
f010130a:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f0101310:	83 c6 01             	add    $0x1,%esi
f0101313:	eb 8e                	jmp    f01012a3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0101315:	83 fb 0a             	cmp    $0xa,%ebx
f0101318:	74 05                	je     f010131f <readline+0xaf>
f010131a:	83 fb 0d             	cmp    $0xd,%ebx
f010131d:	75 84                	jne    f01012a3 <readline+0x33>
			if (echoing)
f010131f:	85 ff                	test   %edi,%edi
f0101321:	74 0c                	je     f010132f <readline+0xbf>
				cputchar('\n');
f0101323:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f010132a:	e8 6b f1 ff ff       	call   f010049a <cputchar>
			buf[i] = 0;
f010132f:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
f0101336:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
			return buf;
		}
	}
}
f010133b:	83 c4 1c             	add    $0x1c,%esp
f010133e:	5b                   	pop    %ebx
f010133f:	5e                   	pop    %esi
f0101340:	5f                   	pop    %edi
f0101341:	5d                   	pop    %ebp
f0101342:	c3                   	ret    
	...

f0101350 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101350:	55                   	push   %ebp
f0101351:	89 e5                	mov    %esp,%ebp
f0101353:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101356:	b8 00 00 00 00       	mov    $0x0,%eax
f010135b:	80 3a 00             	cmpb   $0x0,(%edx)
f010135e:	74 09                	je     f0101369 <strlen+0x19>
		n++;
f0101360:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101363:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101367:	75 f7                	jne    f0101360 <strlen+0x10>
		n++;
	return n;
}
f0101369:	5d                   	pop    %ebp
f010136a:	c3                   	ret    

f010136b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010136b:	55                   	push   %ebp
f010136c:	89 e5                	mov    %esp,%ebp
f010136e:	53                   	push   %ebx
f010136f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101372:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101375:	85 c9                	test   %ecx,%ecx
f0101377:	74 19                	je     f0101392 <strnlen+0x27>
f0101379:	80 3b 00             	cmpb   $0x0,(%ebx)
f010137c:	74 14                	je     f0101392 <strnlen+0x27>
f010137e:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0101383:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101386:	39 c8                	cmp    %ecx,%eax
f0101388:	74 0d                	je     f0101397 <strnlen+0x2c>
f010138a:	80 3c 03 00          	cmpb   $0x0,(%ebx,%eax,1)
f010138e:	75 f3                	jne    f0101383 <strnlen+0x18>
f0101390:	eb 05                	jmp    f0101397 <strnlen+0x2c>
f0101392:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101397:	5b                   	pop    %ebx
f0101398:	5d                   	pop    %ebp
f0101399:	c3                   	ret    

f010139a <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010139a:	55                   	push   %ebp
f010139b:	89 e5                	mov    %esp,%ebp
f010139d:	53                   	push   %ebx
f010139e:	8b 45 08             	mov    0x8(%ebp),%eax
f01013a1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01013a4:	ba 00 00 00 00       	mov    $0x0,%edx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01013a9:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01013ad:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01013b0:	83 c2 01             	add    $0x1,%edx
f01013b3:	84 c9                	test   %cl,%cl
f01013b5:	75 f2                	jne    f01013a9 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01013b7:	5b                   	pop    %ebx
f01013b8:	5d                   	pop    %ebp
f01013b9:	c3                   	ret    

f01013ba <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01013ba:	55                   	push   %ebp
f01013bb:	89 e5                	mov    %esp,%ebp
f01013bd:	56                   	push   %esi
f01013be:	53                   	push   %ebx
f01013bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01013c2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013c5:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013c8:	85 f6                	test   %esi,%esi
f01013ca:	74 18                	je     f01013e4 <strncpy+0x2a>
f01013cc:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f01013d1:	0f b6 1a             	movzbl (%edx),%ebx
f01013d4:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01013d7:	80 3a 01             	cmpb   $0x1,(%edx)
f01013da:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013dd:	83 c1 01             	add    $0x1,%ecx
f01013e0:	39 ce                	cmp    %ecx,%esi
f01013e2:	77 ed                	ja     f01013d1 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01013e4:	5b                   	pop    %ebx
f01013e5:	5e                   	pop    %esi
f01013e6:	5d                   	pop    %ebp
f01013e7:	c3                   	ret    

f01013e8 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01013e8:	55                   	push   %ebp
f01013e9:	89 e5                	mov    %esp,%ebp
f01013eb:	56                   	push   %esi
f01013ec:	53                   	push   %ebx
f01013ed:	8b 75 08             	mov    0x8(%ebp),%esi
f01013f0:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013f3:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013f6:	89 f0                	mov    %esi,%eax
f01013f8:	85 c9                	test   %ecx,%ecx
f01013fa:	74 27                	je     f0101423 <strlcpy+0x3b>
		while (--size > 0 && *src != '\0')
f01013fc:	83 e9 01             	sub    $0x1,%ecx
f01013ff:	74 1d                	je     f010141e <strlcpy+0x36>
f0101401:	0f b6 1a             	movzbl (%edx),%ebx
f0101404:	84 db                	test   %bl,%bl
f0101406:	74 16                	je     f010141e <strlcpy+0x36>
			*dst++ = *src++;
f0101408:	88 18                	mov    %bl,(%eax)
f010140a:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010140d:	83 e9 01             	sub    $0x1,%ecx
f0101410:	74 0e                	je     f0101420 <strlcpy+0x38>
			*dst++ = *src++;
f0101412:	83 c2 01             	add    $0x1,%edx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101415:	0f b6 1a             	movzbl (%edx),%ebx
f0101418:	84 db                	test   %bl,%bl
f010141a:	75 ec                	jne    f0101408 <strlcpy+0x20>
f010141c:	eb 02                	jmp    f0101420 <strlcpy+0x38>
f010141e:	89 f0                	mov    %esi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101420:	c6 00 00             	movb   $0x0,(%eax)
f0101423:	29 f0                	sub    %esi,%eax
	}
	return dst - dst_in;
}
f0101425:	5b                   	pop    %ebx
f0101426:	5e                   	pop    %esi
f0101427:	5d                   	pop    %ebp
f0101428:	c3                   	ret    

f0101429 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101429:	55                   	push   %ebp
f010142a:	89 e5                	mov    %esp,%ebp
f010142c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010142f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101432:	0f b6 01             	movzbl (%ecx),%eax
f0101435:	84 c0                	test   %al,%al
f0101437:	74 15                	je     f010144e <strcmp+0x25>
f0101439:	3a 02                	cmp    (%edx),%al
f010143b:	75 11                	jne    f010144e <strcmp+0x25>
		p++, q++;
f010143d:	83 c1 01             	add    $0x1,%ecx
f0101440:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101443:	0f b6 01             	movzbl (%ecx),%eax
f0101446:	84 c0                	test   %al,%al
f0101448:	74 04                	je     f010144e <strcmp+0x25>
f010144a:	3a 02                	cmp    (%edx),%al
f010144c:	74 ef                	je     f010143d <strcmp+0x14>
f010144e:	0f b6 c0             	movzbl %al,%eax
f0101451:	0f b6 12             	movzbl (%edx),%edx
f0101454:	29 d0                	sub    %edx,%eax
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101456:	5d                   	pop    %ebp
f0101457:	c3                   	ret    

f0101458 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101458:	55                   	push   %ebp
f0101459:	89 e5                	mov    %esp,%ebp
f010145b:	53                   	push   %ebx
f010145c:	8b 55 08             	mov    0x8(%ebp),%edx
f010145f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101462:	8b 45 10             	mov    0x10(%ebp),%eax
	while (n > 0 && *p && *p == *q)
f0101465:	85 c0                	test   %eax,%eax
f0101467:	74 23                	je     f010148c <strncmp+0x34>
f0101469:	0f b6 1a             	movzbl (%edx),%ebx
f010146c:	84 db                	test   %bl,%bl
f010146e:	74 24                	je     f0101494 <strncmp+0x3c>
f0101470:	3a 19                	cmp    (%ecx),%bl
f0101472:	75 20                	jne    f0101494 <strncmp+0x3c>
f0101474:	83 e8 01             	sub    $0x1,%eax
f0101477:	74 13                	je     f010148c <strncmp+0x34>
		n--, p++, q++;
f0101479:	83 c2 01             	add    $0x1,%edx
f010147c:	83 c1 01             	add    $0x1,%ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010147f:	0f b6 1a             	movzbl (%edx),%ebx
f0101482:	84 db                	test   %bl,%bl
f0101484:	74 0e                	je     f0101494 <strncmp+0x3c>
f0101486:	3a 19                	cmp    (%ecx),%bl
f0101488:	74 ea                	je     f0101474 <strncmp+0x1c>
f010148a:	eb 08                	jmp    f0101494 <strncmp+0x3c>
f010148c:	b8 00 00 00 00       	mov    $0x0,%eax
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101491:	5b                   	pop    %ebx
f0101492:	5d                   	pop    %ebp
f0101493:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101494:	0f b6 02             	movzbl (%edx),%eax
f0101497:	0f b6 11             	movzbl (%ecx),%edx
f010149a:	29 d0                	sub    %edx,%eax
f010149c:	eb f3                	jmp    f0101491 <strncmp+0x39>

f010149e <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010149e:	55                   	push   %ebp
f010149f:	89 e5                	mov    %esp,%ebp
f01014a1:	8b 45 08             	mov    0x8(%ebp),%eax
f01014a4:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01014a8:	0f b6 10             	movzbl (%eax),%edx
f01014ab:	84 d2                	test   %dl,%dl
f01014ad:	74 15                	je     f01014c4 <strchr+0x26>
		if (*s == c)
f01014af:	38 ca                	cmp    %cl,%dl
f01014b1:	75 07                	jne    f01014ba <strchr+0x1c>
f01014b3:	eb 14                	jmp    f01014c9 <strchr+0x2b>
f01014b5:	38 ca                	cmp    %cl,%dl
f01014b7:	90                   	nop
f01014b8:	74 0f                	je     f01014c9 <strchr+0x2b>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01014ba:	83 c0 01             	add    $0x1,%eax
f01014bd:	0f b6 10             	movzbl (%eax),%edx
f01014c0:	84 d2                	test   %dl,%dl
f01014c2:	75 f1                	jne    f01014b5 <strchr+0x17>
f01014c4:	b8 00 00 00 00       	mov    $0x0,%eax
		if (*s == c)
			return (char *) s;
	return 0;
}
f01014c9:	5d                   	pop    %ebp
f01014ca:	c3                   	ret    

f01014cb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01014cb:	55                   	push   %ebp
f01014cc:	89 e5                	mov    %esp,%ebp
f01014ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01014d1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01014d5:	0f b6 10             	movzbl (%eax),%edx
f01014d8:	84 d2                	test   %dl,%dl
f01014da:	74 18                	je     f01014f4 <strfind+0x29>
		if (*s == c)
f01014dc:	38 ca                	cmp    %cl,%dl
f01014de:	75 0a                	jne    f01014ea <strfind+0x1f>
f01014e0:	eb 12                	jmp    f01014f4 <strfind+0x29>
f01014e2:	38 ca                	cmp    %cl,%dl
f01014e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01014e8:	74 0a                	je     f01014f4 <strfind+0x29>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01014ea:	83 c0 01             	add    $0x1,%eax
f01014ed:	0f b6 10             	movzbl (%eax),%edx
f01014f0:	84 d2                	test   %dl,%dl
f01014f2:	75 ee                	jne    f01014e2 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f01014f4:	5d                   	pop    %ebp
f01014f5:	c3                   	ret    

f01014f6 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01014f6:	55                   	push   %ebp
f01014f7:	89 e5                	mov    %esp,%ebp
f01014f9:	83 ec 0c             	sub    $0xc,%esp
f01014fc:	89 1c 24             	mov    %ebx,(%esp)
f01014ff:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101503:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101507:	8b 7d 08             	mov    0x8(%ebp),%edi
f010150a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010150d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101510:	85 c9                	test   %ecx,%ecx
f0101512:	74 30                	je     f0101544 <memset+0x4e>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101514:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010151a:	75 25                	jne    f0101541 <memset+0x4b>
f010151c:	f6 c1 03             	test   $0x3,%cl
f010151f:	75 20                	jne    f0101541 <memset+0x4b>
		c &= 0xFF;
f0101521:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101524:	89 d3                	mov    %edx,%ebx
f0101526:	c1 e3 08             	shl    $0x8,%ebx
f0101529:	89 d6                	mov    %edx,%esi
f010152b:	c1 e6 18             	shl    $0x18,%esi
f010152e:	89 d0                	mov    %edx,%eax
f0101530:	c1 e0 10             	shl    $0x10,%eax
f0101533:	09 f0                	or     %esi,%eax
f0101535:	09 d0                	or     %edx,%eax
		asm volatile("cld; rep stosl\n"
f0101537:	09 d8                	or     %ebx,%eax
f0101539:	c1 e9 02             	shr    $0x2,%ecx
f010153c:	fc                   	cld    
f010153d:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010153f:	eb 03                	jmp    f0101544 <memset+0x4e>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101541:	fc                   	cld    
f0101542:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101544:	89 f8                	mov    %edi,%eax
f0101546:	8b 1c 24             	mov    (%esp),%ebx
f0101549:	8b 74 24 04          	mov    0x4(%esp),%esi
f010154d:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101551:	89 ec                	mov    %ebp,%esp
f0101553:	5d                   	pop    %ebp
f0101554:	c3                   	ret    

f0101555 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101555:	55                   	push   %ebp
f0101556:	89 e5                	mov    %esp,%ebp
f0101558:	83 ec 08             	sub    $0x8,%esp
f010155b:	89 34 24             	mov    %esi,(%esp)
f010155e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101562:	8b 45 08             	mov    0x8(%ebp),%eax
f0101565:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
f0101568:	8b 75 0c             	mov    0xc(%ebp),%esi
	d = dst;
f010156b:	89 c7                	mov    %eax,%edi
	if (s < d && s + n > d) {
f010156d:	39 c6                	cmp    %eax,%esi
f010156f:	73 35                	jae    f01015a6 <memmove+0x51>
f0101571:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101574:	39 d0                	cmp    %edx,%eax
f0101576:	73 2e                	jae    f01015a6 <memmove+0x51>
		s += n;
		d += n;
f0101578:	01 cf                	add    %ecx,%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010157a:	f6 c2 03             	test   $0x3,%dl
f010157d:	75 1b                	jne    f010159a <memmove+0x45>
f010157f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101585:	75 13                	jne    f010159a <memmove+0x45>
f0101587:	f6 c1 03             	test   $0x3,%cl
f010158a:	75 0e                	jne    f010159a <memmove+0x45>
			asm volatile("std; rep movsl\n"
f010158c:	83 ef 04             	sub    $0x4,%edi
f010158f:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101592:	c1 e9 02             	shr    $0x2,%ecx
f0101595:	fd                   	std    
f0101596:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101598:	eb 09                	jmp    f01015a3 <memmove+0x4e>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010159a:	83 ef 01             	sub    $0x1,%edi
f010159d:	8d 72 ff             	lea    -0x1(%edx),%esi
f01015a0:	fd                   	std    
f01015a1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01015a3:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01015a4:	eb 20                	jmp    f01015c6 <memmove+0x71>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015a6:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01015ac:	75 15                	jne    f01015c3 <memmove+0x6e>
f01015ae:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015b4:	75 0d                	jne    f01015c3 <memmove+0x6e>
f01015b6:	f6 c1 03             	test   $0x3,%cl
f01015b9:	75 08                	jne    f01015c3 <memmove+0x6e>
			asm volatile("cld; rep movsl\n"
f01015bb:	c1 e9 02             	shr    $0x2,%ecx
f01015be:	fc                   	cld    
f01015bf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015c1:	eb 03                	jmp    f01015c6 <memmove+0x71>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01015c3:	fc                   	cld    
f01015c4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01015c6:	8b 34 24             	mov    (%esp),%esi
f01015c9:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01015cd:	89 ec                	mov    %ebp,%esp
f01015cf:	5d                   	pop    %ebp
f01015d0:	c3                   	ret    

f01015d1 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f01015d1:	55                   	push   %ebp
f01015d2:	89 e5                	mov    %esp,%ebp
f01015d4:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01015d7:	8b 45 10             	mov    0x10(%ebp),%eax
f01015da:	89 44 24 08          	mov    %eax,0x8(%esp)
f01015de:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015e1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01015e8:	89 04 24             	mov    %eax,(%esp)
f01015eb:	e8 65 ff ff ff       	call   f0101555 <memmove>
}
f01015f0:	c9                   	leave  
f01015f1:	c3                   	ret    

f01015f2 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01015f2:	55                   	push   %ebp
f01015f3:	89 e5                	mov    %esp,%ebp
f01015f5:	57                   	push   %edi
f01015f6:	56                   	push   %esi
f01015f7:	53                   	push   %ebx
f01015f8:	8b 75 08             	mov    0x8(%ebp),%esi
f01015fb:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01015fe:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101601:	85 c9                	test   %ecx,%ecx
f0101603:	74 36                	je     f010163b <memcmp+0x49>
		if (*s1 != *s2)
f0101605:	0f b6 06             	movzbl (%esi),%eax
f0101608:	0f b6 1f             	movzbl (%edi),%ebx
f010160b:	38 d8                	cmp    %bl,%al
f010160d:	74 20                	je     f010162f <memcmp+0x3d>
f010160f:	eb 14                	jmp    f0101625 <memcmp+0x33>
f0101611:	0f b6 44 16 01       	movzbl 0x1(%esi,%edx,1),%eax
f0101616:	0f b6 5c 17 01       	movzbl 0x1(%edi,%edx,1),%ebx
f010161b:	83 c2 01             	add    $0x1,%edx
f010161e:	83 e9 01             	sub    $0x1,%ecx
f0101621:	38 d8                	cmp    %bl,%al
f0101623:	74 12                	je     f0101637 <memcmp+0x45>
			return (int) *s1 - (int) *s2;
f0101625:	0f b6 c0             	movzbl %al,%eax
f0101628:	0f b6 db             	movzbl %bl,%ebx
f010162b:	29 d8                	sub    %ebx,%eax
f010162d:	eb 11                	jmp    f0101640 <memcmp+0x4e>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010162f:	83 e9 01             	sub    $0x1,%ecx
f0101632:	ba 00 00 00 00       	mov    $0x0,%edx
f0101637:	85 c9                	test   %ecx,%ecx
f0101639:	75 d6                	jne    f0101611 <memcmp+0x1f>
f010163b:	b8 00 00 00 00       	mov    $0x0,%eax
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
}
f0101640:	5b                   	pop    %ebx
f0101641:	5e                   	pop    %esi
f0101642:	5f                   	pop    %edi
f0101643:	5d                   	pop    %ebp
f0101644:	c3                   	ret    

f0101645 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101645:	55                   	push   %ebp
f0101646:	89 e5                	mov    %esp,%ebp
f0101648:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010164b:	89 c2                	mov    %eax,%edx
f010164d:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101650:	39 d0                	cmp    %edx,%eax
f0101652:	73 15                	jae    f0101669 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101654:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0101658:	38 08                	cmp    %cl,(%eax)
f010165a:	75 06                	jne    f0101662 <memfind+0x1d>
f010165c:	eb 0b                	jmp    f0101669 <memfind+0x24>
f010165e:	38 08                	cmp    %cl,(%eax)
f0101660:	74 07                	je     f0101669 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101662:	83 c0 01             	add    $0x1,%eax
f0101665:	39 c2                	cmp    %eax,%edx
f0101667:	77 f5                	ja     f010165e <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101669:	5d                   	pop    %ebp
f010166a:	c3                   	ret    

f010166b <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010166b:	55                   	push   %ebp
f010166c:	89 e5                	mov    %esp,%ebp
f010166e:	57                   	push   %edi
f010166f:	56                   	push   %esi
f0101670:	53                   	push   %ebx
f0101671:	83 ec 04             	sub    $0x4,%esp
f0101674:	8b 55 08             	mov    0x8(%ebp),%edx
f0101677:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010167a:	0f b6 02             	movzbl (%edx),%eax
f010167d:	3c 20                	cmp    $0x20,%al
f010167f:	74 04                	je     f0101685 <strtol+0x1a>
f0101681:	3c 09                	cmp    $0x9,%al
f0101683:	75 0e                	jne    f0101693 <strtol+0x28>
		s++;
f0101685:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101688:	0f b6 02             	movzbl (%edx),%eax
f010168b:	3c 20                	cmp    $0x20,%al
f010168d:	74 f6                	je     f0101685 <strtol+0x1a>
f010168f:	3c 09                	cmp    $0x9,%al
f0101691:	74 f2                	je     f0101685 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101693:	3c 2b                	cmp    $0x2b,%al
f0101695:	75 0c                	jne    f01016a3 <strtol+0x38>
		s++;
f0101697:	83 c2 01             	add    $0x1,%edx
f010169a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f01016a1:	eb 15                	jmp    f01016b8 <strtol+0x4d>
	else if (*s == '-')
f01016a3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f01016aa:	3c 2d                	cmp    $0x2d,%al
f01016ac:	75 0a                	jne    f01016b8 <strtol+0x4d>
		s++, neg = 1;
f01016ae:	83 c2 01             	add    $0x1,%edx
f01016b1:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01016b8:	85 db                	test   %ebx,%ebx
f01016ba:	0f 94 c0             	sete   %al
f01016bd:	74 05                	je     f01016c4 <strtol+0x59>
f01016bf:	83 fb 10             	cmp    $0x10,%ebx
f01016c2:	75 18                	jne    f01016dc <strtol+0x71>
f01016c4:	80 3a 30             	cmpb   $0x30,(%edx)
f01016c7:	75 13                	jne    f01016dc <strtol+0x71>
f01016c9:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01016cd:	8d 76 00             	lea    0x0(%esi),%esi
f01016d0:	75 0a                	jne    f01016dc <strtol+0x71>
		s += 2, base = 16;
f01016d2:	83 c2 02             	add    $0x2,%edx
f01016d5:	bb 10 00 00 00       	mov    $0x10,%ebx
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01016da:	eb 15                	jmp    f01016f1 <strtol+0x86>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01016dc:	84 c0                	test   %al,%al
f01016de:	66 90                	xchg   %ax,%ax
f01016e0:	74 0f                	je     f01016f1 <strtol+0x86>
f01016e2:	bb 0a 00 00 00       	mov    $0xa,%ebx
f01016e7:	80 3a 30             	cmpb   $0x30,(%edx)
f01016ea:	75 05                	jne    f01016f1 <strtol+0x86>
		s++, base = 8;
f01016ec:	83 c2 01             	add    $0x1,%edx
f01016ef:	b3 08                	mov    $0x8,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01016f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01016f6:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01016f8:	0f b6 0a             	movzbl (%edx),%ecx
f01016fb:	89 cf                	mov    %ecx,%edi
f01016fd:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101700:	80 fb 09             	cmp    $0x9,%bl
f0101703:	77 08                	ja     f010170d <strtol+0xa2>
			dig = *s - '0';
f0101705:	0f be c9             	movsbl %cl,%ecx
f0101708:	83 e9 30             	sub    $0x30,%ecx
f010170b:	eb 1e                	jmp    f010172b <strtol+0xc0>
		else if (*s >= 'a' && *s <= 'z')
f010170d:	8d 5f 9f             	lea    -0x61(%edi),%ebx
f0101710:	80 fb 19             	cmp    $0x19,%bl
f0101713:	77 08                	ja     f010171d <strtol+0xb2>
			dig = *s - 'a' + 10;
f0101715:	0f be c9             	movsbl %cl,%ecx
f0101718:	83 e9 57             	sub    $0x57,%ecx
f010171b:	eb 0e                	jmp    f010172b <strtol+0xc0>
		else if (*s >= 'A' && *s <= 'Z')
f010171d:	8d 5f bf             	lea    -0x41(%edi),%ebx
f0101720:	80 fb 19             	cmp    $0x19,%bl
f0101723:	77 15                	ja     f010173a <strtol+0xcf>
			dig = *s - 'A' + 10;
f0101725:	0f be c9             	movsbl %cl,%ecx
f0101728:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f010172b:	39 f1                	cmp    %esi,%ecx
f010172d:	7d 0b                	jge    f010173a <strtol+0xcf>
			break;
		s++, val = (val * base) + dig;
f010172f:	83 c2 01             	add    $0x1,%edx
f0101732:	0f af c6             	imul   %esi,%eax
f0101735:	8d 04 01             	lea    (%ecx,%eax,1),%eax
		// we don't properly detect overflow!
	}
f0101738:	eb be                	jmp    f01016f8 <strtol+0x8d>
f010173a:	89 c1                	mov    %eax,%ecx

	if (endptr)
f010173c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101740:	74 05                	je     f0101747 <strtol+0xdc>
		*endptr = (char *) s;
f0101742:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101745:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101747:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f010174b:	74 04                	je     f0101751 <strtol+0xe6>
f010174d:	89 c8                	mov    %ecx,%eax
f010174f:	f7 d8                	neg    %eax
}
f0101751:	83 c4 04             	add    $0x4,%esp
f0101754:	5b                   	pop    %ebx
f0101755:	5e                   	pop    %esi
f0101756:	5f                   	pop    %edi
f0101757:	5d                   	pop    %ebp
f0101758:	c3                   	ret    
f0101759:	00 00                	add    %al,(%eax)
f010175b:	00 00                	add    %al,(%eax)
f010175d:	00 00                	add    %al,(%eax)
	...

f0101760 <__udivdi3>:
f0101760:	55                   	push   %ebp
f0101761:	89 e5                	mov    %esp,%ebp
f0101763:	57                   	push   %edi
f0101764:	56                   	push   %esi
f0101765:	83 ec 10             	sub    $0x10,%esp
f0101768:	8b 45 14             	mov    0x14(%ebp),%eax
f010176b:	8b 55 08             	mov    0x8(%ebp),%edx
f010176e:	8b 75 10             	mov    0x10(%ebp),%esi
f0101771:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101774:	85 c0                	test   %eax,%eax
f0101776:	89 55 f0             	mov    %edx,-0x10(%ebp)
f0101779:	75 35                	jne    f01017b0 <__udivdi3+0x50>
f010177b:	39 fe                	cmp    %edi,%esi
f010177d:	77 61                	ja     f01017e0 <__udivdi3+0x80>
f010177f:	85 f6                	test   %esi,%esi
f0101781:	75 0b                	jne    f010178e <__udivdi3+0x2e>
f0101783:	b8 01 00 00 00       	mov    $0x1,%eax
f0101788:	31 d2                	xor    %edx,%edx
f010178a:	f7 f6                	div    %esi
f010178c:	89 c6                	mov    %eax,%esi
f010178e:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0101791:	31 d2                	xor    %edx,%edx
f0101793:	89 f8                	mov    %edi,%eax
f0101795:	f7 f6                	div    %esi
f0101797:	89 c7                	mov    %eax,%edi
f0101799:	89 c8                	mov    %ecx,%eax
f010179b:	f7 f6                	div    %esi
f010179d:	89 c1                	mov    %eax,%ecx
f010179f:	89 fa                	mov    %edi,%edx
f01017a1:	89 c8                	mov    %ecx,%eax
f01017a3:	83 c4 10             	add    $0x10,%esp
f01017a6:	5e                   	pop    %esi
f01017a7:	5f                   	pop    %edi
f01017a8:	5d                   	pop    %ebp
f01017a9:	c3                   	ret    
f01017aa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01017b0:	39 f8                	cmp    %edi,%eax
f01017b2:	77 1c                	ja     f01017d0 <__udivdi3+0x70>
f01017b4:	0f bd d0             	bsr    %eax,%edx
f01017b7:	83 f2 1f             	xor    $0x1f,%edx
f01017ba:	89 55 f4             	mov    %edx,-0xc(%ebp)
f01017bd:	75 39                	jne    f01017f8 <__udivdi3+0x98>
f01017bf:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f01017c2:	0f 86 a0 00 00 00    	jbe    f0101868 <__udivdi3+0x108>
f01017c8:	39 f8                	cmp    %edi,%eax
f01017ca:	0f 82 98 00 00 00    	jb     f0101868 <__udivdi3+0x108>
f01017d0:	31 ff                	xor    %edi,%edi
f01017d2:	31 c9                	xor    %ecx,%ecx
f01017d4:	89 c8                	mov    %ecx,%eax
f01017d6:	89 fa                	mov    %edi,%edx
f01017d8:	83 c4 10             	add    $0x10,%esp
f01017db:	5e                   	pop    %esi
f01017dc:	5f                   	pop    %edi
f01017dd:	5d                   	pop    %ebp
f01017de:	c3                   	ret    
f01017df:	90                   	nop
f01017e0:	89 d1                	mov    %edx,%ecx
f01017e2:	89 fa                	mov    %edi,%edx
f01017e4:	89 c8                	mov    %ecx,%eax
f01017e6:	31 ff                	xor    %edi,%edi
f01017e8:	f7 f6                	div    %esi
f01017ea:	89 c1                	mov    %eax,%ecx
f01017ec:	89 fa                	mov    %edi,%edx
f01017ee:	89 c8                	mov    %ecx,%eax
f01017f0:	83 c4 10             	add    $0x10,%esp
f01017f3:	5e                   	pop    %esi
f01017f4:	5f                   	pop    %edi
f01017f5:	5d                   	pop    %ebp
f01017f6:	c3                   	ret    
f01017f7:	90                   	nop
f01017f8:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f01017fc:	89 f2                	mov    %esi,%edx
f01017fe:	d3 e0                	shl    %cl,%eax
f0101800:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101803:	b8 20 00 00 00       	mov    $0x20,%eax
f0101808:	2b 45 f4             	sub    -0xc(%ebp),%eax
f010180b:	89 c1                	mov    %eax,%ecx
f010180d:	d3 ea                	shr    %cl,%edx
f010180f:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f0101813:	0b 55 ec             	or     -0x14(%ebp),%edx
f0101816:	d3 e6                	shl    %cl,%esi
f0101818:	89 c1                	mov    %eax,%ecx
f010181a:	89 75 e8             	mov    %esi,-0x18(%ebp)
f010181d:	89 fe                	mov    %edi,%esi
f010181f:	d3 ee                	shr    %cl,%esi
f0101821:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f0101825:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101828:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010182b:	d3 e7                	shl    %cl,%edi
f010182d:	89 c1                	mov    %eax,%ecx
f010182f:	d3 ea                	shr    %cl,%edx
f0101831:	09 d7                	or     %edx,%edi
f0101833:	89 f2                	mov    %esi,%edx
f0101835:	89 f8                	mov    %edi,%eax
f0101837:	f7 75 ec             	divl   -0x14(%ebp)
f010183a:	89 d6                	mov    %edx,%esi
f010183c:	89 c7                	mov    %eax,%edi
f010183e:	f7 65 e8             	mull   -0x18(%ebp)
f0101841:	39 d6                	cmp    %edx,%esi
f0101843:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101846:	72 30                	jb     f0101878 <__udivdi3+0x118>
f0101848:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010184b:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f010184f:	d3 e2                	shl    %cl,%edx
f0101851:	39 c2                	cmp    %eax,%edx
f0101853:	73 05                	jae    f010185a <__udivdi3+0xfa>
f0101855:	3b 75 ec             	cmp    -0x14(%ebp),%esi
f0101858:	74 1e                	je     f0101878 <__udivdi3+0x118>
f010185a:	89 f9                	mov    %edi,%ecx
f010185c:	31 ff                	xor    %edi,%edi
f010185e:	e9 71 ff ff ff       	jmp    f01017d4 <__udivdi3+0x74>
f0101863:	90                   	nop
f0101864:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101868:	31 ff                	xor    %edi,%edi
f010186a:	b9 01 00 00 00       	mov    $0x1,%ecx
f010186f:	e9 60 ff ff ff       	jmp    f01017d4 <__udivdi3+0x74>
f0101874:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101878:	8d 4f ff             	lea    -0x1(%edi),%ecx
f010187b:	31 ff                	xor    %edi,%edi
f010187d:	89 c8                	mov    %ecx,%eax
f010187f:	89 fa                	mov    %edi,%edx
f0101881:	83 c4 10             	add    $0x10,%esp
f0101884:	5e                   	pop    %esi
f0101885:	5f                   	pop    %edi
f0101886:	5d                   	pop    %ebp
f0101887:	c3                   	ret    
	...

f0101890 <__umoddi3>:
f0101890:	55                   	push   %ebp
f0101891:	89 e5                	mov    %esp,%ebp
f0101893:	57                   	push   %edi
f0101894:	56                   	push   %esi
f0101895:	83 ec 20             	sub    $0x20,%esp
f0101898:	8b 55 14             	mov    0x14(%ebp),%edx
f010189b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010189e:	8b 7d 10             	mov    0x10(%ebp),%edi
f01018a1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01018a4:	85 d2                	test   %edx,%edx
f01018a6:	89 c8                	mov    %ecx,%eax
f01018a8:	89 4d f4             	mov    %ecx,-0xc(%ebp)
f01018ab:	75 13                	jne    f01018c0 <__umoddi3+0x30>
f01018ad:	39 f7                	cmp    %esi,%edi
f01018af:	76 3f                	jbe    f01018f0 <__umoddi3+0x60>
f01018b1:	89 f2                	mov    %esi,%edx
f01018b3:	f7 f7                	div    %edi
f01018b5:	89 d0                	mov    %edx,%eax
f01018b7:	31 d2                	xor    %edx,%edx
f01018b9:	83 c4 20             	add    $0x20,%esp
f01018bc:	5e                   	pop    %esi
f01018bd:	5f                   	pop    %edi
f01018be:	5d                   	pop    %ebp
f01018bf:	c3                   	ret    
f01018c0:	39 f2                	cmp    %esi,%edx
f01018c2:	77 4c                	ja     f0101910 <__umoddi3+0x80>
f01018c4:	0f bd ca             	bsr    %edx,%ecx
f01018c7:	83 f1 1f             	xor    $0x1f,%ecx
f01018ca:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01018cd:	75 51                	jne    f0101920 <__umoddi3+0x90>
f01018cf:	3b 7d f4             	cmp    -0xc(%ebp),%edi
f01018d2:	0f 87 e0 00 00 00    	ja     f01019b8 <__umoddi3+0x128>
f01018d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01018db:	29 f8                	sub    %edi,%eax
f01018dd:	19 d6                	sbb    %edx,%esi
f01018df:	89 45 f4             	mov    %eax,-0xc(%ebp)
f01018e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01018e5:	89 f2                	mov    %esi,%edx
f01018e7:	83 c4 20             	add    $0x20,%esp
f01018ea:	5e                   	pop    %esi
f01018eb:	5f                   	pop    %edi
f01018ec:	5d                   	pop    %ebp
f01018ed:	c3                   	ret    
f01018ee:	66 90                	xchg   %ax,%ax
f01018f0:	85 ff                	test   %edi,%edi
f01018f2:	75 0b                	jne    f01018ff <__umoddi3+0x6f>
f01018f4:	b8 01 00 00 00       	mov    $0x1,%eax
f01018f9:	31 d2                	xor    %edx,%edx
f01018fb:	f7 f7                	div    %edi
f01018fd:	89 c7                	mov    %eax,%edi
f01018ff:	89 f0                	mov    %esi,%eax
f0101901:	31 d2                	xor    %edx,%edx
f0101903:	f7 f7                	div    %edi
f0101905:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101908:	f7 f7                	div    %edi
f010190a:	eb a9                	jmp    f01018b5 <__umoddi3+0x25>
f010190c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101910:	89 c8                	mov    %ecx,%eax
f0101912:	89 f2                	mov    %esi,%edx
f0101914:	83 c4 20             	add    $0x20,%esp
f0101917:	5e                   	pop    %esi
f0101918:	5f                   	pop    %edi
f0101919:	5d                   	pop    %ebp
f010191a:	c3                   	ret    
f010191b:	90                   	nop
f010191c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101920:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101924:	d3 e2                	shl    %cl,%edx
f0101926:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0101929:	ba 20 00 00 00       	mov    $0x20,%edx
f010192e:	2b 55 f0             	sub    -0x10(%ebp),%edx
f0101931:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101934:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101938:	89 fa                	mov    %edi,%edx
f010193a:	d3 ea                	shr    %cl,%edx
f010193c:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101940:	0b 55 f4             	or     -0xc(%ebp),%edx
f0101943:	d3 e7                	shl    %cl,%edi
f0101945:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101949:	89 55 f4             	mov    %edx,-0xc(%ebp)
f010194c:	89 f2                	mov    %esi,%edx
f010194e:	89 7d e8             	mov    %edi,-0x18(%ebp)
f0101951:	89 c7                	mov    %eax,%edi
f0101953:	d3 ea                	shr    %cl,%edx
f0101955:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101959:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010195c:	89 c2                	mov    %eax,%edx
f010195e:	d3 e6                	shl    %cl,%esi
f0101960:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101964:	d3 ea                	shr    %cl,%edx
f0101966:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f010196a:	09 d6                	or     %edx,%esi
f010196c:	89 f0                	mov    %esi,%eax
f010196e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101971:	d3 e7                	shl    %cl,%edi
f0101973:	89 f2                	mov    %esi,%edx
f0101975:	f7 75 f4             	divl   -0xc(%ebp)
f0101978:	89 d6                	mov    %edx,%esi
f010197a:	f7 65 e8             	mull   -0x18(%ebp)
f010197d:	39 d6                	cmp    %edx,%esi
f010197f:	72 2b                	jb     f01019ac <__umoddi3+0x11c>
f0101981:	39 c7                	cmp    %eax,%edi
f0101983:	72 23                	jb     f01019a8 <__umoddi3+0x118>
f0101985:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101989:	29 c7                	sub    %eax,%edi
f010198b:	19 d6                	sbb    %edx,%esi
f010198d:	89 f0                	mov    %esi,%eax
f010198f:	89 f2                	mov    %esi,%edx
f0101991:	d3 ef                	shr    %cl,%edi
f0101993:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101997:	d3 e0                	shl    %cl,%eax
f0101999:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f010199d:	09 f8                	or     %edi,%eax
f010199f:	d3 ea                	shr    %cl,%edx
f01019a1:	83 c4 20             	add    $0x20,%esp
f01019a4:	5e                   	pop    %esi
f01019a5:	5f                   	pop    %edi
f01019a6:	5d                   	pop    %ebp
f01019a7:	c3                   	ret    
f01019a8:	39 d6                	cmp    %edx,%esi
f01019aa:	75 d9                	jne    f0101985 <__umoddi3+0xf5>
f01019ac:	2b 45 e8             	sub    -0x18(%ebp),%eax
f01019af:	1b 55 f4             	sbb    -0xc(%ebp),%edx
f01019b2:	eb d1                	jmp    f0101985 <__umoddi3+0xf5>
f01019b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019b8:	39 f2                	cmp    %esi,%edx
f01019ba:	0f 82 18 ff ff ff    	jb     f01018d8 <__umoddi3+0x48>
f01019c0:	e9 1d ff ff ff       	jmp    f01018e2 <__umoddi3+0x52>
