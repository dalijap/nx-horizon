program TestProject;

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  NX.Horizon in '..\source\NX.Horizon.pas',
  TestCases in 'TestCases.pas';

{$R *.RES}

begin
  ReportMemoryLeaksOnShutdown := True;
  DUnitTestRunner.RunRegisteredTests;
end.

