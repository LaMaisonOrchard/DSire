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
import env;
import ish;

static this()
{
    //Ish.register(new GitCmd());
}

            
class GitCmd : Ish.Command
{
    public bool matchOp (const(char)[] name) {return false;}
    public bool matchCmd(const(char)[] name) {return name == "git";} 
           
    public void help()
    {         
        writeln("GIT stub");                
    }   
         
    public void fullHelp()
    {         
        writeln("GIT stub");                
    }
        
    public int run(Env env, const(char)[][] items ...)
    {
        writeln("GIT stub");
            
        return 0;
    }
}   
