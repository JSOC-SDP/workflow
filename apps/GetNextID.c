#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

/* GetNextID - returns the next serial number for given file
 *  
 * Uses flock on a file that contains the previous
 * ID.  Locks the file, reads prev number, writes next number, removes lock.
 * returns a single line on stdout containing the incremented number.
 * Format is <fixed part>-<date>-<sequence number>.
 *
 * To call with a new file and/or new fixed-part call with 2 args, <filename> <fixed_part>
 * To simply update an existing ID number part of an existing ID file, call with just <filename>
 */

void static getlock(FILE *fp, char *fname)
  {
  int sleeps;
  for(sleeps=0; lockf(fileno(fp),F_TLOCK,0); sleeps++)
    {
    if (sleeps >= 20)
      {
      fprintf(stderr,"Lock stuck on %s, GetNextID failed.\n", fname);
      exit(1);
      }
    sleep(1);
    }
  return;
  }

int main(int argc, char **argv)
{
char fname[1024];
int NextIDsn;
int nread;
int old_date, new_date;
int year, month, day;
char fixedpart[100];
char NextID[100];
FILE *fp;
struct tm *now;
time_t nowtime;

if (argc < 2)
  {
  fprintf(stderr, "GetNextID failed, needs filename.\n");
  exit(1);
  }
strncpy(fname, argv[1], 1000);

if (argc == 3)
  {
  strcpy(fixedpart, argv[2]);
  NextIDsn = 0;
  old_date = 0;
  fp = fopen(fname, "w");
  getlock(fp, fname);
  }
else
  {
  fp = fopen(fname, "r+");
  if (!fp)
    {
    fprintf(stderr, "GetNextID failed to open sn file, %s.\n", fname);
    exit(1);
    }
  getlock(fp, fname);

  nread = fscanf(fp,"%[^-]-%d-%d",fixedpart,&old_date,&NextIDsn);
  if (nread != 3)
    {
    fprintf(stderr,"GetNextID failed. found %d instead of 3 fields in %s\n", nread, fname);
    exit(1);
    }
  }

nowtime = time(0);
now = gmtime(&nowtime);
new_date = 10000*(now->tm_year+1900) + 100*(now->tm_mon+1) + now->tm_mday;
if (old_date != new_date)
  {
  FILE *history;
  strcat(fname, ".history");
  history = fopen(fname, "a");
  fprintf(history,"%s-%d-%05d\n", fixedpart, old_date, NextIDsn);
  fclose(history);
  NextIDsn = 1;
  }
else
  NextIDsn += 1;
rewind(fp);
sprintf(NextID,"%s-%d-%05d", fixedpart, new_date, NextIDsn);

fprintf(fp,"%s\n",NextID);
rewind(fp);
lockf(fileno(fp),F_ULOCK,0);
fclose(fp);
printf("%s\n",NextID);
}
