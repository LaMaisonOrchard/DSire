import std.stdio;
import std.process;
import std.file; 
import ish;

int main(string args[])
{
    int status = 0;
    
    File input = stdin;
    
    if (args.length > 1)
    {
      input.open(args[1], "r");
    }
    scope(exit) input.close();

    auto env = setEnvironment(args);
    
    auto shell = new Ish(stdout, stderr, env, getcwd(), args);
    
    foreach (line; input.byLine())
    {
        if (!shell.run(line))
        {
	  break;
	}
    }
    
    return shell.ExitStatus();
}


string[string] setEnvironment(ref string[] args)
{
   auto env = environment.toAA();

version( Win32 )
{
   defaultEnv("OS",  "WIN32", env);
   defaultEnv("EXE", ".exe", env);
   defaultEnv("EDITOR", Ish.getFullPath("notepad.exe", env), env);
}
else version( Win64 )
{
   defaultEnv("OS",  "WIN64", env);
   defaultEnv("EXE", ".exe", env);
   defaultEnv("EDITOR", Ish.getFullPath("notepad.exe", env), env);
}
else version( linux )
{
   defaultEnv("OS",  "LINUX", env);
   defaultEnv("EXE", "", env);
   defaultEnv("EDITOR", Ish.getFullPath("nano", env), env);
}
else version( OSX )
{
   defaultEnv("OS",  "OSX", env);
   defaultEnv("EXE", "", env);
}
else version ( FreeBSD )
{
   defaultEnv("OS",  "FREEBSD", env);
   defaultEnv("EXE", "", env);
}
else version (Solaris)
{
   defaultEnv("OS",  "SOLARIS", env);
   defaultEnv("EXE", "", env);
}
else
{
   static assert( false, "Unsupported platform" );
}

   defaultEnv("TMP", tempDir(), env);
   
   return env;
}