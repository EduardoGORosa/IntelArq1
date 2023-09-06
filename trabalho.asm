;             Trabalho Intel
;
;         Eduardo Rosa   00335503

        .model small
        .stack

CR					equ		0dh
LF					equ		0ah
FileHandleSaida		equ		".res"

        .data

FileName				db		256 dup (?)				; Nome do arquivo a ser lido
FileNameDst				db		50	dup(0)				; Nome do arquivo a ser escrito
FileBuffer				db		0 						; Buffer de leitura do arquivo
FileHandle				dw		0						; Handler do arquivo de leitura
FileHandleDst			dw		0						; Handler do arquivo de saida
FileNameBuffer			db		150 dup (?)

MsgAskFile				db		"Nome do arquivo: ", 0
ErrorOpenFileMsg		db		"Erro na abertura do arquivo.", CR, LF, 0
ErrorReadFileMsg		db		"Erro na leitura do arquivo.", CR, LF, 0
ErrorCreateFileMsg		db		"Erro na criacao do arquivo", CR, LF, 0
ErrorWriteFileMsg		db		"Erro na escrita do arquivo", CR, LF, 0
ErrorCommandLineMsg		db		"Erro na escrita da linha de comando", CR, LF, 0
MsgCRLF					db		CR, LF, 0

MsgCountA				db		"Count of 'A': ", 0
MsgCountC				db		"Count of 'C': ", 0
MsgCountT				db		"Count of 'T': ", 0
MsgCountG				db		"Count of 'G': ", 0

SomaCol1			db		0
SomaCol2			db		0
SomaCol3			db		0
SomaCol4			db 		0
Contador			db		0
Contador2			dw		0
TotalBytes			dw 		0
;TODO		Fazer TotalBytes2 funcionar
TotalBytes2			db		0	
VetorHexa			dw		"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"
FlagError				db		0
BufferWRWORD			db		20 dup (?)
sw_n					dw		0
sw_f					db		0
sw_m					dw		0
BufferChar				db		0
BufferPutChar				db		0

A_Count     			db 		0
C_Count     			db 		0
T_Count     			db 		0
G_Count     			db 		0
A_CountStr	db		6 dup (?)   ; Buffer para o contador de 'A' em formato de string
C_CountStr	db		6 dup (?)   ; Buffer para o contador de 'C' em formato de string
T_CountStr	db		6 dup (?)   ; Buffer para o contador de 'T' em formato de string
G_CountStr	db		6 dup (?)   ; Buffer para o contador de 'G' em formato de string

commandLine db 1000 dup(?)   ; Buffer para armazenar a linha de comando
inputFile db 50 dup(?)     ; Nome do arquivo de entrada
outputFile db 'a.out',0       ; Nome padrão do arquivo de saída
groupSize dw 0               ; Tamanho do grupo de bases
options db 1000 dup(?)      ; Opções da linha de comando
argc dw 0                    ; Contagem de argumentos da linha de comando
argv dw 0                    ; Ponteiro para argumentos da linha de comando

        .code
        .startup

		mov ah,62h
		int 21h
		mov si, offset bx:80H
		mov al, [si]

		
		jmp Final
LoopReadFile:
    mov bx, FileHandle
    call getChar
    jc  ErrorReadFile
    cmp ax, 0
    jz  CloseAndFinal
    mov BufferChar, dl
    mov al, dl
    ;call putChar
	call printf_c
    ; Check for 'A', 'C', 'T', 'G' and update counters
    cmp al, 'A'
    je  IncrementA
    cmp al, 'C'
    je  IncrementC
    cmp al, 'T'
    je  IncrementT
    cmp al, 'G'
    je  IncrementG
    jmp LoopReadFile

IncrementA:
    inc A_Count
    jmp LoopReadFile

IncrementC:
    inc C_Count
    jmp LoopReadFile

IncrementT:
    inc T_Count
    jmp LoopReadFile

IncrementG:
    inc G_Count
	jmp LoopReadFile

ErrorOpenFile:
		lea		bx,ErrorOpenFileMsg
		call	printf_s
		mov		FlagError,1
		jmp		Final

ErrorReadFile:
		lea		bx, ErrorReadFileMsg
		call	printf_s
		mov		FlagError, 1
		jmp		CloseAndFinal

ErrorCreateFile:
		lea		bx, ErrorCreateFileMsg
		call	printf_s
		mov		FlagError, 1
		jmp		CloseAndFinal

ErrorWriteFile:
		lea 	bx, ErrorWriteFileMsg
		call	printf_s
		mov		FlagError, 1
		jmp		CloseAndFinal

CloseAndFinal:

    ; Display counts of 'A', 'C', 'T', 'G'
    ; Após incrementar cada contador (IncrementA, IncrementC, IncrementT, IncrementG), converta o valor para string

	; convert A to string
	mov al, A_Count
	mov bx, offset A_CountStr
	call sprintf_w

	; convert C to string
	mov al, C_Count
	mov bx, offset C_CountStr
	call sprintf_w

	; convert T to string
	mov al, T_Count
	mov bx, offset T_CountStr
	call sprintf_w

	; convert G to string
	mov al, G_Count
	mov bx, offset G_CountStr
	call sprintf_w

	; Breakline
	lea		bx,MsgCRLF
	call	printf_s

	; Print A message and A counter
	lea bx, MsgCountA
	call printf_s
	lea bx, A_CountStr
	call printf_s

	; Breakline
	lea		bx,MsgCRLF
	call	printf_s

	; Print C message and C counter
	lea bx, MsgCountC
	call printf_s
	lea bx, C_CountStr
	call printf_s

	; Breakline
	lea		bx,MsgCRLF
	call	printf_s

	; Print T message and T counter
	lea bx, MsgCountT
	call printf_s
	lea bx, T_CountStr
	call printf_s

	; Breakline
	lea		bx,MsgCRLF
	call	printf_s

	; Print G message and G counter
	lea bx, MsgCountG
	call printf_s
	lea bx, G_CountStr
	call printf_s
Final:
		.exit

;
;--------------------------------------------------------------------
;Funcao: Parse command line
;--------------------------------------------------------------------
parse_command_line proc near
    mov si, offset commandLine
    mov ax, [si]  ; Inicialmente, al aponta para o primeiro caractere da linha de comando

    ; Pule o nome do programa
    find_space:
        inc si
        mov ax, [si]
        cmp ax, ' '
        jne find_space
        mov bx, si
        call sprintf_w
        mov dx, ax
        call printf_c

    next_option:
        inc si
        mov ax, [si]

        ; Verificar se encontramos uma opção válida
        cmp ax, '-'
        jne invalid_option

		; Move string pointer
		inc si
		mov ax, [si]
        ; mov dl, al
        ; call printf_c

		cmp ax, 'f'
        je f_option
		cmp ax, 'o'
        je o_option
		cmp ax, 'n'
        je n_option
        jmp actg_option

	f_option:

		jmp find_space

	o_option:

		jmp find_space

	n_option:

		jmp find_space

	actg_option:

        jmp done_parsing

    invalid_option:
        lea		bx,ErrorCommandLineMsg
		call	printf_s
		mov		FlagError,1

    done_parsing:
        ret

parse_command_line endp

;
;--------------------------------------------------------------------
;Funcao: Le o nome do arquivo do teclado
;--------------------------------------------------------------------
GetFileName	proc	near
		lea		bx,MsgAskFile			; Coloca mensagem que pede o nome do arquivo
		call	printf_s

		mov		ah,0ah						; Le uma linha do teclado
		lea		dx,FileNameBuffer
		mov		byte ptr FileNameBuffer,100
		int		21h

		lea		si,FileNameBuffer+2			; Copia do buffer de teclado para o FileName
		lea		di,FileName
		mov		cl,FileNameBuffer+1
		mov		ch,0
		mov		ax,ds						; Ajusta ES=DS para poder usar o MOVSB
		mov		es,ax
		rep 	movsb

		mov		byte ptr es:[di],0			; Coloca marca de fim de string
		ret
GetFileName	endp

;
;--------------------------------------------------------------------
;Função Escrever um string na tela
;		printf_s(char *s -> BX)
;--------------------------------------------------------------------
printf_s	proc	near
	mov		dl,[bx]
	cmp		dl,0
	je		ps_1

	push	bx
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
;Função pra pegar o nome do arquivo saida
;--------------------------------------------------------------------
pegaNome	proc	near
	LoopPegaNome:
		lea		bx, FileName
		mov		cx,	Contador2
		add		bx, cx
		mov		al, [bx]
		cmp		al, 0
		je		FimPegaNome
		cmp		al,	2eh
		je		FimPegaNome
		lea		bx, FileNameDst
		mov		cx,	Contador2
		add		bx, cx
		mov		[bx], al
		inc		Contador2
		jmp		LoopPegaNome

	FimPegaNome:
		lea		bx, FileNameDst
		mov		cx,	Contador2
		add		bx,	cx
		mov		[bx], 2eh
		inc		bx
		mov		[bx], 52h
		inc		bx
		mov		[bx], 65h
		inc		bx
		mov		[bx], 73h
		ret
pegaNome	endp
;--------------------------------------------------------------------
		end
;--------------------------------------------------------------------