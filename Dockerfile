# Dockerfile for SQANTI3
# https://github.com/ConesaLab/SQANTI3

FROM python:3

MAINTAINER Joel Nitta joelnitta@gmail.com

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update

#########################
### install miniconda ###
#########################

ENV MINICONDA_VERSION py37_4.9.2
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

# Clone SQANTI3 repo
ENV APPNAME SQANTI3
ENV APPS_HOME /apps
RUN mkdir $APPS_HOME
WORKDIR $APPS_HOME
RUN git clone https://github.com/ConesaLab/SQANTI3.git
WORKDIR $APPS_HOME/$APPNAME
# Checkout most recent version at time of building docker image (806893d = v1.6 on Dec 17, 2020)
RUN git checkout 806893d5ef8d26c6177fe3f34a1ad7c25724bf20

# Build SQANTI3 conda environment
ENV ENV_PREFIX /env/$APPNAME
RUN conda update --name base --channel defaults conda && \
    conda env create --prefix $ENV_PREFIX --file $APPS_HOME/$APPNAME/$APPNAME.conda_env.yml --force && \
    conda clean --all --yes

# Install gtfToGenePred dependency
# "that seems to have some issues with Python 3.7 (or openssl) when installed though conda"
RUN wget http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/gtfToGenePred -P $APPS_HOME/$APPNAME/utilities/ && \
    chmod +x $APPS_HOME/$APPNAME/utilities/gtfToGenePred

# Install C-DNA cupcake dependency
# Checkout most recent version at time of building docker image (6cefd47 = v19.0.0 on Jan 18, 2021)

# need to switch shell from default /sh to /bash so that `source` works
SHELL ["/bin/bash", "-c"]
RUN source $CONDA_DIR/etc/profile.d/conda.sh && \
  conda activate /env/$APPNAME && \
  git clone https://github.com/Magdoll/cDNA_Cupcake.git && \
  cd cDNA_Cupcake && \
  git checkout 6cefd4769318712478b0c5adacceae167d19776c && \
  python setup.py build && \
  python setup.py install && \
  conda deactivate
SHELL ["/bin/sh", "-c"]

### Make shell scripts to run conda apps in conda environment ###
# e.g., SQANTI3 scripts can be run with `sqanti3_qc.py --help`

# Make python scripts executable
# sqanti3_RulesFilter.py lacks a shebang. add it here for now, but remove
# this if that gets fixed in the future.
RUN sed -i '1s/^/#!\/usr\/bin\/env python\n/' sqanti3_RulesFilter.py && \
  chmod +x $APPS_HOME/$APPNAME/sqanti3_qc.py && \
  chmod +x $APPS_HOME/$APPNAME/sqanti3_RulesFilter.py

# Make wrapper for sqanti3_qc.py
# needs to SQANTI3 conda env and export path to cDNA cupcake
ENV TOOLNAME sqanti3_qc.py
RUN echo '#!/bin/bash' >> /usr/local/bin/$TOOLNAME && \
  echo "source $CONDA_DIR/etc/profile.d/conda.sh" >> /usr/local/bin/$TOOLNAME && \
  echo "conda activate /env/$APPNAME" >> /usr/local/bin/$TOOLNAME  && \
  echo "export PYTHONPATH=$PYTHONPATH:$APPS_HOME/$APPNAME/cDNA_Cupcake/sequence/" >> /usr/local/bin/$TOOLNAME  && \
  echo "$APPS_HOME/$APPNAME/$TOOLNAME \"\$@\"" >> /usr/local/bin/$TOOLNAME  && \
  chmod 755 /usr/local/bin/$TOOLNAME

# Make wrapper for sqanti3_RulesFilter.py
ENV TOOLNAME sqanti3_RulesFilter.py
RUN echo '#!/bin/bash' >> /usr/local/bin/$TOOLNAME && \
  echo "source $CONDA_DIR/etc/profile.d/conda.sh" >> /usr/local/bin/$TOOLNAME && \
  echo "conda activate /env/$APPNAME" >> /usr/local/bin/$TOOLNAME  && \
  echo "export PYTHONPATH=$PYTHONPATH:$APPS_HOME/$APPNAME/cDNA_Cupcake/sequence/" >> /usr/local/bin/$TOOLNAME  && \
  echo "$APPS_HOME/$APPNAME/$TOOLNAME \"\$@\"" >> /usr/local/bin/$TOOLNAME  && \
  chmod 755 /usr/local/bin/$TOOLNAME

# Now add new tools and make wrapper for protein_classification.py 
# First copy new tool from our local forked repo
COPY src/protein_classification.py $APPS_HOME/$APPNAME/
ENV TOOLNAME protein_classification.py
RUN echo '#!/bin/bash' >> /usr/local/bin/$TOOLNAME && \
  echo "source $CONDA_DIR/etc/profile.d/conda.sh" >> /usr/local/bin/$TOOLNAME && \
  echo "conda activate /env/$APPNAME" >> /usr/local/bin/$TOOLNAME  && \
  echo "export PYTHONPATH=$PYTHONPATH:$APPS_HOME/$APPNAME/cDNA_Cupcake/sequence/" >> /usr/local/bin/$TOOLNAME  && \
  echo "$APPS_HOME/$APPNAME/$TOOLNAME \"\$@\"" >> /usr/local/bin/$TOOLNAME  && \
  chmod 755 /usr/local/bin/$TOOLNAME

# Now add new tools and make wrapper for protein_classification.py first by
# First copy new tool from our local forked repo
COPY src/sample_and_ref_gtf_file_rename_cds_to_exon.py $APPS_HOME/$APPNAME/
ENV TOOLNAME sample_and_ref_gtf_file_rename_cds_to_exon.py
RUN echo '#!/bin/bash' >> /usr/local/bin/$TOOLNAME && \
  echo "source $CONDA_DIR/etc/profile.d/conda.sh" >> /usr/local/bin/$TOOLNAME && \
  echo "conda activate /env/$APPNAME" >> /usr/local/bin/$TOOLNAME  && \
  echo "export PYTHONPATH=$PYTHONPATH:$APPS_HOME/$APPNAME/cDNA_Cupcake/sequence/" >> /usr/local/bin/$TOOLNAME  && \
  echo "$APPS_HOME/$APPNAME/$TOOLNAME \"\$@\"" >> /usr/local/bin/$TOOLNAME  && \
  chmod 755 /usr/local/bin/$TOOLNAME

# Now add new tools and make wrapper for protein_classification.py first by
# First copy new tool from our local forked repo
COPY src/sqanti3_protein.py $APPS_HOME/$APPNAME/
ENV TOOLNAME sqanti3_protein.py
RUN echo '#!/bin/bash' >> /usr/local/bin/$TOOLNAME && \
  echo "source $CONDA_DIR/etc/profile.d/conda.sh" >> /usr/local/bin/$TOOLNAME && \
  echo "conda activate /env/$APPNAME" >> /usr/local/bin/$TOOLNAME  && \
  echo "export PYTHONPATH=$PYTHONPATH:$APPS_HOME/$APPNAME/cDNA_Cupcake/sequence/" >> /usr/local/bin/$TOOLNAME  && \
  echo "$APPS_HOME/$APPNAME/$TOOLNAME \"\$@\"" >> /usr/local/bin/$TOOLNAME  && \
  chmod 755 /usr/local/bin/$TOOLNAME

WORKDIR /root
