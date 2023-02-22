//LAB THREE PART FOUR WITH KEY FUNCTIONALITY 
.global _start

//[R4] = Load Register
//[R4, #0x4] = Counter Register 
//[R4, #0x8] = Control Register
//[R4, #0xC] = Interrupt Status 

_start: LDR SP, =200000
		MOV R0, #0 //Holds the ones digit after execution of DIVIDE subroutine
        MOV R1, #0 //Holds the tens digit after execution of DIVIDE subroutine
		MOV R10, #0 //The counter that counts the number we are displaying on HEX
		MOV R11, #0
		MOV R3, #0 //Used to hold ones digit before ORRing with R0
		LDR R8, =0xFF200020 // base address of HEX3-HEX0
		MOV R9, #0 //Temporarily holds the 10s digit while we convert ones digit into bit code 
		//[R8, #3C] = 0xFF2005c, which is the edge capture register of the keys
		MOV R7, #0 //The register we use to check 
		
COUNTER: CMP R10, #100  //CMP R0, #100 
	     BEQ HUNDRED_COUNTER_RESET
		 
		
		 MOV R0, R10 //Move the hundredths of a second into R0 
		 PUSH {LR}
	     BL DIVIDE //Call the divide subroutine 
		 POP {LR}
		 PUSH {R9} //Push R9 Onto the stack 
		 MOV R9, R1 //Save the 10s digit of hundredths of seconds for later
		 PUSH {LR}
	     BL SEG7_CODE //Convert the ones digit of the hundredths of a second into bit code
		 POP {LR} 
	     MOV R3, R0  //Move the ones digit bit code into R3
	     MOV R0, R9 //Move the 10s digit into R0 
		 POP {R9}
		 PUSH {LR} 
	     BL SEG7_CODE //Convert the 10s digit of the hundredths of a second into bit code 
		 POP {LR} 
	     LSL R0, #8   //Shift 10s digit 8 bits over 
	     ORR  R3, R0 //Combine the two together and save in R3
		 
		 
		 MOV R0, R11 //Move the Actual Seconds into R0
		 PUSH {LR}
		 BL DIVIDE //Call the divide subroutine 
		 POP {LR}
		
		 PUSH {R9} //Push R9 onto the stack 
		 MOV R9, R1 //save the 10s digit of the seconds into R9
		 PUSH {LR}
		 BL SEG7_CODE //Convert ones digit of the seconds into bit code 
		 POP {LR}
		 
		 
		
		 MOV R7, R0  //R7<- Ones digit bit code 
		 LSL R7, #16 //(8 zeros, ones digit, 16 zeros)
		 MOV R0, R9 //Move the 10s digit into R0 
		 POP {R9}
		 
		 PUSH {LR}
		 BL SEG7_CODE //Convert the 10s digit of the seconds into bit code 
         POP {LR}
		 
		 LSL R0, #24 //R0 has the 10s digit of the actual seconds 
		 ORR R7, R0 //ORR the tens digit and ones digit of the seconds together 
		 ORR R3, R7 //ORR the seconds and the hundredths of a second together
		 
		 
	     STR R3, [R8] //Display the number 
	     ADD R10, #1 //Increment the hundredths of seconds 
		
		 PUSH {LR}
		 BL TIMER_RESET1 //Take care of timing 
		 
         POP {LR} 

		 B COUNTER
		 		 
HUNDRED_COUNTER_RESET: MOV R10, #0
                       CMP R11, #59 
					   BEQ SECOND_COUNTER_RESET
					   ADD R11, #1 //Increment the actual seconds 
			   		   B COUNTER
			   
SECOND_COUNTER_RESET: MOV R11, #0
					  B COUNTER

//TIMER CODE
TIMER_RESET1: PUSH {R4-R11}

TIMER_RESET2:
			//
			//CODE FOR KEY PRESSES HERE 
			LDR R9, [R8, #0x3C] //Load the edge capture register into R9 
			ANDS R9, #15
			BGT ECR_RESET_1
			//
            LDR R5, =0x1E8480 //Load 2 Mil into R5
			LDR R4, =0xFFFEC600 //R4 points to the Load Register of the Counter
			STR R5, [R4] //Store 2 Million into R4, Load the timer
			MOV R6, #1
		    STR R6, [R4, #0x8] //Store a one into the control register to start the timer
			 
POLL:  LDR R7, [R4, #0xC] //Load the interrupt status register into R7
	   ANDS R7, #1 //Check the value of the F bit 
	   BEQ POLL   //If it equals zero, keep polling 
	   //B INTERRUPT_RESET  //If it does not equal zero, move on to reset the f bit 

INTERRUPT_RESET: STR R6, [R4, #0xC] //Store a one into F bit to reset it to zero 
                 POP {R4-R11}
                 MOV PC, LR
				 
ECR_RESET_1: MOV R10, #15 
             STR R10, [R8, #0x3C] //Store ones into ECR to reset it 
			 B WAIT  //Branch to wait loop where we will stay until another key is pressed
			 
WAIT:        LDR R9, [R8, #0x3C]  //Again, load the ECR into R9
			 ANDS R9, #15  //Check if a key was presed, if so, go back to sub loop 
			 BGT ECR_RESET_2
			 B WAIT

ECR_RESET_2: MOV R10, #15  
			 STR R10, [R8, #0x3C]   //Store ones into ECR to reset it 
			 B TIMER_RESET2  
//We will use R8, R9, R10, R11 for checking for key presses 

//CODE FOR DIVIDING 
DIVIDE: 	MOV R2, #0

CONT: 		CMP R0, #10
	  		BLT DIV_END
	  		SUB R0, #10
	  		ADD R2, #1
	  		B CONT

DIV_END: 	MOV R1, R2 // quotient in R1 (remainder in R0)
		 	MOV PC, LR
//CODE FOR DIVIDING

//SEG7 CODE
SEG7_CODE:  MOV     R1, #BIT_CODES  
            ADD     R1, R0         // index into the BIT_CODES "array"
            LDRB    R0, [R1]       // load the bit pattern (to be returned)
            MOV     PC, LR              

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment   
//SEG7CODE