"
" Vim Rspec
" Last change: March 3 2009
" Version> 0.0.2
" Maintainer: Eustáquio 'TaQ' Rangel
" License: GPL
" URL: git://github.com/taq/vim-rspec
"
" Script to run the spec command inside Vim
" To install, unpack the files on your ~/.vim directory and source it 
"
function! s:find_xslt()
	return system("xsltproc --version | head -n1")
endfunction

function! s:find_grep()
	return system("grep --version | head -n1")
endfunction

function! s:error_msg(msg)
	echohl ErrorMsg
	echo a:msg
	echohl None
endfunction

function! s:notice_msg(msg)
	echohl MoreMsg
	echo a:msg
	echohl None
endfunction

function! s:RunSpecMain(type)
	let l:xsltproc_cmd = s:find_xslt()
	if match(l:xsltproc_cmd,'\d')<0
		call s:error_msg("You need xsltproc to run this script.")
		return
	end
	let l:grep_cmd = s:find_grep()
	if match(l:grep_cmd,'\d')<0
		call s:error_msg("You need grep to run this script.")
		return
	end
	let l:bufn = bufname("%")

	" run just the current file
	if a:type=="file"
		if match(l:bufn,'_spec.rb')>=0
			call s:notice_msg("Running spec on the current file ...")
			let l:spec  = "spec -f h ".l:bufn
		else
			call s:error_msg("Seems ".l:bufn." is not a *_spec.rb file")
			return
		end			
	else
		let l:dir = expand("%:p:h")
		if isdirectory(l:dir."/spec")>0
			call s:notice_msg("Running spec on the spec directory ...")
		else
			" try to find a spec directory on the current path
			let l:tokens = split(l:dir,"/")
			let l:dir = ""
			for l:item in l:tokens
				call remove(l:tokens,-1)
				let l:path = "/".join(l:tokens,"/")."/spec"
				if isdirectory(l:path)
					let l:dir = l:path
					break
				end
			endfor
			if len(l:dir)>0
				call s:notice_msg("Running spec on the spec directory found (".l:dir.") ...")
			else
				call s:error_msg("No ".l:dir."/spec directory found")
				return
			end				
		end			
		if isdirectory(l:dir)<0
			call s:error_msg("Could not find the ".l:dir." directory.")
			return
		end
		let l:spec = "spec -f h ".l:dir." -p **/*_spec.rb"
	end		

	" run the spec command
	let l:xsl   = expand("~/").".vim/plugin/vim-rspec.xsl"
	let s:cmd	= l:spec." | xsltproc --novalid --html ".l:xsl." - 2> /dev/null | grep \"^[-\+\[ ]\""
	echo

	" put the result on a new buffer
	silent exec "new" 
	set buftype=nofile
	silent exec "r! ".s:cmd
	set syntax=vim-rspec
	silent exec "nnoremap <buffer> <cr> :call <SID>TryToOpen()<cr>"
	call cursor(1,1)	
endfunction

function! s:TryToOpen()
	let l:line = getline(".")
	if match(l:line,'^  [\/\.]')<0
		call s:error_msg("No file found.")
		return
	end
	let l:tokens = split(l:line,":")
	silent exec "sp ".substitute(l:tokens[0],'/^\s\+',"","")
	call cursor(l:tokens[1],1)
endfunction

function! RunSpec()
	call s:RunSpecMain("file")
endfunction

function! RunSpecs()
	call s:RunSpecMain("dir")
endfunction

command! RunSpec	call RunSpec()
command! RunSpecs	call RunSpecs()
