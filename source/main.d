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
import env;
import appEnv;

int main(string[] args)
{
   string script;

   setEnvironment(args);
   
   switch(AppName())
   {
       case "ish":
          return ishMain(args);

       case "env":
          return envMain(args);

       case "sire":
       default:
          return sireMain(args);
    }
}

int sireMain(string[] args)
{
   int status = 0;
   
   sireArgs(args);

   // Display the environment
   foreach (string name, string value; thisEnv.raw)
   {
      writefln("[%s] = [%s]", name, value);
   }

   // Display the environment
   foreach (string name; Targets())
   {
      writefln("<%s>", name);
   }



   return status;
}

void sireArgs(ref string[] args)
{
	  
   // Read and variable definitions
   size_t i = 0; // input parmeter
   while (i < args.length)
   {
	  string arg = args[i];


	  if ((arg == "-params") || (arg == "-p"))
	  {
		 // everything else are shell parameters
		 args = args[i+1..$];
		 i = args.length;
	  }
	  else if (arg == "-c")
	  {
		 // Set the configuration
         i += 1;
		 if (i < args.length)
		 {
			//setEnv("CONFIG", args[i], baseEnv);
			i += 1;
		 }
	  }	
	  else if (arg[0] != '-')
	  {
		 //targets ~= arg;
	  }
   }
}

int envMain(string[] args)
{
   int status = 0;

   // Display the environment
   foreach (string name, string value; thisEnv.raw)
   {
      writefln("%s=%s", name, value);
   }


   return status;
}


int ishMain(string[] args)
{
    bool interactive;
    int status = 0;
    
    ishArgs(args, interactive);
        
    File input = stdin;
    
    if (Targets.length > 0)
    {
        int rtn = 0;

        foreach (target; Targets())
        {
           input.open(Targets[0], "r");
    	     scope(exit) input.close();

           auto shell = new Ish(stdout, stderr, thisEnv.dup, thisEnv.getEnv("PWD"), Params());
    
           foreach (line; input.byLine())
           {
               if (!shell.run(line))
               {
	             break;
	         }
           }
    
           rtn = shell.ExitStatus();
        }

        return rtn;
    }
    else
    {    
        auto shell = new Ish(stdout, stderr, thisEnv.dup, thisEnv.getEnv("PWD"), Params());
    
        if (interactive) write("> ");
        foreach (line; input.byLine())
        {
            if (!shell.run(line))
            {
	          break;
	      }
            if (interactive) write("> ");
        }
    
        return shell.ExitStatus();
    }
}

void ishArgs(ref string[] args, ref bool interactive)
{
   // Read and variable definitions
   interactive = true; // Assume interactive
   
   int i = 0; // input parmeter
   while (i < args.length)
   {
	  string arg = args[i];


	  if (arg == "-ni")
	  {
		 // Set the configuration
         interactive = false;
         i += 1;
	  }	
   }
}
