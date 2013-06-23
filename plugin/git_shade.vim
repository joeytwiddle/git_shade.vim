
command! GitShade call s:GitShade(expand("%"))
"command! GitHighlightRecentLines call s:GitShade(expand("%"))
"command! GitGlowRecentLines call s:GitShade(expand("%"))

function! s:GitShade(filename)

  if !has("gui_running")
    echo "Only works in GUI mode."
    return
  endif

  let cmd = "git blame --line-porcelain -t " . shellescape(a:filename)

  echo "Doing: " . cmd

  let data = system(cmd)

  let lines = split(data,'\n')

  let time = -1
  let nextLine = 0
  let times = []
  for line in lines

    if nextLine
      call add(times, time)
      let nextLine = 0
    else

      let words = split(line,' ')

      if words[0] == "committer-time"
        let time = words[1]
      elseif words[0] == "filename"
        let nextLine = 1
      endif

    endif

  endfor

  "echo "Hopefully " . len(times) . " matches the number of lines in the buffer."

  if line("$") != len(times)
    echo "WARNING: buffer lines " . line("$") . " do not match git blame lines " . len(lines)
  endif

  silent! call clearmatches()

  let curTime = localtime()
  let maxAge = 14.0 * 24.0 * 60.0 * 60.0

  let lineNum = 0
  for timeStr in times
    let lineNum += 1

    let timeNum = str2nr(timeStr)
    let timeSince = curTime - timeNum
    if timeSince < 0
      let timeSince = 0
    endif
    if timeSince > maxAge
      let timeSince = maxAge
    endif
    "let lum = 255.0 / (1.0 + timeSince / 60.0 / 60.0 / 24.0 / 15.0)
    let lum = 255.0 * ( 1.0 - timeSince / maxAge )
    let lum = float2nr(lum)
    let lumHex = printf('%02x', lum)
    "let hlStr = "00" . lumHex . "00"
    "let hlStr = lumHex . "ff" . lumHex
    let hlStr = "0000" . lumHex
    "echo "Hex for age " . timeStr . " is: " . hlStr

    let hlName = "ColoredTime_" . hlStr

    if hlexists(hlName)
      exec "highlight clear " . hlName
    endif
    "exec "highlight " . hlName . " guifg=#" . hlStr . " gui=none"
    exec "highlight " . hlName . " guibg=#" . hlStr

    let pattern = "\\%" . lineNum . "l"

    call matchadd(hlName, pattern)

    "if lineNum > 20
    "  break
    "endif

  endfor

  exec "highlight Normal guibg=black"

  augroup GitShade
    autocmd!
    autocmd BufWinEnter * call clearmatches()
  augroup END

  " TODO: Creating all these pattern matches makes rendering very inefficient.
  " The time taken to render will probably grow linearly with the number of lines in the file (the number of matches we create).
  " To reduce this, we could group together times which are the same, and create just one match for each unique timestamp.
  " Alternatively, we could use the 'signs' column to indicate different ages, and highlight lines through that.

endfunction
