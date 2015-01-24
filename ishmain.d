import std.stdio;
import std.process;
import std.file; 
import ish;

int main(string args[])
{
    int status = 0;
    
    File input = stdin;
    
    if (args.length > 1)
    {
      input.open(args[1], "r");
    }
    scope(exit) input.close();
    
    auto shell = new Ish(stdout, stderr, environment.toAA(), getcwd(), args);
    
    foreach (line; input.byLine())
    {
        if (!shell.run(line))
        {
	  break;
	}
    }
    
    return shell.ExitStatus();
}