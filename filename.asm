;
;	Slowdos Source Code
;
;
;	$Id: filename.asm,v 1.3 2003/06/17 17:39:10 dom Exp $
;	$Author: dom $
;	$Date: 2003/06/17 17:39:10 $
;
;	Manipulation of filenames


		MODULE	filename
		INCLUDE	"slowdos.def"


		XREF	error_filename

		XREF	errorn
		XREF	synexe

		XDEF	getstr
		XDEF	getst0
		XDEF	plafil
		XDEF	plafi0
		XDEF	ckchar
		XDEF	ckwild
		XDEF	ckwild_length

		XDEF	parse_p3name
		XDEF	filename_start
		XDEF	nsort

		XDEF	clufia
		XDEF	clfilen
		XDEF	clfiln
		XDEF	clfil0

		XDEF	uftofin

		XREF	rom3
		XREF	wrinit
		XREF	wrcopy




;Get a string from the BASIC area
;used for filenames....
;Entry: hl=address to dump string...
;This has been sorted to handle null names
;if handling .TAP files..
;Further sorted out to not sort out filenames...

;
; Get a string from the BASIC memory area, used for filenames.
;
; Entry:	hl = address to dump string
; Entry(getst0) bc = how long the name should be
;
; NB. This function really is black magic!
                  
getstr:   ld    bc,12  		;8 + 3 + '.'
getst0:   push  hl  
          push  bc  
          ld    hl,gtfisp	;Just a temporary workspace
          ld    b,c
          call  clfil0		;Initialises b bytes at hl with ' '
          call  rom3  
          defw  11249  		; de=address, bc=length
          call  wrinit  	;
          pop   hl  		;Get length back
          and   a  
          sbc   hl,bc  		;Check to see if its too long
          jp    c,error_filename
;Some temporary workspace
          ld    hl,gtfisp
          ld    b,c  
          ld    a,b  
          and   a  
          jr    nz,gets15  
;We have a null length filename...
          ld   hl,flags2
          bit  6,(hl)    ;not dealing with TAP at first glance
          jr   z,getsl4
          ld   a,(flags3) ;check whether this is real or not...
          bit  0,a
          jr   z,getsl4 ;it's not..we're reading from, but this ain't
;Okay, handling TAP file, so set filename up to be *
          set  1,(hl)    ;wild name
          pop  hl	 ;get dest address back
          ld   a,'*'
          ld   (hl),a
          and  a ;set nz, (nc=not significent)
          ret
getsl4:   call  errorn  
          defb   43  ;bad filename - ie none!!
gets15:
          push  hl  ;save gtfisp
getst1:   push  hl  
          call  wrcopy  
          pop   hl  
          ld    (hl),a  
          inc   hl  
          inc   de  
          djnz  getst1  
          pop  hl ; hl=gtfisp
          pop  de  ;de=destination filename storage
          ld   a,(flags2)
          bit  6,a
          jr   nz,getstt
          bit  7,a
          call nz,getst9
          push de
          call plafil
getst8:   pop  hl
          push hl
          call  ckwild
          ld   hl,flags
getst4:   bit  1,(hl)  
          pop  hl  
          ret   
;This bit to handle .TAP names
getstt:   push de
          ld   bc,10
          ldir
          jr   getst8

;Get string sort out for +3 filenames
;hl=basic filename
;de=dest address
getst9:   push de
          push hl
          ex   de,hl
          ld   b,16
          call parse_p3name1
          ld   hl,flags2
          res  7,(hl)
          ld   hl,(filename_start)
          pop  de
          and  a
          sbc  hl,de
          ld   b,h
          ld   c,l
          pop  hl
          ex   de,hl
          ld   a,b
          or   c
          ret  z
          ldir
          ret


;Plafil: designed to pad the filename fully
;out
;Entry:    hl=filename as from BASIC
;          de=addr of where to place filename

plafil:   push de
          ex   de,hl
          ld   b,12
          call clfil0
          ex   de,hl	;hl = source
          pop  de
plafi0:   push de	;save dest
          ld   b,8
          call plafi1
          ex   de,hl	;de = source
          pop  hl	;dest
          ld   bc,8
          add  hl,bc
          ld   (hl),'.'
          inc  hl
          ex   de,hl
          ld   b,3
;The actual routine itself
plafi1:   ld   a,(hl)
          inc  hl
          cp   '.'
          ret  z
          ld   (de),a
          inc  de
          djnz plafi1
          ret


;Check the filename and convert to upper
;case
;Entry:   hl=address of filename
;Exit:     c=filename bad
;         nc=filename good

ckchar:   ex   de,hl
          ld   b,8
          call ckcha1
          ret  c
          inc  de
          ld   b,3
          call ckcha1
          ret

ckcha1:   ld   a,(de)
          cp   97
          jr   c,ckcha2
          cp   123
          jr   nc,ckcha2
	  add	A,224
ckcha2:   ld   (de),a
          inc  de
          cp   127
          ccf
          ret  c
          cp   32
          ret  c
          ld   hl,badcha
ckcha3:   cp   (hl)
          scf
          ret  z
          inc  hl
          bit  7,(hl)
          jr   z,ckcha3
          djnz ckcha1
          and  a    
          ret



badcha:   defm   "!&()+,-./:;<=>[\]|" & 128
          

; Check to see if a filename is wild
; Sets bit 1,(flags) if it is wild in anyway
; Entry:	hl = addy of filename
;                b = length to check (ckwild_length) 
; Exit:		none 

ckwild:   ld    b,12
ckwild_length:	
	  push  hl
          ld    hl,flags  
          res   1,(hl)  
          pop   hl  
ckwild1:  ld    a,(hl)  
          cp    '*'  
          jr    z,ckwild2 
          cp    '?'  
          jr    z,ckwild2
          inc   hl  
          djnz  ckwild1  
          ret   
ckwild2:  push  hl  
          ld    hl,flags  
          set   1,(hl)  
          pop   hl
	  ret
	  
          

gtfisp:		defs	16,32	; VARIABLE

;Clear the filename
;Entry:    hl=filename

clufia:   ld   hl,ufia+2
          jr   clfiln
clfilen:  ld   hl,filen
clfiln:   ld   b,12
clfil0:   push hl
clfil1:   ld   (hl),32
          inc  hl
          djnz clfil1
          pop  hl
          ret


;Copy the filename in the UFIA to filen
;Entry:   ix=ufia
;Exit:    ix=ufia
;         hl=ufia+2

uftofin:  push ix
          pop  hl
          inc  hl
          inc  hl
          push hl
          ld   de,filen
          ld   bc,12
          ldir
          pop  hl
          ret


; Convert a filename within a .TAP file to +3 format
; Entry:	none
; Exit:	none
nsort:    ld    hl,intafil+10  
          ld    de,(filename_start)	; Destination
          push  de	        ; Save dest
          ld    c,10  	    ; Length of .TAP filename
          ld    b,8  	    ; Length of this segment
          call  nsort1  	; Returns hl = current pos in .TAP name
          ex    de,hl  	    ; Get it into de
          pop   hl	        ; Get original dest back
          push  bc  	    ; Save amount of .TAP chars left
          ld    bc,8  	    ; Step to '.' place
          add   hl,bc  
          pop   bc  
          ld    (hl),'.'  	; Put the '.' there
          inc   hl  	    ; Step to extension place
          ex    de,hl  	    ; Now hl = remainder of .TAP name, de = ext place
          ld    b,3  	    ; 3 characters in extension
          
nsort1:   ld    a,(hl)  	; Some bounds checking
          cp    127  	    ; If > 127 then use a # instead
          jr    nc,nsort7  
          cp    32  	    ; If < 32 then use a # as well
          jr    nc,nsort3  	
nsort7:   ld    a,'#'  
nsort3:   inc   hl  	    ; Increment .TAP pointer
          cp    '.'  	    ; If .TAP has a '.'
          jr    z,nsort8  	; Do some checking
          ld    (de),a  	; Otherwise store it
          inc   de  	    ; Increment +3 place
nsort9:   dec   c  	        ; Dec .TAP counter
          ret   z  	        ; And return if zero
          djnz  nsort1  	; Loop over characters left in +3 filepart
          ret   

nsort8:   ld    a,c  	    ; If we hit a '.' and we've not got two chars
          cp    2  	        ; left then return
          ret   nz  
          jr    nsort9

	;Get a +3 drive number...
;Exit:    hl=flags2

parse_p3name:   
	  ld    b,16  
          ld    de,namep3  	; Start of +3 filename
parse_p3name1:   
	  ld    (filename_start),de ; Say it starts there initially
          ld    hl,flags2
	  res   5,(hl)		; Indicate that its only a filename
gp3dr1:   ld    a,(de)  
          inc   de  
          cp    ':'  	    ; If the character is a : then prev char is drive
          jr    nz,gp3dr3  
          ld    (filename_start),de ; Filename starts after the :
          dec   de  	    ; Pick up the drive letter
          dec   de  
          ld    a,(de)
          bit   7,(hl)	    ; If set then check drive parameter (hl=flags2)
          call  z,ckdrv  
          ld    (de),a  	; And save the uppercased drive letter
          inc   de  	    ; Get the first letter of the filename
          inc   de  
          res   5,(hl)  	; Indicate +3 name is filename
          ld    a,(de)  	; If the first character after drive is space
          cp    32  	    ; then we just have a drive
          ret   nz  
          set   5,(hl)  	; Indicate that we only have a drive
          ret   
gp3dr3:   djnz  gp3dr1  	; Keep looping
          ret   
filename_start:   defw   0  	        ;VARIABLE - start of +3 filename without drives
          
; Check to see whether a +3 drive is valid
; Entry:	a = drive letter
; Exit:	z = drive valid 
;	a = upper cased drive descriptor
;	Displays error if invalid
ckdrv:    and   223  	    ; Convert to uppercase
          cp    'A'  
          ret   z  
          cp    'M'  
          ret   z  
          call  errorn  
          defb  78 	        ;invalid drv 
