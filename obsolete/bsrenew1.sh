#Windows version, used to start SBCL from MINGW64/git bash
# renew bootstrap/c files

mkdir -p bootstrap/c
mkdir -p build
rm -rf ./build/symta
cp -R ./pkg/symta ./build
mkdir -p build/symta/lib

cp src/*.s build/symta/src

ROOTDIR="$(pwd -W)"

echo "Generating SBCL script..."
echo "(require :asdf)" > build/build.cl
echo "(setf asdf:*central-registry*
  (list* #P\"${ROOTDIR}/bootstrap/\"
         asdf:*central-registry*))" >> build/build.cl
echo "(require :symta)" >> build/build.cl
echo "(in-package :symta)" >> build/build.cl
echo "(build \"${ROOTDIR}/build/symta/\")" >> build/build.cl

echo "Invoking SBCL to produce compiler's *.c files..."
sbcl --script build/build.cl

echo "Copying *.c files to bootstrap/c..."
cp build/symta/lib/core_.c bootstrap/c
cp build/symta/lib/reader.c bootstrap/c
cp build/symta/lib/compiler.c bootstrap/c
cp build/symta/lib/macro.c bootstrap/c
cp build/symta/lib/eval.c bootstrap/c
cp build/symta/lib/main.c bootstrap/c

echo "Done. Now run appropriate build* file to produce compiler's executable."