#USE THIS SCRIPT TO COMPILE MODULE FILE
gcc -rdynamic -I $1 -shared "$2" -o "$3"
