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

import std.conv;
import std.ascii;  // ASCII support
//import std.uni;  // Unicode support

import lib.LineProcessing;

string[string] envRaw;  // The raw native version of the environment
string[string] envEnc;  // The encoded version of the environment

/*************************************************************
 * Configure the environment from the native environment
 **/
void setEnv(string[string] env)
{
   if ("DHUT_ENC" in env)
   {
      envEnc = env;

      foreach(key, value; envEnc)
      {
         envRaw[key] = Concatinate(' ', Decode(value));
      }

      envRaw.remove("DHUT_ENC");
   }
   else
   {
      envRaw = env;

      foreach(key, value; envRaw)
      {
         envEnc[key] = Encode(NormalisePath(value));
      }

      envEnc["DHUT_ENC"] = "1";
   }
}

///////// ENVIRONMENT Manipulation /////////////////////////////////////////////////////
   
public string getEnv(const(char)[] name)
{
version ( Windows )
{
   // Force the name to uppercase
   name = name.toUpper;
}
   // Expand the names environment variable
   auto p = (name in envRaw);
   if (p is null)
   {
      return "";
   }
   else
   {
      return *p;
   }
}

   
public string getEnvEnc(const(char)[] name)
{
version ( Windows )
{
   // Force the name to uppercase
   name = name.toUpper;
}
   // Expand the names environment variable
   auto p = (name in envEnc);
   if (p is null)
   {
      return "";
   }
   else
   {
      return *p;
   }
}



   
public void setEnv(const(char)[] name, string value)
{
version ( Windows )
{
   // Force the name to uppercase
   name = name.toUpper;
}
   envRaw[name] = value;
   envEnc[name] = Encode(NormalisePath(value));
}



   
public void setEnvEnv(const(char)[] name, string value)
{
version ( Windows )
{
   // Force the name to uppercase
   name = name.toUpper;
}
   envRaw[name] = Concatinate(' ', Decode(value));
   envEnc[name] = value;
}


   
public void unsetEnv(const(char)[] name)
{
version ( Windows )
{
   // Force the name to uppercase
   string nm = name.toUpper;
}
else
{
   string nm = name.idup;
}

   auto p = (name in envRaw);
   if (p !is null)
   {
   	envRaw.remove(nm);
   	envEnc.remove(nm);
   }
}


public void defaultEnv(const(char)[] name, string value)
{
version ( Windows )
{
   // Force the name to uppercase
   name = name.toUpper;
}
   auto p = (name in envRaw);
   if (p is null)
   {
      // Undefined variable
      envRaw[name] = value;
      envEnc[name] = Encode(NormalisePath(value));
   }
   else
   {
      // Already defined
   }
}


public void defaultEnvEnc(const(char)[] name, string value)
{
version ( Windows )
{
   // Force the name to uppercase
   name = name.toUpper;
}
   auto p = (name in envRaw);
   if (p is null)
   {
      // Undefined variable
      envRaw[name] = Concatinate(' ', Decode(value));
      envEnc[name] = value;
   }
   else
   {
      // Already defined
   }
}

@property public pure string toUpper(const(char)[] name)
{
   // TODO - this could be optimised
   
   // Force the name to uppercase
   char[] tmp;
   tmp.length = name.length;
   for (int i = 0; (i < name.length); i++)
   {
      tmp[i] = std.ascii.toUpper(name[i]);
   }
   return tmp.idup;
}

public pure bool allDigits(const(char)[] name)
{
   foreach (const(char)ch; name)
   {
      if (!isDigit(ch))
      {
         return false;
      }
   }
   
   return true;
}

string Concatinate(char ch, string[] list)
{
   if (list.length == 0)
   {
      return "";
   }
   else if (list.length == 1)
   {
      return list[0];
   }
   else
   {
      char[] work;
      work.length = list[0].length;
      work[0..$] = list[0][0..$];

      size_t idx = work.length;
      foreach (item; list)
      {
         work.length += item.length +1;
         work[idx++] = ' ';
         work[idx..$] = item[0..$];
      }

      return work.idup;
   }
}
