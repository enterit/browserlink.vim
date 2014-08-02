" File:        brolink.vim
" Version:     2.6.0
" Description: Links VIM to your browser for live/responsive editing.
" Maintainer:  Jonathan Warner <jaxbot@gmail.com> <http://github.com/jaxbot>
" Homepage:    http://jaxbot.me/
" Repository:  https://github.com/jaxbot/brolink.vim
" License:     Copyright (C) 2014 Jonathan Warner
"              Released under the MIT license
"			   ======================================================================
"

if !exists("g:bl_serverpath")
	let g:bl_serverpath = "http://127.0.0.1:9001"
endif

let g:bl_state = 0
let s:path = expand('<sfile>:p:h')

python <<NOMAS
import sys
import time
import urllib2
import vim
import os
import subprocess
NOMAS

function! s:EvaluateSelection()
	call s:evaluateJS(s:get_visual_selection())
endfunction

function! s:EvaluateBuffer()
	call s:evaluateJS(join(getline(1,'$')," "))
endfunction

function! s:EvaluateWord()
	call s:evaluateJS(expand("<cword>") . "()")
endfunction

function! s:evaluateJS(js)
	python urllib2.urlopen(urllib2.Request(vim.eval("g:bl_serverpath") + "/evaluate", vim.eval("a:js")))
endfunction

function! s:sendCommand(command)
	python <<EOF
try:
	urllib2.urlopen(vim.eval("g:bl_serverpath") + "/" + vim.eval("a:command")).read()
except:
	vim.command("call s:startBrolink()")
EOF
endfunction

function! s:startBrolink()
	call system("cd " . s:path . "/../brolink && ./start.sh &")
endfunction

function! s:getConsole()
	normal ggdG
python <<EOF
data = urllib2.urlopen(vim.eval("g:bl_serverpath") + "/console").read()
for line in data.split("\n"):
	vim.current.buffer.append(line)
EOF
	setlocal nomodified
	nnoremap <buffer> i :BLEval 
	nnoremap <buffer> cc :BLConsoleClear<cr>:e<cr>
	nnoremap <buffer> r :e!<cr>
	nnoremap <buffer> <cr> :BLTraceLine<cr>
endfunction

function! s:traceLine()
python <<EOF

line = vim.eval("getline('.')")
fragments = line.split('/')
page = fragments[-1].split(':')[0]
line = fragments[-1].split(':')[1]

vim.command("b " + page)
vim.command(":" + line)
EOF
endfunction

function! s:get_visual_selection()
	let [lnum1, col1] = getpos("'<")[1:2]
	let [lnum2, col2] = getpos("'>")[1:2]
	let lines = getline(lnum1, lnum2)
	let lines[-1] = lines[-1][: col2 - 2]
	let lines[0] = lines[0][col1 - 1:]
	return join(lines, " ")
endfunction

function! s:setupHandlers()
	au BufWritePost *.html,*.htm,*.js,*.php :BLReloadPage
	au BufWritePost *.css :BLReloadCSS	
endfunction

command! -range -nargs=0 BLEvaluateSelection call s:EvaluateSelection()
command!        -nargs=0 BLEvaluateBuffer    call s:EvaluateBuffer()
command!        -nargs=0 BLEvaluateWord      call s:EvaluateWord()
command!        -nargs=1 BLEval              call s:evaluateJS(<f-args>)
command!        -nargs=0 BLReloadPage        call s:sendCommand("reload/page")
command!        -nargs=0 BLReloadCSS         call s:sendCommand("reload/css")
command!        -nargs=0 BLConsoleClear      call s:sendCommand("clear")
command!        -nargs=0 BLConsole           edit brolink/console
command!        -nargs=0 BLTraceLine         call s:traceLine()
autocmd BufReadCmd brolink/console* call s:getConsole()

if !exists("g:bl_no_mappings")
	vmap <silent><Leader>be :BLEvaluateSelection<CR>
	nmap <silent><Leader>be :BLEvaluateBuffer<CR>
	nmap <silent><Leader>bf :BLEvaluateWord<CR>
	nmap <silent><Leader>br :BLReloadPage<CR>
	nmap <silent><Leader>bc :BLReloadCSS<CR>
endif

if !exists("g:bl_no_autoupdate")
	call s:setupHandlers()
endif

if !exists("g:bl_no_eager")
	let g:bl_no_eager = 0
endif

