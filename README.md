# shstack - Persistent and Easy to Use Stacks Shared Between Shell Sessions

This is an early release.  There are bugs.  Some of them are purely cosmetic.  Some things are actually broken.

shstack lets you push files and directories onto named stacks.  The stacks are stored on the file system and can be manipulated and retrieved by other shell sessions.  

## Known Bugs

 * Some Perl warning messages (the ones I saw didn't cause trouble)
 * `for` and `sfor` don't handle filenames with spaces correctly

## Output of the help command

usage: s <command> [command [[stack] [item(s)]]]

  list    List active stacks, no need to specify a stack
  show    List the items in the named stack
  edit    Opens the stack in $EDITOR

  get     Pretend these aren't stacks, get the top value of a stack
  set     Pretend these aren't stacks, set the top value of a stack

  push    Push an item onto the top of the named stack
  pop     Pop an item off of the top of the named stack
  shift   Shift an item onto the bottom of the named stack
  unshift Unshift an item off of the bottom of the named stack

  print0  Output named stack for piping to xargs -0, stack is unmodified
  push0   push output of find -print0 onto a stack

  for     Execute a command on each item in a stack, stack is unmodified
  sfor    Works like for, but items are removed from stack on command success

  copy    Make a copy of a stack
  delete  Delete a stack

  help    Verbose help for above commands

## Some usage examples

### rsync three directories to two hosts

    wonko@zaphod:~$ s push testHost backup1.patshead.com
    wonko@zaphod:~$ s push testHost backup2.patshead.com
    wonko@zaphod:~$ s show testHost
    backup2.patshead.com
    backup1.patshead.com
    wonko@zaphod:~$ s push testSource /etc
    wonko@zaphod:~$ s push testSource /var/named
    wonko@zaphod:~$ s push testSource /home
    wonko@zaphod:~$ s for echo rsync %testSource% %testHost%:backups/
    rsync /home backup2.patshead.com:backups/
    rsync /home backup1.patshead.com:backups/
    rsync /var/named backup2.patshead.com:backups/
    rsync /var/named backup1.patshead.com:backups/
    rsync /etc backup2.patshead.com:backups/
    rsync /etc backup1.patshead.com:backups/
    wonko@zaphod:~$ 
    
### Ping a list of stored servers

    wonko@zaphod:~$ s show servers
    patshead.com
    openvz1.serverswarm.com
    dns1.serverswarm.com
    dns2.serverswarm.com
    mail.patshead.com
    wonko@zaphod:~$ s for 'echo %servers% `hostup %servers%`' | column -t
    patshead.com             UP
    openvz1.serverswarm.com  UP
    dns1.serverswarm.com     UP
    dns2.serverswarm.com     UP
    mail.patshead.com        UP
    wonko@zaphod:~$ 

### Screen shots

There are a couple of screen shots and some slightly more verbose ramblings about shstack [available on my website](http://blog.patshead.com/2013/05/shstack-persistent-and-easy-to-use-stacks-shared-between-shell-sessions.html)
