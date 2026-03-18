# Using Multistage builds to make the final image smaller.
 
#### Stage one #####
FROM pytorch/pytorch:1.5.1-cuda10.1-cudnn7-runtime as builder

# set work directory
WORKDIR /usr/src/app

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

COPY ./backend/requirements_gpu.txt . 
RUN pip wheel \
	--no-cache-dir \
	--no-deps \
	--wheel-dir \
	/usr/src/app/wheels -r requirements_gpu.txt


### Stage two #####
FROM pytorch/pytorch:1.5.1-cuda10.1-cudnn7-runtime

# This is needed for the openJDK copy-paste to use wget.
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends wget

######################################### Copied from Docker's Openjdk Dockerfile ###############################################
##### https://github.com/docker-library/openjdk/blob/8107dd6c8a2f42c91fd37904fdfe7d4c434ca5fc/16/jdk/buster/Dockerfile ########
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		bzip2 \
		unzip \
		xz-utils \
		\
# utilities for keeping Debian and OpenJDK CA certificates in sync
		ca-certificates p11-kit \
		\
# jlink --strip-debug on 13+ needs objcopy: https://github.com/docker-library/openjdk/issues/351
# Error: java.io.IOException: Cannot run program "objcopy": error=2, No such file or directory
		binutils \
# java.lang.UnsatisfiedLinkError: /usr/local/openjdk-11/lib/libfontmanager.so: libfreetype.so.6: cannot open shared object file: No such file or directory
# java.lang.NoClassDefFoundError: Could not initialize class sun.awt.X11FontManager
# https://github.com/docker-library/openjdk/pull/235#issuecomment-424466077
		fontconfig libfreetype6 \
	; \
	rm -rf /var/lib/apt/lists/*

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8


# backwards compatibility shim
RUN { echo '#/bin/sh'; echo 'echo "$JAVA_HOME"'; } > /usr/local/bin/docker-java-home && chmod +x /usr/local/bin/docker-java-home

# https://jdk.java.net/
# >
# > Java Development Kit builds, from Oracle
# >

ENV JAVA_VERSION 11
RUN apt-get update && apt-get install -y openjdk-11-jdk && apt-get clean && rm -rf /var/lib/apt/lists/*

######################## OpenJDK Done #############################
#
# create directory for the app user
ENV HOME=/home/app
RUN mkdir $HOME


ENV MALLET_BIN_DIRECTORY=$HOME/mallet-2.0.8/bin
# Prepare mallet installation
ADD http://mallet.cs.umass.edu/dist/mallet-2.0.8.tar.gz .
RUN tar -C $HOME -xf mallet-2.0.8.tar.gz; \
	rm mallet-2.0.8.tar.gz; \
	ls $MALLET_BIN_DIRECTORY/mallet # Check the mallet executable is there


RUN set -eux; \
	apt-get update; \
	apt-get install -y gosu; \
	rm -rf /var/lib/apt/lists/*; \
	# verify that the binary works
	gosu nobody true

# create the app user
RUN groupadd -r app -g 999 &&  useradd -r -g app  -u 999 app

## install dependencies
COPY --from=builder /usr/src/app/wheels /wheels
RUN pip install --no-cache /wheels/*; \
	rm -rf /wheels
RUN python -m nltk.downloader stopwords wordnet

# Prepare project data directory, this is actually a volume 
# Handled by docker-compose.yml
ENV PROJECT_DATA_DIRECTORY=$HOME/project_data_directory
# This is similarly a volume.
ENV TRANSFORMERS_CACHE_DIRECTORY=$HOME/transformers_cache_directory
# Flask env to make sure flask doesn't serve
# static files
ENV FLASK_ENV=production

# Setup th app directory
ENV APP_HOME=/home/app/web
RUN mkdir $APP_HOME
# copy project
COPY . $APP_HOME

# chown all the files to the app user
RUN chown -R app:app $HOME

# Needed because all the python imports look like
# from flask_app import ...
# and not from backend.flask_app import ...
WORKDIR $APP_HOME/backend/

ENTRYPOINT [ "../entrypoint.sh" ]
CMD [ "gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "flask_app.app:create_app()" ]
