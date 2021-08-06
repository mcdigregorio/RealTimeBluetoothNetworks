;/*****************************************************************************/
; OSasm.s: low-level OS commands, written in assembly                       */
; Runs on LM4F120/TM4C123/MSP432
; Lab 2 starter file
; February 10, 2016
;


        AREA |.text|, CODE, READONLY, ALIGN=2
        THUMB
        REQUIRE8
        PRESERVE8

        EXTERN  RunPt            ; currently running thread
        EXPORT  StartOS
        EXPORT  SysTick_Handler
        IMPORT  Scheduler

;Switch threads
;First steps -> Save context of current thread
;Second steps -> Load saved context of old thread and kickoff
;SP = system stack pointer, sp = thread stack pointer
SysTick_Handler                ; 1) Saves R0-R3,R12,LR,PC,PSR -> Automatically pushed onto stack by processor, SP points to R0 at "top of stack"
    CPSID   I                  ; 2) Prevent interrupt during switch, make this sequence atomic
	PUSH {R4-R11}			   ; 3) Save remaining registers, R4-R11, SP moves to R4
	LDR R0, =RunPt			   ; 4) R0 = pointer to RunPt (pointer to pointer?), old thread
	LDR R1, [R0]			   ;    R1 = RunPt
	STR SP, [R1]			   ; 5) Save SP into TCB
	;LDR R1, [R1,#4]			   ; 6) R1 = RunPt->next
	;STR R1, [R0]			   ;    RuntPt = R1
	PUSH {R0,LR}			   ; Push LR because the following BL call will use that register (don't want to kill the 0xFFFFFFF9 that's there for ISR), push R0 to keep stack push/pops even
	BL Scheduler			   ; Call external C function, RunPt = RunPt->next
	POP {R0,LR}				   ; Pop LR (restore 0xFFFFFFF9 so ISR can properly finish), pop R0 to keep stack push/pops even
	LDR R1, [R0]			   ; Load new value of RunPtr to R1 (new thread) (R1 now points to new thread)
	LDR SP, [R1]			   ; 7) new thread SP; SP = RuntPt->sp
	POP {R4-R11} 			   ; 8) Restore regs R4-R11
    CPSIE   I                  ; 9) tasks run with interrupts enabled
    BX      LR                 ; 10) restore R0-R3,R12,LR,PC,PSR

StartOS
	LDR R0, =RunPt			   ; Load address of RunPt into R0
	LDR R2, [R0]			   ; Load value at R0 to R2, R2 now equals address that RunPt was pointing to. In this case that would be the stack pointer of the first TCB.
	LDR SP, [R2]			   ; System Stack Pointer now points to stack of first TCB
	POP {R4-R11}			   ; Restore registers R4-R11 from stack
	POP {R0-R3}				   ; Restore registers R0-R3 from stack
	POP {R12}				   ; Restore R12 from stack
	ADD SP,SP,#4			   ; Skip over LR from initial stack, not relevant to initial thread run
	POP {LR}				   ; Pop what used to be PC into LR, PC value is start of thread program
	ADD SP,SP,#4			   ; Skip over PSR (Process Status Register), process never ran, so PSR is of no significance
    CPSIE   I                  ; Enable interrupts at processor level
    BX      LR                 ; start first thread

    ALIGN
    END
