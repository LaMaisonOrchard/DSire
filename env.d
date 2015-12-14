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
import core.stdc.stdlib;
import std.process;
import std.file;
import ish;

public
{

string         AppName() {return appName;}
string         BaseDir() {return base;}
string[]       Targets() {return targets;}
string[]       Params()  {return params;}
string[string] Env()     {return baseEnv;}


string[string] setEnvironment(string[] args)
{
   auto env = environment.toAA();

   GetAppName(args[0]);
   args = args[1..$];
  
   // Read and variable definitions
   while (args.length > 0)
   {
	string arg = args[0];
      args = args[1..$];

      if ((arg == "-params") || (arg == "-p"))
      {
         // everything else are shell parameters
         params = args;
         args = args[$..$];
      }
      else if (arg == "-c")
      {
         // everything else are shell parameters
         if (args.length >0)
         {
            setEnv("CONFIG", args[0],   env);
            args = args[1..$];
         }
      }
      else if (arg == "-C")
      {
         // everything else are shell parameters
         if (args.length >0)
         {
            chdir(args[0]);
            args = args[1..$];
         }
      }
      else if ((arg == "-i") || (arg == "-v") || (arg == "--version"))
      {         
         writefln("%s 0.0.1", AppName());
         exit(0);
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
      else if ((arg.length > 2) && (arg[0..2] == "-U"))
      {
         string name  = arg[2..$];
         
         for (int i = 0; (i < name.length); i++)
         {
            if (name[i] == '=')
            {
               name  = name[0..i];
               break;
            }
         }
         
         unsetEnv(name, env);
      }
      else if (arg[0] != '-')
      {
         targets ~= arg;
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

   defaultEnv("TMP",    tempDir(), env);
   defaultEnv("PWD",    getcwd(),  env);
   defaultEnv("CONFIG", "DEBUG",   env);

   baseEnv = env;
   
   return env;
}

}

private
{

string[string] baseEnv;
string         appName = "sire";
string         base = "";
string[]       targets;
string[]       params;

void GetAppName(string app)
{
   int i = app.length -1;
   while ((i > 0) && (app[i] != '\\') && (app[i] != '/'))
   {
      i -= 1;
   }

   // Get the path to the app.
   if (i >= 0)
   {
       base = app[0..i+1];
       appName = app[i+1..$];
   }
   else
   {
       base = "";
       appName = app;
   }

   // strip the suffix
   i = appName.length -1;
   while ((i > 0) && (appName[i] != '.'))
   {
      i -= 1;
   }
   if (i > 0)
   {
      // Remove the suffix found
      appName = appName [0..i];
   }


   // Work out the absolute path - TODO}
}

}