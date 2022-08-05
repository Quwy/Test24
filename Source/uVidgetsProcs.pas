{ internal vidgets API }

unit uVidgetsProcs;

interface

uses
  uVidgetSharedTypes,
  uVidgetsClasses,
  System.Classes,
  System.SysUtils,
  System.Types;

// return error text by error code
function VgErrorText(const ErrorCode: LongWord): UnicodeString;

// initialize surface. Container is a OS-specific window handle
function VgInit(const Container: NativeUInt): LongWord;
// deinitialize surface and restore OS-specific window
function VgDeinit: LongWord;
// force repaint OS-specific window and surface
function VgRepaint: LongWord;

// create new Vidget class with own look and behaviour to use it many times
function VgCreateVidgetClass(const ClassName: UnicodeString; const PaintProc: TVidgetPaintProc; const EventProc: TVidgetSystemEventProc): LongWord;
// create new Vidget on the surface
function VgCreateVidget(const ClassName: UnicodeString; const ParentID: NativeUInt; const VidgetProps: TVidgetProps; const UserData: Pointer; const EventProc: TVidgetUserEventProc; out ID: NativeUInt): LongWord;
// function to simplify VgCreateVidget call
function VgCreateVidgetProps(const Color: Cardinal; const Left, Top, Width, Height: Integer): TVidgetProps;
// update user-defined data associated with vidget and force it to update itself on the surface
function VgUpdateVidgetUserData(const ID: NativeUInt; const UserData: Pointer): LongWord;
// toggle vidget visibility
function VgUpdateVidgetVisibility(const ID: NativeUInt; const Visible: Boolean): LongWord;


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
     'Vidget not found',
     'Invalid error code');

var
  RootVidget: TVidget;
  ClassHeaders: TClassHeaders;

procedure PaintProc(const PaintAPI: TPaintAPI);
begin
  RootVidget.Paint(PaintAPI);
end;

procedure EventProc(const EventAPI: TEventAPI);
begin
  RootVidget.Event(EventAPI);
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
      RootVidget := TVidget.Create(OsRGB(64, 64, 64), Width, Height);
      Result := VG_ERROR_SUCCESS;
    end
  else
    Result := VG_ERROR_INVALID_CONTAINER;
end;

function VgDeinit: LongWord;
begin
  if OsDeinitContainer then
    begin
      RootVidget.Free;
      Result := VG_ERROR_SUCCESS;
    end
  else
    Result := VG_ERROR_NOT_INITIALIZED;
end;

function VgCreateVidgetClass(const ClassName: UnicodeString; const PaintProc: TVidgetPaintProc; const EventProc: TVidgetSystemEventProc): LongWord;
begin
  if ClassHeaders.IndexOfName(ClassName) <= 0 then
    begin
      ClassHeaders.Add(TClassHeader.Create(ClassName, PaintProc, EventProc));
      Result := VG_ERROR_SUCCESS;
    end
  else
    Result := VG_ERROR_CLASS_ALREADY_REGISTERED;
end;

function VgCreateVidget(const ClassName: UnicodeString; const ParentID: NativeUInt; const VidgetProps: TVidgetProps; const UserData: Pointer; const EventProc: TVidgetUserEventProc; out ID: NativeUInt): LongWord;
var
  ClassIdx: Integer;
  Vidget: TChildVidget;
  ParentVidget: TVidget;
begin
  ClassIdx := ClassHeaders.IndexOfName(ClassName);
  if ClassIdx >= 0 then
    begin
      Result := VG_ERROR_SUCCESS;

      if ParentID > 0 then
        begin
          ParentVidget := RootVidget.VidgetByID(ParentID);
          if not Assigned(ParentVidget) then
            Result := VG_ERROR_PARENT_NOT_FOUND;
        end
      else
        ParentVidget := RootVidget;

      if Result = VG_ERROR_SUCCESS then
        begin
          Vidget := TChildVidget.Create(ClassName, ParentVidget, VidgetProps, ClassHeaders[ClassIdx].PaintProc, ClassHeaders[ClassIdx].SystemEventProc, UserData);
          Vidget.UserEventProc := EventProc;
          ID := Vidget.ID;
        end;
    end
  else
    Result := VG_ERROR_CLASS_NOT_REGISTERED;
end;

function VgCreateVidgetProps(const Color: Cardinal; const Left, Top, Width, Height: Integer): TVidgetProps;
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

function VgUpdateVidgetUserData(const ID: NativeUInt; const UserData: Pointer): LongWord;
var
  Vidget: TChildVidget;
begin
  Vidget := RootVidget.VidgetByID(ID);
  if Assigned(Vidget) then
    begin
      Vidget.UserData := UserData;
      Vidget.Parent.NeedRepaint;
      Result := VG_ERROR_SUCCESS;
    end
  else
    Result := VG_ERROR_Vidget_NOT_FOUND;
end;

function VgUpdateVidgetVisibility(const ID: NativeUInt; const Visible: Boolean): LongWord;
var
  Vidget: TChildVidget;
begin
  Vidget := RootVidget.VidgetByID(ID);
  if Assigned(Vidget) then
    begin
      Vidget.Vidible := Visible;
      Vidget.NeedRepaint;
      Result := VG_ERROR_SUCCESS;
    end
  else
    Result := VG_ERROR_Vidget_NOT_FOUND;
end;

// standart PANEL vidget painter
procedure PanelPaintProc(ClassName: PWideChar; ID: NativeUInt; PaintAPI: TPaintAPI; VidgetProps: PVidgetProps; var UserData: Pointer); stdcall;
begin
  PaintAPI.FillRect(VidgetProps^.Color, VidgetProps^.Dimensions.Left, VidgetProps^.Dimensions.Top, VidgetProps^.Dimensions.Left + VidgetProps^.Dimensions.Width, VidgetProps^.Dimensions.Top + VidgetProps^.Dimensions.Height);
end;

// standart LABEL vidget painter
procedure LabelPaintProc(ClassName: PWideChar; ID: NativeUInt; PaintAPI: TPaintAPI; VidgetProps: PVidgetProps; var UserData: Pointer); stdcall;
begin
  PaintAPI.FillRect(VidgetProps^.Color, VidgetProps^.Dimensions.Left, VidgetProps^.Dimensions.Top, VidgetProps^.Dimensions.Left + VidgetProps^.Dimensions.Width, VidgetProps^.Dimensions.Top + VidgetProps^.Dimensions.Height);
  PaintAPI.OutText(OsRGB(0, 0, 0), VidgetProps^.Dimensions.Left, VidgetProps^.Dimensions.Top, VidgetProps^.Dimensions.Left + VidgetProps^.Dimensions.Width, VidgetProps^.Dimensions.Top + VidgetProps^.Dimensions.Height, PWideChar(UserData));
end;

// standart BUTTON vidget painter
procedure ButtonPaintProc(ClassName: PWideChar; ID: NativeUInt; PaintAPI: TPaintAPI; VidgetProps: PVidgetProps; var UserData: Pointer); stdcall;
begin
  PaintAPI.FillRect(VidgetProps^.Color, VidgetProps^.Dimensions.Left, VidgetProps^.Dimensions.Top, VidgetProps^.Dimensions.Left + VidgetProps^.Dimensions.Width, VidgetProps^.Dimensions.Top + VidgetProps^.Dimensions.Height);
  PaintAPI.DrawRect(OsRGB(0, 0, 0), VidgetProps^.Dimensions.Left + 1, VidgetProps^.Dimensions.Top + 1, VidgetProps^.Dimensions.Left + VidgetProps^.Dimensions.Width - 1, VidgetProps^.Dimensions.Top + VidgetProps^.Dimensions.Height - 1);
  PaintAPI.OutText(OsRGB(0, 0, 0), VidgetProps^.Dimensions.Left, VidgetProps^.Dimensions.Top, VidgetProps^.Dimensions.Left + VidgetProps^.Dimensions.Width, VidgetProps^.Dimensions.Top + VidgetProps^.Dimensions.Height, PWideChar(UserData));
end;

// standart BUTTON vidget animator and event repeater to the user-defined handler
procedure ButtonSystemEventProc(ClassName: PWideChar; ID: NativeUInt; EventAPI: TEventAPI; VidgetProps: PVidgetProps; var UserData: Pointer); stdcall;
var
  Vidget: TChildVidget;
begin
  case EventAPI.EventType of
    etMouseDn:
      begin
        VidgetProps^.Color := VidgetProps^.Color - OsRGB(30, 30, 30); // for such a beat on the hands
      end;
    etMouseUp:
      begin
        VidgetProps^.Color := VidgetProps^.Color + OsRGB(30, 30, 30);
      end;
  end;

  Vidget := RootVidget.VidgetByID(ID);
  if Assigned(Vidget) and Assigned(Vidget.UserEventProc) then
    Vidget.UserEventProc(ClassName, ID, EventAPI, VidgetProps^, UserData);
end;

procedure CreateStdClasses;
begin
  // here are created all "standart" vidgets, included in the library
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

