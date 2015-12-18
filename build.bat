

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
dmd sire.obj appEnv.obj lib/ish.obj lib/git.obj lib/url.obj lib/rules.obj lib/lineProcessing.obj lib/env.obj -ofbin\sire.exe

echo Build ish
copy bin\sire.exe bin\ish.exe
copy bin\sire.exe bin\env.exe

echo Done
