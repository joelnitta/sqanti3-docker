# Dockerfile for SQANTI3
# https://github.com/ConesaLab/SQANTI3

FROM python:3

LABEL org.opencontainers.image.authors="Joel Nitta joelnitta@gmail.com"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update

#########################
### install miniconda ###
#########################

ENV MINICONDA_VERSION py37_4.10.3
ENV CONDA_DIR /miniconda3

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-$MINICONDA_VERSION-Linux-x86_64.sh -O ~/miniconda.sh && \
    chmod +x ~/miniconda.sh && \
    ~/miniconda.sh -b -p $CONDA_DIR && \
    rm ~/miniconda.sh

# make non-activate conda commands available
ENV PATH=$CONDA_DIR/bin:$PATH

# make conda activate command available from /bin/bash --login shells
RUN echo ". $CONDA_DIR/etc/profile.d/conda.sh" >> ~/.profile

# make conda activate command available from /bin/bash --interative shells
RUN conda init bash

########################################
### build conda environment: SQANTI3 ###
########################################

# Create /apps for installing software
ENV APPS_HOME /apps
RUN mkdir $APPS_HOME

# Download SQANTI3 and build conda env
WORKDIR $APPS_HOME
ENV APPNAME SQANTI3
ENV VERSION 5.1.1
ENV ENV_PREFIX /env/$APPNAME
RUN wget https://github.com/ConesaLab/$APPNAME/archive/refs/tags/v$VERSION.tar.gz && \
  tar xf v$VERSION.tar.gz && \
  rm v$VERSION.tar.gz && \
  cd $APPNAME-$VERSION && \
  conda update --name base --channel defaults conda && \
  conda env create --prefix $ENV_PREFIX --file $APPS_HOME/$APPNAME-$VERSION/$APPNAME.conda_env.yml --force && \
  conda clean --all --yes

# Install C-DNA cupcake dependency in SQANTI3 conda environment
WORKDIR $APPS_HOME/$APPNAME-$VERSION/
ENV CCVER 28.0.0

RUN wget https://github.com/Magdoll/cDNA_Cupcake/archive/refs/tags/v$CCVER.tar.gz && \
  tar xf v$CCVER.tar.gz && \
  rm v$CCVER.tar.gz

# Need to switch shell from default /sh to /bash so that `source` works.
SHELL ["/bin/bash", "-c"]
RUN source $CONDA_DIR/etc/profile.d/conda.sh && \
  conda activate $ENV_PREFIX && \
  cd cDNA_Cupcake-$CCVER && \
  python setup.py build && \
  python setup.py install && \
  conda deactivate
SHELL ["/bin/sh", "-c"]

### Make shell scripts to run conda apps in conda environment ###
# e.g., SQANTI3 scripts can be run with `sqanti3_qc.py --help`

# Make python scripts executable 
RUN chmod +x $APPS_HOME/$APPNAME-$VERSION/sqanti3_qc.py && \
  chmod +x $APPS_HOME/$APPNAME-$VERSION/sqanti3_filter.py

# Make wrapper for sqanti3_qc.py
# needs to SQANTI3 conda env and export path to cDNA cupcake
ENV TOOLNAME sqanti3_qc.py
RUN echo '#!/bin/bash' > /usr/local/bin/$TOOLNAME && \
  echo "source $CONDA_DIR/etc/profile.d/conda.sh" >> /usr/local/bin/$TOOLNAME && \
  echo "conda activate $ENV_PREFIX" >> /usr/local/bin/$TOOLNAME && \
  echo "export PYTHONPATH=$PYTHONPATH:$APPS_HOME/$APPNAME-$VERSION/cDNA_Cupcake-$CCVER/sequence/" >> /usr/local/bin/$TOOLNAME && \
  echo "$APPS_HOME/$APPNAME-$VERSION/$TOOLNAME \"\$@\"" >> /usr/local/bin/$TOOLNAME && \
  chmod 755 /usr/local/bin/$TOOLNAME

# Make wrapper for sqanti3_filter.py
ENV TOOLNAME sqanti3_filter.py
RUN echo '#!/bin/bash' > /usr/local/bin/$TOOLNAME && \
  echo "source $CONDA_DIR/etc/profile.d/conda.sh" >> /usr/local/bin/$TOOLNAME && \
  echo "conda activate $ENV_PREFIX" >> /usr/local/bin/$TOOLNAME && \
  echo "export PYTHONPATH=$PYTHONPATH:$APPS_HOME/$APPNAME-$VERSION/cDNA_Cupcake-$CCVER/sequence/" >> /usr/local/bin/$TOOLNAME && \
  echo "$APPS_HOME/$APPNAME-$VERSION/$TOOLNAME \"\$@\"" >> /usr/local/bin/$TOOLNAME && \
  chmod 755 /usr/local/bin/$TOOLNAME

WORKDIR /root
