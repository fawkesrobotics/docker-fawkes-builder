FROM       quay.io/fedora/fedora:36

COPY mongodb.repo /etc/yum.repos.d/

RUN dnf install -y --nodocs dnf-plugin-ovl && \
  echo "deltarpm=0" >> /etc/dnf/dnf.conf && \
	# Update and clean cache afterwards
	dnf -y --nodocs update && \
  dnf install -y --nodocs 'dnf-command(copr)' && \
  dnf -y copr enable tavie/pddl_parser && \
  dnf -y copr enable thofmann/clips-6.31 && \
  dnf -y copr enable thofmann/clips_protobuf && \
	dnf -y copr enable thofmann/eclipse-clp-6 && \
	dnf -y copr enable thofmann/gologpp && \
	dnf -y copr enable thofmann/planner && \
  dnf -y copr enable thofmann/rcll-refbox && \
  dnf install -y --nodocs --excludepkg fedora-release \
    @buildsys-build \
    @development-tools \
    CGAL-devel \
    SDL-devel \
    SDL_image-devel \
    SDL_net-devel \
    apr-util-devel \
    asciidoc \
    assimp-devel \
    avahi-devel \
    bluez-libs-devel \
    boost-devel \
    bullet-devel \
    bzip2-devel \
    cairomm \
    catch-devel \
    clingo-devel \
    clips \
    clips-emacs \
    clipsmm-devel \
    cmake \
    collada-dom-devel \
    compat-lua \
    compat-lua-devel \
    compat-tolua++-devel \
    console-bridge-devel \
    ctemplate-devel \
    docbook-style-xsl \
    doxygen \
    doxygen-latex \
    eclipse-clp-devel \
    eigen3-devel \
    elfutils-libelf-devel \
    fast-forward \
    file-devel \
    flite-devel \
    fltk-devel \
    freeglut-devel \
    freeimage-devel \
    gazebo-devel \
    gazebo-media \
    gazebo-ode-devel \
    gcc-c++ \
    gconfmm26-devel \
    git \
    glibmm24-devel \
    gologpp-devel \
    gperftools-devel \
    graphviz \
    graphviz-devel \
    gtest-devel \
    gtkmm30-devel \
    gts-devel \
    hokuyoaist-devel \
    hostname \
    kernel-headers \
    libXext-devel \
    libccd-devel \
    libdaemon-devel \
    libdc1394-devel \
    libjpeg-devel \
    libkindrv-devel \
    libkni3-devel \
    libmicrohttpd-devel \
    libmodbus-devel \
    libpng-devel \
    librealsense-devel \
    librealsense1-devel \
    libtool-ltdl-devel \
    libudev-devel \
    libusb-devel \
    libuuid-devel \
    libxml++-devel \
    libxml2-devel \
    libxslt \
    log4cxx-devel \
    lz4-devel \
    make \
    mesa-libGL-devel \
    mesa-libGLU-devel \
    mongo-cxx-driver-devel \
    mongodb-org-server \
    npm \
    ogre-devel \
    opencv-devel \
    openni-devel \
    openssl-devel \
    orocos-bfl-devel \
    orocos-kdl-devel \
    pcl-devel \
    pddl_parser-devel \
    player-devel \
    poco-devel \
    popf \
    protobuf-compiler \
    protobuf-devel \
    protobuf_comm-devel \
    python-collada \
    python-empy \
    python-netifaces \
    python-rosdistro \
    python-rosdistro \
    python-setuptools \
    python3-defusedxml \
    python3-libxml2 \
    python3-numpy \
    python3-pyopengl \
    python3-pyyaml \
    python3-rosdep \
    python3-rosinstall \
    python3-rosinstall \
    python3-rosinstall_generator \
    python3-rospkg \
    python3-rospkg \
    python3-sip-devel \
    python3-wstool \
    rapidjson-devel \
    rcll-refbox \
    readline-devel \
    rrdtool-devel \
    screen \
    sqlite-devel \
    tbb-devel \
    tinyxml-devel \
    tinyxml2-devel \
    tmux \
    urdfdom-devel \
    urdfdom-headers-devel \
    urg-devel \
    websocketpp-devel \
    xmlrpc-c-devel \
    yaml-cpp-devel \
	&& dnf clean all

ENV ROS_DISTRO=noetic \
    SHELL=/bin/bash \
		ROS_BUILD_TYPE=Release \
		ROSCONSOLE_STDOUT_LINE_BUFFERED=1 \
		ROSCONSOLE_FORMAT='[${severity}] [${time}] ${node}: ${message}' \
    ROS_SETUP_BASH=/usr/lib64/ros/setup.bash \
    ROS_SETUP_SH=/usr/lib64/ros/setup.sh

RUN \
  dnf -y copr enable thofmann/ros &&\
  dnf -y install --nodocs \
    ros-desktop_full ros-desktop_full-devel \
    ros-move_base_msgs ros-move_base_msgs-devel \
    ros-tf2_bullet ros-tf2_bullet-devel &&\
  dnf clean all

RUN \
  source /etc/profile &&\
	rosdep init &&\
	rosdep update

COPY profile-ros.sh /etc/profile.d/ros.sh
COPY screenrc /root/.screenrc
RUN mkdir -p /opt/ros
COPY run-env /opt/ros

# ROS_DISTRO set by fedora-ros layer

COPY fawkes-pre.rosinstall /opt/ros/

# Get and compile ROS pre bits
RUN /bin/bash -c "source /etc/profile && \
  mkdir -p /opt/ros/catkin_ws_${ROS_DISTRO}_fawkes_pre/src; \
  cd /opt/ros/catkin_ws_${ROS_DISTRO}_fawkes_pre; \
  wstool init -j $(nproc) src ../fawkes-pre.rosinstall; \
  rosdep install --from-paths src --ignore-src --rosdistro $ROS_DISTRO -y; \
  catkin_make_isolated --install --install-space /opt/ros/$ROS_DISTRO \
    -DCMAKE_BUILD_TYPE=$ROS_BUILD_TYPE || exit $?; \
  rm -rf *_isolated; \
  "

RUN \
  dnf -y --nodocs install ccache clang-tools-extra licensecheck yamllint parallel procps-ng &&\
  dnf clean all

COPY ccache.conf /etc/ccache.conf

RUN \
	pip3 --no-cache-dir install gitlint
