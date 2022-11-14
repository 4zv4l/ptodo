# ptodo
todo parser/list in Perl  
Will generate a TODO.md that will contains all the TODO found in a project  
The script keeps track if a TODO is done or undone.
# Usage
```
ptodo [OPTIONS] [Directory]

OPTIONS:
   -h              show this help
   -p              show undone tasks after analyse
   -x              do not append previous matching .todoignore
Directory:
   The Directory to analyse
Ignore:
   Can write a [Directory]/.todoignore
   Which contains files/extensions
   to skip when generating the TODO.md
Backup:
   In case something went wrong a backup of
   your previous `TODO.md` will be made as `.TODO.md.bak`
```
# Ignore
If you add a .todoignore in your project directory after running the script,  
the files skipped won't be removed automatically from the `TODO.md`  
except if you use the option `-x`.
# Backup
In case something went wrong a backup of your previous `TODO.md` will be made as `.TODO.md.bak`.
