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
import env;
import ish;

public
{
	string         AppName() {return appName;}
	string[]       Targets() {return targets;}
	string[]       Params()  {return params;}
	
	bool interactive() @property
	{
	   return isInteractive;
	}


	void setEnvironment(ref string[] args)
	{
	   GetAppName();
	   args = args[1..$];
	  
	   // Read and variable definitions
       int i = 0; // input parmeter
       int o = 0; // output parameter
	   while (i < args.length)
	   {
		  string arg = args[i];

		  if (arg == "-ish")
		  {
			 // Set not interactive
			 appName = "ish";
             i += 1;
		  }		  
          else if (arg == "-sire")
		  {
			 // Set not interactive
			 appName = "sire";
             i += 1;
		  }		  
          else if (arg == "-env")
		  {
			 // Set not interactive
			 appName = "env";
             i += 1;
		  }
		  else if (arg == "-C")
		  {
			 // Set the working directory
             i += 1;
			 if (i < args.length)
			 {
				chdir(args[i]);
                i += 1;
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
			 
			 for (int j = 0; (j < name.length); j++)
			 {
				if (name[j] == '=')
				{
				   value = name[j+1..$];
				   name  = name[0..j];
				   break;
				}
			 }
			 
			 setEnv(name, value); 
             i += 1;
		  }
		  else if ((arg.length > 2) && (arg[0..2] == "-U"))
		  {
			 string name  = arg[2..$];
			 
			 for (int j = 0; (j < name.length); j++)
			 {
				if (name[j] == '=')
				{
				   name  = name[0..j];
				   break;
				}
			 }
			 
			 unsetEnv(name);
             i += 1;
		  }
		  else
		  {
			 args[o++] = args[i++];
		  }
	   }
       
       // Trim back the array
       args.length = o;

	version( Win32 )
	{
	   defaultEnv("OS",  "WIN32");
	   defaultEnv("EXE", ".exe");
	   defaultEnv("OBJ", ".obj");
	   defaultEnv("EDITOR", Ish.getFullPath("notepad.exe", thisEnv));
	}
	else version( Win64 )
	{
	   defaultEnv("OS",  "WIN64");
	   defaultEnv("EXE", ".exe");
	   defaultEnv("OBJ", ".obj");
	   defaultEnv("EDITOR", Ish.getFullPath("notepad.exe", thisEnv));
	}
	else version( linux )
	{
	   defaultEnv("OS",  "LINUX");
	   defaultEnv("EXE", "");
	   defaultEnv("OBJ", ".o");
	   defaultEnv("EDITOR", getFullPath("nano", thisEnv));
	}
	else version( OSX )
	{
	   defaultEnv("OS",  "OSX");
	   defaultEnv("OBJ", ".o");
	   defaultEnv("EXE", "");
	}
	else version ( FreeBSD )
	{
	   defaultEnv("OS",  "FREEBSD");
	   defaultEnv("OBJ", ".o");
	   defaultEnv("EXE", "");
	}
	else version (Solaris)
	{
	   defaultEnv("OS",  "SOLARIS");
	   defaultEnv("OBJ", ".o");
	   defaultEnv("EXE", "");
	}
	else
	{
	   static assert( false, "Unsupported platform" );
	}

	   defaultEnv("TMP",    tempDir());
	   defaultEnv("PWD",    getcwd());
	   defaultEnv("CONFIG", "DEBUG");
	}
}


private
{
	string         appName = "sire";
	string[]       targets;
	string[]       params;
	bool           isInteractive = true;

	void GetAppName()
	{
	   string app = thisExePath();

	   size_t i = app.length -1;
	   while ((i > 0) && (app[i] != '\\') && (app[i] != '/'))
	   {
		  i -= 1;
	   }

	   // Get the path to the app.
	   if (i >= 0)
	   {
		   appName = app[i+1..$];
		   setEnv("DHUT_BIN", app[0..i+1]);

		   if ((i > 4) && (app[i-4..i] == "/bin") || (app[i-4..i] == "\\bin"))
		   {
			   setEnv("DHUT", app[0..i-3]);
		   }
	   }
	   else
	   {
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
	}
}
