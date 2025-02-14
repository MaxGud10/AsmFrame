.model tiny
.code
org 100h
locals @@

;--------------------------------------------------------------------
;                                 DEFINE
;--------------------------------------------------------------------
video_memory_segment equ 0b800h ; ������� �����������
command_line_ptr     equ 0080h  ; ��������� �� ��������� ������
end_of_string        equ 0024h  ; ������ ����� ������ '$'
ascii_zero           equ 0030h  ; ������ '0'
ascii_w_hex          equ 0057h  ; ������ 'w' � ����������������� �������
exit_code            equ 4c00h  ; ��� ���������� ���������
frame_style_size     equ 9d     ; ������ ����� �����
frame_color          equ 047h   ; ���� ����� �� ���������
shadow_color         equ 070h   ; ���� ����

;--------------------------------------------------------------------
start:	jmp main


main    proc
        nop
        push bp     ; ��������� ������� ���������, ������� bp ������ ������������ ��� ������ � ���������� ����������� � ����������� ������� 
        mov  bp, sp  ; �������� �������� �������� sp � bp => bp ��������� �� ������� ������� ����� 
        sub  sp, 10  ; ����� 10 ���� �� �������� sp. �������� 10 ���� � ����� ��� ��������� ����������. �� ���� �� 2 ����� �� 5 ���������� 

        ; ��������� �������� �� �����
        mov bx, video_memory_segment ; �������� � ������� bx �������� ����� ������ 
        mov es, bx                   ; ����������� �������� �� bx � es. ������� es ������������ ��� ������ � ��������������� ���������� ������, � ������ ������ � ������������.
        xor bx, bx                   ; �������� �������� bx 

        ; ���������� ��� ����������
        mov [bp-2 ], word ptr 0000h  ; ������ ��������� ������. �������� �� ������ bp-2 �������� 0 
        mov [bp-4 ], word ptr 0000h  ; ����� �����
        mov [bp-6 ], word ptr 0000h  ; ������ �����
        mov [bp-8 ], word ptr 0000h  ; ���� �����
        mov [bp-10], word ptr 0000h  ; ����� �����
        mov si, command_line_ptr     ; si - ��������� �� ��������� ������
        xor ax, ax                   ; �������� ������� ax
        mov al, [si]                 ; ��������� ������ ���� �� ��������� ������ � ������� al 
        mov word ptr [bp-2], ax      ; ��������� ������ ��������� ������ � ������ ��������� ����������
        inc  si                       ; ����������� si �� 1, ����� ������� � ���������� �������
        push si                      ; ��������� si � ���� 
        mov ax, word ptr [bp-2]      ; ��������� ������ ��������� ������ � ax
        add si, ax                   ; ��������� � ����� ��������� ������
        mov [si], byte ptr end_of_string ; ������������� ������ ����� ������ '$' � ����� ��������� ������ 
        pop si

        ; �������� ������ ��������� ������
        call skip_spaces
        call atoi                   ; ��������� ������ ����� -> �����
        mov [bp-4], ax              ; ����� = ax 
        call skip_spaces
        call atoi                   ; ��������� ������ ����� -> ������
        mov [bp-6], ax              ; ������ = ax 
        call skip_spaces
        call atoh                   ; ��������� ������ ����� (�����������������) -> ���� 
        mov [bp-8], ax              ; ���� = ax 
        call skip_spaces
        call atoi                   ; ��������� ��������� ����� -> ����� �����
        mov [bp-10], ax             ; ����� = ax 
        
        call skip_spaces
        ; �������� �������� �����! draw_frame(�����, ������, ����, �����, ������)
        push [bp-4]
        push [bp-6]
        push [bp-8]
        push [bp-10]
        push si
        call draw_frame
        
        ; ���������� ���������
        mov ax, exit_code           ; ��������� ��� ���������� ��������� � �������� ax
        int 21h
        mov sp, bp                  ; ��������������� ��������� �����
        pop bp
        ret
main endp

;--------------------------------------------------------------------
; draw_frame(length, width, color, style, string)
; function for drawing a frame
; uses and modifies: length, width, color, style, es:[bx] if es = 0b800h is a segment of video memory
; returns: nothing
; saves registers: ax, bx, cx, dx, di
; local variables: 0
;--------------------------------------------------------------------
draw_frame      proc
                nop
                push bp                 ; ��������� ������� ���������. ������� bp ������������ ��� ������ � ���������� ����������� � ����������� �������
                mov  bp, sp              ; �������� �������� �������� sp � bp  
                sub  sp, 4               ; ��������� �������� �������� sp �� 4 � ����� ��� ��������� ����������. ��� 2 ���������� �� 2 ����� 
        
                push ax                 ; ��������� ��������
                push bx
                push cx
                push dx
                push di
                push si

                ;---------------------------------------------------------------
                ; coordinate = line * 160d + shift
                ; center = 11 * 160 + 80
                ; es:[di] = coordinate of curr cell
                ;
                ; si - ptr of style frame
                ; di - pointer of current cell
                ; bh - color, BL - char
                ; ax, cx, dx - help
                ;---------------------------------------------------------------

                ; ������������� �����
                ; curr_style = style_frame + frame_style_size * ������
                xor si, si               ; �������� si 
                lea si, style_frame      ; ��������� ����� ���������� f_s � ������� si 
                mov ax, frame_style_size ; �������� �����  f_s_s � ������� ax  
                mul word ptr [bp+6]      ; �������� ax �� �������� �� ������ [bp+6] (������ ����� �����) � ��������� ��������� � ax
                add si, ax               ; ���������� ��������� ��������� � si (si ��������� �� ������ ����� �����)
                
                ; ������������� ����
                xor bx, bx               ; �������� ������� bx
                mov bh, [bp+8]           ; �������� ����� ����� ����� � bh 

                ; ������������� di � �����
                xor dx, dx               ; �������� �������� dx
                mov ax, 160d             ; 160 - ���������� ���� �� ������ � �����������
                mov dx, 11d              ; ��������� �������� 11 � ������� dx, ��� 11 ����� ������ 
                mul dx                   ; 11 * 160 = ax 
                add ax, 80               ; ax + 80
                mov di, ax               ; �������� ������� ax � di => di ��������� �� �����

                ; ������������� ��������� ������� di
                mov ax, [bp+12]         ; di = ����� - �����/2 * 2 (�����) - 160 * (������/2)
                mov cl, 2               ; ��������� �������� 2 � ������� cl
                div cl                  ; ����� �������� � �������� ax �� cl. ��������� ����������� � al, � ������� � ah
                @@check_alignment:      ; ���������, ���� (di % 2 != 0) - ����� ��������� �� 1 ����!
                        cmp ah, 0       ; ���������� ������� ah �� ������� � 0 
                        je @@alignment_done ; if ah ==0 => ��������� �� �����. �� ���� ����� ����� ������ 
                @@align:                ; ������������ ��������� ������� 
                        dec di          ; ��������� �������� �������� di �� 1
                @@alignment_done:
                sub di, [bp+12]         ; ��������� �������� ������� ��������� �� ������ [bp+12] �� �������� di 
                mov ax, [bp+10]         ; ��������� �������� �� ����� �� ������ [bp+10]� ������� ax
                mov cl, 2d              ; ��������� �������� 2 � ������� cl
                div cl                  ; ����� �������� � �������� ax �� cl. ������� ���� � al, � ������� � ah
                xor ah, ah
                mov cx, 160d            ; ��������� �������� 160 � ������� cx
                mul cx                  ; �������� �������� � ax �� cx
                sub di, ax              ; �������� �������� ax �� di. di ��������� �� ��������� ������� ��� ��������� ����� (� ������ �� ������)

                push di                 ; ��������� ������

                ; ������ �����
                push [bp+12]            ; �������� �������� �������� ����� ����� � ����
                call draw_line  
                add  si, 3               ; si + 3

                xor cx, cx              ; for (i = 2; i < ������; i++) { draw_line }
                add cx, 2               ; ��-�� ������
        @@draw_frame_loop: 
                cmp cx, [bp+10]         ; ���������� �������� cx �� ��������� ������� ���� �� ������ � [bp+10]
                jae @@draw_frame_end    ; ���� cx >= [bp+10] �� ��������� �� �����. �� ���� ��������� �����

                push [bp+12]
                call draw_line

                inc cx                  ; cx + 1
                jmp @@draw_frame_loop   ; ��������� � ������ �����       
        @@draw_frame_end:
                add si, 3               ; si + 3
                push [bp+12]            
                call draw_line

                add si, 3               ; si + 3

                ; ����� �����
                pop di                  ; ��������������� ������
                add di, 2               ; ����� ����� �� ��������� �������� � ����� ������� 
                add di, 160             ; ��������� � ������. �� ���� ������� �� ��������� ������ 

                mov si, [bp+4]          ; ������ si

                mov ax, [bp+12]         ; [bp-2] = (����� - 2) * (������ - 2) = �������
                sub ax, 2               ; ax - 2
                mov dx, [bp+10]
                sub dx, 2               ; dx - 2 
                mul dx                  ; ���� ������� ����� 
                mov [bp-2], ax          ; ��������� ������� � ��������� ���������� �� ������ [bp-2]

                ; �������� �������� �� ����������� �� ������ ������
                mov cx, [bp+12]   ; cx = ����� ����
                sub cx, 2         ; cx = ����� - 2 (�������)
                mov ax, cx        ; ax = ����� - 2
                sub ax, dx        ; ax = (����� - 2) - (������ - 2)
                shr ax, 1         ; ax = AX / 2 (�������� ������)
                add di, ax        ; di = DI + �������� ������

                ; �������� ������������ �������� �� ������ ������
                mov ax, [bp+10]    ; ax = width of frame
                sub ax, 2          ; ax = ������ - 2 (�������)
                shr ax, 1          ; ax = AX / 2 (�������� ������)
                mov cx, 160d       ; cx = 160 (���� � ������)
                mul cx             ; ax = AX * 160 (������������ �������� � ������)
                add di, ax         ; di = DI + ������������ ��������
                
                mov al, end_of_string   ; ��������� � al ����� ������ 
                mov cx, 2               ; cx = 2 
                xor dx, dx              ; ������� �������
        @@write_text_loop:              ; while ((*ptr != end_char) && (������ < �������)) { ����� }
                cmp al, byte ptr [si]   ; ���������� ������ ����� ������ � ������� �������� ������ �� ������� si
                je  @@write_text_end     ; if al == si -> write_text_end
                cmp dx, [bp-2]          ; ���������� �������� �������� ������� � dx  � �������� ��� ������ 
                jae @@write_text_end    ; ���� ������� ��������� �� ��������� � ����� 

        @@check_line_end:
                cmp cx, [bp+12]          ; ���� ������ ������� �������, ��������� �� ��������� ������
                jb @@line_end_done       ; if cx < [bp+12] -> line_end_done
        @@move_to_next_line:
                mov cx, 2               
                sub di, [bp+12]         ; �������� ����� ����� �� di, ����� ��������� � ������ ������� ������ 
                add di, 4               ; di + 4 (�������� �� 4 ����� ������)
                add di, 120             ; di + 120 (�������� �� 120 ������ ����)
        @@line_end_done:
                movsb                   ; �������� ���� �� ������ �� ������ [si] � ������ �� ������ [di] � ����������� si � di �� 1
                mov byte ptr es:[di], bh ; ���������� ���� � ����� ������ �� bh � ����� ������ �� ������ es:[di]
                inc di
                inc cx
                inc dx
                jmp @@write_text_loop   ; ������������ � ������ ����� 
        @@write_text_end:

                ;--------------------------
                
                pop si
                pop di
                pop dx                   ; ��������������� ��������
                pop cx 
                pop bx
                pop ax
                
                mov sp, bp               ; ��������������� ��������� �����
                pop bp
                ret 6
draw_frame      endp

;--------------------------------------------------------------------
; draw_line(�����)
; ������� ��� ��������� ����� � �������� �� ��������� ������
; ���������� � ��������: bx, di - ������� �� ��������� ������ (+160)
; ����������: ������
; ��������� ��������: cx, si
; ��������� ����������: 0
;--------------------------------------------------------------------
draw_line proc
                nop
                push bp                   ; ��������� ������� ���������
                mov  bp, sp               ; �������� �������� �������� sp � ������� bp. ������ bp ��������� �� ������� ������� �����
                
                push cx                   ; ��������� ��������
                push si

                push di                   ; ��������� ������ ��� �������� �� ��������� ������!

                ; ������ ������
                mov bl, byte ptr [si]     ; �������� ���� ����������� �� ������ [si] � ������� bl 
                mov word ptr  es:[di], bx ; ���������� ����� �� �������� bx � ����� ������ �� ������ es:[di]
                add di, 2                 ; di + 2. ����� ������� � ��������� ������ ����� ������ 
                inc si                    ; ��������� � ���������� �������  

                ; ��������� �������
                xor cx, cx                ; for (i = 2; i < �����; i++) { ... }
                add cx, 2                 ; ��-�� ������
        @@draw_line_loop:
                cmp cx, [bp+4]             
                jae @@draw_line_end       ; if cx >= ����� -> draw_line_end
                
                mov bl, byte ptr [si]     ; ��������� ���� ����� ������ �� ������ [si] � ������� bl  
                mov word ptr  es:[di], bx ; ���������� ����� � ����������� �� ��� es:[di]
                add di, 2                 ; di + 2. ����� ������� � ��������� ������ ������

                inc cx                    ; ��������� � ���������� ������� 
                jmp @@draw_line_loop      ; ��������� � ������ ����� 
        @@draw_line_end:
                ; ��������� ������
                inc si                  
                mov bl, byte ptr [si]     ; ��������� ���� �� ������ �� ��� [si] � ������� bl 
                mov word ptr  es:[di], bx ; ���������� ����� �� �������� � bx ����������� �� ������ es:[di]
                add di, 2                 ; ��������� � ��������� ������ ������ 

                ; ��������������� di � ��������� �� ��������� ������
                pop di
                add di, 160

                pop si                  ; ��������������� ��������
                pop cx

                mov sp, bp              ; ��������������� ��������� �����
                pop bp
                ret 2
draw_line endp

;--------------------------------------------------------------------
; skip_spaces()
; Function to skip spaces 
; Use & Change:  SI - address of string
; Return: nothing
; Save Regs: AX
; Locals: 0
;--------------------------------------------------------------------
skip_spaces	proc
                nop
                push ax 
;-------------------BODY---------------------
@@skip_loop:       ; while (al == ' ') { si++ }
                mov al, [si]            ; ��������� ���� �� ��� [si] � al. si ��������� �� ������� ������ ������ 
		        cmp al, ' '			
                jne @@skip_end          ; al != ' '
		        inc si                  ; ��������� � ���������� ������� 
		        jmp @@skip_loop         ; ��������� � ������ ����� 
@@skip_end:
;---------------------------------------------
                pop ax
	        ret
skip_spaces	endp

;--------------------------------------------------------------------
; atoi() -  ASCII to Integer
; Function to process decimal number from str
; Use & Change:  AX, SI - address of string
; Return: AX = return number
; Save Regs: BX,CX,DX
; Locals: 2
;--------------------------------------------------------------------
atoi    proc
        nop
        push bp                 ; ��������� ������� ���������
        mov  bp, sp             
        sub  sp, 4              ; �������� ����� ��� 2 ��������� ����������. ���� �� ����� ������� ����� ������, � ������ ������

        push bx                 ; ��������� ��������, bx - ������������ �������� 
        push cx
        push dx

;-------------------BODY---------------------
        call num_len             ; ax = ����� ������
        mov [bp-2], ax           ; [bp-2] = ������ ������
        xor ax, ax               ; ax = 0

        mov [bp-4], ax           ; [bp-4] = i = ax = 0
@@atoi_loop:                     ; for ([bp-4]; [bp-4] < [bp-2]; [bp-4]++)
            mov bx, [bp-4]       
            cmp bx, [bp-2]       ; ���������� ������� ������ � ������ ������, ������� �������� �� ��� [bp - 2]
            jae @@atoi_end       ; if bx >= ����� ������ -> atoi_end

            mov bx, 10d          ; bx * 10 -> bx + ����� -> bx * 10 -> ... (�������� �������)
            mul bx               ; ���� ��� �������������� ������ � ����� 
            mov dl, [si]         ; ��������� � ������� dl ������� ������ ������ �� ��� [si]
            sub dl, ascii_zero   ; �� �������� ������� �������� ��� ������� '0', ����� �������� ��� �������� ��������
            add ax, dx           ; ��������� ��� �������� �������� � ����������, ������� �������� � ax
            inc si               ; ��������� � ���������� ������� 

            inc word ptr [bp-4]  
            jmp @@atoi_loop      ; ��������� � ������ ����� 
@@atoi_end:
;---------------------------------------------
        pop dx                   ; ��������������� ��������
        pop cx 
        pop bx
        
        mov sp, bp               ; ��������������� ��������� �����
        pop bp
        ret
atoi    endp

;--------------------------------------------------------------------
; num_len
; Function of processing length of string till not digit
; Use & Change:  AX,SI - address of string
; Return: AX = length of number
; Save Regs: BX,CX,DX
; Locals: 0
;--------------------------------------------------------------------
num_len proc
        nop

        push bx                     ; ��������� ��������
        push cx
        push dx
;-------------------BODY---------------------
        mov bx, si
@@num_len_loop:		             ; while ([ax] >= '0' && [ax] <= '9')
        
        inc bx  

        xor dx, dx                   ; dx = 0
        mov al, [bx]            
        @@check_digit: 
                cmp al, '0'          ; ����������  al � �������� '0'
                jb @@num_len_end     ; if al < '0' -> num_len_end
                cmp al, '9'          ; ���������� al c '9'
                ja @@num_len_end     ; if al > '9' -> num_len_end
        @@is_digit:  
                mov dx, 1            ; �������� 1 � dx => �� ����� ����� 
        @@num_len_end:         
                cmp dx, 1            ; ��������� ���� �� ������� ����� () 
                je @@num_len_loop		
                sub bx, si            ; ax = bx - si - ����� ������ ��������� �� ���� 
                mov ax, bx            ; ������������� ����� � ax
;---------------------------------------------

        pop dx                         ; ��������������� ��������
        pop cx
        pop bx
        
        ret
num_len endp

;--------------------------------------------------------------------
; atoh
; Function to process hex number from str
; Use & Change:  AX, SI - address of string
; Return: AX = return number
; Save Regs: BX,CX,DX
; Locals: 2
;--------------------------------------------------------------------
atoh    proc
        nop
        push bp                 ; ��������� ������� ���������
        mov  bp, sp  
        sub sp, 4               ; �������� ����� ��� 2 ��������� ����������

        push bx                 ; ��������� ��������, bx - ������������ �������� 
        push cx
        push dx
;-------------------BODY---------------------
        call num_len            ; ax = ����� ������

        mov [bp-2], ax          ; [bp-2] = ������ ������
        xor ax, ax              ; ax = 0

        mov [bp-4], ax          ; [bp-4] = i = ax = 0
@@atoh_loop:                    ; for ([bp-4]; [bp-4] < [bp-2]; [bp-4]++)
            mov bx, [bp-4] 
            cmp bx, [bp-2]      ; ���������� ������� ������ � ������ ������ 
            jae @@atoh_end      ; if bx >= ����� ������ -> atoh_end

            mov bx, 16d         ; bx * 16 -> bx + ����� -> bx * 16 -> ...
            mul bx              ; ���� ��� �������������� ������ � �����
            mov dl, [si]

            ; �������� �������� �� ������ ������ ��� ������
            @@check_hex_digit: 
                        cmp dl, '0'         ; ���������� dl � '0'
                        jb @@hex_letter     ; if dl < '0' -> hex_letter
                        cmp dl, '9'
                        ja @@hex_letter     ; if dl > '9'    -> hex_letter
            @@hex_digit:    
                        sub dl, ascii_zero  ; '0-9' - '0' = �����
                        jmp @@hex_end
            @@hex_letter:  
                        sub dl, ascii_w_hex ; 'a-f' - 'w' = �����
            @@hex_end:
            add ax, dx
            inc si

            inc word ptr [bp-4]             ; ����������� ������ ���������� �� ��� [bp-4] 
            jmp @@atoh_loop                 ; ������� � ������ ����� 
@@atoh_end:
;---------------------------------------------

        pop dx           ; ��������������� ��������
        pop cx 
        pop bx
        
        mov sp, bp       ; ��������������� ��������� �����
        pop bp
        ret
atoh    endp

;--------------------------------------------------------------------
; style_frame- styles for the frame
;--------------------------------------------------------------------
style_frame     db 0c9h, 0cdh, 0bbh, 0bah, 020h, 0bah, 0c8h, 0cdh, 0bch
                db 0dah, 0c4h, 0bfh, 0b3h, 020h, 0b3h, 0c0h, 0c4h, 0d9h
                db 0dch, 0dch, 0dch, 0ddh, 020h, 0deh, 0dfh, 0dfh, 0dfh
                db 03h,  03h,  03h,  03h,  020h, 03h,  03h,  03h,  03h

;-------------------------------------------------------------------
end Start
