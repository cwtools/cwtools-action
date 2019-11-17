FROM mcr.microsoft.com/dotnet/core/sdk:3.0

LABEL com.github.actions.name="CWTools checks"
LABEL com.github.actions.description="Run CWTools on your HoI4 code in parallel to your builds"
LABEL com.github.actions.icon="code"
LABEL com.github.actions.color="purple"

LABEL maintainer="Antoni Baum <antoni.baum@protonmail.com>"

COPY lib /action/lib

RUN apt-get update && \
  apt-get -y install \
  ruby bash git wget p7zip
RUN mkdir -p /src

RUN git clone --depth=1 --single-branch --branch CLI https://github.com/tboby/cwtools.git /src/cwtools
WORKDIR /src/cwtools/CWToolsCLI
RUN dotnet tool restore
RUN dotnet paket restore
WORKDIR /

RUN git clone --depth=1 https://github.com/tboby/cwtools-hoi4-config.git /src/cwtools-hoi4-config

ENTRYPOINT ["/action/lib/entrypoint.sh"]
