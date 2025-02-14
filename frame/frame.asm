.model tiny
.code
org 100h
locals @@

;--------------------------------------------------------------------
;                                 DEFINE
;--------------------------------------------------------------------
video_memory_segment equ 0b800h ; сегмент видеопамяти
command_line_ptr     equ 0080h  ; указатель на командную строку
end_of_string        equ 0024h  ; символ конца строки '$'
ascii_zero           equ 0030h  ; символ '0'
ascii_w_hex          equ 0057h  ; символ 'w' в шестнадцатеричном формате
exit_code            equ 4c00h  ; код завершения программы
frame_style_size     equ 9d     ; размер стиля рамки
frame_color          equ 047h   ; цвет рамки по умолчанию
shadow_color         equ 070h   ; цвет тени

;--------------------------------------------------------------------
start:	jmp main


main    proc
        nop
        push bp     ; сохраняем базовый указатель, регистр bp обычно используется для работы с локальными переменными и аргументами функции 
        mov  bp, sp  ; копируем значение регистра sp в bp => bp указатель на текущую вершину стека 
        sub  sp, 10  ; вычли 10 байт из регистра sp. выделяем 10 байт в стеке для локальных переменных. то есть по 2 байта на 5 переменных 

        ; сохранять регистры не нужно
        mov bx, video_memory_segment ; положили в регистр bx значение видео памяти 
        mov es, bx                   ; скопировали значение из bx в es. регистр es используется для работы с дополнительными сегментами памяти, в данном случае — видеопамятью.
        xor bx, bx                   ; обнулили значение bx 

        ; переменные для сохранения
        mov [bp-2 ], word ptr 0000h  ; размер командной строки. положили по адресу bp-2 значение 0 
        mov [bp-4 ], word ptr 0000h  ; длина рамки
        mov [bp-6 ], word ptr 0000h  ; ширина рамки
        mov [bp-8 ], word ptr 0000h  ; цвет рамки
        mov [bp-10], word ptr 0000h  ; стиль рамки
        mov si, command_line_ptr     ; si - указатель на командную строку
        xor ax, ax                   ; обнулили регистр ax
        mov al, [si]                 ; загружаем первый байт из командной строки в регистр al 
        mov word ptr [bp-2], ax      ; сохраняет размер командной строки в первую локальную переменную
        inc  si                       ; увеличиваем si на 1, чтобы перейти к следующему символу
        push si                      ; сохраняем si в стек 
        mov ax, word ptr [bp-2]      ; загружает размер командной строки в ax
        add si, ax                   ; переходим к концу командной строки
        mov [si], byte ptr end_of_string ; устанавливаем символ конца строки '$' в конец командной строки 
        pop si

        ; начинаем разбор командной строки
        call skip_spaces
        call atoi                   ; сканируем первое число -> длина
        mov [bp-4], ax              ; длина = ax 
        call skip_spaces
        call atoi                   ; сканируем второе число -> ширина
        mov [bp-6], ax              ; ширина = ax 
        call skip_spaces
        call atoh                   ; сканируем третье число (шестнадцатеричное) -> цвет 
        mov [bp-8], ax              ; цвет = ax 
        call skip_spaces
        call atoi                   ; сканируем четвертое число -> стиль рамки
        mov [bp-10], ax             ; стиль = ax 
        
        call skip_spaces
        ; начинаем рисовать рамку! draw_frame(длина, ширина, цвет, стиль, строка)
        push [bp-4]
        push [bp-6]
        push [bp-8]
        push [bp-10]
        push si
        call draw_frame
        
        ; завершение программы
        mov ax, exit_code           ; загружаем код завершения программы в регистры ax
        int 21h
        mov sp, bp                  ; восстанавливаем указатель стека
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
                push bp                 ; сохраняем базовый указатель. регистр bp используется для работы с локальными переменными и аргументами функции
                mov  bp, sp              ; копируем значение регистра sp в bp  
                sub  sp, 4               ; уменьшаем значение регистра sp на 4 в стеке для локальных переменных. для 2 переменных по 2 байта 
        
                push ax                 ; сохраняем регистры
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

                ; устанавливаем стиль
                ; curr_style = style_frame + frame_style_size * индекс
                xor si, si               ; обнулили si 
                lea si, style_frame      ; загружаем адрес переменной f_s в регистр si 
                mov ax, frame_style_size ; копируем адрес  f_s_s в регистр ax  
                mul word ptr [bp+6]      ; умножает ax на значение по адресу [bp+6] (индекс стиля рамки) и результат сохраняем в ax
                add si, ax               ; прибавляем результат умножения к si (si указывает на нужный стиль рамки)
                
                ; устанавливаем цвет
                xor bx, bx               ; обнуляет регистр bx
                mov bh, [bp+8]           ; копируем адрее цвета рамки в bh 

                ; устанавливаем di в центр
                xor dx, dx               ; обнулили регистра dx
                mov ax, 160d             ; 160 - количество байт на строку в видеопамяти
                mov dx, 11d              ; загружает значение 11 в регистр dx, где 11 номер строки 
                mul dx                   ; 11 * 160 = ax 
                add ax, 80               ; ax + 80
                mov di, ax               ; копируем регистр ax в di => di указывает на центр

                ; устанавливаем начальную позицию di
                mov ax, [bp+12]         ; di = центр - длина/2 * 2 (слово) - 160 * (ширина/2)
                mov cl, 2               ; загружает значение 2 в регистр cl
                div cl                  ; делит значение в регистре ax на cl. результат сохраняется в al, а остаток в ah
                @@check_alignment:      ; проверяем, если (di % 2 != 0) - нужно выровнять на 1 байт!
                        cmp ah, 0       ; сравниваем остаток ah от деления с 0 
                        je @@alignment_done ; if ah ==0 => переходим по метке. то есть длина рамки четная 
                @@align:                ; выравнивание начальной позиции 
                        dec di          ; уменьшает значение регистра di на 1
                @@alignment_done:
                sub di, [bp+12]         ; вычисляем значение которое находится по адресу [bp+12] из регистра di 
                mov ax, [bp+10]         ; загружаем значение из стека по адресу [bp+10]в регистр ax
                mov cl, 2d              ; загружает значение 2 в регистр cl
                div cl                  ; делит значение в регистре ax на cl. частное сохр в al, а остаток в ah
                xor ah, ah
                mov cx, 160d            ; загружаем значение 160 в регистр cx
                mul cx                  ; умножает значение в ax на cx
                sub di, ax              ; вычитаем значение ax из di. di указывает на начальную позицию для рисования рамки (с учетом ее ширины)

                push di                 ; сохраняем начало

                ; рисуем рамку
                push [bp+12]            ; передаем значение значение длины рамки в стек
                call draw_line  
                add  si, 3               ; si + 3

                xor cx, cx              ; for (i = 2; i < ширина; i++) { draw_line }
                add cx, 2               ; из-за границ
        @@draw_frame_loop: 
                cmp cx, [bp+10]         ; сравниваем значение cx со значением которое лежи по адресу в [bp+10]
                jae @@draw_frame_end    ; если cx >= [bp+10] то переходим по метке. то есть окончание цикла

                push [bp+12]
                call draw_line

                inc cx                  ; cx + 1
                jmp @@draw_frame_loop   ; переходим в начале цикла       
        @@draw_frame_end:
                add si, 3               ; si + 3
                push [bp+12]            
                call draw_line

                add si, 3               ; si + 3

                ; пишем текст
                pop di                  ; восстанавливаем начало
                add di, 2               ; чтобы текст не начинался вплотную к левой границе 
                add di, 160             ; смещаемся к тексту. то есть перешли на следующую строку 

                mov si, [bp+4]          ; меняем si

                mov ax, [bp+12]         ; [bp-2] = (длина - 2) * (ширина - 2) = площадь
                sub ax, 2               ; ax - 2
                mov dx, [bp+10]
                sub dx, 2               ; dx - 2 
                mul dx                  ; наша площадь рамки 
                mov [bp-2], ax          ; сохраняем площадь в локальную переменную по адресу [bp-2]

                ; Вычислим смещение по горизонтали от центра текста
                mov cx, [bp+12]   ; cx = длина рамы
                sub cx, 2         ; cx = длина - 2 (границы)
                mov ax, cx        ; ax = длина - 2
                sub ax, dx        ; ax = (длина - 2) - (ширина - 2)
                shr ax, 1         ; ax = AX / 2 (смещение центра)
                add di, ax        ; di = DI + смещение центра

                ; Вычислим вертикальное смещение от центра текста
                mov ax, [bp+10]    ; ax = width of frame
                sub ax, 2          ; ax = ширина - 2 (границы)
                shr ax, 1          ; ax = AX / 2 (смещение центра)
                mov cx, 160d       ; cx = 160 (байт в строке)
                mul cx             ; ax = AX * 160 (вертикальное смещение в байтах)
                add di, ax         ; di = DI + вертикальное смещение
                
                mov al, end_of_string   ; загружаем в al конец строки 
                mov cx, 2               ; cx = 2 
                xor dx, dx              ; счетчик площади
        @@write_text_loop:              ; while ((*ptr != end_char) && (размер < площадь)) { пишем }
                cmp al, byte ptr [si]   ; сравниваем символ конца строки с текущим символом текста по адрессу si
                je  @@write_text_end     ; if al == si -> write_text_end
                cmp dx, [bp-2]          ; сравнивает значение счетчика площади в dx  с площадью для текста 
                jae @@write_text_end    ; если площадь заполнена то переходим к метке 

        @@check_line_end:
                cmp cx, [bp+12]          ; если строка слишком длинная, переходим на следующую строку
                jb @@line_end_done       ; if cx < [bp+12] -> line_end_done
        @@move_to_next_line:
                mov cx, 2               
                sub di, [bp+12]         ; вычитаем длину рамки из di, чтобы вернуться к началу текущей строки 
                add di, 4               ; di + 4 (смещение на 4 байта вправо)
                add di, 120             ; di + 120 (смещение на 120 байтов вниз)
        @@line_end_done:
                movsb                   ; копирует байт из памяти по адресу [si] в память по адресу [di] и увеличивает si и di на 1
                mov byte ptr es:[di], bh ; записываем цвет в видео память из bh в видео память по адресу es:[di]
                inc di
                inc cx
                inc dx
                jmp @@write_text_loop   ; возвращаемся в начало цикла 
        @@write_text_end:

                ;--------------------------
                
                pop si
                pop di
                pop dx                   ; восстанавливаем регистры
                pop cx 
                pop bx
                pop ax
                
                mov sp, bp               ; восстанавливаем указатель стека
                pop bp
                ret 6
draw_frame      endp

;--------------------------------------------------------------------
; draw_line(длина)
; функция для рисования линии и перехода на следующую строку
; использует и изменяет: bx, di - переход на следующую строку (+160)
; возвращает: ничего
; сохраняет регистры: cx, si
; локальные переменные: 0
;--------------------------------------------------------------------
draw_line proc
                nop
                push bp                   ; сохраняем базовый указатель
                mov  bp, sp               ; копируем значение регистра sp в регистр bp. теперь bp указывает на текущую вершину стека
                
                push cx                   ; сохраняем регистры
                push si

                push di                   ; сохраняем ячейку для перехода на следующую строку!

                ; первый символ
                mov bl, byte ptr [si]     ; копируем байт находящийся по адресу [si] в регистр bl 
                mov word ptr  es:[di], bx ; записываем слово из регистра bx в видео память по адресу es:[di]
                add di, 2                 ; di + 2. чтобы перейти к следующей ячейки видео памяти 
                inc si                    ; переходим к следующему символу  

                ; следующие символы
                xor cx, cx                ; for (i = 2; i < длина; i++) { ... }
                add cx, 2                 ; из-за границ
        @@draw_line_loop:
                cmp cx, [bp+4]             
                jae @@draw_line_end       ; if cx >= длины -> draw_line_end
                
                mov bl, byte ptr [si]     ; загружаем байт видео памяти по адресу [si] в регистр bl  
                mov word ptr  es:[di], bx ; записываем слово в видеопамять по адр es:[di]
                add di, 2                 ; di + 2. чтобы перейти к следующей ячейки памяти

                inc cx                    ; переходим к следующему символу 
                jmp @@draw_line_loop      ; переходим к начало цикла 
        @@draw_line_end:
                ; последний символ
                inc si                  
                mov bl, byte ptr [si]     ; загружаем байт из памяти по адр [si] в регистр bl 
                mov word ptr  es:[di], bx ; записываем слово из регистра в bx видеопамять по адресу es:[di]
                add di, 2                 ; переходим к следующей ячейки памяти 

                ; восстанавливаем di и переходим на следующую строку
                pop di
                add di, 160

                pop si                  ; восстанавливаем регистры
                pop cx

                mov sp, bp              ; восстанавливаем указатель стека
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
                mov al, [si]            ; загружаем байт по адр [si] в al. si указывает на текущий символ строки 
		        cmp al, ' '			
                jne @@skip_end          ; al != ' '
		        inc si                  ; переходим к следующему символу 
		        jmp @@skip_loop         ; переходим в начало цикла 
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
        push bp                 ; сохраняем базовый указатель
        mov  bp, sp             
        sub  sp, 4              ; выделяем место для 2 локальных переменных. одна на будет хранить длину строки, а другая индекс

        push bx                 ; сохраняем регистры, bx - возвращаемое значение 
        push cx
        push dx

;-------------------BODY---------------------
        call num_len             ; ax = длина строки
        mov [bp-2], ax           ; [bp-2] = размер строки
        xor ax, ax               ; ax = 0

        mov [bp-4], ax           ; [bp-4] = i = ax = 0
@@atoi_loop:                     ; for ([bp-4]; [bp-4] < [bp-2]; [bp-4]++)
            mov bx, [bp-4]       
            cmp bx, [bp-2]       ; сравниваем текущий индекс с длиной строки, которой хранится по адр [bp - 2]
            jae @@atoi_end       ; if bx >= длине строки -> atoi_end

            mov bx, 10d          ; bx * 10 -> bx + цифра -> bx * 10 -> ... (сдвигаем разряды)
            mul bx               ; цикл для преобразования строки в число 
            mov dl, [si]         ; загружаем в регистр dl текущий символ строки по адр [si]
            sub dl, ascii_zero   ; из текущего символа вычитаем код символа '0', чтобы получить его числовое значение
            add ax, dx           ; добавляем это числовое значение к результату, который хранится в ax
            inc si               ; переходим к следующему символу 

            inc word ptr [bp-4]  
            jmp @@atoi_loop      ; переходим в начало цикла 
@@atoi_end:
;---------------------------------------------
        pop dx                   ; восстанавливаем регистры
        pop cx 
        pop bx
        
        mov sp, bp               ; восстанавливаем указатель стека
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

        push bx                     ; сохраняем регистры
        push cx
        push dx
;-------------------BODY---------------------
        mov bx, si
@@num_len_loop:		             ; while ([ax] >= '0' && [ax] <= '9')
        
        inc bx  

        xor dx, dx                   ; dx = 0
        mov al, [bx]            
        @@check_digit: 
                cmp al, '0'          ; сравниваем  al с символом '0'
                jb @@num_len_end     ; if al < '0' -> num_len_end
                cmp al, '9'          ; сравниваем al c '9'
                ja @@num_len_end     ; if al > '9' -> num_len_end
        @@is_digit:  
                mov dx, 1            ; записали 1 в dx => мы нашли цифру 
        @@num_len_end:         
                cmp dx, 1            ; проверяем была ли найдена цифра () 
                je @@num_len_loop		
                sub bx, si            ; ax = bx - si - длина строки состоящую из цифр 
                mov ax, bx            ; окончательная длина в ax
;---------------------------------------------

        pop dx                         ; восстанавливаем регистры
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
        push bp                 ; сохраняем базовый указатель
        mov  bp, sp  
        sub sp, 4               ; выделяем место для 2 локальных переменных

        push bx                 ; сохраняем регистры, bx - возвращаемое значение 
        push cx
        push dx
;-------------------BODY---------------------
        call num_len            ; ax = длина строки

        mov [bp-2], ax          ; [bp-2] = размер строки
        xor ax, ax              ; ax = 0

        mov [bp-4], ax          ; [bp-4] = i = ax = 0
@@atoh_loop:                    ; for ([bp-4]; [bp-4] < [bp-2]; [bp-4]++)
            mov bx, [bp-4] 
            cmp bx, [bp-2]      ; сравниваем текущий индекс с длиной строки 
            jae @@atoh_end      ; if bx >= длине строки -> atoh_end

            mov bx, 16d         ; bx * 16 -> bx + цифра -> bx * 16 -> ...
            mul bx              ; цикл для преобразования строки в число
            mov dl, [si]

            ; проверка является ли символ цифрой или буквой
            @@check_hex_digit: 
                        cmp dl, '0'         ; сравниваем dl с '0'
                        jb @@hex_letter     ; if dl < '0' -> hex_letter
                        cmp dl, '9'
                        ja @@hex_letter     ; if dl > '9'    -> hex_letter
            @@hex_digit:    
                        sub dl, ascii_zero  ; '0-9' - '0' = цифра
                        jmp @@hex_end
            @@hex_letter:  
                        sub dl, ascii_w_hex ; 'a-f' - 'w' = цифра
            @@hex_end:
            add ax, dx
            inc si

            inc word ptr [bp-4]             ; увеличиваем индекс хранящийся по адр [bp-4] 
            jmp @@atoh_loop                 ; прыгаем в начало цикла 
@@atoh_end:
;---------------------------------------------

        pop dx           ; восстанавливаем регистры
        pop cx 
        pop bx
        
        mov sp, bp       ; восстанавливаем указатель стека
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
