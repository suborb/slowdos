;
;       Slowdos Source Code
;
;
;       $Id: mscopy.asm,v 1.3 2003/06/15 20:26:25 dom Exp $
;       $Author: dom $
;       $Date: 2003/06/15 20:26:25 $
;
;       Copy routines


		MODULE	copy

		INCLUDE	"slowdos.def"
		INCLUDE	"syntax.def"
		INCLUDE	"printing.def"

	;; Errors
		XREF	errorn
		

		XREF	settap
		XREF	settapn

		XREF	clufia
		XREF	clfil0
		XREF	clfilen
		XREF	getst0

		XREF	dodos

		XREF	disca0
	
		XREF	wropen
		XREF	wrbyte
		XREF	wrclos

		XREF	trdope
		XREF	rdope1
		XREF	rdbyte
		
		XREF	tapnam	;  msmove.asm

		XREF	parse_p3name
		XREF	filename_start
		XREF	nsort

		XDEF	copy



catnam:		defs	16,32	; VARIABLE - used for cataloguing
		defb	255
copied:		defb	0	; VARIABLE - number of files copied
	
; Copy command
;
; Syntax:
; COPY Pdd"u1" TO "u2"
; COPY "u1" TO Pdd[!]["u2"]
          
copy:     call  rout32  	; Check to see which mode we want
          and   223  
          cp    'P'  	    ; Copying from MSDOS
          jp    z,copy20  
          
; Copying to MSDOS from +3
          call  exptex  	; We want a string
          cp    204  	    ; The next token should be TO
          jp    nz,error_nonsense  	; Else its nonsense in BASIC
          call  getdrv	    ; Get the drive specifier
          call  syntax  	; If only syntax mode don't set some flags
          jr    z,copy1  
          ld    hl,flags2  
          set   3,(hl)  	; Set destination is drive flag
          dec   hl   	    ; hl=flags
          res   5,(hl)	    ; Indicate that we do want the file header
          call  settapn	    ; some .TAP thing?
copy1:    call  rout24	    ; Get current token
          cp    '!'	        ; If '!' is specified then miss off the header
          jr    nz,copycf
          ld    hl,flags	; Indicate headerless, why no syntax check?
          set   5,(hl)	    ; FIXME
          call  rout32
copycf:   call  ckenqu  	; Check for end
          jr    z,copy2  	; It was the end
          call  cksemi  	; Check for semi, comma or double quote
          call  exptex  	; We expect a string
          call  syntax  	; Check for running in syntax mode
          jr    z,copy2  
          ld    hl,flags2  	; The destination isn't a file
          res   3,(hl)  
          call  clufia	    ; Clear ufia, hl = ufia+2
          call  getstr  	; Get the DOS filename
          jr    z,copy2  	; Valid destination filename
          call  errorn  
          defb  73 	        ;dest can't wild  
copy2:    call  ckend  	    ; Statement end/syntax mode
          ld    hl,flags2  
          res   2,(hl)  	; Indicate no files copied yet
          res   1,(hl)	    ; Reset +3 filename is wild
          set   7,(hl)
          ld    b,16
          ld    hl,namep3  	; Clear the source filename
          call  clfil0	    ; Exits with hl = clfil0
          ld    bc,16	    ; Max 16 characters
          call  getst0  	; Get the string
          ld    hl,flags2  
          jr    z,cop2_3  
          bit   3,(hl)  	; Source is wild, but filename specified
          jr    nz,cop2_8  
          call  errorn  
          defb  74 	        ;dest must be drv  
cop2_8:   set   1,(hl)  	; Indicate +3 filename is wild
cop2_9:   ld    hl,namep3  	; Copy the whole filename to catalogue wildcard
          ld    de,catnam  
          ld    bc,16  
          ldir  
; Reset the variables etc...
cop2_3:   ld    hl,copied  	; Reset copied file count
          ld    (hl),0  
          ld    a,2  	    ; Print to upper screen
          call  setchan
          ld    a,13  	    ; Print a newline first of all
          call  print  
copy3:    call  parse_p3name  	;hl=flags2 on exit
          bit   1,(hl)  	; Check to see if source is wild
          jr    z,copy9  	; No its not
; Since we have a wild source, we have to catalogue the +3 disc
          xor   a
          ld    de,sector	; Initialise the last catname space
          ld    b,32
clp3csp:  ld    (de),a
          inc   de
          djnz  clp3csp  
          bit   2,(hl)  	; hl = flags2, have we copied before?
          jr    z,cop3_1  	; No, leave cat buffer uninitialised
          ld    hl,(filename_start) ; Copy the user/drive stripped filename
          ld    de,sector  
          ld    c,8  
          ldir  
          inc   hl  
          ld    c,3  
          ldir  
cop3_1:   ld    hl,catnam  	; Matching wildcard
          ld    de,sector  	; Last matched filename/buffer
          ld    bc,769	    ; b = buffer size (3), c = include system files
          ld    iy,286  	; +3DOS catalogue vector
          call  dodos  
          ld    hl,flags2  
          dec   b	        ; b should be > 1
          jr    nz,cop3_2  
          bit   2,(hl)  	; Check to see if we've copied any already
          jp    nz,copy6  
          call  errorn  
          defb  47 	        ;file not found  
cop3_2:   ld    hl,sector+13  ; Copy first matching entry to full spec buffer
          ld    de,(filename_start) ; Destination buffer
          ld    b,8  	    ; Copy root
          call  cop3_3  	; Removes flags which are in bit 7 of each char
          ld    a,'.'  	    ; Plonk a '.' in
          ld    (de),a  
          inc   de  
          ld    b,3  	    ; Now do the extension
          call  cop3_3  
          jr    copy9
cop3_3:   ld    a,(hl)  
          and   127  
          ld    (de),a  
          inc   hl  
          inc   de  
          djnz  cop3_3  
          ret   
copy9:
          ld    hl,flags2	; Check if destination is drive
          bit   3,(hl)
          jr    z,cop9_1	; It isn't - i.e. we had a filename
          ld    hl,(filename_start)	; So copy +3 filename to DOS filename buffer
          ld    de,ufia+2
          ld    bc,12
          ldir
cop9_1:   call  prfiln  	; Print the +3 filename
          ld    de,ufia+2  
          call  prdfin  	; Print the DOS file number
          ld    hl,copied  	; Increment the number file copied count
          inc   (hl)  
          ld    bc,1  	    ; Open the file on the +3 disc
          ld    d,b  
          ld    e,c  
          ld    hl,namep3  
          ld    iy,262  	; +3DOS OPEN_FILE vactor
          call  dodos  
          ld    b,0  	    ; Get the +3 DOS fileheader
          ld    iy,271  
          call  dodos  	    ; ix points to file header in page 7
          jr    z,wfilt1	; There's no file header
          ld    a,(ix+1)	; Check for the file length being 0
          or    (ix+2)
          jr    z,wfilt1	; If it is, then declare header invalid
          push  ix  	    ; If header is valid, copy it over to the ufia
          pop   hl  
          ld    de,ufia+15  
          ld    bc,7  
          ldir  
          jr    nobas1
; If there's no header, or the header indicates a 0 length file then 
; fake the file header for MSDOS
wfilt1:
          ld    hl,ufia+15
          ld    b,7
wfilt2:   ld    (hl),0
          inc   hl
          djnz  wfilt2
; Find the length of the file
nobas1:   ld    b,0
          ld    iy,307	    ;DOS GET POSITION
          call  dodos 
          push  hl	        ;Since at the start of file e = 0
          ld    b,0
          ld    iy,313	    ;DOS GET EOF
          call  dodos
          ld    d,0
          pop   bc
          and   a
          sbc   hl,bc
          jr    nc,nobas2
          dec   e
nobas2:
          push  hl	        ; Save file length
          push  de
          ld    ix,ufia  	; Open the MSDOS file
          call  wropen  
          pop   de	        ; Get file length back
          pop   hl
          inc   e	
copy5:    push  hl	        ; BUG! This loop is wrong
          push  de  
          ld    b,0  
          ld    iy,280  	; DOS BYTE READ
          call  dodos  
          ld    a,c  	    ; Write the byte to the MSDOS disc
          call  wrbyte  
          pop   de
          pop   hl
          dec   hl	        ; As I said, this loop is  wrong and will cause
          ld    a,h	        ; problems if file has length that is a multiple
          or    l	        ; of 65536
          jr    nz,copy5
          dec   e
          jr    nz,copy5
          call  wrclos  	; Close the DOS file
          ld    b,0  	    ; Close the +3 file
          ld    iy,265  	; DOS CLOSE
          call  dodos  
          ld    hl,flags2  
          set   2,(hl)  	; Indicate that we copied a file
          bit   1,(hl)  	; Was the source wild
          jp    nz,copy3  	; If so, loop around
copy6:    call  messag  	; Print ip how many files were copied
          defb  13,13,32,255  
          ld    hl,(copied)  
          ld    h,0  
          ld    b,255  	    ; Space lead the number
          call  prhund  
          call  messag  
          defm  " file" & 255
          ld    a,(copied)  ; Nice touch so that the English is correct
          dec   a  
          ld    a,'s'  
          call  nz,print  
          call  messag  
          defm  " copied." & 13 & 255
          ret   
          
          
; Copy file from MSDOS to +3 disc
copy20:   call  rout32  	; Get next character
          call  gdrive  	; Get drive specifier
          call  cksemi  	; We want a semi colon, comma or quote
          call  exptex  	; No we want a string
          cp    204  	    ; The next token must be TOO
          jp    nz,error_nonsense  	; Else its nonsense in BASIC
          call  rout32  	; Get the next character
          call  exptex  	; We want the destination filename
          call  ckend  	    ; And that must be the end of the statement
          ld    hl,flags	; BUG! Should be flags2 not flags
          set   7,(hl)
          dec   hl   	    ; 
          res   5,(hl)	    ; BUG? Should be flags2 - dest drive
          ld    b,16  	    ; Clear the destination filename
          ld    hl,namep3  
          call  clfil0	    ; Exits with b = 0, hl = namep3
          ld    c,16  	    ; And get the string
          call  getst0  
          jp    nz,error_filename ; Destination can't be wild
copy23:   ld    hl,flags2  	; ????
          ld    a,(hl)
          and   11110000b
          ld    (hl),a
          call  parse_p3name  	; Parse the +3 filename, hl = flags2
          bit   5,(hl)  	; Set if +3 filename is only a drive
          jr    z,copy24  
          set   3,(hl)  	; Indicates that we only have a drive dest?
copy24:   ld    a,1         ;ATP..the MSDOG name may be .TAP..
          call  settap
          call  clfilen  	; Clear filen, exit hl=filen
          call  getstr  	; Get the MSDOS source name
          jr    z,copy25  	; Source isn't wild
          ld    hl,flags2  
          set   1,(hl)	    ; Indicate source is wild
          bit   3,(hl)  	; Check to see if dest is drive
          jr    nz,copy25  	; It was, so no need to error
          call  errorn  
          defb  74 	        ;dest must be drv  
copy25:   ld    hl,copied  	; Initialise number of copied files
          ld    (hl),0  
          ld    a,2  	    ; Display in the upper screen
          call  setchan
          ld    a,13  
          call  print  
cop251:   ld    ix,ufia  
          ld    hl,flags2	; Check to see if we're in a .TAP file
          bit   6,(hl)
          jr    z,cop252	; No we're not
          ld    ix,filen-2	; In .TAP file, pretend the filen is the ufia
          push  hl	        ; Save flags2
          call  trdope	    ; Open the file within the .TAP file
          jr    nz,cop295	; Jump if there was a filename in the .TAP file
          ld    hl,tapnam	; There was no filename (headerless etc)
          ld    de,(filename_start)	; Use the .TAP filename
          ld    bc,8
          ldir
          ex    de,hl
          ld    (hl),'.'	; With a '.'
          inc   hl
          ld    a,(copied)	; And a suffix of the number of files copied
          add   a,48
          ld    (hl),a
          ld    de,(filename_start)	; Allows something to be displayed
          jr    cop260

cop295:   pop   hl   	    ;hl=flags2
          bit   3,(hl)	    ; If the destination is a drive
          call  nz,nsort	; Then convert filename in .TAP to +3 format
          ld    de,intafil+10 ; This allows it to be displayed nicely
          jr    cop260

; If we're not within a .TAP file, the file is on the normal directory
cop252:   call  disca0  	; Scan the DOS directory for matching filename
          jr    c,cop255  	; There was a match
cop213:   ld    hl,flags2  	
cop253:   bit   2,(hl)  	; Had we previously copied some files?
          jp    nz,copy6  	; Yes we had
          call  errorn  
          defb  34 	        ;no file  

cop255:   call  rdope1  	; Open the file on the DOS disc, on entry, hl
		                    ; points to the filename within the directory
          ld    hl,flags2  	; Check to see if destination is wild
          bit   3,(hl)  
          jr    z,cop266  	; It wasn't wild
          ld    hl,(filename_start) ; Since it was wild, copy the filename
          ld    de,pdname	; This include the '.'
          ex    de,hl
          ld    bc,12
          ldir
;Print the filenames
cop266:   ld    de,pdname  	; rdope1 fills this with the filename
cop260:   call  prdfin  
          call  prfiln 	    ; Print the +3 filename 
          ld    a,13  
          call  print  
          ld    hl,namep3  	; Open the +3 file for writing
          ld    de,259  
          ld    bc,2  
          ld    iy,262  	; DOS OPEN
          call  dodos  

cop267:   ld    hl,(rdflen) ; This is initialised by rdope1 
          ld    de,(rdflen+2)
          inc   e	        ; BUG
          ld    a,(flags2)	; Check to see if we're in a .TAP file
          bit   6,a
          jr    z,copy27
          ld    hl,(temphd+1)	; If we are, pick up the length of file within TAP
          ld    e,1
copy27:   push  hl	        ; BUG, once again this loop is broken
          push  de  
          call  rdbyte  	; Read the byte from the MSDOS disc
          ld    b,0  	    ; And write it to the +3 file
          ld    c,a  
          ld    iy,283  	; DOS WRITE BYTE
          call  dodos  
          pop   de
          pop   hl
          dec   hl
          ld    a,h
          or    l
          jr    nz,copy27
          dec   e
          jr    nz,copy27
          ld    hl,flags2	; If we're within a .TAP file, skip the checksum
          bit   6,(hl)
          call  nz,rdbyte 
          ld    a,(temphd)	; If the file is a long type, don't write header
          cp    5
          jr    nc,copy28
          ld    b,0  
          ld    iy,271  	; DOS REF HEAD
          call  dodos  
          push  ix  	    ; Copy our generated header over 
          pop   de  
          ld    hl,temphd  
          ld    bc,7  
          ldir  
          
copy28:   ld    b,0  	    ; Close the +3 file
          ld    iy,265  	; DOS CLOSE
          call  dodos  
          ld    hl,copied  	; Increment copied file count
          inc   (hl)  
nobas3:   ld    hl,flags2  	
          set   2,(hl)  	; Indicate that we've copied a file
          set   4,(hl)  
          bit   1,(hl)  	; Was source wild
          jp    nz,cop251  	; If so, then loop over
          jp    copy6  	    ; Print summary of files copied
          
          
 
          
; Print the DOS filename
; Entry:	de = filename
; Exit:	none
prdfin:   push  de  	    ; Save it
          ld    a,255  	    ; Hack it so we don't wait for a scroll? prompt
          ld    (23692),a  
          call  messag      ; Print a silly DOS drive name
          defm  "P*:" & 255
          pop   de  
          ld    bc,12	    ; Filename length is 12 characters
          ld    hl,flags2	; Unless we're within a .TAP file
          bit   6,(hl)
          jr    z,prdfin1
          ld    bc,10  	    ; And then its 10
prdfin1:  call  string  
          ld    a,6  	    ; Go to next "column"
          jp    print  

; Print the +3 filename
; Entry:	none
; Exit:	none
prfiln:   ld    a,255  	    ; Hack it so we don't wait for scroll? prompt
          ld    (23692),a  
          ld    bc,16  	    ; +3 filename is always 16 characters
          ld    de,namep3  
          jp    string  


