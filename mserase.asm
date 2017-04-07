;
;       Slowdos Source Code
;
;
;       $Id: mserase.asm,v 1.3 2003/06/15 20:26:25 dom Exp $
;       $Author: dom $
;       $Date: 2003/06/15 20:26:25 $
;
;	Erase command


		MODULE	erase

		INCLUDE	"slowdos.def"
		INCLUDE	"syntaxdefs.def"

	;; Errors that we use
		EXTERN	errorn
		EXTERN	error_notfound
		EXTERN	error_filetype
	;; Other things
		EXTERN	settapn
		EXTERN	clfiln
		EXTERN	clfilen
		EXTERN	ckchar

		EXTERN	discan
		EXTERN	disca0

		EXTERN	swos
		EXTERN	swos1

		EXTERN	rdnxft
		EXTERN	link_clusters	
		EXTERN	wrfata

		EXTERN	r_hxfer
		EXTERN	uftofin
		EXTERN	ckwild

		PUBLIC	hook_erase
		PUBLIC	erase
		PUBLIC	getdiroffset


fildes:		defs	12,32	; VARIABLE


hook_erase:  
	  call  r_hxfer
          call  uftofin
          ld    hl,filen
          call  ckwild
          jp    en_ers
	
	
; Erase command
;
; Syntax:
; ERASE Pdd"f"   - erase file f from the disc, f may be wild
; ERASE Pdd"u1" TO "u2"    - rename u1 to u2


erase:
          call  getdrv		; Get the drive
          call  cksemi  	; Get a semi colon, comma or quote
          call  exptex  	; We want some text
          call  ckenqu  	; Check for end of statement (i.e. delete)
          jp    z,erase6  
          cp    204      	; If not end, TO must follow
          jp    nz,error_nonsense ; If not, then nonsense in basic

; Renaming files
          call  rout32  	
          call  cksemi  	; We expect a semi colon, comma or filename
          call  exptex  	; Get a strinbg
          call  ckend  		; End of statement
          call  settapn		; Clear .TAP modes
          ld    hl,fildes	; Clear fildes
          call  clfiln  	; Exits with hl=fildes
          call  getstr  	; Get the second string
          jr    z,eras15  
eras14:   call  errorn  
          defb  43 		;bad filename  
eras15:   call  clfilen		; Clear ufia+2, hl = ufia+2
          call  getstr  	; Get the original filename
          jr    nz,eras14  
          call  discan  	; Search for the original filename a = posn
          jp    nc,error_notfound ; File not found
erase0:   ld    de,(dirsol)	; Get directory sector
          push  de		; Save it
          call  getdiroffset	; Get offset within sector for dir entry
          push  hl		; Save that too
          ld    hl,sector  	; Copy the read sector to the write sector
          ld    de,wrisec  
          push  de
          ld    bc,512  
          ldir  
          pop   de		; Get wrisec back
          pop   ix		; Get the offset into sector back
          add   ix,de		; Now ix points to the file
erase2:   bit   0,(ix+11)  	; Check for read only flag
          jr    z,eras25  
          call  errorn  
          defb  52 ;read only  
eras25:   push  ix		; Save the sector positoin
          ld    hl,fildes  	; Check the new filename for bad characters
          push  hl
          call  ckchar
          pop   hl
          jp    c,error_filename 
          pop   de  		; Copy the new filename over the old one
          push  hl  		; hl = fildes
          ld    bc,8  
          ldir  
          inc   hl		; Now do extension
          ld    bc,3
          ldir
          pop   hl  		; Get fildes back, copy to filen
          ld    de,filen  
          ld    bc,12  
          ldir  
          call  discan  	; Scan the disc for the new name
          jr    nc,erase4  	; If found then error
          call  errorn  
          defb  32 ;file exists  
erase4:   pop   de  		; Not found, so write out the directory sector
          jp    swos  

; Delete a file from disc
erase6:   call  ckend		; End of statement
          call  settapn  	; Clear .TAP modes
          call  clfilen  	; Clear filen,  hl = filen
          call  getstr  	; Get the filename
en_ers:   ld    hl,flags  
          res   2,(hl)  	; No files found yet
          inc   hl   		; hl=flags2
          res   4,(hl)  	; Indicate start from beginning of directory
eras64:   call  disca0  	; Scan the disc 
          jr    c,erase8  	; Filename found
          ld    hl,flags  	
          bit   1,(hl)  	; Check if wild filename was supplied
          jr    z,erase7  	; No it wasn't
          bit   2,(hl)  	; Check to see if we already found something
          ret   nz  		; We did, so exit normally
erase7:   call  errorn  
          defb  34 		;file not exist  
erase8:   call  getdiroffset	; Offset within directory
          push  hl		; Save it
          ld    hl,sector  	; Copy this sector to write sector
          ld    de,wrisec  
          push  de
          ld    bc,512  
          ldir  
          pop   de		; de = wrisec
          pop   ix		; offset within directory
          add   ix,de
          bit   0,(ix+11) 	; check for read only file
          jr    z,eras81
          call  errorn
          defb  52   		;file read only
eras81:   bit   4,(ix+11) 	; can't delete directories
          jp    nz,error_filetype
eras82:   bit   3,(ix+11) 	; can't delete volume names
          jp    nz,error_filetype
          ld    (ix+0),229   	; Blank out first character of name
; Chase the FAT trail and zero down clusters occupied by this file
          ld    e,(ix+26)
          ld    d,(ix+27)
eras84:   push  de
          call  rdnxft		; de = next cluster
          pop   hl		; hl = current cluster
          push  af		; Save whether valid next cluster or not
          ex    de,hl
          push  hl		; Save next cluster
          ld    bc,0		; Zero out that link
          call  link_clusters
          pop   de		; Get next cluster back
          pop   af		; nc means next cluster is good
          jr    nc,eras84
          ld    hl,swos1	; Write out one copy of the FAT, save the other
          call  wrfata		; so it can be used to restore files
          ld    de,(dirsol)	; Write out the directory sector
          call  swos  
          ld    hl,flags  
          set   2,(hl)  	; Indicate that we've deleted a file
          bit   1,(hl)  	; Check to see if filename was wild
          inc   hl   		; hl=flags2
          set   4,(hl)		; Continue scanning directory from last posn
          jr    nz,eras64  	; loop back around if filename was wild
          ret

;Routine to find position in directory sector
;Entry:   a=file posn (and 15)
;Exit:   hl=offset

getdiroffset:
	and	15
	add	A,A
	ADD	A,A
	ADD	A,A
	ld	l,a
	ld	h,0
	add	hl,hl
	add	hl,hl
	ret
