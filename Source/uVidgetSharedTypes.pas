{ data types and constants, used on both sides: DLL and EXE }

unit uVidgetSharedTypes;

interface

uses
  System.Types;

type
  // OS-independed raphical primitive methods signatures
  TLine = procedure(Color: LongWord; X1, Y1, X2, Y2: LongInt); stdcall;
  TDrawRect = procedure(Color: LongWord; X1, Y1, X2, Y2: LongInt); stdcall;
  TFillRect = procedure(Color: LongWord; X1, Y1, X2, Y2: LongInt); stdcall;
  TOutText = procedure(Color: LongWord; X1, Y1, X2, Y2: LongInt; Text: PWideChar); stdcall;

  TPaintAPI = record
    Line: TLine;
    DrawRect: TDrawRect;
    FillRect: TFillRect;
    OutText: TOutText;
    // many other graphical primitives implied here
  end;

  TEventType = (etMouseDn, etMouseUp);
  TEventAPI = record
    EventType: TEventType;
    Position: TPoint;
    // many other events and its dependecities implied here
  end;
  // Vidget rectangle
  TVidgetDimensions = record
    Left, Top, Width, Height: Integer;
  end;
  // basic Vidget properties
  TVidgetProps = record
    Color: Cardinal;
    Dimensions: TVidgetDimensions;
  end;
  PVidgetProps = ^TVidgetProps;

  // Vidget paint method
  TVidgetPaintProc = procedure(ClassName: PWideChar; ID: NativeUInt; PaintAPI: TPaintAPI; VidgetProps: PVidgetProps; var UserData: Pointer); stdcall;
  // Vidget event method for visualise any reaction on the events
  TVidgetSystemEventProc = procedure(ClassName: PWideChar; ID: NativeUInt; EventAPI: TEventAPI; VidgetProps: PVidgetProps; var UserData: Pointer); stdcall;
  // user defined event handler (such as OnClick or OnMouseDown)
  TVidgetUserEventProc = procedure(ClassName: PWideChar; ID: NativeUInt; EventAPI: TEventAPI; VidgetProps: TVidgetProps; var UserData: Pointer); stdcall;

const
  VG_ERROR_SUCCESS = 0;
  VG_ERROR_INVALID_CONTAINER = 1;
  VG_ERROR_NOT_INITIALIZED = 2;
  VG_ERROR_CLASS_ALREADY_REGISTERED = 3;
  VG_ERROR_CLASS_NOT_REGISTERED = 4;
  VG_ERROR_PARENT_NOT_FOUND = 5;
  VG_ERROR_Vidget_NOT_FOUND = 6;

implementation

end.
