#! /bin/bash
#set -evx

TIME=$(date "+%Y-%m-%d %H:%M:%S")
OS="$(uname)"
echo ${OS}
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

# mac版本
if [[ -z "${INSTALL_ON_LINUX-}" ]]; then
  ver_cmp=11
  ver_cur=$(sw_vers -productVersion 2>/dev/null | awk '{print int($0)}')
fi
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

# 代理软件
if ! type corkscrew > /dev/null 2>&1; then
  echo "${tty_red}==>缺少corkscrew 开始安装${tty_reset}"
  if [[ -z "${INSTALL_ON_LINUX-}" ]]; then
    brew install corkscrew
  else
    sudo apt install corkscrew
  fi
fi

# ssh密钥
GIT_SSH_NAMES=("my_github" "tongcheng_gitlab")
PC_SSH_NAMES=("debian" "hackintosh")
GIT_SSH_EMAILS=("Bannirui@outlook.com" "rui3.ding@ly.com")
# 处理单个git ssh 入参1个 是GIT_SSH_NAMES的脚标
function process_git_ssh() {
  file_name="${USER_HOME_PREFIX}/${USER_NAME}/.ssh/${GIT_SSH_NAMES[${1}]}"
  if [ ! -f "${file_name}" ]; then
    echo "${tty_green}生成密钥路径为${file_name}"
    /usr/bin/expect<<-EOF
    set timeout 60
    # 开启进程会话
    spawn ssh-keygen -t rsa -C ${GIT_SSH_EMAILS[${1}]} -n '' -f ${file_name}
    expect {
      "Enter file in which to save the key (/root/.ssh/id_rsa):" { send "\r"; exp_continue }
      "Overwrite (y/n)?" { send "n\r" }
      "Enter passphrase (empty for no passphrase):" { send "\r"; exp_continue }
      "Enter same passphrase again:" { send "\r" }
    }
    # 结束进程会话
    expect eof
# 这个地方EOF一定要顶格写
EOF
    /bin/bash -c "ssh-add ${GIT_SSH_NAMES[${1}]}"
  fi
}
function process_pc_ssh() {
  file_name="${USER_HOME_PREFIX}/${USER_NAME}/.ssh/${PC_SSH_NAMES[${1}]}"
  if [ ! -f "${file_name}" ]; then
    echo "${tty_green}生成密钥路径为${file_name}"
    /usr/bin/expect<<-EOF
    set timeout 60
    # 开启进程会话
    spawn ssh-keygen -t rsa -n '' -f ${file_name}
    expect {
      "Enter file in which to save the key (/root/.ssh/id_rsa):" { send "\r"; exp_continue }
      "Overwrite (y/n)?" { send "n\r" }
      "Enter passphrase (empty for no passphrase):" { send "\r"; exp_continue }
      "Enter same passphrase again:" { send "\r" }
    }
    # 结束进程会话
    expect eof
# 这个地方EOF一定要顶格写
EOF
  fi
}

/bin/bash -c "$(git config --global --unset user.name)"
/bin/bash -c "$(git config --global --unset user.email)"
for ((i=0;i<${#GIT_SSH_NAMES[@]};i++));
do
  process_git_ssh ${i};
done
/bin/bash -c "$(git config --global user.name "dingrui")"
/bin/bash -c "$(git config --global user.email "Bannirui@outlook.com")"

for ((i=0;i<${#PC_SSH_NAMES[@]};i++));
do
  process_pc_ssh ${i};
done

# 临时ssh config 下面要用github ssh协议clone项目
my_config="${USER_HOME_PREFIX}/${USER_NAME}/.ssh/config"
if [[ ! -L ${my_config} ]]; then
  /bin/bash -c "touch ${my_config}"
  if [[ ! -f ${my_config} ]]; then
    /bin/bash -c "touch ${my_config}"
  fi
  str="
    Host github.com
	  HostName ssh.github.com
    Port 443
	  IdentityFile ~/.ssh/my_github
	  User Bannirui@outlook.com
    PreferredAuthentications publickey
    ProxyCommand corkscrew 127.0.0.1 7890 %h %p
  "
  echo ${str} > ${my_config}
fi

# zsh
zsh --version
if [ $? -ne 0 ]; then
  echo "${tty_red}==>缺少zsh 开始安装${tty_reset}"
  if [[ -z "${INSTALL_ON_LINUX-}" ]]; then
    # Mac
    brew install zsh
    # omz
    echo "${tty_red}==>缺少omz 开始安装${tty_reset}"
    /bin/bash -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    # Linux
    sudo apt install zsh
  fi
fi

# neofetch
if command -v neofetch >/dev/null 2>&1 ; then
  echo "${tty_cyan}neofetch已经安装过了${tty_reset}"
else
  echo "${tty_red}缺少neofetch 开始安装${tty_reset}"
  if [[ -z "${INSTALL_ON_LINUX-}" ]]; then
    # Mac
    brew install neofetch
  else
    # Linux
    sudo apt install neofetch
  fi
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
  echo "${tty_red}缺少maven 因为maven的安装可能依赖JAVA_HOME 而jdk的版本需求可能各不相同 因此请手动安装maven${tty_reset}"
fi

# node
if command -v node >/dev/null 2>&1 ; then
  echo "${tty_cyan}==>node已经安装过了${tty_reset}"
else
  echo "${tty_red}==>缺少node 开始安装${tty_reset}"
  if [[ -z "${INSTALL_ON_LINUX-}" ]]; then
    # Macos
    if [[ -z "${INSTALL_ON_LINUX-}" ]]; then
      echo "${tty_red}==>系统版本为${ver_cur} 当前版本太低 brew安装不了node 需要手动安装${tty_reset}"
    else
      brew install node
    fi
  else
    # Linux
    sudo apt install nodejs
  fi
fi

# npm
if command -v npm >/dev/null 2>&1 ; then
  echo "${tty_cyan}==>npm已经安装过了${tty_reset}"
else
  echo "${tty_red}==>缺少npm 开始安装${tty_reset}"
  if [[ -z "${INSTALL_ON_LINUX-}" ]]; then
    # Macos
    if [ $ver_cur -le $ver_cmp ]; then
      echo "${tty_red}==>系统版本为${ver_cur} 当前版本太低 brew安装不了npm 需要手动安装${tty_reset}"
    else
      brew install npm
    fi
  else
    # Linux
    sudo apt install npm
  fi
fi

# vscode
code --version
if [ $? -ne 0 ]; then
  echo "${tty_red}==>缺少vscode 开始安装${tty_reset}"
  if [[ -z "${INSTALL_ON_LINUX-}" ]]; then
    # Mac
    brew install visual-studio-code
  else
    # Linux
    sudo apt install visual-studio-code
  fi
fi

# arm-none-eabi
arm-none-eabi-gcc --version
if [ $? -ne 0 ]; then
  echo "${tty_red}==>缺少arm-none-eabi-gcc 开始安装 如果需要指定版本就手动再重新安装${tty_reset}"
  if [[ -z "${INSTALL_ON_LINUX-}" ]]; then
    # Mac
    echo "${tty_red}系统版本<=11时 brew安装不了node高版本 需要手动处理${tty_reset}"
    #brew install arm-none-eabi-gcc
  else
    # Linux
    sudo apt install arm-none-eabi-gcc
  fi
fi

# 配置文件
SETTING_GIT_REPO="dev-env-setting"
SETTING_PATH=${USER_HOME_PREFIX}/${USER_NAME}/MyDev/env/${SETTING_GIT_REPO}
echo "${tty_green}==>配置文件为${SETTING_PATH}${tty_reset}"
if [ ! -d ${SETTING_PATH} ]; then
  echo "${tty_green}配置文件不存在 开始clone远程"
  # 私仓
  /bin/bash -c "git clone git@github.com:Bannirui/${SETTING_GIT_REPO}.git ${SETTING_PATH}"
fi

# zshrc
my_config="${USER_HOME_PREFIX}/${USER_NAME}/.zshrc"
echo "${tty_green}==>配置${my_config}${tty_reset}"
if [ ! -L ${my_config} ]; then
  /bin/bash -c "ln -s ${SETTING_PATH}/zsh/zshrc ${my_config}"
else
  /bin/bash -c "ln -s -f ${SETTING_PATH}/zsh/zshrc ${my_config}"
fi

# vscode
if [[ -z "${INSTALL_ON_LINUX-}" ]]; then
  # Mac
  my_vscode_setting_path="${USER_HOME_PREFIX}/${USER_NAME}/Library/Application Support/Code/User/settings.json"
  my_vscode_keybind_path="${USER_HOME_PREFIX}/${USER_NAME}/Library/Application Support/Code/User/keybindings.json"
else
  # Linux
  my_vscode_setting_path="${USER_HOME_PREFIX}/${USER_NAME}/.config/Code/User/settings.json"
  my_vscode_keybind_path="${USER_HOME_PREFIX}/${USER_NAME}/.config/Code/User/keybindings.json"
fi

if [[ -z "${INSTALL_ON_LINUX-}" ]]; then
  # Mac
  if [ $ver_cur -le $ver_cmp ]; then
    my_vscode_setting_src="${SETTING_PATH}/vscode/setting/settings_hackintosh.json"
  else
    my_vscode_setting_src="${SETTING_PATH}/vscode/setting/settings_mac.json"
  fi
else
  # Linux
  my_vscode_setting_src="${SETTING_PATH}/vscode/setting/settings_linux.json"
fi

echo "${tty_green}==>配置${my_vscode_setting_path}${tty_reset}"
echo "${tty_green}==>配置${my_vscode_keybind_path}${tty_reset}"
if [[ ! -L ${my_vscode_setting_path} ]]; then
  /bin/bash -c "ln -s ${my_vscode_setting_src} '${my_vscode_setting_path}'"
else
  /bin/bash -c "ln -sf ${my_vscode_setting_src} '${my_vscode_setting_path}'"
fi
if [[ ! -L ${my_vscode_keybind_path} ]]; then
  /bin/bash -c "ln -s ${SETTING_PATH}/vscode/setting/keybindings.json '${my_vscode_keybind_path}'"
else
  /bin/bash -c "ln -sf ${SETTING_PATH}/vscode/setting/keybindings.json '${my_vscode_keybind_path}'"
fi

# vimrc
my_config="${USER_HOME_PREFIX}/${USER_NAME}/.vimrc"
echo "${tty_green}==>配置${my_config}${tty_reset}"
if [ ! -L ${my_config} ]; then
  /bin/bash -c "ln -s ${SETTING_PATH}/vim/vimrc ${my_config}"
else
  /bin/bash -c "ln -s -f ${SETTING_PATH}/vim/vimrc ${my_config}"
fi

# ssh config 上面为了临时使用git的ssh创建过了一个文件
my_config="${USER_HOME_PREFIX}/${USER_NAME}/.ssh/config"
echo "${tty_green}==>配置${my_config}${tty_reset}"
if [[ -f ${my_config} ]]; then
  /bin/bash -c "rm -f ${my_config}"
fi
if [ ! -L ${my_config} ]; then
  /bin/bash -c "ln -s ${SETTING_PATH}/ssh/config ${my_config}"
else
  /bin/bash -c "ln -s -f ${SETTING_PATH}/ssh/config ${my_config}"
fi

# maven config
my_config="${USER_HOME_PREFIX}/${USER_NAME}/.m2/settings.xml"
echo "${tty_green}==>配置${my_config}${tty_reset}"
if [ ! -L ${my_config} ]; then
  /bin/bash -c "ln -s ${SETTING_PATH}/maven/maven_settings.xml ${my_config}"
else
  /bin/bash -c "ln -s -f ${SETTING_PATH}/maven/maven_settings.xml ${my_config}"
fi

# idea vimrc
my_config="${USER_HOME_PREFIX}/${USER_NAME}/.ideavimrc"
echo "${tty_green}==>配置${my_config}${tty_reset}"
if [ ! -L ${my_config} ]; then
  /bin/bash -c "ln -s ${SETTING_PATH}/ide/ideavimrc ${my_config}"
else
  /bin/bash -c "ln -s -f ${SETTING_PATH}/ide/ideavimrc ${my_config}"
fi
