;** Z-80(tm) DISASSEMBLER V1.40beta1+dev - (c) 2015-25 GmEsoft, All rights reserved. **
;
;	Mon Apr  7 11:41:18 2025
;
;	Disassembly of : HELPGEN.CMD
;	Equates file   : HELPGEN.EQU
;	Equates file   : LSDOSSVC.EQU
;	Screening file : HELPGEN.SCR
;
;	COM	'Copyright (c) 1983 by Logical Systems Incorporated - - ALL Rights Reserved'
;
$SVC    MACRO   #N
        LD      A,#N
        RST     0028H
        ENDM
;
@KEY	EQU	0001H		; wait for key press
@DSP	EQU	0002H		; display character
@CTL	EQU	0005H		; make control request
@PRT	EQU	0006H		; send character to printer
@KEYIN	EQU	0009H		; accept line of input
@DSPLY	EQU	000AH		; display message line
@PRINT	EQU	000EH		; print message line
@VDCTL	EQU	000FH		; control video display
@DATE	EQU	0012H		; get system date
@EXIT	EQU	0016H		; return to LS-DOS
@ERROR	EQU	001AH		; post error message
@INIT	EQU	003AH		; open new or existing file
@OPEN	EQU	003BH		; open existing file
@CLOSE	EQU	003CH		; close file
@CKEOF	EQU	003EH		; check for end-of-file
@LOF	EQU	0040H		; calculate EOF LRN
@READ	EQU	0043H		; read record from file
@WRITE	EQU	004BH		; write record to file
@FSPEC	EQU	004EH		; parse filename
@FEXT	EQU	004FH		; set up default extension
@GTDCB	EQU	0052H		; get device control block
@DIV16	EQU	005EH		; divide 16 by 8
@HIGH$	EQU	0064H		; get or set HIGH$
;
;
	ORG	3000H
;
; 	HELPGEN Entry Point
;
HELPGEN	PUSH	HL		; Save command line pointer
	LD	HL,0000H	; HL=0 to get current HIGH$
	LD	B,00H		;
	$SVC	@HIGH$		; get or set HIGH$
	LD	(_HIGH$),HL	; HIGH$ address
;	Display title
$TITLE	LD	HL,TITLE$	; Help System Text Processor Version 6.0
	$SVC	@DSPLY		; display message line
;	Ask input file
$ASKIN	LD	HL,SOURCE?	; Enter SOURCE file specification :
	$SVC	@DSPLY		; display message line
	LD	HL,_BUFFER	; 80-chars buffer
	LD	B,16H		; 22 chars max ffffffff/xxx.pppppppp:d (should be 23)
	$SVC	@KEYIN		; accept line of input
	JR	NC,$ASKIJ1	; Continue if <Break> not pressed
	LD	HL,0000H	;   else...
	$SVC	@EXIT		;   return to LS-DOS
$ASKIJ1	LD	A,B		; Anything entered?
	OR	A		;
	JR	Z,$ASKIN	; Ask again if not
	LD	DE,_FCBIN	; Input FCB
	$SVC	@FSPEC		; parse filename
	JR	Z,$ASKIJ2	; Continue if filename is correct
	LD	HL,BADSRC$	;   Else "Improper Source Filename"
	JR	$ASKIN		;   and Ask input file again
;
;	Input filename is correct - open the file
;
$ASKIJ2	LD	B,01H		; Input file LRL = 1
	LD	HL,_BUFIN	; Input file buffer
	$SVC	@OPEN		; open existing file
	JR	Z,$ASKOUT	; Continue if no error
	CP	2AH		;
	JR	Z,$ASKOUT	; or if error "LRL Mismatch"
	OR	0C0H		;
	LD	C,A		; Otherwise:
	$SVC	@ERROR		; post error message
	LD	HL,ANYKEY$	; Press ANY key to continue
	$SVC	@DSPLY		; display message line
	$SVC	@KEY		; wait for key press
	JR	$TITLE		; Display title and ask input file
;
;	Input file opened - Ask output file name
;
$ASKOUT	LD	HL,DESTIN?	; Enter DESTINATION file name     :
	$SVC	@DSPLY		; display message line
	LD	B,0AH		; 10 chars max: ffffffff:d
	LD	HL,_BUFFER	; 80-chars line buffer
	$SVC	@KEYIN		; accept line of input
	JP	C,ABORT@	; Close and abort
	LD	A,B		; Anything entered?
	OR	A		;
	JR	Z,$ASKOUT	; if not, ask again
	PUSH	BC		; save name length
	LD	DE,_FCBOUT	; Output FCB
	$SVC	@FSPEC		; parse filename
	JR	NZ,$ASKOUT	; Ask again if improper filespec
	LD	HL,HLP$		; HLP default file extension
	$SVC	@FEXT		; set up default extension
	POP	BC		; restore name length
	LD	A,B		; add 4 to the length (/HLP)
	ADD	A,04H		;
	LD	B,00H		;
	LD	C,A		; to BC
	LD	HL,_NAMOUT	; Output file name buffer
	EX	DE,HL		;
	LDIR			; Move the filename to buffer
	EX	DE,HL		;
	LD	(HL),03H	; Terminate the filename
	LD	DE,_FCBOUT	; Output FCB
	LD	B,01H		; Output file LRL = 1
	LD	HL,_BUFOUT	; Output file buffer
	$SVC	@INIT		; open new or existing file
	JR	C,$DOGEN	; Generate HLP file
	LD	HL,_NAMOUT	; Output file name buffer
	$SVC	@DSPLY		; display message line
	LD	HL,FILXST?	; file already exists - destroy it?
	$SVC	@DSPLY		; display message line
	$SVC	@KEY		; wait for key press
	CP	59H		; 'Y' ?
	JR	Z,$DOGEN	; if yes, go generate HLP file
	CP	79H		; 'y' ?
	JR	Z,$DOGEN	; if yes, go generate HLP file
	CP	4EH		; 'N' ?
	CALL	Z,CLOOUT@	; if yes, close out file, abort on error
	CP	6EH		; 'n' ?
	CALL	Z,CLOOUT@	; if yes, close out file, abort on error
	JR	$ASKOUT		; ask output filename again
;
;	All files opened - generate HLP file
;
$DOGEN	POP	HL		; Restore command line pointer
	CALL	PFLAG@		; 'P' (print) flag specified?
	CALL	CKSAME@		; Abort if source and dest files are the same
	EXX			; Swap regs
	LD	HL,PROCSF$	; Processing Source File
	$SVC	@DSPLY		; display message line
	LD	HL,_RECIN	; HL' = Input record buffer (1 byte)	
	LD	DE,_FCBIN	; DE' = Input FCB
	EXX			; Swap back regs
	CALL	SHWPCT@		; Show progress bar if length/50 > 0
	LD	IY,_PFLAGS	; Bit-mapped proc flags (via IY+0) B7=key B6=SPC B5=EOF
	LD	IX,_INDEX	; Index pointer
	LD	HL,(_HIGH$)	; HIGH$ address
	LD	(IX+1),L	; Save to index's key pointer
	LD	(IX+2),H	;  (stored backwards!)
	SET	7,(IY+0)	; Set KEY flag
	LD	DE,_BUFFER	; 80-chars line buffer
	CALL	READ@		; Read a byte
	LD	(DE),A		; Store in buffer
	CP	20H		; ' '
	JP	C,$NULKEY	; if not displayable, exit with "Null Key Encountered"
	LD	C,4FH		; 80 chars - 1
	INC	DE		; bump buffer ptr
;
;	Loop to read lines from file
;
$READLN	LD	B,C		; B = C = remaining chars in line counter
	LD	L,E		; HL = DE
	LD	H,D
;	Loop to fill the line buffer with chars of the file
$READCH	CALL	READ@		; Read a byte
	CP	00H		; NUL ?
	JR	Z,$READCH	; read next byte if yes
	BIT	5,(IY+0)	; Did we reach the EOF?
	JR	Z,L3116		; go if not
;	End-of-file: add end-of-page if not present
	DEC	HL		; get previous char in buffer
	LD	A,(HL)		;
	CP	0CH		; is it an end-of-page (Form Feed) ?
	INC	HL		;
	JR	Z,$RDCHJ1	; go if yes
	LD	(HL),0CH	; else store an end-of-page
	INC	HL		; advance pointer
$RDCHJ1	LD	(HL),03H	; store an end-of-text
	JR	$CONVLN		; Convert line
;
;	No EOF: change graphics to ' ' and store in line buffer
;
L3116	CP	80H		; Is it a graphics char (>= 80H)
	JR	C,$NOGRAF	; If yes:
	LD	A,20H		;   replace with a white space
$NOGRAF	LD	(HL),A		; Store the char
	INC	HL		; advance pointer
	DJNZ	$READCH		; read next char
;
;	Buffer full or end-of-file: Compress line
;
$CONVLN	CALL	PRGRES@		; Update progress bar
	LD	C,00H		;
	LD	HL,_BUFFER	; HL = 80-chars buffer
	PUSH	HL		; DE = HL
	POP	DE		;
	DEC	DE		; DE = preceding char
;
;	Loop to convert chars
;
$CONVCH	LD	A,(HL)		; Get char
	BIT	7,(IY+0)	; Are we reading an index key?
	JP	NZ,RDKEY@	; Go if yes
	CP	0DH		; Is it an EOL (Carriage Return) ?
	JP	Z,$EOL		; Go if yes
	CP	0CH		; Is it an EOP (Form Feed) ?
	JP	Z,$EOP		; Go if yes
	CP	03H		; Is it an EOT ?
	JP	Z,$EOT		; Go if yes
	CP	20H		; Is it a white space ?
	JR	NZ,$CONVJ4	; Go if nots
	BIT	6,(IY+0)	; Are we compressing spaces ?
	JR	Z,$CONVJ1	; Go if not
	PUSH	HL		; Save HL
	LD	HL,(_SPCCTR)	; Increment white spaces counter
	INC	HL		;
	LD	(_SPCCTR),HL	;
	POP	HL		; Restore HL
	JR	$NEXTCH		; Bump to next char
;
;	Not in space compression
;
$CONVJ1	LD	A,(HL)		; Get char
	CP	03H		; End-of-text ?
	JR	Z,$CONVJ4	;   go if yes
	INC	HL		; Point to Next char
	LD	A,(HL)		; is it followed by 
	CP	20H		; a white space ?
	DEC	HL		;
	JR	NZ,$CONVJ2	;   go if not
	DEC	DE		; Get char before last char
	LD	A,(DE)		;
	CP	80H		; Was it a "char+space" ?
	INC	DE		;
	JR	NC,$COMMIT	; if yes, commit char to buffer
	LD	A,(DE)		; Get last char
	CP	80H		; Was it a "char+space" ?
	SET	6,(IY+0)	; Enter space compression mode
	JR	C,$CONVJ3	; Jump if not
	JR	$NEXTCH		; Bump to next char
;
;	Not in space compression and no white space
;
$CONVJ2	DEC	DE		; Get char before last char
	LD	A,(DE)		;
	CP	80H		; is it a space compression char?
	INC	DE		;
	JR	NC,$CONVJ4	; if yes, treat this char as normal char
$CONVJ3	LD	A,(DE)		; Get last char
	CP	80H		; is it a "char+space" ?
	JR	NC,$COMMIT	; if yes, Commit char to buffer
	PUSH	HL		; Save HL
	OR	A		; 
	LD	HL,_BUFFER	; 80-chars line buffer
	SBC	HL,DE		; is DE pointing before the buffer?
	POP	HL		; Rest HL
	JP	NC,$ENDCMP	; If yes, reset COMP, commit char and bump
	OR	80H		; Set "char+space"
	LD	(DE),A		; Store char
	INC	HL		; bump pointers HL (source)
	INC	DE		; and DE (dest)
	PUSH	BC		; Save regs
	PUSH	HL		;
	PUSH	DE		;
	EX	DE,HL		; Source ptr to DE
	LD	HL,_ENDBUF	; End buffer to HL
	INC	HL		; Compute number of bytes to move
	XOR	A		;
	SBC	HL,DE		;
	LD	C,L		;   to BC
	LD	B,H		;
	POP	DE		; restore regs
	POP	HL		;
	PUSH	DE		; re-save them
	PUSH	HL		; 
	LDIR			; Move bytes (compress space)
	POP	HL		; restore regs
	POP	DE		;
	POP	BC		;
	DEC	HL		; Decrement pointers
	DEC	DE		;
	JP	$CONVCH		; Convert next char
;
; 	Put char, set bit 7 if space follows
;
$CONVJ4	BIT	6,(IY+0)	; Space compression active?
	JR	Z,$COMMIT	;   if not, commit char to buffer
	LD	A,(_SPCCTR)	; else, get white spaces counter,
	OR	80H		; set high bit
	INC	DE		; increment dest ptr,
	LD	(DE),A		; store the space compression code
	JP	$COMPSP		; Compress spaces
;
;	Commit char to buffer
;
$COMMIT	INC	DE		; Bump dest ptr
;	Bump to next char
$NEXTCH	INC	HL		; Bump source ptr
	INC	C		; Bump source counter
	JP	$CONVCH		; Loop - Convert next char
;
;	Reset COMP, commit char and bump
;
$ENDCMP	RES	6,(IY+0)	; Reset Space compression active flag
	JR	$COMMIT		; Commit char to buffer
;
;	End-of-text (end of input line)
;
$EOT	LD	B,C		; Get char counter
	PUSH	HL		; HL to DE
	POP	DE		;
	DEC	DE		; DE -= 2
	DEC	DE		;
	DEC	B		; char count - 1
$EOTL1	LD	A,(DE)		; get char at HL-2
	CP	80H		; is it a "char+space" or compression code?
	JR	NC,$EOTJ3	; if yes, exit loop
	DEC	DE		; go back one more time
	DJNZ	$EOTL1		; and loop to get previous char
	BIT	5,(IY+0)	; End-of-file reached ?
	JR	Z,$EOTJ2	; Jump if not
	LD	A,C		; Get char counter
	CP	00H		; Zero?
	JP	Z,SORTFL@	; if yes, sort and file keys
	JP	$EOL		; else put End-of-line: put 0DH or 8DH if space follows
;
;	End-of-file not reached
;
$EOTJ2	SET	3,(IY+0)	; set flag 3 (TBD)
	DEC	HL		; unget last (invalid) char
	JP	$EOL		; End-of-line: put 0DH or 8DH if space follows
;
;	High bit of char at HL-2 is set
;
$EOTJ3	LD	C,B		;
	SET	4,(IY+0)	; set flag 4 (TBD)
	XOR	80H		; reset high bit
	LD	(DE),A		; put char 
	BIT	6,(IY+0)	; Are we in space compression mode?
	JP	Z,$EOL		; if not: End-of-line: put 0DH or 8DH if space follows
	PUSH	DE		; else
	POP	HL		; get dest ptr
	INC	HL		; ++ptr
	LD	(HL),0DH	; put EOL
	INC	HL		; ++ptr
	LD	(HL),03H	; put EOT
	DEC	HL		; --ptr
	JP	$EOL		; End-of-line: put 0DH or 8DH if space follows
;
;	Garbage
;
	JP	$EOL		; End-of-line: put 0DH or 8DH if space follows
;
;------------------------------------------------------------------------------
;
;	Sort and file keys
;
SORTFL@	LD	HL,SORTFL$	; Sorting and filing keys
	$SVC	@DSPLY		; display message line
	LD	(IY+0),00H	; Clear flags
	PUSH	IX		; Index ptr
	POP	DE		; to DE
	LD	HL,_INDEX	; Keywords index pointer (via IX+0..4), length = 5
	EX	DE,HL		; HL=index table ptr, DE=table origin
	XOR	A		;
	SBC	HL,DE		; HL=table length
	PUSH	HL		;
	POP	BC		; to BC
	LD	DE,0005H	; DE = index entry length
				; We'll divide the index table length
				;   by the index entry length
				;   to get the number of entries...
				; Note: it would have been easier
				;   to count the index entries
				;   while the entries are added...
				; But the division algorithm
				;   is interesting by itself.
;
;	Division of BC (table length) by DE (5)
;	Non-restoring division algorithm from Rodnay Zaks' book
;	"How to Program the Z-80" (Radio Shack 62-2066) p. 139
;
;	Input:
;		DE = divisor
;		BC = dividend (DVD)
;	Output:
;		HL = remainder
;		BC = quotient
;
;				; Comments from the book:
$DIV16	LD	A,B		; Get (DVD) high
	LD	HL,0		; Clear result
	LD	B,16		; Counter
;	Subtraction loop
$TRYSUB	RL	C		; Rotate result + acc left
	RLA			;
	ADC	HL,HL		; Left shift. Never sets carry.
	SBC	HL,DE		; Minus divisor
$NULL	CCF			; Result bit
	JR	NC,$NGV		; Accumulator negative?
$PTV	DJNZ	$TRYSUB		; Counter zero?
	JR	$DONE		; 
;	Had a borrow from subtraction
;	Addition loop
$RESTOR	RL	C		; Rotate result + acc left
	RLA			; 
	ADC	HL,HL		; As above
	AND	A		; 
	ADC	HL,DE		; Restore by adding dvsr
	JR	C,$PTV		; Result positive
	JR	Z,$NULL		; Result zero
$NGV	DJNZ	$RESTOR		; Counter zero?
;	End division
$DONE	RL	C		; Shift in result bit
	RLA			;
	ADD	HL,DE		; Correct remainder
	LD	B,A		; Quotient is in B, C
;
;	End of division algorithm
;
	LD	IX,_INDEX	; Index origin
	LD	(_ENTCTR),BC	; Store number of index entries
	LD	IX,_INDEX	; Index origin (again, unneeded)
;
;	Index sort outer loop
;
$SORTOL	LD	HL,(_ENTCTR)	; Number of index entries to HL
	XOR	A		;
	SBC	HL,BC		; Sub remaining entries
	INC	HL		; so, 1
	LD	(_DONENT),HL	; Done entries in both loops
	DEC	BC		; Decrement number of remaining entries
	LD	A,B		; No remaining entry?
	OR	C		;
	JR	Z,$FILIDX	; Exit loop if yes
	PUSH	BC		; Save # remaining entries
	PUSH	IX		; Outer loop index pointer (IX)
	POP	IY		; to inner loop index ptr (IY)
;
;	Index sort inner loop
;
$SORTIL	LD	DE,0005H	; Bump inner loop index ptr (IY)
	ADD	IY,DE		;
	LD	BC,(_DONENT)	; Done entries in both loops
	LD	HL,(_ENTCTR)	; Number of table entries
	XOR	A		; 
	SBC	HL,BC		; All entries done in both loops?
	JR	Z,$SORTIX	; Exit inner loop if yes
	INC	BC		; Increment done entries
	LD	(_DONENT),BC	;   and write back
	LD	E,(IX+1)	; Get outer loop keyword
	LD	D,(IX+2)	;   to DE
	LD	L,(IY+1)	; Get inner loop keyword
	LD	H,(IY+2)	;   to HL
	LD	A,(DE)		; Get 1st char of outer loop keyword
	CP	(HL)		; Compare with 1st char of inner loop keyword
	JR	C,$SORTIL	; If less, then both entries
				;   are in the correct order, so loop again
	JR	NZ,$SWAP	; If greater, swap index entries
				; otherwise need to compare the remaining chars
	LD	A,(IX+0)	; Get outer loop keyword length
	LD	C,(IY+0)	; Get inner loop keyword length
	CP	C		; Is outer loop keyword shorter?
	JR	C,$CPKEYS	; If yes, take the outer loop length
	LD	A,C		; Else take the inner loop length
;	Compare index keys
$CPKEYS	SUB	03H		; Subtract 3 (TODO: why?)
	LD	B,A		; To B = loop counter
;	Loop to compare keys
$CPKYL1	DEC	HL		; point to inner loop index key next char
	DEC	DE		; point to outer loop index key next char
	LD	A,(DE)		; is inner loop next char
	CP	(HL)		;   before the outer loop next char?
	JR	C,$SORTIL	; If less, then both entries
				;   are in the correct order, 
				;   so loop again (inner loop)
	JR	NZ,$SWAP	; If greater, swap index entries
				; otherwise check next chars
	DJNZ	$CPKYL1		; Done comparing the key chars
	LD	A,(IX+0)	; Is the outer loop key
	CP	C		;   shorter than the inner loop key?
	JP	Z,DUPKEY@	; If same length, error: 
				;   Duplicate Keys Encountered
	JR	NC,$SWAP	; If longer, swap index entries
	JR	$SORTIL		; Else loop again (inner loop)
;
;	Done inner loop
;
$SORTIX	CALL	OUTKEY@		; Display/Print the sorted index key
	LD	DE,0005H	; Bump the outer loop index pointer
	ADD	IX,DE		;
	POP	BC		; Restore # remaining entries
	JR	$SORTOL		; Index sort outer loop
;
;	Swap index entries
;
$SWAP	LD	B,05H		; Number of bytes to exchange
	PUSH	IX		; Outer loop ptr to HL
	POP	HL		;
	PUSH	IY		; Inner loop ptr to DE
	POP	DE		;
$SWAPL1	LD	C,(HL)		; Get one loop byte
	LD	A,(DE)		; Get other loop byte
	EX	DE,HL		; Swap pointers (not really needed...)
	LD	(HL),C		; Save other loop byte
	LD	(DE),A		; Save one loop byte
	INC	HL		; bump pointers
	INC	DE		;
	DJNZ	$SWAPL1		; iterate 5 times
	JR	$SORTIL		; Loop to next inner loop entry
;
;-----------------------------------------------------------------------------
;
;	End sort outer loop - File index
;
$FILIDX	CALL	OUTKEY@		; List last entry
	LD	C,00H		; Get print flag
_PFLG1	EQU	$-1		;
	INC	C		;
	DEC	C		;
	JR	Z,$FILIJ1	; Skip if no printing
	LD	C,0DH		; <CR>
	$SVC	@PRT		; send <CR> to printer
$FILIJ1	LD	DE,_FCBIN	; Input FCB
	$SVC	@CLOSE		; close input file
	JP	NZ,$CNCLOS	; Jump if error
	LD	BC,(_ENTCTR)	; # of index entries to BC
	LD	HL,_INDEX	; Index origin
;	Loop on index entries
$FILIL2	PUSH	BC		; Save index entries counter
	LD	B,(HL)		; Get keyword length (could be done directly to A)
	LD	A,B		; minus 3 (TODO: why?)
	SUB	03H		;
	LD	B,A		; to chars counter B
	INC	HL		; bump ptr
	LD	E,(HL)		; get keyword address to DE
	INC	HL		;
	LD	D,(HL)		;
$FILIL3	DEC	DE		; point to last keyword char
	DJNZ	$FILIL3		;
	LD	A,(DE)		; set high bit of last char
	OR	80H		;
	LD	(DE),A		;
	LD	B,02H		; 2 iterations
$FILIL4	DEC	DE		; point to word following (preceding) key
	INC	HL		;
	LD	A,(HL)		; copy help page position in file
	LD	(DE),A		;
	DJNZ	$FILIL4		; iterate twice
	POP	BC		; restore index entries counter
	DEC	BC		; one less remaining entry
	LD	A,B		; All entries done?
	OR	C		;
	INC	HL		;
	JR	NZ,$FILIL2	; Loop if not
	LD	DE,_FCBOUT	; DE = Output FCB
	$SVC	@LOF		; calculate EOF LRN
	PUSH	BC		; save index position in file to BC
	LD	BC,(_ENTCTR)	; # of index entries to BC
	LD	IX,_INDEX	; Index origin
	EXX			; Swap regs
	LD	DE,_FCBOUT	; Output FCB
	LD	HL,_RECOUT	; Output 1-byte record buffer
	EXX			; Swap regs
	LD	HL,_RECOUT	; Output 1-byte record buffer
;	Write index outer loop (entries)
$WIDXOL	PUSH	BC		; Save entries counter
	LD	B,(IX+0)	; Entry length
	LD	E,(IX+1)	; Entry keyword LSB
	LD	D,(IX+2)	; Entry keyword MSB
;	Write index inner loop (key chars)
$WIDXIL	LD	A,(DE)		; Get next entry data byte
	LD	(HL),A		; Move to record buffer
	EXX			; Swap regs
	$SVC	@WRITE		; write record to file
	JP	NZ,ERROR@	; If error, close all files and abort
	EXX			; Swap regs
	DEC	DE		; Next data byte (preceding in RAM)
	DJNZ	$WIDXIL		; loop until all data bytes written
	LD	DE,0005H	; Bump index entry pointer
	ADD	IX,DE		;
	POP	BC		; Restore entries counter
	DEC	BC		; Decrement it
	LD	A,B		; Done?
	OR	C		;
	JR	NZ,$WIDXOL	; Loop if not
	EXX			; Swap regs
	POP	BC		; Restore index position in file to BC
	LD	(HL),C		; write LSB
	$SVC	@WRITE		; write record to file
	JP	NZ,ERROR@	; If error, close all files and abort
	LD	(HL),B		; write MSB
	$SVC	@WRITE		; write record to file
	JP	NZ,ERROR@	; If error, close all files and abort
	$SVC	@CLOSE		; close file
	JP	NZ,ERROR@	; If error, close all files and abort
	LD	HL,CONCLD$	; Display "Processing concluded"
	$SVC	@DSPLY		; display message line
	LD	HL,0000H	; Exit status = SUCCESS
	$SVC	@EXIT		; return to LS-DOS
;
;-----------------------------------------------------------------------------
;
;	Read and store key (downwards from $HIGH)
;
RDKEY@	LD	E,(IX+1)	; Get index keyword address to DE
	LD	D,(IX+2)	;
	LD	C,02H		;
$RDKYL1	LD	A,(HL)		; Get char
	CP	0DH		; EOL ?
	JR	Z,$ENDKEY	; If yes, put end of key
	CP	61H		; is lower case letter ?
	JR	C,$RDKYJ2	;
	CP	7BH		;
	JR	NC,$RDKYJ2	;
	RES	5,A		; if yes, convert to upper case
$RDKYJ2	LD	(DE),A		; Store key char
	DEC	DE		; ... downwards !
	LD	A,01H		; check if too long
	ADD	A,C		;
	CP	42H		; maximum 65 chars...
	JP	NC,KWTLNG@	; Keyword exceeds maximum allowable length
	LD	C,A		; count char
	INC	HL		; inc input ptr
	JR	$RDKYL1		; loop for next char
;
;	End of key
;
$ENDKEY	LD	A,02H		; Check key length (including position 2 bytes)
	CP	C		;
	JP	Z,$NULKEY	; If empty, error: "Null Key Encountered"
	INC	HL		; Get char following the CR following the key
	LD	A,(HL)		;
	CP	0CH		; is it an end-of-page (FF)?
	JR	Z,$ENDKJ1	;   go if yes (next line is a key alias)
	RES	7,(IY+0)	; else reset KEY flag
$ENDKJ1	DEC	DE		; Leave 2 bytes in keys storage for file pos
	DEC	DE		;
	LD	(IX+0),C	; Store key length in index entry
	PUSH	HL		; Save buffer input ptr
	PUSH	DE		; Save key storage ptr
	LD	D,00H		;
	LD	E,C		;
	LD	HL,(_KEYCTR)	; Get Key chars counter (seems unneeded/unused)
	ADD	HL,DE		; add key length
	LD	(_KEYCTR),HL	; Save Key chars counter (seems unneeded/unused)
	LD	HL,(_FILPOS)	; Position in file
	LD	(IX+3),L	; put pos in file to index entry
	LD	(IX+4),H	;
	LD	DE,0005H	; Bump index ptr to next index entry
	ADD	IX,DE		;
	POP	DE		; restore key storage ptr (keywords bottom address)
	PUSH	IX		; IX to HL (index top address)
	POP	HL		;
	XOR	A		;
	SBC	HL,DE		; Compare index top address with keywords bottom address
	JP	NC,MEMOVL@	; If overlay, error: Memory overlay - abort
	LD	(IX+1),E	; put keyword address to index entry
	LD	(IX+2),D	;
	POP	HL		; Restore buffer input ptr
	LD	E,L		; to DE, buffer output ptr
	LD	D,H		;
	LD	BC,0000H	; Init bytes to move ctr to 0
	BIT	7,(IY+0)	; KEY flag still active (alias)?
	JR	Z,$ENDKL2	; Go if not
	INC	DE		; else bump buffer output ptr (skip end-of-page?)
	INC	HL		;  and bump buffer input ptr
;
;	Count chars in line buffer following keyword until EOT char
;
$ENDKL2	INC	C		; Count char
	LD	A,(DE)		; get char
	CP	03H		; is it End-of-text ?
	INC	DE		; Point to next char
	JR	NZ,$ENDKL2	; Jump if not
;
;	Delete the keyword from the line buffer
;
	LD	DE,_BUFFER	; 80-chars line buffer
	LDIR			; Delete keyword from line buffer
	LD	HL,_BUFFER	; Reset both pointers to buffer start
	PUSH	HL		;
	POP	DE		;
	LD	BC,0000H	; Reset chars counter
	JP	$EOLJ11		; Calc the remaining space in line buffer
;
;-----------------------------------------------------------------------------
;
;	End-of-line: put 0DH or 8DH if space follows
;
$EOL	INC	HL		; Point to next char
	LD	A,(HL)		; get next char
	CP	20H		; is a space ?
	DEC	HL		; Point back to current char
	JR	NZ,$EOLJ1	; jump if not
	INC	HL		; else check if following char
	INC	HL		;   is an end-of-text
	LD	A,(HL)		;
	CP	03H		;
	DEC	HL		;
	DEC	HL		;
	JR	Z,$EOLJ1	; jump if yes
	LD	(HL),8DH	; otherwise, replace the EOL (CR)
	LD	A,8DH		;   with EOL.OR.80H (high bit set)
$EOLJ1	LD	B,C		; Is there something to write?
	INC	C		;
	DEC	C		;
	JR	Z,$EOLJ3	; Jump if not
	LD	HL,_BUFFER	; 80-chars line buffer
;	Write compressed line to file
$EOLL2	LD	A,(HL)		; get char to write
	CALL	WRITE@		; Write a byte
	INC	HL		; point to next char
	DJNZ	$EOLL2		; and loop back
	BIT	3,(IY+0)	; is Flag 3 set?
	JR	Z,$EOLJ3	; if yes,
	RES	3,(IY+0)	;   clear it
	JR	$EOLJ6		;   and jump
;
$EOLJ3	LD	A,(HL)		; else get the next char
	CP	8DH		; is it a "EOL+space" ?
	JR	Z,$EOLJ4	; jump if yes
	CP	20H		; is it a white space ?
	JR	Z,$EOLJ5	; jump if yes (could jump to $EOLJ6...)
	LD	A,0DH		; else write EOL
$EOLJ4	CALL	WRITE@		; Write a byte
	INC	C		; count char
$EOLJ5	LD	A,(HL)		; get the next char again
	CP	20H		; is it a space?
	JR	NZ,$EOLJ7	; jump if yes
$EOLJ6	DEC	HL		; otherwise get preceding char
	LD	A,(HL)		;
$EOLJ7	LD	(_PREC1),A	; and store to 1st char preceding buffer
	INC	HL		; bump buffer input ptr (seems useless)
	PUSH	HL		; Save it
	LD	D,00H		; output length to DE
	LD	E,C		;
	LD	HL,(_FILPOS)	; Get Position in file
	ADD	HL,DE		; add the output length
	JP	C,TULONG@	; if too long, "Destination File Exceeds 65,535 characters"
	LD	(_FILPOS),HL	; Save new Position in file
	POP	HL		; restore buffer input ptr
	DEC	HL		; decrement it (seems useless, see above)
	LD	A,8DH		; check if char is a "EOL+space"
	CP	(HL)		;
	INC	HL		; bump ptr
	JR	NZ,$EOLJ8	; jump if not
	LD	A,20H		; else check if following char is a space
	CP	(HL)		;
	JR	NZ,$EOLJ8	; jump if not
	INC	HL		; else bump ptr
	CP	(HL)		; check if the char after is a space
	DEC	HL		; decr ptr
	JR	Z,$EOLJ8	; jump if yes
	INC	HL		; else absorb space
	INC	C		; and count the char
$EOLJ8	LD	A,51H		; A = Line buffer size + 1
	SUB	C		; A -= length
	LD	C,A		; move to BC: number of bytes to move
	LD	B,00H		;
	LD	DE,_BUFFER	; 80-chars line buffer
	BIT	4,(IY+0)	; is Flag 4 set ?
	JR	Z,$EOLJ10	; jump if not
	RES	4,(IY+0)	; reset the flag
	BIT	6,(IY+0)	; is COMP flag set
	JR	NZ,$EOLJ9	; jump if yes
	DEC	HL		; else decr source ptr
	INC	C		; and add one char to move
$EOLJ9	LD	A,(_SPCCTR)	; White spaces counter
	CP	00H		; are there any?
	JR	Z,$EOLJ10	; jump to LDIR if not
	RES	6,(IY+0)	; reset COMP flag
	LD	A,00H		; Clear white space counter
	LD	(_SPCCTR),A	;
;	Delete the written line from the line buffer,
;	move the next line chars to the beginning of buffer.
$EOLJ10	LDIR			; Move the bytes
;	Calc the remaining space in line
$EOLJ11	LD	BC,0000H	; Count the remaining chars
	LD	DE,_BUFFER	; 80-chars line buffer
;	Seek the EOT char in the line
$EOLL12	LD	A,(DE)		; Get next char
	CP	03H		; End-of-text?
	JR	Z,$EOLJ13	; Exit loop if yes
	INC	C		; increment counter
	INC	DE		; increment pointer
	JR	$EOLL12		; Loop until end-of-text
;	EOT found, calc the remaining space in line buffer
$EOLJ13	LD	HL,_ENDBUF	; Line buffer end
	XOR	A		;
	SBC	HL,DE		; Calc space left in line buffer
	LD	C,L		; to C (BC)
	INC	C		; Buffer full?
	DEC	C		;
	JR	NZ,$EOLX14	; Skip if not
	LD	C,01H		; else free one byte
	DEC	DE		;
$EOLX14	JP	$READLN		; Loop to read lines from file
;
;-----------------------------------------------------------------------------
;
;	End-of-page
;
$EOP	SET	7,(IY+0)	; Set KEY flag
	LD	BC,004FH	; Delete the end-of-page char
	LD	DE,_BUFFER	; 80-chars line buffer
	INC	HL		;
	LDIR			;
	LD	HL,_BUFFER	; 80-chars line buffer
	LD	A,0CH		; write an end-of-page char
	CALL	WRITE@		; Write a byte
	LD	DE,(_FILPOS)	; Get Position in file
	INC	DE		; Increment it
	LD	(_FILPOS),DE	; Save Position in file
	LD	A,(HL)		; Get next char
	CP	03H		; is it an end-of-text ?
	JP	Z,SORTFL@	; If yes, go to Sort and file keys
	LD	DE,004FH	; else bump ptr by 79 chars
	ADD	HL,DE		;
	EX	DE,HL		; to DE
	LD	C,01H		; one char
	JP	$READLN		; Loop to read lines from file
;
;-----------------------------------------------------------------------------
;
;	Error: Close all files and abort (A=err code)
;
ERROR@	PUSH	AF		; Save error code
	LD	DE,_FCBIN	; get input FCB
	$SVC	@CLOSE		; close input file
	LD	DE,_FCBOUT	; get output FCB
	$SVC	@CLOSE		; close output file
	LD	HL,ABORT$	; "System >> ABORTED << due to :"
	$SVC	@DSPLY		; display message line
	POP	AF		; recover error code
	OR	40H		; set flag to abort
	LD	C,A		; Error code to C
	$SVC	@ERROR		; post error message
;
;-----------------------------------------------------------------------------
;
;	Close out file, abort on error
;
CLOOUT@	PUSH	DE		; Save DE (needed?)
	PUSH	AF		; Save error code (weird?)
	LD	DE,_FCBOUT	; Get output FCB
	$SVC	@CLOSE		; close output file
	JR	Z,$CLOUJ1	; Exit on success
	LD	HL,ABORT$	; "System >> ABORTED << due to :"
	$SVC	@DSPLY		; display message line
	POP	AF		; recover error code
	OR	40H		; set flag to abort
	LD	C,A		; error code to C
	$SVC	@ERROR		; post error message
$CLOUJ1	POP	AF		; restore error code
	POP	DE		; restore DE
	RET			; done
;
;-----------------------------------------------------------------------------
;
;	Read a byte
;
READ@	EXX			; Swap regs
	$SVC	@CKEOF		; check for end-of-file
	JR	Z,$READJ1	; if yes:
	SET	5,(IY+0)	;   set EOF flag
	JR	$READX		;   and exit
;	No EOF
$READJ1	$SVC	@READ		; read record from file
	JP	NZ,ERROR@	; Close all files and abort (err code in A)
	LD	A,(HL)		; get char from rec buffer
$READX	EXX			; Swap regs back
	RET
;
;-----------------------------------------------------------------------------
;
;	Write a byte
;
WRITE@	EXX			; Swap regs
	PUSH	DE		; Save input FCB
	PUSH	HL		; Save input rec buffer
	LD	DE,_FCBOUT	; get Output FCB
	LD	HL,_RECOUT	; get Output record buffer (1 byte)
	LD	(HL),A		; put byte to rec buffer
	$SVC	@WRITE		; write record to file
	; Call to clear _PREC2 (call self-destroyed...)
$CPREC2	CALL	CPREC2@		; Clear _PREC2 (call self-destroyed...)
	POP	HL		; Recover input rec buffer
	POP	DE		; Recover input FCB
	JP	NZ,ERROR@	; If error, close all files and abort (A=err code)
	EXX			; Swap regs back
	RET			; Done
;
;-----------------------------------------------------------------------------
;
;	Clear _PREC2 (call self-destroyed...)
;
CPREC2@	LD	HL,_PREC2	; point to 2nd char preceding buffer
	LD	(HL),00H	; clear it
	LD	HL,$CPREC2	; call RESET@ and erase this call (Why?)
	LD	(HL),00H	; replace the call with NOPs
	INC	HL		;
	LD	(HL),00H	;
	INC	HL		;
	LD	(HL),00H	;
	RET			; Done
;
;-----------------------------------------------------------------------------
;
;	Compress spaces (spaces compression code)
;
$COMPSP	PUSH	HL		; Save buffer input ptr
	INC	DE		; Inc buffer output ptr
	LD	BC,0000H	; Init chars to move counter
	; Loop to count chars to move
$LCMPSP	LD	A,(HL)		; Get char
	CP	03H		; Is it end-of-text?
	JR	Z,$JCMPSP	; If yes, exit loop
	INC	C		; Count one more char to move
	INC	HL		; Point to next char
	JR	$LCMPSP		; Loop
	; Move bytes to compress spaces
$JCMPSP	POP	HL		; Restore buffer input ptr
	INC	C		; One more char
	LDIR			; Move char and delete spaces
	LD	HL,0000H	; Clear spaces counter
	LD	(_SPCCTR),HL	;
	RES	6,(IY+0)	; Reset COMP flag
	JP	$CONVLN		; Loop to convert lines
;
;-----------------------------------------------------------------------------
;
;	Sorry, cannot close file
;
$CNCLOS	LD	HL,CNCLOS$	; Sorry, cannot close file
	$SVC	@DSPLY		; display message line
	JP	ERROR@		; Close all files and abort (err code in A)
;
;-----------------------------------------------------------------------------
;
; 	Keyword exceeds maximum allowable length
;
KWTLNG@	LD	HL,KWTLNG$	; Keyword exceeds maximum allowable length
	$SVC	@DSPLY		; display message line
	LD	B,50H		; Line buffer length
	LD	HL,_BUFFER	; 80-chars line buffer
$KWTLL1	LD	A,(HL)		; Get keyword char
	CP	03H		; End-of-text?
	JR	Z,$KWTLX	; Exit loop if yes
	LD	C,A		; Char to C
	$SVC	@DSP		; display character
	INC	HL		; Point to next char
	DJNZ	$KWTLL1		; Loop until line is done
$KWTLX	JP	ABORT@		; Close and abort
;
;-----------------------------------------------------------------------------
;
;	Memory overlay - abort
;
MEMOVL@	LD	HL,MEMOVL$	; Memory Overlap has occured due to too many keys
	$SVC	@DSPLY		; display message line
;
;	Close and abort
;
ABORT@	EXX			; Switch to input FCB and buffer
	$SVC	@CLOSE		; close input file
	EXX			; Switch back
	LD	DE,_FCBOUT	; Output FCB
	$SVC	@CLOSE		; close output file
	LD	HL,0FFFFH	; Exit code = -1
	$SVC	@EXIT		; return to LS-DOS
;
;-----------------------------------------------------------------------------
;
;	Check and abort if source and dest files are the same
;
CKSAME@	LD	A,(_FCBIN+7)	; Get input Directory Entry Code
	LD	IX,_FCBOUT	; Select Output FCB
	CP	(IX+7)		; Compare with output Directory Entry Code
	JR	NZ,$CKSAMX	; Exit if different
	LD	A,(_FCBIN+6)	; Get input Logical Drive Number
	CP	(IX+6)		; Compare with output Logical Drive Number
	JR	NZ,$CKSAMX	; Exit if different
	LD	HL,SAMFIL$	; "SAME Source and Destination File - Operation terminated"
	$SVC	@DSPLY		; display message line
	JR	ABORT@		; Close and abort
;
$CKSAMX	LD	(IX+8),00H	; Truncate existing file
	LD	(IX+12),00H	;
	LD	(IX+13),00H	;
	RET			; Done
;
;-----------------------------------------------------------------------------
;
;	Display/Print an index key
;
OUTKEY@	PUSH	BC		; Save counter
	PUSH	HL		; Save pointer (needed?)
	LD	A,(IX+0)	; Get keyword length
	SUB	02H		; Minus the 2 position in file bytes
	CP	13H		; Less than 19 chars
	JR	C,$OUTKJ1	; Jump if yes
	PUSH	AF		; Else check cursor position
	LD	B,04H		;
	$SVC	@VDCTL		; control video display
	POP	AF		;
	ADD	A,L		; Add keyword length to horiz position
	CP	50H		; Less than 80 ?
	JR	C,$OUTKJ1	; If not,
	LD	C,0DH		;   go to next line
	$SVC	@DSP		; display character
;	Probably missing:
;	- go to next print line if printer is active
;	- reset the column counter
$OUTKJ1	LD	L,(IX+1)	; Point to 1st keyword char
	LD	H,(IX+2)	;
	LD	B,(IX+0)	; Get the keyword length
	DEC	B		; Minus the 2 position in file bytes
	DEC	B		;
$OUTKL2	LD	C,(HL)		; Get a char
	$SVC	@DSP		; display character
	LD	A,00H		; Printer flag
_PFLG3	EQU	$-1
	INC	A		; Is it set?
	DEC	A		;
	JR	Z,$OUTKJ3	; if yes, 
	$SVC	@PRT		;   send character to printer
$OUTKJ3	DEC	HL		; point downwards to next char
	DJNZ	$OUTKL2		; loop for remaining chars
	LD	A,(_COLUMN)	; Get Keyword column counter
	INC	A		; Increment it
	LD	(_COLUMN),A	; Put back Keyword column counter
	LD	A,16H		; A = max length + 3 = 20 chars + 2
$OUTKL4	CP	(IX+0)		; Compare with keyword length + 2
	JR	C,$OUTKJ5	;
	JR	NZ,$OUTKJ6	; Jump if less than 20 chars
$OUTKJ5	ADD	A,14H		; Increase max length by 20 chars
	PUSH	AF		; Save max length
	LD	A,(_COLUMN)	; get Keyword column counter
	INC	A		; Increment it
	LD	(_COLUMN),A	; Put back Keyword column counter
	POP	AF		; Restore max length
	JR	$OUTKL4		; Loop and check again
;	Display spaces to tabulate
$OUTKJ6	SUB	(IX+0)		; Calc the # of spaces to tabulate
	LD	B,A		; to B
	PUSH	AF		; Save it (for printer)
$OUTKL7	LD	C,20H		; ' '
	$SVC	@DSP		; display character
	DJNZ	$OUTKL7		; Loop until tab position reached
	LD	A,00H		; Get printer flag
_PFLG2	EQU	$-1		;
	INC	A		;
	DEC	A		; is it set?
	JR	NZ,$OUTKJ8	; Jump if yes
$OUTKX	POP	AF		; Otherwise restore all regs
	POP	HL		;
	POP	BC		;
	RET			; and exit
;	Print spaces to tabulate
$OUTKJ8	LD	A,(_COLUMN)	; Keyword column counter
	CP	04H		; Last column?
	JR	NC,$OUTKJA	; Jump if yes
	POP	AF		; Otherwise get # of spaces to print
	LD	B,A		; to B
$OUTKL9	LD	C,20H		; ' '
	$SVC	@PRT		; send character to printer
	DJNZ	$OUTKL9		; Loop until tab position reached
	PUSH	AF		; Save AF (could be avoided by skipping the POP AF)
	JR	$OUTKX		; and exit
;	Last column
$OUTKJA	LD	A,00H		; Reset column counter
	LD	(_COLUMN),A	; Keyword column counter
	LD	C,0DH		; Go to next print line
	$SVC	@PRT		; send character to printer
	JR	$OUTKX		; and exit
;
;-----------------------------------------------------------------------------
;
;	'P' (print) flag specified?
;
PFLAG@	LD	A,(HL)		; Get a char from command line
	CP	0DH		; End of line?
	RET	Z		; Return if yes
	RES	5,A		; change to upper case
	CP	50H		; is it a 'P' ?
	JR	Z,$PFLGL1	; Jump to prepare printer if yes
	INC	HL		; point to next command line char
	JR	PFLAG@		; Loop to test next char(s)
;
$PFLGL1	LD	HL,PREPPR$	; "Prepare printer"
	$SVC	@DSPLY		; display message line
	$SVC	@KEY		; wait for key press
	CP	01H		; <Break> ?
	JR	NZ,$PFLGJ2	; Jump if not
	LD	HL,0000H	; else set exit code = 0
	$SVC	@EXIT		;   and exit to LS-DOS
$PFLGJ2	LD	DE,5250H	; 'PR' printer device ID
	$SVC	@GTDCB		; get device control block
	EX	DE,HL		; Move DCB address to DE (or HL?)
	LD	C,00H		; Test printer ready
	$SVC	@CTL		; make control request
	JR	NZ,$PFLGL1	;   loop back if not ready
	LD	HL,KYWRDS$	; "Alphabetical listing of the keywords"
	$SVC	@PRINT		; print message line
	LD	HL,_NAMOUT	; Output file name
	$SVC	@PRINT		; print message line
	LD	HL,PRDATE$	; Listing date buffer
	PUSH	BC		; Save BC reg (unneeded...)
	$SVC	@DATE		; get system date
	LD	HL,PR_ON$	; " on "
	$SVC	@PRINT		; print message line
	LD	HL,PRDATE$	; Listing date buffer
	$SVC	@PRINT		; print date
	LD	C,0DH		; <CR>
	$SVC	@PRT		; send character to printer
	LD	B,4DH		; 77 '=' signs
$PFLGL3	LD	C,3DH		; '='
	$SVC	@PRT		; send character to printer
	DJNZ	$PFLGL3		; 77 times
	LD	B,02H		; 2 <CR>s
$PFLGL4	LD	C,0DH		; <CR>
	$SVC	@PRT		; send character to printer
	DJNZ	$PFLGL4		; 2 times
	LD	A,0FFH		; Set printer flags in code
	LD	(_PFLG3),A	;
	LD	(_PFLG2),A	;
	LD	(_PFLG1),A	;
	POP	BC		; Restore BC  (unneeded, see above)
	RET			; Done
;
;-----------------------------------------------------------------------------
;
;	Null Key Encountered: display prior key if any and abort
;
$NULKEY	LD	HL,NULKEY$	; Null Key Encountered - Prior Key was
	$SVC	@DSPLY		; display message line
	PUSH	IX		; Copy index entry ptr
	POP	HL		;   to HL
	LD	DE,0005H	; Point to previous index key
	XOR	A		;   5 bytes backwards
	SBC	HL,DE		; (nb: didn't need to use HL for that!) 
	PUSH	HL		; Move back to IX
	POP	IX		; 
	LD	DE,_INDEX	; Keywords index pointer (via IX+0..4), length = 5
	XOR	A		; Test if previous key exists
	SBC	HL,DE		;
	JR	C,NOPRKY@	; Jump to display "NO PRIOR KEY" if not
	LD	B,(IX+0)	; Get previous keyword length
	DEC	B		; Minus 2
	DEC	B		;
	LD	L,(IX+1)	; Point to keyword's 1st char
	LD	H,(IX+2)	;
$NULKL1	LD	C,(HL)		; Get a char
	$SVC	@DSP		; display character
	DEC	HL		; Point to next char (backwards)
	DJNZ	$NULKL1		; Loop for remaining chars
$ABORT1	JP	ABORT@		; Close and abort
;
;	NO PRIOR KEY
;
NOPRKY@	LD	HL,NOPRKY$	; NO PRIOR KEY
	$SVC	@DSPLY		; display message line
	JR	$ABORT1		; Close and abort
;
;-----------------------------------------------------------------------------
;
;	Destination File Exceeds 65,535 characters
;
TULONG@	LD	HL,TULONG$	; Destination File Exceeds 65,535 characters
	$SVC	@DSPLY		; display message line
	JP	ABORT@		; Close and abort
;
;-----------------------------------------------------------------------------
;
;	Show progress bar if length/50 > 0
;
SHWPCT@	LD	HL,(_FCBIN+12)	; Ending Record Number (# of sectors)
	LD	C,32H		; Divide by 50
	$SVC	@DIV16		; SVC: divide 16 by 8
	LD	A,L		; is quotient zero?
	OR	H		;
	RET	Z		; exit if yes
	LD	(_PRGINC),HL	; save to Progress increment
	LD	(_PRGRES),HL	; save to Progress counter
	LD	IY,PCTS$	; 0 25 50 75 100 %
$SPCTL1	LD	B,04H		; Get cursor pos to HL
	$SVC	@VDCTL		; control video display
	LD	BC,000EH	; Tab counter
	LD	A,(IY+0)	; Get next char in pct string
	CP	00H		; End of string?
	JR	Z,$SPCTX	; exit loop if yes
	CP	01H		; Tabulate?
	JR	NZ,$SPCTJ2	; Jump if not
	ADD	HL,BC		; Move to next tab
	LD	B,03H		; Set cursor position
	$SVC	@VDCTL		; control video display
	JR	$SPCTJ3		; Point to next char and loop
;	Display char
$SPCTJ2	LD	C,A		; C = Char to display
	$SVC	@DSP		; display character
$SPCTJ3	INC	IY		; Point to next char
	JR	$SPCTL1		; loop back
;	End of loop
$SPCTX	LD	C,0DH		; End of loop: display CR
	$SVC	@DSP		; display character in C
	LD	C,3EH		; display '>'
	$SVC	@DSP		; display character in C
	RET			; done
;
;-----------------------------------------------------------------------------
;
;	Update progress bar
;
PRGRES@	PUSH	HL		; save all regs
	PUSH	DE		;
	PUSH	BC		;
	PUSH	AF		;
	LD	HL,(_FCBIN+10)	; Get input Next Record Number (sector)
	LD	DE,(_PRGRES)	; Progress counter
	XOR	A		; (useless)
	LD	A,E		;
	OR	D		; is it zero?
	JR	Z,$PRGRSX	; exit if yes
	SBC	HL,DE		; Is the file pos < progress counter?
	JR	C,$PRGRSX	; exit if yes
	EX	DE,HL		; else move progress counter to DE
	LD	DE,(_PRGINC)	; get Progress increment
	ADD	HL,DE		; bump progress counter
	LD	(_PRGRES),HL	; put back Progress counter
	LD	B,04H		; Get current cursor pos
	$SVC	@VDCTL		; control video display
	DEC	L		; Decrement it
	LD	C,3DH		; replace the '>' with an '=' 
	LD	B,02H		; put char to screen at given pos
	$SVC	@VDCTL		; control video display
	LD	C,3EH		; char to display next '>'
	$SVC	@DSP		; display character
$PRGRSX	POP	AF		; restore all regs
	POP	BC		;
	POP	DE		;
	POP	HL		;
	RET			; Done
;
;-----------------------------------------------------------------------------
;
;	Strings area
;
; 	Progress bar "0 25 50 75 100 %"
PCTS$	DB	'0',01H
	DB	'25',01H
	DB	'50',01H
	DB	'75',01H
	DB	'100 %',00H
;	System >> ABORTED << due to :
ABORT$	DB	1CH,1FH
	DB	'System >> ABORTED << due to :',0DH
;	Help System Text Processor Version 6.0
TITLE$	DB	1CH,1FH
	DB	'Help System Text Processor Version 6.0  ',0AH
	DB	'Copyright (c) 1983 by Logical Systems, Inc.',0AH,0DH
;	Enter SOURCE file specification :
SOURCE?	DB	'Enter SOURCE file specification : ',03H
;	Destination File Exceeds 65,535 characters
TULONG$	DB	0AH
	DB	'Destination File Exceeds 65,535 characters',0AH
	DB	'Divide Source file and try again',0DH
;	Enter DESTINATION file name     : 
DESTIN?	DB	'Enter DESTINATION file name     : ',03H
;	Improper Source Filename
BADSRC$	DB	0AH
	DB	'Improper Source Filename',0AH,0DH
;	Press ANY key to continue
ANYKEY$	DB	0AH
	DB	'Press ANY key to continue',0DH
;	HLP default file extension
HLP$	DB	'HLP'
;	file already exists - destroy it?
FILXST?	DB	' file already exists.',0AH
	DB	'Is it permissible to destroy it? (Y/N)',0AH,03H
;	Sorry, cannot close file
CNCLOS$	DB	0AH
	DB	'Sorry, cannot close file',0AH,0DH
;
;-----------------------------------------------------------------------------
;
;	Duplicate Keys Encountered
;
DUPKEY@	LD	HL,DUPKEY$	; Duplicate Keys Encountered
	$SVC	@DSPLY		; display message line
	LD	A,(IX+0)	; Get keyword length (+2)
	LD	L,(IX+1)	; Get address of keyword's
	LD	H,(IX+2)	;   first char
	SUB	02H		; Length - 2
	LD	B,A		; to counter
$DUPKL1	LD	C,(HL)		; Get a char
	$SVC	@DSP		; display character
	DEC	HL		; point to next char (in rev order)
	DJNZ	$DUPKL1		; Loop for all chars of the keyword.
	JP	ABORT@		; Close and abort
;
;-----------------------------------------------------------------------------
;
;	Strings area (cont'd)
;
;	Duplicate Keys Encountered
DUPKEY$	DB	0AH
	DB	'Duplicate Keys Encountered',0AH
	DB	'Operation Terminated',0DH
;	Processing concluded
CONCLD$	DB	0AH
	DB	'Processing concluded',0DH
;	Keyword exceeds maximum allowable length
KWTLNG$	DB	0AH
	DB	'Keyword exceeds maximum allowable length',0AH,0DH
;	Memory Overlap has occured due to too many keys
MEMOVL$	DB	0AH
	DB	'Memory Overlap has occured due to too many keys',0AH
	DB	'Divide Source file and try again',0AH,0DH
;	Sorting and filing keys
SORTFL$	DB	0AH
	DB	'Sorting and filing keys',0DH
;	Null Key Encountered - Prior Key was 
NULKEY$	DB	0AH
	DB	'Null Key Encountered - Prior Key was ',03H
;	NO PRIOR KEY
NOPRKY$	DB	0AH
	DB	'NO PRIOR KEY',0DH
;-----------------------------------------------------------------------------
;
;	Variables
;
;	Progress increment
_PRGINC	DW	0000H
;	Progress counter
_PRGRES	DW	0000H
;	HIGH$ address
_HIGH$	DB	00H,00H
;	Keyword column counter
_COLUMN	DB	00H
;	2nd char preceding buffer
_PREC2	DB	80H
;	1st char preceding buffer
_PREC1	DB	85H
;	80-chars line buffer
_BUFFER	DS	0050H
;	Buffer end (EOT marker)
_ENDBUF	DB	03H
;	Output file name buffer
_NAMOUT	DS	0019H
;	Position in file
_FILPOS	DW	0000H
;	"Done" entries counter
_DONENT	DW	0000H
;	Key chars counter (seems unneeded)
_KEYCTR	DW	0000H
;	Index entries counter
_ENTCTR	DW	0000H
;	White spaces counter
_SPCCTR	DW	0000H
;-----------------------------------------------------------------------------
;
;	FCBs and file/record buffers
;	Byte 6		Logical Drive Number
;	Byte 7		Directory Entry Code
;	Bytes 10-11	Next Record Number (sector)
;	Bytes 12-13	Ending Record Number (sector)
;	
;	Input FCB
_FCBIN	DS	0020H		; Input FCB start
;	Output FCB
_FCBOUT	DS	0020H
;	Input file buffer
_BUFIN	DS	0100H
;	Output file buffer
_BUFOUT	DS	0100H
;	Input record buffer (1 byte)
_RECIN	DB	00H
;	Output record buffer (1 byte)
_RECOUT	DB	00H
;
;	_PFLAGS = Bit-mapped processing flags (via IY+0)
;
;	Bit 7	Reading keyword
;	Bit 6	Space compression
;	Bit 5	Got End-Of-File
;	Bit 4	?? (TBD)
;	Bit 3	?? (TBD)
;	Bit 2-0	Unused (could use one of those bits as a print flag...)
;
_PFLAGS	DB	00H
;-----------------------------------------------------------------------------
;
;	_INDEX = Index table start
;
;	This area overlaps the strings area used before the processing starts.
;
;	Keywords index table origin (via IX+0..4), length = 5
;
;	0	Keyword length+2 (keyword + text position in file)
;	1-2	points to keyword's 1st character. The keywords are stored 
;		in memory in reverse order. Each keyword is followed by
;		2 bytes that will store the position of the text page in the 
;		file (from IX+3, IX+4).
;	3-4	Position of the text page in the .HLP file.
;
_INDEX	DB	00H
;-----------------------------------------------------------------------------
;
;	Strings area used during initialization phase,
;	overwritten by the index table.
;
;	SAME Source and Destination File - Operation terminated
SAMFIL$	DB	'SAME Source and Destination File',0AH
	DB	'Operation terminated',0DH
;	Processing Source File
PROCSF$	DB	0AH
	DB	'Processing Source File',0DH
;	Prepare printer
PREPPR$	DB	0AH
	DB	'Prepare printer. Press ANY key when ready or BREAK to abort',0DH
;	Alphabetical listing of the keywords
KYWRDS$	DB	'Alphabetical listing of the keywords for the file : ',03H
;	Listing date
PRDATE$	DS	0008H
	DB	03H
;	' on '
PR_ON$	DB	' on ',03H
;
;
	END	HELPGEN
