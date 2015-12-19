

mkdir bin

echo Build sire
dmd -c -op sire.d
dmd -c -op appEnv.d 
dmd -c -op lib/ish.d 
dmd -c -op lib/git.d 
dmd -c -op lib/url.d 
dmd -c -op lib/rules.d 
dmd -c -op lib/LineProcessing.d
dmd -c -op lib/env.d
dmd sire.o appEnv.o lib/ish.o lib/git.o lib/url.o lib/rules.o lib/LineProcessing.o lib/env.o -ofbin/sire

echo Build ish
cp bin/sire bin/ish
cp bin/sire bin/env

echo Done
