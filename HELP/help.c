#include <stdio.h>
#include <io.h>
#include <ctype.h>
#include <stddef.h>
#include <string.h>

#include <fcntl.h>		// O_RDWR...
#include <sys/stat.h>	// S_IWRITE

#ifdef _WIN32
#include <windows.h>
#endif

typedef struct
{
	char name[80];
	int  addr;
} index_t;

index_t index[256];

char buf[256];

int input();

void hline();

void reverse();
void normal();
void getcolor();

int main( int argc, char* argv[] )
{
	FILE *in;
	char fname[256];

	if ( argc < 2 )
	{
		puts( "USAGE: help file[.hlp] [keyword]" );
		exit( 1 );
	}

	strcpy( fname, argv[1] );
	if ( !strchr( fname, '.' ) )
	{
		strcat( fname, ".HLP" );
	}

	in = fopen( fname, "rb" );
	if ( !in )
	{
		printf( "Help file %s can't be opened\n", argv[1] );
		exit( 1 );
	}

	int pos, end;
	int c, i, n;
	fseek( in, 0, SEEK_END );
	pos = ftell( in );
	pos -= 2;
	end = pos;
	fseek( in, pos, SEEK_SET );
	pos = fgetc( in );
	pos += fgetc( in ) << 8;
	fseek( in, pos, SEEK_SET );
	n = 0;
	while ( ftell( in ) < end )
	{
		i = 0;
		do
		{
			c = fgetc( in );
			index[n].name[i++] = c & 0x7F;
		} while ( !(c & 0x80 ) );
		index[n].name[i] = 0;
		index[n].addr = fgetc( in ) | ( fgetc( in ) << 8 );
		++n;
	}

	*buf = 0;
	if ( argc >= 3 )
	{
		strcpy( buf, argv[2] );
		for ( i = 3; i < argc; ++i )
		{
			strcat( buf, " " );
			strcat( buf, argv[i] );
		}
	}

	getcolor();

	while ( 1 )
	{
		normal();

		if ( *buf )
		{
			for ( i=0; i<n; ++i )
			{
				if ( !strcmpi( index[i].name, buf ) )
				{
					int lin = 1, col = 0, lastc = 0;

					hline();
					puts( index[i].name );
					fseek( in, index[i].addr, SEEK_SET );
					for (;;)
					{
						c = fgetc( in );
						if ( c & 0x80 )
						{
							if ( lastc & 0x80 )
							{
								c -= 0x80;
								while ( c-- )
								{
									putchar( ' ' );
								}
								c = 0;
							}
						}

						lastc = c;
						c &= 0x7F;

						if ( c == 0x0C )
						{
							break;
						}
						else if ( c == 0x0D )
						{
							if ( lin == 23 )
							{
								getch();
								lin = 0;
								puts( "" );
								hline();
							}
							else
							{
								puts( "" );
								++lin;
							}
						}
						else if ( c == 0x7F )
						{
							// toggle inverse video
							reverse();
						}
						else if ( c )
						{
							putchar( c );
						}

						if ( lastc & 0x80 )
						{
							putchar( ' ' );
						}
					}
					input();
					break;
				}
			}

			if ( i == n )
				*buf = 0;
		}
		else
		{
			int lin = 4;
			int col = 0;

			hline();
			puts( "HELP System - 6.3.1 - Copyright (c) 2025 by GmEsoft." );
			puts( "All Rights Reserved. Unauthorized duplication is prohibited." );
			puts( "" );
			printf( "Directory for HELP file: %s\n", argv[1] );
			for ( i = 0; i < n; ++i )
			{
				int len = strlen( index[i].name );
				len = 20 * ( len / 20 ) + 20;
				if ( col + len > 80 )
				{
					puts( "" );
					col = 0;
					++lin;
					if ( lin == 23 )
					{
						lin = 0;
						if ( input() )
							break;
						hline();
					}
				}
				printf( "%-*s", len, index[i].name );
				col += len;
			}
			if ( col > 0 )
				puts( "" );
			if ( !*buf )
				input();
		}
	}
}

int input()
{
	printf( "Enter keyword or press <Ctl-C> to exit: " );
	if ( gets_s( buf, sizeof buf ) )
	{
		return strlen( buf );
	}
	return 0;
}

void hline()
{
	for ( int i=0; i<80; ++i )
		putchar( '_' );
	puts( "" );
}

#ifdef _WIN32

int oldcolor, color;

void getcolor()
{
	HANDLE hConsole = GetStdHandle( STD_OUTPUT_HANDLE );
	CONSOLE_SCREEN_BUFFER_INFO csbi;
	if ( GetConsoleScreenBufferInfo( hConsole, &csbi ) )
	{
		color = oldcolor = csbi.wAttributes;
	}
}

void normal()
{
	HANDLE hConsole = GetStdHandle( STD_OUTPUT_HANDLE );
    SetConsoleTextAttribute( hConsole, color = oldcolor );
}

void reverse()
{
	HANDLE hConsole = GetStdHandle( STD_OUTPUT_HANDLE );
	color <<= 4;
	color |= color >> 8;
	color &= 0xFF;
	SetConsoleTextAttribute( hConsole, color );
}

#else

void getcolor()
{
}

void normal()
{
}

void reverse()
{
}

#endif
