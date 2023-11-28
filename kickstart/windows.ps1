# Installing Chocolatey Package manager

## Allow execution
Set-ExecutionPolicy Bypass -Scope Process

## Install Chocoltey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

## Ensure choco is installed
choco -v

# Install Git from Chocolatey
choco install git

# Change dir to user
cd $env:USERPROFILE

# Make code dir
mkdir code; cd code

# Clone dotfile repo
git clone https://github.com/alvpickmans/dotfiles.git

# Install PowerToys
winget install Microsoft.PowerToys --source winget

# Install starship terminal
winget install starship

# Install Nushell
choco install nushell

# Install Neovim
choco install neovim

# Download CaskaydiaCove font from
# https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/CascadiaCode.zip

# Download VS Code and install Nord theme
# https://code.visualstudio.com/docs/?dv=win

