.data
	cowFileErr: 	.string "[ERROR]: file with path '%s' was not found in the system.\n"
	programUsageMsg:.string "\033[38:5:3mMissing cow file path!\033[m\nUsage: ./cow <program>.cow\n"
	fileMode:		.string "r"
	
	cowInstSet:		.string "MOO", "MoO", "MOo", "Moo", "MMM"
					.string "moO", "mOo", "moo", "mOO"
					.string "OOO", "OOM"
					.string "oom"

	cowInstJmps:	.long MOO
					.long MoO
					.long MOo
					.long Moo
					.long MMM

					.long moO
					.long mOo
					.long moo
					.long mOO

					.long OOO
					.long OOM

					.long oom

	instFormatStr: 	.string "%3c"

	programMem: 	.space 4096
	cpyReg:			.int 0


.text
	.global main

/*
1. Tendremos que leer carácter por carácter.
2. Se ignoran los espacios en blanco.
3. Cada vez que nos encontremos una M, m, o u O podemos
   empezar a procesar la instrucción.
4. La mejor estrategia es ir descartando posibles
   instrucciones, cualquier carácter distinto de los
   anteriores va a formar inmediatamente una instrucción
   invalida.
5. En caso contrario, tenemos un árbol de decisión por
   cada carácter de los que están formadas cada una de las
   12 instrucciones.
   m -> 	moo mOo moO mOO
   mo -> 	moo moO
   mO -> 	mOo mOO

   M -> 	Moo MOo MoO MOO MMM
   Mo -> 	Moo MoO
   MO -> 	MOo MOO
   MM -> 	MMM

   O -> 	OOO OOM
   OO -> 	0OO OOM

   o -> 	oom
6. Necesitamos un bucle que se encargue de tomar caracteres
   hasta llegar a EOF (%eax = -1) y en el interior del bucle
   tendremos que ir descartando hasta poder leer 3 caracteres.
7. Entonces tendremos que encadenar ifs que salten a la etiqueta
   en la que se ejecute la instrucción en sí misma.
*/

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

MOO:
	ret
MoO:
	ret
MOo:
	ret
Moo:
	ret
MMM:

moO:
	ret
mOo:
	ret
moo:
	ret
mOO:

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

	/* "%eax" = lower("%eax") */
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

	/* processCowFile(filePtr) */
	pushl -4(%ebp)
	call processCowFile
	addl $4, %esp

	/* fclose(cowFilePtr); */
	pushl -4(%ebp)
	call fclose
	addl $4, %esp

	jmp endMain

	/* printf("\033[38:5:3mMissing cow file path!\033[m\nUsage: ./cow <program>.cow\n") */
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
