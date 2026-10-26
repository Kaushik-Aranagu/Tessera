import re,sys
s=open(sys.argv[1]).read()
src='\n'.join(re.findall(r'<script>(.*?)</script>',s,re.S))
st=[];i=0;n=len(src);prev='';pairs={')':'(',']':'[','}':'{'};ok=True;line=1
while i<n:
    c=src[i]
    if c=='\n':line+=1
    if c in '"\'`':
        q=c;i+=1
        while i<n and src[i]!=q:
            if src[i]=='\\':i+=1
            if src[i]=='\n':
                if q!='`':print('newline in string',line);ok=False;break
                line+=1
            i+=1
        i+=1;prev='x';continue
    if src.startswith('//',i):
        while i<n and src[i]!='\n':i+=1
        continue
    if src.startswith('/*',i):
        j=src.index('*/',i);line+=src[i:j].count('\n');i=j+2;continue
    if c=='/' and prev in '(,=:[!&|?{};+':
        i+=1;cls=False
        while i<n:
            if src[i]=='\\':i+=2;continue
            if src[i]=='[':cls=True
            elif src[i]==']':cls=False
            elif src[i]=='/' and not cls:break
            i+=1
        i+=1;prev='x';continue
    if c in '([{':st.append((c,line))
    elif c in ')]}':
        if not st or st[-1][0]!=pairs[c]:print('mismatch',c,'line',line,st[-1:]);ok=False;break
        st.pop()
    if not c.isspace():prev=c
    i+=1
print('OK' if ok and not st else ('UNCLOSED',st[-3:]))
