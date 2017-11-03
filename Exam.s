	.arch  armv8-a
	.fpu   neon-fp-armv8
	.cpu   cortex-a53
	.syntax unified
	.global main

	.text
main:
	// Ask user for name of data file
	ldr  r0, =askname
	bl   printf

	// Read user input
	ldr  r0, =infmtf
	ldr  r1, =filename
	bl   scanf

	// Open the given file 
	ldr  r0, =filename
	ldr  r1, =rmode
	bl   fopen

	// Process the data in the file
	mov  r5, r0
	bl readFile
	mov  r4, r0 // Pointer to malloc
	mov  r6, r1 // Num items read
	mov  r7, r2 // Size of data

	// Close the file
	mov r0, r5
	bl fclose

	// Ask user for grid location and time
	ldr r0, =askloc
	bl printf
	ldr r0, =infmtStr
	ldr r1, =crimeLoc
	bl scanf

	ldr r0, =asktime
	bl printf
	ldr r0, =infmtStr
	ldr r1, =crimeTime
	bl scanf

	// Process data
	mov r0, r4
	mov r1, r6
	mov r2, r7
	bl findPotentialSuspects
	
	// End of program
	mov   r0, #0
	mov   r7, #1
	swi  #0

findPotentialSuspects:
	stmfd sp!, {r4, r5, r6, r7, r8, r9, r10, lr}
	// Parameters: r0 = mem location of strings, r1 = num strings, r2 = size of data
	mov r4, r0
	mov r5, r1
	mov r6, r2

	// ---------------------------------------
	// Extract time and distance


	// ---------------------------------------
	// Convert all the times to seconds
	mov r7, #0
	mov r8, r4 // current string to convert
	convertSecLoop:
		add r7, r7, #1
		cmp r7, r5
		bgt endConvert
 		
		mov r0, r8
		bl convertToSeconds

		add r8, r8, r6
		b convertSecLoop

	endConvert:
	// --------------------------------------
	// Find nearest crime times
	
	
	// --------------------------------------
	// Check if suspect could have reasonably done it
	// params:
	bl confirmSuspect
	// returns:

	// --------------------------------------
	// 		
	
	ldmfd sp!, {r4, r5, r6, r7, r8, r9, r10, lr}
	mov pc, lr	

confirmSuspect:
	// --------------------------------------
	// Compute distance

	// --------------------------------------
	// Compute time difference

	// --------------------------------------
	// Compute speed


convertToSeconds:
	stmfd sp!, {r4, r5, r6, r7, r8, r9, r10, lr}
	// r0 = mem address of string to convert
	

	ldmfd sp!, {r4, r5, r6, r7, r8, r9, r10, lr}
	mov pc, lr	
readFile:
	stmfd sp!, {r4, r5, r6, r7, r8, r9, r10, lr}
	// Parameters: r0 has result of fopen
	mov r10, r0
	mov r4, #0  // counter
	mov r9, #20 // data size

	countLoop:
		ldr  r1, =infmtLine
		mov  r2, sp	    // store on the stack
		sub  sp, sp, r9    
		bl   fscanf

		cmp  r0, #1 	  // fscanf read a line
		add  sp, sp, r9   // return stack to normal
		addeq r4, r4, #1  // increment

		beq  countLoop	  // loop again if stuff was read

	mul r0, r4, r9    // number of items we read * 20
	bl malloc

	mov r5, r0         // pointer to malloc'd area
	mov r6, r5	   // copy
	mov r7, #0
	
	
	// Go through the heap and store each string
	readLoop:
		mov r0, r10      // freshly opened file
		ldr r1, =infmtLine
		mov r2, r6
		bl fscanf	 // read current string into current malloc pointer
		
		add r7, r7, #1   // 20 byte string
		cmp r7, r4	 // end if we passed num of lines read
		bgt endRead

		add r6, r6, r9  // location to store next string
		b readLoop
 
	// At this point we should have the stack returned to normal
	// and malloc holding all our strings
	endRead:
		mov r0, r5 // malloc
		mov r1, r4 // number of strings
		mov r2, r9 // size of data
	// Returns: pointer to array of strings, number of items read, size of data
	ldmfd sp!, {r4, r5, r6, r7, r8, r9, r10, lr}
	mov pc, lr

	.data

askname:
	.asciz	"Please enter the name of your data file:\n"
askloc:
	.asciz  "Please enter the coordinates of the crime:\n"
asktime:
	.asciz  "Please enter the time of the crime:\n"

errormsg:
	.asciz  "Error.\n"

flushy:
	.asciz  "\n"

infmtf:
	.asciz  "%79s"

infmtn:
	.asciz  "%i"
infmtLine:
	.asciz  "%20s"
infmtStr:
	.asciz  "%11s"

outfmt:
	.asciz  "N = %i  Avg = %i\n"

filename:
	.space	80

rmode:
	.asciz  "r"

crimeLoc:
	.space 12
crimeTime:
	.space 12
