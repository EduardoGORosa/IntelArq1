; Trabalho Intel

.model small
.stack

.data
ORG 80H             
CMDCNT DB ?          ; COMMAND LINE COUNT
CMDSTR DB 127 DUP(?)  ; COMMAND LINE BUFFER
; --------------------------------------------
; DATA
; --------------------------------------------
CR                          equ     0dh
LF                          equ     0ah

cmdline               db    127   dup(?)
input_file            db    50    dup(?)        ; Nome do arquivo de entrada
output_file           db    50    dup(?)        ; Nome padrão do arquivo de saída
default_output_file   db    'a.out', 0       ; Nome padrão do arquivo de saída
nitrogen_bases        db    5     dup(?)
s_nitrogen_bases      db    6     dup(?)
file_size             dw    0
file_size_str         db    5     dup(?)
base_lines            dw    0
base_a                dw    0
base_c                dw    0
base_t                dw    0
base_g                dw    0
base_plus             db    0
position              dw    0
position_str          dw    5     dup(?)
cur_position          dw    0
cur_position_str      dw    5    dup(?)
base_valid            db    "actg+", 0
error_command_line    db   "Erro na linha de comando", CR, LF, 0
error_command_line_f  db   "Erro no argumento f", CR, LF, 0
error_command_line_o  db   "Erro no argumento o", CR, LF, 0
error_command_line_n  db   "Erro no argumento n", CR, LF, 0
error_command_line_a  db   "Erro no argumento actg", CR, LF, 0
flag_error            db     0
msg_crlf              db    CR, LF, 0
msg_input_file        db    "Nome do arquivo de entrada : ", 0
msg_output_file       db    "Nome do arquivo de saida : ", 0
msg_group_size        db    "Tamanho dos grupos de bases a serem calculados: ", 0
msg_information       db    "Informacoes a serem colocadas no arquivo de saida: ", 0
msg_bases_size_input  db    "Numero de bases no arquivo de entrada: ", 0
msg_group_count       db    "Numero de grupos a serem processados: ", 0
msg_lines_input_file  db    "Numero de linhas do arquivo de entrada que contém bases: ", 0
error_open_file_msg   db    "Erro na abertura do arquivo.", CR, LF, 0
error_read_file_msg   db    "Erro na leitura do arquivo.", CR, LF, 0
error_create_file_msg db   "Erro na criacao do arquivo", CR, LF, 0
error_write_file_msg  db    "Erro na escrita do arquivo", CR, LF, 0
error_unknown_char_msg db    "Erro caractere indevido na leitura do arquivo", CR, LF, 0
loading               db    "Carregando",0
file_handle           dw    0                      ; Handler do arquivo de leitura
file_handle_dst       dw    0                      ; Handler do arquivo de saida
file_buffer           db    0                      ; Buffer de leitura do arquivo
sw_n                  dw    0
sw_f                  db    0
sw_m                  dw    0
base_a_str            db    6 dup (?)   ; Buffer para o contador de 'A' em formato de string
base_c_str            db    6 dup (?)   ; Buffer para o contador de 'C' em formato de string
base_t_str            db    6 dup (?)   ; Buffer para o contador de 'T' em formato de string
base_g_str            db    6 dup (?)   ; Buffer para o contador de 'G' em formato de string
base_at_str           db    6 dup (?)   ; Buffer para o contador de 'G' em formato de string
base_cg_str           db    6 dup (?)   ; Buffer para o contador de 'G' em formato de string
group_size_str        db    5     dup(?)               ; Tamanho do grupo de bases
group_size            db    0
; --------------------------------------------
; SCAN INPUT PARAMETER LINE

.code
.startup
   mov      si, 81h
   mov      ch,0
   mov      cl,es:[80h]      ; PARAMETER COUNT by variable CMDCNT
   call     get_commandline

   lea      bx, msg_crlf
   call     printf_s

   call     sort_nitrogen_bases

   ; Abre o arquivo
   lea      dx, input_file
   call     fopen
   jc       error_open_file      ; If (CF == 1), erro ao abrir o arquivo
   mov      file_handle, ax      ; Salva handle do arquivo

   lea      bx, file_handle
   call     calculate_file_size

   mov      ax, file_size
   lea      bx, file_size_str
   call     sprintf_w

   lea      bx, output_file
   cmp      [bx], 0
   jne       cmd_output_file

default_file:
   lea      dx, default_output_file
   call     fcreate
   jc       error_create_file
   mov      file_handle_dst, ax      ; Salva handle do arquivo
   lea      bx, file_handle_dst
   jmp      loop_read_file

cmd_output_file:
   lea      dx, output_file
   call     fcreate
   jc       error_create_file
   lea      bx, file_handle_dst
   mov      file_handle_dst, ax      ; Salva handle do arquivo
   jmp      loop_read_file

loop_read_file:
      lea   si, s_nitrogen_bases
   set_header_bases:
      cmp   byte ptr [si], 0
      je    start_count 
      cmp   byte ptr [si], 'a'
      je    set_header_a
      cmp   byte ptr [si], 'c'
      je    set_header_c
      cmp   byte ptr [si], 't'
      je    set_header_t
      cmp   byte ptr [si], 'g'
      je    set_header_g
      cmp   byte ptr [si], '+'
      je    set_header_plus
      jmp   start_count

   set_header_a:
      mov   dl, 'A'
      mov   bx, file_handle_dst
      call  set_char
      inc   si
      cmp   byte ptr [si], 0
      je    start_count
      mov   dl, 3bh
      call  set_char
      jmp   set_header_bases
   set_header_c:
      mov   dl, 'C'
      mov   bx, file_handle_dst
      call  set_char
      inc   si
      cmp   byte ptr [si], 0
      je    start_count
      mov   dl, 3bh
      call  set_char
      jmp   set_header_bases
   set_header_t:
      mov   dl, 'T'
      mov   bx, file_handle_dst
      call  set_char
      inc   si
      cmp   byte ptr [si], 0
      je    start_count
      mov   dl, 3bh
      call  set_char
      jmp   set_header_bases
   set_header_g:
      mov   dl, 'G'
      mov   bx, file_handle_dst
      call  set_char
      inc   si
      cmp   byte ptr [si], 0
      je    start_count
      mov   dl, 3bh
      call  set_char
      jmp   set_header_bases

   set_header_plus:
      mov   dl, 'A'
      mov   bx, file_handle_dst
      call  set_char
      mov   dl, 2bh
      call  set_char
      mov   dl, 'T'
      call  set_char
      mov   dl, 3bh
      call  set_char
      mov   dl, 'C'
      call  set_char
      mov   dl, 2bh
      call  set_char
      mov   dl, 'G'
      call  set_char
   start_count:   
      lea     bx, loading
      call    printf_s
      lea     bx, file_size
      mov     cx, [bx]
      lea     bx, group_size
      sub     cx, [bx]
      jl      file_less_than_group
      mov     position, cx
      dec     cur_position
      inc     position
   count_bases:
      inc     cur_position
      mov     bx, file_handle_dst
      mov     cx, cur_position
      cmp     cx, position
      je      close_and_final
      mov     dl, 2eh
      call    printf_c
      mov     dl, CR
      call    set_char
      mov     dl, LF
      call    set_char
      lea     si, s_nitrogen_bases
      mov     base_a, 0
      mov     base_c, 0
      mov     base_t, 0
      mov     base_g, 0
      lea     bx, group_size
      mov     cx, [bx]
      push    cx
      mov     bx, file_handle
      mov     ah, 42h
      sub     cx, cx
      mov     dx, cur_position ; CX:DX=+7
      mov     al, 0h  ; from beginning
      int     21h
      call    get_char
      cmp     dl, 0ah
      je      cr_case
      mov     ah, 42h
      sub     cx, cx
      mov     dx, cur_position ; CX:DX=+7
      mov     al, 0h  ; from beginning
      int     21h
      pop     cx
      jmp     count_bases_loop

      cr_case:
         pop     cx
         inc     position
         inc     cur_position
         inc     base_lines

      count_bases_loop:
         cmp     cx, 0
         je      set_count_bases

         push    cx
         call    get_char
         jc      error_read_file
         cmp     dl, 0
         jz      close_and_final
         mov     al, dl
         ; Check for 'A', 'C', 'T', 'G' and update counters
         cmp     al, 'A'
         je      increment_a
         cmp     al, 'C'
         je      increment_c
         cmp     al, 'T'
         je      increment_t
         cmp     al, 'G'
         je      increment_g
         cmp     al, 0ah
         je      else_count_bases_loop
         
         increment_a:
            pop     cx
            inc     base_a
            dec     cx
            jmp     count_bases_loop

         increment_c:
            pop     cx
            inc     base_c
            dec     cx
            jmp     count_bases_loop

         increment_t:
            pop     cx
            inc     base_t
            dec     cx
            jmp     count_bases_loop

         increment_g:
            pop     cx
            inc     base_g
            dec     cx
            jmp     count_bases_loop
         
         else_count_bases_loop:
            pop     cx
            jmp     count_bases_loop

         error_unknown_char:
            lea   bx, error_unknown_char_msg
            call  printf_s
            mov   flag_error, 1
            jmp   close_and_final

         set_count_bases:
            cmp   byte ptr [si], 0
            je    count_bases 
            cmp   byte ptr [si], 'a'
            je    set_count_a
            cmp   byte ptr [si], 'c'
            je    set_count_c
            cmp   byte ptr [si], 't'
            je    set_count_t
            cmp   byte ptr [si], 'g'
            je    set_count_g
            cmp   byte ptr [si], '+'
            je    set_count_plus
            jmp   count_bases
            ; put base_a in its location in file
            set_count_a:
               mov   ax, base_a
               lea   bx, base_a_str
               call  sprintf_w
               mov   bx, file_handle_dst
               lea   di, base_a_str
               set_count_a_loop:
                  mov   dl, [di]
                  cmp   dl, 0
                  je    end_set_count_a_loop
                  call  set_char
                  inc   di
                  jmp   set_count_a_loop
               end_set_count_a_loop:
                  mov   dl, 3bh
                  call  set_char
                  inc   si
                  jmp   set_count_bases
            set_count_c:
               mov   ax, base_c
               lea   bx, base_c_str
               call  sprintf_w
               mov   bx, file_handle_dst
               lea   di, base_c_str
               set_count_c_loop:
                  mov   dl, [di]
                  cmp   dl, 0
                  je    end_set_count_c_loop
                  call  set_char
                  inc   di
                  jmp   set_count_c_loop
               end_set_count_c_loop:
                  mov   dl, 3bh
                  call  set_char
                  inc   si
                  jmp   set_count_bases
            set_count_t:
               mov   ax, base_t
               lea   bx, base_t_str
               call  sprintf_w
               mov   bx, file_handle_dst
               lea   di, base_t_str
               set_count_t_loop:
                  mov   dl, [di]
                  cmp   dl, 0
                  je    end_set_count_t_loop
                  call  set_char
                  inc   di
                  jmp   set_count_t_loop
               end_set_count_t_loop:
                  mov   dl, 3bh
                  call  set_char
                  inc   si
                  jmp   set_count_bases
            set_count_g:
               mov   ax, base_g
               lea   bx, base_g_str
               call  sprintf_w
               mov   bx, file_handle_dst
               lea   di, base_g_str
               set_count_g_loop:
                  mov   dl, [di]
                  cmp   dl, 0
                  je    end_set_count_g_loop
                  call  set_char
                  inc   di
                  jmp   set_count_g_loop
               end_set_count_g_loop:
                  mov   dl, 3bh
                  call  set_char
                  inc   si
                  jmp   set_count_bases
            set_count_plus:
                  mov   ax, base_a
                  add   ax, base_t
                  lea   bx, base_at_str
                  call  sprintf_w
                  mov   bx, file_handle_dst
                  lea   di, base_at_str
               set_count_at_loop:
                  mov   dl, [di]
                  cmp   dl, 0
                  je    end_set_count_at_loop
                  call  set_char
                  inc   di
                  jmp   set_count_at_loop
               end_set_count_at_loop:
                  mov   dl, 3bh
                  call  set_char
                  mov   ax, base_c
                  add   ax, base_g
                  lea   bx, base_cg_str
                  call  sprintf_w
                  mov   bx, file_handle_dst
                  lea   di, base_cg_str
               set_count_cg_loop:
                  mov   dl, [di]
                  cmp   dl, 0
                  je    end_set_count_plus
                  call  set_char
                  inc   di
                  jmp   set_count_cg_loop
               end_set_count_plus:
                  inc   si
                  jmp   set_count_bases

error_open_file:
      lea   bx, error_open_file_msg
      call  printf_s
      mov   flag_error, 1
      jmp   final

error_read_file:
      lea   bx, error_read_file_msg
      call  printf_s
      mov   flag_error, 1
      jmp   close_and_final

error_create_file:
      lea   bx, error_create_file_msg
      call  printf_s
      mov   flag_error, 1
      jmp   close_and_final

error_write_file:
      lea   bx, error_write_file_msg
      call  printf_s
      mov   flag_error, 1
      jmp   close_and_final

close_and_final:
   lea      bx, msg_crlf
   call     printf_s

   lea      bx, msg_input_file
   call     printf_s
   lea      bx, input_file
   call     printf_s

   lea      bx, msg_crlf
   call     printf_s

   lea      bx, output_file
   cmp      [bx], 0
   je       print_default_outfile

   lea      bx, msg_output_file
   call     printf_s
   lea      bx, output_file
   call     printf_s
   lea      bx, msg_crlf
   call     printf_s

   jmp      close_and_final2

print_default_outfile:

   lea      bx, msg_output_file
   call     printf_s
   lea      bx, default_output_file
   call     printf_s
   lea      bx, msg_crlf
   call     printf_s

close_and_final2:

   lea   bx, msg_group_size
   call  printf_s
   lea   bx, group_size_str
   call  printf_s
   lea   bx, msg_crlf
   call  printf_s
   lea   bx, msg_information
   call  printf_s
   lea   bx, s_nitrogen_bases
   call  printf_s
   lea   bx, msg_crlf
   call  printf_s
   lea   bx, msg_bases_size_input
   call  printf_s
   lea   bx, file_size_str
   call  printf_s
   lea   bx, msg_crlf  
   call  printf_s
   lea   bx, msg_group_count
   call  printf_s
   mov   ax, position
   lea   bx, base_lines
   sub   ax, [bx]
   lea   bx, position_str
   call  sprintf_w
   lea   bx,position_str
   call  printf_s

   jmp   final

   file_less_than_group:
      lea   bx, error_write_file_msg
      call  printf_s
      mov   flag_error,1

final:
      .exit

;
; --------------------------------------------------------------------
; Função: Converte um inteiro (n) para (string)
;        sprintf(string->BX, "%d", n->AX)
; --------------------------------------------------------------------
sprintf_w proc near
   mov   sw_n, ax
   mov   cx, 5
   mov   sw_m, 10000
   mov   sw_f, 0

sw_do:
   mov   dx, 0
   mov   ax, sw_n
   div   sw_m

   cmp   al, 0
   jne   sw_store
   cmp   sw_f, 0
   je    sw_continue
sw_store:
   add   al, '0'
   mov   [bx], al
   inc   bx

   mov   sw_f, 1
sw_continue:

   mov   sw_n, dx

   mov   dx, 0
   mov   ax, sw_m
   mov   bp, 10
   div   bp
   mov   sw_m, ax

   dec   cx
   cmp   cx, 0
   jnz   sw_do

   cmp   sw_f, 0
   jnz   sw_continua2
   mov   [bx], '0'
   inc   bx
sw_continua2:

   mov   byte ptr [bx], 0
   ret
sprintf_w endp

;
; --------------------------------------------------------------------
; Função Le um caractere do arquivo identificado pelo HANDLE BX
; get_char(handle->BX)
; Entra: BX -> file handle
; Sai:   DL -> caractere
; AX -> numero de caracteres lidos
; CF -> "0" se leitura ok
; --------------------------------------------------------------------
get_char proc near
   mov   ah, 3fh
   mov   cx, 1
   lea   dx, file_buffer
   int   21h
   jc    error_read_file
   mov   dl, file_buffer
   ret
get_char endp

;
; --------------------------------------------------------------------
; Função Abre o arquivo cujo nome está no string apontado por DX
; boolean fopen(char *FileName -> DX)
; Entra: DX -> ponteiro para o string com o nome do arquivo
; Sai:   AX -> handle do arquivo
; CF -> 0, se OK
; --------------------------------------------------------------------
fopen proc near
   mov   al, 0
   mov   ah, 3dh
   int   21h
   ret
fopen endp

;
; --------------------------------------------------------------------
; --------------------------------------------------------------------
fseek proc near
   mov   bx, file_handle
   mov   ax, 4200h
   int   21h
   ret
fseek endp

;
; --------------------------------------------------------------------
; Função Cria o arquivo cujo nome está no string apontado por DX
; boolean fcreate(char *FileName -> DX)
; Sai:   AX -> handle do arquivo
; CF -> 0, se OK
; --------------------------------------------------------------------
fcreate proc near
   mov   cx, 0
   mov   ah, 3ch
   int   21h
   ret
fcreate endp

;
; --------------------------------------------------------------------
; Entra: BX -> file handle
; Sai: CF -> "0" se OK
; --------------------------------------------------------------------
fclose proc near
   mov   ah, 3eh
   int   21h
   ret
fclose endp

;
; --------------------------------------------------------------------
; Função Escrever um string na tela
; printf_s(char *s -> BX)
; --------------------------------------------------------------------
printf_s proc near
   mov   dl, [bx]
   cmp   dl, 0
   je    ps_1

   push  bx
   mov   ah, 2
   int   21h
   pop   bx

   inc   bx
   jmp   printf_s

ps_1:
   ret
printf_s endp

;
; --------------------------------------------------------------------
; Função Escrever um char na tela
; Entra: DL -> Char a ser escrito
; --------------------------------------------------------------------
printf_c proc near
   mov   ah, 2
   int   21h
   ret
printf_c endp

;
; --------------------------------------------------------------------
; Entra: BX -> file handle
; dl -> caractere
; Sai: AX -> numero de caracteres escritos
; CF -> "0" se escrita ok
; --------------------------------------------------------------------
set_char proc near
   mov   ah, 40h
   mov   cx, 1
   mov   file_buffer, dl
   lea   dx, file_buffer
   int   21h
   ret
set_char endp

;
; --------------------------------------------------------------------
; Função: Converte um ASCII-DECIMAL para HEXA
; Entra: (S) -> DS:BX -> Ponteiro para o string de origem
; Sai: (A) -> AX -> Valor "Hex" resultante
; Algoritmo:
; A = 0;
; while (*S!='\0') {
; A = 10 * A + (*S - '0')
; ++S;
; }
; return
; --------------------------------------------------------------------
atoi proc near

   ; A = 0;
   mov ax, 0

   atoi_2:
   ; while (*S!='\0') {
   cmp byte ptr [bx], 0
   jz atoi_1

   ; A = 10 * A
   mov cx, 10
   mul cx

   ; A = A + *S
   mov ch, 0
   mov cl, [bx]
   add ax, cx

   ; A = A - '0'
   sub ax, '0'

   ; ++S
   inc bx

   ;}
   jmp atoi_2

   atoi_1:
   ; return
   ret

atoi endp

;
; --------------------------------------------------------------------
; Parse commandline in arguments
; --------------------------------------------------------------------
get_commandline proc near
   cmp cx, 0
   jnz parse_command_line          ; YES - PROCESS COMMAND LINE PARAMETERS
   jmp no_arguments           ; NO - PARAMETERS

parse_command_line:
   skip_space:
      mov al, es:[si]
      cmp al, ' '
      je next_option
      cmp al, CR
      je no_arguments
      inc si
      jmp skip_space

   next_option:
      inc si
      mov al, es:[si]

      ; Verificar se encontramos uma opção válida
      cmp al, '-'
      jne invalid_option

      ; Move string pointer
      inc si
      mov al, es:[si]
      cmp al, CR
      je invalid_option
      cmp al, 'f'
      je f_option
      cmp al, 'o'
      je o_option
      cmp al, 'n'
      je n_option
      jmp base_option

   f_option:
      lea di, input_file
      inc si
      mov al, es:[si]
      cmp al, ' '
      jne invalid_option_f
      f_option_loop:
         inc si
         mov al, es:[si]
         cmp al, ' '
         je skip_space
         cmp al, CR
         je skip_space
         mov [di], al
         inc di
         jmp f_option_loop

   o_option:
      lea di, output_file
      inc si
      mov al, es:[si]
      cmp al, ' '
      jne invalid_option_o
      o_option_loop:
         inc si
         mov al, es:[si]
         cmp al, ' '
         je skip_space
         cmp al, CR
         je skip_space
         mov [di], al
         inc di
         jmp o_option_loop

   n_option:
      lea di, group_size_str
      inc si
      mov al, es:[si]
      cmp al, ' '
      jne invalid_option_n
      n_option_loop:
         inc si
         mov al, es:[si]
         cmp al, ' '
         je end_n_option
         cmp al, CR
         je end_n_option
         cmp al, 39h
         jg invalid_option_n
         cmp al, 30h
         jl invalid_option_n
         mov [di], al
         inc di
         jmp n_option_loop
      end_n_option:
         mov      [di], 0
         jmp      skip_space

   base_option:
      lea di, base_valid    ; di = base_valid initial adress
      lea bx, nitrogen_bases
      cmp al, ' '           ; if space invalid
      je invalid_option_a
      cmp al, CR            ; if cr invalid
      je invalid_option_a
   base_check_loop:
      lea di, base_valid    ; di = base_valid initial adress
      mov al, es:[si]       ; al = cmdline char
      cmp al, ' '           ; if space base_cmd ended
      je done_parsing_base
      cmp al, CR            ; if cr base_cmd ended
      je done_parsing_base
   base_valid_loop:
      cmp byte ptr [di], 0
      je invalid_option_a
      mov cl, [di]
      cmp cl, al
      je valid_base
      inc di
      jmp base_valid_loop

valid_base:
      mov [bx], al
      inc bx
      inc si
      jmp base_check_loop

done_parsing_base:
      jmp      skip_space

invalid_option:
      lea bx, error_command_line
      call printf_s
      mov flag_error, 1
      .exit
invalid_option_f:
      lea bx, error_command_line_f
      call printf_s
      mov flag_error, 1
      .exit
invalid_option_o:
      lea bx, error_command_line_o
      call printf_s
      mov flag_error, 1
      .exit
invalid_option_n:
      lea bx, error_command_line_n
      call printf_s
      mov flag_error, 1
      .exit
invalid_option_a:
      lea bx, error_command_line_n
      call printf_s
      mov flag_error, 1
      .exit

no_arguments:
      lea      bx, group_size_str
      call     atoi
      lea      bx, group_size
      mov      [bx], ax
      cmp      ax, 0
      je       invalid_option
      ret
get_commandline endp

;
; --------------------------------------------------------------------
; Sort nitrogen bases command line parameter
; --------------------------------------------------------------------
sort_nitrogen_bases  proc  near

      lea   di,nitrogen_bases
      lea   si,s_nitrogen_bases
   s_loop_a:
      mov   dl, [di]
      cmp   dl, 0
      je    end_put_a
      cmp   dl, 'a'
      je    s_put_a
      inc   di
      jmp   s_loop_a
   s_put_a:
      mov   [si],'a'
      inc   si 
   end_put_a:
      lea   di,nitrogen_bases
   s_loop_t:
      mov   dl, [di]
      cmp   dl, 0
      je    end_put_t
      cmp   dl, 't'
      je    s_put_t
      inc   di
      jmp   s_loop_t
   s_put_t:
      mov   [si],'t'
      inc   si
   end_put_t:
      lea   di,nitrogen_bases
   s_loop_c:
      mov   dl, [di]
      cmp   dl, 0
      je    end_put_c
      cmp   dl, 'c'
      je    s_put_c
      inc   di
      jmp   s_loop_c
   s_put_c:
      mov   [si],'c'
      inc   si
   end_put_c:
      lea   di,nitrogen_bases
   s_loop_g:
      mov   dl, [di]
      cmp   dl, 0
      je    end_put_g
      cmp   dl, 'g'
      je    s_put_g
      inc   di
      jmp   s_loop_g
   s_put_g:
      mov   [si],'g'
      inc   si
   end_put_g:
      lea   di, nitrogen_bases
   s_loop_plus:
      mov   dl, [di]
      cmp   dl, 0
      je    s_ret
      cmp   dl, '+'
      je    s_put_plus
      inc   di
      jmp   s_loop_plus
   s_put_plus:
      mov   [si],'+'
   s_ret:
      ret
sort_nitrogen_bases endp


; Função para calcular o tamanho de caracteres no arquivo lido
; Entrada: BX -> file handle
; Saída: DX:AX -> tamanho do arquivo em caracteres

calculate_file_size proc near
   xor ax, ax        ; Inicialize AX com 0
   xor cx, cx        ; Inicialize CX com 0 para usar como contador

cfs_read_loop:
   mov   bx, file_handle
   call  get_char
   jc    error_read_file
   cmp   ax, 0
   jz    end_of_file
   cmp   dl, 'A'
   je    inc_file_size
   cmp   dl, 'G'
   je    inc_file_size
   cmp   dl, 'C'
   je    inc_file_size
   cmp   dl, 'T'
   je    inc_file_size
   cmp   dl, CR
   je    loop_file_size
   cmp   dl, LF
   je    loop_file_size
   jmp   error_unknown_char
   inc_file_size:
   inc   file_size
   loop_file_size:
   jmp   cfs_read_loop

end_of_file:
   ret
calculate_file_size endp

; --------------------------------------------------------------------
; Print a formatted message with a carriage return and line feed
; --------------------------------------------------------------------
printf_crlf proc near
   lea bx, msg_crlf
   call printf_s
   ret
printf_crlf endp

; --------------------------------------------------------------------
; Print a formatted message with a line feed
; --------------------------------------------------------------------
printf_lf proc near
   mov bx, LF
   call printf_s
   ret
printf_lf endp

; --------------------------------------------------------------------
; Print a formatted message with a carriage return
; --------------------------------------------------------------------
printf_cr proc near
   mov bx, CR
   call printf_s
   ret
printf_cr endp

; --------------------------------------------------------------------
; Print a formatted message followed by a carriage return and line feed
; --------------------------------------------------------------------
printf_crlf_s proc near
   call printf_s
   call printf_crlf
   ret
printf_crlf_s endp

; --------------------------------------------------------------------
; Function: Clear the command line buffer
; --------------------------------------------------------------------
clear_cmdline_buffer proc near
   mov di, offset cmdline
   mov cx, 128
   xor al, al
   rep stosb
   ret
clear_cmdline_buffer endp

end

