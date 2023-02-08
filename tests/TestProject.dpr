program TestProject;

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnit,
  {$ELSE}
  DUnitTestRunner,
  {$ENDIF}
  NX.Horizon in '..\source\NX.Horizon.pas',
  TestCases in 'TestCases.pas';

{$R *.RES}

begin
  ReportMemoryLeaksOnShutdown := True;
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnit.RunRegisteredTests;
  {$ELSE}
  DUnitTestRunner.RunRegisteredTests;
  {$ENDIF}
end.
