import std.stdio;
import std.container;
import std.ascii;  // ASCII support
//import std.uni;  // Unicode support
import std.process; 
import std.conv; 
import std.outbuffer; 


public class Dsh
{
  /////////////////////////////////////////////////////
  //
  // Create a dsh interpreter
  //
  this(File out_fp, File err_fp, string[string] env)
  {
    this.out_fp  = out_fp;
    this.err_fp  = err_fp;
    this.env     = env;
  }
  
  /////////////////////////////////////////////////////
  //
  // Create a dsh interpreter
  //
  this(OutBuffer out_buf, File err_fp, string[string] env)
  {
    this.out_buf = out_buf;
    this.err_fp  = err_fp;
    this.env     = env;
  }
  
  /////////////////////////////////////////////////////
  //
  // Execute one of more dsh commands.
  //
  // RETURN False is returned in the shell exits
  //
  bool run(const(char)[] command)
  {
    
    auto parseState = state.SPACE;
    
    char[]    entry;
    Element[] line;
    bool      more = true;
    
    // Create a stack of input sources
    auto inputs = new SList!(const(char)[])();
    inputs.insertFront(command);
    
    while (!inputs.empty())
    {
      const (char)[] input = inputs.front();
      inputs.removeFront();
      
      while (more && (input.length > 0))
      {
	if (input[0] == '\r')
	{
	  // EOL
	  more = eol(parseState, line, entry);
	  entry = entry[0..0];
	  line  = line [0..0];
	  
	  if ((input.length > 1) && (input[1] == '\n'))
	  {
	    // Consume the '\r' so the '\n' is also consumed
	    input = input[1..$];
	  }
	}
	else if (input[0] == '\n')
	{
	  // EOL
	  more = eol(parseState, line, entry);
	  entry = entry[0..0];
	  line  = line [0..0];
	}
	else
	{
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
		  entry ~= input[0];
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
		line ~= Element(parseState, entry);
		entry = entry[0..0];
		parseState = state.SPACE;
	      }
	      else if (input[0] == '\"')
	      {
		// End of the entry
		line ~= Element(parseState, entry);
		entry = entry[0..0];
		
		// Consume the start quote
		parseState = state.DOUBLE_QUOTE;
	      }
	      else if (input[0] == '`')
	      {
		// End of the entry
		line ~= Element(parseState, entry);
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
		  entry ~= input[0];
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
		line ~= Element(parseState, entry);
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
		  entry ~= input[0];
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
		line ~= Element(parseState, entry);
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
		  entry ~= input[0];
		}
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
	
	//write(input[0]);
	input = input[1..$];
      }
    }
    
    // EOL
    more = eol(parseState, line, entry);
    entry = entry[0..0];
    line  = line [0..0];
    
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
	line ~= Element(parseState, entry);
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
    this(state type, const(char)[] arg)
    {
      this.type = type;
      this.arg  = arg.idup;
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
      const(char)[] rtn;
      
      rtn = expandVariables(this.arg);
      
      switch(type)
      {
	default:
	  return [""];  // Should never get here
	  
	case state.ARG:      
	  return [rtn];
	  
	case state.DOUBLE_QUOTE:      
	  return [rtn];
	  
	case state.BACK_QUOTE:      
	  return [rtn];
      }
    }
    
    const(char)[]expandVariables(const(char)[] arg)
    {
      // STUB
      return  arg;
    }
    
    state  type;
    string arg;
  };
  
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
	  else
	  {
	    // The default is no error
	    exitStatus = 0;
	  }
	  break;
	  
	case "echo":
	  const(char)[][] items = expanded[1..$];
	  
	  if (out_buf !is null)
	  {
	    if (items.length > 0)
	    {	
	      out_buf.write(items[0]);
	      foreach(const(char)[] item; items[1..$])
	      {
		out_buf.write(" ");
		out_buf.write(item);
	      }
	    }
	  }
	  else
	  {
	    if (items.length > 0)
	    {	
	      out_fp.write(items[0]);
	      foreach(const(char)[] item; items[1..$])
	      {
		out_fp.write(" ");
		out_fp.write(item);
	      }
	    }
	    out_fp.writeln();
	  }
	  
	  // No errors
	  exitStatus = 0;
	  break;
	  
	default:
	  // Excute the command as a program
	  try
	  {
	    if (out_buf !is null)
	    {
	      // Use a pipe to capture stdout as text to be processed
	      
	      char[] buffer;
	      auto pipes = pipeProcess(expanded, Redirect.stdout);
	      scope(exit) wait(pipes.pid);
	      
	      while (0 < pipes.stdout.readln(buffer))
	      {
		out_buf.write(buffer);
	      }
	    }
	    else
	    {
	      // Run the program passing on the stdout
	      auto pid   = spawnProcess(expanded, stdin, out_fp, err_fp, env);
	      exitStatus = wait(pid);
	    }
	  }
	  catch(Exception ex)
	  {
	    // Report and errors thrown by the process
	    err_fp.writeln(ex.msg);
	  }
	  break;
      }
    }
    
    return more;
  }
  
  int ExitStatus()
  {
    return exitStatus;
  }
  OutBuffer      out_buf;
  File           out_fp;
  File           err_fp;
  string[string] env;
  int            exitStatus = 0;
}