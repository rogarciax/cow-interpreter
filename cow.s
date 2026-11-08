.data
	cowFileErr: 	 .string "\033[38:5:1m[ERROR]\033[m: file with path '%s' was not found in the system.\n"
	programUsageMsg: .string "\033[38:5:3mMissing cow file path!\033[m\nUsage: ./cow <program>.cow\n"
	cellUnderflowMsg:.string "\033[38:5:1m[ERROR]\033[m: tried to move back to a cell out of bounds \033[38:5:237m(underflow)\033[m."
	cellOverflowMsg: .string "\033[38:5:1m[ERROR]\033[m: tried to move forward to a cell out of bounds \033[38:5:237m(overflow)\033[m."
	fileMode:		 .string "r"
	
	cowInstSet:		 .string "moo", "mOo", "moO", "mOO"
					 .string "Moo", "MOo", "MoO", "MOO"
					 .string "OOO", "MMM", "OOM", "oom"

	cowInstJmps:	 .long moo
					 .long mOo
					 .long moO
					 .long mOO

					 .long Moo
					 .long MOo
					 .long MoO
					 .long MOO

					 .long MOO
					 .long OOO
					 .long OOM
					 .long oom

	instFormatStr: 	 .string "%3c"

	currentCell: 	 .int 0
	programMem: 	 .space 4096
	cpyReg:			 .int 0

.text
	.global main

/* FILE *openCow(const char *path) */
openCow:
	pushl %ebp
	movl %esp, %ebp
	pushl %ecx
	pushl %edx

	/* fopen(argv[1], "r") */
	pushl $fileMode
	pushl 8(%ebp)
	call fopen
	addl $8, %esp

	/* if (cowFilePtr == NULL) */
	cmpl $0, 8(%ebp)
	jne endOpenCow

	/* printf("[ERROR]: file with path '%s' was not found in the system.\n"); */
	fileErr:
	pushl 8(%ebp)
	pushl $cowFileErr
	call printf
	addl $8, %esp
	movl $0, %eax

	endOpenCow:
	popl %edx
	popl %ecx
	leave
	ret

/* char lower(char ch) */
lower:
	pushl %ebp
	movl %esp, %ebp

	movl 8(%ebp), %eax

	/* if (ch >= 'A' && ch <= 'Z') */
	cmp $'A', %eax
	jl endLower

	cmp $'Z', %eax
	jg endLower

	/* ch += 32 */
	addl $32, %eax

	endLower:
	leave
	ret

moo:
	ret

mOo:
	/* if (currentCell == 0) */
	cmpl $0, currentCell
	jne endmOo

	cellUnderflowErr:
	pushl %eax
	pushl %ecx
	pushl %edx

	/* printf("\033[38:5:1m[ERROR]\033[m: tried to move back to a cell out of bounds \033[38:5:237m(underflow)\033[m."); */
	pushl $cellUnderflowMsg
	call printf
	addl $4, %esp

	popl %eax
	popl %ecx
	popl %edx

	endmOo:
	/* currentCell--; */
	decl currentCell
	ret

moO:
	pushl %eax
	movl programMem, %eax
	shll $2, %eax

	/* if (currentCel > programMem / 4) */
	cmpl %eax, currentCell
	jle endmoO

	cellOverflowErr:
	pushl %eax
	pushl %ecx
	pushl %edx

	/* printf("\033[38:5:1m[ERROR]\033[m: tried to move forward to a cell out of bounds \033[38:5:237m(overflow)\033[m."); */
	pushl $cellOverflowMsg
	call printf
	addl $4, %esp

	popl %eax
	popl %ecx
	popl %edx

	endmoO:
	/* currentCell++; */
	incl currentCell
	popl %eax
	ret

mOO:
	ret

Moo:
	pushl %eax
	pushl %ecx
	pushl %edx
	pushl %ebx
	pushl %edi

	movl currentCell, %edi
	leal programMem(, %edi, 4), %ebx

	cmpl $0, (%ebx)
	je readASCIIChar

	printASCIIchar:
	pushl (%ebx)
	call putc
	addl $4, %esp

	jmp endMoo

	readASCIIChar:
	call getchar
	movl %eax, (%ebx)

	endMoo:
	popl %edi
	popl %ebx
	popl %edx
	popl %ecx
	popl %eax
	ret

MOo:
	ret

MoO:
	ret

MOO:
	ret

OOO:
	ret

OOM:
	ret

oom:
	ret

/* void processCowFile(FILE *filePtr) */
processCowFile:
	pushl %ebp
	movl %esp, %ebp
	subl $4, %esp
	pushl %eax
	pushl %ecx
	pushl %edx
	pushl %ebx
	pushl %edi

	/* instBuff = (char *)malloc(3); */
	pushl $3
	call malloc
	movl %eax, -4(%ebp)
	addl $4, %esp

	/* while (("%eax" = getc(filePtr)) != EOF) */
	readChar:
	pushl 8(%ebp)
	call getc
	addl $4, %esp

	cmpl $-1, %eax /* reached EOF */
	je endProcessCowFile

	/* "%eax" = lower("%eax"); */
	pushl %eax
	call lower
	addl $4, %esp

	/* if ("%eax" != 'm' || "%eax" != 'o') */
	cmpl $'m', %eax
	jne readChar

	cmpl $'o', %eax
	jne readChar
	/* continue; */

	/* fscanf(filePtr, "%3c", instBuff); */
	pushl -4(%ebp)
	pushl instFormatStr
	pushl 8(%ebp)
	call fscanf
	addl $12, %esp

	xor %edi, %edi

	/* do { */
	checkNextInst:
	pushl $3
	leal cowInstSet(, %edi, 4), %ebx
	pushl %ebx
	pushl -4(%ebp)
	call strncmp
	addl $12, %esp

	/* if (strncmp(instBuff, cowInstset[i], 3) != 0) */
	cmpl $0, %eax
	/* continue; */
	jne checkNextInst

	/* cowInstSet[i](); */
	call *cowInstSet(, %edi, 4)

	/* i++ */
	incl %edi
	
	/* } while (i <= 12); */
	cmpl $12, %edi
	jg readChar

	endProcessCowFile:
	popl %edi
	popl %ebx
	popl %edx
	popl %ecx
	popl %eax
	leave
	ret

main:
	pushl %ebp
	movl %esp, %ebp
	subl $4, %esp
	pushl %eax
	pushl %ecx
	pushl %edx
	pushl %esi

	/* if (argc == 1) */
	cmpl $1, 8(%ebp)
	je printUsageMsg

	movl 12(%ebp), %esi

	/* FILE *cowFile= openCow(argv[1]); */
	pushl 4(%esi)
	call openCow
	movl %eax, -4(%ebp)
	addl $4, %esp

	/* if (cowFile == NULL) */
	cmpl $0, -4(%ebp)
	/* return 1; */
	movl $1, %eax
	je endMain

	/* processCowFile(filePtr); */
	pushl -4(%ebp)
	call processCowFile
	addl $4, %esp

	/* fclose(cowFilePtr); */
	pushl -4(%ebp)
	call fclose
	addl $4, %esp

	jmp endMain

	/* printf("\033[38:5:3mMissing cow file path!\033[m\nUsage: ./cow <program>.cow\n"); */
	printUsageMsg:
	pushl $programUsageMsg
	call printf
	addl $4, %esp
	/* return 1; */
	movl $1, %eax

	endMain:
	popl %esi
	popl %edx
	popl %ecx
	popl %eax
	leave
	ret
