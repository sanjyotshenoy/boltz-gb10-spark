#!/bin/bash
set -e  # Exit immediately if any command fails

echo ">>> Step 0: Checking Python Version..."
if ! python3 -c 'import sys; exit(0) if sys.version_info >= (3, 12) else exit(1)'; then
    echo "ERROR: Unsupported Python version. Requires 3.12+"
    exit 1
fi
echo "✓ Python version is compatible."

echo ">>> Step 1: Installing PyTorch Nightly (CUDA 13.0)..."
# We install this FIRST to ensure the environment prefers the GPU version.
pip3 install torch torchvision --index-url https://download.pytorch.org/whl/cu130

echo ">>> Step 2: Installing Project..."
# Install the project in editable mode.
# This might pull in 'cuequivariance' dependencies, which we will fix in the next step.
pip install -e .[cuda]

echo ">>> Step 4: Fixing Triton (For Blackwell/SM100)..."
# Torch likely installed a standard version of Triton. We need the Nightly for Blackwell.
echo "    - Removing standard Triton..."
pip uninstall -y triton || true
echo "    - Installing Triton Nightly..."
pip install --index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/Triton-Nightly/pypi/simple/ triton

echo ">>> Step 3: Sanitizing CUDA Kernels (The 'Namespace Collision' Fix)..."
# The project installation might have pulled in CUDA 12 variants. We must kill them.
echo "    - Removing conflicting CUDA 12 packages..."
pip uninstall -y cuequivariance-ops-cu12 cuequivariance-ops-torch-cu12 || true

echo "    - Forcing installation of CUDA 13 Ops..."
# We explicitly install the version that matches your Blackwell/GB10 GPU
pip install "cuequivariance-ops-torch-cu13>=0.8.0" cuequivariance-torch>=0.8.0

echo ">>> Step 5: Final Verification..."
python3 -c "import torch; print(f'Torch: {torch.__version__} (CUDA: {torch.cuda.is_available()})')"
python3 -c "import triton; print(f'Triton: {triton.__version__}')"
# # Verify the specific ops library loads without the 'libcublas' error
# python3 -c "import cuequivariance_ops_torch; print(f'Cuequivariance Ops: LOADED SUCCESSFULLY')"

echo "----------------------------------------------------------------"
echo ">>> SUCCESS. You are ready to run:"
echo "    boltz predict ..."
echo "----------------------------------------------------------------"