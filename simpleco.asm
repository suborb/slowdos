;
;       Slowdos Source Code
;
;
;       $Id: simpleco.asm,v 1.1 2003/06/14 23:08:19 dom Exp $
;       $Author: dom $
;       $Date: 2003/06/14 23:08:19 $
;
;	Some supposedly simple commands




; Move command
;
; Supported syntax:
;
; MOVE Pdd"f" TO #ss  - copy file f to stream ss
; MOVE TO Pdd"f"      - change directory to f
; MOVE TO Tdd"f" [IN] - enter a .TAP file (reading)
; MOVE TO Tdd"f" OUT  - create a .TAP file writing
; MOVE TO Tdd	      - exit the current .TAP file

          
move:     call  rout32  
          cp    204  		;TO - i.e. .TAP/Directory reading
          jp    z,tread
          call  getdrv1		; Moving to subdirectory, get the drive
          call  cksemi  	; We want a semi-colon
          call  exptex  	; Now we expect a string
          cp    204 		; TO - copying to streams
          jp    nz,nonerr  	; No TO, Nonsense in BASIC
          call  rout32  	; Get next character
          cp    '#'  		; Must be a #, otherwise its nonsense
          jp    nz,nonerr  
          call  e32_1n  	; Now we expect a number
          call  ckend  		; And the end of the statement

; Execution of the routine proper
	  call	getnum		; Get the stream number
          ld    a,b  		; Odd stuff with streams > 255?
          and   a  
          jr    nz,move1  
          set   7,c  
move1:    ld    a,c  		; Select the channel
          ld    (chanel),a  
          ld    a,1
          call  settap		; Some weird flag nonse
          call  clufia    	; Clear the filename within ufia, hl = ufia+2
          call  getstr  	; Get the string and place it within ufia
          ld    ix,ufia		; Open the file
          call  rdopen  
          ld    a,(chanel)  	; Open the channel
          call  setchan
          ld    bc,(temphd+1)  	; Pick up the file length
move2:    call  rdbyte  	; Read a byte from the file
          cp    13  
          jr    z,move8  	; If LF then display it
          cp    32  		; Otherwise if < 32 replace with ' '
          jr    nc,move8  	
          ld    a,32  
move8:    call  print		; Print the character out
move3:    dec   bc  		; And loop around
          ld    a,b  
          or    c  
          jr    nz,move2  
          ret   		; All done

;Select a TAP file/directory...

tread:    call  rout32		; Find out if it's a P or a T
          and   223
          cp    'P'		; It's a subdirectory
          jp    z,movsdi
          cp    'T'
          jp     nz,nonerr  	; Not a .TAP, so Nonsense in BASIC

; .TAP file handling
          call getdrv2		; Skip over the drive specifier
          call ckenqu		; Check for statement end
          jr   nz,tread1	; Not end, we must be entering .TAP file
          call ckend		; Check for end/syntax

; Close the currently open .TAP file
tapend:   ld   hl,flags2	; Reset .TAP indicator
          res  6,(hl)
          inc  hl		; Skips to flags3
          bit  1,(hl)		; Were we writing to .TAP file
          ret  z		; No we weren't
          res  1,(hl)		; Reset writing indicator
          call mslog     	; Check the disc
          jp   wrclos		; And write out the file

; Entering a .TAP file
tread1:   call cksemi		; We want a semicolon
          call exptex		; And then some text
          call rout24		; No we need to check for IN/OUT
          cp   223  		; OUT
          jr   nz,tread11
;Okay, trying to save into .TAP
          call rout32
          call syntax		; If we're in syntax mode then don't set flags
          jr   z,tread11
          ld   hl,flags3	; Set writing .TAP if not in syntax mode
          set  1,(hl)
tread11:  cp   191  		; IN
          jr   nz,tread19
          ld   hl,flags3	; If we're already writing then we can't have IN
          bit  1,(hl)
          jp   nz,nonerr	; So Nonsense in BASIC
          call rout32
tread19:  call ckend		; IT really is the end

; We have some shared parameter reading
          ld   hl,flags2	; Reset in .TAP file flag
          res  6,(hl)
          call clufia		; Clear ufia+2, exit hl = ufia+2
          call getstr		; Get the string
          jp   nz,bfnerr 	; Returned a wild card, can't have that!

tread2:   ld   de,ufia+11	; Check for .TAP suffix
          ld   hl,tapiden
          call ckext
          jp   nz,bfiltyp	; Not there, so bad filetype

; Now try to open the .TAP file on disc
          ld   ix,ufia
          ld   hl,flags3	; Check for writing
          bit  1,(hl)
          jr   nz,tread3	; We're writing, don't want to read it
          call rdopen
          ld   hl,ufia+2	; Save the .TAP filename
          ld   de,tapnam 
          ld   bc,8
          ldir
          ld   hl,flags2	; Indicate that we're in a .TAP file
          set  6,(hl)
          ret

; We want to write to a .TAP file
tread3:   res  1,(hl)		; hl = flags3
          push hl
          dec  hl
          dec  hl		; hl = flags
          set  5,(hl)    	; Indicate we want headerless file
          call wropen		; open the file
          pop  hl
          set  1,(hl)		; Indicate that we're writing to a .TAP file
          ret

tapnam:   ds   8,0		;VARIABLE
tapiden:  db   'TAP'

;Move into a subdirectory..

movsdi:   call getdrv2		; Pick up the drive
          call ckenqu		; Check for end
          jr   nz,movsdi1	; Not end, must be subdir attached
          call ckend		; End of statement
; No name provided, move back to the root directory
movsdi0:  ld   hl,0		; Set subdirectory cluster number to 0
          ld   (sdclus),hl
          ld   hl,flags3
          res  3,(hl)		; Reset in subdir flag
          dec  hl        	; hl=flags2
          res  6,(hl)    	; Reset in .TAP file flag
          ret
; Moving into a subdirectory
movsdi1:  call cksemi		; We want a semicolon/separator
          call exptex		; Now we want a string
          call ckend		; End of statement please

          call clfilen		; Clear the filename, hl = filen
          call rom3		; Get address of string
          dw   11249		; Leaves de = address, bc = length
movsdie:  ld   a,c		; Length is 0, go back to the root dir
          or   b
          jr   z,movsdi0 
          ex   de,hl		; hl =address
movsdi3:  exx			; hl'=address, bc'=length
          ld   de,filen		; Get 8 characters into filen
          ld   b,8
movsdi2:  push de
          push bc
          exx
          call movgch		; Returns z = end or dir separator
          exx
          pop  bc
          pop  de
          ld   (de),a
          jr   z,movsdi4 ;it's our bit
          inc  de
          djnz movsdi2
movsdi4:  cp   '/'		; Last character was a '/'
          jr   nz,movsdi9	; So replace it with a ' '
          ld   a,32
          ld   (de),a
movsdi9:  ld   a,b  		; If its longer than 8 characters then its wrong
          sub  8
          ret  z   
          ld   hl,filen  	; filen is where dirname is kept
          ld   b,8
          call ckwild		; Check to see if its wild
          ld   hl,flags
          bit  1,(hl)
          jp   nz,bfnerr	; We don't like wildcard directories
          exx
          push hl		; Save the address and length of string 
          push bc
          exx
          call discan		; Scan the disc for the filename hl=dir entry
          jp   nc,filnot 	; File doesn't exist
movsdi5:  ld   bc,11		; Skip to the file type
          add  hl,bc
          bit  4,(hl)		; Check for subdir flag
          jp   z,bfiltyp     	; Not set, so bad filename
          ld   c,15
          add  hl,bc		; Skip to cluster start
          ld   e,(hl)		; Pick up cluster
          inc  hl
          ld   d,(hl)
          ld   hl,flags3	; If this is a subdir i.e. cluster != 0 then
          res  3,(hl)		; we set subdir flag
          ld   a,d
          or   e
          jr   z,movsdi6
          set  3,(hl)
movsdi6:  ld   (sdclus),de	; Save subdirectory cluster
          exx			; And loop back for the next bit of the path
          pop  bc
          pop  hl
          ld   a,b
          or   c
          ret  z
          jr   movsdi3



;Get a character....
;Entry:   hl= addy of string
;	  bc = number of characters needed
;Exit:    hl = hl + 1
;         bc = bc - 1
;	   a = character picked up
;          z = end of current thing

movgch:   call gfropg	; Get character from BASIC
          inc  hl	; Increment address
          dec  bc	; Decrement counter
          ld   e,a
          cp   '/'	; Check for directory separater
          ret  z
          ld   a,b	; Test bc = 0
          or   c
          ld   a,e	; Restore the character
          ret




;READ # command -set +3 USER area
          
          
;uread:    call  rout32  
;          cp    '#'  
;          jp   nz,nonerr
;Change +3 user area
;uread0:   call  e32_1n  
;          call  ckend  
;          call  rom3  
;          dw    fnint2  
;          ld    a,b  
;          and   a  
;          jr    z,uread2  
;uread1:   call  errorn  
;          db    45 ;bad parameters  
;uread2:   ld    a,c  
;          cp    16  
;          jr    nc,uread1  
;          ld    iy,304  
;          jp    dodos  

          
;
; Poke@ command. Supported syntax:
;
; POKE @a1,d1
;
; If d1 < 256 then 8 bit poke, otherwise 16 bit poke
;
 
          
poke:     call  rout32  
          cp    '@'  		; Check for '@'
          jp    nz,nonerr  	; No? Call Nonsense in BASIC
          call  e32_1n  	; We expect one number
          cp    ','  		; Then a comma
          jp    nz,nonerr  	; No comma, Nonsense in BASIC
          call  e32_1n  	; We now want another number
          call  ckend  		; And end of statement
          call  getnum		; Get the value from the stack
          push  bc  		; Store it
          call  getnum		; Get the address
          ld    h,b  		; Get it into hl
          ld    l,c  
          pop   bc  		; Now get the value back
          ld    (hl),c  	; And poke it
          inc   hl  		; Increment the address
          ld    a,b  		; Check if the high byte of the value != 0
          and   a  
          ret   z		; It is zero then return
          ld    (hl),b  	; Else poke it
	  ret			; Command finished

;Fun cls routine
          
;cls:      call  rout32  
;          cp    '#'  
;          jp    nz,nonerr  
;          call  rout32  
;          call  ckend  
;          ld    hl,56  
;          ld    (23693),hl  
;          ld    (23695),hl  
;          ld    (iy+14),l  
;         ld    (iy+87),h  
;          ld    a,2  
;          call  rom3  
;          dw    5633  
;          call  rom3  
;          dw    3435  
;          ld    a,7  
;          out   (254),a  
;          ret             
