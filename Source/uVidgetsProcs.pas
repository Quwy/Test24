unit uVidgetsProcs;

interface

uses
  uVidgetSharedTypes,
  uVidgetsClasses,
  System.Classes,
  System.SysUtils,
  System.Types;

function VgErrorText(const ErrorCode: LongWord): UnicodeString;

function VgInit(const Container: NativeUInt): LongWord;
function VgDeinit: LongWord;
function VgRepaint: LongWord;

function VgCreateVidgetClass(const ClassName: UnicodeString; const PaintProc: TWidgetPaintProc; const EventProc: TWidgetSystemEventProc): LongWord;
function VgCreateVidget(const ClassName: UnicodeString; const ParentID: NativeUInt; const WidgetProps: TWidgetProps; const UserData: Pointer; const EventProc: TWidgetUserEventProc; out ID: NativeUInt): LongWord;
function VgCreateWidgetProps(const Color: Cardinal; const Left, Top, Width, Height: Integer): TWidgetProps;
function VgUpdateWidgetUserData(const ID: NativeUInt; const UserData: Pointer): LongWord;
function VgUpdateWidgetVisibility(const ID: NativeUInt; const Visible: Boolean): LongWord;


implementation

{$IFDEF MSWINDOWS}

uses
  uWindows;

{$ELSE}
  {$ERROR 'Platform not implemented'}
{$ENDIF}

const
  VG_MAX_ERROR = 6;

  ERROR_STRINGS: array[0..VG_MAX_ERROR + 1] of UnicodeString =
    ('Success',
     'Invalid container',
     'Container not initialized',
     'Class name already registered',
     'Class name not registered',
     'Parent not found',
     'Widget not found',
     'Invalid error code');

var
  RootWidget: TWidget;
  ClassHeaders: TClassHeaders;

procedure PaintProc(const PaintAPI: TPaintAPI);
begin
  RootWidget.Paint(PaintAPI);
end;

procedure EventProc(const EventAPI: TEventAPI);
begin
  RootWidget.Event(EventAPI);
end;

function VgErrorText(const ErrorCode: LongWord): UnicodeString;
begin
  if ErrorCode <= VG_MAX_ERROR then
    Result := ERROR_STRINGS[ErrorCode]
  else
    Result := ERROR_STRINGS[VG_MAX_ERROR + 1];
end;

function VgInit(const Container: NativeUInt): LongWord;
var
  Width, Height: LongInt;
begin
  if OsInitContainer(Container, PaintProc, EventProc, Width, Height) then
    begin
      RootWidget := TWidget.Create(OsRGB(64, 64, 64), Width, Height);
      Result := VG_ERROR_SUCCESS;
    end
  else
    Result := VG_ERROR_INVALID_CONTAINER;
end;

function VgDeinit: LongWord;
begin
  if OsDeinitContainer then
    begin
      RootWidget.Free;
      Result := VG_ERROR_SUCCESS;
    end
  else
    Result := VG_ERROR_NOT_INITIALIZED;
end;

function VgCreateVidgetClass(const ClassName: UnicodeString; const PaintProc: TWidgetPaintProc; const EventProc: TWidgetSystemEventProc): LongWord;
begin
  if ClassHeaders.IndexOfName(ClassName) <= 0 then
    begin
      ClassHeaders.Add(TClassHeader.Create(ClassName, PaintProc, EventProc));
      Result := VG_ERROR_SUCCESS;
    end
  else
    Result := VG_ERROR_CLASS_ALREADY_REGISTERED;
end;

function VgCreateVidget(const ClassName: UnicodeString; const ParentID: NativeUInt; const WidgetProps: TWidgetProps; const UserData: Pointer; const EventProc: TWidgetUserEventProc; out ID: NativeUInt): LongWord;
var
  ClassIdx: Integer;
  Widget: TChildWidget;
  ParentWidget: TWidget;
begin
  ClassIdx := ClassHeaders.IndexOfName(ClassName);
  if ClassIdx >= 0 then
    begin
      Result := VG_ERROR_SUCCESS;

      if ParentID > 0 then
        begin
          ParentWidget := RootWidget.WidgetByID(ParentID);
          if not Assigned(ParentWidget) then
            Result := VG_ERROR_PARENT_NOT_FOUND;
        end
      else
        ParentWidget := RootWidget;

      if Result = VG_ERROR_SUCCESS then
        begin
          Widget := TChildWidget.Create(ClassName, ParentWidget, WidgetProps, ClassHeaders[ClassIdx].PaintProc, ClassHeaders[ClassIdx].SystemEventProc, UserData);
          Widget.UserEventProc := EventProc;
          ID := Widget.ID;
        end;
    end
  else
    Result := VG_ERROR_CLASS_NOT_REGISTERED;
end;

function VgCreateWidgetProps(const Color: Cardinal; const Left, Top, Width, Height: Integer): TWidgetProps;
begin
  Result.Color := Color;
  Result.Dimensions.Left := Left;
  Result.Dimensions.Top := Top;
  Result.Dimensions.Width := Width;
  Result.Dimensions.Height := Height;
end;

function VgRepaint: LongWord;
begin
  if OsRepaintContainer then
    Result := VG_ERROR_SUCCESS
  else
    Result := VG_ERROR_NOT_INITIALIZED;
end;

function VgUpdateWidgetUserData(const ID: NativeUInt; const UserData: Pointer): LongWord;
var
  Widget: TChildWidget;
begin
  Widget := RootWidget.WidgetByID(ID);
  if Assigned(Widget) then
    begin
      Widget.UserData := UserData;
      Widget.Parent.NeedRepaint;
      Result := VG_ERROR_SUCCESS;
    end
  else
    Result := VG_ERROR_WIDGET_NOT_FOUND;
end;

function VgUpdateWidgetVisibility(const ID: NativeUInt; const Visible: Boolean): LongWord;
var
  Widget: TChildWidget;
begin
  Widget := RootWidget.WidgetByID(ID);
  if Assigned(Widget) then
    begin
      Widget.Vidible := Visible;
      Widget.NeedRepaint;
      Result := VG_ERROR_SUCCESS;
    end
  else
    Result := VG_ERROR_WIDGET_NOT_FOUND;
end;

procedure PanelPaintProc(ClassName: PWideChar; ID: NativeUInt; PaintAPI: TPaintAPI; WidgetProps: PWidgetProps; var UserData: Pointer); stdcall;
begin
  PaintAPI.FillRect(WidgetProps^.Color, WidgetProps^.Dimensions.Left, WidgetProps^.Dimensions.Top, WidgetProps^.Dimensions.Left + WidgetProps^.Dimensions.Width, WidgetProps^.Dimensions.Top + WidgetProps^.Dimensions.Height);
end;

procedure LabelPaintProc(ClassName: PWideChar; ID: NativeUInt; PaintAPI: TPaintAPI; WidgetProps: PWidgetProps; var UserData: Pointer); stdcall;
begin
  PaintAPI.FillRect(WidgetProps^.Color, WidgetProps^.Dimensions.Left, WidgetProps^.Dimensions.Top, WidgetProps^.Dimensions.Left + WidgetProps^.Dimensions.Width, WidgetProps^.Dimensions.Top + WidgetProps^.Dimensions.Height);
  PaintAPI.OutText(OsRGB(0, 0, 0), WidgetProps^.Dimensions.Left, WidgetProps^.Dimensions.Top, WidgetProps^.Dimensions.Left + WidgetProps^.Dimensions.Width, WidgetProps^.Dimensions.Top + WidgetProps^.Dimensions.Height, PWideChar(UserData));
end;

procedure ButtonPaintProc(ClassName: PWideChar; ID: NativeUInt; PaintAPI: TPaintAPI; WidgetProps: PWidgetProps; var UserData: Pointer); stdcall;
begin
  PaintAPI.FillRect(WidgetProps^.Color, WidgetProps^.Dimensions.Left, WidgetProps^.Dimensions.Top, WidgetProps^.Dimensions.Left + WidgetProps^.Dimensions.Width, WidgetProps^.Dimensions.Top + WidgetProps^.Dimensions.Height);
  PaintAPI.DrawRect(OsRGB(0, 0, 0), WidgetProps^.Dimensions.Left + 1, WidgetProps^.Dimensions.Top + 1, WidgetProps^.Dimensions.Left + WidgetProps^.Dimensions.Width - 1, WidgetProps^.Dimensions.Top + WidgetProps^.Dimensions.Height - 1);
  PaintAPI.OutText(OsRGB(0, 0, 0), WidgetProps^.Dimensions.Left, WidgetProps^.Dimensions.Top, WidgetProps^.Dimensions.Left + WidgetProps^.Dimensions.Width, WidgetProps^.Dimensions.Top + WidgetProps^.Dimensions.Height, PWideChar(UserData));
end;

procedure ButtonSystemEventProc(ClassName: PWideChar; ID: NativeUInt; EventAPI: TEventAPI; WidgetProps: PWidgetProps; var UserData: Pointer); stdcall;
var
  Widget: TChildWidget;
begin
  case EventAPI.EventType of
    etMouseDn:
      begin
        WidgetProps^.Color := WidgetProps^.Color - OsRGB(30, 30, 30);
      end;
    etMouseUp:
      begin
        WidgetProps^.Color := WidgetProps^.Color + OsRGB(30, 30, 30);
      end;
  end;

  Widget := RootWidget.WidgetByID(ID);
  if Assigned(Widget) and Assigned(Widget.UserEventProc) then
    Widget.UserEventProc(ClassName, ID, EventAPI, WidgetProps^, UserData);
end;

procedure CreateStdClasses;
begin
  VgCreateVidgetClass('PANEL', PanelPaintProc, nil);
  VgCreateVidgetClass('LABEL', LabelPaintProc, nil);
  VgCreateVidgetClass('BUTTON', ButtonPaintProc, ButtonSystemEventProc);
end;

initialization
  ClassHeaders := TClassHeaders.Create;
  CreateStdClasses;

finalization
  ClassHeaders.Free;

end.
