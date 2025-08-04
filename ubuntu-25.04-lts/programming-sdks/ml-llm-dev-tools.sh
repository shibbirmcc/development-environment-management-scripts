#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

########################################
# Load utilities (logging, shell-detection, cleanup)
########################################
source "$(dirname "$0")/../../env_utils.sh"
init_logging
detect_source_file
ensure_env_dir

########################################
# LOCAL DIRECTORIES TO STORE ENVIRONMENT SCRIPTS
########################################
ML_LLM_ENV_FILE="$ENVIRONMENT_DIR/.ml-llm"

if [ ! -f "$ML_LLM_ENV_FILE" ]; then
    touch "$ML_LLM_ENV_FILE"
fi

echo "🔍 Detecting Ubuntu version..."
UBUNTU_VERSION=$(lsb_release -rs)
echo "✅ Ubuntu $UBUNTU_VERSION detected."

echo "📦 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "🔧 Installing dependencies..."
sudo apt install -y libnuma-dev wget gnupg2 python3-pip build-essential git curl neofetch htop unzip dkms

echo "📥 Installing Miniconda for isolated Python environment..."
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
bash ~/miniconda.sh -b -p $HOME/miniconda

eval "$($HOME/miniconda/bin/conda shell.bash hook)"
conda init
conda create -n rocm-ml python=3.10 -y
conda activate rocm-ml

echo "🌐 Adding ROCm repo (using Ubuntu 24.04 base for compatibility)..."
wget -qO - http://repo.radeon.com/rocm/rocm.gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/rocm.gpg
echo 'deb [arch=amd64] http://repo.radeon.com/rocm/apt/6.0 ubuntu main' | sudo tee /etc/apt/sources.list.d/rocm.list

echo "📦 Installing ROCm (drivers + runtime)..."
sudo apt update
sudo apt install -y rocm-dev rocm-libs rocm-hip-runtime rocm-opencl rocm-smi

echo "⚙️ Setting up ROCm environment variables..."
echo 'export PATH=/opt/rocm/bin:$PATH' | tee -a $ML_LLM_ENV_FILE
echo 'export LD_LIBRARY_PATH=/opt/rocm/lib:$LD_LIBRARY_PATH' | tee -a $ML_LLM_ENV_FILE
echo 'export HIP_VISIBLE_DEVICES=0' | tee -a $ML_LLM_ENV_FILE
source $ML_LLM_ENV_FILE

# Ensure $ML_LLM_ENV_FILE is sourced in $SOURCE_FILE
marker="source $ML_LLM_ENV_FILE"
if [ -f "$ML_LLM_ENV_FILE" ]; then
    if ! grep -Fq "$marker" "$SOURCE_FILE"; then
        echo "$marker" >> "$SOURCE_FILE"
        log "Added ml-llm env script to $SOURCE_FILE. Please restart your shell or run: source $SOURCE_FILE"
    fi
fi
source $SOURCE_FILE



echo "🔁 Adding your user to video and render groups..."
sudo usermod -a -G video $USER
sudo usermod -a -G render $USER

echo "🧪 Verifying ROCm installation..."
/opt/rocm/bin/rocminfo || echo "❌ ROCm may not be detected, reboot and try again"
/opt/rocm/bin/clinfo || echo "❌ OpenCL info not available, try after reboot"

echo "📦 Installing PyTorch with ROCm..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.0

echo "✅ Done! You may now reboot your system to apply group changes."
echo "🚀 After reboot, activate your environment with: conda activate rocm-ml"
