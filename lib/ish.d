import std.stdio;
import std.container;
import std.ascii;  // ASCII support
//import std.uni;  // Unicode support
import std.process; 
import std.conv; 
import std.outbuffer; 
import std.file; 
import std.datetime;


public class Ish
{
   /////////////////////////////////////////////////////
   //
   // Create a ish interpreter
   //
   this(File out_fp, File err_fp, string[string] env, string cwd = getcwd())
   {
      this.first    = true;
      this.out_fp   = out_fp;
      this.err_fp   = err_fp;
      this.env      = env;
      this.cwd      = cwd;
      env["PWD"]    = cwd;
   }
   
   /////////////////////////////////////////////////////
   //
   // Create a ish interpreter
   //
   this(OutBuffer out_buf, File err_fp, string[string] env, string cwd = getcwd())
   {
      this.first    = true;
      this.out_buf  = out_buf;
      this.err_fp   = err_fp;
      this.env      = env;
      this.cwd      = cwd;
      env["PWD"]    = cwd;
   }
   
   public int ExitStatus()
   {
      // Is there a sub-shell
      if (sub_fp.isOpen())
      {
         sub_fp.close();
         this.exitStatus = wait(this.sub_pid);
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
      
      char[]    entry;
      Element[] line;
      bool      more    = true;
      bool      lineEnd = false;  // Are we at the end of a line
      
      // Is this the first input line
      if (this.first)
      {
         first = false;
         
         if (input.length > 2)
         {
            // Does the line start with a hash bang
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
         
         auto rtn = tryWait(this.sub_pid);
         if (rtn.terminated)
         {
            sub_fp.close();
            more            = false;
            this.exitStatus = rtn.status;
         }
      }
      
      while (more && (input.length > 0))
      {
         if (input[0] == '\r')
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
               more = eol(parseState, line, entry);
            }
            
            entry = entry[0..0];
            line  = line [0..0];
            
            if ((input.length > 1) && (input[1] == '\n'))
            {
               // Consume the '\r' so the '\n' is also consumed
               input = input[1..$];
            }
         
            lineNo  += 1;
            lineEnd  = true;
         }
         else if (input[0] == '\n')
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
               more = eol(parseState, line, entry);
            }
            
            entry = entry[0..0];
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
                  if (isWhite(input[0]))
                  {
                     // Consume the white space
                  }
                  else if (input[0] == '\"')
                  {
                     // Consume the start quote
                     parseState = state.DOUBLE_QUOTE;
                  }
                  else if (input[0] == '`')
                  {
                     // Consume the start quote
                     parseState = state.BACK_QUOTE;
                  }
                  else if (input[0] == ';')
                  {
                     // EOL
                     more = eol(parseState, line, entry);
                     entry = entry[0..0];
                     line  = line [0..0];
                  }
                  else if (input[0] == '\\')
                  {
                     if (input.length < 2)
                     {
                        // Illegal escape sequence
                     }
                     else
                     {
                        // Consume the escape
                        input = input[1..$];
                     
                        // Add to the entry
                        switch(input[0])
                        {
                           case 'n':
                              entry ~= '\n';
                              break;
                           
                           case 'r':
                              entry ~= '\r';
                              break;
                           
                           case 't':
                              entry ~= '\t';
                              break;
                           
                           default:
                              entry ~= input[0];
                              break;
                        }
                        parseState  = state.ARG;		
                     }
                  }
                  else
                  {
                     // Add to the entry
                      entry ~= input[0];
                     
                     parseState  = state.ARG;
                  }
                  break;
                  
               case state.ARG: // argument
                  if (isWhite(input[0]))
                  {
                     // End of the entry
                     line ~= Element(this, parseState, entry);
                     entry = entry[0..0];
                     parseState = state.SPACE;
                  }
                  else if (input[0] == '\"')
                  {
                     // End of the entry
                     line ~= Element(this, parseState, entry);
                     entry = entry[0..0];
                     
                     // Consume the start quote
                     parseState = state.DOUBLE_QUOTE;
                  }
                  else if (input[0] == '`')
                  {
                     // End of the entry
                     line ~= Element(this, parseState, entry);
                     entry = entry[0..0];
                     
                     // Consume the start quote
                     parseState = state.BACK_QUOTE;
                  }
                  else if (input[0] == ';')
                  {
                     // EOL
                     more = eol(parseState, line, entry);
                     entry = entry[0..0];
                     line  = line [0..0];
                  }
                  else if (input[0] == '\\')
                  {
                     if (input.length < 2)
                     {
                        // Illegal escape sequence
                     }
                     else
                     {
                        // Consume the escape
                        input = input[1..$];
                     
                        // Add to the entry
                        switch(input[0])
                        {
                           case 'n':
                           entry ~= '\n';
                           break;
                           
                           case 'r':
                           entry ~= '\r';
                           break;
                           
                           case 't':
                           entry ~= '\t';
                           break;
                           
                           default:
                           entry ~= input[0];
                           break;
                        }		
                     }
                  }
                  else
                  {
                     // Add to the entry
                     entry ~= input[0];
                  }
                  break;
                  
               case state.DOUBLE_QUOTE: // quote
                  if (input[0] == '\"')
                  {
                     // End of the entry
                     line ~= Element(this, parseState, entry);
                     entry = entry[0..0];
                     
                     // Consume the end quote
                     parseState = state.SPACE;
                  }
                  else if (input[0] == '\\')
                  {
                     if (input.length < 2)
                     {
                        // Illegal escape sequence
                     }
                     else
                     {
                        // Consume the escape
                        input = input[1..$];
                     
                        // Add to the entry
                        switch(input[0])
                        {
                           case 'n':
                           entry ~= '\n';
                           break;
                           
                           case 'r':
                           entry ~= '\r';
                           break;
                           
                           case 't':
                           entry ~= '\t';
                           break;
                           
                           default:
                           entry ~= input[0];
                           break;
                        }		
                     }
                  }
                  else
                  {
                     // Add to the entry
                     entry ~= input[0];
                  }
                  break;
                  
               case state.BACK_QUOTE: // operation
                  if (input[0] == '`')
                  {
                     // End of the entry
                     line ~= Element(this, parseState, entry);
                     entry = entry[0..0];
                     
                     // Consume the end quote
                     parseState = state.SPACE;
                  }
                  else
                  {
                     // Add to the entry
                     entry ~= input[0];
                  }
                  break;
                  
               default:
                  // Illegal state - TODO
                  break;
            }
         }
         
         // Remove the charactor that has now been processed
         input = input[1..$];
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
      else if (line.length > 0)
      {
         more = eol(parseState, line, entry);
      }
      else
      {
         // Nothing to do
      }
      
      entry = entry[0..0];
      line  = line [0..0];
      
      if (!lineEnd)
      {
         // Implicit line ens at the end of the input
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
      
      const(char)[][] args;
      
      // This must start with an absolute path
      if (
          (input.length >= 2) &&
          (
           (input[0] == '/')  ||
           (isAlpha(input[0]) && (input[1] == ':'))
          )
         )
      {
         while (input.length > 0)
         {
            int i = 0;
            while ((i < input.length) && !isWhite(input[i])) i++;
            args ~= input[0..i];
            input = input[i..$];
            
            // Remove any white space
            while ((input.length > 0) && isWhite(input[i]))
            {
               if (input[0] == '\r')
               {
                  // This is the end of the first line
                  input = input[1..$];
                  
                  if ((input.length > 0) && (input[0] == '\n'))
                  {
                     input = input[1..$];
                  }
                  break;
               }
               else if (input[0] == '\n')
               {
                  // This is the end of the first line
                  input = input[1..$];
                  break;
               }
               else
               {
                  // Strip the white space
                  input = input[1..$];
               }
            }
         }
         
         try
         {
            auto pipes = pipeProcess(args, Redirect.stdin, this.env, Config.newEnv | Config.suppressConsole, cwd);
            this.sub_pid = pipes.pid;
            this.sub_fp  = pipes.stdin;
            
            // Pass through any remaining input
            if (input.length > 0)
            {
               this.sub_fp.writeln(input);
            }
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
         err_fp.writeln("Illegal sub-shell");
         exitStatus = -1;
      }
      
      return more;
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
      more = process(line);
      
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
      const(char)[][] expand()
      {
         switch(type)
         {
            default:
               return [""];  // Should never get here
               
            case state.ARG:      
               return [expandVariables(this.arg)];
               
            case state.DOUBLE_QUOTE:      
               return [expandVariables(this.arg)];
               
            case state.BACK_QUOTE: 
               auto output = new OutBuffer();
               auto shell  = new Ish(output, parent.err_fp, parent.env, parent.cwd);
               
               shell.run(this.arg);
               auto text = output.toString();
               
               const(char)[][] args;
               int s = 0;
               int e = 0;
               while (e < text.length)
               {
                  // Strip white space
                  while ((e < text.length) && isWhite(text[e])) e++;
                  
                  if (e >= text.length)
                  {
                  // The end
                  }
                  else if (text[e] == '\"')
                  {
                  // Quoted argument
                  e++;
                  s = e;
                  while ((e < text.length) && (text[e] != '\"')) e++;
                  
                  args ~= text[s..e];
                  }
                  else
                  {
                  // Unquoted argument
                  s = e;
                  while ((e < text.length) && !isWhite(text[e])) e++;
                  
                  if (s != e)
                  {
                     args ~= text[s..e];
                  }
                  }
               }
               return args;
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
            if (arg[i] != '$')
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
         
         // Expand the names environment variable
         auto p = (nm in parent.env);
         if (p is null)
         {
            return "";
         }
         else
         {
            return *p;
         }
      }
      
      state  type;
      string arg;
      Ish    parent;
   }
   
   /////////////////////////////////////////////////////
   //
   // Process a hell command
   //
   // RETURN False is returned in the shell exits
   //
   private bool process(Element[] line)
   {
      bool more = true;
      
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
                  
         // Process the command
         switch (expanded[0])
         {
            case "exit":
               more = false;
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
               break;
               
            case "echo":
               const(char)[][] items = expanded[1..$];
               
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
               exitStatus = 0;
               break;
               
            case "cd":
               const(char)[][] items = expanded[1..$];
               
               if (items.length != 1)
               {  
                  // Illeagl args
                  err_fp.writeln("cd <dir>");
                  exitStatus = -1;      
               }
               else
               {
                  try
                  {
                     // Try to change directory
                     chdir(items[0]);
                     cwd = getcwd();
                     env["PWD"]   = cwd;
                  }
                  catch (Exception ex)
                  {
                     err_fp.writeln(ex.msg);
                     exitStatus = -1;
                  }
               }
               break;
               
            case "mkdir":
               const(char)[][] items = expanded[1..$];
               
               // No errors
               exitStatus = 0;
               
               if (items.length == 0)
               {  
                  // Illeagl args
                  err_fp.writeln("mkdir {<directory>}");
                  exitStatus = -1;      
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
                        err_fp.writeln(ex.msg);
                        exitStatus = -1;
                     }
                  }
               }
               
               break;
               
            case "help":
               const(char)[][] items = expanded[1..$];
               
               // No errors
               exitStatus = 0;
               
               if (items.length == 0)
               {  
                  writeln("ish version 1.0.0");
                  writeln("help <command>");
               }
               else
               {  
                  switch(items[0])
                  {
                     case "exit":
                        writeln("exit [<exit code>]");
                        writeln("   Terminate the shell returning the given exit code.");
                        writeln("   If no exit code is specified the the exit code of the");
                        writeln("   last command is returned.");
                        break;
                        
                     case "echo":
                        writeln("echo {<arg>}");
                        writeln("   Write out the list of arguments. Arguments containing");
                        writeln("   white space will be quoted.");
                        break;
                        
                     case "cd":
                        writeln("cd <dir>");
                        writeln("   Change the current working directory. The environment");
                        writeln("   variable PWD is updated to reflext the new directory.");
                        break;
                        
                     case "mkdir":
                        writeln("mkdir {<directory>}");
                        writeln("   Create the specified directory paths. No error is reported");
                        writeln("   if the path already exists.");                        
                        break;
                  
                     case "help":
                        writeln("help [<command>]");
                        writeln("   Output help on built is commands.");
                     break;
                  
                     case "touch":
                        writeln("mkdir {<file>}");
                        writeln("   Create the file of update is modified time to the current time.");     
                        
                        break;
                        
                     case "copy":
                        writeln("copy <from> <to>");
                        writeln("   Copy the file from one location to another.");   
                        break;
                        
                     case "move":
                        writeln("move <from> <to>");
                        writeln("   Move the file from one location to another.");                        
                     break;
                     
                     default:
                        break;
                  }
               }
               
               break;
               
            case "touch":
               const(char)[][] items = expanded[1..$];
               
               // No errors
               exitStatus = 0;
               
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
                        err_fp.writeln("Failed to touch : " ~ item);
                        exitStatus = -1;
                     }
                  }
               }
               
               break;
               
            case "copy":
               const(char)[][] items = expanded[1..$];
               
               // No errors
               exitStatus = 0;
               
               if (items.length != 2)
	       {
                  // Illeagl args
                  err_fp.writeln("copy <from> <to>");
                  exitStatus = -1;
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
                     err_fp.writeln(ex.msg);
                     exitStatus = -1;
                  }
               }
               
               break;
               
            case "move":
               const(char)[][] items = expanded[1..$];
               
               // No errors
               exitStatus = 0;
               
               if (items.length != 2)
	       {
                  // Illeagl args
                  err_fp.writeln("move <from> <to>");
                  exitStatus = -1;
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
                     err_fp.writeln(ex.msg);
                     exitStatus = -1;
                  }
               }
               
               break;
               
            default:
               // Execute the command as a program
               try
               {
                  // Use a pipe to capture stdout as text to be processed
                     
                  char[] buffer;
                  auto pipes = pipeProcess(expanded, Redirect.stdout, this.env, Config.newEnv | Config.suppressConsole, cwd);
                  scope(exit) exitStatus = wait(pipes.pid);
                     
                  while (0 < pipes.stdout.readln(buffer))
                  {
                     write(buffer);
                  }
               }
               catch(Exception ex)
               {
                  // Report and errors thrown by the process
                  err_fp.writeln(ex.msg);
                  exitStatus = -1;
               }
               break;
         }
      }
      
      return more;
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
   
   bool containsSpaces(const(char)[] text)
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
   
   bool first;          // Is this the first line of input
   
   OutBuffer      out_buf;
   File           out_fp;
   File           err_fp;
   File           sub_fp; // Sub-shell input
   Pid            sub_pid;
   string[string] env;
   string         cwd;
   int            exitStatus = 0;
   int            lineNo  = 1;
}