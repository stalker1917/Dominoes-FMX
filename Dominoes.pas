unit Dominoes;

interface
uses Debug,SysUtils,Math;
const MaxTurns = 10000;
const MaxSemiTurns = 1666;
type
TSides = record
  A : Byte;
  B : Byte;
end;

TArrSides = Array[0..27] of TSides;

TDominoes = class(TObject)
Players : Array[0..1] of TArrSides;
Stock : TArrSides;
TableLow : TArrSides;
TableHigh: TArrSides;
High : Array[0..5] of byte;      //Последняя для пользовательского массива
LowEnd : Byte;
HighEnd : Byte;
DupelFLag : Boolean;
RatFlags: Array [0..6] of boolean;  //Каких фишек у игрока точно нет.
FullEnumeration :Boolean;
RatPriority : Boolean;
Alpha,Beta : Integer;
Deep : Integer;
DeepMax : Byte;

constructor Create;
destructor Destroy;
procedure CopyData(const F:TDominoes);
procedure Copy(var F:TDominoes);
procedure NewGame;
procedure Take(i:Byte);
function Find(i:Byte):Boolean; //Поиск фигур в колоде
function GetCount(i,Dots:byte):byte; overload;  //Считаем количество доминошек с заданым числом точек
function GetCount(const Arr:TArrSides; Index,Dots:byte):byte; overload;
function FindDominoes(i,A,B:byte):byte;
function FindDominoesArr(const Arr:TArrSides; Index,A,B:byte):byte;
function Rat(i:byte):byte; //Ход по закрышиванию врага
function Fish(i:byte;CurrFish:Byte=0):Boolean;
function GetScore(i:byte):Byte;
function GoodForDrop(i,Pos:byte):byte;
function FindDouples(i:byte):Boolean;
function NotAnyTurn(i:Byte):Boolean;
//procedure Drop(i,Pos:byte); overload;
procedure Drop(i,Pos:byte;Priority:Boolean=False); //overload;
procedure ManualDrop(i,Pos:byte;Priority:Boolean);
procedure LowLevelDrop(var Source,Dest:TArrSides;SIndex,DIndex,Pos:byte);
procedure RandomMix(var Arr:TArrSides; LengthArr:byte);
procedure SimpleTurn(i: Byte);
procedure HardTurn;
procedure EnumerateCombinations(const Buf:TDominoes; L,M,N: Integer;
  const CurrentCombination: TArray<Byte>; Index: byte);
procedure EnumeratePermutations(const CurrentPermutation: TArray<Byte>);
function ScoreTurn(Index:Byte):Integer; // Ход, чтобы полностью оптимизировать очки.
function SubTurn(var ScoreResult:Integer;i,j,DropState:Byte):Boolean;
class function IsElementInArray(element: Byte; const arr: TArray<Byte>): Boolean;
class function NumberToSides(Input:byte):TSides;   //0..27

end;

var

MainField,TurnField : TDominoes;
Win,Lose : Boolean;
Debug : TDebug;
FirstRound : Boolean; //Проверяем, у кого 1:1, 2:2 и т.д.
FirstStep : Boolean;
FullTree : Boolean=False;  //Отображать полное дерево проходов
//Alpha,Beta : Integer;

implementation
constructor TDominoes.Create;
begin
  Inherited Create;
  Deep := 0;
end;

destructor TDominoes.Destroy;
begin
  Inherited Destroy;
end;

procedure TDominoes.Copy(var F: TDominoes);
begin
  F := TDominoes.Create;
  CopyData(F);
  F.Deep := Deep + 1;
end;

procedure TDominoes.CopyData;
begin
  F.Players := Players;
  F.Stock := Stock;
  F.TableLow := TableLow;
  F.TableHigh := TableHigh;
  F.High := High;
  F.HighEnd := HighEnd;
  F.LowEnd := LowEnd;
  F.Alpha := Alpha;
  F.Beta := Beta;
  F.DeepMax := DeepMax;
end;

procedure TDominoes.RandomMix;
var i,j:byte;
Temp : TSides;
begin
  for i := 0 to LengthArr-1 do
    begin
      j := Random(LengthArr);
      Temp := Arr[i];
      Arr[i] := Arr[j];
      Arr[j] := Temp;
    end;
end;



procedure TDominoes.NewGame;
var i,j,Temp: Integer;
TempStock : Array[0..27] of byte;  //27
begin
  for i:= 0 to 4 do High[i] := 0;
  High[2] := 28;
  for i := 0 to 27 do Stock[i]:=NumberToSides(i);
  RandomMix(Stock,28);
  //for i := 0 to 720 do Debug.Log(IntToStr(i)+'-'+IntToStr(TempStock[i]));
  //for i := 0 to 27 do Stock[i] := NumberToSides(TempStock[i]);
  for I := 0 to 6 do
    for j := 0 to 1 do
      Take(j);
  for I := 0 to 6 do RatFlags[i] :=False;
  LowEnd := 7;
  HighEnd := 7;
end;

procedure TDominoes.Take;
begin
  Players[i,High[i]] := Stock[High[2]-1];
  inc(High[i]);
  dec(High[2]);
end;

function TDominoes.Find;
var Sides:TSides;
j:Byte;
begin
  result := False;
  while (High[2]>0) and (result=False) do
    begin
      Take(i);
      Sides := Players[i,High[i]-1];
      result := (Sides.A=LowEnd) or (Sides.B=LowEnd) or (Sides.A=HighEnd) or (Sides.B=HighEnd);
      if (not result) and (i=0) then for j := 0 to 6 do RatFlags[j] :=False; //Взяли карту, значит теперь это количество точек у него может быть
    end;
  if i=0 then
    begin
      RatFlags[LowEnd]:=True; //Разве не важно , человек или машина ходит?
      RatFlags[HighEnd]:=True;
    end;
end;

function TDominoes.GetCount(i,Dots:byte):byte;
begin
  case i of
   0,1: result := GetCount(Players[i],i,Dots);
   2: result := GetCount(Stock,i,Dots);
   3: result := GetCount(TableLow,i,Dots);
   4: result := GetCount(TableHigh,i,Dots);
  end;

end;

function TDominoes.GetCount(const Arr: TArrSides; Index,Dots: Byte): Byte;
var j:Integer;
begin
  Result := 0;
  for j := 0 to High[Index]-1 do
    if Arr[j].A=Dots then inc(Result)
    else if Arr[j].B=Dots then inc(Result);
end;

function TDominoes.FindDominoes;
begin
  case i of
   0,1: result := FindDominoesArr(Players[i],i,A,B);
   2: result := FindDominoesArr(Stock,i,A,B);
   3: result := FindDominoesArr(TableLow,i,A,B);
   4: result := FindDominoesArr(TableHigh,i,A,B);
end;
end;

function TDominoes.FindDominoesArr;
var j:Integer;
begin
  Result := 255;
    for j := 0 to High[Index]-1 do
      begin
        if ((A=Arr[j].A) and (B=Arr[j].B)) or
         ((A=Arr[j].B) and (B=Arr[j].A)) then
           begin
             Result :=j;
             break;
           end;
      end;
end;

function TDominoes.Fish;  //Определяет, можем ли мы поставить рыбу
var j:byte;
begin
  j := GetCount(3,i)+GetCount(4,i);
  result := (j>=(6+CurrFish));
  if CurrFish>0 then exit;
  DupelFLag := False;
  if (j=5) and (FindDominoes(3,i,i)=255) and (FindDominoes(4,i,i)=255) then
    begin
      DupelFLag := True;
      Result := True;
    end;
  //Если дупель ещё не вытянут.
end;

function TDominoes.Rat;
var j,k:Integer;
RatArr : Array [0..6] of byte;
RatIndex :byte;
NotRat :byte;
begin
  RatPriority := False;
  result := 255;
  for j := 0 to 6 do RatArr[j] := GetCount(i,j);
  RatIndex := 0;
  if RatArr[LowEnd]=0 then inc(RatIndex)
                      else NotRat := LowEnd;
  if RatArr[HighEnd]=0 then inc(RatIndex)
  else
   begin
     NotRat := HighEnd;
     RatPriority := True; //Ставим туда где NotRat
   end;
  case RatIndex of
    1:
     for j := 0 to 6 do
       if (RatArr[j]=0) then
         begin
           result := FindDominoes(i xor 1,NotRat,j);
           if result=255 then continue;
           if Fish(j) then  result := result + 128
                      else  break;   //Ищем результаты без рыбы
         end;
    2:
      begin
        result := FindDominoes(i xor 1,LowEnd,LowEnd);
        if result=255 then result := FindDominoes(i xor 1,HighEnd,HighEnd);
        if result=255 then result := FindDominoes(i xor 1,LowEnd,HighEnd);  //Может у нас 2 крысная 1 крысная, карта 2-1 тоже подойдёт.
      end;
  end;
end;



procedure TDominoes.SimpleTurn(i: Byte);
var
RatPos,RatPos2:Byte;
Score1,Score2 : Byte;
//S : TSides;
F : TDominoes;
j: Integer;
DropState:Byte;
MaxIndex,MaxScore : Integer;
MaxHigh,HEnd:Boolean;

begin
  //while MaxIndex=-1 do

  if not FirstStep then RatPos :=Rat(i xor 1)
                   else RatPos := 255;
  if RatPos<>255 then
    if RatPos<128 then
      begin
        Drop(i,RatPos,RatPriority);
        //Иногда идёт сброс не в ту сторону.  Надо выставить 2-1, по единчке , а выставляет по двойке!
        exit;
      end
    else
      begin
        RatPos := RatPos-128;
        Score1 := GetScore(i)-Players[i,RatPos].A-Players[i,RatPos].B;
        Score2 := GetScore(i xor 1);
        if DupelFlag then
         begin
           RatPos2 := FindDominoes(i xor 1,LowEnd,LowEnd);
           if RatPos2=255 then
             begin
               Copy(F);
               F.Find(i xor 1);
               Score2 := GetScore(i xor 1);
               F.Destroy;
             end;
           Score2 := Score2-2*LowEnd;
         end;
        if Score1<Score2 then
          begin
            Drop(i,RatPos); //Если рыба выгодна, то ходим
            exit;
          end;
      end;
  MaxIndex := -1;
  MaxScore := -1;
  MaxHigh := False;
  for j := 0 to High[i]-1 do
   begin
     DropState:= GoodForDrop(i,j);
     if FirstStep then DropState := 3;
     if Dropstate>0 then
       begin
         if (Players[i,j].A=Players[i,j].B) then     //Не дадим дупель отрубить! На первом ходе тоже полезно дупелями ходить
           begin
             MaxIndex := j;
             Break;
           end;
         Score1 := 0;
         Score2 := 0;
         if (Dropstate mod 2 >0)  then
           begin
             Score1 := GetCount(i,HighEnd);
             if Players[i,j].A=LowEnd then Score1 := Score1 + GetCount(i,Players[i,j].B)
                                      else Score1 := Score1 + GetCount(i,Players[i,j].A);

           end;
         if (Dropstate div 2 >0) then
           begin
             Score2 := GetCount(i,LowEnd);
             if Players[i,j].A=HighEnd then Score2 := Score2 + GetCount(i,Players[i,j].B)
                                       else Score2 := Score2 + GetCount(i,Players[i,j].A);
           end;
         HEnd := Score2>Score1;
         if Hend then Score1:=Score2;
         if Score1>MaxScore then
           begin
             MaxScore := Score1;
             MaxIndex := j;
             MaxHigh := Hend;
           end;
       end;
   end;
  if MaxIndex=-1 then
      if Find(i) then SimpleTurn(i)//Drop(i,High[i]-1)  //Повторяем ещё раз с найденной картой.
      else
  else Drop(i,MaxIndex,MaxHigh);
end;

Procedure TDominoes.Drop;
begin
  if FirstStep then
    begin
      LowEnd  := 255;
      HighEnd := Players[i,Pos].B;
      ManualDrop(i,Pos,false) ;
      FirstStep :=False;
    end
  else
  if Priority then
   if (Players[i,Pos].A=HighEnd) or (Players[i,Pos].B=HighEnd) then  ManualDrop(i,Pos,true)
                                                               else  ManualDrop(i,Pos,false)
  else
    if (Players[i,Pos].A=LowEnd) or (Players[i,Pos].B=LowEnd) then  ManualDrop(i,Pos,false)
                                                              else  ManualDrop(i,Pos,true);
end;

Procedure TDominoes.ManualDrop;
//var A:byte;
begin
  if Priority then
    begin
      if (Players[i,Pos].B=HighEnd) then
        begin
          Players[i,Pos].B := Players[i,Pos].A;
          Players[i,Pos].A := HighEnd;
        end;
      HighEnd := Players[i,Pos].B;
      LowLevelDrop(Players[i],TableHigh,i,4,Pos);
    end
  else
    begin
      if (Players[i,Pos].A=LowEnd) then
        begin
          Players[i,Pos].A := Players[i,Pos].B;
          Players[i,Pos].B := LowEnd;
        end;
      LowEnd := Players[i,Pos].A;
      LowLevelDrop(Players[i],TableLow,i,3,Pos);
    end;
end;

Procedure TDominoes.LowLevelDrop;
begin
  Dest[High[Dindex]] := Source[Pos];
  inc(High[Dindex]);
  if Pos<High[Sindex]-1 then Source[Pos] := Source[High[Sindex]-1];
  dec(High[Sindex]);
end;

function TDominoes.NotAnyTurn;
var j,A:Integer;
begin
  A := 0;
  for j := 0 to High[i]-1 do A := A+GoodForDrop(i,j);
  result := (A=0);
end;


function TDominoes.GoodForDrop;
begin
  result := 0;
  if (Players[i,Pos].A=LowEnd) or (Players[i,Pos].B = LowEnd) then inc(result); //1
  if (Players[i,Pos].A=HighEnd) or (Players[i,Pos].B =HighEnd) then result:=result+2; //2 а если оба , то 3
end;

function TDominoes.GetScore;
var j:Integer;
begin
  result := 0;
  if (High[i]=1) and (Players[i,0].A=0) and (Players[i,0].B=0) then result := 10
  else
   for j := 0 to High[i]-1 do  result := result + Players[i,j].A + Players[i,j].B;
end;

function TDominoes.FindDouples;
var j:Integer;
begin
  result := False;
  for j := 0 to High[i]-1 do
    if Players[i,j].A=Players[i,j].B then
      begin
        result := true;
        break;
      end;
end;

procedure TDominoes.HardTurn; //Для честной игры, основанной на вероятностях.
var Buf : TDominoes;
  I,L,M,N: Integer;
  Combinations : Int64;
  Included : TArray<Byte>;

begin
  Buf := TDominoes.Create;
  Copy(Buf);
  High[3] := 0;
  i:=0;
  while i<Buf.High[2] do
    if (RatFlags[Buf.Stock[i].A]) or (RatFlags[Buf.Stock[i].B]) then
      Buf.LowLevelDrop(Buf.Stock,Buf.TableLow,2,3,i)
    else
      inc(i);
  //Появлились 3 массива Table Low - что точно войдёт. Stock и Player[1] - конкуренты
  L := High[3];
  M := High[0];
  N := High[2];
  Combinations := 1;
  for I := N+1 to N+M do Combinations :=  Combinations*i; // (N+M)!/N!
  for I := 1 to M do Combinations := Combinations div i; // (N+M)!/(N!*M!);
  if Combinations<MaxSemiTurns then  //Мало комбинаций, можем перебрать все.
    begin
     for i := 1 to (N+L) do Combinations := Combinations*i;
     FullEnumeration := Combinations<MaxTurns; //При максимуме дозволяется 3 фишки в колоде
     for i := 0 to M-1 do
       Buf.Stock[N+i]:=Buf.Players[0,i];
     EnumerateCombinations(Buf,L,M,N,[],0);
    end;
end;

procedure TDominoes.EnumerateCombinations;
var
  i,j,k: Integer;
  Buf2,Buf3 : TDominoes;
begin
  if Length(CurrentCombination) = N then    //Получили комбинацию
  begin
    // Display or process the combination
    // For example, you can add it to a list, display in a memo, etc.
    Buf2 := TDominoes.Create;
    Buf3 := TDominoes.Create;
    Copy(Buf2);
    k := 0;
    for I := 0 to N do
     begin
      if i=0 then
        for j := 0 to CurrentCombination[i]-1 do
          begin
            Buf2.Players[0,k]:=Buf.Stock[j];
            inc(k);
          end
      else
        for j := CurrentCombination[i-1] + 1 to CurrentCombination[i]-1 do
          begin
            Buf2.Players[0,k]:=Buf.Stock[j];
            inc(k);
          end;
      Buf2.Stock[i] := Buf.Stock[CurrentCombination[i]];
     end;
    for i := N+1 to N+L do
      Buf2.Stock[i] := Buf.TableLow[i-N];
    if FullEnumeration then
     Buf2.EnumeratePermutations([])
    else
      for I := 0 to 9 do  //Если в колоде много фишек, считаем 10 комбинаций расположений для каждой.
        begin
          Buf2.Copy(Buf3);
          Buf3.RandomMix(Buf3.Stock,Buf3.High[2]);
          //Игра в SimpleTurn;
        end;
    Buf2.Destroy;
    Buf3.Destroy;
    //Получаем комбинации
  end
  else
  for i := Index to N+M do  //В Tparallel.for
  begin
    EnumerateCombinations(Buf,L,M,N, CurrentCombination + [i], i + 1);
  end;
end;

procedure TDominoes.EnumeratePermutations;
var
  I: Integer;
  Buf : TDominoes;
  A : TArray<Byte>;
begin
  if Length(CurrentPermutation) = High[2] then
  begin
    // Display or process the permutation
    // For example, you can add it to a list, display in a memo, etc.
    Buf:=TDominoes.Create;
    Copy(Buf);
    for I := 0 to High[2]-1 do
      Buf.Stock[i] := Stock[CurrentPermutation[i]];
    //Игра в Simple Turn
    Buf.Destroy;
  end
  else
  for I := 0 to High[2]-1 do
    if not TDominoes.IsElementInArray(i,CurrentPermutation) then
      EnumeratePermutations(CurrentPermutation + [I]);
end;

function TDominoes.ScoreTurn;
var i:Integer;
LegalTurn:Boolean;
DropState: Byte;
PlayerS,BotS : Integer;
begin
  if Deep=0 then DeepMax := 12;
  if (Deep=DeepMax) or (High[0]=0) or (High[1]=0) or Fish(HighEnd,1) then
    begin
      PlayerS := GetScore(0);
      BotS := GetScore(1);
      if (Fish(HighEnd,1)) and (PlayerS<>BotS) then
        if PlayerS>BotS then result := PlayerS
                        else result := -BotS
      else result := PlayerS-BotS;
     {$IFNDEF ANDROID} if FullTree then Debug.Log('='+IntToStr(result));   {$ENDIF}

      exit;
    end
  else
    begin
      LegalTurn := False;
      if Index=1 then result := -1000
                 else result := 1000;
      if Deep=0 then
        begin
          Alpha := -1000;
          Beta := 1000;
        end;
      for I := 0 to High[Index]-1 do
        begin
          DropState := GoodForDrop(Index,i);
          if DropState>0 then
            begin
              LegalTurn := True;
              if (DropState mod 2) = 1 then
                if SubTurn(Result,Index,i,1) then break;
              if (DropState div 2) = 1 then
                if SubTurn(Result,Index,i,2) then break;
            end;
        end;
      if (not LegalTurn) and (Deep>0) then
        begin
          if DeepMax<100 then DeepMax := DeepMax+1; //Когда пропуск хода, слишком малая глубина
          SubTurn(Result,Index,i,0);
        end
      else if (LegalTurn) and (Deep=0) then
        begin
          TurnField.CopyData(Self);
          {$IFNDEF ANDROID} Debug.Log('Prediction: '+IntToStr(Result));  {$ENDIF}
        end;
    end;
end;

function TDominoes.SubTurn;
var F:TDominoes;
CurrScore : Integer;
begin
  Result := False;
  Copy(F);
  if Dropstate>0 then F.Drop(i,j,Dropstate=2);
 {$IFNDEF ANDROID}  if FullTree then Debug.Log(InttoStr(Players[i,j].A)+':'+InttoStr(Players[i,j].B)+'-'+IntToStr(Deep)); {$ENDIF}

  CurrScore := F.ScoreTurn(i xor 1);
  if ((i=1) and (CurrScore>ScoreResult))
    or ((i=0) and (CurrScore<ScoreResult)) then
      begin
        ScoreResult := CurrScore;
        if Deep=0 then F.CopyData(TurnField);
      end;
  F.Destroy;
  if i=1 then
    if ScoreResult>=Beta then Result := True  //Отсекаем даже равные ветви
                         else Alpha := Max(Alpha,ScoreResult)
  else
    if ScoreResult<=Alpha then Result := True  //Отсекаем даже равные ветви
                          else Beta := Min(Beta,ScoreResult);
end;



class function TDominoes.IsElementInArray(element: Byte; const arr: TArray<Byte>): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := Low(arr) to System.High(arr) do
  begin
    if arr[i] = element then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

class function TDominoes.NumberToSides;
var i:byte;
begin
  for I := 0 to 6 do
    if Input>=(7-i) then Input := Input+i-7
    else
      begin
        result.A := i;
        result.B := Input+i;
        break;
      end;
end;









end.
