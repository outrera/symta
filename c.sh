#USE THIS SCRIPT TO COMPILE MODULE FILE
CFLAGS="-rdynamic -I \"$1\""
gcc $CFLAGS -shared "$2" -o "$3"