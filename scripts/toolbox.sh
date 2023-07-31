#!/usr/bin/env bash

set -e

shopt -s expand_aliases
alias k='kubectl'

if [[ "${NO_COLORS}" != "true" ]]
then
  # handy color vars for pretty prompts
  # Defining some colors for output
  NC='\033[0m' # No Color
  BLACK="\033[0;30m"
  BLUE='\033[0;34m'
  BROWN="\033[0;33m"
  GREEN='\033[0;32m'
  GREY="\033[0;90m"
  CYAN='\033[0;36m'
  MAGENTA='\033[0;35m'
  RED='\033[0;31m'
  PURPLE="\033[0;35m"
  WHITE='\033[0;37m'
  YELLOW='\033[0;33m'
  COLOR_RESET="\033[0m"
fi

shopt -s expand_aliases
alias k='kubectl'

####################################
## Section to declare the functions
####################################
repeat_char(){
  COLOR=${1}
	for i in {1..70}; do echo -ne "${!COLOR}$2${NC}"; done
}

fmt() {
  COLOR="WHITE"
  MSG="${@:1}"
  echo -e "${!COLOR} ${MSG}${NC}"
}

msg() {
  COLOR=${1}
  MSG="${@:2}"
  echo -e "\n${!COLOR}## ${MSG}${NC}"
}

succeeded() {
  MSG=$1
  # Use command substitution to check if the string contains a newline
  if [ -z "$(echo "$MSG" | grep $'\n')" ]; then
    # Single-line string, directly echo it
    echo -e "${GREEN}NOTE:${NC} $MSG"
  else
    # Multiline string, iterate over each line using a while loop and read
    while IFS= read -r line; do
      echo -e "${GREEN}NOTE:${NC} $line"
    done <<< "$MSG"
  fi
}

note() {
  MSG=$1

  # Use command substitution to check if the string contains a newline
  if [ -z "$(echo "$MSG" | grep $'\n')" ]; then
    # Single-line string, directly echo it
    echo -e "${BLUE}NOTE:${NC} $MSG"
  else
    # Multiline string, iterate over each line using a while loop and read
    while IFS= read -r line; do
      echo -e "${BLUE}NOTE:${NC} $line"
    done <<< "$MSG"
  fi
}

warn() {
  MSG=$1
  # Use command substitution to check if the string contains a newline
  if [ -z "$(echo "$MSG" | grep $'\n')" ]; then
    # Single-line string, directly echo it
    echo -e "${YELLOW}$MSG${NC}"
  else
    # Multiline string, iterate over each line using a while loop and read
    while IFS= read -r line; do
      echo -e "${YELLOW}$line${NC}"
    done <<< "$MSG"
  fi
}

error() {
  MSG=$1
  # Use command substitution to check if the string contains a newline
  if [ -z "$(echo "$MSG" | grep $'\n')" ]; then
    # Single-line string, directly echo it
    echo -e "${RED}ERROR:${NC} $MSG"
  else
    # Multiline string, iterate over each line using a while loop and read
    while IFS= read -r line; do
      echo -e "${RED}ERROR:${NC} $line"
    done <<< "$MSG"
  fi
}

log() {
  MSG="${@:2}"
  echo; repeat_char ${1} '#'; msg ${1} ${MSG}; repeat_char ${1} '#'; echo
}

format_message() {
  local message_format="$1"
  shift
  local formatted_msg=$(printf "$message_format" "$@")
  echo "$formatted_msg"
}

is_multiline_string() {
  if echo "$1" | grep -q $'\n'; then
    return 0  # True, string is multiline
  else
    return 1  # False, string is single line
  fi
}

log_http_response() {
    local ERROR_MSG=$1
    local SUCCESS_MSG=$2
    local RESPONSE=$3

    # Extract the response code from the output
    http_code=${RESPONSE:${#RESPONSE}-3}

    # Read the response body from the file and remove Headers
    response=$(cat response.txt)
    removeHeaders=$(echo "$response" | grep -vE "^(Content-Type:|Content-Length:|Date:|Location:|Connection:|HTTP/1.1)")
    bodyMessage=$(echo "$removeHeaders" | tr -d '\n\r')

    if [[ "$http_code" = 500 ]]; then
      error "$(format_message "$ERROR_MSG" "500 Internal Server Error")"
      exit 1
    fi
    if [[ "$http_code" = 400 ]]; then
      error "$(format_message "$ERROR_MSG" "400 Bad Request")"
      exit 1
    fi
    if [[ "$http_code" = 404 ]]; then
      error "$(format_message "$ERROR_MSG" "404 Not found")"
      exit 1
    fi
    if [[ "$http_code" = 406 ]]; then
      error "$(format_message "$ERROR_MSG" "406 Not Acceptable")"
      exit 1
    fi
    if [[ "$http_code" = 409 ]]; then
      error "$(format_message "$ERROR_MSG" "409 Conflict")"
      exit 1
    fi
    if [[ "$http_code" = 415 ]]; then
      error "$(format_message "$ERROR_MSG" "415 Unsupported Media Type")"
      exit 1
    fi
    if [[ "$response" = *"alert-danger"* ]]; then
      error "$(format_message "$ERROR_MSG" "$bodyMessage")"
      exit 1
    fi

    note "$(format_message "$SUCCESS_MSG" "$bodyMessage")"
}

function cmdExec() {
  COMMAND=${1}
  if [ "$PSEUDO_TTY" = "false" ]; then
    fmt "${COMMAND}"
    eval "${COMMAND}"
  else
    if "$HAS_PV"; then
      pe "$1"
    else
      echo ""
      echo -e "${RED}##############################################################"
      echo "# Hold it !! I require pv but it's not installed. " >&2;
      echo -e "${RED}##############################################################"
      echo ""
      echo -e "${COLOR_RESET}Installing pv:"
      echo ""
      echo -e "${BLUE}Mac:${COLOR_RESET} $ brew install pv"
      echo ""
      echo -e "${BLUE}Other:${COLOR_RESET} http://www.ivarch.com/programs/pv.shtml"
      echo -e "${COLOR_RESET}"
      exit 1
    fi
  fi
}

############################################
## Main section
############################################

# Define a function to check if a command exists
function pv_exists() {
  command -v pv >/dev/null 2>&1
}

# Check if the command exists and store the result in a variable
if pv_exists; then
  HAS_PV=true
  ##########################################
  ## Play demo functions and variables section
  ##########################################
  C_NUM=0
  # the speed to "type" the text
  TYPE_SPEED=${TYPE_SPEED:-20}

  # no wait after "p" or "pe"
  NO_WAIT=${NO_WAIT:-"false"}

  # if > 0, will pause for this amount of seconds before automatically proceeding with any p or pe
  PROMPT_TIMEOUT=${PROMPT_TIMEOUT:-0}

  # don't show command number unless user specifies it
  SHOW_CMD_NUMS=false
  # prompt and command color which can be overridden
  DEMO_PROMPT="$ "
  DEMO_CMD_COLOR=$WHITE
  DEMO_COMMENT_COLOR=$GREY

  ##
  # wait for user to press ENTER
  # if $PROMPT_TIMEOUT > 0 this will be used as the max time for proceeding automatically
  ##
  function wait() {
    if [[ "$PROMPT_TIMEOUT" == "0" ]]; then
      read -rs
    else
      read -rst "$PROMPT_TIMEOUT"
    fi
  }

  ##
  # render the prompt by itself
  #
  ##
  function pr() {
    # render the prompt
    x=$(PS1="$DEMO_PROMPT" "$BASH" --norc -i </dev/null 2>&1 | sed -n '${s/^\(.*\)exit$/\1/p;}')

    # show command number is selected
    if $SHOW_CMD_NUMS; then
     printf "[$((++C_NUM))] $x"
    else
     printf "$x"
    fi
  }

  ##
  # print command only. Useful for when you want to pretend to run a command
  #
  # takes 1 param - the string command to print
  #
  # usage: p "ls -l"
  #
  ##
  function p() {
    if [[ ${1:0:1} == "#" ]]; then
      cmd=$DEMO_COMMENT_COLOR$1$COLOR_RESET
    else
      cmd=$DEMO_CMD_COLOR$1$COLOR_RESET
    fi

    if [[ -z "$PROMPT_AFTER" ]]; then
      pr "$@"
    fi

    # wait for the user to press a key before typing the command
    if [ $NO_WAIT = false ]; then
      wait
    fi

    if [[ -z $TYPE_SPEED ]]; then
      echo -en "$cmd"
    else
      echo -en "$cmd" | pv -qL $[$TYPE_SPEED+(-2 + RANDOM%5)];
    fi

    # wait for the user to press a key before moving on
    if [ $NO_WAIT = false ]; then
      wait
    fi
    echo ""
  }

  ##
  # Prints and executes a command
  #
  # takes 1 parameter - the string command to run
  #
  # usage: pe "ls -l"
  #
  ##
  function pe() {
    # print the command
    p "$@"
    run_cmd "$@"
    if [[ -n "$PROMPT_AFTER" ]]; then
      pr
    fi
  }

  ##
  # print and executes a command immediately
  #
  # takes 1 parameter - the string command to run
  #
  # usage: pei "ls -l"
  #
  ##
  function pei {
    NO_WAIT=true pe "$@"
  }

  ##
  # Enters script into interactive mode
  #
  # and allows newly typed commands to be executed within the script
  #
  # usage : cmd
  #
  ##
  function cmd() {
    # render the prompt
    x=$(PS1="$DEMO_PROMPT" "$BASH" --norc -i </dev/null 2>&1 | sed -n '${s/^\(.*\)exit$/\1/p;}')
    printf "$x$COLOR_RESET"
    read command
    run_cmd "${command}"
  }

  function run_cmd() {
    function handle_cancel() {
      printf ""
    }

    trap handle_cancel SIGINT
    if [[ "$NO_COLORS" == "" ]]; then stty -echoctl ; fi
    eval "$@"
    if [[ "$NO_COLORS" == "" ]]; then stty echoctl ; fi
    trap - SIGINT
  }
else
  HAS_PV=false
fi