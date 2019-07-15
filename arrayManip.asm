TITLE arrayManip   (arrayManip.asm)

; Author: Justin Boyer
; Last Modified: 7/15/19
; OSU email address: boyerju@oregonstate.edu

; Description:  This program prints an unorganized list of random numbers from an array.
; It sorts the array and the prints the sorted array. The user specifies the number of elements randomly generated to the array.
;	Input: Takes a number in the set [10 .. 200]
;	Output: The unordered array followed by the ordered array
;	NOTE: This program requires the Irvine library to run (http://kipirvine.com/asm/)



INCLUDE Irvine32.inc
.386
;.model flat,stdcall
.stack 4096

;Constant definitions
MIN					EQU		10			;Min number accepted
MAX					EQU		200			;Max number accepted
HI					EQU		999			;Random number upper bound
LO					EQU		100			;Random number lower bound
NUMS_PER_LINE		EQU		10			;number of numbers to print on each line
ARRAY_POS_SIZE		EQU		4			;Array position is multiplied by this value. This value can be changed to fit the array type - byte 1, word 2, dword 4 etc

.data
;Introduction
	projectName		BYTE	"Random Numbers - This program will fill an array with random numbers and order it from high to low",0
	author			BYTE	"By: Justin Boyer", 0

;Get Data
	dataRequest		BYTE	"Enter the number of random numbers you would like to add.",0
	dataPrompt		BYTE	"Enter a number in [10 .. 200] : ",0
	request			DWORD	?	;Added by the user
	outOfRange		BYTE	"Entry out of range, thy again"

;Array
	list			DWORD	200 DUP (?)		
	ordered			BYTE	"Ordered Array:",0
	unordered		BYTE	"Unordered Array:",0

;Median
	printMedian		BYTE	"The Median is: ",0

;Goodbye
	thanks			BYTE	"Thanks for coming! Come again soon -Justin",0



.code

main PROC	
	CALL	Randomize		;random seed
	
	;Intro
	push	OFFSET author	
	push	OFFSET projectName
	CALL	Introduction
	
	;get data
	push	OFFSET request
	push	OFFSET dataPrompt
	push	OFFSET outOfRange	
	push	OFFSET dataRequest
	CALL	getData
	
	;fill the array with random numberbers
	MOV		eax,request
	
	push	OFFSET list
	push	request
	CALL	fillArray

	;To dispay push list address and count
	push	OFFSET	unordered
	push	OFFSET list
	push	request
	call	displayList

	;order the array
	push	OFFSET list
	push	request
	CALL	sortList

	;display the median
	push	OFFSET printMedian
	push	OFFSET list
	push	request
	call	displayMedian 
	
	;To dispay push list address and count
	push	OFFSET	ordered
	push	OFFSET list
	push	request
	call	displayList
	
	;goodbye
	push	OFFSET thanks
	CALL	goodbye

	exit	; exit to operating system
main ENDP

; (insert additional procedures here)

;Introduction Procedure
;This Procedure prints the intro strings to the console using the IrvineLibrary WriteString
;Pre: projectName [ebp+8] and author [ebp+12] pushed to stack
;Post: projectName and author are printed to the console
;Registers changed: EDX
Introduction	PROC
	push			ebp					;save the address stored in ebp so it can be retored when we return to main
	mov				ebp, esp			;adjust the stack base to esp for the duration of the procedure
	MOV		edx, [ebp+8]
	CALL	WriteString
	CALL	Crlf
	
	MOV		edx, [ebp+12]
	CALL	WriteString
	CALL	Crlf

	pop		ebp							;restore ebp back to the stack base for the program as a whole
	RET		8							;return address + 4 (the 2 addresses of the strings)
Introduction	ENDP


;getData Procedure
;This procedure asks the user for a number in the set [10 .. 200], and validates said number. It will loop until a number in range is provided
;Pre: address of dataRequest pushed to stack [ebp+8], address of outOfRange pushed to stack [ebp+12], address of dataPrompt pushed to stack [ebp+16]
;address of request pushed to stack [ebp+20]
;Post: request contains a user selected value in [10 .. 200]
;Registers changed: EDX, EAX
getData		PROC
	push			ebp					;save the address stored in ebp so it can be retored when we return to main
	mov				ebp, esp			;adjust the stack base to esp for the duration of the procedure

	MOV		edx, [ebp+8]
	CALL	WriteString
	CALL	Crlf
	JMP		getNum					;skip out of range message

tryAgain:							;If the number was not in range the loop back up to this point, including the out of range message
	MOV		edx, [ebp+12]
	CALL	WriteString
	CALL	Crlf

getNum:								;Ask for the number and get input
	MOV		edx,  [ebp+16]
	CALL	WriteString
	CALL	Crlf

	;get number in EAX
	CALL	ReadInt

	;validate
	CMP		eax, MAX
	JG		tryAgain

	CMP		eax, MIN
	JL		tryAgain

	;Load the number into the variable so it can be accessed later
	MOV		edx,  [ebp+20]			;The address of request is now in edx
	MOV		[edx], eax				;make the contents of eax the data of the address in edx

	POP		ebp
	RET		16						;4 items x4 = 16
getData		ENDP

;fillArray
;This procedure will fill an array with a specified number of random numbers
;pre: push the address of the array [ebp + 16], and push the value of request [ebp + 12] to the stack
;post: the array is filled with (request) number of random values
;registers changed:

	fillArray		PROC
	push			eax					;store the data from eax, so it can be restored later
	push			ebp					;save the address stored in ebp so it can be retored when we return to main
	mov				ebp, esp			;adjust the stack base to esp for the duration of the procedure
	mov				esi,[ebp+16]		;move the the address of the array to esi
	mov				ecx,[ebp+12]		;move the value of request to ecx (loop counter)

;everything is initialized, now start the array filling loop
arrayFill:
	call		getRando			;random number now in eax
	mov			[esi],eax			;place random number into the current position in the array
	add			esi, ARRAY_POS_SIZE	;increment the array to the next position
	loop		arrayFill			;decrement ecx (request)
	
	pop				ebp				;return to stack base
	pop				eax				;retore info from eax
	ret				8				;return plus pop the two DWORDS passed
	fillArray		ENDP


;getRando
;This procedure returns a pseudorandom number in the eax.
;This procedure uses RandomRange to return a number in the range specified by HI and LO global varialbles
;pre:none
;post:eax contains a pseudorandom number between LO and HI
;registers changed: eax

getRando		PROC
	mov			eax,HI				;move the global constant for the random ceiling to eax
	add			eax,1				;These 2 lines adjust the HI parameter so the desired result...
	sub			eax,LO				;...is between the specified low and hi
	call		RandomRange			;gets a number between 0 and the value in eax (non-inclusive)
	add			eax,LO				;add LO so that the number will not be below LO (thats why it was subtracted before calling RandomRange)
	ret								;value returned in eax
getRando		ENDP

;sortList Procedure
;This procedure will sort an unsorted array from hi to low.
;pre:push the address of the array [ebp + 16], and push the value of request [ebp + 12] to the stack
;post: The array will be sorted from high to low
;Registers affected: esi, eax, ebx, ecx

;define local variable
changeMade	EQU	DWORD PTR [ebp-4]

sortList	PROC
	push	ebp
	mov		ebp,esp
	sub		esp,4				;reserve space for changeMade flag
	mov		changeMade, 0		;Initialize changeMade flag to 0
	mov		ecx, [ebp + 8]		;ecx is the loop control - [ebp+8] is how many item to loop through
	mov		esi, [ebp+12]		;location of list (@list)

;bubble sort has 2 loops: inner loop cycles through the data (request) number of times, swapping items out of order
;The outer loop keeps looping through the data as long as at least one change was made
outerLoop:
	mov		changeMade, 0		;reset the flag to look for a change in the new loop
	mov		ecx, [ebp + 8]		;reset loop counter
	mov		esi, [ebp+12]		;reset location of list (@list)
	innerLoop:
		mov		eax,[esi]						;copy the array data into eax
		mov		ebx,esi							;copy the array address into ebx
		add		esi,4							;move esi to the next array element
		cmp		eax,[esi]						;compare the current and next array elements
		jge		continueInnerLoop				;We are ordering high to low, so eax should be > than [esi] - if not swap
		
		;if eax is less than [esi] then the values are swapped
		;push the two values to be swapped by reference 
		push	esi
		push	ebx
		call	swap
		mov		changeMade, 1					;if a swap is made, indicate so in the swap


	continueInnerLoop:
		loop	innerLoop			;if they are already in order, do nothing
		
	;Once we reach this pointer, ecx has reached 0 and the inner loop has finished one cycle
	;return to the outerloop and see if any changes were made
	;if yes, run through the inner loop again
	cmp		changeMade,0
	jne		outerLoop


	;after the outer loop terminates, the array is ordered high to low
	;clean up the stack and return to main
	mov		esp,ebp			;remove locals from the stack
	pop		ebp
	ret		8				; 4 - offset list, 4-count
	sortList		ENDP


;swap Procedure
;Swap the values of two passed array positions
;Pre: pushed the two addresses to swap values to the stack
;Post: values at those addresses are swapped
;Registers changed: esi,ebx,eax,edx

swap	PROC
	push			ebp					;save the address stored in ebp so it can be retored when we return to main
	mov				ebp, esp			;adjust the stack base to esp for the duration of the procedure
	mov				esi,[ebp+12]		;move the the address of the first value to esi
	mov				ebx,[ebp+8]			;move the the address of the second value to ecx
	mov				eax,[esi]			;[reg] to [reg] is not a valid move bc it is the same as mem to mem
	mov				edx,[ebx]			
	
	;swap the values
	mov				[esi],edx
	mov				[ebx],eax

	mov		esp,ebp			;remove locals from the stack
	pop		ebp
	ret		8				; 4 - offset list, 4-count
	swap	ENDP


;displayList Procedure
;This procedure displays the ints in an array
;pre: the address of the string indicating if the array is ordered or unordered[ebp+16], the address of the array start [ebp+12] and the count of elements[ebp+8] are pushed to the stack (Ebp+12 & ebp+8)
;post: The int contents are printed to the screen
;Registers changed: esi, ecx, eax, edx
;*From lecture video 20*

;define local variable
numbersInLine	EQU	DWORD PTR [ebp-4]

displayList		PROC
	push	ebp
	mov		ebp,esp
	sub		esp,4				;reserve space for numbersInLine counter
	mov		numbersInLine, 0	;Initialize numbersInLine counter to 0
	mov		esi, [ebp+12]		;location of list (@list)
	mov		ecx, [ebp+8]		;ecx is the loop control - [ebp+8] is count data
	mov		edx, [ebp+16]		;load the label into edx to print
	call	Crlf
	call	WriteString			;print the array label (ordered/unordered) to the console
	call	Crlf
more:
	mov		eax, [esi]		;get current element (data at the address in esi)
	;check if there are 10 numbers in the line already. If yes, start a new line
	cmp		numbersInLine, NUMS_PER_LINE		;if the number of numbers in the line equals the number of numbers allowed in a line, make a new line and reset the counter - otherwise skip to next step
	jne		WriteNext
	call	Crlf
	mov		numbersInLine, 0

WriteNext:	
	call	WriteDec		;write the current element of the array
	mov		eax,' '			;clear eax to add space between numbers
	call	WriteChar
	inc		numbersInLine	;increment the numbersInLine counter
	add		esi, 4			;get to next element
	loop	more
endMore:
	mov		esp,ebp			;remove locals from the stack
	pop		ebp
	ret		8				; 4 - offset list, 4-count
displayList		ENDP

;displayMedian Procedure
;This procedure will find the median (middle number) of an ordered set and print it to the screen.
;Finding the median is different for odd and even numbers. For odd numbers it is the value at position(x/2)+1 where x is the number of elements
;For an even number, it is the average of the values at positions x/2 and (x/2)+1
;Pre:List is ordered, address of label string pushed to stack [ebp+16], address of array bushed to stack [ebp+12], value of request pushed to stack[ebp+8]
;Post: Median displayed on the console, returned in eax
;Registers Changed: eax, edx, ebx
displayMedian		PROC
	push	ebp
	mov		ebp,esp
	mov		esi, [ebp+12]	;location of list (@list)
	mov		eax, [ebp+8]	;value of request is the dividend
	mov		edx, 0			;clear the edx for the remainder
	;First check if the value of request is even or odd
	mov		ebx,2			;divide by 2 and check for remainder
	div		ebx
	cmp		edx,0			;if the remainder is 0 then it is an even number
	je		EvenNum

	;if odd, find the value at the mid point (x/2)+1
	mov		ebx,ARRAY_POS_SIZE	
	mul		ebx					;multiply the midpoint by the size of the array values to get the distance from the array start
	add		esi,eax				;add the distance to the array address to get the position
	mov		eax,[esi]			;move the value in the chosen position to eax to print
	jmp		Midpoint

EvenNum:
	;find the average of x/2 (currently in eax) and (x/2)+1
	;first, get the value position x/2:
	sub		eax,1				;adjust the array index to account for 0
	mov		ebx,ARRAY_POS_SIZE	
	mul		ebx					;multiply array position (x/2) by the size of the array values to get the distance from the array start
	add		esi,eax				;add the distance to the array address to get the position
	mov		eax,[esi]			;move the value in the chosen position to eax
	add		esi,4				;move to the next position in the array
	mov		ebx,[esi]			;store the value in ebx
	add		eax,ebx				;sum the two values to prepare to get the mean
	mov		edx,0				;reset the edx for the remainder
	mov		ebx,2				;load ebx with the divisor
	div		ebx
	cmp		edx,0				;if there is a remainder, round up 
	je		Midpoint			;the unrounded value is loaded into eax and ready to print
	inc		eax					;add one if there was a remainder
	jmp		Midpoint			;the rounded value is loaded into eax and ready to print

Midpoint:						;The midpoint is found and value is loaded into eax, ready to print

	call	crlf
	call	crlf
	mov		edx,[ebp+16]
	call	WriteString
	call	WriteDec
	call	crlf
	pop		ebp
	ret		8				;2x4 = 8
displayMedian		ENDP

;goodbye Procedure
;This procedure prints the goodbye message
;Pre: thanks pushed to stack [ebp+8]
;Post: Goodbye message is printed to the screen
;Registers changed: EDX
goodbye		PROC
	push	ebp
	mov		ebp,esp
	call	CrLf
	mov 	edx, [ebp+8]
	call	CrLf
	call	WriteString
	call	CrLf
	pop		ebp
	ret		4	
goodbye		ENDP




END main
