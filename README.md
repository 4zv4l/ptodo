# ptodo
todo parser/list in Perl  
Will generate a TODO.md that will contains all the TODO found in a project  
The script keeps track if a TODO is done or undone.
# Usage
```
ptodo [OPTIONS] [Directory]

OPTIONS:
   -h              show this help
   -p              show undone tasks
Directory:
   The Directory to analyse
Ignore:
   Can write a [Directory]/.todoignore
   Which contains files/extensions
   to skip when generating the TODO.md
```
# Ignore
If you add a .todoignore in your project directory after running the script,  
the files skipped won't be removed automatically from the `TODO.md`
