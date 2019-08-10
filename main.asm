TITLE MASM Connect 4(main.asm)

INCLUDE Irvine32.inc
.data
reset_message BYTE "Would you like to play again? Type Y for Yes. Type N for No.", 0
invalid_char BYTE "You entered an invalid character, please try again.", 0
goodbye BYTE "Thank you for playing Connect 4, goodbye", 0
fullMessage BYTE "Game over, the board is full!", 0
; board representation
; 00 06 12 18 24 30 36
; 01 07 13 19 25 31 37
; 02 08 14 20 26 31 38
; 03 09 15 21 27 33 39
; 04 10 16 22 28 34 40
; 05 11 17 23 29 35 41
board BYTE 42 DUP(0) ; six rows, seven columns; each six is a column, lowest num is highest position
rows DWORD 6
columns DWORD 7

;Variables needed to properly display and
;input to the board
empty BYTE 0
player_piece BYTE 1
computer_piece BYTE 2
selected BYTE 0
tempInput dd 0

winner BYTE 0 ; piece of winner added here when someone wins
full BYTE 0 ; Flips to 1 if the whole board is full
resetFlag BYTE 0 ; Flips if the game wants to be reset

;Records the previous move taken by the AI or user
aiprevious DWORD ?

; flag for the ai to stop a vertical victory
ai_stop_vertical DWORD 0

;Text needed for the GUI
rownumbers BYTE "1 2 3 4 5 6 7",0
blank BYTE "- ",0
capitalX BYTE "X ",0
capitalO BYTE "O ",0
point DWORD 0

; for counting how many tokens are in a row/diagonal
token_counter DWORD 0

; because indices are separate of pointers
roaming_index DWORD ?
static_index DWORD ?

;For user Input
column_input_prompt BYTE "Enter a number between 1 and 7 where you want to place your token: ",0
column_input_error BYTE "Invalid value!",0
column_input_full BYTE "Requested column is full!",0

;Winner messages
ai_winner BYTE "The Computer won!", 0
player_winner BYTE "You won!", 0

;AI play message
ai_placed_message BYTE "AIs move: ",0
debug_string BYTE "too far",0
.code

main PROC
NewGame:
mov resetFlag, 0
mov full, 0
mov winner, 0
mov eax, 0
mov ebx, 0
mov ecx, 0
mov edx, 0

;Starts the game with an AI random Place
mov selected, 0
Call AIPlaceRandom
Call BoardPrint

;This is the main running loop for the Program, it switches
;between a smartAI input and then moves to
;a playerinput afterwards
mainloop:
	mov selected, 1 ;Sets the value to let procedures know the player is placing
	Call getInput
	Call CheckVictory ;Checks if there is a victory after the Player moves
	Call BoardPrint ; Prints the board with the new piece
	mov al, winner
	cmp al, 1
	je PlayerWinner ;If there is a win jump to the AI win section
	Call allFull ;Checks to see if the board is full
	mov al, full
	cmp al, 1
	je BoardFull ;If the board is full jump to the appropriate boardFull section
	Call CRLF

	;Repeat above for steps for the AI and any subsequent moves

	mov selected, 0
	Call AIPlaceSmart
	Call checkVictory
	mov edx, offset ai_placed_message
	Call WriteString
	Call CRLF
	Call BoardPrint
	Call CRLF
	mov al, winner
	cmp al, 2
	je AIwinner
	Call allFull
	mov al, full
	cmp al, 1
	je BoardFull

	jmp mainloop

AIwinner: ;This prints out the appropriate message if the AI wins
mov edx, offset ai_winner
Call WriteString
Call Crlf
jmp replay 

PlayerWinner: ;This prints out the appropriate message if the player wins
mov edx, offset player_winner
Call WriteString
Call Crlf
jmp replay

BoardFull: ;This prints out the appropriate message of the board is full
mov edx, offset fullMessage
Call WriteString
Call CRLF

replay: ;This will reset the game if the user chooses to play again
	Call ResetGame
	mov al, resetFlag
	cmp al, 1
	je NewGame ;This jumps back to the top of the program if the user chosses to play again
	mov eax, 2000
	Call Delay
	exit
main ENDP


Clear PROC
	mov eax, 0
	mov ebx, 0
	mov ecx, 0
	mov edx, 0
ret
Clear endp

checkVictory PROC
; checks if a victory condition (4+ tokens in a row) has been met based on the last played token
; author: Tom Castle

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
mov ecx, 1

; check down
down_check_loop:
	inc esi ; move the pointer down the column
	mov eax, roaming_index
	inc eax ; move the index down the column
	mov roaming_index, eax

	mov token_counter, ecx
	cmp ecx, 3
	je stop_vertical
	jne check_for_vertical_victory
	
	stop_vertical: ; no more easy wins by just stacking things
		mov eax, 1
		mov ai_stop_vertical, eax

	check_for_vertical_victory:
		mov ecx, token_counter
		cmp ecx, 4 ; check victory condition on accumulator
		jge victory

	mov ecx, token_counter

	mov edx, 0
	mov eax, roaming_index
	div rows ; will tell if at top of column, i.e. can't keep checking down
	cmp edx, 0 ; at the top of the next column
	je down_diff_token ; at the top of the next column
	
	mov bl, [esi] ; stage comparison
	cmp bl, [edi] ; compare tokens
	je down_same_token
	jne down_diff_token
	
	down_same_token:
		inc ecx ; same token, increment counter
		jmp down_check_loop ; same token, loop
	
	down_diff_token: ; don't keep checking if the token changed, shouldn't be a victory below that
		mov esi, edi ; reset pointer	
		mov ecx, 1 ; reset counter
		mov token_counter, ecx
		mov eax, static_index
		mov roaming_index, eax ; reset index

horizontal_check_loop:
	; crawl left
	check_left_loop:
		sub esi, rows
		mov eax, roaming_index
		sub eax, rows
		mov roaming_index, eax

		cmp eax, 0 ; off the left side of the board
		jl reset_ptr_horizontal

		mov bl, [esi]
		cmp bl, [edi]
		je left_same_token
		jne left_diff_token

		left_same_token:
			inc ecx
			jmp check_left_loop

		left_diff_token:
			jmp reset_ptr_horizontal
	
	; reset
	reset_ptr_horizontal:
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

		mov bl, [esi]
		cmp bl, [edi]
		je right_same_token
		jne right_diff_token		

		right_same_token:
			inc ecx
			jmp check_right_loop

		right_diff_token:
			jmp horizontal_check
		
	; check if greater than or equal to 4
	horizontal_check:
		mov token_counter, ecx
		mov eax, ecx
		cmp ecx, 4
		jge victory
		mov ecx, token_counter

	; reset for diagonal
	mov ecx, 1
	mov token_counter, ecx
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

		mov bl, [esi]
		cmp bl, [edi]
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

		mov bl, [esi]
		cmp bl, [edi]
		je tb_dr_same_token
		jne tb_dr_diff_token

		tb_dr_same_token:
			inc ecx
			jmp check_down_right_loop

		tb_dr_diff_token:
			jmp tb_diagonal_check

	tb_diagonal_check:
		mov token_counter, ecx
		cmp ecx, 4
		jge victory
		mov ecx, token_counter

	; reset for other diagonal
	mov ecx, 1
	mov token_counter, ecx
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

		mov bl, [esi]
		cmp bl, [edi]
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
		sub esi, 1
		mov eax, roaming_index
		add eax, rows
		sub eax, 1
		mov roaming_index, eax

		cmp eax, 41 ; off the right side of the board
		jg bt_diagonal_check

		mov edx, 0
		div rows
		cmp edx, 5 ; wrapped to the bottom of the next column, so off the top of the board
		je bt_diagonal_check

		mov bl, [esi]
		cmp bl, [edi]
		je bt_ur_same_token
		jne bt_ur_diff_token

		bt_ur_same_token:
			inc ecx
			jmp count_up_right_loop

		bt_ur_diff_token:
			jmp bt_diagonal_check

	bt_diagonal_check:
		mov token_counter, ecx
		cmp ecx, 4
		jge victory
		mov ecx, token_counter

; maybe clear things
jmp no_victory

victory:
	mov eax, 0
	mov al, [edi]
	mov winner, al

no_victory:
ret 
checkVictory ENDP

; procedure to check if the player would like to play the game again.
;Author: Sam Partlow
ResetGame proc
AskAgain:
mov edx, offset reset_message
Call WriteString
Call ReadChar
Call Crlf

cmp al, 'Y'
je reset
jne checkN

checkN:
cmp al, 'N'
je done
jne checky

checky:
cmp al, 'y'
je reset
jne checkno

checkno:
cmp al, 'n'
je done
jne invalidChar


invalidChar:
mov edx, offset invalid_char
Call WriteString
Call Crlf
jmp AskAgain

reset:
Call ResetBoard
mov resetFlag, 1
jmp playagain

done:
mov edx, offset goodbye
Call WriteString
Call Crlf
playagain:
ret
ResetGame endp

; resets the board and begins new game
; Author: Sam Partlow
ResetBoard Proc
	mov al, 0
	mov ecx, 42
	mov edi, offset board

	reset_loop: ;Fills all the values in the board with 0
		mov [edi], aL
		inc edi
		loop reset_loop
ret
ResetBoard endp

;This function Takes a random integer from 0-6 for 
;the AI move and places it on the board 
;Author: Nick Foley
AIPlaceRandom PROC
ai_place_random:
	mov eax, 7
	Call Randomrange
	Call findColumn

ret
AIPlaceRandom endp

;Bases placement off of previous move, no matter if it was 
;user or AI chosen move 
;Author: Nick Foley
AIPlacesmart PROC

;This makes a range of numbers to determine whether
;or not the place the piece on top or next to the previous
;placed piece
ai_place_smart:
	mov eax, 15
	mov ebx, aiprevious
	mov ecx, 1
	cmp ai_stop_vertical, ecx ;If there is a possible vertical victory it will be stopped by this
	je stopWin
	cmp ebx, 0
	je right
	cmp ebx, 6
	je left 
	Call Randomrange
	cmp eax, 5
	jl left
	cmp eax, 10
	jg right
	jmp top
stopWin:
	mov ai_stop_vertical, 0 ;Resets the vertical victory stopper
top: ;Places on top of the previous
	mov eax, ebx
	Call findColumn
	jmp pieceplaced

left: ;Places to the left of the previous
	mov eax, ebx
	sub eax, 1
	Call findColumn
	jmp pieceplaced

right: ;Places on top of the previous
	mov eax, ebx
	add eax, 1
	Call findColumn
pieceplaced:
ret
AIPlacesmart endp

;Finds the column that is needed for 
;proper placement of the piece 
;Author: Nick Foley
findColumn PROC
	mov esi, offset board
	mov ebx, 0 ; for the index
	cmp selected, bl ;This checks if it is the AI placing
	jne ignore ;It will skip it if the player is placing

	;These instructions move the pointer to 41 (The max)
	;if the column chosen for placement is already full.
	;This ensures the AI will place a piece and there will
	;be no overflow.
	mov tempInput, eax
	MUL rows
	add esi, eax
	cmp [esi], bl ;Checks if the top of the column is full
	je moveon
	jmp place6
	moveon:
	mov esi, offset board
	mov eax, tempInput

	ignore:
	;These check which colum will have the piece placed inside of it
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
	add ebx, 5
	Call placeTop
	mov aiprevious, eax
	jmp finish
place1:
	add esi, 11
	add ebx, 11
	Call placeTop
	mov aiprevious, eax
	jmp finish
place2:
	add esi, 17
	add ebx, 17
	Call placeTop
	mov aiprevious, eax
	jmp finish
place3:
	add esi, 23
	add ebx, 23
	Call placeTop
	mov aiprevious, eax
	jmp finish
place4:
	add esi, 29
	add ebx, 29
	Call placeTop
	mov aiprevious, eax
	jmp finish
place5:
	add esi, 35
	add ebx, 35
	Call placeTop
	mov aiprevious, eax
	jmp finish
place6:
	mov esi, offset board
	add esi, 41
	add ebx, 41
	Call placeTop
	mov aiprevious, eax
	jmp finish

finish:
ret
findColumn endp

;Places a piece at the top of the column
;Author: Nick Foley
placeTop PROC

	;This moves down the column until an open space is found
	find:
		mov dl, [esi]
		cmp dl, 0
		je place 
		dec esi
		dec ebx ; pointer
	jmp find

	;This puts a piece inside of the board no matter if it is player or AI
	place:
		cmp selected, 1
		je player
		mov dl, computer_piece
		mov [esi], dl
		jmp placeover
	player:
		mov dl, player_piece
		mov [esi], dl
	placeover:
		mov edi, esi ; sets up for victory checking
		mov static_index, ebx
	ret
placeTop endp

;Prints the board for Connect 4 Author:
;All variabes are refreshed here
;Author: Nick Foley
BoardPrint PROC
	mov esi, offset board
	mov point, 0
	mov edx, offset rownumbers
	Call WriteString ;Prints out the column numbers
	CALL CRLF
	mov al, 1
	mov bl, 2
Print: ;Loops until every row has been printed
	mov ecx, 7
	PrintRow: ;Loops through each column and displays what is in each column of the specified row
		cmp [esi],al
		je X
		cmp [esi],bl
		je O
		jmp nothing
	; Prints out X for Player, O for AI, and - for blank
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
		add esi, 6 ;Increases the pointer for each column in the row

Loop PrintRow
	Call CRLF
	inc point
	cmp point, 6
	je printDone
	sub esi, 41 ;Moves the pointer to the beggining of the new row
	jmp Print
printDone: ;Loops until each row has been printed
ret
BoardPrint endp

getInput PROC

get_input:
; gets column input from user
; validates input and asks for another input if a bad value is supplied
; author: Tom Castle

	mov edx, offset column_input_prompt
	call WriteString
	call ReadInt
	cmp eax, 1
	jl invalid_input ; too small
	cmp eax, 7
	jg invalid_input ; too large
	jmp valid_input
	
invalid_input:
	mov edx, offset column_input_error
	call WriteString
	call CRLF
	jmp get_input

column_full:
	mov edx, offset column_input_full
	call WriteString
	call CRLF
	jmp get_input
	
valid_input:
	sub eax, 1
	mov tempInput, eax
	mov esi, offset board
	MUL rows
	add esi, eax
	mov dl, empty
	cmp [esi], dl
	jne column_full ; the column was full, ask for another value
	mov eax, tempInput
	Call findColumn
ret ;
getInput ENDP

;This procedure checks if the entire board is full
;and changes a variable 1 if it is
;Author: Nick Foley
allFull PROC
	mov al, 0
	mov esi, offset board
	cmp [esi], al
	je checkDone
	add esi, 6
	cmp [esi], al
	je checkDone
	add esi, 6
	cmp [esi], al
	je checkDone
	add esi, 6
	cmp [esi], al
	je checkDone
	add esi, 6
	cmp [esi], al
	je checkDone
	add esi, 6
	cmp [esi], al
	je checkDone
	add esi, 6
	cmp [esi], al
	je checkDone
	mov full, 1 ;Changes the full variable to 1 if the board is full
checkDone:	
ret 
allFull endp


END main
