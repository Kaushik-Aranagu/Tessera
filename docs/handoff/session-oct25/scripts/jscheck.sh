#!/bin/bash
# parse every <script> block of an HTML file with gjs (SpiderMonkey); prints the first syntax error per block
f="$1"; python3 - "$f" <<'PY'
import re,sys,subprocess,os
s=open(sys.argv[1]).read()
blocks=re.findall(r'<script>(.*?)</script>',s,re.S)
bad=0
for i,b in enumerate(blocks):
    open('/tmp/_blk.js','w').write(b)
    r=subprocess.run(['gjs','-c',"try{new Function(String(imports.gi.GLib.file_get_contents('/tmp/_blk.js')[1]));print('OK')}catch(e){print('SYNTAX ERROR: '+e.message+' line '+e.lineNumber)}"],capture_output=True,text=True)
    out=(r.stdout.strip().split('\n')[-1]) if r.stdout.strip() else r.stderr.strip()[-200:]
    if 'OK' not in out:bad+=1;print('block',i,':',out)
# a stray <script> inside a block means an unclosed one
if re.search(r'<script>(?:(?!</script>).)*<script>',s,re.S):bad+=1;print('UNCLOSED <script> somewhere')
print(os.path.basename(sys.argv[1]),'blocks',len(blocks),'OK' if not bad else 'PROBLEMS '+str(bad))
PY
