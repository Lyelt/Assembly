	.arch  armv8-a
	.fpu   neon-fp-armv8
	.cpu   cortex-a53
	.syntax unified
	.global main

	.text

userInput:
	stmfd sp!, {r4, r5, r6, lr}

	ldr r0, =picPrompt
	bl printf

	ldr r1, =file1
	ldr r0, =infmt1
	bl scanf

	ldr r0, =msgPrompt
	bl printf

	ldr r1, =file2
	ldr r0, =infmt1
	bl scanf

	ldmfd sp!, {r4, r5, r6, lr}
	mov pc, lr

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
// Parameters: r0 = filename
//	       r1 = new image to write
writeimage:
	stmfd sp!, {r4,r5,r6,r7,lr}

	mov  r7, r1     // location of new image
	ldr  r1, =wmode // "w"
	bl   fopen	// open file for writing
	mov  r4, r0     // addr of open file

	ldr  r1, =outfmt1 // write the code
	ldr  r2, =code
	bl   fprintf
	
	mov  r0, r4	  // write the width and height
	ldr  r1, =outfmt2
	ldr  r2, =width
	ldr  r2, [r2]
	ldr  r3, =height
	ldr  r3, [r3]
	bl   fprintf

	mov  r0, r4	   // write the max val
	ldr  r1, =outfmt3
	ldr  r2, =maxval
	ldr  r2, [r2]
	bl   fprintf	  

	ldr  r2, =width    // calculate image size
	ldr  r2, [r2]
	ldr  r3, =height
	ldr  r3, [r3]
	mul  r6, r2, r3

	mov  r0, r7 // location of new image data
	mov  r1, #1 // 1 byte each
	mov  r2, r6 // image size
	mov  r3, r4 // location of open file
	bl   fwrite

	mov  r0, r4
	bl   fclose

	ldmfd sp!, {r4,r5,r6,r7,lr}
	mov  pc, lr

// ------------------------------------------------------------------------------------
// Parameters: r0 = address of original image
//             r1 = address of encrypted message
//             r2 = length of message in bytes
//             r3 = key value of cipher

hideMessage:
	stmfd sp!, {r4,r5,r6,r7,r8,r9,r10,r12,lr}

	mov  r4, r0 // address of original image
	mov  r7, r1 // address of encrypted message
	mov  r8, r2 // length of message in bytes
	mov  r9, r3 // key value of cipher
	mov r10, #0 // cursor for current position in image

	// Calculate total space needed
	ldr  r2, =width
	ldr  r2, [r2]
	ldr  r3, =height
	ldr  r3, [r3]
	mul  r5, r2, r3
	// Allocate space for the new image
	mov  r0, r5
	bl   malloc
	mov  r6, r0
	
	mov r0, r8
	mov r1, #4 // 4 bytes in message length
	bl hide    // Hide message length

	mov r0, r9
	mov r1, #1 // 1 byte in key value
	bl hide
	
	mov r12, #0
	messageLoop:
		ldrb r0, [r7, r8] // process the hidden message one byte at a time
		mov r1, #1
		bl hide

		add r12, r12, #1
		cmp r12, r8     // end of hidden message
		bge doneHide

		b messageLoop

// ---------------------------------------------------------------------------------
// Parameters: r0 = data to hide
//             r1 = size of data in bytes
// 
hide:
	// r0 contains the data
	// r1 contains the number of times to loop (ie. number of bytes)
	// r4 will be addr of original image (global)
	// r6 will be addr of new image (global)
	// r10 will be cursor (global) 
	stmfd sp!, {r5, r7, r8, r9, r12, lr}
	
	outer:
		subs  r1, r1, #1 // Loop as many times as necessary
		blt return

		mov r5, #4 // will go through each byte 4 times 
	
	// Loop through each byte, two bits at a time
	inner:
		subs r5, r5, #1
		blt outer
		
		ldrb r7, [r4, r10]  // current byte in original image
		
		bfi r7, r0, #0, #2  // replace bits 0-2
		lsr r0, r0, #2	    // shift 2 bits
		
		strb r7, [r6, r10]  // store to new image

		add r10, r10, #1 // next byte in the image
		b inner

	return:
		ldmfd sp!, {r5, r7, r8, r9, r12, lr}
		mov pc, lr


doneHide:
	// write the rest of the image without any hidden message
	sub r10, r10, #1
	finishLoop:
		add r10, r10, #1 // image cursor
		cmp r10, r5     // size of image
		bgt beginWrite

		ldrb r7, [r4, r10]
		strb r7, [r6, r10]
		b finishLoop
beginWrite:
	
	ldr  r0, =outMsg
	bl   printf

	ldr  r0, =sizeMsg
	mov  r1, r8
	bl   printf

	ldr  r0, =keyMsg
	mov  r1, r9
	bl   printf

	ldr  r0, =file3
	mov  r1, r6
	bl   writeimage

	ldr  r0, =syscomm
	bl   system
	
	mov  r0, r6
	bl   free
 
	ldmfd sp!, {r4,r5,r6,r7,r8,r9,r10,r12,lr}
	mov  pc, lr

// ------------------------------------------------------------------------------------
// Parameters: r0 = address of filename location
//	       r1 = size of image in bytes
// Returns:    r0 = address of message
//	       r1 = size of message in bytes
readHiddenMessage:
	stmfd sp!, {r4, r5, r6, r7, r8, r9, lr}

	// filename in r0
	// image size in r1
	mov r4, r0
	mov r6, #4
	udiv r6, r1, r6 // Max number of bytes for message
	mov r0, r6  
	bl malloc     // calloc to set all to 0
	mov r5, r0    // result of calloc

	// open file for read
	mov  r0, r4
	ldr  r1, =rmode
	bl   fopen
	// fscanf for contents of file
	ldr r1, =infmt1
	mov r2, r5
	bl fscanf

	mov r8, #0
	sizeLoop:
		cmp r8, r6 // check for overflow
		bgt error
		
		ldrb r9, [r5, r8] // each byte in the malloc'd area
		cmp r9, #0	  // if it's zero, end of message
		beq returnSize

		add r8, r8, #1 
		b sizeLoop 

	returnSize:
		mov r0, r5 // return address of message
		mov r1, r8 // return number of bytes read
		ldmfd sp!, {r4, r5, r6, r7, r8, r9, lr}
		mov pc, lr

// ---------------------------------------------------------------------
// Parameters: r0 = address of message 
//             r1 = length of message
// Returns:    r0 = address of message after encryption
//	       r1 = encryption key value
encryptMessage:
	stmfd sp!, {r4, r5, r6, r7, r8, r9, r10, lr}
	mov r5, r0
	mov r0, #0
	bl time
	bl srand
	bl rand
	mov r7, #127
	ands r4, r0, r7 // mod 127

	mov r7, #0
	mov r0, r5
	encryptLoop:
		cmp r7, r1
		bgt endEncrypt

		ldrb r5, [r0, r7] // original byte
		add r5, r5, r4    // key
		cmp r5, #127
		subgt r5, r5, #128
		strb r5, [r0, r7] // store back

		add r7, r7, #1
		b encryptLoop

	endEncrypt:
		mov r1, r4		
		ldmfd sp!, {r4, r5, r6, r7, r8, r9, r10, lr}
		mov pc, lr

// ---------------------------------------------------------------------

main:
	// User inputs name of image and file
	bl userInput
	// Read the original image
	ldr  r0, =file1
	bl   readimage
	
	mov  r4, r0 // result of malloc
	mov  r5, r1 // file size

	ldr  r0, =file2 // filename
	mov  r1, r5 	// bytes allocated for image

	// Read the hidden message
	bl readHiddenMessage
	// r0 contains result of malloc
	// r1 contains size of message
	mov r6, r0
	mov r7, r1
	// Encrypt the message with a cipher
	bl encryptMessage
	// r0 contains message after encryption

	// mov r1, r0
	// Hide message in the image and write it out
	mov  r3, r1 // r1 would have encryption key
	mov  r2, r7   // size of message to hide
	mov  r1, r6   // address of message
	mov  r0, r4   // address of image read
	
	bl   hideMessage 

	mov  r0, r4
	bl   free

	mov  r0, r6
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

syscomm:   
	.asciz  "gpicview steg.pgm"
file1:
	.space 80
file2:
	.space 80
file3:
	.asciz	"steg.pgm"
picPrompt:
	.asciz "Please enter the name of the image: \n"
msgPrompt:
	.asciz "Please enter the file containing the message to hide: \n"
outMsg:
	.asciz "Your file can be found in steg.pgm\n"
sizeMsg:
	.asciz "Message size: %i bytes\n"
keyMsg:
	.asciz "Cipher key: %i\n"
errorMsg:
	.asciz  "Something went wrong.\n"
flushy:
	.asciz  "\n"
infmt1:
	.asciz  "%s"
infmt2:
	.asciz	"%i %i"
infmt3:
	.asciz	"%i"
outfmt1:
	.asciz  "%s\n"
outfmt2:
	.asciz	"%i %i\n"
outfmt3:
	.asciz	"%i\n"
rmode:
	.asciz  "rb"
wmode:
	.asciz  "wb"
code:
	.space 3
	.align 2
width:
	.word 0
height: 
	.word 0
maxval:
	.word 0
