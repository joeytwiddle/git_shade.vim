" git_shade.vim - Colors lines in different intensities according to their age in git's history
" Run :GitShade to shade the file.  Switch buffer or :e the file to remove the shading.

" === Options ===

if !exists("g:GitShade_ColorGradient") || !exists("g:GitShade_ColorWhat")
  let g:GitShade_ColorGradient = "black_to_blue"
  let g:GitShade_ColorWhat = "bg"
  "let g:GitShade_ColorGradient = "green_to_white"
  "let g:GitShade_ColorWhat = "fg"
endif

" === Commands ===

command! GitShade call s:GitShade(expand("%"))
"command! GitHighlightRecentLines call s:GitShade(expand("%"))
"command! GitGlowRecentLines call s:GitShade(expand("%"))

" === Script ===

function! s:GitShade(filename)

  if !has("gui_running")
    echo "Only works in GUI mode."
    return
  endif

  let cmd = "git blame --line-porcelain -t " . shellescape(a:filename)

  echo "Doing: " . cmd

  let data = system(cmd)

  let lines = split(data,'\n')

  let times = []
  let earliestTime = localtime()
  let latestTime = 0

  let timeNum = -1
  let nextLineIsContent = 0
  for line in lines

    if nextLineIsContent
      call add(times, timeNum)
      let nextLineIsContent = 0
      if timeNum > latestTime
        let latestTime = timeNum
      endif
      if timeNum < earliestTime
        let earliestTime = timeNum
      endif
    else

      let words = split(line,' ')

      if words[0] == "committer-time"
        let timeNum = str2nr(words[1])
      elseif words[0] == "filename"
        let nextLineIsContent = 1
      endif

    endif

  endfor

  if line("$") != len(times)
    echo "WARNING: buffer lines " . line("$") . " do not match git blame lines " . len(lines)
  endif

  " TODO: These options should be made configurable

  " In active projects, we want colors to represent age relative to now
  let mostRecentTime = localtime()
  " In old projects, we probably want to show changes relative to the last change (even if it was years ago)
  "let mostRecentTime = latestTime

  " Lines older than 2 weeks are colored normally
  let maxAge = 14.0 * 24.0 * 60.0 * 60.0
  " Only lines from the very first commit are colored normally
  "let maxAge = latestTime - earliestTime

  silent! call clearmatches()

  let lineNum = 0
  for timeNum in times

    let lineNum += 1

    let timeSince = mostRecentTime - timeNum
    if timeSince < 0
      let timeSince = 0
    endif
    if timeSince > maxAge
      let timeSince = maxAge
    endif

    " Linear
    let intensity = 255.0 * ( 1.0 - timeSince / maxAge )
    " Exponential: intensity halves every 2 weeks
    "let intensity = 255.0 / (1.0 + timeSince / 60.0 / 60.0 / 24.0 / 15.0)
    let intensity = float2nr(intensity)
    let lumHex = printf('%02x', intensity)

    if g:GitShade_ColorGradient == "black_to_green"
      let hlStr = "00" . lumHex . "00"
    elseif g:GitShade_ColorGradient == "green_to_white"
      let hlStr = lumHex . "ff" . lumHex
    elseif g:GitShade_ColorGradient == "black_to_blue"
      let hlStr = "0000" . lumHex
    endif

    "echo "Hex for age " . timeNum . " is: " . hlStr

    let hlName = "ColoredTime_" . hlStr

    if hlexists(hlName)
      exec "highlight clear " . hlName
    endif

    if g:GitShade_ColorWhat == "fg"
      exec "highlight " . hlName . " guifg=#" . hlStr . " gui=none"
    else
      exec "highlight " . hlName . " guibg=#" . hlStr
    endif

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
