; ------------------------------------------------------------------
; os_draw_border -- draw a single character border
; BL = colour, CH = start row, CL = start column, DH = end row, DL = end column

os_draw_border:
	pusha
	
	mov ax, 0x1000
	mov ds, ax
	
	inc byte [internal_call]

	mov [.start_row], ch
	mov [.start_column], cl
	mov [.end_row], dh
	mov [.end_column], dl

	mov al, [.end_column]
	sub al, [.start_column]
	dec al
	mov [.width], al
	
	mov al, [.end_row]
	sub al, [.start_row]
	dec al
	mov [.height], al
	
	mov ah, 09h
	mov bh, 0
	mov cx, 1

	mov dh, [.start_row]
	mov dl, [.start_column]
	call os_move_cursor

	mov al, [.character_set + 0]
	int 10h
	
	mov dh, [.start_row]
	mov dl, [.end_column]
	call os_move_cursor
	
	mov al, [.character_set + 1]
	int 10h
	
	mov dh, [.end_row]
	mov dl, [.start_column]
	call os_move_cursor
	
	mov al, [.character_set + 2]
	int 10h
	
	mov dh, [.end_row]
	mov dl, [.end_column]
	call os_move_cursor
	
	mov al, [.character_set + 3]
	int 10h
	
	mov dh, [.start_row]
	mov dl, [.start_column]
	inc dl
	call os_move_cursor
	
	mov al, [.character_set + 4]
	mov cx, 0
	mov cl, [.width]
	int 10h
	
	mov dh, [.end_row]
	call os_move_cursor
	int 10h
	
	mov al, [.character_set + 5]
	mov cx, 1
	mov dh, [.start_row]
	inc dh
	
.sides_loop:
	mov dl, [.start_column]
	call os_move_cursor
	int 10h
	
	mov dl, [.end_column]
	call os_move_cursor
	int 10h
	
	inc dh
	dec byte [.height]
	cmp byte [.height], 0
	jne .sides_loop
	
	popa
	dec byte [internal_call]
	jmp os_return
	
	
.start_column				db 0
.end_column				db 0
.start_row				db 0
.end_row				db 0
.height					db 0
.width					db 0

.character_set				db 218, 191, 192, 217, 196, 179

; ------------------------------------------------------------------
; os_draw_horizontal_line - draw a horizontal between two points
; IN: BH = width, BL = colour, DH = start row, DL = start column

os_draw_horizontal_line:
	pusha
	
	mov ax, 0x1000
	mov ds, ax
	
	inc byte [internal_call]
	
	mov cx, 0
	mov cl, bh
	
	call os_move_cursor
	
	mov ah, 09h
	mov al, 196
	mov bh, 0
	int 10h

	popa
	dec byte [internal_call]
	jmp os_return
	
; ------------------------------------------------------------------
; os_draw_horizontal_line - draw a horizontal between two points
; IN: BH = length, BL = colour, DH = start row, DL = start column

os_draw_vertical_line:
	pusha
	
	mov ax, 0x1000
	mov ds, ax
	
	inc byte [internal_call]
	
	mov cx, 0
	mov cl, bh
	
	mov ah, 09h
	mov al, 179
	mov bh, 0
	
.lineloop:
	push cx
	
	call os_move_cursor
	
	mov cx, 1
	int 10h
	
	inc dh
	
	pop cx
	
	loop .lineloop

	popa
	dec byte [internal_call]
	jmp os_return
	

; ------------------------------------------------------------------
; os_move_cursor -- Moves cursor in text mode
; IN: DH, DL = row, column; OUT: Nothing (registers preserved)

os_move_cursor:
	pusha

	mov bh, 0
	mov ah, 2
	int 10h				; BIOS interrupt to move cursor

	popa
	jmp os_return

	

; ------------------------------------------------------------------
; os_draw_block -- Render block of specified colour
; IN: BL/DL/DH/SI/DI = colour/start X pos/start Y pos/width/finish Y pos

os_draw_block:
	pusha
	
	mov ax, 0x1000
	mov ds, ax
	
	; find starting byte
	
	mov [.colour], bl
	mov byte [.character], 32
	
	mov [.rows], di
	
	mov ax, 0			; start with row * 80
	mov al, dh
	mov bx, ax			; use bit shifts for fast multiplication
	shl ax, 4			; 2^4 = 16 
	shl bx, 6			; 2^6 = 64
	add ax, bx			; 16 + 64 = 80
	mov bx, 0			; add column
	mov bl, dl
	add ax, bx
	shl ax, 1			; each text mode character takes two bytes (colour and value)
	mov di, ax
	
	mov [.width], si		; store the width, this will need to be reset
	
	mov bx, 80			; find amount to increment by to get to next line ((screen width - block width) * 2)
	sub bx, si
	shl bx, 1
	mov si, bx
	
	mov ax, 0			; find number of rows to do (finish Y - start Y)
	mov al, dh
	sub [.rows], ax
	
	mov ax, 0xB800			; set the text segment
	mov es, ax
	
	mov ax, [.character]		; get the value to write
	
.write_data:
	mov cx, [.width]		; get line width
	rep stosw			; write character value
	
	add di, si			; move to next line
	
	dec word [.rows]
	cmp word [.rows], 0		; check if we have processed every row
	
	jne .write_data			; if not continue
	
	popa
	jmp os_return

	.width				dw 0
	.rows				dw 0
	.character			db 0
	.colour				db 0
	
	
