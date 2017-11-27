	.arch  armv8-a
	.fpu   neon-fp-armv8
	.cpu   cortex-a53
	.syntax unified
	.global main

	.text

readimage:
	stmfd sp!, {r4,r5,r6,lr}
	// filename in r0
	// open file for read
	ldr  r1, =rmode
	bl   fopen
	// store result in r4
	mov  r4, r0

	// read code
	ldr  r1, =infmt1
	ldr  r2, =code
	bl   fscanf
	
	// read height and width
	mov  r0, r4
	ldr  r1, =infmt2
	ldr  r2, =width
	ldr  r3, =height
	bl   fscanf
	
	// read max val
	mov  r0, r4
	ldr  r1, =infmt3
	ldr  r2, =maxval
	bl   fscanf

	ldr  r2, =width
	ldr  r2, [r2]
	ldr  r3, =height
	ldr  r3, [r3]
	mul  r6, r2, r3
	
	// allocate the required amount of bytes
	mov  r0, r6
	bl   malloc

	// read contents of the image into the allocated space
	mov  r5, r0
	mov  r1, #1
	mov  r2, r6
	mov  r3, r4
	bl   fread
	// close the file
	mov  r0, r4
	bl   fclose
	// return the result of malloc
	mov  r0, r5
	mov  r1, r6
	ldmfd sp!, {r4,r5,r6,lr}
	mov  pc, lr

// ----------------------------------------------------------------------------
// Parameters: r0 = address of message
//	       r1 = length of message
//             
writefile:
	stmfd sp!, {r4,r5,r6,r7,lr}
	
	mov r5, r0
	mov r6, r1

	ldr r0, =file2
	ldr r1, =wmode
	bl fopen
	mov r4, r0

	mov r7, #0
	writeLoop:
		mov r0, r4
		ldr r1, =infmt3
		ldr r2, [r5, r7]
		bl fprintf

		add r7, r7, #1
		cmp r7, r6
		bge doneWrite
		b writeLoop

	doneWrite:
		mov r0, r4
		bl fclose

	ldmfd sp!, {r4,r5,r6,r7,lr}
	mov  pc, lr

// ---------------------------------------------------------------------------------
// Parameters: r0 = location to store extracted data
//             r1 = size of data to extract in bytes
// 
extract:
	// r0 contains the data area
	// r1 contains the number of times to loop (ie. number of bytes)
	// r4 will be addr of original image
	// r10 will be cursor for original image
	stmfd sp!, {r5, r7, r8, r9, r12, lr}
	
	outer:
		mov r5, #0  // one byte's info is hidden across 4 bytes
		mov r8, #0  // clear the register we'll store the current byte in
		subs r1, r1, #1
		blt return  // return if we extracted the proper number of bytes
		b inner
	
	// Loop through each byte, two bits at a time
	inner:
		cmp r5, #4	     // loop 4 times per byte
		strbge r8, [r0, r1]  // if we're done with the inner loop, store the byte
		bge outer
		
		ldrb r7, [r4, r10]   // current byte in original image
		
		ubfx r9, r7, #0, #2  // extract bits 0-2
		mov  r11, #2
		mul  r11, r5, r11    // shift based on current position in the byte
		lsl  r9, r9, r11 
		orr  r8, r8, r9	     // OR extracted bits 

		add r10, r10, #1
		add r5, r5, #1
		b inner

	return:
		ldmfd sp!, {r5, r7, r8, r9, r12, lr}
		mov pc, lr

// ------------------------------------------------------------------------------------
// Parameters: r0 = address of image data location
//	       r1 = size of image in bytes
// Returns:    r0 = address of message
//	       r1 = size of message
extractHiddenMessage:
	stmfd sp!, {r4, r5, r6, r7, r8, r9, lr}
	mov r10, #0 // cursor for image reading
	mov r4, r0  // address of original image

	mov r6, #4
	udiv r6, r1, r6 // Max number of bytes for message
	mov r0, r6  
	bl malloc       // allocate space for the message
	mov r5, r0

	// extract the number of chars
	ldr r0, =size // address to read into
	mov r1, #1 //#4    // number of bytes to read
	bl extract    

	ldr r0, =key  // extract the key value
	mov r1, #1
	bl extract

	ldr r7, =size
	ldr r7, [r7] // number of chars in the message

	extractLoop:
		subs r7, r7, #1
		cmp r7, #0
		blt doneExtract    // end of message

		//ldrb r0, [r5, r7]  // location to read into
		add r0, r5, r7
		mov  r1, #1 	   // one byte at a time
		bl extract

		b extractLoop

	doneExtract:
		mov r0, r5 // return address of message
		ldr r1, =size
		ldr r1, [r1] // return size of message
		ldmfd sp!, {r4, r5, r6, r7, r8, r9, lr}
		mov pc, lr

// ---------------------------------------------------------------------
// Parameters: r0 = address of message 
//             r1 = length of message
// Returns:    r0 = address of message after encryption
//	       
decryptMessage:
	stmfd sp!, {r4, r5, r6, r7, r8, r9, r10, lr}
	
	ldr r4, =key
	ldr r4, [r4]

	mov r7, #0
	decryptLoop:
		cmp r7, r1
		bgt endDecrypt

		ldrb r5, [r0, r7] // original byte
		sub r5, r5, r4    // key
		cmp r5, #0
		addlt r5, r5, #128
		strb r5, [r0, r7] // store back

		add r7, r7, #1
		b decryptLoop

	endDecrypt:		
		ldmfd sp!, {r4, r5, r6, r7, r8, r9, r10, lr}
		mov pc, lr

// ---------------------------------------------------------------------

main:
	// User inputs name of image and file
	// bl userInput
	// Read the original image
	ldr  r0, =file1
	bl   readimage
	
	mov  r4, r0 // result of malloc
	mov  r5, r1 // file size

	bl extractHiddenMessage
	mov  r5, r0 // second result of malloc

	bl decryptMessage
	bl writefile

	mov  r0, r4
	bl   free

	mov  r0, r5
	bl   free
 
	mov   r0, #0
	mov   r7, #1
	svc  #0

error:
	ldr r0, =errorMsg
	bl printf

	mov r0, #0
	mov r7, #1
	svc #0

	.data
file1:
	.asciz	"stego.pgm"
file2:
	.asciz	"steg.txt"

errorMsg:
	.asciz  "Something went wrong.\n"
flushy:
	.asciz  "\n"
infmt1:
	.asciz  "%s"
infmt2:
	.asciz	"%i %i"
infmt3:
	.asciz	"%c "
outfmt1:
	.asciz  "%s\n"
outfmt2:
	.asciz	"%i %i\n"
outfmt3:
	.asciz	"%i\n"
rmode:
	.asciz  "rb"
wmode:
	.asciz  "w"
code:
	.space 3
	.align 2
width:
	.word 0
height: 
	.word 0
maxval:
	.word 0
	.align 1
key:
	.byte 0
size:
	.byte 0 //.word 0
