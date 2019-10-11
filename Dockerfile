FROM nvidia/cuda:10.0-cudnn7-devel

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y \
  apt-utils \
  build-essential \
  cmake \
  sudo \
  && rm -rf /var/lib/apt/lists/*

#####################################################################
# Setup ssh service
RUN apt-get update && apt-get install -y \
  openssh-server \
  zsh \
  tmux \
  vim \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

RUN apt-get update && apt-get install -y locales

RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

ENV TZ=America/Chicago
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
#####################################################################

#####################################################################
# Setup X-windows stuff
RUN apt-get update && apt-get install -y \
  xauth \
  x11-apps \
  x11-common \
  x11-session-utils \
  x11-utils \
  x11-xserver-utils \
  && rm -rf /var/lib/apt/lists/*

# Fixed X11 forwarding
RUN echo X11Forwarding yes >> /etc/ssh/sshd_config
RUN sed -i 's/.*X11UseLocalhost.*/X11UseLocalhost no/' /etc/ssh/sshd_config
RUN echo X11UseLocalhost no >> /etc/ssh/sshd_config

#####################################################################

# Install prerequisites for all the opencv stuff
RUN apt-get update && apt-get install -y \
  libgstreamer1.0-0 \
  gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-ugly \
  gstreamer1.0-libav \
  gstreamer1.0-doc \
  gstreamer1.0-tools \
  libdc1394-22-dev \
  libavcodec-dev \
  libavformat-dev \
  libavutil-dev \
  libfreetype6-dev \
  libswscale-dev \
  libswscale4 \
  ffmpeg \
  libharfbuzz-dev \
  libtesseract-dev \
  liblept5 \
  libavresample-dev \
  libgtk-3-0 \
  libgtk-3-dev \
  libhdf5-dev \
  liblapack-dev \
  libeigen3-dev \
  gstreamer1.0-plugins-bad-videoparsers \
  gstreamer1.0-plugins-base-apps \
  libgstreamer1.0-0 \
  libgstreamer1.0-dev \
  libgstreamer-plugins-bad1.0-0 \
  libgstreamer-plugins-bad1.0-dev \
  libgstreamer-plugins-base1.0-0 \
  libgstreamer-plugins-base1.0-dev \
  libgstreamer-plugins-good1.0-0 \
  libgstreamer-plugins-good1.0-dev \
  libqt5gstreamer-1.0-0 \
  libqt5gstreamer-dev \
  qtgstreamer-plugins-qt5 \
  protobuf-compiler \
  libboost-all-dev \
  libgflags-dev \
  libgoogle-glog-dev \
  liblmdb-dev \
  libleveldb-dev \
  libsnappy-dev \
  libatlas-base-dev \
  python-numpy \
  liblapacke \
  liblapacke-dev \
  liblapack3 \
  libv4l-dev \
  v4l-utils \
  doxygen \
  python3-tk \
  && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    python3-pip

RUN python3 -m pip install --upgrade pip setuptools wheel ipython keras

WORKDIR /opt

RUN apt-get update && apt-get install -y \
    cuda-cublas-10-0 \
    cuda-cublas-dev-10-0 \
    git \
    golang \
    libprotobuf-dev \
    libprotoc-dev \
    protobuf-compiler \
    protobuf-compiler-grpc \
    python3-protobuf

RUN apt-get update && apt-get install -y \
    caffe-cuda \
    caffe-tools-cuda \
    libcaffe-cuda-dev \
    python3-caffe-cuda

# RUN git clone --branch 1.0 https://github.com/bvlc/caffe

# RUN cd caffe && mkdir build && cd build \
   # && cmake -D CMAKE_INSTALL_PREFIX=/usr/local -D USE_OPENCV=OFF -Wno-dev \
   # -D CUDA_ARCH_NAME=Manual -D CUDA_ARCH_BIN="35 52 60 61 70" \
   # -D CUDA_ARCH_PTX="70" ..

# RUN cd caffe/build && make all -j"$(nproc)" \
   # && make install -j"$(nproc)" \
   # && cd ../..

# RUN apt-get update && apt-get install -y \
    # python3-opencv

RUN git clone --branch 3.4.3 https://github.com/opencv/opencv
RUN git clone --branch 3.4.3 https://github.com/opencv/opencv_contrib

RUN apt-get update && apt-get install -y \
    libv4l-dev

RUN cd opencv && mkdir build && cd build \
  && cmake -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D WITH_CUDA=ON \
    -D WITH_LIBV4L=ON \
    -D INSTALL_PYTHON_EXAMPLES=ON \
    -D OPENCV_EXTRA_MODULES_PATH=/opt/opencv_contrib/modules \
    -D BUILD_EXAMPLES=ON -D BUILD_DOCS=ON .. \
  && make -j"$(nproc)" \
  && make install -j"$(nproc)" \
  && cd ../.. \
  && rm -fr opencv && rm -fr opencv_contrib

RUN apt-get update && apt-get install -y bc

RUN apt-get install -y ocl-icd-libopencl1

# Tensorboard
EXPOSE 6006

CMD ["/usr/sbin/sshd", "-D"]
