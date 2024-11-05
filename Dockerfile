# Stage 1: Set up base environment with CUDA and basic tools
FROM nvidia/cuda:11.7.1-cudnn8-runtime-ubuntu20.04 AS base
RUN apt-get update && apt-get install -y \
    python3.7 python3-pip git curl wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Stage 2: Install Miniconda and create the MoleculeSTM environment
FROM base AS miniconda-setup
# Download and install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh
ENV PATH="/opt/conda/bin:${PATH}"

# Create MoleculeSTM Conda environment and install dependencies
RUN conda create -y -n MoleculeSTM python=3.7 && \
    conda init bash && \
    echo "source activate MoleculeSTM" > ~/.bashrc

# Activate environment and install core dependencies
# Install core dependencies directly within the MoleculeSTM environment
RUN /opt/conda/bin/conda create -y -n MoleculeSTM python=3.7 && \
    /opt/conda/bin/conda install -n MoleculeSTM -y -c rdkit rdkit=2020.09.1.0 && \
    /opt/conda/bin/conda install -n MoleculeSTM -y -c conda-forge -c pytorch pytorch=1.9.1 cudatoolkit=10.2 && \
    /opt/conda/bin/conda install -n MoleculeSTM -y -c pyg -c conda-forge pyg=2.0.3 && \
    /opt/conda/bin/conda install -n MoleculeSTM -y -c conda-forge numpy=1.21.6 boto3 && \
    /opt/conda/bin/conda run -n MoleculeSTM pip install requests tqdm matplotlib spacy Levenshtein transformers ogb==1.2.0 && \
    /opt/conda/bin/conda run -n MoleculeSTM python -m pip install git+https://github.com/MolecularAI/pysmilesutils.git && \
    /opt/conda/bin/conda run -n MoleculeSTM DS_BUILD_OPS=1 DS_BUILD_UTILS=1 pip install deepspeed




# Stage 3: Set up additional dependencies and MoleculeSTM tools
FROM miniconda-setup AS molecule-tools
# Clone MolBART and install it
RUN git clone https://github.com/MolecularAI/MolBART.git --branch megatron-molbart-with-zinc && \
    cd MolBART/megatron_molbart/Megatron-LM-v1.1.5-3D_parallelism && \
    pip install . && \
    cd ../../..

# Install Apex for mixed precision
RUN git clone https://github.com/chao1224/apex.git && \
    cd apex && \
    pip install -v --disable-pip-version-check --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" ./ && \
    cd ..

# Set the entrypoint
CMD ["/bin/bash"]
