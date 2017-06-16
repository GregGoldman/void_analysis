function dragtest
figure
axes('xlimmode','manual','ylimmode','manual') %<- important
line(0.5,0.5,'marker','s','markersize',10,'hittest','on','buttondownfcn',@clickmarker)

function clickmarker(src,ev)
set(ancestor(src,'figure'),'windowbuttonmotionfcn',{@dragmarker,src})
set(ancestor(src,'figure'),'windowbuttonupfcn',@stopdragging)

function dragmarker(fig,ev,src)
coords=get(gca,'currentpoint');
x=coords(1,1,1);
y=coords(1,2,1);
disp(x)
disp(y)
set(src,'xdata',x,'ydata',y);

function stopdragging(fig,ev)
set(fig,'windowbuttonmotionfcn','')
set(fig,'windowbuttonupfcn','')