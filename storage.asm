;
;       Slowdos Source Code
;
;
;       $Id: storage.asm,v 1.3 2003/06/17 19:08:03 dom Exp $
;       $Author: dom $
;       $Date: 2003/06/17 19:08:03 $
;
;	Memory storage that is used 
	

		MODULE	storage

		XDEF	curdrv
		XDEF	ufia
		XDEF	chanel
		XDEF	temphd
		XDEF	rdflen
		XDEF	wrflen
		XDEF	page
		XDEF	namep3
		XDEF	pdname
		XDEF	curfat
		XDEF	flags
		XDEF	flags2
		XDEF	flags3
		XDEF	rotsta
		XDEF	rotlen
		XDEF	fileno
		XDEF	frepos
		XDEF	dirsec
		XDEF	dirsol
		XDEF	sdclus
		XDEF	filen
		XDEF	intafil



;From msload

curdrv:
ufia:		defb	0	;drive
chanel:		defb	0	;stream
		defs	12,32	;name - including '.'
		defb	0	;dir flags
		defb	0	;filetype
		defw	0	;file length
		defw	0	;load addy
		defw	0	;offset

	
temphd:		defs	7,0
rdflen:		defw	0,0	; VARIABLE - reading file length


wrflen:		defw	0,0	; VARIABLE - writing file length

page:     defb    0		; VARIABLE


;Plus3 filename and header
namep3:		defs	16,32	; VARIABLE - +3 filename
		defb	255
pdname:		defs	12,0



curfat:		defw	0	; VARIABLE - current/last cluster of catalogue
flags:		defb	0	; VARIABLE
flags2:		defb	0	; VARIABLE
flags3:		defb	0	; VARIABLE
rotsta:		defw	0	; VARIABLE - start of root directory
rotlen:		defw	0	; VARIABLE - length of root directory
fileno:		defb	0	; VARIABLE - Position within directory
frepos:		defb	0	; VARIABLE - free position

dirsec:		defw    0	 ; VARIABLE - sector containing first free dir entry
dirsol:		defw    0        ; VARIABLE, saved directory sector
sdclus:		defw    0        ; VARIABLE, subdir starting cluster number
filen:		defs    12,0     ; VARIABLE, contains file pattern
intafil:	defs    20,32    ; VARIABLE - store for .TAP filenames


