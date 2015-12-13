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

string base = "";
string script = "";
string[] params;

int main(string args[])
{
   string script;

   auto env = setEnvironment(args[1..$]);

   switch(appName(args[0]))
   {
       case "ish":
          return ishMain(script, env);

       case "sire":
       default:
          return sireMain(script, env);
    }
}

string appName(string app)
{
   int i = app.length -1;
   while ((i > 0) && (app[i] != '\\') && (app[i] != '/'))
   {
      i -= 1;
   }

   // Get the path to the app.
   string name;
   if (i >= 0)
   {
       base = app[0..i+1];
       name = app[i+1..$];
   }
   else
   {
       base = "";
       name = app;
   }

   // strip the suffix
   i = name.length -1;
   while ((i > 0) && (name[i] != '.'))
   {
      i -= 1;
   }
   if (i > 0)
   {
      // Remove the suffix found
      name = name [0..i];
   }

   // Work out the absolute path - TODO}
   writefln("APP [%s]  [%s]", base, name);

   return name;
}

int sireMain(string script, string[string] env)
{
   int status = 0;

   // Display the environment
   foreach (string name, string value; env)
   {
      writefln("[%s] = [%s]", name, value);
   }


   return status;
}

int ishMain(string script, string[string] env)
{
    int status = 0;
    
    File input = stdin;
    
    if (script.length > 1)
    {
      input.open(script, "r");
    }
    scope(exit) input.close();
    
    auto shell = new Ish(stdout, stderr, env, getcwd(), params);
    
    write("> ");
    foreach (line; input.byLine())
    {
      if (!shell.run(line))
      {
	  break;
	}
      write("> ");
    }
    
    return shell.ExitStatus();
}


string[string] setEnvironment(string[] args)
{
   auto env = environment.toAA();
  
   // Read and variable definitions
   while (args.length > 0)
   {
	string arg = args[0];
      args = args[1..$];

      if (arg == "-params")
      {
         // everything else are shell parameters
         params = args[1..$];
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
      else if (arg == "-f")
      {
         if (args.length > 0)
         {
             script = args[0];
             args = args[1..$];
         }
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