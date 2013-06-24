" git_shade.vim - Colors lines in different intensities according to their age in git's history
" Run :GitShade to shade the file.  Switch buffer or :e the file to remove the shading.
" TODO: Should seek .git folder from the buffer file's path, in case our pwd is not within the project.

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

  let timesDictionary = {}
  let earliestTime = localtime()
  let latestTime = 0

  let timeNum = -1
  let nextLineIsContent = 0
  let lineNum = 0
  for line in lines

    if nextLineIsContent
      let lineNum += 1
      "call add(times, timeNum)
      if !exists("timesDictionary[timeNum]")
        let timesDictionary[timeNum] = []
      endif
      let list = timesDictionary[timeNum]
      call add(list, lineNum)
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

  "if line("$") != len(times)
  "  echo "WARNING: buffer lines " . line("$") . " do not match git blame lines " . len(lines)
  "endif

  " TODO: These options should be made configurable

  " In active projects, we want colors to represent age relative to now
  "let mostRecentTime = localtime()
  " In old projects, we probably want to show changes relative to the last change (even if it was years ago)
  let mostRecentTime = latestTime

  " Lines older than 2 weeks are colored normally
  "let maxAge = 14 * 24 * 60 * 60
  " Only lines from the very first commit are colored normally
  "let maxAge = latestTime - earliestTime
  " Only shade lines in the second half of the file's history
  let maxAge = (latestTime - earliestTime) / 2

  " We need maxAge to be a float
  let maxAge = maxAge * 1.0

  silent! call clearmatches()

  "let lineNum = 0
  "for timeNum in times
  for [timeNum, linesThisCommit] in items(timesDictionary)

    "let lineNum += 1

    let timeSince = mostRecentTime - timeNum
    if timeSince < 0
      let timeSince = 0
    endif
    if timeSince > maxAge
      let timeSince = maxAge
      " Skip doing any highlighting on old/unshaded lines
      " Only applies to some themes.
      if g:GitShade_ColorWhat == "bg" && match(g:GitShade_ColorGradient, "^black")==0
        continue
      endif
    endif

    " Integer calculation did not work well (numbers got too large?)
    "let intensity = max([min([255 - (255 * timeSince / maxAge), 255]), 0])
    " Linear
    let intensity = 255.0 * ( 1.0 - timeSince / maxAge )
    " Exponential: intensity halves every 2 weeks
    "let intensity = 255.0 / (1.0 + timeSince / 60.0 / 60.0 / 24.0 / 15.0)
    let intensity = float2nr(intensity)
    let lumHex = printf('%02x', intensity)

    " NOTE: In future we may want to interpolate between two provided colors.  If they are provided in hex, we can use str2nr(hexStr, 16) to obtain a decimal.
    if g:GitShade_ColorGradient == "black_to_green"
      let hlStr = "00" . lumHex . "00"
    elseif g:GitShade_ColorGradient == "green_to_white"
      let hlStr = lumHex . "ff" . lumHex
    elseif g:GitShade_ColorGradient == "black_to_blue"
      let hlStr = "0000" . lumHex
    elseif g:GitShade_ColorGradient == "grey_to_black"
      let unlumHex = printf('%02x', 128-intensity/2)
      let hlStr = unlumHex . unlumHex . unlumHex
    endif

    "echo "Hex for age " . timeNum . " is: " . hlStr

    let hlName = "GitShade_" . hlStr

    if hlexists(hlName)
      exec "highlight clear " . hlName
    endif

    "echo "timeSince=" . timeSince . " maxAge=" . maxAge . " intensity=" . intensity

    if g:GitShade_ColorWhat == "fg"
      exec "highlight " . hlName . " guifg=#" . hlStr . " gui=none"
    else
      exec "highlight " . hlName . " guibg=#" . hlStr
    endif

    "let pattern = "\\%" . lineNum . "l"
    let pattern = join( map(linesThisCommit,'"\\%" . v:val . "l"'), '\|' )

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

  " Creating all these pattern matches makes rendering very inefficient.
  " The time taken to render will probably grow linearly with the number of lines in the file (the number of matches we create).
  " DONE: To reduce this, we could group together times which are the same, and create just one pattern for each unique timestamp, which would highlight multiple lines.
  " As done here: http://stackoverflow.com/questions/13675019/vim-highlight-lines-using-line-number-on-external-file?rq=1
  " Alternatively, we could use the 'signs' column to indicate different ages, and highlight lines through that.

endfunction
