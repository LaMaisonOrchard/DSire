import std.stdio;
import std.process;
import std.file;
import ish;

int main(string args[])
{
   int status = 0;
  
   auto env = setEnvironment(args);

   // Display the environment
   foreach (string name, string value; env)
   {
      writefln("[%s] = [%s]", name, value);
   }


   return status;
}


string[string] setEnvironment(ref string[] args)
{
   auto env = environment.toAA();
  
   // Read and variable definitions
   foreach (ref arg; args)
   {
      if (arg == "-params")
      {
         // everything else are shell parameters
         break;
      }
      else if ((arg.length > 2) && (arg[0..2] == "-D"))
      {
         string name  = arg[2..$];
         string value = "1";
         arg = "";
         
         for (int i = 0; (i < name.length); i++)
         {
            if (name[i] == '=')
            {
               value = name[i+1..$];
               name  = name[0..i];
               break;
            }
         }
         
         setEnv(name, value, env);
      }
   }

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