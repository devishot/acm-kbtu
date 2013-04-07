var n,i,s:integer;

begin s:=0;
assign(input,'input.txt'); reset(input);
assign(output,'output.txt'); rewrite(output);
read(n)
for i:=1 to n do
s:=s+i;
write(s);
end.
