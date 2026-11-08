.data
	cowFileErr: 	.string "[ERROR]: file with path '%s' was not found in the system.\n"
	fileMode:		.string "r"
	cowFilePtr: 	.long 0

.text
	.global main

/* void openCow(const char *path) */
openCow:
	pushl %ebp
	movl %esp, %ebp
	pushl %eax
	pushl %ecx
	pushl %edx

	pushl $fileMode
	pushl 8(%ebp)
	call fopen
	movl %eax, cowFilePtr
	add $8, %esp

	cmpl $0, cowFilePtr
	jne endOpenCow

	fileErr:
	pushl 8(%ebp)
	pushl $cowFileErr
	call printf
	add $8, %esp

	endOpenCow:
	popl %edx
	popl %ecx
	popl %eax
	leave
	ret

main:
	pushl %ebp
	movl %esp, %ebp
	pushl %eax
	pushl %ecx
	pushl %edx
	pushl %esi

	movl 12(%ebp), %esi

	pushl 4(%esi)
	call openCow
	addl $4, %esp

	cmpl $0, cowFilePtr
	je endMain

	pushl cowFilePtr
	call fclose
	add $4, %esp

	endMain:
	popl %esi
	popl %edx
	popl %ecx
	popl %eax
	leave
	ret
