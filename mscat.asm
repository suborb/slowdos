;
;       Slowdos Source Code
;
;
;       $Id: mscat.asm,v 1.2 2003/06/17 17:39:10 dom Exp $
;       $Author: dom $
;       $Date: 2003/06/17 17:39:10 $
;
;	Disc cataloging routines
    

		MODULE	catalogue

		INCLUDE	"slowdos.def"
		INCLUDE "syntax.def"
		INCLUDE "printing.def"

	;; External routines
		XREF	clfilen
	;; Error handling
		XREF	errorn

		XREF	getsec
	
		XREF	sros
		XREF	sros1

		XREF	swos
		XREF	swos1

		XREF	rdnxft

		XREF	r_hxfer
		XREF	uftofin

		XDEF	hook_catmem
		XDEF	hook_mscat
		XDEF	cat
		XDEF	mslog	
		XDEF	ncats3
		XDEF	discan
		XDEF	disca0
		XDEF	cksub
		XDEF	rdfat
		XDEF	wrfata
		XDEF	wrifat
		XDEF	cfile1

       
clusno:		defb	0	; VARIABLE - catalogue cluster count
catdon:		defb	0	; VARIABLE - number of root dir slots catalogued   

cursec:		defw	0	; VARIABLE - current sector being catalogued
fileno:		defb	0	; VARIABLE - Position within directory
discou:		defb    0       ; VARIABLE, saved file number within dir
dispos:		defw    0        ; VARIABLE, saved addy within dir

	
hook_catmem: 
	  ex    de,hl
          ld    (dumadd2+1),hl
          inc   hl
          ld    (dumadd+1),hl
          ld    hl,flags3
          set   7,(hl)
hook_mscat:  
	  call  r_hxfer
          call  uftofin
          jp    ncats3

; Catalogue disc routine
; Syntax:

cat:      call  syntax		; Check for syntax, if !syntax then set stuff up
          jr    z,cat1
          ld    a,2		; Set the default channel
          ld    (chanel),a
          call  clfilen		; Clear the filename, hl = filen
          ld    a,'*'		; Set up wild card checking
          ld    (hl),a  
          ld    (filen+9),a
cat1:     call  rout32		; Look for a channel identifier
          cp    '#'
          jr    nz,ncatcd
          set   7,(iy+1)
          call  e32_1n		; Expect one number
          cp    ','		; And then a comma or a semicolon
          jr    z,catcom
          cp    ';'
          jp    nz,error_nonsense
catcom:   call  syntax		; More bit fiddling in syntax mode
          jr    nz,catco1
          res   7,(iy+1)
catco1:   call  rout32		
          call  syntax		; If in syntax mode, don't get the number off
          jr    z,ncatcd
          call  getnum		; Get the stream off the stack
          ld    a,b
          or    c
          jr    nz,stinra
          set   7,c
stinra:   ld    a,c
          ld    (chanel),a
ncatcd:	  call  gdrive		; Get the drive number
          call  ckenqu		; Check for end of statement
          jr    z,ncatc1
          cp    ';'		; If not end of statement we must have a ';'
          jp    nz,error_nonsense
          call  rout32
          call  exptex		; And then we want a string
          call  ckend		; So this really is the end
          ld    hl,filen	; Get the BASIC string into filen
          call  getstr
          jr    ncats3
ncatc1:   call ckend		; If no string then we must check for the end
          

; The main catalogue routine itself

ncats3:   ld    a,(chanel)	; Direct output to the selected channel
          call  setchan
msccat:   call  mslog		; Log the disc in
          call  gsubst		; Setup for subdirectories
          
	  xor	a		; Initialise num file slots done
          ld    (catdon),a
          ld    hl,flags  
          res   2,(hl)  	; Set no files seen flag
msclop:   ld    de,(cursec)  
          call  chdpr  		; Read in and display directory for this sector
          call  nxdsec  	; Get next sector
          jr    c,msclop  	; Loop if there is a next sector
          
	  ld    hl,flags  	; If no files found, print the message
          bit   2,(hl)  
          jr    nz,root4  
          call  messag  
          defm  "No files found" & 13 & 255
root4:    ld    a,13  
          call  print  		; Print a blank line
          call  free		; Calculate disc space free
          ld    b,255		; And then display it b = 255 indicates space
          call  prhund  
          call  messag  
          defm  "K free" & 13 & 255         
          ret   


;Find number of free entries in FAT table
;Entry:   none
;Exit:    hl=number of free K

free:     ld   bc,713		;FIXME? Number of clusters available?
          ld   de,2		; First free cluster
          ld   hl,0		; Set 0 clusters free initially
free1:    push de		; Save all parameters
          push hl
          push bc
          call rdnxft		; Get next cluster for de
          pop  bc
          pop  hl
          ld   a,d		; If 0 then it's empty, inc free cluster count
          or   e
          jr   nz,free2
          inc  hl
free2:    pop  de
          inc  de		; Increment the cluster
          dec  bc		; Loop over bc
          ld   a,b
          or   c
          jr   nz,free1
          ld   de,(diskif+13)	; Get number of sectors in a cluster
          ld   d,0
          call rhlxde		; Multiply the two together
          srl  h		; Divide by two (since 1 sector=512 bytes)
          rr   l
          ret          
          

;
; Log a disc in - check the boot sector and read the FAT in
;
mslog:    ld    de,0		; MSDOS sector 0
          call  sros
          ld    hl,sector  	; Copy the sector to the diskif area
          ld    de,diskif  
          push  de  		; Save diskif
          ld    bc,30  
          ldir  
          pop   hl  		; Get it back
          ld    a,(hl)  	; Check the first few bytes for a signature
          cp    0Ebh  
          jr    z,mscat2  
mscat1:   call  errorn  
          defb  67 		;unrecognised disc format  

mscat2:   inc   hl  		; skip over second byte since M$ changed it
          inc   hl  		; go to third byte
          ld    a,(hl)  
          cp    090h  
          jr    nz,mscat1  	; Invalid, say unrecognised disc format
	  ld    hl,(diskif+17)	; Find number of sectors in root directory
          ld    b,4  
mscat3:   srl   h  
          rr    l  
          djnz  mscat3  
          ld    (rotlen),hl  	; And save the number
          ld    hl,(diskif+22)	; Sectors per FAT
          ld    de,(diskif+16)	; Number of FAT copies
          ld    d,0  
          call  rhlxde  
          ld    de,(diskif+14)  ; Number of reserved sectors
          ld    d,0  
          add   hl,de  
          ld    (rotsta),hl  	; Save start of root directory
          ld    a,(flags3)	; If we're not in subdir
          bit   3,a
          jr    nz,rdfat
          ld    (cursec),hl  	; Set current dir sector to the start of rootdir
          
;Read in the FAT table
rdfat:    ld    hl,sros1	
          jp    wrfata

; Write the FAT table 
; This function writes it twice

wrifat:   ld    hl,swos1
          call  wrfata
          jr    wrfat0

; Read/write the FAT table
; Entry:	hl = sector read/write routine
; Exit:		de = next sector after FAT table

wrfata:   ld    (fatch+1),hl	; Save which routine to use
          ld    de,(diskif+14)  ; Number of reserved sectors
wrfat0:   ld    b,3  		; Number of sectors in a FAT table
          ld    hl,fattab  	; Address of where the table is
wrfat1:   push  bc  
          push  hl  
          push  de  
fatch:    call  swos1  
          pop   de
          pop   hl
          pop   bc  
          inc   h  		; Increment writing position
          inc   h  
          inc   de  		; Increment the MSDOS sector
          djnz  wrfat1  
          ret   
          
;Scan a disc for the filename. The filename is stored in filen
;Entry: none
;Exit:  nc = no file found
;        c = file found and hl = filename
;        a = position in dirsector
          
disca0:   ld    hl,flags2  	; If reset then start from the start
          bit   4,(hl)  	
          jr    z,discan  
          ld    de,(dirsol)  	; Reread last sector and pick up old values
          call  sros  
          ld    a,(discou)  	; Pick up saved values
          ld    b,a  
          ld    hl,(dispos)  
          jr    discar  	; And jump to end of loop
         
discan:   ld    hl,flags2	; Indicate start from start
          res   4,(hl)
          ld    hl,0
          ld    (fileno),hl
          ld    (catdon),hl
          call  gsubst		; Setup for sub directories
disca1:   ld    hl,flags2	; If we're continuing, don't log the disc in
          bit   4,(hl)
          call  z,mslog
disca2:   ld    de,(cursec)  	; Save the current sector
          ld    (dirsol),de  
          call  sros  		; Read it in
          ld    b,16  		; Number of dir entries per sector
          ld    hl,sector  
disca3:   push  bc  
          push  hl  
          call  chffil  	; Check if this file match spec in filen
          jr    z,disca5 	; We matched it
          pop   hl  
          pop   bc  
discar:   ld    de,32  		; Skip to next dir entry
          add   hl,de  
          djnz  disca3  
          call  nxdsec  	; Get the next directory sector
          jr    c,disca2  	; Keep looping if there is one
          ret   

; If we matched a file then exit out of the scanning routine
disca5:   pop   hl  		; Get dir entry address back
          pop   bc  		; And count into sector
          ld    a,b  		; Save them so we can be called again
          ld    (discou),a  
          ld    (dispos),hl  
          ld    a,16  		; Calculate directory number
          sub   b  
          scf   		; Indicate that we matched a file
          ret   


; Set up directory variables for subdirectories
; Entry:	none
; Exit:		none
gsubst:   call  cksub
          ret   z
          ld    de,(sdclus)
          jp    nxdse6    ;place in curfat, get sector etc..

; Check to see we're inside a subdirectory
; Entry:	none
; Exit:		z = in subdir, nz = not in
;	       hl = flags3
cksub:    ld    hl,flags3
          bit   3,(hl)
          ret
        
;Get the next sector - this bit
;of code is often needed so
;dump into subroutine?!?
;Entry: none
;Exit:  c = more sectors..
;      nc = no more sectors
;      hl = sector to read next
          
nxdsec:   call  cksub		; Check for being in subdir
          jr    nz,nxdse2  	; If in subdir then do things differently
          call  nxdse3		; hl = (cursec)
          ld    a,(catdon)  	; Add 16 to number of file entries already done
	  add	a,16  
          ld    (catdon),a  
          ld    hl,diskif+17  	; Max number of root directory entries
          cp    (hl)  
          ret   c  		; There is a next sector
nxdse1:   and   a  		; Indicate no more sectors to read
          ret   
; Now, handle subdirectories
nxdse2:   ld    hl,clusno  	; Add one to current sector within cluster
          inc   (hl)  
          ld    a,(diskif+13)  	; Number of sectors per cluster
          cp    (hl)  
          jr    nz,nxdse3  	; Not matched, increment cursec and return
          ld    (hl),0  	; Start at sector 0 within the cluster
          ld    de,(curfat)	; Get current cluster number
          call  rdnxft  	; And then get the next
          jr    c,nxdse1	; There was no next, return and indicate so
nxdse6:   ld    (curfat),de	; Save the current cluster number
          call  getsec  	; Convert to sector number
          ld    (cursec),de	; Save it
          scf   		; Indicate that we have another sector
          ret




; Increment the current sector count
; Entry:	none			
; Exit:		c = set
;	       hl = next sector to read
nxdse3:   ld    hl,(cursec)  
          inc   hl  
          ld    (cursec),hl  
          scf   
          ret   
          
          

; Handles displaying a directory
; Entry:	de = current directory sector
; Exit:		none
          
chdpr:    call  sros  		; Read the sector
          ld    b,16  		; Number of files per sector
          ld    hl,sector  	; Start of directory
chdpr0:   push  bc  		; Save some registers
          push  hl  
          call  chffil  	; Check the filename
          jr    nc,chdpr1  	; No file there
          call  z,pricae  	; Print if it matches
chdpr1:   pop   hl  		; Restore registers
          pop   bc  
          ld    de,32  		; Step to next directory entry
          add   hl,de  
          djnz  chdpr0  	; And loop
          ret   
          
;Checks the directory entry to see it matches the pattern in filen
;Entry: hl = addy of filename in sector
;Exit:  hl = unchanged
;Flags:
;        c = file at entry
;        z = file is match
;       nz = file no match
;    nz+nc = no file present
;     z+nc = end of dir + no file - not valid
          
chffil:   ld    a,(fileno)  	; Increment position within directory
          inc   a  
          ld    (fileno),a  
          ld    a,(hl)  	; Check to see if file is deleted
          cp    0E5h  
          jr    z,chffi2  
          and   a  		; Alternate check for deleted file
          jr    z,chffi2  
          push  hl  		; Save address
          ld    bc,11  		; Go to flags
          add   hl,bc  
          bit   3,(hl)  	; Check for volume name
          pop   hl   		; Get address back
          jr    nz,nomatch 	; Volume names shouldn't match
          push  hl  		; Save address
          call  cfilen  	; Check filename, return z/nz for matching
          pop   hl  		; Restore address
chffi3:   scf  			; Indicate that there was a file here
          ret   
; Exit if there's no file at the position
chffi2:   ld    a,(frepos)  	; If we've no free dir position marked then set
          and   a  		; FIXME: should set to -1 really
          ret   nz		; (frepos) already contains a file position
          ld    a,(fileno)  
          ld    (frepos),a  	; Save free slot
          ld    de,(dirsol)	; Save sector where free position is
          ld    (dirsec),de
nomatch:  and  a		; nc means no file at position
          ret
       

;Put the CAT o/p into memory
dumadd:   ld    hl,0
          ld    bc,12
          ex    de,hl
          ldir      ;copy filename + type
          ld    c,15
          add   hl,bc
          ld    c,6 
          ldir      ;copy start cluster & filelength
          ex    de,hl
          ld    (dumadd+1),hl
          ld    a,(fileno)
dumadd2:  ld    (0),a
          pop   hl
          ret
          
          
; Print or dump the directory entry into a buffer
; Entry:	hl = directory entry
pricae:   push  hl  		; Save 
          ld    de,flags3
          ex    de,hl		; de = dir entry, hl = flags3
          bit   7,(hl)		; If we're dumping into a buffer, go there
          jr    nz,dumadd
          dec   hl
          dec   hl   		; hl = flags
          set   2,(hl)  	; Indicate that we matched a file
          ld    bc,8  		; Print out the main part of the filename
          call  string  
          ld    a,'.'  
          call  print  
          ld    c,3  		; And now the extension
          call  string  
          ex    de,hl  		; hl = dir entry, pointing at dir flags
          bit   4,(hl)  	; Test to see if directory
          jr    z,prica1	; No its not  
          call  messag  
          defm  "<DIR>" & 255
          jr    prica2  	; Skip over file size priting
prica1:   ld    a,32  		; Print a space
          call  print  
          ld    c,17  		; Step to filesize in dir entry
          add   hl,bc  
          inc   hl  		; Ignore bits 24-32 since it can't be used
          ld    e,(hl)  	; Pick up bits 8 - 23 of file size
          inc   hl  
          ld    d,(hl)  
          srl   d  		; Divide by 4
          rr    e  
          srl   d  
          rr    e  
          ex    de,hl  
          ld    b,255  		; Display leading spaces
          call  prhund  
          ld    a,'K'  		; It's always in K
          call  print  
prica2:   ld    a,13  		; Print a line feed
          call  print  
          pop   hl  		; Restore dir entry
          ret   
          
;Check the filename to see it matches the spec in filen
;Entry: hl = filename in direc
;Exit:   z = file is match
;       nz = file doesn't match
          
cfilen:   push  hl  		; Save address in directory
          ld    de,filen  	; filen contains the file pattern
          ld    b,8  		; Compare 8 characters
          call  cfile1  
          pop   hl  		; Get dir address back
          ret   nz  		; We didn't match at all
          ld    bc,8  		; Matched, skip to extension
          add   hl,bc  
          ld    de,filen+9  	; Load up filen extension
          ld    b,3  		; Extensions have 3 characters
          
cfile1:   ld    a,(de)  	; If matching pattern contains a '*' then match
          cp    '*'  
          ret   z  
          cp    '?'  		; A '?' matches any character
          jr    z,cfile2  
          xor   (hl)  		; Does a case insensitive match
          and   223  
          ret   nz  		; Doesn't match
cfile2:   inc   de  		; We matched carry on looping
          inc   hl  
          djnz  cfile1  
          ret   		; Will return z if we get to the end
          
          
          

          
          


