

mkdir -p bin

echo Build sire
cd source
dmd -c -op main.d
dmd -c -op appEnv.d 
dmd -c -op ish.d 
dmd -c -op git.d 
dmd -c -op url.d 
dmd -c -op rules.d 
dmd -c -op line_processing.d
dmd -c -op env.d
dmd main.o appEnv.o ish.o git.o url.o rules.o line_processing.o env.o -of../bin/sire

cd ..

echo Build ish
cp bin/sire bin/ish
cp bin/sire bin/env

echo Done
