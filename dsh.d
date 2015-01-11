import std.stdio;

int main(string args[])
{
    int status = 0;
    
    File input = stdin;
    
    if (args.length > 1)
    {
      input.open(args[1], "r");
    }
    scope(exit) input.close();
    
    foreach (line; input.byLine())
    {
        writeln(line);
    }
    
    return status;
}