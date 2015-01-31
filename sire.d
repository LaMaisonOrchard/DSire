/****************************************************************************

    The Sire build utility 'sire'.
    Copyright (C) 2015  David W Orchard (davido@errol.org.uk)

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*****************************************************************************/
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