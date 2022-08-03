unit uVidgetSharedTypes;

interface

uses
  System.Types;

type
  TLine = procedure(Color: LongWord; X1, Y1, X2, Y2: LongInt); stdcall;
  TDrawRect = procedure(Color: LongWord; X1, Y1, X2, Y2: LongInt); stdcall;
  TFillRect = procedure(Color: LongWord; X1, Y1, X2, Y2: LongInt); stdcall;
  TOutText = procedure(Color: LongWord; X1, Y1, X2, Y2: LongInt; Text: PWideChar); stdcall;

  TPaintAPI = record
    Line: TLine;
    DrawRect: TDrawRect;
    FillRect: TFillRect;
    OutText: TOutText;
    // ...
  end;

  TEventType = (etMouseDn, etMouseUp);
  TEventAPI = record
    EventType: TEventType;
    Position: TPoint;
    // ...
  end;

  TGlobalPaintProc = procedure(const PaintAPI: TPaintAPI);
  TGlobalEventProc = procedure(const EventAPI: TEventAPI);

  TWidgetDimensions = record
    Left, Top, Width, Height: Integer;
  end;
  TWidgetProps = record // mandatory widget properties
    Color: Cardinal;
    Dimensions: TWidgetDimensions;
  end;
  PWidgetProps = ^TWidgetProps;
  TWidgetPaintProc = procedure(ClassName: PWideChar; ID: NativeUInt; PaintAPI: TPaintAPI; WidgetProps: PWidgetProps; var UserData: Pointer); stdcall;
  TWidgetSystemEventProc = procedure(ClassName: PWideChar; ID: NativeUInt; EventAPI: TEventAPI; WidgetProps: PWidgetProps; var UserData: Pointer); stdcall;
  TWidgetUserEventProc = procedure(ClassName: PWideChar; ID: NativeUInt; EventAPI: TEventAPI; WidgetProps: TWidgetProps; var UserData: Pointer); stdcall;

const
  VG_ERROR_SUCCESS = 0;
  VG_ERROR_INVALID_CONTAINER = 1;
  VG_ERROR_NOT_INITIALIZED = 2;
  VG_ERROR_CLASS_ALREADY_REGISTERED = 3;
  VG_ERROR_CLASS_NOT_REGISTERED = 4;
  VG_ERROR_PARENT_NOT_FOUND = 5;
  VG_ERROR_WIDGET_NOT_FOUND = 6;


implementation

end.
