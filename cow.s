.data
	/* Error messages */
	cowFileErr: 	 		.string "\033[38:5:1m[ERROR]\033[m: file with path '%s' was not found in the system.\n"
	programUsageMsg: 		.string "\033[38:5:3mMissing cow file path!\033[m\nUsage: ./cow <program>.cow\n"
	cellUnderflowMsg:		.string "\033[38:5:1m[ERROR]\033[m: tried to move back to a cell out of bounds \033[38:5:239m(CellUnderflow)\033[m.\n"
	cellOverflowMsg:		.string "\033[38:5:1m[ERROR]\033[m: tried to move forward to a cell out of bounds \033[38:5:239m(CellOverflow)\033[m.\n"
	outOfBoundsInstIdxMsg: 	.string "\033[38:5:1m[ERROR]\033[m: tried to execute instruction with index: %d (min 0, max 11) \033[38:5:239m(InstIdxOutOfBounds)\033[m.\n"

	/* File ops vars */
	fileMode:				.string "r"
	
	/* Interpreter vars */
	cowInstSet:				.string "moo", "mOo", "moO", "mOO"
					 		.string "Moo", "MOo", "MoO", "MOO"
					 		.string "OOO", "MMM", "OOM", "oom"

	cowInstJmps:			.long moo
							.long mOo
							.long moO
							.long mOO

							.long Moo
							.long MOo
							.long MoO
							.long MOO

							.long OOO
							.long MMM
							.long OOM
							.long oom

	/* Printf formats */
	instFormatStr: 			.string "%3c"
	intFormatStr:		.string "%d"

	/* Cell addressing vars */
	currentCell: 			.int 0
	totalCells: 			.int 1024
	programMem: 			.space 4096

	/* Copy register vars */
	cpyReg:					.int 0
	cpyRegState:			.byte 0 /* 1 occupied, 0 empty */

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

/* int moo() */
moo:
	ret

/* int mOo() */
mOo:
	/* if (currentCell == 0) */
	cmpl $0, currentCell
	jne endmOo
	movl $0, %eax /* to return 0 on success */

	cellUnderflowErr:
	pushl %ecx
	pushl %edx

	/* printf("\033[38:5:1m[ERROR]\033[m: tried to move back to a cell out of bounds \033[38:5:237m(underflow)\033[m."); */
	pushl $cellUnderflowMsg
	call printf
	addl $4, %esp
	movl $1, %eax /* to return 1 on failure */

	popl %ecx
	popl %edx

	endmOo:
	/* currentCell--; */
	decl currentCell
	ret

/* int moO() */
moO:
	pushl %ebx
	movl totalCells, %ebx

	movl $0, %eax /* to return 0 on success */

	/* if (currentCel > programMem / 4) */
	cmpl %ebx, currentCell
	jle endmoO

	cellOverflowErr:
	pushl %ecx
	pushl %edx

	/* printf("\033[38:5:1m[ERROR]\033[m: tried to move forward to a cell out of bounds \033[38:5:237m(overflow)\033[m."); */
	pushl $cellOverflowMsg
	call printf
	addl $4, %esp
	movl $1, %eax /* to return 1 on failure */

	popl %ecx
	popl %edx

	endmoO:
	/* currentCell++; */
	incl currentCell
	popl %ebx
	ret

/* int mOO() */
mOO:
	pushl %edi
	pushl %ebx

	movl currentCell, %edi
	/* "%ebx" = programMem[currentCell]; */
	movl programMem(, %edi, 4), %ebx

	movl $0, %eax /* to return 0 on success */

	/* if ("%ebx" >= 0 && "%ebx" < 12) */
	cmpl $0, %ebx
	jl outOfBoundsInstIdxErr

	cmpl $12, %ebx
	jge outOfBoundsInstIdxErr

	/* cowInstJmps["%ebx"](); */
	call *cowInstJmps(, %ebx, 4)
	jmp endmOO

	outOfBoundsInstIdxErr:
	pushl %ecx
	pushl %edx

	/* printf(\033[38:5:1m[ERROR]\033[m: tried to execute instruction with index: %d (min 0, max 11) \033[38:5:237m(InstIdxOutOfBounds)\033[m.) */
	pushl $outOfBoundsInstIdxMsg
	call printf
	addl $4, %esp
	movl $1, %eax /* to return 1 on failure */

	popl %edx
	popl %ecx

	endmOO:
	popl %ebx
	popl %edi
	ret

/* int Moo() */
Moo:
	pushl %ecx
	pushl %edx
	pushl %ebx
	pushl %edi

	movl currentCell, %edi
	/* "%ebx" = *programMem[currentCell]; */
	leal programMem(, %edi, 4), %ebx

	cmpl $0, (%ebx)
	je readASCIIChar

	printASCIIchar:
	/* putchar(*"%ebx") */
	pushl (%ebx)
	call putchar
	addl $4, %esp

	jmp endMoo

	readASCIIChar:
	/* "%ebx" = getchar() */
	call getchar
	movl %eax, (%ebx)

	endMoo:
	popl %edi
	popl %ebx
	popl %edx
	popl %ecx
	/* return 0; */
	movl $0, %eax
	ret

/* int MOo() */
MOo:
	pushl %edi

	/* programMem[currentCell]--; */
	movl currentCell, %edi
	decl programMem(, %edi, 4)
	/* return 0; */
	movl $0, %eax

	popl %edi
	ret

/* int MoO() */
MoO:
	pushl %edi

	/* programMem[currentCell]++; */
	movl currentCell, %edi
	incl programMem(, %edi, 4)
	/* return 0; */
	movl $0, %eax

	popl %edi
	ret

/* int MOO() */
MOO:
	ret

/* int OOO() */
OOO:
	pushl %edi
	pushl %ebx

	/* programMem[currentCell] = 0; */
	movl currentCell, %edi
	leal programMem(, %edi, 4), %ebx
	movl $0, (%ebx)
	/* return 0; */
	movl $0, %eax
	
	popl %ebx
	popl %edi
	ret

/* int MMM() */
MMM:
	pushl %edi
	pushl %ebx

	mov currentCell, %edi

	cmpl $1, cpyRegState
	je copyValIntoCell
	
	copyValIntoReg:
	movl programMem(, %edi, 4), %ebx
	/* cpyReg = programMem[currentCell]; */
	movl %ebx, cpyReg
	/* cpyRegState = 1 */
	movl $1, cpyRegState
	jmp endMMM

	copyValIntoCell:
	leal programMem(, %edi, 4), %ebx
	/* programMem[currentCell] = cpyReg; */
	movl cpyReg, %eax
	movl %eax, (%ebx)
	/* cpyRegState = 0 */
	movl $0, cpyRegState

	endMMM:
	/* return 0 */
	movl $0, %eax
	popl %ebx
	popl %edi
	ret

/* int OOM() */
OOM:
	pushl %edi
	pushl %ebx

	movl currentCell, %edi
	movl programMem(, %edi, 4), %ebx

	/* printf("%d", programMem[currentCell]); */
	pushl %ebx
	pushl $intFormatStr
	call printf
	addl $8, %esp

	/* return 0; */
	movl $0, %eax
	popl %ebx
	popl %edi
	ret

/* int oom() */
oom:
	pushl %edi
	pushl %ebx

	movl currentCell, %edi
	leal programMem(, %edi, 4), %ebx
	
	/* scanf("%d", programMem[currentCell]); */
	pushl %ebx
	pushl $intFormatStr
	call scanf
	addl $8, %esp

	/* return 0; */
	movl $0, %eax
	popl %ebx
	popl %edi
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
	je readInst

	cmpl $'o', %eax
	/* continue; */
	jne continueReadChar

	readInst:
	/* ftell(filePtr, -1, SEEK_CUR); */
	pushl $1 /* SEEK_CUR */
	pushl $-1
	pushl 8(%ebp)
	call fseek
	addl $12, %esp

	/* fscanf(filePtr, "%3c", instBuff); */
	pushl -4(%ebp)
	pushl $instFormatStr
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
	jne incInstIdx

	/* "%eax" = cowInstSet[i](); */
	call *cowInstJmps(, %edi, 4)

	cmpl $0, %eax
	jne endProcessCowFile
	movl $12, %edi /* To exit the loop */

	incInstIdx:
	/* i++ */
	incl %edi
	
	/* } while (i < 12); */
	cmpl $12, %edi
	jl checkNextInst

	continueReadChar:
	jmp readChar

	endProcessCowFile:
	/* free(instBuff); */
	pushl -4(%ebp)
	call free
	addl $4, %esp

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
