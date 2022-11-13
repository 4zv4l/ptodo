# ptodo
todo parser/list in Perl  
Will generate a TODO.md that will contains all the TODO found in a project  
The script keeps track if a TODO is done or undone.
# Usage
```
todo [OPTIONS] [Directory]

OPTIONS:
   -h              show this help
   -p              show undone tasks
Directory:
   The Directory to analyse
Ignore:
   Can write a [Directory]/.todoignore
   That will contain files to ignore
```
for `.todoignore`, if the folder is `project` a file to ignore would be written `project/path/to/file`.
