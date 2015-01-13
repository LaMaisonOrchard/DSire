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
    writeln(command);
    
    char state = ' ';
    
    // Create a stack of input sources
    auto inputs = new Stack!(const (char)[])();
    inputs.push(command);
    
    while (!inputs.empty())
    {
      const (char)[] input = inputs.pop();
      
      while (input.length > 0)
      {
	switch (state)
	{
	  case ' ': // white space
	    break;
	    
	  case '.': // argument
	    break;
	    
	  case '\"': // quote
	    break;
	    
	  case '`': // operation
	    break;
	    
	  default:
	    // Illegal state - TODO
	    break;
	}
	
	input = input[1..$];
      }
    }
    
    //isWhite(command[0]);
    
    return true;
  }
  
  int ExitStatus()
  {
    return 0;
  }
  
}

public class Stack(T)
{
  /////////////////////////////////////////////////////
  //
  // Push an item on to the stack
  //
  void push(T a)
  {
    stack = new elem!(T)(a, stack);
  }
  
  /////////////////////////////////////////////////////
  //
  // Pop an item off the stack. Throws is the stack is empty.
  //
  // RETURN False is returned in the shell exits
  //
  T pop()
  {
    if (empty())
    {
      throw new emptyStack("pop()");
    }
    else
    {
      T rtn = stack.item;
      stack = stack.next();
      return rtn;
    }
  }
  
  T top()
  {
    if (empty())
    {
      throw new emptyStack("top()");
    }
    else
    {
      return stack.item;
    }
  }
    
  bool empty()
  {
    return stack is null;
  }
  
  public class emptyStack : object.Exception
  {
    this(string msg)
    {
      super(msg);
    }
  }
  
  public class stackOverflow : object.Exception
  {
    this(string msg)
    {
      super(msg);
    }
  }
  
  private class elem(T)
  {
    this(T d, elem!(T) n)
    {
      this.data = d;
      this.Next = n;
    }
    
    T        item() {return this.data;}
    elem!(T) next() {return this.Next;}
    
    T        data;
    elem!(T) Next;
  }
  
  elem!(T) stack = null;
}