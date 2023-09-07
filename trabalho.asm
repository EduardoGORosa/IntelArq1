;             Trabalho Intel
;
;         Eduardo Rosa   00335503

.model small
.stack

.data
ORG 80H             
CMDCNT DB ?          ;COMMAND LINE COUNT
CMDSTR DB 127 DUP(?)  ;COMMAND LINE BUFFER
;--------------------------------------------
; DATA
;--------------------------------------------
CR					      equ		0dh
LF					      equ		0ah

cmdline              db    127   dup(?)
inputFile            db    50    dup(?)        ; Nome do arquivo de entrada
outputFile           db    50    dup(?)        ; Nome padrão do arquivo de saída
defaultOutputFile    db    'a.out', 0       ; Nome padrão do arquivo de saída
groupSize            db    5     dup(?)               ; Tamanho do grupo de bases
nitrogen_bases       db    5     dup(?)
base_a               db    0
base_c               db    0
base_t               db    0
base_g               db    0
base_plus            db    0
base_valid           db    "actg+", 0
errorCommandLineMsg	db		"Erro na escrita da linha de comando", CR, LF, 0
flagError				db		0
MsgCRLF					db		CR, LF, 0
;--------------------------------------------
;SCAN INPUT PARAMETER LINE

.code
.startup
   mov      si, 81h
   mov      ch,0
   mov      cl,es:[80h]      ;PARAMETER COUNT by variable CMDCNT
   cmp      cx,0
   jnz      parse_command_line          ;YES - PROCESS COMMAND LINE PARAMETERS
   jmp      no_arguments           ;NO - PARAMETERS
   
parse_command_line:   
   skip_space:
      mov   al, es:[si]
      cmp   al, ' '
      je    next_option
      cmp   al, CR
      je    no_arguments
      inc   si
      jmp   skip_space
   
   next_option:
      inc   si
      mov   al, es:[si]

      ; Verificar se encontramos uma opção válida
      cmp   al, '-'
      jne   invalid_option

		; Move string pointer
		inc   si
		mov   al, es:[si]
      cmp   al, CR
      je    invalid_option
		cmp   al, 'f'
      je    f_option
		cmp   al, 'o'
      je    o_option
		cmp   al, 'n'
      je    n_option
      jmp   base_option

   f_option:
      lea   di, inputFile
      inc   si
      mov   al, es:[si]
      cmp   al, ' '
      jne   invalid_option
      f_option_loop:
         inc   si
         mov   al, es:[si]
         cmp   al, ' '
         je    skip_space
         cmp   al, CR
         je    skip_space
         mov   [di], al
         inc   di
         jmp   f_option_loop 

	o_option:
      lea   di, outputFile
      inc   si
      mov   al, es:[si]
      cmp   al, ' '
      jne   invalid_option
      o_option_loop:
         inc   si
         mov   al, es:[si]
         cmp   al, ' '
         je    skip_space
         cmp   al, CR
         je    skip_space
         mov   [di], al
         inc   di
         jmp   o_option_loop 

	n_option:
      lea   di, groupSize
      inc   si
      mov   al, es:[si]
      cmp   al, ' '
      jne   invalid_option
      n_option_loop:
         inc   si
         mov   al, es:[si]
         cmp   al, ' '
         je    end_n_option
         cmp   al, CR
         je    end_n_option
         cmp   al, 39h
         jg    invalid_option
         cmp   al, 30h
         jl    invalid_option
         mov   [di], al
         inc   di
         jmp   n_option_loop
      end_n_option:
         mov   [di], 0
         jmp   skip_space

	base_option:
      lea   di, base_valid    ; di = base_valid initial adress
      lea   bx, nitrogen_bases
      cmp   al, ' '           ; if space invalid
      je    invalid_option
      cmp   al, CR            ; if cr invalid
      je    invalid_option
   base_check_loop:
      mov   al, es:[si]       ; al = cmdline char
      cmp   al, ' '           ; if space base_cmd ended
      je    done_parsing_base
      cmp   al, CR            ; if cr base_cmd ended
      je    done_parsing_base             
   search_loop:
      cmp   al, [di]       ; if cmdline char == base_valid initial address
      je    char_is_valid     ; char_is_valid()
      inc   di                ; base_address++
      mov   cl, [di]                ; base_address++
      cmp   cl, 0             ; if base_address == 0
      jne   search_loop       ; search_loop()
      jmp   invalid_base_option
      
   char_is_valid:
      cmp   al, 'a'           ; if cmdline char == 'a'
      je    put_a             ; base_a = True
      cmp   al, 'c'           ; if cmdline char == 'c'
      je    put_c             ; base_c = True
      cmp   al, 't'           ; if cmdline char == 't'
      je    put_t             ; base_t = True
      cmp   al, 'g'           ; if cmdline char == 'g'
      je    put_g             ; base_g = True
      cmp   al, '+'           ; if cmdline char == '+'
      je    put_plus          ; base_plus = True
      jmp   base_check_loop

      put_a: 
         mov   [bx], 'a'
         inc   bx
         inc   si
         jmp   base_check_loop   
      put_c: 
         mov   [bx], 'c'
         inc   bx
         inc   si
         jmp   base_check_loop   
      put_t: 
         mov   [bx], 't'
         inc   bx
         inc   si
         jmp   base_check_loop   
      put_g: 
         mov   [bx], 'g'
         inc   bx
         inc   si
         jmp   base_check_loop   
      put_plus: 
         mov   [bx], '+'
         inc   bx
         inc   si
         jmp   base_check_loop      

    done_parsing_base:
         jmp   no_arguments                                                     

   invalid_base_option:
      mov cx, 5                 ; Set the loop counter to the number of elements
      lea si, nitrogen_bases    ; Set edi to point to the start of the array

      invalid_base_loop:
         mov byte ptr [si], 0          ; Zero out the current element
         inc si                    ; Move to the next element
         loop invalid_base_loop

   invalid_option:
      lea   bx,errorCommandLineMsg
      call  printf_s
      mov	flagError,1
      jmp   skip_space
   
no_arguments:  NOP

      lea   bx,inputFile
      call  printf_s

      lea   bx,MsgCRLF
      call  printf_s

      lea   bx,outputFile
      call  printf_s

      lea   bx,MsgCRLF
      call  printf_s

      lea   bx,groupSize
      call  atoi
      mov   bx,ax
      call  printf_s

      lea   bx,MsgCRLF
      call  printf_s

      lea   bx,nitrogen_bases
      call  printf_s

.exit
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

;
;--------------------------------------------------------------------
;Função:Converte um ASCII-DECIMAL para HEXA
;Entra: (S) -> DS:BX -> Ponteiro para o string de origem
;Sai:	(A) -> AX -> Valor "Hex" resultante
;Algoritmo:
;	A = 0;
;	while (*S!='\0') {
;		A = 10 * A + (*S - '0')
;		++S;
;	}
;	return
;--------------------------------------------------------------------
atoi	proc near

		; A = 0;
		mov		ax,0
		
atoi_2:
		; while (*S!='\0') {
		cmp		byte ptr[bx], 0
		jz		   atoi_1

		; 	A = 10 * A
		mov		cx,10
		mul		cx

		; 	A = A + *S
		mov		ch,0
		mov		cl,[bx]
		add		ax,cx

		; 	A = A - '0'
		sub		ax,'0'

		; 	++S
		inc		bx
		
		;}
		jmp		atoi_2

atoi_1:
		; return
		ret

atoi	endp

;--------------------------------------------------------------------
		end
;--------------------------------------------------------------------


end