// Nicholas Ghobrial
// P1

.arch armv8-a
.cpu cortex-a53
.global main
.syntax unified

.text

main:
	// ---- write prompt
	mov r0, #1
	ldr r1, =prompt
	mov r2, #27
	bl write

	// ---- stdin
	mov r0, #0
	ldr r1, =input // 8 bytes
	mov r2, #8
	bl read

	// ---- process the input
	ldr r8, =input
	mov r0, #7  // starting index
	mov r1, #0  // ending index
	mov r2, #1  // hex multiplier, 1 -> 16 -> 256, etc.
	mov r7, #0  // running total

	loop:
		cmp r0, r1	// check end condition
		blt out		// break
		
		ldrb r3, [r8, r0] // one byte at a time from our input
		
		// check if result is 0-9
		sub r4, r3, #48
		cmp r4, #0
		blt error	// not a valid character
		cmp r4, #9	// if it's 0-9, it's valid
		ble valid 	// found

		// check if result is A-F
		sub r4, r3, #55 // A=65, so 65-55==10
		cmp r4, #10	// somewhere between 9 and A, invalid
		blt error
		cmp r4, #15	// if it's A-F (10-15) it's valid
		ble valid	// found      
		
		// check if result is a-f
		sub r4, r3, #87 // a=97, so 97-87==10
		cmp r4, #10	// somewhere between F and a
		blt error	
		cmp r4, #15	// a-f (10-15) is valid
		ble valid	// found		
		
		// letter out of bounds past f
		b error

	valid:  // found a valid char. add to sum and loop again
		mul r6, r4, r2  // our hex char * hex multiplier
		add r7, r7, r6  // add to our total
		mov r10, #16
		mul r2, r2, r10 // multiply hex multiplier

		sub r0, r0, #1  // decrement index and loop
		b loop		

	out: 
		// ---- get ready to process the output
		ldr r9, =output
		mov r0, #31 // starting index
		mov r5, #0  // ending index
		b bitloop
	
	bitloop:
		cmp r0, r5	// check if we hit 0
		blt done	// we're done

		and r1, r7, #1     // mask with 1 bit
		add r1, r1, #48    // convert back to ascii
		strb r1, [r9, r0]  // index is our offset
		lsr r7, #1	   // shift right for next time
		
		sub r0, r0, #1     // decrement and loop
		b bitloop

	done:
		mov r0, #1
		ldr r1, =message
		mov r2, #37
		bl write

		mov r0, #1
		ldr r1, =output
		mov r2, #32
		bl write

		mov r0, #1
		ldr r1, =newline
		mov r2, #1
		bl write

		mov r0, #0
		mov r7, #1
		swi 0

	error:  // error message and exit
		mov r0, #1
		ldr r1, =err
		mov r2, #43
		bl write

		
		mov r0, #1
		ldr r1, =newline
		mov r2, #1
		bl write

		mov r0, #0
		mov r7, #1
		swi 0

.data
err:
	.ascii "Input must be 8 characters [a-f][A-F][0-9]."
prompt:
	.ascii "Enter 8 characters of hex: "
message:
	.ascii "Your hex string converted to binary: "
newline:
	.ascii "\n"
input:
	.space 8
output:
	.space 32
