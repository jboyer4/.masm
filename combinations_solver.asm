TITLE Combinations Solver     (combinations_solver.asm)

; Author: Justin Boyer
; Last Modified: 7/15/19
; OSU email address: boyerju@oregonstate.edu

; Description:  This is a combinations problem HW helper. It provides a combinations problem and asks the user for their answer.
;	The program will inform the user if their answer is correct or not.
;	NOTE1: This program requires the irvine library to run (see http://kipirvine.com/asm/)
;	NOTE2: This program reads user input as a string and converts the ascii charecters to ints for the mathmatical functions. 
;		The readInt function from the Irvine library makes this unnecessary, but I wrote this program this way to showcase ascii manipulation skills

INCLUDE Irvine32.inc

;Constant definitions:
SET_MIN				EQU		3
SET_MAX				EQU		12
SELECT_MIN			EQU		0
INPUT_MAX			EQU		9
PLACE_MULTIPLIER	EQU		10


;mWrite will print a string to the console - source class lecture
;buffer is the string you wish to print
;MACROS
	mWrite	MACRO	buffer
		push		edx
		mov			edx, buffer
		call		WriteString
		pop			edx
	ENDM

	mNumber	MACRO	num
		push		eax
		mov			eax, num
		call		WriteDec
		pop			eax
	ENDM

.data
;Introduction 
	intro			BYTE	"Programming Assignment 6B: Stats HW Helper",0
	author			BYTE	"By: Justin Boyer",0
	instructions1	BYTE	"I will present you with a randomly generated combinations problem.",0
	instructions2	BYTE	"Enter your answer and I will tell you if you got it right!",0
;generate problem
	numInSet		DWORD	? ;NUmber of elements in the set - will be randomly generated for each problem
	elemChosen		DWORD	? ;Number of elements chosen from the set - will be randomly generated for each problem
	problemtxt		BYTE	"Problem: ",0
	inSettxt		BYTE	"Number of elements in the set: ",0
	choosetxt		BYTE	"Number of elements to choose from the set: ",0
;getData
	strAnswer		BYTE	INPUT_MAX+1 DUP (?)		;Unser input. Will need to be converted to a decimal number
	decAnswer		DWORD	0						;initialize to 0
	enterAnswer		BYTE	"Enter your answer:",0
	invalid			BYTE	"Invalid input - Please enter an unsigned integer",0
;combinations
	result			DWORD	0
;showResults
	thereAre		BYTE	"There are ",0
	combinationsOf	BYTE	" combinations of ",0
	items			BYTE	" items from a set of ",0
	correct			BYTE	"Correct! Good Job!",0
	tryAgain		BYTE	"Try again",0
;goAgain
	goAgain			BYTE	"Would you like to try again? (y/n)"
	againAns		BYTE	?
	goodbye			BYTE	"Goodbye",0
	yOrN			BYTE	"Please enter y or n",0

.code
main PROC
	
	call		Randomize		;random seed
	
	;INTRO
		push		OFFSET	intro
		push		OFFSET	author
		push		OFFSET	instructions1
		push		OFFSET	instructions2
		call		Introduction
restart:	
	;GENERATE PROBLEM
		push		OFFSET	numInSet
		push		OFFSET	elemChosen
		call		showProblem
	;GET DATA
		push		OFFSET	strAnswer
		push		OFFSET	decAnswer
		call		getData

	;COMBINATIONS
		push		numInSet
		push		elemChosen
		push		OFFSET	result
		call		combinations
	
	;SHOW RESULTS
		push		numInSet
		push		elemChosen
		push		decAnswer
		push		result
		call		showResults

	;GO AGAIN?
	getYN:
		call		crlf
		mWrite		OFFSET goAgain
		call		ReadChar			;char in AL
		
		;n or N to exit
		cmp			AL,110
		je			exitProgram
		cmp			AL,78
		je			exitProgram

		;y or Y to go again
		cmp			AL, 121
		je			restart
		cmp			AL, 89
		je			restart

		mWrite		OFFSET yOrN
		jmp			getYN

	;GOODBYE
exitProgram:
	mWrite	OFFSET goodbye
	exit
main ENDP





;;;FUNCTIONS BELOW;;;

;Introduction PROC
;This proc introduces the program, the author, and the instructions
;Pre: push the required string addresses to the stack: intro [ebp+16], author [ebp+12], instructions[ebp+8]
;Post: the introduction is displayed to the console
;Registers changed: None, all registers are restored

Introduction PROC
	push		ebp
	mov			ebp, esp

	mWrite		[ebp+20]
	call		crlf
	mWrite		[ebp+16]
	call		crlf
	call		crlf
	mWrite		[ebp+12]
	call		crlf
	mWrite		[ebp+8]
	
	pop			ebp
	ret			16			;return address + 4 * (4 string addresses)
Introduction	ENDP

;getRando
;This procedure takes a variable address and fills it with a pseudorandom number.
;pre:Push the address of the variable you wish to fill with a random number [ebp+24], as well as the min [ebp+16] and max [ebp+20] ranges for the number
;post:passed address has a psuedorandom number between min and max
;registers changed: None eax is used and restored

getRando		PROC
	push	eax						;need eax for call RandomRange
	push	ebx
	push	ebp
	mov		ebp,esp
	
	mov			eax,[ebp+20]		
	add			eax,1				;max on RandomRange in non-inclusive, so add 1
	
	sub			eax,[ebp+16]		;subtracting the min now will allow us to adjust the min after we get the random number and offset it from 0 if necessary

	call		RandomRange			;gets a number between 0 and the value in eax (non-inclusive)
	add			eax,[ebp+16]		;Add the min back in to offset the min from 0 if applicable

	;now add the number from eax into the address passed
	mov			ebx, [ebp+24]		;the passed variable address now is in ebx
	mov			[ebx], eax			;set the value held at the address in ebx to the value in eax
	
	pop		ebp
	pop		ebx
	pop		eax
	ret		12	

getRando		ENDP

;showProblem proc
;This Program generates 2 random numbers and creates a new problem to solve
;Pre: push the addresses of the numInSet [ebp+16] and elemChosen[ebp+12]
;Post: The practice problem is displayed on the console
;Registers changed: None
showProblem		PROC
		push	eax
		push	ebp
		mov		ebp,esp
		
		call		crlf
		mWrite		OFFSET problemtxt
		call		crlf

		;Elements in set: 
			mWrite		OFFSET inSettxt	
			;Get Random values
				push		[ebp+16]	;variable to fill with random value
				push		SET_MAX
				push		SET_MIN
				call		getRando
			mNumber		numInSet
			call		crlf

		;Elements to choose from the set
			mWrite		OFFSET choosetxt
				push		[ebp+12]					;variable to fill with random value
				mov			eax, [ebp+16]				;get the value to pass, not the address
				push		[eax]						;The maximum number of elements possible to choose is the number of elements in the set
				push		SELECT_MIN					;minimum number of elements to select defaults to 0
				call		getRando
			mNumber		elemChosen
			call		crlf
	pop		ebp
	pop		eax
	ret		8
showProblem		ENDP



;getData	proc
;This procedure reads a string in from the user and passes it to the validation function
;It returns a number in a passed variable address
;Pre: pass the address to hold the string version of the answer [ebp+40] and the address to hold the decimal conversion [ebp+36]
;Post:decAnswer contains a validated answer to check againts the computed answer
;Registers changed: none

getData		PROC
	pushad
	mov		ebp,esp
	jmp		getString	;skip invalidString for now - it is the restart point if there is invalid input

invalidString:
	call	crlf
	mWrite	OFFSET	invalid
	call	crlf

getString:
	mWrite	OFFSET enterAnswer
	mov		edx, [ebp+40]			;The string OFFSET is now in edx
	mov		ecx, INPUT_MAX
	call	ReadString				;string is saved in the address at edx 
	mov		ecx,eax					;move the string length to the counter register
	call	crlf
	mov		esi, [ebp+40]			;move the input sting to the array process reg

	cld								;clear the direction flag
	mov		ebx,[ebp+36]			;load the address to store the int into
	mov		eax,0					;initialize the decAnswer to 0
	mov		[ebx],eax

	;now we have the string input at the address in edx we need to validate and get a decimal to add to the running total
getChar:
	;multiply current total by 10 to make room for next digit
	
	
	mov		eax,10					;load 10 in the register so it can be multiplied by the memory
	mov		edx,[ebx]
	mul		edx						;multiply the value at the address at ebx by 10
	mov		[ebx],eax				;move the multiplied value into memory
	
	;get the next char and validate it
	mov		eax,0					;make sure eax is reset so it doesn't mess up AL
	lodsb							;load next char into AL
	call	charToInt				;eax now contains the int value of the passed char
	cmp		eax,10					;10 is not a valid digit so if eax contains 10 it is not a valid digit
	jge		invalidString			;get a new string if the current one is invalid (not a number)

	;if the char is valid, add it to the running total
	add		[ebx],eax

	loop getChar

	popad
	ret		8
getData		ENDP

;charToInt
;This function changes a char to an int and validates that the passed char is an int.
;pre: lead eax with th char
;post: eax contains the char as an int if possible. Non int chars will return 10
;Registers changed: EAX - this proc converts the char contents of eax to int (or 10 if not valid int)
charToInt	PROC
	;ints have char values between 48 and 57
	cmp		eax,48			;check if it is above 48
	jl		invalidChar
	cmp		eax,57			;check if above 57
	jg		invalidChar

	sub		eax,48			;if it is in range, then subtract 48 to get the char as an int
	jmp		converted

invalidChar:				;assign invalid charsthe value 10
	mov		eax,10
converted:
	ret
charToInt	ENDP



;Factorial	PROC
;This procedure uses recursion to fin the factorial of a passed number.
;pre: Push the running total (initialized to 1)[ebp+8], and the value to multiply by [ebp+12]
;post: the factorial of the number passed is stored in eax
;Registers changed:eax, ebx
Factorial	PROC
	push	ebp
	mov		ebp,esp


	mov		ebx,[ebp+8]				;next number to multiply by
	mov		eax,[ebp+12]			;running total
	cmp		ebx,1					;Base Case: factorial is finished
	jle		finished

recurse:							;recursive case
	mul		ebx						;mul the running total by the next number
	dec		ebx						;decrement the number to multiply by to get the next number
	push	eax						;push running total
	push	ebx						;push the next number to multiply by
	call	Factorial

finished:
	pop		ebp
	ret		8
Factorial	ENDP


;Combinations PROC
;This proc takes recursevly solves the combinations problem using n!/(r!(n-r)!) where n is numsInSet and r is elemChosen and stores the result in the result variable
;pre: push the value for the numInSet [ebp+44], elemChosen [ebp+40], and the address to store the reult in [ebp+36]
;post: the answer to the problem is stored in the result variable
;registers changed: none

combinations		PROC

;define local variable
FactorialAns		EQU	DWORD PTR [ebp-4]
denominator			EQU	DWORD PTR [ebp-8]


	pushad
	mov		ebp,esp
	sub		esp,8					;reserve space for local variables

	;(n-r)
	mov		eax,[ebp+44]
	mov		ebx,[ebp+40]
	sub		eax,ebx

	;(n-r)!
	mov		FactorialAns,1			;initialize to total to 1 for the recursive function
	push	FactorialAns			;push the location to store the answer
	push	eax						;push the value to find the factorial of
	call	factorial	
	mov		denominator,eax			;put the value of (n-r)! into the denominator

	;r!
	mov		FactorialAns,1			;initialize to total to 1 for the recursive function
	push	FactorialAns			;push the location to store the answer
	mov		ebx,[ebp+40]
	push	ebx						;push the value to find the factorial of (r)
	call	factorial	

	;r!(n-r!)	r! is stored in eax and (n-r)! is stored in the denominator
	mul		denominator
	mov		denominator,eax
	cmp		eax,0
	jne		getN					;If the denominator is zero (r = 0 or r = n) then there are n possibilities
	mov		eax,[ebp+44]				;prepare to load n into the answer
	jmp		loadAnswer

getN:
	;n!
	mov		FactorialAns,1			;initialize to total to 1 for the recursive function
	push	FactorialAns			;push the location to store the answer
	mov		ebx,[ebp+44]
	push	ebx						;push the value to find the factorial of (n)
	call	factorial
	
	;n!/(r!(n-r)!)	n! is stored in eax, r!(n-r!) is stored in the denominator
	mov		edx,0					;clear for remainder
	div		denominator

loadAnswer:
	;load the address to store the result in
	mov		ebx,[ebp+36]
	mov		[ebx],eax

	mov		esp,ebp					;remove locals from the stack
	popad
	ret		12
	combinations	ENDP



;showResults	PROC
;This procedure checks the inputed answer vs the correnct answer and reports the results to the user
;pre: push the computed answer result[ebp+36], the the user's answer decAnswer[ebp+40], elemChosen[ebp+44], numInSet[ebp+48]
;post: Print to the console if the user got the answer right or not
;Registers changed: None
showResults		PROC
	pushad
	mov		ebp,esp

	mWrite	OFFSET thereAre
	mNumber	[ebp+36]
	mWrite	OFFSET combinationsOf	
	mnumber	[ebp+44]
	mWrite	OFFSET items
	mNumber	[ebp+48]
	call	crlf
	
	mov		eax,[ebp+40]	;load the user answer into the eax to compare it to the result
	cmp		eax,[ebp+36]
	je		correctAnswer	;If the are equal, the answer is correct
	mWrite	OFFSET tryAgain
	jmp		endOfShowResults
correctAnswer:
	mWrite	OFFSET correct
endOfShowResults:
	popad
	ret		16
showResults		ENDP


END main
