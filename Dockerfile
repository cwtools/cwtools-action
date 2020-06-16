FROM mcr.microsoft.com/dotnet/core/sdk:3.0

COPY lib /action/lib

RUN apt-get update && \
  apt-get -y install \
  ruby bash git wget p7zip

ENTRYPOINT ["/action/lib/entrypoint.sh"]
