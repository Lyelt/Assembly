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
	mov pc, lr

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
	mov r0, #1
	mov pc, lr

validateChoice:
	// ----Determine if user entered valid choice (h, o, b)
	// ----Parameters: input char
	// ----Returns: 1 if input is valid
	mov r0, #1
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
	.space 10
inputChoice:
	.byte
output:
	.space 32
