let s:plugin_root = expand('<sfile>:p:h:h')

if !exists("g:vim_ai_debug_log_file")
  let g:vim_ai_debug_log_file = "/tmp/vim_ai_debug.log"
endif

if !exists("g:vim_ai_config_file_path")
  let g:vim_ai_config_file_path = expand("~")."/.config/vim-ai-token.json"
endif

if !exists("g:vim_ai_name")
  let g:vim_ai_name = "doubao"
endif

if !exists("g:vim_ai_roles_config_file")
  let g:vim_ai_roles_config_file = s:plugin_root . "/roles-example.ini"
endif

" read json from g:vim_ai_config_file_path,and encode to json
if filereadable(expand(g:vim_ai_config_file_path))
  let g:vim_ai_config_map = json_decode(join(readfile(expand(g:vim_ai_config_file_path))))[g:vim_ai_name]
  if !has_key(g:vim_ai_config_map, "model")
    let g:vim_ai_config_map["model"] = ""
  endif
  if !has_key(g:vim_ai_config_map, "endpoint_url")
    let g:vim_ai_config_map["endpoint_url"] = ""
  endif
  if !has_key(g:vim_ai_config_map, "token")
    echoerr "token not found in " . g:vim_ai_config_file_path
    finish
  endif
else
  " default set openai
  let g:vim_ai_config_map = {
        \  "model": "gpt-3.5-turbo",
        \  "endpoint_url": "https://api.openai.com/v1/chat/completions",
        \  "token": "",
        \}
endif

let g:vim_ai_complete_default = {
\  "engine": "complete",
\  "options": {
\    "model": g:vim_ai_config_map["model"],
\    "endpoint_url": g:vim_ai_config_map["endpoint_url"],
\    "token": g:vim_ai_config_map["token"],
\    "max_tokens": (has_key(g:vim_ai_config_map, "max_tokens") ? g:vim_ai_config_map["max_tokens"] : 1000),
\    "temperature": (has_key(g:vim_ai_config_map, "temperature") ? g:vim_ai_config_map["temperature"] : 0.1),
\    "request_timeout": (has_key(g:vim_ai_config_map, "request_timeout") ? g:vim_ai_config_map["request_timeout"] : 20),
\    "enable_auth": 1,
\    "selection_boundary": "",
\  },
\  "ui": {
\    "paste_mode": 1,
\  },
\}

let g:vim_ai_edit_default= g:vim_ai_complete_default

let s:initial_chat_prompt =<< trim END
>>> system

You are a general assistant.
If you attach a code block add syntax type after ``` to enable syntax highlighting.
END
let g:vim_ai_chat_default = {
\  "options": {
\    "model": g:vim_ai_config_map["model"],
\    "endpoint_url": g:vim_ai_config_map["endpoint_url"],
\    "token": g:vim_ai_config_map["token"],
\    "max_tokens": (has_key(g:vim_ai_config_map, "max_tokens") ? g:vim_ai_config_map["max_tokens"] : 1000),
\    "temperature": (has_key(g:vim_ai_config_map, "temperature") ? g:vim_ai_config_map["temperature"] : 0.1),
\    "request_timeout": (has_key(g:vim_ai_config_map, "request_timeout") ? g:vim_ai_config_map["request_timeout"] : 20),
\    "enable_auth": 1,
\    "selection_boundary": "",
\    "initial_prompt": s:initial_chat_prompt,
\  },
\  "ui": {
\    "open_chat_command": "preset_below",
\    "scratch_buffer_keep_open": 0,
\    "populate_options": 0,
\    "code_syntax_enabled": 1,
\    "paste_mode": 1,
\  },
\}

if !exists("g:vim_ai_open_chat_presets")
  let g:vim_ai_open_chat_presets = {
  \  "preset_below": "below new | call vim_ai#MakeScratchWindow()",
  \  "preset_tab": "tabnew | call vim_ai#MakeScratchWindow()",
  \  "preset_right": "rightbelow 55vnew | setlocal noequalalways | setlocal winfixwidth | call vim_ai#MakeScratchWindow()",
  \  "preset_left": "leftbelow 55vnew | setlocal noequalalways | setlocal winfixwidth | call vim_ai#MakeScratchWindow()",
  \}
endif

if !exists("g:vim_ai_debug")
  let g:vim_ai_debug = 0
endif

function! vim_ai_config#ExtendDeep(defaults, override) abort
  let l:result = a:defaults
  for [l:key, l:value] in items(a:override)
    if type(get(l:result, l:key)) is v:t_dict && type(l:value) is v:t_dict
      call vim_ai_config#ExtendDeep(l:result[l:key], l:value)
    else
      let l:result[l:key] = l:value
    endif
  endfor
  return l:result
endfunction

function! s:MakeConfig(config_name) abort
  let l:defaults = copy(g:[a:config_name . "_default"])
  let l:override = exists("g:" . a:config_name) ? g:[a:config_name] : {}
  let g:[a:config_name] = vim_ai_config#ExtendDeep(l:defaults, l:override)
endfunction

call s:MakeConfig("vim_ai_chat")
call s:MakeConfig("vim_ai_complete")
call s:MakeConfig("vim_ai_edit")

function! vim_ai_config#load()
  " nothing to do - triggers autoloading of this file
endfunction
