unit uVidgetsDllWrapper;

interface

uses
  uVidgetSharedTypes;

function ErrorText(const ErrorCode: LongWord): UnicodeString; stdcall;
function Init(const Container: NativeUInt): LongWord; stdcall;
function Deinit: LongWord; stdcall;
function Repaint: LongWord; stdcall;
function CreateVidgetClass(const ClassName: UnicodeString; const PaintProc: TWidgetPaintProc; const EventProc: TWidgetSystemEventProc): LongWord; stdcall;
function CreateVidget(const ClassName: UnicodeString; const ParentID: NativeUInt; const WidgetProps: TWidgetProps; const UserData: Pointer; const EventProc: TWidgetUserEventProc; out ID: NativeUInt): LongWord; stdcall;
function CreateWidgetProps(const Color: Cardinal; const Left, Top, Width, Height: Integer): TWidgetProps; stdcall;
function UpdateWidgetUserData(const ID: NativeUInt; const UserData: Pointer): LongWord; stdcall;
function UpdateWidgetVisibility(const ID: NativeUInt; const Visible: Boolean): LongWord; stdcall;

procedure CheckVidget(const ErrorCode: LongWord);

implementation

uses
  System.SysUtils;

procedure CheckVidget(const ErrorCode: LongWord);
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
function CreateWidgetProps; stdcall; external LIB_VIDGETS;
function UpdateWidgetUserData; stdcall; external LIB_VIDGETS;
function UpdateWidgetVisibility; stdcall; external LIB_VIDGETS;


end.
