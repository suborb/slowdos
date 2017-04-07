;
;       Slowdos Source Code
;
;
;       $Id: fat.asm,v 1.1 2003/06/15 20:26:25 dom Exp $
;       $Author: dom $
;       $Date: 2003/06/15 20:26:25 $
;
;	Routines regarding the FAT table



		MODULE	fat

		INCLUDE	"slowdos.def"

		PUBLIC	rdnxft
		PUBLIC	wrnxft
		PUBLIC	link_clusters
		PUBLIC	getsec


;Find next FAT when reading
;Entry: de=current FAT
;Exit:  de=next FAT
;        c=illegal FAT
          
rdnxft:   ld    bc,fattab  
          ld    h,d  
          ld    l,e  
          add   hl,hl  
          add   hl,de  
          srl   h  
          rr    l  
          jr    c,rdnxf1 ;is nibble  
          add   hl,bc  
          ld    e,(hl)  
          inc   hl  
          ld    a,(hl)  
          and   15  
          ld    d,a  
          jr    rdnxf3  
rdnxf1:   add   hl,bc  
          ld    e,(hl)  
          inc   hl  
          ld    d,(hl)  
          ld    b,4  
rdnxf2:   srl   d  
          rr    e  
          djnz  rdnxf2  
rdnxf3:   ld    hl,0F00h ; Compare to endmarker
          and   a  
          sbc   hl,de  
          ret

;Find a free cluster (writing!!)
;Exit:    de=cluster
;          z=got a cluster
;         nz=no more clusters
          
wrnxft:   ld    de,0	    ; Cluster number
          ld    bc,713	    ; FIXME: Number of clusters in total
          ld    hl,fattab	; Start of the FAT table
wrnxf1:   ld    a,(hl)	    ; Byte aligned clusters
          inc   hl	        ; Increment to bits 3 - 0
          and   a	        ; If low byte is non zero try nibble aligned
          jr    nz,wrnxf2
          ld    a,(hl)	    ; Now high 4 bits
          and   15
          ret   z	        ; Was zero, thus cluster is available
;On a half in FAT table
wrnxf2:   inc   de
          ld    a,(hl)	    ; Test bits 0 - 4 of nibble aligned cluster
          inc   hl	        ; Increment bits 8 -11 of nibble aligned
          and   240	        ; Test bits 0 - 4
          jr    nz,wrnxf3	; In use
          ld    a,(hl)	    ; Test bits 8 -11
          and   a
          ret   z	        ; Was zero, cluster available
wrnxf3:   inc   hl
          inc   de	        ; Increment cluster number
          dec   bc	        ; Decrement number of clusters available
          ld    a,b
          or    c    
          jr    nz,wrnxf1
          inc   a	        ; No clusters available, returns nz
          ret

;Mark a FAT in the table as being used
;Entry:   de=current cluster
;         bc=next cluster
;Exit:    de=corrupt

link_clusters:	
	  ld    h,d	        ; hl = current cluster
          ld    l,e
          add   hl,hl       ;x2
          add   hl,de	    ;x3
          srl   h	        ;/2
          rr    l
          ld    de,fattab
          jr    c,locim1    ; if carry then cluster position starts on nibble
          add   hl,de	    ; Add in the start of the FAT table
          ld    (hl),c	    ; Place low byte
          inc   hl
          ld     a,(hl)	    ; Mask out high nibble and place it
          and   240
          or    b
          ld    (hl),a
          ret
locim1:   add   hl,de	    ; Add in to start of FAT table
          ld    a,4	        ; Shift left the cluster link to place
locim2:   sla   c
          rl    b
          dec   a
          jr    nz,locim2
          ld    a,(hl)	    ; And then store it
          and   15
          or    c
          ld    (hl),a
          inc   hl
          ld    (hl),b
          ret


;Get sector number from cluster
;Entry: de=cluster
;Exit:  de=MSDOS sector
          
getsec:   dec   de  		; First valid cluster is 2
          dec   de  
          ld    hl,(diskif+13) 	; Sectors per cluster
          ld    h,0  
          call  rhlxde  	; Bad, bad, should call through rom3
          ld    de,(rotsta) ; Start of root directory
          add   hl,de  
          ld    de,(rotlen) ; Length of root directory
          add   hl,de  
          ex    de,hl  
          ret   
          