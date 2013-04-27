_stack() {
  local i

  if (( CURRENT == 2 )); then
    compadd $(s commands)
  fi

  if (( CURRENT == 3 )); then
    for i in list show edit get set push pop shift unshift print0 copy delete drop; do
      if [[ $words[2] == $i ]]; then
        compadd $(s stacks)
      fi
    done
  fi

  if (( CURRENT == 4 )); then
    for i in copy; do
      if [[ $words[2] == $i ]]; then
        compadd $(s stacks)
      fi
    done

    for i in set push shift; do
      if [[ $words[2] == $i ]]; then
        _files
      fi
    done

    
  fi
}

compdef _stack s
