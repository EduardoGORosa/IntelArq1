Microsoft (R) Macro Assembler Version 6.11		    09/05/23 17:40:11
teste.asm						     Page 1 - 1



 0000				COMSEG SEGMENT PARA PUBLIC 'CODE'
				ASSUME CS:COMSEG,DS:COMSEG,ES:COMSEG,SS:COMSEG

 = 000D				CR					      equ		0dh
 = 000A				LF					      equ		0ah

				ORG 80H             
 0080 00			CMDCNT DB ?          ;COMMAND LINE COUNT
 0081  0050 [			CMDSTR DB 80 DUP(?)  ;COMMAND LINE BUFFER
        00
       ]
				   
 00D1				START PROC FAR
 00D1  E9 010A			       JMP ENTRY     ;JUMP PASS DATA
				;--------------------------------------------
 00D4  007F [			cmdline db  127 dup(?)
        00
       ]
 0153  0032 [			SrcFileName				db		50 dup (?)				; Nome do arquivo a ser lido
        00
       ]
 0185  0032 [			DstFileName			   db		50	dup(?)				; Nome do arquivo a ser escrito
        00
       ]
 01B7 45 72 72 6F 20 6E		ErrorCommandLineMsg	db		"Erro na escrita da linha de comando", CR, LF, 0
       61 20 65 73 63 72
       69 74 61 20 64 61
       20 6C 69 6E 68 61
       20 64 65 20 63 6F
       6D 61 6E 64 6F 0D
       0A 00
 01DD 00			FlagError				db		0
				;--------------------------------------------

				;SCAN INPUT PARAMETER LINE

 01DE				ENTRY:  
 01DE  BE 0081 R		   MOV      SI,OFFSET CMDSTR ;STRING
 01E1  8D 3E 00D4 R		   lea      DI, cmdline
				       
 01E5  B5 00			   MOV      CH,0
 01E7  26: 8A 0E 0080		   MOV      CL,ES:[80h]      ;PARAMETER COUNT by variable CMDCNT
 01EC  83 F9 00			   CMP      CX,0
 01EF  75 02			   JNZ      get_command_line          ;YES - PROCESS COMMAND LINE PARAMETERS
 01F1  EB 08			   JMP      no_arguments           ;NO - PARAMETERS
				   
 01F3				get_command_line:   
 01F3  8A 04			   MOV      al,[SI]
 01F5  88 05			   mov      [di],al

 01F7  46			   inc      si
 01F8  47			   inc      di             ;INCREMENT STRING
 01F9  E2 F8			   LOOP     get_command_line
				   
 01FB  90			no_arguments:  NOP

				;START OF MAIN PROGRAM
 01FC  8D 1E 00D4 R		   lea		bx,cmdline			; Coloca mensagem que pede o nome do arquivo
 0200  E8 004A			   call	   printf_s    

 0203  E8 0006			   call     parse_command_line


				;RETURN TO DOS
 0206				DONE: 
 0206  1E			   PUSH     DS
 0207  B8 0000			   MOV      AX,0
 020A  50			   PUSH     AX
 020B  CB			   RET
 020C				START ENDP

				;
				;--------------------------------------------------------------------
				; Parse command line string
				;--------------------------------------------------------------------
 020C				parse_command_line proc near
 020C  8D 36 00D4 R		    lea     si, offset cmdline

				    ; go to next arg
 0210				    find_space:
 0210  8A 04			      mov   al, [si]
 0212  3C 20			      cmp   al, ' '
 0214  74 03			      je    next_option
 0216  46			      inc   si
 0217  EB F7			      jmp   find_space

 0219				    next_option:
 0219  46			      inc   si
 021A  8A 04			      mov   al, [si]

				        ; Verificar se encontramos uma opção válida
 021C  3C 2D			      cmp   al, '-'
 021E  75 20			      jne   invalid_option

						; Move string pointer
 0220  46					inc   si
 0221  8A 04					mov   al, [si]
				        ; mov dl, al
				        ; call printf_c

 0223  3C 66					cmp   al, 'f'
 0225  74 0A			      je    f_option
 0227  3C 6F					cmp   al, 'o'
 0229  74 0F			      je    o_option
 022B  3C 6E					cmp   al, 'n'
 022D  74 0D			      je    n_option
 022F  EB 0D			      jmp   actg_option

 0231					f_option:
 0231  8D 1E 01B7 R		      lea   bx,ErrorCommandLineMsg
 0235  E8 0015			      call  printf_s
 0238  EB D6				   jmp   find_space

 023A					o_option:

 023A  EB D4				   jmp   find_space

 023C					n_option:

 023C  EB D2				   jmp   find_space

 023E					actg_option:

 023E  EB 0C			      jmp   done_parsing

 0240				    invalid_option:
 0240  8D 1E 01B7 R		      lea   bx,ErrorCommandLineMsg
 0244  E8 0006			      call  printf_s
 0247  C6 06 01DD R 01		      mov	FlagError,1

 024C				    done_parsing:
 024C  C3			      ret

 024D				parse_command_line endp

				;
				;--------------------------------------------------------------------
				;Função Escrever um string na tela
				;		printf_s(char *s -> BX)
				;--------------------------------------------------------------------
 024D				printf_s	proc	near
 024D  8A 17				mov		dl,[bx]
 024F  80 FA 00				cmp		dl,0
 0252  74 09				je		ps_1

 0254  53				push	bx
 0255  B4 02				mov		ah,2
 0257  CD 21				int		21H
 0259  5B				pop		bx

 025A  43				inc		bx		
 025B  EB F0				jmp		printf_s
						
 025D				ps_1:
 025D  C3				ret
 025E				printf_s	endp

				;
				;--------------------------------------------------------------------
				;Função Escrever um char na tela
				;		Entra: DL -> Char a ser escrito
				;--------------------------------------------------------------------
 025E				printf_c	proc	near
 025E  B4 02					mov		ah, 2
 0260  CD 21					int		21H
 0262  C3					ret
 0263				printf_c	endp

 0263				COMSEG ENDS

				END START
Microsoft (R) Macro Assembler Version 6.11		    09/05/23 17:40:11
teste.asm						     Symbols 2 - 1




Segments and Groups:

                N a m e                 Size     Length   Align   Combine Class

COMSEG . . . . . . . . . . . . .	16 Bit	 0263	  Para	  Public  'CODE'	


Procedures,  parameters and locals:

                N a m e                 Type     Value    Attr

START  . . . . . . . . . . . . .	P Far	 00D1	  COMSEG	Length= 013B Private
parse_command_line . . . . . . .	P Near	 020C	  COMSEG	Length= 0041 Private
printf_c . . . . . . . . . . . .	P Near	 025E	  COMSEG	Length= 0005 Private
printf_s . . . . . . . . . . . .	P Near	 024D	  COMSEG	Length= 0011 Private


Symbols:

                N a m e                 Type     Value    Attr

CMDCNT . . . . . . . . . . . . .	Byte	 0080	  COMSEG	
CMDSTR . . . . . . . . . . . . .	Byte	 0081	  COMSEG	
CR . . . . . . . . . . . . . . .	Number	 000Dh	 
DONE . . . . . . . . . . . . . .	L Near	 0206	  COMSEG	
DstFileName  . . . . . . . . . .	Byte	 0185	  COMSEG	
ENTRY  . . . . . . . . . . . . .	L Near	 01DE	  COMSEG	
ErrorCommandLineMsg  . . . . . .	Byte	 01B7	  COMSEG	
FlagError  . . . . . . . . . . .	Byte	 01DD	  COMSEG	
LF . . . . . . . . . . . . . . .	Number	 000Ah	 
SrcFileName  . . . . . . . . . .	Byte	 0153	  COMSEG	
actg_option  . . . . . . . . . .	L Near	 023E	  COMSEG	
cmdline  . . . . . . . . . . . .	Byte	 00D4	  COMSEG	
done_parsing . . . . . . . . . .	L Near	 024C	  COMSEG	
f_option . . . . . . . . . . . .	L Near	 0231	  COMSEG	
find_space . . . . . . . . . . .	L Near	 0210	  COMSEG	
get_command_line . . . . . . . .	L Near	 01F3	  COMSEG	
invalid_option . . . . . . . . .	L Near	 0240	  COMSEG	
n_option . . . . . . . . . . . .	L Near	 023C	  COMSEG	
next_option  . . . . . . . . . .	L Near	 0219	  COMSEG	
no_arguments . . . . . . . . . .	L Near	 01FB	  COMSEG	
o_option . . . . . . . . . . . .	L Near	 023A	  COMSEG	
ps_1 . . . . . . . . . . . . . .	L Near	 025D	  COMSEG	

	   0 Warnings
	   0 Errors
