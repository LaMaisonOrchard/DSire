import std.stdio;
import std.process;

int main(string args[])
{
  int status = 0;
  
  auto env = environment.toAA();
  

version( Win32 )
{
    env["OS"]  = "WIN32";
    env["EXE"] = ".exe";
}
else version( Win64 )
{
    env["OS"]  = "WIN64";
    env["EXE"] = ".exe";
}
else version( linux )
{
    env["OS"]  = "LINUX";
    env["EXE"] = "";
}
else version( OSX )
{
    env["OS"]  = "OSX";
    env["EXE"] = "";
}
else version ( FreeBSD )
{
    env["OS"]  = "FreeBSD";
    env["EXE"] = "";
}
else version (Solaris)
{
    env["OS"]  = "SOLARIS";
    env["EXE"] = "";
}
else
{
    static assert( false, "Unsupported platform" );
}

   // Display the environment
   foreach (string name, string value; env)
   {
      writefln("[%s] = [%s]", name, value);
   }


  return status;
}