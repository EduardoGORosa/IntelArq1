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
groupSizeStr         db    5     dup(?)               ; Tamanho do grupo de bases
groupSize            db    0
nitrogen_bases       db    5     dup(?)
s_nitrogen_bases     db    5     dup(?)
fileSize             db    0
base_a               db    0
base_c               db    0
base_t               db    0
base_g               db    0
base_plus            db    0
base_valid           db    "actg+", 0
errorCommandLineMsg	db		"Erro na escrita da linha de comando", CR, LF, 0
FlagError				db		0
MsgCRLF					db		CR, LF, 0
MsgInputFile         db    "Nome do arquivo de entrada : ", 0
MsgOutputFile        db    "Nome do arquivo de saída : ", 0
MsgGroupSize         db    "Tamanho dos grupos de bases a serem calculados: ", 0
MsgInformation       db    "Informações a serem colocadas no arquivo de saída: ", 0
MsgBasesSizeInput    db    "Número de bases no arquivo de entrada: ", 0
MsgGroupCount        db    "Número de grupos a serem processados: ", 0
MsgLinesInputFile    db    "Número de linhas do arquivo de entrada que contém bases: ", 0
ErrorOpenFileMsg		db		"Erro na abertura do arquivo.", CR, LF, 0
ErrorReadFileMsg		db		"Erro na leitura do arquivo.", CR, LF, 0
ErrorCreateFileMsg	db		"Erro na criacao do arquivo", CR, LF, 0
ErrorWriteFileMsg		db		"Erro na escrita do arquivo", CR, LF, 0
FileHandle				dw		0						; Handler do arquivo de leitura
FileHandleDst			dw		0						; Handler do arquivo de saida
FileBuffer				db		0 						; Buffer de leitura do arquivo
sw_n					   dw		0
sw_f					   db		0
sw_m					   dw		0
msg_base_a				db		"Count of 'A': ", 0
msg_base_c				db		"Count of 'C': ", 0
msg_base_t				db		"Count of 'T': ", 0
msg_base_g				db		"Count of 'G': ", 0
base_a_str	         db		6 dup (?)   ; Buffer para o contador de 'A' em formato de string
base_c_str	         db		6 dup (?)   ; Buffer para o contador de 'C' em formato de string
base_t_str	         db		6 dup (?)   ; Buffer para o contador de 'T' em formato de string
base_g_str	         db		6 dup (?)   ; Buffer para o contador de 'G' em formato de string
;--------------------------------------------
;SCAN INPUT PARAMETER LINE

.code
.startup
   mov      si, 81h
   mov      ch,0
   mov      cl,es:[80h]      ;PARAMETER COUNT by variable CMDCNT
   call     get_commandline

   lea      bx,MsgCRLF
   call     printf_s

   call     sort_nitrogen_bases

   lea      bx,groupSizeStr
   call     atoi
   lea      bx,groupSize
   mov      [bx], ax
   
   ;	Abre o arquivo
   lea		dx,inputFile
   call 	   fopen
   jc		   ErrorOpenFile		;If (CF == 1), erro ao abrir o arquivo
   mov		FileHandle,ax		; Salva handle do arquivo

   lea		bx, outputFile
   cmp      [bx], 0
   je       DefaultOFile
   jmp      CmdOFile

DefaultOFile:
   lea		dx, defaultOutputFile
   call	   fcreate
   jc		   ErrorCreateFile
   mov		FileHandleDst, ax
   jmp      LoopReadFile

CmdOFile:
   lea		dx, outputFile
   call	   fcreate
   jc		   ErrorCreateFile
   mov		FileHandleDst, ax

LoopReadFile:
      lea   si, s_nitrogen_bases
   set_header_bases:
      cmp   byte ptr[si], 0
      je    count_bases 
      cmp   byte ptr[si], 'a'
      je    set_header_a
      cmp   byte ptr[si], 'c'
      je    set_header_c
      cmp   byte ptr[si], 't'
      je    set_header_t
      cmp   byte ptr[si], 'g'
      je    set_header_g
      cmp   byte ptr[si], '+'
      je    set_header_plus
      jmp   count_bases

   set_header_a:
      mov   dl, 'A'
      mov   bx, FileHandleDst
      call  setChar
      inc   si
      cmp   byte ptr[si], 0
      je    count_bases
      mov   dl, 3bh
      call  setChar
      jmp   set_header_bases
   set_header_c:
      mov   dl, 'C'
      mov   bx, FileHandleDst
      call  setChar
      inc   si
      cmp   byte ptr[si], 0
      je    count_bases
      mov   dl, 3bh
      call  setChar
      jmp   set_header_bases
   set_header_t:
      mov   dl, 'T'
      mov   bx, FileHandleDst
      call  setChar
      inc   si
      cmp   byte ptr[si], 0
      je    count_bases
      mov   dl, 3bh
      call  setChar
      jmp   set_header_bases
   set_header_g:
      mov   dl, 'G'
      mov   bx, FileHandleDst
      call  setChar
      inc   si
      cmp   byte ptr[si], 0
      je    count_bases
      mov   dl, 3bh
      call  setChar
      jmp   set_header_bases

   set_header_plus:
      mov   dl, 'A'
      mov   bx, FileHandleDst
      call  setChar
      mov   dl, 2bh
      call  setChar
      mov   dl, 'T'
      call  setChar
      mov   dl, 3bh
      call  setChar
      mov   dl, 'C'
      call  setChar
      mov   dl, 2bh
      call  setChar
      mov   dl, 'G'
      call  setChar
      jmp   CloseAndFinal

   count_bases:
      mov     dl, CR
      call    setChar
      mov     dl, LF
      call    setChar
      lea     bx,groupSize
      mov     cx,[bx]
      mov     base_a, 0
      mov     base_c, 0
      mov     base_t, 0
      mov     base_g, 0
      count_bases_loop:
         mov     bx, FileHandle
         call    getChar
         jc      ErrorReadFile
         cmp     ax, 0
         jz      CloseAndFinal
         mov     al, dl
         ; Check for 'A', 'C', 'T', 'G' and update counters
         cmp     al, 'A'
         je      IncrementA
         cmp     al, 'C'
         je      IncrementC
         cmp     al, 'T'
         je      IncrementT
         cmp     al, 'G'
         je      IncrementG
         loop    count_bases_loop
         jmp     count_bases

         IncrementA:
            inc     base_a
            jmp     count_bases_loop

         IncrementC:
            inc     base_c
            jmp     count_bases_loop

         IncrementT:
            inc     base_t
            jmp     count_bases_loop

         IncrementG:
            inc     base_g
            jmp     count_bases_loop

ErrorOpenFile:
		lea		bx,ErrorOpenFileMsg
		call	   printf_s
		mov		FlagError,1
		jmp		Final

ErrorReadFile:
		lea		bx, ErrorReadFileMsg
		call	   printf_s
		mov		FlagError, 1
		jmp		CloseAndFinal

ErrorCreateFile:
		lea		bx, ErrorCreateFileMsg
		call	   printf_s
		mov		FlagError, 1
		jmp		CloseAndFinal

ErrorWriteFile:
		lea 	   bx, ErrorWriteFileMsg
		call	   printf_s
		mov		FlagError, 1
		jmp		CloseAndFinal

CloseAndFinal:

    ; Display counts of 'A', 'C', 'T', 'G'
    ; Após incrementar cada contador (IncrementA, IncrementC, IncrementT, IncrementG), converta o valor para string

	; convert A to string
	mov      al, base_a
	mov      bx, offset base_a_str
	call     sprintf_w

	; convert C to string
	mov      al, base_c
	mov      bx, offset base_c_str
	call     sprintf_w

	; convert T to string
	mov      al, base_t
	mov      bx, offset base_t_str
	call     sprintf_w

	; convert G to string
	mov      al, base_g
	mov      bx, offset base_g_str
	call     sprintf_w

	; Breakline
	lea		bx,MsgCRLF
	call	   printf_s

	; Print A message and A counter
	lea      bx, msg_base_a
	call     printf_s
	lea      bx, base_a_str
	call     printf_s

	; Breakline
	lea		bx,MsgCRLF
	call	   printf_s

	; Print C message and C counter
	lea      bx, msg_base_c
	call     printf_s
	lea      bx, base_c_str
	call     printf_s

	; Breakline
	lea		bx,MsgCRLF
	call	   printf_s

	; Print T message and T counter
	lea      bx, msg_base_t
	call     printf_s
	lea      bx, base_t_str
	call     printf_s

	; Breakline
	lea		bx,MsgCRLF
	call	   printf_s

	; Print G message and G counter
	lea      bx, msg_base_g
	call     printf_s
	lea      bx, base_g_str
	call     printf_s

Final:
		.exit

;
;--------------------------------------------------------------------
;Função: Converte um inteiro (n) para (string)
;		 sprintf(string->BX, "%d", n->AX)
;--------------------------------------------------------------------
sprintf_w	proc	near
	mov		sw_n,ax
	mov		cx,5
	mov		sw_m,10000
	mov		sw_f,0
	
sw_do:
	mov		dx,0
	mov		ax,sw_n
	div		sw_m
	
	cmp		al,0
	jne		sw_store
	cmp		sw_f,0
	je		sw_continue
sw_store:
	add		al,'0'
	mov		[bx],al
	inc		bx
	
	mov		sw_f,1
sw_continue:
	
	mov		sw_n,dx
	
	mov		dx,0
	mov		ax,sw_m
	mov		bp,10
	div		bp
	mov		sw_m,ax
	
	dec		cx
	cmp		cx,0
	jnz		sw_do

	cmp		sw_f,0
	jnz		sw_continua2
	mov		[bx],'0'
	inc		bx
sw_continua2:

	mov		byte ptr[bx],0
	ret		
sprintf_w	endp

;
;--------------------------------------------------------------------
;Função	Le um caractere do arquivo identificado pelo HANLDE BX
;		getChar(handle->BX)
;Entra: BX -> file handle
;Sai:   dl -> caractere
;		AX -> numero de caracteres lidos
;		CF -> "0" se leitura ok
;--------------------------------------------------------------------
getChar	proc	near
	mov		ah,3fh
	mov		cx,1
	lea		dx,FileBuffer
	int		21h
	mov		dl,FileBuffer
	ret
getChar	endp

;
;--------------------------------------------------------------------
;Função	Abre o arquivo cujo nome está no string apontado por DX
;		boolean fopen(char *FileName -> DX)
;Entra: DX -> ponteiro para o string com o nome do arquivo
;Sai:   AX -> handle do arquivo
;       CF -> 0, se OK
;--------------------------------------------------------------------
fopen	proc	near
	mov		al,0
	mov		ah,3dh
	int		21h
	ret
fopen	endp

;
;--------------------------------------------------------------------
;Função Cria o arquivo cujo nome está no string apontado por DX
;		boolean fcreate(char *FileName -> DX)
;Sai:   AX -> handle do arquivo
;       CF -> 0, se OK
;--------------------------------------------------------------------
fcreate	proc	near
	mov		cx,0
	mov		ah,3ch
	int		21h
	ret
fcreate	endp

;
;--------------------------------------------------------------------
;Entra:	BX -> file handle
;Sai:	CF -> "0" se OK
;--------------------------------------------------------------------
fclose	proc	near
	mov		ah,3eh
	int		21h
	ret
fclose	endp

;
;--------------------------------------------------------------------
;Função Escrever um string na tela
;		printf_s(char *s -> BX)
;--------------------------------------------------------------------
printf_s	   proc	near
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
printf_s	   endp

;
;--------------------------------------------------------------------
;Função Escrever um char na tela
;		Entra: DL -> Char a ser escrito
;--------------------------------------------------------------------
printf_c	   proc	near
		mov		ah, 2
		int		21H
		ret
printf_c	   endp

;
;--------------------------------------------------------------------
;Entra: BX -> file handle
;       dl -> caractere
;Sai:   AX -> numero de caracteres escritos
;		CF -> "0" se escrita ok
;--------------------------------------------------------------------
setChar	proc	near
	mov		ah,40h
	mov		cx,1
	mov		FileBuffer,dl
	lea		dx,FileBuffer
	int		21h
	ret
setChar	endp

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
atoi	      proc near

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

atoi	      endp

;
;--------------------------------------------------------------------
; Parse commandline in arguments
;--------------------------------------------------------------------
get_commandline	proc	near
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
      lea   di, groupSizeStr
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
      lea   di, base_valid    ; di = base_valid initial adress
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
      mov	FlagError,1
      jmp   skip_space
   
no_arguments:  NOP

      ret
get_commandline   endp

sort_nitrogen_bases  proc  near

      lea   di,nitrogen_bases
      lea   si,s_nitrogen_bases
   s_loop_a:
      cmp   [di], 0
      je    s_loop_t
      cmp   [di], 'a'
      je    s_put_a
      inc   di
   s_put_a:
      mov   [si],'a'
      inc   si 
   s_loop_t:
      cmp   [di], 0
      je    s_loop_c
      cmp   [di], 't'
      je    s_put_t
      inc   di
   s_put_t:
      mov   [si],'t'
      inc   si
   s_loop_c:
      cmp   [di], 0
      je    s_loop_g
      cmp   [di], 'c'
      je    s_put_c
      inc   di
   s_put_c:
      mov   [si],'c'
      inc   si
   s_loop_g:
      cmp   [di], 0
      je    s_loop_plus
      cmp   [di], 'g'
      je    s_put_g
      inc   di
   s_put_g:
      mov   [si],'g'
      inc   si
   s_loop_plus:
      cmp   [di], 0
      je    s_ret
      cmp   [di], '+'
      je    s_put_plus
      inc   di
   s_put_plus:
      mov   [si],'+'
   s_ret:
      ret

sort_nitrogen_bases  endp

count_file_size   proc  near
   inc fileSize
count_file_size

;--------------------------------------------------------------------
		end
;--------------------------------------------------------------------