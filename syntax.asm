;
;       Slowdos Source Code
;
;
;       $Id: syntax.asm,v 1.1 2003/06/15 20:26:27 dom Exp $
;       $Author: dom $
;       $Date: 2003/06/15 20:26:27 $
;
;       Routines concerned with syntax and interfacing with ROM3



		MODULE		syntax
		INCLUDE		"slowdos.def"

		XREF		rom3		; We need this!
		XREF		errorn
		XREF		synexe

		XDEF		cksemi
		XDEF		getdrv
		XDEF		getdrv1
		XDEF		getdrv2
		XDEF		gdrive
		XDEF		chadd

		XDEF		error_nonsense
		XDEF		error_filename

		XDEF		ckend
		XDEF		ckenqu
		XDEF		syntax
		
		XDEF		getnum
		XDEF		usezer
	
		XDEF		rout24
		XDEF		rout32

		XDEF		readbyte
	
		XDEF		e32_1n
		XDEF		expt1n
		XDEF		exptex
		

; Check to ensure that we have ";" or a "," before a filename variable
; Entry:	a = current character
; Exit:		if we exit then it's okay           
cksemi:   cp    ','  
          jp    z,rout32  
          cp    ';'  
          jp    z,rout32  
          cp    '"'
          ret   z
          jp    error_nonsense


; Various entry points dependent on whether we already have the
; character in a or not
getdrv:   call rout32		; Get the next characte
getdrv1:  and  223		; Enforce upper case
          cp   'P'		; If no 'P' then nonsense in BASIC
          jr   nz,error_nonsense
getdrv2:  call rout32		; Now get the drive letter

; Check the drive specifier
; Entry:	a = current character
; Exit:		a = next character
gdrive:   cp    '*'  		; If a * then skip over getting drive number
          jr    z,chadd  
          call  expt1n  	; We expect one number
          call  rout24  	; Skip to next valid character
          call  syntax  	; If in syntax mode, return now
          ret   z  
          push  af  		; Save current character
          call  getnum		; Get the number off stack int bc
          ld    a,b  		; Has to be < 256
          and   a  
          jr    nz,error_baddrive  
          ld    a,c  		; Has to be < 3
          cp    3  
          jr    nc,error_baddrive  
          and   a  		; Can't be 0
          jr    z,error_baddrive  
          ld    (curdrv),a  	; Save the current drive
          pop   af  
          ret
	   
chadd:    call  rom3  		; Skip to next printable character
          defw  $74 ;chadd  
          ret   
          
; Various errors
error_baddrive:   
	  call  errorn  
          defb  36 ;invalid device  
error_nonsense:   
	  call  errorn  
          defb  11  
error_filename: 
          call  errorn  
          defb  33  

;Check for end of line & also for running in syntax mode
ckend:    call  rout24  
          call  ckenqu  
          jr    nz,error_nonsense	;Not end of statement, call nonsense in basic
	  ld    (iy+0),255  	;No error
          set   7,(iy+1)  
          call  syntax  	;Checks if we're doing syntax
          ret   nz  		;We're not, so execute the command
          res   7,(iy+1)  
          pop   bc  
          jp    synexe  	;Carry on syntax checking
          
; Checks for end of statement
; Entry:	a = character to check
; Exit:		z = end of statement/ nz = not end of statement
ckenqu:   cp    13  
          ret   z  
          cp    58  
          ret   
          
; Check if we're in syntax mode
; Entry:	none
; Exit:		z / nz dependent on mode
syntax:   bit   7,(iy+48)  
          ret   
          
; Stack a 0 on the number stack if not in syntax mode
; Entry:	none
; Exit:		none
usezer:   call  syntax  
          ret   z  
          ld    bc,0  
          call  rom3  
          defw  11563  
          ret   
          
; Get number from calculator stack into bc
; Entry:	none
; Exit:		bc = 16 bit number
getnum:   call  rom3
          defw  fnint2
          ret

; Pick up next character
; Entry:	none
; Exit:		a = next char 
rout32:   call  rom3  
          defw  32  
          ret   

; Pick up current character/next if nor printable
; Entry:	none
; Exit:		a = next char 
rout24:   call  rom3
          defw  24
          ret

; Pick up a byte from the normal BASIC memory area
; Entry:	hl = address
; Exit:		hl = address
;		 a = value at that address
readbyte: call	rom3
	  defw	123
	  ret

; We expect to get a number next in the input stream
; Entry:	none
; Exit:		none
e32_1n:   call  rout32  	; Get next char if needed
expt1n:   call  rom3  		; Parse expression
          defw  9467  
          bit   6,(iy+1)  	; Check for numeric result
          ret   nz  		; It was
          pop   bc  
          call  errorn  
          defb  11  
          
; We expect a string to be next
; Entry:	none
; Exit:		none
exptex:   call  rom3  		; Parse expression
          defw  9467  
          bit   6,(iy+1)  	; Check for string result
          ret   z  		; It was
          pop   bc  
          call  errorn  
          defb   11  

          



