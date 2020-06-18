FROM cwtools/cwtools-action:latest

COPY lib /action/lib

ENTRYPOINT ["/action/lib/entrypoint.sh"]
