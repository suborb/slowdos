;
;	Slowdos Source Code
;
;
;	$Id: msformat.asm,v 1.2 2003/06/15 20:26:26 dom Exp $
;	$Author: dom $
;	$Date: 2003/06/15 20:26:26 $
;
;	Provides routines for formatting discs
;
;	Discdos: 13/2/1996 Imported into Slowdos 1/12/1997

	
		MODULE	format

		INCLUDE	"slowdos.def"
		INCLUDE	"syntax.def"

	;; Other things
		XREF	settapn
		XREF	clfilen

		XREF	setchan
		XREF	messag

		XREF	dodos
		XREF	swos

		XREF	xdpb


		XDEF	format
		XDEF	seccle

	
	
; Format command. Supported syntax:
;
; FORMAT Pdd[!][;"discname"]

format:   call  getdrv           ;loads (curdrv) with the current unit
          ld    hl,flags		; 
          res   5,(hl)		;Reset "initialise disc only" flag
          res   2,(hl)		;Reset "write discname" flag
          call  ckenqu		;Returns z if end of statement
          jr    z,forma2
          cp    '!'		;Check to see if we just want to initialise
          jr    nz,forma1
          ld    hl,flags		;Set "initialise disc only" flag
          set   5,(hl)
          call  rout32
forma1:   call  ckenqu		;Check to see if we have the end of statment
          jr    z,forma2
          cp    ';'		;Not end of statement, check for semicolon
          jp    nz,error_nonsense
          call  rout32
          call  exptex		;We expect a string
          call  ckend		;We must have end of statement
          call  settapn		;??
          call  clfilen		;Clear the filename, exits with hl=filen
          call  getstr		;Get 12 byte string into filen area
          ld    hl,flags	;Indicate that we have a discname
          set   2,(hl)
          jr    forma3
forma2:   call  ckend  		;If no discname, check for end of statement
forma3:   ld    a,0FDh  	;Lower screen
          call  setchan
          call  messag  
          defb  22,1,0  
          defm  "ARE YOU SURE (Y/N)"
          defb  '?'  
          defb  255  
          call  confim 		;Returns z if [yY] is pressed
          ret   nz  		;User not sure, so exit

; Start the disc format
          ld    hl,flags	;Check to see if we only wanted to initialise
          bit   5,(hl)
          jr    nz,diinit
          call  seccle		;Clear the write sector
          ld    b,160  		;Number of sectors
          ld    d,0  		;Track number
form1:    push  bc  
          push  de  
          ld    ix,xdpb  
          call  setup  
          pop   de  
          push  de  
          ld    e,229  
          ld    b,7  
          ld    c,1  
          ld    hl,wrisec  
          ld    iy,364  
          call  dodos  
          pop   de  
          inc   d  
          pop   bc  
          djnz  form1  

; Initialise the disc - write the boot sector etc
diinit:   call  seccle  	;Clear the write sector
          ld    b,7  		;Blank out the first 7 sectors of the disc
          ld    de,0  
diini1:   push  bc  
          push  de  
          call  swos  
          pop   de  
          inc   de  
          pop   bc  
          djnz  diini1  
          ld    hl,dispec  	;Copy the standard disc specification
          ld    de,wrisec  
          ld    bc,30  
          ldir  
          ld    de,0  
          call  swos  		;Write it out to disc
          call  seccle  	;Clear the write sector
          ld    de,0F9FFh  	;Standard start for FAT table
          ld    hl,wrisec  
          ld    (hl),d  
          inc   hl  
          ld    (hl),e  
          inc   hl  
          ld    (hl),e  
          dec   hl  
          dec   hl  
          ld    de,1  		;Write to FAT table 1
          call  swos  
          ld    hl,sector  
          ld    de,4  		;Write to FAT table 2
          call  swos  
          ld    hl,flags	;Check to see if there's a discname
          bit   2,(hl)
          ret   z		;No there isn't, so exit
;Okay, have to title the disc now..
          call  seccle		;Clear the sector
          ld    hl,filen	;Copy filen to the write sector
          ld    de,wrisec
          ld    bc,8
          ld    a,c
          ldir
          inc   hl		;Skip over the '.'
          ld    bc,3
          ldir
          ld    (de),a		;File attribute?
          ld    de,7		;Write to sector 7 - start of root directory
          call  swos
          ret

;
; Clears the write sector memory space
;
seccle:   ld   hl,wrisec
          ld   de,wrisec+1
          ld   bc,511
          ld   (hl),0
          ldir
          ret

;
; Some clever formatting setup code
;
setup:    push  bc  
          push  de  
          ld    b,(ix+19)  
          ld    c,0  
          ld    hl,wrisec  
setup1:   push  bc  
          push  de  
          ld    a,(ix+17)  
          ld    b,0  
          and   127  
          jr    z,setup3  
          dec   a  
          jr    nz,setup2  
          ld    a,d  
          rra   
          ld    d,a  
          ld    a,b  
          rla   
          ld    b,a  
          jr    setup3  
setup2:   ld    a,d  
          sub   (ix+18)  
          jr    c,setup3  
          sub   (ix+18)  
          cpl   
          ld    d,a  
          inc   b  
setup3:   ld    (hl),d  
          inc   hl  
          ld    (hl),b  
          inc   hl  
          pop   de  
          pop   bc  
          push  bc  
          xor   a  
          bit   0,c  
          jr    z,setup4  
          ld    a,(ix+19)  
          inc   a  
          srl   a  
setup4:	  add	A,(ix+20)  
          srl   c  
	  add	A,c  
          ld    (hl),a  
          pop   bc  
          inc   c  
          inc   hl  
          ld    a,(ix+15)  
          ld    (hl),a  
          inc   hl  
          djnz  setup1  
          pop   de  
          pop   bc  
          ret


; Wait for a keypress
; Exit:		z = [Yy] was pressed, nz = otherwise

confim:   set   5,(iy+2)
          call  rom3
          defw  15D4h ;Wait key
          and 223
          cp 'Y'
          ret
	          
;MSDOS standard specification
          
dispec:   defb    0Ebh,034h,090h  
          defm    "SPDOS3.3"
          defw    512  ;Sector size  
          defb    2    ;Cluster size  
          defw    1    ;Reserved sec  
          defb    2    ;No FAT tabs  
          defw    70h  ;Dir slots  
          defw    5A0h ;Secs/Disc  
          defb    0F9h ;Media descrip  
          defw    3    ;Secs/FAT  
          defw    9    ;Secs/Track  
          defw    2    ;Tracks/cycle  
          defw    0    ;Hidden secs  
