;Storage variables for Slowdos 
;Shoved at end to avoid some nasty
;Memory conflicts (if any...)


;From msload

curdrv:
ufia:	db	0	;drive
chanel:	db	0	;stream
	ds	12,32	;name - including '.'
	db	0	;dir flags
	db	0	;filetype
	dw	0	;file length
	dw	0	;load addy
	dw	0	;offset

;Filetype 4=48k snapshot
;Filetype 5=headerless long code

;Variables for loading..

rdclco:	db	0	;counter
rdclse:	dw	0	;sector
rdclus:	dw	0	;cluster
rdflen:	dw	0,0	;file length
rdfsec:	dw	0	;used for copy MS - MS
sectgo:	dw	0
secpos:	dw	0
temphd:	ds	7,0

;Variables for saving

wrclco:	db	0
wrtogo:	dw	0
wrsepo:	dw	0
wrclus:	dw	0
wrclse:	dw	0
wrdsec:	dw	0
wrdpos:	dw	0

wrflen:	dw	0,0
;dirmse:	ds	32,0


;From mscopy.asm
;At 65472 have 64 bytes to play with....

dirmse:	equ	65472	;32
diskif:	equ	dirmse+32	;30


;Plus3 filename and header
namep3:	ds	16,32
	db	255
pdname:	ds	12,0
catnam:	ds	16,32
	db	255
copied:	db	0

;Second ufia - not used!!!
;ufia2:	ds	22,0


;From mscat5.asm

;MSDOS catalogue data

;volnam:	ds	11,32
curfat:	dw	0
cursec:	dw	0
catdon:	db	0
clusno:	db	0
flags:	db	0
flags2:	db	0
flags3:	db	0
rotsta:	dw	0
rotlen:	dw	0
fileno:	db	0
frepos:	db	0


;MSDOS disc parameter table

;diskif:	ds	30,0
