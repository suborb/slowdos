/*
 *  Create a single binary for Slowdos
 * 
 *   $Id: appmake.c,v 1.1 2003/06/15 22:04:44 dom Exp $
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static int parameter_search(char *name,char *target);

unsigned char  booter[512 + 6912];  /* Won't be longer than that */

int main(int argc, char *argv[])
{
    int  booter_len;
    int  binary_len;
    FILE *fp;

    int  runexe, synexe, sfail0, sfail1, sfail2;

    int  patch, patch2, patch3, patch4, patch5;

    fp = fopen("booter.bin","rb");
    booter_len = fread(booter,1,512,fp);
    fclose(fp);
    
    fp = fopen("commands.bin","rb");
    binary_len = fread(&booter[booter_len],1,6912,fp);
    fclose(fp);

    runexe = parameter_search("commands.map","RUNEXE"); runexe++;
    synexe = parameter_search("commands.map","SYNEXE"); synexe++;
    sfail0 = parameter_search("commands.map","SFAIL0"); sfail0++;
    sfail1 = parameter_search("commands.map","SFAIL1"); sfail1++;
    sfail2 = parameter_search("commands.map","SFAIL2"); sfail2++;

    patch  = parameter_search("booter.map","PATCH"); patch+=2;
    patch2  = parameter_search("booter.map","PATCH2"); patch2+=2;
    patch3  = parameter_search("booter.map","PATCH3"); patch3++;
    patch4  = parameter_search("booter.map","PATCH4"); patch4++;
    patch5  = parameter_search("booter.map","PATCH5"); patch5++;

    booter[patch - 32768] = runexe % 256;
    booter[patch+1 - 32768] = runexe / 256;

    booter[patch2 - 32768] = synexe % 256;
    booter[patch2+1 - 32768] = synexe / 256;

    booter[patch3 - 32768] = sfail0 % 256;
    booter[patch3+1 -32768 ] = sfail0 / 256;

    booter[patch4 - 32768] = sfail1 % 256;
    booter[patch4+1 - 32768] = sfail1 / 256; 

    booter[patch5 - 32768] = sfail2 % 256;
    booter[patch5+1 - 32768] = sfail2 / 256;

    fp = fopen("slowdos.bin","wb");
    fwrite(booter,1,binary_len + booter_len,fp);
    fclose(fp);
    exit(0);
}





/* Search through debris from z80asm for some important parameters */
static int parameter_search(char *name,char *target)
{
    char    buffer[512];
    long    val=-1;
    FILE    *fp;

  
    if ( (fp=fopen(name,"r"))==NULL) {
	exit(1);
    }
    
    /* Successfully opened the file so search through it.. */
    while ( fgets(buffer,512,fp) != NULL ) {
        if      (strncmp(buffer,target,strlen(target)) == 0 ) {
            sscanf(buffer,"%*s%*s%*[ $]%lx",&val);
            break;
        }
    }
    fclose(fp);
    return(val);
}



