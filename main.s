;****************** main.s ***************
; Program written by: Kate Baumli and Rebecca Wong
; Date Created: 2/14/2017
; Last Modified: 2/27/2017
; Brief description of the program
;   The LED toggles at 8 Hz and a varying duty-cycle
;   Repeat the functionality from Lab2-3 but now we want you to 
;   insert debugging instruments which gather data (state and timing)
;   to verify that the system is functioning as expected.
; Hardware connections (External: One button and one LED)
;  PE1 is Button input  (1 means pressed, 0 means not pressed)
;  PE0 is LED output (1 activates external LED on protoboard)
;  PF2 is Blue LED on Launchpad used as a heartbeat
; Instrumentation data to be gathered is as follows:
; After Button(PE1) press collect one state and time entry. 
; After Buttin(PE1) release, collect 7 state and
; time entries on each change in state of the LED(PE0): 
; An entry is one 8-bit entry in the Data Buffer and one 
; 32-bit entry in the Time Buffer
;  The Data Buffer entry (byte) content has:
;    Lower nibble is state of LED (PE0)
;    Higher nibble is state of Button (PE1)
;  The Time Buffer entry (32-bit) has:
;    24-bit value of the SysTick's Current register (NVIC_ST_CURRENT_R)
; Note: The size of both buffers is 50 entries. Once you fill these
;       entries you should stop collecting data
; The heartbeat is an indicator of the running of the program. 
; On each iteration of the main loop of your program toggle the 
; LED to indicate that your code(system) is live (not stuck or dead).

GPIO_PORTE_DATA_R  EQU 0x400243FC
GPIO_PORTE_DIR_R   EQU 0x40024400
GPIO_PORTE_AFSEL_R EQU 0x40024420
GPIO_PORTE_DEN_R   EQU 0x4002451C

GPIO_PORTF_DATA_R  EQU 0x400253FC
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_DEN_R   EQU 0x4002551C
SYSCTL_RCGCGPIO_R  EQU 0x400FE608

COUNT	EQU 500000
ENTIRE_COUNT EQU 2500000
LED_ON EQU	1
LED_OFF EQU 0	
SWITCH EQU 2
ONE EQU 1

; RAM Area
           AREA    DATA, ALIGN=2
;-UUU-Declare  and allocate space for your Buffers 
;    and any variables (like pointers and counters) here
DataBuffer SPACE 50
TimeBuffer SPACE 200 ; 50 elements 4 bytes each 
DataPt    SPACE 4
TimePt	   SPACE 4	
NEntries 	SPACE 1

; ROM Area
       IMPORT  TExaS_Init
	IMPORT SysTick_Init
	IMPORT NVIC_ST_CURRENT_R	   
;-UUU-Import routine(s) from other assembly files (like SysTick.s) here
       AREA    |.text|, CODE, READONLY, ALIGN=2
       THUMB
       EXPORT  Start

Start
 ; TExaS_Init sets bus clock at 80 MHz
      BL  TExaS_Init ; voltmeter, scope on PD3
      CPSIE  I    ; TExaS voltmeter, scope runs on interrupts

	LDR R1, =SYSCTL_RCGCGPIO_R      ; activate clock for Port F
    LDR R0, [R1]                 
    ORR R0, R0, #0x10               ; set bits 4 & 5 to turn on clock
    STR R0, [R1]                  
    NOP
    NOP                                                       
    LDR R1, =GPIO_PORTE_DIR_R       ; set direction register
    MOV R0,#0x01	                ; PE1 INPUT, PE0 output
    STR R0, [R1]                    
    LDR R1, =GPIO_PORTE_AFSEL_R     ; regular port function
    MOV R0, #0                      ; 0 means disable alternate function 
    STR R0, [R1]                                
    LDR R1, =GPIO_PORTE_DEN_R       ; enable Port E digital port
    MOV R0, #0xFF                   ; 1 means enable digital I/O
    STR R0, [R1]      
    LDR R0, [R1]                 
	
		LDR R4,=COUNT					;R4 HAS 20% OF DELAY
		LDR R9,=ONE
		LDR R5,=ENTIRE_COUNT
		AND R7,R7,#0					;R7 WILL HOLD FLAG THAT WILL BE ASSERTED IF SWITCH HAS BEEN PRESSED
		LDR R0,=GPIO_PORTE_DATA_R
loop		
		LDR R1,[R0]						;STARTING FLASHING
		LDR R2,=LED_ON					;TURNING
		ORR R1,R1,R2					;ON
		STR R1,[R0]						;LED
		MOV R3,R4						;R3 WILL BE USED BY DELAY FUNCTION & DECREMENTED
		BL DELAY
		LDR R1,[R0]						;TURNING
		LDR R2,=LED_OFF
		AND R1,R1,R2					;LED
		STR R1,[R0]						;OFF
		MOV R3,R4			;REPLENISHING R3 (BECAUSE IT WAS DECREMENTED TO 0 IN DELAY)		
		RSB R3,R3,R5					;SUBTRACTING DUTY CYCLE PERCENTATGE FROM 100% TO GET OFF DUTY CYCLE
		BL DELAY
		LDR R1,[R0]
		LDR R6,=SWITCH
		AND R1,R1,R6					;BIT MASKING SWITCH
		CMP R1, R6
		BNE NOT_CURRENTLY_PRESSED					;CHECKING IF SWITCH  IS PRESSED CURRENTLY
		LDR R7,=ONE
		B NO_FLAG
NOT_CURRENTLY_PRESSED CMP R7,R9					;COMPARING TO ONE TO SEE IF FLAG IS ASSERTED
		BNE NO_FLAG
		CMP R4,R5						;SWITCH HAS BEEN ASSERTED AND RELEASED, CHANGING DUTY CYCLE
		BNE ADD_TWENTY_PERCENT			;CHECKING IF THE DUTY CYCLE IS AT 100%
		AND R4,R4,#0
		AND R7,R7,#0
		B loop								;SETTING IT TO 0 FOR THE NEXT ROUND
ADD_TWENTY_PERCENT LDR R8,=COUNT
		ADD R4,R4,R8			;ADDING 20% TO THE DUTY CYCLE
		AND R7,R7,#0
NO_FLAG B loop		
		
DELAY	SUBS R3,R3,#1
		BHI DELAY
		BX LR

Debug_Init
	PUSH {R0-R4,LR}
	LDR R2,=DataBuffer
	LDR R3,=TimeBuffer
	LDR R0,=DataPt
	LDR R1,=TimePt
	STR R2,[R0]
	STR R3,[R1]
	LDR R0,[R0]	 ; R0 and R1 now have the actual pointers R0 DATA R1 TIME
	LDR R1,[R1]
	MOV R2,#50	;R2 will keep track of how many array values we have traversed through
	MOV R3,#0xFF

Buffer_Init			;loop that stores 0xFF into all buffer locations
	STRB R3,[R0]	;STORE 0xFF into data buffer location
	STRB R3,[R1]
	STRB R3,[R1,#1]
	STRB R3,[R1,#2]
	STRB R3,[R1,#3] ;STORE 0xFF into every byte
	ADD R0,R0,#1
	ADD R1,R1,#4
	SUBS R2,R2,#1
	BNE Buffer_Init
	BL 	SysTick_Init
	LDR R0,=NEntries
	MOV R1,#50
	STR R1,[R0]
	POP {R0-R4,PC}	;return from subroutine
	
Debug_Capture
	PUSH {R0-R10,LR}
	LDR R0,=NEntries				;Checking if we have stored 50 entries yet
	LDR R1,[R0] 
	CMP R1,#0
	BEQ DONE
	LDR R2,=GPIO_PORTE_DATA_R
	LDR R3,[R2]						;Loading in port E data
	LDR R7,=NVIC_ST_CURRENT_R
	LDR R8,[R7]						;Loading in SysTick currrent time 
	AND R4,R3,#0x02					;bit masking switch
	LSL R4,R4,#3					;shifting it over to next nibble
	AND R3,R3,#0x01					;combining Data to have PEO in first nibble and
	ORR R3,R3,R4					; PE1 in next nibble
	LDR R5,=DataPt					
	LDR R6,[R5]
	STRB R3,[R6]					;storing data in data buffer array
	ADD R6,R6,#1
	STR R6,[R5]						;incrememnted dataBuffer pointer for next time around
	LDR R9,=TimePt
	LDR R10,[R9]					;R10 has next availabl address of time buffer array
	STR R8,[R10]
	ADD R10,R10,#1					;incremented timeBuffer pointer for next time aroudn
	STR R10,[R9]
	SUB	R1,R1,#1					;decrementing index counter 
DONE
	POP {R0-R10,PC}
	 


      ALIGN      ; make sure the end of this section is aligned
      END        ; end of file

