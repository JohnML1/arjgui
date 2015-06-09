program arjgui;

{$MODE Delphi}

uses
  Forms, Interfaces,
  Unit1 in 'Unit1.pas' {MainForm1}{,
  StringGridUtils in '../../../comp/CLX/source/StringGridUtils.pas'};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm1, MainForm1);
  Application.Run;
end.
