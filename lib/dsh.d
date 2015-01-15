import std.stdio;
import std.container;
import std.ascii;  // ASCII support
//import std.uni;  // Unicode support


public class Dsh
{
  /////////////////////////////////////////////////////
  //
  // Create a dsh interpreter
  //
  this(File out_fp, File err_fp, string[string] env)
  {
  }
  
  /////////////////////////////////////////////////////
  //
  // Create a dsh interpreter where standard output is
  // returned as a string.
  //
  this(inout string out_fp, File err_fp, string[string] env)
  {
  }
  
  /////////////////////////////////////////////////////
  //
  // Execute one of more dsh commands.
  //
  // RETURN False is returned in the shell exits
  //
  bool run(const(char)[] command)
  {
    enum state
    {
      SPACE,
      ARG,
      DOUBLE_QUOTE,
      BACK_QUOTE
    };
    
    auto parseState = state.SPACE;
    
    char[]   entry;
    string[] line;
    bool     more = true;
    
    // Create a stack of input sources
    auto inputs = new SList!(const (char)[])();
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
	  if (entry.length > 0)
	  {
	    line ~= entry.idup;
	    entry = entry[0..0];
	  }
	  parseState = state.SPACE;
	    
	  // Process the line
	  more = process(line);
	  line = line[0..0];
	  
	  if ((input.length > 1) && (input[1] == '\n'))
	  {
	    // Consume the '\r' so the '\n' is also consumed
	    input = input[1..$];
	  }
	}
	else if (input[0] == '\n')
	{
	  // EOL
	  if (entry.length > 0)
	  {
	    line ~= entry.idup;
	    entry = entry[0..0];
	  }
	  parseState = state.SPACE;
	    
	  // Process the line
	  more = process(line);
	  line = line[0..0];
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
	      else if (input[0] == '\\')
	      {
		if (input.length > 1)
		{
		  // Illegal quote
		}
		else
		{
		  // Consume the escape
		  input = input[1..$];
		
		  entry ~= input[0];
		  parseState  = state.ARG;		
		}
	      }
	      else
	      {
		// Clear the entry and add to the entry
		entry ~= input[0];
		parseState  = state.ARG;
	      }
	      break;
	      
	    case state.ARG: // argument
	      if (isWhite(input[0]))
	      {
		// End of the entry
		line ~= entry.idup;
		entry = entry[0..0];
		parseState = state.SPACE;
	      }
	      else if (input[0] == '\"')
	      {
		// End of the entry
		line ~= entry.idup;
		entry = entry[0..0];
		
		// Consume the start quote
		parseState = state.DOUBLE_QUOTE;
	      }
	      else if (input[0] == '`')
	      {
		// End of the entry
		line ~= entry.idup;
		entry = entry[0..0];
		
		// Consume the start quote
		parseState = state.BACK_QUOTE;
	      }
	      else if (input[0] == '\\')
	      {
		if (input.length > 1)
		{
		  // Illegal quote
		}
		else
		{
		  // Consume the escape
		  input = input[1..$];
		
		  entry ~= input[0];
		}
	      }
	      else
	      {
		// Clear the entry and add to the entry
		entry ~= input[0];
	      }
	      break;
	      
	    case state.DOUBLE_QUOTE: // quote
	      break;
	      
	    case state.BACK_QUOTE: // operation
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
    if (entry.length > 0)
    {
      line ~= entry.idup;
      entry = entry[0..0];
    }
    
    // Process the line
    more = process(line);
    line = line[0..0];
    
    return more;
  }
  
  /////////////////////////////////////////////////////
  //
  // Process shell command
  //
  // RETURN False is returned in the shell exits
  //
  private bool process(string[] line)
  {
    foreach(string entry; line)
    {
      writeln(entry);
    }
    
    return true;
  }
  
  int ExitStatus()
  {
    return 0;
  }
  
}