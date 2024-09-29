# Download the Conda installer package
wget -c https://repo.anaconda.com/miniconda/Miniconda3-py39_24.5.0-0-Linux-x86_64.sh

# Install conda
bash Miniconda3-latest-Linux-x86_64.sh

# Navigate to the working directory
cd /path/to/PTpipe/

# Create a PTpipe conda environment
conda env create -f environment.yml

# Enter PTpipe's conda environment
conda activate PTpipe

# Navigate to the config file to modify the working directory
vi ./config/config.yaml
home: /path/to/PTpipe

# Run the PTpipe pipeline
python PTpipe_run.py