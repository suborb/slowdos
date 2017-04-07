;
;       Slowdos Source Code
;
;
;       $Id: msload.asm,v 1.3 2003/06/15 20:26:26 dom Exp $
;       $Author: dom $
;       $Date: 2003/06/15 20:26:26 $
;
;	Routines concerned with loading files from disc



		MODULE	load

		INCLUDE	"slowdos.def"

		INCLUDE "syntaxdefs.def"



		;; Routines that are external to this module

		EXTERN	clfiln
		EXTERN	settapn
		EXTERN	errorn

		EXTERN	discan
		EXTERN	disca0
		EXTERN	ckchar
		EXTERN	swos
		EXTERN	clfilen
		EXTERN	locimp
		EXTERN	wrfata
		EXTERN	rdnxft
		EXTERN	swos1
		EXTERN	getsec
		EXTERN	uftofin

		EXTERN	setchan
		EXTERN	messag
		EXTERN	confim
		EXTERN	dodos

		EXTERN	rdfat
		EXTERN	clfil0
		EXTERN	cfile1


		EXTERN	sros

		EXTERN	r_hxfer


		PUBLIC	file_signature
		PUBLIC	error_filetype
		PUBLIC	error_notfound

		PUBLIC	hook_rdopen
		PUBLIC	rdopen
		PUBLIC	rdope1
		PUBLIC	ckext
		PUBLIC	trdope
		PUBLIC	pdconv
		PUBLIC	rdblok
		PUBLIC	rdbyte
		PUBLIC	wrcopy
		PUBLIC	rdini1
		PUBLIC	rdcop1
	

          
;File signature for +3 files
.file_signature   
	  defm    "PLUS3DOS"
          defb    26  
          defb    1,0 ;version no  
          
          
texsna:   defm    "SNA"  	; File extension for .SNA files

rdclco:		defb	0	; VARIABLE - sectors to go in cluster
rdclse:		defw	0	; VARIABLE - current reading DOS sector
rdclus:		defw	0	; VARIABLE - current reading cluster
sectgo:		defw	0	; VARIABLE - bytes left in sector
secpos:		defw	0	; VARIABLE - reading position in sector


hook_rdopen:  
	  call  r_hxfer
	;; Fall into rdopen
          
;Open a file to read
;Entry: ix=ufia

rdopen:   ld    hl,flags2
          bit   6,(hl)		; Are we reading a .TAP file?
          jp    nz,trdope
          call  uftofin		; Copy ufia to filen, exit hl = ufia+2
          call  ckchar		; Check filename and upper case it
          jp    c,error_filename
          call  discan  	; Scan for the file in the directory
          jr    c,rdope1  	; It did exit
error_notfound:
          call  errorn  
          defb  34		    ;file not exist  
rdope1:   ld    de,pdname	; Copy the filename for use by copy
          ld    bc,8
          ldir
          ld    a,'.'
          ld    (de),a
          inc   de
          ld    c,3		; We know b = 0
          ldir
          bit   4,(hl)  	; Check the directory flags
          jr    z,rdope2  	; It wasn't a directory
error_filetype:
          call  errorn  	
          defb    29            ;wrong file type  
rdope2:   ld    de,15 		; Get the started cluster 
          add   hl,de  
          ld    e,(hl)  
          inc   hl  
          ld    d,(hl)  
          inc   hl
          ld    (rdclus),de     ; And save it
          push  hl  		; hl points to file length, save it
          call  getsec  	; Convert cluster into sector
          pop   hl  		; Get pointer to file length back
          ld    (rdclse),de     ; Save the starting sector
          ld    c,(hl)  	; Pick up the file length (lsb)
          inc   hl  
          ld    b,(hl)  
          inc   hl  
          ld    e,(hl)  
          inc   hl  
          ld    d,(hl)  	; msb
          ld    (rdflen),bc     ; Save file length
          ld    (rdflen+2),de  
          ld    a,(diskif+13)  	; Number of sectors in a cluster
          inc   a  
          ld    (rdclco),a      ; And save it
          call  rnfsec  	; Read in first sector
          ld    hl,sector  	; Check file header
          ld    de,file_signature  
          ld    b,9  
rdope3:   ld    a,(de)  
          cp    (hl)  
          jr    nz,rdope5  	; It doesn't match i.e. headerless file
          inc   hl  
          inc   de  
          djnz  rdope3  
          ld    bc,6  		; Step to +3 header information
          add   hl,bc  
          ld    de,temphd  
          inc  bc   		; bc was 6, need it to be 7!!!
          ldir  		    ; Copy the header to temporary space
          ld    hl,384  	; Set up sector variables
          ld    (sectgo),hl  
          ld    hl,sector+128  
          ld    (secpos),hl  
          ret   
;Files without PLUS3DOS headers
rdope5:   ld    hl,(rdflen+2)  
          ld    a,h  
          or    l  
          jr    z,rdope6 	; File was < 65536 bytes 
rdope7:   ld    a,5   		; Indicate long file
rdope8:   ld    (temphd),a  
          ld    hl,(rdflen)     ; Set up the length and other header stuff
          ld    de,(rdflen+2)  
rdopeb:   ld    (temphd+1),hl  
          ld    (temphd+3),de  
          ld    hl,0  
          ld    (temphd+5),hl  
          ret
rdope6:   ld    hl,(rdflen)	; Check for snapshot length
          ld    bc,49179  
          and   a  
          sbc   hl,bc  
          ld    a,h  
          or    l
          ld    a,3             ; Just a normal code file 
          jr    nz,rdope8       ; Setup headers 
          ld    de,filen+9      ; Compare extension
          ld    hl,texsna  
          call  ckext		; Exits with 3 =code, 4 =snap files
          jr    rdope8

;Check an extension matches...
;Entry:   de=filename extension
;         hl=should match with
;Exit:     z=match/nz=no match
;         a=4(snap)/3(code) - only for .SNA matching

ckext:    ld    b,3
ckext1:   ld    a,(de)
          and   223
          cp    (hl)
          ld    a,3             ;normal code
          ret   nz
          inc   hl
          inc   de
          djnz  ckext1
          ld    a,4             ;snapshot
          ret


       
; Open a file within a .TAP file
trdope:   push  ix	        ; Save ufia
          call  rdfat	        ; Read the FAT table in
          pop   ix	        ; Restore ufia
trdoper:  call  rdbyte	        ; Read in length of .TAP file
          ld    e,a
          call  rdbyte
          ld    d,a
          ld    hl,19	        ; Compare with length of header
          and   a
          sbc   hl,de
          ld    a,h
          or    l
          jr    z,trdope2	; There was a header file there
          ld    a,(ix+2) 	; Check to see if we're copying out of a .TAP 
          cp    '*'
          jp    nz,trdope9	; We're not, so skip this block
          call  rdbyte   	; Skip the .TAP file type
          dec   de		    ; Decrement file length
          ld    a,3		    ; Construct a fake header
          ld    hl,0
          ld    (temphd),a
          ld    (temphd+1),de
          ld    (temphd+3),hl
          ld    (temphd+5),hl
          ld    a,l
          and   a           ;nc,z
          ret
trdope2:  call  rdbyte		; Read 'header' .TAP filetype
          dec   de		; Reduce file length
          and   a               ; Filetype must be zero
          jr    nz,trdope9	; If not, we'll skip the file
          call  rdbyte		; Read ZX filetype
          dec   de		; Decrement file length
          ld    (temphd),a	; Save filetype
          ld    hl,intafil	; Clear the temporary space
          ld    b,20
          call  clfil0		; Exits with hl = intafil
          push  de	        ; Save file length
          call  pdconv    	; Convert +3 filename in ufia to .TAP in intafil
          pop   de		; Get file length back
          ld    b,10		; Read in the filename in the .TAP file
          ld    hl,intafil+10
trdope0:  call  rdbyte
          dec   de
          ld    (hl),a
          inc   hl
          djnz  trdope0
          ld    b,6		; Now read in the header info from the .TAP file
          ld    hl,temphd+1
trdope1:  call  rdbyte
          dec   de
          ld    (hl),a
          inc   hl
          djnz  trdope1
          push  de		; Save file length
          ld    hl,intafil+10	; Compare filenames
          ld    de,intafil
          ld    b,10
          call  cfile1
          pop   de		; Restore file length
          jr    nz,trdope9	; If they don't match, skip over this block
          call  rdbyte    	; Discard the checksum of header
          call  rdbyte    	; Discard LSB of next block length
          call  rdbyte    	; Discard MSB of next block length
          call  rdbyte    	; Discard datatype of next block
          ld    a,e		; e != 0
          and   a               ;nc,nz
          ret

;Scan to end of file...
trdope9:  ld    a,d		; check length
          or    e
          jp    z,trdoper
          call  rdbyte		; Read byte
          dec   de	        ; Decrement file length
          jr    trdope9		; And loop


;Adjust name MSDOS > tape
          
pdconv:   push  ix		; Get ufia into hl
          pop   hl
          inc   hl		; Skip to ufia+2
          inc   hl
          ld    de,intafil  
adjust:   ld    bc,2573  	; b = 10, c = 13
lback:    ld    a,(hl)  
          dec   c  
          jr    z,adok  
          inc   hl  
          cp    32  
          jr    nz,lok  
          jr    lback  
lok:      ld    (de),a  
          inc   de  
          djnz  lback  
          jr    adout  
adok:     ld    a,32  
adok1:    ld    (de),a  
          inc   de  
          djnz  adok1  
adout:    ld    hl,intafil  
;Check to remove trailing '.'
          ld    b,10  
adout1:   ld    a,(hl)  
          cp    '.'  
          jr    nz,adout2  
          inc   hl  
          ld    a,(hl)  
          cp    32  
          ret   nz  
          dec   hl  
          ld    (hl),32  
          ret   
adout2:   inc   hl  
          djnz  adout1
          ret


;Read the next sector for a file
rnfsec:   ld    hl,rdclco  	; Decrement sectors in cluster count
          dec   (hl)  
          call  z,rnfse2  	; Read all sectors, get next cluster
rnfse1:   ld    de,(rdclse)     ; Read in the next sector in a cluster
          push  de  
          call  sros  
          pop   de  
          inc   de  
          ld    (rdclse),de     ; Save next sector position
          ld    hl,512  	; Set up reading variables
          ld    (sectgo),hl  
          ld    hl,sector  
          ld    (secpos),hl  
          ret   
rnfse2:   ld    de,(rdclus)     ; Pick up current cluster
          call  rdnxft  	; Get next cluster
          ld    (rdclus),de     ; Save it
          jr    nc,rnfse3  	; Next cluster is valid
rnfse4:   call  errorn  
          defb    49 		;end of file  
rnfse3:   call  getsec  	; Convert to DOS sector
          ld    (rdclse),de     ; Save it
          ld    a,(diskif+13)  	; Number of sectors per cluster
          ld    (rdclco),a  	; Save it
          ret
          
          
          
;Read a block of bytes
;Entry: de=ld addr
;       bc=length
          
rdblok:   call  rdinit  	; Copy control block to printer buffer
rdblo1:   ld    a,b  		; Check file length
          or    c  
          jr    z,rdblo0  	; Read all we should
          call  rdbyte  	; Read a byte from disc
          call  rdcopy  	; Copy to the appropriate place
          inc   de  
          dec   bc  
          jr    rdblo1  	; Loop round once more
rdblo0:   ld    hl,flags2	; Check for reading .TAP file
          bit   6,(hl)
          ret   z		; Not reading .TAP file
          jp    rdbyte		; Swallow the parity byte
          
; Read/write a byte from any page in memory
; This calls code in the printer buffer
wrcopy:
rdcopy:   di    
          push  bc  
          ld    b,a  
          ld    a,(page)  
          ld    l,a  
          ld    a,b  
          ld    bc,32765  
          ld    h,23  
          jp    23420  
rdcop1:   pop   bc  
          ei    
          ret   
          
; Little utility routine to read a byte from memory pages
rdcopr:   out   (c),l  
          ld    (de),a  
          out   (c),h  
          jp    rdcop1  
          
rdinit:   ld    hl,rdcopr  
rdini1:   push  de  
          push  bc  
          ld    de,23420  
          ld    bc,10  
          ldir  
          pop   bc  
          pop   de  
          ret   
          
;Read a byte from the file
;Entry: none
;Exit:  a=byte
;(all else preserved)
rdbyte:   push  de  
          push  bc  
          push  hl  
          ld    hl,(sectgo)     ; Check amount left to read in current sector
          ld    a,h  
          or    l  
          call  z,rnfsec  	; Need to pick up the next sector
rdbyt1:   ld    hl,(secpos)  
          ld    a,(hl)  
          inc   hl  
          ld    (secpos),hl  
          ld    hl,(sectgo)  
          dec   hl  
          ld    (sectgo),hl  
rdbyt2:   pop   hl  
          pop   bc  
          pop   de  
          ret   
          


