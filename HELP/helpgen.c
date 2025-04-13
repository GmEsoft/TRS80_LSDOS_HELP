#include <stdio.h>
#include <io.h>
#include <ctype.h>
#include <stddef.h>
#include <string.h>

#include <fcntl.h>		// O_RDWR...
#include <sys/stat.h>	// S_IWRITE

typedef struct
{
	char name[80];
	int  addr;
} index_t;

index_t index[256];

char buf[256];

int compare_name( const void *x, const void *y );

int main( int argc, char* argv[] )
{
	FILE *in, *out;
	char fname[256];
	int n = 0, addr = 0, pos;

	puts( "Help System Text Processor Version 6.0" );
	puts( "Copyright (c) 2025 by GmEsoft. All rights reserved." );
	puts( "" );

	if ( argc < 2 )
	{
		puts( "USAGE: helpgen file[.TXT] [file[.HLP]]" );
		exit( 1 );
	}

	// Input file name, default ext = .TXT
	strcpy( fname, argv[1] );
	if ( !strchr( fname, '.' ) )
	{
		strcat( fname, ".TXT" );
	}

	in = fopen( fname, "r" );
	if ( !in )
	{
		printf( "Text file %s can't be opened\n", fname );
		exit( 1 );
	}

	printf( "Input  text file: %s\n", fname );

	// Output file name, default = input name, default ext = .HLP
	strcpy( fname, argv[argc<3 ? 1 : 2] );

	if ( argc < 3 )
	{
		char *p = strchr( fname, '.' );
		if ( p )
			*p = 0;
	}

	if ( !strchr( fname, '.' ) )
	{
		strcat( fname, ".HLP" );
	}

	out = fopen( fname, "wb" );
	if ( !out )
	{
		printf( "Help file %s can't be opened\n", fname );
		exit( 1 );
	}

	printf( "Output help file: %s\n", fname );

	puts( "" );
	puts( "Processing Source File" );

	while ( true )
	{
		int i = 0;
		int c, lastc = 0, comp = 0;

		// Get the file position of the text corresponding
		// to the next keyword
		addr = ftell( out );
		if ( addr > 0xFFFF )
		{
			puts( "Destination File Exceeds 65,535 characters" );
			exit( 1 );
		}
		index[n].addr = addr;

		// Get the keyword
		while ( !feof( in ) && ( c = fgetc( in ) ) != 0x0D )
		{
			index[n].name[i++] = c;
		}

		index[n].name[i] = 0;

		if ( c < 0 )
		{
			// Got end-of-file
			break;
		}

		if ( !i )
		{
			// Keyword is empty => abort
			printf( "Null Key Encountered - Prior Key was %s",
				n ? index[n-1].name : "NO PRIOR KEY" );
			exit( 1 );
		}

		++n;

		// Read and compress the help page corresponding
		// to the keyword
		while ( !feof( in ) && ( c = fgetc( in ) ) != 0x0C )
		{
			if ( c == 0x0A )
				continue;

			if ( !lastc || c != ' ' )
			{
				// A char is pending for output
				// or the current char is not a space
				if ( lastc )
				{
					// Write the pending char
					fputc( lastc, out );
					// If the pending char was a 'char+space'
					// => put the new char as is.
					if ( ( lastc & 0x80 ) || ( c == 0x7F ) )
					{
						fputc( c, out );
						lastc = 0;
						continue;
					}
				}
				// New char pending for output
				lastc = c;
			}
			else
			{
				// New char is a space and
				// last char was not compressed
				if ( lastc < 0x80 )
				{
					// Last char was not compressed
					// => make a 'char+space'
					lastc |= 0x80;
					comp = 0;
				}
				else if ( comp )
				{
					// We are in space compression mode
					// => count the space
					++lastc;
				}
				else
				{
					// Last char is a 'char+space'
					// => enter space compression mode
					fputc( lastc, out );
					lastc = 0x81;
					comp = 1;
				}
			}
		}

		// Write the last pending char of the help page if any
		if ( lastc )
		{
			fputc( lastc, out );
			lastc = 0;
			fputc( 0x0C, out );
		}
	}

	puts( "" );
	puts( "Sorting and filing keys" );

	// Sort the index on keywords
	qsort( index, n, sizeof( index_t ), compare_name );

	pos = 0;

	// Write the index
	for ( int i = 0; i < n; ++i )
	{
		int len = strlen( index[i].name );

		// Set high bit of last char of the keyword
		index[i].name[len-1] |= 0x80;

		// Write the keyword with the high bit of the last char set
		fwrite( index[i].name, 1, len, out );

		// Write the help page offset
		fputc( index[i].addr & 0xFF, out );
		fputc( index[i].addr >> 8, out );

		// Display the keyword
		index[i].name[len-1] &= 0x7F;
		len = 20 * ( len / 20 ) + 20;
		if ( pos + len > 80 )
		{
			puts( "" );
			pos = 0;
		}
		printf( "%-*s", len, index[i].name );
		pos += len;
	}

	// Write the index offset
	fputc( addr & 0xFF, out );
	fputc( addr >> 8, out );

	puts( "" );
	puts( "Processing concluded" );

}

int compare_name( const void *x, const void *y )
{
	return strcmp( ( (index_t*)x )->name, ( (index_t*)y )->name );
}
