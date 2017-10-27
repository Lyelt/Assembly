// Nicholas Ghobrial
// P2

.arch armv8-a
.cpu cortex-a53
.global main
.syntax unified
.fpu neon-fp-armv8

.text

print:
	// ----Primpt prompt, echo input, convert, and print result
	// ----Parameters: input string, conversion choice
	mov r7, lr
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
	bl validateInput
	mov r9, r1  // store length of input
	mov r10, r2 // 1 if negative, 0 if positive
	cmp r0, #1  // Input is valid
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
bl convert
mov pc, r7

convert:
// ------ both choices have been validated
	stmfd sp!, {r7, fp, lr}

	//mov r11, lr
	ldr r0, =input // address of input string
	mov r1, r9     // num of digits
	mov r3, r10    // negative flag
	ldr r2, =inputChoice // x, o, b
	ldr r2, [r2]
	bl convertInput // r0 = addr of input string. r1 = length. r2 = conversion choice, r3 = negative flag

	mov r4, r0 // label result
	mov r5, r1 // length of output string

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

	mov r0, #1
	mov r1, r4
	mov r2, r5
	bl write // the converted string

	mov r0, #1
	ldr r1, =flush
	mov r2, #1
	bl write
		
	ldmfd sp!, {r7, fp, lr}
	mov pc, lr

convertInput:
	// ----Call the appropriate conversion function
	// ----Parameters: address of input string, length of input string, conversion choice, negative flag
	// ----Returns: addr of label containing output, string length
	stmfd sp!, {lr}

	bl convertToDecimal // convert the input string to a decimal number

	cmp r2, #120
	bleq convertToHex

	cmp r2, #111
	bleq convertToOctal

	cmp r2, #98 
	bleq convertToBinary

	ldmfd sp!, {lr}
	mov pc, lr

convertToHex:
	// ----Convert decimal value to hex string (8 chars)
	ldr r4, =hexString
	mov r5, #7 // start
	mov r6, #0 // end

	hexLoop:
		cmp r5, r6
		blt hexEnd
	
		and r3, r0, #15 // mask with 15
		cmp r3, #9
		addgt r3, r3, #55  // A-F ASCII
		addle r3, r3, #48 // 0-9 ASCII
		strb r3, [r4, r5]
		lsr r0, #4 // next 4 bits

		sub r5, r5, #1
		b hexLoop
	hexEnd:
		ldr r0, =hexString
		mov r1, #8
		mov pc, lr

convertToOctal:
	// ----Convert decimal value to octal string (11 chars)
	ldr r4, =octString
	mov r5, #10 // start
	mov r6, #0  // end

	octalLoop:
		cmp r5, r6
		blt octalEnd
		
		and r3, r0, #7 // mask with 7
		add r3, r3, #48 // ascii
		strb r3, [r4, r5]
		lsr r0, #3  // next three bits
		
		sub r5, r5, #1
		b octalLoop 
			

	octalEnd:
		ldr r0, =octString
		mov r1, #11
		mov pc, lr

convertToBinary:
	// ----Convert decimal value to binary string (32 chars)
	// ----r0: decimal input, r1: length
	ldr r4, =binString
	mov r5, #31 // start
	mov r6, #0  // end

	binaryLoop:
		cmp r5, r6
		blt binaryEnd // hit 0, we're done

		and r3, r0, #1  // mask digit with 1 bit
		add r3, r3, #48 // convert back to ascii
		strb r3, [r4, r5] 
		lsr r0, #1
		
		sub r5, r5, #1 // decrement and loop
		b binaryLoop

	binaryEnd:
		ldr r0, =binString
		mov r1, #32
		mov pc, lr

convertToDecimal:
	// ----Convert input string to 32-bit 2's compliment form
	mov r9, r3  // negative flag
	sub r10, r1, #1 // length of the input string - 1
	mov r3, #0  // ending index
	mov r4, #0  // running total
	mov r7, #1  // multiplier
	
	cmp r9, #1
	addeq r3, r3, #1 // dont try to include the negative sign when converting
	
	decimalLoop:
		cmp r10, r3 // have we hit the end
		blt negativeCheck
		
		ldrb r6, [r0, r10] // least significant digit to most
		sub r6, r6, #48 // Subtract ASCII 48 to get digit value
		mul r5, r6, r7  // mult by multiplier
		add r4, r4, r5  // add to running total
		mov r8, #10
		mul r7, r7, r8  // update multiplier

		sub r10, r10, #1
		b decimalLoop

	negativeCheck: 
		cmp r9, #1
		bne decimalEnd
		
		ldr r5, =#0xFFFFFFFF
		eor r4, r4, r5
		add r4, r4, #1

	decimalEnd:
		mov r0, r4
		mov pc, lr

validateInput:
	// ----Determine if the input string can be stored in 32-bit 2's compliment
	// ----Parameters: input string
	// ----Returns: 1 if input is valid, length of input string, 1 if negative
	stmfd sp!, {r4, r5, r6, r7, r8, lr}
	mov r4, r0 // save param
	mov r0, #1 // default: valid
	mov r8, #0 // default: positive
	mov r3, #0  // start
	mov r2, #11 // end
	charCheckLoop:
		cmp r3, r2
		bge checkLast // if we reached 11th byte check if it has data

		ldrb r1, [r4, r3] // each char in the input
		// if theres no data, end of input
		cmp r1, #10
		beq finalCheck
 
		// valid range is 0-9
		sub r5, r1, #48
		cmp r5, #0
		blt checkBadData // could be -
		cmp r5, #9
		bgt bad
		
		add r3, r3, #1 
		b charCheckLoop

	checkLast:
		ldrb r1, [r4, r3]
		cmp r1, #10 // if 11th byte isnt null, overflow
		bne bad
		b done
	
	checkBadData:
		// Any non-digit in non-first position is bad
		cmp r3, #0
		bne bad
		
		mov r6, #0
		// If its a - thats fine
		cmp r1, #45 // -
		moveq r8, #1
		bne bad

		// increment and loop
		add r3, r3, #1
		b charCheckLoop

	finalCheck:
		cmp r3, #10 // If there are exactly 10 digits
		beq checkOverflow // we have to check for overflow
		b done // Otherwise we're done

	checkOverflow:
		// smull and adds
		mov r2, #0 // end number
		mov r5, #1 // multiplier
		mov r6, #0 // running total

		overflowLoop:
			cmp r3, r2
			blt done

			ldrb r1, [r4, r3]
			sub r1, r1, #48
			smull r1, r4, r1, r5 // rdLo rdHi
			cmp r4, #0    	     // overflow in the high register
			bne bad
			adds r6, r6, r1	     // add to running total
			bvs bad		     // if overflow after adding
			
			sub r3, r3, #1
			b overflowLoop

	bad:	
		mov r0, #0 // found bad input
	
	done:
		mov r2, r8 // negative flag
		mov r1, r3 // number of valid chars we read
		ldmfd sp!, {r4, r5, r6, r7, r8, lr}
		mov pc, lr

validateChoice:
	// ----Determine if user entered valid choice (x, o, b)
	// ----Parameters: input char
	// ----Returns: 1 if input is valid
	mov r1, r0 // save param
	mov r0, #0 // default: false
	cmp r1, #120 // x
	beq good
	cmp r1, #111 // o
	beq good
	cmp r1, #98  // b
	beq good
	b end // if none matched, bad choice
	good:
		mov r0, #1 // found good input
	end:
		mov pc, lr

main:
	bl print
	mov r0, #0
	mov r7, #1
	swi 0

.data
prompt:
	.asciz "Enter a decimal value (-2,147,483,648 to 2,147,483,647): \n"
choice:
	.asciz "Convert to hex, octal, or binary (x, o, b)? \n"
echoprompt:
	.asciz "Conversion value:  "
echochoice:
	.asciz "Conversion choice: "
flush:
	.ascii "\n"
outputWrite:
	.asciz "Your converted output: "
	.align 1
inputChoice:
	.byte 0 
	.align 2
hexString:
	.space 8
octString:
	.space 11
binString:
	.space 32
output:
	.space 32
input:
	.space 11

