TIME=$(date "+%Y-%m-%d %H:%M:%S")
OS="$(uname)"
if [[ "${OS}" == "Linux" ]]; then
  INSTALL_ON_LINUX=1
  USER_HOME_PREFIX="/home"
elif [[ "${OS}" == "Darwin" ]]; then
  INSTALL_ON_MAC=1
  USER_HOME_PREFIX="/Users"
else
  echo "开发环境脚本只适配mac或者linux"
  exit 1
fi
USER_NAME="dingrui"

# 字符串染色
if [[ -t 1 ]]; then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi

tty_universal() { tty_escape "0;$1"; } #正常显示
tty_mkbold() { tty_escape "1;$1"; }    #设置高亮
tty_underline="$(tty_escape "4;39")"   #下划线
tty_blue="$(tty_universal 34)"         #蓝色
tty_red="$(tty_universal 31)"          #红色
tty_green="$(tty_universal 32)"        #绿色
tty_yellow="$(tty_universal 33)"       #黄色
tty_bold="$(tty_universal 39)"         #加黑
tty_cyan="$(tty_universal 36)"         #青色
tty_reset="$(tty_escape 0)"            #去除颜色

# 开始执行环境配置
echo "
              ${tty_green}开始执行脚本配置开发环境${tty_reset}
              ${tty_cyan}Bannirui@outlook.com${tty_reset}
              当前系统类型为${OS}
              ${TIME}
"
# 包管理器
if [[ -z "${INSTALL_ON_LINUX-}" ]]; then
  # Mac
  brew --version
  if [ $? -ne 0 ]; then
    echo "${tty_red}缺少Homebrew 开始安装${tty_reset}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
fi

# git
git --version
if [ $? -ne 0 ]; then
  if [[ -z "${INSTALL_ON_LINUX-}" ]]; then
    echo "${tty_red}缺少git 请安装git${tty_reset}后再运行此脚本 ${tty_red}在系统弹窗中点击[安装]按钮 如果没有弹窗可能是系统版本太老${tty_reset}"
    xcode-select --install
    exit 1
  else
    echo "${tty_red}缺少git 开始安装 请输入Y${tty_reset}"
    sudo apt install git
  fi
fi

# ssh密钥
GIT_SSH_NAMES=("my_github" "tongcheng_gitlab")
GIT_SSH_EMAILS=("Bannirui@outlook.com" "rui3.ding@ly.com")
# 处理单个git ssh 入参1个 是GIT_SSH_NAMES的脚标
process() {
  file_name="${USER_HOME_PREFIX}/${USER_NAME}/.ssh/${GIT_SSH_NAMES[${1}]}"
  if [ ! -f ${file_name} ]; then
    echo "${tty_green}生成密钥路径为${file_name}"
    /bin/bash -c "ssh-keygen -t rsa -C ${GIT_SSH_EMAILS[${1}]} -f ${file_name} -P "" -N "" -q"
    /bin/bash -c "ssh-add ${GIT_SSH_NAMES[${1}]}"
  fi
}

/bin/bash -c "$(git config --global --unset user.name)"
/bin/bash -c "$(git config --global --unset user.email)"

for ((i=0;i<${#GIT_SSH_NAMES[@]};i++));
  do
    process ${i};
  done

/bin/bash -c "$(git config --global user.name "dingrui")"
/bin/bash -c "$(git config --global user.email "Bannirui@outlook.com")"

# zsh
zsh --version
if [ $? -ne 0 ]; then
  echo "${tty_red}缺少zsh 开始安装{tty_reset}"
  /bin/bash -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
# zsh插件
# 按照插件名称安装指定插件 入参为插件名称
install_zsh_plugin() {
  if [ ! -d "${ZSH_PLUGIN_DIR}/${1}" ]; then
    echo "${tty_red}不存在${ZSH_PLUGIN_DIR}/${1}${tty_reset}"
    echo "${tty_green}==>安装${1}插件${tty_reset}"
    /bin/bash -c "$(git clone https://github.com/zsh-users/${1}.git ${ZSH_PLUGIN_DIR}/${1})"
  fi
}

ZSH_PLUGIN_DIR="${USER_HOME_PREFIX}/${USER_NAME}/.oh-my-zsh/custom/plugins"
# zsh插件名称
PLUGINS="zsh-autosuggestions zsh-syntax-highlighting zsh-completions"
for PLUGIN_NAME in ${PLUGINS};
do
  install_zsh_plugin ${PLUGIN_NAME} ;
done

# maven
mvn --version
if [ $? -ne 0 ]; then
  echo "${tty_red}缺少maven 开始安装{tty_reset}"
  if [[ -z "${INSTALL_ON_LINUX-}" ]]; then
    # Macos
    brew install maven
  else
    # Linux
    sudo apt install maven
  fi
fi

# node
node --version
if [ $? -ne 0 ]; then
  echo "${tty_red}缺少node 开始安装{tty_reset}"
  if [[ -z "${INSTALL_ON_LINUX-}" ]]; then
    # Macos
    brew install node
  else
    # Linux
    sudo apt install nodejs
  fi
fi

# npm
npm --version
if [ $? -ne 0 ]; then
  echo "${tty_red}缺少npm 开始安装{tty_reset}"
  if [[ -z "${INSTALL_ON_LINUX-}" ]]; then
    # Macos
    brew install npm
  else
    # Linux
    sudo apt install npm
  fi
fi