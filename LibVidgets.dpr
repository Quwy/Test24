library LibVidgets;

uses
  System.SysUtils,
  System.Classes,

  uWindows in 'Source\uWindows.pas',
  uVidgetSharedTypes in 'Source\uVidgetSharedTypes.pas',
  uVidgetsProcs in 'Source\uVidgetsProcs.pas',
  uVidgetsClasses in 'Source\uVidgetsClasses.pas';


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

function CreateVidgetClass(const ClassName: UnicodeString; const PaintProc: TWidgetPaintProc; const EventProc: TWidgetSystemEventProc): LongWord; stdcall;
begin
  Result := VgCreateVidgetClass(ClassName, PaintProc, EventProc);
end;

function CreateVidget(const ClassName: UnicodeString; const ParentID: NativeUInt; const WidgetProps: TWidgetProps; const UserData: Pointer; const EventProc: TWidgetUserEventProc; out ID: NativeUInt): LongWord; stdcall;
begin
  Result := VgCreateVidget(ClassName, ParentID, WidgetProps, UserData, EventProc, ID);
end;

function CreateWidgetProps(const Color: Cardinal; const Left, Top, Width, Height: Integer): TWidgetProps; stdcall;
begin
  Result := VgCreateWidgetProps(Color, Left, Top, Width, Height);
end;

function UpdateWidgetUserData(const ID: NativeUInt; const UserData: Pointer): LongWord; stdcall;
begin
  Result := VgUpdateWidgetUserData(ID, UserData);
end;

function UpdateWidgetVisibility(const ID: NativeUInt; const Visible: Boolean): LongWord; stdcall;
begin
  Result := VgUpdateWidgetVisibility(ID, Visible);
end;

exports
  ErrorText,
  Init,
  Deinit,
  Repaint,
  CreateVidgetClass,
  CreateVidget,
  CreateWidgetProps,
  UpdateWidgetUserData,
  UpdateWidgetVisibility;

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
end.
