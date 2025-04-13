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

int compare_addr( const void *x, const void *y );

int main( int argc, char* argv[] )
{
	FILE *in, *out;
	char fname[256];
	int pos, end;
	int c, i, n;

	puts( "Help System Text Extractor Version 6.0" );
	puts( "Copyright (c) 2025 by GmEsoft. All rights reserved." );
	puts( "" );

	if ( argc < 2 )
	{
		puts( "USAGE: help2txt file[.HLP] [file[.TXT]]" );
		exit( 1 );
	}

	// Input file name, default ext = .HLP
	strcpy( fname, argv[1] );
	if ( !strchr( fname, '.' ) )
	{
		strcat( fname, ".HLP" );
	}

	in = fopen( fname, "rb" );
	if ( !in )
	{
		printf( "Help file %s can't be opened\n", fname );
		exit( 1 );
	}

	printf( "Input  help file: %s\n", fname );

	// Output file name, default = input name, default ext = .TXT
	strcpy( fname, argv[argc<3 ? 1 : 2] );

	if ( argc < 3 )
	{
		char *p = strchr( fname, '.' );
		if ( p )
			*p = 0;
	}

	if ( !strchr( fname, '.' ) )
	{
		strcat( fname, ".TXT" );
	}

	out = fopen( fname, "w" );
	if ( !out )
	{
		printf( "Text file %s can't be opened\n", fname );
		exit( 1 );
	}

	printf( "Output text file: %s\n", fname );

	puts( "" );
	puts( "Processing Help File" );

	// Read index
	fseek( in, 0, SEEK_END );
	pos = ftell( in );
	pos -= 2;
	end = pos;
	fseek( in, pos, SEEK_SET );
	pos = fgetc( in );
	pos += fgetc( in ) << 8;
	fseek( in, pos, SEEK_SET );
	n = 0;
	pos = 0;
	while ( ftell( in ) < end )
	{
		int len;

		i = 0;
		do
		{
			c = fgetc( in );
			index[n].name[i++] = c & 0x7F;
		} while ( !(c & 0x80 ) );

		index[n].name[i] = 0;
		index[n].addr = fgetc( in ) | ( fgetc( in ) << 8 );

		len = strlen( index[n].name );
		len = 20 * ( len / 20 ) + 20;
		if ( pos + len > 80 )
		{
			puts( "" );
			pos = 0;
		}
		printf( "%-*s", len, index[n].name );
		pos += len;

		++n;
	}

	if ( pos )
	{
		puts( "" );
	}

	// Sort index by address
	qsort( index, n, sizeof( index_t ), compare_addr );

	puts( "" );
	puts( "Writing text file" );

	// Uncompress help text
	for ( i = 0; i < n; ++i )
	{
		int lin = 1, col = 0, lastc = 0;
		fputs( index[i].name, out );
		fputc( '\r', out );

		if ( i+1 < n && index[i].addr == index[i+1].addr )
		{
			// More than one entry for the same help page
			fputc( 0x0C, out );
			continue;
		}

		fseek( in, index[i].addr, SEEK_SET );

		for (;;)
		{
			c = fgetc( in );
			if ( c & 0x80 )
			{
				// Space Compression code ?
				if ( lastc & 0x80 )
				{
					c -= 0x80;
					while ( c-- )
					{
						fputc( ' ', out );
					}
					c = 0;
				}
			}

			lastc = c;
			c &= 0x7F;

			if ( c == 0x0C )
			{
				// End of page
				fputc( 0x0C, out );
				break;
			}
			else if ( c == 0x0D )
			{
				// Carriage return
				fputc( '\r', out );
				++lin;
			}
			else if ( c == 0x7F )
			{
				// Invert or blink flag
				fputc( 0x7F, out );
			}
			else if ( c )
			{
				// Normal char
				fputc( c, out );
			}

			if ( lastc & 0x80 )
			{
				// Append space if bit 7 was set
				// and was not a space compression code
				fputc( ' ', out );
			}
		}
	}

	puts( "" );
	puts( "Processing concluded" );
}

// Compare addresses in index entries
int compare_addr( const void *x, const void *y )
{
	return ( (index_t*)x )->addr - ( (index_t*)y )->addr;
}
