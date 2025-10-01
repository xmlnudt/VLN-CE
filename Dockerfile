FROM hccz95/ubuntu:20.04

RUN ./replace-mirrors.sh

RUN apt-get update && apt-get install -y \
    git wget curl \
    python3-dev \
    python2-dev \
    && rm -rf /var/lib/apt/lists/*

ARG CONDA_PATH=/root/.miniconda3
ENV PATH=$CONDA_PATH/bin:$PATH
ARG CONDA_URL=https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-py37_23.1.0-1-Linux-x86_64.sh
RUN wget --quiet --no-check-certificate $CONDA_URL -O miniconda.sh && \
    bash miniconda.sh -b -p $CONDA_PATH && \
    rm miniconda.sh

# 可选：启用 libmamba 求解器（显著更快更稳定）
RUN $CONDA_PATH/bin/conda install -n base -y conda-libmamba-solver && \
    $CONDA_PATH/bin/conda config --set solver libmamba
RUN conda install -c aihabitat -c conda-forge habitat-sim=0.1.7 headless -y

RUN git clone --branch 0.1.7 https://gh-proxy.com/https://github.com/xmlnudt/habitat-lab.git
RUN git clone https://gh-proxy.com/https://github.com/xmlnudt/VLN-CE.git

SHELL ["/bin/bash", "-lc"]
RUN cd habitat-lab && $CONDA_PATH/bin/pip3 install --no-cache-dir -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/
# RUN cd habitat-lab && $CONDA_PATH/bin/pip3 install --no-cache-dir -r habitat_baselines/rl/requirements.txt -i https://mirrors.aliyun.com/pypi/simple/
# RUN cd habitat-lab && $CONDA_PATH/bin/pip3 install --no-cache-dir -r habitat_baselines/rl/ddppo/requirements.txt -i https://mirrors.aliyun.com/pypi/simple/

# 用sed将requirements.txt中的torch版本改为1.13
RUN cd habitat-lab && sed -i 's/^torch==.*$/torch==1.13/' habitat_baselines/rl/requirements.txt
RUN cd habitat-lab && $CONDA_PATH/bin/pip3 install --no-cache-dir -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/
RUN cd habitat-lab && $CONDA_PATH/bin/pip3 install --no-cache-dir -r habitat_baselines/rl/requirements.txt -i https://mirrors.aliyun.com/pypi/simple/
RUN cd habitat-lab && $CONDA_PATH/bin/pip3 install --no-cache-dir -r habitat_baselines/rl/ddppo/requirements.txt -i https://mirrors.aliyun.com/pypi/simple/

RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN conda init
RUN pip install --no-cache-dir msgpack==1.0.5 msgpack-numpy==0.4.8
RUN cd habitat-lab && python setup.py develop --all

RUN cd VLN-CE && \
    sed -i 's/^torch==.*$/torch==1.13/' requirements.txt && \
    python -m pip install -r requirements.txt

RUN apt-get update && apt-get install -y libgl1-mesa-dev
RUN apt-get update && apt-get install -y xvfb
RUN apt-get update && apt-get install -y libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev libgomp1
RUN pip uninstall lmdb -y && pip install lmdb
RUN pip install gym==0.21

# docker run --rm -it --gpus all -v data:/root/VLN-CE/data test bash
# xvfb-run python run.py --exp-config vlnce_baselines/config/r2r_baselines/nonlearning.yaml --run-type eval
# xvfb-run python run.py --exp-config vlnce_baselines/config/r2r_baselines/seq2seq.yaml --run-type train


# COPY data/scene_datasets/mp3d/v1/tasks/mp3d_habitat.zip ./
# COPY ddppo-models.zip ./
# COPY R2R_VLNCE_v1-3_preprocessed.zip ./
# COPY R2R_VLNCE_v1-3.zip ./



#     unzip data/scene_datasets/mp3d/v1/tasks/mp3d_habitat.zip -d data/scene_datasets/

# RUN gdown https://drive.google.com/uc?id=1T9SjqZWyR2PCLSXYkFckfDeIs6Un0Rjm && \
#     gdown https://drive.google.com/uc?id=1fo8F4NKgZDH-bPSdVU3cONAkt5EW-tyr && \
#     wget https://dl.fbaipublicfiles.com/habitat/data/baselines/v1/ddppo/ddppo-models.zip && \
#     unzip R2R_VLNCE_v1-3_preprocessed.zip -d data/datasets/
#     unzip ddppo-models.zip
