program BasicDemo;

uses
  Vcl.Forms,
  BasicDemoMainF in 'BasicDemoMainF.pas' {MainForm},
  NX.Horizon in '..\..\source\NX.Horizon.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
