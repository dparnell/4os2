#!/bin/sh
# Build 4OS2 on a Unix host (macOS or Linux) with Open Watcom v2.
#
#   sh build.sh [OUTDIR]
#
# WATCOM defaults to ~/opt/watcom (an Open Watcom v2 snapshot). The
# programs (4OS2.EXE, JPOS2DLL.DLL, KEYSTACK.EXE, SHRALIAS.EXE and
# OPTION2.EXE) go to OUTDIR (default: out/). This does what master.mif
# does on OS/2, without wmake or the REXX build-level script. The book,
# 4OS2.INF, is compiled from 4os2.ipf when Open Watcom has wipfc for
# this host (Linux, Windows; not the macOS snapshots). Open Watcom has no
# MKMSGF, so 4os2h.txt (the help message file, 4OS2H.MSG) is left for
# the caller to compile.
set -e
src=$(cd "$(dirname "$0")" && pwd)
out=${1:-$src/out}
: "${WATCOM:=$HOME/opt/watcom}"
[ -d "$WATCOM" ] || { echo "4os2: Open Watcom not found (set WATCOM)" >&2; exit 1; }
case "$(uname -s)-$(uname -m)" in
Darwin-arm64) host=armo64 ;;
Darwin-*) host=bino64 ;;
Linux-aarch64) host=arml64 ;;
*) host=binl64 ;;
esac
export WATCOM PATH="$WATCOM/$host:$PATH" INCLUDE="$WATCOM/h:$WATCOM/h/os2"
mkdir -p "$out/obj"
out=$(cd "$out" && pwd)
cd "$out/obj"

# The build level (BLDLEVEL), as make_buildlevel.cmd writes it, from
# h/version.h and h/build.h.
def() { sed -n "s/^#define $1 *\([^ /]*\).*/\1/p" "$src/h/$2" | head -1 | tr -d '"\r'; }
maj=$(sed -n 's/^#define VER_MAJOR *\([0-9]*\).*/\1/p' "$src/h/version.h" | tail -1)
min=$(sed -n 's/^#define VER_MINOR *\([0-9]*\).*/\1/p' "$src/h/version.h" | tail -1)
rev=$(sed -n 's/^#define VER_REVISION *"\([^"]*\)".*/\1/p' "$src/h/version.h" | tail -1)
bld=$(def VER_BUILD build.h)
stamp=$(date -u '+%Y-%m-%d %H:%M:%S')
: "${VENDOR:=AB}"
host_name=$(printf %.11s "${HOSTNAME:-$(uname -n)}")
printf "'@#%s:%s.%s%s#@##1## %-24s %-11s::::%s::@@  4os2 Command Shell Extension'\n" \
    "$VENDOR" "$maj" "$min" "$rev" "$stamp" "$host_name" "$bld" > buildlevel.txt

cflags="-zq -wx -ef -I$src/h -oaxt -bt=os2"
cc() { for f in "$@"; do wcc386 $cflags -fo="$f.obj" "$src/c/$f.c"; done; }
lnk() { name=$1; shift; printf '%s\n' "$@" > "$name.lnk"; wlink @"$name.lnk"; }

objs4="main parser os2init cmds expand eval ea dircmds filecmds syscmds os2cmds
    os2calls misc env batch screenio msg error window listall lines kparse
    iofmt32 select os2tty istring iparse dbcs wrappers"
cc $objs4 option2 os2cfg os2nb jpos2dll shralias keystack
for f in bcd32 os32util; do wasm -zq -fo="$f.obj" "$src/a/$f.asm"; done

# 4OS2.EXE, with the DOS stub that starts it from a DOS session.
wcl -zq -bt=dos -fe=vdm2os2.exe "$src/c/vdm2os2.c" >/dev/null
sed "s#\.\./4os2.ico#$src/4os2.ico#" "$src/4os2.rc" > 4os2.rc
wrc -q -r -zm -bt=os2 -fo=4os2.res 4os2.rc
lnk 4os2 "name 4os2" "system os2v2" "option map" "option quiet" \
    "option description @buildlevel.txt" "option stub=vdm2os2.exe" \
    "library $WATCOM/lib286/os2/os2" "file { $(echo $objs4 bcd32 os32util | sed 's/\([a-z0-9]*\)/\1.obj/g') }"
wrc -q 4os2.res 4os2.exe

lnk jpos2dll "name jpos2dll.dll" "system os2v2 dll initglobal" "option quiet" \
    "option description @buildlevel.txt" "option manyautodata" "segment type DATA shared" \
    "library clib3r, os2386" \
    "export QueryExtLIBPATH.1, SetExtLIBPATH.2, SendKeys.3, QuitSendKeys.4" \
    "export StartHook.5, PauseKeys.6, KeystackHookProc.7" "file jpos2dll.obj"
lnk keystack "name keystack" "system os2v2" "option quiet" "option description @buildlevel.txt" "file keystack.obj"
lnk shralias "name shralias" "system os2v2" "option quiet" "option description @buildlevel.txt" "file shralias.obj"

# OPTION2.EXE, the settings notebook.
sed -e 's#\.\.[\\/]option2\.dlg#option2.dlg#' -e "s#\.\.[\\\\/]4os2\.ico#$src/4os2.ico#" "$src/option2.rc" > option2.rc
tr -d '\r' < "$src/option2.dlg" > option2.dlg
wrc -q -r -zm -bt=os2 -I="$src/h" -I="$src" -fo=option2.res option2.rc
lnk option2 "name option2" "system os2v2_pm" "option quiet" "option description @buildlevel.txt" \
    "file option2.obj, os2cfg.obj, os2nb.obj, istring.obj"
wrc -q option2.res option2.exe

for f in 4os2.exe jpos2dll.dll keystack.exe shralias.exe option2.exe; do
    cp "$f" "$out/$(echo "$f" | tr a-z A-Z)"
done

# 4OS2.INF, the book that HELP opens.
if command -v wipfc >/dev/null 2>&1; then
    WIPFC="$WATCOM/wipfc" wipfc -q -i -l en_US "$src/4os2.ipf" -o "$out/4OS2.INF"
fi
