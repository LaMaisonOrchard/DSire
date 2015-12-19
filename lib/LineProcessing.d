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

import std.conv;
import std.ascii;  // ASCII support
//import std.uni;  // Unicode support


/**********************************************************
 *  Split the text into lines separated by \r, \r\n, \n, \n\r or ;
 *
 **/
public string[] SplitLines(string text)
{
    string[] lines;
    int start = 0;
    int end = 0;

    while (end < text.length)
    {
       if (text[end] == ';')
       {
          lines ~= text[start..end];
          end += 1;
          start = end;
       }
       else if (text[end] == '\r')
       {
          lines ~= text[start..end];
          end += 1;
          if ((end < text.length) && (text[end] == '\n'))
          {
             end += 1;
          }
          start = end;
       }          
       else if (text[end] == '\n')
       {
          lines ~= text[start..end];
          end += 1;
          if ((end < text.length) && (text[end] == '\r'))
          {
             end += 1;
          }
          start = end;
       }   
       else if ((text[end] == '\\') && (end+1 < text.length))
       {
          end += 2;
       }       
       else
       {
          end += 1;
       }       
   }

    if (start < end)
    {
       lines ~= text[start..$];
    }

    return lines;
}


/**********************************************************
 * Expand the variables in the line
 *
 **/
public pure string ExpandLine(char open, char close)(string line, string[] args ...)
{
   return line; // TODO

   //Check for variables
   bool expand = false;
   int idx = 0;
   while (!expand && (idx < line.length-3))
   {
      if (line[idx] == '\\')
      {
         // excaped characters
         idx += 2;
      }
      else if ((line[idx] == '$') && (line[idx+1] == open))
      {
         // Start of a variable
         expand = true;
      }
      else
      {
         idx += 1;
      }
   }

   if (!expand)
   {
      return line;
   }
   else
   {
      string buffer;

      int start = 0;
      int end = 0;
      while (end < line.length)
      {
         if (line[end] == '\\')
         {
            // excaped characters
            end += 2;
         }
         else if ((end < line.length-1) && (line[end] == '$') && (line[end+1] == open))
         {
            // Start of a variable
            buffer ~= line[start..end];

            // Match brackets to get the variable name
            int count = 1;
            start = end+2;
            end = start;
            while ((count > 0) && (end < line.length))
            {
                if ((end < line.length-1) && (line[end] == '$') && (line[end+1] == open))
                {
                    count += 1;
                    end += 2;
                } 
                else if (line[end] == close)
                {
                    count -= 1;
                    end += 1;
                }
                else
                {
                    end += 1;
                }
            }

            buffer ~= Encode(ExpandVar!(open,close)(line[start..end], args));
            end += 1;
         }
         else
         {
            end += 1;
         }
      }

       if (start < end)
       {
           buffer ~= line[start..$];
       }
   }

}


/**********************************************************
 * Decode the double quotes and excape character and spit into
 * a list of arguments. The '`' and '=' charaters are interpreted
 * as single arguments when not excaped or quoted.
 *
 **/
public pure string[] Decode(string line)
{
   string[] args;

   size_t start = 0;
   size_t end = 0;

   while (end < line.length)
   {
      // Strip white space
      start = end;
      while ((start < line.length) && line[start].isWhite)
      {
         start++;
      }

      // find the space separated block
      end = start;
      while((end < line.length) && !line[end].isWhite)
      {
         if (line[end] == '\\')
         {
            // Skip the excaped character
            end++;
         }
         end++;
      }

      if (end > line.length) end = line.length;
   
      if (end > start)
      {
         args ~= DecodeSingle(line[start..end]);
      }
   }

   return args;
}



/**********************************************************
 * Enlode a set of arguments in a format that can be decode
 * by Decode();
 *
 **/
public pure string Encode(string[] args ...)
{
   string line;

   if (args.length == 1)
   {
       line = EncodeSingle(args[0]);
   }
   else if (args.length > 1)
   {
      line ~= EncodeSingle(args[0]);
      foreach (arg; args)
      {
         line ~= " ";
         line ~= EncodeSingle(arg);
      }
   }

   return line;
}

/**********************************************************
 * Convert '\\' to '/' in strings
 *
 **/
public pure string NormalisePath(string path)
{
version ( Windows )
{

   //Check for character to convert
   int count = 0;
   foreach (ch ; path)
   {
      if (ch == '\\')
      {
         count += 1;
         break;
      }
   }

   if (count == 0)
   {
      return path;
   }
   else
   {
      char[] work;
      work.length = path.length;

      int idx = 0;
      foreach (ch ; path)
      {
         if (ch == '\\')
         {
            work[idx++] = '/';
         }
         else
         {
            work[idx++] = ch;
         }
      }

      return work.idup;
   }
}
else
{
   return path;
}
}



/**********************************************************
 * Enlode a set an argument in a format that can be decode
 * by Decode();
 *
 **/
private pure string EncodeSingle(string arg)
{
   //Check the number of character to excape
   int count = 0;
   foreach (ch ; arg)
   {
      if ((ch == '"') || (ch == ' ') || (ch == '\\') || (ch == '\t'))
      {
         count += 1;
      }
   }

   if (count == 0)
   {
      return arg;
   }
   else
   {
      char[] work;
      work.length = arg.length+count;

      int idx = 0;
      foreach (ch ; arg)
      {
         if ((ch == '"') || (ch == ' ') || (ch == '\\'))
         {
            work[idx++] = '\\';
            work[idx++] = ch;
         }
         else if (ch == '\t')
         {
            work[idx++] = '\\';
            work[idx++] = 't';
         }
         else
         {
            work[idx++] = ch;
         }
      }

      return work.idup;
   }
}



/**********************************************************
 * Decode a an argument in a format that can be encoded
 * by Encode();
 *
 **/
private pure string DecodeSingle(string arg)
{
   //Check the number of character to excape
   int count = 0;
   foreach (ch ; arg)
   {
      if (ch == '\\')
      {
         count += 1;
      }
   }

   if (count == 0)
   {
      return arg;
   }
   else
   {
      char[] work;
      work.length = arg.length;

      int too = 0;
      int from = 0;
      while (from < arg.length)
      {
         if (arg[from] == '\\')
         {
            from += 1;
            if (from < arg.length)
            {
               work[too++] = arg[from++];
            }
         }
         else
         {
            work[too++] = arg[from++];
         }
      }

      return work[0..too].idup;
   }
}



/**********************************************************
 * Expand the variable by name. Theses are unencoded values.
 *
 **/
private pure string[] ExpandVar(char open, char close)(string varName, string[] args ...)
{
    int start;
    int end;

    string[] names;
    string[] values;

    // Expand the variable name
    // TODO
    names ~= varName;

    foreach (name ; names)
    {
       start = 0;
       end = args.length;

       if (isSplice(name, start, end))
       {
          values += args[start..end]; 
       }
       else
       {
          value ~= getEnvEnc(name);
       }
    }

    return values;
}

/**********************************************************
 * Parse the name to see if it defines a splice. The start
 * and end of the splice is returned in the variable start
 * and end. The splice is trimed to fit with in the bounds
 * of the initial values of start and end;
 *
 **/
private bool isSplice(string name, ref int start, ref int end)
{
    // TODO - Parse the name

    return false;
}
