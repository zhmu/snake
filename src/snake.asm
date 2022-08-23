;
; snake - (c) Rink Springer
;
jumps
code            segment para use16 'code'
                assume  cs:code,ds:code
                org     100h

start:          jmp     begin

SNAKECOL        equ     01eh
BORDERCOL       equ     01eh

x               db      1
y               db      1
xp              db      1
yp              db      0
snakelen        dw      4

tw              dw      0
seed            dw      01fefh

;
; random
;
; this will return a number from 0 .. [ax]. it will return the result in [dx]
; and update the [seed].
;
random:         mov     bx,ax
                mov     ax,[seed]
                rol     ax,1
                mov     [seed],ax

                div     bx
                ret

begin:          mov     di,offset history
                mov     cx,[snakelen]
                xor     ax,ax
                rep     stosw

                mov     bp,0b000h

                mov     ah,0fh                          ; video: get mode
                int     10h
                cmp     al,3
                jne     mono

                add     bp,0800h

mono:           mov     es,bp
                xor     di,di

                mov     ax,(BORDERCOL shl 8) + 201
                stosw
                add     al,4
                mov     cx,78
                rep     stosw
                mov     al,187
                stosw

                mov     cx,23
                dec     al
loopy:          stosw
                push    ax cx
                mov     al,32
                mov     cx,78
                rep     stosw
                pop     cx ax
                stosw
                loop    loopy

                mov     al,200
                stosw
                mov     al,205
                mov     cx,78
                rep     stosw
                mov     al,188
                stosw


mainloop:       mov     di,word ptr [history]
                or      di,di
                jz      dontdelete

                mov     word ptr es:[di],(SNAKECOL shl 8) + 32

dontdelete:     mov     si,offset history+2
                mov     di,offset history
                mov     cx,[snakelen]
                dec     cx
                push    es ds
                pop     es
                rep     movsw
                pop     es

                xor     ah,ah
                xor     bh,bh
                mov     al,[y]
                mov     bl,[x]
                add     al,[yp]
                add     bl,[xp]

                cmp     bl,79
                jne     q1

                mov     bl,1
                jmp     q4

q1:             or      bl,bl
                jnz     q4

                mov     bl,78

q4:             cmp     al,24
                jne     q3

                mov     al,1
                jmp     q2

q3:             or      al,al
                jnz     q2

                mov     al,23

q2:             mov     [y],al
                mov     [x],bl

                mov     di,80
                mul     di
                add     ax,bx
                shl     ax,1
                mov     di,ax

                mov     bp,snakelen
                dec     bp
                shl     bp,1
                mov     word ptr history[bp],di
                mov     ax,word ptr es:[di]
                mov     word ptr es:[di],(SNAKECOL shl 8) + 219

                cmp     al,'o'
                jne     next2

                mov     [tw],0
                mov     di,[snakelen]
                shl     di,1
                xor     ax,ax
                mov     ds:[offset history+di],ax

                inc     word ptr [snakelen]

                jmp     next

next2:          cmp     al,32
                jne     death

next:           push    es
                xor     ax,ax
                push    ax
                pop     es
                mov     ax,es:[46ch]
                inc     ax
delayloop:      cmp     es:[46ch],ax
                jl      delayloop
                pop     es

                cmp     [tw],0
                jnz     skipnewtw

                mov     ax,22
                call    random
                inc     dx
                mov     ax,80
                mul     dx
                mov     di,ax                   ; di = (1 + random(23)) * 80
     
                mov     ax,77
                call    random
                inc     dx
                add     di,dx
                shl     di,1                    ; di += (1 + random (78)) * 2

                and     di,0fffeh
                mov     [tw],di
                mov     es:[di],(SNAKECOL shl 8) + 'o'

skipnewtw:

                mov     ah,1                    ; keyboard: check for key
                int     16h             
                jz      mainloop                ; no key, return to mainloop

                xor     ah,ah                   ; keyboard: read the key
                int     16h

                mov     bp,word ptr [xp]

                cmp     ah,050h                 ; down?
                jne     notdown

                mov     bp,0100h

notdown:        cmp     ah,048h                 ; up?
                jne     notup

                mov     bp,0ff00h

notup:          cmp     ah,04dh                 ; right?
                jne     notright

                mov     bp,01h

notright:       cmp     ah,04bh                 ; left?
                jne     notleft

                mov     bp,0ffh

notleft:        mov     word ptr [xp],bp

                cmp     al,1bh                  ; escape?
                jne     mainloop                ; no, return to the main loop

death:          int     20h

history         equ     this byte

code            ends
                end     start
