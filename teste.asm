;             Trabalho Intel
;
;         Eduardo Rosa   00335503

COMSEG SEGMENT PARA PUBLIC 'CODE'
ASSUME CS:COMSEG,DS:COMSEG,ES:COMSEG,SS:COMSEG

ORG 80H             
CMDCNT DB ?          ;COMMAND LINE COUNT
CMDSTR DB 127 DUP(?)  ;COMMAND LINE BUFFER
   
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
   mov      si, offset CMDSTR ;STRING
   mov      ch,0
   mov      cl,es:[80h]      ;PARAMETER COUNT by variable CMDCNT
   cmp      cx,0
   jnz      parse_command_line          ;YES - PROCESS COMMAND LINE PARAMETERS
   jmp      no_arguments           ;NO - PARAMETERS
   
parse_command_line:   
   skip_space:
      mov   al, [si]
      cmp   al, ' '
      je    next_option
      cmp   al, CR
      je    invalid_option
      inc   si
      jmp   skip_space
   
   next_option:
      inc   si
      mov   al, [si]

      ; Verificar se encontramos uma opção válida
      cmp   al, '-'
      jne   invalid_option
      cmp   al, CR
      je    invalid_option

		; Move string pointer
		inc   si
		mov   al, [si]
      cmp   al, CR
      je    invalid_option
		cmp   al, 'f'
      je    f_option
		cmp   al, 'o'
      je    o_option
		cmp   al, 'n'
      je    n_option
      jmp   actg_option

   f_option:
      lea   di, inputFile
      inc   si
      mov   al, [si]
      cmp   al, ' '
      jne   invalid_option
      f_option_loop:
         inc   si
         mov   al, [si]
         cmp   al, ' '
         je    skip_space
         cmp   al, CR
         je    skip_space
         ;inc   di
         mov   [di], al
         jmp   f_option_loop 

	o_option:
      lea   bx,ErrorCommandLineMsg
      call  printf_s
	   jmp   skip_space

	n_option:
      lea   bx,ErrorCommandLineMsg
      call  printf_s
	   jmp   skip_space

	actg_option:
      lea   bx,ErrorCommandLineMsg
      call  printf_s
      jmp   done_parsing

    invalid_option:
      lea   bx,ErrorCommandLineMsg
      call  printf_s
      mov	FlagError,1
      jmp   no_arguments
    done_parsing:
      ret

      LOOP     parse_command_line
   
no_arguments:  NOP

      lea   bx,inputFile
      call  printf_s
;RETURN TO DOS
DONE: 
   PUSH     DS
   MOV      AX,0
   PUSH     AX
   RET
START ENDP

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