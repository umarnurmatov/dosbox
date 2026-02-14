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
CTRL_CHR    equ 2dh         ; '-'
B_CHR       equ 2h          ; default border charachter

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
                
                mov si, ARGCNT_ADDR		
                mov byte ptr dl, [si]       ; dl = str_len
                
                cmp dl, 0
                je @@init_default

                push CTRL_CHR
                push dx
                push CMDARG_ADDR
                call StrChr
                add sp, 6h

                cmp dx, cx
                je @@b_default
                mov si, cx
                add si, CMDARG_ADDR + 1
                mov byte ptr dl, [si]
                push dx

@@b_default:    push B_CHR

@@b_end:        mov si, CMDARG_ADDR	        ; si = &cmd_str
                jmp @@init_end
     
@@init_default: mov si, offset DEFAULT_STR	; si = &default_str
                mov cx, DEFAULT_STR_LEN

@@init_end:	    mov di, SCREENW * (SCREENH / 2) + SCREENW / 2
                mov ax, VRAMSEGMENT
                mov es, ax
                mov ah, COLATTRIB           
                mov dx, cx
                shr dx, 1h
                sal dx, 1h
                sub di, dx		            ; pox_y -= str_len / 2

                push di
                push cx

                call PrintStr

                mov byte ptr al, [bp-2]
                mov word ptr di, [bp-4]
                sub di, B_OFFSET + SCREENW
                mov cl, 3h
                xor ch, ch

                call VerticalLine

                mov word ptr cx, [bp-6]
                add cx, B_OFFSET

                call HorizontalLine

                mov cx, 3h
                mov ch, 1h

                call VerticalLine

                mov byte ptr cx, [bp-6]
                add cx, B_OFFSET
                mov ch, 1h

                call HorizontalLine
                
                add sp, 6h
                pop bp
                ret
Main            endp

;-------------------------------------


;-------------------------------------
; Find symbol in string
; Entry: stack[0] --> string  
;        stack[2]   = string length
;        stack[4]   = charachter to find
; Exit:  CX         = charachter position
; Assum: ES points to string segment
; Destr: AX, DI
; Notes: Cdecl
;-------------------------------------

StrChr          proc
                
                push bp
                mov bp, sp

                mov word ptr di, [bp+4]
                mov word ptr cx, [bp+6]
                mov byte ptr al, [bp+8]

                cld                         ; clear direction flag

                repne scasb                 ; while(cx--) if(al == es:[di++]) break;
                                            ; cx = len - pos

                mov word ptr ax, [bp+6]
                neg cx
                add cx, ax
                dec cx

                pop bp
                ret
StrChr          endp

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
