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
import lib.ish;
import appEnv;

int main(string args[])
{
   string script;

   setEnvironment(args[0..$]);

   switch(AppName())
   {
       case "ish":
          return ishMain();

       case "env":
          return envMain();

       case "sire":
       default:
          return sireMain();
    }
}

int sireMain()
{
   int status = 0;

   // Display the environment
   foreach (string name, string value; Env())
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

int envMain()
{
   int status = 0;

   // Display the environment
   foreach (string name, string value; Env())
   {
      writefln("%s=%s", name, value);
   }


   return status;
}


int ishMain()
{
    int status = 0;
    
    File input = stdin;
    
    if (Targets.length > 0)
    {
        int rtn = 0;

        foreach (target; Targets())
        {
           input.open(Targets[0], "r");
    	     scope(exit) input.close();

           auto shell = new Ish(stdout, stderr, Env(), Env["PWD"], Params());
    
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
        auto shell = new Ish(stdout, stderr, Env(), Env["PWD"], Params());
    
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