ARG base_image=ubuntu:jammy
FROM ${base_image}

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    libssl-dev \
    libreadline-dev \
    libyaml-0-2 \
    locales \
    zip \
    zlib1g-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8 \
 && /usr/sbin/update-locale LANG=en_US.UTF-8 \
 && dpkg-reconfigure -f noninteractive locales

RUN git clone https://github.com/rbenv/rbenv.git $HOME/.rbenv && ln -s $HOME/.rbenv/libexec/rbenv /usr/local/bin

RUN eval "$(rbenv init -)" \
 && git clone https://github.com/rbenv/ruby-build.git $(rbenv root)/plugins/ruby-build

RUN eval "$(rbenv init -)" \
 && git clone https://github.com/sstephenson/rbenv-default-gems.git $(rbenv root)/plugins/rbenv-default-gems \
 && echo 'bundler 2.3.26' >> $(rbenv root)/default-gems

RUN eval "$(rbenv init -)" \
 && rbenv install 3.1.3

RUN eval "$(rbenv init -)" \
 && rbenv install 2.7.6

RUN eval "$(rbenv init -)" \
 && rbenv install 3.0.4

RUN eval "$(rbenv init -)" \
 && rbenv install 3.1.3
