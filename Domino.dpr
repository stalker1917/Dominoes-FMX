program Domino;

uses
  System.StartUpCopy,
  FMX.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Dominoes in 'Dominoes.pas',
  Debug in 'Debug.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Landscape, TFormOrientation.InvertedLandscape];
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
