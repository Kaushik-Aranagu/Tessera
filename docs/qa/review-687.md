
## Delta d49ef6b4: PASS
Master merged in. --self-test now reads TesseraCore/.../Notes/SecretWords.swift as text (read-only open, path from the script's own location, inside the repo), extracts the public words set, requires non-empty and exact equality with SECRET_WORDS. Fails loudly on zero. No new imports, no network, writes nothing. Low: the file handle is not closed (harmless in a self-test).
