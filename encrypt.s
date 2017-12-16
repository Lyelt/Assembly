	.arch  armv8-a
	.fpu   neon-fp-armv8
	.cpu   cortex-a53
	.syntax unified
	.global main

	.text

main:


gatherInput:
	mov  r0, #0
	ldr  r1, =input
	mov  r2, #16
	bl   read

	mov  r4, r0 // number of chars read

	bl   firstEncrypt

	mov  r0, r4 // number of chars read
	bl   secondEncrypt
	
	mov  r0, #1
	ldr  r1, =output
	mov  r2, r4
	bl   write

	cmp  r4, #16
	beq  gatherInput

end:
	mov r0, #0
	mov r7, #1
	swi #0

	
firstEncrypt:
	stmfd sp!, {r4, r5, r6, r7, r8, r9, r10, lr}
	
	mov  r5, r0 // number of chars read, 16 or less
	mov  r7, #0
	ldr  r4, =input

loop1:
	ldrb  r0, [r4, r7]
	bl    encryptLetter
	strb  r0, [r4, r7]

	add  r7, r7, #1
	cmp  r7, r5
	blt  loop1

	ldmfd sp!, {r4, r5, r6, r7, r8, r9, r10, lr}
	mov pc, lr

// -------------------------------------------------------------------
encryptLetter:
	stmfd sp!, {r4, r5, r6, r7, r8, r9, r10, lr}

	cmp  r0, #64
	blt  doExchange // less than 64, mix bits
	beq  endCheck   // 64 is nothing

	cmp  r0, #97
	bge  checkLower
	blt  checkUpper

	checkUpper:
		cmp  r0, #90
		bgt  endCheck  // 91-96, do nothing
		
		// Between 65-90, uppercase
		add  r0, r0, #32 // convert to lower
		add  r0, r0, #5  // cipher key of 5
		b    endCheck

	checkLower:
		cmp  r0, #122
		bgt  endCheck  // 123+, do nothing

		// Between 97-122, lowercase
		sub  r0, r0, #32 // convert to upper
		add  r0, r0, #7	 // cipher key of 7
		b    endCheck

	doExchange:
		// Less than 64
		mov  r1, r0 // save off original byte
		mov  r0, #0 // clear return value

		and  r2, r1, #32 // bit position 5
		lsr  r2, #3      // moves to pos 2
		orr  r0, r0, r2  // insert into ret val

		and  r2, r1, #16 // bit position 4
		lsr  r2, #3      // moves to pos 1
		orr  r0, r0, r2  // insert

		and  r2, r1, #8  // position 3
		lsl  r2, #1      // goes to 4
		orr  r0, r0, r2

		and  r2, r1, #4  // position 2
		lsr  r2, #2      // goes to 0
		orr  r0, r0, r2

		and  r2, r1, #2  // position 1
		lsl  r2, #4      // goes to 5	
		orr  r0, r0, r2

		and  r2, r1, #1  // position 0
		lsl  r2, #3      // goes to 3
		orr  r0, r0, r2
		
	endCheck:
		ldmfd sp!, {r4, r5, r6, r7, r8, r9, r10, lr}
		mov pc, lr


// ------------------------------------------------------------------
secondEncrypt:
	stmfd sp!, {r4, r5, r6, r7, r8, r9, r10, lr}
	cmp  r0, #16
	bge  doArrange
	// Less than 16 bytes, pad with blanks
	add  r0, r0, #1
	ldr  r1, =input
	loop2:
		mov  r2, #32 // spaces
		strb r2, [r1, r0]
		add  r0, r0, #1
		cmp  r0, #16
		blt  loop2
doArrange:
	ldr  r4, =input
	ldr  r5, =output
	mov  r6, #-1
	mov  r9, #0
	loop3:  // outer loop, for each "row"
		add  r6, r6, #1
		cmp  r6, #4
		bge  endArrange

		mov  r7, r6  // begin the increments of 4 at the current row number
		mov  r10, #0 // inner loop counter

	loop4:  // inner loop, for each "column", starting at whatever row we are on
		ldrb r8, [r4, r7]    // eg. first loop would do bytes 1, 5, 9, 13
		strb r8, [r5, r9]    // store to output space in its appropriate location
		
		add  r7, r7, #4    // inner loop, increments of 4
		add  r9, r9, #1    // output counter
		add  r10, r10, #1
		cmp  r10, #4
		bge  loop3
		b    loop4
		

endArrange:
	ldmfd sp!, {r4, r5, r6, r7, r8, r9, r10, lr}
	mov pc, lr


	.data
input:
	.space 16
output:
	.space 16
