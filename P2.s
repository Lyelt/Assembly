// Nicholas Ghobrial
// P2

.arch armv8-a
.cpu cortex-a53
.global main
.syntax unified

.text

print:
	// ----Primpt prompt, echo input, convert, and print result
	// ----Parameters: input string, conversion choice
	mov r8, lr
promptLoop:	
	// write prompt
	mov r0, #1
	ldr r1, =prompt
	mov r2, #58
	bl write
	// read number
	mov r0, #0
	ldr r1, =input // 10 bytes
	mov r2, #10	
	bl read
	
	// validate input
	ldr r0, =input // Input string passed to validation function
	ldr r0, [r0]
	bl validateInput
	cmp r0, #1 // Input is valid
	bne promptLoop
	b choiceLoop
	
choiceLoop:
	// write prompt
	mov r0, #1
	ldr r1, =choice
	mov r2, #46
	bl write
	// read choice
	mov r0, #0
	ldr r1, =inputChoice
	mov r2, #1
	bl read

	// validate choice
	ldr r0, =inputChoice
	ldr r0, [r0]
	bl validateChoice
	cmp r0, #1 // input is valid
	bne choiceLoop
	b convert

convert:
// ------ both choices have been validated
	ldr r0, =input
	ldr r0, [r0]
	ldr r1, =inputChoice
	ldr r1, [r1]
	bl convertInput

	mov r10, r0 // result from conversion stored in r10

	// echo user input
	mov r0, #1
	ldr r1, =echoprompt
	mov r2, #18
	bl write // prompt
	mov r0, #1
	ldr r1, =input
	mov r2, #10
	bl write // value

	// echo choice
	mov r0, #1
	ldr r1, =echochoice
	mov r2, #19
	bl write // prompt
	mov r0, #1
	ldr r1, =inputChoice
	mov r2, #1
	bl write // value
	mov r0, #1
	ldr r1, =flush
	mov r2, #1
	bl write // flush

// ------ Print result
	mov r0, #1
	ldr r1, =outputWrite
	mov r2, #24
	bl write // output

	mov pc, r8 // previous contents of lr

	
	

convertInput:
	// ----Call the appropriate conversion function
	// ----Parameters: input string, conversion choice
	// ----Returns: equivalent output string
	mov r8, pc // save pc
		


	mov pc, r8

convertToHex:
	// ----Convert decimal value to hex string (8 chars)
	mov pc, lr

convertToOctal:
	// ----Convert decimal value to octal string (11 chars)
	mov pc, lr

convertToBinary:
	// ----Convert decimal value to binary string (32 chars)
	mov pc, lr

convertToDecimal:
	// ----Convert input string to 32-bit 2's compliment form
	mov pc, lr

validateInput:
	// ----Determine if the input string can be stored in 32-bit 2's compliment
	// ----Parameters: input string
	// ----Returns: 1 if input is valid
	mov r4, r0 // save param
	ldr r4, [r4]
	mov r0, #1 // default: true

	mov r3, #0  // start
	mov r2, #11 // end
	charCheckLoop:
		cmp r3, r2
		bge checkLast // if we reached 11th byte check if null 

		ldrb r1, [r4, r3] // each char in the input
		// if null, end of input
		cmp r1, #0
		
		b done 
		// valid range is 0-9
		sub r5, r1, #48
		cmp r5, #0
		blt checkBadData // could be + or -
		cmp r5, #9
		bgt bad
		
		add r3, r3, #1 
		b charCheckLoop

	checkLast:
		ldrb r1, [r4, r3] 
		cmp r1, #0 // if 11th byte isnt null, overflow
		bne bad
		b done
	
	checkBadData:
		// Any non-digit in non-first position is bad
		cmp r3, #0
		bne bad
		
		mov r6, #0
		// If its a + or - thats fine
		cmp r1, #43 // +
		mov r6, #1
		cmp r1, #45 // -
		mov r6, #1
		cmp r6, #1
		bne bad 

		// increment and loop
		add r3, r3, #1
		b charCheckLoop

	bad:	
		mov r0, #0 // found bad input
	
	done:
		mov pc, lr

validateChoice:
	// ----Determine if user entered valid choice (h, o, b)
	// ----Parameters: input char
	// ----Returns: 1 if input is valid
	mov r1, r0 // save param
	mov r0, #0 // default: false
	cmp r1, #104 // h
	beq good
	cmp r1, #111 // o
	beq good
	cmp r1, #98  // b
	beq good
	good:
		mov r0, #1 // found good input
	mov pc, lr

main:

	bl print
	mov r0, #0
	mov r7, #1
	swi 0

	error:  // error message and exit
		mov r0, #1
		ldr r1, =err
		mov r2, #43
		bl write

		
		mov r0, #1
		ldr r1, =flush
		mov r2, #1
		bl write

		mov r0, #0
		mov r7, #1
		swi 0

.data
err:
	.asciz "Input must be able to fit in 32 bit 2's compliment."
prompt:
	.asciz "Enter a decimal value (-2,147,483,648 to 2,147,483,647): \n"
choice:
	.asciz "Convert to hex, octal, or binary (h, o, b)? \n"
echoprompt:
	.asciz "Conversion value:  "
echochoice:
	.asciz "Conversion choice: "
flush:
	.asciz "\n"
outputWrite:
	.asciz "Your converted output: \n"
input:
	.space 11
inputChoice:
	.byte
output:
	.space 32
