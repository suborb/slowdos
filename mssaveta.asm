;Save command for Slowdos -
;cobbled together out of DiSCDOS
;and old version of slowdos
;15/12/97 - yes..sub dirs do work!!! Hurrah!!!!!
;20/2/98  - added in save to .TAP - works - hurrah!!!



; Open a file to be write
; Entry: ix=ufia
wropen:   call  uftofin	; Copy ufia to filen, exit hl = ufia+2
          call  ckchar	; Check filename and uppercase it
          jp    c,bfnerr	; Filename was bad
          ld    hl,flags3	
          bit   1,(hl)	; Writing to a .TAP file?
          jp    nz,wropetap	; If so, then go there
          call  discan	; Scan for the file on disc
          ld    hl,(dirsec)	; Save sector containing first free dir entry
          ld    (wrdsec),hl
          jr    nc,wrope1  	; If filename doesn't exist then dont error
          call  errorn
          db    48 	;file already exists
wrope1:   ld    a,(frepos)  	; Get the free directory slot
          and   a  
          jr    nz,wrope2  	; We have a free slot
          call  cksub	; Check to see if we're in subdirectory
          jr    z,nodiren	; We're not in subdir, so we need to error
; We're in a subdirectory, try to allocate more space
          call  seccle	; Clear the write sector
          call  wrnxft	; Find a free cluster, de = new cluster
          jp    nz,dfull	; No free cluster so error
          ld    c,e	; Move new cluster into bc
          ld    b,d
          ld    de,(curfat)	; Pick up the last cluster of the subdirectory
		; we have access to this since we searched the
		; directory for the filename
          push  bc  	; Save new cluster
          call  locimp	; Link the two clusters together
          pop   de	; Get new cluster back
          ld    bc,0FFFh	; Set next cluster to be "end of chain"
          push  de	; Save new cluster
          call  locimp	; Terminate the cluster chain
          pop   de	; Get new cluster back
          call  getsec	; Convert to DOS sector number
          ld    (wrdsec),de	; Save it for later
          push  de	; 
          call  swos	; Write a blank directory sector
          pop   de	
          inc   de	; BUG!! Go to next sector in cluster 
          call  swos	; Write the second sector of the cluster
          ld    a,1
          jr    wrope2
nodiren:  call  errorn  	; No space left in diretory
          db    51  
;a=file number
;Clear the directory setup
; Entry:	a = free directory slot
wrope2:   ld    (wrdpos),a   	; Save the directory slot
          xor   a	; Blank out our temporary directory entry
          ld    b,32
          ld    hl,dirmse
wrope3:   ld    (hl),a
          inc   hl
          djnz  wrope3
          call  seccle	; Clear the write sector
          push  ix  	; ix = ufia
          pop   hl  	; Copy the filename to our directory entry
          inc   hl
          inc   hl
          ld    de,dirmse
          ld    bc,8  
          ldir  
          inc   hl	; Now copy extension and file type
          ld    c,4	; We know that b = 0
          ldir
          call  wnfse5	; Set (wrsepo),wrisec; (wrtogo),512
          ld    a,(diskif+13)	; Number of sectors per cluster
          ld    (wrclco),a	; And save it
          ld    hl,flags
          bit   5,(hl)	; Check to see if we want a header or not
          jr    nz,wrope5	; If we don't skip over header writing
          ld    hl,signat	; Copy over the +3DOS file header
          ld    de,wrisec
          ld    bc,11
          ldir
          ld    l,(ix+16)	; Pick up file length
          ld    h,(ix+17)
          ld    c,128	; We know b = 0
          and   a
          adc   hl,bc
          ex    af,af'	; Save overflow flag
          ex    de,hl	; de = file length, hl = where to write filelength
          ld    (hl),e	; Write file length into
          inc   hl
          ld    (hl),d
          inc   hl
          ex    de,hl	; de = where to write
          ld    hl,0
          ld    c,0  ;	; We know b = 0
          ex    af,af'	; Get overflow back
          adc   hl,bc	; Add in the overflow
          ex    de,hl	; de = top word of file length, hl = write place
          ld    (hl),e
          inc   hl
          ld    (hl),d
          inc   hl
          ex    de,hl
          push  ix	; ix = ufia
          pop   hl
          ld    c,15	; We know b = 0. Move to fileinfo section of ufia
          add   hl,bc
          ld    c,7  	; We know b = 0
          ldir		; Copy the file header into the sector
          ld    hl,wrisec	; Now calculate the header checksum
          ld    b,127
          xor   a
wrope4:   add   a,(hl)
          inc   hl
          djnz  wrope4
          ld    (hl),a	; And write it
          inc   hl
          ld    (wrsepo),hl	; Save first writing position
          ld    hl,384	; And how much length is still available
          ld    (wrtogo),hl
wrope5:   ld    hl,(wrsepo)	; Set up the file length byte counter
          ld    de,wrisec	; See how much we've written so far
          and   a
          sbc   hl,de
          ld    (wrflen),hl	; And save it
          ld    hl,0
          ld    (wrflen+2),hl
          call  wrnxft	; Try to get a free cluster
          jr    z,wrope6	; We succeeded
dfull:    call  errorn
          db    50 ; Disc full
wrope6:   ld    (dirmse+26),de ; Save the first cluster into the directory entry
          ld    (wrclus),de	; Set up the current cluster
          call  getsec	; Convert to DOS sector
          ld    (wrclse),de	; And save that too
          ret   

; We're writing to a .TAP file. The .TAP file is already open
; Entry:	ix = ufia
wropetap: push  ix	; Stack the ufia
          call  mslog	; Ensure that this is a MSDOS disc
          pop   ix	; Get the ufia back
          ld    hl,19 	; Length of header
          call  wropeta9	; Write word to file
          ld    h,0	; .TAP filetype
          call  wropeta8  	; Write byte and set parity
          ld    a,(ix+15)
          call  wrbyte	; Write a byte to disc
          ld    hl,intafil	; A temporary buffer
          ld    b,20	; Length of buffer
          call  clfil0	; Clear it, returns hl = intafil
          push  hl
          call  pdconv   	; Convert filename in ufia and place in intafil
          pop   hl  	;hl=intafil
          ld    b,10	; Length of filename
          call  wropeta7	; Write filename to disc
          push  ix   	; Get ufia into hl
          pop   hl
          ld    bc,16	; Step to header information
          add   hl,bc
          ld    b,6	; Header to write is 6 bytes long
          call  wropeta7	; And so write this to disc
          ld    a,(parity+1)	; Get the parity byte
          call  wrbyte	; And write it to disc
          ld    l,(ix+16)	; Get file length
          ld    h,(ix+17)
          inc   hl	; Cover for parity
          inc   hl	; Cover for .TAP filetype
          call  wropeta9	; Write word
          ld    h,255	; .TAP filetype
          jp    wropeta8  	; Write filetype and initialise parity

; Write a stream of bytes to disc
; Entry:	hl = buffer
;	 b = number of bytes to write
wropeta7: ld    a,(hl)
          call  wrbyte
          inc   hl
          djnz  wropeta7
          ret

; Write the .TAP filetype out. also initialises parity
; Entry:	h = .TAP filetype
wropeta8: xor   a
          ld    (parity+1),a
          ld    a,h
          jp    wrbyte

; Write a 16 bit number to disc
; Entry:	hl = 16 bit number
wropeta9: ld    a,l
          call  wrbyte
          ld    a,h
          jp    wrbyte

;Write a string of bytes
;Entry: de=addr
;       bc=length
wrblok:   call  wrinit  	; Copy the write code to somewhere in printer buf
wrblo1:   ld    a,b  	; Check for number of bytes left
          or    c  
          ret   z  	; We're done
          call  wrcopy  	; Pick up the byte
          call  wrbyte  	; Write it to DOS
          inc   de  
          dec   bc  
          jr    wrblo1  
          
;Changing these routines to reference the read ones...

; Copy the code snippet for picking up values from BASIC memory
; to 23420
wrinit:   ld    hl,wrcopr  	; The routine we use
          jp    rdini1	; Copy it
          
wrcopr:   out   (c),l  
          ld    a,(de)  
          out   (c),h  
          jp    rdcop1
          
;Write a byte to the file
;Entry: a=byte
wrbyte:   push  de  	; Save registers that we use
          push  bc  
          push  hl  
          push  af  	; Save the byte we want to write
          ld    hl,(wrtogo)  	; Bytes left in the sector
          ld    a,h  
          or    l  
          call  z,wnfsec	; Get the next sector
wrbyt1:   pop   af  	; Get the byte back
          ld    hl,(wrsepo)   ; Position within sector
          ld    (hl),a  	; Store the byte
          inc   hl  	; Increment sector position
          ld    (wrsepo),hl  
          ld    hl,(wrtogo)   ; Decrement amount of space left in sector
          dec   hl  
          ld    (wrtogo),hl  
          ld    h,a	; Update the parity
parity:   ld    a,0
          xor   h
          ld    (parity+1),a
          ld    hl,(wrflen)	; Increment the file length
          inc   hl
          ld    (wrflen),hl
          ld    a,h	; Check for overflow
          or    l
          jr    nz,wrbyt2
          ld    hl,(wrflen+2)	; If overflowed increment high word
          inc   hl
          ld    (wrflen+2),hl
wrbyt2:   pop   hl  	; Restore registers
          pop   bc  
          pop   de  
          ret   


;Find the next file sector (writing)
wnfsec:   ld    hl,wrclco 	; Decrement number of sectors in cluster
          dec   (hl)
          jr    z,wnfse2	; Jump if we reached the end of the cluster
wnfse1:   ld    de,(wrclse)	; Pick up the current sector
          push  de	; Stack it
          call  swos	; Write sector to disc
          pop   de	; Get sector back
          inc   de	; Increment sector number
wnfse6:   ld    (wrclse),de	; Save it
wnfse5:   ld    hl,wrisec	; Set up writing variables
          ld    (wrsepo),hl
          ld    hl,512
          ld    (wrtogo),hl
          ret
; Completed our cluster, get a new one
wnfse2:   ld    de,(wrclse)	; Write out the current sector
          call  swos
          ld    de,(wrclus)	; Pick up the current cluster
          ld    bc,1	; A fake cluster
          push  de	; Save current cluster
          call  locimp	; Fake lock so we don't get the same cluster again
          call  wrnxft	; Get a new cluster
          jp    nz,dfull	; No new cluster, disc full
wnfse3:   ld    (wrclus),de	; Save the new cluster
          ld    c,e	; Get new cluster into de
          ld    b,d
          pop   de	; Get back the old cluster
          push  bc	; Stack the new cluster
          call  locimp	; Link the two together
          pop   de	; Get back the new cluster
          call  getsec	; Convert to DOS sector
          ld    a,(diskif+13) ; Number of sectors in cluster
          ld    (wrclco),a	; Save them
          jr    wnfse6	; Set up sector number and writing variables


          
;Close a file being written to the DOS disc
wrclos:   ld    hl,flags3
          bit   1,(hl)	; Check for writing to a .TAP file
          jr    z,wrclos0	; Not writing to .TAP file
          ld    a,(parity+1)  ; Pick up the parity byte
          call  wrbyte	; And write it to disc
          jp    wrifat	; Save the FAT to disc (not too sure why!)

wrclos0:  ld    bc,0FFFh	; End of cluster chain marker
          ld    de,(wrclus)	; Current cluster
          call  locimp	; Link together
          ld    de,(wrclse)	; Pick up last cluster
          call  swos	; And write it to disc
          ld    de,(wrdsec)	; Get directory cluster
          call  sros	; Read it in
          ld    hl,sector  	; Copy the directory from read to write memory
          ld    de,wrisec  
          ld    bc,512  
          ldir  
          ld    hl,(wrflen)	; Update dir entry with the real file length
          ld    (dirmse+28),hl
          ld    hl,(wrflen+2)
          ld    (dirmse+30),hl
          ld    a,(wrdpos)	; Pick up free directory entry indicator
          dec   a	; Decrement it
          call  locate	; And pick up offset
          ld    de,wrisec	; Add to start of sector
          add   hl,de
          ld    de,dirmse	; Copy our directory entry into the dir sector
          ex    de,hl
          ld    bc,32
          ldir
          ld    de,(wrdsec)  	; And write directory sector to disc
          call  swos  
          jp    wrifat	; Write the updated FAT table to disc
          
          
;Find a free cluster (writing!!)
;Exit:    de=cluster
;          z=got a cluster
;         nz=no more clusters
          
wrnxft:   ld    de,0	; Cluster number
          ld    bc,713	; FIXME: Number of clusters in total
          ld    hl,fattab	; Start of the FAT table
wrnxf1:   ld    a,(hl)	; Byte aligned clusters
          inc   hl	; Increment to bits 3 - 0
          and   a	; If low byte is non zero try nibble aligned
          jr    nz,wrnxf2
          ld    a,(hl)	; Now high 4 bits
          and   15
          ret   z	; Was zero, thus cluster is available
;On a half in FAT table
wrnxf2:   inc   de
          ld    a,(hl)	; Test bits 0 - 4 of nibble aligned cluster
          inc   hl	; Increment bits 8 -11 of nibble aligned
          and   240	; Test bits 0 - 4
          jr    nz,wrnxf3	; In use
          ld    a,(hl)	; Test bits 8 -11
          and   a
          ret   z	; Was zero, cluster available
wrnxf3:   inc   hl	; 
          inc   de	; Increment cluster number
          dec   bc	; Decrement number of clusters available
          ld    a,b
          or    c    
          jr    nz,wrnxf1
          inc   a	; No clusters available, returns nz
          ret

;Mark a FAT in the table as being used
;Entry:   de=current cluster
;         bc=next cluster
;Exit:    de=corrupt

locimp:   ld    h,d	; hl = current cluster
          ld    l,e
          add   hl,hl	;x2
          add   hl,de	;x3
          srl   h	;/2
          rr    l
          ld    de,fattab
          jr    c,locim1  	; if carry then cluster position starts on nibble
          add   hl,de	; Add in the start of the FAT table
          ld    (hl),c	; Place low byte
          inc   hl
          ld     a,(hl)	; Mask out high nibble and place it
          and   240
          or    b
          ld    (hl),a
          ret
locim1:   add   hl,de	; Add in to start of FAT table
          ld    a,4	; Shift left the cluster link to place
locim2:   sla   c
          rl    b
          dec   a
          jr    nz,locim2
          ld    a,(hl)	; And then store it
          and   15
          or    c
          ld    (hl),a
          inc   hl
          ld    (hl),b
          ret
