program ObserverDemo;

uses
  Vcl.Forms,
  ObserverDemoMainF in 'ObserverDemoMainF.pas' {MainForm},
  NX.Horizon in '..\..\source\NX.Horizon.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
