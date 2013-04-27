#! /usr/bin/perl

use strict;
use warnings;

use File::Temp qw/tempfile/;
use File::Spec;
use Storable qw(lock_nstore lock_retrieve);

my $pairs;
my $stackfile = glob('~/.stack');

$pairs=lock_retrieve($stackfile) if ( -e $stackfile );

my %dispatch = (
  'commands' => \&command_commands,
  'stacks' => \&command_stacks,
  'list' => \&command_list,
  'show' => \&command_show,
  'edit' => \&command_edit,
  'get' => \&command_get,
  'set' => \&command_set,
  'push' => \&command_push,
  'push0' => \&command_push0,
  'pop' => \&command_pop,
  'shift' => \&command_shift,
  'unshift' => \&command_unshift,
  'print0' => \&command_print0,
  'for' => \&command_for,
  'sfor' => \&command_sfor,
  'copy' => \&command_copy,
  'delete' => \&command_delete,
  'drop' => \&command_delete,
  'help' => \&command_help,
 );

my $command=shift;

dispatch();

sub command_commands {               #for zsh tab completion
  print join "\n", keys %dispatch;
  print "\n";
}

sub command_edit {
  my $key=shift @ARGV;
  my ($fh, $filename) = tempfile();

  if ($key) {
    print $fh join "\n", @{$pairs->{$key}};
    system($ENV{'EDITOR'}, $filename);
    $fh->seek(0, 0);

    delete $pairs->{$key};

    while (<$fh>) {
      chomp;
      push @{$pairs->{$key}}, $_ if ($_ ne '');
    }
    unlink $fh;
  }
}

sub command_stacks {
  my $key=shift @ARGV;

  for my $key (keys %$pairs) {
    print "$key\n";
  }

  exit;
}

sub command_list {
  my $key=shift @ARGV;

  for my $key (keys %$pairs) {
    print "$key (" . @{$pairs->{$key}} . ")\n";
  }

  exit;
}

sub command_set {
  my $key=shift @ARGV;

  if (filecheck()) {
    for (@ARGV) {
      @{$pairs->{$key}}[0]=File::Spec->rel2abs($_);
    }
  } else {
    @{$pairs->{$key}}[0]=join ' ', @ARGV;
  }

}

sub command_push0 {
  my $key=shift @ARGV;

  local $/="\0";
  while (<>) {
    unshift @{$pairs->{$key}}, $_;
  }
}

sub command_push {
  my $key=shift @ARGV;
  if (filecheck()) {
    for (@ARGV) {
      unshift @{$pairs->{$key}}, File::Spec->rel2abs($_);
    }
  } else {
    unshift @{$pairs->{$key}}, join ' ', @ARGV;
  }

}

sub command_unshift {
  my $key=shift @ARGV;
  if (filecheck()) {
    for (@ARGV) {
      push @{$pairs->{$key}}, File::Spec->rel2abs($_);
    }
  } else {
    push @{$pairs->{$key}}, join ' ', @ARGV;
  }

}

sub command_get {
  my $key=shift @ARGV;

  if (@{$pairs->{$key}}) {
    print @{$pairs->{$key}}[0], "\n";
  }

}

sub command_pop {
  my $key=shift @ARGV;

  if (@{$pairs->{$key}}) {
    print shift @{$pairs->{$key}}, "\n";
  }

}

sub command_shift {
  my $key=shift @ARGV;

  if (@{$pairs->{$key}}) {
    print pop @{$pairs->{$key}}, "\n";
  }

}

sub command_print0 {
  my $key=shift @ARGV;

  if (@{$pairs->{$key}}) {
    print join "\0", @{$pairs->{$key}};
  }

}

sub command_show {
  my $key=shift @ARGV;

  if ($key) {
    if (@{$pairs->{$key}}) {
      print join "\n", @{$pairs->{$key}};
      print "\n";
    }
  } else {
    for my $k (keys %$pairs) {
      print "$k:\n";
      for my $i (0 .. $#{$pairs->{$k}}) {
          printf "  %3d: %-72s\n", $i, $pairs->{$k}->[$i];
        }
    }
  }

}

sub command_copy {
  my $key=shift @ARGV;

  if (@{$pairs->{$key}}) {
    open(my $clipboard, "| xclip") or die 'xclip not available';
    print $clipboard join "\n", @{$pairs->{$key}};
    print $clipboard "\n";
    close($clipboard);
  }

}

sub command_delete {
  my $key=shift @ARGV;
  delete $pairs->{$key};
}

sub command_for {
  my $forCommand=join ' ', @ARGV;
  my @keys=findKeys($forCommand);

  forLoop(\@keys, 0, $forCommand);
  exit;
}

sub command_sfor {
  my $key=shift @ARGV;
  my @failures;

  if (@{$pairs->{$key}}) {
    for (@{$pairs->{$key}}) {
      my $forCommand=join ' ', @ARGV;
      $forCommand =~ s/%%/$_/g;
      $forCommand =~ s/{}/$_/g;
      print "$_: ";
      system($forCommand);
      push @failures, $_ if $? != 0;
    }
  }

  if (@failures > 0) {
    $pairs->{$key}=\@failures;
  } else {
    delete $pairs->{$key};
  }

}



sub filecheck {
  for (@ARGV) {
    return undef unless (-e $_);
  }
  return 1;
}

sub findKeys {
  my $command=shift;
  my %keys;

  while ($command =~ /%(.+?)%/gc) {
    if ($pairs->{$1}) {
      $keys{$1}++;
    } else {
      print "Stack named '$1' not found\n";
      exit 1;
    }
  }

  return keys %keys;
}

sub forLoop {
  my $keys=shift;
  my $index=shift;
  my $forCommand=shift;

  for my $x (0 .. $#{$pairs->{$keys->[$index]}}) {
    my $command=$forCommand;
    my $sub=quotemeta($pairs->{$keys->[$index]}->[$x]);

    $command =~ s/%$keys->[$index]%/$sub/g;

    if ($index == $#{$keys}) {
      system($command);
    } else {
      forLoop($keys, $index + 1, $command);
    }

  }
}

sub dispatch {
  for (sort keys %dispatch) {
    if (fuzzy_match($command, $_)) {
      $dispatch{$_}->();
      lock_nstore $pairs, $stackfile;
      exit;
    }
  }
  command_help();
  exit;
}

sub fuzzy_match {
  my ($strA, $strB)=@_;
  my $regex='^';

  for (split '', $strA) {
    $regex .= "$_.*";
  }
  return $strB =~ /$regex/;
}

sub command_help {
  print <<END;
usage: s <command> [command [[stack] [item(s)]]]

  list    List active stacks, no need to specify a stack
  show    List the items in the named stack
  edit    Opens the stack in \$EDITOR

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

END
}


