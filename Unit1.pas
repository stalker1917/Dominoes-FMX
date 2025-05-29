unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls,Dominoes,Debug, FMX.Objects;

const
EtalonWidth = 1200;
EtalonHeight = 540;
DominoPixel=40;


type
  TForm1 = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure Image1Paint(Sender: TObject; Canvas: TCanvas;
      const ARect: TRectF);
  private
    { Private declarations }
  public
    { Public declarations }
  procedure PaintDominoes(Canvas: TCanvas; DotCountA, DotCountB: Integer; const DominoRect: TRectF; Dots:Boolean=True);
  procedure PaintDots(Canvas: TCanvas; X, Y, Radius : Double; Count:Integer; Max: Double; DotColor: TAlphaColor);
  procedure PaintPlayer(i:byte;Top:Integer);
  procedure PaintTable(Index:byte;Arr:TArrSides);
  function GetStep(Count:Byte):Integer;
  function XYToPos(X,Y:Integer):Byte;
  procedure HumanTurn(Pos:Byte; Priority : Boolean = False);
  procedure BotTurn;
  procedure CheckScores(_TurnBot:Boolean=False);
  end;

var
  Form1: TForm1;
  PlayerScore,BotScore:Integer;
  FishFlag :  Integer;
  EndRound : Boolean;
  TurnBot :Boolean;

procedure NewRound;
procedure NewGame;

implementation

{$R *.fmx}

Function EtalonToX(X:Integer):Integer;
begin
  Result:=Round(X*Form1.ClientWidth/EtalonWidth);
end;

Function EtalonToY(Y:Integer):Integer;
begin
  Result:=Round(Y*Form1.ClientHeight/EtalonHeight);
end;

Function EtalonToScreenRect(R:TRect):TRectF;
begin
  result.Left := EtalonToX(R.Left);
  result.Right := EtalonToX(R.Right);
  result.Top:= EtalonToY(R.Top);
  result.Bottom := EtalonToY(R.Bottom);
end;


Function XToEtalon(X:Single):Integer;
begin
  Result:=Round(X*EtalonWidth/Form1.ClientWidth);
end;

Function YToEtalon(Y:Single):Integer;
begin
  Result:=Round(Y*EtalonHeight/Form1.ClientHeight);
end;




procedure NewRound;
begin
  if MainField<>nil then MainField.Destroy;
  if TurnField<>nil then TurnField.Destroy;
  MainField := TDominoes.Create;
  TurnField := TDominoes.Create;
  MainField.NewGame;
  Win := False;
  Lose := False;
  FirstStep := True;
  //NTurn := 0;
  Form1.Label1.Visible := False;
  Form1.Image3.Visible := False;
  FishFlag := 2;
  EndRound := False;
end;

procedure NewGame;
begin
  PlayerScore :=0;
  BotScore :=0;
  Win := False;
  Lose := False;
  NewRound;
end;



procedure TForm1.PaintDominoes;
var
  DotRadius : Double;
  Max : Double;
  DotX, DotY: Double;
  DotColor: TAlphaColor;
  //Center
  VertiCal : Boolean;
  Bitmap : TBitmap;
  BmpRect : TRect;
begin
  DotRadius := EtalontoX(DominoPixel)/10;
  DotColor := TAlphaColors.White;
  Vertical := DominoRect.Height>DominoRect.Width;
  if Vertical then Max := DominoRect.Height/4
              else Max := DominoRect.Width/4;
 {
  Bitmap := TBitmap.Create;
  Bitmap.Width := ROund(DominoRect.Width);
  Bitmap.Height := ROund(DominoRect.Height);
  BmpRect := TRect.Create(TPoint.Create(0,0),Bitmap.Width,Bitmap.Height);
  Bitmap.Canvas.Fill.Color := TAlphaColors.Black;
  Bitmap.Canvas.BeginScene();
  Bitmap.Canvas.FillRect(BmpRect, 0, 0, [], 1);
  Bitmap.Canvas.EndScene();   }



  // Paint dominoes
  Canvas.Fill.Color := TAlphaColors.Black;
  Canvas.FillRect(DominoRect, 0, 0, [], 1); // Draw the filled rectangle
  if not Dots then exit;

   Canvas.Stroke.Color := TAlphaColors.Gray; // Set the pen color
   Canvas.Stroke.Thickness := 1; // Set the pen thickness if needed

    if Vertical then
    begin
      Canvas.DrawLine(
        PointF(DominoRect.Left + 5, DominoRect.Top + DominoRect.Height / 2),
        PointF(DominoRect.Right - 5, DominoRect.Top + DominoRect.Height / 2), 1
      );
    end
    else
    begin
      Canvas.DrawLine(
        PointF(DominoRect.Left + DominoRect.Width / 2, DominoRect.Top + 5),
        PointF(DominoRect.Left + DominoRect.Width / 2, DominoRect.Bottom - 5), 1
      );
    end;

  // Paint dots for part A
  if Vertical then
    begin
      DotX := DominoRect.Left + DominoRect.Width/2;//DotRadius * 2;
      DotY := DominoRect.Top + DominoRect.Height/4;
    end
  else
    begin
      DotX := DominoRect.Left + DominoRect.Width/4;//DotRadius * 2;
      DotY := DominoRect.Top + DominoRect.Height/2;
    end;
  PaintDots(Canvas, DotX, DotY, DotRadius, DotCountA, Max, DotColor);

  // Paint dots for part B
  if Vertical then DotY := DominoRect.Bottom - DominoRect.Height/4
              else DotX := DominoRect.Right - DominoRect.Width/4;//DotRadius * 2;
  PaintDots(Canvas, DotX, DotY, DotRadius, DotCountB, Max, DotColor);
 // Canvas.DrawBitmap(Bitmap,BmpRect,DominoRect,1,false);
end;

procedure TForm1.PaintDots;
var i,j:Integer;
begin
  Canvas.Fill.Color := DotColor;
  case Count of
    1:
      Canvas.FillEllipse(RectF(X - Radius, Y - Radius, X + Radius, Y + Radius), 1);
    2:
      begin
        Canvas.FillEllipse(RectF(X - Radius - Max / 2, Y - Radius - Max / 2, X + Radius - Max / 2, Y- Max / 2 +Radius), 1);
        Canvas.FillEllipse(RectF(X - Radius + Max / 2, Y - Radius + Max / 2, X + Radius + Max / 2, Y + Radius + Max / 2), 1);
      end;
    3:
      for i := -1 to 1 do
        Canvas.FillEllipse(RectF(X - Radius + i*Max / 2, Y - Radius+ i*Max / 2, X + Radius+ i*Max / 2, Y + Radius+ i*Max / 2), 1);
    4:
      for i := -1 to 1 do
        if i<>0 then
          for j := -1 to 1 do
            if j<>0 then Canvas.FillEllipse(RectF(X - Radius + i*Max / 2, Y - Radius+ j*Max / 2, X + Radius+ i*Max / 2, Y + Radius+ j*Max / 2), 1);
    5:
      begin
        for i := -1 to 1 do
        if i<>0 then
          for j := -1 to 1 do
            if j<>0 then Canvas.FillEllipse(RectF(X - Radius + i*Max / 2, Y - Radius+ j*Max / 2, X + Radius+ i*Max / 2, Y + Radius+ j*Max / 2), 1);

        Canvas.FillEllipse(RectF(X - Radius, Y - Radius, X + Radius, Y + Radius), 1);;
      end;
    6:
      for i := -1 to 1 do
        //if i<>0 then
          for j := -1 to 1 do
            if j<>0 then Canvas.FillEllipse(RectF(X - Radius + i*Max / 2, Y - Radius+ j*Max / 2, X + Radius+ i*Max / 2, Y + Radius+ j*Max / 2), 1);
  end;
end;



procedure TForm1.FormCreate(Sender: TObject);
begin
  Randomize;
  {$IFNDEF ANDROID} Dominoes.Debug := TDebug.Initialize('debug.txt');   {$ENDIF}
  NewRound;
end;





procedure TForm1.CheckScores;
var i :Integer;
Scores : Array[0..1] of Byte;
S : String;
begin
  for I := 0 to 1 do Scores[i] := MainField.GetScore(i);
  Label1.Text := 'Рыба';
  Label1.Visible := True;
  Image3.Visible := True;
  TurnBot := _TurnBot;  //Здесь переставляем ход на того, кто обьявил рыбу
  if Scores[0]>Scores[1] then
    begin
      PlayerScore := PlayerScore+Scores[0];
      TurnBot := True;
      Label1.FontColor := TAlphaColors.Blue;
      S := 'Конец раунда';
    end
  else
    if Scores[0]<Scores[1] then
      begin
        BotScore := BotScore+Scores[1];
        Label1.FontColor := TAlphaColors.Red;
        S := 'Конец раунда';
      end
    else  //Явная рыба
      begin
        PlayerScore := PlayerScore+Scores[0];
        BotScore := BotScore+Scores[1];
      end;
  case FishFlag of
    0: TurnBot := False;
    1: TurnBot := True;
    2: Label1.Text := S;
  end;
  Label3.Text := IntToStr(PlayerScore);
  Label5.Text := IntToStr(BotScore);
  EndRound := True;//Может быть конец раунда делаем по клику.
  if (PlayerScore>100) and (PlayerScore>=BotScore)  then  Lose := True;
  if (BotScore>100) and (BotScore>=PlayerScore) then  Win := True;
  if Win then
    if Lose then
      begin
        Label1.FontColor := TAlphaColors.Black;
        Label1.Text:= 'Ничья';
      end
    else
      begin
        Label1.FontColor := TAlphaColors.Maroon;;
        Label1.Text := 'Победа!';
      end
  else
    if Lose then
      begin
        Label1.FontColor := TAlphaColors.Aqua;
        Label1.Text := 'Поражение...';
      end;
end;

procedure TForm1.HumanTurn;
begin
  //Надо как-то считать рыбу
  MainField.Drop(0,Pos,Priority);
  if MainField.High[0]=0 then CheckScores//
  else
    if MainField.Fish(MainField.HighEnd,1) then
      begin
        FishFlag := 0;
        CheckScores;
      end
    else BotTurn;
end;

procedure TForm1.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
FormMouseDown(Sender,Button,Shift, X, Y);
end;

procedure TForm1.Image1Paint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
FormPaint(Sender,Form1.Canvas,Arect);
end;

procedure TForm1.BotTurn;
begin
  if MainField.High[2]=0 then MainField.ScoreTurn(1)
                         else MainField.SimpleTurn(1); //Потом будет HardTurn
  if MainField.High[1]=0  then CheckScores
  else
    if MainField.Fish(MainField.HighEnd,1) then
      begin
        FishFlag := 1;
        CheckScores(True);
      end
    else
      if MainField.NotAnyTurn(0) then
       if not MainField.Find(0) then
         BotTurn;
  //if not MainField.Find(0) then BotTurn;   //Поиск в колоде
end;



procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var
  {GridSize,} CellSize, GridX, GridY: Integer;
  Color:Byte;
  Pos : Byte;
  PosFlag : Boolean;
  //Douples : Boolean;
begin
  if Win or Lose then exit;
  if EndRound then
   begin
     EndRound := False;
     Label1.Visible := False;
     Image3.Visible := False;
     NewRound;
     if TurnBot then BotTurn; //Первый ход бота.
     Invalidate;
     exit;
   end;
  Pos := XYToPos(Round(XtoEtalon(X)),Round(YtoEtalon(Y)));
  if Pos=255 then exit;
  if Pos>=32 then
    begin
      Pos:=Pos-32;
      PosFlag := MainField.Players[0,Pos].B=MainField.HighEnd;
    end
  else PosFlag := MainField.Players[0,Pos].A=MainField.HighEnd;
  if FirstStep then
    if MainField.FindDouples(0) then
      if MainField.Players[0,Pos].A=MainField.Players[0,Pos].B then HumanTurn(Pos)
      else
    else HumanTurn(Pos)
  else
    if MainField.GoodForDrop(0,Pos)>0 then
      if MainField.GoodForDrop(0,Pos)=3 then HumanTurn(Pos,PosFlag)
                                        else HumanTurn(Pos);

 Invalidate;
end;




function TForm1.GetStep;
begin
  if Count<14 then Result := Round(DominoPixel*1.5)
              else Result := Round(DominoPixel*1.5*13/Count);
end;

function TForm1.XYToPos;
var Step:Integer;
begin

  if (Y<530-DominoPixel*2) or (X<Round(DominoPixel*15/50))  then result:=255
  else
    begin
      Step := GetStep(MainField.High[0]);
      result := (X-Round(DominoPixel*15/50)) div Step;
      if result>=MainField.High[0] then result:=255
      else
        if Y>530-DominoPixel then result:=result + 32;
    end;

end;

procedure TForm1.PaintPlayer;
var
  DominoRect: TRect;
  j:Integer;
  Step:Integer;
  DominoSpace : Integer;
begin
  Step := GetStep(MainField.High[i]);
  for j := 0 to MainField.High[i]-1 do
    begin
      //50x100 пикселей ,поменять на динамическую
      DominoSpace := Round(DominoPixel*15/50);
      DominoRect := Rect(j*Step+DominoSpace, Top, j*Step+DominoSpace+DominoPixel, Top+DominoPixel*2); // Adjust the rectangle as needed
      PaintDominoes(Canvas, MainField.Players[i,j].A, MainField.Players[i,j].B, EtalonToScreenRect(DominoRect),i=0);
    end;
end;

procedure TForm1.PaintTable; //Унифицировать
var
X,Y:Integer;
StepMinus : Integer;
DominoRect: TRect;
ScreenDominoRect : TRectF;
Stage : Byte;
Invert : Boolean;
Orientation : Boolean;
var i:Integer;
begin
  if Index=3 then StepMinus:=-1
             else StepMinus:=1;

  X:=512;//ClientWidth div 2; //512
  Stage := 0;
  Invert := False;
  Y:=270;
  for i := 0 to MainField.High[Index]-1 do
    begin
      if (Arr[i].A=Arr[i].B) or (Stage=1) then
        begin
          if (StepMinus>0) then X := X+DominoPixel+2;
          DominoRect := Rect(X-DominoPixel, Y-DominoPixel, X, Y+DominoPixel);
          if (StepMinus<0) then X := X-DominoPixel-2;
          if (Stage=1) then
           begin
             Stage := 2;
             StepMinus := -StepMinus;
             if (X<DominoPixel*2)  then X:=DominoPixel+18
                         else X:=984-DominoPixel div 2;
             if Index=3 then Y:=Y-Round(DominoPixel*1.5)-2
                    else Y:=Y+Round(DominoPixel*1.5)+2;
             //X := 52;
             //Y:= Y-77;
           end;
           Orientation := false;//not (Index=3);
        end
      else
        begin
          if (StepMinus>0) then X := X+DominoPixel*2+2;
          DominoRect := Rect(X-DominoPixel*2, Y-DominoPixel div 2, X, Y+DominoPixel div 2);
          if (StepMinus<0) then X := X-DominoPixel*2-2;
          Orientation := Invert;
        end;

      if Orientation then PaintDominoes(Canvas, Arr[i].B, Arr[i].A, EtalonToScreenRect(DominoRect),true)
                     else PaintDominoes(Canvas, Arr[i].A, Arr[i].B, EtalonToScreenRect(DominoRect),true);
      if (X<DominoPixel*2) or (X>1000-Round(DominoPixel*1.5)-1) then
       if Stage=0 then
         begin
           Stage:=1;
           if (X<DominoPixel*2)  then X:=DominoPixel+18
                       else X:=984-DominoPixel div 2;
           if Index=3 then Y:=Y-Round(DominoPixel*1.5)-2
                      else Y:=Y+Round(DominoPixel*1.5)+2;

         end
      else
       begin
         Stage := 0;
         Invert := not Invert;
       end;
    end;

end;


procedure TForm1.FormPaint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  Canvas.BeginScene;
 // Canvas.Fill.Color:=TAlphaColors.White;
 // Canvas.FillRect(ClientRect,1);    //полностью очищаем форму.
  PaintPlayer(0,530-DominoPixel*2);
  PaintPlayer(1,10);
  PaintTable(3,MainField.TableLow);
  PaintTable(4,MainField.TableHigh);
  Canvas.EndScene;
  //if Image3.Visible then Image3.InvalidateRect(TRectF.Create(0,0,Image3.Width,Image3.Height));
end;






procedure TForm1.FormResize(Sender: TObject);
var ScaleX,ScaleY:Double;
begin

Image1.Position.X := 0;
Image1.Position.Y := 0;
Image1.Height := ClientHeight;
Image1.Width := ClientWidth;


{$IFDEF ANDROID}
ScaleX := ClientWidth/EtalonWidth;
ScaleY := ClientHeight/EtalonHeight;
Label1.Position.X := EtalonToX(250);
Label1.Position.Y := EtalonToY(160);
Label1.Scale.X := ScaleX;
Label1.Scale.Y := ScaleY;
Label2.Position.X := EtalonToX(1057);
Label2.Position.Y := EtalonToY(32);
Label2.Scale.X := ScaleX;
Label2.Scale.Y := ScaleY;
Label3.Position.X := EtalonToX(1073);
Label3.Position.Y := EtalonToY(83);
Label3.Scale.X := ScaleX;
Label3.Scale.Y := ScaleY;
Label4.Position.X := EtalonToX(1057);
Label4.Position.Y := EtalonToY(144);
Label4.Scale.X := ScaleX;
Label4.Scale.Y := ScaleY;
Label5.Position.X := EtalonToX(1073);
Label5.Position.Y := EtalonToY(195);
Label5.Scale.X := ScaleX;
Label5.Scale.Y := ScaleY;
{$ENDIF}
Image2.Position.X := Label2.Position.X-EtalonToX(20);
Image2.Width := Label4.Width + EtalonToX(50);
Image2.Position.Y := Label2.Position.Y -  EtalonToY(20);
Image2.Height := Label5.Position.Y+Label5.Height-Image2.Position.Y +EtalonToY(20);
Image3.Position.X := Label1.Position.X-EtalonToX(10);
Image3.Width := EtalonToX(260);//Label1.Width + EtalonToX(20);
Image3.Position.Y := Label1.Position.Y -  EtalonToY(10);
Image3.Height := Label1.Height + EtalonToY(20);



Invalidate;
end;



end.
