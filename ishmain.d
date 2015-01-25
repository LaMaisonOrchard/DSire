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

    auto env = environment.toAA();
version ( Windows )
{
    env["EXE"] = ".exe";
    env["BAT"] = ".bat";
}
else
{
    env["EXE"] = "";
    env["BAT"] = "";
}
    
    auto shell = new Ish(stdout, stderr, env, getcwd(), args);
    
    foreach (line; input.byLine())
    {
        if (!shell.run(line))
        {
	  break;
	}
    }
    
    return shell.ExitStatus();
}