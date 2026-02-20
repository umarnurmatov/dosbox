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
CTRL_CHR    equ 2fh

DEF_BORD_CHR equ 023h

locals @@

Start:		    call Main 

Exit:           mov ax, 004ch
                int 21h

;-------------------------------------
; Main func
;-------------------------------------
Main		    proc

                push bp
                mov bp, sp

                
                mov si, ARGCNT_ADDR		
                mov byte ptr cl, [si]       ; cx = str_len

                jcxz Exit

                push CTRL_CHR
                push cx
                push CMDARG_ADDR 
                call StrChr
                add sp, 6h

                mov byte ptr al, [si]
                cmp ax, cx
                jne @@else
                push DEF_BORD_CHR 
                jmp @@if_end
@@else:         mov di, CMDARG_ADDR 
                add di, cx
                mov byte ptr al, [di]
                dec cx
                push ax
@@if_end:
                mov si, CMDARG_ADDR
                mov di, SCREENW * (SCREENH / 2) + SCREENW / 2
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

                pop cx
                pop di
                pop ax

                sub di, B_OFFSET + SCREENW
                add cl, B_OFFSET
                mov ch, 03h
                mov ah, COLATTRIB

                push di
                push ax
                push cx

                call RectBorder
                
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
; Draw rectangular border
; Entry: stack[0] = top left corner
;        stack[2] = char
;        stack[3] = color attribute
;        stack[4] = width
;        stack[5] = height
; Exit:  none
; Assum: ES points to VRAM segment
; Destr: AX, CX, DX, DI
; Note:  Pascal
;-------------------------------------

RectBorder      proc
                
                push bp
                mov bp, sp

                mov word ptr cx, [bp+4]
                mov word ptr ax, [bp+6]
                mov word ptr di, [bp+8] 
                xor ch, ch

                mov byte ptr cl, [bp+5]
                
                call VerticalLine

                mov byte ptr cl, [bp+4]

                call HorizontalLine

                mov byte ptr cl, [bp+5] 
                mov ch, 1h

                call VerticalLine

                mov byte ptr cl, [bp+4]

                call HorizontalLine
                
                pop bp
                ret 6
RectBorder      endp

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
