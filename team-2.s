#Big Brother Calculator
#Program allows user to enter upto 5 floating point numbers, then perform calculations according to user's choice
#and repeat them as many times the user wants to. Then print out the maximum number out of the entered ones. 
# Useful constants - reusable read only data constants
		.equ    	STDIN,0 
        .equ		STDOUT,1 
        .equ    	READ,0 
        .equ    	WRITE,1 
        .equ    	EXIT,60 
# Stack frame cosntants
        .equ   	promptOffset,-56
        .equ		menuOffset, -48
        .equ    	localSize,-88
		
# Strings for message output
.section .rodata	
prompt:	
		.string "\nPlease input number of floats you would like to enter (min of 2 and max of 5): "
		.equ promptSz, .-prompt-1
menuPrompt:
		.string "\nChoose one option\n1. Addition\n2. Subtraction\n3.Multiplication\n4. Division\nor any key to quit program: "
		.equ menuPromptSz, .-menuPrompt-1
inputPrompt:
		.string "\nEnter your floating point values (8 characters maximum): "
		.equ inputPromptSz, .-inputPrompt-1
peerror:
		.string "You have a precision error.\n"
		.equ peerrorSz, .-peerror-1
inerr:
		.string "\nYou entered less than 2 or more than 5 numbers."
		.equ inerrSz, .-inerr-1
numerr:
		.string "\nYou entered something other than numbers or did not enter a floating point number. \nEnter again:"
		.equ numerrSz, .-numerr-1
result:
		.string "\nYour result is: "
		.equ resultSz, .-result-1
maxResult:
		.string "\nMaximum number is: "
		.equ maxResultSz, .-maxResult-1	
period:
		.string ".\n"
		.equ periodSz, .-period-1
diverrormsg:
		.string "You cannot divide by zero.\n"
		.equ	diverrormsgSz, .-diverrormsg-1
		
# Writable variable data
.data
		inputAmount: .long 0		# the amount of numbers to input stored 
		offsetAmount: .long 0
		maxIndex: .long 0
		mulfactor: .long 0
		negativeFlag: .long 0
		mulfactor1: .float 100000000
		oneflag: .float 1
		div:	.float 10
		flag:	.long 0
		deccount: .long 0
		initialize: .float 0
		negflag: .long 0
		
#Main code
.text
.globl _start

_start:
		pushq	%rbp											#setting up call stack
		movq	%rsp, %rbp
		addq 	$localSize, %rsp
		
_getInput:
		movl	$promptSz, %edx						#prompting user to input the number of floats they want to input
		movl	$prompt, %esi
		movl	$STDOUT, %edi
		movl	$WRITE, %eax
		syscall
		
		movl	$2, %edx
		leaq	promptOffset(%rbp), %rsi
		movl	$STDIN, %edi
		movl	$READ, %eax
		syscall 
		
		movq	(%rsi), %rax									# copy value loaded at address stored into first argument rdi to call function for convert
		subq	$48, %rax										# subtract 30 from input to get decimal number
		movb	%al, inputAmount						# store the input amount for number of entered floats into variable
		
		cmpq	$2, inputAmount						#input validation: giving error message if entered less than 2 or more than 5
		jb			inputError
		cmpq	$5, inputAmount
		ja			inputError
		jmp		inputContinue
inputError:														#printing error message for input error
		movl	$inerrSz, %edx
		movl	$inerr, %esi
		movl	$STDOUT, %edi
		movl	$WRITE, %eax
		syscall
		jmp		_getInput
inputContinue:												#continuing in the input of numbers 
		movl	$inputPromptSz, %edx				#prompting user to enter the floating point numbers 
		movl	$inputPrompt, %esi
		movl	$STDOUT, %edi
		movl	$WRITE, %eax
		syscall
		
		movb	$0, %r10b					# comaprison count with input to loop - set to 1
		
_inputFloats:								# section to input floats 
		pushq	%r10
		call		_getFloat										#calling _getFloat function to get the float values from the ascii string entered 
		popq	%r10
		movss	%xmm0, -40(%rbp, %r10, 8)			#moving float values in the array of floats on call stack
		
		stmxcsr	-64(%rbp)									#algorithm to check for precision error
		movb	-64(%rbp), %al
		andb	$32, %al
		cmpb	$0, %al
		ja			peon
		jmp		floatcont
peon:																#printing error message if there is precision error
		movl	$peerrorSz, %edx
		movl	$peerror, %esi
		movl	$STDOUT, %edi
		movl	$WRITE, %eax
		syscall
		andb	$0xdf, -64(%rbp)							#resetting the precision error flag
		ldmxcsr -64(%rbp)
floatcont:
		
		incb	%r10b												# increment counter by 1 
		cmpb	inputAmount, %r10b					# compare defined input amount value with counter
		jb		_inputFloats									# incrementer is less than or equal to inputAmount so loop and continue entering float values on next line
		
_menuOptions:												# arithmetic menu prompt section
		movl	$menuPromptSz, %edx				#prompting the user to input 1,2,3, or 4, to perform arithmatic operations according to hte input
		movl	$menuPrompt, %esi
		movl	$STDOUT, %edi
		movl	$WRITE, %eax
		syscall
		
		movl	$2, %edx
		leaq	menuOffset(%rbp), %rsi	
		movl	$STDIN, %edi
		movl	$READ, %eax
		syscall
		
		movq	(%rsi), %rdi									# copy value loaded at address stored 
		subb	$48, %dil										# subtract 30 from input to get decimal number
		movq	-32(%rbp), %xmm1						#moving the first 2 numbers of array as arguements to pass for function call
		movq	-40(%rbp), %xmm0
		movq	$0, -72(%rbp)								#initializing space on call stack to store the result
		cmpb	$1, %dil										#comparing users input to perform calculations accordingly
		je		additionfun
		cmpb	$2, %dil
		je		subtractionfun
		cmpb	$3, %dil
		je		multiplicationfun
		cmpb	$4, %dil
		je		divisionfun
		jmp	_maximum
		
additionfun:													#calling addition function
		call	addition
		movss	%xmm0, -72(%rbp)
		jmp 	printResult
subtractionfun:												#calling subtraction function
		call		subtraction
		movss	%xmm0, -72(%rbp)
		jmp 	printResult
multiplicationfun:											#calling multiplication function
		call 		multiplication
		movss	%xmm0, -72(%rbp)
		jmp 	printResult
divisionfun:													#calling division function
		movss	initialize, %xmm2						
		comiss	%xmm2, %xmm1
		je			diverror
		call 		division
		movss	%xmm0, -72(%rbp)
		jmp 	printResult

diverror:
		movl	$diverrormsgSz, %edx
		movl	$diverrormsg, %esi
		movl	$STDOUT, %edi
		movl	$WRITE, %eax
		syscall
		jmp _menuOptions
		
printResult:														#printing the result of operations
		movss	-72(%rbp), %xmm0
		call		decimalconvert							#calling decimalconvert function to convert result from float to ascii
		cmpq	$0, %rax										#checking if the result is 0
		je			zero
		jmp		contResult
zero:																#if the result is zero, printing zero
		addq	$0x30, %rax
contResult:		
		movq	%rdx, -88(%rbp)							#staring the ascii result on call stack
		movq	%rax, -80(%rbp)
		
		movl	$resultSz, %edx							#printing out the result
		movl	$result, %esi
		movl	$STDOUT, %edi
		movl	$WRITE, %eax
		syscall
		
		movl	$16, %edx
		leaq		-88(%rbp), %rsi
		movl	$STDOUT, %edi
		movl	$WRITE, %eax
		syscall
		
		jmp _menuOptions
		
_maximum:													#finding the maximum and printing it out
		movq	$0, %r10										# set counter back to 0
		movss	-40(%rbp), %xmm0
_maxLoop:														#loop to find the max number and index for max by comparing 2 numbers at a time
		incq	%r10
		cmpq	inputAmount, %r10
		je		_displayMax
		movss	-40(%rbp, %r10, 8), %xmm1
		comiss	%xmm1, %xmm0							# compare first index with next index to see which ones greater
		jb		_changeIndex
		jmp 	_maxLoop
		
_changeIndex:												#moving the bigger number index to naxIndex, and saving the bigger number in xmm0
		movq	%r10, maxIndex							# update index for larger float
		movss 	%xmm1, %xmm0							# update new value
		jmp 	_maxLoop
		
_displayMax:													# display the maximum float value entered after convert to ascii
		movq	maxIndex, %r10
		movss	-40(%rbp, %r10, 8), %xmm0
		call		decimalconvert							#calling decimalconvert function to convert result from float to ascii
		movq	%rdx, -88(%rbp)
		movq	%rax, -80(%rbp)
		
		movl	$maxResultSz, %edx					#printing the result of maximum number
		movl	$maxResult, %esi
		movl	$STDOUT, %edi
		movl	$WRITE, %eax
		syscall
		
		movl	$16, %edx
		leaq		-88(%rbp), %rsi
		movl	$STDOUT, %edi
		movl	$WRITE, %eax
		syscall								

		movl	$periodSz, %edx
		movl	$period, %esi
		movl	$STDOUT, %edi
		movl	$WRITE, %eax
		syscall

_endProgram:
		movq	%rbp, %rsp									#resetting the call stack and exiting the program
		popq 	%rbp
		movl	$EXIT, %eax
		syscall	

# functions used below
_getFloat:														#get float function
		pushq	%rbp
		movq	%rsp, %rbp
		subq	$24, %rsp
startInput:		
		movl	$9, %edx
		leaq		(%rsp), %rsi									# load current stack pointer address 
		movl	$STDIN, %edi
		movl	$READ, %eax
		syscall

		movq	%rax, %r8										#using r8 as counter for number of digits
		subq	$1, %r8
		leaq		(%rsp), %rbx
		movq	$0, %rax										#initializing the register to use
		movq	$0, %rdx
		movq	$1, %r9
		movq	$1, negativeFlag
		cmpb	$0x2d, (%rbx)								#checking for negative numbers
		je		_negativeFloat
		jmp		floatConvert

_negativeFloat:												#if negative number changing negativeFlag to -1 to check later
		movq	$-1, negativeFlag
		decq	%r8													#decreasing r8 which contains number of characters
		incq	%rbx												#increasing rbx to go to the next bit 

floatConvert:													#converting from ascii to float
		movb	(%rbx), %cl									
		cmpb	$0x2e, %cl									#checking if the character is decimal 
		je			afterDecimal								#jumping to afterDecimal to calculate the digits after the decimal 
		cmpb	$0x30, %cl									#checking if anything other than numbers; printing error message if true
		jb			numerror
		cmpb	$0x39, %cl
		ja			numerror
		subq	$0x30, (%rbx)								#converting from ascii to float same as previod labs
		movb	(%rbx), %r10b
		imulq	$10, %rax
		addq	%r10, %rax
		incq		%rbx
		subq	$1, %r8
		jmp		floatConvert
afterDecimal:													#jumping to afterDecimal after getting a decimal character in the ascii string
		incq		%rbx											#incrementing rbx to go to next character
		subq	$1, %r8
		cmpq	$0, %r8											#comparing the remaining string with zero
		je		doneFloat										#if it is zero than done with conversion
		movb	(%rbx), %cl
		cmpb	$0x30, %cl									#checking if anything other than numbers; printing error message if true
		jb			numerror
		cmpb	$0x39, %cl
		ja			numerror
		subq	$0x30, (%rbx)								#converting from float to ascii same as previous labs
		movb	(%rbx), %r10b								
		imulq	$10, %rdx
		addq	%r10, %rdx
		imulq	$10, %r9										#calculating the power of 10 to divide with (number of digits after decimal )
		jmp		afterDecimal
numerror:														#printing error message if something other than numbers
		movl	$numerrSz, %edx
		movl	$numerr, %esi
		movl	$STDOUT, %edi
		movl	$WRITE, %eax
		syscall
		jmp		startInput									#jumping back to take input again
doneFloat:
		movss	-4(%rbp), %xmm0						#initialing floating point registers
		movss	-4(%rbp), %xmm1
		movss	-4(%rbp), %xmm2
		cvtsi2ss	%rax, %xmm0							#converting whole part of the number to float
		cvtsi2ss	%rdx, %xmm1							#converting after decimal part of number to float
		cvtsi2ss	%r9, %xmm2							
		divss		%xmm2, %xmm1						#dividing after decimal part by the power fo 10 calculated 
		addss		%xmm1, %xmm0						#adding the whole and the fraction part to get the number
		
		cvtsi2ss	negativeFlag, %xmm3				
		mulss		%xmm3, %xmm0						#multiplying by the negativeFlag (-1 if negative number, 1 if positive number)
		
		movq	%rbp, %rsp									#resetting the call stack and returning to main
		popq	%rbp
		ret

addition:															#addition function to add numbers
		pushq	%rbp
		movq	%rsp, %rbp
		
		addss	%xmm1, %xmm0
		
		movq	%rbp, %rsp
		popq	%rbp
		ret

subtraction:													#subtraction function to subtract numbers
		pushq	%rbp
		movq	%rsp, %rbp
		
		subss	%xmm1, %xmm0
		
		movq	%rbp, %rsp
		popq	%rbp
		ret
		
multiplication:												#multiplication function to multiply numbers
		pushq	%rbp
		movq	%rsp, %rbp
		
		mulss	%xmm1, %xmm0
		
		movq	%rbp, %rsp
		popq	%rbp
		ret
		
division:															#division function to divide numbers
		pushq	%rbp
		movq	%rsp, %rbp
		
		divss	%xmm1, %xmm0
		
		movq	%rbp, %rsp
		popq	%rbp	
		ret	

decimalconvert:												#decimal convert function to convert from float to decimal to ascii
		pushq	%rbp
		movq	%rsp ,%rbp
		subq	$16, %rsp
		
		movq	$0, flag											#initializing registers and memories to use
		movq	$0, %r11
		movq	$0, negflag
		movq	$1, negativeFlag
		movss	%xmm0, -16(%rbp)						#storing the number on call stack
		movss	initialize, %xmm1
		comiss	%xmm1, %xmm0							#checking if number is negative
		jb			negativefloat								#jumping if number is negative
		je			done1											#jumping to done1 if 0
		jmp		positivefloat								#jumping if positive number
negativefloat:													#if the number is negative, multiplying by -1 and setting negativeFlag = -1
		movq	$-1, negativeFlag
		cvtsi2ss negativeFlag, %xmm1
		mulss	%xmm1, %xmm0
positivefloat:													#continuing in the conversion
		movss	oneflag, %xmm1							
		comiss	%xmm1, %xmm0							#comparing the number with 1
		jb			lessthanone									#jumping if less than 1
		jmp		countloop									#jumping to count number of decimal places to shift
lessthanone:													#setting negflag one to check for results less than 1
		movq	$1, negflag
countloop:														#counting the number of decimal places to shift
		comiss	%xmm1, %xmm0							#comparing the number with 1
		jb			countcont									#if less than 1 exitting the loop
		divss	div, %xmm0									#diving the number by 10
		incq		flag												#incrementing the flag (counting how many decimal places we moved)
		jmp		countloop
countcont:														#continuing conversion
		movq	$7, %r9											
		subq	flag, %r9										#subtracting 7 from the number of decimal places because we have 7 digit precision.
		movq	%r9, flag
		movq	-16(%rbp), %rbx							#moving the number to rbx (which is stored in IEEE format of float in hexadecimal form
		
		movq	$1, %r8											#initializing the registers to be used
		movss	initialize, %xmm0
#calculating the exponent		
		shll		$1, %ebx										#shifting left 1 bit to get rid of sign bit
		movq	$0, %rcx
		movl	%ebx, %ecx
		shll		$8, %ebx										#shifting left 8 bits to get rid of exponent
		shrl		$24, %ecx										#shifting right 24 bits to get the exponent and subtracting the bias od 127 from it
		subl		$127, %ecx
		movl	%ecx, deccount							#storing the exponent in deccount variable
mentissaloop:													#loop to calculate the mentissa or significand
		cmpl	$0, %ebx										#comparing the remaining number with 0
		je			continue										#jumping to continue conversion
		movq	$2, %rax										
		mulq	%r8												#multiplying by 2 for every iteration
		movq	%rax, %r8										#moving the power of 2 in r8
		shll		$1, %ebx										#shifting left 1 bit to check for carry flag
		jc			findmentissa								#jumping if there is carry flag
		jmp		mentissaloop
findmentissa:													#calculating the mentissa in this loop
		movss	oneflag, %xmm2
		cvtsi2ss %r8d, %xmm1							#converting the power of 2 to float
		divss	%xmm1, %xmm2							#dividing the power of 2 from 1 (just like we do it on paper)
		addss	%xmm2, %xmm0							#adding to the mentissa
		jmp		mentissaloop
continue:															#continuing in conversion ( here we got the mentissa)
		addss	oneflag, %xmm0							#adding 1 to the mentissa
		movq	$100000000, %rax						
		cvtsi2ss	%eax, %xmm1
		mulss	%xmm1, %xmm0							#multiplying the mentissa by 100000000 (to get rid of the decimal)
		cvtss2si %xmm0, %r9								#converting the float to the decimal
		cmpb	$0, deccount								#comparing deccount with 0 (to check for negative exponent)
		jl			mulloopneg
		jmp		mulloop
mulloopneg:													#loop for negative exponent
		cmpb	$0, deccount								#comparing exponent with 0
		je			donemul										#jumping when exponent is zero and we are done with the loop
		incb		deccount
		movq	%r9, %rax
		movq	$2, %r9
		divq		%r9												#dividing the number (mentissa + 1) by 2 as many times as the exponent is
		movq	%rax, %r9
		jmp		mulloopneg
mulloop:															#loop for positive exponent
		cmpb	$0, deccount								#comparing exponent with 0
		je			donemul										#jumping when exponent is zero and we are done with the loop
		decq		deccount
		movq	$2, %rax
		mulq	%r9												#dividing the number (mentissa + 1) by 2 as many times as the exponent is
		movq	%rax, %r9
		jmp		mulloop
donemul:															#done with multiplyin with 2 to mentissa +1 and got the number
		movq	$0, %rdx										#loop to check if the number is 7 digits or not
		cmpq	$10000000, %r9							#comparing if number is 7 digits
		jb			donefloat
		movq	%r9, %rax
		movq	$10, %r9										
		divq		%r9												#dividing by 10 ro reduce 1 digit from the back
		movq	%rax, %r9
		jmp		donemul
donefloat:														#done with getting the 7 digit number converted from float to decimal
		movq	$0, %r10										#initializing registers to use
		movq	$0, %r11
asciiloop:															#converting digits before the decimal to ascii
		movq	$0, %rdx
		cmpq	$0, %r9
		je			done
		cmpq	$0, flag											#comparing if flag is zero (which means no digits before decimal
		jle		beforedecimal
		decq		flag
		movq	%r9, %rax										#converting the number to ascii just as we did in previous labs
		movq	$10, %r9
		divq		%r9
		movq	%rax, %r9
		addq	$0x30, %rdx
		movq	%rdx, %r10
		movq	$0x100, %rax
		mulq	%r11
		movq	%rax, %r11
		addq	%r10, %r11
		jmp		asciiloop
beforedecimal:												#adding decimal when flag goes zero
		movq	$0x100, %rax
		mulq	%r11
		movq	%rax, %r11
		addb	$0x2e, %r11b
decimalloop:													#converting the digits before the decimal (whole part)  to ascii and added after the decimal character
		movq	$0, %rdx
		cmpq	$0, %r9
		je			done
		movq	%r9, %rax
		movq	$10, %r9
		divq		%r9
		movq	%rax, %r9
		addq	$0x30, %rdx
		movq	%rdx, %r10
		movq	$0x100, %rax
		mulq	%r11
		movq	%rax, %r11
		addq	%r10, %r11
		jmp decimalloop
done:																#checking there is no numbers before decimal
		cmpq	$1, negflag
		je			addDecimal
		jmp		done1
addDecimal:													#if no numbers before decimal then adding a ".0" at the end of number
		movq	$0x100, %rax
		mulq	%r11
		movq	%rax, %r11
		addb	$0x2e, %r11b
		movq	$0x100, %rax
		mulq	%r11
		movq	%rax, %r11
		addb	$0x30, %r11b
done1:																#got the number now going to check if it is negative or positive
		movq	%r11, %rax
		movq	$0, %rdx
		cmpq	$-1, negativeFlag						#comparing negativeFlag with -1
		je			negfloat
		jmp		posfloat
negfloat:															# adding a negative sign if number is negative
		movq	$0x2d, %rdx
posfloat:
		movq	%rbp, %rsp
		popq	%rbp
		ret
