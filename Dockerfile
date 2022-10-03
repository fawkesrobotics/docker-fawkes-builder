FROM       quay.io/fedora/fedora:36

COPY mongodb.repo /etc/yum.repos.d/

RUN dnf install -y --nodocs dnf-plugin-ovl && \
  echo "deltarpm=0" >> /etc/dnf/dnf.conf && \
	# Update and clean cache afterwards
	dnf -y --nodocs update && \
  dnf install -y --nodocs 'dnf-command(copr)' && \
  #dnf -y copr enable tavie/pddl_parser && \
  dnf -y copr enable thofmann/clips-6.31 && \
  dnf -y copr enable thofmann/clips_protobuf && \
	dnf -y copr enable thofmann/eclipse-clp-6 && \
	dnf -y copr enable thofmann/gologpp && \
	dnf -y copr enable thofmann/planner && \
  dnf install -y --nodocs --excludepkg fedora-release \
    @buildsys-build @development-tools \
	  gcc-c++ git make cmake hostname \
	  doxygen doxygen-latex asciidoc docbook-style-xsl \
	  kernel-headers elfutils-libelf-devel file-devel \
	  yaml-cpp-devel python3-pyyaml tinyxml-devel tinyxml2-devel libxslt xmlrpc-c-devel \
	  libxml2-devel libxml++-devel python3-libxml2 apr-util-devel \
	  boost-devel log4cxx-devel poco-devel readline-devel bzip2-devel \
	  gperftools-devel gtest-devel catch-devel libtool-ltdl-devel sqlite-devel \
	  tbb-devel python-setuptools python3-numpy python3-pyopengl \
	  avahi-devel bluez-libs-devel libmicrohttpd-devel libdaemon-devel \
    npm rapidjson-devel ctemplate-devel websocketpp-devel \
	  openssl-devel libmodbus-devel \
	  libjpeg-devel libpng-devel opencv-devel \
    orocos-kdl-devel orocos-bfl-devel \
	  libusb-devel hokuyoaist-devel libdc1394-devel libkni3-devel \
    librealsense-devel librealsense1-devel \
	  libudev-devel urg-devel libkindrv-devel \
	  flite-devel \
	  urdfdom-headers-devel urdfdom-devel \
	  bullet-devel CGAL-devel eigen3-devel \
	  gts-devel libccd-devel pcl-devel player-devel openni-devel \
	  protobuf-devel protobuf-compiler protobuf_comm-devel \
	  graphviz graphviz-devel rrdtool-devel \
	  mongo-cxx-driver-devel mongodb-org-server \
	  assimp-devel freeimage-devel ogre-devel \
	  mesa-libGL-devel mesa-libGLU-devel freeglut-devel \
	  libXext-devel fltk-devel \
	  SDL-devel SDL_image-devel SDL_net-devel \
	  cairomm gconfmm26-devel glibmm24-devel gtkmm30-devel \
	  gazebo-devel gazebo-ode-devel gazebo-media \
	  python3-rospkg python3-rospkg console-bridge-devel \
	  python-rosdistro python3-rosinstall \
	  python3-wstool python3-rosdep python-rosdistro \
    python3-rosinstall_generator python3-rosinstall \
    python3-defusedxml \
    python3-sip-devel \
	  python-netifaces \
	  clips clipsmm-devel clips-emacs \
    clingo-devel \
    eclipse-clp-devel gologpp-devel \
    #pddl_parser-devel \
    fast-forward popf \
	  compat-lua compat-lua-devel compat-tolua++-devel \
	  collada-dom-devel python-collada python-empy lz4-devel libuuid-devel \
	  screen \
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

# Install refbox, used for testing
RUN \
  dnf -y --nodocs install 'dnf-command(copr)' && \
  dnf -y copr enable thofmann/rcll-refbox && \
  dnf -y --nodocs install rcll-refbox tmux && \
  dnf clean all
