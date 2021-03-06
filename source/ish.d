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
import std.concurrency;
import std.container;
import std.ascii;  // ASCII support
//import std.uni;  // Unicode support
import std.process; 
import std.conv; 
import std.outbuffer; 
import std.file; 
import std.datetime;
import std.path;
import url;
import env;
import line_processing;


public class Ish
{
   /////////////////////////////////////////////////////
   //
   // Create a ish interpreter
   //
   this(File out_fp, File err_fp, Env env, string cwd, string[] args ...)
   {
      this.first    = true;
      this.out_fp   = out_fp;
      this.err_fp   = err_fp;
      this.env      = env;
      this.args     = args;
      this.cwd      = cwd;
      this.env.setEnv(cwd);
   }
   
   /////////////////////////////////////////////////////
   //
   // Create a ish interpreter
   //
   this(OutBuffer out_buf, File err_fp, Env env, string cwd, string[] args ...)
   {
      this.first    = true;
      this.out_buf  = out_buf;
      this.err_fp   = err_fp;
      this.env      = env;
      this.args     = args;
      this.cwd      = cwd;
      this.env.setEnv(cwd);
   }
   
   public int ExitStatus()
   {
    try{
        
      // Is there a sub-shell
      if (sub_fp.isOpen())
      {
         this.exitStatus = finishSubShell();
    stderr.writeln("5)");
      }
      
    }
    catch
    {    stderr.writeln("5.1)");
    }
      
      return this.exitStatus;
   }
   
   /////////////////////////////////////////////////////
   //
   // Execute one of more ish commands.
   //
   // RETURN False is returned in the shell exits
   //
   bool run(const(char)[] input)
   {
      auto parseState = state.SPACE;
      
      Element[] line;
      bool      more    = true;
      bool      lineEnd = false;  // Are we at the end of a line
      
      // Is this the first input line
      if (this.first)
      {
         first = false;         
         if (input.length > 2)
         {            // Does the line start with a hash bang
            if ((input[0] == '#') &&
                (input[1] == '!'))
            {
               // Try to start a sub-shell
               more  = startSubShell(input[2..$]);
               input = input[0..0];
            }
         }
      }
       
      // Is there a sub-shell
      if (more && sub_fp.isOpen())
      {
         // Send the input to the sub-shell
         this.sub_fp.writeln(input);
         input = input[0..0];

         // This blocks - we need a way of doing non-blocking - TODO
         //foreach (text; this.sub_out.byLine())
         //{
         //    out_fp.writeln(text);
         //}
         
         auto rtn = tryWait(this.sub_pid);
         if (rtn.terminated)
         {
            sub_fp.close();
            more            = false;
            this.exitStatus = rtn.status;
         }
      }
      
      int i = 0;
      while (more && (i < input.length))
      {
         if (input[i] == '\r')
         {
            // EOL
            if (parseState == state.DOUBLE_QUOTE)
            {
               err_fp.writeln("Unterminated quotes");
               more = false;
            }
            else if (parseState == state.BACK_QUOTE)
            {
               err_fp.writeln("Unterminated back quotes");
               more = false;
            }
            else
            {
               more = eol(parseState, line, input[0..i]);
            }
            
            input = input[i+1..$]; i = 0;
            line  = line [0..0];
            
            if ((input.length > 1) && (input[i] == '\n'))
            {
               // Consume the '\r' so the '\n' is also consumed
               input = input[1..$];
            }
         
            lineNo  += 1;
            lineEnd  = true;
         }
         else if (input[i] == '\n')
         {
            // EOL
            if (parseState == state.DOUBLE_QUOTE)
            {
               err_fp.writeln("Unterminated quotes");
               more = false;
            }
            else if (parseState == state.BACK_QUOTE)
            {
               err_fp.writeln("Unterminated back quotes");
               more = false;
            }
            else
            {
               more = eol(parseState, line, input[0..i]);
            }
            
            input = input[i+1..$]; i = 0;
            line  = line [0..0];
            
            lineNo  += 1;
            lineEnd  = true;
         }
         else
         {
            lineEnd  = false;
            
            switch (parseState)
            {
               case state.SPACE: // white space
                  if (isWhite(input[i]))
                  {
                     // Consume the white space
                     i += 1;
                  }
                  else if (input[i] == '\"')
                  {
                     // Consume the start quote
                     input = input[i+1..$]; i = 0;
                     parseState = state.DOUBLE_QUOTE;
                  }
                  else if (input[i] == '`')
                  {
                     // Consume the start quote
                     input = input[i+1..$]; i = 0;
                     parseState = state.BACK_QUOTE;
                  }
                  else if (input[i] == '=')
                  {
                     // EOL
                     line  ~= Element(this, state.ARG, "=");
                     input  = input[i+1..$]; i = 0;
                  }
                  else if (input[i] == ';')
                  {
                     // EOL
                     more = eol(parseState, line, "");
                     input = input[i+1..$]; i = 0;
                     line  = line [0..0];
                  }
                  else if (input[i] == '#')
                  {
                     // EOL
                     more = eol(parseState, line, "");
                     line  = line [0..0];

                     // Skip to the end of line
                     while ((input.length > i) && (input[i] != '\r') && (input[i] != '\n'))
                     {
                        i += 1;
                     }
                     input = input[i..$]; i = 0;
                     
                  }
                  else if (input[i] == escCh)
                  {
                     if (input.length < i+2)
                     {
                        // Illegal escape sequence
                     }
                     else
                     {
                        input = input[i..$]; i = 2;
                        parseState  = state.ARG;		
                     }
                  }
                  else
                  {
                     // Add to the entry
                     input = input[i..$]; i = 1;
                     parseState  = state.ARG;
                  }
                  break;
                  
               case state.ARG: // argument
                  if (isWhite(input[i]))
                  {
                     // End of the entry
                     line ~= Element(this, parseState, input[0..i]);
                     input = input[i..$]; i = 1;
                     parseState = state.SPACE;
                  }
                  else if (input[i] == '\"')
                  {
                     // End of the entry
                     line ~= Element(this, parseState, input[0..i]);
                     input = input[i..$]; i = 1;
                     
                     // Consume the start quote
                     parseState = state.DOUBLE_QUOTE;
                  }
                  else if (input[i] == '`')
                  {
                     // End of the entry
                     line ~= Element(this, parseState, input[0..i]);
                     input = input[i..$]; i = 1;
                     
                     // Consume the start quote
                     parseState = state.BACK_QUOTE;
                  }
                  else if (input[i] == '=')
                  {
                     // EOL
                     line  ~= Element(this, parseState, input[0..i]);
                     line  ~= Element(this, parseState, "=");
                     input  = input[i+1..$]; i = 0;
                  }
                  else if (input[i] == ';')
                  {
                     // EOL
                     more = eol(parseState, line, input[0..i]);
                     input = input[i+1..$]; i = 0;
                     line  = line [0..0];
                     parseState = state.SPACE;
                  }
                  else if (input[i] == '#')
                  {
                     // EOL
                     more = eol(parseState, line, input[0..i]);
                     line  = line [0..0];

                     // Skip to the end of line
                     while ((input.length > i) && (input[i] != '\r') && (input[i] != '\n'))
                     {
                        i += 1;
                     }
                     input = input[i..$]; i = 0;
                     
                  }
                  else if (input[i] == escCh)
                  {
                     if (input.length < 2)
                     {
                        // Illegal escape sequence
                     }
                     else
                     {
                        // Consume the escape
                        i += 2;
                     }
                  }
                  else
                  {
                     // Add to the entry
                     i += 1;
                  }
                  break;
                  
               case state.DOUBLE_QUOTE: // quote
                  if (input[i] == '\"')
                  {
                     // End of the entry
                     line ~= Element(this, parseState, input[0..i]);
                     input = input[i..$]; i = 1;
                     
                     // Consume the end quote
                     parseState = state.SPACE;
                  }
                  else if (input[i] == escCh)
                  {
                     if (input.length < 2)
                     {
                        // Illegal escape sequence
                     }
                     else
                     {
                        // Consume the escape
                        i += 2;
                     }
                  }
                  else
                  {
                     // Add to the entry
                     i += 1;
                  }
                  break;
                  
               case state.BACK_QUOTE: // operation
                  if (input[i] == '`')
                  {
                     // End of the entry
                     line ~= Element(this, parseState, input[0..i]);
                     input = input[i..$]; i = 1;
                     
                     // Consume the end quote
                     parseState = state.SPACE;
                  }
                  else
                  {
                     // Add to the entry
                     i += 1;
                  }
                  break;
                  
               default:
                  // Illegal state - TODO
                  break;
            }
         }
      }
      
      
      
      // EOL
      if (parseState == state.DOUBLE_QUOTE)
      {
         err_fp.writeln("Unterminated quotes");
         more = false;
      }
      else if (parseState == state.BACK_QUOTE)
      {
         err_fp.writeln("Unterminated back quotes");
         more = false;
      }
      else
      {
         more = eol(parseState, line, input[0..i]);
      }
      
      input = input[0..0];
      line  = line [0..0];
      
      if (!lineEnd)
      {
         // Implicit line end at the end of the input
         lineNo  += 1;
      }
      
      return more;
   }
   
   
   /////////////////////////////////////////////////////
   //
   // Start a sub shell using the given command
   //
   bool startSubShell(const(char)[]input)
   {
      bool more = true;
      
      string[] args;
	  
	  // Get the first line
	  int i = 0;
	  while ((i < input.length) && (input[i] != '\r') && (input[i] != '\n')) i += 1;
	  args = Decode(input[0..i].idup);
	  input = input[i..$];
      
      // // Split up the ar
      
      Url name = args[0];
      // This must start with an absolute path
      if (((name.scheme  == "file") || (name.scheme.length == 1)) && (name.path[0] == '/'))
      {
         try
         {
            this.sub_shell = this.sub_shell[0..0];
            foreach(arg; args)
            {
               this.sub_shell ~= arg.idup;
            }
            
            auto pipes = pipeProcess(args, Redirect.stdin | Redirect.stdout, this.env.raw, Config.newEnv | Config.suppressConsole, cwd);
            this.sub_pid = pipes.pid;
            this.sub_fp  = pipes.stdin;
            this.sub_out = pipes.stdout;
           
            // Pass through any remaining input
            if (input.length > 0)
            {
               this.sub_fp.writeln(input);
            }
 
            passThrough(sub_out, out_fp);
     writeln("1)");
        }
         catch (Exception ex)
         {
            // Report and errors thrown by the process
            more = false;
            err_fp.writeln(ex.msg);
            exitStatus = -1;
         }
      }
      else
      {
         more = false;
         err_fp.write  ("Illegal sub-shell : "); 
         err_fp.writeln(name);
         exitStatus = -1;
      }
      
      return more;
   }
 
   
   /////////////////////////////////////////////////////
   //
   // Start a sub shell using the given command
   //
   int finishSubShell()
   {
     writeln("2)");
     if (sub_fp.isOpen())
      {
     writeln("3)");
        this.sub_fp.close();
    writeln("4)");

    passThroughJoin();
    auto rtn = wait(this.sub_pid);
         return rtn;
      }
      else
      {
         return this.exitStatus;
      }
   }
   
   /////////////////////////////////////////////////////
   //
   // Process the end of a command
   //
   // RETURN Returns true if more commands should be processed.
   //
   private bool eol(ref state parseState, Element[] line, const(char)[] entry)
   {
      bool more = true;
      
      if (parseState != state.SPACE)
      {
         if (entry.length > 0)
         {
            line ~= Element(this, parseState, entry);
         }
         parseState = state.SPACE;
      }
         
      // Process the line 
      if (line.length > 0)
      {
         more = process(line);
      }
      
      return more;
   }
   
   // This is the current state of the parsing engine.
   private enum state
   {
      SPACE,             // Parsing white space
      ARG,               // Parsing a simple argument
      DOUBLE_QUOTE,      // Parsing a quoted argument
      BACK_QUOTE         // Parsing a back quoted argument
   };
   
   
   /////////////////////////////////////////////////////
   //
   // This structure represents a parsed element on a line.
   // This is the element in its unexpanded state. This
   // structure will expand the element when requested.
   //
   private struct Element
   {
      this(Ish parent, state type, const(char)[] arg)
      {
         this.parent = parent;
         this.type   = type;
         this.arg    = arg.idup;
      }
      
      /////////////////////////////////////////////////////
      //
      // Expand the element and return the element in its
      // expanded form
      //
      // RETURN False is returned in the shell exits
      //
      string[] expand()
      {
         switch(type)
         {
            default:
               return [""];  // Should never get here
                                 
            case state.ARG:
            case state.DOUBLE_QUOTE:   
               auto name = expandVariables(this.arg).idup;
               auto list = glob(DecodeSingle(name));
               if (list.length == 0)
               {
                  return [decode(name)];
               }
               else
               {
                  return list;
               }
               
            case state.BACK_QUOTE: 
               auto output = new OutBuffer();
               auto shell  = new Ish(output, parent.err_fp, parent.env.dup, parent.cwd, parent.args);
               
               shell.run(this.arg);
               return Decode(output.toString());
         }
      }
      
      const(char)[]expandVariables(const(char)[] arg)
      {
         // STUB
         string rtn;
         int    i = 0;
         int    s = i;
         while (i < arg.length)
         {	
            if (arg[i] == escCh)
            {
               i += 2;
            }
            else if (arg[i] != '$')
            {
               i += 1;
            }
            else if (i == arg.length-1)
            {
               // End of the line
               i += 1;
            }
            else if (arg[i+1] == '?')
            {
               // Insert return
               rtn ~= arg[s..i];
               i = i+2;
               s = i;
               
               rtn ~= to!string(parent.ExitStatus());
            }
            else if (arg[i+1] != '{')
            {
               // Not a variable
               i += 1;
            }
            else
            {
               // Variable declaration
               rtn ~= arg[s..i];
               i = i+2;
               s = i;
               
               // Balance the brackets
               int count = 1;
               while ((i < arg.length) && (count > 0))
               {
                  if (arg[i] == '{')
                  {
                  count += 1;
                  }
                  else if (arg[i] == '}')
                  {
                  count -= 1;
                  }
                  else
                  {
                  }
                  i += 1;
               }
               
               if (count != 0)
               {
                  // Unbalanced brackets TODO
               }
            
               rtn ~= expand(arg[s..i-1]);
               s = i;
            }
         }
         
         if (s != i)
         {
            rtn ~= arg[s..i];
         }
         
         return rtn;
      }
   
      // Expand the named environment variable
      private string expand(const(char)[] name)
      {
         string nm;
         
         // Look for nested environment variable references
         int    i = 0;
         int    s = i;
         while (i < name.length)
         {	
            if (name[i] != '$')
            {
               i += 1;
            }
            else if (i == name.length-1)
            {
               // End of the name
               i += 1;
            }
            else if (name[i+1] == '{')
            {
               // Variable declaration
               nm ~= name[s..i];
               i = i+2;
               s = i;
               
               // Balance the brackets
               int count = 1;
               while ((i < name.length) && (count > 0))
               {
                  if (name[i] == '{')
                  {
                     count += 1;
                  }
                  else if (name[i] == '}')
                  {
                     count -= 1;
                  }
                  else
                  {
                  }
                  i += 1;
               }
               
               if (count != 0)
               {
                  // Unbalanced brackets TODO
               }
               
               nm ~= expand(name[s..i-1]);
               s = i;
            }
         }
         
         // Add the last part to the name
         if (s != i)
         {
            nm ~= name[s..i];
         }
         
         return parent.getEnv(nm);
      }
   
      string decode(string name)
      {
         string dec;
         
         int i = 0;
         // Expand any excaped charactors and check for glob charactors
         while (name.length > 0)
         {            
            if (name[0] == escCh)
            {
               // Excape
               // TODO
               name = name[1..$];
               dec ~= name[i];
            }
            else
            {
               dec ~= name[0];
            }
            
            name = name[1..$];
         }
         
         return dec;
      }
   
      string[] glob(string name, string path = "")
      {
         if (name.length == 0)
         {
            return [path];
         }
         else
         {
            string decode;
            bool   doGlobe = false;
            
            // Expand any excaped charactors and check for glob charactors
            while (name.length > 0)
            {
               if ((name[0] =='*') || (name[0] =='?') || (name[0] =='[') || (name[0] ==']'))
               {
                  doGlobe = true;
               }
               
               if (name[0] == escCh)
               {
                  // Excape
                  // TODO
                  name = name[1..$];
                  decode ~= name[0];
               }
               else if ((name[0] == '/') || (name[0] == '\\'))
               {
                  if (!doGlobe)
                  {
                     path   ~= decode;
                     path   ~= name[0];
                     decode  = decode[0..0];
                  }
                  else
                  {
                     break;
                  }
               }
               else
               {
                  decode ~= name[0];
               }
               
               name = name[1..$];
            }
            
            if (doGlobe)
            {
               string[] rtn;
               string   tmp = path;
               
               if (path.length == 0)
               {
                  tmp = ".";
               }
             
               try
               {
                  foreach (p; dirEntries(tmp, decode, SpanMode.shallow, true))
                  {
                     if (name.length == 0)
                     {
                        rtn ~= NormalisePath(p.name);
                     }
                     else if (!isDir(p.name))
                     {
                     }
                     else
                     {
                        rtn ~= glob(name[1..$], p.name ~ '/');
                     }
                  }
               }
               catch (FileException ex)
               {
               }
               
               return rtn;
            }
         }
         
         return [];
      }

      string[] splitWhite(string name)
      {
         string[] rtn;

         int i = 0;
         while (name.length > i)
         {
            // Strip white space
            while ((name.length > i) && isWhite(name[i])) i += 1;

            if (name[i] == '"')
            {
               // Quoted string
               i += 1;
               int j = i;
               while ((name.length > i) && (name[i] != '"')) i += 1;

               rtn ~= name[j..i];

               if (name[i] == '"') i += 1;
            }
            else
            {
               // Scan to the next white space
               int j = i;
               while ((name.length > i) && !isWhite(name[i]))
               {
                  if ((name[i] == escCh) && (name.length > i+1))
                     i += 2;
                  else
                     i += 1;
               }

               // if we found something add it
               if (i != j)
               {
                  rtn ~= name[j..i];
               }
            }
         }

         return rtn;
      }
      
      state  type;
      string arg;
      Ish    parent;
   }  
   
    public interface Command
    {
        bool matchOp (const(char)[] name); 
        bool matchCmd(const(char)[] name);
        
        void help();        
        void fullHelp();
        
        int run(Env env, const(char)[][] ...);
    }
    
    public static class CmdException : Exception
    {
        this(const(char)[] msg, int rtn)
        {
            super(msg.idup);
            this.rtn = rtn;
        }        
        
        this(string msg, int rtn)
        {
            super(msg);
            this.rtn = rtn;
        }
        
        int exitCode() @property
        {
            return rtn;
        }
        
        private int rtn;
    }
    
    static private Command[] internalCmd;
    
    /////////////////////////////////////////////////////
    //
    // Register one or more commands with thse shell
    //
    // RETURN nothing
    //
    static public void register(Command[] cmd ...)
    {
        internalCmd ~= cmd;
    }
   
    /////////////////////////////////////////////////////
    //
    // Process a shell command
    //
    // RETURN False is returned in the shell exits
    //
    private bool process(Element[] line)
    {
        bool more = true;
        bool done = false;
      
        const(char)[][] expanded;
      
        // Expand all the elements into their final form
        foreach(Element entry; line)
        {
            expanded ~= entry.expand();
        }
      
        // Is there anything to process
        if (expanded.length > 0)
        {
            // The default is no error
            exitStatus = 0;
         
            // Check for exit
            if (expanded[0] == "exit")
            {                  
                if (expanded.length > 1)
                {
                    try
                    {
                        exitStatus = to!int(expanded[1]);
                    }
                    catch(Exception)
                    {
                        // Bad conversion
                        err_fp.writeln("Bad argument to exit : ", expanded[1]);
                        exitStatus = -1;
                    }
                }
             
                return false;
            }
         
            // Check for help
            if (expanded[0] == "help")
            { 
                if (expanded.length == 1)
                {
                    writeln("exit [<exit code>]");
                    writeln("   Terminate the shell returning the given exit code.");
                    writeln("   If no exit code is specified the the exit code of the");
                    writeln("   last command is returned.");
                    writeln("help [<command>]");
                    writeln("   Output help on built is commands.");         // Check for operators  
               
                    foreach (cmd; internalCmd)
                    {
                        cmd.help();
                    }
                }
                else if (expanded.length > 1)
                {
                    foreach (cmd; internalCmd)
                    {
                        if (cmd.matchOp(expanded[1]) || cmd.matchCmd(expanded[1]))
                        {
                            cmd.help();
                            return true; 
                        }
                    } 
                
                    writeln("Unknown command");
                }
            
                return true; 
            }
         
            try
            {
                // Check for operators     
                foreach (cmd; internalCmd)
                {
                    if ((expanded.length > 1) && cmd.matchOp(expanded[1]))
                    {
                        exitStatus = cmd.run(this.env, expanded);
                        return true;
                    }
                }  
                         
                // Check for commands  
                foreach (cmd; internalCmd)
                {
                    if (cmd.matchCmd(expanded[0]))
                    {
                        exitStatus = cmd.run(this.env, expanded);
                        return true;
                    }
                } 
                        
                // Execute the command as a program
                auto fullPath = getFullPath(expanded[0].idup);
                  
                if (fullPath.length == 0)
                {
                    // No executable found
                    err_fp.writeln("No such programs : " ~ expanded[0]);
                    exitStatus = -1;
                }
                else if (isScript(fullPath))
                {
                    auto appName = fullPath;
version ( Windows )
{
                    if ((fullPath.length > 4) &&
                        (fullPath[$-4..$] == ".bat") &&
                        (fullPath[$-4..$] == ".cmd"))
                    {
                        // Windows batch file
                        appName = getFullPath("cmd.exe");
                    }
}
                    // Run the file as a script
                    File input;
    
                    input.open(fullPath, "r");
                    scope(exit) input.close();
                     
                    string[] args;
                    args ~= appName;
                    foreach (const(char)[] arg; expanded[1..$]) args ~= arg.idup;
                    auto shell  = new Ish(this.err_fp, this.err_fp, this.env.dup, this.cwd, args);
                     
                    foreach (inputLine; input.byLine())
                    {
                        if (!shell.run(inputLine))
                        {
                            break;
                        }
                    }
                     
                    exitStatus = shell.ExitStatus();
                }
                else
                {
                    // Use a pipe to capture stdout as text to be processed
                        
                    char[] buffer;
                    expanded[0] = fullPath;
                    auto pipes = pipeProcess(expanded, Redirect.stdout, this.env.raw, Config.newEnv | Config.suppressConsole, cwd);
                    scope(exit) exitStatus = wait(pipes.pid);
                        
                    while (0 < pipes.stdout.readln(buffer))
                    {
                        write(buffer);
                    }
                }
            }
            catch(CmdException ex)
            {
                // Report and errors thrown by the process
                err_fp.writeln(ex.msg);
                exitStatus = ex.exitCode;
            }
            catch(Exception ex)
            {
                // Report and errors thrown by the process
                err_fp.writeln(ex.msg);
                exitStatus = -1;
            }
        }
      
        return true;
    }
   
    
   /////////////////////////////////////////////////////
   //
   // Is this file an executable script
   //
   // RETURN True is a script file
   //              
   static public bool isScript(string fullPath)
   {
      // Is this executable
      if (!executableFile(fullPath))
      {
         return false;
      }
      
      // Read up to 16 charactor from the file
      File fp;
      fp.open(fullPath, "rb");
      scope(exit) fp.close();
      
      char[16] data;
      fp.rawRead(data);
      
      // Are all the charactor printable ASCII or white space
      foreach (ch; data)
      {
         if (!isGraphical(ch) && !isWhite(ch))
         {
            return false;
         }
      }
      
      return true;
   }
   
   void write(const(char)[] arg ...)
   {
      if (out_buf !is null)
      {
         out_buf.write(arg);
      }
      else
      {
         out_fp.write(arg);out_fp.flush();
      }
   }
   
   void writeln(const(char)[] arg ...)
   {
      if (out_buf !is null)
      {
         out_buf.write(arg);
         out_buf.write(" ");  // Use spaces to separate rather than EOL
      }
      else
      {
         out_fp.writeln(arg);
      }
   }
   
   private string getEnv(const(char)[] name)
   {
      return .getEnv(name, this.env, this.args);
   }
   
   private void setEnv(const(char)[] name, string value)
   {
      .setEnv(name, value, this.env, this.args);
   }
   
   bool first = true;          // Is this the first line of input
   
   OutBuffer       out_buf;
   File            out_fp;
   File            err_fp;
   File            sub_fp;  // Sub-shell input
   File            sub_out; // Sub-shell output
   Pid             sub_pid;
   string[]        sub_shell;
   Env             env;
   string[]        args;
   string          cwd;
   int             exitStatus = 0;
   int             lineNo  = 1;
   
   static immutable char escCh = '%';
}

///////// Commands /////////////////////////////////////////////////////

static this()
{
    Ish.register
    (
        new AsignCmd(),
        new EchoCmd(),
        new WhichCmd(),
        new CdCmd(),
        new MkdirCmd(),
        new RmdirCmd(),
        new TouchCmd(),
        new CopyCmd(),
        new MoveCmd()
    );
}

class AsignCmd : Ish.Command
{
    public bool matchOp (const(char)[] name) {return name == "=";}
    public bool matchCmd(const(char)[] name) {return false;}
        
    public void help()
    {                        
        writeln("<var> = {<value>}");
    }     
       
    public void fullHelp()
    {                        
        help();
    }
        
    public int run(Env env, const(char)[][] items ...)
    {      
        auto name = items[0];
            
        items = items[2..$];
            
        string[] args;
        args.length = items.length;
        foreach (idx, item; items)
        {
            args[idx] = item.idup;
        }
                     
        env.setEnv(name, args);
               
        // No errors
        return 0;
    }
}
     
class EchoCmd : Ish.Command
{
    public bool matchOp (const(char)[] name) {return false;}
    public bool matchCmd(const(char)[] name) {return name == "echo";}
        
    public void help()
    {                        
        writeln("echo {<arg>}");
        writeln("   Write out the list of arguments. Arguments containing");
        writeln("   white space will be quoted.");
    }   
       
    public void fullHelp()
    {                        
        help();
    }
        
    public int run(Env env, const(char)[][] items ...)
    {      
        items = items[1..$];
                     
        if (items.length > 0)
        {	
            if (containsSpaces(items[0]))
            {
                write('\"');
                write(items[0]);
                write('\"');
            }
            else
            {
                write(items[0]);
            }
                  
            foreach(const(char)[] item; items[1..$])
            {
                write(" ");
                if (containsSpaces(item))
                {
                    write('\"');
                    write(item);
                    write('\"');
                }
                else
                {
                    write(item);
                }
            }
        }
        writeln();
               
        // No errors
        return 0;
    }
}
      
class WhichCmd : Ish.Command
{
    public bool matchOp (const(char)[] name) {return false;}
    public bool matchCmd(const(char)[] name) {return name == "which";}
        
    public void help()
    {
        writeln("which {<file>}");
        writeln("   Write out the full path of each executable file."); 
    }   
       
    public void fullHelp()
    {                        
        help();
    }
        
    public int run(Env env, const(char)[][] items ...)
    { 
       items = items[1..$];
                     
        if (items.length > 0)
        {      
            auto fullPath = getFullPath(items[0].idup);
            if (containsSpaces(fullPath))
            {
                write('\"');
                write(fullPath);
                write('\"');
            }
            else
            {
                write(fullPath);
            }
                  
            foreach(const(char)[] item; items[1..$])
            {
                fullPath = getFullPath(item.idup);
                     
                write(" ");
                if (containsSpaces(fullPath))
                {
                    write('\"');
                    write(fullPath);
                    write('\"');
                }
                else
                {
                    write(fullPath);
                }
            }
        }
        writeln();
               
        // No errors
        return 0;
    }
} 
          
class CdCmd : Ish.Command
{
    public bool matchOp (const(char)[] name) {return false;}
    public bool matchCmd(const(char)[] name) {return name == "cd";}
        
    public void help()
    {                        
        writeln("cd <dir>");
        writeln("   Change the current working directory. The environment");
        writeln("   variable PWD is updated to reflext the new directory.");
    }   
       
    public void fullHelp()
    {                        
        help();
    }
        
    public int run(Env env, const(char)[][] items ...)
    {
        items = items[1..$];
               
        if (items.length != 1)
        {  
            // Illeagl args
            throw new Ish.CmdException("cd <dir>", -1); 
        }
        else
        {
            try
            {
                // Try to change directory
                chdir(items[0]);
                env.setEnv("PWD", getcwd());
            }
            catch (Exception ex)
            {
                throw new Ish.CmdException(ex.msg, -1); 
            }
        }
            
        return 0;
    }
}     
      
class MkdirCmd : Ish.Command
{
    public bool matchOp (const(char)[] name) {return false;}
    public bool matchCmd(const(char)[] name) {return name == "mkdir";}
        
    public void help()
    {                        
        writeln("mkdir {<directory>}");
        writeln("   Create the specified directory paths. No error is reported");
        writeln("   if the path already exists.");
    }   
       
    public void fullHelp()
    {                        
        help();
    }
        
    public int run(Env env, const(char)[][] items ...)
    { 
        items = items[1..$];
               
        if (items.length == 0)
        {  
            // Illeagl args
            throw new Ish.CmdException("mkdir {<directory>}", -1);   
        }
        else
        {  
            foreach(const(char)[] item; items[0..$])
            {
                try
                {
                    if (!exists(item) || !isDir(item))
                    {
                       mkdirRecurse(item);
                    }
                }
                catch(Exception ex)
                {
                    // Report and errors thrown by the process
                    throw new Ish.CmdException(ex.msg, -1);   
                }
            }
        }
            
        return 0;
    }
}    
      
class RmdirCmd : Ish.Command
{
    public bool matchOp (const(char)[] name) {return false;}
    public bool matchCmd(const(char)[] name) {return name == "rmdir";}
    public void help()
    {
        writeln("rmdir {<directory>}");
        writeln("   Delete the specified directory (and sub-directries).");
    }   
       
    public void fullHelp()
    {                        
        help();
    }
        
    public int run(Env env, const(char)[][] items ...)
    {
        items = items[1..$]; 

        if (items.length == 0)
        {  
            // Illeagl args
            throw new Ish.CmdException("rmdir {<directory>}", -1);     
        }
        else
        {  
            foreach(const(char)[] item; items[0..$])
            {
                try
                {
                    if (exists(item) && isDir(item))
                    {
                        rmdirRecurse(item);
                    }
                }
                catch(Exception ex)
                {
                    // Report and errors thrown by the process
                    throw new Ish.CmdException(ex.msg, -1);   
                }
            }
        }
            
        return 0;
    }
} 
               
           
               
      
class TouchCmd : Ish.Command
{
    public bool matchOp (const(char)[] name) {return false;}
    public bool matchCmd(const(char)[] name) {return name == "touch";}
        
    public void help()
    { 
        writeln("mkdir {<file>}");
        writeln("   Create the file of update is modified time to the current time.");
    }   
       
    public void fullHelp()
    {                        
        help();
    }
        
    public int run(Env env, const(char)[][] items ...)
    {
        items = items[1..$];
        if (items.length > 0)
        {  
            foreach(const(char)[] item; items[0..$])
            {
                try
                {
                    if (exists(item))
                    {
                        setTimes(item, Clock.currTime, Clock.currTime);
                    }
                    else
                    {
                        File fp;
                        fp.open(item.idup, "w");
                        scope(exit) fp.close();
                    }
                }
                catch(Exception ex)
                {
                    // Report and errors thrown by the process
                    throw new Ish.CmdException("Failed to touch : " ~ item, -1);   
                }
            }
        }
            
        return 0;
    }
} 
            
class CopyCmd : Ish.Command
{
    public bool matchOp (const(char)[] name) {return false;}
    public bool matchCmd(const(char)[] name) {return name == "copy";}
        
    public void help()
    {                        
        writeln("copy <from> <to>");
        writeln("   Copy the file from one location to another."); 
    }   
       
    public void fullHelp()
    {                        
        help();
    }
        
    public int run(Env env, const(char)[][] items ...)
    {
        items = items[1..$];
            
        if (items.length != 2)
        {
            // Illeagl args
            throw new Ish.CmdException("copy <from> <to>", -1);  
        }
        else
        {
            try
            {
                copy(items[0], items[1]);
            }
            catch (Exception ex)
            {
                // Report and errors thrown by the process
                throw new Ish.CmdException(ex.msg, -1);  
            }
        }
            
        return 0;
    }
}    
          
class MoveCmd : Ish.Command
{
    public bool matchOp (const(char)[] name) {return false;}
    public bool matchCmd(const(char)[] name) {return name == "move";}
        
    public void help()
    {
        writeln("move <from> <to>");
        writeln("   Move the file from one location to another.");
    }   
       
    public void fullHelp()
    {                        
        help();
    }
        
    public int run(Env env, const(char)[][] items ...)
    {
        items = items[1..$];
        if (items.length != 2)
        {
            // Illeagl args
            throw new Ish.CmdException("move <from> <to>", -1);
        }
        else
        {
            try
            {
                rename(items[0], items[1]);
            }
            catch (Exception ex)
            {
                // Report and errors thrown by the process 
                throw new Ish.CmdException(ex.msg, -1);  
            }
        }
            
        return 0;
    }
} 




///////// ENVIRONMENT Manipulation /////////////////////////////////////////////////////
   
public string getEnv(const(char)[] name, Env env, string[] args = null)
{
version ( Windows )
{
   // Force the name to uppercase
   name = name.toUpper;
}
   if ((args != null) && allDigits(name))
   {
      auto idx = to!int(name);
      
      if (idx < args.length)
      {
         return args[idx];
      }
      else
      {
         return "";
      }
   }
   else
   {
      // Expand the names environment variable
      return env.getEnv(name);
   }
}


   
public void setEnv(const(char)[] name, string value, ref Env env, ref string[] args)
{
version ( Windows )
{
   // Force the name to uppercase
   name = name.toUpper;
}
   if ((args != null) && allDigits(name))
   {
      auto idx = to!int(name);
      
      if (args.length < idx)
      {
         args.length = idx+1;
      }
      args[idx] = value;
   }
   else
   {
      env.setEnv(name, value);
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

public string tempFile()
{
   // TODO
   return tempDir() ~ "/fred";
}   

private bool containsSpaces(const(char)[] text)
{
  foreach(char ch; text)
  {
     if (isWhite(ch))
     {
        return true;
     }
  }
      
  return false;
}

   
      
string buildPath(string path, string name)
{
    if (absolutePath(path))
    {
        // Absolute path
        return path ~ "/" ~ name;
    }
    else
    {
        // Relative path
        return getcwd() ~ "/" ~ path ~ "/" ~ name;
    }
}
   
   
bool absolutePath(const(char)[] name)
{
    Url tmp = name;
    return ((tmp.path.length > 0) && ((tmp.scheme.length == 1) || (tmp.path[0] == '/')));
}
   
   
bool executableFile(const(char)[] name)
{
    bool exe = (exists(name) && isFile(name));
    return exe;
}
     
   
/////////////////////////////////////////////////////
//
// Find the absolute full path to the executable
//
// RETURN The full path
//
public string getFullPath(string name, Env env = thisEnv)
{
    string tmp;
    version ( Windows )
    {
        // If this does not have a suffix then add '.exe'
        if (extension(name) == "")
        {
            name = name ~ ".exe";
        }
    }
      
    // Check for an absolute path
    if (absolutePath(name))
    {
        // Absolute path
        return name;
    }
      
    // Is the path specified
    foreach (ch; name)
    {
        if ((ch == '/') || (ch == '\\'))
        {
            tmp = getcwd() ~ "/" ~ name;
            if (executableFile(tmp))
            {
                return tmp;
            }
            else
            {
                return "";
            }
        }
    }
      
    version ( Windows )
    {
        immutable(char) psep = ';';
      
        string[] varList1 =
        [
            "PROGRAMFILES",
            "PROGRAMFILES(X86)",
            "PROGRAMW6432",
            "COMMONPROGRAMFILES",
            "COMMONPROGRAMFILES(X86)",
            "COMMONPROGRAMW6432"
        ];
      
        string[] varList2 =
        [
            "WINDIR",
            "SystemRoot"
        ];
         
        // The directory from which the application loaded.
        tmp = thisExePath() ~ "/" ~ name;
        if (executableFile(tmp))
        {
            return tmp;
        }
      
        // The current directory for the parent process.
        tmp = getcwd() ~ "/" ~ name;
        if (executableFile(tmp))
        {
            return tmp;
        }
      
        foreach(envVar; varList1)
        {
            tmp = .getEnv(envVar, env);
            if (tmp.length > 0)
            {
                foreach (tmp1; dirEntries(tmp,name,SpanMode.depth))
                {
                    if (executableFile(tmp1))
                    {
                      return tmp1;
                    }
                }
            }
        }
      
        foreach(envVar; varList2)
        {
            tmp = .getEnv(envVar, env);
            if (tmp.length > 0)
            {
                foreach (tmp1; dirEntries(tmp ~ "/System32",name,SpanMode.depth))
                {
                    if (executableFile(tmp1))
                    {
                        return tmp1;
                    }
                }
            }
        }
    }
    else
    {
        immutable(char) psep = ':';
    }

    // The directories listed in the PATH environment variable.
    auto path = env.getEnv("PATH");
      
    int i = 0;
    while (i < path.length)
    {
        if (path[i] == psep)
        {
            // Is a path specified
            if (i > 0)
            {
                // Combine this with the file name and check if it is an executable
                tmp = buildPath(path[0..i], name);
                if (executableFile(tmp))
                {
                  return tmp;
                }
            }
            
            // Strip this element out
            path = path[i+1.. $];
            i = 0;
        }
        else
        {
            i++;
        }
    }
      
    // Check any remaining path
    if (path.length > 0)
    {
        tmp = buildPath(path[0..$], name);
        if (executableFile(tmp))
        {
            return tmp;
        }
    }

    return "";
}


public void passThrough(File from, File to)
{
    pass_through = spawn(&passThroughThread, thisTid);

    // Send the file handles.
    send(pass_through, from.fileno, to.fileno);
}

public int passThroughJoin()
{
    int rtn = -1;
    
    receive(
        (int status)
        {
            rtn = status;
        }
    );
    
    return rtn;
}


private Tid pass_through;
  
private void passThroughThread(Tid ownerTid)
{
    // Get the in and out file handles.
    File inFile;
    File outFile;
    receive(
        (int from, int to)
        {
            inFile.fdopen(from, "r");
            outFile.fdopen(to, "w");
        }
    );
           outFile.writeln("check2");
    try
    { 
        char[1] buffer;
        while (inFile.isOpen() && !inFile.eof())
        {
           outFile.rawWrite(inFile.rawRead(buffer));
        }
    }
    catch
    {
    }
    
    inFile.close();
    //outFile.close();
    
    writeln("out2");
    send(ownerTid, 1);
    writeln("out3");
 }


