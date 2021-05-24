#!/bin/env zsh
#  ____            _   __  __                 _
# |  _ \ _ __ ___ (_) |  \/  | __ _ _ __ ___ | |_
# | |_) | '__/ _ \| | | |\/| |/ _` | '_ ` _ \| __|
# |  __/| | | (_) | | | |  | | (_| | | | | | | |_
# |_|   |_|  \___// | |_|  |_|\__, |_| |_| |_|\__|
#               |__/          |___/
#
# AUTHOR      : avimehenwal
# DATE        : 06-Dec-2020
# PURPOSE     : ZSH Plugin
# FILENAME    : projectManagement.zsh
#
# interactive and sane options for jumping b/w your project
# things which you often do

__ZSH_PLUGIN_DEPS=(fzf find tree)
for dep in $__ZSH_PLUGIN_DEPS
do
  (( $+commands[$dep] )) && echo "$dep is installed"|| echo "Plugin-Dependency $dep Not Installed"
  # ( $(command -v $dep > /dev/null )) && echo "$dep is installed"|| echo "Plugin-Dependency $dep Not Installed"
done
# ( $(pip3 show termgraph > /dep/null) ) && echo "Plugin-Dependency termgraph Not Installed" || echo "termgraph is installed"


SCRIPT_APATH=${0:a:h}
export AVI_ZSH_PM_DATA=${SCRIPT_APATH}/project-names.data
[ -f "${AVI_ZSH_PM_DATA}" ] || touch ${AVI_ZSH_PM_DATA}

# list Project Files for editing
function pf() {
  local RG='rg --files --hidden --follow --no-ignore-vcs -g "!{node_modules,.git}"'
  $EDITOR $(
    eval ${RG} | fzf \
      --multi \
      --bind ctrl-a:select-all \
      --preview-window=right:65% \
      --preview='stat {-1}; bat --color=always {-1}' \
      --prompt='list ProjectFiles>>'
  )
}

# Projects
treeGraph() {
  git fetch --all --quiet
  # tree --du --si --sort=size -C -d -L 1 -i $LOC
  tree --du --sort=size --noreport -i -d -L 1 |
    sed 1d |
    sed s/]// |
    awk '{print $3"\t"$2}' |
    termgraph --title "${PWD}" --color red
}

# http://zsh.sourceforge.net/Doc/Release/User-Contributions.html#index-colors
# autoload -U colors
# colors
# echo $bold_color$bg[red]bold red${reset_color} plain
# echo $bold_color$fg[white]$bg[black]bold red${reset_color} plain
# echo $bold_color$fg[black]$bg[green]bold red${reset_color} plain
# echo $bold_color$fg[black]$bg[blue]bold red${reset_color} plain
# echo $bold_color$fg[black]$bg[magenta]bold red${reset_color} plain
# echo $bold_color$fg[black]$bg[cyan]bold red${reset_color} plain
# echo $bold_color$fg[black]$bg[white]bold red${reset_color} plain
pp() {
  local result=""
  echo 📌 $bold_color$fg[black]$bg[yellow] MyProjects ${reset_color} ${MyProjects}
  while IFS= read -r PROJ; do
    loc=$(find $HOME -not \( -path $HOME/.Trash -prune \) -maxdepth 2 -type d -name ${PROJ})
    result+="$bold_color$fg[green]${PROJ}${reset_color} ${loc}\n"
  done < $AVI_ZSH_PM_DATA
  selection=$(echo -e ${result} |
    column -t -c Name,Path |
    fzf --header-lines=0 \
      --height=70% \
      --preview-window=right:50% \
      --prompt='select Project >' \
      --preview 'tree -C -L 1 {-1} --sort=mtime -r')
  cd $(echo $selection | awk '{print $2}') && treeGraph
}

generateProjectAlias() {
  # Internal FIeld Seperator
  while IFS= read -r PROJ; do
    local loc=$(find ${HOME} -not \( -path $HOME/.Trash -prune \) -maxdepth 2 -type d -name ${PROJ} -print)
    local value="cd ${loc} && pf"
    alias $PROJ="${value}"
    # echo "alias $PROJ='$value'"
  done < $AVI_ZSH_PM_DATA
}

# Add Project
project_add () {
  local project=$1
  echo ${project} >> ${AVI_ZSH_PM_DATA} && echo $bold_color$bg[green]$fg[black] $project ${reset_color} Added to $AVI_ZSH_PM_DATA
}
# check if already exists
pa() {
  local project=$(basename $PWD)
  grep -q ^${project} ${AVI_ZSH_PM_DATA} && echo "$bold_color$bg[yellow]$fg[black] ${project} ${reset_color} Already exists in list 🏃" || project_add ${project}
  bat $AVI_ZSH_PM_DATA
}

# regex match doesnt work on zsh
# [[ $line =~ ^- ]] && echo file
# [[ $line =~ ^d ]] && echo directory

# only for NPM projects
run() {
  clear
  DELIMITER='#' # want to retain colons in script names, its pretty standard
  if [ -f ./package.json ]; then
    echo 🏃 $bold_color$bg[green]$fg[black] NPM RUN ${reset_color} project scripts 🏃
    npm run $(
    jq ".scripts" < ./package.json |
      sed -e "s/\": \"/$DELIMITER/g" |
      sed -e '1d;$d' -e 's/"//g' -e 's/,//g' |
        column --table -s "$DELIMITER" --table-right 1 |
        bat -l bash --style=plain |
        fzf --no-multi --cycle --height=50% --margin=15% --padding=1% --info=inline \
          --prompt='npm run ' --ansi
      # --preview='bat -l sh {}'
    )
  else
    echo $bold_color$bg[red]$fg[black] package.json ${reset_color} File not found in CWD
  fi

}

echo "PROJECT MANAGEMENT ZSH PLUGIN"
generateProjectAlias

# END
