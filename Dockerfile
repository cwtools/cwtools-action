FROM volgakurvar/cwtools-action:1.0.0-dotnet

COPY lib /action/lib

ENTRYPOINT ["/action/lib/entrypoint.sh"]
