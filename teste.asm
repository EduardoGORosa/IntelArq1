;             Trabalho Intel
;
;         Eduardo Rosa   00335503

COMSEG SEGMENT PARA PUBLIC 'CODE'
ASSUME CS:COMSEG,DS:COMSEG,ES:COMSEG,SS:COMSEG

ORG 80H             
CMDCNT DB ?          ;COMMAND LINE COUNT
CMDSTR DB 80 DUP(?)  ;COMMAND LINE BUFFER
   
START PROC FAR
       JMP ENTRY     ;JUMP PASS DATA
;--------------------------------------------
; DATA
;--------------------------------------------
CR					      equ		0dh
LF					      equ		0ah

cmdline              db    127 dup(?)
inputFile            db    50 dup(?)     ; Nome do arquivo de entrada
outputFile           db    'a.out',0       ; Nome padrão do arquivo de saída
groupSize            dw    0               ; Tamanho do grupo de bases
ErrorCommandLineMsg	db		"Erro na escrita da linha de comando", CR, LF, 0
FlagError				db		0
;--------------------------------------------
;SCAN INPUT PARAMETER LINE

ENTRY:  
   MOV      si,OFFSET CMDSTR ;STRING
   lea      DI, cmdline
       
   MOV      CH,0
   MOV      CL,ES:[80h]      ;PARAMETER COUNT by variable CMDCNT
   CMP      CX,0
   JNZ      get_command_line          ;YES - PROCESS COMMAND LINE PARAMETERS
   JMP      no_arguments           ;NO - PARAMETERS
   
get_command_line:   
   MOV      al,[si]
   mov      [di],al

   inc      si
   inc      di             ;INCREMENT STRING
   LOOP     get_command_line
   
no_arguments:  NOP

;START OF MAIN PROGRAM
   lea		bx,cmdline			; Coloca mensagem que pede o nome do arquivo
   call	   printf_s    

   call     parse_command_line


;RETURN TO DOS
DONE: 
   PUSH     DS
   MOV      AX,0
   PUSH     AX
   RET
START ENDP

;
;--------------------------------------------------------------------
; Parse command line string
;--------------------------------------------------------------------
parse_command_line proc near
    lea     si, offset cmdline

    ; go to next arg
    skip_space:
      mov   al, [si]
      cmp   al, ' '
      je    next_option
      inc   si
      jmp   skip_space

    next_option:
      inc   si
      mov   al, [si]

        ; Verificar se encontramos uma opção válida
      cmp   al, '-'
      jne   invalid_option

		; Move string pointer
		inc   si
		mov   al, [si]
		cmp   al, 'f'
      je    f_option
		cmp   al, 'o'
      je    o_option
		cmp   al, 'n'
      je    n_option
      jmp   actg_option

	f_option:
      lea   bx,cmdline
      call  printf_s
	   jmp   skip_space

	o_option:
      lea   bx,cmdline
      call  printf_s
	   jmp   skip_space

	n_option:
      lea   bx,cmdline
      call  printf_s
	   jmp   skip_space

	actg_option:
      lea   bx,cmdline
      call  printf_s
      jmp   done_parsing

    invalid_option:
      lea   bx,ErrorCommandLineMsg
      call  printf_s
      mov	FlagError,1

    done_parsing:
      ret

parse_command_line endp

;
;--------------------------------------------------------------------
;Função Escrever um string na tela
;		printf_s(char *s -> BX)
;--------------------------------------------------------------------
printf_s	proc	near
	mov		dl,[bx]
	cmp		dl,0
	je		   ps_1

	push	   bx
	mov		ah,2
	int		21H
	pop		bx

	inc		bx		
	jmp		printf_s
		
ps_1:
	ret
printf_s	endp

;
;--------------------------------------------------------------------
;Função Escrever um char na tela
;		Entra: DL -> Char a ser escrito
;--------------------------------------------------------------------
printf_c	proc	near
		mov		ah, 2
		int		21H
		ret
printf_c	endp

COMSEG ENDS

END START