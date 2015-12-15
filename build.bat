

mkdir bin

echo Build sire
dmd sire.d env.d lib/ish.d lib/git.d lib/url.d lib/rules.d -ofbin\sire.exe

echo Build ish
copy bin\sire.exe bin\ish.exe
copy bin\sire.exe bin\env.exe

echo Done
