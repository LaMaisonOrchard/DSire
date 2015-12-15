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

import std.parallelism;
import std.file;
import std.datetime;

class RuleSet
{
    this()
    {
       SetFileDate("FORCE", long.max);
    }

    /**********************************
    * Find rule (if any) in the RuleSet that matches this name.
    */
    Rule LookUp(string name)
    {
       foreach (rule; ruleSet)
       {
          if (rule.Match(name))
          {
              return rule;
          }
       }

       return null;
    }

    /**********************************
    * Append a rule to the rule set 
    */
    void Append(Rule rule)
    {
        ruleSet ~= rule;
        rule.Parent(this);
    }

    long LookUpFileDate(string name, bool wait)
    {
       if (null == (name in fileInfo))
       {
           // Date undefined
           return (-1);
       }
       else
       {
           if (wait && (fileInfo[name].date == 0))
           {
               fileInfo[name].task.Wait();
               fileInfo[name] = FileData(GetFileDate(name));
           }

           return fileInfo[name].date;
       }
    }

    void SetFileDate(string name, long date)
    {
        fileInfo[name] = FileData(date);
    }

    void SetFileDate(string name, BuildTask task)
    {
        fileInfo[name] = FileData(task);
    }

    private struct FileData
    {
       public this(long date)
       {
          this.date = date;
       }

       public this(BuildTask task)
       {
          this.date = 0;
          this.task = task;
       }

       public long      date = -1;
       public BuildTask task;
    }

    private Rule[] ruleSet;
    private FileData[string] fileInfo;
}


class Rule
{
    /**********************************
    * Inform the rule of its containing RuleSet.
    */
    private void Parent(RuleSet set)
    {
       ruleSet = set;
    }


    /**********************************
    * Does this file match this rule.
    */
    bool Match(string name)
    {
        return false;  // TODO - Implement
    }

    string[] Dependents(string target)
    {
       return string[].init;
    }

    /**********************************
    * Apply this rule to the given target.
    */
    void Process(string target)
    {
       Rule rule;
       auto deps = Dependents(target);

       // Update a dependent files
       foreach (dep; deps)
       {
          long date = ruleSet.LookUpFileDate(dep, false);
          if (date >= 0)
          {
              // File up to date;
          }
          else if (null is (rule = ruleSet.LookUp(dep)))
          {
             if (exists(dep))
             {
                ruleSet.SetFileDate(dep, GetFileDate(dep));
             }
             else
             {
                // TODO fail - missing file
             }
          }
          else
          {
             rule.Process(dep);
          }
       }

       // Check the dates of the dependents
       long depDate = -1;
       foreach (dep; deps)
       {
          long date = ruleSet.LookUpFileDate(dep, true);
          if (date > depDate)
          {
              depDate = date;
          }
       }
       
       if (exists(target))
       {
          SysTime accessTime;
          SysTime modificationTime;
          getTimes(target, accessTime, modificationTime);

          if (depDate > modificationTime.toUnixTime())
          {
             // The file is out of date so try to update it - TODO
             ruleSet.SetFileDate(target, new BuildTask("", target, string[].init, string[string].init));
          }
       }
       else
       {
          // The file does not exist so try to create it - TODO
          ruleSet.SetFileDate(target, new BuildTask("", target, string[].init, string[string].init));
       }
    }

    RuleSet ruleSet;
}

class BuildTask
{
    this(string script, string name, string[] deps, string[string] env)
    {
        // TODO - Run the build either here or in a task
    }


    /*************************************
     * Wait for the task to complete
     */
    void Wait()
    {
    }

    //Task task;
}

/**********************************************
 * Get the modified date for the file or if the
 * file does not exist the current time.
 */
long GetFileDate(string name)
{
   if (exists(name))
   {
      SysTime accessTime;
      SysTime modificationTime;
      getTimes(name, accessTime, modificationTime);

      return modificationTime.toUnixTime();
   }
   else
   {
      return Clock.currTime.toUnixTime();
   }
}
