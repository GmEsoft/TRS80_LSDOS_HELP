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
directly extracted from Rodnay Zaks's book *How to Program the Z-80*, p. 139. The original 
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


Space Compression Format
------------------------

In the generated /HLP file, the spaces from the source file are generally compressed.
The space compression rules are:
- Any non-blank char in the input file must be of ASCII code between 0x01 and 0x7F.
  All chars above 0x7F are changed to a white space char.
- If a space follows a non-blank character, this non-blank character will have its
  high bit set to 1. This new char will be referred as a "char+space" code. The non-blank
  char can be any displayable char, a "reverse video" or "blink" marker (0x7F) 
  or a new-line (0x0D).
- A "char+space" code can never follow another "char+space" code. The candidate char
  and the following space will be encoded as they are.
- If one or more spaces follow the first space following a non-blank char, they will
  be encoded into a "space-compression" char with an ASCII code between 0x81 and 0xFF.
  Those "space-compression" chars must always follow a "char+space" code.
  
### Example

In this example the 'char+space' codes will be shown as `{'char'+0x80}` and the
space compression codes as values `{0x80+n}` where `n` is the number of compressed spaces.

- Input: `Inv       Makes a visible file invisible`
- Output: `In{'v'+0x80}{0x80+6}Make{'s'+0x80}a visibl{'e'+0x80}fil{'e'+0x80}invisible`

```
0000000210: __ __ __ __ __ __ __ __ | __ __ 49 6E F6 86 4D 61  __________In~~Ma
0000000220: 6B 65 F3 61 20 76 69 73 | 69 62 6C E5 66 69 6C E5  ke~a visibl~fil~
0000000230: 69 6E 76 69 73 69 62 6C | 65 __ __ __ __ __ __ __  invisible_______
```

We can observe that:
- The first space following `Inv` is combined with the character `v` preceding it: `0xF6`.
- The 6 following spaces are encoded into a 'space compression' code `0x86`.
- The first space following `Makes` is combined with the character `s` preceding it: `0xF3`.
- The sequence `a ` following the 'char+space' `{'s'+0x80}` is not compressed because
  it would be interpreted by a 'space-compression' char.


Credits
-------

Gratitude goes to:
- **Tim Mann** for making TRS-80 resources available to the community;
- **George Phillips** for the ZMAC Z-80 Macro Assembler;
- **Pete Cervasio** for the original LS-DOS 6.3.1 complete build system;
- **Rodnay Zaks** for his outstanding book *How to program the Z-80* (Radio Shack
  edition Cat. No. 62-2066) and the fascinating non-restoring division
  routine.

Many thanks to all of them !
