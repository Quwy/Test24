{ DLL wrapper to the internal vidgets API
  All function descriptions see in the uVidgetsProcs unit }

library LibVidgets;

uses
  System.SysUtils,
  System.Classes,
  uWindows in 'Source\uWindows.pas',
  uVidgetSharedTypes in 'Source\uVidgetSharedTypes.pas',
  uVidgetsProcs in 'Source\uVidgetsProcs.pas',
  uVidgetsClasses in 'Source\uVidgetsClasses.pas',
  uInternalTypes in 'Source\uInternalTypes.pas';

{$R *.res}

function ErrorText(const ErrorCode: LongWord): UnicodeString; stdcall;
begin
  Result := VgErrorText(ErrorCode);
end;

function Init(const Container: NativeUInt): LongWord; stdcall;
begin
  Result := VgInit(Container);
end;

function Deinit: LongWord; stdcall;
begin
  Result := VgDeinit;
end;

function Repaint: LongWord; stdcall;
begin
  Result := VgRepaint;
end;

function CreateVidgetClass(const ClassName: UnicodeString; const PaintProc: TVidgetPaintProc; const EventProc: TVidgetSystemEventProc): LongWord; stdcall;
begin
  Result := VgCreateVidgetClass(ClassName, PaintProc, EventProc);
end;

function CreateVidget(const ClassName: UnicodeString; const ParentID: NativeUInt; const VidgetProps: TVidgetProps; const UserData: Pointer; const EventProc: TVidgetUserEventProc; out ID: NativeUInt): LongWord; stdcall;
begin
  Result := VgCreateVidget(ClassName, ParentID, VidgetProps, UserData, EventProc, ID);
end;

function CreateVidgetProps(const Color: Cardinal; const Left, Top, Width, Height: Integer): TVidgetProps; stdcall;
begin
  Result := VgCreateVidgetProps(Color, Left, Top, Width, Height);
end;

function UpdateVidgetUserData(const ID: NativeUInt; const UserData: Pointer): LongWord; stdcall;
begin
  Result := VgUpdateVidgetUserData(ID, UserData);
end;

function UpdateVidgetVisibility(const ID: NativeUInt; const Visible: Boolean): LongWord; stdcall;
begin
  Result := VgUpdateVidgetVisibility(ID, Visible);
end;

exports
  ErrorText,
  Init,
  Deinit,
  Repaint,
  CreateVidgetClass,
  CreateVidget,
  CreateVidgetProps,
  UpdateVidgetUserData,
  UpdateVidgetVisibility;

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
end.
