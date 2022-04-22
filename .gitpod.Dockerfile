# Install the latest gitpod default Docker pacakges
FROM gitpod/workspace-full-vnc:2022-04-21-14-44-14

# Workaround to temp fix the tailscale NO PUBKEY issue 
RUN sudo rm /etc/apt/sources.list.d/tailscale.list

# Use node version manager to install the preferred version of node.js
RUN bash -c ". .nvm/nvm.sh \
    && nvm install 16 \
    && nvm use 16 \
    && nvm alias default 16"

RUN echo "nvm use default &>/dev/null" >> ~/.bashrc.d/51-nvm-fix

# Install Go 1.1x if this is later needed just copy again content from here:
# frist delete the current go version 
RUN rm -rf go
# Install own version with https://github.com/gitpod-io/workspace-images/tree/main/chunks/lang-go
ENV TRIGGER_REBUILD=1
ENV GO_VERSION=1.18
ENV GOPATH=$HOME/go-packages
ENV GOROOT=$HOME/go
ENV PATH=$GOROOT/bin:$GOPATH/bin:$PATH
RUN curl -fsSL https://dl.google.com/go/go$GO_VERSION.linux-amd64.tar.gz | tar xzs && \
# install VS Code Go tools for use with gopls as per https://github.com/golang/vscode-go/blob/master/docs/tools.md
# also https://github.com/golang/vscode-go/blob/27bbf42a1523cadb19fad21e0f9d7c316b625684/src/goTools.ts#L139
    go install -v github.com/uudashr/gopkgs/cmd/gopkgs@v2 && \
    go install -v github.com/ramya-rao-a/go-outline@latest && \
    go install -v github.com/cweill/gotests/gotests@latest && \
    go install -v github.com/fatih/gomodifytags@latest && \
    go install -v github.com/josharian/impl@latest && \
    go install -v github.com/haya14busa/goplay/cmd/goplay@latest && \
    go install -v github.com/go-delve/delve/cmd/dlv@latest && \
    go install -v github.com/golangci/golangci-lint/cmd/golangci-lint@latest && \
    go install -v golang.org/x/tools/gopls@latest && \
    sudo rm -rf $GOPATH/src $GOPATH/pkg /home/gitpod/.cache/go /home/gitpod/.cache/go-build
# user Go packages
ENV GOPATH=/workspace/go \
    PATH=/workspace/go/bin:$PATH


# tell playwright to download browsers into node_modules (within workspace)
ENV PLAYWRIGHT_BROWSERS_PATH=0

# Install packages to improve chromium dep install prebuild process
RUN sudo apt-get update \
    && sudo apt-get install -y \
        fonts-liberation libatk1.0-0 libatspi2.0-0 \
        libcairo2 libfontconfig1 libnspr4 libpango-1.0-0 libxcb1 libxcomposite1 \
        libxdamage1 libxext6 libxfixes3 libxrandr2 libxshmfence1 ttf-unifont \
        xfonts-scalable fonts-ipafont-gothic fonts-tlwg-loma-otf fonts-wqy-zenhei \
        ttf-ubuntu-font-family xfonts-cyrillic fonts-noto-color-emoji libasound2 \
        libatk-bridge2.0-0 libcups2 libdbus-1-3 libdrm2 libfreetype6 libgbm1 \
        libglib2.0-0 libgtk-3-0 libnss3 libx11-6 libx11-xcb1 xvfb \
        moreutils \
    && sudo rm -rf /var/lib/apt/lists/*

# Install kubectl & nice helper tools
RUN brew install kubectl
RUN brew install k9s
RUN brew install c-bata/kube-prompt/kube-prompt

# Set the default shell to zsh rather than sh
ENV SHELL /bin/zsh

# run the installation script
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true

# install plugins
RUN git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
RUN git clone https://github.com/lukechilds/zsh-better-npm-completion ~/.oh-my-zsh/custom/plugins/zsh-better-npm-completion

ADD --chown=gitpod:gitpod .gitpod/HOME/* $HOME/

# prefetch gitstatusd
RUN ~/.oh-my-zsh/custom/themes/powerlevel10k/gitstatus/install

# install 1password cli via direct download
RUN wget https://cache.agilebits.com/dist/1P/op2/pkg/v2.0.2/op_linux_amd64_v2.0.2.zip -O temp.zip \
    && unzip temp.zip \
    && sudo mv op /usr/bin/ \
    && rm temp.zip

# install gcloud
USER root
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
    | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - \
    && apt-get update -y \
    && apt-get install google-cloud-sdk -y
USER gitpod
