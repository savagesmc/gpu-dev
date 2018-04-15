ARG cuda_version=9.0
ARG cudnn_version=7
FROM nvidia/cuda:${cuda_version}-cudnn${cudnn_version}-devel

# Install system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
      bzip2 \
      ca-certificates \
      g++ \
      git \
      graphviz \
      libgl1-mesa-glx \
      libhdf5-dev \
      openmpi-bin \
      tmux \
      vim \
      wget \
      zsh

# Install conda
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH

RUN wget --quiet --no-check-certificate https://repo.continuum.io/miniconda/Miniconda3-4.2.12-Linux-x86_64.sh && \
    echo "c59b3dd3cad550ac7596e0d599b91e75d88826db132e4146030ef471bb434e9a *Miniconda3-4.2.12-Linux-x86_64.sh" | sha256sum -c - && \
    /bin/bash /Miniconda3-4.2.12-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-4.2.12-Linux-x86_64.sh && \
    echo export PATH=$CONDA_DIR/bin:'$PATH' > /etc/profile.d/conda.sh

WORKDIR /build

ARG python_version=3.6

RUN conda install -y python=${python_version} && \
    pip install --upgrade pip && \
    pip install \
      sklearn_pandas \
      tensorflow-gpu

RUN conda install \
      bcolz \
      h5py \
      jupyter \
      matplotlib \
      mkl \
      nose \
      notebook \
      Pillow \
      pandas \
      pygpu \
      pyyaml \
      scikit-learn \
      six \
      theano

RUN pip install cntk-gpu

RUN conda install -y -c numba cudatoolkit=8.0

ARG NUMBA_VERSION=0.38
RUN conda install -y -c numba numba=$NUMBA_VERSION

RUN conda install -y accelerate

RUN git clone git://github.com/keras-team/keras.git && pip install -e keras[tests] && \
    pip install git+git://github.com/keras-team/keras.git && \
    conda clean -yt

ADD theanorc /etc/theanorc

RUN apt-get update && apt-get install -y \
      apt-utils \
      autojump \
      bash \
      build-essential \
      cmake \
      git \
      inetutils-ping \
      net-tools \
      openssh-server \
      python-pip \
      python \
      sudo \
      tcpdump \
      vim

#####################################################################
# Setup ssh service
RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

RUN apt-get update && apt-get install -y locales

RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
#####################################################################

#####################################################################
# Setup X-windows stuff
RUN apt-get update && apt-get install -y \
   x11-apps

# Fixed X11 forwarding
RUN echo X11Forwarding yes >> /etc/ssh/sshd_config
RUN sed -i 's/.*X11UseLocalhost.*/X11UseLocalhost no/' /etc/ssh/sshd_config

#####################################################################

#ENV PYTHONPATH='/src/:$PYTHONPATH'
RUN pip install tf-nightly-gpu

EXPOSE 8888
EXPOSE 6006

#CMD ["jupyter", "notebook", "--port=8888", "--ip=0.0.0.0"]
CMD ["/usr/sbin/sshd", "-D"]
