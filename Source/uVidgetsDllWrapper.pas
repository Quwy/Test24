{ Simple Delphi wrapper for LibVidgets.dll library
  All function descriptions see in the uVidgetsProcs unit }

unit uVidgetsDllWrapper;

interface

uses
  uVidgetSharedTypes;

function ErrorText(const ErrorCode: LongWord): UnicodeString; stdcall;
function Init(const Container: NativeUInt): LongWord; stdcall;
function Deinit: LongWord; stdcall;
function Repaint: LongWord; stdcall;
function CreateVidgetClass(const ClassName: UnicodeString; const PaintProc: TVidgetPaintProc; const EventProc: TVidgetSystemEventProc): LongWord; stdcall;
function CreateVidget(const ClassName: UnicodeString; const ParentID: NativeUInt; const VidgetProps: TVidgetProps; const UserData: Pointer; const EventProc: TVidgetUserEventProc; out ID: NativeUInt): LongWord; stdcall;
function CreateVidgetProps(const Color: Cardinal; const Left, Top, Width, Height: Integer): TVidgetProps; stdcall;
function UpdateVidgetUserData(const ID: NativeUInt; const UserData: Pointer): LongWord; stdcall;
function UpdateVidgetVisibility(const ID: NativeUInt; const Visible: Boolean): LongWord; stdcall;

// like another delphi functions for instant returned error checking
procedure VidgetCheck(const ErrorCode: LongWord);

implementation

uses
  System.SysUtils;

procedure VidgetCheck(const ErrorCode: LongWord);
begin
  if ErrorCode <> VG_ERROR_SUCCESS then
    Exception.Create(ErrorText(ErrorCode));
end;

const
  LIB_VIDGETS = 'LibVidgets.dll';

function ErrorText; stdcall; external LIB_VIDGETS;
function Init; stdcall; external LIB_VIDGETS;
function Deinit; stdcall; external LIB_VIDGETS;
function Repaint; stdcall; external LIB_VIDGETS;
function CreateVidgetClass; stdcall; external LIB_VIDGETS;
function CreateVidget; stdcall; external LIB_VIDGETS;
function CreateVidgetProps; stdcall; external LIB_VIDGETS;
function UpdateVidgetUserData; stdcall; external LIB_VIDGETS;
function UpdateVidgetVisibility; stdcall; external LIB_VIDGETS;

end.

