//Copyright 2016 Andrey S. Ionisyan (anserion@gmail.com)
//
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.

// last version: https://github.com/anserion/lex_scanner.git

{Поиск многосимвольных идентификаторов, чисел,             }
{односимвольных и двухсимвольных операций во входном потоке}
program lex_scanner(input, oufput);

type
t_sym=record 
    kind: (nul,oper,num,ident); {тип идентификатора}
    tag:integer;   {вспомогательный элемент число-метка (зарезервировано)}
    i_name:integer;  {числовое имя-код идентификатора для быстрой обработки}
    s_name:string;   {строковое имя идентификатора}
end;

const digits=['0'..'9'];
      eng_letters=['A'..'Z','a'..'z'];
      spec_letters=[',',';','!','%','?','#','$','@','&','^',
                    '/','\','|','=','<','>','(',')','{','}',
                    '[',']','+','-','*','.','''','"','`',':','~'];
//локализация не работает на 2 байта/символ UTF8
//      rus_letters=['А','Б','В','Г','Д','Е','Ё','Ж','З','И','Й'];,
//                   'К','Л','М','Н','О','П','Р','С','Т','У','Ф',
//                   'Х','Ц','Ч','Ш','Щ','Ы','Ь','Ъ','Э','Ю','Я',
//                   'а','б','в','г','д','е','ё','ж','з','и','й',
//                   'к','л','м','н','о','п','р','с','т','у','ф',
//                   'х','ц','ч','ш','щ','ы','ь','ъ','э','ю','я'];

var ch,ch2: char; {последний прочитанный входной символ и следующий за ним}
    start_of_file, end_of_file:boolean;

{прочитать из потока ввода два символа и поместить их в ch, ch2}
procedure getch;
begin
  if end_of_file then begin write('UNEXPECTED END OF FILE'); halt(-1); end;
  if eof(input) then end_of_file:=true;
  if start_of_file then begin ch:=' '; ch2:=' '; end;
  if end_of_file then begin ch:=ch2; ch2:=' '; end;

  if not(end_of_file) and not(start_of_file) then
  begin ch:=ch2; read(ch2); end;

  if not(end_of_file) and start_of_file then
  begin
     read(ch); start_of_file:=false;
     if not(eof(input)) then read(ch2) else ch2:=' ';
  end;
end {getch};

{найти во входном потоке терминальный символ}
function getsym:t_sym;
var id: t_sym;
begin {getsym}
  {пропускаем возможные пробелы и концы строк}
  while (ch=' ')or(ch=chr(10))or(ch=chr(13)) do getch;

  id.s_name:='';
  id.kind:=nul;

  {если ch - буква или знак подчеркивния, то это - начало имени}
  //локализация не работает на 2-х байтовых символах UTF8
  if ch in ['_']+eng_letters{+rus_letters} then
  begin
    id.kind:=ident;
    {читаем посимвольно имя id[], состоящее из букв A-Z, цифр, подчеркивания}
    repeat
      id.s_name:=id.s_name+ch;
      getch;
    until not(ch in ['_']+eng_letters+digits{+rus_letters});
  end
    else
  if ch in digits then {если ch - цифра, то это - начало числа}
  begin
    id.kind:=num;
    repeat
      id.s_name:=id.s_name+ch;
      getch;
    until not(ch in digits);
    if (ch='.')and(ch2 in digits) then
    begin
      id.s_name:=id.s_name+ch;
      getch;
      repeat
        id.s_name:=id.s_name+ch;
        getch;
      until not(ch in digits);
    end;
  end
    else
  if ch in spec_letters then
  begin {односимвольный и некоторые двусимвольные идентификаторы}
    id.kind:=oper;
    {односимвольные спецсимволы}
    id.s_name:=ch;
    {разбор случаев двусимвольных спецкомбинаций}
    if (ch='-')and(ch2='>') then begin id.s_name:='->'; getch; end;
    if (ch='<')and(ch2='-') then begin id.s_name:='<-'; getch; end;
    if (ch='<')and(ch2='>') then begin id.s_name:='<>'; getch; end;
    if (ch='!')and(ch2='=') then begin id.s_name:='!='; getch; end;
    if (ch='=')and(ch2='=') then begin id.s_name:='=='; getch; end;
    if (ch=':')and(ch2='=') then begin id.s_name:=':='; getch; end;
    if (ch='<')and(ch2='=') then begin id.s_name:='<='; getch; end;
    if (ch='>')and(ch2='=') then begin id.s_name:='>='; getch; end;
    if (ch='(')and(ch2='*') then begin id.s_name:='(*'; getch; end;
    if (ch='*')and(ch2=')') then begin id.s_name:='*)'; getch; end;
    if (ch='+')and(ch2='+') then begin id.s_name:='++'; getch; end;
    if (ch='-')and(ch2='-') then begin id.s_name:='--'; getch; end;
    if (ch='*')and(ch2='*') then begin id.s_name:='**'; getch; end;
    if (ch='.')and(ch2='.') then begin id.s_name:='..'; getch; end;
    if (ch=':')and(ch2=':') then begin id.s_name:='::'; getch; end;
    if (ch='/')and(ch2='/') then begin id.s_name:='//'; getch; end;
    if (ch='|')and(ch2='|') then begin id.s_name:='||'; getch; end;
    if (ch='&')and(ch2='&') then begin id.s_name:='&&'; getch; end;
    if (ch='^')and(ch2='^') then begin id.s_name:='^^'; getch; end;
    {смайлики :) }
    if (ch=':')and(ch2=')') then begin id.s_name:=':)'; getch; end;
    if (ch=':')and(ch2='(') then begin id.s_name:=':('; getch; end;
    if (ch=':')and(ch2=']') then begin id.s_name:=':]'; getch; end;
    if (ch=':')and(ch2='[') then begin id.s_name:=':['; getch; end;

    getch;
  end
    else
  begin
    id.s_name:=ch;
    id.kind:=nul;
    getch;
  end;
  getsym:=id;
end {getsym};

var id:t_sym;
begin {основная программа}
start_of_file:=true; end_of_file:=false;

getch;
repeat
    id:=getsym;
    writeln('kind=',id.kind,' name=',id.s_name);
until id.s_name='.';

end.
