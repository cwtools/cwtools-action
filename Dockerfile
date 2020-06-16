FROM mcr.microsoft.com/dotnet/core/sdk:3.0

RUN apt-get update && \
  apt-get -y install \
  ruby bash git wget p7zip
