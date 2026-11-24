# PasswordManager

## Wahl der Zugriffsregel: `.biometryCurrentSet` vs. `.userPresence`

Für einen Passwort-Manager ist `.biometryCurrentSet` aus Sicherheitsgründen die bessere Wahl, weil gespeicherte Passwörter automatisch unlesbar werden,
sobald auf dem Gerät ein neues Gesicht oder ein neuer Finger hinzugefügt wird. 
Bei `.userPresence` reicht hingegen auch der Gerätecode aus, und die Einträge bleiben selbst nach einer Änderung der Biometrie weiterhin lesbar. 
Wenn jemand den Gerätecode kennt, könnte er bei `.userPresence` auf alle Passwörter zugreifen oder eigene Biometrie hinzufügen. 
Der Nachteil von `.biometryCurrentSet` ist zwar, dass Einträge nach einem Face-ID-Reset neu angelegt werden müssen, 
aber bei sensiblen Passwörtern ist der höhere Schutz vor unbefugtem Zugriff wichtiger als der Komfort.
