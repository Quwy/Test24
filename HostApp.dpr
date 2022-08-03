program HostApp;

uses
  Vcl.Forms,
  uHostForm in 'Source\uHostForm.pas' {fHostForm},
  uVidgetsDllWrapper in 'Source\uVidgetsDllWrapper.pas',
  uVidgetSharedTypes in 'Source\uVidgetSharedTypes.pas';

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfHostForm, fHostForm);
  Application.Run;
end.
