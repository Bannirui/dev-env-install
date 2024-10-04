# dev-env-install
开发环境的必要工具的安装脚本

### 1 开发工具清单

- Homebrew

- iterm2

- Git

- zsh

- ~~~maven~~~

- node

- npm

- corkscrew

### 2 使用方式

> 当前脚本对配置文件进行软链接 部分配置文件涉及隐私信息 因此放在了私仓

> 在执行如下脚本之前可能需要在终端临时设置环境变量让安装命令走代理

```sh
export http_proxy=http://127.0.0.1:7890
export https_proxy=https://127.0.0.1:7890
export socks5_proxy=socks5://127.0.0.1:7890
```

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Bannirui/dev-env-install/refs/heads/master/install.sh)"
```