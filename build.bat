

mkdir bin

echo Build sire
dmd sire.d lib/ish.d lib/git.d lib/url.d -ofbin\sire.exe

echo Build ish
copy bin\sire.exe bin\ish.exe

echo Done
