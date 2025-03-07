TITLE                  RESIDENT_RAMKA
;-------------------------------------------------------------------------------
;           			 RESIDENT
; make a programm which:
; - prints a box with registers
;-------------------------------------------------------------------------------
.model tiny
.code
.386
org 100h


;Timer - 1 param - frame
;Keybord -







SCREEN_LENGTH 			equ 80d					;length of screen
SCREEN_HIGHT  			equ 25d					;hight of screen
;FRAME_COLOR   			equ 00001100b       	;pink(rework as inputed)
VIDEOSEG	  	        equ 0b800h	 			;BIOS segment
DEFAULT_COLOR			equ 07h

Start:
        ;cld                                     ;di++ instead of --
        ;mov ax, VIDEOSEG                        ;ax = b800
        ;mov es, ax                              ;es = ax
        ;mov ah, 4ch                             ; ah = 4c
        mov di, 5*80*2+40*2


        xor ax, ax
        mov es, ax                              ;es = 0
        mov bx, 08h*4                           ;set bx as 9 int

        mov ax, es:[bx]                         ;ax = adress of 9 int
        mov int08_old_offset, ax                ;save old adress
        mov ax, es:[bx+2]                       ;ax = adress of 9 int segment
        mov int08_old_segment, ax               ;save old 9 int segment

        cli                                     ;turn off ints
        mov word ptr es:[bx], offset New_int_08

        mov ax, cs                              ;ax = current segment
        mov es:[bx+2], ax                       ;9 int's segment set as current
        sti                                     ;turn back on ints
        ;int 09h                                ;call int 09h
;---------------------------------------------------------------------------------------
        xor ax, ax
        mov es, ax                              ;es = 0
        mov bx, 09h*4                           ;set bx as 9 int

        mov ax, es:[bx]                         ;ax = adress of 9 int
        mov int09_old_offset, ax                ;save old adress
        mov ax, es:[bx+2]                       ;ax = adress of 9 int segment
        mov int09_old_segment, ax               ;save old 9 int segment

        cli                                     ;turn off ints
        mov word ptr es:[bx], offset New_int_09
        mov ax, cs                              ;ax = current segment
        mov es:[bx+2], ax                       ;9 int's segment set as current
        sti

		;int 09h
        ;push 40
        ;push 15
        ;call make_frame
        ;add sp, 4d

        mov ax, 3100h
        mov dx, offset EOP
        shr dx, 4
        inc dx
        int 21h


New_int_08              proc
                        push ax bx cx dx di si es ds      ;save registers

						push cs
						pop ds

						mov al, FRAME_FLAG
                        cmp al, 1                         ;if ax == 1 print_frame
                        jne @@exit1


						push ax
						push dx
						push cx
						push bx
						push ax

						mov ax, offset AX_INFO
						push ax
						call get_a_from_hex
						add sp, 4d

						mov ax, offset BX_INFO
						push ax
						call get_a_from_hex
						add sp, 4d

						mov ax, offset CX_INFO
						push ax
						call get_a_from_hex
						add sp, 4d

						mov ax, offset DX_INFO
						push ax
						call get_a_from_hex
						add sp, 4d


		               	push 17
                        push 7
                        call make_frame	 						;print frame
                        add sp, 4d

						pop ax



						;xor ah, ah
						;jmp @@exit1



;@@res1:                 ;in al, 61h             ;al = data from port 61
                        ;mov ah, al              ;ah = al
                        ;or al, 80h              ;???????? ???????? ?? ???????? ?
                        ;out 61h, al             ;port 61 = al
                        ;mov al, ah
                        ;out 61h, al

                        ;mov al, 20h
                        ;out 20h, al

@@exit1:

                        pop ds es si di dx cx bx ax
                        db 0eah
int08_old_offset        dw 0
int08_old_segment       dw 0
                        endp
;---------------------------------------------------------------------------------
New_int_09              proc
                        ;int 03h
                        push ax bx cx dx di si es ds      ;save registers
						;mov bx, 5*80*2+40*2
						;mov cx, VIDEOSEG
						;mov es, cx
						;mov byte ptr es:[bx], al
						;mov FRAME_FLAG, al

						push cs
						pop ds
                        in al, 60h

                        mov ah, 13h
                        cmp al, ah
                        jne @@exit2

		                ;xor FRAME_FLAG, FRAME_FLAG
					  	cmp FRAME_FLAG, 1
						jne @@fr_fl_was_0


						mov ax, VIDEOSEG
						mov es, ax
						xor di, di	 					;if FRAME_FLAG == 1 and 'r' was pressed second time load the SCREENSHOT
						mov ax, cs
						mov ds, ax
						lea si, [SCREENSHOT]

						mov cx, 4000d
@@loader:				lodsb
						stosb
						loop @@loader

						mov FRAME_FLAG, 0
						jmp @@exit2


@@fr_fl_was_0:
						mov al, 1
						mov FRAME_FLAG, al
						mov ax, VIDEOSEG
						mov ds, ax
						xor si, si	 							;if FRAME_FLAG != 1 ( ==0 ) save in SCREENSHOT
						mov ax, cs
						mov es, ax
						lea di, [SCREENSHOT]
						mov cx, 4000d
@@saver:				lodsb
						stosb
						loop @@saver

@@exit2:
                        pop ds es si di dx cx bx ax

                        db 0eah
int09_old_offset        dw 0
int09_old_segment       dw 0
                        endp


;-------------------------------------------------------------------------------
;get_a_from_hex		make symbols from 4 number input
;-------------------------------------------------------------------------------
;Entry: 4 numbers
;Change reg:
;-------------------------------------------------------------------------------
get_a_from_hex			proc
						push bp
						mov bp, sp
						mov bx, [bp+4d]		;bx= ptr to str
						mov ax, [bp+6d]     ;ax=4 numbers
						add bx, 5
						mov di, bx
						push ax
						mov ax, cs
						mov es, ax
						pop ax

													;0110 1001 1010 1010 rol cx, 4   1001 1010 1010 0110  6
						push ax
						push ax
						push ax
						push ax
						pop cx

						rol cx, 12
						and ch, 00001111b
						call from_num_or_let_to_a
						mov al, ch
						stosb

						pop cx
						;rol cx, 4
						and ch, 00001111b
						call from_num_or_let_to_a
						mov al, ch
						stosb

						pop cx
						rol cx, 4
						and ch, 00001111b
						call from_num_or_let_to_a
						mov al, ch
						stosb

						pop cx
						rol cx, 8
						and ch, 00001111b
						call from_num_or_let_to_a
						mov al, ch
						stosb

						mov sp, bp
						pop bp
						ret
						endp

;-------------------------------------------------------------------------------
;from_num_or_let_to_a
;-------------------------------------------------------------------------------
from_num_or_let_to_a	proc

						xor ah, ah
						cmp ch, ah
						jb EOP

						mov ah, 15
						cmp ch, ah
						ja EOP
						mov ah, 9
						cmp ch, ah
						ja @@letter
						jmp @@number

@@number: 				add ch, 30h
						jmp @@exit3

@@letter:				add ch, 37h
						jmp @@exit3

@@exit3:
						ret
						endp
;-------------------------------------------------------------------------------
;make_frame:	    plays animation of opening a message
;-------------------------------------------------------------------------------
;Entry: legth, hight, color, type of frame, user frame elems, message
;Exit: frame printed in commander
;BALL TORTURE REGISTERS:
;-------------------------------------------------------------------------------
make_frame	proc
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
print_frame	proc
			push ax				;save ax = length
			push bx	 			;save bx = hight
			;push dx	 			;save dx = type of frame

			;call get_location	;es = videoseg, bx = location
			mov ax, VIDEOSEG
			mov es, ax
			mov di, 2*80*2+55*2
			;pop dx	 			;return dx
			pop bx	 			;return bx
			pop ax				;return ax
			;push ax
			;push bx
			;push cx

			lea si, [TYPE_OF_FRAME]
			push ax
			push bx
			push word ptr [si]   		;0c9h left corner
			push word ptr [si+1] 		;0cdh between corners
			push word ptr [si+2] 		;0bbh right corner
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
			push bx
			push word ptr [si+3]		;0bah left border
			push word ptr [si+4]		;0h   middle space
			push word ptr [si+5]		;0bah right border
			call make_string
			add sp, 6d		;set sp correctly
			pop bx
			pop ax
			;pop cx
			;pop bx
			;pop ax


			dec dx

			push ax bx cx dx di si es ds
			call find_gap
			sub di, ax

			;std
			cmp dx, 4
			jne @@check2
			mov ax, VIDEOSEG ; copypaste
			mov es, ax
			sub di, 12*2
			mov ax, cs
			mov ds, ax
			mov si, offset AX_INFO
			mov cx, 9
@@ax_printer:
			lodsb
			mov ah, DEFAULT_COLOR
			stosw
			Loop @@ax_printer

			;add di, 10

			jmp @@exit


@@check2:
			cmp dx, 3
			jne @@check3

			mov ax, VIDEOSEG
			mov es, ax
			sub di, 12*2
			mov ax, cs
			mov ds, ax
			mov si, offset BX_INFO
			mov cx, 9
@@bx_printer:
			lodsb
			mov ah, DEFAULT_COLOR
			stosw
			Loop @@ax_printer
			;add di, 10

			jmp @@exit


@@check3:
			cmp dx, 2
			jne @@check4

			mov ax, VIDEOSEG
			mov es, ax
			sub di, 12*2
			mov ax, cs
			mov ds, ax
			mov si, offset CX_INFO
			mov cx, 9
@@cx_printer:
			lodsb
			mov ah, DEFAULT_COLOR
			stosw
			Loop @@ax_printer
			;add di, 10


			jmp @@exit

@@check4:
			cmp dx, 1
			jne @@exit

			mov ax, VIDEOSEG
			mov es, ax
			sub di,12*2
			mov ax, cs
			mov ds, ax
			mov si, offset DX_INFO
			mov cx, 9
@@Dx_printer:
			lodsb
			mov ah, DEFAULT_COLOR
			stosw
			Loop @@ax_printer
			;add di, 10



@@exit:		cld
			pop ds es si di dx cx bx ax

			cmp dx, 0		;cycle
		ja @@string_printer

		push ax
		push word ptr [si+6]		;0c8h left down corner
		push word ptr [si+7]		;0cdh down border
		push word ptr [si+8]		;0bch right down corner
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
symbol_printer	proc
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
get_location	proc
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
find_gap	proc
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
make_string	proc
		push bp
		mov bp, sp

		push ax	 			;push length
		push ax	 			;push length
		;push cx
		;push ax
		mov ax, [bp+8d]		;ax = first inputed symbol

		push ax				;push symbol
		push DEFAULT_COLOR				;push color
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
		push DEFAULT_COLOR
 		call symbol_printer
		add sp, 4d

		pop ax
		call find_gap
		add di, ax

		mov sp, bp		;return sp's value
		pop bp			;return bp's value

		ret
		endp

String          				db 'Start1488$'
TYPE_OF_FRAME   				db '…Õª∫ ∫»Õº'
SCREENSHOT 						db 4000 dup (' ')
FRAME_FLAG       			    db 0

AX_INFO	 						db 9 dup ('AX =     ')
BX_INFO	 						db 9 dup ('BX =     ')
CX_INFO	 						db 9 dup ('CX =     ')
DX_INFO	 						db 9 dup ('DX =     ')
EOP:
end             		Start
