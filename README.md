TRS80_LSDOS_HELP
================

LS-DOS Help File Extractor and Generator


Description
-----------

This repository contains the C source code for three tools designed to manipulate 
LS-DOS 6 /HLP files:
- `help.c`: Displays /HLP files on the PC Windows console, mimicking the original
  LS-DOS HELP/CMD, including reverse video characters;
- `help2txt.c`: Extracts /TXT files from /HLP files in a format compatible with 
  HELPGEN/CMD (found in the 'MARK IV' tools collection by Misosys);
- `helpgen.c`: A C-based attempt to re-implement the original Misosys tool 
  'HELPGEN/CMD', used to create /HLP files from source text files.

The original `HELPGEN/CMD` is available on 
[Tim Mann's web site](https://www.tim-mann.org/misosys.html#down) 
[here](https://www.tim-mann.org/trs80/mark4.zip). Its documentation can be found
[here](https://www.tim-mann.org/trs80/doc/ldoshelp.pdf).

The compressed /HLP format was reverse-engineered by analyzing the source code 
of the HELP command also [available](https://www.tim-mann.org/trs80/doc/l631srci.zip) 
on Tim Mann's site.

Additionally, I disassembled the original HELPGEN/CMD to better understand its 
functionality. This analysis revealed an intriguing implementation of a 
'non-restoring' 16-by-15-bit division routine, which I later discovered was 
directly extracted from Rodnay Zaks's book *How to Program the Z-80*. The original 
source code comments from the book are included in `HELPGEN.ASM`.

This repository also features updated versions of:
- The DOS Help file for Model 4 LS-DOS 6.3.1L with fixes to the `COPY` command 
  (previously altering some characters), and the `DATE` command (extending the years 
  range to 2079);
- The DOS Help file for Model II LS-DOS 6.3.1L and above, with the same `DATE` command
  modification.

That's it.  Enjoy !

Best regards,

Michel Bernard (michel_bernard at icloud.com)


Credits
-------

Gratitude goes to:
- **Tim Mann** for making TRS-80 resources available to the community;
- **George Phillips** for the ZMAC Z-80 Macro Assembler;
- **Pete Cervasio** for the original LS-DOS 6.3.1 complete build system;
- **Rodnay Zaks** for his outstanding book `How to program the Z-80` (Radio Shack
  edition Cat. No. 62-2066) and the fascinating non-restoring division
  routine.

Many thanks to all of them !
