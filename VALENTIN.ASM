TITLE                  VALENTINE
;-------------------------------------------------------------------------------
;           			 Valentine
; make a programm which:
; - prints a box with a message
; - make it from input symbols
; - make animation
; - make text on different strings
;-------------------------------------------------------------------------------

.model tiny										;allocate 64KB of memory
.code	 										;set data to code type
.286	 										;include assembler's library
org 100h	 									;set ip to 256 in dec (100h hex)
locals @@										;call local functions

SCREEN_LENGTH 			equ 80d					;length of screen
SCREEN_HIGHT  			equ 25d					;hight of screen
;FRAME_COLOR   			equ 00001100b       	;pink(rework as inputed)
VIDEOSEG	  			equ 0b800h	 			;BIOS segment
CMD_INPUT	 			equ 81h	 				;ip of cmd
DEFAULT_COLOR			equ 07h

Start:					mov si, CMD_INPUT		;set si to the adress of cmd
						mov ax, 0600h 			;choose scrolling int
						mov bh, 07				;set normal color
						xor cx, cx				;upper left corner
						mov dx, 184fh			;lower right corner
						int 10h					;call int

						call dec_input_to_hex   ;read length
						and dx, 11111110b
						mov [a], dx

						call dec_input_to_hex	;read hight
						and dx, 11111110b
						inc dx
						mov [b], dx

						call bin_input_to_hex	;read color
						mov [color], dx

						call dec_input_to_hex   ;read frame_type
						mov [frame_type], dx	;set frame_type
						push dx
						xor ax, ax
						cmp dx, ax
						jne @@check2			;if dx != 0, dont scan for symbols

						call space_skipper
						lea di, [CUSTOM_FRAME]	;di = adress of string where the frame elments will be inserted
						mov cx, 9
;--------------------------------------
@@write_da_string:		lodsb					;save elem to al
						stosb					;take from al and put into [di]
						;mov ax, 0
						;cmp cx, ax
						loop @@write_da_string	;read and write 9 symbols
;--------------------------------------
@@check2:				call space_skipper

						xor bx, bx
						lea di, [STRING]		;di = adress of string where the message will be inserted
@@reader:				lodsb
						mov dl, 24h
						cmp al, dl
						je @@exit
						stosb
						inc bx
						jmp @@reader


@@exit:					mov [str_len], bx

						mov ax, 7
						mov bx, 7
						dec ax
						dec bx

@@animation:			int 03h
						inc ax
						inc bx
						cmp ax, [a]
						ja @@length_decreaser
						jmp @@check_b

@@length_decreaser:		dec ax
						jmp @@check_b

@@check_b:				cmp bx, [b]
						ja @@hight_decreaser
						jmp @@frame_printer

@@hight_decreaser:		dec bx
						jmp @@frame_printer


@@frame_printer:		push ax
						push bx
						push ax
						push bx
						xor ax, ax
						xor bx, bx
						call make_frame
						add sp, 4d

						mov ax, 8600h
						xor cx, cx
						mov dx, 0c350h

						int 15h

						pop bx
						pop ax
						cmp ax, [a]
						je @@check_b2
						jmp @@animation

@@check_b2:				cmp bx, [b]
						je @@print_text
						jmp @@animation

@@print_text:			call print_text

						mov ax, 4c00h			;end programm ( interupt 21 )
						int 21h


;-------------------------------------------------------------------------------
;space_skipper
;-------------------------------------------------------------------------------
;Entry: None
;Exit: None
;-------------------------------------------------------------------------------

space_skipper			proc
						dec si	 			;now al is on the -1 symbol of cmd
@@cycle_to_skip_spaces:	inc si	 			;al = 0 symbol of cmd
						mov ax, [si]       	;set ax to symbol of cmd
						mov dl, 20h	 		;dl = ascii of ' '
						cmp al, dl			;if al == dl scip ' '
						je @@cycle_to_skip_spaces

						ret
						endp
;-------------------------------------------------------------------------------
;dec_input_to_hex:		scans arguments of cmd from dec to hex
;-------------------------------------------------------------------------------
;Entry: None
;Exit: DX
;BALL TORTURE REGISTERS: AX, DX, SI
;-------------------------------------------------------------------------------

dec_input_to_hex		proc
						xor dx, dx 			;register for return number
						call space_skipper
						xor dx, dx

@@get_number_from_cmd:	push dx				;save dx

						mov ax, [si]	 	     	;take a symbol from cmd after the space
                        xor ah, ah			;after taking a number from cmd to register
											;we recieve ax = ah al, al = first symbol, ah = the symbol
											;after the first symbol, so we clear the trash part
											;of the register
						mov dx,30h			;dx = ascii of '0'
						cmp ax, dx
						jae @@check2	 	;if symbol>=0: jmp next check, else jmp to exit
						jmp @@final_result
@@check2:				mov dx,38h			;if symbol<=9;jmp adding
						cmp ax, dx
						jbe @@adding_to_result
						jmp @@final_result
@@adding_to_result:		mov dx,30h			;dx = ascii of '0'
						sub ax, dx			;ax = the number in dec numeric system
                        pop dx				;return the old sum
						push ax	 			;\
						mov ax, dx	 		; \
						mov dx, 10d			;  |new sum = old sum * 10 + new number
						mul dx				;  |
						mov dx, ax			; /
						pop ax				;/
						add dx, ax
						inc si
						jmp @@get_number_from_cmd
@@final_result:         pop dx
                        ret
						endp
;-------------------------------------------------------------------------------
;bin_input_to_hex:  scans arguments of cmd from bin to hex
;-------------------------------------------------------------------------------
;Entry: None
;Exit: DX
;BALL TORTURE REGISTERS: AX, DX, SI
;-------------------------------------------------------------------------------
bin_input_to_hex		proc
						xor dx, dx 			;register for return number
						call space_skipper
						xor dx, dx

@@scanner:				push dx
						mov ax, [si]
						xor ah, ah
						mov dx, 30h
						sub ax, dx
						mov dx, 1d	 		;if dx != 1 jmp check 2
						cmp ax, dx
						jne @@check2
						je @@adding_to_number
@@check2:				xor dx, dx	 		;if dx != 0 jmp exit
						cmp ax, dx
						je @@adding_to_number
						jmp @@exit
@@adding_to_number:		pop dx
						shl dx, 1			;if dx = 0 or 1
						add dx, ax	 		;new sum = old sum*2 + new number
						inc si
						jmp @@scanner

@@exit:					pop dx

						ret
						endp

;-------------------------------------------------------------------------------
;make_frame:	    plays animation of opening a message
;-------------------------------------------------------------------------------
;Entry: legth, hight, color, type of frame, user frame elems, message
;Exit: frame printed in commander
;BALL TORTURE REGISTERS:
;-------------------------------------------------------------------------------
make_frame				proc
						push bp
						mov bp, sp
						;mov dx, [bp+4d]	     ;dx = type of frame
						;mov cx, [bp+6d]		 ;cx = frame color
						mov bx, [bp+4d]		 ;bx= current hight
						mov ax, [bp+6d]     ;ax=current length
						and ax, 11111110b
						and bx, 11111110b
						inc bx


						;push ax
						;push cx
						;push dx
						;mov ax, 8600h
						;mov cx, 0003h
						;mov dx, 0d090h
						;int 15h
						;pop dx
						;pop cx
						;pop ax

						call print_frame
						;add sp, 4d

						mov sp, bp
						pop bp
						ret
						endp
;-------------------------------------------------------------------------------
; print_frame:		prints frame from 9 elements
;-------------------------------------------------------------------------------
;Entry:
;Exit: 		   None
;BALL TORTURE REGISTERS:   BX, DX, SI, BP, SP
;-------------------------------------------------------------------------------
print_frame		proc
			push ax				;save ax = length
			push bx	 			;save bx = hight
			;push dx	 			;save dx = type of frame
			call get_location	;es = videoseg, bx = location
			;pop dx	 			;return dx
			pop bx	 			;return bx
			pop ax				;return ax
			;push ax
			;push bx
			;push cx

			mov dx, 0
			cmp [frame_type], dx
			jne @@check2
			lea si, [CUSTOM_FRAME]
			jmp @@exit

@@check2:	mov dx, 1
			cmp [frame_type], dx
			jne @@check3
			lea si, [TYPE1]
			jmp @@exit

@@check3:	lea si, [TYPE2]
			jmp @@exit

@@exit:		push ax
			push bx
			push [si]   		;0c9h left corner
			push [si+1] 		;0cdh between corners
			push [si+2] 		;0bbh right corner
			call make_string
			add sp, 6d		;set sp correctly
			pop bx
			pop ax
			;pop cx
			;pop bx
			;pop ax

			mov dx, bx		; -2 because of corners
			sub dx, 2d

@@string_printer:			;saving cycles amount
			;push ax
			;push bx
			;push cx
			push ax
			push [si+3]		;0bah left border
			push [si+4]		;0h   middle space
			push [si+5]		;0bah right border
			call make_string
			add sp, 6d		;set sp correctly
			pop ax
			;pop cx
			;pop bx
			;pop ax

			dec dx
			cmp dx, 0		;cycle
			ja @@string_printer

			push ax
			push [si+6]		;0c8h left down corner
			push [si+7]		;0cdh down border
			push [si+8]		;0bch right down corner
			call make_string
			add sp, 6d		;set sp correctly
			pop ax

			ret
			endp
;-------------------------------------------------------------------------------
;symbol_printer:	prints given symbol
;***takes symbol from stack, using stosw sets symbol as given and color as
;   FRAME_COLOR
;-------------------------------------------------------------------------------
;Entry: symbol
;Exit: none
;BALL TORTURE REGISTERS: AX, BP, SP, CX
;-------------------------------------------------------------------------------
symbol_printer		proc
			push bp
			mov bp, sp
			mov al, [bp+6d]  ;prints inputed symbol
			mov cx, [bp+4d]  ;sets symbol color
			mov ah, cl
			stosw

			mov sp, bp		 ;return sp's value
			pop bp			 ;return bp's value

			ret
			endp
;-------------------------------------------------------------------------------
;get_location:		gets location if the left up corner of frame
;***sets es as B800, calculating adress of top left corner:
;   adress = (80*y*2 + x*2), x = (screen_length - frame length) / 2,
;		   |	 |   y = (screen hight - frame_hight) / 2
;		(multipl by 2 because the first byte is for symbol and second
;		 is for cell's color
;-------------------------------------------------------------------------------
;Entry:None
;Exit:BX
;BALL TOTURE REGISTERS: AX, DI, DX, ES
;-------------------------------------------------------------------------------
get_location		proc
			push ax			;save length-------------------------------------
			push bx			;save hight---------------------------			|
			mov ax, VIDEOSEG			;set segment to B800	 |			|
			mov es, ax		;es = ax = B800	 					 |			|
																;|			|
			push SCREEN_HIGHT	;------------------\			 |			|
			pop ax				;ax = 25d 			\			 |			|
			;mov bx, [b]  			;bx = frame hight 	 \		 |			|
			pop bx;-----------------------------------------------			|
			sub ax, bx      	;					   -calculate y	 		|
			mov dx, SCREEN_LENGTH	;dx = 80d		 /						|
			mul dx				;					/						|
			mov di, ax			;------------------/						|
																		   ;|
			push SCREEN_LENGTH	;------------------\						|
			pop ax				;					calculate x-------------
			;mov bx, [a] 				;bx = frame length /
			pop bx
			sub ax, bx			;------------------|
			;and ax, 011111110b

			add di, ax		;final coords

			ret
			endp
;-------------------------------------------------------------------------------
;find_gap: 	find the gap between strings
;***basically its just (screen length - frame length)*2
;-------------------------------------------------------------------------------
;Entry: None
;Exit: None
;BALL TORTURE REGISTERS: AX, CX
;-------------------------------------------------------------------------------
find_gap		proc
			mov cx, SCREEN_LENGTH
			sub cx, ax
			mov ax, cx
			;mov ax, SCREEN_LENGTH-MY_LENGTH

			shl ax, 1		;== ax*2

			ret
			endp
;-------------------------------------------------------------------------------
;make_string:    	makes string from character
;*** receives 3 symbols: left symbol, middle symbol ( which will be repeated
;   for (frame_length - 2 ) times and right symbol, prints left symbol using
;   "symbol printer", then printing middle one using cycle and then right symbol
;   again using "symbol printer"
;-------------------------------------------------------------------------------
;Entry: left, middle and right symbols
;Exit: None
;BALL TORTURE REGISTERS: AX,BX,CX,SP
;-------------------------------------------------------------------------------
make_string		proc
			push bp
			mov bp, sp

			push ax	 			;push length
			push ax	 			;push length
			;push cx
			;push ax
			mov ax, [bp+8d]		;ax = first inputed symbol

			push ax				;push symbol
			push [color]				;push color
			call symbol_printer
			add sp, 4d

			;int 03h
			;mov cx, [a] 				; cx = ax = length
			pop cx
			sub cx, 2d			; -2 because of left and right sides

			mov al, [bp+6d]		;ax = second inputed symbol
			;mov ax, cx
			;mov byte ptr es:[di+1], FRAME_COLOR  ;set symbol's colour
			;add di, 2d		;replace cursor
			rep stosw

			;pop cx
			xor ax, ax
			mov ax, [bp+4d]		;ax = third inputed symbol
			push ax
			push [color]

 			call symbol_printer
			add sp, 4d

			pop ax
			call find_gap
			add di, ax

			mov sp, bp		;return sp's value
			pop bp			;return bp's value

			ret
			endp
;-------------------------------------------------------------------------------
;print_text: prints message on the middle of frame
;-------------------------------------------------------------------------------
;Entry: None
;Exit:None
;REGISTERS:
;-------------------------------------------------------------------------------
print_text			proc
					mov ax, VIDEOSEG
					mov es, ax

					push SCREEN_HIGHT
					pop ax
					dec ax	 				;ax = 25-1
					push SCREEN_LENGTH
					pop dx
					mul dx					;ax = ax*80
					mov di, ax				;di = ax
					push [str_len]
					pop dx
					push SCREEN_LENGTH
					pop ax
					sub ax, dx
					and ax, 11111110b
					add di, ax	 			;bx = adress of 1 symbol of str


					lea si, [STRING]

					mov cx, [str_len]
@@cycle:			lodsb
					mov ah, DEFAULT_COLOR
					stosw

					push ax cx dx
					mov ah, 86h
					xor cx, cx
					mov dx, 0c350h
					int 15h

					pop dx cx ax

					dec cx
					xor ax, ax
					cmp cx, ax
					jne @@cycle

					ret
					endp
;-------------------------------------------------------------------------------
a 				dw 0
b 				dw 0
color 			dw 0
str_len  		dw 0
frame_type      dw 0
CUSTOM_FRAME 	db 9 dup (' ')

STRING 			db 128 dup (' ')
TYPE1	 		db '+-+|.|+-+'
TYPE2   		db 'ÉÍ»º ºÈÍ¼'
end			Start
