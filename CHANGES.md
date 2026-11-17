# Changes in this fork

4OS2 is Copyright (c)1989-2002 J.P. Software, Inc.  http://jpsoft.com/
(see license.txt). This fork is derived from
https://github.com/StevenLevine/4os2 (commit 7e56d1c, "Always update build
level string"). As the license asks, the changes made here are listed
below with their dates.

## 2026-11-17

- `getline` is now `JpGetLine` (c/*.c, h/proto.h): Open Watcom v2's
  `stdio.h` declares POSIX `getline( char **, size_t *, FILE * )`, which
  clashed with 4OS2's own `getline` and stopped every file that includes
  `proto.h` from compiling. Only the name changed.
- `#include <STDARG.H>` is now `<stdarg.h>` (c/option2.c, c/wrappers.c),
  so the headers are found on case-sensitive file systems.
- `build.sh`: builds 4OS2.EXE, JPOS2DLL.DLL, KEYSTACK.EXE, SHRALIAS.EXE
  and OPTION2.EXE on Linux or macOS with Open Watcom v2 (what
  `master.mif` does on OS/2), writes the BLDLEVEL string that
  `make_buildlevel.cmd` makes, and compiles 4OS2.INF where Open Watcom
  has `wipfc`. Warnings are no longer errors (`-we` dropped): Open
  Watcom v2 warns about unused parameters that 1.x did not.
- `.github/workflows/build.yml`: builds on GitHub Actions (Open Watcom v2
  from `open-watcom/setup-watcom`), checks that the programs are LX
  modules, keeps them with the book, the license and the samples as an
  artifact, and publishes them as a release for `v*` tags.
