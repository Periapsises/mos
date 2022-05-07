# The FileSystem

Because garry's mod doesn't allow all extensions to be written, this library simulates additional extenstions.  
It has functions to verify the validity of file extensions, sanitize and desanitize them.

When finding an invalid extention, the filesystem appends `~.txt` at the end.  
The `~` symbol is then used later to determine which part of the file name to hide from the user as well as some of the code.