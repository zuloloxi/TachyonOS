; +---------------------------------+
; | API Macros - Used for API calls |
; +---------------------------------+
	
	%MACRO API_START 0					; Begin API call
		push es
		push ds
		pusha
		inc byte [gs:internal_call]
	%ENDMACRO
	
	%MACRO API_END 0					; End API call (without returning anything)
		dec byte [gs:internal_call]
		popa
		pop ds
		pop es
		jmp os_return
	%ENDMACRO
	
	%MACRO API_RETURN 1					; End API call (return one value)
		dec byte [gs:internal_call]
		mov [gs:%%tmp], %1
		popa
		mov %1, [gs:%%tmp]
		pop ds
		pop es
		jmp os_return
		%%tmp			dw 0
	%ENDMACRO
	
	%MACRO API_SEGMENTS 0					; Set the kernel segments
		push ax
		mov ax, gs
		mov ds, ax
		mov es, ax
		pop ax
	%ENDMACRO
	