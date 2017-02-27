; SysTick.s
; Module written by: ***Your Names**update this***
; Date Created: 2/14/2017
; Last Modified: 2/14/2017 
; Brief Description: Initializes SysTick

NVIC_ST_CTRL_R        EQU 0xE000E010
NVIC_ST_RELOAD_R      EQU 0xE000E014
NVIC_ST_CURRENT_R     EQU 0xE000E018
RELOAD_VALUE 		  EQU 0xFFFFFFFF
        AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB
; ;-UUU-Export routine(s) from SysTick.s to callers

;------------SysTick_Init------------
; ;-UUU-Complete this subroutine
; Initialize SysTick with busy wait running at bus clock.
; Input: none
; Output: none
; Modifies: ??
SysTick_Init
	PUSH {R0-R3}
	LDR R0,=NVIC_ST_CTRL_R
	LDR R1,[R0]
	BIC R1,R1,#0x01
	STR R1,[R0]
	LDR R2,=NVIC_ST_RELOAD_R
	LDR R3,=RELOAD_VALUE
	LDR R1,[R3]
	STR R1,[R2]
	LDR R2,=NVIC_ST_CTRL_R
	MOV R1,#0
	STR R1,[R2]
	LDR R1,[R0]
	ORR R1,R1,#0x05
	BIC R1,R1,#0x02
	STR R1,[R0]
	POP {R0-R3}
    BX  LR                          ; return
	
    ALIGN                           ; make sure the end of this section is aligned
    END                             ; end of file
