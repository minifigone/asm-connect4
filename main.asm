TITLE MASM Connect 4(main.asm)

INCLUDE Irvine32.inc
.data
reset_message BYTE "Would you like to play again? Type Y for Yes. Type N for No.", 0
invalid_char BYTE "You entered an invalid character, please try again.", 0
goodbye BYTE "Thank you for playing Connect 4, goodbye", 0
; board representation
; 00 06 12 18 24 30 36
; 01 07 13 19 25 31 37
; 02 08 14 20 26 31 38
; 03 09 15 21 27 33 39
; 04 10 16 22 28 34 40
; 05 11 17 23 29 35 41
board BYTE 42 DUP(0) ; six rows, seven columns; each six is a column, lowest num is highest position
rows BYTE 6
columns BYTE 7

empty BYTE 0
player_piece BYTE 1
computer_piece BYTE 2

;Recors the previous move taken be the AI
aiprevious dd ?

; for counting how many tokens are in a row/diagonal
vcheck_accumulator BYTE 0

.code

main PROC

	exit
main ENDP

WinProc PROC

ret
WinProc endp

checkVictory PROC
; edi -> pointer for last played token
; esi -> roaming pointer
; eax -> used for division
; ebx -> used to stage comparison
; ecx -> used for counting tokens of a type in a line
; edx -> used for division

mov esi, edi ; copy pointer
mov ecx, 0

; check down
down_check_loop:
	cmp ecx, 4 ; check victory condition on accumulator
	jge victory

	mov edx, 0
	mov eax, esi
	div rows ; will tell if at top of column, i.e. can't keep checking down ; TODO make work. i.e. don't div ptr value, div index determined somehow
	cmp edx, 0 ; at the top of the next column
	je horizontal_check_loop ;#2 at the top of the next column
	
	inc esi ; move the pointer down the column
	mov ebx, [esi] ; stage comparison
	cmp ebx, [edi] ; compare tokens
	je down_same_token
	jne down_diff_token
	
	down_same_token:
		inc ecx ; same token, increment counter
		jmp down_check_loop ;#2 same token, loop
	
	down_diff_token: ; don't keep checking if the token changed, shouldn't be a victory below that
		mov esi, edi ; reset pointer	
		mov ecx, 0 ; reset counter

horizontal_check_loop:
	; crawl left
	check_left_loop:
		cmp esi, 0 ; off the left side of the board ; TODO make work. i.e. don't div ptr value, div index determined somehow
		jl reset_ptr

		sub esi, rows
		mov ebx, [esi]
		cmp ebx, [edi]
		je left_same_token
		jne left_diff_token
		
		left_same_token:
			inc ecx
			jmp check_left_loop

		left_diff_token:
			jmp reset_ptr
	
	; reset
	reset_ptr:
		mov esi, edi

	; crawl right
	check_right_loop:
		cmp esi, 41 ; off the right side of the board ; TODO make work. i.e. don't div ptr value, div index determined somehow
		jg horizontial_check

		add esi, rows
		mov ebx, [esi]
		cmp ebx, [edi]
		je right_same_token
		jne right_diff_token		

		right_same_token:
			inc ecx
			jmp check_right_loop

		right_diff_token:
			jmp horizontial_check
		
	; check if greater than or equal to 4
	horizontal_check:
		cmp ecx, 4
		jge victory

	; reset for diagonal
	mov ecx, 0
	mov esi, edi

; check one diagonal, requires some sort of accumulator
check_tb_diagonal:
	check_up_left_loop:
		cmp esi, 0 ; off the left side of the board ; TODO make work. i.e. don't div ptr value, div index determined somehow
		jl reset_ptr
		mov edx, 0
		mov eax, esi
		div rows ; TODO make work. i.e. don't div ptr value, div index determined somehow
		cmp edx, 5 ; wrapped to the bottom of the next column, so off the top of the board

		sub esi, rows
		sub esi, 1
		mov ebx, [esi]
		cmp ebx, [edi]
		je tb_ul_same_token
		jne tb_ul_diff_token		

		tb_ul_same_token:
			inc ecx
			jmp check_up_left_loop

		tb_ul_diff_token:
			jmp reset_ptr

	reset_ptr:
		mov esi, edi

	check_down_right_loop:

	tb_diagonal_check:
		cmp ecx, 4
		jge victory

	; reset for other diagonal
	mov ecx, 0
	move esi, edi
	
; check other diagonal, requires some sort of accumulator
check_bt_diagonal:

victory:

no_victory:
ret ;
checkVictory ENDP

; procedure to check if the player would like to play the game again.
ResetGame proc
mov edx, offset reset_message
Call WriteString
Call ReadChar
Call Crlf

cmp edx, 'Y'
je reset:
jne checkN

checkN:
cmp edx, 'N'
je done
jne checky

checky:
cmp edx, 'y'
je reset:
jne checkn

checkn:
cmp edx, 'n'
je done
jne invalidChar

invalidChar:
mov edx, offset invalid_char
Call WriteString
Call Crlf
jmp reset

reset:
Call ResetBoard

done:
mov edx, offset goodbye
Call WriteString
Call Crlf
ret
ResetGame endp

; resets the board and begins new game
ResetBoard Proc

ret
ResetBoard endp

AIPlaceRandom PROC

mov eax, 7
Call RandomInt
Call findColumn

ret

AIPlace endp

;Bases placement off of previous move
AIPlacesmart PROC
mov eax, 7
mov ebx, aiprevious
cmp ebx, 0
je right
cmp ebx, 6
je left 
Call RandomInt
cmp eax, 3
jle left
jmp right
left:
sub eax, 1
Call findColumn
right:
add eax, 1
Call findColumn
ret
AIPlacesmart endp

;Places at the top of the column
placeTop PROC

;These move up the column until an open space is found
find:
cmp [esi], 0
je place 
dec esi
Loop find

;This puts a piece inside of the array
place:
mov [esi], 2

ret
placeTop endp

;Finds the column that is needed
findColumn PROC
mov esi, offset board

;These check which colum wall have the piece placed inside of it
cmp eax, 0
je place0
cmp eax, 1
je place1
cmp eax, 2
je place2
cmp eax, 3
je place3
cmp eax, 4
je place4
cmp eax, 5
je place5
cmp eax, 6
je place6
jmp finish

;These place a piece in the chosen column
;and place it at the top of the column
place0:
Call placeTop
mov aiprevious, eax
jmp finish
place1:
add esi, 11
Call placeTop
mov aiprevious, eax
jmp finish
place2:
add esi, 17
Call placeTop
mov aiprevious, eax
jmp finish
place3:
add esi, 23
Call placeTop
mov aiprevious, eax
jmp finish
place4:
add esi, 29
Call placeTop
mov aiprevious, eax
jmp finish
place5:
add esi, 35
Call placeTop
mov aiprevious, eax
jmp finish
place6:
add esi,41
Call placeTop
mov aiprevious, eax
jmp finish

finish:
ret
findColumn endp

;Implement A function to check whether or
;not a wanted column is filled
checkFullProc

ret
checkProc endp

END main