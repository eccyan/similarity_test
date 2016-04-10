# Disable buffer
def dev_null(buffer=STDOUT)
  original = buffer.dup # does a dup2() internally
  buffer.reopen '/dev/null', 'w'
  yield
ensure
  buffer.reopen original
end
