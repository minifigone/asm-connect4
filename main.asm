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
rows dd 6
columns dd 7

empty BYTE 0
player_piece BYTE 1
computer_piece BYTE 2

winner BYTE 0 ; piece of winner added here when someone wins

;Records the previous move taken be the AI
aiprevious dd ?

;Variables needed for the GUI
rownumbers db "1 2 3 4 5 6 7",0
blank db "- ",0
capitalX db "X ",0
capitalO db "O ",0
point dd 0

; for counting how many tokens are in a row/diagonal
vcheck_accumulator BYTE 0
roaming_index DWORD ?
static_index DWORD ?

.code

main PROC
mov eax, 0
mov ebx, 0
mov ecx, 0
mov edx, 0
;mainloop:
Call AIPlaceRandom
Call AIPlaceSmart
Call AIPlaceRandom
Call AIPlaceSmart
Call AIPlaceRandom
Call AIPlaceSmart
Call BoardPrint
mov eax, 1000
Call Delay
;jmp mainloop
	exit
main ENDP


Clear PROC
	mov eax, 0
	mov ebx, 0
	mov ecx, 0
	mov edx, 0
ret
Clear endp
WinProc PROC

ret
WinProc endp

checkVictory PROC
; static_index -> index of last played token
; edi -> pointer for last played token
; esi -> roaming pointer
; eax -> used for division, used for temporarily holding index values
; ebx -> used to stage comparison
; ecx -> used for counting tokens of a type in a line
; edx -> used for division

mov esi, edi ; copy pointer
mov eax, static_index
mov roaming_index, eax ; copy index
mov ecx, 0

; check down
down_check_loop:
	cmp ecx, 4 ; check victory condition on accumulator
	jge victory

	mov edx, 0
	mov eax, roaming_index
	div rows ; will tell if at top of column, i.e. can't keep checking down
	cmp edx, 0 ; at the top of the next column
	je horizontal_check_loop ; at the top of the next column
	
	inc esi ; move the pointer down the column
	mov ebx, [esi] ; stage comparison
	cmp ebx, [edi] ; compare tokens
	je down_same_token
	jne down_diff_token
	
	down_same_token:
		inc ecx ; same token, increment counter
		inc esi
		mov eax, roaming_index
		inc eax
		mov roaming_index, eax
		jmp down_check_loop ; same token, loop
	
	down_diff_token: ; don't keep checking if the token changed, shouldn't be a victory below that
		mov esi, edi ; reset pointer	
		mov ecx, 0 ; reset counter
		mov eax, static_index
		inc eax
		mov roaming_index, eax

horizontal_check_loop:
	; crawl left
	check_left_loop:
		sub esi, rows
		mov eax, roaming_index
		sub eax, rows
		mov roaming_index, eax

		cmp eax, 0 ; off the left side of the board
		jl reset_ptr_horizontial

		mov ebx, [esi]
		cmp ebx, [edi]
		je left_same_token
		jne left_diff_token

		left_same_token:
			inc ecx
			jmp check_left_loop

		left_diff_token:
			jmp reset_ptr_horizontial
	
	; reset
	reset_ptr_horizontial:
		mov esi, edi
		mov eax, static_index
		mov roaming_index, eax

	; crawl right
	check_right_loop:
		add esi, rows
		mov eax, roaming_index
		add eax, rows
		mov roaming_index, eax

		cmp eax, 41 ; off the right side of the board
		jg horizontal_check

		add esi, rows
		mov ebx, [esi]
		cmp ebx, [edi]
		je right_same_token
		jne right_diff_token		

		right_same_token:
			inc ecx
			jmp check_right_loop

		right_diff_token:
			jmp horizontal_check
		
	; check if greater than or equal to 4
	horizontal_check:
		cmp ecx, 4
		jge victory

	; reset for diagonal
	mov ecx, 0
	mov esi, edi
	mov eax, static_index
	mov roaming_index, eax

; check one diagonal, requires some sort of accumulator
check_tb_diagonal:
	check_up_left_loop:
		sub esi, rows
		sub esi, 1
		mov eax, roaming_index
		sub eax, rows
		sub eax, 1
		mov roaming_index, eax

		mov edx, 0
		div rows
		cmp edx, 5 ; wrapped to the bottom of the next column, so off the top of the board
		je reset_ptr_tb_diagonal

		mov eax, roaming_index
		cmp eax, 0 ; off the left side of the board
		jl reset_ptr_tb_diagonal

		mov ebx, [esi]
		cmp ebx, [edi]
		je tb_ul_same_token
		jne tb_ul_diff_token

		tb_ul_same_token:
			inc ecx
			jmp check_up_left_loop

		tb_ul_diff_token:
			jmp reset_ptr_tb_diagonal

	reset_ptr_tb_diagonal:
		mov esi, edi
		mov eax, static_index
		mov roaming_index, eax

	check_down_right_loop:
		add esi, rows
		add esi, 1
		mov eax, roaming_index
		add eax, rows
		add eax, 1
		mov roaming_index, eax

		cmp eax, 41 ; off the right side of the board
		jg tb_diagonal_check
		
		mov edx, 0
		div rows
		cmp edx, 0 ; wrapped to the top of the next column, so off the bottom of the board
		je tb_diagonal_check

		mov ebx, [esi]
		cmp ebx, [edi]
		je tb_dr_same_token
		jne tb_dr_diff_token

		tb_dr_same_token:
			inc ecx
			jmp check_down_right_loop

		tb_dr_diff_token:
			jmp tb_diagonal_check

	tb_diagonal_check:
		cmp ecx, 4
		jge victory

	; reset for other diagonal
	mov ecx, 0
	mov esi, edi
	mov eax, static_index
	mov roaming_index, eax
	
; check other diagonal, requires some sort of accumulator
check_bt_diagonal:
	check_down_left_loop:
		sub esi, rows
		add esi, 1
		mov eax, roaming_index
		sub eax, rows
		add eax, 1
		mov roaming_index, eax

		cmp eax, 0 ; off the left side of the board
		jl reset_ptr_bt_diagonal

		mov edx, 0
		div rows
		cmp edx, 0 ; wrapped to the top of the next column, so off the bottom of the board
		je reset_ptr_bt_diagonal

		mov ebx, [esi]
		cmp ebx, [edi]
		je bt_dl_same_token
		jne bt_dl_diff_token

		bt_dl_same_token:
			inc ecx
			jmp check_down_left_loop

		bt_dl_diff_token:
			jmp reset_ptr_bt_diagonal

	reset_ptr_bt_diagonal:
		mov esi, edi
		mov eax, static_index
		mov roaming_index, eax

	count_up_right_loop:
		add esi, rows
		add esi, 1
		mov eax, roaming_index
		add eax, rows
		add eax, 1
		mov roaming_index, eax

		cmp eax, 41 ; off the right side of the board
		jg bt_diagonal_check

		mov edx, 0
		div rows
		cmp edx, 5 ; wrapped to the bottom of the next column, so off the top of the board

		mov ebx, [esi]
		cmp ebx, [edi]
		je bt_ur_same_token
		jne bt_ur_diff_token

		bt_ur_same_token:
			inc ecx
			jmp count_up_right_loop

		bt_ur_diff_token:
			jmp bt_diagonal_check

	bt_diagonal_check:
		cmp ecx, 4
		jge victory

; maybe clear things
jmp no_victory

victory:
	; raise a flag or something, i don't know

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
je reset
jne checkN

checkN:
cmp edx, 'N'
je done
jne checky

checky:
cmp edx, 'y'
je reset
jne checkn

checkno:
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
Call Randomrange
Call findColumn

ret

AIPlaceRandom endp

;Bases placement off of previous move
AIPlacesmart PROC
	mov eax, 7
	mov ebx, aiprevious
	cmp ebx, 0
	je right
	cmp ebx, 6
	je left 
	Call Randomrange
	cmp eax, 3
	jle left
	jmp right
left:
	mov eax, ebx
	sub eax, 1
	sub eax, 1
	Call findColumn
right:
	mov eax, ebx
	add eax, 1
	Call findColumn
ret
AIPlacesmart endp

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
	add esi, 5
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

;Places at the top of the column
placeTop PROC

	;These move up the column until an open space is found
	find:
		mov dl, [esi]
		cmp dl, 0
		je place 
		dec esi
	jmp find

	;This puts a piece inside of the array
	place:
		mov dl, computer_piece
		mov [esi], dl
	ret
placeTop endp


;Implement A function to check whether or

checkFull Proc
	
ret
checkFull endp

;Prints the board for Connect 4 Author: Nick Foley
;All variabes are refreshed here
BoardPrint PROC
	mov esi, offset board
	mov point, 0
	mov edx, offset rownumbers
	Call WriteString
	CALL CRLF
	mov al, 1
	mov bl, 2
Print:
	mov ecx, 7
	PrintRow:
		cmp [esi],al
		je X
		cmp [esi],bl
		je O
		jmp nothing
	X:
		mov edx, offset capitalX
		Call WriteString
		jmp over
	O:
		mov edx, offset capitalO
		Call WriteString
		jmp over
	nothing:
		mov edx, offset blank
		Call WriteString
		jmp over
	over:
		add esi, 6

Loop PrintRow
	Call CRLF
	inc point
	cmp point, 6
	je printDone
	sub esi, 41
	jmp Print
printDone:
ret
BoardPrint endp
END main