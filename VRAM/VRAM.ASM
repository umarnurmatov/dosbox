.model tiny
.code
org 100h

CRLF		equ 0dh, 0ah
VRAMSEGMENT	equ 0b800h
ARGCNT_ADDR	equ 80h
CMDARG_ADDR	equ 81h
COLATTRIB	equ 00000100b
COLATTRIB_BD	equ 10110010b
SCREENH		equ 19h
SCREENW		equ 2*50h

DEFSTR_LEN	equ 0bh

Start:		mov ax, VRAMSEGMENT
		mov es, ax
		
		mov di, SCREENW*(SCREENH/2)+SCREENW/2
		mov si, ARGCNT_ADDR		
		mov byte ptr cl, [si]   ; cx = str_len
		
		cmp cl, 0
		je init_default

		mov si, CMDARG_ADDR	; si = &cmd_str
		jmp init_end
 
init_default:   mov si, offset DEFAULT_STR	; si = &default_str
		mov cl, DEFSTR_LEN

init_end:	
		mov ah, COLATTRIB       ; ah = color_attrib
		mov dx, cx
		shr dx, 1
		sal dx, 1
		sub di, dx		; pox_y -= str_len / 2
		push cx

sloop:		lodsb			; al = ds:[si]; ++si
		stosw			; es:[di] = ah; ++di
		dec cl
		cmp cl, 0h
		jne sloop

		mov di, SCREENW*(SCREENH/2 - 1)+SCREENW/2-2
		sub di, dx
		pop si
		add si, 02h
		mov dx, 01h

		call draw_rect

		mov ax, 004ch
		int 21h

draw_rect:				; di <- top-left corner
					; si <- width
					; dx <- height - 2
		mov ah, COLATTRIB_BD
		mov al, 023h
		
		push di
		call draw_hline

		pop bx
		add bx, SCREENW
		xor cx, cx
		sub si, 02h
		sal si, 1
yloop: 		mov word ptr es:[bx], ax
		mov word ptr es:[bx]+2[si], ax
		add bx, SCREENW
		inc cx
		cmp cx, dx
		jne yloop
		shr si, 1
		add si, 02h

		mov di, bx
		call draw_hline
		
		ret

draw_hline:				; di <- start
					; si <- width
		xor cx, cx
xloop:		stosw
		inc cx
		cmp cx, si
		jne xloop

		ret

DEFAULT_STR     db 'hello world', CRLF

end Start