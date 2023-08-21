#compdef rdg
local -a all_opts
local -a rdg=( env RENPYDESKGEN_CHECK_OPTIONAL_DEPENDENCIES=false rdg -qQ )

_rdg_icon_size_handler() {
    local ret=1
    local -a size_handler_display size_handler_words
    size_handler_display=(
        {C,closest-convert}:'convert to closest found size'
        {M,closest-move}:'move to closest found size directory without converting'
        {S,create-new-scaled}:'create a new scaled icon size entry between a min and max scaling factor'
        {T,create-new-threshold}:'create a new over and under size threshold icon size entry'
        {F,create-new-fixed}:'create a new icon entry of fixed size'
        {O,only-create}:'do not register icon size'
    )
    size_handler_words=(
        {C,closest-convert}
        {M,closest-move}
        {S,create-new-scaled=}
        {T,create-new-threshold=}
        {F,create-new-fixed}
        {O,only-create}
    )
    _rdg_icon_size_handler_erase() {
        local re=''
        if [[ "$LBUFFER" =~ \\bcreate-new-(scaled|threshold)=$ && "$KEYS" =~ [^0-9] ]]; then
            LBUFFER=${LBUFFER[1,-2]}
        fi
    }
    _describe -t size_handler_display 'icon size handler' size_handler_display size_handler_words -S '' -R _rdg_icon_size_handler_erase && ret=0
    return $ret
}

_rdg_icon_resize(){
    local ret=1
    local -a methods
    methods=(
        {resize,lanczos,l}:'use Lanczos interpolation'
        {scale,area,box,s}:'average or replace pixels respectively'
        {sample,nearest-neighbour,point,n,nn}:'interpolate using nearest neighbour'
        )
    if command -v magick &>/dev/null; then
        magick -list filter | while read -r FILTER; do
        methods=(
            $methods
            "custom\\:$FILTER:ImageMagick $FILTER filter"
                )
            done
    fi
    if command -v ffmpeg &>/dev/null; then
        ffmpeg -v quiet -h full | sed -n '/-sws_flags/,/-/p' | sort | uniq | head -n-2 | while read -r FLAG _ DESC; do
        methods=(
            $methods
            "custom\\:$FLAG:FFmpeg $DESC flag"
                )
            done
    fi
    _describe -t methods 'icon resizing' methods && ret=0
    return $ret
}

_rdg_log_level(){
    local ret=1
    local -a levels
    levels=(
        {4,debug,d}:'log file system operations and print `sudo`'
        {3,info,i}:'status information'
        {2,warning,w}:'warnings'
        {1,errors,e}:'errors'
        {0,quiet,q}:'suppress most output'
        )
    _describe 'log level' levels && ret=0
    return $ret
}

_rdg_complete() {
    local -a complete indices
    local dir
    local -i index
    if [[ -e $words[$CURRENT] ]]; then
        dir=$words[$CURRENT]
        [[ -d "$dir" ]] || dir=${dir%/*}
    else
        indices=($words[(I)-s] $words[(I)-d] $words[(I)--script] $words[(I)--starting-dir])
        index=${${(nO)indices}[1]}
        if [[ $index == $((CURRENT-1)) ]]; then
            index=${${(nO)indices}[2]}
        fi
        if [[ $index > 0  ]]; then
            dir=$words[index+1]
            [[ -d "$dir" ]] || dir=${dir%/*}
        else
            dir='.'
        fi
    fi

    IFS=$'\0' complete=($($rdg '-!' api_complete "$1" "$dir" | sed '$s/\x00$//'))
    _describe "$2" complete && ret=0
    return $ret
}

_rdg_xdg_dirs() {
    local -a complete
    complete=(${(s.:.)XDG_DATA_DIRS} '/usr/local/share/' $XDG_DATA_HOME "$HOME/.local/share/")
    complete=(${(u)complete})
    complete=(${^complete}/$1)
    complete=(${complete:A})
    [[ "$1" == 'icon' && -d "$HOME/.icons" ]] && complete=( $complete "$HOME/.icons" )
    [[ "$1" == 'icon' && -d '/usr/share/pixmaps' ]] && complete=( $complete '/usr/share/pixmaps' )
    _describe "$2" complete && ret=0
    return $ret
}

all_opts=(
    '(-i --install -I --no-install)'{-i,--install}'[install the desktop file]'
    '(-i --install -I --no-install)'{-I,--no-install}'[do not install the desktop file]'
    '(-u --unstall -U --no-uninstall)'{-u,--uninstall}'[uninstall the desktop file]'
    '(-u --unstall -U --no-uninstall)'{-U,--no-install}'[do not uninstall the desktop file]'
    '(-e --remove-empty-dirs -E --no-remove-empty-dirs)'{-e,--remove-empty-dirs}'[remove empty directories when uninstalling]'
    '(-e --remove-empty-dirs -E --no-remove-empty-dirs)'{-E,--no-remove-empty-dirs}'[do not remove empty directories when uninstalling]'
    '(-a --install-all-users -A --no-install-all-users)'{-e,--install-all-users}'[install system wide]'
    '(-a --install-all-users -A --no-install-all-users)'{-E,--no-install-all-users}'[do not install system wide]'
    '(-s --script)'{-s,--script=}"[Ren'Py start script]"':script file:->startscript'
    '(-d --starting-dir)'{-d,--starting-dir=}"[Ren'Py game directory]"':game directory:->startdir'
    '(-c --icon -C --no-icon)'{-c,--icon=}"[icon file]"':icon file:_files'
    '(-v --current-version-search -V --no-current-version-search)'{-v,--current-version-search}'[search for newest version of game]'
    '(-v --current-version-search -V --no-current-version-search)'{-V,--no-current-version-search}'[do not search for newest version of game]'
    '(-S --current-version-search-dir)'{-S,--current-version-search-dir=}'[start directory for current version]:version search directory:_files -/'
    '(-N --display-name)'{-N,--display-name=}"[displayed game name]"':game name:->gamename'
    '(-K --set-keywords)*'{-k,--add-keywords=}"[add keywords]"':keywords:'
    '!(-K --set-keywords)*'{--keywords=}"[add keywords]"':keywords:'
    '(-K --set-keywords)'{-K,--set-keywords=}"[set keywords]"':keywords:'
    '(-m --name-keyword -M --no-name-keyword)'{-v,--name-keyword}'[use script name as keyword]'
    '(-m --name-keyword -M --no-name-keyword)'{-V,--no-name-keyword}'[do not use script name as keyword]'
    '(-p --vendor-prefix)'{-p,--vendor-prefix=}"[prefix of generated files]"':vendor prefix:'
    '(-O --icon-dir)'{-O,--icon-dir=}"[icon installation directory]"':icon directory:->icondir'
    '(-o --installation-dir)'{-o,--installation-dir=}"[desktop file installation directory]"':desktop file directory:->installdir'
    '(-f --create-default-icon-size -F --no-create-default-icon-size)'{-f,--create-default-icon-size}'[create 48×48 icon]'
    '(-f --create-default-icon-size -F --no-create-default-icon-size)'{-f,--no-create-default-icon-size}'[do not create 48×48 icon]'
    '(-P --icon-handling-program)'{-P,--icon-handling-program=}"[program for icon conversion, extraction, etc.]"':icon program:->iconprog'
    '(-t --theme-attribute-file)'{-t,--theme-attribute-file=}"[file containing configurations]"':theme file:_files'
    '(-H --icon-size-not-existing-handling)'{-H,--icon-size-not-existing-handling=}"[how to handle undefined icon sizes]"':icon size handling:_rdg_icon_size_handler'
    '(-r --icon-resize-method)'{-r,--icon-resize-method=}"[icon resizing algorithm]"':icon size method:_rdg_icon_resize'
    '(-C --no-icon -c --icon --no-no-icon)'{-C,--no-icon}'[do not use an icon]'
    '(--broad-icon-search --no-broad-icon-search)--broad-icon-search[threat anything with ‘icon’ in its name as an icon]'
    '(--broad-icon-search --no-broad-icon-search)--no-broad-icon-search[do not threat anything with ‘icon’ in its name as an icon]'
    '(-w --download-fallback-icon -W --no-download-fallback-icon)'{-w,--download-fallback-icon}'[download a default icon in none is found]'
    '(-w --download-fallback-icon -W --no-download-fallback-icon)'{-W,--no-download-fallback-icon}'[do not download a default icon in none is found]'
    '(--fallback-icon-url)--fallback-icon-url=[location of icon to download]:icon url:_urls'
    '(-Q --interactive --no-interactive --non-interactive)--interactive[force interactiveness]'
    '(-Q --interactive --no-interactive --non-interactive)'{-Q,--non-interactive}'[disable interactiveness]'
    '!(-Q --interactive --no-interactive --non-interactive)--non-interactive[disable interactiveness]'
    '(-y --yes -n --no)'{-y,--yes}'[assume ‘yes’ for all prompts]'
    '(-y --yes -n --no)'{-n,--no}'[assume ‘no’ for all prompts]'
    '(-g --gui -G --no-gui)'{-g,--gui}'[force use of]'
    '(-g --gui -G --no-gui)'{-G,--no-gui}'[disable GUI]'
    '(-l --log-level)'{-l,--log-level}'[set verbosity of script]:log level:_rdg_log_level'
    '(-L --gui-log-level)'{-L,--gui-log-level}'[set amount of GUI info dialogues]:log level:_rdg_log_level'
    '(-x --log-system -X --no-log-system)'{-x,--log-system}'[also log to system log]'
    '(-x --log-system -X --no-log-system)'{-X,--no-log-system}'[do not log to system log]'
    '(-q --quiet -X --no-log-system)'{-q,--quiet}'[same as ‘-Xl 0 -L 0’]'
    '(-? --api-query)'{-'\?',--api-query}'[API: query variables]:variables:_rdg_variables'
    '(-! --api-call)'{-!,--api-call}'[API: call function]:functions:_rdg_functions'
    '(- :)'{-h,--help}'[show help message in pager]'
    '(- :)'{-Z,--version}'[print version information]'
    '*:file:_files'
    )
if [ "$($rdg -\? o:ICON_DISABLED)" = true ]; then
    all_opts=($all_opts '(-C --no-icon --no-no-icon)--no-no-icon[overwrite a default -C with this secret option OwO]')
fi

local curcontext="$curcontext" state state_descr line ret=1
typeset -A opt_args
_arguments -C -s -S "$all_opts[@]" && ret=0

case $state in
  (iconprog)
      local -a progs
      if command -v ffmpeg &>/dev/null; then
          progs=(ffmpeg:'use FFmpeg' $progs)
      fi
      if command -v magick &>/dev/null; then
          progs=(magick:'use ImageMagick' $progs)
      fi
      _describe 'icon handler' progs && ret=0
    ;;
  (startscript)
      _rdg_complete "RENPY_SCRIPT_PATH" "Ren'Py script"
      ;;
  (startdir)
      _rdg_complete "RENPY_DIRECTORY" "Ren'Py directory"
      ;;
  (gamename)
      # You may want to use BUILD_NAME instead of GAME_NAME here to be faster
      _rdg_complete "GAME_NAME" "Ren'Py game name"
      ;;
  (icondir)
      _rdg_comp_temp() {
          _rdg_xdg_dirs 'icons' 'XDG icon directory'
      }
      _alternative \
          "XDG directories:XDG dir:_rdg_comp_temp" \
          'directories:dir:_files -/'
      ;;
  (installdir)
      _rdg_comp_temp() {
          _rdg_xdg_dirs 'applications' 'XDG installation directory'
      }
      _alternative \
          "XDG directories:XDG dir:_rdg_comp_temp" \
          'directories:dir:_files -/'
      ;;
esac
return ret
