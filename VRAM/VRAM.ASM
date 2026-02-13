.model tiny

.data

CRLF		    equ 0dh, 0ah

DEFAULT_STR     db 'hello world', CRLF
DEFAULT_STR_LEN equ $ - DEFAULT_STR - 2

.code
org 100h

VRAMSEGMENT	equ 0b800h
ARGCNT_ADDR	equ 80h
CMDARG_ADDR	equ 81h
COLATTRIB	equ 00000100b
SCREENH		equ 19h
SCREENW		equ 2*50h
B_OFFSET    equ 4h

locals @@

Start:		    call Main 

                mov ax, 004ch
                int 21h

;-------------------------------------
; Main func
;-------------------------------------
Main		    proc

                push bp
                mov bp, sp

                mov ax, VRAMSEGMENT
                mov es, ax
                
                mov di, SCREENW * (SCREENH / 2) + SCREENW / 2
                mov si, ARGCNT_ADDR		
                mov byte ptr cl, [si]       ; cx = str_len
                
                cmp cl, 0
                je @@init_default

                mov si, CMDARG_ADDR	        ; si = &cmd_str
                jmp @@init_end
     
@@init_default: mov si, offset DEFAULT_STR	; si = &default_str
                mov cl, DEFAULT_STR_LEN

@@init_end:	    mov ah, COLATTRIB           
                mov dx, cx
                shr dx, 1h
                sal dx, 1h
                sub di, dx		            ; pox_y -= str_len / 2

                push di
                push cx

                call PrintStr

                mov al, 1h

                mov word ptr di, [bp-2]
                sub di, B_OFFSET + SCREENW
                mov cl, 3h
                xor ch, ch

                call VerticalLine

                mov word ptr cx, [bp-4]
                add cx, B_OFFSET

                call HorizontalLine

                mov cx, 3h
                mov ch, 1h

                call VerticalLine

                mov byte ptr cx, [bp-4]
                add cx, B_OFFSET
                mov ch, 1h

                call HorizontalLine
                
                add sp, 4h
                pop bp
                ret
Main            endp

;-------------------------------------


;-------------------------------------
; Print string
; 
; Entry: DS:SI --> string
;        ES:DI --> vram addr
;        CX    =   string length
; Destr: SI, DI, CX
;-------------------------------------

PrintStr        proc
                
@@loopv:        lodsb			; al = ds:[si]; ++si
                stosw			; es:[di] = ah; ++di
                dec cl
                jnz @@loopv

                ret
PrintStr        endp

;-------------------------------------
                
;-------------------------------------
; Ouputs vertical line of given length
;
; Entry: ES:DI = first line point
;        AL    = char
;        AH    = color attribute
;        CL    = length
;        CH    = direction
; Exit:  DI  --> last line point
; Destr: CL, DX
;-------------------------------------

VerticalLine    proc

                cmp ch, 0
                je @@if
                mov dx, -SCREENW
                jmp @@endif
@@if:           mov dx, SCREENW
@@endif:
                
@@loopv:        mov word ptr es:[di], ax  
                add di, dx
                dec cl
                jnz @@loopv

                sub di, dx

                ret
VerticalLine    endp

;-------------------------------------

;-------------------------------------
; Ouputs horizontal line of given length
;
; Entry: ES:DI = first line point
;        AL    = char
;        AH    = color attribute
;        CL    = length
;        CH    = direction
; Exit:  DI  --> last line point
; Destr: CL, DX 
;-------------------------------------

HorizontalLine  proc

                cmp ch, 0
                je @@if
                mov dx, -2h
                jmp @@endif
@@if:           mov dx, 2h
@@endif:
                
@@loopv:        mov word ptr es:[di], ax  
                add di, dx
                dec cl
                jnz @@loopv

                sub di, dx

                ret
HorizontalLine  endp

;-------------------------------------

end Start
